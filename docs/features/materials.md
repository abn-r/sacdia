# Materiales (tienda del Campo Local)

**Estado**: IMPLEMENTADO
**Verificado contra código**: 2026-10-04 (rama `development`); sección de la app móvil, 2026-11-19

## Descripcion de dominio

Materiales permite que cada Campo Local publique un catálogo de productos (uniformes, insignias, material de clase) y que los directivos de sección hagan pedidos. El Campo Local revisa la disponibilidad de cada línea, aprueba el pedido, valida el comprobante de pago y marca la entrega. Todo el dinero se maneja en centavos enteros (`*_centavos`).

## Que existe (verificado contra codigo)

### Backend (`src/materials/`)

Submódulos: `catalog`, `categories`, `config`, `inventory`, `orders`, `receipts` y `shared`. Todos los controllers usan `JwtAuthGuard` + `PermissionsGuard` con `AuthorizationResource({ type: 'active_assignment' })`. Los códigos de permiso están en `src/materials/shared/permissions.ts` y usan el prefijo `materiales:`.

| Método | Ruta (`/api/v1`) | Permiso |
|---|---|---|
| GET | `/materials/catalog/categories` | `materiales:read` |
| GET | `/materials/catalog/programs` (tipos de club) | `materiales:read` |
| GET | `/materials/catalog` (paginado, acotado al Campo Local) | `materiales:read` |
| GET | `/materials/catalog/:id` | `materiales:read` |
| GET / POST | `/materials/categories` | `materiales:manage-inventory` |
| PATCH / DELETE | `/materials/categories/:id` | `materiales:manage-inventory` |
| GET | `/materials/config` (config del Campo Local del actor) | `materiales:read` |
| GET | `/materials/config/all` | `materiales:configure` |
| PATCH | `/materials/config` | `materiales:configure` |
| PATCH | `/materials/config/:localFieldId` | `materiales:configure` |
| GET / POST | `/materials/inventory` | `materiales:manage-inventory` |
| PATCH / DELETE | `/materials/inventory/:id` (DELETE = `active=false`) | `materiales:manage-inventory` |
| PATCH | `/materials/inventory/:id/variants/:variantId` (stock por variante) | `materiales:manage-inventory` |
| POST | `/materials/orders` | `materiales:create` |
| GET | `/materials/orders/history` (solo pedidos propios) | `materiales:read` |
| GET | `/materials/orders` | `materiales:read` |
| GET | `/materials/orders/:folio` | `materiales:read` |
| PATCH | `/materials/orders/:folio/lines/:lineId` | `materiales:approve` |
| POST | `/materials/orders/:folio/approve` | `materiales:approve` |
| POST | `/materials/orders/:folio/cancel` | `materiales:read` (el servicio decide, ver reglas) |
| POST | `/materials/orders/:folio/deliver` | `materiales:deliver` |
| POST | `/materials/receipts/:folio` (multipart) | `materiales:upload-receipt` |
| POST | `/materials/receipts/:folio/approve` | `materiales:validate-receipt` |
| POST | `/materials/receipts/:folio/reject` | `materiales:validate-receipt` |
| GET | `/materials/receipts/:folio` (URLs firmadas) | `materiales:read` |

`:folio` acepta el folio (`SOL…`) o el UUID del pedido.

### Reglas verificadas

- **Máquina de estados** (`orders/state-machine.ts`): `en_revision → aprobada | cancelada`, `aprobada → pagada | cancelada`, `pagada → entregada | cancelada`; `entregada` y `cancelada` son terminales. Una transición inválida responde 422 `state_machine_violation`.
- **Creación**: al menos una línea; productos activos del Campo Local de la sección (`club_sections → clubs.local_field_id`). El precio se toma del producto (la variante no tiene precio). Las líneas nacen con `disponibilidad = pendiente`.
- **Folio**: se asigna al crear el pedido (`FolioService.allocate` dentro de la transacción de `createOrder`). Formato `SOL{año}{0001}`, contador por `(local_field_id, year)` en `material_folio_counters` con `SELECT … FOR UPDATE`; el año se calcula en `America/Mexico_City`. Dos Campos Locales pueden tener el mismo folio.
- **Revisión de líneas**: solo en `en_revision` (si no, 422 `lines_frozen`). `disponible` fija `qty_disponible = qty`; `agotado` fija 0; `parcial` exige `qty_disponible` entre 1 y `qty`. El total de la línea se recalcula con `qty_disponible`.
- **Aprobación**: falla con 422 `unresolved_lines` si queda alguna línea `pendiente`. En una transacción descuenta stock (409 `insufficient_stock` si no alcanza), recalcula totales con el envío por defecto y copia en el pedido los datos bancarios y la dirección de recogida de `material_config` (snapshot).
- **Cancelación**: en `en_revision` puede cancelar el creador o quien tenga `materiales:approve`; en `aprobada` o `pagada` solo `materiales:approve` (403 `cancel_forbidden`). Si el pedido ya había descontado stock, se restaura. Cancelar un pedido `pagada` marca `refund_pending = true`.
- **Comprobante**: solo se sube con el pedido en `aprobada`. PDF, JPEG o PNG, máximo 10 MB, con validación de *magic bytes* (`receipt-file-validation.pipe.ts`); se guarda en R2. Aprobar exige comprobante `pendiente` y que no exista otro `aprobado` (409 `already_approved_comprobante`); pasa el pedido a `pagada`. Rechazar deja el pedido en `aprobada`.
- **Entrega**: solo desde `pagada`.
- **Configuración**: `bank_account_clabe` debe tener 18 dígitos; `envio_centavos_default >= 0`.
- **Eventos**: `EventsPublisher` solo escribe logs estructurados (`order.created`, `order.approved`, `order.cancelled`, `order.paid`, `comprobante.validated`…); no envía notificaciones.
- **Alcance territorial**: `resolveActorLocalField` resuelve el ámbito del actor (Campo Local, unión, división o todo); sin ámbito configurado responde `ADMIN_USER_SCOPE_MISSING`.

### Admin (`sacdia-admin/src/app/(dashboard)/dashboard/materials/`)

- `/dashboard/materials` redirige a `/dashboard/materials/inbox` (bandeja de pedidos).
- `/dashboard/materials/request/[folio]`: detalle y revisión del pedido.
- `/dashboard/materials/receipts` y `/receipts/[folio]`: validación de comprobantes.
- `/dashboard/materials/inventory` y `/categories`: productos, variantes y categorías.
- `/dashboard/materials/config` es una ruta heredada: redirige a `/dashboard/configuration/local-field/payment-methods`. La entrega (envío y recogida) se configura en `/dashboard/configuration/local-field/delivery`.

### App móvil (`sacdia-app/lib/features/materials/`)

**Verificado contra código**: 2026-11-19 (`development`; rediseño en sacdia-app #263, ajustes en #267, #268 y #269, y el panel de estado compartido de #261). La app solo cubre al club que pide: no revisa líneas, no aprueba, no valida comprobantes ni entrega (eso es del admin).

**Rutas** (`lib/core/config/route_names.dart`, `router.dart`)

| Ruta | Pantalla |
|---|---|
| `/home/materials` | `OrderHistoryView`: «Pedidos» (entrada del módulo desde el inicio) |
| `/home/materials/catalog` | `CatalogView`: «Nuevo pedido» (push fuera del shell) |
| `/home/materials/cart` | `CartView`: «Tu pedido» (carrito y confirmación en una pantalla) |
| `/home/materials/order/:folio` | `OrderReviewView`: detalle del pedido por folio o UUID |
| `/home/materials/order/:folio/receipt` | `UploadReceiptView`: subir comprobante |
| `/home/materials/product/:id` | enlace antiguo: abre el catálogo con la hoja de ese producto |
| `/home/materials/order/:folio/payment` | enlace antiguo: abre el detalle del pedido con la hoja de pago (solo si el pedido está `aprobada`) |
| `/home/materials/summary` | redirige a `/home/materials/cart` |
| `/home/materials/history` | redirige a `/home/materials` |

**Pedidos (`OrderHistoryView`)**: `GET /materials/orders/history`. Los pedidos se agrupan (`groupOrders`, más nuevo primero en cada grupo) en «Por atender», «En curso», «Entregados» y «Cancelados»; un grupo vacío no se dibuja.
- «Por atender»: pedidos `aprobada` a los que el club debe responder: sin comprobante (pagar) o con el último comprobante `rechazado` (subir otro).
- «En curso»: `en_revision`, `pagada`, y `aprobada` con comprobante pendiente o aprobado (esperando al campo local).
- Cada fila muestra miniaturas apiladas, icono y texto de estado, el folio completo en monoespaciada y el monto. Pie fijo «Nuevo pedido» (`SacFrostedFooter`). Estados de esqueleto, vacío y error con reintento; *pull-to-refresh*.

**Catálogo (`CatalogView`)**: búsqueda, filtro por programa (tipo de club), filtro por categoría, paginación con «Cargar más» e icono de carrito. Tocar un producto abre `ProductSizesSheet`:
- Productos con variante: un paso de cantidad por talla o color. Muestra «Quedan N» (en color de advertencia con 3 o menos, `kLowStockThreshold = 3`) y «Agotada» sin selector cuando el stock es 0. Productos sin variante: un solo selector de piezas.
- El botón «Agregar N · $total» agrega todas las opciones elegidas de una vez y muestra un aviso «Se agregó … · Ver carrito».
- El carrito vive en memoria (`cartProvider`); cada línea guarda el precio del momento y la opción de variante.

**Tu pedido (`CartView`)**: productos, dos tarjetas de entrega (recoger en el campo local, o envío al club con su costo), notas opcionales, totales y botón fijo «Confirmar pedido · $total». Las opciones de entrega salen de `GET /materials/config` (`deliveryOptions`); sin configuración muestra recoger y envío. Con envío gratis el texto es «Sin costo» y no «$0.00». Al confirmar (`POST /materials/orders`) vacía el carrito, vuelve a la lista y muestra «Pedido {folio} enviado · Ver pedido». Al abrir esta pantalla se descarta el aviso «Ver carrito» del catálogo (#268).

**Detalle del pedido (`OrderReviewView`)**
- Arriba, `SacStatePanel` con el estado actual y «Paso N de 4». Al tocarlo se abre `showSacStatesSheet` con los 4 pasos: En revisión, Aprobado: falta pagar, Pagado: lo preparan y Entregado. Un pedido cancelado no tiene número de paso.
- Si el último comprobante fue rechazado, el panel pasa a «Comprobante rechazado» y se cita el `reject_reason` del revisor bajo el título «Motivo del campo local».
- Secciones: productos (cantidad × precio), totales (productos, entrega con «Sin costo» si es 0, total) y comprobantes, cuando hay.
- Una sola acción fija abajo según el estado: «Pagar $total» (pedido `aprobada` sin comprobante) o «Subir otro comprobante» (último comprobante rechazado). En los demás estados no hay acción.
- El menú ⋯ ofrece copiar el folio y, solo con el pedido `en_revision`, «Cancelar pedido» (último, en rojo), que pide un motivo obligatorio (`POST /materials/orders/:folio/cancel`). La app no ofrece cancelar `aprobada` ni `pagada`, aunque el backend lo permita a quien tiene `materiales:approve`.
- Los comprobantes ya guardados con un nombre generado (`image_picker_*`, `scaled_*`, un UUID suelto o vacío) se muestran como «Comprobante» o «Comprobante N» (`materials.receipts.default_name`, `receiptDisplayName`). Los nombres reales se muestran tal cual.

**Pago (`PaymentSheet`)**: hoja con el monto en grande, banco, CLABE, beneficiario y concepto (el folio), tomados del snapshot de datos bancarios que el backend copia al aprobar. Las filas de CLABE, beneficiario y concepto tienen botón de copiar de 44 pt; al copiar, el icono cambia a una marca durante 1.5 s dentro de la fila (sin animación con movimiento reducido) y los lectores de pantalla reciben «Copiado: …» como región viva. No se usa un *snackbar* porque quedaba detrás de la hoja (#269). «Ya pagué · subir comprobante» cierra la hoja y abre la pantalla de comprobante.

**Subir comprobante (`UploadReceiptView`)**: el monto llega prellenado con el total del pedido (editable; debe ser mayor a 0), la fecha es hoy (no admite futuras) y el concepto es el folio. El archivo se elige con una hoja Cámara, Galería o Archivo; PDF, JPG o PNG de hasta 10 MB (`_maxFileSizeBytes`). Muestra tarjeta de vista previa con «Cambiar archivo» y los errores junto al campo. Envía `monto_centavos`, `ref_bancaria_declarada` (el folio) y `fecha_pago`. Las fotos de cámara o galería se suben como `comprobante-<folio>.<ext>` (`friendlyReceiptUploadName`, sin caracteres fuera de letras, números, `_` y `-`); un archivo elegido con «Archivo» conserva su nombre.

**Flujo verificado de punta a punta** (iOS contra backend local, 2026-11-18/19): crear pedido; el admin resuelve la disponibilidad de cada línea (`PATCH /materials/orders/:folio/lines/:lineId`; sin eso `approve` responde `422 unresolved_lines`); `POST .../approve`; la app muestra «Pagar» y la hoja de pago; se sube el comprobante; el admin lo rechaza con motivo (la app lo muestra como «Motivo del campo local»); se sube otro; el admin lo aprueba; la app muestra «Pagado: lo preparan».

### Base de datos

`material_categories` (globales), `material_products` (por Campo Local, `UNIQUE (local_field_id, sku)`), `material_variants` (una por producto; `talla` o `color`), `material_variant_options` (stock por opción), `material_orders`, `material_order_lines`, `material_comprobantes`, `material_folio_counters` y `material_config` (PK `local_field_id`). Enums: `MaterialOrderEstado`, `MaterialDisponibilidad`, `MaterialComprobanteStatus`, `MaterialVariantType`, `MaterialEntrega` (`recoger`, `envio`).

## Relacion con otros dominios

- `GET /api/v1/payment-obligations/pending` incluye pedidos de materiales (ver [ordenes-de-pago.md](ordenes-de-pago.md)).

## Gaps y pendientes

- La descripción Swagger de `POST /materials/orders/:folio/approve` dice que asigna el folio, pero el folio se asigna al crear el pedido.
- No hay notificaciones push ni correo en los cambios de estado; solo logs.
- `refund_pending` se marca, pero no existe flujo de reembolso.
- La app solo permite cancelar pedidos `en_revision`; el backend admite cancelar también `aprobada` y `pagada` con `materiales:approve`.
- El modelo de estados de la app tiene 4 pasos (en revisión, aprobado, pagado, entregado), sin un paso aparte para el comprobante pendiente de validación: un pedido `aprobada` con comprobante pendiente se muestra como «Revisando tu pago» dentro del paso 2.
