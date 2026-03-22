# Club Sections Consolidation — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Consolidar 3 tablas identicas (`club_adventurers`, `club_pathfinders`, `club_master_guilds`) en una sola tabla `club_sections`, renombrar "club-instances" a "club-sections" en los 3 repos, y actualizar documentacion canon.

**Architecture:** Migracion SQL en transaccion unica crea `club_sections`, mapea datos desde las 3 tablas, actualiza 10 tablas dependientes con FK unica `club_section_id`, y dropea las tablas originales (renombradas con sufijo `_deprecated` por 7 dias). Backend NestJS simplifica switch/if patterns a queries parametrizados. Admin Next.js y App Flutter actualizan tipos, providers y componentes.

**Tech Stack:** PostgreSQL, Prisma 7, NestJS 11, Next.js 16, Flutter/Dart, Supabase

---

## Chunk 1: Migracion SQL y Prisma Schema

### Task 1: Pre-migration data audit

> Script SQL de verificacion para ejecutar ANTES de la migracion. Confirma estado actual de datos, detecta anomalias y establece baselines para verificacion post-migracion.

**File:** `sacdia-backend/prisma/migrations/scripts/pre-migration-audit.sql`

- [ ] **1.1** Create the scripts directory:
  ```bash
  mkdir -p /Users/abner/Documents/development/sacdia/sacdia-backend/prisma/migrations/scripts
  ```

- [ ] **1.2** Create `pre-migration-audit.sql` with this exact content:
  ```sql
  -- =============================================================
  -- PRE-MIGRATION AUDIT: Club Sections Consolidation
  -- Run this BEFORE applying the migration.
  -- Expected: zero anomalies, non-zero row counts.
  -- =============================================================

  -- 1. Row counts per source table (baseline for post-migration check)
  SELECT 'club_adventurers' AS source_table, COUNT(*) AS row_count FROM club_adventurers
  UNION ALL
  SELECT 'club_pathfinders', COUNT(*) FROM club_pathfinders
  UNION ALL
  SELECT 'club_master_guilds', COUNT(*) FROM club_master_guilds;

  -- 2. Verify club_type_id values are consistent
  --    Expected: club_adventurers -> club_type_id for Aventureros
  --              club_pathfinders -> club_type_id for Conquistadores
  --              club_master_guilds -> club_type_id for Guias Mayores
  SELECT 'club_adventurers' AS source, ct.name AS club_type_name, ca.club_type_id, COUNT(*) AS cnt
  FROM club_adventurers ca JOIN club_types ct ON ca.club_type_id = ct.club_type_id
  GROUP BY ct.name, ca.club_type_id
  UNION ALL
  SELECT 'club_pathfinders', ct.name, cp.club_type_id, COUNT(*)
  FROM club_pathfinders cp JOIN club_types ct ON cp.club_type_id = ct.club_type_id
  GROUP BY ct.name, cp.club_type_id
  UNION ALL
  SELECT 'club_master_guilds', ct.name, cm.club_type_id, COUNT(*)
  FROM club_master_guilds cm JOIN club_types ct ON cm.club_type_id = ct.club_type_id
  GROUP BY ct.name, cm.club_type_id;

  -- 3. NULL main_club_id counts (these will stay NULL in club_sections)
  SELECT 'club_adventurers' AS source, COUNT(*) FILTER (WHERE main_club_id IS NULL) AS null_main_club
  FROM club_adventurers
  UNION ALL
  SELECT 'club_pathfinders', COUNT(*) FILTER (WHERE main_club_id IS NULL) FROM club_pathfinders
  UNION ALL
  SELECT 'club_master_guilds', COUNT(*) FILTER (WHERE main_club_id IS NULL) FROM club_master_guilds;

  -- 4. Dependent table FK usage (how many non-NULL FKs per column per table)
  SELECT 'activities' AS dep_table,
    COUNT(*) FILTER (WHERE club_adv_id IS NOT NULL) AS adv_refs,
    COUNT(*) FILTER (WHERE club_pathf_id IS NOT NULL) AS pathf_refs,
    COUNT(*) FILTER (WHERE club_mg_id IS NOT NULL) AS mg_refs
  FROM activities
  UNION ALL
  SELECT 'activity_instances',
    COUNT(*) FILTER (WHERE club_adv_id IS NOT NULL),
    COUNT(*) FILTER (WHERE club_pathf_id IS NOT NULL),
    COUNT(*) FILTER (WHERE club_mg_id IS NOT NULL)
  FROM activity_instances
  UNION ALL
  SELECT 'folder_assignments',
    COUNT(*) FILTER (WHERE club_adv_id IS NOT NULL),
    COUNT(*) FILTER (WHERE club_pathf_id IS NOT NULL),
    COUNT(*) FILTER (WHERE club_mg_id IS NOT NULL)
  FROM folder_assignments
  UNION ALL
  SELECT 'camporee_clubs',
    COUNT(*) FILTER (WHERE club_adv_id IS NOT NULL),
    COUNT(*) FILTER (WHERE club_pathf_id IS NOT NULL),
    COUNT(*) FILTER (WHERE club_mg_id IS NOT NULL)
  FROM camporee_clubs
  UNION ALL
  SELECT 'club_inventory',
    COUNT(*) FILTER (WHERE club_adv_id IS NOT NULL),
    COUNT(*) FILTER (WHERE club_pathf_id IS NOT NULL),
    COUNT(*) FILTER (WHERE club_mg_id IS NOT NULL)
  FROM club_inventory
  UNION ALL
  SELECT 'club_role_assignments',
    COUNT(*) FILTER (WHERE club_adv_id IS NOT NULL),
    COUNT(*) FILTER (WHERE club_pathf_id IS NOT NULL),
    COUNT(*) FILTER (WHERE club_mg_id IS NOT NULL)
  FROM club_role_assignments
  UNION ALL
  SELECT 'finances',
    COUNT(*) FILTER (WHERE club_adv_id IS NOT NULL),
    COUNT(*) FILTER (WHERE club_pathf_id IS NOT NULL),
    COUNT(*) FILTER (WHERE club_mg_id IS NOT NULL)
  FROM finances
  UNION ALL
  SELECT 'folders_modules_records',
    COUNT(*) FILTER (WHERE club_adv_id IS NOT NULL),
    COUNT(*) FILTER (WHERE club_pathf_id IS NOT NULL),
    COUNT(*) FILTER (WHERE club_mg_id IS NOT NULL)
  FROM folders_modules_records
  UNION ALL
  SELECT 'folders_section_records',
    COUNT(*) FILTER (WHERE club_adv_id IS NOT NULL),
    COUNT(*) FILTER (WHERE club_pathf_id IS NOT NULL),
    COUNT(*) FILTER (WHERE club_mg_id IS NOT NULL)
  FROM folders_section_records
  UNION ALL
  SELECT 'units',
    COUNT(*) FILTER (WHERE club_adv_id IS NOT NULL),
    COUNT(*) FILTER (WHERE club_pathf_id IS NOT NULL),
    COUNT(*) FILTER (WHERE club_mg_id IS NOT NULL)
  FROM units;

  -- 5. Anomaly: rows with MORE THAN ONE FK set (should be 0 for most tables)
  SELECT 'activities' AS dep_table, COUNT(*) AS multi_fk_rows
  FROM activities
  WHERE (CASE WHEN club_adv_id IS NOT NULL THEN 1 ELSE 0 END
       + CASE WHEN club_pathf_id IS NOT NULL THEN 1 ELSE 0 END
       + CASE WHEN club_mg_id IS NOT NULL THEN 1 ELSE 0 END) > 1
  UNION ALL
  SELECT 'activity_instances', COUNT(*) FROM activity_instances
  WHERE (CASE WHEN club_adv_id IS NOT NULL THEN 1 ELSE 0 END
       + CASE WHEN club_pathf_id IS NOT NULL THEN 1 ELSE 0 END
       + CASE WHEN club_mg_id IS NOT NULL THEN 1 ELSE 0 END) > 1
  UNION ALL
  SELECT 'club_role_assignments', COUNT(*) FROM club_role_assignments
  WHERE (CASE WHEN club_adv_id IS NOT NULL THEN 1 ELSE 0 END
       + CASE WHEN club_pathf_id IS NOT NULL THEN 1 ELSE 0 END
       + CASE WHEN club_mg_id IS NOT NULL THEN 1 ELSE 0 END) > 1
  UNION ALL
  SELECT 'camporee_clubs', COUNT(*) FROM camporee_clubs
  WHERE (CASE WHEN club_adv_id IS NOT NULL THEN 1 ELSE 0 END
       + CASE WHEN club_pathf_id IS NOT NULL THEN 1 ELSE 0 END
       + CASE WHEN club_mg_id IS NOT NULL THEN 1 ELSE 0 END) > 1
  UNION ALL
  SELECT 'club_inventory', COUNT(*) FROM club_inventory
  WHERE (CASE WHEN club_adv_id IS NOT NULL THEN 1 ELSE 0 END
       + CASE WHEN club_pathf_id IS NOT NULL THEN 1 ELSE 0 END
       + CASE WHEN club_mg_id IS NOT NULL THEN 1 ELSE 0 END) > 1
  UNION ALL
  SELECT 'finances', COUNT(*) FROM finances
  WHERE (CASE WHEN club_adv_id IS NOT NULL THEN 1 ELSE 0 END
       + CASE WHEN club_pathf_id IS NOT NULL THEN 1 ELSE 0 END
       + CASE WHEN club_mg_id IS NOT NULL THEN 1 ELSE 0 END) > 1
  UNION ALL
  SELECT 'folders_modules_records', COUNT(*) FROM folders_modules_records
  WHERE (CASE WHEN club_adv_id IS NOT NULL THEN 1 ELSE 0 END
       + CASE WHEN club_pathf_id IS NOT NULL THEN 1 ELSE 0 END
       + CASE WHEN club_mg_id IS NOT NULL THEN 1 ELSE 0 END) > 1
  UNION ALL
  SELECT 'folders_section_records', COUNT(*) FROM folders_section_records
  WHERE (CASE WHEN club_adv_id IS NOT NULL THEN 1 ELSE 0 END
       + CASE WHEN club_pathf_id IS NOT NULL THEN 1 ELSE 0 END
       + CASE WHEN club_mg_id IS NOT NULL THEN 1 ELSE 0 END) > 1
  UNION ALL
  SELECT 'units', COUNT(*) FROM units
  WHERE (CASE WHEN club_adv_id IS NOT NULL THEN 1 ELSE 0 END
       + CASE WHEN club_pathf_id IS NOT NULL THEN 1 ELSE 0 END
       + CASE WHEN club_mg_id IS NOT NULL THEN 1 ELSE 0 END) > 1;

  -- 6. Orphan check: FKs pointing to non-existent source rows
  SELECT 'activities->club_adventurers' AS check_name, COUNT(*) AS orphans
  FROM activities a WHERE a.club_adv_id IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM club_adventurers ca WHERE ca.club_adv_id = a.club_adv_id)
  UNION ALL
  SELECT 'activities->club_pathfinders', COUNT(*)
  FROM activities a WHERE a.club_pathf_id IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM club_pathfinders cp WHERE cp.club_pathf_id = a.club_pathf_id)
  UNION ALL
  SELECT 'activities->club_master_guilds', COUNT(*)
  FROM activities a WHERE a.club_mg_id IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM club_master_guilds cm WHERE cm.club_mg_id = a.club_mg_id);

  -- 7. folder_assignments orphan FK check (no @relation in Prisma — may be dead columns)
  SELECT 'folder_assignments->club_adventurers (ORPHAN FK)' AS check_name, COUNT(*) AS refs
  FROM folder_assignments WHERE club_adv_id IS NOT NULL
  UNION ALL
  SELECT 'folder_assignments->club_pathfinders (ORPHAN FK)', COUNT(*)
  FROM folder_assignments WHERE club_pathf_id IS NOT NULL
  UNION ALL
  SELECT 'folder_assignments->club_master_guilds (ORPHAN FK)', COUNT(*)
  FROM folder_assignments WHERE club_mg_id IS NOT NULL;

  -- 8. Duplicate unique constraints on club_role_assignments (confirm both exist)
  SELECT conname, contype, conrelid::regclass
  FROM pg_constraint
  WHERE conrelid = 'club_role_assignments'::regclass
    AND conname IN ('club_role_assignment_unique', 'club_role_assignment_unique_refactored');

  -- 9. Permission strings that will need updating
  SELECT permission_id, permission_name
  FROM permissions
  WHERE permission_name LIKE 'club_instances%';

  -- 10. Current index listing for the 3 source tables (to know what gets dropped)
  SELECT tablename, indexname
  FROM pg_indexes
  WHERE tablename IN ('club_adventurers', 'club_pathfinders', 'club_master_guilds')
  ORDER BY tablename, indexname;
  ```

- [ ] **1.3** Run the audit script against the Supabase DB:
  ```bash
  cd /Users/abner/Documents/development/sacdia/sacdia-backend
  psql "$DATABASE_URL" -f prisma/migrations/scripts/pre-migration-audit.sql
  ```
  **Expected output:**
  - Query 1: Non-zero row counts for all 3 tables
  - Query 5: All `multi_fk_rows` = 0 (no row references more than one club type)
  - Query 6: All `orphans` = 0
  - Query 7: If all 3 counts are 0, folder_assignments FKs are dead columns (skip mapping in migration)
  - Query 8: Both constraint names returned
  - Query 9: All `club_instances%` permission strings listed (note exact names for Task 2)

- [ ] **1.4** Save audit results to a local file for reference:
  ```bash
  psql "$DATABASE_URL" -f prisma/migrations/scripts/pre-migration-audit.sql > prisma/migrations/scripts/pre-migration-audit-results.txt 2>&1
  ```

- [ ] **1.5** **DECISION GATE:** If query 5 shows `multi_fk_rows > 0` for ANY table, STOP. Report the anomalous rows — they need manual resolution before proceeding. If query 7 shows non-zero counts for folder_assignments, those FKs are live and MUST be mapped in Task 2 (uncomment the folder_assignments mapping block).

---

### Task 2: Migration SQL script

> Prisma migration SQL that runs as a single transaction. Creates `club_sections`, migrates all data, updates all 10 dependent tables, and deprecates original tables.

**File:** `sacdia-backend/prisma/migrations/YYYYMMDDHHMMSS_consolidate_club_sections/migration.sql`

- [ ] **2.1** Create the migration directory (use current timestamp):
  ```bash
  MIGRATION_DIR="/Users/abner/Documents/development/sacdia/sacdia-backend/prisma/migrations/$(date +%Y%m%d%H%M%S)_consolidate_club_sections"
  mkdir -p "$MIGRATION_DIR"
  echo "$MIGRATION_DIR"  # Save this path — you'll need it
  ```

- [ ] **2.2** Create `migration.sql` in that directory with this exact content:

  ```sql
  -- =============================================================
  -- MIGRATION: Consolidate club_adventurers, club_pathfinders,
  --            club_master_guilds into club_sections
  -- Strategy: Single transaction, mapping table, deprecate originals
  -- =============================================================

  -- =============================================
  -- PHASE 1: Create club_sections + mapping table
  -- =============================================

  -- 1a. Create the consolidated table
  CREATE TABLE "club_sections" (
    "club_section_id" SERIAL PRIMARY KEY,
    "active" BOOLEAN NOT NULL DEFAULT false,
    "souls_target" INTEGER NOT NULL DEFAULT 1,
    "fee" INTEGER NOT NULL DEFAULT 1,
    "meeting_day" JSONB[] DEFAULT '{}',
    "meeting_time" JSONB[] DEFAULT '{}',
    "club_type_id" INTEGER NOT NULL,
    "main_club_id" INTEGER,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT NOW(),
    "modified_at" TIMESTAMPTZ(6) NOT NULL DEFAULT NOW(),
    CONSTRAINT "club_sections_club_type_id_fkey"
      FOREIGN KEY ("club_type_id") REFERENCES "club_types"("club_type_id") ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT "club_sections_main_club_id_fkey"
      FOREIGN KEY ("main_club_id") REFERENCES "clubs"("club_id") ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT "club_sections_main_club_id_club_type_id_key"
      UNIQUE ("main_club_id", "club_type_id")
  );

  -- 1b. Temporary mapping table (persists until end of migration)
  CREATE TEMP TABLE "_club_section_mapping" (
    source_table TEXT NOT NULL,
    old_id INTEGER NOT NULL,
    new_club_section_id INTEGER NOT NULL,
    PRIMARY KEY (source_table, old_id)
  );

  -- 1c. Insert from club_adventurers
  INSERT INTO "club_sections" (active, souls_target, fee, meeting_day, meeting_time, club_type_id, main_club_id, created_at, modified_at)
  SELECT active, souls_target, fee, meeting_day, meeting_time, club_type_id, main_club_id, created_at, modified_at
  FROM "club_adventurers";

  INSERT INTO "_club_section_mapping" (source_table, old_id, new_club_section_id)
  SELECT 'club_adventurers', ca.club_adv_id, cs.club_section_id
  FROM "club_adventurers" ca
  JOIN "club_sections" cs
    ON cs.club_type_id = ca.club_type_id
   AND (cs.main_club_id = ca.main_club_id OR (cs.main_club_id IS NULL AND ca.main_club_id IS NULL));

  -- 1d. Insert from club_pathfinders
  INSERT INTO "club_sections" (active, souls_target, fee, meeting_day, meeting_time, club_type_id, main_club_id, created_at, modified_at)
  SELECT active, souls_target, fee, meeting_day, meeting_time, club_type_id, main_club_id, created_at, modified_at
  FROM "club_pathfinders";

  INSERT INTO "_club_section_mapping" (source_table, old_id, new_club_section_id)
  SELECT 'club_pathfinders', cp.club_pathf_id, cs.club_section_id
  FROM "club_pathfinders" cp
  JOIN "club_sections" cs
    ON cs.club_type_id = cp.club_type_id
   AND (cs.main_club_id = cp.main_club_id OR (cs.main_club_id IS NULL AND cp.main_club_id IS NULL));

  -- 1e. Insert from club_master_guilds
  INSERT INTO "club_sections" (active, souls_target, fee, meeting_day, meeting_time, club_type_id, main_club_id, created_at, modified_at)
  SELECT active, souls_target, fee, meeting_day, meeting_time, club_type_id, main_club_id, created_at, modified_at
  FROM "club_master_guilds";

  INSERT INTO "_club_section_mapping" (source_table, old_id, new_club_section_id)
  SELECT 'club_master_guilds', cm.club_mg_id, cs.club_section_id
  FROM "club_master_guilds" cm
  JOIN "club_sections" cs
    ON cs.club_type_id = cm.club_type_id
   AND (cs.main_club_id = cm.main_club_id OR (cs.main_club_id IS NULL AND cm.main_club_id IS NULL));

  -- 1f. Verify mapping completeness
  DO $$
  DECLARE
    v_source_count INTEGER;
    v_mapped_count INTEGER;
  BEGIN
    SELECT (SELECT COUNT(*) FROM club_adventurers)
         + (SELECT COUNT(*) FROM club_pathfinders)
         + (SELECT COUNT(*) FROM club_master_guilds)
    INTO v_source_count;

    SELECT COUNT(*) FROM _club_section_mapping INTO v_mapped_count;

    IF v_source_count != v_mapped_count THEN
      RAISE EXCEPTION 'Mapping mismatch: % source rows but % mapped rows', v_source_count, v_mapped_count;
    END IF;

    -- Also verify club_sections count
    IF (SELECT COUNT(*) FROM club_sections) != v_source_count THEN
      RAISE EXCEPTION 'club_sections count (%) != source count (%)', (SELECT COUNT(*) FROM club_sections), v_source_count;
    END IF;
  END $$;

  -- =============================================
  -- PHASE 2: Add club_section_id to dependent tables
  -- =============================================

  ALTER TABLE "activities"               ADD COLUMN "club_section_id" INTEGER;
  ALTER TABLE "activity_instances"       ADD COLUMN "club_section_id" INTEGER;
  ALTER TABLE "folder_assignments"       ADD COLUMN "club_section_id" INTEGER;
  ALTER TABLE "camporee_clubs"           ADD COLUMN "club_section_id" INTEGER;
  ALTER TABLE "club_inventory"           ADD COLUMN "club_section_id" INTEGER;
  ALTER TABLE "club_role_assignments"    ADD COLUMN "club_section_id" INTEGER;
  ALTER TABLE "finances"                 ADD COLUMN "club_section_id" INTEGER;
  ALTER TABLE "folders_modules_records"  ADD COLUMN "club_section_id" INTEGER;
  ALTER TABLE "folders_section_records"  ADD COLUMN "club_section_id" INTEGER;
  ALTER TABLE "units"                    ADD COLUMN "club_section_id" INTEGER;

  -- =============================================
  -- PHASE 3: Populate club_section_id from mapping
  -- =============================================

  -- 3a. activities
  UPDATE "activities" t SET club_section_id = m.new_club_section_id
  FROM "_club_section_mapping" m
  WHERE (m.source_table = 'club_adventurers' AND t.club_adv_id = m.old_id)
     OR (m.source_table = 'club_pathfinders' AND t.club_pathf_id = m.old_id)
     OR (m.source_table = 'club_master_guilds' AND t.club_mg_id = m.old_id);

  -- 3b. activity_instances
  UPDATE "activity_instances" t SET club_section_id = m.new_club_section_id
  FROM "_club_section_mapping" m
  WHERE (m.source_table = 'club_adventurers' AND t.club_adv_id = m.old_id)
     OR (m.source_table = 'club_pathfinders' AND t.club_pathf_id = m.old_id)
     OR (m.source_table = 'club_master_guilds' AND t.club_mg_id = m.old_id);

  -- 3c. folder_assignments
  -- NOTE: These are orphan FKs (no @relation in Prisma). If pre-audit query 7
  -- showed all zeros, this UPDATE will match zero rows — which is correct.
  -- If they had data, this correctly maps them.
  UPDATE "folder_assignments" t SET club_section_id = m.new_club_section_id
  FROM "_club_section_mapping" m
  WHERE (m.source_table = 'club_adventurers' AND t.club_adv_id = m.old_id)
     OR (m.source_table = 'club_pathfinders' AND t.club_pathf_id = m.old_id)
     OR (m.source_table = 'club_master_guilds' AND t.club_mg_id = m.old_id);

  -- 3d. camporee_clubs
  UPDATE "camporee_clubs" t SET club_section_id = m.new_club_section_id
  FROM "_club_section_mapping" m
  WHERE (m.source_table = 'club_adventurers' AND t.club_adv_id = m.old_id)
     OR (m.source_table = 'club_pathfinders' AND t.club_pathf_id = m.old_id)
     OR (m.source_table = 'club_master_guilds' AND t.club_mg_id = m.old_id);

  -- 3e. club_inventory
  UPDATE "club_inventory" t SET club_section_id = m.new_club_section_id
  FROM "_club_section_mapping" m
  WHERE (m.source_table = 'club_adventurers' AND t.club_adv_id = m.old_id)
     OR (m.source_table = 'club_pathfinders' AND t.club_pathf_id = m.old_id)
     OR (m.source_table = 'club_master_guilds' AND t.club_mg_id = m.old_id);

  -- 3f. club_role_assignments
  UPDATE "club_role_assignments" t SET club_section_id = m.new_club_section_id
  FROM "_club_section_mapping" m
  WHERE (m.source_table = 'club_adventurers' AND t.club_adv_id = m.old_id)
     OR (m.source_table = 'club_pathfinders' AND t.club_pathf_id = m.old_id)
     OR (m.source_table = 'club_master_guilds' AND t.club_mg_id = m.old_id);

  -- 3g. finances
  UPDATE "finances" t SET club_section_id = m.new_club_section_id
  FROM "_club_section_mapping" m
  WHERE (m.source_table = 'club_adventurers' AND t.club_adv_id = m.old_id)
     OR (m.source_table = 'club_pathfinders' AND t.club_pathf_id = m.old_id)
     OR (m.source_table = 'club_master_guilds' AND t.club_mg_id = m.old_id);

  -- 3h. folders_modules_records
  UPDATE "folders_modules_records" t SET club_section_id = m.new_club_section_id
  FROM "_club_section_mapping" m
  WHERE (m.source_table = 'club_adventurers' AND t.club_adv_id = m.old_id)
     OR (m.source_table = 'club_pathfinders' AND t.club_pathf_id = m.old_id)
     OR (m.source_table = 'club_master_guilds' AND t.club_mg_id = m.old_id);

  -- 3i. folders_section_records
  UPDATE "folders_section_records" t SET club_section_id = m.new_club_section_id
  FROM "_club_section_mapping" m
  WHERE (m.source_table = 'club_adventurers' AND t.club_adv_id = m.old_id)
     OR (m.source_table = 'club_pathfinders' AND t.club_pathf_id = m.old_id)
     OR (m.source_table = 'club_master_guilds' AND t.club_mg_id = m.old_id);

  -- 3j. units
  UPDATE "units" t SET club_section_id = m.new_club_section_id
  FROM "_club_section_mapping" m
  WHERE (m.source_table = 'club_adventurers' AND t.club_adv_id = m.old_id)
     OR (m.source_table = 'club_pathfinders' AND t.club_pathf_id = m.old_id)
     OR (m.source_table = 'club_master_guilds' AND t.club_mg_id = m.old_id);

  -- =============================================
  -- PHASE 4: Add FK constraints + indexes
  -- onDelete behavior matches existing per-table:
  --   NoAction: activities, activity_instances, camporee_clubs,
  --             folders_modules_records, folders_section_records, units
  --   SetNull:  club_inventory, finances (implicit Prisma default for optional)
  --   Cascade:  club_role_assignments
  --   NoAction: folder_assignments (new FK — was orphan before)
  -- =============================================

  -- 4a. activities (onDelete: NO ACTION — matches existing)
  ALTER TABLE "activities"
    ADD CONSTRAINT "activities_club_section_id_fkey"
    FOREIGN KEY ("club_section_id") REFERENCES "club_sections"("club_section_id")
    ON DELETE NO ACTION ON UPDATE NO ACTION;

  CREATE INDEX "idx_activities_club_section" ON "activities"("club_section_id");

  -- 4b. activity_instances (onDelete: NO ACTION — matches existing)
  ALTER TABLE "activity_instances"
    ADD CONSTRAINT "activity_instances_club_section_id_fkey"
    FOREIGN KEY ("club_section_id") REFERENCES "club_sections"("club_section_id")
    ON DELETE NO ACTION ON UPDATE NO ACTION;

  CREATE INDEX "idx_activity_instances_club_section" ON "activity_instances"("club_section_id");

  -- 4c. folder_assignments (onDelete: NO ACTION — new FK, safe default)
  ALTER TABLE "folder_assignments"
    ADD CONSTRAINT "folder_assignments_club_section_id_fkey"
    FOREIGN KEY ("club_section_id") REFERENCES "club_sections"("club_section_id")
    ON DELETE NO ACTION ON UPDATE NO ACTION;

  CREATE INDEX "idx_folder_assignments_club_section" ON "folder_assignments"("club_section_id");

  -- 4d. camporee_clubs (onDelete: NO ACTION — matches existing)
  ALTER TABLE "camporee_clubs"
    ADD CONSTRAINT "camporee_clubs_club_section_id_fkey"
    FOREIGN KEY ("club_section_id") REFERENCES "club_sections"("club_section_id")
    ON DELETE NO ACTION ON UPDATE NO ACTION;

  CREATE INDEX "idx_camporee_clubs_club_section" ON "camporee_clubs"("club_section_id");

  -- 4e. club_inventory (onDelete: SET NULL — matches Prisma implicit default)
  ALTER TABLE "club_inventory"
    ADD CONSTRAINT "club_inventory_club_section_id_fkey"
    FOREIGN KEY ("club_section_id") REFERENCES "club_sections"("club_section_id")
    ON DELETE SET NULL ON UPDATE NO ACTION;

  CREATE INDEX "idx_club_inventory_club_section" ON "club_inventory"("club_section_id");

  -- 4f. club_role_assignments (onDelete: CASCADE — matches existing)
  ALTER TABLE "club_role_assignments"
    ADD CONSTRAINT "club_role_assignments_club_section_id_fkey"
    FOREIGN KEY ("club_section_id") REFERENCES "club_sections"("club_section_id")
    ON DELETE CASCADE ON UPDATE NO ACTION;

  CREATE INDEX "idx_club_role_assignments_club_section" ON "club_role_assignments"("club_section_id");

  -- 4g. finances (onDelete: SET NULL — matches Prisma implicit default)
  ALTER TABLE "finances"
    ADD CONSTRAINT "finances_club_section_id_fkey"
    FOREIGN KEY ("club_section_id") REFERENCES "club_sections"("club_section_id")
    ON DELETE SET NULL ON UPDATE NO ACTION;

  CREATE INDEX "idx_finances_club_section" ON "finances"("club_section_id");

  -- 4h. folders_modules_records (onDelete: NO ACTION — matches existing)
  ALTER TABLE "folders_modules_records"
    ADD CONSTRAINT "folders_modules_records_club_section_id_fkey"
    FOREIGN KEY ("club_section_id") REFERENCES "club_sections"("club_section_id")
    ON DELETE NO ACTION ON UPDATE NO ACTION;

  CREATE INDEX "idx_folders_modules_records_club_section" ON "folders_modules_records"("club_section_id");

  -- 4i. folders_section_records (onDelete: NO ACTION — matches existing)
  ALTER TABLE "folders_section_records"
    ADD CONSTRAINT "folders_section_records_club_section_id_fkey"
    FOREIGN KEY ("club_section_id") REFERENCES "club_sections"("club_section_id")
    ON DELETE NO ACTION ON UPDATE NO ACTION;

  CREATE INDEX "idx_folders_section_records_club_section" ON "folders_section_records"("club_section_id");

  -- 4j. units (onDelete: NO ACTION — matches existing)
  ALTER TABLE "units"
    ADD CONSTRAINT "units_club_section_id_fkey"
    FOREIGN KEY ("club_section_id") REFERENCES "club_sections"("club_section_id")
    ON DELETE NO ACTION ON UPDATE NO ACTION;

  CREATE INDEX "idx_units_club_section" ON "units"("club_section_id");

  -- =============================================
  -- PHASE 5: Update unique constraints
  -- =============================================

  -- 5a. club_role_assignments: drop BOTH duplicate unique constraints
  ALTER TABLE "club_role_assignments"
    DROP CONSTRAINT "club_role_assignment_unique";

  ALTER TABLE "club_role_assignments"
    DROP CONSTRAINT "club_role_assignment_unique_refactored";

  -- 5b. club_role_assignments: new unique constraint with club_section_id
  ALTER TABLE "club_role_assignments"
    ADD CONSTRAINT "club_role_assignment_unique"
    UNIQUE ("user_id", "role_id", "club_section_id", "ecclesiastical_year_id", "start_date");

  -- 5c. activity_instances: drop old unique constraint
  ALTER TABLE "activity_instances"
    DROP CONSTRAINT "activity_instances_unique_instance_per_activity";

  -- 5d. activity_instances: new unique constraint with club_section_id
  ALTER TABLE "activity_instances"
    ADD CONSTRAINT "activity_instances_unique_per_section"
    UNIQUE ("activity_id", "club_section_id");

  -- =============================================
  -- PHASE 6: Drop old FK columns from dependent tables
  -- =============================================

  -- 6a. activities — drop old FKs and columns
  ALTER TABLE "activities" DROP CONSTRAINT IF EXISTS "activities_club_adv_id_fkey";
  ALTER TABLE "activities" DROP CONSTRAINT IF EXISTS "activities_club_mg_id_fkey";
  ALTER TABLE "activities" DROP CONSTRAINT IF EXISTS "activities_club_pathf_id_fkey";
  ALTER TABLE "activities" DROP COLUMN "club_adv_id", DROP COLUMN "club_pathf_id", DROP COLUMN "club_mg_id";

  -- 6b. activity_instances — drop old FKs and columns
  ALTER TABLE "activity_instances" DROP CONSTRAINT IF EXISTS "activity_instances_club_adv_id_fkey";
  ALTER TABLE "activity_instances" DROP CONSTRAINT IF EXISTS "activity_instances_club_pathf_id_fkey";
  ALTER TABLE "activity_instances" DROP CONSTRAINT IF EXISTS "activity_instances_club_mg_id_fkey";
  DROP INDEX IF EXISTS "idx_activity_instances_adv";
  DROP INDEX IF EXISTS "idx_activity_instances_pathf";
  DROP INDEX IF EXISTS "idx_activity_instances_mg";
  ALTER TABLE "activity_instances" DROP COLUMN "club_adv_id", DROP COLUMN "club_pathf_id", DROP COLUMN "club_mg_id";

  -- 6c. folder_assignments — drop orphan columns (no FK constraints to drop)
  ALTER TABLE "folder_assignments" DROP COLUMN "club_adv_id", DROP COLUMN "club_pathf_id", DROP COLUMN "club_mg_id";

  -- 6d. camporee_clubs — drop old FKs and columns
  ALTER TABLE "camporee_clubs" DROP CONSTRAINT IF EXISTS "camporee_clubs_club_adv_id_fkey";
  ALTER TABLE "camporee_clubs" DROP CONSTRAINT IF EXISTS "camporee_clubs_club_mg_id_fkey";
  ALTER TABLE "camporee_clubs" DROP CONSTRAINT IF EXISTS "camporee_clubs_club_pathf_id_fkey";
  ALTER TABLE "camporee_clubs" DROP COLUMN "club_adv_id", DROP COLUMN "club_pathf_id", DROP COLUMN "club_mg_id";

  -- 6e. club_inventory — drop old FKs and columns
  ALTER TABLE "club_inventory" DROP CONSTRAINT IF EXISTS "club_inventory_club_adv_id_fkey";
  ALTER TABLE "club_inventory" DROP CONSTRAINT IF EXISTS "club_inventory_club_mg_id_fkey";
  ALTER TABLE "club_inventory" DROP CONSTRAINT IF EXISTS "club_inventory_club_pathf_id_fkey";
  ALTER TABLE "club_inventory" DROP COLUMN "club_adv_id", DROP COLUMN "club_pathf_id", DROP COLUMN "club_mg_id";

  -- 6f. club_role_assignments — drop old FKs, indexes, and columns
  ALTER TABLE "club_role_assignments" DROP CONSTRAINT IF EXISTS "club_role_assignments_club_adv_id_fkey";
  ALTER TABLE "club_role_assignments" DROP CONSTRAINT IF EXISTS "club_role_assignments_club_mg_id_fkey";
  ALTER TABLE "club_role_assignments" DROP CONSTRAINT IF EXISTS "club_role_assignments_club_pathf_id_fkey";
  DROP INDEX IF EXISTS "idx_club_role_assignments_club_adv";
  DROP INDEX IF EXISTS "idx_club_role_assignments_club_mg";
  DROP INDEX IF EXISTS "idx_club_role_assignments_club_pathf";
  ALTER TABLE "club_role_assignments" DROP COLUMN "club_adv_id", DROP COLUMN "club_pathf_id", DROP COLUMN "club_mg_id";

  -- 6g. finances — drop old FKs and columns
  ALTER TABLE "finances" DROP CONSTRAINT IF EXISTS "finances_club_adv_id_fkey";
  ALTER TABLE "finances" DROP CONSTRAINT IF EXISTS "finances_club_mg_id_fkey";
  ALTER TABLE "finances" DROP CONSTRAINT IF EXISTS "finances_club_pathf_id_fkey";
  ALTER TABLE "finances" DROP COLUMN "club_adv_id", DROP COLUMN "club_pathf_id", DROP COLUMN "club_mg_id";

  -- 6h. folders_modules_records — drop old FKs and columns
  ALTER TABLE "folders_modules_records" DROP CONSTRAINT IF EXISTS "fk_act_club_adventurers";
  ALTER TABLE "folders_modules_records" DROP CONSTRAINT IF EXISTS "fk_act_club_master_guild";
  ALTER TABLE "folders_modules_records" DROP CONSTRAINT IF EXISTS "fk_act_club_pathfinders";
  ALTER TABLE "folders_modules_records" DROP COLUMN "club_adv_id", DROP COLUMN "club_pathf_id", DROP COLUMN "club_mg_id";

  -- 6i. folders_section_records — drop old FKs and columns
  --     NOTE: same constraint names as folders_modules_records — Prisma uses map: names
  --     These are DIFFERENT constraints on DIFFERENT tables, despite same names in Prisma.
  --     PostgreSQL namespaces constraints per-table, so this is safe.
  ALTER TABLE "folders_section_records" DROP CONSTRAINT IF EXISTS "fk_act_club_adventurers";
  ALTER TABLE "folders_section_records" DROP CONSTRAINT IF EXISTS "fk_act_club_master_guild";
  ALTER TABLE "folders_section_records" DROP CONSTRAINT IF EXISTS "fk_act_club_pathfinders";
  ALTER TABLE "folders_section_records" DROP COLUMN "club_adv_id", DROP COLUMN "club_pathf_id", DROP COLUMN "club_mg_id";

  -- 6j. units — drop old FKs and columns
  ALTER TABLE "units" DROP CONSTRAINT IF EXISTS "fk_act_club_adventurers";
  ALTER TABLE "units" DROP CONSTRAINT IF EXISTS "fk_act_club_master_guild";
  ALTER TABLE "units" DROP CONSTRAINT IF EXISTS "fk_act_club_pathfinders";
  ALTER TABLE "units" DROP COLUMN "club_adv_id", DROP COLUMN "club_pathf_id", DROP COLUMN "club_mg_id";

  -- =============================================
  -- PHASE 7: Deprecate original tables (NOT drop — 7-day grace period)
  -- =============================================

  ALTER TABLE "club_adventurers"  RENAME TO "club_adventurers_deprecated";
  ALTER TABLE "club_pathfinders"  RENAME TO "club_pathfinders_deprecated";
  ALTER TABLE "club_master_guilds" RENAME TO "club_master_guilds_deprecated";

  -- Add comment with deprecation date for scheduled cleanup
  COMMENT ON TABLE "club_adventurers_deprecated" IS 'DEPRECATED: Consolidated into club_sections. Drop after 7 days grace period.';
  COMMENT ON TABLE "club_pathfinders_deprecated" IS 'DEPRECATED: Consolidated into club_sections. Drop after 7 days grace period.';
  COMMENT ON TABLE "club_master_guilds_deprecated" IS 'DEPRECATED: Consolidated into club_sections. Drop after 7 days grace period.';

  -- =============================================
  -- PHASE 8: Update permission strings
  -- =============================================

  UPDATE "permissions"
  SET permission_name = REPLACE(permission_name, 'club_instances', 'club_sections'),
      modified_at = NOW()
  WHERE permission_name LIKE 'club_instances%';

  -- =============================================
  -- PHASE 9: Cleanup temp table (auto-dropped at end of session for TEMP tables,
  -- but explicit drop for clarity)
  -- =============================================

  DROP TABLE IF EXISTS "_club_section_mapping";
  ```

- [ ] **2.3** Verify the migration SQL is syntactically valid:
  ```bash
  cd /Users/abner/Documents/development/sacdia/sacdia-backend
  # Dry-run parse check (will fail on execution but validates syntax)
  psql "$DATABASE_URL" -c "BEGIN; \i '$MIGRATION_DIR/migration.sql'; ROLLBACK;" 2>&1 | tail -5
  ```
  **Note:** If you want a true dry-run, wrap in BEGIN/ROLLBACK. The transaction will create everything and then roll back.

- [ ] **2.4** **IMPORTANT — constraint name verification:** Before running for real, verify the actual FK constraint names in the database match what we're dropping. Run:
  ```sql
  SELECT conname, conrelid::regclass AS table_name
  FROM pg_constraint
  WHERE contype = 'f'
    AND conrelid IN (
      'activities'::regclass, 'activity_instances'::regclass, 'camporee_clubs'::regclass,
      'club_inventory'::regclass, 'club_role_assignments'::regclass, 'finances'::regclass,
      'folders_modules_records'::regclass, 'folders_section_records'::regclass, 'units'::regclass
    )
    AND (conname LIKE '%club_adv%' OR conname LIKE '%club_pathf%' OR conname LIKE '%club_mg%'
         OR conname LIKE '%adventurers%' OR conname LIKE '%pathfinders%' OR conname LIKE '%master_guild%')
  ORDER BY table_name, conname;
  ```
  If any constraint name differs from what the migration drops, update the `DROP CONSTRAINT` statements to match. The `IF EXISTS` guard prevents hard failures, but you'd leave orphan constraints.

---

### Task 3: Prisma schema update

> Update `schema.prisma` to reflect the post-migration state. Remove 3 old models, add `club_sections`, update 10 dependent models and `club_types` + `clubs`.

**File:** `/Users/abner/Documents/development/sacdia/sacdia-backend/prisma/schema.prisma`

- [ ] **3.1** Add the new `club_sections` model. Insert it AFTER the `clubs` model (after line 289). Exact content:
  ```prisma
  model club_sections {
    club_section_id        Int                       @id @default(autoincrement())
    active                 Boolean                   @default(false)
    souls_target           Int                       @default(1)
    fee                    Int                       @default(1)
    meeting_day            Json[]                    @db.Json
    meeting_time           Json[]                    @db.Json
    club_type_id           Int
    main_club_id           Int?
    created_at             DateTime                  @default(now()) @db.Timestamptz(6)
    modified_at            DateTime                  @default(now()) @updatedAt @db.Timestamptz(6)

    // Relations — parent
    club_types             club_types                @relation(fields: [club_type_id], references: [club_type_id], onDelete: NoAction, onUpdate: NoAction)
    clubs                  clubs?                    @relation(fields: [main_club_id], references: [club_id], onDelete: Cascade, onUpdate: NoAction)

    // Relations — children (10 dependent tables)
    activities             activities[]
    activity_instances     activity_instances[]
    camporee_clubs         camporee_clubs[]
    club_inventory         club_inventory[]
    club_role_assignments  club_role_assignments[]
    finances               finances[]
    folder_assignments     folder_assignments[]
    folders_modules_records folders_modules_records[]
    folders_section_records folders_section_records[]
    units                  units[]

    @@unique([main_club_id, club_type_id])
  }
  ```

- [ ] **3.2** Delete the 3 old models completely:
  - Delete `model club_adventurers { ... }` (lines 291-313)
  - Delete `model club_pathfinders { ... }` (lines 315-337)
  - Delete `model club_master_guilds { ... }` (lines 339-361)

- [ ] **3.3** Update `model activities` — replace 3 FK columns + 3 relations with 1:
  - Remove lines: `club_adv_id Int?`, `club_mg_id Int?`, `club_pathf_id Int?`
  - Remove lines: `club_adv_i club_adventurers? @relation(...)`, `club_mg club_master_guilds? @relation(...)`, `club_pathf club_pathfinders? @relation(...)`
  - Add: `club_section_id Int?`
  - Add: `club_sections club_sections? @relation(fields: [club_section_id], references: [club_section_id], onDelete: NoAction, onUpdate: NoAction)`

- [ ] **3.4** Update `model activity_instances` — replace 3 FK columns + 3 relations with 1:
  - Remove: `club_adv_id Int?`, `club_pathf_id Int?`, `club_mg_id Int?`
  - Remove: `club_adventurers club_adventurers? @relation(...)`, `club_pathfinders club_pathfinders? @relation(...)`, `club_master_guilds club_master_guilds? @relation(...)`
  - Remove old indexes: `@@index([club_adv_id], ...)`, `@@index([club_pathf_id], ...)`, `@@index([club_mg_id], ...)`
  - Remove old unique: `@@unique([activity_id, club_adv_id, club_pathf_id, club_mg_id], ...)`
  - Add: `club_section_id Int?`
  - Add: `club_sections club_sections? @relation(fields: [club_section_id], references: [club_section_id], onDelete: NoAction, onUpdate: NoAction)`
  - Add: `@@index([club_section_id], map: "idx_activity_instances_club_section")`
  - Add: `@@unique([activity_id, club_section_id], map: "activity_instances_unique_per_section")`

- [ ] **3.5** Update `model folder_assignments` — replace 3 orphan columns with 1 FK:
  - Remove: `club_adv_id Int?`, `club_pathf_id Int?`, `club_mg_id Int?`
  - Add: `club_section_id Int?`
  - Add: `club_sections club_sections? @relation(fields: [club_section_id], references: [club_section_id], onDelete: NoAction, onUpdate: NoAction)`

- [ ] **3.6** Update `model camporee_clubs` — replace 3 FKs + 3 relations with 1:
  - Remove: `club_adv_id Int?`, `club_mg_id Int?`, `club_pathf_id Int?`
  - Remove: `club_adv club_adventurers? @relation(...)`, `club_mg club_master_guilds? @relation(...)`, `club_pathf club_pathfinders? @relation(...)`
  - Add: `club_section_id Int?`
  - Add: `club_sections club_sections? @relation(fields: [club_section_id], references: [club_section_id], onDelete: NoAction, onUpdate: NoAction)`

- [ ] **3.7** Update `model club_inventory` — replace 3 FKs + 3 relations with 1:
  - Remove: `club_adv_id Int?`, `club_mg_id Int?`, `club_pathf_id Int?`
  - Remove: `club_adventurers club_adventurers? @relation(...)`, `club_master_guild club_master_guilds? @relation(...)`, `club_pathfinders club_pathfinders? @relation(...)`
  - Add: `club_section_id Int?`
  - Add: `club_sections club_sections? @relation(fields: [club_section_id], references: [club_section_id], onDelete: SetNull, onUpdate: NoAction)`

- [ ] **3.8** Update `model club_role_assignments` — replace 3 FKs + 3 relations with 1:
  - Remove: `club_adv_id Int?`, `club_pathf_id Int?`, `club_mg_id Int?`
  - Remove: `club_adventurers club_adventurers? @relation(...)`, `club_master_guild club_master_guilds? @relation(...)`, `club_pathfinders club_pathfinders? @relation(...)`
  - Remove both `@@unique` constraints (the two duplicate ones)
  - Remove: `@@index([club_adv_id], ...)`, `@@index([club_mg_id], ...)`, `@@index([club_pathf_id], ...)`
  - Add: `club_section_id Int?`
  - Add: `club_sections club_sections? @relation(fields: [club_section_id], references: [club_section_id], onDelete: Cascade, onUpdate: NoAction)`
  - Add: `@@unique([user_id, role_id, club_section_id, ecclesiastical_year_id, start_date], map: "club_role_assignment_unique")`
  - Add: `@@index([club_section_id], map: "idx_club_role_assignments_club_section")`

- [ ] **3.9** Update `model finances` — replace 3 FKs + 3 relations with 1:
  - Remove: `club_adv_id Int?`, `club_mg_id Int?`, `club_pathf_id Int?`
  - Remove: `club_adventurers club_adventurers? @relation(...)`, `club_master_guild club_master_guilds? @relation(...)`, `club_pathfinders club_pathfinders? @relation(...)`
  - Add: `club_section_id Int?`
  - Add: `club_sections club_sections? @relation(fields: [club_section_id], references: [club_section_id], onDelete: SetNull, onUpdate: NoAction)`

- [ ] **3.10** Update `model folders_modules_records` — replace 3 FKs + 3 relations with 1:
  - Remove: `club_adv_id Int?`, `club_mg_id Int?`, `club_pathf_id Int?`
  - Remove: `club_adventurers club_adventurers? @relation(...)`, `club_master_guild club_master_guilds? @relation(...)`, `club_pathfinders club_pathfinders? @relation(...)`
  - Add: `club_section_id Int?`
  - Add: `club_sections club_sections? @relation(fields: [club_section_id], references: [club_section_id], onDelete: NoAction, onUpdate: NoAction)`

- [ ] **3.11** Update `model folders_section_records` — replace 3 FKs + 3 relations with 1:
  - Remove: `club_adv_id Int?`, `club_mg_id Int?`, `club_pathf_id Int?`
  - Remove: `club_adventurers club_adventurers? @relation(...)`, `club_master_guild club_master_guilds? @relation(...)`, `club_pathfinders club_pathfinders? @relation(...)`
  - Add: `club_section_id Int?`
  - Add: `club_sections club_sections? @relation(fields: [club_section_id], references: [club_section_id], onDelete: NoAction, onUpdate: NoAction)`

- [ ] **3.12** Update `model units` — replace 3 FKs + 3 relations with 1:
  - Remove: `club_adv_id Int?`, `club_mg_id Int?`, `club_pathf_id Int?`
  - Remove: `club_adventurers club_adventurers? @relation(...)`, `club_master_guild club_master_guilds? @relation(...)`, `club_pathfinders club_pathfinders? @relation(...)`
  - Add: `club_section_id Int?`
  - Add: `club_sections club_sections? @relation(fields: [club_section_id], references: [club_section_id], onDelete: NoAction, onUpdate: NoAction)`

- [ ] **3.13** Update `model club_types` — replace 3 child relations with 1:
  - Remove: `club_adventurers club_adventurers[]`
  - Remove: `club_master_guild club_master_guilds[]`
  - Remove: `club_pathfinders club_pathfinders[]`
  - Add: `club_sections club_sections[]`

- [ ] **3.14** Update `model clubs` — replace 3 child relations with 1:
  - Remove: `club_adventurers club_adventurers[]`
  - Remove: `club_master_guild club_master_guilds[]`
  - Remove: `club_pathfinders club_pathfinders[]`
  - Add: `club_sections club_sections[]`

- [ ] **3.15** Validate the schema:
  ```bash
  cd /Users/abner/Documents/development/sacdia/sacdia-backend
  npx prisma validate
  ```
  **Expected output:** `The schema is valid.` with no errors.

- [ ] **3.16** Generate the Prisma client to verify types compile:
  ```bash
  cd /Users/abner/Documents/development/sacdia/sacdia-backend
  npx prisma generate
  ```
  **Expected output:** `Generated Prisma Client` with no errors.

- [ ] **3.17** Mark migration as applied (since we wrote the SQL manually):
  ```bash
  cd /Users/abner/Documents/development/sacdia/sacdia-backend
  npx prisma migrate resolve --applied "$(basename $MIGRATION_DIR)"
  ```
  **Note:** Only run this AFTER the SQL migration has been applied to the database. If using `prisma migrate deploy`, skip this step — Prisma will detect the pending migration and apply it.

---

### Task 4: Post-migration verification

> Verification script to run AFTER migration. Confirms data integrity, constraint correctness, and zero data loss.

**File:** `sacdia-backend/prisma/migrations/scripts/post-migration-verify.sql`

- [ ] **4.1** Create `post-migration-verify.sql` with this exact content:
  ```sql
  -- =============================================================
  -- POST-MIGRATION VERIFICATION: Club Sections Consolidation
  -- Run AFTER applying the migration.
  -- All checks should pass (expected values in comments).
  -- =============================================================

  -- 1. Row count in club_sections matches sum of deprecated tables
  --    Expected: total = adv + pathf + mg from pre-audit
  SELECT 'club_sections_count' AS check_name,
    (SELECT COUNT(*) FROM club_sections) AS actual,
    (SELECT COUNT(*) FROM club_adventurers_deprecated)
    + (SELECT COUNT(*) FROM club_pathfinders_deprecated)
    + (SELECT COUNT(*) FROM club_master_guilds_deprecated) AS expected,
    CASE
      WHEN (SELECT COUNT(*) FROM club_sections) =
           (SELECT COUNT(*) FROM club_adventurers_deprecated)
           + (SELECT COUNT(*) FROM club_pathfinders_deprecated)
           + (SELECT COUNT(*) FROM club_master_guilds_deprecated)
      THEN 'PASS' ELSE 'FAIL'
    END AS result;

  -- 2. No orphan club_section_id in any dependent table
  --    Expected: 0 orphans for each
  SELECT 'activities_orphans' AS check_name,
    COUNT(*) AS orphan_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
  FROM activities a
  WHERE a.club_section_id IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM club_sections cs WHERE cs.club_section_id = a.club_section_id)
  UNION ALL
  SELECT 'activity_instances_orphans', COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
  FROM activity_instances ai
  WHERE ai.club_section_id IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM club_sections cs WHERE cs.club_section_id = ai.club_section_id)
  UNION ALL
  SELECT 'club_role_assignments_orphans', COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
  FROM club_role_assignments cra
  WHERE cra.club_section_id IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM club_sections cs WHERE cs.club_section_id = cra.club_section_id)
  UNION ALL
  SELECT 'units_orphans', COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
  FROM units u
  WHERE u.club_section_id IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM club_sections cs WHERE cs.club_section_id = u.club_section_id)
  UNION ALL
  SELECT 'finances_orphans', COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
  FROM finances f
  WHERE f.club_section_id IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM club_sections cs WHERE cs.club_section_id = f.club_section_id)
  UNION ALL
  SELECT 'camporee_clubs_orphans', COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
  FROM camporee_clubs cc
  WHERE cc.club_section_id IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM club_sections cs WHERE cs.club_section_id = cc.club_section_id);

  -- 3. Old columns are gone (these should ERROR if columns exist — wrapped in DO block)
  DO $$
  BEGIN
    -- Verify columns dropped from activities
    IF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'activities' AND column_name IN ('club_adv_id', 'club_pathf_id', 'club_mg_id')
    ) THEN
      RAISE EXCEPTION 'OLD COLUMNS STILL EXIST in activities';
    END IF;

    -- Verify columns dropped from club_role_assignments
    IF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'club_role_assignments' AND column_name IN ('club_adv_id', 'club_pathf_id', 'club_mg_id')
    ) THEN
      RAISE EXCEPTION 'OLD COLUMNS STILL EXIST in club_role_assignments';
    END IF;

    -- Verify columns dropped from units
    IF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'units' AND column_name IN ('club_adv_id', 'club_pathf_id', 'club_mg_id')
    ) THEN
      RAISE EXCEPTION 'OLD COLUMNS STILL EXIST in units';
    END IF;

    RAISE NOTICE 'All old columns successfully dropped.';
  END $$;

  -- 4. New FK constraints exist
  SELECT conname, conrelid::regclass AS table_name, 'PASS' AS result
  FROM pg_constraint
  WHERE contype = 'f'
    AND conname LIKE '%club_section_id_fkey'
  ORDER BY table_name;
  -- Expected: 10 rows (one per dependent table)

  -- 5. New indexes exist
  SELECT indexname, tablename, 'PASS' AS result
  FROM pg_indexes
  WHERE indexname LIKE '%club_section%'
  ORDER BY tablename;
  -- Expected: 10+ rows

  -- 6. UNIQUE constraints are correct
  SELECT conname, conrelid::regclass AS table_name
  FROM pg_constraint
  WHERE contype = 'u'
    AND conrelid IN ('club_role_assignments'::regclass, 'activity_instances'::regclass, 'club_sections'::regclass)
  ORDER BY table_name, conname;
  -- Expected:
  --   activity_instances: activity_instances_unique_per_section
  --   club_role_assignments: club_role_assignment_unique (NEW one with club_section_id)
  --   club_sections: club_sections_main_club_id_club_type_id_key

  -- 7. No duplicate unique constraints remain on club_role_assignments
  SELECT conname FROM pg_constraint
  WHERE conrelid = 'club_role_assignments'::regclass AND contype = 'u';
  -- Expected: exactly 1 row (club_role_assignment_unique)

  -- 8. Deprecated tables still exist (for rollback safety)
  SELECT tablename, 'EXISTS' AS status
  FROM pg_tables
  WHERE tablename IN ('club_adventurers_deprecated', 'club_pathfinders_deprecated', 'club_master_guilds_deprecated');
  -- Expected: 3 rows

  -- 9. Permission strings updated
  SELECT permission_name, 'FAIL — still has club_instances' AS result
  FROM permissions WHERE permission_name LIKE 'club_instances%'
  UNION ALL
  SELECT permission_name, 'PASS' FROM permissions WHERE permission_name LIKE 'club_sections%';
  -- Expected: only PASS rows, zero FAIL rows

  -- 10. club_sections has correct club_type distribution
  SELECT ct.name AS club_type, COUNT(*) AS section_count
  FROM club_sections cs
  JOIN club_types ct ON cs.club_type_id = ct.club_type_id
  GROUP BY ct.name
  ORDER BY ct.name;
  -- Expected: matches pre-audit query 2
  ```

- [ ] **4.2** Run the verification:
  ```bash
  cd /Users/abner/Documents/development/sacdia/sacdia-backend
  psql "$DATABASE_URL" -f prisma/migrations/scripts/post-migration-verify.sql
  ```
  **Expected:** All checks show PASS. Zero FAIL rows. 10 FK constraints. 10+ indexes.

- [ ] **4.3** Run Prisma validation against the live database:
  ```bash
  cd /Users/abner/Documents/development/sacdia/sacdia-backend
  npx prisma db pull --force
  npx prisma validate
  ```
  **Expected:** Schema introspected successfully. `The schema is valid.` This confirms the Prisma schema matches the actual database state.

- [ ] **4.4** Restore the handwritten schema (db pull overwrites it):
  ```bash
  cd /Users/abner/Documents/development/sacdia/sacdia-backend
  git checkout -- prisma/schema.prisma
  ```
  **Why:** `prisma db pull` overwrites formatting and comments. We want our clean handwritten schema.

- [ ] **4.5** Generate Prisma client one final time to confirm types:
  ```bash
  cd /Users/abner/Documents/development/sacdia/sacdia-backend
  npx prisma generate
  ```

---

### Chunk 1 Completion Criteria

All of these must be true before moving to Chunk 2 (Backend NestJS changes):

1. Pre-audit ran with zero anomalies (multi-FK = 0, orphans = 0)
2. Migration SQL applied successfully (all 9 phases)
3. `npx prisma validate` passes with the updated schema
4. `npx prisma generate` succeeds
5. Post-migration verification shows all PASS
6. 10 FK constraints + 10 indexes confirmed on `club_section_id`
7. Both duplicate `club_role_assignment_unique*` constraints replaced by single new one
8. 3 deprecated tables exist with comments
9. Zero `club_instances%` permission strings remain

---

## Chunk 2: Backend NestJS — Club Sections Consolidation

**Prerequisito:** Chunk 1 completado. Prisma client regenerado con modelo `club_sections`. Las 10 tablas dependientes usan `club_section_id` FK.

---

### Task 5: Rename DTOs & Types

**Files:**
- Create: `sacdia-backend/src/clubs/dto/section.dto.ts`
- Modify: `sacdia-backend/src/clubs/dto/index.ts`
- Modify: `sacdia-backend/src/post-registration/dto/complete-club-selection.dto.ts`
- Delete: `sacdia-backend/src/clubs/dto/instance.dto.ts`
- Delete: `sacdia-backend/src/clubs/dto/instance.dto.spec.ts`

- [ ] **5.1** Create `section.dto.ts` — reemplaza `instance.dto.ts`. `ClubInstanceType` enum se elimina (el tipo viene de `club_types.club_type_id`):

```ts
import { IsInt, IsOptional, IsArray, IsBoolean } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';

export class CreateClubSectionDto {
  @ApiProperty({ example: 2, description: 'ID del tipo de club (FK a club_types)' })
  @Type(() => Number)
  @IsInt()
  club_type_id: number;

  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  souls_target?: number;

  @ApiPropertyOptional({ example: 100 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  fee?: number;

  @ApiPropertyOptional({ example: [{ day: 'Saturday' }] })
  @IsOptional()
  @IsArray()
  meeting_day?: Record<string, unknown>[];

  @ApiPropertyOptional({ example: [{ time: '09:00' }] })
  @IsOptional()
  @IsArray()
  meeting_time?: Record<string, unknown>[];
}

export class UpdateClubSectionDto {
  @ApiPropertyOptional()
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  souls_target?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  fee?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  meeting_day?: Record<string, unknown>[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  meeting_time?: Record<string, unknown>[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  active?: boolean;
}
```

- [ ] **5.2** Update barrel export `sacdia-backend/src/clubs/dto/index.ts`:
  - Replace `export * from './instance.dto'` with `export * from './section.dto'`

- [ ] **5.3** Update `complete-club-selection.dto.ts`:
  - Remove `club_type` field
  - Rename `club_instance_id` → `club_section_id`

- [ ] **5.4** Delete `instance.dto.ts` and `instance.dto.spec.ts`

- [ ] **5.5** Commit:
  ```bash
  git add sacdia-backend/src/clubs/dto/
  git add sacdia-backend/src/post-registration/dto/
  git commit -m "feat(clubs): replace instance DTOs with section DTOs"
  ```

---

### Task 6: Refactor clubs.service.ts

**File:** `sacdia-backend/src/clubs/clubs.service.ts`

- [ ] **6.1** Update imports — replace `ClubInstanceType`, `CreateInstanceDto`, `UpdateInstanceDto` with `CreateClubSectionDto`, `UpdateClubSectionDto`

- [ ] **6.2** Replace `getInstances()` (3 parallel queries + manual mapping) with:
```ts
async getSections(clubId: number) {
  await this.findOne(clubId);
  return this.prisma.club_sections.findMany({
    where: { main_club_id: clubId },
    include: { club_types: { select: { name: true } } },
    orderBy: { club_section_id: 'asc' },
  });
}
```

- [ ] **6.3** Replace `getInstance()` (switch/case) with:
```ts
async getSection(sectionId: number) {
  const section = await this.prisma.club_sections.findUnique({
    where: { club_section_id: sectionId },
    include: { club_types: { select: { name: true } } },
  });
  if (!section) throw new NotFoundException(`Club section ${sectionId} not found`);
  return section;
}
```

- [ ] **6.4** Replace `createInstance()` (switch/case with 3 identical blocks) with:
```ts
async createSection(clubId: number, dto: CreateClubSectionDto) {
  await this.findOne(clubId);
  const clubType = await this.prisma.club_types.findUnique({
    where: { club_type_id: dto.club_type_id },
  });
  if (!clubType || !clubType.active) {
    throw new BadRequestException(`Club type ${dto.club_type_id} not found or inactive`);
  }
  return this.prisma.club_sections.create({
    data: {
      main_club_id: clubId,
      club_type_id: dto.club_type_id,
      souls_target: dto.souls_target || 1,
      fee: dto.fee || 0,
      meeting_day: (dto.meeting_day || []) as Prisma.InputJsonValue[],
      meeting_time: (dto.meeting_time || []) as Prisma.InputJsonValue[],
      active: true,
    },
    include: { club_types: { select: { name: true } } },
  });
}
```

- [ ] **6.5** Replace `updateInstance()` (switch/case) with:
```ts
async updateSection(sectionId: number, dto: UpdateClubSectionDto) {
  return this.prisma.club_sections.update({
    where: { club_section_id: sectionId },
    data: { ...dto, modified_at: new Date() },
    include: { club_types: { select: { name: true } } },
  });
}
```

- [ ] **6.6** Simplify `getMembers()` — remove `type: ClubInstanceType` param, use `club_section_id` directly:
```ts
async getMembers(sectionId: number) {
  return this.prisma.club_role_assignments.findMany({
    where: { club_section_id: sectionId, active: true },
    include: {
      users: { select: { user_id: true, name: true, paternal_last_name: true, maternal_last_name: true, user_image: true } },
      roles: { select: { role_id: true, role_name: true, role_category: true } },
    },
    orderBy: { start_date: 'desc' },
  });
}
```

- [ ] **6.7** Simplify `assignRole()` — replace 3-way null FK assignment with `club_section_id: dto.club_section_id`

- [ ] **6.8** Delete helpers `getClubTypeName()` and `getInstanceWhereClause()`

- [ ] **6.9** Update `findAll()` and `findOne()` includes — replace 3-way relation includes with `club_sections: { include: { club_types: { select: { name: true } } } }`

- [ ] **6.10** Verify: `rg 'club_adventurers|club_pathfinders|club_master_guilds|ClubInstanceType' sacdia-backend/src/clubs/clubs.service.ts` → 0 matches

- [ ] **6.11** Commit:
  ```bash
  git add sacdia-backend/src/clubs/clubs.service.ts
  git commit -m "refactor(clubs): replace instance switch/case methods with section queries"
  ```

---

### Task 7: Refactor clubs.controller.ts

**File:** `sacdia-backend/src/clubs/clubs.controller.ts`

- [ ] **7.1** Update imports — replace old DTOs with new ones

- [ ] **7.2** Replace all routes:

| Step | Old Route | New Route | Changes |
|------|-----------|-----------|---------|
| 7.2a | `GET :clubId/instances` | `GET :clubId/sections` | Permission: `club_sections:read`, method: `getSections()` |
| 7.2b | `GET :clubId/instances/:type/:instanceId` | `GET :clubId/sections/:sectionId` | Remove `:type` param, add `ParseIntPipe` for sectionId |
| 7.2c | `POST :clubId/instances` | `POST :clubId/sections` | Permission: `club_sections:create`, DTO: `CreateClubSectionDto` |
| 7.2d | `PATCH :clubId/instances/:type/:instanceId` | `PATCH :clubId/sections/:sectionId` | Remove `:type`, DTO: `UpdateClubSectionDto` |
| 7.2e | `DELETE :clubId/instances/:type/:instanceId` | `DELETE :clubId/sections/:sectionId` | Remove `:type` |
| 7.2f | `GET :clubId/instances/:type/:instanceId/members` | `GET :clubId/sections/:sectionId/members` | Remove `:type` |

- [ ] **7.3** Verify: `rg 'instances' sacdia-backend/src/clubs/clubs.controller.ts` → 0 matches (club-related)

- [ ] **7.4** Commit:
  ```bash
  git add sacdia-backend/src/clubs/clubs.controller.ts
  git commit -m "refactor(clubs): migrate controller routes from /instances to /sections"
  ```

---

### Task 8: Refactor Guards & Authorization

**Files:**
- `sacdia-backend/src/common/services/authorization-context.service.ts`
- `sacdia-backend/src/common/guards/permissions.guard.ts`

- [ ] **8.1** `authorization-context.service.ts` — Replace `ClubAssignmentRecord` type: remove 3 optional relation blocks (`club_adventurers?`, `club_pathfinders?`, `club_master_guild?`), add single `club_sections?` with `club_section_id`, `club_types`, `clubs`

- [ ] **8.2** `authorization-context.service.ts` — Simplify `resolveUserAuthorization()` query: replace 3 relation includes in club_role_assignments select with single `club_sections: { select: { club_section_id: true, club_types: { select: { name: true } }, clubs: { select: CLUB_SCOPE_SELECT } } }`

- [ ] **8.3** `authorization-context.service.ts` — Simplify `buildClubGrant()`: replace 3 if-blocks (one per club type table) with single block reading `assignment.club_sections`

- [ ] **8.4** `permissions.guard.ts` — Replace `ResolvedInstanceScope` type: `{ mainClubId: number; clubSectionId: number }`

- [ ] **8.5** `permissions.guard.ts` — Simplify `resolveActivityScope()`: replace 3-way FK query with single `club_section_id` + `club_sections.main_club_id`

- [ ] **8.6** `permissions.guard.ts` — Simplify `resolveFinanceScope()`: same pattern

- [ ] **8.7** `permissions.guard.ts` — Replace `resolveInventoryInstanceScope()` (~70 lines, switch with 3 branches) with single `club_sections.findUnique` query (~15 lines)

- [ ] **8.8** `permissions.guard.ts` — Delete `buildInstanceScopeFromRecord()` (3-way if-chain) and `normalizeInstanceType()` — no longer needed

- [ ] **8.9** Verify: `rg 'club_adv_id|club_pathf_id|club_mg_id|normalizeInstanceType' sacdia-backend/src/common/` → 0 matches

- [ ] **8.10** Commit:
  ```bash
  git add sacdia-backend/src/common/
  git commit -m "refactor(auth): simplify guards from 3-way instance lookups to club_section_id"
  ```

---

### Task 9: Update Peripheral Services

- [ ] **9.1** `post-registration.service.ts`:
  - Delete `ClubInstanceField` type and `resolveClubInstanceField()` method
  - In `completeStep3()`: use `dto.club_section_id` directly, simplify `resolveSelectedClub()` to query `club_sections`
  - In `resolveMemberAssignment()`: replace dynamic FK key with `club_section_id`

- [ ] **9.2** Commit: `git commit -m "refactor(post-registration): migrate to club_section_id"`

- [ ] **9.3** `activities.service.ts`:
  - Replace 3-way relation includes with `club_sections` include
  - Simplify `findByClub()`: query `club_sections` for sectionIds, use `IN` filter
  - Delete `buildInstanceConditions()`, `selectPrimaryInstance()`, `extractInstanceSelections()`
  - Simplify `attachInstances()` to read from `club_sections`

- [ ] **9.4** Commit: `git commit -m "refactor(activities): migrate to club_section_id"`

- [ ] **9.5** `notifications.service.ts`:
  - Simplify `sendToClubMembers(clubSectionId, dto)` — remove `instanceType` param, query `club_role_assignments` by `club_section_id`

- [ ] **9.6** `folders.service.ts`:
  - Rename `getUserClubInstances()` → `getUserClubSection()`
  - Replace all 3-way OR queries with `club_section_id` direct
  - Simplify `enrollUser()`, `getFolderProgress()`, `updateSectionProgress()`

- [ ] **9.7** `finances.service.ts`: Replace 3-way FKs with `club_section_id`

- [ ] **9.8** `inventory.service.ts`: Replace `instanceType` param with `sectionId`, delete `buildWhereClause()` helper

- [ ] **9.9** `auth.service.ts`: Replace 3-way relation includes in club_role_assignments query with `club_sections`

- [ ] **9.10** Commit:
  ```bash
  git add sacdia-backend/src/
  git commit -m "refactor(services): migrate all peripheral services to club_section_id"
  ```

---

### Task 10: Permission Constants & Verification

- [ ] **10.1** Verify permission UPDATE was in the migration SQL (Chunk 1): `club_instances:*` → `club_sections:*`

- [ ] **10.2** Search for any remaining `club_instances` references:
  ```bash
  rg 'club_instances' sacdia-backend/src/
  ```
  Expected: 0 matches

- [ ] **10.3** Search for any remaining old FK references:
  ```bash
  rg 'club_adv_id|club_pathf_id|club_mg_id' sacdia-backend/src/
  ```
  Expected: 0 matches

- [ ] **10.4** Search for old method names:
  ```bash
  rg 'getInstance\b|getInstances\b|createInstance\b|updateInstance\b|ClubInstanceType' sacdia-backend/src/
  ```
  Expected: 0 matches (in club context)

---

### Task 11: Update Tests

**Unit tests:**

- [ ] **11.1** `clubs.service.spec.ts` — Update imports, mock data (replace 3-way FKs with `club_section_id`), method calls, delete tests for removed helpers

- [ ] **11.2** `permissions.guard.spec.ts` — Update mock data, remove `normalizeInstanceType` tests, update `ResolvedInstanceScope` references

- [ ] **11.3** `authorization-context.service.spec.ts` — Update mock structure, remove 3-way relation mocks

- [ ] **11.4** `activities.service.spec.ts` — Update mock data, remove `buildInstanceConditions` expectations

- [ ] **11.5** `post-registration.service.spec.ts` — Replace `club_instance_id` with `club_section_id` in test DTOs, remove `club_type`

- [ ] **11.6** `post-registration.controller.spec.ts` — Update request payloads

- [ ] **11.7** `finances.service.spec.ts` — Replace 3-way FK mocks

- [ ] **11.8** `auth.service.spec.ts` — Replace 3-way relation mocks

- [ ] **11.9** Commit: `git commit -m "test(clubs): update unit tests for club-sections consolidation"`

**E2E tests:**

- [ ] **11.10** `test/clubs.e2e-spec.ts` — Update route paths, remove `:type` segment, update payloads

- [ ] **11.11** `test/post-registration.e2e-spec.ts` — Replace `club_instance_id` → `club_section_id`

- [ ] **11.12** `test/activities.e2e-spec.ts` — Update instance references

- [ ] **11.13** Commit: `git commit -m "test(e2e): update E2E tests for club-sections consolidation"`

**Verification:**

- [ ] **11.14** Run unit tests:
  ```bash
  cd sacdia-backend && pnpm test
  ```
  Expected: ALL PASS

- [ ] **11.15** Run E2E tests:
  ```bash
  cd sacdia-backend && pnpm test:e2e
  ```
  Expected: ALL PASS

- [ ] **11.16** Build check:
  ```bash
  cd sacdia-backend && pnpm build
  ```
  Expected: SUCCESS

---

### Chunk 2 Completion Criteria

1. Zero references to `club_instances`, `ClubInstanceType`, `club_adv_id`, `club_pathf_id`, `club_mg_id` in `sacdia-backend/src/`
2. All routes use `/sections/:sectionId` (no `:type` param)
3. All permission decorators use `club_sections:*`
4. `pnpm build` passes
5. `pnpm test` passes
6. `pnpm test:e2e` passes

---

## Chunk 3: Admin (Next.js / sacdia-admin)

> Actualizar tipos, API calls, server actions, componentes y pages que referencian el patron `club-instances` / 3 tablas para usar el modelo unificado `club_sections`.

**Files affected (9):**
- `sacdia-admin/src/lib/api/clubs.ts` — types + API functions
- `sacdia-admin/src/lib/api/notifications.ts` — `ClubInstanceType`
- `sacdia-admin/src/lib/clubs/actions.ts` — server actions
- `sacdia-admin/src/lib/notifications/actions.ts` — notification action
- `sacdia-admin/src/lib/auth/permissions.ts` — permission constants
- `sacdia-admin/src/lib/auth/permission-utils.ts` — permission helpers
- `sacdia-admin/src/components/clubs/club-instances-panel.tsx` — rename to `club-sections-panel.tsx`
- `sacdia-admin/src/components/notifications/notification-forms.tsx` — club notification form
- `sacdia-admin/src/app/(dashboard)/dashboard/clubs/[id]/page.tsx` — club detail page

### Task 12: Update API types and functions (`src/lib/api/clubs.ts`)

> Replace all `ClubInstance*` types and `*ClubInstance*` functions with `ClubSection*` equivalents. API URLs change from `/instances/:type/:instanceId` to `/sections/:sectionId`.

**File:** `sacdia-admin/src/lib/api/clubs.ts`

- [ ] **12.1** Replace the `ClubInstance` type with `ClubSection`:
  ```typescript
  // BEFORE (lines 43-53):
  export type ClubInstance = {
    instance_id: number;
    instance_type: "adventurers" | "pathfinders" | "master_guilds";
    club_type_id: number;
    name: string;
    active: boolean;
    members_count?: number;
  };

  export type ClubInstanceType = ClubInstance["instance_type"];

  // AFTER:
  export type ClubSection = {
    club_section_id: number;
    club_type_id: number;
    club_type?: { name?: string; slug?: string } | null;
    name: string;
    active: boolean;
    souls_target?: number;
    fee?: number;
    meeting_day?: Array<{ day: string }>;
    meeting_time?: Array<{ time: string }>;
    members_count?: number;
  };
  ```

- [ ] **12.2** Replace `ClubInstancePayload` with `ClubSectionPayload`:
  ```typescript
  // BEFORE (lines 54-63):
  export type ClubInstancePayload = {
    type: ClubInstanceType;
    club_type_id?: number;
    name?: string;
    souls_target?: number;
    fee?: number;
    meeting_day?: Array<{ day: string }>;
    meeting_time?: Array<{ time: string }>;
    active?: boolean;
  };

  // AFTER:
  export type ClubSectionPayload = {
    club_type_id: number;
    name?: string;
    souls_target?: number;
    fee?: number;
    meeting_day?: Array<{ day: string }>;
    meeting_time?: Array<{ time: string }>;
    active?: boolean;
  };
  ```

- [ ] **12.3** Replace `ClubInstanceMembersQuery` and `ClubInstanceMember` with `ClubSectionMembersQuery` and `ClubSectionMember`:
  ```typescript
  // BEFORE (lines 65-80):
  export type ClubInstanceMembersQuery = { ... };
  export type ClubInstanceMember = { ... };

  // AFTER:
  export type ClubSectionMembersQuery = {
    yearId?: number;
    active?: boolean;
  };

  export type ClubSectionMember = {
    assignment_id?: string;
    user_id: string;
    name: string;
    picture_url?: string | null;
    role?: string | null;
    role_display_name?: string | null;
    role_id?: string;
    start_date?: string;
    active?: boolean;
  };
  ```

- [ ] **12.4** Replace `listClubInstances` with `listClubSections`:
  ```typescript
  // BEFORE:
  export async function listClubInstances(clubId: number) {
    return apiRequest(`/clubs/${clubId}/instances`);
  }

  // AFTER:
  export async function listClubSections(clubId: number) {
    return apiRequest(`/clubs/${clubId}/sections`);
  }
  ```

- [ ] **12.5** Replace `createClubInstance` with `createClubSection`:
  ```typescript
  // BEFORE:
  export async function createClubInstance(clubId: number, payload: ClubInstancePayload) {
    return apiRequest(`/clubs/${clubId}/instances`, {
      method: "POST",
      body: payload,
    });
  }

  // AFTER:
  export async function createClubSection(clubId: number, payload: ClubSectionPayload) {
    return apiRequest(`/clubs/${clubId}/sections`, {
      method: "POST",
      body: payload,
    });
  }
  ```

- [ ] **12.6** Replace `updateClubInstance` with `updateClubSection` — signature simplification removes `instanceType`:
  ```typescript
  // BEFORE:
  export async function updateClubInstance(
    clubId: number,
    instanceType: ClubInstanceType,
    instanceId: number,
    payload: Partial<ClubInstancePayload>,
  ) {
    return apiRequest(`/clubs/${clubId}/instances/${instanceType}/${instanceId}`, {
      method: "PATCH",
      body: payload,
    });
  }

  // AFTER:
  export async function updateClubSection(
    clubId: number,
    sectionId: number,
    payload: Partial<ClubSectionPayload>,
  ) {
    return apiRequest(`/clubs/${clubId}/sections/${sectionId}`, {
      method: "PATCH",
      body: payload,
    });
  }
  ```

- [ ] **12.7** Replace `listClubInstanceMembers` with `listClubSectionMembers`:
  ```typescript
  // BEFORE:
  export async function listClubInstanceMembers(
    clubId: number,
    instanceType: ClubInstanceType,
    instanceId: number,
    query: ClubInstanceMembersQuery = {},
  ) {
    return apiRequest(`/clubs/${clubId}/instances/${instanceType}/${instanceId}/members`, {
      params: query,
    });
  }

  // AFTER:
  export async function listClubSectionMembers(
    clubId: number,
    sectionId: number,
    query: ClubSectionMembersQuery = {},
  ) {
    return apiRequest(`/clubs/${clubId}/sections/${sectionId}/members`, {
      params: query,
    });
  }
  ```

- [ ] **12.8** Replace `createClubRoleAssignment` — remove `instanceType` param:
  ```typescript
  // BEFORE:
  export async function createClubRoleAssignment(
    clubId: number,
    instanceType: ClubInstanceType,
    instanceId: number,
    payload: ClubRoleAssignmentCreatePayload,
  ) {
    return apiRequest(`/clubs/${clubId}/instances/${instanceType}/${instanceId}/roles`, {
      method: "POST",
      body: payload,
    });
  }

  // AFTER:
  export async function createClubRoleAssignment(
    clubId: number,
    sectionId: number,
    payload: ClubRoleAssignmentCreatePayload,
  ) {
    return apiRequest(`/clubs/${clubId}/sections/${sectionId}/roles`, {
      method: "POST",
      body: payload,
    });
  }
  ```

- [ ] **12.9** Verify zero references to old types:
  ```bash
  cd sacdia-admin && grep -rn 'ClubInstance\|club_instance\|listClubInstances\|createClubInstance\|updateClubInstance\|ClubInstanceType\|ClubInstancePayload\|ClubInstanceMember' src/lib/api/clubs.ts
  ```
  Expected: zero matches

### Task 13: Update notification API types (`src/lib/api/notifications.ts`)

> Remove `ClubInstanceType` and simplify `sendClubNotification` to use `sectionId` instead of `instanceType + instanceId`.

**File:** `sacdia-admin/src/lib/api/notifications.ts`

- [ ] **13.1** Replace the entire file:
  ```typescript
  import { apiRequest } from "@/lib/api/client";

  export type SendNotificationPayload = {
    user_id: string;
    title: string;
    body: string;
    data?: Record<string, string>;
  };

  export type BroadcastNotificationPayload = {
    title: string;
    body: string;
    data?: Record<string, string>;
  };

  export type ClubNotificationPayload = {
    title: string;
    body: string;
    data?: Record<string, string>;
  };

  export async function sendNotification(payload: SendNotificationPayload) {
    return apiRequest("/notifications/send", {
      method: "POST",
      body: payload,
    });
  }

  export async function broadcastNotification(payload: BroadcastNotificationPayload) {
    return apiRequest("/notifications/broadcast", {
      method: "POST",
      body: payload,
    });
  }

  export async function sendClubNotification(
    sectionId: number,
    payload: ClubNotificationPayload,
  ) {
    return apiRequest(`/notifications/section/${sectionId}`, {
      method: "POST",
      body: payload,
    });
  }
  ```

- [ ] **13.2** Verify no reference to `ClubInstanceType`:
  ```bash
  cd sacdia-admin && grep -rn 'ClubInstanceType\|instanceType' src/lib/api/notifications.ts
  ```
  Expected: zero matches

### Task 14: Refactor server actions (`src/lib/clubs/actions.ts`)

> Replace the entire sync-by-3-types pattern with a unified section model. Remove `MANAGED_INSTANCE_TYPES`, `parseInstanceType`, `getInstanceByType`, `buildClubInstancePath`. Simplify all action functions.

**File:** `sacdia-admin/src/lib/clubs/actions.ts`

- [ ] **14.1** Update imports — replace all `Instance` imports with `Section` equivalents:
  ```typescript
  // BEFORE:
  import {
    createClub,
    createClubInstance,
    createClubRoleAssignment,
    deleteClub,
    listClubInstances,
    revokeClubRoleAssignment,
    updateClub,
    updateClubInstance,
    updateClubRoleAssignment,
    type ClubInstance,
    type ClubInstanceType,
  } from "@/lib/api/clubs";

  // AFTER:
  import {
    createClub,
    createClubSection,
    createClubRoleAssignment,
    deleteClub,
    listClubSections,
    revokeClubRoleAssignment,
    updateClub,
    updateClubSection,
    updateClubRoleAssignment,
    type ClubSection,
  } from "@/lib/api/clubs";
  ```

- [ ] **14.2** Remove the 3-type sync infrastructure (lines 21-68) and replace with simplified section types:
  ```typescript
  // DELETE these entirely:
  // - MANAGED_INSTANCE_TYPES
  // - ManagedInstanceType
  // - ClubInstanceSyncInput
  // - ClubInstanceSyncResult (rename to ClubSectionSyncResult)
  // - parseInstanceType()
  // - parseManagedInstanceType()
  // - buildClubInstancePath()
  // - readManagedInstanceInput()
  // - readManagedInstanceInputs()
  // - normalizeCreatedInstanceId()
  // - getInstanceByType()
  // - executeInstanceSyncAction()

  // REPLACE with:
  export type ClubSectionSyncResult = {
    action: "created" | "updated" | "deactivated" | "unchanged" | "failed";
    ok: boolean;
    message: string;
    sectionId?: number;
  };

  export type ClubActionState = {
    error?: string;
    success?: string;
    createdClubId?: number;
    sectionResults?: ClubSectionSyncResult[];
  };
  ```

- [ ] **14.3** Replace `buildClubInstancePath` with `buildClubSectionPath`:
  ```typescript
  function buildClubSectionPath(clubId: number, sectionId: number) {
    return `/dashboard/clubs/${clubId}/sections/${sectionId}`;
  }
  ```

- [ ] **14.4** Replace `normalizeCreatedInstanceId` with `normalizeCreatedSectionId`:
  ```typescript
  function normalizeCreatedSectionId(payload: unknown) {
    const created = unwrapObject<Record<string, unknown>>(payload);
    const candidateIds = [created?.club_section_id, created?.id];
    for (const candidateId of candidateIds) {
      const parsed = Number(candidateId);
      if (Number.isFinite(parsed) && parsed > 0) {
        return parsed;
      }
    }
    return undefined;
  }
  ```

- [ ] **14.5** Refactor `syncClubInstancesAction` to `syncClubSectionsAction` — process individual section sync instead of 3-type loop:
  ```typescript
  export async function syncClubSectionsAction(
    clubId: number,
    _: ClubActionState,
    formData: FormData,
  ): Promise<ClubActionState> {
    const sectionIdRaw = readString(formData, "section_id");
    const name = readString(formData, "name");
    const clubTypeIdRaw = readString(formData, "club_type_id");
    const activeRaw = readString(formData, "active");

    const sectionId = sectionIdRaw ? Number(sectionIdRaw) : null;
    const clubTypeId = clubTypeIdRaw ? Number(clubTypeIdRaw) : null;

    if (!clubTypeId || !Number.isFinite(clubTypeId)) {
      return { error: "Tipo de club obligatorio." };
    }

    try {
      if (sectionId && Number.isFinite(sectionId)) {
        // Update existing section
        const payload: Record<string, unknown> = {};
        if (name) payload.name = name;
        if (clubTypeId) payload.club_type_id = clubTypeId;
        if (activeRaw) payload.active = activeRaw === "true";

        await updateClubSection(clubId, sectionId, payload);
        revalidatePath(`/dashboard/clubs/${clubId}`);
        return { success: "Sección actualizada correctamente." };
      } else {
        // Create new section
        await createClubSection(clubId, {
          club_type_id: clubTypeId,
          name: name || undefined,
        });
        revalidatePath(`/dashboard/clubs/${clubId}`);
        return { success: "Sección creada correctamente." };
      }
    } catch (error) {
      return {
        error: getActionErrorMessage(error, "No se pudo sincronizar la sección", {
          endpointLabel: `/clubs/${clubId}/sections`,
        }),
      };
    }
  }
  ```

- [ ] **14.6** Refactor `createClubWithInstancesAction` — replace the 3-type instance loop with section-based creation:
  ```typescript
  export async function createClubWithSectionsAction(
    _: ClubActionState,
    formData: FormData,
  ): Promise<ClubActionState> {
    let clubId: number | null = null;

    try {
      const payload = buildCreatePayload(formData);
      const createdPayload = await createClub(payload);
      clubId = normalizeCreatedClubId(createdPayload);
    } catch (error) {
      return {
        error: getActionErrorMessage(error, "No se pudo crear el club", {
          endpointLabel: "/clubs",
        }),
      };
    }

    if (!clubId) {
      return {
        error: "Club creado, pero no se pudo resolver su ID para continuar con secciones.",
      };
    }

    // Parse sections from form — form fields: section_club_type_id_0, section_name_0, etc.
    const sectionResults: ClubSectionSyncResult[] = [];
    let idx = 0;
    while (formData.has(`section_club_type_id_${idx}`)) {
      const clubTypeId = Number(readString(formData, `section_club_type_id_${idx}`));
      const sectionName = readString(formData, `section_name_${idx}`);

      if (!Number.isFinite(clubTypeId) || clubTypeId <= 0) {
        idx++;
        continue;
      }

      try {
        const result = await createClubSection(clubId, {
          club_type_id: clubTypeId,
          name: sectionName || undefined,
        });
        sectionResults.push({
          action: "created",
          ok: true,
          message: "Sección creada.",
          sectionId: normalizeCreatedSectionId(result),
        });
      } catch (error) {
        sectionResults.push({
          action: "failed",
          ok: false,
          message: getActionErrorMessage(error, "No se pudo crear la sección", {
            endpointLabel: `/clubs/${clubId}/sections`,
          }),
        });
      }
      idx++;
    }

    revalidatePath("/dashboard/clubs");
    revalidatePath(`/dashboard/clubs/${clubId}`);

    const failed = sectionResults.filter((r) => !r.ok);
    if (failed.length > 0) {
      return {
        error: "El club se creó, pero una o más secciones fallaron.",
        success: "Puedes continuar al detalle del club y reintentar las secciones fallidas.",
        createdClubId: clubId,
        sectionResults,
      };
    }

    redirect(`/dashboard/clubs/${clubId}`);
  }
  ```

- [ ] **14.7** Refactor `createClubInstanceAction` to `createClubSectionAction`:
  ```typescript
  export async function createClubSectionAction(
    clubId: number,
    _: ClubActionState,
    formData: FormData,
  ): Promise<ClubActionState> {
    const clubTypeIdRaw = readString(formData, "club_type_id");
    const clubTypeId = Number(clubTypeIdRaw);
    if (!Number.isFinite(clubTypeId) || clubTypeId <= 0) {
      return { error: "Tipo de club no válido" };
    }

    const soulsTarget = Number(readString(formData, "souls_target") || "0");
    if (!Number.isFinite(soulsTarget) || soulsTarget < 0) {
      return { error: "Meta de almas debe ser un número positivo" };
    }

    const fee = Number(readString(formData, "fee") || "0");
    if (!Number.isFinite(fee) || fee < 0) {
      return { error: "La cuota debe ser un número positivo" };
    }

    const meetingDayRaw = readString(formData, "meeting_day");
    const meetingTimeRaw = readString(formData, "meeting_time").slice(0, 5) || "09:00";

    const payload: Parameters<typeof createClubSection>[1] = {
      club_type_id: clubTypeId,
    };

    const name = readString(formData, "name");
    if (name) payload.name = name;
    payload.souls_target = soulsTarget;
    payload.fee = fee;
    if (meetingDayRaw) payload.meeting_day = [{ day: meetingDayRaw }];
    payload.meeting_time = [{ time: meetingTimeRaw }];

    try {
      await createClubSection(clubId, payload);
    } catch (error) {
      return {
        error: getActionErrorMessage(error, "No se pudo crear la sección", {
          endpointLabel: `/clubs/${clubId}/sections`,
        }),
      };
    }

    revalidatePath(`/dashboard/clubs/${clubId}`);
    return { success: "Sección creada correctamente" };
  }
  ```

- [ ] **14.8** Refactor `updateClubInstanceAction` to `updateClubSectionAction` — remove `instanceTypeValue` param:
  ```typescript
  export async function updateClubSectionAction(
    clubId: number,
    sectionId: number,
    _: ClubActionState,
    formData: FormData,
  ): Promise<ClubActionState> {
    const payload: { name?: string; active?: boolean; club_type_id?: number } = {};
    const name = readString(formData, "name");
    if (name) {
      payload.name = name;
    }

    const activeRaw = readString(formData, "active");
    if (activeRaw) {
      if (activeRaw !== "true" && activeRaw !== "false") {
        return { error: "El estado de la sección no es válido" };
      }
      payload.active = activeRaw === "true";
    }

    const clubTypeId = parseOptionalPositiveNumber(formData, "club_type_id");
    if (clubTypeId !== undefined) {
      payload.club_type_id = clubTypeId;
    }

    if (Object.keys(payload).length === 0) {
      return { error: "No hay cambios para guardar en la sección" };
    }

    try {
      await updateClubSection(clubId, sectionId, payload);
    } catch (error) {
      return {
        error: getActionErrorMessage(error, "No se pudo actualizar la sección", {
          endpointLabel: `/clubs/${clubId}/sections/${sectionId}`,
        }),
      };
    }

    revalidatePath(`/dashboard/clubs/${clubId}`);
    revalidatePath(buildClubSectionPath(clubId, sectionId));
    return { success: "Sección actualizada correctamente" };
  }
  ```

- [ ] **14.9** Refactor `addClubInstanceMemberAction` to `addClubSectionMemberAction`:
  ```typescript
  export async function addClubSectionMemberAction(
    clubId: number,
    sectionId: number,
    _: ClubActionState,
    formData: FormData,
  ): Promise<ClubActionState> {
    const userId = readString(formData, "user_id");
    if (!userId) {
      return { error: "El ID del usuario es obligatorio" };
    }

    const roleId = readString(formData, "role_id");
    if (!roleId) {
      return { error: "El rol es obligatorio" };
    }

    let ecclesiasticalYearId = 0;
    try {
      ecclesiasticalYearId = parseRequiredNumber(formData, "ecclesiastical_year_id", "Año eclesiástico");
    } catch (error) {
      return { error: error instanceof Error ? error.message : "Año eclesiástico inválido" };
    }

    const startDate = readString(formData, "start_date") || new Date().toISOString();
    const endDate = readString(formData, "end_date") || undefined;

    try {
      await createClubRoleAssignment(clubId, sectionId, {
        user_id: userId,
        role_id: roleId,
        ecclesiastical_year_id: ecclesiasticalYearId,
        start_date: startDate,
        ...(endDate ? { end_date: endDate } : {}),
      });
    } catch (error) {
      return {
        error: getActionErrorMessage(error, "No se pudo crear la asignación de rol", {
          endpointLabel: `/clubs/${clubId}/sections/${sectionId}/roles`,
        }),
      };
    }

    revalidatePath(`/dashboard/clubs/${clubId}`);
    revalidatePath(buildClubSectionPath(clubId, sectionId));
    return { success: "Asignación creada correctamente" };
  }
  ```

- [ ] **14.10** Refactor `updateClubInstanceMemberRoleAction` to `updateClubSectionMemberRoleAction`:
  ```typescript
  export async function updateClubSectionMemberRoleAction(
    clubId: number,
    sectionId: number,
    userId: string,
    _: ClubActionState,
    formData: FormData,
  ): Promise<ClubActionState> {
    if (!userId) {
      return { error: "No se pudo identificar al miembro" };
    }

    const assignmentId = readString(formData, "assignment_id");
    if (!assignmentId) {
      return { error: "No se pudo identificar la asignación a actualizar" };
    }

    const roleId = readString(formData, "role_id");
    if (!roleId) {
      return { error: "El rol es obligatorio" };
    }

    let ecclesiasticalYearId = 0;
    try {
      ecclesiasticalYearId = parseRequiredNumber(formData, "ecclesiastical_year_id", "Año eclesiástico");
    } catch (error) {
      return { error: error instanceof Error ? error.message : "Año eclesiástico inválido" };
    }

    const startDate = readString(formData, "start_date") || new Date().toISOString();

    try {
      await updateClubRoleAssignment(assignmentId, {
        role_id: roleId,
        ecclesiastical_year_id: ecclesiasticalYearId,
        start_date: startDate,
        status: "active",
      });
    } catch (error) {
      return {
        error: getActionErrorMessage(error, "No se pudo actualizar el rol", {
          endpointLabel: `/club-roles/${assignmentId}`,
        }),
      };
    }

    revalidatePath(buildClubSectionPath(clubId, sectionId));
    return { success: "Rol actualizado correctamente" };
  }
  ```

- [ ] **14.11** Refactor `removeClubInstanceMemberAction` to `removeClubSectionMemberAction`:
  ```typescript
  export async function removeClubSectionMemberAction(
    clubId: number,
    sectionId: number,
    _: ClubActionState,
    formData: FormData,
  ): Promise<ClubActionState> {
    const assignmentId = readString(formData, "assignment_id");
    if (!assignmentId) {
      return { error: "No se pudo identificar la asignación a remover" };
    }

    try {
      await revokeClubRoleAssignment(assignmentId);
    } catch (error) {
      return {
        error: getActionErrorMessage(error, "No se pudo remover la asignación", {
          endpointLabel: `/club-roles/${assignmentId}`,
        }),
      };
    }

    revalidatePath(`/dashboard/clubs/${clubId}`);
    revalidatePath(buildClubSectionPath(clubId, sectionId));
    return { success: "Asignación removida correctamente" };
  }
  ```

- [ ] **14.12** Verify no old references remain:
  ```bash
  cd sacdia-admin && grep -rn 'Instance\|instance_type\|MANAGED_INSTANCE' src/lib/clubs/actions.ts | grep -v 'ecclesiastical'
  ```
  Expected: zero matches

### Task 15: Update notification server actions (`src/lib/notifications/actions.ts`)

> Remove `ClubInstanceType` import and simplify `clubNotificationAction` to use `sectionId`.

**File:** `sacdia-admin/src/lib/notifications/actions.ts`

- [ ] **15.1** Replace the import:
  ```typescript
  // BEFORE:
  import {
    sendNotification,
    broadcastNotification,
    sendClubNotification,
    type ClubInstanceType,
  } from "@/lib/api/notifications";

  // AFTER:
  import {
    sendNotification,
    broadcastNotification,
    sendClubNotification,
  } from "@/lib/api/notifications";
  ```

- [ ] **15.2** Refactor `clubNotificationAction` to use `section_id` instead of `instance_type + instance_id`:
  ```typescript
  export async function clubNotificationAction(
    _: NotificationActionState,
    formData: FormData,
  ): Promise<NotificationActionState> {
    const sectionIdRaw = readString(formData, "section_id");
    const title = readString(formData, "title");
    const body = readString(formData, "body");

    if (!sectionIdRaw) return { error: "El ID de sección es obligatorio" };
    if (!title) return { error: "El título es obligatorio" };
    if (!body) return { error: "El mensaje es obligatorio" };

    const sectionId = Number(sectionIdRaw);
    if (!Number.isFinite(sectionId) || sectionId <= 0) {
      return { error: "El ID de sección no es válido" };
    }

    try {
      await sendClubNotification(sectionId, { title, body });
    } catch (error) {
      return {
        error: getActionErrorMessage(error, "No se pudo enviar la notificación al club", {
          endpointLabel: `/notifications/section/${sectionId}`,
        }),
      };
    }

    return { success: "Notificación de sección enviada correctamente" };
  }
  ```

### Task 16: Update permission constants (`src/lib/auth/permissions.ts`)

> Rename `CLUB_INSTANCES_*` and `CLUBS_INSTANCES_*` constants to `CLUB_SECTIONS_*` and `CLUBS_SECTIONS_*`. Update PERMISSION_GROUPS labels.

**File:** `sacdia-admin/src/lib/auth/permissions.ts`

- [ ] **16.1** Replace the club instances constants block (lines 46-58):
  ```typescript
  // BEFORE:
  // Canonical naming for club instances (new RBAC plan)
  export const CLUBS_INSTANCES_READ = "clubs_instances:read";
  export const CLUBS_INSTANCES_CREATE = "clubs_instances:create";
  export const CLUBS_INSTANCES_UPDATE = "clubs_instances:update";
  export const CLUBS_INSTANCES_DELETE = "clubs_instances:delete";
  // Legacy aliases kept for backward compatibility during migration.
  export const CLUB_INSTANCES_READ = "club_instances:read";
  export const CLUB_INSTANCES_CREATE = "club_instances:create";
  export const CLUB_INSTANCES_UPDATE = "club_instances:update";
  export const CLUB_INSTANCES_DELETE = "club_instances:delete";

  // AFTER:
  // Club sections (consolidated from club_instances)
  export const CLUB_SECTIONS_READ = "club_sections:read";
  export const CLUB_SECTIONS_CREATE = "club_sections:create";
  export const CLUB_SECTIONS_UPDATE = "club_sections:update";
  export const CLUB_SECTIONS_DELETE = "club_sections:delete";
  ```

- [ ] **16.2** Update PERMISSION_GROUPS clubs section (lines 170-177):
  ```typescript
  // BEFORE:
  { key: CLUBS_INSTANCES_READ, label: "Ver instancias" },
  { key: CLUBS_INSTANCES_CREATE, label: "Crear instancia" },
  { key: CLUBS_INSTANCES_UPDATE, label: "Editar instancia" },
  { key: CLUBS_INSTANCES_DELETE, label: "Eliminar instancia" },

  // AFTER:
  { key: CLUB_SECTIONS_READ, label: "Ver secciones" },
  { key: CLUB_SECTIONS_CREATE, label: "Crear sección" },
  { key: CLUB_SECTIONS_UPDATE, label: "Editar sección" },
  { key: CLUB_SECTIONS_DELETE, label: "Eliminar sección" },
  ```

### Task 17: Update permission utils (`src/lib/auth/permission-utils.ts`)

> Rename permission key arrays and helper functions from `Instance` to `Section`.

**File:** `sacdia-admin/src/lib/auth/permission-utils.ts`

- [ ] **17.1** Update imports:
  ```typescript
  // BEFORE:
  import {
    CLUBS_CREATE,
    CLUBS_INSTANCES_CREATE,
    CLUBS_INSTANCES_READ,
    CLUBS_INSTANCES_UPDATE,
    CLUBS_READ,
    CLUBS_UPDATE,
    CLUB_INSTANCES_CREATE,
    CLUB_INSTANCES_READ,
    CLUB_INSTANCES_UPDATE,
    ...
  } from "@/lib/auth/permissions";

  // AFTER:
  import {
    CLUBS_CREATE,
    CLUB_SECTIONS_CREATE,
    CLUB_SECTIONS_READ,
    CLUB_SECTIONS_UPDATE,
    CLUBS_READ,
    CLUBS_UPDATE,
    ...
  } from "@/lib/auth/permissions";
  ```

- [ ] **17.2** Replace permission key arrays (lines 37-48):
  ```typescript
  // BEFORE:
  export const CLUBS_INSTANCES_READ_KEYS = [
    CLUBS_INSTANCES_READ,
    CLUB_INSTANCES_READ,
  ];
  export const CLUBS_INSTANCES_CREATE_KEYS = [
    CLUBS_INSTANCES_CREATE,
    CLUB_INSTANCES_CREATE,
  ];
  export const CLUBS_INSTANCES_UPDATE_KEYS = [
    CLUBS_INSTANCES_UPDATE,
    CLUB_INSTANCES_UPDATE,
  ];

  // AFTER:
  export const CLUB_SECTIONS_READ_KEYS = [CLUB_SECTIONS_READ];
  export const CLUB_SECTIONS_CREATE_KEYS = [CLUB_SECTIONS_CREATE];
  export const CLUB_SECTIONS_UPDATE_KEYS = [CLUB_SECTIONS_UPDATE];
  ```

- [ ] **17.3** Rename helper functions (lines 369-388):
  ```typescript
  // BEFORE:
  export function canReadClubInstances(user: AuthUser | null | undefined) {
    return canByPermissionOrRole(user, CLUBS_INSTANCES_READ_KEYS, { ... });
  }
  export function canCreateClubInstances(user: AuthUser | null | undefined) { ... }
  export function canUpdateClubInstances(user: AuthUser | null | undefined) { ... }

  // AFTER:
  export function canReadClubSections(user: AuthUser | null | undefined) {
    return canByPermissionOrRole(user, CLUB_SECTIONS_READ_KEYS, {
      allowAdminFallback: true,
      allowClubRoleFallback: true,
    });
  }

  export function canCreateClubSections(user: AuthUser | null | undefined) {
    return canByPermissionOrRole(user, CLUB_SECTIONS_CREATE_KEYS, {
      allowAdminFallback: true,
      allowClubRoleFallback: true,
    });
  }

  export function canUpdateClubSections(user: AuthUser | null | undefined) {
    return canByPermissionOrRole(user, CLUB_SECTIONS_UPDATE_KEYS, {
      allowAdminFallback: true,
      allowClubRoleFallback: true,
    });
  }
  ```

- [ ] **17.4** Search the entire admin codebase for callers of the old functions and update:
  ```bash
  cd sacdia-admin && grep -rn 'canReadClubInstances\|canCreateClubInstances\|canUpdateClubInstances\|CLUBS_INSTANCES_READ_KEYS\|CLUBS_INSTANCES_CREATE_KEYS\|CLUBS_INSTANCES_UPDATE_KEYS' src/
  ```
  Update all call sites to use the new names.

### Task 18: Rename and refactor component (`club-instances-panel.tsx` → `club-sections-panel.tsx`)

> Rename the component file and update all internal references from `Instance` to `Section`.

**Files:**
- Delete: `sacdia-admin/src/components/clubs/club-instances-panel.tsx`
- Create: `sacdia-admin/src/components/clubs/club-sections-panel.tsx`

- [ ] **18.1** Create `club-sections-panel.tsx` with the renamed component:
  ```typescript
  "use client";

  import { useState, useActionState, useEffect } from "react";
  import { useRouter } from "next/navigation";
  import { useFormStatus } from "react-dom";
  import { Plus, Users, CheckCircle, XCircle, Loader2, ChevronDown, ChevronUp } from "lucide-react";
  import { Button } from "@/components/ui/button";
  import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
  import { Badge } from "@/components/ui/badge";
  import { Input } from "@/components/ui/input";
  import { Label } from "@/components/ui/label";
  import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
  } from "@/components/ui/select";
  import { createClubSectionAction, type ClubActionState } from "@/lib/clubs/actions";

  type Section = {
    club_section_id?: number;
    club_type_id?: number;
    club_type?: { name?: string; slug?: string } | null;
    name?: string;
    active?: boolean;
    souls_target?: number | null;
    fee?: number | null;
    members_count?: number;
  };

  const DAYS_OF_WEEK = [
    { value: "Monday", label: "Lunes" },
    { value: "Tuesday", label: "Martes" },
    { value: "Wednesday", label: "Miércoles" },
    { value: "Thursday", label: "Jueves" },
    { value: "Friday", label: "Viernes" },
    { value: "Saturday", label: "Sábado" },
    { value: "Sunday", label: "Domingo" },
  ];

  function InfoRow({ label, value }: { label: string; value: React.ReactNode }) {
    return (
      <div className="flex flex-col gap-1 sm:flex-row sm:items-center sm:gap-4">
        <span className="min-w-[140px] text-sm font-medium text-muted-foreground">{label}</span>
        <span className="text-sm">{value ?? "—"}</span>
      </div>
    );
  }

  function SubmitButton({ label }: { label: string }) {
    const { pending } = useFormStatus();
    return (
      <Button type="submit" size="sm" disabled={pending}>
        {pending ? <Loader2 className="mr-2 size-4 animate-spin" /> : <Plus className="mr-2 size-4" />}
        {label}
      </Button>
    );
  }

  function CreateSectionForm({
    clubId,
    onSuccess,
  }: {
    clubId: number;
    onSuccess: () => void;
  }) {
    const router = useRouter();
    const boundAction = createClubSectionAction.bind(null, clubId);
    const [state, action] = useActionState(boundAction, {} as ClubActionState);

    useEffect(() => {
      if (state.success) {
        router.refresh();
        onSuccess();
      }
    }, [state.success]);

    return (
      <form action={action} className="mt-4 space-y-4 border-t pt-4">
        {state.error && (
          <p className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">{state.error}</p>
        )}

        <div className="grid gap-3 sm:grid-cols-2">
          <div className="space-y-1">
            <Label htmlFor="section_club_type_id">Tipo de club</Label>
            <Input id="section_club_type_id" name="club_type_id" type="number" min="1" required />
          </div>

          <div className="space-y-1">
            <Label htmlFor="section_name">Nombre</Label>
            <Input id="section_name" name="name" placeholder="Nombre de la sección" />
          </div>

          <div className="space-y-1">
            <Label htmlFor="section_souls">Meta de almas</Label>
            <Input id="section_souls" name="souls_target" type="number" min="0" defaultValue="0" />
          </div>

          <div className="space-y-1">
            <Label htmlFor="section_fee">Cuota de membresía</Label>
            <Input id="section_fee" name="fee" type="number" min="0" step="0.01" defaultValue="0" />
          </div>

          <div className="space-y-1">
            <Label htmlFor="section_day">Día de reunión</Label>
            <Select name="meeting_day">
              <SelectTrigger id="section_day">
                <SelectValue placeholder="Seleccionar día" />
              </SelectTrigger>
              <SelectContent>
                {DAYS_OF_WEEK.map((d) => (
                  <SelectItem key={d.value} value={d.value}>{d.label}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-1">
            <Label htmlFor="section_time">Hora de reunión</Label>
            <Input
              id="section_time"
              name="meeting_time"
              type="time"
              defaultValue="09:00"
              step="60"
            />
          </div>
        </div>

        <div className="flex justify-end">
          <SubmitButton label="Crear sección" />
        </div>
      </form>
    );
  }

  interface ClubSectionsPanelProps {
    clubId: number;
    sections: Section[];
  }

  export function ClubSectionsPanel({ clubId, sections }: ClubSectionsPanelProps) {
    const [showForm, setShowForm] = useState(false);
    const [refreshKey, setRefreshKey] = useState(0);

    return (
      <div className="space-y-4" key={refreshKey}>
        <div className="flex items-center justify-between">
          <p className="text-sm text-muted-foreground">
            Secciones del club (Aventureros, Conquistadores, Guías Mayores, etc.)
          </p>
          {!showForm && (
            <Button variant="outline" size="sm" onClick={() => setShowForm(true)} type="button">
              <Plus className="mr-2 size-4" />
              Agregar sección
            </Button>
          )}
        </div>

        {showForm && (
          <Card className="border-dashed">
            <CardContent className="py-4">
              <div className="flex items-center justify-between mb-2">
                <p className="text-sm font-medium">Nueva sección</p>
                <Button variant="ghost" size="sm" onClick={() => setShowForm(false)} type="button">
                  <ChevronUp className="mr-2 size-4" />Cancelar
                </Button>
              </div>
              <CreateSectionForm
                clubId={clubId}
                onSuccess={() => {
                  setShowForm(false);
                  setRefreshKey((k) => k + 1);
                }}
              />
            </CardContent>
          </Card>
        )}

        {sections.length === 0 && !showForm && (
          <Card className="border-dashed">
            <CardContent className="py-6 text-center">
              <XCircle className="mx-auto size-8 text-muted-foreground" />
              <p className="mt-2 text-sm text-muted-foreground">No hay secciones creadas</p>
            </CardContent>
          </Card>
        )}

        {sections.map((section) => {
          const sectionId = section.club_section_id;
          const label = section.club_type?.name ?? section.name ?? `Sección #${sectionId}`;

          return (
            <Card key={sectionId}>
              <CardHeader className="flex flex-row items-center justify-between pb-3">
                <div className="flex items-center gap-3">
                  {section.active !== false ? (
                    <CheckCircle className="size-5 text-green-600" />
                  ) : (
                    <XCircle className="size-5 text-muted-foreground" />
                  )}
                  <CardTitle className="text-base">{label}</CardTitle>
                </div>
                <Badge variant={section.active !== false ? "default" : "outline"}>
                  {section.active !== false ? "Activa" : "Inactiva"}
                </Badge>
              </CardHeader>
              <CardContent className="space-y-2">
                <InfoRow label="ID sección" value={sectionId} />
                {section.souls_target != null && (
                  <InfoRow label="Meta de almas" value={section.souls_target} />
                )}
                {section.fee != null && (
                  <InfoRow label="Cuota de membresía" value={`$${section.fee}`} />
                )}
                {section.members_count != null && (
                  <InfoRow
                    label="Miembros"
                    value={
                      <span className="flex items-center gap-1">
                        <Users className="size-3.5" />
                        {section.members_count}
                      </span>
                    }
                  />
                )}
              </CardContent>
            </Card>
          );
        })}
      </div>
    );
  }
  ```

- [ ] **18.2** Delete the old file:
  ```bash
  rm sacdia-admin/src/components/clubs/club-instances-panel.tsx
  ```

### Task 19: Update notification form component

> Simplify `ClubNotificationForm` to use single `section_id` field instead of `instance_type` + `instance_id`.

**File:** `sacdia-admin/src/components/notifications/notification-forms.tsx`

- [ ] **19.1** Replace `ClubNotificationForm` — change header text, remove type selector, replace instance_id with section_id:
  ```typescript
  export function ClubNotificationForm() {
    const [state, action] = useActionState(clubNotificationAction, initial);

    return (
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Users className="size-5 text-primary" />
            <CardTitle className="text-base">Por sección de club</CardTitle>
          </div>
          <CardDescription>Enviar notificación a todos los miembros de una sección de club.</CardDescription>
        </CardHeader>
        <CardContent>
          <form action={action} className="space-y-4">
            <StatusBanner state={state} />
            <div className="space-y-2">
              <Label htmlFor="club_section_id">
                ID de sección <span className="text-destructive">*</span>
              </Label>
              <Input id="club_section_id" name="section_id" type="number" placeholder="ID numérico de la sección" required />
            </div>
            <div className="space-y-2">
              <Label htmlFor="club_title">
                Título <span className="text-destructive">*</span>
              </Label>
              <Input id="club_title" name="title" placeholder="Título de la notificación" required />
            </div>
            <div className="space-y-2">
              <Label htmlFor="club_body">
                Mensaje <span className="text-destructive">*</span>
              </Label>
              <Textarea id="club_body" name="body" placeholder="Contenido del mensaje" rows={3} required />
            </div>
            <SubmitButton label="Enviar a sección" />
          </form>
        </CardContent>
      </Card>
    );
  }
  ```

### Task 20: Update club detail page

> Update imports and props from `ClubInstancesPanel` to `ClubSectionsPanel`, rename `instances` to `sections` in the page type and JSX.

**File:** `sacdia-admin/src/app/(dashboard)/dashboard/clubs/[id]/page.tsx`

- [ ] **20.1** Update import:
  ```typescript
  // BEFORE:
  import { ClubInstancesPanel } from "@/components/clubs/club-instances-panel";

  // AFTER:
  import { ClubSectionsPanel } from "@/components/clubs/club-sections-panel";
  ```

- [ ] **20.2** Update the `Club` type — rename `instances` to `sections`:
  ```typescript
  // BEFORE (lines 35-46):
  instances?: Array<{
    instance_id?: number;
    instance_type?: string;
    club_type_id?: number;
    club_type?: { name?: string } | null;
    type?: string;
    name?: string;
    active?: boolean;
    soul_goal?: number | null;
    membership_fee?: number | null;
    members_count?: number;
  }>;

  // AFTER:
  sections?: Array<{
    club_section_id?: number;
    club_type_id?: number;
    club_type?: { name?: string; slug?: string } | null;
    name?: string;
    active?: boolean;
    souls_target?: number | null;
    fee?: number | null;
    members_count?: number;
  }>;
  ```

- [ ] **20.3** Update the sections variable assignment:
  ```typescript
  // BEFORE:
  const instances = club.instances ?? [];

  // AFTER:
  const sections = club.sections ?? [];
  ```

- [ ] **20.4** Update the Tabs content:
  ```typescript
  // BEFORE:
  <TabsTrigger value="instances">Instancias ({instances.length})</TabsTrigger>
  ...
  <TabsContent value="instances" className="mt-4 space-y-4">
    <ClubInstancesPanel clubId={clubId} instances={instances} />
  </TabsContent>

  // AFTER:
  <TabsTrigger value="sections">Secciones ({sections.length})</TabsTrigger>
  ...
  <TabsContent value="sections" className="mt-4 space-y-4">
    <ClubSectionsPanel clubId={clubId} sections={sections} />
  </TabsContent>
  ```

- [ ] **20.5** Commit:
  ```bash
  cd sacdia-admin
  git add -A
  git commit -m "refactor: rename club-instances to club-sections across admin

  - API types: ClubInstance → ClubSection, endpoints use /sections/:sectionId
  - Server actions: remove 3-type sync pattern, simplify to section-based ops
  - Permissions: club_instances:* → club_sections:*
  - Components: club-instances-panel → club-sections-panel
  - Notifications: remove instance_type selector, use section_id
  - Club detail page: instances tab → sections tab"
  ```

- [ ] **20.6** Build check:
  ```bash
  cd sacdia-admin && pnpm build
  ```
  Expected: SUCCESS

- [ ] **20.7** Lint check:
  ```bash
  cd sacdia-admin && pnpm lint
  ```
  Expected: PASS

- [ ] **20.8** Final grep verification:
  ```bash
  cd sacdia-admin && grep -rn 'ClubInstance\|club_instance\|club-instance\|CLUB_INSTANCES\|CLUBS_INSTANCES\|club_adv_id\|club_pathf_id\|club_mg_id\|instance_type.*adventurers\|instance_type.*pathfinders\|instance_type.*master_guilds' src/ --include='*.ts' --include='*.tsx'
  ```
  Expected: zero matches

---

### Chunk 3 Completion Criteria

1. Zero references to `ClubInstance`, `ClubInstanceType`, `club_instances`, `CLUBS_INSTANCES_*`, `CLUB_INSTANCES_*` in `sacdia-admin/src/`
2. All API functions use `/sections/:sectionId` URLs (no `:type` param)
3. Permission constants use `club_sections:*`
4. `club-instances-panel.tsx` deleted, `club-sections-panel.tsx` created
5. Notification form uses single `section_id` field
6. `pnpm build` passes
7. `pnpm lint` passes

---

## Chunk 4: App (Flutter / sacdia-app)

> Actualizar modelos, datasources, domain layer, providers, views y widgets que referencian el patron `club_instances` / 3 tablas para usar `club_sections`. Tambien impacta el modulo `members` y `evidence_folder` que consumen el contexto de instancia.

**Files affected (28):**

**club feature (12 files):**
- `sacdia-app/lib/features/club/data/models/club_info_model.dart` — `ClubInstanceModel` → `ClubSectionModel`
- `sacdia-app/lib/features/club/data/datasources/club_remote_data_source.dart` — API URLs
- `sacdia-app/lib/features/club/data/repositories/club_repository_impl.dart` — method signatures
- `sacdia-app/lib/features/club/domain/entities/club_info.dart` — `ClubInstance` entity → `ClubSection`
- `sacdia-app/lib/features/club/domain/repositories/club_repository.dart` — interface
- `sacdia-app/lib/features/club/domain/usecases/get_club_instance.dart` — rename to `get_club_section.dart`
- `sacdia-app/lib/features/club/domain/usecases/update_club_instance.dart` — rename to `update_club_section.dart`
- `sacdia-app/lib/features/club/presentation/providers/club_providers.dart` — provider names
- `sacdia-app/lib/features/club/presentation/views/club_view.dart` — entity refs

**post_registration feature (5 files):**
- `sacdia-app/lib/features/post_registration/data/models/club_instance_model.dart` — rename to `club_section_model.dart`
- `sacdia-app/lib/features/post_registration/data/datasources/club_selection_remote_data_source.dart` — API URL + bucket parsing
- `sacdia-app/lib/features/post_registration/presentation/providers/club_selection_providers.dart` — provider names
- `sacdia-app/lib/features/post_registration/presentation/widgets/club_type_selector.dart` — refs
- `sacdia-app/lib/features/post_registration/presentation/views/club_selection_step_view.dart` — refs
- `sacdia-app/lib/features/post_registration/presentation/views/post_registration_shell.dart` — payload key

**evidence_folder feature (8 files):**
- `sacdia-app/lib/features/evidence_folder/data/datasources/evidence_folder_remote_data_source.dart` — param + URL rename
- `sacdia-app/lib/features/evidence_folder/data/repositories/evidence_folder_repository_impl.dart` — param rename
- `sacdia-app/lib/features/evidence_folder/domain/repositories/evidence_folder_repository.dart` — param rename
- `sacdia-app/lib/features/evidence_folder/domain/usecases/get_evidence_folder.dart` — param rename
- `sacdia-app/lib/features/evidence_folder/domain/usecases/upload_evidence_file.dart` — param rename
- `sacdia-app/lib/features/evidence_folder/domain/usecases/delete_evidence_file.dart` — param rename
- `sacdia-app/lib/features/evidence_folder/domain/usecases/submit_section.dart` — param rename
- `sacdia-app/lib/features/evidence_folder/presentation/providers/evidence_folder_providers.dart` — param rename
- `sacdia-app/lib/features/evidence_folder/presentation/views/evidence_folder_view.dart` — prop rename
- `sacdia-app/lib/features/evidence_folder/presentation/views/evidence_section_detail_view.dart` — prop rename

**activities feature (2 files):**
- `sacdia-app/lib/features/activities/data/models/activity_model.dart` — `clubAdvId`/`clubPathfId`/`clubMgId` → `clubSectionId`
- `sacdia-app/lib/features/activities/data/models/create_activity_request.dart` — same

**members feature (9 files):**
- `sacdia-app/lib/features/members/presentation/providers/members_providers.dart` — `ClubContext.instanceType`/`instanceId` → `sectionId`
- `sacdia-app/lib/features/members/data/datasources/members_remote_data_source.dart` — URLs
- `sacdia-app/lib/features/members/data/repositories/members_repository_impl.dart` — params
- `sacdia-app/lib/features/members/data/models/club_member_model.dart` — field refs
- `sacdia-app/lib/features/members/domain/usecases/get_club_members.dart` — params
- `sacdia-app/lib/features/members/domain/usecases/get_join_requests.dart` — params
- `sacdia-app/lib/features/members/domain/usecases/assign_club_role.dart` — params
- `sacdia-app/lib/features/members/domain/repositories/members_repository.dart` — interface
- `sacdia-app/lib/features/members/domain/entities/club_member.dart` — field refs

**router (1 file):**
- `sacdia-app/lib/core/config/router.dart` — provider refs

### Task 21: Rename domain entity `ClubInstance` → `ClubSection`

> Update the core entity that everything else depends on.

**File:** `sacdia-app/lib/features/club/domain/entities/club_info.dart`

- [ ] **21.1** Rename `ClubInstance` class to `ClubSection`, update field names:
  ```dart
  // BEFORE:
  /// Entidad de dominio para una instancia de club
  /// (Aventureros, Conquistadores o Guías Mayores).
  class ClubInstance extends Equatable {
    final int id;
    final String mainClubId;
    final String instanceType;
    final String instanceTypeName;
    ...
  }

  // AFTER:
  /// Entidad de dominio para una sección de club
  /// (Aventureros, Conquistadores o Guías Mayores).
  class ClubSection extends Equatable {
    /// ID numérico de la sección (club_section_id).
    final int id;

    /// ID del club contenedor (UUID).
    final String mainClubId;

    /// club_type_id del tipo de sección.
    final int clubTypeId;

    /// Nombre legible del tipo (ej: 'Conquistadores').
    final String clubTypeName;

    /// Nombre propio de la sección.
    final String? name;

    /// Teléfono de contacto.
    final String? phone;

    /// Email de contacto.
    final String? email;

    /// Sitio web.
    final String? website;

    /// URL del logo/imagen.
    final String? logoUrl;

    /// Dirección física.
    final String? address;

    /// Latitud de la ubicación.
    final double? lat;

    /// Longitud de la ubicación.
    final double? long;

    /// ¿Sección activa?
    final bool active;

    const ClubSection({
      required this.id,
      required this.mainClubId,
      required this.clubTypeId,
      required this.clubTypeName,
      this.name,
      this.phone,
      this.email,
      this.website,
      this.logoUrl,
      this.address,
      this.lat,
      this.long,
      required this.active,
    });

    @override
    List<Object?> get props => [
          id, mainClubId, clubTypeId, clubTypeName,
          name, phone, email, website, logoUrl, address, lat, long, active,
        ];
  }
  ```

### Task 22: Update data model `ClubInstanceModel` → `ClubSectionModel`

> Update the data model in `club_info_model.dart` to extend `ClubSection` instead of `ClubInstance`. Simplify type detection — no more `instanceType` slug, use `clubTypeId` int.

**File:** `sacdia-app/lib/features/club/data/models/club_info_model.dart`

- [ ] **22.1** Remove the `_instanceTypeSlugs` and `normalizeInstanceType` helper (no longer needed — type is determined by `club_type_id`). Keep `_instanceTypeNames` for display:
  ```dart
  // DELETE:
  const _instanceTypeSlugs = { ... };
  String normalizeInstanceType(String raw) { ... }

  // KEEP (but rename):
  /// Mapa de club_type slugs a nombres legibles en español.
  /// Fallback para cuando club_type.name no viene del API.
  const _clubTypeDisplayNames = {
    'adventurers': 'Aventureros',
    'pathfinders': 'Conquistadores',
    'master_guild': 'Guías Mayores',
  };
  ```

- [ ] **22.2** Rename `ClubInstanceModel` to `ClubSectionModel`:
  ```dart
  /// Modelo de datos para una sección de club.
  ///
  /// Mapea la respuesta de:
  ///   GET /api/v1/clubs/:clubId/sections/:sectionId
  class ClubSectionModel extends ClubSection {
    const ClubSectionModel({
      required super.id,
      required super.mainClubId,
      required super.clubTypeId,
      required super.clubTypeName,
      super.name,
      super.phone,
      super.email,
      super.website,
      super.logoUrl,
      super.address,
      super.lat,
      super.long,
      required super.active,
    });

    factory ClubSectionModel.fromJson(Map<String, dynamic> json) {
      final rawId = json['club_section_id'] ?? json['id'];
      final id = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;

      final mainClubId =
          (json['main_club_id'] ?? json['club_id'] ?? '').toString();

      // club_type_id is the discriminator
      final rawClubTypeId = json['club_type_id'];
      final clubTypeId = rawClubTypeId is int
          ? rawClubTypeId
          : (int.tryParse(rawClubTypeId?.toString() ?? '') ?? 0);

      // Determine display name from nested club_type or slug fallback
      final clubTypeNested = json['club_type'] as Map<String, dynamic>?;
      final clubTypeName = clubTypeNested?['name'] as String? ??
          _clubTypeDisplayNames[clubTypeNested?['slug']] ??
          '';

      final lat = _parseDouble(json['lat'] ?? json['latitude']);
      final long = _parseDouble(json['long'] ?? json['longitude'] ?? json['lng']);

      return ClubSectionModel(
        id: id,
        mainClubId: mainClubId,
        clubTypeId: clubTypeId,
        clubTypeName: clubTypeName,
        name: json['name'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        website: json['website'] as String?,
        logoUrl: json['logo_url'] ?? json['image'] as String?,
        address: json['address'] as String?,
        lat: lat,
        long: long,
        active: json['active'] as bool? ?? true,
      );
    }

    Map<String, dynamic> toJson() {
      final map = <String, dynamic>{
        'club_section_id': id,
        'main_club_id': mainClubId,
        'club_type_id': clubTypeId,
        'active': active,
      };
      if (name != null) map['name'] = name;
      if (phone != null) map['phone'] = phone;
      if (email != null) map['email'] = email;
      if (website != null) map['website'] = website;
      if (logoUrl != null) map['logo_url'] = logoUrl;
      if (address != null) map['address'] = address;
      if (lat != null) map['lat'] = lat;
      if (long != null) map['long'] = long;
      return map;
    }
  }
  ```

### Task 23: Update data source, repository, and use cases

> Update API URLs from `/instances/:type/:instanceId` to `/sections/:sectionId`. Remove `instanceType` parameter from all signatures.

**File:** `sacdia-app/lib/features/club/data/datasources/club_remote_data_source.dart`

- [ ] **23.1** Update interface — rename methods and remove `instanceType` param:
  ```dart
  // BEFORE:
  abstract class ClubRemoteDataSource {
    Future<ClubInfoModel> getClub(String clubId);
    Future<ClubInstanceModel> getClubInstance({
      required String clubId,
      required String instanceType,
      required int instanceId,
    });
    Future<ClubInstanceModel> updateClubInstance({
      required String clubId,
      required String instanceType,
      required int instanceId,
      Map<String, dynamic>? data,
    });
  }

  // AFTER:
  abstract class ClubRemoteDataSource {
    Future<ClubInfoModel> getClub(String clubId);
    Future<ClubSectionModel> getClubSection({
      required String clubId,
      required int sectionId,
    });
    Future<ClubSectionModel> updateClubSection({
      required String clubId,
      required int sectionId,
      Map<String, dynamic>? data,
    });
  }
  ```

- [ ] **23.2** Update implementation — change URLs and model references:
  ```dart
  // getClubInstance → getClubSection
  @override
  Future<ClubSectionModel> getClubSection({
    required String clubId,
    required int sectionId,
  }) async {
    try {
      AppLogger.i('Obteniendo sección: $sectionId del club $clubId', tag: _tag);
      final token = await _getAuthToken();
      final response = await _dio.get(
        '$_baseUrl/clubs/$clubId/sections/$sectionId',
        options: Options(headers: _authHeaders(token)),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = _unwrapMap(response.data);
        return ClubSectionModel.fromJson(json);
      }
      throw ServerException(
        message: 'Error al obtener sección del club',
        code: response.statusCode,
      );
    } on DioException catch (e) {
      AppLogger.e('DioException en getClubSection', tag: _tag, error: e);
      throw ServerException(
        message: e.response?.data?['message'] ?? e.message ?? 'Error de red',
        code: e.response?.statusCode,
      );
    } catch (e) {
      if (e is AuthException || e is ServerException) rethrow;
      AppLogger.e('Error inesperado en getClubSection', tag: _tag, error: e);
      throw ServerException(message: e.toString());
    }
  }

  // updateClubInstance → updateClubSection (same pattern, URL changes)
  @override
  Future<ClubSectionModel> updateClubSection({
    required String clubId,
    required int sectionId,
    Map<String, dynamic>? data,
  }) async {
    // ... same pattern, URL: '$_baseUrl/clubs/$clubId/sections/$sectionId'
  }
  ```

**File:** `sacdia-app/lib/features/club/domain/repositories/club_repository.dart`

- [ ] **23.3** Update repository interface:
  ```dart
  abstract class ClubRepository {
    Future<Either<Failure, ClubInfo>> getClub(String clubId);

    /// Obtiene la sección de club por ID.
    Future<Either<Failure, ClubSection>> getClubSection({
      required String clubId,
      required int sectionId,
    });

    /// Actualiza la sección de club.
    Future<Either<Failure, ClubSection>> updateClubSection({
      required String clubId,
      required int sectionId,
      String? name,
      String? phone,
      String? email,
      String? website,
      String? logoUrl,
      String? address,
      double? lat,
      double? long,
    });
  }
  ```

**File:** `sacdia-app/lib/features/club/data/repositories/club_repository_impl.dart`

- [ ] **23.4** Update implementation — replace `getClubInstance`/`updateClubInstance` with `getClubSection`/`updateClubSection`, remove `instanceType` from method calls.

**File:** `sacdia-app/lib/features/club/domain/usecases/get_club_instance.dart` → rename to `get_club_section.dart`

- [ ] **23.5** Create `get_club_section.dart`:
  ```dart
  import 'package:dartz/dartz.dart';
  import '../../../../core/errors/failures.dart';
  import '../../../../core/usecases/usecase.dart';
  import '../entities/club_info.dart';
  import '../repositories/club_repository.dart';

  class GetClubSectionParams {
    final String clubId;
    final int sectionId;

    const GetClubSectionParams({
      required this.clubId,
      required this.sectionId,
    });
  }

  class GetClubSection implements UseCase<ClubSection, GetClubSectionParams> {
    final ClubRepository _repository;
    const GetClubSection(this._repository);

    @override
    Future<Either<Failure, ClubSection>> call(GetClubSectionParams params) {
      return _repository.getClubSection(
        clubId: params.clubId,
        sectionId: params.sectionId,
      );
    }
  }
  ```

- [ ] **23.6** Delete old file:
  ```bash
  rm sacdia-app/lib/features/club/domain/usecases/get_club_instance.dart
  ```

**File:** `sacdia-app/lib/features/club/domain/usecases/update_club_instance.dart` → rename to `update_club_section.dart`

- [ ] **23.7** Create `update_club_section.dart`:
  ```dart
  import 'package:dartz/dartz.dart';
  import '../../../../core/errors/failures.dart';
  import '../../../../core/usecases/usecase.dart';
  import '../entities/club_info.dart';
  import '../repositories/club_repository.dart';

  class UpdateClubSectionParams {
    final String clubId;
    final int sectionId;
    final String? name;
    final String? phone;
    final String? email;
    final String? website;
    final String? logoUrl;
    final String? address;
    final double? lat;
    final double? long;

    const UpdateClubSectionParams({
      required this.clubId,
      required this.sectionId,
      this.name,
      this.phone,
      this.email,
      this.website,
      this.logoUrl,
      this.address,
      this.lat,
      this.long,
    });
  }

  class UpdateClubSection
      implements UseCase<ClubSection, UpdateClubSectionParams> {
    final ClubRepository _repository;
    const UpdateClubSection(this._repository);

    @override
    Future<Either<Failure, ClubSection>> call(UpdateClubSectionParams params) {
      return _repository.updateClubSection(
        clubId: params.clubId,
        sectionId: params.sectionId,
        name: params.name,
        phone: params.phone,
        email: params.email,
        website: params.website,
        logoUrl: params.logoUrl,
        address: params.address,
        lat: params.lat,
        long: params.long,
      );
    }
  }
  ```

- [ ] **23.8** Delete old file:
  ```bash
  rm sacdia-app/lib/features/club/domain/usecases/update_club_instance.dart
  ```

### Task 24: Update club providers

> Rename providers, update use case references, simplify `ClubContext` to use `sectionId` instead of `instanceType + instanceId`.

**File:** `sacdia-app/lib/features/club/presentation/providers/club_providers.dart`

- [ ] **24.1** Update imports:
  ```dart
  // BEFORE:
  import '../../domain/usecases/get_club_instance.dart';
  import '../../domain/usecases/update_club_instance.dart';

  // AFTER:
  import '../../domain/usecases/get_club_section.dart';
  import '../../domain/usecases/update_club_section.dart';
  ```

- [ ] **24.2** Rename use case providers:
  ```dart
  // BEFORE:
  final getClubInstanceUseCaseProvider = Provider<GetClubInstance>((ref) { ... });
  final updateClubInstanceUseCaseProvider = Provider<UpdateClubInstance>((ref) { ... });

  // AFTER:
  final getClubSectionUseCaseProvider = Provider<GetClubSection>((ref) {
    return GetClubSection(ref.read(clubRepositoryProvider));
  });
  final updateClubSectionUseCaseProvider = Provider<UpdateClubSection>((ref) {
    return UpdateClubSection(ref.read(clubRepositoryProvider));
  });
  ```

- [ ] **24.3** Update `canEditClubProvider` — change permission strings:
  ```dart
  // BEFORE:
  requiredPermissions: const {
    'clubs:update',
    'club_instances:update',
    'clubs_instances:update',
  },

  // AFTER:
  requiredPermissions: const {
    'clubs:update',
    'club_sections:update',
  },
  ```

- [ ] **24.4** Rename `currentClubInstanceProvider` to `currentClubSectionProvider`:
  ```dart
  final currentClubSectionProvider =
      FutureProvider.autoDispose<ClubSection?>((ref) async {
    final context = await ref.watch(clubContextProvider.future);
    if (context == null) return null;

    final useCase = ref.read(getClubSectionUseCaseProvider);
    final result = await useCase(
      GetClubSectionParams(
        clubId: context.clubId.toString(),
        sectionId: context.sectionId,
      ),
    );

    return result.fold(
      (failure) => throw Exception(failure.message),
      (section) => section,
    );
  });
  ```

- [ ] **24.5** Update `UpdateClubState` and `UpdateClubNotifier` to use `ClubSection`:
  ```dart
  class UpdateClubState {
    final bool isLoading;
    final ClubSection? updatedSection;
    final String? errorMessage;
    // ... same copyWith pattern, rename updatedInstance → updatedSection
  }

  class UpdateClubNotifier extends AutoDisposeNotifier<UpdateClubState> {
    @override
    UpdateClubState build() => const UpdateClubState();

    Future<bool> save({
      required String clubId,
      required int sectionId,
      // ... remove instanceType, keep all other params
    }) async {
      state = state.copyWith(isLoading: true, clearError: true);
      final useCase = ref.read(updateClubSectionUseCaseProvider);
      final result = await useCase(
        UpdateClubSectionParams(
          clubId: clubId,
          sectionId: sectionId,
          name: name,
          phone: phone,
          // ... rest of params
        ),
      );
      return result.fold(
        (failure) {
          state = state.copyWith(isLoading: false, errorMessage: failure.message);
          return false;
        },
        (section) {
          state = state.copyWith(isLoading: false, updatedSection: section);
          return true;
        },
      );
    }
  }
  ```

### Task 25: Update members module — `ClubContext` and datasource URLs

> `ClubContext` changes from `instanceType + instanceId` to just `sectionId`. Members datasource URLs change from `/instances/:type/:instanceId/members` to `/sections/:sectionId/members`.

**File:** `sacdia-app/lib/features/members/presentation/providers/members_providers.dart`

- [ ] **25.1** Update `ClubContext`:
  ```dart
  // BEFORE:
  class ClubContext {
    final int clubId;
    final String instanceType;
    final int instanceId;
    const ClubContext({ required this.clubId, required this.instanceType, required this.instanceId });
  }

  // AFTER:
  class ClubContext {
    final int clubId;
    final int sectionId;
    const ClubContext({ required this.clubId, required this.sectionId });
  }
  ```

- [ ] **25.2** Update `clubContextProvider` — simplify to read `sectionId` instead of `instanceType + instanceId`:
  ```dart
  final clubContextProvider = FutureProvider<ClubContext?>((ref) async {
    final authState = await ref.watch(authNotifierProvider.future);
    if (authState == null) return null;

    final activeGrant = authState.authorization?.activeGrant;
    if (activeGrant != null &&
        activeGrant.clubId != null &&
        activeGrant.sectionId != null) {
      return ClubContext(
        clubId: activeGrant.clubId!,
        sectionId: activeGrant.sectionId!,
      );
    }

    if (!kRbacLegacyContextFallbackEnabled) return null;

    final metadata = authState.metadata;
    if (metadata == null) return null;

    final clubData = metadata['club'] as Map<String, dynamic>?;
    final clubId = clubData?['club_id'];
    final sectionId = clubData?['club_section_id'] ?? clubData?['instance_id'] ?? clubData?['id'];

    if (clubId == null || sectionId == null) return null;

    final parsedClubId = clubId is int ? clubId : int.tryParse(clubId.toString());
    final parsedSectionId = sectionId is int ? sectionId : int.tryParse(sectionId.toString());

    if (parsedClubId == null || parsedClubId <= 0) return null;
    if (parsedSectionId == null || parsedSectionId <= 0) return null;

    return ClubContext(clubId: parsedClubId, sectionId: parsedSectionId);
  });
  ```

- [ ] **25.3** Remove `_normalizeInstanceType()` function (no longer needed).

- [ ] **25.4** Update all member provider usages that pass `instanceType`/`instanceId` to pass `sectionId` instead. Every call like:
  ```dart
  // BEFORE:
  instanceType: ctx.instanceType,
  instanceId: ctx.instanceId,

  // AFTER:
  sectionId: ctx.sectionId,
  ```

**File:** `sacdia-app/lib/features/members/data/datasources/members_remote_data_source.dart`

- [ ] **25.5** Update interface — replace `instanceType + instanceId` params with `sectionId`:
  ```dart
  // BEFORE:
  Future<List<ClubMemberModel>> getClubMembers({
    required int clubId,
    required String instanceType,
    required int instanceId,
  });

  // AFTER:
  Future<List<ClubMemberModel>> getClubMembers({
    required int clubId,
    required int sectionId,
  });
  ```
  Apply the same change to `getJoinRequests` and `assignClubRole`.

- [ ] **25.6** Update implementation URLs:
  ```dart
  // BEFORE:
  '$_baseUrl/clubs/$clubId/instances/$instanceType/$instanceId/members'

  // AFTER:
  '$_baseUrl/clubs/$clubId/sections/$sectionId/members'
  ```
  Apply same to roles URL: `'$_baseUrl/clubs/$clubId/sections/$sectionId/roles'`

**Files:** All other members domain files (`members_repository.dart`, `members_repository_impl.dart`, `get_club_members.dart`, `get_join_requests.dart`, `assign_club_role.dart`, `club_member.dart`, `club_member_model.dart`)

- [ ] **25.7** Replace `instanceType: String` + `instanceId: int` params with `sectionId: int` throughout the members domain layer. This is a mechanical rename across the following files:
  - `sacdia-app/lib/features/members/domain/repositories/members_repository.dart`
  - `sacdia-app/lib/features/members/data/repositories/members_repository_impl.dart`
  - `sacdia-app/lib/features/members/domain/usecases/get_club_members.dart`
  - `sacdia-app/lib/features/members/domain/usecases/get_join_requests.dart`
  - `sacdia-app/lib/features/members/domain/usecases/assign_club_role.dart`

### Task 26: Update post_registration module

> Replace `ClubInstanceModel` with `ClubSectionModel`, update datasource to parse new API response format, update providers.

**File:** `sacdia-app/lib/features/post_registration/data/models/club_instance_model.dart` → rename to `club_section_model.dart`

- [ ] **26.1** Create `club_section_model.dart` — the new unified response from `GET /clubs/:id/sections` returns a flat array instead of 3 buckets:
  ```dart
  import 'package:equatable/equatable.dart';

  /// Modelo de sección de club (tipo específico de club)
  class ClubSectionModel extends Equatable {
    final int id;
    final int clubTypeId;
    final int clubId;

    /// Nombre legible del tipo de club (puede ser null)
    final String? clubTypeName;

    const ClubSectionModel({
      required this.id,
      required this.clubTypeId,
      required this.clubId,
      this.clubTypeName,
    });

    /// Parsea un item desde la respuesta de GET /clubs/:id/sections
    factory ClubSectionModel.fromJson(Map<String, dynamic> json) {
      final rawId = json['club_section_id'] ?? json['id'];
      final rawClubTypeId = json['club_type_id'];
      final rawClubId = json['main_club_id'] ?? json['club_id'];

      // club_type puede venir como objeto nested
      final clubTypeNested = json['club_type'] as Map<String, dynamic>?;
      final clubTypeName = clubTypeNested?['name'] as String? ??
          json['club_type_name'] as String?;

      return ClubSectionModel(
        id: rawId is int ? rawId : (int.tryParse(rawId?.toString() ?? '') ?? 0),
        clubTypeId: rawClubTypeId is int
            ? rawClubTypeId
            : (int.tryParse(rawClubTypeId?.toString() ?? '') ?? 0),
        clubId: rawClubId is int
            ? rawClubId
            : (int.tryParse(rawClubId?.toString() ?? '') ?? 0),
        clubTypeName: clubTypeName,
      );
    }

    Map<String, dynamic> toJson() => {
          'club_section_id': id,
          'club_type_id': clubTypeId,
          'main_club_id': clubId,
          if (clubTypeName != null) 'club_type_name': clubTypeName,
        };

    /// Nombre para mostrar
    String get displayName {
      if (clubTypeName != null && clubTypeName!.isNotEmpty) return clubTypeName!;
      return 'Sección #$id';
    }

    @override
    List<Object?> get props => [id, clubTypeId, clubId];
  }
  ```

- [ ] **26.2** Delete old file:
  ```bash
  rm sacdia-app/lib/features/post_registration/data/models/club_instance_model.dart
  ```

**File:** `sacdia-app/lib/features/post_registration/data/datasources/club_selection_remote_data_source.dart`

- [ ] **26.3** Update import:
  ```dart
  // BEFORE:
  import '../models/club_instance_model.dart';
  // AFTER:
  import '../models/club_section_model.dart';
  ```

- [ ] **26.4** Update interface and implementation — `getClubInstances` → `getClubSections`:
  ```dart
  // Interface:
  Future<List<ClubSectionModel>> getClubSections(int clubId);

  // Implementation — new API returns flat array:
  @override
  Future<List<ClubSectionModel>> getClubSections(int clubId) async {
    try {
      final options = await _authOptions();
      final response = await _dio.get(
        '$_baseUrl/clubs/$clubId/sections',
        options: options,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // New API returns { data: [...] } or [...] directly
        final dynamic body = response.data;
        List<dynamic> items;
        if (body is Map<String, dynamic> && body.containsKey('data')) {
          items = body['data'] as List<dynamic>;
        } else if (body is List<dynamic>) {
          items = body;
        } else {
          items = [];
        }

        return items
            .map((json) => ClubSectionModel.fromJson(json as Map<String, dynamic>))
            .where((section) => section.id > 0)
            .toList();
      }

      throw ServerException(message: 'Error al obtener secciones de club');
    } catch (e) {
      AppLogger.e('Error en getClubSections', tag: _tag, error: e);
      if (e is DioException) {
        throw ServerException(message: e.message ?? 'Error de conexión');
      }
      if (e is AppException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
  ```

- [ ] **26.5** Update `completeStep3` — change payload key from `club_instance_id` to `club_section_id`:
  ```dart
  // BEFORE:
  Future<void> completeStep3({
    ...
    required String clubTypeSlug,
    required int clubInstanceId,
    ...
  });
  // data: { 'club_instance_id': clubInstanceId, 'club_type': clubTypeSlug, ... }

  // AFTER:
  Future<void> completeStep3({
    ...
    required int clubSectionId,
    ...
  });
  // data: { 'club_section_id': clubSectionId, ... }
  // NOTE: 'club_type' field is no longer needed — type comes from the section's club_type_id
  ```

**File:** `sacdia-app/lib/features/post_registration/presentation/providers/club_selection_providers.dart`

- [ ] **26.6** Update import:
  ```dart
  // BEFORE:
  import '../../data/models/club_instance_model.dart';
  // AFTER:
  import '../../data/models/club_section_model.dart';
  ```

- [ ] **26.7** Rename providers:
  ```dart
  // clubInstancesProvider → clubSectionsProvider
  final clubSectionsProvider =
      FutureProvider<List<ClubSectionModel>>((ref) async {
    final clubId = ref.watch(selectedClubProvider);
    if (clubId == null) return [];
    final dataSource = ref.read(clubSelectionDataSourceProvider);
    return dataSource.getClubSections(clubId);
  });

  // selectedClubInstanceProvider → selectedClubSectionProvider
  final selectedClubSectionProvider = StateProvider<int?>((ref) {
    final sections = ref.watch(clubSectionsProvider).valueOrNull;
    if (sections == null || sections.isEmpty) return null;
    if (sections.length == 1) return sections.first.id;
    // Age-based recommendation — use clubTypeId or clubTypeName instead of slug
    final age = ref.watch(userAgeProvider);
    if (age == null) return null;
    // ... same logic but using clubTypeName for matching
    return null;
  });

  // selectedClubTypeSlugProvider → REMOVE (no longer needed — type comes from section)
  // Instead, derive clubTypeId from the selected section:
  final selectedClubTypeIdProvider = Provider<int?>((ref) {
    final selectedId = ref.watch(selectedClubSectionProvider);
    if (selectedId == null) return null;
    final sections = ref.watch(clubSectionsProvider).valueOrNull;
    if (sections == null || sections.isEmpty) return null;
    final section = sections.where((s) => s.id == selectedId).firstOrNull;
    return section?.clubTypeId;
  });

  // classesProvider — update to use selectedClubTypeIdProvider
  final classesProvider = FutureProvider<List<ClassModel>>((ref) async {
    final clubTypeId = ref.watch(selectedClubTypeIdProvider);
    if (clubTypeId == null) return [];
    final dataSource = ref.read(clubSelectionDataSourceProvider);
    return dataSource.getClassesByClubType(clubTypeId);
  });

  // canCompleteStep3Provider — update ref:
  final canCompleteStep3Provider = Provider<bool>((ref) {
    final country = ref.watch(selectedCountryProvider);
    final union = ref.watch(selectedUnionProvider);
    final localField = ref.watch(selectedLocalFieldProvider);
    final clubSection = ref.watch(selectedClubSectionProvider);
    final classId = ref.watch(selectedClassProvider);
    final clubTypeId = ref.watch(selectedClubTypeIdProvider);

    return country != null &&
        union != null &&
        localField != null &&
        clubSection != null &&
        classId != null &&
        clubTypeId != null;
  });
  ```

**Files:** `club_type_selector.dart`, `club_selection_step_view.dart`, `post_registration_shell.dart`

- [ ] **26.8** Update all references in presentation widgets:
  - `selectedClubInstanceProvider` → `selectedClubSectionProvider`
  - `clubInstancesProvider` → `clubSectionsProvider`
  - `ClubInstanceModel` → `ClubSectionModel`
  - `selectedClubTypeSlugProvider` → `selectedClubTypeIdProvider`
  - `clubInstanceId` param in `completeStep3` → `clubSectionId`

### Task 27: Update evidence_folder module

> Rename `clubInstanceId` param to `clubSectionId` throughout the entire evidence_folder feature. Update API URL from `/club-instances/:id/evidence-folder` to `/sections/:id/evidence-folder`.

- [ ] **27.1** Mechanical rename across all evidence_folder files — replace `clubInstanceId` with `clubSectionId` in:
  - `evidence_folder_remote_data_source.dart` (interface + impl, URL: `/club-instances/$clubInstanceId/` → `/sections/$clubSectionId/`)
  - `evidence_folder_repository.dart`
  - `evidence_folder_repository_impl.dart`
  - `get_evidence_folder.dart` (`GetEvidenceFolderParams.clubInstanceId` → `.clubSectionId`)
  - `upload_evidence_file.dart` (`UploadEvidenceFileParams.clubInstanceId` → `.clubSectionId`)
  - `delete_evidence_file.dart` (`DeleteEvidenceFileParams.clubInstanceId` → `.clubSectionId`)
  - `submit_section.dart` (`SubmitSectionParams.clubInstanceId` → `.clubSectionId`)
  - `evidence_folder_providers.dart` (family key, notifier arg)
  - `evidence_folder_view.dart` (widget prop `clubInstanceId` → `clubSectionId`)
  - `evidence_section_detail_view.dart` (widget prop `clubInstanceId` → `clubSectionId`)

- [ ] **27.2** Update the API URL pattern in the datasource:
  ```dart
  // BEFORE:
  '$_baseUrl/club-instances/$clubInstanceId/evidence-folder'
  '$_baseUrl/club-instances/$clubInstanceId/evidence-folder/sections/$sectionId/submit'
  '$_baseUrl/club-instances/$clubInstanceId/evidence-folder/sections/$sectionId/files'

  // AFTER:
  '$_baseUrl/sections/$clubSectionId/evidence-folder'
  '$_baseUrl/sections/$clubSectionId/evidence-folder/sections/$sectionId/submit'
  '$_baseUrl/sections/$clubSectionId/evidence-folder/sections/$sectionId/files'
  ```

### Task 28: Update activities models

> Replace 3 FK fields (`clubAdvId`, `clubPathfId`, `clubMgId`) with single `clubSectionId`.

**File:** `sacdia-app/lib/features/activities/data/models/activity_model.dart`

- [ ] **28.1** Replace the 3 FK fields with 1:
  ```dart
  // BEFORE:
  final int clubAdvId;
  final int clubPathfId;
  final int clubMgId;

  // AFTER:
  final int clubSectionId;
  ```

- [ ] **28.2** Update `fromJson`:
  ```dart
  // BEFORE:
  clubAdvId: (json['club_adv_id'] as int?) ?? 0,
  clubPathfId: (json['club_pathf_id'] as int?) ?? 0,
  clubMgId: (json['club_mg_id'] as int?) ?? 0,

  // AFTER:
  clubSectionId: (json['club_section_id'] as int?) ?? 0,
  ```

- [ ] **28.3** Update `toJson`:
  ```dart
  // BEFORE:
  'club_adv_id': clubAdvId,
  'club_pathf_id': clubPathfId,
  'club_mg_id': clubMgId,

  // AFTER:
  'club_section_id': clubSectionId,
  ```

- [ ] **28.4** Update `toEntity()` — the `Activity` domain entity also needs the same change.

**File:** `sacdia-app/lib/features/activities/data/models/create_activity_request.dart`

- [ ] **28.5** Replace 3 FK fields with 1:
  ```dart
  // BEFORE:
  final int clubAdvId;
  final int clubPathfId;
  final int clubMgId;

  // AFTER:
  final int clubSectionId;
  ```

- [ ] **28.6** Update `toJson`:
  ```dart
  // BEFORE:
  'club_adv_id': clubAdvId,
  'club_pathf_id': clubPathfId,
  'club_mg_id': clubMgId,

  // AFTER:
  'club_section_id': clubSectionId,
  ```

### Task 29: Update router

**File:** `sacdia-app/lib/core/config/router.dart`

- [ ] **29.1** Update the evidence folder shell provider ref:
  ```dart
  // BEFORE:
  final clubInstanceAsync = ref.watch(currentClubInstanceProvider);
  // ... clubInstanceAsync.when(...)
  // ... EvidenceFolderView(clubInstanceId: instance.id.toString())

  // AFTER:
  final clubSectionAsync = ref.watch(currentClubSectionProvider);
  // ... clubSectionAsync.when(...)
  // ... EvidenceFolderView(clubSectionId: section.id.toString())
  ```

### Task 30: Run Flutter analysis and commit

- [ ] **30.1** Run analyzer:
  ```bash
  cd sacdia-app && flutter analyze
  ```
  Expected: zero errors

- [ ] **30.2** Run tests:
  ```bash
  cd sacdia-app && flutter test
  ```
  Expected: ALL PASS

- [ ] **30.3** Commit:
  ```bash
  cd sacdia-app
  git add -A
  git commit -m "refactor: rename club-instances to club-sections across app

  - Domain: ClubInstance entity → ClubSection, remove instanceType field
  - Data: ClubInstanceModel → ClubSectionModel, API URLs /sections/:sectionId
  - Members: ClubContext uses sectionId instead of instanceType+instanceId
  - Post-registration: ClubInstanceModel → ClubSectionModel, flat array parse
  - Evidence folder: clubInstanceId param → clubSectionId, URL /sections/:id
  - Activities: 3 FK fields (clubAdvId/clubPathfId/clubMgId) → clubSectionId
  - Router: update provider refs"
  ```

- [ ] **30.4** Final grep verification:
  ```bash
  cd sacdia-app && grep -rn 'ClubInstance\|club_instance\|clubInstance\|club_adv_id\|club_pathf_id\|club_mg_id\|instanceType\|instance_type' lib/ --include='*.dart' | grep -v 'club_section' | grep -v '\.g\.dart' | grep -v 'generated'
  ```
  Expected: zero matches (except possibly unrelated uses of `instanceType` in other contexts)

---

### Chunk 4 Completion Criteria

1. Zero references to `ClubInstance`, `ClubInstanceModel`, `clubInstanceId`, `instance_type`, `instanceType` (in club context), `club_adv_id`, `club_pathf_id`, `club_mg_id` in `sacdia-app/lib/`
2. All API URLs use `/sections/:sectionId` (no `:type` param)
3. `ClubContext` uses `sectionId` (not `instanceType + instanceId`)
4. `flutter analyze` passes with zero errors
5. `flutter test` passes
6. Old files deleted: `get_club_instance.dart`, `update_club_instance.dart`, `club_instance_model.dart` (post_registration)

---

## Chunk 5: Documentation & Canon

> Actualizar todos los documentos canon, specs y referencias que mencionan las 3 tablas separadas, `club_instances`, o el patron de 3 FK.

**Files affected:**
- `docs/canon/decisiones-clave.md` — nueva decisión de consolidación
- `docs/canon/runtime-sacdia.md` — marcar naming como IMPLEMENTADO
- `docs/features/gestion-clubs.md` — actualizar DB listing
- `docs/features/carpetas-evidencias.md` — endpoints actualizados
- `docs/database/SCHEMA-REFERENCE.md` — tabla consolidada
- `docs/audit/REALITY-MATRIX.md` — actualizar estado
- `docs/audit/DECISIONS-PENDING.md` — cerrar decisión
- `docs/api/API-SPECIFICATION.md` — endpoints actualizados

### Task 31: Update `docs/canon/decisiones-clave.md`

- [ ] **31.1** Add new decision entry:
  ```markdown
  ### Club Sections Consolidation (2026-03-17)

  **Decisión:** Consolidar `club_adventurers`, `club_pathfinders` y `club_master_guilds` en una sola tabla `club_sections` con `club_type_id` como discriminador.

  **Motivación:**
  - 3 tablas identicas violaban DRY y causaban switch/case patterns en todo el stack
  - Agregar un nuevo tipo de club requeria cambios de schema, no solo un INSERT
  - 10 tablas dependientes tenian 3 FK nullables en vez de 1 FK directa

  **Impacto:**
  - SQL: 1 tabla `club_sections` con UNIQUE(main_club_id, club_type_id)
  - Backend: switch/if eliminados, queries parametrizados por club_section_id
  - Admin: API URLs /clubs/:id/sections/:sectionId (sin :type param)
  - App: ClubSection entity, sectionId en vez de instanceType + instanceId
  - Permisos: club_instances:* → club_sections:*

  **Estado:** IMPLEMENTADO
  ```

### Task 32: Update `docs/database/SCHEMA-REFERENCE.md`

- [ ] **32.1** Replace the 3 separate table entries (`club_adventurers`, `club_pathfinders`, `club_master_guilds`) with a single `club_sections` entry:
  ```markdown
  ### club_sections
  | Column | Type | Constraints |
  |--------|------|-------------|
  | club_section_id | SERIAL | PK |
  | active | BOOLEAN | DEFAULT false |
  | souls_target | INT | DEFAULT 1 |
  | fee | INT | DEFAULT 1 |
  | meeting_day | JSON[] | |
  | meeting_time | JSON[] | |
  | club_type_id | INT | NOT NULL, FK → club_types |
  | main_club_id | INT | NULL, FK → clubs ON DELETE CASCADE |
  | created_at | TIMESTAMPTZ | DEFAULT NOW() |
  | modified_at | TIMESTAMPTZ | DEFAULT NOW() |

  **Unique:** (main_club_id, club_type_id)
  ```

- [ ] **32.2** Update all 10 dependent table entries — replace `club_adv_id`/`club_pathf_id`/`club_mg_id` columns with `club_section_id`:
  For each of: `activities`, `activity_instances`, `folder_assignments`, `camporee_clubs`, `club_inventory`, `club_role_assignments`, `finances`, `folders_modules_records`, `folders_section_records`, `units`:
  ```markdown
  | club_section_id | INT | FK → club_sections |
  ```

### Task 33: Update `docs/api/API-SPECIFICATION.md`

- [ ] **33.1** Replace club instances endpoint documentation:
  ```markdown
  ### Club Sections
  | Method | Path | Description |
  |--------|------|-------------|
  | GET | /clubs/:id/sections | List all sections for a club |
  | GET | /clubs/:id/sections/:sectionId | Get section detail |
  | POST | /clubs/:id/sections | Create a new section |
  | PATCH | /clubs/:id/sections/:sectionId | Update a section |
  | DELETE | /clubs/:id/sections/:sectionId | Delete a section |
  | GET | /clubs/:id/sections/:sectionId/members | List section members |
  | POST | /clubs/:id/sections/:sectionId/roles | Assign role in section |
  ```

### Task 34: Update remaining canon and audit docs

- [ ] **34.1** Update `docs/canon/runtime-sacdia.md`:
  - Find references to "club_instances renaming" and mark as **IMPLEMENTADO**
  - Update any table references from 3 tables to `club_sections`

- [ ] **34.2** Update `docs/features/gestion-clubs.md`:
  - Replace table listing: `club_adventurers, club_pathfinders, club_master_guilds` → `club_sections`

- [ ] **34.3** Update `docs/features/carpetas-evidencias.md`:
  - Replace endpoint URLs: `/club-instances/:id/evidence-folder` → `/sections/:id/evidence-folder`

- [ ] **34.4** Update `docs/audit/REALITY-MATRIX.md`:
  - Mark club_sections consolidation as complete
  - Remove any "pending" markers for this change

- [ ] **34.5** Update `docs/audit/DECISIONS-PENDING.md`:
  - Close the club-instances consolidation decision if it exists there
  - Reference the new entry in `decisiones-clave.md`

### Task 35: Final verification and commit

- [ ] **35.1** Run a full grep across docs for stale references:
  ```bash
  cd /Users/abner/Documents/development/sacdia && grep -rn 'club_adventurers\|club_pathfinders\|club_master_guilds\|club_instances\|club_adv_id\|club_pathf_id\|club_mg_id\|ClubInstanceType' docs/ --include='*.md' | grep -v 'history/' | grep -v 'consolidation' | grep -v 'DEPRECATED\|deprecated\|_deprecated'
  ```
  Expected: zero matches (excluding history/ archive docs and the consolidation plan/spec itself)

- [ ] **35.2** Commit docs:
  ```bash
  cd /Users/abner/Documents/development/sacdia
  git add docs/
  git commit -m "docs: update canon and references for club-sections consolidation

  - decisiones-clave: add consolidation decision
  - SCHEMA-REFERENCE: replace 3 tables with club_sections
  - API-SPECIFICATION: update endpoints to /sections/:sectionId
  - runtime-sacdia: mark naming as IMPLEMENTADO
  - gestion-clubs: update table listing
  - carpetas-evidencias: update evidence folder endpoints
  - REALITY-MATRIX: mark consolidation complete
  - DECISIONS-PENDING: close pending decision"
  ```

---

### Chunk 5 Completion Criteria

1. Zero stale references to `club_adventurers`, `club_pathfinders`, `club_master_guilds`, `club_instances` in active canon docs (excluding `docs/history/` and the plan/spec files themselves)
2. `SCHEMA-REFERENCE.md` shows `club_sections` table with 10 dependent tables using `club_section_id`
3. `API-SPECIFICATION.md` shows `/sections/:sectionId` endpoints
4. `decisiones-clave.md` has the consolidation decision marked IMPLEMENTADO
5. `DECISIONS-PENDING.md` has the decision closed

---

## Global Completion Criteria (all 5 chunks)

1. **Database:** `club_sections` table exists, 3 original tables renamed to `*_deprecated`, 10 dependent tables use `club_section_id` FK
2. **Backend:** Zero references to old patterns in `sacdia-backend/src/`, all tests and build pass
3. **Admin:** Zero references to old patterns in `sacdia-admin/src/`, build and lint pass
4. **App:** Zero references to old patterns in `sacdia-app/lib/`, `flutter analyze` clean
5. **Docs:** Canon reflects the consolidated model, zero stale references in active docs
6. **Permissions:** `club_instances:*` → `club_sections:*` in DB and all codebases
7. **API contract:** All routes use `/sections/:sectionId` (no `:type` param anywhere)

---
