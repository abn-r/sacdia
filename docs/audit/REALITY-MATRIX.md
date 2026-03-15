# Reality Matrix — SACDIA
Fecha: 2026-03-14

## Resumen

| Categoria | Total | ALINEADO | SIN CANON | SIN DOCS | FANTASMA | PARCIAL | DRIFT |
|-----------|-------|----------|-----------|----------|----------|---------|-------|
| Endpoints | 223 | 168 | 21 | 17 | 17 | — | 0 |
| Modelos | 72 | 24 | 41 | 7 | 0 | — | 0 |
| Features | 16 | 8 | 2 | 0 | 1 | 5 | 0 |
| Integraciones | 7 | 4 | 1 | 1 | 1 | — | 0 |

**Fuentes de verdad cruzadas**:
- Codigo: `backend-audit.md` (198 endpoints, 72 modelos, 22 modulos), `admin-audit.md` (37 pages), `app-audit.md` (55 screens)
- Documentacion API: `ENDPOINTS-LIVE-REFERENCE.md` (180 endpoints documentados)
- Schema: `schema.prisma` (72 modelos), `SCHEMA-REFERENCE.md`
- Canon: `dominio-sacdia.md`, `runtime-sacdia.md`, `arquitectura-sacdia.md`, `decisiones-clave.md`, `auth/modelo-autorizacion.md`, `auth/runtime-auth.md`

---

## Tabla 1: Endpoints

Convenciones:
- **Implementado**: existe en backend-audit.md (codigo real)
- **Doc API**: existe en ENDPOINTS-LIVE-REFERENCE.md
- **Canon**: la capacidad/dominio del endpoint esta mencionada en documentos canon

### auth

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| GET `/` | Si | Si | No | SIN CANON |
| GET `/health` | Si | Si | Si | ALINEADO |
| POST `/auth/register` | Si | Si | Si | ALINEADO |
| POST `/auth/login` | Si | Si | Si | ALINEADO |
| POST `/auth/refresh` | Si | Si | Si | ALINEADO |
| POST `/auth/logout` | Si | Si | Si | ALINEADO |
| POST `/auth/password/reset-request` | Si | Si | Si | ALINEADO |
| GET `/auth/me` | Si | Si | Si | ALINEADO |
| PATCH `/auth/me/context` | Si | Si | Si | ALINEADO |
| GET `/auth/profile/completion-status` | Si | Si | Si | ALINEADO |
| GET `/auth/sessions` | Si | Si | Si | ALINEADO |
| DELETE `/auth/sessions/:sessionId` | Si | Si | Si | ALINEADO |
| DELETE `/auth/sessions` | Si | Si | Si | ALINEADO |
| POST `/auth/oauth/google` | Si | Si | Si | ALINEADO |
| POST `/auth/oauth/apple` | Si | Si | Si | ALINEADO |
| GET `/auth/oauth/callback` | Si | Si | Si | ALINEADO |
| GET `/auth/oauth/providers` | Si | Si | Si | ALINEADO |
| DELETE `/auth/oauth/:provider` | Si | Si | Si | ALINEADO |
| POST `/auth/mfa/enroll` | Si | Si | Si | ALINEADO |
| POST `/auth/mfa/verify` | Si | Si | Si | ALINEADO |
| GET `/auth/mfa/factors` | Si | Si | Si | ALINEADO |
| DELETE `/auth/mfa/unenroll` | Si | Si | Si | ALINEADO |
| GET `/auth/mfa/status` | Si | Si | Si | ALINEADO |

### users

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| GET `/users/:userId` | Si | Si | Si | ALINEADO |
| GET `/users/:userId/allergies` | Si | Si | Si | ALINEADO |
| GET `/users/:userId/diseases` | Si | Si | Si | ALINEADO |
| GET `/users/:userId/medicines` | Si | Si | Si | ALINEADO |
| PATCH `/users/:userId` | Si | Si | Si | ALINEADO |
| PUT `/users/:userId/allergies` | Si | Si | Si | ALINEADO |
| PUT `/users/:userId/diseases` | Si | Si | Si | ALINEADO |
| PUT `/users/:userId/medicines` | Si | Si | Si | ALINEADO |
| DELETE `/users/:userId/allergies/:allergyId` | Si | Si | Si | ALINEADO |
| DELETE `/users/:userId/diseases/:diseaseId` | Si | Si | Si | ALINEADO |
| DELETE `/users/:userId/medicines/:medicineId` | Si | Si | Si | ALINEADO |
| POST `/users/:userId/profile-picture` | Si | Si | Si | ALINEADO |
| DELETE `/users/:userId/profile-picture` | Si | Si | Si | ALINEADO |
| GET `/users/:userId/age` | Si | Si | Si | ALINEADO |
| GET `/users/:userId/requires-legal-representative` | Si | Si | Si | ALINEADO |

### users — honors

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| GET `/users/:userId/honors` | Si | Si | Si | ALINEADO |
| GET `/users/:userId/honors/stats` | Si | Si | Si | ALINEADO |
| POST `/users/:userId/honors` | Si | No | Si | SIN DOCS |
| POST `/users/:userId/honors/bulk` | Si | No | No | SIN DOCS |
| POST `/users/:userId/honors/:honorId/files` | Si | No | No | SIN DOCS |
| POST `/users/:userId/honors/:honorId` | Si | Si | Si | ALINEADO |
| PATCH `/users/:userId/honors/:honorId` | Si | Si | Si | ALINEADO |
| DELETE `/users/:userId/honors/:honorId` | Si | Si | Si | ALINEADO |

### emergency-contacts

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| POST `/users/:userId/emergency-contacts` | Si | Si | Si | ALINEADO |
| GET `/users/:userId/emergency-contacts` | Si | Si | Si | ALINEADO |
| GET `/users/:userId/emergency-contacts/:contactId` | Si | Si | Si | ALINEADO |
| PATCH `/users/:userId/emergency-contacts/:contactId` | Si | Si | Si | ALINEADO |
| DELETE `/users/:userId/emergency-contacts/:contactId` | Si | Si | Si | ALINEADO |

### legal-representatives

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| POST `/users/:userId/legal-representative` | Si | Si | Si | ALINEADO |
| GET `/users/:userId/legal-representative` | Si | Si | Si | ALINEADO |
| PATCH `/users/:userId/legal-representative` | Si | Si | Si | ALINEADO |
| DELETE `/users/:userId/legal-representative` | Si | Si | Si | ALINEADO |

### post-registration

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| GET `/users/:userId/post-registration/status` | Si | Si | Si | ALINEADO |
| POST `/users/:userId/post-registration/step-1/complete` | Si | Si | Si | ALINEADO |
| POST `/users/:userId/post-registration/step-2/complete` | Si | Si | Si | ALINEADO |
| POST `/users/:userId/post-registration/step-3/complete` | Si | Si | Si | ALINEADO |

### clubs

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| GET `/clubs` | Si | Si | Si | ALINEADO |
| GET `/clubs/:clubId` | Si | Si | Si | ALINEADO |
| POST `/clubs` | Si | Si | Si | ALINEADO |
| PATCH `/clubs/:clubId` | Si | Si | Si | ALINEADO |
| DELETE `/clubs/:clubId` | Si | Si | Si | ALINEADO |
| GET `/clubs/:clubId/instances` | Si | Si | Si | ALINEADO |
| GET `/clubs/:clubId/instances/:type` | Si | Si | Si | ALINEADO |
| POST `/clubs/:clubId/instances` | Si | Si | Si | ALINEADO |
| PATCH `/clubs/:clubId/instances/:type/:instanceId` | Si | Si | Si | ALINEADO |
| GET `/clubs/:clubId/instances/:type/:instanceId/members` | Si | Si | Si | ALINEADO |
| POST `/clubs/:clubId/instances/:type/:instanceId/roles` | Si | Si | Si | ALINEADO |

### club-roles

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| PATCH `/club-roles/:assignmentId` | Si | Si | Si | ALINEADO |
| DELETE `/club-roles/:assignmentId` | Si | Si | Si | ALINEADO |

### honors (catalogo)

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| GET `/honors` | Si | Si | Si | ALINEADO |
| GET `/honors/categories` | Si | Si | Si | ALINEADO |
| GET `/honors/grouped-by-category` | Si | No | Si | SIN DOCS |
| GET `/honors/:honorId` | Si | Si | Si | ALINEADO |

### activities

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| GET `/clubs/:clubId/activities` | Si | Si | Si | ALINEADO |
| POST `/clubs/:clubId/activities` | Si | Si | Si | ALINEADO |
| GET `/activities/:activityId` | Si | Si | Si | ALINEADO |
| PATCH `/activities/:activityId` | Si | Si | Si | ALINEADO |
| DELETE `/activities/:activityId` | Si | Si | Si | ALINEADO |
| POST `/activities/:activityId/attendance` | Si | Si | Si | ALINEADO |
| GET `/activities/:activityId/attendance` | Si | Si | Si | ALINEADO |

### finances

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| GET `/finances/categories` | Si | Si | Si | ALINEADO |
| GET `/clubs/:clubId/finances` | Si | Si | Si | ALINEADO |
| GET `/clubs/:clubId/finances/summary` | Si | Si | Si | ALINEADO |
| POST `/clubs/:clubId/finances` | Si | Si | Si | ALINEADO |
| GET `/finances/:financeId` | Si | Si | Si | ALINEADO |
| PATCH `/finances/:financeId` | Si | Si | Si | ALINEADO |
| DELETE `/finances/:financeId` | Si | Si | Si | ALINEADO |

### admin — RBAC

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| GET `/admin/rbac/permissions` | Si | Si | Si | ALINEADO |
| GET `/admin/rbac/permissions/:id` | Si | Si | Si | ALINEADO |
| POST `/admin/rbac/permissions` | Si | Si | Si | ALINEADO |
| PATCH `/admin/rbac/permissions/:id` | Si | Si | Si | ALINEADO |
| DELETE `/admin/rbac/permissions/:id` | Si | Si | Si | ALINEADO |
| GET `/admin/rbac/roles` | Si | Si | Si | ALINEADO |
| GET `/admin/rbac/roles/:id` | Si | Si | Si | ALINEADO |
| POST `/admin/rbac/roles/:id/permissions` | Si | Si | Si | ALINEADO |
| PUT `/admin/rbac/roles/:id/permissions` | Si | Si | Si | ALINEADO |
| DELETE `/admin/rbac/roles/:id/permissions/:permissionId` | Si | Si | Si | ALINEADO |

### notifications

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| POST `/notifications/send` | Si | Si | Si | ALINEADO |
| POST `/notifications/broadcast` | Si | Si | Si | ALINEADO |
| POST `/notifications/club/:instanceType/:instanceId` | Si | Si | Si | ALINEADO |

### fcm-tokens

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| POST `/fcm-tokens` | Si | Si | Si | ALINEADO |
| DELETE `/fcm-tokens/:token` | Si | Si | Si | ALINEADO |
| GET `/fcm-tokens` | Si | Si | Si | ALINEADO |
| GET `/fcm-tokens/user/:userId` | Si | Si | Si | ALINEADO |

### camporees

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| GET `/camporees` | Si | Si | Si | ALINEADO |
| GET `/camporees/:camporeeId` | Si | Si | Si | ALINEADO |
| POST `/camporees` | Si | Si | Si | ALINEADO |
| PATCH `/camporees/:camporeeId` | Si | Si | Si | ALINEADO |
| DELETE `/camporees/:camporeeId` | Si | Si | Si | ALINEADO |
| POST `/camporees/:camporeeId/register` | Si | Si | Si | ALINEADO |
| GET `/camporees/:camporeeId/members` | Si | Si | Si | ALINEADO |
| DELETE `/camporees/:camporeeId/members/:userId` | Si | Si | Si | ALINEADO |

### catalogs

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| GET `/catalogs/club-types` | Si | Si | Si | ALINEADO |
| GET `/catalogs/activity-types` | Si | No | No | SIN DOCS |
| GET `/catalogs/relationship-types` | Si | Si | No | SIN CANON |
| GET `/catalogs/countries` | Si | Si | Si | ALINEADO |
| GET `/catalogs/unions` | Si | Si | Si | ALINEADO |
| GET `/catalogs/local-fields` | Si | Si | Si | ALINEADO |
| GET `/catalogs/districts` | Si | Si | Si | ALINEADO |
| GET `/catalogs/churches` | Si | Si | Si | ALINEADO |
| GET `/catalogs/roles` | Si | Si | Si | ALINEADO |
| GET `/catalogs/ecclesiastical-years` | Si | Si | Si | ALINEADO |
| GET `/catalogs/ecclesiastical-years/current` | Si | Si | Si | ALINEADO |
| GET `/catalogs/club-ideals` | Si | Si | No | SIN CANON |
| GET `/catalogs/allergies` | Si | Si | No | SIN CANON |
| GET `/catalogs/diseases` | Si | Si | No | SIN CANON |

### certifications

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| GET `/certifications/certifications` | Si | Si | Si | ALINEADO |
| GET `/certifications/certifications/:id` | Si | Si | Si | ALINEADO |
| POST `/certifications/users/:userId/certifications/enroll` | Si | Si | Si | ALINEADO |
| GET `/certifications/users/:userId/certifications` | Si | Si | Si | ALINEADO |
| GET `/certifications/users/:userId/certifications/:certificationId/progress` | Si | Si | Si | ALINEADO |
| PATCH `/certifications/users/:userId/certifications/:certificationId/progress` | Si | Si | Si | ALINEADO |
| DELETE `/certifications/users/:userId/certifications/:certificationId` | Si | Si | Si | ALINEADO |

### inventory

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| GET `/inventory/clubs/:clubId/inventory` | Si | Si | Si | ALINEADO |
| GET `/inventory/inventory/:id` | Si | Si | Si | ALINEADO |
| POST `/inventory/clubs/:clubId/inventory` | Si | Si | Si | ALINEADO |
| PATCH `/inventory/inventory/:id` | Si | Si | Si | ALINEADO |
| DELETE `/inventory/inventory/:id` | Si | Si | Si | ALINEADO |
| GET `/inventory/catalogs/inventory-categories` | Si | Si | Si | ALINEADO |

### folders

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| GET `/folders/folders` | Si | Si | Si | ALINEADO |
| GET `/folders/folders/:id` | Si | Si | Si | ALINEADO |
| POST `/folders/users/:userId/folders/:folderId/enroll` | Si | Si | Si | ALINEADO |
| GET `/folders/users/:userId/folders` | Si | Si | Si | ALINEADO |
| GET `/folders/users/:userId/folders/:folderId/progress` | Si | Si | Si | ALINEADO |
| PATCH `/folders/users/:userId/folders/:folderId/modules/:moduleId/sections/:sectionId` | Si | Si | Si | ALINEADO |
| DELETE `/folders/users/:userId/folders/:folderId` | Si | Si | Si | ALINEADO |

### admin — reference (catalogos admin)

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| GET `/admin/relationship-types` | Si | Si | No | SIN CANON |
| POST `/admin/relationship-types` | Si | Si | No | SIN CANON |
| PATCH `/admin/relationship-types/:relationshipTypeId` | Si | Si | No | SIN CANON |
| DELETE `/admin/relationship-types/:relationshipTypeId` | Si | Si | No | SIN CANON |
| GET `/admin/allergies` | Si | Si | No | SIN CANON |
| POST `/admin/allergies` | Si | Si | No | SIN CANON |
| PATCH `/admin/allergies/:allergyId` | Si | Si | No | SIN CANON |
| DELETE `/admin/allergies/:allergyId` | Si | Si | No | SIN CANON |
| GET `/admin/diseases` | Si | Si | No | SIN CANON |
| POST `/admin/diseases` | Si | Si | No | SIN CANON |
| PATCH `/admin/diseases/:diseaseId` | Si | Si | No | SIN CANON |
| DELETE `/admin/diseases/:diseaseId` | Si | Si | No | SIN CANON |
| GET `/admin/medicines` | Si | No | No | SIN DOCS |
| POST `/admin/medicines` | Si | No | No | SIN DOCS |
| PATCH `/admin/medicines/:medicineId` | Si | No | No | SIN DOCS |
| DELETE `/admin/medicines/:medicineId` | Si | No | No | SIN DOCS |
| GET `/admin/ecclesiastical-years` | Si | Si | No | SIN CANON |
| POST `/admin/ecclesiastical-years` | Si | Si | No | SIN CANON |
| PATCH `/admin/ecclesiastical-years/:yearId` | Si | Si | No | SIN CANON |
| DELETE `/admin/ecclesiastical-years/:yearId` | Si | Si | No | SIN CANON |

### admin — geography

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| GET `/admin/countries` | Si | Si | Si | ALINEADO |
| POST `/admin/countries` | Si | Si | Si | ALINEADO |
| PATCH `/admin/countries/:countryId` | Si | Si | Si | ALINEADO |
| DELETE `/admin/countries/:countryId` | Si | Si | Si | ALINEADO |
| GET `/admin/unions` | Si | Si | Si | ALINEADO |
| POST `/admin/unions` | Si | Si | Si | ALINEADO |
| PATCH `/admin/unions/:unionId` | Si | Si | Si | ALINEADO |
| DELETE `/admin/unions/:unionId` | Si | Si | Si | ALINEADO |
| GET `/admin/local-fields` | Si | Si | Si | ALINEADO |
| POST `/admin/local-fields` | Si | Si | Si | ALINEADO |
| PATCH `/admin/local-fields/:localFieldId` | Si | Si | Si | ALINEADO |
| DELETE `/admin/local-fields/:localFieldId` | Si | Si | Si | ALINEADO |
| GET `/admin/districts` | Si | Si | Si | ALINEADO |
| POST `/admin/districts` | Si | Si | Si | ALINEADO |
| PATCH `/admin/districts/:districtId` | Si | Si | Si | ALINEADO |
| DELETE `/admin/districts/:districtId` | Si | Si | Si | ALINEADO |
| GET `/admin/churches` | Si | Si | Si | ALINEADO |
| POST `/admin/churches` | Si | Si | Si | ALINEADO |
| PATCH `/admin/churches/:churchId` | Si | Si | Si | ALINEADO |
| DELETE `/admin/churches/:churchId` | Si | Si | Si | ALINEADO |

### admin — users

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| GET `/admin/users` | Si | Si | Si | ALINEADO |
| GET `/admin/users/:userId` | Si | Si | Si | ALINEADO |

### classes

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| GET `/classes` | Si | Si | Si | ALINEADO |
| GET `/classes/:classId` | Si | Si | Si | ALINEADO |
| GET `/classes/:classId/modules` | Si | Si | Si | ALINEADO |
| GET `/users/:userId/classes` | Si | Si | Si | ALINEADO |
| POST `/users/:userId/classes/enroll` | Si | Si | Si | ALINEADO |
| GET `/users/:userId/classes/:classId/progress` | Si | Si | Si | ALINEADO |
| PATCH `/users/:userId/classes/:classId/progress` | Si | Si | Si | ALINEADO |

### Endpoints FANTASMA (documentados pero no implementados)

Estos endpoints son consumidos por el admin o la app pero NO existen en el backend audit:

| Endpoint | Consumidor | Doc API | Canon | Estado | Nota |
|----------|:---:|:---:|:---:|---|---|
| PATCH `/admin/users/:userId/approval` | Admin | No | No | FANTASMA | Usado en admin-audit pero no en backend-audit ni en ENDPOINTS-LIVE-REFERENCE |
| PATCH `/admin/users/:userId` | Admin | No | No | FANTASMA | Usado en admin-audit como fallback de approval |
| GET `/admin/honor-categories` | Admin | No | No | FANTASMA | Usado en admin-audit (CRUD completo) pero no en backend-audit |
| POST `/admin/honor-categories` | Admin | No | No | FANTASMA | Idem |
| PATCH `/admin/honor-categories/:id` | Admin | No | No | FANTASMA | Idem |
| DELETE `/admin/honor-categories/:id` | Admin | No | No | FANTASMA | Idem |
| GET `/admin/honor-categories/:id` | Admin | No | No | FANTASMA | Idem |
| GET `/admin/club-ideals` | Admin | No | No | FANTASMA | Usado en admin-audit como read-only pero no en backend-audit |
| POST `/auth/update-password` | App | No | No | FANTASMA | Llamado por app pero no en backend-audit |

### Endpoints SIN DOCS consumidos por app (no en ENDPOINTS-LIVE-REFERENCE)

| Endpoint | Consumidor | Implementado | Doc API | Canon | Estado | Nota |
|----------|:---:|:---:|:---:|:---:|---|---|
| POST `/auth/pr-check` | App | Si? | No | No | SIN DOCS | Usado por app auth datasource |
| GET `/users/:userId/post-registration/photo-status` | App | Si? | No | No | SIN DOCS | Usado por app post_registration |
| PATCH `/emergency-contacts/:contactId` | App | Si? | No | No | SIN DOCS | App usa ruta diferente a backend (backend: `/users/:userId/emergency-contacts/:contactId`) |
| DELETE `/emergency-contacts/:contactId` | App | Si? | No | No | SIN DOCS | Idem |
| GET `/clubs/:clubId/instances/:instanceType/:instanceId` | App | Si? | No | Si | SIN DOCS | App club datasource; similar a documented route but with explicit instance return |
| PATCH `/clubs/:clubId/instances/:instanceType/:instanceId` | App | Si? | No | Si | SIN DOCS | Idem |
| GET `/club-instances/:id/evidence-folder` | App | No | No | No | FANTASMA | Evidence folder endpoints no existen en backend-audit |
| POST `/club-instances/:id/evidence-folder/sections/:sectionId/submit` | App | No | No | No | FANTASMA? | Idem |
| POST `/club-instances/:id/evidence-folder/sections/:sectionId/files` | App | No | No | No | FANTASMA? | Idem |
| DELETE `/club-instances/:id/evidence-folder/sections/:sectionId/files/:fileId` | App | No | No | No | FANTASMA? | Idem |
| POST `/users/:userId/classes/:classId/sections/:requirementId/files` | App | No | No | No | SIN DOCS | App classes datasource, file upload |
| DELETE `/users/:userId/classes/:classId/sections/:requirementId/files/:fileId` | App | No | No | No | SIN DOCS | App classes datasource, file delete |
| GET `/clubs/:clubId/instances/:type/:instanceId/members/insurance` | App | No | No | No | FANTASMA? | Insurance listing per instance |
| GET `/users/:memberId/insurance` | App | No | No | No | FANTASMA? | User insurance detail |
| POST `/users/:memberId/insurance` | App | No | No | No | FANTASMA? | Create insurance |
| PATCH `/insurance/:insuranceId` | App | No | No | No | FANTASMA? | Update insurance |

> **Nota**: Los endpoints marcados "FANTASMA?" pueden existir en backend no capturados en la auditoria o estar planificados. La app los consume pero no se encontraron en el backend-audit de 198 endpoints.

---

## Tabla 2: Modelos de Datos

Convenciones:
- **schema.prisma**: existe como `model` en el archivo prisma en docs/
- **SCHEMA-REFERENCE**: documentado en SCHEMA-REFERENCE.md
- **Canon**: mencionado o su concepto de dominio referenciado en documentos canon

| Model | schema.prisma | SCHEMA-REFERENCE | Canon | Estado |
|-------|:---:|:---:|:---:|---|
| activities | Si | No | Si | SIN DOCS |
| activity_types | Si (backend-audit) | No | No | SIN DOCS |
| activity_instances | Si (backend-audit) | No | No | SIN DOCS |
| folder_assignments | Si | No | No | SIN CANON |
| camporee_clubs | Si | No | No | SIN CANON |
| camporee_members | Si | No | No | SIN CANON |
| churches | Si | Si | Si | ALINEADO |
| class_module_progress | Si | Si | Si | ALINEADO |
| class_modules | Si | No | No | SIN CANON |
| class_section_progress | Si | Si | Si | ALINEADO |
| class_sections | Si | No | No | SIN CANON |
| classes | Si | Si | Si | ALINEADO |
| club_ideals | Si | No | No | SIN CANON |
| club_inventory | Si | No | No | SIN CANON |
| club_types | Si | No | Si | SIN DOCS |
| clubs | Si | Si | Si | ALINEADO |
| club_adventurers | Si | Si | Si | ALINEADO |
| club_pathfinders | Si | Si | Si | ALINEADO |
| club_master_guilds | Si | Si | Si | ALINEADO |
| club_role_assignments | Si | Si | Si | ALINEADO |
| countries | Si | Si | Si | ALINEADO |
| districts | Si | Si | Si | ALINEADO |
| ecclesiastical_years | Si | No | Si | SIN DOCS |
| enrollments | Si | Si | Si | ALINEADO |
| error_logs | Si | No | No | SIN CANON |
| finances | Si | No | Si | SIN DOCS |
| finances_categories | Si | No | No | SIN CANON |
| folders | Si | No | Si | SIN CANON |
| folders_modules | Si | No | No | SIN CANON |
| folders_modules_records | Si | No | No | SIN CANON |
| folders_section_records | Si | No | No | SIN CANON |
| folders_sections | Si | No | No | SIN CANON |
| honors | Si | Si | Si | ALINEADO |
| honors_categories | Si | No | No | SIN CANON |
| inventory_categories | Si | No | No | SIN CANON |
| local_camporees | Si | No | No | SIN CANON |
| local_fields | Si | Si | Si | ALINEADO |
| master_honors | Si | No | No | SIN CANON |
| permissions | Si | Si | Si | ALINEADO |
| role_permissions | Si | Si | Si | ALINEADO |
| roles | Si | Si | Si | ALINEADO |
| union_camporee_local_fields | Si | No | No | SIN CANON |
| union_camporees | Si | No | No | SIN CANON |
| unions | Si | Si | Si | ALINEADO |
| unit_members | Si | No | No | SIN CANON |
| units | Si | No | No | SIN CANON |
| users | Si | Si | Si | ALINEADO |
| user_fcm_tokens | Si | No | No | SIN CANON |
| users_pr | Si | Si | Si | ALINEADO |
| users_classes | Si | Si | Si | ALINEADO |
| certifications | Si | No | Si | SIN DOCS |
| certification_modules | Si | No | No | SIN CANON |
| certification_sections | Si | No | No | SIN CANON |
| users_certifications | Si | No | No | SIN CANON |
| certification_module_progress | Si | No | No | SIN CANON |
| certification_section_progress | Si | No | No | SIN CANON |
| member_insurances | Si | No | No | SIN CANON |
| investiture_validation_history | Si | No | No | SIN CANON |
| investiture_config | Si | No | No | SIN CANON |
| diseases | Si | No | No | SIN CANON |
| allergies | Si | No | No | SIN CANON |
| emergency_contacts | Si | Si | Si | ALINEADO |
| weekly_records | Si | No | No | SIN CANON |
| users_allergies | Si | No | No | SIN CANON |
| users_diseases | Si | No | No | SIN CANON |
| users_medicines | Si | No | No | SIN CANON |
| users_honors | Si | No | No | SIN CANON |
| users_permissions | Si | No | No | SIN CANON |
| users_roles | Si | Si | Si | ALINEADO |
| medicines | Si | No | No | SIN CANON |
| relationship_types | Si | No | No | SIN CANON |
| legal_representatives | Si | Si | Si | ALINEADO |

### Conteos modelos

- **ALINEADO**: 24 (schema.prisma + SCHEMA-REFERENCE + Canon)
- **SIN CANON**: 41 (en schema.prisma pero sin mencion canon ni SCHEMA-REFERENCE significativa)
- **SIN DOCS**: 7 (en schema.prisma y con concepto en canon pero sin SCHEMA-REFERENCE)
- **FANTASMA**: 0
- **DRIFT**: 0

> **Nota**: SCHEMA-REFERENCE.md solo documenta ~25 tablas principales. Las 72 tablas del schema.prisma incluyen muchas tablas pivote, auxiliares y de tracking que nunca se documentaron en SCHEMA-REFERENCE. Canon menciona dominios pero no tablas individuales; la columna Canon refleja si el concepto de negocio detras de la tabla esta mencionado en documentos canon.

---

## Tabla 3: Modulos/Features

Convenciones:
- **Backend Module**: existe como modulo NestJS en backend-audit
- **Admin Pages**: tiene paginas funcionales en admin-audit
- **App Screens**: tiene screens en app-audit
- **Canon Domain**: dominio descrito en documentos canon
- **Estado**: ALINEADO (todas las capas relevantes presentes), PARCIAL (algunas capas faltantes), FANTASMA (canon-only), SIN CANON (code-only)

| Dominio | Backend Module | Admin Pages | App Screens | Canon Domain | Estado |
|---------|:---:|:---:|:---:|:---:|---|
| auth | Si (AuthModule) | Si (login) | Si (auth, 5 screens) | Si (auth/) | ALINEADO |
| gestion-clubs (clubes, secciones, cargos) | Si (ClubsModule) | Si (clubs, 3 pages) | Si (club, members, units) | Si (dominio, runtime) | ALINEADO |
| clases-progresivas | Si (ClassesModule) | Si (read-only) | Si (classes, 6 screens) | Si (formacion/trayectoria) | ALINEADO |
| honores | Si (HonorsModule) | Si (honors, CRUD) | Si (honors, 4 screens) | Si (formacion) | ALINEADO |
| actividades | Si (ActivitiesModule) | Placeholder | Si (activities, 4 screens) | Si (runtime 6.6) | PARCIAL |
| finanzas | Si (FinancesModule) | Placeholder | Si (finances, 3 screens) | Si (runtime 6.6) | PARCIAL |
| catalogos | Si (CatalogsModule, AdminModule) | Si (catalogs, 13 pages) | Si (shared catalogs) | Si (runtime 6.5) | ALINEADO |
| camporees | Si (CamporeesModule) | Si (read-only) | No | Si (runtime 6.6) | PARCIAL |
| communications (notificaciones) | Si (NotificationsModule) | Si (notifications, 1 page) | No (consume FCM tokens) | Si (runtime 6.6) | ALINEADO |
| certificaciones-guias-mayores | Si (CertificationsModule) | Si (read-only) | No | Si (formacion) | PARCIAL |
| inventario | Si (InventoryModule) | Placeholder | Si (inventory, 4 screens) | Si (runtime 6.6) | PARCIAL |
| gestion-seguros (insurance) | No backend module | Placeholder | Si (insurance, 3 screens) | No | SIN CANON |
| carpetas-evidencias (folders) | Si (FoldersModule) | Si (read-only) | Si (evidence_folder, 2 screens) | Si (formacion) | ALINEADO |
| rbac (permisos/roles) | Si (RbacModule) | Si (rbac, 3 pages) | No | Si (auth/) | ALINEADO |
| infrastructure (health, logging) | Si (CommonModule, AppModule) | No | No | Si (runtime 6.7) | SIN CANON |
| validacion-investiduras | No backend module | No | No | Si (dominio: validacion) | FANTASMA |

### Conteos features

- **ALINEADO**: 8
- **PARCIAL**: 5
- **SIN CANON**: 2
- **FANTASMA**: 1
- **DRIFT**: 0

> **Notas**:
> - **actividades**: Backend completo, app completa, admin es placeholder.
> - **finanzas**: Backend completo, app completa, admin es placeholder.
> - **inventario**: Backend completo, app completa, admin es placeholder.
> - **camporees**: Backend y admin (read-only), app no tiene screens.
> - **certificaciones-guias-mayores**: Backend y admin (read-only), app no tiene screens.
> - **gestion-seguros**: App tiene screens completas con datasource, pero backend-audit no muestra un InsuranceModule dedicado. Las tablas `member_insurances` existen en schema.prisma.
> - **validacion-investiduras**: Canon describe validacion e investidura como actos institucionales. Existen tablas (`investiture_validation_history`, `investiture_config`, `enrollments` con `investiture_status_enum`) pero no hay modulo backend, endpoints, pages ni screens dedicados.

---

## Tabla 4: Integraciones Externas

| Service | Configurado | Usado Activamente | Documentado | Estado |
|---------|:---:|:---:|:---:|---|
| Supabase Auth | Si | Si | Si (canon, runtime) | ALINEADO |
| Firebase Admin (FCM) | Si (condicional) | Si | Si (runtime 9) | ALINEADO |
| Sentry | Si (condicional) | Si | No | SIN CANON |
| Redis / Upstash | Si (condicional) | Si | Si (runtime 9) | ALINEADO |
| Cloudflare R2 (S3) | Si | Si | No en canon | SIN DOCS |
| Supabase Storage | No en backend | No detectado en uso | Si (runtime 9, baseline tecnica) | FANTASMA |
| NestJS Cache Manager | Si | Si | Si (parte de Redis stack) | ALINEADO |

### Conteos integraciones

- **ALINEADO**: 4
- **SIN CANON**: 1 (Sentry — configurado y activo pero no en canon)
- **SIN DOCS**: 1 (Cloudflare R2 — usado activamente pero canon documenta "Supabase Storage")
- **FANTASMA**: 1 (Supabase Storage — documentado en canon pero reemplazado por R2 en runtime real)
- **DRIFT**: 0

> **Nota critica**: Canon y baseline tecnica documentan "Supabase Storage" como servicio de archivos, pero el backend real usa Cloudflare R2 (S3-compatible) via `R2FileStorageService`. Esto es un **reemplazo no documentado en canon**.

---

## Hallazgos Destacados

### 1. Gap de documentacion API (18 endpoints)
ENDPOINTS-LIVE-REFERENCE.md documenta 180 endpoints vs 198 en backend. Los 18 endpoints faltantes son:
- 4 endpoints de `/admin/medicines` (CRUD completo sin docs)
- 3 endpoints de user honors (`POST bulk`, `POST files`, `POST register`)
- 1 endpoint `GET /honors/grouped-by-category`
- 1 endpoint `GET /catalogs/activity-types`
- Varios endpoints consumidos por app con rutas alternativas

### 2. Endpoints fantasma del admin panel (9 endpoints)
El admin panel consume 9 endpoints que no existen en el backend-audit:
- CRUD completo de `/admin/honor-categories` (5 endpoints)
- `PATCH /admin/users/:userId/approval` y `PATCH /admin/users/:userId`
- `GET /admin/club-ideals`
- `POST /auth/update-password`

### 3. Evidence folder y insurance: app sin backend
La app tiene screens completas para evidence folders y insurance, pero los endpoints que consume (`/club-instances/*`, `/users/:memberId/insurance`, etc.) no aparecen en el backend audit de 198 endpoints.

### 4. SCHEMA-REFERENCE desactualizado
SCHEMA-REFERENCE.md solo documenta ~25 de 72 tablas. Falta documentacion para toda la capa de certificaciones, folders, camporees, inventario, seguros, investiduras y muchas tablas auxiliares.

### 5. Storage drift: R2 vs Supabase Storage
Canon documenta Supabase Storage pero el backend usa Cloudflare R2. Necesita actualizacion de canon.

### 6. Canon no cubre operaciones administrativas de catalogos
Los 16+ endpoints de CRUD admin para alergias, enfermedades, tipos de relacion, anos eclesiasticos, etc. estan implementados y documentados en API docs pero no son mencionados como capacidad en ningun documento canon.

### 7. Validacion de investiduras: tablas sin runtime
Existen las tablas `investiture_validation_history`, `investiture_config` y el enum `investiture_status_enum` en schema.prisma, pero no hay endpoints, pages ni screens que los expongan. Canon describe validacion como acto institucional clave pero no hay implementacion visible.
