# Camporees
Estado: PARCIAL

## Que existe (verificado contra codigo)
- **Backend**: CamporeesModule — 8 endpoints (list, detail, create, update, delete, register member, list members, remove member). Controller: CamporeesController. Guards: JwtAuthGuard, PermissionsGuard, ClubRolesGuard.
- **Admin**: 1 page read-only (camporees list via ModuleListPage). Consume GET /camporees. Las acciones de CRUD y gestion de miembros existen en lib/camporees/actions.ts y lib/api/camporees.ts pero la page solo muestra listado.
- **App**: No implementado. No hay screens de camporees.
- **DB**: local_camporees, union_camporees, union_camporee_local_fields, camporee_clubs, camporee_members

## Que define el canon
- Canon runtime 6.6 menciona camporees como capacidad operativa
- Canon dominio no detalla reglas especificas de camporees mas alla de ser evento institucional

## Gap
- App no tiene screens para camporees
- Admin tiene acciones implementadas en codigo pero la UI es read-only
- Canon no profundiza en el modelo de camporees

## Prioridad
- A definir por el desarrollador
