# Auth

**Estado**: IMPLEMENTADO

## Descripcion de dominio

El modulo de autenticacion es el punto de entrada al sistema SACDIA. Gestiona el ciclo de vida completo de la identidad del usuario: registro, login, refresh de sesion, logout, recuperacion de contrasena, autenticacion con proveedores externos (Google, Apple) y autenticacion multifactor (MFA/2FA). El sistema delega la gestion de identidad a Supabase Auth, que actua como identity provider, y el backend de SACDIA gestiona la logica de negocio sobre esa identidad.

El registro de usuarios incluye un flujo de post-registro en tres pasos: (1) foto de perfil, (2) informacion personal completa, y (3) seleccion de club con alta anual en `enrollments`. Este flujo asegura que cada miembro tenga un perfil completo antes de acceder a las funcionalidades del club. El post-registro se trackea en la tabla `users_pr`.

El sistema soporta un flujo de aprobacion administrativa donde nuevos usuarios quedan en estado `pending` hasta que un administrador los aprueba o rechaza. Los campos `approval_status` y `rejection_reason` en la tabla `users` controlan este flujo. Ademas, cada usuario tiene flags de acceso diferenciados: `access_app` (app movil) y `access_panel` (panel admin).

La gestion de sesiones permite listar sesiones activas y cerrar sesiones individuales o todas. El OAuth con Google y Apple esta integrado con flujos server-side que manejan callbacks de los proveedores.

## Que existe (verificado contra codigo)

### Backend (AuthModule)
- **Controllers**:
  - `src/auth/auth.controller.ts` — AuthController (register, login, refresh, logout, password reset, me, context, completion-status, update-password)
  - `src/auth/sessions.controller.ts` — SessionsController (CRUD de sesiones)
  - `src/auth/oauth.controller.ts` — OAuthController (Google, Apple, callback, providers, disconnect)
  - `src/auth/mfa.controller.ts` — MfaController (enroll, verify, factors, unenroll, status)
- **Services**: AuthService, OAuthService, MfaService (`src/common/services/mfa.service.ts`), SessionManagementService (`src/common/services/session-management.service.ts`), TokenBlacklistService (`src/common/services/token-blacklist.service.ts`)
- **22 endpoints**:
  - Auth core: `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh`, `POST /auth/logout`, `POST /auth/password/reset-request`, `POST /auth/update-password`, `GET /auth/me`, `PATCH /auth/me/context`, `GET /auth/profile/completion-status`
  - Sesiones: `GET /auth/sessions`, `DELETE /auth/sessions/:sessionId`, `DELETE /auth/sessions`
  - OAuth: `POST /auth/oauth/google`, `POST /auth/oauth/apple`, `GET /auth/oauth/callback`, `GET /auth/oauth/providers`, `DELETE /auth/oauth/:provider`
  - MFA: `POST /auth/mfa/enroll`, `POST /auth/mfa/verify`, `GET /auth/mfa/factors`, `DELETE /auth/mfa/unenroll`, `GET /auth/mfa/status`

### Post-Registration (PostRegistrationModule)
- **Controller**: `src/post-registration/post-registration.controller.ts`
- **4 endpoints**:
  - `GET /api/v1/users/:userId/post-registration/status` — Estado del post-registro
  - `POST /api/v1/users/:userId/post-registration/step-1/complete` — Paso 1: foto de perfil
  - `POST /api/v1/users/:userId/post-registration/step-2/complete` — Paso 2: informacion personal
  - `POST /api/v1/users/:userId/post-registration/step-3/complete` — Paso 3: seleccion de club + alta anual en `enrollments`

### Admin
- **Login funcional**: `POST /auth/login`, `GET /auth/me`
- **Logout**: `POST /auth/logout`
- **Proteccion per-page**: via `requireAdminUser()` que verifica `access_panel`
- **Gestion de usuarios**: `GET /admin/users`, `GET /admin/users/:userId`, `PATCH /admin/users/:userId`, `PATCH /admin/users/:userId/approval`
- No implementa: registro, MFA, OAuth, gestion de sesiones

### App Movil
- **5 screens de auth**: SplashView, LoginView, RegisterView, ForgotPasswordView, AuthGate
- Consume 9+ endpoints incluyendo login, register, logout, password reset, completion-status, context switch
- OAuth Google/Apple declarado pero lanza excepcion "no disponible aun"

### Base de datos
- `users` — Tabla principal con `approval_status` (pending/approved/rejected), `rejection_reason`, `access_app`, `access_panel`
- `users_pr` — Tracking de post-registro (3 pasos + estado completo + `active_club_assignment_id`)
- `users_roles` — Roles globales asignados
- `users_permissions` — Permisos directos
- `roles` — Catalogo de roles
- `permissions` — Catalogo de permisos
- `user_fcm_tokens` — Tokens FCM para push notifications

### Contrato de tokens
- Login y refresh responden en camelCase: `accessToken`, `refreshToken`, `expiresAt`, `tokenType`
- Refresh acepta `refreshToken` en body
- Logout es best-effort (no requiere JWT valido)
- Endpoints MFA soportan header opcional `x-refresh-token` para bind de sesion

## Requisitos funcionales

1. Registro de usuarios con email y contrasena via Supabase Auth
2. Login con email/contrasena que devuelve JWT (access + refresh tokens)
3. Refresh de sesion automatico con refresh token
4. Logout con invalidacion de tokens (best effort)
5. Recuperacion de contrasena via email
6. Cambio de contrasena para usuarios autenticados
7. Post-registro en 3 pasos obligatorios antes de acceso completo
8. Paso 3 del post-registro debe crear enrollment anual en `enrollments`
9. OAuth con Google y Apple como metodos alternativos de login
10. MFA con enrolamiento, verificacion y gestion de factores
11. Gestion de sesiones (listar activas, cerrar individual, cerrar todas)
12. Contexto de club activo persistido y switcheable via `PATCH /auth/me/context`
13. Flujo de aprobacion administrativa para nuevos usuarios
14. Flags de acceso diferenciados: `access_app` y `access_panel`

## Decisiones de diseno

- **Supabase Auth como identity provider**: SACDIA no gestiona contrasenas directamente; delega a Supabase Auth
- **JWT en camelCase**: Ruptura deliberada con snake_case de SQL; los tokens usan camelCase para consistencia con el frontend
- **Contexto activo persistido**: `active_club_assignment_id` en `users_pr` permite que el backend resuelva autorizacion de club sin requerir que el cliente envie el contexto en cada request
- **Post-registro con enrollment**: El paso 3 no solo selecciona club sino que crea la inscripcion anual operativa
- **Logout best-effort**: El logout acepta bearer opcional y no falla si el token ya expiro
- **Token blacklist**: `TokenBlacklistService` invalida tokens revocados usando Redis/Upstash como cache

## Gaps y pendientes

- **OAuth en app no funcional**: Google y Apple estan declarados pero lanzan excepcion "no disponible aun"
- **`POST /auth/pr-check` fantasma**: La app consume este endpoint pero no aparece en el backend
- **Admin sin MFA/OAuth/sesiones**: El panel admin solo implementa login/logout basico
- **Migracion de approval pendiente**: La migracion Prisma para `users.approval_status` y `users.rejection_reason` existe en codigo pero tiene un bloqueo por shadow DB (`schema "extensions" does not exist`)
- **Admin approval endpoints**: `PATCH /admin/users/:userId/approval` y `PATCH /admin/users/:userId` aparecen en el admin audit pero estaban marcados como FANTASMA en la Reality Matrix (ahora verificados en ENDPOINTS-LIVE-REFERENCE como existentes en `src/admin/admin-users.controller.ts`)

## Prioridad y siguiente accion

- **Prioridad**: Alta para destrabar la migracion de approval en DB y habilitar OAuth en la app
- **Siguiente accion**: Resolver el bloqueo del shadow DB para aplicar la migracion de approval. Implementar OAuth funcional en la app movil. Investigar y resolver `POST /auth/pr-check` (endpoint fantasma consumido por la app).
