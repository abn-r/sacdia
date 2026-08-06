# Contrato Canonico de Autorizacion

**Status**: ACTIVE
**Fecha**: 2026-03-10
**Ambito**: `sacdia-backend`, `sacdia-admin`, `sacdia-admin-ios`, `sacdia-app`

## Proposito

Este documento define la fuente de verdad para autorizacion en SACDIA.

La regla principal es:

- el backend resuelve autorizacion;
- los clientes consumen autorizacion resuelta;
- los campos legacy existen solo por compatibilidad temporal.

## Precedencia Documental

Para evitar contratos paralelos, la precedencia oficial es:

1. `AUTHORIZATION-CANONICAL-CONTRACT.md` (shape y semantica del payload `authorization`).
2. `RBAC-ENFORCEMENT-MATRIX.md` (como se enforcea cada permiso en backend).
3. `CLUB-ROLE-ASSIGNMENT-FIRST-CONTRACT.md` (modelo de escrituras/lecturas de asignaciones de club).

Regla explicita:

- el arreglo plano `permissions` legacy no es fuente oficial de autorizacion para clientes nuevos.

## Contrato Oficial

El contrato oficial vive en `GET /auth/me` bajo el campo `authorization`.

```ts
type AuthorizationPayload = {
  authorization: {
    grants: {
      global_roles: Array<{
        role_name: string;
        permissions: string[];
        scope: {
          country?: { id: number | string; name?: string | null };
          union?: { id: number | string; name?: string | null };
          local_field?: { id: number | string; name?: string | null };
        };
      }>;
      club_assignments: Array<{
        assignment_id: string;
        role_name: string;
        permissions: string[];
        club: { club_id: number; club_name: string };
        instance: {
          type: "adventurers" | "pathfinders" | "master_guilds";
          instance_id: number;
          instance_name?: string | null;
        };
        scope: {
          country?: { id: number | string; name?: string | null };
          union?: { id: number | string; name?: string | null };
          local_field?: { id: number | string; name?: string | null };
        };
        status: string;
        start_date?: string | null;
        end_date?: string | null;
      }>;
    };
    active_assignment: {
      assignment_id: string | null;
    };
    effective: {
      permissions: string[];
      scope: {
        global: {
          country?: { id: number | string; name?: string | null };
          union?: { id: number | string; name?: string | null };
          local_field?: { id: number | string; name?: string | null };
        };
        club: {
          assignment_id: string;
          role_name: string;
          club: { club_id: number; club_name: string };
          instance: {
            type: "adventurers" | "pathfinders" | "master_guilds";
            instance_id: number;
            instance_name?: string | null;
          };
        } | null;
      };
    };
  };
}
```

## Semantica

### `authorization.grants`

Describe lo que el usuario tiene asignado en el sistema.

- `global_roles`: inventario de roles globales con alcance territorial.
- `club_assignments`: inventario de asignaciones exactas por club e instancia.

### `authorization.active_assignment`

Describe cual asignacion de club esta activa en la sesion actual.

- Si es `null`, el usuario no tiene contexto activo de club.
- Si tiene valor, solo esa asignacion aporta permisos de club a `effective`.

### `authorization.effective`

Describe lo que el backend ya resolvio para la sesion actual.

- `effective.permissions`: permisos listos para gating en clientes.
- `effective.scope.global`: alcance territorial resuelto.
- `effective.scope.club`: contexto activo exacto de club e instancia.

## Reglas Canonicas para Recursos `user`

Cuando una ruta usa `@AuthorizationResource({ type: 'user', ownerParam: 'userId' })`, el contrato runtime vigente es:

- ownership real sobre `userId` habilita self-service estricto para el propio usuario;
- si no hay ownership, el actor necesita permiso global suficiente (`users:read_detail` para lecturas, `users:update` para escrituras);
- permisos provenientes solo de `active_assignment` no habilitan acceso transversal a recursos `user` de terceros.

Sub-recursos sensibles hoy cubiertos por familias finas:

- `health`: `GET/PUT /users/:userId/allergies`, `GET/PUT /users/:userId/diseases`, `GET/PUT /users/:userId/medicines`, `DELETE` item-level de esas tres colecciones;
- `emergency_contacts`: `GET/POST/PATCH/DELETE /users/:userId/emergency-contacts`;
- `legal_representative`: `GET/POST/PATCH/DELETE /users/:userId/legal-representative`;
- `post_registration`: `GET /users/:userId/post-registration/status` y `POST /users/:userId/post-registration/step-{1,2,3}/complete`.

Limite explicito del baseline `health` actual:

- `medicines` forma parte del runtime canonico activo como relacion sensible `user -> medicines`.
- No existe todavia vinculo runtime `medicine <-> disease` ni debe inferirse por analogia.

### Tiering RBAC sensible vigente

El runtime vigente SI distingue permisos finos por familia sensible para sub-recursos `user`:

- `health:read` / `health:update`;
- `emergency_contacts:read` / `emergency_contacts:update`;
- `legal_representative:read` / `legal_representative:update`;
- `post_registration:read` / `registration:complete`.

Regla de enforcement:

- ownership sobre `userId` mantiene self-service estricto del propio usuario;
- para terceros, solo cuentan permisos globales;
- permisos de club provenientes de `authorization.active_assignment` NO habilitan acceso a recursos `user` de terceros.

OR transicional vigente:

- lecturas finas aceptan `family:read` O el legado de la familia `users:*` para lectura (`users:read_detail`);
- escrituras finas aceptan `family:update` O el legado de la familia `users:*` para escritura (`users:update`);
- excepcion: `registration:complete` es un permiso global dedicado sin fallback legacy. Asignado a roles de campo (super_admin, admin, assistant-lf, director-lf y equivalentes union/dia por herencia). El owner siempre puede completar su propio registro sin este permiso.

Esto existe para compatibilidad transicional y NO redefine el contrato objetivo de largo plazo.

### Exclusiones explicitas fuera de scope del change

Las siguientes rutas directas del recurso `user` permanecen fuera del tiering fino y siguen en metadata legacy `users:*`:

- `GET /users/:userId`;
- `PATCH /users/:userId`;
- `POST /users/:userId/profile-picture`;
- `DELETE /users/:userId/profile-picture`;
- `GET /users/:userId/age`;
- `GET /users/:userId/requires-legal-representative`.

Regla documental:

- no inventar familias nuevas para estas rutas;
- documentarlas como exclusiones deliberadas de `rbac-sensitive-subresources`;
- cualquier tiering adicional sobre perfil base, foto o derivados requiere change posterior.

### Politica cerrada - excepcion minima de terceros en post-registro

El runtime vigente permite que un actor no owner con permiso global `registration:complete` ejecute:

- `POST /users/:userId/post-registration/step-1/complete`;
- `POST /users/:userId/post-registration/step-2/complete`;
- `POST /users/:userId/post-registration/step-3/complete`.

La decision funcional canonica queda cerrada asi:

- `GET /users/:userId/post-registration/status` permite lectura administrativa minima de terceros con `post_registration:read` o fallback legacy `users:read_detail`;
- `POST /users/:userId/post-registration/step-{1,2,3}/complete` requiere `registration:complete` (permiso global dedicado, sin fallback a `users:update`). Roles asignados: super_admin, admin, assistant-lf, director-lf y equivalentes union/dia por herencia;
- ownership mantiene feedback detallado actual y permite completar sin necesidad de `registration:complete`;
- terceros no reciben en respuestas ni errores detalles sensibles del usuario objetivo.

### Politica de cliente - excepcion minima para terceros

La politica canonica para clientes queda asi:

- `process-state` / `administrative completion` de terceros puede reflejarse cuando exista autorizacion global resuelta explicita (`post_registration:read` o `users:read_detail` para lectura; `registration:complete` para escritura);
- `GET /post-registration/status` para terceros debe limitarse al estado administrativo minimo del proceso y no necesita feedback guiado tipo `nextStep`;
- `POST /step-{1,2,3}/complete` para terceros debe usar respuestas y errores minimos, sin devolver detalles sensibles del paso 2 ni feedback detallado del usuario objetivo;
- datos sensibles enviados por el usuario (`health` = `allergies` + `diseases` + `medicines`, `emergency contacts`, `legal representative`, perfil sensible derivado del paso 2) NO deben quedar expuestos ni editables en clientes de terceros solo por `users:update` generico;
- `sacdia-admin`, `sacdia-admin-ios` y `sacdia-app` deben degradar u ocultar esas superficies cuando no exista una senal explicita compatible con esta politica minima.

## Registro Canonico de Exclusiones

Las exclusiones vigentes tras este cierre son exactamente estas:

1. perfil base y mutacion general `PATCH /users/:userId`;
2. foto de perfil (`POST/DELETE /users/:userId/profile-picture`);
3. derivados `GET /users/:userId/age` y `GET /users/:userId/requires-legal-representative`.

Regla de control de scope:

- no reetiquetar estas rutas como familias finas sin cambio backend adicional;
- no usar clientes para simular un tiering que el backend no publica.

## Validacion Transversal Final

Validacion documental final tras cierre de la excepcion minima:

- backend: las familias `health`, `emergency_contacts`, `legal_representative` y `post_registration` se enforcean con permisos finos + fallback legacy de la familia `users:*`;
- backend: el contrato `user` verificado se mantiene en ownership o permiso global; `active_assignment` no habilita acceso a terceros;
- backend: post-registro sobre terceros queda en modo administrativo minimo; owner conserva feedback detallado y terceros reciben respuestas saneadas;
- `sacdia-admin`: el consumo canonico sigue siendo `authorization.effective.permissions` y `authorization.grants`;
- `sacdia-admin-ios`: el inicio de sesion valida la elegibilidad del panel y despues consume `authorization.effective.permissions` y `authorization.grants` desde `/auth/me`;
- `sacdia-app`: el gating sensible distingue familias finas, pero conserva fallback transicional a `users:read_detail` / `users:update`;
- docs activas de auth y API quedan alineadas sobre familias finas cubiertas y exclusiones fuera de scope.

## Reglas de Consumo

### Backend

- La autorizacion se enforcea contra `authorization`.
- Los guards no deben depender de `roles`, `permissions`, `club` o `club_context` legacy para decisiones nuevas.

### `sacdia-admin`

- Debe usar `authorization.effective.permissions` para habilitar rutas, acciones y botones.
- Debe usar `authorization.grants` para matrices, detalle de roles y selectores de contexto.
- No debe reconstruir permisos desde `users_roles`, `role_permissions` ni variantes locales.

### `sacdia-app`

- Debe usar `authorization.effective.permissions` para acciones habilitadas.
- Debe usar `authorization.effective.scope.club` como contexto activo.
- Debe usar `authorization.grants.club_assignments` para selector de contexto.
- No debe leer roles de club desde `metadata.roles` ni contexto de club desde `metadata.club`.

### `sacdia-admin-ios`

- Debe usar `authorization.effective.permissions` para habilitar modulos y acciones.
- Debe conservar roles globales y asignaciones de club desde `authorization.grants` para contexto y alcance.
- Puede usar la misma lista de roles administrativos de `sacdia-admin` solo para admitir o rechazar el acceso inicial al panel; esa lista no sustituye el enforcement de permisos por operacion.
- No debe consumir la fachada privada no publicada `/auth/admin/*`.

## Campos Legacy

Los siguientes campos siguen expuestos temporalmente para compatibilidad:

- `roles`
- `permissions`
- `club`
- `club_context`

Regla:

- siguen vivos solo durante migracion;
- no son el contrato oficial;
- cualquier consumidor nuevo debe usar `authorization`.

## Ejemplo de `GET /auth/me`

```json
{
  "status": "success",
  "data": {
    "user_id": "0a111111-2222-3333-4444-555555555555",
    "email": "usuario@sacdia.app",
    "roles": ["assistant_admin"],
    "permissions": ["clubs:read", "users:read"],
    "authorization": {
      "grants": {
        "global_roles": [
          {
            "role_name": "assistant_admin",
            "permissions": ["clubs:read", "users:read"],
            "scope": {
              "union": { "id": 7, "name": "Union Norte" },
              "local_field": { "id": 14, "name": "Campo Metropolitano" }
            }
          }
        ],
        "club_assignments": [
          {
            "assignment_id": "2b111111-2222-3333-4444-555555555555",
            "role_name": "director",
            "permissions": ["clubs:update", "club_instances:update"],
            "club": { "club_id": 25, "club_name": "Club Amanecer" },
            "instance": {
              "type": "pathfinders",
              "instance_id": 9,
              "instance_name": "Conquistadores"
            },
            "scope": {
              "union": { "id": 7, "name": "Union Norte" },
              "local_field": { "id": 14, "name": "Campo Metropolitano" }
            },
            "status": "active",
            "start_date": "2026-01-01T00:00:00.000Z",
            "end_date": null
          }
        ]
      },
      "active_assignment": {
        "assignment_id": "2b111111-2222-3333-4444-555555555555"
      },
      "effective": {
        "permissions": [
          "club_instances:update",
          "clubs:read",
          "clubs:update",
          "users:read"
        ],
        "scope": {
          "global": {
            "union": { "id": 7, "name": "Union Norte" },
            "local_field": { "id": 14, "name": "Campo Metropolitano" }
          },
          "club": {
            "assignment_id": "2b111111-2222-3333-4444-555555555555",
            "role_name": "director",
            "club": { "club_id": 25, "club_name": "Club Amanecer" },
            "instance": {
              "type": "pathfinders",
              "instance_id": 9,
              "instance_name": "Conquistadores"
            }
          }
        }
      }
    }
  }
}
```

## Cambio de Contexto Activo

`PATCH /auth/me/context`

```json
{
  "assignment_id": "2b111111-2222-3333-4444-555555555555"
}
```

Respuesta esperada:

- `authorization.active_assignment`
- `authorization.effective`
- compatibilidad temporal con `club` y `active`

### QR canonico

Las credenciales QR nuevas consumen este mismo contrato de autorizacion:

- `qr:issue_self` habilita `/qr/me`, `/qr/me/card` y `/qr/me/card.pdf`;
- `qr:validate` habilita `/qr/validate`;
- `/qr/scan` permanece como alias legacy y sigue gobernado por `attendance:manage`.

## Authorization-time (tiempo de negocio)

La autorizacion efectiva de asignaciones de club se evalua contra un contexto temporal resuelto por Campo Local. Este contrato aplica al runtime AuthZ (backend PRs `#242`, `#334`, `#247`, `#336`); no introduce endpoints nuevos.

### Orden de resolucion de timezone

1. Partir del `club_section` relevante.
2. Resolver `club` → `local_field`.
3. Validar `local_fields.timezone` como IANA geografica canonica.
4. Emitir `TemporalContext`:
   - `now` (instante UTC del reloj inyectado)
   - `businessDate` (`YYYY-MM-DD` en la timezone del Campo Local)
   - `businessTimeZone` (IANA canonica)
   - `localFieldId`

Si el Campo Local falta o su timezone no es clasificable, el backend falla cerrado con:

- HTTP `503`
- `ErrorCode.LOCAL_FIELD_TIMEZONE_UNAVAILABLE`
- detalle `{ reason }` (`MISSING` u otras razones de clasificacion)

No se inventa timezone por defecto.

### Effectivity de asignaciones

`ClubAssignmentEffectivityPolicy` es la unica fuente de verdad para autoridad vigente:

| Superficie | Contrato |
| --- | --- |
| Memoria | `isEffective(assignment, context)` |
| Prisma | `toPrismaWhere(context)` |
| SQL crudo | `toSql(context, assignmentAlias)` con columnas calificadas (`alias.active`, etc.) |

Reglas de vigencia (`active`, `status='active'`, `start_date`/`end_date` por `businessDate`, `expires_at` por `now`) deben mantener paridad entre las tres superficies.

`toSql` exige un alias SQL seguro (`^[A-Za-z_][A-Za-z0-9_]*$`) para poder embebese en joins donde `active` u otras columnas son ambiguas.

Limites de dia de negocio (`startOfBusinessDate`, `startOfNextBusinessDate`) usan la timezone del contexto; los tests de politica usan `TestingClock`, que clona el instante inicial para evitar mutacion compartida del `Date`.

Intenciones no autoritativas (workflow/historico) deben declarar `grantsAuthority: false` via `CLUB_ASSIGNMENT_NON_AUTHORITY_ALLOWLIST`.

### Consumidores T08 (migración por inventario)

El inventario endurecido (`club-assignment-effectivity.inventory`) clasifica predicados `club_role_assignments` como `T08` (autoridad efectiva), `T09` (scope/workflow) o `allowlist` (no autoridad).

Runtime R07 migra el **path canónico de autoridad** en `AuthorizationContextService`. Runtime R07b migra el **resource-scope de investidura** en `ClubRolesGuard`:

| Aspecto | Contrato R07 / R07b |
| --- | --- |
| Inventario Prisma | `where: { active: true }` sigue precargando candidatos; **no** es la puerta temporal de autoridad. |
| Autoridad efectiva | `ClubAssignmentEffectivityPolicy.isEffective` con `TemporalContext` del Campo Local de cada asignación. |
| `/auth/me` / cache miss | `effective.permissions` y `active_assignment` solo consideran asignaciones vigentes en la timezone del recurso. |
| `ClubRolesGuard` (R07b) | Resolución de club vía enrollment de investidura solo acepta asignaciones temporalmente vigentes; fail-closed sin timezone IANA clasificable. |
| Fail-closed | Asignación `status='active'` sin timezone IANA clasificable → `LOCAL_FIELD_TIMEZONE_UNAVAILABLE` (503). |
| Fuera de este slice | `PermissionsGuard`, `clubs`/`rbac`/`auth` y demás entradas T08 del inventario (sub-slices dependientes ≤400). |

## Authorization context versioning (cache v4 read path)

Backend stack `#254`–`#271` (+ remediaciones `#342`/`#344`) introduce versionado durable de contexto de autorización. Runtime R05 cablea el **read-path** en `AuthorizationContextService.resolveUserAuthorization` vía `resolveAuthorizationContextV4`. Runtime R06 añade **controles de rollout** (feature flag + métricas/logs sin PII + rollback operativo). **No hay endpoint HTTP dedicado de cache**; los clientes siguen usando `/auth/me` y guards existentes.

### Semántica

- Tabla durable `authorization_context_versions` (por `user_id`).
- Lecturas resuelven clave `auth:context:v4:{userId}:{version}` con envelope (`value`, `valid_until`, `territory_time_vector`).
- Hit fresco (envelope válido) omite la fuente canónica; miss/expirado/corrupto vuelve a la fuente canónica y reescribe el envelope.
- Fallo de Redis en get/set **no** concede autoridad desde cache: se continúa con la fuente canónica (o se deniega si esa fuente falla).
- Mutaciones que cambian autoridad efectiva hacen bump **dentro de la misma transacción** que la escritura de negocio.
- Tras commit exitoso se invalida cache Redis del usuario (v4 actual + claves legacy v3/v2); si el bump falla, la mutación hace rollback y no se limpia cache.
- Escrituras no-op / rechazadas **no** incrementan versión.

### Rollout, observabilidad y rollback (R06)

| Control | Contrato |
| --- | --- |
| Flag `AUTH_CONTEXT_CACHE_V4_ENABLED` | Default `true` (preserva read-path R05). Valor `false` omite Redis (sin get/set) y carga solo la fuente canónica — rollback operativo sin cambiar la semántica de permisos. |
| Métricas in-process | Contadores `hits` / `misses` / `errors` / `bypassed` vía `getAuthorizationCacheMetrics()`; sin userId, email ni otros PII. |
| Logs seguros | Eventos `auth_context_cache outcome=hit\|miss\|error\|bypass` sin identificadores de usuario. |
| Efecto del rollback | Con flag apagado, las decisiones de autorización coinciden con la fuente canónica aunque exista envelope corrupto o privilegiado en Redis. |

### Superficies que hacen bump (contrato operativo)

| Superficie | Cuándo |
| --- | --- |
| Asignaciones de club (`ClubsService`) | create/update/remove/end + sucesión de director |
| Membership requests | approve/reject/create path que altera assignment; expiry bulk |
| Requests (transfer/role) | mutaciones aprobadas que alteran assignments |
| Post-registration step 3 | cambio scope exitoso |

### Concurrencia y bulk

- Bumps multi-usuario usan orden determinista (`bumpOrdered`: dedupe + sort) para evitar deadlocks.
- Expiry masivo de membership usa `updateManyAndReturn` (usuarios exactos expirados) + `bumpMany` set-based.

### Errores / timezone

| Código | HTTP | Cuándo |
| --- | --- | --- |
| `AUTH_CONTEXT_USER_NOT_FOUND` | 401 | Fuente canónica sin usuario |
| `AUTH_CONTEXT_UNAVAILABLE` | 503 | Versión durable o fuente canónica no disponible (fail-closed; no se concede permiso) |
| `LOCAL_FIELD_TIMEZONE_UNAVAILABLE` | 503 | Fuente canónica con asignación activa cuyo Campo Local carece de timezone IANA clasificable (R07; ver Authorization-time / consumidores T08) |

La lectura cache v4 **no** inventa timezone ni autoridad desde Redis. Tras R07, la fuente canónica de `AuthorizationContextService` sí evalúa effectivity con timezone de Campo Local; un envelope cacheado solo reproduce un snapshot ya resuelto bajo esas reglas.

## Critical audit writer y fallos de auditoría

Backend stack C07 (`#253`/`#346`/`#259`/`#260` + remediaciones) publica un escritor transaccional de auditoría crítica. **No introduce endpoints HTTP nuevos.**

### Contrato `AUDIT_WRITE_FAILED`

| Campo | Valor |
| --- | --- |
| Código | `AUDIT_WRITE_FAILED` |
| HTTP | `503 SERVICE_UNAVAILABLE` |
| Semántica | La mutación crítica no pudo confirmar un evento de auditoría durable (persistencia, snapshot incompatible en replay, o carrera no recuperable). |
| Rollback | El caller debe abortar la misma transacción de negocio. Un fallo de audit no se degrada a “éxito sin audit”. |
| Replay exacto | Misma `event_key` + mismo snapshot canónico (incl. `Date` serializados) → `{ replayed: true }` sin segunda fila. |
| Replay incompatible | Misma `event_key` con snapshot distinto → `AUDIT_WRITE_FAILED` (fail-closed). |

Denegaciones de autorización pueden registrarse vía `SecurityDenialAuditService` sin alterar el error original del caller: si el audit durable no está disponible, el denial original se preserva y el fallo de audit se reporta solo a logs.

## Exact super-admin write y primitiva global de roles

Backend stack C07 (`#267`/`#270`/`#279` + remediaciones) añade política y primitiva internas. **No hay ruta HTTP live nueva** para assign/revoke global vía esta primitiva; los controllers RBAC existentes no deben interpretarse como migrados hasta wiring explícito.

### `ExactSuperAdminWritePolicy` / guard

- Exige asignación activa `users_roles` + rol `super-admin` GLOBAL activo.
- `admin` solo, u otros roles globales, **no** satisfacen la política.
- Error: `403 SUPER_ADMIN_WRITE_REQUIRED`.

### Primitiva `GlobalUserRoleWriteService` (interna)

| Regla | Comportamiento |
| --- | --- |
| Actor | Debe pasar `ExactSuperAdminWritePolicy` (revalidada tras locks). |
| Rol objetivo | Solo roles `GLOBAL` activos (`RBAC_GLOBAL_ROLE_REQUIRED` si no). |
| Idempotencia | `event_key = rbac-global-users-role:{idempotencyKey}`; cada mutación distinta necesita su propia clave. |
| Revoke sin fila | No-op (`changed: false`); no crea `users_roles`. |
| Replay opuesto | Misma `idempotencyKey` con mutación contraria → `409 IDEMPOTENCY_KEY_REUSED`. |
| Audit | Escritura vía critical audit writer dentro de la misma transacción; fallo → rollback + `AUDIT_WRITE_FAILED`. |

Consumidores HTTP futuros deben versionar/invalidar contexto de autorización (sección anterior) cuando la primitiva altere autoridad efectiva; mientras no haya wiring, no afirmar integración live.

## Guide Major club-role eligibility (BE-11 foundation)

Backend `#251` introduce `ClubRoleEligibilityService` como fuente P0 para el gate GM-01 sobre **asignaciones de rol de club** (categoría CLUB). **No introduce endpoint HTTP nuevo** y, en este slice, **no cablea** create/edit/schedule/activate/revoke ni succession.

### Contrato `CLUB_ROLE_GUIDE_MAJOR_REQUIRED`

| Campo | Valor |
| --- | --- |
| Código | `CLUB_ROLE_GUIDE_MAJOR_REQUIRED` |
| HTTP | `403 FORBIDDEN` |
| Semántica | El usuario objetivo no cumple elegibilidad Guía Mayor para el rol CLUB solicitado (salvo exención `member`). |
| Consumo | Callers futuros deben invocar `assertEligible` / `evaluate` dentro de la misma transacción de mutación; re-evaluar en activación (no retener grants previos). |

### Reglas de elegibilidad (foundation)

| Caso | Resultado | `basis` |
| --- | --- | --- |
| `roleName === 'member'` (canónico exacto) | Elegible sin consultar enrollments | `MEMBER_EXEMPT` |
| Enrollment `classes.asset_code = GM-01` con `investiture_status = INVESTIDO` (histórico; clase puede estar inactiva) | Elegible | `HISTORICAL_INVESTED` |
| Enrollment activo `GM-01` con status en `IN_PROGRESS`, `SUBMITTED_FOR_VALIDATION`, `CLUB_APPROVED`, `COORDINATOR_APPROVED`, `FIELD_APPROVED` | Elegible | `ACTIVE_ENROLLMENT` |
| Sin match (incl. solo `APPROVED` / `REJECTED` / `EXPIRED` u otros) | No elegible → `CLUB_ROLE_GUIDE_MAJOR_REQUIRED` | `null` |

### Dependencia de Investiture / enrollments

La foundation **lee** `enrollments` + `classes.asset_code` + `investiture_status_enum`. No crea flujo de investidura ni endpoint de validación. Los estados canónicos y el avance a `INVESTIDO` siguen viviendo en el dominio de investiduras/clases (`docs/features/validacion-investiduras.md`, `docs/features/clases-progresivas.md`).

### Distinción vs gate pedagógico live

Las asignaciones pedagógicas `class-counselor-assignments` ya exponen `403 CLASS_COUNSELOR_GUIDE_MAJOR_REQUIRED` con filtro legacy por nombre de clase. Ese contrato live **no** se reemplaza en `#251`. Unificar consumidores al asset `GM-01` / `ClubRoleEligibilityService` es trabajo de follow-up explícito.

## Referencias Relacionadas

- `docs/features/auth/RBAC-ENFORCEMENT-MATRIX.md`
- `docs/features/auth/PERMISSIONS-SYSTEM.md`
- `docs/history/implementation/IMPLEMENTATION-SESSION-2026-03-06-auth-authorization-contract.md`
- `docs/history/implementation/IMPLEMENTATION-SESSION-2026-03-07-rbac-hardening-stage-1.md`
