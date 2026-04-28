# Achievements Documentation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

## Execution status — COMPLETED

| Task | Status | Executed |
|---|---|---|
| 1. Audit achievements runtime | ✅ done | 2026-04-14 |
| 2. Draft the feature document | ✅ done | 2026-04-14 |
| 3. Register in feature registry | ✅ done | 2026-04-14 |
| 4. Sync live API reference | ✅ done | 2026-04-15 |
| 5. Sync DB reference | ✅ done | 2026-04-15 |
| 6. Documentation verification pass | ✅ done | 2026-04-15 |
| 7. Capture decisions in memory | ✅ done | 2026-04-15 |

**Outcome:** Feature doc `docs/features/achievements.md` published as NO CANON, registry row added, canonical refs (`ENDPOINTS-LIVE-REFERENCE.md` +16 endpoints, `SCHEMA-REFERENCE.md` +4 tables/3 enums) synced, engram topic `docs/achievements-documentation` saved. Three unresolved drift items propagated as explicit markers in the canonical docs (mobile response shape, admin PUT/PATCH + enums + multipart field, four events defined but not emitting).

---

**Goal:** Document `achievements/gamification` as a feature-first operational domain, without promoting it to canon, and only publish API/DB support that is backed by verified runtime.

**Architecture:** Start with a short runtime reconciliation pass because achievements exists in backend, app, admin, and DB, but the current live API reference omits the module and some clients show drift. Then write the feature doc as the primary artifact, update the feature registry, and only after that sync the subordinate API/DB references with explicitly verified surface.

**Tech Stack:** Markdown docs, NestJS controllers/services, Prisma schema, Next.js admin client, Flutter mobile client.

---

### Task 1: Audit achievements runtime before touching docs ✅ 2026-04-14

**Files:**
- Read: `sacdia-backend/src/achievements/achievements.controller.ts`
- Read: `sacdia-backend/src/achievements/admin/admin-achievements.controller.ts`
- Read: `sacdia-backend/src/achievements/achievements.service.ts`
- Read: `sacdia-backend/src/achievements/events/achievement-events.ts`
- Read: `sacdia-backend/src/classes/classes.service.ts`
- Read: `sacdia-backend/src/evidence-review/evidence-review.service.ts`
- Read: `sacdia-backend/src/investiture/investiture.service.ts`
- Read: `sacdia-backend/prisma/schema.prisma`
- Read: `sacdia-app/lib/features/achievements/data/datasources/achievements_remote_data_source.dart`
- Read: `sacdia-admin/src/lib/api/achievements.ts`
- Read: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- Read: `docs/database/SCHEMA-REFERENCE.md`

**Step 1: Build the verified runtime inventory**

- List the public user endpoints under `/api/v1/achievements`.
- List the admin endpoints under `/api/v1/admin/achievements`.
- List the Prisma models and enums that back the feature.
- List the event emitters that clearly feed achievements evaluation.

**Step 2: Mark drift and confidence level**

- Mark anything present in runtime but missing from `docs/api/ENDPOINTS-LIVE-REFERENCE.md`.
- Mark any client drift that should be mentioned as verification context, not copied into docs.
- Decide whether API/DB documentation can be updated in the same pass.

**Step 3: Verification checkpoint**

- Evidence required before continuing:
  - achievements runtime endpoints are enumerated from backend controllers
  - achievements DB structures are confirmed in Prisma
  - missing or drifting docs are explicitly listed

### Task 2: Draft the feature document as the primary artifact ✅ 2026-04-14

**Files:**
- Create: `docs/features/achievements.md`
- Read: `docs/features/infrastructure.md`
- Read: `docs/features/member-of-month.md`
- Read: `docs/achievements-seed-draft.md`
- Read: `docs/achievements-ui-redesign-spec.md`

**Step 1: Create the document frame**

- Add title, functional state, and a short note that this is a `NO CANON` operational feature.
- Add sections for description, verified runtime surface, data model, user/admin surfaces, emitted events, gaps, and next action.

**Step 2: Write only verified behavior**

- Describe user catalog/progress/detail flows from backend runtime.
- Describe admin CRUD and retroactive evaluation from admin runtime.
- Describe event-driven evaluation using only emitters verified in code.
- Describe app/admin consumers as implementation evidence, not source of truth.

**Step 3: Call out exclusions explicitly**

- Note that seed content and UI redesign spec are subordinate references.
- Note that anything not verified in runtime stays out or is labeled `Por verificar`.

**Step 4: Verification checkpoint**

- Re-read `docs/features/achievements.md` and confirm every API or DB claim can be traced to runtime or Prisma.

### Task 3: Register the new feature in the feature registry ✅ 2026-04-14

**Files:**
- Modify: `docs/features/README.md`
- Read: `docs/features/achievements.md`

**Step 1: Add achievements to the registry table**

- Add a new `achievements` row.
- Set coverage to document present.
- Set functional state to `NO CANON` if that is what the feature doc declares.

**Step 2: Update aggregate counts if needed**

- Recalculate document totals and functional state counts.
- Keep wording consistent with the existing registry format.

**Step 3: Verification checkpoint**

- Confirm the registry row links to `docs/features/achievements.md`.
- Confirm counts match the actual table contents.

### Task 4: Sync the live API reference only if runtime is fully reconcilable ✅ 2026-04-15

**Files:**
- Modify: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- Read: `sacdia-backend/src/achievements/achievements.controller.ts`
- Read: `sacdia-backend/src/achievements/admin/admin-achievements.controller.ts`

**Step 1: Add the missing achievements section**

- Document `/api/v1/achievements` user endpoints.
- Document `/api/v1/admin/achievements` admin endpoints.
- Include auth and permission notes only when they are visible in runtime decorators/guards.

**Step 2: Add concise contract notes**

- Mention secret achievement masking.
- Mention grouped catalog vs user progress summary shapes if verified.
- Mention file upload route details only from controller runtime.

**Step 3: Stop condition**

- If any endpoint contract is still ambiguous after Task 1, do not invent it.
- Instead add a minimal note in the plan execution log that API sync is deferred pending deeper runtime audit.

**Step 4: Verification checkpoint**

- Confirm every documented route exists in controller code.
- Confirm method, path, auth, and description align with decorators and code comments.

### Task 5: Sync the DB reference for achievements ✅ 2026-04-15

**Files:**
- Modify: `docs/database/SCHEMA-REFERENCE.md`
- Read: `sacdia-backend/prisma/schema.prisma`

**Step 1: Expand the achievements note if needed**

- Add concise notes for `achievement_categories`, `achievements`, `user_achievements`, and `achievement_event_log`.
- Mention enum names only if they are active in Prisma.

**Step 2: Keep the note human and structural**

- Focus on relationships, uniqueness, scope, progress tracking, and event log semantics.
- Do not restate all columns unless they clarify operational behavior.

**Step 3: Verification checkpoint**

- Confirm every table/model name and enum matches Prisma exactly.
- Confirm uniqueness and indexes mentioned are present in Prisma.

### Task 6: Run the documentation verification pass ✅ 2026-04-15

**Files:**
- Read: `docs/features/achievements.md`
- Read: `docs/features/README.md`
- Read: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- Read: `docs/database/SCHEMA-REFERENCE.md`
- Read: `docs/canon/source-of-truth.md`

**Step 1: Verify framing and authority**

- Confirm achievements remains feature documentation and was not promoted to canon.
- Confirm no `docs/canon/*` file was edited.
- Confirm the feature doc points to runtime and Prisma as operational authorities.

**Step 2: Verify internal consistency**

- Check that feature, API, and DB docs do not contradict one another.
- Check that any drift or unresolved point is labeled clearly.

**Step 3: Final verification checklist**

- `docs/features/achievements.md` exists and is feature-first
- `docs/features/README.md` registers the domain correctly
- `docs/api/ENDPOINTS-LIVE-REFERENCE.md` includes achievements only if verified
- `docs/database/SCHEMA-REFERENCE.md` reflects the achievements data model
- no canon files were modified
- no commits were created

### Task 7: Capture decisions and discoveries in memory ✅ 2026-04-15

**Files:**
- Evidence only: `docs/plans/2026-04-14-achievements-documentation-design.md`
- Evidence only: `docs/plans/2026-04-14-achievements-documentation-implementation-plan.md`

**Step 1: Save the documentary framing decision**

- Save that achievements is being documented feature-first and remains `NO CANON` for now.

**Step 2: Save the runtime audit discovery**

- Save that achievements has real runtime surface across backend/app/admin/DB, but the live API reference is currently missing the module and clients show drift that requires careful reconciliation.

**Step 3: Verification checkpoint**

- Confirm the memory entries mention the affected files and the reason for the chosen framing.
