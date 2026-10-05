# Expansión del pipeline de reportes — roadmap

**Estado**: PARCIALMENTE IMPLEMENTADO (revisado 2026-10-04 contra `development`)

> Complementa `docs/features/cron-automation.md`.
> - **Hecho en `development`**: dashboard de jobs, alerting interno de crons, reportes trimestrales y anuales, limpieza de tokens FCM y zona horaria explícita en la mayoría de los jobs.
> - **Falta**: reintentos por job, alerting externo, filtrado histórico y reintento desde el admin, y reportes de investiduras y de camporees.

---

## 1. Motivación

El backend ya cubre automatización operativa relevante (monthly reports, member of month, rankings, cierre financiero, recordatorios, expiración, cleanup). Áreas candidatas a sumarse:

- dashboards operativos de pipeline (visibilidad del cron para admins);
- alerting sobre fallos persistentes;
- expansión de dominios cubiertos.

## 2. Estado actual

- 15 jobs `@Cron` en el backend (ver `docs/features/cron-automation.md`); sus ejecuciones se registran en `cron_run_log` mediante `CronRunLogger`.
- Dashboard admin en `/dashboard/system/jobs` (§3.1).
- Alerting interno de crons con `CronAlertService` (§3.2).
- `reports.auto_generate_enabled` vale `'true'` en `prisma/seeds/system-config.seed.sql`. Los flags `reports.quarterly_auto_generate_enabled` y `reports.annual_auto_generate_enabled` nacen en `'false'` (migración `20260427120000_quarterly_annual_reports`).
- Los tokens FCM inactivos se purgan (§3.4).

## 3. Líneas candidatas

### 3.1 Dashboard operativo de jobs — COMPLETADO 2026-04-22

Superficie admin que muestre, por job: última ejecución, duración, próximas ejecuciones, tasa de fallo, feature flag asociado.

Valor: visibilidad operativa sin SSH al servidor.

**Estado**: cerrado. Cubre:
- Colas BullMQ (`notifications`, `achievements`, `data-exports`) vía `GET /admin/analytics/jobs-overview` — métricas transitorias.
- 9 `@Cron` services vía tabla `cron_run_log` + helper `CronRunLogger` + endpoint `GET /admin/analytics/cron-runs` — métricas persistentes (avg duration 30d, failure rate 7d, último éxito/fallo, total runs 7d).
- Página admin `/dashboard/system/jobs` integra ambas secciones.

Ver `docs/features/cron-automation.md` §Observabilidad admin.

**Falta cerrar** (roadmap menor):
- replay/retry de failed BullMQ jobs desde admin.
- búsqueda/filtrado histórico por fecha o job.
- alerting externo cuando failure_rate > umbral (§3.2).

### 3.2 Alerting automático

Integración con herramienta externa (Sentry / Datadog / plataforma propia) para disparar alerta cuando:
- job falla N veces consecutivas;
- duración supera umbral;
- feature flag dark-launched lleva >30d sin activarse.

**Estado**: alerting interno implementado; el externo sigue pendiente.

- `CronAlertService` (`src/common/services/cron-alert.service.ts`, cron `cron-alert-check` en los minutos 5, 20, 35 y 50 de cada hora) revisa `cron_run_log` y alerta cuando:
  - un job falla 3 veces seguidas;
  - un job supera la duración máxima (5 min por defecto);
  - la tasa de fallo de 24 h supera el 50 %.
- Avisa a los usuarios `super-admin` por correo y con notificación in-app (`system_alert:cron_failure`). No repite la misma alerta durante 6 h.
- Los errores de la aplicación llegan además a Sentry (`docs/canon/runtime-alerting.md`).
- Pendiente:
  - plataforma externa (Datadog o similar);
  - alerta por feature flags apagados más de 30 días.

### 3.3 Reportes trimestrales y anuales

Hoy solo existen reportes mensuales (`monthly_reports`). Dominios candidatos a automatizar:

- **reporte trimestral** por club con métricas agregadas;
- **reporte anual institucional** consolidado por `ecclesiastical_year`;
- **reporte de investiduras por ciclo**;
- **reporte de camporees** post-evento.

**Estado**: trimestral y anual implementados; investiduras y camporees siguen pendientes.

- Módulos `src/quarterly-reports/` y `src/annual-reports/` en el backend, cada uno con controller, generación de PDF y cron:
  - `quarterly-reports-auto-generate`: día 1 de enero, abril, julio y octubre;
  - `annual-reports-auto-generate`: 1 de enero.
- Los dos crons se controlan con sus flags de `system_config`, apagados por defecto.

### 3.4 Cleanup FCM tokens huérfanos — COMPLETADO 2026-04-22

Nuevo job `@Cron` que purgue filas de `user_fcm_tokens` con `active = false` y `modified_at < now() - 90 días`.

Valor: evitar crecimiento indefinido de la tabla.

Riesgo: muy bajo (no afecta usuarios activos).

**Estado**: cerrado. Implementado en `sacdia-backend/src/common/services/cleanup.service.ts` como método `cleanupInactiveFcmTokens()` con decorador `@Cron(CronExpression.EVERY_DAY_AT_3AM, { name: 'fcm-tokens-cleanup', timeZone: 'UTC' })`.

Nota (2026-10-04): `src/notifications/fcm-tokens.service.ts` declara otro `@Cron('0 3 * * 0', { name: 'fcm-tokens-cleanup' })` con el mismo nombre. Conviene unificar los dos jobs.

### 3.5 Job timezone explícito — COMPLETADO 2026-04-22

Agregar `{ timeZone: 'UTC' }` a los 7 jobs que hoy dependen del default de NestJS. Tarea mecánica, sin impacto operativo si el default sigue siendo UTC, pero evita ambigüedad ante cambios futuros.

**Estado**: cerrado para los jobs de entonces.

- Revisión de 2026-10-04: `monthly-reports-reminders` usa `America/Mexico_City` a propósito.
- Siguen sin `timeZone` explícito:
  - `cron-alert-check` (`cron-alert.service.ts`);
  - `fcm-tokens-cleanup` (`fcm-tokens.service.ts`).

### 3.6 Retries más granulares por job

Hoy BullMQ retries aplican solo a jobs de `notifications`. Otros jobs caen si la ejecución falla. Evaluar migrar jobs críticos (monthly-reports, rankings, finance-period) a BullMQ con política de retry.

## 4. Priorización tentativa

| # | Línea | Prioridad | Dependencia |
|---|-------|-----------|-------------|
| 1 | Cleanup FCM tokens huérfanos | hecho | — |
| 2 | Job timezone explícito | hecho (faltan 2 jobs nuevos) | — |
| 3 | Dashboard operativo de jobs | hecho (`cron_run_log`) | — |
| 4 | Alerting automático | interno hecho; externo pendiente | elección de plataforma |
| 5 | Reporte trimestral / anual | hecho; investiduras y camporees pendientes | demanda concreta del producto |
| 6 | BullMQ retry por job | pendiente | análisis de casos de falla real |

## 5. Criterio de éxito

- **Job dashboard**: admin puede responder "¿el cron X corrió anoche?" sin abrir logs del servidor.
- **Alerting**: fallo persistente dispara notificación en <5 minutos.
- **Cleanup tokens**: tabla `user_fcm_tokens` crece proporcional a usuarios activos, no al histórico.
- **Timezone explícito**: cualquier nuevo job sigue convención uniforme sin ambigüedad.

## 6. Estado actual

- **Prioridad global**: baja. Lo de mayor valor ya está en `development`.
- **Pendiente**:
  - reintentos por job (§3.6);
  - alerting externo;
  - reintento y filtrado histórico desde el admin;
  - reportes de investiduras y de camporees;
  - unificar los dos jobs `fcm-tokens-cleanup` y fijar su zona horaria.
