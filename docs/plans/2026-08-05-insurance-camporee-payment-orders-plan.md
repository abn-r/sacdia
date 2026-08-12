# Órdenes de pago territoriales (seguros + camporees) — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Estado:** READY FOR APPROVAL — regenerado desde runtime actual (2026-08-07)  
**Alcance:** `sacdia-backend`, `sacdia-app`, `sacdia-admin`, docs canónicas  
**Supersede:** borrador previo que dependía de Finance ledger v2 (PRs cerrados, no en `development`)

**Goal:** Que el director emita una orden grupal con beneficiarios nombrados, descargue el formato, suba comprobante y solo tras aprobación de Campo Local se activen seguros (cupo+asignación) o inscripciones de camporee.

**Architecture:** Kernel compartido de órdenes territoriales reutilizando el patrón vivo de Materials (folio, state machine, comprobante privado, bandeja LF) y el modelo de capacidad de seguros ya existente (`insurance_products` / `cycles` / `purchases` / `slots` / `assignments` / `evidence_files`). Sin ledger Finance v2. Club `finances` no participa. Camporee gana órdenes grupales paralelas; `camporee_payments` por miembro queda legado bajo feature flag.

**Tech Stack:** NestJS + Prisma + PostgreSQL + R2 + PDFKit; Flutter + Riverpod; Next.js + TanStack Query + shadcn/ui.

---

## 0. Runtime que ancla este plan (verificar antes de codear)

### Seguros — ya en `sacdia-backend`

| Pieza | Estado |
|-------|--------|
| `insurance_products`, `insurance_cycle_configs` | Schema + `InsuranceConfigService` + endpoints config |
| `insurance_purchases` + proof multipart + confirm/reject/reverse | `InsurancePurchasesController/Service` |
| `insurance_coverage_slots` materializados al confirmar | Sí |
| `insurance_assignments` | Schema + domain helpers; **sin API HTTP de assign** |
| Legacy `member_insurances` create inmediato | App + admin lo usan; camporee exige este FK |
| UI app/admin de purchases/products/cycles | **No existe** |

Flujo purchase actual: qty anónima + comprobante → `PENDING_CONFIRMATION` → confirm crea slots `AVAILABLE`. **No nombra beneficiarios.** Choca con decisión de producto (beneficiarios en la orden).

### Materials — patrón reutilizable (no drop-in)

- Folio: `src/materials/orders/folio.service.ts` (`SOL{year}{####}`, counter por LF)
- SM: `en_revision → aprobada → pagada → entregada` + comprobante `pendiente|aprobado|rechazado`
- Proof: multipart Nest → R2 privado → signed download 900s
- Admin review UI + print HTML cliente (sin PDF servidor)
- **No** tiene beneficiarios, PDF servidor, expiry ni maker-checker

### Camporees — flujo opuesto al deseado

- `POST …/register` crea `camporee_members` **antes** del pago; exige `insurance_id` legacy
- `camporee_payments` se cuelga del miembro ya inscrito; approve/reject de pago tardío
- `registration_cost` / `payment_deadline` existen; backend **no** bloquea inscripción por impago
- Gratis = costo nulo / UX sin pago; no API aparte

### Finance

- Módulo vivo = caja de club (`finances`, evidencias de movimiento)
- **No** hay ledger v2 en `development`. Este plan **no** lo espera ni lo bloquea.

### PDF servidor

- Reutilizar enfoque PDFKit de `MonthlyReportsPdfService` (`src/monthly-reports/monthly-reports-pdf.service.ts`)

### Docs drift

- `docs/database/schema.prisma` y `docs/features/gestion-seguros.md` **no** reflejan el capacity model. Canonizar en Fase 0.

---

## 1. Decisiones cerradas (producto + técnica)

### Producto (conservadas del borrador)

1. App: director selecciona beneficiarios, emite orden, descarga formato, sube comprobante.
2. Admin: Campo Local configura productos/costos y aprueba/rechaza comprobantes y reasignaciones.
3. Una selección = una orden grupal atómica (un folio, un total, un comprobante vigente).
4. Sin pagos/aprobaciones parciales en v1.
5. Seguro usa producto/ciclo configurado por Campo Local.
6. Reasignación solo mismo club; ejecuta al aprobar Campo Local; sin nuevo pago.
7. `camporee_members` se crean **después** de aprobar comprobante (camporees de pago).
8. “Campamento” = dominio `local_camporees` existente.

### Técnicas nuevas (ancladas al runtime)

9. **No Finance ledger.** Proof + revisión viven en el dominio (como materials/insurance purchases).
10. **No inventar capacity model paralelo.** Cumplir sobre `insurance_*` existente.
11. **Beneficiarios nombrados reemplazan qty anónima** para el flujo nuevo. Purchases qty-only quedan legado (lectura + drain); flag apaga submit qty cuando el nuevo flujo esté ON.
12. Confirmación de orden de seguro = TX única: slot + assignment ACTIVE + proyección `member_insurances` (bridge camporee FK).
13. Patrones a copiar: FolioService materials, evidence privada insurance, PDFKit monthly-reports, bandeja admin materials receipts.
14. Upload v1 = **multipart Nest** (como purchases/materials). Sin upload-intents hasta que exista primitiva compartida estable.
15. Maker-checker: quien subió el comprobante no puede aprobarlo (`insurance:review` / permiso camporee equivalente).
16. Feature flag por `local_field_id` para rollout.

---

## 2. Arquitectura objetivo

```text
                    +-------------------------------+
                    | FieldPaymentOrders (kernel)   |
                    | folio / SM / PDF / proof      |
                    | review queue / maker-checker  |
                    +---------------+---------------+
                                    |
              +---------------------+---------------------+
              v                                           v
   InsuranceFulfillment                        CamporeeFulfillment
   products/cycles (exist)                     registration_cost (exist)
   order -> slots+assignments                  order -> camporee_members
   + member_insurances bridge                  status approved + insurance_id
```

### Estados unificados (kernel)

```text
ISSUED
  ├── PROOF_SUBMITTED
  │     ├── APPROVED
  │     └── PROOF_REJECTED ──> PROOF_SUBMITTED   (mismo folio)
  ├── CANCELLED   (solo desde ISSUED / PROOF_REJECTED)
  └── EXPIRED     (job o check lazy desde ISSUED sin proof; plazo configurable
                   en system_config `field_payment_orders.expiry_days`, default 15 días)
```

Beneficiarios, precios, producto/evento: inmutables desde `ISSUED`. Cambiar = cancelar + nueva orden.

### Persistencia

**Reutilizar**

- `insurance_products`, `insurance_cycle_configs`
- `insurance_coverage_slots`, `insurance_assignments`, `insurance_slot_movements`
- `insurance_evidence_files` (extender tipo/FK si hace falta para órdenes nuevas)

**Evolucionar / añadir**

- `field_payment_orders` — propósito `INSURANCE | CAMPOREE`, folio, LF, club, section, montos (centavos), moneda, vencimiento, estado, actores, `purpose_ref` (cycle_config_id o camporee_id), timestamps
- `field_payment_order_lines` — `beneficiary_user_id`, unit_cost_snapshot, sequence, purpose payload JSON mínimo
- `field_payment_order_proofs` — r2_key, mime, size, status, reject_reason, uploaded_by (o reutilizar `insurance_evidence_files` + tabla camporee equivalente; preferir una tabla kernel si unifica review)
- `field_payment_folio_counters` — copiar semántica materials (`local_field_id`, year, last_folio); prefijo distinto p.ej. `ORD{year}{####}`
- `insurance_reassignment_requests` — from/to user, slot/assignment, motivo, decisión LF
- Bridge: al aprobar seguro, upsert `member_insurances` ligado a assignment (campos mínimos para camporee eligibility)

**Legado (no borrar en v1)**

- `insurance_purchases` qty-only: read/confirm residual bajo flag OFF del nuevo flujo
- `camporee_payments` por miembro: sigue para union/histórico; pagado+flag ON usa órdenes grupales
- Legacy `POST /users/:memberId/insurance`: flag OFF en LF piloto

### Fulfillment

**Seguro (approve)** — una TX:

1. Validar elegibilidad vigente de cada línea (membresía sección, sin assignment activa incompatible).
2. Crear 1 slot + 1 assignment ACTIVE por línea (validity desde cycle/product).
3. Upsert proyección `member_insurances` por beneficiario.
4. Marcar orden `APPROVED` + proof aprobado.
5. Fallo cualquiera → rollback total.

**Camporee (approve)** — una TX:

1. Revalidar sección inscrita, deadlines, membresía, seguro vigente (assignment activa o legacy) por línea.
2. Crear todos los `camporee_members` con `status=approved`, `insurance_id` del bridge/legacy.
3. Opcional: 1 `camporee_payments` agregado o link `order_id` en metadata — **no** N pagos parciales.
4. Si uno falla elegibilidad → rechazar approve completo, cero miembros nuevos.

**Camporee sin pago** — SUPERSEDED (addendum 2026-08-12): ningún camporee es gratis para clubes ni personal de apoyo; toda inscripción de miembros pasa por orden de pago con flag ON. Solo jueces (`camporee_judges`) y staff de Campo Local/Unión (`camporee_staff_members`) no pagan inscripción, y esos flujos ya son separados del register de miembros — no se tocan. `registration_cost` null/0 en un camporee = error de configuración: bloquear creación de órdenes y register de miembros con error explícito.

---

## 3. Contratos API (contract-first)

Permisos nuevos/ajustados (seed + grants LF):

- Reusar donde quepa: `insurance:create|read|review|configure`
- Añadir: `field-payment-orders:read|create|upload-proof|cancel|review` (o namespaced corto acordado en Task 1)
- Camporee paid path: `attendance:manage` crea orden; review con `attendance:approve_late` **o** permiso review unificado — decidir en Task 1 docs y no mezclar late-enrollment con proof-review en la misma semántica de UI.

### Director — app

```http
POST /api/v1/insurance/payment-orders
POST /api/v1/camporees/:camporeeId/payment-orders

GET  /api/v1/payment-orders
GET  /api/v1/payment-orders/:orderId
GET  /api/v1/payment-orders/:orderId/document

POST /api/v1/payment-orders/:orderId/proof   # multipart, como materials/purchases
POST /api/v1/payment-orders/:orderId/cancel

POST /api/v1/insurance/reassignment-requests
GET  /api/v1/insurance/reassignment-requests
```

Backend deriva club/sección/LF del actor. Cliente **no** envía `club_id` / `local_field_id`.

Body create insurance (ilustrativo):

```json
{
  "insurance_cycle_config_id": 12,
  "beneficiary_user_ids": ["uuid", "uuid"]
}
```

Total y unit_cost **solo backend** desde cycle. Idempotencia: header `Idempotency-Key` UUID opcional en create/approve.

### Campo Local — admin

```http
GET  /api/v1/payment-orders/review-queue
POST /api/v1/payment-orders/:orderId/approve
POST /api/v1/payment-orders/:orderId/reject

GET  /api/v1/insurance/reassignment-requests/review-queue
POST /api/v1/insurance/reassignment-requests/:id/approve
POST /api/v1/insurance/reassignment-requests/:id/reject
```

Config ya parcial:

```http
GET|POST /api/v1/insurance/products
PATCH    /api/v1/insurance/products/:id
GET|POST /api/v1/insurance/cycles
PATCH    /api/v1/insurance/cycles/:id
```

Exponer en admin (hoy backend-only). Instrucciones de caja: reutilizar/extender patrón `MaterialConfig` (cuenta/CLABE/leyendas) **por LF** para órdenes — tabla `field_payment_order_configs` o columnas en config materials si el negocio acepta compartir datos bancarios; default = **tabla propia mínima** para no acoplar stock.

---

## 4. Plan de implementación

### Fase 0 — Canon y baseline (docs + flags)

### Task 0.1: Canonizar capacity model y gaps

**Files:**
- Modify: `docs/features/gestion-seguros.md`
- Modify: `docs/database/schema.prisma` (sync desde backend)
- Modify: `docs/database/SCHEMA-REFERENCE.md`
- Modify: `docs/api/ENDPOINTS-LIVE-REFERENCE.md` (purchases/config ya runtime)
- Modify: `docs/audit/REALITY-MATRIX.md` si aplica

**Steps:**
1. Documentar dual-path: legacy `member_insurances` vs purchases/slots.
2. Marcar purchases qty-only como legado a reemplazar por payment-orders.
3. Listar endpoints purchases/config en LIVE reference verificando controllers.
4. `git diff --check`

**Commit:** `docs: canonize insurance capacity model and payment-order baseline`

### Task 0.2: Feature flag + ownership

**Files:**
- Create/Modify system-config o flag table pattern ya usado en backend (buscar flag existente; no inventar segundo mecanismo)
- Modify: `docs/features/gestion-seguros.md`, `docs/features/camporees.md`

**Decision to record:** flag key p.ej. `field_payment_orders_v1` scoped by `local_field_id`.

**Commit:** `docs: define field payment orders rollout flag`

---

### Fase 1 — Kernel backend

### Task 1.1: Schema `field_payment_orders*`

**Files:**
- Create: `sacdia-backend/prisma/migrations/<ts>_field_payment_orders/migration.sql`
- Modify: `sacdia-backend/prisma/schema.prisma`
- Sync docs schema

**Invariants:**
- Unique parcial: no dos órdenes activas (`ISSUED|PROOF_SUBMITTED|PROOF_REJECTED`) con mismo beneficiario+purpose_ref
- Money en centavos + check totales = suma líneas
- Folio unique por `(local_field_id, folio)`

**Tests:** migration apply en CI PG; constraint tests.

**Commit:** `feat(db): add field payment orders schema`

### Task 1.2: State machine + FolioService

**Files:**
- Create: `sacdia-backend/src/field-payment-orders/state-machine.ts`
- Create: `sacdia-backend/src/field-payment-orders/folio.service.ts` (adaptar materials)
- Create: `*.spec.ts`

Copiar estilo `materials/orders/state-machine.ts` y `folio.service.ts`. Prefijo `ORD`.

**Commit:** `feat(field-payment-orders): add folio and state machine`

### Task 1.3: PDF documento de orden

**Files:**
- Create: `sacdia-backend/src/field-payment-orders/field-payment-order-pdf.service.ts`
- Pattern: PDFKit como monthly-reports

Debe incluir: folio, concepto, club/sección, beneficiarios, precio unitario, total, vencimiento, instrucciones de pago (datos bancarios Y opción de pago en la caja del Campo Local, según config del LF), leyenda **“Orden de pago — no es comprobante fiscal”**.

**Commit:** `feat(field-payment-orders): generate printable order PDF`

### Task 1.4: Proof upload + signed read

**Files:**
- Create: `sacdia-backend/src/field-payment-orders/field-payment-order-proof.service.ts`
- Reusar validación magic-bytes/size de materials receipts / insurance-evidence

Estados: upload desde `ISSUED|PROOF_REJECTED` → `PROOF_SUBMITTED`. Reject → `PROOF_REJECTED` sin quemar folio.

**Commit:** `feat(field-payment-orders): private proof upload and signed URLs`

### Task 1.5: Create/list/get/cancel + review-queue/approve/reject skeleton

**Files:**
- Create module/controller/service/DTOs under `src/field-payment-orders/`
- Wire `app.module.ts`
- Permissions seed

Approve/reject llaman ports `InsuranceFulfillment` / `CamporeeFulfillment` (stubs que fallan hasta Fase 2/3).

**Commit:** `feat(field-payment-orders): expose order lifecycle API`

---

### Fase 2 — Fulfillment seguros

### Task 2.1: Create insurance payment order (beneficiarios)

**Files:**
- Modify insurance create path to use kernel
- Validate cycle activo, club_type, membership, sin duplicados activos
- Snapshot `unit_cost` desde `insurance_cycle_configs`

**Commit:** `feat(insurance): create beneficiary payment orders`

### Task 2.2: Approve → slots + assignments + member_insurances bridge

**Files:**
- Create: `src/field-payment-orders/fulfillment/insurance-fulfillment.service.ts`
- Modify assignment status enums usage → ACTIVE en approve
- Bridge writer a `member_insurances`

**Tests críticos:**
- approve concurrente no duplica
- rollback si bridge falla
- maker-checker
- elegibilidad rota en approve → 409/400 sin side effects

**Commit:** `feat(insurance): fulfill payment orders into slots and assignments`

### Task 2.3: Reassignment requests

**Files:**
- Schema + API + TX close old assignment / open new
- Same club only (`assertSameClubTransfer` ya en `domain/insurance-policy.ts`)

**Commit:** `feat(insurance): reassignment requests with LF approval`

### Task 2.4: Dual-read + gate legacy writes

**Files:**
- Modify `insurance.service.ts` list/detail: prefer active assignment (+ bridge), fallback legacy
- Flag ON: bloquear `POST /users/:memberId/insurance` create directo en LF piloto
- Flag ON: bloquear `POST …/insurance/purchases` qty submit

**Commit:** `feat(insurance): dual-read assignments and gate legacy creates`

### Task 2.5: Admin config UI products/cycles + review queue seguros

**Ownership:** Composer en admin; contrato ya estable.

**Files (admin):**
- `/dashboard/insurance` config products/cycles
- Bandeja `payment-orders` filtrable purpose=INSURANCE
- Proof viewer via signed URL

**Commit:** `feat(admin): insurance payment order config and review`

### Task 2.6: App flujo orden de seguro

**Files (app):**
- Selector múltiple elegibles
- Resumen + total
- Download/share PDF
- Upload proof + timeline
- Ocultar “seguro activo” hasta APPROVED

**Commit:** `feat(app): insurance group payment orders`

---

### Fase 3 — Fulfillment camporees

### Task 3.1: Create camporee payment order

**Prechecks:** sección en `camporee_clubs` registered|approved; miembros en sección; seguro vigente; no línea duplicada activa; `registration_cost > 0`.

**Commit:** `feat(camporees): create group payment orders`

### Task 3.2: Approve → create members atomically

**Files:**
- `camporee-fulfillment.service.ts`
- No crear members en create-order
- Revalidate insurance on approve
- Link opcional order↔members

**Commit:** `feat(camporees): fulfill payment orders into members`

### Task 3.3: Gate register/payment legacy when flag ON

**Files:**
- `camporees.service.ts` register + payments endpoints
- SUPERSEDED "free path" (addendum 2026-08-12): con flag ON, TODO register de miembros exige orden aprobada; sin excepción por costo 0 (costo 0/null = error de config). Flujos de jueces y staff LF/Unión intactos (no pagan, no usan register de miembros).

**Commit:** `feat(camporees): gate paid direct register behind payment orders flag`

### Task 3.4: Admin + app camporee order UX

- Admin: misma bandeja purpose=CAMPOREE
- App: reemplazar register-multiple paid por emit-order flow; payments view lee órdenes

**Commits:** separados admin/app.

---

### Fase 4 — Rollout y métricas

### Task 4.1: Observability

Emitir/contar: orders issued, proof_submitted, approved, rejected, expire, fulfill_fail, approve_latency.

### Task 4.2: Piloto un LF

1. Seed products/cycles + bank instructions  
2. Flag ON  
3. Drain purchases pendientes legacy  
4. Monitorear  
5. Solo entonces alinear 100% app/admin copy

### Task 4.3: Docs finales

Actualizar `docs/features/gestion-seguros.md`, `camporees.md`, `ENDPOINTS-LIVE-REFERENCE.md`, `FRONTEND-INTEGRATION-GUIDE.md`, SCHEMA refs.

**Commit:** `docs: finalize field payment orders contracts`

---

## 5. Pruebas y aceptación

- Director no selecciona fuera de su sección/alcance.
- Precio/beneficiarios inmutables post-`ISSUED`.
- Reject proof permite reupload mismo folio.
- Approve concurrente no duplica slots ni `camporee_members`.
- Fallo fulfill revierte approve completo.
- Approve seguro → exactamente 1 assignment ACTIVE + 1 bridge `member_insurances` por línea.
- Reassignment pendiente no mueve titular actual.
- No reassign entre clubes / productos incompatibles.
- Archivo inválido/sobrepeso/fuera de alcance rechazado.
- Flag OFF: comportamientos legacy intactos.
- Camporee gratis: register directo sigue.
- Ejecutar tests focalizados + `flutter analyze` / test afectados; **sin builds**.

---

## 6. Orden de PRs sugerido

1. Docs canon (Task 0.x)  
2. Backend kernel schema+API (1.x)  
3. Insurance fulfillment + gate (2.1–2.4)  
4. Admin seguros (2.5) — Composer  
5. App seguros (2.6)  
6. Camporee backend (3.1–3.3)  
7. Admin/app camporee (3.4)  
8. Rollout docs/metrics (4.x)

Contract-first: ningún PR app/admin mergea sin endpoints documentados en LIVE reference.

---

## 7. Fuera de alcance (v1)

- Finance ledger v2 / `settleFieldPaymentOrder` contable  
- Upload-intents presignados  
- Pagos parciales / multi-comprobante  
- Camporees de unión en el nuevo flujo (salvo que reutilicen mismo kernel en v1.1)  
- Notificaciones push de vencimiento de orden (log + bandeja bastan)  
- Migración inventada de folios para `member_insurances` históricos

---

## Addendum — verificación de runtime y ajustes de producto (2026-08-12)

### Verificación contra `development`

Las anclas de la sección 0 fueron re-verificadas el 2026-08-12: **todas confirmadas** con una excepción parcial:

- **Feature flags (parcial):** existe `system_config` (tabla + `SystemConfigService.get()`) pero es global; NO hay flags por `local_field_id` ni módulo de feature flags. Resolución: usar `system_config` con key `field_payment_orders_v1` cuyo value JSON contiene la lista de `local_field_id` habilitados. Cumple "no inventar segundo mecanismo".
- El plan no está implementado: cero rastro de `field_payment_orders` en schema, migraciones, seeds o código de los 3 repos.

### Precisiones de runtime que el plan no registraba

1. **Colisión de ruta admin:** `/dashboard/insurance` YA existe (CRUD de `member_insurances` + expiring). La config de productos/ciclos (Task 2.5) va en subruta propia (p.ej. `/dashboard/insurance/config`) sin pisar la existente.
2. **Admin camporee ya maduro:** detalle con tabs clubs/members/payments/aprobaciones + voucher (`camporee-detail-tabs.tsx`). Task 3.4 = integrar la bandeja de órdenes a esa superficie, no construir desde cero.
3. **Permiso de review:** `attendance:approve_late` existe (scope LF/Unión) pero su semántica es late-enrollment. Decisión: permiso único `field-payment-orders:review` para la bandeja de ambos propósitos, con grants espejo de `insurance:review` (`director-lf`, `assistant-lf`, `admin`, `super-admin`).
4. **Prefijo HTTP real:** `/api/v1/...` confirmado; purchases usan `club-sections/:sectionId/insurance/purchases`.

### Ajustes de producto (usuario, 2026-08-12)

1. **Pago en banco O en caja del Campo Local.** La configuración por LF (`field_payment_order_configs`) debe soportar ambos: datos bancarios (cuenta/CLABE) e instrucciones de pago en caja. El PDF muestra las opciones configuradas.
2. **Ningún camporee es gratis.** Clubes y personal de apoyo siempre pagan inscripción. Solo jueces y staff del Campo Local/Unión no pagan (sus flujos `camporee_judges`/`camporee_staff_members` son separados y no se tocan). Se elimina el "free path" del register de miembros: con flag ON, toda inscripción de miembros exige orden aprobada; `registration_cost` null/0 = error de configuración que bloquea órdenes y register.
3. **Expiración configurable:** `system_config` key `field_payment_orders.expiry_days`, default **15 días**. Check lazy en lecturas/transiciones + job opcional.

## Key Learnings

1. Runtime ya tiene mitad del modelo de seguros (config + purchase qty + slots); el gap real es **beneficiarios nombrados, assignment API, UI y bridge a `member_insurances`**.
2. Materials es la referencia operativa de folio/comprobante/review; no el módulo a extender con stock.
3. Bloquearse en Finance v2 fue un callejón: el producto puede cerrar con evidencia de dominio + fulfillment atómico.
4. Camporee hoy es member-first; el cambio duro es gate del register de pago, no solo una pantalla nueva.
