# Monthly Reports (informes mensuales)

**Estado**: IMPLEMENTADO

## Descripcion de dominio

`monthly-reports` consolida el informe mensual operativo de una matricula anual de club (`club_enrollments`) para un mes y ano dados. El runtime actual mezcla datos auto-calculados en vivo, captura manual complementaria, congelamiento de snapshot, envio formal y generacion de PDF.

La feature esta implementada en backend con IDs UUID y estados `draft -> generated -> submitted`. Admin y app tienen superficies cliente para esta feature, pero hoy presentan drift respecto del contrato real del backend; en este batch solo se deja documentado ese drift.

## Que existe (verificado contra codigo)

### Backend (MonthlyReportsModule)
- **Controller**: `src/monthly-reports/monthly-reports.controller.ts`
- **Service**: `src/monthly-reports/monthly-reports.service.ts`
- **PDF**: `src/monthly-reports/monthly-reports-pdf.service.ts`
- **Cron**: `src/monthly-reports/monthly-reports-cron.service.ts`
- **9 endpoints directos**:
  - `GET /api/v1/monthly-reports/preview/:enrollmentId` - preview en vivo para una matricula y periodo
  - `POST /api/v1/monthly-reports/:enrollmentId` - obtener o crear borrador unico por `(club_enrollment_id, month, year)`
  - `PATCH /api/v1/monthly-reports/:reportId/manual-data` - guardar datos manuales solo si el informe esta en `draft`
  - `POST /api/v1/monthly-reports/:reportId/generate` - congelar `snapshot_data` y pasar a `generated`
  - `POST /api/v1/monthly-reports/:reportId/submit` - pasar de `generated` a `submitted`
  - `GET /api/v1/monthly-reports/enrollment/:enrollmentId` - listar informes por matricula, con filtro opcional `status`
  - `GET /api/v1/monthly-reports/admin/list` - **supervision multi-club para admin/coordinator** (agregado 2026-04-22). Query params: `club_type_id`, `local_field_id`, `year`, `month`, `status`, `page`, `limit`. Scope: admin/super_admin ve todo; coordinator es forzado a su `local_field_id` derivado via `AuthorizationContextService` (JWT no trae claim directo, se resuelve en server con cache Redis 5min). Response paginada con club_name, club_type, local_field, submitter_name y member_count por item.
  - `GET /api/v1/monthly-reports/:reportId/pdf` - descargar PDF solo para `generated|submitted`
  - `GET /api/v1/monthly-reports/:reportId` - obtener detalle completo con `manual_data`, `snapshot_data`, matricula y submitter
- **Permisos verificados**:
  - casi toda la superficie requiere `reports:read`
  - descarga PDF requiere `reports:download`
  - el controller usa `JwtAuthGuard`, `PermissionsGuard` y `@AuthorizationResource({ type: 'active_assignment' })`
- **Estados reales verificados**:
  - `draft`
  - `generated`
  - `submitted`
- **IDs reales verificados**:
  - `monthly_report_id`: UUID
  - `club_enrollment_id`: UUID
  - `submitted_by`: UUID nullable a `users.user_id`
- **Preview auto-calculado real**:
  - `member_count`
  - `directiva`
  - `honors` (`started`, `completed`, `details`)
  - `activities` (`total`, `list`)
  - `finances` (`income`, `expenses`, `balance`, `transactions`)
  - `meeting_days`
- **Datos manuales reales**:
  - administracion: `planning_meetings`, `parent_meetings`, `youth_council_attendance`, `church_board_attendance`
  - actividad misionera: `soul_target`, `unbaptized_members`, `bible_studies_receiving`, `has_weekly_bible_instruction`, `bible_studies_given`, `literature_distributed`, `baptized_this_month`, `total_baptized`
  - texto/seguimiento: `club_participation_description`, `community_service_description`, `certificates_delivered`, `members_have_booklet`, `booklet_requirements_signed`

### Automatizacion backend
- **Cron operativo**: corre todos los dias a las `23:00` del servidor
- Lee `system_config`:
  - `reports.auto_generate_enabled`
  - `reports.auto_generate_day`
- Si el dia coincide, genera informes para el mes anterior de todas las matriculas activas
- Usa lock distribuido `cron:monthly-reports-auto-generate`
- `YearEndService` tambien auto-genera informes `draft` antes del cierre anual

### PDF real
- El PDF se genera en backend con `pdfkit`; no es un archivo preexistente en storage
- Solo se habilita si el informe tiene `snapshot_data` y estado `generated` o `submitted`
- Usa formato carta y arma al menos estas secciones:
  - `1. ADMINISTRACION`
  - `2. ENSENANZAS`
  - `3. ACTIVIDADES DEL CLUB`
  - `4. FINANZAS`
  - `5. ACTIVIDAD MISIONERA`
  - `6. SERVICIO`
- Toma metadatos reales de club, distrito, iglesia, tipo de club, mes/anio y submitter

### Admin Web
- **Surface verificada**:
  - `src/lib/api/monthly-reports.ts`
  - `src/components/reports/*`
  - `src/app/(dashboard)/dashboard/reports/[reportId]/page.tsx`
- **Drift explicito verificado**:
  - el admin tipa `report_id` y `enrollment_id` como `number`, pero backend usa UUID
  - la pagina `[reportId]` hace `Number(reportId)` y rechaza cualquier UUID valido
  - `MonthlyReportManualData` del admin usa campos legacy como `weekly_meetings_held`, `leadership_meetings`, `souls_won`, `service_hours_total`, que NO coinciden con `UpdateManualDataDto` del backend
  - `MonthlyReportAutoData` del admin espera shape legacy (`activities_count`, `members_total`, `attendance_rate`, etc.) que no coincide con el `preview`/`snapshot_data` real actual
- **Conclusion factual**: existe superficie admin para monthly reports, pero hoy no debe documentarse como compatible con el contrato backend vigente

### App Movil
- **Surface verificada**:
  - `lib/features/monthly_reports/*`
  - rutas `monthlyReports` y `monthlyReportDetail`
- **Drift explicito verificado**:
  - la app modela `reportId` y `enrollmentId` como `int`, pero backend usa UUID
  - el data source llama endpoints reales de backend, pero con IDs numericos en firma y routing
  - la entidad movil reconoce estados `draft|submitted|approved|rejected`; backend real usa `draft|generated|submitted`
  - el modelo movil espera payload legacy (`total_activities`, `total_members`, `attendance_rate`, `notes`, etc.) y no refleja el shape real de `snapshot_data` ni de `manual_data`
- **Conclusion factual**: la app tiene implementacion cliente del dominio, pero hoy tambien esta en drift respecto del runtime real del backend

### Base de datos
- `monthly_reports` - cabecera del informe mensual por matricula + mes + ano
- `monthly_report_manual_data` - bloque one-to-one de datos manuales asociado por `monthly_report_id`
- Relaciones de soporte con `club_enrollments`, `users`, `club_sections`, `clubs`, `club_types`, `churches`, `districts`, `activities`, `finances`, `club_role_assignments` y `users_honors`

## Requisitos funcionales

1. Debe existir a lo sumo un informe por matricula, mes y ano
2. Debe poder verse un preview en vivo antes de congelar el snapshot
3. Solo informes en `draft` deben aceptar actualizacion manual o generacion
4. Solo informes en `generated` deben poder enviarse
5. El PDF debe generarse desde el snapshot congelado, no desde datos en vivo
6. Debe existir automatizacion para generar informes del mes anterior y durante cierre anual

## Decisiones de diseno

- **Owner del informe = matricula anual**: el agregado se ata a `club_enrollment_id`, no al club ni a la seccion aislados
- **Unicidad por periodo**: la tupla `(club_enrollment_id, month, year)` evita borradores duplicados
- **Snapshot separado de manual_data**: el auto-calculado congelado vive en `snapshot_data`, mientras la captura humana queda normalizada en `monthly_report_manual_data`
- **PDF server-side**: el documento se genera bajo demanda desde backend y no requiere que el cliente componga el reporte

## Gaps y pendientes

- **Drift fuerte en admin**: routing, IDs y payload manual/auto no coinciden con el contrato backend actual
- **Drift fuerte en app**: IDs numericos, estados legacy y shape de datos distintos al runtime real
- **Estado no arbitrado mas alla de submitted**: en backend no existen estados `approved` o `rejected` para monthly reports aunque algunos clientes los modelen

## Prioridad y siguiente accion

- **Prioridad**: Media - el backend esta lo bastante completo para documentar y operar, pero los clientes siguen en drift
- **Siguiente accion**: abrir un batch separado de reconciliacion de contratos para admin/app sin mezclarlo con esta resincronizacion documental
