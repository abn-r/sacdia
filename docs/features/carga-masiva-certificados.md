# Carga masiva por certificados OCR

**Estado**: IMPLEMENTADO (en `development`). La variante de OCR con ADC y la validación de PDF con `pdf-lib` están **pendientes de merge (PR #448 de sacdia-backend)**.

Superficies en `development`: backend `src/certificate-bulk-imports` (26 rutas), admin `/dashboard/certificate-bulk-imports*` y `/dashboard/institutional-certificate-requests*`, app `lib/features/certificate_import`.

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
- OCR seam: `CertificateOcrProvider` + `GoogleVisionCertificateOcrProvider`. En `development` llama a la API REST `images:annotate` autenticada con `GOOGLE_VISION_API_KEY`; sin clave responde `CERTIFICATE_IMPORT_OCR_UNAVAILABLE`. El cliente oficial con ADC está pendiente de merge (PR #448).

### Endpoints miembro

| Metodo | Path | Descripcion |
|---|---|---|
| POST | `/api/v1/certificate-bulk-imports` | Crear borrador con archivos/comprobantes |
| POST | `/api/v1/certificate-bulk-imports/:batchId/process-ocr` | Encolar la lectura. Sin Redis responde `CERTIFICATE_IMPORT_OCR_UNAVAILABLE` y no marca el lote como leído |
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
3. Una fila aprobada es idempotente: no duplica `users_honors` ni `enrollments`. Dos aprobaciones simultáneas reclaman la fila con `revision`; la segunda no crea otro hecho. Un rechazo simultáneo tampoco pisa una fila ya reclamada.
4. El OCR no valida; solo prellena datos.
5. Las pantallas de registros importados deben mostrar vista simplificada basada en comprobante, no el checklist/progreso normal.

## Reglas confirmadas el 2026-09-21

> [!WARNING]
> **Pendiente de merge (PR #448 de sacdia-backend).** Lo que esta sección dice de ADC, gRPC, PDF de 1 a 5 páginas y validación con `pdf-lib` describe la rama `feat/investiture-authorization-ocr`. En `development` el proveedor usa `GOOGLE_VISION_API_KEY` sobre REST.

La aprobación de una fila CLASS ya acredita el hecho histórico. La subida nueva pide una URL firmada, confirma los bytes y guarda la clave sellada. La lectura automática usa Google Cloud Vision con **Application Default Credentials (ADC)** sobre JPEG, PNG, WebP y PDF completos de **1 a 5 páginas**, con máximo binario de **10 MiB** por documento. `GOOGLE_VISION_API_KEY` ya no autentica este proveedor. El SDK oficial usa gRPC con bytes, no REST/base64, GCS ni una URL pública.

La petición del miembro encola el trabajo en `certificate-import-ocr` (concurrencia 1, dos intentos); no comparte el worker de finanzas ni rankings. Aceptar la cola **no** significa que OCR terminó. Sin Redis la petición responde `CERTIFICATE_IMPORT_OCR_UNAVAILABLE`. ADC ausente/inválido, cuota, deadline o fallo de lectura se detectan en el worker; no se registra `OCR_PROCESSED` ante fallo o respuesta PDF incompleta. La app espera brevemente tras encolar y abre la revisión incluso cuando falla la lectura: el miembro puede agregar/corregir filas a mano si conserva evidencia confirmada válida. El OCR no verifica autenticidad, no aprueba ni acredita el certificado.

En confirmación, el backend analiza el PDF real con `pdf-lib`: rechaza cifrado, corrupto/truncado, sin páginas o con más de cinco páginas antes de sellar/confirmar. Sella **el mismo Buffer validado** en una clave exclusiva por intento (`batches/{batchId}/sealed/{fileId}-{attemptUuid}.pdf`), no una copia posterior del staging mutable. Antes de OCR se vuelve a validar el PDF, incluidos comprobantes antiguos. La verificación de cierre/xref es mínima, no una certificación completa ISO ni un límite de CPU/descompresión del parser. La app informa el máximo de páginas sin duplicar el parser. [Operación, identidad y limitaciones](../guides/google-vision-certificate-ocr.md).

El comprobante se abre con la descarga firmada, no con `file_url`. La bandeja institucional mantiene contrato, persistencia y panel exclusivo del superadministrador.

Un expediente admite un documento activo. El dueño descarga su comprobante sellado. Campo Local descarga los de su campo. Una evidencia `INSTITUTIONAL` solo la descargan el dueño y el superadministrador. No hay fallback a URL pública. El bucket `R2_BUCKET_CERTIFICATE_IMPORTS` es opcional al arrancar; sin esa configuración la subida responde `CERTIFICATE_IMPORT_STORAGE_UNAVAILABLE`.

Enviar el expediente exige al menos una fila completa y un archivo `CONFIRMED` con `object_key`. Una fecha futura, un catálogo inexistente o una `expected_revision` vieja no pisan el borrador. Un lote compuesto solo por Guía Mayor Avanzado o Instructor no se manda a Campo Local. Esas clases se envían a `institutional_certificate_requests`. Aprobar esa solicitud no crea `enrollments`.

Tres vías distintas:

- Cursado y validación anual: requisitos, duración, ceremonia y estados hasta `INVESTIDO` por el flujo normal de investidura.
- Acreditación histórica de Campo Local: el comprobante prueba un hecho ya ocurrido. No exige clase en curso, clase anterior, orden ni posición en la escala. Una clase aprobada queda `INVESTIDO` con la fecha del certificado.
- Guía Mayor (`GM-01`): el comprobante aprobado sustituye la inscripción actual de esa clase. Queda una sola fila, `INVESTIDO`, en el periodo de la fecha del certificado. No se conservan dos inscripciones. Guía Mayor es, por ahora, la última clase del recorrido: el año siguiente la persona sigue como miembro y no recibe otra clase ni otra fila GM.
- Guía Mayor Avanzado e Instructor: no las acredita Campo Local y no crean `enrollments` al aprobar la solicitud. Van a una bandeja exclusiva del superadministrador.

## Despliegue

El orden es schema aditivo, backend con la cola apagada si no hay Redis, y después los clientes. ADC debe estar disponible para el worker; sin credenciales o Redis no hay lectura exitosa y el expediente válido puede completarse a mano. Usar una identidad dedicada por ambiente y privilegios mínimos; nunca subir ADC personal a Render. El flujo base está en `development`; la parte ADC está pendiente de merge (PR #448). Configuración Render y smoke OCR real siguen pendientes de autorización. Ver [runbook](../guides/google-vision-certificate-ocr.md). Ante una falla, se dejan de aceptar cargas y aprobaciones nuevas; la lectura y la auditoría se conservan. No se borran hechos ya acreditados ni se restauran índices viejos. `scripts/audit-certificate-imports.ts` solo informa y rechaza `--apply`. No usa `DATABASE_URL`.

### Estados de la bandeja institucional

Vigentes en `institutional_certificate_requests`. Solo el superadministrador decide. En HTTP, Campo Local, admin genérico y Unión reciben `GUARD_PERMISSION_DENIED` en el guard de la bandeja. Si la petición llega al servicio, responde `CERTIFICATE_IMPORT_INSTITUTIONAL_FORBIDDEN`. Unión pasa el alias de Campo Local en la bandeja común y el servicio responde `CERTIFICATE_IMPORT_REVIEWER_SCOPE_REQUIRED`.

| Estado | Significado |
|---|---|
| `PENDING_REVIEW` | Solicitud enviada, con comprobante confirmado. Un periodo faltante bloquea la aprobación y no rechaza el documento. |
| `APPROVED` | El superadministrador validó el expediente. No significa que la clase quedó inscrita. |
| `REJECTED` | Rechazo con motivo visible para el solicitante. La decisión queda inmutable. |

### Errores públicos

Ya usados por el runtime, como `BadRequestException` con mensaje estable:

- `CERTIFICATE_IMPORT_YEAR_NOT_FOUND`
- `CERTIFICATE_IMPORT_YEAR_AMBIGUOUS`
- `CERTIFICATE_IMPORT_ITEM_MISSING_CLASS`
- `CERTIFICATE_IMPORT_ITEM_MISSING_DATE`
- `CERTIFICATE_IMPORT_FILE_REQUIRED`
- `CERTIFICATE_IMPORT_INSTITUTIONAL_REVIEW_REQUIRED`: Guía Mayor Avanzado (`GM-02`) o Instructor (`GM-03`). Campo Local no crea `enrollments`.
- `CERTIFICATE_IMPORT_FINAL_DATE_CONFLICT`: ya existe un hecho final aprobado con otra fecha civil.
- `CERTIFICATE_IMPORT_ENROLLMENT_RECONCILIATION_REQUIRED`: hay un cursado ordinario del mismo periodo y la aprobación no identifica esa inscripción, o hay más de una fila de Guía Mayor.
- `CERTIFICATE_IMPORT_ENROLLMENT_MISMATCH`: el identificador enviado no es la inscripción de ese usuario, clase y periodo.
- `CERTIFICATE_IMPORT_ENROLLMENT_VERSION_CONFLICT`: `modified_at` de esa inscripción cambió. Hay que volver a leer el detalle.
- `CERTIFICATE_IMPORT_INSTITUTIONAL_FORBIDDEN`: la bandeja institucional no es de Campo Local, admin genérico ni Unión. En HTTP el guard responde antes con `GUARD_PERMISSION_DENIED`.
- `CERTIFICATE_IMPORT_REVIEWER_SCOPE_REQUIRED`: el rol pasó el alias de Campo Local, pero no tiene ámbito sobre el expediente. Unión cae aquí en la bandeja común.
- `CERTIFICATE_IMPORT_DECISION_IMMUTABLE`: la solicitud ya tiene la decisión contraria.
- `CERTIFICATE_IMPORT_CLASS_NOT_INSTITUTIONAL`: la clase no es Guía Mayor Avanzado ni Instructor.
- `CERTIFICATE_IMPORT_REQUEST_NOT_FOUND`
- `CERTIFICATE_IMPORT_STATUS_INVALID`
- `CERTIFICATE_IMPORT_OCR_UNAVAILABLE`: Redis ausente al encolar, o credenciales ADC/autorización no disponibles en el worker. Evidencia válida confirmada permite captura manual.
- `CERTIFICATE_IMPORT_OCR_UNSUPPORTED_TYPE`: el comprobante no es JPEG, PNG, WebP ni PDF.
- `CERTIFICATE_IMPORT_OCR_QUOTA`: Vision rechazó la lectura por cuota.
- `CERTIFICATE_IMPORT_OCR_FILE_TOO_LARGE`: el archivo supera 10 MiB, el tope binario del comprobante.
- `CERTIFICATE_IMPORT_OCR_FAILED`: fallo/deadline, páginas faltantes/duplicadas/extra o con error, o ausencia de texto usable. El archivo sellado válido permanece.
- HTTP 400 `CERTIFICATE_IMPORT_PDF_TOO_MANY_PAGES`: dividir o extraer hasta cinco páginas y volver a subir.
- HTTP 400 `CERTIFICATE_IMPORT_PDF_ENCRYPTED`: quitar contraseña/protección y volver a subir.
- HTTP 400 `CERTIFICATE_IMPORT_PDF_INVALID`: volver a exportar el PDF y subirlo; nunca se muestran detalles internos del parser.

La aprobación de `GM-01` es la confirmación de sustitución: reutiliza la fila existente, la pasa a `HISTORICAL_CERTIFICATE` / `INVESTIDO` y conserva el mismo `enrollment_id`. `investiture_date` es la fecha del certificado. `enrollment_date` de un alta nueva es la fecha técnica del registro, no el inicio del cursado. Un hecho final idéntico solo vincula el comprobante. Cada fila se decide sola. El lote sigue `SUBMITTED` mientras quede alguna fila sin decidir. Pasa a `APPROVED` cuando todas quedaron aprobadas y a `NEEDS_CORRECTION` cuando todas quedaron decididas y al menos una fue rechazada. `PARTIALLY_APPROVED` permanece en el enum y en el filtro de la bandeja para expedientes anteriores; una decisión nueva no lo asigna. Una fila institucional no se decide en esta bandeja.

Si la clase y el periodo ya tienen una inscripción operativa no investida, y no es Guía Mayor, la aprobación debe enviar `reconcile_enrollment_id` y `expected_modified_at`. Eso inviste esa fila, conserva el identificador, `record_kind`, el progreso y `enrollment_date`, y escribe el historial. Sin esos datos la aprobación no cambia la inscripción. El detalle del lote incluye `operational_reconciliation` para esa confirmación. La ficha del usuario enlaza el comprobante sellado del logro y, si la fila es histórica, muestra el progreso archivado sin abrirlo como checklist.
