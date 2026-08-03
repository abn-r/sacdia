# ENDPOINTS LIVE REFERENCE (Runtime Truth)

<!-- Generado estáticamente contra sacdia-backend/src/**/*controller.ts el 2026-07-07. El contrato operations-dashboard se sincronizó manualmente contra el runtime final el 2026-07-15. No se levantó la app ni se ejecutó build. Los conteos agregados permanecen como snapshot del generador 2026-07-07. -->

> [!IMPORTANT]
> Documento canónico operativo para clientes SACDIA. Base URL: `/api/v1`.
> La tabla refleja los decoradores HTTP efectivos en controllers NestJS; DTOs, ejemplos y errores finos viven en Swagger/runtime y docs de feature cuando aplique.

**Estado**: ACTIVE
**Actualizado**: 2026-07-15
**Total endpoints**: 697 decoradores HTTP en 90 controllers
**Métodos**: GET 291 · POST 207 · PATCH 103 · DELETE 88 · PUT 8
**Auth detectada**: JWT 685 · Public 12

## Cómo leer esta referencia

- `Auth`: `JWT` cuando el controller/método declara `JwtAuthGuard`, `AuthGuard` o `ApiBearerAuth`; `Public` cuando no se detecta guard bearer en el controller/método.
- `Roles/Permisos`: combina `@RequirePermissions`, `@GlobalRoles`, `@ClubRoles` y `@Roles` detectados a nivel clase/método.
- `Uso`: sale de `@ApiOperation.summary` cuando existe; si no existe, se infiere desde el nombre del handler y el método HTTP.
- `Uso backend`: primeras llamadas a servicios/repositorios inyectados detectadas en el handler. `-` significa que el handler responde inline o usa lógica privada no capturada por esta extracción estática.
- `Source`: controller de origen para verificar el contrato antes de tocar clientes.

## Resumen por dominio

| Dominio/API tag | Endpoints |
| --- | ---: |
| Achievements | 4 |
| Admin - Achievements | 12 |
| activities | 8 |
| admin-auth | 6 |
| admin-camporee-event-types | 4 |
| admin | 2 |
| admin-geography | 24 |
| Admin - Honors Requirements | 7 |
| admin-notifications | 1 |
| Admin - Phase E Catalogs (i18n) | 29 |
| admin-reference | 38 |
| admin-users | 7 |
| analytics | 6 |
| Annual Evidence Folders | 13 |
| Annual Evidence Folders - Templates | 9 |
| Award Categories | 5 |
| Annual Evidence Folders - Evaluation | 5 |
| Annual Evidence Folders - Rankings | 4 |
| annual-reports | 9 |
| app.controller.ts | 1 |
| auth | 19 |
| OAuth | 5 |
| camporee-event-templates | 5 |
| camporee-events | 16 |
| camporee-scoring | 17 |
| camporee-staff | 8 |
| camporee-venues | 9 |
| camporees | 47 |
| catalogs | 16 |
| admin-certificate-bulk-imports | 6 |
| certificate-bulk-imports | 6 |
| certifications | 7 |
| class-counselor-assignments | 4 |
| class-progress-scope | 2 |
| classes | 3 |
| user-classes | 7 |
| club-enrollments | 7 |
| clubs | 16 |
| club-roles | 2 |
| admin-coordination | 8 |
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
| membership-requests | 3 |
| monthly-reports | 9 |
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
| POST | `/api/v1/clubs/:clubId/activities` | JWT | Permisos: activities:create; Club: director, deputy-director, secretary, counselor | Crear actividad | ActivitiesService.create() | `src/activities/activities.controller.ts` |
| GET | `/api/v1/activities/:activityId` | JWT | Permisos: activities:read | Obtener actividad por ID | ActivitiesService.findOne() | `src/activities/activities.controller.ts` |
| PATCH | `/api/v1/activities/:activityId` | JWT | Permisos: activities:update | Actualizar actividad | ActivitiesService.update() | `src/activities/activities.controller.ts` |
| DELETE | `/api/v1/activities/:activityId` | JWT | Permisos: activities:delete | Desactivar actividad | ActivitiesService.remove() | `src/activities/activities.controller.ts` |
| POST | `/api/v1/activities/:activityId/image` | JWT | Permisos: activities:update | Subir imagen de actividad | ActivitiesService.uploadImage() | `src/activities/activities.controller.ts` |
| POST | `/api/v1/activities/:activityId/attendance` | JWT | Permisos: attendance:manage | Registrar asistencia | ActivitiesService.recordAttendance() | `src/activities/activities.controller.ts` |
| GET | `/api/v1/activities/:activityId/attendance` | JWT | Permisos: attendance:read | Obtener asistencia | ActivitiesService.getAttendance() | `src/activities/activities.controller.ts` |

### admin-auth

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/users/:userId/sessions` | JWT | Global: admin, super-admin; Permisos: users:update_admin | List all active sessions for a user | AdminAuthService.listUserSessions() | `src/admin/admin-auth.controller.ts` |
| DELETE | `/api/v1/admin/users/:userId/sessions/:sessionId` | JWT | Global: admin, super-admin; Permisos: users:update_admin | Revoke a specific session for a user | AdminAuthService.revokeUserSession() | `src/admin/admin-auth.controller.ts` |
| DELETE | `/api/v1/admin/users/:userId/sessions` | JWT | Global: admin, super-admin; Permisos: users:update_admin | Revoke all sessions for a user | AdminAuthService.revokeAllUserSessions() | `src/admin/admin-auth.controller.ts` |
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

### Admin - Phase E Catalogs (i18n)

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/classes` | JWT | Global: admin, super-admin; Permisos: catalogs:read | List all classes with their full translations (admin editor) | AdminPhaseECatalogsService.findAllClasses() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| POST | `/api/v1/admin/classes` | JWT | Global: admin, super-admin; Permisos: catalogs:create | Create a class with optional translations | AdminPhaseECatalogsService.createClass() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| PATCH | `/api/v1/admin/classes/:id` | JWT | Global: admin, super-admin; Permisos: catalogs:update | Update a class and upsert/delete translations | AdminPhaseECatalogsService.updateClass() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| DELETE | `/api/v1/admin/classes/:id` | JWT | Global: admin, super-admin; Permisos: catalogs:delete | Soft-delete a class (active = false) | AdminPhaseECatalogsService.deleteClass() | `src/admin/admin-phase-e-catalogs.controller.ts` |
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
| POST | `/api/v1/admin/catalogs/cache/invalidate` | JWT | Global: admin, super-admin; Permisos: catalogs:update | Invalidate all catalog caches | CatalogCacheService.invalidateAll() | `src/admin/admin-reference.controller.ts` |
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
| POST | `/api/v1/admin/ecclesiastical-years` | JWT | Global: admin, super-admin; Permisos: ecclesiastical_years:create | Create ecclesiastical year | AdminReferenceService.createEcclesiasticalYear() | `src/admin/admin-reference.controller.ts` |
| PATCH | `/api/v1/admin/ecclesiastical-years/:yearId` | JWT | Global: admin, super-admin; Permisos: ecclesiastical_years:update | Update ecclesiastical year | AdminReferenceService.updateEcclesiasticalYear() | `src/admin/admin-reference.controller.ts` |
| DELETE | `/api/v1/admin/ecclesiastical-years/:yearId` | JWT | Global: admin, super-admin; Permisos: ecclesiastical_years:delete | Soft delete ecclesiastical year | AdminReferenceService.deleteEcclesiasticalYear() | `src/admin/admin-reference.controller.ts` |

### admin-users

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/users` | JWT | Global: admin, super-admin; Permisos: users:read | Listar usuarios administrativos con alcance por rol (ALL/UNION/LOCAL_FIELD) | AdminUsersService.listUsers() | `src/admin/admin-users.controller.ts` |
| GET | `/api/v1/admin/users/bulk-template` | JWT | Global: admin, super-admin; Permisos: users:bulk_create; Global: admin, super-admin, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Descarga plantilla .xlsx para carga masiva de usuarios | AdminUsersService.getBulkTemplateBuffer() | `src/admin/admin-users.controller.ts` |
| GET | `/api/v1/admin/users/:userId` | JWT | Global: admin, super-admin; Permisos: users:read_detail | Obtener detalle de usuario validando alcance por rol del actor | AdminUsersService.getUserById() | `src/admin/admin-users.controller.ts` |
| PATCH | `/api/v1/admin/users/:userId/approval` | JWT | Global: admin, super-admin; Permisos: users:update_admin | Approve or reject a user | AdminUsersService.updateUserApproval() | `src/admin/admin-users.controller.ts` |
| PATCH | `/api/v1/admin/users/:userId` | JWT | Global: admin, super-admin; Permisos: users:update_admin | Update user administrative fields | AdminUsersService.updateUser() | `src/admin/admin-users.controller.ts` |
| POST | `/api/v1/admin/users` | JWT | Global: admin, super-admin; Permisos: users:create; Global: admin, super-admin, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Crear usuario manualmente (admin-iniciado, con invite por email) | AdminUsersService.createAdminUser() | `src/admin/admin-users.controller.ts` |
| POST | `/api/v1/admin/users/bulk` | JWT | Global: admin, super-admin; Permisos: users:bulk_create; Global: admin, super-admin, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Carga masiva de usuarios desde archivo .xlsx o .csv | AdminUsersService.bulkCreateAdminUsers() | `src/admin/admin-users.controller.ts` |

### analytics

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/analytics/sla-dashboard` | JWT | Global: admin, coordinator | SLA Dashboard | AnalyticsService.getSlaDashboard() | `src/analytics/analytics.controller.ts` |
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
| POST | `/api/v1/annual-folders/rankings/recalculate` | JWT | Permisos: rankings:recalculate | Manually trigger a rankings recalculation | RankingsService.recalculateRankings() | `src/annual-folders/rankings.controller.ts` |

### annual-reports

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/annual-reports` | JWT | Permisos: reports:read | Listar informes anuales (admin) | AnnualReportsService.listForAdmin() | `src/annual-reports/annual-reports.controller.ts` |
| GET | `/api/v1/admin/annual-reports/:id` | JWT | Permisos: reports:read | Obtener informe anual por ID (admin) | AnnualReportsService.getReport() | `src/annual-reports/annual-reports.controller.ts` |
| PATCH | `/api/v1/admin/annual-reports/:id` | JWT | Permisos: reports:update | Actualizar datos manuales del informe anual (admin) | AnnualReportsService.updateManualData() | `src/annual-reports/annual-reports.controller.ts` |
| POST | `/api/v1/admin/annual-reports/:id/regenerate` | JWT | Permisos: reports:update | Regenerar datos calculados del informe anual (admin) | AnnualReportsService.regenerate() | `src/annual-reports/annual-reports.controller.ts` |
| POST | `/api/v1/admin/annual-reports/:id/finalize` | JWT | Permisos: reports:update | Finalizar informe anual (admin) | AnnualReportsService.finalize() | `src/annual-reports/annual-reports.controller.ts` |
| GET | `/api/v1/admin/annual-reports/:id/pdf` | JWT | Permisos: reports:download | Descargar PDF del informe anual (admin) | AnnualReportsPdfService.generatePdf() | `src/annual-reports/annual-reports.controller.ts` |
| GET | `/api/v1/clubs/:clubId/annual-reports` | JWT | Permisos: reports:read | Listar informes anuales de un club (usuario) | AnnualReportsService.listForClub() | `src/annual-reports/annual-reports.controller.ts` |
| GET | `/api/v1/clubs/:clubId/annual-reports/:id` | JWT | Permisos: reports:read | Obtener informe anual por ID (usuario) | AnnualReportsService.getReport() | `src/annual-reports/annual-reports.controller.ts` |
| GET | `/api/v1/clubs/:clubId/annual-reports/:id/pdf` | JWT | Permisos: reports:download | Descargar PDF del informe anual (usuario) | AnnualReportsPdfService.generatePdf() | `src/annual-reports/annual-reports.controller.ts` |

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
| POST | `/api/v1/auth/verify-email/send` | JWT | - | Enviar email de verificación al usuario autenticado | AuthService.sendVerificationEmail() | `src/auth/auth.controller.ts` |
| POST | `/api/v1/auth/verify-email/confirm` | Public | - | Confirmar verificación de email con token | AuthService.confirmEmailVerification() | `src/auth/auth.controller.ts` |
| POST | `/api/v1/auth/update-password` | JWT | - | Update authenticated user password | AuthService.updateOwnPassword() | `src/auth/auth.controller.ts` |
| GET | `/api/v1/auth/me` | JWT | - | Obtener perfil del usuario autenticado | AuthService.getProfile() | `src/auth/auth.controller.ts` |
| PATCH | `/api/v1/auth/me/context` | JWT | - | Cambiar contexto activo de club/instancia del usuario | AuthService.setActiveClubContext() | `src/auth/auth.controller.ts` |
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
| GET | `/api/v1/camporee-events/:eventId/scoring-targets` | JWT | - | List enrolled sections that can receive scores | CamporeeScoringService.getScoringTargets() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| POST | `/api/v1/camporee-events/:eventId/sections/:clubSectionId/scores` | JWT | Header opcional `Idempotency-Key: <UUID>`; juez primary o override autorizado | Submit official camporee score/no-show with serialized target and replay-safe receipt | CamporeeScoringService.submitScore() | `src/camporee-scoring/camporee-scoring.controller.ts` |

#### Contrato de captura oficial de score

- Los listados `GET .../judges` devuelven `camporee_judge_id`, `user_id`, `name`, `email`, `notes`, `user_image`, `status` y `active`. Sólo incluyen filas activas del roster solicitado.
- `PATCH /camporee-judges/:judgeId` acepta `{ notes?: string | null, status?: "active" | "inactive", active?: boolean }`. Requiere `camporee_events:update`; el servicio resuelve el camporee padre desde el UUID del juez y valida acceso `current-write` antes de mutar. Un UUID inexistente devuelve `404 CAMPOREE_SCORING_JUDGE_NOT_FOUND` y un actor sin scope devuelve `403 CAMPOREE_EVENT_ACCESS_DENIED`.
- Cuando `PATCH` deja `active=false` o un `status` distinto de `active`, y siempre en `DELETE`, el juez y todas sus asignaciones activas se desactivan en la misma transacción. Las submissions/resultados históricos no se eliminan ni bloquean la operación: conservan su vínculo auditable con la asignación inactiva, por lo que este flujo no devuelve `409` por scores existentes.
- Desactivar el roster de scoring no desactiva automáticamente la fila independiente de `camporee_staff_members`; esa persona puede seguir cumpliendo una función operativa no relacionada con scoring.

- `Idempotency-Key` es opcional por compatibilidad, pero si llega debe ser UUID. El replay del mismo actor, clave y payload canónico devuelve el receipt original sin mutación; reutilizar la clave con otro payload devuelve `409 IDEMPOTENCY_KEY_REUSED`.
- `source` es una intención no confiable: el servidor deriva `judge_primary` para el juez principal asignado cuando no solicita override, `manual_lf` para gestores LF/Unión autorizados y `admin_override` sólo para `admin`, `assistant-admin` o `super-admin`. El permiso `camporee_events:update` por sí solo no autoriza scoring.
- El payload canónico incluye target, source efectiva, `no_show`/estado, notas, `expected_active_result_id` e ítems ordenados por rúbrica; no incluye timestamps.
- Con `Idempotency-Key`, el orden de serialización es fijo: lock bigint por `hashtextextended(prefijo + submitted_by + key, 0)`, lock `pg_advisory_xact_lock(eventId::integer, clubSectionId::integer)`, lookup idempotente y lectura del resultado activo. Los casts explícitos compensan que Prisma enlaza números JavaScript como `INT8` y fuerzan el overload PostgreSQL `(integer, integer)`. Ambos overloads usan keyspaces separados; el hash de 64 bits conserva un riesgo teórico de colisión que sólo sobre-serializa.
- Si el índice único produce `P2002` pese al lock, el servicio relee fuera de la transacción: mismo hash y receipt completo devuelve replay; hash distinto devuelve `409 IDEMPOTENCY_KEY_REUSED`; ausencia de fila relanza el error original. Un receipt sin resultado asociado falla con `500 CAMPOREE_SCORING_RECEIPT_INCOMPLETE`.
- Un override efectivo `manual_lf` o `admin_override` sobre resultado activo debe enviar `expected_active_result_id` igual al ID activo y `notes` no vacío como motivo; si falta el motivo devuelve `400 CAMPOREE_SCORING_OVERRIDE_REASON_REQUIRED`, y si el resultado no coincide devuelve `409 CAMPOREE_SCORING_RESULT_STALE`. El primer score manual, sin activo, puede omitir ambos.
- El receipt estable incluye `camporee_event_section_result_id`, `camporee_event_score_submission_id`, `score_status`, `raw_awarded_points`, `minimum_adjustment_points`, `total_awarded_points`, `total_max_points`, `percentage`, actor/timestamps de submit/finalización, `notes` e `items`. Su `active=true` es un snapshot del estado al emitirse; no representa el estado actual del resultado después de un override.
| GET | `/api/v1/local-camporees/:camporeeId/leaderboard` | JWT | Permisos: camporee_events:read | Obtener local-camporees/{id}/leaderboard | CamporeeScoringService.getCamporeeLeaderboard() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| GET | `/api/v1/union-camporees/:camporeeId/leaderboard` | JWT | Permisos: camporee_events:read | Obtener union-camporees/{id}/leaderboard | CamporeeScoringService.getCamporeeLeaderboard() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| GET | `/api/v1/camporee-judges/me/assignments` | JWT | - | List current user camporee judge assignments | CamporeeScoringService.getMyJudgeAssignments() | `src/camporee-scoring/camporee-scoring.controller.ts` |

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

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/camporees` | JWT | Permisos: camporees:read | Listar camporees | CamporeesService.findAll() | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/union` | JWT | Permisos: camporees:read | Listar camporees de unión | CamporeesService.findAllUnion() | `src/camporees/camporees.controller.ts` |
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
| GET | `/api/v1/camporees/:camporeeId` | JWT | Permisos: camporees:read | Obtener camporee por ID | CamporeesService.findOne() | `src/camporees/camporees.controller.ts` |
| POST | `/api/v1/camporees` | JWT | Permisos: camporees:create | Crear camporee | CamporeesService.create() | `src/camporees/camporees.controller.ts` |
| PATCH | `/api/v1/camporees/:camporeeId` | JWT | Permisos: camporees:update | Actualizar camporee | CamporeesService.update() | `src/camporees/camporees.controller.ts` |
| DELETE | `/api/v1/camporees/:camporeeId` | JWT | Permisos: camporees:delete | Desactivar camporee | CamporeesService.remove() | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/:camporeeId/section-registration` | JWT | Permisos: camporees:read + sección activa | Consultar inscripción contextual de la sección activa | CamporeesService.getActiveSectionRegistration() | `src/camporees/camporees.controller.ts` |
| POST | `/api/v1/camporees/:camporeeId/section-registration` | JWT | Permisos: camporees:register_active_section; solo director CLUB activo | Inscribir la sección activa sin body ni ID enviado por cliente | CamporeesService.registerActiveSection() | `src/camporees/camporees.controller.ts` |
| POST | `/api/v1/camporees/:camporeeId/register` | JWT | Permisos: attendance:manage | Registrar miembro; exige inscripción activa de la sección y `insurance_id` activo, elegible y vigente | CamporeesService.registerMember() | `src/camporees/camporees.controller.ts` |
| POST | `/api/v1/camporees/:camporeeId/participants` | JWT | Permisos: attendance:manage | Alias contextual para registrar participante en la sección activa | CamporeesService.registerParticipants() | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/:camporeeId/members` | JWT | Permisos: attendance:read | Listar miembros del camporee | CamporeesService.getMembers() | `src/camporees/camporees.controller.ts` |
| DELETE | `/api/v1/camporees/:camporeeId/members/:userId` | JWT | Permisos: attendance:manage | Remover miembro del camporee | CamporeesService.removeMember() | `src/camporees/camporees.controller.ts` |
| POST | `/api/v1/camporees/:camporeeId/clubs` | JWT | Permisos: camporees:register; solo assistant-lf, director-lf, assistant-union o director-union dentro de scope | Legacy: inscribir por `club_section_id` validado desde DB | CamporeesService.enrollClub() | `src/camporees/camporees.controller.ts` |
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

#### Inscripción contextual de la sección activa

`GET` devuelve `200`; `POST` devuelve `201` y **no acepta body**. Ambos derivan club y sección desde el assignment activo del actor. El cliente no debe enviar `club_section_id`, `club_id` ni `registered_by`: el backend persiste al actor autenticado.

```json
{
  "camporeeId": 7,
  "clubId": 11,
  "clubName": "Club Central",
  "clubSectionId": 22,
  "sectionName": "Conquistadores",
  "clubTypeId": 2,
  "clubTypeName": "Conquistadores",
  "status": "registered",
  "disposition": "open",
  "canEnroll": false,
  "blockingReason": "already_enrolled",
  "enrollmentId": 91,
  "registeredAt": "2026-07-14T15:30:00.000Z",
  "registeredBy": {
    "userId": "550e8400-e29b-41d4-a716-446655440000",
    "displayName": "Ana Directora"
  }
}
```

| Campo | Valores / regla |
| --- | --- |
| `status` | `not_enrolled`, `registered`, `pending_approval`, `approved`, `rejected`, `cancelled` |
| `disposition` | `not_open_yet`, `open`, `late_approval_required`, `manually_frozen` |
| `canEnroll` | `true` sólo sin inscripción activa, con director CLUB, tipo incluido y disposition `open` o `late_approval_required` |
| `blockingReason` | `already_enrolled`, `director_role_required`, `club_type_not_included`, `not_open_yet`, `manually_frozen` o `null` |
| `enrollmentId`, `registeredAt`, `registeredBy` | `null` cuando no existe inscripción; el actor contiene `userId` y `displayName` |

El lifecycle aplica cierre manual antes que apertura/deadline. `open` crea estado `registered`; `late_approval_required` crea `pending_approval` y notifica revisión; `not_open_yet` y `manually_frozen` bloquean el `POST`. La lectura usa `camporees:read` para roles con contexto activo; la mutación exige además `camporees:register_active_section` y que el assignment activo sea exactamente `director` de categoría `CLUB`.

Respuestas de control: `400 CAMPOREE_CLUB_REGISTRATION_CLOSED` para `not_open_yet|manually_frozen`, `400 CAMPOREE_NOT_ACTIVE`, `403 CAMPOREE_ACTIVE_SECTION_REQUIRED` cuando el contexto/rol/sección no es elegible y `404 CAMPOREE_NOT_FOUND` fuera del scope territorial. Repetir el POST sobre una inscripción activa devuelve el mismo contrato sin crear un duplicado.

#### Gate de participantes y lineage

`POST /:camporeeId/register` y su alias `POST /:camporeeId/participants` aceptan el DTO existente de participante (`user_id` y `insurance_id?`), pero antes de seguro/duplicados exigen:

1. una única inscripción activa de la misma sección con estado `registered` o `approved`;
2. que el assignment activo del participante pertenezca a esa misma sección;
3. que el actor sea el director de la sección activa.

Los incumplimientos devuelven `422` con `code`:

- `CAMPOREE_SECTION_REGISTRATION_REQUIRED` — no existe inscripción activa elegible de la sección;
- `CAMPOREE_MEMBER_OUTSIDE_ACTIVE_SECTION` — el participante no pertenece a la sección activa.

Al crear el participante, el backend persiste `camporee_members.camporee_club_id` con la inscripción de sección que habilitó la operación.

#### Endpoint legacy local de inscripción por sección

`POST /api/v1/camporees/:camporeeId/clubs` conserva body `{ "club_section_id": 22 }` exclusivamente para organizadores territoriales. Requiere `camporees:register` y uno de estos roles `GLOBAL` exactos: `assistant-lf`, `director-lf`, `assistant-union`, `director-union`. El scope debe coincidir con el campo local del camporee o con su unión padre. Roles CLUB, división, `admin` y `super-admin` no heredan esta operación por wildcard.

El backend relee y bloquea camporee, sección, club y tipo desde DB antes de crear; valida activos, territorio, tipo incluido y unicidad activa. El body identifica la sección, pero no es autoridad para club, campo local, tipo ni actor.

El contrato legacy de unión es distinto: `POST /api/v1/camporees/union/:camporeeId/clubs` conserva `attendance:manage` y el scope del camporee de unión.

### catalogs

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/catalogs/club-types` | JWT | - | Obtener tipos de club | CatalogsService.getClubTypes() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/activity-types` | JWT | - | Obtener tipos de actividad | CatalogsService.getActivityTypes() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/relationship-types` | JWT | - | Obtener tipos de relación | CatalogsService.getRelationshipTypes() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/countries` | JWT | - | Obtener países | CatalogsService.getCountries() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/divisions` | JWT | - | Obtener divisiones | CatalogsService.getDivisions() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/unions` | JWT | - | Obtener uniones | CatalogsService.getUnions() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/local-fields` | JWT | - | Obtener campos locales | CatalogsService.getLocalFields() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/districts` | JWT | - | Obtener distritos | CatalogsService.getDistricts() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/churches` | JWT | - | Obtener iglesias | CatalogsService.getChurches() | `src/catalogs/catalogs.controller.ts` |
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
| POST | `/api/v1/admin/certificate-bulk-imports/:batchId/approve` | JWT | Global: super-admin, admin, assistant-admin, director-lf, assistant-lf | Aprobar todas las filas pendientes de un lote | AdminCertificateBulkImportsService.approveBatch() | `src/certificate-bulk-imports/admin-certificate-bulk-imports.controller.ts` |
| POST | `/api/v1/admin/certificate-bulk-imports/:batchId/reject` | JWT | Global: super-admin, admin, assistant-admin, director-lf, assistant-lf | Rechazar un lote completo y solicitar corrección | AdminCertificateBulkImportsService.rejectBatch() | `src/certificate-bulk-imports/admin-certificate-bulk-imports.controller.ts` |
| POST | `/api/v1/admin/certificate-bulk-imports/:batchId/items/:itemId/approve` | JWT | Global: super-admin, admin, assistant-admin, director-lf, assistant-lf | Aprobar una fila del lote | AdminCertificateBulkImportsService.approveItem() | `src/certificate-bulk-imports/admin-certificate-bulk-imports.controller.ts` |
| POST | `/api/v1/admin/certificate-bulk-imports/:batchId/items/:itemId/reject` | JWT | Global: super-admin, admin, assistant-admin, director-lf, assistant-lf | Rechazar una fila del lote con motivo | AdminCertificateBulkImportsService.rejectItem() | `src/certificate-bulk-imports/admin-certificate-bulk-imports.controller.ts` |

### certificate-bulk-imports

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/certificate-bulk-imports` | JWT | - | Crear un borrador de carga por certificado | CertificateBulkImportsService.createDraft() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |
| POST | `/api/v1/certificate-bulk-imports/:batchId/process-ocr` | JWT | - | Procesar OCR de un borrador del miembro | CertificateBulkImportsService.processOcr() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |
| GET | `/api/v1/certificate-bulk-imports/:batchId` | JWT | - | Obtener detalle de una carga por certificado | CertificateBulkImportsService.getBatch() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |
| PATCH | `/api/v1/certificate-bulk-imports/:batchId/items/:itemId` | JWT | - | Corregir o completar una fila detectada por OCR | CertificateBulkImportsService.updateItem() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |
| POST | `/api/v1/certificate-bulk-imports/:batchId/submit` | JWT | - | Enviar carga por certificado a validación de Campo Local | CertificateBulkImportsService.submit() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |
| POST | `/api/v1/certificate-bulk-imports/:batchId/items/:itemId/resubmit` | JWT | - | Corregir y reenviar una fila rechazada | CertificateBulkImportsService.resubmitItem() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |

### certifications

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/certifications/certifications` | JWT | - | Listar todas las certificaciones disponibles | CertificationsService.findAll() | `src/certifications/certifications.controller.ts` |
| GET | `/api/v1/certifications/certifications/:id` | JWT | - | Obtener detalles de una certificación | CertificationsService.findOne() | `src/certifications/certifications.controller.ts` |
| POST | `/api/v1/certifications/users/:userId/certifications/enroll` | JWT | Permisos: user_certifications:manage | Inscribirse en una certificación | CertificationsService.enrollUser() | `src/certifications/certifications.controller.ts` |
| GET | `/api/v1/certifications/users/:userId/certifications` | JWT | Permisos: user_certifications:read | Listar certificaciones del usuario | CertificationsService.getUserCertifications() | `src/certifications/certifications.controller.ts` |
| GET | `/api/v1/certifications/users/:userId/certifications/:certificationId/progress` | JWT | Permisos: user_certifications:read | Ver progreso detallado de una certificación | CertificationsService.getCertificationProgress() | `src/certifications/certifications.controller.ts` |
| PATCH | `/api/v1/certifications/users/:userId/certifications/:certificationId/progress` | JWT | Permisos: user_certifications:manage | Actualizar progreso de una sección | CertificationsService.updateProgress() | `src/certifications/certifications.controller.ts` |
| DELETE | `/api/v1/certifications/users/:userId/certifications/:certificationId` | JWT | Permisos: user_certifications:manage | Abandonar una certificación | CertificationsService.deleteCertification() | `src/certifications/certifications.controller.ts` |

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
| GET | `/api/v1/clubs/:clubId/sections/:sectionId/classes/:classId/members-progress` | JWT | Permisos: classes:read | Listar avance de miembros por clase en una sección | ClassProgressScopeService.getClassMembersProgress() | `src/classes/class-progress-scope.controller.ts` |

### classes

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/classes` | JWT | - | Listar clases | ClassesService.findAll() | `src/classes/classes.controller.ts` |
| GET | `/api/v1/classes/:classId` | JWT | - | Obtener clase por ID | ClassesService.findOne() | `src/classes/classes.controller.ts` |
| GET | `/api/v1/classes/:classId/modules` | JWT | - | Obtener módulos de una clase | ClassesService.getModules() | `src/classes/classes.controller.ts` |

### user-classes

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/users/:userId/classes` | JWT | Permisos: classes:read | Obtener inscripciones del usuario | ClassesService.getUserEnrollments() | `src/classes/classes.controller.ts` |
| POST | `/api/v1/users/:userId/classes/enroll` | JWT | Permisos: classes:submit_progress | Inscribir usuario en clase | ClassesService.enrollUser() | `src/classes/classes.controller.ts` |
| GET | `/api/v1/users/:userId/classes/:classId/progress` | JWT | Permisos: classes:read | Obtener progreso del usuario en una clase | ClassesService.getUserProgress() | `src/classes/classes.controller.ts` |
| PATCH | `/api/v1/users/:userId/classes/:classId/progress` | JWT | Permisos: classes:submit_progress | Actualizar progreso de sección | ClassesService.updateSectionProgress() | `src/classes/classes.controller.ts` |
| POST | `/api/v1/users/:userId/classes/:classId/sections/:sectionId/submit` | JWT | Permisos: classes:submit_progress | Submit a class section for validation | ClassesService.submitSection() | `src/classes/classes.controller.ts` |
| POST | `/api/v1/users/:userId/classes/:classId/sections/:sectionId/files` | JWT | Permisos: classes:submit_progress | Upload evidence file for a class section | ClassesService.uploadSectionFile() | `src/classes/classes.controller.ts` |
| DELETE | `/api/v1/users/:userId/classes/:classId/sections/:sectionId/files/:fileId` | JWT | Permisos: classes:submit_progress | Delete evidence file for a class section | ClassesService.deleteSectionFile() | `src/classes/classes.controller.ts` |

#### Conflictos de capacidad de inscripción

- El precheck actual de `POST /api/v1/users/:userId/classes/enroll` devuelve `409 CLASS_MAX_AVENTU_CONQUIS_ACTIVE` o `409 CLASS_MAX_GM_ACTIVE` cuando su conteo previo detecta el cupo agotado.
- El marker PostgreSQL `23514` con `detail = SACDIA_ENROLLMENT_PROGRAM_CAPACITY` es interno; su mapeo específico a esos `409` en una carrera queda pendiente de reconciliar el runtime. Otros `23514` no deben reinterpretarse como capacidad.

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
| GET | `/api/v1/clubs` | JWT | - | Listar clubs | ClubsService.findAll() | `src/clubs/clubs.controller.ts` |
| GET | `/api/v1/clubs/:clubId` | JWT | Permisos: clubs:read | Obtener club por ID | ClubsService.findOne() | `src/clubs/clubs.controller.ts` |
| POST | `/api/v1/clubs` | JWT | Permisos: clubs:create | Crear nuevo club | ClubsService.create() | `src/clubs/clubs.controller.ts` |
| PATCH | `/api/v1/clubs/:clubId` | JWT | Permisos: clubs:update; Club: director, deputy-director | Actualizar club (requiere rol director o deputy director) | ClubsService.update() | `src/clubs/clubs.controller.ts` |
| DELETE | `/api/v1/clubs/:clubId` | JWT | Permisos: clubs:delete; Club: director | Desactivar club (requiere rol director) | ClubsService.remove() | `src/clubs/clubs.controller.ts` |
| GET | `/api/v1/clubs/:clubId/sections` | JWT | - | Obtener secciones del club | ClubsService.getSections() | `src/clubs/clubs.controller.ts` |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId` | JWT | Permisos: club_sections:read | Obtener sección por ID | ClubsService.getSection() | `src/clubs/clubs.controller.ts` |
| POST | `/api/v1/clubs/:clubId/sections` | JWT | Permisos: club_sections:create; Club: director, deputy-director | Crear sección de club (requiere director o deputy director) | ClubsService.createSection() | `src/clubs/clubs.controller.ts` |
| PATCH | `/api/v1/clubs/:clubId/sections/:sectionId` | JWT | Permisos: club_sections:update; Club: director, deputy-director, secretary | Actualizar sección (requiere director, deputy director o secretary) | ClubsService.updateSection() | `src/clubs/clubs.controller.ts` |
| GET | `/api/v1/clubs/:clubId/leadership` | JWT | Permisos: clubs:read | Liderazgo del club | ClubsService.getClubLeadership() | `src/clubs/clubs.controller.ts` |
| GET | `/api/v1/clubs/:clubId/overview` | JWT | Permisos: clubs:read | Resumen agregado del club | ClubsService.getClubOverview() | `src/clubs/clubs.controller.ts` |
| GET | `/api/v1/clubs/:clubId/history` | JWT | Permisos: clubs:read | Historial de auditoría del club | ClubsService.getClubHistory() | `src/clubs/clubs.controller.ts` |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId/members` | JWT | Permisos: club_roles:read | Listar miembros de la sección | ClubsService.getMembers() | `src/clubs/clubs.controller.ts` |
| POST | `/api/v1/clubs/:clubId/sections/:sectionId/roles` | JWT | Permisos: club_roles:assign | Asignar rol a un miembro (requiere director, deputy director o secretary) | ClubsService.assignRole() | `src/clubs/clubs.controller.ts` |
| POST | `/api/v1/clubs/:clubId/sections/:sectionId/director-assignment` | JWT | Permisos: club_roles:assign | Asignación inicial de director de sección | ClubsService.assignInitialSectionDirector() | `src/clubs/clubs.controller.ts` |
| POST | `/api/v1/clubs/:clubId/sections/:sectionId/director-succession` | JWT | Permisos: club_roles:assign, club_roles:revoke | Sucesión inmediata de director (baseline actual): termina la asignación saliente y crea la nueva asignación activa en la misma operación | ClubsService.succeedSectionDirector() | `src/clubs/clubs.controller.ts` |

> [!NOTE]
> Esta referencia LIVE conserva únicamente el comportamiento implementado.
> El contrato P0 de scheduling y sus lecturas de preflight/capabilities siguen
> planeados, no implementados ni habilitados; se documentan como contrato
> futuro en `docs/features/gestion-clubs.md` y no se incluyen en la tabla LIVE.

### club-roles

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| PATCH | `/api/v1/club-roles/:assignmentId` | JWT | Permisos: club_roles:assign | Actualizar asignación de rol | ClubsService.updateRoleAssignment() | `src/clubs/clubs.controller.ts` |
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
| GET | `/api/v1/evidence-review/pending` | JWT | Global: admin, super-admin, coordinator | Listar evidencias pendientes de revisión | EvidenceReviewService.getPending() | `src/evidence-review/evidence-review.controller.ts` |
| POST | `/api/v1/evidence-review/bulk-approve` | JWT | Global: admin, super-admin, coordinator | Aprobar múltiples evidencias en bloque | EvidenceReviewService.bulkApprove() | `src/evidence-review/evidence-review.controller.ts` |
| POST | `/api/v1/evidence-review/bulk-reject` | JWT | Global: admin, super-admin, coordinator | Rechazar múltiples evidencias en bloque | EvidenceReviewService.bulkReject() | `src/evidence-review/evidence-review.controller.ts` |
| GET | `/api/v1/evidence-review/:type/:id` | JWT | Global: admin, super-admin, coordinator | Obtener detalle de una evidencia con archivos adjuntos | EvidenceReviewService.getDetail() | `src/evidence-review/evidence-review.controller.ts` |
| POST | `/api/v1/evidence-review/:type/:id/approve` | JWT | Global: admin, super-admin, coordinator | Aprobar una evidencia | EvidenceReviewService.approve() | `src/evidence-review/evidence-review.controller.ts` |
| POST | `/api/v1/evidence-review/:type/:id/reject` | JWT | Global: admin, super-admin, coordinator | Rechazar una evidencia con motivo | EvidenceReviewService.reject() | `src/evidence-review/evidence-review.controller.ts` |
| GET | `/api/v1/evidence-review/:type/:id/history` | JWT | Global: admin, super-admin, coordinator | Historial de validación de una evidencia | EvidenceReviewService.getHistory() | `src/evidence-review/evidence-review.controller.ts` |

### finances

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/finances/categories` | JWT | Permisos: finances:read | Listar categorías financieras | FinancesService.getCategories() | `src/finances/finances.controller.ts` |
| GET | `/api/v1/clubs/:clubId/finances/transactions` | JWT | Permisos: finances:read | Listar todas las transacciones del club (paginadas) | FinancesService.getAllTransactions() | `src/finances/finances.controller.ts` |
| GET | `/api/v1/clubs/:clubId/finances` | JWT | Permisos: finances:read | Listar movimientos financieros del club | FinancesService.findByClub() | `src/finances/finances.controller.ts` |
| GET | `/api/v1/clubs/:clubId/finances/summary` | JWT | Permisos: finances:read | Resumen financiero del club | FinancesService.getSummary() | `src/finances/finances.controller.ts` |
| POST | `/api/v1/clubs/:clubId/finances` | JWT | Permisos: finances:create; Club: director, deputy-director, treasurer | Crear movimiento financiero | FinancesService.create() | `src/finances/finances.controller.ts` |
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
| GET | `/api/v1/honors/categories` | JWT | - | Listar categorías de honores | HonorsService.getCategories() | `src/honors/honors.controller.ts` |
| GET | `/api/v1/honors/grouped-by-category` | JWT | - | Listar honores agrupados por categoría | HonorsService.getGroupedByCategory() | `src/honors/honors.controller.ts` |
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
| GET | `/api/v1/insurance/products` | JWT | `insurance:configure`; solo `director-lf`/`assistant-lf` con Campo Local efectivo | Listar productos configurables del Campo Local efectivo | InsuranceConfigService.listProducts() | `src/insurance/insurance.controller.ts` |
| POST | `/api/v1/insurance/products` | JWT | `insurance:configure`; solo `director-lf`/`assistant-lf` con Campo Local efectivo | Crear producto de seguro en el Campo Local efectivo | InsuranceConfigService.createProduct() | `src/insurance/insurance.controller.ts` |
| PATCH | `/api/v1/insurance/products/:productId` | JWT | `insurance:configure`; solo `director-lf`/`assistant-lf` con Campo Local efectivo | Actualizar producto del propio Campo Local | InsuranceConfigService.updateProduct() | `src/insurance/insurance.controller.ts` |
| GET | `/api/v1/insurance/cycles` | JWT | `insurance:configure`; solo `director-lf`/`assistant-lf` con Campo Local efectivo | Listar ciclos configurados del Campo Local efectivo | InsuranceConfigService.listCycles() | `src/insurance/insurance.controller.ts` |
| POST | `/api/v1/insurance/cycles` | JWT | `insurance:configure`; solo `director-lf`/`assistant-lf` con Campo Local efectivo | Crear configuración de ciclo de un producto propio | InsuranceConfigService.createCycle() | `src/insurance/insurance.controller.ts` |
| PATCH | `/api/v1/insurance/cycles/:cycleConfigId` | JWT | `insurance:configure`; solo `director-lf`/`assistant-lf` con Campo Local efectivo | Actualizar costo, timezone, estado o deadline de ciclo propio | InsuranceConfigService.updateCycle() | `src/insurance/insurance.controller.ts` |
| POST | `/api/v1/club-sections/:sectionId/insurance/purchases` | JWT multipart | `insurance:create` + scope efectivo de la sección | Enviar compra con `purchase_proof` obligatorio; queda pendiente y no crea cupos | InsurancePurchasesService.submit() | `src/insurance/insurance-purchases.controller.ts` |
| GET | `/api/v1/club-sections/:sectionId/insurance/purchases` | JWT | `insurance:read` + scope efectivo de la sección | Listar compras de la propia sección | InsurancePurchasesService.listForSection() | `src/insurance/insurance-purchases.controller.ts` |
| GET | `/api/v1/insurance/purchases/:purchaseId` | JWT | `insurance:read` + territorio/sección efectiva | Consultar compra dentro del alcance efectivo | InsurancePurchasesService.getById() | `src/insurance/insurance-purchases.controller.ts` |
| GET | `/api/v1/insurance/purchases/:purchaseId/proof` | JWT | `insurance:read` + territorio/sección efectiva | Generar URL R2 firmada de 5 minutos para comprobante privado | InsuranceEvidenceService.getPurchaseProofUrl() | `src/insurance/insurance-purchases.controller.ts` |
| POST | `/api/v1/insurance/purchases/:purchaseId/confirm` | JWT | `insurance:review`; `director-lf`, `assistant-lf`, `admin` o `super-admin` dentro del alcance efectivo | Confirmar y materializar N cupos transaccionalmente; deadline inclusivo | InsurancePurchasesService.confirm() | `src/insurance/insurance-purchases.controller.ts` |
| POST | `/api/v1/insurance/purchases/:purchaseId/reject` | JWT | `insurance:review`; mismos roles de revisión | Rechazar compra pendiente con motivo obligatorio y sin cupos | InsurancePurchasesService.reject() | `src/insurance/insurance-purchases.controller.ts` |
| POST | `/api/v1/insurance/purchases/:purchaseId/reverse` | JWT | `insurance:review`; mismos roles de revisión | Revertir solo una compra confirmada sin cupos asignados | InsurancePurchasesService.reverse() | `src/insurance/insurance-purchases.controller.ts` |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId/members/insurance` | JWT | Permisos: insurance:read | Listar seguros de miembros por sección | InsuranceService.listMembersInsurance() | `src/insurance/insurance.controller.ts` |
| GET | `/api/v1/insurance/expiring` | JWT | Global: admin, coordinator | Listar seguros próximos a vencer | InsuranceService.getExpiringInsurances() | `src/insurance/insurance.controller.ts` |
| GET | `/api/v1/users/:memberId/insurance` | JWT | Permisos: insurance:read | Obtener seguro activo del miembro | InsuranceService.getMemberInsurance() | `src/insurance/insurance.controller.ts` |
| POST | `/api/v1/users/:memberId/insurance` | JWT | Permisos: insurance:create | Crear seguro para un miembro | InsuranceService.createInsurance() | `src/insurance/insurance.controller.ts` |
| PATCH | `/api/v1/insurance/:insuranceId` | JWT | Permisos: insurance:update | Actualizar seguro | InsuranceService.updateInsurance() | `src/insurance/insurance.controller.ts` |
| GET | `/api/v1/insurance/products` | JWT | `insurance:configure`; solo `director-lf`/`assistant-lf` con Campo Local efectivo | Listar productos configurables del Campo Local efectivo | InsuranceConfigService.listProducts() | `src/insurance/insurance.controller.ts` |
| POST | `/api/v1/insurance/products` | JWT | `insurance:configure`; solo `director-lf`/`assistant-lf` con Campo Local efectivo | Crear producto de seguro en el Campo Local efectivo | InsuranceConfigService.createProduct() | `src/insurance/insurance.controller.ts` |
| PATCH | `/api/v1/insurance/products/:productId` | JWT | `insurance:configure`; solo `director-lf`/`assistant-lf` con Campo Local efectivo | Actualizar producto del propio Campo Local | InsuranceConfigService.updateProduct() | `src/insurance/insurance.controller.ts` |
| GET | `/api/v1/insurance/cycles` | JWT | `insurance:configure`; solo `director-lf`/`assistant-lf` con Campo Local efectivo | Listar ciclos configurados del Campo Local efectivo | InsuranceConfigService.listCycles() | `src/insurance/insurance.controller.ts` |
| POST | `/api/v1/insurance/cycles` | JWT | `insurance:configure`; solo `director-lf`/`assistant-lf` con Campo Local efectivo | Crear configuración de ciclo de un producto propio | InsuranceConfigService.createCycle() | `src/insurance/insurance.controller.ts` |
| PATCH | `/api/v1/insurance/cycles/:cycleConfigId` | JWT | `insurance:configure`; solo `director-lf`/`assistant-lf` con Campo Local efectivo | Actualizar costo, timezone, estado o deadline de ciclo propio | InsuranceConfigService.updateCycle() | `src/insurance/insurance.controller.ts` |
| POST | `/api/v1/club-sections/:sectionId/insurance/purchases` | JWT multipart | `insurance:create` + scope efectivo de la sección | Enviar compra de cupos con `purchase_proof` obligatorio; solo queda pendiente y no crea cupos | InsurancePurchasesService.submit() | `src/insurance/insurance-purchases.controller.ts` |
| GET | `/api/v1/club-sections/:sectionId/insurance/purchases` | JWT | `insurance:read` + scope efectivo de la sección | Listar compras de la propia sección | InsurancePurchasesService.listForSection() | `src/insurance/insurance-purchases.controller.ts` |
| GET | `/api/v1/insurance/purchases/:purchaseId` | JWT | `insurance:read` + territorio efectivo | Consultar compra dentro del Campo Local/alcance efectivo | InsurancePurchasesService.getById() | `src/insurance/insurance-purchases.controller.ts` |
| GET | `/api/v1/insurance/purchases/:purchaseId/proof` | JWT | `insurance:read` + territorio efectivo | Generar URL R2 firmada de 5 min para comprobante privado autorizado | InsuranceEvidenceService.getPurchaseProofUrl() | `src/insurance/insurance-purchases.controller.ts` |
| POST | `/api/v1/insurance/purchases/:purchaseId/confirm` | JWT | `insurance:review`; `director-lf`, `assistant-lf`, `admin` o `super-admin` dentro de su alcance efectivo | Confirmar y crear N cupos transaccionalmente; fecha límite inclusiva | InsurancePurchasesService.confirm() | `src/insurance/insurance-purchases.controller.ts` |
| POST | `/api/v1/insurance/purchases/:purchaseId/reject` | JWT | `insurance:review`; mismos roles de revisión | Rechazar compra pendiente con motivo obligatorio, sin cupos | InsurancePurchasesService.reject() | `src/insurance/insurance-purchases.controller.ts` |
| POST | `/api/v1/insurance/purchases/:purchaseId/reverse` | JWT | `insurance:review`; mismos roles de revisión | Revertir solo una compra confirmada cuyos cupos sigan sin asignar | InsurancePurchasesService.reverse() | `src/insurance/insurance-purchases.controller.ts` |

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
| GET | `/api/v1/inventory/catalogs/inventory-categories` | JWT | Permisos: inventory:read | Listar categorías de inventario | InventoryService.findAllCategories() | `src/inventory/inventory.controller.ts` |

### investiture

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/investiture/enrollments/:enrollmentId/submit` | JWT | Permisos: investiture:submit; Club: director, counselor | Enviar enrollment a validación de investidura (consejero/director) | InvestitureService.submitForValidation() | `src/investiture/investiture.controller.ts` |
| POST | `/api/v1/investiture/enrollments/:enrollmentId/club-approve` | JWT | Permisos: investiture:validate; Club: director | Director de sección aprueba enrollment para investidura | InvestitureService.clubApprove() | `src/investiture/investiture.controller.ts` |
| POST | `/api/v1/investiture/enrollments/:enrollmentId/coordinator-approve` | JWT | Permisos: investiture:validate; Global: admin, coordinator | Coordinador aprueba enrollment para investidura | InvestitureService.coordinatorApprove() | `src/investiture/investiture.controller.ts` |
| POST | `/api/v1/investiture/enrollments/:enrollmentId/field-approve` | JWT | Permisos: investiture:validate; Global: admin | Campo local aprueba enrollment para investidura | InvestitureService.fieldApprove() | `src/investiture/investiture.controller.ts` |
| POST | `/api/v1/investiture/enrollments/:enrollmentId/invest` | JWT | Permisos: investiture:mark_invested; Global: admin, coordinator | Registrar investidura formal de un enrollment (después de FIELD_APPROVED) | InvestitureService.markInvestido() | `src/investiture/investiture.controller.ts` |
| POST | `/api/v1/investiture/enrollments/:enrollmentId/reject` | JWT | Permisos: investiture:validate; Global: admin, coordinator | Rechazar enrollment en cualquier nivel del flujo de aprobación | InvestitureService.reject() | `src/investiture/investiture.controller.ts` |
| POST | `/api/v1/investiture/enrollments/bulk-approve` | JWT | Global: admin, coordinator | Aprobar múltiples enrollments en bloque | InvestitureService.bulkApproveEnrollments() | `src/investiture/investiture.controller.ts` |
| POST | `/api/v1/investiture/enrollments/bulk-reject` | JWT | Global: admin, coordinator | Rechazar múltiples enrollments en bloque | InvestitureService.bulkRejectEnrollments() | `src/investiture/investiture.controller.ts` |
| POST | `/api/v1/admin/classes/enrollments/expire-overdue` | JWT | Permisos: catalogs:update; Global: admin | Vencer manualmente enrollments atrasados por duración de clase | InvestitureService.expireOverdueEnrollments() | `src/investiture/investiture.controller.ts` |
| GET | `/api/v1/investiture/pending` | JWT | Global: admin, coordinator | Listar enrollments pendientes de aprobación (filtrable por nivel) | InvestitureService.getPending() | `src/investiture/investiture.controller.ts` |
| GET | `/api/v1/investiture/enrollments/:enrollmentId/history` | JWT | - | Historial de validación de investidura de un enrollment | InvestitureService.getHistory() | `src/investiture/investiture.controller.ts` |
| POST | `/api/v1/enrollments/:enrollmentId/submit-for-validation` | JWT | Permisos: investiture:submit; Club: director, counselor | [LEGACY] Enviar enrollment a validación de investidura | InvestitureService.submitForValidation() | `src/investiture/investiture.controller.ts` |
| POST | `/api/v1/enrollments/:enrollmentId/validate` | JWT | Permisos: investiture:validate; Global: admin, coordinator | [LEGACY] Aprobar o rechazar enrollment para investidura | InvestitureService.validateEnrollment() | `src/investiture/investiture.controller.ts` |
| POST | `/api/v1/enrollments/:enrollmentId/investiture` | JWT | Permisos: investiture:mark_invested; Global: admin, coordinator | [LEGACY] Registrar investidura formal de un enrollment | InvestitureService.markInvestido() | `src/investiture/investiture.controller.ts` |
| GET | `/api/v1/enrollments/:enrollmentId/investiture-history` | JWT | - | [LEGACY] Historial de validación de investidura de un enrollment | InvestitureService.getHistory() | `src/investiture/investiture.controller.ts` |
| GET | `/api/v1/admin/investiture/config` | JWT | Global: admin, coordinator, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Listar configuraciones de investidura | InvestitureService.getConfigs() | `src/investiture/investiture.controller.ts` |
| GET | `/api/v1/admin/investiture/config/:configId` | JWT | Global: admin, coordinator, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Obtener configuración de investidura por ID | InvestitureService.getConfig() | `src/investiture/investiture.controller.ts` |
| POST | `/api/v1/admin/investiture/config` | JWT | Global: admin, coordinator, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Crear configuración de investidura | InvestitureService.createConfig() | `src/investiture/investiture.controller.ts` |
| PATCH | `/api/v1/admin/investiture/config/:configId` | JWT | Global: admin, coordinator, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Actualizar configuración de investidura | InvestitureService.updateConfig() | `src/investiture/investiture.controller.ts` |
| DELETE | `/api/v1/admin/investiture/config/:configId` | JWT | Global: admin, coordinator, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Soft-delete de configuración de investidura (active = false) | InvestitureService.deleteConfig() | `src/investiture/investiture.controller.ts` |

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
| GET | `/api/v1/materials/config/all` | JWT | Permisos: MATERIALS_CONFIGURE | List materials configuration for every local_field (unscoped admins) | ConfigService.listAll() | `src/materials/config/config.controller.ts` |
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
| GET | `/api/v1/member-of-month/admin/list` | JWT | Permisos: mom:supervise | Listar miembro del mes multi-sección (admin/coordinator) | MemberOfMonthService.listForAdmin() | `src/member-of-month/member-of-month.controller.ts` |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId/member-of-month` | JWT | Permisos: mom:read | Obtener miembro del mes actual de la sección | MemberOfMonthService.getCurrentMemberOfMonth() | `src/member-of-month/member-of-month.controller.ts` |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId/member-of-month/history` | JWT | Permisos: mom:read | Obtener historial paginado de miembro del mes | MemberOfMonthService.getMemberOfMonthHistory() | `src/member-of-month/member-of-month.controller.ts` |
| POST | `/api/v1/clubs/:clubId/sections/:sectionId/member-of-month/evaluate` | JWT | Permisos: mom:evaluate | Disparar evaluación manual de miembro del mes | MemberOfMonthService.evaluateMemberOfMonth() | `src/member-of-month/member-of-month.controller.ts` |

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
| POST | `/api/v1/monthly-reports/:reportId/generate` | JWT | Permisos: reports:read | Generar informe (congelar datos) | MonthlyReportsService.generate() | `src/monthly-reports/monthly-reports.controller.ts` |
| POST | `/api/v1/monthly-reports/:reportId/submit` | JWT | Permisos: reports:read | Enviar informe al campo | MonthlyReportsService.submit() | `src/monthly-reports/monthly-reports.controller.ts` |
| GET | `/api/v1/monthly-reports/enrollment/:enrollmentId` | JWT | Permisos: reports:read | Listar informes de una matrícula | MonthlyReportsService.listReports() | `src/monthly-reports/monthly-reports.controller.ts` |
| GET | `/api/v1/monthly-reports/:reportId/pdf` | JWT | Permisos: reports:download | Descargar informe mensual en PDF | MonthlyReportsPdfService.generatePdf() | `src/monthly-reports/monthly-reports.controller.ts` |
| GET | `/api/v1/monthly-reports/admin/list` | JWT | Permisos: reports:read | Listar reportes multi-club (admin/coordinator) | MonthlyReportsService.listForAdmin() | `src/monthly-reports/monthly-reports.controller.ts` |
| GET | `/api/v1/monthly-reports/:reportId` | JWT | Permisos: reports:read | Obtener informe mensual | MonthlyReportsService.getReport() | `src/monthly-reports/monthly-reports.controller.ts` |

#### Contrato de `PATCH /api/v1/monthly-reports/:reportId/manual-data`

- Solo admite reportes en `draft` y excluye del payload persistido cualquier campo `undefined`.
- Un payload técnico vacío, o la creación de una fila compuesta únicamente por textos nullable en `null`, vacíos o whitespace, responde `400` con `code = MONTHLY_REPORT_MANUAL_DATA_REQUIRED`.
- `null` en un campo numérico o booleano responde `400` con `code = MONTHLY_REPORT_INVALID_MANUAL_DATA`.
- `0` y `false` explícitos son valores válidos. En una fila existente, los textos nullable aceptan `null` para limpiar su valor.
- El error conserva el response shape global; estos códigos no modifican el contrato de los demás endpoints.

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
| GET | `/api/v1/fcm-tokens/user/:userId` | JWT | - | Get FCM tokens by user ID (owner/admin only) | FcmTokensService.getUserTokens() | `src/notifications/notifications.controller.ts` |

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

### quarterly-reports

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/quarterly-reports` | JWT | Permisos: reports:read | Listar informes trimestrales (admin) | QuarterlyReportsService.listForAdmin() | `src/quarterly-reports/quarterly-reports.controller.ts` |
| GET | `/api/v1/admin/quarterly-reports/:id` | JWT | Permisos: reports:read | Obtener informe trimestral por ID (admin) | QuarterlyReportsService.getReport() | `src/quarterly-reports/quarterly-reports.controller.ts` |
| PATCH | `/api/v1/admin/quarterly-reports/:id` | JWT | Permisos: reports:update | Actualizar datos manuales del informe trimestral (admin) | QuarterlyReportsService.updateManualData() | `src/quarterly-reports/quarterly-reports.controller.ts` |
| POST | `/api/v1/admin/quarterly-reports/:id/regenerate` | JWT | Permisos: reports:update | Regenerar datos calculados del informe trimestral (admin) | QuarterlyReportsService.regenerate() | `src/quarterly-reports/quarterly-reports.controller.ts` |
| POST | `/api/v1/admin/quarterly-reports/:id/finalize` | JWT | Permisos: reports:update | Finalizar informe trimestral (admin) | QuarterlyReportsService.finalize() | `src/quarterly-reports/quarterly-reports.controller.ts` |
| GET | `/api/v1/admin/quarterly-reports/:id/pdf` | JWT | Permisos: reports:download | Descargar PDF del informe trimestral (admin) | QuarterlyReportsPdfService.generatePdf() | `src/quarterly-reports/quarterly-reports.controller.ts` |
| GET | `/api/v1/clubs/:clubId/quarterly-reports` | JWT | Permisos: reports:read | Listar informes trimestrales de un club (usuario) | QuarterlyReportsService.listForClub() | `src/quarterly-reports/quarterly-reports.controller.ts` |
| GET | `/api/v1/clubs/:clubId/quarterly-reports/:id` | JWT | Permisos: reports:read | Obtener informe trimestral por ID (usuario) | QuarterlyReportsService.getReport() | `src/quarterly-reports/quarterly-reports.controller.ts` |
| GET | `/api/v1/clubs/:clubId/quarterly-reports/:id/pdf` | JWT | Permisos: reports:download | Descargar PDF del informe trimestral (usuario) | QuarterlyReportsPdfService.generatePdf() | `src/quarterly-reports/quarterly-reports.controller.ts` |

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
| POST | `/api/v1/member-rankings/recalculate` | JWT | Permisos: member_ranking_weights:write | Manually trigger member + section ranking recalculation | MemberRankingsService.triggerRecalculate() | `src/rankings/member-rankings/member-rankings.controller.ts` |
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
| POST | `/api/v1/admin/rbac/permissions` | JWT | Permisos: permissions:assign | Crear un nuevo permiso | RbacService.createPermission() | `src/rbac/rbac.controller.ts` |
| PATCH | `/api/v1/admin/rbac/permissions/:id` | JWT | Permisos: permissions:assign | Actualizar un permiso | RbacService.updatePermission() | `src/rbac/rbac.controller.ts` |
| DELETE | `/api/v1/admin/rbac/permissions/:id` | JWT | Permisos: permissions:assign | Desactivar un permiso | RbacService.deletePermission() | `src/rbac/rbac.controller.ts` |
| GET | `/api/v1/admin/rbac/roles` | JWT | Permisos: roles:read | Listar roles con sus permisos | RbacService.listRoles() | `src/rbac/rbac.controller.ts` |
| GET | `/api/v1/admin/rbac/roles/:id` | JWT | Permisos: roles:read | Obtener rol con sus permisos | RbacService.getRoleWithPermissions() | `src/rbac/rbac.controller.ts` |
| POST | `/api/v1/admin/rbac/roles` | JWT | Global: super-admin | Crear un nuevo rol | RbacService.createRole() | `src/rbac/rbac.controller.ts` |
| PATCH | `/api/v1/admin/rbac/roles/:id` | JWT | Global: super-admin | Actualizar descripción y/o permisos de un rol | RbacService.updateRole() | `src/rbac/rbac.controller.ts` |
| DELETE | `/api/v1/admin/rbac/roles/:id` | JWT | Global: super-admin | Desactivar (soft delete) un rol | RbacService.deactivateRole() | `src/rbac/rbac.controller.ts` |
| POST | `/api/v1/admin/rbac/roles/:id/permissions` | JWT | Permisos: permissions:assign | Asignar permisos a un rol | RbacService.assignPermissionsToRole() | `src/rbac/rbac.controller.ts` |
| PUT | `/api/v1/admin/rbac/roles/:id/permissions` | JWT | Permisos: permissions:assign | Sincronizar permisos de un rol (reemplaza todos) | RbacService.syncRolePermissions() | `src/rbac/rbac.controller.ts` |
| DELETE | `/api/v1/admin/rbac/roles/:id/permissions/:permissionId` | JWT | Permisos: permissions:assign | Remover un permiso de un rol | RbacService.removePermissionFromRole() | `src/rbac/rbac.controller.ts` |
| GET | `/api/v1/admin/rbac/users/:userId/permissions` | JWT | Permisos: permissions:read | Listar permisos directos de un usuario | RbacService.getUserPermissions() | `src/rbac/rbac.controller.ts` |
| POST | `/api/v1/admin/rbac/users/:userId/permissions` | JWT | Permisos: permissions:assign | Asignar un permiso directo a un usuario | RbacService.assignPermissionToUser() | `src/rbac/rbac.controller.ts` |
| DELETE | `/api/v1/admin/rbac/users/:userId/permissions/:permissionId` | JWT | Permisos: permissions:assign | Remover un permiso directo de un usuario | RbacService.removePermissionFromUser() | `src/rbac/rbac.controller.ts` |
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
| GET | `/api/v1/resource-categories` | JWT | Permisos: resource_categories:read | Listar categorías de recursos activas | ResourceCategoriesService.findAll() | `src/resources/resource-categories.controller.ts` |
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
| GET | `/api/v1/admin/support/reports` | JWT | Global: admin, coordinator | Listar reportes de soporte | SupportService.listReports() | `src/support/support-admin.controller.ts` |
| GET | `/api/v1/admin/support/reports/:reportId` | JWT | Global: admin, coordinator | Obtener detalle de un reporte de soporte | SupportService.getReport() | `src/support/support-admin.controller.ts` |
| PATCH | `/api/v1/admin/support/reports/:reportId/status` | JWT | Global: admin, coordinator | Actualizar estado de un reporte de soporte | SupportService.updateReportStatus() | `src/support/support-admin.controller.ts` |

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
| POST | `/api/v1/clubs/:clubId/units/:unitId/weekly-records` | JWT | Permisos: units:update | Crear registro semanal | UnitsService.createWeeklyRecord() | `src/units/units.controller.ts` |
| POST | `/api/v1/clubs/:clubId/units/:unitId/weekly-records/bulk` | JWT | Permisos: units:update | Crear o actualizar registros semanales de forma atómica | UnitsService.bulkUpsertWeeklyRecords() | `src/units/units.controller.ts` |
| PATCH | `/api/v1/clubs/:clubId/units/:unitId/weekly-records/:recordId` | JWT | Permisos: units:update | Actualizar registro semanal | UnitsService.updateWeeklyRecord() | `src/units/units.controller.ts` |

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
| POST | `/api/v1/validation/submit` | JWT | Permisos: validation:submit | Enviar clase/honor a revision | ValidationService.submitForReview() | `src/validation/validation.controller.ts` |
| POST | `/api/v1/validation/:entityType/:entityId/review` | JWT | Permisos: validation:review | Aprobar o rechazar clase/honor | ValidationService.review() | `src/validation/validation.controller.ts` |
| GET | `/api/v1/validation/pending` | JWT | Permisos: validation:read | Listar items pendientes de revision | ValidationService.getPendingReviews() | `src/validation/validation.controller.ts` |
| GET | `/api/v1/validation/:entityType/:entityId/history` | JWT | Permisos: validation:read | Historial de validacion | ValidationService.getValidationHistory() | `src/validation/validation.controller.ts` |
| GET | `/api/v1/validation/eligibility/:userId` | JWT | Permisos: validation:read | Verificar elegibilidad para investidura | ValidationService.checkInvestmentEligibility() | `src/validation/validation.controller.ts` |

### year-end

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/year-end/:yearId/preview` | JWT | Global: admin, super-admin | Vista previa del impacto de cierre de ano | YearEndService.previewClosureImpact() | `src/year-end/year-end.controller.ts` |
| POST | `/api/v1/year-end/:yearId/close` | JWT | Global: admin, super-admin | Cerrar ano eclesiastico | YearEndService.closeYear() | `src/year-end/year-end.controller.ts` |

## Nota de mantenimiento

- Si cambia un controller, regenerar esta referencia contra `sacdia-backend/src/**/*controller.ts`.
- No confiar en conteos editoriales antiguos: el conteo vigente debe salir del mismo extractor que produce esta tabla.
