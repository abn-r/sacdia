# ENDPOINTS LIVE REFERENCE (Runtime Truth)

<!-- Verificado contra código 2026-03-25. Documento completo: cubre todos los endpoints implementados en controllers. -->

> [!IMPORTANT]
> Documento canónico para agentes (App + Panel Admin).
> Generado desde `src/**/*controller.ts` del backend en runtime.
> Base URL: `/api/v1`

**Estado**: ACTIVE
**Actualizado**: 2026-04-17 (GDPR data export — 3 nuevos endpoints: POST /users/me/data-export, GET /users/me/data-exports, GET /users/me/data-exports/:exportId/download)
**Total endpoints**: 333

## Lectura Rápida

- `Auth`: `Public` o `JWT` según guards/decorators detectados.
- `Roles`: se listan cuando hay `@GlobalRoles` o `@ClubRoles`.
- `Source`: archivo controlador de origen para trazabilidad.

## auth

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| POST | `/api/v1/auth/login` | Public | - | Iniciar sesión | `src/auth/auth.controller.ts` |
| POST | `/api/v1/auth/refresh` | Public | - | Refrescar sesión con refresh token | `src/auth/auth.controller.ts` |
| POST | `/api/v1/auth/logout` | Public (Bearer opcional) | - | Cerrar sesión (best effort) | `src/auth/auth.controller.ts` |
| GET | `/api/v1/auth/me` | JWT | - | Obtener perfil del usuario autenticado | `src/auth/auth.controller.ts` |
| DELETE | `/api/v1/auth/me` | JWT | - | Eliminar cuenta (Apple 5.1.1v). Body: `{ password }`. Rate limit 1/h. Soft-delete + PII anonimizado + sesiones revocadas + FCM desactivado | `src/auth/auth.controller.ts` |
| PATCH | `/api/v1/auth/me/context` | JWT | - | Cambiar contexto activo de club/instancia | `src/auth/auth.controller.ts` |
| POST | `/api/v1/auth/update-password` | JWT | - | Actualizar la contraseña del usuario autenticado | `src/auth/auth.controller.ts` |
| POST | `/api/v1/auth/verify-email/send` | JWT | - | Enviar email de verificación al usuario autenticado | `src/auth/auth.controller.ts` |
| POST | `/api/v1/auth/verify-email/confirm` | Public | - | Confirmar verificación de email con token | `src/auth/auth.controller.ts` |
| POST | `/api/v1/auth/mfa/enroll` | JWT | - | Iniciar enrolamiento de 2FA | `src/auth/mfa.controller.ts` |
| GET | `/api/v1/auth/mfa/status` | JWT | - | Verificar estado de 2FA | `src/auth/mfa.controller.ts` |
| DELETE | `/api/v1/auth/mfa/disable` | JWT | - | Deshabilitar 2FA | `src/auth/mfa.controller.ts` |
| POST | `/api/v1/auth/mfa/verify` | JWT | - | Verificar y activar 2FA | `src/auth/mfa.controller.ts` |
| DELETE | `/api/v1/auth/oauth/:provider` | JWT | - | Desconectar un provider | `src/auth/oauth.controller.ts` |
| POST | `/api/v1/auth/oauth/apple` | Public | - | Iniciar autenticación con Apple | `src/auth/oauth.controller.ts` |
| POST | `/api/v1/auth/oauth/callback` | Public | - | Finalizar callback de OAuth con sesión Better Auth | `src/auth/oauth.controller.ts` |
| POST | `/api/v1/auth/oauth/google` | Public | - | Iniciar autenticación con Google | `src/auth/oauth.controller.ts` |
| GET | `/api/v1/auth/oauth/providers` | JWT | - | Obtener providers conectados | `src/auth/oauth.controller.ts` |
| POST | `/api/v1/auth/password/reset-request` | Public | - | Solicitar recuperación de contraseña | `src/auth/auth.controller.ts` |
| GET | `/api/v1/auth/profile/completion-status` | JWT | - | Obtener estado del post-registro | `src/auth/auth.controller.ts` |
| POST | `/api/v1/auth/register` | Public | - | Registrar nuevo usuario | `src/auth/auth.controller.ts` |
| DELETE | `/api/v1/auth/sessions` | JWT | - | Revocar todas las sesiones excepto la actual (200 `{ revoked_count: N }`). Rate: 10/min/user | `src/auth/sessions.controller.ts` |
| GET | `/api/v1/auth/sessions` | JWT | - | Listar sesiones activas del usuario. Responde `{ sessions[], current_session_id }`. `is_current` requiere JWT con claim `sid`. Rate: 30/min/user | `src/auth/sessions.controller.ts` |
| DELETE | `/api/v1/auth/sessions/:sessionId` | JWT | - | Revocar sesión específica (204). 400 si es la sesión actual, 403 si pertenece a otro usuario, 404 si no existe. Rate: 10/min/user | `src/auth/sessions.controller.ts` |

### Auth Contract Notes (2026-03-04)

- `POST /api/v1/auth/login` y `POST /api/v1/auth/refresh` responden tokens en camelCase: `accessToken`, `refreshToken`, `expiresAt`, `tokenType`.
- Contrato oficial de refresh: body con `refreshToken`.
- Ventana temporal legacy: **2026-03-04** a **2026-03-18** con `AUTH_REJECT_SNAKE_CASE=false` para aceptar `refresh_token`.
- Fecha objetivo de retorno a estricto: **2026-03-18** con `AUTH_REJECT_SNAKE_CASE=true`.
- `POST /api/v1/auth/logout` es fail-safe (best effort): no requiere JWT válido, acepta bearer opcional y `refreshToken` opcional en body.
- `POST /api/v1/auth/oauth/callback` finaliza el flujo OAuth del lado SACDIA después de que Better Auth resolvió su callback interno `GET /api/auth/callback/{provider}`.
- El body de `POST /api/v1/auth/oauth/callback` usa `session_token`, `provider` y `redirect_uri?`.
- `POST /api/v1/auth/mfa/verify` canjea un JWT `aal1` (`mfa_pending: true`) por un nuevo `accessToken` `aal2`.
- **Sessions (2026-04)**: JWTs ahora incluyen claim `sid` (BA session row UUID). `GET /auth/sessions` usa `sid` para marcar `is_current`. Tokens anteriores a este cambio no tienen `sid` — `is_current` será false para todas las sesiones. La tabla usada es `sessions` (Prisma model `session`, BA schema). `DELETE /auth/sessions/:id` devuelve 204. `DELETE /auth/sessions` devuelve 200 con `{ revoked_count }`. El endpoint `POST /auth/mfa/verify` preserva el claim `sid` del token aal1 en el token aal2 resultante.

## users

### GDPR Data Export (mobile Settings screen)

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| POST | `/api/v1/users/me/data-export` | JWT | - | Solicitar exportación de datos GDPR. Body opcional: `{ format?: "json" }`. 201 nuevo job, 200 si ya existe uno pendiente/procesando, 429 si hay export `ready` en las últimas 24h (body: `{ retry_after_seconds, export_id }`). Rate limit Throttle: 1/min short, 2/h medium. | `src/data-export/data-export.controller.ts` |
| GET | `/api/v1/users/me/data-exports` | JWT | - | Listar todos los exports del usuario. Responde `{ exports: [{ export_id, status, format, file_size_bytes, created_at, completed_at, expires_at, failure_reason }] }`. Status posibles: `pending\|processing\|ready\|failed\|expired` | `src/data-export/data-export.controller.ts` |
| GET | `/api/v1/users/me/data-exports/:exportId/download` | JWT | - | Obtener URL presignada de R2 (TTL 15 min) para un export `ready`. 200 `{ url, expires_at }`, 404 no existe o cross-user, 409 pending/processing, 410 expired, 422 failed. Audit log en cada download. | `src/data-export/data-export.controller.ts` |

### User notification preferences (mobile Settings screen)

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1/users/me/notification-preferences` | JWT | - | Obtener preferencias de notificación del usuario. Retorna `{ master, activities, achievements, approvals, invitations, reminders }`. Categorías sin fila en DB default a `true` (modelo opt-out) | `src/notifications/user-notification-preferences.controller.ts` |
| PATCH | `/api/v1/users/me/notification-preferences` | JWT | - | Actualizar preferencias parcialmente. `master=false` desactiva todas las categorías. `master=true` activa todas. Categorías individuales se pueden togglear independientemente | `src/notifications/user-notification-preferences.controller.ts` |
| POST | `/api/v1/users/me/fcm-tokens` | JWT | - | Registrar token FCM del dispositivo. Upsert — si existe se re-activa y re-asocia al usuario actual | `src/notifications/user-notification-preferences.controller.ts` |
| DELETE | `/api/v1/users/me/fcm-tokens/:tokenId` | JWT | - | Desregistrar token FCM por UUID de registro (no por valor del token). Retorna 403 si el token pertenece a otro usuario | `src/notifications/user-notification-preferences.controller.ts` |

### User CRUD endpoints

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1/users/:userId` | JWT | - | Obtener información de un usuario | `src/users/users.controller.ts` |
| PATCH | `/api/v1/users/:userId` | JWT | - | Actualizar información personal del usuario | `src/users/users.controller.ts` |
| GET | `/api/v1/users/:userId/allergies` | JWT | - | Obtener alergias activas del usuario | `src/users/users.controller.ts` |
| GET | `/api/v1/users/:userId/diseases` | JWT | - | Obtener enfermedades activas del usuario | `src/users/users.controller.ts` |
| GET | `/api/v1/users/:userId/medicines` | JWT | - | Obtener medicamentos activos del usuario | `src/users/users.controller.ts` |
| PUT | `/api/v1/users/:userId/allergies` | JWT | - | Guardar alergias del usuario | `src/users/users.controller.ts` |
| PUT | `/api/v1/users/:userId/diseases` | JWT | - | Guardar enfermedades del usuario | `src/users/users.controller.ts` |
| PUT | `/api/v1/users/:userId/medicines` | JWT | - | Guardar medicamentos del usuario | `src/users/users.controller.ts` |
| DELETE | `/api/v1/users/:userId/allergies/:allergyId` | JWT | `health:update` OR `users:update` (owner bypass) | Eliminar una alergia activa del usuario (soft delete) | `src/users/users.controller.ts` |
| DELETE | `/api/v1/users/:userId/diseases/:diseaseId` | JWT | `health:update` OR `users:update` (owner bypass) | Eliminar una enfermedad activa del usuario (soft delete) | `src/users/users.controller.ts` |
| DELETE | `/api/v1/users/:userId/medicines/:medicineId` | JWT | `health:update` OR `users:update` (owner bypass) | Eliminar un medicamento activo del usuario (soft delete) | `src/users/users.controller.ts` |
| GET | `/api/v1/users/:userId/age` | JWT | - | Calcular edad del usuario | `src/users/users.controller.ts` |
| GET | `/api/v1/users/:userId/classes` | JWT | - | Obtener inscripciones del usuario | `src/classes/classes.controller.ts` |
| GET | `/api/v1/users/:userId/classes/:classId/progress` | JWT | - | Obtener progreso anual del usuario en una clase (`?enrollmentId=` opcional) | `src/classes/classes.controller.ts` |
| PATCH | `/api/v1/users/:userId/classes/:classId/progress` | JWT | - | Actualizar progreso anual de sección (`enrollment_id` opcional) | `src/classes/classes.controller.ts` |
| POST | `/api/v1/users/:userId/classes/enroll` | JWT | - | Inscribir usuario en clase | `src/classes/classes.controller.ts` |
| GET | `/api/v1/users/:userId/emergency-contacts` | JWT | - | Listar contactos de emergencia del usuario | `src/emergency-contacts/emergency-contacts.controller.ts` |
| POST | `/api/v1/users/:userId/emergency-contacts` | JWT | `emergency_contacts:update` OR `users:update` (owner bypass) | Crear contacto de emergencia (máximo 5) | `src/emergency-contacts/emergency-contacts.controller.ts` |
| DELETE | `/api/v1/users/:userId/emergency-contacts/:contactId` | JWT | - | Eliminar contacto de emergencia (soft delete) | `src/emergency-contacts/emergency-contacts.controller.ts` |
| GET | `/api/v1/users/:userId/emergency-contacts/:contactId` | JWT | - | Obtener un contacto específico | `src/emergency-contacts/emergency-contacts.controller.ts` |
| PATCH | `/api/v1/users/:userId/emergency-contacts/:contactId` | JWT | - | Actualizar contacto de emergencia | `src/emergency-contacts/emergency-contacts.controller.ts` |
| GET | `/api/v1/users/:userId/honors` | JWT | - | Obtener honores del usuario | `src/honors/honors.controller.ts` |
| POST | `/api/v1/users/:userId/honors` | JWT | - | Registrar honor con datos iniciales (o reactivar) | `src/honors/honors.controller.ts` |
| POST | `/api/v1/users/:userId/honors/bulk` | JWT | - | Registrar honores de usuario de forma masiva | `src/honors/honors.controller.ts` |
| GET | `/api/v1/users/:userId/honors/stats` | JWT | - | Obtener estadísticas de honores del usuario | `src/honors/honors.controller.ts` |
| DELETE | `/api/v1/users/:userId/honors/:honorId` | JWT | - | Abandonar honor | `src/honors/honors.controller.ts` |
| PATCH | `/api/v1/users/:userId/honors/:honorId` | JWT | - | Actualizar progreso de honor | `src/honors/honors.controller.ts` |
| POST | `/api/v1/users/:userId/honors/:honorId` | JWT | - | Iniciar un honor | `src/honors/honors.controller.ts` |
| POST | `/api/v1/users/:userId/honors/:honorId/files` | JWT | - | Subir evidencias del honor (multipart: certificate, document, images) | `src/honors/honors.controller.ts` |
| GET | `/api/v1/users/:userId/honors/:honorId/requirements/progress` | JWT | - | Obtener progreso del usuario por requisito de un honor | `src/honors/honors.controller.ts` |
| PATCH | `/api/v1/users/:userId/honors/:honorId/requirements/:requirementId/progress` | JWT | - | Actualizar progreso de un requisito individual | `src/honors/honors.controller.ts` |
| PATCH | `/api/v1/users/:userId/honors/:honorId/requirements/progress/batch` | JWT | - | Actualizar progreso de múltiples requisitos en lote | `src/honors/honors.controller.ts` |
| DELETE | `/api/v1/users/:userId/legal-representative` | JWT | - | Eliminar representante legal | `src/legal-representatives/legal-representatives.controller.ts` |
| GET | `/api/v1/users/:userId/legal-representative` | JWT | - | Obtener representante legal del usuario | `src/legal-representatives/legal-representatives.controller.ts` |
| PATCH | `/api/v1/users/:userId/legal-representative` | JWT | - | Actualizar representante legal | `src/legal-representatives/legal-representatives.controller.ts` |
| POST | `/api/v1/users/:userId/legal-representative` | JWT | `legal_representative:update` OR `users:update` (owner bypass) | Registrar representante legal (solo para menores de 18) | `src/legal-representatives/legal-representatives.controller.ts` |
| GET | `/api/v1/users/:userId/post-registration/status` | JWT | - | Obtener estado del post-registro | `src/post-registration/post-registration.controller.ts` |
| POST | `/api/v1/users/:userId/post-registration/step-1/complete` | JWT | - | Completar Paso 1: Foto de perfil | `src/post-registration/post-registration.controller.ts` |
| POST | `/api/v1/users/:userId/post-registration/step-2/complete` | JWT | - | Completar Paso 2: Información personal | `src/post-registration/post-registration.controller.ts` |
| POST | `/api/v1/users/:userId/post-registration/step-3/complete` | JWT | - | Completar Paso 3: selección de club y alta anual en `enrollments` | `src/post-registration/post-registration.controller.ts` |
| DELETE | `/api/v1/users/:userId/profile-picture` | JWT | - | Eliminar foto de perfil | `src/users/users.controller.ts` |
| POST | `/api/v1/users/:userId/profile-picture` | JWT | - | Subir foto de perfil | `src/users/users.controller.ts` |
| GET | `/api/v1/users/:userId/requires-legal-representative` | JWT | - | Verificar si el usuario requiere representante legal | `src/users/users.controller.ts` |

### insurance

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1/clubs/:clubId/sections/:sectionId/members/insurance` | JWT | `insurance:read` | Listar miembros de una sección con su seguro activo más reciente | `src/insurance/insurance.controller.ts` |
| GET | `/api/v1/insurance/expiring` | JWT | admin, coordinator (GlobalRoles) | Listar seguros próximos a vencer para monitoreo administrativo global; query: `days_ahead?`, `local_field_id?` | `src/insurance/insurance.controller.ts` |
| GET | `/api/v1/users/:memberId/insurance` | JWT | `insurance:read` | Obtener el detalle del seguro activo del miembro | `src/insurance/insurance.controller.ts` |
| POST | `/api/v1/users/:memberId/insurance` | JWT | `insurance:create` | Crear un seguro para un miembro con evidencia opcional en multipart (`evidence`) | `src/insurance/insurance.controller.ts` |
| PATCH | `/api/v1/insurance/:insuranceId` | JWT | `insurance:update` | Actualizar un seguro existente con evidencia opcional en multipart (`evidence`) | `src/insurance/insurance.controller.ts` |

### User Authorization Notes (2026-03-10)

- Las rutas `user` de esta sección no son solo "JWT-only" en semántica de autorización: runtime usa `JwtAuthGuard` + `PermissionsGuard` + `@AuthorizationResource({ type: 'user', ownerParam: 'userId' })` en las superficies sensibles verificadas de Batch 1.
- Self-service: el owner del `userId` puede operar sobre sus propias rutas sensibles.
- Admin/global access: un actor no owner necesita permiso global `users:read_detail` para lecturas o `users:update` para escrituras; permisos provenientes solo de `active_assignment` no habilitan acceso transversal a recursos `user`.
- Familias sensibles directas del change:
  - `health`: `GET/PUT /allergies`, `GET/PUT /diseases`, `GET/PUT /medicines`, `DELETE` item-level de las tres colecciones.
  - `emergency_contacts`: `GET/POST/PATCH/DELETE /emergency-contacts`.
  - `legal_representative`: `GET/POST/PATCH/DELETE /legal-representative`.
  - `post_registration`: `GET /post-registration/status`, `POST /step-{1,2,3}/complete`.
- OR transicional vigente: para terceros, cada familia acepta su permiso fino (`family:read`/`family:update`) o el fallback legacy de la familia `users:*` (`users:read_detail` para lectura, `users:update` para escritura).
- Baseline health activo: `allergies` + `diseases` + `medicines` como sub-recursos sensibles de `user`; `DELETE` por item está verificado en runtime.
- Excepción mínima de terceros en `post_registration`: `GET /api/v1/users/:userId/post-registration/status` permite lectura administrativa mínima, y `POST /api/v1/users/:userId/post-registration/step-{1,2,3}/complete` permite completion administrativa mínima.
- Exclusiones fuera de scope del change: `GET/PATCH /api/v1/users/:userId`, `POST/DELETE /api/v1/users/:userId/profile-picture`, `GET /api/v1/users/:userId/age` y `GET /api/v1/users/:userId/requires-legal-representative` siguen en metadata legacy `users:*`.
- Para terceros no owner, `status` debe mantenerse en estado administrativo mínimo y `step-{1,2,3}/complete` no debe filtrar razones sensibles detalladas del usuario objetivo.

### Post-registration step 3 runtime notes (FS-02)

- `POST /api/v1/users/:userId/post-registration/step-3/complete` ahora completa el alta operativa anual en `enrollments` como condición de éxito del paso.
- El flujo mantiene idempotencia para reintentos: reusa/reactiva el tuple único `(user_id, class_id, ecclesiastical_year_id)` y evita duplicados por conflicto de unicidad.
- Si el usuario cambia de clase en el mismo año eclesiástico, el backend desactiva otros `enrollments` activos de ese año antes de resolver el seleccionado.
- `users_classes` fue archivada como `users_classes_archive` en la migración y ya no existe en el modelo operativo. El histórico consolidado ahora se resuelve desde `enrollments`.

### Class progress runtime notes (FS-03)

- `GET/PATCH /api/v1/users/:userId/classes/:classId/progress` siguen siendo class-scoped en la ruta, pero el owner real del progreso es `enrollments.enrollment_id`.
- Sin override explícito, el backend resuelve una sola inscripción activa del año eclesiástico actual para `(userId, classId)`.
- `GET` acepta `?enrollmentId=` y `PATCH` acepta `enrollment_id` como override aditivo para seleccionar una inscripción anual específica.
- Si no existe inscripción anual resoluble, la API responde `404`.
- Si la resolución class-scoped es ambigua y no se envía override, la API responde `409` con código `ENROLLMENT_RESOLUTION_AMBIGUOUS`.
- El payload exitoso de lectura expone `enrollment_id` y `ecclesiastical_year_id` para hacer visible el owner anual resuelto.

## activities

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| DELETE | `/api/v1/activities/:activityId` | JWT | - | Desactivar actividad | `src/activities/activities.controller.ts` |
| GET | `/api/v1/activities/:activityId` | JWT | - | Obtener actividad por ID | `src/activities/activities.controller.ts` |
| PATCH | `/api/v1/activities/:activityId` | JWT | - | Actualizar actividad. Acepta `club_section_ids` e `is_joint` para reasociar secciones (upsert) | `src/activities/activities.controller.ts` |
| GET | `/api/v1/activities/:activityId/attendance` | JWT | - | Obtener asistencia | `src/activities/activities.controller.ts` |
| POST | `/api/v1/activities/:activityId/attendance` | JWT | - | Registrar asistencia | `src/activities/activities.controller.ts` |

## achievements

> **NO CANON** — Feature operativa documentada sin promocion al canon. Autoridad: `src/achievements/*.ts` y `prisma/schema.prisma`.

### achievements — user surface

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1/achievements` | JWT | - | Catalogo de logros agrupado por categoria, paginado. Logros secretos no completados aparecen con `name = "???"` y `description = "???"`. Query: `categoryId?`, `page?`, `limit?` | `src/achievements/achievements.controller.ts` |
| GET | `/api/v1/achievements/me` | JWT | - | Resumen del usuario autenticado: `summary` con `total_completed`, `total_points`, `completion_percentage` y logros agrupados con progreso | `src/achievements/achievements.controller.ts` |
| GET | `/api/v1/achievements/categories` | JWT | - | Categorias activas ordenadas por `display_order` | `src/achievements/achievements.controller.ts` |
| GET | `/api/v1/achievements/:achievementId` | JWT | - | Detalle del logro con progreso del usuario. Responde `{ achievement, userProgress }`. Logros secretos no completados se enmascaran. | `src/achievements/achievements.controller.ts` |

### achievements — admin surface

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1/admin/achievements/stats` | JWT | admin, super_admin + `achievements:manage` | Estadisticas del dashboard: totales, tasas de completado, logros mas y menos desbloqueados | `src/achievements/admin/admin-achievements.controller.ts` |
| GET | `/api/v1/admin/achievements/categories` | JWT | admin, super_admin + `achievements:manage` | Listar categorias (vista admin) | `src/achievements/admin/admin-achievements.controller.ts` |
| POST | `/api/v1/admin/achievements/categories` | JWT | admin, super_admin + `achievements:manage` | Crear categoria | `src/achievements/admin/admin-achievements.controller.ts` |
| PATCH | `/api/v1/admin/achievements/categories/:categoryId` | JWT | admin, super_admin + `achievements:manage` | Actualizar categoria | `src/achievements/admin/admin-achievements.controller.ts` |
| DELETE | `/api/v1/admin/achievements/categories/:categoryId` | JWT | admin, super_admin + `achievements:manage` | Soft-delete de categoria. Responde 409 si tiene logros activos. | `src/achievements/admin/admin-achievements.controller.ts` |
| GET | `/api/v1/admin/achievements` | JWT | admin, super_admin + `achievements:manage` | Listar logros (vista admin, paginado). Query: `type?`, `categoryId?`, `active?`, `page?`, `limit?` | `src/achievements/admin/admin-achievements.controller.ts` |
| POST | `/api/v1/admin/achievements` | JWT | admin, super_admin + `achievements:manage` | Crear logro. Valida criterios segun tipo antes de persistir. | `src/achievements/admin/admin-achievements.controller.ts` |
| GET | `/api/v1/admin/achievements/:achievementId` | JWT | admin, super_admin + `achievements:manage` | Obtener logro por ID (vista admin, sin masking) | `src/achievements/admin/admin-achievements.controller.ts` |
| PATCH | `/api/v1/admin/achievements/:achievementId` | JWT | admin, super_admin + `achievements:manage` | Actualizar logro | `src/achievements/admin/admin-achievements.controller.ts` |
| DELETE | `/api/v1/admin/achievements/:achievementId` | JWT | admin, super_admin + `achievements:manage` | Soft-delete de logro (`active = false`) | `src/achievements/admin/admin-achievements.controller.ts` |
| POST | `/api/v1/admin/achievements/:achievementId/image` | JWT | admin, super_admin + `achievements:manage` | Subir badge (multipart, campo `file`, max 2 MB, PNG/SVG/WebP). Guarda en R2 y actualiza `badge_image_key`. | `src/achievements/admin/admin-achievements.controller.ts` |
| POST | `/api/v1/admin/achievements/retroactive/:achievementId` | JWT | admin, super_admin + `achievements:manage` | Disparar evaluacion retroactiva para todos los usuarios que no completaron el logro | `src/achievements/admin/admin-achievements.controller.ts` |

### Achievements Contract Notes (2026-04-15)

- La superficie de usuario exige `JwtAuthGuard`. La superficie admin exige `JwtAuthGuard` + `GlobalRolesGuard` (`admin|super_admin`) + `PermissionsGuard` (`achievements:manage`).
- `GET /api/v1/achievements` devuelve `{ categories: [...], meta: { total, page, limit, totalPages } }`.
- `GET /api/v1/achievements/me` devuelve `{ summary: { total_completed, total_points, completion_percentage }, ... }` con logros agrupados.
- `GET /api/v1/achievements/:achievementId` devuelve wrapper `{ achievement, userProgress }`, no un objeto plano; el cliente movil tiene drift puntual en este contrato (Por verificar en cliente).
- El masking de logros secretos aplica solo en la superficie de usuario; la superficie admin no enmascara.
- La evaluacion de eventos persiste primero en `achievement_event_log` y luego intenta encolar en BullMQ; si la cola no esta disponible, el evento queda persistido sin encolarse.
- Drift de cliente admin verificado (no corregido en este trabajo): usa `PUT` donde el controller expone `PATCH`; usa `scope` con valores `GLOBAL|CLUB|UNIT` donde Prisma define `GLOBAL|CLUB_TYPE|ECCLESIASTICAL_YEAR`; envia campo multipart `image` donde el controller exige `file`.

## admin

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1/admin/allergies` | JWT | super_admin, admin | List allergies for admin management | `src/admin/admin-reference.controller.ts` |
| POST | `/api/v1/admin/allergies` | JWT | super_admin, admin | Create allergy | `src/admin/admin-reference.controller.ts` |
| DELETE | `/api/v1/admin/allergies/:allergyId` | JWT | super_admin, admin | Soft delete allergy | `src/admin/admin-reference.controller.ts` |
| PATCH | `/api/v1/admin/allergies/:allergyId` | JWT | super_admin, admin | Update allergy | `src/admin/admin-reference.controller.ts` |
| GET | `/api/v1/admin/club-ideals` | JWT | super_admin, admin | List club ideals for admin | `src/admin/admin-reference.controller.ts` |
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
| GET | `/api/v1/admin/honor-categories` | JWT | super_admin, admin | List honor categories for admin management | `src/admin/admin-reference.controller.ts` |
| POST | `/api/v1/admin/honor-categories` | JWT | super_admin, admin | Create honor category | `src/admin/admin-reference.controller.ts` |
| GET | `/api/v1/admin/honor-categories/:id` | JWT | super_admin, admin | Get honor category by ID | `src/admin/admin-reference.controller.ts` |
| DELETE | `/api/v1/admin/honor-categories/:id` | JWT | super_admin, admin | Soft delete honor category | `src/admin/admin-reference.controller.ts` |
| PATCH | `/api/v1/admin/honor-categories/:id` | JWT | super_admin, admin | Update honor category | `src/admin/admin-reference.controller.ts` |
| GET | `/api/v1/admin/local-fields` | JWT | super_admin, admin | List local fields for admin management | `src/admin/admin-geography.controller.ts` |
| POST | `/api/v1/admin/local-fields` | JWT | super_admin, admin | Create local field | `src/admin/admin-geography.controller.ts` |
| DELETE | `/api/v1/admin/local-fields/:localFieldId` | JWT | super_admin, admin | Soft delete local field | `src/admin/admin-geography.controller.ts` |
| PATCH | `/api/v1/admin/local-fields/:localFieldId` | JWT | super_admin, admin | Update local field | `src/admin/admin-geography.controller.ts` |
| GET | `/api/v1/admin/medicines` | JWT | super_admin, admin | List medicines for admin management | `src/admin/admin-reference.controller.ts` |
| POST | `/api/v1/admin/medicines` | JWT | super_admin, admin | Create medicine | `src/admin/admin-reference.controller.ts` |
| DELETE | `/api/v1/admin/medicines/:medicineId` | JWT | super_admin, admin | Soft delete medicine | `src/admin/admin-reference.controller.ts` |
| PATCH | `/api/v1/admin/medicines/:medicineId` | JWT | super_admin, admin | Update medicine | `src/admin/admin-reference.controller.ts` |
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
| POST | `/api/v1/admin/catalogs/cache/invalidate` | JWT | `catalogs:update` | Invalida manualmente todo el cache Redis de catálogos (14 keys). Graceful fallback si Redis no está disponible. | `src/admin/admin-cache.controller.ts` |
| GET | `/api/v1/admin/users` | JWT | `users:read` | Listar usuarios administrativos con alcance por rol (ALL/UNION/LOCAL_FIELD) | `src/admin/admin-users.controller.ts` |
| GET | `/api/v1/admin/users/:userId` | JWT | `users:read_detail` | Obtener detalle de usuario validando alcance por rol del actor | `src/admin/admin-users.controller.ts` |
| PATCH | `/api/v1/admin/users/:userId` | JWT | `users:update` | Actualizar campos administrativos del usuario | `src/admin/admin-users.controller.ts` |
| PATCH | `/api/v1/admin/users/:userId/approval` | JWT | `users:update` | Aprobar o rechazar un usuario administrativo | `src/admin/admin-users.controller.ts` |

### Admin user detail transitional formative contract (FS-01)

- Endpoint: `GET /api/v1/admin/users/:userId`
- Envelope se mantiene: `{ status, data }`
- `data.current_operational_enrollment`: fuente anual operativa (SOLO `enrollments` del año eclesiástico activo)
- `data.trajectory_classes`: trayectoria consolidada/histórica (SOLO `enrollments` archivados en `users_classes_archive`)
- `data.classes`: alias legacy **deprecado**; mantiene semántica de trayectoria y NO representa verdad operativa anual
- Reglas de nulidad:
  - si no hay año eclesiástico activo -> `current_operational_enrollment = null`
  - si no hay enrollment activo del año -> `current_operational_enrollment = null`
  - si hay más de un enrollment candidato del año -> `current_operational_enrollment = null` (sin inferencia)
- Consumers actualizados deben leer presente desde `current_operational_enrollment` e histórico desde `trajectory_classes`; no reconstruir presente con `trajectory_classes/classes`

### Pruning administrativo de bloques sensibles

- Endpoint: `GET /api/v1/admin/users/:userId`
- El response poda bloques sensibles según los permisos del actor, agrupados por familia:
  - `health`
  - `emergency_contacts`
  - `legal_representative`
  - `post_registration`
- Cada bloque se incluye en el response **solo** si el actor posee el permiso `{family}:read` o el fallback legacy `users:read_detail`
- Si el actor no tiene el permiso correspondiente, el bloque se omite del objeto `data` sin error
- Reglas detalladas: ver [`SECURITY-GUIDE.md` § Pruning administrativo](SECURITY-GUIDE.md)

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
| GET | `/api/v1/catalogs/activity-types` | Public | - | Obtener tipos de actividad | `src/catalogs/catalogs.controller.ts` |
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
| POST | `/api/v1/clubs/:clubId/activities` | JWT | director, subdirector, secretary, counselor | Crear actividad. Acepta `club_section_ids` e `is_joint` para actividades conjuntas (multi-seccion) | `src/activities/activities.controller.ts` |
| GET | `/api/v1/clubs/:clubId/finances` | JWT | - | Listar movimientos financieros del club | `src/finances/finances.controller.ts` |
| POST | `/api/v1/clubs/:clubId/finances` | JWT | director, deputy_director, treasurer | Crear movimiento financiero | `src/finances/finances.controller.ts` |
| GET | `/api/v1/clubs/:clubId/finances/summary` | JWT | - | Resumen financiero del club | `src/finances/finances.controller.ts` |
| GET | `/api/v1/clubs/:clubId/sections` | JWT | - | Listar secciones del club | `src/clubs/clubs.controller.ts` |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId` | JWT | - | Obtener sección por ID | `src/clubs/clubs.controller.ts` |
| POST | `/api/v1/clubs/:clubId/sections` | JWT | director, subdirector | Crear sección de club (requiere director o subdirector) | `src/clubs/clubs.controller.ts` |
| PATCH | `/api/v1/clubs/:clubId/sections/:sectionId` | JWT | director, subdirector, secretary | Actualizar sección (requiere director, subdirector o secretario) | `src/clubs/clubs.controller.ts` |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId/members` | JWT | - | Listar miembros de la sección | `src/clubs/clubs.controller.ts` |
| POST | `/api/v1/clubs/:clubId/sections/:sectionId/roles` | JWT | director, subdirector, secretary | Asignar rol a un miembro (requiere director, subdirector o secretario) | `src/clubs/clubs.controller.ts` |

## fcm-tokens

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1/fcm-tokens` | JWT | - | Get current user FCM tokens | `src/notifications/notifications.controller.ts` |
| POST | `/api/v1/fcm-tokens` | JWT | - | Register FCM token | `src/notifications/notifications.controller.ts` |
| DELETE | `/api/v1/fcm-tokens/by-token` | JWT | - | Unregister FCM token by token string in request body | `src/notifications/notifications.controller.ts` |
| DELETE | `/api/v1/fcm-tokens/:id` | JWT | - | Unregister FCM token by record ID | `src/notifications/notifications.controller.ts` |
| GET | `/api/v1/fcm-tokens/user/:userId` | JWT | - | Get FCM tokens by user ID (owner/admin only) | `src/notifications/notifications.controller.ts` |

## finances

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| DELETE | `/api/v1/finances/:financeId` | JWT | `finances:delete` | Desactivar movimiento | `src/finances/finances.controller.ts` |
| GET | `/api/v1/finances/:financeId` | JWT | `finances:read` | Obtener movimiento por ID | `src/finances/finances.controller.ts` |
| PATCH | `/api/v1/finances/:financeId` | JWT | `finances:update` | Actualizar movimiento | `src/finances/finances.controller.ts` |
| GET | `/api/v1/finances/categories` | JWT | `finances:read` | Listar categorías financieras | `src/finances/finances.controller.ts` |
| GET | `/api/v1/clubs/:clubId/finances/transactions` | JWT | `finances:read` | Listado paginado para vistas avanzadas; soporta `page`, `limit`, `type`, `search`, `startDate`, `endDate`, `sortBy`, `sortOrder` | `src/finances/finances.controller.ts` |

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

## evidence-folder

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1/club-sections/:sectionId/evidence-folder` | JWT | - | Get evidence folder for club section | `src/folders/evidence-folder.controller.ts` |
| POST | `/api/v1/club-sections/:sectionId/evidence-folder/sections/:efSectionId/submit` | JWT | - | Submit evidence folder section | `src/folders/evidence-folder.controller.ts` |
| POST | `/api/v1/club-sections/:sectionId/evidence-folder/sections/:efSectionId/files` | JWT | - | Upload evidence file (multipart: file) | `src/folders/evidence-folder.controller.ts` |
| DELETE | `/api/v1/club-sections/:sectionId/evidence-folder/sections/:efSectionId/files/:fileId` | JWT | - | Delete evidence file | `src/folders/evidence-folder.controller.ts` |

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
| GET | `/api/v1/honors/grouped-by-category` | Public | - | Listar honores agrupados por categoría | `src/honors/honors.controller.ts` |
| GET | `/api/v1/honors/:honorId/requirements` | Public | - | Listar requisitos de un honor | `src/honors/honors.controller.ts` |

## honor-requirements (user progress)

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1/users/:userId/honors/:honorId/requirements/progress` | JWT | - | Obtener progreso del usuario por requisito | `src/honors/honors.controller.ts` |
| PATCH | `/api/v1/users/:userId/honors/:honorId/requirements/:requirementId/progress` | JWT | - | Actualizar progreso de un requisito individual | `src/honors/honors.controller.ts` |
| PATCH | `/api/v1/users/:userId/honors/:honorId/requirements/progress/batch` | JWT | - | Actualizar progreso de múltiples requisitos en lote | `src/honors/honors.controller.ts` |

## inventory

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1/inventory/catalogs/inventory-categories` | JWT | - | Listar categorías de inventario | `src/inventory/inventory.controller.ts` |
| GET | `/api/v1/inventory/clubs/:clubId/inventory` | JWT | - | Listar items del inventario de un club | `src/inventory/inventory.controller.ts` |
| POST | `/api/v1/inventory/clubs/:clubId/inventory` | JWT | - | Agregar nuevo item al inventario | `src/inventory/inventory.controller.ts` |
| DELETE | `/api/v1/inventory/inventory/:id` | JWT | - | Eliminar logicamente un item del inventario (`active=false`) | `src/inventory/inventory.controller.ts` |
| GET | `/api/v1/inventory/inventory/:id` | JWT | - | Obtener detalles de un item del inventario | `src/inventory/inventory.controller.ts` |
| GET | `/api/v1/inventory/inventory/:inventoryId/history` | JWT | - | Obtener historial de cambios de un item del inventario | `src/inventory/inventory.controller.ts` |
| PATCH | `/api/v1/inventory/inventory/:id` | JWT | - | Actualizar un item del inventario | `src/inventory/inventory.controller.ts` |

## notifications

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| POST | `/api/v1/notifications/broadcast` | JWT | super_admin, admin | Send notification to all users | `src/notifications/notifications.controller.ts` |
| POST | `/api/v1/notifications/club/:instanceType/:instanceId` | JWT | `notifications:club` | Send notification to club members with `active_assignment` enforcement | `src/notifications/notifications.controller.ts` |
| GET | `/api/v1/notifications/history` | JWT | - | Get paginated notification history (admin audit log or user inbox) | `src/notifications/notifications.controller.ts` |
| GET | `/api/v1/notifications/preferences` | JWT | - | Get current user notification preferences | `src/notifications/notifications.controller.ts` |
| PATCH | `/api/v1/notifications/read-all` | JWT | - | Mark all unread notifications as read | `src/notifications/notifications.controller.ts` |
| POST | `/api/v1/notifications/send` | JWT | `notifications:send` | Send notification to specific user | `src/notifications/notifications.controller.ts` |
| GET | `/api/v1/notifications/unread-count` | JWT | - | Get unread notification count for the current user | `src/notifications/notifications.controller.ts` |
| PATCH | `/api/v1/notifications/:deliveryId/read` | JWT | - | Mark a single notification delivery as read | `src/notifications/notifications.controller.ts` |
| PUT | `/api/v1/notifications/preferences/:category` | JWT | - | Update notification preference for a category | `src/notifications/notifications.controller.ts` |

## root

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1` | Public | - | Sin descripción en @ApiOperation | `src/app.controller.ts` |

## investiture

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| POST | `/api/v1/investiture/enrollments/:enrollmentId/submit` | JWT | director, counselor (ClubRoles) | Enviar enrollment al pipeline de validación. Body: `{ club_id: int, comments?: string }` | `src/investiture/investiture.controller.ts` |
| POST | `/api/v1/investiture/enrollments/:enrollmentId/club-approve` | JWT | director (ClubRoles) | Aprobar en nivel club/sección. Body: `{ comments?: string }` | `src/investiture/investiture.controller.ts` |
| POST | `/api/v1/investiture/enrollments/:enrollmentId/coordinator-approve` | JWT | admin, coordinator (GlobalRoles) | Aprobar en nivel coordinación. Body: `{ comments?: string }` | `src/investiture/investiture.controller.ts` |
| POST | `/api/v1/investiture/enrollments/:enrollmentId/field-approve` | JWT | admin (GlobalRoles) | Aprobar en nivel campo local. Body: `{ comments?: string }` | `src/investiture/investiture.controller.ts` |
| POST | `/api/v1/investiture/enrollments/:enrollmentId/invest` | JWT | admin, coordinator (GlobalRoles) | Registrar investidura formal después de `FIELD_APPROVED`. Body: `{ comments?: string }` | `src/investiture/investiture.controller.ts` |
| POST | `/api/v1/investiture/enrollments/:enrollmentId/reject` | JWT | admin, coordinator (GlobalRoles) | Rechazar enrollment en cualquier nivel del pipeline. Body: `{ reason: string }` | `src/investiture/investiture.controller.ts` |
| GET | `/api/v1/investiture/pending` | JWT | admin, coordinator (GlobalRoles) | Listar enrollments pendientes de validación. Query: `local_field_id?`, `ecclesiastical_year_id?`, `page?`, `limit?` | `src/investiture/investiture.controller.ts` |
| GET | `/api/v1/investiture/enrollments/:enrollmentId/history` | JWT | - | Historial canónico del pipeline de investidura. La autorización fina se resuelve en el service. | `src/investiture/investiture.controller.ts` |
| POST | `/api/v1/investiture/enrollments/bulk-approve` | JWT | admin, coordinator (GlobalRoles) | Aprobación masiva. Body: `{ enrollment_ids: int[], action: 'coordinator-approve'|'field-approve'|'invest', comments?: string }`. Máx 200. | `src/investiture/investiture.controller.ts` |
| POST | `/api/v1/investiture/enrollments/bulk-reject` | JWT | admin, coordinator (GlobalRoles) | Rechazo masivo. Body: `{ enrollment_ids: int[], comments: string }`. Máx 200. | `src/investiture/investiture.controller.ts` |
| POST | `/api/v1/enrollments/:enrollmentId/submit-for-validation` | JWT | director, counselor (ClubRoles) | [LEGACY] Enviar enrollment a validación de investidura. Body: `{ club_id: int, comments?: string }` | `src/investiture/investiture.controller.ts` |
| POST | `/api/v1/enrollments/:enrollmentId/validate` | JWT | admin, coordinator (GlobalRoles) | [LEGACY] Aprobar o rechazar desde la superficie simple. Body: `{ action: 'APPROVED'|'REJECTED', comments?: string }` | `src/investiture/investiture.controller.ts` |
| POST | `/api/v1/enrollments/:enrollmentId/investiture` | JWT | admin, coordinator (GlobalRoles) | [LEGACY] Registrar investidura formal. Body: `{ comments?: string }` | `src/investiture/investiture.controller.ts` |
| GET | `/api/v1/enrollments/:enrollmentId/investiture-history` | JWT | - | [LEGACY] Historial de validación de investidura. Dual-role auth in service. | `src/investiture/investiture.controller.ts` |
| GET | `/api/v1/admin/investiture/config` | JWT | admin, coordinator (GlobalRoles) | Listar configuraciones de investidura. Query: `local_field_id?` | `src/investiture/investiture.controller.ts` |
| GET | `/api/v1/admin/investiture/config/:configId` | JWT | admin, coordinator (GlobalRoles) | Obtener configuración de investidura por ID | `src/investiture/investiture.controller.ts` |
| POST | `/api/v1/admin/investiture/config` | JWT | admin (GlobalRoles) | Crear configuración de investidura | `src/investiture/investiture.controller.ts` |
| PATCH | `/api/v1/admin/investiture/config/:configId` | JWT | admin (GlobalRoles) | Actualizar configuración de investidura | `src/investiture/investiture.controller.ts` |
| DELETE | `/api/v1/admin/investiture/config/:configId` | JWT | admin (GlobalRoles) | Soft delete de configuración (`active=false`) | `src/investiture/investiture.controller.ts` |

### Investiture Contract Notes (2026-04-13)

- La superficie canónica actual es la prefijada con `/api/v1/investiture/...`; los endpoints bajo `/api/v1/enrollments/...` permanecen por compatibilidad.
- `POST /api/v1/enrollments/:enrollmentId/validate` es legacy: acepta `APPROVED|REJECTED`, pero en runtime real `APPROVED` mueve el enrollment a `CLUB_APPROVED`.
- El pipeline multietapa usa `SUBMITTED_FOR_VALIDATION -> CLUB_APPROVED -> COORDINATOR_APPROVED -> FIELD_APPROVED -> INVESTIDO`.
- `POST /api/v1/investiture/enrollments/bulk-approve` NO soporta `club-approve`; esa transición sigue siendo individual.
- `GET|POST|PATCH|DELETE /api/v1/admin/investiture/config` son endpoints activos del mismo controller y sostienen la pantalla de configuración del admin.

## resources

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| POST | `/api/v1/resources` | JWT | `resources:create` | Crear recurso (multipart/form-data, archivo max 50 MB; opcional para video_link/text) | `src/resources/resources.controller.ts` |
| GET | `/api/v1/resources` | JWT | `resources:read` | Listar recursos con paginación y filtros (tipo, categoría, tipo de club, scope, texto) | `src/resources/resources.controller.ts` |
| GET | `/api/v1/resources/:id` | JWT | `resources:read` | Obtener recurso por UUID con URL firmada si tiene archivo | `src/resources/resources.controller.ts` |
| GET | `/api/v1/resources/:id/signed-url` | JWT | `resources:read` | Generar URL firmada fresca para archivo del recurso (TTL 1 hora) | `src/resources/resources.controller.ts` |
| PATCH | `/api/v1/resources/:id` | JWT | `resources:update` | Actualizar metadatos del recurso (sin reemplazar archivo) | `src/resources/resources.controller.ts` |
| DELETE | `/api/v1/resources/:id` | JWT | `resources:delete` | Soft delete del recurso (archivo en R2 no se elimina) | `src/resources/resources.controller.ts` |
| GET | `/api/v1/resources/me` | JWT | - | Recursos visibles para el usuario autenticado según scope y tipo de club (no requiere RBAC) | `src/resources/resources-app.controller.ts` |
| GET | `/api/v1/resources/me/:id` | JWT | - | Obtener recurso individual visible para el usuario autenticado con URL firmada | `src/resources/resources-app.controller.ts` |
| GET | `/api/v1/resources/me/:id/signed-url` | JWT | - | Generar URL firmada fresca para archivo del recurso (app, TTL 1 hora) | `src/resources/resources-app.controller.ts` |

## resource-categories

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| POST | `/api/v1/resource-categories` | JWT | `resource_categories:create` | Crear categoría de recurso | `src/resources/resource-categories.controller.ts` |
| GET | `/api/v1/resource-categories` | JWT | `resource_categories:read` | Listar categorías de recursos activas | `src/resources/resource-categories.controller.ts` |
| GET | `/api/v1/resource-categories/:id` | JWT | `resource_categories:read` | Obtener categoría de recurso por ID | `src/resources/resource-categories.controller.ts` |
| PATCH | `/api/v1/resource-categories/:id` | JWT | `resource_categories:update` | Actualizar categoría de recurso | `src/resources/resource-categories.controller.ts` |
| DELETE | `/api/v1/resource-categories/:id` | JWT | `resource_categories:delete` | Soft delete de categoría (falla si tiene recursos activos) | `src/resources/resource-categories.controller.ts` |

## annual-folders-evaluation

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| POST | `/api/v1/annual-folders/:folderId/sections/:sectionId/evaluate` | JWT | `annual_folders:evaluate` | Evaluar una sección de carpeta anual (puntos + notas) | `src/annual-folders/evaluation.controller.ts` |
| POST | `/api/v1/annual-folders/:folderId/sections/:sectionId/reopen` | JWT | `annual_folders:evaluate` | Reabrir sección evaluada para re-evaluación | `src/annual-folders/evaluation.controller.ts` |
| GET | `/api/v1/annual-folders/:folderId/evaluations` | JWT | `annual_folders:evaluate` | Listar evaluaciones de una carpeta anual | `src/annual-folders/evaluation.controller.ts` |

## award-categories

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| POST | `/api/v1/award-categories` | JWT | `award_categories:create` | Crear categoría de premio | `src/annual-folders/award-categories.controller.ts` |
| GET | `/api/v1/award-categories` | JWT | `award_categories:read` | Listar categorías de premios | `src/annual-folders/award-categories.controller.ts` |
| GET | `/api/v1/award-categories/:categoryId` | JWT | `award_categories:read` | Obtener categoría de premio por ID | `src/annual-folders/award-categories.controller.ts` |
| PATCH | `/api/v1/award-categories/:categoryId` | JWT | `award_categories:update` | Actualizar categoría de premio | `src/annual-folders/award-categories.controller.ts` |
| DELETE | `/api/v1/award-categories/:categoryId` | JWT | `award_categories:delete` | Soft delete de categoría de premio | `src/annual-folders/award-categories.controller.ts` |

## rankings

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1/annual-folders/rankings` | JWT | `rankings:read` | Obtener rankings de clubes con filtros (club_type, year, category) | `src/annual-folders/rankings.controller.ts` |
| GET | `/api/v1/annual-folders/rankings/club/:enrollmentId` | JWT | `rankings:read` | Obtener rankings de un club específico | `src/annual-folders/rankings.controller.ts` |
| POST | `/api/v1/annual-folders/rankings/recalculate` | JWT | `rankings:recalculate` | Disparar recálculo manual de rankings | `src/annual-folders/rankings.controller.ts` |

## evidence-review

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1/evidence-review/pending` | JWT | admin, coordinator (GlobalRoles) | Listar evidencias pendientes de validación. Query: `type?` (folder\|class\|honor), `page?`, `limit?` | `src/evidence-review/evidence-review.controller.ts` |
| GET | `/api/v1/evidence-review/:type/:id` | JWT | admin, coordinator (GlobalRoles) | Detalle de evidencia con archivos adjuntos | `src/evidence-review/evidence-review.controller.ts` |
| POST | `/api/v1/evidence-review/:type/:id/approve` | JWT | admin, coordinator (GlobalRoles) | Aprobar evidencia | `src/evidence-review/evidence-review.controller.ts` |
| POST | `/api/v1/evidence-review/:type/:id/reject` | JWT | admin, coordinator (GlobalRoles) | Rechazar evidencia. Body: `{ reason: string }` (required) | `src/evidence-review/evidence-review.controller.ts` |
| POST | `/api/v1/evidence-review/bulk-approve` | JWT | admin, coordinator (GlobalRoles) | Aprobación masiva (mismo tipo). Body: `{ type: string, ids: int[] }` | `src/evidence-review/evidence-review.controller.ts` |
| POST | `/api/v1/evidence-review/bulk-reject` | JWT | admin, coordinator (GlobalRoles) | Rechazo masivo (mismo tipo). Body: `{ type: string, ids: int[], reason: string }` | `src/evidence-review/evidence-review.controller.ts` |
| GET | `/api/v1/evidence-review/:type/:id/history` | JWT | admin, coordinator (GlobalRoles) | Historial de validación de evidencia | `src/evidence-review/evidence-review.controller.ts` |

## analytics

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1/admin/analytics/sla-dashboard` | JWT | admin, coordinator (GlobalRoles) | Métricas SLA: pendientes, overdue, tiempos promedio, tasas de aprobación, throughput 12 semanas. Cache 60s. Scoped por campo local. | `src/analytics/analytics.controller.ts` |

## membership-requests

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1/club-sections/:clubSectionId/membership-requests` | JWT | `club_members:approve` | Listar solicitudes pendientes activas de membresia para una seccion | `src/membership-requests/membership-requests.controller.ts` |
| POST | `/api/v1/club-sections/:clubSectionId/membership-requests/:assignmentId/approve` | JWT | `club_members:approve` | Aprobar solicitud pendiente y activar la asignacion | `src/membership-requests/membership-requests.controller.ts` |
| POST | `/api/v1/club-sections/:clubSectionId/membership-requests/:assignmentId/reject` | JWT | `club_members:approve` | Rechazar solicitud pendiente con motivo opcional | `src/membership-requests/membership-requests.controller.ts` |

## monthly-reports

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1/monthly-reports/preview/:enrollmentId` | JWT | `reports:read` | Vista previa en vivo por matricula UUID + `month` + `year`; no congela datos | `src/monthly-reports/monthly-reports.controller.ts` |
| POST | `/api/v1/monthly-reports/:enrollmentId` | JWT | `reports:read` | Obtener o crear borrador unico por `(club_enrollment_id, month, year)` | `src/monthly-reports/monthly-reports.controller.ts` |
| PATCH | `/api/v1/monthly-reports/:reportId/manual-data` | JWT | `reports:read` | Actualizar datos manuales solo si el informe esta en `draft` | `src/monthly-reports/monthly-reports.controller.ts` |
| POST | `/api/v1/monthly-reports/:reportId/generate` | JWT | `reports:read` | Congelar `snapshot_data` y pasar a `generated` | `src/monthly-reports/monthly-reports.controller.ts` |
| POST | `/api/v1/monthly-reports/:reportId/submit` | JWT | `reports:read` | Pasar de `generated` a `submitted` | `src/monthly-reports/monthly-reports.controller.ts` |
| GET | `/api/v1/monthly-reports/enrollment/:enrollmentId` | JWT | `reports:read` | Listar informes por matricula UUID; acepta `status?` | `src/monthly-reports/monthly-reports.controller.ts` |
| GET | `/api/v1/monthly-reports/:reportId/pdf` | JWT | `reports:download` | Descargar PDF generado server-side; solo disponible para `generated|submitted` | `src/monthly-reports/monthly-reports.controller.ts` |
| GET | `/api/v1/monthly-reports/:reportId` | JWT | `reports:read` | Obtener informe completo con `manual_data`, `snapshot_data`, matricula y submitter | `src/monthly-reports/monthly-reports.controller.ts` |

### Monthly Reports Contract Notes (2026-04-14)

- `enrollmentId` y `reportId` son UUID en runtime; no IDs numericos.
- Los estados vigentes verificados son `draft`, `generated` y `submitted`.
- `PATCH /manual-data` acepta el shape de `UpdateManualDataDto`; no el payload legacy que algunos clientes todavia modelan.
- `GET /pdf` genera el archivo en el backend con `pdfkit`; no devuelve una URL prefirmada ni referencia a storage.

## units

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1/clubs/:clubId/units/:unitId/weekly-records` | JWT | `units:read` | Listar registros semanales activos de miembros activos de la unidad | `src/units/units.controller.ts` |
| POST | `/api/v1/clubs/:clubId/units/:unitId/weekly-records` | JWT | `units:update` | Crear registro semanal; valida pertenencia activa, unicidad `(user_id, week, year)` y scores por categoria | `src/units/units.controller.ts` |
| PATCH | `/api/v1/clubs/:clubId/units/:unitId/weekly-records/:recordId` | JWT | `units:update` | Actualizar asistencia, puntualidad, estado activo o scores por categoria del registro semanal | `src/units/units.controller.ts` |

## scoring-categories

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1/local-fields/:fieldId/scoring-categories` | JWT | `units:read` | Listar categorias de puntuacion para un campo local (division + union + propias) | `src/scoring-categories/scoring-categories.controller.ts` |

## member-of-month

| Method | Path | Auth | Roles | Description | Source |
|---|---|---|---|---|---|
| GET | `/api/v1/clubs/:clubId/sections/:sectionId/member-of-month` | JWT | `units:read` | Obtener ganador(es) del mes actual para una seccion | `src/member-of-month/member-of-month.controller.ts` |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId/member-of-month/history` | JWT | `units:read` | Obtener historial paginado de miembro del mes por seccion | `src/member-of-month/member-of-month.controller.ts` |
| POST | `/api/v1/clubs/:clubId/sections/:sectionId/member-of-month/evaluate` | JWT | `units:update` + director/sub-director/directora de la seccion | Disparar evaluacion manual del periodo solicitado; rate limit 5/min | `src/member-of-month/member-of-month.controller.ts` |

## Nota de mantenimiento

- Si cambia un controlador, regenerar este documento.
- Comando sugerido: `node /tmp/generate_live_endpoints_doc.js` (o script equivalente en repo).
