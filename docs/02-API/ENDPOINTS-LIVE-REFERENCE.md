# ENDPOINTS LIVE REFERENCE (Runtime Truth)

> [!IMPORTANT]
> Documento canónico para agentes (App + Panel Admin).
> Generado desde `src/**/*controller.ts` del backend en runtime.
> Base URL: `/api/v1`

**Generado**: 2026-03-01T21:00:00.000Z
**Total endpoints**: 180

## Lectura Rápida

- `Auth`: `Public` o `JWT` según guards/decorators detectados.
- `Roles`: se listan cuando hay `@GlobalRoles` o `@ClubRoles`.
- `Source`: archivo controlador de origen para trazabilidad.

## auth

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| POST | `/api/v1/auth/login` | Public | - | Iniciar sesión | `src/auth/auth.controller.ts` |
| POST | `/api/v1/auth/logout` | JWT | - | Cerrar sesión | `src/auth/auth.controller.ts` |
| GET | `/api/v1/auth/me` | JWT | - | Obtener perfil del usuario autenticado | `src/auth/auth.controller.ts` |
| POST | `/api/v1/auth/mfa/enroll` | JWT | - | Iniciar enrolamiento de 2FA | `src/auth/mfa.controller.ts` |
| GET | `/api/v1/auth/mfa/factors` | JWT | - | Listar factores MFA configurados | `src/auth/mfa.controller.ts` |
| GET | `/api/v1/auth/mfa/status` | JWT | - | Verificar estado de 2FA | `src/auth/mfa.controller.ts` |
| DELETE | `/api/v1/auth/mfa/unenroll` | JWT | - | Deshabilitar 2FA | `src/auth/mfa.controller.ts` |
| POST | `/api/v1/auth/mfa/verify` | JWT | - | Verificar y activar 2FA | `src/auth/mfa.controller.ts` |
| DELETE | `/api/v1/auth/oauth/:provider` | JWT | - | Desconectar un provider | `src/auth/oauth.controller.ts` |
| POST | `/api/v1/auth/oauth/apple` | Public | - | Iniciar autenticación con Apple | `src/auth/oauth.controller.ts` |
| GET | `/api/v1/auth/oauth/callback` | Public | - | Manejar callback de OAuth | `src/auth/oauth.controller.ts` |
| POST | `/api/v1/auth/oauth/google` | Public | - | Iniciar autenticación con Google | `src/auth/oauth.controller.ts` |
| GET | `/api/v1/auth/oauth/providers` | JWT | - | Obtener providers conectados | `src/auth/oauth.controller.ts` |
| POST | `/api/v1/auth/password/reset-request` | Public | - | Solicitar recuperación de contraseña | `src/auth/auth.controller.ts` |
| GET | `/api/v1/auth/profile/completion-status` | JWT | - | Obtener estado del post-registro | `src/auth/auth.controller.ts` |
| POST | `/api/v1/auth/register` | Public | - | Registrar nuevo usuario | `src/auth/auth.controller.ts` |
| DELETE | `/api/v1/auth/sessions` | JWT | - | Cerrar todas las sesiones | `src/auth/sessions.controller.ts` |
| GET | `/api/v1/auth/sessions` | JWT | - | Listar sesiones activas | `src/auth/sessions.controller.ts` |
| DELETE | `/api/v1/auth/sessions/:sessionId` | JWT | - | Cerrar una sesión específica | `src/auth/sessions.controller.ts` |

### Auth Contract Notes (2026-03-01)

- `POST /api/v1/auth/login` y `POST /api/v1/auth/refresh` responden tokens solo en camelCase: `accessToken`, `refreshToken`, `expiresAt`, `tokenType`.
- `POST /api/v1/auth/refresh` acepta `refreshToken` en request body. `refresh_token` es rechazado con `400` + `code=LEGACY_SNAKE_CASE_REMOVED` (default).
- Rollback temporal controlado: `AUTH_REJECT_SNAKE_CASE=false` permite `refresh_token` únicamente de forma transitoria.
- `GET /api/v1/auth/oauth/callback` mantiene `access_token`/`refresh_token` en query por compatibilidad con proveedor, pero la respuesta backend es camelCase.
- Endpoints MFA soportan header opcional `x-refresh-token` para bind de sesión cuando Supabase lo requiera.

## users

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1/users/:userId` | JWT | - | Obtener información de un usuario | `src/users/users.controller.ts` |
| PATCH | `/api/v1/users/:userId` | JWT | - | Actualizar información personal del usuario | `src/users/users.controller.ts` |
| PUT | `/api/v1/users/:userId/allergies` | JWT | - | Guardar alergias del usuario | `src/users/users.controller.ts` |
| PUT | `/api/v1/users/:userId/diseases` | JWT | - | Guardar enfermedades del usuario | `src/users/users.controller.ts` |
| GET | `/api/v1/users/:userId/age` | JWT | - | Calcular edad del usuario | `src/users/users.controller.ts` |
| GET | `/api/v1/users/:userId/classes` | JWT | - | Obtener inscripciones del usuario | `src/classes/classes.controller.ts` |
| GET | `/api/v1/users/:userId/classes/:classId/progress` | JWT | - | Obtener progreso del usuario en una clase | `src/classes/classes.controller.ts` |
| PATCH | `/api/v1/users/:userId/classes/:classId/progress` | JWT | - | Actualizar progreso de sección | `src/classes/classes.controller.ts` |
| POST | `/api/v1/users/:userId/classes/enroll` | JWT | - | Inscribir usuario en clase | `src/classes/classes.controller.ts` |
| GET | `/api/v1/users/:userId/emergency-contacts` | JWT | - | Listar contactos de emergencia del usuario | `src/emergency-contacts/emergency-contacts.controller.ts` |
| POST | `/api/v1/users/:userId/emergency-contacts` | JWT | - | Crear contacto de emergencia (máximo 5) | `src/emergency-contacts/emergency-contacts.controller.ts` |
| DELETE | `/api/v1/users/:userId/emergency-contacts/:contactId` | JWT | - | Eliminar contacto de emergencia (soft delete) | `src/emergency-contacts/emergency-contacts.controller.ts` |
| GET | `/api/v1/users/:userId/emergency-contacts/:contactId` | JWT | - | Obtener un contacto específico | `src/emergency-contacts/emergency-contacts.controller.ts` |
| PATCH | `/api/v1/users/:userId/emergency-contacts/:contactId` | JWT | - | Actualizar contacto de emergencia | `src/emergency-contacts/emergency-contacts.controller.ts` |
| GET | `/api/v1/users/:userId/honors` | JWT | - | Obtener honores del usuario | `src/honors/honors.controller.ts` |
| DELETE | `/api/v1/users/:userId/honors/:honorId` | JWT | - | Abandonar honor | `src/honors/honors.controller.ts` |
| PATCH | `/api/v1/users/:userId/honors/:honorId` | JWT | - | Actualizar progreso de honor | `src/honors/honors.controller.ts` |
| POST | `/api/v1/users/:userId/honors/:honorId` | JWT | - | Iniciar un honor | `src/honors/honors.controller.ts` |
| GET | `/api/v1/users/:userId/honors/stats` | JWT | - | Obtener estadísticas de honores del usuario | `src/honors/honors.controller.ts` |
| DELETE | `/api/v1/users/:userId/legal-representative` | JWT | - | Eliminar representante legal | `src/legal-representatives/legal-representatives.controller.ts` |
| GET | `/api/v1/users/:userId/legal-representative` | JWT | - | Obtener representante legal del usuario | `src/legal-representatives/legal-representatives.controller.ts` |
| PATCH | `/api/v1/users/:userId/legal-representative` | JWT | - | Actualizar representante legal | `src/legal-representatives/legal-representatives.controller.ts` |
| POST | `/api/v1/users/:userId/legal-representative` | JWT | - | Registrar representante legal (solo para menores de 18) | `src/legal-representatives/legal-representatives.controller.ts` |
| GET | `/api/v1/users/:userId/post-registration/status` | JWT | - | Obtener estado del post-registro | `src/post-registration/post-registration.controller.ts` |
| POST | `/api/v1/users/:userId/post-registration/step-1/complete` | JWT | - | Completar Paso 1: Foto de perfil | `src/post-registration/post-registration.controller.ts` |
| POST | `/api/v1/users/:userId/post-registration/step-2/complete` | JWT | - | Completar Paso 2: Información personal | `src/post-registration/post-registration.controller.ts` |
| POST | `/api/v1/users/:userId/post-registration/step-3/complete` | JWT | - | Completar Paso 3: Selección de club | `src/post-registration/post-registration.controller.ts` |
| DELETE | `/api/v1/users/:userId/profile-picture` | JWT | - | Eliminar foto de perfil | `src/users/users.controller.ts` |
| POST | `/api/v1/users/:userId/profile-picture` | JWT | - | Subir foto de perfil | `src/users/users.controller.ts` |
| GET | `/api/v1/users/:userId/requires-legal-representative` | JWT | - | Verificar si el usuario requiere representante legal | `src/users/users.controller.ts` |

## activities

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| DELETE | `/api/v1/activities/:activityId` | JWT | - | Desactivar actividad | `src/activities/activities.controller.ts` |
| GET | `/api/v1/activities/:activityId` | JWT | - | Obtener actividad por ID | `src/activities/activities.controller.ts` |
| PATCH | `/api/v1/activities/:activityId` | JWT | - | Actualizar actividad | `src/activities/activities.controller.ts` |
| GET | `/api/v1/activities/:activityId/attendance` | JWT | - | Obtener asistencia | `src/activities/activities.controller.ts` |
| POST | `/api/v1/activities/:activityId/attendance` | JWT | - | Registrar asistencia | `src/activities/activities.controller.ts` |

## admin

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1/admin/allergies` | JWT | super_admin, admin | List allergies for admin management | `src/admin/admin-reference.controller.ts` |
| POST | `/api/v1/admin/allergies` | JWT | super_admin, admin | Create allergy | `src/admin/admin-reference.controller.ts` |
| DELETE | `/api/v1/admin/allergies/:allergyId` | JWT | super_admin, admin | Soft delete allergy | `src/admin/admin-reference.controller.ts` |
| PATCH | `/api/v1/admin/allergies/:allergyId` | JWT | super_admin, admin | Update allergy | `src/admin/admin-reference.controller.ts` |
| GET | `/api/v1/admin/churches` | JWT | super_admin, admin | List churches for admin management | `src/admin/admin-geography.controller.ts` |
| POST | `/api/v1/admin/churches` | JWT | super_admin, admin | Create church | `src/admin/admin-geography.controller.ts` |
| DELETE | `/api/v1/admin/churches/:churchId` | JWT | super_admin, admin | Soft delete church | `src/admin/admin-geography.controller.ts` |
| PATCH | `/api/v1/admin/churches/:churchId` | JWT | super_admin, admin | Update church | `src/admin/admin-geography.controller.ts` |
| GET | `/api/v1/admin/countries` | JWT | super_admin, admin | List countries for admin management | `src/admin/admin-geography.controller.ts` |
| POST | `/api/v1/admin/countries` | JWT | super_admin, admin | Create country | `src/admin/admin-geography.controller.ts` |
| DELETE | `/api/v1/admin/countries/:countryId` | JWT | super_admin, admin | Soft delete country | `src/admin/admin-geography.controller.ts` |
| PATCH | `/api/v1/admin/countries/:countryId` | JWT | super_admin, admin | Update country | `src/admin/admin-geography.controller.ts` |
| GET | `/api/v1/admin/diseases` | JWT | super_admin, admin | List diseases for admin management | `src/admin/admin-reference.controller.ts` |
| POST | `/api/v1/admin/diseases` | JWT | super_admin, admin | Create disease | `src/admin/admin-reference.controller.ts` |
| DELETE | `/api/v1/admin/diseases/:diseaseId` | JWT | super_admin, admin | Soft delete disease | `src/admin/admin-reference.controller.ts` |
| PATCH | `/api/v1/admin/diseases/:diseaseId` | JWT | super_admin, admin | Update disease | `src/admin/admin-reference.controller.ts` |
| GET | `/api/v1/admin/districts` | JWT | super_admin, admin | List districts for admin management | `src/admin/admin-geography.controller.ts` |
| POST | `/api/v1/admin/districts` | JWT | super_admin, admin | Create district | `src/admin/admin-geography.controller.ts` |
| DELETE | `/api/v1/admin/districts/:districtId` | JWT | super_admin, admin | Soft delete district | `src/admin/admin-geography.controller.ts` |
| PATCH | `/api/v1/admin/districts/:districtId` | JWT | super_admin, admin | Update district | `src/admin/admin-geography.controller.ts` |
| GET | `/api/v1/admin/ecclesiastical-years` | JWT | super_admin, admin | List ecclesiastical years for admin management | `src/admin/admin-reference.controller.ts` |
| POST | `/api/v1/admin/ecclesiastical-years` | JWT | super_admin, admin | Create ecclesiastical year | `src/admin/admin-reference.controller.ts` |
| DELETE | `/api/v1/admin/ecclesiastical-years/:yearId` | JWT | super_admin, admin | Soft delete ecclesiastical year | `src/admin/admin-reference.controller.ts` |
| PATCH | `/api/v1/admin/ecclesiastical-years/:yearId` | JWT | super_admin, admin | Update ecclesiastical year | `src/admin/admin-reference.controller.ts` |
| GET | `/api/v1/admin/local-fields` | JWT | super_admin, admin | List local fields for admin management | `src/admin/admin-geography.controller.ts` |
| POST | `/api/v1/admin/local-fields` | JWT | super_admin, admin | Create local field | `src/admin/admin-geography.controller.ts` |
| DELETE | `/api/v1/admin/local-fields/:localFieldId` | JWT | super_admin, admin | Soft delete local field | `src/admin/admin-geography.controller.ts` |
| PATCH | `/api/v1/admin/local-fields/:localFieldId` | JWT | super_admin, admin | Update local field | `src/admin/admin-geography.controller.ts` |
| GET | `/api/v1/admin/rbac/permissions` | JWT | super_admin, admin | Listar todos los permisos | `src/rbac/rbac.controller.ts` |
| POST | `/api/v1/admin/rbac/permissions` | JWT | super_admin | Crear un nuevo permiso | `src/rbac/rbac.controller.ts` |
| DELETE | `/api/v1/admin/rbac/permissions/:id` | JWT | super_admin | Desactivar un permiso | `src/rbac/rbac.controller.ts` |
| GET | `/api/v1/admin/rbac/permissions/:id` | JWT | super_admin, admin | Obtener un permiso por ID | `src/rbac/rbac.controller.ts` |
| PATCH | `/api/v1/admin/rbac/permissions/:id` | JWT | super_admin | Actualizar un permiso | `src/rbac/rbac.controller.ts` |
| GET | `/api/v1/admin/rbac/roles` | JWT | super_admin, admin | Listar roles con sus permisos | `src/rbac/rbac.controller.ts` |
| GET | `/api/v1/admin/rbac/roles/:id` | JWT | super_admin, admin | Obtener rol con sus permisos | `src/rbac/rbac.controller.ts` |
| POST | `/api/v1/admin/rbac/roles/:id/permissions` | JWT | super_admin | Asignar permisos a un rol | `src/rbac/rbac.controller.ts` |
| PUT | `/api/v1/admin/rbac/roles/:id/permissions` | JWT | super_admin | Sincronizar permisos de un rol (reemplaza todos) | `src/rbac/rbac.controller.ts` |
| DELETE | `/api/v1/admin/rbac/roles/:id/permissions/:permissionId` | JWT | super_admin | Remover un permiso de un rol | `src/rbac/rbac.controller.ts` |
| GET | `/api/v1/admin/relationship-types` | JWT | super_admin, admin | List relationship types for admin management | `src/admin/admin-reference.controller.ts` |
| POST | `/api/v1/admin/relationship-types` | JWT | super_admin, admin | Create relationship type | `src/admin/admin-reference.controller.ts` |
| DELETE | `/api/v1/admin/relationship-types/:relationshipTypeId` | JWT | super_admin, admin | Soft delete relationship type | `src/admin/admin-reference.controller.ts` |
| PATCH | `/api/v1/admin/relationship-types/:relationshipTypeId` | JWT | super_admin, admin | Update relationship type | `src/admin/admin-reference.controller.ts` |
| GET | `/api/v1/admin/unions` | JWT | super_admin, admin | List unions for admin management | `src/admin/admin-geography.controller.ts` |
| POST | `/api/v1/admin/unions` | JWT | super_admin, admin | Create union | `src/admin/admin-geography.controller.ts` |
| DELETE | `/api/v1/admin/unions/:unionId` | JWT | super_admin, admin | Soft delete union | `src/admin/admin-geography.controller.ts` |
| PATCH | `/api/v1/admin/unions/:unionId` | JWT | super_admin, admin | Update union | `src/admin/admin-geography.controller.ts` |
| GET | `/api/v1/admin/users` | JWT | super_admin, admin, coordinator | Listar usuarios administrativos con alcance por rol (ALL/UNION/LOCAL_FIELD) | `src/admin/admin-users.controller.ts` |
| GET | `/api/v1/admin/users/:userId` | JWT | super_admin, admin, coordinator | Obtener detalle de usuario validando alcance por rol del actor | `src/admin/admin-users.controller.ts` |

## camporees

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1/camporees` | JWT | - | Listar camporees | `src/camporees/camporees.controller.ts` |
| POST | `/api/v1/camporees` | JWT | director, subdirector | Crear camporee | `src/camporees/camporees.controller.ts` |
| DELETE | `/api/v1/camporees/:camporeeId` | JWT | director | Desactivar camporee | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/:camporeeId` | JWT | - | Obtener camporee por ID | `src/camporees/camporees.controller.ts` |
| PATCH | `/api/v1/camporees/:camporeeId` | JWT | director, subdirector | Actualizar camporee | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/:camporeeId/members` | JWT | - | Listar miembros del camporee | `src/camporees/camporees.controller.ts` |
| DELETE | `/api/v1/camporees/:camporeeId/members/:userId` | JWT | director, subdirector | Remover miembro del camporee | `src/camporees/camporees.controller.ts` |
| POST | `/api/v1/camporees/:camporeeId/register` | JWT | - | Registrar miembro en camporee | `src/camporees/camporees.controller.ts` |

## catalogs

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1/catalogs/allergies` | Public | - | Obtener catálogo de alergias | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/churches` | Public | - | Obtener iglesias | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/club-ideals` | Public | - | Obtener ideales de club | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/club-types` | Public | - | Obtener tipos de club | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/relationship-types` | Public | - | Obtener tipos de relación | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/countries` | Public | - | Obtener países | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/diseases` | Public | - | Obtener catálogo de enfermedades | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/districts` | Public | - | Obtener distritos | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/ecclesiastical-years` | Public | - | Obtener años eclesiásticos | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/ecclesiastical-years/current` | Public | - | Obtener año eclesiástico actual | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/local-fields` | Public | - | Obtener campos locales | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/roles` | Public | - | Obtener roles disponibles | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/unions` | Public | - | Obtener uniones | `src/catalogs/catalogs.controller.ts` |

## certifications

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1/certifications/certifications` | JWT | - | Listar todas las certificaciones disponibles | `src/certifications/certifications.controller.ts` |
| GET | `/api/v1/certifications/certifications/:id` | JWT | - | Obtener detalles de una certificación | `src/certifications/certifications.controller.ts` |
| GET | `/api/v1/certifications/users/:userId/certifications` | JWT | - | Listar certificaciones del usuario | `src/certifications/certifications.controller.ts` |
| DELETE | `/api/v1/certifications/users/:userId/certifications/:certificationId` | JWT | - | Abandonar una certificación | `src/certifications/certifications.controller.ts` |
| GET | `/api/v1/certifications/users/:userId/certifications/:certificationId/progress` | JWT | - | Ver progreso detallado de una certificación | `src/certifications/certifications.controller.ts` |
| PATCH | `/api/v1/certifications/users/:userId/certifications/:certificationId/progress` | JWT | - | Actualizar progreso de una sección | `src/certifications/certifications.controller.ts` |
| POST | `/api/v1/certifications/users/:userId/certifications/enroll` | JWT | - | Inscribirse en una certificación | `src/certifications/certifications.controller.ts` |

## classes

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1/classes` | Public | - | Listar clases | `src/classes/classes.controller.ts` |
| GET | `/api/v1/classes/:classId` | Public | - | Obtener clase por ID | `src/classes/classes.controller.ts` |
| GET | `/api/v1/classes/:classId/modules` | Public | - | Obtener módulos de una clase | `src/classes/classes.controller.ts` |

## club-roles

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| DELETE | `/api/v1/club-roles/:assignmentId` | JWT | - | Remover rol de miembro | `src/clubs/clubs.controller.ts` |
| PATCH | `/api/v1/club-roles/:assignmentId` | JWT | - | Actualizar asignación de rol | `src/clubs/clubs.controller.ts` |

## clubs

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1/clubs` | JWT | - | Listar clubs | `src/clubs/clubs.controller.ts` |
| POST | `/api/v1/clubs` | JWT | - | Crear nuevo club | `src/clubs/clubs.controller.ts` |
| DELETE | `/api/v1/clubs/:clubId` | JWT | director | Desactivar club (requiere rol director) | `src/clubs/clubs.controller.ts` |
| GET | `/api/v1/clubs/:clubId` | JWT | - | Obtener club por ID | `src/clubs/clubs.controller.ts` |
| PATCH | `/api/v1/clubs/:clubId` | JWT | director, subdirector | Actualizar club (requiere rol director o subdirector) | `src/clubs/clubs.controller.ts` |
| GET | `/api/v1/clubs/:clubId/activities` | JWT | - | Listar actividades del club | `src/activities/activities.controller.ts` |
| POST | `/api/v1/clubs/:clubId/activities` | JWT | director, subdirector, secretary, counselor | Crear actividad | `src/activities/activities.controller.ts` |
| GET | `/api/v1/clubs/:clubId/finances` | JWT | - | Listar movimientos financieros del club | `src/finances/finances.controller.ts` |
| POST | `/api/v1/clubs/:clubId/finances` | JWT | director, subdirector, treasurer | Crear movimiento financiero | `src/finances/finances.controller.ts` |
| GET | `/api/v1/clubs/:clubId/finances/summary` | JWT | - | Resumen financiero del club | `src/finances/finances.controller.ts` |
| GET | `/api/v1/clubs/:clubId/instances` | JWT | - | Obtener instancias del club | `src/clubs/clubs.controller.ts` |
| POST | `/api/v1/clubs/:clubId/instances` | JWT | director, subdirector | Crear instancia de club (requiere director o subdirector) | `src/clubs/clubs.controller.ts` |
| GET | `/api/v1/clubs/:clubId/instances/:type` | JWT | - | Obtener instancia por tipo | `src/clubs/clubs.controller.ts` |
| PATCH | `/api/v1/clubs/:clubId/instances/:type/:instanceId` | JWT | director, subdirector, secretary | Actualizar instancia (requiere director, subdirector o secretario) | `src/clubs/clubs.controller.ts` |
| GET | `/api/v1/clubs/:clubId/instances/:type/:instanceId/members` | JWT | - | Listar miembros de la instancia | `src/clubs/clubs.controller.ts` |
| POST | `/api/v1/clubs/:clubId/instances/:type/:instanceId/roles` | JWT | director, subdirector, secretary | Asignar rol a un miembro (requiere director, subdirector o secretario) | `src/clubs/clubs.controller.ts` |

## fcm-tokens

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1/fcm-tokens` | JWT | - | Get current user FCM tokens | `src/notifications/notifications.controller.ts` |
| POST | `/api/v1/fcm-tokens` | JWT | - | Register FCM token | `src/notifications/notifications.controller.ts` |
| DELETE | `/api/v1/fcm-tokens/:token` | JWT | - | Unregister FCM token | `src/notifications/notifications.controller.ts` |
| GET | `/api/v1/fcm-tokens/user/:userId` | JWT | - | Get FCM tokens by user ID (owner/admin only) | `src/notifications/notifications.controller.ts` |

## finances

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| DELETE | `/api/v1/finances/:financeId` | JWT | - | Desactivar movimiento | `src/finances/finances.controller.ts` |
| GET | `/api/v1/finances/:financeId` | JWT | - | Obtener movimiento por ID | `src/finances/finances.controller.ts` |
| PATCH | `/api/v1/finances/:financeId` | JWT | - | Actualizar movimiento | `src/finances/finances.controller.ts` |
| GET | `/api/v1/finances/categories` | JWT | - | Listar categorías financieras | `src/finances/finances.controller.ts` |

## folders

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1/folders/folders` | JWT | - | Listar templates de carpetas disponibles | `src/folders/folders.controller.ts` |
| GET | `/api/v1/folders/folders/:id` | JWT | - | Obtener detalles de un template de carpeta | `src/folders/folders.controller.ts` |
| GET | `/api/v1/folders/users/:userId/folders` | JWT | - | Listar carpetas asignadas del usuario | `src/folders/folders.controller.ts` |
| DELETE | `/api/v1/folders/users/:userId/folders/:folderId` | JWT | - | Abandonar una carpeta | `src/folders/folders.controller.ts` |
| POST | `/api/v1/folders/users/:userId/folders/:folderId/enroll` | JWT | - | Inscribirse en una carpeta | `src/folders/folders.controller.ts` |
| PATCH | `/api/v1/folders/users/:userId/folders/:folderId/modules/:moduleId/sections/:sectionId` | JWT | - | Actualizar progreso de una sección | `src/folders/folders.controller.ts` |
| GET | `/api/v1/folders/users/:userId/folders/:folderId/progress` | JWT | - | Ver progreso detallado de una carpeta | `src/folders/folders.controller.ts` |

## health

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1/health` | Public | - | Check API status | `src/health/health.controller.ts` |

## honors

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1/honors` | Public | - | Listar honores | `src/honors/honors.controller.ts` |
| GET | `/api/v1/honors/:honorId` | Public | - | Obtener honor por ID | `src/honors/honors.controller.ts` |
| GET | `/api/v1/honors/categories` | Public | - | Listar categorías de honores | `src/honors/honors.controller.ts` |

## inventory

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1/inventory/catalogs/inventory-categories` | JWT | - | Listar categorías de inventario | `src/inventory/inventory.controller.ts` |
| GET | `/api/v1/inventory/clubs/:clubId/inventory` | JWT | - | Listar items del inventario de un club | `src/inventory/inventory.controller.ts` |
| POST | `/api/v1/inventory/clubs/:clubId/inventory` | JWT | - | Agregar nuevo item al inventario | `src/inventory/inventory.controller.ts` |
| DELETE | `/api/v1/inventory/inventory/:id` | JWT | - | Eliminar un item del inventario | `src/inventory/inventory.controller.ts` |
| GET | `/api/v1/inventory/inventory/:id` | JWT | - | Obtener detalles de un item del inventario | `src/inventory/inventory.controller.ts` |
| PATCH | `/api/v1/inventory/inventory/:id` | JWT | - | Actualizar un item del inventario | `src/inventory/inventory.controller.ts` |

## notifications

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| POST | `/api/v1/notifications/broadcast` | JWT | super_admin, admin | Send notification to all users | `src/notifications/notifications.controller.ts` |
| POST | `/api/v1/notifications/club/:instanceType/:instanceId` | JWT | super_admin, admin | Send notification to club members | `src/notifications/notifications.controller.ts` |
| POST | `/api/v1/notifications/send` | JWT | - | Send notification to specific user | `src/notifications/notifications.controller.ts` |

## root

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1` | Public | - | Sin descripción en @ApiOperation | `src/app.controller.ts` |

## Nota de mantenimiento

- Si cambia un controlador, regenerar este documento.
- Comando sugerido: `node /tmp/generate_live_endpoints_doc.js` (o script equivalente en repo).
