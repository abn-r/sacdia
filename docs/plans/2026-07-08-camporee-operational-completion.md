# Camporee Operational Completion Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Completar el flujo operativo real de camporee: scoring oficial seguro, ausencias/no-presentado, mínimos/máximos, ventanas de evaluación, penalizaciones, adjuntos y UI/admin/app alineadas.

**Architecture:** Contract-first. El backend debe ser la autoridad de reglas críticas: quién puede calificar, cuándo puede calificar, si puede reabrir/modificar y cómo se audita cada resultado. Admin y app sólo exponen flujos permitidos por esos contratos.

**Tech Stack:** NestJS + Prisma + PostgreSQL en `sacdia-backend`; Next.js admin en `sacdia-admin`; Flutter/Riverpod en `sacdia-app`; documentación canónica en `docs/`.

---

## Critical business rules

1. La inscripción/asistencia a camporee no puntúa ranking anual; el ranking usa resultados oficiales por sección/evento.
2. Eventos puntuables usan rúbricas cuya suma debe igualar `camporee_events.max_points`.
3. Sólo el juez principal sube puntaje oficial; ayudantes no promedian ni califican.
4. `assistant-lf` y `director-lf` pueden registrar o corregir manualmente sin asignación de juez.
5. Si el puntaje enviado queda bajo `camporee_events.min_points`, backend lo redondea al mínimo; si no hay mínimo, conserva lo enviado.
6. Nunca se permite superar el máximo del evento/rúbrica.
7. Una calificación oficial de juez principal es one-shot; sólo Campo Local puede modificar/override posterior.
8. “Club no se presentó” debe guardar estado auditable y asignar mínimo configurado.
9. Scoring debe bloquearse fuera de la ventana horaria del evento, salvo override Campo Local.
10. Adjuntos de evento: hasta 5 PDFs por evento.

---

## Batch 1 — Backend scoring crítico

### Task 1: Extender schema y migración para estado de scoring

**Files:**
- Modify: `sacdia-backend/prisma/schema.prisma`
- Create: `sacdia-backend/prisma/migrations/<timestamp>_camporee_score_no_show_and_lock/migration.sql`
- Modify mirror if required: `docs/database/schema.prisma`
- Modify docs: `docs/database/SCHEMA-REFERENCE.md`, `docs/features/camporees.md`

**Steps:**
1. Add fields to `camporee_event_score_submissions` and/or `camporee_event_section_results` for:
   - `status` or equivalent: `scored | no_show | override`
   - `is_no_show Boolean @default(false)` if simpler and explicit.
   - `override_of_submission_id String? @db.Uuid` if needed for audit chain.
2. Add indexes for active result by event/section/status if needed.
3. Document no-show as an official result state.
4. Do not remove existing audit fields.

**Verification:**
- `pnpm exec prisma validate`
- No build.

### Task 2: Add DTO contract for no-show and manual override semantics

**Files:**
- Modify: `sacdia-backend/src/camporee-scoring/dto/camporee-scoring.dto.ts`
- Test: `sacdia-backend/src/camporee-scoring/camporee-scoring.service.spec.ts`

**Steps:**
1. Extend `SubmitCamporeeEventScoreDto` with optional `status` or `no_show` flag.
2. If no-show is true, allow empty rubric items only if service will synthesize zero/minimum items or result totals directly.
3. Keep regular rubric scoring strict: one item per active rubric.
4. Validate source remains `judge_primary | manual_lf | admin_override`.

**Verification:**
- `pnpm exec jest src/camporee-scoring/camporee-scoring.service.spec.ts --runInBand`

### Task 3: Enforce min/max and no-show in service

**Files:**
- Modify: `sacdia-backend/src/camporee-scoring/camporee-scoring.service.ts`
- Test: `sacdia-backend/src/camporee-scoring/camporee-scoring.service.spec.ts`

**Steps:**
1. Add tests first:
   - total below `min_points` clamps to `min_points` when `min_points > 0`.
   - total below min remains as submitted when `min_points` is `0`/unset.
   - no-show stores official result with no-show state and awards `min_points`.
   - no-show with no min awards `0`.
   - exceeding rubric/event max still rejects.
2. Implement minimal service changes.
3. Ensure percentage uses adjusted awarded total.
4. Preserve submission item audit for normal scoring.

**Verification:**
- `pnpm exec jest src/camporee-scoring/camporee-scoring.service.spec.ts --runInBand`

### Task 4: Enforce one-shot judge scoring with LF override only

**Files:**
- Modify: `sacdia-backend/src/camporee-scoring/camporee-scoring.service.ts`
- Test: `sacdia-backend/src/camporee-scoring/camporee-scoring.service.spec.ts`

**Steps:**
1. Add tests first:
   - primary judge cannot submit again when active result exists for event/section.
   - `assistant-lf`/`director-lf` manual source can replace active result.
   - previous result remains inactive/auditable after LF override.
2. Implement check before creating submission:
   - if active result exists and actor is not manual LF/admin override, throw conflict/forbidden.
   - if manual LF/admin override, deactivate previous active result and create replacement.

**Verification:**
- `pnpm exec jest src/camporee-scoring/camporee-scoring.service.spec.ts --runInBand`

---

## Batch 2 — Backend lifecycle and timing

### Task 5: Gate scoring by event time window

**Files:**
- Modify: `sacdia-backend/src/camporee-scoring/camporee-scoring.service.ts`
- Test: `sacdia-backend/src/camporee-scoring/camporee-scoring.service.spec.ts`

**Steps:**
1. Use camporee `start_date` + `day_number` + `starts_at`/`ends_at` to derive window.
2. Primary judge scoring allowed only within window.
3. Manual LF override allowed outside window.
4. Missing time window should be conservative: allow LF setup, reject judge scoring unless business decides otherwise.

### Task 6: Freeze destructive camporee/event changes after start

**Files:**
- Modify: `sacdia-backend/src/camporee-events/camporee-events.service.ts`
- Test: `sacdia-backend/src/camporee-events/camporee-events.service.spec.ts`

**Steps:**
1. Prevent delete/deactivate/removing core scoring aspects once camporee has started.
2. Still allow schedule/judge adjustments explicitly permitted.
3. Document allowed vs blocked mutations.

### Task 7: Automatic deadlines and penalties

**Files:**
- Modify: `sacdia-backend/src/camporees/camporees.service.ts`
- Modify/create: penalty config service if needed.
- Tests in camporee service specs.

**Steps:**
1. Keep deadlines as source of late status.
2. Add deterministic application of configured penalties for late enrollment/payment.
3. Ensure assistant/director LF can approve late joins with penalty audit.

---

## Batch 3 — Event PDF attachments

### Task 8: Backend event attachments

**Files:**
- Modify: `sacdia-backend/prisma/schema.prisma`
- Create migration for `camporee_event_files`
- Modify: `sacdia-backend/src/camporee-events/*`
- Docs: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, `docs/database/SCHEMA-REFERENCE.md`, `docs/features/camporee-events.md`

**Steps:**
1. Model up to 5 active PDF files per event.
2. Add upload/list/delete endpoints.
3. Validate MIME/extension/size using existing file-storage patterns.
4. App-safe preview includes file metadata/download URLs only when allowed.

---

## Batch 4 — Admin/App alignment

### Task 9: Admin staff roster and assignments

**Files:**
- Modify/create under `sacdia-admin/src/components/camporee-*`
- Modify `sacdia-admin/src/lib/api/*` and actions.

**Steps:**
1. Add Personal/Staff tab using backend staff endpoints.
2. Replace UUID inputs with searchable user selector.
3. Assign staff to event agenda roles.

### Task 10: Admin event attachments and no-show/manual override UI

**Steps:**
1. Add PDF manager to event form/detail.
2. Add no-show/manual override controls in scoring panel.
3. Respect backend errors for locked judge results.

### Task 11: App scoring and result visibility

**Files:**
- Modify `sacdia-app/lib/features/camporees/**`

**Steps:**
1. Add no-show action for primary judge.
2. Show read-only received score to director/subdirector.
3. Hide/disable scoring outside allowed window based on backend response.
4. Ensure navigation to judge assignments is discoverable for eligible users.

---

## Batch 1 checkpoint contract

Stop after Batch 1 and report:
- Files changed.
- Schema/doc changes.
- Tests run and exact result.
- Risks for Batch 2.
