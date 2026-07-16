# Operations Dashboard Backend Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use `executing-plans` or `subagent-driven-development` and follow strict test-first RED → GREEN → REFACTOR cycles.

**Goal:** Exponer un dashboard operativo jerárquico, seguro y accionable para alcance global, División, Unión y Campo local, sin confundir estado administrativo con operación anual.

**Architecture:** Agregar un endpoint read-only dentro del módulo `analytics`, con resolución de alcance dedicada, consultas Prisma SQL parametrizadas y un caché corto por alcance/periodo. El contrato devuelve un corte consistente para el scope raíz y sus hijos inmediatos, separa calidad de datos y evita inventar actividad realizada o historia que el esquema no puede atribuir.

**Tech Stack:** NestJS 11, Prisma 7/PostgreSQL, class-validator/class-transformer, Jest, Swagger/OpenAPI.

**Constraints:** No ejecutar builds. No cambiar `schema.prisma` en el MVP. No hacer commits salvo solicitud posterior del usuario. No tocar `sacdia-admin` desde este plan.

---

## Semántica aprobada

- `clubs.active` = estado administrativo del registro.
- Club operativo = club con al menos una sección elegible en el año eclesiástico resuelto: `club_enrollments.status = 'active'` para el año vigente y `status IN ('active', 'closed')` para un año histórico.
- Persona institucional = `COUNT(DISTINCT club_role_assignments.user_id)` con asignación activa del mismo año y dentro del scope.
- Cuenta activa/inactiva = `users.active` dentro del conjunto institucional, nunca sustituto de membresía.
- Actividad = actividad **registrada**; el runtime no demuestra que fue realizada.
- Honores = snapshot por afiliación actual; no se presenta como historia territorial del año.
- Padre y children se recalculan; nunca se suman personas/clases/actividades no aditivas.

## Contrato objetivo

```http
GET /api/v1/admin/analytics/operations-dashboard
  ?ecclesiastical_year_id=
  &division_id=
  &union_id=
  &local_field_id=
  &report_year=
  &report_month=
```

- `ecclesiastical_year_id` es opcional; backend resuelve el año activo.
- `report_year` y `report_month` se envían juntos o se omiten juntos.
- Default de reporte: último mes calendario cerrado dentro del año eclesiástico.
- El cliente solo puede reducir el scope autorizado.
- Solo `super-admin` parte de scope global. `admin` y su alias `assistant-admin` parten de su scope efectivo configurado; DIA, Unión y Campo parten de su nivel institucional correspondiente.

```ts
type DashboardScopeLevel = 'all' | 'division' | 'union' | 'local_field';

type OperationsDashboardData = {
  meta: {
    computed_at: string;
    cached: boolean;
    cache_ttl_seconds: 60;
    definitions_version: '1';
    scope: {
      level: DashboardScopeLevel;
      id: number | null;
      name: string;
      path: Array<{
        level: Exclude<DashboardScopeLevel, 'all'>;
        id: number;
        name: string;
      }>;
    };
    period: {
      ecclesiastical_year: {
        id: number;
        start_date: string;
        end_date: string;
        active: boolean;
      };
      reporting_month: { year: number; month: number } | null;
    };
  };
  summary: OperationsDashboardMetrics;
  children: OperationsDashboardChild[];
  data_quality: Array<{
    metric: string;
    status:
      | 'exact'
      | 'current_affiliation'
      | 'unavailable'
      | 'not_applicable';
    note: string;
  }>;
};
```

No agregar `freshness: stale` por un cache hit. `cached: true` no significa dato vencido.

---

### Task 1: Query DTO and validation

**Files:**
- Create: `src/analytics/dto/operations-dashboard.dto.ts`
- Create: `src/analytics/dto/operations-dashboard.dto.spec.ts`

**Step 1: Write failing DTO tests**

Cubrir con `plainToInstance` + `validate`:

```ts
it('accepts an empty query so backend can resolve active year', async () => {});
it('transforms positive numeric identifiers', async () => {});
it('rejects zero and negative identifiers', async () => {});
it('requires report_year and report_month together', async () => {});
it('rejects report_month outside 1..12', async () => {});
```

**Step 2: Verify RED**

Run:

```bash
pnpm test --runInBand analytics/dto/operations-dashboard.dto.spec.ts
```

Expected: FAIL porque el DTO no existe.

**Step 3: Implement minimal query DTO**

Usar `@Transform`, `@IsInt`, `@Min(1)`, `@Max(12)`, `@IsOptional` y una validación de clase para el par `report_year/report_month`. Documentar cada query param con Swagger.

**Step 4: Verify GREEN**

Ejecutar el mismo comando; esperado: PASS.

---

### Task 2: Dedicated territorial scope resolver

**Files:**
- Create: `src/analytics/operations-dashboard-scope.service.ts`
- Create: `src/analytics/operations-dashboard-scope.service.spec.ts`
- Read/reference: `src/common/services/authorization-context.service.ts`
- Read/reference: `src/common/services/institutional-hierarchy.service.ts`
- Read/reference: `src/admin/admin-users.service.ts`

**Step 1: Write failing scope tests**

Casos obligatorios:

```ts
it('gives global scope only to super-admin');
it('forces admin and assistant-admin to their configured effective scope');
it('forces director-dia to the effective division');
it('allows director-dia to reduce scope to a child union or local field');
it('rejects a sibling division or descendant outside the effective division');
it('forces director-union to its union and validates local field descendants');
it('forces director-lf to its local field');
it('rejects unsupported coordinator and club roles');
it('rejects inconsistent division/union/local-field chains');
it('distinguishes not-found from out-of-bounds');
```

**Step 2: Verify RED**

```bash
pnpm test --runInBand analytics/operations-dashboard-scope.service.spec.ts
```

**Step 3: Implement minimal resolver**

Crear un tipo discriminado:

```ts
type EffectiveOperationsScope =
  | { level: 'all'; id: null; name: string; path: ScopeNode[] }
  | { level: 'division'; id: number; name: string; path: ScopeNode[] }
  | { level: 'union'; id: number; name: string; path: ScopeNode[] }
  | { level: 'local_field'; id: number; name: string; path: ScopeNode[] };
```

Resolver primero el máximo scope desde `ResolvedAuthorizationProfile`; después validar la cadena solicitada mediante consultas jerárquicas. No reutilizar `resolveReportVisibilityScope`, porque hoy concede `all` a DIA.

**Step 4: Verify GREEN and refactor**

Ejecutar el test focalizado y mantener mensajes de error canónicos sin revelar territorios fuera de alcance.

---

### Task 3: Dashboard DTO response model

**Files:**
- Modify: `src/analytics/dto/operations-dashboard.dto.ts`
- Modify: `src/analytics/dto/operations-dashboard.dto.spec.ts`

**Step 1: Write failing response-shape tests**

Validar que el DTO/serialización representa:

- `meta`, `summary`, `children`, `data_quality`;
- `coverage_pct: null` cuando no hay denominador;
- `operational_rate_pct: null` cuando no hay clubes administrativos;
- `reporting_month: null`, reportes en `0` y calidad `not_applicable` cuando el año todavía no tiene un mes cerrado;
- calidad `exact | current_affiliation | unavailable | not_applicable`;
- actividades etiquetadas `registered`, nunca `performed`;
- personas institucionales separadas de cuentas técnicas;
- clubs administrativos separados de clubs operativos.

**Step 2: Implement the Swagger DTOs**

Shape mínimo:

```ts
type OperationsDashboardMetrics = {
  administrative_clubs: { total: number; active: number; inactive: number };
  operations: {
    operational_clubs: number;
    non_operational_clubs: number;
    operational_sections: number;
    operational_rate_pct: number | null;
  };
  people: {
    institutionally_active: number;
    platform_accounts: { active: number; inactive: number };
  };
  classes: {
    total_enrollments: number;
    distinct_people: number;
    by_class: Array<{
      class_id: number;
      class_name: string;
      club_type_id: number;
      club_type_name: string;
      display_order: number;
      enrollment_count: number;
    }>;
  };
  monthly_reports: {
    expected_sections: number;
    submitted_sections: number;
    draft_sections: number;
    generated_sections: number;
    missing_sections: number;
    coverage_pct: number | null;
  };
  honors: {
    in_progress: number | null;
    pending_review: number | null;
    approved: number | null;
    attribution: 'current_affiliation' | 'unavailable';
  };
  activities: {
    registered: number;
    joint_registered: number;
    distinct_participating_sections: number;
  };
  queues: {
    role_assignments_pending: number;
    transfers_pending: number;
    class_validations_pending: number;
    honors_review_pending: number | null;
    annual_folders_pending_union: number;
  };
};
```

Cada child devuelve el mismo shape de métricas, incluido `classes.by_class`. La jerarquía inmediata es División → Unión → Campo local → Club; en scope de Campo local los children son clubes.

**Step 3: Verify**

Ejecutar la suite DTO focalizada.

---

### Task 4: Aggregate repository and mapping

**Files:**
- Create: `src/analytics/operations-dashboard.repository.ts`
- Create: `src/analytics/operations-dashboard.repository.spec.ts`
- Create: `src/analytics/operations-dashboard.mapper.ts`
- Create: `src/analytics/operations-dashboard.mapper.spec.ts`

**Step 1: Write failing mapper/repository contract tests**

Cubrir:

- dos secciones del mismo club producen un club operativo;
- un club administrativo inactivo con enrollment activo sigue siendo operativo;
- el año vigente usa enrollment `active`, mientras que un año histórico usa `active | closed` para operación, reportes, actividades y carpetas anuales;
- una persona con varios roles cuenta una vez;
- root people se recalcula y no suma children;
- actividad conjunta cuenta una actividad y varias secciones participantes;
- cola de clase usa `SUBMITTED`, no `PENDING`;
- hijos sin datos se inicializan con cero;
- SQL usa `Prisma.sql` y nunca `$queryRawUnsafe`.

**Step 2: Verify RED**

```bash
pnpm test --runInBand analytics/operations-dashboard.mapper.spec.ts analytics/operations-dashboard.repository.spec.ts
```

**Step 3: Implement parameterized grouped queries**

Usar CTEs `DISTINCT` para fijar el grano y consultas agrupadas para padre/hijos. Consultas previstas:

1. hijos jerárquicos + clubes administrativos;
2. clubes/secciones operativas;
3. personas/cuentas;
4. clases;
5. reportes;
6. honores actuales;
7. actividades registradas;
8. colas mediante `UNION ALL`.

Las condiciones territoriales deben provenir del scope resuelto, no concatenarse desde strings del request. Paralelizar solo consultas independientes.

**Step 4: Verify GREEN and refactor**

Mantener helpers pequeños para `safeNumber`, porcentaje nullable e inicialización de children.

---

### Task 5: Service orchestration and cache

**Files:**
- Create: `src/analytics/operations-dashboard.service.ts`
- Create: `src/analytics/operations-dashboard.service.spec.ts`

**Step 1: Write failing service tests**

```ts
it('defaults to the active ecclesiastical year');
it('fails explicitly when no active year exists');
it('defaults to the last closed reporting month inside the year');
it('returns reporting_month null when the year has no closed calendar month');
it('uses one computed_at across summary and children');
it('keys cache by actor-resolved scope, year, report month and definitions version');
it('marks cache hits cached without marking them stale');
it('does not cache authorization failures');
it('returns honors unavailable for a non-current historical year');
```

**Step 2: Verify RED**

```bash
pnpm test --runInBand analytics/operations-dashboard.service.spec.ts
```

**Step 3: Implement orchestration**

- Resolver scope primero.
- Resolver año explícito o año activo.
- Validar que reporte solicitado cae dentro del año.
- Consultar repository.
- Mapear data quality.
- Cache `Map` 60 segundos como precedente del módulo actual.

**Step 4: Verify GREEN**

Ejecutar suite focalizada.

---

### Task 6: Controller and module integration

**Files:**
- Modify: `src/analytics/analytics.controller.ts`
- Modify: `src/analytics/analytics.module.ts`
- Create: `src/analytics/analytics.controller.spec.ts`

**Step 1: Write failing controller tests**

Verificar:

- ruta y envelope `{ status: 'ok', data }`;
- query DTO llega al servicio;
- actor se toma de `req.user.sub`;
- roles permitidos: `admin` (incluye el alias `assistant-admin` del guard), `super-admin`, directores/asistentes DIA, Unión y Campo;
- coordinator y roles de club no quedan autorizados;
- propagación de 400/403/404 sin convertirlos en respuesta vacía.

**Step 2: Implement endpoint**

```ts
@Get('operations-dashboard')
@GlobalRoles(/* roles institucionales permitidos */)
async getOperationsDashboard(@Request() req, @Query() query) {
  const data = await this.operationsDashboardService.getDashboard(req.user.sub, query);
  return { status: 'ok', data };
}
```

Agregar Swagger operation/query/response y registrar providers.

**Step 3: Verify**

```bash
pnpm test --runInBand analytics/analytics.controller.spec.ts
```

---

### Task 7: Integration coverage

**Files:**
- Create: `test/operations-dashboard.e2e-spec.ts`
- Reuse: helpers/fixtures E2E existentes.

**Step 1: Write the failing E2E scenarios**

- 401 sin autenticación.
- 403 director de Unión intentando scope hermano.
- 400 cadena territorial inconsistente.
- 404 entidad inexistente dentro de una cadena válida.
- 200 con scope forzado y children correctos.
- club con dos secciones activas cuenta una vez.
- cero real y cobertura no aplicable no se confunden.
- ninguna PII de miembros en respuesta.

**Step 2: Run RED only if E2E environment is available**

```bash
pnpm test:e2e --runInBand operations-dashboard.e2e-spec.ts
```

Si el entorno E2E no está configurado, documentar el bloqueo exacto; no sustituir SQL real con una afirmación no verificada.

**Step 3: Implement fixtures/minimal fixes and verify GREEN**

No modificar datos reales ni `.env`.

---

### Task 8: Canonical documentation

**Files (root docs worktree):**
- Modify: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- Modify: `docs/api/SECURITY-GUIDE.md`
- Create: `docs/features/operations-dashboard.md`

Documentar:

- endpoint, roles, filtros y errores;
- matriz de scope;
- definición exacta de club operativo;
- diferencia con `clubs.active`;
- fórmulas de personas, clases, reportes y actividades;
- métricas `current_affiliation` y `unavailable`;
- cache/freshness;
- métricas aplazadas.

No sobrescribir cambios no relacionados del workspace principal.

---

### Task 9: Verification and review

**Commands — no build:**

```bash
pnpm exec prisma generate
pnpm test --runInBand analytics/dto/operations-dashboard.dto.spec.ts
pnpm test --runInBand analytics/operations-dashboard-scope.service.spec.ts
pnpm test --runInBand analytics/operations-dashboard.mapper.spec.ts
pnpm test --runInBand analytics/operations-dashboard.repository.spec.ts
pnpm test --runInBand analytics/operations-dashboard.service.spec.ts
pnpm test --runInBand analytics/analytics.controller.spec.ts
pnpm test --runInBand
pnpm exec eslint \
  src/analytics/dto/operations-dashboard.dto.ts \
  src/analytics/operations-dashboard-scope.service.ts \
  src/analytics/operations-dashboard.repository.ts \
  src/analytics/operations-dashboard.mapper.ts \
  src/analytics/operations-dashboard.service.ts \
  src/analytics/analytics.controller.ts \
  src/analytics/analytics.module.ts
git diff --check
```

Después:

1. revisión de cumplimiento contra esta especificación;
2. revisión de seguridad de scope/BOLA;
3. revisión de calidad, queries y no aditividad;
4. verificar documentación contra el DTO runtime final;
5. preparar el prompt final de handoff para `sacdia-admin` usando nombres exactos del DTO implementado.

**Baseline confirmado antes del cambio:** 188/188 suites, 2460 tests passed, 1 skipped; sin build.
