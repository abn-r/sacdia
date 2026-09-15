# Screen catalog — oleada 2d: familias restantes en paralelo

**Fecha:** 2026-09-15  
**Estado:** EJECUTADO 2026-09-15 (4 subagentes Grok 4.6 en paralelo; consolidación y resultados en el plan padre, sección "Oleada 2d")  
**Padre:** `docs/plans/2026-09-15-admin-screen-capability-catalog-design.md`  
**Repo:** solo `sacdia-admin` (backend es fuente de verdad de solo lectura)

## Reglas duras (todos los agentes)

- Leer `AGENTS.md` raíz y este plan completo. Verificar en código antes de afirmar.
- Ramas actuales. **No** crear ramas/worktrees. **No** commitear. **No** builds.
- **Cada gate copia literalmente el endpoint**: `permissions` = `@RequirePermissions(...)` del método; `roles` = `@GlobalRoles` efectivo (método sobre clase). Reglas de servicio con match literal → `exactRoles: true` con archivo:línea en comentario. **Nunca** inventar OR: si la UI hoy hace `X_CREATE || CATALOGS_CREATE` y el endpoint solo acepta una clave, el gate lleva solo esa clave. Si el endpoint acepta varias (`@RequirePermissions('a','b')` con modo any), entonces sí van las dos.
- Un verbo = una capability con `id` estable en snake_case (`create`, `update`, `delete`, `publish`, `review`, `certify`, `configure`, …). `kind`: `button` para acciones, `route` para subrutas con `href`, `section` para bloques, `tab` para pestañas.
- `viewAny` no se toca salvo que el agente demuestre con archivo:línea que hoy apunta a una clave que el GET principal no acepta (como pasó con `club_ideals:read`). Si se cambia, decirlo en el resumen.
- Claves nuevas: agregar constante en `sacdia-admin/src/lib/auth/permissions.ts` **dentro de la sección de su familia**, sin reordenar nada más. `screen-catalog.test.ts` exige que toda clave exista en `permissions.ts` y en `sacdia-backend/prisma/**/*.sql`; si una clave no está sembrada, **no** se usa y se reporta.
- **Archivos compartidos prohibidos** (los edita el orquestador después): `screen-catalog/index.ts`, `screen-catalog/types.ts`, `screen-catalog/evaluate.ts`, `screen-catalog/screen-title.ts`, `screen-catalog/screen-catalog.test.ts`, `screens/_helpers.ts`, `screens/users.ts`, `screens/clubs.ts`, `screens/campamentos.ts`, `screens/admin-system.ts`, `screens/home.ts`, `screens/notifications.ts`, `docs/**`, `messages/*.json`, `src/i18n/messages.d.ts`. Tampoco `payment-orders/**` ni `components/payment-orders/**` (WIP del usuario).
- Tests: cada agente crea **su** archivo `sacdia-admin/src/lib/auth/screen-catalog/screen-catalog.<familia>.test.ts` (patrón: copiar `buildUser` de `screen-catalog.test.ts`; casos: permiso sin rol / rol sin permiso / OR viejo que ya no pasa / caso positivo). Actualizar tests existentes de pages/componentes que mockeen `hasPermission`/`hasAnyPermission` pasando permisos efectivos reales en `useAuth`/`requireAdminUser` (`authorization: { grants: { global_roles: [...] }, effective: { permissions: [...] } }`).
- Al terminar: `npx vitest run <rutas tocadas> src/lib/auth/screen-catalog`, `npx eslint <archivos>`, `npx tsc --noEmit -p tsconfig.json 2>&1 | rg "<tus archivos>"`. Errores preexistentes ajenos a ignorar: `activities/*`, `clubs/actions.ts:855`, `scope-options.test.ts`, lucide `Repeat`, `jueces/page.tsx prefer-const`.

## API del catálogo (lectura)

- `canCapability(user | subject, screenId, capabilityId)` y `canViewScreen(user, screenId)` — puras, sirven en server pages, server actions y componentes cliente (`const { user } = useAuth()`).
- `useScreenAccess()` (cliente) → `{ canCapability, canViewScreen }` si ya se usa `usePermissions()`.
- Tipos: `ScreenDefinition`, `ScreenCapability`, `CapabilityGate` en `types.ts`. Helpers `catalogEditorAccess(perms)` (= perms + roles admin/super-admin), `roleOnlyAccess(roles)`, `viewOnlyScreen(id, viewAny)` en `_helpers.ts`.
- Ejemplo de referencia: `screens/users.ts` y `screens/operations.ts` (bloque materiales).

## Entregable por agente

Resumen con: por pantalla, capabilities declaradas y endpoint espejo (archivo:línea); pages/componentes migrados; ORs eliminados y su impacto (qué rol pierde/gana botón, con evidencia del seed si aplica); claves faltantes en seed; archivos tocados; números de vitest/eslint; errores tsc en archivos propios. **No** editar docs: el orquestador consolida.

---

## Agente A — Investidura, inscripciones y certificaciones GM

**Archivo propio:** `screens/investiture.ts` (pantallas `enrollments`, `certifications-list`, `certifications-reviews`, `certificate-bulk-imports`, `investiture-pending`, `investiture-pipeline`, `investiture-config`, `catalogs-certifications`).

Backend: `sacdia-backend/src/investiture/`, `src/club-enrollments/`, `src/certifications/`, `src/certificate-bulk-imports/`, `src/classes/` (progresión). Docs: `docs/features/certificaciones-guias-mayores/`, `docs/features/validacion-investiduras/`, `docs/features/clases-progresivas/`, `docs/api/ENDPOINTS-LIVE-REFERENCE.md`.

Gates ad hoc conocidos:
- `app/(dashboard)/dashboard/certifications/reviews/page.tsx:20` `hasPermission(user, CERTIFICATIONS_REVIEW)` → `canViewScreen("certifications-reviews")`.
- `components/certifications/final-review-tray.tsx:88` `can(CERTIFICATIONS_CERTIFY)` (hook `usePermissions`) → capability `certify` en `certifications-reviews` vía `useScreenAccess()`.
- `app/(dashboard)/dashboard/catalogs/certifications/page.tsx:22-23` `CERTIFICATIONS_CONFIGURE` / `CERTIFICATIONS_PUBLISH` → capabilities `configure`, `publish` en `catalogs-certifications`.
- Buscar más con `rg -n "hasPermission\(|hasAnyPermission\(|can\(|canAny\(|extractRoles\(" src/app/\(dashboard\)/dashboard/{investiture,enrollments,certifications,certificate-bulk-imports} src/components/{investiture,enrollments,certifications,certificate-bulk-imports}`.

Declarar además los verbos que el API expone y la UI ya usa (aprobar/rechazar investidura, avanzar pipeline, importar certificados, etc.) aunque hoy no tengan gate en UI: revisar botones de esas pantallas y sus server actions en `src/lib/{investiture,certifications,enrollments,certificate-bulk-imports}/actions.ts`; si el action llama a un endpoint con `@RequirePermissions`, el botón debe estar detrás de la capability correspondiente. No declarar capabilities sin consumidor ni endpoint.

## Agente B — Seguros, finanzas, inventario de club

**Archivo propio:** `screens/operations.ts`, **solo** las entradas `finances`, `club-inventory`, `insurance-by-section`, `insurance-expiring`, `insurance-config`. **No** tocar `payment-orders`, `materials-*`, `resources-*` (ya migrados o WIP).

Backend: `sacdia-backend/src/insurance/`, `src/finances/`, `src/inventory/`, `src/payment-obligations/` (solo lectura para confirmar claves de instrucciones de pago). Docs: `docs/features/gestion-seguros/`, `docs/features/finanzas/`, `docs/features/inventario/`.

Gates ad hoc conocidos:
- `app/(dashboard)/dashboard/insurance/config/page.tsx:27-28` `INSURANCE_CONFIGURE` y `FIELD_PAYMENT_ORDERS_CONFIGURE` (verificar constante real) → capabilities `configure` y `configure_payment_instructions` en `insurance-config`.
- Buscar más en `src/app/(dashboard)/dashboard/{insurance,finances,inventory}` y `src/components/{insurance,finances,inventory}`, incluidos server actions en `src/lib/{insurance,finances,inventory}/actions.ts`.

## Agente C — Catálogos: geografía y taxonomía de club

**Archivo propio:** `screens/catalogs-geography.ts` (`catalogs-divisions`, `catalogs-countries`, `catalogs-unions`, `catalogs-local-fields`, `catalogs-districts`, `catalogs-churches`, `catalogs-club-ideals`, `catalogs-club-types`).

Backend: `sacdia-backend/src/admin/admin-reference.controller.ts` (club ideals/types, clase `@GlobalRoles('admin','super-admin')`), controladores de geografía en `src/admin/` o `src/catalogs/` (buscar `countries`, `unions`, `local-fields`, `districts`, `churches`). Ojo: la clase puede tener `@GlobalRoles` y el método otro; gana el método.

Pages con OR `X_* || CATALOGS_*` (todas en `src/app/(dashboard)/dashboard/catalogs/`): `divisions`, `countries`, `unions`, `local-fields`, `districts`, `churches`, `club-ideals`, `club-types`. Para cada una: leer el endpoint de create/update/delete, poner el gate exacto, migrar `canCreate/canEdit/canDelete` a `canCapability(user, "<screen>", "create|update|delete")`. Componentes cliente bajo `_components/` que repitan el check también.

Reportar por pantalla qué mitad del OR era falsa (clave que el API no acepta) y a qué roles afecta según `role-permissions.seed.sql`.

## Agente D — Catálogos: académicos, salud, negocio, honores, tipos

**Archivo propio:** `screens/catalogs-domain.ts` (`catalogs-classes`, `catalogs-class-modules`, `catalogs-class-sections`, `catalogs-activity-types`, `catalogs-ecclesiastical-years`, `catalogs-allergies`, `catalogs-diseases`, `catalogs-medicines`, `catalogs-relationship-types`, `catalogs-finance-categories`, `catalogs-inventory-categories`, `catalogs-honor-categories`, `catalogs-honors`). **No** tocar `catalogs-camporee-event-types` (ya migrado) ni `catalogs-certifications` (agente A).

Backend: `admin-reference.controller.ts` (salud, relación, actividad, años, finanzas/inventario categorías), `src/classes/` (clases, módulos, secciones), `src/honors/` o `src/catalogs/` (honores y categorías). Verificar si existen claves específicas (`classes:manage`, `honors:create`, `allergies:create`, …) en `prisma/**/*.sql`; si no están sembradas, la mitad `X_*` del OR era letra muerta y el gate es solo `catalogs:*` + rol admin (o lo que diga el método).

Pages: `classes` (+ `classes/[classId]` relaciones), `class-modules`, `class-sections`, `activity-types`, `ecclesiastical-years` (si tiene gates), `allergies`, `diseases`, `medicines`, `relationship-types`, `finance-categories`, `inventory-categories`, `honor-categories` (también su gate de entrada `:44`, que debe pasar a `canViewScreen`), `honors`. Mismo procedimiento que el agente C.
