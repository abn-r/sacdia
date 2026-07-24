# User Access and Membership Review Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace SACDIA's misleading global user approval flow with review-by-exception, and formalize pending club/section membership as the real limited-access app state.

**Architecture:** Keep identity/system access separate from club/section membership. `club_role_assignments.status` remains the operational gate for club-scoped features. Global admin review becomes an exception workflow, not a manual approval queue for every user.

**Tech Stack:** NestJS + Prisma backend, Next.js admin, Flutter app, Markdown docs.

---

## Preconditions

- Work from clean `development` branches or isolated worktrees.
- Do not run builds unless explicitly requested.
- Preserve existing WIP in root/admin/app repos.
- Use targeted tests only.

## Task 1: Update canonical feature documentation

**Files:**

- Modify: `/Users/abner/Documents/development/sacdia/docs/features/auth.md`
- Modify: `/Users/abner/Documents/development/sacdia/docs/features/membership-requests.md`
- Reference: `/Users/abner/Documents/development/sacdia/docs/plans/2026-05-22-user-access-and-membership-review-design.md`

**Steps:**

1. Update `auth.md` so global approval is not described as the main access gate.
2. Describe global review as exception-based.
3. Keep `access_app` and `access_panel` as explicit surface access controls.
4. Update `membership-requests.md` to define pending membership UX and operational gating.
5. Document the closed pending-membership rules:
   - one pending membership request per user;
   - self-cancel restarts post-registration from club/section selection;
   - director, assistant director, secretary, and secretary-treasurer receive new-request notifications;
   - pending users keep profile/self-management access;
   - pending users see requested club/section as “Pendiente de aprobación”;
   - bulk/staged specialties and classes capture remains personal and does not unlock club operations.
6. Verify terminology:
   - “usuario del sistema” != “miembro aceptado de club/sección”
   - “revisión administrativa” != “solicitud de membresía”

**Validation:**

```bash
grep -n "aprobacion administrativa\\|membresia\\|pending" docs/features/auth.md docs/features/membership-requests.md
```

## Task 2: Demote global approval controls in admin user detail

**Files:**

- Modify: `/Users/abner/Documents/development/sacdia/sacdia-admin/src/components/users/detail/hero.tsx`
- Modify as needed: `/Users/abner/Documents/development/sacdia/sacdia-admin/src/app/(dashboard)/dashboard/users/[userId]/page.tsx`
- Modify as needed: `/Users/abner/Documents/development/sacdia/sacdia-admin/messages/es.json`
- Test if existing harness supports it: admin user detail/component tests.

**Expected behavior:**

- The hero should not present “Aprobar/Rechazar” as primary actions for normal pending users.
- If `approval_status` remains visible, label it as administrative review state, not membership state.
- Membership actions must remain in membership request surfaces.

**Steps:**

1. Inspect current `UserDetailHero` props and button rendering.
2. Add or adapt tests around pending users.
3. Remove primary approval/rejection buttons from hero or hide them behind an explicit exception-review condition.
4. Update copy to avoid confusion with club membership.
5. Run targeted tests only.

**Validation:**

```bash
pnpm exec jest path/to/targeted-test --runInBand
```

## Task 3: Align backend admin approval semantics

**Files:**

- Inspect: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/admin/admin-users.controller.ts`
- Inspect: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/admin/admin-users.service.ts`
- Inspect: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/admin/dto/users.dto.ts`
- Modify tests if semantics change:
  - `/Users/abner/Documents/development/sacdia/sacdia-backend/src/admin/admin-users.service.spec.ts`
  - `/Users/abner/Documents/development/sacdia/sacdia-backend/src/admin/admin-users.controller.spec.ts`

**Expected behavior:**

- Do not introduce global approval as an auth gate.
- If endpoint remains, rename/position it as exception review or deprecate it.
- Align permissions across backend, admin, and docs.

**Steps:**

1. Decide whether to keep endpoint as compatibility-only or redesign later.
2. If kept, document it as administrative review, not general access approval.
3. Ensure backend does not imply membership approval.
4. Add tests only if behavior changes.

**Validation:**

```bash
pnpm exec jest src/admin/admin-users.service.spec.ts --runInBand
```

## Task 4: Define mobile pending-membership UX contract

**Files:**

- Modify: `/Users/abner/Documents/development/sacdia/docs/features/membership-requests.md`
- Later implementation targets:
  - `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/home/presentation/widgets/club_context_card.dart`
  - `/Users/abner/Documents/development/sacdia/sacdia-app/lib/core/widgets/section_switcher_sheet.dart`
  - app routing/auth-gate files as needed.

**Expected behavior:**

- `pending`: show request status screen/card, requested club/section as “Pendiente de aprobación”, and block club features.
- `rejected`: show rejection reason and next action.
- `expired`: show expiration and allow new request.
- `active`: enable normal club context/features.
- Pending users can access profile, manage personal information, and use personal bulk/staging capture for specialties and classes.
- Pending users can cancel their own request; cancellation restarts post-registration from club/section selection.

**Steps:**

1. Document what pending users can see.
2. Document what pending users cannot access.
3. Document cancellation semantics.
4. Document rejection and expiration states.
5. Later, implement Flutter UI with targeted widget tests.

**Validation:**

```bash
grep -n "pending\\|rejected\\|expired\\|active" docs/features/membership-requests.md
```

## Task 5: Enforce pending-membership backend rules

**Files:**

- Inspect/modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/membership-requests/membership-requests.service.ts`
- Inspect/modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/post-registration/post-registration.service.ts`
- Test: related membership/post-registration service specs.

**Expected behavior:**

- A user cannot have multiple pending membership requests.
- Cancelling a pending request resets the club/section selection step without deleting profile data.
- Creating a request notifies director, assistant director, secretary, and secretary-treasurer for the target club/section.
- Pending requests do not produce active club permissions.

**Steps:**

1. Write/adjust failing tests for one-pending-request enforcement.
2. Write/adjust failing tests for self-cancel behavior.
3. Write/adjust failing tests or contract coverage for notification recipient resolution.
4. Implement the minimum backend changes.
5. Run targeted tests only.

**Validation:**

```bash
pnpm exec jest src/membership-requests/membership-requests.service.spec.ts src/post-registration/post-registration.service.spec.ts --runInBand
```

## Task 6: Final consistency pass

**Files:**

- `/Users/abner/Documents/development/sacdia/docs/features/auth.md`
- `/Users/abner/Documents/development/sacdia/docs/features/membership-requests.md`
- `/Users/abner/Documents/development/sacdia/docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- Admin/backend/app files touched by implementation.

**Steps:**

1. Search for old wording that says all users require global approval.
2. Search for ambiguous “Aprobar/Rechazar usuario” labels.
3. Confirm membership approval references point to membership requests.
4. Run targeted tests only; no builds.

**Validation:**

```bash
grep -R "approval_status\\|Aprobar usuario\\|Rechazar usuario\\|aprobacion administrativa" docs sacdia-admin/src sacdia-backend/src sacdia-app/lib
```

## Delivery notes

- Prefer small PRs:
  1. docs contract update;
  2. admin UX cleanup;
  3. backend semantic alignment if needed;
  4. mobile pending-membership UX.
- Do not mix with existing camporee/materials WIP.
- Do not add AI attribution to commits.
