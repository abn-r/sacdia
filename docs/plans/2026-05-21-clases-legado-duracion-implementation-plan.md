# Clases de Legado y Duración Configurable Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implementar clases progresivas con disponibilidad temporal, duración mínima/máxima por año eclesiástico, vencimiento formal de enrollments y preservación de trayectoria histórica.

**Architecture:** Separar tres conceptos que hoy están mezclados: disponibilidad para iniciar una clase, ventana para terminar una clase ya iniciada, y trayectoria histórica del miembro. La disponibilidad vive en `classes`, la cursada sigue viviendo en `enrollments`, y la investidura valida duración/progreso antes de entrar al pipeline.

**Tech Stack:** NestJS 11 + Prisma 7 + PostgreSQL, Next.js 16 admin, Flutter/Riverpod app, Jest/Vitest/flutter_test, documentación SACDIA en `docs/`.

---

## Reglas de dominio aprobadas

1. `classes.available_until_year_id = NULL` significa “sin expiración programada”. No usar años mágicos tipo 2100.
2. Una clase con `available_until_year_id` apuntando al año eclesiástico 2026 puede aceptar nuevos ingresos hasta ese año inclusive.
3. Que una clase deje de aceptar nuevos ingresos NO cancela a quienes ya iniciaron.
4. La duración se cuenta por años eclesiásticos desde `enrollments.ecclesiastical_year_id`, no por `enrollment_date`.
5. Defaults: `min_duration_years = 1`, `max_duration_years = 1`.
6. Excepciones como Guía Mayor Instructor/Avanzado se configuran con duración plurianual.
7. Al superar `max_duration_years` sin investidura, el enrollment queda formalmente vencido, pero conserva progreso.
8. El progreso histórico nunca se borra: SACDIA modela trayectoria de vida.

## Guardrails

- No ejecutar builds. Prohibido `pnpm build`, `flutter build`, `next build` salvo pedido explícito posterior.
- Mantener conventional commits si se commitea.
- No agregar `Co-Authored-By` ni atribución IA.
- Actualizar docs en el mismo trabajo si cambia schema, endpoint, DTO o flujo.
- Hacer TDD con tests focalizados antes de implementación.

---

## Diseño de datos propuesto

### `classes`

Agregar:

```prisma
available_from_year_id  Int?
available_until_year_id Int?
min_duration_years      Int @default(1)
max_duration_years      Int @default(1)
```

Relaciones sugeridas:

```prisma
available_from_year  ecclesiastical_years? @relation("classes_available_from_year", fields: [available_from_year_id], references: [year_id], onDelete: SetNull, onUpdate: NoAction)
available_until_year ecclesiastical_years? @relation("classes_available_until_year", fields: [available_until_year_id], references: [year_id], onDelete: SetNull, onUpdate: NoAction)
```

Índices sugeridos:

```prisma
@@index([available_from_year_id], map: "idx_classes_available_from_year")
@@index([available_until_year_id], map: "idx_classes_available_until_year")
@@index([club_type_id, active], map: "idx_classes_club_type_active")
```

Check constraints en SQL migration:

```sql
ALTER TABLE classes
  ADD CONSTRAINT chk_classes_duration_positive
  CHECK (min_duration_years >= 1 AND max_duration_years >= 1),
  ADD CONSTRAINT chk_classes_duration_range
  CHECK (max_duration_years >= min_duration_years);
```

### `investiture_status_enum`

Agregar estado:

```prisma
EXPIRED
```

Nota: Prisma/Postgres enum requiere migration SQL cuidadosa.

### `investiture_action_enum`

Agregar acción histórica:

```prisma
EXPIRED
```

Razón: si marcamos vencimiento formal, también debe quedar audit trail en `investiture_validation_history`.

---

## Cálculo de años eclesiásticos

No comparar `year_id` como si fuera el año calendario. `year_id` es autoincremental.

Crear helper backend que compare por `ecclesiastical_years.start_date`:

```ts
type YearWindow = {
  startYearId: number;
  currentYearId: number;
};

async function getElapsedEcclesiasticalYearCount({ startYearId, currentYearId }: YearWindow): Promise<number> {
  const [startYear, currentYear] = await prisma.ecclesiastical_years.findMany(...);
  // Count years with start_date >= start.start_date and start_date <= current.start_date.
  // Inclusive: start 2026/current 2026 => 1.
}
```

Expected examples:

- start 2026, current 2026 → `1`
- start 2026, current 2027 → `2`
- start 2026, current 2028 → `3`
- start 2026, current 2029 → `4`

---

## Task 1: Backend schema migration

**Files:**
- Modify: `sacdia-backend/prisma/schema.prisma`
- Create: `sacdia-backend/prisma/migrations/YYYYMMDDHHMMSS_class_duration_availability/migration.sql`
- Modify if present/needed: `docs/database/schema.prisma`
- Modify: `docs/database/SCHEMA-REFERENCE.md`

**Step 1: Write migration SQL**

Add nullable availability columns and duration defaults:

```sql
ALTER TABLE classes
  ADD COLUMN available_from_year_id INT NULL,
  ADD COLUMN available_until_year_id INT NULL,
  ADD COLUMN min_duration_years INT NOT NULL DEFAULT 1,
  ADD COLUMN max_duration_years INT NOT NULL DEFAULT 1;

ALTER TABLE classes
  ADD CONSTRAINT fk_classes_available_from_year
  FOREIGN KEY (available_from_year_id)
  REFERENCES ecclesiastical_years(year_id)
  ON DELETE SET NULL ON UPDATE NO ACTION;

ALTER TABLE classes
  ADD CONSTRAINT fk_classes_available_until_year
  FOREIGN KEY (available_until_year_id)
  REFERENCES ecclesiastical_years(year_id)
  ON DELETE SET NULL ON UPDATE NO ACTION;

ALTER TABLE classes
  ADD CONSTRAINT chk_classes_duration_positive
  CHECK (min_duration_years >= 1 AND max_duration_years >= 1),
  ADD CONSTRAINT chk_classes_duration_range
  CHECK (max_duration_years >= min_duration_years);

CREATE INDEX idx_classes_available_from_year ON classes(available_from_year_id);
CREATE INDEX idx_classes_available_until_year ON classes(available_until_year_id);
```

Add enum values:

```sql
ALTER TYPE investiture_status_enum ADD VALUE IF NOT EXISTS 'EXPIRED';
ALTER TYPE investiture_action_enum ADD VALUE IF NOT EXISTS 'EXPIRED';
```

**Step 2: Update Prisma schema**

Add fields/relations to `model classes` and enum values.

**Step 3: Verify Prisma schema without build**

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm exec prisma validate
```

Expected: schema validates.

**Step 4: Commit**

```bash
git add prisma/schema.prisma prisma/migrations docs/database/schema.prisma docs/database/SCHEMA-REFERENCE.md
git commit -m "feat(classes): add duration and availability schema"
```

---

## Task 2: Backend class availability helpers and public catalog filtering

**Files:**
- Modify: `sacdia-backend/src/classes/classes.service.ts`
- Modify: `sacdia-backend/src/classes/classes.service.spec.ts`
- Modify: `sacdia-backend/src/classes/dto/classes.dto.ts` if query DTOs are introduced
- Modify: `sacdia-backend/src/common/errors/error-codes.ts`

**Step 1: Write failing tests**

Add tests for:

1. `findAll` excludes a class whose `available_until_year` ended before current active year.
2. `findAll` includes classes where `available_until_year_id` is `NULL`.
3. `enrollUser` rejects unavailable class even if `class_id` is known.
4. `enrollUser` allows a class available through the target `ecclesiasticalYearId`.

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm test -- classes.service.spec.ts --runInBand
```

Expected: new tests fail.

**Step 2: Add error codes**

In `sacdia-backend/src/common/errors/error-codes.ts` add:

```ts
CLASS_NOT_AVAILABLE_FOR_YEAR = 'CLASS_NOT_AVAILABLE_FOR_YEAR',
CLASS_DURATION_INVALID = 'CLASS_DURATION_INVALID',
```

**Step 3: Implement availability check**

Add private helper in `ClassesService`:

```ts
private async assertClassAvailableForYear(
  tx: Prisma.TransactionClient,
  classId: number,
  ecclesiasticalYearId: number,
): Promise<void> {
  const targetClass = await tx.classes.findUnique({
    where: { class_id: classId },
    select: {
      class_id: true,
      active: true,
      available_from_year_id: true,
      available_until_year_id: true,
      available_from_year: { select: { start_date: true } },
      available_until_year: { select: { start_date: true } },
    },
  });

  if (!targetClass || !targetClass.active) {
    throw new AppNotFoundException(ErrorCode.CLASS_NOT_FOUND);
  }

  const targetYear = await tx.ecclesiastical_years.findUnique({
    where: { year_id: ecclesiasticalYearId },
    select: { start_date: true },
  });

  if (!targetYear) {
    throw new AppNotFoundException(ErrorCode.CLASS_ACTIVE_YEAR_NOT_FOUND);
  }

  if (targetClass.available_from_year?.start_date && targetYear.start_date < targetClass.available_from_year.start_date) {
    throw new AppBadRequestException(ErrorCode.CLASS_NOT_AVAILABLE_FOR_YEAR);
  }

  if (targetClass.available_until_year?.start_date && targetYear.start_date > targetClass.available_until_year.start_date) {
    throw new AppBadRequestException(ErrorCode.CLASS_NOT_AVAILABLE_FOR_YEAR);
  }
}
```

Use it at the start of `enrollUser` inside the transaction.

**Step 4: Filter `findAll`**

The public catalog should only show startable classes for the active year by default.

Implementation idea:

- Resolve active/current ecclesiastical year.
- Filter `active: true`.
- Include classes where:
  - `available_from_year_id IS NULL OR available_from_year.start_date <= current.start_date`
  - `available_until_year_id IS NULL OR available_until_year.start_date >= current.start_date`

Because Prisma relation filters on self-selected dates may get awkward, prefer a small helper that resolves the current year start date and filters with relation conditions.

**Step 5: Run targeted test**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm test -- classes.service.spec.ts --runInBand
```

Expected: PASS.

**Step 6: Commit**

```bash
git add src/classes src/common/errors/error-codes.ts
git commit -m "feat(classes): enforce class availability by ecclesiastical year"
```

---

## Task 3: Backend duration and enrollment expiration domain logic

**Files:**
- Modify: `sacdia-backend/src/classes/classes.service.ts`
- Modify: `sacdia-backend/src/classes/classes.service.spec.ts`
- Modify: `sacdia-backend/src/investiture/investiture.service.ts`
- Modify: `sacdia-backend/src/investiture/investiture.service.spec.ts`
- Modify: `sacdia-backend/src/common/errors/error-codes.ts`

**Step 1: Add failing duration tests**

In `investiture.service.spec.ts` add tests:

1. Blocks submit if elapsed years `< min_duration_years`.
2. Allows submit if elapsed years is within `[min, max]`.
3. Marks enrollment `EXPIRED` if elapsed years `> max_duration_years` and blocks submit.
4. Does not expire `INVESTIDO` enrollments.
5. Preserves progress records; only updates enrollment status.

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm test -- investiture.service.spec.ts --runInBand
```

Expected: new tests fail.

**Step 2: Add errors**

```ts
INVESTITURE_DURATION_MIN_NOT_MET = 'INVESTITURE_DURATION_MIN_NOT_MET',
INVESTITURE_DURATION_EXPIRED = 'INVESTITURE_DURATION_EXPIRED',
```

**Step 3: Implement helper**

In `InvestitureService`:

```ts
private async getElapsedEcclesiasticalYears(
  startYearId: number,
  currentYearId: number,
): Promise<number> {
  const [startYear, currentYear] = await Promise.all([
    this.prisma.ecclesiastical_years.findUnique({ where: { year_id: startYearId }, select: { start_date: true } }),
    this.prisma.ecclesiastical_years.findUnique({ where: { year_id: currentYearId }, select: { start_date: true } }),
  ]);

  if (!startYear || !currentYear) {
    throw new AppNotFoundException(ErrorCode.CLASS_ACTIVE_YEAR_NOT_FOUND);
  }

  return this.prisma.ecclesiastical_years.count({
    where: {
      start_date: {
        gte: startYear.start_date,
        lte: currentYear.start_date,
      },
    },
  });
}
```

**Step 4: Validate before submission**

In `submitForValidation`, select class duration fields:

```ts
classes: {
  select: {
    min_duration_years: true,
    max_duration_years: true,
  },
},
```

Resolve current active year and compare.

If too early:

```ts
throw new AppBadRequestException(ErrorCode.INVESTITURE_DURATION_MIN_NOT_MET, {
  elapsedYears,
  minDurationYears,
});
```

If expired:

- Update enrollment to `EXPIRED`.
- Set `locked_for_validation: true` or keep false? Recommendation: false for edit/history visibility, but status blocks validation. Do not delete progress.
- Create history entry with `action: EXPIRED`.
- Throw `INVESTITURE_DURATION_EXPIRED`.

**Step 5: Add explicit expiration method**

Add service method, useful for admin/cron/manual flows:

```ts
async expireOverdueEnrollments(currentYearId?: number): Promise<{ expired: number }> { ... }
```

Scope:

- active enrollments
- status in `IN_PROGRESS` or `REJECTED`
- not `INVESTIDO`
- elapsed years > class.max_duration_years

**Step 6: Run tests**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm test -- investiture.service.spec.ts classes.service.spec.ts --runInBand
```

Expected: PASS.

**Step 7: Commit**

```bash
git add src/investiture src/classes src/common/errors/error-codes.ts
git commit -m "feat(investiture): validate class duration before submission"
```

---

## Task 4: Backend admin class config API

**Files:**
- Modify: `sacdia-backend/src/admin/dto/phase-e-catalogs.dto.ts`
- Modify: `sacdia-backend/src/admin/admin-phase-e-catalogs.service.ts`
- Modify: `sacdia-backend/src/admin/admin-phase-e-catalogs.controller.ts` only if docs/swagger text changes
- Modify: `sacdia-backend/src/admin/admin-reference.service.spec.ts` or create focused spec if patterns exist

**Step 1: Write failing admin tests**

Test update accepts:

```json
{
  "available_until_year_id": 2026,
  "min_duration_years": 2,
  "max_duration_years": 3
}
```

Test invalid min/max is rejected by DTO validation or DB constraint.

**Step 2: Extend DTO**

In `CreateClassDto`:

```ts
@ApiPropertyOptional({ example: 2026, nullable: true })
@IsOptional()
@IsInt()
@Min(1)
available_from_year_id?: number | null;

@ApiPropertyOptional({ example: 2026, nullable: true })
@IsOptional()
@IsInt()
@Min(1)
available_until_year_id?: number | null;

@ApiPropertyOptional({ example: 1 })
@IsOptional()
@IsInt()
@Min(1)
min_duration_years?: number;

@ApiPropertyOptional({ example: 1 })
@IsOptional()
@IsInt()
@Min(1)
max_duration_years?: number;
```

**Step 3: Extend create/update service**

In `createClass`, default min/max to 1.

In `updateClass`, preserve null semantics:

- `undefined` → do not change
- `null` → clear availability year
- number → set FK

**Step 4: Run tests**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm test -- admin-phase-e-catalogs.service.spec.ts --runInBand
```

Expected: PASS. If no spec exists, create one and run it directly.

**Step 5: Commit**

```bash
git add src/admin
git commit -m "feat(admin): expose class duration configuration"
```

---

## Task 5: Admin UI for class duration/legacy config

**Files:**
- Modify: `sacdia-admin/src/lib/api/phase-e-catalogs.ts`
- Modify: `sacdia-admin/src/lib/phase-e-catalogs/actions.ts`
- Modify: `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/classes/page.tsx`
- Modify or create: `sacdia-admin/src/components/catalogs/phase-e-catalog-crud-page.tsx`
- Modify: `sacdia-admin/src/components/classes/classes-list.tsx`
- Modify: `sacdia-admin/src/app/(dashboard)/dashboard/classes/[classId]/page.tsx`
- Modify i18n messages under `sacdia-admin/messages/` or current locale path

**Step 1: Write failing tests**

Prefer component/action tests if existing Vitest setup covers similar pages.

Cases:

1. Class form submits `min_duration_years`, `max_duration_years`, `available_until_year_id`.
2. Detail page displays “Sin expiración programada” when null.
3. List shows legacy/available badge based on fields returned by API.

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-admin
pnpm test
```

Expected: failing targeted tests. Do not run build.

**Step 2: Extend API types**

Add to class types:

```ts
available_from_year_id?: number | null;
available_until_year_id?: number | null;
min_duration_years: number;
max_duration_years: number;
availability_status?: 'AVAILABLE' | 'LEGACY' | 'FUTURE';
```

**Step 3: Add form fields**

Because class config now has more than basic name/description, prefer a dedicated class form page/component instead of overloading generic CRUD too far.

Recommended new component:

```text
sacdia-admin/src/components/classes/class-config-form.tsx
```

Fields:

- active
- club type
- minimum age
- display order
- available from year
- available until year
- min duration years
- max duration years
- requires invested GM

Use React Hook Form + Zod.

**Step 4: Add validation**

Zod:

```ts
min_duration_years: z.coerce.number().int().min(1),
max_duration_years: z.coerce.number().int().min(1),
```

Cross-field refine:

```ts
.refine((data) => data.max_duration_years >= data.min_duration_years, {
  path: ['max_duration_years'],
  message: 'La duración máxima debe ser mayor o igual a la mínima.',
})
```

**Step 5: Run tests/lint**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-admin
pnpm test
pnpm exec tsc --noEmit
```

Expected: PASS. Do not run `pnpm build`.

**Step 6: Commit**

```bash
git add src messages
git commit -m "feat(admin): configure class availability and duration"
```

---

## Task 6: Flutter app models and UX states

**Files:**
- Modify: `sacdia-app/lib/features/classes/data/models/class_model.dart`
- Modify: `sacdia-app/lib/features/classes/domain/entities/progressive_class.dart`
- Modify: `sacdia-app/lib/features/classes/data/models/class_with_progress_model.dart`
- Modify: `sacdia-app/lib/features/classes/domain/entities/class_with_progress.dart`
- Modify: `sacdia-app/lib/features/classes/presentation/views/classes_list_view.dart`
- Modify: `sacdia-app/lib/features/profile/presentation/widgets/profile_classes_section.dart`
- Modify: `sacdia-app/lib/features/dashboard/presentation/widgets/current_class_card.dart`
- Modify: `sacdia-app/lib/features/investiture/domain/entities/investiture_status.dart`
- Modify: `sacdia-app/lib/features/investiture/presentation/widgets/investiture_status_badge.dart`

**Step 1: Write failing model tests**

Add/update tests for JSON parsing:

- nullable `available_until_year_id`
- duration fields default/fallback
- `EXPIRED` investiture status

Run:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app
flutter test test/features/classes
```

Expected: fail before implementation.

**Step 2: Update entities/models**

Add fields:

```dart
final int? availableFromYearId;
final int? availableUntilYearId;
final int minDurationYears;
final int maxDurationYears;
```

Add `InvestitureStatus.expired` mapping from `EXPIRED`.

**Step 3: Update UI semantics**

- New enrollment/list views rely on backend filtering, but tolerate explicit status if returned.
- Profile/trayectoria shows expired classes as historical progress, not available to complete.
- Current class card should not present “submit for investiture” if status is expired.

Copy suggestion:

- “Vencida”
- “Esta clase se conserva en tu trayectoria, pero ya no puede completarse para investidura.”

**Step 4: Run tests/analyze**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app
flutter test test/features/classes test/features/investiture
flutter analyze
```

Expected: PASS. Do not run Flutter build.

**Step 5: Commit**

```bash
git add lib test
git commit -m "feat(app): show legacy class trajectory states"
```

---

## Task 7: API docs and feature docs

**Files:**
- Modify: `docs/features/clases-progresivas.md`
- Modify: `docs/features/validacion-investiduras.md`
- Modify: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- Modify: `docs/api/FRONTEND-INTEGRATION-GUIDE.md`
- Modify: `docs/database/SCHEMA-REFERENCE.md`
- Modify: `docs/api-database/backend-service-table-traceability.md` if table/service reads changed materially

**Step 1: Update class feature doc**

Add section:

```md
## Clases legacy y disponibilidad temporal

- `available_until_year_id = NULL` significa sin expiración programada.
- La disponibilidad controla nuevos ingresos, no trayectoria histórica.
- La duración mínima/máxima se calcula por año eclesiástico.
```

**Step 2: Update investiture doc**

Add requirement:

- Submit to validation must enforce configured class duration.
- Expired enrollments cannot enter validation.
- Expired enrollments remain visible as trajectory/progress.

**Step 3: Update endpoint docs**

Document new class fields returned in:

- `GET /api/v1/classes`
- `GET /api/v1/classes/:classId`
- `GET /api/v1/users/:userId/classes`
- admin `GET|POST|PATCH /api/v1/admin/classes`

Document new error codes.

**Step 4: Commit**

```bash
git add docs
git commit -m "docs(classes): document legacy availability and duration rules"
```

---

## Task 8: End-to-end targeted verification without builds

**Files:**
- No production file changes unless tests reveal a bug.

**Step 1: Backend targeted tests**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
pnpm test -- classes.service.spec.ts investiture.service.spec.ts --runInBand
pnpm exec prisma validate
```

Expected: PASS.

**Step 2: Admin targeted checks**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-admin
pnpm test
pnpm exec tsc --noEmit
```

Expected: PASS.

**Step 3: Flutter targeted checks**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app
flutter test test/features/classes test/features/investiture
flutter analyze
```

Expected: PASS.

**Step 4: Manual scenarios**

Use seeded/test data to verify:

1. Normal class with `available_until_year_id = NULL`, `min=1`, `max=1` appears for enrollment.
2. Guía Mayor Avanzado configured with `available_until_year_id` pointing to the 2026 ecclesiastical year, `min=2`, `max=3`:
   - New enrollment in 2026 allowed.
   - New enrollment in 2027 blocked.
   - Existing 2026 enrollment can submit in 2027/2028 if progress is complete and min duration met.
   - Existing 2026 enrollment becomes `EXPIRED` in 2029 if not invested.
3. Expired enrollment keeps progress visible in user trajectory.
4. Invested enrollment remains visible permanently.

**Step 5: Final commit if fixes were needed**

```bash
git add <changed-files>
git commit -m "test(classes): cover legacy duration scenarios"
```

---

## Implementation notes

- Do not overload `active=false` for legacy. `active=false` remains soft-delete/administrative deactivation.
- Use `EXPIRED` as a domain state, not `active=false`.
- Keep public class catalog focused on classes available to start.
- Keep user trajectory based on `enrollments`, including expired/invested historical records.
- Any bulk certificate/import flow that marks class completion must ensure it can still apply historical investiture records without requiring current class availability.

## Resolved implementation decision

Expiration must be enforced in two places:

1. **Submit-time guard:** when a user attempts to submit an enrollment for investiture, the backend must calculate the elapsed ecclesiastical years. If the enrollment exceeded `max_duration_years`, mark it `EXPIRED`, write `investiture_validation_history.action = EXPIRED`, preserve all progress records, and reject the submission.
2. **Admin/manual process:** provide an auditable admin/manual operation to expire overdue enrollments in batch, so reports and user profiles can be cleaned without waiting for each user to attempt investiture.

Do **not** implement an automatic cron in the first iteration. Cron can be added later if operations prove it is needed.
