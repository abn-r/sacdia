# Informes trimestrales y anuales de club

**Estado**: IMPLEMENTADO PARCIAL
**Verificado contra código**: 2026-11-12 (`development`; rediseño de backend #653, admin #304 y app #256; la migración `20261112120000_periodic_reports_from_monthly` está aplicada en `development`, `staging` y `production` el 2026-11-12)
**Dominio relacionado**: [monthly-reports.md](monthly-reports.md)

## Descripcion de dominio

Además del informe mensual por inscripción, el backend genera dos informes por **club** (no por sección): uno trimestral (año calendario + trimestre) y uno anual (año eclesiástico). Nadie captura datos en ellos. Conservan su estructura, pero las cifras que antes se escribían a mano se calculan a partir de los informes mensuales del club con estado `submitted` dentro del periodo (`monthly_report_manual_data`), junto con el resto de los datos calculados (`computed_data`). El estado es `draft` (en curso) o `finalized` (cerrado y congelado) y el PDF se genera al descargar.

## Que existe (verificado contra codigo)

> Esta sección describe el comportamiento vigente en `development` (backend #653, admin #304, app #256).

### Origen de los datos

Un solo conjunto de secciones alimenta todas las cifras: todas las secciones del club, activas o no (el mismo que usa `FinanceAggregationService`). Todos los rangos de fecha son semiabiertos (inicio incluido, fin excluido). Código: `src/reports/periodic-report-data.service.ts` y `src/reports/periodic-monthly-data.ts`.

| Campo del informe | Fuente |
|---|---|
| `planning_meetings`, `parent_meetings`, `youth_council_attendance`, `church_board_attendance` | Suma de los informes mensuales `submitted` del periodo |
| `soul_target` | Valor del último mes enviado con datos (si ese mes tiene varias secciones, se suman) |
| `total_baptized` (anual) | Igual que `soul_target`: último mes enviado |
| `baptized_this_quarter` / `baptized_this_year` (y `missionary.*`) | Suma de `baptized_this_month` de los meses enviados |
| `club_participation_description`, `community_service_description` | Una entrada por mes enviado con texto (`{ year, month, text }`), del más antiguo al más reciente |
| `certificates_delivered` | `true` si algún mes enviado lo marca; `false` si ninguno; `null` sin meses enviados |
| `camporees_attended` | Camporees distintos (locales y de unión, activos) cuya fecha de inicio cae en el periodo y donde una sección del club tiene inscripción activa en `camporee_clubs` con estado `registered` o `approved` (rechazadas y canceladas no cuentan). No sale del informe mensual |
| `annual_achievements_description`, `all_investitures_completed` (anual) | Siguen en la estructura pero **siempre `null`**: no hay fuente mensual |
| `months_submitted`, `months_covered` | Meses distintos del periodo con al menos un informe mensual enviado |
| `months_reported` (anual) | Meses distintos con un informe mensual que no sea borrador (generado o enviado), máximo 12 |
| `member_count` | Personas distintas con una asignación en el club que se cruza con el periodo |
| `directiva` | Asignaciones de directiva que se cruzan con el periodo, aunque ya hayan terminado |
| `honors` | Especialidades iniciadas y completadas en el periodo (`users_honors` activas de los miembros del periodo) |
| `activities.total` | Actividades creadas en el periodo en las secciones del club |
| `finances` | `income`, `expenses`, `balance` = neto del periodo, `total_balance` = saldo acumulado de toda la historia al fin del periodo, `transactions`; vía `FinanceAggregationService` (mismas cifras que el resumen del club y el informe mensual) |
| `top_achievers` (anual) | Miembros con más especialidades del año |

Sin ningún informe mensual enviado en el periodo, los campos que salen de ellos quedan en `null` (nunca `0`) y el PDF y el admin muestran "—". `camporees_attended` siempre es un número. El campo `ranking_percentile` del informe anual **se eliminó**.

### Ciclo de vida

- `draft` (en curso): el periodo está abierto o dentro del periodo de gracia. Cada `GET` del detalle y cada descarga del PDF **recalculan** los datos antes de responder.
- `finalized` (cerrado): congelado por el cron diario cuando pasan `reports.periodic_freeze_grace_days` días (por defecto 15) desde el fin del periodo, para que el último informe mensual aún pueda enviarse. `finalized_at` se guarda y `finalized_by` queda `null` (automático). Un informe finalizado no cambia nunca por las vías normales.
- No hay edición manual ni finalización manual: se **retiraron** `PATCH /admin/{quarterly,annual}-reports/:id` y `POST /admin/{quarterly,annual}-reports/:id/finalize`, junto con los DTO `update-manual-data`.
- `generate` crea el informe si no existe; si el periodo ya pasó la gracia lo crea **ya congelado**, y si no, lo deja en `draft` recalculado. Uno finalizado se devuelve sin tocarlo.
- `regenerate` es la salida de soporte: recalcula también un informe finalizado y conserva su estado. Solo para `super-admin` y `admin` globales (`ExactGlobalRoles`); cualquier otro rol recibe `403 GUARD_PERMISSION_DENIED`.

### Backend (`src/quarterly-reports/`, `src/annual-reports/`, `src/reports/`)

Ambos controllers usan `JwtAuthGuard` + `PermissionsGuard`; cada ruta declara `@AuthorizationResource` (`active_assignment` en las `admin/*`, `club` en las `clubs/:clubId/*`). Rutas espejo (`{tipo}` = `quarterly-reports` o `annual-reports`):

| Método | Ruta (`/api/v1`) | Permiso |
|---|---|---|
| GET | `/admin/{tipo}` | `reports:read` + `AuthorizationResource({ type: 'active_assignment' })` |
| GET | `/admin/{tipo}/:id` | `reports:read` |
| POST | `/admin/{tipo}/generate` (bajo demanda) | `reports:update` |
| POST | `/admin/{tipo}/:id/regenerate` | `reports:update` + rol global `super-admin` o `admin` |
| GET | `/admin/{tipo}/:id/pdf` | `reports:download` |
| GET | `/clubs/:clubId/{tipo}` | `reports:read` |
| GET | `/clubs/:clubId/{tipo}/:id` | `reports:read` |
| GET | `/clubs/:clubId/{tipo}/:id/pdf` | `reports:download` |

Reglas verificadas:

- **Listado admin**: filtra por división, unión, campo local, club, año, estado (`draft` o `finalized`) y, en el trimestral, trimestre; limitado al ámbito jerárquico del actor (`resolvePeriodicReportVisibilityScopeForActor`). El `status` solo acepta `draft|finalized` y un parámetro de query desconocido responde `400` (DTO `ListQuarterlyReportsQueryDto` / `ListAnnualReportsQueryDto`).
- **Coordinadores sin acceso**: quien llega a los informes solo por la rama de coordinador (`coordinator`, `zone-coordinator` o `general-coordinator` sin otro rol territorial ni sección de club propia) recibe `403 PERIODIC_REPORTS_FORBIDDEN` en **todas** las rutas trimestrales y anuales, `admin/*` y `clubs/:clubId/*`. Conservan `reports:read` y `reports:download` porque los informes mensuales y el cumplimiento (`/reports/compliance`) no cambian. Código: `src/common/authorization/periodic-reports-access.ts` (`isCoordinatorOnlyForPeriodicReports`).
- **Capacidad `reports.view_periodic`**: la tiene quien posee `reports:read` y resuelve a un ámbito territorial (roles `ALL_REPORTS_ROLES`, unión o campo local) o a una sección de club propia; nunca un coordinador sin otro rol. Los clientes la usan para ocultar las pantallas.
- **Generación bajo demanda**: `POST /admin/quarterly-reports/generate` recibe `{ club_id, year (2020–2100), quarter (1–4) }` y `POST /admin/annual-reports/generate` recibe `{ club_id, ecclesiastical_year_id }`. Responden `200` con el mismo cuerpo que `GET /admin/{tipo}/:id`.
  - Dos peticiones simultáneas para el mismo periodo no fallan: la segunda lee la fila que creó la primera.
  - El club debe existir y estar activo (`404 QUARTERLY_REPORT_CLUB_NOT_FOUND` / `ANNUAL_REPORT_CLUB_NOT_FOUND`) y estar dentro del ámbito del actor (`403 GUARD_PERMISSION_DENIED`).
  - El periodo debe haber empezado según el día de `America/Mexico_City`: el trimestre en curso se permite, uno futuro responde `400 REPORT_PERIOD_IN_FUTURE`. Lo mismo para el año eclesiástico (por `start_date`).
- **Unicidad**: `quarterly_reports (club_id, year, quarter)` y `annual_reports (club_id, ecclesiastical_year_id)`.
- **Cron** (ver [cron-automation.md](cron-automation.md)): ambos corren **a diario** y congelan lo que ya pasó la gracia; no generan "el periodo recién cerrado".
  - Trimestral: `0 3 * * *` UTC (`quarterly-reports-auto-generate`). Anual: `30 3 * * *` UTC (`annual-reports-auto-generate`).
  - Cada corrida es un catch-up idempotente desde el inicio del año eclesiástico **anterior** al vigente hasta el último periodo ya fuera de gracia; fechas en `America/Mexico_City`; recorre los clubes activos uno por uno (en serie), omite los ya finalizados y los clubes creados después de terminado el periodo.
  - Requieren `system_config.reports.quarterly_auto_generate_enabled` / `reports.annual_auto_generate_enabled` en `'true'`. La migración `20261112120000_periodic_reports_from_monthly` las deja en `'true'` y crea `reports.periodic_freeze_grace_days = '15'` (no pisa un valor ya ajustado; un valor que no sea entero >= 0 cae a 15). Aplicada solo en la base de desarrollo; staging y producción pendientes.
  - Usan lock Redis y registran en `cron_run_log`.
- **Datos calculados**: `member_count` cuenta personas distintas (una persona con dos asignaciones cuenta una vez). Trimestre válido: 1 a 4 (`QUARTERLY_REPORT_INVALID_QUARTER`). El informe anual usa el mismo cálculo sobre todo el año eclesiástico, más `months_reported` y `top_achievers`.
- **PDF**: lo generan `QuarterlyReportsPdfService` y `AnnualReportsPdfService` al descargar (un borrador se recalcula antes); no se guarda en R2 (los nombres de archivo están en [monthly-reports.md](monthly-reports.md)).
  - Las etiquetas están localizadas en es, en, fr y pt-BR (`src/i18n/*/quarterly_reports.json`, `annual_reports.json`).
  - Contenido: directiva con el nombre del rol; las cifras que salen de los informes mensuales con "—" si están vacías y los textos mes a mes; cada total una sola vez en su sección; bloque final "Director/a del club" con los directores de la directiva (sin correo; "Sin director asignado" si no hay).
  - Paginación: salta de página solo si la sección no cabe y numera el pie "Página X de Y" en todas las páginas.
  - El año eclesiástico se muestra como "2026" si empieza y termina el mismo año, o "2025–2026" si cruza años.

### Admin

- Pantallas `/dashboard/reports/quarterly` y `/dashboard/reports/annual` (sidebar y catálogo de pantallas `reports-quarterly`, `reports-annual`): listado con filtros, diálogo **Generar** (club + año y trimestre, o año eclesiástico) y detalle `[id]`. Las pantallas se muestran solo con la capacidad `reports.view_periodic` (`capabilityAccess` en `src/lib/auth/screen-catalog/screens/clubs.ts`).
- El detalle es solo lectura: muestra los datos calculados y los bloques de datos tomados de los informes mensuales. No hay formulario de datos manuales ni botón Finalizar. El estado se muestra como "En curso" (`draft`) o "Cerrado" (`finalized`).
- **Recalcular** aparece solo sobre un informe cerrado y solo para `super-admin` y `admin` globales con `reports:update` (capacidad de servidor `reports.regenerate_periodic` en la capacidad `regenerate` de la pantalla), con diálogo de confirmación; la descarga del PDF aparece con la capacidad `download` en cualquier estado. La directiva muestra el rol traducido (mismas etiquetas `roles.*` que el resto del panel).
- La pestaña de informes del detalle de club muestra trimestrales y anuales solo con la capacidad `reports.view_periodic`, enlaza cada fila con su detalle y muestra un error si una de las dos llamadas falla.
- Procedencia: admin #304.

### App móvil

- La app deja de consumir los informes trimestrales y anuales. La pantalla de informes del coordinador (`lib/features/coordinator/presentation/views/coordinator_reports_view.dart`) queda solo con el cumplimiento de informes mensuales ("Cumplimiento de informes mensuales"): chips de mes, totales del mes y una tarjeta por club con su estado y los PDF mensuales. El data source ya no llama a `admin/quarterly-reports` ni `admin/annual-reports`. Sigue sin generar, editar ni finalizar nada.

### Base de datos

- `quarterly_reports` y `annual_reports`: `status`, `auto_generated_at`, `finalized_at`, `finalized_by`, `manual_data` (JSONB, ya sin uso: nadie lo escribe), `computed_data` (JSONB) y `pdf_url` (sin uso: el PDF se genera al vuelo).
- La migración `20261112120000_periodic_reports_from_monthly` solo toca `system_config` (las dos banderas y la gracia); no cambia el esquema.

## Gaps y pendientes

- Migración de configuración aplicada solo en dev; falta aplicarla en staging y producción antes de que los crons congelen informes allí.
- `annual_achievements_description` y `all_investitures_completed` del informe anual quedan siempre vacíos hasta que exista una fuente mensual.
- `manual_data` y `pdf_url` quedan como columnas sin uso.
