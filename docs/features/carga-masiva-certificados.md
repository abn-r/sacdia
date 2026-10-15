# Carga masiva por certificados OCR

**Estado**: IMPLEMENTADO (en `development`). La variante de OCR con ADC y la validación de PDF con `pdf-lib` entraron con la PR #448 de sacdia-backend (2026-10-07); el proxy keyless (`OCR_MODE=remote`) está aprobado en local y no desplegado.

Superficies en `development`: backend `src/certificate-bulk-imports` (28 rutas) y `src/instructors`, admin `/dashboard/certificate-bulk-imports*`, `/dashboard/institutional-certificate-requests*` y `/dashboard/honor-instructor-proposals`, app `lib/features/certificate_import`.

**Rediseño (2026-10-12, implementado):** catálogos de especialidades y clases con nombres en las filas, instructor opcional, rango de fechas 1960-01-01..hoy, estado de lectura (`ocr_state`), archivo y página de origen de cada fila, borrado de borradores y revisión de Campo Local con instructor y conflicto. Backend #473 a #476 y #478, admin #227 a #229, app #161 a #170. Ver «Rediseño: instructor, catálogos, fechas, lectura y páginas». Plan y estado por slice: `docs/plans/2026-10-09-certificate-import-instructor-data-model.md`.

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
- OCR seam: `CertificateOcrProvider`, con dos proveedores elegidos por `OCR_MODE`: `GoogleVisionCertificateOcrProvider` (modo `direct`, cliente oficial con ADC local) y `CloudRunCertificateOcrProvider` (modo `remote`, HTTPS firmado con HMAC hacia el proxy `sacdia-ocr-proxy`). Estado: ambos aprobados en local; el proxy **no está desplegado**.

### Endpoints miembro

| Metodo | Path | Descripcion |
|---|---|---|
| GET | `/api/v1/certificate-bulk-imports` | Listar expedientes propios para retomarlos |
| POST | `/api/v1/certificate-bulk-imports` | Crear borrador con archivos/comprobantes |
| POST | `/api/v1/certificate-bulk-imports/:batchId/process-ocr` | Encolar la lectura. Sin Redis responde `CERTIFICATE_IMPORT_OCR_UNAVAILABLE` y no marca el lote como leído |
| GET | `/api/v1/certificate-bulk-imports/catalog/classes?clubTypeId=` | Clases elegibles (incluye retiradas e institucionales con `institutional: true`) |
| GET | `/api/v1/certificate-bulk-imports/:batchId` | Consultar lote propio (con `ocr_state`, `ocr_error_code`, páginas e instructor) |
| DELETE | `/api/v1/certificate-bulk-imports/:batchId` | Descartar un borrador propio (solo `DRAFT`) |
| PATCH | `/api/v1/certificate-bulk-imports/:batchId/items/:itemId` | Corregir fila OCR |
| POST | `/api/v1/certificate-bulk-imports/:batchId/submit` | Enviar a revision de Campo Local |
| POST | `/api/v1/certificate-bulk-imports/:batchId/items/:itemId/resubmit` | Corregir y reenviar fila rechazada |

El alta, el `PATCH` y el borrado de filas (`POST`/`DELETE .../items`), y los archivos (`files/presign`, `files/:fileId/confirm`, `files/:fileId/download`, `DELETE files/:fileId`) están en `docs/api/ENDPOINTS-LIVE-REFERENCE.md`. Instructores: `GET /api/v1/instructor-candidates?q=` (módulo `src/instructors`, compartido con «Mis especialidades»).

### Endpoints admin

| Metodo | Path | Descripcion |
|---|---|---|
| GET | `/api/v1/admin/certificate-bulk-imports/pending` | Listar lotes pendientes del scope del revisor |
| GET | `/api/v1/admin/certificate-bulk-imports/:batchId` | Detalle de lote para revision |
| POST | `/api/v1/admin/certificate-bulk-imports/:batchId/approve` | Aprobar filas pendientes del lote |
| POST | `/api/v1/admin/certificate-bulk-imports/:batchId/reject` | Rechazar lote y pedir correccion |
| POST | `/api/v1/admin/certificate-bulk-imports/:batchId/items/:itemId/approve` | Aprobar una fila |
| POST | `/api/v1/admin/certificate-bulk-imports/:batchId/items/:itemId/reject` | Rechazar una fila con motivo |

La cola de propuestas de instructor sobre especialidades ya aprobadas (`/api/v1/admin/honor-instructor-proposals`) tiene el mismo revisor y alcance; ver [honores](honores.md).

## Base de datos

Tablas de workflow/auditoria:

- `certificate_bulk_import_batches`
- `certificate_bulk_import_items`
- `certificate_bulk_import_files`
- `certificate_bulk_import_item_events`

Columnas añadidas por el rediseño (migraciones M1 y M2; detalle en `docs/database/SCHEMA-REFERENCE.md`):

- `certificate_bulk_import_items.instructor_user_id` / `instructor_name` (solo filas HONOR; como máximo uno), `source_file_id` (FK a `certificate_bulk_import_files`, `ON DELETE SET NULL`) y `source_page`.
- `certificate_bulk_import_files.page_count`.
- Al aprobar una fila HONOR, el instructor y `completed_at` se copian a `users_honors` (`instructor_*`, `completed_at`).

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

### Lectura OCR (`ocr_state`, derivado)

No es columna: se deriva de los eventos `OCR_QUEUED`, `OCR_PROCESSED` y `OCR_FAILED` del lote y del job de BullMQ.

| Valor | Significado |
|---|---|
| `null` | Nunca se pidió la lectura |
| `pending` | En cola (incluye la espera entre dos intentos) |
| `running` | El worker está leyendo |
| `done` | Terminó y propuso al menos una fila |
| `empty` | Terminó sin filas: captura manual |
| `failed` | Falló; `ocr_error_code` trae la causa si el worker la registró (lista blanca) |

## UX mobile

- Flujo estilo asistente: subir comprobante (con progreso y reintento que conserva el lote y el archivo), esperar la lectura, revisar la sábana de datos, editar fila, enviar a revisión y ver estado.
- La sábana usa cards, no tabla, porque puede haber pocos o muchos registros y el usuario corrige desde teléfono. La revisión agrupa las filas, muestra qué falta de cada una y tiene un dock con «Completar N» y «Enviar».
- Las filas muestran tipo (`HONOR`/`CLASS`), el nombre **detectado** por el OCR, el nombre del catálogo **elegido por el miembro** (con categoría o tipo de club), la fecha y una alerta «Revisa la fecha» cuando la confianza de la fecha es menor a 0.8. **El OCR no hace match de catálogo**: `honor_id` y `class_id` los elige el miembro en el editor.
- Espera de lectura: la app sondea `ocr_state` cada 2 s, avisa que sigue leyendo a los 8 s y deja de esperar a los 60 s; si el estado es `empty` o `failed` abre la revisión con captura manual y reintento.
- El comprobante se abre en el archivo y la página de la fila (`source_file_id`, `source_page`); si faltan, en el primer archivo, página 1.
- El editor elige especialidad (`GET /honors?search=`) y clase (`catalog/classes`) de listas, pide la fecha entre 1960-01-01 y hoy y, en filas de especialidad, un instructor opcional (usuario de tu Campo Local o nombre libre). El instructor no cuenta para dejar la fila lista.
- Cancelar o abandonar durante la subida borra el borrador (`DELETE`), sin bloquear al usuario.
- Si una fila rechazada vuelve al miembro, puede corregirse y reenviarse.

## UX admin

- Bandeja de Campo Local con KPIs, filtros y tabla de lotes.
- Detalle split view: comprobante sticky + datos/filas/auditoria.
- Aprobacion por lote o por fila.
- El detalle muestra el estado de lectura (`ocr_state`), el instructor de cada especialidad (sin correo ni foto), un aviso cuando hay `instructor_conflict` (la especialidad ya estaba aprobada con otro instructor y se conservó) y el archivo y página de cada fila.
- Rechazo siempre requiere motivo visible para el miembro.

## Invariantes

1. El miembro solo opera sus propios lotes.
2. El revisor de Campo Local solo revisa lotes de su `local_field_id`, salvo roles globales.
3. Una fila aprobada es idempotente: no duplica `users_honors` ni `enrollments`. Dos aprobaciones simultáneas reclaman la fila con `revision`; la segunda no crea otro hecho. Un rechazo simultáneo tampoco pisa una fila ya reclamada.
4. El OCR no valida; solo prellena datos.
5. Las pantallas de registros importados deben mostrar vista simplificada basada en comprobante, no el checklist/progreso normal.
6. El instructor es opcional, solo de filas HONOR, y nunca bloquea dejar la fila lista ni enviar. Un usuario del sistema debe ser del mismo Campo Local que el dueño del lote, activo, aprobado y mayor de edad; el nombre libre no entra a la auditoría.
7. `completed_at` (especialidad) y fecha de investidura (clase) van entre 1960-01-01 y hoy. Una fecha del OCR fuera de rango no se guarda como `completed_at`: queda en `detected_date`.
8. Solo se borra un borrador `DRAFT` propio y sin solicitudes institucionales, y nunca con una lectura OCR en cola o en curso.

## Reglas confirmadas el 2026-09-21

La aprobación de una fila CLASS ya acredita el hecho histórico. La subida nueva pide una URL firmada, confirma los bytes y guarda la clave sellada. La lectura automática usa Google Cloud Vision con **Application Default Credentials (ADC)** sobre JPEG, PNG, WebP y PDF completos de **1 a 5 páginas**, con máximo binario de **10 MiB** por documento. `GOOGLE_VISION_API_KEY` ya no autentica este proveedor. El SDK oficial usa gRPC con bytes, no REST/base64, GCS ni una URL pública. ADC es el modo `direct`, solo para la Mac del desarrollador.

La petición del miembro encola el trabajo en `certificate-import-ocr` (concurrencia 1, dos intentos); no comparte el worker de finanzas ni rankings. Aceptar la cola **no** significa que OCR terminó. Sin Redis la petición responde `CERTIFICATE_IMPORT_OCR_UNAVAILABLE`. ADC ausente/inválido, cuota, deadline o fallo de lectura se detectan en el worker; no se registra `OCR_PROCESSED` ante fallo o respuesta PDF incompleta. La app espera brevemente tras encolar y abre la revisión incluso cuando falla la lectura: el miembro puede agregar/corregir filas a mano si conserva evidencia confirmada válida. El OCR no verifica autenticidad, no aprueba ni acredita el certificado.

En confirmación, el backend analiza el PDF real con `pdf-lib` dentro de un `worker_thread` descartable (un worker a la vez, con tope de descompresión): rechaza cifrado, corrupto/truncado, sin páginas o con más de cinco páginas antes de sellar/confirmar. Si no obtiene turno de validación, `confirm` responde HTTP 429 `CERTIFICATE_IMPORT_PDF_BUSY` y el archivo no queda confirmado. Sella **el mismo Buffer validado** en una clave exclusiva por intento (`batches/{batchId}/sealed/{fileId}-{attemptUuid}.pdf`), no una copia posterior del staging mutable. Antes de OCR se vuelve a validar el PDF, incluidos comprobantes antiguos. La verificación de cierre/xref es mínima, no una certificación completa ISO; la contención de memoria y descompresión (TaskR) está aprobada en local y no se midió en Render. La app informa el máximo de páginas sin duplicar el parser. [Operación, identidad y limitaciones](../guides/google-vision-certificate-ocr.md).

El comprobante se abre con la descarga firmada, no con `file_url`. La bandeja institucional mantiene contrato, persistencia y panel exclusivo del superadministrador.

Un expediente admite un documento activo. El dueño descarga su comprobante sellado. Campo Local descarga los de su campo. Una evidencia `INSTITUTIONAL` solo la descargan el dueño y el superadministrador. No hay fallback a URL pública. El bucket `R2_BUCKET_CERTIFICATE_IMPORTS` es opcional al arrancar; sin esa configuración la subida responde `CERTIFICATE_IMPORT_STORAGE_UNAVAILABLE`.

Enviar el expediente exige al menos una fila completa y un archivo `CONFIRMED` con `object_key`. Una fecha futura, un catálogo inexistente o una `expected_revision` vieja no pisan el borrador. Un lote compuesto solo por Guía Mayor Avanzado o Instructor no se manda a Campo Local. Esas clases se envían a `institutional_certificate_requests`. Aprobar esa solicitud no crea `enrollments`.

Tres vías distintas:

- Cursado y validación anual: requisitos, duración, ceremonia y estados hasta `INVESTIDO` por el flujo normal de investidura.
- Acreditación histórica de Campo Local: el comprobante prueba un hecho ya ocurrido. No exige clase en curso, clase anterior, orden ni posición en la escala. Una clase aprobada queda `INVESTIDO` con la fecha del certificado.
- Guía Mayor (`GM-01`): el comprobante aprobado sustituye la inscripción actual de esa clase. Queda una sola fila, `INVESTIDO`, en el periodo de la fecha del certificado. No se conservan dos inscripciones. Guía Mayor es, por ahora, la última clase del recorrido: el año siguiente la persona sigue como miembro y no recibe otra clase ni otra fila GM.
- Guía Mayor Avanzado e Instructor: no las acredita Campo Local y no crean `enrollments` al aprobar la solicitud. Van a una bandeja exclusiva del superadministrador.

## Rediseño: instructor, catálogos, fechas, lectura y páginas

Vigente en `development` desde 2026-10-12. Contrato campo por campo y códigos de error: `docs/api/ENDPOINTS-LIVE-REFERENCE.md` §«Estado de lectura, instructor y páginas» y el contrato canónico de `docs/api/API-SPECIFICATION.md`.

- **Catálogos.** `GET /honors?search=` (2 a 60 caracteres) y `GET /certificate-bulk-imports/catalog/classes` (con retiradas e institucionales). Las respuestas de lote traen `honor {name, category}` y `class {name, asset_code, club_type}` con nombres traducidos, para no resolver ids en el cliente. `club_type_id` en el cuerpo de una fila CLASS es solo una verificación de coherencia (`CERTIFICATE_IMPORT_CLASS_CLUB_TYPE_MISMATCH`).
- **Instructor.** Bloque `instructor` `{ kind: USER | EXTERNAL, user_id?, display_name, photo_url? }`. Buscador `GET /instructor-candidates?q=` (JWT, 30/min, mismo Campo Local, sin correo, máximo 10). Escritura `instructor_user_id` o `instructor_name`, como máximo uno. En una fila CLASS se rechaza (`CERTIFICATE_IMPORT_HONOR_INSTRUCTOR_NOT_ALLOWED`). Al crear el lote, un instructor inválido no rompe el alta: la fila nace `NEEDS_REVIEW` con el código en `rejection_reason`.
- **Aprobación e instructor (D7).** Sin fila previa de `users_honors`: se copia el instructor del ítem. Fila aún no `APPROVED`: el instructor del ítem, si trae, reemplaza al declarado; si no trae, se conserva el existente (nunca se borra por omisión). Fila ya `APPROVED` (misma fecha): se completa si no tenía; si tenía **otro**, se conserva el existente y se marca `instructor_conflict` en la respuesta, el detalle admin y el evento `ITEM_APPROVED`. La fecha se compara contra `completed_at ?? date` de la especialidad aprobada.
- **Fechas.** `completed_at` entre 1960-01-01 y hoy (`CERTIFICATE_IMPORT_DATE_TOO_OLD`, `_IN_FUTURE`, `_INVALID`). `PATCH`/`resubmit` responden 400; al crear sin `mark_as_ready` la fila nace `NEEDS_REVIEW`; con `mark_as_ready: true` la creación responde 400.
- **Lectura.** `ocr_state` y `ocr_error_code` en las respuestas del lote. `OCR_QUEUED` se registra antes de encolar. Una lectura en cola o en curso no se duplica; tras un fallo, `process-ocr` de nuevo reintenta. Un reproceso solo descarta filas que el miembro no tocó (sin catálogo, instructor ni ediciones).
- **Páginas y archivo.** El OCR trabaja por archivo y por página (tope de 5 páginas por documento). Cada fila guarda `source_file_id` y `source_page`; cada archivo, `page_count`.
- **Borrar borrador.** `DELETE /certificate-bulk-imports/:batchId`: 404 si no es del usuario, 409 `CERTIFICATE_IMPORT_BATCH_NOT_DELETABLE` (ya no es `DRAFT` o tiene solicitudes institucionales) y 409 `CERTIFICATE_IMPORT_OCR_IN_PROGRESS`. Borra filas, archivos y eventos en cascada y, después del commit, los objetos de R2 (mejor esfuerzo); no queda traza en base, solo en el log.
- **Migraciones.** M1 `20261010120000_certificate_import_honor_instructor` y M2 `20261010130000_certificate_import_ocr_pages`. Estado por rama de Neon y procedimiento: `docs/deployment/DEPLOYMENT-GUIDE.md` §0.5.

## Despliegue

El orden es schema aditivo, backend con la cola apagada si no hay Redis, y después los clientes. Sin Redis o sin una vía de lectura disponible no hay lectura exitosa y el expediente válido puede completarse a mano. Nunca subir ADC personal a Render ni generar claves de cuenta de servicio o API keys: la organización bloquea las claves y el diseño es keyless.

Estado del OCR automático (2026-10-07), distinguiendo local de desplegado:

- **Aprobado en local** (`PASS_LOCAL_SLICE`): contrato HMAC v1, ledger Firestore y cuota (probado con emulador), contención PDF en Render, handler del proxy con Vision simulado y adaptador `remote` del backend.
- **No desplegado**: no existen Cloud Run, Firestore, Secret Manager ni el modo `remote` en Render. Los servicios de Render están en plan Free (512 MB, 0,1 CPU). El entrypoint de producción del proxy sigue en implementación. El humo con Vision real no se ejecutó.
- `OCR_MODE` elige el proveedor: `direct` (ADC en la Mac) o `remote` (proxy). Es obligatorio con `NODE_ENV=production`; un `remote` incompleto impide el arranque y no cae a ADC.

Flujo `remote`: Render lee el comprobante sellado, valida y cuenta las páginas del PDF y envía el Buffer firmado al proxy; el proxy reserva hasta 400 páginas por día UTC y por entorno (compartidas entre usuarios), confirma `CALLING` en Firestore y hace una sola llamada a Vision. Una incertidumbre (crash, plazo, red, respuesta perdida) pasa a revisión manual sin segunda llamada; no hay exactly-once. El texto OCR nunca se guarda en el ledger. Ver [runbook](../guides/google-vision-certificate-ocr.md), [infraestructura de preproducción](../guides/ocr-proxy-preprod-infra.md) y [ADR 11](../api/ARCHITECTURE-DECISIONS.md). Ante una falla, se dejan de aceptar cargas y aprobaciones nuevas; la lectura y la auditoría se conservan. No se borran hechos ya acreditados ni se restauran índices viejos. `scripts/audit-certificate-imports.ts` solo informa y rechaza `--apply`. No usa `DATABASE_URL`.

### Estados de la bandeja institucional

Vigentes en `institutional_certificate_requests`. Solo el superadministrador decide. En HTTP, Campo Local, admin genérico y Unión reciben `GUARD_PERMISSION_DENIED` en el guard de la bandeja. Si la petición llega al servicio, responde `CERTIFICATE_IMPORT_INSTITUTIONAL_FORBIDDEN`. Unión pasa el alias de Campo Local en la bandeja común y el servicio responde `CERTIFICATE_IMPORT_REVIEWER_SCOPE_REQUIRED`.

| Estado | Significado |
|---|---|
| `PENDING_REVIEW` | Solicitud enviada, con comprobante confirmado. Un periodo faltante bloquea la aprobación y no rechaza el documento. |
| `APPROVED` | El superadministrador validó el expediente. No significa que la clase quedó inscrita. |
| `REJECTED` | Rechazo con motivo visible para el solicitante. La decisión queda inmutable. |

### Errores públicos

Ya usados por el runtime, como `BadRequestException` con mensaje estable:

- `CERTIFICATE_IMPORT_DATE_TOO_OLD`, `CERTIFICATE_IMPORT_DATE_IN_FUTURE`, `CERTIFICATE_IMPORT_DATE_INVALID`: `completed_at` fuera de 1960-01-01..hoy o no es una fecha real.
- `CERTIFICATE_IMPORT_HONOR_INSTRUCTOR_NOT_ALLOWED`: instructor en una fila CLASS.
- `CERTIFICATE_IMPORT_CLASS_CLUB_TYPE_MISMATCH`: `club_type_id` no coincide con el de la clase.
- `CERTIFICATE_IMPORT_BATCH_NOT_DELETABLE` (409) y `CERTIFICATE_IMPORT_OCR_IN_PROGRESS` (409): borrado de borrador.
- `HONOR_INSTRUCTOR_AMBIGUOUS`, `HONOR_INSTRUCTOR_INVALID`, `HONOR_INSTRUCTOR_SELF` (400): comparten código con «Mis especialidades».
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
- `CERTIFICATE_IMPORT_OCR_UNAVAILABLE`: Redis ausente al encolar, credenciales ADC/autorización no disponibles (`direct`), o proxy no disponible (`remote`): 401/403/503, redirect, plazo de 40 s, o cualquier 429/5xx/504 de plataforma sin sobre v1 válido. Evidencia válida confirmada permite captura manual. No es la cola de validación PDF de `confirm`.
- `CERTIFICATE_IMPORT_OCR_UNSUPPORTED_TYPE`: el comprobante no es JPEG, PNG, WebP ni PDF.
- `CERTIFICATE_IMPORT_OCR_QUOTA`: Vision rechazó la lectura por cuota, o el proxy agotó las 400 páginas diarias del entorno (solo con un sobre v1 `QUOTA` válido). Un 429 de plataforma sin sobre no es cuota.
- `CERTIFICATE_IMPORT_OCR_FILE_TOO_LARGE`: el archivo supera 10 MiB, el tope binario del comprobante.
- `CERTIFICATE_IMPORT_OCR_FAILED`: fallo/deadline, páginas faltantes/duplicadas/extra o con error, ausencia de texto usable, ejecución incierta, conflicto de operación o lease vigente en el ledger (`remote`). Va a revisión manual sin repetir Vision. El archivo sellado válido permanece.
- HTTP 400 `CERTIFICATE_IMPORT_PDF_TOO_MANY_PAGES`: dividir o extraer hasta cinco páginas y volver a subir.
- HTTP 400 `CERTIFICATE_IMPORT_PDF_ENCRYPTED`: quitar contraseña/protección y volver a subir.
- HTTP 400 `CERTIFICATE_IMPORT_PDF_INVALID`: volver a exportar el PDF y subirlo; nunca se muestran detalles internos del parser.
- HTTP 429 `CERTIFICATE_IMPORT_PDF_BUSY`: hay otros archivos en validación. Reintentar el mismo `confirm` en unos segundos. No borrar el staging. Distinto de `CERTIFICATE_IMPORT_OCR_UNAVAILABLE`.

La aprobación de `GM-01` es la confirmación de sustitución: reutiliza la fila existente, la pasa a `HISTORICAL_CERTIFICATE` / `INVESTIDO` y conserva el mismo `enrollment_id`. `investiture_date` es la fecha del certificado. `enrollment_date` de un alta nueva es la fecha técnica del registro, no el inicio del cursado. Un hecho final idéntico solo vincula el comprobante. Cada fila se decide sola. El lote sigue `SUBMITTED` mientras quede alguna fila sin decidir. Pasa a `APPROVED` cuando todas quedaron aprobadas y a `NEEDS_CORRECTION` cuando todas quedaron decididas y al menos una fue rechazada. `PARTIALLY_APPROVED` permanece en el enum y en el filtro de la bandeja para expedientes anteriores; una decisión nueva no lo asigna. Una fila institucional no se decide en esta bandeja.

Si la clase y el periodo ya tienen una inscripción operativa no investida, y no es Guía Mayor, la aprobación debe enviar `reconcile_enrollment_id` y `expected_modified_at`. Eso inviste esa fila, conserva el identificador, `record_kind`, el progreso y `enrollment_date`, y escribe el historial. Sin esos datos la aprobación no cambia la inscripción. El detalle del lote incluye `operational_reconciliation` para esa confirmación. La ficha del usuario enlaza el comprobante sellado del logro y, si la fila es histórica, muestra el progreso archivado sin abrirlo como checklist.
