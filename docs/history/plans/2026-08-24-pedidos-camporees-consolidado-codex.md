# Pedidos de campamentos y camporees — Consolidated Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Permitir que una sección inscrita en un campamento o camporee emita uno o más pedidos globales de artículos asignados a miembros inscritos, pague y compruebe cada obligación por separado de la inscripción, y dé seguimiento hasta la distribución por miembro.

**Architecture:** Crear un bounded context independiente `camporee-orders`, reutilizando patrones probados de Materials y Field Payment Orders sin extender sus tablas. Cada sección podrá emitir varios pedidos independientes con líneas nominadas por `camporee_member_id`; un read model transversal mostrará inscripción, materiales generales y pedidos dentro de “Pagos pendientes” sin fusionar folios, comprobantes ni estados. La entrega tendrá dos niveles: LF entrega el pedido a la sección y el director registra después la distribución de cada línea al miembro beneficiario.

**Tech Stack:** NestJS 11, Prisma 7, PostgreSQL, Cloudflare R2, PDFKit, Flutter/Riverpod, Next.js 16, React 19, TanStack Query y shadcn/ui.

**Estado:** READY FOR IMPLEMENTATION
**Fecha:** 2026-08-24
**Alcance:** `sacdia-backend`, `sacdia-app`, `sacdia-admin` y documentación canónica
**Restricción:** Nunca ejecutar builds. Usar pruebas focalizadas, lint sin `--fix`, typecheck/analyze y `git diff --check`.

---

## 0. Consolidación y precedencia

Este documento reemplaza como plan de ejecución —sin borrar— a:

- `docs/plans/2026-08-24-pedidos-camporees-codex.md`
- `docs/plans/2026-08-24-camporee-pedidos-cursor.md`

Cuando haya conflicto, manda este plan. Las resoluciones principales son:

| Conflicto | Resolución canónica |
|---|---|
| Extender Materials vs dominio nuevo | Dominio independiente `camporee-orders` |
| Cualquier miembro activo vs solo inscrito | Solo `camporee_members` activos `registered|approved` |
| Línea agregada + allocations vs línea nominada | Línea nominada; consolidado calculado |
| Pago normal vs entrega excepcional sin proof | Ambos; excepción LF auditada |
| Bandeja separada vs Pagos pendientes unificado | Read model unificado; mutaciones separadas |
| Stock administrado vs made-to-order | Made-to-order en v1; sin kardex |
| Varias oleadas vs pedido global singular | Varios pedidos independientes por sección y camporee |
| `materiales:*` vs permisos propios | Permisos `camporee-orders:*` |
| `npm` vs package manager del proyecto | `pnpm` |
| Schema documental vs efectivo | Manda `sacdia-backend/prisma/schema.prisma` |

---

## 1. Runtime verificado que debe reutilizarse

### Patrones, no tablas

- Folios transaccionales:
  - `sacdia-backend/src/materials/orders/folio.service.ts`
  - `sacdia-backend/src/field-payment-orders/folio.service.ts`
- State machine pura:
  - `sacdia-backend/src/field-payment-orders/state-machine.ts`
- Proof privado, magic bytes y URLs firmadas:
  - `sacdia-backend/src/field-payment-orders/field-payment-order-proof.service.ts`
  - `sacdia-backend/src/field-payment-orders/proof-file-validation.pipe.ts`
- PDF servidor:
  - `sacdia-backend/src/field-payment-orders/field-payment-order-pdf.service.ts`
- Scope territorial:
  - `sacdia-backend/src/common/authorization/actor-territory-scope.ts`
  - `sacdia-backend/src/field-payment-orders/order-actor.ts`
- Caja/banco LF:
  - tabla `field_payment_order_configs`
  - `sacdia-backend/src/field-payment-orders/field-payment-order-configs.service.ts`
- Roster inscrito:
  - `camporee_clubs`
  - `camporee_members`
- Superficies cliente:
  - `sacdia-app/lib/features/payment_orders/`
  - `sacdia-admin/src/components/payment-orders/`
  - `sacdia-admin/src/components/camporees/camporee-detail-tabs.tsx`

### Qué no debe reutilizarse como persistencia

| Módulo | Motivo |
|---|---|
| `MaterialProduct` / `MaterialOrder` | Catálogo LF, stock y líneas anónimas; generalizarlo ampliaría regresiones |
| `field_payment_orders` | Purpose y costo uniforme por beneficiario; no soporta carrito heterogéneo |
| `camporee_payments` | Ledger por miembro sin catálogo ni consolidado |
| `resources` | Archivos digitales, no artículos vendibles |
| `club_inventory` | Bienes operativos del club, no ventas |

---

## 2. Decisiones funcionales cerradas

1. **Solo inscritos:** cada línea referencia un `camporee_member_id` activo y con estado `registered|approved` del mismo camporee y sección.
2. **Orden de sección:** el director captura por persona, pero el sistema emite un folio y total global para la sección.
3. **Pago independiente:** inscripción y pedidos nunca comparten orden, total ni comprobante.
4. **Pagos pendientes:** ambas obligaciones aparecen juntas en una lectura agregada; cada acción abre su flujo propietario.
5. **Varios pedidos:** una sección puede emitir pedidos iniciales y suplementarios dentro de la ventana del camporee; cada uno conserva folio, pago, proof y estado propios.
6. **Correcciones y adiciones:** antes de pagar, cancelar y reemitir. Después de pagar o entregar, no se modifica la orden histórica; personas o materiales nuevos se agregan mediante otro pedido.
7. **Catálogo territorial:** producto dueño `DIVISION|UNION|LOCAL_FIELD`, exactamente uno.
8. **Oferta por camporee:** producto + camporee + precio. El mismo producto puede tener precios diferentes en eventos distintos.
9. **Campo Local cobra:** aun para catálogo Unión/División, la caja, revisión y entrega pertenecen al LF de la sección emisora.
10. **Made-to-order:** v1 no descuenta stock ni administra disponibilidad física.
11. **Tallas:** un eje por producto: `LETTER|NUMERIC|NONE`; opciones libres y ordenadas.
12. **Género:** se representa como productos distintos —por ejemplo, Playera hombre y Playera mujer—, no como segundo eje.
13. **Precio servidor:** el cliente nunca manda precio ni total; se toma la oferta y se guarda snapshot.
14. **Proof normal:** upload → revisión maker-checker → `PAID`.
15. **Excepción LF:** `director-lf` o `assistant-lf` puede autorizar pago sin proof, permitir entrega y dejar proof documental pendiente.
16. **Proof posterior:** aprobar/rechazar un proof cargado después de la excepción no cambia el estado `PAID|DELIVERED`.
17. **Entrega LF → sección:** LF confirma la entrega global del pedido al director y la orden pasa a `DELIVERED`.
18. **Distribución sección → miembro:** después de la entrega global, el director marca cada línea nominada como entregada; el avance derivado es `NOT_STARTED|PARTIAL|COMPLETE`.
19. **Granularidad de distribución:** una línea se entrega completa; v1 no divide parcialmente la cantidad de una misma línea.
20. **Sin parciales financieros:** no hay pagos ni devoluciones parciales automatizadas.
21. **Sin Finance ledger:** el dominio conserva su proof y estado; no crea movimientos de caja de club.
22. **Contract-first:** backend, schema, permisos y errores se cierran antes del admin visual.

### Fuera de alcance v1

- Pedido directo por el miembro.
- Jueces y staff.
- Stock, kardex, proveedores, producción y transporte.
- Segundo eje de variante.
- Precio diferente por talla.
- Pago en línea o conciliación bancaria.
- Reembolso automatizado.
- Transferencia financiera LF → Unión/División.
- Carrito persistente en servidor antes de emitir.
- Entrega parcial de la cantidad contenida en una misma línea.

---

## 3. Arquitectura objetivo

```text
Biblioteca territorial                 Camporee local o de unión
Division | Union | Local Field          orders settings
              |                                |
              v                                v
 camporee_order_products ------> camporee_order_offerings
 talla/opciones                   precio del evento
                                           |
                           director captura por inscrito
                                           |
                                           v
                                  camporee_orders
                            múltiples folios por sección
                                           |
                                           v
                               camporee_order_lines
                         camporee_member + artículo + talla
                                           |
                   +-----------------------+---------------------+
                   v                                             v
       summary derivado por producto/talla             detalle nominado/PDF
                   |
                   v
        proof → review LF → PAID → DELIVERED (LF → sección)
                   |
                   +── excepción authorize-without-proof

Después de DELIVERED:
camporee_order_lines → director marca entrega al miembro
                    → distribution_status derivado

Read model:
field_payment_orders + material_orders + camporee_orders
                         |
                         v
                 payment_obligations
```

### Principio de consistencia

La línea nominada es la única fuente de verdad. No se persiste una segunda tabla de allocations ni una cantidad agregada independiente.

```text
summary(product, option) = SUM(camporee_order_lines.qty)
total(order)              = SUM(camporee_order_lines.line_total_centavos)
```

El backend calcula y escribe líneas + total dentro de una transacción. PostgreSQL verifica únicamente invariantes por fila (`qty > 0`, `line_total = qty * unit_price`); no se pretende usar un `CHECK` cross-row.

---

## 4. Modelo de datos

Migración propuesta:

`sacdia-backend/prisma/migrations/20260824190000_camporee_orders/migration.sql`

### 4.1 Settings del camporee

Añadir a `local_camporees` y `union_camporees`:

```prisma
orders_enabled    Boolean   @default(false)
orders_opens_at   DateTime? @db.Timestamptz(6)
orders_deadline   DateTime? @db.Timestamptz(6)
```

Reglas:

- `orders_enabled=false` bloquea catálogo público y emisión.
- `orders_opens_at=null` abre de inmediato.
- `orders_deadline=null` usa fin del camporee como tope.
- Se usa timezone IANA del camporee; no interpretar dates con timezone del dispositivo.

### 4.2 Enums

```prisma
enum camporee_order_owner_scope_enum {
  DIVISION
  UNION
  LOCAL_FIELD
}

enum camporee_order_size_scheme_enum {
  LETTER
  NUMERIC
  NONE
}

enum camporee_order_status_enum {
  ISSUED
  PROOF_SUBMITTED
  PROOF_REJECTED
  PAID
  DELIVERED
  CANCELLED
  EXPIRED
}

enum camporee_order_proof_status_enum {
  SUBMITTED
  APPROVED
  REJECTED
}
```

### 4.3 Biblioteca territorial

`camporee_order_products`

| Columna | Regla |
|---|---|
| `camporee_order_product_id` | UUID PK |
| `owner_scope` | enum territorial |
| `owner_division_id` | requerido solo para División |
| `owner_union_id` | requerido solo para Unión |
| `owner_local_field_id` | requerido solo para LF |
| `title` | varchar(200), no vacío |
| `description` | text nullable |
| `size_scheme` | `LETTER|NUMERIC|NONE` |
| `club_type_id` | nullable = todos los programas |
| `active` | soft-delete |
| `created_by_id`, `modified_by_id` | actor UUID |
| timestamps | timestamptz |

Checks/índices:

- Exactamente un owner compatible con `owner_scope`.
- Índices por owner + active.
- No permitir cambiar owner después de crear.

`camporee_order_product_options`

| Columna | Regla |
|---|---|
| `camporee_order_product_option_id` | UUID PK |
| `camporee_order_product_id` | FK cascade |
| `label` | varchar(40), único por producto |
| `sort_order` | entero |
| `active` | soft-delete |

- `NONE`: cero opciones activas.
- `LETTER|NUMERIC`: al menos una opción activa antes de ofertar.
- `NUMERIC`: label debe ser una representación numérica válida.
- Una opción referenciada por una orden nunca se elimina físicamente.

### 4.4 Oferta por camporee

`camporee_order_offerings`

| Columna | Regla |
|---|---|
| `camporee_order_offering_id` | UUID PK |
| `local_camporee_id` / `union_camporee_id` | XOR |
| `camporee_order_product_id` | FK |
| `price_centavos` | entero > 0 |
| `active` | soft-delete |
| `sort_order` | orden visual |
| `created_by_id`, `modified_by_id` | actor UUID |
| timestamps | timestamptz |

Índices únicos parciales impiden repetir producto en el mismo camporee.

Visibilidad:

- Camporee local: producto del LF organizador, su Unión o su División.
- Camporee de Unión: producto de la Unión organizadora o su División.
- Nunca un producto de otro sibling territorial.

### 4.5 Orden de sección

`camporee_orders`

| Columna | Regla |
|---|---|
| `camporee_order_id` | UUID PK |
| `local_field_id` | LF que cobra, derivado de la sección |
| `club_id`, `club_section_id` | contexto emisor |
| `local_camporee_id` / `union_camporee_id` | XOR |
| `folio`, `folio_reference` | `PED{yyyy}{####}` |
| `status` | state machine |
| `currency` | `MXN` |
| `total_centavos` | suma transaccional de líneas |
| `expires_at` | expiración lazy |
| `issued_by_id` | emisor |
| `approved_by_id`, `approved_at` | review normal |
| `authorized_without_proof` | default false |
| `authorized_by_id`, `authorized_at`, `authorization_reason` | excepción auditada |
| `delivered_to_section_by_id`, `delivered_to_section_at` | entrega global LF → sección |
| `cancelled_by_id`, `cancelled_at`, `cancel_reason` | cancelación |
| `expired_at` | expiración |
| `idempotency_key` | UUID opcional, único por emisor |
| snapshot bancario/caja | copia de `field_payment_order_configs` al emitir |
| timestamps | timestamptz |

Índices:

- Unique `(local_field_id, folio_reference)`.
- Unique `(issued_by_id, idempotency_key)` cuando key no es null.
- No existe unique sección + camporee: se permiten pedidos suplementarios.
- LF + status, sección + camporee + created_at y camporee + status.

### 4.6 Líneas nominadas

`camporee_order_lines`

| Columna | Regla |
|---|---|
| `camporee_order_line_id` | UUID PK |
| `camporee_order_id` | FK cascade |
| `sequence` | entero único dentro de orden |
| `camporee_member_id` | FK al inscrito, fuente de elegibilidad |
| `beneficiary_user_id` | snapshot/índice del usuario |
| `beneficiary_name_snapshot` | nombre al emitir |
| `offering_id` | FK a oferta |
| `product_id` | snapshot FK |
| `option_id` | nullable según size scheme |
| `product_title_snapshot` | título histórico |
| `option_label_snapshot` | talla histórica |
| `qty` | entero 1..99 |
| `unit_price_centavos` | snapshot servidor |
| `line_total_centavos` | `qty * unit_price` |
| `delivered_to_member_by_id` | director que entregó; nullable |
| `delivered_to_member_at` | fecha de entrega; nullable |

Unique `(order_id, camporee_member_id, offering_id, option_id)`.

Reglas de distribución:

- Solo puede marcarse una línea cuando la orden está `DELIVERED` por LF.
- Solo el director activo de la sección emisora puede marcarla.
- La operación es idempotente: repetirla devuelve la línea ya entregada sin duplicar eventos.
- `distribution_status` no se persiste en la cabecera; se deriva así:

```text
NOT_STARTED = ninguna línea tiene delivered_to_member_at
PARTIAL     = algunas líneas tienen delivered_to_member_at
COMPLETE    = todas las líneas tienen delivered_to_member_at
```
- La entrega aplica a la cantidad completa de la línea.

### 4.7 Proof y folio

- `camporee_order_proofs`: mismas columnas seguras que `field_payment_order_proofs`.
- `camporee_order_folio_counters`: PK `(local_field_id, year)`, counter con `FOR UPDATE`.
- R2 privado; JPG/PNG/WebP/PDF ≤10 MB; magic bytes; URL firmada de 15 minutos.

---

## 5. Elegibilidad exacta

`assertBeneficiaryEligible()` debe afirmar, por cada línea:

```text
camporee_member.active = true
camporee_member.status IN ('registered', 'approved')
camporee_member.camporee_club.club_section_id = actor.active_section_id
camporee_member.camporee_id = route.local_camporee_id
  XOR
camporee_member.union_camporee_id = route.union_camporee_id
```

Además:

- La sección está inscrita y activa en `camporee_clubs`.
- Para Unión, el LF participa activamente en `union_camporee_local_fields`.
- El actor tiene un rol permitido en esa sección.
- No se aceptan `user_id` libres enviados por cliente.

Roles emisores v1:

- `director`
- `deputy-director`
- `secretary`
- `secretary-treasurer`
- `treasurer`

---

## 6. Máquina de estados

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

PAID|DELIVERED con authorized_without_proof=true:
  admite upload/re-upload documental de proof;
  approve/reject del proof NO cambia status de la orden.
```

Reglas:

- Maker-checker: uploader != reviewer.
- `DELIVERED`, `CANCELLED`, `EXPIRED` son terminales respecto del pedido.
- Proof documental posterior mantiene su propia state machine.
- Expiración lazy solo desde `ISSUED` sin proof.
- TTL: `min(orders_deadline, created_at + config expiry_days)`; default 15 días.
- Transición inválida: 422 `CAMPOREE_ORDER_INVALID_TRANSITION`.
- `DELIVERED` significa LF → sección; no implica que todos los miembros recibieron sus artículos.
- La distribución a miembros no agrega estados a la orden financiera: se deriva desde las líneas como `NOT_STARTED|PARTIAL|COMPLETE`.

---

## 7. Permisos y alcance

Permisos nuevos:

| Permiso | Uso |
|---|---|
| `camporee-orders:read` | catálogo visible, órdenes propias/territoriales, PDF |
| `camporee-orders:catalog-manage` | CRUD biblioteca dentro del scope |
| `camporee-orders:offering-configure` | settings y ofertas del camporee propio |
| `camporee-orders:create` | emitir/cancelar orden propia |
| `camporee-orders:upload-proof` | subir proof de orden propia |
| `camporee-orders:review` | approve/reject LF |
| `camporee-orders:authorize-without-proof` | excepción LF |
| `camporee-orders:deliver` | entrega LF |
| `camporee-orders:distribute` | registrar entrega de una línea al miembro |

Grants:

- Liderazgo de sección: read/create/upload-proof según lista de §5.
- Solo `director` de la sección: distribute sobre órdenes de su propia sección.
- `director-lf`, `assistant-lf`: read/review/authorize/deliver y catálogo/oferta dentro de LF.
- `director-union`, `assistant-union`: catálogo/oferta de Unión; no revisan pagos de LF.
- `director-dia`, `assistant-dia`: catálogo de División; no revisan pagos de LF.
- Admin/super-admin: según política global vigente, siempre recortado por el resolver aplicable y auditado.

Ninguna mutación carga una orden solo por UUID y permiso: siempre resuelve el territorio y la relación con la sección.

---

## 8. Contratos HTTP

Prefijo `/api/v1`; envelope y errores según contratos actuales.

### 8.1 Biblioteca

| Método | Ruta | Permiso |
|---|---|---|
| POST | `/camporee-order-products` | catalog-manage |
| GET | `/camporee-order-products` | read |
| GET | `/camporee-order-products/:productId` | read |
| PATCH | `/camporee-order-products/:productId` | catalog-manage |
| POST | `/camporee-order-products/:productId/options` | catalog-manage |
| PATCH | `/camporee-order-product-options/:optionId` | catalog-manage |

No hard-delete. El backend deriva/verifica owner territorial.

### 8.2 Settings y ofertas

| Método | Ruta | Permiso |
|---|---|---|
| PATCH | `/camporees/:camporeeId/orders-settings` | offering-configure |
| PATCH | `/union-camporees/:camporeeId/orders-settings` | offering-configure |
| GET | `/camporees/:camporeeId/order-offerings` | read |
| GET | `/union-camporees/:camporeeId/order-offerings` | read |
| PUT | `/camporees/:camporeeId/order-offerings` | offering-configure |
| PUT | `/union-camporees/:camporeeId/order-offerings` | offering-configure |

GET de detalle del camporee incluye settings para evitar round-trip adicional.

### 8.3 Pedido

| Método | Ruta | Permiso |
|---|---|---|
| POST | `/camporees/:camporeeId/orders` | create |
| POST | `/union-camporees/:camporeeId/orders` | create |
| GET | `/camporee-orders` | read |
| GET | `/camporee-orders/review-queue` | review |
| GET | `/camporee-orders/:orderId` | read |
| GET | `/camporee-orders/:orderId/document` | read |
| GET | `/camporee-orders/:orderId/proof` | read |
| POST | `/camporee-orders/:orderId/proof` | upload-proof |
| POST | `/camporee-orders/:orderId/cancel` | create/review |
| POST | `/camporee-orders/:orderId/approve` | review |
| POST | `/camporee-orders/:orderId/reject` | review |
| POST | `/camporee-orders/:orderId/authorize-without-proof` | authorize-without-proof |
| POST | `/camporee-orders/:orderId/deliver` | deliver |
| POST | `/camporee-orders/:orderId/lines/:lineId/deliver-to-member` | distribute |

Reglas:

- `GET /camporee-orders` devuelve todos los pedidos visibles; no colapsa pedidos suplementarios.
- Cada `POST /camporees/:camporeeId/orders` crea un folio independiente, salvo replay de la misma `idempotency_key`.
- `deliver` registra LF → sección; `deliver-to-member` exige orden `DELIVERED` y director activo de la sección.

Create body:

```json
{
  "lines": [
    {
      "camporee_member_id": 801,
      "offering_id": "uuid-playera",
      "option_id": "uuid-m",
      "qty": 1
    },
    {
      "camporee_member_id": 802,
      "offering_id": "uuid-gorra",
      "option_id": null,
      "qty": 1
    }
  ]
}
```

Montos, club, sección y LF están prohibidos como autoridad del cliente.

Respuesta incluye:

- cabecera, folio, estado, expiración y total;
- líneas nominadas;
- summary derivado `{ product, option, qty, subtotal_centavos }`;
- snapshot de instrucciones de pago;
- flag `authorized_without_proof`;
- `distribution_status` derivado y, por línea, `delivered_to_member_at` y director responsable.

### 8.4 Pagos pendientes

```http
GET /api/v1/payment-obligations/pending
GET /api/v1/payment-obligations/pending?camporee_id=17
GET /api/v1/payment-obligations/pending?union_camporee_id=8
```

Fuentes:

- `field_payment_orders`
- `material_orders`
- `camporee_orders`

Cada pedido pendiente aparece como una obligación separada, aunque pertenezca a la misma sección y camporee.

Contrato:

```json
{
  "data": [
    {
      "source": "CAMPOREE_ORDER",
      "source_id": "uuid",
      "purpose": "CAMPOREE_MATERIALS",
      "folio": "PED20260001",
      "total_centavos": 425000,
      "currency": "MXN",
      "status": "PAYMENT_DUE",
      "action_required": "UPLOAD_PROOF",
      "camporee": { "type": "local", "id": 17, "name": "Camporí 2026" },
      "created_at": "2026-08-24T18:00:00Z"
    }
  ]
}
```

El read model no muta las fuentes ni crea un ledger nuevo.

### 8.5 Errores mínimos

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

## 9. PDF

Leyenda: **“Orden de pedido de camporee — no es comprobante fiscal”**.

Contenido:

1. Camporee, sección, club, LF, folio, expiración y total.
2. Consolidado para producción/almacén: producto + talla + cantidad.
3. Detalle nominado: miembro + artículo + talla + cantidad.
4. Instrucciones de banco/caja tomadas del snapshot.
5. Si se autorizó sin proof, leyenda auditada en el detalle administrativo; no presentarla como comprobante fiscal.

---

## 10. Plan de implementación TDD

### Task 1: Congelar canon y ADR del dominio

**Files:**
- Create: `docs/features/camporee-orders.md`
- Modify: `docs/features/README.md`
- Modify: `docs/features/camporees.md`
- Modify: `docs/api/ARCHITECTURE-DECISIONS.md`
- Modify: `docs/audit/DECISIONS-PENDING.md`

**Steps:**
1. Documentar requisitos EARS para elegibilidad, pago separado, excepción sin proof, múltiples pedidos y distribución nominada.
2. Registrar ADR: nuevo bounded context en vez de extender Materials/FieldPaymentOrders.
3. Registrar endpoints como `PLANNED`, nunca como runtime implementado.
4. Cerrar como resuelta la elegibilidad “solo inscritos”.
5. Ejecutar `git diff --check`.
6. Commit: `docs(camporees): define camporee orders domain`.

### Task 2: Crear schema, state machine y folio

**Files:**
- Create: `sacdia-backend/prisma/migrations/20260824190000_camporee_orders/migration.sql`
- Modify: `sacdia-backend/prisma/schema.prisma`
- Create: `sacdia-backend/src/camporee-orders/state-machine.ts`
- Create: `sacdia-backend/src/camporee-orders/state-machine.spec.ts`
- Create: `sacdia-backend/src/camporee-orders/folio.service.ts`
- Create: `sacdia-backend/src/camporee-orders/folio.service.spec.ts`
- Modify: `sacdia-backend/src/common/errors/error-codes.ts`

**Steps:**
1. Escribir tests rojos de todas las transiciones de §6.
2. Ejecutar `pnpm exec jest src/camporee-orders/state-machine.spec.ts --runInBand`; esperar FAIL por módulo inexistente.
3. Implementar state machine mínima y pasar tests.
4. Escribir tests rojos de folio por LF, incremento, concurrencia y año CDMX.
5. Implementar counter con lock `FOR UPDATE`.
6. Añadir tablas, checks por fila, XORs, índices y campos de entrega por línea; no crear unique sección + camporee.
7. Ejecutar `pnpm exec prisma validate`.
8. Ejecutar specs focalizadas.
9. No aplicar la migración a Neon.
10. Commit: `feat(camporee-orders): add schema state machine and folio`.

### Task 3: Implementar permisos y resolver territorial

**Files:**
- Create: `sacdia-backend/src/camporee-orders/permissions.ts`
- Create: `sacdia-backend/src/camporee-orders/camporee-order-actor.ts`
- Create: `sacdia-backend/src/camporee-orders/camporee-order-actor.spec.ts`
- Modify: `sacdia-backend/prisma/seeds/permissions.seed.sql`
- Modify: `sacdia-backend/prisma/seeds/role-permissions.seed.sql`

**Steps:**
1. Tests rojos para LF, Unión, División, sibling y actor sin scope.
2. Tests rojos para create limitado a sección activa.
3. Implementar resolución sobre helpers canónicos existentes.
4. Seedear permisos y grants de §7 siguiendo la convención de commits del workspace.
5. Ejecutar `pnpm exec jest src/camporee-orders/camporee-order-actor.spec.ts --runInBand`.
6. Commit: `feat(camporee-orders): enforce territorial permissions`.

### Task 4: Implementar biblioteca territorial

**Files:**
- Create: `sacdia-backend/src/camporee-orders/camporee-orders.module.ts`
- Create: `sacdia-backend/src/camporee-orders/catalog.controller.ts`
- Create: `sacdia-backend/src/camporee-orders/catalog.service.ts`
- Create: `sacdia-backend/src/camporee-orders/catalog.service.spec.ts`
- Create: `sacdia-backend/src/camporee-orders/dto/create-camporee-order-product.dto.ts`
- Create: `sacdia-backend/src/camporee-orders/dto/update-camporee-order-product.dto.ts`
- Create: `sacdia-backend/src/camporee-orders/dto/create-product-option.dto.ts`
- Modify: `sacdia-backend/src/app.module.ts`

**Steps:**
1. Tests rojos de CRUD soft-delete y scope exacto.
2. Tests de `LETTER`, `NUMERIC`, `NONE` y orden de opciones.
3. Tests que impidan cambiar owner y eliminar options históricas.
4. Implementar DTO validation y servicio mínimo.
5. Ejecutar `pnpm exec jest src/camporee-orders/catalog.service.spec.ts --runInBand`.
6. Ejecutar ESLint focalizado sin `--fix`.
7. Commit: `feat(camporee-orders): add territorial product library`.

### Task 5: Implementar settings y ofertas

**Files:**
- Create: `sacdia-backend/src/camporee-orders/offerings.controller.ts`
- Create: `sacdia-backend/src/camporee-orders/offerings.service.ts`
- Create: `sacdia-backend/src/camporee-orders/offerings.service.spec.ts`
- Create: `sacdia-backend/src/camporee-orders/dto/update-order-settings.dto.ts`
- Create: `sacdia-backend/src/camporee-orders/dto/replace-camporee-offerings.dto.ts`
- Modify: `sacdia-backend/src/camporees/dto/create-camporee.dto.ts`
- Modify: `sacdia-backend/src/camporees/dto/create-union-camporee.dto.ts`
- Modify: `sacdia-backend/src/camporees/camporees.service.ts`

**Steps:**
1. Tests rojos de ventana y `orders_enabled` fail-closed.
2. Tests de cascada territorial LF/Unión/División.
3. Tests de precio servidor, opción requerida y oferta inactiva.
4. Implementar GET/PATCH settings y GET/PUT offerings.
5. Exponer settings en detalle de camporee sin romper DTOs existentes.
6. Ejecutar `pnpm exec jest src/camporee-orders/offerings.service.spec.ts --runInBand`.
7. Commit: `feat(camporee-orders): configure camporee offerings`.

### Task 6: Emitir orden solo para inscritos

**Files:**
- Create: `sacdia-backend/src/camporee-orders/camporee-orders.controller.ts`
- Create: `sacdia-backend/src/camporee-orders/camporee-orders.service.ts`
- Create: `sacdia-backend/src/camporee-orders/camporee-orders.service.spec.ts`
- Create: `sacdia-backend/src/camporee-orders/eligibility.service.ts`
- Create: `sacdia-backend/src/camporee-orders/eligibility.service.spec.ts`
- Create: `sacdia-backend/src/camporee-orders/dto/create-camporee-order.dto.ts`
- Create: `sacdia-backend/src/camporee-orders/dto/list-camporee-orders.query.dto.ts`
- Create: `sacdia-backend/src/camporee-orders/dto/camporee-order.dto.ts`

**Steps:**
1. Test rojo: `camporee_member` approved de misma sección/camporee es elegible.
2. Tests rojos: `pending_approval`, rejected, inactive, otra sección, otro camporee y user ID libre.
3. Test rojo de camporee Unión con LF participante.
4. Test rojo: la misma sección puede crear dos pedidos con folios, totales y estados independientes.
5. Test rojo: una persona o material nuevo puede incluirse en un pedido suplementario sin modificar el anterior.
6. Test de idempotencia con mismo payload y conflicto con payload diferente.
7. Implementar TX: resolver actor → validar settings → validar líneas → snapshot → folio → orden.
8. Derivar summary y total desde líneas nominadas.
9. Ejecutar `pnpm exec jest src/camporee-orders/eligibility.service.spec.ts src/camporee-orders/camporee-orders.service.spec.ts --runInBand`.
10. Commit: `feat(camporee-orders): issue enrolled-member section orders`.

### Task 7: Implementar PDF, proof y ciclo operativo

**Files:**
- Create: `sacdia-backend/src/camporee-orders/pdf.service.ts`
- Create: `sacdia-backend/src/camporee-orders/pdf.service.spec.ts`
- Create: `sacdia-backend/src/camporee-orders/proof.service.ts`
- Create: `sacdia-backend/src/camporee-orders/proof.service.spec.ts`
- Create: `sacdia-backend/src/camporee-orders/proof-file-validation.pipe.ts`
- Create: `sacdia-backend/src/camporee-orders/distribution.service.ts`
- Create: `sacdia-backend/src/camporee-orders/distribution.service.spec.ts`
- Modify: `sacdia-backend/src/camporee-orders/camporee-orders.controller.ts`
- Modify: `sacdia-backend/src/camporee-orders/camporee-orders.service.ts`
- Create: `sacdia-backend/test/camporee-orders.e2e-spec.ts`

**Steps:**
1. Tests rojos de PDF: cabecera, consolidado, nominado e instrucciones snapshot.
2. Tests rojos de upload seguro y signed URL.
3. Tests rojos maker-checker approve/reject.
4. Tests rojos authorize-without-proof limitado a LF y con motivo obligatorio.
5. Test: proof posterior aprobado/rechazado no cambia `PAID|DELIVERED`.
6. Test: entrega LF → sección solo desde `PAID`.
7. Tests rojos: solo director activo de la sección puede marcar una línea y únicamente después de `DELIVERED`.
8. Tests rojos: entrega nominada idempotente y progreso derivado `NOT_STARTED|PARTIAL|COMPLETE`.
9. Test rojo: pedidos suplementarios mantienen distribuciones independientes.
10. Implementar servicios y endpoints mínimos.
11. Ejecutar `pnpm exec jest src/camporee-orders test/camporee-orders.e2e-spec.ts --runInBand`.
12. Commit: `feat(camporee-orders): add proof and two-level delivery`.

### Task 8: Implementar read model Pagos pendientes

**Files:**
- Create: `sacdia-backend/src/payment-obligations/payment-obligations.module.ts`
- Create: `sacdia-backend/src/payment-obligations/payment-obligations.controller.ts`
- Create: `sacdia-backend/src/payment-obligations/payment-obligations.service.ts`
- Create: `sacdia-backend/src/payment-obligations/payment-obligations.service.spec.ts`
- Create: `sacdia-backend/src/payment-obligations/dto/list-payment-obligations.query.dto.ts`
- Create: `sacdia-backend/src/payment-obligations/dto/payment-obligation.dto.ts`
- Modify: `sacdia-backend/src/app.module.ts`

**Steps:**
1. Tests rojos de mapeo para las tres fuentes.
2. Tests de `PAYMENT_DUE`, `UNDER_REVIEW`, `PROOF_REJECTED`, `ORDER_REVIEW`.
3. Test: dos pedidos de la misma sección/camporee producen dos obligaciones independientes.
4. Tests de sección activa y scope territorial.
5. Tests de filtros local/union camporee y orden estable.
6. Implementar proyección read-only sin FK ni mutaciones cruzadas.
7. Ejecutar `pnpm exec jest src/payment-obligations/payment-obligations.service.spec.ts --runInBand`.
8. Commit: `feat(payments): aggregate pending obligations`.

### Task 9: Implementar contratos y dominio móvil

**Files:**
- Create: `sacdia-app/lib/features/camporee_orders/domain/entities/camporee_order.dart`
- Create: `sacdia-app/lib/features/camporee_orders/domain/entities/camporee_order_product.dart`
- Create: `sacdia-app/lib/features/camporee_orders/domain/entities/camporee_order_offering.dart`
- Create: `sacdia-app/lib/features/camporee_orders/domain/repositories/camporee_orders_repository.dart`
- Create: `sacdia-app/lib/features/camporee_orders/data/models/camporee_order_model.dart`
- Create: `sacdia-app/lib/features/camporee_orders/data/models/camporee_order_product_model.dart`
- Create: `sacdia-app/lib/features/camporee_orders/data/datasources/camporee_orders_remote_data_source.dart`
- Create: `sacdia-app/lib/features/camporee_orders/data/repositories/camporee_orders_repository_impl.dart`
- Create: `sacdia-app/lib/features/payment_orders/domain/entities/payment_obligation.dart`
- Create: `sacdia-app/lib/features/payment_orders/data/models/payment_obligation_model.dart`
- Modify: `sacdia-app/lib/core/constants/api_endpoints.dart`

**Steps:**
1. Tests rojos de parsing local/union, talla null, proof exception y distribución por línea.
2. Tests de create payload con `camporee_member_id` y sin montos.
3. Tests de mapping `source → detail route` para obligaciones.
4. Implementar datasource/repository con Clean Architecture.
5. Ejecutar `flutter test test/features/camporee_orders test/features/payment_orders`.
6. Commit: `feat(camporee-orders): add mobile domain and data contracts`.

### Task 10: Implementar flujo móvil

**Files:**
- Create: `sacdia-app/lib/features/camporee_orders/presentation/providers/camporee_orders_providers.dart`
- Create: `sacdia-app/lib/features/camporee_orders/presentation/views/camporee_order_catalog_view.dart`
- Create: `sacdia-app/lib/features/camporee_orders/presentation/views/camporee_member_order_view.dart`
- Create: `sacdia-app/lib/features/camporee_orders/presentation/views/camporee_order_review_view.dart`
- Create: `sacdia-app/lib/features/camporee_orders/presentation/views/camporee_order_detail_view.dart`
- Modify: `sacdia-app/lib/features/camporees/presentation/views/camporee_detail_view.dart`
- Modify: `sacdia-app/lib/features/payment_orders/presentation/views/payment_orders_view.dart`
- Modify: `sacdia-app/lib/core/config/route_names.dart`
- Modify: `sacdia-app/lib/core/config/router.dart`
- Modify: `sacdia-app/assets/translations/es.json`
- Modify: `sacdia-app/assets/translations/en.json`
- Modify: `sacdia-app/assets/translations/fr.json`
- Modify: `sacdia-app/assets/translations/pt-BR.json`
- Create: `sacdia-app/test/features/camporee_orders/presentation/camporee_order_flow_test.dart`

**Steps:**
1. CTA Pedidos solo con settings activos y sección inscrita.
2. Selector usa roster del camporee, nunca toda la membresía.
3. Captura artículos/talla por persona y muestra consolidado antes de emitir.
4. Bloquear doble tap; después de emitir, permitir iniciar otro pedido sin alterar los existentes.
5. Historial muestra todos los pedidos de la sección con folio, total, pago y distribución independientes.
6. Detalle permite PDF, proof, cancelación y seguimiento.
7. Con orden `DELIVERED`, el director puede marcar cada línea como entregada al miembro y ver progreso `NOT_STARTED|PARTIAL|COMPLETE`.
8. Pagos pendientes combina fuentes y navega por `source`.
9. Probar loading, vacío, error, disabled, closed, múltiples pedidos, distribución parcial y success.
10. Ejecutar `flutter test test/features/camporee_orders test/features/payment_orders`.
11. Ejecutar `flutter analyze`.
12. Commit: `feat(camporee-orders): add enrolled-member ordering flow`.

### Task 11: Preparar contratos y handoff admin

**Files:**
- Create: `sacdia-admin/src/lib/api/camporee-orders.ts`
- Create: `sacdia-admin/src/lib/types/camporee-orders.ts`
- Create: `sacdia-admin/src/lib/api/payment-obligations.ts`
- Create: `sacdia-admin/src/lib/types/payment-obligations.ts`
- Create: `docs/plans/handoffs/camporee-orders-admin-handoff.md`

**Steps:**
1. Tipar productos, ofertas, múltiples órdenes, distribución por línea, proof y obligaciones.
2. Añadir funciones API exactas y mapeo de errores.
3. Tests de estados, montos, múltiples folios, progreso de distribución y rutas de navegación.
4. Handoff especifica permisos, DTOs, loading/empty/error/success, excepción sin proof y entrega en dos niveles.
5. No diseñar visualmente fuera del ownership de Codex.
6. Ejecutar Vitest focalizado.
7. Commit: `feat(admin): add camporee orders contracts`.

### Task 12: Implementar operación admin

**Files:**
- Create: `sacdia-admin/src/components/camporee-orders/`
- Create: `sacdia-admin/src/app/(dashboard)/dashboard/campamentos/pedidos/catalogo/page.tsx`
- Create: `sacdia-admin/src/app/(dashboard)/dashboard/campamentos/pedidos/bandeja/page.tsx`
- Modify: `sacdia-admin/src/components/camporees/camporee-form-dialog.tsx`
- Modify: `sacdia-admin/src/components/camporees/union-camporee-form-dialog.tsx`
- Modify: `sacdia-admin/src/components/camporees/camporee-detail-tabs.tsx`
- Modify: `sacdia-admin/src/app/(dashboard)/dashboard/payment-orders/page.tsx`
- Modify: `sacdia-admin/messages/es.json`
- Modify: `sacdia-admin/messages/en.json`
- Modify: `sacdia-admin/messages/fr.json`
- Modify: `sacdia-admin/messages/pt-BR.json`
- Create: `sacdia-admin/src/components/camporee-orders/camporee-orders-tab.test.tsx`
- Create: `sacdia-admin/src/components/camporee-orders/camporee-order-review.test.tsx`
- Create: `sacdia-admin/src/components/payment-orders/payment-obligations-client.test.tsx`

**Steps:**
1. Configurar settings y ofertas local/union.
2. Catálogo territorial respeta owner y ancestros read-only.
3. Tab Pedidos lista todos los folios y muestra primero consolidado y luego nominado en cada detalle.
4. Review normal es acción primaria; authorize-without-proof es secundaria, exige motivo y confirmación.
5. Entrega LF → sección solo desde PAID; admin visualiza el progreso posterior por miembro sin suplantar al director.
6. Página Pagos pendientes representa las tres fuentes sin mezclar acciones.
7. Probar permisos, scopes y estados UI.
8. Ejecutar `pnpm exec vitest run` focalizado.
9. Ejecutar `pnpm typecheck` y `pnpm lint`; no ejecutar build.
10. Commit: `feat(admin): manage camporee orders`.

### Task 13: Canonizar runtime y cerrar verificación

**Files:**
- Modify: `docs/features/camporee-orders.md`
- Modify: `docs/features/camporees.md`
- Modify: `docs/features/README.md`
- Modify: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- Modify: `docs/api/FRONTEND-INTEGRATION-GUIDE.md`
- Modify: `docs/api/SECURITY-GUIDE.md`
- Modify: `docs/api/TESTING-GUIDE.md`
- Modify: `docs/database/schema.prisma`
- Modify: `docs/database/SCHEMA-REFERENCE.md`
- Modify: `docs/audit/REALITY-MATRIX.md`

**Steps:**
1. Promover `PLANNED` a `IMPLEMENTED` solo tras verificación real.
2. Sincronizar schema documental desde el backend efectivo.
3. Ejecutar Jest focalizado de `camporee-orders` y `payment-obligations`.
4. Ejecutar Flutter tests focalizados y `flutter analyze`.
5. Ejecutar Vitest focalizado, `pnpm typecheck` y lint admin.
6. Ejecutar `git diff --check` en cada repositorio.
7. No ejecutar builds.
8. Documentar desviaciones y fallos preexistentes sin ampliar alcance.
9. Commit: `docs(camporees): canonize camporee orders runtime`.

---

## 11. Criterios de aceptación

1. Camporee con pedidos desactivados no muestra CTA y rechaza emisión.
2. Solo `camporee_members` activos `registered|approved` pueden aparecer o enviarse.
3. Director de Panteras asigna playeras/tallas, gorras y libros a personas concretas.
4. Cada pedido muestra un consolidado derivado y detalle nominado con su propio folio.
5. La misma sección puede emitir pedidos suplementarios con folio, pago, proof y estado independientes.
6. Precio y total nunca se aceptan desde cliente.
7. Proof normal requiere maker-checker y mueve a PAID.
8. Director/asistente LF autoriza sin proof con motivo; entrega queda habilitada.
9. Proof posterior a la excepción queda auditado sin reabrir ni cambiar la orden.
10. LF marca el pedido como entregado a la sección solo desde `PAID`.
11. Después de `DELIVERED`, el director marca artículos por miembro y el avance pasa de `NOT_STARTED` a `PARTIAL` y `COMPLETE`.
12. Otro rol de sección, otro club o una orden aún no entregada no puede registrar distribución.
13. Camporee de Unión cobra y revisa en LF de la sección.
14. Producto División/Unión/LF solo aparece dentro de su cascada territorial.
15. Pagos pendientes muestra inscripción, materiales y cada pedido como filas separadas.
16. Ninguna operación de pedido modifica `field_payment_orders`, `material_orders` o `camporee_payments`.
17. No se ejecutan builds.

---

## 12. Review Workload Forecast

- **Riesgo de superar 400 líneas:** HIGH.
- **Chained/stacked PRs:** obligatorios salvo `size:exception` explícita.

### Slices recomendados

1. **Backend A:** schema + state machine + folio + permisos.
2. **Backend B:** catálogo + settings + ofertas.
3. **Backend C:** elegibilidad + emisión múltiple + PDF + proof + entrega en dos niveles.
4. **Backend D:** PaymentObligations + contratos canónicos.
5. **App:** dominio/data + flujo + Pagos pendientes.
6. **Admin contracts:** tipos/API/handoff.
7. **Admin UI:** implementación visual sobre contratos cerrados.

Cada slice mantiene tests y docs del comportamiento dentro del mismo work unit.

---

## 13. Riesgos

| Riesgo | Mitigación |
|---|---|
| Duplicar patrones de órdenes | Copiar comportamiento probado; extraer shared primitive solo si es mecánico y cubierto por tests |
| Confundir inscripción y pedidos | Tab/folio/purpose/estados separados; read model solo lectura |
| Usar membresía en vez de inscripción | FK y guard obligatorio sobre `camporee_member_id` |
| Excepción sin proof se vuelve normal | Permiso estrecho, motivo, acción secundaria y auditoría |
| Total cabecera diverge | Transacción única y tests; no CHECK cross-row falso |
| Actor conoce UUID ajeno | Scope territorial y ownership en cada mutación |
| Cambiar producto/talla histórica | Snapshots en línea y soft-delete |
| Duplicar accidentalmente un pedido | Idempotency key, confirmación UI y folio independiente; no bloquear pedidos suplementarios legítimos |
| Confundir entrega LF con distribución al miembro | Estado `DELIVERED` solo para LF → sección y progreso derivado desde líneas |
| Marcar entrega nominada desde otro scope | Permiso `distribute`, director activo y ownership de sección en cada mutación |
| Plan demasiado grande | PRs encadenados de §12 |

---

## 14. Definition of Done

- Dominio `camporee-orders` aislado y documentado.
- Catálogo territorial y ofertas por camporee operativos.
- Solo inscritos elegibles.
- Múltiples pedidos de sección con líneas nominadas y consolidado derivado por folio.
- Pago normal y excepción auditada sin comprobante.
- PDF, proof privado, revisión y entrega LF → sección.
- Director registra entrega por línea al miembro y el sistema deriva el progreso de distribución.
- Pagos pendientes unifica lectura sin fusionar obligaciones.
- Tests backend/app/admin cubren happy path, errores y autorización.
- Docs API, seguridad, testing, DB y feature reflejan runtime real.
- Cambios divididos en work units revisables.
- Ningún build ejecutado.
