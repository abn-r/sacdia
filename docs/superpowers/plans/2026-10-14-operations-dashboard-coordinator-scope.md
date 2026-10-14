# Alcance de coordinador en el dashboard de operaciones — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Que los coordinadores (`coordinator`, `zone-coordinator`, `general-coordinator`) reciban `GET /api/v1/analytics/operations-dashboard` limitado a sus secciones asignadas, con desglose por club, y que el admin lo renderice.

**Architecture:** Un nivel nuevo `coordinator` en el alcance del dashboard, resuelto con `CoordinationService.resolveCoordinatorScope` (lista canónica de `club_section_ids`, PR #396). El repositorio filtra con `cs.club_section_id IN (...)`; la clave de caché incluye las secciones; el DTO no expone `section_ids`. El admin solo agrega el nivel al tipo y un test.

**Tech Stack:** NestJS 11, Prisma 7 (`$queryRaw` + `Prisma.sql`/`Prisma.join`), Jest; Next.js 16 + Vitest en el admin.

**Spec:** `docs/superpowers/specs/2026-10-14-operations-dashboard-coordinator-scope-design.md`

---

## Reglas para quien ejecuta

- PR 1 vive en `sacdia-backend/`, PR 2 en `sacdia-admin/`. Cada uno es un repo git propio; los comandos se corren desde el repo indicado.
- Commits convencionales en inglés, **sin** líneas de atribución de IA. No hacer push ni abrir PRs salvo que el dueño lo pida.
- Herramientas de shell: `rg`, `fd`, `sd`, `bat`, `eza`. Nunca `grep`/`find`/`sed`/`cat`/`ls`. Para ediciones multilínea usar la herramienta Edit.
- **No** correr `pnpm build` en ningún repo.
- Backend: Jest se corre con `pnpm run test -- <patrón>`. `prisma generate` ya corrió si `node_modules/.prisma` existe; si un test falla con "Cannot find module '.prisma/client'", correr `pnpm prisma generate` una vez.
- Admin: la rama de trabajo actual puede ser `feat/antislop-sentence-case-labels` (subproyecto 1). PR 2 **sale de `development`**, no de esa rama.

## Mapa de archivos

### `sacdia-backend`

| Archivo | Cambio |
|---|---|
| `src/analytics/operations-dashboard.types.ts` | `'coordinator'` en `OperationsDashboardScopeLevel`; `section_ids?` en `ResolvedOperationsDashboardScope`; `getOperationsDashboardChildLevel('coordinator') → 'club'` |
| `src/analytics/analytics.controller.ts` | 3 roles de coordinador en `@GlobalRoles`; descripción Swagger |
| `src/analytics/operations-dashboard.controller.spec.ts` | Afirmación de roles actualizada |
| `src/analytics/operations-dashboard-scope.service.ts` | Inyecta `CoordinationService`; rama `coordinator` |
| `src/analytics/operations-dashboard-scope.service.spec.ts` | Mock de `CoordinationService`; 6 tests nuevos |
| `src/analytics/operations-dashboard.repository.ts` | `bucketExpression`, `scopePredicate`, `clubScopePredicate`, `loadChildren` para `coordinator` |
| `src/analytics/operations-dashboard.repository.spec.ts` | 1 test nuevo |
| `src/analytics/operations-dashboard.service.ts` | `cacheKey` con `section_ids` |
| `src/analytics/operations-dashboard.service.spec.ts` | 1 test nuevo |
| `src/analytics/dto/operations-dashboard.dto.ts` | `'coordinator'` en el enum de `OperationsDashboardScopeDto.level` |

### `sacdia-admin`

| Archivo | Cambio |
|---|---|
| `src/lib/api/operations-dashboard.ts` | `"coordinator"` en `ScopeLevel`; `scopePathLabels` exportada (movida desde el chrome) |
| `src/components/dashboard/operations-dashboard-chrome.tsx` | Importa `scopePathLabels` en vez de definirla |
| `src/lib/api/operations-dashboard.test.ts` (existente) | Agrega el `describe("scopePathLabels")` |

---

# PR 1 — `sacdia-backend`

### Task 0: Rama

- [ ] **Step 1: Crear la rama desde `development` actualizado**

Desde `sacdia-backend/`:

```bash
git checkout development
git pull --ff-only
git checkout -b feat/operations-dashboard-coordinator-scope
```

Expected: `Switched to a new branch 'feat/operations-dashboard-coordinator-scope'`.

- [ ] **Step 2: Baseline de tests del módulo**

Run: `pnpm run test -- operations-dashboard`
Expected: todos verdes (anotar el total de tests para comparar al final).

---

### Task 1: Tipos

**Files:**
- Modify: `src/analytics/operations-dashboard.types.ts` (líneas 1-5, 18-23, 112-125)

No hay spec propio de tipos; los tests de las tareas 3-5 los cubren. Este cambio es necesario para que compilen.

- [ ] **Step 1: Ampliar `OperationsDashboardScopeLevel`**

Reemplazar:

```ts
export type OperationsDashboardScopeLevel =
  | 'all'
  | 'division'
  | 'union'
  | 'local_field';
```

por:

```ts
export type OperationsDashboardScopeLevel =
  | 'all'
  | 'division'
  | 'union'
  | 'local_field'
  | 'coordinator';
```

- [ ] **Step 2: Agregar `section_ids` al alcance resuelto**

Reemplazar:

```ts
export type ResolvedOperationsDashboardScope = {
  level: OperationsDashboardScopeLevel;
  id: number | null;
  name: string;
  path: OperationsDashboardScopePathNode[];
};
```

por:

```ts
export type ResolvedOperationsDashboardScope = {
  level: OperationsDashboardScopeLevel;
  id: number | null;
  name: string;
  path: OperationsDashboardScopePathNode[];
  /**
   * Only for level 'coordinator': the actor's assigned club sections.
   * Sorted ascending, deduplicated, never empty.
   */
  section_ids?: number[];
};
```

`OperationsDashboardScopePathNode.level` sigue siendo `Exclude<OperationsDashboardScopeLevel, 'all'>`; eso ahora incluye `'coordinator'` en el tipo, pero ningún nodo de path se construye con ese nivel (el coordinador tiene `path: []`). No hace falta excluirlo.

- [ ] **Step 3: Nivel hijo**

En `getOperationsDashboardChildLevel`, agregar un caso al `switch`:

```ts
    case 'local_field':
      return 'club';
    case 'coordinator':
      return 'club';
```

- [ ] **Step 4: Verificar que compila**

Run: `pnpm exec tsc --noEmit -p tsconfig.json 2>&1 | rg 'operations-dashboard' ; echo "done"`
Expected: errores solo en `operations-dashboard.repository.ts` (los `switch` de `bucketExpression`, `scopePredicate` y `loadChildren` ya no son exhaustivos: "Function lacks ending return statement" o "Not all code paths return a value"). Se resuelven en la tarea 4. Si `tsc` no reporta nada, también está bien (depende de `noImplicitReturns`).

- [ ] **Step 5: Commit**

```bash
git add src/analytics/operations-dashboard.types.ts
git commit -m "feat(analytics): add coordinator level to operations dashboard scope types"
```

---

### Task 2: Guard del endpoint (test primero)

**Files:**
- Modify: `src/analytics/operations-dashboard.controller.spec.ts:24-49`
- Modify: `src/analytics/analytics.controller.ts:127-143`

- [ ] **Step 1: Actualizar la afirmación del spec**

En `operations-dashboard.controller.spec.ts`, reemplazar:

```ts
    expect(Reflect.getMetadata(GLOBAL_ROLES_KEY, handler)).toEqual([
      'admin',
      'super-admin',
      'director-dia',
      'assistant-dia',
      'director-union',
      'assistant-union',
      'director-lf',
      'assistant-lf',
    ]);
```

por:

```ts
    expect(Reflect.getMetadata(GLOBAL_ROLES_KEY, handler)).toEqual([
      'admin',
      'super-admin',
      'director-dia',
      'assistant-dia',
      'director-union',
      'assistant-union',
      'director-lf',
      'assistant-lf',
      'coordinator',
      'zone-coordinator',
      'general-coordinator',
    ]);
```

y, justo después de `expect(operation.description).toContain('Solo super-admin ve el sistema');`, agregar:

```ts
    expect(operation.description).toContain('Coordinadores');
```

- [ ] **Step 2: Verificar que falla**

Run: `pnpm run test -- operations-dashboard.controller`
Expected: FAIL en `exposes GET operations-dashboard for only the supported global roles` (arreglo recibido sin los 3 roles).

- [ ] **Step 3: Actualizar el controlador**

En `analytics.controller.ts`, reemplazar:

```ts
  @GlobalRoles(
    'admin',
    'super-admin',
    'director-dia',
    'assistant-dia',
    'director-union',
    'assistant-union',
    'director-lf',
    'assistant-lf',
  )
  @ApiOperation({
    summary: 'Dashboard operativo jerárquico',
    description:
      'Indicadores operativos agregados con alcance forzado en servidor. ' +
      'Solo super-admin ve el sistema; administradores y liderazgos DIA, Unión y Campo solo su territorio y descendientes.',
  })
```

por:

```ts
  @GlobalRoles(
    'admin',
    'super-admin',
    'director-dia',
    'assistant-dia',
    'director-union',
    'assistant-union',
    'director-lf',
    'assistant-lf',
    'coordinator',
    'zone-coordinator',
    'general-coordinator',
  )
  @ApiOperation({
    summary: 'Dashboard operativo jerárquico',
    description:
      'Indicadores operativos agregados con alcance forzado en servidor. ' +
      'Solo super-admin ve el sistema; administradores y liderazgos DIA, Unión y Campo solo su territorio y descendientes. ' +
      'Coordinadores: solo sus secciones asignadas, con desglose por club.',
  })
```

- [ ] **Step 4: Verificar que pasa**

Run: `pnpm run test -- operations-dashboard.controller`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add src/analytics/analytics.controller.ts src/analytics/operations-dashboard.controller.spec.ts
git commit -m "feat(analytics): allow coordinator roles on the operations dashboard endpoint"
```

---

### Task 3: Resolución de alcance (test primero)

**Files:**
- Modify: `src/analytics/operations-dashboard-scope.service.spec.ts`
- Modify: `src/analytics/operations-dashboard-scope.service.ts`

- [ ] **Step 1: Mock de `CoordinationService` y `coordination_zones` en el spec**

En `operations-dashboard-scope.service.spec.ts`, reemplazar el bloque:

```ts
describe('OperationsDashboardScopeService', () => {
  const authorizationContext = {
    resolveUserAuthorization: jest.fn(),
  };
  const prisma = {
    divisions: { findUnique: jest.fn() },
    unions: { findUnique: jest.fn() },
    local_fields: { findUnique: jest.fn() },
  };

  let service: OperationsDashboardScopeService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new OperationsDashboardScopeService(
      prisma as any,
      authorizationContext as any,
    );
```

por:

```ts
const coordinatorScope = ({
  sectionIds,
  assignments,
}: {
  sectionIds: number[];
  assignments: Array<{
    assignment_type: 'GENERAL' | 'ZONE' | 'SECTION';
    zone_id?: number | null;
  }>;
}) => ({
  is_coordinator: sectionIds.length > 0,
  club_section_ids: sectionIds,
  assignments: assignments.map((assignment, index) => ({
    assignment_id: `assignment-${index}`,
    assignment_type: assignment.assignment_type,
    local_field_id: 100,
    zone_id: assignment.zone_id ?? null,
    club_type_id: null,
    club_section_id: null,
  })),
  sections: [],
});

describe('OperationsDashboardScopeService', () => {
  const authorizationContext = {
    resolveUserAuthorization: jest.fn(),
  };
  const coordinationService = {
    resolveCoordinatorScope: jest.fn(),
  };
  const prisma = {
    divisions: { findUnique: jest.fn() },
    unions: { findUnique: jest.fn() },
    local_fields: { findUnique: jest.fn() },
    coordination_zones: { findUnique: jest.fn() },
  };

  let service: OperationsDashboardScopeService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new OperationsDashboardScopeService(
      prisma as any,
      authorizationContext as any,
      coordinationService as any,
    );
    prisma.coordination_zones.findUnique.mockImplementation(({ where }) =>
      Promise.resolve(
        where.zone_id === 5
          ? { zone_id: 5, name: 'Zona Norte', active: true }
          : null,
      ),
    );
```

- [ ] **Step 2: Reemplazar el test de rechazo y agregar los nuevos**

Reemplazar el test completo `it('rejects coordinators and club-only actors', ...)` (líneas 268-282) por este bloque:

```ts
  it('rejects club-only actors', async () => {
    authorizationContext.resolveUserAuthorization.mockResolvedValueOnce(
      resolvedAuth({ roles: [] }),
    );
    await expect(service.resolve('club-actor', {})).rejects.toMatchObject({
      code: ErrorCode.GUARD_PERMISSION_DENIED,
    });
    expect(coordinationService.resolveCoordinatorScope).not.toHaveBeenCalled();
  });

  it('resolves a coordinator to its assigned sections, sorted and deduplicated', async () => {
    authorizationContext.resolveUserAuthorization.mockResolvedValueOnce(
      resolvedAuth({ roles: ['zone-coordinator'], localFieldId: 100 }),
    );
    coordinationService.resolveCoordinatorScope.mockResolvedValueOnce(
      coordinatorScope({
        sectionIds: [40, 12, 15, 12],
        assignments: [{ assignment_type: 'GENERAL' }],
      }),
    );

    await expect(service.resolve('coordinator', {})).resolves.toEqual({
      level: 'coordinator',
      id: null,
      name: 'Secciones asignadas',
      path: [],
      section_ids: [12, 15, 40],
    });
    expect(coordinationService.resolveCoordinatorScope).toHaveBeenCalledWith(
      'coordinator',
    );
  });

  it('names the scope after the zone when every assignment is the same zone', async () => {
    authorizationContext.resolveUserAuthorization.mockResolvedValueOnce(
      resolvedAuth({ roles: ['zone-coordinator'], localFieldId: 100 }),
    );
    coordinationService.resolveCoordinatorScope.mockResolvedValueOnce(
      coordinatorScope({
        sectionIds: [12, 15],
        assignments: [
          { assignment_type: 'ZONE', zone_id: 5 },
          { assignment_type: 'ZONE', zone_id: 5 },
        ],
      }),
    );

    await expect(service.resolve('coordinator', {})).resolves.toMatchObject({
      level: 'coordinator',
      name: 'Zona Norte',
    });
    expect(prisma.coordination_zones.findUnique).toHaveBeenCalledWith({
      where: { zone_id: 5 },
      select: { zone_id: true, name: true, active: true },
    });
  });

  it('falls back to the generic name for mixed assignments or an unknown zone', async () => {
    authorizationContext.resolveUserAuthorization.mockResolvedValue(
      resolvedAuth({ roles: ['coordinator'], localFieldId: 100 }),
    );
    coordinationService.resolveCoordinatorScope.mockResolvedValueOnce(
      coordinatorScope({
        sectionIds: [12],
        assignments: [
          { assignment_type: 'ZONE', zone_id: 5 },
          { assignment_type: 'SECTION' },
        ],
      }),
    );
    await expect(service.resolve('coordinator', {})).resolves.toMatchObject({
      name: 'Secciones asignadas',
    });

    coordinationService.resolveCoordinatorScope.mockResolvedValueOnce(
      coordinatorScope({
        sectionIds: [12],
        assignments: [{ assignment_type: 'ZONE', zone_id: 999 }],
      }),
    );
    await expect(service.resolve('coordinator', {})).resolves.toMatchObject({
      name: 'Secciones asignadas',
    });
  });

  it('rejects a coordinator without active sections with a scope-missing error', async () => {
    authorizationContext.resolveUserAuthorization.mockResolvedValueOnce(
      resolvedAuth({ roles: ['general-coordinator'], localFieldId: 100 }),
    );
    coordinationService.resolveCoordinatorScope.mockResolvedValueOnce(
      coordinatorScope({ sectionIds: [], assignments: [] }),
    );

    await expect(service.resolve('coordinator', {})).rejects.toMatchObject({
      code: ErrorCode.ADMIN_USER_SCOPE_MISSING,
    });
  });

  it('rejects any territorial filter for a coordinator before resolving sections', async () => {
    authorizationContext.resolveUserAuthorization.mockResolvedValue(
      resolvedAuth({ roles: ['coordinator'], localFieldId: 100 }),
    );

    for (const filters of [
      { localFieldId: 100 },
      { unionId: 10 },
      { divisionId: 1 },
    ]) {
      await expect(service.resolve('coordinator', filters)).rejects.toMatchObject(
        { code: ErrorCode.GUARD_PERMISSION_DENIED },
      );
    }
    expect(coordinationService.resolveCoordinatorScope).not.toHaveBeenCalled();
  });

  it('prefers a broader territorial role over a coordinator role', async () => {
    authorizationContext.resolveUserAuthorization.mockResolvedValueOnce(
      resolvedAuth({ roles: ['coordinator', 'director-lf'], localFieldId: 100 }),
    );

    await expect(service.resolve('director', {})).resolves.toMatchObject({
      level: 'local_field',
      id: 100,
    });
    expect(coordinationService.resolveCoordinatorScope).not.toHaveBeenCalled();
  });
```

- [ ] **Step 3: Verificar que falla**

Run: `pnpm run test -- operations-dashboard-scope`
Expected: FAIL. Los 6 tests nuevos fallan (el constructor ignora el tercer argumento y `coordinator` sigue en 403); los demás pasan.

- [ ] **Step 4: Implementar en el servicio**

En `operations-dashboard-scope.service.ts`:

4a. Imports: después de `import { PrismaService } from '../prisma/prisma.service';` agregar:

```ts
import { CoordinationService } from '../coordination/coordination.service';
```

4b. Constantes: después de `const ADMIN_SCOPE_ROLES = new Set(['admin', 'assistant-admin']);` agregar:

```ts
const COORDINATOR_ROLES = new Set([
  'coordinator',
  'zone-coordinator',
  'general-coordinator',
]);
const COORDINATOR_SCOPE_NAME = 'Secciones asignadas';
```

4c. Constructor: reemplazar

```ts
  constructor(
    private readonly prisma: PrismaService,
    private readonly authorizationContext: AuthorizationContextService,
  ) {}
```

por

```ts
  constructor(
    private readonly prisma: PrismaService,
    private readonly authorizationContext: AuthorizationContextService,
    private readonly coordinationService: CoordinationService,
  ) {}
```

4d. En `resolve`, justo después de `const base = this.resolveActorBaseScope(authorization);` y antes de `this.assertSameLevelFiltersWithinBase(...)`, agregar:

```ts
    if (base.level === 'coordinator') {
      return this.resolveCoordinatorScope(actorId, filters);
    }
```

4e. En `resolveActorBaseScope`, reemplazar el final:

```ts
      throw new AppForbiddenException(ErrorCode.ADMIN_USER_SCOPE_MISSING);
    }

    throw new AppForbiddenException(ErrorCode.GUARD_PERMISSION_DENIED);
  }
```

por:

```ts
      throw new AppForbiddenException(ErrorCode.ADMIN_USER_SCOPE_MISSING);
    }

    if (hasAnyRole(roles, COORDINATOR_ROLES)) {
      return { level: 'coordinator', id: null };
    }

    throw new AppForbiddenException(ErrorCode.GUARD_PERMISSION_DENIED);
  }

  /**
   * Coordinators see only their assigned club sections (PR #396 canon) and
   * cannot navigate the territory, so any territorial filter is denied.
   */
  private async resolveCoordinatorScope(
    actorId: string,
    filters: OperationsDashboardScopeFilters,
  ): Promise<ResolvedOperationsDashboardScope> {
    if (
      filters.divisionId !== undefined ||
      filters.unionId !== undefined ||
      filters.localFieldId !== undefined
    ) {
      this.denyOutsideScope();
    }

    const scope = await this.coordinationService.resolveCoordinatorScope(actorId);
    const sectionIds = [...new Set(scope.club_section_ids)].sort(
      (a, b) => a - b,
    );
    if (sectionIds.length === 0) {
      throw new AppForbiddenException(ErrorCode.ADMIN_USER_SCOPE_MISSING);
    }

    return {
      level: 'coordinator',
      id: null,
      name: await this.resolveCoordinatorScopeName(scope.assignments),
      path: [],
      section_ids: sectionIds,
    };
  }

  private async resolveCoordinatorScopeName(
    assignments: Array<{ assignment_type: string; zone_id: number | null }>,
  ): Promise<string> {
    const zoneIds = new Set(
      assignments.map((assignment) =>
        assignment.assignment_type === 'ZONE' ? assignment.zone_id : null,
      ),
    );
    if (zoneIds.size !== 1) return COORDINATOR_SCOPE_NAME;

    const [zoneId] = zoneIds;
    if (typeof zoneId !== 'number') return COORDINATOR_SCOPE_NAME;

    const zone = await this.prisma.coordination_zones.findUnique({
      where: { zone_id: zoneId },
      select: { zone_id: true, name: true, active: true },
    });
    return zone?.active ? zone.name : COORDINATOR_SCOPE_NAME;
  }
```

Nota: `denyOutsideScope(): never` ya existe en el servicio (línea ~331) y lanza `GUARD_PERMISSION_DENIED`.

4f. `resolveTargetLevel`, `resolveTargetId` y `loadTarget` reciben `OperationsDashboardScopeLevel`/`Exclude<..., 'all'>`. Con `'coordinator'` en el tipo, `loadTarget` puede quejarse de que no retorna en todos los caminos. Al final de `loadTarget`, antes del cierre, si no existe ya un `throw` final, agregar:

```ts
    throw new AppForbiddenException(ErrorCode.GUARD_PERMISSION_DENIED);
```

(solo si `tsc` lo pide; `resolve` nunca llega ahí con `coordinator` porque retorna antes).

- [ ] **Step 5: Verificar que pasa**

Run: `pnpm run test -- operations-dashboard-scope`
Expected: PASS, todos (los previos + 7 del bloque nuevo, que reemplaza 1).

- [ ] **Step 6: Commit**

```bash
git add src/analytics/operations-dashboard-scope.service.ts src/analytics/operations-dashboard-scope.service.spec.ts
git commit -m "feat(analytics): resolve coordinator scope from assigned club sections"
```

---

### Task 4: Repositorio (test primero)

**Files:**
- Modify: `src/analytics/operations-dashboard.repository.spec.ts`
- Modify: `src/analytics/operations-dashboard.repository.ts`

- [ ] **Step 1: Agregar el test**

En `operations-dashboard.repository.spec.ts`, después del test `loads all aggregate families with parameterized Prisma SQL` (termina en la línea ~124), agregar:

```ts
  it('filters a coordinator scope by assigned sections and lists their clubs', async () => {
    const coordinatorScope: ResolvedOperationsDashboardScope = {
      level: 'coordinator',
      id: null,
      name: 'Zona Norte',
      path: [],
      section_ids: [12, 15, 40],
    };

    await repository.loadSnapshot({
      scope: coordinatorScope,
      ecclesiasticalYear: year,
      reportingMonth: { year: 2026, month: 6 },
      includeHonors: true,
    });

    expect(prisma.$queryRaw).toHaveBeenCalledTimes(9);

    const queries = prisma.$queryRaw.mock.calls.map(([query]) => ({
      sql: (query.strings as string[]).join('?'),
      values: query.values as unknown[],
    }));

    const childrenQuery = queries.find((q) => q.sql.includes('SELECT DISTINCT c.club_id AS id'));
    expect(childrenQuery?.sql).toContain('INNER JOIN club_sections cs ON cs.main_club_id = c.club_id');
    expect(childrenQuery?.sql).toContain('cs.club_section_id IN (?,?,?)');
    expect(childrenQuery?.values).toEqual([12, 15, 40]);

    const administrativeQuery = queries.find((q) => q.sql.includes('AS inactive'));
    expect(administrativeQuery?.sql).toContain('c.club_id IN (');
    expect(administrativeQuery?.sql).toContain('SELECT cs2.main_club_id FROM club_sections cs2');
    expect(administrativeQuery?.sql).toContain('cs2.club_section_id IN (?,?,?)');
    expect(administrativeQuery?.values).toEqual(expect.arrayContaining([12, 15, 40]));

    const sectionScopedQueries = queries.filter(
      (q) => q !== childrenQuery && q !== administrativeQuery,
    );
    expect(sectionScopedQueries).toHaveLength(7);
    for (const query of sectionScopedQueries) {
      expect(query.sql).toContain('cs.club_section_id IN (?,?,?)');
      expect(query.sql).toContain('c.club_id AS bucket_id');
      expect(query.values).toEqual(expect.arrayContaining([12, 15, 40]));
    }

    expect(JSON.stringify(prisma.$queryRaw.mock.calls)).not.toContain('ANY(');
  });
```

- [ ] **Step 2: Verificar que falla**

Run: `pnpm run test -- operations-dashboard.repository`
Expected: FAIL (hoy los `switch` no manejan `coordinator`: `bucket`/`scopePredicate` quedan `undefined` y el test de children no encuentra la query).

- [ ] **Step 3: Implementar**

En `operations-dashboard.repository.ts`:

3a. En `loadSnapshot`, reemplazar:

```ts
    const bucket = this.bucketExpression(scope);
    const scopePredicate = this.scopePredicate(scope);
```

por:

```ts
    const bucket = this.bucketExpression(scope);
    const scopePredicate = this.scopePredicate(scope);
    const clubScopePredicate = this.clubScopePredicate(scope);
```

y reemplazar `this.loadAdministrativeClubs(bucket, scopePredicate),` por `this.loadAdministrativeClubs(bucket, clubScopePredicate),`.

3b. En `loadChildren`, agregar un caso al final del `switch`, después del caso `'local_field'`:

```ts
      case 'coordinator':
        return this.prisma.$queryRaw<DashboardChildNode[]>(Prisma.sql`
          SELECT DISTINCT c.club_id AS id, c.name
          FROM clubs c
          INNER JOIN club_sections cs ON cs.main_club_id = c.club_id
          WHERE cs.club_section_id IN (${Prisma.join(this.sectionIds(scope))})
          ORDER BY c.name ASC, c.club_id ASC
        `);
```

3c. En `bucketExpression`, agregar al `switch`:

```ts
      case 'local_field':
        return Prisma.sql`c.club_id`;
      case 'coordinator':
        return Prisma.sql`c.club_id`;
```

3d. Reemplazar `scopePredicate` completo por:

```ts
  private scopePredicate(scope: ResolvedOperationsDashboardScope): Prisma.Sql {
    switch (scope.level) {
      case 'all':
        return Prisma.sql`TRUE`;
      case 'division':
        return Prisma.sql`d.division_id = ${scope.id}`;
      case 'union':
        return Prisma.sql`u.union_id = ${scope.id}`;
      case 'local_field':
        return Prisma.sql`lf.local_field_id = ${scope.id}`;
      case 'coordinator':
        return Prisma.sql`cs.club_section_id IN (${Prisma.join(this.sectionIds(scope))})`;
    }
  }

  /**
   * Same as scopePredicate for territorial levels. For a coordinator, queries
   * that start from `clubs c` (no club_sections join) filter by the clubs that
   * own the assigned sections.
   */
  private clubScopePredicate(
    scope: ResolvedOperationsDashboardScope,
  ): Prisma.Sql {
    if (scope.level !== 'coordinator') return this.scopePredicate(scope);
    return Prisma.sql`c.club_id IN (
      SELECT cs2.main_club_id FROM club_sections cs2
      WHERE cs2.club_section_id IN (${Prisma.join(this.sectionIds(scope))})
    )`;
  }

  private sectionIds(scope: ResolvedOperationsDashboardScope): number[] {
    const ids = scope.section_ids ?? [];
    if (ids.length === 0) {
      // The scope service rejects empty coordinator scopes before reaching here.
      throw new Error('Coordinator scope requires at least one section id');
    }
    return ids;
  }
```

- [ ] **Step 4: Verificar que pasa**

Run: `pnpm run test -- operations-dashboard.repository`
Expected: PASS (los previos + 1).

- [ ] **Step 5: Commit**

```bash
git add src/analytics/operations-dashboard.repository.ts src/analytics/operations-dashboard.repository.spec.ts
git commit -m "feat(analytics): scope operations dashboard queries by coordinator sections"
```

---

### Task 5: Clave de caché (test primero)

**Files:**
- Modify: `src/analytics/operations-dashboard.service.spec.ts`
- Modify: `src/analytics/operations-dashboard.service.ts:126-139`

- [ ] **Step 1: Agregar el test**

En `operations-dashboard.service.spec.ts`, después de `const globalScope: ResolvedOperationsDashboardScope = {...};` agregar:

```ts
const coordinatorScope = (
  sectionIds: number[],
): ResolvedOperationsDashboardScope => ({
  level: 'coordinator',
  id: null,
  name: 'Secciones asignadas',
  path: [],
  section_ids: sectionIds,
});
```

y, como último `it` dentro del `describe('OperationsDashboardService', ...)`, agregar:

```ts
  it('never shares a cached snapshot between coordinators with different sections', async () => {
    scopeService.resolve
      .mockResolvedValueOnce(coordinatorScope([12, 15]))
      .mockResolvedValueOnce(coordinatorScope([12, 40]))
      .mockResolvedValueOnce(coordinatorScope([12, 15]));

    const first = await service.getDashboard('coordinator-a', {});
    const second = await service.getDashboard('coordinator-b', {});
    const third = await service.getDashboard('coordinator-c', {});

    expect(repository.loadSnapshot).toHaveBeenCalledTimes(2);
    expect(first.meta.cached).toBe(false);
    expect(second.meta.cached).toBe(false);
    expect(third.meta.cached).toBe(true);
    expect(third.meta.scope).toEqual(
      expect.not.objectContaining({ section_ids: expect.anything() }),
    );
  });
```

El último `expect` fija que `section_ids` no se expone en el DTO (el mapper copia `scope` tal cual hoy; ver Step 3).

- [ ] **Step 2: Verificar que falla**

Run: `pnpm run test -- operations-dashboard.service`
Expected: FAIL en el test nuevo: `loadSnapshot` se llamó 1 vez (clave `coordinator:all:...` compartida).

- [ ] **Step 3: Implementar**

3a. En `operations-dashboard.service.ts`, reemplazar `cacheKey` completo por:

```ts
  private cacheKey(
    scope: ResolvedOperationsDashboardScope,
    year: EcclesiasticalYearRecord,
    reportingMonth: ReportingMonth | null,
  ): string {
    const scopeKey =
      scope.level === 'coordinator'
        ? (scope.section_ids ?? []).join(',')
        : String(scope.id ?? 'all');
    return [
      'operations-dashboard',
      scope.level,
      scopeKey,
      year.year_id,
      reportingMonth?.year ?? 'none',
      reportingMonth?.month ?? 'none',
    ].join(':');
  }
```

3b. El mapper copia el objeto completo en `meta` (`src/analytics/operations-dashboard.mapper.ts:86`, la línea `      scope,`), lo que filtraría `section_ids` al cliente. Reemplazar esa línea por:

```ts
      scope: {
        level: scope.level,
        id: scope.id,
        name: scope.name,
        path: scope.path,
      },
```

El spec del mapper (`operations-dashboard.mapper.spec.ts:32`) pasa un `scope` sin `section_ids` y compara con `toEqual`/`toMatchObject`; sigue pasando con el objeto reconstruido.

- [ ] **Step 4: Verificar que pasa**

Run: `pnpm run test -- operations-dashboard.service operations-dashboard.mapper`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/analytics/operations-dashboard.service.ts src/analytics/operations-dashboard.service.spec.ts src/analytics/operations-dashboard.mapper.ts
git commit -m "feat(analytics): key the operations dashboard cache by coordinator sections"
```

---

### Task 6: DTO y verificación final del backend

**Files:**
- Modify: `src/analytics/dto/operations-dashboard.dto.ts:76-78`

- [ ] **Step 1: Enum del DTO**

Reemplazar:

```ts
export class OperationsDashboardScopeDto {
  @ApiProperty({ enum: ['all', 'division', 'union', 'local_field'] })
  level!: 'all' | 'division' | 'union' | 'local_field';
```

por:

```ts
export class OperationsDashboardScopeDto {
  @ApiProperty({
    enum: ['all', 'division', 'union', 'local_field', 'coordinator'],
  })
  level!: 'all' | 'division' | 'union' | 'local_field' | 'coordinator';
```

`OperationsDashboardScopePathNodeDto.level` no cambia (ningún nodo de path es `coordinator`).

- [ ] **Step 2: Suite del módulo + lint**

Run: `pnpm run test -- operations-dashboard analytics.controller`
Expected: PASS; total = baseline de la Task 0 + 8 tests (scope: 7 nuevos menos 1 reemplazado = +6; repository +1; service +1). Reportar el número real.

Run: `pnpm run lint`
Expected: sin errores nuevos en `src/analytics/`. Si el lint ya reportaba errores en otros módulos antes de esta rama, dejarlos.

Run: `pnpm exec tsc --noEmit -p tsconfig.json; echo "exit:$?"`
Expected: `exit:0`.

- [ ] **Step 3: Commit**

```bash
git add src/analytics/dto/operations-dashboard.dto.ts
git commit -m "docs(analytics): expose the coordinator scope level in the dashboard DTO"
```

- [ ] **Step 4: Verificación manual (dueño), con el backend corriendo contra `development` de Neon**

Con un token de un usuario coordinador de zona:

```bash
curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:3000/api/v1/analytics/operations-dashboard" | jq '.data.meta.scope, (.data.children | map({id, name, level}))'
```

Expected: `level: "coordinator"`, `path: []`, `name` = nombre de zona; `children` solo clubes de la zona, `level: "club"`.

```bash
curl -s -o /dev/null -w "%{http_code}\n" -H "Authorization: Bearer $TOKEN" "http://localhost:3000/api/v1/analytics/operations-dashboard?local_field_id=100"
```

Expected: `403`.

- [ ] **Step 5: Push y PR** (solo cuando el dueño lo pida)

```bash
git push -u origin feat/operations-dashboard-coordinator-scope
gh pr create --base development --title "feat(analytics): coordinator scope for the operations dashboard" --body "Coordinators (coordinator, zone-coordinator, general-coordinator) now get the operations dashboard limited to their assigned club sections (CoordinationService.resolveCoordinatorScope, PR #396 canon), with a per-club breakdown. Territorial filters are denied (403), empty assignments return ADMIN_USER_SCOPE_MISSING, and the cache key includes the section ids so two coordinators never share a snapshot. Spec: docs/superpowers/specs/2026-10-14-operations-dashboard-coordinator-scope-design.md in the sacdia workspace."
```

---

# PR 2 — `sacdia-admin`

### Task 7: Rama

- [ ] **Step 1: Crear la rama desde `development`**

Desde `sacdia-admin/`:

```bash
git checkout development
git pull --ff-only
git checkout -b feat/operations-dashboard-coordinator-level
```

Expected: `Switched to a new branch 'feat/operations-dashboard-coordinator-level'`. Si `git checkout development` falla por cambios sin commit, detenerse y reportar (no hacer `stash`).

---

### Task 8: Nivel `coordinator` y `scopePathLabels` (test primero)

**Files:**
- Modify: `src/lib/api/operations-dashboard.test.ts` (YA EXISTE con 19 tests: agregar al final, no sobrescribir)
- Modify: `src/lib/api/operations-dashboard.ts:6` y final del archivo
- Modify: `src/components/dashboard/operations-dashboard-chrome.tsx:23-29`

- [ ] **Step 1: Escribir el test**

Agregar al FINAL de `src/lib/api/operations-dashboard.test.ts` (sumar `scopePathLabels` y `type OperationsDashboardScope` al import existente de `@/lib/api/operations-dashboard`; no reemplazar el archivo):

```ts
import { describe, expect, it } from "vitest";
import {
  scopePathLabels,
  type OperationsDashboardScope,
} from "@/lib/api/operations-dashboard";

describe("scopePathLabels", () => {
  it("returns no labels for the global scope", () => {
    const scope: OperationsDashboardScope = {
      level: "all",
      id: null,
      name: "Todos",
      path: [],
    };
    expect(scopePathLabels(scope)).toEqual([]);
  });

  it("lists the path and ends with the current territory", () => {
    const scope: OperationsDashboardScope = {
      level: "local_field",
      id: 100,
      name: "Campo 100",
      path: [
        { level: "division", id: 1, name: "División 1" },
        { level: "union", id: 10, name: "Unión 10" },
        { level: "local_field", id: 100, name: "Campo 100" },
      ],
    };
    expect(scopePathLabels(scope)).toEqual(["División 1", "Unión 10", "Campo 100", "Campo 100"]);
  });

  it("shows only the scope name for a coordinator, who has no territorial path", () => {
    const scope: OperationsDashboardScope = {
      level: "coordinator",
      id: null,
      name: "Zona Norte",
      path: [],
    };
    expect(scopePathLabels(scope)).toEqual(["Zona Norte"]);
  });
});
```

Nota sobre el segundo test: hoy `scopePathLabels` agrega `scope.name` aunque ya sea el último nodo del path; el chrome lo compensa con `showBreadcrumb = breadcrumbText !== meta.scope.name`. El test documenta el comportamiento actual sin cambiarlo (fuera de alcance).

- [ ] **Step 2: Verificar que falla**

Run: `pnpm exec vitest run src/lib/api/operations-dashboard.test.ts`
Expected: FAIL — `scopePathLabels` no se exporta (error de import) y/o error de tipo en `level: "coordinator"`.

- [ ] **Step 3: Tipo y función exportada**

En `src/lib/api/operations-dashboard.ts`:

3a. Reemplazar la línea 6:

```ts
export type ScopeLevel = "all" | "division" | "union" | "local_field";
```

por:

```ts
export type ScopeLevel = "all" | "division" | "union" | "local_field" | "coordinator";
```

3b. Reemplazar `OperationsDashboardScopePathNode`:

```ts
export type OperationsDashboardScopePathNode = {
  level: Exclude<ScopeLevel, "all">;
  id: number;
  name: string;
};
```

por:

```ts
export type OperationsDashboardScopePathNode = {
  level: Exclude<ScopeLevel, "all" | "coordinator">;
  id: number;
  name: string;
};
```

3c. Al final del archivo, en la sección de helpers, agregar:

```ts
/**
 * Breadcrumb labels for the current scope: the territorial path followed by
 * the scope name. A coordinator has no territorial path, so only the name shows.
 */
export function scopePathLabels(scope: OperationsDashboardScope): string[] {
  const labels = scope.path.map((node) => node.name);
  if (scope.level !== "all") {
    labels.push(scope.name);
  }
  return labels;
}
```

- [ ] **Step 4: Usar la función en el chrome**

En `operations-dashboard-chrome.tsx`:

4a. Borrar la función local:

```ts
function scopePathLabels(data: OperationsDashboardData): string[] {
  const labels = data.meta.scope.path.map((node) => node.name);
  if (data.meta.scope.level !== "all") {
    labels.push(data.meta.scope.name);
  }
  return labels;
}
```

4b. Agregar `scopePathLabels` al import existente de `@/lib/api/operations-dashboard` (el archivo ya importa `buildDashboardHref`, `buildResetScopeQuery` y tipos desde ahí; agregar el nombre a esa lista).

4c. Reemplazar `const pathLabels = scopePathLabels(data);` por `const pathLabels = scopePathLabels(meta.scope);` (la variable `meta` ya existe en ese punto: `const { meta } = data;`).

4d. Si `OperationsDashboardData` ya no se usa en el archivo tras borrar la función, quitarlo del import.

- [ ] **Step 5: Verificar que pasa**

Run: `pnpm exec vitest run src/lib/api/operations-dashboard.test.ts`
Expected: PASS, 3 tests.

Run: `pnpm typecheck && pnpm lint`
Expected: typecheck sin errores. Lint: solo los problemas pre-existentes en `development` (76 al 2026-10-14; comparar el conteo con `git stash`-free: correr `pnpm lint` en `development` si hace falta).

Run: `pnpm test`
Expected: solo la falla pre-existente `screen-catalog.app.test.ts > matches the committed Flutter fixture`.

- [ ] **Step 6: Commit**

```bash
git add src/lib/api/operations-dashboard.ts src/lib/api/operations-dashboard.test.ts src/components/dashboard/operations-dashboard-chrome.tsx
git commit -m "feat(dashboard): accept the coordinator scope level from the operations dashboard"
```

- [ ] **Step 7: Push y PR** (solo cuando el dueño lo pida)

```bash
git push -u origin feat/operations-dashboard-coordinator-level
gh pr create --base development --title "feat(dashboard): accept the coordinator scope level" --body "Adds the coordinator scope level the backend now returns for coordinators (sacdia-backend PR: coordinator scope for the operations dashboard). The chrome shows the scope name without a territorial breadcrumb; the territory table already handles club-level children. Safe to merge before the backend deploys. Spec: docs/superpowers/specs/2026-10-14-operations-dashboard-coordinator-scope-design.md in the sacdia workspace."
```
