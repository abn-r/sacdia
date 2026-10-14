# Alcance de coordinador en el dashboard de operaciones — Diseño

- **Fecha**: 2026-10-14
- **Repos**: `sacdia-backend` (principal), `sacdia-admin` (compatibilidad mínima)
- **Subproyecto**: 2 de 3 (1 base visual ✅ → **2 alcance de coordinador** → 3 rediseño del inicio por rol)
- **Estado**: aprobado para spec

## Contexto

El endpoint `GET /api/v1/analytics/operations-dashboard` alimenta el inicio del admin. Hoy los coordinadores (`coordinator`, `zone-coordinator`, `general-coordinator`) reciben 403 en dos capas:

1. `@GlobalRoles(...)` en `src/analytics/analytics.controller.ts` no los incluye.
2. `OperationsDashboardScopeService.resolveActorBaseScope` no los mapea y lanza `GUARD_PERMISSION_DENIED`.

El admin muestra `OperationsDashboardError` para ellos.

La regla canónica de autoridad del coordinador ya existe (PR #396): son los `club_section_ids` de sus asignaciones activas, resueltos por `CoordinationService.resolveCoordinatorScope(userId)` (`src/coordination/coordination.service.ts:408`). Esa función ya traduce `GENERAL` (campo, opcionalmente por tipo de club), `ZONE` y `SECTION` a secciones. Reportes, QR, seguros, camporees y admin-users filtran así.

Decisión del dueño (2026-10-14): **un solo nivel `coordinator` filtrado por `section_ids`**, no niveles `zone`/`section` nuevos.

## Objetivo

Que un coordinador reciba el dashboard de operaciones limitado a sus secciones asignadas, con desglose por club, sin filtrar datos entre coordinadores, y que el admin lo renderice sin error.

## Diseño — backend

### Tipos (`src/analytics/operations-dashboard.types.ts`)

```ts
export type OperationsDashboardScopeLevel =
  | 'all' | 'division' | 'union' | 'local_field' | 'coordinator';

export type ResolvedOperationsDashboardScope = {
  level: OperationsDashboardScopeLevel;
  id: number | null;
  name: string;
  path: OperationsDashboardScopePathNode[];
  /** Solo en level 'coordinator'. Ordenado ascendente, sin duplicados, no vacío. */
  section_ids?: number[];
};
```

`getOperationsDashboardChildLevel('coordinator')` → `'club'`. `OperationsDashboardChildLevel` no cambia. `OperationsDashboardScopePathNode.level` no cambia (el coordinador tiene `path: []`).

### Guard (`src/analytics/analytics.controller.ts`)

`@GlobalRoles` de `operations-dashboard` suma `'coordinator'`, `'zone-coordinator'`, `'general-coordinator'`. La descripción Swagger suma: "Coordinadores: solo sus secciones asignadas."

### Resolución de alcance (`src/analytics/operations-dashboard-scope.service.ts`)

Inyectar `CoordinationService` (el módulo ya importa `CoordinationModule`).

`resolveActorBaseScope` conserva el orden actual (super-admin → división → unión → campo → admin). Al final, antes del `GUARD_PERMISSION_DENIED`:

- Si tiene algún rol de `COORDINATOR_ROLES = {'coordinator','zone-coordinator','general-coordinator'}` → `{ level: 'coordinator', id: null }`.

En `resolve`, cuando `base.level === 'coordinator'`:

1. Si `filters` trae `divisionId`, `unionId` o `localFieldId` → 403 `GUARD_PERMISSION_DENIED` (no puede navegar fuera de su alcance). Mismo código que hoy para cualquier salida de alcance.
2. `const scope = await coordinationService.resolveCoordinatorScope(actorId)`.
3. Si `scope.club_section_ids` está vacío → 403 `ADMIN_USER_SCOPE_MISSING`.
4. Devuelve:
   ```ts
   {
     level: 'coordinator',
     id: null,
     name,            // ver abajo
     path: [],
     section_ids: [...new Set(scope.club_section_ids)].sort((a, b) => a - b),
   }
   ```

`name`:
- Si todas las asignaciones son `ZONE` y comparten `zone_id`, el nombre de la zona (`coordination_zones.name`, cargado con `prisma.coordination_zones.findUnique`). Si la zona no existe o está inactiva, cae al caso general.
- En cualquier otro caso: `'Secciones asignadas'`.

Un rol más amplio siempre gana: un usuario con `director-lf` + `coordinator` resuelve como campo local (sin cambio de comportamiento).

### Repositorio (`src/analytics/operations-dashboard.repository.ts`)

- `bucketExpression('coordinator')` → `c.club_id`.
- Lista de ids: `IN (${Prisma.join(scope.section_ids)})`, el mismo patrón que `analytics.service.ts:316` ya usa para secciones de coordinador. No usar `= ANY(...)`.
- `scopePredicate('coordinator')` → `cs.club_section_id IN (${Prisma.join(scope.section_ids)})`. Aplica a los 7 loaders que ya hacen `JOIN club_sections cs` (`loadOperations`, `loadPeople`, `loadClasses`, `loadMonthlyReports`, `loadHonors`, `loadActivities`, `loadQueues`).
- `loadAdministrativeClubs` no hace join a secciones. Para `coordinator` recibe un predicado distinto:
  ```sql
  c.club_id IN (
    SELECT cs2.main_club_id FROM club_sections cs2
    WHERE cs2.club_section_id IN (${Prisma.join(scope.section_ids)})
  )
  ```
  Implementación: nuevo método privado `clubScopePredicate(scope)` que devuelve `scopePredicate(scope)` para los demás niveles y la subconsulta para `coordinator`. `loadAdministrativeClubs` usa `clubScopePredicate`.
- `loadChildren('coordinator')`:
  ```sql
  SELECT DISTINCT c.club_id AS id, c.name
  FROM clubs c
  INNER JOIN club_sections cs ON cs.main_club_id = c.club_id
  WHERE cs.club_section_id IN (${Prisma.join(scope.section_ids)})
  ORDER BY c.name ASC, c.club_id ASC
  ```

### Caché (`src/analytics/operations-dashboard.service.ts`)

`cacheKey` para `coordinator` reemplaza `scope.id ?? 'all'` por `scope.section_ids.join(',')`:

```
operations-dashboard:coordinator:12,15,40:{year_id}:{month}
```

Dos coordinadores con secciones idénticas comparten entrada; con secciones distintas, nunca. El TTL de 60 s no cambia.

### Mapper (`src/analytics/operations-dashboard.mapper.ts`)

Sin cambio de lógica: `getOperationsDashboardChildLevel` ya decide el nivel hijo. `meta.scope` sale con `level: 'coordinator'`, `id: null`, `path: []`, `name`. **No** se expone `section_ids` en el DTO (es detalle interno; evita filtrar la estructura de asignaciones al cliente).

### DTO / Swagger (`src/analytics/dto/operations-dashboard.dto.ts`)

El enum de `level` en el DTO de scope suma `'coordinator'`.

### Tests (Jest, specs existentes)

`operations-dashboard-scope.service.spec.ts`:
- Reemplaza `rejects coordinators and club-only actors` por: coordinador con secciones → `{ level: 'coordinator', section_ids ordenados y sin duplicados, path: [] }`; club-only sigue en 403.
- Coordinador sin asignaciones activas → 403 `ADMIN_USER_SCOPE_MISSING`.
- Coordinador con `localFieldId` en filtros → 403 `GUARD_PERMISSION_DENIED`.
- Coordinador + `director-lf` → nivel `local_field` (precedencia).
- Nombre: todas `ZONE` con la misma zona → nombre de zona; mezcla → `'Secciones asignadas'`.

`operations-dashboard.repository.spec.ts`:
- Para `coordinator`, cada loader recibe el predicado por `cs.club_section_id` y `loadAdministrativeClubs` el predicado por club. `loadChildren` lista clubes distintos. Se verifica sobre los `Prisma.Sql` capturados (patrón del spec actual).

`operations-dashboard.service.spec.ts`:
- Dos coordinadores con `section_ids` distintos → dos llamadas al repositorio (sin colisión de caché). Mismos `section_ids` → una llamada.

Guard: hoy ningún spec lee la metadata de `@GlobalRoles` del controlador. Se agrega un test en `operations-dashboard.controller.spec.ts` que lee la metadata con `Reflect.getMetadata` sobre `AnalyticsController.prototype.getOperationsDashboard` y afirma que incluye los 3 roles de coordinador.

Comando: `pnpm run test -- operations-dashboard analytics.controller`.

## Diseño — admin (compatibilidad mínima)

`sacdia-admin`:

- `src/lib/api/operations-dashboard.ts`: `ScopeLevel` suma `"coordinator"`. `ChildLevel` no cambia.
- `src/components/dashboard/operations-dashboard-chrome.tsx`: ya muestra `meta.scope.name` y el breadcrumb a partir de `path`; con `path: []` solo se ve el nombre. Sin cambios de lógica, solo verificar con un test que `level: "coordinator"` renderiza el nombre y no el enlace de "reset" (no hay filtros territoriales).
- `src/components/dashboard/territory-breakdown-table.tsx`: `child.level === "club"` ya está cubierto. Sin cambios.
- `messages/*.json`: no hace falta clave nueva (`level.club` existe).
- Test: `operations-dashboard.test.tsx` suma un caso con `meta.scope = { level: "coordinator", id: null, name: "Zona Norte", path: [] }` y `children` de nivel `club`.

El rediseño por rol del inicio (incluida la vista propia de coordinador) es el subproyecto 3.

## Fuera de alcance

- Qué colas puede accionar el coordinador (el admin ya oculta enlaces sin acceso vía `firstAccessibleHref`; los conteos ya respetan `section_ids`).
- `sla-dashboard` y `local-field-dashboard` (ya tienen su propia lógica de coordinador).
- `sacdia-app` (Flutter) y `sacdia-admin-ios`.
- Rediseño visual del inicio.

## Entrega

Dos PRs independientes, en este orden:

1. **`sacdia-backend`** — `feat/operations-dashboard-coordinator-scope`, base `development`. Estimado < 400 líneas (tipos, guard, scope service, repositorio, caché, DTO, tests).
2. **`sacdia-admin`** — `feat/operations-dashboard-coordinator-level`, base `development`. Estimado < 60 líneas. Funciona aunque el backend aún no esté desplegado (solo agrega un caso al tipo y un test).

Commits convencionales en inglés, sin atribución de IA. Sin `pnpm build`.

## Verificación

- Backend: `pnpm run test -- operations-dashboard analytics.controller` verde; `pnpm run lint` sin errores nuevos.
- Manual (dueño): con un usuario coordinador de zona en `development`, `GET /api/v1/analytics/operations-dashboard` devuelve 200 con `meta.scope.level = "coordinator"`, `children` solo con clubes de su zona, y las colas con conteos ≤ a los del director de campo del mismo campo. El mismo request con `?local_field_id=` devuelve 403.
- Admin: `pnpm typecheck`, `pnpm test`; el coordinador ve el inicio sin `OperationsDashboardError`.

## Riesgos

- **Fuga entre coordinadores por caché**: mitigado con `section_ids` en la clave; cubierto por test.
- **`Prisma.join` con lista vacía lanza**: el scope service garantiza `section_ids` no vacío (403 antes de llegar al repositorio); el test de scope lo cubre.
- **Coordinador `GENERAL` con muchas secciones**: la lista de ids puede ser larga (todo un campo). PostgreSQL maneja `= ANY` con cientos de ids sin problema; si un campo supera ~1 000 secciones, se revisa en el subproyecto 3.
- **Colas accionables**: el conteo de `annual_folders_pending_union` puede ser > 0 para un coordinador aunque no pueda evaluarlas; el admin ya no enlaza a pantallas sin acceso. Se decide en el subproyecto 3 si se oculta la fila.
