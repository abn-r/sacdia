# Contrato Assignment-First para Roles de Club

**Status**: ACTIVE  
**Fecha**: 2026-03-07  
**Ámbito**: backend, admin, app

## Propósito

Este documento define la unidad canónica de autorización de club.

La unidad oficial ya no es:

- `user + role` suelto;
- `metadata.roles`;
- `club_context` inferido en cliente.

La unidad oficial es la **asignación exacta**.

## Entidad Canónica

Una asignación de rol de club representa:

- `assignment_id`
- `user_id`
- `role_id`
- `role_name`
- `club_id`
- `instance_type`
- `instance_id`
- `ecclesiastical_year_id`
- `start_date`
- `end_date`
- `status`
- `active`

## Modelo Mental

Un usuario puede tener varias asignaciones.

Ejemplos:

- Director en `Club Amanecer / pathfinders / instance_id=9`
- Tesorero en `Club Amanecer / adventurers / instance_id=3`

Solo una asignación puede estar activa en la sesión mediante `active_assignment`.

## Endpoints Canónicos

### 1. Crear asignación

`POST /clubs/:clubId/instances/:type/:instanceId/roles`

Payload:

```json
{
  "user_id": "0a111111-2222-3333-4444-555555555555",
  "role_id": "8b111111-2222-3333-4444-555555555555",
  "instance_type": "pathfinders",
  "instance_id": 9,
  "ecclesiastical_year_id": 2026,
  "start_date": "2026-01-01T00:00:00.000Z",
  "end_date": null
}
```

Notas:

- `clubId`, `type` e `instanceId` vienen en la ruta.
- `instance_type` e `instance_id` también forman parte del payload actual del backend.
- `role_id` debe venir de `GET /catalogs/roles?category=CLUB`.
- `ecclesiastical_year_id` debe venir de `GET /catalogs/ecclesiastical-years` o `GET /catalogs/ecclesiastical-years/current`.

### 2. Actualizar asignación

`PATCH /club-roles/:assignmentId`

Payload actual:

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

`DELETE /club-roles/:assignmentId`

Semántica:

- soft delete;
- marca `active = false`;
- marca `status = ended`;
- fija `end_date`.

### 4. Activar contexto de sesión

`PATCH /auth/me/context`

Payload:

```json
{
  "assignment_id": "2b111111-2222-3333-4444-555555555555"
}
```

Respuesta relevante:

- `authorization.active_assignment`
- `authorization.effective`

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
- No debe interpretar que `metadata.roles` representa cargos de club efectivos.

## Compatibilidad Temporal

Persisten flujos legacy members-centric en algunos consumidores.

Ejemplos de anti-patrón que deben eliminarse:

- actualizar rol usando `userId + role`;
- reconstruir contexto desde `club` plano en metadata;
- asumir que todas las asignaciones aportan permisos simultáneamente.

## Convenciones

### `instance_type`

Valores válidos:

- `adventurers`
- `pathfinders`
- `master_guilds`

### `role_name`

Los nombres canónicos de roles de club esperados por backend incluyen:

- `director`
- `deputy_director`
- `secretary`
- `treasurer`
- `counselor`
- `instructor`
- `member`

El backend mantiene normalización para algunos aliases legacy, pero clientes nuevos deben usar nombres canónicos.

## Regla de Seguridad

Las asignaciones disponibles describen lo que el usuario tiene.

La autorización efectiva de club sale solo de:

- `authorization.active_assignment`
- `authorization.effective.scope.club`
- `authorization.effective.permissions`

## Referencias Relacionadas

- `docs/01-FEATURES/auth/AUTHORIZATION-CANONICAL-CONTRACT.md`
- `docs/01-FEATURES/auth/RBAC-ENFORCEMENT-MATRIX.md`
- `docs/01-FEATURES/auth/future-rbac-user-stories.md`
