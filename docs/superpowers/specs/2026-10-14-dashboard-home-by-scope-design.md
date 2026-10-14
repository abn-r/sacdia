# Inicio del admin por nivel de alcance — Diseño

- **Fecha**: 2026-10-14
- **Repo**: `sacdia-admin` (sin cambios de backend)
- **Subproyecto**: 3 de 3 (1 base visual ✅ → 2 alcance de coordinador ✅ → **3 rediseño del inicio**)
- **Estado**: aprobado para spec

## Contexto

`/dashboard` (`src/app/(dashboard)/dashboard/page.tsx` → `OperationsDashboardView`) apila 8 bloques con el mismo peso: chrome, cola de pendientes, fila de 4 KPIs, cobertura + formación, honores + actividades, tabla por territorio, accesos directos y calidad de datos. antislop lo marca como "Default Dashboard Shell" y "Stat Cards": la pantalla no dice cuál es su trabajo.

Dirección del DS (§0): `Dial: ENERGY 1 / RHYTHM 2 / MOTION 1`.

Los pastores siguen redirigidos a `/dashboard/investiture-requests`. Los coordinadores ya reciben su alcance (`level: "coordinator"`, hijos = clubes) desde sacdia-backend#499.

## Decisiones del dueño (2026-10-14)

1. El layout lo decide el **nivel de alcance** (`meta.scope.level`), no el nombre del rol.
2. `all` / `division` / `union` → **supervisión**. `local_field` / `coordinator` → **despacho**.
3. Con drill-down (hay filtro territorial en la URL) **siempre supervisión**, aunque el nivel sea `local_field`.
4. Bloques secundarios: formación, honores y actividades en una sección compacta "Contexto del periodo" al final; accesos directos eliminados (duplican el sidebar); calidad de datos como nota al pie.
5. Jerarquía aprobada con boceto (ver "Layout").

## Layout

### Supervisión

1. Chrome (sin cambios: alcance, periodo, "Volver a mi alcance").
2. **Frase resumen** (reemplaza la fila de KPIs).
3. **Tabla por brecha** (protagonista): territorios hijos ordenados por brecha; los que no tienen brecha van al final en `text-muted-foreground`.
4. **Pendientes** compactos (solo colas visibles, ver "Regla de colas"). Si no hay ninguna, el bloque no se muestra.
5. Contexto del periodo.
6. Nota de calidad de datos.

### Despacho

1. Chrome.
2. **Por atender** (protagonista): una fila por cola visible con icono, nombre, conteo y acción "Revisar". Sin colas visibles → estado vacío con causa ("Nada pendiente en tu alcance") y sin CTA.
3. **Clubes que van atrás**: solo hijos con brecha (sin informe del mes o no operativos), con el motivo como texto. Si ninguno, el bloque no se muestra.
4. Frase resumen.
5. Contexto del periodo.
6. Nota de calidad de datos.

## Lógica (funciones puras en `src/lib/dashboard/operations-home.ts`)

```ts
export type HomeMode = "supervise" | "dispatch";

export function resolveHomeMode(
  scope: OperationsDashboardScope,
  query: OperationsDashboardQuery,
): HomeMode;
// dispatch ⇔ (scope.level === "local_field" || scope.level === "coordinator")
//            && !query.division_id && !query.union_id && !query.local_field_id

export type ChildGap = {
  missingSections: number;     // monthly_reports.missing_sections (0 si no hay mes cerrado)
  nonOperationalClubs: number; // operations.non_operational_clubs
  pendingTotal: number;        // suma de queues (honors_review_pending null → 0)
  hasGap: boolean;             // missingSections > 0 || nonOperationalClubs > 0
};

export function childGap(child: OperationsDashboardChild, hasReportingMonth: boolean): ChildGap;

export function rankChildrenByGap(
  children: OperationsDashboardChild[],
  hasReportingMonth: boolean,
): Array<{ child: OperationsDashboardChild; gap: ChildGap }>;
// orden: hasGap desc, missingSections desc, nonOperationalClubs desc, pendingTotal desc, name asc

export function laggingClubs(
  children: OperationsDashboardChild[],
  hasReportingMonth: boolean,
): Array<{ child: OperationsDashboardChild; reasons: Array<"missingReport" | "nonOperational"> }>;
// solo hasGap, mismo orden que rankChildrenByGap
```

Frases resumen: funciones puras que devuelven **la clave i18n y sus valores**, no texto, para que el componente traduzca:

```ts
export type SummaryMessage = { key: string; values: Record<string, number | string> };

export function supervisionSummary(
  children: OperationsDashboardChild[],
  summary: DashboardMetrics,
  hasReportingMonth: boolean,
): SummaryMessage[];
// - con mes: { key: "childrenReported", values: { reported, total } }
//   reported = hijos con expected_sections > 0 y missing_sections === 0;
//   total = hijos con expected_sections > 0
// - sin mes: { key: "noClosedMonth" }
// - si summary.operations.non_operational_clubs > 0: { key: "nonOperationalClubs", values: { count } }

export function dispatchSummary(summary: DashboardMetrics, hasReportingMonth: boolean): SummaryMessage[];
// - con mes: { key: "sectionsReported", values: { submitted, expected } }
// - sin mes: { key: "noClosedMonth" }
// - si non_operational_clubs > 0: { key: "nonOperationalClubs", values: { count } }
```

### Regla de colas

`buildWorkQueue(summary)` (existente) ya filtra conteos `> 0` y ordena desc. Nueva función:

```ts
export function visibleWorkQueue(
  summary: DashboardMetrics,
  user: AuthUser,
): Array<OperationsWorkItem & { href: string }>;
// buildWorkQueue(summary) filtrado a filas con firstAccessibleHref(user, [item.href]) definido
```

Una fila aparece solo si su conteo es > 0 **y** el usuario puede abrir esa pantalla. Cierra el pendiente del subproyecto 2 (carpetas de unión para coordinadores) y aplica igual en los dos modos.

`OPERATIONS_SHORTCUTS`, `OperationsShortcutId` y `resolveAccessibleShortcuts` se eliminan.

## Componentes (container / presentational)

`OperationsDashboardView` (async, existente) queda como **container**: carga traducciones, llama `resolveHomeMode` y las funciones puras, resuelve hrefs y pasa props planas a una de dos vistas **síncronas** (testeables en Vitest):

| Archivo | Tipo | Contenido |
|---|---|---|
| `operations-dashboard-view.tsx` | async container | Decide el modo y arma props |
| `operations-home-supervision.tsx` (nuevo) | sync | Frase, `OperationsGapTable`, pendientes compactos, contexto, nota |
| `operations-home-dispatch.tsx` (nuevo) | sync | `OperationsWorkQueue`, clubes atrasados, frase, contexto, nota |
| `operations-gap-table.tsx` (nuevo) | sync | Tabla shadcn: nombre (link), informes (`%` + "faltan N"), no operativos, pendientes. Filas sin brecha en `text-muted-foreground`. Link: club → `/dashboard/clubs/{id}`; otro nivel → drill-down (`buildDrillDownQuery`) |
| `operations-period-context.tsx` (nuevo) | sync | Formación (`ClassEnrollmentsChart` compacto), honores, actividades en una sola `Card` con 3 columnas en `xl` |
| `operations-work-queue.tsx` | sync | Filas con borde (sin `Card` contenedor), acción "Revisar"; recibe solo filas visibles |
| `operations-data-quality.tsx` | sync | Nota al pie `text-xs text-muted-foreground`, sin `Card` |
| `operations-dashboard-chrome.tsx` | async | Sin cambios |
| `loading.tsx` | — | Skeleton: header, frase, bloque principal, contexto |

Reglas DS: radios por rol (§4.1), labels en sentence case, tokens semánticos, `StatusBadge` para estados, Hugeicons vía alias, `tabular-nums` en números. Sin animaciones de entrada (MOTION 1).

Estados:
- **Sin mes cerrado**: la tabla muestra "—" en informes; la frase dice que no hay mes cerrado; `childGap` cuenta `missingSections = 0`.
- **Sin hijos** (alcance vacío): `EmptyState` en el bloque principal de supervisión.
- **Error**: `OperationsDashboardError` sin cambios.

## Borrado

Sin importadores desde páginas (verificado 2026-10-14) o huérfanos tras el rediseño:

`dashboard-version-switch`, `dashboard-metric-progress`, `operations-dashboard-bento`, `operations-dashboard-bento-client`, `operations-bento-mini-charts`, `operations-bento-tile`, `operations-dashboard-v2-view`, `operations-dashboard-v2-charts`, `operations-kpi-strip`, `operations-coverage-card`, `operations-shortcuts`, `territory-breakdown-table` (≈1 950 líneas).

`/dashboard/v2/page.tsx` sigue (redirect). Los tests de `operations-dashboard.test.tsx` que cubren `OperationsBentoTile` y `OperationsKpiStrip` se eliminan; los de `ClassEnrollmentsChart` y traducciones se quedan. Claves i18n usadas solo por archivos borrados se eliminan de los 4 idiomas y de `src/i18n/messages.d.ts` (verificar cada clave con `rg` antes de borrar).

## i18n

Claves nuevas bajo `dashboardHub.operations.home` en `es`, `en`, `fr`, `pt-BR` y `messages.d.ts`. Sentence case, sin guion largo, español neutro. Mínimo:

`gapTableTitle`, `gapTableColumns.{name,reports,nonOperational,pending}`, `missingCount` ("faltan {count}"), `pendingTitle`, `review` ("Revisar"), `dispatchTitle` ("Por atender"), `dispatchEmptyTitle`, `dispatchEmptyDescription`, `laggingClubsTitle`, `lagReason.{missingReport,nonOperational}`, `periodContextTitle`, `summary.{childrenReported,sectionsReported,noClosedMonth,nonOperationalClubs}`.

## Pruebas (Vitest)

`src/lib/dashboard/operations-home.test.ts` (existente, se amplía):
- `resolveHomeMode`: cada nivel sin filtro; `local_field` con `local_field_id` → supervise; `coordinator` → dispatch.
- `childGap` / `rankChildrenByGap`: orden por los 4 criterios; sin mes → `missingSections = 0`; `honors_review_pending: null` cuenta 0.
- `laggingClubs`: solo con brecha, motivos correctos.
- `supervisionSummary` / `dispatchSummary`: con y sin mes; con y sin no operativos; hijos con `expected_sections = 0` fuera del total.
- `visibleWorkQueue`: excluye conteo 0 y pantallas sin acceso.

`src/components/dashboard/operations-dashboard.test.tsx` (se amplía): render de `SupervisionHome` y `DispatchHome` con `NextIntlClientProvider`:
- El bloque principal es el primer encabezado de sección.
- Colas sin acceso no aparecen; sin colas → estado vacío en despacho, sin bloque de pendientes en supervisión.
- Filas sin brecha llevan `text-muted-foreground`.

`page.test.tsx` sigue pasando (la página no cambia).

Comandos: `pnpm exec vitest run src/lib/dashboard src/components/dashboard`, `pnpm typecheck`, `pnpm audit:design-system --strict`, eslint sobre archivos tocados. Sin `pnpm build`.

## Entrega

Dos PRs encadenados sobre `development` (el total pasa de 400 líneas):

1. **`refactor/dashboard-remove-dead-views`**: borra los 7 archivos que ninguna página usa (`dashboard-version-switch`, `dashboard-metric-progress`, `operations-dashboard-bento`, `-bento-client`, `-bento-mini-charts`, `-v2-view`, `-v2-charts`) y sus claves i18n y tests. Solo eliminaciones; la vista actual no cambia.
2. **`feat/dashboard-home-by-scope`** (base: rama 1): funciones puras + tests, vistas nuevas, borra `kpi-strip`, `coverage-card`, `shortcuts`, `bento-tile`, `territory-breakdown-table`, i18n, `loading.tsx`.

Antes de entregar el PR 2: checklist de `antislop-ui` y revisión visual del dueño en light y dark con un usuario de cada modo (unión y campo local o coordinador).

## Fuera de alcance

- Cambios de backend o del contrato del endpoint.
- Vista de pastor.
- Gráficos nuevos (antislop: "Charts Without a Question"); `ClassEnrollmentsChart` se conserva solo dentro del contexto.
- Personalización del inicio por usuario.

## Riesgos

- **Sin mes cerrado** al inicio del año eclesiástico: la tabla pierde su criterio principal; queda ordenada por no operativos y pendientes. Aceptado.
- **Pérdida de accesos directos**: quien los usaba navega por el sidebar. Aceptado por el dueño.
- **Tamaño del PR 2**: alrededor de 400 líneas netas nuevas más borrados; si pasa del presupuesto, se divide en lógica + vistas.
