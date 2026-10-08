# Investidura por autorización — Soporte de backend para las pantallas (Plan 0)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Agregar al backend los cinco datos que las pantallas de la app y del panel necesitan y que hoy la API no entrega.

**Architecture:** Cambios chicos y aditivos sobre el módulo `src/investiture-requests/` y `src/classes/district-investiture-pastors.*`. Ninguna regla de negocio nueva: el contexto de presentación reutiliza exactamente las comprobaciones de `acceptEnrollment` sin escribir, y el resto agrega campos de lectura. Este plan bloquea a los planes 1 (panel) y 2 (app).

**Tech Stack:** NestJS 11, Prisma 7.9, Jest, PostgreSQL 18 (e2e aislada).

**Base:** rama `feat/investiture-authorization-completion` del backend (PR abn-r/sacdia-backend#465) o `development` una vez mergeado. Spec: `docs/plans/2026-09-28-investidura-autorizacion.md` (IA-01 a IA-62).

---

## Reglas para quien ejecute

- TDD: prueba roja registrada antes de cada cambio. Lo que dependa de la base, también en PostgreSQL.
- Unitarias: `node node_modules/jest/bin/jest.js --no-coverage --forceExit` (no `pnpm run test -- …`).
- PostgreSQL: clúster descartable propio (`PATH=/opt/homebrew/opt/postgresql@18/bin:$PATH`, `LC_ALL=C`, `log_min_messages = warning`, puerto ≠ 5432), `--config ./test/jest-e2e.json --runInBand`, `SACDIA_TEST_DATABASE_URL` y `SACDIA_POSTGRES_SERVER_LOG`.
- `npx tsc --noEmit -p tsconfig.build.json` y `npx eslint --no-fix` sobre los archivos tocados.
- Sin builds, sin Neon, sin commits fuera de los indicados. Los contratos nuevos se documentan en `docs/api/ENDPOINTS-LIVE-REFERENCE.md` y `docs/api/FRONTEND-INTEGRATION-GUIDE.md` del repo raíz.

## Archivos

| Archivo | Responsabilidad |
| --- | --- |
| `src/investiture-requests/investiture-presentation-context.ts` (nuevo) | Tipos `PresentationCandidate`, `PresentationContextView` y el mapeo de códigos bloqueantes |
| `src/investiture-requests/investiture-authorization-requests.service.ts` | `presentationContext()`, extracción de `evaluateEnrollmentForPresentation()` desde `acceptEnrollment`, campos nuevos en el listado del autorizador |
| `src/investiture-requests/investiture-authorization-requests.controller.ts` | Ruta `GET club-sections/:sectionId/investiture-requests/presentation-context` |
| `src/classes/district-investiture-pastors.service.ts` / `.controller.ts` | `user_name`/`email` en `DistrictPastorView`; búsqueda de candidatos a pastor |
| `src/investiture-requests/investiture-communications.service.ts` | `type` y destino en el push del resultado |
| Specs y `test/investiture-authorization-requests-postgres.e2e-spec.ts` | Pruebas |

---

### Task 1: Extraer la evaluación de presentación sin escribir

Hoy `acceptEnrollment` (`investiture-authorization-requests.service.ts`, ~L1129-1370) valida y **lanza** el primer código que falla: fuera de sección, clase legado (IA-62), flujo anterior activo, ya investido (IA-06), solicitud activa incompatible (IA-04/05), duración (IA-18), `EXPIRED`, elegibilidad (IA-08). La app necesita esos mismos motivos **sin intentar presentar**.

**Files:**
- Modify: `src/investiture-requests/investiture-authorization-requests.service.ts`
- Test: `src/investiture-requests/investiture-authorization-requests.service.spec.ts`

- [ ] **Step 1: Prueba roja de equivalencia.** Para cada código que hoy lanza `acceptEnrollment`, una prueba que llame al nuevo método privado expuesto para pruebas y espere `{ eligible: false, code }` con el mismo código, y otra con un enrollment elegible que espere `{ eligible: true }`.

```ts
describe('evaluateEnrollmentForPresentation', () => {
  it.each([
    ['INVESTITURE_REQUEST_OUTSIDE_SECTION', outsideSectionFixture],
    ['INVESTITURE_REQUEST_CLASS_NOT_ELIGIBLE', legacyInstitutionalClassFixture],
    ['INVESTITURE_REQUEST_LEGACY_PIPELINE_ACTIVE', legacyPipelineFixture],
    ['INVESTITURE_REQUEST_ALREADY_INVESTED', alreadyInvestedFixture],
    ['INVESTITURE_REQUEST_ACTIVE_EXISTS', activePendingFixture],
    ['INVESTITURE_DURATION_MIN_NOT_MET', firstYearOfTwoYearClassFixture],
    ['INVESTITURE_DURATION_EXPIRED', expiredFixture],
    ['INVESTITURE_REQUEST_NOT_ELIGIBLE', notEligibleProgressFixture],
  ])('returns %s without writing', async (code, fixture) => {
    const { service, store, context, enrollment } = await fixture();
    await expect(
      service['evaluateEnrollmentForPresentation'](store, context, enrollment),
    ).resolves.toEqual({ eligible: false, code });
    expect(store.investiture_authorization_people.create).not.toHaveBeenCalled();
  });
});
```

Los fixtures reutilizan los helpers de mocks que ya usa la spec para `present`; los códigos exactos se toman de `src/common/errors/error-codes.ts` (si alguno difiere del listado, usar el real y anotarlo).

- [ ] **Step 2:** Correr `node node_modules/jest/bin/jest.js --no-coverage --forceExit src/investiture-requests/investiture-authorization-requests.service.spec.ts -t evaluateEnrollmentForPresentation`. Esperado: FAIL (método inexistente).

- [ ] **Step 3: Implementación.** Mover el cuerpo de comprobaciones de `acceptEnrollment` a:

```ts
private async evaluateEnrollmentForPresentation(
  store: Prisma.TransactionClient | PrismaService,
  context: SectionContext,
  enrollment: EnrollmentRow,
): Promise<{ eligible: true } | { eligible: false; code: ErrorCode }>
```

y dejar `acceptEnrollment` así (mismo orden de candados que hoy; la evaluación corre después de los candados, como ahora):

```ts
const verdict = await this.evaluateEnrollmentForPresentation(store, context, enrollment);
if (!verdict.eligible) {
  throw codeToException(verdict.code, { userId: enrollment.user_id, classId: enrollment.class_id });
}
```

`codeToException` conserva el tipo de excepción y el `details` que hoy lanza cada rama (409 o 400). No cambia ningún código ni estado HTTP.

- [ ] **Step 4:** Correr la spec completa del servicio y la e2e de PostgreSQL. Esperado: todo verde, sin cambios en pruebas existentes.

- [ ] **Step 5: Commit** — `refactor(investiture): evaluate presentation eligibility without writing`.

---

### Task 2: Contexto de presentación para la directiva

`GET /api/v1/club-sections/:sectionId/investiture-requests/presentation-context?ecclesiastical_year_id=` — solo director, secretario o secretario-tesorero de la sección y el año (los mismos de `present`); subdirector y `super-admin` sin cargo: 403 `INVESTITURE_REQUEST_FORBIDDEN`.

Respuesta:

```ts
// src/investiture-requests/investiture-presentation-context.ts
export type PresentationCandidate = {
  enrollment_id: number;
  user_id: string;
  user_name: string | null;
  class_id: number;
  class_name: string | null;
  overall_progress: number;          // mismo cálculo de ClassProgressScopeService
  eligible: boolean;
  blocked_code: string | null;       // código de Task 1 si eligible = false
  pending_person_id: string | null;  // si ya está PENDING en la solicitud abierta
};

export type PresentationContextView = {
  club_section_id: number;
  ecclesiastical_year_id: number;
  window: {
    start_date: string | null;
    end_date: string | null;
    open_today: boolean;              // investitureWindowAllowsOperation con el día local del Campo
  };
  year_open: boolean;
  open_request_id: string | null;     // la solicitud con PENDING de esa sección y año, si existe
  candidates: PresentationCandidate[];
};
```

Candidatos: los enrollments `OPERATIONAL` activos de miembros activos de la sección para ese año, más los de clase cruzada que hoy acepta `present` (P4-2), sin repetir. Orden: `eligible` primero, luego `user_name`.

**Files:** el archivo nuevo de tipos, servicio, controlador, specs y e2e.

- [ ] **Step 1: Pruebas rojas (unidad).**
  - Directiva con dos miembros, uno elegible y uno `PENDING`: el elegible sale `eligible: true`; el pendiente sale `eligible: false`, `blocked_code: 'INVESTITURE_REQUEST_ACTIVE_EXISTS'` y `pending_person_id` con su id.
  - Ventana cerrada hoy: `window.open_today === false`; los candidatos siguen listándose.
  - Subdirector: 403 `INVESTITURE_REQUEST_FORBIDDEN`.
  - Ninguna escritura (`create`/`update`/`updateMany` no llamados) y ningún candado tomado.

- [ ] **Step 2: Prueba roja (PostgreSQL)** en un `describe('presentation context')` nuevo al final del describe principal de la e2e: sembrar una sección con un elegible, uno en el flujo anterior (`SUBMITTED_FOR_VALIDATION`) y uno ya investido en otro enrollment de la misma clase; esperar `eligible` true / `LEGACY_PIPELINE_ACTIVE` / `ALREADY_INVESTED` y el nombre real de la clase.

- [ ] **Step 3:** Correr ambas. Esperado: FAIL (ruta inexistente).

- [ ] **Step 4: Implementación.**
  - Controlador, siguiendo el patrón de `list` (L65-85):

```ts
@Get('club-sections/:sectionId/investiture-requests/presentation-context')
@ApiOperation({ summary: 'Contexto para presentar personas a investidura' })
async presentationContext(
  @Param('sectionId', ParseIntPipe) sectionId: number,
  @Query('ecclesiastical_year_id', ParseIntPipe) ecclesiasticalYearId: number,
  @Request() req: AuthenticatedRequest,
) {
  const data = await this.requests.presentationContext(
    req.user.authorization, sectionId, ecclesiasticalYearId, req.user.sub,
  );
  return { status: 'success', data };
}
```

  La ruta va **antes** de cualquier `club-sections/:sectionId/investiture-requests/:x` para que Nest no la confunda.
  - Servicio: `presentationContext()` resuelve el `SectionContext` con `loadContext(..., { validateTimeZone: false })` para no fallar por zona inválida, verifica el cargo con la misma función que `present`, lee la ventana con `investitureWindowAllowsOperation` y el día local del Campo, carga los enrollments candidatos en una consulta, y llama a `evaluateEnrollmentForPresentation` por cada uno **sin transacción ni candados**. `overall_progress` sale de `ClassRequirementEligibilityService` en lote, igual que `ClassProgressScopeService.getClassMembersProgress`.

- [ ] **Step 5:** Correr unidad y PostgreSQL. Esperado: PASS.

- [ ] **Step 6: Contrato.** Documentar la ruta en `docs/api/ENDPOINTS-LIVE-REFERENCE.md` (tabla del módulo `investiture-requests`) y en `docs/api/FRONTEND-INTEGRATION-GUIDE.md` (sección de la solicitud), aclarando que es solo informativa: `present` vuelve a comprobar todo bajo candados.

- [ ] **Step 7: Commit** — `feat(investiture): add presentation context for the section board`.

---

### Task 3: Datos de club y sección en el listado del autorizador

`GET /api/v1/investiture-requests?ecclesiastical_year_id=` devuelve `InvestitureRequestView[]` sin nombre de club, sección ni conteos; el panel no puede armar la lista.

- [ ] **Step 1: Prueba roja.** El listado del autorizador devuelve, por solicitud:

```ts
club_id: number;
club_name: string | null;
section_name: string | null;
district_name: string | null;
pending_count: number;   // personas PENDING
earliest_investiture_date: string | null; // menor fecha entre los PENDING
created_at: string;
```

  y el detalle (`GET investiture-requests/:id`) devuelve los mismos campos de cabecera. Las formas de `people[]` no cambian.

- [ ] **Step 2:** Correr la spec. Esperado: FAIL.

- [ ] **Step 3:** Extender `InvestitureRequestView` con esos campos opcionales para no romper otros consumidores, y completarlos en `listForAuthorizer` y `readForAuthorizer` con una consulta por lote (`club_sections` → `clubs` → `churches` → `districts`), sin N+1.

- [ ] **Step 4:** Unidad + PostgreSQL (un caso que lea dos solicitudes de clubes distintos y verifique nombres reales). Esperado: PASS.

- [ ] **Step 5:** Documentar en `ENDPOINTS-LIVE-REFERENCE.md`. **Commit** — `feat(investiture): include club, section and counts in authorizer reads`.

---

### Task 4: Nombres de pastores y búsqueda de candidatos

`DistrictPastorView` trae solo `user_id`; el listado de usuarios con filtro de rol (`GET /admin/users?role=`) es solo para `admin` y `super-admin`, así que un `director-lf` no puede buscar a quién asignar.

- [ ] **Step 1: Pruebas rojas.**
  - `GET districts/:districtId/investiture-pastors` y `GET clubs/:clubId/investiture-authorizers` incluyen `user_name` y `email` por pastor.
  - Nueva `GET /api/v1/investiture-pastor-candidates?q=` para los mismos roles que asignan (`director-lf`, `assistant-lf` del Campo, `director-union`, `assistant-union`): devuelve hasta 20 usuarios con rol global `pastor` y cuenta activa (`pastorEligibility` de `investiture-pastor-eligibility.ts`) cuyo nombre o correo contiene `q` (mínimo 3 caracteres; menos → 400 de validación). Forma: `{ user_id, user_name, email }[]`. Otro rol: 403.

- [ ] **Step 2:** Correr. Esperado: FAIL.

  - **Decisión del 2026-10-08 (privacidad):** la búsqueda devuelve solo pastores cuyo `users.local_field_id` está dentro del alcance de quien busca (su Campo; para `director-union`/`assistant-union`, los Campos de su unión). Cada palabra de `q` debe tener al menos 2 caracteres. Un pastor sin `local_field_id` no aparece en la búsqueda hasta que se le registre el Campo.
- [ ] **Step 3:** Implementar en `district-investiture-pastors.service.ts` y `.controller.ts` (DTO `SearchPastorCandidatesDto` con `@IsString() @MinLength(3) q`). El nombre se arma igual que en `requestLabels` del servicio de solicitudes.

- [ ] **Step 4:** Unidad + `test/district-investiture-pastors-postgres.e2e-spec.ts`. Esperado: PASS.

- [ ] **Step 5:** Documentar. **Commit** — `feat(investiture): expose pastor names and candidate search`.

---

### Task 5: Destino del push de resultado

El push de resultado manda `data: { requestId }` sin `type` (`investiture-communications.service.ts` ~L1121). La app solo navega por `data.type` o `data.route` en una lista permitida.

- [ ] **Step 1: Prueba roja.** El push de resultado incluye `type: 'investiture_result'`, `audience: 'person' | 'board'`, `requestId`, `sectionId` (string) y `classId` (string, solo para `person`).

- [ ] **Step 2:** Correr la spec de entrega. Esperado: FAIL.

- [ ] **Step 3:** Agregar esos campos al `data` del push en `ResultDraft` (`investiture-communications.rules.ts`) y en `pushBestEffort`. La bandeja (`notification_logs`) no cambia: la app enruta por `source` (`investiture:invested` / `investiture:rejected`).

- [ ] **Step 4:** Correr. Esperado: PASS. **Commit** — `feat(investiture): tag result pushes for app navigation`.

---

### Task 6: Verificación integral y PR

- [ ] Unitarias completas, `tsc`, ESLint de los archivos tocados y las suites PostgreSQL (`investiture-authorization-requests`, `district-investiture-pastors`, `certificate-import`, `evidence-review-investiture-guard`, `helpers/investiture-server-log`) con 0 `deadlock detected`.
- [ ] PR contra `development` (o apilado sobre #465 si todavía no se mergeó), `type:feature`. Tamaño esperado < 400 líneas sin contar pruebas.

## Fuera de este plan

Pantallas (planes 1 y 2), fase 8, migraciones en Neon.
