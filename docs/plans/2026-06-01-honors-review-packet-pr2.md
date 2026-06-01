# Honors Review Packet PR2 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Expose and render a complete review packet for submitted honors so reviewers can see general evidence, per-requirement progress, and per-requirement evidence in one place.

**Architecture:** Keep PR1's `HonorValidationWorkflowService` as the only state transition owner. PR2 extends the read side of `EvidenceReviewService.getDetail('honor', id)` with an optional `honor_review_packet` payload and updates the admin evidence detail dialog to render it when present. This avoids inventing a parallel endpoint while preserving backward compatibility for class evidence details.

**Tech Stack:** NestJS 11, Prisma 7, Jest/ts-jest, Next.js 16, React Testing Library/Vitest, TypeScript.

**Non-negotiables:**
- Do not run builds.
- Use TDD: failing tests before implementation.
- Do not commit unless explicitly requested.
- Keep PR2 read-side only; do not change approval/rejection state transitions.

---

## Desired backend response

`GET /api/v1/evidence-review/honor/:userHonorId` should keep the existing `EvidenceDetail` shape and add:

```ts
honor_review_packet?: {
  user_honor_id: number;
  honor_id: number;
  honor_name: string;
  validation_status: string;
  progress: {
    total_requirements: number;
    completed_count: number;
    progress_percentage: number;
  };
  general_files: EvidenceFile[];
  requirement_files: EvidenceFile[];
  requirements: Array<{
    requirement_id: number;
    requirement_number: string;
    display_label: string | null;
    requirement_text: string;
    requires_evidence: boolean;
    completed: boolean;
    completed_at: Date | null;
    evidence_count: number;
    evidences: EvidenceFile[];
  }>;
}
```

`files` should include all reviewable honor evidence: normalized `evidence_files`, legacy `certificate`, `document`, `images`, and per-requirement evidence.

---

## Task 1: Backend tests for honor review packet

**Files:**
- Modify: `sacdia-backend/src/evidence-review/evidence-review.service.spec.ts`

**Steps:**
1. Add a test for `getDetail('honor', id)` returning `honor_review_packet`.
2. Mock `users_honors.findUnique`, `honor_requirements.findMany`, and `user_honor_requirement_progress.findMany`.
3. Assert packet progress counts, requirement completion, and combined files.
4. Run `pnpm test -- evidence-review.service.spec.ts --runInBand` and verify RED.

## Task 2: Backend implementation

**Files:**
- Modify: `sacdia-backend/src/evidence-review/evidence-review.service.ts`

**Steps:**
1. Extend `EvidenceDetail` with optional `honor_review_packet`.
2. Add backend types for packet items.
3. Update `getHonorDetail` to query requirements and progress/evidence.
4. Add helper to normalize legacy honor files.
5. Add helper to normalize requirement evidence into `EvidenceFile`.
6. Return `files` as all reviewable evidence and packet as structured review context.
7. Run backend targeted tests.

## Task 3: Admin API types

**Files:**
- Modify: `sacdia-admin/src/lib/api/evidence-review.ts`

**Steps:**
1. Add TypeScript types for `HonorReviewPacket`.
2. Extend `EvidenceDetail` with optional `honor_review_packet`.
3. Keep existing call signatures unchanged.

## Task 4: Admin detail rendering

**Files:**
- Modify: `sacdia-admin/src/components/evidence-review/evidence-detail-dialog.tsx`
- Modify: `sacdia-admin/src/components/evidence-review/evidence-detail-dialog.test.tsx`

**Steps:**
1. Write a failing test where an honor detail includes `honor_review_packet`.
2. Assert the dialog renders progress and requirement evidence context.
3. Implement a compact honor packet section above attached files.
4. Keep class detail rendering unchanged.
5. Run targeted Vitest for the dialog.

## Task 5: Documentation and verification

**Files:**
- Modify: `docs/features/honores.md`
- Modify: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`

**Steps:**
1. Document that evidence-review honor detail includes `honor_review_packet`.
2. Run backend targeted Jest.
3. Run admin targeted Vitest if dependencies are available.
4. Run `git diff --check` in touched repos.

---

## Acceptance criteria

- Honor detail response includes a structured review packet.
- Packet includes requirement progress and requirement evidence.
- `files` includes all evidence reviewers need to see.
- Existing class evidence detail behavior remains unchanged.
- Admin detail dialog shows packet context for honors only.
- Targeted tests pass.
