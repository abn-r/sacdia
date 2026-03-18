# Inventario
Estado: PARCIAL

## Que existe (verificado contra codigo)
- **Backend**: InventoryModule — 6 endpoints (list by club, detail, create, update, delete, categories). Controller: InventoryController. Guards: JwtAuthGuard, PermissionsGuard.
- **Admin**: Placeholder — redirige a seleccionar club. No consume endpoints. No tiene funcionalidad.
- **App**: 4 screens (InventoryView, InventoryItemDetailView, AddInventoryItemSheet, InventoryFilterSheet). Consume los 6 endpoints del backend incluyendo categorias, CRUD completo y filtros.
- **DB**: club_inventory, inventory_categories

## Que define el canon
- Canon runtime 6.6 menciona inventario como capacidad operativa del sistema

## Gap
- Admin es placeholder — backend y app estan completos pero admin no tiene UI funcional

## Prioridad
- A definir por el desarrollador
