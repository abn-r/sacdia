# 8.4-A Section + Member Rankings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar rankings nivel sección + miembro extendiendo el pipeline composite ranking de 8.4-C, con dark-launch independiente, RBAC granular, y UI en 2 fases (admin web → Flutter móvil).

**Architecture:** Sección como agregado puro de miembros (sin calculadores propios). Miembro con 4 calculators TDD (clases, evidencias, investiduras, camporees) más composite con NULL redistribution. Cron secuencial mismo job (club → member → section), kill-switch independiente para dark launch, polimorfismo `award_categories.scope`. Tablas nuevas: `member_rankings`, `section_rankings`, `member_ranking_weights`. Reuso de `WeightsResolverService` y `CompositeScoreService` parametrizados por scope.

**Tech Stack:** NestJS + Prisma + PostgreSQL Neon (3 branches dev/staging/prod) + BullMQ + Redis (cron infra), Jest TDD backend, Next.js 16 + shadcn/ui + Tailwind v4 admin, Flutter Clean Architecture mobile (Fase 2).

**Spec reference:** `docs/superpowers/specs/2026-04-29-clasificacion-seccion-miembro-design.md`

**Engram references:** `sacdia/strategy/8-4-a-seccion-miembro-spec` (spec key), patrones #1204 / #1296 / #1839 (Neon migrations TXN atómicas), #1850 (clubs sin `union_id` directo — derivar via `local_fields`), #1883 / #1888 (controller order bugs con ParseUUIDPipe — orden en `module.controllers` array crítico, requiere e2e HTTP test real para detectar).

**Race-safe rule:** Same-repo (sacdia-backend) → serialize subagents. schema.prisma sólo lo edita Task 5. Cross-repo (backend ↔ admin) paralelizable únicamente después de mergear backend.

**Branch convention:** `feat/section-member-rankings-8-4-a` en los 3 repos cuando arranquen sub-features. Empezar en `sacdia-backend`.

**Test creds dev:** `admin@sacdia.com / Sacdia2026!` (super_admin), `director@sacdia.com / Sacdia2026!` (director-club ACV/GM).

---

## SCHEMA AUDIT NOTES (a verificar en Phase 0 antes de migrations)

El spec §5 lista 11 ítems de audit (A1–A11) que deben validarse contra Neon dev branch antes de escribir las migrations definitivas. Sin esto, las migrations pueden romper en runtime y los calculadores apuntar a tablas/columnas inexistentes. Phase 0 cubre esto explícitamente. Cuando un calculador (Tasks 6–9) referencia una tabla cuyo nombre o columna no fue confirmada, el subagente DEBE consultar primero los resultados del audit committed por Phase 0 antes de escribir SQL.

---

## Phase 0 — Migration audit + schema validation contra Neon dev

### Task 1: Schema audit subagent contra Neon dev (A1–A11)

**Files:**
- Create: `docs/superpowers/audits/2026-04-29-section-member-schema-audit.md`
- Modify: `docs/superpowers/specs/2026-04-29-clasificacion-seccion-miembro-design.md` (sección §5 con resultados)

- [ ] **Step 1: Lanzar subagent read-only que conecte a Neon dev y ejecute las 11 queries del spec §5**

Lanzar repo-researcher (haiku) con instrucciones: ejecutar las queries A1–A11 del spec §5 contra Neon dev usando:

```bash
PSQL=/opt/homebrew/opt/libpq/bin/psql
URL=$(neonctl connection-string development --project-id wispy-hall-32797215)
$PSQL "$URL" -v ON_ERROR_STOP=1 <<'SQL'
-- A1: members.member_id type
SELECT data_type FROM information_schema.columns
  WHERE table_name='members' AND column_name='member_id';

-- A2: members.member_status presence + enum values
SELECT column_name, data_type, udt_name FROM information_schema.columns
  WHERE table_name='members' AND column_name='member_status';
SELECT DISTINCT member_status FROM members LIMIT 20;

-- A3: club_sections.club_section_id type
SELECT data_type FROM information_schema.columns
  WHERE table_name='club_sections' AND column_name='club_section_id';

-- A4: member_class_progress existence + columns
SELECT to_regclass('public.member_class_progress');
SELECT column_name, data_type FROM information_schema.columns
  WHERE table_name='member_class_progress' ORDER BY ordinal_position;

-- A5: evidence_attendance per-member
SELECT to_regclass('public.evidence_attendance');
SELECT column_name FROM information_schema.columns
  WHERE table_name='evidence_attendance' ORDER BY ordinal_position;

-- A6: investitures per-member
SELECT to_regclass('public.investitures'), to_regclass('public.member_investitures');
SELECT table_name, column_name FROM information_schema.columns
  WHERE table_name IN ('investitures','member_investitures') ORDER BY table_name, ordinal_position;

-- A7: camporee_attendees / camporee_participants per-member
SELECT to_regclass('public.camporee_attendees'), to_regclass('public.camporee_participants');

-- A8: rol member en roles
SELECT role_id, code, name FROM roles WHERE code = 'member' OR name ILIKE '%member%';

-- A9: system_config column names
SELECT column_name FROM information_schema.columns
  WHERE table_name='system_config' ORDER BY ordinal_position;

-- A10: years vs ecclesiastical_years
SELECT to_regclass('public.years'), to_regclass('public.ecclesiastical_years');
SELECT column_name FROM information_schema.columns
  WHERE table_name='ecclesiastical_years' ORDER BY ordinal_position;

-- A11: investiture_requirements
SELECT to_regclass('public.investiture_requirements');
SELECT column_name FROM information_schema.columns
  WHERE table_name='investiture_requirements' ORDER BY ordinal_position;
SQL
```

El subagent debe devolver un report estructurado por ítem con: query ejecutada, output crudo, conclusión (CONFIRMED / DEVIATION / MISSING) y recomendación de acción. Patrón engram #1204/#1296/#1839 para uso de neonctl.

- [ ] **Step 2: Escribir audit report en `docs/superpowers/audits/2026-04-29-section-member-schema-audit.md`**

Estructura obligatoria:

```markdown
# Audit 8.4-A — Schema validation Neon dev (2026-04-29)

| ID  | Ítem                                  | Estado    | Tabla/columna real                | Acción                         |
|-----|---------------------------------------|-----------|-----------------------------------|--------------------------------|
| A1  | members.member_id INTEGER             | CONFIRMED | integer                           | usar Int en Prisma             |
| A2  | members.member_status existe          | TBD       | ...                               | si no existe → skip filtro F1  |
| A3  | club_sections.club_section_id INTEGER | CONFIRMED | integer                           | usar Int en Prisma             |
...
```

Una sección por ítem con la query, output, decisión.

- [ ] **Step 3: Update spec §5 con resultados confirmados**

Reemplazar la tabla "TODO" del spec §5 por la tabla real con estado CONFIRMED/DEVIATION/MISSING + acción tomada. Linkear al audit report.

- [ ] **Step 4: Commit**

```bash
cd /Users/abner/Documents/development/sacdia
git add docs/superpowers/audits/2026-04-29-section-member-schema-audit.md \
        docs/superpowers/specs/2026-04-29-clasificacion-seccion-miembro-design.md
git commit -m "$(cat <<'EOF'
docs(audit): validate 8.4-A schema dependencies against Neon dev

Run queries A1-A11 against development branch of wispy-hall-32797215.
Lock real table/column names before writing migrations.
EOF
)"
```

---

### Task 2: Lock decisiones de fallback para A2 y A11 (gating)

**Files:**
- Modify: `docs/superpowers/plans/2026-04-29-clasificacion-seccion-miembro.md` (este archivo, sección "Decisions log")
- Modify: `docs/superpowers/specs/2026-04-29-clasificacion-seccion-miembro-design.md` (§5 + §15.2 OQs)

- [ ] **Step 1: Decisión A2 (member_status)**

Si audit Task 1 reporta:
- **A2 CONFIRMED**: `SectionAggregationService` filtra por `m.member_status = 'active'`. No hay cambios.
- **A2 MISSING**: Fase 1 omite el filtro (se agregan TODAS las filas con `composite IS NOT NULL` en el AVG). Documentar TODO en plan + spec. Migration separada `ADD COLUMN member_status varchar(20) NOT NULL DEFAULT 'active'` se planifica para Fase 2 (no en este plan).

Append a este plan, en sección "Decisions log" al final:

```markdown
## Decisions log

- **A2 — `members.member_status`**: <CONFIRMED | MISSING>. <Acción>.
- **A11 — `investiture_requirements`**: <CONFIRMED | MISSING>. <Acción>.
- **A4 — `member_class_progress`**: <nombre real de tabla>. <Columnas confirmadas>.
- **A5 — `evidence_attendance`**: <nombre real | MISSING>. <Acción>.
- **A6 — investiduras per-member**: <tabla real>. <Columnas año + status>.
- **A7 — camporees per-member**: <tabla real | MISSING>. <Acción>.
- **A10 — años**: <`years` | `ecclesiastical_years`>. <FK column real>.
```

- [ ] **Step 2: Decisión A11 (investiture_requirements)**

- **A11 CONFIRMED**: `InvestitureScoreService` calcula `eligible_count` desde `investiture_requirements` per `(club_type_id, seniority_year)`.
- **A11 MISSING**: Workaround documentado. Opciones:
  1. **Bloquear señal**: `InvestitureScoreService.calculate()` retorna NULL siempre. Composite redistribuye su peso. Categorización afectada documentada.
  2. **Derivar elegibilidad**: si existe `class_modules` con regla por `club_type_id + age_min` o equivalente, derivar `eligible_count` de ahí. Documentar fórmula.

Lock una de las dos opciones aquí antes de Phase 2.

- [ ] **Step 3: Decisión A10 (years vs ecclesiastical_years)**

Lockear: a partir de Phase 1, todas las migrations y modelos Prisma usan el nombre de tabla y columna que devuelve el audit (probablemente `ecclesiastical_year_id` consistente con 8.4-C). Reemplazar `year_id` placeholder del spec en todas las referencias.

- [ ] **Step 4: Commit decisiones**

```bash
git add docs/superpowers/plans/2026-04-29-clasificacion-seccion-miembro.md \
        docs/superpowers/specs/2026-04-29-clasificacion-seccion-miembro-design.md
git commit -m "$(cat <<'EOF'
docs(plan): lock 8.4-A audit fallback decisions for A2/A10/A11

Fix migration ambiguity before Phase 1. Decisions sealed prior to writing SQL.
EOF
)"
```

---

## Phase 1 — Database migrations + RBAC seeds (sacdia-backend)

### Task 3: Crear 4 archivos de migration SQL

**Files:**
- Create: `sacdia-backend/prisma/migrations/20260429000000_member_rankings_schema/migration.sql`
- Create: `sacdia-backend/prisma/migrations/20260429000100_award_categories_scope/migration.sql`
- Create: `sacdia-backend/prisma/migrations/20260429000200_member_rankings_seeds/migration.sql`
- Create: `sacdia-backend/prisma/migrations/20260429000300_member_rankings_award_seeds/migration.sql`

> **NOTA**: tipos de FK (`Int` vs `String/Uuid`) deben matchear lo confirmado por audit Task 1. El template a continuación asume `member_id INTEGER`, `club_id INTEGER`, `club_section_id INTEGER`, `ecclesiastical_year_id INTEGER` consistente con 8.4-C. Si audit difiere, ajustar antes de commit.

- [ ] **Step 1: `20260429000000_member_rankings_schema/migration.sql`**

```sql
-- 20260429000000_member_rankings_schema

CREATE TABLE member_rankings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id INTEGER NOT NULL REFERENCES members(member_id) ON DELETE CASCADE,
  club_id INTEGER NOT NULL REFERENCES clubs(club_id),
  club_section_id INTEGER REFERENCES club_sections(club_section_id),
  ecclesiastical_year_id INTEGER NOT NULL REFERENCES ecclesiastical_years(year_id),
  class_score_pct NUMERIC(5,2),
  evidence_score_pct NUMERIC(5,2),
  investiture_score_pct NUMERIC(5,2),
  camporee_score_pct NUMERIC(5,2),
  composite_score_pct NUMERIC(5,2),
  rank_position INTEGER,
  awarded_category_id UUID REFERENCES award_categories(award_category_id),
  composite_calculated_at TIMESTAMPTZ(6),
  created_at TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
  CONSTRAINT uq_member_rankings_member_year UNIQUE(member_id, ecclesiastical_year_id)
);

CREATE INDEX idx_member_rankings_club_year
  ON member_rankings(club_id, ecclesiastical_year_id);

CREATE INDEX idx_member_rankings_section_year
  ON member_rankings(club_section_id, ecclesiastical_year_id);

CREATE INDEX idx_member_rankings_composite
  ON member_rankings(club_id, ecclesiastical_year_id, composite_score_pct DESC NULLS LAST);

CREATE TABLE section_rankings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  club_section_id INTEGER NOT NULL REFERENCES club_sections(club_section_id) ON DELETE CASCADE,
  club_id INTEGER NOT NULL REFERENCES clubs(club_id),
  ecclesiastical_year_id INTEGER NOT NULL REFERENCES ecclesiastical_years(year_id),
  composite_score_pct NUMERIC(5,2),
  active_member_count INTEGER NOT NULL DEFAULT 0,
  rank_position INTEGER,
  awarded_category_id UUID REFERENCES award_categories(award_category_id),
  composite_calculated_at TIMESTAMPTZ(6),
  created_at TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
  CONSTRAINT uq_section_rankings_section_year UNIQUE(club_section_id, ecclesiastical_year_id)
);

CREATE INDEX idx_section_rankings_club_year
  ON section_rankings(club_id, ecclesiastical_year_id);

CREATE INDEX idx_section_rankings_composite
  ON section_rankings(club_id, ecclesiastical_year_id, composite_score_pct DESC NULLS LAST);

CREATE TABLE member_ranking_weights (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  club_type_id INTEGER REFERENCES club_types(club_type_id),
  ecclesiastical_year_id INTEGER REFERENCES ecclesiastical_years(year_id),
  class_pct NUMERIC(5,2) NOT NULL,
  evidence_pct NUMERIC(5,2) NOT NULL,
  investiture_pct NUMERIC(5,2) NOT NULL,
  camporee_pct NUMERIC(5,2) NOT NULL,
  is_default BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
  CONSTRAINT chk_member_weights_sum_100
    CHECK (class_pct + evidence_pct + investiture_pct + camporee_pct = 100),
  CONSTRAINT chk_member_weights_ranges
    CHECK (
      class_pct       BETWEEN 0 AND 100
      AND evidence_pct    BETWEEN 0 AND 100
      AND investiture_pct BETWEEN 0 AND 100
      AND camporee_pct    BETWEEN 0 AND 100
    ),
  CONSTRAINT uq_member_weights_type_year UNIQUE(club_type_id, ecclesiastical_year_id)
);

-- partial unique index for default global (club_type_id IS NULL AND year IS NULL)
CREATE UNIQUE INDEX idx_member_ranking_weights_default
  ON member_ranking_weights ((1))
  WHERE club_type_id IS NULL AND ecclesiastical_year_id IS NULL;
```

- [ ] **Step 2: `20260429000100_award_categories_scope/migration.sql`**

```sql
-- 20260429000100_award_categories_scope

ALTER TABLE award_categories
  ADD COLUMN scope VARCHAR(20) NOT NULL DEFAULT 'club';

ALTER TABLE award_categories
  ADD CONSTRAINT chk_award_scope
  CHECK (scope IN ('club', 'section', 'member'));

-- Backfill defensivo (todas las filas existentes ya tienen 'club' por DEFAULT)
UPDATE award_categories SET scope = 'club' WHERE scope IS NULL;

CREATE INDEX idx_award_categories_scope
  ON award_categories(scope, is_legacy);
```

- [ ] **Step 3: `20260429000200_member_rankings_seeds/migration.sql`**

```sql
-- 20260429000200_member_rankings_seeds

-- Seed default global weights (40/25/20/15 según spec §4.3)
INSERT INTO member_ranking_weights
  (club_type_id, ecclesiastical_year_id, class_pct, evidence_pct, investiture_pct, camporee_pct, is_default)
VALUES
  (NULL, NULL, 40, 25, 20, 15, true)
ON CONFLICT DO NOTHING;

-- system_config keys nuevas
INSERT INTO system_config (config_key, config_value, description, config_type) VALUES
  ('member_ranking.recalculation_enabled', 'true',
   'Kill-switch para el recálculo de member + section rankings (8.4-A)', 'boolean'),
  ('member_ranking.member_visibility', 'self_only',
   'Visibilidad del ranking para el miembro: self_only | self_and_top_n | hidden', 'string'),
  ('member_ranking.top_n', '5',
   'Cantidad de miembros en top N cuando member_visibility = self_and_top_n', 'integer')
ON CONFLICT (config_key) DO NOTHING;

-- 10 permisos nuevos
INSERT INTO permissions (permission_id, code, description, created_at)
VALUES
  (gen_random_uuid(), 'member_rankings:read_self',     'Read own member ranking',                NOW()),
  (gen_random_uuid(), 'member_rankings:read_section',  'Read member rankings within own section', NOW()),
  (gen_random_uuid(), 'member_rankings:read_club',     'Read member rankings within own club',    NOW()),
  (gen_random_uuid(), 'member_rankings:read_lf',       'Read member rankings within own local field', NOW()),
  (gen_random_uuid(), 'member_rankings:read_global',   'Read all member rankings',                NOW()),
  (gen_random_uuid(), 'member_ranking_weights:read',   'Read member ranking weight configurations', NOW()),
  (gen_random_uuid(), 'member_ranking_weights:write',  'Create/update/delete member ranking weights', NOW()),
  (gen_random_uuid(), 'section_rankings:read_club',    'Read section rankings within own club',   NOW()),
  (gen_random_uuid(), 'section_rankings:read_lf',      'Read section rankings within own local field', NOW()),
  (gen_random_uuid(), 'section_rankings:read_global',  'Read all section rankings',               NOW())
ON CONFLICT (code) DO NOTHING;

-- Grants en role_permissions según matriz §4.6 del spec
-- super_admin + admin: TODO (10 permisos)
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM roles r CROSS JOIN permissions p
WHERE r.code IN ('super_admin', 'admin')
  AND p.code LIKE 'member_rankings:%' OR p.code LIKE 'section_rankings:%' OR p.code LIKE 'member_ranking_weights:%'
ON CONFLICT DO NOTHING;

-- member: read_self
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM roles r CROSS JOIN permissions p
WHERE r.code = 'member' AND p.code = 'member_rankings:read_self'
ON CONFLICT DO NOTHING;

-- assistant-club, director-club: read_section + read_club + section_rankings:read_club
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM roles r CROSS JOIN permissions p
WHERE r.code IN ('assistant-club', 'director-club')
  AND p.code IN ('member_rankings:read_section', 'member_rankings:read_club', 'section_rankings:read_club')
ON CONFLICT DO NOTHING;

-- director-dia, assistant-dia: read_club + section_rankings:read_club
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM roles r CROSS JOIN permissions p
WHERE r.code IN ('director-dia', 'assistant-dia')
  AND p.code IN ('member_rankings:read_club', 'section_rankings:read_club')
ON CONFLICT DO NOTHING;

-- director-lf, assistant-lf: read_lf + section_rankings:read_lf
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM roles r CROSS JOIN permissions p
WHERE r.code IN ('director-lf', 'assistant-lf')
  AND p.code IN ('member_rankings:read_lf', 'section_rankings:read_lf')
ON CONFLICT DO NOTHING;

-- director-lf adicional: member_ranking_weights:read
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM roles r CROSS JOIN permissions p
WHERE r.code = 'director-lf'
  AND p.code = 'member_ranking_weights:read'
ON CONFLICT DO NOTHING;

-- director-union, assistant-union: read_global + section_rankings:read_global + weights:read
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM roles r CROSS JOIN permissions p
WHERE r.code IN ('director-union', 'assistant-union')
  AND p.code IN ('member_rankings:read_global', 'section_rankings:read_global', 'member_ranking_weights:read')
ON CONFLICT DO NOTHING;
```

> **NOTA**: si audit Task 1 reporta nombres de roles distintos a los del spec (ej. `member` no existe en tabla `roles`), revisar en sub-paso de Phase 0 antes de aplicar este archivo.

- [ ] **Step 4: `20260429000300_member_rankings_award_seeds/migration.sql`**

```sql
-- 20260429000300_member_rankings_award_seeds

-- Seed default categorías scope='member' y scope='section'
INSERT INTO award_categories
  (award_category_id, name, scope, min_composite_pct, max_composite_pct, color, is_legacy, created_at, updated_at)
VALUES
  (gen_random_uuid(), 'AAA', 'member', 85, 100,    '#4ade80', false, NOW(), NOW()),
  (gen_random_uuid(), 'AA',  'member', 75, 84.99,  '#86efac', false, NOW(), NOW()),
  (gen_random_uuid(), 'A',   'member', 65, 74.99,  '#fde047', false, NOW(), NOW()),
  (gen_random_uuid(), 'B',   'member', 50, 64.99,  '#fb923c', false, NOW(), NOW()),
  (gen_random_uuid(), 'C',   'member',  0, 49.99,  '#f87171', false, NOW(), NOW()),
  (gen_random_uuid(), 'AAA', 'section', 85, 100,   '#4ade80', false, NOW(), NOW()),
  (gen_random_uuid(), 'AA',  'section', 75, 84.99, '#86efac', false, NOW(), NOW()),
  (gen_random_uuid(), 'A',   'section', 65, 74.99, '#fde047', false, NOW(), NOW()),
  (gen_random_uuid(), 'B',   'section', 50, 64.99, '#fb923c', false, NOW(), NOW()),
  (gen_random_uuid(), 'C',   'section',  0, 49.99, '#f87171', false, NOW(), NOW())
ON CONFLICT DO NOTHING;
```

- [ ] **Step 5: Commit los 4 archivos**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
git add prisma/migrations/20260429000000_member_rankings_schema \
        prisma/migrations/20260429000100_award_categories_scope \
        prisma/migrations/20260429000200_member_rankings_seeds \
        prisma/migrations/20260429000300_member_rankings_award_seeds
git commit -m "$(cat <<'EOF'
feat(schema): add member + section rankings migrations (8.4-A)

3 new tables (member_rankings, section_rankings, member_ranking_weights),
award_categories.scope polymorphic column, 10 RBAC permissions, 3 system_config keys,
default global weights 40/25/20/15, 10 default award categories (member + section).
EOF
)"
```

---

### Task 4: Aplicar 4 migrations a Neon dev → staging → prod

**Files:**
- Read-only: 4 migration files de Task 3
- Execution: psql + neonctl

> **Patrón engram #1204 / #1296 / #1839**: TXN atómica per-archivo, registrar en `_prisma_migrations` manualmente, verify queries post-apply.

- [ ] **Step 1: Pre-check sobre cada branch**

```bash
PSQL=/opt/homebrew/opt/libpq/bin/psql

for BRANCH in development staging production; do
  URL=$(neonctl connection-string $BRANCH --project-id wispy-hall-32797215)
  echo "=== Pre-check $BRANCH ==="
  $PSQL "$URL" -v ON_ERROR_STOP=1 <<'SQL'
SELECT to_regclass('public.member_rankings'),
       to_regclass('public.section_rankings'),
       to_regclass('public.member_ranking_weights');
SELECT column_name FROM information_schema.columns
  WHERE table_name='award_categories' AND column_name='scope';
SELECT config_key FROM system_config
  WHERE config_key LIKE 'member_ranking.%';
SELECT code FROM permissions WHERE code LIKE 'member_rankings:%' OR code LIKE 'section_rankings:%' OR code LIKE 'member_ranking_weights:%';
SQL
done
```

Expected en los 3 branches PRE-apply: `to_regclass` NULL para las 3 tablas, 0 rows para `scope` column, 0 system_config rows, 0 permissions rows.

- [ ] **Step 2: Aplicar atómicamente per branch (dev primero)**

```bash
for BRANCH in development staging production; do
  URL=$(neonctl connection-string $BRANCH --project-id wispy-hall-32797215)
  echo "=== Apply $BRANCH ==="
  $PSQL "$URL" -v ON_ERROR_STOP=1 <<SQL
BEGIN;

\i sacdia-backend/prisma/migrations/20260429000000_member_rankings_schema/migration.sql
INSERT INTO _prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count)
VALUES (gen_random_uuid()::text, 'manual', NOW(), '20260429000000_member_rankings_schema', NULL, NULL, NOW(), 1);

\i sacdia-backend/prisma/migrations/20260429000100_award_categories_scope/migration.sql
INSERT INTO _prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count)
VALUES (gen_random_uuid()::text, 'manual', NOW(), '20260429000100_award_categories_scope', NULL, NULL, NOW(), 1);

\i sacdia-backend/prisma/migrations/20260429000200_member_rankings_seeds/migration.sql
INSERT INTO _prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count)
VALUES (gen_random_uuid()::text, 'manual', NOW(), '20260429000200_member_rankings_seeds', NULL, NULL, NOW(), 1);

\i sacdia-backend/prisma/migrations/20260429000300_member_rankings_award_seeds/migration.sql
INSERT INTO _prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count)
VALUES (gen_random_uuid()::text, 'manual', NOW(), '20260429000300_member_rankings_award_seeds', NULL, NULL, NOW(), 1);

COMMIT;
SQL
done
```

Si CUALQUIER branch falla, abortar el loop y NO continuar. Investigar root cause antes de retry. Si falla post-apply (verify), correr rollback DDL del spec §11.8 sobre el branch afectado.

- [ ] **Step 3: Verify post-apply per branch**

```bash
for BRANCH in development staging production; do
  URL=$(neonctl connection-string $BRANCH --project-id wispy-hall-32797215)
  echo "=== Verify $BRANCH ==="
  $PSQL "$URL" -v ON_ERROR_STOP=1 <<'SQL'
SELECT to_regclass('public.member_rankings') IS NOT NULL AS member_rankings_ok,
       to_regclass('public.section_rankings') IS NOT NULL AS section_rankings_ok,
       to_regclass('public.member_ranking_weights') IS NOT NULL AS weights_ok;
-- expect: t,t,t

SELECT class_pct, evidence_pct, investiture_pct, camporee_pct
  FROM member_ranking_weights
  WHERE club_type_id IS NULL AND ecclesiastical_year_id IS NULL;
-- expect: (40, 25, 20, 15)

SELECT COUNT(*) FROM system_config WHERE config_key LIKE 'member_ranking.%';
-- expect: 3

SELECT COUNT(*) FROM permissions
  WHERE code LIKE 'member_rankings:%' OR code LIKE 'section_rankings:%' OR code LIKE 'member_ranking_weights:%';
-- expect: 10

SELECT COUNT(*) FROM award_categories WHERE scope = 'member';
-- expect: >= 5

SELECT COUNT(*) FROM award_categories WHERE scope = 'section';
-- expect: >= 5

SELECT migration_name FROM _prisma_migrations WHERE migration_name LIKE '20260429%' ORDER BY migration_name;
-- expect: 4 rows
SQL
done
```

- [ ] **Step 4: Engram save**

Save `mem_save` con topic_key `sacdia/migration/8-4-a-applied`, type=config, content: branches afectados, timestamps, verify outputs. NO commit code aún (no hay código TS aún).

---

### Task 5: Extender `schema.prisma` con 3 modelos nuevos + extension AwardCategory.scope

**Files:**
- Modify: `sacdia-backend/prisma/schema.prisma`

> **Race-safety**: ESTE es el único task que toca `schema.prisma`. Otros tasks NO modifican el archivo.

- [ ] **Step 1: Localizar `model award_categories` y agregar campo scope**

```prisma
model award_categories {
  // ...existing fields...
  scope             String   @default("club") @db.VarChar(20)
  // ...
  @@index([scope, is_legacy], map: "idx_award_categories_scope")
}
```

- [ ] **Step 2: Agregar 3 modelos nuevos al final del schema (después de los modelos de 8.4-C)**

```prisma
model member_rankings {
  id                       String       @id @default(uuid()) @db.Uuid
  member_id                Int
  club_id                  Int
  club_section_id          Int?
  ecclesiastical_year_id   Int
  class_score_pct          Decimal?     @db.Decimal(5, 2)
  evidence_score_pct       Decimal?     @db.Decimal(5, 2)
  investiture_score_pct    Decimal?     @db.Decimal(5, 2)
  camporee_score_pct       Decimal?     @db.Decimal(5, 2)
  composite_score_pct      Decimal?     @db.Decimal(5, 2)
  rank_position            Int?
  awarded_category_id      String?      @db.Uuid
  composite_calculated_at  DateTime?    @db.Timestamptz(6)
  created_at               DateTime     @default(now()) @db.Timestamptz(6)
  updated_at               DateTime     @default(now()) @db.Timestamptz(6)

  members                  members              @relation(fields: [member_id], references: [member_id], onDelete: Cascade)
  clubs                    clubs                @relation(fields: [club_id], references: [club_id])
  club_sections            club_sections?       @relation(fields: [club_section_id], references: [club_section_id])
  ecclesiastical_years     ecclesiastical_years @relation(fields: [ecclesiastical_year_id], references: [year_id])
  award_categories         award_categories?    @relation(fields: [awarded_category_id], references: [award_category_id])

  @@unique([member_id, ecclesiastical_year_id], map: "uq_member_rankings_member_year")
  @@index([club_id, ecclesiastical_year_id], map: "idx_member_rankings_club_year")
  @@index([club_section_id, ecclesiastical_year_id], map: "idx_member_rankings_section_year")
  @@index([club_id, ecclesiastical_year_id, composite_score_pct(sort: Desc)], map: "idx_member_rankings_composite")
}

model section_rankings {
  id                       String      @id @default(uuid()) @db.Uuid
  club_section_id          Int
  club_id                  Int
  ecclesiastical_year_id   Int
  composite_score_pct      Decimal?    @db.Decimal(5, 2)
  active_member_count      Int         @default(0)
  rank_position            Int?
  awarded_category_id      String?     @db.Uuid
  composite_calculated_at  DateTime?   @db.Timestamptz(6)
  created_at               DateTime    @default(now()) @db.Timestamptz(6)
  updated_at               DateTime    @default(now()) @db.Timestamptz(6)

  club_sections            club_sections        @relation(fields: [club_section_id], references: [club_section_id], onDelete: Cascade)
  clubs                    clubs                @relation(fields: [club_id], references: [club_id])
  ecclesiastical_years     ecclesiastical_years @relation(fields: [ecclesiastical_year_id], references: [year_id])
  award_categories         award_categories?    @relation(fields: [awarded_category_id], references: [award_category_id])

  @@unique([club_section_id, ecclesiastical_year_id], map: "uq_section_rankings_section_year")
  @@index([club_id, ecclesiastical_year_id], map: "idx_section_rankings_club_year")
}

model member_ranking_weights {
  id                       String     @id @default(uuid()) @db.Uuid
  club_type_id             Int?
  ecclesiastical_year_id   Int?
  class_pct                Decimal    @db.Decimal(5, 2)
  evidence_pct             Decimal    @db.Decimal(5, 2)
  investiture_pct          Decimal    @db.Decimal(5, 2)
  camporee_pct             Decimal    @db.Decimal(5, 2)
  is_default               Boolean    @default(false)
  created_at               DateTime   @default(now()) @db.Timestamptz(6)
  updated_at               DateTime   @default(now()) @db.Timestamptz(6)

  club_types               club_types?           @relation(fields: [club_type_id], references: [club_type_id])
  ecclesiastical_years     ecclesiastical_years? @relation(fields: [ecclesiastical_year_id], references: [year_id])

  @@unique([club_type_id, ecclesiastical_year_id], map: "uq_member_weights_type_year")
}
```

- [ ] **Step 3: Agregar reverse relations a modelos existentes**

En `model members`: `member_rankings member_rankings[]`
En `model clubs`: `member_rankings member_rankings[]` y `section_rankings section_rankings[]`
En `model club_sections`: `member_rankings member_rankings[]` y `section_rankings section_rankings[]`
En `model ecclesiastical_years`: `member_rankings member_rankings[]`, `section_rankings section_rankings[]`, `member_ranking_weights member_ranking_weights[]`
En `model club_types`: `member_ranking_weights member_ranking_weights[]`
En `model award_categories`: `member_rankings member_rankings[]` y `section_rankings section_rankings[]`

- [ ] **Step 4: Run prisma generate**

```bash
cd sacdia-backend
pnpm prisma generate
pnpm tsc --noEmit
```

Expected: ambos exit 0. Si `tsc` reporta errores, generalmente es relación faltante en algún modelo existente — revisar paso 3.

- [ ] **Step 5: Commit**

```bash
git add prisma/schema.prisma
git commit -m "$(cat <<'EOF'
feat(schema): add member + section rankings Prisma models (8.4-A)

3 new models (member_rankings, section_rankings, member_ranking_weights),
extend award_categories with scope field, regenerate Prisma client.
EOF
)"
```

---

## Phase 2 — Backend score calculators TDD (sacdia-backend)

> **Reglas TDD**: cada calculator se implementa en orden estricto: spec test PRIMERO con código completo de los assertions, run `pnpm jest <file>` esperando FAIL, then minimal implementation, run again esperando PASS, then commit. NO se permite saltarse el "run failing first" step. Si audit Task 1 reportó que la tabla fuente no existe, aplicar el workaround documentado en Phase 0 ANTES de escribir el calculator.

> **Carpeta destino para los 6 servicios**: `sacdia-backend/src/member-rankings/score-calculators/`. Module wiring se hace en Task 12.

### Task 6: `ClassScoreService` TDD

**Files:**
- Create: `sacdia-backend/src/member-rankings/score-calculators/class-score.ts`
- Create: `sacdia-backend/src/member-rankings/score-calculators/class-score.spec.ts`

- [ ] **Step 1: Write failing test**

```typescript
import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { ClassScoreService } from './class-score';

describe('ClassScoreService.calculate', () => {
  let svc: ClassScoreService;
  let prisma: { $queryRaw: jest.Mock };

  beforeEach(async () => {
    prisma = { $queryRaw: jest.fn() };
    const m = await Test.createTestingModule({
      providers: [ClassScoreService, { provide: PrismaService, useValue: prisma }],
    }).compile();
    svc = m.get(ClassScoreService);
  });

  it('returns 60 when 3/5 classes completed', async () => {
    prisma.$queryRaw
      .mockResolvedValueOnce([{ completed: 3n, required: 5n }]);
    const result = await svc.calculate(101, 7);
    expect(Number(result)).toBe(60);
  });

  it('returns NULL when required_count = 0', async () => {
    prisma.$queryRaw
      .mockResolvedValueOnce([{ completed: 0n, required: 0n }]);
    const result = await svc.calculate(101, 7);
    expect(result).toBeNull();
  });

  it('returns 100 when completed > required (defensive clamp)', async () => {
    prisma.$queryRaw
      .mockResolvedValueOnce([{ completed: 12n, required: 8n }]);
    const result = await svc.calculate(101, 7);
    expect(Number(result)).toBe(100);
  });

  it('returns 100 when fully completed', async () => {
    prisma.$queryRaw
      .mockResolvedValueOnce([{ completed: 5n, required: 5n }]);
    const result = await svc.calculate(101, 7);
    expect(Number(result)).toBe(100);
  });

  it('returns 0 when none completed', async () => {
    prisma.$queryRaw
      .mockResolvedValueOnce([{ completed: 0n, required: 5n }]);
    const result = await svc.calculate(101, 7);
    expect(Number(result)).toBe(0);
  });
});
```

- [ ] **Step 2: Run, expect FAIL**

```bash
cd sacdia-backend
pnpm jest src/member-rankings/score-calculators/class-score.spec.ts
```

Expected: `Cannot find module './class-score'`.

- [ ] **Step 3: Implement minimal `class-score.ts`**

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class ClassScoreService {
  constructor(private readonly prisma: PrismaService) {}

  async calculate(memberId: number, ecclesiasticalYearId: number): Promise<number | null> {
    // NOTA: nombres de tabla/columna confirmados por audit A4. Si difieren, ajustar aquí.
    const rows = await this.prisma.$queryRaw<{ completed: bigint; required: bigint }[]>`
      SELECT
        (SELECT COUNT(*)::bigint
           FROM member_class_progress mcp
           WHERE mcp.member_id = ${memberId}
             AND mcp.ecclesiastical_year_id = ${ecclesiasticalYearId}
             AND mcp.status = 'completed') AS completed,
        (SELECT COUNT(*)::bigint
           FROM class_modules cm
           JOIN members m ON m.member_id = ${memberId}
           WHERE cm.club_type_id = m.club_type_id
             AND cm.is_required = true) AS required
    `;
    const completed = Number(rows[0]?.completed ?? 0n);
    const required = Number(rows[0]?.required ?? 0n);
    if (required === 0) return null;
    const pct = Math.min((completed / required) * 100, 100);
    return Number(pct.toFixed(2));
  }
}
```

- [ ] **Step 4: Run, expect PASS**

```bash
pnpm jest src/member-rankings/score-calculators/class-score.spec.ts
```

Expected: 5 tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/member-rankings/score-calculators/class-score.ts \
        src/member-rankings/score-calculators/class-score.spec.ts
git commit -m "feat(member-rankings): add ClassScoreService with NULL-on-zero-required"
```

---

### Task 7: `EvidenceScoreService` TDD

**Files:**
- Create: `sacdia-backend/src/member-rankings/score-calculators/evidence-score.ts`
- Create: `sacdia-backend/src/member-rankings/score-calculators/evidence-score.spec.ts`

> Si audit A5 reportó MISSING para `evidence_attendance`, aplicar workaround locked en Phase 0 (probable: derivar de `annual_folder_section_evaluations` per-member o block calculator retornando NULL).

- [ ] **Step 1: Write failing test**

```typescript
import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { EvidenceScoreService } from './evidence-score';

describe('EvidenceScoreService.calculate', () => {
  let svc: EvidenceScoreService;
  let prisma: { $queryRaw: jest.Mock };

  beforeEach(async () => {
    prisma = { $queryRaw: jest.fn() };
    const m = await Test.createTestingModule({
      providers: [EvidenceScoreService, { provide: PrismaService, useValue: prisma }],
    }).compile();
    svc = m.get(EvidenceScoreService);
  });

  it('returns 80 when attended 8/10 evidences', async () => {
    prisma.$queryRaw.mockResolvedValueOnce([{ attended: 8n, total: 10n }]);
    expect(Number(await svc.calculate(101, 7))).toBe(80);
  });

  it('returns NULL when total_evidences = 0', async () => {
    prisma.$queryRaw.mockResolvedValueOnce([{ attended: 0n, total: 0n }]);
    expect(await svc.calculate(101, 7)).toBeNull();
  });

  it('returns 100 when 100% attended', async () => {
    prisma.$queryRaw.mockResolvedValueOnce([{ attended: 10n, total: 10n }]);
    expect(Number(await svc.calculate(101, 7))).toBe(100);
  });

  it('returns 0 when 0 attended', async () => {
    prisma.$queryRaw.mockResolvedValueOnce([{ attended: 0n, total: 10n }]);
    expect(Number(await svc.calculate(101, 7))).toBe(0);
  });
});
```

- [ ] **Step 2: Run, expect FAIL**

```bash
pnpm jest src/member-rankings/score-calculators/evidence-score.spec.ts
```

- [ ] **Step 3: Implement**

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class EvidenceScoreService {
  constructor(private readonly prisma: PrismaService) {}

  async calculate(memberId: number, ecclesiasticalYearId: number): Promise<number | null> {
    // NOTA: si A5 reporta MISSING, swap esta query por workaround locked en Phase 0.
    const rows = await this.prisma.$queryRaw<{ attended: bigint; total: bigint }[]>`
      SELECT
        (SELECT COUNT(DISTINCT ea.evidence_id)::bigint
           FROM evidence_attendance ea
           WHERE ea.member_id = ${memberId}
             AND ea.ecclesiastical_year_id = ${ecclesiasticalYearId}) AS attended,
        (SELECT COUNT(DISTINCT e.evidence_id)::bigint
           FROM evidences e
           JOIN members m ON m.member_id = ${memberId}
           WHERE e.club_id = m.club_id
             AND e.ecclesiastical_year_id = ${ecclesiasticalYearId}
             AND e.active = true) AS total
    `;
    const attended = Number(rows[0]?.attended ?? 0n);
    const total = Number(rows[0]?.total ?? 0n);
    if (total === 0) return null;
    const pct = Math.min((attended / total) * 100, 100);
    return Number(pct.toFixed(2));
  }
}
```

- [ ] **Step 4: Run, expect PASS**

```bash
pnpm jest src/member-rankings/score-calculators/evidence-score.spec.ts
```

- [ ] **Step 5: Commit**

```bash
git add src/member-rankings/score-calculators/evidence-score.ts \
        src/member-rankings/score-calculators/evidence-score.spec.ts
git commit -m "feat(member-rankings): add EvidenceScoreService with NULL-on-zero-total"
```

---

### Task 8: `InvestitureScoreService` TDD

**Files:**
- Create: `sacdia-backend/src/member-rankings/score-calculators/investiture-score.ts`
- Create: `sacdia-backend/src/member-rankings/score-calculators/investiture-score.spec.ts`

> Si audit A11 reportó MISSING, aplicar workaround locked en Phase 0 (block o derivar). Decisión crítica: `eligible_count = 0` → NULL (NO 100). Tests blindan esto.

- [ ] **Step 1: Write failing test**

```typescript
import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { InvestitureScoreService } from './investiture-score';

describe('InvestitureScoreService.calculate', () => {
  let svc: InvestitureScoreService;
  let prisma: { $queryRaw: jest.Mock };

  beforeEach(async () => {
    prisma = { $queryRaw: jest.fn() };
    const m = await Test.createTestingModule({
      providers: [InvestitureScoreService, { provide: PrismaService, useValue: prisma }],
    }).compile();
    svc = m.get(InvestitureScoreService);
  });

  it('returns ~66.67 for 2/3 investitures achieved', async () => {
    prisma.$queryRaw.mockResolvedValueOnce([{ achieved: 2n, eligible: 3n }]);
    expect(Number(await svc.calculate(101, 7))).toBeCloseTo(66.67, 2);
  });

  it('returns NULL when eligible_count = 0 (decisión crítica)', async () => {
    prisma.$queryRaw.mockResolvedValueOnce([{ achieved: 0n, eligible: 0n }]);
    expect(await svc.calculate(101, 7)).toBeNull();
  });

  it('returns 100 when achieved = eligible', async () => {
    prisma.$queryRaw.mockResolvedValueOnce([{ achieved: 3n, eligible: 3n }]);
    expect(Number(await svc.calculate(101, 7))).toBe(100);
  });

  it('returns 100 (clamped) when achieved > eligible (data corruption)', async () => {
    prisma.$queryRaw.mockResolvedValueOnce([{ achieved: 5n, eligible: 3n }]);
    expect(Number(await svc.calculate(101, 7))).toBe(100);
  });

  it('returns 0 when achieved = 0 with eligible > 0', async () => {
    prisma.$queryRaw.mockResolvedValueOnce([{ achieved: 0n, eligible: 3n }]);
    expect(Number(await svc.calculate(101, 7))).toBe(0);
  });
});
```

- [ ] **Step 2: Run, expect FAIL**

```bash
pnpm jest src/member-rankings/score-calculators/investiture-score.spec.ts
```

- [ ] **Step 3: Implement**

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class InvestitureScoreService {
  constructor(private readonly prisma: PrismaService) {}

  async calculate(memberId: number, ecclesiasticalYearId: number): Promise<number | null> {
    // NOTA: nombres de tabla por audit A6/A11. Si A11 MISSING, retornar null incondicional.
    const rows = await this.prisma.$queryRaw<{ achieved: bigint; eligible: bigint }[]>`
      SELECT
        (SELECT COUNT(*)::bigint
           FROM investitures i
           WHERE i.member_id = ${memberId}
             AND i.achieved_year_id = ${ecclesiasticalYearId}
             AND i.status = 'approved') AS achieved,
        (SELECT COUNT(*)::bigint
           FROM investiture_requirements ir
           JOIN members m ON m.member_id = ${memberId}
           WHERE ir.club_type_id = m.club_type_id
             AND ir.seniority_year <= COALESCE(m.seniority_years, 0)) AS eligible
    `;
    const achieved = Number(rows[0]?.achieved ?? 0n);
    const eligible = Number(rows[0]?.eligible ?? 0n);
    if (eligible === 0) return null;
    const pct = Math.min((achieved / eligible) * 100, 100);
    return Number(pct.toFixed(2));
  }
}
```

- [ ] **Step 4: Run, expect PASS**

```bash
pnpm jest src/member-rankings/score-calculators/investiture-score.spec.ts
```

- [ ] **Step 5: Commit**

```bash
git add src/member-rankings/score-calculators/investiture-score.ts \
        src/member-rankings/score-calculators/investiture-score.spec.ts
git commit -m "feat(member-rankings): add InvestitureScoreService (NULL on zero eligible)"
```

---

### Task 9: `CamporeeScoreService` per-member TDD

**Files:**
- Create: `sacdia-backend/src/member-rankings/score-calculators/camporee-score.ts`
- Create: `sacdia-backend/src/member-rankings/score-calculators/camporee-score.spec.ts`

> Diferencia con 8.4-C: numerador = camporees a los que el MIEMBRO asistió (no el club). Denominador igual al club: camporees del scope union. **Engram #1850**: clubs sin `union_id` directo, derivar via `local_fields`.

- [ ] **Step 1: Write failing test**

```typescript
import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { CamporeeScoreService } from './camporee-score';

describe('CamporeeScoreService.calculate (per-member)', () => {
  let svc: CamporeeScoreService;
  let prisma: { $queryRaw: jest.Mock };

  beforeEach(async () => {
    prisma = { $queryRaw: jest.fn() };
    const m = await Test.createTestingModule({
      providers: [CamporeeScoreService, { provide: PrismaService, useValue: prisma }],
    }).compile();
    svc = m.get(CamporeeScoreService);
  });

  it('returns 50 when attended 1/2', async () => {
    prisma.$queryRaw
      .mockResolvedValueOnce([{ resolved_union_id: 3 }])  // resolve union via local_field
      .mockResolvedValueOnce([{ total: 2n }])             // denom
      .mockResolvedValueOnce([{ participated: 1n }]);     // numer
    expect(Number(await svc.calculate(101, 7))).toBe(50);
  });

  it('returns NULL when total_camporees = 0', async () => {
    prisma.$queryRaw
      .mockResolvedValueOnce([{ resolved_union_id: 3 }])
      .mockResolvedValueOnce([{ total: 0n }]);
    expect(await svc.calculate(101, 7)).toBeNull();
  });

  it('handles member whose club has no resolvable union (fallback nationals only)', async () => {
    prisma.$queryRaw
      .mockResolvedValueOnce([{ resolved_union_id: null }])
      .mockResolvedValueOnce([{ total: 1n }])
      .mockResolvedValueOnce([{ participated: 1n }]);
    expect(Number(await svc.calculate(101, 7))).toBe(100);
  });

  it('returns 100 when participated = total', async () => {
    prisma.$queryRaw
      .mockResolvedValueOnce([{ resolved_union_id: 3 }])
      .mockResolvedValueOnce([{ total: 2n }])
      .mockResolvedValueOnce([{ participated: 2n }]);
    expect(Number(await svc.calculate(101, 7))).toBe(100);
  });
});
```

- [ ] **Step 2: Run, expect FAIL**

```bash
pnpm jest src/member-rankings/score-calculators/camporee-score.spec.ts
```

- [ ] **Step 3: Implement**

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class CamporeeScoreService {
  constructor(private readonly prisma: PrismaService) {}

  async calculate(memberId: number, ecclesiasticalYearId: number): Promise<number | null> {
    // 1. Resolver union_id del miembro vía local_fields (engram #1850: clubs no tiene union_id directo)
    const unionRows = await this.prisma.$queryRaw<{ resolved_union_id: number | null }[]>`
      SELECT lf.union_id AS resolved_union_id
      FROM members m
      JOIN clubs c ON c.club_id = m.club_id
      JOIN local_fields lf ON lf.local_field_id = c.local_field_id
      WHERE m.member_id = ${memberId}
    `;
    const unionId = unionRows[0]?.resolved_union_id ?? null;

    // 2. Denom: total camporees del scope (local del LF + nationals = union_id IS NULL)
    const denomRows = await this.prisma.$queryRaw<{ total: bigint }[]>`
      SELECT COUNT(*)::bigint AS total FROM (
        SELECT local_camporee_id AS camporee_id FROM local_camporees
          WHERE ecclesiastical_year_id = ${ecclesiasticalYearId} AND active = true
            AND (local_field_id IN (SELECT local_field_id FROM local_fields WHERE union_id = ${unionId}) OR ${unionId}::int IS NULL)
        UNION ALL
        SELECT union_camporee_id AS camporee_id FROM union_camporees
          WHERE ecclesiastical_year_id = ${ecclesiasticalYearId} AND active = true
            AND (union_id = ${unionId} OR union_id IS NULL)
      ) t
    `;
    const total = Number(denomRows[0]?.total ?? 0n);
    if (total === 0) return null;

    // 3. Numer: camporees asistidos por este miembro
    const numerRows = await this.prisma.$queryRaw<{ participated: bigint }[]>`
      SELECT COUNT(DISTINCT ca.camporee_id)::bigint AS participated
      FROM camporee_attendees ca
      WHERE ca.member_id = ${memberId}
        AND ca.ecclesiastical_year_id = ${ecclesiasticalYearId}
        AND ca.status = 'attended'
    `;
    const participated = Number(numerRows[0]?.participated ?? 0n);

    const pct = Math.min((participated / total) * 100, 100);
    return Number(pct.toFixed(2));
  }
}
```

- [ ] **Step 4: Run, expect PASS**

```bash
pnpm jest src/member-rankings/score-calculators/camporee-score.spec.ts
```

- [ ] **Step 5: Commit**

```bash
git add src/member-rankings/score-calculators/camporee-score.ts \
        src/member-rankings/score-calculators/camporee-score.spec.ts
git commit -m "feat(member-rankings): add per-member CamporeeScoreService scoped via local_fields"
```

---

### Task 10: `MemberCompositeScoreService` TDD (NULL redistribution)

**Files:**
- Create: `sacdia-backend/src/member-rankings/score-calculators/member-composite-score.ts`
- Create: `sacdia-backend/src/member-rankings/score-calculators/member-composite-score.spec.ts`
- Create: `sacdia-backend/src/member-rankings/score-calculators/member-weights-resolver.ts`
- Create: `sacdia-backend/src/member-rankings/score-calculators/member-weights-resolver.spec.ts`

> 2 servicios en este task (resolver + composite). El composite reusa conceptualmente el `WeightsResolverService` de 8.4-C pero contra `member_ranking_weights`.

- [ ] **Step 1: Write `member-weights-resolver.spec.ts` (failing)**

```typescript
import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { MemberWeightsResolverService } from './member-weights-resolver';

describe('MemberWeightsResolverService.resolve', () => {
  let svc: MemberWeightsResolverService;
  let prisma: { member_ranking_weights: { findFirst: jest.Mock } };

  beforeEach(async () => {
    prisma = { member_ranking_weights: { findFirst: jest.fn() } };
    const m = await Test.createTestingModule({
      providers: [MemberWeightsResolverService, { provide: PrismaService, useValue: prisma }],
    }).compile();
    svc = m.get(MemberWeightsResolverService);
  });

  it('returns club_type+year override when present', async () => {
    prisma.member_ranking_weights.findFirst.mockResolvedValueOnce({
      class_pct: 50, evidence_pct: 20, investiture_pct: 20, camporee_pct: 10,
    });
    expect(await svc.resolve(1, 7)).toEqual({
      class: 50, evidence: 20, investiture: 20, camporee: 10,
      source: 'override:club_type_1+year_7',
    });
  });

  it('falls back to default global', async () => {
    prisma.member_ranking_weights.findFirst
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce({ class_pct: 40, evidence_pct: 25, investiture_pct: 20, camporee_pct: 15 });
    expect(await svc.resolve(1, 7)).toEqual({
      class: 40, evidence: 25, investiture: 20, camporee: 15, source: 'default',
    });
  });

  it('throws when default is missing (config invariant)', async () => {
    prisma.member_ranking_weights.findFirst.mockResolvedValue(null);
    await expect(svc.resolve(1, 7)).rejects.toThrow('Default member ranking weights missing');
  });
});
```

- [ ] **Step 2: Implement `member-weights-resolver.ts`**

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

export interface ResolvedMemberWeights {
  class: number;
  evidence: number;
  investiture: number;
  camporee: number;
  source: string;
}

@Injectable()
export class MemberWeightsResolverService {
  constructor(private readonly prisma: PrismaService) {}

  async resolve(clubTypeId: number, ecclesiasticalYearId: number): Promise<ResolvedMemberWeights> {
    const override = await this.prisma.member_ranking_weights.findFirst({
      where: { club_type_id: clubTypeId, ecclesiastical_year_id: ecclesiasticalYearId },
    });
    if (override) {
      return {
        class: Number(override.class_pct),
        evidence: Number(override.evidence_pct),
        investiture: Number(override.investiture_pct),
        camporee: Number(override.camporee_pct),
        source: `override:club_type_${clubTypeId}+year_${ecclesiasticalYearId}`,
      };
    }
    const def = await this.prisma.member_ranking_weights.findFirst({
      where: { club_type_id: null, ecclesiastical_year_id: null },
    });
    if (!def) throw new Error('Default member ranking weights missing');
    return {
      class: Number(def.class_pct),
      evidence: Number(def.evidence_pct),
      investiture: Number(def.investiture_pct),
      camporee: Number(def.camporee_pct),
      source: 'default',
    };
  }
}
```

Run `pnpm jest member-weights-resolver.spec.ts` → PASS.

- [ ] **Step 3: Write `member-composite-score.spec.ts` (failing)**

```typescript
import { MemberCompositeScoreService, ComponentScoresNullable } from './member-composite-score';
import type { ResolvedMemberWeights } from './member-weights-resolver';

const W: ResolvedMemberWeights = {
  class: 40, evidence: 25, investiture: 20, camporee: 15, source: 'default',
};

describe('MemberCompositeScoreService.compose (with NULL redistribution)', () => {
  const svc = new MemberCompositeScoreService();

  it('weighted average when all 4 scores present', () => {
    const scores: ComponentScoresNullable = { class: 80, evidence: 70, investiture: 60, camporee: 50 };
    // 80*0.4 + 70*0.25 + 60*0.2 + 50*0.15 = 32 + 17.5 + 12 + 7.5 = 69
    expect(svc.compose(scores, W)).toBe(69);
  });

  it('redistributes NULL weight proportionally to valid scores', () => {
    // class NULL, weight 40 → redistribute over evidence(25), investiture(20), camporee(15) sum=60
    // redistributed weights: evidence = 25 + 25/60*40 = 41.6667; investiture = 20 + 20/60*40 = 33.3333; camporee = 15 + 15/60*40 = 25
    // sum = 100. Composite = (70*41.6667 + 60*33.3333 + 50*25)/100
    const scores: ComponentScoresNullable = { class: null, evidence: 70, investiture: 60, camporee: 50 };
    const result = svc.compose(scores, W);
    const expected = (70 * 41.6667 + 60 * 33.3333 + 50 * 25) / 100;
    expect(result).toBeCloseTo(expected, 1);
  });

  it('returns NULL when all scores are NULL', () => {
    const scores: ComponentScoresNullable = { class: null, evidence: null, investiture: null, camporee: null };
    expect(svc.compose(scores, W)).toBeNull();
  });

  it('uses single valid score as composite when 3 are NULL', () => {
    const scores: ComponentScoresNullable = { class: 80, evidence: null, investiture: null, camporee: null };
    expect(svc.compose(scores, W)).toBe(80);
  });

  it('clamps composite to [0,100]', () => {
    const scores: ComponentScoresNullable = { class: 100, evidence: 100, investiture: 100, camporee: 100 };
    expect(svc.compose(scores, W)).toBe(100);
  });
});
```

- [ ] **Step 4: Implement `member-composite-score.ts`**

```typescript
import { Injectable } from '@nestjs/common';
import type { ResolvedMemberWeights } from './member-weights-resolver';

export interface ComponentScoresNullable {
  class: number | null;
  evidence: number | null;
  investiture: number | null;
  camporee: number | null;
}

@Injectable()
export class MemberCompositeScoreService {
  compose(scores: ComponentScoresNullable, weights: ResolvedMemberWeights): number | null {
    const pairs: Array<{ score: number; weight: number }> = [];
    if (scores.class !== null)       pairs.push({ score: scores.class,       weight: weights.class });
    if (scores.evidence !== null)    pairs.push({ score: scores.evidence,    weight: weights.evidence });
    if (scores.investiture !== null) pairs.push({ score: scores.investiture, weight: weights.investiture });
    if (scores.camporee !== null)    pairs.push({ score: scores.camporee,    weight: weights.camporee });

    if (pairs.length === 0) return null;

    const sumValid = pairs.reduce((s, p) => s + p.weight, 0);
    if (sumValid === 0) return null;

    // Redistribute NULL weights proportionally to remaining valid weights
    const sumNull = 100 - sumValid;
    const redistributed = pairs.map((p) => ({
      score: p.score,
      weight: p.weight + (p.weight / sumValid) * sumNull,
    }));

    const composite = redistributed.reduce((s, p) => s + p.score * p.weight, 0) / 100;
    const clamped = Math.max(0, Math.min(100, composite));
    return Number(clamped.toFixed(2));
  }
}
```

Run `pnpm jest member-composite-score.spec.ts` → PASS.

- [ ] **Step 5: Commit**

```bash
git add src/member-rankings/score-calculators/member-weights-resolver.ts \
        src/member-rankings/score-calculators/member-weights-resolver.spec.ts \
        src/member-rankings/score-calculators/member-composite-score.ts \
        src/member-rankings/score-calculators/member-composite-score.spec.ts
git commit -m "feat(member-rankings): add MemberCompositeScoreService with NULL redistribution"
```

---

### Task 11: `SectionAggregationService` TDD

**Files:**
- Create: `sacdia-backend/src/member-rankings/score-calculators/section-aggregation.ts`
- Create: `sacdia-backend/src/member-rankings/score-calculators/section-aggregation.spec.ts`

> Si A2 (`member_status`) MISSING per audit, omitir filtro `WHERE m.member_status = 'active'` en la query (ver decisión locked en Phase 0).

- [ ] **Step 1: Write failing test**

```typescript
import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { SectionAggregationService } from './section-aggregation';

describe('SectionAggregationService.aggregate', () => {
  let svc: SectionAggregationService;
  let prisma: { $queryRaw: jest.Mock };

  beforeEach(async () => {
    prisma = { $queryRaw: jest.fn() };
    const m = await Test.createTestingModule({
      providers: [SectionAggregationService, { provide: PrismaService, useValue: prisma }],
    }).compile();
    svc = m.get(SectionAggregationService);
  });

  it('returns AVG and active_count for section with 3 active members', async () => {
    prisma.$queryRaw.mockResolvedValueOnce([{ avg_pct: '70.50', active_count: 3n }]);
    const result = await svc.aggregate(42, 7);
    expect(result).toEqual({ composite_score_pct: 70.5, active_member_count: 3 });
  });

  it('returns NULL composite + 0 count for empty section', async () => {
    prisma.$queryRaw.mockResolvedValueOnce([{ avg_pct: null, active_count: 0n }]);
    const result = await svc.aggregate(42, 7);
    expect(result).toEqual({ composite_score_pct: null, active_member_count: 0 });
  });

  it('AVG ignores NULL composite scores (PostgreSQL default)', async () => {
    // member 1=80, 2=NULL, 3=60 → AVG = 70 over 2 valid (PostgreSQL ignores NULL)
    prisma.$queryRaw.mockResolvedValueOnce([{ avg_pct: '70.00', active_count: 3n }]);
    const result = await svc.aggregate(42, 7);
    expect(result.composite_score_pct).toBe(70);
    expect(result.active_member_count).toBe(3);
  });
});
```

- [ ] **Step 2: Run, expect FAIL**

```bash
pnpm jest src/member-rankings/score-calculators/section-aggregation.spec.ts
```

- [ ] **Step 3: Implement**

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

export interface SectionAggregateResult {
  composite_score_pct: number | null;
  active_member_count: number;
}

@Injectable()
export class SectionAggregationService {
  constructor(private readonly prisma: PrismaService) {}

  async aggregate(clubSectionId: number, ecclesiasticalYearId: number): Promise<SectionAggregateResult> {
    // NOTA: si A2 MISSING (decisión Phase 0), eliminar JOIN m + filtro member_status.
    const rows = await this.prisma.$queryRaw<{ avg_pct: string | null; active_count: bigint }[]>`
      SELECT
        AVG(mr.composite_score_pct)::numeric(5,2) AS avg_pct,
        COUNT(*)::bigint AS active_count
      FROM member_rankings mr
      JOIN members m ON m.member_id = mr.member_id
      WHERE mr.club_section_id = ${clubSectionId}
        AND mr.ecclesiastical_year_id = ${ecclesiasticalYearId}
        AND m.member_status = 'active'
    `;
    const avgRaw = rows[0]?.avg_pct;
    const activeCount = Number(rows[0]?.active_count ?? 0n);

    return {
      composite_score_pct: avgRaw === null ? null : Number(avgRaw),
      active_member_count: activeCount,
    };
  }
}
```

- [ ] **Step 4: Run, expect PASS**

```bash
pnpm jest src/member-rankings/score-calculators/section-aggregation.spec.ts
```

- [ ] **Step 5: Commit**

```bash
git add src/member-rankings/score-calculators/section-aggregation.ts \
        src/member-rankings/score-calculators/section-aggregation.spec.ts
git commit -m "feat(member-rankings): add SectionAggregationService AVG-of-actives"
```

---

## Phase 3 — Backend cron integration + ranking-position update (sacdia-backend)

### Task 12: Extender `rankings.service.ts` con `recalculateMemberRankings` + `recalculateSectionAggregates`

**Files:**
- Modify: `sacdia-backend/src/annual-folders/rankings.service.ts`
- Modify: `sacdia-backend/src/annual-folders/annual-folders.module.ts` (registrar 6 providers nuevos)
- Create: `sacdia-backend/src/annual-folders/__tests__/rankings.service.member.spec.ts`

- [ ] **Step 1: Registrar providers en `annual-folders.module.ts`**

```typescript
import { ClassScoreService } from '../member-rankings/score-calculators/class-score';
import { EvidenceScoreService } from '../member-rankings/score-calculators/evidence-score';
import { InvestitureScoreService } from '../member-rankings/score-calculators/investiture-score';
import { CamporeeScoreService as MemberCamporeeScoreService } from '../member-rankings/score-calculators/camporee-score';
import { MemberWeightsResolverService } from '../member-rankings/score-calculators/member-weights-resolver';
import { MemberCompositeScoreService } from '../member-rankings/score-calculators/member-composite-score';
import { SectionAggregationService } from '../member-rankings/score-calculators/section-aggregation';

@Module({
  // ...
  providers: [
    // ...existing 8.4-C providers...
    ClassScoreService,
    EvidenceScoreService,
    InvestitureScoreService,
    MemberCamporeeScoreService,
    MemberWeightsResolverService,
    MemberCompositeScoreService,
    SectionAggregationService,
  ],
})
```

- [ ] **Step 2: Inyectar en RankingsService constructor**

```typescript
constructor(
  private readonly prisma: PrismaService,
  // existing 8.4-C services...
  private readonly classScore: ClassScoreService,
  private readonly evidenceScore: EvidenceScoreService,
  private readonly investitureScore: InvestitureScoreService,
  private readonly memberCamporeeScore: MemberCamporeeScoreService,
  private readonly memberWeights: MemberWeightsResolverService,
  private readonly memberComposite: MemberCompositeScoreService,
  private readonly sectionAggregation: SectionAggregationService,
) {}
```

- [ ] **Step 3: Implementar `recalculateMemberRankings(yearId?)`**

```typescript
async recalculateMemberRankings(yearId?: number): Promise<{ processed: number; skipped: number }> {
  const year = yearId ?? await this.resolveActiveYearId();
  const logger = new Logger('member-rankings');

  const clubs = await this.prisma.clubs.findMany({
    where: { active: true },
    select: { club_id: true, club_type_id: true },
  });

  let processed = 0;
  let skipped = 0;

  for (const club of clubs) {
    const members = await this.prisma.members.findMany({
      where: { club_id: club.club_id },
      select: { member_id: true, club_section_id: true },
    });

    for (const member of members) {
      try {
        const [classS, evS, invS, camS] = await Promise.all([
          this.classScore.calculate(member.member_id, year),
          this.evidenceScore.calculate(member.member_id, year),
          this.investitureScore.calculate(member.member_id, year),
          this.memberCamporeeScore.calculate(member.member_id, year),
        ]);

        const weights = await this.memberWeights.resolve(club.club_type_id, year);
        const composite = this.memberComposite.compose(
          { class: classS, evidence: evS, investiture: invS, camporee: camS },
          weights,
        );

        await this.prisma.member_rankings.upsert({
          where: { uq_member_rankings_member_year: { member_id: member.member_id, ecclesiastical_year_id: year } },
          create: {
            member_id: member.member_id,
            club_id: club.club_id,
            club_section_id: member.club_section_id,
            ecclesiastical_year_id: year,
            class_score_pct: classS as any,
            evidence_score_pct: evS as any,
            investiture_score_pct: invS as any,
            camporee_score_pct: camS as any,
            composite_score_pct: composite as any,
            composite_calculated_at: new Date(),
          },
          update: {
            club_id: club.club_id,
            club_section_id: member.club_section_id,
            class_score_pct: classS as any,
            evidence_score_pct: evS as any,
            investiture_score_pct: invS as any,
            camporee_score_pct: camS as any,
            composite_score_pct: composite as any,
            composite_calculated_at: new Date(),
            updated_at: new Date(),
          },
        });
        processed++;
      } catch (err) {
        logger.error(`Member recalc failed member_id=${member.member_id} year=${year}`, err);
        skipped++;
      }
    }
  }

  logger.log(`Member recalc done year=${year} processed=${processed} skipped=${skipped}`);
  return { processed, skipped };
}
```

- [ ] **Step 4: Implementar `recalculateSectionAggregates(yearId?)`**

```typescript
async recalculateSectionAggregates(yearId?: number): Promise<{ processed: number; skipped: number }> {
  const year = yearId ?? await this.resolveActiveYearId();
  const logger = new Logger('section-rankings');

  const sections = await this.prisma.club_sections.findMany({
    select: { club_section_id: true, main_club_id: true },
  });

  let processed = 0;
  let skipped = 0;

  for (const section of sections) {
    try {
      const result = await this.sectionAggregation.aggregate(section.club_section_id, year);
      await this.prisma.section_rankings.upsert({
        where: { uq_section_rankings_section_year: { club_section_id: section.club_section_id, ecclesiastical_year_id: year } },
        create: {
          club_section_id: section.club_section_id,
          club_id: section.main_club_id,
          ecclesiastical_year_id: year,
          composite_score_pct: result.composite_score_pct as any,
          active_member_count: result.active_member_count,
          composite_calculated_at: new Date(),
        },
        update: {
          composite_score_pct: result.composite_score_pct as any,
          active_member_count: result.active_member_count,
          composite_calculated_at: new Date(),
          updated_at: new Date(),
        },
      });
      processed++;
    } catch (err) {
      logger.error(`Section aggregate failed section_id=${section.club_section_id} year=${year}`, err);
      skipped++;
    }
  }

  logger.log(`Section aggregate done year=${year} processed=${processed} skipped=${skipped}`);
  return { processed, skipped };
}
```

- [ ] **Step 5: Wire en cron handler existente**

Localizar `@Cron('0 2 * * *', { name: 'rankings-recalculation', timeZone: 'UTC' })` (8.4-C) y extender:

```typescript
@Cron('0 2 * * *', { name: 'rankings-recalculation', timeZone: 'UTC' })
async handleRankingsRecalculation(): Promise<void> {
  const logger = new Logger('rankings-cron');
  // Kill-switch global 8.4-C
  const globalEnabled = await this.systemConfig.get('ranking.recalculation_enabled');
  if (globalEnabled === 'false') {
    logger.warn('Recalculation disabled by global kill-switch');
    return;
  }

  // Step 1: clubs (8.4-C)
  await this.recalculateClubRankings();

  // Step 2 + 3: member + section (8.4-A)
  const memberEnabled = await this.systemConfig.get('member_ranking.recalculation_enabled');
  if (memberEnabled !== 'false') {
    try {
      await this.recalculateMemberRankings();
    } catch (err) {
      logger.error('recalculateMemberRankings failed, continuing to section aggregates', err);
    }
    try {
      await this.recalculateSectionAggregates();
    } catch (err) {
      logger.error('recalculateSectionAggregates failed', err);
    }
  } else {
    logger.warn('Member ranking recalculation disabled by kill-switch');
  }
}
```

- [ ] **Step 6: Integration test rankings.service.member.spec.ts**

```typescript
import { Test } from '@nestjs/testing';
import { RankingsService } from '../rankings.service';
import { PrismaService } from '../../prisma/prisma.service';
// Import all 7 score services + mocks

describe('RankingsService.recalculateMemberRankings', () => {
  // Mock prisma + services, verify:
  // - kill-switch off → NO calls to score services
  // - per-member error logged + counted as skipped, loop continues
  // - upsert called with correct shape
});

describe('RankingsService.recalculateSectionAggregates', () => {
  // - empty section → composite NULL + count 0
  // - error per section logged + skipped, continues
});
```

Run: `pnpm jest rankings.service.member.spec.ts` → PASS (≥4 tests).

- [ ] **Step 7: Commit**

```bash
git add src/annual-folders/rankings.service.ts \
        src/annual-folders/annual-folders.module.ts \
        src/annual-folders/__tests__/rankings.service.member.spec.ts
git commit -m "$(cat <<'EOF'
feat(rankings): wire member + section recalculation into cron pipeline

Sequential club -> member -> section. Kill-switch member_ranking.recalculation_enabled
gates steps 2+3 independently. Per-member/section errors logged + skipped.
EOF
)"
```

---

### Task 13: SQL UPDATE DENSE_RANK() per club + año (NULLS LAST)

**Files:**
- Modify: `sacdia-backend/src/annual-folders/rankings.service.ts` (agregar método `updateRankPositions`)
- Modify: `sacdia-backend/src/annual-folders/__tests__/rankings.service.member.spec.ts`

- [ ] **Step 1: Implementar `updateMemberRankPositions(yearId)`**

```typescript
private async updateMemberRankPositions(yearId: number): Promise<void> {
  await this.prisma.$executeRaw`
    UPDATE member_rankings mr
    SET rank_position = ranked.rk
    FROM (
      SELECT id, DENSE_RANK() OVER (
        PARTITION BY club_id, ecclesiastical_year_id
        ORDER BY composite_score_pct DESC NULLS LAST
      ) AS rk
      FROM member_rankings
      WHERE ecclesiastical_year_id = ${yearId}
    ) ranked
    WHERE mr.id = ranked.id
  `;
  // Set NULL rank for rows where composite is NULL (no positional rank)
  await this.prisma.$executeRaw`
    UPDATE member_rankings
    SET rank_position = NULL
    WHERE ecclesiastical_year_id = ${yearId}
      AND composite_score_pct IS NULL
  `;
}

private async updateSectionRankPositions(yearId: number): Promise<void> {
  await this.prisma.$executeRaw`
    UPDATE section_rankings sr
    SET rank_position = ranked.rk
    FROM (
      SELECT id, DENSE_RANK() OVER (
        PARTITION BY club_id, ecclesiastical_year_id
        ORDER BY composite_score_pct DESC NULLS LAST
      ) AS rk
      FROM section_rankings
      WHERE ecclesiastical_year_id = ${yearId}
    ) ranked
    WHERE sr.id = ranked.id
  `;
  await this.prisma.$executeRaw`
    UPDATE section_rankings
    SET rank_position = NULL
    WHERE ecclesiastical_year_id = ${yearId}
      AND composite_score_pct IS NULL
  `;
}
```

- [ ] **Step 2: Llamar después de cada recalculate**

En `recalculateMemberRankings` antes del return: `await this.updateMemberRankPositions(year);`
En `recalculateSectionAggregates` antes del return: `await this.updateSectionRankPositions(year);`

- [ ] **Step 3: Integration test (real Prisma against test DB seed)**

Agregar test en spec del Task 12:

```typescript
it('assigns DENSE_RANK with NULLS LAST and ties share rank', async () => {
  // Seed 4 member_rankings: composite 90, 90, 80, NULL (same club + year)
  // After updateMemberRankPositions: ranks = [1, 1, 2, NULL]
});
```

- [ ] **Step 4: Run + Commit**

```bash
pnpm jest rankings.service.member.spec.ts
git add src/annual-folders/rankings.service.ts \
        src/annual-folders/__tests__/rankings.service.member.spec.ts
git commit -m "feat(rankings): add DENSE_RANK NULLS LAST for member + section positions"
```

---

## Phase 4 — Backend REST endpoints (sacdia-backend)

> **CRÍTICO — engram #1883 / PR #28**: el orden de controllers en el array `controllers` del `@Module` IMPORTA. Rutas específicas deben declararse ANTES que rutas con `:param` dinámico. Si añadís rutas con `:param` a un módulo existente, reordená Y agregá un e2e test HTTP real (Task 18) para detectar bugs de ParseUUIDPipe order. Recordá que `member_id`, `club_section_id`, `club_id` son INTEGER — NO usar `ParseUUIDPipe` en esos params, solo `ParseIntPipe`. Usar `ParseUUIDPipe` SOLO en `awarded_category_id` y `member_ranking_weights.id`.

### Task 14: Crear módulo `member-rankings/` (controller + service + DTOs)

**Files:**
- Create: `sacdia-backend/src/member-rankings/member-rankings.module.ts`
- Create: `sacdia-backend/src/member-rankings/member-rankings.controller.ts`
- Create: `sacdia-backend/src/member-rankings/member-rankings.service.ts`
- Create: `sacdia-backend/src/member-rankings/dto/member-ranking-response.dto.ts`
- Create: `sacdia-backend/src/member-rankings/dto/member-breakdown.dto.ts`
- Create: `sacdia-backend/src/member-rankings/dto/recalculate-member-rankings.dto.ts`
- Create: `sacdia-backend/src/member-rankings/__tests__/member-rankings.controller.spec.ts`

- [ ] **Step 1: Crear DTOs**

`member-ranking-response.dto.ts` (campos según spec §6.5):

```typescript
export class MemberRankingResponseDto {
  member_id!: number;
  member_name!: string;
  club_section_id!: number | null;
  section_name!: string | null;
  class_score_pct!: number | null;
  evidence_score_pct!: number | null;
  investiture_score_pct!: number | null;
  camporee_score_pct!: number | null;
  composite_score_pct!: number | null;
  rank_position!: number | null;
  awarded_category!: { id: string; name: string; color: string; min_pct: number; max_pct: number } | null;
  composite_calculated_at!: string | null;
}
```

`member-breakdown.dto.ts` extiende lo anterior agregando `weights_applied` + 4 `*_breakdown` (ver spec §6.5).

`recalculate-member-rankings.dto.ts`:

```typescript
import { IsInt, IsOptional } from 'class-validator';

export class RecalculateMemberRankingsDto {
  @IsOptional() @IsInt() year_id?: number;
  @IsOptional() @IsInt() club_id?: number;
}
```

- [ ] **Step 2: Crear `member-rankings.service.ts`**

Métodos:
- `list(filter, scope)` — query paginada con scope-filter del caller
- `breakdown(memberId, callerScope)` — drill-down 4 breakdowns + weights
- `me(memberId)` — respeta `member_visibility` flag
- `triggerRecalc(dto)` — kill-switch check + delega en `RankingsService.recalculateMemberRankings(year_id)`

Pseudocódigo:

```typescript
async me(memberId: number) {
  const visibility = await this.systemConfig.get('member_ranking.member_visibility');
  if (visibility === 'hidden') throw new ForbiddenException('MEMBER_RANKING_HIDDEN');

  const yearId = await this.resolveActiveYear();
  const member = await this.prisma.member_rankings.findUnique({
    where: { uq_member_rankings_member_year: { member_id: memberId, ecclesiastical_year_id: yearId } },
    include: { /* relations for DTO */ },
  });
  if (!member) throw new NotFoundException('MEMBER_RANKING_NOT_FOUND');

  const result: MemberMyRankingDto = { member: this.toDto(member), visibility_mode: visibility as any };
  if (visibility === 'self_and_top_n') {
    const topN = parseInt(await this.systemConfig.get('member_ranking.top_n') || '5', 10);
    result.top_n = await this.fetchTopN(member.club_id, yearId, topN);
  }
  return result;
}
```

- [ ] **Step 3: Crear `member-rankings.controller.ts`**

```typescript
import { Body, Controller, Get, Param, ParseIntPipe, Post, Query, UseGuards, Req } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { PermissionsGuard } from '../auth/permissions.guard';
import { RequirePermissions } from '../auth/permissions.decorator';
import { MemberRankingsService } from './member-rankings.service';
import { RecalculateMemberRankingsDto } from './dto/recalculate-member-rankings.dto';

@Controller('member-rankings')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class MemberRankingsController {
  constructor(private readonly svc: MemberRankingsService) {}

  // ORDER MATTERS — specific routes BEFORE :param routes (engram #1883)
  @Get('me')
  @RequirePermissions('member_rankings:read_self')
  me(@Req() req: any) {
    return this.svc.me(req.user.member_id);
  }

  @Post('recalculate')
  @RequirePermissions('member_ranking_weights:write')
  recalculate(@Body() dto: RecalculateMemberRankingsDto) {
    return this.svc.triggerRecalc(dto);
  }

  @Get()
  @RequirePermissions(
    'member_rankings:read_self', 'member_rankings:read_section', 'member_rankings:read_club',
    'member_rankings:read_lf', 'member_rankings:read_global'
  )
  list(@Query() filter: any, @Req() req: any) {
    return this.svc.list(filter, req.user);
  }

  @Get(':memberId/breakdown')
  @RequirePermissions(
    'member_rankings:read_self', 'member_rankings:read_section', 'member_rankings:read_club',
    'member_rankings:read_lf', 'member_rankings:read_global'
  )
  breakdown(@Param('memberId', ParseIntPipe) memberId: number, @Req() req: any) {
    return this.svc.breakdown(memberId, req.user);
  }
}
```

- [ ] **Step 4: Module + register**

```typescript
@Module({
  controllers: [MemberRankingsController],
  providers: [MemberRankingsService /*, plus services from Phase 2/3 imports */],
  exports: [MemberRankingsService],
})
export class MemberRankingsModule {}
```

Importar en `app.module.ts`.

- [ ] **Step 5: Integration tests (controller spec)**

```typescript
describe('MemberRankingsController', () => {
  // Mock JwtAuthGuard + PermissionsGuard + service
  it('GET /member-rankings/me with visibility=hidden → 403', async () => { ... });
  it('GET /member-rankings/me with visibility=self_only → 200 returns own only', async () => { ... });
  it('GET /member-rankings/me with visibility=self_and_top_n → 200 includes top_n', async () => { ... });
  it('GET /member-rankings as member → only own row', async () => { ... });
  it('GET /member-rankings as director-club → filters by club_id', async () => { ... });
  it('GET /member-rankings/:memberId/breakdown wrong scope → 403', async () => { ... });
  it('POST /member-rankings/recalculate as super_admin → 200', async () => { ... });
});
```

Run: `pnpm jest member-rankings.controller.spec.ts` → PASS.

- [ ] **Step 6: Commit**

```bash
git add src/member-rankings/
git commit -m "$(cat <<'EOF'
feat(member-rankings): add REST endpoints (list, me, breakdown, recalculate)

Specific routes ordered before :param routes (engram #1883). Visibility flag enforced
in /me. RBAC scope-filtered list. Integer params via ParseIntPipe.
EOF
)"
```

---

### Task 15: Crear módulo `section-rankings/`

**Files:**
- Create: `sacdia-backend/src/section-rankings/section-rankings.module.ts`
- Create: `sacdia-backend/src/section-rankings/section-rankings.controller.ts`
- Create: `sacdia-backend/src/section-rankings/section-rankings.service.ts`
- Create: `sacdia-backend/src/section-rankings/dto/section-ranking-response.dto.ts`
- Create: `sacdia-backend/src/section-rankings/__tests__/section-rankings.controller.spec.ts`

- [ ] **Step 1: DTO + service**

`section-ranking-response.dto.ts` según spec §6.5 (`SectionRankingResponseDto`).

Service: `list(filter, scope)` + `members(sectionId, scope)`.

- [ ] **Step 2: Controller (orden de rutas crítico)**

```typescript
@Controller('section-rankings')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class SectionRankingsController {
  constructor(private readonly svc: SectionRankingsService) {}

  @Get()
  @RequirePermissions('section_rankings:read_club', 'section_rankings:read_lf', 'section_rankings:read_global')
  list(@Query() filter: any, @Req() req: any) { return this.svc.list(filter, req.user); }

  @Get(':sectionId/members')
  @RequirePermissions('section_rankings:read_club', 'section_rankings:read_lf', 'section_rankings:read_global')
  members(@Param('sectionId', ParseIntPipe) sectionId: number, @Req() req: any) {
    return this.svc.members(sectionId, req.user);
  }
}
```

- [ ] **Step 3: Integration test**

```typescript
describe('SectionRankingsController', () => {
  it('GET /section-rankings as director-club → 200 filtered by club', async () => {});
  it('GET /section-rankings as member → 403', async () => {});
  it('GET /section-rankings/:sectionId/members other club → 403', async () => {});
});
```

- [ ] **Step 4: Commit**

```bash
git add src/section-rankings/
git commit -m "feat(section-rankings): add REST endpoints (list, members) with RBAC scope filter"
```

---

### Task 16: Crear módulo `member-ranking-weights/` CRUD

**Files:**
- Create: `sacdia-backend/src/member-ranking-weights/member-ranking-weights.module.ts`
- Create: `sacdia-backend/src/member-ranking-weights/member-ranking-weights.controller.ts`
- Create: `sacdia-backend/src/member-ranking-weights/member-ranking-weights.service.ts`
- Create: `sacdia-backend/src/member-ranking-weights/dto/create-member-ranking-weights.dto.ts`
- Create: `sacdia-backend/src/member-ranking-weights/dto/update-member-ranking-weights.dto.ts`
- Create: `sacdia-backend/src/member-ranking-weights/__tests__/member-ranking-weights.controller.spec.ts`

- [ ] **Step 1: DTOs con `class-validator`**

```typescript
// create-member-ranking-weights.dto.ts
import { IsInt, IsNumber, IsOptional, Min, Max, ValidateIf } from 'class-validator';

export class CreateMemberRankingWeightsDto {
  @IsOptional() @IsInt() club_type_id?: number;
  @IsOptional() @IsInt() ecclesiastical_year_id?: number;
  @IsNumber() @Min(0) @Max(100) class_pct!: number;
  @IsNumber() @Min(0) @Max(100) evidence_pct!: number;
  @IsNumber() @Min(0) @Max(100) investiture_pct!: number;
  @IsNumber() @Min(0) @Max(100) camporee_pct!: number;
}
```

- [ ] **Step 2: Service con valid SUM=100 + DELETE-default-blocked**

```typescript
async create(dto: CreateMemberRankingWeightsDto) {
  const sum = dto.class_pct + dto.evidence_pct + dto.investiture_pct + dto.camporee_pct;
  if (sum !== 100) throw new BadRequestException('WEIGHTS_SUM_INVALID');
  try {
    return await this.prisma.member_ranking_weights.create({ data: dto });
  } catch (err: any) {
    if (err.code === 'P2002') throw new ConflictException('WEIGHTS_CONFLICT');
    throw err;
  }
}

async remove(id: string) {
  const row = await this.prisma.member_ranking_weights.findUnique({ where: { id } });
  if (!row) throw new NotFoundException();
  if (row.is_default) throw new BadRequestException('DEFAULT_WEIGHTS_NOT_DELETABLE');
  return this.prisma.member_ranking_weights.delete({ where: { id } });
}
```

- [ ] **Step 3: Controller (params UUID → ParseUUIDPipe)**

```typescript
@Controller('member-ranking-weights')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class MemberRankingWeightsController {
  constructor(private readonly svc: MemberRankingWeightsService) {}

  @Get()
  @RequirePermissions('member_ranking_weights:read')
  list() { return this.svc.list(); }

  @Get(':id')
  @RequirePermissions('member_ranking_weights:read')
  findOne(@Param('id', ParseUUIDPipe) id: string) { return this.svc.findOne(id); }

  @Post()
  @RequirePermissions('member_ranking_weights:write')
  create(@Body() dto: CreateMemberRankingWeightsDto) { return this.svc.create(dto); }

  @Patch(':id')
  @RequirePermissions('member_ranking_weights:write')
  update(@Param('id', ParseUUIDPipe) id: string, @Body() dto: UpdateMemberRankingWeightsDto) {
    return this.svc.update(id, dto);
  }

  @Delete(':id')
  @RequirePermissions('member_ranking_weights:write')
  remove(@Param('id', ParseUUIDPipe) id: string) { return this.svc.remove(id); }
}
```

- [ ] **Step 4: Tests**

5 test cases mínimos:
- POST con sum != 100 → 400
- POST duplicate (club_type+year) → 409
- DELETE on default → 400
- POST as field_admin → 403
- GET as super_admin → 200

- [ ] **Step 5: Commit**

```bash
git add src/member-ranking-weights/
git commit -m "feat(member-ranking-weights): add CRUD with sum=100 + default-protect"
```

---

### Task 17: Extender `award-categories` controller con filter `?scope=` + scope validation en POST/PATCH

**Files:**
- Modify: `sacdia-backend/src/award-categories/award-categories.controller.ts`
- Modify: `sacdia-backend/src/award-categories/award-categories.service.ts`
- Modify: `sacdia-backend/src/award-categories/dto/create-award-category.dto.ts`
- Modify: `sacdia-backend/src/award-categories/dto/update-award-category.dto.ts`
- Modify: `sacdia-backend/src/award-categories/__tests__/award-categories.controller.spec.ts`

- [ ] **Step 1: Agregar scope a DTOs**

```typescript
// create-award-category.dto.ts
import { IsEnum, IsOptional } from 'class-validator';

export enum AwardCategoryScope { CLUB = 'club', SECTION = 'section', MEMBER = 'member' }

export class CreateAwardCategoryDto {
  // ...existing...
  @IsOptional() @IsEnum(AwardCategoryScope) scope?: AwardCategoryScope = AwardCategoryScope.CLUB;
}
```

- [ ] **Step 2: Filter `?scope=` en GET**

```typescript
@Get()
list(@Query('scope') scope?: AwardCategoryScope, @Query('is_legacy') legacy?: string) {
  return this.svc.list({ scope, is_legacy: legacy === 'true' });
}
```

Service:
```typescript
async list(filter: { scope?: AwardCategoryScope; is_legacy?: boolean }) {
  return this.prisma.award_categories.findMany({
    where: {
      ...(filter.scope && { scope: filter.scope }),
      ...(filter.is_legacy !== undefined && { is_legacy: filter.is_legacy }),
    },
  });
}
```

- [ ] **Step 3: PATCH scope sólo por admin**

```typescript
@Patch(':id')
update(@Param('id', ParseUUIDPipe) id: string, @Body() dto: UpdateAwardCategoryDto, @Req() req: any) {
  if (dto.scope && !req.user.roles.includes('admin') && !req.user.roles.includes('super_admin')) {
    throw new ForbiddenException('SCOPE_UPDATE_REQUIRES_ADMIN');
  }
  return this.svc.update(id, dto);
}
```

- [ ] **Step 4: Test**

3 tests nuevos:
- GET ?scope=member → only scope=member rows
- POST scope=invalid → 400
- PATCH scope=member as field_admin → 403

- [ ] **Step 5: Commit**

```bash
git add src/award-categories/
git commit -m "feat(award-categories): add scope filter + admin-gated scope updates"
```

---

### Task 18: E2E integration test real Express HTTP a `/member-rankings/` y `/section-rankings/`

**Files:**
- Create: `sacdia-backend/test/member-rankings.e2e-spec.ts`
- Create: `sacdia-backend/test/section-rankings.e2e-spec.ts`

> **Por qué este test**: engram #1888 — tests modulares con `Test.createTestingModule` NO ven bugs de orden de controllers (`ParseUUIDPipe` interceptando `/me` antes que el handler específico). Solo HTTP real a través de Express los detecta.

- [ ] **Step 1: `member-rankings.e2e-spec.ts`**

```typescript
import { Test } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';

describe('MemberRankings E2E', () => {
  let app: INestApplication;
  let adminToken: string;
  let memberToken: string;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = moduleRef.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ transform: true }));
    await app.init();
    // Login flow to get tokens
    adminToken = await loginAs('admin@sacdia.com', 'Sacdia2026!');
    memberToken = await loginAs('member@sacdia.com', 'Sacdia2026!');
  });

  afterAll(async () => { await app.close(); });

  it('GET /member-rankings → 200 (no ParseUUIDPipe order bug)', async () => {
    const res = await request(app.getHttpServer())
      .get('/member-rankings')
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(200);
  });

  it('GET /member-rankings/me as member → 200 with own data', async () => {
    const res = await request(app.getHttpServer())
      .get('/member-rankings/me')
      .set('Authorization', `Bearer ${memberToken}`);
    expect([200, 404]).toContain(res.status); // 404 si aún no recalculado
  });

  it('POST /member-rankings/recalculate as admin → 200/201', async () => {
    const res = await request(app.getHttpServer())
      .post('/member-rankings/recalculate')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({});
    expect([200, 201]).toContain(res.status);
  });

  it('POST /member-rankings/recalculate as member → 403', async () => {
    const res = await request(app.getHttpServer())
      .post('/member-rankings/recalculate')
      .set('Authorization', `Bearer ${memberToken}`)
      .send({});
    expect(res.status).toBe(403);
  });
});
```

- [ ] **Step 2: `section-rankings.e2e-spec.ts`**

```typescript
describe('SectionRankings E2E', () => {
  // similar setup
  it('GET /section-rankings → 200 (no controller order bug)', async () => {});
  it('GET /section-rankings/:sectionId/members → 200 valid integer ID', async () => {});
});
```

- [ ] **Step 3: Run + Commit**

```bash
pnpm jest --config test/jest-e2e.json
git add test/member-rankings.e2e-spec.ts test/section-rankings.e2e-spec.ts
git commit -m "$(cat <<'EOF'
test(rankings): add E2E HTTP tests to detect controller ordering bugs

Modular tests miss ParseUUIDPipe order issues (engram #1888). Real Express
HTTP roundtrip required.
EOF
)"
```

---

## Phase 5 — Admin web UI Fase 1 (sacdia-admin)

> **Cross-repo gate**: NO ejecutar Phase 5 hasta que Phase 4 esté mergeada en sacdia-backend. Cada page sigue `sacdia-admin/DESIGN-SYSTEM.md`: shadcn/ui new-york, dark mode con semantic tokens (`bg-primary/10`, `text-muted-foreground` — nunca `bg-blue-50`), lucide-react icons. CRUD CREATE/EDIT = `Dialog`, DELETE = `AlertDialog`. Reusar componentes 8.4-C cuando aplique.

### Task 19: `/dashboard/member-rankings` — table list + filters + breakdown link

**Files:**
- Create: `sacdia-admin/src/app/(dashboard)/dashboard/member-rankings/page.tsx`
- Create: `sacdia-admin/src/lib/api/member-rankings.ts`
- Create: `sacdia-admin/src/components/member-rankings/MemberRankingScoreBadge.tsx`

- [ ] **Step 1: API client `lib/api/member-rankings.ts`**

```typescript
export interface MemberRanking {
  member_id: number;
  member_name: string;
  club_section_id: number | null;
  section_name: string | null;
  class_score_pct: number | null;
  evidence_score_pct: number | null;
  investiture_score_pct: number | null;
  camporee_score_pct: number | null;
  composite_score_pct: number | null;
  rank_position: number | null;
  awarded_category: { id: string; name: string; color: string; min_pct: number; max_pct: number } | null;
  composite_calculated_at: string | null;
}

export interface MemberRankingPage { data: MemberRanking[]; total: number; page: number; limit: number; }

export async function listMemberRankings(filter: { club_id?: number; year_id?: number; section_id?: number; page?: number; limit?: number }): Promise<MemberRankingPage> {
  const qs = new URLSearchParams(Object.entries(filter).filter(([, v]) => v != null).map(([k, v]) => [k, String(v)]));
  const res = await fetch(`/api/proxy/member-rankings?${qs}`, { credentials: 'include' });
  if (!res.ok) throw new Error('Failed to list member rankings');
  return res.json();
}
```

- [ ] **Step 2: `MemberRankingScoreBadge.tsx`**

```tsx
import { Badge } from '@/components/ui/badge';

export function MemberRankingScoreBadge({ value }: { value: number | null }) {
  if (value === null) return <Badge variant="outline">N/D</Badge>;
  const variant = value >= 85 ? 'success' : value >= 65 ? 'warning' : 'destructive';
  return <Badge variant={variant}>{value.toFixed(2)}%</Badge>;
}
```

- [ ] **Step 3: Page**

```tsx
'use client';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { listMemberRankings, MemberRanking } from '@/lib/api/member-rankings';
import { MemberRankingScoreBadge } from '@/components/member-rankings/MemberRankingScoreBadge';
import { Button } from '@/components/ui/button';
// + filter selects (year/club/section)

export default function MemberRankingsPage() {
  const [rows, setRows] = useState<MemberRanking[]>([]);
  // load with filters, paginate, render table similar to 8.4-C rankings page
  // table: # | Miembro | Sección | Composite badge | Class% | Evidence% | Investiture% | Camporee% | Categoría | Acciones
  return (
    <div className="container mx-auto py-8 space-y-4">
      <h1 className="text-2xl font-semibold">Ranking de miembros</h1>
      {/* filters */}
      <table className="w-full text-sm">
        <thead><tr>{['#','Miembro','Sección','Composite','Clase %','Evidencias %','Investiduras %','Camporees %','Categoría','Acciones'].map(h => <th key={h}>{h}</th>)}</tr></thead>
        <tbody>
          {rows.map((r) => (
            <tr key={r.member_id}>
              <td>{r.rank_position ?? '—'}</td>
              <td>{r.member_name}</td>
              <td>{r.section_name ?? '—'}</td>
              <td><MemberRankingScoreBadge value={r.composite_score_pct} /></td>
              <td>{r.class_score_pct ?? '—'}</td>
              <td>{r.evidence_score_pct ?? '—'}</td>
              <td>{r.investiture_score_pct ?? '—'}</td>
              <td>{r.camporee_score_pct ?? '—'}</td>
              <td>{r.awarded_category?.name ?? '—'}</td>
              <td>
                <Link href={`/dashboard/member-rankings/${r.member_id}/breakdown`}>
                  <Button variant="link">Ver detalle</Button>
                </Link>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
```

- [ ] **Step 4: Smoke + Commit**

```bash
cd sacdia-admin
pnpm dev   # navegar a /dashboard/member-rankings
git add src/app/\(dashboard\)/dashboard/member-rankings src/lib/api/member-rankings.ts src/components/member-rankings
git commit -m "feat(admin): add member rankings list page with score badges"
```

---

### Task 20: `/dashboard/member-rankings/[memberId]/breakdown`

**Files:**
- Create: `sacdia-admin/src/app/(dashboard)/dashboard/member-rankings/[memberId]/breakdown/page.tsx`
- Create: `sacdia-admin/src/components/member-rankings/MemberBreakdownCard.tsx`

- [ ] **Step 1: API call `getMemberBreakdown(memberId)` en `lib/api/member-rankings.ts`**

```typescript
export interface MemberBreakdown extends MemberRanking {
  weights_applied: { class_pct: number; evidence_pct: number; investiture_pct: number; camporee_pct: number; source: string };
  class_breakdown: { completed_count: number; required_count: number; percentage: number | null };
  evidence_breakdown: { attended_count: number; total_evidences: number; percentage: number | null };
  investiture_breakdown: { achieved_count: number; eligible_count: number; percentage: number | null };
  camporee_breakdown: { participated_count: number; total_camporees: number; percentage: number | null };
}

export async function getMemberBreakdown(memberId: number): Promise<MemberBreakdown> {
  const res = await fetch(`/api/proxy/member-rankings/${memberId}/breakdown`, { credentials: 'include' });
  if (!res.ok) throw new Error('Failed to fetch breakdown');
  return res.json();
}
```

- [ ] **Step 2: `MemberBreakdownCard.tsx` (4 cards reutilizables)**

```tsx
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Trophy, BookOpen, Tent, Award } from 'lucide-react';

type Signal = 'class' | 'evidence' | 'investiture' | 'camporee';

const ICONS: Record<Signal, any> = { class: BookOpen, evidence: Trophy, investiture: Award, camporee: Tent };
const TITLES: Record<Signal, string> = { class: 'Clases', evidence: 'Evidencias', investiture: 'Investiduras', camporee: 'Camporees' };

export function MemberBreakdownCard({ signal, percentage, numerator, denominator, weight }:
  { signal: Signal; percentage: number | null; numerator: number; denominator: number; weight: number }) {
  const Icon = ICONS[signal];
  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2"><Icon className="h-5 w-5" />{TITLES[signal]}</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="text-3xl font-semibold">{percentage === null ? 'N/D' : `${percentage.toFixed(2)}%`}</div>
        <div className="text-sm text-muted-foreground">{numerator}/{denominator} · peso {weight}%</div>
      </CardContent>
    </Card>
  );
}
```

- [ ] **Step 3: Page**

```tsx
'use client';
import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import { getMemberBreakdown, MemberBreakdown } from '@/lib/api/member-rankings';
import { MemberBreakdownCard } from '@/components/member-rankings/MemberBreakdownCard';
import { MemberRankingScoreBadge } from '@/components/member-rankings/MemberRankingScoreBadge';

export default function BreakdownPage() {
  const { memberId } = useParams<{ memberId: string }>();
  const [data, setData] = useState<MemberBreakdown | null>(null);
  useEffect(() => { getMemberBreakdown(parseInt(memberId, 10)).then(setData); }, [memberId]);
  if (!data) return <div>Cargando…</div>;

  return (
    <div className="container mx-auto py-8 space-y-6">
      <header>
        <h1 className="text-2xl font-semibold">{data.member_name}</h1>
        <div className="text-muted-foreground">{data.section_name ?? '—'}</div>
        <MemberRankingScoreBadge value={data.composite_score_pct} />
      </header>
      <section className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <MemberBreakdownCard signal="class"       percentage={data.class_breakdown.percentage}       numerator={data.class_breakdown.completed_count}      denominator={data.class_breakdown.required_count}    weight={data.weights_applied.class_pct} />
        <MemberBreakdownCard signal="evidence"    percentage={data.evidence_breakdown.percentage}    numerator={data.evidence_breakdown.attended_count}    denominator={data.evidence_breakdown.total_evidences} weight={data.weights_applied.evidence_pct} />
        <MemberBreakdownCard signal="investiture" percentage={data.investiture_breakdown.percentage} numerator={data.investiture_breakdown.achieved_count} denominator={data.investiture_breakdown.eligible_count} weight={data.weights_applied.investiture_pct} />
        <MemberBreakdownCard signal="camporee"    percentage={data.camporee_breakdown.percentage}    numerator={data.camporee_breakdown.participated_count}denominator={data.camporee_breakdown.total_camporees}weight={data.weights_applied.camporee_pct} />
      </section>
      <section>
        <h2 className="text-lg font-medium">Pesos aplicados</h2>
        <div className="text-sm text-muted-foreground">Fuente: {data.weights_applied.source}</div>
      </section>
    </div>
  );
}
```

- [ ] **Step 4: Commit**

```bash
git add src/app/\(dashboard\)/dashboard/member-rankings/\[memberId\] src/components/member-rankings/MemberBreakdownCard.tsx
git commit -m "feat(admin): add member rankings breakdown drill-down page"
```

---

### Task 21: `/dashboard/section-rankings` — table list + drill-down link

**Files:**
- Create: `sacdia-admin/src/app/(dashboard)/dashboard/section-rankings/page.tsx`
- Create: `sacdia-admin/src/app/(dashboard)/dashboard/section-rankings/[sectionId]/members/page.tsx`
- Create: `sacdia-admin/src/lib/api/section-rankings.ts`

- [ ] **Step 1: API client**

```typescript
export interface SectionRanking {
  club_section_id: number;
  section_name: string;
  composite_score_pct: number | null;
  rank_position: number | null;
  active_member_count: number;
  awarded_category: { id: string; name: string; color: string; min_pct: number; max_pct: number } | null;
  composite_calculated_at: string | null;
}

export async function listSectionRankings(filter: { club_id?: number; year_id?: number }): Promise<{ data: SectionRanking[]; total: number }> {
  const qs = new URLSearchParams(Object.entries(filter).filter(([, v]) => v != null).map(([k, v]) => [k, String(v)]));
  const res = await fetch(`/api/proxy/section-rankings?${qs}`, { credentials: 'include' });
  if (!res.ok) throw new Error('Failed to list section rankings');
  return res.json();
}

export async function listSectionMembers(sectionId: number): Promise<{ section: SectionRanking; members: any[] }> {
  const res = await fetch(`/api/proxy/section-rankings/${sectionId}/members`, { credentials: 'include' });
  if (!res.ok) throw new Error('Failed');
  return res.json();
}
```

- [ ] **Step 2: List page (table + Ver miembros link)**

Tabla con columns: `#`, Sección, Composite badge, Miembros activos, Categoría, Acciones.

- [ ] **Step 3: `/[sectionId]/members` page**

Header con datos de la sección + tabla reutilizando `MemberRankingScoreBadge` para cada miembro.

- [ ] **Step 4: Commit**

```bash
git add src/app/\(dashboard\)/dashboard/section-rankings src/lib/api/section-rankings.ts
git commit -m "feat(admin): add section rankings list + members drill-down pages"
```

---

### Task 22: `/dashboard/member-ranking-weights` — CRUD page

**Files:**
- Create: `sacdia-admin/src/app/(dashboard)/dashboard/member-ranking-weights/page.tsx`
- Create: `sacdia-admin/src/lib/api/member-ranking-weights.ts`
- Create: `sacdia-admin/src/components/member-ranking-weights/MemberWeightsForm.tsx`
- Create: `sacdia-admin/src/components/member-ranking-weights/NewMemberOverrideForm.tsx`

> Reusar `WeightSumIndicator` y `WeightInput` de 8.4-C (`sacdia-admin/src/components/rankings/`). No duplicar.

- [ ] **Step 1: API client**

```typescript
export interface MemberRankingWeights {
  id: string;
  club_type_id: number | null;
  ecclesiastical_year_id: number | null;
  class_pct: number;
  evidence_pct: number;
  investiture_pct: number;
  camporee_pct: number;
  is_default: boolean;
  updated_at: string;
}

export async function listMemberRankingWeights(): Promise<MemberRankingWeights[]> {
  const res = await fetch('/api/proxy/member-ranking-weights', { credentials: 'include' });
  if (!res.ok) throw new Error('Failed');
  return res.json();
}
// + create / update / remove (idéntico al patrón ranking-weights 8.4-C)
```

- [ ] **Step 2: `MemberWeightsForm.tsx`**

Idéntico a `WeightsForm` de 8.4-C pero con 4 inputs distintos (`class_pct`, `evidence_pct`, `investiture_pct`, `camporee_pct`).

- [ ] **Step 3: Page composition (default global card + overrides table + Add override Dialog)**

Estructura similar a `/dashboard/ranking-weights` page de 8.4-C: Card con default global + Card con tabla de overrides + Dialog "Agregar override" usando shadcn `Dialog` + `AlertDialog` para delete.

- [ ] **Step 4: Commit**

```bash
git add src/app/\(dashboard\)/dashboard/member-ranking-weights src/lib/api/member-ranking-weights.ts src/components/member-ranking-weights
git commit -m "feat(admin): add member ranking weights CRUD page (default + overrides)"
```

---

### Task 23: Extender `/dashboard/award-categories` con tabs scope (Club | Section | Member) + Active/Legacy nested

**Files:**
- Modify: `sacdia-admin/src/app/(dashboard)/dashboard/annual-folders/categories/page.tsx`
- Modify: existing form component for award categories (locate first via `rg 'min_composite_pct' sacdia-admin/src`)

- [ ] **Step 1: Tabs primarios scope**

```tsx
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';

const [scopeTab, setScopeTab] = useState<'club' | 'section' | 'member'>('club');
const [legacyTab, setLegacyTab] = useState<'active' | 'legacy'>('active');

<Tabs value={scopeTab} onValueChange={(v) => setScopeTab(v as any)}>
  <TabsList>
    <TabsTrigger value="club">Club</TabsTrigger>
    <TabsTrigger value="section">Sección</TabsTrigger>
    <TabsTrigger value="member">Miembro</TabsTrigger>
  </TabsList>
</Tabs>

<Tabs value={legacyTab} onValueChange={(v) => setLegacyTab(v as any)}>
  <TabsList>
    <TabsTrigger value="active">Activas</TabsTrigger>
    <TabsTrigger value="legacy">Legacy</TabsTrigger>
  </TabsList>
</Tabs>
```

- [ ] **Step 2: Fetch con `?scope=${scopeTab}&is_legacy=${legacyTab === 'legacy'}`**

- [ ] **Step 3: Form (CREATE/EDIT) agregar select scope**

```tsx
<Select value={form.scope} onValueChange={(v) => setForm({ ...form, scope: v })}>
  <SelectTrigger><SelectValue /></SelectTrigger>
  <SelectContent>
    <SelectItem value="club">Club</SelectItem>
    <SelectItem value="section">Sección</SelectItem>
    <SelectItem value="member">Miembro</SelectItem>
  </SelectContent>
</Select>
```

- [ ] **Step 4: Commit**

```bash
git add src/app/\(dashboard\)/dashboard/annual-folders/categories
git commit -m "feat(admin): add scope tabs + active/legacy filter to award categories"
```

---

## Phase 6 — Documentation update (root sacdia)

### Task 24: Update canon docs y registries

**Files:**
- Modify: `docs/canon/runtime-rankings.md`
- Modify: `docs/canon/decisiones-clave.md`
- Modify: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- Modify: `docs/database/SCHEMA-REFERENCE.md`
- Modify: `docs/features/README.md`

- [ ] **Step 1: `docs/canon/runtime-rankings.md` agregar §14**

Nueva sección §14 "Rankings nivel sección + miembro (8.4-A)":
- Pipeline secuencial: club → member → section
- Kill-switch independiente `member_ranking.recalculation_enabled`
- Tablas: `member_rankings`, `section_rankings`, `member_ranking_weights`
- Composite con NULL redistribution
- Política DENSE_RANK NULLS LAST
- Visibility flag `member_visibility`
- Linkear al spec `docs/superpowers/specs/2026-04-29-clasificacion-seccion-miembro-design.md`

- [ ] **Step 2: `docs/canon/decisiones-clave.md` agregar §23**

§23 "Clasificación sección + miembro (8.4-A)" resumiendo Q1–Q9 del spec, weights default 40/25/20/15, polimorfismo `award_categories.scope`, RBAC matrix.

- [ ] **Step 3: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`**

Agregar 4 grupos nuevos (≈10 endpoints):
- `/member-rankings` (GET, GET/me, GET/:memberId/breakdown, POST/recalculate)
- `/section-rankings` (GET, GET/:sectionId/members)
- `/member-ranking-weights` (GET, GET/:id, POST, PATCH/:id, DELETE/:id)
- Extension `?scope=` en `/award-categories`

Total bump 340 → ~350 endpoints.

- [ ] **Step 4: `docs/database/SCHEMA-REFERENCE.md`**

Agregar 3 tablas nuevas (`member_rankings`, `section_rankings`, `member_ranking_weights`) con sus columnas + indexes + constraints. Documentar extension `award_categories.scope`.

- [ ] **Step 5: `docs/features/README.md`**

Entry: "Clasificación sección y miembro — 8.4-A — vigente desde 2026-04-29 — spec en `docs/superpowers/specs/2026-04-29-clasificacion-seccion-miembro-design.md`. Status: backend + admin Fase 1 mergeado, Flutter Fase 2 pendiente.".

- [ ] **Step 6: Commit**

```bash
cd /Users/abner/Documents/development/sacdia
git add docs/canon/runtime-rankings.md \
        docs/canon/decisiones-clave.md \
        docs/api/ENDPOINTS-LIVE-REFERENCE.md \
        docs/database/SCHEMA-REFERENCE.md \
        docs/features/README.md
git commit -m "docs(canon): document 8.4-A section + member rankings runtime"
```

---

## Phase 7 — Smoke E2E + manual validation (post-merge)

### Task 25: Smoke manual contra Neon dev

**Files:** ninguno (validation only)

- [ ] **Step 1: Kill-switch ON validation**

```bash
URL=$(neonctl connection-string development --project-id wispy-hall-32797215)
PSQL=/opt/homebrew/opt/libpq/bin/psql
$PSQL "$URL" -c "UPDATE system_config SET config_value = 'true' WHERE config_key = 'member_ranking.recalculation_enabled';"
```

Login como super_admin: `admin@sacdia.com / Sacdia2026!`

- [ ] **Step 2: Trigger manual recalc**

```bash
TOKEN=<jwt obtenido del login>
curl -X POST http://localhost:3000/api/v1/member-rankings/recalculate \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
```

Esperado: 200 / 201 con `{ triggered: true, year_id: <active> }`.

- [ ] **Step 3: Verificar populate en DB**

```bash
$PSQL "$URL" -c "SELECT COUNT(*) FROM member_rankings WHERE composite_calculated_at >= NOW() - interval '5 min';"
$PSQL "$URL" -c "SELECT COUNT(*) FROM section_rankings WHERE composite_calculated_at >= NOW() - interval '5 min';"
```

- [ ] **Step 4: Validar que AVG sección coincide cálculo manual**

```bash
$PSQL "$URL" -c "
SELECT sr.club_section_id, sr.composite_score_pct AS section_pct,
       AVG(mr.composite_score_pct)::numeric(5,2) AS manual_avg,
       COUNT(*) FILTER (WHERE mr.composite_score_pct IS NOT NULL) AS member_count
FROM section_rankings sr
LEFT JOIN member_rankings mr ON mr.club_section_id = sr.club_section_id
  AND mr.ecclesiastical_year_id = sr.ecclesiastical_year_id
JOIN members m ON m.member_id = mr.member_id AND m.member_status = 'active'
WHERE sr.ecclesiastical_year_id = (SELECT year_id FROM ecclesiastical_years WHERE active = true LIMIT 1)
GROUP BY sr.club_section_id, sr.composite_score_pct
LIMIT 10;
"
```

`section_pct` debe ser igual a `manual_avg` ±0.01.

- [ ] **Step 5: RBAC negative tests**

```bash
# member token de otro miembro al breakdown ajeno → 403
curl -i -X GET http://localhost:3000/api/v1/member-rankings/<otro-member-id>/breakdown -H "Authorization: Bearer $MEMBER_TOKEN"
# expect: 403

# director-club a club ajeno → 403
curl -i -X GET "http://localhost:3000/api/v1/member-rankings?club_id=<otro-club>" -H "Authorization: Bearer $DIR_CLUB_TOKEN"
# expect: 403 o filtrado vacío

# director-lf scope OK
curl -i -X GET http://localhost:3000/api/v1/section-rankings -H "Authorization: Bearer $DIR_LF_TOKEN"
# expect: 200 con secciones del LF
```

- [ ] **Step 6: Visibility=hidden negative test**

```bash
$PSQL "$URL" -c "UPDATE system_config SET config_value = 'hidden' WHERE config_key = 'member_ranking.member_visibility';"

curl -i -X GET http://localhost:3000/api/v1/member-rankings/me -H "Authorization: Bearer $MEMBER_TOKEN"
# expect: 403 con MEMBER_RANKING_HIDDEN

# Restore
$PSQL "$URL" -c "UPDATE system_config SET config_value = 'self_only' WHERE config_key = 'member_ranking.member_visibility';"
```

- [ ] **Step 7: Save engram session summary**

`mem_save` con topic_key `sacdia/feature/8-4-a-shipped`, type=architecture, content: lista de tasks completados, branches mergeadas, smoke results, endpoints HTTP probados, follow-ups pendientes (Fase 2 Flutter, optimización delta-only).

---

## Phase 8 — Mobile Flutter UI Fase 2 (sacdia-app, optional separate wave)

> **NOTA**: Phase 8 es opcional para este plan. Si el usuario quiere ship rápido la Fase 1, comentar tasks 26–28 e indicar que se generará un plan separado cuando arranque Fase 2. Mantener Phase 8 documentada aquí como referencia. Branch sugerida: `feat/section-member-rankings-8-4-a-mobile`.

### Task 26: Flutter repository + provider para member + section rankings

**Files:**
- Create: `sacdia-app/lib/features/rankings/domain/entities/member_ranking.dart`
- Create: `sacdia-app/lib/features/rankings/domain/repositories/member_rankings_repository.dart`
- Create: `sacdia-app/lib/features/rankings/data/repositories/member_rankings_remote_repository.dart`
- Create: `sacdia-app/lib/features/rankings/presentation/providers/my_ranking_provider.dart`
- Create: `sacdia-app/lib/features/rankings/presentation/providers/section_ranking_provider.dart`

- [ ] **Step 1: Domain entity**

`MemberRanking` y `SectionRanking` Dart classes con campos del DTO REST. Implementar `fromJson` / `toJson`.

- [ ] **Step 2: Abstract repository**

```dart
abstract class MemberRankingsRepository {
  Future<MemberMyRankingDto> getMyRanking();
  Future<List<MemberRanking>> getSectionRankings(int sectionId, int yearId);
}
```

- [ ] **Step 3: Implementación remote repository**

HTTP calls a `/api/v1/member-rankings/me` y `/api/v1/section-rankings/:sectionId/members`. Manejar 403 sin throw (retornar empty state cuando `visibility = hidden`).

- [ ] **Step 4: Providers Riverpod**

```dart
final myRankingProvider = FutureProvider.autoDispose<MemberMyRankingDto?>((ref) async {
  final repo = ref.watch(memberRankingsRepositoryProvider);
  try {
    return await repo.getMyRanking();
  } on ForbiddenException {
    return null;
  }
});

final sectionRankingProvider = FutureProvider.autoDispose
  .family<List<MemberRanking>, ({int sectionId, int yearId})>((ref, p) async {
    final repo = ref.watch(memberRankingsRepositoryProvider);
    return repo.getSectionRankings(p.sectionId, p.yearId);
  });
```

- [ ] **Step 5: Tests + Commit**

```bash
cd sacdia-app
flutter test test/features/rankings
git add lib/features/rankings test/features/rankings
git commit -m "feat(rankings): add Flutter repository + Riverpod providers for member + section rankings"
```

---

### Task 27: `MyRankingScreen` con 4 score cards + composite + awarded category

**Files:**
- Create: `sacdia-app/lib/features/rankings/presentation/screens/my_ranking_screen.dart`
- Create: `sacdia-app/lib/features/rankings/presentation/widgets/score_card.dart`

- [ ] **Step 1: ScoreCard widget**

ScoreCard con HugeIconData (per memory rule), value display, label.

- [ ] **Step 2: MyRankingScreen**

Pantalla con composite badge grande + 4 ScoreCards. Si `provider.value == null` (visibility=hidden), mostrar empty state. Si `composite_calculated_at == null`, mostrar "Tu puntaje aún no fue calculado". Si `visibility = self_and_top_n`, mostrar sección Top N con lista compacta.

Pull-to-refresh + auto-dispose providers.

- [ ] **Step 3: Routing**

Agregar ruta `/my-ranking` al GoRouter. Gateada por permiso `member_rankings:read_self`.

- [ ] **Step 4: Tests + Commit**

```bash
flutter test test/features/rankings/my_ranking_screen_test.dart
git add lib/features/rankings/presentation/screens/my_ranking_screen.dart \
        lib/features/rankings/presentation/widgets/score_card.dart
git commit -m "feat(rankings): add MyRankingScreen with composite + 4 score cards"
```

---

### Task 28: `SectionRankingScreen` con lista miembros sección

**Files:**
- Create: `sacdia-app/lib/features/rankings/presentation/screens/section_ranking_screen.dart`

- [ ] **Step 1: Screen**

Header con sección + composite + miembros activos. ListView de members con rank, nombre, composite badge, awarded_category badge.

- [ ] **Step 2: RBAC client-side gating**

Verificar permiso `section_rankings:read_club` (o superior) antes de mostrar la pantalla en el menú. Si no, hide nav item.

- [ ] **Step 3: Tests + Commit**

```bash
git add lib/features/rankings/presentation/screens/section_ranking_screen.dart
git commit -m "feat(rankings): add SectionRankingScreen with member list"
```

---

## Phase 9 — Fase 2 optimization (delta-only) — OPTIONAL

### Task 29: Optimization delta-only — recalc solo miembros con cambios desde último recálculo

**Files:**
- Modify: `sacdia-backend/src/annual-folders/rankings.service.ts`
- Create: `sacdia-backend/prisma/migrations/20260601000000_member_progress_tracking/migration.sql` (si hace falta agregar `last_progress_change`)
- Modify: `sacdia-backend/src/annual-folders/__tests__/rankings.service.member.spec.ts`

- [ ] **Step 1: Migration `ADD COLUMN last_progress_change` en `members`** (si no existe)

```sql
ALTER TABLE members ADD COLUMN last_progress_change TIMESTAMPTZ(6);
CREATE INDEX idx_members_last_progress_change ON members(last_progress_change);
```

Aplicar a 3 branches con TXN atómico (patrón Task 4).

- [ ] **Step 2: Trigger / app-level update de `last_progress_change`**

En cada mutation que afecte señales (member_class_progress, evidence_attendance, investitures, camporee_attendees), set `members.last_progress_change = NOW()` para el `member_id` afectado.

- [ ] **Step 3: Modify `recalculateMemberRankings` para filter delta-only**

```typescript
// Filtrar members donde last_progress_change > last member_rankings.composite_calculated_at
const members = await this.prisma.$queryRaw<...>`
  SELECT m.member_id, m.club_section_id, m.club_id, c.club_type_id
  FROM members m
  JOIN clubs c ON c.club_id = m.club_id
  LEFT JOIN member_rankings mr
    ON mr.member_id = m.member_id AND mr.ecclesiastical_year_id = ${year}
  WHERE c.active = true
    AND (mr.composite_calculated_at IS NULL
         OR m.last_progress_change > mr.composite_calculated_at)
`;
```

- [ ] **Step 4: Test + Commit**

```bash
pnpm jest rankings.service.member.spec.ts
git add prisma/migrations/20260601000000_member_progress_tracking \
        src/annual-folders/rankings.service.ts \
        src/annual-folders/__tests__/rankings.service.member.spec.ts
git commit -m "perf(rankings): delta-only member recalc using last_progress_change"
```

---

## Verification gate (antes de declarar 8.4-A done)

- [ ] **Backend tests**

  ```bash
  cd sacdia-backend
  pnpm jest
  pnpm tsc --noEmit
  pnpm jest --config test/jest-e2e.json
  ```

- [ ] **Admin tests**

  ```bash
  cd sacdia-admin
  pnpm test
  pnpm tsc --noEmit
  ```

- [ ] **Drift check (Neon vs Prisma) en 3 branches**

  ```bash
  cd sacdia-backend
  for BRANCH in development staging production; do
    URL=$(neonctl connection-string $BRANCH --project-id wispy-hall-32797215)
    DATABASE_URL="$URL" pnpm prisma migrate status
  done
  ```

  Expected: las 3 reportan "Database schema is up to date".

- [ ] **Smoke E2E manual** (Task 25 completado)

- [ ] **Engram session summary** con `mem_save` topic_key `sacdia/feature/8-4-a-shipped`.

---

## Decisions log

> Llenar este log al cerrar Phase 0 / Task 2. Sirve como source of truth para todos los tasks subsiguientes.

- **A1** — `members.member_id`: <CONFIRMED INTEGER | DEVIATION>. Acción: <usar Int en Prisma>.
- **A2** — `members.member_status`: <CONFIRMED | MISSING>. Acción: <filtrar 'active' | omitir filtro Fase 1, ADD COLUMN en Fase 2>.
- **A3** — `club_sections.club_section_id`: <CONFIRMED INTEGER>.
- **A4** — `member_class_progress`: <nombre real de tabla>. Columnas: <list>.
- **A5** — `evidence_attendance`: <existe | derivar de annual_folder_section_evaluations | block calculator NULL>.
- **A6** — investiduras per-member: <tabla real>. Columna año: <achieved_year_id | year_id>. Status values: <list>.
- **A7** — camporees per-member: <camporee_attendees | camporee_participants | MISSING>.
- **A8** — rol `member`: <existe en roles | implicado por members table>.
- **A9** — system_config columnas: <`config_key/config_value/config_type` confirmados>.
- **A10** — años: <`ecclesiastical_years.year_id` | `years.year_id`>. Reemplazar referencias en plan.
- **A11** — `investiture_requirements`: <existe | MISSING → workaround>.

---

## Out-of-scope reminder (NO implementar aquí)

- Visibilidad usuario final detallada con permission-aware filtering en endpoint search list (nivel 8.4-B sub-feature dedicada)
- Periodicidad mensual/trimestral del ranking (8.4-D)
- Agrupación regional / multi-club (8.4-E)
- Notificaciones FCM por cambio de ranking del miembro
- Ranking histórico retroactivo
- Export CSV / PDF
- Gráficos evolutivos del score del miembro

---

## Engram patterns referenciados

- **#1204 / #1296 / #1839** — Neon migrations TXN atómico per-archivo, registro manual en `_prisma_migrations`, verify queries pre/post-apply.
- **#1850** — Schema discoveries 8.4-C: `clubs` no tiene `union_id` directo, derivar via `local_fields`.
- **#1883 / PR #28 / #1888** — Controller order bugs: rutas específicas antes que `:param` dinámicos. Tests modulares NO ven `ParseUUIDPipe` order bugs; requiere e2e HTTP real (Task 18).
- **#1839** (cron) — Patrón secuencial en mismo job + kill-switch + try/catch per fase.
