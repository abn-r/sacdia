# Actividades
Estado: PARCIAL

## Que existe (verificado contra codigo)
- **Backend**: ActivitiesModule — 7 endpoints (list by club, create, detail, update, delete, register attendance, get attendance). Controller: ActivitiesController. Guards: JwtAuthGuard, PermissionsGuard, ClubRolesGuard.
- **Admin**: Placeholder — redirige a seleccionar club. No consume endpoints. No tiene funcionalidad.
- **App**: 4 screens (ActivitiesListView, ActivityDetailView, CreateActivityView, LocationPickerView). Consume los 7 endpoints del backend. Incluye selector de ubicacion en mapa. Nota: /home/activities tiene clubId hardcodeado a 1.
- **DB**: activities, activity_types, activity_instances

## Que define el canon
- Canon runtime 6.6 menciona actividades como capacidad operativa del sistema
- Actividades son parte de la operacion concreta de la seccion de club

## Gap
- Admin es placeholder — backend y app estan completos pero admin no tiene UI funcional
- GET /catalogs/activity-types existe en backend pero sin documentacion API ni canon

## Prioridad
- A definir por el desarrollador
