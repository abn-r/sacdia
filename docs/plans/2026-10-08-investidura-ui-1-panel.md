# Investidura por autorización — Pantallas del panel (Plan 1)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Que el pastor del distrito y la dirección del Campo autoricen investiduras desde el panel, y que el Campo configure ventana, porcentaje y pastores por distrito.

**Architecture:** Un módulo de API nuevo (`src/lib/api/investiture-requests.ts`), un mapa de errores por feature y cuatro superficies: listado de solicitudes del autorizador, detalle con decisión por persona, configuración del Campo (ventana + porcentaje) y pastores por distrito. Las páginas son Server Components que cargan con `apiRequest` y pasan datos a un `*ClientPage`; las mutaciones usan `apiRequestFromClient`. Permisos de pantalla por el screen-catalog. Una ruta raíz `/investiture-requests/[requestId]` redirige al detalle para que funcione el enlace del correo.

**Tech Stack:** Next.js 16 (App Router), React 19, shadcn/ui (new-york), Tailwind v4, react-hook-form + zod, next-intl, sonner, vitest + Testing Library.

**Depende de:** Plan 0 (`docs/plans/2026-10-08-investidura-ui-0-backend-soporte.md`) Tasks 3 y 4 mergeadas, y backend #465.

---

## Reglas para quien ejecute

- Leer `sacdia-admin/DESIGN-SYSTEM.md` antes de crear componentes. Reglas que aplican aquí: `PageHeader` en cada página; tablas con `DataTableShell`; estados con `StatusBadge` mediante un wrapper por feature; `EmptyState`, `Skeleton`, `EndpointErrorBanner`; destructivo o irreversible con `AlertDialog`; Dialog solo para ≤4 campos planos; formularios con react-hook-form + zod; textos con next-intl; tokens semánticos, nunca colores Tailwind fijos; iconos solo `lucide-react`; títulos Geist `font-semibold tracking-tight` (no `font-display`).
- TDD con vitest: prueba roja antes de cada componente o función. Patrón de mocks: `vi.mock("@/lib/api/investiture-requests", async (orig) => ({ ...(await orig()), fn: (...a) => mockFn(...a) }))`, `vi.mock("sonner")`, render dentro de `<NextIntlClientProvider locale="es" messages={messages}>` con `messages/es.json` (ver `src/components/certificate-bulk-imports/certificate-bulk-import-action-dialog.test.tsx`).
- Comandos: `pnpm test <ruta>`, `pnpm lint`, `pnpm typecheck`. Al tocar `messages/*.json`, regenerar tipos: `node scripts/generate-messages-types.mjs`. No correr `pnpm build` salvo que el usuario lo pida.
- Textos en los 4 idiomas (`es`, `en`, `pt-BR`, `fr`); `es` es la base. Los textos cerrados del plan funcional (§4) van literales en `es`.
- Commits por unidad de trabajo, Conventional Commits, sin atribuciones.

## Archivos

| Archivo | Responsabilidad |
| --- | --- |
| `src/lib/api/investiture-requests.ts` | Tipos y llamadas: listado del autorizador, detalle, resolución |
| `src/lib/api/investiture-field-config.ts` | Ventana, porcentaje, cupo y pastores por distrito, búsqueda de candidatos |
| `src/components/investiture-requests/investiture-request-errors.ts` | `code → mensaje` para todos los códigos del flujo |
| `src/components/investiture-requests/person-status-badge.tsx` | Wrapper de `StatusBadge` para `PENDING/INVESTED/REJECTED_*/REMOVED/CLOSED_YEAR` |
| `src/components/investiture-requests/requests-list-client-page.tsx` | Listado del autorizador |
| `src/components/investiture-requests/request-detail-client-page.tsx` | Detalle + decisiones |
| `src/components/investiture-requests/decision-confirm-dialog.tsx` | `AlertDialog` de confirmación de la resolución |
| `src/components/investiture-requests/resolution-summary.tsx` | Resultado de la resolución |
| `src/components/investiture-config/field-config-client-page.tsx` | Ventana + porcentaje |
| `src/components/investiture-config/pastors-client-page.tsx` | Pastores por distrito + cupo |
| `src/components/investiture-config/assign-pastor-dialog.tsx` | Asignación (Dialog, 1 campo) |
| `src/app/(dashboard)/dashboard/investiture-requests/page.tsx` y `[requestId]/page.tsx` | Rutas del autorizador |
| `src/app/(dashboard)/dashboard/investiture-settings/page.tsx` | Configuración del Campo |
| `src/app/(dashboard)/dashboard/investiture-pastors/page.tsx` | Pastores por distrito |
| `src/app/investiture-requests/[requestId]/page.tsx` | Redirección del enlace del correo |
| `src/lib/auth/screen-catalog/screens/investiture.ts` | Screens nuevas |
| `src/lib/auth/permissions.ts` | Constantes de roles nuevas |
| `src/navigation/sidebar/sidebar-items.ts` | Items nuevos en "Validación e investiduras" |
| `src/components/certificate-bulk-imports/certificate-import-errors.ts` | Códigos nuevos de certificados |
| `messages/{es,en,pt-BR,fr}.json` | Namespace `investiture_requests` y `investiture_config` |

---

### Task 1: Módulo de API de solicitudes

**Files:** Create `src/lib/api/investiture-requests.ts`; Test `src/lib/api/investiture-requests.test.ts`.

- [ ] **Step 1: Prueba roja** — que `resolveInvestitureRequest` haga `POST /investiture-requests/:id/resolutions` con el cuerpo dado y desenvuelva `{status,data}`; que `listInvestitureRequestsForAuthorizer` pase `ecclesiastical_year_id` como param.

```ts
import { describe, expect, it, vi, beforeEach } from "vitest";
const clientMock = vi.fn();
vi.mock("@/lib/api/client", async (orig) => ({
  ...(await orig<typeof import("@/lib/api/client")>()),
  apiRequestFromClient: (...a: unknown[]) => clientMock(...a),
}));
import { resolveInvestitureRequest } from "./investiture-requests";

describe("resolveInvestitureRequest", () => {
  beforeEach(() => clientMock.mockReset());
  it("posts decisions and unwraps the envelope", async () => {
    clientMock.mockResolvedValue({ status: "success", data: { request_id: "r1", invested: [], rejected_by_person: [], rejected_by_system: [], retired: [], blocked: [], already_resolved: [] } });
    const result = await resolveInvestitureRequest("r1", { invest: [{ person_id: "p1" }], reject: [] });
    expect(clientMock).toHaveBeenCalledWith("/investiture-requests/r1/resolutions", { method: "POST", body: { invest: [{ person_id: "p1" }], reject: [] } });
    expect(result.request_id).toBe("r1");
  });
});
```

- [ ] **Step 2:** `pnpm test src/lib/api/investiture-requests.test.ts` → FAIL.

- [ ] **Step 3: Implementación** (formas del backend #465 + Plan 0 Task 3):

```ts
import { apiRequest, apiRequestFromClient } from "@/lib/api/client";
import { unwrapApiData } from "@/lib/api/unwrap";

export type InvestiturePersonStatus =
  | "PENDING" | "INVESTED" | "REJECTED_BY_PERSON" | "REJECTED_BY_SYSTEM" | "REMOVED" | "CLOSED_YEAR";

export type InvestitureRequestPerson = {
  person_id: string; user_id: string; user_name: string | null;
  class_id: number; class_name: string | null; section_name: string | null;
  enrollment_id: number; investiture_date: string; status: InvestiturePersonStatus;
  can_authorize: boolean; authorization_comment: string | null;
  rejection_reason: string | null; system_reason: string | null;
  resolution_code: string | null; resolved_by_id: string | null; resolved_by_name: string | null;
  date_changed_by_id: string | null; date_changed_at: string | null;
};

export type InvestitureRequest = {
  request_id: string; club_section_id: number; ecclesiastical_year_id: number;
  club_id?: number; club_name?: string | null; section_name?: string | null; district_name?: string | null;
  pending_count?: number; earliest_investiture_date?: string | null; created_at?: string;
  people: InvestitureRequestPerson[];
};

export type InvestitureResolutionInput = {
  invest?: Array<{ person_id: string; comment?: string }>;
  reject?: Array<{ person_id: string; reason: string }>;
};

export type InvestitureResolution = {
  request_id: string;
  invested: InvestitureRequestPerson[];
  rejected_by_person: InvestitureRequestPerson[];
  rejected_by_system: InvestitureRequestPerson[];
  retired: InvestitureRequestPerson[];
  blocked: Array<{ person_id: string; code: string }>;
  already_resolved: Array<{ person_id: string; status: InvestiturePersonStatus }>;
};

export async function listInvestitureRequestsForAuthorizer(ecclesiasticalYearId: number): Promise<InvestitureRequest[]> {
  const raw = await apiRequest<unknown>("/investiture-requests", { params: { ecclesiastical_year_id: ecclesiasticalYearId } });
  return unwrapApiData<InvestitureRequest[]>(raw);
}

export async function getInvestitureRequest(requestId: string): Promise<InvestitureRequest> {
  const raw = await apiRequest<unknown>(`/investiture-requests/${encodeURIComponent(requestId)}`);
  return unwrapApiData<InvestitureRequest>(raw);
}

export async function resolveInvestitureRequest(requestId: string, input: InvestitureResolutionInput): Promise<InvestitureResolution> {
  const raw = await apiRequestFromClient<unknown>(`/investiture-requests/${encodeURIComponent(requestId)}/resolutions`, { method: "POST", body: input });
  return unwrapApiData<InvestitureResolution>(raw);
}
```

  Si la firma real de `apiRequest`/`unwrapApiData` difiere (por ejemplo, `params` con otro nombre), adaptarse a `src/lib/api/client.ts` y `src/lib/api/unwrap.ts` y ajustar la prueba.

- [ ] **Step 4:** Correr → PASS. **Commit** — `feat(investiture): add investiture requests API module`.

### Task 2: Módulo de API de configuración del Campo

**Files:** Create `src/lib/api/investiture-field-config.ts` + test.

- [ ] **Step 1: Prueba roja** — `updateInvestitureWindow(7, 3, {start_date, end_date})` hace `PATCH /local-fields/7/investiture-windows/3`; `searchPastorCandidates("ana", 5)` hace `GET /investiture-pastor-candidates` con `q` y `districtId`.
- [ ] **Step 2:** Correr → FAIL.
- [ ] **Step 3: Implementación** con estos tipos y funciones (mismo patrón que Task 1):

```ts
export type InvestitureWindow = { local_field_id: number; ecclesiastical_year_id: number; start_date: string | null; end_date: string | null; configured: boolean; operational: boolean; can_edit: boolean };
export type FieldClassThreshold = { local_field_id: number; ecclesiastical_year_id: number; minimum_percent: number; configured: boolean; can_edit: boolean };
export type PastorQuota = { slots: number; configured: boolean; can_edit: boolean };
export type DistrictPastor = { districlub_type_id: number; user_id: string; user_name?: string | null; email?: string | null; can_authorize: boolean; role_missing?: boolean; account_inactive?: boolean };
export type DistrictPastorList = { districlub_type_id: number; slots: number; can_assign: boolean; pastors: DistrictPastor[] };
export type PastorCandidate = { user_id: string; user_name: string | null; email: string | null };

// GET/PATCH /local-fields/:lf/investiture-windows/:year   body { start_date, end_date }
// GET/PATCH /local-fields/:lf/class-thresholds/:year      body { minimum_percent }
// GET/PATCH /investiture-pastor-quota                     body { slots }
// GET/POST  /districts/:d/investiture-pastors             body { user_id }
// DELETE    /districts/:d/investiture-pastors/:userId
// GET       /investiture-pastor-candidates?q=&districtId=   (districtId: Campo del distrito que se edita)
export async function getInvestitureWindow(localFieldId: number, yearId: number): Promise<InvestitureWindow> { /* apiRequest + unwrapApiData */ }
export async function updateInvestitureWindow(localFieldId: number, yearId: number, body: { start_date: string; end_date: string }): Promise<InvestitureWindow> { /* apiRequestFromClient PATCH */ }
export async function getFieldClassThreshold(localFieldId: number, yearId: number): Promise<FieldClassThreshold> { /* … */ }
export async function updateFieldClassThreshold(localFieldId: number, yearId: number, minimumPercent: number): Promise<FieldClassThreshold> { /* … */ }
export async function getPastorQuota(): Promise<PastorQuota> { /* … */ }
export async function updatePastorQuota(slots: number): Promise<PastorQuota> { /* … */ }
export async function listDistrictPastors(districtId: number): Promise<DistrictPastorList> { /* … */ }
export async function assignDistrictPastor(districtId: number, userId: string): Promise<DistrictPastorList> { /* … */ }
export async function removeDistrictPastor(districtId: number, userId: string): Promise<void> { /* … */ }
export async function searchPastorCandidates(q: string): Promise<PastorCandidate[]> { /* … */ }
```

  Cada cuerpo sigue exactamente el patrón de Task 1 (lectura con `apiRequest`, escritura con `apiRequestFromClient`, `unwrapApiData`).
- [ ] **Step 4:** Correr → PASS. **Commit** — `feat(investiture): add field configuration API module`.

### Task 3: Mapa de errores del flujo

**Files:** Create `src/components/investiture-requests/investiture-request-errors.ts` + test; Modify `messages/*.json` (namespace `investiture_requests.errors`).

- [ ] **Step 1: Prueba roja** — `getInvestitureRequestErrorMessage(apiErrorWithCode("INVESTITURE_REQUEST_WINDOW_CLOSED"), t)` devuelve `t("errors.window_closed")`; un código desconocido devuelve `error.message`.
- [ ] **Step 2:** Correr → FAIL.
- [ ] **Step 3: Implementación** con el mismo patrón que `src/components/certifications/certification-review-errors.ts` (`extractErrorCode` + `switch`). Cubrir como mínimo los códigos del módulo en `sacdia-backend/src/common/errors/error-codes.ts` que empiezan con `INVESTITURE_REQUEST_`, `INVESTITURE_WINDOW_`, `CLASS_THRESHOLD_`, `INVESTITURE_PASTOR_` e `INVESTITURE_DURATION_`; listar con `rg -o "INVESTITURE_[A-Z_]+|CLASS_THRESHOLD_[A-Z_]+" sacdia-backend/src/common/errors/error-codes.ts | sort -u` y crear una clave por código (`errors.<snake_case>`). Textos `es` tomados de `sacdia-backend/src/i18n/es/errors.json` para esos mismos códigos.
- [ ] **Step 4:** Correr → PASS; regenerar `messages.d.ts`. **Commit** — `feat(investiture): map investiture request errors`.

### Task 4: Badge de estado por persona

**Files:** Create `src/components/investiture-requests/person-status-badge.tsx` + test.

- [ ] **Step 1: Prueba roja** — cada estado renderiza su etiqueta traducida e `intent`: `PENDING→warning`, `INVESTED→success`, `REJECTED_BY_PERSON` y `REJECTED_BY_SYSTEM→destructive`, `REMOVED→neutral`, `CLOSED_YEAR→neutral`.
- [ ] **Step 2:** FAIL. **Step 3:** wrapper fino sobre `StatusBadge` (`@/components/ui/status-badge`), igual que `src/components/investiture/investiture-status-badge.tsx`. **Step 4:** PASS. **Commit** — `feat(investiture): add investiture person status badge`.

### Task 5: Permisos, screens y navegación

**Files:** Modify `src/lib/auth/permissions.ts`, `src/lib/auth/screen-catalog/screens/investiture.ts`, `src/navigation/sidebar/sidebar-items.ts`; Test `src/lib/auth/screen-catalog/screen-catalog.investiture.test.ts`.

- [ ] **Step 1: Prueba roja** en `screen-catalog.investiture.test.ts`:
  - `investiture-requests` y su detalle: visibles para `pastor`, `director-lf`, `assistant-lf`; no visibles para `director` de club, `admin`, `director-union`.
  - `investiture-settings`: visible para `director-lf`, `assistant-lf`, `admin`, `assistant-admin`, `director-union`, `assistant-union`, `director-dia`, `assistant-dia`; no para `pastor`.
  - `investiture-pastors`: visible para `director-lf`, `assistant-lf`, `director-union`, `assistant-union`; no para `pastor` ni `admin`.
  - Atención: los alias de `role-aliases.ts` hacen equivalentes los 6 roles lf/union/dia; si eso vuelve visible una screen para un rol que el backend rechaza, la página igual debe manejar el 403 con `EndpointErrorBanner state="forbidden"` (Task 6-8) y la prueba debe documentarlo.
- [ ] **Step 2:** FAIL.
- [ ] **Step 3: Implementación:**

```ts
// src/lib/auth/permissions.ts
export const INVESTITURE_AUTHORIZER_ROLES = ["pastor", "director-lf", "assistant-lf"] as const;
export const INVESTITURE_FIELD_CONFIG_ROLES = ["director-lf", "assistant-lf", "admin", "assistant-admin", "director-union", "assistant-union", "director-dia", "assistant-dia"] as const;
export const INVESTITURE_PASTOR_ASSIGN_ROLES = ["director-lf", "assistant-lf", "director-union", "assistant-union"] as const;

// src/lib/auth/screen-catalog/screens/investiture.ts (agregar al array exportado)
{ id: "investiture-requests", path: "/dashboard/investiture-requests", surfaces: ["admin"], viewAny: roleOnlyAccess([...INVESTITURE_AUTHORIZER_ROLES]), capabilities: [] },
{ id: "investiture-settings", path: "/dashboard/investiture-settings", surfaces: ["admin"], viewAny: roleOnlyAccess([...INVESTITURE_FIELD_CONFIG_ROLES]), capabilities: [] },
{ id: "investiture-pastors", path: "/dashboard/investiture-pastors", surfaces: ["admin"], viewAny: roleOnlyAccess([...INVESTITURE_PASTOR_ASSIGN_ROLES]), capabilities: [] },
```

  `/dashboard/investiture-requests/[requestId]` queda cubierto por prefijo de `investiture-requests`. Sidebar: tres subitems nuevos en el grupo "Validación e investiduras" (`sidebar-items.ts` ~L233-310) con ids iguales a las screens, iconos `ShieldCheck`, `CalendarRange`, `UserCog` de lucide, `activeMatch: "prefix"` para el listado. Si el tipo `ScreenDefinition` exige más campos, completarlos copiando una screen existente del mismo archivo.
- [ ] **Step 4:** PASS + `pnpm typecheck`. **Commit** — `feat(investiture): register authorization screens and navigation`.

### Task 5b: Acceso del pastor (decisión del 2026-10-08)

El pastor entra al panel y, de momento, solo ve «Autorizaciones de investidura» (plan funcional §1). El perfil del pastor es solo de la app.

**Files:** Modify la página de inicio del dashboard (`src/app/(dashboard)/dashboard/page.tsx`) y `src/navigation/sidebar/sidebar-items.ts` si hace falta; Test `src/lib/auth/screen-catalog/screen-catalog.investiture.test.ts` y una prueba de la página de inicio.

- [ ] **Step 1: Pruebas rojas:**
  - Un usuario cuyo único rol admin es `pastor` ve en el sidebar solo `investiture-requests`.
  - `/dashboard` redirige a `/dashboard/investiture-requests` para ese usuario. Un `director-lf` sigue viendo el inicio actual.
- [ ] **Step 2:** FAIL.
- [ ] **Step 3:** Implementar la redirección en la página de inicio con `extractRoles(user)` de `src/lib/auth/roles.ts`: si el conjunto de roles admin del usuario es exactamente `{pastor}`, hacer `redirect("/dashboard/investiture-requests")`. Revisar con el screen-catalog que ninguna otra screen incluya `pastor` (las pruebas existentes que le niegan acceso deben seguir verdes).
- [ ] **Step 4:** PASS. **Commit:** `feat(investiture): land pastors on the authorization screen`.

### Task 6: Listado de solicitudes del autorizador

**Files:** Create `src/app/(dashboard)/dashboard/investiture-requests/page.tsx`, `src/components/investiture-requests/requests-list-client-page.tsx` + test.

Comportamiento:
- Server page: `await requireAdminUser()`; año por `?year=` o el año actual (`listEcclesiasticalYears` de `src/lib/api/catalogs.ts`, elegir el activo); `listInvestitureRequestsForAuthorizer(year)` en `try/catch`; un `ApiError` 403 → `EndpointErrorBanner state="forbidden"` (caso `super-admin` o `admin`: el backend no les lista).
- `PageHeader` con título «Autorizaciones de investidura» y descripción «Solicitudes pendientes de tu distrito o Campo.»; `EcclesiasticalYearSelect` en `actions` que hace `router.push(?year=)`.
- `DataTableShell` con columnas: Club, Sección, Distrito, Pendientes (`pending_count`), Próxima fecha (`earliest_investiture_date` formateada), Presentada (`created_at`). Fila completa enlaza a `/dashboard/investiture-requests/{request_id}`. Orden: próxima fecha ascendente.
- Vacío: `EmptyState` «No hay solicitudes pendientes».

- [ ] **Step 1: Prueba roja** del client page: renderiza dos filas con nombres y conteos, enlaza al detalle, muestra el `EmptyState` con lista vacía.
- [ ] **Step 2:** FAIL. **Step 3:** implementar. **Step 4:** PASS + lint + typecheck. **Commit** — `feat(investiture): add authorizer request list page`.

### Task 7: Detalle y resolución

**Files:** Create `src/app/(dashboard)/dashboard/investiture-requests/[requestId]/page.tsx`, `request-detail-client-page.tsx`, `decision-confirm-dialog.tsx`, `resolution-summary.tsx` + tests.

Comportamiento (plan funcional IA-03, IA-09, IA-10, IA-12, IA-41):
- Cabecera con club, sección, distrito, año; `PageHeader` con breadcrumb al listado.
- Tabla de personas con nombre, clase, fecha, `PersonStatusBadge`. Las resueltas muestran quién decidió (`resolved_by_name`, «Sistema» para `REJECTED_BY_SYSTEM`), el comentario o el texto largo del sistema (`system_reason`). El autorizador **no** ve `rejection_reason` (el backend lo devuelve `null`; no inventarlo).
- Para cada `PENDING` con `can_authorize: true`: control segmentado «Investir / Rechazar / Sin decidir» (default «Sin decidir»). «Investir» abre un textarea opcional de comentario (máx. 500). «Rechazar» exige motivo (zod `min(1).max(1000)`).
- Barra de acción fija al pie: «Confirmar decisiones (N)»; deshabilitada si N = 0 o hay un rechazo sin motivo. Abre `DecisionConfirmDialog` (`AlertDialog`, irreversible): lista cuántos se invisten y cuántos se rechazan; botón «Confirmar» con estado «Confirmando…».
- Al confirmar: `resolveInvestitureRequest`. Mostrar `ResolutionSummary` con cuatro grupos: investidos, rechazados por quien autoriza, rechazados por el sistema (con `system_reason`), sin aplicar (`blocked` con el mensaje de `getInvestitureRequestErrorMessage` y `already_resolved` con «Ya había sido resuelto»). Luego `router.refresh()`.
- Error de la llamada: `toast.error(getInvestitureRequestErrorMessage(error, t))`. `INVESTITURE_REQUEST_WINDOW_CLOSED` y `INVESTITURE_REQUEST_YEAR_CLOSED` además muestran un banner persistente arriba de la tabla: «La ventana del Campo está cerrada. Pedí al Campo que la amplíe para poder autorizar.»
- Si ninguna persona tiene `can_authorize`, ocultar controles y mostrar un aviso informativo (caso `super-admin` leyendo).

- [ ] **Step 1: Pruebas rojas:**
  - envía `{ invest: [{person_id:"p1", comment:"¡Bien!"}], reject: [{person_id:"p2", reason:"Faltan evidencias"}] }` tras confirmar;
  - el botón queda deshabilitado con un rechazo sin motivo;
  - muestra «Sistema» y el texto largo para `REJECTED_BY_SYSTEM`;
  - no renderiza controles cuando `can_authorize` es `false`;
  - muestra el banner con `INVESTITURE_REQUEST_WINDOW_CLOSED`.
- [ ] **Step 2:** FAIL. **Step 3:** implementar. **Step 4:** PASS + lint + typecheck. **Commit** — `feat(investiture): add request detail with per-person resolution`.

### Task 8: Redirección del enlace del correo

**Files:** Create `src/app/investiture-requests/[requestId]/page.tsx` + test.

```tsx
import { redirect } from "next/navigation";

export default async function InvestitureRequestLinkPage({ params }: { params: Promise<{ requestId: string }> }) {
  const { requestId } = await params;
  redirect(`/dashboard/investiture-requests/${encodeURIComponent(requestId)}`);
}
```

- [ ] **Step 1: Prueba roja** — llamar la página con `params` y esperar `redirect` (mock de `next/navigation`) con la ruta del dashboard.
- [ ] **Step 2:** FAIL. **Step 3:** crear la página. Verificar en `src/proxy.ts` que `/investiture-requests/*` no queda bloqueada ni requiere cookie (la autenticación la hace `/dashboard`); si el proxy usa un `matcher`, no agregar esta ruta al matcher. **Step 4:** PASS. **Commit** — `feat(investiture): redirect mail links to the request detail`.

### Task 9: Configuración del Campo (ventana y porcentaje)

**Files:** Create `src/app/(dashboard)/dashboard/investiture-settings/page.tsx`, `src/components/investiture-config/field-config-client-page.tsx` + test.

Comportamiento (IA-13, IA-19, IA-23, IA-24):
- Server page con la plantilla de `D/configuration/local-field/delivery/page.tsx`: `resolveUserLocalField(user)`, `canPickLocalField(scope)`, `LocalFieldPicker` para unión, división y admin; año por `?year=` con `EcclesiasticalYearSelect`.
- Dos `Card`:
  - **Ventana de solicitudes:** fechas de inicio y fin (inputs `type="date"`), con el texto «Del {inicio} al {fin}, inclusive, en la zona del Campo.» Si `configured` es `false` y las fechas vienen `null`: «No hay ventana operativa para este año. Configurala para permitir presentar y autorizar.» (W1). Guardar con `updateInvestitureWindow`; validación zod `start_date <= end_date`. Solo editable si `can_edit`.
  - **Porcentaje mínimo:** número 0-100 (default mostrado 80 si `configured` es `false`), con ayuda «Hasta el 30 de junio lo edita el Campo; después solo super-admin.» Solo editable si `can_edit`.
- `toast.success` al guardar y `router.refresh()`; errores con el mapa de Task 3 (incluye los 400 de validación sin `code`).

- [ ] **Step 1: Pruebas rojas** — modo lectura con `can_edit: false` (sin botón Guardar); envío correcto de fechas; mensaje de W1 con `start_date: null`; validación `inicio > fin`.
- [ ] **Step 2:** FAIL. **Step 3:** implementar. **Step 4:** PASS. **Commit** — `feat(investiture): add field window and threshold settings`.

### Task 10: Pastores por distrito y cupo

**Files:** Create `src/app/(dashboard)/dashboard/investiture-pastors/page.tsx`, `pastors-client-page.tsx`, `assign-pastor-dialog.tsx` + tests.

Comportamiento (sección 2 del plan funcional, BC-6/BCR-6):
- Lista de distritos del Campo (`listAdminDistricts` de `src/lib/api/admin-districts.ts` filtrado por `local_field_id`; respetar `normalizeDistrict` y la PK `districlub_type_id`), con picker de Campo para roles de unión.
- Por distrito: tarjeta con «{n}/{cupo} pastores» y la lista de pastores (nombre, correo). Badges: `role_missing` → «Sin rol de pastor», `account_inactive` → «Cuenta inactiva»; ambos con texto «Ocupa cupo, no autoriza ni recibe correos». Acción «Quitar» con `AlertDialog` destructivo.
- «Asignar pastor» (solo si `can_assign` y hay cupo libre): `AssignPastorDialog` con un combobox (Popover + Command) que busca con `searchPastorCandidates(q, districtId)` a partir de 3 caracteres, con debounce de 300 ms. Decisión del 2026-10-08: siempre envía el `districtId` del distrito que se edita, porque el backend solo acepta pastores del Campo de ese distrito (400 `INVESTITURE_PASTOR_FIELD_MISMATCH`, mapeado en el mapa de errores). Un solo campo, así que Dialog es correcto según §6.1.1.
- Tarjeta superior «Cupo de pastores por distrito»: número; editable solo si `can_edit` del cupo (super-admin). Bajar el cupo por debajo de los activos devuelve un error del backend que se muestra con el mapa.

- [ ] **Step 1: Pruebas rojas** — badges `role_missing` y `account_inactive`; no se muestra «Asignar» sin cupo; el diálogo no busca con menos de 3 caracteres; «Quitar» pide confirmación.
- [ ] **Step 2:** FAIL. **Step 3:** implementar. **Step 4:** PASS. **Commit** — `feat(investiture): add district pastor assignment`.

### Task 11: Errores nuevos de certificados

**Files:** Create `src/components/certificate-bulk-imports/certificate-import-errors.ts` + test; Modify `certificate-bulk-import-action-dialog.tsx` (catch ~L133-136) y `messages/*.json` (`certificate_bulk_imports.errors.*`).

- [ ] **Step 1: Prueba roja** — `CERTIFICATE_IMPORT_AUTHORIZATION_PENDING` → «La persona tiene una solicitud de investidura pendiente en este año. Primero se resuelve la autorización.»; `CERTIFICATE_IMPORT_ENDED_YEAR_FIELD_FORBIDDEN` → «Solo el Campo de la solicitud o la administración pueden acreditar este certificado.»; en el diálogo, el primero se muestra como banner inline, no como toast.
- [ ] **Step 2:** FAIL. **Step 3:** implementar. **Step 4:** PASS. **Commit** — `feat(certificates): explain investiture-related approval errors`.

### Task 12: Verificación integral y PR

- [ ] `pnpm test`, `pnpm lint`, `pnpm typecheck` en verde; `node scripts/generate-messages-types.mjs` sin diferencias pendientes.
- [ ] Revisión manual con el backend local (si el usuario lo autoriza): flujo pastor → listado → detalle → resolución; Campo → ventana → porcentaje → pastores.
- [ ] PR contra `development` de `sacdia-admin`, `type:feature`. Si supera 400 líneas sin tests, partir en PRs encadenados: (a) Tasks 1-5, (b) Tasks 6-8, (c) Tasks 9-10, (d) Task 11.

## Fuera de este plan

Retirar `/dashboard/investiture`, `/pipeline`, `/config` y el tab de clases de `/dashboard/clubs/validations` (fase 8). Activar `INVESTITURE_EMAIL_ENABLED` (despliegue).
