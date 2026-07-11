# Auth

**Estado**: IMPLEMENTADO

## Descripcion de dominio

El modulo de autenticacion es el punto de entrada al sistema SACDIA. Gestiona el ciclo de vida completo de la identidad del usuario: registro, login, refresh de sesion, logout, recuperacion de contrasena, autenticacion con proveedores externos (Google, Apple) y autenticacion multifactor (MFA/2FA). El runtime vigente usa Better Auth self-hosted para resolver identidad primaria y sesiones opacas, mientras el backend de SACDIA emite su JWT HS256 para consumo de API.

El registro de usuarios incluye un flujo de post-registro en tres pasos: (1) foto de perfil, (2) informacion personal completa, y (3) seleccion de club con alta anual en `enrollments`. Este flujo asegura que cada miembro tenga un perfil completo antes de acceder a las funcionalidades del club. El post-registro se trackea en la tabla `users_pr`.

El sistema no debe depender de una aprobacion global manual para que cada usuario exista o acceda a SACDIA. La regla vigente de producto separa identidad, acceso por superficie y membresia operativa: `access_app` controla acceso a app movil, `access_panel` controla acceso al panel admin, y la pertenencia real a club/seccion se resuelve por asignaciones activas. Los campos `approval_status` y `rejection_reason` quedan orientados a **revision administrativa por excepcion**, no a una cola masiva de aprobacion de todos los usuarios.

La gestion de sesiones permite listar sesiones activas y cerrar sesiones individuales o todas. El OAuth con Google y Apple esta integrado con flujos server-side que manejan callbacks de los proveedores.

## Que existe (verificado contra codigo)

### Backend (AuthModule)
- **Controllers**:
  - `src/auth/auth.controller.ts` — AuthController (register, login, refresh, logout, password reset, verify-email, me, context, completion-status, update-password)
  - `src/auth/sessions.controller.ts` — SessionsController (CRUD de sesiones)
  - `src/auth/oauth.controller.ts` — OAuthController (Google, Apple, callback, providers, disconnect)
  - `src/auth/mfa.controller.ts` — MfaController (enroll, verify, disable, status)
- **Services**: AuthService, OAuthService, MfaService (`src/common/services/mfa.service.ts`), SessionManagementService (`src/common/services/session-management.service.ts`), TokenBlacklistService (`src/common/services/token-blacklist.service.ts`)
- **23 endpoints**:
  - Auth core: `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh`, `POST /auth/logout`, `POST /auth/password/reset-request`, `POST /auth/verify-email/send`, `POST /auth/verify-email/confirm`, `POST /auth/update-password`, `GET /auth/me`, `PATCH /auth/me/context`, `GET /auth/profile/completion-status`
  - Sesiones: `GET /auth/sessions`, `DELETE /auth/sessions/:sessionId`, `DELETE /auth/sessions`
  - OAuth: `POST /auth/oauth/google`, `POST /auth/oauth/apple`, `POST /auth/oauth/callback`, `GET /auth/oauth/providers`, `DELETE /auth/oauth/:provider`
  - MFA: `POST /auth/mfa/enroll`, `POST /auth/mfa/verify`, `DELETE /auth/mfa/disable`, `GET /auth/mfa/status`

### Post-Registration (PostRegistrationModule)
- **Controller**: `src/post-registration/post-registration.controller.ts`
- **4 endpoints**:
  - `GET /api/v1/users/:userId/post-registration/status` — Estado del post-registro
  - `POST /api/v1/users/:userId/post-registration/step-1/complete` — Paso 1: foto de perfil
  - `POST /api/v1/users/:userId/post-registration/step-2/complete` — Paso 2: informacion personal
  - `POST /api/v1/users/:userId/post-registration/step-3/complete` — Paso 3: seleccion de club + alta anual en `enrollments`

### Admin
- **Login funcional**: `POST /auth/login`, `GET /auth/me`
- **Persistencia de sesion**: el panel guarda `accessToken` y `refreshToken` en cookies HTTP-only persistentes. El JWT de acceso dura hasta 8h; la sesion real se sostiene con el refresh token opaco de Better Auth por hasta 7 dias con sliding refresh.
- **Refresh automatico**: si el panel navega a `/dashboard` sin access token pero con refresh token, redirige por `/api/auth/refresh` y vuelve al destino original. Las llamadas cliente que reciben 401 refrescan una vez y reintentan antes de mandar al login.
- **Logout**: `POST /auth/logout`
- **Proteccion per-page**: via `requireAdminUser()` que verifica `access_panel`
- **Dashboard birthday celebration**: el layout protegido lee `birthday` desde `GET /auth/me`; si coincide con el dia calendario local del usuario, muestra un modal celebratorio solo durante ese dia. La opcion "no volver a mostrar hoy" se persiste en `localStorage` por `user_id + anio + MM-DD`.
- **Gestion de usuarios**: `GET /admin/users`, `GET /admin/users/:userId`, `PATCH /admin/users/:userId`, `PATCH /admin/users/:userId/approval`
- **Revision administrativa**: `PATCH /admin/users/:userId/approval` existe como superficie de revision/compatibilidad, pero no debe entenderse como aprobacion de membresia a club/seccion ni como gate global masivo.
- **Cuentas eliminadas/anónimas**: el panel usa `is_deleted` para mostrar una etiqueta traducida (`Cuenta eliminada`, `Deleted account`, etc.) sin usar el email técnico `deleted-{user_id}@sacdia.deleted` ni guardar textos de UI en campos de identidad.
- No implementa UI de: registro, MFA, OAuth, gestion de sesiones

### App Movil
- **5 screens de auth**: SplashView, LoginView, RegisterView, ForgotPasswordView, AuthGate
- Consume 9+ endpoints incluyendo login, register, logout, password reset, completion-status, context switch
- **Proteccion biometrica local**: la app implementa biometria como app-lock post-login, no como metodo de inicio de sesion. El switch de settings habilita un opt-in local y `BiometricGate` solo bloquea cuando existe una sesion autenticada vigente; si no hay sesion, login y rutas publicas no quedan cubiertas por el lock. Al cerrar sesion, expirar la sesion o eliminar la cuenta, la preferencia biometrica se limpia junto con la sesion local.
- **Dashboard birthday celebration**: `DashboardView` lee `UserEntity.birthday` desde `/auth/me`; si coincide con el dia calendario local, muestra un modal celebratorio y un banner festivo arriba de `ClubInfoCard`. El banner reabre el modal hasta que el usuario pulse "no volver a mostrar hoy"; esa decision se persiste en `SharedPreferences` por `user_id + anio + MM-DD`.
- **Post-registro paso 2**: la app precarga `gender`, `birthday`, `baptism`, `baptism_date` y `blood` desde `GET /users/:userId` al volver a datos personales. Las declaraciones explicitas "No tengo alergias/enfermedades/medicamentos" se conservan localmente en `SharedPreferences` por usuario y categoria, porque los endpoints actuales de salud exponen listas y una lista vacia no distingue "sin declarar" de "declarado como ninguno".
- **Profile update payload**: la pantalla de edicion de perfil no envia `phone` ni `address` cuando estan vacios. `PATCH /users/:userId` valida `phone` si la propiedad existe; por eso `phone: ""` debe omitirse para representar "sin telefono".
- **Eliminar cuenta**: la app pide confirmación localizada, llama `DELETE /auth/me`, limpia sesión/caché local y describe el efecto real como desactivación + anonimización de datos personales; no promete borrar historial/progreso inmediatamente.
- OAuth Google/Apple declarado pero lanza excepcion "no disponible aun"

### Base de datos
- `users` — Tabla principal con `approval_status` (pending/approved/rejected), `rejection_reason`, `access_app`, `access_panel`
- `users_pr` — Tracking de post-registro (3 pasos + estado completo + `active_club_assignment_id`)
- `users_roles` — Roles globales asignados
- `users_permissions` — Permisos directos
- `roles` — Catalogo de roles
- `permissions` — Catalogo de permisos
- `user_fcm_tokens` — Tokens FCM para push notifications
- `admin_auth_sessions` — Metadata 1:1 de sesión administrativa definida en la rama backend; no forma parte del runtime de referencia
- `admin_mfa_challenges` — Challenges administrativos MFA hash-only definidos en la rama backend; no forman parte del runtime de referencia

### Contrato de tokens
- Login y refresh responden en camelCase: `accessToken`, `refreshToken`, `expiresAt`, `tokenType`
- Refresh acepta `refreshToken` en body
- Logout es best-effort (no requiere JWT valido)
- El `refreshToken` corresponde al session token opaco de Better Auth
- MFA usa handshake `aal1` -> `POST /auth/mfa/verify` -> nuevo `accessToken` `aal2`

## Requisitos funcionales

1. Registro de usuarios con email y contrasena via Better Auth + backend SACDIA
2. Login con email/contrasena que devuelve JWT (access + refresh tokens)
3. Refresh de sesion automatico con refresh token
4. Logout con invalidacion de tokens (best effort)
5. Recuperacion de contrasena via email
6. Cambio de contrasena para usuarios autenticados
7. Post-registro en 3 pasos obligatorios antes de acceso completo
8. Paso 3 del post-registro debe crear enrollment anual en `enrollments`
9. OAuth con Google y Apple como metodos alternativos de login
10. MFA con enrolamiento TOTP, verificacion, consulta de estado y deshabilitacion
11. Gestion de sesiones (listar activas, cerrar individual, cerrar todas)
12. Contexto de club activo persistido y switcheable via `PATCH /auth/me/context`
13. Revision administrativa por excepcion para usuarios con banderas de riesgo
14. Flags de acceso diferenciados: `access_app` y `access_panel`
15. La membresia activa a club/seccion debe ser el gate operativo para funcionalidades de club

## Decisiones de diseno

- **Better Auth + JWT propio**: Better Auth resuelve identidad primaria y sesiones; SACDIA firma el JWT HS256 que consumen los clientes
- **JWT en camelCase**: Ruptura deliberada con snake_case de SQL; los tokens usan camelCase para consistencia con el frontend
- **Contexto activo persistido**: `active_club_assignment_id` en `users_pr` permite que el backend resuelva autorizacion de club sin requerir que el cliente envie el contexto en cada request
- **Post-registro con enrollment**: El paso 3 no solo selecciona club sino que crea la inscripcion anual operativa
- **Revision por excepcion**: no se aprueban manualmente todos los usuarios; solo se escalan casos con riesgo o inconsistencia
- **Membresia como gate operativo**: un usuario autenticado puede existir sin membresia activa, pero las funcionalidades de club/seccion requieren una asignacion activa
- **Logout best-effort**: El logout acepta bearer opcional y no falla si el token ya expiro
- **Token blacklist**: `TokenBlacklistService` invalida tokens revocados usando Redis/Upstash como cache
- **Eliminacion de cuenta por autoservicio**: `DELETE /auth/me` revoca sesiones, desactiva FCM, marca `users.active=false`, anonimiza PII en `users`, borra credenciales/vínculos en `accounts` y registra `account_deletion_log`. Los clientes deben derivar el texto visible desde `is_deleted`/`member_is_deleted`; no se guardan etiquetas como `Cuenta eliminada` en columnas de identidad.
- **Biometria movil como app-lock**: para la release actual, la biometria movil protege una sesion local ya autenticada. No restaura tokens, no reemplaza Better Auth/JWT ni crea un contrato backend nuevo. Un login biometrico real queda fuera de alcance y debe tratarse como feature futura con diseño propio de restauracion segura de sesion.

### Sacdia Admin nativo (contrato aprobado; aún no expuesto en runtime)

- La futura fachada `/api/v1/auth/admin/*` será aditiva; no modificará los contratos ni el comportamiento de `/auth/*` legacy.
- Antes de crear sesión, firmar JWT o consultar TOTP, `validateCredentials` valida las credenciales sin efectos laterales. Luego, `AdminEligibilityService` ejecuta una consulta fresca y fail-closed sobre `users`: solo `active === true && access_panel === true` permite continuar; `access_panel = null`, usuario ausente o cualquier otro estado niegan el acceso.
- El login no contará roles GLOBAL ni asignaciones de club para decidir acceso a la superficie. Después de autenticar, cada operación seguirá exigiendo permiso RBAC y scope backend.
- La denegación de eligibility usará `AUTH_PANEL_ACCESS_DENIED` con HTTP 403, sin revelar qué bandera falló. Los errores de base de datos se propagarán y nunca habilitarán acceso.
- En la rama backend `codex/sacdia-admin-ios-auth`, hasta `ee84d2d`, están implementados `validateCredentials`, eligibility, metadata/transacción de sesión, `AdminSessionService`, JWT admin HS256 de 15 minutos, validación stateful por request, finalización transaccional AAL2, mapeo privado de errores canónicos y emisión/persistencia hash-only del challenge MFA pre-auth.
- El access token canónico usa `iss='https://api.sacdia.app'`, `aud='sacdia-admin-api'`, `surface='admin'`, `client_type='ios'`, `sid`, `jti`, `aal`, `amr` y `mfa_pending=false`, sin email. `aal1` exige `amr=['pwd']`; `aal2`, `amr=['pwd','otp']`. `iat`, `exp` y la expiración pública derivan del mismo segundo epoch. La sesión interna usa ventana de 7 días y expiración absoluta de 30 días.
- El token pre-auth MFA usa `iss='https://api.sacdia.app'`, `aud='sacdia-admin-mfa'`, `purpose='mfa'`, `mfa_pending=true`, `aal='aal1'` y `amr=['pwd']`; dura 5 minutos y solo su hash SHA-256 queda persistido. Su emisión todavía es privada.
- En esa rama, la revocación se valida contra base de datos en cada request, el parser Bearer de Passport se comparte con la comprobación de blacklist y una caída de la autoridad de sesión falla segura con HTTP 503. `JwtStrategy` conserva intactos los tokens legacy sin `surface` y valida manualmente solo `surface='admin'`. Los providers administrativos permanecen privados en `AuthModule`.
- Desde `c09a600` hasta `ee84d2d`, inclusive, solo están implementados el schema, la migración y las pruebas estáticas de persistencia refresh D1: token vigente hash-only, historial, campos de recibo con TTL exacto de 60 segundos, idle de hasta 7 días, absoluto de 30 días y sentinel Better Auth `admin-disabled:<session_id>`. No existe writer, cifrado en ejecución ni servicio de rotación.
- D1c mantiene como contrato futuro refresh opacos de 256 bits solo después de completar MFA/AAL2, `generation` monotónica, historial hasta la expiración absoluta, reuse que revoca familia + `sid`, `Idempotency-Key` UUID y recibos AES-256-GCM con keyring separado. D2 debe excluir sesiones/tokens administrativos de endpoints legacy Better Auth y nunca aceptar credenciales legacy en el flujo admin; el sentinel aislado no alcanza.
- No existe endpoint `/api/v1/auth/admin/*`, la migración no está desplegada ni verificada y ningún controller nuevo está publicado. La finalización MFA es un servicio privado y refresh sigue sin runtime; el contrato de tokens legacy permanece intacto y la fachada no debe documentarse como live.

## Gaps y pendientes

- **OAuth en app no funcional**: Google y Apple estan declarados pero lanzan excepcion "no disponible aun"
- **`POST /auth/pr-check` fantasma**: La app consume este endpoint pero no aparece en el backend
- **Admin sin UI MFA/OAuth/sesiones**: El panel admin implementa login/logout y refresh automatico, pero no tiene pantallas propias para MFA, OAuth ni gestion de sesiones.
- **Semantica legacy de approval**: `PATCH /admin/users/:userId/approval` queda como superficie de revision por excepcion/compatibilidad, no como gate de membresia; la UI principal de detalle de usuario ya no debe presentarlo como accion hero global.
- **Admin approval endpoints**: `PATCH /admin/users/:userId/approval` y `PATCH /admin/users/:userId` aparecen en el admin audit pero estaban marcados como FANTASMA en la Reality Matrix (ahora verificados en ENDPOINTS-LIVE-REFERENCE como existentes en `src/admin/admin-users.controller.ts`)
- **Banderas de revision pendientes de formalizar**: menor sin tutor legal, nombre + fecha de nacimiento identicos a otro usuario, y nombres ofensivos.

## Prioridad y siguiente accion

- **Prioridad**: Alta para alinear UI/docs/backend con el modelo de revision por excepcion y membresia activa como gate operativo
- **Siguiente accion**: formalizar banderas de revision por excepcion y verificar end-to-end el flujo de membresia pendiente con backend + app.
