# Schema Reference - SACDIA Database

**Estado**: ACTIVE
**Sincronizado contra**: `sacdia-backend/prisma/schema.prisma` (checkout principal) **más** modelos `camporee_order_*` de `feat/camporee-orders` y `camporee_supply_*` de `feat/camporee-supplies` (worktree `/private/tmp/sacdia-backend-camporee-orders`; no Neon)
**Fecha de resincronizacion**: 2026-08-28 (`20260828140000_class_honors_module` aplicada en Neon development/staging/production; `20260828120000_camporee_event_honors` ya estaba aplicada en las tres)

Referencia humana concisa del schema Prisma vigente.

> [!IMPORTANT]
> La autoridad estructural efectiva sigue siendo `sacdia-backend/prisma/schema.prisma`.
> `docs/database/schema.prisma` debe permanecer como espejo documental fiel del mismo archivo.

---

## Cifras vigentes

- **Modelos Prisma**: 200 (checkout `feat/camporee-event-honors` incluye `camporee_event_honors`; 199 en `development` + pedidos/insumos en ramas previas)
- **Enums Prisma**: 44 (36 del checkout principal + 4 de camporee-orders + 4 de camporee-supplies en la misma worktree)
- **Tablas Better Auth mapeadas**: `session -> sessions`, `account -> accounts`, `verification -> verifications`

---

## Correcciones de drift relevantes

### `users`

- Incluye `email_verified`, `approval_status` y `rejection_reason`.
- Mantiene `access_app`, `access_panel`, `country_id`, `union_id`, `local_field_id`.
- Ya no usa los flags legacy `apple_connected`, `fb_connected` ni `google_connected`.

### `users_pr`

- Incluye `active_club_assignment_id` ademas del tracking de post-registro.
- No existe tabla dedicada para credenciales QR: el contrato canónico nuevo usa JWT stateless y, por ahora, solo `users_pr`/`club_role_assignments` para resolver contexto visual y autorizacion.

### `club_sections`

- Es la estructura vigente para secciones de club.
- Cada club tiene una fila por tipo de catálogo activo (`club_types`); no tiene nombre propio. La etiqueta visible es `{clubs.name} · {club_types.name}`.
- `active` indica si el club opera esa sección. Unirse, post-registro, camporee y QR solo usan secciones activas.
- Incluye datos operativos propios (`phone`, `email`, `website`, `logo_url`, `address`, `lat`, `long`).
- La unicidad vigente es `@@unique([main_club_id, club_type_id])`.

### `club_role_assignments`

- La relacion operativa es contra `club_section_id`.
- Incluye `expires_at` y `rejection_reason`.
- La unicidad vigente es `@@unique([user_id, role_id, club_section_id, ecclesiastical_year_id, start_date])`.
- Tambien soporta el flujo de membership requests via `status` (`pending`, `active`, `rejected`, `expired`) sobre la misma asignacion anual.

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

- `weekly_records` materializa `unit_id`, usuario, semana ISO, total de puntos, `created_by` y `active` por `unit_id + user_id + week + year`. `attendance` y `punctuality` quedan como columnas legacy de compatibilidad y no son fuente del total.
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
| `enrollments` | `(ecclesiastical_year_id, investiture_status, active)`; parcial `(status, submitted_at) WHERE active` | validación por año + overdue SLA |
| `club_role_assignments` | `(ecclesiastical_year_id, active, status)` | dashboard de personas |
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

- `activities` incluye `activity_date`, `activity_end_date`, `reminder_sent`, `activity_type_id`, `club_section_id`, `is_joint` y `activity_series_id` (nullable). Unique parcial `(activity_series_id, activity_date)` cuando hay serie.
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

Insumos de sección (migración `20260826120000_camporee_supplies` aplicada en Neon development/staging/production el 2026-08-28). No reutiliza tablas de `camporee_orders`. Unique parcial plan `(sección, camporee)` vive en SQL, no en `@@unique` Prisma.

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

Pedidos de mercancía nominados (migración `20260824190000_camporee_orders` en rama `feat/camporee-orders`; **no aplicada a Neon**). Fuente estructural de la rama: worktree `/private/tmp/sacdia-backend-camporee-orders/prisma/schema.prisma`. El checkout `sacdia-backend` principal no incluye estas tablas.

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
- `achievement_event_log` — journal de eventos procesados por el evaluador. Guarda `event_type`, `user_id`, `payload` JSON, flag `processed` e indices por `(user_id, event_type, created_at)` y por eventos pendientes `(processed, created_at)` para el worker de BullMQ. Sin BullMQ disponible, el evento queda persistido pero no encolado.
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

### `admin_auth_sessions` (rama backend)

- Extiende `sessions` con una relación opcional 1:1: `session_id` es PK/FK y usa borrado en cascada.
- Mantiene `surface='admin'`, `client_type='ios'`, `family_id`, assurance `aal1|aal2`, expiración absoluta, expiración inactiva (`idle_expires_at`) y datos de revocación; el DDL aplica los checks correspondientes.
- `idle_expires_at` está diseñado para convertirse en la autoridad de expiración por inactividad cuando D1c adopte el writer y la lectura runtime. En el estado actual de la rama, `AdminSessionRepository.isActiveForToken` todavía valida `sessions.expires_at` de Better Auth; por tanto, esa fecha aún no es solo un espejo de compatibilidad.
- `active_assignment_id` es opcional, referencia `club_role_assignments` y usa `ON DELETE SET NULL`.
- Incluye índices para `family_id`, `revoked_at` y `active_assignment_id`.
- La migración existe únicamente en la rama backend `codex/sacdia-admin-ios-auth`; su despliegue no fue verificado y la tabla todavía no forma parte del runtime de referencia.

### Persistencia de refresh administrativo (rama backend)

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
- `admin_auth_sessions` (definida en rama backend; no publicada en el runtime de referencia)
- `admin_refresh_tokens`, `admin_refresh_token_history`, `admin_refresh_rotation_receipts` (definidas en rama backend; no publicadas en el runtime de referencia)

### Usuarios y salud

- `users`, `legal_representatives`, `emergency_contacts`, `relationship_types`
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

- `honors`, `honors_categories`, `master_honors`, `users_honors`
- `honor_club_types`, `class_honors`, `class_prerequisites`
- `honor_requirements`, `user_honor_requirement_progress`, `requirement_evidence`, `evidence_files`
- `master_honor_divisions`, `master_honor_requirement_groups`, `master_honor_requirement_options`, `master_honor_requirement_option_honors`
- `users_master_honors`, `master_honor_evaluation_history`

### Actividades, camporees e inventario

- `activity_types`, `activities`, `activity_instances`
- `local_camporees`, `union_camporees`, `union_camporee_local_fields`, `camporee_clubs`, `camporee_members`, `camporee_payments`
  - `local_camporees` y `union_camporees` guardan dirección textual (`local_camporee_place` / `union_camporee_place`), coordenadas opcionales (`lat`, `long`) para vista de mapa en app, `agenda_visible_from` para abrir agenda completa antes/durante el camporee y `club_registration_closed_at/by` para congelar secciones competitivas.
  - En rama `feat/camporee-orders` ambos modelos añaden `orders_enabled` (default `false`), `orders_opens_at` y `orders_deadline` para la ventana de pedidos de mercancía. Migración no aplicada a Neon.
  - En rama `feat/camporee-supplies` ambos modelos añaden `supply_edit_cutoff_local_time VARCHAR(5) DEFAULT '21:00'` para el freeze de insumos. Migración `20260826120000_camporee_supplies` aplicada en Neon development (previa) y staging/production el 2026-08-28.
  - Ambos modelos incluyen `club_registration_opens_at TIMESTAMPTZ NULL` (nulo = apertura inmediata), deadlines `TIMESTAMPTZ`, y `timezone` IANA con default histórico provisional `America/Mexico_City`. `timezone_verified_at/by` audita la confirmación; `timezone_verified_by` tiene FK nombrada a `users(user_id)`, `ON DELETE SET NULL` e índice por tabla. El backfill no modifica fechas ni deadlines históricos.
  - Los eventos del camporee viven en `camporee_events` y se relacionan con camporee local o de unión mediante FK excluyentes.
  - Bloques opcionales de agenda viven en `camporee_event_schedule_blocks`; sus asignaciones por sección inscrita viven en `camporee_event_schedule_block_assignments`.
  - El roster operativo vive en `camporee_staff_members`; cada fila apunta a un usuario y exactamente un camporee local o de unión, con categoría descriptiva (`judge`, `administrative`, `kitchen`, `support`, `spiritual`, `leadership`, `other`).
  - Las asignaciones de personas a actividades viven en `camporee_event_staff_assignments`; permiten roles `responsible`, `assistant`, `evaluator` y `support`, sin forzar todos los roles en cada evento.
  - Especialidades de preparación viven en `camporee_event_honors` (`camporee_event_id` + `honor_id`, unique, `display_order`). Consultivo: no inscribe ni bloquea. Máx. 20. FK honor `ON DELETE RESTRICT`. Rama `feat/camporee-event-honors`; migración `20260828120000_camporee_event_honors` aplicada en Neon development/staging/production el 2026-08-28.
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
- `folder_template_status_enum` (`DRAFT`, `PUBLISHED`, `ARCHIVED`)
- `honor_validation_status_enum`
- `insurance_type_enum`
- `investiture_action_enum`
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
- `camporee_order_owner_scope_enum` (`DIVISION`, `UNION`, `LOCAL_FIELD`) — rama `feat/camporee-orders`, no Neon
- `camporee_order_size_scheme_enum` (`LETTER`, `NUMERIC`, `NONE`)
- `camporee_order_status_enum` (`ISSUED`, `PROOF_SUBMITTED`, `PROOF_REJECTED`, `PAID`, `DELIVERED`, `CANCELLED`, `EXPIRED`)
- `camporee_order_proof_status_enum` (`SUBMITTED`, `APPROVED`, `REJECTED`)
- `camporee_supply_uom_enum` (`KG`, `L`, `BAG`, `UNIT`) — rama `feat/camporee-supplies`, no Neon
- `camporee_supply_plan_status_enum` (`DRAFT`, `SUBMITTED`)
- `camporee_supply_payment_kind_enum` (`PRINCIPAL`, `CHARGE`, `REFUND`)
- `camporee_supply_payment_status_enum` (`ISSUED`, `PAID`, `CANCELLED`)

---

## Migraciones recientes

- `20260826120000_camporee_supplies` - crea enums/tablas de insumos de sección, unique parcial plan por sección+camporee, y añade `supply_edit_cutoff_local_time` a `local_camporees` y `union_camporees`. Existe en `feat/camporee-supplies` (worktree `/private/tmp/sacdia-backend-camporee-orders`); **no ejecutada ni verificada contra Neon**.
- `20260824190000_camporee_orders` - crea enums/tablas de pedidos de mercancía y añade `orders_enabled`/`orders_opens_at`/`orders_deadline` a `local_camporees` y `union_camporees`. Existe en `feat/camporee-orders` (worktree); **no ejecutada ni verificada contra Neon**.
- `20260710130000_admin_auth_sessions` - creada en la rama backend para metadata administrativa 1:1 sobre `sessions`, assurance, expiración absoluta y revocación; despliegue no verificado.
- `20260710200000_admin_refresh_rotation` - depende de `20260710130000_admin_auth_sessions`; añade `idle_expires_at` para su adopción futura en D1c, deshabilita con sentinel las sesiones administrativas legacy y crea estructuras hash-only de refresh, historial y recibos cifrados. Existe en la rama backend, pero no fue ejecutada ni verificada contra una base de datos; no tiene writer ni publica endpoints runtime y no debe desplegarse antes de D1c + D2.
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
