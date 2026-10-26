# Schema Reference - SACDIA Database

**Estado**: ACTIVE
**Sincronizado contra**: `sacdia-backend/prisma/schema.prisma` en la rama `development` (commit `68123f6`)
**Fecha de resincronizacion**: 2026-10-13 (última migración en `development`: `20261013110000_remove_retired_investiture_permissions`). Las secciones de abajo se resincronizaron por completo hasta el 2026-10-04; después solo se añadieron las de instructor de especialidad y carga por certificado (2026-10-13) y la de aceptación legal (`legal_acceptances`, 2026-10-15, migración `20261015120000_legal_acceptances`, pendiente de merge; las cifras de abajo no la incluyen) y la de perfiles familiares (2026-10-16, actualizada el 2026-10-19 con la Fase 2 completa; migración `20261016120000_family_profiles`, rama `feat/family-profiles`, mergeada (PR #530 de sacdia-backend)). El espejo `schema.prisma` sí es la copia completa e incluye ambas. La sub-fase 3a de perfiles familiares (2026-10-19; migración `20261020120000_family_teen_login`, rama `feat/family-profiles-phase3`, mergeada (PR #531 de sacdia-backend)) añade `supervised_logins` y dos reemplazos de CHECK; ver «Cuentas supervisadas (Fase 3a)». La sub-fase 3b (2026-10-20; migración `20261021120000_family_linked_devices`, misma rama, mergeada (PR #531 de sacdia-backend)) añade `linked_devices` y `device_pairing_tokens` y amplía otro CHECK de `supervised_logins`; ver «Dispositivos vinculados (Fase 3b)». La sub-fase 3c (2026-10-20; migraciones `20261022120000_family_director_minors` y `20261022130000_seed_family_permissions`, misma rama, mergeada (PR #531 de sacdia-backend)) añade `dependent_profiles.teen_login_nudged_at` y los permisos `dependents:create` y `consent:verify`; ver «Registro por director y acceso familiar (Fase 3c)». Las cifras de abajo y el espejo `schema.prisma` **todavía no incluyen ni la 3a ni la 3b ni la 3c** (se resincronizan cuando el backend se mezcle). El seguimiento de coordinadores (2026-10-20; migración `20261023120000_grant_consent_verify_to_coordinators`, rama `feat/coordinator-consent-verify`, solo DML, **aplicada en `development` y `staging`** (2026-10-21), pendiente en `production`) da `consent:verify` a los roles globales de coordinador; ver su sección más abajo. La migración `20261024120000_allow_coordinator_paper_form` (rama `feat/coordinator-pending-consents`, solo DDL, **aplicada en `development` y `staging`** (2026-10-21), pendiente en `production`) amplía el CHECK `guardianships_verification_method_ck` con `coordinator_paper_form`; ver su sección más abajo.

Referencia humana concisa del schema Prisma vigente.

> [!IMPORTANT]
> La autoridad estructural efectiva sigue siendo `sacdia-backend/prisma/schema.prisma`.
> `docs/database/schema.prisma` debe permanecer como espejo documental fiel del mismo archivo.

---

## Cifras vigentes

- **Modelos Prisma**: 257 (incluye 27 modelos `*_translations` de i18n)
- **Enums Prisma**: 79
- **Migraciones Prisma**: 187 directorios en `prisma/migrations/`
- **Tablas Better Auth mapeadas**: `session -> sessions`, `account -> accounts`, `verification -> verifications`
- **Espejo `schema.prisma`**: 262 modelos y 79 enums, es decir, las cifras de arriba más `legal_acceptances` y las 4 tablas de perfiles familiares. La migración `20261016120000_family_profiles` no cambia el número de enums.

---

## Autorización de investidura por solicitud (PR #448 de sacdia-backend, mergeado)

> [!WARNING]
> Las tablas de esta sección están en `development` desde el PR #448 de sacdia-backend (rama `feat/investiture-authorization-ocr`), junto con sus migraciones (`20260930120000_local_field_class_thresholds`, `20261001130000_local_field_investiture_windows`, `20261001143000_district_investiture_pastors`, `20261001193000_investiture_authorization_requests` y `20261002183000_investiture_authorization_resolution`), y están aplicadas en las tres ramas de Neon (2026-10-13). `docs/database/schema.prisma` las refleja.

### `local_field_class_thresholds` (2026-09-30)

- Tabla nueva, no aplicada a producción en este cambio.
- Clave `(local_field_id, ecclesiastical_year_id)`, `minimum_percent` 0–100, default 80.
- La usa el cálculo de requisitos de clase. Sin fila, el porcentaje efectivo es 80.
- Migración: `sacdia-backend/prisma/migrations/20260930120000_local_field_class_thresholds/migration.sql`.

### `local_field_investiture_windows` (2026-10-01)

- Tabla nueva, no aplicada a producción en este cambio.
- Clave `(local_field_id, ecclesiastical_year_id)`. `start_date` y `end_date` inclusivos, con `start_date <= end_date`.
- Sin fila, si el 1 de octubre y el 20 de diciembre intersectan el año, la ventana efectiva es ese recorte. Si no hay intersección y no hay una fila válida dentro del año, no hay ventana: la API responde `start_date` y `end_date` en null y la lectura no inserta. Una fila fuera del año no abre la ventana ni se reescribe al leer.
- No sustituye `investiture_config.investiture_date` ni cierra el pipeline anterior.
- Migración: `sacdia-backend/prisma/migrations/20261001130000_local_field_investiture_windows/migration.sql`.

### `investiture_pastor_quota` y `district_investiture_pastors` (2026-10-01)

- Tablas nuevas, no aplicadas a producción en este cambio.
- El cupo es una fila global (`quota_id = 1`) con `slots >= 0`. Sin fila, el valor efectivo es 2 y la lectura no inserta.
- Cambiar `slots` y dar de alta o reactivar toman el mismo `pg_advisory_xact_lock` antes de leer ocupación o cupo. El caso sin fila queda cubierto. Bajar el cupo no borra asignaciones.
- La asignación es `(districlub_type_id, user_id)`. `active` distingue el cupo ocupado. Como máximo, los `slots` vigentes por distrito.
- El distrito de una autorización se lee por `clubs.church_id` → `churches.districlub_type_id`, no por `clubs.districlub_type_id`.
- No sustituye el rol global `pastor` ni cierra el pipeline anterior.
- `user_id` referencia `users.user_id` con `ON DELETE RESTRICT` y `ON UPDATE NO ACTION`. La relación Prisma se llama `district_investiture_pastor_user`. Si el usuario pierde el rol global `pastor`, la fila sigue `active` y sigue contando para el cupo. El listado la devuelve con `can_authorize` false y `role_missing` true. Si la cuenta está eliminada (`users.active = false`), la fila también sigue `active` y ocupando cupo, y el listado la devuelve con `can_authorize` false y `account_inactive` true. En ambos casos no entra en los autorizadores del club, no autoriza y no recibe correos.
- Cambio de Campo (2026-10-08): dos triggers `AFTER UPDATE OF local_field_id` desactivan (`active = false`, `modified_at = now()`) las asignaciones activas cuyo pastor y distrito dejan de estar en el mismo Campo. `trg_users_drop_district_pastors_on_field_change` en `users` (función `drop_district_pastors_on_user_field_change`) cubre que el pastor cambie de Campo o quede sin Campo, como en la eliminación de cuenta; `trg_districts_drop_district_pastors_on_field_change` en `districts` (función `drop_district_pastors_on_district_field_change`) cubre que el distrito pase a otro Campo. Solo disparan si el valor cambia; no borran filas y liberan el cupo. La migración también desactiva una vez las filas activas que ya cruzaban Campos. Los triggers no están en `schema.prisma`. Reactivar sigue regido por `INVESTITURE_PASTOR_FIELD_MISMATCH`. Por eso una cuenta eliminada que pierde su Campo ya no sigue ocupando cupo.
- Migraciones: `sacdia-backend/prisma/migrations/20261001143000_district_investiture_pastors/migration.sql`, `sacdia-backend/prisma/migrations/20261007180000_district_investiture_pastor_user_fk/migration.sql` y `sacdia-backend/prisma/migrations/20261008120000_district_pastor_field_change/migration.sql` (aplicada en las tres ramas de Neon). La llave foránea también está aplicada en Neon. En la base de prueba reconstruida no había huérfanos; la restricción es `district_investiture_pastors_user_id_fkey`.

### `investiture_authorization_requests` e `investiture_authorization_people` (2026-10-01)

- Tablas nuevas, no aplicadas a producción en este cambio.
- Una solicitud pertenece a una sección y a un año. Las personas guardan clase, enrollment, fecha y estado.
- Estados: `PENDING`, `INVESTED`, `REJECTED_BY_PERSON`, `REJECTED_BY_SYSTEM`, `REMOVED`, `CLOSED_YEAR`.
- `authorization_comment`, `rejection_reason` y `system_reason` guardan el comentario opcional, el motivo humano y el texto largo del sistema. `date_changed_by_id` y `date_changed_at` guardan quién corrigió la fecha y el instante del reloj de la aplicación. Esas dos columnas están en `sacdia-backend/prisma/migrations/20261007180100_investiture_date_change_audit/migration.sql` y están aplicadas en las tres ramas de Neon (2026-10-13). La lectura de la persona no devuelve el motivo humano ni el texto largo, y colapsa los dos rechazos. Autorizar escribe `INVESTED` y pasa el enrollment a `INVESTIDO` sin `FIELD_APPROVED`. El rechazo humano escribe `REJECTED_BY_PERSON` y no cambia el enrollment. Quien ya no cumple queda `REJECTED_BY_SYSTEM` con `resolution_code` `REQUIREMENTS`.
- `single_slot` true es Aventureros o Conquistadores regulares: una fila `PENDING` por persona. false es la excepción de Guía Mayor: una `PENDING` por persona y clase.
- `CLOSED_YEAR` es el pendiente que cerró el año, no un rechazo. No guarda el texto de falta de requisitos. `POST /api/v1/year-end/:yearId/close` y el corte automático lo escriben. Presentar y agregar toman el candado de ese año antes de insertar y vuelven a leer si el año sigue abierto. El corte también alcanza un club cuyo único pendiente es una solicitud de un año terminado. Repetir el cierre no cambia `INVESTED` ni crea otra solicitud en el año siguiente. El recordatorio deja de incluir esa fila porque ya no está `PENDING`.
- Quitar usa `resolution_code` `REMOVED`. Un pendiente de alguien que ya está `INVESTIDO` en esa clase pasa a `REMOVED` con `resolution_code` `ALREADY_INVESTED`.
- Presentar y agregar toman, en este orden y dentro de la misma transacción, `pg_advisory_xact_lock` de la sección y el año (`investiture-authorization-section:`), luego el de cada usuario (`investiture-authorization-user:`) y luego el de cada enrollment (`investiture-authorization-enrollment:`). El de sección cubre el alta del grupo aunque todavía no exista la cabecera. Agregar a una cabecera explícita, bajo ese candado, no la reactiva si otra de la misma sección y año ya tiene pendientes. Quitar y cambiar fecha siguen tomando solo el candado de usuario. El cierre de una fila por fin de año usa el mismo orden de sección, usuario y enrollment, y solo escribe si sigue `PENDING`.
- Resolver toma antes, y los sostiene hasta confirmar, el candado del año (`investiture-authorization-year:`), el de la ventana del Campo y el año (`investiture-authorization-calendar:`, también si todavía no hay fila) y, cuando autoriza el pastor, el de esa asignación (`investiture-authorization-pastor:`). Después toma sección, usuarios y enrollments, vuelve a leer año, ventana y asignación, y comprueba el calendario con el instante tomado después de esa espera. Guardar la ventana toma año y luego calendario. Cerrar o desactivar el año eclesiástico toma el candado del año. Quitar al pastor toma el candado de la asignación y después el de la fila del distrito. `investiture_authorization_people.achievement_intent_key` guarda la intención de `class.completed` en la misma escritura que `INVESTED`. `achievement_event_log.idempotency_key` deja una sola fila de ese evento. Esa clave puede llevar `:`; el identificador de la cola es otro valor estable y no la reutiliza. Una reconciliación entrega la intención confirmada aunque el año o la ventana ya no admitan una autorización nueva. `investiture_message_dispatches` guarda cada correo o notificación de este flujo. La clave única es `(kind, execution_key, recipient_user_id, role, scope_key)`. `kind` es `PRESENTATION`, `REMINDER` o `RESULT`. `queued` significa que la cola aceptó el trabajo. `sent` significa que el proveedor o la bandeja confirmaron la entrega. Un `sending` con `lease_until` nulo o vencido se puede reclamar. Un fallo queda `failed` y se reintenta sobre la misma fila. `sent` no abre otro envío. Una presentación nueva guarda su identidad de operación en `execution_key`. Repetir los mismos enrollments es otra operación. Reintentar la misma identidad no aborta la transacción. `uncertain` es un acuse ambiguo que pasó 24 horas y no se reenvía solo. Antes de reenviar un contenido congelado se vuelven a comprobar destinatario, rol, territorio, año y pendientes. Si ya no corresponde, o si solo queda autorizada una parte del contenido congelado, el aviso queda `skipped`, no se llama al proveedor y no se cambia el cuerpo ni la clave. Ese cuerpo, su destino y su alcance salen de la misma instantánea con la que se armó el correo. El cuerpo del resultado no guarda el motivo humano. `notification_logs.idempotency_key` deja una sola fila de bandeja por aviso de resultado. `attempts` cuenta cada entrega al canal de correo (reclamo o re-encolado); el tope de recordatorios es 5. `investiture_reminder_runs` registra la corrida diaria de recordatorios por Campo, rol (`pastor`, `director-lf`, `assistant-lf`) y día local (`local_date`, texto `YYYY-MM-DD`); su clave primaria `(local_field_id, role, local_date)` hace idempotente la reclamación entre instancias y la FK a `local_fields` es `ON DELETE CASCADE`. Las migraciones son `20261005190000_investiture_message_dispatches`, `20261005200000_investiture_message_delivery`, `20261006120000_investiture_message_uncertain` y `20261007190000_investiture_reminder_runs`. No están aplicadas a producción.
- Escribir progreso, evidencia, envío o revisión de ese enrollment toma el mismo candado de enrollment y vuelve a leer el pendiente antes de guardar. La subida no toca almacenamiento si ya hay pendiente. El borrado de almacenamiento ocurre después de esa comprobación.
- Índices únicos parciales, solo en el SQL: una `PENDING` por `(user_id, class_id)` y una `PENDING` con `single_slot` true por `user_id`. Prisma no los expresa. El modelo tampoco declara las llaves hacia `club_sections`, `ecclesiastical_years` ni `enrollments`; esas llaves están en el SQL.
- `prisma migrate diff` contra el esquema no aplica esos índices ni esas llaves. No sustituye la migración.
- No sustituye el pipeline anterior ni marca `locked_for_validation`.
- Migración de las tablas: `sacdia-backend/prisma/migrations/20261001193000_investiture_authorization_requests/migration.sql`. Los tres textos van en `sacdia-backend/prisma/migrations/20261002183000_investiture_authorization_resolution/migration.sql`. Ninguna está aplicada a producción.

### `investiture_validation_history` y `LEGACY_LOCK_RELEASED` (fase 8, 2026-10-09)

- Valor nuevo de `investiture_action_enum`: `LEGACY_LOCK_RELEASED`. Migración `sacdia-backend/prisma/migrations/20261009120000_investiture_legacy_lock_release_action/migration.sql` (`ALTER TYPE ... ADD VALUE IF NOT EXISTS`). Mergeada con backend #469 y aplicada en `development`, `staging` y `production` de Neon (2026-10-13).
- Solo la escribe `POST /api/v1/admin/investiture/legacy-locks/release` cuando suelta `locked_for_validation`: una fila por enrollment liberado, con `performed_by` el `super-admin` que corrió la operación y un comentario fijo. El `investiture_status` del enrollment no cambia.
- La tabla `investiture_validation_history` se conserva y solo se lee; `investiture_config` también se conserva, sin lecturas ni escrituras por HTTP (sus rutas responden 410).
- Una app o un panel viejos que listen el historial reciben un valor de `action` que no conocen. La app vieja lo muestra como «Enviado para validación».

## Instructor de especialidad, fecha de finalización y carga por certificado (2026-10-13)

> [!WARNING]
> Cuatro migraciones aditivas del backend (#474, #475, #479 y #480). Estado por rama de Neon: las cuatro están aplicadas en `development`, `staging` y `production` (verificado el 2026-10-13 contra `_prisma_migrations` y el esquema). Procedimiento y reglas en `docs/deployment/DEPLOYMENT-GUIDE.md` §0.4 y §0.5. Código nuevo sobre una base sin estas migraciones **falla**: migrar primero.

### `users_honors`: instructor y fecha de finalización

- `instructor_user_id uuid` (FK a `users`, `NO ACTION`) e `instructor_name varchar(150)`, ambos nullable (M1). CHECK: `users_honors_instructor_exclusive_ck` (como máximo uno) y `users_honors_instructor_name_ck` (nombre libre de 3 a 150 caracteres sin contar espacios de los extremos). Índice parcial `idx_users_honors_instructor_user_approved` sobre `instructor_user_id` donde `active` y `validation_status = 'APPROVED'` (conteo de «especialidades enseñadas»). El nombre de un instructor usuario no se copia: se lee en vivo de `users`.
- `completed_at date` nullable (M5): fecha de **finalización**. `users_honors.date` sigue siendo la fecha de **inicio**. CHECK `users_honors_completed_at_min_ck` (`>= 1960-01-01`; sin cota superior, el «no futuro» lo valida el DTO). Backfill determinista en la migración: copia `date` a `completed_at` solo en filas `APPROVED` enlazadas por `applied_entity_id` a un ítem HONOR `APPROVED` cuyo `completed_at` es igual a `users_honors.date`; el resto (incluido el flujo normal) queda en `NULL`. La aprobación por certificado compara contra `completed_at ?? date`.
- Enviar a revisión exige `completed_at` solo cuando `REQUIRE_HONOR_COMPLETED_AT_ON_SUBMIT` es `true`; hoy es `false` (la base no lo exige nunca).

### `certificate_bulk_import_items` y `certificate_bulk_import_files`

- Items, M1: `instructor_user_id` e `instructor_name` (misma forma y CHECK de exclusividad y de nombre que `users_honors`) más `certificate_bulk_import_items_instructor_honor_ck` (solo filas `HONOR` pueden llevar instructor). Índice parcial `idx_certificate_bulk_items_instructor_user`.
- Items, M2: `source_file_id uuid` (FK a `certificate_bulk_import_files.file_id`, `ON DELETE SET NULL`: es una pista de navegación) y `source_page smallint` (CHECK `>= 1`). Sin CHECK entre ambas (con `SET NULL` bloquearía borrar el archivo) ni tope de páginas en la base (vive en `CERTIFICATE_IMPORT_MAX_PDF_PAGES`). Índice parcial `idx_certificate_bulk_items_source_file`. Solo las escribe el parser OCR; filas manuales o anteriores: `NULL`.
- Files, M2: `page_count smallint` (CHECK `>= 1`), escrito al confirmar (imagen: 1). Archivos anteriores: `NULL`.
- `ocr_state` y `ocr_error_code` **no** son columnas: se derivan de `certificate_bulk_import_item_events` (`OCR_QUEUED`, `OCR_PROCESSED`, `OCR_FAILED`) y del job de BullMQ.
- El borrado de un borrador (`DELETE /certificate-bulk-imports/:batchId`) depende del `ON DELETE CASCADE` de items, files y events hacia el lote; las solicitudes institucionales no cascadean y bloquean el borrado.

### `honor_instructor_proposals` (M4)

Propuesta de instructor sobre una especialidad ya `APPROVED`. `users_honors` no se toca hasta aprobar.

| Columna | Tipo | Notas |
|---|---|---|
| `proposal_id` | `uuid` PK | `gen_random_uuid()` |
| `user_honor_id` | `int` | FK a `users_honors` (`NO ACTION`) |
| `proposed_by_id` | `uuid` | FK a `users`; en v1 siempre el dueño |
| `instructor_user_id` / `instructor_name` | `uuid` / `varchar(150)` | FK a `users`; exactamente uno de los dos |
| `status` | `honor_instructor_proposal_status_enum` | `PENDING` (default), `APPROVED`, `REJECTED`, `WITHDRAWN` |
| `rejection_reason` | `text` | obligatorio y no nulo si `REJECTED` |
| `reviewed_by_id`, `reviewed_at` | `uuid`, `timestamptz` | presentes si y solo si `APPROVED` o `REJECTED` |
| `created_at`, `modified_at` | `timestamptz` | `now()` |

- CHECK: `honor_instructor_proposals_one_instructor_ck` (`(instructor_user_id IS NULL) <> (instructor_name IS NULL)`), `..._name_ck` (3 a 150), `..._review_ck` (revisor y fecha coherentes con el estado) y `..._reason_ck` (`status <> 'REJECTED' OR (rejection_reason IS NOT NULL AND longitud entre 3 y 500)`; el `IS NOT NULL` es explícito porque un `NULL` en el `BETWEEN` dejaría pasar el CHECK).
- Índices: único parcial `uq_honor_instructor_proposals_pending` (`user_honor_id` donde `status = 'PENDING'`, una pendiente por especialidad), `idx_honor_instructor_proposals_queue` (`created_at` donde `PENDING`) e `idx_honor_instructor_proposals_honor` (`user_honor_id, created_at DESC`). Sin `CONCURRENTLY`: la tabla nace vacía y la migración corre con `prisma migrate deploy`.
- Sin `local_field_id` propio: el alcance del revisor sale del Campo Local **actual** del dueño de la especialidad.

### Migraciones de esta sección

| # | Directorio | Contenido |
|---|---|---|
| M1 | `20261010120000_certificate_import_honor_instructor` | `instructor_*` en `certificate_bulk_import_items` y `users_honors`, FK, CHECK e índices parciales (con `CONCURRENTLY`) |
| M2 | `20261010130000_certificate_import_ocr_pages` | `source_file_id`, `source_page`, `page_count`, FK `SET NULL`, CHECK e índice parcial (con `CONCURRENTLY`) |
| M5 | `20261012130000_honors_completed_at` | `users_honors.completed_at`, CHECK >= 1960-01-01 y backfill |
| M4 | `20261013100000_honor_instructor_proposals` | Enum y tabla `honor_instructor_proposals` |

(M3, `detected_instructor_name`, era opcional y no se implementó.)

## Aceptación legal (2026-10-15)

> [!NOTE]
> Tabla nueva en la rama `feat/legal-acceptance` de sacdia-backend, pendiente de merge. Al mergear, la migración corre con `prisma migrate deploy` al final del build en Render. `docs/database/schema.prisma` (espejo) no se actualiza en este cambio y debe resincronizarse al mergear.

### `legal_acceptances`

Evidencia **append-only** de que un usuario aceptó los Términos y Condiciones o el Aviso de Privacidad en una versión concreta (LFPDPPP, revisión de tiendas). El código solo inserta (con `skipDuplicates`); nunca actualiza ni borra filas.

| Columna | Tipo | Nulo | Default | Notas |
|---|---|---|---|---|
| `legal_acceptance_id` | `uuid` | no | `gen_random_uuid()` | PK `legal_acceptances_pkey` |
| `user_id` | `uuid` | no | - | FK a `users.user_id`: quien acepta |
| `document_type` | `varchar(16)` | no | - | CHECK: `terms` o `privacy` |
| `document_version` | `varchar(32)` | no | - | Versión aceptada (por ejemplo `1.0.0-store`) |
| `accepted_at` | `timestamptz(6)` | no | `now()` | Momento de la aceptación |
| `method` | `varchar(32)` | no | - | CHECK: `register_checkbox` o `acceptance_gate` |
| `ip_address` | `varchar(45)` | sí | - | IP de la petición, truncada a 45 |
| `user_agent` | `varchar(512)` | sí | - | User agent de la petición, truncado a 512 |
| `accepted_by_user_id` | `uuid` | sí | - | FK a `users.user_id`: quien aceptó en nombre de otro. Null en la aceptación propia. Con perfiles familiares, el tutor queda aquí cuando acepta por un menor (ver «Perfiles familiares») |
| `created_at` | `timestamptz(6)` | no | `now()` | |

- **CHECK**: `legal_acceptances_document_type_ck` (`document_type IN ('terms', 'privacy')`), `legal_acceptances_method_ck` (`method IN ('register_checkbox', 'acceptance_gate')`) y `legal_acceptances_document_version_ck` (`char_length(btrim(document_version)) BETWEEN 1 AND 32`). Prisma no modela CHECK: solo existen en la migración.
- **Índice único**: `uq_legal_acceptances_user_doc_version` sobre `(user_id, document_type, document_version)`, creado con `CREATE UNIQUE INDEX` y mapeado con `@@unique(map:)`. Sirve las consultas de estado y de exportación, y hace idempotente el `createMany` con `skipDuplicates`. No hay otro índice.
- **FK**: `legal_acceptances_user_id_fkey` y `legal_acceptances_accepted_by_user_id_fkey`, ambas a `users(user_id)` sin cláusula `ON DELETE`/`ON UPDATE` explícita, es decir, el valor por defecto de Postgres `NO ACTION` (igual que `onDelete: NoAction` en Prisma). Los usuarios se anonimizan o desactivan, no se borran, así que nada cascada.
- **Relaciones Prisma**: `legal_acceptance_user` (`users.legal_acceptances`) y `legal_acceptance_accepted_by` (`users.legal_acceptances_given`).
- **Pendiente = ausencia de fila**: un documento está pendiente si no existe fila para `(usuario, tipo, versión vigente)`. Tras revertir una versión, el usuario que ya la había aceptado no vuelve a quedar pendiente.
- **Migración**: `sacdia-backend/prisma/migrations/20261015120000_legal_acceptances/migration.sql`. Escrita a mano (nunca `migrate dev` ni `migrate diff`): `CREATE TABLE IF NOT EXISTS` más un `CREATE UNIQUE INDEX IF NOT EXISTS`, sin `ALTER`, `DROP` ni `CONCURRENTLY`. Solo aditiva. Reversión manual por rama de Neon: eliminar la tabla a mano; no hay migración down. Aplicada en `development` y `staging` (2026-10-21); pendiente en `production` (se aplica en orden con el deploy del backend, ver `docs/deployment/DEPLOYMENT-GUIDE.md`, §0.6).
- **Retención**: IP y user agent se conservan como evidencia del consentimiento mientras la cuenta existe. Al eliminar la cuenta, `AccountDeletionService` los pone en `NULL` dentro de la misma transacción; el historial (documento, versión, fecha y método) se queda en el usuario anonimizado. El aviso de privacidad debe mencionarlo.
- **Exportación**: `DataExportService` incluye las filas del propio usuario como `legal_acceptances` (ver `data-export` en `docs/api/ENDPOINTS-LIVE-REFERENCE.md`).
- **Versiones vigentes**: viven en `sacdia-backend/src/legal/legal-documents.constants.ts`, no en la base de datos (ver `docs/legal/README.md`).

## Perfiles familiares (2026-10-16, actualizado 2026-10-19)

> [!NOTE]
> Fase 2 de perfiles familiares (sacdia-backend, rama `feat/family-profiles`), mergeada (PR #530 de sacdia-backend). La Fase 2 **no añadió migraciones ni cambios de schema después de 2a**: la subida de fichas, la verificación del director y el bloque de admin (sub-fase 2c) usan las tablas y columnas de esta misma migración. La migración `20261016120000_family_profiles` corre con `prisma migrate deploy` al final del build en Render. Aplicada en `development` y `staging` (2026-10-21), con psql y fila en `_prisma_migrations` (flujo de migraciones de Neon); pendiente en `production`, donde la aplica `migrate deploy` con el deploy. `docs/database/schema.prisma` (espejo) ya está resincronizado con esta rama.

Un **dependiente** es un menor de 13 años (el corte depende del país) que tiene un perfil `users` pero ninguna fila `account` ni correo: lo registra un tutor desde la app. El **tutor** actúa por él enviando `X-Acting-For` (ver «Actuar en nombre de un dependiente» en `docs/api/ENDPOINTS-LIVE-REFERENCE.md`). Las tutorías reemplazan a `legal_representatives`, que sigue en el schema y se elimina en la Fase 4.

### `users.email` ahora admite NULL

- `email` pasó de `NOT NULL` a nullable (`String? @unique @db.VarChar(100)` en Prisma). Es la única sentencia de la migración que altera una tabla existente fuera de `countries`.
- El `UNIQUE` se mantiene: Postgres permite muchas filas con `NULL`. Los dependientes se crean con `email = NULL`.
- Efectos en código: verificación de correo, envío de correos, tarjeta QR (cae al nombre de la sección o del club), soporte y listados de admin toleran `null`. El token de acceso lleva `email: null` para estos perfiles.

### `countries`: política de edad

Tres columnas nuevas, añadidas con `ADD COLUMN IF NOT EXISTS`:

| Columna | Tipo | Nulo | Default | Notas |
|---|---|---|---|---|
| `minor_self_login_min_age` | `smallint` | no | `13` | Edad mínima para tener cuenta propia. Por debajo se crea un dependiente. CHECK `countries_minor_self_login_min_age_ck`: entre 0 y 21 |
| `age_of_majority` | `smallint` | no | `18` | Edad en que se deja de ser menor. CHECK `countries_age_of_majority_ck`: entre 14 y 21 |
| `age_reference_timezone` | `varchar(64)` | sí | - | Zona IANA cuyo calendario decide «hoy» al calcular edades. Null usa `America/Mexico_City` |

- Si el usuario no tiene país, o el país no existe, el código usa 13 / 18 / `America/Mexico_City` (`CountryAgePolicyService`). La política se cachea 1 hora (`cache:catalogs:country_age_policy:{id}`) y se invalida al actualizar el país desde admin.
- Un dependiente nuevo toma el `country_id` del tutor.

### `dependent_profiles`

Identidad explícita de un dependiente: una fila por menor sin cuenta, con su ciclo de congelación y purga.

| Columna | Tipo | Nulo | Default | Notas |
|---|---|---|---|---|
| `user_id` | `uuid` | no | - | PK `dependent_profiles_pkey` y FK a `users.user_id` |
| `created_by_user_id` | `uuid` | no | - | FK a `users.user_id`: quien lo registró. Un tutor (desde «Mi familia»), el propio adolescente al canjear su código (Fase 3a) o, desde la Fase 3c, el **director** que lo creó en su sección. La regla de cuatro ojos de custodia lee esta columna |
| `created_at` | `timestamptz(6)` | no | `now()` | |
| `frozen_at` | `timestamptz(6)` | sí | - | Se llena cuando el último tutor sale y no hay club que lo custodie |
| `purge_after` | `timestamptz(6)` | sí | - | `frozen_at` + 90 días |
| `purged_at` | `timestamptz(6)` | sí | - | Momento en que el cron de purga anonimizó el perfil |
| `teen_login_nudged_at` | `timestamptz(6)` | sí | - | Fase 3c. Marca de que ya se avisó a los tutores de que el menor llegó a la edad de acceso propio. `NULL` = nunca avisado. Sin default; ver «Registro por director y acceso familiar (Fase 3c)» |

- **CHECK**: `dependent_profiles_frozen_ck` exige `(frozen_at IS NULL) = (purge_after IS NULL)`.
- **Índice parcial** `idx_dependent_profiles_purge` sobre `(purge_after) WHERE frozen_at IS NOT NULL AND purged_at IS NULL`: lo recorre el cron de purga.
- Relaciones Prisma: `dependent_profile_user` (1:1 con `users.dependent_profile`) y `dependent_profile_creator`.

### `guardianships`

Quién responde por un dependiente. Una fila por tutor (o por custodia de un club) y dependiente; las filas revocadas se conservan como historial.

| Columna | Tipo | Nulo | Default | Notas |
|---|---|---|---|---|
| `guardianship_id` | `uuid` | no | `gen_random_uuid()` | PK `guardianships_pkey` |
| `dependent_user_id` | `uuid` | no | - | FK a `users.user_id`: el menor |
| `guardian_user_id` | `uuid` | sí | - | FK a `users.user_id`: el tutor. Null en custodia de club y en tutores externos heredados |
| `is_custodian` | `boolean` | no | `false` | Custodia del club (el tutor se fue y el menor tiene membresía) |
| `custodian_club_id` | `integer` | sí | - | FK a `clubs.club_id`: obligatorio si `is_custodian` |
| `relationship_type_id` | `uuid` | sí | - | FK a `relationship_types`. Sin restricción en la base: el servicio solo acepta los nombres de `GUARDIAN_RELATIONSHIP_TYPE_NAMES` (ver `docs/features/family-profiles.md`, «Parentesco del tutor») |
| `is_primary` | `boolean` | no | `false` | Tutor principal: el que puede quitar a un secundario |
| `consent_status` | `varchar(16)` | no | `'pending'` | `pending`, `verified` o `revoked` |
| `sworn_declaration_at` | `timestamptz(6)` | sí | - | Cuando el tutor juró serlo |
| `invited_by_guardianship_id` | `uuid` | sí | - | FK a `guardianships`: la tutoría de quien emitió el código con que entró |
| `verified_by_user_id` | `uuid` | sí | - | FK a `users.user_id`: quién verificó el consentimiento |
| `verification_method` | `varchar(32)` | sí | - | `director_paper_form`, `coordinator_paper_form`, `guardian_invite`, `legacy_import` o `test_placeholder` |
| `verified_at` | `timestamptz(6)` | sí | - | |
| `revoked_at` | `timestamptz(6)` | sí | - | |
| `revoked_reason` | `varchar(32)` | sí | - | `guardian_left`, `removed_by_primary`, `guardian_account_closed`, `claimed`, `admin` o `released` (Fase 3a: también `removed_by_dependent`) |
| `external_name` | `varchar(150)` | sí | - | Tutor sin cuenta (solo importación desde `legal_representatives`) |
| `external_phone` | `varchar(20)` | sí | - | |
| `is_test_data` | `boolean` | no | `false` | Filas de prueba: nunca cuentan como consentimiento ni dan acceso |
| `created_at` | `timestamptz(6)` | no | `now()` | |
| `modified_at` | `timestamptz(6)` | no | `now()` | `@updatedAt` en Prisma |

- **CHECK**:
  - `guardianships_consent_status_ck`, `guardianships_verification_method_ck` y `guardianships_revoked_reason_ck` fijan los valores de arriba (los dos últimos admiten NULL). El CHECK de `verification_method` admite `coordinator_paper_form` desde la migración `20261024120000_allow_coordinator_paper_form` (**aplicada en `development` y `staging`** (2026-10-21), pendiente en `production`; ver «Quién escribe `verified`»).
  - `guardianships_holder_ck`: una fila es de custodia (`is_custodian`, sin `guardian_user_id`, con `custodian_club_id`) o de persona (sin club y con `guardian_user_id` o `external_name`).
  - `guardianships_not_self_ck`: nadie es su propio tutor.
  - `guardianships_revoked_ck`: `(consent_status = 'revoked') = (revoked_at IS NOT NULL)`.
  - `guardianships_verified_ck`: `verified` exige `verified_at`.
- **Índices únicos parciales** (solo existen en la migración):
  - `uq_guardianships_active_pair` sobre `(dependent_user_id, guardian_user_id)` donde hay tutor y `consent_status <> 'revoked'`: un tutor activo una sola vez por menor.
  - `uq_guardianships_active_primary` sobre `(dependent_user_id) WHERE is_primary AND consent_status <> 'revoked'`: un solo principal activo.
  - `uq_guardianships_active_custodian` sobre `(dependent_user_id) WHERE is_custodian AND consent_status <> 'revoked'`: una sola custodia activa.
- **Índices no únicos**: `idx_guardianships_dependent` (declarado en Prisma con `@@index`), y los parciales `idx_guardianships_guardian_active` (`guardian_user_id` sin revocadas) e `idx_guardianships_custodian_club` (`custodian_club_id` en custodias activas).
- Relaciones Prisma: `guardianship_dependent`, `guardianship_guardian`, `guardianship_verifier`, `guardianships_custodian` (en `clubs`), `guardianship_invites` (autorreferencia) y la inversa en `relationship_types.guardianships`.
- **Activa** significa `consent_status IN ('pending','verified')`. Solo las filas activas, no de custodia ni de prueba cuentan para acceso, límites y notificaciones. Límites aplicados en servicio: 10 dependientes activos por tutor y 4 tutores activos por dependiente.
- **Quién da acceso**: solo `pending` y `verified` de una persona con cuenta **activa** (`users.active`; un tutor eliminado o desactivado no actúa aunque su fila siga). `revoked`, custodia, tutor externo e `is_test_data` no dan acceso.
- **Quién escribe `verified`**: `POST .../membership-requests/:assignmentId/verify-consent` lo fija sobre la tutoría **principal** activa (de persona o de custodia): `coordinator_paper_form` si quien verifica llegó por la vía del coordinador (rol global de coordinador con `consent:verify` y una `coordinator_assignment` vigente que cubre la sección) y `director_paper_form` en cualquier otro caso (director, o un rol de club con solo `consent:verify`). Si el coordinador además tiene autoridad de club en esa misma sección (por ejemplo, es director o secretario de ella), el permiso lo cubre su rol de club, `coordinatorSectionGrant` queda en `false` y se guarda `director_paper_form`. La columna es `varchar(32)`, pero el CHECK `guardianships_verification_method_ck` (creado en `20261016120000_family_profiles`) solo admitía `director_paper_form`, `guardian_invite`, `legacy_import` y `test_placeholder`. La migración `20261024120000_allow_coordinator_paper_form` (rama `feat/coordinator-pending-consents`, commit `74f5412c`) lo amplía con `coordinator_paper_form`; **hay que aplicarla a Neon antes de desplegar el backend de esa rama**, porque sin ella el `UPDATE` de una verificación por coordinador falla. Está **aplicada en `development` y `staging`** (2026-10-21), pendiente en `production` (ver «`20261024120000_allow_coordinator_paper_form`»). Las filas verificadas antes de ese cambio (rama `feat/coordinator-pending-consents`) siguen como `director_paper_form`. `guardian_invite` lo reciben los tutores invitados por una fila que se verifica (promoción en cadena). `legacy_import` y `test_placeholder` solo los escribe el script de desarrollo. Una custodia de club se verifica con la regla de cuatro ojos (el que subió la ficha, el que creó al menor y el tutor que lo dejó en custodia no pueden verificarla).
- **Datos del tutor externo**: al purgar al menor, `external_phone` se anula siempre. `external_name` se anula en las filas de custodia o con `guardian_user_id`, pero en una fila de titular externo (no custodia y sin `guardian_user_id`) se **sobrescribe con el marcador `'Tutor'`** (`PURGED_GUARDIAN_NAME`, `src/guardianships/guardianships.constants.ts`), porque `guardianships_holder_ck` exige un `external_name` en esa fila y anularlo hacía fallar la purga con el error 23514 (corregido en el commit `9533895d`, rama `fix/approve-status-and-device-refresh-pg`, pendiente de merge).

### `guardianship_consent_evidences`

Historial append-only de la ficha de consentimiento firmada (imagen o PDF). La ficha cuelga de la **tutoría principal activa** del menor (la fila de consentimiento, de persona o de custodia), la suben el tutor (cualquier tutor activo) o el director y la lee el tutor, el director o un admin con URL firmada de 15 minutos. El bucket es privado: `GUARDIANSHIP_EVIDENCE` (`R2_BUCKET_GUARDIANSHIP_EVIDENCE`; sin él los endpoints de ficha responden 503). Contrato de endpoints en `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, sección `guardianships`.

| Columna | Tipo | Nulo | Default | Notas |
|---|---|---|---|---|
| `evidence_id` | `uuid` | no | `gen_random_uuid()` | PK `guardianship_consent_evidences_pkey` |
| `guardianship_id` | `uuid` | no | - | FK a `guardianships` |
| `file_key` | `varchar(512)` | no | - | Clave del objeto en el bucket privado `GUARDIANSHIP_EVIDENCE` |
| `content_type` | `varchar(64)` | no | - | CHECK: `image/jpeg`, `image/png`, `image/webp` o `application/pdf` |
| `size_bytes` | `integer` | no | - | CHECK: entre 1 y 10485760 (10 MB) |
| `uploaded_by_user_id` | `uuid` | no | - | FK a `users.user_id`: quien subió de verdad (tutor o director). |
| `uploaded_at` | `timestamptz(6)` | no | `now()` | |
| `superseded_at` | `timestamptz(6)` | sí | - | Se llena cuando una subida nueva reemplaza a esta. El objeto en R2 **se conserva** (historial legal) |
| `purged_at` | `timestamptz(6)` | sí | - | Reservada. La purga de un dependiente borra la fila entera, no la marca |

- **Índice único parcial** `uq_guardianship_consent_evidences_current` sobre `(guardianship_id) WHERE superseded_at IS NULL AND purged_at IS NULL`: una sola evidencia vigente por tutoría.
- Relación Prisma: `consent_evidence_uploader` (`users.guardianship_consent_evidences_uploaded`).
- La purga de un dependiente borra las filas y sus objetos en R2 (decisión A9); la tutoría queda para auditoría.
- **Clave del objeto**: `{prefijo}/{guardianship_id}/{uuid}.{ext}` con prefijo `R2_KEY_PREFIX_GUARDIANSHIP_EVIDENCE` (por defecto `guardianships/consent`); la extensión sale del tipo MIME validado, nunca del nombre original.
- **Auditoría**: cada subida y cada lectura escriben un evento `guardianship_consent_evidence` (`uploaded` o `read`, `changes.via` = `guardian`, `director` o `admin`) en `audit_logs`; la verificación escribe `guardianship` / `consent_verified` dentro de su transacción, con `changes.verification_method` igual al valor de la fila (`director_paper_form` o `coordinator_paper_form`; en este último el resumen dice «verificado por el coordinador»).

### `guardianship_link_codes`

Códigos de vinculación de un solo uso. Solo se guarda el hash.

| Columna | Tipo | Nulo | Default | Notas |
|---|---|---|---|---|
| `link_code_id` | `uuid` | no | `gen_random_uuid()` | PK `guardianship_link_codes_pkey` |
| `code_hash` | `char(64)` | no | - | HMAC-SHA256 hex del código normalizado. `UNIQUE` `guardianship_link_codes_code_hash_key` |
| `dependent_user_id` | `uuid` | no | - | FK a `users.user_id` |
| `purpose` | `varchar(24)` | no | - | CHECK: `second_guardian` o `director_claim` (Fase 3a: también `teen_guardian_link`; ver «Cuentas supervisadas (Fase 3a)») |
| `issued_by_user_id` | `uuid` | no | - | FK a `users.user_id`: tutor o director que lo emitió |
| `issued_for_club_section_id` | `integer` | sí | - | FK a `club_sections`: obligatorio solo en `director_claim` |
| `expires_at` | `timestamptz(6)` | no | - | CHECK `expires_at > created_at`. 72 h en `second_guardian`, 7 días en `director_claim` |
| `consumed_at` | `timestamptz(6)` | sí | - | |
| `consumed_by_user_id` | `uuid` | sí | - | FK a `users.user_id` |
| `revoked_at` | `timestamptz(6)` | sí | - | Un código nuevo revoca los abiertos del mismo (dependiente, propósito) |
| `created_at` | `timestamptz(6)` | no | `now()` | |

- **CHECK**: `guardianship_link_codes_purpose_ck`, `guardianship_link_codes_consumed_ck` (`consumed_at` y `consumed_by_user_id` van juntos), `guardianship_link_codes_section_ck` (`director_claim` si y solo si hay sección) y `guardianship_link_codes_expiry_ck`.
- **Índice parcial** `idx_guardianship_link_codes_dependent_open` sobre `(dependent_user_id, purpose) WHERE consumed_at IS NULL AND revoked_at IS NULL`.
- El código en claro (8 caracteres Crockford base32, `XXXX-XXXX`) sale del servidor una sola vez, en la respuesta de emisión. El hash usa una clave HKDF derivada de `BETTER_AUTH_SECRET`; no hay variable de entorno nueva.
- Relaciones Prisma: `link_code_dependent`, `link_code_issuer`, `link_code_consumer` y la inversa en `club_sections.guardianship_link_codes`.

### Reglas de datos

- **Sin copia de datos en la migración.** `legal_representatives` no se migra. El script opcional `sacdia-backend/scripts/family-profiles/seed-dev-guardianships.ts` solo es para ramas de desarrollo: por defecto es simulacro, y con `--apply` más `--placeholders` o `--from-legal-reps` escribe filas `is_test_data` o `legacy_import`. Se ejecuta a mano por rama de Neon y se niega a correr con `NODE_ENV=production`.
- **Aceptación legal del menor**: al crear un dependiente se insertan sus filas en `legal_acceptances` con `method = 'register_checkbox'`, `user_id` = el menor y `accepted_by_user_id` = el tutor. El CHECK de `method` no cambia.
- **Estados de un dependiente** cuando el último tutor sale (voluntariamente o por cierre de cuenta): pasa a otro tutor activo (el más antiguo se vuelve principal si hace falta), o a custodia del club si tiene una asignación `active` o `pending` (fila `is_custodian`), o se congela (`frozen_at = now()`, `purge_after = now() + 90 días`).
- **Aceptaciones hechas por un tutor**: cuando el tutor elimina su cuenta se anulan `ip_address` y `user_agent` de las filas de `legal_acceptances` donde `user_id` es el tutor **o** `accepted_by_user_id` es el tutor, porque las aceptaciones en nombre del menor llevan la IP y el dispositivo del tutor. Se hace en la misma transacción de la eliminación, después de ceder los menores.
- **Purga** (cron `dependent-profiles-purge`, `20 4 * * *` UTC, lotes de 100; decisión A9: «borrar» es borrar):
  1. **Una transacción**: anonimiza la fila `users` (`active = false` y `email`, nombre, apellidos, `birthday`, `blood`, `gender`, `baptism_date`, `user_image`, `country_id`, `union_id` y `local_field_id` en NULL); borra con `DELETE` alergias, enfermedades, medicinas, contactos de emergencia, filas de `guardianship_consent_evidences`, `evidence_files` de clases y especialidades, `requirement_evidence` y `notification_deliveries` (la bandeja del menor); vacía las columnas de archivo de `users_honors` (`certificate = ''`, `document = NULL`, `images = []`); anula `external_phone` de sus `guardianships` y `external_name` salvo en las filas de titular externo, donde queda el marcador `'Tutor'`; anula IP y user agent en sus `legal_acceptances`; fija `dependent_profiles.purged_at`; y sube el `epoch` de acting-for.
  2. **Después de confirmar, R2**, por bucket: fichas de consentimiento (`GUARDIANSHIP_EVIDENCE`), foto de perfil (`USER_PROFILES`), evidencias de clases (`CLASS_EVIDENCE`), evidencias de requisitos de especialidades que no sean enlaces (`EVIDENCE_FILES`), y certificado, documento e imágenes de las especialidades del menor (`USERS_HONORS_CERT` / `USERS_HONORS`, o `CERTIFICATE_IMPORTS` cuando el objeto salió de una carga por certificado). Las claves se leen antes de la transacción (viven en filas que esta borra o vacía); el borrado va tras confirmarla, con mejor esfuerzo por bucket: si R2 falla, la purga **no** se revierte ni se reintenta (`purged_at` ya está fijado y las claves ya no están en la base), y se registra el evento `dependent_purge_storage_cleanup_failed` con el bucket y las claves para limpiar los huérfanos a mano (commit `9533895d`; antes se borraba R2 primero y un fallo de la transacción dejaba los archivos borrados y los datos en la base).
  3. **Se conserva**: la fila `users` anonimizada, las filas de `guardianships` (quién lo tuvo a cargo, sin datos de contacto del tutor externo), `dependent_profiles` y las filas de progreso de clases y especialidades, sin ningún archivo.
- **Migración**: `sacdia-backend/prisma/migrations/20261016120000_family_profiles/migration.sql`. Escrita a mano, 17 sentencias en una sola transacción: 4 `ALTER TABLE` (`users.email DROP NOT NULL` y las 3 columnas de `countries`), 4 `CREATE TABLE IF NOT EXISTS` y 9 índices (3 únicos parciales de `guardianships`, 1 único parcial de evidencias, 1 parcial de `dependent_profiles`, 1 de dependiente, 2 parciales más de `guardianships` y 1 parcial de códigos). Todas las FK usan la acción por defecto `NO ACTION`. Sin `DROP`, `DELETE`, `INSERT`, `UPDATE` ni `CONCURRENTLY`; el guard `src/guardianships/family-profiles.migration.spec.ts` lo comprueba y solo admite `ALTER TABLE users ALTER COLUMN email DROP NOT NULL`. Reversión manual por rama de Neon; no hay migración down.
- **Particularidad de Prisma**: los índices únicos parciales y los parciales no caben en `@@index`/`@@unique`; `schema.prisma` los documenta en un comentario y la migración es la fuente. No ejecutar `prisma format`.

## Cuentas supervisadas (Fase 3a)

> [!NOTE]
> Fase 3a de perfiles familiares (sacdia-backend, rama `feat/family-profiles-phase3`), mergeada (PR #531 de sacdia-backend). Describe el schema **implementado** en la rama. Migración: `sacdia-backend/prisma/migrations/20261020120000_family_teen_login/migration.sql`, escrita a mano y que se aplica a mano a la rama `development` de Neon con psql (flujo de migraciones de Neon; **nunca** `prisma migrate dev`, el shadow DB no sirve). **Aplicada** (tarea T3a-B05, hecha): la migración se aplicó a la rama `development` de Neon con aprobación del usuario y se verificó con `prisma migrate status`. También en `staging` (2026-10-21); pendiente en `production`. `docs/database/schema.prisma` (espejo) se resincroniza al mezclar. Contrato de endpoints: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, «Cuentas supervisadas de 13 a 17 años (Fase 3a)».

Un **adolescente con cuenta supervisada** es un usuario con fila `account`, con edad desde la edad mínima de cuenta del país y menor que su mayoría de edad. No hay columna «es adolescente»: la edad se calcula en cada petición con la política del país (`CountryAgePolicyService`, zona horaria del país). El modo pendiente de tutor también se **deriva** (no se guarda): la ausencia de una tutoría `verified`, de persona (no custodia) y real.

### `supervised_logins`

Una fila por adolescente con cuenta (o con acceso habilitado por un tutor). Es la fuente del nombre de usuario, del método de acceso, del reloj de 90 días y de los recordatorios.

| Columna | Tipo | Nulo | Default | Notas |
|---|---|---|---|---|
| `user_id` | `uuid` | no | - | PK `supervised_logins_pkey` y FK a `users.user_id` |
| `method` | `varchar(8)` | no | - | `email` o `handle` |
| `login_handle` | `varchar(40)` | sí | - | Nombre de usuario generado por el servidor. Obligatorio si `method = 'handle'` y nulo si es `email` |
| `origin` | `varchar(16)` | no | - | `self_registered` (el adolescente se registró) o `guardian_enabled` (lo habilitó un tutor) |
| `enabled_by_guardianship_id` | `uuid` | sí | - | FK a `guardianships`: la tutoría con que se habilitó el acceso o con que se vinculó el primer tutor |
| `enabled_by_user_id` | `uuid` | sí | - | FK a `users.user_id`: el tutor |
| `enabled_at` | `timestamptz(6)` | sí | - | |
| `password_set_by` | `varchar(8)` | no | - | `guardian` o `self` |
| `pending_since` | `timestamptz(6)` | sí | - | Inicio del reloj de 90 días sin tutor. Null cuando hay un tutor de persona activo (aunque esté pendiente de verificación) |
| `pending_reminder_level` | `smallint` | no | `0` | Recordatorios enviados: 0 ninguno, 1 a los 7 días, 2 a los 30, 3 a los 83 |
| `disabled_at` | `timestamptz(6)` | sí | - | |
| `disabled_by_user_id` | `uuid` | sí | - | FK a `users.user_id`: el tutor o el admin que lo deshabilitó. Null si lo hizo el sistema |
| `disabled_reason` | `varchar(24)` | sí | - | `guardian`, `admin` o `unlinked_purged` (Fase 3b: la base también admite `age_majority`, reservado y sin uso por decisión del 2026-10-20: ver abajo) |
| `created_at` | `timestamptz(6)` | no | `now()` | |
| `modified_at` | `timestamptz(6)` | no | `now()` | `@updatedAt` en Prisma |

- **CHECK**: `supervised_logins_method_ck`, `supervised_logins_origin_ck` y `supervised_logins_password_set_by_ck` fijan los valores de arriba. `supervised_logins_handle_ck`: `(method = 'handle') = (login_handle IS NOT NULL)`. `supervised_logins_handle_format_ck`: `login_handle ~ '^[a-z0-9][a-z0-9-]{5,39}$'`. `supervised_logins_guardian_enabled_ck`: `origin = 'guardian_enabled'` exige `enabled_by_guardianship_id`, `enabled_by_user_id` y `enabled_at`. `supervised_logins_reminder_ck`: `pending_reminder_level` entre 0 y 3. `supervised_logins_disabled_ck`: `(disabled_at IS NULL) = (disabled_reason IS NULL)`. `supervised_logins_disabled_reason_ck`: `guardian`, `admin`, `unlinked_purged` y, desde la migración de la Fase 3b, `age_majority`.
- **Índices** (solo en la migración; los parciales y de expresión no caben en `@@index`/`@@unique`): `uq_supervised_logins_handle` único sobre `(lower(login_handle)) WHERE login_handle IS NOT NULL` (el nombre de usuario es único sin distinguir mayúsculas) e `idx_supervised_logins_pending` sobre `(pending_since) WHERE pending_since IS NOT NULL AND disabled_at IS NULL` (lo recorre el cron `pending-teen-guardian`).
- **FK**: todas con la acción por defecto `NO ACTION` (sin `ON DELETE`). Relaciones Prisma con nombre: `supervised_login_user` (1:1, inversa `users.supervised_login`), `supervised_login_enabler`, `supervised_login_disabler` y `supervised_login_guardianship`.
- **Semántica de las filas**:
  - Adolescente que se registra solo: `origin = self_registered`, `method = email`, `password_set_by = self`, `pending_since = now`. La fila se crea en el registro cuando llega una fecha de 13 a 17 años (el registro guarda `birthday` y `country_id` desde `9f83891d`; `AuthService.register`, `src/auth/auth.service.ts:211-268`) o, sin fecha, cuando el paso 2 del post-registro la guarda (`UsersService.afterBirthdayChanged`, idempotente). Una cuenta propia **sin** fecha de nacimiento y con el post-registro abierto no tiene fila: es `age_unknown_user` (restringida; `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, «Edad desconocida»).
  - Al canjear el código del adolescente: se llenan `enabled_by_*` y `enabled_at`, `pending_since = NULL`, nivel 0 (el reloj se detiene aunque el vínculo siga pendiente).
  - Acceso habilitado por un tutor: `origin = guardian_enabled`, `method = email` o `handle`, `password_set_by = guardian`.
  - Sale el último tutor de un adolescente con cuenta: `pending_since = now`, nivel 0 (no se congela).
  - A los 90 días sin tutor: `disabled_at = now`, `disabled_reason = unlinked_purged` y el cron congela el perfil.
  - La mayoría de edad **no** se guarda: la edad se calcula por petición.
- **Invariante** (prueba de consistencia): un titular de cuenta con fila en `dependent_profiles` tiene siempre una fila `supervised_logins`. Un adolescente con cuenta menor de edad **sin** fila se trata como pendiente (falla cerrada); el script `scripts/family-profiles/backfill-supervised-logins.ts` (solo desarrollo, simulacro por defecto, `--apply` para escribir) crea las filas `self_registered` de los titulares de 13 a 17 años existentes (con tutoría: `pending_since = NULL`; sin ella: `pending_since = now()`, de modo que el reloj de 90 días arranca al desplegar y no al registrarse).
- **Particularidad de `dependent_profiles`**: para un adolescente con cuenta, la fila se crea **al canjear el código del adolescente** (`created_by_user_id` = el propio adolescente) o al congelarlo por el plazo de 90 días (`frozen_at = now`, `purge_after = now + 90 días`, igual que un dependiente). Un adolescente con cuenta no se congela cuando sale su último tutor: vuelve al modo pendiente.

### `guardianship_link_codes.purpose` y `guardianships.revoked_reason`: dos reemplazos de CHECK

La migración es aditiva salvo estos dos reemplazos, que **solo amplían** los valores (nunca los restringen, así que no dejan filas huérfanas). Cada uno es un par `DROP CONSTRAINT IF EXISTS` + `ADD CONSTRAINT` que el guard de la migración permite de forma explícita, solo para ese nombre.

| Constraint | Antes | Ahora |
|---|---|---|
| `guardianship_link_codes_purpose_ck` | `second_guardian`, `director_claim` | `second_guardian`, `director_claim`, `teen_guardian_link` (18 caracteres, cabe en `varchar(24)`) |
| `guardianships_revoked_reason_ck` | `guardian_left`, `removed_by_primary`, `guardian_account_closed`, `claimed`, `admin`, `released` | los anteriores y `removed_by_dependent` (el adolescente quita un vínculo pendiente que él inició) |

- `guardianship_link_codes_section_ck` (`director_claim` si y solo si hay sección) **no cambia** y sigue siendo válido para el propósito nuevo (sin sección). El código `teen_guardian_link` lo emite el adolescente: `issued_by_user_id` = `dependent_user_id` = el adolescente; vigencia 72 h; un código nuevo revoca los abiertos del mismo (dependiente, propósito).
- Una tutoría creada al canjear `teen_guardian_link` es no custodia, principal, `pending`, con `invited_by_guardianship_id` NULL y `sworn_declaration_at` lleno; nunca se verifica sola.

### Migración 20261020120000_family_teen_login

- **7 sentencias**: 1 `CREATE TABLE IF NOT EXISTS supervised_logins`, 2 `CREATE INDEX IF NOT EXISTS` (los dos de arriba) y 2 pares `DROP CONSTRAINT IF EXISTS` + `ADD CONSTRAINT` (los dos reemplazos). Sin DML, sin `DROP` de objetos de datos, sin `RENAME`, `TRUNCATE`, `CONCURRENTLY`, `BEGIN`/`COMMIT` ni `ON DELETE`/`ON UPDATE`. La tabla `sessions` **no se toca** (la sesión de un adolescente es una sesión normal).
- **Guard**: `src/guardianships/family-profiles-phase3.migration.spec.ts` (precedente `family-profiles.migration.spec.ts`): quita comentarios, comprueba la lista permitida (el número de sentencias coincide con el real), aplica la lista de prohibiciones de la Fase 2, verifica que los dos CHECK nuevos sean superconjuntos de los anteriores, incluye casos negativos (`DROP TABLE guardianships`, `UPDATE users`, `INSERT`, `TRUNCATE`, `BEGIN`, un `purpose` sin `director_claim`, `DROP` de `guardianship_link_codes_section_ck`), comprueba el modelo en el DMMF y los nombres de índice, y que aplicarla dos veces sea idempotente (por patrón).
- **Aplicación**: a mano con psql a la rama `development` de Neon, dos veces para probar la idempotencia, y luego fila en `_prisma_migrations`. Nunca a producción desde este flujo (producción se actualiza al promover). Reversión manual por rama de Neon; no hay migración down. El rollback preferido es apagar la bandera `FAMILY_TEEN_LOGIN_ENABLED` (ver `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, «Banderas de configuración»; apagarla bloquea los inicios de sesión por nombre de usuario y corta en la siguiente petición las sesiones ya abiertas, sin borrarlas; volver a encenderla las restaura); revertir el PR deja la tabla sin uso.
- **Sin variable de entorno nueva de datos**: las tres banderas (`FAMILY_TEEN_LOGIN_ENABLED`, `FAMILY_LINKED_DEVICE_ENABLED`, `FAMILY_DIRECTOR_CREATE_MINOR_ENABLED`, por defecto `false`) están en `config/env.validation.ts` (`src/config/env.validation.ts:237-`).
- **Purga de un adolescente con cuenta** (cron `dependent-profiles-purge`, mismo pipeline que un dependiente congelado): además de lo de «Perfiles familiares», borra la credencial y las filas OAuth de `accounts`, las filas `verifications`, las sesiones y los tokens FCM, deja en `NULL` el correo y los datos personales y conserva la fila `users` anonimizada. El correo queda libre para reutilizarse.

## Dispositivos vinculados (Fase 3b)

> [!NOTE]
> Fase 3b de perfiles familiares (sacdia-backend, rama `feat/family-profiles-phase3`, commits `f31c24cb..1054af7a`), mergeada (PR #531 de sacdia-backend). Describe el schema **implementado** en la rama. Migración: `sacdia-backend/prisma/migrations/20261021120000_family_linked_devices/migration.sql`, escrita a mano. **Aplicada a la rama `development` de Neon el 2026-10-20 con aprobación del usuario** (tarea T3b-B04): `psql` con `ON_ERROR_STOP` en una transacción, registro en `_prisma_migrations` y verificación con `prisma migrate status` (al día). Antes de aplicarla ninguna de las dos tablas existía, la última migración era `20261020120000_family_teen_login` y 0 filas de `supervised_logins` violaban el CHECK nuevo; después, `linked_devices` tiene 9 constraints y `device_pairing_tokens` 8. Aplicada también en `staging` (2026-10-21); **pendiente en `production`**: llega al promover `development` → preproducción → `main` (Render corre `prisma migrate deploy` al final del build). La aplicación a Neon la hizo el orquestador del backend; esta referencia la registra tal como se informó y no se volvió a comprobar contra la base al escribirla. `docs/database/schema.prisma` (espejo) se resincroniza al mezclar. Contrato de endpoints: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, «Dispositivo vinculado de menores de 13 años (Fase 3b)».

Un **dispositivo vinculado** es el teléfono de un menor sin cuenta: tiene una sesión propia (fila normal de `sessions`) y una fila `linked_devices` que la nombra. Una sesión es de dispositivo **solo** si una fila `linked_devices` tiene su `session_id`; `sessions` no cambia.

### `linked_devices`

| Columna | Tipo | Nulo | Default | Notas |
|---|---|---|---|---|
| `linked_device_id` | `uuid` | no | `gen_random_uuid()` | PK `linked_devices_pkey` |
| `dependent_user_id` | `uuid` | no | - | FK a `users.user_id`: el menor |
| `guardianship_id` | `uuid` | no | - | FK a `guardianships.guardianship_id`: la tutoría con que se emparejó. La compuerta exige que siga `verified`, no custodia, no de prueba y no revocada |
| `paired_by_user_id` | `uuid` | no | - | FK a `users.user_id`: el tutor que creó el token |
| `session_id` | `text` | no | - | Id de la sesión del dispositivo en `sessions`. **Sin FK** (ver abajo) |
| `label` | `varchar(60)` | no | - | Nombre del teléfono que manda el propio dispositivo (el servicio lo limpia a 40 caracteres como máximo, sin caracteres de control ni `<` `>`; por defecto `Dispositivo`) |
| `platform` | `varchar(16)` | no | - | `ios` o `android` |
| `app_version` | `varchar(32)` | sí | - | |
| `fcm_token_id` | `uuid` | sí | - | Id del token FCM que registró el dispositivo (`user_fcm_tokens.fcm_token_id`). **Sin FK**: la fila del token puede desaparecer sin tocar el historial del dispositivo |
| `paired_at` | `timestamptz(6)` | no | `now()` | |
| `absolute_expires_at` | `timestamptz(6)` | no | - | Tope absoluto: `paired_at + 180 días`. El refresh nunca lo supera |
| `last_seen_at` | `timestamptz(6)` | sí | - | Se escribe como máximo cada 5 minutos |
| `revoked_at` | `timestamptz(6)` | sí | - | |
| `revoked_by_user_id` | `uuid` | sí | - | FK a `users.user_id`: quien desvinculó. Nulo si lo hizo el sistema (ciclo de vida, compuerta, el propio dispositivo) |
| `revoked_reason` | `varchar(32)` | sí | - | Ver el CHECK |

- **FK**: las cuatro con la acción por defecto `NO ACTION` (sin `ON DELETE`): `linked_devices_dependent_user_id_fkey`, `linked_devices_guardianship_id_fkey`, `linked_devices_paired_by_user_id_fkey` y `linked_devices_revoked_by_user_id_fkey`.
- **CHECK**: `linked_devices_platform_ck` (`ios` o `android`); `linked_devices_expiry_ck` (`absolute_expires_at > paired_at`); `linked_devices_revoked_ck` (`(revoked_at IS NULL) = (revoked_reason IS NULL)`: sin motivo no hay revocación y al revés); `linked_devices_revoked_reason_ck`: `guardian`, `guardianship_revoked`, `guardian_account_closed`, `teen_login_enabled`, `majority`, `dependent_frozen`, `device_logout`, `session_revoked`, `admin` o `expired`.
- **Índices** (solo en la migración; el único y los parciales no caben en `@@index`/`@@unique` de Prisma): `uq_linked_devices_session` único sobre `(session_id)`; `idx_linked_devices_dependent_active` sobre `(dependent_user_id) WHERE revoked_at IS NULL` (cuenta del tope de dos dispositivos); `idx_linked_devices_guardianship_active` sobre `(guardianship_id) WHERE revoked_at IS NULL` (revocar por tutoría).
- **Por qué `session_id` no tiene FK** (decisión de diseño ADR-4): las filas de `sessions` se borran físicamente al cerrar sesión, al cambiar la contraseña y en todo camino de revocación; una FK con `NO ACTION` rompería esos borrados, y una con `CASCADE` borraría el historial del dispositivo. Por eso la relación Prisma no existe (`session_id String` plano) y la unión se hace a mano (`BetterAuthService.findLinkedDeviceOfSession`, `SessionsService`). Tampoco hay `ALTER` de `sessions`.
- **Relaciones Prisma con nombre**: en `users`, `linked_device_dependent`, `linked_device_pairer` y `linked_device_revoker` (campos `linked_devices_as_dependent`, `linked_devices_paired`, `linked_devices_revoked`); en `guardianships`, `linked_device_guardianship` (campo `linked_devices`).
- **Semántica**: máximo **2 dispositivos activos** por menor (`revoked_at IS NULL`; se hace cumplir en el servicio bajo el candado por dependiente, no con una restricción de la base). Una revocación escribe `revoked_at`, `revoked_reason` y `revoked_by_user_id` con compare-and-set sobre `revoked_at IS NULL` (una revocación doble no cambia nada ni duplica la auditoría). Quién escribe cada motivo y qué dispara la revocación: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, «Cuándo se revoca un dispositivo (motivos)».

### `device_pairing_tokens`

El token de un solo uso que un tutor verificado crea para emparejar el teléfono (lo lleva el QR). Solo se guarda su HMAC.

| Columna | Tipo | Nulo | Default | Notas |
|---|---|---|---|---|
| `pairing_token_id` | `uuid` | no | `gen_random_uuid()` | PK `device_pairing_tokens_pkey` |
| `token_hash` | `char(64)` | no | - | HMAC-SHA256 en hexadecimal del token (clave HKDF derivada de `BETTER_AUTH_SECRET`, `info = sacdia:device-pairing-token`). UNIQUE (`device_pairing_tokens_token_hash_key`). El token en claro no se guarda |
| `dependent_user_id` | `uuid` | no | - | FK a `users.user_id` |
| `guardianship_id` | `uuid` | no | - | FK a `guardianships.guardianship_id`: la tutoría del tutor que lo creó |
| `created_by_user_id` | `uuid` | no | - | FK a `users.user_id`: el tutor |
| `expires_at` | `timestamptz(6)` | no | - | `created_at + 10 minutos` |
| `consumed_at` | `timestamptz(6)` | sí | - | |
| `consumed_device_id` | `uuid` | sí | - | FK a `linked_devices.linked_device_id`: el dispositivo que lo canjeó |
| `revoked_at` | `timestamptz(6)` | sí | - | Lo marca un token nuevo del mismo menor |
| `created_at` | `timestamptz(6)` | no | `now()` | |

- **FK**: las cuatro con `NO ACTION`: `device_pairing_tokens_dependent_user_id_fkey`, `..._guardianship_id_fkey`, `..._created_by_user_id_fkey` y `..._consumed_device_id_fkey`.
- **CHECK**: `device_pairing_tokens_consumed_ck` (`(consumed_at IS NULL) = (consumed_device_id IS NULL)`) y `device_pairing_tokens_expiry_ck` (`expires_at > created_at AND expires_at <= created_at + interval '15 minutes'`; el servicio usa 10 minutos y la base no admite más de 15).
- **Índice** (solo en la migración): `idx_device_pairing_tokens_open` sobre `(dependent_user_id) WHERE consumed_at IS NULL AND revoked_at IS NULL`.
- **Orden de escritura al canjear**: primero se crea la fila de `linked_devices` y después se consume el token con compare-and-set; el CHECK `consumed_ck` y la FK `consumed_device_id` obligan a ese orden.
- Relaciones Prisma con nombre: `pairing_token_dependent`, `pairing_token_creator`, `pairing_token_guardianship` y `pairing_token_device` (en `users`: `pairing_tokens_as_dependent` y `pairing_tokens_created`; en `guardianships`: `pairing_tokens`).

### `supervised_logins.disabled_reason`: `age_majority` (reemplazo del CHECK diferido de la 3a)

La migración incluye el reemplazo del CHECK `supervised_logins_disabled_reason_ck` que la verificación 3a (W5) dejó diferido para la 3b: `DROP CONSTRAINT IF EXISTS` + `ADD CONSTRAINT` que **solo amplía** los valores (nunca los restringe, así que no deja filas huérfanas).

| Constraint | Antes | Ahora |
|---|---|---|
| `supervised_logins_disabled_reason_ck` | `guardian`, `admin`, `unlinked_purged` | `guardian`, `admin`, `unlinked_purged`, `age_majority` (reservado, sin uso) |

Decisión del 2026-10-20 (FP3-16, opción A): **ningún código escribe `age_majority`**. Al llegar a la mayoría de edad el principal se calcula por la edad en cada petición (deja de ser `supervised_user`, se acaba la supervisión y el tutor pierde facultades y avisos) y la fila de `supervised_logins` no se toca, para que el acceso propio siga funcionando: una fila con `disabled_at` bloquearía el inicio de sesión, y un acceso con nombre de usuario (sin correo) dejaría al adulto sin su cuenta. El valor queda en el CHECK, reservado. La prueba de inventario `supervised-logins.disabled-reason.inventory.spec.ts` lo permite.

### Migración 20261021120000_family_linked_devices

- **8 sentencias**: 2 `CREATE TABLE IF NOT EXISTS` (`linked_devices`, `device_pairing_tokens`), 4 `CREATE INDEX IF NOT EXISTS` (uno único y tres parciales) y 1 par `DROP CONSTRAINT IF EXISTS` + `ADD CONSTRAINT` (el CHECK de arriba). Sin DML, sin `DROP` de objetos de datos, sin `CONCURRENTLY` ni `BEGIN`/`COMMIT`. **`sessions` no se toca.** El guard `src/guardianships/family-profiles-phase3.migration.spec.ts` (bloque 3b) comprueba la lista permitida, la lista de prohibiciones, casos negativos, el DMMF de los dos modelos y que el CHECK nuevo sea superconjunto del anterior.
- **Validación previa**: aplicada dos veces sobre una base PGlite en memoria con cada CHECK y cada restricción única ejercitados (informe del backend); la aplicación real a Neon `development` está arriba.
- **Reversión**: manual por rama de Neon; no hay migración down. Las dos tablas y sus índices se pueden borrar a mano; el CHECK ampliado puede quedarse. El rollback preferido es apagar `FAMILY_LINKED_DEVICE_ENABLED` (por defecto `false`; ver `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, «Bandera `FAMILY_LINKED_DEVICE_ENABLED`»): corta toda petición de dispositivo con 401 sin tocar la base y, al volver a encenderla, los dispositivos activos funcionan de nuevo. **Cambiar la bandera en un servidor desplegado exige reiniciarlo.**
- **Sin variable de entorno nueva de datos**: la clave de los tokens se deriva de `BETTER_AUTH_SECRET` con HKDF.

### Retención y purga

La purga del menor (`dependent-profiles-purge`, servicio `DependentProfilesPurgeCronService`; commit `a8af9091`) corre en la misma transacción que el resto de la limpieza y hace lo siguiente con estas dos tablas:

- **Revoca** los dispositivos que sigan activos (`revokeAllForDependent` con motivo `dependent_frozen`); si el menor ya estaba congelado, repetir la revocación no cambia nada.
- **Borra** todos los tokens FCM del menor (`user_fcm_tokens`).
- **Borra** todas las filas de `device_pairing_tokens` del menor (tokens de un solo uso, guardados solo como hash, sin valor de auditoría).
- **Anonimiza** todas las filas de `linked_devices` del menor: `label` se sobrescribe con la constante `PURGED_DEVICE_LABEL` (`'Dispositivo'`; la columna es `NOT NULL`, por eso no se anula), y `app_version` y `fcm_token_id` pasan a `NULL`.

Las filas de `linked_devices` **no** se borran: quedan como registro de qué teléfonos se vincularon y cuándo. Tras la purga siguen en cada fila `platform`, `paired_by_user_id`, `revoked_by_user_id`, el motivo de revocación y las fechas; el texto libre que escribió el menor o su tutor ya no está. La decisión A9 («borrar» es borrar) queda cubierta para el texto libre y los tokens; conservar las filas de dispositivo como auditoría sin datos personales sigue siendo una decisión de producto sin entrada en `docs/audit/DECISIONS-PENDING.md`.

## Registro por director y acceso familiar (Fase 3c)

> Fase 3c de perfiles familiares (sacdia-backend, rama `feat/family-profiles-phase3`, commit `cf3d6ce2`), mergeada (PR #531 de sacdia-backend). Describe el schema **implementado** en la rama. Dos migraciones escritas a mano (sin `prisma migrate dev`; el shadow DB no sirve) y **aplicadas a la rama `development` de Neon el 2026-10-20 con aprobación del usuario** (tarea T3c-B05): `psql --single-transaction`, **dos veces cada una** (idempotentes), registradas en `_prisma_migrations` con su checksum sha256 y verificadas. Con estas dos, las **cuatro** migraciones de la Fase 3 están aplicadas en `development` y `staging` (2026-10-21); `production` sigue pendiente y llega con la promoción. Esta referencia registra lo informado por el orquestador del backend y no se volvió a comprobar contra la base al escribirla. `docs/database/schema.prisma` (espejo) se resincroniza al mezclar. Contrato: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, «Registro de menores por un director y acceso familiar en el panel (Fase 3c)».

### `20261022120000_family_director_minors`

Una sola sentencia, aditiva y re-ejecutable (el resto del archivo son comentarios; sin DML, sin default ni cambios de constraints):

```sql
ALTER TABLE dependent_profiles ADD COLUMN IF NOT EXISTS teen_login_nudged_at timestamptz(6);
```

- `dependent_profiles.teen_login_nudged_at` (`timestamptz(6)`, nullable, sin default; modelo Prisma `DateTime? @db.Timestamptz(6)`). La escribe el cron `family-age-transitions`: reclama la marca con un compare-and-set (`WHERE teen_login_nudged_at IS NULL`) **antes** de enviar el aviso del cumpleaños 13, así dos instancias no avisan dos veces; si todos los envíos fallan la marca se libera a `NULL`. Un menor sin tutor verificado se omite y queda en `NULL`.
- **No se añadió columna de creador**: `dependent_profiles.created_by_user_id` ya existía desde la Fase 2.
- **Verificación aplicada en `development`**: la columna existe, es `timestamptz` y admite NULL.
- Reversión manual por rama de Neon: la columna puede quedarse sin uso o borrarse a mano. No hay migración down.

### `20261022130000_seed_family_permissions`

Solo DML (precedente: `20260823190000_seed_audit_read_permission`). Cada `INSERT` lleva `ON CONFLICT`, así que aplicarla dos veces no cambia nada:

- `permissions`: `dependents:create` y `consent:verify` (`ON CONFLICT (permission_name) DO UPDATE` de descripción y `active`).
- `role_permissions` (`ON CONFLICT (role_id, permission_id) DO NOTHING`, uniendo solo roles y permisos activos):

| Permiso | Rol | Categoría |
| --- | --- | --- |
| `dependents:create` | `director`, `deputy-director` | CLUB |
| `consent:verify` | `director`, `deputy-director`, `secretary`, `secretary-treasurer` | CLUB |
| `dependents:create` y `consent:verify` | `admin`, `assistant-admin`, `super-admin` | GLOBAL (explícito: una migración no puede apoyarse en los comodines de los seeds) |

- **Esta migración no** otorga `consent:verify` a `coordinator`, `zone-coordinator` ni `general-coordinator` (ni a `assistant-lf`, que ya verifica por `club_members:approve`); los coordinadores lo reciben en la migración `20261023120000_grant_consent_verify_to_coordinators` (sección siguiente). El motivo original: `PermissionsGuard` no resuelve su territorio sobre recursos de sección (limitación B11 explicada en `docs/api/ENDPOINTS-LIVE-REFERENCE.md`). Las mismas filas viven entre las marcas `-- BEGIN family permissions (phase 3c)` y `-- END family permissions (phase 3c)` de `prisma/seeds/permissions.seed.sql` y `prisma/seeds/role-permissions.seed.sql` (al final de la transacción del seed, después de los bloques de cada rol); el guard `family-profiles-phase3.migration.spec.ts` comprueba que migración y seeds coinciden, que solo hay `INSERT` a esas dos tablas, que no hay `DELETE` y que cada `INSERT` tiene `ON CONFLICT`.
- **Resultado en `development`**: **10** asignaciones de rol (no 12 como en las bases de las pruebas): `dependents:create` a director y subdirector de club y a `admin` y `super-admin`; `consent:verify` a director, subdirector, secretario y secretario-tesorero de club y a `admin` y `super-admin`. La rama `development` de Neon **no tiene el rol `assistant-admin`** (solo `admin` y `super-admin`) y la migración une únicamente roles activos que existen, así que es lo esperado.
- Reversión: las filas se pueden borrar a mano (`DELETE` en `role_permissions` y luego en `permissions`); no hay migración down.

### `20261023120000_grant_consent_verify_to_coordinators`

Solo DML (precedente: `20261022130000_seed_family_permissions`), rama `feat/coordinator-consent-verify` de sacdia-backend, **aplicada en `development` y `staging`** (2026-10-21), pendiente en `production`. No crea el permiso (`consent:verify` lo creó la migración anterior); solo añade filas de `role_permissions`:

| Permiso | Rol | Categoría |
| --- | --- | --- |
| `consent:verify` | `coordinator`, `zone-coordinator`, `general-coordinator` | GLOBAL |

- `INSERT ... SELECT gen_random_uuid(), r.role_id, p.permission_id` con `ON CONFLICT (role_id, permission_id) DO NOTHING`, uniendo solo roles con `role_category = 'GLOBAL'` y `active = true` y el permiso activo. Aplicarla dos veces no cambia nada. Un `role_permissions` ya existente pero inactivo no se reactiva (igual que en la migración anterior).
- Las mismas filas viven en `prisma/seeds/role-permissions.seed.sql`, entre las marcas `-- BEGIN coordinator consent:verify` y `-- END coordinator consent:verify`, **después** de los bloques `DELETE` + `INSERT` de cada rol de coordinador (esos bloques borran todas las filas del rol y las reinsertan, así que cualquier permiso extra se reafirma después) y dentro de la transacción del seed.
- Solo concede el permiso. Que un coordinador lo use en una sección depende de la guardia, no de esta tabla: ver `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, «Revisor solo-verificación». No se le da `club_members:approve` ni `dependents:create`.
- Aplicada en `development` y `staging` (2026-10-21); falta aplicarla en `production`. No hay un recuento de filas nuevas registrado (depende de los roles activos que existan en cada rama). Tras aplicarla, un coordinador debe ver `consent:verify` en `/auth/me`.
- Reversión: `DELETE` manual de esas tres filas de `role_permissions`; no hay migración down.

### `20261024120000_allow_coordinator_paper_form`

Escrita a mano, solo DDL, rama `feat/coordinator-pending-consents` de sacdia-backend (migración en el commit `74f5412c`; el servicio que deriva `viaCoordinator` de `coordinatorSectionGrant`, en `7130542e`). **Aplicada en `development` y `staging`** (2026-10-21), pendiente en `production`; hay que aplicarla a Neon **antes** de desplegar ese backend.

- Hace `DROP CONSTRAINT` y `ADD CONSTRAINT` de `guardianships_verification_method_ck`, que pasa a admitir `director_paper_form`, `coordinator_paper_form`, `guardian_invite`, `legacy_import` y `test_placeholder`. Sigue admitiendo NULL. Se puede volver a ejecutar sin efecto.
- No toca datos: las filas ya verificadas siguen como `director_paper_form`.
- Reversión: solo hacia adelante. Mientras no haya filas con `coordinator_paper_form`, se puede restaurar el CHECK anterior; cuando ya existen, quitar el valor del CHECK falla (o exige reescribir esas filas), así que se corrige con otra migración.
- Validada el 2026-10-21 contra Postgres real en la rama temporal de Neon `qa-coord-20261021`: con la migración aplicada, un `verify-consent` de coordinador (`approve: false`) devolvió y guardó `coordinator_paper_form`; el evento `consent_verified` quedó con el resumen «Consentimiento del tutor verificado por el coordinador» y `changes.verification_method = coordinator_paper_form`, y la solicitud siguió `pending`.

### Filas que crea el registro por director

No añade tablas ni columnas. Por cada menor registrado por un director (`POST /club-sections/:clubSectionId/dependents`) el servicio escribe, en una transacción: `users` (sin `email`; `country_id` del club de la sección), `users_pr`, `users_roles` (rol `user`), `dependent_profiles` (`created_by_user_id` = el director), una fila de `guardianships` de **custodia** (`guardian_user_id` NULL, `is_custodian`, `custodian_club_id` = club principal de la sección, `is_primary`, `consent_status = pending`, `sworn_declaration_at`), una `club_role_assignments` con `status = 'pending'` (nunca `active`), dos filas de `legal_acceptances` con `accepted_by_user_id` = el director y una fila de `audit_logs` (`entity_type = dependent`, `action = created_by_director`). No hay fila en `account`.

Si la solicitud de ese menor vence sin tutor (`expireStaleRequests`), la fila de `dependent_profiles` pasa a `frozen_at = now` y `purge_after = now + 90 días` (el CHECK `dependent_profiles_frozen_ck` se cumple) y el cron `dependent-profiles-purge` hace el resto a los 90 días.

## Modelos añadidos a esta referencia (resincronización 2026-10-04)

Resumen por grupo de modelos que ya estaban en el schema de `development` y faltaban en esta página.

### Historia institucional (`institutional_*`, `*_history`, `hierarchy_contexts`)

Migraciones `20260527120000_institutional_hierarchy_history`, `20260527193000_closed_output_hierarchy_snapshots` y `20260723120000_institutional_history_foundation`. Código de dominio en `sacdia-backend/src/institutional-history/` (sin controller propio).

- `institutional_reorganizations` — reorganización institucional (`type`, `effective_on`, `description`, `authority_source` default `WORLD_CHURCH_EXECUTIVE`, `idempotency_key` único, `approved_by`). `corrects_reorganization_id` enlaza una corrección con la reorganización corregida.
- `institutional_reorganization_participants` — participantes de una reorganización: una entidad entre división, unión, campo local, distrito, iglesia o club.
- `institutional_lineage_edges` — aristas de linaje entre participantes (`from_participant_id` → `to_participant_id`, `relation_type`).
- `institutional_name_versions` y `institutional_name_version_translations` — nombres y abreviaturas versionados por vigencia (`valid_from`/`valid_to`) y por registro (`recorded_from`/`recorded_to`), con `supersedes_name_version_id` y `reorganization_id` opcional.
- `union_division_history`, `local_field_union_history`, `district_local_field_history`, `church_district_history` y `club_institutional_history` — pertenencia jerárquica con vigencia y bitemporalidad (`valid_*`, `recorded_*`, `supersedes_*`, `precision` default `system_backfill`).
- `hierarchy_contexts` — snapshot de la cadena jerárquica a una fecha (`as_of`, `source`, `context` JSON). Lo referencian `enrollment_rankings` y `section_rankings` para congelar el contexto de salidas cerradas.

### Autorización

- `authorization_context_versions` — una fila por usuario (`user_id` PK, `version BIGINT`). `AuthorizationContextVersionService` (`src/common/authorization/`) la incrementa dentro de la transacción que cambia asignaciones o geografía, para invalidar el contexto de autorización cacheado. Migración `20260730150000_authorization_temporal_context`.

### Camporees (personal, participantes externos, plantillas y sedes)

- `camporee_staff_members` y `camporee_event_staff_assignments` — roster operativo y asignaciones por evento (ver la sección de camporees del inventario).
- `camporee_external_participants` — participante externo sin cuenta (`full_name`, `role_type`, `role_description?`, `active`), ligado a un camporee local o de unión. Puede ser sujeto de `insurance_assignments`. Migración `20260723120000_insurance_capacity_model`.
- `camporee_event_templates`, `camporee_event_template_rubrics` y `camporee_venues` — plantillas reutilizables de eventos y sedes.

### Materiales (`material_*`)

Modelos Prisma en PascalCase mapeados a tablas snake_case: `MaterialCategory` (`material_categories`), `MaterialProduct` (`material_products`), `MaterialVariant` (`material_variants`), `MaterialVariantOption` (`material_variant_options`), `MaterialOrder` (`material_orders`), `MaterialOrderLine` (`material_order_lines`), `MaterialComprobante` (`material_comprobantes`), `MaterialFolioCounter` (`material_folio_counters`) y `MaterialConfig` (`material_config`). Módulo `src/materials`.

### Importación de certificados y solicitudes institucionales

- `certificate_bulk_import_batches`, `certificate_bulk_import_items`, `certificate_bulk_import_files` y `certificate_bulk_import_item_events` — lotes de importación masiva, archivos privados (OCR) y bitácora por ítem.
- `institutional_certificate_requests` e `institutional_certificate_request_events` — bandeja institucional de solicitudes de certificado (migración `20260921190000_institutional_certificate_requests`).
- Desde 2026-10-13, instructor opcional, archivo y página de origen en los ítems y `page_count` en los archivos: ver «Instructor de especialidad, fecha de finalización y carga por certificado».

### Reportes, operación y cuentas

- `quarterly_reports` y `annual_reports` — reportes trimestral y anual.
- `cron_run_log` y `cron_alerts_log` — ejecuciones y alertas de cron jobs (`/admin/analytics/cron-runs`).
- `data_export_requests` — solicitudes de exportación de datos (R2 `data-exports`).
- `account_deletion_log` — bitácora de eliminación de cuentas.
- `notification_deliveries` — entregas por usuario para bandeja y conteo de no leídas.

### i18n

27 modelos `*_translations` (por ejemplo `countries_translations`, `honors_translations`, `classes_translations`, `club_ideals_translations`). Cada tabla guarda traducciones distintas de `es` con `UNIQUE (<fk>, locale)`.

## Correcciones anteriores

### `users`

- Incluye `email_verified`, `approval_status` y `rejection_reason`.
- Mantiene `access_app`, `access_panel`, `country_id`, `union_id`, `local_field_id`.
- Ya no usa los flags legacy `apple_connected`, `fb_connected` ni `google_connected`.
- `email` admite NULL desde `20261016120000_family_profiles` (dependientes sin correo). Sigue `UNIQUE`. Ver «Perfiles familiares».

### `users_pr`

- Incluye `active_club_assignment_id` ademas del tracking de post-registro.
- No existe tabla dedicada para credenciales QR: el contrato canónico nuevo usa JWT stateless y, por ahora, solo `users_pr`/`club_role_assignments` para resolver contexto visual y autorizacion.

### `club_sections`

- Es la estructura vigente para secciones de club.
- Cada club tiene una fila por tipo de catálogo activo (`club_types`); no tiene nombre propio. La etiqueta visible es `{clubs.name} · {club_types.name}`.
- `active` indica si el club opera esa sección. Unirse, post-registro, camporee y QR solo usan secciones activas.
- Incluye datos operativos propios (`phone`, `email`, `website`, `logo_url`, `address`, `lat`, `long`).
- La unicidad vigente es `@@unique([main_club_id, club_type_id])`.

### `club_inventory`: condición y campos extendidos (Pendiente de merge)

Migración `20261026130000_inventory_extended_fields` (backend, rama `fix/inventory-extended-fields`, Pendiente de merge). Aditiva y compatible con el código anterior: las filas existentes quedan con `condition = 'bueno'` y `NULL` en el resto, sin backfill. Aplicada en Neon `development` (2026-10-26); pendiente en `staging` y `production` (ver `docs/deployment/DEPLOYMENT-GUIDE.md` §0.7).

| Columna | Tipo | Nulabilidad / default |
|---|---|---|
| `condition` | `VARCHAR(10)` | `NOT NULL DEFAULT 'bueno'` |
| `serial_number` | `VARCHAR(100)` | `NULL` |
| `purchase_date` | `DATE` | `NULL` |
| `estimated_value` | `DECIMAL(12,2)` | `NULL` |
| `location` | `VARCHAR(150)` | `NULL` |
| `assigned_to` | `VARCHAR(150)` | `NULL` (texto libre, no FK) |
| `notes` | `TEXT` | `NULL` |

CHECK constraints (solo en la base; Prisma no los modela):

- `club_inventory_condition_check`: `condition IN ('bueno', 'regular', 'malo')`.
- `club_inventory_estimated_value_check`: `estimated_value IS NULL OR estimated_value >= 0`.

Los cambios de estos campos se auditan por campo en `inventory_history`. Contrato y reglas de validación: `docs/features/inventario.md`.

### `club_role_assignments`

- La relacion operativa es contra `club_section_id`.
- Incluye `expires_at` y `rejection_reason`.
- La unicidad vigente es `@@unique([user_id, role_id, club_section_id, ecclesiastical_year_id, start_date])`.
- `status` (`varchar(20)`): `pending`, `active`, `rejected`, `expired` (membership requests); `designated` es **legado** (director futuro previo a T2; no crear filas nuevas); `ended` (cargo cerrado, p. ej. destitución o corte de año); `inactive` (`active=true`) representa pertenencia **no inscrita** del año de la fila, no autorización. La directiva activa esa misma fila al inscribir. No reescribir un cargo `ended` para simular el retorno.
- Índice único parcial `uniq_cra_director_status_section_year` (migración `20260908180000_director_year_slots`; Prisma no lo expresa): `(club_section_id, ecclesiastical_year_id, role_id, status) WHERE active = true AND status IN ('active', 'designated') AND role_id = <uuid del rol CLUB director>`. Garantiza a lo sumo un director operativo y un designado por sección+año (el mismo `role_id` con `status` distinto no choca). No aplica a otros roles de club.
- Índice único parcial `uniq_cra_annual_member_section_year` (migración `20260909120000_annual_membership_cycle`): `(user_id, club_section_id, ecclesiastical_year_id) WHERE active = true AND status IN ('active', 'inactive') AND role_id = <uuid del rol CLUB member> AND club_section_id IS NOT NULL`. Una membresía anual equivalente por usuario/sección/año. Duplicados existentes bloquean la migración; no se borran automáticamente.

### `director_succession_plans`

- Programación privada del director del periodo siguiente. `outgoing_assignment_id` es nullable para permitir sección vacante.
- Unicidad abierta: índice parcial `uniq_director_succession_open_section_year` (migración `20260909130000_director_succession_open_unique`) `(club_section_id, target_ecclesiastical_year_id) WHERE status IN ('scheduled','activated','blocked')`. Un plan cancelado no bloquea reprogramar. No crea CRA `designated`.
- Idempotencia de alta: único `(scheduled_by_id, idempotency_key)` + `request_hash`.

### `club_year_transitions`

- Ledger único `(club_id, ecclesiastical_year_id)` del corte anual por club (`pending` / `in_progress` / `completed` / `failed`). Escritura de aplicación restringida a `YearCutService`. No sustituye el lock Redis del cron. Migración `20260909120000_annual_membership_cycle` aplicada a Neon development (2026-09-11).

### `class_counselor_assignments`

- Modela la responsabilidad pedagógica anual de una clase progresiva por `user_id + club_section_id + class_id + ecclesiastical_year_id`.
- Se vincula opcionalmente al `club_role_assignment_id` activo que sustenta la asignación operativa del usuario en esa sección/año.
- `responsibility_type` acepta `primary`, `assistant` o `substitute`.
- `exceptional` + `exception_reason` documentan el caso extraordinario de segunda clase asignada a la misma persona.
- Restricciones vigentes:
  - asignación activa única por `(user_id, club_section_id, class_id, ecclesiastical_year_id)`;
  - máximo 1 `primary` activo por `(club_section_id, class_id, ecclesiastical_year_id)`;
  - trigger DB limita a 3 responsables activos por clase/sección/año;
  - trigger DB limita a 2 clases activas por persona/sección/año y exige justificación para la segunda.

### Coordinación institucional

- `coordination_zones` modela zonas creadas por campo local para agrupar distritos.
- `coordination_zone_districts` asocia distritos a zonas y mantiene una unicidad activa por distrito para evitar doble cobertura operativa.
- `coordinator_assignments` define autoridad real con `assignment_type` (`GENERAL`, `ZONE`, `SECTION`):
  - `GENERAL`: un coordinador general activo por campo local.
  - `ZONE`: un coordinador por zona + `club_type_id`.
  - `SECTION`: un coordinador directo por `club_section_id`.
- La unidad final de autorización sigue siendo `club_sections`; el backend debe resolver el alcance efectivo como `club_section_ids`.
- La incompatibilidad director/coordinador sobre la misma `club_section` se valida en servicio, porque depende de roles activos en `club_role_assignments`.

### `weekly_records`, `weekly_record_scores` y `scoring_categories`

- `weekly_records` materializa `unit_id`, usuario, semana domingo–sábado (hora México), total de puntos, `created_by` y `active` por `unit_id + user_id + week + year`. `attendance` y `punctuality` quedan como columnas legacy de compatibilidad y no son fuente del total.
- Índice de acceso por usuario/año/semana: `idx_weekly_records_user_year_week` `(user_id, year, week)` — cubre MoM y scores de carpeta anual.
- `weekly_record_scores` guarda el desglose por categoria con unicidad `(record_id, category_id)`.
- `scoring_categories` define categorias heredadas o propias por `origin_level` + `origin_id`, con `scoring_mode` (`numeric` o `boolean_full`) para decidir si acepta valores intermedios o solo todo/nada.

### Índices de rendimiento (2026-08-18)

Migración `20260818190000_query_performance_indexes` (btree `CONCURRENTLY` + GIN `pg_trgm`). Cierra sequential scans en filtros/búsqueda.

| Tabla | Índice | Uso |
| --- | --- | --- |
| `investiture_validation_history` | `(enrollment_id, created_at)`, `(action, created_at)`, parcial `INVESTIDO` | SLA dashboard / throughput |
| `weekly_records` | `(user_id, year, week)` | MoM, scores de asistencia/uso |
| `honors` | `(active, honors_category_id, name)`, `(club_type_id, active)` | catálogo agrupado |
| `clubs` | `church_id`, `(districlub_type_id, active)`, `(active, name)`, GIN `name` | listado/filtro/ILIKE |
| `churches` / `districts` / `local_fields` | FK + `active` | joins de geografía |
| `emergency_contacts` | `(owner_id, active)` | CRUD por dueño |
| `insurance_evidence_files` | purchase / assignment / uploaded_by | lookup de evidencias |
| `accounts` | `user_id` | Better Auth por usuario |
| `resources` / `finances` / `support_reports` / `material_products` | GIN trigram en texto | `contains` / ILIKE |
| `enrollments` | `(ecclesiastical_year_id, investiture_status, active)`; parcial `(status, submitted_at) WHERE active`; parcial único regular y cruzado `(user_id, ecclesiastical_year_id) WHERE active AND record_kind = OPERATIONAL` | validación por año + overdue SLA + cursado cruzado GM; el histórico por certificado no ocupa cupo |
| `club_role_assignments` | `(ecclesiastical_year_id, active, status)`; único parcial `uniq_cra_director_status_section_year` (rol director CLUB, `active`+`designated` por sección+año) | dashboard de personas; un director operativo y un designado por sección/año |
| `activities` | `created_by`, `created_at DESC`, `(created_by, activity_date)` | listado y scores |
| `annual_folders` | `status`; `(status, modified_at DESC)` | colas de evaluación |
| `folders` | `ecclesiastical_year_id` | scores de evidencias |
| `weekly_records` | btree + parcial `WHERE active` | MoM / scores |
| `camporee_events` | GIN `title`; `(camporee_id, day, starts_at, display_order)` | listado/`q` |
| `union_camporee_local_fields` | `(local_field_id, active)` | listas de union camporee por campo |

Los GIN/parciales no caben en `@@index` de Prisma; el SQL de la migración es la fuente de esas formas. Los btree sí están declarados en `prisma/schema.prisma`.

### `member_of_month`

- Persiste ganadores por `club_section_id`, `month` y `year`; admite empates porque la unicidad incluye `user_id`.
- Incluye `total_points` y `notified` para el tracking de notificaciones.

### `master_honors` y requisitos configurables

- `master_honors` ahora incluye:
  - `applicability_scope` (`ALL` o `SELECTED_DIVISIONS`).
  - `philosophy` y `notes` para contexto explicativo.
  - Relación inversa explícita a `master_honor_evaluation_history[]` para trazabilidad.
- Nuevos modelos asociados a reglas, estado y trazabilidad:
  - `master_honor_divisions`
  - `master_honor_requirement_groups`
  - `master_honor_requirement_options`
  - `master_honor_requirement_option_honors`
  - `users_master_honors`
  - `master_honor_evaluation_history`
- `users` ahora expone:
  - `users_master_honors[]` (estado de maestrías).
  - `master_honor_evaluation_history[]` (evento de cambios de estado).
- `divisions` ahora también expone `awarded_users_master_honors[]` para relacionar maestrías otorgadas por división.
- `honors`, `honors_categories`, `master_honors` y `divisions` incorporan relaciones necesarias para configurar y evaluar maestrías por reglas y por división.
- El espejo documental declara `divisions` para resolver las nuevas relaciones de maestrías; la tabla ya existía en el schema efectivo del backend.
- Semántica vigente:
  - Solo cuentan especialidades de usuario con `users_honors.validation_status = APPROVED` y `users_honors.active = true`.
  - `users_master_honors.status = AWARDED` se presenta como `Vigente`.
  - `users_master_honors.status IN (REVOKED, RETIRED)` se presenta como `No vigente` y conserva historial visible.
  - `users_master_honors.awarded_division_id` guarda la división histórica usada para el primer otorgamiento; la reevaluación usa esa división histórica cuando el registro ya existe.
  - `master_honor_evaluation_history.evaluation_snapshot` documenta qué grupos, opciones y especialidades contaron en cada cambio.
  - `honors.master_honors_id` no es fuente de verdad para requisitos configurables; se conserva como relación legacy/catálogo mientras el evaluador usa las tablas de reglas.

### `users_honors` y modo de finalizacion

- `users_honors.validation_status` sigue siendo la fuente canonica del estado de revision (`IN_PROGRESS`, `PENDING_REVIEW`, `APPROVED`, `REJECTED`).
- `users_honors.completion_mode` define el camino de trabajo de la especialidad inscrita con default `UNDECIDED`.
- Valores vigentes de `honor_completion_mode_enum`:
  - `UNDECIDED` — honor inscrito sin camino elegido; bloquea submit de honores editables.
  - `IN_APP` — requisitos, respuestas y evidencia puntual dentro de la app.
  - `EXTERNAL` — formato completado en `document` + evidencias generales; no depende del checklist para submit.
- `users_honors.document` representa el formato completado en modo externo. `users_honors.images` conserva evidencias generales legacy/actuales con limite runtime de 10 imagenes totales.
- `requirement_evidence` conserva evidencias puntuales por requisito para el modo `IN_APP`.
- Desde 2026-10-13: `completed_at` (finalización), `instructor_user_id` e `instructor_name`; una fila `PENDING_REVIEW` o `APPROVED` no se reescribe desde la API (ver «Instructor de especialidad, fecha de finalización y carga por certificado»).

### `honors`, aplicabilidad y clases

- `honors.code` es el identificador estable del catalogo para imports y sincronizaciones. Es nullable durante el rollout, pero cuenta con unicidad para los registros que lo usan.
- `honor_club_types` modela la disponibilidad/eligibilidad activa de una especialidad por tipo de club (`honor_id`, `club_type_id`, `active`), con unicidad `@@unique([honor_id, club_type_id])`.
- `class_honors` modela la relacion curricular entre una clase y una especialidad (`class_id`, `honor_id`, `relation_type`, `module_id?`, `active`), con unicidad `@@unique([class_id, honor_id, relation_type])`. `module_id` ancla la especialidad a un módulo de la misma clase (`ON DELETE SET NULL`). En runtime las relaciones son informativas (no bloquean módulo ni investidura), incluso `REQUIRED`.
- `class_prerequisites` modela prerrequisitos explicitos entre clases (`class_id`, `prerequisite_class_id`, `active`), con unicidad `@@unique([class_id, prerequisite_class_id])` y CHECK anti-auto-referencia. Cumplido = enrollment del usuario con `investiture_status = INVESTIDO` en la clase prerequisito (cualquier ano). Aditivo a `classes.requires_invested_gm`.
- `classes.requires_invested_gm` es un flag por clase, no por tipo de club. La clase de entrada `Guía Mayor` debe quedar en `false`; las clases GM posteriores (Avanzado, Instructor) pueden exigir un enrollment `INVESTIDO` en cualquier clase de Guías Mayores. Error runtime: `CLASS_GM_INVESTITURE_REQUIRED`.
- `class_honor_relation_type_enum` permite clasificar el vínculo como `REQUIRED`, `RECOMMENDED` o `ELECTIVE`.
- `honors.club_type_id` se conserva como compatibilidad legacy durante el rollout. Los filtros nuevos de catalogo deben usar `honor_club_types`.
- Las especialidades de Aventureros importadas usan `honors_categories.name = 'Aventureros'` solo como categoria tecnica de compatibilidad cuando el campo de categoria es requerido; la relacion con clases vive en `class_honors`.

### `monthly_reports` y `monthly_report_manual_data`

- `monthly_reports` usa `monthly_report_id` UUID y relacion obligatoria a `club_enrollments.club_enrollment_id` (tambien UUID).
- La unicidad vigente es `@@unique([club_enrollment_id, month, year])`.
- El estado es `String` con default `draft`; el runtime backend verificado usa `draft`, `generated` y `submitted`.
- `snapshot_data` es `Json?` y guarda el snapshot congelado del preview auto-calculado.
- `submitted_by` referencia `users.user_id` y permite identificar al submitter cuando el informe pasa a `submitted`.
- El PDF canónico privado se referencia con un bloque de metadatos nullable y completo: `pdf_r2_key VARCHAR(512)`, `pdf_size_bytes BIGINT`, `pdf_sha256 CHAR(64)`, `pdf_generated_at TIMESTAMPTZ(6)` y `pdf_template_version VARCHAR(32)`.
- `monthly_reports_pdf_metadata_complete_chk` exige que los cinco campos estén todos vacíos o todos presentes; cuando existen, el tamaño debe ser positivo y el checksum debe ser SHA-256 hexadecimal minúsculo.
- `idx_monthly_reports_pdf_template_version` permite seleccionar artefactos ausentes o desactualizados para reparación/backfill.
- `monthly_report_manual_data` es one-to-one por `monthly_report_id` (`@unique`) y se elimina en cascada si se elimina el informe padre.
- Los campos manuales vigentes son administrativos, misioneros y de seguimiento; no coinciden con algunos payloads legacy de clientes.

### `system_config`

- Incluye configuracion operativa general.
- Membership requests usa la key `membership.pending_timeout_days` para expirar solicitudes pendientes.
- Nuevas keys desde 8.4-C (2026-04-28):
  - `ranking.finance_closing_deadline_day` (default `5`) — día del mes límite para cierre financiero en el cálculo de `finance_score_pct`.
  - `ranking.recalculation_enabled` (default `true`) — kill-switch que inhibe el cron y el endpoint manual de recálculo de rankings cuando es `false`.

### `audit_logs`

- Tabla única del audit trail interno. Base extendida por `20260730180000_durable_audit_logs` (`event_key` único, `actor_kind`, `actor_scope`, `target_user_id`, `target_scope`, `effective_at`, `correlation_id`, `idempotency_key`, `result`; `action` amplió a VARCHAR(64)).
- Desde `20260812190000_audit_http_operations` (2026-08-12):
  - `source VARCHAR(24) NOT NULL DEFAULT 'service'` — `'http'` para filas generadas por `HttpAuditInterceptor` (mutaciones HTTP automáticas), `'service'` para eventos de dominio explícitos.
  - `request_context JSONB?` — solo filas `source='http'`: `{ method, path, status_code, duration_ms, ip, user_agent }`. Nunca contiene el body del request.
  - Índice `idx_audit_logs_created` sobre `created_at` para retención y consultas por rango temporal.
- `correlation_id` enlaza todas las filas escritas durante un mismo request HTTP (contexto `AsyncLocalStorage`; honra header `x-request-id` si es UUID válido).
- Ver `docs/features/audit-log.md` para el diseño completo del trail.

### `activities`, `activity_instances` y `activity_series`

- `activities` incluye `activity_date`, `activity_end_date`, `reminder_sent`, `activity_type_id`, `club_section_id`, `is_joint` y `activity_series_id` (nullable). Unique parcial `(activity_series_id, activity_date)` cuando hay serie. `attendees` es la asistencia confirmada. `rsvp` (jsonb) guarda la intención en actividades virtuales: `{ "<user_id>": "going" | "not_going" }`. No confirma asistencia. `audience` es `all` (toda la sección), `board` (directiva) o `classes` (ids en `classes`).
- `activity_instances` materializa una actividad por seccion (actividades conjuntas). **No** modela recurrencia.
- `activity_series` guarda la receta (`kind` interval/weekly, `interval_days`, `weekdays`, `first_date`, `until_date`) dentro del año eclesiastico de la fila.
- `activity_series_sections` recuerda las secciones de una serie conjunta para extender.

### `finances`

- Incluye `modified_by_id`, `club_section_id` y `post_closing_note`.
- La relacion principal es con `club_sections`, no con tablas legacy separadas por tipo.
- `finance_evidence_files` guarda hasta 3 fotos activas por movimiento financiero. Tiene FK `finance_id -> finances.finance_id` con `onDelete: Cascade`, FK `uploaded_by_id -> users.user_id`, metadatos de archivo (`file_url`, `file_name`, `file_type`, `file_size`) y `active`.
- Indices de evidencias: `idx_finance_evidence_files_finance` y `idx_finance_evidence_files_uploaded_by`.

### `member_insurances`

- Incluye `created_by_id`, `modified_by_id`, `evidence_file_url` y `evidence_file_name`.
- Sigue relacionada con `camporee_members`.
- **Dual-path**: es la vía legacy de alta directa de seguros y el FK que exige camporees. El capacity model (abajo) es la vía nueva; al aprobar una orden de pago de seguro se hace upsert aquí como *bridge* para no romper `camporee_members`.

### Insurance capacity model (`insurance_products`, `insurance_cycle_configs`, `insurance_purchases`, `insurance_coverage_slots`, `insurance_slot_movements`, `insurance_assignments`, `insurance_evidence_files`)

Modelo de capacidad de seguros por Campo Local, vivo en runtime desde antes de este trabajo pero no documentado aquí (drift corregido 2026-08-12):

- `insurance_products` — producto por LF con `coverage_scope` (`insurance_coverage_scope_enum`), `validity_mode` (`insurance_validity_mode_enum`), `default_duration_months?`. Índice `(local_field_id, active)`.
- `insurance_cycle_configs` — costo por ciclo: FK producto/LF/`ecclesiastical_year_id`/`club_type_id`, `unit_cost DECIMAL(10,2)`, `purchase_deadline DATE`, `timezone`. Unique por scope efectivo `(producto, LF, año, club_type)`.
- `insurance_purchases` — compra **qty anónima** por sección (`quantity`, `unit_cost_snapshot`, `total_amount`, `status insurance_purchase_status_enum` default `PENDING_CONFIRMATION`, submitter/reviewer). **Legado a reemplazar por `field_payment_orders`** (compras con beneficiarios nombrados); queda para lectura/drain.
- `insurance_coverage_slots` — cupos materializados al confirmar una compra: `sequence_number` unique por compra, `status insurance_slot_status_enum` default `AVAILABLE`, sección compradora vs sección actual.
- `insurance_slot_movements` — journal de movimientos de slot (`movement_type`, from/to section, `correlation_id`).
- `insurance_assignments` — asignación de un slot a un sujeto (`subject_type insurance_assignment_subject_enum`: user o participante externo de camporee), `valid_from/valid_until DATE`, `status insurance_assignment_status_enum` default `PENDING_CONFIRMATION`. Sin API HTTP de assign hasta payment-orders.
- `insurance_evidence_files` — evidencia privada en R2 ligada a compra o assignment (`evidence_type insurance_evidence_type_enum`, `file_key`, magic-bytes validados en upload).

### Field payment orders (`field_payment_orders`, `field_payment_order_lines`, `field_payment_order_proofs`, `field_payment_folio_counters`, `field_payment_order_configs`, `insurance_reassignment_requests`)

Órdenes de pago territoriales (migración `20260812220000_field_payment_orders`, 2026-08-12). Fuente estructural: `sacdia-backend/prisma/schema.prisma`.

- `field_payment_orders` — orden grupal por sección: `purpose field_payment_order_purpose_enum` (`INSURANCE|CAMPOREE`), `local_field_id`, `club_id`, `club_section_id`, folio secuencial por LF/año (`folio`, `folio_reference` unique por LF), referencia de propósito (`insurance_cycle_config_id?` para INSURANCE; exactamente uno de `local_camporee_id?` / `union_camporee_id?` para CAMPOREE, vía CHECK — `union_camporee_id` agregado en v1.1, migración `20260813130000`), `currency`, `unit_cost_centavos`, `total_centavos`, `status field_payment_order_status_enum` (`ISSUED|PROOF_SUBMITTED|APPROVED|PROOF_REJECTED|CANCELLED|EXPIRED`), `expires_at` (default 15 días vía `system_config`), `issued_by_id`, `idempotency_key?` (unique por emisor), auditoría de transiciones (`approved_by_id/at`, `cancelled_by_id/at`, `expired_at`).
- `field_payment_order_lines` — beneficiario nombrado por línea: `sequence`, `beneficiary_user_id`, `unit_cost_centavos`, `purpose`, `purpose_ref_id`, `active_guard BOOLEAN` (parte del unique parcial que impide dos órdenes activas del mismo beneficiario para el mismo propósito; se apaga al cancelar/expirar).
- `field_payment_order_proofs` — comprobantes subidos a R2 (`file_key`, `file_name`, `mime_type`, `size_bytes`), `status field_payment_order_proof_status_enum` (`SUBMITTED|APPROVED|REJECTED`), `uploaded_by_id`, `reviewed_by_id/at`, `reject_reason?`. Maker-checker: quien sube no puede aprobar.
- `field_payment_folio_counters` — contador `(local_field_id, year)` con `last_folio`; asignación con `FOR UPDATE` dentro de la transacción de creación. Formato `ORD{year}{####}`.
- `field_payment_order_configs` — instrucciones de pago por LF (unique `local_field_id`): datos bancarios (`bank_name/account/clabe/holder`) y/o `cash_instructions` (caja del campo), `extra_notes`, `active`. Requerida para renderizar el PDF de la orden.
- `insurance_reassignment_requests` — solicitud de transferencia de cobertura activa entre miembros del mismo club: `insurance_assignment_id`, `from_user_id`, `to_user_id`, `reason?`, `status` (`PENDING|APPROVED|REJECTED`), reviewer + `reject_reason?`.
- **Flags en `system_config`**: `field_payment_orders_v1` (JSON con lista de `local_field_id` habilitados) y `field_payment_orders.expiry_days` (default `15`).

### Camporee supplies (`camporee_supply_slots`, `camporee_supply_products`, `camporee_supply_plans`, `camporee_supply_lines`, `camporee_supply_payment_docs`, `camporee_supply_deliveries`, `camporee_supply_plan_audits`, `camporee_supply_folio_counters`)

Insumos de sección (migración `20260826120000_camporee_supplies`, en `development`). No reutiliza tablas de `camporee_orders`. Unique parcial plan `(sección, camporee)` vive en SQL, no en `@@unique` Prisma.

- `local_camporees` / `union_camporees` — `supply_edit_cutoff_local_time VARCHAR(5) NOT NULL DEFAULT '21:00'` (hora local del freeze).
- `camporee_supply_slots` — horario del organizador (`label`, `deliver_time` HH:MM, `sort_order`, `active`). XOR local/unión.
- `camporee_supply_products` — catálogo del evento (`name`, `uom` KG|L|BAG|UNIT, `unit_cost_centavos`, `active`). Precio bloqueado si existe plan `SUBMITTED`.
- `camporee_supply_plans` — un plan por sección inscrita; `status DRAFT|SUBMITTED`; `committed_total_centavos` al primer envío.
- `camporee_supply_lines` — `(plan, date, slot, product)` unique; `qty DECIMAL(12,3)`; snapshot `unit_cost_centavos` + `line_total_centavos`.
- `camporee_supply_payment_docs` — `PRINCIPAL|CHARGE|REFUND`; folio `INS{yyyy}{####}` unique por LF; PRINCIPAL no se reescribe; hijos apuntan a `parent_id`.
- `camporee_supply_deliveries` — check-in parcial a la sección (`qty`, actor, `note?`). Sin `delivered_to_member`.
- `camporee_supply_plan_audits` — append-only (bypass de freeze con motivo).
- `camporee_supply_folio_counters` — contador `(local_field_id, year)` propio, no el de PED.

### Camporee orders (`camporee_order_products`, `camporee_order_product_options`, `camporee_order_offerings`, `camporee_orders`, `camporee_order_lines`, `camporee_order_proofs`, `camporee_order_folio_counters`)

Pedidos de mercancía nominados (migración `20260824190000_camporee_orders`, en `development`). Fuente estructural: `sacdia-backend/prisma/schema.prisma`.

- `local_camporees` / `union_camporees` — flags `orders_enabled BOOLEAN NOT NULL DEFAULT false`, `orders_opens_at TIMESTAMPTZ?`, `orders_deadline TIMESTAMPTZ?`.
- `camporee_order_products` — biblioteca territorial: `owner_scope` (`DIVISION|UNION|LOCAL_FIELD`) + un owner id, `size_scheme` (`LETTER|NUMERIC|NONE`), `club_type_id?`, `active`.
- `camporee_order_product_options` — un eje de talla por producto; unique `(product_id, label)`; soft-delete.
- `camporee_order_offerings` — producto ofertado en un camporee (`local_camporee_id` XOR `union_camporee_id`, CHECKs en SQL) con `price_centavos`.
- `camporee_orders` — pedido de sección: folio `PED{yyyy}{####}` unique por LF, `status camporee_order_status_enum` (`ISSUED|PROOF_SUBMITTED|PROOF_REJECTED|PAID|DELIVERED|CANCELLED|EXPIRED`), `total_centavos` calculado en servidor, `authorized_without_proof`, snapshot de caja LF, `idempotency_key?` unique por emisor. Sin unique que impida pedidos suplementarios de la misma sección.
- `camporee_order_lines` — línea nominada: `camporee_member_id` (elegibilidad), snapshots de nombre/producto/talla/precio, `qty`, `delivered_to_member_at?`. Unique `(order_id, camporee_member_id, offering_id, option_id)` + unique parcial `option_id IS NULL` en SQL.
- `camporee_order_proofs` — comprobante R2 (`r2_key`), `status` (`SUBMITTED|APPROVED|REJECTED`), maker-checker.
- `camporee_order_folio_counters` — contador `(local_field_id, year)` con `last_folio`.
- **Flag en `system_config`**: `camporee_orders.expiry_days` (default `15`).

### `achievement_categories`, `achievements`, `user_achievements`, `achievement_event_log`

> **NO CANON** — Dominio achievements documentado como feature operativa sin promocion al canon. Autoridad estructural: `sacdia-backend/prisma/schema.prisma`.

- `achievement_categories` — categorias editables con `display_order`, `icon`, `active`; unicidad por `name`.
- `achievements` — definicion del logro con `criteria` JSON tipado por `achievement_type`, `scope` (`achievement_scope`), `tier` (`achievement_tier`), flags `secret`, `repeatable`, `max_repeats`, FK opcional a `club_types.club_type_id`, y auto-relacion opcional para prerequisito.
- `user_achievements` — progreso del usuario por tuple `(user_id, achievement_id, ecclesiastical_year_id)`. Campos clave: `progress_value`, `progress_target`, `completed` (bool), `times_completed`, `notified`, `progress_metadata` (JSON). La unicidad asegura un registro de progreso por usuario/logro/año.
- `achievement_event_log` — journal de eventos procesados por el evaluador. Guarda `event_type`, `user_id`, `payload` JSON, flag `processed` e indices por `(user_id, event_type, created_at)` y por eventos pendientes `(processed, created_at)` para el worker de BullMQ. `idempotency_key` es único y nullable: la autorización de investidura lo usa para dejar una sola fila de `class.completed`. El `jobId` de BullMQ no es esa clave: es un hash estable sin `:`. Sin BullMQ disponible, el evento queda persistido pero no encolado. Un trabajo con el mismo identificador no vuelve a evaluar un evento ya `processed`. Si ese trabajo agotó sus intentos y sigue en `failed`, la reconciliación lo reintenta con el mismo id y los intentos en cero, sin abrir otra fila.
- **Enums activos** (verificados en Prisma):
  - `achievement_type`: `THRESHOLD`, `STREAK`, `COMPOUND`, `MILESTONE`, `COLLECTION`
  - `achievement_scope`: `GLOBAL`, `CLUB_TYPE`, `ECCLESIASTICAL_YEAR`
  - `achievement_tier`: `BRONZE`, `SILVER`, `GOLD`, `PLATINUM`, `DIAMOND`
- **Drift de cliente verificado** (no corregido en este trabajo): el cliente admin usa valores de `scope` `GLOBAL|CLUB|UNIT` que no coinciden con los valores Prisma `GLOBAL|CLUB_TYPE|ECCLESIASTICAL_YEAR`.

### `classes` y duración de trayectoria

- `classes.available_from_year_id INT?` y `classes.available_until_year_id INT?` referencian `ecclesiastical_years.year_id`.
- `classes.advanced_enabled BOOLEAN NOT NULL DEFAULT false` habilita la vía avanzada de la clase sin mezclarla con investidura.
- `available_until_year_id = NULL` significa sin vencimiento para nuevas inscripciones; no se usa año sentinel.
- `classes.min_duration_years INT NOT NULL DEFAULT 1` y `classes.max_duration_years INT NOT NULL DEFAULT 1` gobiernan elegibilidad antes de solicitar investidura.
- CHECKs vigentes: `min_duration_years >= 1`, `max_duration_years >= 1`, `max_duration_years >= min_duration_years`.
- Índices: `idx_classes_available_from_year`, `idx_classes_available_until_year`.
- `class_sections.requirement_track` separa `BASIC`, `ADVANCED` y `EXTRA`; `BASIC` + `EXTRA` cuentan para investidura, mientras `ADVANCED` se gestiona como badge/estado aparte.
- `class_sections` puede anclarse opcionalmente a `divisions`, `unions`, `local_fields` o ventana por `ecclesiastical_years`; `EXTRA` exige exactamente un owner y `BASIC`/`ADVANCED` no aceptan owner.
- `enrollments.investiture_status` incluye `EXPIRED` para preservar progreso histórico cuando se supera la duración máxima sin investidura.
- `ecclesiastical_years` no admite rangos solapados (`ecclesiastical_years_no_overlap`, daterange inclusivo). Un periodo histórico puede permanecer inactivo.
- `enrollments.record_kind` distingue `OPERATIONAL` (default) de `HISTORICAL_CERTIFICATE`. Los índices parciales `uniq_enrollments_active_user_year_regular` y `uniq_enrollments_active_user_year_cross_type` solo aplican a filas operativas activas. Un histórico exige `INVESTIDO`, fecha, `active` y progreso bloqueado. Guía Mayor (`GM-01`) admite una sola fila por persona.
- `certificate_bulk_import_files` guarda el comprobante privado: `upload_status`, `staging_key`, `object_key`, `size_bytes`, `confirmed_at` y `jurisdiction` (`CAMPO_LOCAL` o `INSTITUTIONAL`). La descarga usa la clave sellada, no una URL pública. Las filas anteriores quedan `CONFIRMED` sin `object_key` hasta una carga nueva.
- `certificate_bulk_import_batches.revision` y `certificate_bulk_import_items.revision` empiezan en 0. El cliente puede enviar `expected_revision`; si no coincide, el cambio se rechaza.
- `institutional_certificate_requests` guarda la solicitud de Guía Mayor Avanzado o Instructor. Estados: `PENDING_REVIEW`, `APPROVED`, `REJECTED`. Aprobar no crea `enrollments`. El índice `uniq_institutional_certificate_request_open` impide dos solicitudes abiertas o aprobadas para la misma persona, clase, archivo y fecha.
- `enrollments.cross_type_enrollment` marca el privilegio de un Guía Mayor investido que cursa una clase de Aventureros o Conquistadores en el mismo año. Los índices parciales permiten una activa operativa de cada tipo por usuario/año.
- `investiture_validation_history.action` incluye `EXPIRED` para auditar vencimientos manuales o por guard de investidura.

### `enrollment_rankings`, `section_rankings`, `enrollment_ranking_weights` (8.4-A)

> Naming híbrido canónico: schema usa `enrollment_*`; API/permisos/DTOs usan `member-*`. Ver `docs/canon/decisiones-clave.md` §22 y `docs/canon/runtime-rankings.md` §13.8. Lock permanente Audit A11.

**`enrollment_rankings`** — clasificación por enrollment y año eclesiástico:

- PK: `id UUID`, Unique: `(enrollment_id INTEGER, ecclesiastical_year_id INTEGER)`.
- Señales: `class_score_pct`, `investiture_score_pct`, `camporee_score_pct` — cada una `NUMERIC(5,2)`, nullable, CHECK ∈ [0,100].
- Composite: `composite_score_pct NUMERIC(5,2)`, nullable, CHECK ∈ [0,100].
- Posición: `rank_position INTEGER` nullable (NULLS LAST, DENSE_RANK).
- FK: `enrollment_id → enrollments`, `user_id → users`, `club_id → clubs`, `club_section_id → club_sections` (nullable), `ecclesiastical_year_id → ecclesiastical_years`, `awarded_category_id → award_categories` (nullable).
- Índices: `(club_id, ecclesiastical_year_id)`, `(club_section_id, ecclesiastical_year_id)`, `(club_id, ecclesiastical_year_id, composite_score_pct DESC)`, `(user_id)`, `(awarded_category_id)`.

**`section_rankings`** — agregado puro por sección y año:

- PK: `id UUID`, Unique: `(club_section_id INTEGER, ecclesiastical_year_id INTEGER)`.
- `composite_score_pct NUMERIC(5,2)` nullable — AVG de enrollments con composite NOT NULL.
- `active_enrollment_count INTEGER` — conteo de enrollments activos (default 0).
- `rank_position INTEGER` nullable.
- `awarded_category_id UUID` nullable — FK → `award_categories`.
- FK: `club_section_id → club_sections`, `ecclesiastical_year_id → ecclesiastical_years`, `club_id → clubs`, `awarded_category_id → award_categories` (nullable).
- Índices: `(club_id, ecclesiastical_year_id)`, `(club_id, ecclesiastical_year_id, composite_score_pct DESC)`, `(awarded_category_id)`.

**`enrollment_ranking_weights`** — pesos de señales por (club_type_id, ecclesiastical_year_id):

- PK: `id UUID`, Unique: `(club_type_id INTEGER?, ecclesiastical_year_id INTEGER?)`.
- `class_pct`, `investiture_pct`, `camporee_pct` — `DECIMAL(5,2)`.
- `is_default BOOLEAN` — true solo para la fila global (ambas FK nullable).
- Sum=100 enforced al nivel de servicio con tolerancia IEEE `Math.abs(sum-100) ≤ 0.01`; no existe CHECK DB.
- Seeded: fila global `is_default=true` con pesos 50/30/20 (class/investiture/camporee).

### `award_categories` — extensión scope (8.4-A)

- Nueva columna: `scope VARCHAR(20) NOT NULL DEFAULT 'club'` — valores válidos: `club | section | member`.
- Índice: `idx_award_categories_scope` sobre `(scope, is_legacy)`.
- Backfill: todas las filas existentes antes de la migración → `scope='club'`.
- El query param `?scope=` en `GET /api/v1/award-categories` filtra por este campo. Error canónico: `AWARD_CATEGORY_SCOPE_INVALID`.
- POST y PATCH aceptan `scope` como campo opcional (`@IsOptional @IsIn(['club','section','member'])`).

### Better Auth

- Los modelos Prisma vigentes son `session`, `account` y `verification`.
- En base fisica se mapean a `sessions`, `accounts` y `verifications` via `@@map`.

### `admin_auth_sessions` (rama `codex/sacdia-admin-ios-auth`, no en `development`)

- Extiende `sessions` con una relación opcional 1:1: `session_id` es PK/FK y usa borrado en cascada.
- Mantiene `surface='admin'`, `client_type='ios'`, `family_id`, assurance `aal1|aal2`, expiración absoluta, expiración inactiva (`idle_expires_at`) y datos de revocación; el DDL aplica los checks correspondientes.
- `idle_expires_at` está diseñado para convertirse en la autoridad de expiración por inactividad cuando D1c adopte el writer y la lectura runtime. En el estado actual de la rama, `AdminSessionRepository.isActiveForToken` todavía valida `sessions.expires_at` de Better Auth; por tanto, esa fecha aún no es solo un espejo de compatibilidad.
- `active_assignment_id` es opcional, referencia `club_role_assignments` y usa `ON DELETE SET NULL`.
- Incluye índices para `family_id`, `revoked_at` y `active_assignment_id`.
- La migración existe únicamente en la rama backend `codex/sacdia-admin-ios-auth`; su despliegue no fue verificado y la tabla todavía no forma parte del runtime de referencia.

### Persistencia de refresh administrativo (rama `codex/sacdia-admin-ios-auth`, no en `development`)

Esta persistencia pertenece al flujo administrativo iOS y está definida en la rama backend `codex/sacdia-admin-ios-auth`. Los commits desde `c09a600` hasta `ee84d2d`, ambos inclusive, aportan schema, migración y pruebas estructurales; todavía no existe writer, cleanup ni endpoint runtime de login, refresh o logout administrativo.

- `admin_refresh_tokens` permite **cero o una fila** por `session_id`; no demuestra que hoy exista un refresh vigente. El schema exige un `token_hash` de 64 caracteres hexadecimales minúsculos, formato destinado a SHA-256, pero todavía no existe un writer que materialice ese contrato; tampoco hay columna para el secreto raw. La clave compuesta `(session_id, family_id)` enlaza la eventual fila con `admin_auth_sessions` y el borrado de la sesión la elimina.
- `admin_refresh_token_history` está diseñado para conservar hashes de generaciones rotadas y soportar detección de reuso e idempotencia. No tiene FK a `sessions` ni FK de `replaced_by_token_id`, para permitir retención independiente del estado actual. El CHECK de base de datos garantiza únicamente `retain_until >= rotated_at + 60 seconds`; conservar cada hash hasta la expiración absoluta de su sesión será obligación del writer y cleanup futuros, no una restricción vigente del schema.
- `admin_refresh_rotation_receipts` reserva persistencia para recibos cifrados AES-GCM mediante `key_id`, `nonce` de 12 bytes, `ciphertext` y `auth_tag` de 16 bytes, sin columna para un refresh token en claro. Un futuro writer deberá ligar el `Idempotency-Key` UUID tanto a `(previous_token_id, idempotency_key)` como a `(session_id, previous_generation, idempotency_key)` y a la identidad compuesta completa del historial previo (`token_id`, `session_id`, `family_id`, `generation`, `rotated_at`). El DDL sí exige TTL exacta de 60 segundos (`expires_at = created_at + 60 seconds`) y que `created_at` coincida con `history_rotated_at`.
- La migración inicializa `idle_expires_at` de sesiones administrativas existentes, acotado por `absolute_expires_at`; falla si queda un null. Después deshabilita únicamente sus tokens legacy de Better Auth con el sentinel `admin-disabled:<session_id>`, previa detección de colisión. Esas sesiones requieren reautenticación para crear una familia de refresh; no se insertan refresh tokens actuales durante el backfill y las sesiones no administrativas no se modifican.
- Esta migración **no debe ejecutarse** antes de completar D2 —exclusión de tokens/sesiones legacy y reautenticación comprobada— y D1c —writer y adopción runtime de `idle_expires_at`—. `20260710200000_admin_refresh_rotation` depende de que `20260710130000_admin_auth_sessions` ya haya creado `admin_auth_sessions`; existe en la rama backend, pero **no se ejecutó ni se verificó contra una base de datos**.

### `folder_templates`

- Ownership polimorfico: incluye `owner_union_id` y `owner_local_field_id`, ambos nullable con FK a `unions(union_id)` y `local_fields(local_field_id)` respectivamente (`ON DELETE RESTRICT`).
- Ya no existe el unique compuesto `(club_type_id, ecclesiastical_year_id)`; cada tipo-anio puede convivir con una plantilla por union y una por campo local.
- El CHECK `folder_templates_exactly_one_owner_check` obliga a que exactamente uno de los owners este presente.
- La unicidad efectiva se enforce via dos indices unicos parciales: `folder_templates_union_owner_unique` sobre `(club_type_id, ecclesiastical_year_id, owner_union_id) WHERE owner_union_id IS NOT NULL` y `folder_templates_local_field_owner_unique` sobre `(club_type_id, ecclesiastical_year_id, owner_local_field_id) WHERE owner_local_field_id IS NOT NULL`.
- Indices btree de apoyo: `idx_folder_templates_owner_union`, `idx_folder_templates_owner_local_field`.
- Incluye `status folder_template_status_enum NOT NULL DEFAULT 'DRAFT'` con valores `DRAFT`, `PUBLISHED`, `ARCHIVED`; `active=true` queda reservado para plantillas `PUBLISHED` capaces de generar carpetas.
- Indice btree `idx_folder_templates_status` para filtros administrativos por lifecycle.
- Desde la unificación con ranking anual, las nuevas plantillas son borrador por default (`active=false`, `status='DRAFT'`) y sólo se pueden publicar si la suma de `folder_template_sections.max_points` coincide exactamente con el componente efectivo `annual_evidence_folder.max_points`.
- Las plantillas `DRAFT` pueden editarse y eliminarse si no generaron carpetas; las `PUBLISHED`/`ARCHIVED` quedan bloqueadas y se reutilizan mediante copia a nuevo borrador.
- La migración jerárquica desactiva plantillas activas existentes que no cumplan esa regla; las carpetas ya creadas conservan su snapshot histórico.

### `annual_folders`

- Incluye `local_camporee_id` y `union_camporee_id` (ambos nullable) con FK a `local_camporees` y `union_camporees` respectivamente (`ON DELETE NO ACTION`).
- El CHECK `annual_folders_at_most_one_camporee_check` impide que una carpeta referencie simultaneamente a un camporee local y a uno de union; ambos nulos es valido para carpetas de solo-investidura.
- Incluye el flag `requires_union_confirmation BOOLEAN NOT NULL DEFAULT false`, materializado en la tabla para que el runtime no tenga que recalcularlo en cada lectura.
- Indices de apoyo: `idx_annual_folders_local_camporee`, `idx_annual_folders_union_camporee`.

### `annual_folder_section_evaluations`

- Columnas renombradas: `evaluated_by_id -> lf_approved_by` y `evaluated_at -> lf_approved_at`. Ambas son ahora NULLABLE y `lf_approved_at` ya no lleva `DEFAULT now()`.
- Nuevas columnas para la capa de union: `union_approved_by UUID?` (FK a `users.user_id`), `union_approved_at TIMESTAMPTZ?` y `union_decision union_evaluation_decision_enum?`.
- Nueva columna `status annual_folder_section_status_enum NOT NULL DEFAULT 'PENDING'`, que materializa el estado de la evaluacion en vez de derivarlo. Los valores siguen el flujo `PENDING -> SUBMITTED -> PREAPPROVED_LF -> VALIDATED | REJECTED`.
- CHECK `annual_folder_section_evaluations_union_after_lf_check`: `union_approved_at IS NULL OR lf_approved_at IS NOT NULL`; una accion de union requiere que exista accion previa del campo local.
- CHECK `annual_folder_section_evaluations_preapproved_requires_lf_check`: `status <> 'PREAPPROVED_LF' OR lf_approved_at IS NOT NULL`; impide marcar `PREAPPROVED_LF` sin un timestamp de aprobacion local.
- Indice `idx_annual_folder_section_evaluations_status` para soportar filtrado analitico por estado.

### `club_annual_rankings` — columnas extendidas (8.4-C)

Columnas nuevas desde migración `20260428*_extended_rankings_schema`:

- `folder_score_pct FLOAT NOT NULL DEFAULT 0` — porcentaje de puntaje de carpeta (0-100).
- `finance_score_pct FLOAT NOT NULL DEFAULT 0` — porcentaje de cierre financiero mensual (0-100).
- `camporee_score_pct FLOAT NOT NULL DEFAULT 0` — porcentaje de resultados oficiales de eventos puntuables de camporee por sección (0-100); la inscripción/asistencia ya no otorga puntos.
- `evidence_score_pct FLOAT NOT NULL DEFAULT 0` — porcentaje de evidencias validadas (0-100).
- `composite_score_pct FLOAT NOT NULL DEFAULT 0` — promedio ponderado de los 4 componentes (0-100).
- `composite_calculated_at TIMESTAMPTZ?` — timestamp de la última actualización del composite.

Índice nuevo: `idx_rankings_composite` sobre `(ecclesiastical_year_id, club_type_id, composite_score_pct DESC)` para soportar el dense ranking y listados ordenados por composite.

### `award_categories` — columnas extendidas (8.4-C)

Columnas nuevas:

- `min_composite_pct FLOAT?` — umbral inferior de `composite_score_pct` para calificar en la categoría (0-100).
- `max_composite_pct FLOAT?` — umbral superior de `composite_score_pct` (0-100). `null` = sin tope.
- `is_legacy BOOLEAN NOT NULL DEFAULT false` — marcador de filas creadas antes de 2026-04-28. Las categorías legacy se excluyen del composite ranking. El GET filtra `is_legacy = false` por defecto.

### `ranking_weight_configs` (nueva — 8.4-C)

Tabla que almacena configuraciones de pesos para el composite ranking:

- `id UUID PK` — identificador de la configuración.
- `club_type_id INT?` — FK a `club_types`; `NULL` = configuración global default.
- `folder_weight INT NOT NULL` — peso del componente carpeta (0-100).
- `finance_weight INT NOT NULL` — peso del componente finanzas (0-100).
- `camporee_weight INT NOT NULL` — peso del componente camporee (0-100).
- `evidence_weight INT NOT NULL` — peso del componente evidencias (0-100).
- `created_at TIMESTAMPTZ NOT NULL DEFAULT now()`.
- `updated_at TIMESTAMPTZ NOT NULL DEFAULT now()`.

Constraints:

- CHECK `ranking_weight_configs_sum_check`: `folder_weight + finance_weight + camporee_weight + evidence_weight = 100`.
- Índice único parcial: `ranking_weight_configs_club_type_unique` sobre `(club_type_id) WHERE club_type_id IS NOT NULL` — permite único global null + un override por club_type.

### `ranking_tiers` (nueva — ranking scorecard)

Tabla global de rangos de reconocimiento calculados por bandas porcentuales desde el máximo anual hacia abajo:

- `ranking_tier_id UUID PK`.
- `name VARCHAR(100)` — nombre visible, por ejemplo `Diamante`.
- `slug VARCHAR(80)` — identificador único estable.
- `band_percentage DECIMAL(5,2)` — amplitud del rango; debe estar en `(0,100]`.
- `color VARCHAR(20)?` e `icon VARCHAR(100)?` — metadatos visuales para admin/app.
- `sort_order INTEGER` — orden descendente desde el mayor reconocimiento.
- `active BOOLEAN DEFAULT true`.

Índices/constraints:

- `ranking_tiers_slug_key` único por `slug`.
- CHECK `ranking_tiers_band_percentage_check`.
- Índice único parcial `ranking_tiers_active_sort_order_unique` para evitar dos rangos activos con el mismo orden.
- Índice `idx_ranking_tiers_active_order` para listar rangos activos ordenados.

### `annual_ranking_configs` (nueva — ranking scorecard)

Configura el máximo anual por alcance jerárquico, año eclesiástico y tipo de club. La configuración de Unión tiene precedencia sobre Campo Local:

- `annual_ranking_config_id UUID PK`.
- `union_id INT?` — FK → `unions`; scope superior.
- `local_field_id INT?` — FK → `local_fields`; scope local permitido sólo cuando no hay configuración activa de su Unión.
- `ecclesiastical_year_id INT` — FK → `ecclesiastical_years`.
- `club_type_id INT` — FK → `club_types`.
- `max_points INT` — máximo anual del ranking; debe ser positivo. Debe incluir un componente `annual_evidence_folder` que define el total obligatorio de la Carpeta Anual.
- `active BOOLEAN DEFAULT true`.
- `created_by UUID?`, `updated_by UUID?` — auditoría ligera del usuario que creó/actualizó.

Índices/constraints:

- CHECK `annual_ranking_configs_exactly_one_scope_check`: exactamente uno entre `union_id` y `local_field_id`.
- Índices únicos parciales: `annual_ranking_configs_unique_union_scope` sobre `(union_id, ecclesiastical_year_id, club_type_id)` y `annual_ranking_configs_unique_local_field_scope` sobre `(local_field_id, ecclesiastical_year_id, club_type_id)`.
- CHECK `annual_ranking_configs_max_points_check`.
- Índices `idx_annual_ranking_configs_union_id`, `idx_annual_ranking_configs_local_field_id`, `idx_annual_ranking_configs_year_type` y `idx_annual_ranking_configs_active`.

### `annual_ranking_axis_configs` (nueva — ejes del ranking anual)

Divide una configuración anual en ejes configurables. El uso inicial recomendado es:

- `administrative` — `Cumplimiento Administrativo`.
- `operational` — `Vida Operativa del Club`.

Columnas:

- `annual_ranking_axis_config_id UUID PK`.
- `annual_ranking_config_id UUID` — FK → `annual_ranking_configs` con `ON DELETE CASCADE`.
- `axis_key VARCHAR(50)` — clave estable del eje.
- `label VARCHAR(120)` — etiqueta visible.
- `max_points INT` — presupuesto máximo del eje; debe ser positivo.
- `sort_order INTEGER DEFAULT 0`.
- `active BOOLEAN DEFAULT true`.

Índices/constraints:

- Unique `(annual_ranking_config_id, axis_key)`.
- CHECK `annual_ranking_axis_configs_max_points_check`.
- Índice `idx_annual_ranking_axis_configs_active_order`.
- Índice `idx_annual_ranking_axis_configs_config_active_order`.
- La suma de ejes activos debe igualar `annual_ranking_configs.max_points`; se valida en servicio/API porque depende de múltiples filas.

### `annual_ranking_component_configs` (nueva — ranking scorecard)

Define el presupuesto de puntos por componente dentro de un eje anual:

- `annual_ranking_component_config_id UUID PK`.
- `annual_ranking_config_id UUID` — FK → `annual_ranking_configs` con `ON DELETE CASCADE`.
- `annual_ranking_axis_config_id UUID?` — FK → `annual_ranking_axis_configs` con `ON DELETE CASCADE`. Es nullable para permitir remediación manual de componentes legacy desconocidos; las escrituras nuevas deben persistir componentes asociados a un eje.
- `component_key VARCHAR(50)` — clave estable canónica (`annual_evidence_folder`, `monthly_reports_timeliness`, `finance_compliance`, `institutional_data_completeness`, `activities_registered`, `attendance_participation`, `camporee_events`, `class_investiture_progress`, `sacdia_operational_usage`). Alias legacy aceptados por API: `annual_folder`, `finance`, `camporee`.
- `label VARCHAR(120)` — etiqueta visible.
- `max_points INT` — puntos máximos del componente; debe ser positivo.
- `sort_order INTEGER DEFAULT 0`.
- `active BOOLEAN DEFAULT true`.

Índices/constraints:

- Unique `(annual_ranking_config_id, component_key)`.
- CHECK `annual_ranking_component_configs_max_points_check`.
- Índice `idx_annual_ranking_component_configs_active_order`.
- Índice `idx_annual_ranking_component_configs_axis_id`.
- La suma de componentes activos por eje debe igualar `annual_ranking_axis_configs.max_points`; se valida en servicio/API porque depende de múltiples filas.

---

## Inventario resumido por dominio

### Organizacion y clubes

- `countries`, `unions`, `local_fields`, `districts`, `churches`, `clubs`, `club_sections`, `club_types`, `club_ideals`, `units`, `unit_members`
- `coordination_zones`, `coordination_zone_districts`, `coordinator_assignments`

### RBAC y auth

- `roles`, `permissions`, `role_permissions`, `users_roles`, `users_permissions`, `club_role_assignments`, `role_slot_limits`, `role_assignment_requests`
- `session`, `account`, `verification`, `users_pr`, `notification_preferences`, `notification_logs`, `user_fcm_tokens`
- `admin_auth_sessions` (solo en la rama `codex/sacdia-admin-ios-auth`; no está en `development`)
- `admin_refresh_tokens`, `admin_refresh_token_history`, `admin_refresh_rotation_receipts` (solo en la rama `codex/sacdia-admin-ios-auth`; no están en `development`)
- `authorization_context_versions`

### Usuarios y salud

- `users`, `legal_representatives`, `emergency_contacts`, `relationship_types`
- `dependent_profiles`, `guardianships`, `guardianship_consent_evidences`, `guardianship_link_codes` (perfiles familiares; `legal_representatives` queda de solo lectura hasta la Fase 4)
- `allergies`, `diseases`, `medicines`, `users_allergies`, `users_diseases`, `users_medicines`
- `member_insurances`

### Formacion

- `classes`, `class_modules`, `class_sections`, `enrollments`, `class_module_progress`, `class_section_progress`
- `certifications`, `certification_versions`, `certification_eligibility_rules`, `certification_modules`, `certification_sections`, `certification_requirement_components`
- `users_certifications`, `certification_section_progress`, `certification_component_responses`, `certification_evidences`, `certification_review_events`, `certification_closeout_evidences`, `certification_module_progress` (legacy projection retained)
- `investiture_config`, `investiture_validation_history`, `validation_logs`

**Certificaciones configurables (2026-08-11):**

- `certification_versions.status`: `DRAFT` | `PUBLISHED` | `RETIRED` — solo `DRAFT` es mutable.
- `users_certifications`: `certification_version_id` (FK obligatoria en inscripciones nuevas), `status` (`ENROLLED` … `CERTIFIED`), `lock_version` (concurrencia optimista).
- `certification_section_progress`: `enrollment_id`, `status` (`DRAFT` | `SUBMITTED` | `CHANGES_REQUESTED` | `APPROVED`); fuente de verdad del requisito.
- `certification_evidences.upload_status`: `PENDING_UPLOAD` | `CONFIRMED`; bucket R2 privado.
- `certification_closeout_evidences.review_status`: `PENDING` | `SUBMITTED` | `CHANGES_REQUESTED` | `APPROVED`.

### Honores y evidencias

- `honors`, `honors_categories`, `master_honors`, `users_honors`, `honor_instructor_proposals`
- `honor_club_types`, `class_honors`, `class_prerequisites`
- `honor_requirements`, `user_honor_requirement_progress`, `requirement_evidence`, `evidence_files`
- `master_honor_divisions`, `master_honor_requirement_groups`, `master_honor_requirement_options`, `master_honor_requirement_option_honors`
- `users_master_honors`, `master_honor_evaluation_history`

### Actividades, camporees e inventario

- `activity_types`, `activities`, `activity_instances`
- `local_camporees`, `union_camporees`, `union_camporee_local_fields`, `camporee_clubs`, `camporee_members`, `camporee_payments`
  - `local_camporees` y `union_camporees` guardan dirección textual (`local_camporee_place` / `union_camporee_place`), coordenadas opcionales (`lat`, `long`) para vista de mapa en app, `agenda_visible_from` para abrir agenda completa antes/durante el camporee y `club_registration_closed_at/by` para congelar secciones competitivas.
  - Ambos modelos incluyen `orders_enabled` (default `false`), `orders_opens_at` y `orders_deadline` para la ventana de pedidos de mercancía (migración `20260824190000_camporee_orders`).
  - Ambos modelos incluyen `supply_edit_cutoff_local_time VARCHAR(5) DEFAULT '21:00'` para el freeze de insumos (migración `20260826120000_camporee_supplies`).
  - Ambos modelos incluyen `club_registration_opens_at TIMESTAMPTZ NULL` (nulo = apertura inmediata), deadlines `TIMESTAMPTZ`, y `timezone` IANA con default histórico provisional `America/Mexico_City`. `timezone_verified_at/by` audita la confirmación; `timezone_verified_by` tiene FK nombrada a `users(user_id)`, `ON DELETE SET NULL` e índice por tabla. El backfill no modifica fechas ni deadlines históricos.
  - Los eventos del camporee viven en `camporee_events` y se relacionan con camporee local o de unión mediante FK excluyentes.
  - Bloques opcionales de agenda viven en `camporee_event_schedule_blocks`; sus asignaciones por sección inscrita viven en `camporee_event_schedule_block_assignments`.
  - El roster operativo vive en `camporee_staff_members`; cada fila apunta a un usuario y exactamente un camporee local o de unión, con categoría descriptiva (`judge`, `administrative`, `kitchen`, `support`, `spiritual`, `leadership`, `other`).
  - Las asignaciones de personas a actividades viven en `camporee_event_staff_assignments`; permiten roles `responsible`, `assistant`, `evaluator` y `support`, sin forzar todos los roles en cada evento.
  - Especialidades de preparación viven en `camporee_event_honors` (`camporee_event_id` + `honor_id`, unique, `display_order`). Consultivo: no inscribe ni bloquea. Máx. 20. FK honor `ON DELETE RESTRICT`. Migración `20260828120000_camporee_event_honors`.
  - Scoring reutilizable de templates vive en `camporee_event_template_rubrics`; al clonar un template puntuable se copian criterios hacia `camporee_event_rubrics`.
  - Scoring oficial vive en `camporee_event_rubrics`, `camporee_judges`, `camporee_event_judge_assignments`, `camporee_event_score_submissions`, `camporee_event_score_submission_items` y `camporee_event_section_results`. `camporee_events.scoring_enabled` habilita puntaje real por rúbrica; `camporee_clubs`/`camporee_members` quedan como inscripción operativa/histórica.
  - `camporee_event_score_submissions` guarda `score_status` (`scored`/`no_show`), `is_no_show` y `override_of_submission_id` para auditar ausencias y correcciones manuales del resultado oficial anterior. Además persiste `idempotency_key UUID?` y `request_hash VARCHAR(64)?`; el índice único parcial `(submitted_by, idempotency_key)` sólo aplica cuando la clave no es nula. `raw_awarded_points` conserva la suma de rúbrica antes del piso y `minimum_adjustment_points` la diferencia aplicada; `total_awarded_points` sigue siendo el total oficial. La migración `20260709100000` backfillea conservadoramente filas históricas con `raw_awarded_points = total_awarded_points` y `minimum_adjustment_points = 0` porque no puede reconstruir ajustes previos.
  - `camporee_event_section_results` replica `score_status` e `is_no_show` en el resultado activo; sólo debe haber un resultado activo por evento/sección, y un override de Campo Local inactiva el anterior. El backend serializa cada mutación por `(camporee_event_id, club_section_id)` en la misma transacción antes de leer o reemplazar el activo.
  - Las mutaciones de scoring oficial requieren `club_registration_closed_at` porque la lista de secciones inscritas debe estar congelada; la inscripción de miembros sigue controlada por su propio deadline.
- `inventory_categories`, `club_inventory`, `inventory_evidence_files`, `inventory_history`

### Finanzas y carpetas

- `finances`, `finance_evidence_files`, `finances_categories`, `FinancePeriodClosing`
- `folders`, `folders_modules`, `folders_sections`, `folder_assignments`, `folders_modules_records`, `folders_section_records`

### Enrollment anual, ranking y reportes

- `club_enrollments`, `folder_templates`, `folder_template_sections`
- `annual_folders`, `annual_folder_evidences`, `annual_folder_section_evaluations`, `annual_folder_section_submissions`
- `award_categories`, `club_annual_rankings`, `ranking_weight_configs`, `ranking_tiers`, `annual_ranking_configs`, `annual_ranking_axis_configs`, `annual_ranking_component_configs`, `monthly_reports`, `monthly_report_manual_data`, `member_of_month`, `weekly_records`, `scoring_categories`, `weekly_record_scores`
- `enrollment_rankings`, `section_rankings`, `enrollment_ranking_weights` — (8.4-A) clasificación por enrollment/sección

### Recursos y logros

- `resource_categories`, `resources`
- `achievement_categories`, `achievements`, `user_achievements`, `achievement_event_log`

### Soporte operativo

- `error_logs`, `system_config`, `club_transfer_requests`

---

## Enums vigentes

- `achievement_scope`
- `achievement_tier`
- `achievement_type`
- `annual_folder_section_status_enum` (`PENDING`, `SUBMITTED`, `PREAPPROVED_LF`, `VALIDATED`, `REJECTED`)
- `blood_type`
- `evidence_type_enum`
- `evidence_validation_enum`
- `gender`
- `class_honor_relation_type_enum` (`REQUIRED`, `RECOMMENDED`, `ELECTIVE`)
- `master_honor_applicability_scope_enum`
- `master_honor_requirement_group_type_enum`
- `honor_completion_mode_enum` (`UNDECIDED`, `IN_APP`, `EXTERNAL`)
- `honor_instructor_proposal_status_enum` (`PENDING`, `APPROVED`, `REJECTED`, `WITHDRAWN`)
- `folder_template_status_enum` (`DRAFT`, `PUBLISHED`, `ARCHIVED`)
- `honor_validation_status_enum`
- `insurance_type_enum`
- `investiture_action_enum` (incluye `LEGACY_LOCK_RELEASED`, migración `20261009120000_investiture_legacy_lock_release_action`, aplicada en las tres ramas de Neon; la escribe solo el desbloqueo de la vía anterior de la fase 8 y no cambia `investiture_status`)
- `investiture_status_enum`
- `origin_level_enum`
- `user_master_honor_status_enum`
- `user_master_honor_source_enum`
- `user_master_honor_status_reason_enum`
- `role_category`
- `union_evaluation_decision_enum` (`APPROVED`, `REJECTED_OVERRIDE`)
- `user_approval_status`
- `certification_version_status_enum` (`DRAFT`, `PUBLISHED`, `RETIRED`)
- `certification_enrollment_status_enum` (`ENROLLED`, `IN_PROGRESS`, `READY_FOR_CLOSEOUT`, `SUBMITTED_FOR_FINAL_REVIEW`, `APPROVED`, `CERTIFIED`, `WITHDRAWN`, `EXPIRED`, `CHANGES_REQUESTED`)
- `certification_requirement_status_enum` (`DRAFT`, `SUBMITTED`, `CHANGES_REQUESTED`, `APPROVED`)
- `certification_component_type_enum` (`TEXT_RESPONSE`, `FILE_EVIDENCE`, `LINKED_HONOR`, `LINKED_ACTIVITY`, `ATTESTATION`, `AUTO_VALIDATION`)
- `certification_eligibility_rule_type_enum` (`MIN_AGE`, `BAPTIZED`, `INVESTED_CLASS`, `ACTIVE_CLUB_TYPE`, `ACTIVE_ROLE`)
- `certification_evidence_upload_status_enum` (`PENDING_UPLOAD`, `CONFIRMED`)
- `certification_review_event_type_enum` (envíos, devoluciones, aprobaciones, certificación)
- `certification_closeout_review_status_enum` (`PENDING`, `SUBMITTED`, `CHANGES_REQUESTED`, `APPROVED`)
- `camporee_order_owner_scope_enum` (`DIVISION`, `UNION`, `LOCAL_FIELD`)
- `camporee_order_size_scheme_enum` (`LETTER`, `NUMERIC`, `NONE`)
- `camporee_order_status_enum` (`ISSUED`, `PROOF_SUBMITTED`, `PROOF_REJECTED`, `PAID`, `DELIVERED`, `CANCELLED`, `EXPIRED`)
- `camporee_order_proof_status_enum` (`SUBMITTED`, `APPROVED`, `REJECTED`)
- `camporee_supply_uom_enum` (`KG`, `L`, `BAG`, `UNIT`)
- `camporee_supply_plan_status_enum` (`DRAFT`, `SUBMITTED`)
- `camporee_supply_payment_kind_enum` (`PRINCIPAL`, `CHARGE`, `REFUND`)
- `camporee_supply_payment_status_enum` (`ISSUED`, `PAID`, `CANCELLED`)

---

## Migraciones recientes

- `20261024120000_allow_coordinator_paper_form` - rama `feat/coordinator-pending-consents` (sacdia-backend, commit `74f5412c`, PR #534), mergeada en `development`. Solo DDL, escrita a mano: `DROP` y `ADD` de `guardianships_verification_method_ck` con `director_paper_form`, `coordinator_paper_form`, `guardian_invite`, `legacy_import` y `test_placeholder` (admite NULL; re-ejecutable). **Aplicada en `development` y `staging`** (2026-10-21), pendiente en `production`; hay que aplicarla antes de desplegar ese backend. Reversión solo hacia adelante una vez que existan filas con el valor nuevo. Validada el 2026-10-21 en la rama temporal `qa-coord-20261021`.
- `20261023120000_grant_consent_verify_to_coordinators` - rama `feat/coordinator-consent-verify` (sacdia-backend, PR #532, ya mergeado). Solo DML: `INSERT ... SELECT` en `role_permissions` de `consent:verify` para los roles globales `coordinator`, `zone-coordinator` y `general-coordinator` (`ON CONFLICT (role_id, permission_id) DO NOTHING`, solo roles y permiso activos). **Aplicada en `development` y `staging`** (2026-10-21), pendiente en `production`; mientras no esté aplicada en una rama, `/auth/me` no trae `consent:verify` para un coordinador. Ver «Registro por director y acceso familiar (Fase 3c)».
- `20261022130000_seed_family_permissions` - rama `feat/family-profiles-phase3`, mergeada (PR #531 de sacdia-backend). Solo DML: permisos `dependents:create` y `consent:verify` y sus asignaciones por rol (ver «Registro por director y acceso familiar (Fase 3c)»). Aplicada en `development` (2026-10-20, con aprobación del usuario; 10 asignaciones) y `staging` (2026-10-21); pendiente en `production`.
- `20261022120000_family_director_minors` - misma rama. `dependent_profiles.teen_login_nudged_at timestamptz(6)` nullable (una sentencia, aditiva). Aplicada en `development` (2026-10-20, con aprobación del usuario) y `staging` (2026-10-21); pendiente en `production`.
- `20261021120000_family_linked_devices` - rama `feat/family-profiles-phase3`, mergeada (PR #531 de sacdia-backend). Tablas `linked_devices` y `device_pairing_tokens` con sus índices, y el CHECK `supervised_logins_disabled_reason_ck` ampliado con `age_majority`. Sin DML; `sessions` no cambia. Aplicada en `development` (2026-10-20, con aprobación del usuario) y `staging` (2026-10-21); pendiente en `production`.
- `20261016120000_family_profiles` - rama `feat/family-profiles`, mergeada (PR #530 de sacdia-backend). `users.email` nullable, 3 columnas de política de edad en `countries` y las tablas `dependent_profiles`, `guardianships`, `guardianship_consent_evidences` y `guardianship_link_codes` con sus índices parciales. Sin DML. Aplicada en `development` y `staging` (2026-10-21); pendiente en `production`.
- `20261013100000_honor_instructor_proposals` (M4) - enum y tabla `honor_instructor_proposals`; índices sin `CONCURRENTLY` desde #485.
- `20261012130000_honors_completed_at` (M5) - `users_honors.completed_at`, CHECK >= 1960-01-01 y backfill determinista.
- `20261010130000_certificate_import_ocr_pages` (M2) - `page_count`, `source_page` y `source_file_id`.
- `20261010120000_certificate_import_honor_instructor` (M1) - instructor opcional en ítems de importación y en `users_honors`.
- `20260923170000_activity_audience` y `20260923160000_activity_rsvp` - audiencia y RSVP de actividades.
- `20260921190000_institutional_certificate_requests` - bandeja institucional de solicitudes de certificado.
- `20260921180000_certificate_import_revision` y `20260921170000_certificate_import_private_files` - revisión y archivos privados de la importación de certificados.
- `20260921153000_ecclesiastical_year_no_overlap` - evita años eclesiásticos solapados.
- `20260921140000_historical_certificate_enrollments` - crea `enrollment_record_kind` (`OPERATIONAL` y registros históricos) para separar los hechos históricos de certificados del slot operativo de inscripción.
- `20260915210000_grant_investiture_mark_invested_coordinators` - permiso de marcar investido para coordinadores.
- `20260909130000_director_succession_open_unique` - único parcial `uniq_director_succession_open_section_year` (planes `scheduled`/`activated`/`blocked`). Aplicada a Neon development (2026-09-11).
- `20260909120000_annual_membership_cycle` - `outgoing_assignment_id` nullable, `club_year_transitions`, único parcial member anual. Aplicada a Neon development (2026-09-11). Preflight: 0 grupos member duplicados; 2 CRA director test de `director-club@sacdia.com` cerradas (`ended`) antes de `20260908180000`.
- `20260908180000_director_year_slots` - índice único parcial `uniq_cra_director_status_section_year` (rol director CLUB, `active`+`designated` por sección+año). Aplicada a Neon development (2026-09-11).
- `20260826120000_camporee_supplies` - crea enums/tablas de insumos de sección, unique parcial plan por sección+camporee, y añade `supply_edit_cutoff_local_time` a `local_camporees` y `union_camporees`.
- `20260824190000_camporee_orders` - crea enums/tablas de pedidos de mercancía y añade `orders_enabled`/`orders_opens_at`/`orders_deadline` a `local_camporees` y `union_camporees`.
- `20260710130000_admin_auth_sessions` - **solo en la rama `codex/sacdia-admin-ios-auth`, no en `development`**; creada para metadata administrativa 1:1 sobre `sessions`, assurance, expiración absoluta y revocación; despliegue no verificado.
- `20260710200000_admin_refresh_rotation` - **solo en la rama `codex/sacdia-admin-ios-auth`**; depende de `20260710130000_admin_auth_sessions`; añade `idle_expires_at` para su adopción futura en D1c, deshabilita con sentinel las sesiones administrativas legacy y crea estructuras hash-only de refresh, historial y recibos cifrados. Existe en la rama backend, pero no fue ejecutada ni verificada contra una base de datos; no tiene writer ni publica endpoints runtime y no debe desplegarse antes de D1c + D2.
- `20260415100000_folder_templates_polymorphic_owner` - añade owners polimorficos (`owner_union_id`, `owner_local_field_id`), dropea el unique compuesto legacy y establece el CHECK/indices parciales de exactamente-un-owner.
- `20260415100100_annual_folders_camporee_link` - añade `local_camporee_id`, `union_camporee_id`, `requires_union_confirmation`, el CHECK de a-lo-mas-un-camporee y los indices asociados.
- `20260415100200_section_evaluations_dual_level` - renombra `evaluated_by_id`/`evaluated_at` a `lf_approved_by`/`lf_approved_at` (ambas nullable), añade `union_approved_by`/`union_approved_at`/`union_decision`, crea `union_evaluation_decision_enum` y el CHECK de orden LF→Union.
- `20260415100300_section_evaluations_stored_status` - crea `annual_folder_section_status_enum`, añade la columna `status` materializada con default `PENDING`, el CHECK de `PREAPPROVED_LF` y el indice analitico por estado.
- `20260415100400_annual_folders_eager_evaluation_backfill` - migracion data-only; no-op sobre dev por ausencia de datos legacy.
- `20260428000000_extended_rankings_schema` (8.4-C) - añade 5 columnas de score + `composite_calculated_at` a `club_annual_rankings`; crea `ranking_weight_configs` con CHECK sum=100 + índice único parcial; extiende `award_categories` con `min_composite_pct`, `max_composite_pct`, `is_legacy`; crea `idx_rankings_composite`; inserta configuración global default (60/15/15/10); agrega keys `ranking.finance_closing_deadline_day` y `ranking.recalculation_enabled` en `system_config`. Aplicada en los 3 branches Neon (development, staging, production).
- `20260528180000_annual_ranking_scorecard` - crea `ranking_tiers`, `annual_ranking_configs` y `annual_ranking_component_configs` para soportar rangos porcentuales globales y máximos anuales por campo local/año/tipo de club.
- `20260623160000_hierarchical_annual_ranking_configs` - agrega scope jerárquico Unión/Campo Local a `annual_ranking_configs`, reemplaza el unique local por índices parciales por scope, cambia nuevas `folder_templates` a borrador por defecto (`active=false`) y desactiva plantillas activas que no coincidan con el presupuesto efectivo de `annual_evidence_folder`.
- `20260623193000_folder_template_lifecycle` - crea `folder_template_status_enum`, añade `folder_templates.status`, backfillea `PUBLISHED` para plantillas activas y `DRAFT` para inactivas, y agrega `idx_folder_templates_status`.
- `20260629203000_camporee_location_coordinates` - agrega coordenadas opcionales `lat`/`long` a `local_camporees` y `union_camporees`, y concede `camporee_events:read` a roles operativos de club para la vista móvil de eventos.
- `20260702193000_camporee_rubric_scoring` - agrega scoring real por rúbricas, roster/asignaciones de jueces y resultados oficiales por sección/evento.
- `20260706120000_camporee_agenda_blocks` - agrega `agenda_visible_from` a camporees locales/de unión, crea bloques de agenda por evento con asignaciones a secciones inscritas y alinea seeds base de `camporee_event_types`.
- `20260707160000_camporee_staff_roster` - agrega `camporee_staff_members`, `camporee_event_staff_assignments`, cierre explícito `club_registration_closed_at/by` en camporees locales/de unión y backfill de jueces existentes hacia roster de personal.
- `20260708193000_camporee_score_no_show_and_lock` - agrega estado oficial `score_status`/`is_no_show` y `override_of_submission_id` para no-presentados, bloqueo one-shot de juez principal y overrides auditables de Campo Local.
- `20260709100000_camporee_score_idempotency` - agrega clave idempotente y hash canónico por actor, auditoría de total crudo/ajuste mínimo, índice único parcial y backfill histórico conservador (`raw=total oficial`, `ajuste=0`).
- `20260709110000_camporee_lifecycle_timezone` - agrega apertura temporal de clubes, timezone IANA y auditoría de su verificación a camporees locales/de unión; backfillea el default provisional `America/Mexico_City` sin reescribir fechas ni deadlines históricos.
- `20260531203000_annual_ranking_axes` - crea `annual_ranking_axis_configs`, asocia componentes a ejes administrativo/operativo, y conserva componentes legacy desconocidos como inactivos para remediación manual sin asignarlos silenciosamente a un eje.
- `20260429000000_enrollment_rankings_schema` - (8.4-A) crea `enrollment_rankings`, `section_rankings`, `enrollment_ranking_weights` con indexes, UNIQUE constraints y CHECK constraints de rango [0,100]. Ver §14.1 de `docs/canon/runtime-rankings.md`.
- `20260429000001_award_categories_scope` - (8.4-A) añade `scope VARCHAR(20) DEFAULT 'club'` a `award_categories` + índice `idx_award_categories_scope` on `(scope, is_legacy)`. Backfill: filas existentes → `scope='club'`.
- `20260429000002_enrollment_rankings_seeds` - (8.4-A) seed de fila global `is_default=true` en `enrollment_ranking_weights` con pesos 50/30/20 (class/investiture/camporee).
- `20260521120000_class_duration_availability` - añade disponibilidad por año eclesiástico y duración min/max a `classes`; agrega `EXPIRED` a enums de investidura.
- `20260604000000_master_honor_requirements` - agrega reglas configurables de maestrías (`applicability_scope`, `philosophy`, `notes`) y tablas `master_honor_divisions`, `master_honor_requirement_groups`, `master_honor_requirement_options`, `master_honor_requirement_option_honors`, `users_master_honors`, `master_honor_evaluation_history`.
- `20260612000000_honor_applicability_and_class_links` - agrega `honors.code`, `honor_club_types`, `class_honors` y `class_honor_relation_type_enum`; backfill de aplicabilidad desde `honors.club_type_id` y códigos legacy para honores existentes.
- `20260828120000_camporee_event_honors` - tabla puente `camporee_event_honors` para especialidades de preparación en instancias de evento (consultivo, sin gate). Aplicada en Neon development/staging/production el 2026-08-28.
- `20260828140000_class_honors_module` - añade `class_honors.module_id` nullable FK a `class_modules` (`ON DELETE SET NULL`) para anclar especialidades a un módulo. Informativo: no bloquea progreso ni investidura. Aplicada en Neon development/staging/production el 2026-08-28.
- `20260811200000_class_prerequisites` - agrega `class_prerequisites` con FKs a `classes`, unique `(class_id, prerequisite_class_id)` y CHECK anti-auto-referencia.
- `20260429000003_enrollment_rankings_default_award_seeds` - (8.4-A) seed de categorías de premio con `scope='member'` para clasificación de miembros.

## Nota operativa

- Para detalle estructural exacto, usar `docs/database/schema.prisma` o `sacdia-backend/prisma/schema.prisma`.
- Si esta referencia contradice el schema Prisma real, el schema real gana y esta pagina debe resincronizarse.
