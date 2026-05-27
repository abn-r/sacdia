-- SACDIA DB drift remediation — DO NOT APPLY BLINDLY
-- Date: 2026-05-22
-- Scope: Neon branch currently used by sacdia-backend .env.
--
-- Purpose:
--   1. Bring real DB schema in line with Prisma model for class duration/availability.
--   2. Repair sequence drift detected in activity_types.
--
-- Important:
--   - This script is idempotent where PostgreSQL supports it.
--   - It intentionally does NOT mutate _prisma_migrations.
--   - After applying and verifying, reconcile migration history separately.
--   - Do NOT run `prisma migrate deploy` blindly: audit found 4 migrations pending
--     in _prisma_migrations, but 3 already have DB objects present.
--
-- Pending migration represented by this remediation:
--   - 20260521120000_class_duration_availability
--
-- Expected follow-up after successful apply + verification:
--   - pnpm exec prisma migrate resolve --applied 20260521120000_class_duration_availability
--   - Evaluate resolving these separately only after confirming object parity:
--       20260513000000_add_audit_logs
--       20260514130000_materials_per_local_field
--       20260520170000_certificate_bulk_imports_init

BEGIN;

SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';

-- ---------------------------------------------------------------------------
-- 1) Enum values required by class duration/availability logic
-- ---------------------------------------------------------------------------

ALTER TYPE "investiture_status_enum" ADD VALUE IF NOT EXISTS 'EXPIRED';
ALTER TYPE "investiture_action_enum" ADD VALUE IF NOT EXISTS 'EXPIRED';

-- ---------------------------------------------------------------------------
-- 2) classes: availability window + duration bounds
-- ---------------------------------------------------------------------------

ALTER TABLE "classes"
  ADD COLUMN IF NOT EXISTS "available_from_year_id" INTEGER;

ALTER TABLE "classes"
  ADD COLUMN IF NOT EXISTS "available_until_year_id" INTEGER;

ALTER TABLE "classes"
  ADD COLUMN IF NOT EXISTS "min_duration_years" INTEGER DEFAULT 1;

UPDATE "classes"
SET "min_duration_years" = 1
WHERE "min_duration_years" IS NULL;

ALTER TABLE "classes"
  ALTER COLUMN "min_duration_years" SET DEFAULT 1,
  ALTER COLUMN "min_duration_years" SET NOT NULL;

ALTER TABLE "classes"
  ADD COLUMN IF NOT EXISTS "max_duration_years" INTEGER DEFAULT 1;

UPDATE "classes"
SET "max_duration_years" = GREATEST(1, "min_duration_years")
WHERE "max_duration_years" IS NULL;

ALTER TABLE "classes"
  ALTER COLUMN "max_duration_years" SET DEFAULT 1,
  ALTER COLUMN "max_duration_years" SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'classes_available_from_year_id_fkey'
  ) THEN
    ALTER TABLE "classes"
      ADD CONSTRAINT "classes_available_from_year_id_fkey"
      FOREIGN KEY ("available_from_year_id")
      REFERENCES "ecclesiastical_years"("year_id")
      ON DELETE NO ACTION ON UPDATE NO ACTION;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'classes_available_until_year_id_fkey'
  ) THEN
    ALTER TABLE "classes"
      ADD CONSTRAINT "classes_available_until_year_id_fkey"
      FOREIGN KEY ("available_until_year_id")
      REFERENCES "ecclesiastical_years"("year_id")
      ON DELETE NO ACTION ON UPDATE NO ACTION;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'classes_min_duration_years_check'
  ) THEN
    ALTER TABLE "classes"
      ADD CONSTRAINT "classes_min_duration_years_check"
      CHECK ("min_duration_years" >= 1);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'classes_max_duration_years_check'
  ) THEN
    ALTER TABLE "classes"
      ADD CONSTRAINT "classes_max_duration_years_check"
      CHECK ("max_duration_years" >= 1);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'classes_duration_years_order_check'
  ) THEN
    ALTER TABLE "classes"
      ADD CONSTRAINT "classes_duration_years_order_check"
      CHECK ("max_duration_years" >= "min_duration_years");
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS "idx_classes_available_from_year"
  ON "classes"("available_from_year_id");

CREATE INDEX IF NOT EXISTS "idx_classes_available_until_year"
  ON "classes"("available_until_year_id");

-- ---------------------------------------------------------------------------
-- 3) Sequence repair detected by read-only audit
-- ---------------------------------------------------------------------------

DO $$
DECLARE
  max_id bigint;
BEGIN
  SELECT COALESCE(MAX("activity_type_id"), 0)
  INTO max_id
  FROM "activity_types";

  IF max_id = 0 THEN
    PERFORM setval('public.activity_types_activity_type_id_seq', 1, false);
  ELSE
    PERFORM setval('public.activity_types_activity_type_id_seq', max_id, true);
  END IF;
END $$;

-- Defensive: keep clubs sequence aligned too. Audit currently shows it is OK,
-- but this is safe and prevents recurrence if fixtures/manual inserts move max().
DO $$
DECLARE
  max_id bigint;
BEGIN
  SELECT COALESCE(MAX("club_id"), 0)
  INTO max_id
  FROM "clubs";

  IF max_id = 0 THEN
    PERFORM setval('public.clubs_club_id_seq', 1, false);
  ELSE
    PERFORM setval('public.clubs_club_id_seq', max_id, true);
  END IF;
END $$;

COMMIT;

-- ---------------------------------------------------------------------------
-- Post-apply verification queries (run read-only after commit)
-- ---------------------------------------------------------------------------

-- SELECT column_name
-- FROM information_schema.columns
-- WHERE table_schema = 'public'
--   AND table_name = 'classes'
--   AND column_name IN (
--     'available_from_year_id',
--     'available_until_year_id',
--     'min_duration_years',
--     'max_duration_years'
--   )
-- ORDER BY column_name;
--
-- SELECT conname
-- FROM pg_constraint
-- WHERE conname IN (
--   'classes_available_from_year_id_fkey',
--   'classes_available_until_year_id_fkey',
--   'classes_min_duration_years_check',
--   'classes_max_duration_years_check',
--   'classes_duration_years_order_check'
-- )
-- ORDER BY conname;
--
-- SELECT 'activity_types' AS table_name,
--        (SELECT COALESCE(MAX(activity_type_id),0) FROM activity_types) AS max_id,
--        (SELECT last_value FROM public.activity_types_activity_type_id_seq) AS last_value,
--        (SELECT is_called FROM public.activity_types_activity_type_id_seq) AS is_called;
