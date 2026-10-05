# Materiales (tienda del Campo Local)

**Estado**: IMPLEMENTADO
**Verificado contra código**: 2026-10-04 (rama `development`)

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

Vistas: `catalog_view`, `product_detail_view`, `cart_view`, `order_review_view`, `order_summary_view`, `payment_details_view`, `upload_receipt_view` y `order_history_view`.

### Base de datos

`material_categories` (globales), `material_products` (por Campo Local, `UNIQUE (local_field_id, sku)`), `material_variants` (una por producto; `talla` o `color`), `material_variant_options` (stock por opción), `material_orders`, `material_order_lines`, `material_comprobantes`, `material_folio_counters` y `material_config` (PK `local_field_id`). Enums: `MaterialOrderEstado`, `MaterialDisponibilidad`, `MaterialComprobanteStatus`, `MaterialVariantType`, `MaterialEntrega` (`recoger`, `envio`).

## Relacion con otros dominios

- `GET /api/v1/payment-obligations/pending` incluye pedidos de materiales (ver [ordenes-de-pago.md](ordenes-de-pago.md)).

## Gaps y pendientes

- La descripción Swagger de `POST /materials/orders/:folio/approve` dice que asigna el folio, pero el folio se asigna al crear el pedido.
- No hay notificaciones push ni correo en los cambios de estado; solo logs.
- `refund_pending` se marca, pero no existe flujo de reembolso.
