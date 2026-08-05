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
  - `GET /api/v1/monthly-reports/admin/list` - **supervision multi-club jerárquica**. Query params: `division_id`, `union_id`, `local_field_id`, `club_type_id`, `year`, `month`, `status`, `page`, `limit`. Scope: `super-admin`/`admin`/`director-dia`/`assistant-dia` ven todo y pueden filtrar; `director-union`/`assistant-union` quedan forzados a su unión; `director-lf`/`assistant-lf`/`coordinator`/`assistant-admin` quedan forzados a su campo; director/secretario de club queda limitado a su sección activa. Response paginada con club_name, club_type, local_field, submitter_name y member_count por item.
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
  - `finances` (`income`, `expenses`, `balance`, `total_balance`, `transactions`)
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
- **Cron de recordatorios**: corre todos los dias a las `09:00` en `America/Mexico_City` y solo emite notificaciones en dias programados
  - dia 27: recuerda a director y secretario registrar avances del mes actual
  - dia 1: recuerda que quedan 5 dias para cerrar el informe del mes anterior
  - dia 4: ultimo recordatorio antes del cierre
  - dia 5: aviso de registro cerrado
  - dia 6: aviso de informe generado/disponible, solo si el informe existe en estado `generated` o `submitted`
  - usa `reports.reminders_enabled`; si la config no existe, los recordatorios quedan habilitados por defecto
  - fuente de notificacion: `monthly_reports:reminder`, categoria movil `reminders`
  - destinatarios: roles de club `director`, `secretary` y `secretary-treasurer`; no incluye subdirector
- `YearEndService` tambien auto-genera informes `draft` antes del cierre anual

### PDF real

- El PDF se genera en backend con `pdfkit`; no es un archivo preexistente en storage
- Solo se habilita si el informe tiene `snapshot_data` y estado `generated` o `submitted`
- Usa formato carta y arma al menos estas secciones:
  - `1. ADMINISTRACION`
  - `2. ENSENANZAS`
  - `3. ACTIVIDADES DEL CLUB`
  - `4. FINANZAS` (incluye balance del mes y saldo total acumulado del club)
  - `5. ACTIVIDAD MISIONERA`
  - `6. SERVICIO`
- Toma metadatos reales de club, distrito, iglesia, tipo de club, mes/anio y submitter

### Admin Web

- **Surface verificada**:
  - `src/lib/api/monthly-reports.ts`
  - `src/components/reports/*`
  - `src/app/(dashboard)/dashboard/reports/[reportId]/page.tsx`
- **Contrato reconciliado parcialmente**:
  - el adaptador admin desempaqueta `{ status, data }` y normaliza `monthly_report_id`/`club_enrollment_id` del backend hacia el contrato local `report_id`/`enrollment_id`; crear, listar, detalle, generar, enviar y descargar PDF usan UUID válidos
- **Drift explicito pendiente**:
  - `MonthlyReportManualData` del admin usa campos legacy como `weekly_meetings_held`, `leadership_meetings`, `souls_won`, `service_hours_total`, que NO coinciden con `UpdateManualDataDto` del backend
  - `MonthlyReportAutoData` del admin espera shape legacy (`activities_count`, `members_total`, `attendance_rate`, etc.) que no coincide con el `preview`/`snapshot_data` real actual
- **Conclusión factual**: la navegación y acciones por ID ya consumen el contrato UUID del backend; los payloads manuales y la presentación de datos auto-calculados siguen pendientes de reconciliación
- **Plantilla imprimible de referencia**: `/reports/monthly-preview` renderiza fuera del shell del dashboard un formulario HTML rellenable de exactamente tres páginas carta vertical. La página 1 contiene Administración y Enseñanzas; la página 2, Actividades del club y Finanzas; la página 3, Actividad misionera, Servicio y Firmas. `/reports/monthly-preview?example=1` inicializa el mismo formulario con una fixture local de muestra. Esta plantilla no persiste ni adapta sus campos al DTO backend actual y requiere los logos oficiales locales en `public/brand/iasd-logo-horizontal.svg` y `public/brand/iasd-symbol.svg`.

### App Movil

- **Surface verificada**:
  - `lib/features/monthly_reports/*`
  - rutas `monthlyReports`, `monthlyReportDetail` y acceso desde `/home/reports`
- **Contrato reconciliado parcialmente**:
  - monthly reports usa `String` para `reportId` y `enrollmentId`, compatible con UUID backend
  - `EnrollmentModel` conserva `enrollmentUuid` para llamar endpoints UUID sin romper consumers legacy que aun usan `id: int`
  - `MonthlyReportModel` parsea `snapshot_data`, `manual_data`, `generated_at`, club y tipo de club
  - la pantalla `/home/reports` permite preparar el informe del mes actual creando/abriendo `draft` y editar datos manuales; la generacion del mes queda reservada al cron/sistema en el cierre del mes siguiente
  - el detalle movil muestra la misma informacion funcional que el PDF organizada por administracion, ensenanzas/honores, actividades, finanzas, actividad misionera y servicio/materiales
  - al guardar datos manuales, campos numericos vacios se normalizan a `0`; campos de texto vacios se envian como `null` para limpiar valores previos
- **Pendiente cliente**: reconciliacion completa de consumidores legacy de enrollment que todavia usan IDs numericos. El `submit` no es flujo primario de director/secretario si el reporte se genera automaticamente el dia de cierre.

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
6. Debe existir automatizacion para generar informes del mes anterior y durante cierre anual; la captura manual del club ocurre durante el mes actual

## Decisiones de diseno

- **Owner del informe = matricula anual**: el agregado se ata a `club_enrollment_id`, no al club ni a la seccion aislados
- **Unicidad por periodo**: la tupla `(club_enrollment_id, month, year)` evita borradores duplicados
- **Snapshot separado de manual_data**: el auto-calculado congelado vive en `snapshot_data`, mientras la captura humana queda normalizada en `monthly_report_manual_data`. Los campos declarativos de reuniones, actividad misionera y servicio NO deben guardarse como `activities` salvo que correspondan a eventos reales del calendario del club.
- **PDF server-side**: el documento se genera bajo demanda desde backend y no requiere que el cliente componga el reporte

## Gaps y pendientes

- **Drift fuerte en admin**: routing, IDs y payload manual/auto no coinciden con el contrato backend actual
- **App movil parcialmente reconciliada**: reportes mensuales ya usan UUID y snapshot/manual_data; la app captura/edita `draft` y deja la generacion al sistema; queda pendiente limpieza de consumers legacy de enrollment numerico
- **Estado no arbitrado mas alla de submitted**: en backend no existen estados `approved` o `rejected` para monthly reports aunque algunos clientes los modelen

## Prioridad y siguiente accion

- **Prioridad**: Media - el backend esta lo bastante completo para documentar y operar, pero los clientes siguen en drift
- **Siguiente accion**: completar admin web y definir, si hace falta, una accion administrativa auditada para reabrir/regenerar reportes
