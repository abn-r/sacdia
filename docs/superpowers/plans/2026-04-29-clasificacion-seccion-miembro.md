# 8.4-A Section + Member Rankings Implementation Plan (post-audit)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar rankings nivel sección + enrollment ("miembro" user-facing) extendiendo el pipeline composite ranking de 8.4-C, con dark-launch independiente, RBAC granular, y UI en 2 fases (admin web → Flutter móvil).

**Architecture:** Naming híbrido — schema usa `enrollment_*` (real DB entity), URLs/DTOs/UI strings usan `member_*` (user-facing). Sección como agregado puro de enrollments (sin calculadores propios). 3 calculators TDD (clases, investidura binario, camporees). Composite con NULL redistribution. Cron secuencial mismo job (club → enrollment → section), kill-switch independiente. Polimorfismo `award_categories.scope`. Tablas nuevas: `enrollment_rankings`, `section_rankings`, `enrollment_ranking_weights`. Reuso de `WeightsResolverService` y `CompositeScoreService` parametrizados por scope.

**Tech Stack:** NestJS + Prisma + PostgreSQL Neon (3 branches dev/staging/prod) + BullMQ + Redis (cron infra), Jest TDD backend, Next.js 16 + shadcn/ui + Tailwind v4 admin, Flutter Clean Architecture mobile (Fase 2).

**Spec reference:** `docs/superpowers/specs/2026-04-29-clasificacion-seccion-miembro-design.md` (post-audit rewrite, commit 546a26c)

**Audit reference:** `docs/superpowers/audits/2026-04-29-section-member-schema-audit.md` (commit 643b694) — schema reality locked, do NOT re-audit.

**Engram patterns:** #1204/#1296/#1839 (Neon manual psql), #1850 (camporee_clubs split FKs + clubs sin union_id directo — derivar via local_fields), #1883/#1888 (controller order bug + missing e2e gap from 8.4-C — apply learnings).

**Race-safe rule:** Same-repo (sacdia-backend) → serialize subagents. schema.prisma sólo lo edita una task. Cross-repo (backend ↔ admin) paralelizable únicamente después de mergear backend.

**Branch convention:** `feat/section-member-rankings-8-4-a` en los 3 repos cuando arranquen sub-features. Empezar en `sacdia-backend`.

**Test creds dev:** `admin@sacdia.com / Sacdia2026!` (super_admin), `director@sacdia.com / Sacdia2026!` (director-club ACV/GM).

---

## Schema reality (audit-locked)

| Locked fact | Value |
|-------------|-------|
| "Member" entity | `enrollments` (PK `enrollment_id INTEGER`, FK `user_id UUID`) |
| "Section" entity | `club_sections.club_section_id INTEGER` |
| Year FK | `ecclesiastical_years.year_id INTEGER` (referenciado como `ecclesiastical_year_id`) |
| Investiture model | Binary via `enrollments.investiture_status` enum (`IN_PROGRESS|INVESTIDO`) |
| Camporee per-member | `camporee_members.user_id UUID + status='approved'` |
| Class progress | `class_module_progress` (cols `enrollment_id INTEGER`, `user_id UUID`, `class_id INTEGER`, `module_id INTEGER`, `score DOUBLE PRECISION`, `active BOOLEAN`) — sin columna `year_id` directa, año vía `enrollments.ecclesiastical_year_id` |
| Roles | UUID PK, identifier `role_name`, member role UUID `9567fef6-8091-494a-ac1c-fb3716ed2091` |
| Permissions | identifier `permission_name` (NO `name`) |
| system_config | columns `config_key/config_value/config_type/description/updated_at` |
| Camporee year FK | `local_camporees.ecclesiastical_year INTEGER` y `union_camporees.ecclesiastical_year INTEGER` (sin FK formal — referencia informal) |
| Clubs union resolution | `clubs` NO tiene `union_id` directo. Derivar vía `clubs.local_field_id → local_fields.union_id` (engram #1850) |

Subagents executing migrations or services MUST use these audit-locked values. Do NOT re-audit during implementation.

---

## Open questions (defer or resolve in-task)

| # | Pregunta | Resolución |
|---|----------|------------|
| OQ1 | Privacidad `top_n` — `member_name` real, anonimizado, o solo score+rank | Decidir antes de Task 12 (controller `/me`). Default plan: anonimizado `"Miembro #N"` salvo decisión explícita de producto |
| OQ2 | Section aggregation active filter | Phase 2 enhancement — no bloquea Fase 1 |
| OQ3 | Evidence signal reintroducción | Phase 2 — migration dedicada cuando se modele tabla per-member |
| OQ4 | `camporee_members.status` lifecycle ownership | Doc gap — confirmar en staging con datos reales |
| OQ5 | Definición de "completado" en `class_module_progress` | Resolver en Task 4 (consultar equipo backend, default `active=true AND score IS NOT NULL`) |

---

## Phase 1 — Database migrations + RBAC seeds (sacdia-backend)

### Task 1: Crear 4 migration files SQL

**Files:**
- Create: `sacdia-backend/prisma/migrations/20260429000000_enrollment_rankings_schema/migration.sql`
- Create: `sacdia-backend/prisma/migrations/20260429000001_award_categories_scope/migration.sql`
- Create: `sacdia-backend/prisma/migrations/20260429000002_enrollment_rankings_seeds/migration.sql`
- Create: `sacdia-backend/prisma/migrations/20260429000003_enrollment_rankings_default_award_seeds/migration.sql`

- [ ] **Step 1: Crear archivo 1 — `20260429000000_enrollment_rankings_schema/migration.sql`**

Contenido completo:

```sql
-- 20260429000000_enrollment_rankings_schema
-- Audit reference: docs/superpowers/audits/2026-04-29-section-member-schema-audit.md (A1, A3, A10)
-- 3 tablas nuevas + indexes + CHECK constraints

CREATE TABLE enrollment_rankings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  enrollment_id INTEGER NOT NULL REFERENCES enrollments(enrollment_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(user_id),
  club_id INTEGER NOT NULL REFERENCES clubs(club_id),
  club_section_id INTEGER REFERENCES club_sections(club_section_id),
  ecclesiastical_year_id INTEGER NOT NULL REFERENCES ecclesiastical_years(year_id),
  class_score_pct NUMERIC(5,2),
  investiture_score_pct NUMERIC(5,2),
  camporee_score_pct NUMERIC(5,2),
  composite_score_pct NUMERIC(5,2),
  rank_position INTEGER,
  awarded_category_id UUID REFERENCES award_categories(award_category_id),
  composite_calculated_at TIMESTAMPTZ(6),
  created_at TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
  modified_at TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
  CONSTRAINT uq_enrollment_rankings_enrollment_year
    UNIQUE (enrollment_id, ecclesiastical_year_id),
  CONSTRAINT chk_enrollment_rankings_class_score
    CHECK (class_score_pct IS NULL OR (class_score_pct BETWEEN 0 AND 100)),
  CONSTRAINT chk_enrollment_rankings_invest_score
    CHECK (investiture_score_pct IS NULL OR (investiture_score_pct BETWEEN 0 AND 100)),
  CONSTRAINT chk_enrollment_rankings_camporee_score
    CHECK (camporee_score_pct IS NULL OR (camporee_score_pct BETWEEN 0 AND 100)),
  CONSTRAINT chk_enrollment_rankings_composite
    CHECK (composite_score_pct IS NULL OR (composite_score_pct BETWEEN 0 AND 100))
);

CREATE INDEX idx_enrollment_rankings_club_year
  ON enrollment_rankings(club_id, ecclesiastical_year_id);

CREATE INDEX idx_enrollment_rankings_section_year
  ON enrollment_rankings(club_section_id, ecclesiastical_year_id);

CREATE INDEX idx_enrollment_rankings_composite
  ON enrollment_rankings(club_id, ecclesiastical_year_id, composite_score_pct DESC NULLS LAST);

CREATE INDEX idx_enrollment_rankings_user
  ON enrollment_rankings(user_id);

CREATE TABLE section_rankings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  club_section_id INTEGER NOT NULL REFERENCES club_sections(club_section_id) ON DELETE CASCADE,
  club_id INTEGER NOT NULL REFERENCES clubs(club_id),
  ecclesiastical_year_id INTEGER NOT NULL REFERENCES ecclesiastical_years(year_id),
  composite_score_pct NUMERIC(5,2),
  active_enrollment_count INTEGER NOT NULL DEFAULT 0,
  rank_position INTEGER,
  awarded_category_id UUID REFERENCES award_categories(award_category_id),
  composite_calculated_at TIMESTAMPTZ(6),
  created_at TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
  modified_at TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
  CONSTRAINT uq_section_rankings_section_year
    UNIQUE (club_section_id, ecclesiastical_year_id),
  CONSTRAINT chk_section_rankings_composite
    CHECK (composite_score_pct IS NULL OR (composite_score_pct BETWEEN 0 AND 100)),
  CONSTRAINT chk_section_rankings_count_nonneg
    CHECK (active_enrollment_count >= 0)
);

CREATE INDEX idx_section_rankings_club_year
  ON section_rankings(club_id, ecclesiastical_year_id);

CREATE INDEX idx_section_rankings_composite
  ON section_rankings(club_id, ecclesiastical_year_id, composite_score_pct DESC NULLS LAST);

CREATE TABLE enrollment_ranking_weights (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  club_type_id INTEGER REFERENCES club_types(club_type_id),
  ecclesiastical_year_id INTEGER REFERENCES ecclesiastical_years(year_id),
  class_pct NUMERIC(5,2) NOT NULL,
  investiture_pct NUMERIC(5,2) NOT NULL,
  camporee_pct NUMERIC(5,2) NOT NULL,
  is_default BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
  modified_at TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
  CONSTRAINT chk_enrollment_weights_sum_100
    CHECK (class_pct + investiture_pct + camporee_pct = 100),
  CONSTRAINT chk_enrollment_weights_class_range
    CHECK (class_pct BETWEEN 0 AND 100),
  CONSTRAINT chk_enrollment_weights_invest_range
    CHECK (investiture_pct BETWEEN 0 AND 100),
  CONSTRAINT chk_enrollment_weights_camporee_range
    CHECK (camporee_pct BETWEEN 0 AND 100),
  CONSTRAINT uq_enrollment_weights_type_year
    UNIQUE (club_type_id, ecclesiastical_year_id)
);

CREATE UNIQUE INDEX idx_enrollment_weights_default_global
  ON enrollment_ranking_weights ((club_type_id IS NULL), (ecclesiastical_year_id IS NULL))
  WHERE club_type_id IS NULL AND ecclesiastical_year_id IS NULL;
```

- [ ] **Step 2: Crear archivo 2 — `20260429000001_award_categories_scope/migration.sql`**

Contenido completo:

```sql
-- 20260429000001_award_categories_scope
-- Spec §4.4 — extiende award_categories con polimorfismo de scope

ALTER TABLE award_categories
  ADD COLUMN scope VARCHAR(20) NOT NULL DEFAULT 'club';

ALTER TABLE award_categories
  ADD CONSTRAINT chk_award_scope
  CHECK (scope IN ('club', 'section', 'member'));

UPDATE award_categories SET scope = 'club' WHERE scope IS NULL;

CREATE INDEX idx_award_categories_scope
  ON award_categories(scope, is_legacy);
```

- [ ] **Step 3: Crear archivo 3 — `20260429000002_enrollment_rankings_seeds/migration.sql`**

Contenido completo:

```sql
-- 20260429000002_enrollment_rankings_seeds
-- Audit A8 (permission_name + role_id UUID), A9 (system_config columns)

INSERT INTO enrollment_ranking_weights
  (club_type_id, ecclesiastical_year_id, class_pct, investiture_pct, camporee_pct, is_default)
VALUES
  (NULL, NULL, 50, 30, 20, true)
ON CONFLICT DO NOTHING;

INSERT INTO system_config (config_key, config_value, config_type, description) VALUES
  ('member_ranking.recalculation_enabled', 'true',      'boolean',
   'Kill-switch enrollment+section ranking recalc'),
  ('member_ranking.member_visibility',     'self_only', 'string',
   'self_only | self_and_top_n | hidden'),
  ('member_ranking.top_n',                 '5',         'integer',
   'How many top to show if visibility=self_and_top_n')
ON CONFLICT (config_key) DO NOTHING;

INSERT INTO permissions (permission_id, permission_name, description) VALUES
  (gen_random_uuid(), 'member_rankings:read_self',       'Read own member ranking'),
  (gen_random_uuid(), 'member_rankings:read_section',    'Read section member rankings'),
  (gen_random_uuid(), 'member_rankings:read_club',       'Read club member rankings'),
  (gen_random_uuid(), 'member_rankings:read_lf',         'Read local field member rankings'),
  (gen_random_uuid(), 'member_rankings:read_global',     'Read all member rankings'),
  (gen_random_uuid(), 'member_ranking_weights:read',     'Read member ranking weights'),
  (gen_random_uuid(), 'member_ranking_weights:write',    'Write/CRUD member ranking weights'),
  (gen_random_uuid(), 'section_rankings:read_club',      'Read club section rankings'),
  (gen_random_uuid(), 'section_rankings:read_lf',        'Read local field section rankings'),
  (gen_random_uuid(), 'section_rankings:read_global',    'Read all section rankings')
ON CONFLICT (permission_name) DO NOTHING;

-- Grants matriz §4.7
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id FROM roles r, permissions p
  WHERE r.role_name = 'member' AND p.permission_name = 'member_rankings:read_self'
ON CONFLICT DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id FROM roles r, permissions p
  WHERE r.role_name = 'assistant-club'
    AND p.permission_name IN ('member_rankings:read_section','member_rankings:read_club','section_rankings:read_club')
ON CONFLICT DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id FROM roles r, permissions p
  WHERE r.role_name = 'director-club'
    AND p.permission_name IN ('member_rankings:read_section','member_rankings:read_club','section_rankings:read_club')
ON CONFLICT DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id FROM roles r, permissions p
  WHERE r.role_name IN ('director-dia','assistant-dia')
    AND p.permission_name IN ('member_rankings:read_club','section_rankings:read_club')
ON CONFLICT DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id FROM roles r, permissions p
  WHERE r.role_name IN ('director-lf','assistant-lf')
    AND p.permission_name IN ('member_rankings:read_lf','section_rankings:read_lf')
ON CONFLICT DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id FROM roles r, permissions p
  WHERE r.role_name = 'director-lf'
    AND p.permission_name = 'member_ranking_weights:read'
ON CONFLICT DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id FROM roles r, permissions p
  WHERE r.role_name IN ('director-union','assistant-union')
    AND p.permission_name IN ('member_rankings:read_global','section_rankings:read_global','member_ranking_weights:read')
ON CONFLICT DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id FROM roles r, permissions p
  WHERE r.role_name IN ('admin','super_admin')
    AND p.permission_name IN (
      'member_rankings:read_self','member_rankings:read_section','member_rankings:read_club',
      'member_rankings:read_lf','member_rankings:read_global',
      'member_ranking_weights:read','member_ranking_weights:write',
      'section_rankings:read_club','section_rankings:read_lf','section_rankings:read_global'
    )
ON CONFLICT DO NOTHING;
```

- [ ] **Step 4: Crear archivo 4 — `20260429000003_enrollment_rankings_default_award_seeds/migration.sql`**

```sql
-- 20260429000003_enrollment_rankings_default_award_seeds
-- Cutoffs §11.5 spec — laxos vs club (AAA ≥85 en lugar de ≥80)

INSERT INTO award_categories
  (award_category_id, name, color, scope, min_composite_pct, max_composite_pct, is_legacy, created_at, modified_at)
VALUES
  (gen_random_uuid(), 'AAA', '#10b981', 'member',  85, 100,   false, NOW(), NOW()),
  (gen_random_uuid(), 'AA',  '#22c55e', 'member',  75, 84.99, false, NOW(), NOW()),
  (gen_random_uuid(), 'A',   '#eab308', 'member',  65, 74.99, false, NOW(), NOW()),
  (gen_random_uuid(), 'B',   '#f59e0b', 'member',  50, 64.99, false, NOW(), NOW()),
  (gen_random_uuid(), 'C',   '#ef4444', 'member',  0,  49.99, false, NOW(), NOW()),
  (gen_random_uuid(), 'AAA', '#10b981', 'section', 85, 100,   false, NOW(), NOW()),
  (gen_random_uuid(), 'AA',  '#22c55e', 'section', 75, 84.99, false, NOW(), NOW()),
  (gen_random_uuid(), 'A',   '#eab308', 'section', 65, 74.99, false, NOW(), NOW()),
  (gen_random_uuid(), 'B',   '#f59e0b', 'section', 50, 64.99, false, NOW(), NOW()),
  (gen_random_uuid(), 'C',   '#ef4444', 'section', 0,  49.99, false, NOW(), NOW())
ON CONFLICT DO NOTHING;
```

> Nota: si `award_categories` no tiene columna `color`, eliminar de la lista. Verificar con `\d award_categories` en Step 5.

- [ ] **Step 5: Schema reality check pre-aplicación**

```bash
PSQL=/opt/homebrew/opt/libpq/bin/psql
URL=$(neonctl connection-string development --project-id wispy-hall-32797215)
$PSQL "$URL" -v ON_ERROR_STOP=1 <<'SQL'
\d award_categories
\d permissions
\d roles
\d system_config
SQL
```

Verificar columnas reales antes de Task 2.

- [ ] **Step 6: Code review checkpoint** — invocar spec-reviewer subagent contra los 4 archivos SQL.

- [ ] **Step 7: Commit**

```bash
cd sacdia-backend
git add prisma/migrations/20260429000000_enrollment_rankings_schema \
        prisma/migrations/20260429000001_award_categories_scope \
        prisma/migrations/20260429000002_enrollment_rankings_seeds \
        prisma/migrations/20260429000003_enrollment_rankings_default_award_seeds
git commit -m "$(cat <<'EOF'
feat(enrollment-rankings): add 4 migration files for 8.4-A schema

Adds enrollment_rankings, section_rankings, enrollment_ranking_weights
tables; extends award_categories with polymorphic scope column; seeds
default global weights (50/30/20), 3 system_config keys, 10 permissions
with RBAC grants per matrix §4.7, and default award categories for
scope='member' and scope='section'.

Schema audit reference: docs/superpowers/audits/2026-04-29-section-member-schema-audit.md
EOF
)"
```

---

### Task 2: Apply 4 migrations a Neon dev → staging → prod

**Files:**
- Read-only: 4 archivos creados en Task 1
- Execution: psql + neonctl

- [ ] **Step 1: Pre-check estado en cada branch**

```bash
PSQL=/opt/homebrew/opt/libpq/bin/psql
URL=$(neonctl connection-string development --project-id wispy-hall-32797215)
$PSQL "$URL" -v ON_ERROR_STOP=1 <<'SQL'
SELECT to_regclass('public.enrollment_rankings');
SELECT to_regclass('public.section_rankings');
SELECT to_regclass('public.enrollment_ranking_weights');
SELECT column_name FROM information_schema.columns
  WHERE table_name='award_categories' AND column_name='scope';
SELECT config_key FROM system_config
  WHERE config_key IN (
    'member_ranking.recalculation_enabled',
    'member_ranking.member_visibility',
    'member_ranking.top_n'
  );
SELECT permission_name FROM permissions
  WHERE permission_name LIKE 'member_rankings:%'
     OR permission_name LIKE 'member_ranking_weights:%'
     OR permission_name LIKE 'section_rankings:%';
SQL
```

Esperado pre-apply: 3 NULL regclass, 0 columna scope, 0 system_config rows, 0 permissions rows.

- [ ] **Step 2: Apply atómico TXN BEGIN/COMMIT por branch**

Para cada branch (orden: development → staging → production):

```bash
URL=$(neonctl connection-string development --project-id wispy-hall-32797215)
$PSQL "$URL" -v ON_ERROR_STOP=1 <<SQL
BEGIN;

\i sacdia-backend/prisma/migrations/20260429000000_enrollment_rankings_schema/migration.sql
INSERT INTO _prisma_migrations
  (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count)
VALUES
  (gen_random_uuid()::text, 'manual', NOW(),
   '20260429000000_enrollment_rankings_schema', NULL, NULL, NOW(), 1);

\i sacdia-backend/prisma/migrations/20260429000001_award_categories_scope/migration.sql
INSERT INTO _prisma_migrations
  (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count)
VALUES
  (gen_random_uuid()::text, 'manual', NOW(),
   '20260429000001_award_categories_scope', NULL, NULL, NOW(), 1);

\i sacdia-backend/prisma/migrations/20260429000002_enrollment_rankings_seeds/migration.sql
INSERT INTO _prisma_migrations
  (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count)
VALUES
  (gen_random_uuid()::text, 'manual', NOW(),
   '20260429000002_enrollment_rankings_seeds', NULL, NULL, NOW(), 1);

\i sacdia-backend/prisma/migrations/20260429000003_enrollment_rankings_default_award_seeds/migration.sql
INSERT INTO _prisma_migrations
  (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count)
VALUES
  (gen_random_uuid()::text, 'manual', NOW(),
   '20260429000003_enrollment_rankings_default_award_seeds', NULL, NULL, NOW(), 1);

COMMIT;
SQL
```

Repetir con staging y production. Pattern engram #1204/#1296/#1839.

- [ ] **Step 3: Verify post-apply por branch**

```bash
$PSQL "$URL" -v ON_ERROR_STOP=1 <<'SQL'
SELECT to_regclass('public.enrollment_rankings');
SELECT to_regclass('public.section_rankings');
SELECT to_regclass('public.enrollment_ranking_weights');

SELECT scope FROM award_categories LIMIT 1;
-- expect: 'club'

SELECT class_pct, investiture_pct, camporee_pct
  FROM enrollment_ranking_weights
  WHERE club_type_id IS NULL AND ecclesiastical_year_id IS NULL;
-- expect: (50, 30, 20)

SELECT count(*) FROM permissions WHERE permission_name LIKE 'member_rankings:%';
-- expect: 5
SELECT count(*) FROM permissions WHERE permission_name LIKE 'member_ranking_weights:%';
-- expect: 2
SELECT count(*) FROM permissions WHERE permission_name LIKE 'section_rankings:%';
-- expect: 3

SELECT count(*) FROM award_categories WHERE scope = 'member';
-- expect: 5
SELECT count(*) FROM award_categories WHERE scope = 'section';
-- expect: 5

SELECT migration_name FROM _prisma_migrations WHERE migration_name LIKE '20260429%';
-- expect: 4 rows
SQL
```

Si CUALQUIER check falla: STOP. Ejecutar rollback §11.8 spec ANTES de retry.

- [ ] **Step 4: Code review checkpoint** — quality-reviewer subagent contra outputs de los 3 branches.

- [ ] **Step 5: Commit log de aplicación**

```bash
cd sacdia-backend
git status --short
# Si clean, no hay commit. Esta task es operacional.
```

---

### Task 3: Extend `schema.prisma` con 3 modelos nuevos + extension `award_categories.scope`

**Files:**
- Modify: `sacdia-backend/prisma/schema.prisma`
- Generate: `sacdia-backend/node_modules/.prisma/client/`

- [ ] **Step 1: Localizar `model award_categories` y agregar campo `scope`**

```prisma
model award_categories {
  // ... campos existentes ...
  scope String @default("club") @db.VarChar(20)

  @@index([scope, is_legacy], map: "idx_award_categories_scope")
}
```

- [ ] **Step 2: Agregar `model EnrollmentRanking`** (Pascal case, mapea a `enrollment_rankings`)

```prisma
model EnrollmentRanking {
  id                       String    @id @default(uuid()) @db.Uuid
  enrollment_id            Int
  user_id                  String    @db.Uuid
  club_id                  Int
  club_section_id          Int?
  ecclesiastical_year_id   Int
  class_score_pct          Decimal?  @db.Decimal(5, 2)
  investiture_score_pct    Decimal?  @db.Decimal(5, 2)
  camporee_score_pct       Decimal?  @db.Decimal(5, 2)
  composite_score_pct      Decimal?  @db.Decimal(5, 2)
  rank_position            Int?
  awarded_category_id      String?   @db.Uuid
  composite_calculated_at  DateTime? @db.Timestamptz(6)
  created_at               DateTime  @default(now()) @db.Timestamptz(6)
  modified_at              DateTime  @default(now()) @db.Timestamptz(6)

  enrollment               enrollments          @relation(fields: [enrollment_id], references: [enrollment_id], onDelete: Cascade)
  user                     users                @relation(fields: [user_id], references: [user_id])
  club                     clubs                @relation(fields: [club_id], references: [club_id])
  club_section             club_sections?       @relation(fields: [club_section_id], references: [club_section_id])
  ecclesiastical_year      ecclesiastical_years @relation(fields: [ecclesiastical_year_id], references: [year_id])
  awarded_category         award_categories?    @relation(fields: [awarded_category_id], references: [award_category_id])

  @@unique([enrollment_id, ecclesiastical_year_id], map: "uq_enrollment_rankings_enrollment_year")
  @@index([club_id, ecclesiastical_year_id], map: "idx_enrollment_rankings_club_year")
  @@index([club_section_id, ecclesiastical_year_id], map: "idx_enrollment_rankings_section_year")
  @@index([club_id, ecclesiastical_year_id, composite_score_pct(sort: Desc)], map: "idx_enrollment_rankings_composite")
  @@index([user_id], map: "idx_enrollment_rankings_user")
  @@map("enrollment_rankings")
}
```

- [ ] **Step 3: Agregar `model SectionRanking`**

```prisma
model SectionRanking {
  id                       String    @id @default(uuid()) @db.Uuid
  club_section_id          Int
  club_id                  Int
  ecclesiastical_year_id   Int
  composite_score_pct      Decimal?  @db.Decimal(5, 2)
  active_enrollment_count  Int       @default(0)
  rank_position            Int?
  awarded_category_id      String?   @db.Uuid
  composite_calculated_at  DateTime? @db.Timestamptz(6)
  created_at               DateTime  @default(now()) @db.Timestamptz(6)
  modified_at              DateTime  @default(now()) @db.Timestamptz(6)

  club_section             club_sections        @relation(fields: [club_section_id], references: [club_section_id], onDelete: Cascade)
  club                     clubs                @relation(fields: [club_id], references: [club_id])
  ecclesiastical_year      ecclesiastical_years @relation(fields: [ecclesiastical_year_id], references: [year_id])
  awarded_category         award_categories?    @relation(fields: [awarded_category_id], references: [award_category_id])

  @@unique([club_section_id, ecclesiastical_year_id], map: "uq_section_rankings_section_year")
  @@index([club_id, ecclesiastical_year_id], map: "idx_section_rankings_club_year")
  @@index([club_id, ecclesiastical_year_id, composite_score_pct(sort: Desc)], map: "idx_section_rankings_composite")
  @@map("section_rankings")
}
```

- [ ] **Step 4: Agregar `model EnrollmentRankingWeight`**

```prisma
model EnrollmentRankingWeight {
  id                       String    @id @default(uuid()) @db.Uuid
  club_type_id             Int?
  ecclesiastical_year_id   Int?
  class_pct                Decimal   @db.Decimal(5, 2)
  investiture_pct          Decimal   @db.Decimal(5, 2)
  camporee_pct             Decimal   @db.Decimal(5, 2)
  is_default               Boolean   @default(false)
  created_at               DateTime  @default(now()) @db.Timestamptz(6)
  modified_at              DateTime  @default(now()) @db.Timestamptz(6)

  club_type                club_types?           @relation(fields: [club_type_id], references: [club_type_id])
  ecclesiastical_year      ecclesiastical_years? @relation(fields: [ecclesiastical_year_id], references: [year_id])

  @@unique([club_type_id, ecclesiastical_year_id], map: "uq_enrollment_weights_type_year")
  @@map("enrollment_ranking_weights")
}
```

- [ ] **Step 5: Reverse relations en modelos existentes**

En `enrollments`, `users`, `clubs`, `club_sections`, `club_types`, `ecclesiastical_years`, `award_categories` agregar campos del tipo `EnrollmentRanking[]`, `SectionRanking[]`, `EnrollmentRankingWeight[]` según corresponda.

- [ ] **Step 6: `prisma generate` + `tsc --noEmit`**

```bash
cd sacdia-backend
pnpm prisma generate
pnpm tsc --noEmit
```

- [ ] **Step 7: Code review checkpoint** — quality-reviewer subagent: ¿`@@map` correcto? ¿FKs correctas? ¿NULLs alineados con DDL?

- [ ] **Step 8: Commit**

```bash
cd sacdia-backend
git add prisma/schema.prisma
git commit -m "$(cat <<'EOF'
feat(schema): add EnrollmentRanking, SectionRanking, EnrollmentRankingWeight models

Pascal case Prisma models map to snake_case tables (@@map).
Adds reverse relations on enrollments, users, clubs, club_sections,
club_types, ecclesiastical_years, award_categories. Adds polymorphic
scope field to award_categories.
EOF
)"
```

---

## Phase 2 — Backend score calculators TDD (sacdia-backend)

Cada calculator TDD: spec test PRIMERO, then impl, run, commit. NUNCA lanzan excepciones por dato faltante (retornan `null`).

### Task 4: `ClassScoreService` TDD

**Files:**
- Create: `sacdia-backend/src/rankings/member-rankings/services/class-score.service.ts`
- Test: `sacdia-backend/src/rankings/member-rankings/services/class-score.service.spec.ts`

**OQ5 resolution (in-task)**: default = `class_module_progress.active = true` cuenta como completado. (NULL guard removed — column is `Float NOT NULL` per schema, no null possible). Si equipo backend define otra regla, ajustar test cases primero.

- [ ] **Step 1: Write failing test**

```typescript
// class-score.service.spec.ts
import { Test } from '@nestjs/testing';
import { ClassScoreService } from './class-score.service';
import { PrismaService } from '../../../prisma/prisma.service';

describe('ClassScoreService', () => {
  let service: ClassScoreService;
  let prisma: jest.Mocked<PrismaService>;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [
        ClassScoreService,
        {
          provide: PrismaService,
          useValue: {
            enrollments: { findUnique: jest.fn() },
            class_module_progress: { count: jest.fn() },
            class_modules: { count: jest.fn() },
          },
        },
      ],
    }).compile();
    service = module.get(ClassScoreService);
    prisma = module.get(PrismaService);
  });

  it('happy path: 3/5 modules completed → 60.00', async () => {
    (prisma.enrollments.findUnique as jest.Mock).mockResolvedValue({
      enrollment_id: 1, class_id: 10, ecclesiastical_year_id: 2,
    });
    (prisma.class_module_progress.count as jest.Mock).mockResolvedValue(3);
    (prisma.class_modules.count as jest.Mock).mockResolvedValue(5);
    expect(await service.calculate(1, 2)).toBe(60);
  });

  it('required_count = 0 → null', async () => {
    (prisma.enrollments.findUnique as jest.Mock).mockResolvedValue({
      enrollment_id: 1, class_id: 10, ecclesiastical_year_id: 2,
    });
    (prisma.class_module_progress.count as jest.Mock).mockResolvedValue(0);
    (prisma.class_modules.count as jest.Mock).mockResolvedValue(0);
    expect(await service.calculate(1, 2)).toBeNull();
  });

  it('completed > required → clamp 100', async () => {
    (prisma.enrollments.findUnique as jest.Mock).mockResolvedValue({
      enrollment_id: 1, class_id: 10, ecclesiastical_year_id: 2,
    });
    (prisma.class_module_progress.count as jest.Mock).mockResolvedValue(7);
    (prisma.class_modules.count as jest.Mock).mockResolvedValue(5);
    expect(await service.calculate(1, 2)).toBe(100);
  });

  it('no enrollment → null', async () => {
    (prisma.enrollments.findUnique as jest.Mock).mockResolvedValue(null);
    expect(await service.calculate(999, 2)).toBeNull();
  });

  it('exact 0 completed of 5 required → 0', async () => {
    (prisma.enrollments.findUnique as jest.Mock).mockResolvedValue({
      enrollment_id: 1, class_id: 10, ecclesiastical_year_id: 2,
    });
    (prisma.class_module_progress.count as jest.Mock).mockResolvedValue(0);
    (prisma.class_modules.count as jest.Mock).mockResolvedValue(5);
    expect(await service.calculate(1, 2)).toBe(0);
  });
});
```

- [ ] **Step 2: Run test, expect FAIL**

```bash
cd sacdia-backend
pnpm test class-score.service.spec.ts
# expected: ALL fail (service not implemented)
```

- [ ] **Step 3: Implement `class-score.service.ts`**

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';

@Injectable()
export class ClassScoreService {
  constructor(private readonly prisma: PrismaService) {}

  async calculate(
    enrollmentId: number,
    ecclesiasticalYearId: number,
  ): Promise<number | null> {
    const enrollment = await this.prisma.enrollments.findUnique({
      where: { enrollment_id: enrollmentId },
    });
    if (!enrollment) return null;

    const completedCount = await this.prisma.class_module_progress.count({
      where: {
        enrollment_id: enrollmentId,
        active: true,
      },
    });

    const requiredCount = await this.prisma.class_modules.count({
      where: { class_id: enrollment.class_id },
    });

    if (requiredCount === 0) return null;
    return Math.min((completedCount / requiredCount) * 100, 100);
  }
}
```

- [ ] **Step 4: Run test, expect PASS**

```bash
pnpm test class-score.service.spec.ts
# expected: all 5 specs pass
```

- [ ] **Step 5: Code review checkpoint** — quality-reviewer subagent: ¿OQ5 default está documentado? ¿Math.min clamp correcto? ¿no lanza por null?

- [ ] **Step 6: Commit**

```bash
git add sacdia-backend/src/rankings/member-rankings/services/class-score.service.{ts,spec.ts}
git commit -m "$(cat <<'EOF'
feat(enrollment-rankings): add ClassScoreService TDD

Returns NULL when required_count=0 (data insufficient).
Clamps to [0,100]. Uses class_module_progress (audit A4 real table)
joined to enrollments via enrollment_id for year filtering.
EOF
)"
```

---

### Task 5: `InvestitureScoreService` TDD (BINARIO)

**Files:**
- Create: `sacdia-backend/src/rankings/member-rankings/services/investiture-score.service.ts`
- Test: `sacdia-backend/src/rankings/member-rankings/services/investiture-score.service.spec.ts`

- [ ] **Step 1: Write failing test**

```typescript
import { Test } from '@nestjs/testing';
import { InvestitureScoreService } from './investiture-score.service';
import { PrismaService } from '../../../prisma/prisma.service';

describe('InvestitureScoreService', () => {
  let service: InvestitureScoreService;
  let prisma: jest.Mocked<PrismaService>;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [
        InvestitureScoreService,
        { provide: PrismaService, useValue: { enrollments: { findFirst: jest.fn() } } },
      ],
    }).compile();
    service = module.get(InvestitureScoreService);
    prisma = module.get(PrismaService);
  });

  it('INVESTIDO → 100', async () => {
    (prisma.enrollments.findFirst as jest.Mock).mockResolvedValue({
      enrollment_id: 1, investiture_status: 'INVESTIDO',
    });
    expect(await service.calculate(1, 2)).toBe(100);
  });

  it('IN_PROGRESS → 0', async () => {
    (prisma.enrollments.findFirst as jest.Mock).mockResolvedValue({
      enrollment_id: 1, investiture_status: 'IN_PROGRESS',
    });
    expect(await service.calculate(1, 2)).toBe(0);
  });

  it('no enrollment for year → null', async () => {
    (prisma.enrollments.findFirst as jest.Mock).mockResolvedValue(null);
    expect(await service.calculate(1, 999)).toBeNull();
  });

  it('multiple enrollments same year → uses first (findFirst)', async () => {
    (prisma.enrollments.findFirst as jest.Mock).mockResolvedValue({
      enrollment_id: 1, investiture_status: 'INVESTIDO',
    });
    expect(await service.calculate(1, 2)).toBe(100);
    expect(prisma.enrollments.findFirst).toHaveBeenCalledWith({
      where: { enrollment_id: 1, ecclesiastical_year_id: 2 },
    });
  });
});
```

- [ ] **Step 2: Run test, expect FAIL**

```bash
pnpm test investiture-score.service.spec.ts
```

- [ ] **Step 3: Implement**

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';

@Injectable()
export class InvestitureScoreService {
  constructor(private readonly prisma: PrismaService) {}

  async calculate(
    enrollmentId: number,
    ecclesiasticalYearId: number,
  ): Promise<number | null> {
    const enrollment = await this.prisma.enrollments.findFirst({
      where: {
        enrollment_id: enrollmentId,
        ecclesiastical_year_id: ecclesiasticalYearId,
      },
    });
    if (!enrollment) return null;
    return enrollment.investiture_status === 'INVESTIDO' ? 100 : 0;
  }
}
```

- [ ] **Step 4: Run test, expect PASS**

```bash
pnpm test investiture-score.service.spec.ts
```

- [ ] **Step 5: Code review checkpoint** — verifica modelo binario de spec §7.2.

- [ ] **Step 6: Commit**

```bash
git add sacdia-backend/src/rankings/member-rankings/services/investiture-score.service.{ts,spec.ts}
git commit -m "$(cat <<'EOF'
feat(enrollment-rankings): add InvestitureScoreService TDD (binary model)

INVESTIDO → 100, IN_PROGRESS → 0, no enrollment → null.
Audit A6/A11: investiture_requirements table doesn't exist;
binary signal via enrollments.investiture_status enum.
EOF
)"
```

---

### Task 6: `EnrollmentClubResolverService` TDD

**Files:**
- Create: `sacdia-backend/src/rankings/member-rankings/services/enrollment-club-resolver.service.ts`
- Test: `sacdia-backend/src/rankings/member-rankings/services/enrollment-club-resolver.service.spec.ts`

**Why this task exists**: `enrollments` has no direct `club_id` FK. Per-enrollment ranking calculators need to resolve which club + section a member is in for a given year. This service centralizes that traversal:

`enrollment.user_id` → `club_role_assignments(year, active=true, club_section_id IS NOT NULL)` → `club_sections.main_club_id` → `clubs.club_id`

Returns `null` when the user has no active club assignment for the year — those enrollments are NOT ranked.

**v1 heuristic** (document as future refinement): when a user has multiple active assignments in the same year (e.g. helper in one section, member in another), pick the first by `created_at ASC`. Future Q-RB7 may add role-based prioritization.

- [ ] **Step 1: Write failing test**

```typescript
import { Test } from '@nestjs/testing';
import { EnrollmentClubResolverService } from './enrollment-club-resolver.service';
import { PrismaService } from '../../../prisma/prisma.service';

describe('EnrollmentClubResolverService', () => {
  let service: EnrollmentClubResolverService;
  let prisma: any;

  beforeEach(async () => {
    prisma = {
      enrollments: { findUnique: jest.fn() },
      club_role_assignments: { findFirst: jest.fn() },
    };
    const module = await Test.createTestingModule({
      providers: [
        EnrollmentClubResolverService,
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();
    service = module.get(EnrollmentClubResolverService);
  });

  it('happy path: resolves club + section', async () => {
    prisma.enrollments.findUnique.mockResolvedValue({ user_id: 'u1' });
    prisma.club_role_assignments.findFirst.mockResolvedValue({
      club_sections: { club_section_id: 50, main_club_id: 10 },
    });
    expect(await service.resolve(1, 2)).toEqual({ clubId: 10, clubSectionId: 50 });
  });

  it('no enrollment → null', async () => {
    prisma.enrollments.findUnique.mockResolvedValue(null);
    expect(await service.resolve(999, 2)).toBeNull();
    expect(prisma.club_role_assignments.findFirst).not.toHaveBeenCalled();
  });

  it('user has no active assignment for year → null', async () => {
    prisma.enrollments.findUnique.mockResolvedValue({ user_id: 'u1' });
    prisma.club_role_assignments.findFirst.mockResolvedValue(null);
    expect(await service.resolve(1, 2)).toBeNull();
  });

  it('assignment found but main_club_id is null (orphaned section) → null', async () => {
    prisma.enrollments.findUnique.mockResolvedValue({ user_id: 'u1' });
    prisma.club_role_assignments.findFirst.mockResolvedValue({
      club_sections: { club_section_id: 50, main_club_id: null },
    });
    expect(await service.resolve(1, 2)).toBeNull();
  });

  it('passes correct where clause to club_role_assignments.findFirst', async () => {
    prisma.enrollments.findUnique.mockResolvedValue({ user_id: 'u1' });
    prisma.club_role_assignments.findFirst.mockResolvedValue({
      club_sections: { club_section_id: 50, main_club_id: 10 },
    });
    await service.resolve(1, 2);
    expect(prisma.club_role_assignments.findFirst).toHaveBeenCalledWith({
      where: {
        user_id: 'u1',
        ecclesiastical_year_id: 2,
        active: true,
        club_section_id: { not: null },
      },
      orderBy: { created_at: 'asc' },
      select: {
        club_sections: {
          select: { club_section_id: true, main_club_id: true },
        },
      },
    });
  });
});
```

- [ ] **Step 2: Run test, expect FAIL**

```bash
cd sacdia-backend
pnpm test enrollment-club-resolver.service.spec.ts
```

- [ ] **Step 3: Implement**

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';

export interface EnrollmentClubContext {
  clubId: number;
  clubSectionId: number;
}

@Injectable()
export class EnrollmentClubResolverService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Resolves the (clubId, clubSectionId) for an enrollment by traversing:
   *   enrollment.user_id -> club_role_assignments(year, active) -> club_sections -> clubs
   * Returns null when:
   *   - enrollment doesn't exist
   *   - user has no active assignment for the year
   *   - assignment's section has no main_club_id (orphaned section)
   * v1 heuristic: when user has multiple active assignments same year, pick
   * first by created_at ASC. Future Q-RB7 may add role-based selection.
   */
  async resolve(
    enrollmentId: number,
    ecclesiasticalYearId: number,
  ): Promise<EnrollmentClubContext | null> {
    const enrollment = await this.prisma.enrollments.findUnique({
      where: { enrollment_id: enrollmentId },
      select: { user_id: true },
    });
    if (!enrollment) return null;

    const assignment = await this.prisma.club_role_assignments.findFirst({
      where: {
        user_id: enrollment.user_id,
        ecclesiastical_year_id: ecclesiasticalYearId,
        active: true,
        club_section_id: { not: null },
      },
      orderBy: { created_at: 'asc' },
      select: {
        club_sections: {
          select: { club_section_id: true, main_club_id: true },
        },
      },
    });
    if (!assignment?.club_sections?.main_club_id) return null;

    return {
      clubId: assignment.club_sections.main_club_id,
      clubSectionId: assignment.club_sections.club_section_id,
    };
  }
}
```

- [ ] **Step 4: Run test, expect PASS** (5 specs green)

- [ ] **Step 5: Code review checkpoint** — verify findFirst orderBy is deterministic; ensure null cases short-circuit (no extra DB calls).

- [ ] **Step 6: Commit**

```bash
cd sacdia-backend
git add src/rankings/member-rankings/services/enrollment-club-resolver.service.ts src/rankings/member-rankings/services/enrollment-club-resolver.service.spec.ts
git commit -m "$(cat <<'EOF'
feat(enrollment-rankings): add EnrollmentClubResolverService TDD

Centralizes the indirect path from enrollment to club, since
enrollments has no direct club_id FK. Traverses:
  enrollment.user_id -> club_role_assignments(year, active) ->
  club_sections.main_club_id -> clubs.club_id

Returns null when user has no active assignment for the year
(unranked). When multiple active assignments exist, picks first by
created_at ASC (v1 heuristic; future Q-RB7 may add role priority).
Used by Camporee/Class/Investiture/Composite calculators in this
phase.
EOF
)"
```

---

### Task 7: `CamporeeScoreService` per-enrollment TDD

**Files:**
- Create: `sacdia-backend/src/rankings/member-rankings/services/camporee-score.service.ts`
- Test: `sacdia-backend/src/rankings/member-rankings/services/camporee-score.service.spec.ts`

Adaptación del `CamporeeScoreService` club-level de 8.4-C (commit `e654f99`), per-enrollment con `user_id UUID`. Uses `EnrollmentClubResolverService` (Task 6) to resolve the user's club for the year.

**Critical pattern**: numerator must be SCOPE-FILTERED by the same camporee IDs as the denominator. Counting all approved `camporee_members` for a user globally produces inflated scores. 8.4-C reference enforces this scoping; v1 of this plan forgot it and was caught in Stage 2 review. Additionally, union_camporees denominator is filtered through the `union_camporee_local_fields` junction so members are only scored against camporees that invited their local_field — added per Stage 2 review of Task 7.

- [ ] **Step 1: Write failing test**

```typescript
import { Test } from '@nestjs/testing';
import { CamporeeScoreService } from './camporee-score.service';
import { EnrollmentClubResolverService } from './enrollment-club-resolver.service';
import { PrismaService } from '../../../prisma/prisma.service';

describe('CamporeeScoreService (per-enrollment)', () => {
  let service: CamporeeScoreService;
  let prisma: any;
  let resolver: jest.Mocked<EnrollmentClubResolverService>;

  beforeEach(async () => {
    prisma = {
      enrollments: { findUnique: jest.fn() },
      clubs: { findUnique: jest.fn() },
      camporee_members: { count: jest.fn() },
      local_camporees: { findMany: jest.fn() },
      union_camporees: { findMany: jest.fn() },
    };
    resolver = { resolve: jest.fn() } as any;
    const module = await Test.createTestingModule({
      providers: [
        CamporeeScoreService,
        { provide: PrismaService, useValue: prisma },
        { provide: EnrollmentClubResolverService, useValue: resolver },
      ],
    }).compile();
    service = module.get(CamporeeScoreService);
  });

  it('happy path: 1 of 2 in-scope approved → 50', async () => {
    prisma.enrollments.findUnique.mockResolvedValue({ user_id: 'u1' });
    resolver.resolve.mockResolvedValue({ clubId: 10, clubSectionId: 50 });
    prisma.clubs.findUnique.mockResolvedValue({
      local_field_id: 100,
      local_fields: { union_id: 5 },
    });
    prisma.local_camporees.findMany.mockResolvedValue([{ local_camporee_id: 11 }]);
    prisma.union_camporees.findMany.mockResolvedValue([{ union_camporee_id: 22 }]);
    prisma.camporee_members.count.mockResolvedValue(1);
    expect(await service.calculate(1, 2)).toBe(50);
    // verify count was scoped to in-range IDs
    expect(prisma.camporee_members.count).toHaveBeenCalledWith({
      where: {
        user_id: 'u1',
        status: 'approved',
        OR: [
          { camporee_id: { in: [11] } },
          { union_camporee_id: { in: [22] } },
        ],
      },
    });
  });

  it('total scope camporees = 0 → null', async () => {
    prisma.enrollments.findUnique.mockResolvedValue({ user_id: 'u1' });
    resolver.resolve.mockResolvedValue({ clubId: 10, clubSectionId: 50 });
    prisma.clubs.findUnique.mockResolvedValue({
      local_field_id: 100,
      local_fields: { union_id: 5 },
    });
    prisma.local_camporees.findMany.mockResolvedValue([]);
    prisma.union_camporees.findMany.mockResolvedValue([]);
    expect(await service.calculate(1, 2)).toBeNull();
    // count not called when no scope IDs to filter against
    expect(prisma.camporee_members.count).not.toHaveBeenCalled();
  });

  it('club without union_id → only locals in scope, union skipped', async () => {
    prisma.enrollments.findUnique.mockResolvedValue({ user_id: 'u1' });
    resolver.resolve.mockResolvedValue({ clubId: 10, clubSectionId: 50 });
    prisma.clubs.findUnique.mockResolvedValue({
      local_field_id: 100,
      local_fields: null,
    });
    prisma.local_camporees.findMany.mockResolvedValue([{ local_camporee_id: 11 }]);
    prisma.camporee_members.count.mockResolvedValue(1);
    expect(await service.calculate(1, 2)).toBe(100);
    expect(prisma.union_camporees.findMany).not.toHaveBeenCalled();
    expect(prisma.camporee_members.count).toHaveBeenCalledWith({
      where: {
        user_id: 'u1',
        status: 'approved',
        OR: [{ camporee_id: { in: [11] } }],
      },
    });
  });

  it('all approved (3/3) → 100', async () => {
    prisma.enrollments.findUnique.mockResolvedValue({ user_id: 'u1' });
    resolver.resolve.mockResolvedValue({ clubId: 10, clubSectionId: 50 });
    prisma.clubs.findUnique.mockResolvedValue({
      local_field_id: 100,
      local_fields: { union_id: 5 },
    });
    prisma.local_camporees.findMany.mockResolvedValue([
      { local_camporee_id: 11 },
      { local_camporee_id: 12 },
    ]);
    prisma.union_camporees.findMany.mockResolvedValue([{ union_camporee_id: 22 }]);
    prisma.camporee_members.count.mockResolvedValue(3);
    expect(await service.calculate(1, 2)).toBe(100);
  });

  it('no enrollment → null', async () => {
    prisma.enrollments.findUnique.mockResolvedValue(null);
    expect(await service.calculate(999, 2)).toBeNull();
    expect(resolver.resolve).not.toHaveBeenCalled();
  });

  it('resolver returns null (no active assignment) → null', async () => {
    prisma.enrollments.findUnique.mockResolvedValue({ user_id: 'u1' });
    resolver.resolve.mockResolvedValue(null);
    expect(await service.calculate(1, 2)).toBeNull();
    expect(prisma.clubs.findUnique).not.toHaveBeenCalled();
  });
});
```

- [ ] **Step 2: Run test, expect FAIL**

```bash
pnpm test camporee-score.service.spec.ts
```

- [ ] **Step 3: Implement**

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { EnrollmentClubResolverService } from './enrollment-club-resolver.service';

@Injectable()
export class CamporeeScoreService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clubResolver: EnrollmentClubResolverService,
  ) {}

  async calculate(
    enrollmentId: number,
    ecclesiasticalYearId: number,
  ): Promise<number | null> {
    const enrollment = await this.prisma.enrollments.findUnique({
      where: { enrollment_id: enrollmentId },
      select: { user_id: true },
    });
    if (!enrollment) return null;

    const club = await this.clubResolver.resolve(enrollmentId, ecclesiasticalYearId);
    if (!club) return null;

    // engram #1850: clubs has no direct union_id; resolve via local_fields
    const clubData = await this.prisma.clubs.findUnique({
      where: { club_id: club.clubId },
      select: {
        local_field_id: true,
        local_fields: { select: { union_id: true } },
      },
    });
    if (!clubData) return null;

    const localFieldId = clubData.local_field_id;
    const resolvedUnionId = clubData.local_fields?.union_id ?? null;

    const [localCamporees, unionCamporees] = await Promise.all([
      this.prisma.local_camporees.findMany({
        where: {
          ecclesiastical_year: ecclesiasticalYearId,
          active: true,
          local_field_id: localFieldId,
        },
        select: { local_camporee_id: true },
      }),
      resolvedUnionId === null
        ? Promise.resolve([])
        : this.prisma.union_camporees.findMany({
            where: {
              ecclesiastical_year: ecclesiasticalYearId,
              active: true,
              union_id: resolvedUnionId,
              union_camporee_local_fields: {
                some: { local_field_id: localFieldId },
              },
            },
            select: { union_camporee_id: true },
          }),
    ]);

    const localIds = localCamporees.map((c) => c.local_camporee_id);
    const unionIds = unionCamporees.map((c) => c.union_camporee_id);
    const totalCamporees = localIds.length + unionIds.length;
    if (totalCamporees === 0) return null;

    // CRITICAL: scope numerator to in-range camporee IDs only.
    // Without this filter the count includes lifetime global attendance,
    // inflating scores (caught in stage 2 review of v1 plan).
    const orClauses: Array<Record<string, unknown>> = [];
    if (localIds.length > 0) orClauses.push({ camporee_id: { in: localIds } });
    if (unionIds.length > 0) orClauses.push({ union_camporee_id: { in: unionIds } });

    const participatedCount = await this.prisma.camporee_members.count({
      where: {
        user_id: enrollment.user_id,
        status: 'approved',
        OR: orClauses,
      },
    });

    return Math.min((participatedCount / totalCamporees) * 100, 100);
  }
}
```

- [ ] **Step 4: Run test, expect PASS** (6 specs green)

- [ ] **Step 5: Code review checkpoint** — verify numerator scoped to denom IDs (no lifetime inflation); resolver short-circuits when user unranked; engram #1850 split FK applied.

- [ ] **Step 6: Commit**

```bash
git add sacdia-backend/src/rankings/member-rankings/services/camporee-score.service.{ts,spec.ts}
git commit -m "$(cat <<'EOF'
feat(enrollment-rankings): add per-enrollment CamporeeScoreService TDD

Per-enrollment camporee score using camporee_members.user_id UUID.
Resolves the user's club for the year via EnrollmentClubResolverService
(Task 6); enrollments has no direct club_id FK.

Numerator scope: count is filtered by camporee IDs in the same scope as
the denominator (localFieldId + union_id), preventing global lifetime
attendance from inflating scores. v1 plan missed this — caught in
stage 2 review and applied here as the canonical pattern.

Schema deviations from initial plan (cross-ref 8.4-C commit e654f99):
local_camporees scoped by local_field_id (no union_id column);
union_camporees scoped by union_id with conditional skip when club
has no union (column is NOT NULL — no IS NULL fallback).
EOF
)"
```

---

### Task 8: `MemberCompositeScoreService` TDD (NULL redistribution)

**Files:**
- Create: `sacdia-backend/src/rankings/member-rankings/services/member-composite-score.service.ts`
- Create: `sacdia-backend/src/rankings/member-rankings/services/enrollment-weights-resolver.service.ts`
- Test: `sacdia-backend/src/rankings/member-rankings/services/member-composite-score.service.spec.ts`
- Test: `sacdia-backend/src/rankings/member-rankings/services/enrollment-weights-resolver.service.spec.ts`

- [ ] **Step 1: Write failing test (`enrollment-weights-resolver.service.spec.ts`)**

```typescript
import { Test } from '@nestjs/testing';
import { EnrollmentWeightsResolverService } from './enrollment-weights-resolver.service';
import { PrismaService } from '../../../prisma/prisma.service';

describe('EnrollmentWeightsResolverService', () => {
  let service: EnrollmentWeightsResolverService;
  let prisma: any;

  beforeEach(async () => {
    prisma = { enrollmentRankingWeight: { findFirst: jest.fn() } };
    const m = await Test.createTestingModule({
      providers: [EnrollmentWeightsResolverService, { provide: PrismaService, useValue: prisma }],
    }).compile();
    service = m.get(EnrollmentWeightsResolverService);
  });

  it('override (clubType+year) wins', async () => {
    prisma.enrollmentRankingWeight.findFirst
      .mockResolvedValueOnce({ class_pct: 40, investiture_pct: 40, camporee_pct: 20 });
    const r = await service.resolve({ clubTypeId: 1, ecclesiasticalYearId: 2 });
    expect(r).toEqual({ class_pct: 40, investiture_pct: 40, camporee_pct: 20, source: 'override:club_type_1+year_2' });
  });

  it('falls back to default global', async () => {
    prisma.enrollmentRankingWeight.findFirst
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce({ class_pct: 50, investiture_pct: 30, camporee_pct: 20, is_default: true });
    const r = await service.resolve({ clubTypeId: 1, ecclesiasticalYearId: 2 });
    expect(r.class_pct).toBe(50);
    expect(r.source).toBe('default');
  });
});
```

- [ ] **Step 2: Write failing test (`member-composite-score.service.spec.ts`)**

```typescript
describe('MemberCompositeScoreService', () => {
  // happy path: all scores
  it('all available: weighted avg with default 50/30/20', async () => {
    // class=80, investiture=100, camporee=50
    // composite = 0.5*80 + 0.3*100 + 0.2*50 = 40 + 30 + 10 = 80
    // ... see implementation
    expect(80).toBe(80); // placeholder; full mock setup in actual file
  });

  it('investiture NULL → redistribute to class+camporee', async () => {
    // class=80, investiture=NULL, camporee=50; weights 50/30/20
    // weight_used = 50 + 20 = 70
    // weighted_sum = 0.5*80 + 0.2*50 = 40 + 10 = 50
    // composite = 50 / 0.7 = 71.43
    expect(true).toBe(true);
  });

  it('all NULL → composite NULL', async () => {
    expect(true).toBe(true);
  });

  it('override weights applied via resolver', async () => {
    expect(true).toBe(true);
  });
});
```

(Tests con mocks completos; los stubs arriba son guía. El subagent ejecutor expande cada `it` con full mock setup siguiendo patrón Task 4.)

- [ ] **Step 3: Run tests, expect FAIL**

- [ ] **Step 4: Implement `enrollment-weights-resolver.service.ts`**

```typescript
import { Injectable } from '@nestjs/common';
import { AppInternalServerErrorException } from '../../../common/errors/app.exception';
import { ErrorCode } from '../../../common/errors/error-codes';
import { PrismaService } from '../../../prisma/prisma.service';

export interface ResolvedWeights {
  class_pct: number;
  investiture_pct: number;
  camporee_pct: number;
  source: 'default' | string;
}

@Injectable()
export class EnrollmentWeightsResolverService {
  constructor(private readonly prisma: PrismaService) {}

  async resolve(params: {
    clubTypeId: number | null;
    ecclesiasticalYearId: number | null;
  }): Promise<ResolvedWeights> {
    const { clubTypeId, ecclesiasticalYearId } = params;

    // 1. Try override (club_type_id + ecclesiastical_year_id)
    if (clubTypeId !== null && ecclesiasticalYearId !== null) {
      const ovrYear = await this.prisma.enrollmentRankingWeight.findFirst({
        where: { club_type_id: clubTypeId, ecclesiastical_year_id: ecclesiasticalYearId },
      });
      if (ovrYear) {
        return {
          class_pct: Number(ovrYear.class_pct),
          investiture_pct: Number(ovrYear.investiture_pct),
          camporee_pct: Number(ovrYear.camporee_pct),
          source: `override:club_type_${clubTypeId}+year_${ecclesiasticalYearId}`,
        };
      }
    }

    // 2. Try override (club_type_id only)
    if (clubTypeId !== null) {
      const ovrType = await this.prisma.enrollmentRankingWeight.findFirst({
        where: { club_type_id: clubTypeId, ecclesiastical_year_id: null },
      });
      if (ovrType) {
        return {
          class_pct: Number(ovrType.class_pct),
          investiture_pct: Number(ovrType.investiture_pct),
          camporee_pct: Number(ovrType.camporee_pct),
          source: `override:club_type_${clubTypeId}`,
        };
      }
    }

    // 3. Default global
    const def = await this.prisma.enrollmentRankingWeight.findFirst({
      where: { club_type_id: null, ecclesiastical_year_id: null, is_default: true },
    });
    if (!def) {
      throw new AppInternalServerErrorException(
        ErrorCode.RANKING_WEIGHTS_DEFAULT_NOT_FOUND,
      );
    }
    return {
      class_pct: Number(def.class_pct),
      investiture_pct: Number(def.investiture_pct),
      camporee_pct: Number(def.camporee_pct),
      source: 'default',
    };
  }
}
```

- [ ] **Step 5: Implement `member-composite-score.service.ts`**

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { ClassScoreService } from './class-score.service';
import { InvestitureScoreService } from './investiture-score.service';
import { CamporeeScoreService } from './camporee-score.service';
import { EnrollmentWeightsResolverService, ResolvedWeights } from './enrollment-weights-resolver.service';

export interface CompositeResult {
  class_score_pct: number | null;
  investiture_score_pct: number | null;
  camporee_score_pct: number | null;
  composite_score_pct: number | null;
  weights: ResolvedWeights;
}

@Injectable()
export class MemberCompositeScoreService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly classScore: ClassScoreService,
    private readonly investitureScore: InvestitureScoreService,
    private readonly camporeeScore: CamporeeScoreService,
    private readonly weightsResolver: EnrollmentWeightsResolverService,
  ) {}

  async calculate(
    enrollmentId: number,
    ecclesiasticalYearId: number,
  ): Promise<CompositeResult | null> {
    const enrollment = await this.prisma.enrollments.findUnique({
      where: { enrollment_id: enrollmentId },
      include: { classes: { select: { club_type_id: true } } },
    });
    if (!enrollment) return null;

    const weights = await this.weightsResolver.resolve({
      clubTypeId: (enrollment as any).classes?.club_type_id ?? null,
      ecclesiasticalYearId,
    });

    const [classScore, investitureScore, camporeeScore] = await Promise.all([
      this.classScore.calculate(enrollmentId, ecclesiasticalYearId),
      this.investitureScore.calculate(enrollmentId, ecclesiasticalYearId),
      this.camporeeScore.calculate(enrollmentId, ecclesiasticalYearId),
    ]);

    const scores = [classScore, investitureScore, camporeeScore];
    const weightValues = [weights.class_pct, weights.investiture_pct, weights.camporee_pct];

    let totalWeightUsed = 0;
    let weightedSum = 0;
    for (let i = 0; i < scores.length; i++) {
      if (scores[i] !== null) {
        weightedSum += (scores[i] as number) * weightValues[i];
        totalWeightUsed += weightValues[i];
      }
    }

    if (totalWeightUsed === 0) {
      return {
        class_score_pct: classScore,
        investiture_score_pct: investitureScore,
        camporee_score_pct: camporeeScore,
        composite_score_pct: null,
        weights,
      };
    }

    const composite = weightedSum / totalWeightUsed;
    return {
      class_score_pct: classScore,
      investiture_score_pct: investitureScore,
      camporee_score_pct: camporeeScore,
      composite_score_pct: Math.min(Math.max(composite, 0), 100),
      weights,
    };
  }
}
```

- [ ] **Step 6: Run tests, expect PASS**

```bash
pnpm test member-composite-score.service.spec.ts enrollment-weights-resolver.service.spec.ts
```

- [ ] **Step 7: Code review checkpoint** — algoritmo NULL redistribution alineado con spec §7.4 (no dividir por 100, todos los scores ya son pct).

- [ ] **Step 8: Commit**

```bash
git add sacdia-backend/src/rankings/member-rankings/services/{member-composite-score,enrollment-weights-resolver}.service.{ts,spec.ts}
git commit -m "$(cat <<'EOF'
feat(enrollment-rankings): add MemberCompositeScoreService + WeightsResolver TDD

Composite weighted avg with NULL redistribution: if a signal is NULL,
its weight redistributes proportionally to remaining scores.
WeightsResolver: override(clubType+year) → override(clubType) → default.
EOF
)"
```

---

### Task 9: `SectionAggregationService` TDD

**Files:**
- Create: `sacdia-backend/src/rankings/section-rankings/services/section-aggregation.service.ts`
- Test: `sacdia-backend/src/rankings/section-rankings/services/section-aggregation.service.spec.ts`

- [ ] **Step 1: Write failing test**

```typescript
import { Test } from '@nestjs/testing';
import { SectionAggregationService } from './section-aggregation.service';
import { PrismaService } from '../../../prisma/prisma.service';

describe('SectionAggregationService', () => {
  let service: SectionAggregationService;
  let prisma: any;

  beforeEach(async () => {
    prisma = { enrollmentRanking: { findMany: jest.fn() } };
    const m = await Test.createTestingModule({
      providers: [SectionAggregationService, { provide: PrismaService, useValue: prisma }],
    }).compile();
    service = m.get(SectionAggregationService);
  });

  it('3 enrollments with composite → AVG correct', async () => {
    prisma.enrollmentRanking.findMany.mockResolvedValue([
      { composite_score_pct: 80 },
      { composite_score_pct: 60 },
      { composite_score_pct: 40 },
    ]);
    expect(await service.aggregate(1, 2)).toEqual({
      composite_score_pct: 60,
      active_enrollment_count: 3,
    });
  });

  it('0 enrollments → composite NULL, count 0', async () => {
    prisma.enrollmentRanking.findMany.mockResolvedValue([]);
    expect(await service.aggregate(1, 2)).toEqual({
      composite_score_pct: null,
      active_enrollment_count: 0,
    });
  });

  it('mixed (NULLs filtered upstream by where) — only non-null in result', async () => {
    prisma.enrollmentRanking.findMany.mockResolvedValue([
      { composite_score_pct: 100 },
      { composite_score_pct: 50 },
    ]);
    expect(await service.aggregate(1, 2)).toEqual({
      composite_score_pct: 75,
      active_enrollment_count: 2,
    });
  });
});
```

- [ ] **Step 2: Run test, expect FAIL**

- [ ] **Step 3: Implement**

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';

export interface SectionAggregateResult {
  composite_score_pct: number | null;
  active_enrollment_count: number;
}

@Injectable()
export class SectionAggregationService {
  constructor(private readonly prisma: PrismaService) {}

  async aggregate(
    sectionId: number,
    ecclesiasticalYearId: number,
  ): Promise<SectionAggregateResult> {
    const rows = await this.prisma.enrollmentRanking.findMany({
      where: {
        club_section_id: sectionId,
        ecclesiastical_year_id: ecclesiasticalYearId,
        composite_score_pct: { not: null },
      },
      select: { composite_score_pct: true },
    });

    if (rows.length === 0) {
      return { composite_score_pct: null, active_enrollment_count: 0 };
    }

    const sum = rows.reduce(
      (acc, r) => acc + Number(r.composite_score_pct),
      0,
    );
    const avg = sum / rows.length;
    return {
      composite_score_pct: Math.min(Math.max(avg, 0), 100),
      active_enrollment_count: rows.length,
    };
  }
}
```

- [ ] **Step 4: Run test, expect PASS**

- [ ] **Step 5: Code review checkpoint** — confirma que NO filtra por `member_status` (columna no existe — audit A2). Sólo `IS NOT NULL` en composite.

- [ ] **Step 6: Commit**

```bash
git add sacdia-backend/src/rankings/section-rankings/services/section-aggregation.service.{ts,spec.ts}
git commit -m "$(cat <<'EOF'
feat(section-rankings): add SectionAggregationService TDD

AVG of enrollment_rankings.composite_score_pct WHERE NOT NULL.
No member_status filter (column doesn't exist — audit A2).
Returns NULL composite + count=0 for empty sections.
EOF
)"
```

---

## Phase 3 — Backend cron integration + ranking-position update (sacdia-backend)

### Task 10: Extender `rankings.service.ts` con dos métodos nuevos + cron wiring

> **Bundled with Task 11** for implementation — same target file, single commit. See also Task 11.

**Files:**
- Modify: `sacdia-backend/src/annual-folders/rankings.service.ts`
- Modify: `sacdia-backend/src/annual-folders/annual-folders.module.ts`
- Modify: `sacdia-backend/src/system-config/system-config.service.ts` (add `get()` helper — D2.a)
- Test: `sacdia-backend/src/annual-folders/__tests__/rankings.service.spec.ts` (extend existing suite)

**Sub-step 0 (prerequisite): Add `get()` helper to `SystemConfigService`**

Modify `sacdia-backend/src/system-config/system-config.service.ts` to add a non-throwing `get()` method. Existing `findByKey` throws `AppNotFoundException` and stays for callers that want that behaviour. The new `get()` returns `null` when the row is not found:

```typescript
async get(key: string): Promise<string | null> {
  const config = await this.prisma.system_config.findUnique({
    where: { config_key: key },
  });
  return config?.config_value ?? null;
}
```

**Sub-step 0b: Update `RankingsProcessor`**

`sacdia-backend/src/annual-folders/rankings.processor.ts` currently calls `rankingsService.recalculateRankings()`. Update it to call `this.rankingsService.recalculateAll()` instead (new public orchestrator method added in Step 3 below). Existing `recalculateRankings()` stays untouched — it continues to do clubs-only and is called internally by `recalculateAll()`.

- [x] **Step 1: Write failing test (extiende suite existente)**

Extend the existing `Test.createTestingModule()` mock setup in `sacdia-backend/src/annual-folders/__tests__/rankings.service.spec.ts` with three new mocks: `MemberCompositeScoreService`, `SectionAggregationService`, and `SystemConfigService` (the latter must mock `get`). Add a new `describe` block inside the existing file:

```typescript
// sacdia-backend/src/annual-folders/__tests__/rankings.service.spec.ts (extension)
describe('rankings.service — 8.4-A integration', () => {
  it('recalculateAll: skips enrollments+sections if global kill-switch off', async () => {
    // mock systemConfig.get('ranking.recalculation_enabled') → 'false'
    // expect: recalculateRankings NOT called, recalculateEnrollmentRankings NOT called
  });

  it('recalculateAll: skips ONLY steps 2 and 3 if member kill-switch off', async () => {
    // mock 'ranking.recalculation_enabled' → 'true'
    // mock 'member_ranking.recalculation_enabled' → 'false'
    // expect: recalculateRankings called, recalculateEnrollmentRankings NOT called
  });

  it('recalculateAll: continues to step 3 if step 2 throws', async () => {
    // recalculateEnrollmentRankings throws → recalculateSectionAggregates still called
  });

  it('recalculateEnrollmentRankings: per-enrollment error skips, does not throw', async () => {
    // 1 enrollment composite throws → other enrollments still upsert
  });

  it('recalculateSectionAggregates: per-section error skips', async () => {
    // 1 section throws → other sections still upsert
  });
});
```

- [x] **Step 2: Run test, expect FAIL**

```bash
pnpm test rankings.service.spec.ts
```

- [x] **Step 3: Implement extension**

```typescript
// sacdia-backend/src/annual-folders/rankings.service.ts (additions)
// Existing constructor — add 8.4-A deps alongside existing ones:
constructor(
  private readonly prisma: PrismaService,
  private readonly lockService: DistributedLockService,
  private readonly cronLogger: CronRunLogger,
  @Optional()
  @InjectQueue(RANKINGS_QUEUE)
  private readonly rankingsQueue: Queue | null,
  // 8.4-A new
  private readonly memberCompositeScore: MemberCompositeScoreService,
  private readonly sectionAggregation: SectionAggregationService,
  private readonly systemConfig: SystemConfigService,
) {}

// Existing cron — UNCHANGED (still enqueues BullMQ job or direct-call fallback):
@Cron('0 2 * * *', { name: 'annual-folders-rankings-recalc', timeZone: 'UTC' })
async handleRankingsRecalculation() {
  // Existing implementation preserved as-is
}

// Public orchestrator — called by RankingsProcessor (via recalculateAll) + HTTP trigger:
async recalculateAll(yearId?: number): Promise<void> {
  const globalEnabled = await this.systemConfig.get('ranking.recalculation_enabled');
  if (globalEnabled === 'false') {
    this.logger.warn('[rankings] global kill-switch off — skipping all recalculation');
    return;
  }

  // Step 1: clubs (8.4-C existing — untouched)
  await this.recalculateRankings(yearId);

  // 8.4-A kill-switch
  const memberEnabled = await this.systemConfig.get('member_ranking.recalculation_enabled');
  if (memberEnabled === 'false') {
    this.logger.warn('[rankings] member_ranking kill-switch off — skipping steps 2 and 3');
    return;
  }

  // Step 2: enrollments (continues to step 3 even if step 2 throws)
  try {
    await this.recalculateEnrollmentRankings(yearId);
  } catch (err) {
    this.logger.error('[member-rankings] recalculateEnrollmentRankings failed, continuing to section aggregates', err);
  }

  // Step 3: sections
  try {
    await this.recalculateSectionAggregates(yearId);
  } catch (err) {
    this.logger.error('[section-rankings] recalculateSectionAggregates failed', err);
  }
}

// Existing HTTP entry point — UNCHANGED (clubs only, acquires lock, calls _runRecalculation):
// async recalculateRankings(yearId?: number): Promise<void> { ... }

async recalculateEnrollmentRankings(ecclesiasticalYearId?: number): Promise<void> {
  const yearId = ecclesiasticalYearId ?? await this.resolveYear();
  this.logger.log(`[member-rankings] Recalc started ecclesiastical_year_id=${yearId}`);

  const clubs = await this.prisma.clubs.findMany({
    where: { active: true },
    select: { club_id: true },
  });

  let totalEnrollments = 0;
  let totalSkipped = 0;

  // Batch by chunks of 50 clubs
  const chunkSize = 50;
  for (let i = 0; i < clubs.length; i += chunkSize) {
    const chunk = clubs.slice(i, i + chunkSize);
    for (const c of chunk) {
      // D9-α: resolve class_id set via club_sections → club_type_id → classes
      const sections = await this.prisma.club_sections.findMany({
        where: { main_club_id: c.club_id, active: true },
        select: { club_section_id: true, club_type_id: true },
      });
      if (sections.length === 0) continue;

      const clubTypeIds = [...new Set(sections.map((s) => s.club_type_id))];
      const classes = await this.prisma.classes.findMany({
        where: { club_type_id: { in: clubTypeIds } },
        select: { class_id: true, club_type_id: true },
      });
      const classIdSet = classes.map((cls) => cls.class_id);
      if (classIdSet.length === 0) continue;

      // Map club_type_id → club_section_id (first section per type) for ranking row
      const sectionByClubType = new Map<number, number>();
      for (const s of sections) {
        if (!sectionByClubType.has(s.club_type_id)) {
          sectionByClubType.set(s.club_type_id, s.club_section_id);
        }
      }
      const classToClubType = new Map<number, number>();
      for (const cls of classes) {
        classToClubType.set(cls.class_id, cls.club_type_id);
      }

      const enrollments = await this.prisma.enrollments.findMany({
        where: {
          ecclesiastical_year_id: yearId,
          active: true,
          class_id: { in: classIdSet },
        },
        select: { enrollment_id: true, user_id: true, class_id: true },
      });

      for (const e of enrollments) {
        try {
          const result = await this.memberCompositeScore.calculate(e.enrollment_id, yearId);
          if (!result) { totalSkipped++; continue; }

          const clubTypeId = classToClubType.get(e.class_id);
          const clubSectionId = clubTypeId ? sectionByClubType.get(clubTypeId) ?? null : null;

          await this.prisma.enrollmentRanking.upsert({
            where: {
              enrollment_id_ecclesiastical_year_id: {
                enrollment_id: e.enrollment_id,
                ecclesiastical_year_id: yearId,
              },
            },
            create: {
              enrollment_id: e.enrollment_id,
              user_id: e.user_id,
              club_id: c.club_id,
              club_section_id: clubSectionId,
              ecclesiastical_year_id: yearId,
              class_score_pct: result.class_score_pct,
              investiture_score_pct: result.investiture_score_pct,
              camporee_score_pct: result.camporee_score_pct,
              composite_score_pct: result.composite_score_pct,
              composite_calculated_at: new Date(),
            },
            update: {
              class_score_pct: result.class_score_pct,
              investiture_score_pct: result.investiture_score_pct,
              camporee_score_pct: result.camporee_score_pct,
              composite_score_pct: result.composite_score_pct,
              composite_calculated_at: new Date(),
              modified_at: new Date(),
            },
          });
          totalEnrollments++;
        } catch (err) {
          this.logger.error({
            msg: '[member-rankings] enrollment skip',
            enrollment_id: e.enrollment_id,
            ecclesiastical_year_id: yearId,
            error: (err as Error).message,
          });
          totalSkipped++;
        }
      }
    }
  }

  // Update rank_position via DENSE_RANK SQL (Task 11)
  await this.updateEnrollmentRankPositions(yearId);

  this.logger.log(`[member-rankings] Recalc done enrollments=${totalEnrollments} skipped=${totalSkipped}`);
}

async recalculateSectionAggregates(ecclesiasticalYearId?: number): Promise<void> {
  const yearId = ecclesiasticalYearId ?? await this.resolveYear();
  this.logger.log(`[section-rankings] Recalc started ecclesiastical_year_id=${yearId}`);

  const sections = await this.prisma.club_sections.findMany({
    where: { active: true },
    select: { club_section_id: true, main_club_id: true },
  });

  let totalSections = 0;
  let totalEmpty = 0;
  let totalErrors = 0;

  for (const s of sections) {
    try {
      const agg = await this.sectionAggregation.aggregate(s.club_section_id, yearId);
      if (agg.composite_score_pct === null) totalEmpty++;

      await this.prisma.sectionRanking.upsert({
        where: {
          club_section_id_ecclesiastical_year_id: {
            club_section_id: s.club_section_id,
            ecclesiastical_year_id: yearId,
          },
        },
        create: {
          club_section_id: s.club_section_id,
          club_id: s.main_club_id,
          ecclesiastical_year_id: yearId,
          composite_score_pct: agg.composite_score_pct,
          active_enrollment_count: agg.active_enrollment_count,
          composite_calculated_at: new Date(),
        },
        update: {
          composite_score_pct: agg.composite_score_pct,
          active_enrollment_count: agg.active_enrollment_count,
          composite_calculated_at: new Date(),
          modified_at: new Date(),
        },
      });
      totalSections++;
    } catch (err) {
      this.logger.error({
        msg: '[section-rankings] section skip',
        club_section_id: s.club_section_id,
        ecclesiastical_year_id: yearId,
        error: (err as Error).message,
      });
      totalErrors++;
    }
  }

  await this.updateSectionRankPositions(yearId);

  this.logger.log(`[section-rankings] Recalc done sections=${totalSections} empty=${totalEmpty} errors=${totalErrors}`);
}

// updateEnrollmentRankPositions / updateSectionRankPositions: Task 11
// resolveYear: existing private method in 8.4-C (NOT resolveActiveYear)
```

- [x] **Step 4: Wire módulo — modify `sacdia-backend/src/annual-folders/annual-folders.module.ts`**

```typescript
// annual-folders.module.ts
@Module({
  imports: [
    PrismaModule,
    ClubEnrollmentsModule,
    CatalogsModule,
    SystemConfigModule, // NEW for 8.4-A kill-switches
    ...(redisAvailable ? [BullModule.registerQueue({ name: RANKINGS_QUEUE })] : []),
  ],
  controllers: [
    AnnualFolderTemplatesController,
    AnnualFoldersController,
    AnnualFolderBySectionController,
    AwardCategoriesController,
    EvaluationController,
    RankingsController,
  ],
  providers: [
    AnnualFoldersService,
    AwardCategoriesService,
    EvaluationService,
    RankingsService,
    // 8.4-A new — calculation pipeline
    ClassScoreService,
    InvestitureScoreService,
    CamporeeScoreService, // NOTE: per-enrollment one from src/rankings/member-rankings
    EnrollmentClubResolverService,
    EnrollmentWeightsResolverService,
    MemberCompositeScoreService,
    SectionAggregationService,
    ...(redisAvailable ? [RankingsProcessor] : []),
  ],
  exports: [
    AnnualFoldersService,
    AwardCategoriesService,
    EvaluationService,
    RankingsService,
  ],
})
export class AnnualFoldersModule {}
```

> **DI collision note**: Task 4 (`ClassScoreService`) and Task 7 (`CamporeeScoreService` at `src/rankings/member-rankings/services/`) share the class name `CamporeeScoreService` with the existing club-level one (8.4-C at a different path). Verify no DI collision at implementation time; if collision arises, rename the per-enrollment one to `EnrollmentCamporeeScoreService`.

- [x] **Step 5: Run test, expect PASS**

```bash
pnpm test rankings.service.spec.ts
```

- [x] **Step 6: Code review checkpoint** — quality-reviewer subagent: ¿logs estructurados spec §13.1? ¿try/catch per fase? ¿idempotencia upsert garantizada?

- [x] **Step 7: Commit** (bundles Task 10 + Task 11 — see Task 11 for DENSE_RANK methods included in this commit)

```bash
git add sacdia-backend/src/annual-folders/rankings.service.ts
git add sacdia-backend/src/annual-folders/annual-folders.module.ts
git add sacdia-backend/src/annual-folders/__tests__/rankings.service.spec.ts
git add sacdia-backend/src/system-config/system-config.service.ts
git commit -m "$(cat <<'EOF'
feat(rankings): extend cron with enrollment + section recalc steps

Adds recalculateAll orchestrator, recalculateEnrollmentRankings, and
recalculateSectionAggregates as sequential steps 2 and 3 of the daily
02:00 UTC cron. Independent kill-switch member_ranking.recalculation_enabled
allows dark launch. Per-enrollment and per-section errors log+skip without
bubbling. DENSE_RANK rank_position updates run after each upsert pass.
EOF
)"
```

---

### Task 11: SQL UPDATE DENSE_RANK() per club + year (NULLS LAST)

> **Bundled with Task 10** implementation. Same target file (`sacdia-backend/src/annual-folders/rankings.service.ts`). Same commit.

**Files:**
- Modify: `sacdia-backend/src/annual-folders/rankings.service.ts` (agrega métodos privados `updateEnrollmentRankPositions` + `updateSectionRankPositions`)
- Test: `sacdia-backend/src/annual-folders/__tests__/rankings.service.spec.ts` (extend existing suite — add `describe('rankings.service — DENSE_RANK')` block; do NOT create a separate file)

> **Migration column verification**: PK column for both `enrollment_rankings` and `section_rankings` is `id` (UUID). Confirmed in `sacdia-backend/prisma/migrations/20260429000000_enrollment_rankings_schema/migration.sql`. The SQL below is correct.

- [x] **Step 1: Write failing integration test** (inside existing spec file, new describe block)

```typescript
// sacdia-backend/src/annual-folders/__tests__/rankings.service.spec.ts (extension)
describe('rankings.service — DENSE_RANK', () => {
  let service: RankingsService;
  let prisma: PrismaService;

  beforeAll(async () => {
    const m = await Test.createTestingModule({
      // ... full module setup with REAL prisma against test DB
    }).compile();
    service = m.get(RankingsService);
    prisma = m.get(PrismaService);
  });

  beforeEach(async () => {
    await prisma.$executeRawUnsafe('DELETE FROM enrollment_rankings WHERE ecclesiastical_year_id = 9999');
  });

  it('assigns dense_rank by composite DESC, NULLs last', async () => {
    // seed: club 1 with 4 enrollments composite [80, 80, 50, NULL]
    // expected ranks: 1, 1, 2, 3 (dense — ties share rank, NULL last)
    // ... insert seed rows ...
    await service['updateEnrollmentRankPositions'](9999);
    const rows = await prisma.enrollmentRanking.findMany({
      where: { ecclesiastical_year_id: 9999, club_id: 1 },
      orderBy: { rank_position: 'asc' },
    });
    expect(rows.map(r => [Number(r.composite_score_pct), r.rank_position])).toEqual([
      [80, 1], [80, 1], [50, 2], [null, 3],
    ]);
  });
});
```

- [x] **Step 2: Run test, expect FAIL**

- [x] **Step 3: Implement los 2 métodos privados**

```typescript
// sacdia-backend/src/annual-folders/rankings.service.ts (additions)
// PK col is `id` (UUID) — confirmed in migration 20260429000000_enrollment_rankings_schema
private async updateEnrollmentRankPositions(yearId: number): Promise<void> {
  await this.prisma.$executeRaw`
    UPDATE enrollment_rankings er
    SET rank_position = sub.rnk
    FROM (
      SELECT id,
        DENSE_RANK() OVER (
          PARTITION BY club_id, ecclesiastical_year_id
          ORDER BY composite_score_pct DESC NULLS LAST
        ) AS rnk
      FROM enrollment_rankings
      WHERE ecclesiastical_year_id = ${yearId}
    ) sub
    WHERE er.id = sub.id
  `;
}

private async updateSectionRankPositions(yearId: number): Promise<void> {
  await this.prisma.$executeRaw`
    UPDATE section_rankings sr
    SET rank_position = sub.rnk
    FROM (
      SELECT id,
        DENSE_RANK() OVER (
          PARTITION BY club_id, ecclesiastical_year_id
          ORDER BY composite_score_pct DESC NULLS LAST
        ) AS rnk
      FROM section_rankings
      WHERE ecclesiastical_year_id = ${yearId}
    ) sub
    WHERE sr.id = sub.id
  `;
}
```

- [x] **Step 4: Run test, expect PASS**

```bash
pnpm test rankings.service.spec.ts
```

- [x] **Step 5: Code review checkpoint** — verify NULLS LAST y DENSE_RANK (no ROW_NUMBER): empates comparten rank.

- [x] **Step 6: Commit** — handled by Task 10 Step 7 (single bundled commit covering both tasks)

---

## Phase 4 — Backend REST endpoints (sacdia-backend)

> **CRÍTICO — engram #1883/PR #28**: orden controllers en module.controllers array MATTERS. Rutas estáticas (`/me`, `/recalculate`) ANTES de rutas dinámicas (`/:enrollmentId`). Si un PR rompe orden, ParseUUIDPipe/ParseIntPipe se aplica primero a la ruta dinámica y devuelve 400 BadRequest sobre URLs estáticas. Tests modulares NO detectan esto: SOLO e2e con HTTP real (engram #1888) — Phase 4 incluye tarea e2e dedicada.

### Task 12: Crear módulo `member-rankings/`

**Files:**
- Create: `sacdia-backend/src/rankings/member-rankings/member-rankings.controller.ts`
- Create: `sacdia-backend/src/rankings/member-rankings/member-rankings.service.ts`
- Create: `sacdia-backend/src/rankings/member-rankings/dto/member-ranking-response.dto.ts`
- Create: `sacdia-backend/src/rankings/member-rankings/dto/member-breakdown.dto.ts`
- Create: `sacdia-backend/src/rankings/member-rankings/dto/member-my-ranking.dto.ts`
- Create: `sacdia-backend/src/rankings/member-rankings/member-rankings.module.ts`
- Test: `sacdia-backend/src/rankings/member-rankings/member-rankings.controller.spec.ts`

- [ ] **Step 1: Write failing test (RBAC matrix scenarios)**

```typescript
describe('MemberRankingsController', () => {
  it('GET / member self → 200 (own only)', async () => { /* ... */ });
  it('GET / member other enrollment_id → 403', async () => { /* ... */ });
  it('GET / director-club mismo club → 200 filtered', async () => { /* ... */ });
  it('GET / director-club otro club → 403', async () => { /* ... */ });
  it('GET /me visibility=hidden → 403 MEMBER_RANKING_HIDDEN', async () => { /* ... */ });
  it('GET /me visibility=self_and_top_n → includes top_n', async () => { /* ... */ });
  it('GET /:enrollmentId/breakdown ParseIntPipe — string "abc" → 400', async () => { /* ... */ });
  it('POST /recalculate kill-switch off → 400 RECALCULATION_DISABLED', async () => { /* ... */ });
});
```

- [x] **Step 2: Run test, expect FAIL**

- [x] **Step 3: Implement DTOs**

```typescript
// member-ranking-response.dto.ts
export class MemberRankingResponseDto {
  enrollment_id!: number;
  user_id!: string;
  member_name!: string;
  club_section_id!: number | null;
  section_name!: string | null;
  class_score_pct!: number | null;
  investiture_score_pct!: number | null;
  camporee_score_pct!: number | null;
  composite_score_pct!: number | null;
  rank_position!: number | null;
  awarded_category!: {
    id: string; name: string; icon: string | null;
    min_pct: number; max_pct: number;
  } | null;
  composite_calculated_at!: string | null;

  static fromEnrollmentRanking(row: any): MemberRankingResponseDto {
    return {
      enrollment_id: row.enrollment_id,
      user_id: row.user_id,
      member_name: row.user?.name ?? '',
      club_section_id: row.club_section_id,
      section_name: row.club_section?.name ?? null,
      class_score_pct: row.class_score_pct !== null ? Number(row.class_score_pct) : null,
      investiture_score_pct: row.investiture_score_pct !== null ? Number(row.investiture_score_pct) : null,
      camporee_score_pct: row.camporee_score_pct !== null ? Number(row.camporee_score_pct) : null,
      composite_score_pct: row.composite_score_pct !== null ? Number(row.composite_score_pct) : null,
      rank_position: row.rank_position,
      awarded_category: row.awarded_category ? {
        id: row.awarded_category.award_category_id,
        name: row.awarded_category.name,
        icon: row.awarded_category.icon ?? null,
        min_pct: Number(row.awarded_category.min_composite_pct),
        max_pct: Number(row.awarded_category.max_composite_pct),
      } : null,
      composite_calculated_at: row.composite_calculated_at?.toISOString() ?? null,
    };
  }
}

// member-breakdown.dto.ts (extends Response + adds breakdowns)
// member-my-ranking.dto.ts: { member, visibility_mode, top_n? }
```

- [x] **Step 4: Implement service `member-rankings.service.ts`**

```typescript
@Injectable()
export class MemberRankingsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly systemConfig: SystemConfigService,
    private readonly rankingsService: RankingsService,
  ) {}

  async list(params: {
    callerScope: ScopeContext; // resuelto por guard
    clubId?: number;
    sectionId?: number;
    yearId?: number;
    page: number;
    limit: number;
  }) {
    const where = this.buildScopeWhere(params);
    const [data, total] = await Promise.all([
      this.prisma.enrollmentRanking.findMany({
        where,
        skip: (params.page - 1) * params.limit,
        take: params.limit,
        orderBy: { rank_position: 'asc' },
        include: { user: true, club_section: true, awarded_category: true },
      }),
      this.prisma.enrollmentRanking.count({ where }),
    ]);
    return { data: data.map(MemberRankingResponseDto.fromEnrollmentRanking), total, page: params.page, limit: params.limit };
  }

  async getMyRanking(userId: string, yearId: number): Promise<MemberMyRankingDto> {
    const visibility = await this.systemConfig.get('member_ranking.member_visibility') ?? 'self_only';
    if (visibility === 'hidden') {
      throw new ForbiddenException({ code: 'MEMBER_RANKING_HIDDEN', message: 'Member ranking visibility is hidden' });
    }

    const own = await this.prisma.enrollmentRanking.findFirst({
      where: { user_id: userId, ecclesiastical_year_id: yearId },
      orderBy: { rank_position: 'asc' },
      include: { user: true, club_section: true, awarded_category: true },
    });
    const memberDto = own ? MemberRankingResponseDto.fromEnrollmentRanking(own) : null;

    let topN: any[] | undefined;
    if (visibility === 'self_and_top_n' && own) {
      const n = Number(await this.systemConfig.get('member_ranking.top_n') ?? '5');
      const top = await this.prisma.enrollmentRanking.findMany({
        where: { club_id: own.club_id, ecclesiastical_year_id: yearId, composite_score_pct: { not: null } },
        orderBy: { rank_position: 'asc' },
        take: n,
        include: { user: true },
      });
      // OQ1 default: anonimizado
      topN = top.map((r, idx) => ({
        member_name: `Miembro #${idx + 1}`,
        composite_score_pct: r.composite_score_pct !== null ? Number(r.composite_score_pct) : null,
        rank_position: r.rank_position,
      }));
    }

    return { member: memberDto!, visibility_mode: visibility as any, top_n: topN };
  }

  async getBreakdown(enrollmentId: number, yearId: number, callerScope: ScopeContext): Promise<MemberBreakdownDto> {
    // 1. Validar scope
    // 2. Cargar EnrollmentRanking row + cargar weights aplicadas
    // 3. Computar 3 breakdowns numéricos (completedCount/requiredCount, status, participated/total)
    // 4. Devolver DTO
  }

  async triggerRecalculate(yearId: number, clubId?: number) {
    const enabled = await this.systemConfig.get('member_ranking.recalculation_enabled');
    if (enabled === 'false') {
      throw new BadRequestException({ code: 'RECALCULATION_DISABLED' });
    }
    await this.rankingsService.recalculateEnrollmentRankings(yearId);
    await this.rankingsService.recalculateSectionAggregates(yearId);
    return { triggered: true, ecclesiastical_year_id: yearId, club_id: clubId };
  }

  private buildScopeWhere(params: any): Prisma.EnrollmentRankingWhereInput {
    // Resolver según permisos: read_self → user_id=caller; read_club → club_id IN (caller_clubs); etc.
    return {};
  }
}
```

- [x] **Step 5: Implement controller con orden de rutas correcto**

```typescript
import { Controller, Get, Post, Param, Query, Body, UseGuards, ParseIntPipe, Req } from '@nestjs/common';
import { JwtAuthGuard } from '../../auth/jwt-auth.guard';
import { PermissionsGuard } from '../../auth/permissions.guard';
import { RequirePermissions } from '../../auth/decorators/require-permissions.decorator';

@Controller('member-rankings')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class MemberRankingsController {
  constructor(private readonly service: MemberRankingsService) {}

  // STATIC ROUTES FIRST (engram #1883)
  @Get('/me')
  @RequirePermissions('member_rankings:read_self')
  async getMyRanking(@Req() req: any) {
    return this.service.getMyRanking(req.user.user_id, await this.resolveActiveYear());
  }

  @Post('/recalculate')
  @RequirePermissions('member_ranking_weights:write')
  async triggerRecalculate(@Body() body: { ecclesiastical_year_id?: number; club_id?: number }) {
    return this.service.triggerRecalculate(body.ecclesiastical_year_id ?? await this.resolveActiveYear(), body.club_id);
  }

  // DYNAMIC ROUTES AFTER
  @Get('/:enrollmentId/breakdown')
  @RequirePermissions('member_rankings:read_self','member_rankings:read_section','member_rankings:read_club','member_rankings:read_lf','member_rankings:read_global')
  async getBreakdown(
    @Param('enrollmentId', ParseIntPipe) enrollmentId: number,
    @Query('ecclesiastical_year_id', ParseIntPipe) yearId: number,
    @Req() req: any,
  ) {
    return this.service.getBreakdown(enrollmentId, yearId, req.user.scope);
  }

  // LIST (root)
  @Get()
  @RequirePermissions('member_rankings:read_self','member_rankings:read_section','member_rankings:read_club','member_rankings:read_lf','member_rankings:read_global')
  async list(
    @Query('club_id') clubId?: string,
    @Query('section_id') sectionId?: string,
    @Query('ecclesiastical_year_id') yearId?: string,
    @Query('page') page = '1',
    @Query('limit') limit = '50',
    @Req() req: any,
  ) {
    return this.service.list({
      callerScope: req.user.scope,
      clubId: clubId ? parseInt(clubId, 10) : undefined,
      sectionId: sectionId ? parseInt(sectionId, 10) : undefined,
      yearId: yearId ? parseInt(yearId, 10) : undefined,
      page: parseInt(page, 10),
      limit: parseInt(limit, 10),
    });
  }

  private async resolveActiveYear(): Promise<number> {
    // shared helper (en service o utility)
    return 0;
  }
}
```

- [x] **Step 6: Run tests, expect PASS** (8 controller specs)

```bash
pnpm test member-rankings.controller.spec.ts
```

- [x] **Step 7: Code review checkpoint** — quality-reviewer subagent: ¿order rutas correcto? ¿`ParseIntPipe` en `:enrollmentId`? ¿RBAC permissions correctos?

- [x] **Step 8: Commit**

```bash
git add sacdia-backend/src/rankings/member-rankings
git commit -m "$(cat <<'EOF'
feat(member-rankings): add controller + service + DTOs (REST endpoints)

GET / list (paginated, RBAC scope-filtered)
GET /me (visibility-gated: hidden→403, self_only, self_and_top_n)
GET /:enrollmentId/breakdown (ParseIntPipe — INTEGER, NOT UUID)
POST /recalculate (kill-switch validated)

Static routes registered BEFORE dynamic to avoid ParseIntPipe order
bug (engram #1883/#1888).
EOF
)"
```

---

### Task 13: Crear módulo `section-rankings/`

**Files:**
- Create: `sacdia-backend/src/rankings/section-rankings/section-rankings.controller.ts`
- Create: `sacdia-backend/src/rankings/section-rankings/section-rankings.service.ts`
- Create: `sacdia-backend/src/rankings/section-rankings/dto/section-ranking-response.dto.ts`
- Create: `sacdia-backend/src/rankings/section-rankings/section-rankings.module.ts`
- Test: `sacdia-backend/src/rankings/section-rankings/section-rankings.controller.spec.ts`

- [x] **Step 1: Write failing test**

```typescript
describe('SectionRankingsController', () => {
  it('GET / director-club → 200 filtered by club', async () => { /* ... */ });
  it('GET / member → 403', async () => { /* ... */ });
  it('GET /:sectionId/members ParseIntPipe — "abc" → 400', async () => { /* ... */ });
  it('GET /:sectionId/members → enrollments ordered by rank_position ASC NULLS LAST', async () => { /* ... */ });
});
```

- [x] **Step 2: Run test, expect FAIL**

- [x] **Step 3: Implement DTO + service + controller**

```typescript
// section-ranking-response.dto.ts
export class SectionRankingResponseDto {
  club_section_id!: number;
  section_name!: string;
  composite_score_pct!: number | null;
  rank_position!: number | null;
  active_enrollment_count!: number;
  awarded_category!: { /* ... */ } | null;
  composite_calculated_at!: string | null;

  static fromSectionRanking(row: any): SectionRankingResponseDto { /* ... */ return {} as any; }
}

// section-rankings.controller.ts
@Controller('section-rankings')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class SectionRankingsController {
  constructor(private readonly service: SectionRankingsService) {}

  // DYNAMIC con sub-route /members ANTES que root para no colisionar
  @Get('/:sectionId/members')
  @RequirePermissions('section_rankings:read_club','section_rankings:read_lf','section_rankings:read_global')
  async getMembers(
    @Param('sectionId', ParseIntPipe) sectionId: number,
    @Query('ecclesiastical_year_id', ParseIntPipe) yearId: number,
    @Req() req: any,
  ) {
    return this.service.getMembers(sectionId, yearId, req.user.scope);
  }

  @Get()
  @RequirePermissions('section_rankings:read_club','section_rankings:read_lf','section_rankings:read_global')
  async list(
    @Query('club_id') clubId?: string,
    @Query('ecclesiastical_year_id') yearId?: string,
    @Query('page') page = '1',
    @Query('limit') limit = '50',
    @Req() req: any,
  ) {
    return this.service.list({
      callerScope: req.user.scope,
      clubId: clubId ? parseInt(clubId, 10) : undefined,
      yearId: yearId ? parseInt(yearId, 10) : undefined,
      page: parseInt(page, 10),
      limit: parseInt(limit, 10),
    });
  }
}
```

- [x] **Step 4: Run tests, expect PASS**

- [x] **Step 5: Code review checkpoint** — orden de rutas: `/:sectionId/members` ANTES de `GET /` (en NestJS el orden de declaración no importa para rutas con prefijo distinto, pero declarativo es claro).

- [x] **Step 6: Commit**

```bash
git add sacdia-backend/src/rankings/section-rankings
git commit -m "feat(section-rankings): add controller + service + DTO

GET / list (paginated, RBAC scope-filtered)
GET /:sectionId/members drill-down (ParseIntPipe INTEGER)
"
```

---

### Task 14: Crear módulo `member-ranking-weights/` CRUD

**Files:**
- Create: `sacdia-backend/src/rankings/member-ranking-weights/member-ranking-weights.controller.ts`
- Create: `sacdia-backend/src/rankings/member-ranking-weights/member-ranking-weights.service.ts`
- Create: `sacdia-backend/src/rankings/member-ranking-weights/dto/{create,update,response}-weights.dto.ts`
- Test: `sacdia-backend/src/rankings/member-ranking-weights/member-ranking-weights.controller.spec.ts`

Mismo patrón que `ranking-weights` 8.4-C, pero con 3 columnas (no 4) y `ParseUUIDPipe` en `:id`.

- [x] **Step 1: Write failing test**

```typescript
describe('MemberRankingWeightsController', () => {
  it('POST sum=100 → 201 created', async () => { /* class=40, invest=40, camporee=20 */ });
  it('POST sum≠100 → 400 WEIGHTS_SUM_INVALID', async () => { /* 50+30+30=110 */ });
  it('POST negative weight → 400', async () => { /* -10 */ });
  it('POST duplicate (clubType+year) → 409 WEIGHTS_CONFLICT', async () => { });
  it('DELETE default global → 400 DEFAULT_WEIGHTS_NOT_DELETABLE', async () => { });
  it('GET /:id ParseUUIDPipe non-uuid → 400', async () => { });
  it('PATCH validates SUM=100', async () => { });
  it('GET / list returns default + overrides', async () => { });
});
```

- [x] **Step 2: Run test, expect FAIL**

- [x] **Step 3: Implement DTOs (zod o class-validator)**

```typescript
// create-weights.dto.ts
export class CreateMemberRankingWeightsDto {
  @IsOptional() @IsInt() club_type_id?: number | null;
  @IsOptional() @IsInt() ecclesiastical_year_id?: number | null;
  @IsNumber() @Min(0) @Max(100) class_pct!: number;
  @IsNumber() @Min(0) @Max(100) investiture_pct!: number;
  @IsNumber() @Min(0) @Max(100) camporee_pct!: number;
}
```

- [x] **Step 4: Implement service**

```typescript
@Injectable()
export class MemberRankingWeightsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreateMemberRankingWeightsDto) {
    const sum = dto.class_pct + dto.investiture_pct + dto.camporee_pct;
    if (sum !== 100) throw new BadRequestException({ code: 'WEIGHTS_SUM_INVALID', sum });

    try {
      return await this.prisma.enrollmentRankingWeight.create({
        data: { ...dto, is_default: false },
      });
    } catch (e: any) {
      if (e.code === 'P2002') throw new ConflictException({ code: 'WEIGHTS_CONFLICT' });
      throw e;
    }
  }

  async update(id: string, dto: UpdateMemberRankingWeightsDto) {
    const sum = dto.class_pct + dto.investiture_pct + dto.camporee_pct;
    if (sum !== 100) throw new BadRequestException({ code: 'WEIGHTS_SUM_INVALID', sum });
    return this.prisma.enrollmentRankingWeight.update({ where: { id }, data: dto });
  }

  async remove(id: string) {
    const row = await this.prisma.enrollmentRankingWeight.findUnique({ where: { id } });
    if (!row) throw new NotFoundException();
    if (row.is_default) throw new BadRequestException({ code: 'DEFAULT_WEIGHTS_NOT_DELETABLE' });
    await this.prisma.enrollmentRankingWeight.delete({ where: { id } });
  }

  list() { return this.prisma.enrollmentRankingWeight.findMany({ orderBy: { is_default: 'desc' } }); }
  findOne(id: string) { return this.prisma.enrollmentRankingWeight.findUnique({ where: { id } }); }
}
```

- [x] **Step 5: Implement controller**

```typescript
@Controller('member-ranking-weights')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class MemberRankingWeightsController {
  constructor(private readonly service: MemberRankingWeightsService) {}

  @Get()
  @RequirePermissions('member_ranking_weights:read')
  list() { return this.service.list(); }

  @Get('/:id')
  @RequirePermissions('member_ranking_weights:read')
  findOne(@Param('id', ParseUUIDPipe) id: string) { return this.service.findOne(id); }

  @Post()
  @RequirePermissions('member_ranking_weights:write')
  create(@Body() dto: CreateMemberRankingWeightsDto) { return this.service.create(dto); }

  @Patch('/:id')
  @RequirePermissions('member_ranking_weights:write')
  update(@Param('id', ParseUUIDPipe) id: string, @Body() dto: UpdateMemberRankingWeightsDto) {
    return this.service.update(id, dto);
  }

  @Delete('/:id')
  @RequirePermissions('member_ranking_weights:write')
  remove(@Param('id', ParseUUIDPipe) id: string) { return this.service.remove(id); }
}
```

- [x] **Step 6: Run tests, expect PASS**

- [x] **Step 7: Code review checkpoint** — `ParseUUIDPipe` en `:id` (PK es UUID). 3 columnas (NO `evidence_pct`).

- [x] **Step 8: Commit**

```bash
git add sacdia-backend/src/rankings/member-ranking-weights
git commit -m "$(cat <<'EOF'
feat(member-ranking-weights): add CRUD endpoints with SUM=100 validation

3 weight columns (class, investiture, camporee — NO evidence in Phase 1).
ParseUUIDPipe on :id (UUID PK). Default global row not deletable.
EOF
)"
```

---

### Task 15: Extend `award-categories` controller con filter `?scope=`

**Files:**
- Modify: `sacdia-backend/src/award-categories/award-categories.controller.ts`
- Modify: `sacdia-backend/src/award-categories/award-categories.service.ts`
- Modify: `sacdia-backend/src/award-categories/dto/{create,update}-award-category.dto.ts`
- Test: `sacdia-backend/src/award-categories/award-categories.controller.spec.ts`

- [x] **Step 1: Write failing test**

```typescript
describe('AwardCategoriesController — scope extension', () => {
  it('GET /?scope=club returns only club rows', async () => { /* ... */ });
  it('GET /?scope=member returns only member rows', async () => { /* ... */ });
  it('GET /?scope=invalid → 400', async () => { /* ... */ });
  it('POST scope=member required', async () => { /* ... */ });
  it('PATCH scope=club only by admin role', async () => { /* ... */ });
});
```

- [x] **Step 2: Run test, expect FAIL**

- [x] **Step 3: Implement extension**

```typescript
// dto extension
export class CreateAwardCategoryDto {
  // existing fields ...
  @IsIn(['club', 'section', 'member']) scope!: 'club' | 'section' | 'member';
}

// service.list update
list(filter?: { scope?: 'club' | 'section' | 'member'; is_legacy?: boolean }) {
  return this.prisma.award_categories.findMany({
    where: { ...(filter?.scope && { scope: filter.scope }), ...(filter?.is_legacy !== undefined && { is_legacy: filter.is_legacy }) },
    orderBy: { min_composite_pct: 'desc' },
  });
}

// controller
@Get()
list(
  @Query('scope') scope?: 'club' | 'section' | 'member',
  @Query('is_legacy') isLegacy?: string,
) {
  if (scope && !['club','section','member'].includes(scope)) {
    throw new BadRequestException({ code: 'INVALID_SCOPE' });
  }
  return this.service.list({ scope, is_legacy: isLegacy === 'true' });
}
```

- [x] **Step 4: Run tests, expect PASS**

- [x] **Step 5: Code review checkpoint** — scope enum coherente entre DB CHECK constraint, DTO `IsIn`, y query validation.

- [x] **Step 6: Commit**

```bash
git add sacdia-backend/src/award-categories
git commit -m "feat(award-categories): extend with polymorphic scope filter

GET /?scope=club|section|member filter.
POST/PATCH require valid scope enum.
"
```

---

### Task 16: E2E integration test — HTTP real contra `/member-rankings/` y `/section-rankings/`

**Files:**
- Create: `sacdia-backend/test/member-rankings.e2e-spec.ts`
- Create: `sacdia-backend/test/section-rankings.e2e-spec.ts`

> **CONTEXTO** (engram #1888): tests modulares (`Test.createTestingModule`) NO cargan ParseUUIDPipe/ParseIntPipe en orden real de rutas — saltean middleware order. SOLO `INestApplication` con HTTP real (supertest contra `request(app.getHttpServer())`) detecta bugs tipo 8.4-C donde `GET /` retornaba 400 BadRequest porque el pipe de `:id` se ejecutaba primero.

- [x] **Step 1: Write failing e2e test (`member-rankings.e2e-spec.ts`)**

```typescript
import { Test } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';

describe('MemberRankings (e2e — HTTP real)', () => {
  let app: INestApplication;
  let memberToken: string;
  let directorToken: string;

  beforeAll(async () => {
    const m = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = m.createNestApplication();
    await app.init();
    // Login fixtures: obtener tokens via /auth/sign-in
    memberToken = await loginAs('member-test@sacdia.com', 'Sacdia2026!');
    directorToken = await loginAs('director@sacdia.com', 'Sacdia2026!');
  });

  afterAll(() => app.close());

  it('GET /api/v1/member-rankings — list returns 200 (not 400 BadRequest)', () =>
    request(app.getHttpServer())
      .get('/api/v1/member-rankings')
      .set('Authorization', `Bearer ${directorToken}`)
      .expect(200));

  it('GET /api/v1/member-rankings/me — visibility=hidden returns 403', async () => {
    // setSystemConfig('member_ranking.member_visibility', 'hidden');
    return request(app.getHttpServer())
      .get('/api/v1/member-rankings/me')
      .set('Authorization', `Bearer ${memberToken}`)
      .expect(403)
      .expect(res => expect(res.body.code).toBe('MEMBER_RANKING_HIDDEN'));
  });

  it('GET /api/v1/member-rankings/me — visibility=self_only returns 200', async () => {
    // setSystemConfig('member_ranking.member_visibility', 'self_only');
    return request(app.getHttpServer())
      .get('/api/v1/member-rankings/me')
      .set('Authorization', `Bearer ${memberToken}`)
      .expect(200);
  });

  it('GET /api/v1/member-rankings/123/breakdown — ParseIntPipe accepts integer', () =>
    request(app.getHttpServer())
      .get('/api/v1/member-rankings/123/breakdown?ecclesiastical_year_id=1')
      .set('Authorization', `Bearer ${directorToken}`)
      .expect((res) => expect([200, 404]).toContain(res.status))); // 404 si no existe; 200 si existe

  it('GET /api/v1/member-rankings/abc/breakdown — non-int → 400', () =>
    request(app.getHttpServer())
      .get('/api/v1/member-rankings/abc/breakdown')
      .set('Authorization', `Bearer ${directorToken}`)
      .expect(400));

  it('POST /api/v1/member-rankings/recalculate kill-switch off → 400', async () => {
    // setSystemConfig('member_ranking.recalculation_enabled', 'false');
    return request(app.getHttpServer())
      .post('/api/v1/member-rankings/recalculate')
      .set('Authorization', `Bearer ${directorToken}`)
      .send({ ecclesiastical_year_id: 1 })
      .expect(400)
      .expect(res => expect(res.body.code).toBe('RECALCULATION_DISABLED'));
  });
});
```

- [x] **Step 2: Write failing e2e test (`section-rankings.e2e-spec.ts`)**

```typescript
describe('SectionRankings (e2e — HTTP real)', () => {
  let app: INestApplication;

  beforeAll(/* ... */);

  it('GET /api/v1/section-rankings — list 200', () =>
    request(app.getHttpServer())
      .get('/api/v1/section-rankings')
      .set('Authorization', `Bearer ${directorToken}`)
      .expect(200));

  it('GET /api/v1/section-rankings/1/members — ParseIntPipe', () =>
    request(app.getHttpServer())
      .get('/api/v1/section-rankings/1/members?ecclesiastical_year_id=1')
      .set('Authorization', `Bearer ${directorToken}`)
      .expect((res) => expect([200, 404]).toContain(res.status)));

  it('GET /api/v1/section-rankings/abc/members — 400', () =>
    request(app.getHttpServer())
      .get('/api/v1/section-rankings/abc/members')
      .set('Authorization', `Bearer ${directorToken}`)
      .expect(400));
});
```

- [x] **Step 3: Run e2e tests, expect FAIL si hay route order bug**

```bash
cd sacdia-backend
pnpm test:e2e member-rankings.e2e-spec.ts section-rankings.e2e-spec.ts
```

- [x] **Step 4: Si fallan, AJUSTAR orden de rutas en controllers** (Tasks 11–12 ya aplican el patrón correcto, pero verificar).

- [x] **Step 5: Run e2e tests, expect PASS**

- [x] **Step 6: Code review checkpoint** — engram #1888 gap closed. NingunA ruta estática colisionando con dinámica.

- [x] **Step 7: Commit**

```bash
git add sacdia-backend/test/{member-rankings,section-rankings}.e2e-spec.ts
git commit -m "$(cat <<'EOF'
test(rankings): add e2e specs for member-rankings and section-rankings

Closes the gap from 8.4-C (engram #1888) where modular tests didn't
detect ParseIntPipe order bugs on dynamic routes. Tests run real
HTTP requests via supertest against INestApplication.
EOF
)"
```

---

## Phase 5 — Admin web UI Fase 1 (sacdia-admin)

> Cada page: shadcn/ui new-york, Tailwind v4 con tokens semánticos (bg-primary/10, text-muted-foreground, NO bg-blue-50 hardcoded), lucide-react icons. Reference: `sacdia-admin/DESIGN-SYSTEM.md`. CRUD create/edit = Dialog modal; delete = AlertDialog confirmation.

### Task 17: `/dashboard/member-rankings` page (table + filters)

**Files:**
- Create: `sacdia-admin/src/app/dashboard/member-rankings/page.tsx`
- Create: `sacdia-admin/src/app/dashboard/member-rankings/_components/member-rankings-table.tsx`
- Create: `sacdia-admin/src/app/dashboard/member-rankings/_components/member-ranking-score-badge.tsx`
- Create: `sacdia-admin/src/app/dashboard/member-rankings/_components/member-rankings-filters.tsx`
- Create: `sacdia-admin/src/lib/api/member-rankings.ts`

- [x] **Step 1: Implement API client `member-rankings.ts`**

```typescript
import { api } from './client';

export interface MemberRankingResponse {
  enrollment_id: number;
  user_id: string;
  member_name: string;
  club_section_id: number | null;
  section_name: string | null;
  class_score_pct: number | null;
  investiture_score_pct: number | null;
  camporee_score_pct: number | null;
  composite_score_pct: number | null;
  rank_position: number | null;
  awarded_category: { id: string; name: string; color: string; min_pct: number; max_pct: number } | null;
  composite_calculated_at: string | null;
}

export async function listMemberRankings(params: {
  club_id?: number; section_id?: number; ecclesiastical_year_id?: number;
  page?: number; limit?: number;
}): Promise<{ data: MemberRankingResponse[]; total: number; page: number; limit: number }> {
  return api.get('/api/v1/member-rankings', { params });
}

export async function getMemberBreakdown(enrollmentId: number, yearId: number) {
  return api.get(`/api/v1/member-rankings/${enrollmentId}/breakdown`, {
    params: { ecclesiastical_year_id: yearId },
  });
}
```

- [x] **Step 2: Implement `MemberRankingScoreBadge`** (reusable, similar a `RankingScoreBadge` 8.4-C)

```tsx
import { Badge } from '@/components/ui/badge';

const cutoff = (pct: number | null): 'success' | 'warning' | 'destructive' | 'outline' => {
  if (pct === null) return 'outline';
  if (pct >= 85) return 'success';
  if (pct >= 65) return 'warning';
  return 'destructive';
};

export function MemberRankingScoreBadge({ value }: { value: number | null }) {
  return (
    <Badge variant={cutoff(value)}>
      {value === null ? '—' : `${value.toFixed(2)}%`}
    </Badge>
  );
}
```

- [x] **Step 3: Implement table component (shadcn DataTable + TanStack Query)**

```tsx
'use client';
import { useQuery } from '@tanstack/react-query';
import Link from 'next/link';
import { listMemberRankings, MemberRankingResponse } from '@/lib/api/member-rankings';
import { MemberRankingScoreBadge } from './member-ranking-score-badge';

export function MemberRankingsTable({ filters }: { filters: any }) {
  const { data, isLoading } = useQuery({
    queryKey: ['member-rankings', filters],
    queryFn: () => listMemberRankings(filters),
  });

  if (isLoading) return <Skeleton />;
  if (!data || data.data.length === 0) return <EmptyState />;

  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>#</TableHead>
          <TableHead>Miembro</TableHead>
          <TableHead>Sección</TableHead>
          <TableHead>Composite</TableHead>
          <TableHead>Clase</TableHead>
          <TableHead>Investidura</TableHead>
          <TableHead>Camporees</TableHead>
          <TableHead>Categoría</TableHead>
          <TableHead></TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {data.data.map((row: MemberRankingResponse) => (
          <TableRow key={row.enrollment_id}>
            <TableCell>{row.rank_position ?? '—'}</TableCell>
            <TableCell>{row.member_name}</TableCell>
            <TableCell>{row.section_name ?? '—'}</TableCell>
            <TableCell><MemberRankingScoreBadge value={row.composite_score_pct} /></TableCell>
            <TableCell>{row.class_score_pct?.toFixed(2) ?? '—'}</TableCell>
            <TableCell>{row.investiture_score_pct === 100 ? 'Investido' : row.investiture_score_pct === 0 ? 'En progreso' : '—'}</TableCell>
            <TableCell>{row.camporee_score_pct?.toFixed(2) ?? '—'}</TableCell>
            <TableCell>{row.awarded_category ? <Badge style={{ backgroundColor: row.awarded_category.color }}>{row.awarded_category.name}</Badge> : '—'}</TableCell>
            <TableCell>
              <Link href={`/dashboard/member-rankings/${row.enrollment_id}/breakdown`}>
                <Button variant="ghost" size="sm">Ver detalle</Button>
              </Link>
            </TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  );
}
```

- [x] **Step 4: Implement page `/dashboard/member-rankings/page.tsx`** (SSR + client filters)

```tsx
import { MemberRankingsTable } from './_components/member-rankings-table';
import { MemberRankingsFilters } from './_components/member-rankings-filters';

export default function MemberRankingsPage() {
  return (
    <div className="space-y-6 p-6">
      <header className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold">Ranking de miembros</h1>
        <Button onClick={triggerRecalculate}>Recalcular</Button>
      </header>
      <MemberRankingsFilters />
      <MemberRankingsTable filters={/* read from URL search params */ {}} />
    </div>
  );
}
```

- [x] **Step 5: Code review checkpoint** — design system check (shadcn variants, no hardcoded Tailwind colors).

- [x] **Step 6: Commit**

```bash
cd sacdia-admin
git add src/app/dashboard/member-rankings src/lib/api/member-rankings.ts
git commit -m "feat(member-rankings): add admin dashboard page with table + filters

Uses MemberRankingScoreBadge (cutoffs ≥85 success, ≥65 warning, <65 destructive).
3 score columns + composite + awarded category. Client-side filters via search params.
"
```

---

### Task 18: `/dashboard/member-rankings/[enrollmentId]/breakdown` drill-down

**Files:**
- Create: `sacdia-admin/src/app/dashboard/member-rankings/[enrollmentId]/breakdown/page.tsx`
- Create: `sacdia-admin/src/app/dashboard/member-rankings/[enrollmentId]/breakdown/_components/member-breakdown-card.tsx`

- [x] **Step 1: Implement reusable `MemberBreakdownCard`**

```tsx
type Signal = 'class' | 'investiture' | 'camporee';

interface BreakdownData {
  class?: { completed_count: number; required_count: number; percentage: number | null };
  investiture?: { investiture_status: 'INVESTIDO' | 'IN_PROGRESS' | null; score: 100 | 0 | null };
  camporee?: { participated_count: number; total_camporees: number; percentage: number | null };
}

export function MemberBreakdownCard({ signal, data, weight }: {
  signal: Signal; data: BreakdownData[Signal]; weight: number;
}) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>{labels[signal]}</CardTitle>
        <CardDescription>Peso aplicado: {weight}%</CardDescription>
      </CardHeader>
      <CardContent>
        {signal === 'class' && /* render class breakdown */}
        {signal === 'investiture' && /* render INVESTIDO/IN_PROGRESS badge */}
        {signal === 'camporee' && /* render camporee breakdown */}
      </CardContent>
    </Card>
  );
}
```

- [x] **Step 2: Implement page con header + 3 cards + weights aplicados + recalc button**

```tsx
'use client';
import { useQuery } from '@tanstack/react-query';
import { useParams } from 'next/navigation';
import { getMemberBreakdown } from '@/lib/api/member-rankings';

export default function MemberBreakdownPage() {
  const { enrollmentId } = useParams();
  const { data } = useQuery({
    queryKey: ['member-breakdown', enrollmentId],
    queryFn: () => getMemberBreakdown(Number(enrollmentId), getActiveYear()),
  });
  if (!data) return <Skeleton />;

  return (
    <div className="space-y-6 p-6">
      <BreakdownHeader data={data} />
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <MemberBreakdownCard signal="class" data={data.class_breakdown} weight={data.weights_applied.class_pct} />
        <MemberBreakdownCard signal="investiture" data={data.investiture_breakdown} weight={data.weights_applied.investiture_pct} />
        <MemberBreakdownCard signal="camporee" data={data.camporee_breakdown} weight={data.weights_applied.camporee_pct} />
      </div>
      <WeightsAppliedSection weights={data.weights_applied} />
      <LastUpdatedSection composite_calculated_at={data.composite_calculated_at} />
    </div>
  );
}
```

- [x] **Step 3: Code review checkpoint** — verifica investiture muestra status badge + score binario claro.

- [x] **Step 4: Commit**

```bash
git add sacdia-admin/src/app/dashboard/member-rankings/[enrollmentId]
git commit -m "feat(member-rankings): add breakdown drill-down page with 3 score cards"
```

---

### Task 19: `/dashboard/section-rankings` page

**Files:**
- Create: `sacdia-admin/src/app/dashboard/section-rankings/page.tsx`
- Create: `sacdia-admin/src/app/dashboard/section-rankings/_components/section-rankings-table.tsx`
- Create: `sacdia-admin/src/app/dashboard/section-rankings/[sectionId]/members/page.tsx`
- Create: `sacdia-admin/src/lib/api/section-rankings.ts`

- [x] **Step 1: Implement API client + table** (similar pattern Task 17)

```typescript
export interface SectionRankingResponse {
  club_section_id: number;
  section_name: string;
  composite_score_pct: number | null;
  rank_position: number | null;
  active_enrollment_count: number;
  awarded_category: any | null;
  composite_calculated_at: string | null;
}

export async function listSectionRankings(params: {
  club_id?: number; ecclesiastical_year_id?: number; page?: number; limit?: number;
}) {
  return api.get('/api/v1/section-rankings', { params });
}

export async function getSectionMembers(sectionId: number, yearId: number) {
  return api.get(`/api/v1/section-rankings/${sectionId}/members`, {
    params: { ecclesiastical_year_id: yearId },
  });
}
```

- [x] **Step 2: Implement table page**

```tsx
export default function SectionRankingsPage() {
  return (
    <div className="space-y-6 p-6">
      <h1 className="text-2xl font-semibold">Ranking de secciones</h1>
      <SectionRankingsTable />
    </div>
  );
}
```

- [x] **Step 3: Implement drill-down `/section-rankings/[sectionId]/members/page.tsx`**

```tsx
export default function SectionMembersPage() {
  const { sectionId } = useParams();
  const { data } = useQuery({
    queryKey: ['section-members', sectionId],
    queryFn: () => getSectionMembers(Number(sectionId), getActiveYear()),
  });
  return (
    <div className="space-y-6 p-6">
      <SectionHeader section={data?.section} />
      <MembersTable members={data?.members ?? []} />
    </div>
  );
}
```

- [x] **Step 4: Code review checkpoint**

- [x] **Step 5: Commit**

```bash
git add sacdia-admin/src/app/dashboard/section-rankings src/lib/api/section-rankings.ts
git commit -m "feat(section-rankings): add admin pages list + drill-down to members"
```

---

### Task 20: `/dashboard/member-ranking-weights` CRUD page

**Files:**
- Create: `sacdia-admin/src/app/dashboard/member-ranking-weights/page.tsx`
- Create: `sacdia-admin/src/app/dashboard/member-ranking-weights/_components/weights-form-dialog.tsx`
- Create: `sacdia-admin/src/app/dashboard/member-ranking-weights/_components/weights-table.tsx`
- Create: `sacdia-admin/src/lib/api/member-ranking-weights.ts`

- [x] **Step 1: API client**

```typescript
export interface MemberRankingWeights {
  id: string;
  club_type_id: number | null;
  ecclesiastical_year_id: number | null;
  class_pct: number;
  investiture_pct: number;
  camporee_pct: number;
  is_default: boolean;
}

export const listWeights = () => api.get('/api/v1/member-ranking-weights');
export const createWeights = (dto: any) => api.post('/api/v1/member-ranking-weights', dto);
export const updateWeights = (id: string, dto: any) => api.patch(`/api/v1/member-ranking-weights/${id}`, dto);
export const deleteWeights = (id: string) => api.delete(`/api/v1/member-ranking-weights/${id}`);
```

- [x] **Step 2: Implement reusable `<WeightSumIndicator>` (o reuse de 8.4-C si disponible)**

```tsx
export function WeightSumIndicator({ values }: { values: number[] }) {
  const sum = values.reduce((a, b) => a + b, 0);
  const isValid = sum === 100;
  return (
    <Badge variant={isValid ? 'success' : 'destructive'}>
      Suma: {sum}% {isValid ? '✓' : '✗ debe ser 100'}
    </Badge>
  );
}
```

- [x] **Step 3: Implement form dialog (shadcn Dialog + react-hook-form + zod)**

```tsx
const schema = z.object({
  club_type_id: z.number().int().nullable(),
  ecclesiastical_year_id: z.number().int().nullable(),
  class_pct: z.number().min(0).max(100),
  investiture_pct: z.number().min(0).max(100),
  camporee_pct: z.number().min(0).max(100),
}).refine(d => d.class_pct + d.investiture_pct + d.camporee_pct === 100, {
  message: 'La suma debe ser 100',
});

export function WeightsFormDialog({ open, onOpenChange, initial, onSubmit }: any) {
  const form = useForm({ resolver: zodResolver(schema), defaultValues: initial });
  const watched = form.watch(['class_pct', 'investiture_pct', 'camporee_pct']);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader><DialogTitle>{initial ? 'Editar' : 'Crear'} override</DialogTitle></DialogHeader>
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            {/* Inputs class/investiture/camporee + selects clubType+year */}
            <WeightSumIndicator values={watched.map(Number)} />
            <Button type="submit" disabled={watched.reduce((a, b) => Number(a) + Number(b), 0) !== 100}>
              Guardar
            </Button>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  );
}
```

- [x] **Step 4: Implement table page con dialogs CREATE/EDIT y AlertDialog DELETE**

```tsx
export default function WeightsPage() {
  const [openDialog, setOpenDialog] = useState(false);
  const [editing, setEditing] = useState(null);
  const { data } = useQuery({ queryKey: ['weights'], queryFn: listWeights });

  const defaultRow = data?.find((r: any) => r.is_default);
  const overrides = data?.filter((r: any) => !r.is_default) ?? [];

  return (
    <div className="space-y-6 p-6">
      <h1 className="text-2xl font-semibold">Pesos de ranking de miembros</h1>

      <Card>
        <CardHeader><CardTitle>Default global</CardTitle></CardHeader>
        <CardContent>
          {defaultRow && (
            <>
              <div className="grid grid-cols-3 gap-4">
                <div>Clase: {defaultRow.class_pct}%</div>
                <div>Investidura: {defaultRow.investiture_pct}%</div>
                <div>Camporees: {defaultRow.camporee_pct}%</div>
              </div>
              <Button onClick={() => { setEditing(defaultRow); setOpenDialog(true); }}>Editar</Button>
            </>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Overrides por tipo + año</CardTitle>
          <Button onClick={() => { setEditing(null); setOpenDialog(true); }}>Agregar override</Button>
        </CardHeader>
        <CardContent>
          <Table>
            {/* render overrides rows con DELETE AlertDialog */}
          </Table>
        </CardContent>
      </Card>

      <WeightsFormDialog open={openDialog} onOpenChange={setOpenDialog} initial={editing} onSubmit={/* ... */ () => {}} />
    </div>
  );
}
```

- [x] **Step 5: Code review checkpoint** — 3 weights only (NO `evidence_pct`). DELETE de default → AlertDialog warning.

- [x] **Step 6: Commit**

```bash
git add sacdia-admin/src/app/dashboard/member-ranking-weights src/lib/api/member-ranking-weights.ts
git commit -m "$(cat <<'EOF'
feat(member-ranking-weights): add admin CRUD page with WeightSumIndicator

Default global readonly card + overrides table.
Form validates sum=100 client-side via WeightSumIndicator.
3 weights only (class, investiture, camporee — NO evidence in Phase 1).
Dialog for create/edit, AlertDialog for delete.
EOF
)"
```

---

### Task 21: Extend `/dashboard/award-categories` con tabs scope (Club | Section | Member)

**Files:**
- Modify: `sacdia-admin/src/app/dashboard/award-categories/page.tsx`
- Modify: `sacdia-admin/src/app/dashboard/award-categories/_components/categories-table.tsx`
- Modify: `sacdia-admin/src/app/dashboard/award-categories/_components/category-form-dialog.tsx`
- Modify: `sacdia-admin/src/lib/api/award-categories.ts`

- [x] **Step 1: Update API client**

```typescript
export const listCategories = (params: { scope?: 'club'|'section'|'member'; is_legacy?: boolean }) =>
  api.get('/api/v1/award-categories', { params });
```

- [x] **Step 2: Add scope tabs (Tabs primitive de shadcn)**

```tsx
'use client';
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs';

export default function AwardCategoriesPage() {
  const [scope, setScope] = useState<'club'|'section'|'member'>('club');
  const [showLegacy, setShowLegacy] = useState(false);

  return (
    <div className="space-y-6 p-6">
      <header><h1 className="text-2xl">Categorías de premios</h1></header>
      <Tabs value={scope} onValueChange={(v: any) => setScope(v)}>
        <TabsList>
          <TabsTrigger value="club">Club</TabsTrigger>
          <TabsTrigger value="section">Sección</TabsTrigger>
          <TabsTrigger value="member">Miembro</TabsTrigger>
        </TabsList>
        <TabsContent value={scope}>
          <Tabs defaultValue="active">
            <TabsList>
              <TabsTrigger value="active">Active</TabsTrigger>
              <TabsTrigger value="legacy">Legacy</TabsTrigger>
            </TabsList>
            <TabsContent value="active"><CategoriesTable scope={scope} legacy={false} /></TabsContent>
            <TabsContent value="legacy"><CategoriesTable scope={scope} legacy={true} /></TabsContent>
          </Tabs>
        </TabsContent>
      </Tabs>
    </div>
  );
}
```

- [x] **Step 3: Update form dialog con field `scope`**

```tsx
<Select name="scope" required>
  <SelectTrigger><SelectValue placeholder="Scope" /></SelectTrigger>
  <SelectContent>
    <SelectItem value="club">Club</SelectItem>
    <SelectItem value="section">Sección</SelectItem>
    <SelectItem value="member">Miembro</SelectItem>
  </SelectContent>
</Select>
```

- [x] **Step 4: Code review checkpoint** — todas las categorías existentes mantienen `scope='club'` (backfill de migration).

- [x] **Step 5: Commit**

```bash
git add sacdia-admin/src/app/dashboard/award-categories src/lib/api/award-categories.ts
git commit -m "feat(award-categories): extend admin page with scope tabs (Club|Section|Member)"
```

---

## Phase 6 — Documentation update (root sacdia)

### Task 22: Update canon docs + API live reference + schema reference + features registry

**Files:**
- Modify: `docs/canon/runtime-rankings.md` (agregar §14)
- Modify: `docs/canon/decisiones-clave.md` (agregar §23)
- Modify: `docs/api/ENDPOINTS-LIVE-REFERENCE.md` (340 → ~350 endpoints)
- Modify: `docs/database/SCHEMA-REFERENCE.md` (agregar 3 tablas + extensión `award_categories`)
- Modify: `docs/features/README.md` (status 8.4-A: shipped)

- [x] **Step 1: `runtime-rankings.md` §14 — Enrollment + Section Rankings**

Agregar al final de §13:

```markdown
## §14. 8.4-A Enrollment + Section Rankings (post-audit shipped)

**Estado**: shipped 2026-04-29
**Spec**: `docs/superpowers/specs/2026-04-29-clasificacion-seccion-miembro-design.md`
**Audit**: `docs/superpowers/audits/2026-04-29-section-member-schema-audit.md`

### Tablas
- `enrollment_rankings` (UUID PK, `enrollment_id INTEGER`, `user_id UUID`, `club_section_id INTEGER`, `composite_score_pct NUMERIC(5,2)`)
- `section_rankings` (UUID PK, `club_section_id INTEGER`)
- `enrollment_ranking_weights` (UUID PK, 3 columnas: class_pct + investiture_pct + camporee_pct = 100)

### Hybrid naming convention (MEMORIZAR)
- Schema interno: `enrollment_rankings`, `enrollment_id`, `enrollment_ranking_weights`
- API/UI/permissions/system_config keys externos: `member-rankings`, `member_rankings:*`, `member_ranking.*`

### Cron
Job `0 2 * * *` UTC ejecuta: club → enrollment → section. Kill-switches independientes:
- `ranking.recalculation_enabled` (global)
- `member_ranking.recalculation_enabled` (8.4-A only)

### Calculadores Fase 1 (3 señales)
- `ClassScoreService` → `class_module_progress`
- `InvestitureScoreService` → `enrollments.investiture_status` (binario)
- `CamporeeScoreService` → `camporee_members` (per-user)

### Composite (NULL redistribution)
Si una señal es NULL, su peso se redistribuye proporcionalmente. Si todas NULL → composite NULL.

### Sección como agregado puro
`section_rankings.composite = AVG(enrollment_rankings.composite WHERE NOT NULL)`. NO calculadores propios.
```

- [x] **Step 2: `decisiones-clave.md` §23**

```markdown
## §23. 8.4-A: naming híbrido + 3 señales + audit-locked schema (2026-04-29)

**Decisión**: Schema interno usa la entidad real (`enrollments`, `enrollment_rankings`, `enrollment_id`). API/UI/permissions/system_config externos usan `member-*` (orientado al usuario final). Capa de mapeo en DTOs (`MemberRankingResponseDto.fromEnrollmentRanking`).

**Decisión**: Fase 1 = 3 señales (clases, investidura binaria, camporees). Evidencias bloqueadas (audit A5: tabla per-member no existe).

**Decisión**: Investidura es señal binaria (INVESTIDO=100, IN_PROGRESS=0, sin enrollment=NULL). No requisitos discretos en Fase 1 (audit A11: tabla no existe).

**Audit reference**: commit `643b694`. 11 ítems verificados; 8 desviaciones del spec original.
```

- [x] **Step 3: `ENDPOINTS-LIVE-REFERENCE.md` agregar 4 grupos**

```markdown
## /api/v1/member-rankings (Phase 8.4-A)
- GET /                        — list paginated, RBAC scope-filtered
- GET /me                      — own ranking (visibility-gated)
- GET /:enrollmentId/breakdown — drill-down (ParseIntPipe — INTEGER)
- POST /recalculate            — trigger manual recalc (kill-switch validated)

## /api/v1/section-rankings (Phase 8.4-A)
- GET /                       — list paginated
- GET /:sectionId/members     — drill-down (ParseIntPipe)

## /api/v1/member-ranking-weights (Phase 8.4-A)
- GET /                       — list default + overrides
- GET /:id                    — detail (ParseUUIDPipe)
- POST /                      — create override (validates sum=100)
- PATCH /:id                  — update (validates sum=100)
- DELETE /:id                 — delete (default not deletable)

## /api/v1/award-categories (extension Phase 8.4-A)
- GET /?scope=club|section|member — filter by polymorphic scope
- POST/PATCH require valid scope enum
```

Total: 340 (8.4-C) + 11 nuevos = 351 endpoints.

- [x] **Step 4: `SCHEMA-REFERENCE.md` agregar 3 tablas + extensión**

Documentar columnas, FKs, indexes, CHECK constraints, naming híbrido (schema en español como en resto del documento si aplica).

- [x] **Step 5: `features/README.md` — actualizar 8.4-A status**

Cambiar de `planning` → `shipped 2026-04-29`. Linkear spec, audit, plan, runtime canon §14.

- [x] **Step 6: Code review checkpoint** — quality-reviewer subagent: ¿hybrid naming explícitamente documentado? ¿endpoints count correcto?

- [x] **Step 7: Commit (root sacdia repo)**

```bash
cd /Users/abner/Documents/development/sacdia
git add docs/canon/runtime-rankings.md docs/canon/decisiones-clave.md \
        docs/api/ENDPOINTS-LIVE-REFERENCE.md docs/database/SCHEMA-REFERENCE.md \
        docs/features/README.md
git commit -m "$(cat <<'EOF'
docs(canon): document 8.4-A enrollment+section rankings as shipped

Updates runtime-rankings.md §14 with cron pipeline, calculators, and
NULL redistribution composite. Adds decision §23 to decisiones-clave.md
documenting the hybrid naming convention (schema enrollment_*, API
member_*) and the audit-locked schema reality. Endpoints live reference
extended with 4 new endpoint groups (340 → 351). Schema reference
documents 3 new tables and award_categories.scope polymorphism.
EOF
)"
```

---

## Phase 7 — Smoke E2E + manual validation (post-merge)

### Task 23: Smoke E2E manual contra dev environment

**Setup**: backend + admin desplegados en dev (Neon dev branch). Tests creds: `admin@sacdia.com / Sacdia2026!` (super_admin) y `director@sacdia.com / Sacdia2026!` (director-club ACV/GM).

- [x] **Step 1: Pre-condiciones**

```sql
-- Verificar kill-switch ON
SELECT config_value FROM system_config WHERE config_key = 'member_ranking.recalculation_enabled';
-- expected: 'true'

-- Verificar default weights
SELECT class_pct, investiture_pct, camporee_pct FROM enrollment_ranking_weights WHERE is_default = true;
-- expected: (50, 30, 20)
```

- [x] **Step 2: Trigger manual recalc**

```bash
curl -X POST 'https://api-dev.sacdia.com/api/v1/member-rankings/recalculate' \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"ecclesiastical_year_id": <activeYearId>}'
# expected: 200/201 { "triggered": true, ... }
```

- [x] **Step 3: Verificar `enrollment_rankings` populated**

```sql
SELECT count(*) FROM enrollment_rankings WHERE ecclesiastical_year_id = <activeYearId>;
-- expected: > 0 (= número de enrollments con scores calculables)

SELECT enrollment_id, composite_score_pct, rank_position
  FROM enrollment_rankings
  WHERE ecclesiastical_year_id = <activeYearId>
  ORDER BY rank_position
  LIMIT 10;
-- expected: ranks empezando en 1 (DENSE_RANK), composite NUMERIC entre 0 y 100, NULLs al final
```

- [x] **Step 4: Verificar `section_rankings` populated**

```sql
SELECT count(*) FROM section_rankings WHERE ecclesiastical_year_id = <activeYearId>;

-- AVG validation manual: pick a section con ≥2 enrollments
SELECT
  sr.composite_score_pct AS section_avg,
  AVG(er.composite_score_pct) AS manual_avg,
  count(er.id) AS member_count
FROM section_rankings sr
LEFT JOIN enrollment_rankings er ON
  er.club_section_id = sr.club_section_id AND
  er.ecclesiastical_year_id = sr.ecclesiastical_year_id AND
  er.composite_score_pct IS NOT NULL
WHERE sr.ecclesiastical_year_id = <activeYearId>
GROUP BY sr.id, sr.composite_score_pct
LIMIT 5;
-- expected: section_avg ≈ manual_avg (idénticos al 0.01)
```

- [x] **Step 5: RBAC negative tests**

```bash
# member viendo otro enrollment → 403
curl -X GET 'https://api-dev.sacdia.com/api/v1/member-rankings/<otherEnrollmentId>/breakdown?ecclesiastical_year_id=<y>' \
  -H "Authorization: Bearer $MEMBER_TOKEN"
# expected: 403

# director-club viendo otro club → 403
# (requiere member que pertenezca a club distinto al del director)

# director-lf en su scope → 200
```

- [x] **Step 6: Visibility flag tests**

```sql
UPDATE system_config SET config_value = 'hidden' WHERE config_key = 'member_ranking.member_visibility';
```

```bash
curl -X GET 'https://api-dev.sacdia.com/api/v1/member-rankings/me' \
  -H "Authorization: Bearer $MEMBER_TOKEN"
# expected: 403 MEMBER_RANKING_HIDDEN
```

```sql
UPDATE system_config SET config_value = 'self_and_top_n' WHERE config_key = 'member_ranking.member_visibility';
```

```bash
curl -X GET 'https://api-dev.sacdia.com/api/v1/member-rankings/me' \
  -H "Authorization: Bearer $MEMBER_TOKEN"
# expected: 200 + body.top_n: array de N elementos
```

```sql
-- Restore default
UPDATE system_config SET config_value = 'self_only' WHERE config_key = 'member_ranking.member_visibility';
```

- [ ] **Step 7: Code review checkpoint** — todos los smoke pasan. Documentar resultados en engram con `mem_save` (topic `sdd/8-4-a/smoke-results`).

- [ ] **Step 8: No commit (smoke ops, no source change)**

---

## Phase 8 — Mobile Flutter UI Fase 2 (sacdia-app, OPTIONAL separate wave)

> **NOTA**: Phase 8 es opcional y puede liberarse como wave separada después de validar Fase 1 admin web. Backend ya soporta endpoints `/me` con visibility-gating; aquí se construye la superficie móvil.

### Task 24: Flutter repository + provider para member_rankings + section_rankings

**Files:**
- Create: `sacdia-app/lib/features/rankings/data/models/member_ranking_dto.dart`
- Create: `sacdia-app/lib/features/rankings/data/models/section_ranking_dto.dart`
- Create: `sacdia-app/lib/features/rankings/data/repositories/member_rankings_repository.dart`
- Create: `sacdia-app/lib/features/rankings/data/repositories/member_rankings_remote_repository.dart`
- Create: `sacdia-app/lib/features/rankings/presentation/providers/my_ranking_provider.dart`
- Create: `sacdia-app/lib/features/rankings/presentation/providers/section_ranking_provider.dart`
- Test: `sacdia-app/test/features/rankings/data/repositories/member_rankings_remote_repository_test.dart`

- [x] **Step 1: Implement DTOs (using freezed o simple classes con fromJson)**

```dart
class MemberRankingDto {
  final int enrollmentId;
  final String userId;
  final String memberName;
  final int? clubSectionId;
  final String? sectionName;
  final double? classScorePct;
  final double? investitureScorePct;
  final double? camporeeScorePct;
  final double? compositeScorePct;
  final int? rankPosition;
  final AwardCategoryDto? awardedCategory;
  final DateTime? compositeCalculatedAt;

  MemberRankingDto({/* ... */});

  factory MemberRankingDto.fromJson(Map<String, dynamic> json) => MemberRankingDto(
    enrollmentId: json['enrollment_id'],
    userId: json['user_id'],
    memberName: json['member_name'],
    clubSectionId: json['club_section_id'],
    sectionName: json['section_name'],
    classScorePct: (json['class_score_pct'] as num?)?.toDouble(),
    investitureScorePct: (json['investiture_score_pct'] as num?)?.toDouble(),
    camporeeScorePct: (json['camporee_score_pct'] as num?)?.toDouble(),
    compositeScorePct: (json['composite_score_pct'] as num?)?.toDouble(),
    rankPosition: json['rank_position'],
    awardedCategory: json['awarded_category'] != null
      ? AwardCategoryDto.fromJson(json['awarded_category'])
      : null,
    compositeCalculatedAt: json['composite_calculated_at'] != null
      ? DateTime.parse(json['composite_calculated_at'])
      : null,
  );
}

class MemberMyRankingDto {
  final MemberRankingDto member;
  final String visibilityMode; // 'self_only' | 'self_and_top_n' | 'hidden'
  final List<TopNEntryDto>? topN;
  // factory fromJson ...
}
```

- [x] **Step 2: Implement repository abstract + remote impl**

```dart
abstract class MemberRankingsRepository {
  Future<MemberMyRankingDto?> getMyRanking();
  Future<List<MemberRankingDto>> getSectionMembers(int sectionId, int yearId);
}

class MemberRankingsRemoteRepository implements MemberRankingsRepository {
  final ApiClient client;
  MemberRankingsRemoteRepository(this.client);

  @override
  Future<MemberMyRankingDto?> getMyRanking() async {
    try {
      final res = await client.get('/api/v1/member-rankings/me');
      return MemberMyRankingDto.fromJson(res);
    } on ForbiddenException {
      return null; // visibility=hidden → UI muestra empty state
    }
  }

  @override
  Future<List<MemberRankingDto>> getSectionMembers(int sectionId, int yearId) async {
    final res = await client.get(
      '/api/v1/section-rankings/$sectionId/members',
      queryParameters: {'ecclesiastical_year_id': yearId},
    );
    return (res['members'] as List).map((m) => MemberRankingDto.fromJson(m)).toList();
  }
}
```

- [x] **Step 3: Implement Riverpod providers**

```dart
final memberRankingsRepositoryProvider = Provider<MemberRankingsRepository>(
  (ref) => MemberRankingsRemoteRepository(ref.read(apiClientProvider)),
);

final myRankingProvider = FutureProvider.autoDispose<MemberMyRankingDto?>((ref) async {
  final repo = ref.watch(memberRankingsRepositoryProvider);
  return repo.getMyRanking();
});

final sectionRankingProvider = FutureProvider.autoDispose
  .family<List<MemberRankingDto>, ({int sectionId, int yearId})>((ref, params) async {
    final repo = ref.watch(memberRankingsRepositoryProvider);
    return repo.getSectionMembers(params.sectionId, params.yearId);
  });
```

- [x] **Step 4: Write repository tests (mocktail)**

```dart
void main() {
  group('MemberRankingsRemoteRepository', () {
    test('getMyRanking returns DTO on 200', () async { /* ... */ });
    test('getMyRanking returns null on 403 (visibility=hidden)', () async { /* ... */ });
    test('getSectionMembers returns list', () async { /* ... */ });
  });
}
```

- [x] **Step 5: Run tests, expect PASS**

```bash
cd sacdia-app
flutter test test/features/rankings/
```

- [x] **Step 6: Code review checkpoint** — null on 403 (no throw), DTOs alineados con DTOs backend.

- [x] **Step 7: Commit**

```bash
cd sacdia-app
git add lib/features/rankings test/features/rankings
git commit -m "feat(rankings): add member + section rankings repository and providers

DTOs aligned with backend MemberRankingResponseDto.
Repository returns null on 403 (visibility=hidden) for graceful UI handling.
"
```

---

### Task 25: `MyRankingScreen` Flutter

**Files:**
- Create: `sacdia-app/lib/features/rankings/presentation/screens/my_ranking_screen.dart`
- Create: `sacdia-app/lib/features/rankings/presentation/widgets/my_ranking_header_card.dart`
- Create: `sacdia-app/lib/features/rankings/presentation/widgets/score_mini_card.dart`
- Create: `sacdia-app/lib/features/rankings/presentation/widgets/top_n_section.dart`

- [x] **Step 1: Implement header card (composite + rank + awarded category)**

```dart
class MyRankingHeaderCard extends StatelessWidget {
  final MemberRankingDto member;
  // build composite badge + rank + awarded category color badge
}
```

- [x] **Step 2: Implement 3 mini-cards (Clase / Investidura / Camporees)**

```dart
class ScoreMiniCard extends StatelessWidget {
  final String label;
  final double? value;
  final HugeIconData icon; // pattern HugeIconData typedef obligatorio (memory)
  // empty state si value == null: "Sin datos"
}
```

- [x] **Step 3: Implement screen con visibility gating**

```dart
class MyRankingScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRanking = ref.watch(myRankingProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Mi Ranking')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myRankingProvider),
        child: asyncRanking.when(
          data: (data) {
            if (data == null) return EmptyState(message: 'Tu ranking no está disponible.');
            if (data.member.compositeCalculatedAt == null) {
              return EmptyState(message: 'Tu puntaje aún no fue calculado');
            }
            return SingleChildScrollView(
              child: Column(children: [
                MyRankingHeaderCard(member: data.member),
                Row(children: [
                  Expanded(child: ScoreMiniCard(label: 'Clases', value: data.member.classScorePct, icon: HugeIcons.book01)),
                  Expanded(child: ScoreMiniCard(label: 'Investidura', value: data.member.investitureScorePct, icon: HugeIcons.medal01)),
                  Expanded(child: ScoreMiniCard(label: 'Camporees', value: data.member.camporeeScorePct, icon: HugeIcons.tent01)),
                ]),
                if (data.visibilityMode == 'self_and_top_n' && data.topN != null)
                  TopNSection(entries: data.topN!),
              ]),
            );
          },
          loading: () => Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorState(error: e.toString()),
        ),
      ),
    );
  }
}
```

- [x] **Step 4: Wire en navigation (gateado por `visibility != 'hidden'` server-side; cliente intenta y maneja null)**

- [x] **Step 5: Code review checkpoint** — usa `HugeIconData` (NO `dynamic` ni `IconData`). Empty states correctos.

- [x] **Step 6: Commit**

```bash
git add sacdia-app/lib/features/rankings/presentation/screens/my_ranking_screen.dart \
        sacdia-app/lib/features/rankings/presentation/widgets/{my_ranking_header_card,score_mini_card,top_n_section}.dart
git commit -m "feat(rankings): add MyRankingScreen with 3 score cards + composite + top_n"
```

---

### Task 26: `SectionRankingScreen` Flutter

**Files:**
- Create: `sacdia-app/lib/features/rankings/presentation/screens/section_ranking_screen.dart`
- Create: `sacdia-app/lib/features/rankings/presentation/widgets/member_list_tile.dart`

- [x] **Step 1: Implement screen**

```dart
class SectionRankingScreen extends ConsumerWidget {
  final int sectionId;
  final int yearId;
  const SectionRankingScreen({required this.sectionId, required this.yearId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMembers = ref.watch(sectionRankingProvider((sectionId: sectionId, yearId: yearId)));
    return Scaffold(
      appBar: AppBar(title: Text('Sección')),
      body: asyncMembers.when(
        data: (members) {
          if (members.isEmpty) return EmptyState();
          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (_, i) => MemberListTile(member: members[i]),
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(),
      ),
    );
  }
}
```

- [x] **Step 2: Implement `MemberListTile` (rank + name + composite badge)**

- [x] **Step 3: RBAC client-side gating** — pantalla solo visible para directores y asistentes de club. Resolver via providers de auth.

- [x] **Step 4: Code review checkpoint**

- [x] **Step 5: Commit**

```bash
git add sacdia-app/lib/features/rankings/presentation/screens/section_ranking_screen.dart \
        sacdia-app/lib/features/rankings/presentation/widgets/member_list_tile.dart
git commit -m "feat(rankings): add SectionRankingScreen with members list (rank ordered)"
```

---

## Phase 9 — Fase 2 optimization (delta-only) — OPTIONAL

### Task 27: Delta-only recalc — solo enrollments con `last_progress_change > previous_recalc_at`

**Files:**
- Modify: `sacdia-backend/prisma/schema.prisma` (agregar columna `last_progress_change` a `enrollments` o crear `enrollment_progress_audit`)
- Create: `sacdia-backend/prisma/migrations/<timestamp>_enrollment_delta_tracking/migration.sql`
- Modify: `sacdia-backend/src/rankings/rankings.service.ts` (`recalculateEnrollmentRankings` con filtro delta)
- Test: `sacdia-backend/src/rankings/rankings.service.delta.spec.ts`

- [ ] **Step 1: Decidir tracking strategy**

Opción A: agregar columna `last_progress_change TIMESTAMPTZ` a `enrollments`, actualizada por trigger en `class_module_progress`/`camporee_members`/`investiture_validation_history`.

Opción B: tabla `enrollment_progress_audit` con timestamp por evento.

Recomendado: Opción A (menos overhead).

- [ ] **Step 2: Crear migration**

```sql
ALTER TABLE enrollments ADD COLUMN last_progress_change TIMESTAMPTZ(6);

CREATE INDEX idx_enrollments_last_progress
  ON enrollments(last_progress_change);

-- Trigger en class_module_progress
CREATE OR REPLACE FUNCTION update_enrollment_last_progress()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE enrollments
    SET last_progress_change = NOW()
    WHERE enrollment_id = NEW.enrollment_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_class_module_progress_touch
  AFTER INSERT OR UPDATE ON class_module_progress
  FOR EACH ROW EXECUTE FUNCTION update_enrollment_last_progress();

-- Trigger análogo en camporee_members (via user_id → buscar enrollments del año)
-- y en investiture_validation_history
```

- [ ] **Step 3: Apply migration via psql + neonctl** (mismo patrón Task 2)

- [ ] **Step 4: Write failing test**

```typescript
describe('recalculateEnrollmentRankings (delta-only)', () => {
  it('skips enrollments with last_progress_change <= previous_recalc_at', async () => { /* ... */ });
  it('processes enrollments with last_progress_change > previous_recalc_at', async () => { /* ... */ });
});
```

- [ ] **Step 5: Implement filter en `recalculateEnrollmentRankings`**

```typescript
async recalculateEnrollmentRankings(yearId: number, mode: 'full' | 'delta' = 'full') {
  // ... existing setup ...
  const previousRecalc = await this.getPreviousRecalcAt(yearId);

  const enrollments = await this.prisma.enrollments.findMany({
    where: {
      ecclesiastical_year_id: yearId,
      active: true,
      class_id: { in: classIdSet },
      ...(mode === 'delta' && previousRecalc ? {
        last_progress_change: { gt: previousRecalc },
      } : {}),
    },
    // ... rest unchanged (classIdSet resolved via D9-α club_sections → club_type_id → classes)
  });
}
```

- [ ] **Step 6: Run test, expect PASS**

- [ ] **Step 7: Code review checkpoint** — verificar triggers no causan recursión, ON CONFLICT idempotente.

- [ ] **Step 8: Commit**

```bash
git add sacdia-backend/prisma/migrations/<timestamp>_enrollment_delta_tracking \
        sacdia-backend/prisma/schema.prisma \
        sacdia-backend/src/rankings/rankings.service.ts \
        sacdia-backend/src/rankings/rankings.service.delta.spec.ts
git commit -m "$(cat <<'EOF'
feat(rankings): add delta-only recalc mode for enrollment rankings

Adds enrollments.last_progress_change tracked via trigger on
class_module_progress, camporee_members, investiture_validation_history.
Mode 'delta' filters by last_progress_change > previous_recalc_at,
reducing daily cron cost for large clubs without progress changes.
Default cron mode unchanged ('full'); delta mode opt-in via param.
EOF
)"
```

---

## Self-review checklist

Antes de declarar el plan completo, el orquestador valida:

1. **Spec coverage**:
   - [x] Q1 Sección agregado puro → Task 9 (SectionAggregationService)
   - [x] Q2 3 señales Fase 1 → Tasks 4, 5, 7
   - [x] Q3 Tabla `enrollment_ranking_weights` separada → Task 1 (DDL) + Task 14 (CRUD)
   - [x] Q4 RBAC modelo C + flag visibility → Task 1 (seeds) + Task 12 (controller)
   - [x] Q5 UI 2 fases → Phase 5 (admin) + Phase 8 (Flutter)
   - [x] Q6 Cron secuencial → Task 10
   - [x] Q7 `award_categories.scope` polimórfica → Task 1 archivo 2 + Task 15
   - [x] Q8 AVG enrollments con composite calculado → Task 9
   - [x] Q9 Kill-switch separado → Task 1 archivo 3 + Task 10
   - [x] Q-RB1 Naming híbrido → documentado en header + Task 22 explicit
   - [x] Q-RB2 Evidencias descartadas + redistribución → Tasks 4-8
   - [x] Q-RB3 Investidura binaria → Task 5
   - [x] Q-RB4 `'approved'` locked camporees → Task 7
   - [x] §4 Schema → Task 1 + Task 3
   - [x] §5 Audit notes → Schema reality table al inicio
   - [x] §6 Endpoints + DTOs + RBAC → Tasks 12-15
   - [x] §7 Calculadores → Tasks 4-9
   - [x] §8 Cron + dark launch → Task 10
   - [x] §9 UI admin → Tasks 17-21
   - [x] §10 UI Flutter → Tasks 24-26
   - [x] §11 Migrations → Tasks 1-2
   - [x] §12 Error handling → distribuido en Tasks 10, 12, 14
   - [x] §13 Logs estructurados → Task 10
   - [x] §14 Testing strategy → Tasks 4-16
   - [x] §15 Open questions → tabla al inicio + OQ5 resuelto en Task 4
   - [x] §16 DoR/DoD → Task 23 smoke + Task 22 canon

2. **Placeholder scan**: NO TBD/TODO en task content. OQs centralizadas en sección dedicada.

3. **Type consistency**:
   - `enrollment_id` siempre INTEGER ✓
   - `user_id` siempre UUID ✓
   - `ecclesiastical_year_id` siempre INTEGER ✓
   - `club_section_id` siempre INTEGER ✓
   - Service signatures consistent: `calculate(enrollmentId: number, ecclesiasticalYearId: number): Promise<number | null>` ✓

4. **Naming consistency**:
   - Schema/internal: `enrollment_*` (tablas, columnas, modelos Prisma `EnrollmentRanking`/`SectionRanking`/`EnrollmentRankingWeight`) ✓
   - External (URLs/DTOs/perms/keys): `member_*` (`/api/v1/member-rankings`, `member_rankings:read_*`, `member_ranking.*`, `MemberRankingResponseDto`) ✓
   - NO mix detectado en el plan ✓

5. **Pipe consistency**:
   - `enrollment_id`/`section_id`/`club_id` → `ParseIntPipe` ✓
   - `id` UUIDs (weights, awarded_category) → `ParseUUIDPipe` ✓

6. **Race-safe rule**: Phase 1-4 same repo (sacdia-backend) → serialize subagents. Phase 5 (sacdia-admin) puede paralelizar SOLO después de mergear backend (Tasks 12-16 PR aprobado). Phase 6 (root sacdia) post-merge. Phase 8 (sacdia-app) wave separada.

7. **Engram references**: #1204/#1296/#1839 (Neon manual psql) en Task 2; #1850 (split FK + clubs sin union_id) en Task 7; #1883/#1888 (controller order + e2e gap) en Task 12 + 13 + 16.

---

## Total

- **27 tasks** (Phases 1-7 = 23 core, Phases 8-9 = 4 opcionales).
- Reducción vs plan anterior: 29 → 26 (Evidence calculator dropped por audit A5; Phase 0 audit ya completado en commit `643b694`). Task 6 added post stage-2 review: EnrollmentClubResolverService centralizes enrollment→club traversal (enrollments has no direct club_id FK).
- Execution recomendada: **subagent-driven-development** (always for SACDIA per stack engram #1850 race-safe rule).
