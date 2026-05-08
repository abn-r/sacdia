# Cron Automation (jobs programados del backend)

**Estado**: IMPLEMENTADO

<!-- VERIFICADO contra código 2026-04-22: 8 @Cron jobs identificados en sacdia-backend/src/, ScheduleModule registrado en app.module.ts:75, timezone UTC (uno explícito, siete por default NestJS). -->

## Descripción de dominio

El backend SACDIA ejecuta 8 jobs programados que automatizan flujos institucionales recurrentes: generación de reportes mensuales, cierre financiero, cálculo de rankings anuales, evaluación de miembro del mes, recordatorios de actividades, expiración de solicitudes, cleanup de tokens/sesiones y limpieza de exportes vencidos.

Todos los jobs operan en **UTC** (ver §3), son **idempotentes por diseño** (usan locks distribuidos o verificaciones de estado previo) y siguen un patrón **fire-and-forget** desde el scheduler — fallos dentro de un job no detienen el resto del pipeline ni propagan excepciones al caller original del endpoint que disparó el flujo.

Varios jobs están gobernados por `system_config` o feature flags (ver §6) para habilitar/deshabilitar por ambiente sin redeploy.

## Que existe (verificado contra código)

### Infraestructura

- **Módulo NestJS**: `ScheduleModule.forRoot()` registrado en `sacdia-backend/src/app.module.ts:75`.
- **Timezone**: UTC explícito en los 8 jobs desde 2026-04-22 (opción `{ timeZone: 'UTC' }` en cada decorador `@Cron`).
- **Locks distribuidos**: varios jobs usan lock en Redis para evitar ejecución concurrente entre múltiples instancias (ver cada job para TTL).
- **Logging**: estructurado vía `Logger` de NestJS; fallos por entidad se loguean y continúan con el siguiente elemento del batch.

### Inventario de jobs

| # | Job | Cron | Frecuencia efectiva | Módulo |
|---|-----|------|---------------------|--------|
| 1 | Monthly reports auto-generate | `0 23 * * *` | diario 23:00 UTC | `monthly-reports` |
| 2 | Nightly rankings recalculation | `0 2 * * *` | diario 02:00 UTC | `annual-folders` |
| 3 | Data export cleanup | `0 4 * * *` | diario 04:00 UTC | `data-export` |
| 4 | Member of the month auto-evaluate | `5 0 1 * *` | día 1 del mes, 00:05 UTC | `member-of-month` |
| 5 | Finance period closing | `0 0 1 * *` | día 1 del mes, 00:00 UTC | `finances` |
| 6 | Activity reminders | `*/5 * * * *` | cada 5 minutos | `activities` |
| 7 | Membership requests expiry | `0 * * * *` | cada hora en :00 | `membership-requests` |
| 8 | Cleanup expired sessions/tokens | `EVERY_6_HOURS` (`0 */6 * * *`) | cada 6 horas | `common` |
| 9 | Cleanup inactive FCM tokens (>90d) | `EVERY_DAY_AT_3AM` (`0 3 * * *`) | diario 03:00 UTC | `common` |

## Detalle por job

### 1. Monthly reports auto-generate

- **Archivo**: `sacdia-backend/src/monthly-reports/monthly-reports-cron.service.ts:23`
- **Método**: `handleAutoGenerate()`
- **Clase**: `MonthlyReportsCronService`
- **Propósito**: Cuando la feature flag `reports.auto_generate_enabled` está activa y el día del mes actual coincide con `reports.auto_generate_day` (default 5), genera reportes mensuales del mes anterior para todos los enrollments activos.
- **Entidades mutadas**: `monthly_reports` (getOrCreateDraft → generate), snapshots asociados.
- **Side-effects**: logs por enrollment; procesamiento iterativo en batches.
- **Condiciones skip**:
  - lock distribuido no adquirido (otra instancia en curso; TTL 23h);
  - `reports.auto_generate_enabled` ≠ `true`;
  - fecha actual ≠ `reports.auto_generate_day`;
  - reporte del enrollment ya en status distinto de `draft`.

### 2. Nightly rankings recalculation

- **Archivo**: `sacdia-backend/src/annual-folders/rankings.service.ts:66`
- **Método**: `handleRankingsRecalculation()`
- **Clase**: `RankingsService`
- **Propósito**: Recalcula rankings generales y por categoría de premio para todas las carpetas evaluadas o cerradas del año eclesiástico activo. Canon: `docs/canon/runtime-rankings.md`.
- **Entidades mutadas**: `club_annual_rankings` (upsert general + categorizadas, delete stales).
- **Side-effects**: lock distribuido (TTL 10 min) por año; logs de conteo.
- **Condiciones skip**:
  - `ConflictException` si otra ejecución tiene el lock;
  - no-op si no hay carpetas evaluadas/cerradas.

### 3. Data export cleanup

- **Archivo**: `sacdia-backend/src/data-export/data-export.service.ts:258`
- **Método**: `cleanupExpiredExports()`
- **Clase**: `DataExportService`
- **Propósito**: Marca exportes vencidos como `expired` y hace hard-delete de registros expirados + 6 meses. Limpia archivos correspondientes en Cloudflare R2.
- **Entidades mutadas**: `data_export_requests` (status, deleted_at); objetos en R2.
- **Side-effects**: R2 object deletion (fire-and-forget); logs estructurados JSON de métricas.
- **Condiciones skip**: no-op si no hay objetos expirados; advertencias si R2 falla (continúa ejecución).

### 4. Member of the month auto-evaluate

- **Archivo**: `sacdia-backend/src/member-of-month/member-of-month-cron.service.ts:23`
- **Método**: `handleAutoEvaluate()`
- **Clase**: `MemberOfMonthCronService`
- **Propósito**: Evalúa el "miembro del mes" del mes anterior para cada sección activa. Procesa en lotes de 10 con timeout de 5 minutos. El offset `5 0 1 * *` (00:05) evita race conditions contra jobs de midnight.
- **Entidades mutadas**: `member_of_month` y agregados de scoring (vía `memberOfMonthService.runEvaluation`).
- **Side-effects**: logs por sección (éxito/fallo); posible emisión de notificación al ganador (feature implementada en MoM service, ver `docs/features/member-of-month.md`).
- **Condiciones skip**: no-op si no hay secciones activas; timeout de 5 min por lote (continúa en siguiente ejecución mensual).

### 5. Finance period closing

- **Archivo**: `sacdia-backend/src/finances/finance-period.service.ts:122`
- **Método**: `handleMonthlyClosing()`
- **Clase**: `FinancePeriodService`
- **Propósito**: Cierra período financiero del mes anterior para todos los clubs activos. Crea `financePeriodClosing` con breakdown por categoría y sección.
- **Entidades mutadas**: `financePeriodClosing` (create por club). Solo lectura de `finances`, `club_sections`, `finances_categories`.
- **Side-effects**: logs por club; batch de 50 clubs por iteración.
- **Condiciones skip**: skip si ya existe closing para `(club_id, year, month)`; errores por club se loguean y continúan batch.

### 6. Activity reminders

- **Archivo**: `sacdia-backend/src/activities/activities-reminder.service.ts:24`
- **Método**: `handleActivityReminders()`
- **Clase**: `ActivitiesReminderService`
- **Propósito**: Envía notificaciones FCM push a miembros de sección aproximadamente `N` minutos (default 60) antes de que una actividad comience hoy.
- **Entidades mutadas**: `activities.reminder_sent = true` por actividad notificada.
- **Side-effects**: push FCM vía `NotificationsService.sendToClubMembers` con `source: 'activities:reminder'` (ver `docs/canon/runtime-communications.md`).
- **Condiciones skip**:
  - lock no adquirido (otra instancia en curso);
  - sin candidatos dentro de la ventana de recordatorio;
  - actividades con parsing de tiempo inválido se loguean y se omiten.

### 7. Membership requests expiry

- **Archivo**: `sacdia-backend/src/membership-requests/membership-requests-cron.service.ts:19`
- **Método**: `handleExpiry()`
- **Clase**: `MembershipRequestsCronService`
- **Propósito**: Expira solicitudes de membresía pendientes más antiguas que el timeout definido en `system_config` (default 8 días).
- **Entidades mutadas**: `membership_requests` (status → expired vía service).
- **Side-effects**: lock distribuido (TTL 55 min); logs de conteo.
- **Condiciones skip**: lock no adquirido; fallos del servicio se loguean sin throw.

### 8. Cleanup expired sessions/tokens

- **Archivo**: `sacdia-backend/src/common/services/cleanup.service.ts:29`
- **Método**: `cleanupExpiredRecords()`
- **Clase**: `CleanupService`
- **Propósito**: Elimina sesiones y tokens de verificación cuya `expiresAt < now`.
- **Entidades mutadas**: `session`, `verification` (`deleteMany`).
- **Side-effects**: logs de conteo eliminado. **Este job NO desactiva tokens FCM** — esa política vive en `notifications.processor.ts:822-843` durante el envío (ver `docs/canon/runtime-communications.md` §8).
- **Condiciones skip**: no-op si no hay registros vencidos; errores de query se capturan y loguean sin throw.

### 9. Cleanup inactive FCM tokens

- **Archivo**: `sacdia-backend/src/common/services/cleanup.service.ts:65`
- **Método**: `cleanupInactiveFcmTokens()`
- **Clase**: `CleanupService` (misma clase que job 8)
- **Propósito**: Purga filas de `user_fcm_tokens` con `active = false` y `modified_at < now() - 90 días`. Complementa la desactivación automática por error permanente FCM (`notifications.processor.ts:822-843`) evitando crecimiento indefinido de la tabla.
- **Entidades mutadas**: `user_fcm_tokens` (`deleteMany`).
- **Side-effects**: logs de inicio (con `cutoff` ISO) + fin (con `count`); `logger.error` con stack trace en caso de fallo, sin throw.
- **Condiciones skip**: no-op si no hay filas inactivas; errores capturados y loggeados.

## Política común canonizada

1. **Timezone**: todos los jobs operan en UTC. La conversión a hora local es responsabilidad del cliente que presenta los datos.
2. **Idempotencia**: cada job debe ser seguro de re-ejecutar. Los mecanismos habilitadores son lock distribuido (jobs 1, 2, 6, 7), verificación de estado previo (3, 4, 5) o `deleteMany` con condición temporal (8).
3. **Fire-and-forget**: fallos dentro de un job no deben propagarse fuera del job. Los errores se loguean con contexto suficiente para diagnóstico posterior.
4. **Batching**: jobs con alcance masivo (1, 5, 4) procesan en lotes con timeout propio. El batch siguiente se recupera en la próxima ejecución programada.
5. **Logging estructurado**: los jobs críticos (1, 2, 3, 7) emiten logs con métricas contables (procesados, omitidos, fallidos).

## Feature flags / system_config

| Job | Flag o config | Default |
|-----|---------------|---------|
| 1. monthly-reports | `reports.auto_generate_enabled` | `false` |
| 1. monthly-reports | `reports.auto_generate_day` | `5` |
| 7. membership-requests | `membership.pending_timeout_days` | `8` |
| 6. activities-reminder | `activities.reminder_window_minutes` | `60` |

El resto de jobs no tiene feature flag; están siempre activos una vez `ScheduleModule` arranca.

## Requisitos funcionales

1. Ningún job puede ejecutarse concurrentemente consigo mismo en múltiples instancias sin coordinar vía lock.
2. Los jobs deben respetar el timezone UTC consistentemente — tanto en la expresión cron como en la lógica interna que compara fechas.
3. Los jobs que mutan datos críticos (monthly-reports, rankings, finance-period, member-of-month) deben ser idempotentes ante re-ejecución.
4. Los jobs que emiten FCM (activities-reminder) deben respetar las preferencias opt-out del usuario (ver `docs/canon/runtime-communications.md` §7).
5. Los jobs gobernados por feature flag deben leer el flag en cada ejecución, no en el arranque del módulo.

## Relación con canon

- `docs/canon/runtime-sacdia.md` — topología general del runtime;
- `docs/canon/runtime-rankings.md` — política del cron de rankings (job 2);
- `docs/canon/runtime-communications.md` — política de emisión FCM (job 6);
- `docs/features/monthly-reports.md`, `docs/features/member-of-month.md`, `docs/features/annual-folders-scoring.md` — detalle funcional por dominio.

## Gaps y pendientes

- **Sin dashboard operativo de jobs**: no hay superficie admin para ver última ejecución, tiempo de ejecución, tasa de fallo por job. Consumo actual: logs del servidor.
- **Sin alerting automático**: fallos se loguean pero no disparan alerta inmediata.
- **`reports.auto_generate_enabled` default false**: la generación automática de reportes mensuales está en dark launch; en producción requiere activación manual por ambiente.
- **Cleanup de FCM tokens desactivados antiguos**: no existe job dedicado que purgue filas con `active = false` anteriores a una ventana (los tokens se desactivan pero quedan). Ver §8.

## Observabilidad admin

**Estado**: IMPLEMENTADO 2026-04-22.

El admin tiene dos superficies complementarias de observabilidad: BullMQ (colas) y cron_run_log (ejecuciones de `@Cron`).

### Colas BullMQ (lector transitorio)

- Endpoint: `GET /api/v1/admin/analytics/jobs-overview` (guards `JwtAuthGuard` + `GlobalRolesGuard` + `@GlobalRoles('admin', 'super_admin')`).
- Servicio: `sacdia-backend/src/analytics/jobs-overview.service.ts` con `@InjectQueue` de las 3 colas vigentes: `notifications`, `achievements`, `data-exports`.
- Módulo: `AnalyticsModule` registra las 3 colas condicionalmente via `isRedisConfigured()` (patrón convencional del proyecto); si Redis no está configurado, el endpoint responde `503 ServiceUnavailableException` en lugar de crashear al boot.
- Response:
  ```
  { queues: [{ name, waiting, active, completed, failed, delayed, paused }], recent_failed: [{ job_id, queue, name, failed_reason, attempts, timestamp }] }
  ```
- Es lector puro del estado transitorio de BullMQ (no persiste, no muta).

### Cron runs (persistencia histórica)

- Tabla: `cron_run_log` (`sacdia-backend/prisma/schema.prisma`). Migración manual: `prisma/migrations/20260422000000_add_cron_run_log/migration.sql`.
- Helper reusable: `CronRunLogger` en `sacdia-backend/src/common/services/cron-run-logger.service.ts` con métodos `track(jobName, fn, meta?)` y `trackSkipped(jobName, reason?)`. Exportado desde `CommonModule` (global).
- Instrumentación: los 9 `@Cron` envuelven su lógica en `cronLogger.track(...)` retornando `{ itemsProcessed: number }` donde aplique.
- Naming canónico de jobs (columna `job_name`):
  - `monthly-reports-auto-generate`
  - `rankings-recalculate`
  - `data-export-cleanup`
  - `member-of-month-auto-evaluate`
  - `finance-period-closing`
  - `activities-reminder`
  - `membership-requests-expiry`
  - `cleanup-expired-records`
  - `fcm-tokens-cleanup`
- Status valores: `running | completed | failed | skipped` (CHECK constraint en SQL).
- Endpoint: `GET /api/v1/admin/analytics/cron-runs` — retorna `{ recent[], stats[] }`. `recent` es última ejecución por job vía `DISTINCT ON (job_name)`. `stats` agrega `avg_duration_ms_30d`, `failure_rate_7d`, `last_success`, `last_failure`, `total_runs_7d` por job.
- Sin dependencia de Redis — siempre disponible.

### Página admin

`/dashboard/system/jobs` — Server Component `revalidate=30` con `Promise.allSettled` sobre ambos endpoints:
- Sección "Colas BullMQ": cards por cola (failed en rojo si > 0), tabla de últimos 20 fallos con tooltip, refresh button.
- Sección "Cron Jobs": tabla con las 9 rows siempre visibles (join con lista hardcoded), columnas Job / Última ejecución / Status / Duración / Items / Último éxito / Último fallo / Tasa fallo 7d / Runs 7d. Status badges coloreados.
- Degradación grácil: si una de las 2 llamadas falla, la otra renderiza normalmente.
- Nav: entrada "Jobs & Colas" en sección Sistema, icon `Activity`, permiso `system_config:read`.

### Alerting Sentry

**Estado**: IMPLEMENTADO 2026-04-22.

Sentry `@sentry/node` ya estaba instalado e inicializado en `main.ts`. Integración agregada en 4 puntos guardados por `SENTRY_DSN` env var:
- `common/services/cron-run-logger.service.ts` — `track()` catch block: `Sentry.captureException(err, { tags: { job_name, cron: true }, extra: { duration_ms, metadata, run_id } })` antes del re-throw.
- 3 BullMQ processors (`notifications`, `achievements`, `data-export`) — `worker.on('failed', ...)` ahora emite `Sentry.captureException` con tags `{ bullmq, queue, job_name }` + extra `{ job_id, attempts, failed_reason }`.

Threshold alerting (failure_rate > umbral) se configura en la UI de Sentry via issue grouping rules — no requiere polling backend.

### Replay/retry BullMQ

**Estado**: IMPLEMENTADO 2026-04-22.

- Endpoint: `POST /api/v1/admin/analytics/jobs/:queue/:jobId/retry` (`@GlobalRoles('super_admin')` — más restrictivo que lectura).
- Servicio: `jobs-overview.service.ts` método `retryFailedJob(queueName, jobId)`:
  - `NotFoundException` si cola o job no existen.
  - `ConflictException` (409) si job está `active`.
  - `BadRequestException` (400) si job no está `failed`.
  - Llama `job.retry()` de BullMQ 5.x.
- UI: botón "Retry" por fila en tabla de failed jobs con `AlertDialog` de confirmación shadcn, `toast` sonner on success/error, `router.refresh()`. Disabled si `job_id === null` o si hay retry en flight para esa fila.

### Búsqueda/filtrado histórico cron runs

**Estado**: IMPLEMENTADO 2026-04-22.

- Endpoint: `GET /api/v1/admin/analytics/cron-runs/history?job_name&status&since&until&page&limit` (`@GlobalRoles('admin', 'super_admin')`).
- Servicio: `cron-runs.service.ts` método `getHistory(params)` con query Prisma paginada (`skip`/`take` + `orderBy started_at desc`), filtros dinámicos por job_name, status y rango de fechas.
- Response: `{ total, page, limit, items: CronHistoryItem[] }`. Max limit 100.
- Página admin: `/dashboard/system/jobs/history` Server Component `revalidate=0` + Client Component con filtros URL-searchParams, tabla paginada, Dialog de detalle con metadata JSON + error_message completo.
- Link "Ver historial" junto al header de sección "Cron Jobs" en `/dashboard/system/jobs`.

## Prioridad y siguiente acción

- **Prioridad**: Baja — pipeline operativo estable. Observabilidad BullMQ + cron_run_log + Sentry + retry + history cerradas.
- **Siguiente acción**: auditar permisos reutilizados sin dominio propio (3 alta prioridad identificadas: scoring-categories, requests, certifications). Análogo al caso MoM — requiere confirmación humana para decisiones pendientes.
