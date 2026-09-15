# Screen catalog — plan de cierre (lo que queda)

**Fecha:** 2026-09-15  
**Estado:** PLAN — para ejecución manual o por agente, un bloque por sesión  
**Padre:** `docs/plans/2026-09-15-admin-screen-capability-catalog-design.md` (oleadas 1–2d hechas, 945/945 tests admin)  
**Orden recomendado:** 0 → 1 → 2 → 3 → 4 → 5. Los bloques 1–3 son independientes entre sí; 4 depende de 0; 5 depende de todo lo anterior.

## Convenciones (aplican a todos los bloques)

- Leer `AGENTS.md` raíz. Ramas actuales; sin worktrees; sin builds. Commits solo en el bloque 5.
- **Gate = espejo literal del endpoint**: `permissions` = `@RequirePermissions` del método; `roles` = `@GlobalRoles` efectivo (método pisa clase); regla de servicio con match literal → `exactRoles: true` + comentario `archivo:línea`. Nunca OR inventado. Si el endpoint tiene `@SkipPermissions`, el gate es solo `roles`.
- Verbo = capability `{ id, kind, gate }` en el archivo `screens/<familia>.ts` que ya posee la pantalla. Consumidores: `canCapability(user, screenId, capId)` / `canViewScreen(user, screenId)` (puras; sirven en pages, server actions y componentes cliente con `useAuth()`), `useScreenAccess()` en cliente.
- Claves nuevas → constante en `sacdia-admin/src/lib/auth/permissions.ts`, sección de su familia. `screen-catalog.test.ts` exige que toda clave exista ahí **y** en `sacdia-backend/prisma/**/*.sql`; una clave no sembrada no se usa y se reporta.
- Tests: casos en el `screen-catalog.<familia>.test.ts` existente (o crearlo). Tests de componentes que mockeen `hasPermission` → pasar permisos reales en `useAuth`/`requireAdminUser` con `authorization: { grants: { global_roles }, effective: { permissions } }`.
- Cierre de cada bloque: `npx vitest run <rutas> src/lib/auth/screen-catalog`, `npx eslint <archivos>`, `npx tsc --noEmit -p tsconfig.json 2>&1 | rg "<archivos>"`. Preexistentes a ignorar: `activities/*` (lucide `Repeat`), `class-honors-dialog.tsx`, `clubs/actions.ts:855`, `scope-options.test.ts`, `jueces/page.tsx prefer-const`.
- Docs en el mismo bloque: `docs/features/rbac.md` (bullet corto) y sección "Estado de implementación" del plan padre.

---

## Bloque 0 — Cerrar el WIP de `payment-orders` (prerequisito de 4)

**Estado:** HECHO 2026-09-15. El WIP de tabs se cerró al migrar al catálogo (3 tabs reales).

Estado: `sacdia-admin` tiene sin commitear `src/app/(dashboard)/dashboard/payment-orders/page.tsx`, `src/components/payment-orders/payment-orders-client.tsx`, `payment-order-tabs.ts` (+ test) y un stash `fix/auth-materials-territory-ui: wip materials territory ui`. Nadie del catálogo lo tocó.

1. Decidir si ese WIP se termina, se commitea aparte o se descarta. Terminarlo primero; el catálogo no debe mezclarse con él.
2. Cuando esté limpio, migrar la página al catálogo:
   - `payment-orders/page.tsx:29-50`: `isSuperAdmin || hasAnyPermission(...)` por tab → declarar en `screens/operations.ts` (`payment-orders`) capabilities `kind: "tab"`: `pending` (`camporee-orders:read` | `camporee-supplies:read`), `field` (`field-payment-orders:review` | `field-payment-orders:read`), `materials` (`materiales:read`), `reassignments` (`insurance:read`). Verificar cada OR contra el controlador correspondiente: un OR solo es válido si el tab agrega datos de varios endpoints y cada clave abre uno de ellos (hub). Documentarlo en el comentario de la capability.
   - `PAYMENT_ORDERS_PAGE_PERMISSIONS` sigue siendo la unión de esos tabs; `viewAny` no cambia.
   - `payment-orders-client.tsx`: si decide visibilidad de tabs, recibir booleans desde la page o usar `useScreenAccess()`.
3. Tests: `screen-catalog.operations.test.ts` (un caso por tab); tests existentes de payment-orders.

## Bloque 1 — Residuos admin: pages con gate ad hoc (≈1 h)

**Estado:** HECHO 2026-09-15.

Todas son `hasPermission`/`hasAnyPermission` con clave única (sin OR) salvo donde se indica. Regla: entrada → `canViewScreen`; botones → `canCapability`.

| Page | Línea | Hoy | Pantalla / capability |
|---|---|---|---|
| `clubs/activities/page.tsx` | 74 | `hasAnyPermission([ACTIVITIES_READ])` | `canViewScreen("activities")` |
| ídem | 87-88 | `ACTIVITIES_CREATE`, `ACTIVITIES_UPDATE` | `activities.create`, `activities.update` (declarar en `screens/clubs.ts`; verificar `sacdia-backend/src/activities/*.controller.ts`; si hay `delete` en UI, también) |
| `configuration/notifications/page.tsx` | 23-25 | OR `NOTIFICATIONS_SEND \| BROADCAST \| CLUB` | `canViewScreen("notifications-hub")` (el `viewAny` ya es ese OR: hub) |
| `configuration/notifications/history/page.tsx` | 46-48 | tres `hasPermission` | `notifications-hub.{send_direct,broadcast,send_club}` en `screens/notifications.ts`; verificar `sacdia-backend/src/notifications/*.controller.ts` |
| `resources/page.tsx` | 217, 299-301 | `RESOURCES_READ`, `_CREATE/_UPDATE/_DELETE` | `canViewScreen("resources-list")`, `resources-list.{create,update,delete}` en `screens/operations.ts`; verificar `src/resources/*.controller.ts` (¿`@GlobalRoles`? ¿scope por territorio en servicio?) |
| `resources/categories/page.tsx` | 99, 131-133 | `RESOURCE_CATEGORIES_*` | `canViewScreen("resources-categories")`, `resources-categories.{create,update,delete}` |
| `coordination/page.tsx` | 27 | `COORDINATION_MANAGE` | `canViewScreen("coordination")` |

Server actions que deben usar la misma capability que su botón:

| Action | Líneas | Migrar a |
|---|---|---|
| `lib/notifications/actions.ts` | 78, 112, 144 | `notifications-hub.{send_direct,broadcast,send_club}` |
| `lib/resources/resource-actions.ts` | 158, 180, 207 | `resources-list.{create,update,delete}` |
| `lib/resources/category-actions.ts` | 75, 98, 123 | `resources-categories.{create,update,delete}` |

Test: casos en `screen-catalog.operations.test.ts` (resources) y nuevo `screen-catalog.notifications.test.ts`.

## Bloque 2 — Residuos camporees: OR `camporee_events:* || camporees:*` en actions (≈45 min)

**Estado:** HECHO 2026-09-15.

El API de eventos/venues/scoring solo acepta `camporee_events:*` (verificado en 2b: `camporee-events.controller.ts`, `camporee-scoring.controller.ts`). Estos actions aún aceptan la mitad muerta; el botón ya está gated por catálogo, así que hoy es inconsistencia, no agujero (el API rechaza igual).

| Action | Líneas | Migrar a |
|---|---|---|
| `lib/camporee-events/actions.ts` | 299, 330, 365, 450, 482, 514, 543, 572, 613, 741, 774, 807, 848, 885, 923 | `canCapability(user, camporeeScreenId(kind), "events.create\|update\|delete")` cuando el action sabe si es local/unión; si es de plantillas → `campamentos-plantillas.{create,update,delete}` |
| `lib/camporee-venues/actions.ts` | 54, 113, 137 | Verificar `sacdia-backend/src/camporee-venues/*.controller.ts` (¿`camporee_events:*` o clave propia `camporee_venues:*`?). Declarar `venues.{create,update,delete}` en `CAMPOREE_DETAIL_CAPABILITIES` con la clave real |
| `lib/camporee-scoring/actions.ts` | 64 (`assertCanUpdateScoring`), 391 | `events.update`; la 391 es lectura de leaderboard: `canViewScreen` de la pantalla que la usa o capability `scoring.read` = `camporee_events:read` |

Cómo saber el `kind` en cada action: mirar su firma (`scope`, `camporeeType`, `isUnion`, ruta `union-camporees/*`). Si un action es agnóstico, usar `campamentos-list-local` con comentario "gates idénticos en ambos" (patrón ya usado en `camporee-order-detail.tsx`).

## Bloque 3 — Master honors (≈30 min, decisión incluida)

**Estado:** HECHO 2026-09-15. Decisión: **exponer** (no deep-link, no borrar).

- API: `admin-phase-e-catalogs.controller.ts` L651-722 — `honors:{read,create,update,delete}` + clase `@GlobalRoles('admin','super-admin')`. Recalc POST = `honors:update`.
- Pantalla `catalogs-master-honors` en `catalogs-domain.ts` (mismas claves que `catalogs-honors`; un grant abre las dos).
- Sidebar hoja bajo Especialidades; alias `catalog_master_honors`.
- Page `/dashboard/catalogs/master-honors` (`PhaseECatalogCrudPage` + extras).
- Actions → `canCapability(user, "catalogs-master-honors", create|update|delete)`. Recalc reusa `update`.
- Constante `MASTER_HONORS_MANAGE` retirada (nunca sembrada; el OR `master_honors:manage || catalogs:*` era letra muerta).

## Bloque 4 — Oleada 3: app Flutter (diseño + primer corte, 1–2 sesiones)

**Estado:** HECHO 2026-09-15. Opción **B** (registro Dart hermano). Documentado en `DECISIONS-PENDING.md`.

- `evaluateAccess` + alias + pantallas `app` en `sacdia-app/lib/core/authorization/`.
- Quick access y tabs Clases/Actividades por `screenId`.
- Fixture `sacdia-app/test/fixtures/screen-catalog.snapshot.json` = `dumpAppCatalog()` admin.
- Hub app `coordinator-hub` ≠ admin `coordination`. Judge tile sigue por asignación.

## Bloque 5 — Commits (3 repos) y limpieza

**Estado:** HECHO 2026-09-15. Orden: backend → admin → app → docs. Admin quedó en **un** commit: las oleadas 1–2d y los residuos 0–4 estaban mezclados en el working tree; cortar por oleada habría dejado HEAD intermedios rotos (helpers borrados que las pages viejas aún importaban). El WIP de payment-orders ya estaba cerrado (bloque 0) y viajó en el mismo commit.

1. **sacdia-backend** (`perf/dashboard-summary-round-trips` `2717db8`)  
   `feat(admin): open user list and detail to field-level roles via USER_MANAGEMENT_ROLES`  
   Archivos: `src/admin/admin-users.controller.ts`, `src/admin/admin-users.controller.spec.ts`. Jest 10/10 y eslint en verde. `test/.DS_Store` no se commiteó.
2. **sacdia-admin** (`development` `7eda2e5`)  
   `feat(auth): add screen capability catalog and migrate admin gates to it`  
   177 files: núcleo `screen-catalog/**`, sidebar, page gate, users, matriz/picker, i18n, páginas/actions de oleadas 2–2d, master honors, tabs de payment-orders, y baja de `NAV_ITEM_ACCESS` / `director-succession` / `use-can-manage-users` / `camporee-scoring/permissions`.
3. **sacdia-app** (`development` `fe821117`)  
   `feat(auth): gate quick access with screen catalog sibling`  
   `lib/core/authorization/**`, `quick_access_grid`, `router`, tests, fixture. Fuera: imágenes welcome y `Untitled`.
4. **docs (repo raíz)**  
   `docs(rbac): document screen capability catalog waves 1-2d and app sibling`  
   Archivos: `docs/features/rbac.md`, `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, `docs/canon/auth/{modelo-autorizacion,runtime-auth}.md`, `docs/api/FRONTEND-INTEGRATION-GUIDE.md`, `docs/audit/DECISIONS-PENDING.md`, `docs/plans/2026-09-15-*.md` (solo los de catálogo). No se arrastró presentación, imágenes, `.cursor/`, `graft/`, ni `AGENTS.md`.
5. Limpieza: `graft build` al final para reindexar.

## Decisiones abiertas que este plan no resuelve (dueño: backend/producto)

Registradas en `docs/audit/DECISIONS-PENDING.md`; el plan solo las lista para que no se pierdan.

- Vencimientos de seguros (`GET /insurance/expiring`) → **HECHO 2026-09-15**: `admin`/`coordinator`; `director-lf`/`assistant-lf` entran por alias de coordinator (union/dia fuera). Recorte LF a su `local_field`. Pastor y roles CLUB fuera.
- Sucesión anual de director → **HECHO 2026-09-15**: UI alineada al API. `clubs.succeed_director` = `director-lf` / `assistant-lf` / `admin` / `super-admin` (no `deputy-director`). Backend sin cambio.
- Ideales / tipos de club y años eclesiásticos → **HECHO 2026-09-15**: Crear/Eliminar solo `super-admin`. PATCH de años sigue en admin.
- Coordinator `investiture:mark_invested` → **HECHO 2026-09-15**: seed + migración para coordinator/zone/general.
- `director-lf`/`assistant-lf` ≡ coordinator (investidura, SLA, tickets) → **HECHO 2026-09-15**: alias `coordinator` (no listing `director-lf` en el decorador).
- 15 pantallas sin clave en `nav.items` → **HECHO 2026-09-15**: claves snake_case en `nav.items` (es/en/fr/pt-BR) + alias `clubs-evidence-folders-templates` → `annual_folders_templates`. Matriz/picker ya no caen al título literal del sidebar.

## Criterio de éxito global

- `rg -n "hasPermission\(|hasAnyPermission\(" sacdia-admin/src/app sacdia-admin/src/components sacdia-admin/src/lib --glob '!*.test.*' --glob '!**/permission-utils.ts'` devuelve **0** líneas fuera de `permission-utils.ts` y de helpers documentados como "fuera del catálogo" (`confirm-union`, `canViewAdministrativeCompletion`).
- `rg -n "extractRoles\(" sacdia-admin/src/app --glob '*.tsx'` devuelve solo `investiture/pipeline` (variante de vista) y `users/new` (jerarquía).
- Suite admin en verde; `screen-catalog.test.ts` sin allowlist nueva.
- App: quick access gateado por `screenId`; test de paridad en verde en ambos repos.
- Cuatro commits (backend, admin, app, docs); `git status` limpio de este trabajo (otros cambios de raíz ajenos al catálogo siguen fuera).
