# Inventario

**Estado**: IMPLEMENTADO

## Descripcion de dominio

El inventario gestiona los bienes materiales de cada club de Conquistadores, Aventureros o Guias Mayores. Los clubes acumulan equipamiento a lo largo de los anos: carpas, utensilios de cocina, herramientas, equipos de sonido, materiales didacticos, banderas, uniformes de respaldo, botiquines, cuerdas, brujulas y todo tipo de insumos para campamentos y actividades.

El control de inventario es critico para la planificacion logistica de campamentos y camporees. Saber que tiene el club, en que estado se encuentra y que cantidad hay disponible evita gastos innecesarios y permite una distribucion equitativa de recursos entre unidades. El inventario esta categorizado mediante un catalogo compartido (`inventory_categories`) que estandariza la clasificacion entre clubes.

Cada item del inventario pertenece a una instancia/seccion operativa de club (`club_section_id`) y tiene campos para nombre, descripcion, cantidad y categoria. El sistema soporta filtrado por categoria para facilitar la busqueda de items especificos.

## Que existe (verificado contra codigo)

### Backend (InventoryModule)
- **Controller**: `src/inventory/inventory.controller.ts`
- **Service**: `src/inventory/inventory.service.ts`
- **Guards**: JwtAuthGuard, PermissionsGuard
- **7 endpoints**:
  - `GET /api/v1/inventory/catalogs/inventory-categories` — Listar categorias de inventario
  - `GET /api/v1/inventory/clubs/:clubId/inventory` — Listar items del inventario de una instancia de club
  - `POST /api/v1/inventory/clubs/:clubId/inventory` — Agregar nuevo item al inventario
  - `GET /api/v1/inventory/inventory/:id` — Obtener detalles de un item
  - `GET /api/v1/inventory/inventory/:inventoryId/history` — Obtener historial de cambios del item
  - `PATCH /api/v1/inventory/inventory/:id` — Actualizar un item
  - `DELETE /api/v1/inventory/inventory/:id` — Eliminar logicamente un item (`active=false`)

### Admin
- **UI funcional en `/dashboard/inventory`**
  - selector de club
  - filtro por categoria
  - tabla de items
  - dialogos de alta/edicion/eliminacion
  - dialogo de historial por item
- Consume categorias, listado, alta, edicion, eliminacion logica e historial

### App Movil
- **4 screens**: InventoryView, InventoryItemDetailView, AddInventoryItemSheet, InventoryFilterSheet
- Consume categorias, listado, detalle, alta, edicion y eliminacion
- CRUD completo desde la app
- Incluye filtrado por categorias

### Base de datos
- `club_inventory` — Items del inventario por club/seccion, con `active` para soft delete
- `inventory_categories` — Catalogo de categorias de inventario
- `inventory_history` — Historial de cambios por campo/accion (`CREATE`, `UPDATE`, `DELETE`)
- **Nota**: `inventory_categories` tenia un typo en el PK (`inventory_categoty_id`). Corregido en schema.prisma; migracion `20260320000000_fix_inventory_category_id_typo` creada (pendiente de deploy).

## Requisitos funcionales

1. Cada club debe poder registrar items de inventario con nombre, descripcion, cantidad, condicion y categoria
2. El inventario debe ser consultable por club con filtros por categoria
3. Los items deben poder actualizarse para reflejar cambios de descripcion, cantidad o categoria
4. Los items deben poder darse de baja mediante desactivacion logica del registro operativo
5. Las categorias de inventario deben ser un catalogo compartido y gestionable
6. El panel admin debe ofrecer gestion de inventario por club
7. El sistema debe permitir consultar items individuales con todo su detalle
8. El sistema debe exponer historial de cambios para auditoria basica por item

## Decisiones de diseno

- **Autorizacion por permisos + recurso inventario**: usa `PermissionsGuard` con metadata `inventory_instance` o `inventory_item` segun la ruta
- **Namespace propio**: Los endpoints viven bajo `/inventory/` y separan categorias, listados y operaciones por item
- **Soft delete operacional**: `DELETE` marca `club_inventory.active=false`; el item deja de aparecer en listados operativos, pero el registro y su auditoria tecnica permanecen
- **Historial por campo**: cada alta, actualizacion o baja registra cambios en `inventory_history`, accesibles tanto desde el detalle como desde `GET /api/v1/inventory/inventory/:inventoryId/history`

## Gaps y pendientes

- **Typo en PK de categorias**: corregido en schema.prisma; migracion `20260320000000_fix_inventory_category_id_typo` creada y pendiente de deploy en produccion
- **Sin historial de movimientos de negocio**: existe auditoria tecnica de cambios, pero no un kardex/logistica de prestamos, devoluciones o movimientos fisicos
- **Sin fotos**: No hay soporte para adjuntar fotos de los items del inventario
- **Sin prestamos**: No hay modelo para registrar prestamos de equipamiento entre clubes o a unidades
- **Sin vinculacion a actividades**: No se puede asignar equipamiento a una actividad o campamento especifico

## Prioridad y siguiente accion

- **Prioridad**: Media — feature operativa en backend, admin y app; las brechas restantes son logisticas/fotograficas, no de CRUD base
- **Siguiente accion**: Si el negocio lo necesita, extender de auditoria tecnica a movimientos de inventario (prestamos, devoluciones y asignacion a actividades) y deployar la migracion `20260320000000_fix_inventory_category_id_typo` en produccion.
