# Inventario

**Estado**: PARCIAL

## Descripcion de dominio

El inventario gestiona los bienes materiales de cada club de Conquistadores, Aventureros o Guias Mayores. Los clubes acumulan equipamiento a lo largo de los anos: carpas, utensilios de cocina, herramientas, equipos de sonido, materiales didacticos, banderas, uniformes de respaldo, botiquines, cuerdas, brujulas y todo tipo de insumos para campamentos y actividades.

El control de inventario es critico para la planificacion logistica de campamentos y camporees. Saber que tiene el club, en que estado se encuentra y que cantidad hay disponible evita gastos innecesarios y permite una distribucion equitativa de recursos entre unidades. El inventario esta categorizado mediante un catalogo compartido (`inventory_categories`) que estandariza la clasificacion entre clubes.

Cada item del inventario pertenece a un club especifico y tiene campos para nombre, descripcion, cantidad, estado/condicion y categoria. El sistema soporta filtrado por categoria para facilitar la busqueda de items especificos.

## Que existe (verificado contra codigo)

### Backend (InventoryModule)
- **Controller**: `src/inventory/inventory.controller.ts`
- **Service**: `src/inventory/inventory.service.ts`
- **Guards**: JwtAuthGuard, PermissionsGuard
- **6 endpoints**:
  - `GET /api/v1/inventory/catalogs/inventory-categories` — Listar categorias de inventario
  - `GET /api/v1/inventory/clubs/:clubId/inventory` — Listar items del inventario de un club
  - `POST /api/v1/inventory/clubs/:clubId/inventory` — Agregar nuevo item al inventario
  - `GET /api/v1/inventory/inventory/:id` — Obtener detalles de un item
  - `PATCH /api/v1/inventory/inventory/:id` — Actualizar un item
  - `DELETE /api/v1/inventory/inventory/:id` — Eliminar un item

### Admin
- **Placeholder** — Redirige a seleccionar club. No consume endpoints. Sin funcionalidad real.

### App Movil
- **4 screens**: InventoryView, InventoryItemDetailView, AddInventoryItemSheet, InventoryFilterSheet
- Consume los 6 endpoints del backend
- CRUD completo desde la app
- Incluye filtrado por categorias

### Base de datos
- `club_inventory` — Items del inventario por club
- `inventory_categories` — Catalogo de categorias de inventario
- **Nota**: `inventory_categories` tiene un typo en el PK: `inventory_categoty_id` (falta la 'r' en category)

## Requisitos funcionales

1. Cada club debe poder registrar items de inventario con nombre, descripcion, cantidad, condicion y categoria
2. El inventario debe ser consultable por club con filtros por categoria
3. Los items deben poder actualizarse para reflejar cambios de estado, cantidad o ubicacion
4. Los items deben poder eliminarse cuando se dan de baja
5. Las categorias de inventario deben ser un catalogo compartido y gestionable
6. El panel admin debe ofrecer gestion de inventario por club (actualmente placeholder)
7. El sistema debe permitir consultar items individuales con todo su detalle

## Decisiones de diseno

- **Autorizacion por permisos**: A diferencia de actividades y finanzas que usan `ClubRolesGuard`, inventario usa solo `PermissionsGuard` sin restriccion de roles de club especificos
- **Namespace propio**: Los endpoints de inventario viven bajo `/inventory/` como prefijo, no directamente bajo `/clubs/`, separando la logica de inventario del modulo de clubs
- **Categorias con endpoint dedicado**: Las categorias de inventario tienen su propio endpoint dentro del namespace de inventario (`/inventory/catalogs/inventory-categories`), no en el modulo general de catalogos
- **Sin soft delete**: A diferencia de otros modulos, el `DELETE` de inventario parece ser hard delete (no hay campo `active` verificado en el controller)

## Gaps y pendientes

- **Admin es placeholder**: Backend y app completos pero el panel admin no tiene UI funcional
- **Typo en PK de categorias**: `inventory_categoty_id` deberia ser `inventory_category_id` — pendiente de migracion
- **Sin historial de movimientos**: No hay tracking de cuando se agrego, retiro o movio un item (solo estado actual)
- **Sin fotos**: No hay soporte para adjuntar fotos de los items del inventario
- **Sin prestamos**: No hay modelo para registrar prestamos de equipamiento entre clubes o a unidades
- **Sin vinculacion a actividades**: No se puede asignar equipamiento a una actividad o campamento especifico

## Prioridad y siguiente accion

- **Prioridad**: Media — backend y app funcionales; admin es el gap principal
- **Siguiente accion**: Implementar UI de inventario en sacdia-admin consumiendo los 6 endpoints existentes. Corregir el typo en `inventory_categoty_id` mediante migracion Prisma.
