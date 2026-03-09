# Contrato Canónico de Autorización

**Status**: ACTIVE  
**Fecha**: 2026-03-09  
**Ámbito**: `sacdia-backend`, `sacdia-admin`, `sacdia-app`

## Propósito

Este documento define la fuente de verdad para autorización en SACDIA.

La regla principal es:

- el backend resuelve autorización;
- los clientes consumen autorización resuelta;
- los campos legacy existen solo por compatibilidad temporal.

## Precedencia Documental

Para evitar contratos paralelos, la precedencia oficial es:

1. `AUTHORIZATION-CANONICAL-CONTRACT.md` (shape y semántica del payload `authorization`).
2. `RBAC-ENFORCEMENT-MATRIX.md` (cómo se enforcea cada permiso en backend).
3. `CLUB-ROLE-ASSIGNMENT-FIRST-CONTRACT.md` (modelo de escrituras/lecturas de asignaciones de club).

Regla explícita:

- el arreglo plano `permissions` legacy no es fuente oficial de autorización para clientes nuevos.

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

## Semántica

### `authorization.grants`

Describe lo que el usuario tiene asignado en el sistema.

- `global_roles`: inventario de roles globales con alcance territorial.
- `club_assignments`: inventario de asignaciones exactas por club e instancia.

### `authorization.active_assignment`

Describe cuál asignación de club está activa en la sesión actual.

- Si es `null`, el usuario no tiene contexto activo de club.
- Si tiene valor, solo esa asignación aporta permisos de club a `effective`.

### `authorization.effective`

Describe lo que el backend ya resolvió para la sesión actual.

- `effective.permissions`: permisos listos para gating en clientes.
- `effective.scope.global`: alcance territorial resuelto.
- `effective.scope.club`: contexto activo exacto de club e instancia.

## Reglas Canónicas para Recursos `user`

Cuando una ruta usa `@AuthorizationResource({ type: 'user', ownerParam: 'userId' })`, el contrato runtime vigente es:

- ownership real sobre `userId` habilita self-service estricto para el propio usuario;
- si no hay ownership, el actor necesita permiso global suficiente (`users:read_detail` para lecturas, `users:update` para escrituras);
- permisos provenientes solo de `active_assignment` no habilitan acceso transversal a recursos `user` de terceros.

Sub-recursos sensibles hoy cubiertos por este modelo:

- perfil base y foto de perfil;
- alergias y enfermedades;
- contactos de emergencia;
- representante legal;
- estado y pasos de post-registro;
- endpoints derivados como edad calculada y `requires-legal-representative`.

### GAP FORMAL - tiering de datos sensibles

El modelo RBAC vigente NO distingue con permisos dedicados entre:

- perfil general;
- salud;
- contactos de emergencia;
- representante legal;
- progreso de post-registro.

Por lo tanto:

- no declarar tiers finos de acceso que el runtime actual no enforcea;
- documentar estos sub-recursos como heredando `users:read_detail` o `users:update` + ownership/admin access.

### DECISION PENDING - administracion de post-registro sobre terceros

El runtime vigente todavia permite que un actor no owner con permiso global `users:update` ejecute:

- `POST /users/:userId/post-registration/step-1/complete`;
- `POST /users/:userId/post-registration/step-2/complete`;
- `POST /users/:userId/post-registration/step-3/complete`.

Esta capacidad existe hoy en backend, pero sigue abierta como decision funcional canónica.

Hasta resolverla:

- no declarar permisos nuevos por suposicion;
- no asumir que `users:update` habilita lectura o edicion de datos sensibles de terceros;
- tratar la administracion de `process-state` / `administrative completion` como excepcion minima documentada, no como permiso fino nuevo.

### Politica de cliente - opcion C minima para terceros

Las rutas de post-registro siguen usando el recurso `user`, por lo que runtime todavia permite que un actor con permiso global `users:update` las mutile aunque no sea owner.

La politica canónica para clientes queda asi:

- `process-state` / `administrative completion` de terceros puede reflejarse cuando exista autorizacion global resuelta explicita (`users:read_detail` para lectura, `users:update` para escritura);
- datos sensibles enviados por el usuario (`health`, `emergency contacts`, `legal representative`, perfil sensible derivado del paso 2) NO deben quedar expuestos ni editables en clientes de terceros solo por `users:update` genérico;
- `sacdia-admin` y `sacdia-app` deben degradar u ocultar esas superficies cuando no exista una señal explicita compatible con esta politica minima.

## Registro Canonico de Abiertos

Los abiertos vigentes tras Batch 1, Batch 2 y Batch 3 son exactamente estos:

1. `GAP FORMAL`: no existe tier RBAC separado para perfil general vs salud vs contactos de emergencia vs representante legal vs progreso de post-registro.
2. `DECISION PENDING`: falta definir si la administracion de post-registro de terceros via `users:update` global debe mantenerse como politica estable o cerrarse en una etapa posterior.

Regla de control de scope:

- no agregar permisos nuevos ni reinterpretar permisos legacy para cerrar estos abiertos a nivel cliente;
- cualquier cambio futuro debe partir de backend + contrato canónico actualizado.

## Validacion Transversal Final

Validacion documental final de Batch 3:

- backend: el contrato `user` verificado se mantiene en ownership o permiso global; `active_assignment` no habilita acceso a terceros;
- `sacdia-admin`: el consumo canónico sigue siendo `authorization.effective.permissions` y `authorization.grants`;
- `sacdia-app`: el gating sensible usa ownership o `users:read_detail`, y separa eso de `users:update` para `administrative completion`;
- docs activas de auth y API quedan alineadas sobre los mismos dos abiertos: `GAP FORMAL` y `DECISION PENDING`.

## Reglas de Consumo

### Backend

- La autorización se enforcea contra `authorization`.
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

- siguen vivos solo durante migración;
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
              "union": { "id": 7, "name": "Unión Norte" },
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
              "union": { "id": 7, "name": "Unión Norte" },
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
            "union": { "id": 7, "name": "Unión Norte" },
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

- `docs/01-FEATURES/auth/RBAC-ENFORCEMENT-MATRIX.md`
- `docs/01-FEATURES/auth/CLUB-ROLE-ASSIGNMENT-FIRST-CONTRACT.md`
- `docs/01-FEATURES/auth/PERMISSIONS-SYSTEM.md`
- `docs/history/implementation/IMPLEMENTATION-SESSION-2026-03-06-auth-authorization-contract.md`
- `docs/history/implementation/IMPLEMENTATION-SESSION-2026-03-07-rbac-hardening-stage-1.md`
