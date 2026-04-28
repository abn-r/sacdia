# Runtime: Auth

## Estado
ACTIVE
<!-- VERIFICADO contra código 2026-04-13: runtime auth alineado con Better Auth, verify-email, OAuth callback POST y MFA aal1/aal2 -->

## Propósito
Este documento define el comportamiento técnico vigente del dominio de autenticación y autorización.

Acá manda el runtime real del backend, no los walkthroughs viejos ni suposiciones de cliente.

## Precedencia
Orden de autoridad para auth dentro de la capa canónica activa:

1. `docs/canon/source-of-truth.md`
2. `docs/canon/runtime-sacdia.md`
3. `docs/canon/auth/modelo-autorizacion.md`
4. `docs/canon/auth/runtime-auth.md`

Si una fuente subordinada contradice una superior, gana la superior y el conflicto debe escalarse.

## Resumen operativo
El estado actual del runtime de auth es este:

- la autenticación base depende de Better Auth self-hosted;
- el backend expone endpoints propios bajo `/api/v1/auth/*`;
- `POST /auth/login` y `POST /auth/refresh` entregan tokens en camelCase;
- `GET /auth/me` es la fuente canónica del bloque `authorization`;
- el contexto activo de club se cambia con `PATCH /auth/me/context`;
- existen superficies activas para OAuth, MFA y gestión de sesiones;
- `refreshToken` representa el session token opaco de Better Auth y el backend firma el `accessToken` HS256.

## Componentes runtime

### Better Auth
Responsabilidades actuales:
- autenticar credenciales con email y password;
- crear y refrescar sesiones opacas;
- soportar OAuth con Google y Apple a través de su callback interno;
- servir de base para el flujo MFA/TOTP integrado por backend.

### Backend NestJS
Responsabilidades actuales:
- exponer endpoints canónicos de auth para clientes;
- emitir y validar el JWT HS256 de SACDIA para API;
- resolver perfil autenticado;
- resolver autorización efectiva por sesión;
- persistir y cambiar asignación activa de club;
- ofrecer superficies auxiliares de verify-email, MFA, OAuth y sesiones.

### Prisma / Postgres
Responsabilidades actuales:
- persistir usuario local en `users`;
- persistir tracking de post-registro y `active_club_assignment_id` en `users_pr`;
- persistir verificaciones y secretos TOTP en `verification`;
- persistir sesiones opacas de Better Auth en `session`/`sessions` según runtime efectivo;
- persistir roles, permisos y asignaciones de club;
- persistir cuentas conectadas OAuth en `account`.

### Cache / Redis
Responsabilidades actuales:
- blacklist de tokens;
- gestión operativa de sesiones concurrentes;
- TTL de sesiones administradas por backend.

## Endpoints canónicos vigentes
<!-- VERIFICADO contra código 2026-04-13: auth.controller.ts, oauth.controller.ts, mfa.controller.ts, auth.service.ts y better-auth.service.ts -->

### Sesión base
- `POST /api/v1/auth/register` <!-- VERIFICADO -->
- `POST /api/v1/auth/login` <!-- VERIFICADO -->
- `POST /api/v1/auth/refresh` <!-- VERIFICADO -->
- `POST /api/v1/auth/logout` <!-- VERIFICADO -->
- `POST /api/v1/auth/password/reset-request` <!-- VERIFICADO -->
- `POST /api/v1/auth/verify-email/send` <!-- VERIFICADO -->
- `POST /api/v1/auth/verify-email/confirm` <!-- VERIFICADO -->
- `POST /api/v1/auth/update-password` <!-- VERIFICADO -->
- `GET /api/v1/auth/me` <!-- VERIFICADO -->
- `PATCH /api/v1/auth/me/context` <!-- VERIFICADO -->
- `GET /api/v1/auth/profile/completion-status` <!-- VERIFICADO -->

### OAuth
- `POST /api/v1/auth/oauth/google` <!-- VERIFICADO -->
- `POST /api/v1/auth/oauth/apple` <!-- VERIFICADO -->
- `POST /api/v1/auth/oauth/callback` <!-- VERIFICADO -->
- `GET /api/v1/auth/oauth/providers` <!-- VERIFICADO -->
- `DELETE /api/v1/auth/oauth/:provider` <!-- VERIFICADO -->

### MFA
- `POST /api/v1/auth/mfa/enroll` <!-- VERIFICADO -->
- `POST /api/v1/auth/mfa/verify` <!-- VERIFICADO -->
- `GET /api/v1/auth/mfa/status` <!-- VERIFICADO -->
- `DELETE /api/v1/auth/mfa/disable` <!-- VERIFICADO -->

### Gestión de sesiones
- `GET /api/v1/auth/sessions` <!-- VERIFICADO -->
- `DELETE /api/v1/auth/sessions/:sessionId` <!-- VERIFICADO -->
- `DELETE /api/v1/auth/sessions` <!-- VERIFICADO -->

## Contratos vigentes de tokens

### Login
`POST /api/v1/auth/login` responde hoy:

```json
{
  "status": "success",
  "data": {
    "accessToken": "...",
    "refreshToken": "...",
    "expiresAt": 1900000000,
    "tokenType": "bearer",
    "user": {
      "id": "uuid",
      "email": "user@sacdia.app",
      "name": "Juan",
      "paternal_last_name": "Perez",
      "maternal_last_name": "Lopez",
      "avatar": null,
      "roles": ["user"]
    },
    "needsPostRegistration": false,
    "postRegistrationStatus": null
  }
}
```

Reglas vigentes:
- el login autentica y entrega tokens;
- el login NO entrega el bloque canónico `authorization`;
- después del login, el cliente debe llamar `GET /auth/me` para obtener autorización efectiva y contexto activo.

### Refresh
`POST /api/v1/auth/refresh` recibe como contrato vigente:

```json
{
  "refreshToken": "v1.abc..."
}
```

Y responde:

```json
{
  "status": "success",
  "data": {
    "accessToken": "...",
    "refreshToken": "...",
    "expiresAt": 1900000000,
    "tokenType": "bearer"
  }
}
```

Compatibilidad transicional:
- `refresh_token` existió como input legacy;
- hoy el contrato canónico es `refreshToken`;
- el backend ya contempla rechazo estricto del payload snake_case;
- el valor transportado es el session token opaco de Better Auth, no un refresh JWT separado.

### Logout
`POST /api/v1/auth/logout` es best effort:
- acepta bearer opcional;
- acepta `refreshToken` opcional en body;
- si recibe `refreshToken`, intenta revocar la sesión opaca en Better Auth;
- si solo recibe `accessToken`, invalida el JWT en blacklist y deja expirar la sesión opaca por su ciclo natural;
- no bloquea UX si la revocación falla.

## Contrato canónico de autorización
La fuente oficial para autorización resuelta por sesión es `GET /api/v1/auth/me`.

Campos canónicos relevantes:
- `authorization.grants.global_roles`
- `authorization.grants.club_assignments`
- `authorization.active_assignment`
- `authorization.effective.permissions`
- `authorization.effective.scope`

Reglas vigentes:
- backend resuelve autorización;
- clientes consumen autorización resuelta;
- `authorization.effective.permissions` es la fuente operativa para gating de UX;
- permisos de club salen solo de la asignación activa;
- los campos legacy `roles`, `permissions`, `club` y `club_context` siguen expuestos solo por compatibilidad temporal.

## Contexto activo de club
El cambio de contexto activo ocurre únicamente por:

`PATCH /api/v1/auth/me/context`

Payload vigente:

```json
{
  "assignment_id": "uuid"
}
```

Semántica vigente:
- la asignación debe pertenecer al usuario;
- la asignación debe estar `active = true` y `status = active`;
- el backend persiste `active_club_assignment_id` en `users_pr`;
- la respuesta devuelve `authorization` recalculado;
- los clientes no deben inventar contexto activo localmente.

## OAuth vigente
Estado actual soportado:
- Google;
- Apple.

Flujo vigente resumido:
1. cliente llama `POST /auth/oauth/{provider}`;
2. backend devuelve una URL de Better Auth para redirigir el browser;
3. proveedor autentica al usuario;
4. Better Auth resuelve internamente `GET /api/auth/callback/{provider}` y crea/actualiza sesión;
5. cliente llama `POST /auth/oauth/callback` con `session_token`, `provider` y opcionalmente `redirect_uri`;
6. backend valida esa sesión opaca, provisiona filas SACDIA faltantes si aplica y firma el JWT HS256;
7. backend responde con `accessToken`, `sessionToken`, `user` y `needsPostRegistration`.

Notas vigentes:
- el callback público de SACDIA es `POST`, no `GET`;
- la fuente de verdad de providers conectados es la tabla `account` de Better Auth;
- `GET /auth/oauth/providers` retorna `string[]` y `DELETE /auth/oauth/:provider` desvincula la cuenta realmente.

## MFA vigente
Estado actual soportado:
- MFA con TOTP sobre JWT propio de SACDIA.

Superficies vigentes:
- enrolamiento de factor;
- verificación con elevación de sesión;
- consulta de estado;
- deshabilitación.

Notas vigentes:
- los endpoints MFA requieren JWT;
- `POST /auth/mfa/verify` admite token `aal1` (`mfa_pending: true`) y devuelve un nuevo `accessToken` `aal2` cuando verifica el código;
- `GET /auth/mfa/status` puede consultarse con token `aal1`;
- la superficie MFA pública vigente se limita a enrolar, verificar, consultar estado y deshabilitar.

Límite importante del estado actual:
- el endpoint de login principal no publica hoy un handshake canónico de `requiresMfa` previo a sesión elevada;
- MFA existe como superficie operativa, pero el flujo exacto de challenge en login todavía necesita definirse de forma canónica en procesos.

## Gestión operativa de sesiones
Estado actual soportado:
- listado de sesiones activas;
- cierre de una sesión específica;
- cierre de todas las sesiones;
- blacklist global por usuario;
- límite de 5 sesiones concurrentes;
- almacenamiento en cache con TTL de 24 horas.

Reglas vigentes:
- las sesiones operativas del backend viven en cache, no en Prisma;
- el servicio de blacklist invalida tokens antes de expiración natural;
- `DELETE /auth/sessions` blacklistea tokens del usuario y limpia sesiones registradas.

Límite importante del estado actual:
- existe servicio de session management, pero su integración completa con `POST /auth/login` y `POST /auth/refresh` no está cerrada como contrato canónico en esta capa;
- por eso, la gestión de sesiones debe tratarse hoy como superficie disponible, pero con integración pendiente de consolidación total en el proceso de sesión.

## Registro y post-registro
Estado actual:
- `POST /api/v1/auth/register` crea usuario vía Better Auth y completa filas SACDIA en Prisma;
- también crea tracking granular en `users_pr`;
- asigna el rol global `user`;
- dispara el flujo de verify-email para cuentas nuevas;
- `GET /api/v1/auth/profile/completion-status` expone el estado del post-registro.

El login y OAuth devuelven `needsPostRegistration` para que el cliente decida continuidad UX.

## Campos y compatibilidad legacy
Campos legacy todavía expuestos por compatibilidad:
- `roles`
- `permissions`
- `club`
- `club_context`

Regla vigente:
- pueden seguir existiendo durante migración;
- no son contrato nuevo;
- cualquier cliente nuevo o refactorizado debe consumir `authorization`.

## Seguridad runtime vigente
- JWT autentica identidad;
- `JwtAuthGuard` protege endpoints autenticados;
- `PermissionsGuard` y metadata de recurso endurecen autorización en rutas sensibles;
- frontend no actúa como barrera de seguridad;
- logout y cierre de sesiones deben asumirse como operaciones defensivas, no como única garantía;
- datos sensibles del usuario siguen reglas específicas de ownership o permiso global en recursos `user`.

## Gaps y pendientes explícitos
Estos puntos NO deben maquillarse como cerrados:

- el proceso canónico post-login debe explicitar la llamada a `GET /auth/me`;
- MFA existe, pero el handshake exacto de login con elevación a `aal2` no está consolidado como contrato canónico de proceso;
- session management existe, pero su wiring contractual completo con login/refresh todavía necesita cerrarse;
- los campos legacy siguen vivos y deben eliminarse gradualmente cuando admin y app migren por completo al bloque `authorization`.

## Regla para clientes

### `sacdia-admin`
- usa `authorization.effective.permissions` para gating de páginas, acciones y mutaciones;
- usa `authorization.grants` para matrices, detalle de roles y selector de contexto;
- no reconstruye RBAC desde joins locales.

### `sacdia-app`
- usa `authorization.effective.permissions` para acciones habilitadas;
- usa `authorization.effective.scope.club` como contexto activo;
- usa `authorization.grants.club_assignments` para selector de contexto;
- no usa metadata legacy como fuente de autorización nueva.

## Referencias activas
- `docs/canon/source-of-truth.md`
- `docs/canon/runtime-sacdia.md`
- `docs/canon/auth/modelo-autorizacion.md`
- `docs/features/auth/AUTHORIZATION-CANONICAL-CONTRACT.md`
- `docs/features/auth/PERMISSIONS-SYSTEM.md`
- `docs/features/auth/RBAC-ENFORCEMENT-MATRIX.md`
- `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- `sacdia-backend/src/auth/auth.controller.ts`
- `sacdia-backend/src/auth/auth.service.ts`
- `sacdia-backend/src/auth/oauth.controller.ts`
- `sacdia-backend/src/auth/mfa.controller.ts`
- `sacdia-backend/src/auth/sessions.controller.ts`
- `sacdia-backend/src/common/services/authorization-context.service.ts`
