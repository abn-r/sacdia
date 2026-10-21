# Cron Automation (jobs programados del backend)

**Estado**: IMPLEMENTADO

<!-- VERIFICADO contra código 2026-10-21 (rama feat/admin-run-cron-now de sacdia-backend): los 20 @Cron de src/ están listados en `src/admin/cron-jobs/cron-job.registry.ts` y en el inventario de abajo. ScheduleModule registrado en app.module.ts. El job 11 (year-cut) ya no activa CRA designated ni crea member active; ledger/SQL anual no declarado aplicado a Neon. La mayoría opera en UTC; monthly report reminders opera en America/Mexico_City por ser comunicación de calendario local; cron-alert-check y fcm-tokens-stale-cleanup no declaran zona horaria. -->

## Descripción de dominio

El backend SACDIA ejecuta jobs programados que automatizan flujos institucionales recurrentes: generación de reportes mensuales, recordatorios de reportes mensuales, cierre financiero, cálculo de rankings anuales, evaluación de miembro del mes, recordatorios de actividades, expiración de solicitudes, cleanup de tokens/sesiones y limpieza de exportes vencidos, informes trimestrales y anuales, corte del año eclesiástico, alertas por jobs fallidos, recordatorios de autorización de investidura y los ciclos de edad y tutor de los perfiles familiares. En total son **20 jobs** `@Cron` (ver «Inventario de jobs»).

La mayoría de los jobs operan en **UTC** (ver «Política común canonizada»); los recordatorios de reportes mensuales operan en `America/Mexico_City` porque son mensajes de calendario local para usuarios. Dos jobs (`cron-alert-check` y `fcm-tokens-stale-cleanup`) no declaran zona horaria y usan la del proceso. Son **idempotentes por diseño** (usan locks distribuidos o verificaciones de estado previo; algunos solo dependen de la verificación de estado) y siguen un patrón **fire-and-forget** desde el scheduler — fallos dentro de un job no detienen el resto del pipeline ni propagan excepciones al caller original del endpoint que disparó el flujo.

Varios jobs están gobernados por `system_config` o feature flags (ver «Feature flags / system_config») para habilitar/deshabilitar por ambiente sin redeploy.

## Que existe (verificado contra código)

### Infraestructura

- **Módulo NestJS**: `ScheduleModule.forRoot()` registrado en `sacdia-backend/src/app.module.ts:75`.
- **Timezone**: UTC explícito (`timeZone: 'UTC'`) en 17 de los 20 jobs. Excepciones: `monthly-reports-reminders` usa `{ timeZone: 'America/Mexico_City' }`; `cron-alert-check` y `fcm-tokens-stale-cleanup` no pasan `timeZone` y corren en la zona del proceso del servidor.
- **Locks distribuidos**: 11 jobs toman un lock en Redis (`DistributedLockService.tryAcquire`) para evitar ejecución concurrente entre múltiples instancias (ver cada job para clave y TTL). Los demás (`rankings-recalculate`, `finance-period-closing`, `data-export-cleanup`, `member-of-month-auto-evaluate`, `cleanup-expired-records`, `fcm-tokens-cleanup`, `fcm-tokens-stale-cleanup`, `cron-alert-check`, `investiture-achievement-intent`) no tienen lock a nivel del `@Cron` y dependen de la idempotencia del trabajo o de un lock interno (rankings: lock por año dentro del recálculo).
- **Logging**: estructurado vía `Logger` de NestJS; fallos por entidad se loguean y continúan con el siguiente elemento del batch.
- **Los `@Cron` corren dentro del proceso de la API.** `ScheduleModule` vive en el mismo proceso NestJS: si el servicio está dormido, **ningún cron corre**. El servicio `development` ("API Sacdia", plan Free de Render) se suspende tras unos 15 minutos sin tráfico y la primera petición paga un arranque en frío (en la observación del 2026-10-21, unos 24 s); todas las entradas de `cron_run_log` se detuvieron desde el 2026-10-20 20:30 UTC hasta que se despertó el servicio. Afecta a **todos** los jobs (purgas, recordatorios, vencimientos, barridos). Decisión del 2026-10-21: se deja así en desarrollo; **producción necesita un plan de pago siempre encendido** (ver `docs/deployment/DEPLOYMENT-GUIDE.md`, §0.6, punto 10). No confíes en la hora de un cron en `development`: consulta `cron_run_log` y, si necesitas que corra uno, usa «Ejecutar ahora» (ver «Observabilidad admin»). Alternativas descartadas por ahora, si algún día hiciera falta fiabilidad en desarrollo: un ping externo de keep-alive, o mover los crones a Render Cron Jobs o GitHub Actions que llamen a endpoints internos protegidos.

### Inventario de jobs

Los 20 jobs coinciden con la allowlist `CRON_JOB_DEFINITIONS` de `src/admin/cron-jobs/cron-job.registry.ts` (un spec escanea las fuentes y falla si un `@Cron` aparece o desaparece sin entrada). La columna «Job» muestra el nombre de `cron_run_log.job_name` (`jobName` del registro). «Notifica» marca los jobs que envían **avisos reales** (push, bandeja o correo) a personas.

| # | Job (`job_name`) | Cron | Frecuencia efectiva | Módulo | Notifica |
|---|------------------|------|---------------------|--------|----------|
| 1 | Monthly reports auto-generate (`monthly-reports-auto-generate`) | `0 23 * * *` | diario 23:00 UTC | `monthly-reports` | No |
| 2 | Monthly reports reminders (`monthly-reports-reminders`) | `0 9 * * *` | diario 09:00 America/Mexico_City, emite solo dias 27/1/4/5/6 | `monthly-reports` | Sí (push) |
| 3 | Nightly rankings recalculation (`rankings-recalculate`) | `0 2 * * *` | diario 02:00 UTC | `annual-folders` | No |
| 4 | Data export cleanup (`data-export-cleanup`) | `0 4 * * *` | diario 04:00 UTC | `data-export` | No |
| 5 | Member of the month auto-evaluate (`member-of-month-auto-evaluate`) | `5 0 1 * *` | día 1 del mes, 00:05 UTC | `member-of-month` | Sí (push/bandeja a ganadores y directores) |
| 6 | Finance period closing (`finance-period-closing`) | `0 0 1 * *` | día 1 del mes, 00:00 UTC | `finances` | No |
| 7 | Activity reminders (`activities-reminder`) | `*/15 * * * *` | cada 15 minutos UTC | `activities` | Sí (push) |
| 8 | Membership requests expiry (`membership-requests-expiry`) | `3 * * * *` | cada hora en el minuto :03 UTC | `membership-requests` | No |
| 9 | Cleanup expired sessions/tokens (`cleanup-expired-records`) | `EVERY_6_HOURS` (`0 */6 * * *`) | cada 6 horas UTC | `common` | No |
| 10 | Cleanup inactive FCM tokens >90d (`fcm-tokens-cleanup`) | `EVERY_DAY_AT_3AM` (`0 3 * * *`) | diario 03:00 UTC | `common` | No |
| 11 | **Ecclesiastical year cut** (`ecclesiastical-year-cut`) | `5 6 * * *` | diario 06:05 UTC (~00:05 CST / ~23:05 CDT México) | `year-cut` | Sí, condicional (solo si omite un plan de directiva: aviso a `super-admin`, `admin` y la dirección del campo local) |
| 12 | Investiture achievement intent (`investiture-achievement-intent`) | `*/5 * * * *` | cada 5 minutos UTC, y también al arrancar | `investiture-requests` | No |
| 13 | Investiture authorization reminders (`investiture-authorization-reminders`) | `*/15 * * * *` | cada 15 minutos UTC; envía a las 10:00 locales de cada Campo | `investiture-requests` | Sí (correo) |
| 14 | Annual reports auto-generate (`annual-reports-auto-generate`) | `0 2 1 1 *` | 1 de enero, 02:00 UTC | `annual-reports` | No |
| 15 | Quarterly reports auto-generate (`quarterly-reports-auto-generate`) | `0 1 1 1,4,7,10 *` | día 1 de enero, abril, julio y octubre, 01:00 UTC | `quarterly-reports` | No |
| 16 | Cron alert check (`cron-alert-check`) | `5,20,35,50 * * * *` | cada 15 minutos (minutos :05, :20, :35, :50), zona del proceso | `common` | Sí (correo + bandeja a super-admin) |
| 17 | Stale FCM tokens cleanup (`fcm-tokens-stale-cleanup`) | `0 3 * * 0` | domingos 03:00, zona del proceso | `notifications` | No |
| 18 | Dependent profiles purge (`dependent-profiles-purge`) | `20 4 * * *` | diario 04:20 UTC | `guardianships` | No |
| 19 | Pending teen guardian (`pending-teen-guardian`) | `40 4 * * *` | diario 04:40 UTC | `guardianships` | Sí (push + bandeja al adolescente) |
| 20 | Family age transitions (`family-age-transitions`) | `0 14 * * *` | diario 14:00 UTC | `guardianships` | Sí (push + bandeja a tutores) |

Notas del inventario:

- Los jobs 1, 3 y 6 delegan el trabajo a una cola BullMQ cuando hay Redis (5 intentos, backoff exponencial desde 1 min); sin Redis corren en línea y sin reintento. Los otros 17 corren en el propio `@Cron`.
- `fcm-tokens-cleanup` era el nombre de `@Cron` de **dos** métodos: el job 10 (`CleanupService.cleanupInactiveFcmTokens`, inactivos >90 d, registra corrida) y el job 17 (`FcmTokensService.cleanupOldTokens`, `last_used` >90 d, no registra corrida). Con el nombre duplicado, solo uno de los dos se programaba. Corregido en la rama `feat/admin-run-cron-now` (sin hash todavía): el `@Cron` del job 17 pasa a llamarse `fcm-tokens-stale-cleanup`, igual que en el registro de crones.
- No registran fila en `cron_run_log` tres jobs: `cron-alert-check` (16), `fcm-tokens-stale-cleanup` (17) e `investiture-achievement-intent` (12). Los otros 17 sí.

## Detalle por job

### 1. Monthly reports auto-generate

- **Archivo**: `sacdia-backend/src/monthly-reports/monthly-reports-cron.service.ts`
- **Método**: `handleAutoGenerate()` (lógica en `MonthlyReportsService.runAutoGeneration()`)
- **Clase**: `MonthlyReportsCronService`
- **Propósito**: Cuando la feature flag `reports.auto_generate_enabled` está activa, **concilia a diario todos los periodos vencidos** de los enrollments activos: genera los informes mensuales que faltan y los borradores cuyo corte ya pasó. El corte de cada periodo es el día `reports.auto_generate_day` (entero 1–28, default 5; si el valor es inválido se usa 5) del mes siguiente a las 23:00 UTC. Ya no depende de que el cron corra justo ese día.
- **Entidades mutadas**: `monthly_reports` (getOrCreateDraft → generate), snapshots asociados.
- **Side-effects**: con Redis encola un job BullMQ (`BackgroundJobName.MONTHLY_REPORTS_AUTO_GENERATE`, 5 intentos con backoff exponencial desde 1 min) y la fila de `cron_run_log` la escribe el worker; sin Redis ejecuta en línea y sin reintento. Logs por enrollment; procesamiento en batches.
- **Lock**: Redis `cron:monthly-reports-auto-generate`, TTL 23 h; se libera justo después de encolar (evita doble encolado entre instancias, no cubre la ejecución del worker).
- **Condiciones skip**:
  - lock distribuido no adquirido (otra instancia en curso);
  - `reports.auto_generate_enabled` ≠ `true`;
  - periodo cuyo corte aún no llegó;
  - informe del periodo ya en status distinto de `draft`.

### 2. Monthly reports reminders

- **Archivo**: `sacdia-backend/src/monthly-reports/monthly-reports-reminder-cron.service.ts`
- **Cron**: `0 9 * * *`, zona `America/Mexico_City`
- **Lock**: Redis `cron:monthly-reports-reminders`, TTL 23 h
- **Método**: `handleReminderNotifications()` (lógica en `MonthlyReportsService.runReminderNotifications()`)
- **Clase**: `MonthlyReportsReminderCronService`
- **Propósito**: Notificar a director y secretario de cada sección activa sobre la captura/cierre/disponibilidad del informe mensual.
- **Calendario funcional**:
  - día 27: registrar avances del mes actual;
  - día 1: quedan 5 días para cerrar el informe del mes anterior;
  - día 4: último recordatorio;
  - día 5: registro cerrado;
  - día 6: informe generado/disponible, solo si el informe existe en estado `generated` o `submitted`.
- **Destinatarios**: roles de club `director`, `secretary` y `secretary-treasurer`; no incluye subdirector.
- **Side-effects**: `NotificationsService.sendToSectionRole()` con source `monthly_reports:reminder` y categoría móvil `reminders`.
- **Condiciones skip**:
  - lock distribuido no adquirido;
  - `reports.reminders_enabled` = `false` (cualquier otro valor, o sin fila, deja los recordatorios activos);
  - día fuera del calendario programado;
  - sección sin director/secretario activo o usuarios con opt-out de `reminders`.

### 3. Nightly rankings recalculation

- **Archivo**: `sacdia-backend/src/annual-folders/rankings.service.ts`
- **Método**: `handleRankingsRecalculation()`
- **Clase**: `RankingsService`
- **Cron**: `0 2 * * *` UTC. El `@Cron` se llama `annual-folders-rankings-recalc`, pero la fila de `cron_run_log` usa `rankings-recalculate` (el nombre del registro de crones).
- **Cola**: con Redis encola un job BullMQ (5 intentos, backoff exponencial) y el worker registra la corrida; sin Redis recalcula en línea sin reintento. El cron nocturno recalcula solo rankings de **clubes**; los de miembros se piden por HTTP.
- **Propósito**: Recalcula rankings generales y por categoría de premio para todas las carpetas evaluadas o cerradas del año eclesiástico activo. Canon: `docs/canon/runtime-rankings.md`.
- **Entidades mutadas**: `club_annual_rankings` (upsert general + categorizadas, delete stales).
- **Side-effects**: lock distribuido (TTL 10 min) por año; logs de conteo.
- **Condiciones skip**:
  - `AppConflictException` (`ANNUAL_FOLDER_RANKINGS_LOCK_CONFLICT`) si otra ejecución tiene el lock;
  - kill-switch `ranking.recalculation_enabled` = `false` (devuelve `skipped`);
  - no-op si no hay carpetas evaluadas/cerradas.

### 4. Data export cleanup

- **Archivo**: `sacdia-backend/src/data-export/data-export.service.ts`
- **Método**: `cleanupExpiredExports()`
- **Clase**: `DataExportService`
- **Cron**: `0 4 * * *` UTC; sin lock a nivel del `@Cron`.
- **Propósito**: Marca exportes vencidos como `expired` y hace hard-delete de registros expirados + 6 meses. Limpia archivos correspondientes en Cloudflare R2.
- **Entidades mutadas**: `data_export_requests` (status, deleted_at); objetos en R2.
- **Side-effects**: R2 object deletion (fire-and-forget); logs estructurados JSON de métricas.
- **Condiciones skip**: no-op si no hay objetos expirados; advertencias si R2 falla (continúa ejecución).

### 5. Member of the month auto-evaluate

- **Archivo**: `sacdia-backend/src/member-of-month/member-of-month-cron.service.ts`
- **Método**: `handleAutoEvaluate()`
- **Clase**: `MemberOfMonthCronService`
- **Propósito**: Evalúa el "miembro del mes" del mes anterior para cada sección activa. Procesa en lotes de 10 con timeout de 5 minutos. El offset `5 0 1 * *` (00:05) evita race conditions contra jobs de midnight.
- **Entidades mutadas**: `member_of_month` y agregados de scoring (vía `memberOfMonthService.runEvaluation`).
- **Side-effects**: logs por sección (éxito/fallo); **notifica**: por cada sección evaluada, `MemberOfMonthService` avisa a cada ganador (fuente `units:member_of_month`) y a los directores, subdirectores y `directora` de la sección (fuente `units:member_of_month_director`), solo si son destinatarios de datos de club alcanzables; es no bloqueante (ver `docs/features/member-of-month.md`). Sin lock a nivel del `@Cron`.
- **Condiciones skip**: no-op si no hay secciones activas; timeout de 5 min por lote (continúa en siguiente ejecución mensual).

### 6. Finance period closing

- **Archivo**: `sacdia-backend/src/finances/finance-period.service.ts`
- **Método**: `handleMonthlyClosing()`
- **Clase**: `FinancePeriodService`
- **Propósito**: Cierra el período financiero del **mes calendario anterior en UTC** para todos los clubs activos. El cron corre `0 0 1 * *` UTC; `previousUtcMonth()` usa `getUTCMonth`/`getUTCFullYear` para no cerrar el mes -2 en zonas UTC-oeste (p. ej. México). Crea o deja intacto `finance_period_closings` con breakdown por categoría y sección.
- **Entidades mutadas**: `finance_period_closings` (create por club). Solo lectura de `finances`, `club_sections`, `finances_categories`.
- **Side-effects**: con Redis encola un job BullMQ (5 intentos, backoff exponencial desde 1 min); sin Redis cierra en línea sin reintento. Logs por club; batch de 50 clubs por iteración. Sin lock a nivel del `@Cron`.
- **Condiciones skip**: skip si ya existe closing para `(club_id, year, month)`; errores por club se loguean y continúan batch.
- **Rebuild**: `tsx scripts/rebuild-finance-period-closings.ts --apply` regenera meses ya cerrados del año eclesiástico activo con `closed_at` = 00:00 UTC del día 1 del mes siguiente (el instante en que el cron UTC debió correr).

### 7. Activity reminders

- **Archivo**: `sacdia-backend/src/activities/activities-reminder.service.ts`
- **Método**: `handleActivityReminders()`
- **Clase**: `ActivitiesReminderService`
- **Cron**: `*/15 * * * *` UTC (cada 15 minutos).
- **Lock**: Redis `cron:activities-reminder`, TTL 14 min.
- **Propósito**: Envía notificaciones FCM push a la audiencia de la actividad aproximadamente `N` minutos (`activity_reminder_minutes_before`, default 60) antes de que comience hoy. La audiencia depende de `activities.audience`: directiva (`sendToSectionRole`), clases concretas, o todos los miembros de la sección (`sendToClubMembers`).
- **Entidades mutadas**: `activities.reminder_sent = true` por actividad notificada.
- **Side-effects**: push FCM vía `NotificationsService` (`sendToSectionRole` / `sendToClubMembers` / envío por clase) con `source: 'activities:reminder'` (ver `docs/canon/runtime-communications.md`).
- **Condiciones skip**:
  - lock no adquirido (otra instancia en curso);
  - sin candidatos dentro de la ventana de recordatorio;
  - actividades con parsing de tiempo inválido se loguean y se omiten.

### 8. Membership requests expiry

- **Archivo**: `sacdia-backend/src/membership-requests/membership-requests-cron.service.ts`
- **Método**: `handleExpiry()`
- **Clase**: `MembershipRequestsCronService`
- **Cron**: `3 * * * *` UTC (cada hora, en el minuto :03).
- **Propósito**: Expira solicitudes de membresía pendientes más antiguas que el timeout definido en `system_config` (default 8 días).
- **Entidades mutadas**: `membership_requests` (status → expired vía service).
- **Side-effects**: lock distribuido `cron:membership-requests-expiry` (TTL 55 min); logs de conteo.
- **Condiciones skip**: lock no adquirido; fallos del servicio se loguean sin throw.

### 9. Cleanup expired sessions/tokens

- **Archivo**: `sacdia-backend/src/common/services/cleanup.service.ts`
- **Método**: `cleanupExpiredRecords()`
- **Clase**: `CleanupService`
- **Cron**: `CronExpression.EVERY_6_HOURS` UTC; sin lock.
- **Propósito**: Elimina sesiones y tokens de verificación cuya `expiresAt < now`.
- **Entidades mutadas**: `session`, `verification` (`deleteMany`).
- **Side-effects**: logs de conteo eliminado. **Este job NO desactiva tokens FCM** — esa política vive en `notifications.processor.ts:822-843` durante el envío (ver `docs/canon/runtime-communications.md` §8).
- **Condiciones skip**: no-op si no hay registros vencidos; errores de query se capturan y loguean sin throw.

### 10. Cleanup inactive FCM tokens

- **Archivo**: `sacdia-backend/src/common/services/cleanup.service.ts`
- **Método**: `cleanupInactiveFcmTokens()`
- **Clase**: `CleanupService` (misma clase que el job 9)
- **Cron**: `CronExpression.EVERY_DAY_AT_3AM` UTC; sin lock. No confundir con el job 17 (`fcm-tokens-stale-cleanup`), cuyo `@Cron` compartía el nombre `fcm-tokens-cleanup` hasta el renombrado de la rama `feat/admin-run-cron-now` (ver nota del inventario).
- **Propósito**: Purga filas de `user_fcm_tokens` con `active = false` y `modified_at < now() - 90 días`. Complementa la desactivación automática por error permanente FCM (`notifications.processor.ts:822-843`) evitando crecimiento indefinido de la tabla.
- **Entidades mutadas**: `user_fcm_tokens` (`deleteMany`).
- **Side-effects**: logs de inicio (con `cutoff` ISO) + fin (con `count`); `logger.error` con stack trace en caso de fallo, sin throw.
- **Condiciones skip**: no-op si no hay filas inactivas; errores capturados y loggeados.

### 11. Ecclesiastical year cut

- **Archivo**: `sacdia-backend/src/year-cut/year-cut-cron.service.ts`
- **Método**: `handleYearCut()`; también `onModuleInit()` (misma ruta, recuperación al arrancar)
- **Clase**: `YearCutCronService`
- **Servicio de lógica**: `YearCutService.applyCut()` (`src/year-cut/year-cut.service.ts`)
- **Propósito**: Transición anual **por club** al inicio del año eclesiástico vigente:
  1. Selecciona cargos `status=active` cuyo `ecclesiastical_years.end_date` es anterior a `currentYear.start_date`. No usa `ecclesiastical_year_id != vigente` (no cierra futuros). También incluye clubes con una solicitud de investidura `PENDING` de un año ya terminado, aunque no tengan cargos vencidos ni una transición incompleta.
  2. Termina esos cargos → `status=ended`, `active=false`, `end_date` = fin del periodo saliente (conserva un `end_date` anterior más temprano; no reescribe con `currentYear.start_date`). Cierra `class_counselor_assignments` vencidas; no crea autoridad pedagógica nueva.
  3. Activa planes `director_succession_plans` en `scheduled` con `effective_date <= currentYear.start_date` creando CRA director `status=active`. **No** activa filas CRA `designated`.
     - Si el sucesor no es elegible para `director` en esa sección (regla de Guía Mayor), el plan se **omite**: queda `scheduled`, se emite `logger.warn` (plan, usuario, código) y, tras el commit del club, se notifica (fire-and-forget, fuente `admin:year_cut_director_plan_skipped`, textos en `notifications.notifications.year_cut.*` de los 4 locales) a `super-admin`/`admin` y a `director-lf`/`assistant-lf` del campo local del club. Un fallo al notificar se loguea y no aborta el corte.
  4. Egresados de tipo: si el resolvedor de siguiente clase indica que el miembro cruza de tipo de club (`crossed_type`), escribe su inscripción anual en la sección destino (`AnnualMembershipService.writeTypeJumpEnrollment`); esos usuarios no se devuelven a `not-enrolled`.
  5. Resuelve estado final: junta AV/CQ → `member inactive` en GM vía política anual; consejero/member en **esa** sección. Si ya hay director `active` en el destino, no crea member extra. No crea clases ni `member active`. Esa política no se sustituye por un alta automática.
  6. Antes de recorrer los clubes, toma el candado del año de cada año ya terminado y cierra sus `PENDING` como `CLOSED_YEAR`. Una alta que esperaba ese candado queda incluida. El recorrido del club vuelve a cerrar lo que siga `PENDING`. No toca `INVESTED`, no escribe el texto de falta de requisitos y no copia la solicitud al año siguiente. Si la transición del club ya está `completed`, no reinscribe ni activa cargos.
- **Cron**: `5 6 * * *` UTC (~00:05 CST en horario estándar México).
- **Lock**: Redis `cron:ecclesiastical-year-cut` (TTL ~23 horas) **y** `pg_advisory_xact_lock(club_id, year_id)` dentro de la transacción por club.
- **job_name**: `ecclesiastical-year-cut` (en `cron_run_log`).
- **Entidades mutadas**: `club_role_assignments`; `director_succession_plans` (`scheduled` → `activated`); `class_counselor_assignments`; `club_year_transitions`; `authorization_context_versions` (bumpMany en tx); `investiture_authorization_people` pendientes de años terminados de ese club.
- **Notifica**: sí, solo de forma condicional: cuando omite un plan de sucesión de director (paso 3), avisa a `super-admin`/`admin` y a `director-lf`/`assistant-lf` del campo local (`notifySkippedDirectorPlans` → `sendToGlobalRole`, `src/year-cut/year-cut.service.ts`). Sin planes omitidos no envía nada.
- **Side-effects**: `AuthorizationContextService.invalidateUserAuthorizationCache` por usuario afectado (post-commit, try/catch por usuario). Fallo de caché/FCM **no** revierte ni duplica el corte. **NO llama** `YearEndService.closeYear`. **NO hace blacklist de JWT**.
- **Idempotencia**: ledger `club_year_transitions` único `(club_id, ecclesiastical_year_id)`. Si `status=completed`, no repite cargos ni `ensureNotEnrolled`, pero sí vuelve a cerrar pendientes de investidura que hayan quedado: el `updateMany` solo coincide con `PENDING`. Reintento con `in_progress`/fallo relee candidatos bajo lock y reutiliza `ensureNotEnrolled`.
- **Retorno**: `{ ended, activated, returnedNotEnrolled, typeGraduatesEnrolled, usersInvalidated, investiturePendingClosed }`. `itemsProcessed` del cron = ended + activated + returnedNotEnrolled + typeGraduatesEnrolled. Ya no existe `gmMembersCreated` ni `ghostsMarked`.
- **Condiciones skip**: lock Redis no adquirido (`trackSkipped`); ningún club candidato y ningún pendiente de investidura de un año terminado (log + return temprano). Si solo hay esos pendientes, el barrido los cierra y no recorre cargos. Una transición `completed` no repite la continuidad anual.
- **Migraciones**: `20260908180000_director_year_slots`, `20260909120000_annual_membership_cycle` (ledger + unique member) y `20260909130000_director_succession_open_unique` aplicadas a Neon development (2026-09-11).

### 12. Investiture achievement intent

- **Archivo**: `sacdia-backend/src/investiture-requests/investiture-achievement-intent.reconciler.ts`
- **Método**: `reconcile()` y `onModuleInit()`
- **Clase**: `InvestitureAchievementIntentReconciler`
- **Cron**: `*/5 * * * *`, zona `UTC`. Sin lock Redis y **sin fila en `cron_run_log`** (solo loguea; los errores se capturan y no se propagan).
- **Propósito**: entregar `class.completed` de una investidura ya confirmada si el insert o la cola fallaron. También corre al arrancar. No autoriza de nuevo y no envía correo.
- **Condiciones**: solo filas `INVESTED` con `achievement_intent_key` cuyo evento no está `processed`. El año, la ventana y la asignación pueden estar cerrados.

### 13. Investiture authorization reminders

- **Archivo**: `sacdia-backend/src/investiture-requests/investiture-reminder.cron.ts`
- **Método**: `handle()` (despacha con `InvestitureCommunicationsService.dispatchReminders()` y reintenta con `deliverPending()`)
- **Clase**: `InvestitureReminderCron`
- **Cron**: `*/15 * * * *`, zona `UTC`
- **Notifica**: correo (Pastor y director/asistente del Campo). Está condicionado por `INVESTITURE_EMAIL_ENABLED`; apagado, `deliverPending` omite el correo y solo retoma los avisos de resultado (bandeja y push).
- **Lock**: `cron:investiture-authorization-reminders`, 14 minutos
- **Propósito**: correo de recordatorio cuando en `local_fields.timezone` son las 10:00 y el minuto es menor que 15. Pastor: lunes, miércoles y viernes, un correo por Campo con los distritos de esa persona. Director y asistente del Campo: solo lunes, un correo por rol. La corrida del día se registra por Campo y rol en `investiture_reminder_runs` aunque no haya pendientes; si la de las 10:00 no ocurrió, la primera ejecución disponible del mismo día la reclama una vez, y si ya ocurrió no hay envío tardío para destinatarios nuevos. Un Campo cuyo render falla (por ejemplo `ADMIN_PANEL_URL` vacío) libera su reclamo y no consume el día. Cada entrega de un recordatorio a la cola es un único intento ante el proveedor (`attempts: 1`). Después recupera intenciones pendientes, filas `failed`, claims `sending` con lease vencido y trabajos `queued` cuyo job falta o quedó `failed`. Un job `failed` se reactiva con el mismo id.
- **Condiciones**: el año eclesiástico del Campo tiene que estar activo y el día local dentro de `start_date` y `end_date`. Hace falta al menos un pendiente. Con la ventana cerrada el correo sigue y pide ampliarla. Sin fila de ventana se usa el mismo rango por defecto del primer envío. Esas condiciones se vuelven a leer antes de cada llamada al proveedor, también si el contenido ya está congelado. Si el destinatario, el año o los pendientes ya no corresponden, o si solo queda autorizada una parte del contenido congelado, no se envía y no se cambia el cuerpo ni la clave. Ese cuerpo, su destino y su alcance salen de la misma instantánea con la que se armó el correo. Un intento que sigue permitido y ya fue aceptado por el proveedor no se recompone: durante 24 horas se reintenta el contenido guardado y después queda `uncertain`, sin un segundo envío automático. No escribe en la bandeja del panel. No autoriza ni cierra solicitudes.

### 14. Annual reports auto-generate

- **Archivo**: `sacdia-backend/src/annual-reports/annual-reports-cron.service.ts`
- **Método**: `handleAutoGenerate()`
- **Clase**: `AnnualReportsCronService`
- **Cron**: `0 2 1 1 *`, zona `UTC` (1 de enero, 02:00).
- **Lock**: Redis `cron:annual-reports-auto-generate`, TTL 23 h.
- **Propósito**: genera los informes anuales del último año eclesiástico terminado (`end_date` anterior a hoy, el más reciente) para todos los clubes activos, vía `AnnualReportsService.autoGenerateForAllClubs()`.
- **Flag**: `reports.annual_auto_generate_enabled` debe ser `true`; sin la fila o con otro valor termina con 0 items.
- **Condiciones skip**: lock no adquirido; flag apagado; no hay año eclesiástico terminado. Los errores fatales se capturan y se loguean.
- **Notifica**: no.

### 15. Quarterly reports auto-generate

- **Archivo**: `sacdia-backend/src/quarterly-reports/quarterly-reports-cron.service.ts`
- **Método**: `handleAutoGenerate()`
- **Clase**: `QuarterlyReportsCronService`
- **Cron**: `0 1 1 1,4,7,10 *`, zona `UTC` (día 1 de enero, abril, julio y octubre, 01:00).
- **Lock**: Redis `cron:quarterly-reports-auto-generate`, TTL 23 h.
- **Propósito**: genera los informes trimestrales del trimestre recién terminado (enero → T4 del año anterior; abril → T1; julio → T2; octubre → T3) para todos los clubes activos, vía `QuarterlyReportsService.autoGenerateForAllClubs()`.
- **Flag**: `reports.quarterly_auto_generate_enabled` debe ser `true`.
- **Condiciones skip**: lock no adquirido; flag apagado. Los errores fatales se capturan y se loguean.
- **Notifica**: no.

### 16. Cron alert check

- **Archivo**: `sacdia-backend/src/common/services/cron-alert.service.ts`
- **Método**: `checkAndAlertFailures()`
- **Clase**: `CronAlertService`
- **Cron**: `5,20,35,50 * * * *`, **sin `timeZone`** (zona del proceso). Sin lock Redis y sin fila en `cron_run_log` (no se vigila a sí mismo).
- **Propósito**: lee `cron_run_log` de los jobs con corridas en las últimas 24 h y dispara una alerta cuando se cumple alguna condición: `consecutive_failures` (3 o más fallos seguidos), `duration` (una corrida completada de la última hora tardó 5 min o más) o `failure_rate` (más del 50 % de fallos en 24 h). No hay umbrales por job (el mapa de overrides está vacío).
- **Entidades mutadas**: `cron_alerts_log` (ancla de deduplicación: la misma pareja `(job_name, condition)` no vuelve a alertar durante 6 h mientras `resolved_at` sea `NULL`).
- **Notifica**: sí, a todos los usuarios activos con rol global `super-admin`: correo (`EmailService.sendCronAlert`, locale `es`) y aviso en la bandeja/push (`NotificationsService.notifySafe`, fuente `system_alert:cron_failure`). Si no hay super-admin activos, solo loguea un warning.
- **Alcance real**: solo detecta fallos, lentitud y tasa de error de corridas **registradas**. No detecta un job que dejó de correr (sin filas nuevas no hay condición), así que un servicio dormido no genera alertas.

### 17. Stale FCM tokens cleanup

- **Archivo**: `sacdia-backend/src/notifications/fcm-tokens.service.ts`
- **Método**: `cleanupOldTokens()`
- **Clase**: `FcmTokensService`
- **Cron**: `0 3 * * 0`, **sin `timeZone`** (domingos 03:00, zona del proceso). Su `@Cron` se llamaba `fcm-tokens-cleanup`, igual que el del job 10 (con el nombre duplicado, solo uno de los dos se programaba); se renombra a `fcm-tokens-stale-cleanup` en la rama `feat/admin-run-cron-now` (sin hash todavía).
- **Propósito**: `deleteMany` de `user_fcm_tokens` con `last_used` anterior a 90 días (activos o no). Complementa al job 10, que borra los inactivos por `modified_at`.
- **Registro**: no usa `CronRunLogger` (sin fila en `cron_run_log`, sin lock); errores capturados y logueados sin throw. El registro de crones ya lo nombra `fcm-tokens-stale-cleanup`.
- **Notifica**: no.

### 18. Dependent profiles purge

- **Archivo**: `sacdia-backend/src/guardianships/dependent-profiles-purge-cron.service.ts`
- **Método**: `handlePurge()` (lógica en `purgeDue()` / `purgeOne()`)
- **Clase**: `DependentProfilesPurgeCronService`
- **Cron**: `20 4 * * *`, zona `UTC`.
- **Lock**: Redis `cron:dependent-profiles-purge`, TTL 23 h.
- **Propósito**: purga los perfiles de dependientes **congelados** cuyo `purge_after` ya venció (90 días tras el congelamiento): anonimiza la fila de `users` (sin correo, `active=false`), borra datos de salud, contactos de emergencia, evidencias de consentimiento y de clases/honores, la bandeja de notificaciones y los tokens de emparejamiento, limpia los dispositivos vinculados (se conservan como auditoría) y marca `dependent_profiles.purged_at`. Tras el commit borra los objetos de R2 con mejor esfuerzo. La fila de `users` y las filas de tutela se conservan como historial legal.
- **Procesamiento**: lotes de 100; cada dependiente va en su propia transacción. Si alguno falla, el job termina en `failed` (para que `cron_run_log` y `cron-alert-check` lo reporten) y los pendientes se reintentan en la siguiente corrida.
- **Notifica**: no.

### 19. Pending teen guardian

- **Archivo**: `sacdia-backend/src/guardianships/pending-teen-cron.service.ts`
- **Método**: `handleDaily()` (lógica en `run()`)
- **Clase**: `PendingTeenCronService`
- **Cron**: `40 4 * * *`, zona `UTC`.
- **Lock**: Redis `cron:pending-teen-guardian`, TTL 23 h.
- **Propósito**: pasada diaria sobre los adolescentes autorregistrados sin tutor vinculado:
  1. Inicia el reloj (`supervised_logins.pending_since = now`) de un menor sin fila, en la **primera** evaluación (las cuentas anteriores a la función no se congelan en la primera corrida).
  2. Envía recordatorios al **adolescente** (push + bandeja, nunca correo; fuente `family:teen_reminder`) a los días 7, 30 y 83 del reloj. Tras una caída solo se manda el último recordatorio vencido, una vez.
  3. Al día 90 congela la cuenta: marca el perfil dependiente como congelado (`purge_after = now + 90 días`), deshabilita el login supervisado (`unlinked_purged`) y borra las sesiones. Un vínculo pendiente cuenta como vinculado y detiene el reloj. El borrado duro lo hace el job 18.
- **Procesamiento**: lotes de 100. Si alguno falla, el job termina en `failed` y se reintenta en la siguiente corrida. No toca a quien alcanzó la mayoría de edad.
- **Notifica**: sí (push + bandeja al adolescente).

### 20. Family age transitions

- **Archivo**: `sacdia-backend/src/guardianships/family-age-transitions-cron.service.ts`
- **Método**: `handleDaily()` (lógica en `run()`)
- **Clase**: `FamilyAgeTransitionsCronService`
- **Cron**: `0 14 * * *`, zona `UTC`.
- **Lock**: Redis `cron:family-age-transitions`, TTL 23 h.
- **Propósito**: pasada diaria sobre los hitos de edad de los dependientes de perfiles familiares:
  1. **Aviso del cumpleaños 13**: a un dependiente activo, sin cuenta (o con login deshabilitado), no congelado ni purgado y con `teen_login_nudged_at IS NULL`, cuya edad en la política de su país está entre `minSelfLoginAge` y la mayoría de edad, cada tutor verificado no custodio recibe un push + bandeja («ya puede tener su propio login», nunca correo; fuente `family:age_nudge`, silenciable por el tutor). La marca se reclama primero con compare-and-set, así que dos instancias o un reintento no duplican el aviso. Solo corre con `FAMILY_TEEN_LOGIN_ENABLED` encendido; apagado no envía ni marca nada.
  2. **Barrido de dispositivos**: revoca los dispositivos vinculados cuyo menor alcanzó la mayoría de edad (`majority`) y los que pasaron el tope absoluto de 180 días (`expired`), vía `LinkedDevicesService`, que avisa a los tutores restantes una sola vez. No depende del flag (un kill switch no debe detener el mantenimiento).
- **Procesamiento**: lotes de 100. Si alguno falla, el job termina en `failed`; el aviso fallido devuelve su claim y la revocación se reintenta en el barrido siguiente.
- **Notifica**: sí (push + bandeja a tutores; avisos de revocación a tutores).

## Política común canonizada

1. **Timezone**: los jobs operan en UTC, con tres excepciones: `monthly-reports-reminders` (`America/Mexico_City`), y `cron-alert-check` y `fcm-tokens-stale-cleanup` (sin `timeZone`, usan la zona del proceso). La conversión a hora local de lo que se muestra es responsabilidad del cliente; el job 13 convierte por Campo con `local_fields.timezone`.
2. **Idempotencia**: cada job debe ser seguro de re-ejecutar. Los mecanismos son lock distribuido en Redis (jobs 1, 2, 7, 8, 11, 13, 14, 15, 18, 19, 20), lock por año dentro del recálculo (job 3), verificación de estado previo (jobs 4, 5, 6, 12, 16), `deleteMany` con condición temporal (jobs 9, 10, 17) y ledger `club_year_transitions` + lock de transacción por club (job 11).
3. **Fire-and-forget**: fallos dentro de un job no deben propagarse fuera del job. Los errores se loguean con contexto suficiente para diagnóstico posterior. Los jobs 18, 19 y 20 marcan la corrida como `failed` si algún elemento falla, para que `cron_run_log` y `cron-alert-check` lo reporten, y reintentan en la siguiente corrida.
4. **Batching**: jobs con alcance masivo (jobs 1, 5, 6, 18, 19, 20) procesan en lotes con timeout propio o tamaño fijo. El batch siguiente se recupera en la próxima ejecución programada.
5. **Logging estructurado**: los jobs críticos (jobs 1, 2, 3, 4, 8) emiten logs con métricas contables (procesados, omitidos, fallidos). 17 de los 20 jobs persisten además cada corrida en `cron_run_log` (ver «Observabilidad admin»).

## Feature flags / system_config

| Job | Flag o config | Default |
|-----|---------------|---------|
| 1. monthly-reports-auto-generate | `reports.auto_generate_enabled` | `false` |
| 1. monthly-reports-auto-generate | `reports.auto_generate_day` (1–28) | `5` |
| 2. monthly-reports-reminders | `reports.reminders_enabled` | activo salvo valor `false` |
| 3. rankings-recalculate | `ranking.recalculation_enabled` (kill-switch) | activo salvo valor `false` |
| 7. activities-reminder | `activity_reminder_minutes_before` | `60` |
| 8. membership-requests-expiry | `membership.pending_timeout_days` | `8` |
| 13. investiture-authorization-reminders | variable de entorno `INVESTITURE_EMAIL_ENABLED` | ver `investitureEmailEnabled()` |
| 14. annual-reports-auto-generate | `reports.annual_auto_generate_enabled` | `false` (sin fila = apagado) |
| 15. quarterly-reports-auto-generate | `reports.quarterly_auto_generate_enabled` | `false` (sin fila = apagado) |
| 20. family-age-transitions | flag de familia `FAMILY_TEEN_LOGIN_ENABLED` (solo el aviso del cumpleaños 13; el barrido de dispositivos no depende de él) | ver `FamilyFeatureFlagsService` |

El resto de jobs no tiene feature flag; están siempre activos una vez `ScheduleModule` arranca.

## Requisitos funcionales

1. Ningún job puede ejecutarse concurrentemente consigo mismo en múltiples instancias sin coordinar vía lock.
2. Los jobs deben respetar el timezone UTC consistentemente — tanto en la expresión cron como en la lógica interna que compara fechas.
3. Los jobs que mutan datos críticos (monthly-reports, rankings, finance-period, member-of-month, year-cut, purga de dependientes) deben ser idempotentes ante re-ejecución.
4. Los jobs que emiten avisos (los 8 marcados «Sí» en la columna «Notifica» del inventario, uno de ellos condicional) deben respetar las preferencias opt-out del usuario cuando la categoría lo permita (ver `docs/canon/runtime-communications.md` §7).
5. Los jobs gobernados por feature flag deben leer el flag en cada ejecución, no en el arranque del módulo.

## Relación con canon

- `docs/canon/runtime-sacdia.md` — topología general del runtime;
- `docs/canon/runtime-rankings.md` — política del cron de rankings (job 3);
- `docs/canon/runtime-communications.md` — política de emisión FCM (jobs 2, 5, 7, 16, 19 y 20);
- `docs/features/monthly-reports.md`, `docs/features/member-of-month.md`, `docs/features/annual-folders-scoring.md` — detalle funcional por dominio.

## Gaps y pendientes

- **Alerting sin cobertura de «job que no corrió»**: `cron-alert-check` (job 16) avisa de fallos, lentitud y tasa de error de corridas registradas, pero no detecta un job que dejó de ejecutarse (por ejemplo, con el servicio dormido). Tres jobs no registran corrida y quedan fuera de la vigilancia: `cron-alert-check`, `fcm-tokens-stale-cleanup` e `investiture-achievement-intent`.
- **`reports.auto_generate_enabled` default false**: la generación automática de reportes mensuales está en dark launch; en producción requiere activación manual por ambiente. Lo mismo vale para `reports.annual_auto_generate_enabled` y `reports.quarterly_auto_generate_enabled`.
- **Dos limpiezas de tokens FCM que se solapan en intención** (jobs 10 y 17: inactivos por `modified_at` frente a sin uso por `last_used`). Pendiente decidir si se unifican. El nombre de `@Cron` duplicado `fcm-tokens-cleanup` (con el que solo uno de los dos se programaba) se corrigió en la rama `feat/admin-run-cron-now`, que renombra el del job 17 a `fcm-tokens-stale-cleanup` (sin hash todavía).
- **Zona del proceso en dos jobs**: `cron-alert-check` y `fcm-tokens-stale-cleanup` no declaran `timeZone`; si el proceso no corre en UTC, su hora efectiva cambia.

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
  BullMQ 6: `paused` en overview queda 0. Jobs de cola pausada viven en `waiting`. Health `GET .../queues/:queueName/health` sigue con `paused` booleano vía `queue.isPaused()`.
- Es lector puro del estado transitorio de BullMQ (no persiste, no muta).

### Cron runs (persistencia histórica)

- Tabla: `cron_run_log` (`sacdia-backend/prisma/schema.prisma`). Migración manual: `prisma/migrations/20260422000000_add_cron_run_log/migration.sql`.
- Helper reusable: `CronRunLogger` en `sacdia-backend/src/common/services/cron-run-logger.service.ts` con métodos `track(jobName, fn, meta?)` y `trackSkipped(jobName, reason?)`. Exportado desde `CommonModule` (global).
- Instrumentación: 17 de los 20 `@Cron` envuelven su lógica en `cronLogger.track(...)` retornando `{ itemsProcessed: number }` donde aplique (en los jobs 1, 3 y 6 la llamada ocurre en el worker de BullMQ cuando hay Redis). No registran corrida `cron-alert-check`, `fcm-tokens-stale-cleanup` e `investiture-achievement-intent`.
- Naming canónico de jobs (columna `job_name`):
  - `monthly-reports-auto-generate`
  - `monthly-reports-reminders`
  - `rankings-recalculate`
  - `data-export-cleanup`
  - `member-of-month-auto-evaluate`
  - `finance-period-closing`
  - `activities-reminder`
  - `membership-requests-expiry`
  - `cleanup-expired-records`
  - `fcm-tokens-cleanup`
  - `ecclesiastical-year-cut`
  - `investiture-authorization-reminders`
  - `annual-reports-auto-generate`
  - `quarterly-reports-auto-generate`
  - `dependent-profiles-purge`
  - `pending-teen-guardian`
  - `family-age-transitions`
  - (sin corrida registrada: `cron-alert-check`, `fcm-tokens-stale-cleanup`, `investiture-achievement-intent`; solo existen como nombre del registro de crones)
- Status valores: `running | completed | failed | skipped` (CHECK constraint en SQL).
- Endpoint: `GET /api/v1/admin/analytics/cron-runs` — retorna `{ recent[], stats[] }`. `recent` es última ejecución por job vía `DISTINCT ON (job_name)`. `stats` agrega `avg_duration_ms_30d`, `failure_rate_7d`, `last_success`, `last_failure`, `total_runs_7d` por job.
- Cada elemento de `recent[]` incluye `trigger` (`'manual' | 'scheduled'`) y `triggered_by` (`user_id` del super-admin de una ejecución manual, o `null`). Pendiente de merge (rama `feat/admin-run-cron-now`, ver «Ejecutar ahora»).
- Sin dependencia de Redis — siempre disponible.

### Página admin

`/dashboard/system/jobs` — Server Component `revalidate=30` con `Promise.allSettled` sobre ambos endpoints:
- Sección "Colas BullMQ": cards por cola (failed en rojo si > 0), tabla de últimos 20 fallos con tooltip, refresh button.
- Sección "Cron Jobs": tabla con las 20 rows siempre visibles (catálogo de `GET /admin/cron-jobs`; si no responde, cae a la lista de nombres conocida en `src/lib/system/cron-jobs.ts`), columnas Job / Última ejecución / Status / Duración / Items / Último éxito / Último fallo / Tasa fallo 7d / Runs 7d. Status badges coloreados.
- Degradación grácil: si una de las 2 llamadas falla, la otra renderiza normalmente.
- Nav: entrada "Jobs & Colas" en sección Sistema, icon `Activity`, permiso `system_config:read`.

### Ejecutar ahora (jobs bajo demanda)

**Estado**: IMPLEMENTADO en las ramas `feat/admin-run-cron-now` de sacdia-backend (commits `2bacda55` y `bb57a925`) y sacdia-admin (commits `34d9e4e`, `ac40318`, `1c21151` y `5026a0a`), **pendiente de merge**. Contrato y errores completos en `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, «Jobs programados bajo demanda».

- **Para qué.** Con el servicio de `development` dormido los crones no corren (ver «Infraestructura»). Un super-admin puede ejecutar un job a mano; es la forma de correrlos en desarrollo.
- **API** (solo `super-admin`, 10 por minuto): `GET /api/v1/admin/cron-jobs` (los 20 jobs de la allowlist con su cron de 5 campos, zona horaria y si son ejecutables) y `POST /api/v1/admin/cron-jobs/:jobName/run` (200; espera al job; 404 `CRON_JOB_NOT_FOUND` si no está en la lista). Ejecuta el mismo método que el scheduler, con el **mismo candado** y la **misma fila** de `cron_run_log`, marcada `metadata.trigger = 'manual'` y `metadata.triggered_by`. Añade un candado `cron-manual:<job>`: un job que ya corre responde `skipped`. Los jobs respaldados por BullMQ (`monthly-reports-auto-generate`, `rankings-recalculate`, `finance-period-closing`) devuelven `enqueued: true` cuando hay Redis y terminan en el worker. Audita `admin.cron_job.run`.
- **Allowlist.** Los 20 `@Cron` del código, uno por uno (`src/admin/cron-jobs/cron-job.registry.ts`); un spec escanea las fuentes y falla si aparece o desaparece un `@Cron` sin entrada, así que añadir un job obliga a decidir si se expone. El inventario de arriba lista los mismos 20 jobs que la allowlist (antes listaba 12). `fcm-tokens-stale-cleanup` es el `cleanupOldTokens` de `FcmTokensService` (job 17), que compartía nombre de scheduler con `cleanup.service.ts` hasta el renombrado de la rama, y no registra corrida.
- **Panel**: en `/dashboard/system/jobs`, columna «Acciones» con «Ejecutar ahora» y un `AlertDialog` de confirmación, visible solo para un super-admin y en los 20 jobs del catálogo (todos son ejecutables, `runnable: true`). Muestra la insignia «Manual» y, si `enqueued` es `true`, el aviso «En cola». Si la petición se corta (408, 502 o 504) avisa que la ejecución sigue en el servidor y refresca el historial.
- **Cuidado: no es una simulación.** Corre la lógica real sobre los datos reales de la base. Los jobs que notifican a personas pueden enviar avisos reales; son los 8 marcados «Sí» en la columna «Notifica» del inventario: `monthly-reports-reminders`, `member-of-month-auto-evaluate`, `activities-reminder`, `investiture-authorization-reminders`, `cron-alert-check`, `pending-teen-guardian`, `family-age-transitions` y, solo si omite un plan de directiva, `ecclesiastical-year-cut`. Los más sensibles son `activities-reminder` (push a las secciones con actividades próximas) y `cron-alert-check` (correo y aviso a los super-admin). Antes de ejecutar un job que notifica, confirma que los destinatarios sean de prueba (lista completa en el contrato).
- **Jobs largos y tiempo de espera HTTP.** La petición dura lo que dure el job. El backend responde 408 a los 30 s por defecto (`REQUEST_TIMEOUT_MS`) y Render puede cortar antes (502/504), pero el trabajo **no se cancela**: sigue en el servidor, mantiene el candado hasta terminar y escribe su fila de `cron_run_log`. Ante un corte no reintentes: revisa el historial.

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
