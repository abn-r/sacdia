# Órdenes de pago territoriales y obligaciones de pago

**Estado**: IMPLEMENTADO
**Verificado contra código**: 2026-10-04 (rama `development`)
**Dominios relacionados**: [gestion-seguros.md](gestion-seguros.md) (seguros, reasignaciones, runbook de piloto), [camporees.md](camporees.md), [camporee-orders.md](camporee-orders.md), [camporee-supplies.md](camporee-supplies.md), [materials.md](materials.md)

## Descripcion de dominio

Una **orden de pago territorial** (`field_payment_orders`) es el cobro que un club hace al Campo Local por una lista de beneficiarios con nombre: seguro anual o inscripción a un camporee. La sección emite la orden, descarga el PDF con las instrucciones de pago, sube el comprobante y el Campo Local lo aprueba. Al aprobar, el backend materializa el resultado (cobertura de seguro o inscripción al camporee) en la misma transacción.

Las **obligaciones de pago** (`payment-obligations`) son una vista de solo lectura que junta todo lo que una sección o un Campo Local tiene pendiente de pagar o revisar: órdenes de pago, pedidos de camporee, pedidos de materiales y documentos de cobro de insumos de camporee.

## Que existe (verificado contra codigo)

### Backend: órdenes de pago (`src/field-payment-orders/`)

Controller con `JwtAuthGuard` + `PermissionsGuard`.

| Método | Ruta (`/api/v1`) | Permiso | Recurso |
|---|---|---|---|
| POST | `/insurance/payment-orders` | `field-payment-orders:create` | `active_assignment` |
| POST | `/camporees/:camporeeId/payment-orders` | `field-payment-orders:create` | `active_assignment` |
| POST | `/union-camporees/:camporeeId/payment-orders` | `field-payment-orders:create` | `active_assignment` |
| GET | `/payment-orders` | `field-payment-orders:read` | `active_assignment` |
| GET | `/payment-orders/context` | `field-payment-orders:read` | `active_assignment` |
| GET | `/payment-orders/review-queue` | `field-payment-orders:review` | `global` |
| GET / POST | `/payment-orders/config` | `field-payment-orders:configure` | `global` |
| GET | `/payment-orders/:orderId` | `field-payment-orders:read` | `active_assignment` |
| GET | `/payment-orders/:orderId/document` (PDF) | `field-payment-orders:read` | `active_assignment` |
| GET | `/payment-orders/:orderId/proof` | `field-payment-orders:read` | `active_assignment` |
| POST | `/payment-orders/:orderId/proof` (multipart) | `field-payment-orders:upload-proof` | `active_assignment` |
| POST | `/payment-orders/:orderId/cancel` | `field-payment-orders:cancel` | `active_assignment` |
| POST | `/payment-orders/:orderId/approve` | `field-payment-orders:review` | `global` |
| POST | `/payment-orders/:orderId/reject` | `field-payment-orders:review` | `global` |

Las reasignaciones de cobertura de seguro (`/insurance/reassignments`, 4 rutas) viven en el mismo módulo y están descritas en [gestion-seguros.md](gestion-seguros.md).

Reglas verificadas en `field-payment-orders.service.ts`, `state-machine.ts` y `fulfillment/`:

- **Propósitos**: `INSURANCE` (referencia `insurance_cycle_config_id`) y `CAMPOREE` (referencia `local_camporee_id` o `union_camporee_id`). En un camporee de unión cobra igualmente el Campo Local; el traspaso a la unión ocurre fuera del sistema.
- **Estados**: `ISSUED → PROOF_SUBMITTED | CANCELLED | EXPIRED`; `PROOF_SUBMITTED → APPROVED | PROOF_REJECTED`; `PROOF_REJECTED → PROOF_SUBMITTED | CANCELLED`. `APPROVED`, `CANCELLED` y `EXPIRED` son terminales. Transición inválida: 422 `FIELD_PAYMENT_ORDER_INVALID_TRANSITION`.
- **Emisión**: exige el flag `field_payment_orders_v1` activo para el Campo Local (`FIELD_PAYMENT_ORDER_FLAG_DISABLED`), al menos un beneficiario y costo unitario mayor que cero (`FIELD_PAYMENT_ORDER_COST_NOT_CONFIGURED`). Total = costo unitario × beneficiarios. Un beneficiario con otra orden activa produce 409 `FIELD_PAYMENT_ORDER_DUPLICATE_BENEFICIARY`.
- **Idempotencia**: el header `Idempotency-Key` hace que una segunda petición del mismo emisor con la misma clave devuelva la orden existente.
- **Folio**: `ORD{año}{0001}`, contador por Campo Local y año en `field_payment_folio_counters`.
- **Vencimiento**: `expires_at` = emisión + `field_payment_orders.expiry_days` (por defecto 15). Las órdenes `ISSUED` vencidas pasan a `EXPIRED` de forma perezosa: en bloque al llamar a `GET /payment-orders` o `GET /payment-orders/review-queue`, y una a una al leer el detalle, cancelar o subir comprobante (subir comprobante a una orden vencida responde `FIELD_PAYMENT_ORDER_EXPIRED`). No hay cron.
- **Aprobación**: requiere un comprobante `SUBMITTED`; quien lo subió no puede aprobar (`FIELD_PAYMENT_ORDER_MAKER_CHECKER`). Rechazar exige motivo (`FIELD_PAYMENT_ORDER_REJECT_REASON_REQUIRED`).
- **Materialización de camporee**: en la transacción de aprobación revalida que la sección siga inscrita, la membresía activa y un seguro vigente por beneficiario, y crea un `camporee_members` aprobado y un `camporee_payments` de inscripción aprobado por línea. Un fallo revierte todo. "Ningún camporee es gratis": `registration_cost` nulo o 0 bloquea la orden.
- **Materialización de seguro**: ver [gestion-seguros.md](gestion-seguros.md) ("Órdenes de pago territoriales").
- **Eventos**: logs estructurados `field_payment_order.*` (`issued`, `proof_submitted`, `approved`, `rejected`, `cancelled`, `expired`, `fulfill_fail`).

### Backend: obligaciones de pago (`src/payment-obligations/`)

| Método | Ruta (`/api/v1`) | Permiso |
|---|---|---|
| GET | `/payment-obligations/pending` | cualquiera de `camporee-orders:read`, `camporee-supplies:read`, `field-payment-orders:read`, `materiales:read` (`mode: 'any'`), recurso `active_assignment` |

Reglas verificadas en `payment-obligations.service.ts`:

- **Ámbito**: acceso global → todo; revisor con Campo Local → su Campo Local; si no, la sección activa del actor; sin ninguno, lista vacía.
- **Fuentes**:
  - `FIELD_PAYMENT_ORDER` y `CAMPOREE_ORDER` en `ISSUED`, `PROOF_SUBMITTED` o `PROOF_REJECTED`;
  - `MATERIAL_ORDER` en `en_revision` (`ORDER_REVIEW`) o `aprobada` (`PAYMENT_DUE`);
  - `CAMPOREE_SUPPLY_CHARGE` / `CAMPOREE_SUPPLY_REFUND` para documentos de insumos `ISSUED`.
- Cada fila trae `status` (`PAYMENT_DUE`, `UNDER_REVIEW`, `PROOF_REJECTED`, `ORDER_REVIEW`) y `action_required` (`UPLOAD_PROOF`, `WAIT_REVIEW`, `RESUBMIT_PROOF`, `WAIT_APPROVAL`, `PAY_AT_CAMP`, `PROCESS_REFUND`).
- Con filtro de camporee (`camporee_id` o `union_camporee_id`) se omiten los pedidos de materiales. Orden: fecha descendente, luego fuente y folio.

### Admin

- `/dashboard/payment-orders` (`PaymentOrdersClient`): pestañas de pendientes (`PaymentObligationsClient`, consume `/payment-obligations/pending`), bandeja de órdenes y reasignaciones (`ReassignmentsTray`).
- `/dashboard/insurance/config`: productos, ciclos e instrucciones de pago del Campo Local.

### App móvil

- `lib/features/payment_orders/`: `PaymentOrdersView`, `IssuePaymentOrderView` (emisión con selección de beneficiarios) y `PaymentOrderDetailView` (PDF, comprobante, estado).
- `lib/features/camporee_orders/` consume `GET /payment-obligations/pending`.

### Base de datos

- `field_payment_orders` (propósito, Campo Local, club, sección, folio, referencias, costos en centavos, `expires_at`, `idempotency_key`, `issued_by_id`).
- `field_payment_order_lines` (un beneficiario por línea), `field_payment_order_proofs` (`SUBMITTED`, `APPROVED`, `REJECTED`), `field_payment_folio_counters`, `field_payment_order_configs` (datos bancarios y de caja por Campo Local, único por `local_field_id`), `insurance_reassignment_requests`.
- Enums: `field_payment_order_purpose_enum`, `field_payment_order_status_enum`, `field_payment_order_proof_status_enum`, `insurance_reassignment_request_status_enum`.

## Gaps y pendientes

- La expiración es perezosa; no hay job que venza órdenes sin actividad.
- Los eventos son solo logs: no hay notificación push ni correo al aprobar o rechazar.
- El rollout por Campo Local depende de editar el JSON de `field_payment_orders_v1` en [system-config.md](system-config.md).
