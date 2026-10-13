# Carga por certificado: instructor, catálogo y campos de clase — diseño de datos y API

- Fecha: 2026-10-09 (actualizado el 2026-10-10 y el 2026-10-12 con las decisiones del usuario)
- Estado: propuesta con decisiones del usuario incorporadas, D1 a D13 (sin implementar). No se tocó código ni base de datos. No quedan preguntas abiertas sobre el diseño de datos y la API, salvo las dos de §7.2.
- Alcance: `sacdia-backend` (Prisma, `src/certificate-bulk-imports/**`, `src/honors/**`, `src/evidence-review/**`, catálogos, el módulo nuevo de candidatos a instructor y la propuesta de instructor sobre especialidades aprobadas), `sacdia-app` (`lib/features/certificate_import` y `lib/features/honors`), `sacdia-admin` (revisión del Campo Local, visor de comprobantes y cola de propuestas de instructor).
- Fuente leída: `origin/development` de los tres repos (backend `722be4b`, app `07a7088b`, admin `7a6575a`) y las docs canónicas en `docs/`. El flujo normal de especialidades (§1.6) se investigó en esos mismos commits, sin tocar el checkout.
- Documento hermano: `2026-10-09-certificate-import-redesign-design.md` (diseño UX de la app). Los dos comparten las mismas decisiones.

## Decisiones tomadas

Todas las decisiones son del usuario. Reemplazan las propuestas y preguntas abiertas de versiones anteriores de este documento.

| # | Fecha | Decisión | Dónde se aplica en este documento |
|---|---|---|---|
| D1 | 2026-10-09 | El instructor es **opcional** para marcar una especialidad como lista. | §4.1, §7.3 |
| D2 | 2026-10-09 | El buscador de instructores solo devuelve usuarios **activos, aprobados y mayores de edad del mismo Campo Local** que el miembro (no la unión, "de momento"). No exige Guía Mayor. Solo expone nombre y foto. Los instructores de otros campos se cargan como **nombre libre**. | §2.3, §2.6, §4.4, §7.1, §7.3 |
| D3 | 2026-10-09 | El backend expone `ocr_state` (`pending`, `running`, `done`, `empty`, `failed`) en las respuestas del lote. Se deriva del job de OCR, **sin tabla nueva**. | §4.2, §4.6, §7.3 |
| D4 | 2026-10-09 | La API expone `page_count` del archivo y hay una columna nullable `source_page` en `certificate_bulk_import_items`, que el parser OCR llena con la página donde leyó cada fila. El visor abre directo en esa página (app y admin). | §2.2, §2.5, §4.2, §4.7, §6.1, §6.2, §7.3 |
| D5 | 2026-10-09 | Umbral de confianza de fecha: **0.8**. Por debajo, la fila muestra "Revisa la fecha". | §4.2 (`field_confidence.date`), §6.2 |
| D6 | 2026-10-09 | Fecha mínima válida **1960-01-01** y ninguna fecha futura. Aplica a la fecha completada de la especialidad y a la de investidura de la clase. Se valida en la app (formulario) y en el backend (DTO). | §3.1, §4.1, §4.8 |
| D7 | 2026-10-09 | Si la especialidad ya estaba aprobada con otro instructor, se **conserva el existente** y se marca `instructor_conflict` en el evento o la auditoría. El revisor del Campo Local lo ve. | §5, §6.1 |
| D8 | 2026-10-10 | v1 **sin notificación ni confirmación** del instructor. | §5, §7.1 |
| D9 | 2026-10-10 | El conteo de "especialidades enseñadas" incluye **ambos flujos**: la carga por certificado y el flujo normal ("Mis especialidades", `POST/PATCH /users/:userId/honors`). El formulario normal también pide el instructor opcional, con el mismo componente selector (usuario del mismo Campo Local o nombre libre). El selector **no puede depender de un `batchId`**. | §2.1, §4.4, §4.8, §7.3 |
| D10 | 2026-10-12 | En el flujo normal de "Mis especialidades", el instructor (opcional) se captura en `HonorEvidenceView`, antes de "Enviar a revisión". Se guarda con `PATCH /users/:userId/honors/:honorId` y solo se puede editar en `IN_PROGRESS` o `REJECTED`. | §4.8, §7.3 (B5) |
| D11 | 2026-10-12 | En una especialidad **ya aprobada**, el miembro puede proponer **solo el instructor** y el Campo Local lo aprueba o rechaza. El resto de los datos queda congelado. | §2.7, §4.9, §5, §6.1, §7.1, §7.3 (B9, B10) |
| D12 | 2026-10-12 | `certificate_bulk_import_items.source_file_id` (uuid nullable, FK a `certificate_bulk_import_files`, `ON DELETE SET NULL`) se agrega en la misma migración M2 que `source_page`. El lote acepta hasta 10 archivos (`CERTIFICATE_IMPORT_MAX_FILES`). El visor abre el archivo y la página correctos; si falta, usa el primer archivo y la página 1. | §2.2, §2.4, §2.5, §4.2, §4.7, §6, §7.1, §7.3 (B4, B6) |
| D13 | 2026-10-12 | Dos PRs de seguridad aparte, previos al rediseño. **SEC-1** (`fix/honors-create-mutability-guard`): el alta (`POST /users/:userId/honors` y `/bulk`) ya no reescribe especialidades `APPROVED` ni `PENDING_REVIEW`. **SEC-2** (`fix/honors-abandon-restart-guard`, apilado sobre SEC-1): abandonar queda bloqueado en `APPROVED` y `PENDING_REVIEW`, e iniciar sobre una fila inactiva `APPROVED` o `PENDING_REVIEW` solo restaura `active = true`. Prerrequisito de B5 y de B9. | §1.6, §4.8, §7.1, §7.3 |

Consecuencias de diseño derivadas (no son decisiones nuevas):

- El endpoint de búsqueda deja de colgar del lote: pasa a `GET /instructor-candidates?q=`, con el alcance del Campo Local del usuario autenticado (§4.4).
- Los códigos de error de instructor que usan los dos flujos pierden el prefijo `CERTIFICATE_IMPORT_` (§4.5).
- `page_count` se **persiste** al confirmar el archivo (columna nullable en `certificate_bulk_import_files`) en lugar de recalcularse al leer (§2.2, §4.7). Es una elección técnica dentro de D4; si se prefiere no tocar `files`, se calcula al vuelo desde R2, con más costo por lectura.
- Hay **tres migraciones obligatorias** (M1 instructor; M2 páginas y archivo de origen; M4 propuestas de instructor) y una opcional (M3), para que los slices puedan desplegarse por separado (§2.5, §7.3).
- La propuesta de instructor sobre una especialidad aprobada (D11) usa **su propio endpoint y su propia tabla**. No reutiliza el `PATCH` ni el alta, que siguen bloqueados para `APPROVED` (§4.9).
- Con SEC-1 y SEC-2 (D13), el único camino que cambia algo de una especialidad aprobada es la propuesta de D11, y solo cambia el instructor. B5 ya no necesita su propio cierre parcial del hueco de mutabilidad (§4.8).

---

## 0. Resumen

Hoy la fila de carga por certificado guarda `honor_id` o `class_id` crudos y la app los pide como "ID de catálogo" en un campo de texto. No hay ningún dato de instructor en el sistema: ni en `certificate_bulk_import_items` ni en `users_honors`. Se propone:

1. Agregar `instructor_user_id` (FK nullable a `users`) e `instructor_name` (texto libre) en `certificate_bulk_import_items` **y** en `users_honors`, mutuamente excluyentes, solo para filas `HONOR`. El instructor es opcional (D1).
2. No agregar columnas para la clase: el tipo de club sale de `classes.club_type_id` y la fecha de investidura ya es `completed_at`, que la aprobación escribe en `enrollments.investiture_date`.
3. Reemplazar el "ID de catálogo" por selectores: categoría → especialidad (con búsqueda) y tipo de club → clase. Se reutilizan `GET /honors/categories`, `GET /honors` (con un parámetro `search` nuevo) y `GET /catalogs/club-types`. Para las clases se agrega un endpoint dentro del módulo de carga por certificado. Para buscar instructores se agrega **un solo endpoint compartido**, `GET /instructor-candidates?q=`, que sirve a la carga por certificado y al formulario normal de especialidades (D2, D9).
4. La aprobación copia el instructor a `users_honors` y lo deja auditado en `certificate_bulk_import_item_events`. Si ya había otro instructor aprobado, se conserva y se marca `instructor_conflict` (D7).
5. La API del lote expone `ocr_state` (derivado del job, sin tabla nueva, D3), `files[].page_count` y, por fila, `source_page` y `source_file_id` (D4 y D12), para que el visor abra el archivo y la página correctos.
6. Las fechas de especialidad y de investidura se validan entre 1960-01-01 y hoy, en DTO y servicio (D6).
7. El flujo normal de especialidades (`/users/:userId/honors`) recibe los mismos campos de instructor y la misma validación de fechas (D9 y D10, §4.8). El instructor se captura antes de enviar a revisión y solo se edita en `IN_PROGRESS` o `REJECTED`.
8. Una especialidad **ya aprobada** admite una única excepción (D11, §2.7 y §4.9): el miembro propone el instructor en una tabla aparte (`honor_instructor_proposals`, migración M4) con su propio endpoint, y el Campo Local lo aprueba o rechaza. Solo al aprobar se escribe `users_honors.instructor_*`, por un método acotado que no pasa por `assertHonorIsMutable`.
9. Dos PRs de seguridad previos (D13), SEC-1 y SEC-2, cierran el alta, el abandono y el reinicio que hoy permiten reescribir una especialidad aprobada o en revisión. Son prerrequisito de B5 y B9 (§7.3).

---

## 1. Estado actual

### 1.1 Tablas del flujo (`prisma/schema.prisma`)

| Tabla | Campos relevantes | Notas |
|---|---|---|
| `certificate_bulk_import_batches` | `batch_id` uuid, `user_id`, `local_field_id`, `status` (`DRAFT`…`NEEDS_CORRECTION`), `raw_ocr_payload` Json, `revision` | Un expediente por subida del miembro. |
| `certificate_bulk_import_files` | `file_id`, `batch_id`, `object_key`, `upload_status`, `jurisdiction` (`CAMPO_LOCAL`/`INSTITUTIONAL`), `size_bytes` BigInt | Comprobantes sellados en R2. |
| `certificate_bulk_import_items` | `item_id`, `batch_id`, `item_type` (`HONOR`/`CLASS`), `honor_id` Int?, `class_id` Int?, `detected_name` varchar(255), `detected_date` date, `completed_at` date, `ocr_confidence`, `field_confidence` Json, `status` (`NEEDS_REVIEW`, `READY`, `SUBMITTED`, `APPROVED`, `REJECTED`, `RESUBMITTED`), `rejection_reason`, `reviewed_by_id`, `reviewed_at`, `applied_entity_type` (`USER_HONOR`/`ENROLLMENT`), `applied_entity_id` Int, `revision`, `active` | FKs a `honors`, `classes` y `users` (revisor) con `ON DELETE NO ACTION`. **No hay CHECK constraints** (migración `20260520170000_certificate_bulk_imports_init`). Nada impide hoy que una fila `CLASS` tenga `honor_id`: lo evita el servicio. |
| `certificate_bulk_import_item_events` | `event_id`, `batch_id`, `item_id`, `action` varchar(50), `performed_by_id`, `comment`, `payload` Json | Auditoría (`ITEM_ADDED`, `ITEM_UPDATED`, `ITEM_REMOVED`, `ITEM_RESUBMITTED`, `ITEM_APPROVED`, `OCR_PROCESSED`, …). |

### 1.2 Especialidades del usuario

- `honors`: `honor_id`, `name` varchar(100), `honors_category_id` → `honors_categories.honor_category_id`, `club_type_id`, `active`, `skill_level`. Su relación con tipos de club está además en `honor_club_types` (N:N), que es la que usa el filtro `clubTypeId` del catálogo.
- `honors_categories`: `honor_category_id`, `name` (único), `active`, traducciones en `honors_categories_translations`.
- `users_honors`: `user_honor_id`, `user_id`, `honor_id`, `validation_status` (`IN_PROGRESS`/`PENDING_REVIEW`/`APPROVED`/`REJECTED`), `validate` boolean, `validated_by_id`, `validated_at`, `certificate`, `images` Json, `date` date, `completion_mode`, `active`. Único `(user_id, honor_id)`.
- **No existe ningún campo de instructor.** Revisé el schema completo con `rg -i "instructor|teacher|taught"` y no hay columnas. Lo único parecido es `users_honors.validate`, que los DTOs de `src/honors/dto/honors.dto.ts` describen como "Honor validado por instructor". Es un boolean sin relación con ninguna persona. Fuera de este flujo (`POST /users/:userId/honors`, bulk y `PATCH`) tampoco se registra quién enseñó la especialidad.

### 1.3 Clases e investidura

- `classes`: `class_id`, `name` (único), `club_type_id` (NOT NULL → `club_types`), `active`, `asset_code` (por ejemplo `GM-01`, y `GM-02`/`GM-03` institucionales), `available_from_year_id` y `available_until_year_id`, `minimum_age`.
- `club_types`: `club_type_id`, `name` (único), `active`.
- `enrollments`: `user_id`, `class_id`, `ecclesiastical_year_id`, `investiture_status` (`… INVESTIDO`), `investiture_date` timestamptz, `record_kind` (`OPERATIONAL`/`HISTORICAL_CERTIFICATE`), `validated_by`, `validated_at`. El historial se guarda en `investiture_validation_history`.
- Las clases `GM-02` (Guía Mayor Avanzado) y `GM-03` (**Instructor**) no las acredita el Campo Local. Van a `institutional_certificate_requests` (`src/certificate-bulk-imports/institutional-class-codes.ts`).

### 1.4 Qué hace hoy el código

- **OCR** (`ocr/certificate-ocr.parser.ts`): busca las etiquetas `especialidad:`/`honor:` y `clase:`/`investidura:`, divide por `,`/`;` y toma una sola fecha global del texto. `runQueuedOcr` (`certificate-bulk-imports.service.ts`) crea las filas **siempre con `honor_id`/`class_id` nulos** y en `NEEDS_REVIEW`. No hay match contra el catálogo. Al reprocesar desactiva las filas `NEEDS_REVIEW` que no tienen `honor_id` ni `class_id`.
  - **Páginas**: el proxy de Cloud Run ya devuelve `pages[].text` por página (`cloud-run-certificate-ocr.provider.ts#successText`), pero el proveedor las **concatena con `\n`** en un solo `rawText` y el parser trabaja sobre ese texto plano. Hoy la página de origen se pierde antes de llegar al parser (ver §4.7).
  - **Estado del job**: `processOcr` encola con `jobId = certificate-ocr-{batchId}`, `attempts: 2`, `removeOnComplete: true` y `removeOnFail: { age: 3600, count: 20 }`. Los fallos terminales (`OCR_FAILED`, `OCR_QUOTA`, PDF inválido…) no llegan al lote: solo `OCR_QUEUED` y `OCR_PROCESSED` quedan como eventos (ver §4.6).
- **Edición por el miembro** (`PATCH /certificate-bulk-imports/:batchId/items/:itemId`, `POST …/items` y `POST …/items/:itemId/resubmit`; DTO `UpdateCertificateImportItemDto`): recibe `item_type`, `honor_id`, `class_id`, `detected_name`, `detected_date`, `completed_at`, `ocr_confidence`, `field_confidence`, `mark_as_ready` y `expected_revision`.
  - `assertCatalogChoice` revisa que `honors.active` sea verdadero, o que la clase exista y esté activa (las institucionales pasan aunque estén inactivas). Si falla, responde `CERTIFICATE_IMPORT_CATALOG_NOT_FOUND`.
  - `assertNotFuture` rechaza fechas futuras con `CERTIFICATE_IMPORT_DATE_IN_FUTURE`.
  - Para clases, `assertClassCertificateMayProceed` revisa la edad histórica y la autorización viva del mismo año.
  - Para que una fila quede `READY` hacen falta `mark_as_ready`, `completed_at` y el id de catálogo que corresponda al tipo.
- **Respuesta al miembro**: `batchInclude()` del servicio de miembro trae `items` **sin relaciones**. La app recibe solo ids, sin nombres de especialidad o clase.
- **Respuesta al admin** (`admin-certificate-bulk-imports.service.ts#batchInclude`): trae `honor {honor_id, name}`, `class {class_id, name, asset_code}` y `user {name, apellidos, email}`.
- **Aprobación** (`certificate-bulk-imports-application.service.ts`):
  - `HONOR`: hace upsert en `users_honors` por `(user_id, honor_id)` con `validation_status=APPROVED`, `date=completed_at`, `certificate` igual al primer archivo y `images` con todos. También crea `evidence_files`. Si ya existe una fila APROBADA con **otra** fecha, responde `CERTIFICATE_IMPORT_FINAL_DATE_CONFLICT`. Si la fecha es la misma, solo refresca la evidencia.
  - `CLASS`: resuelve el año eclesiástico a partir de `completed_at`. Rechaza las clases institucionales. Según el caso crea un `enrollments` `HISTORICAL_CERTIFICATE`/`INVESTIDO` con `investiture_date = completed_at`, reconcilia la inscripción operativa o sustituye la de `GM-01`. Después escribe en `investiture_validation_history`.
  - En los dos casos marca la fila como `APPROVED`, guarda `applied_entity_*` y registra el evento `ITEM_APPROVED` con `{applied_entity_type, applied_entity_id}`.
- **App** (`sacdia-app/lib/features/certificate_import`):
  - `CertificateImportItemModel` lee `honor_id`, `class_id`, `class.asset_code`, `detected_*`, `completed_at`, `status` y `rejection_reason`.
  - `certificate_import_item_editor_sheet.dart` tiene un único `SacTextField` `certificate_import.editor.catalog_id`, que se convierte en `honorId` o `classId` según el tipo.
  - `CertificateImportItemUpdatePayload` siempre manda `item_type` y nunca manda `expected_revision`.
- **Admin** (`sacdia-admin/src/components/certificate-bulk-imports/certificate-bulk-import-detail-page.tsx`): muestra el tipo, el estado, la confianza OCR, `detected_name`, "Catálogo: {honor.name|class.name}" y la fecha del certificado. Solo aprueba o rechaza; no edita filas.

### 1.5 Inconsistencias encontradas (docs ↔ código)

1. `docs/api/ENDPOINTS-LIVE-REFERENCE.md` marca `GET /honors`, `/honors/categories`, `/honors/grouped-by-category`, `/classes` y `/catalogs/club-types` como `JWT`. En el código los cinco son `@Public()` + `OptionalJwtAuthGuard`, es decir, no exigen token.
2. `docs/features/carga-masiva-certificados.md` (línea 87) dice que las filas muestran el "match de catalogo". El OCR nunca vincula catálogo: `honor_id` y `class_id` siempre nacen nulos.
3. El servicio de miembro no incluye la relación `class` en `getBatch`, pero la app lee `class.asset_code` (o `class_asset_code`). En el lado del miembro, `classAssetCode` siempre llega `null`.
4. `toItemUpdateData` solo persiste `honor_id`/`class_id` cuando el body trae `item_type`, y si lo trae pero sin el id, lo **borra** (`?? null`). En cambio, `mergeItem` valida con `dto.honor_id ?? existing.honor_id`. Un `PATCH` sin `item_type` puede dejar `READY` una fila sin persistir el id. La app hoy siempre manda `item_type` y el id, así que no lo dispara, pero la semántica es frágil y conviene corregirla junto con los campos nuevos.
5. `GET /classes` filtra por la disponibilidad **del año actual** (`buildAvailabilityWhere`). Una clase retirada (`available_until_year_id` pasado) no aparece, pero `assertCatalogChoice` sí la acepta. Con ese endpoint, la app no puede elegir clases de certificados históricos.
6. La app no manda `expected_revision`, así que el bloqueo optimista del backend (migración `20260921180000`) no se usa desde el móvil.
7. "Instructor" ya significa algo en el dominio: es la clase institucional `GM-03`, y el parser OCR marca `^instructor$` como institucional. El "instructor de una especialidad" es otro concepto. Hay que nombrarlo con cuidado en la UI, las docs y los errores (ver §2.6).
8. Fuera de alcance, pero visto: el aviso de GM-01 del admin usa colores fijos (`bg-blue-50 text-blue-700`), contra la regla de tokens semánticos del design system.
9. `page_count` no se persiste: `assertCertificateImportPdf` cuenta las páginas al confirmar el archivo (y falla si hay más de 5), pero devuelve el número y nadie lo guarda. `certificate_bulk_import_files` no tiene ninguna columna de páginas.
10. Los DTO de fecha de la carga por certificado solo validan formato (`@IsDateString({ strict: true })`). El rechazo de fechas futuras vive en el servicio (`assertNotFuture`, que compara contra la fecha UTC de hoy), y **no existe ninguna cota inferior**. Un OCR que lea "1925" por "2025" pasa sin aviso.

### 1.6 Flujo normal de especialidades (`/users/:userId/honors`)

Investigado en `origin/development` (backend `722be4b`, app `07a7088b`). Es el segundo flujo que alimenta `users_honors` y el conteo de "especialidades enseñadas" (D9).

**Backend** (`src/honors/honors.controller.ts`, controlador `UserHonorsController`, `@Controller('users/:userId/honors')`, `JwtAuthGuard` + `PermissionsGuard`, recurso `user` con `ownerParam: 'userId'`):

| Endpoint | Permiso | DTO | Servicio | Qué hace |
|---|---|---|---|---|
| `GET /users/:userId/honors` | `user_honors:read` | query `validated` | `getUserHonors` | Lista (máx. 500, `active = true`). Incluye `honors {honor_id, name, honor_image, club_type_id, skill_level, club_types, honors_categories}`. Devuelve **filas Prisma crudas** (snake_case) pasadas por `mapUserHonorPrivateUrls`. |
| `POST /users/:userId/honors/:honorId` | `user_honors:create` | `StartHonorDto { date? }` | `startHonor` | **Es lo que usa la app** al inscribirse. Crea o reactiva la fila en `IN_PROGRESS`, con `date = dto.date ?? hoy`. 409 si ya está activa. |
| `PATCH /users/:userId/honors/:honorId` | `user_honors:submit` | `UpdateUserHonorDto { validate?, certificate?, images?, document?, date?, completionMode? }` | `updateUserHonor` | Actualiza evidencia, fecha y modo de trabajo. Pasa por `assertHonorIsMutable`: **bloquea `PENDING_REVIEW` y `APPROVED`**. |
| `POST /users/:userId/honors` | `user_honors:create` | `CreateUserHonorDto { honorId, date?, validate?, certificate?, images?, document? }` | `createUserHonor` | Registra o reactiva con datos iniciales. **La app no lo usa** (ver abajo). |
| `POST /users/:userId/honors/bulk` | `user_honors:create` | `BulkCreateUserHonorsDto { honors: CreateUserHonorDto[] }` | `createUserHonorsBulk` | Igual, en lote. Tampoco lo usa la app. |
| `POST /users/:userId/honors/:honorId/files` | `user_honors:create` | multipart | `uploadUserHonorFiles` | Sube certificado, documento e imágenes. |
| `DELETE /users/:userId/honors/:honorId` | `user_honors:delete` | — | `abandonHonor` | Desactiva. |
| `POST /validation/submit` | `validation:submit` | `{ entityType: 'honor', entityId: user_honor_id }` | `HonorValidationWorkflowService.submitForReview` | Pasa a `PENDING_REVIEW`. Exige modo de trabajo decidido y requisitos o evidencia completos. |
| `POST /evidence-review/:type/:id/approve` | revisor | — | `HonorValidationWorkflowService.approve` | Pasa a `APPROVED` con `validate = true`, `validated_by_id` y `validated_at`. **No toca la fecha ni, hoy, nada del instructor.** |

Detalles que condicionan el diseño:

1. **`users_honors.date` es la fecha de inicio, no de finalización.** `startHonor` la fija en "hoy". La app muestra como fecha de finalización `validatedAt ?? date` (`honor_completion_view.dart`). La app **no manda `date`** en ningún punto del flujo normal y no tiene ningún selector de fecha en `lib/features/honors/presentation`.
2. **Las vías `POST /users/:userId/honors` y `/bulk` no aplican `assertHonorIsMutable`** cuando la fila ya existe: `createUserHonor` y `createUserHonorsBulk` entran por `buildUpdateDataFromCreateDto` sin revisar el estado. Un cliente puede reescribir `date`, `validate`, `certificate` e `images` de una fila `APPROVED` o `PENDING_REVIEW`. Es una debilidad previa, ajena al instructor, que **se cierra antes, en SEC-1** (D13, §7.3), para que el instructor no la herede.
2b. **Abandonar y reiniciar también saltan la protección.** `abandonHonor` desactiva la fila sin mirar `validation_status` (una `APPROVED` o `PENDING_REVIEW` queda inactiva). Después, `startHonor` sobre esa fila inactiva la **reactiva y la reinicia a `IN_PROGRESS`**, con `validate = false`, evidencias vacías y `validated_by_id`/`validated_at` en `NULL`. Es decir, un miembro puede borrar una aprobación y, con ella, el instructor. Se cierra en **SEC-2** (D13).
3. Todos los DTO de este flujo usan **camelCase** (`honorId`, `completionMode`), a diferencia de la carga por certificado (snake_case). Los campos nuevos de instructor siguen la convención de cada controlador.
4. Todos los campos de fecha solo validan `@IsDateString()`: sin cota inferior ni rechazo de futuro.
5. La aprobación del flujo normal la hace el módulo de revisión de evidencias (`src/evidence-review`, detalle en `getDetail` línea ~667) y el panel del admin (`sacdia-admin/src/components/evidence-review/evidence-detail-dialog.tsx`). Hoy ese detalle no muestra nada de instructor.
6. El conteo no distingue el origen: `users_honors` es único por `(user_id, honor_id)`, así que una especialidad aprobada por un flujo o por el otro cuenta una sola vez.

**App** (`sacdia-app/lib/features/honors`):

- "Mis especialidades" es `presentation/views/my_honors_view.dart`. Tocar una tarjeta abre `HonorEvidenceView` (`honor_evidence_view.dart`), que es el **único punto de envío a revisión** (`_submitForReview`, que llama a `POST /validation/submit`).
- La inscripción sale de `honor_detail_view.dart` (`_EnrollCtaButton` → `HonorEnrollmentNotifier.enrollInHonor` → `enrollUserInHonor` → `POST /users/:userId/honors/:honorId` sin cuerpo).
- La elección del modo de trabajo usa `PATCH …/:honorId` con `{ completionMode }` (`updateHonorCompletionMode`).
- `RegisterUserHonorParams` + `registerUserHonor` + `honorRegistrationNotifierProvider` existen (mandan `POST /users/:userId/honors` con `validate: false`), pero **ninguna vista los consume**: es código sin uso.
- No hay ninguna mención a "instructor" en `lib/features/honors`.

---

## 2. Modelo de datos del instructor

### 2.1 Decisión

Cada especialidad lleva **un** instructor opcional (D1), que puede ser:

- **usuario del sistema del mismo Campo Local** que el dueño de la especialidad: `instructor_user_id` (uuid, FK a `users.user_id`); o
- **persona externa**: `instructor_name` (texto libre). Incluye a quien no tiene cuenta y a quien es de **otro Campo Local** (D2); o
- **sin instructor**: ambos nulos.

Son mutuamente excluyentes. Cuando hay `instructor_user_id`, **no se guarda una copia del nombre**: el nombre se lee en vivo desde `users`. Hay dos motivos:

- Privacidad: `account-deletion.service.ts` hace soft-delete y anonimiza `users.name` y los apellidos. Una copia del nombre en otra tabla quedaría con datos personales después del borrado de la cuenta.
- Sin desincronización: si la persona corrige su nombre, el registro lo refleja.

El dato vive en dos lugares:

| Tabla | Por qué |
|---|---|
| `certificate_bulk_import_items` | Borrador editable por el miembro y evidencia de lo que se declaró y revisó. |
| `users_honors` | Registro de dominio que sobrevive a la aprobación y permite contar "especialidades enseñadas por X". Lo escriben **los dos flujos** (D9): la aprobación de la carga por certificado (§5) y el flujo normal de especialidades (`POST/PATCH /users/:userId/honors`, §4.8). Una vez aprobada la especialidad, solo cambia por la aprobación de una propuesta (D11, §4.9). |
| `honor_instructor_proposals` | Propuesta de instructor del miembro sobre una especialidad **ya aprobada**, pendiente de decisión del Campo Local (D11, §2.7). Conserva el historial de propuestas y los motivos de rechazo. |

### 2.2 Columnas nuevas

**`certificate_bulk_import_items`**

| Columna | Tipo | Null | Descripción |
|---|---|---|---|
| `instructor_user_id` | `uuid` | sí | FK a `users(user_id)`. Usuario que enseñó la especialidad. |
| `instructor_name` | `varchar(150)` | sí | Nombre completo libre si la persona no está en el sistema. Se normaliza (trim y espacios colapsados). |
| `detected_instructor_name` | `varchar(255)` | sí | *(Solo slice OCR, opcional.)* Texto crudo sugerido por el OCR. Nunca se vincula solo a un usuario. |
| `source_file_id` | `uuid` | sí | FK a `certificate_bulk_import_files(file_id)`, `ON DELETE SET NULL` (D12). Archivo del lote donde el parser OCR leyó la fila. Un lote acepta hasta 10 archivos (`CERTIFICATE_IMPORT_MAX_FILES`), por eso `source_page` solo tiene sentido junto con este dato. Las filas manuales y las anteriores a M2 quedan en `NULL`. Solo la escribe el parser; el miembro no la edita. |
| `source_page` | `smallint` | sí | Página (1 a 5) **dentro de `source_file_id`** donde el parser OCR leyó la fila (D4). Las filas manuales y las filas con archivo sin páginas conocidas quedan en `NULL`. Solo la escribe el parser; el miembro no la edita. Para imágenes es `1`. |

**`certificate_bulk_import_files`**

| Columna | Tipo | Null | Descripción |
|---|---|---|---|
| `page_count` | `smallint` | sí | Número de páginas del archivo (D4). Se escribe **al confirmar** el archivo, con el valor que ya calcula `assertCertificateImportPdf` (PDF) o `1` (imagen). Los archivos anteriores a la migración quedan en `NULL` y la API los devuelve como `null` (el cliente muestra "PDF" sin número). |

**`users_honors`**

| Columna | Tipo | Null | Descripción |
|---|---|---|---|
| `instructor_user_id` | `uuid` | sí | FK a `users(user_id)`. |
| `instructor_name` | `varchar(150)` | sí | Nombre externo. |

No hace falta una columna de procedencia en `users_honors`: la fila de importación que la originó se encuentra con `certificate_bulk_import_items.applied_entity_type = 'USER_HONOR' AND applied_entity_id = user_honor_id`, que ya tiene el índice `idx_certificate_bulk_items_applied_entity`.

### 2.3 Restricciones

```sql
-- Ítems: exclusividad, solo HONOR, nombre no vacío
ALTER TABLE certificate_bulk_import_items
  ADD CONSTRAINT certificate_bulk_import_items_instructor_exclusive_ck
    CHECK (instructor_user_id IS NULL OR instructor_name IS NULL) NOT VALID,
  ADD CONSTRAINT certificate_bulk_import_items_instructor_honor_ck
    CHECK (item_type = 'HONOR' OR (instructor_user_id IS NULL AND instructor_name IS NULL)) NOT VALID,
  ADD CONSTRAINT certificate_bulk_import_items_instructor_name_ck
    CHECK (instructor_name IS NULL OR char_length(btrim(instructor_name)) BETWEEN 3 AND 150) NOT VALID;

-- users_honors: exclusividad y nombre no vacío
ALTER TABLE users_honors
  ADD CONSTRAINT users_honors_instructor_exclusive_ck
    CHECK (instructor_user_id IS NULL OR instructor_name IS NULL) NOT VALID,
  ADD CONSTRAINT users_honors_instructor_name_ck
    CHECK (instructor_name IS NULL OR char_length(btrim(instructor_name)) BETWEEN 3 AND 150) NOT VALID;
```

Los CHECK de páginas van en la migración de páginas (§2.5):

```sql
ALTER TABLE certificate_bulk_import_items
  ADD CONSTRAINT certificate_bulk_import_items_source_page_ck
    CHECK (source_page IS NULL OR source_page >= 1) NOT VALID;
ALTER TABLE certificate_bulk_import_files
  ADD CONSTRAINT certificate_bulk_import_files_page_count_ck
    CHECK (page_count IS NULL OR page_count >= 1) NOT VALID;
```

**No hay un CHECK entre `source_page` y `source_file_id`** (por ejemplo, "si hay página, hay archivo"): con `ON DELETE SET NULL`, borrar un archivo pondría `source_file_id` en `NULL` y haría fallar el CHECK, que bloquearía el borrado. La coherencia la resuelve el cliente al leer (§4.7): sin archivo de origen, la página se ignora.

El tope de 5 páginas **no** se repite en la base: vive en `CERTIFICATE_IMPORT_MAX_PDF_PAGES`, y un CHECK con otro `5` se desincronizaría si el límite cambia.

**Las fechas no llevan CHECK** (D6). La cota 1960-01-01 y el rechazo de futuro se validan en el DTO y el servicio (§3.1, §4.8). Un CHECK sobre `completed_at` o `users_honors.date` fallaría al validar filas históricas que ya existen fuera de rango (por ejemplo, un `1925` mal leído por el OCR) y bloquearía escrituras no relacionadas.

Reglas que no caben en un CHECK porque cruzan tablas. Las aplica un servicio compartido (`InstructorsService.assertEligible`, §4.4), que usan los dos flujos:

- `instructor_user_id` ≠ dueño de la especialidad: `batch.user_id` en la carga por certificado y `:userId` en el flujo normal. Nadie es su propio instructor. Código `HONOR_INSTRUCTOR_SELF`.
- El instructor del sistema tiene que estar `active = true` y `approval_status = 'approved'` **al momento de elegirlo**. Si después se desactiva, el dato histórico se conserva.
- El instructor tiene que ser **mayor de edad** y tener el **mismo `users.local_field_id`** que el dueño de la especialidad (D2). Así un cliente no puede asignar un UUID cualquiera de otro campo, de un menor o de una persona no aprobada. Si el dueño no tiene Campo Local, solo se admite nombre libre.

### 2.4 FKs, `ON DELETE` e índices

- FK `instructor_user_id → users(user_id)` con `ON DELETE NO ACTION ON UPDATE NO ACTION`, igual que todas las FKs a `users` del módulo. En SACDIA los usuarios nunca se borran físicamente: `account-deletion.service.ts` hace soft-delete y anonimiza. Con `NO ACTION`, un hard delete accidental falla en lugar de borrar en silencio la cuenta de enseñanza. Una cuenta borrada se muestra como "Usuario eliminado" porque el nombre ya está anonimizado.
  - Alternativa: `ON DELETE SET NULL`. No bloquea, pero pierde el conteo y la trazabilidad. Se descarta.
- FK `source_file_id → certificate_bulk_import_files(file_id)` con **`ON DELETE SET NULL`** `ON UPDATE NO ACTION` (D12). A diferencia de las FKs a `users`, aquí la referencia es una **pista de navegación**, no un dato de dominio:
  - `NO ACTION` bloquearía una limpieza de archivos sin confirmar o un borrado de archivo, por una fila que solo lo cita.
  - `CASCADE` destruiría la especialidad o la clase que el miembro declaró, solo por perder el archivo.
  - `SET NULL` conserva la fila y el cliente cae al respaldo "primer archivo, página 1" (§4.7). Hoy los archivos se desactivan con `active = false` y no se borran; el borrado físico llega solo en cascada desde el lote (`batch → files` es `CASCADE`), donde las filas también desaparecen.
- Índices (parciales, `CONCURRENTLY`):

```sql
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_certificate_bulk_items_instructor_user
  ON certificate_bulk_import_items (instructor_user_id)
  WHERE instructor_user_id IS NOT NULL;

-- M2: acelera el SET NULL del FK de source_file_id al borrar un archivo
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_certificate_bulk_items_source_file
  ON certificate_bulk_import_items (source_file_id)
  WHERE source_file_id IS NOT NULL;

-- Conteo "especialidades enseñadas" por instructor
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_honors_instructor_user_approved
  ON users_honors (instructor_user_id)
  WHERE instructor_user_id IS NOT NULL AND active = true AND validation_status = 'APPROVED';
```

Consulta de conteo que cubre el índice:

```sql
SELECT instructor_user_id, count(*) AS honors_taught
FROM users_honors
WHERE instructor_user_id = $1 AND active AND validation_status = 'APPROVED'
GROUP BY instructor_user_id;
```

### 2.5 Migración (aditiva, sin downtime)

Son **tres migraciones obligatorias e independientes** (M1, M2 y M4) y una opcional (M3), todas aditivas. Se aplican **a mano por `psql` en Neon** dev → staging → prod (la shadow DB está rota), como las migraciones anteriores y como `20260630090000`, que separa `CONCURRENTLY` fuera de transacción. Después se registran en `_prisma_migrations`. Ninguna otra parte de este plan toca la base: `ocr_state` (D3) se deriva del job y **no** necesita migración.

| Migración | Nombre sugerido | Contenido | La necesitan |
|---|---|---|---|
| **M1. Instructor** | `prisma/migrations/20261010120000_certificate_import_honor_instructor/` | `instructor_user_id` e `instructor_name` en `certificate_bulk_import_items` y en `users_honors`, FKs, CHECKs e índices parciales | B2 (carga por certificado); B5 (flujo normal) y B9 (propuestas aprobadas) la usan sin agregar migración |
| **M2. Páginas y archivo de origen** | `prisma/migrations/20261010130000_certificate_import_ocr_pages/` | `source_page` y `source_file_id` (con su FK `ON DELETE SET NULL` e índice parcial) en `certificate_bulk_import_items`, y `page_count` en `certificate_bulk_import_files`, con sus CHECKs (D4 y D12) | B4 (`page_count`, `source_page` y `source_file_id`) |
| **M4. Propuestas de instructor** | `prisma/migrations/20261012120000_honor_instructor_proposals/` | Tabla nueva `honor_instructor_proposals`, sus FKs, CHECKs e índices (§2.7) | B9 (backend). B10 (admin) la consume por la API |

M1, M2 y M4 no dependen entre sí **a nivel de esquema**: M4 solo crea una tabla nueva. B9 sí necesita M1 aplicada porque, al aprobar una propuesta, escribe `users_honors.instructor_user_id` e `instructor_name`. Si el slice OCR opcional (§6.2) se implementa, agrega otra migración aditiva con `detected_instructor_name` (M3).

Pasos de cada migración:

1. `ALTER TABLE … ADD COLUMN IF NOT EXISTS … NULL` (sin default): es solo metadatos y no reescribe la tabla.
2. `ADD CONSTRAINT … FOREIGN KEY … NOT VALID` y después `VALIDATE CONSTRAINT`. Con `NOT VALID` se evita bloquear escrituras mientras valida. Como todas las filas existentes son `NULL`, la validación es trivial.
3. CHECKs `NOT VALID` y `VALIDATE CONSTRAINT`, con el mismo criterio.
4. `CREATE INDEX CONCURRENTLY` en un archivo o paso aparte, fuera de transacción.
5. Prisma (`schema.prisma`):

```prisma
model certificate_bulk_import_items {
  // …
  instructor_user_id       String? @db.Uuid
  instructor_name          String? @db.VarChar(150)
  instructor               users?  @relation("certificate_import_item_instructor", fields: [instructor_user_id], references: [user_id], onDelete: NoAction, onUpdate: NoAction)
  // CHECKs *_instructor_* e índice parcial idx_certificate_bulk_items_instructor_user: migración 20261010120000 (M1).
  source_page              Int?    @db.SmallInt // migración 20261010130000 (M2)
  source_file_id           String? @db.Uuid     // migración 20261010130000 (M2)
  source_file              certificate_bulk_import_files? @relation("certificate_import_item_source_file", fields: [source_file_id], references: [file_id], onDelete: SetNull, onUpdate: NoAction)
}

model certificate_bulk_import_files {
  // …
  page_count Int? @db.SmallInt // migración 20261010130000 (M2)
  items_sourced certificate_bulk_import_items[] @relation("certificate_import_item_source_file")
}

model users_honors {
  // …
  instructor_user_id String? @db.Uuid
  instructor_name    String? @db.VarChar(150)
  instructor         users?  @relation("user_honor_instructor", fields: [instructor_user_id], references: [user_id], onDelete: NoAction, onUpdate: NoAction)
}

model users {
  // …
  certificate_import_items_instructed certificate_bulk_import_items[] @relation("certificate_import_item_instructor")
  honors_instructed                   users_honors[]                  @relation("user_honor_instructor")
}
```

Compatibilidad: las filas existentes quedan "sin instructor", sin `source_page`, sin `source_file_id` y sin `page_count`. Los clientes viejos no mandan los campos nuevos y siguen funcionando. Ver §4.1 para la semántica de `undefined` y `null`. Los clientes nuevos tienen que tolerar `page_count`, `source_page` y `source_file_id` en `null` (filas manuales, archivos y filas anteriores a M2).

Rollback: el despliegue es forward-only. Si hiciera falta revertir, se hace `DROP CONSTRAINT`/`DROP INDEX`/`DROP COLUMN`, solo antes de que haya datos reales o después de exportarlos.

### 2.6 Guía Mayor, instructores externos y nombres

- **Guía Mayor**: **no se exige** que el instructor del sistema sea Guía Mayor (D2). Hay especialistas reales que no lo son (médicos, bomberos, etc.) y certificados viejos firmados por personas fuera del sistema. El único filtro de elegibilidad es activo, aprobado, mayor de edad y del mismo Campo Local.
- **Externos**: `instructor_name` cubre a quien no tiene cuenta **y a quien pertenece a otro Campo Local** (D2): ese instructor se carga como nombre libre aunque sí tenga cuenta en SACDIA. El admin lo ve marcado como "externo, no verificado". Consecuencia: el conteo de "especialidades enseñadas" por usuario **no cuenta** lo que enseñó alguien a miembros de otro campo. Más adelante podría existir una herramienta de admin para vincular nombres externos con usuarios, o ampliar el alcance a la unión (D2 dice "de momento"). No entra en v1.
- **Nombres**: en la API, la UI y los códigos de error se habla de "instructor de la especialidad" (`HONOR_INSTRUCTOR_*`; solo `CERTIFICATE_IMPORT_HONOR_INSTRUCTOR_NOT_ALLOWED` conserva el prefijo del módulo), para no confundirlo con la clase `GM-03` "Instructor". En la base basta `instructor_*`. En `certificate_bulk_import_items` el CHECK lo limita a filas `HONOR`.

### 2.7 Propuesta de instructor sobre una especialidad aprobada (D11)

Una especialidad `APPROVED` está congelada (§4.8, SEC-1 y SEC-2). D11 abre **una sola excepción**: el miembro propone el instructor y el Campo Local lo aprueba o rechaza. Hace falta guardar la propuesta pendiente en algún lugar que **no sea** el instructor vigente de `users_honors`.

**Decisión: tabla de propuestas (`honor_instructor_proposals`), no columnas `pending_instructor_*` en `users_honors`.**

| Criterio | Columnas `pending_instructor_*` | Tabla de propuestas (elegida) |
|---|---|---|
| Rechazo con motivo y revisor | No caben sin agregar estado, motivo, revisor y fecha: terminan siendo una tabla disfrazada dentro de una fila de uso intenso | Columnas propias (`status`, `rejection_reason`, `reviewed_by_id`, `reviewed_at`) |
| Historial | Cada propuesta pisa a la anterior: solo queda `validation_logs` | Una fila por propuesta: el miembro ve el último rechazo con su motivo y el admin ve el historial |
| Fuga de datos | `getUserHonors` devuelve filas Prisma crudas (hasta 500): las columnas pendientes saldrían en todas las respuestas y habría que quitarlas a mano | La fila de `users_honors` no cambia de forma; la propuesta sale solo en el bloque `instructor_proposal` |
| Cola del revisor | Escaneo de `users_honors` con un filtro sobre columnas nuevas | Índice parcial sobre `status = 'PENDING'` |
| Una sola propuesta pendiente | CHECK de columnas, sin historial | Índice único parcial, sin carreras |
| Aislamiento respecto de `assertHonorIsMutable` | La propuesta escribe en la fila aprobada (el registro congelado) | `users_honors` no se toca hasta aprobar |
| Costo | 6 o más columnas y 2 CHECKs más en `users_honors` | Una tabla y una migración aditiva (M4) |

**Tabla `honor_instructor_proposals`** (migración M4):

| Columna | Tipo | Null | Descripción |
|---|---|---|---|
| `proposal_id` | `uuid` PK, `gen_random_uuid()` | no | |
| `user_honor_id` | `int` | no | FK a `users_honors(user_honor_id)`, `ON DELETE NO ACTION` (la especialidad no se borra físicamente) |
| `proposed_by_id` | `uuid` | no | FK a `users(user_id)`. En v1 siempre es el dueño de la especialidad; se guarda explícito para la auditoría |
| `instructor_user_id` | `uuid` | sí | FK a `users(user_id)`, `NO ACTION`. Misma regla que §2.1: el nombre no se copia, se lee en vivo |
| `instructor_name` | `varchar(150)` | sí | Nombre libre normalizado |
| `status` | enum `honor_instructor_proposal_status_enum` | no | `PENDING` (default), `APPROVED`, `REJECTED`, `CANCELLED` |
| `rejection_reason` | `text` | sí | Obligatorio al rechazar |
| `reviewed_by_id` | `uuid` | sí | FK a `users(user_id)`. Quien aprobó o rechazó |
| `reviewed_at` | `timestamptz` | sí | |
| `created_at`, `modified_at` | `timestamptz` | no | `now()` |

Restricciones (la tabla nace vacía, así que los CHECK se crean directamente, sin `NOT VALID`):

```sql
ALTER TABLE honor_instructor_proposals
  ADD CONSTRAINT honor_instructor_proposals_one_instructor_ck
    CHECK ((instructor_user_id IS NULL) <> (instructor_name IS NULL)),          -- exactamente uno de los dos
  ADD CONSTRAINT honor_instructor_proposals_name_ck
    CHECK (instructor_name IS NULL OR char_length(btrim(instructor_name)) BETWEEN 3 AND 150),
  ADD CONSTRAINT honor_instructor_proposals_review_ck
    CHECK ((status IN ('APPROVED','REJECTED')) = (reviewed_by_id IS NOT NULL AND reviewed_at IS NOT NULL)),
  ADD CONSTRAINT honor_instructor_proposals_reason_ck
    CHECK (status <> 'REJECTED' OR char_length(btrim(rejection_reason)) BETWEEN 3 AND 500);

-- Una sola propuesta pendiente por especialidad (reemplazar = cancelar la anterior en la misma transacción)
CREATE UNIQUE INDEX uq_honor_instructor_proposals_pending
  ON honor_instructor_proposals (user_honor_id) WHERE status = 'PENDING';
-- Cola del Campo Local
CREATE INDEX idx_honor_instructor_proposals_queue
  ON honor_instructor_proposals (created_at) WHERE status = 'PENDING';
-- Última propuesta por especialidad (getUserHonors)
CREATE INDEX idx_honor_instructor_proposals_honor
  ON honor_instructor_proposals (user_honor_id, created_at DESC);
```

- **Sin `local_field_id` en la fila.** El alcance del revisor se deriva del Campo Local **actual** del dueño de la especialidad (`users.local_field_id`), el mismo criterio con el que se elige al instructor (D2). Un snapshot dejaría la propuesta atada a un campo al que el miembro ya no pertenece.
- No se indexa `instructor_user_id` en esta tabla: se consulta por especialidad o por estado, nunca "todas las propuestas de X", y los usuarios no se borran físicamente.
- `users_honors` no cambia de forma por D11. Los índices parciales del conteo (§2.4) siguen siendo los mismos.

```prisma
enum honor_instructor_proposal_status_enum {
  PENDING
  APPROVED
  REJECTED
  CANCELLED
}

model honor_instructor_proposals {
  proposal_id        String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  user_honor_id      Int
  proposed_by_id     String   @db.Uuid
  instructor_user_id String?  @db.Uuid
  instructor_name    String?  @db.VarChar(150)
  status             honor_instructor_proposal_status_enum @default(PENDING)
  rejection_reason   String?
  reviewed_by_id     String?  @db.Uuid
  reviewed_at        DateTime? @db.Timestamptz(6)
  created_at         DateTime @default(now()) @db.Timestamptz(6)
  modified_at        DateTime @default(now()) @db.Timestamptz(6)

  user_honor   users_honors @relation(fields: [user_honor_id], references: [user_honor_id], onDelete: NoAction, onUpdate: NoAction)
  proposed_by  users        @relation("honor_instructor_proposal_proposer", fields: [proposed_by_id], references: [user_id], onDelete: NoAction, onUpdate: NoAction)
  instructor   users?       @relation("honor_instructor_proposal_instructor", fields: [instructor_user_id], references: [user_id], onDelete: NoAction, onUpdate: NoAction)
  reviewed_by  users?       @relation("honor_instructor_proposal_reviewer", fields: [reviewed_by_id], references: [user_id], onDelete: NoAction, onUpdate: NoAction)
  // CHECKs e índices parciales: migración 20261012120000_honor_instructor_proposals (M4).
}
```

Rollback: igual que M1 y M2, solo hacia adelante. Antes de que haya propuestas reales, `DROP TABLE` y `DROP TYPE`.

---

## 3. Campos de la clase: tipo de club y fecha de investidura

- **¿Ya existen?** Sí, de forma derivada:
  - Tipo de club = `classes.club_type_id` de la clase elegida. No hace falta una columna en el ítem.
  - Fecha de investidura = `certificate_bulk_import_items.completed_at`. Al aprobar se copia a `enrollments.investiture_date` (`accreditHistoricalClass`, `substituteGuideMajor`, `reconcileOperationalEnrollment`). Es la fecha que decide el año eclesiástico.
- **Cómo se elige en la app**: primero el tipo de club (`GET /catalogs/club-types`) y después la clase de ese tipo (endpoint de §4.3). Solo se persiste `class_id`. Al reabrir la fila, el tipo de club sale de `class.club_type_id` en la respuesta.
- **DTO**: se agrega `club_type_id?` **solo como verificación de coherencia, no se guarda**. Si llega junto con `class_id` y `classes.club_type_id` es distinto, responde 400 `CERTIFICATE_IMPORT_CLASS_CLUB_TYPE_MISMATCH`. Sirve para atrapar un selector desincronizado en el cliente.
  - Alternativa: guardar `club_type_id` en el ítem para conservar un borrador con tipo de club pero sin clase. Se descarta en v1 porque duplica un dato derivable y abre una incoherencia que habría que validar con un trigger.
- **Qué valida hoy el backend y se mantiene**:
  - La clase existe y está activa, o es institucional (`assertCatalogChoice`).
  - `completed_at` no es futura, y ahora tampoco es anterior al 1960-01-01 (§3.1).
  - La edad mínima histórica (`assertClassCertificateHistoricalAge`).
  - No hay una autorización viva en el mismo año (`rejectSameYearLiveAuthorization`).
  - El año eclesiástico existe y no es ambiguo.
  - Las clases `GM-02`/`GM-03` van por el circuito institucional.
- **UI**: para filas `CLASS`, la etiqueta de `completed_at` pasa a decir "Fecha de investidura". Para `HONOR` dice "Fecha en que completó la especialidad". El campo de la API es el mismo.

### 3.1 Rango válido de fechas (D6)

Regla única para la fecha completada de la especialidad y la de investidura de la clase: **`1960-01-01 <= fecha <= hoy`**.

- **Constante compartida**: `MIN_CERTIFICATE_DATE = '1960-01-01'` en un único lugar de `src/common` (por ejemplo `src/common/utils/honor-date-range.ts`). La usan la carga por certificado y el flujo normal de especialidades (§4.8). La app replica la constante en un solo archivo de `core` y los tests de cada lado la fijan.
- **Dónde se valida**:
  - **DTO** (`UpdateCertificateImportItemDto.completed_at`, y los DTO del flujo normal, §4.8): un decorador `@IsDateInRange()` que revisa formato estricto y cota inferior.
  - **Servicio**: `assertNotFuture` pasa a `assertDateInRange(completed_at)` con los dos extremos. Sigue comparando contra la fecha UTC de hoy, igual que hoy; el margen del lado seguro (UTC va por delante de América) evita rechazos falsos al cierre del día.
  - **App**: el selector de fecha limita `firstDate = 1960-01-01` y `lastDate = hoy`, y el formulario muestra el error de campo antes de guardar. La validación del cliente es ayuda de UX; la del backend es la que manda.
- **Códigos**: `CERTIFICATE_IMPORT_DATE_IN_FUTURE` (existente) y `CERTIFICATE_IMPORT_DATE_TOO_OLD` (nuevo, 400). Para el flujo normal, `HONOR_DATE_IN_FUTURE` y `HONOR_DATE_TOO_OLD` (§4.5).
- **OCR**: si el parser lee una fecha fuera de rango (por ejemplo `1925`), **no** la deja como `completed_at`. Guarda `detected_date` (el valor crudo) y deja `completed_at` en `NULL`, con `field_confidence.date = 0`. La fila nace `NEEDS_REVIEW` y la app muestra "Revisa la fecha". Así un error de lectura no pasa por una fecha "válida".
- **Datos existentes**: no se corrigen ni se bloquean. La regla se aplica a las escrituras nuevas. Una fila vieja fuera de rango que se edite por otro motivo sí tiene que corregir la fecha para quedar `READY`.
- **Alcance de `detected_date`**: no se valida (es el texto crudo del OCR).

---

## 4. API

### 4.1 DTO de ítem (miembro): `UpdateCertificateImportItemDto`

Lo usan `POST /certificate-bulk-imports/:batchId/items`, `PATCH …/items/:itemId`, `POST …/items/:itemId/resubmit` y `items[]` de `POST /certificate-bulk-imports`. Campos nuevos:

| Campo | Tipo | Validación | Semántica |
|---|---|---|---|
| `instructor_user_id` | `string \| null` | `@IsOptional()`, `@ValidateIf(v => v !== null) @IsUUID()` | `undefined` = no cambia, `null` = borra, uuid = asigna y **borra `instructor_name`** |
| `instructor_name` | `string \| null` | `@Transform(trim + colapsar espacios)`, `@ValidateIf(v => v !== null) @IsString() @MinLength(3) @MaxLength(150) @Matches(/^[^\p{Cc}]+$/u)` | `undefined` = no cambia, `null` = borra, texto = asigna y **borra `instructor_user_id`** |
| `club_type_id` | `number` | `@IsOptional() @IsInt() @Min(1)` | Solo verificación (§3). No se persiste. |
| `completed_at` (existente) | `string` | se mantiene `@ValidateIf(mark_as_ready) @IsDateString({ strict: true })` y se agrega `@IsDateInRange()` (§3.1) | `1960-01-01 <= valor <= hoy` (D6) |

`source_page` **no** forma parte del DTO del miembro: lo escribe solo el parser OCR (§4.7). Si un cliente lo manda, `whitelist` de `ValidationPipe` lo descarta.

Reglas del servicio:

- Si llegan los dos con valor: 400 `HONOR_INSTRUCTOR_AMBIGUOUS`.
- Si la fila es o pasa a ser `CLASS`: si se mandó un instructor, 400 `CERTIFICATE_IMPORT_HONOR_INSTRUCTOR_NOT_ALLOWED`. Al cambiar `item_type` a `CLASS`, el servidor limpia los dos campos.
- `instructor_user_id`: pasa por `InstructorsService.assertEligible(ownerUserId = batch.user_id, instructorUserId)` (§4.4): tiene que existir, estar activo y aprobado, ser mayor de edad, **del mismo Campo Local que el dueño del lote**, y no ser el dueño. Si no, 400 `HONOR_INSTRUCTOR_INVALID` (o `HONOR_INSTRUCTOR_SELF`), sin aclarar cuál de las condiciones falló, para no filtrar si el usuario existe fuera del alcance.
- **El instructor es opcional para quedar `READY`** (D1). `isReady` para `HONOR` **no** mira `instructor_*`. La app lo pide y lo destaca, pero no bloquea. No hay ninguna pregunta abierta pendiente sobre esto.
- `addItem` mantiene su política actual (BC-9): un instructor inválido no rompe el alta. La fila nace `NEEDS_REVIEW` con el código en `rejection_reason`. `updateItem` y `resubmitItem` responden 400.
- **Corrección incluida** (inconsistencia 4): `toItemUpdateData` tiene que tomar `honor_id`/`class_id`/`instructor_*` de `mergeItem`, que respeta "undefined = no cambia", y no depender de que llegue `item_type`.
- Eventos: `ITEM_UPDATED` y `ITEM_ADDED` agregan `payload.changed_fields` (por ejemplo `["honor_id","instructor_user_id"]`) **sin valores**, para no duplicar el nombre libre en la auditoría.
- OCR re-run: el criterio de filas descartables en `runQueuedOcr` pasa a ser `NEEDS_REVIEW` **y** `revision = 0`, o como mínimo agregar `instructor_user_id IS NULL AND instructor_name IS NULL`. Así un reproceso no borra lo que el miembro ya completó.

### 4.2 Respuestas

**Miembro** (`GET /certificate-bulk-imports/:batchId`, y las respuestas de alta, edición y reenvío de ítem): `items[].include`, más un mapper que aplana y no expone datos de más:

```jsonc
{
  "item_id": "…",
  "item_type": "HONOR",
  "detected_name": "Primeros auxilios",
  "completed_at": "2019-05-12",
  "honor_id": 12,
  "honor": { "honor_id": 12, "name": "Primeros Auxilios",
             "category": { "honor_category_id": 3, "name": "Salud" } },
  "class_id": null,
  "class": null,                       // en CLASS: { class_id, name, asset_code, club_type: { club_type_id, name } }
  "instructor": {                      // null si no hay instructor
    "kind": "USER",                    // "USER" | "EXTERNAL"
    "user_id": "…",                    // solo si USER
    "display_name": "Ana Pérez Gómez", // USER: armado desde users (si está anonimizado: "Usuario eliminado"); EXTERNAL: instructor_name
    "photo_url": "https://…signed…"    // solo USER; URL firmada de vida corta o null
  },
  "instructor_user_id": "…",           // se mantienen las columnas crudas por compatibilidad
  "instructor_name": null,
  "source_file_id": "…",               // D12: archivo de files[] donde el OCR leyó la fila; null si la fila es manual o anterior a M2
  "source_page": 2,                    // D4: página DENTRO de source_file_id; null si no se ubicó. Sin source_file_id, el cliente la ignora
  "field_confidence": { "name": 0.9, "date": 0.74 }  // D5: date < 0.8 => la app muestra "Revisa la fecha"
}
```

Nivel de lote y de archivo (mismas respuestas):

```jsonc
{
  "batch_id": "…",
  "status": "DRAFT",
  "ocr_state": "running",              // D3: "pending" | "running" | "done" | "empty" | "failed" | null (ver §4.6)
  "files": [
    { "file_id": "…", "file_name": "certificado.pdf", "file_type": "application/pdf",
      "size_bytes": 2412345, "page_count": 3 }   // D4: null si el archivo es anterior a M2
  ],
  "items": [ /* … */ ]
}
```

El umbral 0.8 (D5) lo aplica el **cliente** sobre `field_confidence.date`; el backend no agrega una bandera calculada, para que app y admin lean el mismo dato crudo y el umbral viva en un solo lugar de cada cliente. Si el umbral se vuelve configurable, se mueve al backend como `needs_date_review: boolean`.

Con esto se corrige también la inconsistencia 3: la app recibe `class.asset_code`. Los nombres de catálogo salen traducidos con `TranslationService`, igual que en `HonorsService`/`ClassesService`.

**Admin** (`GET /admin/certificate-bulk-imports/:batchId` y `/pending`): mismo bloque `instructor` (sin `photo_url`, para no generar URLs firmadas en listados). Se agrega `honor.category`, `class.club_type` y la bandera `instructor.kind`. También `ocr_state` (solo en el detalle), `files[].page_count`, `items[].source_file_id`, `items[].source_page` e `items[].instructor_conflict` (§5). Nunca se expone el email del instructor.

### 4.3 Catálogos que necesita la app

| Necesidad | Endpoint | Estado | Cambio |
|---|---|---|---|
| Tipos de club | `GET /catalogs/club-types` | Existe (público, cacheado; devuelve `club_type_id` y `name`) | Ninguno. La app ya tiene `clubTypesProvider`. |
| Categorías de especialidad | `GET /honors/categories` | Existe (público, cache Redis 1 h) | Ninguno. |
| Especialidades por categoría con búsqueda | `GET /honors?categoryId=&search=&page=&limit=` | Existe **sin** `search` | Agregar `search` (opcional, 2–60 caracteres, trim) a `HonorFiltersDto` y a `buildHonorCatalogWhere`: `OR [name ILIKE %q%, translations.some(name ILIKE %q%)]`, escapando `%`/`_`. Sin cache: el catálogo tiene pocos miles de filas y el índice btree `idx_honors_name` no sirve para `%q%`. Si se necesita, más adelante se agrega un GIN trigram sobre `honors.name`. **No** filtrar por `clubTypeId` por defecto: un miembro puede tener especialidades de Aventureros de cuando era chico. |
| Clases por tipo de club | **Nuevo** `GET /certificate-bulk-imports/catalog/classes?clubTypeId=` | `GET /classes` no sirve: filtra por la disponibilidad del año actual (inconsistencia 5) | Devuelve `class_id`, `name`, `asset_code`, `club_type_id` e `institutional: boolean`, con **la misma regla que `assertCatalogChoice`**: activas más institucionales, sin ventana de disponibilidad. JWT y `@SkipPermissions()`, como el controlador del miembro. Un solo lugar define qué se puede elegir en este flujo. Alternativa: un parámetro `includeUnavailable=true` en `GET /classes`. Se descarta porque mezcla la regla de este flujo con el catálogo operativo. |

La app usa `institutional: true` para mostrar que esas filas van al circuito del superadministrador (flujo ya existente).

### 4.4 Búsqueda de usuarios para elegir instructor

Ninguna búsqueda existente sirve:

- `GET /admin/users` es solo admin y expone el email.
- `GET /investiture-pastor-candidates` es para roles de Campo y Unión y también expone el email.

Su patrón sí se reutiliza: tokens, mínimo de caracteres, `escapeLikeWildcards`, `take` acotado y alcance territorial (`district-investiture-pastors.service.ts#searchCandidates`).

**Endpoint nuevo (compartido por los dos flujos)**: `GET /instructor-candidates?q=`

Ya **no** cuelga de un `batchId` (D9): el formulario normal de "Mis especialidades" no tiene lote. El endpoint vive en un módulo propio, `src/instructors/` (`InstructorCandidatesController` + `InstructorsService`), que importan `CertificateBulkImportsModule` y `HonorsModule`. La ruta anterior `GET /certificate-bulk-imports/:batchId/instructor-candidates` de la propuesta previa **se descarta** (nunca se implementó).

- **Auth/RBAC**: `JwtAuthGuard` y `@SkipPermissions()`. Cualquier miembro autenticado puede buscar, porque tanto el miembro que carga un certificado como el que envía una especialidad por el flujo normal necesitan el selector. El control de abuso ya no es "tener un lote editable"; pasa a ser el alcance, el límite de tasa y la respuesta mínima (ver "Privacidad" abajo).
- **Alcance (D2)**: usuarios con el **mismo `users.local_field_id` que el usuario autenticado**. No se amplía a la unión ("de momento"). Si quien llama no tiene Campo Local, la búsqueda devuelve `[]` y la app ofrece solo el nombre libre. El selector de instructores de otros campos locales **no existe**: esas personas se cargan como nombre libre.
- **Filtro de elegibilidad**: `active = true`, `approval_status = 'approved'`, `user_id ≠ caller`, **mayor de edad** (`birthday <= hoy − 18 años`; si `birthday` es nulo, la persona queda excluida) y cuenta no anonimizada. **No** se exige ser Guía Mayor ni tener ningún rol.
- **Búsqueda**: `q` con trim, mínimo 3 caracteres en total y 2 por token. Cada token tiene que matchear en `name`, `paternal_last_name` o `maternal_last_name` (`contains`, `insensitive`, escapado). **Nunca en `email`**: evita enumerar correos. Los índices GIN trigram de esas columnas ya existen (migración `20260630090000`). `q` vacío o corto devuelve `[]`: este endpoint **no** lista a todo el campo.
- **Respuesta mínima (D2: solo nombre y foto)**, máximo 10, ordenada por nombre y apellidos:

```json
{ "status": "success", "data": [
  { "user_id": "…", "display_name": "Ana Pérez Gómez", "photo_url": "https://…signed (TTL corto)…" }
] }
```

  Nunca devuelve email, teléfono, fecha de nacimiento, roles, club, tipo de club ni ids territoriales. (La propuesta anterior del diseño de la app mostraba "club y tipo de club" bajo cada resultado; con D2 **ya no se muestra**.) `photo_url` se firma con `StorageBucketAlias.USER_PROFILES`, igual que `users.service.ts#resolvePrivateAssetUrl`, con un TTL de unos 10 minutos. Si falla la firma, se devuelve `null` y la app muestra iniciales.
- **Rate limiting**: `@Throttle(namedThrottle({ ttl: 60_000, limit: 30 }))` por usuario (`UserAwareThrottlerGuard`). La app aplica un debounce de 300 ms.
- **Privacidad**:
  - El filtro por Campo Local reemplaza al "estar ligado a un lote propio" de la propuesta anterior. Es **más débil** como control de abuso: cualquier miembro autenticado puede consultar nombres y fotos de adultos activos de su propio Campo Local. Es el costo de compartir el selector. Se acepta en v1 porque (a) el dato ya es visible entre miembros del mismo campo, (b) la búsqueda exige nombre parcial de 3 letras, (c) hay tope de 10 resultados y 30 consultas por minuto.
  - No se registra cada consulta (sería ruido y además guardaría datos personales del texto buscado). El evento de auditoría ocurre cuando el miembro **asigna** el instructor (`ITEM_UPDATED.changed_fields` en la carga por certificado; ver §4.8 para el flujo normal).
  - Homónimos: v1 muestra solo nombre y foto, que es lo que pidió el usuario. Dentro de un solo Campo Local el riesgo es menor que en una unión. Si aparecen confusiones, el siguiente paso de menor exposición es agregar el **nombre del club** (dato institucional, no personal), no el correo ni la edad.
- **Validación al asignar**: `InstructorsService.assertEligible(ownerUserId, instructorUserId)` repite el mismo filtro (misma unidad de código que el buscador) contra el **dueño de la especialidad**, no contra quien llama. En la carga por certificado y en el flujo normal ambos coinciden (el miembro edita lo suyo), pero la validación del backend no asume que quien llama sea el dueño (los endpoints de `/users/:userId/honors` se declaran con `ownerParam: 'userId'` y `PermissionsGuard`, y el guard puede permitir a otros roles actuar sobre ese usuario; hay que verificarlo al implementar).
- **Cambio de Campo Local**: si el miembro se muda a otro campo después de asignar el instructor, el dato histórico se conserva. El alcance se evalúa **solo al elegir**.

### 4.5 Errores nuevos (`ErrorCode`)

Compartidos por los dos flujos (se declaran una vez, en el módulo de instructores):

- `HONOR_INSTRUCTOR_AMBIGUOUS` (400): llegaron `instructor_user_id` e `instructor_name` con valor.
- `HONOR_INSTRUCTOR_INVALID` (400): no existe, inactivo, no aprobado, menor de edad o de otro Campo Local.
- `HONOR_INSTRUCTOR_SELF` (400): el miembro se eligió a sí mismo.
- `HONOR_DATE_TOO_OLD` (400) y `HONOR_DATE_IN_FUTURE` (400): fecha fuera de rango en el flujo normal (D6).
- Propuesta de instructor sobre una especialidad aprobada (D11, §4.9):
  - `HONOR_INSTRUCTOR_REQUIRED` (400): la propuesta no trae ni `instructorUserId` ni `instructorName`. Con los dos, `HONOR_INSTRUCTOR_AMBIGUOUS`.
  - `HONOR_INSTRUCTOR_UNCHANGED` (400): la persona propuesta ya es el instructor vigente.
  - `HONOR_INSTRUCTOR_PROPOSAL_NOT_APPROVED` (400): la especialidad no está `APPROVED` y activa. Mientras está en curso o rechazada, el instructor se guarda con el `PATCH` (D10).
  - `HONOR_INSTRUCTOR_PROPOSAL_NOT_FOUND` (404): la propuesta no existe.
  - `HONOR_INSTRUCTOR_PROPOSAL_NOT_PENDING` (409): ya se aprobó, rechazó o canceló.
  - `HONOR_INSTRUCTOR_PROPOSAL_FORBIDDEN` (403): quien llama no es el dueño de la especialidad (endpoints del miembro) o su Campo Local no coincide con el del dueño (endpoints del admin).

Solo de la carga por certificado:

- `CERTIFICATE_IMPORT_HONOR_INSTRUCTOR_NOT_ALLOWED` (400): instructor en una fila `CLASS`.
- `CERTIFICATE_IMPORT_CLASS_CLUB_TYPE_MISMATCH` (400)
- `CERTIFICATE_IMPORT_DATE_TOO_OLD` (400); `CERTIFICATE_IMPORT_DATE_IN_FUTURE` ya existe.

### 4.6 Estado de lectura del OCR: `ocr_state` (D3)

Se agrega `ocr_state` a **toda respuesta que devuelva el lote**: `GET /certificate-bulk-imports/:batchId`, las respuestas de `POST …/confirm` y `POST …/process-ocr`, y el detalle del admin. **No hay tabla ni columna nueva.** Se deriva así:

| `ocr_state` | Cómo se deriva |
|---|---|
| `pending` | Existe un evento `OCR_QUEUED` para el lote, no hay `OCR_PROCESSED` posterior y el job (`certificate-ocr-{batchId}`) está en `waiting` o `delayed` (incluye el backoff entre el intento 1 y el 2). |
| `running` | El job está en `active`. |
| `done` | Existe un evento `OCR_PROCESSED` posterior al último `OCR_QUEUED` con `item_count > 0`. |
| `empty` | Existe un evento `OCR_PROCESSED` posterior al último `OCR_QUEUED` con `item_count = 0`. |
| `failed` | El job está en `failed` (los dos intentos agotados o `UnrecoverableError`), **o** hay un `OCR_QUEUED` sin `OCR_PROCESSED` y el job ya no existe (ver riesgo abajo). |
| `null` | Nunca se pidió OCR para el lote (por ejemplo, un lote creado a mano). El cliente no muestra estado de lectura. |

Detalles de implementación:

- **Fuente de verdad para `done`/`empty`: el evento `OCR_PROCESSED`, no el job.** `processOcr` encola con `removeOnComplete: true`, así que un job exitoso **desaparece** de Redis. Por eso `done` y `empty` salen de la tabla de eventos (que ya guarda `item_count`), y el job solo se consulta para `pending`, `running` y `failed`.
- **Fuente para `failed`**: `removeOnFail: { age: 3600, count: 20 }`. Un job fallido se conserva **una hora**. Pasada la hora, el job desaparece y lo único que queda es "`OCR_QUEUED` sin `OCR_PROCESSED`". Esa combinación se resuelve así: job inexistente + `OCR_QUEUED` con más de 5 minutos (constante) = `failed`; con menos de 5 minutos = `pending` (cubre la ventana entre `add()` y el registro del job).
- **Sin Redis** (`ocrQueue` ausente): `processOcr` ya responde 400 `CERTIFICATE_IMPORT_OCR_UNAVAILABLE` y no escribe `OCR_QUEUED`; el lote queda con `ocr_state = null`. El 400 sigue siendo el canal del error "la lectura no está disponible" **al encolar**; `failed` cubre el fallo posterior del worker.
- **Costo**: una consulta al evento más reciente (`ORDER BY created_at DESC LIMIT 1` por acción; verificar que `certificate_bulk_import_item_events` tenga índice por `batch_id`) y un `queue.getJob(id)`. El mapper recibe el estado ya resuelto para no consultar Redis en listados: **el listado `/pending` del admin no calcula `ocr_state`**.
- **Mapeo a la UX de la app** (ver el documento de diseño, §3 y §4.5): `pending`/`running` = "Leyendo…"; `done` = filas; `empty` = "No encontramos especialidades ni clases"; `failed` = "No pudimos leer tu comprobante". "Seguir sin esperar" y el *pull-to-refresh* de la Revisión se actualizan con el campo, sin heurística de tiempo.
- **Riesgo conocido: reintento bloqueado.** `jobId` es determinista (`certificate-ocr-{batchId}`). Un job `failed` retenido durante una hora **impide re-encolar** con el mismo id: `add()` devuelve el job existente sin error y `processOcr` igual registra un nuevo `OCR_QUEUED`. Si la app ofrece "Reintentar lectura", el backend tiene que **eliminar el job fallido antes de volver a encolar** (`job.remove()` cuando `getState() === 'failed'`). Esto entra en B3 (§7.3); sin él, `failed` es un estado sin salida durante una hora.
- Códigos de fallo del worker (`OCR_FAILED`, `OCR_QUOTA`, `OCR_UNAVAILABLE`) **no** se exponen como estados separados (D3 define cinco estados). Si la app necesita distinguir "no disponible" de "ilegible" en el texto de error, habría que agregar un `ocr_error_code` opcional; no está en este alcance.

### 4.7 Archivo y página del comprobante: `page_count`, `source_page` y `source_file_id` (D4 y D12)

**`files[].page_count`**

- Se escribe al **confirmar** el archivo (`CertificateImportFilesService.confirm`): para PDF, con el entero que ya devuelve `assertCertificateImportPdf` (el mismo que valida el tope de 5); para imagen, `1`.
- Se expone en `toPublicImportFile` junto con `size_bytes`. Para archivos anteriores a M2 es `null`.
- La app y el admin lo usan para mostrar "PDF · 3 páginas" y para dibujar los controles de página del visor antes de abrir el archivo.

**`items[].source_file_id` e `items[].source_page` (D4 y D12)**

- Un lote acepta hasta **10 archivos** (`CERTIFICATE_IMPORT_MAX_FILES`) y cada PDF hasta 5 páginas. La página de una fila solo tiene sentido **dentro de su archivo**, por eso el parser escribe las dos columnas juntas: `source_file_id` (el archivo) y `source_page` (la página en ese archivo). Las dos nacen en M2.
- **Cambio necesario aguas arriba**: hoy `runQueuedOcr` ya entrega `fileId` por archivo a `ocrProvider.extract`, pero el proveedor devuelve **un solo resultado** con todo el texto concatenado y descarta archivo y página (en Cloud Run recibe `pages[].text` y lo une con `\n`). Hay que cambiar el contrato interno:
  - `CertificateOcrParseResult` pasa a transportar `files: { fileId: string; pages: { pageNumber: number; text: string }[] }[]`, además de `rawText` (que se conserva para `raw_ocr_payload`).
  - `CertificateOcrParser.parse` extrae candidatos **por archivo y por página** y asigna `sourceFileId` y `sourcePage` a cada `CertificateOcrCandidate`.
  - El proveedor de imágenes (`google-vision`) devuelve una sola página por archivo (`sourcePage = 1`).
  - `runQueuedOcr` guarda `source_file_id` y `source_page` en `createMany`.
- **Fecha global**: hoy el parser toma **una** fecha global del texto completo. Al parsear por página, una fecha que aparece en la página 2 no se vería desde los candidatos de la página 1. Regla: la fecha de un candidato es la de su página; si su página no tiene fecha, se usa la primera fecha de su archivo; si el archivo no tiene ninguna, la **primera fecha del lote** (comportamiento actual). En los dos respaldos, `field_confidence.date` se reduce. Test obligatorio.
- **Mismo candidato en varias páginas o archivos**: se conserva el del primer archivo (por orden de subida) y, dentro de él, el de la primera página.
- **Si el parser no puede ubicar la fila** (por ejemplo, no puede decidir entre dos páginas): `source_page = NULL`. Si no puede ubicar ni el archivo, `source_file_id = NULL` también.
- **Flujo normal de especialidades**: ninguno de los dos aplica; no hay OCR.
- **Reglas de resolución en el cliente (app y admin)**: las dos usan la misma, y cada una la fija con un test:
  1. **Archivo.** Si `source_file_id` está y aparece en `files[]`, se abre ese archivo. Si es `null` o ya no aparece, se abre el **primer archivo** de `files[]` (el de subida).
  2. **Página.** `source_page` solo se respeta cuando el archivo salió de `source_file_id` y `1 <= source_page <= page_count` de **ese** archivo (si `page_count` es `null`, basta `source_page >= 1`). En cualquier otro caso, incluido el archivo de respaldo, se abre la **página 1**. Un dato inconsistente nunca debe romper el visor.
- **Visores**: el de la app (`SacPdfViewer`/`CertificateProofViewer`, con `fileId` e `initialPage`) y el del admin (`PdfInlineViewer`, con `initialPage` y el archivo elegido). Con más de un archivo, ambos ofrecen cambiar de archivo.

### 4.8 Flujo normal de especialidades: instructor y fechas (D6, D9, D10)

Cambios en `src/honors/**` para que "Mis especialidades" capture el instructor opcional y respete el rango de fechas.

**Cuándo y dónde se captura (D10).** La app pide el instructor (opcional) en `HonorEvidenceView`, antes de "Enviar a revisión", y lo guarda con `PATCH /users/:userId/honors/:honorId`. El backend solo lo acepta mientras la especialidad está en `IN_PROGRESS` o `REJECTED`; en `PENDING_REVIEW` y `APPROVED` el `PATCH` responde `VALIDATION_HONOR_INVALID_STATUS`. Para una especialidad ya aprobada el único camino es la propuesta de D11 (§4.9).

**DTOs** (`src/honors/dto/honors.dto.ts`). Esta capa usa **camelCase**, así que los campos nuevos son `instructorUserId` e `instructorName` (en la carga por certificado siguen siendo `instructor_user_id` e `instructor_name`):

| DTO | Endpoint | Cambio |
|---|---|---|
| `UpdateUserHonorDto` | `PATCH /users/:userId/honors/:honorId` | Agrega `instructorUserId?: string \| null` e `instructorName?: string \| null`, con **las mismas reglas de validación y semántica** que §4.1 (`undefined` = no cambia, `null` = borra, valor = asigna y borra el otro). `date` pasa a `@IsDateInRange()`. **Es el endpoint principal de la app** (D10): guarda el instructor antes de enviar a revisión, solo en `IN_PROGRESS` o `REJECTED`. |
| `CreateUserHonorDto` | `POST /users/:userId/honors` y cada elemento de `…/bulk` | Mismos campos. `date` con `@IsDateInRange()`. La app no lo usa hoy (§1.6), pero otros clientes sí podrían. |
| `StartHonorDto` | `POST /users/:userId/honors/:honorId` | **Sin instructor**: se inscribe antes de enseñar. `date` con `@IsDateInRange()`. |

**Validaciones en `HonorsService`**

1. `InstructorsService.assertEligible(userId, instructorUserId)` en `updateUserHonor`, `createUserHonor` y `createUserHonorsBulk` (mismo servicio que la carga por certificado; mismos errores `HONOR_INSTRUCTOR_*`).
2. **Mutabilidad (D10 y D13)**: `instructorUserId`/`instructorName` solo se aceptan si `validation_status` es `IN_PROGRESS` o `REJECTED`. `updateUserHonor` ya llama a `assertHonorIsMutable`. Las vías `createUserHonor` y `createUserHonorsBulk` **dejan de reescribir filas `APPROVED` o `PENDING_REVIEW` por completo** gracias a **SEC-1** (D13, §7.3), que llega antes que B5: ahí está el cierre del hueco entero (`date`, `validate`, `certificate`, `images` e instructor), no solo del instructor. B5 **no** agrega su propio guard condicionado a `instructor*`; solo agrega un test que confirma que el instructor tampoco entra por esas vías. `assertHonorIsMutable` y su lista de estados bloqueados **no cambian** con D11 (§4.9).
   - Si la fila está inactiva y se reinicia con `startHonor` desde `IN_PROGRESS` o `REJECTED` (el reinicio actual, que vacía evidencias), el reinicio también deja `instructor_user_id` e `instructor_name` en `NULL`. Para `APPROVED` y `PENDING_REVIEW` el reinicio ya no aplica (SEC-2).
3. **Fechas (D6)**: `date` entre 1960-01-01 y hoy, con `HONOR_DATE_TOO_OLD`/`HONOR_DATE_IN_FUTURE`. Aplica a las tres vías. Como `date` es en este flujo la fecha de **inicio** (`startHonor` la fija en "hoy"), la regla se aplica igual al campo `date` tal como llega; la app actual no manda `date`, así que no hay riesgo de regresión de ese cliente.
4. **Auditoría**: el flujo normal no tiene tabla de eventos por ítem. Se registra en `validation_logs` (`entity_type = 'honor'`) una acción `instructor_set` con `comment` sin el nombre libre (solo `kind`), cuando el instructor cambia. Aprobación y rechazo siguen igual.

**Respuestas**

- `getUserHonors`, `startHonor`, `createUserHonor`, `updateUserHonor`, `createUserHonorsBulk` y la lista del flujo normal devuelven filas Prisma crudas: las columnas `instructor_user_id` e `instructor_name` salen **solas** (snake_case, como el resto de la fila). Se agrega además el bloque `instructor` (`kind`, `user_id`, `display_name`, `photo_url`) con el mismo mapper de §4.2, dentro de `mapUserHonorPrivateUrls`. `getUserHonors` carga hasta 500 filas: **`photo_url` no se firma en listados** (solo `kind` y `display_name`); la foto se firma en las respuestas de una sola fila.
- Cada fila de `getUserHonors` agrega también el bloque `instructor_proposal` (D11, §4.9): la última propuesta `PENDING` o `REJECTED` de esa especialidad, o `null` si no hay. Sin foto firmada en listados.
- Revisión de evidencias: `EvidenceReviewService.getDetail` (`honor`) agrega `instructor` (sin foto firmada, sin email) y `instructor_conflict` no aplica aquí. El panel del admin (`evidence-detail-dialog.tsx`) lo muestra igual que la revisión de la carga por certificado ("Instructor: Ana Pérez (usuario)", "Juan López — externo, no verificado", "Sin instructor declarado").

**Aprobación y conteo**

- `HonorValidationWorkflowService.approve` **no modifica** el instructor. El conteo (§2.4) sale del mismo índice parcial sobre `users_honors`, así que un solo `SELECT` cubre ambos flujos.
- **Conflicto entre flujos (D7)**: ocurre solo en la aprobación de la carga por certificado sobre una fila ya `APPROVED` del flujo normal (misma fecha, otro instructor): se conserva el existente (§5). La inversa no existe: una fila `APPROVED` es inmutable en el flujo normal (punto 2); su instructor solo cambia por la aprobación de una propuesta (D11, §4.9).
- **Especialidades ya aprobadas antes de esta funcionalidad** quedan sin instructor, pero **ya se pueden completar** después: el miembro lo propone y el Campo Local lo aprueba (D11, §4.9). Hasta que lo hagan, el conteo las subestima.

**App** (resumen; el diseño de pantalla está en el documento hermano, §6.4 y §6.5): `UserHonor` y `UserHonorModel` agregan `instructor` e `instructorProposal`; `updateUserHonor` manda `instructorUserId`/`instructorName`; `HonorEvidenceView` muestra el selector antes de "Enviar a revisión" (D10) y, en una especialidad aprobada, la propuesta de §4.9. No se usa `POST /users/:userId/honors`.

**Tests**

- `honors.dto.spec.ts` (nuevo): `instructorUserId` null/uuid inválido; `instructorName` de 2 o 151 caracteres y con caracteres de control; los dos con valor; `date` de 1959-12-31, 1960-01-01 y mañana.
- `honors.service.spec.ts`:
  - `updateUserHonor` asigna usuario del mismo Campo Local y limpia el nombre libre (y al revés);
  - `INVALID` para usuario de otro campo, inactivo, no aprobado o menor;
  - `SELF`;
  - `PENDING_REVIEW` y `APPROVED` rechazan el cambio de instructor (`VALIDATION_HONOR_INVALID_STATUS`);
  - `createUserHonor` y `createUserHonorsBulk` con fila existente `APPROVED` o `PENDING_REVIEW` + `instructor*` rechazan (el cierre general lo prueba SEC-1; aquí se fija que el instructor tampoco entra por esa vía);
  - el reinicio de una fila inactiva `IN_PROGRESS` o `REJECTED` deja `instructor_*` en `NULL`;
  - `startHonor` rechaza `date` fuera de rango y no acepta instructor;
  - la respuesta de `getUserHonors` trae `instructor` sin email ni `photo_url`.
- `evidence-review.service.spec.ts`: el detalle `honor` incluye `instructor` y no incluye email.
- Prueba de integración del conteo: una especialidad por cada flujo, mismo instructor, `count = 2`; la misma especialidad por los dos flujos cuenta 1.

### 4.9 Instructor en una especialidad ya aprobada: propuesta y decisión del Campo Local (D11)

Una especialidad `APPROVED` está congelada. D11 permite **una excepción acotada**: el miembro propone el instructor y el Campo Local decide. Nada más de la especialidad cambia. La propuesta vive en `honor_instructor_proposals` (§2.7, migración M4) y **no** pasa por el `PATCH` ni por el alta, que siguen bloqueados para `APPROVED` (SEC-1, D13).

**Qué camino usa cada estado** (las dos vías son excluyentes por estado):

| `validation_status` de la especialidad | Cómo se cambia el instructor | Lo otro responde |
|---|---|---|
| `IN_PROGRESS`, `REJECTED` | `PATCH /users/:userId/honors/:honorId` (D10, §4.8) | La propuesta: 400 `HONOR_INSTRUCTOR_PROPOSAL_NOT_APPROVED` |
| `PENDING_REVIEW` | Ninguno: queda congelada hasta que el Campo Local decida la especialidad | `PATCH` y propuesta: 400 |
| `APPROVED` (y `active = true`) | Propuesta (esta sección) | `PATCH`: 400 `VALIDATION_HONOR_INVALID_STATUS` |

#### Endpoints del miembro

Van en `UserHonorsController`, con los guards actuales (`JwtAuthGuard` + `PermissionsGuard`, recurso `user`, `ownerParam: 'userId'`). Permiso: **`user_honors:submit`**, el mismo que el `PATCH` de la especialidad, porque es la misma declaración del miembro sobre su propia fila. Sin permiso nuevo.

| Endpoint | Cuerpo | Respuesta | Qué hace |
|---|---|---|---|
| `POST /users/:userId/honors/:honorId/instructor-proposal` | `{ instructorUserId?: string, instructorName?: string }`, **exactamente uno** | 201, la propuesta (`proposal_id`, `status`, `instructor`) | Crea la propuesta `PENDING`. Si ya había una pendiente, la **reemplaza**: la anterior pasa a `CANCELLED` en la misma transacción |
| `DELETE /users/:userId/honors/:honorId/instructor-proposal` | — | 200, la propuesta cancelada | Cancela la propuesta `PENDING` (`CANCELLED`) |

**Lectura**: no hay endpoint nuevo. Cada fila de `GET /users/:userId/honors` trae el bloque `instructor_proposal` (§4.8, "Respuestas"):

```jsonc
"instructor_proposal": {           // null si no hay propuesta PENDING ni REJECTED
  "proposal_id": "…",
  "status": "PENDING",             // "PENDING" | "REJECTED"
  "instructor": { "kind": "USER", "user_id": "…", "display_name": "Ana Pérez Gómez", "photo_url": null },
  "rejection_reason": null,        // texto del revisor si REJECTED
  "created_at": "2026-10-12T15:04:00Z"
}
```

Las propuestas `APPROVED` no salen aquí: ya son el `instructor` vigente de la fila. Las `CANCELLED` tampoco. Una `REJECTED` se muestra hasta que el miembro haga una propuesta nueva.

Reglas del `POST` (en este orden):

1. **Solo el dueño**: `req.user.sub` tiene que ser `:userId`, aunque el `PermissionsGuard` deje pasar a otros roles sobre ese usuario. Si no, 403 `HONOR_INSTRUCTOR_PROPOSAL_FORBIDDEN`. Es una declaración personal; el Campo Local no propone en nombre del miembro.
2. **Precondición**: la fila existe (`HONOR_USER_HONOR_NOT_FOUND` si no), `active = true` y `validation_status = 'APPROVED'`; si no, 400 `HONOR_INSTRUCTOR_PROPOSAL_NOT_APPROVED`.
3. **Forma**: exactamente uno de los dos campos (`HONOR_INSTRUCTOR_REQUIRED` o `HONOR_INSTRUCTOR_AMBIGUOUS`); el nombre se normaliza como en §4.1.
4. **Elegibilidad**: `InstructorsService.assertEligible(userId, instructorUserId)`, el mismo servicio de §4.4 (`HONOR_INSTRUCTOR_INVALID`, `HONOR_INSTRUCTOR_SELF`).
5. **Sin cambio real**: si la persona propuesta ya es el instructor vigente (mismo `instructor_user_id`, o mismo nombre libre sin distinguir mayúsculas), 400 `HONOR_INSTRUCTOR_UNCHANGED`.
6. **Escritura** en una `$transaction`: `UPDATE … SET status = 'CANCELLED'` sobre la pendiente, si existe, y `INSERT` de la nueva. El índice único parcial (§2.7) hace la operación segura ante dos solicitudes simultáneas: la que pierde recibe 409 `HONOR_INSTRUCTOR_PROPOSAL_NOT_PENDING` y la app invalida y vuelve a leer.
7. **Tasa**: `@Throttle(namedThrottle({ ttl: 60_000, limit: 10 }))` por usuario.

El `DELETE` exige también ser el dueño, y responde 404 `HONOR_INSTRUCTOR_PROPOSAL_NOT_FOUND` si no hay una pendiente.

#### Endpoints del admin (Campo Local)

Controlador nuevo `AdminHonorInstructorProposalsController`, `@Controller('admin/honor-instructor-proposals')`:

| Endpoint | Cuerpo | Qué hace |
|---|---|---|
| `GET /admin/honor-instructor-proposals?status=PENDING&page=&limit=` | — | Cola, más antigua primero. `status` admite `PENDING` (por defecto), `APPROVED` y `REJECTED` para ver el historial. Cada elemento: `proposal_id`, `status`, `created_at`, `honor {honor_id, name}`, `member {user_id, display_name}`, `current_instructor` y `proposed_instructor` (ambos con el bloque de §4.2, sin foto firmada ni correo), `rejection_reason`, `reviewed_at` |
| `POST /admin/honor-instructor-proposals/:proposalId/approve` | — | Aprueba (ver abajo) |
| `POST /admin/honor-instructor-proposals/:proposalId/reject` | `{ reason: string }`, de 3 a 500 caracteres | Rechaza con motivo; no toca `users_honors` |

**RBAC**: es el mismo revisor de la carga por certificado, el **Campo Local**, con el mismo patrón que `admin/certificate-bulk-imports`: `@UseGuards(JwtAuthGuard, GlobalRolesGuard)`, `@GlobalRoles('super-admin', 'admin', 'assistant-admin', 'director-lf', 'assistant-lf')` y `@SkipPermissions()`.
- **Alcance**: `super-admin`, y `admin`/`assistant-admin` sin Campo Local, ven todo. Quien tiene Campo Local (incluidos `director-lf` y `assistant-lf`) ve y decide **solo** las propuestas cuyo dueño tiene el mismo `users.local_field_id`; fuera de ese alcance, 403 `HONOR_INSTRUCTOR_PROPOSAL_FORBIDDEN`. El criterio es el del dueño **actual**, el mismo que se usa para elegir al instructor (D2).
- **Sin duplicar la lógica**: `resolveReviewerAccess` y `assertCanAccessBatch` de `AdminCertificateBulkImportsService` se extraen a un helper común (`src/common/reviewer-scope/`) que usan los dos servicios. Es un cambio mecánico y sus pruebas actuales deben seguir verdes sin tocarse.
- **Por qué no `evidence-review`**: ese módulo exige `validation:review`, se limita por sección de club (coordinadores) y su `approve`/`reject` ejecuta el flujo de una especialidad en `PENDING_REVIEW`. Una propuesta no es una especialidad en revisión y su revisor es el Campo Local.
- Docs: `features/rbac.md` y `RBAC-ENFORCEMENT-MATRIX.md` (filas nuevas), `ENDPOINTS-LIVE-REFERENCE.md`.

**Aprobar** (`approve`), todo en una sola `$transaction`:
1. Cargar la propuesta con su especialidad y el dueño; comprobar el alcance del revisor (403).
2. `updateMany` sobre `proposal_id` con `status = 'PENDING'` a `APPROVED` (`reviewed_by_id`, `reviewed_at`). Si afecta 0 filas: 404 `HONOR_INSTRUCTOR_PROPOSAL_NOT_FOUND` o 409 `HONOR_INSTRUCTOR_PROPOSAL_NOT_PENDING`.
3. Comprobar que la especialidad sigue `active` y `APPROVED` (si no, 400 `HONOR_INSTRUCTOR_PROPOSAL_NOT_APPROVED` y se revierte todo).
4. Si la propuesta trae `instructor_user_id`, repetir `assertEligible(dueño, instructor)`. Si ya no es elegible (se desactivó, cambió de campo), 400 `HONOR_INSTRUCTOR_INVALID` y la propuesta sigue `PENDING`; el revisor la rechaza con un motivo. **A diferencia de la aprobación de la carga por certificado (§5, punto 5)**, aquí sí se revalida: pasa tiempo entre proponer y decidir, y el dato entra en un registro que ya estaba cerrado.
5. Escribir el instructor con **`applyApprovedInstructor`** (abajo).
6. Registrar `validation_logs`.

**Rechazar** (`reject`): `updateMany` de `PENDING` a `REJECTED` con `rejection_reason`, `reviewed_by_id` y `reviewed_at`, y registro en `validation_logs`. `users_honors` no se toca. El miembro ve el motivo y puede proponer a otra persona.

#### Cómo convive con `assertHonorIsMutable`

1. **`assertHonorIsMutable` y `HONOR_MUTATION_BLOCKED_STATUSES` no cambian.** No se agrega ningún parámetro, bandera ni excepción por estado. `updateUserHonor`, `createUserHonor` (SEC-1) y `createUserHonorsBulk` (SEC-1) siguen rechazando `APPROVED` y `PENDING_REVIEW`.
2. **No se reutiliza ninguna de esas vías.** La propuesta entra por un endpoint propio, con una precondición **inversa** (exige `APPROVED`). Por eso nunca compiten con el `PATCH`: cada estado tiene un solo camino (tabla de arriba).
3. **La única escritura sobre una especialidad aprobada** es `applyApprovedInstructor(tx, userHonorId, proposal)`, un método privado de `HonorInstructorProposalsService` que solo ejecuta `users_honors.update` con `instructor_user_id`, `instructor_name` (el otro en `NULL`) y `modified_at`. **No toca** `validation_status`, `validated_by_id`, `validated_at`, `date`, `validate`, `certificate`, `images`, `document` ni `active`. Un test compara la fila antes y después de aprobar y exige que solo cambien esas columnas.
4. **`validated_by_id` y `validated_at` siguen diciendo quién aprobó la especialidad.** Quién aprobó el instructor queda en `honor_instructor_proposals.reviewed_by_id` y `reviewed_at`.
5. **SEC-1 y SEC-2 son lo que hace creíble el punto 3**: sin ellos, el alta reescribiría la fila aprobada y el abandono con reinicio la devolvería a `IN_PROGRESS`, así que "el resto queda congelado" no sería cierto. Por eso son prerrequisito de B9.

#### Auditoría

- Tabla `validation_logs` (`entity_type = 'honor'`, `entity_id = user_honor_id`, `user_id` = dueño, `performed_by` = quien actúa). La columna `action` es `varchar(20)`: las cuatro acciones nuevas miden 19 caracteres y caben.

| `action` | Quién | `comment` (JSON, **sin el nombre libre**) |
|---|---|---|
| `instructor_proposed` | Miembro | `{ proposal_id, kind: 'USER' \| 'EXTERNAL', replaced_proposal_id? }` |
| `instructor_withdrawn` | Miembro | `{ proposal_id }` |
| `instructor_approved` | Revisor | `{ proposal_id, kind, previous_kind: 'USER' \| 'EXTERNAL' \| 'NONE' }` |
| `instructor_rejected` | Revisor | `{ proposal_id, reason }` |

- Estado, revisor, fecha y motivo viven además en la propia propuesta. El nombre libre queda solo en `honor_instructor_proposals` y, tras aprobar, en `users_honors`.
- `GET /evidence-review/honor/:id/history` ya lista `validation_logs` de la especialidad; las acciones nuevas aparecerán ahí. El mapper del historial tiene que tolerar acciones que no conoce.

#### Interacción con otros flujos

- **Aprobación de la carga por certificado (D7, §5)**: no cancela una propuesta pendiente. Si esa aprobación completa un instructor en una `APPROVED` sin instructor, y después se aprueba la propuesta, esta lo **reemplaza**. El evento y el log guardan `previous_kind`, y la cola muestra `current_instructor` para que el revisor lo vea al decidir.
- **Cuenta eliminada**: el instructor propuesto se muestra como "Usuario eliminado" con el mismo mapper de §4.2.
- **Notificaciones**: ninguna en v1. Ni el instructor (D8) ni el miembro reciben aviso de la decisión; el miembro la ve al abrir la especialidad. El revisor consulta la cola.
- **Conteo**: el índice parcial de §2.4 cuenta el instructor en cuanto la propuesta se aprueba.

#### Tests de B9

- `honor-instructor-proposals.dto.spec.ts`: ninguno de los dos campos, los dos, uuid inválido, nombre de 2 o 151 caracteres y con caracteres de control; `reason` de 2 y de 501 caracteres.
- `honor-instructor-proposals.service.spec.ts`:
  - propone con usuario del mismo Campo Local y con nombre libre; solo el dueño (otro usuario, 403);
  - `IN_PROGRESS`, `REJECTED`, `PENDING_REVIEW` e inactiva dan `NOT_APPROVED`;
  - `INVALID` (otro campo, inactivo, no aprobado o menor), `SELF`, `UNCHANGED`, `REQUIRED` y `AMBIGUOUS`;
  - reemplazar deja exactamente una propuesta `PENDING` y la anterior en `CANCELLED`; dos solicitudes simultáneas dejan una sola (la otra, 409);
  - cancelar; cancelar sin propuesta da `NOT_FOUND`;
  - los registros de `validation_logs` no incluyen el nombre libre.
- Aprobar:
  - `users_honors` cambia **solo** `instructor_user_id`, `instructor_name` y `modified_at`; `date`, `validate`, `certificate`, `images`, `validation_status`, `validated_by_id` y `validated_at` quedan idénticos;
  - al asignar un usuario, el nombre libre queda en `NULL` y al revés;
  - si el instructor dejó de ser elegible: 400 `INVALID`, la propuesta sigue `PENDING` y la fila no cambia;
  - doble aprobación: 409; aprobar una propuesta ya rechazada o cancelada: 409;
  - revisor de otro Campo Local: 403; `super-admin`, `admin` sin campo y `director-lf` del mismo campo: permitido;
  - `previous_kind` correcto en `NONE`, `USER` y `EXTERNAL`;
  - prueba de integración del conteo: tras aprobar, el instructor suma 1.
- Rechazar: exige motivo; `users_honors` no cambia; el miembro ve `REJECTED` con el motivo hasta que haga otra propuesta.
- **Coexistencia con `assertHonorIsMutable`** (misma spec): con la especialidad `APPROVED`, la propuesta funciona mientras `PATCH` con `instructorUserId` sigue dando `VALIDATION_HONOR_INVALID_STATUS`; ambos resultados en el mismo test.
- `honors.service.spec.ts`: `getUserHonors` trae `instructor_proposal` (`null`, `PENDING`, `REJECTED`; solo la última; sin correo ni foto).
- `admin-honor-instructor-proposals.controller.spec.ts`: metadatos de `@GlobalRoles`, `@SkipPermissions` y `@Throttle`.
- Regresión de la extracción del helper de alcance: las pruebas de acceso de `admin-certificate-bulk-imports.service.spec.ts` pasan sin cambios.
- Esquema: `certificate-bulk-imports.schema.spec.ts` (o uno nuevo) comprueba la tabla, el enum y las relaciones. Prueba SQL contra la rama dev de Neon: los CHECK rechazan los dos campos juntos, ninguno, `REJECTED` sin motivo y `APPROVED` sin revisor, y el índice único rechaza dos `PENDING` de la misma especialidad.
- Historial: `evidence-review.service.spec.ts` verifica que las acciones nuevas aparecen en `getHistory` sin romper el mapper.

---

## 5. Aprobación: cómo se aplican el instructor y las fechas

En `CertificateBulkImportApplicationService.approveHonorItem`:

1. `findSubmittedItem` ya trae la fila completa, incluidos `instructor_*`. Se agregan esos campos al tipo `CertificateImportItemWithBatch`.
2. **Alta** (`users_honors.create`): copia `instructor_user_id` e `instructor_name`, igual que hoy copia `date = completed_at`.
3. **Fila de `users_honors` que existe pero todavía no está `APPROVED`** (por ejemplo, `IN_PROGRESS` desde el flujo normal): la aprobación aplica los hechos revisados. Si la fila de importación **trae** instructor, lo escribe (reemplaza al declarado antes en el flujo normal, y el evento guarda `previous_instructor_kind`); si **no trae** instructor, deja el existente intacto. Nunca borra un instructor por omisión.
4. **Fila ya `APPROVED`** (hoy solo se refresca la evidencia; con otra fecha responde `CERTIFICATE_IMPORT_FINAL_DATE_CONFLICT`, sin cambios). Con **fecha idéntica** (D7):
   - si `users_honors` no tiene instructor: lo completa con lo de la fila;
   - si tiene el **mismo** instructor, o la fila no trae instructor: no hace nada;
   - si tiene **otro**: **conserva el existente** y no lo sobrescribe. Agrega `instructor_conflict: true` al payload de `ITEM_APPROVED`, más `kept_instructor_kind` (`USER`/`EXTERNAL`) y `kept_instructor_user_id` si es un usuario (nunca el nombre libre). Es coherente con la regla existente que protege los hechos ya aprobados.
   - **Visibilidad para el revisor (D7)**: (a) la respuesta de `POST /admin/certificate-bulk-imports/:batchId/approve` incluye `items[].instructor_conflict`, para que el panel lo muestre al aprobar; (b) el detalle del admin devuelve, para filas `SUBMITTED` de tipo `HONOR`, un `instructor_conflict` calculado **antes** de decidir (se compara con la fila `APPROVED` de `users_honors` del mismo usuario y especialidad, igual que ya hace `blockersForItems` con los bloqueos de año); (c) para filas ya aprobadas, el valor sale del payload de `ITEM_APPROVED`. Así el revisor del Campo Local lo ve antes y después de aprobar. El miembro **no** recibe aviso del conflicto.
5. No se vuelve a validar el alcance ni el estado del instructor en la aprobación de la carga por certificado. Se validó al asignarlo, y si se desactivó después, el dato histórico vale igual. Solo se evita romper la transacción: la FK sigue siendo válida porque no hay hard deletes. (La aprobación de una **propuesta** sobre una especialidad ya aprobada sí revalida: ver §4.9.)
6. **Auditoría**: el payload de `ITEM_APPROVED` pasa a ser `{ applied_entity_type, applied_entity_id, instructor_kind: 'USER'|'EXTERNAL'|'NONE', instructor_user_id?, instructor_conflict? }`. El nombre libre no se copia al evento: queda en la fila del ítem y en `users_honors`. `users_honors.validated_by_id` y `validated_at` siguen registrando quién aprobó.
7. **Clases**: no cambia nada. `completed_at` se convierte en `enrollments.investiture_date` y en el año eclesiástico. El historial queda en `investiture_validation_history` y en el evento `ITEM_APPROVED`.

El conteo de "especialidades enseñadas" se hace sobre `users_honors` (§2.4) y cuenta **ambos flujos** (D9): la carga por certificado (§5) y el flujo normal (§4.8). También suma el instructor que llega por una propuesta aprobada sobre una especialidad ya aprobada (D11, §4.9). Cuenta **especialidades aprobadas declaradas por el miembro y aprobadas por el Campo Local**. En v1 **no hay notificación ni confirmación del propio instructor** (D8): el instructor no se entera ni puede impugnar. La versión 2 podría notificarle y dejarle impugnar.

---

## 6. Impacto en admin y OCR

### 6.1 Admin (revisión del Campo Local)

- `src/lib/api/certificate-bulk-imports.ts`: agregar a `CertificateBulkImportItem` los campos `instructor: { kind, user_id?, display_name } | null`, `instructor_conflict: boolean`, `source_file_id: string | null`, `source_page: number | null`, `honor.category` y `class.club_type`; a `CertificateBulkImportFile`, `page_count: number | null`; al detalle del lote, `ocr_state`.
- `certificate-bulk-import-detail-page.tsx`, en cada fila:
  - HONOR: "Categoría · Especialidad". "Instructor: Ana Pérez (usuario del sistema)" o "Instructor: Juan López — externo, no verificado" (con `Badge variant="outline"`). "Sin instructor declarado" si falta.
  - **Conflicto de instructor (D7)**: si `instructor_conflict` es verdadero, un aviso con `Badge` de advertencia: "Esta especialidad ya estaba aprobada con otro instructor. Se conserva el existente: Ana Pérez." Se muestra antes de aprobar (cálculo previo, §5) y se mantiene después de aprobar.
  - CLASS: "Tipo de club · Clase". "Fecha de investidura: …".
  - **Archivo y página de origen (D4 y D12)**: junto a cada fila con `source_page`, un enlace "Ver en la página N". Al tocarlo, el visor del comprobante abre **el archivo de la fila** (`source_file_id`) y salta a esa página. `PdfInlineViewer` (`components/shared/pdf-inline-viewer`) recibe `initialPage` (y, si el PDF se muestra con el visor del navegador, el fragmento `#page=N`). La resolución es la de §4.7: si falta `source_file_id` o el archivo ya no está, abre el primer archivo en la página 1. Con más de un archivo, el visor muestra un selector de archivo (el lote acepta hasta 10).
  - Si `page_count` es conocido, el visor muestra "Página N de M" del archivo abierto.
  - Estado de lectura: si `ocr_state` es `failed` o `empty`, el detalle lo indica ("La lectura automática no encontró filas; el miembro las agregó a mano").
  - Usar tokens semánticos (`text-muted-foreground`, `Badge`), sin colores fijos.
- Fechas fuera de rango: el admin no edita fechas. Una fila con `completed_at` nulo por estar fuera de rango (D6) no llega a `SUBMITTED`.
- El revisor **no edita** el instructor de una fila de la carga por certificado (v1). Si está mal, rechaza la fila con un motivo y el miembro la corrige y la reenvía (flujo existente). Para una especialidad ya aprobada, el cambio llega como propuesta del miembro (D11) y se resuelve en la cola de abajo.
- **Cola de propuestas de instructor (D11, slice B10)**: vista nueva en la sección de revisión del Campo Local, con los datos de `GET /admin/honor-instructor-proposals` (§4.9).
  - Tabla con especialidad, miembro, **instructor vigente** ("Sin instructor declarado" si no hay) e **instructor propuesto**, con la misma insignia de la fila de la carga por certificado: "Ana Pérez (usuario del sistema)" o "Juan López — externo, no verificado". Filtro de estado (pendientes por defecto) y paginación.
  - Aprobar: `AlertDialog` de confirmación que repite el cambio ("Reemplazar a {vigente} por {propuesto}"). Rechazar: `Dialog` con un solo campo, el motivo (3 a 500 caracteres), según la regla de CRUD del design system (≤4 campos planos).
  - Si la aprobación responde `HONOR_INSTRUCTOR_INVALID` (el instructor ya no es elegible), el diálogo lo explica y deja solo la opción de rechazar.
  - Tokens semánticos y `Badge`, sin colores fijos. Sin notificación a nadie en v1: el revisor consulta la cola, y conviene mostrar el conteo de pendientes en la entrada del menú.
- Revisión de evidencias del flujo normal (`components/evidence-review/evidence-detail-dialog.tsx`): muestra el mismo bloque de instructor (§4.8). No hay "conflicto" en ese flujo.
- Opcional (fuera de v1): mostrar el conteo de especialidades enseñadas en el detalle de usuario del admin (`components/users/detail`).

### 6.2 OCR

**Archivo y páginas (D4 y D12, parte del alcance)**: el parser registra `source_file_id` y `source_page` (§4.7). Cambios en `certificate-ocr.provider.ts`, `cloud-run-certificate-ocr.provider.ts`, `google-vision-certificate-ocr.provider.ts`, `certificate-ocr.parser.ts` y `runQueuedOcr`. Tests en `certificate-ocr.parser.spec.ts`: dos archivos con una especialidad cada uno dan `source_file_id` distintos; dos páginas de un mismo archivo con una especialidad cada una dan `source_page` 1 y 2 y el mismo `source_file_id`; la fecha solo en la página 2 se aplica a un candidato de la página 1 con confianza reducida; una imagen da `source_page = 1`; una fecha `1925` deja `completed_at` nulo y `field_confidence.date = 0` (§3.1).

**Sugerencia de instructor (opcional, sin promesa)**:

- Muchos certificados de especialidad tienen una línea "Instructor: …" o "Instructor(a): …". La propuesta es agregar una regex con etiqueta explícita: `/\binstructor(?:a)?\s*(?:de\s+la\s+especialidad)?\s*:\s*([^\n]+)/i`, recortando fechas y firmas.
  - Si aparece **una sola vez** en el archivo, se sugiere para todos los candidatos `HONOR` de ese archivo. Si aparece varias veces y no se puede asociar a cada especialidad, no se sugiere.
  - Se guarda en `detected_instructor_name` y en `field_confidence.instructor` (de 0.3 a 0.5). **Nunca** se completa `instructor_user_id` automáticamente: hay homónimos, alcance y privacidad de por medio.
  - La app usa la sugerencia para precargar el campo de búsqueda o el nombre libre, y el miembro confirma. La búsqueda es solo dentro del Campo Local (D2); si el nombre sugerido no aparece, la app ofrece "Usar «…» como nombre".
- Colisión: `tagInstitutional` ya marca `^instructor$` como la clase `GM-03`. La regex nueva exige la etiqueta con `:` y un nombre después, y solo corre sobre líneas que no matchearon `CLASS_LABEL_REGEX`. Test obligatorio: `Investidura: Instructor` sigue siendo una clase institucional y no se interpreta como instructor de especialidad.
- Calidad esperada: baja o media. Las firmas manuscritas no se leen. Es un plus, no un requisito.

---

## 7. Riesgos, preguntas abiertas y plan

### 7.1 Riesgos

| Riesgo | Mitigación |
|---|---|
| Exposición de datos personales en la búsqueda de instructores (directorio del Campo Local). **Más débil que en la propuesta anterior**: el endpoint ya no está atado a un lote propio y editable (D9) | Alcance al Campo Local del usuario autenticado, solo nombre y foto firmada, sin email, mínimo 3 caracteres, máximo 10 resultados, 30/min, sin menores, `[]` si `q` es corto (§4.4) |
| Un cliente asigna como instructor a alguien de otro campo | `assertEligible` repite el filtro de alcance contra el dueño de la especialidad en el servidor; el UUID no se acepta por haber salido del buscador |
| Conteo inflado o falso (el miembro declara un instructor que no enseñó) | Aprobación del Campo Local. El admin ve el tipo de instructor. Se puede auditar por `applied_entity_id`. Sin confirmación del instructor en v1 (D8) |
| Conteo subestimado: instructores de otros campos (nombre libre, D2) y especialidades ya aprobadas antes de la funcionalidad | Las ya aprobadas se completan con la propuesta de D11 (§4.9), pero depende de que el miembro la haga. Lo de otros campos se acepta en v1: ampliar el alcance a la unión o vincular nombres libres con usuarios queda para después |
| Instructor dado de baja o anonimizado | No se copia el nombre. La FK se mantiene (sin hard deletes) y se muestra "Usuario eliminado" |
| Reproceso OCR borra filas editadas | Criterio de descarte por `revision = 0` (§4.1) |
| Semántica frágil de `PATCH` (inconsistencia 4) | Se corrige en B2 con tests |
| Clases históricas invisibles con `GET /classes` | Endpoint de catálogo propio del flujo (§4.3) |
| Confusión entre "Instructor" (clase GM-03) y el instructor de una especialidad | Nombres de errores y textos de UI distintos, y test en el parser |
| Migración en Neon con shadow DB rota (M1, M2 y M4) | Aplicación manual con `NOT VALID`/`VALIDATE` y `CONCURRENTLY`, en dev → staging → prod, **antes** de desplegar el código que la usa |
| Costo de URLs firmadas en la búsqueda | 10 por consulta, TTL corto, `null` si falla. No se firman en los listados del admin ni en `getUserHonors` |
| `ocr_state = failed` sin salida: el job fallido conserva el `jobId` durante una hora y bloquea el reintento | Eliminar el job fallido antes de re-encolar (§4.6, B3) |
| `done` mal calculado porque el job exitoso se borra (`removeOnComplete`) | `done`/`empty` salen del evento `OCR_PROCESSED`, no del job (§4.6) |
| Parseo por página cambia la semántica de la fecha global y puede perder fechas | Fecha de la página, con respaldo a la primera fecha del documento y confianza reducida; tests (§4.7) |
| `source_file_id` nulo o desactualizado (D12): filas manuales, filas anteriores a M2, un archivo que ya no está, o un parser que no pudo ubicar el archivo | Regla única en app y admin (§4.7): archivo de la fila si está en `files[]`; si no, el primero; la página solo se respeta cuando el archivo salió de `source_file_id`. `ON DELETE SET NULL` evita perder la fila. Tests en los dos clientes |
| Una propuesta de instructor (D11) se usa para abusar: spam de propuestas, o proponer a quien no corresponde | Solo el dueño propone; una sola pendiente por especialidad (índice único parcial, reemplazar cancela la anterior); 10 por minuto; `assertEligible` al proponer y al aprobar; el Campo Local decide y puede rechazar con motivo |
| Escribir `users_honors` de una especialidad aprobada fuera de `assertHonorIsMutable` (D11) | Un único método acotado (`applyApprovedInstructor`) que solo toca `instructor_*` y `modified_at`, con un test que compara la fila antes y después; `assertHonorIsMutable` no cambia (§4.9) |
| La propuesta se aprueba cuando el instructor ya no es elegible (se desactivó o cambió de campo) | Se revalida al aprobar (§4.9, paso 4); si falla, 400 y el revisor la rechaza con motivo |
| Nadie mira la cola de propuestas y quedan pendientes (D11, sin notificaciones en v1) | Conteo de pendientes visible en la entrada del menú del admin (B10). Si no basta, una notificación al Campo Local queda como siguiente paso |
| Una aprobación de la carga por certificado y una propuesta compiten por el instructor de la misma especialidad | La propuesta no se cancela por la aprobación; al aprobarse, reemplaza y deja `previous_kind` en el log. La cola muestra el instructor vigente (§4.9) |
| Fecha mínima 1960 rechaza certificados legítimos más antiguos | Es la decisión D6. Una excepción manual queda fuera de v1 |
| La cota de fecha usa "hoy" en UTC (como `assertNotFuture`) | El desfase va por delante de América, así que no genera rechazos falsos; no cubre zonas UTC+ |

Retirado de esta tabla (D13): el "hueco de mutabilidad" de `POST /users/:userId/honors` y `/bulk` y el de abandonar y reiniciar una especialidad aprobada. Ya no son un riesgo pendiente de este diseño: los cierran SEC-1 y SEC-2, que se despliegan antes de B5 y B9 (§7.3).

### 7.2 Preguntas abiertas

Las preguntas de versiones anteriores quedaron resueltas y se retiraron:

- Las cinco de la propuesta original: D1, D2, D7, D8 y D9.
- Las cuatro de la versión del 2026-10-10, resueltas el 2026-10-12: dónde se pide el instructor en el flujo normal (D10), el hueco de mutabilidad de `POST /users/:userId/honors` y `/bulk` (D13, SEC-1 y SEC-2), completar el instructor de especialidades ya aprobadas (D11) y `source_file_id` para lotes con varios archivos (D12).

Quedan estas dos, que no bloquean ningún slice:

1. **¿`ocr_state` necesita un `ocr_error_code`?** D3 define cinco estados. Para distinguir "lectura no disponible" de "ilegible" en `failed` haría falta un campo opcional. Hoy el único caso diferenciado es el 400 `OCR_UNAVAILABLE` al encolar.
2. **El flujo normal guarda `date` como fecha de inicio** (§1.6). ¿Debe el formulario pedir la fecha de finalización? D6 se aplica al campo `date` tal como existe; no se agrega un selector de fecha en "Mis especialidades".

### 7.3 Plan de implementación por slices

Cada slice es un PR de menos de 400 líneas, con tests y docs en el mismo PR (work-unit commits). Los slices del backend y el admin se llaman **B1 a B10**; los dos PRs de seguridad previos, **SEC-1** y **SEC-2** (D13); los de la app se llaman **S1 a S8** y están en el documento hermano (§11). Esta sección fija el orden y las dependencias de **todos**.

#### Mapa de dependencias y migraciones

| Slice | Repo | Contenido | Migración (manual por `psql` en Neon) | Depende de |
|---|---|---|---|---|
| **SEC-1** | backend | `fix/honors-create-mutability-guard`: el alta ya no reescribe `APPROVED` ni `PENDING_REVIEW` | **No** | — |
| **SEC-2** | backend | `fix/honors-abandon-restart-guard`: abandonar y reiniciar no destruyen `APPROVED` ni `PENDING_REVIEW` | **No** | SEC-1 (apilado) |
| **B1** | backend | Módulo de instructores, catálogos, rango de fechas e `include` de nombres | **No** | — |
| **B2** | backend | Instructor en la carga por certificado, aprobación y conflicto | **Sí: M1** | B1 |
| **B3** | backend | `ocr_state` y reintento de OCR | **No** | — |
| **B4** | backend | `page_count`, `source_page` y `source_file_id` | **Sí: M2** | — (ordenar después de B2 por conflictos en `runQueuedOcr`) |
| **B5** | backend | Instructor y fechas en el flujo normal de especialidades (D10) | **No** (usa M1; M1 tiene que estar aplicada en el entorno) | B1, B2 (M1 aplicada), **SEC-1, SEC-2** |
| **B6** | admin | Revisión de la carga por certificado: instructor, conflicto, archivo y página | **No** | B2, B4 (B3 opcional) |
| **B7** | admin | Revisión de evidencias: instructor | **No** | B5 |
| **B8** | backend | Sugerencia de instructor del OCR (opcional) | **Sí: M3** | B2, B4 |
| **B9** | backend | Propuesta de instructor sobre una especialidad aprobada (D11) | **Sí: M4** (y requiere M1 aplicada) | B1, B2 (M1 aplicada), B5, **SEC-1, SEC-2** |
| **B10** | admin | Cola de propuestas de instructor del Campo Local (D11) | **No** | B9 |
| **S1 a S3** | app | Errores y copy, subida reintentable, visor | No | S3 abre el archivo y la página de la fila cuando exista B4; sin B4 abre el primero en la 1 |
| **S4** | app | Revisión | No | B1 (nombres en filas), B3 (estados F/G exactos), S1, S3 |
| **S5** | app | Editor y selectores de catálogo | No | B1 (búsqueda y clases), S4 |
| **S6** | app | Instructor en la carga por certificado | No | B1, B2 (M1 aplicada), S5 |
| **S7** | app | Instructor en "Mis especialidades" (D10) | No | B1, B5 (M1 aplicada), SEC-1, SEC-2, componente de S6 |
| **S8** | app | Proponer instructor en una especialidad aprobada (D11) | No | B9 (M4 aplicada), B10, S7 |

**Orden recomendado (backend → app → admin)**

1. **SEC-1 y después SEC-2** (sin migración). Son PRs chicos e independientes del rediseño; solo bloquean B5 y B9.
2. **B1** (sin migración). Desbloquea a la app: los selectores de S5 ya pueden hablar con la API real.
3. **B3** (sin migración). Independiente; desbloquea los estados de S4.
4. **B2 + aplicar M1** en Neon dev → staging → prod. Desbloquea S6, B5 y B9.
5. **B4 + aplicar M2**. Desbloquea la apertura en el archivo y la página de S3/S4 y B6.
6. **B5** (usa M1; requiere SEC-1 y SEC-2). Desbloquea S7, B7 y B9.
7. **B9 + aplicar M4** (requiere B5, M1 aplicada y SEC-1/SEC-2). Desbloquea B10 y S8.
8. App en paralelo mientras avanza el backend: **S1 → (S2 ∥ S3) → S4 → S5 → S6 → S7 → S8**. S1 a S3 no necesitan backend nuevo.
9. Admin: **B6** después de B2 y B4; **B7** después de B5; **B10** después de B9. S8 no se publica sin B10: una propuesta que nadie puede resolver es un callejón sin salida.
10. **B8** (opcional) al final.

**Regla de despliegue de migraciones**: cada migración es aditiva (columnas `NULL`, CHECK `NOT VALID` y luego `VALIDATE`, índices `CONCURRENTLY`; M4, al crear una tabla vacía, crea sus CHECK e índices directamente). Se aplica a mano por `psql` en la rama de Neon del entorno **antes** de desplegar el backend que usa las columnas o la tabla, y se registra en `_prisma_migrations`. Código viejo + base nueva funciona (columnas opcionales, tabla sin uso). Código nuevo + base vieja **falla**, así que el orden "migrar primero" es obligatorio. `schema.prisma` y la migración van en el mismo PR para regenerar el cliente.

#### Prerrequisitos de seguridad: SEC-1 y SEC-2 (D13)

Son dos PRs aparte, previos a B5 y B9, sin migración ni cambio de contrato para la app. Cierran los caminos por los que hoy una especialidad `APPROVED` o `PENDING_REVIEW` se puede reescribir o destruir (§1.6, puntos 2 y 2b). Hasta que no estén desplegados, no se mergean B5 ni B9, y por tanto tampoco S7 ni S8.

**SEC-1 — `fix/honors-create-mutability-guard`**

- `createUserHonor`: al encontrar una fila existente (activa o no), llama a `assertHonorIsMutable(existing.validation_status)` **antes** del `update`. Para eso el `select` de la búsqueda previa agrega `validation_status`. Una fila `APPROVED` o `PENDING_REVIEW` responde 400 `VALIDATION_HONOR_INVALID_STATUS` y no se escribe nada.
- `createUserHonorsBulk`: la búsqueda previa de filas existentes agrega `validation_status` y valida **todas** las filas contra `assertHonorIsMutable` antes de ejecutar `operations`. Si una está bloqueada, el lote entero responde 400 con ese código y no se escribe nada (el lote ya se validaba completo antes de escribir para duplicados y catálogo, así que no se introduce parcialidad nueva).
- Sin cambio para filas inexistentes ni para `IN_PROGRESS`/`REJECTED`.
- Tests (`honors.service.spec.ts`): `createUserHonor` y `createUserHonorsBulk` rechazan `APPROVED` y `PENDING_REVIEW` y no llaman a `update`; siguen funcionando con `IN_PROGRESS`, `REJECTED` y filas nuevas; en el lote, una fila bloqueada impide escribir las demás.
- Docs: `ENDPOINTS-LIVE-REFERENCE.md` (nuevo 400 en ambos endpoints).

**SEC-2 — `fix/honors-abandon-restart-guard`** (apilado sobre SEC-1)

- `abandonHonor`: antes de desactivar, `assertHonorIsMutable(userHonor.validation_status)`. En `APPROVED` y `PENDING_REVIEW` responde 400 `VALIDATION_HONOR_INVALID_STATUS`.
- `startHonor` sobre una fila **inactiva**:
  - `APPROVED` o `PENDING_REVIEW`: solo restaura `active = true` (y `modified_at`). **No** reinicia el estado, la fecha, las evidencias ni `validated_*`, no limpia el instructor y no emite `honor.started`. Devuelve la fila como está.
  - `IN_PROGRESS` o `REJECTED`: se conserva el reinicio actual.
- Tests: abandonar `APPROVED` y `PENDING_REVIEW` rechaza y no escribe; iniciar sobre una inactiva `APPROVED` o `PENDING_REVIEW` solo cambia `active` (la fila queda idéntica salvo `active` y `modified_at`) y no emite el evento de logro; el reinicio de una inactiva `IN_PROGRESS`/`REJECTED` sigue vaciando evidencias.
- Docs: `ENDPOINTS-LIVE-REFERENCE.md` (400 en `DELETE /users/:userId/honors/:honorId` y la semántica de `POST …/:honorId` sobre una fila inactiva).

**B1 — Backend: módulo de instructores, catálogos, fechas e includes** (sin migración)

- `src/instructors/` (`InstructorsModule`, `InstructorCandidatesController`, `InstructorsService`): `GET /instructor-candidates?q=` (§4.4) y `assertEligible(ownerUserId, instructorUserId)`. `escapeLikeWildcards` se extrae a `src/common/utils`. Registra los `ErrorCode` `HONOR_INSTRUCTOR_*` (§4.5).
- `src/common/utils/honor-date-range.ts`: `MIN_CERTIFICATE_DATE`, `assertDateInRange` y el decorador `@IsDateInRange()` (§3.1). `UpdateCertificateImportItemDto.completed_at` lo usa; `assertNotFuture` pasa a `assertDateInRange`; error `CERTIFICATE_IMPORT_DATE_TOO_OLD`.
- Parámetro `search` en `GET /honors` (`HonorFiltersDto`, `buildHonorCatalogWhere`).
- `GET /certificate-bulk-imports/catalog/classes?clubTypeId=`.
- `batchInclude` del miembro y del admin con `honor` y `category`, `class` y `club_type` (corrige la inconsistencia 3), y OCR que deja `completed_at` nulo si la fecha está fuera de rango.
- Tests:
  - `instructors.service.spec.ts` y `instructor-candidates.controller.spec.ts`:
    - `q` corto devuelve `[]`; no matchea por email;
    - excluye al propio usuario, inactivos, no aprobados, menores, cuentas anonimizadas y **usuarios de otro Campo Local**;
    - si quien llama no tiene Campo Local: `[]`;
    - máximo 10 resultados; la respuesta no tiene email ni `birthday`;
    - metadata del `@Throttle`;
    - `assertEligible` cubre `INVALID` y `SELF`.
  - `honor-date-range.spec.ts`: 1959-12-31 rechaza, 1960-01-01 acepta, hoy acepta, mañana rechaza.
  - `certificate-bulk-imports.dto.spec.ts`: `completed_at` en rango.
  - `honors.service.spec.ts`: `search` escapa `%`/`_` y matchea traducciones.
  - Catálogo de clases: incluye clases retiradas e institucionales con la bandera, y excluye las inactivas que no son institucionales.
  - `certificate-ocr.parser.spec.ts`: fecha `1925` deja `completed_at` nulo.
- Docs: `ENDPOINTS-LIVE-REFERENCE.md` (endpoints nuevos y corregir `JWT` → `Público` en los cinco catálogos) y `features/carga-masiva-certificados.md`.

**B2 — Backend: instructor en la carga por certificado** (**migración M1**)

- Migración `20261010120000_certificate_import_honor_instructor` (SQL de §2.3–2.5) y `schema.prisma` (items y `users_honors`).
- `UpdateCertificateImportItemDto`: `instructor_user_id`, `instructor_name` y `club_type_id`.
- `CertificateBulkImportsService`:
  - `mergeItem` y `toItemUpdateData` con "undefined = no cambia" (corrige la inconsistencia 4).
  - `assertInstructorChoice` (llama a `InstructorsService.assertEligible` de B1) y la verificación de `club_type_id`.
  - Limpiar el instructor al pasar la fila a `CLASS`.
  - `changed_fields` en los eventos.
  - Criterio de descarte del OCR por `revision = 0`.
- Mapper del bloque `instructor` en las respuestas del miembro y del admin (sin email).
- `approveHonorItem`: copiar el instructor según §5 (incluido `instructor_conflict` y la vista previa del admin).
- Tests:
  - `certificate-bulk-imports.dto.spec.ts`: null, uuid inválido, nombre de 2 o 151 caracteres, caracteres de control, `club_type_id`.
  - `certificate-bulk-imports.service.spec.ts`:
    - asignar un usuario limpia el nombre y al revés;
    - los dos valores juntos dan `AMBIGUOUS`;
    - instructor en una fila CLASS da `NOT_ALLOWED`;
    - ser el propio instructor da `SELF`;
    - un usuario de otro Campo Local, inactivo o menor da `INVALID`;
    - `addItem` con un instructor inválido nace `NEEDS_REVIEW` con motivo;
    - una fila `HONOR` queda `READY` sin instructor (D1);
    - un `PATCH` sin `item_type` no borra `honor_id`;
    - el reproceso OCR conserva las filas con `revision > 0`;
    - un desfase de `club_type_id` da `MISMATCH`.
  - `certificate-bulk-imports-application.service.spec.ts`:
    - alta con usuario o externo;
    - fila existente no aprobada con instructor distinto: lo reemplaza y registra `previous_instructor_kind`;
    - fila existente no aprobada y fila de importación sin instructor: conserva el existente;
    - fila `APPROVED` con fecha distinta: `FINAL_DATE_CONFLICT`, sin cambios;
    - fecha idéntica sin instructor completa;
    - fecha idéntica con otro instructor conserva y marca `instructor_conflict` (con `kept_instructor_*`);
    - el payload del evento no incluye el nombre libre.
  - `admin-certificate-bulk-imports.service.spec.ts`: `instructor_conflict` previo en filas `SUBMITTED` y posterior en filas aprobadas.
  - `certificate-bulk-imports.schema.spec.ts`: las columnas y relaciones existen.
  - `certificate-import-response.mapper.spec.ts`: `instructor.kind`, "Usuario eliminado" y que no haya email.
  - Test SQL o de integración contra la rama dev de Neon: los CHECK rechazan los dos valores juntos y el instructor en una fila CLASS.
- Docs: `SCHEMA-REFERENCE.md`, `ENDPOINTS-LIVE-REFERENCE.md` y `features/carga-masiva-certificados.md`.

**B3 — Backend: `ocr_state` y reintento** (sin migración)

- Resolución de `ocr_state` (§4.6) en `CertificateBulkImportsService.getBatch` y en las respuestas de `confirm`/`process-ocr`, y en el detalle del admin. El listado `/pending` del admin no lo calcula.
- `processOcr`: si el job existente está `failed`, se elimina antes de re-encolar.
- Tests:
  - `pending`/`running` según el estado del job;
  - `done` y `empty` con el job ya borrado (solo el evento);
  - `failed` con job fallido y con job desaparecido pasados 5 minutos;
  - `null` sin `OCR_QUEUED`;
  - sin Redis;
  - reintento tras `failed`.
- Docs: `ENDPOINTS-LIVE-REFERENCE.md`.

**B4 — Backend: archivo y páginas del comprobante** (**migración M2**)

- Migración `20261010130000_certificate_import_ocr_pages` (`source_page` y `source_file_id` con su FK `ON DELETE SET NULL` e índice parcial en items, y `page_count` en files) y `schema.prisma`.
- `CertificateImportFilesService.confirm`: guarda `page_count` (PDF: el valor de `assertCertificateImportPdf`; imagen: 1).
- `toPublicImportFile` expone `page_count`; los mappers de ítem exponen `source_file_id` y `source_page`.
- Contrato OCR por archivo y página (§4.7): proveedor de Cloud Run, proveedor de imágenes, `CertificateOcrParser` y `runQueuedOcr` guardan `source_file_id` y `source_page`.
- Tests: `confirm` guarda `page_count` (PDF de 1 y de 5 páginas; imagen); el mapper público lo expone; parser por archivos y páginas (§6.2); `source_file_id` y `source_page` se guardan; un lote de varios archivos asigna el archivo correcto a cada fila; archivo y filas anteriores a M2 devuelven `null`; borrar el archivo deja `source_file_id` en `NULL` sin borrar la fila (SQL contra la rama dev de Neon).
- Docs: `SCHEMA-REFERENCE.md` y `ENDPOINTS-LIVE-REFERENCE.md`.

**B5 — Backend: instructor y fechas en el flujo normal** (sin migración nueva; **requiere M1 aplicada y SEC-1/SEC-2 desplegados**)

- DTO de `src/honors/dto/honors.dto.ts`, `HonorsService`, `EvidenceReviewService` y `validation_logs` según §4.8. El instructor se guarda con el `PATCH` y solo en `IN_PROGRESS` o `REJECTED` (D10). El cierre de las vías de alta ya viene de SEC-1: B5 no agrega un guard propio.
- El reinicio de una fila inactiva `IN_PROGRESS`/`REJECTED` deja `instructor_*` en `NULL`.
- Tests: los de §4.8.
- Docs: `ENDPOINTS-LIVE-REFERENCE.md` (campos nuevos de `PATCH /users/:userId/honors/:honorId`, `POST /users/:userId/honors`, `/bulk`, y el detalle de revisión de evidencias) y `features/rbac.md` si el selector de instructor lleva permiso propio (hoy no).

**B6 — Admin: revisión de la carga por certificado** (sin migración)

- Tipos de la API y fila de detalle (§6.1): categoría, tipo de club, instructor ("sistema" o "externo, no verificado"), conflicto de instructor, `source_file_id`, enlace "Ver en la página N", `PdfInlineViewer initialPage`, selector de archivo si el lote tiene más de uno y "Página N de M".
- Tests: render de la fila con instructor usuario, externo y nulo; CLASS muestra el tipo de club y la etiqueta "Fecha de investidura"; aviso de conflicto; el enlace de página abre el **archivo y la página** de la fila; sin `source_file_id` abre el primer archivo en la página 1; `page_count` nulo no rompe el visor.

**B7 — Admin: revisión de evidencias de especialidad** (sin migración)

- `evidence-detail-dialog.tsx`: bloque de instructor (§4.8).
- Tests: render con usuario, externo y sin instructor.

**B8 — OCR: sugerencia de instructor (opcional)** (**migración M3**)

- Columna `detected_instructor_name` (migración aditiva `…_certificate_import_detected_instructor`) y regex en `CertificateOcrParser` según §6.2.
- Tests en `certificate-ocr.parser.spec.ts`:
  - `Instructor: Ana Pérez` se sugiere para todas las HONOR del archivo;
  - con dos instructores no se sugiere;
  - `Investidura: Instructor` sigue institucional y sin sugerencia;
  - nunca se completa `instructor_user_id`.

**B9 — Backend: propuesta de instructor sobre una especialidad aprobada** (**migración M4**; requiere M1 aplicada y SEC-1/SEC-2 desplegados)

- Migración `20261012120000_honor_instructor_proposals` (tabla, enum, CHECKs e índices de §2.7) y `schema.prisma`.
- `HonorInstructorProposalsService` y sus endpoints (§4.9):
  - del miembro: `POST` y `DELETE /users/:userId/honors/:honorId/instructor-proposal` (`user_honors:submit`, solo el dueño, 10/min);
  - del admin: `GET`, `approve` y `reject` en `admin/honor-instructor-proposals` (`@GlobalRoles` del Campo Local, `@SkipPermissions()`).
- Extracción del alcance del revisor (`resolveReviewerAccess`, `assertCanAccessBatch`) a `src/common/reviewer-scope/`, compartido con `AdminCertificateBulkImportsService`.
- `applyApprovedInstructor`: la única escritura sobre una especialidad aprobada, acotada a `instructor_*` y `modified_at`. `assertHonorIsMutable` no cambia.
- Bloque `instructor_proposal` en `getUserHonors` (sin foto firmada en listados).
- `ErrorCode` nuevos de §4.5 y acciones de `validation_logs` (`instructor_proposed`, `instructor_withdrawn`, `instructor_approved`, `instructor_rejected`).
- Tests: los de §4.9 ("Tests de B9").
- Docs: `SCHEMA-REFERENCE.md` (tabla y enum), `ENDPOINTS-LIVE-REFERENCE.md` (endpoints, bloque `instructor_proposal` y errores), `features/rbac.md` y `RBAC-ENFORCEMENT-MATRIX.md` (revisor del Campo Local sobre propuestas) y `features/validacion-investiduras.md` solo si menciona el revisor del Campo Local de especialidades.

**B10 — Admin: cola de propuestas de instructor** (sin migración)

- Tipos y cliente de API para `admin/honor-instructor-proposals`; vista de la cola en la sección de revisión del Campo Local (§6.1): tabla con instructor vigente y propuesto, filtro de estado, paginación y conteo de pendientes en el menú.
- Aprobar con `AlertDialog` y rechazar con `Dialog` de un solo campo (motivo, 3 a 500 caracteres), según el design system del admin. Manejo de `HONOR_INSTRUCTOR_INVALID` y `HONOR_INSTRUCTOR_PROPOSAL_NOT_PENDING`.
- Tests: render de la fila con vigente nulo, usuario y externo; aprobar y rechazar llaman al endpoint correcto; el motivo es obligatorio; el error `INVALID` deja solo "Rechazar"; un revisor sin acceso no ve la entrada del menú.

**Cobertura de la app** (detalle en el documento hermano): S1 a S3 no necesitan backend nuevo; S4 consume `ocr_state` (B3), nombres (B1), `page_count` y `source_page` (B4) y el umbral 0.8 sobre `field_confidence.date`; S5 consume la búsqueda de especialidades y el catálogo de clases (B1); S6 consume `GET /instructor-candidates` (B1) y los campos de instructor de la carga por certificado (B2); S7 consume `GET /instructor-candidates` (B1) y los campos de instructor de `/users/:userId/honors` (B5), con SEC-1 y SEC-2 ya desplegados; S8 consume los endpoints de propuesta y el bloque `instructor_proposal` (B9), y necesita la cola del admin (B10). S3, S4 y S5 consumen `source_file_id` junto con `source_page` (B4).
