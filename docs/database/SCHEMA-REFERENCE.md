# Schema Reference - SACDIA Database

**Estado**: ACTIVE
**Sincronizado contra**: `sacdia-backend/prisma/schema.prisma`
**Fecha de resincronizacion**: 2026-04-15 (achievements: notas operativas agregadas)

Referencia humana concisa del schema Prisma vigente.

> [!IMPORTANT]
> La autoridad estructural efectiva sigue siendo `sacdia-backend/prisma/schema.prisma`.
> `docs/database/schema.prisma` debe permanecer como espejo documental fiel del mismo archivo.

---

## Cifras vigentes

- **Modelos Prisma**: 106
- **Enums Prisma**: 14
- **Tablas Better Auth mapeadas**: `session -> sessions`, `account -> accounts`, `verification -> verifications`

---

## Correcciones de drift relevantes

### `users`

- Incluye `email_verified`, `approval_status` y `rejection_reason`.
- Mantiene `access_app`, `access_panel`, `country_id`, `union_id`, `local_field_id`.
- Ya no usa los flags legacy `apple_connected`, `fb_connected` ni `google_connected`.

### `users_pr`

- Incluye `active_club_assignment_id` ademas del tracking de post-registro.

### `club_sections`

- Es la estructura vigente para secciones de club.
- Incluye datos operativos propios (`name`, `phone`, `email`, `website`, `logo_url`, `address`, `lat`, `long`).
- La unicidad vigente es `@@unique([main_club_id, club_type_id])`.

### `club_role_assignments`

- La relacion operativa es contra `club_section_id`.
- Incluye `expires_at` y `rejection_reason`.
- La unicidad vigente es `@@unique([user_id, role_id, club_section_id, ecclesiastical_year_id, start_date])`.
- Tambien soporta el flujo de membership requests via `status` (`pending`, `active`, `rejected`, `expired`) sobre la misma asignacion anual.

### `weekly_records`, `weekly_record_scores` y `scoring_categories`

- `weekly_records` materializa asistencia, puntualidad, total de puntos, `created_by` y `active` por `user_id + week + year`.
- `weekly_record_scores` guarda el desglose por categoria con unicidad `(record_id, category_id)`.
- `scoring_categories` define categorias heredadas o propias por `origin_level` + `origin_id`.

### `member_of_month`

- Persiste ganadores por `club_section_id`, `month` y `year`; admite empates porque la unicidad incluye `user_id`.
- Incluye `total_points` y `notified` para el tracking de notificaciones.

### `monthly_reports` y `monthly_report_manual_data`

- `monthly_reports` usa `monthly_report_id` UUID y relacion obligatoria a `club_enrollments.club_enrollment_id` (tambien UUID).
- La unicidad vigente es `@@unique([club_enrollment_id, month, year])`.
- El estado es `String` con default `draft`; el runtime backend verificado usa `draft`, `generated` y `submitted`.
- `snapshot_data` es `Json?` y guarda el snapshot congelado del preview auto-calculado.
- `submitted_by` referencia `users.user_id` y permite identificar al submitter cuando el informe pasa a `submitted`.
- `monthly_report_manual_data` es one-to-one por `monthly_report_id` (`@unique`) y se elimina en cascada si se elimina el informe padre.
- Los campos manuales vigentes son administrativos, misioneros y de seguimiento; no coinciden con algunos payloads legacy de clientes.

### `system_config`

- Incluye configuracion operativa general.
- Membership requests usa la key `membership.pending_timeout_days` para expirar solicitudes pendientes.

### `activities` y `activity_instances`

- `activities` incluye `activity_date`, `activity_end_date`, `reminder_sent`, `activity_type_id`, `club_section_id` e `is_joint`.
- `activity_instances` sigue vigente para materializar una actividad por seccion.

### `finances`

- Incluye `modified_by_id`, `club_section_id` y `post_closing_note`.
- La relacion principal es con `club_sections`, no con tablas legacy separadas por tipo.

### `member_insurances`

- Incluye `created_by_id`, `modified_by_id`, `evidence_file_url` y `evidence_file_name`.
- Sigue relacionada con `camporee_members`.

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

### `folder_templates`

- Ownership polimorfico: incluye `owner_union_id` y `owner_local_field_id`, ambos nullable con FK a `unions(union_id)` y `local_fields(local_field_id)` respectivamente (`ON DELETE RESTRICT`).
- Ya no existe el unique compuesto `(club_type_id, ecclesiastical_year_id)`; cada tipo-anio puede convivir con una plantilla por union y una por campo local.
- El CHECK `folder_templates_exactly_one_owner_check` obliga a que exactamente uno de los owners este presente.
- La unicidad efectiva se enforce via dos indices unicos parciales: `folder_templates_union_owner_unique` sobre `(club_type_id, ecclesiastical_year_id, owner_union_id) WHERE owner_union_id IS NOT NULL` y `folder_templates_local_field_owner_unique` sobre `(club_type_id, ecclesiastical_year_id, owner_local_field_id) WHERE owner_local_field_id IS NOT NULL`.
- Indices btree de apoyo: `idx_folder_templates_owner_union`, `idx_folder_templates_owner_local_field`.

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

---

## Inventario resumido por dominio

### Organizacion y clubes

- `countries`, `unions`, `local_fields`, `districts`, `churches`, `clubs`, `club_sections`, `club_types`, `club_ideals`, `units`, `unit_members`

### RBAC y auth

- `roles`, `permissions`, `role_permissions`, `users_roles`, `users_permissions`, `club_role_assignments`, `role_slot_limits`, `role_assignment_requests`
- `session`, `account`, `verification`, `users_pr`, `notification_preferences`, `notification_logs`, `user_fcm_tokens`

### Usuarios y salud

- `users`, `legal_representatives`, `emergency_contacts`, `relationship_types`
- `allergies`, `diseases`, `medicines`, `users_allergies`, `users_diseases`, `users_medicines`
- `member_insurances`

### Formacion

- `classes`, `class_modules`, `class_sections`, `enrollments`, `class_module_progress`, `class_section_progress`
- `certifications`, `certification_modules`, `certification_sections`, `users_certifications`, `certification_module_progress`, `certification_section_progress`
- `investiture_config`, `investiture_validation_history`, `validation_logs`

### Honores y evidencias

- `honors`, `honors_categories`, `master_honors`, `users_honors`
- `honor_requirements`, `user_honor_requirement_progress`, `requirement_evidence`, `evidence_files`

### Actividades, camporees e inventario

- `activity_types`, `activities`, `activity_instances`
- `local_camporees`, `union_camporees`, `union_camporee_local_fields`, `camporee_clubs`, `camporee_members`, `camporee_payments`
- `inventory_categories`, `club_inventory`, `inventory_history`

### Finanzas y carpetas

- `finances`, `finances_categories`, `FinancePeriodClosing`
- `folders`, `folders_modules`, `folders_sections`, `folder_assignments`, `folders_modules_records`, `folders_section_records`

### Enrollment anual, ranking y reportes

- `club_enrollments`, `folder_templates`, `folder_template_sections`
- `annual_folders`, `annual_folder_evidences`, `annual_folder_section_evaluations`, `annual_folder_section_submissions`
- `award_categories`, `club_annual_rankings`, `monthly_reports`, `monthly_report_manual_data`, `member_of_month`, `weekly_records`, `scoring_categories`, `weekly_record_scores`
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
- `honor_validation_status_enum`
- `insurance_type_enum`
- `investiture_action_enum`
- `investiture_status_enum`
- `origin_level_enum`
- `role_category`
- `union_evaluation_decision_enum` (`APPROVED`, `REJECTED_OVERRIDE`)
- `user_approval_status`

---

## Migraciones recientes

- `20260415100000_folder_templates_polymorphic_owner` - añade owners polimorficos (`owner_union_id`, `owner_local_field_id`), dropea el unique compuesto legacy y establece el CHECK/indices parciales de exactamente-un-owner.
- `20260415100100_annual_folders_camporee_link` - añade `local_camporee_id`, `union_camporee_id`, `requires_union_confirmation`, el CHECK de a-lo-mas-un-camporee y los indices asociados.
- `20260415100200_section_evaluations_dual_level` - renombra `evaluated_by_id`/`evaluated_at` a `lf_approved_by`/`lf_approved_at` (ambas nullable), añade `union_approved_by`/`union_approved_at`/`union_decision`, crea `union_evaluation_decision_enum` y el CHECK de orden LF→Union.
- `20260415100300_section_evaluations_stored_status` - crea `annual_folder_section_status_enum`, añade la columna `status` materializada con default `PENDING`, el CHECK de `PREAPPROVED_LF` y el indice analitico por estado.
- `20260415100400_annual_folders_eager_evaluation_backfill` - migracion data-only; no-op sobre dev por ausencia de datos legacy.
- `20260429000000_enrollment_rankings_schema` - (8.4-A) crea `enrollment_rankings`, `section_rankings`, `enrollment_ranking_weights` con indexes, UNIQUE constraints y CHECK constraints de rango [0,100]. Ver §13.1 de `docs/canon/runtime-rankings.md`.
- `20260429000001_award_categories_scope` - (8.4-A) añade `scope VARCHAR(20) DEFAULT 'club'` a `award_categories` + índice `idx_award_categories_scope` on `(scope, is_legacy)`. Backfill: filas existentes → `scope='club'`.
- `20260429000002_enrollment_rankings_seeds` - (8.4-A) seed de fila global `is_default=true` en `enrollment_ranking_weights` con pesos 50/30/20 (class/investiture/camporee).
- `20260429000003_enrollment_rankings_default_award_seeds` - (8.4-A) seed de categorías de premio con `scope='member'` para clasificación de miembros.

## Nota operativa

- Para detalle estructural exacto, usar `docs/database/schema.prisma` o `sacdia-backend/prisma/schema.prisma`.
- Si esta referencia contradice el schema Prisma real, el schema real gana y esta pagina debe resincronizarse.
