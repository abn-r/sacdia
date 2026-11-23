# Auth

**Estado**: IMPLEMENTADO

**Actualizado**: 2026-11-19 (`development`; rediseño de perfil y ajustes en la app, sacdia-app #275, e invalidación del caché de autorización en las escrituras de perfil, sacdia-backend #667).

## Descripcion de dominio

El modulo de autenticacion es el punto de entrada al sistema SACDIA. Gestiona el ciclo de vida completo de la identidad del usuario: registro, login, refresh de sesion, logout, recuperacion de contrasena, autenticacion con proveedores externos (Google, Apple) y autenticacion multifactor (MFA/2FA). El runtime vigente usa Better Auth self-hosted para resolver identidad primaria y sesiones opacas, mientras el backend de SACDIA emite su JWT HS256 para consumo de API.

El registro de usuarios incluye un flujo de post-registro en tres pasos: (1) foto de perfil, (2) informacion personal completa, y (3) seleccion de club con alta anual en `enrollments`. Este flujo asegura que cada miembro tenga un perfil completo antes de acceder a las funcionalidades del club. El post-registro se trackea en la tabla `users_pr`. Los tres pasos aplican al modo `club`; el backend deriva en cada lectura un `onboarding_mode` (`club`, `club_exempt` o `panel_only`) que decide qué pasos corresponden a cada cuenta (ver «Modo de ingreso (`onboarding_mode`)»).

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
- **24 endpoints**:
  - Auth core: `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh`, `POST /auth/logout`, `POST /auth/password/reset-request`, `POST /auth/invitation/accept` (pública; ver «Invitación de cuentas creadas desde el panel»), `POST /auth/verify-email/send`, `POST /auth/verify-email/confirm`, `POST /auth/update-password`, `GET /auth/me`, `PATCH /auth/me/context`, `GET /auth/profile/completion-status`
  - Sesiones: `GET /auth/sessions`, `DELETE /auth/sessions/:sessionId`, `DELETE /auth/sessions`
  - OAuth: `POST /auth/oauth/google`, `POST /auth/oauth/apple`, `POST /auth/oauth/callback`, `GET /auth/oauth/providers`, `DELETE /auth/oauth/:provider`
  - MFA: `POST /auth/mfa/enroll`, `POST /auth/mfa/verify`, `DELETE /auth/mfa/disable`, `GET /auth/mfa/status`

### Post-Registration (PostRegistrationModule)
- **Controller**: `src/post-registration/post-registration.controller.ts`
- **4 endpoints**:
  - `GET /api/v1/users/:userId/post-registration/photo-status` — Indica si el usuario ya subió foto de perfil
  - `GET /api/v1/users/:userId/post-registration/status` — Estado del post-registro; incluye `onboarding_mode` (también en la respuesta de un tercero, sin `nextStep`)
  - `POST /api/v1/users/:userId/post-registration/step-1/complete` — Paso 1: foto de perfil
  - `POST /api/v1/users/:userId/post-registration/step-2/complete` — Paso 2: informacion personal
  - `POST /api/v1/users/:userId/post-registration/step-3/complete` — Paso 3: seleccion de club + alta anual en `enrollments`
  - `POST /api/v1/users/:userId/post-registration/membership-request/cancel` — Cancela la solicitud de membresía pendiente para volver a elegir club/sección (`registration:complete`)

### Admin
- **Login funcional**: `POST /auth/login`, `GET /auth/me`
- **Persistencia de sesion**: el panel guarda `accessToken` y `refreshToken` en cookies HTTP-only persistentes. El JWT de acceso dura hasta 8h; la sesion real se sostiene con el refresh token opaco de Better Auth, que desliza 7 dias con cada refresh sin pasar de 30 dias desde el login. Cada refresh rota ese token y el panel guarda el nuevo en la cookie (las rutas `src/app/api/auth/*` lo hacen; el anterior vale 30 s para pestañas que refrescan a la vez).
- **Refresh automatico**: si el panel navega a `/dashboard` sin access token pero con refresh token, redirige por `/api/auth/refresh` y vuelve al destino original. Las llamadas cliente que reciben 401 refrescan una vez y reintentan antes de mandar al login.
- **Logout**: `POST /auth/logout`
- **Proteccion per-page**: via `requireAdminUser()` que verifica `access_panel`
- **Dashboard birthday celebration**: el layout protegido lee `birthday` desde `GET /auth/me`; si coincide con el dia calendario local del usuario, muestra un modal celebratorio solo durante ese dia. La opcion "no volver a mostrar hoy" se persiste en `localStorage` por `user_id + anio + MM-DD`.
- **Gestion de usuarios**: `GET /admin/users`, `GET /admin/users/:userId`, `PATCH /admin/users/:userId` (flags `access_app`, `access_panel`, `active`). El listado muestra un badge por cargo de club (director, subdirector, secretario, consejero, miembro) sin sección; el mismo cargo en varias secciones se colapsa a uno.
- **Ficha de usuario — Accesos (`access_app` / `access_panel` / `active`)**: solo `admin` y `super-admin` (y `assistant-admin` por alias de `GlobalRolesGuard`) ven esas flags: switches en Roles, grid de solo lectura en Resumen (App móvil / Panel admin / Estado) y filas equivalentes del aside. Directores de campo local (`director-lf`), unión, división o club no las ven ni las mutan. Roles de sección de club y Roles de sistema no usan este gate. `PATCH /admin/users/:userId` ya exige clase `@GlobalRoles('admin', 'super-admin')` + `users:update_admin`.
- **Ficha de usuario — Salud**: Resumen y la pestaña Salud muestran los datos médicos de frente si el actor tiene `health:read` (o el OR legado). No hay segundo click de «información protegida» en Resumen; quien no tiene el permiso no ve el bloque ni la pestaña.
- **Revision administrativa de cuenta**: el backend conserva `PATCH /admin/users/:userId/approval` y el campo `approval_status`; el panel admin **no** muestra ni muta ese estado. No confundir con post-registro ni con aprobacion de membresia de club (`club_members:approve`).
- **MFA**: el backend conserva enroll/verify/status/disable y admin reset (`GET/DELETE /admin/users/:userId/mfa`); el panel admin **no** muestra ni resetea MFA en ficha de usuario.
- **Sesiones de ficha**: el backend conserva `GET/DELETE /admin/users/:userId/sessions` (cerca `USER_MANAGEMENT_ROLES` + `users:read_detail` + recorte territorial) y self-service `GET/DELETE /auth/sessions`; el panel admin **no** muestra ni revoca sesiones en ficha de usuario.
- **Cuentas eliminadas/anónimas**: el panel usa `is_deleted` para mostrar una etiqueta traducida (`Cuenta eliminada`, `Deleted account`, etc.) sin usar el email técnico `deleted-{user_id}@sacdia.deleted` ni guardar textos de UI en campos de identidad.
- **Invitación y establecer contraseña**: `/reset-password` acepta `mode=invitation`; con él muestra el texto de invitación y publica en `POST /auth/invitation/accept` en vez de `/auth/password/reset`. Los códigos `AUTH_INVITATION_TOKEN_INVALID` y `AUTH_INVITATION_TOKEN_EXPIRED` cuentan como enlace inválido.
- **Ficha de usuario — post-registro y acceso a la cuenta**: la pestaña de post-registro muestra el modo de ingreso. Con un modo distinto de `club`, el paso 3 aparece como «No aplica» sin acción de forzar; en `panel_only` el estado global también dice «No aplica» y hay un aviso. Una tarjeta «Acceso a la cuenta» con «Reenviar invitación» aparece cuando `invitation_pending` es `true` y el actor tiene el permiso de crear usuarios (`users:create`).
- **Alta de usuarios**: el formulario y la carga masiva exigen Campo local para los roles que el backend publica en `authorization.local_field_required_roles` (hoy `pastor`); el panel no compara nombres de rol.
- No implementa UI de: registro, MFA, OAuth, gestion de sesiones

### App Movil
- **6 screens de auth**: SplashView, WelcomeCarouselView, LoginView, RegisterView, ForgotPasswordView, AuthGate
- **Carrusel de bienvenida** (`WelcomeCarouselView`, sacdia-app PR #250, 2026-11-09): aparece solo la primera vez en el dispositivo, antes del login (`welcome_carousel_seen_v7` en `SharedPreferences`; con sesión iniciada las rutas públicas redirigen y no se muestra).
  - Seis escenas animadas, una por widget en `lib/features/auth/presentation/widgets/welcome/`: logo con destello; las 13 clases y el avance de Viajero validando módulos; panal de especialidades con buscador; mazo de funciones del club; línea de tiempo de servicio; todo converge en el logo.
  - Sigue el tema del sistema. Con movimiento reducido, cada escena muestra su estado final.
  - «Omitir» y «Ya tengo cuenta» llevan al login; el logo de la última escena vuela al del login (`Hero` con `AuthTokens.brandMarkHeroTag`). «Crear cuenta» abre el registro encima del login (`go(login)` y luego `push(register)`), así que volver del registro regresa al login.
  - Textos en es, en, fr y pt-BR bajo `welcome_carousel.*`.
- **Login, registro y recuperar contraseña**: el cielo superior (`AuthSkyWash`) baja de intensidad en modo oscuro y los enlaces de texto usan `context.sac.link`. Detalle de diseño en `sacdia-app/DESIGN-SYSTEM.md` §12.5.
- Consume 9+ endpoints incluyendo login, register, logout, password reset, completion-status, context switch
- **Proteccion biometrica local**: la app implementa biometria como app-lock post-login, no como metodo de inicio de sesion. El switch de «Seguridad» (Ajustes → Seguridad y privacidad) habilita un opt-in local y `BiometricGate` solo bloquea cuando existe una sesion autenticada vigente; si no hay sesion, login y rutas publicas no quedan cubiertas por el lock. Al cerrar sesion, expirar la sesion o eliminar la cuenta, la preferencia biometrica se limpia junto con la sesion local.
- **Dashboard birthday celebration**: `DashboardView` lee `UserEntity.birthday` desde `/auth/me`; si coincide con el dia calendario local, muestra un modal celebratorio y un banner festivo arriba de `ClubInfoCard`. El banner reabre el modal hasta que el usuario pulse "no volver a mostrar hoy"; esa decision se persiste en `SharedPreferences` por `user_id + anio + MM-DD`.
- **Post-registro paso 2**: la app precarga `gender`, `birthday`, `baptism`, `baptism_date` y `blood` desde `GET /users/:userId` al volver a datos personales. Las declaraciones explicitas "No tengo alergias/enfermedades/medicamentos" se conservan localmente en `SharedPreferences` por usuario y categoria, porque los endpoints actuales de salud exponen listas y una lista vacia no distingue "sin declarar" de "declarado como ninguno".
- **Modo de ingreso**: la app lee `onboarding_mode` de `/auth/me` y del login (`OnboardingMode`; un valor ausente o desconocido se lee como `club`) y no lo infiere. `userNeedsPostRegistration` es `true` con la cuenta `profile_incomplete`, o, si el modo no es `panel_only`, mientras `post_register_complete` sea `false`. En `club_exempt` el asistente tiene 2 pasos (foto y datos personales); tras el paso 2 la app relee al usuario y, si el servidor ya marcó el post-registro como completo, entra al inicio. En `panel_only` no hay asistente: la ruta `/account/panel-only` (`PanelOnlyAccountView`) es la única pantalla, con «Cerrar sesión», «Comprobar de nuevo» y, para un tutor, «Mi familia». Una compuerta de rutas (`panel_only_route_policy.dart`) solo deja pasar esa ruta, `/access-denied` y, para un tutor, `/family/**`; no aplica mientras se actúa por un dependiente. El modo se guarda en `SharedPreferences` (`cached_onboarding_mode`) para el arranque sin conexión. Una cuenta solo de panel sí registra el token de notificaciones push. Detalle de cliente en `sacdia-app/CLAUDE.md`, «Modo de ingreso (`onboarding_mode`)».
- **Profile update payload**: la pantalla de edicion de perfil (cada fila guarda por su cuenta, ver «Rediseño de perfil y ajustes») no envia `phone` ni `address` cuando estan vacios. `PATCH /users/:userId` valida `phone` si la propiedad existe; por eso `phone: ""` debe omitirse para representar "sin telefono".
- **Eliminar cuenta**: desde Ajustes → Mis datos, al final, la app muestra primero una hoja de consecuencias que lista a los dependientes y después pide confirmación localizada, llama `DELETE /auth/me`, limpia sesión/caché local y describe el efecto real como desactivación + anonimización de datos personales; no promete borrar historial/progreso inmediatamente.
- **Rediseño de perfil y ajustes** (sacdia-app #275, 2026-11-19, en `development`):
  - **Perfil** (`profile_view.dart`): ya no hay botón «Actualizar perfil»; la insignia del avatar es un lápiz y abre `EditProfileView`.
  - **Editar perfil** (`edit_profile_view.dart`, con `edit_profile_row.dart`, `edit_profile_avatar.dart`, `profile_edit_sheets.dart` y `profile_photo_sheet.dart`): filas agrupadas (Nombre, Datos personales, Iglesia); cada una guarda por su cuenta desde una hoja inferior, las fechas abren el selector de fecha y al encender el bautismo se pide la fecha. La hoja de foto ofrece tomar foto, elegir de la galería o quitarla (con confirmación; `DELETE /users/:userId/profile-picture`, endpoint ya existente). Anillo de progreso al subir y fundido al cambiar. Tras guardar, la app refresca al usuario de autenticación en sitio con `refreshCurrentUser` en lugar de invalidarlo (invalidarlo devolvía al usuario al inicio).
  - **Ajustes** (`profile/presentation/views/settings_view.dart`) es un índice corto: fila de identidad; MI CLUB (credencial, Mi familia, Cambiar de club); PREFERENCIAS (Apariencia, Notificaciones, Idioma); SEGURIDAD Y PRIVACIDAD (Seguridad, Mis datos); DIRECTIVA (Escanear credencial, solo con `attendance:manage` o la capability `club.operational_staff`); AYUDA (Ayuda y soporte, Acerca de SACDIA); Cerrar sesión.
  - **Pantallas nuevas**: `settings/presentation/views/appearance_view.dart` (tema, color de acento, tamaño de texto con muestra, alto contraste y reducir movimiento), `notification_settings_view.dart` (interruptor general, cinco tipos con descripción y, si el sistema negó el permiso, un panel con «Abrir ajustes del teléfono»), `about_view.dart` (versión, documentos legales, caché y sincronización), `profile/presentation/views/security_view.dart` (contraseña en hoja inferior con reglas en vivo de `Validators.validatePassword` y sin campo de confirmación; desbloqueo biométrico; sesiones abiertas con una hoja por sesión y «Cerrar las otras N sesiones» vía `revokeAllOtherSessions`) y `my_data_view.dart` (estado de la exportación de datos e historial; «Eliminar mi cuenta» al final).
  - **Eliminadas**: `AccessibilityView`, la hoja de selección de acento, `ActiveSessionsView`, `DataExportView` y el diálogo de tema.
  - **Visibilidad**: la contraseña se oculta mientras se actúa por un dependiente; sesiones, exportación de datos y eliminar cuenta se ocultan mientras se actúa y para adolescentes supervisados (`isLimitedAccount`); el desbloqueo biométrico se muestra siempre.
  - **Backend** (sacdia-backend #667): `UsersService.update`, `uploadProfilePicture` y `deleteProfilePicture` invalidan el caché de autorización del usuario después de escribir en la base, porque `GET /auth/me` arma el perfil desde ese contexto cacheado (ver `runtime-sacdia.md`).
- OAuth Google/Apple declarado pero lanza excepcion "no disponible aun"

### Base de datos
- `users` — Tabla principal con `approval_status` (pending/approved/rejected), `rejection_reason`, `access_app`, `access_panel`
- `users_pr` — Tracking de post-registro (3 pasos + estado completo + `active_club_assignment_id`). Una fila por usuario (`user_id` único). Register, login social y alta de dependientes la crean; pendiente de merge (PR sacdia-backend#583): para el resto (semillas, cuentas heredadas, creadas por admin) `PostRegistrationRowService.ensure()` (`src/common/services/post-registration-row.service.ts`) la crea de forma perezosa e idempotente (`INSERT ... ON CONFLICT DO NOTHING`, todo en `false`) en `completion-status`, `post-registration/status` y los pasos 1/2/3, `guardian-only` y cancelar solicitud. Un usuario con membresía/rol de club previo no se marca como completo: pasa por el post-registro como cualquier otro
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
7. Post-registro obligatorio antes de acceso completo: 3 pasos en modo `club`, 2 en `club_exempt` y ninguno en `panel_only`
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
- **Contexto activo persistido**: `active_club_assignment_id` en `users_pr` permite que el backend resuelva autorizacion de club sin requerir que el cliente envie el contexto en cada request. La app recuerda ademas la ultima seccion elegida por usuario en el dispositivo (`SharedPreferences`, clave `preferred_section.<user_id>`, `lib/core/auth/preferred_section_store.dart`) y, tras `/auth/me` en el arranque y en cada login, si difiere de la activa que devolvio el servidor y sigue siendo seleccionable, la reafirma con `PATCH /auth/me/context`; si ya no es valida queda la del servidor y se guarda esa. Nunca se lee ni escribe mientras se actua por un dependiente. Con una sola seccion utilizable la linea/tarjeta de club no es un boton
- **Post-registro con enrollment**: El paso 3 no solo selecciona club sino que crea la inscripcion anual operativa
- **Revision por excepcion**: no se aprueban manualmente todos los usuarios; solo se escalan casos con riesgo o inconsistencia
- **Membresia como gate operativo**: un usuario autenticado puede existir sin membresia activa, pero las funcionalidades de club/seccion requieren una asignacion activa
- **Permisos operativos de club**: solo asignaciones del año eclesiástico vigente (`EcclesiasticalYearService` por fechas en `America/Mexico_City`, no flag `active` ni `year_id` suelto) con `status=active` y transición del club `completed` o ausente. `designated` y planes de sucesión **no** aparecen en `/auth/me`. `member inactive` del año vigente sí aparece en `grants` con `operational: false` y `permissions: []` (banner, no tabs). `PATCH /auth/me/context` rechaza `inactive`/`ended`/año ajeno (`AUTH_ASSIGNMENT_YEAR_MISMATCH`) y corte pendiente (`503 CLUB_CYCLE_NOT_READY`). Años solapados → `409 ECCLESIASTICAL_YEAR_AMBIGUOUS`. El corte de año **no** blacklistea JWT; cache Redis `auth:context:v8:{userId}` con revisión de calendario en el envelope y TTL recortado al fin del periodo y a la próxima frontera temporal de los cargos. Un cargo solo es `operational` dentro de su ventana `start_date`/`end_date`/`expires_at`, evaluada con la fecha de negocio del Campo Local del club (`PATCH /auth/me/context` rechaza uno fuera de ventana con `AUTH_ASSIGNMENT_YEAR_MISMATCH`).
- **Inscripción anual**: la directiva con `club_members:approve` en la sección destino. `POST /users/:userId/membership/annual-enroll` responde 403 `ANNUAL_ENROLL_REQUIRES_DIRECTIVE` (D01) incluso si el guard deja pasar al dueño.
- **Logout best-effort**: El logout acepta bearer opcional y no falla si el token ya expiro
- **Token blacklist**: `TokenBlacklistService` invalida tokens revocados usando Redis/Upstash como cache
- **Eliminacion de cuenta por autoservicio**: `DELETE /auth/me` revoca sesiones, desactiva FCM, marca `users.active=false`, anonimiza PII en `users`, borra credenciales/vínculos en `accounts` y registra `account_deletion_log`. Los clientes deben derivar el texto visible desde `is_deleted`/`member_is_deleted`; no se guardan etiquetas como `Cuenta eliminada` en columnas de identidad.
- **Biometria movil como app-lock**: para la release actual, la biometria movil protege una sesion local ya autenticada. No restaura tokens, no reemplaza Better Auth/JWT ni crea un contrato backend nuevo. Un login biometrico real queda fuera de alcance y debe tratarse como feature futura con diseño propio de restauracion segura de sesion.

### Modo de ingreso (`onboarding_mode`)

El backend deriva el modo en cada lectura (`computeOnboardingMode`, `src/common/authorization/onboarding-mode.ts`); nunca se guarda y no hay cambio de esquema. Reglas, en orden (gana la primera):

1. Al menos una asignación de club visible (`authorization.grants.club_assignments`: activa, pendiente, inactiva o vencida; las `designated` no cuentan) → `club`.
2. Capability `app.clubless_surface` (`admin_panel.pastor_only` o `coordination.hub_view`) → `club_exempt`.
3. Capability `admin_panel.access` (un rol global distinto de `user`) → `panel_only`.
4. Cualquier otro caso → `club`. Un miembro que se registra solo, con el rol `user`, sigue eligiendo club.

| Modo | Pasos | `nextStep` | `needsPostRegistration` |
|---|---|---|---|
| `club` | foto, datos personales, club | el siguiente pendiente | `!complete` |
| `club_exempt` | foto, datos personales | `profilePicture` → `personalInfo` → `null` | `!complete` tras reconciliar |
| `panel_only` | ninguno (la función vive en el panel web) | `null` | `false` |

- **Dónde se publica** (aditivo, snake_case): `data.onboarding_mode` en `GET /users/:userId/post-registration/status` (propietario y vista administrativa), en la respuesta de `POST /auth/login`, en la de `POST /auth/oauth/:provider/token` y en `GET /auth/me`. Una app anterior que lo ignora se comporta como antes.
- **`complete` honesto**: `post_register_complete` es siempre el valor de `users_pr.complete`. En `club_exempt` pasa a `true` por una reconciliación idempotente (`UPDATE ... WHERE complete = false AND profile_picture_complete AND personal_info_complete`) que corre al leer el estado, en el login y tras los pasos 1 y 2 (también tras una anulación administrativa). Cuando cambia, se invalida el caché de autorización y el de «actuar en nombre de». `complete` nunca se revoca: cancelar la solicitud de membresía de un `club_exempt` solo reinicia `club_selection_complete` y la asignación activa.
- **`panel_only`**: los pasos 1 y 2 no marcan `complete`. El paso 3 y «solo soy tutor» siguen permitidos: unirse a un club luego mueve la cuenta al modo `club`. Un tutor conserva `/family/**` («Mi familia»).
- La app no infiere el modo: lo lee del servidor (ver «App Movil»).

### Invitación de cuentas creadas desde el panel

- **Token**: identificador `admin-invitation:{userId}`, vigencia de 7 días (el restablecimiento de contraseña sigue en 1 hora). Reemitir invalida el anterior. Plantilla de correo propia en es, en, fr y pt-BR. Enlace: `{ADMIN_PANEL_URL}/reset-password?token=…&mode=invitation`. Sin `EMAIL_ENABLED=true` o sin `ADMIN_PANEL_URL` no se escribe nada y el alta responde igual con `invite_email_sent: false`.
- **Aceptar**: `POST /api/v1/auth/invitation/accept`, pública, cuerpo `{ token, password }` (`ResetPasswordDto`), throttle 5/min. En una transacción fija la contraseña, marca `email_verified` y borra el token; revoca las sesiones y no emite sesión ni JWT (el cliente inicia sesión). Token inválido → 400 `AUTH_INVITATION_TOKEN_INVALID`; vencido → 400 `AUTH_INVITATION_TOKEN_EXPIRED`. Una cuenta desactivada recibe `AUTH_INVITATION_TOKEN_INVALID` y no se escribe nada.
- **Reenviar**: `POST /api/v1/admin/users/:userId/invitation` (`USER_MANAGEMENT_ROLES` + `users:create`, throttle 10/hora por actor). Orden de errores: 404 → 403 → 400 `ADMIN_USER_INVITATION_NOT_APPLICABLE` (cuenta inactiva o sin correo) → 409 `ADMIN_USER_INVITATION_ALREADY_ACCEPTED` → 429 `ADMIN_USER_INVITATION_COOLDOWN` (60 s por usuario) → 503 `ADMIN_USER_INVITATION_UNAVAILABLE` (correo deshabilitado).
- **Cuenta activada** = `email_verified` o una fila `account` no credencial (social). `GET /admin/users/:userId` devuelve `invitation_pending`: `true` solo para una cuenta activa, con correo, no activada.
- **Pastor**: el alta exige `local_field_id` (`ROLES_REQUIRING_LOCAL_FIELD = [pastor]`): 400 `ADMIN_USER_LOCAL_FIELD_REQUIRED`; en la carga masiva, `LOCAL_FIELD_REQUIRED` por fila (la plantilla trae la columna `requiere_campo_local`). El backend publica la lista en `GET /auth/me` → `authorization.local_field_required_roles`. La fila `users_pr` se crea dentro de la transacción de alta.

### Sacdia Admin nativo (contrato aprobado; aún no expuesto en runtime)

- La futura fachada `/api/v1/auth/admin/*` será aditiva; no modificará los contratos ni el comportamiento de `/auth/*` legacy.
- Antes de crear sesión, firmar JWT o consultar TOTP, `validateCredentials` valida las credenciales sin efectos laterales. Luego, `AdminEligibilityService` ejecuta una consulta fresca y fail-closed sobre `users`: solo `active === true && access_panel === true` permite continuar; `access_panel = null`, usuario ausente o cualquier otro estado niegan el acceso.
- El login no contará roles GLOBAL ni asignaciones de club para decidir acceso a la superficie. Después de autenticar, cada operación seguirá exigiendo permiso RBAC y scope backend.
- La denegación de eligibility usará `AUTH_PANEL_ACCESS_DENIED` con HTTP 403, sin revelar qué bandera falló. Los errores de base de datos se propagarán y nunca habilitarán acceso.
- En la rama backend `codex/sacdia-admin-ios-auth`, hasta `ee84d2d`, están implementados `validateCredentials`, eligibility, metadata/transacción de sesión, `AdminSessionService`, JWT admin HS256 de 15 minutos, validación stateful por request, finalización transaccional AAL2, mapeo privado de errores canónicos y emisión/persistencia hash-only del challenge MFA pre-auth.
- El access token canónico usa `iss='https://api.sacdia.app'`, `aud='sacdia-admin-api'`, `surface='admin'`, `client_type='ios'`, `sid`, `jti`, `aal`, `amr` y `mfa_pending=false`, sin email. `aal1` exige `amr=['pwd']`; `aal2`, `amr=['pwd','otp']`. `iat`, `exp` y la expiración pública derivan del mismo segundo epoch. La sesión interna usa ventana de 7 días y expiración absoluta de 30 días.
- El token pre-auth MFA usa `iss='https://api.sacdia.app'`, `aud='sacdia-admin-mfa'`, `purpose='mfa'`, `mfa_pending=true`, `aal='aal1'` y `amr=['pwd']`; dura 5 minutos y solo su hash SHA-256 queda persistido. Su emisión todavía es privada.
- En esa rama, la revocación se valida contra base de datos en cada request, el parser Bearer de Passport se comparte con la comprobación de blacklist y una caída de la autoridad de sesión falla segura con HTTP 503. `JwtStrategy` conserva intactos los tokens legacy sin `surface` y valida manualmente solo `surface='admin'`. Los providers administrativos permanecen privados en `AuthModule`.
- Desde `c09a600` hasta `ee84d2d`, inclusive, solo están implementados el schema, la migración y las pruebas estáticas de persistencia refresh D1: token vigente hash-only, historial, campos de recibo con TTL exacto de 60 segundos, alta/backfill de `idle_expires_at` acotado por `absolute_expires_at` y sentinel Better Auth `admin-disabled:<session_id>`. La política runtime diseñada de idle 7 días/absoluto 30 días es preexistente; D1c deberá adoptarla y escribirla. No existe writer, cifrado en ejecución ni servicio de rotación.
- D1c mantiene como contrato futuro refresh opacos de 256 bits solo después de completar MFA/AAL2, `generation` monotónica, historial hasta la expiración absoluta, reuse que revoca familia + `sid`, `Idempotency-Key` UUID y recibos AES-256-GCM con keyring separado. D2 debe excluir sesiones/tokens administrativos de endpoints legacy Better Auth y nunca aceptar credenciales legacy en el flujo admin; el sentinel aislado no alcanza.
- No existe endpoint `/api/v1/auth/admin/*`, la migración no está desplegada ni verificada y ningún controller nuevo está publicado. La finalización MFA es un servicio privado y refresh sigue sin runtime; el contrato de tokens legacy permanece intacto y la fachada no debe documentarse como live.

## Gaps y pendientes

- **OAuth en app desalineado**: la app inicia Google y Apple con `GET /auth/oauth/google` y `GET /auth/oauth/apple` (`sacdia-app/lib/features/auth/data/datasources/auth_remote_data_source.dart`), pero el backend expone esas rutas como `POST` (`src/auth/oauth.controller.ts`)
- **Admin sin UI MFA/OAuth/sesiones**: El panel admin implementa login/logout y refresh automatico, pero no tiene pantallas propias para MFA, OAuth ni gestion de sesiones.
- **Semantica legacy de approval**: `PATCH /admin/users/:userId/approval` existe en backend por compatibilidad; el panel admin ya no lo consume ni muestra «Revisión administrativa» en el detalle de usuario.
- **Admin approval endpoints**: `PATCH /admin/users/:userId/approval` y `PATCH /admin/users/:userId` estan verificados en ENDPOINTS-LIVE-REFERENCE (`src/admin/admin-users.controller.ts`). El panel solo usa el PATCH generico para flags de acceso/activo, y solo lo expone en Accesos a actores `admin` / `super-admin`.
- **Límites conocidos del modo de ingreso**: (a) una cuenta con los roles `user` y `pastor` y sin club resuelve a `panel_only`, porque la regla del pastor exige que todos sus roles globales sean `pastor`; (b) una cuenta `panel_only` sin dependientes no puede dar de alta a su primer dependiente desde la app (solo un tutor existente conserva «Mi familia»); (c) las cuentas creadas desde el panel antes de este cambio que nunca verificaron el correo aparecen con `invitation_pending: true` y se pueden reinvitar.
- **Banderas de revision pendientes de formalizar**: menor sin tutor legal, nombre + fecha de nacimiento identicos a otro usuario, y nombres ofensivos.

## Prioridad y siguiente accion

- **Prioridad**: Alta para alinear UI/docs/backend con el modelo de revision por excepcion y membresia activa como gate operativo
- **Siguiente accion**: formalizar banderas de revision por excepcion y verificar end-to-end el flujo de membresia pendiente con backend + app.
