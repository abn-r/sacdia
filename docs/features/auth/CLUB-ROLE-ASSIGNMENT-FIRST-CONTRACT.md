# Contrato Assignment-First para Roles de Club

**Status**: ACTIVE  
**Fecha**: 2026-03-08  
**Actualizado**: 2026-10-04 (rescatado de `docs/history/01-FEATURES/auth/` y alineado a `club_sections`)  
**Ámbito**: backend, admin, app

## Propósito

Este documento define la unidad canónica de autorización de club.

La unidad oficial ya no es:

- `user + role` suelto;
- `metadata.roles`;
- `club_context` inferido en cliente.

La unidad oficial es la **asignación exacta** (`club_role_assignments`).

## Entidad Canónica

Una asignación de rol de club (`club_role_assignments` en `sacdia-backend/prisma/schema.prisma`) tiene:

- `assignment_id` (UUID)
- `user_id`
- `role_id` (rol de categoría `CLUB`)
- `club_section_id` (sección del club; el tipo de club sale de `club_sections.club_type_id`)
- `ecclesiastical_year_id`
- `start_date`
- `end_date`
- `status` (default `active`)
- `active`
- `expires_at` y `rejection_reason` (flujos de solicitud y vencimiento)

Las rutas antiguas basadas en instancias (`instance_type` / `instance_id`, con valores `adventurers`, `pathfinders`, `master_guilds`) quedaron reemplazadas por `club_section_id`.

## Modelo Mental

Un usuario puede tener varias asignaciones.

Ejemplos:

- Director en `Club Amanecer`, sección de Conquistadores (`club_section_id=9`)
- Tesorero en `Club Amanecer`, sección de Aventureros (`club_section_id=3`)

Solo una asignación puede estar activa en la sesión mediante `active_assignment`.

## Endpoints Canónicos

Controllers: `ClubsController` y `ClubRolesController` en `sacdia-backend/src/clubs/clubs.controller.ts`. DTOs en `src/clubs/dto/role-assignment.dto.ts`.

### 1. Crear asignación

`POST /api/v1/clubs/:clubId/sections/:sectionId/roles`

- Permiso: `club_roles:assign`. Recurso de autorización: `club` (`clubIdParam: clubId`).
- Body: `AssignRoleDto`.

```json
{
  "user_id": "0a111111-2222-3333-4444-555555555555",
  "role_id": "8b111111-2222-3333-4444-555555555555",
  "ecclesiastical_year_id": 2026,
  "start_date": "2026-01-01T00:00:00.000Z",
  "end_date": null
}
```

Notas:

- `clubId` y `sectionId` vienen en la ruta. `club_section_id` en el body es opcional; si llega y no coincide con `sectionId`, responde 400 `GUARD_ASSIGNMENT_SCOPE_INVALID`.
- `role_id` es el campo preferido y debe venir de `GET /api/v1/catalogs/roles?category=CLUB`. Solo se aceptan roles `CLUB` activos; un `role_id` `GLOBAL` o inactivo responde 400 `CLUB_ROLE_NOT_FOUND`.
- `role` (nombre del rol) se mantiene solo como compatibilidad temporal.
- `ecclesiastical_year_id` debe venir de `GET /api/v1/catalogs/ecclesiastical-years` o `GET /api/v1/catalogs/ecclesiastical-years/current`.
- Un rango de fechas inválido responde 400.

El director tiene rutas dedicadas en la misma sección: `POST .../director-assignment`, `POST .../director-succession` y `GET/POST/PATCH/DELETE .../director-designation` (ver [ENDPOINTS-LIVE-REFERENCE.md](../../api/ENDPOINTS-LIVE-REFERENCE.md), sección `clubs`).

### 2. Actualizar asignación

`PATCH /api/v1/club-roles/:assignmentId`

- Permiso: `club_roles:assign`. Recurso de autorización: `club_assignment` (`idParam: assignmentId`).
- Body: `UpdateRoleAssignmentDto` (todos opcionales): `role_id`, `role`, `ecclesiastical_year_id`, `start_date`, `end_date`, `status`.

```json
{
  "end_date": "2026-12-31T00:00:00.000Z",
  "status": "inactive"
}
```

Uso principal:

- cierre administrativo;
- cambio de estado;
- finalización de vigencia.

### 3. Revocar asignación

`DELETE /api/v1/club-roles/:assignmentId`

- Permiso: `club_roles:revoke`. Recurso de autorización: `club_assignment`.

Semántica (`ClubsService.removeRoleAssignment`):

- soft delete;
- marca `active = false`;
- marca `status = 'ended'`;
- fija `end_date`.

### 4. Activar contexto de sesión

`PATCH /api/v1/auth/me/context`

Payload (`SetActiveClubContextDto`):

```json
{
  "assignment_id": "2b111111-2222-3333-4444-555555555555"
}
```

Respuesta relevante:

- `authorization.active_assignment`
- `authorization.effective`

Errores documentados en la referencia live: asignación `inactive`/`ended`, de un año no vigente o `designated` → 400 `AUTH_ASSIGNMENT_YEAR_MISMATCH`; corte del club no completado → 503 `CLUB_CYCLE_NOT_READY`.

## Semántica de Enforcement (Alineada a Matriz)

| Operación | Endpoint | Recurso de autorización | Criterio base |
|-----------|----------|-------------------------|---------------|
| Crear asignación | `POST /clubs/:clubId/sections/:sectionId/roles` | `club` | `club_roles:assign` + contexto de club válido + reglas complementarias de rol |
| Actualizar asignación | `PATCH /club-roles/:assignmentId` | `club_assignment` | `club_roles:assign` + relación válida con `assignment_id` o bypass global |
| Revocar asignación | `DELETE /club-roles/:assignmentId` | `club_assignment` | `club_roles:revoke` + relación válida con `assignment_id` o bypass global |

Regla de sesión:

- `PATCH /auth/me/context` es el mecanismo único para cambiar asignación activa en sesión.

## Reglas de Cliente

### `sacdia-admin`

- Debe escribir sobre `assignment_id` para update/revoke.
- Debe crear asignaciones usando `role_id`, no solo nombre de rol.
- Debe poblar formularios desde catálogos:
  - roles de club;
  - años eclesiásticos.

### `sacdia-app`

- Debe leer asignaciones desde `authorization.grants.club_assignments`.
- Debe leer contexto activo desde `authorization.effective.scope.club`.
- No debe interpretar que `metadata.roles` o el bloque `legacy` representan cargos de club efectivos.

## Compatibilidad Temporal

Persisten flujos legacy members-centric en algunos consumidores.

Ejemplos de anti-patrón que deben eliminarse:

- actualizar rol usando `userId + role`;
- reconstruir contexto desde `club` plano en metadata;
- asumir que todas las asignaciones aportan permisos simultáneamente.

## Convenciones

### `role_name`

Los roles `CLUB` sembrados en `prisma/seeds/role-permissions.seed.sql` son:

- `director`
- `deputy-director`
- `secretary`
- `treasurer`
- `secretary-treasurer`
- `counselor`
- `instructor`
- `member`

Los cupos por rol están en `prisma/seeds/role-slot-limits.seed.sql`. Clientes nuevos deben usar `role_id`.

## Regla de Seguridad

Las asignaciones disponibles describen lo que el usuario tiene.

La autorización efectiva de club sale solo de:

- `authorization.active_assignment`
- `authorization.effective.scope.club`
- `authorization.effective.permissions`

## Referencias Relacionadas

- [AUTHORIZATION-CANONICAL-CONTRACT.md](./AUTHORIZATION-CANONICAL-CONTRACT.md)
- [RBAC-ENFORCEMENT-MATRIX.md](./RBAC-ENFORCEMENT-MATRIX.md)
- [PERMISSIONS-SYSTEM.md](./PERMISSIONS-SYSTEM.md)
- [ENDPOINTS-LIVE-REFERENCE.md](../../api/ENDPOINTS-LIVE-REFERENCE.md)
