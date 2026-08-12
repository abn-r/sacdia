# Plan de ejecución: órdenes de pago territoriales (seguros + camporees)

> **Para el agente ejecutor:** sigue este plan fase por fase, en orden. Este documento define el CÓMO (orden, branches, gates, commits, reporte). El QUÉ (arquitectura, schema, contratos API, fulfillment, criterios de aceptación) vive en el plan base `docs/plans/2026-08-05-insurance-camporee-payment-orders-plan.md` **incluyendo su Addendum 2026-08-12** — léelo COMPLETO y trátalo como fuente de diseño no negociable. Si un supuesto no coincide con el código real, verifica en el archivo indicado y adapta el detalle sin cambiar diseño ni alcance; registra toda desviación en el reporte final (Fase 8).

**Objetivo:** kernel de órdenes de pago territoriales (`field_payment_orders`): el director emite orden grupal con beneficiarios nombrados, descarga PDF con folio, paga en banco o en la caja del Campo Local, sube comprobante, y solo tras aprobación del Campo Local se activan seguros (slot + assignment + bridge `member_insurances`) o inscripciones de camporee (`camporee_members` aprobados), de forma atómica.

**Arquitectura:** monorepo SACDIA. Backend NestJS 11 + Prisma 7 (PostgreSQL/Neon, R2, PDFKit), app Flutter/Riverpod, admin Next.js 16 + shadcn/ui. Contract-first: backend primero, clientes después. Patrones a copiar (verificados en runtime): folio y state machine de `src/materials/orders/`, evidencia privada multipart de `insurance-purchases`/materials receipts, PDFKit de `monthly-reports-pdf.service.ts`, bandeja admin de `materials/receipts`.

**Contexto obligatorio antes de empezar (en orden):**
1. `AGENTS.md` raíz.
2. Plan base completo + Addendum (`docs/plans/2026-08-05-insurance-camporee-payment-orders-plan.md`).
3. `sacdia-backend/src/insurance/` (capacity model actual), `src/materials/orders/` (patrones), `src/camporees/camporees.service.ts` (register/payments actuales).
4. `docs/features/gestion-seguros.md`, `docs/features/gestion-clubs.md` (o el doc de camporees que exista en `docs/features/`).
5. `sacdia-backend/CLAUDE.md`, `sacdia-admin/CLAUDE.md`, `sacdia-app/CLAUDE.md`.

**Reglas duras:**
- Conventional commits. NUNCA `Co-Authored-By` ni atribución de IA. Tras CADA commit verificar `git log -1 --format='%(trailers)'`; si hay trailer, recrear con `git commit-tree` + `git update-ref` sobre la branch.
- NO builds. NO tocar `.env`. NO aplicar migraciones/seeds contra Neon (quedan versionados; el usuario los aplica).
- Tests del área afectada en verde + typecheck/analyze antes de cerrar cada fase.
- Docs canónicas en el mismo trabajo (Fases 0 y 7).
- No mezclar cambios ajenos preexistentes.

**Decisiones ya tomadas (no re-discutir) — completas en plan base §1 + Addendum:**
1. Branch `feat/field-payment-orders` en los 3 repos runtime + repo raíz para docs. Al final: PRs a `development` (flujo del proyecto).
2. Sin Finance ledger v2. Proof y revisión viven en el dominio.
3. Beneficiarios nombrados; total y unit_cost solo backend; inmutables desde `ISSUED`. Cambio = cancelar + nueva orden.
4. Estados kernel: `ISSUED → PROOF_SUBMITTED → APPROVED | PROOF_REJECTED (→ PROOF_SUBMITTED mismo folio)`; `CANCELLED` desde `ISSUED|PROOF_REJECTED`; `EXPIRED` lazy desde `ISSUED` sin proof.
5. Expiración: `system_config` key `field_payment_orders.expiry_days`, default 15 días.
6. Flag rollout: `system_config` key `field_payment_orders_v1` con lista JSON de `local_field_id` habilitados. No inventar otro mecanismo.
7. Maker-checker: quien subió el comprobante no puede aprobar la orden.
8. Ningún camporee gratis: con flag ON, todo register de miembros exige orden aprobada; `registration_cost` null/0 bloquea órdenes y register con error explícito. Jueces y staff LF/Unión no pagan y sus flujos no se tocan.
9. Pago en banco o caja del LF: tabla propia `field_payment_order_configs` por LF (datos bancarios + instrucciones de caja + leyendas). No acoplar a config de materials.
10. Permisos: `field-payment-orders:read|create|upload-proof|cancel|review` (seed + grants: create/upload/cancel/read para roles directivos de club espejo de `insurance:create`; review espejo de `insurance:review`). Reusar `insurance:configure` para products/cycles.
11. Approve seguro = TX única: validar elegibilidad por línea → 1 slot + 1 assignment `ACTIVE` por línea → upsert `member_insurances` (bridge) → orden `APPROVED`. Fallo → rollback total.
12. Approve camporee = TX única: revalidar (sección registrada, deadline, membresía, seguro vigente por línea) → crear todos los `camporee_members` `status=approved` → link orden↔members. Un fallo → cero miembros.
13. Admin: config de productos/ciclos en subruta nueva (p.ej. `/dashboard/insurance/config`), SIN pisar `/dashboard/insurance` existente (CRUD legacy `member_insurances`). Bandeja única de órdenes filtrable por purpose.
14. Idempotencia: header `Idempotency-Key` opcional en create/approve.
15. Multipart Nest para proof (patrón purchases/materials); R2 privado; signed download ~900s.
16. Legacy intacto con flag OFF: `POST /users/:memberId/insurance`, purchases qty, register directo de camporee y `camporee_payments` siguen funcionando.

---

## Fase 0 — Preparación, canon y flag

### Task 0.1: Branches y baseline

```bash
cd sacdia-backend && git checkout development && git pull && git checkout -b feat/field-payment-orders && cd ..
cd sacdia-app && git checkout development && git pull && git checkout -b feat/field-payment-orders && cd ..
cd sacdia-admin && git checkout development && git pull && git checkout -b feat/field-payment-orders && cd ..
# repo raíz: trabajar en development directamente (solo docs)
```

Baseline (guardar resúmenes; fallos preexistentes se anotan, NO se arreglan):

```bash
cd sacdia-backend && npm test -- src/insurance src/materials src/camporees
cd sacdia-app && flutter test test/features/insurance test/features/camporees 2>/dev/null || true  # anotar qué suites existen
cd sacdia-admin && npx vitest run src/components/insurance src/components/camporees 2>/dev/null || true  # ídem
```

### Task 0.2: Canon docs + flag (plan base Tasks 0.1–0.2)

Ejecutar tal como están en el plan base: documentar dual-path seguros (legacy vs capacity model), marcar purchases qty como legado, listar endpoints purchases/config en `ENDPOINTS-LIVE-REFERENCE.md` verificando contra controllers, sincronizar `docs/database/schema.prisma`, y documentar las keys `field_payment_orders_v1` y `field_payment_orders.expiry_days` en los features docs.

Commits (repo raíz): los dos del plan base.

**Gate:** docs consistentes; `git diff --check` limpio.

---

## Fase 1 — Kernel backend (plan base Tasks 1.1–1.5)

Ejecutar en orden Tasks 1.1 (schema), 1.2 (state machine + folio), 1.3 (PDF), 1.4 (proof), 1.5 (API lifecycle). TDD por task: spec RED → implementar → GREEN → commit (mensajes del plan base).

**Precisiones:**
- Migración con timestamp del día, idempotente donde sea posible. NO aplicar a Neon.
- Tablas: `field_payment_orders`, `field_payment_order_lines`, `field_payment_order_proofs`, `field_payment_folio_counters` (prefijo `ORD`), `field_payment_order_configs`, `insurance_reassignment_requests`. Invariantes del plan base §2 (unique parcial beneficiario+purpose activo, montos en centavos con check de suma, folio unique por LF).
- Folio y SM: copiar estilo `materials/orders/folio.service.ts` (counter FOR UPDATE) y `state-machine.ts`.
- PDF: PDFKit; incluye folio, beneficiarios, total, vencimiento, instrucciones de pago (banco Y/O caja según config LF) y leyenda "Orden de pago — no es comprobante fiscal".
- Proof: multipart, validación magic-bytes/size copiada de materials receipts; upload desde `ISSUED|PROOF_REJECTED` → `PROOF_SUBMITTED`.
- Task 1.5: controller con create (por propósito), list/get/document/proof/cancel + review-queue/approve/reject; approve delega en ports `InsuranceFulfillment`/`CamporeeFulfillment` (stubs que lanzan hasta Fases 2/4). Permisos seed de la decisión 10. Expiración lazy con `expiry_days`.
- Flag helper: servicio pequeño que lee `field_payment_orders_v1` de `system_config` y responde si un `local_field_id` está habilitado (con test).

**Gate de fase:**

```bash
cd sacdia-backend
npm test -- --runInBand src/field-payment-orders
npx prisma validate && npx tsc --noEmit -p tsconfig.build.json
```

Commits mínimos: 5.

---

## Fase 2 — Fulfillment seguros backend (plan base Tasks 2.1–2.4)

- Task 2.1: create de orden de seguro — valida ciclo activo, club_type, membresía, sin duplicado activo por beneficiario; snapshot `unit_cost` del cycle config.
- Task 2.2: `insurance-fulfillment.service.ts` — approve TX (decisión 11). Tests críticos del plan base: approve concurrente no duplica, rollback si bridge falla, maker-checker, elegibilidad rota → 409 sin side effects.
- Task 2.3: `insurance_reassignment_requests` — API create/list/review; TX cierra assignment viejo y abre nuevo; solo mismo club (`assertSameClubTransfer` de `domain/insurance-policy.ts`).
- Task 2.4: dual-read (detalle/list de seguros prefiere assignment activa + bridge, fallback legacy) + gates con flag ON: bloquear `POST /users/:memberId/insurance` y submit de purchases qty en LFs habilitados.

**Gate de fase:**

```bash
npm test -- --runInBand src/field-payment-orders src/insurance
npx tsc --noEmit -p tsconfig.build.json
```

Commits mínimos: 4 (mensajes del plan base).

---

## Fase 3 — Fulfillment camporees backend (plan base Tasks 3.1–3.3)

- Task 3.1: create de orden camporee — prechecks: sección en `camporee_clubs` registered|approved, miembros de la sección, seguro vigente (assignment activa o legacy `member_insurances`), sin línea duplicada activa, `registration_cost > 0` (si null/0 → error de config, decisión 8).
- Task 3.2: `camporee-fulfillment.service.ts` — approve TX (decisión 12); revalida seguro en approve; link orden↔members.
- Task 3.3: gate register/payments legacy con flag ON — TODO register de miembros exige orden aprobada (sin free path); flujos de jueces/staff intactos; `camporee_payments` legacy sigue para histórico.
- E2E: crear `test/field-payment-orders.e2e-spec.ts` cubriendo la matriz mínima del plan base §5 (director fuera de alcance, inmutabilidad post-ISSUED, reject→reupload mismo folio, approve concurrente, rollback fulfill, maker-checker, archivo inválido, flag OFF legacy intacto).

**Gate de fase:**

```bash
npm test -- --runInBand src/field-payment-orders src/insurance src/camporees
npm run test:e2e -- --runInBand test/field-payment-orders.e2e-spec.ts   # adaptar al script real
npx tsc --noEmit -p tsconfig.build.json
```

Commits mínimos: 3–4.

---

## Fase 4 — Admin (plan base Tasks 2.5 + 3.4-admin)

Contract-first: escribir primero `docs/plans/handoffs/field-payment-orders-admin-handoff.md` (repo raíz) con endpoints/DTOs REALES implementados, permisos, estados, errores. Luego UI:

- Config seguros: subruta nueva (p.ej. `/dashboard/insurance/config`) para products/cycles (contra endpoints `insurance:configure` existentes) + config de instrucciones de pago por LF (banco/caja).
- Bandeja de órdenes: página con tabs o filtro purpose=INSURANCE|CAMPOREE; detalle con líneas/beneficiarios, comprobante vía URL firmada on-demand, approve/reject (comentario obligatorio en reject), indicador maker-checker; bandeja de reassignment requests.
- Integrar acceso desde la superficie camporee existente (`camporee-detail-tabs.tsx`) hacia las órdenes del camporee.
- i18n 4 locales + `messages.d.ts` regenerado; tests vitest de los componentes nuevos.

**Gate:** `npx vitest run <áreas nuevas>` + `npm run typecheck` limpios. Commits: 2–3.

---

## Fase 5 — App (plan base Tasks 2.6 + 3.4-app)

- Seguros: selector múltiple de miembros elegibles → resumen con total → emitir orden → descargar/compartir PDF → subir comprobante → timeline de estados. "Seguro activo" solo tras `APPROVED`. Flujo de reasignación (solicitar + estado).
- Camporee (flag ON): reemplazar register pagado directo por emitir orden; la vista de pagos lee órdenes del club/sección; mantener register legacy para flag OFF.
- Mapear errores nuevos a mensajes i18n (4 locales).
- Tests: datasource (contrato método+URL), models, providers y widget tests de las vistas nuevas.

**Gate:**

```bash
cd sacdia-app
dart format lib/features test/features
flutter test test/features/insurance test/features/camporees  # más las suites nuevas
flutter analyze lib/features/insurance lib/features/camporees
```

Commits: 2–3.

---

## Fase 6 — Observabilidad y rollout (plan base Tasks 4.1–4.3)

- Task 4.1: contadores/logs estructurados: issued, proof_submitted, approved, rejected, expired, fulfill_fail, approve_latency (patrón de logging existente del backend; sin infra nueva).
- Task 4.3: docs finales — `gestion-seguros.md`, doc de camporees, `ENDPOINTS-LIVE-REFERENCE.md`, `FRONTEND-INTEGRATION-GUIDE.md`, `SECURITY-GUIDE.md` (maker-checker, ownership de proofs), SCHEMA refs.
- Task 4.2 (piloto: seed products/cycles, flag ON en un LF, drain de purchases) es OPERACIÓN HUMANA post-merge — documentarla como runbook en el doc de feature, NO ejecutarla.

Commit docs: 1.

---

## Fase 7 — Regresión global

```bash
cd sacdia-backend && npm test && npx tsc --noEmit -p tsconfig.build.json && npx prisma validate
cd sacdia-app && flutter test test/features/insurance test/features/camporees && flutter analyze lib/features/insurance lib/features/camporees
cd sacdia-admin && npx vitest run src/components src/lib --exclude '**/.worktrees/**' 2>/dev/null || npx vitest run src/components/insurance src/components/camporees src/lib/api && npm run typecheck
```

Expected: verde salvo fallos preexistentes del baseline (reportar, no arreglar). Sin builds.

---

## Fase 8 — Reporte final (obligatorio)

**Create:** `docs/reports/<fecha>-implementacion-ordenes-pago-territoriales.md` (repo raíz), estructura exacta:

```markdown
# Reporte de implementación — órdenes de pago territoriales

**Fecha:** <fecha>
**Branches:** <branch por repo, con conteo de commits>
**Planes seguidos:** docs/plans/2026-08-05-insurance-camporee-payment-orders-plan.md (+ addendum) + docs/plans/2026-08-12-ordenes-pago-territoriales-plan-ejecucion.md

## 1. Resumen ejecutivo
## 2. Tareas del plan
| Fase/Tarea | Estado | Commit(s) | Notas |
## 3. Desviaciones del plan
## 4. Tests
| Repo | Comando | Resultado |
## 5. Archivos modificados/creados
## 6. Decisiones tomadas durante la ejecución
## 7. Pendientes y riesgos
<mínimo esperado:
- migración field_payment_orders versionada, NO aplicada a Neon
- seeds de permisos y system_config keys NO aplicados a Neon
- flag OFF por defecto en todos los LF; runbook de piloto pendiente
- drain de purchases legacy pendiente
- cualquier fallo preexistente del baseline>
## 8. Verificación manual sugerida
```

Commit: `docs: implementation report for field payment orders`

## Fuera de alcance (NO hacer)

- Finance ledger v2, upload-intents presignados, pagos parciales/multi-comprobante.
- Notificaciones push de vencimiento.
- Camporees de unión en el flujo nuevo (v1.1).
- Migrar folios históricos de `member_insurances`.
- Aplicar migraciones, seeds o flags contra Neon (dev/staging/prod).
- Borrar `insurance_purchases`, `camporee_payments` o el endpoint legacy de seguros.
- Builds de cualquier proyecto.
