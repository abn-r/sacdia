# Inicio del admin por nivel de alcance — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reemplazar el inicio de 8 bloques iguales por dos modos con jerarquía clara — supervisión (tabla por brecha primero) y despacho (cola de pendientes primero) — elegidos por el nivel de alcance.

**Architecture:** Funciones puras en `src/lib/dashboard/operations-home.ts` deciden modo, orden y frases. `OperationsDashboardView` (async) arma props planas y renderiza `SupervisionHome` o `DispatchHome` (síncronas, testeables). Se borra el código muerto (`v2`, `bento`, KPI strip, accesos directos).

**Tech Stack:** Next.js 16 (RSC), React 19, shadcn/ui, Tailwind v4, next-intl (modo estricto: `src/i18n/messages.d.ts` se genera desde `messages/es.json`), Vitest + Testing Library.

**Spec:** `docs/superpowers/specs/2026-10-14-dashboard-home-by-scope-design.md`

---

## Reglas para quien ejecuta

- Repo: `sacdia-admin/` (git propio). Comandos desde ahí.
- Commits convencionales en inglés, **sin** atribución de IA. No push ni PR salvo que el dueño lo pida.
- Shell: `rg`, `fd`, `sd`, `bat`, `eza`. Nunca `grep`/`find`/`sed`/`cat`/`ls`. Ediciones multilínea con la herramienta Edit.
- **No** correr `pnpm build`.
- **Antes de "crear" un archivo, confirmar que no existe** (`fd -t f <nombre> src`). Si existe, detenerse y reportar.
- i18n en modo estricto: tras editar `messages/es.json`, regenerar tipos con `node scripts/generate-messages-types.mjs`. `pnpm typecheck` falla si un `t("...")` usa una clave inexistente: es la red de seguridad al borrar claves.
- **No reescribir los JSON completos** con `JSON.stringify`: los archivos tienen objetos compactos en una línea en otros módulos y se expandirían (ruido en el diff). Usar el helper de abajo, que reescribe **solo** `dashboardHub.operations` y deja el resto byte a byte (verificado el 2026-10-14 en los 4 idiomas).

## Helper i18n (crear una vez, fuera del repo)

Crear `/tmp/sacdia-i18n/ops-block.cjs` (no se commitea):

```js
// Rewrites only messages/<locale>.json -> dashboardHub.operations, keeping the rest byte-identical.
const fs = require("fs");
function locate(raw) {
  const hub = raw.indexOf('\n  "dashboardHub": {');
  if (hub < 0) throw new Error("dashboardHub not found");
  const start = raw.indexOf('\n    "operations": {', hub) + 1;
  const open = raw.indexOf("{", start);
  let depth = 0, inStr = false, esc = false, i = open;
  for (; i < raw.length; i++) {
    const c = raw[i];
    if (inStr) { if (esc) esc = false; else if (c === "\\") esc = true; else if (c === '"') inStr = false; continue; }
    if (c === '"') inStr = true; else if (c === "{") depth++; else if (c === "}") { depth--; if (depth === 0) break; }
  }
  return { open, close: i };
}
function serialize(obj) {
  return JSON.stringify(obj, null, 2).split("\n").map((l, idx) => (idx === 0 ? l : "    " + l)).join("\n");
}
module.exports = function editOperations(file, mutate) {
  const raw = fs.readFileSync(file, "utf8");
  const { open, close } = locate(raw);
  const ops = JSON.parse(raw.slice(open, close + 1));
  mutate(ops);
  const next = raw.slice(0, open) + serialize(ops) + raw.slice(close + 1);
  JSON.parse(next);
  fs.writeFileSync(file, next);
};
```

Verificación tras cada uso: `git diff messages/es.json | rg '^@@'` debe mostrar hunks solo dentro del bloque `operations` (líneas ~1744–2000 de `es.json`).
- Fallas pre-existentes en `development` (no son tuyas): `pnpm lint` ≈76 problemas; `pnpm test` falla solo `screen-catalog.app.test.ts > matches the committed Flutter fixture`. Para lint, verificar solo los archivos tocados con `pnpm exec eslint <archivos>`.

## Mapa de archivos

| Archivo | PR | Cambio |
|---|---|---|
| `src/components/dashboard/dashboard-version-switch.tsx` | 1 | Borrar |
| `src/components/dashboard/dashboard-metric-progress.tsx` | 1 | Borrar |
| `src/components/dashboard/operations-dashboard-bento.tsx` | 1 | Borrar |
| `src/components/dashboard/operations-dashboard-bento-client.tsx` | 1 | Borrar |
| `src/components/dashboard/operations-bento-mini-charts.tsx` | 1 | Borrar |
| `src/components/dashboard/operations-dashboard-v2-view.tsx` | 1 | Borrar |
| `src/components/dashboard/operations-dashboard-v2-charts.tsx` | 1 | Borrar |
| `messages/*.json`, `src/i18n/messages.d.ts` | 1 y 2 | Quitar claves muertas; agregar claves nuevas |
| `src/lib/dashboard/operations-home.ts` (+ `.test.ts`) | 2 | Funciones puras nuevas; quitar accesos directos |
| `src/components/dashboard/operations-gap-table.tsx` | 2 | Nuevo |
| `src/components/dashboard/operations-period-context.tsx` | 2 | Nuevo |
| `src/components/dashboard/operations-home-supervision.tsx` | 2 | Nuevo |
| `src/components/dashboard/operations-home-dispatch.tsx` | 2 | Nuevo |
| `src/components/dashboard/operations-work-queue.tsx` | 2 | Reescritura (sin card, filas con acción) |
| `src/components/dashboard/operations-data-quality.tsx` | 2 | Nota al pie |
| `src/components/dashboard/operations-dashboard-view.tsx` | 2 | Container que elige modo |
| `src/components/dashboard/operations-dashboard.test.tsx` | 1 y 2 | Ajustar |
| `src/app/(dashboard)/dashboard/loading.tsx` | 2 | Skeleton nuevo |
| `operations-kpi-strip`, `operations-coverage-card`, `operations-shortcuts`, `operations-bento-tile`, `territory-breakdown-table` | 2 | Borrar |

---

# PR 1 — `refactor/dashboard-remove-dead-views`

### Task 0: Rama

- [ ] **Step 1**

```bash
git checkout development
git pull --ff-only
git checkout -b refactor/dashboard-remove-dead-views
```

Expected: `Switched to a new branch 'refactor/dashboard-remove-dead-views'`. Si hay cambios sin commit, detenerse y reportar.

---

### Task 1: Borrar vistas muertas y sus claves

**Files:** los 7 componentes de la tabla (PR 1), `messages/{es,en,fr,pt-BR}.json`, `src/i18n/messages.d.ts`, `src/components/dashboard/operations-dashboard.test.tsx:116`.

- [ ] **Step 1: Confirmar que nadie los usa fuera del grupo**

```bash
rg -l 'dashboard-version-switch|dashboard-metric-progress|operations-dashboard-bento|operations-bento-mini-charts|operations-dashboard-v2-view|operations-dashboard-v2-charts' src -g '!src/components/dashboard/dashboard-version-switch.tsx' -g '!src/components/dashboard/dashboard-metric-progress.tsx' -g '!src/components/dashboard/operations-dashboard-bento.tsx' -g '!src/components/dashboard/operations-dashboard-bento-client.tsx' -g '!src/components/dashboard/operations-bento-mini-charts.tsx' -g '!src/components/dashboard/operations-dashboard-v2-view.tsx' -g '!src/components/dashboard/operations-dashboard-v2-charts.tsx'
```

Expected: sin resultados. Si aparece algún archivo, detenerse y reportar.

- [ ] **Step 2: Borrar**

```bash
git rm -q src/components/dashboard/dashboard-version-switch.tsx src/components/dashboard/dashboard-metric-progress.tsx src/components/dashboard/operations-dashboard-bento.tsx src/components/dashboard/operations-dashboard-bento-client.tsx src/components/dashboard/operations-bento-mini-charts.tsx src/components/dashboard/operations-dashboard-v2-view.tsx src/components/dashboard/operations-dashboard-v2-charts.tsx
```

- [ ] **Step 3: Quitar las claves `version`, `v2` y `adminDiagnostic` de los 4 idiomas**

Solo las usaban los archivos borrados (`adminDiagnostic` no lo usa ningún archivo). Correr:

Crear antes el helper de la sección "Helper i18n". Luego:

```bash
node -e '
const editOperations = require("/tmp/sacdia-i18n/ops-block.cjs");
for (const locale of ["es", "en", "fr", "pt-BR"]) {
  editOperations(`messages/${locale}.json`, (ops) => {
    for (const key of ["version", "v2", "adminDiagnostic"]) delete ops[key];
  });
}
'
node scripts/generate-messages-types.mjs
git diff --stat messages
```

Expected: solo eliminaciones en los 4 JSON. Verificar con `git diff messages/es.json | rg '^\+' | rg -v '^\+\+\+'`: como mucho una línea por objeto vecino que pierde o gana coma. Si aparecen otras líneas añadidas, detenerse y reportar.

- [ ] **Step 4: Ajustar el test de traducciones**

En `src/components/dashboard/operations-dashboard.test.tsx`, borrar la línea:

```ts
    expect(messages.dashboardHub.operations.version.switchLabel).toBeTruthy();
```

- [ ] **Step 5: Verificar**

Run: `pnpm typecheck` → sin errores.
Run: `pnpm exec vitest run src/components/dashboard src/app/\(dashboard\)/dashboard src/lib/dashboard src/lib/api/operations-dashboard.test.ts` → todo verde.
Run: `pnpm audit:design-system --strict > /dev/null; echo "exit:$?"` → `exit:0`.

- [ ] **Step 6: Commit**

```bash
git add -A src/components/dashboard messages src/i18n/messages.d.ts
git commit -m "refactor(dashboard): remove unused v2 and bento dashboard views"
```

---

# PR 2 — `feat/dashboard-home-by-scope` (base: rama del PR 1)

### Task 2: Rama encadenada

- [ ] **Step 1**

```bash
git checkout refactor/dashboard-remove-dead-views
git checkout -b feat/dashboard-home-by-scope
```

---

### Task 3: Funciones puras (test primero)

**Files:**
- Modify: `src/lib/dashboard/operations-home.ts`
- Modify: `src/lib/dashboard/operations-home.test.ts`

- [ ] **Step 1: Reemplazar el archivo de tests completo**

`src/lib/dashboard/operations-home.test.ts` existe con 5 tests (uno sobre accesos directos, que desaparecen). Reemplazar su contenido por:

```ts
import { beforeEach, describe, expect, it, vi } from "vitest";
import type {
  DashboardMetrics,
  OperationsDashboardChild,
  OperationsDashboardScope,
} from "@/lib/api/operations-dashboard";
import type { AuthUser } from "@/lib/auth/types";

vi.mock("@/lib/auth/require-page-access", () => ({
  canAccessDashboardPath: vi.fn(),
}));

import { canAccessDashboardPath } from "@/lib/auth/require-page-access";
import {
  buildWorkQueue,
  childGap,
  dispatchSummary,
  hrefPath,
  laggingClubs,
  OPERATIONS_QUEUE_HREFS,
  rankChildrenByGap,
  resolveHomeMode,
  supervisionSummary,
  visibleWorkQueue,
} from "@/lib/dashboard/operations-home";

const mockCanAccess = vi.mocked(canAccessDashboardPath);

function metrics(
  overrides: {
    queues?: Partial<DashboardMetrics["queues"]>;
    reports?: Partial<DashboardMetrics["monthly_reports"]>;
    nonOperational?: number;
  } = {},
): DashboardMetrics {
  return {
    administrative_clubs: { total: 2, active: 2, inactive: 0 },
    operations: {
      operational_clubs: 1,
      non_operational_clubs: overrides.nonOperational ?? 0,
      operational_sections: 2,
      operational_rate_pct: 50,
    },
    people: {
      institutionally_active: 10,
      platform_accounts: { active: 10, inactive: 0 },
    },
    classes: { total_enrollments: 4, distinct_people: 4, by_class: [] },
    monthly_reports: {
      expected_sections: 2,
      submitted_sections: 2,
      draft_sections: 0,
      generated_sections: 0,
      missing_sections: 0,
      coverage_pct: 100,
      ...overrides.reports,
    },
    honors: {
      in_progress: 1,
      pending_review: 3,
      approved: 1,
      attribution: "current_affiliation",
    },
    activities: {
      registered: 8,
      joint_registered: 1,
      distinct_participating_sections: 2,
    },
    queues: {
      role_assignments_pending: 0,
      transfers_pending: 0,
      class_validations_pending: 0,
      honors_review_pending: 0,
      annual_folders_pending_union: 0,
      ...overrides.queues,
    },
  };
}

function child(
  id: number,
  name: string,
  overrides: Parameters<typeof metrics>[0] = {},
): OperationsDashboardChild {
  return { id, name, level: "club", ...metrics(overrides) };
}

const scope = (level: OperationsDashboardScope["level"]): OperationsDashboardScope => ({
  level,
  id: level === "all" || level === "coordinator" ? null : 1,
  name: "Alcance",
  path: [],
});

const user = {} as AuthUser;

beforeEach(() => {
  mockCanAccess.mockReset();
});

describe("resolveHomeMode", () => {
  it("dispatches in the actor's own local field or coordinator scope", () => {
    expect(resolveHomeMode(scope("local_field"), {})).toBe("dispatch");
    expect(resolveHomeMode(scope("coordinator"), {})).toBe("dispatch");
  });

  it("supervises at every wider level", () => {
    expect(resolveHomeMode(scope("all"), {})).toBe("supervise");
    expect(resolveHomeMode(scope("division"), {})).toBe("supervise");
    expect(resolveHomeMode(scope("union"), {})).toBe("supervise");
  });

  it("supervises any drilled-down scope, even a local field", () => {
    expect(resolveHomeMode(scope("local_field"), { local_field_id: 7 })).toBe("supervise");
    expect(resolveHomeMode(scope("local_field"), { union_id: 3 })).toBe("supervise");
    expect(resolveHomeMode(scope("union"), { division_id: 1 })).toBe("supervise");
  });

  it("ignores period-only query params", () => {
    expect(
      resolveHomeMode(scope("local_field"), { report_year: 2026, report_month: 8 }),
    ).toBe("dispatch");
  });
});

describe("childGap", () => {
  it("counts missing reports only when a reporting month exists", () => {
    const lagging = child(1, "A", { reports: { missing_sections: 3 } });
    expect(childGap(lagging, true)).toMatchObject({ missingSections: 3, hasGap: true });
    expect(childGap(lagging, false)).toMatchObject({ missingSections: 0, hasGap: false });
  });

  it("treats unavailable honors review as zero in the pending total", () => {
    const value = child(1, "A", {
      queues: { transfers_pending: 2, honors_review_pending: null, role_assignments_pending: 1 },
    });
    expect(childGap(value, true).pendingTotal).toBe(3);
  });

  it("flags non-operational clubs as a gap", () => {
    expect(childGap(child(1, "A", { nonOperational: 1 }), true).hasGap).toBe(true);
  });
});

describe("rankChildrenByGap", () => {
  it("orders by gap, missing reports, non-operational, pending, then name", () => {
    const ranked = rankChildrenByGap(
      [
        child(1, "Sin brecha B", { queues: { transfers_pending: 9 } }),
        child(2, "Pocos faltantes", { reports: { missing_sections: 1 } }),
        child(3, "Muchos faltantes", { reports: { missing_sections: 5 } }),
        child(4, "Sin brecha A"),
        child(5, "No operativo", { nonOperational: 2 }),
        child(6, "Pocos faltantes con pendientes", {
          reports: { missing_sections: 1 },
          queues: { role_assignments_pending: 4 },
        }),
      ],
      true,
    );

    expect(ranked.map((row) => row.child.name)).toEqual([
      "Muchos faltantes",
      "Pocos faltantes con pendientes",
      "Pocos faltantes",
      "No operativo",
      "Sin brecha B",
      "Sin brecha A",
    ]);
  });
});

describe("laggingClubs", () => {
  it("keeps only children with a gap and names each reason", () => {
    const rows = laggingClubs(
      [
        child(1, "Al día"),
        child(2, "Ambos", { reports: { missing_sections: 1 }, nonOperational: 1 }),
        child(3, "Solo informe", { reports: { missing_sections: 2 } }),
      ],
      true,
    );

    expect(rows.map((row) => [row.child.name, row.reasons])).toEqual([
      ["Solo informe", ["missingReport"]],
      ["Ambos", ["missingReport", "nonOperational"]],
    ]);
  });
});

describe("supervisionSummary", () => {
  it("counts children that reported, ignoring those that expected nothing", () => {
    const messages = supervisionSummary(
      [
        child(1, "A"),
        child(2, "B", { reports: { missing_sections: 1 } }),
        child(3, "C", { reports: { expected_sections: 0, submitted_sections: 0 } }),
      ],
      "local_field",
      metrics({ nonOperational: 2 }),
      true,
    );

    expect(messages).toEqual([
      { key: "childrenReported", values: { reported: 1, total: 2, level: "local_field" } },
      { key: "nonOperationalClubs", values: { count: 2 } },
    ]);
  });

  it("says there is no closed month and skips the report count", () => {
    expect(supervisionSummary([child(1, "A")], "union", metrics(), false)).toEqual([
      { key: "noClosedMonth", values: {} },
    ]);
  });

  it("omits the report sentence when no child expected a report", () => {
    expect(
      supervisionSummary(
        [child(1, "A", { reports: { expected_sections: 0 } })],
        "club",
        metrics(),
        true,
      ),
    ).toEqual([]);
  });
});

describe("dispatchSummary", () => {
  it("reports submitted over expected sections and non-operational clubs", () => {
    expect(
      dispatchSummary(
        metrics({ reports: { expected_sections: 20, submitted_sections: 18 }, nonOperational: 1 }),
        true,
      ),
    ).toEqual([
      { key: "sectionsReported", values: { submitted: 18, expected: 20 } },
      { key: "nonOperationalClubs", values: { count: 1 } },
    ]);
  });

  it("says there is no closed month", () => {
    expect(dispatchSummary(metrics(), false)).toEqual([{ key: "noClosedMonth", values: {} }]);
  });

  it("omits the report sentence when no section expected a report", () => {
    expect(dispatchSummary(metrics({ reports: { expected_sections: 0 } }), true)).toEqual([]);
  });
});

describe("work queue", () => {
  it("keeps only pending queues and sorts by count", () => {
    const queue = buildWorkQueue(
      metrics({
        queues: {
          transfers_pending: 1,
          class_validations_pending: 4,
          honors_review_pending: 3,
        },
      }),
    );

    expect(queue.map((item) => item.id)).toEqual(["classes", "honors", "transfers"]);
    expect(queue[0]?.href).toContain("/dashboard/clubs/validations");
  });

  it("drops unavailable honors review instead of coercing to zero", () => {
    const queue = buildWorkQueue(
      metrics({ queues: { honors_review_pending: null, transfers_pending: 2 } }),
    );
    expect(queue.map((item) => item.id)).toEqual(["transfers"]);
  });

  it("shows only queues the user can open", () => {
    mockCanAccess.mockImplementation((_user, path) => path !== "/dashboard/annual-folders/evaluate");

    const queue = visibleWorkQueue(
      metrics({ queues: { annual_folders_pending_union: 7, transfers_pending: 1 } }),
      user,
    );

    expect(queue.map((item) => item.id)).toEqual(["transfers"]);
    expect(mockCanAccess).toHaveBeenCalledWith(user, "/dashboard/annual-folders/evaluate");
  });

  it("strips query strings for access checks", () => {
    expect(hrefPath("/dashboard/clubs/validations?tab=honors")).toBe(
      "/dashboard/clubs/validations",
    );
  });

  it("sends the class queue to class section evidence", () => {
    expect(OPERATIONS_QUEUE_HREFS.classes).toBe("/dashboard/clubs/validations?tab=sections");
  });
});
```

- [ ] **Step 2: Verificar que falla**

Run: `pnpm exec vitest run src/lib/dashboard/operations-home.test.ts`
Expected: FAIL — `resolveHomeMode`/`childGap`/… no se exportan.

- [ ] **Step 3: Implementar**

En `src/lib/dashboard/operations-home.ts`:

3a. Reemplazar el import de tipos:

```ts
import type { DashboardMetrics } from "@/lib/api/operations-dashboard";
```

por:

```ts
import type {
  ChildLevel,
  DashboardMetrics,
  OperationsDashboardChild,
  OperationsDashboardQuery,
  OperationsDashboardScope,
} from "@/lib/api/operations-dashboard";
```

3b. Borrar `OperationsShortcutId`, `OPERATIONS_SHORTCUTS` y `resolveAccessibleShortcuts` completos.

3c. Al final del archivo agregar:

```ts
export type HomeMode = "supervise" | "dispatch";

/**
 * Dispatch (work queue first) only for the actor's own local field or
 * coordinator scope. Wider levels and any drill-down supervise.
 */
export function resolveHomeMode(
  scope: OperationsDashboardScope,
  query: OperationsDashboardQuery,
): HomeMode {
  const drilledDown =
    query.division_id !== undefined ||
    query.union_id !== undefined ||
    query.local_field_id !== undefined;
  const dispatchLevel = scope.level === "local_field" || scope.level === "coordinator";
  return dispatchLevel && !drilledDown ? "dispatch" : "supervise";
}

export type ChildGap = {
  missingSections: number;
  nonOperationalClubs: number;
  pendingTotal: number;
  hasGap: boolean;
};

function pendingTotal(queues: DashboardMetrics["queues"]): number {
  return (
    queues.role_assignments_pending +
    queues.transfers_pending +
    queues.class_validations_pending +
    (queues.honors_review_pending ?? 0) +
    queues.annual_folders_pending_union
  );
}

export function childGap(
  child: OperationsDashboardChild,
  hasReportingMonth: boolean,
): ChildGap {
  const missingSections = hasReportingMonth ? child.monthly_reports.missing_sections : 0;
  const nonOperationalClubs = child.operations.non_operational_clubs;
  return {
    missingSections,
    nonOperationalClubs,
    pendingTotal: pendingTotal(child.queues),
    hasGap: missingSections > 0 || nonOperationalClubs > 0,
  };
}

export type RankedChild = { child: OperationsDashboardChild; gap: ChildGap };

export function rankChildrenByGap(
  children: OperationsDashboardChild[],
  hasReportingMonth: boolean,
): RankedChild[] {
  return children
    .map((child) => ({ child, gap: childGap(child, hasReportingMonth) }))
    .sort(
      (a, b) =>
        Number(b.gap.hasGap) - Number(a.gap.hasGap) ||
        b.gap.missingSections - a.gap.missingSections ||
        b.gap.nonOperationalClubs - a.gap.nonOperationalClubs ||
        b.gap.pendingTotal - a.gap.pendingTotal ||
        a.child.name.localeCompare(b.child.name, "es"),
    );
}

export type LagReason = "missingReport" | "nonOperational";

export function laggingClubs(
  children: OperationsDashboardChild[],
  hasReportingMonth: boolean,
): Array<{ child: OperationsDashboardChild; reasons: LagReason[] }> {
  return rankChildrenByGap(children, hasReportingMonth)
    .filter(({ gap }) => gap.hasGap)
    .map(({ child, gap }) => {
      const reasons: LagReason[] = [];
      if (gap.missingSections > 0) reasons.push("missingReport");
      if (gap.nonOperationalClubs > 0) reasons.push("nonOperational");
      return { child, reasons };
    });
}

export type SummaryMessage =
  | { key: "childrenReported"; values: { reported: number; total: number; level: ChildLevel } }
  | { key: "sectionsReported"; values: { submitted: number; expected: number } }
  | { key: "noClosedMonth"; values: Record<string, never> }
  | { key: "nonOperationalClubs"; values: { count: number } };

function nonOperationalMessage(summary: DashboardMetrics): SummaryMessage[] {
  const count = summary.operations.non_operational_clubs;
  return count > 0 ? [{ key: "nonOperationalClubs", values: { count } }] : [];
}

export function supervisionSummary(
  children: OperationsDashboardChild[],
  childLevel: ChildLevel,
  summary: DashboardMetrics,
  hasReportingMonth: boolean,
): SummaryMessage[] {
  if (!hasReportingMonth) {
    return [{ key: "noClosedMonth", values: {} }, ...nonOperationalMessage(summary)];
  }
  const expecting = children.filter((child) => child.monthly_reports.expected_sections > 0);
  const reported = expecting.filter((child) => child.monthly_reports.missing_sections === 0);
  const reportMessage: SummaryMessage[] =
    expecting.length > 0
      ? [
          {
            key: "childrenReported",
            values: { reported: reported.length, total: expecting.length, level: childLevel },
          },
        ]
      : [];
  return [...reportMessage, ...nonOperationalMessage(summary)];
}

export function dispatchSummary(
  summary: DashboardMetrics,
  hasReportingMonth: boolean,
): SummaryMessage[] {
  if (!hasReportingMonth) {
    return [{ key: "noClosedMonth", values: {} }, ...nonOperationalMessage(summary)];
  }
  const { expected_sections: expected, submitted_sections: submitted } = summary.monthly_reports;
  const reportMessage: SummaryMessage[] =
    expected > 0 ? [{ key: "sectionsReported", values: { submitted, expected } }] : [];
  return [...reportMessage, ...nonOperationalMessage(summary)];
}

/** Pending queues with work AND a screen the user can open. */
export function visibleWorkQueue(
  summary: DashboardMetrics,
  user: AuthUser,
): OperationsWorkItem[] {
  return buildWorkQueue(summary).filter((item) => firstAccessibleHref(user, [item.href]));
}
```

Nota: en el segundo test de `supervisionSummary` el resultado esperado es solo `noClosedMonth` porque `metrics()` tiene `non_operational_clubs: 0`.

- [ ] **Step 4: Verificar que pasa**

Run: `pnpm exec vitest run src/lib/dashboard/operations-home.test.ts`
Expected: PASS, 20 tests.

Run: `pnpm typecheck`
Expected: errores **solo** en `src/components/dashboard/operations-dashboard-view.tsx` y `operations-shortcuts.tsx` (usan `resolveAccessibleShortcuts` / `OperationsShortcutId`, que ya no existen). Se resuelven en las tareas 9 y 10. Cualquier otro error es tuyo.

- [ ] **Step 5: Commit**

```bash
git add src/lib/dashboard/operations-home.ts src/lib/dashboard/operations-home.test.ts
git commit -m "feat(dashboard): add scope-based home mode, gap ranking, and summaries"
```

---

### Task 4: Claves i18n nuevas

**Files:** `messages/{es,en,fr,pt-BR}.json`, `src/i18n/messages.d.ts`

- [ ] **Step 1: Agregar claves bajo `dashboardHub.operations.home`**

Correr (agrega o sobrescribe solo las claves listadas; no borra nada todavía; usa el helper de "Helper i18n"):

```bash
node -e '
const editOperations = require("/tmp/sacdia-i18n/ops-block.cjs");
const home = {
  es: {
    description: "Lo que necesita atención en tu alcance.",
    summary: {
      childrenReported: "{reported} de {total} {level, select, division {divisiones} union {uniones} local_field {campos locales} other {clubes}} entregaron el informe del mes.",
      sectionsReported: "{submitted} de {expected} secciones entregaron el informe del mes.",
      noClosedMonth: "Todavía no hay un mes cerrado para medir los informes.",
      nonOperationalClubs: "{count, plural, one {# club no operativo.} other {# clubes no operativos.}}"
    },
    gapTable: {
      title: "{level, select, division {Divisiones} union {Uniones} local_field {Campos locales} other {Clubes}}",
      description: "Primero los que tienen informes faltantes o clubes no operativos.",
      columns: { name: "Nombre", reports: "Informes", nonOperational: "No operativos", pending: "Pendientes" },
      missingCount: "faltan {count}",
      emptyTitle: "Sin territorios en este alcance",
      emptyDescription: "Este nivel todavía no tiene territorios hijos registrados."
    },
    pendingTitle: "Pendientes",
    review: "Revisar",
    dispatchTitle: "Por atender",
    dispatchEmptyTitle: "Nada pendiente en tu alcance",
    dispatchEmptyDescription: "Cuando llegue una solicitud o una validación, aparece aquí.",
    laggingTitle: "Clubes que van atrás",
    lagReason: { missingReport: "Sin informe del mes", nonOperational: "No operativo" },
    periodContextTitle: "Contexto del periodo"
  },
  en: {
    description: "What needs attention in your scope.",
    summary: {
      childrenReported: "{reported} of {total} {level, select, division {divisions} union {unions} local_field {local fields} other {clubs}} submitted this month’s report.",
      sectionsReported: "{submitted} of {expected} sections submitted this month’s report.",
      noClosedMonth: "There’s no closed month to measure reports yet.",
      nonOperationalClubs: "{count, plural, one {# non-operational club.} other {# non-operational clubs.}}"
    },
    gapTable: {
      title: "{level, select, division {Divisions} union {Unions} local_field {Local fields} other {Clubs}}",
      description: "Missing reports and non-operational clubs come first.",
      columns: { name: "Name", reports: "Reports", nonOperational: "Non-operational", pending: "Pending" },
      missingCount: "{count} missing",
      emptyTitle: "No territories in this scope",
      emptyDescription: "This level has no child territories registered yet."
    },
    pendingTitle: "Pending",
    review: "Review",
    dispatchTitle: "To do",
    dispatchEmptyTitle: "Nothing pending in your scope",
    dispatchEmptyDescription: "New requests and validations show up here.",
    laggingTitle: "Clubs falling behind",
    lagReason: { missingReport: "No report this month", nonOperational: "Non-operational" },
    periodContextTitle: "Period context"
  },
  fr: {
    description: "Ce qui demande votre attention dans votre périmètre.",
    summary: {
      childrenReported: "{reported} sur {total} {level, select, division {divisions} union {unions} local_field {champs locaux} other {clubs}} ont remis le rapport du mois.",
      sectionsReported: "{submitted} sections sur {expected} ont remis le rapport du mois.",
      noClosedMonth: "Aucun mois clôturé pour mesurer les rapports pour l’instant.",
      nonOperationalClubs: "{count, plural, one {# club non opérationnel.} other {# clubs non opérationnels.}}"
    },
    gapTable: {
      title: "{level, select, division {Divisions} union {Unions} local_field {Champs locaux} other {Clubs}}",
      description: "Les rapports manquants et les clubs non opérationnels en premier.",
      columns: { name: "Nom", reports: "Rapports", nonOperational: "Non opérationnels", pending: "En attente" },
      missingCount: "{count} manquants",
      emptyTitle: "Aucun territoire dans ce périmètre",
      emptyDescription: "Ce niveau n’a encore aucun territoire enfant enregistré."
    },
    pendingTitle: "En attente",
    review: "Examiner",
    dispatchTitle: "À traiter",
    dispatchEmptyTitle: "Rien en attente dans votre périmètre",
    dispatchEmptyDescription: "Les nouvelles demandes et validations apparaissent ici.",
    laggingTitle: "Clubs en retard",
    lagReason: { missingReport: "Pas de rapport ce mois-ci", nonOperational: "Non opérationnel" },
    periodContextTitle: "Contexte de la période"
  },
  "pt-BR": {
    description: "O que precisa de atenção no seu escopo.",
    summary: {
      childrenReported: "{reported} de {total} {level, select, division {divisões} union {uniões} local_field {campos locais} other {clubes}} entregaram o relatório do mês.",
      sectionsReported: "{submitted} de {expected} seções entregaram o relatório do mês.",
      noClosedMonth: "Ainda não há um mês fechado para medir os relatórios.",
      nonOperationalClubs: "{count, plural, one {# clube não operacional.} other {# clubes não operacionais.}}"
    },
    gapTable: {
      title: "{level, select, division {Divisões} union {Uniões} local_field {Campos locais} other {Clubes}}",
      description: "Primeiro os que têm relatórios faltando ou clubes não operacionais.",
      columns: { name: "Nome", reports: "Relatórios", nonOperational: "Não operacionais", pending: "Pendentes" },
      missingCount: "faltam {count}",
      emptyTitle: "Sem territórios neste escopo",
      emptyDescription: "Este nível ainda não tem territórios filhos registrados."
    },
    pendingTitle: "Pendentes",
    review: "Revisar",
    dispatchTitle: "Para atender",
    dispatchEmptyTitle: "Nada pendente no seu escopo",
    dispatchEmptyDescription: "Novas solicitações e validações aparecem aqui.",
    laggingTitle: "Clubes atrasados",
    lagReason: { missingReport: "Sem relatório do mês", nonOperational: "Não operacional" },
    periodContextTitle: "Contexto do período"
  }
};
for (const [locale, keys] of Object.entries(home)) {
  editOperations(`messages/${locale}.json`, (ops) => Object.assign(ops.home, keys));
}
'
node scripts/generate-messages-types.mjs
```

- [ ] **Step 2: Verificar**

Run: `git diff --stat messages src/i18n/messages.d.ts` → solo esos 5 archivos.
Run: `rg -n '—' messages/es.json | rg 'summary|gapTable|dispatch|lagging|periodContext' ; echo none` → `none` (sin guion largo en las claves nuevas).

- [ ] **Step 3: Commit**

```bash
git add messages src/i18n/messages.d.ts
git commit -m "feat(i18n): add dashboard home copy for supervise and dispatch modes"
```

---

### Task 5: `OperationsWorkQueue` (test primero)

**Files:**
- Modify (reescritura completa): `src/components/dashboard/operations-work-queue.tsx`
- Modify: `src/components/dashboard/operations-dashboard.test.tsx`

- [ ] **Step 1: Test**

Al final de `operations-dashboard.test.tsx` agregar (y sumar `import { OperationsWorkQueue } from "@/components/dashboard/operations-work-queue";` a los imports):

```tsx
const QUEUE_LABELS = {
  roles: "Asignaciones pendientes",
  transfers: "Traslados pendientes",
  classes: "Validaciones de clase",
  honors: "Revisiones de especialidades",
  folders: "Carpetas pendientes de Unión",
};

describe("OperationsWorkQueue", () => {
  it("lists each queue with its count and a review link", () => {
    render(
      <OperationsWorkQueue
        headingId="queue"
        title="Por atender"
        reviewLabel="Revisar"
        labels={QUEUE_LABELS}
        items={[
          { id: "classes", count: 12, href: "/dashboard/clubs/validations?tab=sections" },
          { id: "transfers", count: 1, href: "/dashboard/requests/transfers" },
        ]}
      />,
    );

    expect(screen.getByRole("heading", { level: 2, name: "Por atender" })).toBeInTheDocument();
    const link = screen.getByRole("link", { name: /Validaciones de clase/ });
    expect(link).toHaveAttribute("href", "/dashboard/clubs/validations?tab=sections");
    expect(link).toHaveTextContent("12");
    expect(link).toHaveTextContent("Revisar");
  });

  it("shows the empty state when given one and nothing is pending", () => {
    render(
      <OperationsWorkQueue
        headingId="queue"
        title="Por atender"
        reviewLabel="Revisar"
        labels={QUEUE_LABELS}
        items={[]}
        empty={{ title: "Nada pendiente en tu alcance", description: "Aparece aquí." }}
      />,
    );

    expect(screen.getByText("Nada pendiente en tu alcance")).toBeInTheDocument();
  });

  it("renders nothing when empty and no empty state is given", () => {
    const { container } = render(
      <OperationsWorkQueue
        headingId="queue"
        title="Pendientes"
        reviewLabel="Revisar"
        labels={QUEUE_LABELS}
        items={[]}
      />,
    );

    expect(container).toBeEmptyDOMElement();
  });
});
```

- [ ] **Step 2: Verificar que falla**

Run: `pnpm exec vitest run src/components/dashboard/operations-dashboard.test.tsx -t OperationsWorkQueue`
Expected: FAIL (props nuevas no existen; hoy renderiza una `Card` con `CardTitle`, no `h2`).

- [ ] **Step 3: Reescribir `operations-work-queue.tsx` completo**

```tsx
import Link from "next/link";
import { ArrowRight, ArrowUpDown, Award, BookOpen, Inbox, Trophy, UserPlus } from "lucide-react";
import { EmptyState } from "@/components/shared/empty-state";
import type { OperationsQueueId, OperationsWorkItem } from "@/lib/dashboard/operations-home";

const QUEUE_ICONS: Record<OperationsQueueId, typeof Inbox> = {
  roles: UserPlus,
  transfers: ArrowUpDown,
  classes: BookOpen,
  honors: Award,
  folders: Trophy,
};

export interface OperationsWorkQueueProps {
  headingId: string;
  title: string;
  reviewLabel: string;
  labels: Record<OperationsQueueId, string>;
  /** Already filtered to queues with work that the user can open. */
  items: OperationsWorkItem[];
  /** When set, an empty queue shows this state; otherwise the block is omitted. */
  empty?: { title: string; description: string };
}

export function OperationsWorkQueue({
  headingId,
  title,
  reviewLabel,
  labels,
  items,
  empty,
}: OperationsWorkQueueProps) {
  if (items.length === 0 && !empty) {
    return null;
  }

  return (
    <section aria-labelledby={headingId} className="space-y-3">
      <h2 id={headingId} className="font-semibold text-base tracking-tight">
        {title}
      </h2>
      {items.length === 0 && empty ? (
        <EmptyState icon={Inbox} title={empty.title} description={empty.description} />
      ) : (
        <ul className="divide-y divide-border rounded-xl border bg-card">
          {items.map((item) => {
            const Icon = QUEUE_ICONS[item.id];
            return (
              <li key={item.id}>
                <Link
                  href={item.href}
                  className="flex items-center justify-between gap-3 px-4 py-3 transition-colors duration-150 hover:bg-muted/60 motion-reduce:transition-none"
                >
                  <span className="flex min-w-0 items-center gap-3">
                    <Icon className="size-4 shrink-0 text-muted-foreground" aria-hidden />
                    <span className="truncate font-medium text-sm">{labels[item.id]}</span>
                  </span>
                  <span className="flex shrink-0 items-center gap-3 text-sm">
                    <span className="font-semibold tabular-nums">{item.count}</span>
                    <span className="inline-flex items-center gap-1 text-primary">
                      {reviewLabel}
                      <ArrowRight className="size-3.5" aria-hidden />
                    </span>
                  </span>
                </Link>
              </li>
            );
          })}
        </ul>
      )}
    </section>
  );
}
```

- [ ] **Step 4: Verificar que pasa**

Run: `pnpm exec vitest run src/components/dashboard/operations-dashboard.test.tsx -t OperationsWorkQueue`
Expected: PASS, 3 tests.

- [ ] **Step 5: Commit**

```bash
git add src/components/dashboard/operations-work-queue.tsx src/components/dashboard/operations-dashboard.test.tsx
git commit -m "feat(dashboard): turn the work queue into actionable rows"
```

(`operations-dashboard-view.tsx` sigue usando las props viejas: `typecheck` falla ahí hasta la tarea 9. Es esperado.)

---

### Task 6: `OperationsGapTable` (test primero)

**Files:**
- Create: `src/components/dashboard/operations-gap-table.tsx` (confirmar antes con `fd -t f operations-gap-table src` que no existe)
- Modify: `src/components/dashboard/operations-dashboard.test.tsx`

- [ ] **Step 1: Test** (agregar import `import { OperationsGapTable } from "@/components/dashboard/operations-gap-table";`)

```tsx
describe("OperationsGapTable", () => {
  const columns = {
    name: "Nombre",
    reports: "Informes",
    nonOperational: "No operativos",
    pending: "Pendientes",
  };

  it("mutes rows without a gap and flags missing reports", () => {
    render(
      <OperationsGapTable
        headingId="gap"
        title="Campos locales"
        description="Primero los que tienen brecha."
        columns={columns}
        empty={{ title: "Sin territorios", description: "Nada aquí." }}
        rows={[
          {
            key: "local_field-1",
            name: "Campo A",
            href: "/dashboard?local_field_id=1",
            reports: "40%",
            missingLabel: "faltan 6",
            nonOperational: "2",
            pending: "5",
            hasGap: true,
          },
          {
            key: "local_field-2",
            name: "Campo C",
            href: "/dashboard?local_field_id=2",
            reports: "100%",
            nonOperational: "0",
            pending: "0",
            hasGap: false,
          },
        ]}
      />,
    );

    expect(screen.getByRole("heading", { level: 2, name: "Campos locales" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Campo A" })).toHaveAttribute(
      "href",
      "/dashboard?local_field_id=1",
    );
    expect(screen.getByText("faltan 6")).toHaveClass("text-destructive");
    expect(screen.getByRole("link", { name: "Campo C" }).closest("tr")).toHaveClass(
      "text-muted-foreground",
    );
    expect(screen.getByRole("link", { name: "Campo A" }).closest("tr")).not.toHaveClass(
      "text-muted-foreground",
    );
  });

  it("shows the empty state without rows", () => {
    render(
      <OperationsGapTable
        headingId="gap"
        title="Clubes"
        description="x"
        columns={columns}
        empty={{ title: "Sin territorios", description: "Nada aquí." }}
        rows={[]}
      />,
    );

    expect(screen.getByText("Sin territorios")).toBeInTheDocument();
    expect(screen.queryByRole("table")).not.toBeInTheDocument();
  });
});
```

- [ ] **Step 2: Verificar que falla**

Run: `pnpm exec vitest run src/components/dashboard/operations-dashboard.test.tsx -t OperationsGapTable`
Expected: FAIL (módulo no existe).

- [ ] **Step 3: Crear `src/components/dashboard/operations-gap-table.tsx`**

```tsx
import Link from "next/link";
import { MapPin } from "lucide-react";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { EmptyState } from "@/components/shared/empty-state";
import { cn } from "@/lib/utils";

export type OperationsGapRow = {
  key: string;
  name: string;
  href: string;
  /** Coverage already formatted ("40%") or "—" without a closed month. */
  reports: string;
  /** "faltan 6" when sections are missing; absent otherwise. */
  missingLabel?: string;
  nonOperational: string;
  pending: string;
  hasGap: boolean;
};

export interface OperationsGapTableProps {
  headingId: string;
  title: string;
  description: string;
  columns: { name: string; reports: string; nonOperational: string; pending: string };
  empty: { title: string; description: string };
  /** Already ranked by gap. */
  rows: OperationsGapRow[];
}

export function OperationsGapTable({
  headingId,
  title,
  description,
  columns,
  empty,
  rows,
}: OperationsGapTableProps) {
  return (
    <section aria-labelledby={headingId} className="space-y-3">
      <div className="space-y-1">
        <h2 id={headingId} className="font-semibold text-base tracking-tight">
          {title}
        </h2>
        <p className="text-muted-foreground text-sm">{description}</p>
      </div>
      {rows.length === 0 ? (
        <EmptyState icon={MapPin} title={empty.title} description={empty.description} />
      ) : (
        <div className="overflow-x-auto rounded-xl border bg-card">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="text-xs font-medium text-muted-foreground">
                  {columns.name}
                </TableHead>
                <TableHead className="text-xs font-medium text-muted-foreground">
                  {columns.reports}
                </TableHead>
                <TableHead className="text-right text-xs font-medium text-muted-foreground">
                  {columns.nonOperational}
                </TableHead>
                <TableHead className="text-right text-xs font-medium text-muted-foreground">
                  {columns.pending}
                </TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((row) => (
                <TableRow key={row.key} className={cn(!row.hasGap && "text-muted-foreground")}>
                  <TableCell>
                    <Link
                      href={row.href}
                      className={cn("font-medium hover:underline", row.hasGap && "text-primary")}
                    >
                      {row.name}
                    </Link>
                  </TableCell>
                  <TableCell className="tabular-nums">
                    {row.reports}
                    {row.missingLabel ? (
                      <>
                        <span className="text-muted-foreground"> · </span>
                        <span className="text-destructive">{row.missingLabel}</span>
                      </>
                    ) : null}
                  </TableCell>
                  <TableCell className="text-right tabular-nums">{row.nonOperational}</TableCell>
                  <TableCell className="text-right tabular-nums">{row.pending}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}
    </section>
  );
}
```

- [ ] **Step 4: Verificar que pasa**

Run: `pnpm exec vitest run src/components/dashboard/operations-dashboard.test.tsx -t OperationsGapTable`
Expected: PASS, 2 tests.

- [ ] **Step 5: Commit**

```bash
git add src/components/dashboard/operations-gap-table.tsx src/components/dashboard/operations-dashboard.test.tsx
git commit -m "feat(dashboard): add the gap-ranked territory table"
```

---

### Task 7: Contexto del periodo y nota de calidad de datos

**Files:**
- Create: `src/components/dashboard/operations-period-context.tsx` (confirmar que no existe)
- Modify (reescritura de la función de render): `src/components/dashboard/operations-data-quality.tsx`

Sin test propio: se cubren en los tests de render de la tarea 8.

- [ ] **Step 1: Crear `operations-period-context.tsx`**

```tsx
import Link from "next/link";
import type { ReactNode } from "react";
import { Card, CardContent } from "@/components/ui/card";
import { cn } from "@/lib/utils";

type StatRow = { label: string; value: string; tone?: "default" | "warning" };

type ContextGroup = {
  title: string;
  description?: string;
  rows?: StatRow[];
  action?: { href: string; label: string };
  children?: ReactNode;
};

export interface OperationsPeriodContextProps {
  headingId: string;
  title: string;
  groups: ContextGroup[];
}

function StatRowView({ label, value, tone = "default" }: StatRow) {
  return (
    <div className="flex items-center justify-between gap-3 text-sm">
      <span className="min-w-0 truncate text-muted-foreground">{label}</span>
      <span
        className={cn("shrink-0 font-medium tabular-nums", tone === "warning" && "text-destructive")}
      >
        {value}
      </span>
    </div>
  );
}

export function OperationsPeriodContext({ headingId, title, groups }: OperationsPeriodContextProps) {
  return (
    <section aria-labelledby={headingId} className="space-y-3">
      <h2 id={headingId} className="font-semibold text-base tracking-tight">
        {title}
      </h2>
      <Card size="sm">
        <CardContent className="grid gap-6 xl:grid-cols-3">
          {groups.map((group) => (
            <div key={group.title} className="space-y-3">
              <div className="space-y-1">
                <h3 className="font-medium text-sm">{group.title}</h3>
                {group.description ? (
                  <p className="text-muted-foreground text-xs">{group.description}</p>
                ) : null}
              </div>
              {group.rows?.map((row) => <StatRowView key={row.label} {...row} />)}
              {group.children}
              {group.action ? (
                <Link
                  href={group.action.href}
                  className="inline-block text-primary text-sm hover:underline"
                >
                  {group.action.label}
                </Link>
              ) : null}
            </div>
          ))}
        </CardContent>
      </Card>
    </section>
  );
}
```

- [ ] **Step 2: Nota al pie en `operations-data-quality.tsx`**

Reemplazar solo el `return (...)` de `OperationsDataQuality` (desde `return (` hasta el `);` final de la función) por:

```tsx
  return (
    <details className="text-muted-foreground text-xs">
      <summary className="inline-flex cursor-pointer list-none items-center gap-1.5 marker:content-none [&::-webkit-details-marker]:hidden">
        <Info className="size-3.5" aria-hidden />
        <span>{title}</span>
      </summary>
      <p className="mt-2">{description}</p>
      <ul className="mt-2 space-y-1.5">
        {entries.map((entry) => (
          <li key={entry.metric} className="flex flex-wrap items-center gap-2">
            <span className="font-medium text-foreground">{entry.metric}</span>
            <Badge variant={qualityBadgeVariant(entry.status)}>{statusLabels[entry.status]}</Badge>
            <span>{entry.note}</span>
          </li>
        ))}
      </ul>
    </details>
  );
```

- [ ] **Step 3: Verificar**

Run: `pnpm exec eslint src/components/dashboard/operations-period-context.tsx src/components/dashboard/operations-data-quality.tsx` → exit 0.

- [ ] **Step 4: Commit**

```bash
git add src/components/dashboard/operations-period-context.tsx src/components/dashboard/operations-data-quality.tsx
git commit -m "feat(dashboard): add compact period context and data quality footnote"
```

---

### Task 8: `SupervisionHome` y `DispatchHome` (test primero)

**Files:**
- Create: `src/components/dashboard/operations-home-supervision.tsx`, `src/components/dashboard/operations-home-dispatch.tsx` (confirmar que no existen)
- Modify: `src/components/dashboard/operations-dashboard.test.tsx`

- [ ] **Step 1: Tests** (agregar imports de `SupervisionHome` y `DispatchHome`)

```tsx
const gapTableProps = {
  headingId: "gap",
  title: "Campos locales",
  description: "Primero los que tienen brecha.",
  columns: { name: "Nombre", reports: "Informes", nonOperational: "No operativos", pending: "Pendientes" },
  empty: { title: "Sin territorios", description: "Nada aquí." },
  rows: [
    {
      key: "local_field-1",
      name: "Campo A",
      href: "/dashboard?local_field_id=1",
      reports: "40%",
      missingLabel: "faltan 6",
      nonOperational: "2",
      pending: "5",
      hasGap: true,
    },
  ],
};

const contextProps = {
  headingId: "context",
  title: "Contexto del periodo",
  groups: [{ title: "Actividades", rows: [{ label: "Registradas", value: "8" }] }],
};

const dataQualityProps = {
  title: "Calidad de datos",
  description: "Notas.",
  entries: [],
  statusLabels: {
    exact: "Exacto",
    current_affiliation: "Afiliación actual",
    unavailable: "No disponible",
    not_applicable: "No aplica",
  },
};

describe("SupervisionHome", () => {
  it("leads with the gap table and hides empty pending queues", () => {
    render(
      <SupervisionHome
        summary="9 de 12 campos locales entregaron el informe del mes."
        gapTable={gapTableProps}
        pending={{ headingId: "pending", title: "Pendientes", reviewLabel: "Revisar", labels: QUEUE_LABELS, items: [] }}
        context={contextProps}
        dataQuality={dataQualityProps}
      />,
    );

    const headings = screen.getAllByRole("heading", { level: 2 });
    expect(headings[0]).toHaveTextContent("Campos locales");
    expect(screen.queryByRole("heading", { level: 2, name: "Pendientes" })).not.toBeInTheDocument();
    expect(screen.getByText(/9 de 12 campos locales/)).toBeInTheDocument();
  });

  it("shows pending queues below the table when there are any", () => {
    render(
      <SupervisionHome
        summary=""
        gapTable={gapTableProps}
        pending={{
          headingId: "pending",
          title: "Pendientes",
          reviewLabel: "Revisar",
          labels: QUEUE_LABELS,
          items: [{ id: "folders", count: 7, href: "/dashboard/annual-folders/evaluate" }],
        }}
        context={contextProps}
        dataQuality={dataQualityProps}
      />,
    );

    const names = screen.getAllByRole("heading", { level: 2 }).map((h) => h.textContent);
    expect(names.slice(0, 2)).toEqual(["Campos locales", "Pendientes"]);
  });
});

describe("DispatchHome", () => {
  it("leads with the work queue and shows its empty state", () => {
    render(
      <DispatchHome
        queue={{
          headingId: "queue",
          title: "Por atender",
          reviewLabel: "Revisar",
          labels: QUEUE_LABELS,
          items: [],
          empty: { title: "Nada pendiente en tu alcance", description: "Aparece aquí." },
        }}
        lagging={{ headingId: "lagging", title: "Clubes que van atrás", rows: [] }}
        summary="18 de 20 secciones entregaron el informe del mes."
        context={contextProps}
        dataQuality={dataQualityProps}
      />,
    );

    expect(screen.getAllByRole("heading", { level: 2 })[0]).toHaveTextContent("Por atender");
    expect(screen.getByText("Nada pendiente en tu alcance")).toBeInTheDocument();
    expect(
      screen.queryByRole("heading", { level: 2, name: "Clubes que van atrás" }),
    ).not.toBeInTheDocument();
  });

  it("lists lagging clubs with their reasons", () => {
    render(
      <DispatchHome
        queue={{
          headingId: "queue",
          title: "Por atender",
          reviewLabel: "Revisar",
          labels: QUEUE_LABELS,
          items: [{ id: "classes", count: 12, href: "/dashboard/clubs/validations?tab=sections" }],
          empty: { title: "Nada pendiente", description: "x" },
        }}
        lagging={{
          headingId: "lagging",
          title: "Clubes que van atrás",
          rows: [
            {
              key: "club-9",
              name: "Club Águilas",
              href: "/dashboard/clubs/9",
              reasons: [{ label: "Sin informe del mes", tone: "danger" }],
            },
          ],
        }}
        summary=""
        context={contextProps}
        dataQuality={dataQualityProps}
      />,
    );

    expect(screen.getByRole("link", { name: "Club Águilas" })).toHaveAttribute("href", "/dashboard/clubs/9");
    expect(screen.getByText("Sin informe del mes")).toHaveClass("text-destructive");
  });
});
```

- [ ] **Step 2: Verificar que falla**

Run: `pnpm exec vitest run src/components/dashboard/operations-dashboard.test.tsx -t "SupervisionHome|DispatchHome"`
Expected: FAIL (módulos no existen).

- [ ] **Step 3: Crear `operations-home-supervision.tsx`**

```tsx
import { OperationsDataQuality } from "@/components/dashboard/operations-data-quality";
import {
  OperationsGapTable,
  type OperationsGapTableProps,
} from "@/components/dashboard/operations-gap-table";
import {
  OperationsPeriodContext,
  type OperationsPeriodContextProps,
} from "@/components/dashboard/operations-period-context";
import {
  OperationsWorkQueue,
  type OperationsWorkQueueProps,
} from "@/components/dashboard/operations-work-queue";
import type { ComponentProps } from "react";

export interface SupervisionHomeProps {
  /** Translated summary sentences joined with a space; may be empty. */
  summary: string;
  gapTable: OperationsGapTableProps;
  /** Rendered only when it has items (no empty state in supervision). */
  pending: Omit<OperationsWorkQueueProps, "empty">;
  context: OperationsPeriodContextProps;
  dataQuality: ComponentProps<typeof OperationsDataQuality>;
}

export function SupervisionHome({
  summary,
  gapTable,
  pending,
  context,
  dataQuality,
}: SupervisionHomeProps) {
  return (
    <div className="flex flex-col gap-8">
      {summary ? <p className="text-sm">{summary}</p> : null}
      <OperationsGapTable {...gapTable} />
      <OperationsWorkQueue {...pending} />
      <OperationsPeriodContext {...context} />
      <OperationsDataQuality {...dataQuality} />
    </div>
  );
}
```

- [ ] **Step 4: Crear `operations-home-dispatch.tsx`**

```tsx
import Link from "next/link";
import type { ComponentProps } from "react";
import { OperationsDataQuality } from "@/components/dashboard/operations-data-quality";
import {
  OperationsPeriodContext,
  type OperationsPeriodContextProps,
} from "@/components/dashboard/operations-period-context";
import {
  OperationsWorkQueue,
  type OperationsWorkQueueProps,
} from "@/components/dashboard/operations-work-queue";
import { cn } from "@/lib/utils";

export type LaggingClubRow = {
  key: string;
  name: string;
  href: string;
  reasons: Array<{ label: string; tone: "danger" | "muted" }>;
};

export interface DispatchHomeProps {
  /** Must include `empty`: dispatch always shows the queue block. */
  queue: OperationsWorkQueueProps & { empty: NonNullable<OperationsWorkQueueProps["empty"]> };
  lagging: { headingId: string; title: string; rows: LaggingClubRow[] };
  summary: string;
  context: OperationsPeriodContextProps;
  dataQuality: ComponentProps<typeof OperationsDataQuality>;
}

export function DispatchHome({ queue, lagging, summary, context, dataQuality }: DispatchHomeProps) {
  return (
    <div className="flex flex-col gap-8">
      <OperationsWorkQueue {...queue} />
      {lagging.rows.length > 0 ? (
        <section aria-labelledby={lagging.headingId} className="space-y-3">
          <h2 id={lagging.headingId} className="font-semibold text-base tracking-tight">
            {lagging.title}
          </h2>
          <ul className="divide-y divide-border rounded-xl border bg-card">
            {lagging.rows.map((row) => (
              <li key={row.key} className="flex items-center justify-between gap-3 px-4 py-3 text-sm">
                <Link href={row.href} className="font-medium text-primary hover:underline">
                  {row.name}
                </Link>
                <span className="flex flex-wrap justify-end gap-x-3">
                  {row.reasons.map((reason) => (
                    <span
                      key={reason.label}
                      className={cn(
                        reason.tone === "danger" ? "text-destructive" : "text-muted-foreground",
                      )}
                    >
                      {reason.label}
                    </span>
                  ))}
                </span>
              </li>
            ))}
          </ul>
        </section>
      ) : null}
      {summary ? <p className="text-sm">{summary}</p> : null}
      <OperationsPeriodContext {...context} />
      <OperationsDataQuality {...dataQuality} />
    </div>
  );
}
```

- [ ] **Step 5: Verificar que pasa**

Run: `pnpm exec vitest run src/components/dashboard/operations-dashboard.test.tsx -t "SupervisionHome|DispatchHome"`
Expected: PASS, 4 tests.

- [ ] **Step 6: Commit**

```bash
git add src/components/dashboard/operations-home-supervision.tsx src/components/dashboard/operations-home-dispatch.tsx src/components/dashboard/operations-dashboard.test.tsx
git commit -m "feat(dashboard): add supervise and dispatch home views"
```

---

### Task 9: Container y skeleton

**Files:**
- Modify (reescritura completa): `src/components/dashboard/operations-dashboard-view.tsx`
- Modify (reescritura completa): `src/app/(dashboard)/dashboard/loading.tsx`

- [ ] **Step 1: Reescribir `operations-dashboard-view.tsx`**

```tsx
import { getTranslations } from "next-intl/server";
import { OperationsDashboardChrome } from "@/components/dashboard/operations-dashboard-chrome";
import { ClassEnrollmentsChart } from "@/components/dashboard/class-enrollments-chart";
import { SupervisionHome } from "@/components/dashboard/operations-home-supervision";
import { DispatchHome } from "@/components/dashboard/operations-home-dispatch";
import type { OperationsGapRow } from "@/components/dashboard/operations-gap-table";
import type { OperationsPeriodContextProps } from "@/components/dashboard/operations-period-context";
import {
  buildDashboardHref,
  buildDrillDownQuery,
  formatMetricCount,
  formatMetricPercent,
  type ChildLevel,
  type OperationsDashboardChild,
  type OperationsDashboardData,
  type OperationsDashboardQuery,
} from "@/lib/api/operations-dashboard";
import {
  dispatchSummary,
  firstAccessibleHref,
  laggingClubs,
  rankChildrenByGap,
  resolveHomeMode,
  supervisionSummary,
  visibleWorkQueue,
  type SummaryMessage,
} from "@/lib/dashboard/operations-home";
import type { AuthUser } from "@/lib/auth/types";
import { getFormatNumber } from "@/lib/format-locale";

interface OperationsDashboardViewProps {
  data: OperationsDashboardData;
  query: OperationsDashboardQuery;
  user: AuthUser;
}

const CHILD_LEVEL_BY_SCOPE: Record<OperationsDashboardData["meta"]["scope"]["level"], ChildLevel> = {
  all: "division",
  division: "union",
  union: "local_field",
  local_field: "club",
  coordinator: "club",
};

function childHref(child: OperationsDashboardChild, query: OperationsDashboardQuery): string {
  return child.level === "club"
    ? `/dashboard/clubs/${child.id}`
    : buildDashboardHref(buildDrillDownQuery(child, query));
}

export async function OperationsDashboardView({ data, query, user }: OperationsDashboardViewProps) {
  const t = await getTranslations("dashboardHub.operations");
  const tHome = await getTranslations("dashboardHub.operations.home");
  const formatNumber = await getFormatNumber();
  const { meta, summary, children, data_quality } = data;
  const hasReportingMonth = meta.period.reporting_month !== null;
  const fmt = (value: number | null | undefined) => formatMetricCount(value, formatNumber);
  const pct = (value: number | null | undefined) => formatMetricPercent(value, formatNumber);
  const mode = resolveHomeMode(meta.scope, query);
  const childLevel = CHILD_LEVEL_BY_SCOPE[meta.scope.level];

  const sentence = (messages: SummaryMessage[]) =>
    messages.map((message) => tHome(`summary.${message.key}`, message.values)).join(" ");

  const queueLabels = {
    roles: t("attention.roleAssignments"),
    transfers: t("attention.transfers"),
    classes: t("attention.classValidations"),
    honors: t("attention.honorsReview"),
    folders: t("attention.annualFolders"),
  };
  const queueItems = visibleWorkQueue(summary, user);

  const honorsUnavailable = summary.honors.attribution === "unavailable";
  const honorsHref = firstAccessibleHref(user, ["/dashboard/clubs/validations?tab=honors"]);
  const activitiesHref = firstAccessibleHref(user, ["/dashboard/clubs/activities"]);
  const context: OperationsPeriodContextProps = {
    headingId: "operations-context",
    title: tHome("periodContextTitle"),
    groups: [
      {
        title: t("formation.title"),
        description: t("formation.description", {
          enrollments: fmt(summary.classes.total_enrollments),
          people: fmt(summary.classes.distinct_people),
        }),
        children: (
          <ClassEnrollmentsChart items={summary.classes.by_class} compact showTable={false} />
        ),
      },
      {
        title: t("honors.title"),
        description: honorsUnavailable
          ? t("honors.attribution.unavailable")
          : t("honors.attribution.current_affiliation"),
        rows: honorsUnavailable
          ? []
          : [
              { label: t("honors.inProgress"), value: fmt(summary.honors.in_progress) },
              {
                label: t("honors.pendingReview"),
                value: fmt(summary.honors.pending_review),
                tone: (summary.honors.pending_review ?? 0) > 0 ? "warning" : "default",
              },
              { label: t("honors.approved"), value: fmt(summary.honors.approved) },
            ],
        action:
          honorsHref && !honorsUnavailable
            ? { href: honorsHref, label: tHome("honorsAction") }
            : undefined,
      },
      {
        title: t("activities.title"),
        description: t("activities.description"),
        rows: [
          { label: t("activities.registered"), value: fmt(summary.activities.registered) },
          { label: t("activities.jointRegistered"), value: fmt(summary.activities.joint_registered) },
          {
            label: t("activities.participatingSections"),
            value: fmt(summary.activities.distinct_participating_sections),
          },
        ],
        action: activitiesHref ? { href: activitiesHref, label: tHome("activitiesAction") } : undefined,
      },
    ],
  };

  const dataQuality = {
    title: t("dataQuality.title"),
    description: t("dataQuality.description"),
    entries: data_quality,
    statusLabels: {
      exact: t("dataQuality.status.exact"),
      current_affiliation: t("dataQuality.status.current_affiliation"),
      unavailable: t("dataQuality.status.unavailable"),
      not_applicable: t("dataQuality.status.not_applicable"),
    },
  };

  return (
    <div className="@container/main flex flex-col gap-6">
      <OperationsDashboardChrome
        data={data}
        query={query}
        title={tHome("title")}
        description={tHome("description")}
      />

      {mode === "dispatch" ? (
        <DispatchHome
          queue={{
            headingId: "operations-queue",
            title: tHome("dispatchTitle"),
            reviewLabel: tHome("review"),
            labels: queueLabels,
            items: queueItems,
            empty: {
              title: tHome("dispatchEmptyTitle"),
              description: tHome("dispatchEmptyDescription"),
            },
          }}
          lagging={{
            headingId: "operations-lagging",
            title: tHome("laggingTitle"),
            rows: laggingClubs(children, hasReportingMonth).map(({ child, reasons }) => ({
              key: `${child.level}-${child.id}`,
              name: child.name,
              href: childHref(child, query),
              reasons: reasons.map((reason) => ({
                label: tHome(`lagReason.${reason}`),
                tone: reason === "missingReport" ? ("danger" as const) : ("muted" as const),
              })),
            })),
          }}
          summary={sentence(dispatchSummary(summary, hasReportingMonth))}
          context={context}
          dataQuality={dataQuality}
        />
      ) : (
        <SupervisionHome
          summary={sentence(supervisionSummary(children, childLevel, summary, hasReportingMonth))}
          gapTable={{
            headingId: "operations-gap",
            title: tHome("gapTable.title", { level: childLevel }),
            description: tHome("gapTable.description"),
            columns: {
              name: tHome("gapTable.columns.name"),
              reports: tHome("gapTable.columns.reports"),
              nonOperational: tHome("gapTable.columns.nonOperational"),
              pending: tHome("gapTable.columns.pending"),
            },
            empty: {
              title: tHome("gapTable.emptyTitle"),
              description: tHome("gapTable.emptyDescription"),
            },
            rows: rankChildrenByGap(children, hasReportingMonth).map(
              ({ child, gap }): OperationsGapRow => ({
                key: `${child.level}-${child.id}`,
                name: child.name,
                href: childHref(child, query),
                reports: hasReportingMonth ? pct(child.monthly_reports.coverage_pct) : "—",
                missingLabel:
                  gap.missingSections > 0
                    ? tHome("gapTable.missingCount", { count: fmt(gap.missingSections) })
                    : undefined,
                nonOperational: fmt(gap.nonOperationalClubs),
                pending: fmt(gap.pendingTotal),
                hasGap: gap.hasGap,
              }),
            ),
          }}
          pending={{
            headingId: "operations-pending",
            title: tHome("pendingTitle"),
            reviewLabel: tHome("review"),
            labels: queueLabels,
            items: queueItems,
          }}
          context={context}
          dataQuality={dataQuality}
        />
      )}
    </div>
  );
}
```

Notas:
- `tHome(\`summary.${message.key}\`, message.values)`: next-intl en modo estricto acepta la unión de literales. Si `typecheck` rechaza la llamada por el tipo de `values`, reemplazar `sentence` por un `switch (message.key)` con una llamada `tHome("summary.childrenReported", message.values)` por caso, y reportarlo.
- `"—"` es un dato vacío de la tabla, no texto de UI (la regla del guion largo aplica a copy).

- [ ] **Step 2: Reescribir `loading.tsx`**

```tsx
import { Skeleton } from "@/components/ui/skeleton";

export default function DashboardLoading() {
  return (
    <div className="@container/main flex flex-col gap-6">
      <div className="space-y-3">
        <div className="space-y-2">
          <Skeleton className="h-8 w-32" />
          <Skeleton className="h-4 w-96 max-w-full" />
        </div>
        <div className="flex flex-wrap gap-2">
          <Skeleton className="h-5 w-36" />
          <Skeleton className="h-5 w-48" />
          <Skeleton className="h-5 w-40" />
        </div>
      </div>

      <div className="flex flex-col gap-8">
        <Skeleton className="h-4 w-80 max-w-full" />
        <div className="space-y-3">
          <Skeleton className="h-5 w-40" />
          <Skeleton className="h-56 w-full rounded-xl" />
        </div>
        <div className="space-y-3">
          <Skeleton className="h-5 w-48" />
          <Skeleton className="h-40 w-full rounded-xl" />
        </div>
      </div>
    </div>
  );
}
```

- [ ] **Step 3: Verificar**

Run: `pnpm typecheck`
Expected: errores **solo** en `operations-shortcuts.tsx` (importa `OperationsShortcutId`). Se borra en la tarea 10.

Run: `pnpm exec vitest run 'src/app/(dashboard)/dashboard' src/components/dashboard src/lib/dashboard`
Expected: verde (`page.test.tsx` no cambia).

- [ ] **Step 4: Commit**

```bash
git add src/components/dashboard/operations-dashboard-view.tsx 'src/app/(dashboard)/dashboard/loading.tsx'
git commit -m "feat(dashboard): choose the home view by scope level"
```

---

### Task 10: Borrar huérfanos y claves viejas

**Files:** `operations-kpi-strip.tsx`, `operations-coverage-card.tsx`, `operations-shortcuts.tsx`, `operations-bento-tile.tsx`, `territory-breakdown-table.tsx`; `operations-dashboard.test.tsx`; `messages/*.json`; `messages.d.ts`.

- [ ] **Step 1: Confirmar huérfanos**

```bash
rg -l 'operations-kpi-strip|operations-coverage-card|operations-shortcuts|operations-bento-tile|territory-breakdown-table' src
```

Expected: solo los propios archivos y `operations-dashboard.test.tsx`. Cualquier otro → detenerse y reportar.

- [ ] **Step 2: Borrar archivos**

```bash
git rm -q src/components/dashboard/operations-kpi-strip.tsx src/components/dashboard/operations-coverage-card.tsx src/components/dashboard/operations-shortcuts.tsx src/components/dashboard/operations-bento-tile.tsx src/components/dashboard/territory-breakdown-table.tsx
```

- [ ] **Step 3: Limpiar el test**

En `operations-dashboard.test.tsx`:
- Borrar los imports de `OperationsBentoTile` y `OperationsKpiStrip`.
- Borrar los bloques `describe("OperationsBentoTile", ...)` y `describe("OperationsKpiStrip", ...)` completos.
- En `describe("dashboardHub.operations translations", ...)`, reemplazar:

```ts
    expect(messages.dashboardHub.operations.bento.groups.operation).toBeTruthy();
    expect(messages.dashboardHub.operations.bento.stats.operationalClubs).toBeTruthy();
```

por:

```ts
    expect(messages.dashboardHub.operations.home.summary.childrenReported).toBeTruthy();
    expect(messages.dashboardHub.operations.home.dispatchTitle).toBeTruthy();
    expect(messages.dashboardHub.operations.home.gapTable.columns.reports).toBeTruthy();
```

- [ ] **Step 4: Quitar claves sin uso**

```bash
node -e '
const editOperations = require("/tmp/sacdia-i18n/ops-block.cjs");
const deadHome = ["inboxTitle", "inboxDescription", "inboxEmptyTitle", "inboxEmptyDescription", "openQueue", "coverageTitle", "coverageAction", "shortcutsTitle", "shortcutsDescription", "shortcuts"];
for (const locale of ["es", "en", "fr", "pt-BR"]) {
  editOperations(`messages/${locale}.json`, (ops) => {
    for (const key of ["bento", "kpis", "territory"]) delete ops[key];
    for (const key of deadHome) delete ops.home[key];
  });
}
'
node scripts/generate-messages-types.mjs
```

- [ ] **Step 5: Verificar**

Run: `pnpm typecheck` → **sin errores**. Si falla por una clave borrada que algo usa, restaurarla en los 4 idiomas (desde `git show HEAD:messages/<locale>.json`), regenerar y reportar cuál era.
Run: `pnpm exec vitest run src/components/dashboard src/lib/dashboard 'src/app/(dashboard)/dashboard' src/lib/api/operations-dashboard.test.ts` → verde.
Run: `pnpm test` → solo la falla conocida de `screen-catalog`.
Run: `pnpm exec eslint src/components/dashboard src/lib/dashboard 'src/app/(dashboard)/dashboard'` → exit 0.
Run: `pnpm audit:design-system --strict > /dev/null; echo "exit:$?"` → `exit:0`.

- [ ] **Step 6: Commit**

```bash
git add -A src/components/dashboard messages src/i18n/messages.d.ts
git commit -m "refactor(dashboard): remove KPI strip, shortcuts, and the old territory table"
```

---

### Task 11: Revisión antislop y visual

- [ ] **Step 1: Checklist `antislop-ui`** sobre los archivos nuevos y la vista. Cada punto debe ser "sí":
  - Sin fila de KPIs; el bloque principal responde la decisión del modo.
  - Números reales del endpoint, sin valores inventados.
  - Estados vacío / sin mes cerrado / sin hijos con causa.
  - Sin `uppercase` + `tracking-*`, sin `rounded-3xl/4xl`, sin emoji, sin guion largo en copy.
  - Acento (`text-primary`) solo en acciones y en territorios con brecha.
  - Sin animaciones de entrada (MOTION 1).
  Reportar cualquier "no" con archivo:línea.

- [ ] **Step 2: Revisión visual (dueño)** con `pnpm dev`, light y dark:
  - Usuario de unión: modo supervisión, tabla ordenada por brecha, drill-down a un campo sigue en supervisión.
  - Director de campo o coordinador: modo despacho, cola primero.
  - Mes sin cerrar (si hay datos): frase y "—".

- [ ] **Step 3: Push y PRs** (solo cuando el dueño lo pida)

```bash
git push -u origin refactor/dashboard-remove-dead-views
git push -u origin feat/dashboard-home-by-scope
```

PR 1 contra `development`; PR 2 contra `refactor/dashboard-remove-dead-views`.
