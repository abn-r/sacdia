# Annual Ranking Domain Alignment Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Align SACDIA annual ranking terminology around "Carpeta Anual de Evidencias" and evolve rankings into configurable administrative/operational axes with equal default weight.

**Architecture:** Keep existing physical `annual_folders` tables for compatibility, but introduce canonical user-facing terminology and component aliases. Extend annual ranking configuration with axis budgets so each local field/year/club type can configure administrative and operational scoring while preserving current configs through migration.

**Tech Stack:** NestJS 11 + Prisma 7 + PostgreSQL, Next.js 16 + React 19, Flutter + Riverpod + Dio, REST `/api/v1`, project docs under `/Users/abner/Documents/development/sacdia/docs`.

---

## Guardrails

- Do **not** run builds unless the user explicitly asks.
- Do not touch unrelated dirty files.
- Do not commit unless explicitly asked.
- Use TDD for calculation/config behavior.
- Keep existing ranking endpoints working during migration.
- Keep DB physical table names `annual_folders` for now.
- Update docs in the same work unit as behavior/schema/API changes.

## Task 1: Backend constants for canonical ranking components

**Files:**

- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/rankings/annual-ranking-progress/ranking-component-catalog.ts`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/rankings/annual-ranking-progress/ranking-component-catalog.spec.ts`

**Step 1: Write failing tests**

Cover:

- `annual_folder` normalizes to `annual_evidence_folder`;
- `finance` normalizes to `finance_compliance`;
- `camporee` normalizes to `camporee_events`;
- unknown component keys are rejected;
- component keys map to exactly one axis.

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/rankings/annual-ranking-progress/ranking-component-catalog.spec.ts --runInBand
```

Expected: FAIL because catalog does not exist.

**Step 2: Implement catalog**

Create canonical constants:

- axes: `administrative`, `operational`;
- components:
  - `annual_evidence_folder` → administrative;
  - `monthly_reports_timeliness` → administrative;
  - `finance_compliance` → administrative;
  - `institutional_data_completeness` → administrative;
  - `activities_registered` → operational;
  - `attendance_participation` → operational;
  - `camporee_events` → operational;
  - `class_investiture_progress` → operational;
  - `sacdia_operational_usage` → operational.

Legacy aliases:

- `annual_folder` → `annual_evidence_folder`;
- `finance` → `finance_compliance`;
- `camporee` → `camporee_events`.

**Step 3: Re-run test**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/rankings/annual-ranking-progress/ranking-component-catalog.spec.ts --runInBand
```

Expected: PASS.

## Task 2: Prisma schema for ranking axes

**Files:**

- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/prisma/schema.prisma`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/prisma/migrations/<timestamp>_annual_ranking_axes/migration.sql`
- Modify: `/Users/abner/Documents/development/sacdia/docs/database/SCHEMA-REFERENCE.md`

**Step 1: Add migration SQL**

Create table:

```sql
CREATE TABLE annual_ranking_axis_configs (
  annual_ranking_axis_config_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  annual_ranking_config_id UUID NOT NULL REFERENCES annual_ranking_configs(annual_ranking_config_id) ON DELETE CASCADE,
  axis_key VARCHAR(50) NOT NULL,
  label VARCHAR(120) NOT NULL,
  max_points INTEGER NOT NULL CHECK (max_points > 0),
  sort_order INTEGER NOT NULL DEFAULT 0,
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
  UNIQUE (annual_ranking_config_id, axis_key)
);
```

Add nullable FK to existing component table first:

```sql
ALTER TABLE annual_ranking_component_configs
  ADD COLUMN annual_ranking_axis_config_id UUID NULL;
```

Backfill axes for existing configs:

- `administrative` gets existing `annual_folder` + `finance`;
- `operational` gets existing `camporee`;
- preserve existing component max points;
- if existing component key is unknown, map to `administrative` only if product confirms; otherwise leave inactive/manual remediation.

Then enforce FK:

```sql
ALTER TABLE annual_ranking_component_configs
  ADD CONSTRAINT annual_ranking_component_configs_axis_fkey
  FOREIGN KEY (annual_ranking_axis_config_id)
  REFERENCES annual_ranking_axis_configs(annual_ranking_axis_config_id)
  ON DELETE CASCADE;
```

Only set `NOT NULL` after all existing rows are backfilled.

**Step 2: Update Prisma models**

Add model for `annual_ranking_axis_configs` and relation from components.

**Step 3: Update schema reference**

Document:

- axis configs;
- component configs belong to an axis;
- sum validation remains service-level because it spans multiple rows.

**Step 4: Do not run build**

If Prisma client generation is necessary later, run only:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec prisma generate
```

Expected: Prisma client updates; no app build.

## Task 3: Backend config validation by axes

**Files:**

- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/rankings/annual-ranking-progress/annual-ranking-config.service.ts`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/rankings/annual-ranking-progress/annual-ranking-config.service.spec.ts`
- Modify DTOs under: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/rankings/annual-ranking-progress/dto/`

**Step 1: Write failing tests**

Cover:

- default config with 10,000 points accepts administrative=5,000 and operational=5,000;
- rejects axis sum different from config max;
- rejects component sum different from axis max;
- rejects unknown component key;
- accepts legacy aliases and persists canonical keys;
- rejects duplicate component key across axes.

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/rankings/annual-ranking-progress/annual-ranking-config.service.spec.ts --runInBand
```

Expected: FAIL.

**Step 2: Update DTO shape**

Target create/update payload:

```json
{
  "local_field_id": 4,
  "ecclesiastical_year_id": 1,
  "club_type_id": 2,
  "max_points": 10000,
  "axes": [
    {
      "axis_key": "administrative",
      "label": "Cumplimiento Administrativo",
      "max_points": 5000,
      "components": []
    },
    {
      "axis_key": "operational",
      "label": "Vida Operativa del Club",
      "max_points": 5000,
      "components": []
    }
  ]
}
```

**Step 3: Implement validation**

Rules:

- active axis sum = config `max_points`;
- component sum per axis = axis `max_points`;
- component keys normalized through catalog;
- unknown keys return `ANNUAL_RANKING_COMPONENT_UNKNOWN`;
- invalid sums return existing or new domain error.

**Step 4: Re-run tests**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/rankings/annual-ranking-progress/annual-ranking-config.service.spec.ts --runInBand
```

Expected: PASS.

## Task 4: Score calculator registry with safe fallbacks

**Files:**

- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/rankings/annual-ranking-progress/services/annual-ranking-score-registry.service.ts`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/rankings/annual-ranking-progress/services/annual-ranking-score-registry.service.spec.ts`
- Reuse or adapt calculators under: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/annual-folders/score-calculators/`

**Step 1: Write failing tests**

Cover:

- `annual_evidence_folder` uses annual folder percentage;
- legacy `annual_folder` resolves to same calculator;
- `finance_compliance` resolves finance calculator;
- `camporee_events` resolves camporee calculator;
- disabled or unsupported components return explicit `0` with `source_status='not_available'`, not silent success.

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/rankings/annual-ranking-progress/services/annual-ranking-score-registry.service.spec.ts --runInBand
```

Expected: FAIL.

**Step 2: Implement registry**

Initial source-backed calculators:

- `annual_evidence_folder`;
- `finance_compliance`;
- `camporee_events`;
- `monthly_reports_timeliness` if existing `monthly_reports` fields support deadline;
- other operational components may be marked `not_available` until their source definition is implemented.

**Step 3: Fix annual folder source**

Prefer persisted `annual_folders.progress_percentage` or a calculation that uses the full template max denominator. Avoid a denominator of only `VALIDATED` rows because it can overstate progress when some sections are rejected/pending.

**Step 4: Re-run tests**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/rankings/annual-ranking-progress/services/annual-ranking-score-registry.service.spec.ts --runInBand
```

Expected: PASS.

## Task 5: Extend progress and leaderboard DTOs with axes

**Files:**

- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/rankings/annual-ranking-progress/annual-ranking-progress.service.ts`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/rankings/annual-ranking-progress/annual-rankings.service.ts`
- Modify DTOs under: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/rankings/annual-ranking-progress/dto/`
- Modify tests:
  - `/Users/abner/Documents/development/sacdia/sacdia-backend/src/rankings/annual-ranking-progress/annual-ranking-progress.service.spec.ts`
  - `/Users/abner/Documents/development/sacdia/sacdia-backend/src/rankings/annual-ranking-progress/annual-rankings.service.spec.ts`

**Step 1: Write failing response-shape tests**

Expected new response includes:

- `axes[]`;
- each axis has `key`, `label`, `earned_points`, `max_points`, `progress_percentage`, `components[]`;
- legacy `components[]` remains temporarily for compatibility if mobile/admin still consume it.

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/rankings/annual-ranking-progress/annual-ranking-progress.service.spec.ts src/rankings/annual-ranking-progress/annual-rankings.service.spec.ts --runInBand
```

Expected: FAIL.

**Step 2: Implement axis aggregation**

For each configured axis:

```text
component score pct -> component points
axis points = SUM(component points)
total points = SUM(axis points)
```

Rank leaderboard by `total_points DESC`.

**Step 3: Re-run tests**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/rankings/annual-ranking-progress/annual-ranking-progress.service.spec.ts src/rankings/annual-ranking-progress/annual-rankings.service.spec.ts --runInBand
```

Expected: PASS.

## Task 6: Admin configuration UI for axes/components

**Files:**

- Modify or create under: `/Users/abner/Documents/development/sacdia/sacdia-admin/src/`
- Update i18n messages under: `/Users/abner/Documents/development/sacdia/sacdia-admin/src/i18n/`

**Step 1: Add tests or component-level coverage where current admin test pattern exists**

Cover:

- renders two default axes;
- prevents saving when axis sum != annual max;
- prevents saving when component sum != axis max;
- displays canonical "Carpeta Anual de Evidencias".

**Step 2: Update form**

Admin form should show:

```text
Max anual
Eje Administrativo
  Componentes...
Eje Operativo
  Componentes...
```

**Step 3: Run targeted tests**

Use the existing admin test command for the touched area. Do not run build unless explicitly requested.

## Task 7: Mobile scorecard UI with axes

**Files:**

- Modify: `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/rankings/`
- Modify tests under: `/Users/abner/Documents/development/sacdia/sacdia-app/test/features/rankings/`
- Update app strings/assets as needed.

**Step 1: Write failing widget/model tests**

Cover:

- parses `axes[]`;
- displays "Cumplimiento Administrativo";
- displays "Vida Operativa del Club";
- displays "Carpeta Anual de Evidencias";
- does not show competitive leaderboard in app.

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app
flutter test test/features/rankings
```

Expected: FAIL until models/UI are updated.

**Step 2: Implement minimal model/UI updates**

Keep UX focused on the user's own section progress.

**Step 3: Re-run targeted tests**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app
flutter test test/features/rankings
```

Expected: PASS.

## Task 8: Unified naming sweep

**Files:**

- Modify docs:
  - `/Users/abner/Documents/development/sacdia/docs/canon/runtime-rankings.md`
  - `/Users/abner/Documents/development/sacdia/docs/features/annual-folders-scoring.md`
  - `/Users/abner/Documents/development/sacdia/docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- Modify app/admin i18n strings.
- Avoid physical DB table renames.

**Step 1: Search terms**

Run:

```bash
cd /Users/abner/Documents/development/sacdia
rg -n "annual folder|annual_folder|carpeta de evidencias|carpeta anual" docs sacdia-admin/src sacdia-app/lib sacdia-backend/src
```

**Step 2: Update user-facing text**

Use "Carpeta Anual de Evidencias".

**Step 3: Preserve code aliases where needed**

Do not break current DTOs until all clients are updated.

## Task 9: Regression audit script

**Files:**

- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/scripts/audit-annual-ranking-alignment.ts`
- Add docs usage to: `/Users/abner/Documents/development/sacdia/docs/canon/runtime-rankings.md`

**Step 1: Implement read-only checks**

Checks:

- each active annual ranking config has active axes;
- axis sums equal config max;
- component sums equal axis max;
- all component keys are canonical or accepted legacy aliases;
- folder template section max sum matches evaluation eager row max sum per folder;
- no active config has orphan components without axis.

**Step 2: Run read-only audit in dry run**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec tsx scripts/audit-annual-ranking-alignment.ts --dry-run
```

Expected: report only; no writes.

## Task 10: Final verification

**Backend targeted tests:**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/rankings/annual-ranking-progress --runInBand
```

**Mobile targeted tests:**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app
flutter test test/features/rankings
```

**Diff check:**

```bash
cd /Users/abner/Documents/development/sacdia
git diff --check
```

Do not run builds unless the user explicitly asks.

## Open decisions before implementation

1. Exact formula for `monthly_reports_timeliness`.
2. Canonical source for attendance/participation.
3. Whether phase 1 ships only source-backed components and marks the rest disabled, or implements all components at once.
4. Whether admin should allow arbitrary custom component labels or only canonical component keys.

