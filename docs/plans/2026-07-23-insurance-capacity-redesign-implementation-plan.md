# Insurance Capacity Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the user-first insurance model with configurable products, section purchases, individual coverage slots, auditable transfers and assignments, event-scoped external participants, and proportional annual-ranking scoring for late purchases.

**Architecture:** Keep the external insurance platform as the payment and issuance authority. SACDIA records section purchase requests, lets only the Local Field confirm evidence, materializes one traceable slot per confirmed unit, and stores immutable movements and assignment history. Extend the existing annual-ranking component registry with `insurance_purchase_timeliness` instead of applying an ad-hoc final-score deduction.

**Tech Stack:** NestJS 11, Prisma 7, PostgreSQL, Cloudflare R2, Next.js 16, Flutter/Riverpod/Dio, Jest, Vitest, Flutter Test, REST `/api/v1`.

---

## Guardrails

- Do not run builds unless the user explicitly requests them.
- Do not modify unrelated dirty files in the workspace.
- Do not commit unless explicitly requested.
- If commits are authorized, use conventional commits without AI attribution.
- Use strict TDD for business rules and services.
- Keep `member_insurances` readable during migration.
- Do not expose private evidence URLs directly.
- Update canonical API, database, feature, and ranking docs with behavior changes.
- Admin visual composition remains a Cursor Composer work unit; backend contracts,
  permissions, states, and acceptance criteria are defined here first.

## Task 1: Introduce pure insurance domain policies

**Files:**

- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/insurance/domain/insurance-policy.ts`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/insurance/domain/insurance-policy.spec.ts`

**Step 1: Write failing tests**

Cover:

- receipt date equal to deadline is `ORDINARY`;
- receipt date after deadline is `EXTRAORDINARY`;
- `20` ordinary and `10` extraordinary returns `66.67`;
- zero confirmed quantity returns `0`;
- transfer is rejected when sections have different `main_club_id`;
- event validity uses exact event dates;
- fixed validity adds configured months without mutating input dates.

Representative test:

```typescript
describe('calculateInsuranceTimelinessScore', () => {
  it('scores ordinary quantity over total confirmed quantity', () => {
    expect(
      calculateInsuranceTimelinessScore({
        ordinaryQuantity: 20,
        extraordinaryQuantity: 10,
      }),
    ).toBe(66.67);
  });
});
```

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/insurance/domain/insurance-policy.spec.ts --runInBand
```

Expected: FAIL because the policy module does not exist.

**Step 2: Implement minimal pure functions**

Export:

```typescript
classifyInsurancePurchase(receiptDate, deadline)
calculateInsuranceTimelinessScore(input)
assertSameClubTransfer(source, destination)
resolveInsuranceValidity(config, event?)
```

Use date-only comparisons. Do not compare local timestamps for deadline
classification.

**Step 3: Re-run tests**

Expected: PASS.

**Suggested commit if authorized:** `feat(insurance): add coverage domain policies`

## Task 2: Add the capacity-oriented Prisma model

**Files:**

- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/prisma/schema.prisma`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/prisma/migrations/20260723120000_insurance_capacity_model/migration.sql`
- Modify: `/Users/abner/Documents/development/sacdia/docs/database/SCHEMA-REFERENCE.md`

**Step 1: Add enums**

Add enums for:

```text
insurance_coverage_scope_enum
insurance_validity_mode_enum
insurance_purchase_status_enum
insurance_purchase_classification_enum
insurance_slot_status_enum
insurance_slot_movement_type_enum
insurance_assignment_subject_enum
insurance_assignment_status_enum
insurance_evidence_type_enum
```

Use the values defined in the approved design.

**Step 2: Add models**

Add:

```text
insurance_products
insurance_cycle_configs
insurance_purchases
insurance_coverage_slots
insurance_slot_movements
insurance_assignments
insurance_evidence_files
camporee_external_participants
```

Required structural rules:

- immutable purchase provenance fields are non-null after confirmation;
- cycle config uniqueness is product + field + year + club type;
- slot sequence is unique inside a purchase;
- exactly one assignment subject is present;
- exactly one external participant event FK is present;
- exactly one evidence owner is present.

**Step 3: Add SQL-only constraints and indexes**

Prisma cannot express all invariants. Add migration SQL for:

```sql
CREATE UNIQUE INDEX uq_insurance_assignment_active_slot
ON insurance_assignments (insurance_coverage_slot_id)
WHERE status IN ('PENDING_CONFIRMATION', 'ACTIVE');
```

Add `CHECK` constraints for assignment subject, evidence owner, and local/union
camporee XOR rules.

Add query indexes:

```text
purchase: purchasing_section_id + receipt_date + status
slot: current_section_id + status
movement: slot_id + created_at
assignment: user_id + status + valid_until
external participant: event FK + active
```

**Step 4: Validate Prisma**

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec prisma validate
```

Expected: schema valid. Do not run a build.

**Step 5: Update schema reference**

Document ownership, custody, immutable ledger, subject XOR, and ranking
classification snapshot.

**Suggested commit if authorized:** `feat(db): add insurance purchase and slot model`

## Task 3: Implement product and cycle configuration

**Files:**

- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/insurance/insurance-config.service.ts`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/insurance/insurance-config.service.spec.ts`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/insurance/insurance-config.controller.ts`
- Create DTOs under: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/insurance/dto/config/`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/insurance/insurance.module.ts`

**Step 1: Write failing service tests**

Cover:

- create general product with `FIXED_MONTHS`;
- reject fixed product without positive duration;
- create event product with `EVENT_DATES`;
- reject event product with duration months;
- create cycle by field/year/club type;
- reject duplicate effective cycle;
- reject deadline outside ecclesiastical year unless explicitly allowed by canon;
- prevent changing deadline after the first confirmed purchase.

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/insurance/insurance-config.service.spec.ts --runInBand
```

Expected: FAIL.

**Step 2: Implement service and DTO validation**

Endpoints:

```text
GET/POST/PATCH /insurance/products
GET/POST/PATCH /insurance/cycles
```

Only Local Field actors with the new configuration permission may mutate these
resources. Scope validation must use the effective authorization profile, not
only a client-supplied `local_field_id`.

**Step 3: Re-run tests**

Expected: PASS.

**Suggested commit if authorized:** `feat(insurance): add product and cycle configuration`

## Task 4: Implement purchase submission and Local Field review

**Files:**

- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/insurance/insurance-purchases.service.ts`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/insurance/insurance-purchases.service.spec.ts`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/insurance/insurance-purchases.controller.ts`
- Create DTOs under: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/insurance/dto/purchases/`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/insurance/insurance.module.ts`

**Step 1: Write failing tests for submission**

Cover:

- section actor submits quantity, receipt date, external reference, and evidence;
- purchase uses section's actual main club and Local Field;
- mismatched cycle/section type is rejected;
- quantity and monetary values must be positive;
- submission creates no slots.

**Step 2: Write failing tests for confirmation**

Cover:

- only Local Field can confirm;
- confirmation compares external receipt date to deadline inclusively;
- confirmation snapshots deadline, unit cost, owner club, and payer section;
- confirmation creates exactly N numbered slots;
- purchase update and slot creation are atomic;
- repeated confirmation is idempotently rejected;
- rejection requires a reason and creates no slots;
- reversal voids only unassigned slots and preserves history.

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/insurance/insurance-purchases.service.spec.ts --runInBand
```

Expected: FAIL.

**Step 3: Implement endpoints**

```text
POST /club-sections/:sectionId/insurance/purchases
GET  /club-sections/:sectionId/insurance/purchases
GET  /insurance/purchases/:purchaseId
POST /insurance/purchases/:purchaseId/confirm
POST /insurance/purchases/:purchaseId/reject
POST /insurance/purchases/:purchaseId/reverse
```

Use one Prisma transaction to confirm and materialize slots.

**Step 4: Re-run tests**

Expected: PASS.

**Suggested commit if authorized:** `feat(insurance): add section purchase approval flow`

## Task 5: Secure insurance evidence in private R2

**Files:**

- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/insurance/insurance-evidence.service.ts`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/insurance/insurance-evidence.service.spec.ts`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/insurance/insurance-purchases.service.ts`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/insurance/insurance.service.ts`

**Step 1: Write failing tests**

Cover:

- allowed PDF/JPG/PNG/WEBP evidence uploads;
- invalid MIME and oversized files are rejected;
- DB stores object key and metadata, not a temporary signed URL;
- authorized reads return a short-lived signed URL;
- unauthorized territory cannot obtain the URL;
- legacy `evidence_file_url` is resolved safely during compatibility reads.

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/insurance/insurance-evidence.service.spec.ts --runInBand
```

Expected: FAIL.

**Step 2: Implement evidence ownership**

Use `StorageBucketAlias.INSURANCE_EVIDENCE`. Keep purchase proof and individual
receipt types distinct.

**Step 3: Re-run tests**

Expected: PASS.

**Suggested commit if authorized:** `fix(insurance): secure purchase and assignment evidence`

## Task 6: Implement balances, movements, and free-slot transfers

**Files:**

- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/insurance/insurance-slots.service.ts`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/insurance/insurance-slots.service.spec.ts`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/insurance/insurance-slots.controller.ts`
- Create DTOs under: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/insurance/dto/slots/`

**Step 1: Write failing balance tests**

Verify section totals:

```text
purchased
received
transferred_out
assigned
available
void
```

Totals must derive from slots and movements, not a stored editable counter.

**Step 2: Write failing transfer tests**

Cover:

- transfer only `AVAILABLE` slots;
- source and destination must share `main_club_id`;
- owner club and purchasing section remain unchanged;
- current section changes;
- each slot receives a movement;
- multi-slot transfer shares one correlation ID;
- insufficient free slots rejects the whole operation;
- concurrent transfer attempts cannot move the same slot twice.

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/insurance/insurance-slots.service.spec.ts --runInBand
```

Expected: FAIL.

**Step 3: Implement endpoints**

```text
GET  /club-sections/:sectionId/insurance/balance
GET  /club-sections/:sectionId/insurance/movements
POST /insurance/transfers
GET  /insurance/transfers/:correlationId
```

Transfer inside one transaction and insert immutable movement rows.

**Step 4: Re-run tests**

Expected: PASS.

**Suggested commit if authorized:** `feat(insurance): add auditable slot transfers`

## Task 7: Implement member assignment and receipt confirmation

**Files:**

- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/insurance/insurance-assignments.service.ts`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/insurance/insurance-assignments.service.spec.ts`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/insurance/insurance-assignments.controller.ts`
- Create DTOs under: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/insurance/dto/assignments/`

**Step 1: Write failing tests**

Cover:

- assignment can use only a free slot under the section's custody;
- annual member must have valid section relationship;
- submitting assignment requires individual receipt evidence;
- assignment remains pending until Local Field confirms;
- only Local Field activates or rejects;
- activation sets validity snapshot;
- one slot cannot have two pending/active assignments;
- user history returns active, expired, released, and rejected records.

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/insurance/insurance-assignments.service.spec.ts --runInBand
```

Expected: FAIL.

**Step 2: Implement endpoints**

```text
POST /insurance/slots/:slotId/assignments
POST /insurance/assignments/:assignmentId/confirm
POST /insurance/assignments/:assignmentId/reject
GET  /users/:userId/insurance-history
```

**Step 3: Re-run tests**

Expected: PASS.

**Suggested commit if authorized:** `feat(insurance): add confirmed member assignments`

## Task 8: Add event-scoped external participants

**Files:**

- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/camporees/camporee-external-participants.service.ts`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/camporees/camporee-external-participants.service.spec.ts`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/camporees/camporee-external-participants.controller.ts`
- Create DTOs under: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/camporees/dto/external-participants/`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/camporees/camporees.module.ts`

**Step 1: Write failing tests**

Cover:

- participant belongs to exactly one local or Union camporee;
- participant does not create a `users` record;
- role type and minimum identity fields are retained;
- duplicate-looking names in different events remain separate records;
- history remains available after event end;
- event insurance validity equals event start/end dates.

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/camporees/camporee-external-participants.service.spec.ts --runInBand
```

Expected: FAIL.

**Step 2: Implement local and Union routes**

Keep explicit routes for both existing event families. Do not overload a numeric
ID without event type.

**Step 3: Re-run tests**

Expected: PASS.

**Suggested commit if authorized:** `feat(camporees): track external insured personnel`

## Task 9: Implement extraordinary release and reassignment

**Files:**

- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/insurance/insurance-assignments.service.ts`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/insurance/insurance-assignments.service.spec.ts`
- Add DTO: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/insurance/dto/assignments/release-insurance-assignment.dto.ts`

**Step 1: Write failing tests**

Cover:

- only Local Field can release an active assignment;
- reason is mandatory;
- allowed reasons include non-attendance and permanent departure;
- previous assignment becomes `RELEASED`;
- slot becomes `AVAILABLE`;
- new assignment requires a new receipt;
- old receipt and assignment remain unchanged;
- actor and movement are recorded.

**Step 2: Implement**

Endpoint:

```text
POST /insurance/assignments/:assignmentId/release
```

Do not create an endpoint that mutates the old assignment's subject.

**Step 3: Run targeted assignment tests**

Expected: PASS.

**Suggested commit if authorized:** `feat(insurance): add exceptional reassignment audit flow`

## Task 10: Add the annual-ranking insurance component

**Files:**

- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/rankings/annual-ranking-progress/ranking-component-catalog.ts`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/rankings/annual-ranking-progress/ranking-component-catalog.spec.ts`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/rankings/annual-ranking-progress/services/insurance-purchase-timeliness-score.service.ts`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/rankings/annual-ranking-progress/services/insurance-purchase-timeliness-score.service.spec.ts`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/rankings/annual-ranking-progress/services/annual-ranking-score-registry.service.ts`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/rankings/annual-ranking-progress/services/annual-ranking-score-registry.service.spec.ts`

**Step 1: Write failing catalog tests**

Assert:

```text
insurance_purchase_timeliness → administrative
```

**Step 2: Write failing calculator tests**

Cover:

- aggregate confirmed purchases only;
- aggregate by purchasing section, never current slot section;
- exclude rejected, reversed, and `LEGACY_UNCLASSIFIED`;
- `20/30` returns `66.67`;
- all ordinary returns `100`;
- all extraordinary returns `0`;
- no confirmed purchases returns `0`;
- transfers have no effect.

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest \
  src/rankings/annual-ranking-progress/ranking-component-catalog.spec.ts \
  src/rankings/annual-ranking-progress/services/insurance-purchase-timeliness-score.service.spec.ts \
  src/rankings/annual-ranking-progress/services/annual-ranking-score-registry.service.spec.ts \
  --runInBand
```

Expected: FAIL.

**Step 3: Implement calculator and registry binding**

Return:

```typescript
{
  score_pct,
  source_status: 'available',
  source: 'insurance_purchases',
}
```

Let the existing ranking service convert percentage to configured points.

**Step 4: Re-run tests**

Expected: PASS.

**Suggested commit if authorized:** `feat(rankings): score insurance purchase timeliness`

## Task 11: Adapt camporee registration and legacy insurance reads

**Files:**

- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/camporees/dto/register-member.dto.ts`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/camporees/camporees.service.ts`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/camporees/camporees.service.spec.ts`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/insurance/insurance.service.ts`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/insurance/insurance.service.spec.ts`

**Step 1: Write failing compatibility tests**

Cover:

- member camporee registration accepts a confirmed active assignment;
- assignment belongs to the member;
- event/general product eligibility is configurable;
- assignment validity covers the complete event;
- released or expired assignment is rejected;
- legacy `insurance_id` remains temporarily accepted behind a documented
  compatibility path;
- new writes never create `member_insurances`.

**Step 2: Implement additive contract**

Add `insurance_assignment_id` without removing `insurance_id` in the first
release. Prefer the new field when both appear; reject conflicting subjects.

**Step 3: Re-run camporee and insurance tests**

Expected: PASS.

**Suggested commit if authorized:** `refactor(insurance): migrate camporees to coverage assignments`

## Task 12: Create legacy audit and import tooling

**Files:**

- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/scripts/audit-legacy-member-insurances.ts`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/scripts/import-legacy-member-insurances.ts`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/scripts/import-legacy-member-insurances.spec.ts`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/package.json`

**Step 1: Write failing importer tests**

Classify legacy rows:

```text
RESOLVABLE
AMBIGUOUS_SECTION
MISSING_EVIDENCE
INVALID_DATES
ALREADY_IMPORTED
```

**Step 2: Implement dry-run first**

Default command must not write:

```bash
pnpm exec tsx scripts/audit-legacy-member-insurances.ts
```

Import requires an explicit write flag and idempotency key. Imported purchases
use `LEGACY_UNCLASSIFIED` and never affect timeliness ranking.

**Step 3: Run unit tests only**

Do not execute the importer against a real database without separate approval.

**Suggested commit if authorized:** `feat(insurance): add legacy audit and import tools`

## Task 13: Prepare and implement the admin contract handoff

**Files:**

- Create: `/Users/abner/Documents/development/sacdia/docs/plans/2026-07-23-insurance-admin-handoff.md`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-admin/src/lib/api/insurance.ts`
- Add tests under: `/Users/abner/Documents/development/sacdia/sacdia-admin/src/components/insurance/`
- Modify pages/components under:
  `/Users/abner/Documents/development/sacdia/sacdia-admin/src/app/(dashboard)/dashboard/insurance/`
  and `/Users/abner/Documents/development/sacdia/sacdia-admin/src/components/insurance/`

**Step 1: Write the contract-first handoff**

Include:

- endpoints and DTOs;
- permission matrix;
- state machines;
- loading/empty/error/success states;
- purchase inbox;
- section ledger;
- balance and transfer UI;
- assignment confirmation;
- extraordinary reassignment warning;
- external event personnel history;
- ranking breakdown.

**Step 2: Add failing API/client tests**

Cover response normalization and mutation payloads before UI work.

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-admin
pnpm test -- src/components/insurance
```

Expected: FAIL before implementation.

**Step 3: Implement through the admin ownership workflow**

Cursor Composer owns layout and visual polish. Codex verifies contracts, auth,
permissions, types, and integration.

**Step 4: Run targeted tests and design audit**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-admin
pnpm test -- src/components/insurance
pnpm audit:design-system --strict
```

Do not run `pnpm build`.

**Suggested commit if authorized:** `feat(admin): add insurance purchase and slot management`

## Task 14: Adapt the mobile insurance feature

**Files:**

- Modify domain/data/presentation files under:
  `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/insurance/`
- Add tests under:
  `/Users/abner/Documents/development/sacdia/sacdia-app/test/features/insurance/`

**Step 1: Write failing model and provider tests**

Cover:

- parse active assignment and history;
- distinguish purchased, transferred, assigned, and available quantities;
- use signed receipt URL;
- show pending Local Field confirmation;
- derive expiring insurance without including already expired records;
- camporee registration sends `insurance_assignment_id`.

**Step 2: Implement repository and UI adaptation**

Keep confirmation/rejection actions out of mobile unless a Local Field role and
explicit product decision later require them.

**Step 3: Run targeted tests**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app
flutter test test/features/insurance
```

Expected: PASS. Do not run a Flutter build.

**Suggested commit if authorized:** `feat(app): consume insurance assignments and history`

## Task 15: Update canonical documentation

**Files:**

- Modify: `/Users/abner/Documents/development/sacdia/docs/features/gestion-seguros.md`
- Modify: `/Users/abner/Documents/development/sacdia/docs/features/camporees.md`
- Modify: `/Users/abner/Documents/development/sacdia/docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- Modify: `/Users/abner/Documents/development/sacdia/docs/api/FRONTEND-INTEGRATION-GUIDE.md`
- Modify: `/Users/abner/Documents/development/sacdia/docs/database/SCHEMA-REFERENCE.md`
- Modify: `/Users/abner/Documents/development/sacdia/docs/canon/runtime-rankings.md`
- Modify: `/Users/abner/Documents/development/sacdia/docs/canon/runtime-sacdia.md`
- Add ADR entry to: `/Users/abner/Documents/development/sacdia/docs/api/ARCHITECTURE-DECISIONS.md`

**Step 1: Document effective behavior**

Document:

- external platform remains authoritative;
- section purchase and Local Field confirmation;
- slot ownership versus custody;
- transfer and reassignment rules;
- event external participants;
- deadline snapshot and ranking formula;
- migration compatibility period.

**Step 2: Verify endpoint reference against controllers**

Use `rg` to compare route decorators and reference entries. Do not describe
planned endpoints as live until implemented.

**Suggested commit if authorized:** `docs(insurance): document capacity and ranking model`

## Task 16: Targeted verification and release gate

**Files:**

- No production file changes unless verification finds a defect.

**Step 1: Run backend targeted suites**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest \
  src/insurance \
  src/camporees/camporees.service.spec.ts \
  src/rankings/annual-ranking-progress \
  --runInBand
```

Expected: PASS.

**Step 2: Run admin targeted tests**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-admin
pnpm test -- src/components/insurance
pnpm audit:design-system --strict
```

Expected: PASS.

**Step 3: Run mobile targeted tests**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app
flutter test test/features/insurance
```

Expected: PASS.

**Step 4: Verify schema and diffs**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec prisma validate

cd /Users/abner/Documents/development/sacdia
git diff --check
```

Expected: both commands succeed.

**Step 5: Do not build**

No Nest, Next.js, Android, or iOS build is part of this verification unless the
user explicitly requests it later.

## Delivery order

Implement as reviewable work units:

1. domain policies + schema;
2. configuration + purchases + evidence;
3. slots + transfers;
4. assignments + external participants + reassignment;
5. ranking integration;
6. legacy compatibility/import;
7. admin handoff and integration;
8. mobile integration;
9. canonical docs and final verification.

Each unit must preserve a deployable compatibility boundary. Do not remove
`member_insurances` until all consumers use the new assignment contract and the
legacy audit is complete.
