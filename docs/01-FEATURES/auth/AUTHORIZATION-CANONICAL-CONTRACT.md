# Contrato Canónico de Autorización

**Status**: ACTIVE  
**Fecha**: 2026-03-07  
**Ámbito**: `sacdia-backend`, `sacdia-admin`, `sacdia-app`

## Propósito

Este documento define la fuente de verdad para autorización en SACDIA.

La regla principal es:

- el backend resuelve autorización;
- los clientes consumen autorización resuelta;
- los campos legacy existen solo por compatibilidad temporal.

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
- `docs/history/implementation/IMPLEMENTATION-SESSION-2026-03-06-auth-authorization-contract.md`
