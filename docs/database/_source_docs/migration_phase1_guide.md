# Migration Guide - Phase 1 Critical Changes

## Overview
This migration adds critical functionality for:
- Investiture validation workflow
- Certifications system for Guías Mayores
- Insurance management
- Cross-type class enrollment

## Pre-Migration Checklist
- [ ] Backup database
- [ ] Review all changes in `schema_additions_phase1.prisma`
- [ ] Coordinate downtime window (estimated 10-15 minutes)
- [ ] Test migration in development environment first

## Migration Steps

### Step 1: Add New Enums
```sql
-- Add at end of migration file
CREATE TYPE "investiture_status_enum" AS ENUM (
  'IN_PROGRESS',
  'SUBMITTED_FOR_VALIDATION',
  'APPROVED',
  'REJECTED',
  'INVESTIDO'
);

CREATE TYPE "investiture_action_enum" AS ENUM (
  'SUBMITTED',
  'APPROVED',
  'REJECTED',
  'REINVESTITURE_REQUESTED'
);

CREATE TYPE "insurance_type_enum" AS ENUM (
  'GENERAL_ACTIVITIES',
  'CAMPOREE',
  'HIGH_RISK'
);

CREATE TYPE "evidence_validation_enum" AS ENUM (
  'PENDING',
  'VALIDATED',
  'REJECTED'
);
```

### Step 2: Modify `enrollments` Table
```sql
-- CRITICAL: This will require data migration for existing records

-- Add ecclesiastical_year_id (if not exists)
ALTER TABLE "enrollments" 
ADD COLUMN "ecclesiastical_year_id" INTEGER;

-- Update existing enrollments with active ecclesiastical year
UPDATE "enrollments" 
SET "ecclesiastical_year_id" = (
  SELECT "year_id" FROM "ecclesiastical_year" WHERE "active" = true LIMIT 1
);

-- Make it NOT NULL after population
ALTER TABLE "enrollments" 
ALTER COLUMN "ecclesiastical_year_id" SET NOT NULL;

-- Add foreign key
ALTER TABLE "enrollments" 
ADD CONSTRAINT "enrollments_ecclesiastical_year_id_fkey" 
FOREIGN KEY ("ecclesiastical_year_id") 
REFERENCES "ecclesiastical_year"("year_id") 
ON DELETE NO ACTION 
ON UPDATE NO ACTION;

-- Change investiture_status from Boolean to enum
-- STEP 2a: Add new column with enum type
ALTER TABLE "enrollments" 
ADD COLUMN "investiture_status_new" "investiture_status_enum" DEFAULT 'IN_PROGRESS';

-- STEP 2b: Migrate existing data
UPDATE "enrollments" 
SET "investiture_status_new" = CASE
  WHEN "investiture_status" = true THEN 'INVESTIDO'::"investiture_status_enum"
  ELSE 'IN_PROGRESS'::"investiture_status_enum"
END;

-- STEP 2c: Drop old column and rename new one
ALTER TABLE "enrollments" DROP COLUMN "investiture_status";
ALTER TABLE "enrollments" RENAME COLUMN "investiture_status_new" TO "investiture_status";

-- Add new fields
ALTER TABLE "enrollments" ADD COLUMN "submitted_for_validation" BOOLEAN DEFAULT false;
ALTER TABLE "enrollments" ADD COLUMN "submitted_at" TIMESTAMPTZ(6);
ALTER TABLE "enrollments" ADD COLUMN "validated_by" UUID;
ALTER TABLE "enrollments" ADD COLUMN "validated_at" TIMESTAMPTZ(6);
ALTER TABLE "enrollments" ADD COLUMN "rejection_reason" TEXT;
ALTER TABLE "enrollments" ADD COLUMN "investiture_date" TIMESTAMPTZ(6);
ALTER TABLE "enrollments" ADD COLUMN "locked_for_validation" BOOLEAN DEFAULT false;
ALTER TABLE "enrollments" ADD COLUMN "cross_type_enrollment" BOOLEAN DEFAULT false;

-- Add foreign key for validator
ALTER TABLE "enrollments" 
ADD CONSTRAINT "enrollments_validated_by_fkey" 
FOREIGN KEY ("validated_by") 
REFERENCES "users"("user_id") 
ON DELETE NO ACTION 
ON UPDATE NO ACTION;

-- Drop old unique constraint
ALTER TABLE "enrollments" DROP CONSTRAINT IF EXISTS "enrollments_user_id_class_id_key";

-- Add new unique constraint
ALTER TABLE "enrollments" 
ADD CONSTRAINT "enrollments_user_id_class_id_ecclesiastical_year_id_key" 
UNIQUE ("user_id", "class_id", "ecclesiastical_year_id");

-- Add new indexes
CREATE INDEX "idx_enrollments_user_year" ON "enrollments"("user_id", "ecclesiastical_year_id");
CREATE INDEX "idx_enrollments_status" ON "enrollments"("investiture_status");
CREATE INDEX "idx_enrollments_locked" ON "enrollments"("locked_for_validation");
CREATE INDEX "idx_enrollments_cross_type" ON "enrollments"("user_id", "cross_type_enrollment");
```

### Step 3: Create Certifications Tables
```sql
-- certifications
CREATE TABLE "certifications" (
  "certification_id" SERIAL PRIMARY KEY,
  "name" VARCHAR(255) UNIQUE NOT NULL,
  "description" TEXT,
  "material_url" VARCHAR,
  "active" BOOLEAN DEFAULT true,
  "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
  "modified_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP
);

-- certification_modules
CREATE TABLE "certification_modules" (
  "module_id" SERIAL PRIMARY KEY,
  "name" VARCHAR(255) NOT NULL,
  "description" TEXT,
  "certification_id" INTEGER NOT NULL,
  "active" BOOLEAN DEFAULT true,
  "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
  "modified_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY ("certification_id") REFERENCES "certifications"("certification_id") ON DELETE NO ACTION ON UPDATE NO ACTION,
  UNIQUE("name", "certification_id")
);

-- certification_sections
CREATE TABLE "certification_sections" (
  "section_id" SERIAL PRIMARY KEY,
  "name" VARCHAR(255) NOT NULL,
  "description" TEXT,
  "module_id" INTEGER NOT NULL,
  "active" BOOLEAN DEFAULT true,
  "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
  "modified_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY ("module_id") REFERENCES "certification_modules"("module_id") ON DELETE NO ACTION ON UPDATE NO ACTION,
  UNIQUE("name", "module_id")
);

-- users_certifications
CREATE TABLE "users_certifications" (
  "enrollment_id" SERIAL PRIMARY KEY,
  "user_id" UUID NOT NULL,
  "certification_id" INTEGER NOT NULL,
  "enrollment_date" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
  "completion_status" BOOLEAN DEFAULT false,
  "completion_date" TIMESTAMPTZ(6),
  "certificate_url" VARCHAR,
  "active" BOOLEAN DEFAULT true,
  "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
  "modified_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY ("certification_id") REFERENCES "certifications"("certification_id") ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY ("user_id") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE INDEX "idx_users_certifications_completion" ON "users_certifications"("user_id", "completion_status");

-- certification_module_progress
CREATE TABLE "certification_module_progress" (
  "progress_id" SERIAL PRIMARY KEY,
  "user_id" UUID NOT NULL,
  "certification_id" INTEGER NOT NULL,
  "module_id" INTEGER NOT NULL,
  "score" DOUBLE PRECISION NOT NULL,
  "active" BOOLEAN DEFAULT true,
  "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
  "modified_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY ("certification_id") REFERENCES "certifications"("certification_id") ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY ("user_id") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION,
  UNIQUE("user_id", "certification_id", "module_id")
);

-- certification_section_progress
CREATE TABLE "certification_section_progress" (
  "progress_id" SERIAL PRIMARY KEY,
  "user_id" UUID NOT NULL,
  "certification_id" INTEGER NOT NULL,
  "module_id" INTEGER NOT NULL,
  "section_id" INTEGER NOT NULL,
  "score" DOUBLE PRECISION NOT NULL,
  "evidences" JSON,
  "active" BOOLEAN DEFAULT true,
  "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
  "modified_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY ("certification_id") REFERENCES "certifications"("certification_id") ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY ("user_id") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION,
  UNIQUE("user_id", "certification_id", "module_id", "section_id")
);
```

### Step 4: Create Insurance Management Tables
```sql
-- member_insurances
CREATE TABLE "member_insurances" (
  "insurance_id" SERIAL PRIMARY KEY,
  "user_id" UUID NOT NULL,
  "insurance_type" "insurance_type_enum" NOT NULL,
  "policy_number" VARCHAR(100),
  "provider" VARCHAR(255),
  "start_date" DATE NOT NULL,
  "end_date" DATE NOT NULL,
  "coverage_amount" DECIMAL(10, 2),
  "active" BOOLEAN DEFAULT true,
  "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
  "modified_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY ("user_id") REFERENCES "users"("user_id") ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE INDEX "idx_member_insurances_user_expiry" ON "member_insurances"("user_id", "end_date");

-- Modify attending_members_camporees
ALTER TABLE "attending_members_camporees" ADD COLUMN "insurance_verified" BOOLEAN DEFAULT false;
ALTER TABLE "attending_members_camporees" ADD COLUMN "insurance_id" INTEGER;
ALTER TABLE "attending_members_camporees" 
ADD CONSTRAINT "attending_members_camporees_insurance_id_fkey" 
FOREIGN KEY ("insurance_id") 
REFERENCES "member_insurances"("insurance_id") 
ON DELETE NO ACTION 
ON UPDATE NO ACTION;
```

### Step 5: Create Investiture Validation Tables
```sql
-- investiture_validation_history
CREATE TABLE "investiture_validation_history" (
  "history_id" SERIAL PRIMARY KEY,
  "enrollment_id" INTEGER NOT NULL,
  "action" "investiture_action_enum" NOT NULL,
  "performed_by" UUID NOT NULL,
  "comments" TEXT,
  "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY ("enrollment_id") REFERENCES "enrollments"("enrollment_id") ON DELETE CASCADE ON UPDATE NO ACTION,
  FOREIGN KEY ("performed_by") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE INDEX "idx_investiture_history_enrollment" ON "investiture_validation_history"("enrollment_id");

-- investiture_config
CREATE TABLE "investiture_config" (
  "config_id" SERIAL PRIMARY KEY,
  "local_field_id" INTEGER NOT NULL,
  "ecclesiastical_year_id" INTEGER NOT NULL,
  "submission_deadline" DATE NOT NULL,
  "investiture_date" DATE NOT NULL,
  "active" BOOLEAN DEFAULT true,
  "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
  "modified_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY ("local_field_id") REFERENCES "local_fields"("local_field_id") ON DELETE CASCADE ON UPDATE NO ACTION,
  FOREIGN KEY ("ecclesiastical_year_id") REFERENCES "ecclesiastical_year"("year_id") ON DELETE CASCADE ON UPDATE NO ACTION,
  UNIQUE("local_field_id", "ecclesiastical_year_id")
);
```

### Step 6: Modify `classes` Table
```sql
ALTER TABLE "classes" ADD COLUMN "requires_invested_gm" BOOLEAN DEFAULT false;
```

## Post-Migration Verification

### Verify Enums
```sql
SELECT * FROM pg_enum WHERE enumlabel LIKE '%INVEST%';
```

### Verify New Tables
```sql
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
  'certifications',
  'certification_modules',
  'certification_sections',
  'users_certifications',
  'certification_module_progress',
  'certification_section_progress',
  'member_insurances',
  'investiture_validation_history',
  'investiture_config'
);
```

### Verify enrollments Modifications
```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'enrollments' 
AND column_name IN (
  'ecclesiastical_year_id',
  'investiture_status',
  'submitted_for_validation',
  'locked_for_validation',
  'cross_type_enrollment'
);
```

### Verify Indexes
```sql
SELECT indexname FROM pg_indexes 
WHERE tablename = 'enrollments' 
AND indexname LIKE 'idx_%';
```

## Data Population (Optional)

### Create Initial Investiture Configs for Active Year
```sql
INSERT INTO "investiture_config" (
  "local_field_id",
  "ecclesiastical_year_id",
  "submission_deadline",
  "investiture_date"
)
SELECT 
  lf."local_field_id",
  ey."year_id",
  DATE '2026-11-30' as submission_deadline,
  DATE '2026-12-15' as investiture_date
FROM "local_fields" lf
CROSS JOIN (SELECT "year_id" FROM "ecclesiastical_year" WHERE "active" = true) ey
ON CONFLICT DO NOTHING;
```

### Create Sample Certifications
```sql
INSERT INTO "certifications" ("name", "description", "active") VALUES
('Liderazgo Juvenil', 'Certificación en liderazgo para jóvenes', true),
('Instructor de Especialidades', 'Certificación para instruir especialidades', true),
('Consejería Pastoral', 'Certificación en consejería para jóvenes', true),
('Gestión de Clubes', 'Certificación en administración de clubes', true),
('Primeros Auxilios Avanzados', 'Certificación avanzada en primeros auxilios', true),
('Campismo y Supervivencia', 'Certificación en técnicas de campismo', true);
```

## Rollback Strategy

If migration fails, run:
```sql
-- This is a DESTRUCTIVE rollback - use with caution
DROP TABLE IF EXISTS "investiture_config" CASCADE;
DROP TABLE IF EXISTS "investiture_validation_history" CASCADE;
DROP TABLE IF EXISTS "member_insurances" CASCADE;
DROP TABLE IF EXISTS "certification_section_progress" CASCADE;
DROP TABLE IF EXISTS "certification_module_progress" CASCADE;
DROP TABLE IF EXISTS "users_certifications" CASCADE;
DROP TABLE IF EXISTS "certification_sections" CASCADE;
DROP TABLE IF EXISTS "certification_modules" CASCADE;
DROP TABLE IF EXISTS "certifications" CASCADE;

-- Revert enrollments (if possible - may lose data)
ALTER TABLE "enrollments" DROP COLUMN IF EXISTS "cross_type_enrollment";
ALTER TABLE "enrollments" DROP COLUMN IF EXISTS "locked_for_validation";
ALTER TABLE "enrollments" DROP COLUMN IF EXISTS "investiture_date";
ALTER TABLE "enrollments" DROP COLUMN IF EXISTS "rejection_reason";
ALTER TABLE "enrollments" DROP COLUMN IF EXISTS "validated_at";
ALTER TABLE "enrollments" DROP COLUMN IF EXISTS "validated_by";
ALTER TABLE "enrollments" DROP COLUMN IF EXISTS "submitted_at";
ALTER TABLE "enrollments" DROP COLUMN IF EXISTS "submitted_for_validation";
ALTER TABLE "enrollments" DROP COLUMN IF EXISTS "ecclesiastical_year_id";

-- Revert enums
DROP TYPE IF EXISTS "evidence_validation_enum";
DROP TYPE IF EXISTS "insurance_type_enum";
DROP TYPE IF EXISTS "investiture_action_enum";
DROP TYPE IF EXISTS "investiture_status_enum";
```

## Estimated Impact

- **Downtime**: 10-15 minutes
- **Affected Tables**: 4 modified, 9 new tables
- **Data Migration**: `enrollments` table requires careful migration
- **Risk Level**: MEDIUM (due to enrollments modification)

## Notes

- **CRITICAL**: Test in development environment first
- Back up `enrollments` table before migration
- Schedule migration during low-traffic window
- Have rollback script ready

---

**Generated**: 2026-01-20  
**Version**: 1.0.0  
**Applies to**: schema.prisma Phase 1 changes
