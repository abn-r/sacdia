# Contrato Canonico de Autorizacion

**Status**: ACTIVE
**Fecha**: 2026-03-10
**Ambito**: `sacdia-backend`, `sacdia-admin`, `sacdia-app`

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
- `post_registration:read` / `post_registration:update`.

Regla de enforcement:

- ownership sobre `userId` mantiene self-service estricto del propio usuario;
- para terceros, solo cuentan permisos globales;
- permisos de club provenientes de `authorization.active_assignment` NO habilitan acceso a recursos `user` de terceros.

OR transicional vigente:

- lecturas finas aceptan `family:read` O el legado de la familia `users:*` para lectura (`users:read_detail`);
- escrituras finas aceptan `family:update` O el legado de la familia `users:*` para escritura (`users:update`).

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

El runtime vigente todavia permite que un actor no owner con permiso global `users:update` ejecute:

- `POST /users/:userId/post-registration/step-1/complete`;
- `POST /users/:userId/post-registration/step-2/complete`;
- `POST /users/:userId/post-registration/step-3/complete`.

La decision funcional canonica queda cerrada asi:

- no declarar permisos nuevos por suposicion;
- `GET /users/:userId/post-registration/status` permite lectura administrativa minima de terceros con `post_registration:read` o fallback legacy `users:read_detail`;
- `POST /users/:userId/post-registration/step-{1,2,3}/complete` permite completion administrativa minima de terceros con `post_registration:update` o fallback legacy `users:update`;
- ownership mantiene feedback detallado actual;
- terceros no reciben en respuestas ni errores detalles sensibles del usuario objetivo.

### Politica de cliente - excepcion minima para terceros

La politica canonica para clientes queda asi:

- `process-state` / `administrative completion` de terceros puede reflejarse cuando exista autorizacion global resuelta explicita (`post_registration:read` o `users:read_detail` para lectura; `post_registration:update` o `users:update` para escritura);
- `GET /post-registration/status` para terceros debe limitarse al estado administrativo minimo del proceso y no necesita feedback guiado tipo `nextStep`;
- `POST /step-{1,2,3}/complete` para terceros debe usar respuestas y errores minimos, sin devolver detalles sensibles del paso 2 ni feedback detallado del usuario objetivo;
- datos sensibles enviados por el usuario (`health` = `allergies` + `diseases` + `medicines`, `emergency contacts`, `legal representative`, perfil sensible derivado del paso 2) NO deben quedar expuestos ni editables en clientes de terceros solo por `users:update` generico;
- `sacdia-admin` y `sacdia-app` deben degradar u ocultar esas superficies cuando no exista una senal explicita compatible con esta politica minima.

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

## Referencias Relacionadas

- `docs/features/auth/RBAC-ENFORCEMENT-MATRIX.md`
- `docs/features/auth/PERMISSIONS-SYSTEM.md`
- `docs/history/implementation/IMPLEMENTATION-SESSION-2026-03-06-auth-authorization-contract.md`
- `docs/history/implementation/IMPLEMENTATION-SESSION-2026-03-07-rbac-hardening-stage-1.md`
