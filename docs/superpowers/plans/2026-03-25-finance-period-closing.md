# Finance Period Closing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add automatic monthly period closing for club finances with audit snapshots and admin override capability.

**Architecture:** Single new service (`FinancePeriodService`) handles both the cron-driven closing logic and the `validatePeriodOpen` gate. The closing stores an aggregated snapshot per club/month in `finance_period_closings`. Existing `FinancesService.create/update/remove` call `validatePeriodOpen` before writes. Admin overrides are tracked via `post_closing_note` on individual `finances` records.

**Tech Stack:** NestJS 11, Prisma 7, PostgreSQL (Neon), `@nestjs/schedule` (already installed), Jest

**Spec:** `sacdia-backend/docs/superpowers/specs/2026-03-25-finance-period-closing-design.md`

---

## Existing Code Inventory (Read Before Implementing)

### Backend — `sacdia-backend/`

| File | Current state | Action |
|------|--------------|--------|
| `prisma/schema.prisma` (line ~466) | `finances` model has no `post_closing_note` column and no composite index on `[club_section_id, year, month, active]` | **Migrate** |
| `prisma/schema.prisma` | No `FinancePeriodClosing` model exists | **Create model** |
| `src/finances/finances.service.ts` | `create`, `update`, `remove` have no period-closing validation. Only injects `PrismaService` | **Update** |
| `src/finances/finances.controller.ts` | `remove` does not accept `?reason` query param. `create` does not pass `clubId` to service | **Update** |
| `src/finances/dto/finances.dto.ts` | `CreateFinanceDto` and `UpdateFinanceDto` lack `post_closing_note` field | **Update** |
| `src/finances/finances.module.ts` | Only imports `PrismaModule`, provides `FinancesService` + `ClubRolesGuard` | **Update** |
| `src/finances/finances.service.spec.ts` | Tests `create`, `update`, `findOne`, `findByClub`, `getSummary` with mock Prisma | **Update** |
| `src/common/services/authorization-context.service.ts` | `hasAnyGlobalRole(userId, roleNames)` exists and works. `CommonModule` is `@Global()` so no import needed | **Keep** |
| `src/app.module.ts` (line ~67) | `ScheduleModule.forRoot()` already imported | **Keep** |
| `package.json` (line ~40) | `@nestjs/schedule` v6.1.1 already installed | **Keep** |

---

## Task 1: Prisma Schema Migration

**Files:**
- Modify: `sacdia-backend/prisma/schema.prisma`
- Create: `sacdia-backend/prisma/migrations/<timestamp>_add_finance_period_closings/migration.sql` (auto-generated)

### Steps

- [ ] **1.1** Add the `FinancePeriodClosing` model to `prisma/schema.prisma`. Place it right after the `finances_categories` model (after line ~502):

```prisma
model FinancePeriodClosing {
  finance_period_closing_id Int       @id @default(autoincrement())
  club_id                   Int
  year                      Int
  month                     Int
  total_income              Int
  total_expense             Int
  balance                   Int
  movement_count            Int
  breakdown                 Json
  closed_at                 DateTime
  closed_by                 String?   @db.Uuid
  created_at                DateTime  @default(now()) @db.Timestamptz(6)

  clubs                     clubs     @relation(fields: [club_id], references: [club_id], onDelete: NoAction, onUpdate: NoAction)

  @@unique([club_id, year, month])
  @@map("finance_period_closings")
}
```

- [ ] **1.2** Add the reverse relation on the `clubs` model. Find the `clubs` model (line ~307) and add inside it:

```prisma
  finance_period_closings FinancePeriodClosing[]
```

- [ ] **1.3** Add the `post_closing_note` column to the `finances` model. Find the `finances` model (line ~466) and add after the `club_section_id` field (before the relation fields):

```prisma
  post_closing_note   String?
```

- [ ] **1.4** Add the composite index on `finances` for efficient period queries. Find the existing `@@index` line in the `finances` model (line ~487) and add after it:

```prisma
  @@index([club_section_id, year, month, active])
```

- [ ] **1.5** Generate and apply the migration:

```bash
cd sacdia-backend && pnpm prisma migrate dev --name add_finance_period_closings
```

Expected output: migration created and applied successfully, Prisma Client regenerated.

- [ ] **1.6** Verify the generated migration SQL contains:
  - `CREATE TABLE "finance_period_closings"` with all columns
  - `ALTER TABLE "finances" ADD COLUMN "post_closing_note" TEXT`
  - `CREATE UNIQUE INDEX` on `(club_id, year, month)`
  - `CREATE INDEX` on `(club_section_id, year, month, active)`

- [ ] **1.7** Commit:

```bash
git add prisma/schema.prisma prisma/migrations/
git commit -m "feat: add finance_period_closings table and post_closing_note column"
```

---

## Task 2: FinancePeriodService — Core Closing Logic (TDD)

**Files:**
- Create: `sacdia-backend/src/finances/finance-period.service.ts`
- Create: `sacdia-backend/src/finances/finance-period.service.spec.ts`

### Steps

- [ ] **2.1** Create the test file `sacdia-backend/src/finances/finance-period.service.spec.ts` with the test scaffold and mock setup:

```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { FinancePeriodService } from './finance-period.service';
import { PrismaService } from '../prisma/prisma.service';
import { Logger } from '@nestjs/common';

describe('FinancePeriodService', () => {
  let service: FinancePeriodService;

  const mockPrismaService = {
    clubs: {
      findMany: jest.fn(),
    },
    club_sections: {
      findMany: jest.fn(),
    },
    finances: {
      findMany: jest.fn(),
      groupBy: jest.fn(),
    },
    financePeriodClosing: {
      findUnique: jest.fn(),
      create: jest.fn(),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        FinancePeriodService,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    service = module.get<FinancePeriodService>(FinancePeriodService);
    jest.clearAllMocks();
  });

  // Tests go below
});
```

- [ ] **2.2** Add a failing test for `closeMonthForClub` — normal case with movements:

```typescript
  describe('closeMonthForClub', () => {
    it('should aggregate movements and create a closing record', async () => {
      const clubId = 1;
      const year = 2026;
      const month = 2;

      // Club has 2 sections
      mockPrismaService.club_sections.findMany.mockResolvedValue([
        { club_section_id: 10, club_types: { name: 'Conquistadores' } },
        { club_section_id: 11, club_types: { name: 'Aventureros' } },
      ]);

      // Movements for the period
      mockPrismaService.finances.findMany.mockResolvedValue([
        {
          finance_id: 1,
          amount: 5000,
          club_section_id: 10,
          finance_category_id: 1,
          finances_categories: { finance_category_id: 1, name: 'Cuotas', type: 0 },
        },
        {
          finance_id: 2,
          amount: 2000,
          club_section_id: 10,
          finance_category_id: 3,
          finances_categories: { finance_category_id: 3, name: 'Materiales', type: 1 },
        },
        {
          finance_id: 3,
          amount: 3000,
          club_section_id: 11,
          finance_category_id: 1,
          finances_categories: { finance_category_id: 1, name: 'Cuotas', type: 0 },
        },
      ]);

      // No existing closing
      mockPrismaService.financePeriodClosing.findUnique.mockResolvedValue(null);

      const mockClosing = { finance_period_closing_id: 1, club_id: clubId, year, month };
      mockPrismaService.financePeriodClosing.create.mockResolvedValue(mockClosing);

      const result = await service.closeMonthForClub(clubId, year, month);

      expect(mockPrismaService.financePeriodClosing.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          club_id: clubId,
          year,
          month,
          total_income: 8000,    // 5000 + 3000
          total_expense: 2000,   // 2000
          balance: 6000,         // 8000 - 2000
          movement_count: 3,
          breakdown: expect.objectContaining({
            by_category: expect.any(Array),
            by_section: expect.any(Array),
          }),
          closed_at: expect.any(Date),
          closed_by: null,
        }),
      });

      expect(result).toEqual(mockClosing);
    });
  });
```

- [ ] **2.3** Add a failing test for zero-movement months:

```typescript
    it('should create a closing record with zero totals when no movements exist', async () => {
      mockPrismaService.club_sections.findMany.mockResolvedValue([
        { club_section_id: 10, club_types: { name: 'Conquistadores' } },
      ]);
      mockPrismaService.finances.findMany.mockResolvedValue([]);
      mockPrismaService.financePeriodClosing.findUnique.mockResolvedValue(null);

      const mockClosing = { finance_period_closing_id: 2, club_id: 1 };
      mockPrismaService.financePeriodClosing.create.mockResolvedValue(mockClosing);

      await service.closeMonthForClub(1, 2026, 3);

      expect(mockPrismaService.financePeriodClosing.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          total_income: 0,
          total_expense: 0,
          balance: 0,
          movement_count: 0,
        }),
      });
    });
```

- [ ] **2.4** Add a failing test for idempotency — skip when closing already exists:

```typescript
    it('should skip if a closing already exists for the period', async () => {
      mockPrismaService.club_sections.findMany.mockResolvedValue([
        { club_section_id: 10, club_types: { name: 'Conquistadores' } },
      ]);
      mockPrismaService.financePeriodClosing.findUnique.mockResolvedValue({
        finance_period_closing_id: 99,
        club_id: 1,
        year: 2026,
        month: 2,
      });

      const result = await service.closeMonthForClub(1, 2026, 2);

      expect(result).toBeNull();
      expect(mockPrismaService.financePeriodClosing.create).not.toHaveBeenCalled();
    });
```

- [ ] **2.5** Run the tests to confirm they fail:

```bash
cd sacdia-backend && pnpm run test -- --testPathPattern=finance-period.service.spec
```

Expected: all 3 tests FAIL (service file does not exist yet).

- [ ] **2.6** Create the service file `sacdia-backend/src/finances/finance-period.service.ts`:

```typescript
import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { PrismaService } from '../prisma/prisma.service';

type CategoryBreakdownItem = {
  finance_category_id: number;
  name: string;
  type: number;
  total: number;
};

type SectionBreakdownItem = {
  club_section_id: number;
  club_type_name: string;
  income: number;
  expense: number;
  balance: number;
};

type Breakdown = {
  by_category: CategoryBreakdownItem[];
  by_section: SectionBreakdownItem[];
};

@Injectable()
export class FinancePeriodService {
  private readonly logger = new Logger(FinancePeriodService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Close a single month for a single club.
   * Returns the created closing record, or null if already closed.
   */
  async closeMonthForClub(
    clubId: number,
    year: number,
    month: number,
    closedBy: string | null = null,
  ) {
    // 1. Idempotency check
    const existing = await this.prisma.financePeriodClosing.findUnique({
      where: { club_id_year_month: { club_id: clubId, year, month } },
    });

    if (existing) {
      this.logger.debug(
        `Closing already exists for club ${clubId}, ${year}-${String(month).padStart(2, '0')}. Skipping.`,
      );
      return null;
    }

    // 2. Get club sections
    const sections = await this.prisma.club_sections.findMany({
      where: { main_club_id: clubId },
      select: {
        club_section_id: true,
        club_types: { select: { name: true } },
      },
    });

    const sectionIds = sections.map((s) => s.club_section_id);

    // 3. Get all active movements for the period
    const movements = await this.prisma.finances.findMany({
      where: {
        active: true,
        year,
        month,
        club_section_id: { in: sectionIds.length > 0 ? sectionIds : [-1] },
      },
      include: {
        finances_categories: {
          select: { finance_category_id: true, name: true, type: true },
        },
      },
    });

    // 4. Aggregate totals
    let totalIncome = 0;
    let totalExpense = 0;

    for (const mov of movements) {
      if (mov.finances_categories.type === 0) {
        totalIncome += mov.amount;
      } else {
        totalExpense += mov.amount;
      }
    }

    // 5. Build breakdown
    const breakdown = this.buildBreakdown(movements, sections);

    // 6. Create closing record
    return this.prisma.financePeriodClosing.create({
      data: {
        club_id: clubId,
        year,
        month,
        total_income: totalIncome,
        total_expense: totalExpense,
        balance: totalIncome - totalExpense,
        movement_count: movements.length,
        breakdown: breakdown as any,
        closed_at: new Date(),
        closed_by: closedBy,
      },
    });
  }

  private buildBreakdown(
    movements: Array<{
      amount: number;
      club_section_id: number | null;
      finance_category_id: number;
      finances_categories: {
        finance_category_id: number;
        name: string;
        type: number;
      };
    }>,
    sections: Array<{
      club_section_id: number;
      club_types: { name: string | null } | null;
    }>,
  ): Breakdown {
    // by_category
    const categoryMap = new Map<number, CategoryBreakdownItem>();
    for (const mov of movements) {
      const cat = mov.finances_categories;
      const existing = categoryMap.get(cat.finance_category_id);
      if (existing) {
        existing.total += mov.amount;
      } else {
        categoryMap.set(cat.finance_category_id, {
          finance_category_id: cat.finance_category_id,
          name: cat.name,
          type: cat.type,
          total: mov.amount,
        });
      }
    }

    // by_section
    const sectionMap = new Map<
      number,
      SectionBreakdownItem
    >();
    for (const section of sections) {
      sectionMap.set(section.club_section_id, {
        club_section_id: section.club_section_id,
        club_type_name: section.club_types?.name ?? 'Unknown',
        income: 0,
        expense: 0,
        balance: 0,
      });
    }

    for (const mov of movements) {
      if (mov.club_section_id === null) continue;
      const sectionEntry = sectionMap.get(mov.club_section_id);
      if (!sectionEntry) continue;

      if (mov.finances_categories.type === 0) {
        sectionEntry.income += mov.amount;
      } else {
        sectionEntry.expense += mov.amount;
      }
      sectionEntry.balance = sectionEntry.income - sectionEntry.expense;
    }

    return {
      by_category: Array.from(categoryMap.values()),
      by_section: Array.from(sectionMap.values()),
    };
  }
}
```

- [ ] **2.7** Run the tests to confirm they pass:

```bash
cd sacdia-backend && pnpm run test -- --testPathPattern=finance-period.service.spec
```

Expected: all 3 tests PASS.

- [ ] **2.8** Add a test to verify the breakdown structure is correct (category + section aggregation):

```typescript
    it('should build correct breakdown by category and section', async () => {
      mockPrismaService.club_sections.findMany.mockResolvedValue([
        { club_section_id: 10, club_types: { name: 'Conquistadores' } },
        { club_section_id: 11, club_types: { name: 'Aventureros' } },
      ]);

      mockPrismaService.finances.findMany.mockResolvedValue([
        {
          finance_id: 1, amount: 5000, club_section_id: 10,
          finance_category_id: 1,
          finances_categories: { finance_category_id: 1, name: 'Cuotas', type: 0 },
        },
        {
          finance_id: 2, amount: 2000, club_section_id: 11,
          finance_category_id: 1,
          finances_categories: { finance_category_id: 1, name: 'Cuotas', type: 0 },
        },
        {
          finance_id: 3, amount: 1500, club_section_id: 10,
          finance_category_id: 3,
          finances_categories: { finance_category_id: 3, name: 'Materiales', type: 1 },
        },
      ]);

      mockPrismaService.financePeriodClosing.findUnique.mockResolvedValue(null);
      mockPrismaService.financePeriodClosing.create.mockImplementation(
        ({ data }) => Promise.resolve({ finance_period_closing_id: 1, ...data }),
      );

      await service.closeMonthForClub(1, 2026, 2);

      const createCall = mockPrismaService.financePeriodClosing.create.mock.calls[0][0];
      const breakdown = createCall.data.breakdown;

      // by_category: Cuotas total=7000, Materiales total=1500
      expect(breakdown.by_category).toEqual(
        expect.arrayContaining([
          expect.objectContaining({ finance_category_id: 1, name: 'Cuotas', type: 0, total: 7000 }),
          expect.objectContaining({ finance_category_id: 3, name: 'Materiales', type: 1, total: 1500 }),
        ]),
      );

      // by_section: Conquistadores income=5000, expense=1500, balance=3500
      //             Aventureros income=2000, expense=0, balance=2000
      expect(breakdown.by_section).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            club_section_id: 10, club_type_name: 'Conquistadores',
            income: 5000, expense: 1500, balance: 3500,
          }),
          expect.objectContaining({
            club_section_id: 11, club_type_name: 'Aventureros',
            income: 2000, expense: 0, balance: 2000,
          }),
        ]),
      );
    });
```

- [ ] **2.9** Run all tests again:

```bash
cd sacdia-backend && pnpm run test -- --testPathPattern=finance-period.service.spec
```

Expected: all 4 tests PASS.

- [ ] **2.10** Commit:

```bash
git add src/finances/finance-period.service.ts src/finances/finance-period.service.spec.ts
git commit -m "feat: add FinancePeriodService with closeMonthForClub and tests"
```

---

## Task 3: Cron Job — Automatic Monthly Closing (TDD)

**Files:**
- Modify: `sacdia-backend/src/finances/finance-period.service.ts`
- Modify: `sacdia-backend/src/finances/finance-period.service.spec.ts`

### Steps

- [ ] **3.1** Add failing tests for `handleMonthlyClosing` cron method to `finance-period.service.spec.ts`:

```typescript
  describe('handleMonthlyClosing', () => {
    beforeEach(() => {
      // Use fake timers for deterministic date-dependent tests
      jest.useFakeTimers();
      jest.setSystemTime(new Date('2026-04-01'));
      // Mock closeMonthForClub on the service itself
      jest.spyOn(service, 'closeMonthForClub').mockResolvedValue(null);
    });

    afterEach(() => {
      jest.useRealTimers();
    });

    it('should process all active clubs for the previous month', async () => {
      mockPrismaService.clubs.findMany.mockResolvedValue([
        { club_id: 1, name: 'Club Alpha' },
        { club_id: 2, name: 'Club Beta' },
      ]);

      jest.spyOn(service, 'closeMonthForClub')
        .mockResolvedValueOnce({ finance_period_closing_id: 1 } as any)
        .mockResolvedValueOnce({ finance_period_closing_id: 2 } as any);

      await service.handleMonthlyClosing();

      // With faked time at 2026-04-01, previous month is March 2026
      expect(service.closeMonthForClub).toHaveBeenCalledWith(1, 2026, 3);
      expect(service.closeMonthForClub).toHaveBeenCalledWith(2, 2026, 3);
    });

    it('should isolate errors per club and continue processing', async () => {
      mockPrismaService.clubs.findMany.mockResolvedValue([
        { club_id: 1, name: 'Club Alpha' },
        { club_id: 2, name: 'Club Beta' },
        { club_id: 3, name: 'Club Gamma' },
      ]);

      jest.spyOn(service, 'closeMonthForClub')
        .mockResolvedValueOnce({ finance_period_closing_id: 1 } as any)
        .mockRejectedValueOnce(new Error('DB connection lost'))
        .mockResolvedValueOnce({ finance_period_closing_id: 3 } as any);

      // Should NOT throw — errors are isolated
      await expect(service.handleMonthlyClosing()).resolves.not.toThrow();

      expect(service.closeMonthForClub).toHaveBeenCalledTimes(3);
    });
  });
```

- [ ] **3.2** Run tests to confirm the new ones fail:

```bash
cd sacdia-backend && pnpm run test -- --testPathPattern=finance-period.service.spec
```

- [ ] **3.3** Add the `handleMonthlyClosing` cron method and `getPreviousMonth` helper to `finance-period.service.ts`:

```typescript
  // Add inside the FinancePeriodService class, after closeMonthForClub

  /**
   * Cron: runs on the 1st of each month at 00:00 UTC.
   * Closes the previous month for all active clubs.
   */
  @Cron('0 0 1 * *', { name: 'finance-period-closing' })
  async handleMonthlyClosing(): Promise<void> {
    const { month, year } = this.getPreviousMonth(new Date());
    const period = `${year}-${String(month).padStart(2, '0')}`;

    this.logger.log(`Starting monthly period closing for ${period}...`);

    const BATCH_SIZE = 50;
    let offset = 0;
    let totalProcessed = 0;
    let successCount = 0;
    let skipCount = 0;
    let errorCount = 0;

    // Process clubs in batches
    while (true) {
      const clubs = await this.prisma.clubs.findMany({
        where: { active: true },
        select: { club_id: true, name: true },
        skip: offset,
        take: BATCH_SIZE,
        orderBy: { club_id: 'asc' },
      });

      if (clubs.length === 0) break;

      for (const club of clubs) {
        totalProcessed++;
        try {
          const result = await this.closeMonthForClub(club.club_id, year, month);
          if (result) {
            successCount++;
            this.logger.log(
              `Closed period ${period} for club "${club.name}" (ID: ${club.club_id})`,
            );
          } else {
            skipCount++;
          }
        } catch (error) {
          errorCount++;
          const message = error instanceof Error ? error.message : String(error);
          this.logger.error(
            `Failed to close period ${period} for club "${club.name}" (ID: ${club.club_id}): ${message}`,
          );
        }
      }

      offset += BATCH_SIZE;
    }

    this.logger.log(
      `Period closing complete for ${period}: ` +
        `${successCount} closed, ${skipCount} skipped (already closed), ${errorCount} errors, ${totalProcessed} total`,
    );
  }

  private getPreviousMonth(date: Date): { month: number; year: number } {
    const currentMonth = date.getMonth() + 1; // getMonth() is 0-indexed
    const currentYear = date.getFullYear();

    if (currentMonth === 1) {
      return { month: 12, year: currentYear - 1 };
    }

    return { month: currentMonth - 1, year: currentYear };
  }
```

- [ ] **3.4** Run tests to confirm they all pass:

```bash
cd sacdia-backend && pnpm run test -- --testPathPattern=finance-period.service.spec
```

Expected: all 6 tests PASS.

- [ ] **3.5** Commit:

```bash
git add src/finances/finance-period.service.ts src/finances/finance-period.service.spec.ts
git commit -m "feat: add cron job for automatic monthly period closing with batch processing"
```

---

## Task 4: Period Validation — `validatePeriodOpen` (TDD)

**Files:**
- Modify: `sacdia-backend/src/finances/finance-period.service.ts`
- Modify: `sacdia-backend/src/finances/finance-period.service.spec.ts`

### Steps

- [ ] **4.1** Update the test file mock setup to include `AuthorizationContextService`:

```typescript
// Add import at the top of the spec file
import { AuthorizationContextService } from '../common/services/authorization-context.service';
import { ForbiddenException } from '@nestjs/common';

// Update mockPrismaService — no changes needed (financePeriodClosing already there)

// Add mock for AuthorizationContextService
const mockAuthorizationContextService = {
  hasAnyGlobalRole: jest.fn(),
};

// Update the module setup in beforeEach
const module: TestingModule = await Test.createTestingModule({
  providers: [
    FinancePeriodService,
    { provide: PrismaService, useValue: mockPrismaService },
    { provide: AuthorizationContextService, useValue: mockAuthorizationContextService },
  ],
}).compile();
```

- [ ] **4.2** Add failing tests for `validatePeriodOpen` — 3 scenarios:

```typescript
  describe('validatePeriodOpen', () => {
    it('should allow when period is not closed', async () => {
      mockPrismaService.financePeriodClosing.findUnique.mockResolvedValue(null);

      // Should not throw
      await expect(
        service.validatePeriodOpen(1, 2026, 2, 'user-123'),
      ).resolves.not.toThrow();

      // Should not check roles (unnecessary)
      expect(mockAuthorizationContextService.hasAnyGlobalRole).not.toHaveBeenCalled();
    });

    it('should throw ForbiddenException when period is closed and user is not admin', async () => {
      mockPrismaService.financePeriodClosing.findUnique.mockResolvedValue({
        finance_period_closing_id: 1,
        club_id: 1,
        year: 2026,
        month: 2,
      });
      mockAuthorizationContextService.hasAnyGlobalRole.mockResolvedValue(false);

      await expect(
        service.validatePeriodOpen(1, 2026, 2, 'user-123'),
      ).rejects.toThrow(ForbiddenException);

      await expect(
        service.validatePeriodOpen(1, 2026, 2, 'user-123'),
      ).rejects.toThrow('El periodo 2/2026 está cerrado');
    });

    it('should allow when period is closed and user is admin', async () => {
      mockPrismaService.financePeriodClosing.findUnique.mockResolvedValue({
        finance_period_closing_id: 1,
        club_id: 1,
        year: 2026,
        month: 2,
      });
      mockAuthorizationContextService.hasAnyGlobalRole.mockResolvedValue(true);

      await expect(
        service.validatePeriodOpen(1, 2026, 2, 'admin-user-456'),
      ).resolves.not.toThrow();

      expect(mockAuthorizationContextService.hasAnyGlobalRole).toHaveBeenCalledWith(
        'admin-user-456',
        ['admin', 'super_admin'],
      );
    });
  });
```

- [ ] **4.3** Run tests to confirm the 3 new tests fail:

```bash
cd sacdia-backend && pnpm run test -- --testPathPattern=finance-period.service.spec
```

- [ ] **4.4** Update `finance-period.service.ts` to inject `AuthorizationContextService` and add `validatePeriodOpen`.

> **Spec deviation note:** The design spec describes `validatePeriodOpen` as a private method on `FinancesService`. In this implementation it is intentionally **public** and lives on `FinancePeriodService` instead. This is a deliberate separation-of-concerns improvement — `FinancePeriodService` owns all period-closing logic, and `FinancesService` calls it cross-service. Making it public is required for that call path.

```typescript
// Add import at the top
import { Injectable, Logger, ForbiddenException } from '@nestjs/common';
import { AuthorizationContextService } from '../common/services/authorization-context.service';

// Update constructor
constructor(
  private readonly prisma: PrismaService,
  private readonly authorizationContext: AuthorizationContextService,
) {}

// Add the public method
/**
 * Checks if a period is closed and whether the user can override.
 * Throws ForbiddenException if the period is closed and user is not admin.
 */
async validatePeriodOpen(
  clubId: number,
  year: number,
  month: number,
  userId: string,
): Promise<void> {
  const closing = await this.prisma.financePeriodClosing.findUnique({
    where: { club_id_year_month: { club_id: clubId, year, month } },
  });

  if (!closing) return;

  const isAdmin = await this.authorizationContext.hasAnyGlobalRole(
    userId,
    ['admin', 'super_admin'],
  );

  if (!isAdmin) {
    throw new ForbiddenException(
      `El periodo ${month}/${year} está cerrado`,
    );
  }
}
```

- [ ] **4.5** Run tests to confirm all pass:

```bash
cd sacdia-backend && pnpm run test -- --testPathPattern=finance-period.service.spec
```

Expected: all 9 tests PASS.

- [ ] **4.6** Commit:

```bash
git add src/finances/finance-period.service.ts src/finances/finance-period.service.spec.ts
git commit -m "feat: add validatePeriodOpen with admin override support"
```

---

## Task 5: Integrate Validation into FinancesService (TDD)

**Files:**
- Modify: `sacdia-backend/src/finances/finances.service.ts`
- Modify: `sacdia-backend/src/finances/finances.service.spec.ts`

### Steps

- [ ] **5.1** Update the test file mock setup to include `FinancePeriodService`:

```typescript
// Add imports at the top of finances.service.spec.ts
import { ForbiddenException } from '@nestjs/common';
import { FinancePeriodService } from './finance-period.service';

// Add mock
const mockFinancePeriodService = {
  validatePeriodOpen: jest.fn(),
};

// Update the beforeEach module providers:
providers: [
  FinancesService,
  { provide: PrismaService, useValue: mockPrismaService },
  { provide: FinancePeriodService, useValue: mockFinancePeriodService },
],

// Add club_sections mock to the existing mockPrismaService object:
// club_sections: { findUnique: jest.fn() },

// Add to afterEach if not already clearing:
// jest.clearAllMocks();
```

Note: Because of circular dependency risk, inject `FinancePeriodService` via `@Inject(forwardRef(() => FinancePeriodService))` or, simpler, just import it directly since both are in the same module.

- [ ] **5.2** Add failing tests for period validation in `create`:

```typescript
  describe('create — period validation', () => {
    const createDto = {
      year: 2026,
      month: 2,
      amount: 1000,
      club_type_id: 2,
      finance_category_id: 1,
      finance_date: '2026-02-15',
      club_section_id: 10,
    };

    it('should call validatePeriodOpen before creating a movement', async () => {
      mockFinancePeriodService.validatePeriodOpen.mockResolvedValue(undefined);
      mockPrismaService.finances.create.mockResolvedValue({ finance_id: 1, ...createDto });

      await service.create(createDto, 'user-123', 1);

      expect(mockFinancePeriodService.validatePeriodOpen).toHaveBeenCalledWith(
        1, 2026, 2, 'user-123',
      );
    });

    it('should throw ForbiddenException when period is closed for non-admin', async () => {
      mockFinancePeriodService.validatePeriodOpen.mockRejectedValue(
        new ForbiddenException('El periodo 2/2026 está cerrado'),
      );

      await expect(service.create(createDto, 'user-123', 1)).rejects.toThrow(
        ForbiddenException,
      );

      expect(mockPrismaService.finances.create).not.toHaveBeenCalled();
    });

    it('should persist post_closing_note when provided', async () => {
      const dtoWithNote = { ...createDto, post_closing_note: 'Ajuste autorizado' };
      mockFinancePeriodService.validatePeriodOpen.mockResolvedValue(undefined);
      mockPrismaService.finances.create.mockResolvedValue({ finance_id: 1, ...dtoWithNote });

      await service.create(dtoWithNote, 'admin-user', 1);

      expect(mockPrismaService.finances.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            post_closing_note: 'Ajuste autorizado',
          }),
        }),
      );
    });
  });
```

- [ ] **5.3** Add failing tests for period validation in `update`:

```typescript
  describe('update — period validation', () => {
    it('should resolve clubId from movement and validate period before updating', async () => {
      const existingMovement = {
        finance_id: 1,
        year: 2026,
        month: 2,
        amount: 1000,
        club_section_id: 10,
        club_sections: { main_club_id: 1 },
        finances_categories: { name: 'Cuotas', type: 0 },
        club_types: { name: 'Conquistadores' },
        users: null,
      };

      mockPrismaService.finances.findUnique.mockResolvedValue(existingMovement);
      mockPrismaService.club_sections.findUnique = jest.fn().mockResolvedValue({
        club_section_id: 10,
        main_club_id: 1,
      });
      mockFinancePeriodService.validatePeriodOpen.mockResolvedValue(undefined);
      mockPrismaService.finances.update.mockResolvedValue({ finance_id: 1, amount: 2000 });

      await service.update(1, { amount: 2000 }, 'user-123');

      expect(mockFinancePeriodService.validatePeriodOpen).toHaveBeenCalledWith(
        1, 2026, 2, 'user-123',
      );
    });

    it('should skip period validation when movement has no club_section_id', async () => {
      const existingMovement = {
        finance_id: 1,
        year: 2026,
        month: 2,
        amount: 1000,
        club_section_id: null,
        finances_categories: { name: 'Cuotas', type: 0 },
        club_types: { name: 'Conquistadores' },
        users: null,
      };

      mockPrismaService.finances.findUnique.mockResolvedValue(existingMovement);
      mockPrismaService.finances.update.mockResolvedValue({ finance_id: 1, amount: 2000 });

      await service.update(1, { amount: 2000 }, 'user-123');

      expect(mockFinancePeriodService.validatePeriodOpen).not.toHaveBeenCalled();
    });
  });
```

- [ ] **5.4** Add failing tests for period validation in `remove`:

```typescript
  describe('remove — period validation', () => {
    it('should resolve clubId and validate period before soft-deleting', async () => {
      const existingMovement = {
        finance_id: 1,
        year: 2026,
        month: 2,
        amount: 1000,
        club_section_id: 10,
        finances_categories: { name: 'Cuotas', type: 0 },
        club_types: { name: 'Conquistadores' },
        users: null,
      };

      mockPrismaService.finances.findUnique.mockResolvedValue(existingMovement);
      mockPrismaService.club_sections.findUnique = jest.fn().mockResolvedValue({
        club_section_id: 10,
        main_club_id: 1,
      });
      mockFinancePeriodService.validatePeriodOpen.mockResolvedValue(undefined);
      mockPrismaService.finances.update.mockResolvedValue({ finance_id: 1, active: false });

      await service.remove(1, 'user-123');

      expect(mockFinancePeriodService.validatePeriodOpen).toHaveBeenCalledWith(
        1, 2026, 2, 'user-123',
      );
    });

    it('should persist reason as post_closing_note before soft-deleting', async () => {
      const existingMovement = {
        finance_id: 1,
        year: 2026,
        month: 2,
        amount: 1000,
        club_section_id: 10,
        finances_categories: { name: 'Cuotas', type: 0 },
        club_types: { name: 'Conquistadores' },
        users: null,
      };

      mockPrismaService.finances.findUnique.mockResolvedValue(existingMovement);
      mockPrismaService.club_sections.findUnique = jest.fn().mockResolvedValue({
        club_section_id: 10,
        main_club_id: 1,
      });
      mockFinancePeriodService.validatePeriodOpen.mockResolvedValue(undefined);
      mockPrismaService.finances.update.mockResolvedValue({ finance_id: 1, active: false });

      await service.remove(1, 'user-123', 'Error de duplicado');

      expect(mockPrismaService.finances.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            post_closing_note: 'Error de duplicado',
          }),
        }),
      );
    });
  });
```

- [ ] **5.5** Run tests to confirm all new tests fail:

```bash
cd sacdia-backend && pnpm run test -- --testPathPattern=finances.service.spec
```

- [ ] **5.6** Update `finances.service.ts` — inject `FinancePeriodService` and add period validation:

```typescript
// Update imports
import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateFinanceDto, UpdateFinanceDto, FinanceFiltersDto } from './dto';
import {
  PaginationDto,
  PaginatedResult,
  createPaginatedResult,
} from '../common/dto/pagination.dto';
import { FinancePeriodService } from './finance-period.service';

@Injectable()
export class FinancesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly financePeriodService: FinancePeriodService,
  ) {}

  // ... getCategories, findByClub, getSummary, findOne remain unchanged ...

  async create(dto: CreateFinanceDto, createdBy: string, clubId: number) {
    // Period validation — clubId comes from route param (always provided by controller)
    if (clubId != null) {
      await this.financePeriodService.validatePeriodOpen(
        clubId,
        dto.year,
        dto.month,
        createdBy,
      );
    }

    return this.prisma.finances.create({
      data: {
        year: dto.year,
        month: dto.month,
        amount: dto.amount,
        description: dto.description,
        club_type_id: dto.club_type_id,
        finance_category_id: dto.finance_category_id,
        finance_date: new Date(dto.finance_date),
        club_section_id: dto.club_section_id,
        created_by: createdBy,
        active: true,
        created_at: new Date(),
        modified_at: new Date(),
        post_closing_note: dto.post_closing_note ?? null,
      },
      include: {
        finances_categories: { select: { name: true, type: true } },
      },
    });
  }

  async update(financeId: number, dto: UpdateFinanceDto, modifiedBy?: string) {
    const existing = await this.findOne(financeId);

    // Period validation — resolve club_id from club_section_id
    if (existing.club_section_id && modifiedBy) {
      const section = await this.prisma.club_sections.findUnique({
        where: { club_section_id: existing.club_section_id },
        select: { main_club_id: true },
      });

      if (section?.main_club_id) {
        await this.financePeriodService.validatePeriodOpen(
          section.main_club_id,
          existing.year,
          existing.month,
          modifiedBy,
        );
      }
    }

    const updateData: any = {
      modified_at: new Date(),
      ...(modifiedBy && { modified_by_id: modifiedBy }),
    };

    if (dto.amount !== undefined) updateData.amount = dto.amount;
    if (dto.description !== undefined) updateData.description = dto.description;
    if (dto.finance_category_id !== undefined)
      updateData.finance_category_id = dto.finance_category_id;
    if (dto.finance_date !== undefined)
      updateData.finance_date = new Date(dto.finance_date);
    if (dto.post_closing_note !== undefined)
      updateData.post_closing_note = dto.post_closing_note;

    return this.prisma.finances.update({
      where: { finance_id: financeId },
      data: updateData,
      include: {
        finances_categories: { select: { name: true, type: true } },
      },
    });
  }

  async remove(financeId: number, modifiedBy?: string, reason?: string) {
    const existing = await this.findOne(financeId);

    // Period validation — resolve club_id from club_section_id
    if (existing.club_section_id && modifiedBy) {
      const section = await this.prisma.club_sections.findUnique({
        where: { club_section_id: existing.club_section_id },
        select: { main_club_id: true },
      });

      if (section?.main_club_id) {
        await this.financePeriodService.validatePeriodOpen(
          section.main_club_id,
          existing.year,
          existing.month,
          modifiedBy,
        );
      }
    }

    return this.prisma.finances.update({
      where: { finance_id: financeId },
      data: {
        active: false,
        modified_at: new Date(),
        ...(modifiedBy && { modified_by_id: modifiedBy }),
        ...(reason && { post_closing_note: reason }),
      },
    });
  }
}
```

- [ ] **5.7** Run tests to confirm all pass:

```bash
cd sacdia-backend && pnpm run test -- --testPathPattern=finances.service.spec
```

Expected: all tests PASS (including existing ones and new ones).

- [ ] **5.8** Commit:

```bash
git add src/finances/finances.service.ts src/finances/finances.service.spec.ts
git commit -m "feat: integrate period closing validation into finance create/update/remove"
```

---

## Task 6: DTO Updates

**Files:**
- Modify: `sacdia-backend/src/finances/dto/finances.dto.ts`

### Steps

- [ ] **6.1** Add `post_closing_note` to `CreateFinanceDto`:

```typescript
  @ApiPropertyOptional({
    description: 'Justificación para movimiento en período cerrado (solo admin)',
    maxLength: 500,
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  post_closing_note?: string;
```

Add `MaxLength` and `Max` to the imports from `class-validator`:

```typescript
import {
  IsInt,
  IsOptional,
  IsString,
  IsDateString,
  Min,
  Max,
  MaxLength,
} from 'class-validator';
```

Also add `@Max(12)` to the existing `month` field in `CreateFinanceDto` (right after the existing `@Min(1)` decorator):

```typescript
  @Min(1)
  @Max(12)
  month: number;
```

- [ ] **6.2** Add `post_closing_note` to `UpdateFinanceDto`:

```typescript
  @ApiPropertyOptional({
    description: 'Justificación para movimiento en período cerrado (solo admin)',
    maxLength: 500,
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  post_closing_note?: string;
```

- [ ] **6.3** Verify the DTO compiles by running a quick test:

```bash
cd sacdia-backend && pnpm run test -- --testPathPattern=finances
```

Expected: all finance tests pass (no validation errors).

- [ ] **6.4** Commit:

```bash
git add src/finances/dto/finances.dto.ts
git commit -m "feat: add post_closing_note field to finance DTOs"
```

---

## Task 7: Controller Updates

**Files:**
- Modify: `sacdia-backend/src/finances/finances.controller.ts`

### Steps

- [ ] **7.1** Update the `create` method to pass `clubId` to the service:

```typescript
  async create(
    @Param('clubId', ParseIntPipe) clubId: number,
    @Body() dto: CreateFinanceDto,
    @Request() req: any,
  ) {
    return this.financesService.create(dto, req.user.sub, clubId);
  }
```

- [ ] **7.2** Update the `remove` method to accept `?reason` query param:

```typescript
  @Delete('finances/:financeId')
  @RequirePermissions('finances:delete')
  @AuthorizationResource({ type: 'finance', idParam: 'financeId' })
  @ApiOperation({ summary: 'Desactivar movimiento' })
  @ApiParam({ name: 'financeId', type: Number })
  @ApiQuery({
    name: 'reason',
    required: false,
    type: String,
    description: 'Justificación para eliminación en período cerrado (solo admin)',
  })
  @ApiResponse({ status: 200, description: 'Movimiento desactivado' })
  async remove(
    @Param('financeId', ParseIntPipe) financeId: number,
    @Request() req: any,
    @Query('reason') reason?: string,
  ) {
    return this.financesService.remove(financeId, req.user.sub, reason);
  }
```

- [ ] **7.3** Run the full finance test suite:

```bash
cd sacdia-backend && pnpm run test -- --testPathPattern=finances
```

Expected: all tests PASS.

- [ ] **7.4** Commit:

```bash
git add src/finances/finances.controller.ts
git commit -m "feat: pass clubId to create and add reason query param to delete endpoint"
```

---

## Task 8: Module Registration

**Files:**
- Modify: `sacdia-backend/src/finances/finances.module.ts`

### Steps

- [ ] **8.1** Update `finances.module.ts` to register `FinancePeriodService`:

```typescript
import { Module } from '@nestjs/common';
import { FinancesController } from './finances.controller';
import { FinancesService } from './finances.service';
import { FinancePeriodService } from './finance-period.service';
import { PrismaModule } from '../prisma/prisma.module';
import { ClubRolesGuard } from '../common/guards';

@Module({
  imports: [PrismaModule],
  controllers: [FinancesController],
  providers: [FinancesService, FinancePeriodService, ClubRolesGuard],
  exports: [FinancesService, FinancePeriodService],
})
export class FinancesModule {}
```

Note: `ScheduleModule.forRoot()` is already imported in `AppModule` (line ~67), so the `@Cron` decorator in `FinancePeriodService` will be automatically picked up. `AuthorizationContextService` is provided by the `@Global()` `CommonModule`, so no explicit import is needed.

- [ ] **8.2** Run the full test suite (do NOT run `pnpm run build` — project rules prohibit building after changes):

```bash
cd sacdia-backend && pnpm run test
```

Expected: all tests pass, including the new `finance-period.service.spec.ts` and updated `finances.service.spec.ts`.

- [ ] **8.3** Commit:

```bash
git add src/finances/finances.module.ts
git commit -m "feat: register FinancePeriodService in FinancesModule"
```

---

## Verification Checklist

After all tasks are complete, verify end-to-end:

- [ ] `pnpm prisma migrate status` shows no pending migrations
- [ ] `pnpm run test` passes all tests (existing + new)
- [ ] The cron decorator `@Cron('0 0 1 * *')` exists in `FinancePeriodService`
- [ ] `validatePeriodOpen` is called in `create`, `update`, and `remove` of `FinancesService`
- [ ] `post_closing_note` is in both `CreateFinanceDto` and `UpdateFinanceDto`
- [ ] `?reason` query param is accepted on `DELETE /finances/:financeId`
- [ ] The `clubs` model in schema has the `finance_period_closings` reverse relation
- [ ] The composite index `@@index([club_section_id, year, month, active])` exists on `finances`
