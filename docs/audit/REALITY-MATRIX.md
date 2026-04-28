# Reality Matrix — SACDIA
Fecha: 2026-03-26 | Última actualización: 2026-04-17

## Resumen

| Categoria | Total | ALINEADO | SIN CANON | SIN DOCS | FANTASMA | PARCIAL | DRIFT |
|-----------|-------|----------|-----------|----------|----------|---------|-------|
| Endpoints | 244 | 211 | 14 | 11 | 0 | — | 0 |
| Modelos | 76 | 36 | 40 | 0 | 0 | — | 0 |
| Features | 17 | 15 | 1 | 0 | 0 | 1 | 0 |
| Integraciones | 7 | 5 | 1 | 1 | 0 | — | 0 |

**Fuentes de verdad cruzadas**:
- Codigo: `backend-audit.md` (backends con InvestitureModule, InsurancesModule, EvidenceFolderController, ResourcesModule — ~269+ endpoints), `admin-audit.md` (37+ pages), `app-audit.md` (55+ screens)
- Documentacion API: `ENDPOINTS-LIVE-REFERENCE.md` (269 endpoints documentados, post-ResourcesModule 2026-03-26)
- Schema: `schema.prisma` (74 modelos + 8 enums), `SCHEMA-REFERENCE.md` (actualizado 2026-03-22: 74 modelos documentados)
- Canon: `dominio-sacdia.md`, `runtime-sacdia.md`, `arquitectura-sacdia.md`, `decisiones-clave.md`, `auth/modelo-autorizacion.md`, `auth/runtime-auth.md`

---

## Tabla 1: Endpoints

Convenciones:
- **Implementado**: existe en backend (codigo real)
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
| POST `/auth/update-password` | Si | Si | Si | ALINEADO |

> Nota: `POST /auth/update-password` implementado en commit 68af077 (2026-03-18). Era FANTASMA en Wave 0.

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
| POST `/users/:userId/honors` | Si | Si | Si | ALINEADO |
| POST `/users/:userId/honors/bulk` | Si | Si | No | SIN CANON |
| POST `/users/:userId/honors/:honorId/files` | Si | Si | No | SIN CANON |
| POST `/users/:userId/honors/:honorId` | Si | Si | Si | ALINEADO |
| PATCH `/users/:userId/honors/:honorId` | Si | Si | Si | ALINEADO |
| DELETE `/users/:userId/honors/:honorId` | Si | Si | Si | ALINEADO |
| GET `/users/:userId/honors/:honorId/requirements/progress` | Si | Si | No | SIN CANON |
| PATCH `/users/:userId/honors/:honorId/requirements/:requirementId/progress` | Si | Si | No | SIN CANON |
| PATCH `/users/:userId/honors/:honorId/requirements/progress/batch` | Si | Si | No | SIN CANON |

> Nota: endpoints de honors documentados en Wave 2 (ya no SIN DOCS). 2026-03-27: 3 endpoints de requirement progress agregados.

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
| GET `/clubs/:clubId/sections` | Si | Si | Si | ALINEADO |
| GET `/clubs/:clubId/sections/:sectionId` | Si | Si | Si | ALINEADO |
| POST `/clubs/:clubId/sections` | Si | Si | Si | ALINEADO |
| PATCH `/clubs/:clubId/sections/:sectionId` | Si | Si | Si | ALINEADO |
| DELETE `/clubs/:clubId/sections/:sectionId` | No | No | No | — |
| GET `/clubs/:clubId/sections/:sectionId/members` | Si | Si | Si | ALINEADO |
| POST `/clubs/:clubId/sections/:sectionId/roles` | Si | Si | Si | ALINEADO |

> Nota: `DELETE /clubs/:clubId/sections/:sectionId` removido como FANTASMA en Wave 2 — no existe en backend.

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
| GET `/honors/grouped-by-category` | Si | Si | Si | ALINEADO |
| GET `/honors/:honorId` | Si | Si | Si | ALINEADO |
| GET `/honors/:honorId/requirements` | Si | Si | No | SIN CANON |

> Nota: `GET /honors/grouped-by-category` documentado en Wave 2 (ya no SIN DOCS). 2026-03-27: requirements endpoint agregado.

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
| GET `/admin/rbac/users/:userId/permissions` | Si | No | Si | SIN DOCS |
| POST `/admin/rbac/users/:userId/permissions` | Si | No | Si | SIN DOCS |
| DELETE `/admin/rbac/users/:userId/permissions/:permissionId` | Si | No | Si | SIN DOCS |

### notifications

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| POST `/notifications/send` | Si | Si | Si | ALINEADO |
| POST `/notifications/broadcast` | Si | Si | Si | ALINEADO |
| POST `/notifications/club/:sectionId` | Si | Si | Si | ALINEADO |
| GET `/notifications/history` | Si | No | Si | SIN DOCS |

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
| GET `/catalogs/activity-types` | Si | Si | No | SIN CANON |
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

> Nota: `GET /catalogs/activity-types` documentado en Wave 2 (ya no SIN DOCS).

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

### folders (carpetas de evidencia)

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| GET `/folders/folders` | Si | Si | Si | ALINEADO |
| GET `/folders/folders/:id` | Si | Si | Si | ALINEADO |
| POST `/folders/users/:userId/folders/:folderId/enroll` | Si | Si | Si | ALINEADO |
| GET `/folders/users/:userId/folders` | Si | Si | Si | ALINEADO |
| GET `/folders/users/:userId/folders/:folderId/progress` | Si | Si | Si | ALINEADO |
| PATCH `/folders/users/:userId/folders/:folderId/modules/:moduleId/sections/:sectionId` | Si | Si | Si | ALINEADO |
| DELETE `/folders/users/:userId/folders/:folderId` | Si | Si | Si | ALINEADO |

### evidence-folder (endpoints mobiles, commit f651b3f)

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| GET `/clubs/:clubId/sections/:sectionId/evidence-folder` | Si | Si | Si | ALINEADO |
| POST `/clubs/:clubId/sections/:sectionId/evidence-folder/sections/:efSectionId/submit` | Si | Si | Si | ALINEADO |
| POST `/clubs/:clubId/sections/:sectionId/evidence-folder/sections/:efSectionId/files` | Si | Si | Si | ALINEADO |
| DELETE `/clubs/:clubId/sections/:sectionId/evidence-folder/sections/:efSectionId/files/:fileId` | Si | Si | Si | ALINEADO |

> Nota: estos 4 endpoints eran FANTASMA en Wave 0. Implementados en commit f651b3f (2026-03-18).

### insurance (commit 7eed6c8)

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| GET `/clubs/:clubId/sections/:sectionId/members/insurance` | Si | Si | Si | ALINEADO |
| GET `/users/:memberId/insurance` | Si | Si | Si | ALINEADO |
| POST `/users/:memberId/insurance` | Si | Si | Si | ALINEADO |
| PATCH `/insurance/:insuranceId` | Si | Si | Si | ALINEADO |
| GET `/insurance/expiring` | Si | No | Si | SIN DOCS |

> Nota: InsurancesModule implementado en commit 7eed6c8 (2026-03-18). Era SIN CANON (sin modulo backend) en Wave 0.

### investiture (commit 6d33460 + 5eac904)

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| POST `/enrollments/:id/submit-for-validation` | Si | Si | Si | ALINEADO |
| POST `/enrollments/:id/validate` | Si | Si | Si | ALINEADO |
| POST `/enrollments/:id/investiture` | Si | Si | Si | ALINEADO |
| GET `/investiture/pending` | Si | Si | Si | ALINEADO |
| GET `/enrollments/:id/investiture-history` | Si | Si | Si | ALINEADO |

> Nota: InvestitureModule implementado en commits 6d33460 + 5eac904 (2026-03-20). Era FANTASMA en Wave 0 (solo tablas en schema.prisma).

### admin — investiture config

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| GET `/api/v1/admin/investiture/config` | Si | No | No | SIN CANON |
| GET `/api/v1/admin/investiture/config/:configId` | Si | No | No | SIN CANON |
| POST `/api/v1/admin/investiture/config` | Si | No | No | SIN CANON |
| PATCH `/api/v1/admin/investiture/config/:configId` | Si | No | No | SIN CANON |
| DELETE `/api/v1/admin/investiture/config/:configId` | Si | No | No | SIN CANON |

> Nota: CRUD de `investiture_config` (configuración de fechas límite e investidura por campo local y año). Guards: GET requiere `admin|coordinator`, POST/PATCH/DELETE requieren `admin`. DELETE es soft-delete (`active = false`). Verificado en `investiture.controller.ts` (2026-03-22).

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
| GET `/admin/medicines` | Si | Si | No | SIN CANON |
| POST `/admin/medicines` | Si | Si | No | SIN CANON |
| PATCH `/admin/medicines/:medicineId` | Si | Si | No | SIN CANON |
| DELETE `/admin/medicines/:medicineId` | Si | Si | No | SIN CANON |
| GET `/admin/ecclesiastical-years` | Si | Si | No | SIN CANON |
| POST `/admin/ecclesiastical-years` | Si | Si | No | SIN CANON |
| PATCH `/admin/ecclesiastical-years/:yearId` | Si | Si | No | SIN CANON |
| DELETE `/admin/ecclesiastical-years/:yearId` | Si | Si | No | SIN CANON |
| GET `/admin/honor-categories` | Si | Si | No | SIN CANON |
| POST `/admin/honor-categories` | Si | Si | No | SIN CANON |
| PATCH `/admin/honor-categories/:id` | Si | Si | No | SIN CANON |
| DELETE `/admin/honor-categories/:id` | Si | Si | No | SIN CANON |
| GET `/admin/honor-categories/:id` | Si | Si | No | SIN CANON |
| GET `/admin/club-ideals` | Si | Si | No | SIN CANON |

> Nota: `/admin/medicines` documentado en Wave 2 (ya no SIN DOCS). `/admin/honor-categories` (CRUD completo) y `/admin/club-ideals` implementados en commits 8ceaf74 y a90e910 (2026-03-18). Eran FANTASMA en Wave 0.

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
| PATCH `/admin/users/:userId/approval` | Si | Si | Si | ALINEADO |
| PATCH `/admin/users/:userId` | Si | Si | Si | ALINEADO |

> Nota: `PATCH /admin/users/:userId/approval` y `PATCH /admin/users/:userId` implementados en commit 68af077 (2026-03-18). Eran FANTASMA en Wave 0.

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

### resources

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| POST `/resources` | Si | Si | Si | ALINEADO |
| GET `/resources` | Si | Si | Si | ALINEADO |
| GET `/resources/:id` | Si | Si | Si | ALINEADO |
| GET `/resources/:id/signed-url` | Si | Si | Si | ALINEADO |
| PATCH `/resources/:id` | Si | Si | Si | ALINEADO |
| DELETE `/resources/:id` | Si | Si | Si | ALINEADO |
| GET `/resources/me` | Si | Si | Si | ALINEADO |
| GET `/resources/me/:id` | Si | Si | Si | ALINEADO |
| GET `/resources/me/:id/signed-url` | Si | Si | Si | ALINEADO |

### resource-categories

| Endpoint | Implementado | Doc API | Canon | Estado |
|----------|:---:|:---:|:---:|---|
| POST `/resource-categories` | Si | Si | Si | ALINEADO |
| GET `/resource-categories` | Si | Si | Si | ALINEADO |
| GET `/resource-categories/:id` | Si | Si | Si | ALINEADO |
| PATCH `/resource-categories/:id` | Si | Si | Si | ALINEADO |
| DELETE `/resource-categories/:id` | Si | Si | Si | ALINEADO |

> Nota: ResourcesModule (14 endpoints) implementado 2026-03-26. Storage en R2 bucket RESOURCES_FILES, URLs firmadas TTL 1 hora, visibilidad por scope (system/union/local_field).

### Endpoints FANTASMA (resueltos al 2026-03-20)

Todos los endpoints que eran FANTASMA en Wave 0 han sido resueltos:

| Endpoint | Estado anterior | Estado actual | Resolucion |
|----------|:---:|:---:|---|
| PATCH `/admin/users/:userId/approval` | FANTASMA | ALINEADO | Implementado commit 68af077 |
| PATCH `/admin/users/:userId` | FANTASMA | ALINEADO | Implementado commit 68af077 |
| GET `/admin/honor-categories` | FANTASMA | SIN CANON | Implementado commit 8ceaf74 |
| POST `/admin/honor-categories` | FANTASMA | SIN CANON | Implementado commit 8ceaf74 |
| PATCH `/admin/honor-categories/:id` | FANTASMA | SIN CANON | Implementado commit 8ceaf74 |
| DELETE `/admin/honor-categories/:id` | FANTASMA | SIN CANON | Implementado commit 8ceaf74 |
| GET `/admin/honor-categories/:id` | FANTASMA | SIN CANON | Implementado commit 8ceaf74 |
| GET `/admin/club-ideals` | FANTASMA | SIN CANON | Implementado commit a90e910 |
| POST `/auth/update-password` | FANTASMA | ALINEADO | Implementado commit 68af077 |
| DELETE `/clubs/:clubId/sections/:sectionId` | FANTASMA | — | Removido de docs (no existe en backend) |
| GET `/clubs/:clubId/sections/:sectionId/evidence-folder` | FANTASMA | ALINEADO | Implementado commit f651b3f |
| POST `/clubs/:clubId/sections/:sectionId/evidence-folder/sections/:efSectionId/submit` | FANTASMA | ALINEADO | Implementado commit f651b3f |
| POST `/clubs/:clubId/sections/:sectionId/evidence-folder/sections/:efSectionId/files` | FANTASMA | ALINEADO | Implementado commit f651b3f |
| DELETE `/clubs/:clubId/sections/:sectionId/evidence-folder/sections/:efSectionId/files/:fileId` | FANTASMA | ALINEADO | Implementado commit f651b3f |
| GET `/clubs/:clubId/sections/:sectionId/members/insurance` | FANTASMA | ALINEADO | Implementado commit 7eed6c8 |
| GET `/users/:memberId/insurance` | FANTASMA | ALINEADO | Implementado commit 7eed6c8 |
| POST `/users/:memberId/insurance` | FANTASMA | ALINEADO | Implementado commit 7eed6c8 |
| PATCH `/insurance/:insuranceId` | FANTASMA | ALINEADO | Implementado commit 7eed6c8 |

> **Total FANTASMA resueltos**: 18. Quedan 0 endpoints FANTASMA al 2026-03-20.

### Endpoints app con rutas alternativas (pendientes de verificacion)

| Endpoint | Consumidor | Estado | Nota |
|----------|:---:|:---:|---|
| POST `/auth/pr-check` | App | Pendiente verificar | Usado por app auth datasource — no confirmado en backend |
| GET `/users/:userId/post-registration/photo-status` | App | Pendiente verificar | Usado por app post_registration — no confirmado en backend |
| PATCH `/emergency-contacts/:contactId` | App | Pendiente verificar | App usa ruta diferente a backend (`/users/:userId/emergency-contacts/:contactId`) |
| DELETE `/emergency-contacts/:contactId` | App | Pendiente verificar | Idem |

> Nota: estos 4 endpoints no fueron verificados en backend durante la auditoria. Pueden existir sin haber sido capturados.

---

## Tabla 2: Modelos de Datos

Convenciones:
- **schema.prisma**: existe como `model` en el archivo prisma en docs/
- **SCHEMA-REFERENCE**: documentado en SCHEMA-REFERENCE.md (actualizado 2026-03-22: 74 modelos + 8 enums)
- **Canon**: mencionado o su concepto de dominio referenciado en documentos canon

| Model | schema.prisma | SCHEMA-REFERENCE | Canon | Estado |
|-------|:---:|:---:|:---:|---|
| activities | Si | Si | Si | ALINEADO |
| activity_types | Si | Si | No | SIN CANON |
| activity_instances | Si | Si | No | SIN CANON |
| folder_assignments | Si | Si | No | SIN CANON |
| camporee_clubs | Si | Si | No | SIN CANON |
| camporee_members | Si | Si | No | SIN CANON |
| churches | Si | Si | Si | ALINEADO |
| class_module_progress | Si | Si | Si | ALINEADO |
| class_modules | Si | Si | No | SIN CANON |
| class_section_progress | Si | Si | Si | ALINEADO |
| class_sections | Si | Si | No | SIN CANON |
| classes | Si | Si | Si | ALINEADO |
| club_ideals | Si | Si | No | SIN CANON |
| club_inventory | Si | Si | No | SIN CANON |
| club_types | Si | Si | Si | ALINEADO |
| clubs | Si | Si | Si | ALINEADO |
| club_sections | Si | Si | Si | ALINEADO |
| club_role_assignments | Si | Si | Si | ALINEADO |
| countries | Si | Si | Si | ALINEADO |
| districts | Si | Si | Si | ALINEADO |
| ecclesiastical_years | Si | Si | Si | ALINEADO |
| enrollments | Si | Si | Si | ALINEADO |
| error_logs | Si | Si | No | SIN CANON |
| finances | Si | Si | Si | ALINEADO |
| finances_categories | Si | Si | No | SIN CANON |
| folders | Si | Si | Si | ALINEADO |
| folders_modules | Si | Si | No | SIN CANON |
| folders_modules_records | Si | Si | No | SIN CANON |
| folders_section_records | Si | Si | No | SIN CANON |
| folders_sections | Si | Si | No | SIN CANON |
| honor_requirements | Si | Si | No | SIN CANON |
| honors | Si | Si | Si | ALINEADO |
| honors_categories | Si | Si | No | SIN CANON |
| inventory_categories | Si | Si | No | SIN CANON |
| inventory_history | Si | Si | No | SIN CANON |
| local_camporees | Si | Si | No | SIN CANON |
| local_fields | Si | Si | Si | ALINEADO |
| master_honors | Si | Si | No | SIN CANON |
| notification_logs | Si | Si | No | SIN CANON |
| permissions | Si | Si | Si | ALINEADO |
| role_permissions | Si | Si | Si | ALINEADO |
| roles | Si | Si | Si | ALINEADO |
| union_camporee_local_fields | Si | Si | No | SIN CANON |
| union_camporees | Si | Si | No | SIN CANON |
| unions | Si | Si | Si | ALINEADO |
| unit_members | Si | Si | No | SIN CANON |
| units | Si | Si | No | SIN CANON |
| users | Si | Si | Si | ALINEADO |
| user_fcm_tokens | Si | Si | No | SIN CANON |
| users_pr | Si | Si | Si | ALINEADO |
| users_classes | No | No | No | ARCHIVADA (como users_classes_archive) |
| certifications | Si | Si | Si | ALINEADO |
| certification_modules | Si | Si | No | SIN CANON |
| certification_sections | Si | Si | No | SIN CANON |
| users_certifications | Si | Si | No | SIN CANON |
| certification_module_progress | Si | Si | No | SIN CANON |
| certification_section_progress | Si | Si | No | SIN CANON |
| member_insurances | Si | Si | No | SIN CANON |
| investiture_validation_history | Si | Si | No | SIN CANON |
| investiture_config | Si | Si | No | SIN CANON |
| diseases | Si | Si | No | SIN CANON |
| allergies | Si | Si | No | SIN CANON |
| emergency_contacts | Si | Si | Si | ALINEADO |
| weekly_records | Si | Si | No | SIN CANON |
| users_allergies | Si | Si | No | SIN CANON |
| users_diseases | Si | Si | No | SIN CANON |
| users_medicines | Si | Si | No | SIN CANON |
| user_honor_requirement_progress | Si | Si | No | SIN CANON |
| users_honors | Si | Si | No | SIN CANON |
| users_permissions | Si | Si | No | SIN CANON |
| users_roles | Si | Si | Si | ALINEADO |
| medicines | Si | Si | No | SIN CANON |
| relationship_types | Si | Si | No | SIN CANON |
| legal_representatives | Si | Si | Si | ALINEADO |
| resource_categories | Si | Si | Si | ALINEADO |
| resources | Si | Si | Si | ALINEADO |

### Conteos modelos

- **ALINEADO**: 36 (schema.prisma + SCHEMA-REFERENCE + Canon)
- **SIN CANON**: 42 (en schema.prisma + SCHEMA-REFERENCE pero sin mencion en documentos canon)
- **SIN DOCS**: 0 (resuelto — Wave 2 + Wave 3 + 2026-03-22 documentaron todos los modelos en SCHEMA-REFERENCE)
- **FANTASMA**: 0
- **DRIFT**: 0

> **Nota**: SCHEMA-REFERENCE.md fue actualizado en Wave 2 documentando ~72 modelos + 8 enums. Wave 3 completo con activities/activity_types/activity_instances. 2026-03-22: inventory_history y notification_logs agregados (estaban en schema.prisma sin documentar). 2026-03-26: resource_categories y resources agregados (ResourcesModule). 2026-03-27: honor_requirements y user_honor_requirement_progress agregados (per-requirement tracking feature). Los estados SIN CANON persisten porque los conceptos existen en schema.prisma y SCHEMA-REFERENCE pero no estan referenciados explicitamente en los documentos canon de dominio. Para resolverlos, agregar menciones en dominio-sacdia.md o runtime-sacdia.md segun corresponda.

---

## Tabla 3: Modulos/Features

Convenciones:
- **Backend Module**: existe como modulo NestJS en backend
- **Admin Pages**: tiene paginas funcionales en admin
- **App Screens**: tiene screens en app
- **Canon Domain**: dominio descrito en documentos canon
- **Estado**: ALINEADO (todas las capas relevantes presentes y funcionales), PARCIAL (algunas capas faltantes o incompletas), FANTASMA (canon-only sin implementacion), SIN CANON (code-only sin mencion en canon)

| Dominio | Backend Module | Admin Pages | App Screens | Canon Domain | Estado |
|---------|:---:|:---:|:---:|:---:|---|
| auth | Si (AuthModule) | Si (login) | Si (auth, 5 screens) | Si (auth/) | ALINEADO |
| gestion-clubs (clubes, secciones, cargos) | Si (ClubsModule) | Si (clubs, 3 pages) | Si (club, members, units) | Si (dominio, runtime) | ALINEADO |
| clases-progresivas | Si (ClassesModule) | Si (read-only) | Si (classes, 6 screens) | Si (formacion/trayectoria) | ALINEADO |
| honores | Si (HonorsModule, 16 endpoints) | Si (honors, CRUD) | Si (honors, 4 screens + checklist requisitos + progress bar) | Si (formacion) | ALINEADO |
| actividades | Si (ActivitiesModule) | Si (list + detail + create/edit + delete) | Si (activities, 4 screens + edit/delete) | Si (runtime 6.6) | ALINEADO |
| finanzas | Si (FinancesModule) | Si (dashboard + resumen + tabla + filtros + CRUD) | Si (finances, 3 screens + delete AlertDialog) | Si (runtime 6.6) | ALINEADO |
| catalogos | Si (CatalogsModule, AdminModule) | Si (catalogs, 13 pages) | Si (shared catalogs) | Si (runtime 6.5) | ALINEADO |
| camporees | Si (CamporeesModule) | Si (CRUD completo + gestion de miembros) | Si (4 screens + capa de datos completa) | Si (runtime 6.6) | ALINEADO |
| communications (notificaciones) | Si (NotificationsModule) | Si (notifications, 1 page) | No (consume FCM tokens) | Si (runtime 6.6) | ALINEADO |
| certificaciones-guias-mayores | Si (CertificationsModule) | Si (list + detail + progress) | Si (4 screens) | Si (formacion) | ALINEADO |
| inventario | Si (InventoryModule) | Si (CRUD funcional) | Si (inventory, 4 screens) | Si (runtime 6.6) | ALINEADO |
| gestion-seguros (insurance) | Si (InsurancesModule) | Si (CRUD funcional) | Si (insurance, 3 screens) | Si (gestion-seguros.md) | ALINEADO |
| carpetas-evidencias (folders) | Si (FoldersModule + EvidenceFolderController) | Si (read-only) | Si (evidence_folder, 2 screens) | Si (formacion) | ALINEADO |
| rbac (permisos/roles) | Si (RbacModule) | Si (rbac, 3 pages) | No | Si (auth/) | ALINEADO |
| recursos | Si (ResourcesModule, 14 endpoints) | Si (categorias CRUD + recursos CRUD) | Si (Clean Architecture completa) | Si (recursos.md) | ALINEADO |
| infrastructure (health, logging) | Si (CommonModule, AppModule) | No | No | Si (runtime 6.7) | PARCIAL |
| validacion-investiduras | Si (InvestitureModule, 5 endpoints) | Si (table + dialogs + history) | Si (3 screens) | Si (dominio: validacion) | ALINEADO |

### Conteos features

- **ALINEADO**: 16
- **PARCIAL**: 1 (infrastructure — cross-cutting, sin client UI dedicada)
- **SIN CANON**: 0
- **FANTASMA**: 0
- **DRIFT**: 0

> **Notas**:
> - **actividades**: Admin UI completa implementada en commit 1179598 (2026-03-20). Era PARCIAL (placeholder).
> - **finanzas**: Admin dashboard completo implementado en commit 1179598 (2026-03-20). Era PARCIAL (placeholder).
> - **camporees**: Admin CRUD + gestion de miembros en commit c18cc07 (2026-03-20). App 4 screens en commit bfa3231 (2026-03-20). Era PARCIAL.
> - **certificaciones-guias-mayores**: UI Flutter (4 screens) en commit 69cb026. Admin (list + detail + progress) en commit 37e5929 (2026-03-20). Era PARCIAL.
> - **inventario**: Admin CRUD funcional segun feature registry. Era PARCIAL (placeholder).
> - **gestion-seguros**: InsurancesModule implementado en commit 7eed6c8 (2026-03-18). Era SIN CANON.
> - **validacion-investiduras**: InvestitureModule (5 endpoints MVP) en commits 6d33460 + 5eac904 (2026-03-20). Admin en commit 7199ab0. App en commit 2f4ac49. Era FANTASMA.
> - **infrastructure**: CommonModule + AppModule presentes. Sin client UI dedicada — es cross-cutting.
> - **3 migraciones aplicadas**: PK inventory_categories (commit d690a57), auditoria finanzas (commit 69b4b3e), enum INVESTIDO (commit 5eac904).

---

## Tabla 4: Integraciones Externas

| Service | Configurado | Usado Activamente | Documentado | Estado |
|---------|:---:|:---:|:---:|---|
| Supabase Auth | Si | Si | Si (canon, runtime) | ALINEADO |
| Firebase Admin (FCM) | Si (condicional) | Si | Si (runtime 9) | ALINEADO |
| Sentry | Si (condicional) | Si | No | SIN CANON |
| Redis / Upstash | Si (condicional) | Si | Si (runtime 9) | ALINEADO |
| Cloudflare R2 (S3) | Si | Si | Si (runtime-sacdia.md actualizado) | ALINEADO |
| Supabase Storage | No en backend | No detectado | No (corregido en runtime-sacdia.md) | RESUELTO |
| NestJS Cache Manager | Si | Si | Si (parte de Redis stack) | ALINEADO |

### Conteos integraciones

- **ALINEADO**: 5 (Supabase Auth, Firebase/FCM, Redis/Upstash, Cloudflare R2, NestJS Cache Manager)
- **SIN CANON**: 1 (Sentry — configurado y activo pero no en canon)
- **SIN DOCS**: 0
- **FANTASMA**: 0 (Supabase Storage — drift corregido en runtime-sacdia.md 2026-03-14)
- **DRIFT**: 0

> **Nota**: Storage drift resuelto. Canon y runtime ahora documentan Cloudflare R2 como storage provider. La fila de Supabase Storage pasa de FANTASMA a RESUELTO ya que el canon fue actualizado para reflejar realidad.

---

## Hallazgos Destacados

### 1. Todos los FANTASMA resueltos (18 endpoints)
Wave 0 tenia 17 endpoints FANTASMA. Todos fueron resueltos:
- InsurancesModule implementado (4 endpoints insurance)
- EvidenceFolderController implementado (4 endpoints evidence-folder)
- `/admin/honor-categories` CRUD implementado (5 endpoints)
- `/admin/club-ideals` implementado (1 endpoint)
- `/admin/users` approval/update implementados (2 endpoints)
- `/auth/update-password` implementado (1 endpoint)
- `DELETE /clubs/sections/:sectionId` removido de docs (no existe en backend)

### 2. Features: 15 de 16 dominios ALINEADOS
Los dominios que eran PARCIAL o FANTASMA en Wave 0 fueron completados:
- **actividades**: admin UI completa (antes placeholder)
- **finanzas**: admin dashboard completo (antes placeholder)
- **camporees**: app 4 screens + admin CRUD completo (antes sin app screens, admin read-only)
- **certificaciones-guias-mayores**: app 4 screens + admin funcional (antes sin app screens)
- **inventario**: admin CRUD funcional (antes placeholder)
- **gestion-seguros**: InsurancesModule + admin + app (antes SIN CANON)
- **validacion-investiduras**: InvestitureModule + admin + app (antes FANTASMA)

### 3. Endpoints: 248 en matriz (273 en ENDPOINTS-LIVE-REFERENCE.md)
ResourcesModule agrego 14 endpoints nuevos (2026-03-26). 2026-03-27: 4 endpoints de honor requirements/progress agregados. Total 273 en ENDPOINTS-LIVE-REFERENCE.md.

### 4. SCHEMA-REFERENCE actualizado: 78 modelos + 8 enums
Wave 2 documento ~48 modelos adicionales en SCHEMA-REFERENCE.md (era ~25 tablas). 2026-03-22: inventory_history y notification_logs agregados. 2026-03-26: resource_categories y resources agregados. 2026-03-27: honor_requirements y user_honor_requirement_progress agregados.

### 5. 3 migraciones de base de datos aplicadas
- `d690a57`: rename PK inventory_categories (typo corregido)
- `69b4b3e`: campo `modified_by_id` en finances (auditoria)
- `5eac904`: enum `INVESTIDO` en investiture_action_enum

### 6. SIN CANON que quedan (no son bloqueantes)
Los 16+ endpoints CRUD admin de catalogos (`/admin/relationship-types`, `/admin/allergies`, etc.) siguen marcados SIN CANON porque el canon no los menciona explicitamente por nombre, aunque el dominio catalogos esta cubierto en `catalogos.md`.

### 7. Endpoints app con rutas alternativas (pendientes)
4 endpoints consumidos por la app no han sido verificados contra el backend actual:
- `POST /auth/pr-check`
- `GET /users/:userId/post-registration/photo-status`
- `PATCH /emergency-contacts/:contactId` (ruta alternativa)
- `DELETE /emergency-contacts/:contactId` (ruta alternativa)

### 8. infrastructure sigue siendo PARCIAL
CommonModule y AppModule estan implementados pero no hay client UI dedicada (admin ni app). Es cross-cutting por naturaleza — no es un gap critico.

---

## Audit de Seguridad — 2026-04-17

Auditoría de seguridad del backend (`sacdia-backend`). Todos los hallazgos de sesión 2026-04-17.

### Leyenda de severidad

| Nivel | Descripción |
|-------|-------------|
| CRITICAL | Vulnerabilidad explotable directamente, afecta integridad de datos o autenticación |
| HIGH | Falla lógica grave con impacto en autorización, ownership, o consistencia |
| MEDIUM | Gap de validación, race condition de bajo riesgo, o deuda de seguridad |
| LOW | Código defensivo faltante, CVEs en deps, o mejoras de bajo impacto |
| INFRA | Configuración de infraestructura/entorno pendiente |

### Tabla de hallazgos

| ID | Severidad | Área | Descripción | Estado | Commit(s) | Notas |
|----|-----------|------|-------------|--------|-----------|-------|
| C-01 | CRITICAL | annual-folders | TOCTOU en `annual_folders` — doble check sin lock transaccional permitía acceso concurrente a recursos de otro club | RESOLVED | `9ef269d` | Lock via `$transaction` + select-for-update |
| C-02 | CRITICAL | evidence-folder | Validación de evidencia sin verificación de ownership del archivo — un usuario podía adjuntar archivos de otro usuario | RESOLVED | `9ef269d` | Ownership check agregado en upload + validate |
| H-01 | HIGH | notifications | Sin cap en `limit` de listado — `GET /notifications/history` permitía traer N ilimitado de registros | RESOLVED | `56f906f` | Cap a 100, default 20 |
| H-02 | HIGH | scoring-categories | `super_admin` podía ser asignado a scoring-categories sin restricción de roles | RESOLVED | `5cf32ba` | Guard de roles reforzado |
| H-03 | HIGH | annual-folders | `submitFolder` sin verificación de ownership del folder antes de submit | RESOLVED | `9ef269d` | Ownership check previo a transición de estado |
| H-04 | HIGH | config | `EMAIL_ENABLED` no validado en schema Joi — podía arrancar sin la variable y silenciar errores de email | RESOLVED | `077c7d7` | Agregado a Joi schema de config |
| H-05 | HIGH | annual-folders | `setReviewerNote` permitía escribir notas en folders de cualquier territory sin validar scope del reviewer | RESOLVED | `9ef269d` | Territory scope check agregado |
| M-01 | MEDIUM | evidence-folder | `submitSection` sin ownership check a nivel de assignment — cualquier miembro autenticado podía hacer submit de una sección ajena | RESOLVED | `1fdf337` | PermissionsGuard + assignment scope |
| M-02 | MEDIUM | honors | Uploads de honors sin validación de tipo MIME + sin soporte HEIC para iOS | RESOLVED | `bad5ea9` | MIME whitelist + HEIC→JPEG conversion |
| M-03 | MEDIUM | scoring-categories | TODOs de validación sin resolver en scoring-categories service | RESOLVED (verify-only) | `ca072f9` | TODOs documentados y cerrados; lógica verificada como correcta |
| M-04 | MEDIUM | camporees | Paginación faltante en listado de camporees + URLs de archivos sin presign | RESOLVED | SDD change `camporees-pagination-presign` (10 commits, ver archive) | Ref: `sdd/camporees-pagination-presign/archive-report` en engram |
| M-05 | MEDIUM | rankings | Throttle + lock faltante en endpoint de rankings bajo carga concurrente | RESOLVED | `8999cc5` | Throttle + Redis lock aplicados |
| M-06 | MEDIUM | users | `update-user.dto` con validaciones insuficientes — campos sensibles sin whitelist | RESOLVED | `8b23911` | DTO reforzado con class-validator |
| M-07 | MEDIUM | membership-requests | TOCTOU en aprobación de membership-requests — doble aprobación concurrente posible | RESOLVED | `251fcd7` | Transacción + check de estado previo |

### Hallazgos pendientes (OPEN)

| ID | Severidad | Área | Descripción | Estado | Notas |
|----|-----------|------|-------------|--------|-------|
| INFRA-01 | INFRA | storage | `R2_PUBLIC_URL_USER_PROFILES` sin configurar en staging/prod + bucket de Cloudflare sin acceso público habilitado | OPEN | Requiere configuración de infra — no es código |
| INFRA-02 | INFRA | app | `CachedNetworkImage` no conectado a `userImageUrl` en perfil de usuario | OPEN | UI low priority — app |
| ARCH-01 | MEDIUM | admin | `DataTablePagination` sin patrón unificado para tab-context (cada tab tiene su propio estado de paginación) | OPEN | Arquitectural — admin panel |
| VERIFY-01 | MEDIUM | evidence-folder | `submitSection` PermissionsGuard — scope `active_assignment` necesita verificación de que el guard rechaza correctamente asignaciones inactivas | OPEN | Verify-flagged — requiere test unitario |
| DB-01 | MEDIUM | database | `club_role_assignments` sin columnas de audit trail (`created_at`, `created_by_id`) — inconsistente con otros modelos | OPEN | Requiere migration |
| DEP-01 | LOW | deps | CVE: `path-to-regexp` (ReDoS alto) + `protobufjs` (ACE crítico) — deps transitivas sin fix upstream | OPEN | Monitorear — sin fix disponible al 2026-04-17 |
| LOW-01 | LOW | auth | Email verification delivery — pre-existing, no parte del sistema de auth SACDIA nativo | OPEN | Pre-existing, auth layer (Better Auth) |

### Contexto de la sesión 2026-04-17

- **Scope**: sacdia-backend únicamente
- **Commits en backend**: `9ef269d`, `56f906f`, `5cf32ba`, `077c7d7`, `1fdf337`, `bad5ea9`, `ca072f9`, `8999cc5`, `8b23911`, `251fcd7` + 10 commits del change `camporees-pagination-presign`
- **SDD change cerrado**: `camporees-pagination-presign` — archive en engram `sdd/camporees-pagination-presign/archive-report`
- **Sesión previa (2026-04-01)**: audit Flutter (3 CRITICAL + 5 HIGH + 6 MEDIUM, commit `622424e`) + audit Backend (2 CRITICAL + 6 HIGH + 8 MEDIUM, commit `2e8c36b`) — ver memory engram `audit_flutter_2026_04` y `audit_backend_2026_04`
