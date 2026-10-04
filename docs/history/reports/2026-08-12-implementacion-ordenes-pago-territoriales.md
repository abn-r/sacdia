# Reporte de implementación — órdenes de pago territoriales

**Fecha:** 2026-08-12
**Branches:**
- `sacdia-backend` → `feat/field-payment-orders` (16 commits sobre `development`)
- `sacdia-admin` → `feat/field-payment-orders` (4 commits sobre `development`)
- `sacdia-app` → `feat/field-payment-orders` (1 commit sobre `development`)
- raíz (`sacdia`) → `development` (5 commits de docs: baseline canon, flag, addendum+plan, handoff admin, docs finales)

**Planes seguidos:** `docs/plans/2026-08-05-insurance-camporee-payment-orders-plan.md` (+ addendum 2026-08-12) + `docs/plans/2026-08-12-ordenes-pago-territoriales-plan-ejecucion.md`

## 1. Resumen ejecutivo

Se implementó de punta a punta el sistema de órdenes de pago territoriales para seguros y camporees: kernel backend (schema + state machine + folio + PDF + comprobantes + API), fulfillment de seguros (materialización de cobertura en el capacity model con bridge a `member_insurances`), fulfillment de camporees (creación de `camporee_members` al aprobar), reasignaciones de cobertura, gates de flujos legacy detrás del flag `field_payment_orders_v1`, panel admin (bandeja de revisión, configuración de seguros e instrucciones de pago), flujo completo en la app Flutter (emitir orden, PDF, comprobante, timeline) con i18n en 4 locales, observabilidad con eventos estructurados y documentación canónica actualizada con runbook de piloto. Todo en branches `feat/field-payment-orders`; nada aplicado contra Neon.

## 2. Tareas del plan

| Fase/Tarea | Estado | Commit(s) | Notas |
|---|---|---|---|
| F0 — branches, baseline, canon + flag | ✅ | raíz `d99bc2c`, `9ce0971` | Canon del capacity model + definición del flag y `expiry_days` (default 15) |
| F1.1 — schema + migración | ✅ | backend `0f883ec` | `20260812220000_field_payment_orders`: 6 tablas, 4 enums, unique parcial `active_guard`, CHECK XOR de propósito |
| F1.2 — state machine + folio + flag service | ✅ | backend `d583a45` | SM pura; folio `ORD{year}{####}` con `FOR UPDATE`; expiry desde `system_config` |
| F1.3 — PDF | ✅ | backend `6094476` | PDFKit → Buffer con beneficiarios, totales, instrucciones banco/caja y disclaimer |
| F1.4 — comprobantes | ✅ | backend `6a3c843` | Pipe magic-bytes (PDF/JPG/PNG ≤10 MB), R2 privado, URL firmada TTL 15 min |
| F1.5 — API lifecycle + permisos | ✅ | backend `2a76017` | Controller + service kernel con puertos de fulfillment; seeds `field-payment-orders:*` |
| F2.1–2.2 — fulfillment seguros | ✅ | backend `413dc71`, `3609bed` | prepare valida ciclo/membresía/duplicados; fulfill materializa purchase+slots+assignments+bridge |
| F2.3 — reasignaciones | ✅ | backend `d777804` | Mismo club, sin cobertura duplicada en destino, approve mueve assignment + slot movement |
| F2.4 — dual-read + gates legacy seguros | ✅ | backend `b36fd39` | `coverage_source` en getMemberInsurance; alta directa y purchases qty bloqueados con flag ON |
| F3.1–3.2 — fulfillment camporees | ✅ | backend `e0a5d25` | Valida camporee activo, enrollment, seguro vigente, deadline; fulfill crea `camporee_members` aprobados |
| F3.3 — gate register legacy | ✅ | backend `c1a7723` | `FIELD_PAYMENT_ORDER_LEGACY_DISABLED` con flag ON |
| F3 e2e | ✅ | backend `13f4cb4` | Matriz e2e del ciclo completo (happy path, maker-checker, carreras, rollback de fulfillment) |
| F4 — config instrucciones de pago (API) | ✅ | backend `13f2fb2` | GET/POST `/payment-orders/config`; LF propio o admin global con `local_field_id` |
| F4 — admin | ✅ | admin `f71a0f4`, `a5aa52a`, `94ddd8c`, `ad10813` | Bandeja `/dashboard/payment-orders` (órdenes + reasignaciones), tab en detalle de camporee, `/dashboard/insurance/config` (productos, ciclos, instrucciones), i18n 4 locales |
| F5 — contexto emisor (API app) | ✅ | backend `dea9afa` | `GET /payment-orders/context`: flag + ciclos aplicables a la sección activa |
| F5 — app | ✅ | app `c657c2b` | Feature `payment_orders` completa (clean architecture), rutas GoRouter, FAB de seguros redirige al flujo nuevo, registro de camporee redirige a emitir orden, i18n 4 locales, 22 tests |
| F6 — observabilidad | ✅ | backend `4aa1e66` | Eventos `field_payment_order.{issued,proof_submitted,approved,rejected,cancelled,expired,fulfill_fail}` + `approve_latency_ms` |
| F6 — docs finales | ✅ | raíz `be50ec4` | ENDPOINTS (+18, total 757), SECURITY (RBAC + maker-checker), FRONTEND-INTEGRATION, SCHEMA refs + schema.prisma, gestion-seguros (con runbook), camporees |
| F7 — regresión global | ✅ | backend `cbabd21` | Ver §4; el fix de inventory fue el único ajuste requerido |
| F8 — reporte | ✅ | este documento | |

## 3. Desviaciones del plan

- **`GET /payment-orders/context`** no estaba en el plan base; se agregó para que la app decida entre flujo nuevo y legacy sin round-trips extra (flag + ciclos de seguro de la sección activa).
- **`local_field_id` opcional** en el upsert de configuración de pago: el liderazgo LF lo omite (se resuelve del actor); solo el admin global lo envía explícito.
- **Bandeja admin**: la pestaña de reasignaciones vive junto a la de órdenes en `/dashboard/payment-orders` (el plan las trataba por separado).
- **App**: no existe carpeta `test/features/insurance` (el comando de regresión del plan la asumía); la cobertura equivalente vive en `test/features/payment_orders` + `test/features/camporees`.
- **Iconos**: `strokeRoundedTent` no existe en hugeicons 1.1.5 → `strokeRoundedCampfire`; en admin `ShieldPlus`/`ArrowLeftRight` → `Shield`/`ArrowRightLeft`.

## 4. Tests

| Repo | Comando | Resultado |
|---|---|---|
| backend | `npm test` | 3344 passed / 33 skipped / **7 failed preexistentes** (solo `verify-iana-timezone-real-gpg.spec.ts`; falla igual sin estos cambios — GnuPG 2.5.21 local, ambiental) |
| backend | `npx tsc --noEmit -p tsconfig.build.json` | limpio |
| backend | `npx prisma validate` | válido |
| app | `flutter test test/features/payment_orders` | 22/22 passed |
| app | `flutter test test/features/camporees` | 106/106 passed |
| app | `flutter analyze` | 0 errores (2 warnings preexistentes en classes/dashboard) |
| admin | `npx vitest run src/components src/lib --exclude '**/.worktrees/**'` | 673/674 passed; el fallido (`monthly-report.test.tsx`) es timeout bajo carga de suite completa y **pasa en aislamiento** |
| admin | `npm run typecheck` | limpio |

Nota F7: la suite `club-assignment-effectivity.inventory.spec.ts` detectó (correctamente) las 3 queries nuevas de membresía sin clasificar; se clasificaron como `effectiveWhere|T09` en el inventario endurecido (`cbabd21`).

## 5. Archivos modificados/creados

**Backend** (`src/field-payment-orders/` nuevo): schema.prisma + migración `20260812220000`, `state-machine.ts`, `folio.service.ts`, `field-payment-orders-flag.service.ts`, `field-payment-order-pdf.service.ts`, `proof-file-validation.pipe.ts`, `field-payment-order-proof.service.ts`, `field-payment-orders.{service,controller,module}.ts`, `field-payment-order-configs.service.ts`, `insurance-reassignments.{service,controller}.ts`, `fulfillment/{ports,insurance-fulfillment.service,camporee-fulfillment.service}.ts`, `order-actor.ts`, DTOs, specs unitarios + `test/field-payment-orders.e2e-spec.ts`. Modificados: `app.module.ts`, `insurance/insurance.service.ts`, `insurance/insurance-purchases.service.ts`, `camporees/camporees.{service,module}.ts`, `common/errors/error-codes.ts`, i18n errors (4 locales), seeds de permisos, `common/authorization/club-assignment-effectivity.inventory{,.spec}.ts`.

**Admin**: `src/lib/api/{field-payment-orders,insurance-config}.ts`, `src/components/payment-orders/*` (tray, detail, reassignments, camporee tab, errores, format + tests), `src/components/insurance/*` (config client, products, cycles, payment instructions + tests), páginas `/dashboard/payment-orders` y `/dashboard/insurance/config`, sidebar + permisos, `messages/{es,en,fr,pt-BR}.json`.

**App**: `lib/features/payment_orders/**` (entities, models, datasource, repository, providers, widgets, 3 vistas), `core/config/{route_names,router}.dart`, `core/constants/api_endpoints.dart`, `features/insurance/presentation/views/insurance_view.dart`, `features/camporees/presentation/views/camporee_register_member_view.dart`, `assets/translations/{es,en,fr,pt-BR}.json`, `test/features/payment_orders/**` (3 archivos, 22 tests).

**Docs (raíz)**: `docs/api/{ENDPOINTS-LIVE-REFERENCE,SECURITY-GUIDE,FRONTEND-INTEGRATION-GUIDE}.md`, `docs/database/{SCHEMA-REFERENCE.md,schema.prisma}`, `docs/features/{gestion-seguros,camporees}.md`, `docs/plans/handoffs/field-payment-orders-admin-handoff.md`, este reporte.

## 6. Decisiones tomadas durante la ejecución

- **Puertos de fulfillment** (`INSURANCE_FULFILLMENT_PORT` / `CAMPOREE_FULFILLMENT_PORT`) para mantener el kernel agnóstico del propósito; agregar un propósito nuevo no toca el kernel.
- **FKs del kernel solo en SQL** (no relaciones Prisma hacia users/clubs/etc.) para mantenerlo autocontenido; las lecturas cruzadas usan queries explícitas.
- **Lazy expiry** en listados/lecturas en vez de cron: sin infra nueva y las órdenes vencidas liberan `active_guard` al primer acceso.
- **Serialización de aprobaciones concurrentes** con `update … where status='PROOF_SUBMITTED'` dentro de la transacción (perder la carrera → 409).
- **Montos en centavos** (enteros) en órdenes; los ciclos legacy exponen `unit_cost` decimal en pesos y el cliente convierte.
- **App**: con flag ON el FAB de seguros y la vista de inscripción a camporee redirigen al flujo de órdenes (el backend bloquea legacy de todas formas); con flag OFF la UI legacy queda intacta.
- **Bridge `member_insurances`** en el fulfillment de seguros para no romper el FK que exige camporees.

## 7. Pendientes y riesgos

- ~~Migración NO aplicada a Neon~~ → **Migración `20260812220000_field_payment_orders` aplicada y registrada en `_prisma_migrations` en los 3 entornos Neon** (2026-08-12): development (`ep-rough-hill`), staging (`ep-noisy-breeze`) y production (`ep-dark-thunder`). Verificado en cada uno: 6 tablas, permisos, grants y keys de config.
- ~~Seeds NO aplicados~~ → **Seeds de permisos** (`field-payment-orders:*`, 6 permisos / 34 grants) y **keys de `system_config`** (`field_payment_orders_v1`, `field_payment_orders.expiry_days=15`) **aplicados en dev, staging y production**.
- **Flag por entorno**: dev `[4]` (piloto Asociación Centro de Veracruz, con producto/ciclos/instrucciones de prueba sembrados); staging y production `[]` (OFF). Encender en producción sigue el runbook de `docs/features/gestion-seguros.md` §Runbook (seed de productos/ciclos reales, instrucciones de pago, drain de purchases pendientes, flag ON, rollback).
- **Drain de purchases legacy pendiente** antes de encender el flag en un LF.
- **Fallos preexistentes del baseline**: `verify-iana-timezone-real-gpg.spec.ts` (7 tests, ambiental por versión local de GnuPG); `monthly-report.test.tsx` en admin es flaky por timeout bajo suite completa.
- Camporees de unión quedan fuera (v1.1); el flujo nuevo solo cubre camporees locales.
- PRs abiertos hacia `development` (pendientes de merge): backend [#392](https://github.com/abn-r/sacdia-backend/pull/392), admin [#211](https://github.com/abn-r/sacdia-admin/pull/211), app [#142](https://github.com/abn-r/sacdia-app/pull/142).

## 8. Verificación manual sugerida

1. Aplicar migración + seeds en Neon dev; agregar un `local_field_id` de prueba a `field_payment_orders_v1`.
2. Admin (director LF): `/dashboard/insurance/config` → crear producto + ciclo del año, capturar instrucciones de pago (banco y/o caja).
3. App (director de club del LF piloto): Seguros → FAB → seleccionar 2 miembros elegibles → emitir orden → ver PDF (folio `ORD2026…`, instrucciones correctas) → subir comprobante (JPG/PDF).
4. Admin (otro usuario LF, maker-checker): `/dashboard/payment-orders` → abrir orden → aprobar → verificar en app que los 2 miembros aparecen con seguro activo; probar rechazar otra orden con motivo y re-subir comprobante.
5. Camporee local con costo configurado: app → inscripción → verificar redirección a emitir orden; aprobar en admin y confirmar que los `camporee_members` aparecen; verificar que `POST /camporees/:id/register` directo responde `FIELD_PAYMENT_ORDER_LEGACY_DISABLED`.
6. Dejar una orden sin comprobante y adelantar `expires_at` en DB → listar → debe pasar a `EXPIRED` y permitir emitir una nueva para los mismos beneficiarios.
7. Reasignación: solicitar transferencia de cobertura a otro miembro del mismo club sin seguro → aprobar en admin → verificar movimiento.
