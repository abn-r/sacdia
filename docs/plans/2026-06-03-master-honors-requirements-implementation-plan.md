# Master Honors Requirements Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build configurable master-honor requirements so SACDIA can automatically award, revoke, and display master honors based on approved honors.

**Architecture:** Implement master honors as a first-class honors subdomain, not as a generic achievement. Backend owns schema, evaluation, recalculation, history, and notifications; admin owns rule configuration; mobile owns band/history display and global foreground modal UX.

**Tech Stack:** NestJS 11 + Prisma 7 + PostgreSQL + BullMQ/notifications in `sacdia-backend`; Next.js 16 + TypeScript + shadcn/ui in `sacdia-admin`; Flutter + Riverpod + Firebase Messaging in `sacdia-app`.

---

## Execution Rules

- Do not run local builds. Use targeted tests, typecheck, lint/analyze only.
- Product copy must use neutral Spanish. Do not use voseo or regional modisms.
- Use conventional commits. Do not add `Co-Authored-By` or AI attribution.
- Work in reviewable slices. Keep unrelated dirty files out of commits.
- If implementation uses agents, use `gpt-5.3-codex` subagents and review their work before committing.
- Source design: `/Users/abner/Documents/development/sacdia/docs/plans/2026-06-03-master-honors-requirements-design.md`.

## Recommended PR Slices

1. Backend schema + generated client + documented API contract.
2. Backend evaluator + hooks + recalculation + notifications.
3. Admin rule editor.
4. Mobile API/models/display/modal.
5. Initial official rule data import/backfill after the real official requirement list is available.

---

## Task 1: Backend schema and enums

**Files:**
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/prisma/schema.prisma`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/prisma/migrations/YYYYMMDDHHMMSS_master_honor_requirements/migration.sql`
- Modify: `/Users/abner/Documents/development/sacdia/docs/database/schema.prisma`
- Modify: `/Users/abner/Documents/development/sacdia/docs/database/SCHEMA-REFERENCE.md`

**Step 1: Add Prisma models and enums**

Add enums:

```prisma
enum master_honor_applicability_scope_enum {
  ALL
  SELECTED_DIVISIONS
}

enum master_honor_requirement_group_type_enum {
  EXPLICIT_OPTIONS
  CATEGORY_COUNT
}

enum user_master_honor_status_enum {
  AWARDED
  REVOKED
  RETIRED
}

enum user_master_honor_source_enum {
  AUTO
}

enum user_master_honor_status_reason_enum {
  CRITERIA_CHANGED
  USER_NO_LONGER_QUALIFIES
  MASTER_HONOR_INACTIVE
  RECOVERED
}
```

Extend `master_honors`:

```prisma
  applicability_scope master_honor_applicability_scope_enum @default(ALL)
  philosophy          String?
  notes               String?
```

Create models:

```prisma
model master_honor_divisions {
  master_honor_division_id Int      @id @default(autoincrement())
  master_honor_id          Int
  division_id              Int
  active                   Boolean  @default(true)
  created_at               DateTime @default(now()) @db.Timestamptz(6)
  modified_at              DateTime @default(now()) @db.Timestamptz(6)

  master_honor master_honors @relation(fields: [master_honor_id], references: [master_honor_id], onDelete: Cascade, onUpdate: Cascade)
  division     divisions     @relation(fields: [division_id], references: [division_id], onDelete: NoAction, onUpdate: NoAction)

  @@unique([master_honor_id, division_id])
  @@index([division_id])
}

model master_honor_requirement_groups {
  group_id           Int       @id @default(autoincrement())
  master_honor_id    Int
  group_type         master_honor_requirement_group_type_enum
  title              String?   @db.VarChar(200)
  description        String?
  minimum_required   Int
  honors_category_id Int?
  display_order      Int       @default(0)
  active             Boolean   @default(true)
  created_at         DateTime  @default(now()) @db.Timestamptz(6)
  modified_at        DateTime  @default(now()) @db.Timestamptz(6)

  master_honor   master_honors      @relation(fields: [master_honor_id], references: [master_honor_id], onDelete: Cascade, onUpdate: Cascade)
  honor_category honors_categories? @relation(fields: [honors_category_id], references: [honor_category_id], onDelete: NoAction, onUpdate: NoAction)
  options        master_honor_requirement_options[]

  @@index([master_honor_id])
  @@index([honors_category_id])
}

model master_honor_requirement_options {
  option_id     Int      @id @default(autoincrement())
  group_id      Int
  label         String   @db.VarChar(200)
  display_order Int      @default(0)
  active        Boolean  @default(true)
  created_at    DateTime @default(now()) @db.Timestamptz(6)
  modified_at   DateTime @default(now()) @db.Timestamptz(6)

  group  master_honor_requirement_groups         @relation(fields: [group_id], references: [group_id], onDelete: Cascade, onUpdate: Cascade)
  honors master_honor_requirement_option_honors[]

  @@index([group_id])
}

model master_honor_requirement_option_honors {
  option_honor_id Int      @id @default(autoincrement())
  option_id       Int
  honor_id        Int
  active          Boolean  @default(true)
  created_at      DateTime @default(now()) @db.Timestamptz(6)
  modified_at     DateTime @default(now()) @db.Timestamptz(6)

  option master_honor_requirement_options @relation(fields: [option_id], references: [option_id], onDelete: Cascade, onUpdate: Cascade)
  honor  honors                           @relation(fields: [honor_id], references: [honor_id], onDelete: NoAction, onUpdate: NoAction)

  @@unique([option_id, honor_id])
  @@index([honor_id])
}

model users_master_honors {
  user_master_honor_id Int                                  @id @default(autoincrement())
  user_id              String                               @db.Uuid
  master_honor_id      Int
  status               user_master_honor_status_enum
  awarded_at           DateTime?                            @db.Timestamptz(6)
  revoked_at           DateTime?                            @db.Timestamptz(6)
  recovered_at         DateTime?                            @db.Timestamptz(6)
  evaluated_at         DateTime                             @default(now()) @db.Timestamptz(6)
  awarded_division_id  Int?
  source               user_master_honor_source_enum        @default(AUTO)
  status_reason        user_master_honor_status_reason_enum?
  evaluation_snapshot  Json
  active               Boolean                              @default(true)
  created_at           DateTime                             @default(now()) @db.Timestamptz(6)
  modified_at          DateTime                             @default(now()) @db.Timestamptz(6)

  user             users          @relation(fields: [user_id], references: [user_id], onDelete: NoAction, onUpdate: NoAction)
  master_honor     master_honors  @relation(fields: [master_honor_id], references: [master_honor_id], onDelete: NoAction, onUpdate: NoAction)
  awarded_division divisions?     @relation(fields: [awarded_division_id], references: [division_id], onDelete: NoAction, onUpdate: NoAction)
  history          master_honor_evaluation_history[]

  @@unique([user_id, master_honor_id])
  @@index([user_id, status])
  @@index([master_honor_id, status])
}

model master_honor_evaluation_history {
  history_id           Int                                  @id @default(autoincrement())
  user_master_honor_id Int
  user_id              String                               @db.Uuid
  master_honor_id      Int
  from_status          user_master_honor_status_enum?
  to_status            user_master_honor_status_enum
  reason               user_master_honor_status_reason_enum?
  evaluation_snapshot  Json
  created_at           DateTime                             @default(now()) @db.Timestamptz(6)
  created_by_job_id    String?                              @db.VarChar(100)

  user_master_honor users_master_honors @relation(fields: [user_master_honor_id], references: [user_master_honor_id], onDelete: Cascade, onUpdate: Cascade)
  user              users               @relation(fields: [user_id], references: [user_id], onDelete: NoAction, onUpdate: NoAction)
  master_honor      master_honors       @relation(fields: [master_honor_id], references: [master_honor_id], onDelete: NoAction, onUpdate: NoAction)

  @@index([user_id, created_at])
  @@index([master_honor_id, created_at])
}
```

Also add relation arrays to existing `users`, `master_honors`, `honors`, `honors_categories`, and `divisions` models as required by Prisma.

**Step 2: Write migration SQL**

Run only migration generation if allowed by project workflow, or manually write SQL equivalent. Do not run build.

Expected SQL includes:

```sql
CREATE TYPE "master_honor_applicability_scope_enum" AS ENUM ('ALL', 'SELECTED_DIVISIONS');
CREATE TYPE "master_honor_requirement_group_type_enum" AS ENUM ('EXPLICIT_OPTIONS', 'CATEGORY_COUNT');
CREATE TYPE "user_master_honor_status_enum" AS ENUM ('AWARDED', 'REVOKED', 'RETIRED');
CREATE TYPE "user_master_honor_source_enum" AS ENUM ('AUTO');
CREATE TYPE "user_master_honor_status_reason_enum" AS ENUM ('CRITERIA_CHANGED', 'USER_NO_LONGER_QUALIFIES', 'MASTER_HONOR_INACTIVE', 'RECOVERED');
```

Then create the six tables above with FKs and indexes.

**Step 3: Generate Prisma client**

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec prisma generate
```

Expected: Prisma client generated successfully.

**Step 4: Verify TypeScript compile for schema references only**

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec tsc -p tsconfig.build.json --noEmit --pretty false
```

Expected: PASS. If unrelated errors appear, document them and do not fix unrelated areas in this task.

**Step 5: Commit**

```bash
git add prisma/schema.prisma prisma/migrations/YYYYMMDDHHMMSS_master_honor_requirements/migration.sql ../docs/database/schema.prisma ../docs/database/SCHEMA-REFERENCE.md
git commit -m "feat(master-honors): add requirements schema"
```

---

## Task 2: Backend DTOs and admin API contract

**Files:**
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/admin/dto/phase-e-catalogs.dto.ts`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/admin/admin-phase-e-catalogs.controller.ts`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/admin/admin-phase-e-catalogs.service.ts`
- Test: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/admin/admin-phase-e-catalogs.service.spec.ts`
- Modify: `/Users/abner/Documents/development/sacdia/docs/api/ENDPOINTS-LIVE-REFERENCE.md`

**Step 1: Write failing DTO/service tests**

Add tests proving:

- create/update master honor accepts `philosophy`, `notes`, `applicability_scope`;
- `SELECTED_DIVISIONS` requires at least one `division_id`;
- `ALL` clears selected divisions;
- rule groups validate `minimum_required >= 1`;
- explicit groups require options;
- category groups require `honors_category_id` and no options.

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/admin/admin-phase-e-catalogs.service.spec.ts --runInBand
```

Expected: FAIL before implementation.

**Step 2: Add DTO types**

Add DTOs similar to:

```ts
export class MasterHonorRuleOptionDto {
  @IsOptional()
  @IsInt()
  option_id?: number;

  @IsString()
  @MaxLength(200)
  label!: string;

  @IsInt()
  @Min(0)
  display_order = 0;

  @IsArray()
  @ArrayMinSize(1)
  @IsInt({ each: true })
  honor_ids!: number[];

  @IsOptional()
  @IsBoolean()
  active?: boolean;
}

export class MasterHonorRequirementGroupDto {
  @IsOptional()
  @IsInt()
  group_id?: number;

  @IsEnum(master_honor_requirement_group_type_enum)
  group_type!: master_honor_requirement_group_type_enum;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  title?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsInt()
  @Min(1)
  minimum_required!: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  honors_category_id?: number;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => MasterHonorRuleOptionDto)
  options: MasterHonorRuleOptionDto[] = [];
}
```

Extend `CreateMasterHonorDto` and `UpdateMasterHonorDto` with:

```ts
applicability_scope?: 'ALL' | 'SELECTED_DIVISIONS';
philosophy?: string | null;
notes?: string | null;
division_ids?: number[];
requirement_groups?: MasterHonorRequirementGroupDto[];
```

**Step 3: Implement admin service persistence**

In `AdminPhaseECatalogsService`:

- include divisions and groups/options/honors in `findAllMasterHonors`;
- create/update master honor in a transaction;
- soft-delete or replace existing groups/options on update;
- upsert division applicability;
- validate all referenced `division_id`, `honors_category_id`, and `honor_id` exist;
- log mutation.

**Step 4: Add API endpoints for rule preview/recalculation trigger**

Add:

```ts
@Post('master-honors/:id/recalculate')
@RequirePermissions('honors:update')
async recalculateMasterHonor(@Param('id', ParseIntPipe) id: number) { ... }
```

For this task, it may enqueue a placeholder service method implemented in Task 5.

**Step 5: Run tests**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/admin/admin-phase-e-catalogs.service.spec.ts --runInBand
pnpm exec tsc -p tsconfig.build.json --noEmit --pretty false
```

Expected: PASS.

**Step 6: Commit**

```bash
git add src/admin/dto/phase-e-catalogs.dto.ts src/admin/admin-phase-e-catalogs.controller.ts src/admin/admin-phase-e-catalogs.service.ts src/admin/admin-phase-e-catalogs.service.spec.ts ../docs/api/ENDPOINTS-LIVE-REFERENCE.md
git commit -m "feat(master-honors): expose configurable rules api"
```

---

## Task 3: Backend evaluator core

**Files:**
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/honors/master-honors-evaluator.service.ts`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/honors/master-honors-evaluator.service.spec.ts`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/honors/honors.module.ts`

**Step 1: Write failing evaluator tests**

Test cases:

1. awards from explicit list when 7 options are satisfied;
2. counts base/advanced equivalence as one option;
3. awards from category count when 7 approved honors exist in category;
4. requires all groups;
5. stores active-club division on first award;
6. does not revoke due to later club division change;
7. revokes when criteria no longer match;
8. marks `RETIRED` when master honor is inactive;
9. writes evaluation history.

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/honors/master-honors-evaluator.service.spec.ts --runInBand
```

Expected: FAIL because service does not exist.

**Step 2: Implement evaluator types**

Create local types:

```ts
export type MasterHonorTransition = 'NONE' | 'AWARDED' | 'RECOVERED' | 'REVOKED' | 'RETIRED';

export interface MasterHonorEvaluationSnapshot {
  master_honor_id: number;
  master_honor_name: string;
  evaluated_at: string;
  awarded_division_id: number | null;
  groups: Array<{
    group_id: number;
    group_type: 'EXPLICIT_OPTIONS' | 'CATEGORY_COUNT';
    minimum_required: number;
    current_count: number;
    passed: boolean;
    matched_honor_ids: number[];
    matched_options?: Array<{ option_id: number; label: string; matched_honor_ids: number[] }>;
  }>;
}
```

**Step 3: Implement public methods**

```ts
async evaluateUser(userId: string, opts?: { masterHonorId?: number; jobId?: string }): Promise<MasterHonorEvaluationResult[]>;
async evaluateUserForMasterHonor(userId: string, masterHonorId: number, opts?: { jobId?: string }): Promise<MasterHonorEvaluationResult>;
```

Rules:

- approved honors query filters `users_honors.active = true` and `validation_status = APPROVED`;
- first award resolves division from active club context;
- existing record uses `awarded_division_id` for applicability;
- explicit option counts once if any `honor_id` in the option is approved;
- category group counts distinct approved honors in that category;
- all active groups must pass;
- inactive master honor means `RETIRED` for existing awarded/revoked records;
- no record is created for never-awarded and not-qualified users.

**Step 4: Implement persistence**

Use a transaction to:

- create/update `users_master_honors`;
- create `master_honor_evaluation_history` only when status changes;
- keep `evaluation_snapshot` current even when status stays the same.

**Step 5: Run tests**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/honors/master-honors-evaluator.service.spec.ts --runInBand
pnpm exec tsc -p tsconfig.build.json --noEmit --pretty false
```

Expected: PASS.

**Step 6: Commit**

```bash
git add src/honors/master-honors-evaluator.service.ts src/honors/master-honors-evaluator.service.spec.ts src/honors/honors.module.ts
git commit -m "feat(master-honors): evaluate automatic eligibility"
```

---

## Task 4: Backend hooks after honor validation

**Files:**
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/honors/honor-validation-workflow.service.ts`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/honors/honor-validation-workflow.service.spec.ts`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/honors/honors.module.ts`

**Step 1: Write failing tests**

Add tests verifying:

- approving an honor calls `MasterHonorsEvaluatorService.evaluateUser(userId)`;
- rejection or status reversal also calls evaluator;
- evaluator errors are logged but do not fail honor validation response.

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/honors/honor-validation-workflow.service.spec.ts --runInBand
```

Expected: FAIL before hook.

**Step 2: Inject evaluator**

Inject `MasterHonorsEvaluatorService` into `HonorValidationWorkflowService`.

**Step 3: Call evaluator after status-changing transitions**

After `APPROVED`, `REJECTED`, or reset to `IN_PROGRESS`, call:

```ts
await this.masterHonorsEvaluator.evaluateUser(record.user_id).catch((error) => {
  this.logger.warn(`Failed to evaluate master honors: ${(error as Error).message}`);
});
```

**Step 4: Run tests**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/honors/honor-validation-workflow.service.spec.ts src/honors/master-honors-evaluator.service.spec.ts --runInBand
```

Expected: PASS.

**Step 5: Commit**

```bash
git add src/honors/honor-validation-workflow.service.ts src/honors/honor-validation-workflow.service.spec.ts src/honors/honors.module.ts
git commit -m "feat(master-honors): recalculate after honor validation"
```

---

## Task 5: Backend recalculation jobs and notifications

**Files:**
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/honors/master-honors-recalculation.processor.ts`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/honors/master-honors-recalculation.processor.spec.ts`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/honors/master-honors-evaluator.service.ts`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/honors/master-honors-evaluator.service.spec.ts`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/honors/honors.module.ts`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/notifications/notification-source-map.constants.ts`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/notifications/notification-source-map.spec.ts`
- Modify: `/Users/abner/Documents/development/sacdia/docs/api/ENDPOINTS-LIVE-REFERENCE.md`

**Step 1: Write failing notification tests**

Assert evaluator emits notification transitions with payloads:

```ts
{
  type: 'master_honor_changed',
  transition: 'awarded' | 'recovered' | 'not_current',
  master_honor_ids: '1,2',
  master_honor_names: 'Maestría en Acuática|Maestría en Artesanía'
}
```

Sources:

```text
master_honors:awarded
master_honors:recovered
master_honors:not_current
```

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/honors/master-honors-evaluator.service.spec.ts src/notifications/notification-source-map.spec.ts --runInBand
```

Expected: FAIL.

**Step 2: Map notification sources**

Add to `NOTIFICATION_SOURCE_MAP`:

```ts
'master_honors:awarded': 'achievements',
'master_honors:recovered': 'achievements',
'master_honors:not_current': 'achievements',
```

Rationale: user-facing category can remain “achievements/logros” unless product later adds a separate “maestrías” preference category.

**Step 3: Implement notification copy**

Neutral Spanish:

```text
¡Nueva maestría obtenida!
Has obtenido la maestría {nombre}.

Maestría vigente nuevamente
La maestría {nombre} vuelve a estar vigente en tu perfil.

Maestría marcada como No vigente
Las validaciones requeridas para la maestría {nombre} cambiaron. Actualmente no cumples con los requisitos, por lo que quedó marcada como No vigente.
```

For multiple names, use plural title and list names in payload; mobile modal will render the list.

**Step 4: Implement BullMQ processor**

Queue name suggestion: `master-honors`.

Processor job types:

```ts
type MasterHonorJob =
  | { kind: 'user'; userId: string; masterHonorId?: number }
  | { kind: 'master-honor'; masterHonorId: number }
  | { kind: 'all' };
```

Rules:

- admin rule edits enqueue `{ kind: 'master-honor', masterHonorId }`;
- processor finds affected users with approved honors and existing `users_master_honors` rows;
- process in batches.

**Step 5: Wire admin recalculate endpoint**

`POST /api/v1/admin/master-honors/:id/recalculate` enqueues a job and returns:

```json
{ "status": "success", "data": { "queued": true } }
```

**Step 6: Run tests**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/honors/master-honors-evaluator.service.spec.ts src/honors/master-honors-recalculation.processor.spec.ts src/notifications/notification-source-map.spec.ts --runInBand
pnpm exec tsc -p tsconfig.build.json --noEmit --pretty false
```

Expected: PASS.

**Step 7: Commit**

```bash
git add src/honors src/notifications/notification-source-map.constants.ts src/notifications/notification-source-map.spec.ts ../docs/api/ENDPOINTS-LIVE-REFERENCE.md
git commit -m "feat(master-honors): notify and recalculate status changes"
```

---

## Task 6: Backend read APIs for app/profile/band

**Files:**
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/honors/dto/master-honors.dto.ts`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/honors/dto/index.ts`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/honors/master-honors.controller.ts`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/honors/master-honors.service.ts`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/honors/master-honors.service.spec.ts`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/honors/honors.module.ts`
- Modify: `/Users/abner/Documents/development/sacdia/docs/api/ENDPOINTS-LIVE-REFERENCE.md`

**Step 1: Write failing service tests**

Cases:

- list user master honors returns `AWARDED`, `REVOKED`, `RETIRED`;
- response includes `is_current` false for revoked/retired;
- response includes `display_status_label = "No vigente"` for non-current;
- includes `evaluation_snapshot` for detail only, not compact list unless requested.

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/honors/master-honors.service.spec.ts --runInBand
```

Expected: FAIL.

**Step 2: Add endpoints**

```text
GET /api/v1/users/:userId/master-honors
GET /api/v1/users/:userId/master-honors/:masterHonorId
```

Guard with same ownership/admin pattern used by honors endpoints.

**Step 3: Implement response DTO**

```ts
export class UserMasterHonorDto {
  user_master_honor_id!: number;
  master_honor_id!: number;
  name!: string;
  master_image?: string | null;
  status!: 'AWARDED' | 'REVOKED' | 'RETIRED';
  is_current!: boolean;
  display_status_label!: 'Vigente' | 'No vigente';
  awarded_at?: string | null;
  revoked_at?: string | null;
  recovered_at?: string | null;
  status_reason?: string | null;
}
```

**Step 4: Run tests**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/honors/master-honors.service.spec.ts --runInBand
pnpm exec tsc -p tsconfig.build.json --noEmit --pretty false
```

Expected: PASS.

**Step 5: Commit**

```bash
git add src/honors/master-honors.controller.ts src/honors/master-honors.service.ts src/honors/master-honors.service.spec.ts src/honors/dto/master-honors.dto.ts src/honors/dto/index.ts src/honors/honors.module.ts ../docs/api/ENDPOINTS-LIVE-REFERENCE.md
git commit -m "feat(master-honors): expose user master honors"
```

---

## Task 7: Admin API client and rule editor shell

**Files:**
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-admin/src/lib/api/phase-e-catalogs.ts`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-admin/src/lib/phase-e-catalogs/actions.ts`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-admin/src/components/catalogs/master-honor-rules-editor.tsx`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-admin/src/components/catalogs/master-honor-rules-editor.test.tsx`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-admin/src/components/catalogs/phase-e-catalog-crud-page.tsx`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-admin/messages/es.json`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-admin/messages/en.json`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-admin/messages/fr.json`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-admin/messages/pt-BR.json`

**Step 1: Write failing component tests**

Test:

- renders philosophy/notes fields;
- switches applicability between all divisions and selected divisions;
- adds explicit group;
- adds option with multiple equivalent honors;
- validates minimum cannot exceed option count for explicit group;
- renders category-count group.

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-admin
pnpm exec jest src/components/catalogs/master-honor-rules-editor.test.tsx --runInBand
```

Expected: FAIL.

**Step 2: Extend API types**

Add:

```ts
export type MasterHonorRuleGroupType = 'EXPLICIT_OPTIONS' | 'CATEGORY_COUNT';
export type MasterHonorApplicabilityScope = 'ALL' | 'SELECTED_DIVISIONS';

export type MasterHonorRuleOptionPayload = {
  option_id?: number;
  label: string;
  display_order: number;
  honor_ids: number[];
  active?: boolean;
};

export type MasterHonorRuleGroupPayload = {
  group_id?: number;
  group_type: MasterHonorRuleGroupType;
  title?: string | null;
  description?: string | null;
  minimum_required: number;
  honors_category_id?: number | null;
  display_order: number;
  options: MasterHonorRuleOptionPayload[];
  active?: boolean;
};
```

Extend master honor payload with `philosophy`, `notes`, `applicability_scope`, `division_ids`, `requirement_groups`.

**Step 3: Implement editor component**

Requirements:

- one section for basic rule metadata;
- one section for applicability;
- repeatable groups;
- repeatable options;
- multi-select honors per option;
- select category for category-count groups;
- neutral Spanish labels.

**Step 4: Integrate into master honors catalog page**

Add special rendering when entity is `master-honors`. If existing `PhaseECatalogCrudPage` becomes too generic, keep changes minimal and delegate special editor via prop.

**Step 5: Run tests and typecheck**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-admin
pnpm exec jest src/components/catalogs/master-honor-rules-editor.test.tsx --runInBand
pnpm exec tsc --noEmit
```

Expected: PASS.

**Step 6: Commit**

```bash
git add src/lib/api/phase-e-catalogs.ts src/lib/phase-e-catalogs/actions.ts src/components/catalogs/master-honor-rules-editor.tsx src/components/catalogs/master-honor-rules-editor.test.tsx src/components/catalogs/phase-e-catalog-crud-page.tsx messages/es.json messages/en.json messages/fr.json messages/pt-BR.json
git commit -m "feat(master-honors): add admin rule editor"
```

---

## Task 8: Admin recalculation UX

**Files:**
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-admin/src/lib/api/phase-e-catalogs.ts`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-admin/src/lib/phase-e-catalogs/actions.ts`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-admin/src/components/catalogs/master-honor-rules-editor.tsx`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-admin/src/components/catalogs/master-honor-rules-editor.test.tsx`

**Step 1: Write failing tests**

Test:

- after saving rule changes, UI shows recalculation warning;
- manual “Recalcular ahora” button calls `/admin/master-honors/:id/recalculate`;
- only users with edit permissions see recalculation action.

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-admin
pnpm exec jest src/components/catalogs/master-honor-rules-editor.test.tsx --runInBand
```

Expected: FAIL.

**Step 2: Add API action**

```ts
export async function recalculateMasterHonor(id: number) {
  return apiRequest(`/admin/master-honors/${id}/recalculate`, { method: 'POST' });
}
```

**Step 3: Add UI warning**

Neutral Spanish:

```text
Cambiar estos requisitos puede otorgar o marcar como No vigente maestrías de usuarios existentes. El recálculo se ejecutará automáticamente.
```

**Step 4: Run tests**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-admin
pnpm exec jest src/components/catalogs/master-honor-rules-editor.test.tsx --runInBand
pnpm exec tsc --noEmit
```

Expected: PASS.

**Step 5: Commit**

```bash
git add src/lib/api/phase-e-catalogs.ts src/lib/phase-e-catalogs/actions.ts src/components/catalogs/master-honor-rules-editor.tsx src/components/catalogs/master-honor-rules-editor.test.tsx
git commit -m "feat(master-honors): surface recalculation controls"
```

---

## Task 9: Mobile data/domain layer for master honors

**Files:**
- Create: `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/master_honors/domain/entities/user_master_honor.dart`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/master_honors/data/models/user_master_honor_model.dart`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/master_honors/domain/repositories/master_honors_repository.dart`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/master_honors/data/datasources/master_honors_remote_data_source.dart`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/master_honors/data/repositories/master_honors_repository_impl.dart`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/master_honors/presentation/providers/master_honors_providers.dart`
- Test: `/Users/abner/Documents/development/sacdia/sacdia-app/test/features/master_honors/data/datasources/master_honors_remote_data_source_test.dart`
- Test: `/Users/abner/Documents/development/sacdia/sacdia-app/test/features/master_honors/data/models/user_master_honor_model_test.dart`

**Step 1: Write failing model and datasource tests**

Test parsing:

```json
{
  "user_master_honor_id": 10,
  "master_honor_id": 2,
  "name": "Maestría en Acuática",
  "master_image": "https://example.com/a.png",
  "status": "REVOKED",
  "is_current": false,
  "display_status_label": "No vigente",
  "awarded_at": "2026-06-03T10:00:00Z"
}
```

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app
flutter test test/features/master_honors/data/models/user_master_honor_model_test.dart test/features/master_honors/data/datasources/master_honors_remote_data_source_test.dart
```

Expected: FAIL.

**Step 2: Implement entity/model**

Fields:

```dart
class UserMasterHonor {
  final int userMasterHonorId;
  final int masterHonorId;
  final String name;
  final String? masterImage;
  final String status;
  final bool isCurrent;
  final String displayStatusLabel;
  final DateTime? awardedAt;
  final DateTime? revokedAt;
  final DateTime? recoveredAt;
  final String? statusReason;
}
```

**Step 3: Implement datasource/repository/providers**

Endpoint:

```text
GET /api/v1/users/{userId}/master-honors
```

Provider should expose current user master honors and invalidate on master-honor notification.

**Step 4: Run tests/analyze**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app
flutter test test/features/master_honors/data/models/user_master_honor_model_test.dart test/features/master_honors/data/datasources/master_honors_remote_data_source_test.dart
flutter analyze lib/features/master_honors test/features/master_honors
```

Expected: PASS.

**Step 5: Commit**

```bash
git add lib/features/master_honors test/features/master_honors
git commit -m "feat(master-honors): add mobile data layer"
```

---

## Task 10: Mobile band/history display

**Files:**
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/virtual_card/presentation/views/virtual_card_view.dart`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/profile/presentation/widgets/profile_honors_section.dart`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/master_honors/presentation/widgets/master_honor_badge.dart`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/master_honors/presentation/widgets/master_honor_history_section.dart`
- Test: `/Users/abner/Documents/development/sacdia/sacdia-app/test/features/master_honors/master_honor_badge_test.dart`
- Test: `/Users/abner/Documents/development/sacdia/sacdia-app/test/features/virtual_card/virtual_card_master_honors_test.dart`

**Step 1: Write failing widget tests**

Cases:

- current master honor renders normal badge;
- revoked/retired renders badge plus “No vigente” label;
- virtual card includes both current and no-current master honors;
- profile/history section lists status and dates.

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app
flutter test test/features/master_honors/master_honor_badge_test.dart test/features/virtual_card/virtual_card_master_honors_test.dart
```

Expected: FAIL.

**Step 2: Implement badge widget**

Neutral Spanish labels:

```text
Vigente
No vigente
```

Do not hide revoked/retired items.

**Step 3: Integrate with virtual card and profile**

Use `masterHonorsProvider` and render loading/error states conservatively.

**Step 4: Run tests/analyze**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app
flutter test test/features/master_honors/master_honor_badge_test.dart test/features/virtual_card/virtual_card_master_honors_test.dart
flutter analyze lib/features/master_honors lib/features/virtual_card lib/features/profile test/features/master_honors test/features/virtual_card
```

Expected: PASS.

**Step 5: Commit**

```bash
git add lib/features/master_honors lib/features/virtual_card/presentation/views/virtual_card_view.dart lib/features/profile/presentation/widgets/profile_honors_section.dart test/features/master_honors test/features/virtual_card/virtual_card_master_honors_test.dart
git commit -m "feat(master-honors): show band and history status"
```

---

## Task 11: Mobile global modal for master honor changes

**Files:**
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-app/lib/core/notifications/push_notification_service.dart`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/master_honors/presentation/widgets/master_honor_change_modal.dart`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/master_honors/presentation/providers/master_honor_modal_queue_provider.dart`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/master_honors/presentation/providers/master_honors_providers.dart`
- Test: `/Users/abner/Documents/development/sacdia/sacdia-app/test/core/notifications/push_notification_service_master_honor_test.dart`
- Test: `/Users/abner/Documents/development/sacdia/sacdia-app/test/features/master_honors/master_honor_change_modal_test.dart`

**Step 1: Write failing notification tests**

Payload:

```dart
{
  'type': 'master_honor_changed',
  'transition': 'not_current',
  'master_honor_ids': '1,2',
  'master_honor_names': 'Maestría en Acuática|Maestría en Artesanía',
}
```

Assert:

- unread count increments;
- inbox invalidates;
- `masterHonorsProvider` invalidates;
- modal queue receives one grouped event with two names;
- tap route goes to master honors/profile/virtual card route chosen by implementation.

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app
flutter test test/core/notifications/push_notification_service_master_honor_test.dart test/features/master_honors/master_honor_change_modal_test.dart
```

Expected: FAIL.

**Step 2: Implement modal queue**

Rules:

- global queue at provider/service level;
- never stack dialogs;
- if multiple payloads arrive while one modal is open, enqueue and show next after close;
- batch multiple names from one payload into one modal.

**Step 3: Implement modal copy**

Neutral Spanish:

```text
¡Nueva maestría obtenida!
Has obtenido la maestría {nombre}.

¡Nuevas maestrías obtenidas!
Has obtenido:
- {nombre}
- {nombre}

Maestría vigente nuevamente
La maestría {nombre} vuelve a estar vigente en tu perfil.

Maestría marcada como No vigente
Las validaciones requeridas para la maestría {nombre} cambiaron. Actualmente no cumples con los requisitos, por lo que quedó marcada como No vigente.
```

**Step 4: Hook foreground FCM**

In `PushNotificationService._handleForegroundMessage`, before generic notification handling:

```dart
if (type == 'master_honor_changed') {
  _handleMasterHonorChangedForeground(message);
  return;
}
```

Also handle notification tap in `_handleNotificationTap`.

**Step 5: Run tests/analyze**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app
flutter test test/core/notifications/push_notification_service_master_honor_test.dart test/features/master_honors/master_honor_change_modal_test.dart
flutter analyze lib/core/notifications lib/features/master_honors test/core/notifications test/features/master_honors
```

Expected: PASS.

**Step 6: Commit**

```bash
git add lib/core/notifications/push_notification_service.dart lib/features/master_honors test/core/notifications/push_notification_service_master_honor_test.dart test/features/master_honors
git commit -m "feat(master-honors): show global status modal"
```

---

## Task 12: Documentation update

**Files:**
- Modify: `/Users/abner/Documents/development/sacdia/docs/features/honores.md`
- Modify: `/Users/abner/Documents/development/sacdia/docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- Modify: `/Users/abner/Documents/development/sacdia/docs/database/SCHEMA-REFERENCE.md`
- Modify: `/Users/abner/Documents/development/sacdia/docs/plans/2026-06-03-master-honors-requirements-design.md`

**Step 1: Update feature docs**

Document:

- master honors have configurable requirements;
- only approved honors count;
- award/revoke/retire states;
- No vigente visibility in band and history;
- neutral Spanish copy for notifications.

**Step 2: Update API docs**

Document endpoints:

```text
GET /api/v1/users/:userId/master-honors
GET /api/v1/users/:userId/master-honors/:masterHonorId
POST /api/v1/admin/master-honors/:id/recalculate
```

**Step 3: Update DB docs**

Document new tables and enums.

**Step 4: Run docs sanity checks**

```bash
cd /Users/abner/Documents/development/sacdia
git diff --check -- docs/features/honores.md docs/api/ENDPOINTS-LIVE-REFERENCE.md docs/database/SCHEMA-REFERENCE.md docs/plans/2026-06-03-master-honors-requirements-design.md
```

Expected: no output.

**Step 5: Commit**

```bash
git add docs/features/honores.md docs/api/ENDPOINTS-LIVE-REFERENCE.md docs/database/SCHEMA-REFERENCE.md docs/plans/2026-06-03-master-honors-requirements-design.md
git commit -m "docs(master-honors): document requirements workflow"
```

---

## Task 13: Initial data audit and import plan

**Files:**
- Create: `/Users/abner/Documents/development/sacdia/docs/plans/2026-06-03-master-honors-official-rules-import.md`
- Optional create later: `/Users/abner/Documents/development/sacdia/sacdia-backend/scripts/audit-master-honor-assignments.ts`
- Optional create later: `/Users/abner/Documents/development/sacdia/sacdia-backend/scripts/import-master-honor-rules.ts`

**Step 1: Document required source data**

The official import requires:

- master honor name;
- philosophy;
- notes;
- applicability divisions;
- groups;
- group minimum;
- group type;
- category ID or explicit options;
- option label;
- honor IDs equivalent for that option.

**Step 2: Audit existing `honors.master_honors_id`**

Plan script output:

```text
master_honor_id | master_honor_name | assigned_honor_count
1               | ...               | 999
```

Also list honors assigned to master honor 1 for manual review.

**Step 3: Decide import source format**

Recommended source format: JSON or CSV committed under a controlled seed/data path only after official rules are confirmed.

**Step 4: Commit audit plan**

```bash
git add docs/plans/2026-06-03-master-honors-official-rules-import.md
git commit -m "docs(master-honors): plan official rule import"
```

---

## Final Verification Matrix

Backend:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/honors/master-honors-evaluator.service.spec.ts src/honors/master-honors-recalculation.processor.spec.ts src/honors/master-honors.service.spec.ts src/honors/honor-validation-workflow.service.spec.ts src/admin/admin-phase-e-catalogs.service.spec.ts src/notifications/notification-source-map.spec.ts --runInBand
pnpm exec tsc -p tsconfig.build.json --noEmit --pretty false
```

Admin:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-admin
pnpm exec jest src/components/catalogs/master-honor-rules-editor.test.tsx --runInBand
pnpm exec tsc --noEmit
```

App:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app
flutter test test/features/master_honors test/core/notifications/push_notification_service_master_honor_test.dart test/features/virtual_card/virtual_card_master_honors_test.dart
flutter analyze lib/features/master_honors lib/core/notifications lib/features/virtual_card lib/features/profile test/features/master_honors test/core/notifications test/features/virtual_card
```

Workspace docs:

```bash
cd /Users/abner/Documents/development/sacdia
git diff --check
```

---

## Open Decisions Before Implementation

None blocking for the schema/evaluator slice.

Data import remains blocked until the official list of master-honor requirements is available in a machine-readable or manually curated format.
