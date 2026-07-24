# Camporee Staff Roster & Activity Assignments Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add the real camporee operating workflow: a prior personnel roster, flexible people-to-activity assignments, and scoring configuration gated by closed club registration.

**Architecture:** Keep agenda responsibility separate from scoring authority. `camporee_staff_members` becomes the canonical camporee roster; agenda activities use `camporee_event_staff_assignments` for responsible/helper/evaluator/support assignments; existing scoring judge assignments remain for section scoring but must be backed by roster members. Club registration closure freezes eligible club sections before scoring setup.

**Tech Stack:** NestJS 11, Prisma 7 + PostgreSQL/Neon, Next.js 16 admin, Flutter app, Jest, React Testing Library, Flutter test/analyze. Do **not** run builds unless the user explicitly asks.

---

## Business Rules Confirmed

1. A camporee has a prior roster of people who will serve during the event.
2. Roster categories are descriptive capabilities, not mandatory slots per activity:
   - `judge`
   - `administrative`
   - `kitchen`
   - `support`
   - `spiritual`
   - `leadership`
   - `other`
3. Every agenda activity/event can assign only the people it actually needs:
   - opening: president responsible, secretary/helper support
   - lunch: kitchen responsible, kitchen helpers
   - rally: Pedro evaluator/responsible, Marco/Fabio/etc. helpers
4. Agenda assignment is not the same thing as scoring assignment.
5. Scoring setup (rubrics + judges + club sections) must not be configurable until club registration is closed/frozen.
6. Club registration and member registration remain separate:
   - club registration closes early to freeze competition targets
   - member/person registration may remain open until its own deadline

---

## Proposed Backend Data Model

### New table: `camporee_staff_members`

Canonical roster for a local or union camporee.

```prisma
model camporee_staff_members {
  camporee_staff_member_id String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  local_camporee_id        Int?
  union_camporee_id        Int?
  user_id                  String   @db.Uuid
  category                 String   @db.VarChar(30)
  role_label               String?  @db.VarChar(100)
  notes                    String?
  status                   String   @default("active") @db.VarChar(20)
  active                   Boolean  @default(true)
  created_by               String?  @db.Uuid
  modified_by              String?  @db.Uuid
  created_at               DateTime @default(now()) @db.Timestamptz(6)
  modified_at              DateTime @default(now()) @db.Timestamptz(6)

  local_camporee local_camporees? @relation(fields: [local_camporee_id], references: [local_camporee_id], onDelete: Cascade, onUpdate: NoAction)
  union_camporee union_camporees? @relation(fields: [union_camporee_id], references: [union_camporee_id], onDelete: Cascade, onUpdate: NoAction)
  user           users            @relation(fields: [user_id], references: [user_id], onDelete: NoAction, onUpdate: NoAction)

  @@index([local_camporee_id, active], map: "idx_camporee_staff_local_active")
  @@index([union_camporee_id, active], map: "idx_camporee_staff_union_active")
  @@index([user_id], map: "idx_camporee_staff_user")
}
```

Migration-level checks:

```sql
CHECK (
  (local_camporee_id IS NOT NULL AND union_camporee_id IS NULL)
  OR
  (local_camporee_id IS NULL AND union_camporee_id IS NOT NULL)
)
```

```sql
CHECK (category IN (
  'judge',
  'administrative',
  'kitchen',
  'support',
  'spiritual',
  'leadership',
  'other'
))
```

### New table: `camporee_event_staff_assignments`

Flexible people-to-activity assignment for agenda events.

```prisma
model camporee_event_staff_assignments {
  camporee_event_staff_assignment_id String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  camporee_event_id                  Int
  camporee_staff_member_id           String   @db.Uuid
  assignment_role                    String   @db.VarChar(30)
  title_override                     String?  @db.VarChar(100)
  notes                              String?
  display_order                      Int      @default(0)
  active                             Boolean  @default(true)
  created_by                         String?  @db.Uuid
  modified_by                        String?  @db.Uuid
  created_at                         DateTime @default(now()) @db.Timestamptz(6)
  modified_at                        DateTime @default(now()) @db.Timestamptz(6)

  camporee_event        camporee_events        @relation(fields: [camporee_event_id], references: [camporee_event_id], onDelete: Cascade, onUpdate: NoAction)
  camporee_staff_member camporee_staff_members @relation(fields: [camporee_staff_member_id], references: [camporee_staff_member_id], onDelete: Cascade, onUpdate: NoAction)

  @@index([camporee_event_id, active, display_order], map: "idx_camporee_event_staff_event")
  @@index([camporee_staff_member_id, active], map: "idx_camporee_event_staff_member")
}
```

Migration-level check:

```sql
CHECK (assignment_role IN ('responsible', 'assistant', 'evaluator', 'support'))
```

### Extend `local_camporees` and `union_camporees`

Add explicit closure fields for club registration.

```prisma
club_registration_closed_at DateTime? @db.Timestamptz(6)
club_registration_closed_by String?   @db.Uuid
```

Rule:

```ts
const isClubRegistrationClosed =
  Boolean(camporee.club_registration_closed_at);
```

Do not use `club_registration_deadline` alone as closure. Deadline may mark late registration; closure freezes competition targets.

---

## API Contract

### Camporee roster

Create a new backend module:

- `sacdia-backend/src/camporee-staff/camporee-staff.module.ts`
- `sacdia-backend/src/camporee-staff/camporee-staff.controller.ts`
- `sacdia-backend/src/camporee-staff/camporee-staff.service.ts`
- `sacdia-backend/src/camporee-staff/dto/camporee-staff.dto.ts`
- `sacdia-backend/src/camporee-staff/camporee-staff.service.spec.ts`

Endpoints:

```http
GET    /api/v1/local-camporees/:camporeeId/staff
GET    /api/v1/local-camporees/:camporeeId/staff-candidates
POST   /api/v1/local-camporees/:camporeeId/staff
PATCH  /api/v1/camporee-staff/:staffMemberId
DELETE /api/v1/camporee-staff/:staffMemberId

GET    /api/v1/union-camporees/:camporeeId/staff
GET    /api/v1/union-camporees/:camporeeId/staff-candidates
POST   /api/v1/union-camporees/:camporeeId/staff
```

Permissions:

- Read roster: `camporee_events:read`
- Mutate roster: `camporee_events:update`

DTO:

```ts
export type CamporeeStaffCategory =
  | 'judge'
  | 'administrative'
  | 'kitchen'
  | 'support'
  | 'spiritual'
  | 'leadership'
  | 'other';

export class AddCamporeeStaffMemberDto {
  @IsUUID()
  declare user_id: string;

  @IsIn([
    'judge',
    'administrative',
    'kitchen',
    'support',
    'spiritual',
    'leadership',
    'other',
  ])
  declare category: CamporeeStaffCategory;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  declare role_label?: string;

  @IsOptional()
  @IsString()
  declare notes?: string;
}
```

### Agenda activity staff assignments

Extend existing module:

- `sacdia-backend/src/camporee-events/camporee-events.service.ts`
- `sacdia-backend/src/camporee-events/camporee-events.controller.ts`
- `sacdia-backend/src/camporee-events/dto/camporee-events.dto.ts`
- `sacdia-backend/src/camporee-events/camporee-events.service.spec.ts`

Endpoints:

```http
GET /api/v1/camporee-events/:eventId/staff-assignments
PUT /api/v1/camporee-events/:eventId/staff-assignments
```

DTO:

```ts
export type CamporeeEventStaffAssignmentRole =
  | 'responsible'
  | 'assistant'
  | 'evaluator'
  | 'support';

export class CamporeeEventStaffAssignmentDto {
  @IsUUID()
  declare camporee_staff_member_id: string;

  @IsIn(['responsible', 'assistant', 'evaluator', 'support'])
  declare assignment_role: CamporeeEventStaffAssignmentRole;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  declare title_override?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  declare display_order?: number;

  @IsOptional()
  @IsString()
  declare notes?: string;
}

export class ReplaceCamporeeEventStaffAssignmentsDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CamporeeEventStaffAssignmentDto)
  declare assignments: CamporeeEventStaffAssignmentDto[];
}
```

Service rules:

1. Assignment person must belong to the same camporee as the event.
2. `responsible` is required before publishing an event, but not necessarily while draft/programado.
3. More than one helper/support/evaluator is allowed.
4. Do not force every category on every event.

### Club registration closure

Extend:

- `sacdia-backend/src/camporees/camporees.controller.ts`
- `sacdia-backend/src/camporees/camporees.service.ts`
- `sacdia-backend/src/camporees/camporees.service.spec.ts`
- `sacdia-backend/src/camporees/dto/index.ts`

Endpoints:

```http
POST /api/v1/camporees/:camporeeId/club-registration/close
POST /api/v1/camporees/:camporeeId/club-registration/reopen

POST /api/v1/union-camporees/:camporeeId/club-registration/close
POST /api/v1/union-camporees/:camporeeId/club-registration/reopen
```

Rules:

1. Close requires at least one active enrolled club section.
2. Closing stamps `club_registration_closed_at` and `club_registration_closed_by`.
3. Closing prevents new club enrollments by default.
4. Reopen is allowed only if no active scoring results exist and no scoring judge assignments exist.
5. Member registration remains controlled by `member_registration_deadline`, not by club closure.

### Scoring setup gate

Modify:

- `sacdia-backend/src/camporee-scoring/camporee-scoring.service.ts`
- `sacdia-backend/src/camporee-scoring/camporee-scoring.service.spec.ts`

Gate these actions behind closed club registration:

```ts
replaceEventRubrics(...)
assignJudgeToSection(...)
updateJudgeAssignment(...)
deactivateJudgeAssignment(...)
submitScore(...)
```

Important distinction:

- `submitScore` requires club registration closed because official targets must be frozen.
- `getEventRubrics`, `listEventJudgeAssignments`, `getScoringTargets`, `getLeaderboard` remain readable.

Add error code:

```ts
CAMPOREE_CLUB_REGISTRATION_NOT_CLOSED
```

---

## Task 1: Backend schema and migration

**Files:**

- Modify: `sacdia-backend/prisma/schema.prisma`
- Create: `sacdia-backend/prisma/migrations/YYYYMMDDHHMMSS_camporee_staff_roster/migration.sql`

**Step 1: Add failing schema expectation**

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
rg -n "camporee_staff_members|club_registration_closed_at" prisma/schema.prisma
```

Expected before implementation: no matches.

**Step 2: Add Prisma models and relations**

Add:

- `camporee_staff_members`
- `camporee_event_staff_assignments`
- relations in `local_camporees`, `union_camporees`, `users`, `camporee_events`
- closure fields in `local_camporees` and `union_camporees`

**Step 3: Add SQL migration**

The migration must:

- create both new tables
- add closure fields to both camporee tables
- add indexes
- add CHECK constraints for scope/category/assignment role
- backfill current `camporee_judges` into `camporee_staff_members` as `category='judge'`

**Step 4: Validate Prisma schema**

Run:

```bash
pnpm exec prisma validate --schema prisma/schema.prisma
```

Expected: Prisma schema is valid.

**Step 5: Commit**

```bash
git add prisma/schema.prisma prisma/migrations/YYYYMMDDHHMMSS_camporee_staff_roster/migration.sql
git commit -m "feat: add camporee staff roster schema"
```

---

## Task 2: Backend roster API

**Files:**

- Create: `sacdia-backend/src/camporee-staff/camporee-staff.module.ts`
- Create: `sacdia-backend/src/camporee-staff/camporee-staff.controller.ts`
- Create: `sacdia-backend/src/camporee-staff/camporee-staff.service.ts`
- Create: `sacdia-backend/src/camporee-staff/dto/camporee-staff.dto.ts`
- Create: `sacdia-backend/src/camporee-staff/dto/index.ts`
- Create: `sacdia-backend/src/camporee-staff/camporee-staff.service.spec.ts`
- Modify: `sacdia-backend/src/app.module.ts`

**Step 1: Write service tests**

Test cases:

- lists local camporee staff
- lists union camporee staff
- adds a staff member from eligible users
- rejects duplicate active staff member in same camporee
- rejects staff member from a different local field/union scope
- deactivates staff member

Run:

```bash
pnpm exec jest src/camporee-staff/camporee-staff.service.spec.ts --runInBand
```

Expected before implementation: fail because files/classes do not exist.

**Step 2: Implement DTOs**

Use `class-validator` and `@nestjs/swagger`.

**Step 3: Implement service**

Use existing authorization/scope helpers as pattern from:

- `sacdia-backend/src/camporee-scoring/camporee-scoring.service.ts`
- `sacdia-backend/src/camporee-event-templates/camporee-event-templates.service.ts`

**Step 4: Implement controller**

Use:

- `JwtAuthGuard`
- `PermissionsGuard`
- `@RequirePermissions`
- `@AuthorizationResource`

**Step 5: Wire module into `AppModule`**

**Step 6: Run tests**

```bash
pnpm exec jest src/camporee-staff/camporee-staff.service.spec.ts --runInBand
```

Expected: pass.

**Step 7: Commit**

```bash
git add src/camporee-staff src/app.module.ts
git commit -m "feat: add camporee staff roster API"
```

---

## Task 3: Backend activity staff assignments

**Files:**

- Modify: `sacdia-backend/src/camporee-events/camporee-events.controller.ts`
- Modify: `sacdia-backend/src/camporee-events/camporee-events.service.ts`
- Modify: `sacdia-backend/src/camporee-events/dto/camporee-events.dto.ts`
- Modify: `sacdia-backend/src/camporee-events/camporee-events.service.spec.ts`

**Step 1: Write failing tests**

Test cases:

- replaces event staff assignments from camporee roster
- rejects assignment when staff member belongs to another camporee
- includes staff assignments in `getEvent`
- includes staff assignments in `listEvents`
- rejects status transition to `publicado` when no `responsible` assignment exists

Run:

```bash
pnpm exec jest src/camporee-events/camporee-events.service.spec.ts --runInBand
```

Expected before implementation: fail.

**Step 2: Add DTOs**

Add:

- `CamporeeEventStaffAssignmentDto`
- `ReplaceCamporeeEventStaffAssignmentsDto`
- response shape for assigned user/category/role

**Step 3: Implement service methods**

Add:

```ts
listEventStaffAssignments(eventId: number)
replaceEventStaffAssignments(eventId: number, dto, actorId: string)
```

**Step 4: Include assignments in agenda responses**

Extend `getEvent` and `listEvents` include/select so admin/app can display:

- assigned user name
- category
- assignment role
- title override
- display order

**Step 5: Protect publication**

When `status` changes to `publicado`, require at least one active assignment with `assignment_role='responsible'`.

**Step 6: Run tests**

```bash
pnpm exec jest src/camporee-events/camporee-events.service.spec.ts --runInBand
```

Expected: pass.

**Step 7: Commit**

```bash
git add src/camporee-events
git commit -m "feat: assign camporee staff to agenda events"
```

---

## Task 4: Backend club registration closure and scoring gate

**Files:**

- Modify: `sacdia-backend/src/camporees/camporees.controller.ts`
- Modify: `sacdia-backend/src/camporees/camporees.service.ts`
- Modify: `sacdia-backend/src/camporees/camporees.service.spec.ts`
- Modify: `sacdia-backend/src/camporee-scoring/camporee-scoring.service.ts`
- Modify: `sacdia-backend/src/camporee-scoring/camporee-scoring.service.spec.ts`
- Modify: `sacdia-backend/src/common/enums/error-codes.enum.ts`

**Step 1: Write failing camporee closure tests**

Test cases:

- closes local club registration
- closes union club registration
- refuses close without active enrolled club sections
- prevents club enrollment after closure
- allows member registration after club closure when member deadline is still open
- refuses reopen after scoring assignments/results exist

Run:

```bash
pnpm exec jest src/camporees/camporees.service.spec.ts --runInBand
```

Expected before implementation: fail.

**Step 2: Write failing scoring gate tests**

Test cases:

- `replaceEventRubrics` rejects if club registration is not closed
- `assignJudgeToSection` rejects if club registration is not closed
- `submitScore` rejects if club registration is not closed
- read endpoints still work before closure

Run:

```bash
pnpm exec jest src/camporee-scoring/camporee-scoring.service.spec.ts --runInBand
```

Expected before implementation: fail.

**Step 3: Implement closure methods**

Add methods:

```ts
closeLocalCamporeeClubRegistration(camporeeId: number, actorUserId: string)
reopenLocalCamporeeClubRegistration(camporeeId: number, actorUserId: string)
closeUnionCamporeeClubRegistration(camporeeId: number, actorUserId: string)
reopenUnionCamporeeClubRegistration(camporeeId: number, actorUserId: string)
```

**Step 4: Block club enrollment after closure**

Modify:

- local club enroll
- union club enroll
- late approval flows if they create/activate club enrollments

Do **not** block member registration from club closure.

**Step 5: Implement scoring gate helper**

Add in `CamporeeScoringService`:

```ts
private async ensureClubRegistrationClosedForEvent(event: CamporeeEventRecord): Promise<void>
```

Use it in mutating scoring/config paths.

**Step 6: Run focused tests**

```bash
pnpm exec jest src/camporees/camporees.service.spec.ts --runInBand
pnpm exec jest src/camporee-scoring/camporee-scoring.service.spec.ts --runInBand
```

Expected: pass.

**Step 7: Commit**

```bash
git add src/camporees src/camporee-scoring src/common/enums/error-codes.enum.ts
git commit -m "feat: gate camporee scoring by club registration closure"
```

---

## Task 5: Backend compatibility with existing judge API

**Files:**

- Modify: `sacdia-backend/src/camporee-scoring/camporee-scoring.service.ts`
- Modify: `sacdia-backend/src/camporee-scoring/dto/camporee-scoring.dto.ts`
- Modify: `sacdia-backend/src/camporee-scoring/camporee-scoring.service.spec.ts`

**Step 1: Write compatibility tests**

Test cases:

- adding a judge creates or reuses a `camporee_staff_members` row with `category='judge'`
- assigning a scoring judge requires that judge to belong to camporee roster
- assistant judge still cannot submit score
- primary judge can submit score after club registration is closed

**Step 2: Implement compatibility logic**

Keep existing endpoints stable:

```http
GET  /api/v1/local-camporees/:camporeeId/judges
POST /api/v1/local-camporees/:camporeeId/judges
```

But internally make them use/maintain staff roster records.

**Step 3: Run scoring tests**

```bash
pnpm exec jest src/camporee-scoring/camporee-scoring.service.spec.ts --runInBand
```

Expected: pass.

**Step 4: Commit**

```bash
git add src/camporee-scoring
git commit -m "refactor: align camporee judges with staff roster"
```

---

## Task 6: Admin contracts and actions

**Files:**

- Create: `sacdia-admin/src/lib/api/camporee-staff.ts`
- Create: `sacdia-admin/src/lib/camporee-staff/actions.ts`
- Modify: `sacdia-admin/src/lib/api/camporee-events.ts`
- Modify: `sacdia-admin/src/lib/api/camporee-scoring.ts`
- Modify: `sacdia-admin/src/lib/api/camporees.ts`

**Step 1: Add typed API functions**

Add functions:

```ts
listCamporeeStaff(scope, camporeeId)
listCamporeeStaffCandidates(scope, camporeeId)
addCamporeeStaffMember(scope, camporeeId, payload)
updateCamporeeStaffMember(staffMemberId, payload)
deleteCamporeeStaffMember(staffMemberId)
replaceEventStaffAssignments(eventId, payload)
closeClubRegistration(scope, camporeeId)
reopenClubRegistration(scope, camporeeId)
```

**Step 2: Add server actions**

Follow patterns from:

- `sacdia-admin/src/lib/camporee-scoring/actions.ts`
- `sacdia-admin/src/lib/camporee-events/actions.ts`

**Step 3: Run targeted type/test check**

Do not build. Use focused tests if existing.

```bash
pnpm test camporee
```

Expected: existing camporee tests pass or reveal UI updates needed.

**Step 4: Commit**

```bash
git add src/lib/api src/lib/camporee-staff
git commit -m "feat: add camporee staff admin actions"
```

---

## Task 7: Admin roster UI

**Files:**

- Create: `sacdia-admin/src/components/camporee-staff/camporee-staff-panel.tsx`
- Create: `sacdia-admin/src/components/camporee-staff/camporee-staff-panel.test.tsx`
- Modify: `sacdia-admin/src/components/camporees/camporee-detail-tabs.tsx`
- Modify: `sacdia-admin/src/components/camporees/camporee-detail-actions.tsx`

**Step 1: Write UI tests**

Test cases:

- renders current roster
- opens candidate selector
- adds staff member with category
- shows category badge
- deactivates staff member

**Step 2: Implement panel**

UI requirements:

- Search/select user candidate
- Category select
- Optional role label
- Notes
- Table/cards grouped by category
- Empty state: “Aún no hay personal asignado al camporee”

**Step 3: Add detail tab**

Add `Personal` tab before `Eventos`.

**Step 4: Run focused tests**

```bash
pnpm test camporee-staff
```

Expected: pass.

**Step 5: Commit**

```bash
git add src/components/camporee-staff src/components/camporees
git commit -m "feat: manage camporee staff roster in admin"
```

---

## Task 8: Admin event activity assignments UI

**Files:**

- Create: `sacdia-admin/src/components/camporee-events/event-staff-assignments-editor.tsx`
- Create: `sacdia-admin/src/components/camporee-events/event-staff-assignments-editor.test.tsx`
- Modify: `sacdia-admin/src/components/camporee-events/event-form-page.tsx`
- Modify: `sacdia-admin/src/components/camporee-events/timeline/event-row.tsx`
- Modify: `sacdia-admin/src/components/camporee-events/timeline/event-day-card.tsx`

**Step 1: Write UI tests**

Test cases:

- selects responsible from roster
- adds multiple helpers/support/evaluators
- does not require kitchen/admin/support roles
- blocks publish when no responsible assignment exists
- timeline displays responsible and helpers compactly

**Step 2: Implement editor**

Use one flexible list:

```text
Persona | Rol en actividad | Etiqueta opcional | Notas
```

Roles:

- Responsable
- Ayudante
- Evaluador
- Apoyo

**Step 3: Integrate into event create/edit**

When creating event:

1. create event
2. replace staff assignments if provided
3. if scoring event and closed club registration: configure rubrics/judge assignments

**Step 4: Timeline display**

Display:

```text
Responsable: Pedro
Apoyan: Marco, Fabio, Antonio +3
```

**Step 5: Run focused tests**

```bash
pnpm test camporee-events
```

Expected: pass.

**Step 6: Commit**

```bash
git add src/components/camporee-events src/lib/api/camporee-events.ts
git commit -m "feat: assign staff to camporee agenda activities"
```

---

## Task 9: Admin club registration closure UX

**Files:**

- Modify: `sacdia-admin/src/components/camporees/camporee-clubs-panel.tsx`
- Modify: `sacdia-admin/src/components/camporees/camporee-info-card.tsx`
- Modify: `sacdia-admin/src/components/camporee-scoring/event-judge-assignments-panel.tsx`
- Modify: `sacdia-admin/src/components/camporee-scoring/event-score-entry-panel.tsx`

**Step 1: Add tests**

Test cases:

- close registration button appears when there are enrolled sections
- closed state shows frozen target message
- scoring setup panels disabled until closure
- member registration UI remains available after club closure

**Step 2: Implement close/reopen actions**

Use confirmation dialog with explicit warning:

```text
Cerrar inscripción de clubes congela las secciones para puntajes y asignación de jueces.
```

**Step 3: Disable scoring setup until closure**

Display:

```text
Primero cerrá la inscripción de clubes para congelar las secciones participantes.
```

**Step 4: Run focused tests**

```bash
pnpm test camporee
```

Expected: pass.

**Step 5: Commit**

```bash
git add src/components/camporees src/components/camporee-scoring
git commit -m "feat: add camporee club registration closure UI"
```

---

## Task 10: Mobile display support

**Files:**

- Modify: `sacdia-app/lib/features/camporees/data/models/camporee_event_model.dart`
- Modify: `sacdia-app/lib/features/camporees/domain/entities/camporee_event.dart`
- Modify: `sacdia-app/lib/features/camporees/presentation/views/camporee_detail_view.dart`
- Modify: `sacdia-app/lib/features/camporees/presentation/views/judge_assignments_view.dart`

**Step 1: Add model/entity fields**

Represent:

- `staffAssignments`
- responsible
- helpers/evaluators/support list

**Step 2: Display in agenda**

Show responsible/helper data for users viewing the agenda.

**Step 3: Keep judge scoring app flow stable**

Judge scoring continues to use existing scoring assignment endpoint.

**Step 4: Run mobile checks**

Do not build. Use:

```bash
flutter test
flutter analyze
```

Expected: no failures from camporee model/entity changes.

**Step 5: Commit**

```bash
git add lib/features/camporees
git commit -m "feat: show camporee activity staff in app"
```

---

## Task 11: Documentation update

**Files:**

- Modify: `docs/features/camporees.md`
- Modify: `docs/features/camporee-events.md`
- Modify: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- Modify: `docs/api/FRONTEND-INTEGRATION-GUIDE.md`
- Modify: `docs/database/SCHEMA-REFERENCE.md`

**Step 1: Document workflow**

Add canonical flow:

```text
crear camporee
→ definir fechas límite
→ cargar personal del camporee
→ abrir inscripción de clubes
→ cerrar inscripción de clubes
→ configurar eventos/puntajes/jueces/secciones
→ mantener inscripción de miembros según deadline propio
→ publicar agenda
```

**Step 2: Document endpoint contracts**

Add roster, event staff assignment and closure endpoints.

**Step 3: Document DB changes**

Add new tables and closure fields.

**Step 4: Commit**

```bash
git add docs/features docs/api docs/database
git commit -m "docs: document camporee staff workflow"
```

---

## Verification Checklist

Run only focused checks; no builds unless explicitly requested.

Backend:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec prisma validate --schema prisma/schema.prisma
pnpm exec jest src/camporee-staff/camporee-staff.service.spec.ts --runInBand
pnpm exec jest src/camporee-events/camporee-events.service.spec.ts --runInBand
pnpm exec jest src/camporee-scoring/camporee-scoring.service.spec.ts --runInBand
pnpm exec jest src/camporees/camporees.service.spec.ts --runInBand
```

Admin:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-admin
pnpm test camporee
```

Mobile:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app
flutter test
flutter analyze
```

Workspace:

```bash
cd /Users/abner/Documents/development/sacdia
git diff --check
```

---

## Rollout Notes

1. Keep old judge endpoints stable while adding roster.
2. Backfill existing `camporee_judges` as `camporee_staff_members.category='judge'`.
3. Admin should introduce `Personal` before asking the user to configure event staff/scoring.
4. Mobile can start read-only: display responsible/helpers in agenda; do not add editing.
5. Do not hard-delete roster/assignments; deactivate for auditability.

---

## Acceptance Criteria

- A camporee can define a prior roster of people.
- Roster people can be categorized without forcing every category onto every event.
- Any agenda activity can have one responsible and optional helpers/evaluators/support.
- A scoring event can still assign judge principal/helper by enrolled section.
- Scoring setup is blocked until club registration is closed.
- Member registration can remain open after club registration closes.
- Existing camporee judge APIs do not break current app/admin flows.
- Agenda responses include staff assignments for admin/app display.
- Documentation reflects the new workflow.
