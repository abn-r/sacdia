# Enrollment Limits Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enforce enrollment limits per club type in `ClassesService.enrollUser()` — max 1 for Aventureros/Conquistadores (combined), max 2 for Guías Mayores (with prior investiture requirement).

**Architecture:** Single-method validation inside `prisma.$transaction()` in the existing `enrollUser()` method. Club type IDs resolved dynamically by name. The `requires_invested_gm` boolean on the `classes` model drives the investiture pre-condition check.

**Tech Stack:** NestJS 11, Prisma 7, PostgreSQL, Jest

**Spec:** `docs/superpowers/specs/2026-03-24-enrollment-limits-design.md`

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `src/classes/classes.service.ts` | Add enrollment limit validation to `enrollUser()` |
| Modify | `src/classes/classes.service.spec.ts` | Add 12 unit tests for enrollment limits (spec test #8 — concurrency — deferred to integration tests) |

No new files needed.

---

## Task 1: Add test helpers and mock setup for enrollUser

**Files:**
- Modify: `src/classes/classes.service.spec.ts`

- [ ] **Step 1: Read the existing test file to understand current mock patterns**

Read: `src/classes/classes.service.spec.ts`

- [ ] **Step 2: Add the enrollUser describe block with transaction mock helper**

Add a new `describe('enrollUser')` block at the end of the test file (before the closing `}` of the root describe). Include a reusable mock factory for the transaction callback pattern:

```typescript
describe('enrollUser', () => {
  // Reusable mock for prisma.$transaction
  // The transaction receives a callback with a tx proxy that has the same API as prisma
  const setupTransactionMock = (mocks: {
    clubTypes?: any[];
    targetClass?: any;
    investitureCheck?: any;
    activeCount?: number;
    existingEnrollment?: any;
    createResult?: any;
    updateResult?: any;
  }) => {
    const txMock = {
      club_types: {
        findMany: jest.fn().mockResolvedValue(
          mocks.clubTypes ?? [
            { club_type_id: 1, name: 'Aventureros' },
            { club_type_id: 2, name: 'Conquistadores' },
            { club_type_id: 3, name: 'Guías Mayores' },
          ],
        ),
      },
      classes: {
        findUnique: jest.fn().mockResolvedValue(mocks.targetClass ?? null),
      },
      enrollments: {
        findFirst: jest.fn().mockResolvedValue(mocks.investitureCheck ?? null),
        count: jest.fn().mockResolvedValue(mocks.activeCount ?? 0),
        findUnique: jest.fn().mockResolvedValue(mocks.existingEnrollment ?? null),
        create: jest.fn().mockResolvedValue(mocks.createResult ?? { enrollment_id: 1 }),
        update: jest.fn().mockResolvedValue(mocks.updateResult ?? { enrollment_id: 1 }),
      },
    };

    // Note: mockPrismaService.$transaction is already defined in the module setup (jest.fn())
    (mockPrismaService.$transaction as jest.Mock).mockImplementation(
      async (callback: (tx: any) => Promise<any>) => callback(txMock),
    );

    return txMock;
  };

  const userId = 'test-user-uuid';
  const classId = 10;
  const yearId = 1;
});
```

> **Note:** `mockPrismaService.$transaction` is already defined as `jest.fn()` in the existing mock setup. Confirmed present — no changes needed to the mock provider.

- [ ] **Step 3: Run tests to verify setup compiles**

Run: `cd sacdia-backend && npx jest src/classes/classes.service.spec.ts --no-coverage 2>&1 | tail -20`
Expected: existing tests still pass, no new failures.

- [ ] **Step 4: Commit**

```bash
cd sacdia-backend && git add src/classes/classes.service.spec.ts && git commit -m "test: add enrollUser mock setup for enrollment limits"
```

---

## Task 2: Write failing tests for Aventureros/Conquistadores limit

**Files:**
- Modify: `src/classes/classes.service.spec.ts`

- [ ] **Step 1: Write the failing tests**

Inside the `describe('enrollUser')` block, add:

```typescript
it('should allow first enrollment in Aventureros when no active enrollments exist', async () => {
  setupTransactionMock({
    targetClass: { class_id: 10, club_type_id: 1, requires_invested_gm: false },
    activeCount: 0,
    createResult: { enrollment_id: 1, class_id: 10 },
  });

  const result = await service.enrollUser(userId, classId, yearId);
  expect(result).toMatchObject({ enrollment_id: 1, class_id: 10 });
});

it('should block Conquistadores enrollment when 1 active Aventureros enrollment exists', async () => {
  setupTransactionMock({
    targetClass: { class_id: 10, club_type_id: 2, requires_invested_gm: false },
    activeCount: 1,
  });

  await expect(service.enrollUser(userId, classId, yearId)).rejects.toThrow(
    ConflictException,
  );
});

it('should block Aventureros enrollment when 1 active Conquistadores enrollment exists', async () => {
  setupTransactionMock({
    targetClass: { class_id: 10, club_type_id: 1, requires_invested_gm: false },
    activeCount: 1,
  });

  await expect(service.enrollUser(userId, classId, yearId)).rejects.toThrow(
    ConflictException,
  );
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd sacdia-backend && npx jest src/classes/classes.service.spec.ts --no-coverage -t "enrollUser" 2>&1 | tail -20`
Expected: FAIL — `enrollUser` doesn't use `$transaction` yet.

- [ ] **Step 3: Commit failing tests**

```bash
cd sacdia-backend && git add src/classes/classes.service.spec.ts && git commit -m "test: add failing tests for aventureros/conquistadores enrollment limit"
```

---

## Task 3: Write failing tests for GM investiture pre-condition

**Files:**
- Modify: `src/classes/classes.service.spec.ts`

- [ ] **Step 1: Write the failing tests**

```typescript
it('should block GM class with requires_invested_gm when no prior investiture', async () => {
  setupTransactionMock({
    targetClass: { class_id: 10, club_type_id: 3, requires_invested_gm: true },
    investitureCheck: null,
  });

  await expect(service.enrollUser(userId, classId, yearId)).rejects.toThrow(
    ForbiddenException,
  );
});

it('should allow GM class with requires_invested_gm when INVESTIDO exists', async () => {
  setupTransactionMock({
    targetClass: { class_id: 10, club_type_id: 3, requires_invested_gm: true },
    investitureCheck: { enrollment_id: 99, investiture_status: 'INVESTIDO' },
    activeCount: 0,
    createResult: { enrollment_id: 2, class_id: 10 },
  });

  const result = await service.enrollUser(userId, classId, yearId);
  expect(result).toMatchObject({ enrollment_id: 2, class_id: 10 });
});

it('should allow GM class without requires_invested_gm (no investiture needed)', async () => {
  setupTransactionMock({
    targetClass: { class_id: 10, club_type_id: 3, requires_invested_gm: false },
    activeCount: 0,
    createResult: { enrollment_id: 3, class_id: 10 },
  });

  const result = await service.enrollUser(userId, classId, yearId);
  expect(result).toMatchObject({ enrollment_id: 3, class_id: 10 });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd sacdia-backend && npx jest src/classes/classes.service.spec.ts --no-coverage -t "enrollUser" 2>&1 | tail -20`
Expected: FAIL

- [ ] **Step 3: Commit**

```bash
cd sacdia-backend && git add src/classes/classes.service.spec.ts && git commit -m "test: add failing tests for GM investiture pre-condition"
```

---

## Task 4: Write failing tests for GM enrollment limit and edge cases

**Files:**
- Modify: `src/classes/classes.service.spec.ts`

- [ ] **Step 1: Write the failing tests**

```typescript
it('should block GM enrollment when 2 active GM enrollments exist', async () => {
  setupTransactionMock({
    targetClass: { class_id: 10, club_type_id: 3, requires_invested_gm: false },
    activeCount: 2,
  });

  await expect(service.enrollUser(userId, classId, yearId)).rejects.toThrow(
    ConflictException,
  );
});

it('should block reactivation when enrollment limit is reached', async () => {
  setupTransactionMock({
    targetClass: { class_id: 10, club_type_id: 1, requires_invested_gm: false },
    activeCount: 1,
    existingEnrollment: { enrollment_id: 5, active: false },
  });

  await expect(service.enrollUser(userId, classId, yearId)).rejects.toThrow(
    ConflictException,
  );
});

it('should allow reactivation when under enrollment limit', async () => {
  setupTransactionMock({
    targetClass: { class_id: 10, club_type_id: 1, requires_invested_gm: false },
    activeCount: 0,
    existingEnrollment: { enrollment_id: 5, active: false },
    updateResult: { enrollment_id: 5, active: true },
  });

  const result = await service.enrollUser(userId, classId, yearId);
  expect(result).toMatchObject({ enrollment_id: 5, active: true });
});

it('should throw InternalServerErrorException when club types not fully resolved', async () => {
  setupTransactionMock({
    clubTypes: [{ club_type_id: 1, name: 'Aventureros' }], // Only 1 of 3
    targetClass: { class_id: 10, club_type_id: 1, requires_invested_gm: false },
  });

  await expect(service.enrollUser(userId, classId, yearId)).rejects.toThrow(
    InternalServerErrorException,
  );
});

it('should throw NotFoundException when target class does not exist', async () => {
  setupTransactionMock({
    targetClass: null,
  });

  await expect(service.enrollUser(userId, classId, yearId)).rejects.toThrow(
    NotFoundException,
  );
});

it('should throw ConflictException when enrollment already exists and is active (regression)', async () => {
  setupTransactionMock({
    targetClass: { class_id: 10, club_type_id: 1, requires_invested_gm: false },
    activeCount: 0,
    existingEnrollment: { enrollment_id: 7, active: true },
  });

  await expect(service.enrollUser(userId, classId, yearId)).rejects.toThrow(
    ConflictException,
  );
});
```

> **Note on spec test #8 (concurrent requests):** This test requires real database transactions to be meaningful — mocking `$transaction` cannot simulate real concurrency. Deferred to integration/e2e tests.

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd sacdia-backend && npx jest src/classes/classes.service.spec.ts --no-coverage -t "enrollUser" 2>&1 | tail -20`
Expected: FAIL

- [ ] **Step 3: Commit**

```bash
cd sacdia-backend && git add src/classes/classes.service.spec.ts && git commit -m "test: add failing tests for GM limit and edge cases"
```

---

## Task 5: Implement enrollment limit validation in enrollUser()

**Files:**
- Modify: `src/classes/classes.service.ts:1-10` (imports)
- Modify: `src/classes/classes.service.ts:190-234` (enrollUser method)

- [ ] **Step 1: Add missing imports**

Add `ForbiddenException` and `InternalServerErrorException` to the `@nestjs/common` import (`NotFoundException` is already imported):

```typescript
import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  InternalServerErrorException,
  NotFoundException,
} from '@nestjs/common';
```

- [ ] **Step 2: Replace the enrollUser method**

Replace the entire `enrollUser` method (lines 190-234) with:

```typescript
async enrollUser(
  userId: string,
  classId: number,
  ecclesiasticalYearId: number,
) {
  return this.prisma.$transaction(async (tx) => {
    // 1. Resolve club type IDs by name
    const clubTypes = await tx.club_types.findMany({
      where: { name: { in: ['Aventureros', 'Conquistadores', 'Guías Mayores'] } },
    });
    if (clubTypes.length !== 3) {
      throw new InternalServerErrorException(
        'No se pudieron resolver los tipos de club requeridos',
      );
    }
    const aventurerosId = clubTypes.find((ct) => ct.name === 'Aventureros')!.club_type_id;
    const conquistadoresId = clubTypes.find((ct) => ct.name === 'Conquistadores')!.club_type_id;
    const gmId = clubTypes.find((ct) => ct.name === 'Guías Mayores')!.club_type_id;

    // 2. Get target class
    const targetClass = await tx.classes.findUnique({
      where: { class_id: classId },
    });
    if (!targetClass) {
      throw new NotFoundException('Clase no encontrada');
    }

    // 3. Check GM investiture pre-condition
    if (targetClass.requires_invested_gm) {
      const hasInvestiture = await tx.enrollments.findFirst({
        where: {
          user_id: userId,
          investiture_status: 'INVESTIDO',
          classes: { club_type_id: gmId },
        },
      });
      if (!hasInvestiture) {
        throw new ForbiddenException(
          'Necesitás haber sido investido en al menos una clase de Guías Mayores',
        );
      }
    }

    // 4. Enrollment limit by club type
    const { club_type_id } = targetClass;

    if ([aventurerosId, conquistadoresId].includes(club_type_id)) {
      const activeCount = await tx.enrollments.count({
        where: {
          user_id: userId,
          ecclesiastical_year_id: ecclesiasticalYearId,
          active: true,
          classes: { club_type_id: { in: [aventurerosId, conquistadoresId] } },
        },
      });
      if (activeCount >= 1) {
        throw new ConflictException(
          'Ya tenés una inscripción activa en Aventureros/Conquistadores',
        );
      }
    } else if (club_type_id === gmId) {
      const activeCount = await tx.enrollments.count({
        where: {
          user_id: userId,
          ecclesiastical_year_id: ecclesiasticalYearId,
          active: true,
          classes: { club_type_id: gmId },
        },
      });
      if (activeCount >= 2) {
        throw new ConflictException(
          'Ya tenés 2 inscripciones activas en Guías Mayores',
        );
      }
    }

    // 5. Duplicate check + create/reactivate
    const existing = await tx.enrollments.findUnique({
      where: {
        user_id_class_id_ecclesiastical_year_id: {
          user_id: userId,
          class_id: classId,
          ecclesiastical_year_id: ecclesiasticalYearId,
        },
      },
    });

    if (existing) {
      if (existing.active) {
        throw new ConflictException(
          'El usuario ya tiene una inscripción activa para esta clase en el año eclesiástico indicado',
        );
      }

      return tx.enrollments.update({
        where: { enrollment_id: existing.enrollment_id },
        data: { active: true },
        include: {
          classes: { select: { name: true } },
          ecclesiastical_year: { select: { start_date: true, end_date: true } },
        },
      });
    }

    return tx.enrollments.create({
      data: {
        user_id: userId,
        class_id: classId,
        ecclesiastical_year_id: ecclesiasticalYearId,
        enrollment_date: new Date(),
      },
      include: {
        classes: { select: { name: true } },
        ecclesiastical_year: { select: { start_date: true, end_date: true } },
      },
    });
  });
}
```

- [ ] **Step 3: Run ALL enrollUser tests**

Run: `cd sacdia-backend && npx jest src/classes/classes.service.spec.ts --no-coverage -t "enrollUser" 2>&1 | tail -30`
Expected: ALL 12 tests PASS

- [ ] **Step 4: Run the full test suite for classes**

Run: `cd sacdia-backend && npx jest src/classes/classes.service.spec.ts --no-coverage 2>&1 | tail -20`
Expected: ALL tests PASS (existing + new)

- [ ] **Step 5: Commit**

```bash
cd sacdia-backend && git add src/classes/classes.service.ts src/classes/classes.service.spec.ts && git commit -m "feat: enforce enrollment limits per club type in enrollUser"
```

---

## Task 6: Final verification

- [ ] **Step 1: Run the full backend test suite**

Run: `cd sacdia-backend && npx jest --no-coverage 2>&1 | tail -20`
Expected: no regressions

- [ ] **Step 2: Verify TypeScript compilation**

Run: `cd sacdia-backend && npx tsc --noEmit 2>&1 | tail -20`
Expected: no type errors

- [ ] **Step 3: Commit if any fixes were needed**

Only if step 1 or 2 revealed issues that required fixes.
