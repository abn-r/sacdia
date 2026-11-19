# Inventario

**Estado**: IMPLEMENTADO
**Actualizado**: 2026-11-19 (sección de la app móvil verificada contra `development`)

## Descripcion de dominio

El inventario gestiona los bienes materiales de cada club de Conquistadores, Aventureros o Guias Mayores. Los clubes acumulan equipamiento a lo largo de los anos: carpas, utensilios de cocina, herramientas, equipos de sonido, materiales didacticos, banderas, uniformes de respaldo, botiquines, cuerdas, brujulas y todo tipo de insumos para campamentos y actividades.

El control de inventario es critico para la planificacion logistica de campamentos y camporees. Saber que tiene el club, en que estado se encuentra y que cantidad hay disponible evita gastos innecesarios y permite una distribucion equitativa de recursos entre unidades. El inventario esta categorizado mediante un catalogo compartido (`inventory_categories`) que estandariza la clasificacion entre clubes.

Cada item del inventario pertenece a una instancia/seccion operativa de club (`club_section_id`) y tiene campos para nombre, descripcion, cantidad, categoria y, desde la migracion `20261026130000_inventory_extended_fields`, condicion y datos de control (numero de serie, fecha de compra, valor estimado, ubicacion, responsable y notas). El sistema soporta filtrado por categoria para facilitar la busqueda de items especificos y adjuntar fotos de evidencia del articulo.

## Que existe (verificado contra codigo)

### Backend (InventoryModule)
- **Controller**: `src/inventory/inventory.controller.ts`
- **Service**: `src/inventory/inventory.service.ts`
- **Guards**: JwtAuthGuard, PermissionsGuard
- **8 endpoints**:
  - `GET /api/v1/inventory/catalogs/inventory-categories` — Listar categorias de inventario
  - `GET /api/v1/inventory/clubs/:clubId/inventory` — Listar items del inventario de una instancia de club
  - `POST /api/v1/inventory/clubs/:clubId/inventory` — Agregar nuevo item al inventario
  - `GET /api/v1/inventory/inventory/:id` — Obtener detalles de un item
  - `GET /api/v1/inventory/inventory/:inventoryId/history` — Obtener historial de cambios del item
  - `PATCH /api/v1/inventory/inventory/:id` — Actualizar un item
  - `POST /api/v1/inventory/inventory/:id/evidences` — Subir foto de evidencia del item (JPEG/PNG/WebP, maximo 3 activas)
  - `DELETE /api/v1/inventory/inventory/:id` — Eliminar logicamente un item (`active=false`)

### Admin
- **UI funcional en `/dashboard/inventory`**
  - selector de club
  - filtro por categoria
  - tabla de items
  - dialogos de alta/edicion/eliminacion
  - dialogo de historial por item
- Consume categorias, listado, alta, edicion, eliminacion logica e historial
- Campos extendidos (admin, ya en `development`, commit `36b8186b`): dialogo de alta/edicion en 2 pasos con los campos extendidos (al editar, un campo vaciado se envia como `null`), columna de condicion con badge en la tabla, dialogo de detalle de solo lectura y etiquetas de los campos nuevos en el historial (i18n es/en/fr/pt-BR)

### App Movil

**Actualizado**: 2026-11-19 (`development`; rediseño en sacdia-app #262 y ajustes en #267). Código en `lib/features/inventory/`. Ruta `/home/inventory` (`RouteNames.homeInventory`), sin pantallas hijas en el router: el detalle se abre con `Navigator.push` y el resto son hojas.

**Permisos en la app**: `canManageInventoryProvider` es verdadero con cualquiera de `inventory:create`, `inventory:update` o `inventory:delete`. Sin ellos la app es de solo lectura: no hay botón «Agregar artículo», ni menú ⋯ en las filas, ni menú en el detalle.

**Lista (`InventoryView`)**
- Barra superior solo con el título; se actualiza con *pull-to-refresh*.
- Búsqueda por nombre o descripción y botón de filtros con un contador de filtros activos de la hoja (categorías marcadas, más uno si el orden no es el predeterminado). La búsqueda y el estado no cuentan en ese número.
- Chips de estado (Todos, Bueno, Regular, Malo) con conteo. El conteo de cada chip respeta la búsqueda y las categorías activas, pero no el propio estado. Los chips se ocultan si el club no tiene ningún artículo; un filtro que da cero resultados sí los mantiene.
- Pastillas removibles para las categorías marcadas y para un orden distinto al predeterminado, más «Limpiar».
- Artículos agrupados por categoría (grupos de la A a la Z; dentro de cada grupo, el orden elegido). Cada fila muestra foto de 46 px o un recuadro con icono, el nombre completo y «Estado · N piezas · Ubicación».
- El botón ⋯ de la fila abre una hoja con Ver, Editar, Cambiar estado (subhoja con bueno, regular, malo) y Eliminar (al final, en rojo, con confirmación). No hay acciones por deslizamiento.
- Pie fijo con efecto esmerilado «Agregar artículo» (solo con permiso y con al menos un artículo). Estados: esqueleto agrupado, vacío (icono de caja; con acción «Agregar el primer artículo» si hay permiso), sin resultados de búsqueda o filtro, y error con reintento.

**Filtros (`InventoryFilterSheet`)**: orden de selección única (nombre A-Z o Z-A, más nuevos, más antiguos, mayor valor) y categorías con casillas de selección múltiple (`InventoryFilters.categoryIds`, un `Set<int>`). Las categorías y sus conteos se derivan de los artículos ya cargados, no del catálogo del servidor, y una categoría marcada sigue visible aunque su conteo llegue a cero. El estado no está en la hoja. El botón «Ver N artículos» es en vivo; no hay «Aplicar». Los filtros se aplican en el cliente sobre la lista completa y se pierden al salir de la pantalla (`autoDispose`).

**Detalle (`InventoryItemDetailView`)**: el título es el nombre del artículo. Con permiso, un menú ⋯ ofrece Editar, Cambiar estado y Eliminar. Carrusel de fotos de 210 px (`PageView`) con contador «1 / N», o un recuadro tintado si no hay fotos. Muestra una sola insignia de condición, «N piezas · valor total $X» y grupos etiqueta-valor; un valor no registrado se lee «Sin registrar». Muestra el tipo de club humano (Conquistadores, Aventureros o Guias Mayores) en lugar del `club_section_id` técnico y separa autor y fechas de auditoría en filas independientes.

**Alta y edición (`showInventoryItemForm`)**: una sola hoja a pantalla completa (no es una ruta; arrastrar para cerrar está desactivado y cerrar pasa por una confirmación de descarte si hay cambios). Orden: fotos, nombre, categoría (hoja de selección), cantidad (paso de 1 a 9 999) y condición (3 opciones), más un grupo plegable «Más detalles» con número de serie, fecha de compra, valor estimado, ubicación y notas. El botón de guardar queda fijo abajo.
- Al crear, exige al menos una foto; el máximo es 3 fotos activas entre las existentes y las nuevas (`kInventoryMaxPhotos = 3`). Las fotos se suben después de guardar el artículo.
- Al editar envía el estado completo, con `null` en los campos opcionales que el usuario vació. `description` y `assigned_to` ya no están en el formulario, pero la app los reenvía sin cambios al editar para que el `PATCH` no los borre.
- `purchase_date` se lee como fecha de calendario (`YYYY-MM-DD`), sin conversión de zona horaria; no admite fechas futuras en el selector.
- Las categorías del formulario salen de `GET /inventory/catalogs/inventory-categories`. Si falla, la fila de categoría muestra el motivo (permiso, red u otro) y un botón de reintento.

**Lectura defensiva**: `InventoryRemoteDataSource._extractList` acepta la lista suelta o envuelta en `data`/`items`, y los proveedores lanzan el fallo original en vez de uno genérico. Esto endurece el error «No se pudieron cargar las categorías» observado durante el rediseño, cuya causa raíz no se confirmó (no se reprodujo sin una sesión autenticada).

### Base de datos
- `club_inventory` — Items del inventario por club/seccion, con `active` para soft delete. Campos extendidos (migracion `20261026130000_inventory_extended_fields`, aditiva): `condition`, `serial_number`, `purchase_date`, `estimated_value`, `location`, `assigned_to`, `notes` (detalle en la seccion siguiente y en `docs/database/SCHEMA-REFERENCE.md`)
- `inventory_categories` — Catalogo de categorias de inventario
- `inventory_evidence_files` — Fotos de evidencia por item, con limite operativo de 3 archivos activos
- `inventory_history` — Historial de cambios por campo/accion (`CREATE`, `UPDATE`, `DELETE`)
- **Nota**: `inventory_categories` tenia un typo en el PK (`inventory_categoty_id`). Corregido en schema.prisma; migracion `20260320000000_fix_inventory_category_id_typo`.

### Campos extendidos del item

> Backend: ya en `development` (commit `bddc3557`). La migracion esta aplicada en Neon `development` y `staging`. Para `production`, `docs/deployment/DEPLOYMENT-GUIDE.md` §0.7 la marca pendiente y `docs/database/SCHEMA-REFERENCE.md` la marca aplicada (2026-11-09); los dos documentos no coinciden y no se verifico contra la base.

`POST /api/v1/inventory/clubs/:clubId/inventory` y `PATCH /api/v1/inventory/inventory/:id` aceptan, ademas de nombre, descripcion, categoria y cantidad, siete campos opcionales:

| Campo | Tipo | Regla |
|---|---|---|
| `condition` | string | `bueno` (default), `regular` o `malo`. No acepta `null` |
| `serial_number` | string o null | Maximo 100 caracteres |
| `purchase_date` | string o null | `YYYY-MM-DD` valida |
| `estimated_value` | numero o null | >= 0, hasta 2 decimales, maximo 9 999 999 999.99 |
| `location` | string o null | Maximo 150 caracteres |
| `assigned_to` | string o null | Texto libre con el nombre del responsable; maximo 150 caracteres. No es una FK a usuarios |
| `notes` | string o null | Maximo 2000 caracteres |

- Los textos se recortan (`trim`); una cadena vacia se guarda como `null`.
- **PATCH**: omitir un campo lo deja sin cambios; enviar `null` lo limpia (salvo `condition`, que es NOT NULL).
- **POST**: los campos omitidos quedan en `null` y `condition` toma `bueno`. Los items existentes antes de la migracion quedan con `condition = 'bueno'` y el resto en `null`, sin backfill.
- Listado, detalle, alta y edicion devuelven los siete campos. `estimated_value` sale como numero JSON (la columna es `DECIMAL(12,2)`) y `purchase_date` como `YYYY-MM-DD`.
- La base impone la regla con dos CHECK: `club_inventory_condition_check` y `club_inventory_estimated_value_check`.
- **Historial**: el `UPDATE` registra un renglon en `inventory_history` por cada campo extendido que cambia de verdad (comparando valor anterior y nuevo; `estimated_value` se guarda como texto). El `CREATE` sigue registrando solo `name` y `amount`; los campos extendidos del alta no generan renglones de historial.

### Contrato de instancia de club

Aunque el path historico conserva el nombre `:clubId`, los endpoints `GET/POST /api/v1/inventory/clubs/:clubId/inventory` reciben el identificador de la instancia/seccion operativa (`club_sections.club_section_id`). Los registros creados se persisten en `club_inventory.club_section_id` y el listado filtra por ese mismo campo.

## Requisitos funcionales

1. Cada club debe poder registrar items de inventario con nombre, descripcion, cantidad, condicion (`bueno`, `regular` o `malo`), categoria y datos de control opcionales (serie, fecha de compra, valor estimado, ubicacion, responsable, notas)
2. El inventario debe ser consultable por club con filtros por categoria
3. Los items deben poder actualizarse para reflejar cambios de descripcion, cantidad, categoria, condicion o datos de control
4. Los items deben poder darse de baja mediante desactivacion logica del registro operativo
5. Las categorias de inventario deben ser un catalogo compartido y gestionable
6. El panel admin debe ofrecer gestion de inventario por club
7. El sistema debe permitir consultar items individuales con todo su detalle
8. El sistema debe exponer historial de cambios para auditoria basica por item
9. Cada item puede adjuntar de 1 a 3 fotos de evidencia del articulo; la app exige al menos una foto al crear un nuevo registro

## Decisiones de diseno

- **Autorizacion por permisos + recurso inventario**: usa `PermissionsGuard` con metadata `inventory_instance` o `inventory_item` segun la ruta
- **Namespace propio**: Los endpoints viven bajo `/inventory/` y separan categorias, listados y operaciones por item
- **Soft delete operacional**: `DELETE` marca `club_inventory.active=false`; el item deja de aparecer en listados operativos, pero el registro y su auditoria tecnica permanecen
- **Historial por campo**: cada alta, actualizacion o baja registra cambios en `inventory_history`, accesibles tanto desde el detalle como desde `GET /api/v1/inventory/inventory/:inventoryId/history`
- **Auditoria visible**: el detalle del item deriva `created_by`/`created_by_name` desde el primer evento `CREATE` de `inventory_history.performed_by`, para mostrar el usuario real que registro el articulo. Si el usuario tiene foto, la API agrega `avatar_url` firmado; si no, la app mantiene el icono de usuario.
- **Evidencias fotograficas**: las fotos se guardan en almacenamiento privado (`EVIDENCE_FILES`) y la API devuelve URLs firmadas de corta duracion para consumo en app/admin

## Gaps y pendientes

- **Sin historial de movimientos de negocio**: existe auditoria tecnica de cambios, pero no un kardex/logistica de prestamos, devoluciones o movimientos fisicos
- **Sin prestamos**: No hay modelo para registrar prestamos de equipamiento entre clubes o a unidades
- **Sin vinculacion a actividades**: No se puede asignar equipamiento a una actividad o campamento especifico

## Prioridad y siguiente accion

- **Prioridad**: Media — feature operativa en backend, admin y app; las brechas restantes son logisticas/fotograficas, no de CRUD base
- **Siguiente accion**: Si el negocio lo necesita, extender de auditoria tecnica a movimientos de inventario (prestamos, devoluciones y asignacion a actividades).
