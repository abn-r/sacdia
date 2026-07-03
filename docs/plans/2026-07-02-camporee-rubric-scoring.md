# Camporee Rubric Scoring Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implementar puntaje real de camporee por rúbricas, jueces principales/ayudantes y resultados oficiales por sección, reemplazando el scoring anual basado en asistencia.

**Architecture:** Se agrega un bounded context `camporee-scoring` sobre el modelo existente de `camporee_events`, `camporee_clubs` y `club_sections`. La asistencia/inscripción queda como registro operativo, pero el componente anual `camporee_events` se calculará desde resultados finalizados por evento/sección. Las rúbricas son obligatorias para eventos puntuables: la suma de criterios debe igualar `camporee_events.max_points`.

**Tech Stack:** NestJS 11 + Prisma 7 + PostgreSQL, Next.js 16 + React Hook Form/Zod, Flutter + Riverpod/Clean Architecture, Jest/Vitest/Flutter Test.

---

## Reglas de negocio cerradas

- Un evento puede ser puntuable o no puntuable.
- Si `scoring_enabled = true`, el evento debe tener rúbricas activas.
- La suma de `camporee_event_rubrics.max_points` debe ser igual a `camporee_events.max_points`.
- Si varios jueces evalúan la misma sección en el mismo evento, NO se promedia.
- Debe existir máximo un juez principal activo por `camporee_event_id + club_section_id`.
- Sólo el juez principal puede enviar puntaje desde app.
- Los jueces ayudantes quedan como apoyo/auditoría, pero no envían puntaje oficial.
- `assistant-lf` y `director-lf` pueden registrar puntaje manual sin asignación de juez.
- El puntaje oficial se deriva de los ítems de rúbrica.
- La asistencia/inscripción al camporee ya no puntúa ranking anual.
- `camporee_clubs` y `camporee_members` se conservan como registro histórico/operativo.

---

## Fase 1 — Backend schema y migración

### Task 1: Agregar migración SQL de scoring

**Files:**

- Create: `sacdia-backend/prisma/migrations/20260702193000_camporee_rubric_scoring/migration.sql`
- Modify: `sacdia-backend/prisma/schema.prisma`
- Modify: `docs/database/schema.prisma`

**Schema SQL esperado:**

```sql
ALTER TABLE "camporee_events"
  ADD COLUMN "scoring_enabled" BOOLEAN NOT NULL DEFAULT FALSE;

CREATE TABLE "camporee_event_rubrics" (
  "camporee_event_rubric_id" SERIAL PRIMARY KEY,
  "camporee_event_id" INTEGER NOT NULL,
  "title" VARCHAR(120) NOT NULL,
  "description" TEXT,
  "max_points" NUMERIC(10,2) NOT NULL,
  "display_order" INTEGER NOT NULL DEFAULT 0,
  "active" BOOLEAN NOT NULL DEFAULT TRUE,
  "created_by" UUID,
  "modified_by" UUID,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "modified_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT "camporee_event_rubrics_event_fkey"
    FOREIGN KEY ("camporee_event_id")
    REFERENCES "camporee_events"("camporee_event_id")
    ON DELETE CASCADE,
  CONSTRAINT "camporee_event_rubrics_max_points_check"
    CHECK ("max_points" > 0)
);

CREATE INDEX "idx_camporee_event_rubrics_event_active"
  ON "camporee_event_rubrics"("camporee_event_id", "active", "display_order");

CREATE TABLE "camporee_judges" (
  "camporee_judge_id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "local_camporee_id" INTEGER,
  "union_camporee_id" INTEGER,
  "user_id" UUID NOT NULL,
  "status" VARCHAR(20) NOT NULL DEFAULT 'active',
  "notes" TEXT,
  "active" BOOLEAN NOT NULL DEFAULT TRUE,
  "created_by" UUID,
  "modified_by" UUID,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "modified_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT "camporee_judges_scope_check"
    CHECK (
      ("local_camporee_id" IS NOT NULL AND "union_camporee_id" IS NULL)
      OR
      ("local_camporee_id" IS NULL AND "union_camporee_id" IS NOT NULL)
    ),
  CONSTRAINT "camporee_judges_local_fkey"
    FOREIGN KEY ("local_camporee_id") REFERENCES "local_camporees"("local_camporee_id") ON DELETE CASCADE,
  CONSTRAINT "camporee_judges_union_fkey"
    FOREIGN KEY ("union_camporee_id") REFERENCES "union_camporees"("union_camporee_id") ON DELETE CASCADE,
  CONSTRAINT "camporee_judges_user_fkey"
    FOREIGN KEY ("user_id") REFERENCES "users"("user_id") ON DELETE NO ACTION
);

CREATE UNIQUE INDEX "uq_camporee_judges_local_user_active"
  ON "camporee_judges"("local_camporee_id", "user_id")
  WHERE "active" = TRUE AND "local_camporee_id" IS NOT NULL;

CREATE UNIQUE INDEX "uq_camporee_judges_union_user_active"
  ON "camporee_judges"("union_camporee_id", "user_id")
  WHERE "active" = TRUE AND "union_camporee_id" IS NOT NULL;

CREATE TABLE "camporee_event_judge_assignments" (
  "camporee_event_judge_assignment_id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "camporee_event_id" INTEGER NOT NULL,
  "camporee_judge_id" UUID NOT NULL,
  "camporee_club_id" INTEGER,
  "club_section_id" INTEGER NOT NULL,
  "judge_role" VARCHAR(20) NOT NULL,
  "active" BOOLEAN NOT NULL DEFAULT TRUE,
  "created_by" UUID,
  "modified_by" UUID,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "modified_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT "camporee_event_judge_assignments_role_check"
    CHECK ("judge_role" IN ('primary', 'assistant')),
  CONSTRAINT "camporee_event_judge_assignments_event_fkey"
    FOREIGN KEY ("camporee_event_id") REFERENCES "camporee_events"("camporee_event_id") ON DELETE CASCADE,
  CONSTRAINT "camporee_event_judge_assignments_judge_fkey"
    FOREIGN KEY ("camporee_judge_id") REFERENCES "camporee_judges"("camporee_judge_id") ON DELETE CASCADE,
  CONSTRAINT "camporee_event_judge_assignments_camporee_club_fkey"
    FOREIGN KEY ("camporee_club_id") REFERENCES "camporee_clubs"("camporee_club_id") ON DELETE SET NULL,
  CONSTRAINT "camporee_event_judge_assignments_section_fkey"
    FOREIGN KEY ("club_section_id") REFERENCES "club_sections"("club_section_id") ON DELETE NO ACTION
);

CREATE UNIQUE INDEX "uq_camporee_event_primary_judge_section"
  ON "camporee_event_judge_assignments"("camporee_event_id", "club_section_id")
  WHERE "active" = TRUE AND "judge_role" = 'primary';

CREATE INDEX "idx_camporee_event_judge_assignments_judge"
  ON "camporee_event_judge_assignments"("camporee_judge_id", "active");

CREATE TABLE "camporee_event_score_submissions" (
  "camporee_event_score_submission_id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "camporee_event_id" INTEGER NOT NULL,
  "camporee_club_id" INTEGER,
  "club_section_id" INTEGER NOT NULL,
  "judge_assignment_id" UUID,
  "submitted_by" UUID NOT NULL,
  "source" VARCHAR(30) NOT NULL,
  "status" VARCHAR(20) NOT NULL DEFAULT 'submitted',
  "total_awarded_points" NUMERIC(10,2) NOT NULL DEFAULT 0,
  "total_max_points" NUMERIC(10,2) NOT NULL DEFAULT 0,
  "notes" TEXT,
  "voided_reason" TEXT,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "modified_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT "camporee_event_score_submissions_source_check"
    CHECK ("source" IN ('judge_primary', 'manual_lf', 'admin_override')),
  CONSTRAINT "camporee_event_score_submissions_status_check"
    CHECK ("status" IN ('submitted', 'voided')),
  CONSTRAINT "camporee_event_score_submissions_event_fkey"
    FOREIGN KEY ("camporee_event_id") REFERENCES "camporee_events"("camporee_event_id") ON DELETE CASCADE,
  CONSTRAINT "camporee_event_score_submissions_camporee_club_fkey"
    FOREIGN KEY ("camporee_club_id") REFERENCES "camporee_clubs"("camporee_club_id") ON DELETE SET NULL,
  CONSTRAINT "camporee_event_score_submissions_section_fkey"
    FOREIGN KEY ("club_section_id") REFERENCES "club_sections"("club_section_id") ON DELETE NO ACTION,
  CONSTRAINT "camporee_event_score_submissions_assignment_fkey"
    FOREIGN KEY ("judge_assignment_id") REFERENCES "camporee_event_judge_assignments"("camporee_event_judge_assignment_id") ON DELETE SET NULL,
  CONSTRAINT "camporee_event_score_submissions_submitter_fkey"
    FOREIGN KEY ("submitted_by") REFERENCES "users"("user_id") ON DELETE NO ACTION
);

CREATE INDEX "idx_camporee_event_score_submissions_event_section"
  ON "camporee_event_score_submissions"("camporee_event_id", "club_section_id", "created_at");

CREATE TABLE "camporee_event_score_submission_items" (
  "camporee_event_score_submission_item_id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "camporee_event_score_submission_id" UUID NOT NULL,
  "camporee_event_rubric_id" INTEGER NOT NULL,
  "awarded_points" NUMERIC(10,2) NOT NULL,
  "notes" TEXT,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT "camporee_event_score_submission_items_points_check"
    CHECK ("awarded_points" >= 0),
  CONSTRAINT "camporee_event_score_submission_items_submission_fkey"
    FOREIGN KEY ("camporee_event_score_submission_id")
    REFERENCES "camporee_event_score_submissions"("camporee_event_score_submission_id")
    ON DELETE CASCADE,
  CONSTRAINT "camporee_event_score_submission_items_rubric_fkey"
    FOREIGN KEY ("camporee_event_rubric_id")
    REFERENCES "camporee_event_rubrics"("camporee_event_rubric_id")
    ON DELETE NO ACTION
);

CREATE UNIQUE INDEX "uq_camporee_score_submission_item_rubric"
  ON "camporee_event_score_submission_items"(
    "camporee_event_score_submission_id",
    "camporee_event_rubric_id"
  );

CREATE TABLE "camporee_event_section_results" (
  "camporee_event_section_result_id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "camporee_event_id" INTEGER NOT NULL,
  "camporee_club_id" INTEGER,
  "club_section_id" INTEGER NOT NULL,
  "source_submission_id" UUID NOT NULL,
  "total_awarded_points" NUMERIC(10,2) NOT NULL,
  "total_max_points" NUMERIC(10,2) NOT NULL,
  "percentage" NUMERIC(5,2) NOT NULL,
  "finalized_by" UUID NOT NULL,
  "finalized_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "active" BOOLEAN NOT NULL DEFAULT TRUE,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "modified_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT "camporee_event_section_results_event_fkey"
    FOREIGN KEY ("camporee_event_id") REFERENCES "camporee_events"("camporee_event_id") ON DELETE CASCADE,
  CONSTRAINT "camporee_event_section_results_camporee_club_fkey"
    FOREIGN KEY ("camporee_club_id") REFERENCES "camporee_clubs"("camporee_club_id") ON DELETE SET NULL,
  CONSTRAINT "camporee_event_section_results_section_fkey"
    FOREIGN KEY ("club_section_id") REFERENCES "club_sections"("club_section_id") ON DELETE NO ACTION,
  CONSTRAINT "camporee_event_section_results_submission_fkey"
    FOREIGN KEY ("source_submission_id")
    REFERENCES "camporee_event_score_submissions"("camporee_event_score_submission_id")
    ON DELETE NO ACTION,
  CONSTRAINT "camporee_event_section_results_finalizer_fkey"
    FOREIGN KEY ("finalized_by") REFERENCES "users"("user_id") ON DELETE NO ACTION
);

CREATE UNIQUE INDEX "uq_camporee_event_section_results_active"
  ON "camporee_event_section_results"("camporee_event_id", "club_section_id")
  WHERE "active" = TRUE;
```

**Prisma model requirements:**

- Add `scoring_enabled Boolean @default(false)` to `camporee_events`.
- Add relations from `camporee_events`, `users`, `club_sections`, `camporee_clubs`, `local_camporees`, `union_camporees`.
- Use Prisma model names matching existing style where current tables use snake_case models.

**Verification:**

Run only schema-related tests, no build:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec prisma validate
```

Expected: Prisma schema validates.

---

## Fase 2 — Backend domain service

### Task 2: Crear módulo `camporee-scoring`

**Files:**

- Create: `sacdia-backend/src/camporee-scoring/camporee-scoring.module.ts`
- Create: `sacdia-backend/src/camporee-scoring/camporee-scoring.service.ts`
- Create: `sacdia-backend/src/camporee-scoring/camporee-scoring.controller.ts`
- Create: `sacdia-backend/src/camporee-scoring/dto/camporee-scoring.dto.ts`
- Create: `sacdia-backend/src/camporee-scoring/camporee-scoring.service.spec.ts`
- Modify: `sacdia-backend/src/app.module.ts`

**Service responsibilities:**

- Resolve camporee scope from `camporee_event_id`.
- Validate event belongs to local or union camporee.
- Validate section is enrolled in the camporee through `camporee_clubs` when scoring.
- Replace rubrics transactionally and validate sum equals `camporee_events.max_points`.
- Manage judge roster for local/union camporee.
- Manage judge assignments for event + section.
- Enforce one active primary judge per event/section.
- Submit score by rubric.
- Upsert official result per event/section.
- Compute camporee leaderboard.

**Core service signatures:**

```ts
async replaceEventRubrics(
  eventId: number,
  dto: ReplaceCamporeeEventRubricsDto,
  actorUserId: string,
): Promise<CamporeeEventRubricResponseDto[]>

async addJudgeToCamporee(
  scope: { type: 'local' | 'union'; camporeeId: number },
  dto: AddCamporeeJudgeDto,
  actorUserId: string,
): Promise<CamporeeJudgeResponseDto>

async assignJudgeToSection(
  eventId: number,
  dto: AssignCamporeeEventJudgeDto,
  actorUserId: string,
): Promise<CamporeeEventJudgeAssignmentResponseDto>

async submitScore(
  eventId: number,
  clubSectionId: number,
  dto: SubmitCamporeeEventScoreDto,
  actorUserId: string,
): Promise<CamporeeEventSectionResultResponseDto>

async getCamporeeLeaderboard(
  scope: { type: 'local' | 'union'; camporeeId: number },
): Promise<CamporeeLeaderboardResponseDto>
```

**DTO validation:**

- `ReplaceCamporeeEventRubricsDto.items` non-empty when `scoring_enabled=true`.
- `max_points > 0`.
- `awarded_points >= 0`.
- `awarded_points <= rubric.max_points`.
- Submitted score must include exactly one item per active rubric.

**Tests first:**

Create tests for:

- Reject scoring event without rubrics.
- Reject rubric sum different from event max points.
- Reject assistant judge score submission.
- Allow primary judge score submission.
- Allow `assistant-lf/director-lf` manual score without assignment.
- Upsert latest official result for event/section.
- Leaderboard sums results by section and sorts descending.

**Run:**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm test -- camporee-scoring.service.spec.ts --runInBand
```

Expected: targeted unit tests pass.

### Task 3: Agregar endpoints REST

**Files:**

- Modify: `sacdia-backend/src/camporee-scoring/camporee-scoring.controller.ts`
- Modify: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- Modify: `docs/features/camporee-events.md`
- Modify: `docs/features/camporees.md`

**Endpoints:**

```txt
GET  /api/v1/camporee-events/:eventId/rubrics
PUT  /api/v1/camporee-events/:eventId/rubrics

GET  /api/v1/local-camporees/:camporeeId/judges
POST /api/v1/local-camporees/:camporeeId/judges
GET  /api/v1/union-camporees/:camporeeId/judges
POST /api/v1/union-camporees/:camporeeId/judges

GET  /api/v1/camporee-events/:eventId/judge-assignments
POST /api/v1/camporee-events/:eventId/judge-assignments
PATCH /api/v1/camporee-event-judge-assignments/:assignmentId
DELETE /api/v1/camporee-event-judge-assignments/:assignmentId

GET  /api/v1/camporee-events/:eventId/scoring-targets
POST /api/v1/camporee-events/:eventId/sections/:clubSectionId/scores

GET  /api/v1/local-camporees/:camporeeId/leaderboard
GET  /api/v1/union-camporees/:camporeeId/leaderboard

GET  /api/v1/camporee-judges/me/assignments
```

**Authorization:**

- Rubrics/read/leaderboard: `camporee_events:read`.
- Rubrics/write, judge roster, assignments: `camporee_events:update`.
- Manual LF score: `camporee_events:update` scoped to local field/union camporee.
- Judge app score: allowed only if the actor is the active primary judge for that event/section.

**Run:**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm test -- camporee-scoring.controller.spec.ts --runInBand
```

Expected: controller authorization and DTO tests pass.

---

## Fase 3 — Integración con ranking anual

### Task 4: Reemplazar asistencia por resultados oficiales

**Files:**

- Modify: `sacdia-backend/src/annual-folders/score-calculators/camporee-score.ts`
- Modify: `sacdia-backend/src/annual-folders/score-calculators/camporee-score.spec.ts`
- Modify: `sacdia-backend/src/rankings/annual-ranking-progress/services/annual-ranking-score-registry.service.ts`
- Modify: `sacdia-backend/src/rankings/annual-ranking-progress/services/annual-ranking-score-registry.service.spec.ts`
- Modify: `sacdia-backend/src/rankings/annual-ranking-progress/annual-ranking-progress.service.ts`
- Modify: `sacdia-backend/src/rankings/annual-ranking-progress/annual-rankings.service.ts`
- Modify: `docs/features/annual-folders-scoring.md`

**Required change:**

`AnnualRankingScoreContext` must include:

```ts
clubSectionId: number;
```

`camporee_events` component must calculate:

```txt
sum(active camporee_event_section_results.total_awarded_points)
/
sum(scoring_enabled camporee_events.max_points in scope)
* 100
```

**Important denominator rule:**

- Denominator includes scoring-enabled events in active camporees in the section scope.
- Results missing for a section count as zero.
- Attendance records are not awarded points.

**Tests first:**

- Section with two results over three scoring events gets correct percentage.
- Missing result contributes zero.
- Non-scoring event ignored.
- `camporee_clubs` attendance without result gives zero points.

**Run:**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm test -- camporee-score.spec.ts annual-ranking-score-registry.service.spec.ts --runInBand
```

Expected: score no longer depends on `camporee_clubs.status`.

### Task 5: Ajustar ranking de miembros

**Files:**

- Modify: `sacdia-backend/src/rankings/member-rankings/services/camporee-score.service.ts`
- Modify: `sacdia-backend/src/rankings/member-rankings/services/camporee-score.service.spec.ts`

**Decision:**

Member camporee score should inherit the score of the member's active club section for the ecclesiastical year. It must not use personal attendance.

**Run:**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm test -- rankings/member-rankings/services/camporee-score.service.spec.ts --runInBand
```

Expected: member score uses section results, not `camporee_members`.

---

## Fase 4 — Admin contracts y UI

### Task 6: Agregar cliente API admin

**Files:**

- Create: `sacdia-admin/src/lib/api/camporee-scoring.ts`
- Create: `sacdia-admin/src/lib/camporee-scoring/actions.ts`
- Modify: `sacdia-admin/src/lib/api/camporee-events.ts`

**Types:**

```ts
export interface CamporeeEventRubric {
  camporee_event_rubric_id: number;
  camporee_event_id: number;
  title: string;
  description: string | null;
  max_points: number;
  display_order: number;
  active: boolean;
}

export interface CamporeeJudge {
  camporee_judge_id: string;
  user_id: string;
  name: string;
  status: string;
  active: boolean;
}

export interface CamporeeEventJudgeAssignment {
  camporee_event_judge_assignment_id: string;
  camporee_event_id: number;
  camporee_judge_id: string;
  club_section_id: number;
  judge_role: 'primary' | 'assistant';
  active: boolean;
}

export interface CamporeeEventScoreInput {
  source: 'manual_lf' | 'admin_override';
  notes?: string;
  items: Array<{
    camporee_event_rubric_id: number;
    awarded_points: number;
    notes?: string;
  }>;
}
```

**Run:**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-admin
pnpm test -- camporee
```

Expected: existing camporee tests still pass after type additions.

### Task 7: Editor de rúbricas en eventos

**Files:**

- Create: `sacdia-admin/src/components/camporee-events/rubrics-editor.tsx`
- Modify: `sacdia-admin/src/components/camporee-events/event-form-page.tsx`
- Modify: `sacdia-admin/src/components/camporee-events/event-template-form-page.tsx`
- Modify: `sacdia-admin/src/app/(dashboard)/dashboard/camporees/[id]/events/new/page.tsx`
- Modify: `sacdia-admin/src/app/(dashboard)/dashboard/camporees/[id]/events/[eventId]/edit/page.tsx`

**UI rules:**

- Add `scoring_enabled` switch.
- When enabled, show rubric rows.
- Show live sum:

```txt
Rúbricas: 80 / 100 puntos
```

- Block submit when sum differs from event `max_points`.

**Tests:**

- Component rejects save when sum mismatch.
- Component accepts when sum equals max points.

**Run:**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-admin
pnpm test -- rubrics-editor
```

### Task 8: Panel de jueces y asignaciones

**Files:**

- Create: `sacdia-admin/src/components/camporee-scoring/camporee-judges-panel.tsx`
- Create: `sacdia-admin/src/components/camporee-scoring/event-judge-assignments-panel.tsx`
- Modify: `sacdia-admin/src/components/camporee-events/camporee-events-tab.tsx`

**UI rules:**

- Camporee detail shows judges roster.
- Event row opens assignments drawer/panel.
- Per event/section:
  - select primary judge
  - select assistant judges
- UI prevents choosing two primary judges.

**Run:**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-admin
pnpm test -- camporee-judges-panel
```

### Task 9: Captura manual de puntajes y leaderboard

**Files:**

- Create: `sacdia-admin/src/components/camporee-scoring/event-score-entry-panel.tsx`
- Create: `sacdia-admin/src/components/camporee-scoring/camporee-leaderboard.tsx`
- Modify: `sacdia-admin/src/components/camporee-events/camporee-events-tab.tsx`
- Modify: `sacdia-admin/src/components/camporees/camporee-detail-tabs.tsx`

**UI rules:**

- `assistant-lf/director-lf` can enter scores by rubric.
- Total is calculated, not typed.
- Leaderboard shows:
  - rank
  - club
  - section
  - earned points
  - max points
  - percentage

**Run:**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-admin
pnpm test -- event-score-entry-panel camporee-leaderboard
```

---

## Fase 5 — App juez

### Task 10: Modelos y datasource móvil

**Files:**

- Create: `sacdia-app/lib/features/camporees/domain/entities/camporee_judge_assignment.dart`
- Create: `sacdia-app/lib/features/camporees/domain/entities/camporee_rubric.dart`
- Create: `sacdia-app/lib/features/camporees/domain/entities/camporee_score_submission.dart`
- Create: `sacdia-app/lib/features/camporees/data/models/camporee_judge_assignment_model.dart`
- Create: `sacdia-app/lib/features/camporees/data/models/camporee_rubric_model.dart`
- Modify: `sacdia-app/lib/features/camporees/domain/repositories/camporees_repository.dart`
- Modify: `sacdia-app/lib/features/camporees/data/repositories/camporees_repository_impl.dart`
- Modify: `sacdia-app/lib/features/camporees/data/datasources/camporees_remote_data_source.dart`

**Endpoints consumed:**

```txt
GET  /api/v1/camporee-judges/me/assignments
GET  /api/v1/camporee-events/:eventId/rubrics
POST /api/v1/camporee-events/:eventId/sections/:clubSectionId/scores
```

**Run:**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app
flutter test test/features/camporees
```

### Task 11: UI móvil para juez principal

**Files:**

- Create: `sacdia-app/lib/features/camporees/presentation/views/judge_assignments_view.dart`
- Create: `sacdia-app/lib/features/camporees/presentation/views/judge_score_entry_view.dart`
- Modify: `sacdia-app/lib/features/camporees/presentation/providers/camporees_providers.dart`
- Modify: `sacdia-app/lib/core/navigation/app_router.dart`

**UI rules:**

- Show only assignments where current user is primary judge.
- Helpers do not see submit button.
- Score entry uses rubric fields.
- Submit sends one item per rubric.

**Run:**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app
flutter test test/features/camporees
```

---

## Fase 6 — Documentación y cierre

### Task 12: Actualizar documentación canónica operativa

**Files:**

- Modify: `docs/features/camporees.md`
- Modify: `docs/features/camporee-events.md`
- Modify: `docs/features/annual-folders-scoring.md`
- Modify: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- Modify: `docs/api/FRONTEND-INTEGRATION-GUIDE.md`
- Modify: `docs/database/schema.prisma`
- Modify: `docs/database/SCHEMA-REFERENCE.md`

**Required doc updates:**

- Attendance no longer scores ranking annual.
- `camporee_events` formula becomes official rubric score.
- Document judge principal/helper rule.
- Document manual LF scoring.
- Document leaderboard endpoints.
- Document app judge endpoints.

### Task 13: Targeted verification

**Do not run builds unless explicitly requested.**

Run targeted checks only:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm test -- camporee-scoring.service.spec.ts camporee-score.spec.ts annual-ranking-score-registry.service.spec.ts --runInBand
```

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-admin
pnpm test -- camporee
```

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app
flutter test test/features/camporees
```

Expected:

- Backend scoring rules pass.
- Admin rubric/judge UI tests pass.
- App judge scoring tests pass.

---

## Suggested commit slices

Use conventional commits only. No `Co-Authored-By`.

```bash
git commit -m "feat: add camporee rubric scoring schema"
git commit -m "feat: add camporee scoring backend"
git commit -m "feat: score annual camporee rankings from results"
git commit -m "feat: add camporee scoring admin UI"
git commit -m "feat: add camporee judge scoring app flow"
git commit -m "docs: document camporee scoring workflow"
```

---

## Known risks

- Current `camporee_events` ranking component name stays the same but semantics change from attendance to official scoring.
- Existing annual ranking snapshots may change after recalculation.
- Union camporee admin detail support may require additional route work if scoring UI must be available for union camporees beyond the current list page.
- Eligibility by section/type must be enforced carefully so sections are not penalized for events that do not apply to them.

