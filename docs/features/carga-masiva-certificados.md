# Carga masiva por certificados OCR

**Estado**: EN IMPLEMENTACION

## Descripcion de dominio

La carga masiva por certificados permite que un miembro suba comprobantes o certificados desde `sacdia-app` para registrar varias especialidades/honores y clases en una sola operacion. El OCR solo propone datos: el miembro confirma/corrige las filas y el Campo Local aprueba desde `sacdia-admin` antes de aplicar los registros.

El flujo soporta certificados variados y mixtos: un mismo comprobante puede contener varias especialidades y una o mas clases. Cuando OCR no detecta todos los datos necesarios, la app precarga lo encontrado y solicita al usuario completar tipo, elemento de catalogo y fecha de completado/certificacion.

## Regla principal

OCR propone, el miembro confirma y Campo Local valida. La aprobacion aplica a las tablas existentes del dominio; las tablas de importacion son staging/auditoria, no una fuente paralela.

## Backend

### Modulo

- `CertificateBulkImportsModule`
- Controlador miembro: `CertificateBulkImportsController`
- Controlador admin: `AdminCertificateBulkImportsController`
- Servicio workflow: `CertificateBulkImportsService`
- Servicio aplicacion: `CertificateBulkImportApplicationService`
- OCR seam: `CertificateOcrProvider` + `NoopCertificateOcrProvider`

### Endpoints miembro

| Metodo | Path | Descripcion |
|---|---|---|
| POST | `/api/v1/certificate-bulk-imports` | Crear borrador con archivos/comprobantes |
| POST | `/api/v1/certificate-bulk-imports/:batchId/process-ocr` | Ejecutar OCR y crear filas editables |
| GET | `/api/v1/certificate-bulk-imports/:batchId` | Consultar lote propio |
| PATCH | `/api/v1/certificate-bulk-imports/:batchId/items/:itemId` | Corregir fila OCR |
| POST | `/api/v1/certificate-bulk-imports/:batchId/submit` | Enviar a revision de Campo Local |
| POST | `/api/v1/certificate-bulk-imports/:batchId/items/:itemId/resubmit` | Corregir y reenviar fila rechazada |

### Endpoints admin

| Metodo | Path | Descripcion |
|---|---|---|
| GET | `/api/v1/admin/certificate-bulk-imports/pending` | Listar lotes pendientes del scope del revisor |
| GET | `/api/v1/admin/certificate-bulk-imports/:batchId` | Detalle de lote para revision |
| POST | `/api/v1/admin/certificate-bulk-imports/:batchId/approve` | Aprobar filas pendientes del lote |
| POST | `/api/v1/admin/certificate-bulk-imports/:batchId/reject` | Rechazar lote y pedir correccion |
| POST | `/api/v1/admin/certificate-bulk-imports/:batchId/items/:itemId/approve` | Aprobar una fila |
| POST | `/api/v1/admin/certificate-bulk-imports/:batchId/items/:itemId/reject` | Rechazar una fila con motivo |

## Base de datos

Tablas de workflow/auditoria:

- `certificate_bulk_import_batches`
- `certificate_bulk_import_items`
- `certificate_bulk_import_files`
- `certificate_bulk_import_item_events`

Tablas finales existentes:

- HONOR aprobado → `users_honors` + `evidence_files.user_honor_id`
- CLASS aprobada → `enrollments` + `investiture_validation_history`

## Estados

### Batch

- `DRAFT`
- `READY_TO_SUBMIT`
- `SUBMITTED`
- `PARTIALLY_APPROVED`
- `APPROVED`
- `REJECTED`
- `NEEDS_CORRECTION`

### Item

- `NEEDS_REVIEW`
- `READY`
- `SUBMITTED`
- `APPROVED`
- `REJECTED`
- `RESUBMITTED`

## UX mobile

- Flujo estilo asistente: subir comprobante, leer OCR, revisar sabana de datos, editar fila, enviar a revision y ver estado.
- La sabana usa cards, no tabla, porque puede haber pocos o muchos registros y el usuario corrige desde telefono.
- Las filas muestran tipo (`HONOR`/`CLASS`), nombre detectado, match de catalogo, fecha y confianza.
- Si una fila rechazada vuelve al miembro, puede corregirse y reenviarse.

## UX admin

- Bandeja de Campo Local con KPIs, filtros y tabla de lotes.
- Detalle split view: comprobante sticky + datos/filas/auditoria.
- Aprobacion por lote o por fila.
- Rechazo siempre requiere motivo visible para el miembro.

## Invariantes

1. El miembro solo opera sus propios lotes.
2. El revisor de Campo Local solo revisa lotes de su `local_field_id`, salvo roles globales.
3. Una fila aprobada es idempotente: no duplica `users_honors` ni `enrollments`.
4. El OCR no valida; solo prellena datos.
5. Las pantallas de registros importados deben mostrar vista simplificada basada en comprobante, no el checklist/progreso normal.
