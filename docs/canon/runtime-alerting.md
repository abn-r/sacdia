# runtime-alerting

**Estado**: ACTIVE
**Última revisión**: 2026-04-23
**Autoridad rectora**: este documento + Sentry dashboard `sacdia-6g`.

> Captura errores y notifica a operaciones cuando la salud del sistema cae por debajo de un umbral. La observabilidad base (capture) está vigente en los tres runtimes. Las reglas de alerta viven en Sentry UI y son configurables por operaciones.

---

## 1. Capas

| Capa | Qué captura | Dónde se define |
|------|-------------|-----------------|
| SDK init | todos los errores no manejados | `main.ts` (backend), `src/instrumentation*.ts` (admin), `lib/main.dart` (app) |
| Captura explícita | fallos de cron, procesadores BullMQ, handlers HTTP | `CronRunLogger`, `SentryInterceptor`, `*.processor.ts` |
| Alert rules | umbrales + destinos (email / Slack / webhook) | Sentry UI → Project → Alerts → Create Alert |

La infraestructura de capture es código versionado. Las reglas de alerta son configuración Sentry — pueden cambiar sin redeploy.

## 2. Proyectos Sentry

| Servicio | Org | Project slug | Platform | Project ID |
|----------|-----|--------------|----------|------------|
| sacdia-backend | sacdia-6g | sacdia-backend | NestJS | *(crear manualmente)* |
| sacdia-admin   | sacdia-6g | sacdia-admin   | Next.js | 4510840513036288 |
| sacdia-app     | sacdia-6g | sacdia-app     | Flutter | 4511270132645888 |

DSN hardcoded en cada runtime. Env vars cross-runtime:

| Variable | Backend (Render) | Admin (Vercel) | App (build-time) |
|----------|------------------|----------------|------------------|
| `SENTRY_DSN` | requerida | n/a (hardcoded) | n/a (hardcoded) |
| `SENTRY_AUTH_TOKEN` | opcional (source maps) | requerida (source maps) | `sentry.properties` local |
| `VERCEL_GIT_COMMIT_SHA` | n/a | auto por Vercel | n/a |
| `RENDER_GIT_COMMIT` | auto por Render | n/a | n/a |
| `SENTRY_RELEASE` | opcional (override manual) | opcional | opcional |

## 3. Tagging standard

Todo `Sentry.captureException` en el backend debe seguir esta convención para que las reglas UI puedan filtrar limpio:

| Tag | Cuándo | Valor |
|-----|--------|-------|
| `job_name` | cron failure | nombre del job (`monthly-reports`, `rankings`, etc.) |
| `cron` | cron failure | `'true'` |
| `source` | origen | `'cron' \| 'bullmq' \| 'http' \| 'manual'` |
| `queue` | BullMQ failure | nombre de la cola (`notifications`, `achievements`) |
| `domain` | opcional | módulo backend (`auth`, `folders`, etc.) |

**Fingerprint** — para que todas las fallas de un mismo job agrupen en una sola issue:

```ts
Sentry.captureException(err, {
  fingerprint: ['cron-failure', jobName],
  tags: { job_name: jobName, cron: 'true', source: 'cron' },
});
```

`CronRunLogger.track()` ya aplica esta convención automáticamente.

## 4. Reglas de alerta recomendadas

### 4.1 Cron job falló (backend)

- Project: `sacdia-backend`
- Condition: **Issue is first seen** OR **Event count > 3 in 1h** con filter `tags.cron equals true`
- Action: notify team (email / Slack)
- Rationale: un cron que falla una vez puede ser transient. 3 en 1h = problema real.

### 4.2 Backend 5xx spike

- Project: `sacdia-backend`
- Condition: **Event count > 20 in 1h** con filter `level:error` y `!tags.cron:true`
- Action: notify team
- Rationale: spike HTTP 500 = backend degradado.

### 4.3 Admin client error spike

- Project: `sacdia-admin`
- Condition: **Event count > 15 in 1h** con filter `level:error` y `!error.type:NetworkError`
- Action: notify team
- Rationale: 15+ errores cliente/hora = deploy broken o bug regresión.

### 4.4 Flutter crash nuevo

- Project: `sacdia-app`
- Condition: **Issue is first seen** con filter `level:fatal`
- Action: notify team
- Rationale: crashes en mobile son alta prioridad — un nuevo tipo de crash merece atención inmediata.

### 4.5 Regresión post-deploy (opcional)

- Project: cualquiera
- Condition: **Issue is first seen in release X**
- Action: notify team
- Rationale: detección temprana de regresiones en nuevos deploys. Requiere que `release` esté seteado en Sentry.init (ya hecho con `VERCEL_GIT_COMMIT_SHA` / `RENDER_GIT_COMMIT`).

## 5. Configuración UI — pasos por regla

Sentry UI no admite configuración 100% API con los wizard tokens (solo `project:releases`). Configurar por UI es esperado.

```
1. https://sacdia-6g.sentry.io/
2. Projects → seleccionar proyecto
3. Alerts → Create Alert → Issue Alert
4. Configurar según §4.N
5. Save
```

Para crear vía API se requiere User Auth Token con scope `alerts:write` (no el token que generó el wizard).

## 6. Destinos de notificación

Default: email del owner del proyecto.

Opcionales (configurar en Sentry UI):

- **Slack** — requiere integración Slack oficial. Gratuito.
- **Discord** — via webhook.
- **PagerDuty** — plan Business+ Sentry.
- **Webhook** — HTTP POST a endpoint custom.

## 7. Supresión de ruido

Reglas de inbox para reducir noise (Settings → Inbox → Auto-Resolve):

- Auto-resolve después de 14 días sin recurrencia.
- Ignore issues con `NetworkError` si el user está offline (ya filtrado en `ignoreErrors` cliente-side).
- Tag `level:warning` no debe disparar alerta.

## 8. Costo

Free tier Sentry:
- 5K errores/mes
- 10K spans tracing/mes
- 50 replays (no usado)
- 1 user

Si se satura: plan Team ($26/mes, 50K errores) — decidir cuando ocurra.

## 9. Runbook — qué hacer cuando llega alerta

| Alerta | Primera acción | Segunda acción |
|--------|----------------|----------------|
| Cron job falló | revisar `cron_run_log` en `/dashboard/system/jobs` | retry manual si es transient; escalar si persiste |
| Backend 5xx spike | health endpoint `/api/v1/health` | Render logs + DB status |
| Admin client error spike | Sentry issue → tabla afectada | Vercel deploy history (¿regresión reciente?) |
| Flutter crash nuevo | Sentry issue → stack trace | reproducir local; si release-specific, rollback TestFlight |

## 10. Referencias

- `sacdia-backend/src/main.ts` §47-122 — Sentry init + `beforeSend` sanitize
- `sacdia-backend/src/common/services/cron-run-logger.service.ts` — tag + fingerprint convention
- `sacdia-backend/src/common/interceptors/sentry.interceptor.ts` — HTTP error capture
- `sacdia-admin/src/instrumentation*.ts` + `sentry.{server,edge}.config.ts` — admin init
- `sacdia-app/lib/main.dart` — Flutter init + PII scrub
