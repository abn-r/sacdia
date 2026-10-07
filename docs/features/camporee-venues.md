# Sedes de camporee (venues)

**Estado**: IMPLEMENTADO
**Verificado contra código**: 2026-10-04 (rama `development`)
**Dominios relacionados**: [camporees.md](camporees.md), [camporee-events.md](camporee-events.md) (agenda y `camporee_events.venue_id`)

## Descripcion de dominio

Una sede es un lugar físico reutilizable (cancha, auditorio, área de cocina) donde se programan eventos de camporee. Pertenece a una unión o a un campo local y se asigna a los eventos de la agenda. Personal, plantillas y puntuación de camporee ya están en [camporees.md](camporees.md) y [camporee-events.md](camporee-events.md); este documento cubre solo las sedes.

## Que existe (verificado contra codigo)

### Backend (`src/camporee-venues/`)

Controller con `JwtAuthGuard` + `PermissionsGuard`.

| Método | Ruta (`/api/v1`) | Permiso | Recurso |
|---|---|---|---|
| GET | `/camporee-venues` (filtros `scope`, `union_id`, `local_field_id`) | `camporee_events:read` | `active_assignment` |
| GET | `/camporee-venues/:venueId` | `camporee_events:read` | `active_assignment` |
| POST | `/camporee-venues` | `camporee_events:create` | `camporee_venue` |
| PATCH | `/camporee-venues/:venueId` | `camporee_events:update` | `camporee_venue` |
| DELETE | `/camporee-venues/:venueId` | `camporee_events:delete` | `camporee_venue` |
| GET / POST | `/local-camporees/:camporeeId/venues` | `camporee_events:read` / `camporee_events:create` | `camporee` |
| GET / POST | `/union-camporees/:camporeeId/venues` | `camporee_events:read` / `camporee_events:create` | `union_camporee` |

Reglas verificadas en `camporee-venues.service.ts`:

- **Ámbito exclusivo**: `scope = 'union'` exige `union_id` y prohíbe `local_field_id`; `scope = 'local_field'` exige `local_field_id` y prohíbe `union_id`. Cualquier otro valor: `CAMPOREE_VENUE_SCOPE_INVALID`.
- **Sedes visibles para un camporee local**: sedes activas de su campo local y de la unión de ese campo.
- **Sedes visibles para un camporee de unión**: solo sedes activas de esa unión.
- **Alta desde un camporee**: `POST /local-camporees/:id/venues` crea la sede con `scope = 'local_field'` del campo del camporee; `POST /union-camporees/:id/venues` la crea con `scope = 'union'`. Camporee inexistente: `CAMPOREE_EVENT_CAMPOREE_NOT_FOUND`.
- **Baja**: borrado lógico (`active = false`), con `modified_by`. Los eventos que ya la usan conservan el `venue_id`.
- Sede inexistente: `CAMPOREE_VENUE_NOT_FOUND`.

### Admin

- `src/lib/api/camporee-venues.ts`. Se usa en el detalle de camporee local y de unión (`/dashboard/campamentos/[id]`, `/dashboard/campamentos/union/[id]`) y en los formularios de alta y edición de eventos.

### App móvil

- Sin consumo directo; la app recibe la sede dentro del detalle de evento (`events/preview`).

### Base de datos

- `camporee_venues`: `scope`, `union_id`, `local_field_id`, `name` (150), `description` (500), `capacity`, `active`, `created_by`, `modified_by`. Índices por `(union_id, active)`, `(local_field_id, active)` y `(scope, active)`.
- `camporee_events.venue_id` → `camporee_venues` (`ON DELETE SET NULL`).

## Gaps y pendientes

- `capacity` es informativo: no se valida contra participantes de un evento.
- La baja lógica no avisa si la sede tiene eventos futuros programados.
