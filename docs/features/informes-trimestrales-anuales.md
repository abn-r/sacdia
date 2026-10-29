# Informes trimestrales y anuales de club

**Estado**: IMPLEMENTADO PARCIAL
**Verificado contra código**: 2026-10-29 (rama `development`; generación bajo demanda y pantallas del admin: Pendiente de merge)
**Dominio relacionado**: [monthly-reports.md](monthly-reports.md)

## Descripcion de dominio

Además del informe mensual por inscripción, el backend genera dos informes por **club** (no por sección): uno trimestral (año calendario + trimestre) y uno anual (año eclesiástico). Ambos siguen el patrón del informe mensual: datos calculados (`computed_data`), datos manuales (`manual_data`), estado `draft` → `finalized` y PDF generado al descargar.

## Que existe (verificado contra codigo)

### Backend (`src/quarterly-reports/`, `src/annual-reports/`)

Ambos controllers usan `JwtAuthGuard` + `PermissionsGuard`; cada ruta declara `@AuthorizationResource` (`active_assignment` en las `admin/*`, `club` en las `clubs/:clubId/*`). Rutas espejo (`{tipo}` = `quarterly-reports` o `annual-reports`):

| Método | Ruta (`/api/v1`) | Permiso |
|---|---|---|
| GET | `/admin/{tipo}` | `reports:read` + `AuthorizationResource({ type: 'active_assignment' })` |
| GET | `/admin/{tipo}/:id` | `reports:read` |
| PATCH | `/admin/{tipo}/:id` (datos manuales) | `reports:update` |
| POST | `/admin/{tipo}/generate` (bajo demanda, Pendiente de merge) | `reports:update` |
| POST | `/admin/{tipo}/:id/regenerate` | `reports:update` |
| POST | `/admin/{tipo}/:id/finalize` | `reports:update` |
| GET | `/admin/{tipo}/:id/pdf` | `reports:download` |
| GET | `/clubs/:clubId/{tipo}` | `reports:read` |
| GET | `/clubs/:clubId/{tipo}/:id` | `reports:read` |
| GET | `/clubs/:clubId/{tipo}/:id/pdf` | `reports:download` |

Reglas verificadas:

- **Listado admin**: filtra por división, unión, campo local, club, año y estado (y trimestre en el trimestral), limitado al ámbito jerárquico del actor (`resolveReportVisibilityScopeForActor`).
- **Estados**: `draft` y `finalized` (texto). Editar datos manuales, `regenerate` y `finalize` exigen `draft` (`QUARTERLY_REPORT_NOT_DRAFT` / `ANNUAL_REPORT_NOT_DRAFT`). `finalize` guarda `finalized_at` y `finalized_by`. Un informe finalizado queda congelado (Pendiente de merge: hoy en `development` `regenerate` todavía recalcula informes finalizados).
- **Generación bajo demanda** (Pendiente de merge): `POST /admin/quarterly-reports/generate` recibe `{ club_id, year (2020–2100), quarter (1–4) }` y `POST /admin/annual-reports/generate` recibe `{ club_id, ecclesiastical_year_id }`. Responden `200` con el mismo cuerpo que `GET /admin/{tipo}/:id`.
  - Crea el borrador si no existe y recalcula sus datos si sigue en `draft`; si ya está finalizado lo devuelve sin tocarlo.
  - Dos peticiones simultáneas para el mismo periodo no fallan: la segunda lee la fila que creó la primera.
  - El club debe existir y estar activo (`404 QUARTERLY_REPORT_CLUB_NOT_FOUND` / `ANNUAL_REPORT_CLUB_NOT_FOUND`) y estar dentro del ámbito del actor (`403 GUARD_PERMISSION_DENIED`).
  - El periodo debe haber empezado según el día de `America/Mexico_City`: el trimestre en curso se permite, uno futuro responde `400 REPORT_PERIOD_IN_FUTURE`. Lo mismo para el año eclesiástico (por `start_date`).
- **Datos calculados del trimestral**: miembros con asignación activa en las secciones activas del club, directiva, especialidades iniciadas y completadas, actividades, finanzas (ingresos, egresos, balance, movimientos) y bautismos del trimestre. Trimestre válido: 1 a 4 (`QUARTERLY_REPORT_INVALID_QUARTER`).
- **Datos calculados del anual**: lo mismo por año eclesiástico, más meses reportados, percentil de ranking y miembros con más especialidades. Meses reportados = meses distintos (año + mes) con al menos un informe mensual no borrador de cualquier sección del club, máximo 12 (Pendiente de merge: hoy cuenta filas de informes, así que un club con 3 secciones puede pasar de 12).
- **Unicidad**: `quarterly_reports (club_id, year, quarter)` y `annual_reports (club_id, ecclesiastical_year_id)`.
- **Cron**:
  - Trimestral: `0 1 1 1,4,7,10 *` UTC (`quarterly-reports-auto-generate`). Genera el trimestre recién cerrado para todos los clubes activos si `system_config.reports.quarterly_auto_generate_enabled = 'true'`. No toca informes que ya no estén en `draft`.
  - Anual: `0 2 1 1 *` UTC (`annual-reports-auto-generate`). Genera el año eclesiástico recién terminado si `system_config.reports.annual_auto_generate_enabled = 'true'`.
  - Ambos usan lock Redis y registran en `cron_run_log`.
  - En la base de desarrollo las dos banderas están en `'false'`, así que los crons no generan nada; los informes salen solo con la generación bajo demanda.
- **PDF**: lo generan `QuarterlyReportsPdfService` y `AnnualReportsPdfService` al descargar; no se guarda en R2 (los nombres de archivo están en [monthly-reports.md](monthly-reports.md)).
  - Contenido (Pendiente de merge): directiva con el nombre del rol en español; todos los datos manuales, con "—" si están vacíos; cada total una sola vez en su sección; bloque final "Director/a del club" con los directores de la directiva (sin correo; "Sin director asignado" si no hay). Hoy en `development` ese bloque muestra a quien finalizó el informe.
  - Paginación: salta de página solo si la sección no cabe y numera el pie "Página X de Y" en todas las páginas.
  - El año eclesiástico se muestra como "2026" si empieza y termina el mismo año, o "2025–2026" si cruza años.

### Admin

Pendiente de merge (rama `feat/admin-quarterly-annual-reports`):

- Pantallas `/dashboard/reports/quarterly` y `/dashboard/reports/annual` (sidebar y catálogo de pantallas `reports-quarterly`, `reports-annual`): listado con filtros, diálogo **Generar** (club + año y trimestre, o año eclesiástico) y detalle `[id]`.
- El detalle muestra los datos calculados, el formulario de datos manuales y los botones Recalcular y Finalizar solo mientras el informe está en `draft`, cada uno según la capacidad de la pantalla (`update`, `finalize`); la descarga del PDF aparece con la capacidad `download` en cualquier estado. La directiva muestra el rol traducido (mismas etiquetas `roles.*` que el resto del panel).
- La pestaña de informes del detalle de club muestra trimestrales y anuales, enlaza cada fila con su detalle y muestra un error si una de las dos llamadas falla (antes mostraba lista vacía).

En `development` hoy: el detalle de club solo lista los anuales y no hay pantallas de detalle, edición, finalización ni descarga.

### App móvil

- El coordinador ve los listados en solo lectura y descarga el PDF (`lib/features/coordinator/data/datasources/coordinator_reports_remote_data_source.dart`, rutas `admin/quarterly-reports` y `admin/annual-reports`). No genera, edita ni finaliza.

### Base de datos

- `quarterly_reports` y `annual_reports`: `status`, `auto_generated_at`, `finalized_at`, `finalized_by`, `manual_data` (JSONB), `computed_data` (JSONB) y `pdf_url` (sin uso: el PDF se genera al vuelo).

## Gaps y pendientes

- Crons apagados por defecto: si se quieren informes automáticos hay que encender las banderas `reports.*_auto_generate_enabled`.
- `regenerate` puede cambiar los datos de un informe ya finalizado hasta que se mergee el cambio que lo bloquea.
- El cálculo del trimestral cuenta miembros del año eclesiástico con `active = true`, no del año del periodo del informe.
- La app no tiene flujo de generación ni edición (solo lectura para coordinadores).
