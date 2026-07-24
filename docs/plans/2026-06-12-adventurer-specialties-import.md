# Adventurer Specialties Import Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Evolve the unified SACDIA honors catalog so Adventurer specialties can be imported, filtered, and related to Adventurer classes without splitting the domain into a separate honors table.

**Architecture:** Keep `honors` as the single catalog of specialties. Move club-type eligibility from a single-column assumption to an explicit many-to-many availability table, and model class curriculum relationships with a separate class-honor join table. Import Adventurer data through an idempotent dry-run-first pipeline that reports collisions, missing assets, and requirement extraction risks before applying DB writes.

**Tech Stack:** NestJS 11, Prisma 7, PostgreSQL, TypeScript, Jest, Cloudflare R2 for runtime assets, existing scraped dataset at `docs/working/aventureros-especialidades/`.

---

## Context and Constraints

- Do **not** create a separate table for Adventurer honors.
- Do **not** run `pnpm run build`; project rule says never build unless explicitly requested later.
- Use conventional commits only if committing.
- Preserve existing Conquistadores/Guías Mayores behavior while introducing a stronger model.
- Current `sacdia-backend/prisma/schema.prisma` has:
  - `honors.name String @unique`
  - `honors.club_type_id Int`
  - `honors.honor_image String`
  - `honors.material_url String`
  - `honor_requirements @@unique([honor_id, requirement_number])`
- Current extraction artifacts:
  - `/Users/abner/Documents/development/sacdia/docs/working/aventureros-especialidades/index.csv`
  - `/Users/abner/Documents/development/sacdia/docs/working/aventureros-especialidades/images/`
  - `/Users/abner/Documents/development/sacdia/docs/working/aventureros-especialidades/pdf/`
  - `/Users/abner/Documents/development/sacdia/docs/working/aventureros-especialidades/md/`
  - `/Users/abner/Documents/development/sacdia/docs/working/aventureros-especialidades/raw/`

## Target Data Model

### Keep

```text
honors
honor_requirements
honors_categories
classes
club_types
```

### Add

```text
honor_club_types
- honor_club_type_id
- honor_id
- club_type_id
- active
- created_at
- modified_at
- UNIQUE(honor_id, club_type_id)
```

Purpose: who can see/take an honor.

```text
class_honors
- class_honor_id
- class_id
- honor_id
- relation_type: REQUIRED | RECOMMENDED | ELECTIVE
- active
- created_at
- modified_at
- UNIQUE(class_id, honor_id, relation_type)
```

Purpose: which specialties are tied to a class or curriculum requirement.

### Modify

```text
honors
- add code String? initially nullable
- later make code required after backfill
- change uniqueness strategy from global name to stable code
```

Recommended staged uniqueness:

1. Add nullable `code`.
2. Backfill existing honors with deterministic codes.
3. Add unique index on `code`.
4. Drop or relax global unique constraint on `name` only after code is populated.

This avoids breaking existing rows during migration.

---

## Task 1: Add failing tests for honor club-type filtering

**Files:**
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/honors/honors.service.spec.ts`
- Reference: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/honors/honors.service.ts`

**Step 1: Write failing service tests**

Add tests proving `clubTypeId` filters through `honor_club_types`, not just `honors.club_type_id`.

Test cases:

```ts
it('filters honors by many-to-many club type applicability', async () => {
  prisma.honors.findMany.mockResolvedValue([]);
  prisma.honors.count.mockResolvedValue(0);

  await service.findAll({ clubTypeId: 1 });

  expect(prisma.honors.findMany).toHaveBeenCalledWith(
    expect.objectContaining({
      where: expect.objectContaining({
        active: true,
        honor_club_types: {
          some: {
            club_type_id: 1,
            active: true,
          },
        },
      }),
    }),
  );
});
```

Also add grouped catalog equivalent for `getGroupedByCategory`.

**Step 2: Run test to verify it fails**

Run from `/Users/abner/Documents/development/sacdia/sacdia-backend`:

```bash
pnpm exec jest src/honors/honors.service.spec.ts --runInBand
```

Expected: FAIL because `honors.service.ts` still filters with `club_type_id`.

**Step 3: Do not implement yet**

Commit later with Task 3 after schema + service update.

---

## Task 2: Create Prisma migration for applicability and class relationships

**Files:**
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/prisma/schema.prisma`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/prisma/migrations/20260612000000_honor_applicability_and_class_links/migration.sql`
- Modify if needed after Prisma generate: generated Prisma client is not committed.

**Step 1: Add enum and models to Prisma schema**

Add:

```prisma
enum class_honor_relation_type_enum {
  REQUIRED
  RECOMMENDED
  ELECTIVE
}

model honor_club_types {
  honor_club_type_id Int        @id @default(autoincrement())
  honor_id           Int
  club_type_id       Int
  active             Boolean    @default(true)
  created_at         DateTime   @default(now()) @db.Timestamptz(6)
  modified_at        DateTime   @default(now()) @db.Timestamptz(6)

  honor     honors     @relation(fields: [honor_id], references: [honor_id], onDelete: Cascade, onUpdate: NoAction)
  club_type club_types @relation(fields: [club_type_id], references: [club_type_id], onDelete: Cascade, onUpdate: NoAction)

  @@unique([honor_id, club_type_id])
  @@index([club_type_id])
}

model class_honors {
  class_honor_id Int                            @id @default(autoincrement())
  class_id       Int
  honor_id       Int
  relation_type  class_honor_relation_type_enum @default(RECOMMENDED)
  active         Boolean                        @default(true)
  created_at     DateTime                       @default(now()) @db.Timestamptz(6)
  modified_at    DateTime                       @default(now()) @db.Timestamptz(6)

  class classes @relation(fields: [class_id], references: [class_id], onDelete: Cascade, onUpdate: NoAction)
  honor honors  @relation(fields: [honor_id], references: [honor_id], onDelete: Cascade, onUpdate: NoAction)

  @@unique([class_id, honor_id, relation_type])
  @@index([honor_id])
}
```

Update relations:

```prisma
model honors {
  code             String? @unique @db.VarChar(120)
  honor_club_types honor_club_types[]
  class_honors     class_honors[]
}

model club_types {
  honor_club_types honor_club_types[]
}

model classes {
  class_honors class_honors[]
}
```

**Step 2: Write migration SQL**

Migration must:

1. Create enum `class_honor_relation_type_enum`.
2. Add nullable `code` to `honors`.
3. Create `honor_club_types`.
4. Create `class_honors`.
5. Backfill `honor_club_types` from existing `honors.club_type_id`.
6. Backfill `honors.code` for existing rows.

Backfill code pattern:

```sql
UPDATE "honors"
SET "code" = concat(
  'LEGACY-',
  "honor_id"::text,
  '-',
  regexp_replace(
    lower(unaccent("name")),
    '[^a-z0-9]+',
    '-',
    'g'
  )
)
WHERE "code" IS NULL;
```

If `unaccent` is not installed or not allowed, use a simpler safe code:

```sql
UPDATE "honors"
SET "code" = concat('LEGACY-', "honor_id"::text)
WHERE "code" IS NULL;
```

Prefer the simple safe code if production extension support is unknown.

**Step 3: Do not drop `honors.club_type_id` yet**

Keep it as legacy compatibility during rollout. The service will read from `honor_club_types`, but old admin paths may still write `club_type_id` until updated.

**Step 4: Run schema validation only**

Run from `/Users/abner/Documents/development/sacdia/sacdia-backend`:

```bash
pnpm exec prisma validate
```

Expected: Prisma schema is valid.

**Step 5: Commit**

```bash
git add prisma/schema.prisma prisma/migrations/20260612000000_honor_applicability_and_class_links/migration.sql
git commit -m "feat(honors): add applicability and class links"
```

---

## Task 3: Update catalog filtering to use applicability table

**Files:**
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/honors/honors.service.ts`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/honors/honors.service.spec.ts`

**Step 1: Update `where` builder**

Replace:

```ts
...(filters?.clubTypeId && { club_type_id: filters.clubTypeId }),
```

With:

```ts
...(filters?.clubTypeId && {
  honor_club_types: {
    some: {
      club_type_id: filters.clubTypeId,
      active: true,
    },
  },
}),
```

Apply this in both `findAll` and `getGroupedByCategory`.

**Step 2: Include applicability data where useful**

In catalog responses, include a compact list for future UI/admin use:

```ts
honor_club_types: {
  where: { active: true },
  select: {
    club_type_id: true,
    club_type: { select: { name: true } },
  },
},
```

Keep legacy `club_types` include for backward compatibility until clients are updated.

**Step 3: Run targeted tests**

Run:

```bash
pnpm exec jest src/honors/honors.service.spec.ts --runInBand
```

Expected: PASS.

**Step 4: Commit**

```bash
git add src/honors/honors.service.ts src/honors/honors.service.spec.ts
git commit -m "fix(honors): filter catalog by applicability"
```

---

## Task 4: Add dry-run importer for Adventurer specialties

**Files:**
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/scripts/import-adventurer-specialties.ts`
- Test: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/honors/adventurer-specialties-importer.spec.ts`
- Read input: `/Users/abner/Documents/development/sacdia/docs/working/aventureros-especialidades/index.csv`
- Read input: `/Users/abner/Documents/development/sacdia/docs/working/aventureros-especialidades/md/*.md`

**Step 1: Write importer unit tests first**

Test pure helpers:

- CSV parser reads 175 rows.
- `buildHonorCode(row)` produces stable codes:

```ts
ADV-CORDERITOS-ALIMENTOS-SANOS
ADV-CASTORCITOS-AMIGOS-DE-LA-BIBLIA
ADV-ABEJITA-INDUSTRIOSA-LECTURA-I
```

- Duplicate display names are allowed if codes differ.
- Missing `image_url`, `source_url`, or markdown path becomes a dry-run error.
- Requirements parser reads markdown numbered requirements under `## Requisitos detectados`.

**Step 2: Implement dry-run mode**

Default behavior must be dry-run:

```bash
pnpm exec tsx scripts/import-adventurer-specialties.ts --dry-run
```

Output summary:

```text
Adventurer specialties import dry-run
- rows read: 175
- new honors: N
- existing honors by code: N
- display-name collisions: N
- class links to create: N
- requirements to create/update: N
- missing assets: N
- warnings: N
```

The script must exit non-zero if:

- dataset path missing;
- `Aventureros` club type missing;
- duplicate generated code;
- required source file missing;
- asset URL placeholder missing.

**Step 3: Do not write to DB in dry-run**

Dry-run may read:

```ts
prisma.club_types.findFirst({ where: { name: 'Aventureros' } })
prisma.classes.findMany({ where: { club_types: { name: 'Aventureros' } } })
prisma.honors.findMany({ where: { code: { in: codes } } })
```

It must not call create/update/upsert unless `--apply` is passed.

**Step 4: Run importer tests**

Run:

```bash
pnpm exec jest src/honors/adventurer-specialties-importer.spec.ts --runInBand
```

Expected: PASS.

**Step 5: Run dry-run**

Run:

```bash
pnpm exec tsx scripts/import-adventurer-specialties.ts --dry-run
```

Expected: summary with no DB writes.

**Step 6: Commit**

```bash
git add scripts/import-adventurer-specialties.ts src/honors/adventurer-specialties-importer.spec.ts
git commit -m "feat(honors): add adventurer specialties dry-run importer"
```

---

## Task 5: Decide and implement asset URL strategy

**Files:**
- Modify if using existing storage helpers: `/Users/abner/Documents/development/sacdia/sacdia-backend/src/common/storage/*`
- Or create script: `/Users/abner/Documents/development/sacdia/sacdia-backend/scripts/upload-adventurer-specialty-assets.ts`
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/.env.example` only if new env names are required.

**Step 1: Prefer existing R2 env names**

Do not create new buckets unless necessary. Prefer existing R2 configuration and a dedicated prefix:

```text
honors/adventurers/images/{code}.png
honors/adventurers/materials/{code}.pdf
```

**Step 2: Upload assets before DB apply**

The importer should consume a generated manifest:

```json
{
  "ADV-CORDERITOS-ALIMENTOS-SANOS": {
    "imageUrl": "https://.../honors/adventurers/images/ADV-CORDERITOS-ALIMENTOS-SANOS.png",
    "materialUrl": "https://.../honors/adventurers/materials/ADV-CORDERITOS-ALIMENTOS-SANOS.pdf"
  }
}
```

**Step 3: Add `--manifest` validation**

The importer must require manifest URLs in `--apply` mode.

Dry-run can use source URLs from guiasmayores.com for reporting, but apply should use SACDIA-controlled URLs.

**Step 4: Test manifest validation**

Run:

```bash
pnpm exec jest src/honors/adventurer-specialties-importer.spec.ts --runInBand
```

Expected: PASS.

---

## Task 6: Apply importer with idempotent writes

**Files:**
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/scripts/import-adventurer-specialties.ts`

**Step 1: Implement `--apply` only after dry-run is clean**

Write sequence in one transaction per honor:

1. Upsert `honors` by `code`.
2. Upsert `honor_club_types` for `Aventureros`.
3. Upsert `class_honors` when a class mapping exists.
4. Replace or upsert `honor_requirements` by `(honor_id, requirement_number)`.

**Step 2: Preserve `honors.club_type_id` compatibility**

For Adventurer specialties, set legacy `honors.club_type_id` to Adventurer club type id.

For existing Conquistador/GM shared honors, do not change `club_type_id` yet; backfill applicability from existing value in migration.

**Step 3: Use safe class mapping**

Map extraction `level_order` to class names. Dry-run must report missing class matches.

Initial expected mapping:

```text
preescolar -> Corderito
jardin -> Castorcito
grado-1 -> Abejita Industriosa
grado-2 -> Rayito de Sol
grado-3 -> Constructor
grado-4 -> Manitas Ayudadoras
multinivel -> no single class link unless explicitly configured
```

If class names in DB differ, the script should print missing mappings and block `--apply` unless a mapping JSON is provided.

**Step 4: Run apply only with explicit user approval**

Do not run this until approved:

```bash
pnpm exec tsx scripts/import-adventurer-specialties.ts --apply --manifest ./tmp/adventurer-assets-manifest.json
```

Expected: DB writes summary and idempotency report.

---

## Task 7: Update API/docs for new contract

**Files:**
- Modify: `/Users/abner/Documents/development/sacdia/docs/features/honores.md`
- Modify: `/Users/abner/Documents/development/sacdia/docs/database/SCHEMA-REFERENCE.md`
- Modify: `/Users/abner/Documents/development/sacdia/docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- Optionally add ADR: `/Users/abner/Documents/development/sacdia/docs/api/ARCHITECTURE-DECISIONS.md`

**Step 1: Update domain docs**

Document:

- `honors` remains the unified catalog.
- `honor_club_types` controls visibility/eligibility.
- `class_honors` controls curriculum/class relationship.
- `honors.club_type_id` is legacy compatibility during rollout.

**Step 2: Update API docs**

For `GET /api/v1/honors` and `GET /api/v1/honors/grouped-by-category`, document:

- `clubTypeId` now filters by applicability.
- responses may include `honor_club_types`/applicability when exposed.

**Step 3: Run docs consistency check if relevant**

From workspace root:

```bash
node scripts/verify-api-docs-consistency.mjs
```

Expected: PASS or documented known mismatch.

**Step 4: Commit**

```bash
git add docs/features/honores.md docs/database/SCHEMA-REFERENCE.md docs/api/ENDPOINTS-LIVE-REFERENCE.md
git commit -m "docs(honors): document specialty applicability model"
```

---

## Task 8: Client follow-up plan

**Files to inspect before implementation:**
- `/Users/abner/Documents/development/sacdia/sacdia-admin/src/lib/api/honors.ts`
- `/Users/abner/Documents/development/sacdia/sacdia-admin/src/components/honors/honors-crud-page.tsx`
- `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/honors/data/models/honor_model.dart`
- `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/honors/presentation/views/honors_catalog_view.dart`

**Client behavior expected after backend rollout:**

- Admin can eventually manage applicability and class links.
- App filters honors by active club section/type.
- Adventurer members see only Adventurer specialties.
- Conquistadores and Guías Mayores keep seeing shared specialties.

Do not implement client changes in the first backend migration unless required by API response breakage.

---

## Rollout Strategy

1. Add tables and backfill applicability from existing `honors.club_type_id`.
2. Update reads to use `honor_club_types`.
3. Keep legacy `honors.club_type_id` during compatibility window.
4. Add dry-run importer and validate data quality.
5. Upload assets to R2 and generate manifest.
6. Apply import only after dry-run is clean.
7. Update admin/app UI in a separate follow-up if needed.
8. Later migration: consider making `honors.code` required and dropping global `name` uniqueness.

## Risk Register

| Risk | Impact | Mitigation |
|---|---|---|
| Global `honors.name` uniqueness blocks duplicate Adventurer names | Import failure | Add stable `honors.code`; defer dropping name uniqueness until backfill verified |
| Existing filters assume `honors.club_type_id` | Wrong catalog visibility | Backfill `honor_club_types` and update service filters |
| Local asset paths are not runtime-safe | Broken images/materials | Upload to R2 and use manifest in apply mode |
| Requirement extraction is heuristic | Bad checklist UX | Mark import as preliminary; allow review/correction before final apply |
| Class names differ from extraction labels | Broken class links | Dry-run reports missing class mappings and supports mapping JSON |

## Verification Checklist

- [ ] Prisma schema validates.
- [ ] Migration backfills one applicability row per existing honor.
- [ ] `GET /honors?clubTypeId=...` uses applicability.
- [ ] Existing Conquistador/GM catalog tests still pass.
- [ ] Dry-run reads 175 Adventurer rows.
- [ ] Dry-run reports duplicate display names without failing if generated codes differ.
- [ ] Apply mode refuses to run without SACDIA asset manifest.
- [ ] No build executed.

