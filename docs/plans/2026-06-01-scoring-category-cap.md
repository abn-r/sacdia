# Scoring Category System Cap Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Enforce a system-wide configurable maximum for unit scoring category points, defaulting to 20, migrate existing category caps above 20 down to 20, and communicate the cap clearly in the admin UI.

**Architecture:** `system_config` is the source of truth for the cap (`scoring.category_max_points_cap`). Backend validation remains authoritative: category create/update must reject values above the configured cap, while the admin reads the cap to constrain inputs and show a clear legend. Mobile continues consuming `max_points` from scoring categories, with a UX follow-up to avoid only `+1/-1` entry.

**Tech Stack:** NestJS + Prisma + Jest in `sacdia-backend`; Next.js + TypeScript + Vitest in `sacdia-admin`; Flutter/Riverpod in `sacdia-app`.

---

## Design Decisions

- Config key: `scoring.category_max_points_cap`.
- Default value: `20`.
- Existing `scoring_categories.max_points > 20` must be migrated to `20`.
- Backend must enforce the cap on create/update. Admin validation is UX only.
- Admin scoring category forms must show a legend: “Puntaje máximo permitido por el sistema: N puntos por aspecto.”
- Historical weekly records are not rewritten in this change. They are operational records and changing them would alter past results.
- Do not run builds. Use targeted tests/analyze only.

---

### Task 1: Add backend cap config and migration

**Files:**
- Create: `sacdia-backend/prisma/migrations/20260601090000_scoring_category_cap/migration.sql`
- Modify if needed: `sacdia-backend/prisma/seeds/system-config.seed.sql`

**Step 1: Write migration SQL**

Create migration with:

```sql
-- Seed system-wide cap for scoring category max points.
INSERT INTO system_config (config_key, config_value, description, config_type)
VALUES (
  'scoring.category_max_points_cap',
  '20',
  'Maximum allowed max_points for unit scoring categories/aspects.',
  'number'
)
ON CONFLICT (config_key) DO UPDATE
SET
  config_value = EXCLUDED.config_value,
  description = EXCLUDED.description,
  config_type = EXCLUDED.config_type;

-- Normalize existing category caps above the new system maximum.
UPDATE scoring_categories
SET max_points = 20
WHERE max_points > 20;
```

**Step 2: Update seed file if it is the canonical seed path**

If `sacdia-backend/prisma/seeds/system-config.seed.sql` contains the current system config seeds, add the same config row there using `ON CONFLICT`.

**Step 3: Verify migration text only**

Run:

```bash
git diff -- sacdia-backend/prisma/migrations/20260601090000_scoring_category_cap/migration.sql sacdia-backend/prisma/seeds/system-config.seed.sql
```

Expected: only the config seed and `UPDATE scoring_categories` migration appear.

**Step 4: Commit**

```bash
git add sacdia-backend/prisma/migrations/20260601090000_scoring_category_cap/migration.sql sacdia-backend/prisma/seeds/system-config.seed.sql
git commit -m "feat: add scoring category cap config"
```

---

### Task 2: Enforce cap in backend scoring category service

**Files:**
- Modify: `sacdia-backend/src/scoring-categories/scoring-categories.service.ts`
- Modify: `sacdia-backend/src/scoring-categories/scoring-categories.service.spec.ts`
- Potentially modify: `sacdia-backend/src/scoring-categories/dto/scoring-categories.dto.ts`
- Potentially modify: `sacdia-backend/src/common/errors/error-codes.ts` and i18n error files if a specific error code is needed

**Step 1: Write failing service tests**

Add tests to `ScoringCategoriesService` that verify:

1. `createDivisionCategory` rejects `max_points` above `system_config.scoring.category_max_points_cap`.
2. `updateLocalFieldCategory` rejects `max_points` above the cap.
3. Missing or invalid config falls back to `20`.
4. Values equal to the cap are accepted.

Mock additions needed:

```ts
system_config: {
  findUnique: jest.fn(),
},
```

Example failing test shape:

```ts
it('rejects create when max_points exceeds configured system cap', async () => {
  mockPrisma.system_config.findUnique.mockResolvedValue({
    config_key: 'scoring.category_max_points_cap',
    config_value: '20',
    config_type: 'number',
    description: 'cap',
    updated_at: new Date(),
  });

  await expect(
    service.createDivisionCategory({ name: 'Mega puntaje', max_points: 21 }),
  ).rejects.toMatchObject({
    code: expect.any(String),
  });

  expect(mockTx.scoring_categories.create).not.toHaveBeenCalled();
});
```

**Step 2: Run RED test**

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/scoring-categories/scoring-categories.service.spec.ts --runInBand
```

Expected: new tests fail because cap validation does not exist.

**Step 3: Implement minimal backend validation**

In `ScoringCategoriesService`:

- Add constant:

```ts
private static readonly CATEGORY_MAX_POINTS_CAP_KEY = 'scoring.category_max_points_cap';
private static readonly DEFAULT_CATEGORY_MAX_POINTS_CAP = 20;
```

- Add helper:

```ts
private async getCategoryMaxPointsCap(): Promise<number> {
  const config = await this.prisma.system_config.findUnique({
    where: { config_key: ScoringCategoriesService.CATEGORY_MAX_POINTS_CAP_KEY },
  });

  const parsed = Number(config?.config_value);
  if (!Number.isInteger(parsed) || parsed < 1) {
    return ScoringCategoriesService.DEFAULT_CATEGORY_MAX_POINTS_CAP;
  }
  return parsed;
}

private async assertMaxPointsWithinCap(maxPoints?: number): Promise<void> {
  if (maxPoints === undefined) return;
  const cap = await this.getCategoryMaxPointsCap();
  if (maxPoints > cap) {
    throw new AppBadRequestException(/* choose/add proper ErrorCode */);
  }
}
```

- Call helper before every create/update that accepts `max_points`:
  - `createDivisionCategory`
  - `updateDivisionCategory`
  - `createUnionCategory`
  - `updateUnionCategory`
  - `createLocalFieldCategory`
  - `updateLocalFieldCategory`

**Step 4: Align DTO static max**

Change `@Max(1000)` to either:

- remove static `@Max` and rely on service cap, or
- set `@Max(20)` only if product confirms the cap will not vary above 20.

Recommendation: remove `@Max(1000)` and keep `@Min(1)` because the cap is dynamic.

**Step 5: Run GREEN backend test**

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/scoring-categories/scoring-categories.service.spec.ts --runInBand
```

Expected: PASS.

**Step 6: Commit**

```bash
git add sacdia-backend/src/scoring-categories/scoring-categories.service.ts sacdia-backend/src/scoring-categories/scoring-categories.service.spec.ts sacdia-backend/src/scoring-categories/dto/scoring-categories.dto.ts sacdia-backend/src/common/errors/error-codes.ts sacdia-backend/src/i18n/es/errors.json sacdia-backend/src/i18n/en/errors.json sacdia-backend/src/i18n/fr/errors.json sacdia-backend/src/i18n/pt-BR/errors.json
git commit -m "feat: enforce scoring category cap"
```

---

### Task 3: Expose cap to admin scoring UI

**Files:**
- Modify: `sacdia-admin/src/components/scoring-categories/scoring-category-dialog.tsx`
- Modify: `sacdia-admin/src/components/scoring-categories/scoring-categories-table.tsx`
- Modify: `sacdia-admin/src/components/scoring-categories/division-scoring-categories-page.tsx`
- Modify: `sacdia-admin/src/components/scoring-categories/union-scoring-categories-tab.tsx`
- Modify: `sacdia-admin/src/components/scoring-categories/local-field-scoring-categories-tab.tsx`
- Modify: `sacdia-admin/src/components/scoring-categories/scoring-category-dialog.test.tsx`
- Modify or reuse: `sacdia-admin/src/lib/api/system-config.ts`

**Step 1: Write failing UI tests**

Add tests that render `ScoringCategoryDialog` with `maxPointsCap={20}` and assert:

```ts
expect(screen.getByText(/puntaje máximo permitido por el sistema: 20/i)).toBeInTheDocument();
expect(pointsInput.max).toBe('20');
```

Add validation test:

```ts
fireEvent.change(pointsInput, { target: { value: '21' } });
// submit with valid name
expect(mockToastError).toHaveBeenCalledWith(expect.stringMatching(/20/));
expect(onSave).not.toHaveBeenCalled();
```

**Step 2: Run RED admin test**

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-admin
pnpm exec vitest run src/components/scoring-categories/scoring-category-dialog.test.tsx
```

Expected: FAIL because the dialog does not accept or display a cap.

**Step 3: Add dialog prop**

In `ScoringCategoryDialogProps` add:

```ts
maxPointsCap?: number;
```

Default to 20 if absent:

```ts
const effectiveMaxPointsCap = maxPointsCap ?? 20;
```

Update validation:

```ts
if (!Number.isInteger(maxPoints) || maxPoints < 1 || maxPoints > effectiveMaxPointsCap) {
  toast.error(`El puntaje máximo por aspecto no puede superar ${effectiveMaxPointsCap}.`);
  return;
}
```

Update input:

```tsx
<Input id="sc_max_points" type="number" min={1} max={effectiveMaxPointsCap} ... />
<p className="text-[11px] text-muted-foreground">
  Puntaje máximo permitido por el sistema: {effectiveMaxPointsCap} puntos por aspecto.
</p>
```

**Step 4: Fetch cap in scoring table/page layer**

Keep `ScoringCategoriesTable` reusable by accepting:

```ts
maxPointsCap?: number;
```

Pass it into `ScoringCategoryDialog`.

For the division page and union/local-field tabs, fetch the config through `getSystemConfigs()` or add a small helper:

```ts
export async function getSystemConfigByKey(key: string): Promise<SystemConfig | null>
```

Preferred helper in `sacdia-admin/src/lib/api/system-config.ts`:

```ts
export async function getSystemConfig(key: string): Promise<SystemConfig | null> {
  try {
    return await apiRequest<SystemConfig>(`/system-config/${encodeURIComponent(key)}`);
  } catch {
    return null;
  }
}
```

Use fallback `20` when unavailable.

**Step 5: Show legend in table header too**

Near the scoring category table heading, add visible copy:

```tsx
<p className="text-sm text-muted-foreground">
  Puntaje máximo permitido por el sistema: {maxPointsCap ?? 20} puntos por aspecto.
</p>
```

This satisfies the explicit UX requirement even before opening the dialog.

**Step 6: Run GREEN admin test**

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-admin
pnpm exec vitest run src/components/scoring-categories/scoring-category-dialog.test.tsx
```

Expected: PASS.

**Step 7: Commit**

```bash
git add sacdia-admin/src/components/scoring-categories/scoring-category-dialog.tsx sacdia-admin/src/components/scoring-categories/scoring-categories-table.tsx sacdia-admin/src/components/scoring-categories/division-scoring-categories-page.tsx sacdia-admin/src/components/scoring-categories/union-scoring-categories-tab.tsx sacdia-admin/src/components/scoring-categories/local-field-scoring-categories-tab.tsx sacdia-admin/src/components/scoring-categories/scoring-category-dialog.test.tsx sacdia-admin/src/lib/api/system-config.ts
git commit -m "feat: show scoring cap in admin"
```

---

### Task 4: Add real admin navigation for union/local-field scoring aspects

**Files:**
- Modify: `sacdia-admin/src/components/catalogs/geography-list-client.tsx`
- Modify: `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/geography/unions/page.tsx`
- Modify: `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/geography/local-fields/page.tsx`
- Add/modify tests if a test file already exists for `GeographyListClient`

**Step 1: Write failing UI expectation**

If no existing test exists, add a focused test for `GeographyListClient` verifying that a row can show a “Configurar puntuación” link when enabled.

Expected hrefs:

```txt
/dashboard/catalogs/geography/unions/:id?tab=scoring-categories
/dashboard/catalogs/geography/local-fields/:id?tab=scoring-categories
```

**Step 2: Implement optional scoring action**

Add prop:

```ts
showScoringConfigAction?: boolean;
```

When true and `itemId` exists, show a button/dropdown item:

```tsx
<Link href={`${basePath}/${itemId}?tab=scoring-categories`}>
  Configurar puntuación
</Link>
```

Enable it in:

- unions page
- local-fields page

Do not enable for districts/churches.

**Step 3: Run targeted admin test**

Run relevant Vitest command for the new/changed test file. If no test exists and adding one is too costly because of routing mocks, run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-admin
pnpm exec vitest run src/components/scoring-categories/scoring-category-dialog.test.tsx
```

and manually inspect diff for the navigation link.

**Step 4: Commit**

```bash
git add sacdia-admin/src/components/catalogs/geography-list-client.tsx 'sacdia-admin/src/app/(dashboard)/dashboard/catalogs/geography/unions/page.tsx' 'sacdia-admin/src/app/(dashboard)/dashboard/catalogs/geography/local-fields/page.tsx'
git commit -m "feat: expose scoring configuration navigation"
```

---

### Task 5: Improve mobile point entry UX

**Files:**
- Modify: `sacdia-app/lib/features/units/presentation/views/unit_detail_view.dart`
- Potentially add tests if existing widget tests cover units UI

**Step 1: Write/identify widget test**

Search for existing unit detail widget tests. If none exist, keep this as a manual QA task unless adding app test scaffolding is already established.

**Step 2: Replace passive value with editable control**

In `_CategoryRow`, replace the current value `Container` with a tappable control.

Behavior:

- Still shows `points / category.maxPoints`.
- Tap opens a small dialog/bottom sheet with numeric input.
- Input min: `0`.
- Input max: `category.maxPoints`.
- Confirm calls `onSetValue(value)`.
- Keep `+1/-1` for quick small changes.

Validation copy:

```txt
Ingresá un valor entre 0 y {category.maxPoints}.
```

**Step 3: Run targeted Flutter checks**

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app
dart format --set-exit-if-changed lib/features/units/presentation/views/unit_detail_view.dart
flutter analyze
```

Do not run any build.

**Step 4: Commit**

```bash
git add sacdia-app/lib/features/units/presentation/views/unit_detail_view.dart
git commit -m "feat: allow manual unit score entry"
```

---

### Task 6: Update documentation

**Files:**
- Modify: `docs/canon/runtime-scoring-categories.md`
- Modify: `docs/features/weekly-records.md`
- Modify: `docs/api/ENDPOINTS-LIVE-REFERENCE.md` if endpoint behavior or error contract changes

**Step 1: Document cap policy**

Update scoring categories canon:

- Add `scoring.category_max_points_cap` as the global cap.
- Default is `20`.
- Existing categories above cap are normalized by migration.
- Unions/local-fields can manage their own categories but cannot exceed the cap.

**Step 2: Document weekly-record impact**

Add that weekly record scores remain bounded by each category’s `max_points`, and category `max_points` itself is bounded by system config.

**Step 3: Verify docs diff**

Run:

```bash
git diff -- docs/canon/runtime-scoring-categories.md docs/features/weekly-records.md docs/api/ENDPOINTS-LIVE-REFERENCE.md
```

Expected: docs describe the new cap and admin guidance.

**Step 4: Commit**

```bash
git add docs/canon/runtime-scoring-categories.md docs/features/weekly-records.md docs/api/ENDPOINTS-LIVE-REFERENCE.md
git commit -m "docs: document scoring category cap"
```

---

## Verification Summary

Run only targeted verification, never builds:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec jest src/scoring-categories/scoring-categories.service.spec.ts --runInBand
```

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-admin
pnpm exec vitest run src/components/scoring-categories/scoring-category-dialog.test.tsx
```

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app
dart format --set-exit-if-changed lib/features/units/presentation/views/unit_detail_view.dart
flutter analyze
```

