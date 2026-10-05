# Cierre de año eclesiástico (year-end y year-cut)

**Estado**: IMPLEMENTADO
**Verificado contra código**: 2026-10-04 (rama `development`)

## Descripcion de dominio

El cambio de año eclesiástico tiene dos procesos independientes:

- **Cierre administrativo (`year-end`)**: acción manual de un administrador que desactiva un año, cierra las inscripciones anuales de club y sus carpetas de evidencias, y genera los informes mensuales que siguen en borrador.
- **Corte anual de membresía (`year-cut`)**: job diario que, al iniciar el año vigente, termina cargos vencidos, activa planes de sucesión de director y deja a los miembros que regresan como "no inscritos". Está documentado en detalle en [cron-automation.md](cron-automation.md) §11.

`YearCutService` no llama a `YearEndService.closeYear`; son flujos separados.

## Que existe (verificado contra codigo)

### Backend: cierre administrativo (`src/year-end/`)

Controller con `JwtAuthGuard`, `GlobalRolesGuard`, `PermissionsGuard` y `AuthorizationResource({ type: 'global' })`.

| Método | Ruta (`/api/v1`) | Rol global | Permiso |
|---|---|---|---|
| GET | `/year-end/:yearId/preview` | `admin`, `super-admin` | `ecclesiastical_years:update` |
| POST | `/year-end/:yearId/close` | `admin`, `super-admin` | `ecclesiastical_years:update` |

Reglas de `YearEndService.closeYear`:

- El año debe existir (`YEAR_END_ECCLESIASTICAL_YEAR_NOT_FOUND`) y estar activo; si ya está inactivo responde `YEAR_END_YEAR_CLOSED`.
- Antes de la transacción genera (congela) los `monthly_reports` en `draft` de las inscripciones abiertas del año con `MonthlyReportsService.generate(…, 'system')`. Si un informe falla, se registra un aviso y el cierre continúa.
- En una transacción: pone `ecclesiastical_years.active = false`, pasa a `closed` todas las `club_enrollments` del año que no lo estén y cierra sus `annual_folders`. Si la carpeta no tenía `hierarchy_context_id`, guarda una instantánea de la jerarquía institucional del club (`InstitutionalHierarchyService.snapshotForClub`).
- Devuelve `{ yearId, enrollmentsClosed, foldersClosed, reportsGenerated }`.
- `preview` es una simulación: cuenta inscripciones, carpetas e informes afectados y lista las inscripciones con club, tipo y estado actual.

### Backend: corte anual (`src/year-cut/`)

- `YearCutCronService`: `@Cron('5 6 * * *', timeZone: 'UTC')` y también en `onModuleInit` para recuperar un corte perdido. Lock Redis `cron:ecclesiastical-year-cut` (TTL ~23 h) y registro en `cron_run_log` con `job_name = ecclesiastical-year-cut`.
- `YearCutService.applyCut`: procesa por club, con `pg_advisory_xact_lock(club_id, year_id)` y ledger `club_year_transitions` (un club `completed` se omite). Termina cargos vencidos, activa `director_succession_plans` programados, inscribe a quienes pasan de tipo de club (Aventureros → Conquistadores → Guías Mayores) y deja a los demás como `member` inactivo del año vigente.
- Tras cada club invalida la caché de autorización de los usuarios afectados (`invalidateUserAuthorizationCache`); un fallo ahí no revierte el corte.
- Resumen: `{ ended, activated, returnedNotEnrolled, typeGraduatesEnrolled, usersInvalidated }`.
- No tiene endpoint HTTP.

### Admin

- `/dashboard/year-end` (`YearEndClientPage`) consume `GET /year-end/:yearId/preview` y `POST /year-end/:yearId/close` (`src/lib/api/year-end.ts`).

### App móvil

- Sin pantalla propia. La app refleja el resultado del corte en el estado de inscripción anual (ver [gestion-clubs.md](gestion-clubs.md), "Plantilla anual de miembros").

### Base de datos

- `ecclesiastical_years.active`
- `club_enrollments.status` / `closed_at`
- `annual_folders.status` / `closed_at` / `hierarchy_context_id`
- `monthly_reports.status`
- `club_role_assignments`, `director_succession_plans`, `class_counselor_assignments`, `club_year_transitions` (corte anual)

## Gaps y pendientes

- La generación de informes en `closeYear` ocurre fuera de la transacción: si la transacción falla, los informes ya generados quedan generados.
- La consulta de inscripciones a cerrar no está paginada; el propio servicio lo marca como riesgo si el volumen supera unas 5 000 filas.
- El cierre administrativo no está ligado al corte anual. El corte elige el año vigente por fechas (`EcclesiasticalYearService.getCurrentYear`), no por `active`, así que el año saliente sigue con `active = true` hasta que un admin lo cierre.
