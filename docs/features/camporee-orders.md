# Feature: Pedidos de camporee

**Estado**: EN IMPLEMENTACIÓN / PLANNED
**Fecha**: 2026-08-24
**Módulo backend previsto**: `CamporeeOrdersModule` (`src/camporee-orders/`) — aún no existe en runtime
**Plan canónico**: [`docs/plans/2026-08-24-pedidos-camporees-consolidado-codex.md`](../plans/2026-08-24-pedidos-camporees-consolidado-codex.md)
**ADR**: [#9 — Bounded context `camporee-orders`](../api/ARCHITECTURE-DECISIONS.md#9-bounded-context-camporee-orders-independiente-de-materials-y-fieldpaymentorders)

---

## Descripción

Permite que una sección **inscrita** en un campamento o camporee (local o de unión) emita uno o más pedidos globales de artículos (playeras, gorras, pañoletas, libros, materiales) asignados a miembros inscritos, pague y compruebe cada obligación **por separado de la inscripción**, y dé seguimiento hasta la distribución por miembro.

El dominio es un bounded context independiente. Reutiliza patrones (folio, máquina de estados, proof privado, PDF, alcance territorial, caja/banco del campo local) de Materials y Field Payment Orders **sin extender** sus tablas, purposes ni permisos.

No está implementado en backend, admin ni app. Los contratos HTTP de este documento son **PLANNED**. No pertenecen a `docs/api/ENDPOINTS-LIVE-REFERENCE.md` hasta que existan en runtime verificado.

---

## Requisitos EARS

### Elegibilidad — solo inscritos

1. **WHEN** un emisor autorizado crea un pedido con líneas
   **THE SYSTEM SHALL** exigir que cada línea referencie un `camporee_member_id` (nunca un `user_id` libre como autoridad) y rechazar el pedido completo si alguna línea no cumple elegibilidad.

2. **WHEN** el sistema valida un `camporee_member_id` de línea
   **THE SYSTEM SHALL** afirmar que el miembro está `active = true`, con estado `registered` o `approved`, pertenece a la misma sección emisora (`camporee_club.club_section_id` = sección activa del actor) y al mismo camporee de la ruta (`local_camporee_id` XOR `union_camporee_id`).

3. **IF** el cliente envía `user_id`, montos, `club_id`, `club_section_id` o `local_field_id` como autoridad de elegibilidad o cobro
   **THEN THE SYSTEM SHALL** ignorarlos como autoridad (el servidor deriva club, sección y campo local) y, si se pretendía sustituir `camporee_member_id`, responder `CAMPOREE_ORDER_MEMBER_NOT_ELIGIBLE`.

4. **WHEN** el miembro está `pending_approval`, rechazado, inactivo, de otra sección o de otro camporee
   **THE SYSTEM SHALL** rechazar la emisión con `CAMPOREE_ORDER_MEMBER_NOT_ELIGIBLE`.

5. **WHEN** el camporee es de unión
   **THE SYSTEM SHALL** exigir además que el campo local de la sección participe de forma activa en `union_camporee_local_fields`.

### Pago separado de la inscripción

6. **WHILE** existan inscripción y pedidos para la misma sección y camporee
   **THE SYSTEM SHALL** mantener órdenes, totales, folios, comprobantes y máquinas de estado independientes: inscripción vía `field_payment_orders` / `camporee_payments`; pedidos vía `camporee_orders`.

7. **WHEN** una sección emite un pedido
   **THE SYSTEM SHALL** calcular precios y `total_centavos` en servidor desde la oferta vigente (el cliente no envía precio ni total) y **SHALL NOT** crear, mutar ni compartir folio con `field_payment_orders`, `material_orders` o `camporee_payments`.

8. **WHEN** un director consulta “Pagos pendientes”
   **THE SYSTEM SHALL** devolver inscripción, materiales generales y cada pedido de camporee como obligaciones distintas del read model `payment_obligations`, sin fusionar folios ni estados.

### Excepción sin proof

9. **WHEN** un pedido está en `ISSUED` o `PROOF_REJECTED` y un `director-lf` o `assistant-lf` del campo local cobrador invoca `authorize-without-proof` con motivo no vacío
   **THE SYSTEM SHALL** marcar `authorized_without_proof = true`, pasar la orden a `PAID` y permitir la entrega a la sección sin exigir comprobante previo.

10. **IF** la autorización sin proof no incluye motivo
    **THEN THE SYSTEM SHALL** responder `CAMPOREE_ORDER_AUTHORIZATION_REASON_REQUIRED` y no cambiar el estado.

11. **WHEN** un proof se carga después de esa excepción
    **THE SYSTEM SHALL** conservarlo como documento auditable con su propia máquina de estados; aprobar o rechazar ese proof **SHALL NOT** cambiar el estado `PAID` o `DELIVERED` de la orden.

12. **WHEN** el flujo normal de proof aplica (sin excepción)
    **THE SYSTEM SHALL** exigir carga de archivo → revisión maker-checker (uploader ≠ reviewer) → `PAID`.

### Múltiples pedidos

13. **WHEN** una sección inscrita emite un pedido dentro de la ventana (`orders_enabled`, `orders_opens_at`, `orders_deadline`)
    **THE SYSTEM SHALL** crear un folio independiente `PED{yyyy}{####}` aun si ya existen otros pedidos de la misma sección y camporee.

14. **WHEN** hay que corregir un pedido aún no pagado
    **THE SYSTEM SHALL** exigir cancelar y reemitir; **SHALL NOT** mutar líneas de una orden histórica.

15. **WHEN** hay que agregar personas o materiales después de `PAID` o `DELIVERED`
    **THE SYSTEM SHALL** exigir un pedido suplementario nuevo; **SHALL NOT** modificar la orden ya pagada o entregada.

16. **IF** el emisor reenvía el mismo payload con la misma `idempotency_key`
    **THEN THE SYSTEM SHALL** devolver el pedido original (replay) y no crear un segundo folio.

### Distribución nominada

17. **WHEN** el campo local confirma la entrega del pedido a la sección desde `PAID`
    **THE SYSTEM SHALL** pasar la orden a `DELIVERED` (`delivered_to_section_*`). Ese estado significa LF → sección, no que cada miembro ya recibió su artículo.

18. **WHEN** la orden está `DELIVERED` y el director activo de la sección emisora marca una línea como entregada al miembro
    **THE SYSTEM SHALL** registrar `delivered_to_member_at` y el director responsable sobre la cantidad completa de esa línea (v1 no divide la cantidad).

19. **IF** un actor que no es el director activo de la sección, u otra sección, o una orden que aún no está `DELIVERED`, intenta marcar distribución
    **THEN THE SYSTEM SHALL** rechazar con `CAMPOREE_ORDER_NOT_DELIVERED_TO_SECTION` o `CAMPOREE_ORDER_DISTRIBUTION_FORBIDDEN`.

20. **WHEN** se consulta una orden
    **THE SYSTEM SHALL** derivar `distribution_status` sin persistirlo: `NOT_STARTED` (ninguna línea con fecha), `PARTIAL` (algunas), `COMPLETE` (todas). La línea nominada es la única fuente de verdad; no existe tabla de allocations.

---

## Decisiones canónicas (cerradas)

| Tema | Contrato |
|------|----------|
| Bounded context | Nuevo `camporee-orders`. No extender `MaterialProduct`/`MaterialOrder`, purpose de `field_payment_orders`, `camporee_payments`, `resources` ni `club_inventory`. |
| Beneficiario | Solo inscritos; cada línea → `camporee_member_id` activo `registered\|approved` del mismo camporee y sección. |
| Líneas | Nominadas; consolidado derivado `SUM(qty)` / `SUM(line_total_centavos)`. |
| Cobro | El campo local cobra siempre, incluso catálogo Unión/División. |
| Catálogo v1 | Hecho bajo pedido; sin stock ni kardex. |
| Tallas | Un eje: `LETTER` \| `NUMERIC` \| `NONE`. Género = dos productos, no segundo eje. |
| Precio | Snapshot de la oferta del evento; el cliente no manda montos. |
| Folio | `PED{yyyy}{####}` por campo local y año. |
| Settings | En `local_camporees` / `union_camporees`: `orders_enabled` default `false`, `orders_opens_at`, `orders_deadline`. |
| Permisos | Familia propia `camporee-orders:*`. |
| Finanzas de club | El dominio no crea movimientos de caja de club ni ledger Finance. |

Emisores v1: `director`, `deputy-director`, `secretary`, `secretary-treasurer`, `treasurer`. Solo `director` de la sección marca distribución a miembros.

---

## Endpoints (PLANNED)

Prefijo `/api/v1`. Envelope y errores según contratos vigentes. **Ninguno está en runtime.** No copiar esta tabla a `ENDPOINTS-LIVE-REFERENCE.md` como implementada.

Cuerpo de emisión (el cliente no envía montos, club, sección ni campo local):

```json
{
  "lines": [
    {
      "camporee_member_id": 801,
      "offering_id": "uuid-playera",
      "option_id": "uuid-m",
      "qty": 1
    }
  ]
}
```

### Biblioteca territorial

| Method | Path | Permiso | Descripción |
|--------|------|---------|-------------|
| POST | `/camporee-order-products` | `camporee-orders:catalog-manage` | Crear producto (owner territorial derivado en servidor) |
| GET | `/camporee-order-products` | `camporee-orders:read` | Listar biblioteca visible |
| GET | `/camporee-order-products/:productId` | `camporee-orders:read` | Detalle de producto |
| PATCH | `/camporee-order-products/:productId` | `camporee-orders:catalog-manage` | Actualizar producto (no cambiar owner) |
| POST | `/camporee-order-products/:productId/options` | `camporee-orders:catalog-manage` | Crear opción de talla |
| PATCH | `/camporee-order-product-options/:optionId` | `camporee-orders:catalog-manage` | Actualizar opción (soft-delete; no hard-delete si hay órdenes) |

### Settings y ofertas

| Method | Path | Permiso | Descripción |
|--------|------|---------|-------------|
| PATCH | `/camporees/:camporeeId/orders-settings` | `camporee-orders:offering-configure` | Ventana de pedidos del camporee local |
| PATCH | `/union-camporees/:camporeeId/orders-settings` | `camporee-orders:offering-configure` | Ventana de pedidos del camporee de unión |
| GET | `/camporees/:camporeeId/order-offerings` | `camporee-orders:read` | Ofertas del camporee local |
| GET | `/union-camporees/:camporeeId/order-offerings` | `camporee-orders:read` | Ofertas del camporee de unión |
| PUT | `/camporees/:camporeeId/order-offerings` | `camporee-orders:offering-configure` | Reemplazar ofertas del camporee local |
| PUT | `/union-camporees/:camporeeId/order-offerings` | `camporee-orders:offering-configure` | Reemplazar ofertas del camporee de unión |

El GET de detalle del camporee incluirá settings para evitar un round-trip extra.

### Pedido

| Method | Path | Permiso | Descripción |
|--------|------|---------|-------------|
| POST | `/camporees/:camporeeId/orders` | `camporee-orders:create` | Emitir pedido de sección (camporee local) |
| POST | `/union-camporees/:camporeeId/orders` | `camporee-orders:create` | Emitir pedido de sección (camporee de unión) |
| GET | `/camporee-orders` | `camporee-orders:read` | Listar pedidos visibles (no colapsa suplementarios) |
| GET | `/camporee-orders/review-queue` | `camporee-orders:review` | Bandeja de revisión LF |
| GET | `/camporee-orders/:orderId` | `camporee-orders:read` | Detalle: cabecera, líneas nominadas, summary derivado, `distribution_status` |
| GET | `/camporee-orders/:orderId/document` | `camporee-orders:read` | PDF del pedido |
| GET | `/camporee-orders/:orderId/proof` | `camporee-orders:read` | Metadata / URL firmada del proof |
| POST | `/camporee-orders/:orderId/proof` | `camporee-orders:upload-proof` | Subir comprobante (JPG/PNG/WebP/PDF ≤10 MB) |
| POST | `/camporee-orders/:orderId/cancel` | `camporee-orders:create` / `:review` | Cancelar pedido |
| POST | `/camporee-orders/:orderId/approve` | `camporee-orders:review` | Aprobar proof (maker-checker) |
| POST | `/camporee-orders/:orderId/reject` | `camporee-orders:review` | Rechazar proof (motivo obligatorio) |
| POST | `/camporee-orders/:orderId/authorize-without-proof` | `camporee-orders:authorize-without-proof` | Excepción LF; motivo obligatorio |
| POST | `/camporee-orders/:orderId/deliver` | `camporee-orders:deliver` | Entrega LF → sección (`PAID` → `DELIVERED`) |
| POST | `/camporee-orders/:orderId/lines/:lineId/deliver-to-member` | `camporee-orders:distribute` | Director marca línea entregada al miembro |

### Read model transversal (PLANNED)

| Method | Path | Descripción |
|--------|------|-------------|
| GET | `/payment-obligations/pending` | Une `field_payment_orders` + `material_orders` + `camporee_orders` sin fusionar folios. Query opcional `camporee_id` / `union_camporee_id`. |

**Total PLANNED: 27** (6 biblioteca + 6 settings/ofertas + 14 pedido + 1 read model).

---

## Errores previstos (no runtime)

```text
CAMPOREE_ORDERS_DISABLED
CAMPOREE_ORDERS_NOT_OPEN
CAMPOREE_ORDERS_CLOSED
CAMPOREE_ORDER_NOT_FOUND
CAMPOREE_ORDER_FORBIDDEN
CAMPOREE_ORDER_INVALID_TRANSITION
CAMPOREE_ORDER_LINES_REQUIRED
CAMPOREE_ORDER_MEMBER_NOT_ELIGIBLE
CAMPOREE_ORDER_OFFERING_INVALID
CAMPOREE_ORDER_OPTION_REQUIRED
CAMPOREE_ORDER_OPTION_FORBIDDEN
CAMPOREE_ORDER_PRODUCT_SCOPE_INVALID
CAMPOREE_ORDER_PAYMENT_CONFIG_REQUIRED
CAMPOREE_ORDER_MAKER_CHECKER
CAMPOREE_ORDER_PROOF_INVALID_FILE
CAMPOREE_ORDER_REJECT_REASON_REQUIRED
CAMPOREE_ORDER_AUTHORIZATION_REASON_REQUIRED
CAMPOREE_ORDER_NOT_DELIVERED_TO_SECTION
CAMPOREE_ORDER_LINE_NOT_FOUND
CAMPOREE_ORDER_DISTRIBUTION_FORBIDDEN
```

---

## Máquina de estados prevista

```text
ISSUED ──► PROOF_SUBMITTED ──► PAID ──► DELIVERED
  │              │
  │              └──► PROOF_REJECTED ──► PROOF_SUBMITTED
  │                        │
  │                        ├──► PAID  (authorize-without-proof)
  │                        └──► CANCELLED
  ├──► PAID               (authorize-without-proof)
  ├──► CANCELLED
  └──► EXPIRED
```

`DELIVERED`, `CANCELLED` y `EXPIRED` son terminales respecto del pedido financiero. La distribución a miembros no añade estados a esa máquina.

---

## Permisos previstos

| Permiso | Uso |
|---------|-----|
| `camporee-orders:read` | Catálogo visible, órdenes propias/territoriales, PDF |
| `camporee-orders:catalog-manage` | CRUD biblioteca dentro del scope |
| `camporee-orders:offering-configure` | Settings y ofertas del camporee propio |
| `camporee-orders:create` | Emitir/cancelar orden propia |
| `camporee-orders:upload-proof` | Subir proof de orden propia |
| `camporee-orders:review` | Approve/reject LF |
| `camporee-orders:authorize-without-proof` | Excepción LF |
| `camporee-orders:deliver` | Entrega LF → sección |
| `camporee-orders:distribute` | Registrar entrega de una línea al miembro |

Ninguna mutación carga una orden solo por UUID y permiso: siempre resuelve territorio y relación con la sección.

---

## Settings del camporee

En `local_camporees` y `union_camporees` (migración prevista, no aplicada a Neon):

| Campo | Regla |
|-------|--------|
| `orders_enabled` | Default `false`; bloquea catálogo público y emisión |
| `orders_opens_at` | `null` = abre de inmediato si está habilitado |
| `orders_deadline` | `null` = usa el fin del camporee como tope |

Timezone IANA del camporee; no interpretar fechas con la zona del dispositivo.

---

## Fuera de alcance v1

- Pedido directo por el miembro.
- Jueces y staff como beneficiarios.
- Stock, kardex, proveedores, producción y transporte.
- Segundo eje de variante o precio distinto por talla.
- Pago en línea, conciliación bancaria o reembolso automatizado.
- Transferencia financiera LF → Unión/División.
- Carrito persistente en servidor antes de emitir.
- Entrega parcial de la cantidad de una misma línea.
- Logística de cocina/compras operativas del evento (sigue siendo gap de [camporees.md](camporees.md)).

---

## Relación con otros dominios

| Dominio | Relación |
|---------|----------|
| [camporees](camporees.md) | Settings en el camporee; roster `camporee_members` / `camporee_clubs` como elegibilidad. |
| Field Payment Orders | Solo patrón (folio, proof, caja LF). Inscripción permanece en `field_payment_orders`. |
| Materials | Solo patrón. Catálogo general y stock no se reutilizan. |
| Pagos pendientes | Read model unificado; mutaciones siguen siendo dueñas de cada fuente. |
