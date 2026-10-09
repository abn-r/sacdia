# Camporee Section Enrollment Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Permitir que sólo el director inscriba su sección activa a un Camporí, registrar quién realizó la acción y bloquear participantes hasta que la sección esté inscrita o aprobada.

**Architecture:** El backend será la única autoridad para resolver la sección desde `active_assignment`; el cliente no enviará IDs de sección. Un read model contextual alimentará la UI Flutter y una FK desde `camporee_members` a `camporee_clubs` preservará trazabilidad y permitirá validar ownership.

**Tech Stack:** NestJS 11, Prisma 7.8, PostgreSQL/Neon, Jest, Flutter, Riverpod, Dio, GoRouter, Easy Localization, HugeIcons.

**Required skills:** `@test-driven-development`, `@backend-security-coder`, `@api-patterns`, `@developing-mobile-apps`, `@app-ui-design`, `@mobile-design`, `@ui-ux-pro-max`, `@verification-before-completion`.

**Design source:** `docs/plans/2026-07-13-camporee-section-enrollment-design.md`

**Hard constraints:** No builds. No `Co-Authored-By`. Conventional commits only. Do not touch unrelated `evidence-review` work. Implement backend contract and documentation before app consumption.

---

## Worktree and delivery setup

Use isolated branches in each runtime repository:

```bash
git -C sacdia-backend worktree add ../.worktrees/backend-camporee-section-enrollment \
  -b codex/camporee-section-enrollment development
git -C sacdia-app worktree add ../.worktrees/app-camporee-section-enrollment \
  -b codex/camporee-section-enrollment development
```

Do not copy `.env` files. Tests must use mocks or explicitly approved test configuration. The root documentation worktree already lives at `.worktrees/camporee-section-enrollment-design`.

---

### Task 1: Add the director-only permission and schema lineage

**Files:**
- Create: `sacdia-backend/prisma/migrations/20260713220000_camporee_section_registration_context/migration.sql`
- Modify: `sacdia-backend/prisma/schema.prisma:110-169`
- Modify: `sacdia-backend/prisma/seeds/role-permissions.seed.sql:957-1100`
- Test: `sacdia-backend/src/common/guards/permissions-metadata.spec.ts`

**Step 1: Write the failing permission regression test**

Add a test that reads the controller metadata after Task 2's method is declared. Until then, start with a seed contract assertion that only the club `director` receives the new permission:

```ts
it('reserves camporees:register_active_section for the club director', () => {
  const sql = readFileSync(
    join(process.cwd(), 'prisma/seeds/role-permissions.seed.sql'),
    'utf8',
  );
  expect(sql).toContain("'camporees:register_active_section'");
  expect(sql).toMatch(/role_name = 'director'[\s\S]+camporees:register_active_section/);
});
```

Prefer an existing seed-contract test file if one already covers role permissions; do not create duplicate infrastructure.

**Step 2: Run the test to verify RED**

Run:

```bash
pnpm exec jest src/common/guards/permissions-metadata.spec.ts --runInBand
```

Expected: FAIL because the permission is absent.

**Step 3: Add the migration**

The migration must be additive and idempotent for RBAC inserts:

```sql
ALTER TABLE "camporee_members"
  ADD COLUMN "camporee_club_id" INT;

ALTER TABLE "camporee_members"
  ADD CONSTRAINT "fk_camporee_members_camporee_club"
  FOREIGN KEY ("camporee_club_id")
  REFERENCES "camporee_clubs"("camporee_club_id")
  ON DELETE NO ACTION ON UPDATE NO ACTION;

CREATE INDEX "idx_camporee_members_camporee_club_id"
  ON "camporee_members"("camporee_club_id");

CREATE UNIQUE INDEX "uq_camporee_clubs_local_active_section"
  ON "camporee_clubs"("camporee_id", "club_section_id")
  WHERE "camporee_id" IS NOT NULL AND "active" = TRUE;

CREATE UNIQUE INDEX "uq_camporee_clubs_union_active_section"
  ON "camporee_clubs"("union_camporee_id", "club_section_id")
  WHERE "union_camporee_id" IS NOT NULL AND "active" = TRUE;

INSERT INTO permissions (permission_name, description, active)
VALUES (
  'camporees:register_active_section',
  'Inscribir la sección activa del director a un camporee',
  TRUE
)
ON CONFLICT (permission_name) DO UPDATE
SET active = TRUE, modified_at = NOW();

INSERT INTO role_permissions (role_permission_id, role_id, permission_id)
SELECT gen_random_uuid(), r.role_id, p.permission_id
FROM roles r
JOIN permissions p
  ON p.permission_name = 'camporees:register_active_section'
WHERE r.role_name = 'director'
  AND r.role_category = 'CLUB'
  AND r.active = TRUE
  AND p.active = TRUE
ON CONFLICT (role_id, permission_id) DO UPDATE
SET active = TRUE, modified_at = NOW();
```

Before creating unique indexes, add a read-only verification query for duplicate active rows. If duplicates exist in any environment, STOP and produce a remediation report; never auto-delete enrollments.

**Step 4: Update Prisma schema and canonical seed**

Add:

```prisma
model camporee_clubs {
  // existing fields
  members camporee_members[]
}

model camporee_members {
  // existing fields
  camporee_club_id Int?
  camporee_club    camporee_clubs? @relation(
    fields: [camporee_club_id],
    references: [camporee_club_id],
    onDelete: NoAction,
    onUpdate: NoAction,
    map: "fk_camporee_members_camporee_club"
  )

  @@index([camporee_club_id], map: "idx_camporee_members_camporee_club_id")
}
```

Add `camporees:register_active_section` only to the canonical `director` permission list. Do not add it to deputy director, secretary, treasurer or `secretary-treasurer`.

**Step 5: Run schema and permission checks**

Run:

```bash
pnpm exec prisma validate --schema prisma/schema.prisma
pnpm exec jest src/common/guards/permissions-metadata.spec.ts --runInBand
git diff --check
```

Expected: Prisma valid, test PASS, no whitespace errors.

**Step 6: Commit**

```bash
git add prisma/migrations/20260713220000_camporee_section_registration_context \
  prisma/schema.prisma prisma/seeds/role-permissions.seed.sql \
  src/common/guards/permissions-metadata.spec.ts
git commit -m "feat(camporees): add section registration lineage"
```

---

### Task 2: Define the contextual API contract

**Files:**
- Create: `sacdia-backend/src/camporees/dto/camporee-section-registration.dto.ts`
- Modify: `sacdia-backend/src/camporees/camporees.controller.ts:831-875`
- Modify: `sacdia-backend/src/camporees/camporees.controller.spec.ts`
- Modify: `sacdia-backend/src/common/guards/permissions-metadata.spec.ts`

**Step 1: Write failing controller tests**

```ts
it('gets registration state with actor authorization context', async () => {
  const req = { user: { sub: 'actor-id' }, authorization: { marker: true } };
  await controller.getActiveSectionRegistration(7, req as never);
  expect(camporeesService.getActiveSectionRegistration).toHaveBeenCalledWith(
    7,
    'actor-id',
    req.authorization,
  );
});

it('registers without accepting a section id from the client', async () => {
  const req = { user: { sub: 'actor-id' }, authorization: { marker: true } };
  await controller.registerActiveSection(7, req as never);
  expect(camporeesService.registerActiveSection).toHaveBeenCalledWith(
    7,
    'actor-id',
    req.authorization,
  );
});
```

Add metadata assertions that the POST requires `camporees:register_active_section`; the GET requires `camporees:read` and remains read-only for other cargos.

**Step 2: Verify RED**

```bash
pnpm exec jest src/camporees/camporees.controller.spec.ts \
  src/common/guards/permissions-metadata.spec.ts --runInBand
```

Expected: FAIL because methods and metadata are missing.

**Step 3: Add response DTOs**

Define explicit enums/unions and Swagger properties for:

```ts
export type SectionRegistrationStatus =
  | 'not_enrolled'
  | 'registered'
  | 'pending_approval'
  | 'approved'
  | 'rejected'
  | 'cancelled';

export class CamporeeSectionRegistrationDto {
  camporeeId!: number;
  clubId!: number;
  clubName!: string;
  clubSectionId!: number;
  sectionName!: string;
  clubTypeId!: number;
  clubTypeName!: string;
  status!: SectionRegistrationStatus;
  disposition!: 'not_open_yet' | 'open' | 'late_approval_required' | 'manually_frozen';
  canEnroll!: boolean;
  blockingReason!: string | null;
  enrollmentId!: number | null;
  registeredAt!: Date | null;
  registeredBy!: { userId: string; displayName: string } | null;
}
```

Use `@ApiProperty`/`@ApiPropertyOptional` consistently with existing DTOs.

**Step 4: Add controller routes**

```ts
@Get(':camporeeId/section-registration')
@RequirePermissions('camporees:read')
@AuthorizationResource({ type: 'camporee', idParam: 'camporeeId' })
getActiveSectionRegistration(
  @Param('camporeeId', ParseIntPipe) camporeeId: number,
  @Request() req: any,
) {
  return this.camporeesService.getActiveSectionRegistration(
    camporeeId,
    req.user.sub,
    req.authorization,
  );
}

@Post(':camporeeId/section-registration')
@RequirePermissions('camporees:register_active_section')
@AuthorizationResource({ type: 'camporee', idParam: 'camporeeId' })
registerActiveSection(
  @Param('camporeeId', ParseIntPipe) camporeeId: number,
  @Request() req: any,
) {
  return this.camporeesService.registerActiveSection(
    camporeeId,
    req.user.sub,
    req.authorization,
  );
}
```

No `@Body()` is permitted on the contextual POST.

**Step 5: Verify GREEN and commit**

```bash
pnpm exec jest src/camporees/camporees.controller.spec.ts \
  src/common/guards/permissions-metadata.spec.ts --runInBand
git diff --check
git add src/camporees/dto/camporee-section-registration.dto.ts \
  src/camporees/camporees.controller.ts \
  src/camporees/camporees.controller.spec.ts \
  src/common/guards/permissions-metadata.spec.ts
git commit -m "feat(camporees): expose active section registration contract"
```

---

### Task 3: Implement contextual read state

**Files:**
- Modify: `sacdia-backend/src/camporees/camporees.service.ts`
- Modify: `sacdia-backend/src/camporees/camporees.service.spec.ts`
- Modify: `sacdia-backend/src/common/errors/error-codes.ts`
- Modify: `sacdia-backend/src/i18n/{es,en,fr,pt-BR}/errors.json`

**Step 1: Write failing service tests**

Cover:

```ts
it('returns the active director section as not_enrolled');
it('returns existing registration with actor and timestamp');
it('returns canEnroll false for a non-director reader');
it('returns canEnroll false when the camporee excludes the active club type');
it('rejects when no active club assignment exists');
```

Fixture shape:

```ts
const directorAuthorization = {
  active_assignment: { assignment_id: 'assignment-1' },
  grants: {
    global_roles: [],
    club_assignments: [{
      assignment_id: 'assignment-1',
      role_name: 'director',
      club: { club_id: 12, club_name: 'Orión' },
      section: {
        club_section_id: 44,
        club_type_id: 2,
        club_type_name: 'Conquistadores',
      },
      scope: { local_field: { id: 5 } },
    }],
  },
};
```

**Step 2: Verify RED**

```bash
pnpm exec jest src/camporees/camporees.service.spec.ts --runInBand \
  -t "active section registration"
```

**Step 3: Implement one private resolver**

Create a single internal method that:

```ts
private resolveActiveClubGrant(
  authorization: AuthorizationSnapshot,
): ClubAuthorizationGrant {
  const id = authorization.active_assignment.assignment_id;
  const grant = authorization.grants.club_assignments.find(
    candidate => candidate.assignment_id === id,
  );
  if (!grant) {
    throw new AppForbiddenException(
      ErrorCode.CAMPOREE_ACTIVE_SECTION_REQUIRED,
    );
  }
  return grant;
}
```

Do not query a second authorization source; use the request snapshot resolved by the guard.

**Step 4: Implement `getActiveSectionRegistration`**

Load the Camporí, validate territory visibility, find the active enrollment including `registrar`, derive disposition from `CamporeeLifecyclePolicy`, and map `canEnroll` plus `blockingReason`. Non-directors can read state but cannot enroll.

Use one response mapper shared later by the POST. Avoid returning raw Prisma rows.

**Step 5: Verify GREEN and commit**

```bash
pnpm exec jest src/camporees/camporees.service.spec.ts --runInBand \
  -t "active section registration"
git diff --check
git add src/camporees/camporees.service.ts \
  src/camporees/camporees.service.spec.ts \
  src/common/errors/error-codes.ts src/i18n/*/errors.json
git commit -m "feat(camporees): resolve active section registration state"
```

---

### Task 4: Implement secure and idempotent section registration

**Files:**
- Modify: `sacdia-backend/src/camporees/camporees.service.ts`
- Modify: `sacdia-backend/src/camporees/camporees.service.spec.ts`

**Step 1: Write failing mutation tests**

```ts
it('registers only the director active section and actor');
it('rejects deputy director even if attendance:manage exists');
it('rejects an active section from another local field');
it('rejects a club type excluded by the camporee');
it('returns the existing row on a duplicate request');
it('creates pending_approval after the deadline');
it('rejects not_open_yet and manually_frozen dispositions');
```

Assert exact create data:

```ts
expect(tx.camporee_clubs.create).toHaveBeenCalledWith({
  data: expect.objectContaining({
    camporee_id: 7,
    camporee_type: 'local',
    club_section_id: 44,
    club_id: 12,
    registered_by: 'actor-id',
    status: 'registered',
    active: true,
  }),
  include: expect.any(Object),
});
```

**Step 2: Verify RED**

```bash
pnpm exec jest src/camporees/camporees.service.spec.ts --runInBand \
  -t "register active section"
```

**Step 3: Implement transaction**

Within one transaction:

1. load Camporí;
2. resolve active grant;
3. require `role_name === 'director'`;
4. validate field and included type;
5. calculate disposition;
6. return existing active enrollment if found;
7. create `registered` or `pending_approval` with `registered_by = actorUserId`.

Handle a unique-index race by catching Prisma `P2002` and reading the winning row. Do not treat a replay as an error.

**Step 4: Preserve late-approval notification**

Reuse the existing notification path only when a new `pending_approval` row was created. A replay must not send a second notification.

**Step 5: Verify GREEN and commit**

```bash
pnpm exec jest src/camporees/camporees.service.spec.ts --runInBand \
  -t "register active section"
git diff --check
git add src/camporees/camporees.service.ts \
  src/camporees/camporees.service.spec.ts
git commit -m "feat(camporees): register director active section"
```

---

### Task 5: Enforce enrollment before participant registration

**Files:**
- Modify: `sacdia-backend/src/camporees/camporees.controller.ts`
- Modify: `sacdia-backend/src/camporees/camporees.controller.spec.ts`
- Modify: `sacdia-backend/src/camporees/camporees.service.ts:750-920`
- Modify: `sacdia-backend/src/camporees/camporees.service.spec.ts`
- Modify: `sacdia-backend/test/camporees.e2e-spec.ts`

**Step 1: Write failing tests**

```ts
it('blocks a participant when the active section is not enrolled');
it('blocks a participant while section enrollment is pending');
it('rejects a user outside the director active section');
it('persists camporee_club_id for an eligible participant');
it('allows registered and approved section states');
```

The controller test must prove it forwards `req.user.sub` and `req.authorization`; the service must never infer the actor from request body fields.

**Step 2: Verify RED**

```bash
pnpm exec jest src/camporees/camporees.controller.spec.ts \
  src/camporees/camporees.service.spec.ts --runInBand \
  -t "participant registration"
```

**Step 3: Implement the precondition**

Before insurance validation:

```ts
const activeGrant = this.resolveActiveClubGrant(authorization);
const enrollment = await tx.camporee_clubs.findFirst({
  where: {
    camporee_id: camporeeId,
    club_section_id: activeGrant.section.club_section_id,
    active: true,
    status: { in: ['registered', 'approved'] },
  },
});

if (!enrollment) {
  throw new AppUnprocessableEntityException(
    ErrorCode.CAMPOREE_SECTION_REGISTRATION_REQUIRED,
  );
}
```

Validate the target user's active club assignment belongs to the same `club_section_id`. Then persist:

```ts
camporee_club_id: enrollment.camporee_club_id,
```

If organizer-level legacy registration must remain available, isolate it behind its own explicit permission and service method. Do not weaken the contextual director path with role branching.

**Step 4: Add e2e contract coverage**

Cover HTTP status and stable error code for missing enrollment, then success after registration. Use fixtures only; do not point e2e tests at staging or production.

**Step 5: Verify GREEN and commit**

```bash
pnpm exec jest src/camporees/camporees.controller.spec.ts \
  src/camporees/camporees.service.spec.ts --runInBand
pnpm test:e2e -- --runInBand test/camporees.e2e-spec.ts
git diff --check
git add src/camporees test/camporees.e2e-spec.ts
git commit -m "fix(camporees): require section enrollment for participants"
```

---

### Task 6: Add Flutter domain and data contracts

**Files:**
- Create: `sacdia-app/lib/features/camporees/domain/entities/camporee_section_registration.dart`
- Create: `sacdia-app/lib/features/camporees/data/models/camporee_section_registration_model.dart`
- Modify: `sacdia-app/lib/features/camporees/domain/repositories/camporees_repository.dart`
- Modify: `sacdia-app/lib/features/camporees/data/repositories/camporees_repository_impl.dart`
- Modify: `sacdia-app/lib/features/camporees/data/datasources/camporees_remote_data_source.dart`
- Test: `sacdia-app/test/features/camporees/data/models/camporee_section_registration_model_test.dart`
- Test: `sacdia-app/test/features/camporees/data/datasources/camporees_remote_data_source_test.dart`
- Test: `sacdia-app/test/features/camporees/data/repositories/camporees_repository_impl_test.dart`

**Step 1: Write failing model and datasource tests**

```dart
test('parses contextual section registration state', () {
  final model = CamporeeSectionRegistrationModel.fromJson(_fixture);
  expect(model.status, CamporeeSectionRegistrationStatus.registered);
  expect(model.clubSectionId, 44);
  expect(model.registeredBy?.displayName, 'Abner Reyes');
});

test('POST section-registration sends no section id body', () async {
  await ds.registerActiveSection(7);
  expect(adapter.lastOptions!.path,
      '/api/v1/camporees/7/section-registration');
  expect(adapter.lastOptions!.data == null || adapter.lastOptions!.data == '',
      isTrue);
});
```

**Step 2: Verify RED**

```bash
flutter test \
  test/features/camporees/data/models/camporee_section_registration_model_test.dart \
  test/features/camporees/data/datasources/camporees_remote_data_source_test.dart \
  test/features/camporees/data/repositories/camporees_repository_impl_test.dart
```

**Step 3: Implement typed domain model**

Use an enum with an explicit unknown-safe parser. The domain entity exposes helpers only for business readability:

```dart
bool get enablesParticipants =>
    status == CamporeeSectionRegistrationStatus.registered ||
    status == CamporeeSectionRegistrationStatus.approved;
```

Do not put translated UI strings in the entity.

**Step 4: Implement GET and POST datasource/repository methods**

```dart
Future<CamporeeSectionRegistrationModel> getActiveSectionRegistration(
  int camporeeId,
);

Future<CamporeeSectionRegistrationModel> registerActiveSection(
  int camporeeId,
);
```

Parse both direct and `{ data: ... }` envelopes using the existing helper conventions. The POST carries no `club_section_id` and no actor fields.

**Step 5: Verify GREEN and commit**

```bash
flutter test \
  test/features/camporees/data/models/camporee_section_registration_model_test.dart \
  test/features/camporees/data/datasources/camporees_remote_data_source_test.dart \
  test/features/camporees/data/repositories/camporees_repository_impl_test.dart
dart format lib/features/camporees test/features/camporees
git diff --check
git add lib/features/camporees test/features/camporees
git commit -m "feat(camporees): consume section registration contract"
```

---

### Task 7: Add Riverpod state and director-only mutation

**Files:**
- Modify: `sacdia-app/lib/features/camporees/presentation/providers/camporees_providers.dart`
- Create: `sacdia-app/test/features/camporees/presentation/providers/camporee_section_registration_provider_test.dart`

**Step 1: Write failing provider tests**

Cover GET loading/data/error, successful mutation invalidation, and failure preservation:

```dart
test('successful registration invalidates contextual state and detail', () async {
  // Override repository provider with fake.
  // Invoke notifier.register().
  // Assert success and fresh provider reads.
});
```

**Step 2: Verify RED**

```bash
flutter test \
  test/features/camporees/presentation/providers/camporee_section_registration_provider_test.dart
```

**Step 3: Implement providers**

Add:

```dart
final camporeeSectionRegistrationProvider =
    FutureProvider.autoDispose.family<CamporeeSectionRegistration, int>(...);

final registerCamporeeSectionProvider = AutoDisposeNotifierProviderFamily<
    RegisterCamporeeSectionNotifier,
    RegisterCamporeeSectionState,
    int>(...);
```

On success invalidate:

- `camporeeSectionRegistrationProvider(camporeeId)`;
- `camporeeDetailProvider(camporeeId)`;
- `camporeeEnrolledClubsProvider(camporeeId)`;
- member providers only when the state enables participants.

Do not use optimistic success for this mutation.

**Step 4: Verify GREEN and commit**

```bash
flutter test \
  test/features/camporees/presentation/providers/camporee_section_registration_provider_test.dart
dart format lib/features/camporees/presentation/providers \
  test/features/camporees/presentation/providers
git diff --check
git add lib/features/camporees/presentation/providers \
  test/features/camporees/presentation/providers
git commit -m "feat(camporees): manage section registration state"
```

---

### Task 8: Replace the orphan form with the approved mobile flow

**Files:**
- Modify: `sacdia-app/lib/features/camporees/presentation/views/camporee_detail_view.dart`
- Replace or remove: `sacdia-app/lib/features/camporees/presentation/views/camporee_enroll_club_view.dart`
- Create: `sacdia-app/lib/features/camporees/presentation/widgets/camporee_section_registration_panel.dart`
- Create: `sacdia-app/lib/features/camporees/presentation/widgets/camporee_section_registration_sheet.dart`
- Modify: `sacdia-app/lib/core/config/router.dart`
- Modify: `sacdia-app/lib/core/config/route_names.dart`
- Modify: `sacdia-app/assets/translations/{es,en,fr,pt-BR}.json`
- Test: `sacdia-app/test/features/camporees/presentation/views/camporee_detail_section_registration_test.dart`
- Test: `sacdia-app/test/features/camporees/presentation/widgets/camporee_section_registration_sheet_test.dart`

**Step 1: Write failing widget tests**

Cover:

```dart
testWidgets('director sees Inscribir mi sección when available', ...);
testWidgets('deputy sees read-only director guidance', ...);
testWidgets('pending approval blocks participant action', ...);
testWidgets('registered state shows actor and enables participants', ...);
testWidgets('confirmation contains section and no editable id', ...);
testWidgets('loading reserves stable panel height', ...);
testWidgets('error offers retry', ...);
```

Use existing SACDIA theme wrappers and provider overrides. Do not test private widgets directly.

**Step 2: Verify RED**

```bash
flutter test \
  test/features/camporees/presentation/views/camporee_detail_section_registration_test.dart \
  test/features/camporees/presentation/widgets/camporee_section_registration_sheet_test.dart
```

**Step 3: Implement the status panel**

Place `CamporeeSectionRegistrationPanel` before `_MembersSection`. It must render:

- club and section names;
- textual status plus icon;
- actor/date for registered or approved;
- blocking explanation;
- retry for network errors;
- director CTA only when `canEnroll`.

Use `SacButton`, `HugeIcons`, `context.sac`, the 8pt spacing scale and minimum 48dp targets. Use `Semantics` so status is not color-only.

**Step 4: Implement the confirmation sheet**

The sheet shows immutable context, deadline/cost and “Registrarás esta inscripción como director”. Confirm is disabled while loading and calls the notifier once. Use a 150–250ms transform/opacity transition and safe areas; no perpetual animation.

**Step 5: Gate participants**

Replace the unconditional “Inscribir participantes” action:

```dart
if (registration.enablesParticipants) {
  return enabledMembersSection;
}
return blockedMembersSection(
  pending: registration.status == pendingApproval,
);
```

The backend remains authoritative; this gate is UX, not security.

**Step 6: Remove the technical-ID flow**

Delete the manual `TextEditingController`/`TextFormField` path. Remove the standalone GoRouter route if the sheet fully replaces it, or repurpose it only if deep-link requirements demand a full screen. No UI may ask for `club_section_id`.

**Step 7: Verify GREEN, accessibility and commit**

```bash
flutter test \
  test/features/camporees/presentation/views/camporee_detail_section_registration_test.dart \
  test/features/camporees/presentation/widgets/camporee_section_registration_sheet_test.dart
flutter analyze
dart format lib/features/camporees lib/core/config \
  test/features/camporees
git diff --check
git add lib/features/camporees lib/core/config \
  assets/translations test/features/camporees
git commit -m "feat(camporees): add director section enrollment flow"
```

Validate this task on an iOS and Android device/emulator using hot reload. Do not run a build.

---

### Task 9: Synchronize canonical documentation

**Files:**
- Modify: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- Modify: `docs/api/FRONTEND-INTEGRATION-GUIDE.md`
- Modify: `docs/database/SCHEMA-REFERENCE.md`
- Modify: `docs/database/schema.prisma`
- Modify: `docs/features/camporees.md`

**Step 1: Write the documentation delta**

Document:

- GET/POST contextual contracts and example responses;
- director-only permission;
- no request body or client-supplied section ID;
- state/disposition semantics;
- participant preconditions and errors;
- `camporee_members.camporee_club_id` lineage;
- legacy generic endpoint scope.

**Step 2: Verify references**

```bash
rg -n "section-registration|camporees:register_active_section|camporee_club_id" \
  docs/api docs/database docs/features
git diff --check
```

Expected: every contract/schema behavior appears in its canonical surface; no stale statement says participants can register before section enrollment.

**Step 3: Commit**

```bash
git add docs/api/ENDPOINTS-LIVE-REFERENCE.md \
  docs/api/FRONTEND-INTEGRATION-GUIDE.md \
  docs/database/SCHEMA-REFERENCE.md docs/database/schema.prisma \
  docs/features/camporees.md
git commit -m "docs(camporees): document section enrollment contract"
```

Coordinate with any concurrent edit already present in `ENDPOINTS-LIVE-REFERENCE.md`; merge content, never overwrite it.

---

### Task 10: Full verification and environment rollout

**Files:** No new source files unless verification exposes a defect.

**Step 1: Verify backend without build**

```bash
pnpm exec jest src/camporees/camporees.controller.spec.ts \
  src/camporees/camporees.service.spec.ts \
  src/common/guards/permissions-metadata.spec.ts --runInBand
pnpm test:e2e -- --runInBand test/camporees.e2e-spec.ts
pnpm exec prisma validate --schema prisma/schema.prisma
git diff --check
```

Expected: all selected suites PASS, Prisma valid, diff clean.

**Step 2: Verify Flutter without build**

```bash
flutter test test/features/camporees
flutter analyze
git diff --check
```

Expected: all Camporees tests PASS and analyzer reports no issues.

**Step 3: Validate on devices**

Using hot reload only, verify on iOS and Android:

1. director sees section context and CTA;
2. another role sees read-only guidance;
3. no editable ID exists;
4. double tap creates one enrollment;
5. pending state blocks participants;
6. approved/registered state enables participants;
7. large text and screen reader semantics remain usable;
8. offline mutation reports a recoverable error.

**Step 4: Preflight migration duplicates per environment**

Run the duplicate query against development, then staging, then production:

```sql
SELECT camporee_id, club_section_id, COUNT(*)
FROM camporee_clubs
WHERE camporee_id IS NOT NULL AND active = TRUE
GROUP BY camporee_id, club_section_id
HAVING COUNT(*) > 1;
```

Repeat for `union_camporee_id`. Expected: zero rows. STOP on any result.

**Step 5: Apply migrations in order**

```bash
pnpm exec prisma migrate deploy --schema prisma/schema.prisma
pnpm exec prisma migrate status --schema prisma/schema.prisma
```

Apply and smoke-test development first, staging second, production last. Production requires successful staging evidence. Never source `.env` as shell; use dotenv/Neon connection strings safely.

**Step 6: Smoke-test contract**

With environment-specific director credentials:

- GET returns active section state;
- POST writes exactly one enrollment and actor;
- participant registration remains blocked until eligible;
- repeated POST returns the same enrollment;
- health endpoint remains healthy.

**Step 7: Final commit only if verification required fixes**

```bash
git add <only-files-fixed-during-verification>
git commit -m "fix(camporees): address section enrollment verification"
```

Do not create an empty commit.

---

## Completion criteria

- [ ] Only the active section director can mutate contextual registration.
- [ ] No mobile request supplies a section ID or actor ID.
- [ ] Registration is idempotent and records `registered_by`.
- [ ] Participants require an enrolled/approved section and same-section membership.
- [ ] New participants persist `camporee_club_id`.
- [ ] Other roles receive read-only UI.
- [ ] All loading, empty, blocked, pending, success and error states are tested.
- [ ] Backend, app and canonical docs agree.
- [ ] No builds were executed.
- [ ] Development, staging and production migrations are independently verified.
