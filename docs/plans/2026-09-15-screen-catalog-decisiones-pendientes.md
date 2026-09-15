# Screen catalog — cierre de decisiones pendientes (oleada 2c)

**Fecha:** 2026-09-15  
**Estado:** PLAN — para ejecución por subagente  
**Contexto padre:** `docs/plans/2026-09-15-admin-screen-capability-catalog-design.md` (oleadas 1, 2, 2b hechas)  
**Repos tocados:** `sacdia-admin` (seguro), `sacdia-backend` (solo si la evidencia lo exige), `docs/`

## Reglas duras para quien ejecute

- Trabajar en las ramas actuales. **No** crear ramas ni worktrees. **No** commitear. **No** ejecutar builds (`next build`, `nest build`).
- Leer `AGENTS.md` raíz. Verificar antes de afirmar: cada gate del catálogo copia literalmente `@RequirePermissions` + `@GlobalRoles` del endpoint (o una regla de servicio con `exactRoles: true`). Nunca inventar OR de permisos.
- No tocar `sacdia-admin/src/app/(dashboard)/dashboard/payment-orders/**` ni `src/components/payment-orders/**` (WIP local del usuario).
- Al terminar cada tarea: `npx vitest run <rutas afectadas>` y `npx eslint <archivos>` en `sacdia-admin`; `npx jest <spec>` en `sacdia-backend` si se tocó. `npx tsc --noEmit -p tsconfig.json` filtrado a los archivos tocados (hay errores preexistentes ajenos en `activities/*`, `clubs/actions.ts:854`, `scope-options.test.ts`; ignorarlos).
- Actualizar `docs/features/rbac.md` y la sección "Estado de implementación" del plan padre en el mismo trabajo.

## Contexto técnico mínimo

- Catálogo: `sacdia-admin/src/lib/auth/screen-catalog/`. API pública: `canCapability(user|subject, screenId, capId)`, `canViewScreen`, `getScreen`, `camporeeScreenId(kind)`; tipos en `types.ts` (`CapabilityGate` con `exactRoles?`). Tests: `screen-catalog.test.ts` (integridad: ids únicos, hoja de sidebar ↔ pantalla, claves ⊆ `permissions.ts` y ⊆ seeds+migraciones del backend), `matrix-plan.test.ts`, `screen-title.test.ts`.
- Pantallas de camporees: `screens/campamentos.ts`. `campamentos-list-{local,union}` comparten `CAMPOREE_DETAIL_CAPABILITIES` (`events.update` = `camporee_events:update`); `campamentos-judges.manage` = `camporee_events:update`.
- Backend camporees: `sacdia-backend/src/camporee-scoring/camporee-scoring.controller.ts` (judges / judge-assignments: `@RequirePermissions('camporee_events:update')` en escrituras, sin `@GlobalRoles`), `camporee-scoring.service.ts`, `camporee-events.controller.ts`.
- Seeds: `sacdia-backend/prisma/seeds/role-permissions.seed.sql` (bloque `camporee_events:*` ≈ línea 2011: LF/Unión; `camporees:create` en roles CLUB `secretary`, `treasurer`, `secretary-treasurer`, `deputy-director`, `director`). Patrón de migración incremental de permisos: `prisma/migrations/20260823190000_seed_audit_read_permission/migration.sql`.

---

## Tarea 1 — `canManageCamporeeJudgeAssignments`: mover al catálogo

**Archivo:** `sacdia-admin/src/lib/camporee-scoring/permissions.ts` (+ `permissions.test.ts`).  
**Callers:** `app/(dashboard)/dashboard/campamentos/[id]/page.tsx:215`, `campamentos/union/[id]/page.tsx:207`, `lib/camporee-scoring/actions.ts:72`.

Hoy: `hasAnyPermission([camporee_events:update, camporees:update]) || rol admin/super-admin || (isUnion ? director-union/assistant-union : director-lf/assistant-lf)`.

1. Verificar en `camporee-scoring.controller.ts` y `camporee-scoring.service.ts` que `POST camporee-events/:eventId/judge-assignments`, `PATCH/DELETE camporee-event-judge-assignments/:assignmentId`, `POST */judges`, `PATCH/DELETE camporee-judges/:judgeId` exigen exactamente `camporee_events:update` y **no** aceptan `camporees:update` ni tienen fallback por rol en el servicio (buscar `role_name`, `AppForbiddenException` en el service; las líneas 86/102/254 leen roles — determinar si son para autorizar o para poblar candidatos).
2. Si se confirma (esperado): reemplazar el helper por el catálogo.
   - En los dos pages: `canCapability(user, camporeeScreenId(isUnion ? "union" : "local"), "events.update")` (o `campamentos-judges.manage`; elegir uno y usarlo en los tres callers; preferir `events.update` porque los pages son el detalle del camporee).
   - En `actions.ts`: mismo `canCapability`; mantener el mensaje de error existente.
   - Borrar `lib/camporee-scoring/permissions.ts` y su test si quedan sin consumidores. Si algo más los usa, dejar el archivo como wrapper delgado sobre `canCapability` y actualizar el test para reflejar la nueva regla (rol solo no basta; permiso sí basta).
3. Si el servicio **sí** tiene fallback por rol: declarar la regla en el catálogo con `exactRoles: true` sobre una capability nueva `judges.assign` en `CAMPOREE_DETAIL_CAPABILITIES`, y usar esa capability. Documentar la fuente (archivo:línea).
4. Tests: `npx vitest run src/lib/camporee-scoring src/lib/auth/screen-catalog`. Añadir en `screen-catalog.test.ts` un caso: `director-lf` sin `camporee_events:update` → `false` para la capability elegida; con el permiso → `true`.

**Impacto de negocio a reportar:** roles LF/Unión sin `camporee_events:update` dejan de ver el botón de asignar jueces (antes veían y recibían 403). El seed ya da `camporee_events:update` a `assistant-lf`, `director-lf`, `assistant-union`, `director-union`, así que en datos frescos no cambia nada.

## Tarea 2 — Seed de camporees: ¿roles CLUB deben crear eventos?

Hallazgo previo: `camporees:create/update/delete` lo tienen roles **CLUB** (`secretary`, `treasurer`, `secretary-treasurer`, `deputy-director`, `director`); `camporee_events:*` lo tienen roles **GLOBAL** LF/Unión. La UI hacía OR y mostraba a los roles CLUB botones de eventos que devolvían 403; el catálogo ahora los oculta.

1. Determinar intención de producto con evidencia, no con suposiciones:
   - `sacdia-backend/src/camporees/camporees.controller.ts`: ¿qué crea `POST /camporees` para un rol CLUB (camporee de club vs. de campo local)? Leer `@AuthorizationResource`, DTO y servicio.
   - `camporee-events.controller.ts`: los eventos cuelgan de `local-camporees/:id` y `union-camporees/:id`. ¿Existe ruta de eventos para camporees de club? Si no existe, los roles CLUB **no** deben tener `camporee_events:*` y no hay nada que sembrar.
   - Comentario del seed (≈ línea 2011): "LF/Unión manage events, rubrics and leaderboard".
   - `docs/features/` (carpeta de camporees/campamentos si existe) y `docs/api/ENDPOINTS-LIVE-REFERENCE.md` sección camporee events.
2. Resultado esperado: **no sembrar**. Registrar la conclusión (con archivo:línea) en `docs/features/rbac.md` y en el plan padre, sección "Materiales y camporees", reemplazando la frase "Si esos roles deben crear eventos, el fix es en el seed" por la conclusión.
3. Solo si la evidencia muestra que roles CLUB sí operan eventos de camporees locales: crear `prisma/migrations/<timestamp>_grant_camporee_events_club_roles/migration.sql` siguiendo el patrón del audit (INSERT … ON CONFLICT DO NOTHING, `role_category = 'CLUB'`), reflejar en `role-permissions.seed.sql`, y actualizar `docs/database/` según `AGENTS.md`. No ejecutar `prisma migrate` contra ninguna DB.

## Tarea 3 — `confirm-union` y sucesión anual LF: documentar, no mover

Decisión: se quedan **fuera** del catálogo. Motivo: no son espejo de decorador.

- `confirm-union` (`sacdia-backend/src/annual-folders/evaluation.service.ts` ≈ 315-335): `@RequirePermissions('annual_folders:evaluate')` + regla de servicio `director-union`/`assistant-union` **sin** bypass de super-admin. El catálogo hace bypass de super-admin siempre; modelarla mostraría un botón que el API rechaza. UI: `EvaluationClientPage.currentUserRoles` / `UNION_CONFIRMATION_ROLES` en `sacdia-admin/src/components/annual-folders/evaluation-client-page.tsx:419`.
- Sucesión anual (`succeedClubSectionDirectorAction` en `sacdia-admin/src/lib/clubs/actions.ts` ≈ 744): regla solo-UI `director-lf`/`assistant-lf`; el API (`POST :clubId/sections/:sectionId/director-succession`, `club_roles:assign` + `club_roles:revoke` + scope de club) no la exige.

Hacer:

1. Añadir comentario breve en ambos puntos de la UI indicando que la regla es de servicio / solo-UI y por qué no está en el catálogo (una línea, sin ensayo).
2. En `docs/features/rbac.md`, sección Admin, dejar un bullet "Reglas fuera del catálogo" con las dos entradas, su fuente (archivo:línea) y el criterio: *entra al catálogo solo lo que copia un decorador o una regla de servicio con match literal y bypass de super-admin*.
3. Abrir en `docs/audit/DECISIONS-PENDING.md` (si existe; si no, en el plan padre) una entrada: "¿Formalizar en backend la regla LF-only de sucesión anual?" — para que el dueño del backend decida. No implementarlo.

## Entregable final del subagente

Un resumen con:

- Por tarea: qué se verificó (archivo:línea), qué se cambió, qué se descartó y por qué.
- Lista de archivos modificados/creados/borrados por repo.
- Salida resumida de vitest/eslint/jest ejecutados (números, no logs completos) y cualquier fallo preexistente encontrado.
- Cambios de comportamiento visibles para usuarios finales.
