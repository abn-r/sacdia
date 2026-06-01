# Honors Validation Workflow PR1 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Normalize the backend honors validation workflow so `validation_status` is the canonical source of truth and submit/approve/reject go through one domain service.

**Architecture:** Add a backend domain workflow service under the honors module. `ValidationService` and `EvidenceReviewService` must delegate honor validation actions to that service instead of each owning partial copies of the state machine. PR1 does not redesign the admin UI or app screens; it makes the backend contract enforceable first.

**Tech Stack:** NestJS 11, Prisma 7, Jest/ts-jest, SACDIA `AppBadRequestException`/`AppNotFoundException`, existing `validation_logs`, `users_honors`, `honor_requirements`, `user_honor_requirement_progress`, `requirement_evidence`, and `evidence_files` tables.

**Non-negotiables:**
- Do not run `pnpm build`.
- Use TDD: failing unit test first, then implementation.
- Do not add `Co-Authored-By` or AI attribution to commits.
- Use conventional commit messages.
- Keep class validation behavior unchanged; this PR only normalizes honors.

---

## Current Problem

The backend currently has three separate honor-validation behaviors:

1. `ValidationService.submitHonorForReview()` moves a user honor to `PENDING_REVIEW`, but does not check requirements/evidence.
2. `ValidationService.reviewHonor()` can approve/reject honors without requiring the honor to be pending.
3. `EvidenceReviewService.approveHonor()` / `rejectHonor()` perform another partial state machine.

There are also two completion indicators:

- `users_honors.validation_status` — should become the source of truth.
- `users_honors.validate` — legacy boolean, should only be maintained for backward compatibility.

---

## Desired PR1 Behavior

### Submit for review

`submitForReview('honor', userHonorId, userId)` should allow submission only when:

- `users_honors` record exists.
- It belongs to `userId`.
- `active = true`.
- `validation_status` is `IN_PROGRESS` or `REJECTED`.
- It is not already `APPROVED` or `PENDING_REVIEW`.
- It has minimum evidence.
- Required honor requirements are completed.
- If rejected before, it has user changes after the rejection timestamp.

### Approve honor

Approve should allow only `PENDING_REVIEW` honors and set:

- `validation_status = APPROVED`
- `validate = true`
- `validated_by_id`
- `validated_at`
- `rejection_reason = null`
- `modified_at = now`
- validation log action `APPROVED`
- achievement event `honor.validated`

### Reject honor

Reject should allow only `PENDING_REVIEW` honors and set:

- `validation_status = REJECTED`
- `validate = false`
- `validated_by_id`
- `validated_at`
- `rejection_reason`
- `modified_at = now`
- validation log action `REJECTED`

---

## Task 1: Add missing error codes

**Files:**
- Modify: `sacdia-backend/src/common/errors/error-codes.ts`

**Step 1: Add enum values**

Add these near the existing `VALIDATION_HONOR_*` values:

```ts
VALIDATION_HONOR_INACTIVE = 'VALIDATION_HONOR_INACTIVE',
VALIDATION_HONOR_MISSING_EVIDENCE = 'VALIDATION_HONOR_MISSING_EVIDENCE',
VALIDATION_HONOR_REQUIREMENTS_INCOMPLETE = 'VALIDATION_HONOR_REQUIREMENTS_INCOMPLETE',
VALIDATION_HONOR_NO_CHANGES_AFTER_REJECTION = 'VALIDATION_HONOR_NO_CHANGES_AFTER_REJECTION',
VALIDATION_HONOR_NOT_PENDING = 'VALIDATION_HONOR_NOT_PENDING',
```

**Step 2: Run targeted tests**

Run:

```bash
cd sacdia-backend
pnpm test -- evidence-review.service.spec.ts --runInBand
```

Expected: existing tests still pass.

**Step 3: Commit**

```bash
git add sacdia-backend/src/common/errors/error-codes.ts
git commit -m "feat: add honor validation workflow error codes"
```

---

## Task 2: Create workflow service contract

**Files:**
- Create: `sacdia-backend/src/honors/honor-validation-workflow.types.ts`
- Create: `sacdia-backend/src/honors/honor-validation-workflow.service.ts`
- Create: `sacdia-backend/src/honors/honor-validation-workflow.service.spec.ts`

**Step 1: Create types**

Create `sacdia-backend/src/honors/honor-validation-workflow.types.ts`:

```ts
export type HonorValidationStatus =
  | 'IN_PROGRESS'
  | 'PENDING_REVIEW'
  | 'APPROVED'
  | 'REJECTED';

export type HonorReviewAction = 'approved' | 'rejected';

export interface HonorValidationResult {
  id: number;
  type: 'honor';
  status: HonorValidationStatus;
}

export interface HonorSubmitEligibility {
  canSubmit: boolean;
  blockers: string[];
}
```

**Step 2: Write failing service spec**

Create `sacdia-backend/src/honors/honor-validation-workflow.service.spec.ts` with focused unit tests.

Minimum test cases:

```ts
import { HonorValidationWorkflowService } from './honor-validation-workflow.service';
import { ErrorCode } from '../common/errors/error-codes';

describe('HonorValidationWorkflowService', () => {
  const now = new Date('2026-06-01T12:00:00.000Z');

  const mockPrisma = {
    users_honors: {
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    honor_requirements: { findMany: jest.fn() },
    user_honor_requirement_progress: { findMany: jest.fn() },
    requirement_evidence: { count: jest.fn() },
    evidence_files: { count: jest.fn() },
    validation_logs: { create: jest.fn(), findFirst: jest.fn() },
    $transaction: jest.fn(async (callback) => callback(mockPrisma)),
  };

  const notifications = {
    sendToSectionRole: jest.fn(),
    notifySafe: jest.fn(),
  };

  const achievements = {
    emitEvent: jest.fn(),
  };

  let service: HonorValidationWorkflowService;

  beforeEach(() => {
    jest.useFakeTimers().setSystemTime(now);
    jest.clearAllMocks();
    service = new HonorValidationWorkflowService(
      mockPrisma as any,
      notifications as any,
      achievements as any,
    );
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  function pendingHonor(overrides = {}) {
    return {
      user_honor_id: 10,
      user_id: 'user-1',
      honor_id: 20,
      active: true,
      validate: false,
      validation_status: 'PENDING_REVIEW',
      images: ['r2://image.jpg'],
      document: null,
      certificate: '',
      validated_at: null,
      modified_at: new Date('2026-06-01T11:00:00.000Z'),
      honors: {
        honor_id: 20,
        name: 'Arte cristiano',
        honors_category_id: 1,
        club_type_id: 2,
      },
      ...overrides,
    };
  }

  it('blocks submit when evidence is missing', async () => {
    mockPrisma.users_honors.findUnique.mockResolvedValue(
      pendingHonor({ validation_status: 'IN_PROGRESS', images: [], document: null, certificate: '' }),
    );
    mockPrisma.evidence_files.count.mockResolvedValue(0);
    mockPrisma.honor_requirements.findMany.mockResolvedValue([]);
    mockPrisma.user_honor_requirement_progress.findMany.mockResolvedValue([]);
    mockPrisma.requirement_evidence.count.mockResolvedValue(0);

    await expect(service.submitForReview(10, 'user-1')).rejects.toMatchObject({
      code: ErrorCode.VALIDATION_HONOR_MISSING_EVIDENCE,
    });
  });

  it('blocks submit when required requirements are incomplete', async () => {
    mockPrisma.users_honors.findUnique.mockResolvedValue(
      pendingHonor({ validation_status: 'IN_PROGRESS' }),
    );
    mockPrisma.evidence_files.count.mockResolvedValue(0);
    mockPrisma.honor_requirements.findMany.mockResolvedValue([
      { requirement_id: 1, parent_id: null, requires_evidence: false },
    ]);
    mockPrisma.user_honor_requirement_progress.findMany.mockResolvedValue([]);
    mockPrisma.requirement_evidence.count.mockResolvedValue(0);

    await expect(service.submitForReview(10, 'user-1')).rejects.toMatchObject({
      code: ErrorCode.VALIDATION_HONOR_REQUIREMENTS_INCOMPLETE,
    });
  });

  it('submits eligible honor for review', async () => {
    mockPrisma.users_honors.findUnique.mockResolvedValue(
      pendingHonor({ validation_status: 'IN_PROGRESS' }),
    );
    mockPrisma.evidence_files.count.mockResolvedValue(0);
    mockPrisma.honor_requirements.findMany.mockResolvedValue([]);
    mockPrisma.user_honor_requirement_progress.findMany.mockResolvedValue([]);
    mockPrisma.requirement_evidence.count.mockResolvedValue(0);
    mockPrisma.users_honors.update.mockResolvedValue(
      pendingHonor({ validation_status: 'PENDING_REVIEW', submitted_at: now }),
    );

    await expect(service.submitForReview(10, 'user-1')).resolves.toMatchObject({
      user_honor_id: 10,
      validation_status: 'PENDING_REVIEW',
    });

    expect(mockPrisma.users_honors.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { user_honor_id: 10 },
        data: expect.objectContaining({
          validation_status: 'PENDING_REVIEW',
          submitted_at: now,
          rejection_reason: null,
        }),
      }),
    );
  });

  it('approves only pending honors and keeps validate in sync', async () => {
    mockPrisma.users_honors.findUnique.mockResolvedValue(pendingHonor());
    mockPrisma.users_honors.update.mockResolvedValue(
      pendingHonor({ validation_status: 'APPROVED', validate: true }),
    );

    await expect(service.approve(10, 'reviewer-1', 'ok')).resolves.toEqual({
      id: 10,
      type: 'honor',
      status: 'APPROVED',
    });

    expect(mockPrisma.users_honors.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          validation_status: 'APPROVED',
          validate: true,
          validated_by_id: 'reviewer-1',
          rejection_reason: null,
        }),
      }),
    );
  });

  it('rejects only pending honors and clears validate', async () => {
    mockPrisma.users_honors.findUnique.mockResolvedValue(pendingHonor());
    mockPrisma.users_honors.update.mockResolvedValue(
      pendingHonor({ validation_status: 'REJECTED', validate: false }),
    );

    await expect(service.reject(10, 'reviewer-1', 'Falta evidencia')).resolves.toEqual({
      id: 10,
      type: 'honor',
      status: 'REJECTED',
    });

    expect(mockPrisma.users_honors.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          validation_status: 'REJECTED',
          validate: false,
          rejection_reason: 'Falta evidencia',
        }),
      }),
    );
  });
});
```

**Step 3: Run test to verify it fails**

Run:

```bash
cd sacdia-backend
pnpm test -- honor-validation-workflow.service.spec.ts --runInBand
```

Expected: FAIL because `HonorValidationWorkflowService` does not exist.

**Step 4: Implement minimal service skeleton**

Create `sacdia-backend/src/honors/honor-validation-workflow.service.ts`:

```ts
import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { AchievementsService } from '../achievements/achievements.service';
import {
  AppBadRequestException,
  AppNotFoundException,
} from '../common/errors/app.exception';
import { ErrorCode } from '../common/errors/error-codes';
import { HonorValidationResult } from './honor-validation-workflow.types';

const HONOR_STATUS_IN_PROGRESS = 'IN_PROGRESS' as const;
const HONOR_STATUS_PENDING = 'PENDING_REVIEW' as const;
const HONOR_STATUS_APPROVED = 'APPROVED' as const;
const HONOR_STATUS_REJECTED = 'REJECTED' as const;

@Injectable()
export class HonorValidationWorkflowService {
  private readonly logger = new Logger(HonorValidationWorkflowService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
    private readonly achievementsService: AchievementsService,
  ) {}

  async submitForReview(userHonorId: number, userId: string) {
    const userHonor = await this.prisma.users_honors.findUnique({
      where: { user_honor_id: userHonorId },
    });

    if (!userHonor) {
      throw new AppNotFoundException(ErrorCode.VALIDATION_USER_HONOR_NOT_FOUND);
    }

    if (userHonor.user_id !== userId) {
      throw new AppBadRequestException(ErrorCode.VALIDATION_HONOR_NOT_OWNED);
    }

    if (!userHonor.active) {
      throw new AppBadRequestException(ErrorCode.VALIDATION_HONOR_INACTIVE);
    }

    if (userHonor.validate || userHonor.validation_status === HONOR_STATUS_APPROVED) {
      throw new AppBadRequestException(ErrorCode.VALIDATION_HONOR_ALREADY_VALIDATED);
    }

    if (userHonor.validation_status === HONOR_STATUS_PENDING) {
      throw new AppBadRequestException(ErrorCode.VALIDATION_HONOR_ALREADY_PENDING);
    }

    if (![HONOR_STATUS_IN_PROGRESS, HONOR_STATUS_REJECTED].includes(userHonor.validation_status as any)) {
      throw new AppBadRequestException(ErrorCode.VALIDATION_HONOR_INVALID_STATUS);
    }

    await this.assertSubmitEligibility(userHonor);

    const now = new Date();
    const result = await this.prisma.$transaction(async (tx) => {
      const updated = await tx.users_honors.update({
        where: { user_honor_id: userHonorId },
        data: {
          validation_status: HONOR_STATUS_PENDING,
          submitted_at: now,
          rejection_reason: null,
          modified_at: now,
        },
      });

      await tx.validation_logs.create({
        data: {
          entity_type: 'honor',
          entity_id: String(userHonorId),
          user_id: userId,
          action: 'submitted',
          performed_by: userId,
          comment: 'Honor enviado a revision por el miembro',
        },
      });

      return updated;
    });

    await this.notifyHonorSubmitted(userHonorId, userId);
    return result;
  }

  async approve(
    userHonorId: number,
    actorId: string,
    comments?: string,
  ): Promise<HonorValidationResult> {
    const record = await this.prisma.users_honors.findUnique({
      where: { user_honor_id: userHonorId },
      include: {
        honors: {
          select: {
            honor_id: true,
            name: true,
            honors_category_id: true,
            club_type_id: true,
          },
        },
      },
    });

    if (!record) {
      throw new AppNotFoundException(ErrorCode.EVIDENCE_REVIEW_USER_HONOR_NOT_FOUND, { id: userHonorId });
    }

    if (record.validation_status !== HONOR_STATUS_PENDING) {
      throw new AppBadRequestException(ErrorCode.VALIDATION_HONOR_NOT_PENDING, {
        status: record.validation_status,
      });
    }

    const now = new Date();
    const updated = await this.prisma.$transaction(async (tx) => {
      const result = await tx.users_honors.update({
        where: { user_honor_id: userHonorId },
        data: {
          validation_status: HONOR_STATUS_APPROVED,
          validate: true,
          validated_by_id: actorId,
          validated_at: now,
          rejection_reason: null,
          modified_at: now,
        },
      });

      await tx.validation_logs.create({
        data: {
          entity_type: 'honor',
          entity_id: String(userHonorId),
          user_id: record.user_id,
          action: 'APPROVED',
          performed_by: actorId,
          comment: comments ?? null,
        },
      });

      return result;
    });

    await this.emitHonorValidated(record);
    return { id: updated.user_honor_id, type: 'honor', status: updated.validation_status as any };
  }

  async reject(
    userHonorId: number,
    actorId: string,
    reason: string,
  ): Promise<HonorValidationResult> {
    const record = await this.prisma.users_honors.findUnique({
      where: { user_honor_id: userHonorId },
    });

    if (!record) {
      throw new AppNotFoundException(ErrorCode.EVIDENCE_REVIEW_USER_HONOR_NOT_FOUND, { id: userHonorId });
    }

    if (record.validation_status !== HONOR_STATUS_PENDING) {
      throw new AppBadRequestException(ErrorCode.VALIDATION_HONOR_NOT_PENDING, {
        status: record.validation_status,
      });
    }

    const now = new Date();
    const updated = await this.prisma.$transaction(async (tx) => {
      const result = await tx.users_honors.update({
        where: { user_honor_id: userHonorId },
        data: {
          validation_status: HONOR_STATUS_REJECTED,
          validate: false,
          validated_by_id: actorId,
          validated_at: now,
          rejection_reason: reason,
          modified_at: now,
        },
      });

      await tx.validation_logs.create({
        data: {
          entity_type: 'honor',
          entity_id: String(userHonorId),
          user_id: record.user_id,
          action: 'REJECTED',
          performed_by: actorId,
          comment: reason,
        },
      });

      return result;
    });

    return { id: updated.user_honor_id, type: 'honor', status: updated.validation_status as any };
  }

  private async assertSubmitEligibility(userHonor: any) {
    const hasEvidence = await this.hasMinimumEvidence(userHonor);
    if (!hasEvidence) {
      throw new AppBadRequestException(ErrorCode.VALIDATION_HONOR_MISSING_EVIDENCE);
    }

    const complete = await this.areRequiredRequirementsComplete(userHonor.user_honor_id, userHonor.honor_id);
    if (!complete) {
      throw new AppBadRequestException(ErrorCode.VALIDATION_HONOR_REQUIREMENTS_INCOMPLETE);
    }

    if (userHonor.validation_status === HONOR_STATUS_REJECTED && userHonor.validated_at) {
      const changedAfterRejection = userHonor.modified_at > userHonor.validated_at;
      if (!changedAfterRejection) {
        throw new AppBadRequestException(ErrorCode.VALIDATION_HONOR_NO_CHANGES_AFTER_REJECTION);
      }
    }
  }

  private async hasMinimumEvidence(userHonor: any): Promise<boolean> {
    const images = Array.isArray(userHonor.images) ? userHonor.images : [];
    if (images.length > 0 || Boolean(userHonor.document) || Boolean(userHonor.certificate)) {
      return true;
    }

    const generalEvidenceCount = await this.prisma.evidence_files.count({
      where: { user_honor_id: userHonor.user_honor_id, active: true },
    });
    if (generalEvidenceCount > 0) return true;

    const requirementEvidenceCount = await this.prisma.requirement_evidence.count({
      where: {
        active: true,
        progress: { user_honor_id: userHonor.user_honor_id, active: true },
      },
    });
    return requirementEvidenceCount > 0;
  }

  private async areRequiredRequirementsComplete(userHonorId: number, honorId: number): Promise<boolean> {
    const requirements = await this.prisma.honor_requirements.findMany({
      where: { honor_id: honorId, active: true },
      select: { requirement_id: true, parent_id: true },
    });

    if (requirements.length === 0) return true;

    const parentIds = new Set(requirements.map((r) => r.parent_id).filter(Boolean));
    const leafRequirementIds = requirements
      .filter((r) => !parentIds.has(r.requirement_id))
      .map((r) => r.requirement_id);

    if (leafRequirementIds.length === 0) return true;

    const progress = await this.prisma.user_honor_requirement_progress.findMany({
      where: {
        user_honor_id: userHonorId,
        requirement_id: { in: leafRequirementIds },
        active: true,
        completed: true,
      },
      select: { requirement_id: true },
    });

    return new Set(progress.map((p) => p.requirement_id)).size === leafRequirementIds.length;
  }

  private async notifyHonorSubmitted(userHonorId: number, userId: string) {
    try {
      const memberSection = await this.prisma.club_role_assignments.findFirst({
        where: { user_id: userId, active: true },
        select: { club_section_id: true },
      });

      if (memberSection?.club_section_id) {
        void this.notifications.sendToSectionRole(
          memberSection.club_section_id,
          ['coordinator', 'director'],
          'Nuevo honor enviado a revisión',
          'Un miembro ha enviado un honor para validación',
          { type: 'validation', entity_type: 'honor', entity_id: String(userHonorId) },
          'validation:honor_submitted',
        );
      }
    } catch (error: unknown) {
      this.logger.warn(`Notification failed for honor submission ${userHonorId}: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  private async emitHonorValidated(record: any) {
    try {
      await this.achievementsService.emitEvent({
        userId: record.user_id,
        eventType: 'honor.validated',
        payload: {
          honor_id: record.honors?.honor_id ?? record.honor_id,
          category_id: record.honors?.honors_category_id ?? null,
          honor_name: record.honors?.name ?? null,
          club_type_id: record.honors?.club_type_id ?? null,
        },
      });
    } catch (error) {
      this.logger.warn(`Failed to emit achievement event: ${(error as Error).message}`);
    }
  }
}
```

**Step 5: Run tests**

Run:

```bash
cd sacdia-backend
pnpm test -- honor-validation-workflow.service.spec.ts --runInBand
```

Expected: PASS after minor typing fixes.

**Step 6: Commit**

```bash
git add sacdia-backend/src/honors/honor-validation-workflow.types.ts sacdia-backend/src/honors/honor-validation-workflow.service.ts sacdia-backend/src/honors/honor-validation-workflow.service.spec.ts
git commit -m "feat: add honor validation workflow service"
```

---

## Task 3: Register workflow service in Nest modules

**Files:**
- Modify: `sacdia-backend/src/honors/honors.module.ts`
- Modify: `sacdia-backend/src/validation/validation.module.ts`
- Modify: `sacdia-backend/src/evidence-review/evidence-review.module.ts`

**Step 1: Update HonorsModule**

Modify `sacdia-backend/src/honors/honors.module.ts`:

```ts
import { NotificationsModule } from '../notifications/notifications.module';
import { HonorValidationWorkflowService } from './honor-validation-workflow.service';

@Module({
  imports: [PrismaModule, AchievementsModule, NotificationsModule],
  controllers: [
    HonorsController,
    UserHonorsController,
    HonorRequirementsController,
    UserHonorRequirementsController,
    AdminHonorsController,
  ],
  providers: [
    HonorsService,
    HonorRequirementsService,
    AdminHonorsService,
    HonorValidationWorkflowService,
  ],
  exports: [HonorsService, HonorValidationWorkflowService],
})
export class HonorsModule {}
```

**Step 2: Update ValidationModule**

Modify `sacdia-backend/src/validation/validation.module.ts`:

```ts
import { HonorsModule } from '../honors/honors.module';

@Module({
  imports: [PrismaModule, NotificationsModule, HonorsModule],
  controllers: [ValidationController],
  providers: [ValidationService],
  exports: [ValidationService],
})
export class ValidationModule {}
```

**Step 3: Update EvidenceReviewModule**

Modify `sacdia-backend/src/evidence-review/evidence-review.module.ts`:

```ts
import { HonorsModule } from '../honors/honors.module';

@Module({
  imports: [PrismaModule, AchievementsModule, HonorsModule],
  controllers: [EvidenceReviewController],
  providers: [EvidenceReviewService],
  exports: [EvidenceReviewService],
})
export class EvidenceReviewModule {}
```

**Step 4: Run tests**

Run:

```bash
cd sacdia-backend
pnpm test -- honor-validation-workflow.service.spec.ts evidence-review.service.spec.ts --runInBand
```

Expected: PASS.

**Step 5: Commit**

```bash
git add sacdia-backend/src/honors/honors.module.ts sacdia-backend/src/validation/validation.module.ts sacdia-backend/src/evidence-review/evidence-review.module.ts
git commit -m "feat: register honor validation workflow"
```

---

## Task 4: Delegate honor submit/review from ValidationService

**Files:**
- Modify: `sacdia-backend/src/validation/validation.service.ts`
- Create or modify: `sacdia-backend/src/validation/validation.service.spec.ts`

**Step 1: Write failing delegation tests**

If `validation.service.spec.ts` does not exist, create it. Test only honor delegation to avoid class regression noise.

```ts
import { ValidationService } from './validation.service';

describe('ValidationService honor workflow delegation', () => {
  const prisma = {};
  const notifications = {};
  const honorWorkflow = {
    submitForReview: jest.fn(),
    approve: jest.fn(),
    reject: jest.fn(),
  };

  let service: ValidationService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new ValidationService(prisma as any, notifications as any, honorWorkflow as any);
  });

  it('delegates honor submit to HonorValidationWorkflowService', async () => {
    honorWorkflow.submitForReview.mockResolvedValue({ user_honor_id: 10 });

    await service.submitForReview('honor', 10, 'user-1');

    expect(honorWorkflow.submitForReview).toHaveBeenCalledWith(10, 'user-1');
  });

  it('delegates honor approve to HonorValidationWorkflowService', async () => {
    honorWorkflow.approve.mockResolvedValue({ id: 10, type: 'honor', status: 'APPROVED' });

    await service.review('honor', 10, 'approved', 'reviewer-1', 'ok');

    expect(honorWorkflow.approve).toHaveBeenCalledWith(10, 'reviewer-1', 'ok');
  });

  it('delegates honor reject to HonorValidationWorkflowService', async () => {
    honorWorkflow.reject.mockResolvedValue({ id: 10, type: 'honor', status: 'REJECTED' });

    await service.review('honor', 10, 'rejected', 'reviewer-1', 'Falta evidencia');

    expect(honorWorkflow.reject).toHaveBeenCalledWith(10, 'reviewer-1', 'Falta evidencia');
  });
});
```

**Step 2: Run test to verify it fails**

Run:

```bash
cd sacdia-backend
pnpm test -- validation.service.spec.ts --runInBand
```

Expected: FAIL because constructor does not accept `HonorValidationWorkflowService` and methods do not delegate.

**Step 3: Inject workflow service**

Modify constructor in `sacdia-backend/src/validation/validation.service.ts`:

```ts
import { HonorValidationWorkflowService } from '../honors/honor-validation-workflow.service';

constructor(
  private readonly prisma: PrismaService,
  private readonly notifications: NotificationsService,
  private readonly honorValidationWorkflow: HonorValidationWorkflowService,
) {}
```

**Step 4: Delegate honor submit**

Replace honor branch in `submitForReview`:

```ts
if (entityType === 'class') {
  return this.submitClassForReview(entityId, userId);
}
return this.honorValidationWorkflow.submitForReview(entityId, userId);
```

**Step 5: Delegate honor review**

Replace honor branch in `review`:

```ts
if (entityType === 'class') {
  return this.reviewClass(entityId, action, performedBy, comment);
}

if (action === 'approved') {
  return this.honorValidationWorkflow.approve(entityId, performedBy, comment);
}

return this.honorValidationWorkflow.reject(entityId, performedBy, comment!);
```

**Step 6: Remove private duplicate honor methods**

Delete these methods from `ValidationService`:

- `private async submitHonorForReview(...)`
- `private async reviewHonor(...)`

Do not touch class validation methods.

**Step 7: Run tests**

Run:

```bash
cd sacdia-backend
pnpm test -- validation.service.spec.ts honor-validation-workflow.service.spec.ts --runInBand
```

Expected: PASS.

**Step 8: Commit**

```bash
git add sacdia-backend/src/validation/validation.service.ts sacdia-backend/src/validation/validation.service.spec.ts
git commit -m "refactor: delegate honor validation workflow"
```

---

## Task 5: Delegate honor approve/reject from EvidenceReviewService

**Files:**
- Modify: `sacdia-backend/src/evidence-review/evidence-review.service.ts`
- Modify: `sacdia-backend/src/evidence-review/evidence-review.service.spec.ts`

**Step 1: Add failing delegation tests**

Append tests to `sacdia-backend/src/evidence-review/evidence-review.service.spec.ts`:

```ts
it('delegates honor approval to HonorValidationWorkflowService', async () => {
  const workflow = { approve: jest.fn().mockResolvedValue({ id: 10, type: 'honor', status: 'APPROVED' }) };
  const serviceWithWorkflow = new EvidenceReviewService(mockPrisma as any, { emitEvent: jest.fn() } as any, workflow as any);

  await expect(serviceWithWorkflow.approve('honor', 10, 'reviewer-1', { comments: 'ok' })).resolves.toEqual({
    id: 10,
    type: 'honor',
    status: 'APPROVED',
  });

  expect(workflow.approve).toHaveBeenCalledWith(10, 'reviewer-1', 'ok');
});

it('delegates honor rejection to HonorValidationWorkflowService', async () => {
  const workflow = { reject: jest.fn().mockResolvedValue({ id: 10, type: 'honor', status: 'REJECTED' }) };
  const serviceWithWorkflow = new EvidenceReviewService(mockPrisma as any, { emitEvent: jest.fn() } as any, workflow as any);

  await expect(serviceWithWorkflow.reject('honor', 10, 'reviewer-1', { reason: 'Falta evidencia' })).resolves.toEqual({
    id: 10,
    type: 'honor',
    status: 'REJECTED',
  });

  expect(workflow.reject).toHaveBeenCalledWith(10, 'reviewer-1', 'Falta evidencia');
});
```

**Step 2: Run test to verify it fails**

Run:

```bash
cd sacdia-backend
pnpm test -- evidence-review.service.spec.ts --runInBand
```

Expected: FAIL because constructor does not accept workflow and honor methods do not delegate.

**Step 3: Inject workflow service**

Modify `sacdia-backend/src/evidence-review/evidence-review.service.ts` constructor:

```ts
import { HonorValidationWorkflowService } from '../honors/honor-validation-workflow.service';

constructor(
  private readonly prisma: PrismaService,
  private readonly achievementsService: AchievementsService,
  private readonly honorValidationWorkflow: HonorValidationWorkflowService,
) {}
```

**Step 4: Delegate honor branches**

In `approve(...)`, replace honor branch with:

```ts
case 'honor':
  return this.honorValidationWorkflow.approve(id, actorId, dto.comments);
```

In `reject(...)`, replace honor branch with:

```ts
case 'honor':
  return this.honorValidationWorkflow.reject(id, actorId, dto.reason);
```

**Step 5: Remove private duplicate honor methods**

Delete from `EvidenceReviewService`:

- `private async approveHonor(...)`
- `private async rejectHonor(...)`

Keep class review methods unchanged.

**Step 6: Run tests**

Run:

```bash
cd sacdia-backend
pnpm test -- evidence-review.service.spec.ts honor-validation-workflow.service.spec.ts --runInBand
```

Expected: PASS.

**Step 7: Commit**

```bash
git add sacdia-backend/src/evidence-review/evidence-review.service.ts sacdia-backend/src/evidence-review/evidence-review.service.spec.ts
git commit -m "refactor: reuse honor workflow in evidence review"
```

---

## Task 6: Keep rejected-resubmit tracking honest

**Files:**
- Modify: `sacdia-backend/src/honors/honors.service.ts`
- Modify: `sacdia-backend/src/honors/honor-requirements.service.ts`
- Modify: `sacdia-backend/src/honors/honor-validation-workflow.service.spec.ts`

**Why:** The workflow uses `users_honors.modified_at > users_honors.validated_at` to know whether a rejected honor changed before resubmit. Evidence and requirement changes must bump parent `users_honors.modified_at`.

**Step 1: Add failing tests**

Add tests proving rejected honors cannot resubmit when `modified_at <= validated_at` and can resubmit when `modified_at > validated_at`.

```ts
it('blocks rejected honor resubmit when there are no changes after rejection', async () => {
  mockPrisma.users_honors.findUnique.mockResolvedValue(
    pendingHonor({
      validation_status: 'REJECTED',
      validated_at: new Date('2026-06-01T11:30:00.000Z'),
      modified_at: new Date('2026-06-01T11:30:00.000Z'),
    }),
  );
  mockPrisma.evidence_files.count.mockResolvedValue(0);
  mockPrisma.honor_requirements.findMany.mockResolvedValue([]);
  mockPrisma.user_honor_requirement_progress.findMany.mockResolvedValue([]);
  mockPrisma.requirement_evidence.count.mockResolvedValue(0);

  await expect(service.submitForReview(10, 'user-1')).rejects.toMatchObject({
    code: ErrorCode.VALIDATION_HONOR_NO_CHANGES_AFTER_REJECTION,
  });
});
```

**Step 2: Bump parent on general evidence changes**

In `sacdia-backend/src/honors/honors.service.ts`, make sure these methods update `modified_at` on `users_honors`:

- `uploadUserHonorFiles(...)`
- `updateUserHonor(...)`
- `startHonor(...)` already resets state; keep as-is unless missing `modified_at`.

Expected data change:

```ts
modified_at: new Date(),
```

**Step 3: Bump parent on requirement progress/evidence changes**

In `sacdia-backend/src/honors/honor-requirements.service.ts`, after successful mutations that affect progress/evidence, update parent:

```ts
await this.prisma.users_honors.update({
  where: { user_honor_id: userHonor.user_honor_id },
  data: { modified_at: new Date() },
});
```

Apply to methods that:

- update one requirement progress
- batch update requirement progress
- upload requirement evidence
- link requirement evidence
- delete requirement evidence

**Step 4: Run tests**

Run:

```bash
cd sacdia-backend
pnpm test -- honor-validation-workflow.service.spec.ts honors.service.spec.ts --runInBand
```

Expected: PASS after adjusting mocks if existing honors tests assert exact update payloads.

**Step 5: Commit**

```bash
git add sacdia-backend/src/honors/honors.service.ts sacdia-backend/src/honors/honor-requirements.service.ts sacdia-backend/src/honors/honor-validation-workflow.service.spec.ts
git commit -m "fix: track honor changes after rejection"
```

---

## Task 7: Add focused e2e coverage for HTTP submit behavior

**Files:**
- Modify: `sacdia-backend/test/honors.e2e-spec.ts` or create `sacdia-backend/test/honor-validation.e2e-spec.ts`

**Step 1: Prefer unit tests if E2E fixtures are weak**

If the e2e test suite does not have reliable seeded users/honors/auth helpers, do not over-invest here in PR1. Add only lightweight e2e coverage if helpers already exist.

**Recommended e2e behaviors:**

- `POST /api/v1/validation/submit` rejects missing evidence.
- `POST /api/v1/validation/submit` rejects incomplete requirements.
- `POST /api/v1/evidence-review/honor/:id/approve` rejects non-pending honor.

**Step 2: Run targeted e2e only if reliable**

Run:

```bash
cd sacdia-backend
pnpm test:e2e -- honor-validation.e2e-spec.ts --runInBand
```

Expected: PASS.

**Step 3: Commit if added**

```bash
git add sacdia-backend/test/honor-validation.e2e-spec.ts
git commit -m "test: cover honor validation workflow endpoints"
```

---

## Task 8: Update backend API documentation for PR1 behavior

**Files:**
- Modify: `docs/features/honores.md`
- Modify: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`

**Step 1: Update feature doc**

In `docs/features/honores.md`, replace stale statement saying institutional validation does not exist.

Document canonical backend behavior:

```md
### Validación institucional de honores

El flujo runtime de honores usa `users_honors.validation_status` como fuente de verdad:

- `IN_PROGRESS`: inscripción/avance editable.
- `PENDING_REVIEW`: enviado a revisión institucional.
- `APPROVED`: honor aprobado; `validate=true` se mantiene solo por compatibilidad.
- `REJECTED`: honor rechazado; el usuario puede corregir evidencia/progreso y reenviar.

El envío a revisión se realiza por `POST /api/v1/validation/submit` con `entity_type=honor` y `entity_id=user_honor_id`.

Desde PR1, backend rechaza el envío si faltan evidencias mínimas o requisitos obligatorios completos. La UI puede anticipar esos bloqueos, pero no es la fuente de verdad.
```

**Step 2: Update API reference**

In `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, document submit errors for honors:

```md
Honor submit validation errors:
- `VALIDATION_HONOR_MISSING_EVIDENCE`
- `VALIDATION_HONOR_REQUIREMENTS_INCOMPLETE`
- `VALIDATION_HONOR_NO_CHANGES_AFTER_REJECTION`
- `VALIDATION_HONOR_NOT_PENDING`
```

**Step 3: Commit**

```bash
git add docs/features/honores.md docs/api/ENDPOINTS-LIVE-REFERENCE.md
git commit -m "docs: document honor validation workflow"
```

---

## Task 9: Final verification for PR1

**Files:**
- No code changes unless verification reveals a bug.

**Step 1: Run targeted unit tests**

Run:

```bash
cd sacdia-backend
pnpm test -- honor-validation-workflow.service.spec.ts validation.service.spec.ts evidence-review.service.spec.ts honors.service.spec.ts --runInBand
```

Expected: PASS.

**Step 2: Run honors e2e if stable**

Run:

```bash
cd sacdia-backend
pnpm test:e2e -- honors.e2e-spec.ts --runInBand
```

Expected: PASS.

**Step 3: Check formatting manually or run formatter only on touched backend files**

Run only if needed:

```bash
cd sacdia-backend
pnpm exec prettier --write src/honors/honor-validation-workflow.service.ts src/honors/honor-validation-workflow.service.spec.ts src/honors/honor-validation-workflow.types.ts src/validation/validation.service.ts src/validation/validation.service.spec.ts src/evidence-review/evidence-review.service.ts src/evidence-review/evidence-review.service.spec.ts
```

Expected: files formatted.

**Step 4: Review diff**

Run:

```bash
git diff --stat
git diff -- sacdia-backend/src/honors sacdia-backend/src/validation sacdia-backend/src/evidence-review docs/features/honores.md docs/api/ENDPOINTS-LIVE-REFERENCE.md
```

Expected: changes are limited to PR1 backend workflow + docs.

---

## PR1 Acceptance Criteria

- `ValidationService` no longer owns honor submit/review business rules.
- `EvidenceReviewService` no longer owns honor approve/reject business rules.
- `HonorValidationWorkflowService` is the only backend service changing honor validation state.
- `validation_status` drives the workflow.
- `validate` is only synchronized for backward compatibility.
- Submit blocks missing evidence.
- Submit blocks incomplete required requirements.
- Submit blocks rejected honors when nothing changed after rejection.
- Approve/reject only work from `PENDING_REVIEW`.
- Reject sets `validate=false`.
- Targeted tests pass.
- Documentation no longer claims honor validation does not exist.

---

## What PR1 intentionally does NOT do

- It does not redesign the mobile UI.
- It does not redesign the admin review page.
- It does not create the full `HonorReviewPacket` yet.
- It does not migrate all legacy evidence into `evidence_files` yet.
- It does not remove `validate` from the database.
- It does not clean stale admin catalog screens.

Those belong in PR2+.
