# Annual Ranking Scorecard Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Convert SACDIA annual rankings into a points-based recognition system where mobile shows only the active section's annual progress and admin keeps the full leaderboard.

**Architecture:** Add shared backend calculation services for global percentage tiers, local-field annual point budgets, and derived progress summaries. Mobile consumes a compact section-scoped scorecard endpoint; admin manages configuration and consumes a leaderboard endpoint.

**Tech Stack:** NestJS 11 + Prisma 7 + PostgreSQL, Next.js 16 + React 19 + shadcn/ui, Flutter + Riverpod + Dio, REST `/api/v1`.

---

## Guardrails

- Do **not** run builds unless the user explicitly asks.
- Do not commit unrelated dirty files.
- Keep current legacy ranking endpoint working until the new admin path is validated.
- Use TDD for calculation services and API authorization.
- Update docs in the same work unit when API/schema/UI behavior changes.

## Task 1: Backend tier calculation tests

**Files:**

- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/rankings/annual-ranking-progress/services/ranking-tier-calculator.service.spec.ts`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/rankings/annual-ranking-progress/services/ranking-tier-calculator.service.ts`

**Step 1: Write failing tests**

Cover:

- max `10000`, tiers `5%`, `10%`, `15%`;
- Diamante = `9500–10000`;
- Oro = `8500–9499`;
- Plata = `7000–8499`;
- exact boundary `9500` maps to Diamante;
- exact boundary `9499` maps to Oro;
- `points_to_next_tier` for `8450` is `50`.

**Step 2: Run failing test**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/rankings/annual-ranking-progress/services/ranking-tier-calculator.service.spec.ts --runInBand
```

Expected: FAIL because the service does not exist.

**Step 3: Implement minimal service**

Implement pure calculation with no Prisma dependency:

- input: `maxPoints`, ordered tiers with `bandPercentage`;
- output: derived ranges and current/next tier;
- use integer-safe boundaries to avoid overlaps.

**Step 4: Re-run test**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/rankings/annual-ranking-progress/services/ranking-tier-calculator.service.spec.ts --runInBand
```

Expected: PASS.

**Step 5: Commit**

```bash
git add sacdia-backend/src/rankings/annual-ranking-progress/services/ranking-tier-calculator.service.ts sacdia-backend/src/rankings/annual-ranking-progress/services/ranking-tier-calculator.service.spec.ts
git commit -m "feat: add annual ranking tier calculation"
```

## Task 2: Prisma schema for ranking tiers and local annual configs

**Files:**

- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/prisma/schema.prisma`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/prisma/migrations/<timestamp>_annual_ranking_scorecard/migration.sql`
- Modify: `/Users/abner/Documents/development/sacdia/docs/database/SCHEMA-REFERENCE.md`

**Step 1: Add schema models**

Add:

- `ranking_tiers`
- `annual_ranking_configs`
- `annual_ranking_component_configs`

Constraints:

- unique tier slug;
- unique annual config by `(local_field_id, ecclesiastical_year_id, club_type_id)`;
- unique component by `(annual_ranking_config_id, component_key)`.

**Step 2: Add migration SQL**

Use PostgreSQL constraints for:

- positive percentages;
- positive max points;
- FK cascade from annual config to component config.

**Step 3: Validate Prisma generation only if needed**

If code generation is required by Prisma after schema changes, run the narrow command only:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec prisma generate
```

Do not run build.

**Step 4: Commit**

```bash
git add sacdia-backend/prisma/schema.prisma sacdia-backend/prisma/migrations/<timestamp>_annual_ranking_scorecard/migration.sql docs/database/SCHEMA-REFERENCE.md
git commit -m "feat: add annual ranking scorecard schema"
```

## Task 3: Seed default global tiers

**Files:**

- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/prisma/seed.ts` or existing RBAC/catalog seed file used by project convention
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/rankings/annual-ranking-progress/__tests__/ranking-tiers.seed.spec.ts` if seed helpers are testable

**Step 1: Add default tiers**

Initial defaults:

- Diamante: `5`
- Oro: `10`
- Plata: `15`
- Bronce: `20`

Leave room for additional tiers later.

**Step 2: Ensure idempotency**

Use upsert by slug.

**Step 3: Commit**

```bash
git add sacdia-backend/prisma/seed.ts
git commit -m "feat: seed default ranking tiers"
```

## Task 4: Backend annual config service

**Files:**

- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/rankings/annual-ranking-progress/annual-ranking-config.service.ts`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/rankings/annual-ranking-progress/annual-ranking-config.service.spec.ts`
- Create DTOs under: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/rankings/annual-ranking-progress/dto/`

**Step 1: Write tests**

Cover:

- creates config for local field/year/club type;
- rejects duplicate config;
- rejects component sum different from `max_points`;
- resolves config by local field/year/club type.

**Step 2: Run failing tests**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/rankings/annual-ranking-progress/annual-ranking-config.service.spec.ts --runInBand
```

Expected: FAIL.

**Step 3: Implement service**

Use Prisma transactions for config + components.

**Step 4: Re-run tests**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/rankings/annual-ranking-progress/annual-ranking-config.service.spec.ts --runInBand
```

Expected: PASS.

**Step 5: Commit**

```bash
git add sacdia-backend/src/rankings/annual-ranking-progress
git commit -m "feat: add annual ranking config service"
```

## Task 5: Backend mobile progress endpoint

**Files:**

- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/rankings/annual-ranking-progress/annual-ranking-progress.controller.ts`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/rankings/annual-ranking-progress/annual-ranking-progress.service.ts`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/rankings/annual-ranking-progress/annual-ranking-progress.controller.spec.ts`
- Modify module imports in relevant rankings module.

**Step 1: Write authorization tests**

Cover:

- director/secretary/treasurer of active section can read own section progress;
- unrelated club role cannot read other section progress;
- local-field admin can read within scope if required;
- missing config returns clear 404 or domain-specific configuration error.

**Step 2: Write response shape tests**

Expected fields:

- `current_points`
- `max_points`
- `current_tier`
- `next_tier`
- `components`
- `pending_items`

**Step 3: Run failing tests**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/rankings/annual-ranking-progress/annual-ranking-progress.controller.spec.ts --runInBand
```

Expected: FAIL.

**Step 4: Implement endpoint**

Route:

```http
GET /api/v1/club-sections/:sectionId/annual-ranking-progress?year_id=1
```

Implementation:

- resolve section → club → local field → club type;
- resolve annual config;
- calculate component points;
- derive tier;
- collect pending items from annual folder/evidence sources.

**Step 5: Re-run tests**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/rankings/annual-ranking-progress/annual-ranking-progress.controller.spec.ts --runInBand
```

Expected: PASS.

**Step 6: Commit**

```bash
git add sacdia-backend/src/rankings/annual-ranking-progress
git commit -m "feat: expose annual ranking progress endpoint"
```

## Task 6: Backend admin leaderboard endpoint

**Files:**

- Modify or create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/rankings/annual-ranking-progress/annual-rankings.controller.ts`
- Add tests under: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/rankings/annual-ranking-progress/`
- Update legacy compatibility in: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/annual-folders/rankings.controller.ts`

**Step 1: Add tests**

Cover:

- `GET /annual-rankings?local_field_id&club_type_id&year_id`;
- includes rank position, current points, max points, derived tier;
- local-field scope enforcement;
- backward compatibility for `/annual-folders/rankings` if retained.

**Step 2: Run failing tests**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/rankings/annual-ranking-progress --runInBand
```

Expected: FAIL until endpoint exists.

**Step 3: Implement**

Prefer new `/annual-rankings` resource. Keep `/annual-folders/rankings` as adapter if current clients still use it.

**Step 4: Re-run relevant tests**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/rankings/annual-ranking-progress src/annual-folders/__tests__/rankings.controller.spec.ts --runInBand
```

Expected: PASS.

**Step 5: Commit**

```bash
git add sacdia-backend/src/rankings/annual-ranking-progress sacdia-backend/src/annual-folders/rankings.controller.ts sacdia-backend/src/annual-folders/__tests__/rankings.controller.spec.ts
git commit -m "feat: add annual rankings leaderboard endpoint"
```

## Task 7: Backend docs

**Files:**

- Modify: `/Users/abner/Documents/development/sacdia/docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- Modify: `/Users/abner/Documents/development/sacdia/docs/canon/runtime-rankings.md`
- Modify: `/Users/abner/Documents/development/sacdia/docs/features/annual-folders-scoring.md`

**Step 1: Document new API**

Add:

- mobile progress endpoint;
- annual rankings endpoint;
- config endpoints;
- RBAC expectations;
- response examples.

**Step 2: Document legacy path**

Mark `/annual-folders/rankings` as compatibility if the new endpoint becomes canonical.

**Step 3: Commit**

```bash
git add docs/api/ENDPOINTS-LIVE-REFERENCE.md docs/canon/runtime-rankings.md docs/features/annual-folders-scoring.md
git commit -m "docs: document annual ranking scorecard contracts"
```

## Task 8: Flutter data/domain layer

**Files:**

- Create models/entities under: `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/rankings/`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/rankings/data/datasources/rankings_remote_data_source.dart`
- Modify ranking repository/provider files under: `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/rankings/`
- Add tests under: `/Users/abner/Documents/development/sacdia/sacdia-app/test/features/rankings/`

**Step 1: Add model parsing tests**

Create tests for:

- progress response JSON parses correctly;
- tier and component fields are required;
- unknown pending status maps to safe fallback label key.

**Step 2: Run failing Flutter tests**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app
flutter test test/features/rankings
```

Expected: FAIL until models/providers exist.

**Step 3: Implement data/domain layer**

Add:

- `AnnualRankingProgressModel`
- `RankingTierModel`
- `RankingComponentProgressModel`
- `RankingPendingItemModel`
- repository method `getAnnualRankingProgress(sectionId, yearId)`
- Riverpod provider keyed by section/year.

**Step 4: Re-run tests**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app
flutter test test/features/rankings
```

Expected: PASS.

**Step 5: Commit**

```bash
git add sacdia-app/lib/features/rankings sacdia-app/test/features/rankings
git commit -m "feat: add mobile annual ranking progress data layer"
```

## Task 9: Flutter UI replacement

**Files:**

- Modify: `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/rankings/presentation/screens/club_rankings_screen.dart`
- Or create: `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/rankings/presentation/screens/annual_ranking_progress_screen.dart`
- Modify route references if needed under: `/Users/abner/Documents/development/sacdia/sacdia-app/lib/core/`
- Update i18n translation files under: `/Users/abner/Documents/development/sacdia/sacdia-app/assets/translations/` if present.

**Step 1: Add widget tests**

Cover:

- does not render club type selector;
- does not render list of other clubs;
- renders current points and next tier;
- renders translated statuses, not raw `IN_PROGRESS` or similar.

**Step 2: Run failing tests**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app
flutter test test/features/rankings
```

Expected: FAIL.

**Step 3: Implement screen**

Use mobile constraints:

- no long leaderboard list;
- touch targets >= 44–48px;
- explicit loading/error/retry states;
- compact summary cards;
- no raw technical statuses.

**Step 4: Re-run tests and analyzer**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app
flutter test test/features/rankings
flutter analyze
```

Expected: PASS / no new analyzer errors.

**Step 5: Commit**

```bash
git add sacdia-app/lib/features/rankings sacdia-app/lib/core sacdia-app/assets sacdia-app/test/features/rankings
git commit -m "feat: redesign mobile ranking as annual progress"
```

## Task 10: Admin configuration UI

**Files:**

- Create/modify admin pages under: `/Users/abner/Documents/development/sacdia/sacdia-admin/app/(dashboard)/dashboard/`
- Create/modify API actions under: `/Users/abner/Documents/development/sacdia/sacdia-admin/lib/`
- Add components under: `/Users/abner/Documents/development/sacdia/sacdia-admin/components/`
- Add tests near existing Vitest patterns if available.

**Step 1: Add server action/client tests where project pattern exists**

Cover validation:

- max points required;
- component sum must equal total;
- tier band percentage must be positive.

**Step 2: Implement config screens**

Screens:

- global ranking tiers;
- annual local-field ranking configs;
- component budgets.

Use React Hook Form + Zod.

**Step 3: Run admin tests/typecheck**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-admin
pnpm test
pnpm typecheck
```

Expected: PASS.

**Step 4: Commit**

```bash
git add sacdia-admin/app sacdia-admin/components sacdia-admin/lib
git commit -m "feat: add annual ranking configuration UI"
```

## Task 11: Admin leaderboard update

**Files:**

- Modify existing ranking admin page/components under: `/Users/abner/Documents/development/sacdia/sacdia-admin/`
- Modify API clients/actions for rankings.

**Step 1: Update data contract**

Switch admin leaderboard to `/annual-rankings` once backend endpoint exists.

**Step 2: Render new columns**

Columns:

- position;
- club;
- club type;
- current points;
- max points;
- recognition tier;
- components summary.

**Step 3: Run admin tests/typecheck**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-admin
pnpm test
pnpm typecheck
```

Expected: PASS.

**Step 4: Commit**

```bash
git add sacdia-admin
git commit -m "feat: show point-based annual rankings in admin"
```

## Task 12: Final verification

**Files:**

- No new files unless fixing test/docs issues.

**Step 1: Run targeted backend tests**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/rankings/annual-ranking-progress src/annual-folders/__tests__/rankings.controller.spec.ts --runInBand
```

Expected: PASS.

**Step 2: Run Flutter ranking tests**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app
flutter test test/features/rankings
flutter analyze
```

Expected: PASS / no new analyzer errors.

**Step 3: Run admin checks**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-admin
pnpm test
pnpm typecheck
```

Expected: PASS.

**Step 4: Review docs**

Verify:

- `/Users/abner/Documents/development/sacdia/docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- `/Users/abner/Documents/development/sacdia/docs/canon/runtime-rankings.md`
- `/Users/abner/Documents/development/sacdia/docs/features/annual-folders-scoring.md`

**Step 5: Commit fixes if needed**

```bash
git add <changed-files>
git commit -m "test: verify annual ranking scorecard"
```

## Execution handoff

Recommended approach: implement backend calculation/config first, then mobile progress endpoint, then app UI, then admin configuration/leaderboard.

Do not delete the development demo data script until the user asks; it was intentionally mapped for cleanup later.

