# SACDIA Security Implementation Guide

**Estado**: ACTIVE

**Versión**: 1.0  
**Fecha**: 31 de enero de 2026  
**Actualizado**: 15 de julio de 2026
**Status**: ✅ Implementado

---

## RBAC sensible por sub-recurso `user`

El runtime actual endurece sub-recursos sensibles de `user` con `JwtAuthGuard` + `PermissionsGuard` + metadata `@AuthorizationResource({ type: 'user', ownerParam: 'userId' })`.

### Familias incluidas

| Familia | Rutas directas cubiertas | Permisos finos | Fallback transicional |
| --- | --- | --- | --- |
| `health` | `GET/PUT /users/:userId/allergies`, `GET/PUT /users/:userId/diseases`, `GET/PUT /users/:userId/medicines`, `DELETE` item-level | `health:read`, `health:update` | `users:read_detail`, `users:update` |
| `emergency_contacts` | `GET/POST/PATCH/DELETE /users/:userId/emergency-contacts` | `emergency_contacts:read`, `emergency_contacts:update` | `users:read_detail`, `users:update` |
| `legal_representative` | `GET/POST/PATCH/DELETE /users/:userId/legal-representative` | `legal_representative:read`, `legal_representative:update` | `users:read_detail`, `users:update` |
| `post_registration` | `GET /users/:userId/post-registration/status` | `post_registration:read` | `users:read_detail` |
| `post_registration` | `POST /users/:userId/post-registration/step-{1,2,3}/complete` | `registration:complete` | _(sin fallback)_ |
| `post_registration` | `POST /users/:userId/post-registration/membership-request/cancel` | `registration:complete` | _(sin fallback)_ |

Reglas de seguridad:

- el owner del `userId` mantiene self-service aunque no tenga permisos globales explícitos;
- para terceros, solo cuentan permisos globales;
- permisos provenientes solo de `authorization.active_assignment` no habilitan acceso transversal a recursos `user`.

### Excepción mínima de terceros en `post_registration`

- `GET /users/:userId/post-registration/status` para terceros queda limitado a estado administrativo mínimo;
- `POST /users/:userId/post-registration/step-{1,2,3}/complete` para terceros queda limitado a completion administrativa mínima;
- `POST /users/:userId/post-registration/membership-request/cancel` para terceros queda limitado a cancelación administrativa mínima;
- respuestas y errores NO deben filtrar razones sensibles detalladas del usuario objetivo.

### Exclusiones fuera de scope

Estas rutas siguen bajo metadata legacy `users:*` y no forman parte del tiering fino de este change:

- `GET/PATCH /users/:userId`;
- `POST/DELETE /users/:userId/profile-picture`;
- `GET /users/:userId/age`;
- `GET /users/:userId/requires-legal-representative`.

### Pruning administrativo

`GET /api/v1/admin/users/:userId` poda bloques sensibles por familia:

- `health`;
- `emergency_contacts`;
- `legal_representative`;
- `post_registration`.

Cada bloque se expone solo si el actor tiene `family:read` o el fallback legacy `users:read_detail`.

---

## RBAC de progreso de clases

Los endpoints de progreso/evidencias de clases combinan self-service y delegación:

- si `:userId` coincide con el usuario autenticado, las escrituras owner-aware (`PATCH progress`, `POST submit`, `POST files`, `DELETE files`) pueden pasar el guard sin exigir `classes:submit_progress`;
- si el actor trabaja sobre otro miembro, debe tener `classes:submit_progress` desde su asignación activa o permisos globales efectivos;
- en todos los casos, `ClassProgressAccessService` resuelve el enrollment anual y valida el acceso fino al progreso objetivo.

Esto evita dar `classes:submit_progress` al rol `member` de forma amplia y conserva mínimo privilegio para cargas delegadas.

## RBAC de notificaciones

El módulo `notifications` usa permisos finos y scopes explícitos:

| Superficie | Permiso | Scope efectivo | Roles seed |
| --- | --- | --- | --- |
| `POST /notifications/send` | `notifications:send` | global | `admin`, `super-admin` por wildcard |
| `POST /notifications/broadcast` | `notifications:broadcast` | global | `admin`, `super-admin` por wildcard |
| `POST /notifications/club/:instanceType/:instanceId` | `notifications:club` | `active_assignment` exacto | `secretary`, `secretary-treasurer`, `deputy-director`, `director`; `admin`/`super-admin` por wildcard pero sin bypass del target activo |
| `GET /notifications/targets/club` | `notifications:club` | `active_assignment` exacto | mismos roles de envío por club |
| `GET /notifications/history` | JWT | inbox propia o auditoría admin filtrada por servicio | sin permiso de envío requerido |

El envío por club falla cerrado: además del scope exacto, el backend valida que el `instanceType` de la URL coincida con el tipo real de la sección (`NOTIF_TARGET_TYPE_MISMATCH` en mismatch).

---

## RBAC de reportes institucionales

Los listados administrativos de reportes resuelven el contexto con `AuthorizationContextService` y aplican scope jerárquico en el servidor; los filtros del cliente nunca amplían el alcance real del actor.

| Actor | Alcance efectivo |
| --- | --- |
| `super-admin`, `admin`, `director-dia`, `assistant-dia` | Todos los reportes; pueden filtrar por `division_id`, `union_id`, `local_field_id` |
| `director-union`, `assistant-union` | Solo clubes/campos de su unión; pueden reducir por `local_field_id` |
| `director-lf`, `assistant-lf`, `coordinator`, `assistant-admin` | Solo clubes de su campo local |
| Director/secretario con asignación activa de club | Solo reportes de su sección activa |

La regla se centraliza en `src/reports/report-visibility-scope.ts` y se aplica a listados mensuales, trimestrales y anuales.

---

## RBAC y scope del dashboard operativo

`GET /api/v1/admin/analytics/operations-dashboard` usa `JwtAuthGuard` y `GlobalRolesGuard`, pero el guard de rol solo habilita la superficie. `OperationsDashboardScopeService` vuelve a resolver el perfil de autorización y fuerza el alcance territorial antes de consultar métricas.

### Matriz de alcance máximo

| Actor | Alcance máximo efectivo | Reducción permitida |
| --- | --- | --- |
| `super-admin` | Global (`all`) | División, Unión o Campo local válidos |
| `admin`, `assistant-admin` | Scope configurado; Unión tiene precedencia, luego Campo local y finalmente División | Solo el territorio configurado y sus descendientes |
| `director-dia`, `assistant-dia` | Su División efectiva | Unión o Campo local descendiente |
| `director-union`, `assistant-union` | Su Unión efectiva | Campo local descendiente |
| `director-lf`, `assistant-lf` | Su Campo local efectivo | No puede ampliar; permanece en ese Campo local |

El controller declara `admin`, `super-admin` y los seis roles territoriales. `assistant-admin` entra por el alias simétrico `admin ↔ assistant-admin` de `GlobalRolesGuard`; no obtiene alcance global por ese alias. Coordinadores, pastores y actores con roles solo de club no están admitidos.

### Reglas de filtros territoriales

- `division_id`, `union_id` y `local_field_id` son filtros de reducción, nunca autoridad.
- Cuando se envían varios niveles, deben representar una misma cadena territorial.
- El backend carga la geografía objetivo, valida que esté contenida en el scope base del actor y después valida la consistencia de la cadena solicitada.
- Un actor scoped no puede convertir su scope en global omitiendo filtros.
- Un rol que requiere territorio y no tiene un ID efectivo numérico recibe `403 ADMIN_USER_SCOPE_MISSING`.

### Respuestas que evitan enumeración territorial

| Situación | Respuesta |
| --- | --- |
| Destino existente fuera del scope de un actor territorial | `403 GUARD_PERMISSION_DENIED` |
| ID geográfico inexistente solicitado por un actor territorial | El mismo `403 GUARD_PERMISSION_DENIED` |
| Cadena internamente inconsistente dentro de un scope consultable | `400 ANALYTICS_SCOPE_CHAIN_INVALID` |
| División, Unión o Campo local inexistente consultado por `super-admin` global | `404 ADMIN_DIVISION_NOT_FOUND`, `ADMIN_UNION_NOT_FOUND` o `ADMIN_LOCAL_FIELD_NOT_FOUND` |

El `404` geográfico se reserva al actor global. Para actores con scope, existencia y no pertenencia producen el mismo `403`; así la respuesta no revela territorios ajenos. La comprobación de contención precede al error de cadena, por lo que una combinación que apunta fuera del scope también responde `403`.

---

## 📋 Resumen de Características de Seguridad

### Fase 1-3: Seguridad Básica

| Característica   | Archivo                    | Descripción                                     |
| ---------------- | -------------------------- | ----------------------------------------------- |
| Helmet           | `main.ts`                  | Security headers (CSP, HSTS, X-Frame-Options)   |
| Rate Limiting    | `app.module.ts`            | 3 tiers: 3/seg, 20/10seg, 100/min               |
| Compression      | `main.ts`                  | gzip para responses                             |
| CORS             | `main.ts`                  | Whitelist configurable                          |
| XSS Sanitization | `sanitize.pipe.ts`         | Remueve HTML de inputs                          |
| Audit Logging    | `audit.interceptor.ts`     | Log de todas las requests                       |
| Error Handling   | `http-exception.filter.ts` | Oculta detalles en producción                   |
| Password Policy  | `register.dto.ts`          | Requiere mayúscula, minúscula, número, especial |

### Fase 4: Seguridad Avanzada

| Característica  | Archivo                         | Descripción                                |
| --------------- | ------------------------------- | ------------------------------------------ |
| 2FA (TOTP)      | `mfa.service.ts`                | TOTP propio sobre Better Auth + tabla `verifications` |
| Token Blacklist | `token-blacklist.service.ts`    | Revocación de JWT SACDIA                   |
| Session Limits  | Better Auth `sessions`          | Máximo de sesiones gestionado por BA/runtime |
| IP Whitelist    | `ip-whitelist.guard.ts`         | Restricción de acceso admin por IP         |

---

## 🔐 Endpoints de Seguridad

### 2FA (MFA) Endpoints

```typescript
// Iniciar enrolamiento - genera URI TOTP + backup codes
POST /v1/auth/mfa/enroll
// Body: { password: string }
// Response: { totpURI, backupCodes }

// Verificar código TOTP durante login MFA
POST /v1/auth/mfa/verify
// Auth: JWT aal1 permitido por @SkipMfaCheck()
// Body: { code: string }
// Response: { verified: boolean, accessToken?: string }

// Verificar estado de 2FA
GET /v1/auth/mfa/status
// Response: { enabled: boolean }

// Deshabilitar 2FA
DELETE /v1/auth/mfa/disable
// Body: { password: string }
```

### Modelo vigente: Better Auth + JWT SACDIA + TOTP assurance

- Better Auth mantiene sesiones opacas en `sessions`; SACDIA firma JWT HS256 propios con `BETTER_AUTH_SECRET`.
- Login con usuario que tiene TOTP activo emite JWT `aal1` con `mfa_pending: true`.
- `JwtAuthGuard` es el perímetro real: rechaza `mfa_pending: true` en rutas protegidas salvo `@SkipMfaCheck()`.
- `POST /auth/mfa/verify` puede ejecutarse con `aal1`; si el código es válido, emite JWT `aal2` y, cuando el JWT tiene `sid`, guarda assurance en `verifications` como `mfa-session:{sessionId}` hasta `sessions.expires_at`.
- `POST /auth/refresh` revisa esa assurance para usuarios con TOTP: si existe y no expiró, emite `aal2`; si falta, vuelve a emitir `aal1` con `mfa_pending: true`.
- `POST /auth/update-password` requiere `{ currentPassword, password }`, JWT `aal2` para usuarios MFA, revoca todas las sesiones BA del usuario y blacklistea JWTs por 8h.

### Sesión administrativa nativa (implementación privada en rama)

La rama backend `codex/sacdia-admin-ios-auth`, hasta `ee84d2d`, implementa servicios privados para una sesión administrativa stateful sobre Better Auth:

- `validateCredentials` comprueba email y contraseña sin crear sesión ni JWT y conserva una comparación bcrypt también en caminos inválidos para reducir diferencias de timing.
- `AdminEligibilityService` consulta `users` de forma fresca y solo admite `active === true && access_panel === true`; cualquier otro estado se deniega con `AUTH_PANEL_ACCESS_DENIED`.
- Ese gate solo habilita la superficie: no concede roles ni grants. Cada operación administrativa sigue resolviendo RBAC y scope en backend.
- `AdminSessionService` crea metadata 1:1 en `admin_auth_sessions` y emite un JWT HS256 de acceso por 15 minutos con `iss='https://api.sacdia.app'`, `aud='sacdia-admin-api'`, `surface='admin'`, `client_type='ios'`, `sid`, `jti`, `sub`, `aal`, `amr` y `mfa_pending=false`. No incluye email. `aal1` exige exactamente `amr=['pwd']`; `aal2`, `amr=['pwd','otp']`. `iat`, `exp` y `accessTokenExpiresAt` derivan del mismo segundo epoch. La sesión interna dura 7 días y tiene una expiración absoluta de 30 días.
- Cada request admin valida en base de datos el vínculo entre sesión y sujeto/usuario, además de assurance, revocación y expiraciones. No hace join de `active`/`access_panel` por request: esos cambios requieren revocar las sesiones desde la mutación administrativa, integración pendiente de A5. La revocación de una sesión o de todas las sesiones del usuario es inmediata; este JWT NO es stateless.
- `JwtStrategy` mantiene intacta la compatibilidad con JWT legacy cuando `surface` está ausente. Cuando está presente, valida manualmente y solo acepta `surface='admin'` con el contrato completo; reutiliza el parser Bearer de Passport tanto para autenticación como para blacklist y falla cerrado con HTTP 503 (`AUTH_SESSION_AUTHORITY_UNAVAILABLE`) si la autoridad de sesión no está disponible, en vez de convertir la caída en credenciales válidas o en un 401 ambiguo.
- `AdminMfaChallengeService` emite un JWT pre-auth HS256 por 5 minutos con `iss='https://api.sacdia.app'`, `aud='sacdia-admin-mfa'`, `surface='admin'`, `client_type='ios'`, `purpose='mfa'`, `mfa_pending=true`, `aal='aal1'` y `amr=['pwd']`. En `admin_mfa_challenges` se persiste únicamente el SHA-256 del token; el token crudo solo se entrega al llamador privado.
- `AdminMfaCompletionService` finaliza el challenge dentro de la misma transacción que la elegibilidad, el replay TOTP y la creación de sesión AAL2; los outcomes se mapean a códigos canónicos internos sin exponer tokens pre-auth en logs ni excepciones.
- Los servicios y repositorios de eligibility, sesión y challenge MFA, incluido `AdminMfaCompletionService`, están registrados como providers internos de `AuthModule`: no se exportan ni están conectados a un controller.

### Persistencia de refresh administrativo nativo (D1 implementado en rama)

Desde `c09a600` hasta `ee84d2d`, inclusive, la rama contiene únicamente el schema Prisma, la migración SQL y sus pruebas estáticas para soportar la futura rotación. No contiene writer, servicio de refresh, cifrado en ejecución ni emisión de refresh:

- El schema reserva un único digest SHA-256 hexadecimal vigente por `session_id + family_id`, historial hash-only y una estructura de recibos con `key_id`, `nonce` de 12 bytes, `ciphertext`, `auth_tag` de 16 bytes, `plaintext_version=1` y TTL exacto de 60 segundos.
- La migración agrega `idle_expires_at`, acotado por `absolute_expires_at`, y marca la sesión Better Auth asociada con el sentinel `admin-disabled:<session_id>` después de comprobar colisiones.
- El contrato futuro D1c emitirá refresh opacos aleatorios de 256 bits solo para sesiones AAL2 posteriores al challenge MFA; persistirá únicamente hashes, incrementará `generation`, conservará historial hasta la expiración absoluta, aceptará `Idempotency-Key` UUID y cifrará recibos con AES-256-GCM usando un keyring separado.
- El contrato futuro de reuse detection revocará la familia y el `sid` vinculados cuando reaparezca un refresh histórico. Ninguna de esas acciones de rotación o revocación está implementada en runtime todavía.
- Antes de aplicar la migración o publicar la fachada, D2 debe excluir las sesiones y tokens administrativos de los endpoints legacy de Better Auth y nunca aceptar credenciales legacy en el flujo admin. El sentinel por sí solo no es un control suficiente.

> [!IMPORTANT]
> No existe endpoint `/api/v1/auth/admin/*`, la migración no está desplegada ni verificada y ningún controller nuevo está publicado. La finalización MFA existe como servicio privado; para refresh solo existe la persistencia D1, no writer ni rotación runtime. El contrato legacy y la referencia de endpoints vigente no se modifican.

Mientras esa fachada siga sin publicarse, `sacdia-admin-ios` consume el contrato común vigente (`/auth/login`, `/auth/mfa/verify`, `/auth/me`, `/auth/refresh`, `/auth/logout` y `/auth/password/reset-request`), igual que los clientes existentes. Esto no publica ni activa los servicios privados descritos arriba.

### Sessions Endpoints

```typescript
// Listar sesiones activas
GET /v1/auth/sessions
// Response: { activeSessions, maxSessions, sessions }

// Cerrar sesión específica
DELETE /v1/auth/sessions/:sessionId

// Cerrar todas las sesiones (logout de todos los dispositivos)
DELETE /v1/auth/sessions
```

---

## 📝 Ejemplos de Uso

### Token Blacklist Service

```typescript
import { TokenBlacklistService } from "./common/services/token-blacklist.service";

// Revocar token individual
await tokenBlacklistService.blacklistToken(token, expiresInSeconds);

// Revocar todos los tokens de un usuario
await tokenBlacklistService.blacklistAllUserTokens(userId);

// Verificar si token está revocado
const isRevoked = await tokenBlacklistService.isBlacklisted(token);

// Verificar si usuario tiene tokens bloqueados
const isUserBlocked = await tokenBlacklistService.isUserBlacklisted(
  userId,
  tokenIssuedAt,
);
```

### Session Management Service

```typescript
import { SessionManagementService } from "./common/services/session-management.service";

// Crear nueva sesión (elimina la más antigua si excede límite)
const result = await sessionService.createSession(
  userId,
  sessionId,
  deviceInfo,
  ipAddress,
);
// Si removedSession está presente, se eliminó una sesión antigua

// Obtener todas las sesiones activas
const sessions = await sessionService.getUserSessions(userId);

// Actualizar última actividad
await sessionService.updateSessionActivity(userId, sessionId);

// Verificar si sesión es válida
const isValid = await sessionService.isValidSession(userId, sessionId);

// Cerrar sesión específica
await sessionService.removeSession(userId, sessionId);

// Cerrar todas las sesiones (logout de todos los dispositivos)
const count = await sessionService.removeAllSessions(userId);

// Obtener estadísticas de sesiones
const stats = await sessionService.getSessionStats(userId);
// { activeSessions: 3, maxSessions: 5, sessions: [...] }
```

### MFA Service

```typescript
import { MfaService } from "./common/services/mfa.service";

// Iniciar enrolamiento de 2FA
const enrollment = await mfaService.enrollMfa(userId, currentPassword);
// { totpURI, backupCodes }

// Verificar código durante login MFA.
// Si sessionId existe, se persiste assurance server-side para refresh.
const verified = await mfaService.verifyMfa(userId, email, code, sessionId);
// { verified: true, accessToken } | { verified: false }

// Verificar si usuario tiene MFA habilitado
const status = await mfaService.getMfaStatus(userId);
// { enabled: boolean }

// Deshabilitar 2FA
await mfaService.disableMfa(userId, currentPassword);
```

### IP Whitelist Guard

```typescript
import { AdminOnly } from "./common/guards/ip-whitelist.guard";

// En controlador
@Controller("admin")
export class AdminController {
  @AdminOnly() // Solo IPs en whitelist
  @Get("sensitive-data")
  async getSensitiveData() {
    // Solo accesible desde IPs permitidas
  }
}
```

---

## 🔧 Configuración de Variables de Entorno

```env
# ===========================================
# SEGURIDAD - Fase 1-3
# ===========================================
NODE_ENV=production
ALLOWED_ORIGINS=https://sacdia.app,https://admin.sacdia.app

# ===========================================
# SEGURIDAD - Fase 4
# ===========================================
# IP Whitelist para endpoints admin (soporta CIDR)
ADMIN_ALLOWED_IPS=192.168.1.100,10.0.0.0/24,203.0.113.50

# Redis (para cache distribuido - opcional)
REDIS_URL=redis://localhost:6379
```

---

## 📦 Dependencias de Seguridad

```json
{
  "dependencies": {
    "@nestjs/throttler": "^6.5.0",
    "@nestjs/cache-manager": "^3.1.0",
    "helmet": "^8.1.0",
    "compression": "^1.8.1",
    "sanitize-html": "^2.17.0",
    "cache-manager": "^7.2.8",
    "redis": "^5.10.0"
  },
  "devDependencies": {
    "@types/sanitize-html": "^2.16.0"
  }
}
```

---

## 📂 Estructura de Archivos de Seguridad

```
src/
├── common/
│   ├── guards/
│   │   └── ip-whitelist.guard.ts       # IP whitelist para admin
│   ├── interceptors/
│   │   └── audit.interceptor.ts        # Logging de requests
│   ├── filters/
│   │   ├── http-exception.filter.ts    # Errores HTTP seguros
│   │   └── all-exceptions.filter.ts    # Catch-all
│   ├── pipes/
│   │   └── sanitize.pipe.ts            # XSS sanitization
│   └── services/
│       ├── token-blacklist.service.ts  # Revocación de tokens
│       ├── token-blacklist.service.ts  # Revocación user-wide de JWTs
│       └── mfa.service.ts              # TOTP + assurance por sesión BA
├── auth/
│   ├── mfa.controller.ts               # Endpoints de 2FA
│   ├── sessions.controller.ts          # Endpoints de sesiones
│   └── dto/
│       └── mfa.dto.ts                  # DTOs de MFA
└── main.ts                             # Helmet, Compression, CORS
```

---

**Generado**: 31 de enero de 2026

## RBAC de inscripción de secciones en camporee

- `GET /api/v1/camporees/:camporeeId/section-registration` exige `camporees:read` y resuelve la sección desde el assignment activo. Los roles de lectura pueden consultar, pero no por eso mutar.
- `POST /api/v1/camporees/:camporeeId/section-registration` exige `camporees:register_active_section`; el seed/migración elimina grants accidentales y lo concede únicamente al rol `director` de categoría `CLUB`. El servicio vuelve a exigir que el assignment activo sea exactamente ese rol.
- `POST /api/v1/camporees/:camporeeId/clubs` es el flujo legacy local territorial y exige `camporees:register`. Sólo son válidos `assistant-lf`, `director-lf`, `assistant-union` y `director-union`, todos `GLOBAL`, dentro del campo local o unión padre del camporee.
- `camporees:register` se normaliza después de herencias/wildcards: director CLUB, roles de división, `admin` y `super-admin` quedan fuera. Tener `attendance:manage` tampoco autoriza ese endpoint legacy local.
- `POST /api/v1/camporees/union/:camporeeId/clubs` conserva el contrato legacy de unión con `attendance:manage`; no hereda `camporees:register` del endpoint local.
- En el legacy, el body sólo aporta `club_section_id`; camporee, sección, club y tipo se bloquean y releen desde DB. El backend valida activo, territorio y tipo incluido antes de persistir IDs derivados.
- El alta de participantes exige director y sección activa; además verifica inscripción de sección `registered|approved` y pertenencia del participante. Los fallos de elegibilidad usan `422 CAMPOREE_SECTION_REGISTRATION_REQUIRED` o `422 CAMPOREE_MEMBER_OUTSIDE_ACTIVE_SECTION`.

## Alcance y lifecycle de categorías Materials (W1-W2)

Las lecturas de catálogo que enumeran productos/categorías y `GET|POST /api/v1/materials/categories` resuelven primero un alcance de Campo Local desde el snapshot de autorización; `local_field_id` de query es una reducción/verificación, nunca autoridad.

| Actor | Alcance para esos endpoints |
| --- | --- |
| `super-admin` | Todos los Campos, pero debe enviar `local_field_id` en listados y creación para seleccionar uno de forma explícita. |
| `admin`, `director-lf`, `assistant-lf` | Exactamente el Campo Local efectivo; otro `local_field_id` devuelve 403. |
| Rol sin autoridad global de Campo Local | Sólo el Campo Local del club de su asignación activa; si no existe, falla cerrado. |

- Los roles con autoridad de Campo Local pero sin un Campo Local efectivo fallan con `403 local_field_scope_required`; no pueden degradarse al fallback de club.
- La categoría y el producto quedan ligados al mismo Campo por constraints de base de datos, no por el valor enviado por cliente.
- `PATCH|DELETE /materials/categories/:id` resuelven primero la categoría por UUID y autorizan contra el `local_field_id` persistido; el cliente no envía ni sustituye ese ownership.
- Para actores con alcance único, la actualización atómica exige que el UUID siga perteneciendo al mismo Campo y que la categoría continúe activa. Si el recurso cambia concurrentemente, se relee y se devuelve el error de alcance/lifecycle correspondiente o `409 category_concurrent_change`.
- Para un actor con alcance único, una categoría inactiva queda sólo para consulta: reactivarla devuelve `403 material_reactivation_requires_super_admin` y cualquier otra edición devuelve `409 category_inactive`. `super-admin` puede editarla o reactivarla.
- La desactivación no borra la identidad: `DELETE` conserva el UUID, es idempotente cuando ya está inactiva y se bloquea con `409 category_in_use` si existen productos asociados. `PATCH active=false` también se bloquea mientras existan productos activos.
- Esta cobertura no declara auditoría de Materials, administración de pedidos ni cambios de Inventory o seguros; esos flujos permanecen fuera de alcance.

# Captura oficial de puntaje de camporee

- `POST /api/v1/camporee-events/:eventId/sections/:clubSectionId/scores` autoriza `judge_primary` sólo por asignación exacta. La carga manual se limita a `assistant-lf`, `director-lf`, `assistant-union` y `director-union` dentro de scope; `admin_override` se reserva a `admin`, `assistant-admin` y `super-admin`. `camporee_events:update` no es autorización suficiente y `dto.source` nunca es autoridad.
- Cuando existe `Idempotency-Key`, el backend toma primero `pg_advisory_xact_lock(bigint)` sobre `hashtextextended(prefijo estable + actor + clave, 0)` y después `pg_advisory_xact_lock(eventId::integer, clubSectionId::integer)`. Los casts son explícitos porque Prisma enlaza números JavaScript como `INT8`; así PostgreSQL selecciona el overload `(integer, integer)`. Los overloads separan keyspaces y el orden reduce riesgo de deadlock; el hash de 64 bits mantiene una colisión teórica que sólo puede sobre-serializar requests.
- Un replay de misma clave/hash no muta. La defensa P2002 relee la fila tras rollback y devuelve replay o `409 IDEMPOTENCY_KEY_REUSED`, nunca expone el error de unicidad como 500. Un receipt persistido sin resultado asociado falla de forma controlada con `CAMPOREE_SCORING_RECEIPT_INCOMPLETE`.
- Todo override de un resultado activo exige `expected_active_result_id` coincidente y motivo `notes.trim()` no vacío. El motivo queda auditado en la submission; el primer score manual sin resultado activo no lo requiere.
