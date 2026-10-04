# Unidades

**Estado**: IMPLEMENTADO
**Verificado contra código**: 2026-10-04 (rama `development`)
**Dominios relacionados**: [weekly-records.md](weekly-records.md) (puntaje semanal de la unidad), [member-of-month.md](member-of-month.md), [gestion-clubs.md](gestion-clubs.md)

## Descripcion de dominio

Una unidad es un grupo pequeño de miembros dentro de una sección de club, con capitán, secretario, consejero y consejero suplente. Las unidades organizan la operación semanal: sobre ellas se capturan los registros semanales y se calcula el miembro del mes. Este documento cubre la gestión de unidades y sus miembros; los registros semanales están en [weekly-records.md](weekly-records.md).

## Que existe (verificado contra codigo)

### Backend (`src/units/`)

Controller con `JwtAuthGuard` + `PermissionsGuard` y `AuthorizationResource({ type: 'club', clubIdParam: 'clubId' })` en cada ruta.

| Método | Ruta (`/api/v1`) | Permiso |
|---|---|---|
| GET | `/clubs/:clubId/units` | `units:read` |
| POST | `/clubs/:clubId/units` | `units:create` |
| GET | `/clubs/:clubId/units/:unitId` | `units:read` |
| PATCH | `/clubs/:clubId/units/:unitId` | `units:update` |
| DELETE | `/clubs/:clubId/units/:unitId` | `units:delete` |
| POST | `/clubs/:clubId/units/:unitId/members` | `units:update` |
| DELETE | `/clubs/:clubId/units/:unitId/members/:memberId` | `units:update` |

Las 4 rutas de `/weekly-records` del mismo controller están en [weekly-records.md](weekly-records.md).

Reglas verificadas en `units.service.ts`:

- **Alta**: el club debe existir (`UNIT_CLUB_NOT_FOUND`) y `club_section_id` es obligatorio. La sección debe estar activa (`UNIT_SECTION_NOT_FOUND`), pertenecer al club (`UNIT_SECTION_WRONG_CLUB`) y ser del `club_type_id` indicado (`UNIT_SECTION_TYPE_MISMATCH`).
- **Edición**: actualiza solo los campos enviados; si cambia la sección, repite las validaciones de sección.
- **Baja**: borrado lógico (`units.active = false`).
- **Agregar miembro**: el usuario debe existir (`UNIT_USER_NOT_FOUND`) y tener una asignación activa en la sección de la unidad (`UNIT_USER_NOT_IN_SECTION`). Un usuario solo puede estar en una unidad activa por sección (`UNIT_MEMBER_ALREADY_IN_SECTION`). Si ya fue miembro de esta unidad y estaba inactivo, se reactiva la misma fila; si está activo, `UNIT_MEMBER_ALREADY_IN_UNIT`.
- **Quitar miembro**: borrado lógico (`unit_members.active = false`).
- **Invalidación en tiempo real**: agregar o quitar un miembro llama a `NotificationsService.sendSilentToSection` con `resource: 'members'` (sin esperar la respuesta; un fallo solo se registra en log).

### App móvil (`sacdia-app/lib/features/units/`)

- `UnitsListView`, `UnitDetailView`, `UnitFormSheet` (alta y edición), `UnitPointsHistoryView` y `MemberOfMonthHistoryView`.

### Admin

- Sin pantalla de gestión de unidades. `src/components/units/member-combobox.tsx` se reutiliza como selector de miembros en otros formularios (camporees, notificaciones).

### Base de datos

- `units`: `name`, `captain_id`, `secretary_id`, `advisor_id` (obligatorios), `substitute_advisor_id`, `club_type_id`, `club_section_id` (nullable en el schema, obligatorio en el servicio), `active`.
- `unit_members`: `unit_id`, `user_id`, `active`.

## Gaps y pendientes

- Sin historial de movimientos entre unidades (también señalado en [gestion-clubs.md](gestion-clubs.md)).
- El servicio no valida que capitán, secretario y consejeros pertenezcan a la sección.
- Sin gestión de unidades en el admin.
