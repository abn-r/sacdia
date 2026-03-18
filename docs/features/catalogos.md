# Catalogos
Estado: IMPLEMENTADO

## Que existe (verificado contra codigo)
- **Backend**: CatalogsModule (lectura publica, 14 endpoints) + AdminModule (CRUD admin, 20 endpoints de referencia + 20 endpoints de geografia). Catalogo publico: club-types, activity-types, relationship-types, countries, unions, local-fields, districts, churches, roles, ecclesiastical-years, current year, club-ideals, allergies, diseases. Admin CRUD: relationship-types, allergies, diseases, medicines, ecclesiastical-years (AdminReferenceController). Admin Geografia: countries, unions, local-fields, districts, churches (AdminGeographyController).
- **Admin**: 13 pages funcionales. Hub de catalogos. Geografia CRUD: countries, unions, local-fields, districts, churches. Referencia CRUD: allergies, diseases, relationship-types, ecclesiastical-years. Read-only: club-types, club-ideals. Honor categories: CRUD completo (endpoints FANTASMA).
- **App**: Consume catalogos compartidos via CatalogsRemoteDataSourceImpl (club-types, activity-types, districts, churches, roles, ecclesiastical-years). Tambien consume relationship-types, allergies, diseases desde post-registration.
- **DB**: countries, unions, local_fields, districts, churches, club_types, club_ideals, relationship_types, allergies, diseases, medicines, ecclesiastical_years, honors_categories, inventory_categories, finances_categories, activity_types

## Que define el canon
- Canon runtime 6.5 define catalogos como datos de referencia del sistema
- Canon define jerarquia organizacional (pais > union > campo local > distrito > iglesia) como estructura de autoridad, no solo catalogo geografico

## Gap
- 4 endpoints de /admin/medicines sin documentacion API
- GET /catalogs/activity-types sin documentacion API
- Admin consume /admin/club-ideals como endpoint FANTASMA (read-only) — pendiente de implementacion en backend
- Admin consume /admin/honor-categories como endpoints FANTASMA — pendiente de implementacion en backend (ver `docs/features/honores.md`)

## Prioridad
- Media — catalogos son canon de trayectoria; endpoints FANTASMA pendientes de implementacion
