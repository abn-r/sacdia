# ENDPOINTS LIVE REFERENCE (Runtime Truth)

<!-- Generado estáticamente contra sacdia-backend/src/**/*controller.ts el 2026-07-07. Resincronizado contra la rama development (commit 66f4ade) el 2026-10-04: conteos recalculados con el mismo extractor estático de decoradores, 12 rutas reales añadidas y 20 rutas de la rama feat/investiture-authorization-ocr marcadas como pendientes de merge. No se levantó la app ni se ejecutó build. -->

> [!IMPORTANT]
> Documento canónico operativo para clientes SACDIA. Base URL: `/api/v1`.
> La tabla refleja los decoradores HTTP efectivos en controllers NestJS; DTOs, ejemplos y errores finos viven en Swagger/runtime y docs de feature cuando aplique.

**Estado**: ACTIVE
**Actualizado**: 2026-10-04
**Total endpoints**: 866 decoradores HTTP en 108 archivos `*.controller.ts` de `development`. La matriz tiene además 20 filas **pendientes de merge (PR #448 de sacdia-backend)**: secciones `class-thresholds`, `investiture-windows`, `investiture-pastors`, `investiture-requests` y el `GET .../sections/:clubSectionId/score` de camporee-scoring.
**Métodos (development)**: GET 353 · POST 279 · PATCH 125 · DELETE 96 · PUT 13
**Auth detectada (development)**: Public 13 · JWT u Optional JWT 853

## Cómo leer esta referencia

- `Auth`: `JWT` cuando el controller/método declara `JwtAuthGuard`, `AuthGuard` o `ApiBearerAuth`; `Public` cuando no se detecta guard bearer en el controller/método.
- `Roles/Permisos`: combina `@RequirePermissions`, `@GlobalRoles`, `@ClubRoles` y `@Roles` detectados a nivel clase/método. Celda `-` en un endpoint JWT significa `@SkipPermissions` (JWT es el lock: picker post-registro, self-service o superficie `GlobalRoles`).
- Runtime: `PermissionsGuard` es `APP_GUARD` fail-closed. Un handler JWT nuevo sin `@RequirePermissions`, `@SkipPermissions` o `@Public` no queda abierto.
- `Uso`: sale de `@ApiOperation.summary` cuando existe; si no existe, se infiere desde el nombre del handler y el método HTTP.
- `Uso backend`: primeras llamadas a servicios/repositorios inyectados detectadas en el handler. `-` significa que el handler responde inline o usa lógica privada no capturada por esta extracción estática.
- `Source`: controller de origen para verificar el contrato antes de tocar clientes.

## Resumen por dominio

Conteo de filas por sección de la matriz. Las filas marcadas como pendientes de merge no cuentan en el total de `development`.

| Dominio/API tag | Endpoints |
| --- | ---: |
| Achievements | 4 |
| Admin - Achievements | 12 |
| activities | 16 |
| admin-auth | 6 |
| admin-camporee-event-types | 4 |
| admin | 2 |
| admin-audit-logs | 2 |
| admin-geography | 24 |
| Admin - Honors Requirements | 7 |
| admin-notifications | 3 |
| Admin - Phase E Catalogs (i18n) | 36 |
| admin-reference | 38 |
| admin-users | 7 |
| analytics | 8 |
| Annual Evidence Folders | 13 |
| Annual Evidence Folders - Templates | 9 |
| Award Categories | 5 |
| Annual Evidence Folders - Evaluation | 5 |
| Annual Evidence Folders - Rankings | 4 |
| annual-reports | 9 |
| app.controller.ts | 1 |
| auth | 20 |
| OAuth | 5 |
| camporee-event-templates | 5 |
| camporee-events | 16 |
| camporee-scoring | 19 (+1 pendiente de merge, PR #448) |
| camporee-staff | 8 |
| camporee-venues | 9 |
| camporees | 50 |
| catalogs | 16 |
| admin-certificate-bulk-imports | 6 |
| certificate-bulk-imports | 13 |
| certificate-import-institutional-requests | 3 |
| admin-certificate-import-institutional-requests | 4 |
| certifications | 27 |
| Admin - Certifications | 10 |
| class-counselor-assignments | 4 |
| class-progress-scope | 2 |
| class-thresholds (pendiente de merge, PR #448) | 2 |
| investiture-windows (pendiente de merge, PR #448) | 2 |
| investiture-pastors (pendiente de merge, PR #448) | 6 |
| investiture-requests (pendiente de merge, PR #448) | 8 |
| classes | 4 |
| user-classes | 7 |
| club-enrollments | 7 |
| clubs | 20 |
| club-roles | 2 |
| admin-coordination | 9 |
| coordination | 1 |
| dashboard | 1 |
| data-export | 3 |
| emergency-contacts | 5 |
| evidence-review | 7 |
| finances | 9 |
| health | 2 |
| honors | 5 |
| user-honors | 15 |
| user-master-honors | 3 |
| insurance | 18 |
| field-payment-orders | 19 |
| camporee order products | 6 |
| camporee order offerings | 6 |
| camporee orders | 14 |
| payment obligations | 1 |
| camporee supplies | 29 |
| inventory | 8 |
| investiture | 20 |
| legal-representatives | 4 |
| Materials — Catalog | 4 |
| Materials — Categories (admin) | 4 |
| Materials — Config | 4 |
| Materials — Inventory | 5 |
| Materials — Orders | 8 |
| Materials — Receipts | 4 |
| member-of-month | 4 |
| annual-membership | 3 |
| membership-requests | 3 |
| monthly-reports | 10 |
| Notifications | 10 |
| FCM Tokens | 5 |
| User Notification Preferences | 4 |
| post-registration | 6 |
| qr | 6 |
| quarterly-reports | 9 |
| Ranking Weights | 5 |
| Annual Ranking Configs | 4 |
| Annual Ranking Progress | 1 |
| Annual Rankings | 1 |
| Ranking Tiers | 2 |
| Member Ranking Weights | 5 |
| Member Rankings | 4 |
| Section Rankings | 2 |
| rbac | 19 |
| rbac-bootstrap | 1 |
| requests | 8 |
| resource-categories | 5 |
| Resources (App) | 3 |
| Resources | 8 |
| scoring-categories | 12 |
| admin-support | 3 |
| support | 1 |
| system-config | 3 |
| units | 11 |
| users | 15 |
| validation | 5 |
| year-end | 2 |

## Endpoint matrix

### Achievements

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/achievements/me` | JWT | - | Get current user's achievements with progress | AchievementsService.getUserAchievements() | `src/achievements/achievements.controller.ts` |
| GET | `/api/v1/achievements/categories` | JWT | - | List active achievement categories | AchievementsService.findActiveCategories() | `src/achievements/achievements.controller.ts` |
| GET | `/api/v1/achievements` | JWT | - | List all active achievements grouped by category | AchievementsService.findAllAchievements(), AchievementsService.getCompletedAchievementIds() | `src/achievements/achievements.controller.ts` |
| GET | `/api/v1/achievements/:achievementId` | JWT | - | Get achievement detail with user progress | AchievementsService.getAchievementDetail() | `src/achievements/achievements.controller.ts` |

### Admin - Achievements

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/achievements/stats` | JWT | Global: admin, super-admin; Permisos: achievements:manage | Get achievement dashboard stats | AdminAchievementsService.getStats() | `src/achievements/admin/admin-achievements.controller.ts` |
| GET | `/api/v1/admin/achievements/categories` | JWT | Global: admin, super-admin; Permisos: achievements:manage | List all achievement categories (admin view) | AdminAchievementsService.getCategories() | `src/achievements/admin/admin-achievements.controller.ts` |
| POST | `/api/v1/admin/achievements/categories` | JWT | Global: admin, super-admin; Permisos: achievements:manage | Create a new achievement category | AdminAchievementsService.createCategory() | `src/achievements/admin/admin-achievements.controller.ts` |
| PATCH | `/api/v1/admin/achievements/categories/:categoryId` | JWT | Global: admin, super-admin; Permisos: achievements:manage | Update an achievement category | AdminAchievementsService.updateCategory() | `src/achievements/admin/admin-achievements.controller.ts` |
| DELETE | `/api/v1/admin/achievements/categories/:categoryId` | JWT | Global: admin, super-admin; Permisos: achievements:manage | Soft-delete a category | AdminAchievementsService.deleteCategory() | `src/achievements/admin/admin-achievements.controller.ts` |
| GET | `/api/v1/admin/achievements` | JWT | Global: admin, super-admin; Permisos: achievements:manage | List all achievements (admin view, paginated) | AdminAchievementsService.getAchievements() | `src/achievements/admin/admin-achievements.controller.ts` |
| POST | `/api/v1/admin/achievements` | JWT | Global: admin, super-admin; Permisos: achievements:manage | Create a new achievement | AdminAchievementsService.createAchievement() | `src/achievements/admin/admin-achievements.controller.ts` |
| GET | `/api/v1/admin/achievements/:achievementId` | JWT | Global: admin, super-admin; Permisos: achievements:manage | Get a single achievement by ID (admin view) | AdminAchievementsService.getAchievementById() | `src/achievements/admin/admin-achievements.controller.ts` |
| PATCH | `/api/v1/admin/achievements/:achievementId` | JWT | Global: admin, super-admin; Permisos: achievements:manage | Update an achievement | AdminAchievementsService.updateAchievement() | `src/achievements/admin/admin-achievements.controller.ts` |
| DELETE | `/api/v1/admin/achievements/:achievementId` | JWT | Global: admin, super-admin; Permisos: achievements:manage | Soft-delete an achievement | AdminAchievementsService.deleteAchievement() | `src/achievements/admin/admin-achievements.controller.ts` |
| POST | `/api/v1/admin/achievements/:achievementId/image` | JWT | Global: admin, super-admin; Permisos: achievements:manage | Upload badge image for an achievement | AdminAchievementsService.uploadBadgeImage() | `src/achievements/admin/admin-achievements.controller.ts` |
| POST | `/api/v1/admin/achievements/retroactive/:achievementId` | JWT | Global: admin, super-admin; Permisos: achievements:manage | Trigger retroactive achievement evaluation | AdminAchievementsService.triggerRetroactiveEvaluation() | `src/achievements/admin/admin-achievements.controller.ts` |

### activities

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/clubs/:clubId/activities` | JWT | Permisos: activities:read | Listar actividades del club | ActivitiesService.findByClub() | `src/activities/activities.controller.ts` |
| POST | `/api/v1/clubs/:clubId/activities` | JWT | Permisos: activities:create; Club: director, deputy-director, secretary, secretary-treasurer, counselor | Crear actividad | ActivitiesService.create() | `src/activities/activities.controller.ts` |
| POST | `/api/v1/clubs/:clubId/activity-series/preview` | JWT | Permisos: activities:create; Club: director, deputy-director, secretary, secretary-treasurer, counselor | Vista previa de serie de actividades | ActivitiesService.previewActivitySeries() | `src/activities/activities.controller.ts` |
| POST | `/api/v1/clubs/:clubId/activity-series` | JWT | Permisos: activities:create; Club: director, deputy-director, secretary, secretary-treasurer, counselor | Crear serie de actividades | ActivitiesService.createActivitySeries() | `src/activities/activities.controller.ts` |
| GET | `/api/v1/activity-series/:seriesId` | JWT | Permisos: activities:read | Obtener serie de actividades | ActivitiesService.findActivitySeries() | `src/activities/activities.controller.ts` |
| POST | `/api/v1/activity-series/:seriesId/cancel-future` | JWT | Permisos: activities:delete | Cancelar sesiones futuras de una serie | ActivitiesService.cancelFutureActivitySeries() | `src/activities/activities.controller.ts` |
| POST | `/api/v1/activity-series/:seriesId/extend` | JWT | Permisos: activities:create | Agregar más sesiones a una serie | ActivitiesService.extendActivitySeries() | `src/activities/activities.controller.ts` |
| GET | `/api/v1/activities/:activityId` | JWT | Permisos: activities:read | Obtener actividad por ID | ActivitiesService.findOne() | `src/activities/activities.controller.ts` |
| PATCH | `/api/v1/activities/:activityId` | JWT | Permisos: activities:update | Actualizar actividad | ActivitiesService.update() | `src/activities/activities.controller.ts` |
| DELETE | `/api/v1/activities/:activityId` | JWT | Permisos: activities:delete | Desactivar actividad | ActivitiesService.remove() | `src/activities/activities.controller.ts` |
| POST | `/api/v1/activities/:activityId/image` | JWT | Permisos: activities:update | Subir imagen de actividad | ActivitiesService.uploadImage() | `src/activities/activities.controller.ts` |
| POST | `/api/v1/activities/:activityId/attendance` | JWT | Permisos: attendance:manage | Registrar asistencia confirmada. En virtual solo miembros de la sección | ActivitiesService.recordAttendance() | `src/activities/activities.controller.ts` |
| GET | `/api/v1/activities/:activityId/attendance` | JWT | Permisos: attendance:read | Obtener asistencia confirmada | ActivitiesService.getAttendance() | `src/activities/activities.controller.ts` |
| GET | `/api/v1/activities/:activityId/rsvp` | JWT | Permisos: activities:read | Intención de asistencia del usuario (solo virtual) | ActivitiesService.getMyRsvp() | `src/activities/activities.controller.ts` |
| PUT | `/api/v1/activities/:activityId/rsvp` | JWT | Permisos: activities:read | Marcar going o not_going. No confirma asistencia | ActivitiesService.setRsvp() | `src/activities/activities.controller.ts` |
| GET | `/api/v1/activities/:activityId/attendance-roster` | JWT | Permisos: attendance:manage | Miembros de la sección con intención y confirmación (solo virtual) | ActivitiesService.getAttendanceRoster() | `src/activities/activities.controller.ts` |

### admin-auth

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/users/:userId/sessions` | JWT | Global: USER_MANAGEMENT_ROLES (admin + lf/union/dia); Permisos: users:read_detail; recorte territorial | List all active sessions for a user | AdminAuthService.listUserSessions() | `src/admin/admin-auth.controller.ts` |
| DELETE | `/api/v1/admin/users/:userId/sessions/:sessionId` | JWT | Global: USER_MANAGEMENT_ROLES; Permisos: users:read_detail; recorte territorial | Revoke a specific session for a user | AdminAuthService.revokeUserSession() | `src/admin/admin-auth.controller.ts` |
| DELETE | `/api/v1/admin/users/:userId/sessions` | JWT | Global: USER_MANAGEMENT_ROLES; Permisos: users:read_detail; recorte territorial | Revoke all sessions for a user | AdminAuthService.revokeAllUserSessions() | `src/admin/admin-auth.controller.ts` |
| GET | `/api/v1/admin/users/:userId/mfa/status` | JWT | Global: admin, super-admin; Permisos: users:update_admin | Get MFA enrollment status for a user | AdminAuthService.getUserMfaStatus() | `src/admin/admin-auth.controller.ts` |
| DELETE | `/api/v1/admin/users/:userId/mfa` | JWT | Global: admin, super-admin; Permisos: users:update_admin | Reset (disable) MFA for a user | AdminAuthService.resetUserMfa() | `src/admin/admin-auth.controller.ts` |
| POST | `/api/v1/admin/users/:userId/password` | JWT | Global: admin, super-admin; Permisos: users:update_admin | Set a new password for a user | AdminAuthService.setUserPassword() | `src/admin/admin-auth.controller.ts` |

### admin-camporee-event-types

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/camporee-event-types` | JWT | Global: admin, super-admin; Permisos: camporee_event_types:read | List camporee event types | AdminCamporeeEventTypesService.listCamporeeEventTypes() | `src/admin/admin-camporee-event-types.controller.ts` |
| POST | `/api/v1/admin/camporee-event-types` | JWT | Global: admin, super-admin; Permisos: camporee_event_types:create | Create camporee event type | AdminCamporeeEventTypesService.createCamporeeEventType() | `src/admin/admin-camporee-event-types.controller.ts` |
| PATCH | `/api/v1/admin/camporee-event-types/:eventTypeId` | JWT | Global: admin, super-admin; Permisos: camporee_event_types:update | Update camporee event type | AdminCamporeeEventTypesService.updateCamporeeEventType() | `src/admin/admin-camporee-event-types.controller.ts` |
| DELETE | `/api/v1/admin/camporee-event-types/:eventTypeId` | JWT | Global: admin, super-admin; Permisos: camporee_event_types:delete | Soft delete camporee event type | AdminCamporeeEventTypesService.deleteCamporeeEventType() | `src/admin/admin-camporee-event-types.controller.ts` |

### admin

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/cron-alerts` | JWT | Global: admin, super-admin | Paginated cron alert history | AdminCronAlertsService.getAlertHistory() | `src/admin/admin-cron-alerts.controller.ts` |
| POST | `/api/v1/admin/cron-alerts/:id/resolve` | JWT | Global: admin, super-admin; Global: super-admin | Manually resolve a cron alert (super-admin only) | AdminCronAlertsService.resolveAlert() | `src/admin/admin-cron-alerts.controller.ts` |

### admin-audit-logs

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/audit-logs` | JWT | Global: super-admin; Permisos: audit:read. Sin recorte territorial. `admin` → 403. | Listar audit logs globales (cursor `audit_log_id` desc; default 50, max 100). Query: `entity_type`, `actor_user_id`, `action`, `result`, `source`, `from`, `to`, `club_id`, `correlation_id`, `limit`, `cursor`. List no incluye `changes` ni `request_context`. | AuditLogsService.listAdmin() | `src/audit-logs/admin-audit-logs.controller.ts` |
| GET | `/api/v1/admin/audit-logs/:id` | JWT | Global: super-admin; Permisos: audit:read | Detalle con `changes` (solo dominio) y `request_context`. Nunca body de request. | AuditLogsService.getById() | `src/audit-logs/admin-audit-logs.controller.ts` |


### admin-geography

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/divisions` | JWT | Global: admin, super-admin; Permisos: countries:read | List institutional divisions for admin management | AdminGeographyService.listDivisions() | `src/admin/admin-geography.controller.ts` |
| POST | `/api/v1/admin/divisions` | JWT | Global: admin, super-admin; Permisos: countries:create | Create institutional division | AdminGeographyService.createDivision() | `src/admin/admin-geography.controller.ts` |
| PATCH | `/api/v1/admin/divisions/:divisionId` | JWT | Global: admin, super-admin; Permisos: countries:update | Update institutional division | AdminGeographyService.updateDivision() | `src/admin/admin-geography.controller.ts` |
| DELETE | `/api/v1/admin/divisions/:divisionId` | JWT | Global: admin, super-admin; Permisos: countries:delete | Soft delete institutional division | AdminGeographyService.deleteDivision() | `src/admin/admin-geography.controller.ts` |
| GET | `/api/v1/admin/countries` | JWT | Global: admin, super-admin; Permisos: countries:read | List countries for admin management | AdminGeographyService.listCountries() | `src/admin/admin-geography.controller.ts` |
| POST | `/api/v1/admin/countries` | JWT | Global: admin, super-admin; Permisos: countries:create | Create country | AdminGeographyService.createCountry() | `src/admin/admin-geography.controller.ts` |
| PATCH | `/api/v1/admin/countries/:countryId` | JWT | Global: admin, super-admin; Permisos: countries:update | Update country | AdminGeographyService.updateCountry() | `src/admin/admin-geography.controller.ts` |
| DELETE | `/api/v1/admin/countries/:countryId` | JWT | Global: admin, super-admin; Permisos: countries:delete | Soft delete country | AdminGeographyService.deleteCountry() | `src/admin/admin-geography.controller.ts` |
| GET | `/api/v1/admin/unions` | JWT | Global: admin, super-admin; Permisos: unions:read | List unions for admin management | AdminGeographyService.listUnions() | `src/admin/admin-geography.controller.ts` |
| POST | `/api/v1/admin/unions` | JWT | Global: admin, super-admin; Permisos: unions:create | Create union | AdminGeographyService.createUnion() | `src/admin/admin-geography.controller.ts` |
| PATCH | `/api/v1/admin/unions/:unionId` | JWT | Global: admin, super-admin; Permisos: unions:update | Update union | AdminGeographyService.updateUnion() | `src/admin/admin-geography.controller.ts` |
| DELETE | `/api/v1/admin/unions/:unionId` | JWT | Global: admin, super-admin; Permisos: unions:delete | Soft delete union | AdminGeographyService.deleteUnion() | `src/admin/admin-geography.controller.ts` |
| GET | `/api/v1/admin/local-fields` | JWT | Global: admin, super-admin; Permisos: local_fields:read | List local fields for admin management | AdminGeographyService.listLocalFields() | `src/admin/admin-geography.controller.ts` |
| POST | `/api/v1/admin/local-fields` | JWT | Global: admin, super-admin; Permisos: local_fields:create | Create local field | AdminGeographyService.createLocalField() | `src/admin/admin-geography.controller.ts` |
| PATCH | `/api/v1/admin/local-fields/:localFieldId` | JWT | Global: admin, super-admin; Permisos: local_fields:update | Update local field | AdminGeographyService.updateLocalField() | `src/admin/admin-geography.controller.ts` |
| DELETE | `/api/v1/admin/local-fields/:localFieldId` | JWT | Global: admin, super-admin; Permisos: local_fields:delete | Soft delete local field | AdminGeographyService.deleteLocalField() | `src/admin/admin-geography.controller.ts` |
| GET | `/api/v1/admin/districts` | JWT | Global: admin, super-admin; Permisos: local_fields:read | List districts for admin management | AdminGeographyService.listDistricts() | `src/admin/admin-geography.controller.ts` |
| POST | `/api/v1/admin/districts` | JWT | Global: admin, super-admin; Permisos: local_fields:update | Create district | AdminGeographyService.createDistrict() | `src/admin/admin-geography.controller.ts` |
| PATCH | `/api/v1/admin/districts/:districtId` | JWT | Global: admin, super-admin; Permisos: local_fields:update | Update district | AdminGeographyService.updateDistrict() | `src/admin/admin-geography.controller.ts` |
| DELETE | `/api/v1/admin/districts/:districtId` | JWT | Global: admin, super-admin; Permisos: local_fields:delete | Soft delete district | AdminGeographyService.deleteDistrict() | `src/admin/admin-geography.controller.ts` |
| GET | `/api/v1/admin/churches` | JWT | Global: admin, super-admin; Permisos: churches:read | List churches for admin management | AdminGeographyService.listChurches() | `src/admin/admin-geography.controller.ts` |
| POST | `/api/v1/admin/churches` | JWT | Global: admin, super-admin; Permisos: churches:create | Create church | AdminGeographyService.createChurch() | `src/admin/admin-geography.controller.ts` |
| PATCH | `/api/v1/admin/churches/:churchId` | JWT | Global: admin, super-admin; Permisos: churches:update | Update church | AdminGeographyService.updateChurch() | `src/admin/admin-geography.controller.ts` |
| DELETE | `/api/v1/admin/churches/:churchId` | JWT | Global: admin, super-admin; Permisos: churches:delete | Soft delete church | AdminGeographyService.deleteChurch() | `src/admin/admin-geography.controller.ts` |

### Admin - Honors Requirements

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/honors/requirements/pending-review` | JWT | Global: admin, super-admin; Permisos: honors:read | List requirements pending admin review (paginated) | AdminHonorsService.getPendingReview() | `src/admin/admin-honors.controller.ts` |
| PATCH | `/api/v1/admin/honors/requirements/batch-review` | JWT | Global: admin, super-admin; Permisos: honors:update | Batch-review flagged requirements | AdminHonorsService.batchReview() | `src/admin/admin-honors.controller.ts` |
| PATCH | `/api/v1/admin/honors/requirements/:requirementId` | JWT | Global: admin, super-admin; Permisos: honors:update | Update a requirement | AdminHonorsService.updateRequirement() | `src/admin/admin-honors.controller.ts` |
| DELETE | `/api/v1/admin/honors/requirements/:requirementId` | JWT | Global: admin, super-admin; Permisos: honors:delete | Soft-delete a requirement (and its children) | AdminHonorsService.deleteRequirement() | `src/admin/admin-honors.controller.ts` |
| GET | `/api/v1/admin/honors/:honorId/requirements` | JWT | Global: admin, super-admin; Permisos: honors:read | List requirements tree for an honor (admin view) | AdminHonorsService.getRequirements() | `src/admin/admin-honors.controller.ts` |
| POST | `/api/v1/admin/honors/:honorId/requirements` | JWT | Global: admin, super-admin; Permisos: honors:create | Create a requirement for an honor | AdminHonorsService.createRequirement() | `src/admin/admin-honors.controller.ts` |
| PATCH | `/api/v1/admin/honors/:honorId/requirements/reorder` | JWT | Global: admin, super-admin; Permisos: honors:update | Reorder requirements for an honor | AdminHonorsService.reorderRequirements() | `src/admin/admin-honors.controller.ts` |

### admin-notifications

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/notifications/stats` | JWT | Global: admin, super-admin | FCM notification delivery metrics for administrators | AdminNotificationsService.getStats() | `src/admin/admin-notifications.controller.ts` |
| GET | `/api/v1/admin/notifications/categories` | JWT | Global: admin, super-admin | Listar la configuración global de entrega por categoría de notificación | NotificationCategorySettingsService.listCategorySettings() | `src/admin/admin-notifications.controller.ts` |
| PATCH | `/api/v1/admin/notifications/categories` | JWT | Global: admin, super-admin | Actualizar una categoría (`PatchNotificationCategorySettingDto`: `category`, `mobileEnabled`, `defaultEnabled`); responde la lista completa | NotificationCategorySettingsService.updateCategorySetting() | `src/admin/admin-notifications.controller.ts` |

### Admin - Phase E Catalogs (i18n)

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/classes` | JWT | Global: admin, super-admin; Permisos: catalogs:read | List all classes with their full translations (admin editor) | AdminPhaseECatalogsService.findAllClasses() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| POST | `/api/v1/admin/classes` | JWT | Global: admin, super-admin; Permisos: catalogs:create | Create a class with optional translations | AdminPhaseECatalogsService.createClass() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| PATCH | `/api/v1/admin/classes/:id` | JWT | Global: admin, super-admin; Permisos: catalogs:update | Update a class and upsert/delete translations | AdminPhaseECatalogsService.updateClass() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| DELETE | `/api/v1/admin/classes/:id` | JWT | Global: admin, super-admin; Permisos: catalogs:delete | Soft-delete a class (active = false) | AdminPhaseECatalogsService.deleteClass() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| GET | `/api/v1/admin/classes/:classId/honors` | JWT | Global: admin, super-admin; Permisos: catalogs:read | List class-honor relations (incluye inactivas; filtro `active?`; `module_id`/`module`/`material_url`) | AdminPhaseECatalogsService.findClassHonors() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| POST | `/api/v1/admin/classes/:classId/honors` | JWT | Global: admin, super-admin; Permisos: catalogs:create | Create class-honor relation (`REQUIRED`/`RECOMMENDED`/`ELECTIVE`; `module_id?` del mismo `class_id`) | AdminPhaseECatalogsService.createClassHonor() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| PATCH | `/api/v1/admin/classes/:classId/honors/:classHonorId` | JWT | Global: admin, super-admin; Permisos: catalogs:update | Asigna o limpia el módulo (`module_id` number o `null`; omitir deja el módulo igual) | AdminPhaseECatalogsService.updateClassHonor() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| DELETE | `/api/v1/admin/classes/:classId/honors/:classHonorId` | JWT | Global: admin, super-admin; Permisos: catalogs:delete | Soft-delete class-honor relation | AdminPhaseECatalogsService.deleteClassHonor() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| GET | `/api/v1/admin/classes/:classId/prerequisites` | JWT | Global: admin, super-admin; Permisos: catalogs:read | List class prerequisites (incluye inactivas; filtro `active?`) | AdminPhaseECatalogsService.findClassPrerequisites() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| POST | `/api/v1/admin/classes/:classId/prerequisites` | JWT | Global: admin, super-admin; Permisos: catalogs:create | Create class prerequisite with cycle validation | AdminPhaseECatalogsService.createClassPrerequisite() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| DELETE | `/api/v1/admin/classes/:classId/prerequisites/:prerequisiteId` | JWT | Global: admin, super-admin; Permisos: catalogs:delete | Soft-delete class prerequisite | AdminPhaseECatalogsService.deleteClassPrerequisite() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| GET | `/api/v1/admin/class-modules` | JWT | Global: admin, super-admin; Permisos: catalogs:read | List all class modules with their full translations (admin editor) | AdminPhaseECatalogsService.findAllClassModules() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| POST | `/api/v1/admin/class-modules` | JWT | Global: admin, super-admin; Permisos: catalogs:create | Create a class module with optional translations | AdminPhaseECatalogsService.createClassModule() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| PATCH | `/api/v1/admin/class-modules/:id` | JWT | Global: admin, super-admin; Permisos: catalogs:update | Update a class module and upsert/delete translations | AdminPhaseECatalogsService.updateClassModule() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| DELETE | `/api/v1/admin/class-modules/:id` | JWT | Global: admin, super-admin; Permisos: catalogs:delete | Soft-delete a class module (active = false) | AdminPhaseECatalogsService.deleteClassModule() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| GET | `/api/v1/admin/class-sections` | JWT | Global: admin, super-admin; Permisos: catalogs:read | List all class sections with their full translations (admin editor) | AdminPhaseECatalogsService.findAllClassSections() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| POST | `/api/v1/admin/class-sections` | JWT | Global: admin, super-admin; Permisos: catalogs:create | Create a class section with optional translations | AdminPhaseECatalogsService.createClassSection() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| PATCH | `/api/v1/admin/class-sections/:id` | JWT | Global: admin, super-admin; Permisos: catalogs:update | Update a class section and upsert/delete translations | AdminPhaseECatalogsService.updateClassSection() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| DELETE | `/api/v1/admin/class-sections/:id` | JWT | Global: admin, super-admin; Permisos: catalogs:delete | Soft-delete a class section (active = false) | AdminPhaseECatalogsService.deleteClassSection() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| GET | `/api/v1/admin/finance-categories` | JWT | Global: admin, super-admin; Permisos: catalogs:read | List all finance categories with their full translations (admin editor) | AdminPhaseECatalogsService.findAllFinanceCategories() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| POST | `/api/v1/admin/finance-categories` | JWT | Global: admin, super-admin; Permisos: catalogs:create | Create a finance category with optional translations | AdminPhaseECatalogsService.createFinanceCategory() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| PATCH | `/api/v1/admin/finance-categories/:id` | JWT | Global: admin, super-admin; Permisos: catalogs:update | Update a finance category and upsert/delete translations | AdminPhaseECatalogsService.updateFinanceCategory() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| DELETE | `/api/v1/admin/finance-categories/:id` | JWT | Global: admin, super-admin; Permisos: catalogs:delete | Soft-delete a finance category (active = false) | AdminPhaseECatalogsService.deleteFinanceCategory() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| GET | `/api/v1/admin/inventory-categories` | JWT | Global: admin, super-admin; Permisos: catalogs:read | List all inventory categories with their full translations (admin editor) | AdminPhaseECatalogsService.findAllInventoryCategories() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| POST | `/api/v1/admin/inventory-categories` | JWT | Global: admin, super-admin; Permisos: catalogs:create | Create an inventory category with optional translations | AdminPhaseECatalogsService.createInventoryCategory() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| PATCH | `/api/v1/admin/inventory-categories/:id` | JWT | Global: admin, super-admin; Permisos: catalogs:update | Update an inventory category and upsert/delete translations | AdminPhaseECatalogsService.updateInventoryCategory() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| DELETE | `/api/v1/admin/inventory-categories/:id` | JWT | Global: admin, super-admin; Permisos: catalogs:delete | Soft-delete an inventory category (active = false) | AdminPhaseECatalogsService.deleteInventoryCategory() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| GET | `/api/v1/admin/honors-catalog` | JWT | Global: admin, super-admin; Permisos: honors:read | List all honors with their full translations (admin editor) | AdminPhaseECatalogsService.findAllHonors() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| POST | `/api/v1/admin/honors-catalog` | JWT | Global: admin, super-admin; Permisos: honors:create | Create an honor with optional translations | AdminPhaseECatalogsService.createHonor() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| PATCH | `/api/v1/admin/honors-catalog/:id` | JWT | Global: admin, super-admin; Permisos: honors:update | Update an honor and upsert/delete translations | AdminPhaseECatalogsService.updateHonor() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| DELETE | `/api/v1/admin/honors-catalog/:id` | JWT | Global: admin, super-admin; Permisos: honors:delete | Soft-delete an honor (active = false) | AdminPhaseECatalogsService.deleteHonor() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| GET | `/api/v1/admin/master-honors` | JWT | Global: admin, super-admin; Permisos: honors:read | List all master honors with their full translations (admin editor) | AdminPhaseECatalogsService.findAllMasterHonors() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| POST | `/api/v1/admin/master-honors` | JWT | Global: admin, super-admin; Permisos: honors:create | Create a master honor with optional translations | AdminPhaseECatalogsService.createMasterHonor() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| PATCH | `/api/v1/admin/master-honors/:id` | JWT | Global: admin, super-admin; Permisos: honors:update | Update a master honor and upsert/delete translations | AdminPhaseECatalogsService.updateMasterHonor() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| DELETE | `/api/v1/admin/master-honors/:id` | JWT | Global: admin, super-admin; Permisos: honors:delete | Soft-delete a master honor (active = false) | AdminPhaseECatalogsService.deleteMasterHonor() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| POST | `/api/v1/admin/master-honors/:id/recalculate` | JWT | Global: admin, super-admin; Permisos: honors:update | Queue recalculation of affected users for one master honor | AdminPhaseECatalogsService.recalculateMasterHonor() | `src/admin/admin-phase-e-catalogs.controller.ts` |

### admin-reference

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/admin/catalogs/cache/invalidate` | JWT | Global: admin, super-admin; Permisos: catalogs:update | Invalidate all catalog caches (SCAN `cache:catalogs:*` + epoch bump de honores) | CatalogCacheService.invalidateAll() | `src/admin/admin-reference.controller.ts` |
| GET | `/api/v1/admin/activity-types` | JWT | Global: admin, super-admin; Permisos: catalogs:read | List activity types for admin management | AdminReferenceService.listActivityTypes() | `src/admin/admin-reference.controller.ts` |
| POST | `/api/v1/admin/activity-types` | JWT | Global: admin, super-admin; Permisos: catalogs:create | Create activity type | AdminReferenceService.createActivityType() | `src/admin/admin-reference.controller.ts` |
| PATCH | `/api/v1/admin/activity-types/:activityTypeId` | JWT | Global: admin, super-admin; Permisos: catalogs:update | Update activity type | AdminReferenceService.updateActivityType() | `src/admin/admin-reference.controller.ts` |
| DELETE | `/api/v1/admin/activity-types/:activityTypeId` | JWT | Global: admin, super-admin; Permisos: catalogs:delete | Soft delete activity type | AdminReferenceService.deleteActivityType() | `src/admin/admin-reference.controller.ts` |
| GET | `/api/v1/admin/relationship-types` | JWT | Global: admin, super-admin; Permisos: catalogs:read | List relationship types for admin management | AdminReferenceService.listRelationshipTypes() | `src/admin/admin-reference.controller.ts` |
| POST | `/api/v1/admin/relationship-types` | JWT | Global: admin, super-admin; Permisos: catalogs:create | Create relationship type | AdminReferenceService.createRelationshipType() | `src/admin/admin-reference.controller.ts` |
| PATCH | `/api/v1/admin/relationship-types/:relationshipTypeId` | JWT | Global: admin, super-admin; Permisos: catalogs:update | Update relationship type | AdminReferenceService.updateRelationshipType() | `src/admin/admin-reference.controller.ts` |
| DELETE | `/api/v1/admin/relationship-types/:relationshipTypeId` | JWT | Global: admin, super-admin; Permisos: catalogs:delete | Soft delete relationship type | AdminReferenceService.deleteRelationshipType() | `src/admin/admin-reference.controller.ts` |
| GET | `/api/v1/admin/allergies` | JWT | Global: admin, super-admin; Permisos: catalogs:read | List allergies for admin management | AdminReferenceService.listAllergies() | `src/admin/admin-reference.controller.ts` |
| POST | `/api/v1/admin/allergies` | JWT | Global: admin, super-admin; Permisos: catalogs:create | Create allergy | AdminReferenceService.createAllergy() | `src/admin/admin-reference.controller.ts` |
| PATCH | `/api/v1/admin/allergies/:allergyId` | JWT | Global: admin, super-admin; Permisos: catalogs:update | Update allergy | AdminReferenceService.updateAllergy() | `src/admin/admin-reference.controller.ts` |
| DELETE | `/api/v1/admin/allergies/:allergyId` | JWT | Global: admin, super-admin; Permisos: catalogs:delete | Soft delete allergy | AdminReferenceService.deleteAllergy() | `src/admin/admin-reference.controller.ts` |
| GET | `/api/v1/admin/diseases` | JWT | Global: admin, super-admin; Permisos: catalogs:read | List diseases for admin management | AdminReferenceService.listDiseases() | `src/admin/admin-reference.controller.ts` |
| POST | `/api/v1/admin/diseases` | JWT | Global: admin, super-admin; Permisos: catalogs:create | Create disease | AdminReferenceService.createDisease() | `src/admin/admin-reference.controller.ts` |
| PATCH | `/api/v1/admin/diseases/:diseaseId` | JWT | Global: admin, super-admin; Permisos: catalogs:update | Update disease | AdminReferenceService.updateDisease() | `src/admin/admin-reference.controller.ts` |
| DELETE | `/api/v1/admin/diseases/:diseaseId` | JWT | Global: admin, super-admin; Permisos: catalogs:delete | Soft delete disease | AdminReferenceService.deleteDisease() | `src/admin/admin-reference.controller.ts` |
| GET | `/api/v1/admin/club-ideals` | JWT | Global: admin, super-admin; Permisos: catalogs:read | List club ideals for admin | AdminReferenceService.listClubIdeals() | `src/admin/admin-reference.controller.ts` |
| POST | `/api/v1/admin/club-ideals` | JWT | Global: admin, super-admin; Permisos: catalogs:create; Global: super-admin | Create club ideal (super-admin only) | AdminReferenceService.createClubIdeal() | `src/admin/admin-reference.controller.ts` |
| PATCH | `/api/v1/admin/club-ideals/:clubIdealId` | JWT | Global: admin, super-admin; Permisos: catalogs:update | Update club ideal (admin: edit only; super-admin: full edit) | AdminReferenceService.updateClubIdeal() | `src/admin/admin-reference.controller.ts` |
| DELETE | `/api/v1/admin/club-ideals/:clubIdealId` | JWT | Global: admin, super-admin; Permisos: catalogs:delete; Global: super-admin | Soft delete club ideal (super-admin only) | AdminReferenceService.deleteClubIdeal() | `src/admin/admin-reference.controller.ts` |
| GET | `/api/v1/admin/club-types` | JWT | Global: admin, super-admin; Permisos: catalogs:read | List all club types for admin management | AdminReferenceService.listClubTypes() | `src/admin/admin-reference.controller.ts` |
| POST | `/api/v1/admin/club-types` | JWT | Global: admin, super-admin; Permisos: catalogs:create; Global: super-admin | Create club type (super-admin only) | AdminReferenceService.createClubType() | `src/admin/admin-reference.controller.ts` |
| PATCH | `/api/v1/admin/club-types/:clubTypeId` | JWT | Global: admin, super-admin; Permisos: catalogs:update | Update club type (admin: edit only; super-admin: full edit) | AdminReferenceService.updateClubType() | `src/admin/admin-reference.controller.ts` |
| DELETE | `/api/v1/admin/club-types/:clubTypeId` | JWT | Global: admin, super-admin; Permisos: catalogs:delete; Global: super-admin | Soft delete club type (super-admin only) | AdminReferenceService.deleteClubType() | `src/admin/admin-reference.controller.ts` |
| GET | `/api/v1/admin/honor-categories` | JWT | Global: admin, super-admin; Permisos: honor_categories:read | List honor categories for admin management | AdminReferenceService.listHonorCategories() | `src/admin/admin-reference.controller.ts` |
| POST | `/api/v1/admin/honor-categories` | JWT | Global: admin, super-admin; Permisos: honor_categories:create | Create honor category | AdminReferenceService.createHonorCategory() | `src/admin/admin-reference.controller.ts` |
| GET | `/api/v1/admin/honor-categories/:id` | JWT | Global: admin, super-admin; Permisos: honor_categories:read | Get honor category by ID | AdminReferenceService.getHonorCategory() | `src/admin/admin-reference.controller.ts` |
| PATCH | `/api/v1/admin/honor-categories/:id` | JWT | Global: admin, super-admin; Permisos: honor_categories:update | Update honor category | AdminReferenceService.updateHonorCategory() | `src/admin/admin-reference.controller.ts` |
| DELETE | `/api/v1/admin/honor-categories/:id` | JWT | Global: admin, super-admin; Permisos: honor_categories:delete | Soft delete honor category | AdminReferenceService.deleteHonorCategory() | `src/admin/admin-reference.controller.ts` |
| GET | `/api/v1/admin/medicines` | JWT | Global: admin, super-admin; Permisos: catalogs:read | List medicines for admin management | AdminReferenceService.listMedicines() | `src/admin/admin-reference.controller.ts` |
| POST | `/api/v1/admin/medicines` | JWT | Global: admin, super-admin; Permisos: catalogs:create | Create medicine | AdminReferenceService.createMedicine() | `src/admin/admin-reference.controller.ts` |
| PATCH | `/api/v1/admin/medicines/:medicineId` | JWT | Global: admin, super-admin; Permisos: catalogs:update | Update medicine | AdminReferenceService.updateMedicine() | `src/admin/admin-reference.controller.ts` |
| DELETE | `/api/v1/admin/medicines/:medicineId` | JWT | Global: admin, super-admin; Permisos: catalogs:delete | Soft delete medicine | AdminReferenceService.deleteMedicine() | `src/admin/admin-reference.controller.ts` |
| GET | `/api/v1/admin/ecclesiastical-years` | JWT | Global: admin, super-admin; Permisos: ecclesiastical_years:read | List ecclesiastical years for admin management | AdminReferenceService.listEcclesiasticalYears() | `src/admin/admin-reference.controller.ts` |
| POST | `/api/v1/admin/ecclesiastical-years` | JWT | Global: super-admin; Permisos: ecclesiastical_years:create | Create ecclesiastical year | AdminReferenceService.createEcclesiasticalYear() | `src/admin/admin-reference.controller.ts` |
| PATCH | `/api/v1/admin/ecclesiastical-years/:yearId` | JWT | Global: admin, super-admin; Permisos: ecclesiastical_years:update | Update ecclesiastical year | AdminReferenceService.updateEcclesiasticalYear() | `src/admin/admin-reference.controller.ts` |
| DELETE | `/api/v1/admin/ecclesiastical-years/:yearId` | JWT | Global: super-admin; Permisos: ecclesiastical_years:delete | Soft delete ecclesiastical year | AdminReferenceService.deleteEcclesiasticalYear() | `src/admin/admin-reference.controller.ts` |

### admin-users

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/users` | JWT | Global: admin, super-admin, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia (USER_MANAGEMENT_ROLES, pisa la cerca de clase); Permisos: users:read | Listar usuarios administrativos con alcance por rol (ALL/DIVISION/UNION/LOCAL_FIELD). Ordena el conjunto filtrado **antes** de `skip`/`take`. Query: `search`, `role` (OR global o club), `active`, `unionId`, `localFieldId`, `sortBy` (`name` | `created_at`, default `name`), `sortOrder` (`asc` | `desc`, default `asc`), `page`, `limit`. `sortBy=name`: `name`, `paternal_last_name`, `maternal_last_name` (nulls last) + `user_id` asc. `sortBy=created_at`: `created_at` + `user_id` asc. Enum inválido → 400. Cada ítem incluye `roles` (slugs únicos global+club) y `club_assignments` compactos `{ assignment_id, role_name, section_name, club_name }`. El panel de lista muestra un badge por cargo (sin sección; el mismo cargo en varias secciones se colapsa). | AdminUsersService.listUsers() | `src/admin/admin-users.controller.ts` |
| GET | `/api/v1/admin/users/bulk-template` | JWT | Global: admin, super-admin; Permisos: users:bulk_create; Global: admin, super-admin, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Descarga plantilla .xlsx para carga masiva de usuarios | AdminUsersService.getBulkTemplateBuffer() | `src/admin/admin-users.controller.ts` |
| GET | `/api/v1/admin/users/:userId` | JWT | Global: admin, super-admin, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia (USER_MANAGEMENT_ROLES, pisa la cerca de clase); Permisos: users:read_detail | Obtener detalle de usuario validando alcance por rol del actor | AdminUsersService.getUserById() | `src/admin/admin-users.controller.ts` |
| PATCH | `/api/v1/admin/users/:userId/approval` | JWT | Global: admin, super-admin; Permisos: users:update_admin | Approve or reject a user | AdminUsersService.updateUserApproval() | `src/admin/admin-users.controller.ts` |
| PATCH | `/api/v1/admin/users/:userId` | JWT | Global: admin, super-admin; Permisos: users:update_admin | Update user administrative fields | AdminUsersService.updateUser() | `src/admin/admin-users.controller.ts` |
| POST | `/api/v1/admin/users` | JWT | Global: admin, super-admin; Permisos: users:create; Global: admin, super-admin, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Crear usuario manualmente (admin-iniciado, con invite por email) | AdminUsersService.createAdminUser() | `src/admin/admin-users.controller.ts` |
| POST | `/api/v1/admin/users/bulk` | JWT | Global: admin, super-admin; Permisos: users:bulk_create; Global: admin, super-admin, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Carga masiva de usuarios desde archivo .xlsx o .csv | AdminUsersService.bulkCreateAdminUsers() | `src/admin/admin-users.controller.ts` |

### analytics

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/analytics/sla-dashboard` | JWT | Global: admin, coordinator (alias: zone/general + director-lf/assistant-lf; LF recorta a secciones del campo) | SLA Dashboard | AnalyticsService.getSlaDashboard() | `src/analytics/analytics.controller.ts` |
| GET | `/api/v1/admin/analytics/local-field-dashboard` | JWT | Global: admin, super-admin, coordinator, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Dashboard operativo del campo local (miembros activos, inscripciones anuales, cobertura de informes mensuales, distribución por clase, especialidades y actividades). Query opcional `local_field_id`: los roles de campo ven su propio campo; admin puede filtrar | LocalFieldDashboardService.getDashboard() | `src/analytics/analytics.controller.ts` |
| GET | `/api/v1/admin/analytics/operations-dashboard` | JWT | Global: admin (alias: assistant-admin), super-admin, director-dia, assistant-dia, director-union, assistant-union, director-lf, assistant-lf | Dashboard operativo jerárquico con scope forzado en servidor | OperationsDashboardService.getDashboard() | `src/analytics/analytics.controller.ts` |
| GET | `/api/v1/admin/analytics/jobs-overview` | JWT | Global: admin, super-admin | Overview de jobs y colas BullMQ (admin only) | JobsOverviewService.getOverview() | `src/analytics/analytics.controller.ts` |
| POST | `/api/v1/admin/analytics/jobs/:queue/:jobId/retry` | JWT | Global: super-admin | Retry failed BullMQ job (super-admin only) | JobsOverviewService.retryFailedJob() | `src/analytics/analytics.controller.ts` |
| GET | `/api/v1/admin/analytics/queues/:queueName/health` | JWT | Global: admin, super-admin | Queue health snapshot (admin only) | JobsOverviewService.getQueueHealth() | `src/analytics/analytics.controller.ts` |
| GET | `/api/v1/admin/analytics/cron-runs` | JWT | Global: admin, super-admin | Resumen de ejecuciones de cron jobs (admin only) | CronRunsService.getSummary() | `src/analytics/analytics.controller.ts` |
| GET | `/api/v1/admin/analytics/cron-runs/history` | JWT | Global: admin, super-admin | Historial paginado de cron runs con filtros | CronRunsService.getHistory() | `src/analytics/analytics.controller.ts` |

#### `GET /api/v1/admin/analytics/operations-dashboard`

Endpoint read-only agregado. El controller admite los roles enumerados en la tabla; `assistant-admin` es aceptado por el alias `admin ↔ assistant-admin` de `GlobalRolesGuard`. Solo `super-admin` obtiene scope global. Los demás actores reciben el scope territorial resuelto por `OperationsDashboardScopeService`.

##### Query

| Parámetro | Requerido | Validación y comportamiento |
| --- | --- | --- |
| `ecclesiastical_year_id` | No | Entero `>= 1`. Si se omite, selecciona el año activo más reciente por `start_date`. |
| `division_id` | No | Entero `>= 1`; solo puede mantener o reducir el scope autorizado. |
| `union_id` | No | Entero `>= 1`; debe pertenecer a la cadena solicitada y al scope del actor. |
| `local_field_id` | No | Entero `>= 1`; debe pertenecer a la cadena solicitada y al scope del actor. |
| `report_year` | Condicional | Entero `>= 1`; debe enviarse junto con `report_month`. |
| `report_month` | Condicional | Entero `1..12`; debe enviarse junto con `report_year`. |

El periodo mensual explícito debe caer entre los meses inicial y final del año eclesiástico, inclusive. Si ambos parámetros se omiten, el servicio resuelve el último mes calendario cerrado dentro del año. Cuando el año todavía no contiene un mes cerrado, `reporting_month` es `null`, los conteos mensuales son `0`, `coverage_pct` es `null` y la calidad es `not_applicable`.

El `ValidationPipe` global transforma strings numéricos, rechaza propiedades no declaradas y responde `400` ante enteros inválidos, IDs no positivos, mes fuera de rango o un periodo incompleto.

##### Envelope y shape de éxito

```ts
type ScopeLevel = 'all' | 'division' | 'union' | 'local_field';
type ChildLevel = 'division' | 'union' | 'local_field' | 'club';
type MetricQuality =
  | 'exact'
  | 'current_affiliation'
  | 'unavailable'
  | 'not_applicable';

type DashboardMetrics = {
  administrative_clubs: {
    total: number;
    active: number;
    inactive: number;
  };
  operations: {
    operational_clubs: number;
    non_operational_clubs: number;
    operational_sections: number;
    operational_rate_pct: number | null;
  };
  people: {
    institutionally_active: number;
    platform_accounts: { active: number; inactive: number };
  };
  classes: {
    total_enrollments: number;
    distinct_people: number;
    by_class: Array<{
      class_id: number;
      class_name: string;
      club_type_id: number;
      club_type_name: string;
      display_order: number;
      enrollment_count: number;
    }>;
  };
  monthly_reports: {
    expected_sections: number;
    submitted_sections: number;
    draft_sections: number;
    generated_sections: number;
    missing_sections: number;
    coverage_pct: number | null;
  };
  honors: {
    in_progress: number | null;
    pending_review: number | null;
    approved: number | null;
    attribution: 'current_affiliation' | 'unavailable';
  };
  activities: {
    registered: number;
    joint_registered: number;
    distinct_participating_sections: number;
  };
  queues: {
    role_assignments_pending: number;
    transfers_pending: number;
    class_validations_pending: number;
    honors_review_pending: number | null;
    annual_folders_pending_union: number;
  };
};

type OperationsDashboardResponse = {
  status: 'ok';
  data: {
    meta: {
      computed_at: string; // ISO 8601
      cached: boolean;
      cache_ttl_seconds: number; // runtime actual: 60
      definitions_version: string; // runtime actual: "1"
      scope: {
        level: ScopeLevel;
        id: number | null;
        name: string;
        path: Array<{
          level: Exclude<ScopeLevel, 'all'>;
          id: number;
          name: string;
        }>;
      };
      period: {
        ecclesiastical_year: {
          id: number;
          start_date: string; // YYYY-MM-DD
          end_date: string; // YYYY-MM-DD
          active: boolean;
        };
        reporting_month: { year: number; month: number } | null;
      };
    };
    summary: DashboardMetrics;
    children: Array<
      {
        id: number;
        name: string;
        level: ChildLevel;
      } & DashboardMetrics
    >;
    data_quality: Array<{
      metric: string;
      status: MetricQuality;
      note: string;
    }>;
  };
};
```

`children` siempre representa el nivel inmediato: global → División → Unión → Campo local → Club. También contiene `classes.by_class`; no es un resumen compacto. Los totales de `summary` se recalculan de forma independiente y no deben reconstruirse sumando children.

Para un año histórico (`ecclesiastical_year.active = false`), los conteos de especialidades y `queues.honors_review_pending` son `null`, no `0`. `operations.operational_rate_pct` es `null` cuando no hay clubes administrativos y `monthly_reports.coverage_pct` es `null` cuando no hay denominador.

##### Errores

| HTTP | Código/causa | Regla |
| ---: | --- | --- |
| `400` | Validación DTO | Query desconocida, número inválido/no positivo, periodo incompleto o `report_month` fuera de `1..12`. |
| `400` | `ANALYTICS_SCOPE_CHAIN_INVALID` | Los IDs territoriales enviados no forman una misma cadena. |
| `400` | `ANALYTICS_REPORTING_PERIOD_OUTSIDE_ECCLESIASTICAL_YEAR` | El mes solicitado queda fuera del año seleccionado. |
| `401` | JWT faltante o inválido | Rechazo de `JwtAuthGuard`. |
| `403` | `GUARD_PERMISSION_DENIED` | Rol no admitido, destino fuera de scope o geografía desconocida solicitada por un actor scoped. |
| `403` | `ADMIN_USER_SCOPE_MISSING` | El rol requiere scope territorial, pero el perfil efectivo no contiene el ID numérico necesario. |
| `404` | `ADMIN_ECCLESIASTICAL_YEAR_NOT_FOUND` | No existe el año explícito o no hay año activo al omitirlo. |
| `404` | `ADMIN_DIVISION_NOT_FOUND`, `ADMIN_UNION_NOT_FOUND`, `ADMIN_LOCAL_FIELD_NOT_FOUND` | Solo para `super-admin` global que consulta geografía inexistente. |

Los errores de dominio siguen el envelope canónico:

```json
{
  "status": "error",
  "statusCode": 403,
  "code": "GUARD_PERMISSION_DENIED",
  "message": "...",
  "timestamp": "2026-07-15T00:00:00.000Z",
  "path": "/api/v1/admin/analytics/operations-dashboard"
}
```

Un actor territorial recibe el mismo `403 GUARD_PERMISSION_DENIED` tanto para un territorio existente fuera de alcance como para un ID geográfico inexistente. Esto evita enumeración. El `404` geográfico está reservado al actor global.

##### Caché

- `Map` en memoria por réplica, con TTL de 60 segundos.
- Key por `scope.level`, `scope.id`, año eclesiástico y periodo mensual o `none`.
- Un hit devuelve `cached: true` y conserva el `computed_at` del snapshot original.
- Una entrada vencida se elimina y recalcula; no existe stale-on-error.
- `cached: true` no significa stale y el contrato no expone `freshness`.

Semántica funcional y límites: [operations-dashboard.md](../features/operations-dashboard.md).

### Annual Evidence Folders

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/club-sections/:sectionId/annual-folder` | JWT | Permisos: evidence_folders:read | Get annual evidence folder for a club section (current year) | CatalogsService.getCurrentEcclesiasticalYear(), ClubEnrollmentsService.findCurrentBySectionId(), AnnualFoldersService.getFolderByEnrollment() | `src/annual-folders/annual-folder-by-section.controller.ts` |
| POST | `/api/v1/club-sections/:sectionId/annual-folder` | JWT | Permisos: evidence_folders:update | Create annual evidence folder for a club section | ClubEnrollmentsService.findCurrentBySectionId(), AnnualFoldersService.createFolderForEnrollment() | `src/annual-folders/annual-folder-by-section.controller.ts` |
| POST | `/api/v1/annual-folders/enrollments/:enrollmentId` | JWT | Permisos: evidence_folders:update | Create annual evidence folder for a club enrollment | AnnualFoldersService.createFolderForEnrollment() | `src/annual-folders/annual-folders.controller.ts` |
| GET | `/api/v1/annual-folders/evaluation/queue` | JWT | Permisos: annual_folders:evaluate | List annual evidence folders available for evaluation | AnnualFoldersService.getEvaluationQueue() | `src/annual-folders/annual-folders.controller.ts` |
| GET | `/api/v1/annual-folders/:folderId` | JWT | Permisos: evidence_folders:read | Get annual evidence folder with sections and evidences | AnnualFoldersService.getFolder() | `src/annual-folders/annual-folders.controller.ts` |
| GET | `/api/v1/annual-folders/by-enrollment/:enrollmentId` | JWT | Permisos: evidence_folders:read | Get annual evidence folder by enrollment ID | AnnualFoldersService.getFolderByEnrollment() | `src/annual-folders/annual-folders.controller.ts` |
| POST | `/api/v1/annual-folders/:folderId/sections/:sectionId/evidences` | JWT | Permisos: evidence_folders:update | Upload evidence to a folder section | AnnualFoldersService.uploadEvidence() | `src/annual-folders/annual-folders.controller.ts` |
| PATCH | `/api/v1/annual-folders/evidences/:evidenceId` | JWT | Permisos: evidence_folders:update | Update evidence metadata | AnnualFoldersService.updateEvidence() | `src/annual-folders/annual-folders.controller.ts` |
| DELETE | `/api/v1/annual-folders/evidences/:evidenceId` | JWT | Permisos: evidence_folders:update | Delete evidence | AnnualFoldersService.deleteEvidence() | `src/annual-folders/annual-folders.controller.ts` |
| GET | `/api/v1/annual-folders/:folderId/sections/:sectionId/status` | JWT | Permisos: evidence_folders:read | Get the current status of a single section within an annual evidence folder | AnnualFoldersService.getSectionStatus() | `src/annual-folders/annual-folders.controller.ts` |
| POST | `/api/v1/annual-folders/:folderId/sections/:sectionId/submit` | JWT | Permisos: evidence_folders:update | Submit a single section of an annual evidence folder | AnnualFoldersService.submitSection() | `src/annual-folders/annual-folders.controller.ts` |
| POST | `/api/v1/annual-folders/:folderId/submit` | JWT | Permisos: annual_folders:submit | Submit entire folder for review (director/secretariat only) | AnnualFoldersService.submitFolder() | `src/annual-folders/annual-folders.controller.ts` |
| POST | `/api/v1/annual-folders/:folderId/close` | JWT | Permisos: evidence_folders:update | Close folder (field-level action) | AnnualFoldersService.closeFolder() | `src/annual-folders/annual-folders.controller.ts` |

### Annual Evidence Folders - Templates

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/annual-folders/templates` | JWT | Permisos: annual_folder_templates:create | Create folder template for a club type and year | AnnualFoldersService.createTemplate() | `src/annual-folders/annual-folders.controller.ts` |
| GET | `/api/v1/annual-folders/templates/:templateId` | JWT | Permisos: annual_folder_templates:read | Get template by ID with all sections | AnnualFoldersService.getTemplate() | `src/annual-folders/annual-folders.controller.ts` |
| GET | `/api/v1/annual-folders/templates` | JWT | Permisos: annual_folder_templates:read | List templates or get template by club type and year | AnnualFoldersService.listTemplates(), AnnualFoldersService.getTemplateByClubTypeAndYear() | `src/annual-folders/annual-folders.controller.ts` |
| PATCH | `/api/v1/annual-folders/templates/:templateId` | JWT | Permisos: annual_folder_templates:update | Update annual folder template metadata | AnnualFoldersService.updateTemplate() | `src/annual-folders/annual-folders.controller.ts` |
| POST | `/api/v1/annual-folders/templates/:templateId/copy` | JWT | Permisos: annual_folder_templates:create | Copy an annual folder template as a draft | AnnualFoldersService.copyTemplate() | `src/annual-folders/annual-folders.controller.ts` |
| POST | `/api/v1/annual-folders/templates/:templateId/sections` | JWT | Permisos: annual_folder_templates:update | Add section to template | AnnualFoldersService.addTemplateSection() | `src/annual-folders/annual-folders.controller.ts` |
| PATCH | `/api/v1/annual-folders/templates/sections/:sectionId` | JWT | Permisos: annual_folder_templates:update | Update template section | AnnualFoldersService.updateTemplateSection() | `src/annual-folders/annual-folders.controller.ts` |
| DELETE | `/api/v1/annual-folders/templates/sections/:sectionId` | JWT | Permisos: annual_folder_templates:delete | Remove template section | AnnualFoldersService.removeTemplateSection() | `src/annual-folders/annual-folders.controller.ts` |
| DELETE | `/api/v1/annual-folders/templates/:templateId` | JWT | Permisos: annual_folder_templates:delete | Delete a draft annual folder template | AnnualFoldersService.removeTemplate() | `src/annual-folders/annual-folders.controller.ts` |

### Award Categories

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/award-categories` | JWT | Permisos: award_categories:create | Create an award category | AwardCategoriesService.create() | `src/annual-folders/award-categories.controller.ts` |
| GET | `/api/v1/award-categories` | JWT | Permisos: award_categories:read | List award categories with optional filters | AwardCategoriesService.findAll() | `src/annual-folders/award-categories.controller.ts` |
| GET | `/api/v1/award-categories/:categoryId` | JWT | Permisos: award_categories:read | Get a single award category by ID | AwardCategoriesService.findOne() | `src/annual-folders/award-categories.controller.ts` |
| PATCH | `/api/v1/award-categories/:categoryId` | JWT | Permisos: award_categories:update | Update an award category | AwardCategoriesService.update() | `src/annual-folders/award-categories.controller.ts` |
| DELETE | `/api/v1/award-categories/:categoryId` | JWT | Permisos: award_categories:delete | Deactivate an award category (soft delete) | AwardCategoriesService.remove() | `src/annual-folders/award-categories.controller.ts` |

### Annual Evidence Folders - Evaluation

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/annual-folders/:folderId/sections/:sectionId/evaluate` | JWT | Permisos: annual_folders:evaluate | Evaluate a section of an annual evidence folder | EvaluationService.evaluateSection() | `src/annual-folders/evaluation.controller.ts` |
| POST | `/api/v1/annual-folders/:folderId/sections/:sectionId/reopen` | JWT | Permisos: annual_folders:evaluate | Reopen a section for re-evaluation (removes existing evaluation) | EvaluationService.reopenSection() | `src/annual-folders/evaluation.controller.ts` |
| POST | `/api/v1/annual-folders/:folderId/sections/:sectionId/confirm-union` | JWT | Permisos: annual_folders:evaluate | Union actor confirms or overrides a pre-approved section | EvaluationService.confirmUnion() | `src/annual-folders/evaluation.controller.ts` |
| GET | `/api/v1/annual-folders/:folderId/evaluations` | JWT | Permisos: annual_folders:evaluate, evidence_folders:read (any) | Get all section evaluations for a folder | AnnualFoldersService.assertFolderReadAccessForUser(), EvaluationService.getFolderEvaluations() | `src/annual-folders/evaluation.controller.ts` |
| PATCH | `/api/v1/annual-folders/evidences/:evidenceId/reviewer-note` | JWT | Permisos: annual_folders:evaluate | Set or clear a reviewer note on a specific evidence file | AnnualFoldersService.setReviewerNote() | `src/annual-folders/evaluation.controller.ts` |

### Annual Evidence Folders - Rankings

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/annual-folders/rankings` | JWT | Permisos: rankings:read | Get club rankings for a given year and club type | RankingsService.getRankings() | `src/annual-folders/rankings.controller.ts` |
| GET | `/api/v1/annual-folders/rankings/club/:enrollmentId` | JWT | Permisos: rankings:read | Get all rankings for a specific club enrollment | RankingsService.getRankingForClub() | `src/annual-folders/rankings.controller.ts` |
| GET | `/api/v1/annual-folders/rankings/:enrollmentId/breakdown` | JWT | Permisos: rankings:read | Per-component score breakdown for a club enrollment | RankingsService.getBreakdown() | `src/annual-folders/rankings.controller.ts` |
| POST | `/api/v1/annual-folders/rankings/recalculate` | JWT | Permisos: rankings:recalculate | Encola recálculo de rankings de club (202). Poll GET rankings. | RankingsService.enqueueRecalculation() | `src/annual-folders/rankings.controller.ts` |

### annual-reports

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/annual-reports` | JWT | Permisos: reports:read | Listar informes anuales (admin) | AnnualReportsService.listForAdmin() | `src/annual-reports/annual-reports.controller.ts` |
| GET | `/api/v1/admin/annual-reports/:id` | JWT | Permisos: reports:read | Obtener informe anual por ID (admin) | AnnualReportsService.getReport() | `src/annual-reports/annual-reports.controller.ts` |
| PATCH | `/api/v1/admin/annual-reports/:id` | JWT | Permisos: reports:update | Actualizar datos manuales del informe anual (admin) | AnnualReportsService.updateManualData() | `src/annual-reports/annual-reports.controller.ts` |
| POST | `/api/v1/admin/annual-reports/:id/regenerate` | JWT | Permisos: reports:update | Regenerar datos calculados del informe anual (admin) | AnnualReportsService.regenerate() | `src/annual-reports/annual-reports.controller.ts` |
| POST | `/api/v1/admin/annual-reports/:id/finalize` | JWT | Permisos: reports:update | Finalizar informe anual (admin) | AnnualReportsService.finalize() | `src/annual-reports/annual-reports.controller.ts` |
| GET | `/api/v1/admin/annual-reports/:id/pdf` | JWT | Permisos: reports:download | Descargar PDF anual. Nombre: `informe-anual-{club}-{tipo}-{año}.pdf` | AnnualReportsPdfService.generatePdf() | `src/annual-reports/annual-reports.controller.ts` |
| GET | `/api/v1/clubs/:clubId/annual-reports` | JWT | Permisos: reports:read | Listar informes anuales de un club (usuario) | AnnualReportsService.listForClub() | `src/annual-reports/annual-reports.controller.ts` |
| GET | `/api/v1/clubs/:clubId/annual-reports/:id` | JWT | Permisos: reports:read | Obtener informe anual por ID (usuario) | AnnualReportsService.getReport() | `src/annual-reports/annual-reports.controller.ts` |
| GET | `/api/v1/clubs/:clubId/annual-reports/:id/pdf` | JWT | Permisos: reports:download | Descargar PDF anual. Nombre: `informe-anual-{club}-{tipo}-{año}.pdf` | AnnualReportsPdfService.generatePdf() | `src/annual-reports/annual-reports.controller.ts` |

### app.controller.ts

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/` | Public | - | Endpoint raíz de bienvenida/liveness básico | AppService.getHello() | `src/app.controller.ts` |

### auth

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/auth/register` | Public | - | Registrar nuevo usuario | AuthService.register() | `src/auth/auth.controller.ts` |
| POST | `/api/v1/auth/login` | Public | - | Iniciar sesión | AuthService.login() | `src/auth/auth.controller.ts` |
| POST | `/api/v1/auth/refresh` | Public | - | Refrescar sesión con refresh token | AuthService.refreshSession() | `src/auth/auth.controller.ts` |
| POST | `/api/v1/auth/logout` | Public | - | Cerrar sesión | AuthService.logout() | `src/auth/auth.controller.ts` |
| POST | `/api/v1/auth/password/reset-request` | Public | - | Solicitar recuperación de contraseña | AuthService.requestPasswordReset() | `src/auth/auth.controller.ts` |
| POST | `/api/v1/auth/password/reset` | Public | - | Confirmar recuperación de contraseña (`ResetPasswordDto`). Throttle 5/min. No emite sesión ni JWT: el cliente debe iniciar sesión de nuevo. Token inválido o expirado → 400 | AuthService.confirmPasswordReset() | `src/auth/auth.controller.ts` |
| POST | `/api/v1/auth/verify-email/send` | JWT | - | Enviar email de verificación al usuario autenticado | AuthService.sendVerificationEmail() | `src/auth/auth.controller.ts` |
| POST | `/api/v1/auth/verify-email/confirm` | Public | - | Confirmar verificación de email con token | AuthService.confirmEmailVerification() | `src/auth/auth.controller.ts` |
| POST | `/api/v1/auth/update-password` | JWT | - | Update authenticated user password | AuthService.updateOwnPassword() | `src/auth/auth.controller.ts` |
| GET | `/api/v1/auth/me` | JWT | - | Perfil + autorización. Pertenencia no inscrita actual con permisos vacíos. No incluye programación de director. Año solapado → 409 `ECCLESIASTICAL_YEAR_AMBIGUOUS` | AuthService.getProfile() | `src/auth/auth.controller.ts` |
| PATCH | `/api/v1/auth/me/context` | JWT | - | Cambiar contexto activo. `inactive`/`ended`/año no vigente/`designated` → 400 `AUTH_ASSIGNMENT_YEAR_MISMATCH`. Corte del club no completado → 503 `CLUB_CYCLE_NOT_READY`. No invalida JWT | AuthService.setActiveClubContext() | `src/auth/auth.controller.ts` |
| GET | `/api/v1/auth/profile/completion-status` | JWT | - | Obtener estado del post-registro | AuthService.getCompletionStatus() | `src/auth/auth.controller.ts` |
| DELETE | `/api/v1/auth/me` | JWT | - | Eliminar cuenta del usuario autenticado | AccountDeletionService.deleteAccount() | `src/auth/auth.controller.ts` |
| POST | `/api/v1/auth/mfa/enroll` | JWT | - | Habilitar 2FA (TOTP) | MfaService.enrollMfa() | `src/auth/mfa.controller.ts` |
| POST | `/api/v1/auth/mfa/verify` | JWT | - | Verificar código TOTP | MfaService.verifyMfa() | `src/auth/mfa.controller.ts` |
| DELETE | `/api/v1/auth/mfa/disable` | JWT | - | Deshabilitar 2FA | MfaService.disableMfa() | `src/auth/mfa.controller.ts` |
| GET | `/api/v1/auth/mfa/status` | JWT | - | Estado de 2FA | MfaService.getMfaStatus() | `src/auth/mfa.controller.ts` |
| GET | `/api/v1/auth/sessions` | JWT | - | List active sessions | SessionsService.listSessions() | `src/auth/sessions.controller.ts` |
| DELETE | `/api/v1/auth/sessions/:sessionId` | JWT | - | Revoke a specific session | SessionsService.revokeSession() | `src/auth/sessions.controller.ts` |
| DELETE | `/api/v1/auth/sessions` | JWT | - | Revoke all other sessions | SessionsService.revokeAllOtherSessions() | `src/auth/sessions.controller.ts` |

### OAuth

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/auth/oauth/google` | Public | - | Iniciar autenticación con Google | OAuthService.initiateGoogleSignIn() | `src/auth/oauth.controller.ts` |
| POST | `/api/v1/auth/oauth/apple` | Public | - | Iniciar autenticación con Apple | OAuthService.initiateAppleSignIn() | `src/auth/oauth.controller.ts` |
| POST | `/api/v1/auth/oauth/callback` | Public | - | Finalizar callback de OAuth | OAuthService.handleCallback() | `src/auth/oauth.controller.ts` |
| GET | `/api/v1/auth/oauth/providers` | JWT | - | Obtener providers OAuth conectados | OAuthService.getConnectedProviders() | `src/auth/oauth.controller.ts` |
| DELETE | `/api/v1/auth/oauth/:provider` | JWT | - | Desconectar un provider OAuth | OAuthService.disconnectProvider() | `src/auth/oauth.controller.ts` |

### camporee-event-templates

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/camporee-event-templates` | JWT | Permisos: camporee_events:read | List camporee event templates (filtered by role scope) | CamporeeEventTemplatesService.listTemplates() | `src/camporee-event-templates/camporee-event-templates.controller.ts` |
| GET | `/api/v1/camporee-event-templates/:templateId` | JWT | Permisos: camporee_events:read | Get camporee event template by ID | CamporeeEventTemplatesService.getTemplate() | `src/camporee-event-templates/camporee-event-templates.controller.ts` |
| POST | `/api/v1/camporee-event-templates` | JWT | Permisos: camporee_events:create | Create camporee event template | CamporeeEventTemplatesService.createTemplate() | `src/camporee-event-templates/camporee-event-templates.controller.ts` |
| PATCH | `/api/v1/camporee-event-templates/:templateId` | JWT | Permisos: camporee_events:update | Update camporee event template | CamporeeEventTemplatesService.updateTemplate() | `src/camporee-event-templates/camporee-event-templates.controller.ts` |
| DELETE | `/api/v1/camporee-event-templates/:templateId` | JWT | Permisos: camporee_events:delete | Soft delete camporee event template | CamporeeEventTemplatesService.deleteTemplate() | `src/camporee-event-templates/camporee-event-templates.controller.ts` |

### camporee-events

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/camporee-event-types` | JWT | Permisos: camporee_events:read | List active camporee event types for event forms | CamporeeEventsService.listEventTypes() | `src/camporee-events/camporee-events.controller.ts` |
| GET | `/api/v1/local-camporees/:camporeeId/events` | JWT | Permisos: camporee_events:read | List events for a local camporee | CamporeeEventsService.listEvents() | `src/camporee-events/camporee-events.controller.ts` |
| GET | `/api/v1/local-camporees/:camporeeId/events/preview` | JWT | Permisos: camporee_events:read | List app-safe event preview for a local camporee, hiding agenda until configured release | CamporeeEventsService.listEvents() | `src/camporee-events/camporee-events.controller.ts` |
| POST | `/api/v1/local-camporees/:camporeeId/events` | JWT | Permisos: camporee_events:create | Create custom event for a local camporee | CamporeeEventsService.createEvent() | `src/camporee-events/camporee-events.controller.ts` |
| POST | `/api/v1/local-camporees/:camporeeId/events/from-template/:templateId` | JWT | Permisos: camporee_events:create | Clone a template as an event for a local camporee | CamporeeEventsService.createFromTemplate() | `src/camporee-events/camporee-events.controller.ts` |
| GET | `/api/v1/union-camporees/:camporeeId/events` | JWT | Permisos: camporee_events:read | List events for a union camporee | CamporeeEventsService.listEvents() | `src/camporee-events/camporee-events.controller.ts` |
| GET | `/api/v1/union-camporees/:camporeeId/events/preview` | JWT | Permisos: camporee_events:read | List app-safe event preview for a union camporee, hiding agenda until configured release | CamporeeEventsService.listEvents() | `src/camporee-events/camporee-events.controller.ts` |
| POST | `/api/v1/union-camporees/:camporeeId/events` | JWT | Permisos: camporee_events:create | Create custom event for a union camporee | CamporeeEventsService.createEvent() | `src/camporee-events/camporee-events.controller.ts` |
| POST | `/api/v1/union-camporees/:camporeeId/events/from-template/:templateId` | JWT | Permisos: camporee_events:create | Clone a template as an event for a union camporee | CamporeeEventsService.createFromTemplate() | `src/camporee-events/camporee-events.controller.ts` |
| GET | `/api/v1/camporee-events/:eventId` | JWT | Permisos: camporee_events:read | Get a camporee event instance by ID | CamporeeEventsService.getEvent() | `src/camporee-events/camporee-events.controller.ts` |
| PATCH | `/api/v1/camporee-events/:eventId` | JWT | Permisos: camporee_events:update | Update a camporee event instance (overrides) | CamporeeEventsService.updateEvent() | `src/camporee-events/camporee-events.controller.ts` |
| GET | `/api/v1/camporee-events/:eventId/staff-assignments` | JWT | Permisos: camporee_events:read | List staff assignments for a camporee event | CamporeeEventsService.listEventStaffAssignments() | `src/camporee-events/camporee-events.controller.ts` |
| PUT | `/api/v1/camporee-events/:eventId/staff-assignments` | JWT | Permisos: camporee_events:update | Replace staff assignments for a camporee event | CamporeeEventsService.replaceEventStaffAssignments() | `src/camporee-events/camporee-events.controller.ts` |
| PUT | `/api/v1/camporee-events/:eventId/schedule-blocks` | JWT | Permisos: camporee_events:update | Replace optional schedule blocks and club-section assignments for a camporee event | CamporeeEventsService.replaceScheduleBlocks() | `src/camporee-events/camporee-events.controller.ts` |
| DELETE | `/api/v1/camporee-events/:eventId` | JWT | Permisos: camporee_events:delete | Soft delete a camporee event instance | CamporeeEventsService.deleteEvent() | `src/camporee-events/camporee-events.controller.ts` |
| PATCH | `/api/v1/camporee-events/:eventId/reorder` | JWT | Permisos: camporee_events:update | Update display_order of a camporee event instance | CamporeeEventsService.reorderEvent() | `src/camporee-events/camporee-events.controller.ts` |

POST/PATCH de instancia aceptan `honor_ids?: number[]` (máx. 20, únicos, honores activos). Omitir en PATCH no toca la lista; `[]` la vacía. GET, list y preview incluyen `honors[]` (`honor_id`, `name`, `honor_image`, `material_url`, `honors_category_id`, `category_name`, `skill_level`, `active`, `display_order`). Preview no oculta honores aunque la agenda esté cerrada. Errores: `CAMPOREE_EVENT_HONOR_NOT_FOUND`, `CAMPOREE_EVENT_HONOR_DUPLICATE`, `CAMPOREE_EVENT_HONOR_LIMIT`. No hay ruta dedicada. Templates y `from-template` no copian honores.

### camporee-scoring

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/camporee-events/:eventId/rubrics` | JWT | - | List active rubrics for a camporee event | CamporeeScoringService.getEventRubrics() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| PUT | `/api/v1/camporee-events/:eventId/rubrics` | JWT | Permisos: camporee_events:update | Replace rubrics for a camporee event | CamporeeScoringService.replaceEventRubrics() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| GET | `/api/v1/local-camporees/:camporeeId/judges` | JWT | Permisos: camporee_events:read | Listar/consultar local-camporees/{id}/judges | CamporeeScoringService.listCamporeeJudges() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| GET | `/api/v1/local-camporees/:camporeeId/judge-candidates` | JWT | Permisos: camporee_events:update | Listar/consultar local-camporees/{id}/judge-candidates | CamporeeScoringService.listCamporeeJudgeCandidates() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| POST | `/api/v1/local-camporees/:camporeeId/judges` | JWT | Permisos: camporee_events:update | Crear/ejecutar local-camporees/{id}/judges | CamporeeScoringService.addJudgeToCamporee() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| GET | `/api/v1/union-camporees/:camporeeId/judges` | JWT | Permisos: camporee_events:read | Listar/consultar union-camporees/{id}/judges | CamporeeScoringService.listCamporeeJudges() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| GET | `/api/v1/union-camporees/:camporeeId/judge-candidates` | JWT | Permisos: camporee_events:update | Listar/consultar union-camporees/{id}/judge-candidates | CamporeeScoringService.listCamporeeJudgeCandidates() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| POST | `/api/v1/union-camporees/:camporeeId/judges` | JWT | Permisos: camporee_events:update | Crear/ejecutar union-camporees/{id}/judges | CamporeeScoringService.addJudgeToCamporee() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| PATCH | `/api/v1/camporee-judges/:judgeId` | JWT | Permisos: camporee_events:update + scope del camporee del juez | Actualizar `notes`, `status` o `active` del juez | CamporeeScoringService.updateCamporeeJudge() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| DELETE | `/api/v1/camporee-judges/:judgeId` | JWT | Permisos: camporee_events:update + scope del camporee del juez | Desactivar al juez (`status=inactive`, `active=false`) y sus asignaciones activas | CamporeeScoringService.deactivateCamporeeJudge() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| GET | `/api/v1/camporee-events/:eventId/judge-assignments` | JWT | Permisos: camporee_events:read | Listar/consultar camporee-events/{id}/judge-assignments | CamporeeScoringService.listEventJudgeAssignments() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| POST | `/api/v1/camporee-events/:eventId/judge-assignments` | JWT | Permisos: camporee_events:update | Crear/ejecutar camporee-events/{id}/judge-assignments | CamporeeScoringService.assignJudgeToSection() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| PATCH | `/api/v1/camporee-event-judge-assignments/:assignmentId` | JWT | - | Actualizar camporee-event-judge-assignments/{id} | CamporeeScoringService.updateJudgeAssignment() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| DELETE | `/api/v1/camporee-event-judge-assignments/:assignmentId` | JWT | - | Eliminar/desactivar camporee-event-judge-assignments/{id} | CamporeeScoringService.deactivateJudgeAssignment() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| GET | `/api/v1/camporee-events/:eventId/scoring-targets` | JWT | - | List enrolled sections that can receive scores; each row includes `active_result_id` (`null` if the section has no official result yet) | CamporeeScoringService.getScoringTargets() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| GET | `/api/v1/camporee-events/:eventId/sections/:clubSectionId/score` | JWT | - | **Pendiente de merge (PR #448 de sacdia-backend)**: en `development` solo existe el `POST .../scores`. Active official score for one section, or `data: null` when none exists. Includes items, totals and `evaluator_name` | CamporeeScoringService.getOfficialScore() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| POST | `/api/v1/camporee-events/:eventId/sections/:clubSectionId/scores` | JWT | Header opcional `Idempotency-Key: <UUID>`; juez primary o override autorizado | Submit official camporee score/no-show with serialized target and replay-safe receipt | CamporeeScoringService.submitScore() | `src/camporee-scoring/camporee-scoring.controller.ts` |

#### Contrato de captura oficial de score

- Los listados `GET .../judges` devuelven `camporee_judge_id`, `user_id`, `name`, `email`, `notes`, `user_image`, `status` y `active`. Sólo incluyen filas activas del roster solicitado.
- `PATCH /camporee-judges/:judgeId` acepta `{ notes?: string | null, status?: "active" | "inactive", active?: boolean }`. Requiere `camporee_events:update`; el servicio resuelve el camporee padre desde el UUID del juez y valida acceso `current-write` antes de mutar. Un UUID inexistente devuelve `404 CAMPOREE_SCORING_JUDGE_NOT_FOUND` y un actor sin scope devuelve `403 CAMPOREE_EVENT_ACCESS_DENIED`.
- Cuando `PATCH` deja `active=false` o un `status` distinto de `active`, y siempre en `DELETE`, el juez y todas sus asignaciones activas se desactivan en la misma transacción. Las submissions/resultados históricos no se eliminan ni bloquean la operación: conservan su vínculo auditable con la asignación inactiva, por lo que este flujo no devuelve `409` por scores existentes.
- Desactivar el roster de scoring no desactiva automáticamente la fila independiente de `camporee_staff_members`; esa persona puede seguir cumpliendo una función operativa no relacionada con scoring.

- `GET /camporee-events/:eventId/rubrics` responde `{ data: rúbricas, min_points }`. `min_points` es el piso del evento; si es mayor que cero y la suma de criterios queda debajo, el puntaje oficial sube a ese piso. El listado de criterios sigue en `data`. `GET /camporee-events/:eventId/scoring-targets` no exige `camporee_events:read` en el guard: un juez activo asignado al evento también puede leer. El servicio rechaza al resto con `CAMPOREE_SCORING_FORBIDDEN`. Cada scoring-target incluye `active_result_id` para que admin envíe `expected_active_result_id` en un override.
- `POST /camporee-events/:eventId/sections/:clubSectionId/scores` tampoco exige `camporee_events:update` en el guard. El servicio acepta juez `primary` asignado (`judge_primary`) o gestores LF/Unión/admin con scope (`manual_lf`/`admin_override`).
- `Idempotency-Key` es opcional por compatibilidad, pero si llega debe ser UUID. El replay del mismo actor, clave y payload canónico devuelve el receipt original sin mutación; reutilizar la clave con otro payload devuelve `409 IDEMPOTENCY_KEY_REUSED`.
- `source` es una intención no confiable: el servidor deriva `judge_primary` para el juez principal asignado cuando no solicita override, `manual_lf` para gestores LF/Unión autorizados y `admin_override` sólo para `admin`, `assistant-admin` o `super-admin`. El permiso `camporee_events:update` por sí solo no autoriza scoring.
- El payload canónico incluye target, source efectiva, `no_show`/estado, notas, `expected_active_result_id` e ítems ordenados por rúbrica; no incluye timestamps.
- Con `Idempotency-Key`, el orden de serialización es fijo: lock bigint por `hashtextextended(prefijo + submitted_by + key, 0)`, lock `pg_advisory_xact_lock(eventId::integer, clubSectionId::integer)`, lookup idempotente y lectura del resultado activo. Los casts explícitos compensan que Prisma enlaza números JavaScript como `INT8` y fuerzan el overload PostgreSQL `(integer, integer)`. Ambos overloads usan keyspaces separados; el hash de 64 bits conserva un riesgo teórico de colisión que sólo sobre-serializa.
- Si el índice único produce `P2002` pese al lock, el servicio relee fuera de la transacción: mismo hash y receipt completo devuelve replay; hash distinto devuelve `409 IDEMPOTENCY_KEY_REUSED`; ausencia de fila relanza el error original. Un receipt sin resultado asociado falla con `500 CAMPOREE_SCORING_RECEIPT_INCOMPLETE`.
- Un override efectivo `manual_lf` o `admin_override` sobre resultado activo debe enviar `expected_active_result_id` igual al ID activo y `notes` no vacío como motivo; si falta el motivo devuelve `400 CAMPOREE_SCORING_OVERRIDE_REASON_REQUIRED`, y si el resultado no coincide devuelve `409 CAMPOREE_SCORING_RESULT_STALE`. El primer score manual, sin activo, puede omitir ambos.
- El receipt estable incluye `camporee_event_section_result_id`, `camporee_event_score_submission_id`, `score_status`, `raw_awarded_points`, `minimum_adjustment_points`, `total_awarded_points`, `total_max_points`, `percentage`, actor/timestamps de submit/finalización, `notes` e `items`. Su `active=true` es un snapshot del estado al emitirse; no representa el estado actual del resultado después de un override.
| GET | `/api/v1/local-camporees/:camporeeId/leaderboard` | JWT | Permisos: camporee_events:read | Obtener local-camporees/{id}/leaderboard | CamporeeScoringService.getCamporeeLeaderboard() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| GET | `/api/v1/union-camporees/:camporeeId/leaderboard` | JWT | Permisos: camporee_events:read | Obtener union-camporees/{id}/leaderboard | CamporeeScoringService.getCamporeeLeaderboard() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| GET | `/api/v1/camporee-judges/me/assignments` | JWT | - | List current user camporee judge assignments (`event_title`, `club_name`, `section_name`, `can_submit_score`) | CamporeeScoringService.getMyJudgeAssignments() | `src/camporee-scoring/camporee-scoring.controller.ts` |

### camporee-staff

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/local-camporees/:camporeeId/staff` | JWT | Permisos: camporee_events:read | List staff roster for a local camporee | CamporeeStaffService.listStaff() | `src/camporee-staff/camporee-staff.controller.ts` |
| GET | `/api/v1/local-camporees/:camporeeId/staff-candidates` | JWT | Permisos: camporee_events:update | List active users eligible for a local camporee roster | CamporeeStaffService.listStaffCandidates() | `src/camporee-staff/camporee-staff.controller.ts` |
| POST | `/api/v1/local-camporees/:camporeeId/staff` | JWT | Permisos: camporee_events:update | Add a staff member to a local camporee roster | CamporeeStaffService.addStaffMember() | `src/camporee-staff/camporee-staff.controller.ts` |
| GET | `/api/v1/union-camporees/:camporeeId/staff` | JWT | Permisos: camporee_events:read | List staff roster for a union camporee | CamporeeStaffService.listStaff() | `src/camporee-staff/camporee-staff.controller.ts` |
| GET | `/api/v1/union-camporees/:camporeeId/staff-candidates` | JWT | Permisos: camporee_events:update | List active users eligible for a union camporee roster | CamporeeStaffService.listStaffCandidates() | `src/camporee-staff/camporee-staff.controller.ts` |
| POST | `/api/v1/union-camporees/:camporeeId/staff` | JWT | Permisos: camporee_events:update | Add a staff member to a union camporee roster | CamporeeStaffService.addStaffMember() | `src/camporee-staff/camporee-staff.controller.ts` |
| PATCH | `/api/v1/camporee-staff/:staffMemberId` | JWT | Permisos: camporee_events:update | Update a camporee staff roster member | CamporeeStaffService.updateStaffMember() | `src/camporee-staff/camporee-staff.controller.ts` |
| DELETE | `/api/v1/camporee-staff/:staffMemberId` | JWT | Permisos: camporee_events:update | Deactivate a camporee staff roster member | CamporeeStaffService.deactivateStaffMember() | `src/camporee-staff/camporee-staff.controller.ts` |

### camporee-venues

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/camporee-venues` | JWT | Permisos: camporee_events:read | List all venues with optional filters | CamporeeVenuesService.listVenues() | `src/camporee-venues/camporee-venues.controller.ts` |
| GET | `/api/v1/camporee-venues/:venueId` | JWT | Permisos: camporee_events:read | Get a single venue by ID | CamporeeVenuesService.getVenueById() | `src/camporee-venues/camporee-venues.controller.ts` |
| POST | `/api/v1/camporee-venues` | JWT | Permisos: camporee_events:create | Create a venue (explicit scope + union/local_field) | CamporeeVenuesService.createVenue() | `src/camporee-venues/camporee-venues.controller.ts` |
| PATCH | `/api/v1/camporee-venues/:venueId` | JWT | Permisos: camporee_events:update | Update a venue | CamporeeVenuesService.updateVenue() | `src/camporee-venues/camporee-venues.controller.ts` |
| DELETE | `/api/v1/camporee-venues/:venueId` | JWT | Permisos: camporee_events:delete | Soft-delete a venue (sets active = false) | CamporeeVenuesService.deleteVenue() | `src/camporee-venues/camporee-venues.controller.ts` |
| GET | `/api/v1/local-camporees/:camporeeId/venues` | JWT | Permisos: camporee_events:read | List venues accessible to a local camporee | CamporeeVenuesService.listVenuesForCamporee() | `src/camporee-venues/camporee-venues.controller.ts` |
| POST | `/api/v1/local-camporees/:camporeeId/venues` | JWT | Permisos: camporee_events:create | Create a venue scoped to the local camporee's local_field | CamporeeVenuesService.createVenueForLocalCamporee() | `src/camporee-venues/camporee-venues.controller.ts` |
| GET | `/api/v1/union-camporees/:camporeeId/venues` | JWT | Permisos: camporee_events:read | List venues accessible to a union camporee | CamporeeVenuesService.listVenuesForCamporee() | `src/camporee-venues/camporee-venues.controller.ts` |
| POST | `/api/v1/union-camporees/:camporeeId/venues` | JWT | Permisos: camporee_events:create | Create a venue scoped to the union camporee's union | CamporeeVenuesService.createVenueForUnionCamporee() | `src/camporee-venues/camporee-venues.controller.ts` |

### camporees

Los `POST` y `PATCH` de camporees locales y de unión aceptan `start_date` y `end_date` exclusivamente como `YYYY-MM-DD` válido. `club_registration_opens_at`, `club_registration_deadline`, `member_registration_deadline` y `payment_deadline` exigen ISO-8601 con `Z` u offset explícito; no se aceptan fechas sin hora. `timezone` debe ser IANA: al enviarla explícitamente, el backend registra la verificación con el actor autenticado; omitirla en `PATCH` conserva la verificación anterior. La política única resuelve la fase por calendario local y la disposición de clubes: cierre manual primero, luego `not_open_yet`, `open` hasta el deadline inclusivo, y `late_approval_required` sólo después. `not_open_yet` no crea ni habilita aprobación tardía.

`GET`/`POST`/`PATCH` de camporee local y de unión incluyen `orders_enabled`, `orders_opens_at` y `orders_deadline`. No hay `GET` dedicado de orders-settings; la ventana también viaja en `GET .../order-offerings`. Mutación dedicada: `PATCH .../orders-settings`. Ver §camporee orders.

Los mismos `GET`/`POST` de camporee aceptan `supply_edit_cutoff_local_time` (default `21:00`). Mutación dedicada: `PATCH .../supply-settings`. Ver §camporee supplies.

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/camporees` | JWT | Permisos: camporees:read. Recorte territorial rol-primero (`director-lf`/unión/división y admin con ancla); coordinador sin asignación de club → denegado. Query opcional `club_type_id` (1=Aventureros, 2=Conquistadores, 3=Guías Mayores) recorta por `includes_*`; sin el query el catálogo territorial queda completo (admin). | Listar camporees | CamporeesService.findAll() | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/union` | JWT | Permisos: camporees:read. Mismo recorte rol-primero que el listado local (campo / unión / división). | Listar camporees de unión | CamporeesService.findAllUnion() | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/union/:camporeeId` | JWT | Permisos: camporees:read | Obtener camporee de unión por ID | CamporeesService.findOneUnion() | `src/camporees/camporees.controller.ts` |
| POST | `/api/v1/camporees/union` | JWT | Permisos: camporees:create | Crear camporee de unión | CamporeesService.createUnion() | `src/camporees/camporees.controller.ts` |
| PATCH | `/api/v1/camporees/union/:camporeeId` | JWT | Permisos: camporees:update | Actualizar camporee de unión | CamporeesService.updateUnion() | `src/camporees/camporees.controller.ts` |
| DELETE | `/api/v1/camporees/union/:camporeeId` | JWT | Permisos: camporees:delete | Desactivar camporee de unión | CamporeesService.removeUnion() | `src/camporees/camporees.controller.ts` |
| POST | `/api/v1/camporees/union/:camporeeId/clubs` | JWT | Permisos: attendance:manage | Inscribir club en camporee de unión | CamporeesService.enrollClubToUnion() | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/union/:camporeeId/clubs` | JWT | Permisos: attendance:read | Listar clubes inscritos en camporee de unión | CamporeesService.getUnionEnrolledClubs() | `src/camporees/camporees.controller.ts` |
| DELETE | `/api/v1/camporees/union/:camporeeId/clubs/:camporeeClubId` | JWT | Permisos: attendance:manage | Cancelar inscripción de club en camporee de unión | CamporeesService.cancelUnionClubEnrollment() | `src/camporees/camporees.controller.ts` |
| POST | `/api/v1/union-camporees/:camporeeId/club-registration/close` | JWT | Permisos: camporee_events:update | Close union camporee club registration | CamporeesService.closeUnionCamporeeClubRegistration() | `src/camporees/camporee-club-registration.controller.ts` |
| POST | `/api/v1/union-camporees/:camporeeId/club-registration/reopen` | JWT | Permisos: camporee_events:update | Reopen union camporee club registration | CamporeesService.reopenUnionCamporeeClubRegistration() | `src/camporees/camporee-club-registration.controller.ts` |
| POST | `/api/v1/camporees/union/:camporeeId/register` | JWT | Permisos: attendance:manage | Registrar miembro en camporee de unión | CamporeesService.registerMemberToUnion() | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/union/:camporeeId/members` | JWT | Permisos: attendance:read | Listar miembros del camporee de unión | CamporeesService.getUnionMembers() | `src/camporees/camporees.controller.ts` |
| DELETE | `/api/v1/camporees/union/:camporeeId/members/:userId` | JWT | Permisos: attendance:manage | Remover miembro del camporee de unión | CamporeesService.removeUnionMember() | `src/camporees/camporees.controller.ts` |
| POST | `/api/v1/camporees/union/:camporeeId/members/:memberId/payments` | JWT | Permisos: attendance:manage | Registrar pago de miembro en camporee de unión | CamporeesService.createUnionPayment() | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/union/:camporeeId/members/:memberId/payments` | JWT | Permisos: attendance:read | Listar pagos de un miembro en camporee de unión | CamporeesService.getUnionMemberPayments() | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/union/:camporeeId/payments` | JWT | Permisos: attendance:read | Listar todos los pagos del camporee de unión | CamporeesService.getUnionCamporeePayments() | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/union/:camporeeId/pending` | JWT | Permisos: attendance:approve_late | Listar inscripciones pendientes de aprobación en camporee de unión | CamporeeLateApprovalsService.listUnionPending() | `src/camporees/camporees.controller.ts` |
| PATCH | `/api/v1/camporees/union/:camporeeId/clubs/:camporeeClubId/approve` | JWT | Permisos: attendance:approve_late | Aprobar inscripción tardía de club en camporee de unión | CamporeeLateApprovalsService.approveUnionClubEnrollment() | `src/camporees/camporees.controller.ts` |
| PATCH | `/api/v1/camporees/union/:camporeeId/clubs/:camporeeClubId/reject` | JWT | Permisos: attendance:approve_late | Rechazar inscripción tardía de club en camporee de unión | CamporeeLateApprovalsService.rejectUnionClubEnrollment() | `src/camporees/camporees.controller.ts` |
| PATCH | `/api/v1/camporees/union/:camporeeId/members/:camporeeMemberId/approve` | JWT | Permisos: attendance:approve_late | Aprobar inscripción tardía de miembro en camporee de unión | CamporeeLateApprovalsService.approveUnionMemberEnrollment() | `src/camporees/camporees.controller.ts` |
| PATCH | `/api/v1/camporees/union/:camporeeId/members/:camporeeMemberId/reject` | JWT | Permisos: attendance:approve_late | Rechazar inscripción tardía de miembro en camporee de unión | CamporeeLateApprovalsService.rejectUnionMemberEnrollment() | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/:camporeeId/pending` | JWT | Permisos: attendance:approve_late | Listar inscripciones pendientes de aprobación | CamporeeLateApprovalsService.listPending() | `src/camporees/camporees.controller.ts` |
| PATCH | `/api/v1/camporees/:camporeeId/clubs/:camporeeClubId/approve` | JWT | Permisos: attendance:approve_late | Aprobar inscripción tardía de club | CamporeeLateApprovalsService.approveLocalClubEnrollment() | `src/camporees/camporees.controller.ts` |
| PATCH | `/api/v1/camporees/:camporeeId/clubs/:camporeeClubId/reject` | JWT | Permisos: attendance:approve_late | Rechazar inscripción tardía de club | CamporeeLateApprovalsService.rejectLocalClubEnrollment() | `src/camporees/camporees.controller.ts` |
| PATCH | `/api/v1/camporees/:camporeeId/members/:camporeeMemberId/approve` | JWT | Permisos: attendance:approve_late | Aprobar inscripción tardía de miembro | CamporeeLateApprovalsService.approveLocalMemberEnrollment() | `src/camporees/camporees.controller.ts` |
| PATCH | `/api/v1/camporees/:camporeeId/members/:camporeeMemberId/reject` | JWT | Permisos: attendance:approve_late | Rechazar inscripción tardía de miembro | CamporeeLateApprovalsService.rejectLocalMemberEnrollment() | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/:camporeeId/section-registration` | JWT | Permisos: camporees:read | Estado contextual de inscripción al camporee de la sección activa del actor (`CamporeeSectionRegistrationDto`) | CamporeesService.getActiveSectionRegistration() | `src/camporees/camporees.controller.ts` |
| POST | `/api/v1/camporees/:camporeeId/section-registration` | JWT | Permisos: camporees:register_active_section | Inscribir la sección activa del actor. No acepta un ID de sección enviado por el cliente. 400 si la inscripción no está disponible | CamporeesService.registerActiveSection() | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/:camporeeId` | JWT | Permisos: camporees:read | Obtener camporee por ID | CamporeesService.findOne() | `src/camporees/camporees.controller.ts` |
| POST | `/api/v1/camporees` | JWT | Permisos: camporees:create | Crear camporee | CamporeesService.create() | `src/camporees/camporees.controller.ts` |
| PATCH | `/api/v1/camporees/:camporeeId` | JWT | Permisos: camporees:update | Actualizar camporee | CamporeesService.update() | `src/camporees/camporees.controller.ts` |
| DELETE | `/api/v1/camporees/:camporeeId` | JWT | Permisos: camporees:delete | Desactivar camporee | CamporeesService.remove() | `src/camporees/camporees.controller.ts` |
| POST | `/api/v1/camporees/:camporeeId/register` | JWT | Permisos: attendance:manage | Registrar miembro en camporee | CamporeesService.registerMember() | `src/camporees/camporees.controller.ts` |
| POST | `/api/v1/camporees/:camporeeId/participants` | JWT | Permisos: attendance:manage | Alias contextual para registrar participantes con la sección activa del director (`RegisterMemberDto`). 422 `CAMPOREE_SECTION_REGISTRATION_REQUIRED` o `CAMPOREE_MEMBER_OUTSIDE_ACTIVE_SECTION` | CamporeesService.registerParticipants() | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/:camporeeId/members` | JWT | Permisos: attendance:read | Listar miembros del camporee | CamporeesService.getMembers() | `src/camporees/camporees.controller.ts` |
| DELETE | `/api/v1/camporees/:camporeeId/members/:userId` | JWT | Permisos: attendance:manage | Remover miembro del camporee | CamporeesService.removeMember() | `src/camporees/camporees.controller.ts` |
| POST | `/api/v1/camporees/:camporeeId/clubs` | JWT | Permisos: attendance:manage | Inscribir club en camporee | CamporeesService.enrollClub() | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/:camporeeId/clubs` | JWT | Permisos: attendance:read | Listar clubes inscritos en camporee | CamporeesService.getEnrolledClubs() | `src/camporees/camporees.controller.ts` |
| DELETE | `/api/v1/camporees/:camporeeId/clubs/:camporeeClubId` | JWT | Permisos: attendance:manage | Cancelar inscripción de club | CamporeesService.cancelClubEnrollment() | `src/camporees/camporees.controller.ts` |
| POST | `/api/v1/camporees/:camporeeId/club-registration/close` | JWT | Permisos: camporee_events:update | Close local camporee club registration | CamporeesService.closeLocalCamporeeClubRegistration() | `src/camporees/camporee-club-registration.controller.ts` |
| POST | `/api/v1/camporees/:camporeeId/club-registration/reopen` | JWT | Permisos: camporee_events:update | Reopen local camporee club registration | CamporeesService.reopenLocalCamporeeClubRegistration() | `src/camporees/camporee-club-registration.controller.ts` |
| POST | `/api/v1/camporees/:camporeeId/members/:memberId/payments` | JWT | Permisos: attendance:manage | Registrar pago de miembro | CamporeesService.createPayment() | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/:camporeeId/members/:memberId/payments` | JWT | Permisos: attendance:read | Listar pagos de un miembro | CamporeesService.getMemberPayments() | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/:camporeeId/payments` | JWT | Permisos: attendance:read | Listar todos los pagos del camporee | CamporeesService.getCamporeePayments() | `src/camporees/camporees.controller.ts` |
| PATCH | `/api/v1/camporees/payments/:paymentId` | JWT | Permisos: attendance:manage | Actualizar pago | CamporeesService.updatePayment() | `src/camporees/camporees.controller.ts` |
| POST | `/api/v1/camporees/:camporeeId/payments/:paymentId/voucher` | JWT | Permisos: attendance:manage | Adjuntar comprobante a un pago | CamporeesService.uploadPaymentVoucher() | `src/camporees/camporees.controller.ts` |
| DELETE | `/api/v1/camporees/:camporeeId/payments/:paymentId/voucher` | JWT | Permisos: attendance:manage | Remover comprobante de un pago | CamporeesService.removePaymentVoucher() | `src/camporees/camporees.controller.ts` |
| PATCH | `/api/v1/camporees/payments/:camporeePaymentId/approve` | JWT | Permisos: attendance:approve_late | Aprobar pago tardío de camporee | CamporeeLateApprovalsService.approvePayment() | `src/camporees/camporees.controller.ts` |
| PATCH | `/api/v1/camporees/payments/:camporeePaymentId/reject` | JWT | Permisos: attendance:approve_late | Rechazar pago tardío de camporee | CamporeeLateApprovalsService.rejectPayment() | `src/camporees/camporees.controller.ts` |

### catalogs

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/catalogs/club-types` | JWT | - | Obtener tipos de club | CatalogsService.getClubTypes() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/activity-types` | JWT | - | Obtener tipos de actividad | CatalogsService.getActivityTypes() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/relationship-types` | JWT | - | Obtener tipos de relación | CatalogsService.getRelationshipTypes() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/countries` | JWT opcional (`@Public` + OptionalJwt) | - | Países. Sin JWT / sin rol territorial: directorio completo. Con rol territorial: solo el país del actor. | CatalogsService.getCountries() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/divisions` | JWT opcional (`@Public` + OptionalJwt) | - | Divisiones. Con rol territorial: solo las que tienen uniones en el país del actor. | CatalogsService.getDivisions() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/unions` | JWT opcional (`@Public` + OptionalJwt) | - | Uniones. Con rol territorial: uniones del país del actor; `countryId`/`divisionId` de otro país → 403 `GUARD_PERMISSION_DENIED`. | CatalogsService.getUnions() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/local-fields` | JWT opcional (`@Public` + OptionalJwt) | - | Campos locales. Con rol territorial: campos del país del actor; `unionId` de otro país → 403 `GUARD_PERMISSION_DENIED`. | CatalogsService.getLocalFields() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/districts` | JWT opcional (`@Public` + OptionalJwt) | - | Distritos. Con rol territorial: distritos del país del actor; `localFieldId` de otro país → 403 `GUARD_PERMISSION_DENIED`. | CatalogsService.getDistricts() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/churches` | JWT opcional (`@Public` + OptionalJwt) | - | Iglesias. Con rol territorial: iglesias del país del actor; `districtId` de otro país → 403 `GUARD_PERMISSION_DENIED`. | CatalogsService.getChurches() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/roles` | JWT | - | Obtener roles disponibles | CatalogsService.getRoles() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/ecclesiastical-years` | JWT | - | Obtener años eclesiásticos | CatalogsService.getEcclesiasticalYears() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/ecclesiastical-years/current` | JWT | - | Obtener año eclesiástico actual | CatalogsService.getCurrentEcclesiasticalYear() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/club-ideals` | JWT | - | Obtener ideales de club | CatalogsService.getClubIdeals() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/allergies` | JWT | - | Obtener catálogo de alergias | CatalogsService.getAllergies() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/diseases` | JWT | - | Obtener catálogo de enfermedades | CatalogsService.getDiseases() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/medicines` | JWT | - | Obtener catálogo de medicamentos | CatalogsService.getMedicines() | `src/catalogs/catalogs.controller.ts` |

### admin-certificate-bulk-imports

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/certificate-bulk-imports/pending` | JWT | Global: super-admin, admin, assistant-admin, director-lf, assistant-lf | Listar cargas por certificado pendientes | AdminCertificateBulkImportsService.listPending() | `src/certificate-bulk-imports/admin-certificate-bulk-imports.controller.ts` |
| GET | `/api/v1/admin/certificate-bulk-imports/:batchId` | JWT | Global: super-admin, admin, assistant-admin, director-lf, assistant-lf | Obtener detalle de carga por certificado | AdminCertificateBulkImportsService.getDetail() | `src/certificate-bulk-imports/admin-certificate-bulk-imports.controller.ts` |
| POST | `/api/v1/admin/certificate-bulk-imports/:batchId/approve` | JWT | Global: super-admin, admin, assistant-admin, director-lf, assistant-lf | Rechaza decidir el lote entero. Cada fila se aprueba sola | AdminCertificateBulkImportsService.approveBatch() | `src/certificate-bulk-imports/admin-certificate-bulk-imports.controller.ts` |
| POST | `/api/v1/admin/certificate-bulk-imports/:batchId/reject` | JWT | Global: super-admin, admin, assistant-admin, director-lf, assistant-lf | Rechaza decidir el lote entero. Cada fila se rechaza sola | AdminCertificateBulkImportsService.rejectBatch() | `src/certificate-bulk-imports/admin-certificate-bulk-imports.controller.ts` |
| POST | `/api/v1/admin/certificate-bulk-imports/:batchId/items/:itemId/approve` | JWT | Global: super-admin, admin, assistant-admin, director-lf, assistant-lf | Aprobar una fila. Si hay cursado operativo no investido del mismo periodo, exige `reconcile_enrollment_id` y `expected_modified_at` | AdminCertificateBulkImportsService.approveItem() | `src/certificate-bulk-imports/admin-certificate-bulk-imports.controller.ts` |
| POST | `/api/v1/admin/certificate-bulk-imports/:batchId/items/:itemId/reject` | JWT | Global: super-admin, admin, assistant-admin, director-lf, assistant-lf | Rechazar una fila del lote con motivo | AdminCertificateBulkImportsService.rejectItem() | `src/certificate-bulk-imports/admin-certificate-bulk-imports.controller.ts` |

### certificate-bulk-imports

Edad histórica de una fila de clase, al inicio del año eclesiástico de `completed_at`: `CERTIFICATE_IMPORT_BIRTHDAY_REQUIRED`, `CERTIFICATE_IMPORT_CLASS_MINIMUM_AGE_REQUIRED`, `CERTIFICATE_IMPORT_AGE_BELOW_MINIMUM` (`namedArgs`: `age`, `minimumAge`), y los de periodo `CERTIFICATE_IMPORT_DATE_REQUIRED`, `CERTIFICATE_IMPORT_YEAR_NOT_FOUND`, `CERTIFICATE_IMPORT_YEAR_AMBIGUOUS`. Ocurren al dejar la fila lista, al enviarla, al reenviarla y al aprobarla. `PATCH` con `mark_as_ready: true` y edad inválida no guarda. Un `POST` que crea el lote con `mark_as_ready: true` y la edad inválida deja el ítem en `NEEDS_REVIEW` con el motivo; con datos válidos nace `READY`. Lo mismo vale para un catálogo inexistente o inactivo (`CERTIFICATE_IMPORT_CATALOG_NOT_FOUND`) y para una fecha futura (`CERTIFICATE_IMPORT_DATE_IN_FUTURE`), también con `mark_as_ready: false`: al crear (lote con `items[]` o `POST` de un ítem) el ítem nace `NEEDS_REVIEW` con ese código en `rejection_reason` y no falla el lote. El `PATCH` de un ítem es la ruta de edición explícita y sigue respondiendo 400 con esos mismos códigos. Un `PATCH` de una fila de clase ya `READY`, sin `mark_as_ready` o con `false`, guarda la corrección como `NEEDS_REVIEW` si la edad ya no alcanza. La aprobación institucional usa la misma comprobación dentro de la transacción que escribe `APPROVED`.

Solicitud viva de la misma persona y clase: el año que decide es `investiture_authorization_requests.ecclesiastical_year_id` del `PENDING`, no el año de inicio del enrollment. Si el certificado cae en ese año, HTTP 400 `CERTIFICATE_IMPORT_AUTHORIZATION_PENDING`. El mensaje dice que la persona tiene una solicitud de investidura pendiente en este año y que la autorización tiene prioridad. Ocurre al marcar la fila lista, al enviar, al reenviar y al aprobar, y también al crear o aprobar una solicitud institucional, incluida la sustitución de Guía Mayor. La autoridad es la aprobación: no escribe enrollment, historial, evento ni conciliación, y el ítem no queda aprobado. Sin un `PENDING` de esa persona y clase, el mismo año sigue la reconciliación actual. Si el certificado es anterior al año de esa solicitud y la inscripción vinculada sigue `OPERATIONAL`, se acredita y en la misma transacción esa persona pasa a `REMOVED` con `resolution_code` `HISTORICAL_CERTIFICATE_APPLIED` y `system_reason` «Investidura aplicada por certificado de un año anterior». No usa el texto de falta de requisitos, no emite `class.completed` desde la solicitud, no crea un resultado de autorización y no envía correo. La aprobación institucional de un año anterior a la solicitud hace ese retiro y deja la solicitud `APPROVED`; no crea un enrollment. Una clase de un solo año no cambia, porque el año de la solicitud y el del enrollment coinciden. Los roles que aprueban no cambian. Si el año de esa solicitud ya terminó —el año está inactivo, o el día local del Campo de la solicitud es posterior a `end_date`; la zona sale de sección → club → Campo y, si falta, es `America/Mexico_City`— aunque el barrido de year-cut no haya corrido, la misma transacción la deja `CLOSED_YEAR` con `resolution_code` `CLOSED_YEAR`, sin motivo de falta de requisitos y sin evento. Un certificado de un año posterior no escribe `system_reason`. Un certificado de ese mismo año acredita, conserva `CLOSED_YEAR` y escribe `system_reason` «Investidura acreditada posteriormente mediante certificado validado». Lo aprueba `director-lf` o `assistant-lf` de ese Campo, o `admin`, `assistant-admin` o `super-admin` en su alcance. Otro Campo, un `director-lf` o `assistant-lf` sin Campo, o un actor sin esos roles: HTTP 403 `CERTIFICATE_IMPORT_ENDED_YEAR_FIELD_FORBIDDEN` (código traducible), sin efectos. Si el lote quedó en un Campo distinto al de la solicitud, solo un admin global o `super-admin` acredita. El lote sigue limitado por `batch.local_field_id`. Antes del `FOR SHARE` de usuario, clase y año, el envío, el reenvío y la aprobación reúnen los años de las fechas y los años de solicitud `PENDING` y toman `investiture-authorization-year:` de ese conjunto en orden ascendente de `year_id`. La validación de cada ítem no vuelve a tomar esos candados. Después, la aprobación toma `investiture-authorization-user:` y `investiture-authorization-enrollment:` en orden ascendente. El de usuario se toma aunque la primera lectura no vea un `PENDING`.

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/certificate-bulk-imports` | JWT | Dueño, desde el JWT | Listar expedientes propios | CertificateBulkImportsService.listMine() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |
| POST | `/api/v1/certificate-bulk-imports` | JWT | - | Crear un borrador de carga por certificado | CertificateBulkImportsService.createDraft() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |
| POST | `/api/v1/certificate-bulk-imports/:batchId/items` | JWT | Dueño, borrador | Alta manual de fila | CertificateBulkImportsService.addItem() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |
| DELETE | `/api/v1/certificate-bulk-imports/:batchId/items/:itemId` | JWT | Dueño, borrador | Quitar fila no enviada | CertificateBulkImportsService.removeItem() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |
| POST | `/api/v1/certificate-bulk-imports/:batchId/process-ocr` | JWT | - | Encola lectura Google Vision ADC para JPEG/PNG/WebP y PDF completo de 1–5 páginas (≤10 MiB). Sin Redis: `CERTIFICATE_IMPORT_OCR_UNAVAILABLE`. Credenciales, cuota y lectura fallida se resuelven asíncronamente; no hay `OCR_PROCESSED` ante fallo | CertificateBulkImportsService.processOcr() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |
| GET | `/api/v1/certificate-bulk-imports/:batchId` | JWT | - | Obtener detalle de una carga por certificado | CertificateBulkImportsService.getBatch() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |
| PATCH | `/api/v1/certificate-bulk-imports/:batchId/items/:itemId` | JWT | - | Corregir o completar una fila detectada por OCR | CertificateBulkImportsService.updateItem() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |
| POST | `/api/v1/certificate-bulk-imports/:batchId/submit` | JWT | - | Enviar carga por certificado a validación de Campo Local | CertificateBulkImportsService.submit() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |
| POST | `/api/v1/certificate-bulk-imports/:batchId/items/:itemId/resubmit` | JWT | - | Corregir y reenviar una fila rechazada | CertificateBulkImportsService.resubmitItem() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |
| POST | `/api/v1/certificate-bulk-imports/:batchId/files/presign` | JWT | Dueño del lote | Preparar subida firmada de un comprobante | CertificateImportFilesService.presign() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |
| POST | `/api/v1/certificate-bulk-imports/:batchId/files/:fileId/confirm` | JWT | Dueño del lote | Confirmar bytes reales y sellar; PDF válido 1–5 páginas, no cifrado. PDF_INVALID/PDF_ENCRYPTED/PDF_TOO_MANY_PAGES → 400 | CertificateImportFilesService.confirm() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |
| GET | `/api/v1/certificate-bulk-imports/:batchId/files/:fileId/download` | JWT | Dueño; Campo Local en su ámbito; evidencia institucional solo dueño o super-admin | URL efímera del objeto sellado | CertificateImportFilesService.download() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |
| DELETE | `/api/v1/certificate-bulk-imports/:batchId/files/:fileId` | JWT | Dueño, solo expediente editable y sin filas enviadas | Retirar comprobante no enviado | CertificateImportFilesService.remove() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |

#### Contrato de archivos/OCR por certificado (2026-10-01)

- Un documento activo por lote; JPEG/PNG/WebP/PDF, **máximo binario 10 MiB**. Secuencia: crear borrador → presign → PUT privado R2 → confirm → consultar lote → process-ocr. El PUT firmado no recibe Bearer de la API ni sigue redirects.
- `confirm` valida bytes y estructura PDF real antes de `CONFIRMED`; máximo **cinco páginas del documento completo**, no truncamiento de páginas. Cifrado, cierre/xref mínimo inválido, corrupción/truncamiento, cero o >5 páginas se rechazan. PDF se sella desde el Buffer validado en una clave exclusiva por intento; imágenes mantienen su clave existente. No copiar staging mutable después de validar PDF.
- Errores PDF HTTP **400**, nombres completos: `CERTIFICATE_IMPORT_PDF_TOO_MANY_PAGES`, `CERTIFICATE_IMPORT_PDF_ENCRYPTED`, `CERTIFICATE_IMPORT_PDF_INVALID`. Mantiene códigos existentes de tamaño/MIME/storage/ownership. Son `BadRequestException` legacy: el código llega en **`message`**, no debe asumirse `code`. Ejemplo (timestamp/path omitidos):

```json
{"status":"error","statusCode":400,"message":"CERTIFICATE_IMPORT_PDF_TOO_MANY_PAGES"}
```

- `process-ocr` devuelve el lote tras **encolar**, no el resultado de Vision. Redis ausente falla al encolar (`CERTIFICATE_IMPORT_OCR_UNAVAILABLE`); en el worker ADC/auth falla con el mismo código, cuota con `CERTIFICATE_IMPORT_OCR_QUOTA`, fallo/deadline/resultados incompletos con `CERTIFICATE_IMPORT_OCR_FAILED`. Estos fallos posteriores **no son** respuesta HTTP retroactiva ni un nuevo campo público de estado de job. No escribe `OCR_PROCESSED` salvo lectura completa exitosa. El SDK usa ADC, gRPC/Buffer, deadline 25 s y sin retries internos; BullMQ conserva dos intentos/concurrencia 1.
- PDF antiguo confirmado se valida nuevamente antes de Vision; se exige exactamente una respuesta sin error por cada página `1..pageCount`. OCR solo propone; agregar/corregir filas manualmente y aprobación autorizada continúan separados.
- Implementación revisada e integrada al workspace principal; configuración remota en Render, despliegue y smoke OCR real siguen pendientes. [Runbook ADC/operación](../guides/google-vision-certificate-ocr.md).

### certificate-import-institutional-requests

Aprobar no crea `enrollments` ni reactiva la clase. En HTTP, Campo Local, admin genérico y Unión reciben `GUARD_PERMISSION_DENIED`. Si el guard no aplica, el servicio responde `CERTIFICATE_IMPORT_INSTITUTIONAL_FORBIDDEN`. En la bandeja común, Unión pasa el alias de `director-lf` y el servicio responde `CERTIFICATE_IMPORT_REVIEWER_SCOPE_REQUIRED`.

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/certificate-import-institutional-requests` | JWT | Dueño | Enviar solicitud de Guía Mayor Avanzado o Instructor | InstitutionalCertificateRequestsService.submit() | `src/certificate-bulk-imports/institutional-certificate-requests.controller.ts` |
| GET | `/api/v1/certificate-import-institutional-requests` | JWT | Dueño | Consultar sus solicitudes | InstitutionalCertificateRequestsService.listMine() | `src/certificate-bulk-imports/institutional-certificate-requests.controller.ts` |
| GET | `/api/v1/certificate-import-institutional-requests/:requestId` | JWT | Dueño | Detalle, motivo y bloqueo de periodo | InstitutionalCertificateRequestsService.getMine() | `src/certificate-bulk-imports/institutional-certificate-requests.controller.ts` |

### admin-certificate-import-institutional-requests

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/certificate-import-institutional-requests` | JWT | Solo super-admin | Bandeja institucional. Query: `page`, `limit`, `status`, `class_id`, `q` | InstitutionalCertificateRequestsService.listForReview() | `src/certificate-bulk-imports/admin-institutional-certificate-requests.controller.ts` |
| GET | `/api/v1/admin/certificate-import-institutional-requests/:requestId` | JWT | Solo super-admin | Detalle institucional | InstitutionalCertificateRequestsService.getForReview() | `src/certificate-bulk-imports/admin-institutional-certificate-requests.controller.ts` |
| POST | `/api/v1/admin/certificate-import-institutional-requests/:requestId/approve` | JWT | Solo super-admin | Validar expediente, sin crear `enrollments` | InstitutionalCertificateRequestsService.approve() | `src/certificate-bulk-imports/admin-institutional-certificate-requests.controller.ts` |
| POST | `/api/v1/admin/certificate-import-institutional-requests/:requestId/reject` | JWT | Solo super-admin | Rechazar con motivo | InstitutionalCertificateRequestsService.reject() | `src/certificate-bulk-imports/admin-institutional-certificate-requests.controller.ts` |

### certifications

> Motor configurable versionado (migración `20260811180000_configurable_certifications_engine`). La inscripción y el progreso identifican la inscripción por **`userId` + `certificationId`**. Requisitos, evidencias, cierre y revisión final usan `enrollmentId` (`certification-enrollments/:enrollmentId`).

#### Catálogo (Optional JWT)

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/certifications/certifications` | Optional JWT | - | Listar certificaciones disponibles (paginado) | CertificationsService.findAll() | `src/certifications/certifications.controller.ts` |
| GET | `/api/v1/certifications/certifications/:id` | Optional JWT | - | Detalle de certificación con módulos y secciones | CertificationsService.findOne() | `src/certifications/certifications.controller.ts` |

#### Inscripción y progreso (participante / delegado)

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/certifications/users/:userId/certifications/enroll` | JWT | Permisos: user_certifications:manage; owner `userId` | Inscribir en la versión `PUBLISHED` vigente (evalúa elegibilidad configurable) | CertificationsService.enrollUser() | `src/certifications/certifications.controller.ts` |
| GET | `/api/v1/certifications/users/:userId/certifications` | JWT | Permisos: user_certifications:read; owner `userId` | Listar inscripciones del usuario con resumen de progreso | CertificationsService.getUserCertifications() | `src/certifications/certifications.controller.ts` |
| GET | `/api/v1/certifications/users/:userId/certifications/:certificationId/eligibility` | JWT | Permisos: user_certifications:read; owner `userId` | Evaluar elegibilidad explicable por regla (versión publicada) | CertificationsService.getEligibility() | `src/certifications/certifications.controller.ts` |
| GET | `/api/v1/certifications/users/:userId/certifications/:certificationId/progress` | JWT | Permisos: user_certifications:read; owner `userId` | Progreso detallado por módulos/secciones (inscripciones versionadas usan `status` de requisito) | CertificationsService.getCertificationProgress() | `src/certifications/certifications.controller.ts` |
| PATCH | `/api/v1/certifications/users/:userId/certifications/:certificationId/progress` | JWT | Permisos: user_certifications:manage; owner `userId` | **[LEGACY — deprecado 2026-08-11]** Toggle booleano de sección; inscripciones con `certification_version_id` reciben `410 CERT_LEGACY_ENDPOINT_DEPRECATED` | CertificationsService.updateProgress() | `src/certifications/certifications.controller.ts` |
| DELETE | `/api/v1/certifications/users/:userId/certifications/:certificationId` | JWT | Permisos: user_certifications:manage; owner `userId` | Abandonar inscripción (soft delete) | CertificationsService.deleteCertification() | `src/certifications/certifications.controller.ts` |

#### Requisitos y evidencias (participante)

Path base: `/api/v1/certifications/users/:userId/certification-enrollments/:enrollmentId/requirements/:requirementId`. La inscripción se identifica por `enrollmentId` (debe existir, estar activa y pertenecer al `userId` autenticado).

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/certifications/users/:userId/certification-enrollments/:enrollmentId/requirements/:requirementId` | JWT | user_certifications:read; owner `userId` | Estado del requisito, respuestas y componentes | CertificationRequirementsService.getRequirement() | `src/certifications/controllers/user-certification-requirements.controller.ts` |
| PATCH | `/api/v1/certifications/users/:userId/certification-enrollments/:enrollmentId/requirements/:requirementId/draft` | JWT | user_certifications:manage; owner `userId` | Guardar borrador (solo `DRAFT` o `CHANGES_REQUESTED`) | CertificationRequirementsService.saveDraft() | `src/certifications/controllers/user-certification-requirements.controller.ts` |
| POST | `/api/v1/certifications/users/:userId/certification-enrollments/:enrollmentId/requirements/:requirementId/submit` | JWT | user_certifications:manage; owner `userId` | Enviar requisito a revisión (`lock_version` obligatorio) | CertificationRequirementsService.submitRequirement() | `src/certifications/controllers/user-certification-requirements.controller.ts` |
| POST | `/api/v1/certifications/users/:userId/certification-enrollments/:enrollmentId/requirements/:requirementId/evidences/presign` | JWT | user_certifications:manage; owner `userId` | URL firmada de subida R2 (`component_id`, MIME, tamaño) | CertificationEvidenceService.presign() | `src/certifications/controllers/user-certification-requirements.controller.ts` |
| POST | `/api/v1/certifications/users/:userId/certification-enrollments/:enrollmentId/requirements/:requirementId/evidences/confirm` | JWT | user_certifications:manage; owner `userId` | Confirmar objeto subido (valida HEAD en R2) | CertificationEvidenceService.confirm() | `src/certifications/controllers/user-certification-requirements.controller.ts` |
| DELETE | `/api/v1/certifications/users/:userId/certification-enrollments/:enrollmentId/evidences/:evidenceId` | JWT | user_certifications:manage; owner `userId` | Eliminar evidencia mientras el requisito sea editable | CertificationEvidenceService.delete() | `src/certifications/controllers/user-certification-requirements.controller.ts` |

#### Cierre institucional (participante)

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/certifications/users/:userId/certification-enrollments/:enrollmentId/closeout-evidence/presign` | JWT | user_certifications:manage; owner `userId` | URL firmada para comprobante de junta | CertificationCloseoutService.presignCloseoutEvidence() | `src/certifications/controllers/certification-closeout.controller.ts` |
| POST | `/api/v1/certifications/users/:userId/certification-enrollments/:enrollmentId/closeout-evidence/confirm` | JWT | user_certifications:manage; owner `userId` | Confirmar comprobante de junta subido a R2 | CertificationCloseoutService.confirmCloseoutEvidence() | `src/certifications/controllers/certification-closeout.controller.ts` |
| POST | `/api/v1/certifications/users/:userId/certification-enrollments/:enrollmentId/submit-final` | JWT | user_certifications:manage; owner `userId` | Enviar inscripción a revisión final (requisitos obligatorios `APPROVED` + comprobante `CONFIRMED`) | CertificationCloseoutService.submitFinal() | `src/certifications/controllers/certification-closeout.controller.ts` |

#### Revisión de requisitos (institucional)

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/certifications/reviews/requirements` | JWT | Permisos: certifications:review; scope global | Bandeja de requisitos (filtro opcional `?status=`) | CertificationReviewService.getTray() | `src/certifications/controllers/certification-review.controller.ts` |
| GET | `/api/v1/certifications/reviews/requirements/:progressId` | JWT | Permisos: certifications:review; scope global | Detalle de requisito con respuestas, evidencias e historial | CertificationReviewService.getDetail() | `src/certifications/controllers/certification-review.controller.ts` |
| GET | `/api/v1/certifications/reviews/requirements/:progressId/evidences/:evidenceId/download` | JWT | Permisos: certifications:review; scope global | URL firmada efímera (TTL 15 min) de evidencia activa `CONFIRMED` del requisito; no acepta object key del cliente | CertificationReviewService.getEvidenceDownloadUrl() | `src/certifications/controllers/certification-review.controller.ts` |
| POST | `/api/v1/certifications/reviews/requirements/:progressId/approve` | JWT | Permisos: certifications:review; scope global | Aprobar requisito `SUBMITTED` (`lock_version` obligatorio) | CertificationReviewService.approve() | `src/certifications/controllers/certification-review.controller.ts` |
| POST | `/api/v1/certifications/reviews/requirements/:progressId/request-changes` | JWT | Permisos: certifications:review; scope global | Devolver requisito con comentario obligatorio | CertificationReviewService.requestChanges() | `src/certifications/controllers/certification-review.controller.ts` |

#### Revisión final y certificación (institucional)

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/certifications/reviews/final` | JWT | Permisos: certifications:review; scope global | Bandeja de cierres (`SUBMITTED_FOR_FINAL_REVIEW` y `APPROVED`) con metadata del comprobante | CertificationCloseoutService.getFinalTray() | `src/certifications/controllers/certification-closeout.controller.ts` |
| GET | `/api/v1/certifications/reviews/final/:enrollmentId/closeout-evidence/download` | JWT | Permisos: certifications:review; scope global | URL firmada efímera (TTL 15 min) del comprobante de junta activo `CONFIRMED` | CertificationCloseoutService.getCloseoutEvidenceDownloadUrl() | `src/certifications/controllers/certification-closeout.controller.ts` |
| POST | `/api/v1/certifications/reviews/final/:enrollmentId/approve-closeout-evidence` | JWT | Permisos: certifications:review; scope global | Aprobar comprobante de junta → inscripción `APPROVED` | CertificationCloseoutService.approveCloseoutEvidence() | `src/certifications/controllers/certification-closeout.controller.ts` |
| POST | `/api/v1/certifications/reviews/final/:enrollmentId/request-changes` | JWT | Permisos: certifications:review; scope global | Devolver cierre con comentario obligatorio | CertificationCloseoutService.requestChanges() | `src/certifications/controllers/certification-closeout.controller.ts` |
| POST | `/api/v1/certifications/reviews/final/:enrollmentId/certify` | JWT | Permisos: certifications:certify; scope global | Certificar inscripción válida (idempotente) | CertificationCloseoutService.certify() | `src/certifications/controllers/certification-closeout.controller.ts` |

#### Códigos de error `CERT_*`

| Código | HTTP típico | Cuándo |
| --- | --- | --- |
| `CERT_NOT_FOUND` | 404 | Certificación inexistente o inactiva |
| `CERT_ALREADY_ENROLLED` | 409 | Inscripción duplicada activa |
| `CERT_ELIGIBILITY_REQUIRED` | 403 | Usuario no cumple reglas de elegibilidad al inscribir |
| `CERT_ENROLLMENT_NOT_FOUND` | 404 | Sin inscripción activa para `userId` + `certificationId` |
| `CERT_SECTION_INVALID` | 400 | Sección/componente fuera de la versión inscrita |
| `CERT_VERSION_NOT_PUBLISHED` | 400 | No hay versión publicada vigente |
| `CERT_VERSION_IMMUTABLE` | 409 | Mutación sobre versión `PUBLISHED`/`RETIRED` |
| `CERT_REQUIREMENT_LOCKED` | 409 | Requisito en `SUBMITTED`/`APPROVED`; evidencia bloqueada |
| `CERT_REQUIREMENT_INCOMPLETE` | 400 | Faltan entregables obligatorios o objeto R2 ausente |
| `CERT_INVALID_TRANSITION` | 400 | Transición de estado inválida (inscripción o requisito) |
| `CERT_EVIDENCE_INVALID_TYPE` | 400 | MIME no permitido (`jpeg`, `png`, `webp`, `pdf`) |
| `CERT_EVIDENCE_TOO_LARGE` | 400 | Archivo > 10 MiB o divergencia vs. declarado |
| `CERT_REVIEW_SCOPE_FORBIDDEN` | 403 | Revisor fuera de campo local del participante, sin acceso global, o es el propio participante |
| `CERT_CLOSEOUT_INCOMPLETE` | 400 | Faltan requisitos aprobados o comprobante de junta listo |
| `CERT_CONCURRENT_UPDATE` | 409 | `lock_version` obsoleto en envío/revisión |
| `CERT_LEGACY_ENDPOINT_DEPRECATED` | 410 | `PATCH .../progress` sobre inscripción versionada |

### Admin - Certifications

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/certifications` | JWT | Permisos: certifications:configure; scope global | Listar certificaciones con resumen de versiones (id, número, status, título, fechas) | CertificationDefinitionsService.listCertificationsWithVersions() | `src/certifications/controllers/admin-certifications.controller.ts` |
| GET | `/api/v1/admin/certifications/:certificationId/versions/:versionId` | JWT | Permisos: certifications:configure | Árbol completo de una versión: metadatos, reglas de elegibilidad, módulos → secciones → componentes (con `configuration`), todo ordenado por `sort_order`; legible en cualquier status (`DRAFT`/`PUBLISHED`/`RETIRED`) | CertificationDefinitionsService.getVersionDetail() | `src/certifications/controllers/admin-certifications.controller.ts` |
| POST | `/api/v1/admin/certifications` | JWT | Permisos: certifications:configure; scope global | Crear certificación con versión inicial `DRAFT` | CertificationDefinitionsService.createCertification() | `src/certifications/controllers/admin-certifications.controller.ts` |
| POST | `/api/v1/admin/certifications/:certificationId/versions` | JWT | Permisos: certifications:configure | Crear versión `DRAFT` | CertificationDefinitionsService.createDraftVersion() | `src/certifications/controllers/admin-certifications.controller.ts` |
| POST | `/api/v1/admin/certifications/:certificationId/versions/:versionId/clone` | JWT | Permisos: certifications:configure | Clonar versión `PUBLISHED`/`RETIRED` a nuevo `DRAFT` | CertificationDefinitionsService.cloneVersion() | `src/certifications/controllers/admin-certifications.controller.ts` |
| PATCH | `/api/v1/admin/certifications/:certificationId/versions/:versionId` | JWT | Permisos: certifications:configure | Actualizar metadatos de versión `DRAFT` | CertificationDefinitionsService.updateVersionMetadata() | `src/certifications/controllers/admin-certifications.controller.ts` |
| PATCH | `/api/v1/admin/certifications/:certificationId/versions/:versionId/eligibility-rules` | JWT | Permisos: certifications:configure | Reemplazar reglas de elegibilidad del borrador | CertificationDefinitionsService.replaceEligibilityRules() | `src/certifications/controllers/admin-certifications.controller.ts` |
| PATCH | `/api/v1/admin/certifications/:certificationId/versions/:versionId/tree` | JWT | Permisos: certifications:configure | Reemplazar árbol módulos/secciones/componentes del borrador | CertificationDefinitionsService.replaceModulesTree() | `src/certifications/controllers/admin-certifications.controller.ts` |
| POST | `/api/v1/admin/certifications/:certificationId/versions/:versionId/publish` | JWT | Permisos: certifications:publish | Publicar borrador (retira versión `PUBLISHED` anterior) | CertificationDefinitionsService.publishVersion() | `src/certifications/controllers/admin-certifications.controller.ts` |
| DELETE | `/api/v1/admin/certifications/:certificationId/versions/:versionId/publish` | JWT | Permisos: certifications:publish | Retirar versión `PUBLISHED` | CertificationDefinitionsService.retireVersion() | `src/certifications/controllers/admin-certifications.controller.ts` |

### class-counselor-assignments

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId/class-counselor-assignments` | JWT | Permisos: club_roles:read | Listar asignaciones pedagógicas de clases por sección | ClassCounselorAssignmentsService.listAssignments() | `src/classes/class-counselor-assignments.controller.ts` |
| POST | `/api/v1/clubs/:clubId/sections/:sectionId/class-counselor-assignments` | JWT | Permisos: club_roles:assign | Asignar un consejero o secretario a una clase progresiva | ClassCounselorAssignmentsService.createAssignment() | `src/classes/class-counselor-assignments.controller.ts` |
| PATCH | `/api/v1/class-counselor-assignments/:assignmentId` | JWT | Permisos: club_roles:assign | Actualizar una asignación pedagógica de clase | ClassCounselorAssignmentsService.updateAssignment() | `src/classes/class-counselor-assignments.controller.ts` |
| DELETE | `/api/v1/class-counselor-assignments/:assignmentId` | JWT | Permisos: club_roles:revoke | Revocar una asignación pedagógica de clase | ClassCounselorAssignmentsService.removeAssignment() | `src/classes/class-counselor-assignments.controller.ts` |

### class-progress-scope

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId/classes/progress-scope` | JWT | Permisos: classes:read | Listar clases visibles para seguimiento de progreso | ClassProgressScopeService.getProgressScope() | `src/classes/class-progress-scope.controller.ts` |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId/classes/:classId/members-progress` | JWT | Permisos: classes:read | Listar avance de miembros por clase en una sección. Response `members[]` incluye `cross_type_enrollment: boolean`. Devuelve miembros regulares de la sección **y** GMs con `cross_type_enrollment=true` de cualquier sección del mismo club. | ClassProgressScopeService.getClassMembersProgress() | `src/classes/class-progress-scope.controller.ts` |

### class-thresholds

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/local-fields/:localFieldId/class-thresholds/:ecclesiasticalYearId` | JWT | `director-lf` y `assistant-lf` solo en su Campo; `super-admin` en cualquier Campo. Admin, unión, división y un Campo ajeno: 403 `GUARD_PERMISSION_DENIED`. El alias de `GlobalRolesGuard` deja entrar a unión y división; el servicio igual responde 403. | Leer el porcentaje efectivo. Sin fila: `minimum_percent` 80 y `configured` false. La respuesta incluye `can_edit`. | FieldClassThresholdConfigService.get() | `src/classes/field-class-threshold.controller.ts` |
| PATCH | `/api/v1/local-fields/:localFieldId/class-thresholds/:ecclesiasticalYearId` | JWT | Mismos roles que el GET. Escritura: director y asistente del Campo hasta el 30 de junio 23:59 en `local_fields.timezone`, solo si ese instante cae dentro del año pedido. Después, solo `super-admin`, y tampoco fuera de ese año. Fuera de plazo, o con el año `active` en false aunque el día caiga dentro de sus fechas: 403 `CLASS_THRESHOLD_EDIT_CLOSED` para todos los roles, incluido `super-admin`. | Guardar `minimum_percent`. Si el cuerpo no es un entero 0–100 (`101`, `-1`, `90.5`, `"90"`, `null`), el `I18nValidationPipe` responde HTTP 400 con `statusCode`, `message` (arreglo) y `error: "Bad Request"`, sin `code`. `CLASS_THRESHOLD_PERCENT_INVALID` lo lanza el servicio en llamadas internas; no es el contrato de esta ruta. Campo o año ausente: 404 `CLASS_THRESHOLD_FIELD_NOT_FOUND` o `CLASS_THRESHOLD_YEAR_NOT_FOUND`. Zona inválida: 503 `LOCAL_FIELD_TIMEZONE_UNAVAILABLE`. | FieldClassThresholdConfigService.update() | `src/classes/field-class-threshold.controller.ts` |

### investiture-windows

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/local-fields/:localFieldId/investiture-windows/:ecclesiasticalYearId` | JWT | Consultan, dentro de su alcance: `director-lf`, `assistant-lf`, `admin`, `assistant-admin`, `director-union`, `assistant-union`, `director-dia`, `assistant-dia` y `super-admin`. Fuera de alcance: 403 `GUARD_PERMISSION_DENIED`. El alias de `GlobalRolesGuard` deja entrar a unión y división; el servicio igual recorta el Campo. | Sin fila y con intersección: 1 de octubre a 20 de diciembre, recortado al año, `configured` false, `operational` true, sin insertar. Sin intersección y sin configuración válida: `start_date` null, `end_date` null, `configured` false, `operational` false. No se devuelve el año completo ni un rango invertido. `operational` indica que existe un rango, no que el día local caiga dentro. Incluye `can_edit`. Una fila fuera del año, con inicio posterior al fin o con un día imposible no abre la ventana y la lectura no la reescribe. Editar la ventana no autoriza investiduras ni habilita el porcentaje de clase. | FieldInvestitureWindowConfigService.get() | `src/classes/field-investiture-window.controller.ts` |
| PATCH | `/api/v1/local-fields/:localFieldId/investiture-windows/:ecclesiasticalYearId` | JWT | Escriben, con el año activo y el día local dentro de ese año: `director-lf` y `assistant-lf` solo en su Campo; `admin` y `assistant-admin` en su alcance; `super-admin` en cualquier Campo. Unión y división no escriben: 403 `GUARD_PERMISSION_DENIED`. Año inactivo o día local fuera del año: 403 `INVESTITURE_WINDOW_EDIT_CLOSED`. | Cuerpo `start_date` y `end_date` (`YYYY-MM-DD`), inclusivos, dentro del año y con inicio no posterior al fin. Un cuerpo que no tiene esa forma lo rechaza el `I18nValidationPipe` con HTTP 400 sin `code`. Día imposible: 400 `INVESTITURE_WINDOW_DATE_INVALID`. Fuera del año: 400 `INVESTITURE_WINDOW_OUTSIDE_YEAR`. Inicio posterior al fin: 400 `INVESTITURE_WINDOW_START_AFTER_END`. Campo o año ausente: 404 `INVESTITURE_WINDOW_FIELD_NOT_FOUND` o `INVESTITURE_WINDOW_YEAR_NOT_FOUND`. | FieldInvestitureWindowConfigService.update() | `src/classes/field-investiture-window.controller.ts` |

### investiture-pastors

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/investiture-pastor-quota` | JWT | Leen: `super-admin`, `director-lf`, `assistant-lf`, `director-union` y `assistant-union`. Admin, división y director de club: 403 `GUARD_PERMISSION_DENIED`. El alias de `GlobalRolesGuard` deja entrar a división; el servicio igual responde 403. | Sin fila: `slots` 2, `configured` false, sin insertar. `can_edit` es true solo para `super-admin`. | DistrictInvestiturePastorService.getQuota() | `src/classes/district-investiture-pastors.controller.ts` |
| PATCH | `/api/v1/investiture-pastor-quota` | JWT | Solo `super-admin`. Los demás roles, incluidos Campo y unión: 403 `GUARD_PERMISSION_DENIED`. | Cuerpo `{ "slots": 1 }`, entero mayor o igual a 0. El mismo tope vale para todos los distritos. El cambio y las altas o reactivaciones comparten un candado de transacción, también si todavía no hay fila. Si algún distrito ya tiene más pastores activos, 409 `INVESTITURE_PASTOR_QUOTA_BELOW_ASSIGNMENTS` y no se reescribe ni se borran asignaciones. Un cuerpo que no es ese entero lo rechaza el `I18nValidationPipe` con HTTP 400 sin `code`. `INVESTITURE_PASTOR_QUOTA_INVALID` queda para el servicio. | DistrictInvestiturePastorService.updateQuota() | `src/classes/district-investiture-pastors.controller.ts` |
| GET | `/api/v1/districts/:districtId/investiture-pastors` | JWT | Leen dentro de su alcance: `director-lf`, `assistant-lf`, `director-union`, `assistant-union` y `super-admin`. Admin, división y un distrito fuera de alcance: 403 `GUARD_PERMISSION_DENIED`, sin listar pastores. | Pastores activos del distrito. Cada fila trae `user_name` (nombre y apellidos armados igual que en las solicitudes; «Sin nombre» si no hay datos) y `email`. Si el usuario sigue con el rol global `pastor`, `can_authorize` es true. Si ya no lo tiene, la fila sigue activa, ocupa cupo, `can_authorize` es false y `role_missing` es true. Si su cuenta está eliminada, la fila sigue activa y ocupando cupo, `can_authorize` es false y `account_inactive` es true. No se desactiva sola. `can_assign` es false para `super-admin` y cuando el cupo está lleno. | DistrictInvestiturePastorService.list() | `src/classes/district-investiture-pastors.controller.ts` |
| POST | `/api/v1/districts/:districtId/investiture-pastors` | JWT | Asignan dentro de su alcance: `director-lf`, `assistant-lf`, `director-union` y `assistant-union`. `super-admin`, admin y división no asignan por esos roles: 403 `GUARD_PERMISSION_DENIED`. Un cargo de unión sí alcanza los distritos de su unión; un director de Campo solo el suyo. | Cuerpo `{ "user_id": "<uuid>" }`. El usuario debe tener el rol global `pastor`. Alta y reactivación toman el mismo candado que el cambio de cupo antes de leer el tope, también sin fila. Cupo lleno: 409 `INVESTITURE_PASTOR_QUOTA_FULL`. Ya asignado: 409 `INVESTITURE_PASTOR_ALREADY_ASSIGNED`. Sin ese rol: 400 `INVESTITURE_PASTOR_ROLE_REQUIRED`. El pastor debe pertenecer al Campo del distrito (`users.local_field_id` igual al `local_field_id` del distrito); de otro Campo, aunque sea de la misma unión, o sin Campo: 400 `INVESTITURE_PASTOR_FIELD_MISMATCH`, también al reactivar una asignación inactiva y para un cargo de unión. Se evalúa después del rol. Usuario ausente: 404 `INVESTITURE_PASTOR_USER_NOT_FOUND`. Distrito ausente: 404 `INVESTITURE_PASTOR_DISTRICT_NOT_FOUND`. Dos altas del último cupo no pueden quedar ambas activas. La respuesta incluye `user_name` y `email`. Asignar no autoriza una investidura ni llama al pipeline anterior. | DistrictInvestiturePastorService.assign() | `src/classes/district-investiture-pastors.controller.ts` |
| DELETE | `/api/v1/districts/:districtId/investiture-pastors/:userId` | JWT | Los mismos roles que el POST, dentro del mismo alcance. | Desactiva la asignación y libera el cupo. Responde `can_authorize: false`, con `user_name` y `email`. Si no estaba activa: 404 `INVESTITURE_PASTOR_NOT_ASSIGNED`. | DistrictInvestiturePastorService.remove() | `src/classes/district-investiture-pastors.controller.ts` |
| GET | `/api/v1/clubs/:clubId/investiture-authorizers` | JWT | La misma lectura que el listado del distrito, aplicada al distrito resuelto. | El distrito sale de `clubs.church_id` → `churches.districlub_type_id`. No usa `clubs.districlub_type_id` ni un distrito del usuario. `resolved_from` es `church`. Solo entran pastores activos que todavía tienen el rol global `pastor`. Cada uno trae `user_name` y `email`. Quien lo perdió no aparece, aunque su asignación siga ocupando cupo. Club o iglesia ausente: 404 `INVESTITURE_PASTOR_CLUB_NOT_FOUND` o `INVESTITURE_PASTOR_CHURCH_NOT_FOUND`. | DistrictInvestiturePastorService.authorizersForClub() | `src/classes/district-investiture-pastors.controller.ts` |
| GET | `/api/v1/investiture-pastor-candidates?q=&districtId=` | JWT | Quien puede asignar: `director-lf`, `assistant-lf`, `director-union` y `assistant-union`. `super-admin`, admin, división y otros roles: 403 `GUARD_PERMISSION_DENIED`. Unión sin alcance: 403 `ADMIN_USER_SCOPE_MISSING`. | Busca a quién asignar como pastor. `q` es obligatorio, se recorta y exige 3 caracteres o más, y cada palabra (separada por espacios) al menos 2; si no, 400 del `I18nValidationPipe` (por ejemplo `a b`). Compara sin distinguir mayúsculas y por contenido en nombre, apellidos y correo; con varias palabras, cada una debe aparecer en alguno de esos campos. `%`, `_` y `\` se tratan como texto. Solo devuelve cuentas activas con el rol global `pastor` activo (la misma regla de `can_authorize`), hasta 20, por nombre. Cada elemento es `{ "user_id", "user_name", "email" }`. Limita por territorio de quien busca: `director-lf` y `assistant-lf` solo ven pastores cuyo `users.local_field_id` es su Campo; `director-union` y `assistant-union`, los de los Campos de su unión. Un pastor sin `local_field_id` no se devuelve (hay que fijarle el Campo en su perfil). `districtId` es opcional (entero positivo; otro valor: 400). Si viene, se autoriza el distrito con el mismo alcance que al asignar (fuera de alcance: 403 `GUARD_PERMISSION_DENIED`; ausente: 404 `INVESTITURE_PASTOR_DISTRICT_NOT_FOUND`, también con una `q` demasiado corta) y solo se devuelven pastores del Campo de ese distrito, que es la única regla con la que el alta los acepta; así un cargo de unión no ve pastores de otros Campos. Sin `districtId` se mantiene el límite por territorio descrito arriba. | DistrictInvestiturePastorService.searchCandidates() | `src/classes/district-investiture-pastors.controller.ts` |

### investiture-requests

Módulo hermano de `InvestitureModule`. No llama a `submit`, `club-approve`, `coordinator-approve`, `field-approve` ni `invest`, y no envía correo. El controlador usa `JwtAuthGuard` y `@SkipPermissions()`. No usa `GlobalRolesGuard`. El cargo se resuelve en el servicio: director, secretario o secretario-tesorero de esa sección y año, con asignación operativa y `status` active. El subdirector recibe 403 `INVESTITURE_REQUEST_FORBIDDEN` al presentar, leer, agregar, quitar y cambiar fecha. `super-admin` puede leer una solicitud por id y cambiar la fecha. No presenta, no agrega, no quita, no autoriza y el listado de autorizador le responde 403. Un cuerpo que no tiene la forma descrita lo rechaza el `I18nValidationPipe` con HTTP 400 sin `code`.

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/club-sections/:sectionId/investiture-requests` | JWT | Director, secretario o secretario-tesorero de la sección y el año. Subdirector y `super-admin`: 403 `INVESTITURE_REQUEST_FORBIDDEN`. | Cuerpo `{ "ecclesiastical_year_id", "investiture_date", "enrollment_ids" }`. Una solicitud por sección y año mientras haya pendientes. Varias personas comparten la fecha. El día local tiene que caer en la ventana y en el año. Si la llamada no trae un instante explícito, ese día se lee del reloj otra vez después de los candados y antes de escribir. Sin intersección de ventana: 409 `INVESTITURE_REQUEST_WINDOW_CLOSED`. Fecha fuera de la ventana: 400 `INVESTITURE_REQUEST_DATE_OUTSIDE_WINDOW`. Fuera del año: 400 `INVESTITURE_REQUEST_DATE_OUTSIDE_YEAR`. Día imposible: 400 `INVESTITURE_REQUEST_DATE_INVALID`. Año cerrado: 409 `INVESTITURE_REQUEST_YEAR_CLOSED`. Sin progreso: 409 `INVESTITURE_REQUEST_NOT_ELIGIBLE`. `GM-02` y `GM-03`: 400 `INVESTITURE_REQUEST_CLASS_NOT_ELIGIBLE`, sin insertar la persona. Sin duración mínima: 400 `INVESTITURE_DURATION_MIN_NOT_MET`. Certificado histórico: 409 `INVESTITURE_REQUEST_NOT_OPERATIONAL`. Fuera de la sección: 409 `INVESTITURE_REQUEST_OUTSIDE_SECTION`. Aventureros o Conquistadores con otra solicitud activa: 409 `INVESTITURE_REQUEST_ACTIVE_EXISTS`. Guía Mayor, incluido el ya investido que cursa otra clase por `cross_type_enrollment`, puede tener otra activa si la clase es distinta. Ya `INVESTIDO` en esa clase, en este enrollment o en otro de la misma persona y clase y de cualquier `record_kind`: 409 `INVESTITURE_REQUEST_ALREADY_INVESTED` y los pendientes anteriores de esa persona y clase pasan a `REMOVED` con `resolution_code` `ALREADY_INVESTED`. `enrollUser` no impide ese segundo enrollment salvo el caso estrecho de Guía Mayor investida y la clase destino también investida. `validateDisplayOrderProgression` no mira `investiture_status`. Solo con `locked_for_validation` en true (fase 8, decisión B5; el estado de la cadena ya no cuenta): 409 `INVESTITURE_REQUEST_LEGACY_PIPELINE_ACTIVE`. Un expediente desbloqueado, como uno que soltó el desbloqueo, sí se puede presentar. No se inserta la persona. Selección vacía: 400 `INVESTITURE_REQUEST_EMPTY`. Las altas de una persona toman `pg_advisory_xact_lock` por usuario antes de releer. | InvestitureAuthorizationRequestService.present() | `src/investiture-requests/investiture-authorization-requests.controller.ts` |
| GET | `/api/v1/club-sections/:sectionId/investiture-requests?ecclesiastical_year_id=` | JWT | Los mismos cargos de sección. Subdirector: 403. `super-admin` sin ese cargo: 403. | Devuelve la solicitud que todavía tiene alguien `PENDING`. Si no queda ninguno, devuelve la de `CLOSED_YEAR` cuyo `system_reason` es «Investidura acreditada posteriormente mediante certificado validado». Si tampoco, devuelve la informativa con `resolution_code` `HISTORICAL_CERTIFICATE_APPLIED`: la de menor `request_id` y, dentro de ella, la persona de menor `person_id`. Si no hay ninguna de las dos, `data: null` sin insertar. Cada persona trae `can_authorize: true` solo si sigue `PENDING`, y `resolution_code`. | InvestitureAuthorizationRequestService.list() | `src/investiture-requests/investiture-authorization-requests.controller.ts` |
| GET | `/api/v1/club-sections/:sectionId/investiture-requests/presentation-context?ecclesiastical_year_id=` | JWT | Director, secretario o secretario-tesorero de la sección y el año (los mismos de `present`). Subdirector y `super-admin` sin ese cargo: 403 `INVESTITURE_REQUEST_FORBIDDEN`. Sin `ecclesiastical_year_id`: 400. | Solo informativa: no escribe, no abre transacción ni toma candados; `present` vuelve a comprobar todo bajo candados. Devuelve `{ club_section_id, ecclesiastical_year_id, window: { start_date, end_date, open_today, time_zone_invalid }, year_open, open_request_id, candidates[] }`. `open_today` usa el día local del Campo; con la ventana cerrada los candidatos igual se listan. Si la zona horaria guardada del Campo es inválida, `open_today` es `false` y `time_zone_invalid` es `true` (la lectura sigue funcionando; `present` responde `INVESTITURE_REQUEST_TIME_ZONE_INVALID` hasta corregirla). `open_request_id` es la solicitud con `PENDING` de esa sección y año, o null. Cada candidato (`enrollment_id`, `user_id`, `user_name`, `class_id`, `class_name`, `overall_progress`, `eligible`, `blocked_code`, `pending_person_id`) sale de enrollments `OPERATIONAL` activos y no `INVESTIDO`, de la clase del tipo de la sección (las clases institucionales GM-02 y GM-03 no se listan: nunca tienen solicitudes), de miembros activos de la sección en ese año, más las clases cruzadas que `present` acepta (Guía Mayor investido con cargo en otra sección del mismo club). `blocked_code` es el primer código que `present` lanzaría (`INVESTITURE_REQUEST_NOT_OPERATIONAL`, `_OUTSIDE_SECTION`, `_ALREADY_INVESTED`, `_LEGACY_PIPELINE_ACTIVE`, `_ACTIVE_EXISTS`, `_NOT_ELIGIBLE`, `INVESTITURE_DURATION_MIN_NOT_MET`, `INVESTITURE_DURATION_EXPIRED`, `_CLASS_NOT_ELIGIBLE`); `pending_person_id` se llena si la persona ya está `PENDING` en la solicitud abierta. Orden: elegibles primero y luego por nombre. | InvestitureAuthorizationRequestService.presentationContext() | `src/investiture-requests/investiture-authorization-requests.controller.ts` |
| POST | `/api/v1/investiture-requests/:requestId/people` | JWT | Los mismos cargos de sección que el POST inicial. | Agrega personas con su propia fecha. No reescribe la fecha de quienes ya estaban. `GM-02` y `GM-03`: 400 `INVESTITURE_REQUEST_CLASS_NOT_ELIGIBLE`, sin insertar la persona. Mismas reglas de ventana, año, progreso, duración y solicitud activa. Sin instante explícito, el día se vuelve a leer del reloj después de los candados. Si otra cabecera de la sección y el año ya tiene pendientes, no reactiva esta: 409 `INVESTITURE_REQUEST_STALE`. Hay que volver a cargar el listado. No mueve personas. Otro `INVESTIDO` de la misma persona y clase, cualquier `record_kind`: 409 `INVESTITURE_REQUEST_ALREADY_INVESTED`. Solo `locked_for_validation` en true: 409 `INVESTITURE_REQUEST_LEGACY_PIPELINE_ACTIVE`. | InvestitureAuthorizationRequestService.addPeople() | `src/investiture-requests/investiture-authorization-requests.controller.ts` |
| DELETE | `/api/v1/investiture-requests/:requestId/people/:personId` | JWT | Los mismos cargos de sección. | Pasa el pendiente a `REMOVED`, `resolution_code` `REMOVED`. Libera solo el bloqueo de progreso de esa solicitud. No cambia `investiture_status` ni `locked_for_validation`. Si ya no está pendiente: 409 `INVESTITURE_REQUEST_NOT_PENDING`. | InvestitureAuthorizationRequestService.remove() | `src/investiture-requests/investiture-authorization-requests.controller.ts` |
| PATCH | `/api/v1/investiture-requests/:requestId/dates` | JWT | Director, secretario o secretario-tesorero de la sección, o `super-admin`. Subdirector: 403. | Cuerpo `{ "investiture_date", "person_ids" }`. Una fecha válida para todos los pendientes seleccionados. No toca a los no seleccionados ni a quien no está `PENDING`. Si alguno de la selección ya no está pendiente, no cambia a ninguno: 409 `INVESTITURE_REQUEST_NOT_PENDING`. Se puede corregir con el día local fuera de la ventana, si el año sigue abierto y la fecha nueva cae en la ventana y en el año. Con la ventana cerrada por falta de intersección, ninguna fecha entra. Año cerrado: 409 `INVESTITURE_REQUEST_YEAR_CLOSED`. Cada persona cambiada guarda `date_changed_by_id` y `date_changed_at` con el actor y el reloj de la aplicación. Quitar también usa ese reloj. La respuesta lleva la forma de la directiva (con el motivo humano de otras personas rechazadas) cuando corrige la directiva de la sección, y la forma del autorizador (`rejection_reason` en null) cuando corrige `super-admin`. | InvestitureAuthorizationRequestService.changeDates() | `src/investiture-requests/investiture-authorization-requests.controller.ts` |
| GET | `/api/v1/investiture-requests?ecclesiastical_year_id=` | JWT | Pastor asignado al distrito de la iglesia del club, o `director-lf` / `assistant-lf` de ese Campo. `admin`, `super-admin`, unión, división y el directivo de sección no listan por esos cargos: 403 `INVESTITURE_REQUEST_FORBIDDEN`. Otro Campo u otro distrito: 403. | Lista las solicitudes de ese año que todavía tienen alguien `PENDING`, una persona `CLOSED_YEAR` con `system_reason` «Investidura acreditada posteriormente mediante certificado validado», o una persona `REMOVED` con `resolution_code` `HISTORICAL_CERTIFICATE_APPLIED`, en el territorio del actor. Cada solicitud trae además `club_id`, `club_name`, `section_name`, `district_name`, `pending_count` (personas `PENDING`), `earliest_investiture_date` (menor fecha entre los `PENDING`, o null) y `created_at`; se leen por lote, sin una consulta por solicitud. Cada persona trae `user_name`, `class_name`, `section_name` y `resolved_by_name`. El autorizador ve `system_reason` y `rejection_reason` en null. No envía correo por ese retiro. | InvestitureAuthorizationRequestService.listForAuthorizer() | `src/investiture-requests/investiture-authorization-requests.controller.ts` |
| GET | `/api/v1/investiture-requests/:requestId` | JWT | El autorizador del territorio, o `super-admin`. | Devuelve la solicitud con todas sus personas, incluidos investidos, rechazados y retirados, y los mismos campos de cabecera del listado (`club_id`, `club_name`, `section_name`, `district_name`, `pending_count`, `earliest_investiture_date`, `created_at`; también presentes en las lecturas de la directiva). Trae `user_name`, `class_name`, `section_name`, `authorization_comment`, `system_reason`, `resolution_code`, `resolved_by_id`, `resolved_by_name`, `date_changed_by_id` y `date_changed_at`. En un rechazo del sistema, `resolved_by_name` es «Sistema». El autorizador recibe `rejection_reason` en null. `super-admin` lee con la forma del autorizador (`rejection_reason` en null, sin el motivo humano) y no puede presentar ni resolver. Un certificado de un año anterior deja `REMOVED`, `resolution_code` `HISTORICAL_CERTIFICATE_APPLIED` y `system_reason` «Investidura aplicada por certificado de un año anterior». Un certificado del mismo año ya terminado deja `CLOSED_YEAR` y `system_reason` «Investidura acreditada posteriormente mediante certificado validado». | InvestitureAuthorizationRequestService.readForAuthorizer() | `src/investiture-requests/investiture-authorization-requests.controller.ts` |
| GET | `/api/v1/investiture-history` | JWT | Quien consulta, solo sus filas. | Historial propio. Incluye `PENDING`, `INVESTED`, rechazos, `CLOSED_YEAR` y el `REMOVED` de certificado histórico. Trae `class_id`, `class_name` y `ecclesiastical_year_id`. No trae `rejection_reason`, `system_reason` ni el tipo de rechazo. `PENDING`: `person_text` «En espera de autorización.». `INVESTED`: la fecha, la clase y `authorization_comment` si existe. Los dos rechazos salen como `status` `REJECTED` y `person_text` «Falta de requisitos para investidura». `CLOSED_YEAR` no usa ese texto. El certificado posterior del mismo año y el histórico dejan su nota en `person_text`. | InvestitureAuthorizationRequestService.ownHistory() | `src/investiture-requests/investiture-authorization-requests.controller.ts` |
| GET | `/api/v1/club-sections/:sectionId/investiture-history` | JWT | Director, secretario o secretario-tesorero con cargo operativo activo en esa sección. Otro cargo o otra sección: 403 `INVESTITURE_REQUEST_FORBIDDEN`. | El mismo historial, limitado a la sección. `CLOSED_YEAR` no trae el texto de falta de requisitos. Si se acreditó después por certificado del mismo año, `system_reason` es «Investidura acreditada posteriormente mediante certificado validado». | InvestitureAuthorizationRequestService.sectionHistory() | `src/investiture-requests/investiture-authorization-requests.controller.ts` |
| GET | `/api/v1/club-sections/:sectionId/investiture-yearbook` | JWT | Los mismos cargos de esa sección. | Anuario, no un aviso. Lista enrollments `OPERATIONAL` cuyo tipo de clase es el de esa sección, de quienes tuvieron cargo `active`, `inactive` o `ended` en cualquier sección del mismo club. Una clase de otro tipo, aunque la persona tenga membresía aquí, no entra. La clase cruzada aparece en la sección de su tipo, en el mismo club. No exige una solicitud de investidura. No crea inscripciones ni incluye otro club. | InvestitureAuthorizationRequestService.yearbook() | `src/investiture-requests/investiture-authorization-requests.controller.ts` |
| POST | `/api/v1/investiture-requests/:requestId/resolutions` | JWT | El mismo autorizador. Editar la ventana o la fecha no autoriza. | Cuerpo `{ "invest": [{ "person_id", "comment"? }], "reject": [{ "person_id", "reason" }] }`. `GM-02` y `GM-03` ya pendientes: `REMOVED` con `resolution_code` `CLASS_NOT_ELIGIBLE`, sin investir, sin evento y sin texto de falta de requisitos; el resto de la resolución se confirma. Presentar o agregar esas clases sigue en 400 `INVESTITURE_REQUEST_CLASS_NOT_ELIGIBLE`. Se puede investir a unos y rechazar a otros; el resto sigue `PENDING`. El comentario es opcional, hasta 500. El motivo humano es obligatorio, hasta 1000; si falta: 400 `INVESTITURE_REQUEST_REASON_REQUIRED`. Una persona en las dos listas, o repetida: 400 `INVESTITURE_REQUEST_CONFLICTING_DECISION`. Texto más largo: 400 `INVESTITURE_REQUEST_TEXT_TOO_LONG`. Selección vacía: 400 `INVESTITURE_REQUEST_EMPTY`. El día local tiene que caer en la ventana, hasta el último día incluido. No hay plazo de siete días después de la fecha de investidura. Fuera de la ventana: 409 `INVESTITURE_REQUEST_WINDOW_CLOSED`. Cambiar solo la fecha no reabre la ventana. Ampliar la ventana dentro del año sí permite resolver. Año cerrado, o el día local después de `end_date` aunque `active` siga true: 409 `INVESTITURE_REQUEST_YEAR_CLOSED`. Si la fecha de una persona quedó fuera de la ventana, esa persona sigue `PENDING` y la respuesta la trae en `blocked` con `INVESTITURE_REQUEST_DATE_OUTSIDE_WINDOW`; las demás de la misma llamada sí se resuelven. Si todas quedan bloqueadas, 400 con ese código y no se escribe nada. Quien ya no cumple progreso o duración queda `REJECTED_BY_SYSTEM`, `resolution_code` `REQUIREMENTS`, `system_reason` con el texto largo, y su enrollment no pasa a `INVESTIDO`. Las demás pueden quedar investidas. El rechazo humano queda `REJECTED_BY_PERSON` con `rejection_reason` y no cambia `investiture_status`. Autorizar pone la persona en `INVESTED` y el enrollment en `INVESTIDO` con la fecha de esa persona, sin fila en `investiture_validation_history`. El `updateMany` del enrollment exige el estado releído dentro de la transacción y, si coincide, deja `INVESTIDO` con `locked_for_validation` en false. Si no coincide una fila, esa persona queda `REMOVED` sin escribir el enrollment y sin `class.completed`. Si el estado actual es `INVESTIDO`, `resolution_code` es `ALREADY_INVESTED`. Si el enrollment conserva `locked_for_validation` en true de la vía anterior (y no está en `FIELD_APPROVED`), es `LEGACY_PIPELINE_ACTIVE`. En otro desajuste es `CONCURRENT_STATUS`. Las demás personas de la misma llamada se confirman. Ese desajuste no responde 409. Un `INVESTIDO` de la misma persona y clase, en otro enrollment y cualquier `record_kind`, deja a la persona `REMOVED` con `resolution_code` `ALREADY_INVESTED`, sin evento y sin el texto de falta de requisitos. Un enrollment con `locked_for_validation` en true que no está en `FIELD_APPROVED` queda `REMOVED` con `resolution_code` `LEGACY_PIPELINE_ACTIVE`, sin escribir el enrollment, sin evento y sin ese texto. `FIELD_APPROVED` con persona `PENDING`, aunque `locked_for_validation` sea true, lo escribe esta resolución: es el único escritor de esa carrera contra `invest`. Presentar y agregar rechazan ese `FIELD_APPROVED` solo mientras conserva `locked_for_validation`. Con la persona en `INVESTED` queda, en la misma transacción, `achievement_intent_key`. `class.completed` se entrega después del commit, con `idempotency_key` igual a esa intención. El `jobId` de la cola es otro valor estable, sin `:`. Si el insert o la cola fallan, la respuesta sigue en éxito. Si ese trabajo agota sus intentos y queda en `failed`, la reconciliación lo reintenta con el mismo id y los intentos en cero; no crea otra fila. Una reconciliación al arrancar y cada cinco minutos entrega esa intención aunque el año o la ventana ya hayan cerrado o el autorizador ya no tenga la asignación; no reabre la decisión. El reintento del POST, con el calendario abierto, también recupera una sola fila y después responde 409 `INVESTITURE_REQUEST_ALREADY_RESOLVED`. Presentar, rechazar, quitar, el cierre de esa fila o un fallo antes de confirmar no lo emiten. Si la persona ya no está pendiente y no hay intención pendiente, 409 `INVESTITURE_REQUEST_ALREADY_RESOLVED` cuando ninguna de la selección se pudo resolver. La primera decisión confirmada queda. Dentro de la transacción, después de esperar, se leen el año, la ventana y la asignación del pastor, y el instante de esa comprobación se toma después de los candados. El orden de candados es año, calendario del Campo, pastor si aplica, sección/año, usuarios y enrollments. Guardar la ventana, cerrar el año y quitar al pastor toman el candado que les corresponde, también si la ventana todavía no tiene fila. El cierre de una fila `PENDING` como `CLOSED_YEAR` no es ruta HTTP: lo hace `closePendingInvestitureAuthorizations`, sin tocar el enrollment ni emitir el logro. No envía correo ni notificación. | InvestitureAuthorizationRequestService.resolve() | `src/investiture-requests/investiture-authorization-requests.controller.ts` |

La duración usa el año de inicio del enrollment y el año de la solicitud. Si todavía no cumple `min_duration_years`, responde 400 `INVESTITURE_DURATION_MIN_NOT_MET`. Si ya superó `max_duration_years`, o el estado es `EXPIRED`, responde 400 `INVESTITURE_DURATION_EXPIRED` y no cambia el enrollment. Una inscripción cruzada válida se presenta en la sección del mismo club cuyo tipo es el de la clase; la membresía puede estar en otra sección de ese club. La sección de otro tipo, u otro club, responde 409 `INVESTITURE_REQUEST_OUTSIDE_SECTION`.

Presentar y agregar toman el candado de sección y año antes de buscar o crear la cabecera, aunque esa fila todavía no exista, y luego el candado de cada enrollment. Dos personas distintas de la misma sección y año quedan en una sola solicitud. La lectura devuelve a todas las que siguen `PENDING`. Después de confirmar, presentan y agregan guardan la intención del correo en esa misma transacción y después preparan un correo por destinatario y por rol. Cada presentación tiene su propia identidad. Volver a presentar los mismos enrollments es otra operación. Recuperar no cambia la identidad de quien ya fue atendido. Quitar y cambiar la fecha no lo preparan. Aceptar la cola deja el aviso en `queued`. `sent` llega cuando el proveedor confirma. Si ese acuse se pierde y el envío sigue permitido, el reintento usa el contenido guardado durante 24 horas y después el aviso queda `uncertain`, sin reenviar solo. Antes de cada llamada al proveedor, también con ese contenido congelado, se vuelven a leer destinatario, rol, territorio, año y pendientes. Si ya no corresponde, o si solo queda autorizada una parte del contenido congelado, no se envía y no se cambia el cuerpo ni la clave. Ese cuerpo, su destino y su alcance salen de la misma instantánea con la que se armó el correo.

Mientras una persona sigue `PENDING`, puntaje, alta o baja de evidencia, envío de la sección, y aprobar o rechazar esa evidencia responden 409 `INVESTITURE_REQUEST_PROGRESS_LOCKED`. Las escrituras de la vía anterior (club → coordinación → campo) ya no existen: sus rutas, los alias de enrollments, las operaciones en bloque y `POST /validation/submit` o `POST /validation/class/:id/review` con `entity_type` `class` responden HTTP 410 `INVESTITURE_LEGACY_PIPELINE_RETIRED` (fase 8, sección «investiture» más abajo), así que ya no responden `INVESTITURE_REQUEST_PROGRESS_LOCKED`. El código `INVESTITURE_CONCURRENT_UPDATE` (y otros siete que solo usaba esa vía: `INVESTITURE_INVALID_STATE_TRANSITION`, `INVESTITURE_ALREADY_INVESTIDO`, `INVESTITURE_REJECT_COMMENTS_REQUIRED`, `INVESTITURE_FIELD_APPROVE_REQUIRES_ADMIN`, `INVESTITURE_CONFIG_NOT_FOUND`, `INVESTITURE_CONFIG_DUPLICATE`, `INVESTITURE_REQUIREMENTS_INCOMPLETE`) se eliminó del backend en la fase 8. El honor no cambia. `expire-overdue` toma el mismo candado del enrollment dentro de la transacción que guarda, omite al enrollment con un `PENDING` sin abortar el lote y no escribe historial de las filas que no pasaron a `EXPIRED`. `locked_for_validation`, `INVESTIDO` y `EXPIRED` responden `CLASS_PROGRESS_LOCKED` antes de escribir; los estados de la cadena anterior (`CLUB_APPROVED`, `APPROVED` y similares) ya no bloquean por sí solos, así que un expediente liberado por el desbloqueo vuelve a admitir progreso. Enviar una sección y aprobar o rechazar una evidencia de clase solo se cierran con `INVESTIDO` o `EXPIRED`. Otra clase de la misma persona no queda bloqueada por esa fila.

Una resolución confirmada avisa en la bandeja de la app, no por correo. La intención de ese aviso queda en la misma transacción. La directiva de esa sección recibe como máximo dos avisos: uno de investidos y uno de rechazados. El de rechazados junta el rechazo humano y el del sistema, nombra a cada persona y dice quién decidió (la persona o «el sistema», con el texto largo solo en el del sistema). No incluye el motivo humano. La persona investida recibe el texto alegre, sin el comentario. Cualquier rechazo le deja solo «Falta de requisitos para investidura». El motivo humano y el comentario no salen en el aviso de la persona. El subdirector no lo recibe. Un reintento de una decisión ya confirmada no vuelve a avisar. La bandeja usa `notification_logs.idempotency_key`. Si esa escritura falla, el aviso no queda `sent`. El push no sustituye esa fila. El push del resultado lleva `data` con `type: "investiture_result"`, `audience` (`person` o `board`), `requestId`, `sectionId` (cadena) y, solo para `person`, `classId` (cadena); la bandeja (`notification_logs`) no cambia y se enruta por `source` (`investiture:invested` o `investiture:rejected`). Quien apaga `approvals` no lo recibe. El recordatorio es otro correo, el día programado, desde las 10:00 hasta las 23:59 en la zona del Campo. Si la corrida de las 10:00 no ocurrió, sale en la primera corrida de ese mismo día local y no se recupera un día anterior. Un reintento de un fallo vale solo ese día local de la ejecución; pasado el día queda `skipped` con `reminder_day_elapsed`. El tope es 5 intentos al proveedor y después `reminder_retry_limit`: cada entrega de un recordatorio a la cola es un único intento (`attempts: 1`, sin reintentos internos de BullMQ), de modo que el total no pasa de 5 llamadas al proveedor. No crea avisos periódicos en el panel. Una zona en blanco usa `America/Mexico_City`. Una zona inválida responde 400 `INVESTITURE_REQUEST_TIME_ZONE_INVALID` en la solicitud y en el certificado, y el recordatorio omite ese Campo. Un pastor que perdió el rol global no recibe presentación ni recordatorio. Antes de cada llamada al proveedor se vuelven a leer alcance, año, ventana y pendientes, también cuando el contenido ya está congelado. Si ya no corresponde, o si solo queda autorizada una parte del contenido congelado, no se envía y no se cambia el cuerpo ni la clave. Ese cuerpo, su destino y su alcance salen de la misma instantánea con la que se armó el correo. Si sigue permitido, un acuse ambiguo se reconcilia con el contenido guardado durante 24 horas y después queda `uncertain`. La ventana por defecto se resuelve igual en el primer envío y en el reintento. `investiture_message_dispatches` impide repetir el mismo envío para el mismo destinatario, rol y alcance. `queued` no es entrega. `INVESTITURE_EMAIL_ENABLED` sale en false. `ADMIN_PANEL_URL` arma `{origen}/investiture-requests/{requestId}` y solo es obligatorio con ese interruptor encendido. Presentación y recordatorios solo salen si ese interruptor y `EMAIL_ENABLED` están en true. Si falta uno, quedan `skipped` con `last_error` `investiture_email_disabled` y no se reenvían al encender el otro. Un job ya encolado se vuelve a consultar antes del proveedor y, si el correo ya no está habilitado, tampoco sale. La bandeja de la app no usa esos interruptores. Un error de un Campo no aborta los otros ni `deliverPending`. Cada aparición de `/investiture-requests/` exige origen absoluto. La fase 8 apagó la vía anterior en el código (rama `feat/investiture-legacy-shutdown`): no está desplegada, y sus migraciones y el desbloqueo no se aplicaron ni corrieron en ningún entorno.

### classes

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/classes` | JWT | - | Listar clases | ClassesService.findAll() | `src/classes/classes.controller.ts` |
| GET | `/api/v1/classes/:classId` | JWT | - | Obtener clase por ID (incluye `prerequisites` activos y `honors[]` por módulo) | ClassesService.findOne() | `src/classes/classes.controller.ts` |
| GET | `/api/v1/classes/:classId/modules` | JWT | - | Obtener módulos de una clase (embebe `honors[]` por módulo, sin `user_status`) | ClassesService.getModules() | `src/classes/classes.controller.ts` |
| GET | `/api/v1/classes/:classId/honors` | Optional JWT | - | Especialidades relacionadas (`class_honors`); `module_id`, `module_name`, `material_url`; con JWT opcional incluye `user_status`. Informativo: no bloquea módulo ni investidura | ClassesService.getClassHonors() | `src/classes/classes.controller.ts` |

### user-classes

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/users/:userId/classes` | JWT | Permisos: classes:read | Obtener inscripciones del usuario | ClassesService.getUserEnrollments() | `src/classes/classes.controller.ts` |
| POST | `/api/v1/users/:userId/classes/enroll` | JWT | Permisos: classes:submit_progress | Inscribir usuario en clase. GM investido puede añadir una clase cruzada de Aventureros/Conquistadores (`cross_type_enrollment`). Errores: `CLASS_MAX_AVENTU_CONQUIS_ACTIVE`, `CLASS_MAX_GM_ACTIVE`, `CLASS_CROSS_TYPE_GM_REQUIRED`, `CLASS_ALREADY_INVESTED`, `CLASS_ALREADY_ENROLLED` | ClassesService.enrollUser() | `src/classes/classes.controller.ts` |
| GET | `/api/v1/users/:userId/classes/:classId/progress` | JWT | Permisos: classes:read | Obtener progreso del usuario en una clase | ClassesService.getUserProgress() | `src/classes/classes.controller.ts` |
| PATCH | `/api/v1/users/:userId/classes/:classId/progress` | JWT | Permisos: classes:submit_progress | Actualizar progreso de sección | ClassesService.updateSectionProgress() | `src/classes/classes.controller.ts` |
| POST | `/api/v1/users/:userId/classes/:classId/sections/:sectionId/submit` | JWT | Permisos: classes:submit_progress | Submit a class section for validation | ClassesService.submitSection() | `src/classes/classes.controller.ts` |
| POST | `/api/v1/users/:userId/classes/:classId/sections/:sectionId/files` | JWT | Permisos: classes:submit_progress | Upload evidence file for a class section | ClassesService.uploadSectionFile() | `src/classes/classes.controller.ts` |
| DELETE | `/api/v1/users/:userId/classes/:classId/sections/:sectionId/files/:fileId` | JWT | Permisos: classes:submit_progress | Delete evidence file for a class section | ClassesService.deleteSectionFile() | `src/classes/classes.controller.ts` |

### club-enrollments

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/club-enrollments/validation/queue` | JWT | Permisos: club_instances:update | Listar inscripciones anuales pendientes de Campo Local | ClubEnrollmentsService.findValidationQueue() | `src/club-enrollments/club-enrollment-validation.controller.ts` |
| POST | `/api/v1/club-enrollments/:enrollmentId/approve` | JWT | Permisos: club_instances:update | Aprobar inscripción anual del club | ClubEnrollmentsService.approve() | `src/club-enrollments/club-enrollment-validation.controller.ts` |
| POST | `/api/v1/club-enrollments/:enrollmentId/reject` | JWT | Permisos: club_instances:update | Rechazar inscripción anual del club | ClubEnrollmentsService.reject() | `src/club-enrollments/club-enrollment-validation.controller.ts` |
| POST | `/api/v1/clubs/:clubId/sections/:sectionId/enrollments` | JWT | Permisos: club_instances:create | Crear inscripción anual | ClubEnrollmentsService.create() | `src/club-enrollments/club-enrollments.controller.ts` |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId/enrollments` | JWT | Permisos: club_instances:read | Listar inscripciones de la sección | ClubEnrollmentsService.findBySectionId() | `src/club-enrollments/club-enrollments.controller.ts` |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId/enrollments/current` | JWT | Permisos: club_instances:read | Obtener inscripción vigente | ClubEnrollmentsService.findCurrentBySectionId() | `src/club-enrollments/club-enrollments.controller.ts` |
| PATCH | `/api/v1/clubs/:clubId/sections/:sectionId/enrollments/:enrollmentId` | JWT | Permisos: club_instances:update | Actualizar inscripción | ClubEnrollmentsService.update() | `src/club-enrollments/club-enrollments.controller.ts` |

### clubs

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/clubs` | JWT | SkipPermissions (picker post-registro). Con rol territorial el backend recorta por JWT; filtros fuera de alcance → 403 `GUARD_PERMISSION_DENIED`. Sin rol territorial la lista sigue amplia. | Listar clubs | ClubsService.findAll() | `src/clubs/clubs.controller.ts` |
| GET | `/api/v1/clubs/:clubId` | JWT | Permisos: clubs:read | Obtener club por ID | ClubsService.findOne() | `src/clubs/clubs.controller.ts` |
| POST | `/api/v1/clubs` | JWT | Permisos: clubs:create. `local_field_id` debe estar dentro del alcance territorial del actor (`403 GUARD_PERMISSION_DENIED` si no). | Crear club y una sección por cada `club_type` activo. `enabled_club_type_ids` marca AV/CQ `active=true`. Guías Mayores (name/slug/code, nunca `club_type_id` numérico) queda siempre `active=true` y se inyecta si se omite. Array vacío válido si hay GM en catálogo; si no → `400 CLUB_SECTION_TYPES_REQUIRED`. Catálogo vacío o id inexistente → `400 CLUB_TYPE_NOT_FOUND`. No se inventa un id GM. | ClubsService.create() | `src/clubs/clubs.controller.ts` |
| PATCH | `/api/v1/clubs/:clubId` | JWT | Permisos: clubs:update; Club: director, deputy-director, secretary, secretary-treasurer | Actualizar ficha del club (dirección o secretaría de la sección activa) | ClubsService.update() | `src/clubs/clubs.controller.ts` |
| DELETE | `/api/v1/clubs/:clubId` | JWT | Permisos: clubs:delete; Club: director | Desactivar club (requiere rol director) | ClubsService.remove() | `src/clubs/clubs.controller.ts` |
| GET | `/api/v1/clubs/:clubId/sections` | JWT | SkipPermissions (picker post-registro) | Listar secciones del club. Por defecto solo `active=true` (post-registro/membresía). `?includeInactive=true` para gestión. Sin `name`; el tipo va en `club_types` | ClubsService.getSections() | `src/clubs/clubs.controller.ts` |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId` | JWT | Permisos: club_sections:read | Obtener sección por ID | ClubsService.getSection() | `src/clubs/clubs.controller.ts` |
| POST | `/api/v1/clubs/:clubId/sections` | JWT | Permisos: club_sections:create; Club: director, deputy-director | Crear sección si falta el tipo (club pre-migración). 409 si el tipo ya existe. Sin nombre propio | ClubsService.createSection() | `src/clubs/clubs.controller.ts` |
| PATCH | `/api/v1/clubs/:clubId/sections/:sectionId` | JWT | Permisos: club_sections:update; recurso `club_section`; Club: director, deputy-director, secretary, secretary-treasurer de esa sección | Actualizar sección (dirección o secretaría de la sección activa; no cruza a otra sección del mismo club). `active=false` en Guías Mayores → `400 CLUB_SECTION_MASTER_GUIDES_REQUIRED`. `active=true` en GM inactiva (legado) está permitido. `fee` / `souls_target` / meeting no se bloquean. | ClubsService.updateSection() | `src/clubs/clubs.controller.ts` |
| GET | `/api/v1/clubs/:clubId/leadership` | JWT | Permisos: clubs:read | Liderazgo del club: solo `status=active` del año eclesiástico vigente (excluye `designated`) | ClubsService.getClubLeadership() | `src/clubs/clubs.controller.ts` |
| GET | `/api/v1/clubs/:clubId/overview` | JWT | Permisos: clubs:read | Resumen agregado del club | ClubsService.getClubOverview() | `src/clubs/clubs.controller.ts` |
| GET | `/api/v1/clubs/:clubId/history` | JWT | Permisos: clubs:read | Historial de auditoría del club | ClubsService.getClubHistory() | `src/clubs/clubs.controller.ts` |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId/members` | JWT | Permisos: club_roles:read | Listar miembros de la sección. Incluye `guide_major_eligible` y `guide_major_basis` (`INVESTED`/`APPROVED`/`ACTIVE_ENROLLMENT`); `class_counselor_eligible` queda como alias | ClubsService.getMembers() | `src/clubs/clubs.controller.ts` |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId/members/:userId/assignable-roles` | JWT | Permisos: club_roles:read | Roles de club que se pueden asignar al usuario en esa sección. Devuelve `{ guide_major_eligible, section_kind (AV|CQ|GM|UNKNOWN), roles: [{ role_id, role_name, allowed, violation_rule, violation_code }] }` con **todos** los roles de club; los no permitidos traen `allowed:false` y el motivo (`CLUB_ROLE_GUIDE_MAJOR_REQUIRED` o `CLUB_ROLE_MEMBER_REQUIRES_GUIDE_MAJOR_SECTION`). La sección debe pertenecer a `clubId` y el usuario debe tener una asignación en ella (si no, 404 `GUARD_ASSIGNMENT_NOT_FOUND`). | ClubsService.getAssignableRoles() | `src/clubs/clubs.controller.ts` |
| POST | `/api/v1/clubs/:clubId/sections/:sectionId/roles` | JWT | Permisos: club_roles:assign | Asignar rol a un miembro (requiere director, deputy director o secretary). Elegibilidad GM (también en `PATCH /club-roles/:assignmentId`, `director-assignment`, `director-succession`, solicitudes de asignación/transferencia, aprobación de membresía y post-registro): 403 `CLUB_ROLE_GUIDE_MAJOR_REQUIRED` (cargo distinto de `member` sin ser elegible GM) o 403 `CLUB_ROLE_MEMBER_REQUIRES_GUIDE_MAJOR_SECTION` (elegible GM como `member` de AV/CQ); inscripción anual: outcome `blocked` con el mismo código (el salto de tipo AV→CQ por violación responde `skipped`, solo con `logger.warn`) | ClubsService.assignRole() | `src/clubs/clubs.controller.ts` |
| POST | `/api/v1/clubs/:clubId/sections/:sectionId/director-assignment` | JWT | Permisos: club_roles:assign | Asignación inicial de director de sección del **año vigente**. Year distinto → 400 `CLUB_DIRECTOR_DESIGNATION_YEAR_INVALID` | ClubsService.assignInitialSectionDirector() | `src/clubs/clubs.controller.ts` |
| POST | `/api/v1/clubs/:clubId/sections/:sectionId/director-succession` | JWT | Permisos: club_roles:assign, club_roles:revoke; actores: super-admin, admin, director-lf, assistant-lf + canManageClub | Destitución del director en el **año eclesiástico vigente** (`getCurrentYear()`). El year del body y el de `current_assignment_id` deben coincidir con ese año; si no → 400 `CLUB_DIRECTOR_DESIGNATION_YEAR_INVALID`. **No** es la herramienta de diciembre para N+1 (usar `director-designation`) | ClubsService.succeedSectionDirector() | `src/clubs/clubs.controller.ts` |
| POST | `/api/v1/clubs/:clubId/sections/:sectionId/director-designation` | JWT | Permisos: club_roles:assign; `@AuthorizationResource` club; assertCanDesignateDirector (super-admin, admin, director-lf, assistant-lf + canManageClub). Sección debe pertenecer a `clubId`. Header `Idempotency-Key` obligatorio | Preelegir director de un año futuro: crea fila en `director_succession_plans` (`status=scheduled`). No crea CRA `designated` ni invalida caché del sucesor. Vacante → `outgoing_assignment_id` null. Body `{ user_id, ecclesiastical_year_id }`. 201 data `{ succession_id, user_id, ecclesiastical_year_id, effective_date, status, version, outgoing_assignment_id }`. Misma clave+payload reutiliza el plan; distinta payload → 409 `IDEMPOTENCY_KEY_REUSED`. Plan abierto existente → 409 `CLUB_DIRECTOR_PLAN_CONFLICT`. Año no futuro (fechas, no `year_id`) → 400 `CLUB_DIRECTOR_PLAN_YEAR_INVALID`. Falta header → 400 `CLUB_DIRECTOR_PLAN_IDEMPOTENCY_REQUIRED`. `CLUB_DIRECTOR_DESIGNATION_YEAR_INVALID` queda para assignment/succession/update del **año vigente**, no para preelección | DirectorDesignationService.designate() | `src/clubs/clubs.controller.ts` |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId/director-designation` | JWT | Mismos actores que POST (permiso + assertCanDesignateDirector; no basta el permiso solo) | Plan abierto (`scheduled`/`activated`/`blocked`) del año `?yearId=` o `null`. Nunca CRA `designated` | DirectorDesignationService.getDesignation() | `src/clubs/clubs.controller.ts` |
| PATCH | `/api/v1/clubs/:clubId/sections/:sectionId/director-designation` | JWT | Mismos actores que POST | Reemplazar sucesor de un plan `scheduled`. Body `{ succession_id, version, successor_user_id }`. No muta al director operativo. 404 `CLUB_DIRECTOR_PLAN_NOT_FOUND`; versión obsoleta → 409 `CLUB_DIRECTOR_PLAN_VERSION_CONFLICT` | DirectorDesignationService.replacePlan() | `src/clubs/clubs.controller.ts` |
| DELETE | `/api/v1/clubs/:clubId/sections/:sectionId/director-designation` | JWT | Mismos actores que POST | Cancelar plan `scheduled`. Query `successionId` + `version`. No muta al director operativo. Tras cancelar se puede reprogramar | DirectorDesignationService.cancelPlan() | `src/clubs/clubs.controller.ts` |

### club-roles

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| PATCH | `/api/v1/club-roles/:assignmentId` | JWT | Permisos: club_roles:assign | Actualizar asignación de rol. No admite escribir `status=designated` (400 `CLUB_DIRECTOR_DESIGNATION_YEAR_INVALID`). Una fila ya `designated` no reconciliada rechaza cualquier mutación → 409 `CLUB_DIRECTOR_DESIGNATED_UNRECONCILED`. No mover un director a un año no vigente | ClubsService.updateRoleAssignment() | `src/clubs/clubs.controller.ts` |
| DELETE | `/api/v1/club-roles/:assignmentId` | JWT | Permisos: club_roles:revoke | Remover rol de miembro | ClubsService.removeRoleAssignment() | `src/clubs/clubs.controller.ts` |

### admin-coordination

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/coordination/local-fields/:localFieldId/zones` | JWT | Permisos: coordination:manage; Global: admin, super-admin, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Listar zonas de coordinación de un campo local | CoordinationService.listZones() | `src/coordination/coordination.controller.ts` |
| POST | `/api/v1/admin/coordination/local-fields/:localFieldId/zones` | JWT | Permisos: coordination:manage; Global: admin, super-admin, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Crear zona de coordinación en un campo local | CoordinationService.createZone() | `src/coordination/coordination.controller.ts` |
| PATCH | `/api/v1/admin/coordination/zones/:zoneId` | JWT | Permisos: coordination:manage; Global: admin, super-admin, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Actualizar zona de coordinación | CoordinationService.updateZone() | `src/coordination/coordination.controller.ts` |
| POST | `/api/v1/admin/coordination/zones/:zoneId/districts/:districtId` | JWT | Permisos: coordination:manage; Global: admin, super-admin, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Asignar un distrito a una zona de coordinación | CoordinationService.assignDistrictToZone() | `src/coordination/coordination.controller.ts` |
| DELETE | `/api/v1/admin/coordination/zones/:zoneId/districts/:districtId` | JWT | Permisos: coordination:manage; Global: admin, super-admin, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Quitar un distrito de una zona de coordinación | CoordinationService.removeDistrictFromZone() | `src/coordination/coordination.controller.ts` |
| GET | `/api/v1/admin/coordination/local-fields/:localFieldId/assignments` | JWT | Permisos: coordination:manage; Global: admin, super-admin, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Listar asignaciones de coordinadores | CoordinationService.listAssignments() | `src/coordination/coordination.controller.ts` |
| POST | `/api/v1/admin/coordination/local-fields/:localFieldId/assignments` | JWT | Permisos: coordination:manage; Global: admin, super-admin, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Crear asignación de coordinador | CoordinationService.createAssignment() | `src/coordination/coordination.controller.ts` |
| PATCH | `/api/v1/admin/coordination/assignments/:assignmentId` | JWT | Permisos: coordination:manage; Global: admin, super-admin, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Actualizar asignación de coordinador | CoordinationService.updateAssignment() | `src/coordination/coordination.controller.ts` |
| POST | `/api/v1/admin/coordination/local-fields/:localFieldId/backfill` | JWT | Permisos: coordination:manage; Global: admin, super-admin, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Migrar coordinadores legacy (rol + local_field_id) a asignación GENERAL | CoordinationService.backfillLegacyAssignments() | `src/coordination/coordination.controller.ts` |

### coordination

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/coordination/me/scope` | JWT | - | Resolver el alcance efectivo de coordinación del usuario actual | CoordinationService.resolveCoordinatorScope() | `src/coordination/coordination.controller.ts` |

### dashboard

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/dashboard/summary` | JWT | - | Resumen del dashboard del usuario autenticado | DashboardService.getSummary() | `src/dashboard/dashboard.controller.ts` |

### data-export

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/users/me/data-export` | JWT | - | Request a GDPR data export | DataExportService.requestExport() | `src/data-export/data-export.controller.ts` |
| GET | `/api/v1/users/me/data-exports` | JWT | - | List all data export requests for the current user | DataExportService.listExports() | `src/data-export/data-export.controller.ts` |
| GET | `/api/v1/users/me/data-exports/:exportId/download` | JWT | - | Get presigned download URL for a ready export | DataExportService.getDownloadUrl() | `src/data-export/data-export.controller.ts` |

### emergency-contacts

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/users/:userId/emergency-contacts` | JWT | - | Crear contacto de emergencia (máximo 5) | EmergencyContactsService.create() | `src/emergency-contacts/emergency-contacts.controller.ts` |
| GET | `/api/v1/users/:userId/emergency-contacts` | JWT | - | Listar contactos de emergencia del usuario | EmergencyContactsService.findAll() | `src/emergency-contacts/emergency-contacts.controller.ts` |
| GET | `/api/v1/users/:userId/emergency-contacts/:contactId` | JWT | - | Obtener un contacto específico | EmergencyContactsService.findOne() | `src/emergency-contacts/emergency-contacts.controller.ts` |
| PATCH | `/api/v1/users/:userId/emergency-contacts/:contactId` | JWT | - | Actualizar contacto de emergencia | EmergencyContactsService.update() | `src/emergency-contacts/emergency-contacts.controller.ts` |
| DELETE | `/api/v1/users/:userId/emergency-contacts/:contactId` | JWT | - | Eliminar contacto de emergencia (soft delete) | EmergencyContactsService.remove() | `src/emergency-contacts/emergency-contacts.controller.ts` |

### evidence-review

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/evidence-review/pending` | JWT | Global: admin, super-admin, coordinator; Permisos: validation:review | Listar evidencias pendientes de revisión | EvidenceReviewService.getPending() | `src/evidence-review/evidence-review.controller.ts` |
| POST | `/api/v1/evidence-review/bulk-approve` | JWT | Global: admin, super-admin, coordinator; Permisos: validation:review | Aprobar múltiples evidencias en bloque | EvidenceReviewService.bulkApprove() | `src/evidence-review/evidence-review.controller.ts` |
| POST | `/api/v1/evidence-review/bulk-reject` | JWT | Global: admin, super-admin, coordinator; Permisos: validation:review | Rechazar múltiples evidencias en bloque | EvidenceReviewService.bulkReject() | `src/evidence-review/evidence-review.controller.ts` |
| GET | `/api/v1/evidence-review/:type/:id` | JWT | Global: admin, super-admin, coordinator; Permisos: validation:review | Obtener detalle de una evidencia con archivos adjuntos | EvidenceReviewService.getDetail() | `src/evidence-review/evidence-review.controller.ts` |
| POST | `/api/v1/evidence-review/:type/:id/approve` | JWT | Global: admin, super-admin, coordinator; Permisos: validation:review | Aprobar una evidencia | EvidenceReviewService.approve() | `src/evidence-review/evidence-review.controller.ts` |
| POST | `/api/v1/evidence-review/:type/:id/reject` | JWT | Global: admin, super-admin, coordinator; Permisos: validation:review | Rechazar una evidencia con motivo | EvidenceReviewService.reject() | `src/evidence-review/evidence-review.controller.ts` |
| GET | `/api/v1/evidence-review/:type/:id/history` | JWT | Global: admin, super-admin, coordinator; Permisos: validation:review | Historial de validación de una evidencia | EvidenceReviewService.getHistory() | `src/evidence-review/evidence-review.controller.ts` |

### finances

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/finances/categories` | JWT | Permisos: finances:read | Listar categorías financieras (Redis TTL 1h; epoch bump al mutar) | FinancesService.getCategories() | `src/finances/finances.controller.ts` |
| GET | `/api/v1/clubs/:clubId/finances/transactions` | JWT | Permisos: finances:read | Listar todas las transacciones del club (paginadas) | FinancesService.getAllTransactions() | `src/finances/finances.controller.ts` |
| GET | `/api/v1/clubs/:clubId/finances` | JWT | Permisos: finances:read | Listar movimientos financieros del club | FinancesService.findByClub() | `src/finances/finances.controller.ts` |
| GET | `/api/v1/clubs/:clubId/finances/summary` | JWT | Permisos: finances:read | Resumen financiero del club | FinancesService.getSummary() | `src/finances/finances.controller.ts` |
| POST | `/api/v1/clubs/:clubId/finances` | JWT | Permisos: finances:create; Club: director, deputy-director, treasurer, secretary-treasurer | Crear movimiento financiero | FinancesService.create() | `src/finances/finances.controller.ts` |
| GET | `/api/v1/finances/:financeId` | JWT | Permisos: finances:read | Obtener movimiento por ID | FinancesService.findOne() | `src/finances/finances.controller.ts` |
| POST | `/api/v1/finances/:financeId/evidences` | JWT | Permisos: finances:update | Subir foto de evidencia de un movimiento financiero | FinancesService.uploadEvidence() | `src/finances/finances.controller.ts` |
| PATCH | `/api/v1/finances/:financeId` | JWT | Permisos: finances:update | Actualizar movimiento | FinancesService.update() | `src/finances/finances.controller.ts` |
| DELETE | `/api/v1/finances/:financeId` | JWT | Permisos: finances:delete | Desactivar movimiento | FinancesService.remove() | `src/finances/finances.controller.ts` |

### health

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/health` | Public | - | Public ping — returns ok if API is reachable | - | `src/health/health.controller.ts` |
| GET | `/api/v1/health/details` | JWT | Global: admin, super-admin | Detailed health status (admin only) | - | `src/health/health.controller.ts` |

### honors

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/honors/:honorId/requirements` | JWT | - | Obtener requisitos de un honor | HonorRequirementsService.getRequirements() | `src/honors/honor-requirements.controller.ts` |
| GET | `/api/v1/honors` | JWT | - | Listar honores | HonorsService.findAll() | `src/honors/honors.controller.ts` |
| GET | `/api/v1/honors/categories` | JWT | - | Listar categorías de honores (Redis TTL 1h; epoch bump al mutar categorías/honores) | HonorsService.getCategories() | `src/honors/honors.controller.ts` |
| GET | `/api/v1/honors/grouped-by-category` | JWT | - | Listar honores agrupados por categoría (Redis TTL 1h; epoch bump al mutar honores/categorías/tipos de club) | HonorsService.getGroupedByCategory() | `src/honors/honors.controller.ts` |
| GET | `/api/v1/honors/:honorId` | JWT | - | Obtener honor por ID | HonorsService.findOne() | `src/honors/honors.controller.ts` |

### user-honors

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/users/:userId/honors/:honorId/requirements/progress` | JWT | Permisos: user_honors:read | Obtener progreso de requisitos del usuario en un honor | HonorRequirementsService.getUserProgress() | `src/honors/honor-requirements.controller.ts` |
| PATCH | `/api/v1/users/:userId/honors/:honorId/requirements/progress/batch` | JWT | Permisos: user_honors:submit | Actualizar progreso de múltiples requisitos | HonorRequirementsService.bulkUpdateProgress() | `src/honors/honor-requirements.controller.ts` |
| PATCH | `/api/v1/users/:userId/honors/:honorId/requirements/:requirementId/progress` | JWT | Permisos: user_honors:submit | Actualizar progreso de un requisito individual | HonorRequirementsService.updateProgress() | `src/honors/honor-requirements.controller.ts` |
| POST | `/api/v1/users/:userId/honors/:honorId/requirements/:requirementId/evidence/upload` | JWT | Permisos: user_honors:create | Subir evidencia (imagen o archivo) para un requisito | HonorRequirementsService.uploadEvidence() | `src/honors/honor-requirements.controller.ts` |
| POST | `/api/v1/users/:userId/honors/:honorId/requirements/:requirementId/evidence/link` | JWT | Permisos: user_honors:create | Agregar enlace como evidencia para un requisito | HonorRequirementsService.addEvidenceLink() | `src/honors/honor-requirements.controller.ts` |
| GET | `/api/v1/users/:userId/honors/:honorId/requirements/:requirementId/evidence` | JWT | Permisos: user_honors:read | Listar evidencias de un requisito | HonorRequirementsService.getEvidences() | `src/honors/honor-requirements.controller.ts` |
| DELETE | `/api/v1/users/:userId/honors/:honorId/requirements/:requirementId/evidence/:evidenceId` | JWT | Permisos: user_honors:delete | Eliminar una evidencia de un requisito | HonorRequirementsService.deleteEvidence() | `src/honors/honor-requirements.controller.ts` |
| GET | `/api/v1/users/:userId/honors` | JWT | Permisos: user_honors:read | Obtener honores del usuario | HonorsService.getUserHonors() | `src/honors/honors.controller.ts` |
| GET | `/api/v1/users/:userId/honors/stats` | JWT | Permisos: user_honors:read | Obtener estadísticas de honores del usuario | HonorsService.getUserHonorStats() | `src/honors/honors.controller.ts` |
| POST | `/api/v1/users/:userId/honors` | JWT | Permisos: user_honors:create | Registrar honor con datos iniciales | HonorsService.createUserHonor() | `src/honors/honors.controller.ts` |
| POST | `/api/v1/users/:userId/honors/bulk` | JWT | Permisos: user_honors:create | Registrar honores de usuario de forma masiva | HonorsService.createUserHonorsBulk() | `src/honors/honors.controller.ts` |
| POST | `/api/v1/users/:userId/honors/:honorId/files` | JWT | Permisos: user_honors:create | Subir evidencias del honor | HonorsService.uploadUserHonorFiles() | `src/honors/honors.controller.ts` |
| POST | `/api/v1/users/:userId/honors/:honorId` | JWT | Permisos: user_honors:create | Iniciar un honor | HonorsService.startHonor() | `src/honors/honors.controller.ts` |
| PATCH | `/api/v1/users/:userId/honors/:honorId` | JWT | Permisos: user_honors:submit | Actualizar progreso de honor | HonorsService.updateUserHonor() | `src/honors/honors.controller.ts` |
| DELETE | `/api/v1/users/:userId/honors/:honorId` | JWT | Permisos: user_honors:delete | Abandonar honor | HonorsService.abandonHonor() | `src/honors/honors.controller.ts` |

### user-master-honors

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/users/:userId/master-honors` | JWT | Permisos: user_honors:read | Obtener maestrías del usuario | MasterHonorsService.getUserMasterHonors() | `src/honors/master-honors.controller.ts` |
| GET | `/api/v1/users/:userId/master-honors/roadmap` | JWT | Permisos: user_honors:read | Obtener roadmap de maestrías del usuario | MasterHonorsService.getUserMasterHonorRoadmap() | `src/honors/master-honors.controller.ts` |
| GET | `/api/v1/users/:userId/master-honors/:masterHonorId` | JWT | Permisos: user_honors:read | Obtener detalle de una maestría del usuario | MasterHonorsService.getUserMasterHonorDetail() | `src/honors/master-honors.controller.ts` |

### insurance

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId/members/insurance` | JWT | Permisos: insurance:read | Listar seguros de miembros por sección | InsuranceService.listMembersInsurance() | `src/insurance/insurance.controller.ts` |
| GET | `/api/v1/insurance/expiring` | JWT | Global: admin, coordinator (alias: zone/general + director-lf/assistant-lf; LF recorta a local_field); SkipPermissions | Listar seguros próximos a vencer | InsuranceService.getExpiringInsurances() | `src/insurance/insurance.controller.ts` |
| GET | `/api/v1/users/:memberId/insurance` | JWT | Permisos: insurance:read | Obtener seguro activo del miembro | InsuranceService.getMemberInsurance() | `src/insurance/insurance.controller.ts` |
| POST | `/api/v1/users/:memberId/insurance` | JWT | Permisos: insurance:create | Crear seguro para un miembro (legacy directo) | InsuranceService.createInsurance() | `src/insurance/insurance.controller.ts` |
| PATCH | `/api/v1/insurance/:insuranceId` | JWT | Permisos: insurance:update | Actualizar seguro | InsuranceService.updateInsurance() | `src/insurance/insurance.controller.ts` |
| GET | `/api/v1/insurance/products` | JWT | Permisos: insurance:configure | Listar productos de seguro del Campo Local activo | InsuranceConfigService.listProducts() | `src/insurance/insurance.controller.ts` |
| POST | `/api/v1/insurance/products` | JWT | Permisos: insurance:configure | Crear producto de seguro para el Campo Local activo | InsuranceConfigService.createProduct() | `src/insurance/insurance.controller.ts` |
| PATCH | `/api/v1/insurance/products/:productId` | JWT | Permisos: insurance:configure | Actualizar producto de seguro del Campo Local activo | InsuranceConfigService.updateProduct() | `src/insurance/insurance.controller.ts` |
| GET | `/api/v1/insurance/cycles` | JWT | Permisos: insurance:configure | Listar ciclos de seguro del Campo Local activo | InsuranceConfigService.listCycles() | `src/insurance/insurance.controller.ts` |
| POST | `/api/v1/insurance/cycles` | JWT | Permisos: insurance:configure | Crear ciclo de seguro para el Campo Local activo | InsuranceConfigService.createCycle() | `src/insurance/insurance.controller.ts` |
| PATCH | `/api/v1/insurance/cycles/:cycleConfigId` | JWT | Permisos: insurance:configure | Actualizar ciclo de seguro del Campo Local activo | InsuranceConfigService.updateCycle() | `src/insurance/insurance.controller.ts` |
| POST | `/api/v1/club-sections/:sectionId/insurance/purchases` | JWT | Permisos: insurance:create | Registrar compra de cupos (qty, legacy a reemplazar por payment-orders) | InsurancePurchasesService.submit() | `src/insurance/insurance-purchases.controller.ts` |
| GET | `/api/v1/club-sections/:sectionId/insurance/purchases` | JWT | Permisos: insurance:read | Listar compras de cupos de la sección | InsurancePurchasesService.listForSection() | `src/insurance/insurance-purchases.controller.ts` |
| GET | `/api/v1/insurance/purchases/:purchaseId` | JWT | Permisos: insurance:read | Detalle de compra de cupos | InsurancePurchasesService.getById() | `src/insurance/insurance-purchases.controller.ts` |
| GET | `/api/v1/insurance/purchases/:purchaseId/proof` | JWT | Permisos: insurance:read | URL firmada del comprobante de compra | InsurancePurchasesService.getById() + signed proof | `src/insurance/insurance-purchases.controller.ts` |
| POST | `/api/v1/insurance/purchases/:purchaseId/confirm` | JWT | Permisos: insurance:review | Confirmar compra y materializar slots AVAILABLE | InsurancePurchasesService.confirm() | `src/insurance/insurance-purchases.controller.ts` |
| POST | `/api/v1/insurance/purchases/:purchaseId/reject` | JWT | Permisos: insurance:review | Rechazar compra de cupos | InsurancePurchasesService.reject() | `src/insurance/insurance-purchases.controller.ts` |
| POST | `/api/v1/insurance/purchases/:purchaseId/reverse` | JWT | Permisos: insurance:review | Revertir compra confirmada | InsurancePurchasesService.reverse() | `src/insurance/insurance-purchases.controller.ts` |

### field-payment-orders

Órdenes de pago territoriales (seguros + camporees). Flag `field_payment_orders_v1` por Campo Local; expiración default 15 días (`field_payment_orders.expiry_days`).

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/insurance/payment-orders` | JWT | Permisos: field-payment-orders:create | Emitir orden grupal de seguro (ciclo + beneficiarios nombrados) | FieldPaymentOrdersService.createInsuranceOrder() | `src/field-payment-orders/field-payment-orders.controller.ts` |
| POST | `/api/v1/camporees/:camporeeId/payment-orders` | JWT | Permisos: field-payment-orders:create | Emitir orden de inscripción a camporee local | FieldPaymentOrdersService.createCamporeeOrder() | `src/field-payment-orders/field-payment-orders.controller.ts` |
| POST | `/api/v1/union-camporees/:camporeeId/payment-orders` | JWT | Permisos: field-payment-orders:create | Emitir orden de inscripción a camporee de unión (v1.1: cobra el Campo Local del emisor) | FieldPaymentOrdersService.createUnionCamporeeOrder() | `src/field-payment-orders/field-payment-orders.controller.ts` |
| GET | `/api/v1/payment-orders` | JWT | Permisos: field-payment-orders:read | Listar órdenes del alcance del actor (filtros purpose/status/camporee_id/union_camporee_id) | FieldPaymentOrdersService.list() | `src/field-payment-orders/field-payment-orders.controller.ts` |
| GET | `/api/v1/payment-orders/review-queue` | JWT | Permisos: field-payment-orders:review | Bandeja de revisión LF (PROOF_SUBMITTED) | FieldPaymentOrdersService.reviewQueue() | `src/field-payment-orders/field-payment-orders.controller.ts` |
| GET | `/api/v1/payment-orders/context` | JWT | Permisos: field-payment-orders:read | Disponibilidad del flujo + ciclos de seguro para la sección activa (app) | FieldPaymentOrdersService.getIssuerContext() | `src/field-payment-orders/field-payment-orders.controller.ts` |
| GET | `/api/v1/payment-orders/config` | JWT | Permisos: field-payment-orders:configure | Instrucciones de pago del Campo Local (banco/caja) | FieldPaymentOrderConfigsService.get() | `src/field-payment-orders/field-payment-orders.controller.ts` |
| POST | `/api/v1/payment-orders/config` | JWT | Permisos: field-payment-orders:configure | Crear/actualizar instrucciones de pago del Campo Local | FieldPaymentOrderConfigsService.upsert() | `src/field-payment-orders/field-payment-orders.controller.ts` |
| GET | `/api/v1/payment-orders/:orderId` | JWT | Permisos: field-payment-orders:read | Detalle de orden con líneas y comprobantes | FieldPaymentOrdersService.get() | `src/field-payment-orders/field-payment-orders.controller.ts` |
| GET | `/api/v1/payment-orders/:orderId/document` | JWT | Permisos: field-payment-orders:read | PDF imprimible de la orden (PDFKit) | FieldPaymentOrdersService.getDocument() | `src/field-payment-orders/field-payment-orders.controller.ts` |
| GET | `/api/v1/payment-orders/:orderId/proof` | JWT | Permisos: field-payment-orders:read | URL firmada del comprobante (TTL 15 min) | FieldPaymentOrdersService.getProofDownload() | `src/field-payment-orders/field-payment-orders.controller.ts` |
| POST | `/api/v1/payment-orders/:orderId/proof` | JWT | Permisos: field-payment-orders:upload-proof | Subir comprobante (multipart, PDF/JPG/PNG ≤10 MB, magic bytes) | FieldPaymentOrdersService.uploadProof() | `src/field-payment-orders/field-payment-orders.controller.ts` |
| POST | `/api/v1/payment-orders/:orderId/cancel` | JWT | Permisos: field-payment-orders:cancel | Cancelar orden ISSUED/PROOF_REJECTED | FieldPaymentOrdersService.cancel() | `src/field-payment-orders/field-payment-orders.controller.ts` |
| POST | `/api/v1/payment-orders/:orderId/approve` | JWT | Permisos: field-payment-orders:review | Aprobar comprobante y materializar fulfillment (maker-checker) | FieldPaymentOrdersService.approve() | `src/field-payment-orders/field-payment-orders.controller.ts` |
| POST | `/api/v1/payment-orders/:orderId/reject` | JWT | Permisos: field-payment-orders:review | Rechazar comprobante con motivo obligatorio | FieldPaymentOrdersService.reject() | `src/field-payment-orders/field-payment-orders.controller.ts` |
| POST | `/api/v1/insurance/reassignments` | JWT | Permisos: field-payment-orders:create | Solicitar reasignación de cobertura activa (mismo club) | InsuranceReassignmentsService.create() | `src/field-payment-orders/insurance-reassignments.controller.ts` |
| GET | `/api/v1/insurance/reassignments` | JWT | Permisos: field-payment-orders:read | Listar solicitudes de reasignación del alcance | InsuranceReassignmentsService.list() | `src/field-payment-orders/insurance-reassignments.controller.ts` |
| POST | `/api/v1/insurance/reassignments/:requestId/approve` | JWT | Permisos: field-payment-orders:review | Aprobar reasignación (mueve assignment + slot movement) | InsuranceReassignmentsService.approve() | `src/field-payment-orders/insurance-reassignments.controller.ts` |
| POST | `/api/v1/insurance/reassignments/:requestId/reject` | JWT | Permisos: field-payment-orders:review | Rechazar reasignación con motivo | InsuranceReassignmentsService.reject() | `src/field-payment-orders/insurance-reassignments.controller.ts` |

### camporee order products

> Pedidos de mercancía (`src/camporee-orders`, migración `20260824190000_camporee_orders`). Distintos de `/payment-orders` (inscripción/seguro).

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/camporee-order-products` | JWT | Permisos: camporee-orders:catalog-manage | Crear producto de la biblioteca territorial | CatalogService.create() | `src/camporee-orders/catalog.controller.ts` |
| GET | `/api/v1/camporee-order-products` | JWT | Permisos: camporee-orders:read | Listar productos visibles en la cascada territorial | CatalogService.list() | `src/camporee-orders/catalog.controller.ts` |
| GET | `/api/v1/camporee-order-products/:productId` | JWT | Permisos: camporee-orders:read | Obtener un producto de la biblioteca | CatalogService.getById() | `src/camporee-orders/catalog.controller.ts` |
| PATCH | `/api/v1/camporee-order-products/:productId` | JWT | Permisos: camporee-orders:catalog-manage | Actualizar un producto (soft-delete con active=false) | CatalogService.update() | `src/camporee-orders/catalog.controller.ts` |
| POST | `/api/v1/camporee-order-products/:productId/options` | JWT | Permisos: camporee-orders:catalog-manage | Agregar una opción de talla al producto | CatalogService.addOption() | `src/camporee-orders/catalog.controller.ts` |
| PATCH | `/api/v1/camporee-order-product-options/:optionId` | JWT | Permisos: camporee-orders:catalog-manage | Actualizar una opción (label inmutable si hay líneas) | CatalogService.updateOption() | `src/camporee-orders/catalog.controller.ts` |

### camporee order offerings

No existe `GET .../orders-settings`. Settings en `GET` de camporee y en este GET de ofertas. Escritura: `PATCH .../orders-settings`.

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| PATCH | `/api/v1/camporees/:camporeeId/orders-settings` | JWT | Permisos: camporee-orders:offering-configure | Actualizar ventana de pedidos del camporee local | OfferingsService.updateSettings() | `src/camporee-orders/offerings.controller.ts` |
| PATCH | `/api/v1/union-camporees/:camporeeId/orders-settings` | JWT | Permisos: camporee-orders:offering-configure | Actualizar ventana de pedidos del camporee de unión | OfferingsService.updateSettings() | `src/camporee-orders/offerings.controller.ts` |
| GET | `/api/v1/camporees/:camporeeId/order-offerings` | JWT | Permisos: camporee-orders:read | Listar ofertas y settings de pedidos del camporee local | OfferingsService.getOfferings() | `src/camporee-orders/offerings.controller.ts` |
| GET | `/api/v1/union-camporees/:camporeeId/order-offerings` | JWT | Permisos: camporee-orders:read | Listar ofertas y settings de pedidos del camporee de unión | OfferingsService.getOfferings() | `src/camporee-orders/offerings.controller.ts` |
| PUT | `/api/v1/camporees/:camporeeId/order-offerings` | JWT | Permisos: camporee-orders:offering-configure | Reemplazar de forma idempotente las ofertas del camporee local | OfferingsService.replaceOfferings() | `src/camporee-orders/offerings.controller.ts` |
| PUT | `/api/v1/union-camporees/:camporeeId/order-offerings` | JWT | Permisos: camporee-orders:offering-configure | Reemplazar de forma idempotente las ofertas del camporee de unión | OfferingsService.replaceOfferings() | `src/camporee-orders/offerings.controller.ts` |

### camporee orders

Folio `PED{yyyy}{####}`. Máquina: `ISSUED` → `PROOF_SUBMITTED` → `PAID` → `DELIVERED` (más rechazo, cancelación, expiración y excepción `authorize-without-proof`). El cliente no envía montos.

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/camporees/:camporeeId/orders` | JWT | Permisos: camporee-orders:create | Emitir un pedido de sección para un camporee local | CamporeeOrdersService.create() | `src/camporee-orders/camporee-orders.controller.ts` |
| POST | `/api/v1/union-camporees/:camporeeId/orders` | JWT | Permisos: camporee-orders:create | Emitir un pedido de sección para un camporee de unión | CamporeeOrdersService.create() | `src/camporee-orders/camporee-orders.controller.ts` |
| GET | `/api/v1/camporee-orders` | JWT | Permisos: camporee-orders:read | Listar pedidos visibles (no colapsa suplementarios) | CamporeeOrdersService.list() | `src/camporee-orders/camporee-orders.controller.ts` |
| GET | `/api/v1/camporee-orders/review-queue` | JWT | Permisos: camporee-orders:review | Bandeja de revisión de pedidos con comprobante (Campo Local) | CamporeeOrdersService.reviewQueue() | `src/camporee-orders/camporee-orders.controller.ts` |
| GET | `/api/v1/camporee-orders/:orderId` | JWT | Permisos: camporee-orders:read | Detalle de pedido con líneas nominadas, summary y snapshot de pago | CamporeeOrdersService.get() | `src/camporee-orders/camporee-orders.controller.ts` |
| GET | `/api/v1/camporee-orders/:orderId/document` | JWT | Permisos: camporee-orders:read | Descargar PDF imprimible del pedido | CamporeeOrdersService.getDocument() | `src/camporee-orders/camporee-orders.controller.ts` |
| GET | `/api/v1/camporee-orders/:orderId/proof` | JWT | Permisos: camporee-orders:read | URL firmada del comprobante vigente (TTL 900 s) | CamporeeOrdersService.getProofDownload() | `src/camporee-orders/camporee-orders.controller.ts` |
| POST | `/api/v1/camporee-orders/:orderId/proof` | JWT | Permisos: camporee-orders:upload-proof | Subir comprobante de pago (multipart, campo file) | CamporeeOrdersService.uploadProof() | `src/camporee-orders/camporee-orders.controller.ts` |
| POST | `/api/v1/camporee-orders/:orderId/cancel` | JWT | Permisos: camporee-orders:create **o** camporee-orders:review | Cancelar un pedido emitido o con comprobante rechazado | CamporeeOrdersService.cancel() | `src/camporee-orders/camporee-orders.controller.ts` |
| POST | `/api/v1/camporee-orders/:orderId/approve` | JWT | Permisos: camporee-orders:review | Aprobar comprobante y marcar el pedido como pagado | CamporeeOrdersService.approve() | `src/camporee-orders/camporee-orders.controller.ts` |
| POST | `/api/v1/camporee-orders/:orderId/reject` | JWT | Permisos: camporee-orders:review | Rechazar comprobante (permite re-subida) | CamporeeOrdersService.reject() | `src/camporee-orders/camporee-orders.controller.ts` |
| POST | `/api/v1/camporee-orders/:orderId/authorize-without-proof` | JWT | Permisos: camporee-orders:authorize-without-proof | Marcar pagado sin comprobante (excepción de caja del Campo Local) | CamporeeOrdersService.authorizeWithoutProof() | `src/camporee-orders/camporee-orders.controller.ts` |
| POST | `/api/v1/camporee-orders/:orderId/deliver` | JWT | Permisos: camporee-orders:deliver | Marcar el bulto entregado del Campo Local a la sección | CamporeeOrdersService.deliverToSection() | `src/camporee-orders/camporee-orders.controller.ts` |
| POST | `/api/v1/camporee-orders/:orderId/lines/:lineId/deliver-to-member` | JWT | Permisos: camporee-orders:distribute | Marcar una línea nominada como entregada al miembro (solo director de la sección) | CamporeeOrdersService.deliverToMember() | `src/camporee-orders/camporee-orders.controller.ts` |

### payment obligations

Read model de solo lectura. No fusiona folios ni muta `field_payment_orders`, `material_orders`, `camporee_orders` o `camporee_supply_payment_docs`.

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/payment-obligations/pending` | JWT | Permisos (any): camporee-orders:read, camporee-supplies:read, field-payment-orders:read, materiales:read | Listar obligaciones pendientes (inscripción, materiales, pedidos e insumos) sin fusionar folios | PaymentObligationsService.listPending() | `src/payment-obligations/payment-obligations.controller.ts` |

### camporee supplies

> Insumos de sección (`src/camporee-supplies`, migración `20260826120000_camporee_supplies`). Distintos de `/camporee-orders` (mercancía PED) y `/payment-orders` (inscripción). Folio `INS{yyyy}{####}`.

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/camporees/:camporeeId/supply-catalog` | JWT | Permisos: camporee-supplies:read | Catálogo de slots y productos del camporee local | CamporeeSupplyConfigService.getCatalog() | `src/camporee-supplies/config.controller.ts` |
| GET | `/api/v1/union-camporees/:camporeeId/supply-catalog` | JWT | Permisos: camporee-supplies:read | Catálogo de slots y productos del camporee de unión | CamporeeSupplyConfigService.getCatalog() | `src/camporee-supplies/config.controller.ts` |
| PATCH | `/api/v1/camporees/:camporeeId/supply-settings` | JWT | Permisos: camporee-supplies:configure | Actualizar corte de edición de insumos (local) | CamporeeSupplyConfigService.updateSettings() | `src/camporee-supplies/config.controller.ts` |
| PATCH | `/api/v1/union-camporees/:camporeeId/supply-settings` | JWT | Permisos: camporee-supplies:configure | Actualizar corte de edición de insumos (unión) | CamporeeSupplyConfigService.updateSettings() | `src/camporee-supplies/config.controller.ts` |
| POST | `/api/v1/camporees/:camporeeId/supply-slots` | JWT | Permisos: camporee-supplies:configure | Crear horario de entrega (local) | CamporeeSupplyConfigService.createSlot() | `src/camporee-supplies/config.controller.ts` |
| POST | `/api/v1/union-camporees/:camporeeId/supply-slots` | JWT | Permisos: camporee-supplies:configure | Crear horario de entrega (unión) | CamporeeSupplyConfigService.createSlot() | `src/camporee-supplies/config.controller.ts` |
| PATCH | `/api/v1/camporees/:camporeeId/supply-slots/:slotId` | JWT | Permisos: camporee-supplies:configure | Actualizar horario de entrega (local) | CamporeeSupplyConfigService.updateSlot() | `src/camporee-supplies/config.controller.ts` |
| PATCH | `/api/v1/union-camporees/:camporeeId/supply-slots/:slotId` | JWT | Permisos: camporee-supplies:configure | Actualizar horario de entrega (unión) | CamporeeSupplyConfigService.updateSlot() | `src/camporee-supplies/config.controller.ts` |
| POST | `/api/v1/camporees/:camporeeId/supply-products` | JWT | Permisos: camporee-supplies:configure | Crear producto de insumos (local) | CamporeeSupplyConfigService.createProduct() | `src/camporee-supplies/config.controller.ts` |
| POST | `/api/v1/union-camporees/:camporeeId/supply-products` | JWT | Permisos: camporee-supplies:configure | Crear producto de insumos (unión) | CamporeeSupplyConfigService.createProduct() | `src/camporee-supplies/config.controller.ts` |
| PATCH | `/api/v1/camporees/:camporeeId/supply-products/:productId` | JWT | Permisos: camporee-supplies:configure | Actualizar producto; precio bloqueado si hay plan SUBMITTED | CamporeeSupplyConfigService.updateProduct() | `src/camporee-supplies/config.controller.ts` |
| PATCH | `/api/v1/union-camporees/:camporeeId/supply-products/:productId` | JWT | Permisos: camporee-supplies:configure | Actualizar producto de unión | CamporeeSupplyConfigService.updateProduct() | `src/camporee-supplies/config.controller.ts` |
| GET | `/api/v1/camporees/:camporeeId/supply-plan` | JWT | Permisos: camporee-supplies:plan | Plan de insumos de la sección activa (local) | CamporeeSupplyPlansService.getOwnPlan() | `src/camporee-supplies/plans.controller.ts` |
| GET | `/api/v1/union-camporees/:camporeeId/supply-plan` | JWT | Permisos: camporee-supplies:plan | Plan de insumos de la sección activa (unión) | CamporeeSupplyPlansService.getOwnPlan() | `src/camporee-supplies/plans.controller.ts` |
| PUT | `/api/v1/camporees/:camporeeId/supply-plan` | JWT | Permisos: camporee-supplies:plan | Reemplazar líneas del plan en DRAFT (local) | CamporeeSupplyPlansService.replaceDraft() | `src/camporee-supplies/plans.controller.ts` |
| PUT | `/api/v1/union-camporees/:camporeeId/supply-plan` | JWT | Permisos: camporee-supplies:plan | Reemplazar líneas del plan en DRAFT (unión) | CamporeeSupplyPlansService.replaceDraft() | `src/camporee-supplies/plans.controller.ts` |
| POST | `/api/v1/camporees/:camporeeId/supply-plan/submit` | JWT | Permisos: camporee-supplies:plan | Enviar plan y emitir folio PRINCIPAL INS (local) | CamporeeSupplyPlansService.submit() | `src/camporee-supplies/plans.controller.ts` |
| POST | `/api/v1/union-camporees/:camporeeId/supply-plan/submit` | JWT | Permisos: camporee-supplies:plan | Enviar plan y emitir folio PRINCIPAL INS (unión) | CamporeeSupplyPlansService.submit() | `src/camporee-supplies/plans.controller.ts` |
| PATCH | `/api/v1/camporees/:camporeeId/supply-plan/lines` | JWT | Permisos (any): camporee-supplies:plan, review-pay, configure | Ajustar línea SUBMITTED; CHARGE/REFUND; bypass freeze con motivo | CamporeeSupplyPlansService.adjustLine() | `src/camporee-supplies/plans.controller.ts` |
| PATCH | `/api/v1/union-camporees/:camporeeId/supply-plan/lines` | JWT | Permisos (any): camporee-supplies:plan, review-pay, configure | Ajustar línea SUBMITTED (unión) | CamporeeSupplyPlansService.adjustLine() | `src/camporee-supplies/plans.controller.ts` |
| GET | `/api/v1/camporees/:camporeeId/supply-plans` | JWT | Permisos: camporee-supplies:read | Listar planes de insumos del camporee local | CamporeeSupplyPlansService.listPlans() | `src/camporee-supplies/plans.controller.ts` |
| GET | `/api/v1/union-camporees/:camporeeId/supply-plans` | JWT | Permisos: camporee-supplies:read | Listar planes de insumos del camporee de unión | CamporeeSupplyPlansService.listPlans() | `src/camporee-supplies/plans.controller.ts` |
| POST | `/api/v1/camporees/:camporeeId/supply-lines/:lineId/deliveries` | JWT | Permisos: camporee-supplies:deliver | Entrega parcial a la sección (local) | CamporeeSupplyPlansService.deliver() | `src/camporee-supplies/plans.controller.ts` |
| POST | `/api/v1/union-camporees/:camporeeId/supply-lines/:lineId/deliveries` | JWT | Permisos: camporee-supplies:deliver | Entrega parcial a la sección (unión) | CamporeeSupplyPlansService.deliver() | `src/camporee-supplies/plans.controller.ts` |
| GET | `/api/v1/camporees/:camporeeId/supply-reports/kitchen` | JWT | Permisos: camporee-supplies:read | Demanda de cocina (opcional `?date=`) | CamporeeSupplyPlansService.kitchenReport() | `src/camporee-supplies/plans.controller.ts` |
| GET | `/api/v1/union-camporees/:camporeeId/supply-reports/kitchen` | JWT | Permisos: camporee-supplies:read | Demanda de cocina (unión) | CamporeeSupplyPlansService.kitchenReport() | `src/camporee-supplies/plans.controller.ts` |
| GET | `/api/v1/camporees/:camporeeId/supply-reports/cash` | JWT | Permisos: camporee-supplies:read | Totales de caja por sección (local) | CamporeeSupplyPlansService.cashReport() | `src/camporee-supplies/plans.controller.ts` |
| GET | `/api/v1/union-camporees/:camporeeId/supply-reports/cash` | JWT | Permisos: camporee-supplies:read | Totales de caja por sección (unión) | CamporeeSupplyPlansService.cashReport() | `src/camporee-supplies/plans.controller.ts` |
| POST | `/api/v1/camporee-supply-payments/:paymentId/mark-paid` | JWT | Permisos: camporee-supplies:review-pay | Marcar folio INS (principal, cargo o devolución) como pagado | CamporeeSupplyPlansService.markPaid() | `src/camporee-supplies/plans.controller.ts` |

### inventory

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/inventory/clubs/:clubId/inventory` | JWT | Permisos: inventory:read | Listar items del inventario de una instancia de club | InventoryService.findAllByClub() | `src/inventory/inventory.controller.ts` |
| GET | `/api/v1/inventory/inventory/:id` | JWT | Permisos: inventory:read | Obtener detalles de un item del inventario | InventoryService.findOne() | `src/inventory/inventory.controller.ts` |
| GET | `/api/v1/inventory/inventory/:inventoryId/history` | JWT | Permisos: inventory:read | Obtener historial de cambios de un item del inventario | InventoryService.getInventoryHistory() | `src/inventory/inventory.controller.ts` |
| POST | `/api/v1/inventory/clubs/:clubId/inventory` | JWT | Permisos: inventory:create | Agregar nuevo item al inventario | InventoryService.create() | `src/inventory/inventory.controller.ts` |
| PATCH | `/api/v1/inventory/inventory/:id` | JWT | Permisos: inventory:update | Actualizar un item del inventario | InventoryService.update() | `src/inventory/inventory.controller.ts` |
| POST | `/api/v1/inventory/inventory/:id/evidences` | JWT | Permisos: inventory:update | Subir foto de evidencia de un item de inventario | InventoryService.uploadEvidence() | `src/inventory/inventory.controller.ts` |
| DELETE | `/api/v1/inventory/inventory/:id` | JWT | Permisos: inventory:delete | Eliminar un item del inventario | InventoryService.delete() | `src/inventory/inventory.controller.ts` |
| GET | `/api/v1/inventory/catalogs/inventory-categories` | JWT | Permisos: inventory:read | Listar categorías de inventario (Redis TTL 1h) | InventoryService.findAllCategories() | `src/inventory/inventory.controller.ts` |

### investiture

Fase 8 (2026-10-09): la vía club → coordinación → campo está apagada en el código de la rama `feat/investiture-legacy-shutdown`, sin desplegar. Las 17 rutas marcadas «Retirada» responden HTTP 410 con el código estable `INVESTITURE_LEGACY_PIPELINE_RETIRED`, sin exigir permisos ni roles (solo el JWT global): ningún actor recibe un 403 que oculte el 410. Incluye las lecturas `GET /investiture/pending` y `GET /admin/investiture/config*`. Siguen vivos el historial (`GET /investiture/enrollments/:enrollmentId/history` y su alias), `expire-overdue` y el desbloqueo de abajo. Los 17 handlers están en `LegacyInvestitureRetiredController`; no leen cuerpo ni parámetros. El `message` sale del catálogo de errores del idioma de la petición; una app o un panel viejos que no mandan `Accept-Language` lo reciben en español. El inventario histórico y el tratamiento de cada expediente están en `docs/features/validacion-investiduras.md`, sección «Fase 8 — apagado». Los permisos `investiture:submit`, `investiture:validate`, `investiture:mark_invested` e `investiture_config:*` quedan inertes (siguen en seeds y base). `investiture:read` sigue en uso: lo exigen las dos lecturas del historial. Nada está desplegado, las migraciones `20261008120000` y `20261009120000` no están aplicadas en Neon y el desbloqueo no se ejecutó en ningún entorno.

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/investiture/enrollments/:enrollmentId/submit` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Enviar a la validación anterior. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.submit() | `src/investiture/legacy-investiture-retired.controller.ts` |
| POST | `/api/v1/investiture/enrollments/:enrollmentId/club-approve` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Aprobación del club. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.clubApprove() | `src/investiture/legacy-investiture-retired.controller.ts` |
| POST | `/api/v1/investiture/enrollments/:enrollmentId/coordinator-approve` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Aprobación de coordinación. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.coordinatorApprove() | `src/investiture/legacy-investiture-retired.controller.ts` |
| POST | `/api/v1/investiture/enrollments/:enrollmentId/field-approve` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Aprobación del Campo. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.fieldApprove() | `src/investiture/legacy-investiture-retired.controller.ts` |
| POST | `/api/v1/investiture/enrollments/:enrollmentId/invest` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Investir por la vía anterior. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.invest() | `src/investiture/legacy-investiture-retired.controller.ts` |
| POST | `/api/v1/investiture/enrollments/:enrollmentId/reject` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Rechazar en la vía anterior. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.reject() | `src/investiture/legacy-investiture-retired.controller.ts` |
| POST | `/api/v1/investiture/enrollments/bulk-approve` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Aprobación en bloque. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.bulkApprove() | `src/investiture/legacy-investiture-retired.controller.ts` |
| POST | `/api/v1/investiture/enrollments/bulk-reject` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Rechazo en bloque. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.bulkReject() | `src/investiture/legacy-investiture-retired.controller.ts` |
| POST | `/api/v1/admin/classes/enrollments/expire-overdue` | JWT | Permisos: catalogs:update; Global: admin | Vencer manualmente enrollments atrasados por duración de clase | InvestitureService.expireOverdueEnrollments() | `src/investiture/investiture.controller.ts` |
| GET | `/api/v1/investiture/pending` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Pendientes de la vía anterior. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.pending() | `src/investiture/legacy-investiture-retired.controller.ts` |
| GET | `/api/v1/investiture/enrollments/:enrollmentId/history` | JWT | Permisos: investiture:read | Historial de validación de investidura de un enrollment | InvestitureService.getHistory() | `src/investiture/investiture.controller.ts` |
| POST | `/api/v1/enrollments/:enrollmentId/submit-for-validation` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Alias de envío a validación. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.submitForValidationAlias() | `src/investiture/legacy-investiture-retired.controller.ts` |
| POST | `/api/v1/enrollments/:enrollmentId/validate` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Alias de validación. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.validateAlias() | `src/investiture/legacy-investiture-retired.controller.ts` |
| POST | `/api/v1/enrollments/:enrollmentId/investiture` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Alias de investir. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.investitureAlias() | `src/investiture/legacy-investiture-retired.controller.ts` |
| GET | `/api/v1/enrollments/:enrollmentId/investiture-history` | JWT | Permisos: investiture:read | [LEGACY] Historial de validación de investidura de un enrollment | InvestitureService.getHistory() | `src/investiture/investiture.controller.ts` |
| POST | `/api/v1/admin/investiture/legacy-locks/release` | JWT | `super-admin` exacto, comprobado en el servicio (`ExactSuperAdminWritePolicy`); la ruta usa `@SkipPermissions`. Otro actor: 403 `SUPER_ADMIN_WRITE_REQUIRED` | Suelta `locked_for_validation` de los expedientes de la vía anterior sin cambiar su `investiture_status`. Cuerpo `{ "dry_run"?: boolean }`, por defecto `true` (solo lista); con `false` escribe. Responde 200 `{ "status": "success", "data": { "dry_run", "candidates": [], "skipped_pending": [], "released": [] } }`. Candidato: `enrollments` con `locked_for_validation` true, `record_kind` `OPERATIONAL` e `investiture_status` distinto de `INVESTIDO`, sin filtrar por `active` ni por el estado de la cadena. Un enrollment con una persona `PENDING` en `investiture_authorization_people` se omite y va a `skipped_pending`. Con `dry_run: false`, una transacción por enrollment bajo el candado `investiture-authorization-enrollment:`; cada liberado deja una fila `LEGACY_LOCK_RELEASED` en `investiture_validation_history` con el `super-admin` como `performed_by`. Idempotente: repetirlo no vuelve a liberar. Requiere la migración `20261009120000_investiture_legacy_lock_release_action` ya aplicada en ese entorno. No ejecutado en ningún entorno. | LegacyLockReleaseService.release() | `src/investiture/investiture.controller.ts` |
| GET | `/api/v1/admin/investiture/config` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Configuración de la investidura anterior. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.listConfigs() | `src/investiture/legacy-investiture-retired.controller.ts` |
| GET | `/api/v1/admin/investiture/config/:configId` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Configuración de la investidura anterior. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.getConfig() | `src/investiture/legacy-investiture-retired.controller.ts` |
| POST | `/api/v1/admin/investiture/config` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Configuración de la investidura anterior. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.createConfig() | `src/investiture/legacy-investiture-retired.controller.ts` |
| PATCH | `/api/v1/admin/investiture/config/:configId` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Configuración de la investidura anterior. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.updateConfig() | `src/investiture/legacy-investiture-retired.controller.ts` |
| DELETE | `/api/v1/admin/investiture/config/:configId` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Configuración de la investidura anterior. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.deleteConfig() | `src/investiture/legacy-investiture-retired.controller.ts` |

### legal-representatives

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/users/:userId/legal-representative` | JWT | - | Registrar representante legal (solo para menores de 18) | LegalRepresentativesService.create() | `src/legal-representatives/legal-representatives.controller.ts` |
| GET | `/api/v1/users/:userId/legal-representative` | JWT | - | Obtener representante legal del usuario | LegalRepresentativesService.findOne() | `src/legal-representatives/legal-representatives.controller.ts` |
| PATCH | `/api/v1/users/:userId/legal-representative` | JWT | - | Actualizar representante legal | LegalRepresentativesService.update() | `src/legal-representatives/legal-representatives.controller.ts` |
| DELETE | `/api/v1/users/:userId/legal-representative` | JWT | - | Eliminar representante legal | LegalRepresentativesService.remove() | `src/legal-representatives/legal-representatives.controller.ts` |

### Materials — Catalog

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/materials/catalog/categories` | JWT | Permisos: MATERIALS_READ | List all categories with active product count | CatalogService.listCategories() | `src/materials/catalog/catalog.controller.ts` |
| GET | `/api/v1/materials/catalog/programs` | JWT | Permisos: MATERIALS_READ | List all programs (club types) | CatalogService.listPrograms() | `src/materials/catalog/catalog.controller.ts` |
| GET | `/api/v1/materials/catalog` | JWT | Permisos: MATERIALS_READ | List products (paginated, filtered, scoped to LF) | CatalogService.list() | `src/materials/catalog/catalog.controller.ts` |
| GET | `/api/v1/materials/catalog/:id` | JWT | Permisos: MATERIALS_READ | Get product detail by ID | CatalogService.getById() | `src/materials/catalog/catalog.controller.ts` |

### Materials — Categories (admin)

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/materials/categories` | JWT | Permisos: MATERIALS_MANAGE_INVENTORY | List all material categories (admin view; includes inactive) | CategoriesService.list() | `src/materials/categories/categories.controller.ts` |
| POST | `/api/v1/materials/categories` | JWT | Permisos: MATERIALS_MANAGE_INVENTORY | Create a new material category | CategoriesService.create() | `src/materials/categories/categories.controller.ts` |
| PATCH | `/api/v1/materials/categories/:id` | JWT | Permisos: MATERIALS_MANAGE_INVENTORY | Update an existing category | CategoriesService.update() | `src/materials/categories/categories.controller.ts` |
| DELETE | `/api/v1/materials/categories/:id` | JWT | Permisos: MATERIALS_MANAGE_INVENTORY | Soft-delete a category (active=false). Blocked when products reference it. | CategoriesService.softDelete() | `src/materials/categories/categories.controller.ts` |

### Materials — Config

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/materials/config` | JWT | Permisos: MATERIALS_READ | Get the caller's local_field payment + delivery configuration | ConfigService.get() | `src/materials/config/config.controller.ts` |
| GET | `/api/v1/materials/config/all` | JWT | Permisos: MATERIALS_CONFIGURE | Lista config de materiales en el territorio del actor (todos los campos si es unscoped; unión/división/LF recortan) | ConfigService.listForScope() | `src/materials/config/config.controller.ts` |
| PATCH | `/api/v1/materials/config` | JWT | Permisos: MATERIALS_CONFIGURE | Upsert the materials configuration for a local_field (matches caller scope) | ConfigService.upsert() | `src/materials/config/config.controller.ts` |
| PATCH | `/api/v1/materials/config/:localFieldId` | JWT | Permisos: MATERIALS_CONFIGURE | Upsert config for a specific local_field (admin direct) | ConfigService.upsert() | `src/materials/config/config.controller.ts` |

### Materials — Inventory

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/materials/inventory` | JWT | Permisos: MATERIALS_MANAGE_INVENTORY | List products for the caller's local_field (admins can pass ?local_field_id=N) | InventoryService.list() | `src/materials/inventory/inventory.controller.ts` |
| POST | `/api/v1/materials/inventory` | JWT | Permisos: MATERIALS_MANAGE_INVENTORY | Create a product for the caller's local_field (admins can pass ?local_field_id=N) | InventoryService.create() | `src/materials/inventory/inventory.controller.ts` |
| PATCH | `/api/v1/materials/inventory/:id` | JWT | Permisos: MATERIALS_MANAGE_INVENTORY | Partially update a product | InventoryService.update() | `src/materials/inventory/inventory.controller.ts` |
| DELETE | `/api/v1/materials/inventory/:id` | JWT | Permisos: MATERIALS_MANAGE_INVENTORY | Soft-delete a product (sets active=false) | InventoryService.softDelete() | `src/materials/inventory/inventory.controller.ts` |
| PATCH | `/api/v1/materials/inventory/:id/variants/:variantId` | JWT | Permisos: MATERIALS_MANAGE_INVENTORY | Update stock for a specific variant option; recomputes product total stock | InventoryService.updateVariantStock() | `src/materials/inventory/inventory.controller.ts` |

### Materials — Orders

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/materials/orders` | JWT | Permisos: MATERIALS_CREATE | Create a new order | OrdersService.createOrder() | `src/materials/orders/orders.controller.ts` |
| GET | `/api/v1/materials/orders/history` | JWT | Permisos: MATERIALS_READ | Caller's own order history (always scoped to own orders) | OrdersService.historial() | `src/materials/orders/orders.controller.ts` |
| GET | `/api/v1/materials/orders` | JWT | Permisos: MATERIALS_READ | List orders (visibility + LF aware) | OrdersService.list() | `src/materials/orders/orders.controller.ts` |
| PATCH | `/api/v1/materials/orders/:folio/lines/:lineId` | JWT | Permisos: MATERIALS_APPROVE | Update line availability (campo local only, en_revision orders only) | OrdersService.patchLine() | `src/materials/orders/orders.controller.ts` |
| POST | `/api/v1/materials/orders/:folio/approve` | JWT | Permisos: MATERIALS_APPROVE | Approve order — allocate folio, decrement stock, snapshot config | OrdersService.approve() | `src/materials/orders/orders.controller.ts` |
| POST | `/api/v1/materials/orders/:folio/cancel` | JWT | Permisos: MATERIALS_READ | Cancel order — allowed from en_revision (own or campo), aprobada, pagada (campo only) | OrdersService.cancel() | `src/materials/orders/orders.controller.ts` |
| POST | `/api/v1/materials/orders/:folio/deliver` | JWT | Permisos: MATERIALS_DELIVER | Mark order as delivered — terminal transition (pagada → entregada) | OrdersService.deliver() | `src/materials/orders/orders.controller.ts` |
| GET | `/api/v1/materials/orders/:folio` | JWT | Permisos: MATERIALS_READ | Get full order detail by folio | OrdersService.getByFolio() | `src/materials/orders/orders.controller.ts` |

### Materials — Receipts

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/materials/receipts/:folio` | JWT | Permisos: MATERIALS_UPLOAD_RECEIPT | Upload payment receipt for an approved order | ReceiptsService.upload() | `src/materials/receipts/receipts.controller.ts` |
| POST | `/api/v1/materials/receipts/:folio/approve` | JWT | Permisos: MATERIALS_VALIDATE_RECEIPT | Approve a pending receipt — transitions order to pagada | ReceiptsService.approve() | `src/materials/receipts/receipts.controller.ts` |
| POST | `/api/v1/materials/receipts/:folio/reject` | JWT | Permisos: MATERIALS_VALIDATE_RECEIPT | Reject a pending receipt — order remains in aprobada | ReceiptsService.reject() | `src/materials/receipts/receipts.controller.ts` |
| GET | `/api/v1/materials/receipts/:folio` | JWT | Permisos: MATERIALS_READ | List all receipts for an order (with signed read URLs) | ReceiptsService.list() | `src/materials/receipts/receipts.controller.ts` |

### member-of-month

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/member-of-month/admin/list` | JWT | Permisos: mom:supervise. Coordinator: `club_section_ids` (ignora `local_field_id`). | Listar miembro del mes multi-sección (admin/coordinator por asignaciones) | MemberOfMonthService.listForAdmin() | `src/member-of-month/member-of-month.controller.ts` |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId/member-of-month` | JWT | Permisos: mom:read | Obtener miembro del mes actual de la sección | MemberOfMonthService.getCurrentMemberOfMonth() | `src/member-of-month/member-of-month.controller.ts` |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId/member-of-month/history` | JWT | Permisos: mom:read | Obtener historial paginado de miembro del mes | MemberOfMonthService.getMemberOfMonthHistory() | `src/member-of-month/member-of-month.controller.ts` |
| POST | `/api/v1/clubs/:clubId/sections/:sectionId/member-of-month/evaluate` | JWT | Permisos: mom:evaluate | Disparar evaluación manual de miembro del mes | MemberOfMonthService.evaluateMemberOfMonth() | `src/member-of-month/member-of-month.controller.ts` |

### annual-membership

> **Inscripción anual de miembros** — la directiva de la sección destino inscribe a no inscritos del **año vigente**. No copia cargos. D01 bloquea autoactivación del titular.
> POST crea matrícula de clase en la misma transacción (`NextClassResolver` + `ClassEnrollmentPolicyService` modo `annual` + `ClassEnrollmentWriter`). No usa `ClassesService.enrollUser`. GET une no inscritos locales con graduados de tipo (R14: última clase AV/CQ cursada, edad al inicio del año destino, sección destino activa). Salto AV→CQ / CQ→GM: `NextClassResolver` `crossed_type: true` e inscripción en la sección destino del POST; si el resolver apunta a otra sección, `blocked`. Catálogo incompleto, edad insuficiente o sin sección destino: `blocked` `ANNUAL_CLASS_POLICY_UNRESOLVED`. Última clase Guía Mayor: `path_complete`, membresía activa y sin inscripción nueva. Clases GM con `max_duration_years > 1` siguen abiertas (no es este salto). El DTO de resultado no expone `crossed_type`.

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/club-sections/:sectionId/annual-continuations` | JWT | Permisos: club_members:approve · `@AuthorizationResource` club_section | Listar no inscritos de la pertenencia de esa sección en el año vigente **y** candidatos de salto de tipo hacia esta sección (última AV→CQ o última CQ→GM, R14). Query: `page`, `limit`, `search`. Respuesta paginada: `{ user_id, name, base_section_id, ecclesiastical_year_id, annual_status, current_role, eligibility, blocked_reason, suggested_class }`. `suggested_class`: `{ status: 'resolved', class_id }`, `{ status: 'complete' }` cuando Guía Mayor ya es la última clase, o `{ status: 'blocked', code }` (p. ej. `ANNUAL_CLASS_POLICY_UNRESOLVED`). El alta responde `path_complete` sin `enrollment_id` nuevo. No lista exclusiva del año pasado. No filtra elegibilidad por `active=true` de cargos históricos. Directivo AV/CQ que retorna a GM (R04) no aparece aquí como graduado de tipo. | AnnualMembershipService.listContinuations() | `src/annual-membership/annual-continuations.controller.ts` |
| POST | `/api/v1/club-sections/:sectionId/annual-continuations` | JWT | Permisos: club_members:approve · `@AuthorizationResource` club_section | Inscribir. Body: `{ user_ids: string[] }` 1–100 distintos. Activa `member inactive` del año actual en **esta** sección **o crea** `member` active en destino si el salto de tipo es aceptado y la base no coincide. Matricula la clase resuelta (secuencia en el mismo tipo o clase por edad en el tipo destino). Sin exigir investidura del predecesor. Idempotente `already_enrolled` si ya hay `member active` aquí (`enrollment_id` puede ser `null` en ese outcome). Un director operativo en otra sección no cuenta como inscrito aquí. Lote por usuario: `enrolled\|already_enrolled\|blocked\|failed`. `enrollment_id` en `enrolled`. Actor registrado. Dueño del perfil **no** autoriza este POST. | AnnualMembershipService.continueUsers() | `src/annual-membership/annual-continuations.controller.ts` |
| POST | `/api/v1/users/:userId/membership/annual-enroll` | JWT | Permisos: registration:complete · Owner bypass (guard) | **D01 pendiente.** Siempre **403** `ANNUAL_ENROLL_REQUIRES_DIRECTIVE`, sin efectos. No éxito engañoso ni `pending`. | AnnualMembershipService.annualEnroll() | `src/annual-membership/annual-enroll.controller.ts` |

### membership-requests

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/club-sections/:clubSectionId/membership-requests` | JWT | Permisos: club_members:approve | Listar solicitudes pendientes de membresía | MembershipRequestsService.listPending() | `src/membership-requests/membership-requests.controller.ts` |
| POST | `/api/v1/club-sections/:clubSectionId/membership-requests/:assignmentId/approve` | JWT | Permisos: club_members:approve | Aprobar solicitud de membresía | MembershipRequestsService.approve() | `src/membership-requests/membership-requests.controller.ts` |
| POST | `/api/v1/club-sections/:clubSectionId/membership-requests/:assignmentId/reject` | JWT | Permisos: club_members:approve | Rechazar solicitud de membresía | MembershipRequestsService.reject() | `src/membership-requests/membership-requests.controller.ts` |

### monthly-reports

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/monthly-reports/preview/:enrollmentId` | JWT | Permisos: reports:read | Vista previa del informe mensual | MonthlyReportsService.preview() | `src/monthly-reports/monthly-reports.controller.ts` |
| POST | `/api/v1/monthly-reports/:enrollmentId` | JWT | Permisos: reports:read | Obtener o crear borrador de informe mensual | MonthlyReportsService.getOrCreateDraft() | `src/monthly-reports/monthly-reports.controller.ts` |
| PATCH | `/api/v1/monthly-reports/:reportId/manual-data` | JWT | Permisos: reports:read | Actualizar datos manuales del informe | MonthlyReportsService.updateManualData() | `src/monthly-reports/monthly-reports.controller.ts` |
| POST | `/api/v1/monthly-reports/:reportId/generate` | JWT | Permisos: reports:read | Encola congelar snapshot + PDF (202). Poll GET :reportId hasta generated. | MonthlyReportsService.enqueueGenerate() | `src/monthly-reports/monthly-reports.controller.ts` |
| POST | `/api/v1/monthly-reports/:reportId/submit` | JWT | Permisos: reports:read | Enviar informe al campo | MonthlyReportsService.submit() | `src/monthly-reports/monthly-reports.controller.ts` |
| GET | `/api/v1/monthly-reports/enrollment/:enrollmentId` | JWT | Permisos: reports:read | Listar informes de una matrícula | MonthlyReportsService.listReports() | `src/monthly-reports/monthly-reports.controller.ts` |
| GET | `/api/v1/monthly-reports/:reportId/pdf` | JWT | Permisos: reports:download | Descargar PDF. Nombre: `informe-mensual-{club}-{tipo}-{mes}-{año}.pdf` | MonthlyReportsPdfService.generatePdf() | `src/monthly-reports/monthly-reports.controller.ts` |
| POST | `/api/v1/monthly-reports/:reportId/regenerate` | JWT | Permisos: reports:write | Encola rerender del PDF almacenado (202) | MonthlyReportsService.enqueueRegenerate() | `src/monthly-reports/monthly-reports.controller.ts` |
| GET | `/api/v1/monthly-reports/admin/list` | JWT | Permisos: reports:read | Listar reportes multi-club (admin/coordinator) | MonthlyReportsService.listForAdmin() | `src/monthly-reports/monthly-reports.controller.ts` |
| GET | `/api/v1/monthly-reports/:reportId` | JWT | Permisos: reports:read | Obtener informe mensual | MonthlyReportsService.getReport() | `src/monthly-reports/monthly-reports.controller.ts` |

### Notifications

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/notifications/send` | JWT | Permisos: notifications:send | Send notification to specific user | NotificationsService.sendToUser() | `src/notifications/notifications.controller.ts` |
| POST | `/api/v1/notifications/broadcast` | JWT | Permisos: notifications:broadcast | Send notification to all users | NotificationsService.broadcast() | `src/notifications/notifications.controller.ts` |
| POST | `/api/v1/notifications/club/:instanceType/:instanceId` | JWT | Permisos: notifications:club | Send notification to club members | NotificationsService.sendToClubMembers() | `src/notifications/notifications.controller.ts` |
| GET | `/api/v1/notifications/targets/club` | JWT | Permisos: notifications:club | Get authorized club notification targets for current actor | NotificationsService.getAuthorizedClubTargets() | `src/notifications/notifications.controller.ts` |
| GET | `/api/v1/notifications/history` | JWT | - | Get paginated notification history | NotificationsService.getNotificationHistory() | `src/notifications/notifications.controller.ts` |
| GET | `/api/v1/notifications/unread-count` | JWT | - | Get unread notification count for the current user | NotificationsService.getUnreadCount() | `src/notifications/notifications.controller.ts` |
| PATCH | `/api/v1/notifications/read-all` | JWT | - | Mark all unread notifications as read | NotificationsService.markAllDeliveriesRead() | `src/notifications/notifications.controller.ts` |
| PATCH | `/api/v1/notifications/:deliveryId/read` | JWT | - | Mark a single notification delivery as read | NotificationsService.markDeliveryRead() | `src/notifications/notifications.controller.ts` |
| GET | `/api/v1/notifications/preferences` | JWT | - | Get current user notification preferences | NotificationPreferencesService.getUserPreferences() | `src/notifications/notifications.controller.ts` |
| PUT | `/api/v1/notifications/preferences/:category` | JWT | - | Update notification preference for a category | NotificationPreferencesService.setPreference() | `src/notifications/notifications.controller.ts` |

### FCM Tokens

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/fcm-tokens` | JWT | - | Register FCM token | FcmTokensService.registerToken() | `src/notifications/notifications.controller.ts` |
| DELETE | `/api/v1/fcm-tokens/by-token` | JWT | - | Unregister FCM token by token string | FcmTokensService.unregisterToken() | `src/notifications/notifications.controller.ts` |
| DELETE | `/api/v1/fcm-tokens/:id` | JWT | - | Unregister FCM token by record ID | FcmTokensService.unregisterTokenById() | `src/notifications/notifications.controller.ts` |
| GET | `/api/v1/fcm-tokens` | JWT | - | Get current user FCM tokens | FcmTokensService.getUserTokens() | `src/notifications/notifications.controller.ts` |
| GET | `/api/v1/fcm-tokens/user/:userId` | JWT | Owner o global: admin, assistant-admin, super-admin. `coordinator` no es atajo. | Get FCM tokens by user ID (owner/admin only) | FcmTokensService.getUserTokens() | `src/notifications/notifications.controller.ts` |

### User Notification Preferences

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/users/me/notification-preferences` | JWT | - | Get notification preferences for the authenticated user | - | `src/notifications/user-notification-preferences.controller.ts` |
| PATCH | `/api/v1/users/me/notification-preferences` | JWT | - | Update notification preferences | NotificationPreferencesService.setPreference() | `src/notifications/user-notification-preferences.controller.ts` |
| POST | `/api/v1/users/me/fcm-tokens` | JWT | - | Register an FCM token for the authenticated user | FcmTokensService.registerToken() | `src/notifications/user-notification-preferences.controller.ts` |
| DELETE | `/api/v1/users/me/fcm-tokens/:tokenId` | JWT | - | Unregister an FCM token by record ID | FcmTokensService.unregisterTokenById() | `src/notifications/user-notification-preferences.controller.ts` |

### post-registration

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/users/:userId/post-registration/photo-status` | JWT | - | Verificar si el usuario tiene foto de perfil subida | PostRegistrationService.getPhotoStatus() | `src/post-registration/post-registration.controller.ts` |
| GET | `/api/v1/users/:userId/post-registration/status` | JWT | - | Obtener estado del post-registro | PostRegistrationService.getStatus() | `src/post-registration/post-registration.controller.ts` |
| POST | `/api/v1/users/:userId/post-registration/step-1/complete` | JWT | Permisos: registration:complete | Completar Paso 1: Foto de perfil | PostRegistrationService.completeStep1() | `src/post-registration/post-registration.controller.ts` |
| POST | `/api/v1/users/:userId/post-registration/step-2/complete` | JWT | Permisos: registration:complete | Completar Paso 2: Información personal | PostRegistrationService.completeStep2() | `src/post-registration/post-registration.controller.ts` |
| POST | `/api/v1/users/:userId/post-registration/step-3/complete` | JWT | Permisos: registration:complete | Completar Paso 3: Selección de club | PostRegistrationService.completeStep3() | `src/post-registration/post-registration.controller.ts` |
| POST | `/api/v1/users/:userId/post-registration/membership-request/cancel` | JWT | Permisos: registration:complete | Cancelar solicitud pendiente de membresía | PostRegistrationService.cancelPendingMembershipRequest() | `src/post-registration/post-registration.controller.ts` |

### qr

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/qr/member/token` | JWT | - | Issue a short-lived QR token for the authenticated member | QrService.generateMemberToken() | `src/qr/qr.controller.ts` |
| GET | `/api/v1/qr/me` | JWT | - | Get the authenticated user QR metadata | QrService.getMyQr() | `src/qr/qr.controller.ts` |
| GET | `/api/v1/qr/me/card` | JWT | - | Get the QR card payload for the authenticated user | QrService.getMyCard() | `src/qr/qr.controller.ts` |
| GET | `/api/v1/qr/me/card.pdf` | JWT | - | Generate a PDF version of the authenticated user QR card | QrService.generateMyCardPdf() | `src/qr/qr.controller.ts` |
| POST | `/api/v1/qr/validate` | JWT | Permisos: qr:validate | Validate a scanned QR token with the canonical QR contract | QrService.validateMemberQr() | `src/qr/qr.controller.ts` |
| POST | `/api/v1/qr/scan` | JWT | Permisos: attendance:manage | Legacy alias for QR validation + attendance capture | QrService.scanMemberToken() | `src/qr/qr.controller.ts` |

`GET /qr/me/card` incluye en `member` el campo local (`local_field_name`), la unión (`union_name`) y el año eclesiástico vigente (`ecclesiastical_year`, año calendario en `America/Mexico_City`). Ese año es la vigencia de la credencial. `expires_at` sigue siendo solo la caducidad del token QR.

### quarterly-reports

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/quarterly-reports` | JWT | Permisos: reports:read | Listar informes trimestrales (admin) | QuarterlyReportsService.listForAdmin() | `src/quarterly-reports/quarterly-reports.controller.ts` |
| GET | `/api/v1/admin/quarterly-reports/:id` | JWT | Permisos: reports:read | Obtener informe trimestral por ID (admin) | QuarterlyReportsService.getReport() | `src/quarterly-reports/quarterly-reports.controller.ts` |
| PATCH | `/api/v1/admin/quarterly-reports/:id` | JWT | Permisos: reports:update | Actualizar datos manuales del informe trimestral (admin) | QuarterlyReportsService.updateManualData() | `src/quarterly-reports/quarterly-reports.controller.ts` |
| POST | `/api/v1/admin/quarterly-reports/:id/regenerate` | JWT | Permisos: reports:update | Regenerar datos calculados del informe trimestral (admin) | QuarterlyReportsService.regenerate() | `src/quarterly-reports/quarterly-reports.controller.ts` |
| POST | `/api/v1/admin/quarterly-reports/:id/finalize` | JWT | Permisos: reports:update | Finalizar informe trimestral (admin) | QuarterlyReportsService.finalize() | `src/quarterly-reports/quarterly-reports.controller.ts` |
| GET | `/api/v1/admin/quarterly-reports/:id/pdf` | JWT | Permisos: reports:download | Descargar PDF trimestral. Nombre: `informe-trimestral-{club}-{tipo}-{trimestre}-{año}.pdf` | QuarterlyReportsPdfService.generatePdf() | `src/quarterly-reports/quarterly-reports.controller.ts` |
| GET | `/api/v1/clubs/:clubId/quarterly-reports` | JWT | Permisos: reports:read | Listar informes trimestrales de un club (usuario) | QuarterlyReportsService.listForClub() | `src/quarterly-reports/quarterly-reports.controller.ts` |
| GET | `/api/v1/clubs/:clubId/quarterly-reports/:id` | JWT | Permisos: reports:read | Obtener informe trimestral por ID (usuario) | QuarterlyReportsService.getReport() | `src/quarterly-reports/quarterly-reports.controller.ts` |
| GET | `/api/v1/clubs/:clubId/quarterly-reports/:id/pdf` | JWT | Permisos: reports:download | Descargar PDF trimestral. Nombre: `informe-trimestral-{club}-{tipo}-{trimestre}-{año}.pdf` | QuarterlyReportsPdfService.generatePdf() | `src/quarterly-reports/quarterly-reports.controller.ts` |

### Ranking Weights

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/ranking-weights` | JWT | Permisos: ranking_weights:read | List all ranking weight configs | RankingWeightsService.list() | `src/ranking-weights/ranking-weights.controller.ts` |
| GET | `/api/v1/ranking-weights/:id` | JWT | Permisos: ranking_weights:read | Get a single ranking weight config by UUID | RankingWeightsService.getById() | `src/ranking-weights/ranking-weights.controller.ts` |
| POST | `/api/v1/ranking-weights` | JWT | Permisos: ranking_weights:write | Create a club-type ranking weight override | RankingWeightsService.create() | `src/ranking-weights/ranking-weights.controller.ts` |
| PATCH | `/api/v1/ranking-weights/:id` | JWT | Permisos: ranking_weights:write | Partially update a ranking weight config | RankingWeightsService.update() | `src/ranking-weights/ranking-weights.controller.ts` |
| DELETE | `/api/v1/ranking-weights/:id` | JWT | Permisos: ranking_weights:write | Delete a ranking weight override | RankingWeightsService.delete() | `src/ranking-weights/ranking-weights.controller.ts` |

### Annual Ranking Configs

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/annual-ranking-configs` | JWT | Permisos: ranking_weights:read | List annual ranking point budgets | AnnualRankingConfigService.list() | `src/rankings/annual-ranking-progress/annual-ranking-config.controller.ts` |
| POST | `/api/v1/annual-ranking-configs` | JWT | Permisos: ranking_weights:write | Create an annual ranking point budget | AnnualRankingConfigService.create() | `src/rankings/annual-ranking-progress/annual-ranking-config.controller.ts` |
| PATCH | `/api/v1/annual-ranking-configs/:id` | JWT | Permisos: ranking_weights:write | Update an annual ranking point budget | AnnualRankingConfigService.update() | `src/rankings/annual-ranking-progress/annual-ranking-config.controller.ts` |
| DELETE | `/api/v1/annual-ranking-configs/:id` | JWT | Permisos: ranking_weights:write | Deactivate an annual ranking point budget | AnnualRankingConfigService.deactivate() | `src/rankings/annual-ranking-progress/annual-ranking-config.controller.ts` |

### Annual Ranking Progress

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/club-sections/:sectionId/annual-ranking-progress` | JWT | Permisos: rankings:read, rankings:read_lf, rankings:read_global, section_rankings:read_club, section_rankings:read_lf, section_rankings:read_global (any) | Get annual ranking progress for one club section | AnnualRankingProgressService.getSectionProgress() | `src/rankings/annual-ranking-progress/annual-ranking-progress.controller.ts` |

### Annual Rankings

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/annual-rankings` | JWT | Permisos: rankings:read | List annual club rankings for administration | AnnualRankingsService.getLeaderboard() | `src/rankings/annual-ranking-progress/annual-rankings.controller.ts` |

### Ranking Tiers

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/ranking-tiers` | JWT | Permisos: ranking_weights:read | List active ranking recognition tiers | RankingTiersService.listActive() | `src/rankings/annual-ranking-progress/ranking-tiers.controller.ts` |
| PATCH | `/api/v1/ranking-tiers/:id` | JWT | Permisos: ranking_weights:write | Update a ranking recognition tier | RankingTiersService.update() | `src/rankings/annual-ranking-progress/ranking-tiers.controller.ts` |

### Member Ranking Weights

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/member-ranking-weights` | JWT | Global: admin, super-admin; Permisos: member_ranking_weights:read | List all ranking weight configurations (admin) | MemberRankingWeightsService.list() | `src/rankings/member-ranking-weights/member-ranking-weights.controller.ts` |
| POST | `/api/v1/member-ranking-weights` | JWT | Global: admin, super-admin; Permisos: member_ranking_weights:write | Create a ranking weight configuration (admin) | MemberRankingWeightsService.create() | `src/rankings/member-ranking-weights/member-ranking-weights.controller.ts` |
| GET | `/api/v1/member-ranking-weights/:id` | JWT | Global: admin, super-admin; Permisos: member_ranking_weights:read | Get a ranking weight configuration by ID (admin) | MemberRankingWeightsService.findOne() | `src/rankings/member-ranking-weights/member-ranking-weights.controller.ts` |
| PATCH | `/api/v1/member-ranking-weights/:id` | JWT | Global: admin, super-admin; Permisos: member_ranking_weights:write | Update a ranking weight configuration (admin) | MemberRankingWeightsService.update() | `src/rankings/member-ranking-weights/member-ranking-weights.controller.ts` |
| DELETE | `/api/v1/member-ranking-weights/:id` | JWT | Global: admin, super-admin; Permisos: member_ranking_weights:write | Delete a ranking weight configuration (admin) | MemberRankingWeightsService.remove() | `src/rankings/member-ranking-weights/member-ranking-weights.controller.ts` |

### Member Rankings

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/member-rankings/me` | JWT | Permisos: member_rankings:read_self | Get the calling member own ranking | MemberRankingsService.getMyRanking() | `src/rankings/member-rankings/member-rankings.controller.ts` |
| POST | `/api/v1/member-rankings/recalculate` | JWT | Permisos: member_ranking_weights:write | Encola recálculo member + section (y club). Responde al encolar. | MemberRankingsService.triggerRecalculate() | `src/rankings/member-rankings/member-rankings.controller.ts` |
| GET | `/api/v1/member-rankings/:enrollmentId/breakdown` | JWT | Permisos: member_rankings:read_self, member_rankings:read_section, member_rankings:read_club, member_rankings:read_lf, member_rankings:read_global (any) | Get score breakdown for a specific enrollment | MemberRankingsService.getBreakdown() | `src/rankings/member-rankings/member-rankings.controller.ts` |
| GET | `/api/v1/member-rankings` | JWT | Permisos: member_rankings:read_self, member_rankings:read_section, member_rankings:read_club, member_rankings:read_lf, member_rankings:read_global (any) | List member rankings (paginated, RBAC scope-filtered) | MemberRankingsService.list() | `src/rankings/member-rankings/member-rankings.controller.ts` |

### Section Rankings

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/section-rankings/:sectionId/members` | JWT | Permisos: section_rankings:read_club, section_rankings:read_lf, section_rankings:read_global (any) | Get members for a specific section ordered by rank_position ASC NULLS LAST | SectionRankingsService.getMembers() | `src/rankings/section-rankings/section-rankings.controller.ts` |
| GET | `/api/v1/section-rankings` | JWT | Permisos: section_rankings:read_club, section_rankings:read_lf, section_rankings:read_global (any) | List section rankings (paginated, RBAC scope-filtered) | SectionRankingsService.list() | `src/rankings/section-rankings/section-rankings.controller.ts` |

### rbac

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/rbac/permissions` | JWT | Permisos: permissions:read | Listar todos los permisos | RbacService.listPermissions() | `src/rbac/rbac.controller.ts` |
| GET | `/api/v1/admin/rbac/permissions/:id` | JWT | Permisos: permissions:read | Obtener un permiso por ID | RbacService.getPermissionById() | `src/rbac/rbac.controller.ts` |
| POST | `/api/v1/admin/rbac/permissions` | JWT | Global: super-admin; Permisos: permissions:assign | Crear un nuevo permiso | RbacService.createPermission() | `src/rbac/rbac.controller.ts` |
| PATCH | `/api/v1/admin/rbac/permissions/:id` | JWT | Global: super-admin; Permisos: permissions:assign | Actualizar un permiso | RbacService.updatePermission() | `src/rbac/rbac.controller.ts` |
| DELETE | `/api/v1/admin/rbac/permissions/:id` | JWT | Global: super-admin; Permisos: permissions:assign | Desactivar un permiso | RbacService.deletePermission() | `src/rbac/rbac.controller.ts` |
| GET | `/api/v1/admin/rbac/roles` | JWT | Permisos: roles:read | Listar roles con sus permisos | RbacService.listRoles() | `src/rbac/rbac.controller.ts` |
| GET | `/api/v1/admin/rbac/roles/:id` | JWT | Permisos: roles:read | Obtener rol con sus permisos | RbacService.getRoleWithPermissions() | `src/rbac/rbac.controller.ts` |
| POST | `/api/v1/admin/rbac/roles` | JWT | Global: super-admin | Crear un nuevo rol | RbacService.createRole() | `src/rbac/rbac.controller.ts` |
| PATCH | `/api/v1/admin/rbac/roles/:id` | JWT | Global: super-admin | Actualizar descripción y/o permisos de un rol | RbacService.updateRole() | `src/rbac/rbac.controller.ts` |
| DELETE | `/api/v1/admin/rbac/roles/:id` | JWT | Global: super-admin | Desactivar (soft delete) un rol | RbacService.deactivateRole() | `src/rbac/rbac.controller.ts` |
| POST | `/api/v1/admin/rbac/roles/:id/permissions` | JWT | Global: super-admin; Permisos: permissions:assign | Asignar permisos a un rol | RbacService.assignPermissionsToRole() | `src/rbac/rbac.controller.ts` |
| PUT | `/api/v1/admin/rbac/roles/:id/permissions` | JWT | Global: super-admin; Permisos: permissions:assign | Sincronizar permisos de un rol (reemplaza todos) | RbacService.syncRolePermissions() | `src/rbac/rbac.controller.ts` |
| DELETE | `/api/v1/admin/rbac/roles/:id/permissions/:permissionId` | JWT | Global: super-admin; Permisos: permissions:assign | Remover un permiso de un rol | RbacService.removePermissionFromRole() | `src/rbac/rbac.controller.ts` |
| GET | `/api/v1/admin/rbac/users/:userId/permissions` | JWT | Permisos: permissions:read | Listar permisos directos de un usuario | RbacService.getUserPermissions() | `src/rbac/rbac.controller.ts` |
| POST | `/api/v1/admin/rbac/users/:userId/permissions` | JWT | Global: super-admin; Permisos: permissions:assign | Asignar un permiso directo a un usuario | RbacService.assignPermissionToUser() | `src/rbac/rbac.controller.ts` |
| DELETE | `/api/v1/admin/rbac/users/:userId/permissions/:permissionId` | JWT | Global: super-admin; Permisos: permissions:assign | Remover un permiso directo de un usuario | RbacService.removePermissionFromUser() | `src/rbac/rbac.controller.ts` |
| GET | `/api/v1/admin/rbac/users/:userId/roles` | JWT | Global: admin, super-admin | Listar roles asignados a un usuario | RbacService.getUserRoles() | `src/rbac/rbac.controller.ts` |
| POST | `/api/v1/admin/rbac/users/:userId/roles` | JWT | Global: admin, super-admin | Asignar un rol a un usuario | RbacService.assignRoleToUser() | `src/rbac/rbac.controller.ts` |
| DELETE | `/api/v1/admin/rbac/users/:userId/roles/:roleId` | JWT | Global: admin, super-admin | Remover un rol de un usuario | RbacService.removeRoleFromUser() | `src/rbac/rbac.controller.ts` |

### rbac-bootstrap

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/admin/rbac/bootstrap-admin` | Public | - | Crear el primer super-admin (solo funciona si no existe ninguno) | ConfigService.get(), RbacService.bootstrapAdmin() | `src/rbac/rbac.controller.ts` |

### requests

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/requests/transfers` | JWT | Permisos: requests:read | Crear solicitud de transferencia | RequestsService.createTransferRequest() | `src/requests/requests.controller.ts` |
| GET | `/api/v1/requests/transfers` | JWT | Permisos: requests:read | Listar solicitudes de transferencia | RequestsService.getTransferRequests() | `src/requests/requests.controller.ts` |
| GET | `/api/v1/requests/transfers/:requestId` | JWT | Permisos: requests:read | Obtener solicitud de transferencia | RequestsService.getTransferRequest() | `src/requests/requests.controller.ts` |
| POST | `/api/v1/requests/transfers/:requestId/review` | JWT | Permisos: requests:review | Revisar solicitud de transferencia | RequestsService.reviewTransfer() | `src/requests/requests.controller.ts` |
| POST | `/api/v1/requests/assignments` | JWT | Permisos: requests:review | Crear solicitud de asignación de rol | RequestsService.createAssignmentRequest() | `src/requests/requests.controller.ts` |
| GET | `/api/v1/requests/assignments` | JWT | Permisos: requests:read | Listar solicitudes de asignación de rol | RequestsService.getAssignmentRequests() | `src/requests/requests.controller.ts` |
| GET | `/api/v1/requests/assignments/:requestId` | JWT | Permisos: requests:read | Obtener solicitud de asignación de rol | RequestsService.getAssignmentRequest() | `src/requests/requests.controller.ts` |
| POST | `/api/v1/requests/assignments/:requestId/review` | JWT | Permisos: requests:review | Revisar solicitud de asignación de rol | RequestsService.reviewAssignment() | `src/requests/requests.controller.ts` |

### resource-categories

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/resource-categories` | JWT | Permisos: resource_categories:create | Crear categoría de recurso | ResourceCategoriesService.create() | `src/resources/resource-categories.controller.ts` |
| GET | `/api/v1/resource-categories` | JWT | Permisos: resource_categories:read | Listar categorías de recursos activas (Redis TTL 1h) | ResourceCategoriesService.findAll() | `src/resources/resource-categories.controller.ts` |
| GET | `/api/v1/resource-categories/:id` | JWT | Permisos: resource_categories:read | Obtener categoría de recurso por ID | ResourceCategoriesService.findOne() | `src/resources/resource-categories.controller.ts` |
| PATCH | `/api/v1/resource-categories/:id` | JWT | Permisos: resource_categories:update | Actualizar categoría de recurso | ResourceCategoriesService.update() | `src/resources/resource-categories.controller.ts` |
| DELETE | `/api/v1/resource-categories/:id` | JWT | Permisos: resource_categories:delete | Desactivar categoría de recurso (soft delete) | ResourceCategoriesService.remove() | `src/resources/resource-categories.controller.ts` |

### Resources (App)

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/resources/me` | JWT | - | Mis recursos | AuthorizationContextService.resolveUserAuthorization(), ResourcesService.getVisibleResources() | `src/resources/resources-app.controller.ts` |
| GET | `/api/v1/resources/me/:id` | JWT | - | Obtener recurso visible | AuthorizationContextService.resolveUserAuthorization(), ResourcesService.findOneVisible() | `src/resources/resources-app.controller.ts` |
| GET | `/api/v1/resources/me/:id/signed-url` | JWT | - | Obtener URL firmada (app) | AuthorizationContextService.resolveUserAuthorization(), ResourcesService.getVisibleSignedUrl() | `src/resources/resources-app.controller.ts` |

### Resources

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/resources` | JWT | Permisos: resources:create | Crear recurso | ResourcesService.create() | `src/resources/resources.controller.ts` |
| POST | `/api/v1/resources/upload-url` | JWT | Permisos: resources:create | Generar URL firmada para subir un recurso directo a R2 | ResourcesService.generateUploadUrl() | `src/resources/resources.controller.ts` |
| POST | `/api/v1/resources/from-uploaded` | JWT | Permisos: resources:create | Crear recurso desde archivo ya subido a R2 (presigned flow) | ResourcesService.createFromUploaded() | `src/resources/resources.controller.ts` |
| GET | `/api/v1/resources` | JWT | Permisos: resources:read | Listar recursos | ResourcesService.findAll() | `src/resources/resources.controller.ts` |
| GET | `/api/v1/resources/:id` | JWT | Permisos: resources:read | Obtener recurso | ResourcesService.findOne() | `src/resources/resources.controller.ts` |
| GET | `/api/v1/resources/:id/signed-url` | JWT | Permisos: resources:read | Obtener URL firmada | ResourcesService.getSignedUrl() | `src/resources/resources.controller.ts` |
| PATCH | `/api/v1/resources/:id` | JWT | Permisos: resources:update | Actualizar recurso | ResourcesService.update() | `src/resources/resources.controller.ts` |
| DELETE | `/api/v1/resources/:id` | JWT | Permisos: resources:delete | Eliminar recurso | ResourcesService.remove() | `src/resources/resources.controller.ts` |

### scoring-categories

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/divisions/scoring-categories` | JWT | Permisos: scoring_categories:read; Global: admin, super-admin | Listar categorías de puntuación a nivel división | ScoringCategoriesService.findDivisionCategories() | `src/scoring-categories/scoring-categories.controller.ts` |
| POST | `/api/v1/divisions/scoring-categories` | JWT | Permisos: scoring_categories:manage; Global: admin, super-admin | Crear categoría de puntuación a nivel división | ScoringCategoriesService.createDivisionCategory() | `src/scoring-categories/scoring-categories.controller.ts` |
| PATCH | `/api/v1/divisions/scoring-categories/:id` | JWT | Permisos: scoring_categories:manage; Global: admin, super-admin | Actualizar categoría de puntuación a nivel división | ScoringCategoriesService.updateDivisionCategory() | `src/scoring-categories/scoring-categories.controller.ts` |
| DELETE | `/api/v1/divisions/scoring-categories/:id` | JWT | Permisos: scoring_categories:manage; Global: admin, super-admin | Desactivar categoría de puntuación a nivel división (soft delete) | ScoringCategoriesService.deleteDivisionCategory() | `src/scoring-categories/scoring-categories.controller.ts` |
| GET | `/api/v1/unions/:unionId/scoring-categories` | JWT | Permisos: scoring_categories:read | Listar categorías de puntuación para una unión (heredadas + propias) | ScoringCategoriesService.findUnionCategories() | `src/scoring-categories/scoring-categories.controller.ts` |
| POST | `/api/v1/unions/:unionId/scoring-categories` | JWT | Permisos: scoring_categories:manage | Crear categoría de puntuación para una unión | ScoringCategoriesService.createUnionCategory() | `src/scoring-categories/scoring-categories.controller.ts` |
| PATCH | `/api/v1/unions/:unionId/scoring-categories/:id` | JWT | Permisos: scoring_categories:manage | Actualizar categoría de puntuación propia de una unión | ScoringCategoriesService.updateUnionCategory() | `src/scoring-categories/scoring-categories.controller.ts` |
| DELETE | `/api/v1/unions/:unionId/scoring-categories/:id` | JWT | Permisos: scoring_categories:manage | Desactivar categoría de puntuación propia de una unión (soft delete) | ScoringCategoriesService.deleteUnionCategory() | `src/scoring-categories/scoring-categories.controller.ts` |
| GET | `/api/v1/local-fields/:fieldId/scoring-categories` | JWT | Permisos: scoring_categories:read | Listar categorías de puntuación activas para un campo local (división + unión + propias) | ScoringCategoriesService.findLocalFieldCategories() | `src/scoring-categories/scoring-categories.controller.ts` |
| POST | `/api/v1/local-fields/:fieldId/scoring-categories` | JWT | Permisos: scoring_categories:manage | Crear categoría de puntuación para un campo local | ScoringCategoriesService.createLocalFieldCategory() | `src/scoring-categories/scoring-categories.controller.ts` |
| PATCH | `/api/v1/local-fields/:fieldId/scoring-categories/:id` | JWT | Permisos: scoring_categories:manage | Actualizar categoría de puntuación propia de un campo local | ScoringCategoriesService.updateLocalFieldCategory() | `src/scoring-categories/scoring-categories.controller.ts` |
| DELETE | `/api/v1/local-fields/:fieldId/scoring-categories/:id` | JWT | Permisos: scoring_categories:manage | Desactivar categoría de puntuación propia de un campo local (soft delete) | ScoringCategoriesService.deleteLocalFieldCategory() | `src/scoring-categories/scoring-categories.controller.ts` |

### admin-support

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/support/reports` | JWT | Global: admin, coordinator (alias: zone/general + director-lf/assistant-lf; LF recorta a local_field) | Listar reportes de soporte | SupportService.listReports() | `src/support/support-admin.controller.ts` |
| GET | `/api/v1/admin/support/reports/:reportId` | JWT | Global: admin, coordinator (alias: zone/general + director-lf/assistant-lf; LF recorta a local_field) | Obtener detalle de un reporte de soporte | SupportService.getReport() | `src/support/support-admin.controller.ts` |
| PATCH | `/api/v1/admin/support/reports/:reportId/status` | JWT | Global: admin, coordinator (alias: zone/general + director-lf/assistant-lf; LF recorta a local_field) | Actualizar estado de un reporte de soporte | SupportService.updateReportStatus() | `src/support/support-admin.controller.ts` |

### support

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/support/reports` | JWT | - | Create a new support report | SupportService.createReport() | `src/support/support.controller.ts` |

### system-config

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/system-config` | JWT | Global: admin, super-admin | Listar todas las configuraciones del sistema | SystemConfigService.findAll() | `src/system-config/system-config.controller.ts` |
| GET | `/api/v1/system-config/:key` | JWT | Global: admin, super-admin | Obtener una configuracion por clave | SystemConfigService.findByKey() | `src/system-config/system-config.controller.ts` |
| PATCH | `/api/v1/system-config/:key` | JWT | Global: admin, super-admin | Actualizar una configuracion del sistema | SystemConfigService.updateByKey() | `src/system-config/system-config.controller.ts` |

### units

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/clubs/:clubId/units` | JWT | Permisos: units:read | Listar unidades del club | UnitsService.findByClub() | `src/units/units.controller.ts` |
| POST | `/api/v1/clubs/:clubId/units` | JWT | Permisos: units:create | Crear unidad en el club | UnitsService.create() | `src/units/units.controller.ts` |
| GET | `/api/v1/clubs/:clubId/units/:unitId` | JWT | Permisos: units:read | Obtener detalle de una unidad con miembros | UnitsService.findOne() | `src/units/units.controller.ts` |
| PATCH | `/api/v1/clubs/:clubId/units/:unitId` | JWT | Permisos: units:update | Actualizar unidad | UnitsService.update() | `src/units/units.controller.ts` |
| DELETE | `/api/v1/clubs/:clubId/units/:unitId` | JWT | Permisos: units:delete | Desactivar unidad (soft delete) | UnitsService.remove() | `src/units/units.controller.ts` |
| POST | `/api/v1/clubs/:clubId/units/:unitId/members` | JWT | Permisos: units:update | Agregar miembro a la unidad | UnitsService.addMember() | `src/units/units.controller.ts` |
| DELETE | `/api/v1/clubs/:clubId/units/:unitId/members/:memberId` | JWT | Permisos: units:update | Remover miembro de la unidad (soft delete) | UnitsService.removeMember() | `src/units/units.controller.ts` |
| GET | `/api/v1/clubs/:clubId/units/:unitId/weekly-records` | JWT | Permisos: units:read | Listar registros semanales de la unidad | UnitsService.findWeeklyRecords() | `src/units/units.controller.ts` |
| POST | `/api/v1/clubs/:clubId/units/:unitId/weekly-records` | JWT | Permisos: units:update | Crear registro semanal (solo semana vigente domingo–sábado, hora México) | UnitsService.createWeeklyRecord() | `src/units/units.controller.ts` |
| POST | `/api/v1/clubs/:clubId/units/:unitId/weekly-records/bulk` | JWT | Permisos: units:update | Crear o actualizar registros semanales de forma atómica (semana vigente domingo–sábado, hora México) | UnitsService.bulkUpsertWeeklyRecords() | `src/units/units.controller.ts` |
| PATCH | `/api/v1/clubs/:clubId/units/:unitId/weekly-records/:recordId` | JWT | Permisos: units:update | Actualizar registro semanal (solo si pertenece a la semana vigente) | UnitsService.updateWeeklyRecord() | `src/units/units.controller.ts` |

### users

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/users/:userId` | JWT | Permisos: users:read_detail | Obtener información de un usuario | UsersService.findOne() | `src/users/users.controller.ts` |
| GET | `/api/v1/users/:userId/allergies` | JWT | - | Obtener alergias activas del usuario | UsersService.getAllergies() | `src/users/users.controller.ts` |
| GET | `/api/v1/users/:userId/diseases` | JWT | - | Obtener enfermedades activas del usuario | UsersService.getDiseases() | `src/users/users.controller.ts` |
| GET | `/api/v1/users/:userId/medicines` | JWT | - | Obtener medicamentos activos del usuario | UsersService.getMedicines() | `src/users/users.controller.ts` |
| PATCH | `/api/v1/users/:userId` | JWT | Permisos: users:update_profile | Actualizar información personal del usuario | UsersService.update() | `src/users/users.controller.ts` |
| PUT | `/api/v1/users/:userId/allergies` | JWT | - | Guardar alergias del usuario | UsersService.updateAllergies() | `src/users/users.controller.ts` |
| PUT | `/api/v1/users/:userId/diseases` | JWT | - | Guardar enfermedades del usuario | UsersService.updateDiseases() | `src/users/users.controller.ts` |
| PUT | `/api/v1/users/:userId/medicines` | JWT | - | Guardar medicamentos del usuario | UsersService.updateMedicines() | `src/users/users.controller.ts` |
| DELETE | `/api/v1/users/:userId/allergies/:allergyId` | JWT | - | Eliminar alergia del usuario (borrado lógico) | UsersService.removeAllergy() | `src/users/users.controller.ts` |
| DELETE | `/api/v1/users/:userId/diseases/:diseaseId` | JWT | - | Eliminar enfermedad del usuario (borrado lógico) | UsersService.removeDisease() | `src/users/users.controller.ts` |
| DELETE | `/api/v1/users/:userId/medicines/:medicineId` | JWT | - | Eliminar medicamento del usuario (borrado lógico) | UsersService.removeMedicine() | `src/users/users.controller.ts` |
| POST | `/api/v1/users/:userId/profile-picture` | JWT | Permisos: users:update_profile | Subir foto de perfil | UsersService.uploadProfilePicture() | `src/users/users.controller.ts` |
| DELETE | `/api/v1/users/:userId/profile-picture` | JWT | Permisos: users:update_profile | Eliminar foto de perfil | UsersService.deleteProfilePicture() | `src/users/users.controller.ts` |
| GET | `/api/v1/users/:userId/age` | JWT | Permisos: users:read_detail | Calcular edad del usuario | UsersService.calculateAge() | `src/users/users.controller.ts` |
| GET | `/api/v1/users/:userId/requires-legal-representative` | JWT | Permisos: users:read_detail | Verificar si el usuario requiere representante legal | UsersService.calculateAge(), UsersService.requiresLegalRepresentative() | `src/users/users.controller.ts` |

### validation

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/validation/submit` | JWT | Permisos: validation:submit | Enviar clase/honor a revision. Con `entity_type` `class`: 410 `INVESTITURE_LEGACY_PIPELINE_RETIRED` (fase 8) sin leer ni escribir. Sin el permiso `validation:submit` la respuesta es 403 antes que ese 410. El honor no cambia. | ValidationService.submitForReview() | `src/validation/validation.controller.ts` |
| POST | `/api/v1/validation/:entityType/:entityId/review` | JWT | Permisos: validation:review | Aprobar o rechazar clase/honor. Con `class`, aprobar o rechazar, con o sin comentario: 410 `INVESTITURE_LEGACY_PIPELINE_RETIRED` (fase 8), sin escribir. Sin el permiso `validation:review` la respuesta es 403 antes que ese 410. El honor no cambia. | ValidationService.review() | `src/validation/validation.controller.ts` |
| GET | `/api/v1/validation/pending` | JWT | Permisos: validation:read | Listar items pendientes de revision. Desde la fase 8 `classes` siempre es `[]`: solo salen honores. | ValidationService.getPendingReviews() | `src/validation/validation.controller.ts` |
| GET | `/api/v1/validation/:entityType/:entityId/history` | JWT | Permisos: validation:read | Historial de validacion | ValidationService.getValidationHistory() | `src/validation/validation.controller.ts` |
| GET | `/api/v1/validation/eligibility/:userId` | JWT | Permisos: validation:read | Verificar elegibilidad para investidura | ValidationService.checkInvestmentEligibility() | `src/validation/validation.controller.ts` |

### year-end

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/year-end/:yearId/preview` | JWT | Global: admin, super-admin; Permisos: ecclesiastical_years:update | Vista previa del impacto de cierre de ano | YearEndService.previewClosureImpact() | `src/year-end/year-end.controller.ts` |
| POST | `/api/v1/year-end/:yearId/close` | JWT | Global: admin, super-admin; Permisos: ecclesiastical_years:update | Cierra el año. Además de inscripciones de club, carpetas e informes, deja en `CLOSED_YEAR` los pendientes de investidura de ese año. Presentar y agregar toman el candado del año antes que el de la sección y vuelven a leer el año: si el cierre ya dejó el año inactivo, no queda `PENDING`; si la alta escribe mientras espera, este cierre la incluye. No cambia `INVESTED`, no copia la solicitud al año siguiente y no escribe el texto de falta de requisitos. Un año ya inactivo responde `YEAR_END_YEAR_CLOSED`. El conteo va en `investiturePendingClosed`. | YearEndService.closeYear() | `src/year-end/year-end.controller.ts` |

## Nota de mantenimiento

- Si cambia un controller, regenerar esta referencia contra `sacdia-backend/src/**/*controller.ts`.
- No confiar en conteos editoriales antiguos: el conteo vigente debe salir del mismo extractor que produce esta tabla.
