# Expansión del pipeline de reportes — roadmap

**Estado**: PLANIFICADO

> Este documento complementa `docs/features/cron-automation.md` y propone evoluciones futuras del pipeline de automatización. La capacidad vigente son los 8 jobs ya documentados.

---

## 1. Motivación

El backend ya cubre automatización operativa relevante (monthly reports, member of month, rankings, cierre financiero, recordatorios, expiración, cleanup). Áreas candidatas a sumarse:

- dashboards operativos de pipeline (visibilidad del cron para admins);
- alerting sobre fallos persistentes;
- expansión de dominios cubiertos.

## 2. Estado actual

- 8 jobs `@Cron` ejecutándose en UTC (ver `docs/features/cron-automation.md`).
- Sin dashboard admin dedicado.
- Sin alerting automático (fallos sólo en logs del servidor).
- `reports.auto_generate_enabled` default `false` (dark launch).
- Tokens FCM con `active=false` no se purgan (quedan como huérfanos).

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

Decisión pendiente: plataforma.

### 3.3 Reportes trimestrales y anuales

Hoy solo existen reportes mensuales (`monthly_reports`). Dominios candidatos a automatizar:

- **reporte trimestral** por club con métricas agregadas;
- **reporte anual institucional** consolidado por `ecclesiastical_year`;
- **reporte de investiduras por ciclo**;
- **reporte de camporees** post-evento.

### 3.4 Cleanup FCM tokens huérfanos — COMPLETADO 2026-04-22

Nuevo job `@Cron` que purgue filas de `user_fcm_tokens` con `active = false` y `modified_at < now() - 90 días`.

Valor: evitar crecimiento indefinido de la tabla.

Riesgo: muy bajo (no afecta usuarios activos).

**Estado**: cerrado. Implementado en `sacdia-backend/src/common/services/cleanup.service.ts` como método `cleanupInactiveFcmTokens()` con decorador `@Cron(CronExpression.EVERY_DAY_AT_3AM, { name: 'fcm-tokens-cleanup', timeZone: 'UTC' })`.

### 3.5 Job timezone explícito — COMPLETADO 2026-04-22

Agregar `{ timeZone: 'UTC' }` a los 7 jobs que hoy dependen del default de NestJS. Tarea mecánica, sin impacto operativo si el default sigue siendo UTC, pero evita ambigüedad ante cambios futuros.

**Estado**: cerrado. Los 8 jobs tienen ahora `{ timeZone: 'UTC' }` explícito. Verificado en cada archivo de `sacdia-backend/src/**/*-cron.service.ts` + `rankings.service.ts`, `cleanup.service.ts`, `activities-reminder.service.ts`, `finance-period.service.ts`, `data-export.service.ts`.

### 3.6 Retries más granulares por job

Hoy BullMQ retries aplican solo a jobs de `notifications`. Otros jobs caen si la ejecución falla. Evaluar migrar jobs críticos (monthly-reports, rankings, finance-period) a BullMQ con política de retry.

## 4. Priorización tentativa

| # | Línea | Prioridad | Dependencia |
|---|-------|-----------|-------------|
| 1 | Cleanup FCM tokens huérfanos | alta (bajo esfuerzo, beneficio claro) | — |
| 2 | Job timezone explícito | alta (mecánico) | — |
| 3 | Dashboard operativo de jobs | media | `job_run_log` table |
| 4 | Alerting automático | media | elección de plataforma |
| 5 | Reporte trimestral / anual | baja | demanda concreta del producto |
| 6 | BullMQ retry por job | baja | análisis de casos de falla real |

## 5. Criterio de éxito

- **Job dashboard**: admin puede responder "¿el cron X corrió anoche?" sin abrir logs del servidor.
- **Alerting**: fallo persistente dispara notificación en <5 minutos.
- **Cleanup tokens**: tabla `user_fcm_tokens` crece proporcional a usuarios activos, no al histórico.
- **Timezone explícito**: cualquier nuevo job sigue convención uniforme sin ambigüedad.

## 6. Estado actual

- **Prioridad global**: media. Pipeline funciona; evolución es calidad operativa, no funcionalidad nueva.
- **Decisión inmediata**: ninguna. Considerar cleanup FCM tokens en la próxima ola de housekeeping.
