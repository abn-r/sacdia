# Monthly Reports (informes mensuales)

**Estado**: IMPLEMENTADO
**Actualizado**: 2026-11-19 (sección de la app móvil verificada contra `development`)

## Descripcion de dominio

`monthly-reports` consolida el informe mensual operativo de una matricula anual de club (`club_enrollments`) para un mes y ano dados. El runtime actual mezcla datos auto-calculados en vivo, captura manual complementaria, congelamiento de snapshot, envio formal y generacion de PDF.

La feature esta implementada en backend con IDs UUID y estados `draft -> generated -> submitted`. El admin tiene una superficie cliente con drift respecto del contrato real del backend, que se deja documentado abajo; la app móvil usa UUID y los campos reales del backend (ver «App Movil»).

## Que existe (verificado contra codigo)

### Backend (MonthlyReportsModule)

- **Controller**: `src/monthly-reports/monthly-reports.controller.ts`
- **Service**: `src/monthly-reports/monthly-reports.service.ts`
- **PDF**: `src/monthly-reports/monthly-reports-pdf.service.ts`
- **Cron**: `src/monthly-reports/monthly-reports-cron.service.ts`
- **9 endpoints directos**:
  - `GET /api/v1/monthly-reports/preview/:enrollmentId` - preview en vivo para una matricula y periodo
  - `POST /api/v1/monthly-reports/:enrollmentId` - obtener o crear borrador unico por `(club_enrollment_id, month, year)`; responde 201 si crea el borrador y 200 si ya existia (antes siempre 201)
  - `PATCH /api/v1/monthly-reports/:reportId/manual-data` - guardar datos manuales solo si el informe esta en `draft`
  - `POST /api/v1/monthly-reports/:reportId/generate` - encola congelar `snapshot_data` + PDF; responde 202; poll GET hasta `generated`
  - `POST /api/v1/monthly-reports/:reportId/submit` - pasar de `generated` a `submitted`
  - `GET /api/v1/monthly-reports/enrollment/:enrollmentId` - listar informes por matricula, con filtro opcional `status`
  - `GET /api/v1/monthly-reports/admin/list` - **supervision multi-club jerárquica**. Query params: `division_id`, `union_id`, `local_field_id`, `club_type_id`, `year`, `month`, `status`, `page`, `limit`. Scope: `super-admin`/`admin`/`director-dia`/`assistant-dia` ven todo y pueden filtrar; `director-union`/`assistant-union` quedan forzados a su unión; `director-lf`/`assistant-lf`/`assistant-admin` quedan forzados a su campo; `coordinator`/`zone-coordinator`/`general-coordinator` quedan forzados a `club_section_ids` de `coordinator_assignments`; director/secretario de club queda limitado a su sección activa. Response paginada con club_name, club_type, local_field, submitter_name y member_count por item.
  - `GET /api/v1/monthly-reports/:reportId/pdf` - descargar PDF solo para `generated|submitted`
  - `GET /api/v1/monthly-reports/:reportId` - obtener detalle completo con `manual_data`, `snapshot_data`, matricula y submitter
- **Permisos verificados**:
  - lectura (`preview`, listado por matrícula, `admin/list`, detalle) requiere `reports:read`
  - borrador, datos manuales, generar y enviar requieren `reports:submit` (desde 2026-10-22; antes `reports:read`)
  - descarga PDF requiere `reports:download`; `regenerate` requiere `reports:write`
  - tesorero: solo `reports:read` + `reports:download` (ve y descarga). No crea, edita, genera, envía ni regenera el informe; eso es de la directiva (director, subdirector, secretario, secretario-tesorero). Decisión del 2026-11-02, migración `20261102140000_treasurer_monthly_report_read_only`.
  - coordinadores: `reports:read` + `reports:download`, nunca `reports:submit`; detalle, PDF y listado por matrícula declaran `coordinatorSections` (pasa solo si `coordinator_assignments` cubre la sección). Cumplimiento agregado: `GET /api/v1/reports/compliance`
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
  - `directiva`: asignaciones activas de la sección con rol `director`, `deputy-director`, `secretary`, `secretary-treasurer` o `treasurer`, en ese orden (`CLUB_DIRECTIVA_ROLES`). Los informes trimestral y anual usan la misma lista.
  - `honors` (`started`, `completed`, `details`)
  - `activities` (`total`, `list`)
  - `finances` (`income`, `expenses`, `balance`, `total_balance`, `transactions`)
    - Los cinco números salen de `FinanceAggregationService` (movimientos activos en vivo): `balance` es el neto del mes y `total_balance` el saldo acumulado de toda la historia de la seccion hasta el fin del mes. Son los mismos que muestra el resumen del club (decisión 2026-11-11).
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

- El PDF se genera en backend con `pdfkit` y se guarda en R2; `POST generate`/`regenerate` encolan el render (202). GET pdf repara el artefacto si el worker aún no terminó.
- La clave en R2 sigue siendo `{prefijo}/{año}/{mes}/{club_enrollment_id}/{monthly_report_id}.pdf`. El nombre que ve el usuario al descargar o compartir es `informe-mensual-{club}-{tipo}-{mes}-{año}.pdf` (ejemplo: `informe-mensual-Senderos-del-Rey-Conquistadores-agosto-2026.pdf`). Club y tipo salen de la matrícula, sin acentos ni caracteres fuera de letras, números y guiones. El mes va en español. `Content-Disposition` lo fija el backend; el admin lo lee (CORS expone ese header) y la app guarda el temporal con ese nombre para compartir.
- La misma estructura aplica al trimestral (`informe-trimestral-{club}-{tipos}-{trimestre}-{año}.pdf`, por ejemplo `1er-trimestre-2026`) y al anual (`informe-anual-{club}-{tipos}-{año}.pdf`, con el rango del año eclesiástico, por ejemplo `2025-2026`). Esos dos informes son del club, no de una matrícula: si hay varias secciones, los tipos van juntos y ordenados. El PDF se genera al descargar; no hay artefacto en R2.
- HTTP JSON serializa `pdf_size_bytes` como `number` (Prisma `BigInt` no es JSON-safe; list/get/generate/submit lo convierten).
- Solo se habilita si el informe tiene `snapshot_data` y estado `generated` o `submitted`
- Usa formato carta y arma al menos estas secciones:
  - `1. ADMINISTRACIÓN`
  - `2. ENSEÑANZAS`
  - `3. ACTIVIDADES DEL CLUB`
  - `4. FINANZAS` (incluye balance del mes y saldo total acumulado del club)
  - `5. ACTIVIDAD MISIONERA`
  - `6. SERVICIO`
- Toma metadatos reales de club, distrito, iglesia, tipo de club, mes/anio y submitter
- Las filas que no caben en una tabla se resumen como «…y N más»; las fechas de actividad se escriben con mes abreviado («2 sep 2026»); un dato con etiqueta sin valor se muestra como «—». Al final quedan las líneas de firma del secretario/a y del director/a.
- Versión de plantilla: `monthly-report-v3-three-page` (`MONTHLY_REPORT_PDF_TEMPLATE_VERSION`). Al subirla, el GET vuelve a generar los artefactos guardados con una versión anterior.
- Todos los PDF del backend usan las fuentes estándar de pdfkit (WinAnsi). `loadPdfKit()` limpia el texto antes de medirlo o dibujarlo: quita códigos de control y ANSI y caracteres que esas fuentes no tienen (emoji).

### Admin Web

- **Surface verificada**:
  - `src/lib/api/monthly-reports.ts`
  - `src/components/reports/*`
  - `src/app/(dashboard)/dashboard/reports/[reportId]/page.tsx`
- **Contrato reconciliado parcialmente**:
  - el adaptador admin desempaqueta `{ status, data }` y normaliza `monthly_report_id`/`club_enrollment_id` del backend hacia el contrato local `report_id`/`enrollment_id`; crear, listar, detalle, generar, enviar y descargar PDF usan UUID válidos
- **Drift explicito pendiente**:
  - `POST generate` ahora responde 202 con `{ queued: true, status: 'draft' }` hasta que el worker congela el snapshot; el admin/app que esperaban 200 + `generated` en la misma request deben poll `GET :reportId`
  - `MonthlyReportManualData` del admin usa campos legacy como `weekly_meetings_held`, `leadership_meetings`, `souls_won`, `service_hours_total`, que NO coinciden con `UpdateManualDataDto` del backend
  - `MonthlyReportAutoData` del admin espera shape legacy (`activities_count`, `members_total`, `attendance_rate`, etc.) que no coincide con el `preview`/`snapshot_data` real actual
- **Conclusión factual**: la navegación y acciones por ID ya consumen el contrato UUID del backend; los payloads manuales y la presentación de datos auto-calculados siguen pendientes de reconciliación
- **Plantilla imprimible de referencia**: `/reports/monthly-preview` renderiza fuera del shell del dashboard un formulario HTML rellenable de exactamente dos páginas carta vertical. La página 1 contiene Administración, Enseñanzas y Actividades del club; la página 2, Finanzas, Actividad misionera, Servicio y Firmas. Cada sección tiene alto fijo en mm y todo su contenido cabe sin recortes; las tarjetas de indicadores llevan borde neutro uniforme (sin franja de color). Esta plantilla no persiste ni adapta sus campos al DTO backend actual y usa los logos oficiales locales `public/brand/iasd-logo-horizontal.svg` y `public/brand/iasd-symbol.svg` (en el repo desde el commit `1356315` de sacdia-admin; si faltara alguno, la plantilla muestra un aviso en su lugar).

### App Movil

**Actualizado**: 2026-11-19 (`development`; rediseño en sacdia-app #265, ajustes en #267). Código en `lib/features/monthly_reports/`.

**Rutas** (`route_names.dart`)

| Ruta | Pantalla |
|---|---|
| `/home/reports` | `MonthlyReportsVisibleListView`: inicio de «Reportes» (acceso desde el inicio) |
| `/monthly-reports/:enrollmentId` | `MonthlyReportsListView`: historial de una inscripción (se abre desde Finanzas) y reutiliza el mismo historial por año |
| `/monthly-report/:reportId` | `MonthlyReportDetailView`: detalle (también se abre con `Navigator.push` desde el historial) |

**Inicio de «Reportes»**
- Con contexto de club (director, secretario, etc.) el historial sale de `GET /monthly-reports/enrollment/:enrollmentId` de la inscripción de la sección activa. Sin contexto de club (coordinador o admin) usa `GET /monthly-reports/admin/list`, que es multi-club; se evita para quien tiene club porque a un director que además coordina le traería informes de otras secciones.
- «Por atender» muestra solo el informe del mes en curso cuando está en `draft`, o la invitación a empezarlo si todavía no existe (solo con contexto de club). El mes que se prepara es el mes actual (`MonthlyReportPeriod.forPreparation`); el sistema lo genera el día de cierre del mes siguiente. «Empezar» crea o recupera el borrador (`POST /monthly-reports/:enrollmentId`) y abre el detalle. El subtítulo indica cuántas secciones manuales faltan por llenar.
- Debajo, el historial agrupado por año (etiqueta con conteo y una tarjeta por año), una línea corta por fila («Enviado el 6 nov») y el chip de estado. Estados de esqueleto, vacío y error con reintento; *pull-to-refresh*.

**Detalle**
- Arriba, `SacStatePanel` con «Paso N de 4» y, al tocarlo, la hoja con los estados: Borrador, Generado, Enviado y Aprobado (con Rechazado en lugar de Enviado cuando aplica). La fecha en que el sistema genera el informe sale del día de generación que el servidor manda en los pendientes del inicio (`GET /dashboard/pending`); sin esa fila, la app usa el día 5 (`kMonthlyReportDefaultDueDay`).
- Con el informe en `draft`: grupo «Lo llenas tú» con las cuatro secciones manuales (reuniones, actividad misionera, servicio y materiales), cada una con «Listo» o «Falta llenar» (tocarla abre esa sección del formulario), y grupo «Se llena solo» con lo que el sistema calcula, a partir de `GET /monthly-reports/preview/:enrollmentId`. El preview ahora lee `auto_calculated`.
- Con el informe generado o posterior: caja 2×2 con miembros, actividades, ingresos y balance del mes (una cifra que falta se escribe en gris «Sin dato») y grupos etiqueta-valor por sección. Con `rejected` se cita el comentario del revisor (`review_comment`) y se vuelve a mostrar el índice de secciones manuales.
- Una sola acción fija abajo según el estado: `draft` → «Llenar lo que falta» (o «Revisar lo que llenaste» si no falta nada); `generated` → «Enviar al campo local» (con confirmación; `POST /monthly-reports/:reportId/submit`, que la app ahora tiene conectado); `submitted` o `approved` → «Ver PDF»; `rejected` → «Corregir y reenviar». Cuando la acción principal no es «Ver PDF» y el PDF se puede descargar, hay un icono de PDF en la barra superior. El PDF se descarga con el JWT en el header (nunca en la URL) y se abre en el visor interno.
- La app no genera el informe (`canGenerate` es siempre falso): la generación es del cron o del sistema.

**Datos manuales (`MonthlyReportManualDataFormView`)**: una sección por hoja (reuniones: planeación, padres, consejo de jóvenes, junta de iglesia; actividad misionera: meta de almas, no bautizados, estudios bíblicos, instrucción bíblica semanal, estudios dados, literatura, bautizados del mes y total; servicio: participación del club y servicio a la comunidad; materiales: certificados, folletos y requisitos firmados), con contadores, interruptores y campos de texto.
- **Autoguardado** con 700 ms de espera (`kMonthlyReportAutosaveDelay`) y estados «guardando», «guardado» y «error» (`PATCH /monthly-reports/:reportId/manual-data`). «Listo» y cerrar esperan a que termine el guardado pendiente; si falla, no se cierra sin avisar, y cerrar con cambios sin guardar pide confirmación de descarte. El autoguardado no invalida el detalle ni las listas; eso se hace una sola vez al cerrar.
- Los contadores muestran en gris el valor del mes anterior como pista con el nombre del mes y el valor («{mes}: {valor}»), tomado de la lista por inscripción (`monthlyReportPreviousManualDataProvider`), sin pedir nada nuevo al servidor; sin esa lista no se muestra.
- Campos numéricos vacíos se envían como `0`; campos de texto vacíos como `null`.

**Presentación**: un solo chip y estilo de estado para todos los informes (`MonthlyReportStatusChip`). Los nombres de mes van en minúscula a mitad de frase en es, fr y pt-BR (#267). Fechas y «asistentes» se traducen y formatean con la configuración regional.

**Desfase con el backend**: la app modela los estados `approved` y `rejected` (cuatro pasos en el panel), pero el backend solo emite `draft`, `generated` y `submitted`; esos dos estados no ocurren hoy.

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
- **App movil**: usa UUID y `snapshot_data`/`manual_data`, captura y edita `draft`, envia el informe generado y deja la generacion al sistema; queda pendiente limpieza de consumers legacy de enrollment numerico (`EnrollmentModel` conserva `enrollmentUuid` junto al `id` entero)
- **Estado no arbitrado mas alla de submitted**: en backend no existen estados `approved` o `rejected` para monthly reports aunque algunos clientes los modelen

## Prioridad y siguiente accion

- **Prioridad**: Media - el backend esta lo bastante completo para documentar y operar, pero los clientes siguen en drift
- **Siguiente accion**: completar admin web y definir, si hace falta, una accion administrativa auditada para reabrir/regenerar reportes
