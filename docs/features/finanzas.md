# Finanzas
Estado: PARCIAL

## Que existe (verificado contra codigo)
- **Backend**: FinancesModule — 7 endpoints (categories, list by club, summary, create, detail, update, delete). Controller: FinancesController. Guards: JwtAuthGuard, PermissionsGuard, ClubRolesGuard.
- **Admin**: Placeholder — redirige a seleccionar club. No consume endpoints. No tiene funcionalidad.
- **App**: 3 screens (FinancesView, AddTransactionSheet, TransactionDetailView). Consume los 7 endpoints del backend incluyendo listado con filtros por ano/mes, resumen financiero y CRUD de transacciones.
- **DB**: finances, finances_categories

## Que define el canon
- Canon runtime 6.6 menciona finanzas como capacidad operativa del sistema

## Gap
- Admin es placeholder — backend y app estan completos pero admin no tiene UI funcional

## Prioridad
- A definir por el desarrollador
