# Schema Reference - SACDIA Database

**Estado**: ACTIVE
**Sincronizado contra**: `sacdia-backend/prisma/schema.prisma`
**Fecha de resincronizacion**: 2026-04-14

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

### Better Auth

- Los modelos Prisma vigentes son `session`, `account` y `verification`.
- En base fisica se mapean a `sessions`, `accounts` y `verifications` via `@@map`.

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
- `user_approval_status`

---

## Nota operativa

- Para detalle estructural exacto, usar `docs/database/schema.prisma` o `sacdia-backend/prisma/schema.prisma`.
- Si esta referencia contradice el schema Prisma real, el schema real gana y esta pagina debe resincronizarse.
