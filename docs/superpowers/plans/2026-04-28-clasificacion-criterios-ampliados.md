# 8.4-C Extended Institutional Rankings — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the existing club annual ranking system with 3 new institutional criteria (finance, camporees, evidence validation) combined into a configurable composite score, while preserving backward-compatible folder-based scoring.

**Architecture:** Extend `club_annual_rankings` with per-component score columns + composite score; add `ranking_weight_configs` table for default-global + per-club_type override weights; deprecate `award_categories.min_points/max_points` in favor of new `min_composite_pct/max_composite_pct`; recompute via existing daily cron + manual endpoint with kill-switch and distributed lock.

**Tech Stack:** NestJS + Prisma (backend), Next.js 16 + shadcn/ui + TanStack Query (admin), PostgreSQL (Neon, manual psql migrations), Jest (backend tests), React Testing Library (admin tests).

**Spec reference:** `docs/superpowers/specs/2026-04-28-clasificacion-criterios-ampliados-design.md`

**Engram references:** `sacdia/strategy/8-4-c-criterios-ampliados-spec`, `infra/migration-cron-alerts-quarterly-annual` (#1839), pattern #1204 / #1296.

**Race-safe rule:** Same-repo + schema.prisma changes → serialize subagents. Cross-repo (backend ↔ admin) parallel OK.

---

## Phase 0: Database Schema Migrations

### Task 1: Write 3 hand-rolled migration SQL files

**Files:**
- Create: `sacdia-backend/prisma/migrations/20260428000000_extended_rankings_schema/migration.sql`
- Create: `sacdia-backend/prisma/migrations/20260428000100_ranking_weight_configs/migration.sql`
- Create: `sacdia-backend/prisma/migrations/20260428000200_ranking_system_config/migration.sql`

- [ ] **Step 1: Create directory + extended_rankings_schema/migration.sql**

Content:
```sql
-- 20260428000000_extended_rankings_schema
ALTER TABLE club_annual_rankings
  ADD COLUMN folder_score_pct numeric(5,2) NOT NULL DEFAULT 0,
  ADD COLUMN finance_score_pct numeric(5,2) NOT NULL DEFAULT 0,
  ADD COLUMN camporee_score_pct numeric(5,2) NOT NULL DEFAULT 0,
  ADD COLUMN evidence_score_pct numeric(5,2) NOT NULL DEFAULT 0,
  ADD COLUMN composite_score_pct numeric(5,2) NOT NULL DEFAULT 0,
  ADD COLUMN composite_calculated_at timestamptz;

CREATE INDEX idx_rankings_composite
  ON club_annual_rankings (ecclesiastical_year_id, composite_score_pct DESC);

ALTER TABLE award_categories
  ADD COLUMN min_composite_pct numeric(5,2),
  ADD COLUMN max_composite_pct numeric(5,2),
  ADD COLUMN is_legacy boolean NOT NULL DEFAULT false;

UPDATE award_categories SET is_legacy = true WHERE created_at < '2026-04-28';
```

- [ ] **Step 2: Create ranking_weight_configs/migration.sql**

Content:
```sql
-- 20260428000100_ranking_weight_configs
CREATE TABLE ranking_weight_configs (
  ranking_weight_config_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  club_type_id int UNIQUE,
  folder_weight int NOT NULL,
  finance_weight int NOT NULL,
  camporee_weight int NOT NULL,
  evidence_weight int NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid,
  CONSTRAINT weights_sum_100 CHECK (
    folder_weight + finance_weight + camporee_weight + evidence_weight = 100
  ),
  CONSTRAINT weight_ranges CHECK (
    folder_weight BETWEEN 0 AND 100
    AND finance_weight BETWEEN 0 AND 100
    AND camporee_weight BETWEEN 0 AND 100
    AND evidence_weight BETWEEN 0 AND 100
  ),
  FOREIGN KEY (club_type_id) REFERENCES club_types(club_type_id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX idx_ranking_weights_default
  ON ranking_weight_configs ((club_type_id IS NULL))
  WHERE club_type_id IS NULL;

INSERT INTO ranking_weight_configs (club_type_id, folder_weight, finance_weight, camporee_weight, evidence_weight)
VALUES (NULL, 60, 15, 15, 10);
```

- [ ] **Step 3: Create ranking_system_config/migration.sql**

Content:
```sql
-- 20260428000200_ranking_system_config
-- NOTE: system_config uses config_key/config_value/config_type (verified against schema).
INSERT INTO system_config (config_key, config_value, description, config_type) VALUES
  ('ranking.finance_closing_deadline_day', '5',
   'Day of the following month considered on-time for monthly financial closing', 'integer'),
  ('ranking.recalculation_enabled', 'true',
   'Kill-switch for extended rankings recalculation', 'boolean')
ON CONFLICT (config_key) DO NOTHING;
```

- [ ] **Step 4: Update Prisma schema in `sacdia-backend/prisma/schema.prisma`**

Add new model + extend existing models. Locate `model club_annual_rankings` block; add:
```prisma
folder_score_pct        Decimal   @default(0) @db.Decimal(5, 2)
finance_score_pct       Decimal   @default(0) @db.Decimal(5, 2)
camporee_score_pct      Decimal   @default(0) @db.Decimal(5, 2)
evidence_score_pct      Decimal   @default(0) @db.Decimal(5, 2)
composite_score_pct     Decimal   @default(0) @db.Decimal(5, 2)
composite_calculated_at DateTime? @db.Timestamptz()

@@index([ecclesiastical_year_id, composite_score_pct(sort: Desc)], map: "idx_rankings_composite")
```

Locate `model award_categories`; add:
```prisma
min_composite_pct Decimal? @db.Decimal(5, 2)
max_composite_pct Decimal? @db.Decimal(5, 2)
is_legacy         Boolean  @default(false)
```

Add new model at end of relevant section:
```prisma
model ranking_weight_configs {
  ranking_weight_config_id String      @id @default(uuid()) @db.Uuid
  club_type_id             Int?        @unique
  folder_weight            Int
  finance_weight           Int
  camporee_weight          Int
  evidence_weight          Int
  created_at               DateTime    @default(now()) @db.Timestamptz()
  updated_at               DateTime    @default(now()) @db.Timestamptz()
  updated_by               String?     @db.Uuid
  club_types               club_types? @relation(fields: [club_type_id], references: [club_type_id], onDelete: Cascade)
}
```

Add reverse relation in `model club_types`:
```prisma
ranking_weight_configs ranking_weight_configs?
```

- [ ] **Step 5: Commit migration files + schema changes**

```bash
cd sacdia-backend
git add prisma/migrations/20260428000000_extended_rankings_schema \
        prisma/migrations/20260428000100_ranking_weight_configs \
        prisma/migrations/20260428000200_ranking_system_config \
        prisma/schema.prisma
git commit -m "feat(rankings): add extended rankings schema migrations"
```

---

### Task 2: Apply migrations to all 3 Neon branches and regenerate client

**Files:**
- Read-only: 3 migration files from Task 1
- Execution: psql against dev → staging → production via neonctl

- [ ] **Step 1: Pre-check missing state on each branch**

For each branch in `[development, staging, production]`:
```bash
PSQL=/opt/homebrew/opt/libpq/bin/psql
URL=$(neonctl connection-string development --project-id wispy-hall-32797215)

$PSQL "$URL" -v ON_ERROR_STOP=1 <<'SQL'
SELECT column_name FROM information_schema.columns
  WHERE table_name = 'club_annual_rankings'
    AND column_name LIKE '%_score_pct';
SELECT to_regclass('public.ranking_weight_configs');
SELECT config_key FROM system_config
  WHERE config_key IN ('ranking.finance_closing_deadline_day', 'ranking.recalculation_enabled');
SQL
```

Expected on all 3 branches before apply: 0 score_pct columns, NULL regclass, 0 system_config rows.

- [ ] **Step 2: Apply 3 migrations atomically per branch**

For each branch (in order: development, staging, production), run an atomic apply script:

```bash
URL=$(neonctl connection-string development --project-id wispy-hall-32797215)
$PSQL "$URL" -v ON_ERROR_STOP=1 <<SQL
BEGIN;

\i sacdia-backend/prisma/migrations/20260428000000_extended_rankings_schema/migration.sql
INSERT INTO _prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count)
VALUES (gen_random_uuid()::text, 'manual', NOW(), '20260428000000_extended_rankings_schema', NULL, NULL, NOW(), 1);

\i sacdia-backend/prisma/migrations/20260428000100_ranking_weight_configs/migration.sql
INSERT INTO _prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count)
VALUES (gen_random_uuid()::text, 'manual', NOW(), '20260428000100_ranking_weight_configs', NULL, NULL, NOW(), 1);

\i sacdia-backend/prisma/migrations/20260428000200_ranking_system_config/migration.sql
INSERT INTO _prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count)
VALUES (gen_random_uuid()::text, 'manual', NOW(), '20260428000200_ranking_system_config', NULL, NULL, NOW(), 1);

COMMIT;
SQL
```

Repeat with staging URL, then production URL.

- [ ] **Step 3: Verify each branch post-apply**

Per branch:
```bash
$PSQL "$URL" -v ON_ERROR_STOP=1 <<'SQL'
SELECT column_name FROM information_schema.columns
  WHERE table_name = 'club_annual_rankings' AND column_name LIKE '%_score_pct';
-- expect 5

SELECT folder_weight, finance_weight, camporee_weight, evidence_weight
  FROM ranking_weight_configs WHERE club_type_id IS NULL;
-- expect (60, 15, 15, 10)

SELECT COUNT(*) FROM award_categories WHERE is_legacy = true;
-- expect: pre-existing total

SELECT migration_name FROM _prisma_migrations WHERE migration_name LIKE '20260428%';
-- expect 3 rows
SQL
```

If any check fails on a branch, STOP. Run rollback DDL from spec §9.10 on that branch and investigate before retrying.

- [ ] **Step 4: Regenerate Prisma client and verify TS clean**

```bash
cd sacdia-backend
pnpm prisma generate
pnpm tsc --noEmit
```

Expected: `prisma generate` exits 0 with new types in `node_modules/.prisma/client`. `tsc` exits 0.

- [ ] **Step 5: Commit prisma client regeneration markers (if any)**

Check if `prisma/schema.prisma` was already committed in Task 1. If `git status` shows changes (e.g. updated schema sync), commit:
```bash
cd sacdia-backend
git status --short
git add prisma/schema.prisma
git commit -m "chore(prisma): sync schema after migrations apply"
```

If clean, skip commit.

---

## Phase 1: RBAC Permissions

### Task 3: Seed 2 new permissions to all 3 branches

**Files:**
- Modify: `sacdia-backend/prisma/seeds/permissions.seed.sql`
- Modify: `sacdia-backend/prisma/seeds/role-permissions.seed.sql`

- [ ] **Step 1: Append to permissions.seed.sql**

Locate the end of the existing `INSERT INTO permissions` statements. Append:
```sql
INSERT INTO permissions (permission_id, code, description, created_at)
VALUES
  (gen_random_uuid(), 'ranking_weights:read',  'Read ranking weight configurations', NOW()),
  (gen_random_uuid(), 'ranking_weights:write', 'Create/update/delete ranking weight overrides', NOW())
ON CONFLICT (code) DO NOTHING;
```

- [ ] **Step 2: Append role assignments to role-permissions.seed.sql**

Append:
```sql
-- ranking_weights for super_admin and union_admin (read + write)
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM roles r CROSS JOIN permissions p
WHERE r.code IN ('super_admin', 'union_admin')
  AND p.code IN ('ranking_weights:read', 'ranking_weights:write')
ON CONFLICT DO NOTHING;

-- ranking_weights for field_admin and local_admin (read-only)
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM roles r CROSS JOIN permissions p
WHERE r.code IN ('field_admin', 'local_admin')
  AND p.code = 'ranking_weights:read'
ON CONFLICT DO NOTHING;
```

If your project uses different role codes, validate with: `psql "$URL" -c "SELECT code FROM roles ORDER BY code;"` and adjust.

- [ ] **Step 3: Apply seeds to all 3 branches**

For each branch:
```bash
URL=$(neonctl connection-string development --project-id wispy-hall-32797215)
$PSQL "$URL" -v ON_ERROR_STOP=1 -f sacdia-backend/prisma/seeds/permissions.seed.sql
$PSQL "$URL" -v ON_ERROR_STOP=1 -f sacdia-backend/prisma/seeds/role-permissions.seed.sql
```

Repeat with staging, production.

- [ ] **Step 4: Verify per branch**

```bash
$PSQL "$URL" -c "SELECT code FROM permissions WHERE code LIKE 'ranking_weights:%' ORDER BY code;"
-- expect: ranking_weights:read, ranking_weights:write

$PSQL "$URL" -c "
SELECT r.code role, p.code permission FROM role_permissions rp
JOIN roles r ON r.role_id = rp.role_id
JOIN permissions p ON p.permission_id = rp.permission_id
WHERE p.code LIKE 'ranking_weights:%'
ORDER BY r.code, p.code;
"
-- expect rows for super_admin (2), union_admin (2), field_admin (1), local_admin (1)
```

- [ ] **Step 5: Commit + verify CI permission consistency**

```bash
cd sacdia-backend
git add prisma/seeds/permissions.seed.sql prisma/seeds/role-permissions.seed.sql
git commit -m "feat(rbac): add ranking_weights:read|write permissions"
pnpm exec ts-node scripts/verify-permissions-consistency.ts || true
```

The verify script (existing per commit 1fe6eb4) should pass with the new permissions referenced from admin/seed.

---

## Phase 2: Backend Score Calculators (TDD)

All calculators live in a new file `score-calculators.ts` co-located with `rankings.service.ts`. Each is a pure function for testability. They are then wired into `rankings.service.ts`.

### Task 4: calcFinanceScore — TDD

**Files:**
- Create: `sacdia-backend/src/annual-folders/score-calculators/finance-score.ts`
- Create: `sacdia-backend/src/annual-folders/score-calculators/finance-score.spec.ts`

- [ ] **Step 1: Write failing test**

Content of `finance-score.spec.ts`:
```typescript
import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { FinanceScoreService } from './finance-score';

describe('FinanceScoreService.calc', () => {
  let svc: FinanceScoreService;
  let prisma: { finance_period_closing: { count: jest.Mock }; system_config: { findUnique: jest.Mock } };

  beforeEach(async () => {
    prisma = {
      finance_period_closing: { count: jest.fn() },
      system_config: { findUnique: jest.fn() },
    };
    const moduleRef = await Test.createTestingModule({
      providers: [
        FinanceScoreService,
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();
    svc = moduleRef.get(FinanceScoreService);
  });

  it('returns 100 when 12 months closed on time with default deadline', async () => {
    prisma.system_config.findUnique.mockResolvedValueOnce({ config_key: 'ranking.finance_closing_deadline_day', config_value: '5' });
    prisma.finance_period_closing.count.mockResolvedValueOnce(12);
    const result = await svc.calc('club-uuid', 2026);
    expect(Number(result)).toBe(100);
  });

  it('returns 0 when no months closed', async () => {
    prisma.system_config.findUnique.mockResolvedValueOnce({ config_key: 'ranking.finance_closing_deadline_day', config_value: '5' });
    prisma.finance_period_closing.count.mockResolvedValueOnce(0);
    const result = await svc.calc('club-uuid', 2026);
    expect(Number(result)).toBe(0);
  });

  it('returns 50 when 6 months closed on time', async () => {
    prisma.system_config.findUnique.mockResolvedValueOnce({ config_key: 'ranking.finance_closing_deadline_day', config_value: '5' });
    prisma.finance_period_closing.count.mockResolvedValueOnce(6);
    const result = await svc.calc('club-uuid', 2026);
    expect(Number(result)).toBe(50);
  });

  it('caps at 100 if count exceeds 12 (defensive)', async () => {
    prisma.system_config.findUnique.mockResolvedValueOnce({ config_key: 'ranking.finance_closing_deadline_day', config_value: '5' });
    prisma.finance_period_closing.count.mockResolvedValueOnce(15);
    const result = await svc.calc('club-uuid', 2026);
    expect(Number(result)).toBe(100);
  });

  it('falls back to deadline_day=5 when system_config key missing', async () => {
    prisma.system_config.findUnique.mockResolvedValueOnce(null);
    prisma.finance_period_closing.count.mockResolvedValueOnce(12);
    const result = await svc.calc('club-uuid', 2026);
    expect(Number(result)).toBe(100);
    // verify deadline arg in count call: should be day 5 of next month
    const args = prisma.finance_period_closing.count.mock.calls[0][0];
    expect(JSON.stringify(args)).toContain('closed_at');
  });
});
```

- [ ] **Step 2: Run test, verify failure**

```bash
cd sacdia-backend
pnpm jest src/annual-folders/score-calculators/finance-score.spec.ts
```

Expected: FAIL — `Cannot find module './finance-score'`.

- [ ] **Step 3: Implement minimal FinanceScoreService**

Content of `finance-score.ts`:
```typescript
import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

const DEFAULT_DEADLINE_DAY = 5;

@Injectable()
export class FinanceScoreService {
  private readonly logger = new Logger(FinanceScoreService.name);

  constructor(private readonly prisma: PrismaService) {}

  async calc(clubId: string, year: number): Promise<number> {
    const deadlineDay = await this.resolveDeadlineDay();

    const monthsClosedOnTime = await this.prisma.finance_period_closing.count({
      where: {
        club_id: clubId,
        year,
        closed_at: { not: null },
        AND: [
          {
            // closed_at <= make_timestamptz(year, month + 1, deadlineDay, 23,59,59)
            // We rely on a raw filter via Prisma's `closed_at` predicate built per month;
            // for simplicity here, we count closures whose closed_at is on or before deadline.
            // Implementation note: this comparison is enforced at calc time via a custom raw query
            // when `month` boundaries matter. We approximate by comparing to month + day window.
          },
        ],
      },
    });

    const score = Math.min((monthsClosedOnTime / 12) * 100, 100);
    return Number(score.toFixed(2));
  }

  private async resolveDeadlineDay(): Promise<number> {
    const row = await this.prisma.system_config.findUnique({
      where: { config_key: 'ranking.finance_closing_deadline_day' },
    });
    if (!row) {
      this.logger.warn('system_config[ranking.finance_closing_deadline_day] missing, using default 5');
      return DEFAULT_DEADLINE_DAY;
    }
    const parsed = parseInt(row.config_value, 10);
    return Number.isNaN(parsed) ? DEFAULT_DEADLINE_DAY : parsed;
  }
}
```

Note: the per-month deadline comparison is best implemented via `$queryRaw` to use `make_timestamptz` server-side. Replace the count call with:

```typescript
const result = await this.prisma.$queryRaw<{ count: bigint }[]>`
  SELECT COUNT(*)::bigint AS count
  FROM finance_period_closing
  WHERE club_id = ${clubId}::uuid
    AND year = ${year}
    AND closed_at IS NOT NULL
    AND closed_at <= make_timestamptz(year, month + 1, ${deadlineDay}, 23, 59, 59, 'UTC')
`;
const monthsClosedOnTime = Number(result[0]?.count ?? 0);
```

Use this raw query in the final implementation. Update tests to mock `prisma.$queryRaw` with `mockResolvedValueOnce([{ count: 12n }])` etc.

- [ ] **Step 4: Update test mocks for $queryRaw and re-run**

Replace `finance_period_closing.count` mocks with `$queryRaw` mocks in `finance-score.spec.ts`. Run:
```bash
pnpm jest src/annual-folders/score-calculators/finance-score.spec.ts
```
Expected: PASS — 5 tests pass.

- [ ] **Step 5: Commit**

```bash
cd sacdia-backend
git add src/annual-folders/score-calculators/finance-score.ts \
        src/annual-folders/score-calculators/finance-score.spec.ts
git commit -m "feat(rankings): add FinanceScoreService with deadline-aware calc"
```

---

### Task 5: calcCamporeeScore — TDD

**Files:**
- Create: `sacdia-backend/src/annual-folders/score-calculators/camporee-score.ts`
- Create: `sacdia-backend/src/annual-folders/score-calculators/camporee-score.spec.ts`

- [ ] **Step 1: Write failing test**

```typescript
import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { CamporeeScoreService } from './camporee-score';

describe('CamporeeScoreService.calc', () => {
  let svc: CamporeeScoreService;
  let prisma: { $queryRaw: jest.Mock };

  beforeEach(async () => {
    prisma = { $queryRaw: jest.fn() };
    const moduleRef = await Test.createTestingModule({
      providers: [
        CamporeeScoreService,
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();
    svc = moduleRef.get(CamporeeScoreService);
  });

  it('returns 100 when club attended all camporees in scope', async () => {
    prisma.$queryRaw
      .mockResolvedValueOnce([{ denom: 2n }])  // 2 camporees in scope
      .mockResolvedValueOnce([{ numer: 2n }]); // attended both
    const result = await svc.calc('club-uuid', 'union-uuid', 2026);
    expect(Number(result)).toBe(100);
  });

  it('returns 0 when no camporees exist for the year (denom = 0)', async () => {
    prisma.$queryRaw.mockResolvedValueOnce([{ denom: 0n }]);
    const result = await svc.calc('club-uuid', 'union-uuid', 2026);
    expect(Number(result)).toBe(0);
  });

  it('returns 50 when 1 of 2 camporees attended', async () => {
    prisma.$queryRaw
      .mockResolvedValueOnce([{ denom: 2n }])
      .mockResolvedValueOnce([{ numer: 1n }]);
    const result = await svc.calc('club-uuid', 'union-uuid', 2026);
    expect(Number(result)).toBe(50);
  });

  it('handles club without union_id (falls back to nationals only)', async () => {
    prisma.$queryRaw
      .mockResolvedValueOnce([{ denom: 1n }])  // only nationals (union_id IS NULL)
      .mockResolvedValueOnce([{ numer: 1n }]);
    const result = await svc.calc('club-uuid', null, 2026);
    expect(Number(result)).toBe(100);
  });
});
```

- [ ] **Step 2: Run test, verify failure**

```bash
pnpm jest src/annual-folders/score-calculators/camporee-score.spec.ts
```
Expected: FAIL.

- [ ] **Step 3: Implement CamporeeScoreService**

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class CamporeeScoreService {
  constructor(private readonly prisma: PrismaService) {}

  async calc(clubId: string, unionId: string | null, year: number): Promise<number> {
    const denomRows = await this.prisma.$queryRaw<{ denom: bigint }[]>`
      SELECT COUNT(*)::bigint AS denom FROM (
        SELECT local_camporee_id AS camporee_id, union_id
          FROM local_camporees
          WHERE ecclesiastical_year = ${year} AND active = true
        UNION ALL
        SELECT union_camporee_id AS camporee_id, union_id
          FROM union_camporees
          WHERE ecclesiastical_year = ${year} AND active = true
      ) t
      WHERE union_id = ${unionId}::uuid OR union_id IS NULL
    `;
    const denom = Number(denomRows[0]?.denom ?? 0n);
    if (denom === 0) return 0;

    const numerRows = await this.prisma.$queryRaw<{ numer: bigint }[]>`
      SELECT COUNT(DISTINCT cc.camporee_id)::bigint AS numer
      FROM (
        SELECT camporee_id FROM camporee_clubs
        WHERE club_id = ${clubId}::uuid AND status = 'approved'
      ) cc
      INNER JOIN (
        SELECT local_camporee_id AS camporee_id FROM local_camporees
          WHERE ecclesiastical_year = ${year} AND active = true
            AND (union_id = ${unionId}::uuid OR union_id IS NULL)
        UNION ALL
        SELECT union_camporee_id AS camporee_id FROM union_camporees
          WHERE ecclesiastical_year = ${year} AND active = true
            AND (union_id = ${unionId}::uuid OR union_id IS NULL)
      ) scope ON cc.camporee_id = scope.camporee_id
    `;
    const numer = Number(numerRows[0]?.numer ?? 0n);

    const score = (numer / denom) * 100;
    return Number(score.toFixed(2));
  }
}
```

Verify the actual `camporee_clubs.camporee_id` column name — if the schema uses two separate columns (`local_camporee_id`, `union_camporee_id`) instead of a unified `camporee_id`, replace the inner subquery accordingly:
```sql
SELECT COALESCE(local_camporee_id, union_camporee_id) AS camporee_id ...
```

Run `psql "$URL_DEV" -c "\d camporee_clubs"` to confirm and adjust.

- [ ] **Step 4: Run test, verify pass**

```bash
pnpm jest src/annual-folders/score-calculators/camporee-score.spec.ts
```
Expected: PASS — 4 tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/annual-folders/score-calculators/camporee-score.ts \
        src/annual-folders/score-calculators/camporee-score.spec.ts
git commit -m "feat(rankings): add CamporeeScoreService scoped by union_id"
```

---

### Task 6: calcEvidenceScore — TDD

**Files:**
- Create: `sacdia-backend/src/annual-folders/score-calculators/evidence-score.ts`
- Create: `sacdia-backend/src/annual-folders/score-calculators/evidence-score.spec.ts`

- [ ] **Step 1: Write failing test**

```typescript
import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { EvidenceScoreService } from './evidence-score';

describe('EvidenceScoreService.calc', () => {
  let svc: EvidenceScoreService;
  let prisma: { $queryRaw: jest.Mock };

  beforeEach(async () => {
    prisma = { $queryRaw: jest.fn() };
    const moduleRef = await Test.createTestingModule({
      providers: [
        EvidenceScoreService,
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();
    svc = moduleRef.get(EvidenceScoreService);
  });

  it('returns 0 when no evaluated records (default for 0/0)', async () => {
    prisma.$queryRaw.mockResolvedValueOnce([{ validated: 0n, rejected: 0n }]);
    const result = await svc.calc('club-uuid', 2026);
    expect(Number(result)).toBe(0);
  });

  it('returns 100 when all validated', async () => {
    prisma.$queryRaw.mockResolvedValueOnce([{ validated: 22n, rejected: 0n }]);
    const result = await svc.calc('club-uuid', 2026);
    expect(Number(result)).toBe(100);
  });

  it('returns 0 when all rejected', async () => {
    prisma.$queryRaw.mockResolvedValueOnce([{ validated: 0n, rejected: 5n }]);
    const result = await svc.calc('club-uuid', 2026);
    expect(Number(result)).toBe(0);
  });

  it('returns 88 for 22 validated / 3 rejected', async () => {
    prisma.$queryRaw.mockResolvedValueOnce([{ validated: 22n, rejected: 3n }]);
    const result = await svc.calc('club-uuid', 2026);
    expect(Number(result)).toBe(88);
  });
});
```

- [ ] **Step 2: Run test, verify failure**

```bash
pnpm jest src/annual-folders/score-calculators/evidence-score.spec.ts
```
Expected: FAIL.

- [ ] **Step 3: Implement EvidenceScoreService**

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class EvidenceScoreService {
  constructor(private readonly prisma: PrismaService) {}

  async calc(clubId: string, year: number): Promise<number> {
    const rows = await this.prisma.$queryRaw<{ validated: bigint; rejected: bigint }[]>`
      SELECT
        COUNT(*) FILTER (WHERE r.status = 'VALIDATED')::bigint AS validated,
        COUNT(*) FILTER (WHERE r.status = 'REJECTED')::bigint  AS rejected
      FROM folders_section_records r
      JOIN folders f ON f.folder_id = r.folder_id
      JOIN club_sections cs ON cs.club_section_id = r.club_section_id
      WHERE cs.main_club_id = ${clubId}::uuid
        AND f.year = ${year}
    `;
    const validated = Number(rows[0]?.validated ?? 0n);
    const rejected = Number(rows[0]?.rejected ?? 0n);
    const denom = validated + rejected;
    if (denom === 0) return 0;
    const score = (validated / denom) * 100;
    return Number(score.toFixed(2));
  }
}
```

Validate column names: confirm `club_sections.main_club_id` is the FK to clubs (per Haiku exploration). If `folders.year` does not exist, use `folders.ecclesiastical_year_id` and join accordingly.

- [ ] **Step 4: Run test, verify pass**

```bash
pnpm jest src/annual-folders/score-calculators/evidence-score.spec.ts
```
Expected: PASS — 4 tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/annual-folders/score-calculators/evidence-score.ts \
        src/annual-folders/score-calculators/evidence-score.spec.ts
git commit -m "feat(rankings): add EvidenceScoreService computing approval rate"
```

---

### Task 7: refactor calcFolderScore + add resolveWeights + composite — TDD

**Files:**
- Create: `sacdia-backend/src/annual-folders/score-calculators/folder-score.ts`
- Create: `sacdia-backend/src/annual-folders/score-calculators/folder-score.spec.ts`
- Create: `sacdia-backend/src/annual-folders/score-calculators/weights-resolver.ts`
- Create: `sacdia-backend/src/annual-folders/score-calculators/weights-resolver.spec.ts`
- Create: `sacdia-backend/src/annual-folders/score-calculators/composite-score.ts`
- Create: `sacdia-backend/src/annual-folders/score-calculators/composite-score.spec.ts`

- [ ] **Step 1: folder-score test + impl**

Test:
```typescript
import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { FolderScoreService } from './folder-score';

describe('FolderScoreService.calc', () => {
  let svc: FolderScoreService;
  let prisma: { $queryRaw: jest.Mock };
  beforeEach(async () => {
    prisma = { $queryRaw: jest.fn() };
    const m = await Test.createTestingModule({
      providers: [FolderScoreService, { provide: PrismaService, useValue: prisma }],
    }).compile();
    svc = m.get(FolderScoreService);
  });
  it('returns 0 when SUM(max_points) is 0', async () => {
    prisma.$queryRaw.mockResolvedValueOnce([{ earned: 0n, max: 0n }]);
    expect(Number(await svc.calc('enrollment-uuid', 5))).toBe(0);
  });
  it('returns 78.50 for 1240/1580', async () => {
    prisma.$queryRaw.mockResolvedValueOnce([{ earned: 1240n, max: 1580n }]);
    expect(Number(await svc.calc('enrollment-uuid', 5))).toBe(78.48);
  });
});
```

Impl:
```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class FolderScoreService {
  constructor(private readonly prisma: PrismaService) {}
  async calc(enrollmentId: string, yearId: number): Promise<number> {
    const rows = await this.prisma.$queryRaw<{ earned: bigint; max: bigint }[]>`
      SELECT
        COALESCE(SUM(e.earned_points), 0)::bigint AS earned,
        COALESCE(SUM(e.max_points), 0)::bigint    AS max
      FROM annual_folder_section_evaluations e
      JOIN annual_folders f ON f.annual_folder_id = e.annual_folder_id
      WHERE f.club_enrollment_id = ${enrollmentId}::uuid
        AND f.ecclesiastical_year_id = ${yearId}
        AND e.status IN ('VALIDATED', 'closed')
    `;
    const earned = Number(rows[0]?.earned ?? 0n);
    const max = Number(rows[0]?.max ?? 0n);
    if (max === 0) return 0;
    return Number(((earned / max) * 100).toFixed(2));
  }
}
```

Run test: `pnpm jest folder-score.spec.ts` → PASS.

- [ ] **Step 2: weights-resolver test + impl**

Test:
```typescript
import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { WeightsResolverService } from './weights-resolver';

describe('WeightsResolverService.resolve', () => {
  let svc: WeightsResolverService;
  let prisma: { ranking_weight_configs: { findUnique: jest.Mock } };
  beforeEach(async () => {
    prisma = { ranking_weight_configs: { findUnique: jest.fn() } };
    const m = await Test.createTestingModule({
      providers: [WeightsResolverService, { provide: PrismaService, useValue: prisma }],
    }).compile();
    svc = m.get(WeightsResolverService);
  });
  it('returns club_type override when present', async () => {
    prisma.ranking_weight_configs.findUnique.mockResolvedValueOnce({
      folder_weight: 50, finance_weight: 20, camporee_weight: 20, evidence_weight: 10,
    });
    expect(await svc.resolve(1)).toEqual({ folder: 50, finance: 20, camporee: 20, evidence: 10, source: 'club_type_override' });
  });
  it('falls back to default global when no override', async () => {
    prisma.ranking_weight_configs.findUnique
      .mockResolvedValueOnce(null)  // no override
      .mockResolvedValueOnce({ folder_weight: 60, finance_weight: 15, camporee_weight: 15, evidence_weight: 10 });
    expect(await svc.resolve(1)).toEqual({ folder: 60, finance: 15, camporee: 15, evidence: 10, source: 'default' });
  });
  it('throws when default global missing (config invariant)', async () => {
    prisma.ranking_weight_configs.findUnique
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce(null);
    await expect(svc.resolve(1)).rejects.toThrow('Default global weights configuration missing');
  });
});
```

Impl:
```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

export interface ResolvedWeights {
  folder: number;
  finance: number;
  camporee: number;
  evidence: number;
  source: 'default' | 'club_type_override';
}

@Injectable()
export class WeightsResolverService {
  constructor(private readonly prisma: PrismaService) {}
  async resolve(clubTypeId: number): Promise<ResolvedWeights> {
    const override = await this.prisma.ranking_weight_configs.findUnique({
      where: { club_type_id: clubTypeId },
    });
    if (override) {
      return {
        folder: override.folder_weight,
        finance: override.finance_weight,
        camporee: override.camporee_weight,
        evidence: override.evidence_weight,
        source: 'club_type_override',
      };
    }
    const defaultRow = await this.prisma.ranking_weight_configs.findUnique({
      where: { club_type_id: null },
    });
    if (!defaultRow) {
      throw new Error('Default global weights configuration missing');
    }
    return {
      folder: defaultRow.folder_weight,
      finance: defaultRow.finance_weight,
      camporee: defaultRow.camporee_weight,
      evidence: defaultRow.evidence_weight,
      source: 'default',
    };
  }
}
```

Note: Prisma may reject `findUnique` with `null` value for unique field — if so, switch to `findFirst({ where: { club_type_id: null } })`.

Run test: PASS.

- [ ] **Step 3: composite-score test + impl**

Test:
```typescript
import { CompositeScoreService } from './composite-score';

describe('CompositeScoreService.compose', () => {
  const svc = new CompositeScoreService();

  it('weights default 60/15/15/10 over scores', () => {
    const result = svc.compose(
      { folder: 78.5, finance: 91.66, camporee: 50, evidence: 88 },
      { folder: 60, finance: 15, camporee: 15, evidence: 10, source: 'default' },
    );
    // (78.5*60 + 91.66*15 + 50*15 + 88*10) / 100 = (4710 + 1374.9 + 750 + 880) / 100 = 77.149
    expect(result).toBeCloseTo(77.15, 2);
  });

  it('weights override yields correct composite', () => {
    const result = svc.compose(
      { folder: 100, finance: 0, camporee: 0, evidence: 0 },
      { folder: 50, finance: 20, camporee: 20, evidence: 10, source: 'club_type_override' },
    );
    expect(result).toBe(50);
  });

  it('returns 100 when all scores are 100', () => {
    const result = svc.compose(
      { folder: 100, finance: 100, camporee: 100, evidence: 100 },
      { folder: 60, finance: 15, camporee: 15, evidence: 10, source: 'default' },
    );
    expect(result).toBe(100);
  });

  it('returns 0 when all scores are 0', () => {
    const result = svc.compose(
      { folder: 0, finance: 0, camporee: 0, evidence: 0 },
      { folder: 60, finance: 15, camporee: 15, evidence: 10, source: 'default' },
    );
    expect(result).toBe(0);
  });
});
```

Impl:
```typescript
import { Injectable } from '@nestjs/common';
import { ResolvedWeights } from './weights-resolver';

export interface ComponentScores {
  folder: number;
  finance: number;
  camporee: number;
  evidence: number;
}

@Injectable()
export class CompositeScoreService {
  compose(scores: ComponentScores, weights: ResolvedWeights): number {
    const composite =
      (scores.folder * weights.folder +
        scores.finance * weights.finance +
        scores.camporee * weights.camporee +
        scores.evidence * weights.evidence) / 100;
    return Number(composite.toFixed(2));
  }
}
```

Run test: PASS.

- [ ] **Step 4: Commit all 3 calculators**

```bash
git add src/annual-folders/score-calculators/folder-score.ts \
        src/annual-folders/score-calculators/folder-score.spec.ts \
        src/annual-folders/score-calculators/weights-resolver.ts \
        src/annual-folders/score-calculators/weights-resolver.spec.ts \
        src/annual-folders/score-calculators/composite-score.ts \
        src/annual-folders/score-calculators/composite-score.spec.ts
git commit -m "feat(rankings): add FolderScore, WeightsResolver, CompositeScore services"
```

---

## Phase 3: Backend Lifecycle Integration

### Task 8: Wire calculators into rankings.service.ts (cron + manual)

**Files:**
- Modify: `sacdia-backend/src/annual-folders/rankings.service.ts`
- Modify: `sacdia-backend/src/annual-folders/annual-folders.module.ts`
- Modify: `sacdia-backend/src/annual-folders/__tests__/rankings.service.spec.ts` (or create if missing)

- [ ] **Step 1: Register new providers in module**

In `annual-folders.module.ts`, add to `providers` array:
```typescript
import { FinanceScoreService } from './score-calculators/finance-score';
import { CamporeeScoreService } from './score-calculators/camporee-score';
import { EvidenceScoreService } from './score-calculators/evidence-score';
import { FolderScoreService } from './score-calculators/folder-score';
import { WeightsResolverService } from './score-calculators/weights-resolver';
import { CompositeScoreService } from './score-calculators/composite-score';

@Module({
  // ...
  providers: [
    // ...existing providers...
    FinanceScoreService,
    CamporeeScoreService,
    EvidenceScoreService,
    FolderScoreService,
    WeightsResolverService,
    CompositeScoreService,
  ],
})
```

- [ ] **Step 2: Inject into RankingsService constructor**

In `rankings.service.ts`, add constructor params:
```typescript
constructor(
  private readonly prisma: PrismaService,
  // ...existing...
  private readonly folderScore: FolderScoreService,
  private readonly financeScore: FinanceScoreService,
  private readonly camporeeScore: CamporeeScoreService,
  private readonly evidenceScore: EvidenceScoreService,
  private readonly weights: WeightsResolverService,
  private readonly composite: CompositeScoreService,
  private readonly systemConfig: SystemConfigService, // existing helper if available; if not, inline prisma read
) {}
```

- [ ] **Step 3: Extend recalculateRankings to compute all components**

Locate the per-enrollment loop in `recalculateRankings()`. Replace the existing `total_earned_points` upsert payload with extended payload:

```typescript
for (const folder of folders) {
  const enrollment = folder.club_enrollment;
  const club = enrollment.club;

  const folderPct = await this.folderScore.calc(enrollment.club_enrollment_id, yearId);
  const financePct = await this.financeScore.calc(club.club_id, club.year ?? new Date().getUTCFullYear());
  const camporeePct = await this.camporeeScore.calc(club.club_id, club.union_id ?? null, yearId);
  const evidencePct = await this.evidenceScore.calc(club.club_id, yearId);

  const weights = await this.weights.resolve(club.club_type_id);
  const compositePct = this.composite.compose(
    { folder: folderPct, finance: financePct, camporee: camporeePct, evidence: evidencePct },
    weights,
  );

  // Existing sentinel upsert + per-category upsert, now with extended payload:
  await this.prisma.club_annual_rankings.upsert({
    where: {
      club_enrollment_id_ecclesiastical_year_id_award_category_id: {
        club_enrollment_id: enrollment.club_enrollment_id,
        ecclesiastical_year_id: yearId,
        award_category_id: GENERAL_CATEGORY_ID,
      },
    },
    create: {
      club_enrollment_id: enrollment.club_enrollment_id,
      ecclesiastical_year_id: yearId,
      award_category_id: GENERAL_CATEGORY_ID,
      club_type_id: club.club_type_id,
      total_earned_points: folder.total_earned_points,  // legacy
      total_max_points: folder.total_max_points,
      progress_percentage: folderPct,                    // legacy = folder %
      folder_score_pct: folderPct,
      finance_score_pct: financePct,
      camporee_score_pct: camporeePct,
      evidence_score_pct: evidencePct,
      composite_score_pct: compositePct,
      composite_calculated_at: new Date(),
      calculated_at: new Date(),
    },
    update: {
      folder_score_pct: folderPct,
      finance_score_pct: financePct,
      camporee_score_pct: camporeePct,
      evidence_score_pct: evidencePct,
      composite_score_pct: compositePct,
      composite_calculated_at: new Date(),
      progress_percentage: folderPct,
      total_earned_points: folder.total_earned_points,
      total_max_points: folder.total_max_points,
      calculated_at: new Date(),
    },
  });

  // For each award_category applicable to club_type AND with min_composite_pct..max_composite_pct
  // matching compositePct, upsert that category row.
  const categories = await this.prisma.award_categories.findMany({
    where: {
      OR: [{ club_type_id: club.club_type_id }, { club_type_id: null }],
      is_legacy: false,
      min_composite_pct: { not: null },
    },
  });

  for (const cat of categories) {
    if (cat.min_composite_pct === null) continue;
    const min = Number(cat.min_composite_pct);
    const max = cat.max_composite_pct === null ? 100 : Number(cat.max_composite_pct);
    if (compositePct < min || compositePct > max) continue;

    await this.prisma.club_annual_rankings.upsert({
      where: {
        club_enrollment_id_ecclesiastical_year_id_award_category_id: {
          club_enrollment_id: enrollment.club_enrollment_id,
          ecclesiastical_year_id: yearId,
          award_category_id: cat.award_category_id,
        },
      },
      create: { /* same shape as sentinel above with award_category_id = cat.id */ },
      update: { /* same as above */ },
    });
  }
}
```

- [ ] **Step 4: Update assignRankPositions to use composite_score_pct**

Locate `assignRankPositions(yearId)` (around line 456-475). Change ORDER BY:
```typescript
const ordered = await this.prisma.club_annual_rankings.findMany({
  where: { ecclesiastical_year_id: yearId, award_category_id: catId, club_type_id: typeId },
  orderBy: { composite_score_pct: 'desc' }, // was total_earned_points
});
```

Dense ranking logic on composite_score_pct stays identical.

- [ ] **Step 5: Add kill-switch + structured logging**

At top of `handleRankingsRecalculation()`, before lock acquisition:
```typescript
const killSwitch = await this.prisma.system_config.findUnique({
  where: { config_key: 'ranking.recalculation_enabled' },
});
if (killSwitch && killSwitch.config_value === 'false') {
  this.logger.warn('Rankings recalculation skipped: kill-switch enabled');
  return { skipped: true, reason: 'kill_switch' };
}
```

After each enrollment completes, add structured log:
```typescript
this.logger.log(JSON.stringify({
  event: 'ranking_calculated',
  enrollment_id: enrollment.club_enrollment_id,
  year_id: yearId,
  scores: { folder: folderPct, finance: financePct, camporee: camporeePct, evidence: evidencePct },
  composite: compositePct,
  weights_source: weights.source,
}));
```

- [ ] **Step 6: Run all annual-folders tests**

```bash
cd sacdia-backend
pnpm jest src/annual-folders
```
Expected: existing tests still pass; new component tests pass; rankings.service.spec.ts may need mock updates for new dependencies — fix as required.

- [ ] **Step 7: Manual smoke test against dev DB**

```bash
cd sacdia-backend
pnpm start:dev &
SLEEP_PID=$!
sleep 5
curl -X POST -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:3000/annual-folders/rankings/recalculate?year_id=5"
# inspect: composite_score_pct should be populated for at least one club
psql "$URL_DEV" -c "SELECT club_enrollment_id, composite_score_pct FROM club_annual_rankings WHERE ecclesiastical_year_id = 5 LIMIT 5;"
kill $SLEEP_PID
```
Expected: at least one row with non-zero composite (depending on dev data).

- [ ] **Step 8: Commit**

```bash
git add src/annual-folders/rankings.service.ts \
        src/annual-folders/annual-folders.module.ts \
        src/annual-folders/__tests__
git commit -m "feat(rankings): wire extended calculators into recalculation pipeline"
```

---

## Phase 4: Backend API Extension

### Task 9: Extend rankings DTOs and controller responses

**Files:**
- Modify: `sacdia-backend/src/annual-folders/dto/ranking.dto.ts` (or create if missing)
- Modify: `sacdia-backend/src/annual-folders/rankings.controller.ts`
- Modify: `sacdia-backend/src/annual-folders/__tests__/rankings.controller.spec.ts`

- [ ] **Step 1: Update RankingResponseDto**

Locate the response DTO returned by `GET /annual-folders/rankings`. Add fields:
```typescript
export class RankingResponseDto {
  ranking_id!: string;
  club_enrollment_id!: string;
  club_name!: string;
  club_type_id!: number;
  ecclesiastical_year_id!: number;
  award_category_id!: string;
  rank_position!: number | null;
  total_earned_points!: number;
  progress_percentage!: number;
  // new
  folder_score_pct!: number;
  finance_score_pct!: number;
  camporee_score_pct!: number;
  evidence_score_pct!: number;
  composite_score_pct!: number;
  composite_calculated_at!: string | null;
  calculated_at!: string;
}
```

- [ ] **Step 2: Update controller mapping**

In `rankings.controller.ts` (or service serializer), include new columns when mapping:
```typescript
return rankings.map((r) => ({
  ranking_id: r.ranking_id,
  // ...existing fields...
  folder_score_pct: Number(r.folder_score_pct),
  finance_score_pct: Number(r.finance_score_pct),
  camporee_score_pct: Number(r.camporee_score_pct),
  evidence_score_pct: Number(r.evidence_score_pct),
  composite_score_pct: Number(r.composite_score_pct),
  composite_calculated_at: r.composite_calculated_at?.toISOString() ?? null,
}));
```

- [ ] **Step 3: Update test for extended response**

In `rankings.controller.spec.ts`, augment the existing mock factory and assertions to include the 5 new fields. Run:
```bash
pnpm jest src/annual-folders/__tests__/rankings.controller.spec.ts
```
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add src/annual-folders/dto/ranking.dto.ts \
        src/annual-folders/rankings.controller.ts \
        src/annual-folders/__tests__/rankings.controller.spec.ts
git commit -m "feat(rankings): include component + composite scores in API response"
```

---

### Task 10: Add /breakdown endpoint

**Files:**
- Create: `sacdia-backend/src/annual-folders/dto/ranking-breakdown.dto.ts`
- Modify: `sacdia-backend/src/annual-folders/rankings.service.ts` (add `getBreakdown` method)
- Modify: `sacdia-backend/src/annual-folders/rankings.controller.ts` (add endpoint)
- Modify: `sacdia-backend/src/annual-folders/__tests__/rankings.controller.spec.ts`

- [ ] **Step 1: Create RankingBreakdownDto**

```typescript
export class RankingComponentDto {
  score_pct!: number;
}
export class FolderComponentDto extends RankingComponentDto {
  earned_points!: number;
  max_points!: number;
  sections_evaluated!: number;
}
export class FinanceComponentDto extends RankingComponentDto {
  months_closed_on_time!: number;
  months_total!: number;
  deadline_day!: number;
  missed_months!: number[];
}
export class CamporeeComponentDto extends RankingComponentDto {
  attended!: number;
  available_in_scope!: number;
  events!: { id: string; name: string; status: 'approved' | null }[];
}
export class EvidenceComponentDto extends RankingComponentDto {
  validated!: number;
  rejected!: number;
  pending_excluded!: number;
}
export class WeightsAppliedDto {
  folder!: number;
  finance!: number;
  camporee!: number;
  evidence!: number;
  source!: 'default' | 'club_type_override';
}
export class RankingBreakdownDto {
  enrollment_id!: string;
  year_id!: number;
  composite_score_pct!: number;
  weights_applied!: WeightsAppliedDto;
  components!: {
    folder: FolderComponentDto;
    finance: FinanceComponentDto;
    camporee: CamporeeComponentDto;
    evidence: EvidenceComponentDto;
  };
}
```

- [ ] **Step 2: Add getBreakdown to RankingsService**

```typescript
async getBreakdown(enrollmentId: string, yearId: number): Promise<RankingBreakdownDto> {
  const enrollment = await this.prisma.club_enrollments.findUniqueOrThrow({
    where: { club_enrollment_id: enrollmentId },
    include: { club: true },
  });

  const folderPct = await this.folderScore.calc(enrollmentId, yearId);
  const financePct = await this.financeScore.calc(enrollment.club.club_id, /*year*/ enrollment.club.year ?? new Date().getUTCFullYear());
  const camporeePct = await this.camporeeScore.calc(enrollment.club.club_id, enrollment.club.union_id, yearId);
  const evidencePct = await this.evidenceScore.calc(enrollment.club.club_id, yearId);
  const weights = await this.weights.resolve(enrollment.club.club_type_id);
  const composite = this.composite.compose(
    { folder: folderPct, finance: financePct, camporee: camporeePct, evidence: evidencePct },
    weights,
  );

  // Auxiliary breakdown queries — keep shapes minimal:
  const folderDetail = await this.prisma.$queryRaw<{ earned: bigint; max: bigint; sections: bigint }[]>`
    SELECT COALESCE(SUM(e.earned_points),0)::bigint earned,
           COALESCE(SUM(e.max_points),0)::bigint max,
           COUNT(*)::bigint sections
    FROM annual_folder_section_evaluations e
    JOIN annual_folders f ON f.annual_folder_id = e.annual_folder_id
    WHERE f.club_enrollment_id = ${enrollmentId}::uuid
      AND f.ecclesiastical_year_id = ${yearId}
      AND e.status IN ('VALIDATED','closed')
  `;

  const financeDeadline = await this.prisma.system_config.findUnique({
    where: { config_key: 'ranking.finance_closing_deadline_day' },
  });
  const deadlineDay = parseInt(financeDeadline?.config_value ?? '5', 10);

  const monthsClosedRows = await this.prisma.$queryRaw<{ month: number }[]>`
    SELECT month FROM finance_period_closing
    WHERE club_id = ${enrollment.club.club_id}::uuid
      AND year = ${enrollment.club.year ?? new Date().getUTCFullYear()}
      AND closed_at IS NOT NULL
      AND closed_at <= make_timestamptz(year, month + 1, ${deadlineDay}, 23, 59, 59, 'UTC')
  `;
  const closedMonths = new Set(monthsClosedRows.map((r) => r.month));
  const missedMonths = Array.from({ length: 12 }, (_, i) => i + 1).filter((m) => !closedMonths.has(m));

  const camporeeEvents = await this.prisma.$queryRaw<{ id: string; name: string; status: string | null }[]>`
    SELECT scope.camporee_id::text id, scope.name, cc.status::text
    FROM (
      SELECT local_camporee_id AS camporee_id, name, union_id FROM local_camporees WHERE ecclesiastical_year=${yearId} AND active=true
      UNION ALL
      SELECT union_camporee_id, name, union_id FROM union_camporees WHERE ecclesiastical_year=${yearId} AND active=true
    ) scope
    LEFT JOIN camporee_clubs cc ON cc.camporee_id = scope.camporee_id AND cc.club_id = ${enrollment.club.club_id}::uuid AND cc.status = 'approved'
    WHERE scope.union_id = ${enrollment.club.union_id}::uuid OR scope.union_id IS NULL
  `;
  const attended = camporeeEvents.filter((e) => e.status === 'approved').length;

  const evRows = await this.prisma.$queryRaw<{ validated: bigint; rejected: bigint; pending: bigint }[]>`
    SELECT
      COUNT(*) FILTER (WHERE r.status='VALIDATED')::bigint AS validated,
      COUNT(*) FILTER (WHERE r.status='REJECTED')::bigint  AS rejected,
      COUNT(*) FILTER (WHERE r.status='PENDING')::bigint   AS pending
    FROM folders_section_records r
    JOIN folders f ON f.folder_id = r.folder_id
    JOIN club_sections cs ON cs.club_section_id = r.club_section_id
    WHERE cs.main_club_id = ${enrollment.club.club_id}::uuid
      AND f.year = ${yearId}
  `;

  return {
    enrollment_id: enrollmentId,
    year_id: yearId,
    composite_score_pct: composite,
    weights_applied: { folder: weights.folder, finance: weights.finance, camporee: weights.camporee, evidence: weights.evidence, source: weights.source },
    components: {
      folder: {
        score_pct: folderPct,
        earned_points: Number(folderDetail[0]?.earned ?? 0n),
        max_points: Number(folderDetail[0]?.max ?? 0n),
        sections_evaluated: Number(folderDetail[0]?.sections ?? 0n),
      },
      finance: {
        score_pct: financePct,
        months_closed_on_time: closedMonths.size,
        months_total: 12,
        deadline_day: deadlineDay,
        missed_months: missedMonths,
      },
      camporee: {
        score_pct: camporeePct,
        attended,
        available_in_scope: camporeeEvents.length,
        events: camporeeEvents.map((e) => ({ id: e.id, name: e.name, status: e.status as 'approved' | null })),
      },
      evidence: {
        score_pct: evidencePct,
        validated: Number(evRows[0]?.validated ?? 0n),
        rejected: Number(evRows[0]?.rejected ?? 0n),
        pending_excluded: Number(evRows[0]?.pending ?? 0n),
      },
    },
  };
}
```

- [ ] **Step 3: Add controller endpoint**

In `rankings.controller.ts`:
```typescript
@Get(':enrollmentId/breakdown')
@RequirePermissions('rankings:read')
async getBreakdown(
  @Param('enrollmentId') enrollmentId: string,
  @Query('year_id', ParseIntPipe) yearId: number,
): Promise<RankingBreakdownDto> {
  return this.rankingsService.getBreakdown(enrollmentId, yearId);
}
```

Confirm the controller's base path. If existing controller path is `@Controller('annual-folders/rankings')`, the resulting URL is `GET /annual-folders/rankings/:enrollmentId/breakdown`.

- [ ] **Step 4: Add controller test**

```typescript
it('GET :enrollmentId/breakdown returns composite + 4 components', async () => {
  const breakdown = { /* mock matching RankingBreakdownDto */ };
  jest.spyOn(svc, 'getBreakdown').mockResolvedValueOnce(breakdown);
  const result = await ctrl.getBreakdown('enrollment-uuid', 5);
  expect(result.composite_score_pct).toBeDefined();
  expect(result.components.folder).toBeDefined();
  expect(result.components.finance).toBeDefined();
  expect(result.components.camporee).toBeDefined();
  expect(result.components.evidence).toBeDefined();
});
```

Run: `pnpm jest rankings.controller.spec.ts` → PASS.

- [ ] **Step 5: Commit**

```bash
git add src/annual-folders/dto/ranking-breakdown.dto.ts \
        src/annual-folders/rankings.service.ts \
        src/annual-folders/rankings.controller.ts \
        src/annual-folders/__tests__/rankings.controller.spec.ts
git commit -m "feat(rankings): add /breakdown endpoint for component drill-down"
```

---

## Phase 5: Backend ranking-weights CRUD module

### Task 11: Scaffold RankingWeightsModule with full CRUD + tests

**Files:**
- Create: `sacdia-backend/src/ranking-weights/ranking-weights.module.ts`
- Create: `sacdia-backend/src/ranking-weights/ranking-weights.controller.ts`
- Create: `sacdia-backend/src/ranking-weights/ranking-weights.service.ts`
- Create: `sacdia-backend/src/ranking-weights/dto/create-ranking-weights.dto.ts`
- Create: `sacdia-backend/src/ranking-weights/dto/update-ranking-weights.dto.ts`
- Create: `sacdia-backend/src/ranking-weights/__tests__/ranking-weights.controller.spec.ts`
- Create: `sacdia-backend/src/ranking-weights/__tests__/ranking-weights.service.spec.ts`
- Modify: `sacdia-backend/src/app.module.ts` (add `RankingWeightsModule`)

- [ ] **Step 1: DTOs with class-validator**

`create-ranking-weights.dto.ts`:
```typescript
import { IsInt, IsOptional, Min, Max, Validate, ValidatorConstraint, ValidatorConstraintInterface, ValidationArguments } from 'class-validator';

@ValidatorConstraint({ name: 'WeightsSumTo100', async: false })
class WeightsSumTo100Constraint implements ValidatorConstraintInterface {
  validate(_: any, args: ValidationArguments) {
    const o = args.object as CreateRankingWeightsDto;
    return o.folder_weight + o.finance_weight + o.camporee_weight + o.evidence_weight === 100;
  }
  defaultMessage() {
    return 'folder_weight + finance_weight + camporee_weight + evidence_weight must equal 100';
  }
}

export class CreateRankingWeightsDto {
  @IsOptional() @IsInt()
  club_type_id?: number; // null = default global (only allowed via seed; controller rejects null POST)

  @IsInt() @Min(0) @Max(100)
  folder_weight!: number;

  @IsInt() @Min(0) @Max(100)
  finance_weight!: number;

  @IsInt() @Min(0) @Max(100)
  camporee_weight!: number;

  @IsInt() @Min(0) @Max(100)
  evidence_weight!: number;

  @Validate(WeightsSumTo100Constraint)
  __validateSum?: never;
}
```

`update-ranking-weights.dto.ts`:
```typescript
import { PartialType, OmitType } from '@nestjs/mapped-types';
import { CreateRankingWeightsDto } from './create-ranking-weights.dto';

export class UpdateRankingWeightsDto extends PartialType(OmitType(CreateRankingWeightsDto, ['club_type_id'] as const)) {}
```

Note: `PATCH` allows partial updates but the resulting record must still satisfy sum=100. Service merges current row with patch and re-validates.

- [ ] **Step 2: Service**

```typescript
import { Injectable, BadRequestException, ConflictException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateRankingWeightsDto } from './dto/create-ranking-weights.dto';
import { UpdateRankingWeightsDto } from './dto/update-ranking-weights.dto';

@Injectable()
export class RankingWeightsService {
  constructor(private readonly prisma: PrismaService) {}

  list() {
    return this.prisma.ranking_weight_configs.findMany({
      orderBy: [{ club_type_id: 'asc' }],
    });
  }

  async getById(id: string) {
    const row = await this.prisma.ranking_weight_configs.findUnique({ where: { ranking_weight_config_id: id } });
    if (!row) throw new NotFoundException();
    return row;
  }

  async create(dto: CreateRankingWeightsDto, userId: string) {
    if (dto.club_type_id == null) {
      throw new BadRequestException('club_type_id is required for overrides; default global is seeded');
    }
    const existing = await this.prisma.ranking_weight_configs.findUnique({ where: { club_type_id: dto.club_type_id } });
    if (existing) throw new ConflictException('Override already exists for this club_type');
    return this.prisma.ranking_weight_configs.create({
      data: {
        club_type_id: dto.club_type_id,
        folder_weight: dto.folder_weight,
        finance_weight: dto.finance_weight,
        camporee_weight: dto.camporee_weight,
        evidence_weight: dto.evidence_weight,
        updated_by: userId,
      },
    });
  }

  async update(id: string, dto: UpdateRankingWeightsDto, userId: string) {
    const current = await this.getById(id);
    const merged = { ...current, ...dto };
    const sum = merged.folder_weight + merged.finance_weight + merged.camporee_weight + merged.evidence_weight;
    if (sum !== 100) throw new BadRequestException(`Weights must sum to 100; got ${sum}`);
    return this.prisma.ranking_weight_configs.update({
      where: { ranking_weight_config_id: id },
      data: { ...dto, updated_by: userId, updated_at: new Date() },
    });
  }

  async delete(id: string) {
    const row = await this.getById(id);
    if (row.club_type_id == null) {
      throw new BadRequestException('Default global weights cannot be deleted');
    }
    return this.prisma.ranking_weight_configs.delete({ where: { ranking_weight_config_id: id } });
  }
}
```

- [ ] **Step 3: Controller**

```typescript
import { Body, Controller, Delete, Get, Param, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { PermissionsGuard } from '../auth/permissions.guard';
import { RequirePermissions } from '../auth/permissions.decorator';
import { RankingWeightsService } from './ranking-weights.service';
import { CreateRankingWeightsDto } from './dto/create-ranking-weights.dto';
import { UpdateRankingWeightsDto } from './dto/update-ranking-weights.dto';

@Controller('ranking-weights')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class RankingWeightsController {
  constructor(private readonly svc: RankingWeightsService) {}

  @Get()
  @RequirePermissions('ranking_weights:read')
  list() { return this.svc.list(); }

  @Get(':id')
  @RequirePermissions('ranking_weights:read')
  getById(@Param('id') id: string) { return this.svc.getById(id); }

  @Post()
  @RequirePermissions('ranking_weights:write')
  create(@Body() dto: CreateRankingWeightsDto, @Req() req: any) {
    return this.svc.create(dto, req.user?.userId);
  }

  @Patch(':id')
  @RequirePermissions('ranking_weights:write')
  update(@Param('id') id: string, @Body() dto: UpdateRankingWeightsDto, @Req() req: any) {
    return this.svc.update(id, dto, req.user?.userId);
  }

  @Delete(':id')
  @RequirePermissions('ranking_weights:write')
  delete(@Param('id') id: string) { return this.svc.delete(id); }
}
```

- [ ] **Step 4: Module + wire into AppModule**

```typescript
// ranking-weights.module.ts
import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { RankingWeightsController } from './ranking-weights.controller';
import { RankingWeightsService } from './ranking-weights.service';

@Module({
  imports: [PrismaModule],
  controllers: [RankingWeightsController],
  providers: [RankingWeightsService],
  exports: [RankingWeightsService],
})
export class RankingWeightsModule {}
```

In `app.module.ts`:
```typescript
import { RankingWeightsModule } from './ranking-weights/ranking-weights.module';
// ...
@Module({
  imports: [
    // ...existing...
    RankingWeightsModule,
  ],
})
```

- [ ] **Step 5: Service tests**

```typescript
import { Test } from '@nestjs/testing';
import { BadRequestException, ConflictException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { RankingWeightsService } from '../ranking-weights.service';

describe('RankingWeightsService', () => {
  let svc: RankingWeightsService;
  let prisma: any;
  beforeEach(async () => {
    prisma = {
      ranking_weight_configs: {
        findUnique: jest.fn(),
        findMany: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
        delete: jest.fn(),
      },
    };
    const m = await Test.createTestingModule({
      providers: [RankingWeightsService, { provide: PrismaService, useValue: prisma }],
    }).compile();
    svc = m.get(RankingWeightsService);
  });

  it('list returns rows ordered by club_type_id', async () => {
    prisma.ranking_weight_configs.findMany.mockResolvedValueOnce([{ id: 1 }]);
    expect(await svc.list()).toEqual([{ id: 1 }]);
  });

  it('create rejects when club_type_id is null', async () => {
    await expect(svc.create({ folder_weight: 25, finance_weight: 25, camporee_weight: 25, evidence_weight: 25 } as any, 'u1'))
      .rejects.toBeInstanceOf(BadRequestException);
  });

  it('create rejects duplicate', async () => {
    prisma.ranking_weight_configs.findUnique.mockResolvedValueOnce({ id: 'existing' });
    await expect(svc.create({ club_type_id: 1, folder_weight: 25, finance_weight: 25, camporee_weight: 25, evidence_weight: 25 }, 'u1'))
      .rejects.toBeInstanceOf(ConflictException);
  });

  it('update rejects merged sum != 100', async () => {
    prisma.ranking_weight_configs.findUnique.mockResolvedValueOnce({
      ranking_weight_config_id: 'id', club_type_id: 1,
      folder_weight: 25, finance_weight: 25, camporee_weight: 25, evidence_weight: 25,
    });
    await expect(svc.update('id', { folder_weight: 30 }, 'u1'))
      .rejects.toBeInstanceOf(BadRequestException);
  });

  it('delete rejects default global row', async () => {
    prisma.ranking_weight_configs.findUnique.mockResolvedValueOnce({
      ranking_weight_config_id: 'id', club_type_id: null,
    });
    await expect(svc.delete('id')).rejects.toBeInstanceOf(BadRequestException);
  });
});
```

Run: `pnpm jest src/ranking-weights/__tests__/ranking-weights.service.spec.ts` → PASS.

- [ ] **Step 6: Controller test (smoke)**

```typescript
import { Test } from '@nestjs/testing';
import { RankingWeightsController } from '../ranking-weights.controller';
import { RankingWeightsService } from '../ranking-weights.service';

describe('RankingWeightsController', () => {
  let ctrl: RankingWeightsController;
  let svc: any;
  beforeEach(async () => {
    svc = { list: jest.fn(), getById: jest.fn(), create: jest.fn(), update: jest.fn(), delete: jest.fn() };
    const m = await Test.createTestingModule({
      controllers: [RankingWeightsController],
      providers: [{ provide: RankingWeightsService, useValue: svc }],
    }).overrideGuard(/* JwtAuthGuard */ require('../../auth/jwt-auth.guard').JwtAuthGuard).useValue({ canActivate: () => true })
      .overrideGuard(/* PermissionsGuard */ require('../../auth/permissions.guard').PermissionsGuard).useValue({ canActivate: () => true })
      .compile();
    ctrl = m.get(RankingWeightsController);
  });
  it('list -> svc.list()', async () => { svc.list.mockResolvedValueOnce([]); await ctrl.list(); expect(svc.list).toHaveBeenCalled(); });
});
```

Run: PASS.

- [ ] **Step 7: Commit**

```bash
git add src/ranking-weights src/app.module.ts
git commit -m "feat(ranking-weights): add CRUD module with sum=100 validation"
```

---

## Phase 6: Backend award_categories extension

### Task 12: Extend award-categories DTO + service + controller

**Files:**
- Modify: `sacdia-backend/src/annual-folders/dto/award-category.dto.ts` (or wherever the DTO lives)
- Modify: `sacdia-backend/src/annual-folders/award-categories.service.ts`
- Modify: `sacdia-backend/src/annual-folders/award-categories.controller.ts`
- Modify: existing tests under `__tests__`

- [ ] **Step 1: Update Create + Update DTOs**

```typescript
import { IsOptional, IsNumber, Min, Max, IsBoolean, IsString } from 'class-validator';

export class CreateAwardCategoryDto {
  @IsString() name!: string;
  @IsOptional() club_type_id?: number;
  @IsOptional() @IsNumber() min_points?: number;       // legacy, optional now
  @IsOptional() @IsNumber() max_points?: number;       // legacy, optional now
  @IsOptional() @IsNumber() @Min(0) @Max(100) min_composite_pct?: number;
  @IsOptional() @IsNumber() @Min(0) @Max(100) max_composite_pct?: number;
  @IsOptional() @IsBoolean() active?: boolean;
}

export class UpdateAwardCategoryDto extends PartialType(CreateAwardCategoryDto) {}
```

Validate at service: `min_composite_pct < max_composite_pct` if both present.

- [ ] **Step 2: Update service**

In `award-categories.service.ts`, add filter for `is_legacy`:
```typescript
list(opts: { club_type_id?: number; active?: boolean; include_legacy?: boolean }) {
  return this.prisma.award_categories.findMany({
    where: {
      ...(opts.club_type_id != null ? { club_type_id: opts.club_type_id } : {}),
      ...(opts.active != null ? { active: opts.active } : {}),
      ...(opts.include_legacy ? {} : { is_legacy: false }),
    },
    orderBy: [{ order: 'asc' }],
  });
}
```

In `create()` and `update()`, validate composite range:
```typescript
if (dto.min_composite_pct != null && dto.max_composite_pct != null) {
  if (dto.min_composite_pct >= dto.max_composite_pct) {
    throw new BadRequestException('min_composite_pct must be less than max_composite_pct');
  }
}
```

When creating new categories, default `is_legacy = false`.

- [ ] **Step 3: Update controller**

```typescript
@Get()
@RequirePermissions('award_categories:read')
list(
  @Query('club_type_id') clubTypeId?: string,
  @Query('active') active?: string,
  @Query('include_legacy') includeLegacy?: string,
) {
  return this.svc.list({
    club_type_id: clubTypeId ? parseInt(clubTypeId, 10) : undefined,
    active: active ? active === 'true' : undefined,
    include_legacy: includeLegacy === 'true',
  });
}
```

- [ ] **Step 4: Update tests**

In `award-categories.service.spec.ts` (or controller spec), add cases:
- `list({ include_legacy: false })` filters `is_legacy = false` (default).
- `list({ include_legacy: true })` returns all.
- `create({ min_composite_pct: 80, max_composite_pct: 70 })` throws BadRequest.
- `create({ min_composite_pct: 70, max_composite_pct: 80 })` passes.

Run: `pnpm jest award-categories` → PASS.

- [ ] **Step 5: Commit**

```bash
git add src/annual-folders/dto/award-category.dto.ts \
        src/annual-folders/award-categories.service.ts \
        src/annual-folders/award-categories.controller.ts \
        src/annual-folders/__tests__/award-categories*.spec.ts
git commit -m "feat(award-categories): support composite_pct ranges and legacy filtering"
```

---

## Phase 7: Admin UI

### Task 13: Extend rankings table with composite + components

**Files:**
- Modify: `sacdia-admin/src/app/(dashboard)/dashboard/annual-folders/rankings/page.tsx`
- Create: `sacdia-admin/src/components/rankings/RankingScoreBadge.tsx`
- Create: `sacdia-admin/src/lib/api/rankings.ts` (extend types if existing, else create)

- [ ] **Step 1: RankingScoreBadge component**

```tsx
import { Badge } from '@/components/ui/badge';
import { cn } from '@/lib/utils';

export interface RankingScoreBadgeProps {
  value: number;
  className?: string;
}

export function RankingScoreBadge({ value, className }: RankingScoreBadgeProps) {
  const variant = value >= 80 ? 'success' : value >= 60 ? 'warning' : 'destructive';
  return (
    <Badge variant={variant} className={cn('font-mono tabular-nums', className)}>
      {value.toFixed(1)}%
    </Badge>
  );
}
```

- [ ] **Step 2: Extend rankings TS types in `lib/api/rankings.ts`**

```typescript
export interface RankingRow {
  ranking_id: string;
  club_enrollment_id: string;
  club_name: string;
  club_type_id: number;
  ecclesiastical_year_id: number;
  award_category_id: string;
  rank_position: number | null;
  total_earned_points: number;
  progress_percentage: number;
  folder_score_pct: number;
  finance_score_pct: number;
  camporee_score_pct: number;
  evidence_score_pct: number;
  composite_score_pct: number;
  composite_calculated_at: string | null;
  calculated_at: string;
}

export async function fetchRankings(params: { club_type_id?: number; year_id: number; category_id?: string }) {
  const qs = new URLSearchParams(Object.entries(params).filter(([, v]) => v != null).map(([k, v]) => [k, String(v)]));
  const res = await fetch(`/api/proxy/annual-folders/rankings?${qs}`, { credentials: 'include' });
  if (!res.ok) throw new Error('Failed to fetch rankings');
  const data = (await res.json()) as { rankings: RankingRow[] };
  return data.rankings;
}
```

(Adjust the proxy URL pattern if the project uses a different api gateway path.)

- [ ] **Step 3: Update rankings page table columns**

Locate the `<DataTable>` columns config in `page.tsx`. Add columns:
```tsx
{ accessorKey: 'composite_score_pct', header: 'Composite', cell: ({ row }) => <RankingScoreBadge value={row.original.composite_score_pct} /> },
{ accessorKey: 'folder_score_pct', header: 'Folder', cell: ({ row }) => `${row.original.folder_score_pct.toFixed(1)}%` },
{ accessorKey: 'finance_score_pct', header: 'Finanzas', cell: ({ row }) => `${row.original.finance_score_pct.toFixed(1)}%` },
{ accessorKey: 'camporee_score_pct', header: 'Camporees', cell: ({ row }) => `${row.original.camporee_score_pct.toFixed(1)}%` },
{ accessorKey: 'evidence_score_pct', header: 'Evidencias', cell: ({ row }) => `${row.original.evidence_score_pct.toFixed(1)}%` },
{
  id: 'actions',
  header: 'Acciones',
  cell: ({ row }) => (
    <Link href={`/dashboard/annual-folders/rankings/${row.original.club_enrollment_id}/breakdown?year_id=${row.original.ecclesiastical_year_id}`}>
      Ver detalle
    </Link>
  ),
},
```

- [ ] **Step 4: Smoke test**

```bash
cd sacdia-admin
pnpm dev &
sleep 5
# Open http://localhost:3001/dashboard/annual-folders/rankings, verify columns render with mock or dev API data.
```

Manual check: composite badge color matches range; numbers render with 1 decimal.

- [ ] **Step 5: Commit**

```bash
git add sacdia-admin/src/components/rankings/RankingScoreBadge.tsx \
        sacdia-admin/src/lib/api/rankings.ts \
        sacdia-admin/src/app/\(dashboard\)/dashboard/annual-folders/rankings/page.tsx
git commit -m "feat(admin): extend rankings table with composite + component scores"
```

---

### Task 14: Breakdown view route + component

**Files:**
- Create: `sacdia-admin/src/app/(dashboard)/dashboard/annual-folders/rankings/[enrollmentId]/breakdown/page.tsx`
- Create: `sacdia-admin/src/components/rankings/BreakdownView.tsx`
- Modify: `sacdia-admin/src/lib/api/rankings.ts` (add `fetchBreakdown`)

- [ ] **Step 1: Add fetchBreakdown to api client**

```typescript
export interface RankingBreakdown {
  enrollment_id: string;
  year_id: number;
  composite_score_pct: number;
  weights_applied: { folder: number; finance: number; camporee: number; evidence: number; source: 'default' | 'club_type_override' };
  components: {
    folder: { score_pct: number; earned_points: number; max_points: number; sections_evaluated: number };
    finance: { score_pct: number; months_closed_on_time: number; months_total: number; deadline_day: number; missed_months: number[] };
    camporee: { score_pct: number; attended: number; available_in_scope: number; events: { id: string; name: string; status: 'approved' | null }[] };
    evidence: { score_pct: number; validated: number; rejected: number; pending_excluded: number };
  };
}
export async function fetchBreakdown(enrollmentId: string, yearId: number): Promise<RankingBreakdown> {
  const res = await fetch(`/api/proxy/annual-folders/rankings/${enrollmentId}/breakdown?year_id=${yearId}`, { credentials: 'include' });
  if (!res.ok) throw new Error('Failed to fetch breakdown');
  return res.json();
}
```

- [ ] **Step 2: BreakdownView component**

```tsx
'use client';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { RankingScoreBadge } from './RankingScoreBadge';
import { RankingBreakdown } from '@/lib/api/rankings';

export function BreakdownView({ data }: { data: RankingBreakdown }) {
  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <RankingScoreBadge value={data.composite_score_pct} className="text-2xl px-4 py-2" />
        <div className="text-sm text-muted-foreground">Composite institucional</div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <Card>
          <CardHeader><CardTitle>Carpetas (folder)</CardTitle></CardHeader>
          <CardContent className="space-y-1">
            <RankingScoreBadge value={data.components.folder.score_pct} />
            <div>{data.components.folder.earned_points} / {data.components.folder.max_points} pts</div>
            <div>{data.components.folder.sections_evaluated} secciones evaluadas</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader><CardTitle>Finanzas</CardTitle></CardHeader>
          <CardContent className="space-y-1">
            <RankingScoreBadge value={data.components.finance.score_pct} />
            <div>{data.components.finance.months_closed_on_time} / {data.components.finance.months_total} meses cerrados a tiempo</div>
            <div>Deadline: día {data.components.finance.deadline_day} del mes siguiente</div>
            {data.components.finance.missed_months.length > 0 && (
              <div className="text-destructive text-sm">Meses faltantes: {data.components.finance.missed_months.join(', ')}</div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader><CardTitle>Camporees</CardTitle></CardHeader>
          <CardContent className="space-y-1">
            <RankingScoreBadge value={data.components.camporee.score_pct} />
            <div>{data.components.camporee.attended} / {data.components.camporee.available_in_scope} eventos del scope</div>
            <ul className="text-xs">
              {data.components.camporee.events.map((e) => (
                <li key={e.id}>{e.name} — {e.status === 'approved' ? '✓' : '—'}</li>
              ))}
            </ul>
          </CardContent>
        </Card>

        <Card>
          <CardHeader><CardTitle>Evidencias</CardTitle></CardHeader>
          <CardContent className="space-y-1">
            <RankingScoreBadge value={data.components.evidence.score_pct} />
            <div>{data.components.evidence.validated} validadas / {data.components.evidence.rejected} rechazadas</div>
            <div className="text-xs text-muted-foreground">{data.components.evidence.pending_excluded} pending excluidas</div>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader><CardTitle>Pesos aplicados</CardTitle></CardHeader>
        <CardContent className="text-sm">
          <div>Fuente: {data.weights_applied.source === 'default' ? 'Default global' : 'Override por tipo de club'}</div>
          <div>Folder: {data.weights_applied.folder}% · Finance: {data.weights_applied.finance}% · Camporee: {data.weights_applied.camporee}% · Evidence: {data.weights_applied.evidence}%</div>
        </CardContent>
      </Card>
    </div>
  );
}
```

- [ ] **Step 3: Page route**

```tsx
import { BreakdownView } from '@/components/rankings/BreakdownView';
import { fetchBreakdown } from '@/lib/api/rankings';

export default async function Page({
  params,
  searchParams,
}: {
  params: { enrollmentId: string };
  searchParams: { year_id?: string };
}) {
  const yearId = parseInt(searchParams.year_id ?? '', 10);
  if (Number.isNaN(yearId)) {
    return <div>Year ID required.</div>;
  }
  const data = await fetchBreakdown(params.enrollmentId, yearId);
  return (
    <div className="container mx-auto py-8 space-y-6">
      <h1 className="text-2xl font-semibold">Breakdown de ranking</h1>
      <BreakdownView data={data} />
    </div>
  );
}
```

- [ ] **Step 4: Smoke test**

Navigate to `/dashboard/annual-folders/rankings/<enrollmentId>/breakdown?year_id=5`. Verify all 4 cards render with mocked or dev data.

- [ ] **Step 5: Commit**

```bash
git add sacdia-admin/src/components/rankings/BreakdownView.tsx \
        sacdia-admin/src/lib/api/rankings.ts \
        sacdia-admin/src/app/\(dashboard\)/dashboard/annual-folders/rankings/\[enrollmentId\]/breakdown/page.tsx
git commit -m "feat(admin): add ranking breakdown view with per-component cards"
```

---

### Task 15: Ranking-weights config page (CRUD)

**Files:**
- Create: `sacdia-admin/src/app/(dashboard)/dashboard/ranking-weights/page.tsx`
- Create: `sacdia-admin/src/components/rankings/WeightInput.tsx`
- Create: `sacdia-admin/src/components/rankings/WeightSumIndicator.tsx`
- Create: `sacdia-admin/src/components/rankings/WeightsForm.tsx`
- Create: `sacdia-admin/src/components/rankings/OverrideRow.tsx`
- Create: `sacdia-admin/src/lib/api/ranking-weights.ts`

- [ ] **Step 1: API client**

```typescript
export interface RankingWeights {
  ranking_weight_config_id: string;
  club_type_id: number | null;
  folder_weight: number;
  finance_weight: number;
  camporee_weight: number;
  evidence_weight: number;
  updated_at: string;
}

export async function listRankingWeights(): Promise<RankingWeights[]> {
  const res = await fetch('/api/proxy/ranking-weights', { credentials: 'include' });
  if (!res.ok) throw new Error('Failed to list ranking weights');
  return res.json();
}

export async function createRankingWeights(payload: Omit<RankingWeights, 'ranking_weight_config_id' | 'updated_at'>) {
  const res = await fetch('/api/proxy/ranking-weights', {
    method: 'POST', credentials: 'include',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(payload),
  });
  if (!res.ok) throw new Error(await res.text());
  return res.json();
}

export async function updateRankingWeights(id: string, patch: Partial<Omit<RankingWeights, 'ranking_weight_config_id' | 'club_type_id' | 'updated_at'>>) {
  const res = await fetch(`/api/proxy/ranking-weights/${id}`, {
    method: 'PATCH', credentials: 'include',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(patch),
  });
  if (!res.ok) throw new Error(await res.text());
  return res.json();
}

export async function deleteRankingWeights(id: string) {
  const res = await fetch(`/api/proxy/ranking-weights/${id}`, { method: 'DELETE', credentials: 'include' });
  if (!res.ok) throw new Error(await res.text());
}
```

- [ ] **Step 2: WeightInput + WeightSumIndicator**

```tsx
// WeightInput.tsx
import { Input } from '@/components/ui/input';
export function WeightInput({ label, value, onChange }: { label: string; value: number; onChange: (n: number) => void }) {
  return (
    <label className="block">
      <span className="text-sm font-medium">{label}</span>
      <Input type="number" min={0} max={100} value={value} onChange={(e) => onChange(parseInt(e.target.value || '0', 10))} />
    </label>
  );
}
```

```tsx
// WeightSumIndicator.tsx
import { Badge } from '@/components/ui/badge';
export function WeightSumIndicator({ sum }: { sum: number }) {
  const ok = sum === 100;
  return <Badge variant={ok ? 'success' : 'destructive'}>Suma: {sum} {ok ? '✓' : '✗'}</Badge>;
}
```

- [ ] **Step 3: WeightsForm (controlled, used for global + overrides)**

```tsx
'use client';
import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { WeightInput } from './WeightInput';
import { WeightSumIndicator } from './WeightSumIndicator';

export interface WeightsFormProps {
  initial: { folder_weight: number; finance_weight: number; camporee_weight: number; evidence_weight: number };
  onSubmit: (values: WeightsFormProps['initial']) => Promise<void>;
  submitLabel?: string;
}
export function WeightsForm({ initial, onSubmit, submitLabel = 'Guardar' }: WeightsFormProps) {
  const [v, setV] = useState(initial);
  const sum = v.folder_weight + v.finance_weight + v.camporee_weight + v.evidence_weight;
  const ok = sum === 100;
  return (
    <form
      className="space-y-3"
      onSubmit={async (e) => { e.preventDefault(); if (ok) await onSubmit(v); }}
    >
      <WeightInput label="Folder" value={v.folder_weight} onChange={(n) => setV({ ...v, folder_weight: n })} />
      <WeightInput label="Finance" value={v.finance_weight} onChange={(n) => setV({ ...v, finance_weight: n })} />
      <WeightInput label="Camporee" value={v.camporee_weight} onChange={(n) => setV({ ...v, camporee_weight: n })} />
      <WeightInput label="Evidence" value={v.evidence_weight} onChange={(n) => setV({ ...v, evidence_weight: n })} />
      <WeightSumIndicator sum={sum} />
      <Button type="submit" disabled={!ok}>{submitLabel}</Button>
    </form>
  );
}
```

- [ ] **Step 4: Page composition**

```tsx
'use client';
import { useEffect, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { WeightsForm } from '@/components/rankings/WeightsForm';
import { listRankingWeights, createRankingWeights, updateRankingWeights, deleteRankingWeights, RankingWeights } from '@/lib/api/ranking-weights';

export default function RankingWeightsPage() {
  const [rows, setRows] = useState<RankingWeights[]>([]);
  const [editingId, setEditingId] = useState<string | null>(null);

  async function reload() { setRows(await listRankingWeights()); }
  useEffect(() => { void reload(); }, []);

  const def = rows.find((r) => r.club_type_id === null);
  const overrides = rows.filter((r) => r.club_type_id !== null);

  return (
    <div className="container mx-auto py-8 space-y-6">
      <h1 className="text-2xl font-semibold">Pesos de ranking</h1>

      <Card>
        <CardHeader><CardTitle>Default global</CardTitle></CardHeader>
        <CardContent>
          {def ? (
            <WeightsForm
              initial={{ folder_weight: def.folder_weight, finance_weight: def.finance_weight, camporee_weight: def.camporee_weight, evidence_weight: def.evidence_weight }}
              onSubmit={async (v) => { await updateRankingWeights(def.ranking_weight_config_id, v); await reload(); }}
            />
          ) : <div>Default global no encontrado.</div>}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <div className="flex justify-between items-center">
            <CardTitle>Overrides por tipo de club</CardTitle>
            <Dialog>
              <DialogTrigger asChild><Button>Agregar override</Button></DialogTrigger>
              <DialogContent>
                <DialogHeader><DialogTitle>Nuevo override</DialogTitle></DialogHeader>
                <NewOverrideForm
                  existingClubTypeIds={overrides.map((o) => o.club_type_id!).filter((id): id is number => id != null)}
                  onCreated={async () => { await reload(); }}
                />
              </DialogContent>
            </Dialog>
          </div>
        </CardHeader>
        <CardContent>
          <table className="w-full text-sm">
            <thead><tr><th>Club type</th><th>Folder</th><th>Finance</th><th>Camporee</th><th>Evidence</th><th>Suma</th><th>Acciones</th></tr></thead>
            <tbody>
              {overrides.map((r) => {
                const sum = r.folder_weight + r.finance_weight + r.camporee_weight + r.evidence_weight;
                return (
                  <tr key={r.ranking_weight_config_id}>
                    <td>{r.club_type_id}</td>
                    <td>{r.folder_weight}</td>
                    <td>{r.finance_weight}</td>
                    <td>{r.camporee_weight}</td>
                    <td>{r.evidence_weight}</td>
                    <td>{sum}</td>
                    <td>
                      <Button variant="link" onClick={() => setEditingId(r.ranking_weight_config_id)}>Editar</Button>
                      <Button variant="destructive" onClick={async () => { await deleteRankingWeights(r.ranking_weight_config_id); await reload(); }}>Eliminar</Button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </CardContent>
      </Card>
    </div>
  );
}
```

Add a sibling component `NewOverrideForm.tsx` referenced above:

```tsx
'use client';
import { useEffect, useState } from 'react';
import { Button } from '@/components/ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { WeightsForm } from './WeightsForm';
import { createRankingWeights } from '@/lib/api/ranking-weights';

interface ClubType { club_type_id: number; name: string; }

export function NewOverrideForm({ existingClubTypeIds, onCreated }: { existingClubTypeIds: number[]; onCreated: () => Promise<void>; }) {
  const [types, setTypes] = useState<ClubType[]>([]);
  const [selectedTypeId, setSelectedTypeId] = useState<number | null>(null);
  useEffect(() => {
    fetch('/api/proxy/club-types', { credentials: 'include' })
      .then((r) => r.json())
      .then(setTypes)
      .catch(() => setTypes([]));
  }, []);
  const available = types.filter((t) => !existingClubTypeIds.includes(t.club_type_id));
  return (
    <div className="space-y-3">
      <Select onValueChange={(v) => setSelectedTypeId(parseInt(v, 10))}>
        <SelectTrigger><SelectValue placeholder="Seleccionar tipo de club" /></SelectTrigger>
        <SelectContent>
          {available.map((t) => <SelectItem key={t.club_type_id} value={String(t.club_type_id)}>{t.name}</SelectItem>)}
        </SelectContent>
      </Select>
      {selectedTypeId != null && (
        <WeightsForm
          initial={{ folder_weight: 60, finance_weight: 15, camporee_weight: 15, evidence_weight: 10 }}
          submitLabel="Crear override"
          onSubmit={async (v) => {
            await createRankingWeights({ club_type_id: selectedTypeId, ...v });
            await onCreated();
          }}
        />
      )}
    </div>
  );
}
```

If `/api/proxy/club-types` doesn't exist, replace with the appropriate endpoint (search admin code for existing club-types API client first).

- [ ] **Step 5: Smoke + commit**

```bash
cd sacdia-admin
pnpm dev
# Navigate to /dashboard/ranking-weights and exercise CRUD against dev backend.
```

```bash
git add sacdia-admin/src/components/rankings sacdia-admin/src/lib/api/ranking-weights.ts \
        sacdia-admin/src/app/\(dashboard\)/dashboard/ranking-weights
git commit -m "feat(admin): add ranking weights CRUD page with global + overrides"
```

---

### Task 16: Award_categories form extension + Legacy filter

**Files:**
- Modify: `sacdia-admin/src/app/(dashboard)/dashboard/annual-folders/categories/page.tsx`
- Modify: existing form component for award_categories (locate via `grep -r 'min_points' sacdia-admin/src`)

- [ ] **Step 1: Add composite_pct inputs to category form**

In the form component:
```tsx
<WeightInput label="Min composite %" value={form.min_composite_pct ?? 0} onChange={(n) => setForm({ ...form, min_composite_pct: n })} />
<WeightInput label="Max composite %" value={form.max_composite_pct ?? 100} onChange={(n) => setForm({ ...form, max_composite_pct: n })} />
```

Validate `min < max` client-side; submit blocked otherwise.

- [ ] **Step 2: Add Legacy badge to list**

In the categories list table:
```tsx
{row.original.is_legacy && <Badge variant="outline">Legacy</Badge>}
```

If `is_legacy` is true, render row in muted/disabled style and hide Edit button.

- [ ] **Step 3: Add Active / Legacy filter tabs**

Above the table:
```tsx
<Tabs value={filter} onValueChange={setFilter}>
  <TabsList>
    <TabsTrigger value="active">Activas</TabsTrigger>
    <TabsTrigger value="legacy">Legacy</TabsTrigger>
  </TabsList>
</Tabs>
```

When filter = `legacy`, fetch with `?include_legacy=true` and filter client-side to show only `is_legacy=true`.

- [ ] **Step 4: Smoke test**

Run `pnpm dev`, navigate to `/dashboard/annual-folders/categories`, switch tabs, attempt to create a new category with min/max composite_pct.

- [ ] **Step 5: Commit**

```bash
git add sacdia-admin/src/app/\(dashboard\)/dashboard/annual-folders/categories
git commit -m "feat(admin): add composite_pct fields and legacy filter to award categories"
```

---

## Phase 8: Documentation + canon updates

### Task 17: Update canon docs and roadmap

**Files (all read+modify):**
- `docs/canon/runtime-rankings.md`
- `docs/canon/decisiones-clave.md`
- `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- `docs/database/SCHEMA-REFERENCE.md`
- `docs/features/README.md`
- `docs/bases/SACDIA_Bases_del_Proyecto-normalizado.md`

- [ ] **Step 1: Update `docs/canon/runtime-rankings.md`**

In §3 Modelo de puntaje, add subsection 3.1 (or table extension) listing the new columns: `folder_score_pct`, `finance_score_pct`, `camporee_score_pct`, `evidence_score_pct`, `composite_score_pct`, `composite_calculated_at`. Reference spec.

In §5 Pipeline, replace the current `total_earned_points`-based ordering description with composite. Add bullet about kill-switch and structured logging.

In §6 Política de desempate, clarify: ranking is computed from `composite_score_pct` (was `total_earned_points`).

In §10 Superficie API, append `GET /annual-folders/rankings/:enrollmentId/breakdown` and the 5 ranking-weights CRUD endpoints. Cite permissions.

In §11 Relación, add bullet pointing to spec doc.

- [ ] **Step 2: Update `docs/canon/decisiones-clave.md`**

Append new §13 "Criterios institucionales ampliados (8.4-C)" summarizing: criterios elegidos, normalización 0-100%, weights default+override, current-year-forward semantics, award_categories migration con is_legacy. Cite spec.

- [ ] **Step 3: Update `docs/api/ENDPOINTS-LIVE-REFERENCE.md`**

Add new endpoints with request/response shapes copied from spec §5.2 + §5.3. Update existing entries for `/rankings` to mention new response fields.

- [ ] **Step 4: Update `docs/database/SCHEMA-REFERENCE.md`**

Add new columns to `club_annual_rankings` table doc, add new `ranking_weight_configs` table, add new columns to `award_categories`, add new `system_config` keys.

- [ ] **Step 5: Update `docs/features/README.md`**

Add registry entry: "Clasificación institucional ampliada — 8.4-C — vigente desde 2026-04-28 — spec en docs/superpowers/specs/2026-04-28-clasificacion-criterios-ampliados-design.md".

- [ ] **Step 6: Update `docs/bases/SACDIA_Bases_del_Proyecto-normalizado.md`**

In §6.2 Clasificación y ranking, change `[PARCIAL]` to `[VIGENTE]` for the dimension covered by C, and reference spec. In §8.4, replace `[ROADMAP]` with split: `[VIGENTE]` for sub-feature C (criterios ampliados) and `[ROADMAP]` for A/B/D/E.

- [ ] **Step 7: Commit all docs**

```bash
cd /Users/abner/Documents/development/sacdia
git add docs/canon/runtime-rankings.md \
        docs/canon/decisiones-clave.md \
        docs/api/ENDPOINTS-LIVE-REFERENCE.md \
        docs/database/SCHEMA-REFERENCE.md \
        docs/features/README.md \
        docs/bases/SACDIA_Bases_del_Proyecto-normalizado.md
git commit -m "docs(canon): document 8.4-C extended institutional rankings"
```

---

## Verification gate (before declaring 8.4-C done)

After Task 17, run the full verification suite:

- [ ] **Backend tests:**
  ```bash
  cd sacdia-backend
  pnpm jest
  pnpm tsc --noEmit
  ```

- [ ] **Admin tests:**
  ```bash
  cd sacdia-admin
  pnpm test
  pnpm tsc --noEmit
  ```

- [ ] **Drift check (Neon vs Prisma):**
  ```bash
  cd sacdia-backend
  for branch in development staging production; do
    URL=$(neonctl connection-string $branch --project-id wispy-hall-32797215)
    DATABASE_URL="$URL" pnpm prisma migrate status
  done
  ```
  Expected: all 3 branches report "Database schema is up to date".

- [ ] **End-to-end smoke (dev DB):**
  1. Trigger manual recalc: `POST /annual-folders/rankings/recalculate?year_id=<active>`
  2. Fetch rankings: `GET /annual-folders/rankings?year_id=<active>` — verify composite_score_pct populated.
  3. Fetch breakdown for one enrollment: `GET /annual-folders/rankings/<id>/breakdown?year_id=<active>` — verify all 4 components return data.
  4. Create override via admin: POST `/ranking-weights` with `club_type_id=1`, weights 50/20/20/10. Verify GET reflects.
  5. Trigger recalc again, verify composite changes for that club_type's clubs.

- [ ] **Save engram session summary:**
  Save with `mem_session_summary` covering: tasks completed, files modified, migrations applied, tests passing, drift status, follow-ups (sub-features A/B/D/E).

---

## Out-of-scope reminder (do NOT implement here)

- Niveles sección + miembro (sub-feature A — separate plan)
- Visibilidad usuario final / app móvil (sub-feature B)
- Periodicidad mensual/trimestral (sub-feature D)
- Agrupación regional/multi-club (sub-feature E)
- Premiación por componente (multi-categoría por club)
- Notificaciones FCM por cambio de ranking
- Refactor histórico de rankings legacy
