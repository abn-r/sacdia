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

`GET /clubs/:clubId/units/:unitId` agrega `scoring_members [{user_id, name, paternal_last_name, maternal_last_name, user_image, unit_role}]`: los participantes de puntaje de la unidad. Son los miembros activos, el capitán (`unit_role: captain`) y el secretario (`secretary`); nunca el consejero (`advisor_id`) ni el consejero suplente (`substitute_advisor_id`), aunque figuren como miembros. El resto de los miembros llevan `unit_role: member`.

Reglas verificadas en `units.service.ts`:

- **Alta**: el club debe existir (`UNIT_CLUB_NOT_FOUND`) y `club_section_id` es obligatorio. La sección debe estar activa (`UNIT_SECTION_NOT_FOUND`), pertenecer al club (`UNIT_SECTION_WRONG_CLUB`) y ser del `club_type_id` indicado (`UNIT_SECTION_TYPE_MISMATCH`).
- **Edición**: actualiza solo los campos enviados; si cambia la sección, repite las validaciones de sección.
- **Baja**: borrado lógico (`units.active = false`).
- **Agregar miembro**: el usuario debe existir (`UNIT_USER_NOT_FOUND`) y tener una asignación activa en la sección de la unidad (`UNIT_USER_NOT_IN_SECTION`). Un usuario solo puede estar en una unidad activa por sección (`UNIT_MEMBER_ALREADY_IN_SECTION`). Si ya fue miembro de esta unidad y estaba inactivo, se reactiva la misma fila; si está activo, `UNIT_MEMBER_ALREADY_IN_UNIT`.
- **Quitar miembro**: borrado lógico (`unit_members.active = false`).
- **Invalidación en tiempo real**: agregar o quitar un miembro llama a `NotificationsService.sendSilentToSection` con `resource: 'members'` (sin esperar la respuesta; un fallo solo se registra en log).

### App móvil (`sacdia-app/lib/features/units/`)

- `UnitsListView`, `UnitDetailView`, `UnitFormView` (alta y edición a pantalla completa), `UnitPointsHistoryView` y `MemberOfMonthHistoryView`.
- Quien gestiona unidades (`units:create` o `units:update`) siempre aterriza en la lista, aunque tenga una sola unidad; la apertura automática de la única unidad aplica solo a quien no gestiona.
- La lista de puntos (planilla semanal) usa `scoring_members`: incluye al capitán y al secretario con su rol como etiqueta, y no al consejero ni al suplente. Si el servidor no envía `scoring_members`, el cliente deriva la lista de `members` excluyendo a los consejeros.
- El detalle de unidad ya no muestra «Actividades de esta semana».
- Al retroceder, Unidades vuelve al dashboard cuando es la primera página (`lib/core/utils/back_or_home.dart`).

### Admin

- Sin pantalla de gestión de unidades. `src/components/units/member-combobox.tsx` se reutiliza como selector de miembros en otros formularios (camporees, notificaciones).

### Base de datos

- `units`: `name`, `captain_id`, `secretary_id`, `advisor_id` (obligatorios), `substitute_advisor_id`, `club_type_id`, `club_section_id` (nullable en el schema, obligatorio en el servicio), `active`.
- `unit_members`: `unit_id`, `user_id`, `active`.

## Gaps y pendientes

- Sin historial de movimientos entre unidades (también señalado en [gestion-clubs.md](gestion-clubs.md)).
- El servicio no valida que capitán, secretario y consejeros pertenezcan a la sección.
- Sin gestión de unidades en el admin.
