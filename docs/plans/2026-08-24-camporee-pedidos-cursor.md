# Pedidos de camporee — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Estado:** READY FOR REVIEW — no codear hasta que el usuario apruebe este documento  
**Fecha:** 2026-08-24  
**Alcance:** `sacdia-backend`, `sacdia-app`, `sacdia-admin`, docs canónicas  
**Ownership:** Codex = backend + app + contratos + docs. Cursor Composer = admin visual sobre contratos ya cerrados.

**Goal:** Que el campo local, la unión o la división publique un catálogo de artículos (playeras, gorras, pañoletas, libros, materiales de club); que cada camporee elija qué se puede pedir y a qué precio; que el director de la sección pida por persona con talla; que el sistema consolide una orden de pago de la sección; que se pague en el Campo Local con el mismo rito de comprobante que materiales / órdenes territoriales.

**Architecture:** Dominio nuevo `camporee-orders`. No extender `resources` (archivos digitales), ni `club_inventory`, ni `material_products` (stock de LF, líneas anónimas), ni `field_payment_orders.purpose` (costo uniforme INSURANCE|CAMPOREE). Copiar patrones vivos: folio FOR UPDATE, state machine pura, proof multipart + magic bytes, PDFKit, maker-checker, bandeja LF. Dos capas: biblioteca territorial + oferta del camporee. Líneas nominadas (beneficiario + artículo + variante). Cabecera de sección = orden de pago. Made-to-order en v1 (sin kardex).

**Tech Stack:** NestJS 11 + Prisma 7 + PostgreSQL + R2 + PDFKit; Flutter + Riverpod; Next.js 16 + TanStack Query + shadcn/ui.

---

## 0. Runtime que ancla este plan (verificar antes de codear)

Leer en este orden:

1. `AGENTS.md`, `docs/steering/agent-ownership.md`
2. Este plan
3. `docs/features/camporees.md` (órdenes territoriales, union cobra LF)
4. `docs/database/schema.prisma` — `Material*` (~4511), `field_payment_orders` (~4917), `local_camporees` / `union_camporees`, `camporee_clubs`, `camporee_members`, `camporee_payments`
5. `sacdia-backend/src/materials/orders/` (folio, SM, receipts)
6. `sacdia-backend/src/field-payment-orders/` (beneficiarios, proof, PDF, maker-checker, configs de caja)
7. `sacdia-backend/src/camporees/`
8. Admin: `sacdia-admin/src/components/camporees/camporee-detail-tabs.tsx`, `src/components/payment-orders/`
9. App: `sacdia-app/lib/features/camporees/`, `lib/features/payment_orders/`

### Qué NO es este feature

| Módulo | Por qué no sirve drop-in |
|---|---|
| `resources` | Archivos digitales (PDF/audio). Scope `system\|union\|local_field`. Cero tallas, cero pago. |
| `club_inventory` | Bienes del club (carpas, cuerdas). No se vende. |
| `material_products` | Catálogo **solo LF**, stock, 1 eje de variante (`talla` XOR `color`), líneas **sin persona**. |
| `field_payment_orders` | Purpose `INSURANCE\|CAMPOREE`, `unit_cost_centavos` uniforme, 1 línea = 1 inscrito. |
| `camporee_payments` `payment_type=materials` | Ledger suelto por miembro. Sin catálogo ni consolidado. |

### Patrones a copiar (no importar tablas)

- Folio: `src/materials/orders/folio.service.ts` y `src/field-payment-orders/folio.service.ts` — counter `FOR UPDATE`, año `America/Mexico_City`, unique por LF.
- SM pura: `src/field-payment-orders/state-machine.ts`.
- Proof: `src/field-payment-orders/field-payment-order-proof.service.ts` + `proof-file-validation.pipe.ts` (JPG/PNG/WebP/PDF ≤10 MB, magic bytes, R2 privado, signed ~900s).
- PDF: `src/field-payment-orders/field-payment-order-pdf.service.ts`.
- Actor: `src/field-payment-orders/order-actor.ts`.
- Config de caja/banco: **reusar** `field_payment_order_configs` (una caja LF para inscripción y pedidos). No acoplar a `material_config`.
- Admin bandeja: `sacdia-admin/src/components/payment-orders/`.
- App emisión: `sacdia-app/lib/features/payment_orders/`.

---

## 1. Decisiones cerradas

### Producto

1. Nombre de dominio: **Pedidos de camporee**. Código: módulo `camporee-orders`. Tablas `camporee_order_*`. UI: pestaña **Pedidos**. No llamar “Recursos”.
2. Se configura **por camporee** (`orders_enabled`, `orders_opens_at?`, `orders_deadline?`). Default `orders_enabled=false`.
3. Catálogo territorial de dos capas:
   - Biblioteca: producto dueño `division | union | local_field`.
   - Oferta: producto × camporee (local XOR unión) con precio de *este* evento.
4. Unión: misma política que inscripción. Unión (o división) define oferta; **el Campo Local cobra**; el traslado LF → Unión es físico, fuera del sistema.
5. Emisor: director / subdirector / secretario-tesorero / tesorero de la **sección inscrita** (`camporee_clubs` `registered|approved`).
6. Captura: por beneficiario, N artículos. Cada línea = persona + oferta + opción de talla (si aplica) + qty + precio snapshot.
7. Agregado de sección (16 playeras, 13 pines…) se **calcula** de las líneas y se imprime en el PDF. No es la fuente de verdad.
8. Una orden activa no terminal por `(club_section_id, camporee)`. Tras `PAID|DELIVERED|CANCELLED|EXPIRED` se puede emitir otra oleada.
9. Create atómico → `ISSUED` + folio. Sin draft. Cambio = cancelar + nueva orden (si aún no está `PAID`).
10. Pago: caja o banco del LF, PDF, comprobante. Mismo rito operativo que materiales / órdenes territoriales. **No** se mezcla con la orden de inscripción.
11. Excepción LF: `director-lf` y `assistant-lf` pueden marcar pagado **sin** comprobante (`authorized_without_proof`). Eso autoriza entrega. El comprobante queda pendiente y se puede cargar después. Queda auditado (quién, cuándo).
12. Maker-checker en approve de comprobante: quien subió no aprueba.
13. v1 **made-to-order**: no stock, no decremento, no `MaterialDisponibilidad`.
14. Género (hombre/mujer): **dos productos** (Playera hombre / Playera mujer), cada uno con opciones de talla. Un solo eje de variante en v1.
15. Esquema de talla en el producto: `letter | numeric | none`. Opciones = etiquetas libres (`S`,`M`,`L` o `10`,`12`,`14`). `none` = pines, libros.
16. Precio en **centavos** (`Int`). Snapshot en línea y total en cabecera. El cliente no manda montos.
17. No Finance ledger. No `camporee_payments` para pedidos (ese ledger queda de inscripción).
18. No feature flag `system_config` por LF: el kill switch es `orders_enabled` del camporee.
19. Jueces y staff del camporee **fuera de v1**.

### Asunción de elegibilidad (no confirmada en chat; locked para no bloquear)

20. Beneficiario v1 = usuario con **membresía activa** en la `club_section_id` de la orden, y esa sección inscrita en el camporee. **No** se exige `camporee_members` (el flujo payment-first de inscripción puede ir en paralelo).  
    Si producto quiere “solo ya inscritos”, el cambio es un guard en `assertBeneficiaryEligible()` — no toca schema.

### Técnicas

21. Montos solo backend. Idempotency-Key opcional en create/approve/authorize.
22. Proof multipart Nest. Sin upload-intents.
23. Folio prefijo `PED{year}{####}` (no chocar con `SOL` materiales ni `ORD` territoriales). Counter propio `camporee_order_folio_counters`.
24. Expiración lazy de `ISSUED` sin proof: `min(orders_deadline, created_at + expiry_days)`. Default 15 días, key `camporee_orders.expiry_days` en `system_config`. Órdenes `PAID` (con o sin proof) **no** expiran.
25. Permisos nuevos `camporee-orders:*`. No reusar `materiales:*` ni `field-payment-orders:*` para mutar pedidos (sí se **lee** `field_payment_order_configs` para el PDF).
26. Contract-first. Docs canónicas en el mismo trabajo que el schema/API.
27. Conventional commits. Nunca `Co-Authored-By`. No builds. No aplicar migración a Neon desde el agente.
28. Tests del área + typecheck/analyze antes de cerrar fase. Fallos preexistentes se anotan, no se arreglan.

---

## 2. Fuera de v1

- Stock / kardex / “agotado”.
- Envío a domicilio (entrega = recoger en campo o en el evento).
- Segundo eje de variante (talla + color + género en un SKU).
- Pedido por el miembro desde su propia app (solo liderazgo de sección).
- Pedidos de jueces/staff.
- Pago parcial, split, o mezclar inscripción + merch en un folio.
- Catálogo vendible directo sin camporee (eso sigue siendo Materiales).
- i18n de etiquetas de talla más allá del string que cargue el operador.
- Reembolso automatizado.

---

## 3. Modelo de datos

Migración backend: `sacdia-backend/prisma/migrations/20260824180000_camporee_orders/migration.sql`  
Prisma: `sacdia-backend/prisma/schema.prisma`  
Canon: copiar a `docs/database/schema.prisma` en la misma fase.

### 3.1 Flags en el camporee

En `local_camporees` y `union_camporees`:

```text
orders_enabled     Boolean   @default(false)
orders_opens_at    DateTime? @db.Timestamptz(6)
orders_deadline    DateTime? @db.Timestamptz(6)
```

Ventana: si `orders_enabled=false` → 403 `CAMPOREE_ORDERS_DISABLED`.  
Si `now < orders_opens_at` → 422 `CAMPOREE_ORDERS_NOT_OPEN`.  
Si `now > orders_deadline` (inclusivo como el resto de deadlines de camporee: el día límite cuenta; usar el mismo helper de timezone IANA del camporee) → 422 `CAMPOREE_ORDERS_CLOSED`.  
`orders_opens_at` / `orders_deadline` nulos = abierto desde ya / sin cierre extra (sigue valiendo `end_date` del evento como tope duro: no emitir después de `end_date` local).

### 3.2 Biblioteca territorial

```text
enum camporee_order_owner_scope_enum { division union local_field }
enum camporee_order_size_scheme_enum { letter numeric none }
enum camporee_order_status_enum {
  ISSUED
  PROOF_SUBMITTED
  PROOF_REJECTED
  PAID
  DELIVERED
  CANCELLED
  EXPIRED
}
enum camporee_order_proof_status_enum { SUBMITTED APPROVED REJECTED }
```

`camporee_order_products`

| Columna | Notas |
|---|---|
| `camporee_order_product_id` | UUID PK |
| `owner_scope` | `division\|union\|local_field` |
| `owner_division_id` | NOT NULL iff scope=division |
| `owner_union_id` | NOT NULL iff scope=union |
| `owner_local_field_id` | NOT NULL iff scope=local_field |
| `title` | varchar(200) |
| `description` | text? |
| `size_scheme` | letter / numeric / none |
| `club_type_id` | int? — NULL = todos |
| `active` | bool default true |
| `created_by_id`, `modified_by_id` | uuid |
| timestamps | timestamptz |

CHECK: exactamente un owner id según scope.

`camporee_order_product_options`

| Columna | Notas |
|---|---|
| `camporee_order_product_option_id` | UUID PK |
| `camporee_order_product_id` | FK |
| `label` | varchar(40) — `S`, `M`, `12`… |
| `sort_order` | int |
| `active` | bool |

Unique `(product_id, label)`.  
Si `size_scheme=none` el producto **no** tiene opciones; las líneas van con `option_id` NULL.  
Si `letter|numeric` create de oferta exige ≥1 opción activa.

### 3.3 Oferta del camporee

`camporee_order_offerings`

| Columna | Notas |
|---|---|
| `camporee_order_offering_id` | UUID PK |
| `local_camporee_id` | int? |
| `union_camporee_id` | int? |
| `camporee_order_product_id` | FK |
| `price_centavos` | int > 0 |
| `active` | bool |
| `created_by_id` | uuid |
| timestamps | |

CHECK: exactamente un camporee (local XOR union), igual que `field_payment_orders`.  
Unique `(local_camporee_id, product_id)` parcial / `(union_camporee_id, product_id)` parcial.  
El producto debe ser visible para el dueño del camporee (cascada: un camporee local puede ofertar productos de su LF, su unión o su división; un camporee de unión, productos de su unión o su división — no de un LF ajeno).

### 3.4 Orden de sección

`camporee_orders`

| Columna | Notas |
|---|---|
| `camporee_order_id` | UUID PK |
| `local_field_id` | int — LF que cobra (siempre el del club emisor) |
| `club_id`, `club_section_id` | int |
| `local_camporee_id` / `union_camporee_id` | XOR |
| `folio` | int |
| `folio_reference` | varchar(16) `PED20260001` |
| `status` | enum |
| `currency` | `MXN` |
| `total_centavos` | int — suma de líneas |
| `authorized_without_proof` | bool default false |
| `authorized_by_id` / `authorized_at` | excepción LF |
| `issued_by_id` | uuid |
| `approved_by_id` / `approved_at` | approve de proof |
| `delivered_by_id` / `delivered_at` | |
| `cancelled_by_id` / `cancelled_at` / `cancel_reason` | |
| `expired_at` | |
| `expires_at` | |
| `idempotency_key` | uuid? unique por emisor |
| timestamps | |

Unique `(local_field_id, folio_reference)`.  
Unique parcial: una orden activa por sección+camporee donde `status IN ('ISSUED','PROOF_SUBMITTED','PROOF_REJECTED')`. `PAID` no bloquea una oleada nueva (pines extra, etc.).

`camporee_order_lines`

| Columna | Notas |
|---|---|
| `camporee_order_line_id` | UUID PK |
| `camporee_order_id` | FK cascade |
| `sequence` | int |
| `beneficiary_user_id` | uuid |
| `offering_id` | uuid — snapshot de qué se pidió |
| `product_id` | uuid — denormalizado para el PDF si desactivan oferta |
| `option_id` | uuid? |
| `product_title_snapshot` | varchar |
| `option_label_snapshot` | varchar? |
| `qty` | int ≥ 1, v1 max 5 |
| `unit_price_centavos` | int |
| `line_total_centavos` | qty * unit |

Unique `(order_id, beneficiary_user_id, offering_id, option_id)`.  
CHECK: `line_total = qty * unit_price`.  
CHECK cabecera: `total_centavos = sum(lines)`.

`camporee_order_proofs` — copiar columnas de `field_payment_order_proofs`.

`camporee_order_folio_counters` — `(local_field_id, year)` PK, `last_folio`.

Índices: LF+status, section+status, camporee local/unión, beneficiary.

---

## 4. Máquina de estados

Archivo: `sacdia-backend/src/camporee-orders/state-machine.ts` (puro, sin Prisma). Spec: `state-machine.spec.ts`.

```
ISSUED ──► PROOF_SUBMITTED ──► PAID ──► DELIVERED
  │              │
  │              └──► PROOF_REJECTED ──► PROOF_SUBMITTED (mismo folio)
  │                        └──► CANCELLED
  │                        └──► PAID          (authorize-without-proof)
  ├──► PAID                                   (authorize-without-proof)
  ├──► CANCELLED
  └──► EXPIRED                                (lazy, solo ISSUED)

PAID (authorized_without_proof=true) aún acepta POST /proof
  → no cambia status; proof queda SUBMITTED hasta review.
  Approve de ese proof: marca proof APPROVED, no re-dispara PAID.
```

Terminales: `DELIVERED`, `CANCELLED`, `EXPIRED`.  
`PAID` no es terminal (falta entregar).

Transición inválida → 422 `CAMPOREE_ORDER_INVALID_TRANSITION`.

---

## 5. Permisos

Seed: `sacdia-backend/prisma/seeds/permissions.seed.sql` + `role-permissions.seed.sql`.  
Constante TS: `sacdia-backend/src/camporee-orders/permissions.ts`.

| Permiso | Quién | Uso |
|---|---|---|
| `camporee-orders:read` | liderazgo sección + LF/unión/división/admin | listar, detalle, PDF, proof |
| `camporee-orders:catalog-manage` | director/assistant de LF, unión, división + admin | CRUD biblioteca en su scope |
| `camporee-orders:offering-configure` | dueño del camporee (LF para local, unión para union) + admin | activar oferta + precio + flags del camporee |
| `camporee-orders:create` | director, deputy, secretary-treasurer, treasurer (club) | emitir / cancelar propia |
| `camporee-orders:upload-proof` | mismos + quien tenga create | subir comprobante |
| `camporee-orders:review` | director-lf, assistant-lf, admin | approve/reject proof |
| `camporee-orders:authorize-without-proof` | **solo** director-lf, assistant-lf, admin | excepción de caja |
| `camporee-orders:deliver` | director-lf, assistant-lf, admin | marcar entregado |

Guards: `JwtAuthGuard` + `PermissionsGuard` + resource `active_assignment` en create (sección activa). Review recorta al territorio del actor (mismo patrón que `payment-orders/review-queue`).

---

## 6. Contratos HTTP

Prefijo `/api/v1`. Envelope `{ status, data }`. Errores: `ErrorCode` en `sacdia-backend/src/common/errors/error-codes.ts` con prefijo `CAMPOREE_ORDER_*`.

### Catálogo

| Método | Path | Permiso |
|---|---|---|
| POST | `/camporee-order-products` | catalog-manage |
| GET | `/camporee-order-products` | read (filtrado por territorio; query `scope`) |
| GET | `/camporee-order-products/:id` | read |
| PATCH | `/camporee-order-products/:id` | catalog-manage |
| POST | `/camporee-order-products/:id/options` | catalog-manage |
| PATCH | `/camporee-order-product-options/:id` | catalog-manage |

No hard-delete. `active=false`. No editar `owner_scope` después de create.

### Oferta + flags del camporee

| Método | Path | Permiso |
|---|---|---|
| PATCH | `/camporees/:camporeeId/orders-settings` | offering-configure |
| PATCH | `/union-camporees/:camporeeId/orders-settings` | offering-configure |
| GET | `/camporees/:camporeeId/order-offerings` | read |
| GET | `/union-camporees/:camporeeId/order-offerings` | read |
| PUT | `/camporees/:camporeeId/order-offerings` | offering-configure |
| PUT | `/union-camporees/:camporeeId/order-offerings` | offering-configure |

`orders-settings` body: `{ orders_enabled, orders_opens_at, orders_deadline }`.  
PUT offerings: lista `{ product_id, price_centavos, active }`. Reemplazo idempotente del set del camporee.

GET detalle de camporee (ya existente) debe incluir los tres campos nuevos para que app/admin no hagan round-trip extra. Extender DTOs en `src/camporees/`.

### Pedidos

| Método | Path | Permiso |
|---|---|---|
| POST | `/camporees/:camporeeId/orders` | create |
| POST | `/union-camporees/:camporeeId/orders` | create |
| GET | `/camporee-orders` | read |
| GET | `/camporee-orders/review-queue` | review |
| GET | `/camporee-orders/:orderId` | read |
| GET | `/camporee-orders/:orderId/document` | read |
| GET | `/camporee-orders/:orderId/proof` | read (signed URL) |
| POST | `/camporee-orders/:orderId/proof` | upload-proof |
| POST | `/camporee-orders/:orderId/cancel` | create (propia) o review (LF) |
| POST | `/camporee-orders/:orderId/approve` | review |
| POST | `/camporee-orders/:orderId/reject` | review — body `{ reason }` obligatorio |
| POST | `/camporee-orders/:orderId/authorize-without-proof` | authorize-without-proof |
| POST | `/camporee-orders/:orderId/deliver` | deliver |

Create body (montos **prohibidos** en el payload):

```json
{
  "lines": [
    {
      "beneficiary_user_id": "uuid",
      "offering_id": "uuid",
      "option_id": "uuid | null",
      "qty": 1
    }
  ]
}
```

Validaciones create:

- Camporee activo, `orders_enabled`, ventana abierta.
- Sección activa del actor inscrita (`camporee_clubs`).
- Unión: LF del emisor en `union_camporee_local_fields` activo.
- Config de caja/banco del LF presente (`field_payment_order_configs.active`) — si falta, 422 `FIELD_PAYMENT_ORDER_CONFIG_NOT_FOUND` (reusar código; el PDF no puede imprimirse).
- Cada offering activa del **mismo** camporee.
- `option_id` requerido si el producto tiene `size_scheme != none`; prohibido si `none`.
- Beneficiario elegible (decisión 20). Sin duplicar unique de línea.
- ≥1 línea. Total = suma backend.
- No hay otra orden activa de esa sección+camporee.

Respuesta create/get incluye:

- cabecera (folio, status, total, expires_at, authorized_without_proof)
- `lines[]` nominadas
- `summary[]`: `{ product_title, option_label, qty, subtotal_centavos }` (el consolidado “16 playeras M, 5 playeras L…”)
- instrucciones de pago (banco/caja) snapshot **al emitir** (denormalizar 4 campos de config en la orden en create, como materials hace al aprobar). Snapshot en ISSUED, no en PAID: el director imprime de inmediato.

Códigos de error nuevos (mínimo):

```
CAMPOREE_ORDERS_DISABLED
CAMPOREE_ORDERS_NOT_OPEN
CAMPOREE_ORDERS_CLOSED
CAMPOREE_ORDER_NOT_FOUND
CAMPOREE_ORDER_INVALID_TRANSITION
CAMPOREE_ORDER_FORBIDDEN
CAMPOREE_ORDER_ACTIVE_EXISTS
CAMPOREE_ORDER_LINES_REQUIRED
CAMPOREE_ORDER_OPTION_REQUIRED
CAMPOREE_ORDER_OPTION_FORBIDDEN
CAMPOREE_ORDER_OFFERING_INVALID
CAMPOREE_ORDER_ELIGIBILITY_FAILED
CAMPOREE_ORDER_MAKER_CHECKER
CAMPOREE_ORDER_PROOF_INVALID_FILE
CAMPOREE_ORDER_REJECT_REASON_REQUIRED
CAMPOREE_ORDER_PRODUCT_SCOPE_INVALID
```

---

## 7. Fulfillment (qué cambia al pagar)

A diferencia de inscripción, **no** se crean `camporee_members`.  
`PAID` = el Campo Local reconoce la deuda saldada y puede entregar el material.  
`DELIVERED` = el operador LF confirma que el bulto de la sección salió.

Authorize-without-proof: `ISSUED|PROOF_REJECTED` → `PAID`, `authorized_without_proof=true`. Entrega permitida. Proof posterior es auditoría, no gate.

---

## 8. PDF

Copiar `FieldPaymentOrderPdfService`. Leyenda: “Orden de pedido de camporee — no es comprobante fiscal”.

Páginas:

1. Encabezado: camporee, sección, club, folio `PED…`, vencimiento, total.
2. Consolidado (para el taller / almacén): producto + talla + qty.
3. Detalle nominado: persona, artículos, tallas.
4. Instrucciones de pago (banco y/o caja del snapshot).

---

## 9. Superficies cliente

### App (`sacdia-app`)

Feature nueva `lib/features/camporee_orders/` (clean architecture, espejo de `payment_orders`).

- En detalle de camporee: si `orders_enabled`, CTA **Pedidos** (no mezclar con “Órdenes de pago” de inscripción).
- Flujo: elegir ofertas → por cada miembro de la sección, checkboxes de artículos + picker de talla → resumen consolidado → emitir → PDF → subir comprobante.
- Lista de órdenes de la sección para ese camporee.
- Estados loading/error fail-closed. Si `orders_enabled=false`, no pintar el CTA.

Rutas GoRouter bajo el detalle de camporee, query `type=local|union` como payment-orders.

Tests: `test/features/camporee_orders/`.

### Admin (`sacdia-admin`)

Contratos en `src/lib/api/camporee-orders.ts` + server actions si el patrón del módulo de payment-orders lo usa.

1. Settings en create/edit de camporee local y unión: switch Pedidos + fechas.
2. Tab **Pedidos** en `camporee-detail-tabs.tsx` (local y unión): ofertas, bandeja del camporee, detalle, authorize, deliver.
3. Catálogo territorial: ruta `/dashboard/campamentos/pedidos/catalogo` (LF ve los suyos + ancestros de solo lectura; unión/división crean en su scope).
4. Bandeja LF global opcional: reutilizar layout de `payment-orders-tray.tsx` filtrada a pedidos, o tab extra en la bandeja existente **sin** mezclar purpose INSURANCE/CAMPOREE. Preferir bandeja propia `/dashboard/campamentos/pedidos/bandeja` para no ensuciar inscripción.

Composer implementa visual **después** de que backend + `docs/api/ENDPOINTS-LIVE-REFERENCE.md` existan.

---

## 10. Fases de ejecución

Branch: `feat/camporee-orders` en backend, app, admin. Docs en el repo raíz sobre `development`.

```bash
cd sacdia-backend && git checkout development && git pull && git checkout -b feat/camporee-orders
cd ../sacdia-app && git checkout development && git pull && git checkout -b feat/camporee-orders
cd ../sacdia-admin && git checkout development && git pull && git checkout -b feat/camporee-orders
```

Baseline (anotar fallos, no arreglar):

```bash
cd sacdia-backend && npm test -- src/materials src/field-payment-orders src/camporees
cd sacdia-app && flutter test test/features/camporees test/features/payment_orders
cd sacdia-admin && npx vitest run src/components/camporees src/components/payment-orders
```

### Fase 0 — Canon stub

**Files:**

- Create: `docs/features/camporee-orders.md`
- Modify: `docs/features/README.md` (registrar dominio `camporee-orders`, estado `EN IMPLEMENTACIÓN`)
- Modify: `docs/features/camporees.md` (sección “Pedidos” + link; gap de logística ya no aplica a merch)
- Modify: `docs/audit/DECISIONS-PENDING.md` si la asunción 20 debe quedar como decisión abierta visible

Commit raíz: `docs: define camporee orders domain and v1 decisions`

**Gate:** el doc de feature dice qué no es (recursos/inventario/materiales/órdenes de inscripción).

### Fase 1 — Schema + SM + folio + errors + permisos

**Files:**

- Create: `sacdia-backend/prisma/migrations/20260824180000_camporee_orders/migration.sql`
- Modify: `sacdia-backend/prisma/schema.prisma`
- Modify: `docs/database/schema.prisma`, `docs/database/SCHEMA-REFERENCE.md`
- Create: `sacdia-backend/src/camporee-orders/state-machine.ts`
- Create: `sacdia-backend/src/camporee-orders/state-machine.spec.ts`
- Create: `sacdia-backend/src/camporee-orders/folio.service.ts`
- Create: `sacdia-backend/src/camporee-orders/folio.service.spec.ts`
- Create: `sacdia-backend/src/camporee-orders/permissions.ts`
- Modify: `sacdia-backend/src/common/errors/error-codes.ts`
- Modify: `sacdia-backend/prisma/seeds/permissions.seed.sql`, `role-permissions.seed.sql`
- Modify: `local_camporees` / `union_camporees` en schema (3 columnas)

TDD:

1. Spec SM: cada transición de §4, más negativas.
2. Spec folio: dos LF pueden tener `PED20260001`; el segundo allocate incrementa; año CDMX.
3. Migración con CHECKs de XOR owner, XOR camporee, unique parcial de orden activa.

```bash
cd sacdia-backend && npm test -- src/camporee-orders/state-machine.spec.ts src/camporee-orders/folio.service.spec.ts
```

Commit backend: `feat: add camporee orders schema and state machine`

**Gate:** `npx prisma validate`. No aplicar a Neon.

### Fase 2 — Catálogo + ofertas + settings

**Files:**

- Create: `sacdia-backend/src/camporee-orders/camporee-orders.module.ts`
- Create: `sacdia-backend/src/camporee-orders/catalog.service.ts` + `.spec.ts`
- Create: `sacdia-backend/src/camporee-orders/offerings.service.ts` + `.spec.ts`
- Create: `sacdia-backend/src/camporee-orders/dto/*.dto.ts`
- Create: `sacdia-backend/src/camporee-orders/catalog.controller.ts`
- Create: `sacdia-backend/src/camporee-orders/offerings.controller.ts`
- Modify: `sacdia-backend/src/app.module.ts`
- Modify: `sacdia-backend/src/camporees/dto/create-camporee.dto.ts`, `create-union-camporee.dto.ts`, servicios de get/patch para exponer settings (default false; no romper clientes viejos)

Tests: scope inválido (LF no crea producto de unión ajena), cascada de visibilidad, PUT offerings rechaza producto fuera de cascada, `size_scheme=none` sin opciones, letter sin opciones → 422.

Commit: `feat: add camporee order catalog and offerings`

### Fase 3 — Ciclo de vida de la orden + PDF + proof

**Files:**

- Create: `sacdia-backend/src/camporee-orders/camporee-orders.service.ts` + `.spec.ts`
- Create: `sacdia-backend/src/camporee-orders/camporee-orders.controller.ts`
- Create: `sacdia-backend/src/camporee-orders/pdf.service.ts` + `.spec.ts`
- Create: `sacdia-backend/src/camporee-orders/proof.service.ts` + `.spec.ts`
- Reuse pipe: importar `ProofFileValidationPipe` o extraer a `src/common/files/` **solo si** el extract es mecánico; si no, duplicar el pipe en el módulo (YAGNI: copiar, no refactorizar materials).
- Create: `sacdia-backend/test/camporee-orders.e2e-spec.ts` (espejo de `test/field-payment-orders.e2e-spec.ts`)

Servicio create: TX folio + snapshot config + líneas + unique activo.  
Approve: maker-checker, `PAID`.  
Reject: motivo.  
Cancel.  
Expiry lazy en get/list (como field-payment-orders).

```bash
cd sacdia-backend && npm test -- src/camporee-orders test/camporee-orders.e2e-spec.ts
```

Commit: `feat: issue camporee section orders with proof and pdf`

### Fase 4 — Excepción de caja + entrega

**Files:** mismos service/controller + specs.

- `authorize-without-proof` → `PAID` + flags de auditoría.
- `deliver` solo desde `PAID`.
- Proof después de authorize no cambia status.
- Roles: assistant-lf sí; liderazgo de club **no**.

Commit: `feat: allow lf cash authorize and delivery for camporee orders`

### Fase 5 — App

**Files:** `sacdia-app/lib/features/camporee_orders/**`, router, CTA en `camporee_detail_view.dart` (o equivalente bajo `lib/features/camporees/presentation/views/`).

Tests de elegibilidad de UI (no pintar CTA si disabled), mapping de errores, emisión.

```bash
cd sacdia-app && dart analyze lib/features/camporee_orders && flutter test test/features/camporee_orders
```

Commit app: `feat: add camporee merchandise orders flow`

### Fase 6 — Admin

Arranca cuando `ENDPOINTS-LIVE-REFERENCE.md` ya liste las rutas de Fases 2–4.

**Files:**

- `sacdia-admin/src/lib/api/camporee-orders.ts`
- `sacdia-admin/src/components/camporee-orders/`
- Modify: `camporee-form-dialog.tsx`, `union-camporee-form-dialog.tsx`, `camporee-detail-tabs.tsx`
- Rutas catálogo + bandeja bajo `src/app/(dashboard)/dashboard/campamentos/pedidos/`

Criterios visuales: tab Pedidos ≠ tab Órdenes de pago. Consolidado visible antes que el nominado en detalle (el campo necesita el tally para el taller). Excepción de caja no es el botón primario (approve de proof sí lo es).

Commit admin: `feat: add camporee orders catalog and review ui`

### Fase 7 — Docs canónicas (mismo trabajo, no “después”)

- `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- `docs/api/FRONTEND-INTEGRATION-GUIDE.md` (sección pedidos, errores, settings en GET camporee)
- `docs/api/SECURITY-GUIDE.md` (permisos, maker-checker, authorize-without-proof)
- `docs/api/TESTING-GUIDE.md` si hay receta e2e
- `docs/features/camporee-orders.md` estado → `IMPLEMENTADO` cuando las 3 superficies cierren v1
- `docs/features/README.md`
- `docs/audit/REALITY-MATRIX.md`
- `docs/plans/handoffs/camporee-orders-admin-handoff.md` (contrato para Composer, espejo del handoff de payment-orders)

Commit raíz: `docs: canonize camporee orders api and domain`

### Fase 8 — Reporte

Desviaciones vs este plan, tests que ya fallaban, PRs. No ampliar alcance.

---

## 11. Criterios de aceptación v1

1. Camporee con `orders_enabled=false`: app no muestra CTA; POST orders → 403.
2. LF crea “Playera hombre” `letter` S/M/L/XL y “Playera mujer” `letter`; une ambas a un camporee local con precio.
3. Director de Panteras pide 4 playeras (4 personas, tallas distintas) + 3 gorras + 1 libro `none`. PDF muestra consolidado y nominado. Folio `PEDyyyy####`.
4. Segunda emisión mientras la primera está `ISSUED` → 422 `CAMPOREE_ORDER_ACTIVE_EXISTS`.
5. Upload proof → review LF (otra persona) → `PAID` → deliver → `DELIVERED`.
6. Camino excepción: assistant-lf authorize sin proof → `PAID` + `authorized_without_proof` → deliver permitido → proof se puede cargar después.
7. Club leadership no puede authorize-without-proof.
8. Camporee de unión: producto de unión, cobra el LF del club, mismas tablas XOR.
9. División crea producto; camporee local de un LF de esa división puede ofertarlo; un LF de otra división no.
10. No se crea `camporee_members` ni se toca la orden de inscripción.
11. Materiales (SOL) y órdenes territoriales (ORD) siguen intactos.

---

## 12. Riesgos

| Riesgo | Mitigación |
|---|---|
| Confundir Pedidos con Órdenes de pago / Materiales / Recursos | Nombres de UI y docs explícitos; rutas propias |
| Authorize-without-proof se vuelve el camino normal | Botón secundario, permiso estrecho, auditoría |
| Elegibilidad “solo inscritos” vs membresía de sección | Guard único `assertBeneficiaryEligible`; asunción 20 |
| Precio cambiado a mitad de captura | Snapshot en ISSUED; ofertas se pueden desactivar, órdenes viejas conservan snapshot |
| Unique activo bloquea oleada legítima | Unique **no** cubre `PAID`; segunda orden después de pagar |

---

## 13. Commits esperados (mínimo)

```
docs: define camporee orders domain and v1 decisions
feat: add camporee orders schema and state machine
feat: add camporee order catalog and offerings
feat: issue camporee section orders with proof and pdf
feat: allow lf cash authorize and delivery for camporee orders
feat: add camporee merchandise orders flow          (app)
feat: add camporee orders catalog and review ui     (admin)
docs: canonize camporee orders api and domain
```
