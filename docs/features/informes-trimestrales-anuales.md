# Informes trimestrales y anuales de club

**Estado**: IMPLEMENTADO PARCIAL
**Verificado contra código**: 2026-10-04 (rama `development`)
**Dominio relacionado**: [monthly-reports.md](monthly-reports.md)

## Descripcion de dominio

Además del informe mensual por inscripción, el backend genera dos informes por **club** (no por sección): uno trimestral (año calendario + trimestre) y uno anual (año eclesiástico). Ambos siguen el patrón del informe mensual: datos calculados (`computed_data`), datos manuales (`manual_data`), estado `draft` → `finalized` y PDF generado al descargar.

## Que existe (verificado contra codigo)

### Backend (`src/quarterly-reports/`, `src/annual-reports/`)

Ambos controllers usan `JwtAuthGuard` + `PermissionsGuard`. Rutas espejo (`{tipo}` = `quarterly-reports` o `annual-reports`):

| Método | Ruta (`/api/v1`) | Permiso |
|---|---|---|
| GET | `/admin/{tipo}` | `reports:read` + `AuthorizationResource({ type: 'active_assignment' })` |
| GET | `/admin/{tipo}/:id` | `reports:read` |
| PATCH | `/admin/{tipo}/:id` (datos manuales) | `reports:update` |
| POST | `/admin/{tipo}/:id/regenerate` | `reports:update` |
| POST | `/admin/{tipo}/:id/finalize` | `reports:update` |
| GET | `/admin/{tipo}/:id/pdf` | `reports:download` |
| GET | `/clubs/:clubId/{tipo}` | `reports:read` |
| GET | `/clubs/:clubId/{tipo}/:id` | `reports:read` |
| GET | `/clubs/:clubId/{tipo}/:id/pdf` | `reports:download` |

Reglas verificadas:

- **Listado admin**: filtra por división, unión, campo local, club, año y estado (y trimestre en el trimestral), limitado al ámbito jerárquico del actor (`resolveReportVisibilityScopeForActor`).
- **Estados**: `draft` y `finalized` (texto). Editar datos manuales, `generate` y `finalize` exigen `draft` (`QUARTERLY_REPORT_NOT_DRAFT` / `ANNUAL_REPORT_NOT_DRAFT`). `finalize` guarda `finalized_at` y `finalized_by`.
- **`regenerate`** recalcula `computed_data` sin mirar el estado: también actualiza informes `finalized`.
- **Datos calculados del trimestral**: miembros con asignación activa en las secciones activas del club, directiva, especialidades iniciadas y completadas, actividades, finanzas (ingresos, egresos, balance, movimientos) y bautismos del trimestre. Trimestre válido: 1 a 4 (`QUARTERLY_REPORT_INVALID_QUARTER`).
- **Datos calculados del anual**: lo mismo por año eclesiástico, más meses reportados, percentil de ranking y miembros con más especialidades.
- **Unicidad**: `quarterly_reports (club_id, year, quarter)` y `annual_reports (club_id, ecclesiastical_year_id)`.
- **Cron**:
  - Trimestral: `0 1 1 1,4,7,10 *` UTC (`quarterly-reports-auto-generate`). Genera el trimestre recién cerrado para todos los clubes activos si `system_config.reports.quarterly_auto_generate_enabled = 'true'`. No toca informes que ya no estén en `draft`.
  - Anual: `0 2 1 1 *` UTC (`annual-reports-auto-generate`). Genera el año eclesiástico recién terminado si `system_config.reports.annual_auto_generate_enabled = 'true'`.
  - Ambos usan lock Redis y registran en `cron_run_log`.
- **PDF**: lo generan `QuarterlyReportsPdfService` y `AnnualReportsPdfService` al descargar; no se guarda en R2 (los nombres de archivo están en [monthly-reports.md](monthly-reports.md)).

### Admin

- El detalle de club (`/dashboard/clubs/[id]`) lista los informes anuales con `GET /clubs/:clubId/annual-reports` (si la llamada falla, muestra lista vacía).
- `src/lib/api/reports.ts` define `listClubQuarterlyReports`, pero ninguna página lo usa.
- No hay pantallas de detalle, edición, finalización ni descarga de estos informes.

### App móvil

- Sin consumo.

### Base de datos

- `quarterly_reports` y `annual_reports`: `status`, `auto_generated_at`, `finalized_at`, `finalized_by`, `manual_data` (JSONB), `computed_data` (JSONB) y `pdf_url` (sin uso: el PDF se genera al vuelo).

## Gaps y pendientes

- **Rutas sin `@AuthorizationResource`**: en cada controller solo `GET /admin/{tipo}` lo declara. `PermissionsGuard` responde `GUARD_RBAC_MISCONFIGURATION` (500) cuando un handler con `@RequirePermissions` no tiene `@AuthorizationResource`, así que las otras 8 rutas de cada controller fallan tal como están. Afecta también al listado anual del detalle de club en el admin.
- `regenerate` puede cambiar los datos de un informe ya finalizado (en ambos servicios).
- El cálculo del trimestral cuenta miembros del año eclesiástico con `active = true`, no del año del periodo del informe.
- Sin UI de flujo completo en admin ni en app.
