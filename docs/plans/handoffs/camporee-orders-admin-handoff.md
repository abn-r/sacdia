# Handoff Admin — Pedidos de mercancía de camporee (`camporee-orders`)

> Contrato REAL implementado en `sacdia-backend` (branch `feat/camporee-orders`).
> Prefijo global: `/api/v1`. Envelope de éxito: `{ status: 'success', data }`.
> Todas las rutas requieren Bearer JWT + permisos RBAC.
> Fuente: `sacdia-backend/src/camporee-orders/` y `src/payment-obligations/`.
>
> **Ownership visual:** Task 12 (Composer). Este handoff no diseña pantallas.
> Contratos TypeScript: `sacdia-admin/src/lib/types/camporee-orders.ts`,
> `src/lib/api/camporee-orders.ts`, `src/lib/types/payment-obligations.ts`,
> `src/lib/api/payment-obligations.ts`.

Los pedidos de mercancía **no** son las órdenes de inscripción
`/payment-orders`. No reutilizar `field-payment-orders.ts` ni el tab actual
de inscripción como si fueran el mismo dominio.

## 1) Modelo funcional

El Campo Local o la Unión publica un catálogo territorial (playeras, gorras,
pañoletas, libros). El director de una sección **inscrita** emite uno o más
pedidos nominados (`camporee_member_id` activo `registered|approved`). Cada
pedido tiene folio PED propio, total, comprobante y estado. La inscripción
sigue en `field_payment_orders`. Materiales generales siguen en
`material_orders`. Pagos pendientes **agrega** las tres fuentes sin fusionar
folios.

### Máquina de estados (`status`)

```
ISSUED ──► PROOF_SUBMITTED ──► PAID ──► DELIVERED
  │              │               ▲
  │              └──► PROOF_REJECTED ──► PROOF_SUBMITTED (mismo folio)
  │                        │
  │                        └──► CANCELLED
  ├──► PAID (authorize-without-proof, excepción de caja LF)
  ├──► CANCELLED
  └──► EXPIRED (lazy al pasar expires_at; default 15 días)
```

- Transición inválida → **422** `CAMPOREE_ORDER_INVALID_TRANSITION`.
- Maker-checker: quien subió el comprobante **no** puede aprobarlo → **403**
  `CAMPOREE_ORDER_MAKER_CHECKER`.
- Autorizar sin proof exige `reason` y permiso
  `camporee-orders:authorize-without-proof`. No es el flujo primario.
- Proof documental posterior a la excepción se audita y **no** reabre ni
  cambia `PAID|DELIVERED`.
- Entrega LF → sección: solo desde `PAID` → `DELIVERED`.
- Distribución sección → miembro: solo director, solo con orden `DELIVERED`.
  El admin **visualiza** `distribution_status`; no suplanta al director.

### Settings del camporee

Aparecen en el detalle GET ya existente de camporee local/unión:

- `orders_enabled`
- `orders_opens_at`
- `orders_deadline`

No inventar un GET extra. Extender el tipo `Camporee` (y el equivalente de
unión) con esos tres campos opcionales.

Mutación: `PATCH .../orders-settings`. Ofertas: `GET/PUT .../order-offerings`.

### Permisos

| Permiso | Uso en admin |
|---|---|
| `camporee-orders:read` | listar, detalle, PDF, proof firmado, tab Pedidos, catálogo en lectura |
| `camporee-orders:catalog-manage` | crear/editar productos y tallas (owner exacto) |
| `camporee-orders:offering-configure` | settings y ofertas del camporee que organiza |
| `camporee-orders:create` | emisión (app; el admin no construye el carrito en Task 12) |
| `camporee-orders:upload-proof` | subir comprobante (app; admin puede visualizar) |
| `camporee-orders:review` | bandeja, approve, reject |
| `camporee-orders:authorize-without-proof` | excepción de caja, secundaria |
| `camporee-orders:deliver` | LF marca PAID → DELIVERED |
| `camporee-orders:distribute` | director marca línea al miembro; **admin no lo invoca** |

Constantes: `src/lib/auth/permissions.ts` y `src/lib/types/camporee-orders.ts`.

Alcance: el Campo Local cobra, revisa y entrega aunque el producto sea de
Unión/División. Super-admin (`all`) puede configurar.

## 2) Endpoints (no inventar otros)

### Catálogo territorial

- `POST /camporee-order-products` — `catalog-manage`.
- `GET /camporee-order-products?active=` — `read`. Cascada territorial.
- `GET /camporee-order-products/:productId` — `read`.
- `PATCH /camporee-order-products/:productId` — `catalog-manage`. Owner
  inmutable. Soft-delete con `active: false`.
- `POST /camporee-order-products/:productId/options` — `catalog-manage`.
- `PATCH /camporee-order-product-options/:optionId` — `catalog-manage`.
  `label` inmutable si ya hay líneas de pedido.

### Settings y ofertas (local XOR unión)

- `PATCH /camporees/:id/orders-settings`
- `PATCH /union-camporees/:id/orders-settings`
  Body opcional: `{ orders_enabled?, orders_opens_at?, orders_deadline? }`.
  Timestamps con `Z` u offset explícito.
- `GET /camporees/:id/order-offerings` y equivalente unión.
  `{ settings, items[] }` con `product` anidado.
- `PUT /camporees/:id/order-offerings` y equivalente unión.
  Body `{ items: [{ product_id, price_centavos, active?, sort_order? }] }`.
  Reemplazo idempotente; items omitidos se desactivan. Precio en centavos,
  entero > 0.

### Pedidos

- `GET /camporee-orders?camporee_id=&union_camporee_id=&status=` — `read`.
  **No colapsa** pedidos suplementarios de la misma sección.
- `GET /camporee-orders/review-queue` — `review`. `PROOF_SUBMITTED`.
- `GET /camporee-orders/:orderId` — `read`. Líneas nominadas + `summary` derivado.
- `GET /camporee-orders/:orderId/document` — blob PDF
  (`pedido-<folio>.pdf`).
- `GET /camporee-orders/:orderId/proof` — URL firmada 900s.
- `POST /camporee-orders/:orderId/proof` — multipart campo `file`.
- `POST /camporee-orders/:orderId/cancel` — body opcional `{ reason }`.
- `POST /camporee-orders/:orderId/approve` — sin body.
- `POST /camporee-orders/:orderId/reject` — `{ reason }` obligatorio.
- `POST /camporee-orders/:orderId/authorize-without-proof` — `{ reason }`
  obligatorio.
- `POST /camporee-orders/:orderId/deliver` — LF → sección.
- `POST /camporee-orders/:orderId/lines/:lineId/deliver-to-member` —
  director; el admin **no** lo usa como acción propia.

Emisión (`POST /camporees/:id/orders` y unión) existe en backend y está
tipada en el cliente. Task 12 **no** implementa UI de captura nominada.

### Obligaciones pendientes

- `GET /payment-obligations/pending?camporee_id=&union_camporee_id=`
  Permiso: cualquiera de `camporee-orders:read` |
  `field-payment-orders:read` | `materiales:read`.
  `camporee_id` y `union_camporee_id` son mutuamente excluyentes.

`source`: `CAMPOREE_ORDER` | `FIELD_PAYMENT_ORDER` | `MATERIAL_ORDER`.

## 3) Shape de la orden (respuesta real)

```jsonc
{
  "camporee_order_id": "uuid",
  "local_field_id": 7,
  "club_id": 5,
  "club_section_id": 11,
  "local_camporee_id": 40,          // XOR con union_camporee_id
  "union_camporee_id": null,
  "folio": 1,
  "folio_reference": "PED20260001",
  "status": "ISSUED",               // ver máquina de estados
  "currency": "MXN",
  "total_centavos": 19900,          // servidor; el cliente nunca lo envía
  "expires_at": "…",
  "authorized_without_proof": false,
  "authorization_reason": null,
  "delivered_to_section_at": null,
  "lines": [
    {
      "camporee_order_line_id": "uuid",
      "camporee_member_id": 801,
      "option_id": "uuid-or-null",
      "qty": 1,
      "unit_price_centavos": 19900,
      "line_total_centavos": 19900,
      "delivered_to_member_at": null,
      "product_title_snapshot": "Playera",
      "option_label_snapshot": "M",
      "beneficiary_name_snapshot": "Ana Ruiz"
    }
  ],
  "summary": [                      // derivado, no persistido
    {
      "product_title_snapshot": "Playera",
      "option_label_snapshot": "M",
      "qty": 1,
      "subtotal_centavos": 19900
    }
  ],
  "distribution_status": "NOT_STARTED" // NOT_STARTED | PARTIAL | COMPLETE
}
```

Montos siempre en centavos. `summary` = `SUM(qty)` / `SUM(line_total)` por
producto+talla.

## 4) Errores relevantes para UI

| Código | HTTP | Cuándo |
|---|---|---|
| `CAMPOREE_ORDERS_DISABLED` | 403 | `orders_enabled=false` |
| `CAMPOREE_ORDERS_NOT_OPEN` | 422 | antes de `orders_opens_at` |
| `CAMPOREE_ORDERS_CLOSED` | 422 | después del deadline |
| `CAMPOREE_ORDER_NOT_FOUND` | 404 | pedido/producto inexistente o fuera de cascada |
| `CAMPOREE_ORDER_FORBIDDEN` | 403 | fuera de alcance |
| `CAMPOREE_ORDER_INVALID_TRANSITION` | 422 | transición inválida |
| `CAMPOREE_ORDER_MAKER_CHECKER` | 403 | uploader == approver |
| `CAMPOREE_ORDER_PROOF_NOT_FOUND` | 404 | approve/reject/GET proof sin archivo |
| `CAMPOREE_ORDER_PROOF_INVALID_FILE` | 400 | magic bytes / tipo / tamaño |
| `CAMPOREE_ORDER_REJECT_REASON_REQUIRED` | 400 | reject sin motivo |
| `CAMPOREE_ORDER_AUTHORIZATION_REASON_REQUIRED` | 400 | excepción sin motivo |
| `CAMPOREE_ORDER_PAYMENT_CONFIG_REQUIRED` | 400 | LF sin instrucciones de pago |
| `CAMPOREE_ORDER_OFFERING_INVALID` | 422 | oferta inactiva/duplicada/precio inválido |
| `CAMPOREE_ORDER_OPTION_REQUIRED` | 422 | talla exigida y ausente |
| `CAMPOREE_ORDER_OPTION_FORBIDDEN` | 422 | talla inválida o label histórico |
| `CAMPOREE_ORDER_PRODUCT_SCOPE_INVALID` | 422 | producto fuera de cascada |
| `CAMPOREE_ORDER_MEMBER_NOT_ELIGIBLE` | 422 | no inscrito `registered\|approved` |
| `CAMPOREE_ORDER_NOT_DELIVERED_TO_SECTION` | 422 | distribuir antes de DELIVERED |
| `CAMPOREE_ORDER_DISTRIBUTION_FORBIDDEN` | 403 | no es el director de la sección |
| `CAMPOREE_ORDER_LINE_NOT_FOUND` | 404 | línea ajena |

Shape: `{ status: 'error', code, statusCode, message, details?, timestamp, path }`.

Cliente: `getCamporeeOrderErrorMessage` en `src/lib/api/camporee-orders.ts`
(mismo patrón que `payment-order-errors.ts`). Task 12 puede sustituir los
strings por claves i18n de 4 locales + `messages.d.ts`.

## 5) Alcance UI admin (Task 12)

Rutas a construir (no otras):

1. **`/dashboard/campamentos/pedidos/catalogo`**
   Biblioteca territorial. El actor del owner exacto edita; ancestros ven
   el producto **solo lectura**. Unión/LF no editan un producto de División.
   Super-admin sí. No inventar endpoints de “fork” ni de stock.
2. **`/dashboard/campamentos/pedidos/bandeja`**
   Bandeja primaria: `GET /camporee-orders/review-queue`. Detalle con PDF,
   proof firmado, approve (primario) y authorize-without-proof (secundario:
   motivo obligatorio + confirmación). Reject con motivo. Deliver LF solo
   si `status === PAID`.
3. **Settings en formularios** de camporee local y de unión
   (`camporee-form-dialog.tsx`, `union-camporee-form-dialog.tsx`):
   `orders_enabled`, `orders_opens_at`, `orders_deadline` vía PATCH
   `orders-settings`. Ofertas del evento vía GET/PUT `order-offerings`.
4. **Tab Pedidos** en `camporee-detail-tabs.tsx` (local y unión)
   `GET /camporee-orders?camporee_id=` o `union_camporee_id=`. Listar **todos**
   los folios de la sección/evento. En cada detalle: primero consolidado
   (`summary[]`), después nominado (`lines[]`). No mezclar con el tab de
   órdenes de **inscripción**.
5. **Página Pagos pendientes** (`/dashboard/payment-orders`)
   Sustituir/ampliar a `GET /payment-obligations/pending`. Tres fuentes,
   tres acciones propietarias:
   - `FIELD_PAYMENT_ORDER` → `/dashboard/payment-orders?orderId=`
   - `MATERIAL_ORDER` → `/dashboard/materials/request/:id`
   - `CAMPOREE_ORDER` → `/dashboard/campamentos/pedidos/bandeja?orderId=`
   Nunca fusionar dos `CAMPOREE_ORDER`. No mezclar botones de approve de
   inscripción con deliver de pedido.

Helpers: `paymentObligationDetailPath`, `paymentObligationActionOwner`.

### Entrega en dos niveles

- LF / admin con `deliver`: botón “Entregar a la sección” visible solo en
  `PAID`. Llama `POST .../deliver`.
- Tras `DELIVERED`, mostrar progreso `NOT_STARTED|PARTIAL|COMPLETE` y qué
  líneas tienen `delivered_to_member_at`. **No** llamar
  `deliver-to-member` desde el admin.

### Catálogo territorial (UI)

Usar `isExactCatalogOwner`. Ancestros: badge o estado read-only, sin
PATCH/POST de producto. El listado GET ya trae la cascada.

### Estados de superficie (obligatorio en cada pantalla nueva)

| Estado | Comportamiento |
|---|---|
| loading | skeleton/spinner; no inventar filas |
| empty | copy de vacío (sin pedidos, sin ofertas, bandeja vacía, catálogo vacío) |
| error | toast o banner con `getCamporeeOrderErrorMessage`; no silenciar 403 |
| success | toast breve tras approve/reject/authorize/deliver/guardar settings |

i18n: 4 locales (`es`, `en`, `fr`, `pt-BR`) + regenerar `messages.d.ts`.
Tests vitest de los componentes nuevos (plan Task 12). No ejecutar
`pnpm build`.

### Qué no hacer

- No reutilizar `/payment-orders` para mercancía.
- No impersonar `distribute` / `deliver-to-member`.
- No enviar `unit_price_centavos`, `total_centavos` ni `price_centavos` en
  creación de pedidos (la emisión no es UI admin).
- No fusionar folios PED.
- No tocar `sacdia-backend` ni `sacdia-app`.
- No inventar endpoints, estados o campos.
