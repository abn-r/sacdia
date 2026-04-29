# Clasificación institucional — Sección y Miembro (8.4-A)

**Fecha**: 2026-04-29
**Estado**: SPEC APROBADO PARA IMPLEMENTACIÓN (post-audit rewrite)
**Origen**: línea 8.4 del roadmap `docs/bases/SACDIA_Bases_del_Proyecto-normalizado.md`, sub-feature **A** (sección + miembro) de la decomposición acordada (C → A → B → D → E)
**Depende de**: 8.4-C shipped y canonizado en `docs/canon/runtime-rankings.md` §13
**Audit completado**: commit `643b694`, ver `docs/superpowers/audits/2026-04-29-section-member-schema-audit.md`
**Stack agentes**: exploración Haiku/Sonnet, planeación Opus, implementación + tests Sonnet
**Engram topic key**: `sacdia/strategy/8-4-a-seccion-miembro-spec`

---

## 1. Resumen ejecutivo

La sub-feature 8.4-C (criterios ampliados) introdujo el composite ranking institucional a nivel club. La sub-feature 8.4-A extiende ese sistema hacia los dos niveles inferiores del organigrama operativo: la **sección de club** (`club_sections`) y el **miembro** —representado internamente por la entidad `enrollments`, no por una tabla `members` que no existe en el schema.

El diseño mantiene tres principios de 8.4-C: normalización 0-100, pesos configurables con CHECK SUM=100, y recálculo cron extendido con kill-switch independiente. Se introduce un pipeline secuencial dentro del mismo job cron: primero los clubs (8.4-C existente), luego los enrollments (miembros), luego las secciones como agregado puro.

**Convención de naming híbrida** (decisión Q-RB1): el schema y las referencias internas usan la entidad real (`enrollment_*`, `enrollment_id`), mientras que las URLs REST, los DTOs, los permission names y las system_config keys usan la convención orientada al usuario final (`member-rankings`, `member_rankings:read_*`). Los servicios contienen la capa de mapeo explícita.

Las señales de cálculo son tres en Fase 1: progreso de clases (`class_module_progress`), estado de investidura binario (`enrollments.investiture_status`) y participación en camporees (`camporee_members`). La señal de evidencias queda bloqueada en Fase 1 —la tabla per-member requerida no existe— y se documenta como sub-feature Fase 2.

Las secciones no tienen calculadores propios: su composite es el AVG de los composite scores de sus enrollments con `composite_score_pct IS NOT NULL`. Una sección sin enrollments calificados recibe composite NULL y queda excluida del ranking positional.

---

## 2. Decisiones cerradas (Q1–Q9 + Q-RB1–Q-RB4 = 13 decisiones)

### Q1 — Sección como agregado puro de enrollments

**Decisión**: `section_rankings.composite_score_pct` = AVG de `enrollment_rankings.composite_score_pct` filtrado por `composite_score_pct IS NOT NULL`. La sección no tiene calculadores propios ni pipeline paralelo de señales. Es un agregado puro sobre el resultado de los enrollments.

**Rationale**: Mantener un pipeline dual crearía redundancia semántica. No existen señales de sección que no sean ya señales del enrollment. El filtro es `IS NOT NULL` en lugar de `member_status = 'active'` porque la columna `member_status` no existe en el schema (auditoría A2): la entidad miembro es `enrollments`, que tiene `enrollments.active BOOLEAN`.

---

### Q2 — 3 señales en Fase 1 (evidencias bloqueadas)

**Decisión**: Tres señales por enrollment en Fase 1:

| Señal | Servicio | Fuente real (post-audit) |
|-------|----------|--------------------------|
| Clases/módulos completados | `ClassScoreService` | `class_module_progress` (audit A4) |
| Investidura (binaria) | `InvestitureScoreService` | `enrollments.investiture_status` (audit A6) |
| Camporees individuales | `CamporeeScoreService` | `camporee_members` (audit A7) |

La cuarta señal (evidencias) queda **bloqueada en Fase 1**: la tabla `evidence_attendance` per-member no existe (audit A5). Su peso de 25% (original) se redistribuye proporcionalmente entre las tres señales disponibles vía la política de redistribución de NULLs del composite.

---

### Q3 — Tabla nueva `enrollment_ranking_weights` (separada de 8.4-C)

**Decisión**: Tabla `enrollment_ranking_weights`, separada de `ranking_weight_configs` (8.4-C). Misma estructura de resolución: row default global (`club_type_id IS NULL, ecclesiastical_year_id IS NULL`) + override opcional por `club_type_id + ecclesiastical_year_id`. Tres columnas de peso: `class_pct + investiture_pct + camporee_pct = 100`. Pesos default Fase 1: `class=50, investiture=30, camporee=20`.

**Rationale**: Los pesos de enrollment son conceptualmente distintos de los pesos institucionales de club (que pesan carpeta/finanzas/camporees/evidencias institucionales). Compartir tabla crearía ambigüedad semántica.

---

### Q4 — RBAC modelo C híbrido + flag de visibilidad + 10 permisos

**Decisión**: Flag `system_config.member_ranking.member_visibility` con tres valores:
- `'self_only'` (default) — el miembro ve solo su propio score
- `'self_and_top_n'` — el miembro ve su score + top N (configurable vía `member_ranking.top_n`, default `5`)
- `'hidden'` — el miembro no puede ver ningún score (`/me` devuelve 403)

El director de club siempre ve todos los miembros de su club, independientemente del flag. Los 10 permisos se detallan en §4.6 con naming externo `member_rankings:*`.

---

### Q5 — UI en dos fases

**Decisión**: Fase 1 = admin web (sacdia-admin). Fase 2 = Flutter (sacdia-app).

Las páginas admin son para supervisión y configuración y no dependen del flag de visibilidad. La UI móvil es la superficie de self-service del miembro y requiere validar la experiencia antes de escalar.

---

### Q6 — Cron secuencial en mismo job + delta-only en Fase 2

**Decisión**: El cron `@Cron('0 2 * * *' UTC)` ejecuta en orden secuencial:
1. `recalculateClubRankings()` (8.4-C existente, sin cambios)
2. Si `member_ranking.recalculation_enabled = 'true'`: `recalculateMemberRankings()`
3. `recalculateSectionAggregates()`

Errores per-enrollment: log + skip (no bloquean al club ni a otros enrollments). Sección que falla en agregación no bloquea las ya procesadas. Fase 2 optimización: delta-only (recalcular solo enrollments con progreso modificado desde el último recálculo).

---

### Q7 — `award_categories.scope` polimórfica

**Decisión**: `ALTER TABLE award_categories ADD COLUMN scope VARCHAR(20) NOT NULL DEFAULT 'club'` con CHECK constraint `scope IN ('club','section','member')`. Backfill existentes con `'club'`. Index `(scope, is_legacy)`.

---

### Q8 — Agregación de sección: AVG enrollments con composite calculado, secciones vacías NULL

**Decisión**: `composite_pct = AVG(enrollment_rankings.composite_score_pct WHERE composite_score_pct IS NOT NULL)`. No existe columna `member_status` (audit A2) —el equivalente es `enrollments.active BOOLEAN`, pero no se filtra en el join de aggregation porque solo enrollments con composite calculado aparecen en `enrollment_rankings`. Sección con 0 enrollments con composite calculado → `composite = NULL`, no aparece en `rank_position`. `NULLS LAST` en `DENSE_RANK`.

---

### Q9 — Kill-switch separado del de 8.4-C

**Decisión**: `system_config.member_ranking.recalculation_enabled` (user-facing key name, default `'true'`). El cron verifica ambas keys:
- `ranking.recalculation_enabled` (8.4-C) — si `'false'`, el job entero no ejecuta
- `member_ranking.recalculation_enabled` (8.4-A) — si `'false'`, solo saltan pasos 2 y 3

Permite dark launch: habilitar el cálculo en backend antes de liberar la UI móvil.

---

### Q-RB1 — Naming híbrido: schema=`enrollment_*`, externo=`member_*`

**Decisión**: Las tablas nuevas en base de datos usan `enrollment_rankings` y `enrollment_ranking_weights` (refleja la entidad real). Las URLs REST, DTOs, permission names y system_config keys usan `member-rankings`, `member_rankings:*`, `member_ranking.*` (convención orientada al usuario final). Los servicios contienen la capa de mapeo: `MemberRankingResponseDto.fromEnrollmentRanking(row)`.

**Rationale**: Los usuarios finales —directores, miembros, admins— piensan en términos de "miembros", no de "enrollments". El schema debe reflejar la realidad de la base de datos; la API debe reflejar el modelo mental del usuario.

---

### Q-RB2 — Evidencias descartadas Fase 1; 3 calculadores con pesos redistribuidos

**Decisión**: Fase 1 contiene exclusivamente tres calculadores. Los pesos default son `class_pct=50, investiture_pct=30, camporee_pct=20`. Si alguno retorna NULL (dato insuficiente), su peso se redistribuye proporcionalmente entre los scores disponibles. Si los tres son NULL, `composite = NULL`.

---

### Q-RB3 — Investidura binaria: `enrollments.investiture_status`

**Decisión**: `InvestitureScoreService` usa señal binaria. `investiture_status = 'INVESTIDO'` → score = 100. `investiture_status = 'IN_PROGRESS'` → score = 0. Sin enrollment para el año → score = NULL (peso redistribuido). No existe tabla `investiture_requirements` (audit A11) ni `member_investitures` (audit A6): el modelo de graduación por requisitos es Fase 2.

---

### Q-RB4 — `camporee_members.status = 'approved'` como "asistió" (locked)

**Decisión**: Valor `'approved'` locked como señal de asistencia confirmada. Alta confianza: 7+ paths en el código existente usan el literal `'approved'` (`CamporeeScoreService` 8.4-C, `rankings.service.ts`, `late-approvals.service.ts`). La tabla `camporee_members` usa `status VARCHAR(20)` con default `'registered'`, sin constraint de enum.

---

## 3. Arquitectura

### 3.1. Diagrama de capas (8.4-A)

```
┌──────────────────────────────────────────────────────────────┐
│                   Cron Job (rankings.service.ts)              │
│   paso 1: recalculateClubRankings()    [8.4-C existente]      │
│   paso 2: recalculateMemberRankings()  [8.4-A nuevo]          │
│   paso 3: recalculateSectionAggregates() [8.4-A nuevo]        │
└──────────────┬───────────────────────────────────────────────┘
               │
       ┌───────┴────────────────────────────────────┐
       │                                            │
       ▼                                            ▼
MemberCompositeScoreService              SectionAggregationService
(schema: EnrollmentCompositeScoreService) │
       │                                  AVG(enrollment_rankings
  ┌────┴────────────────────┐              WHERE composite IS NOT NULL)
  │  ClassScoreService      │
  │  InvestitureScoreService│
  │  CamporeeScoreService   │
  └────────────────────────┘
       │
WeightsResolverService (enrollment_ranking_weights)
       │
MemberRankingResponseDto.fromEnrollmentRanking(row)  [mapping layer]
```

### 3.2. Módulo backend

Módulo NestJS: `src/rankings/member-rankings/` (subpath del módulo existente).

Servicios nuevos:
- `ClassScoreService`
- `InvestitureScoreService`
- `CamporeeScoreService` (per-enrollment, adaptado del club-level)
- `MemberCompositeScoreService` (nombre externo; internamente orquesta los tres calculadores)
- `SectionAggregationService`
- `EnrollmentWeightsResolverService`

Controllers nuevos:
- `MemberRankingsController` — `/api/v1/member-rankings`
- `SectionRankingsController` — `/api/v1/section-rankings`
- `MemberRankingWeightsController` — `/api/v1/member-ranking-weights`

### 3.3. Relación con 8.4-C

8.4-A NO toca `club_annual_rankings`, `ranking_weight_configs`, ni los score-calculators de club. Son dominios paralelos con tablas separadas. El único shared pattern es el cron job (extensión secuencial) y el `WeightsResolver` conceptual (cada uno con su tabla propia). Ver engram #1850 para el patrón de `camporee_clubs` split FKs y la ausencia de `union_id` directo en `clubs`.

---

## 4. Schema

> **IMPORTANTE**: todo el DDL a continuación usa los tipos y nombres de tabla confirmados por la auditoría del commit `643b694`. La tabla `members` no existe; la entidad miembro es `enrollments`. Los años se referencian en `ecclesiastical_years(year_id)`, no en una tabla `years`. Ver §5 para la tabla de desvíos completa.

### 4.1. Tabla `enrollment_rankings`

```sql
CREATE TABLE enrollment_rankings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  enrollment_id INTEGER NOT NULL REFERENCES enrollments(enrollment_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(user_id),  -- desnormalizado para eficiencia del FE
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
  updated_at TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
  UNIQUE(enrollment_id, ecclesiastical_year_id)
);

CREATE INDEX idx_enrollment_rankings_club_year
  ON enrollment_rankings(club_id, ecclesiastical_year_id);

CREATE INDEX idx_enrollment_rankings_section_year
  ON enrollment_rankings(club_section_id, ecclesiastical_year_id);

CREATE INDEX idx_enrollment_rankings_composite
  ON enrollment_rankings(club_id, ecclesiastical_year_id, composite_score_pct DESC);

CREATE INDEX idx_enrollment_rankings_user
  ON enrollment_rankings(user_id);
```

**Notas**:
- Los 3 component scores son NULLABLE. NULL significa "dato insuficiente para calcular", distinto de 0.
- `composite_score_pct` es NULLABLE. NULL si todos los componentes son NULL.
- `user_id` desnormalizado: permite consultas del endpoint `/me` y filtros RBAC por usuario sin JOIN a `enrollments`.
- `UNIQUE(enrollment_id, ecclesiastical_year_id)` permite upsert idempotente.
- No existe columna `evidence_score_pct` en Fase 1 (señal bloqueada por audit A5). Se agrega en migration dedicada de Fase 2.

### 4.2. Tabla `section_rankings`

```sql
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
  updated_at TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
  UNIQUE(club_section_id, ecclesiastical_year_id)
);

CREATE INDEX idx_section_rankings_club_year
  ON section_rankings(club_id, ecclesiastical_year_id);

CREATE INDEX idx_section_rankings_composite
  ON section_rankings(club_id, ecclesiastical_year_id, composite_score_pct DESC NULLS LAST);
```

**Notas**:
- `composite_score_pct` NULLABLE. Sección sin enrollments con composite calculado → NULL.
- `active_enrollment_count` permite mostrar contexto ("N integrantes") sin join adicional a `enrollment_rankings`.
- `NULLS LAST` en el índice de composite alinea con la política `DENSE_RANK` (§7.7).

### 4.3. Tabla `enrollment_ranking_weights`

```sql
CREATE TABLE enrollment_ranking_weights (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  club_type_id INTEGER REFERENCES club_types(club_type_id),
  ecclesiastical_year_id INTEGER REFERENCES ecclesiastical_years(year_id),
  class_pct NUMERIC(5,2) NOT NULL,
  investiture_pct NUMERIC(5,2) NOT NULL,
  camporee_pct NUMERIC(5,2) NOT NULL,
  is_default BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
  CHECK (class_pct + investiture_pct + camporee_pct = 100),
  UNIQUE(club_type_id, ecclesiastical_year_id)
);

-- Seed: default global (Fase 1: 3 señales)
INSERT INTO enrollment_ranking_weights
  (class_pct, investiture_pct, camporee_pct, is_default)
VALUES
  (50, 30, 20, true)
ON CONFLICT DO NOTHING;
```

**Notas**:
- `club_type_id IS NULL AND ecclesiastical_year_id IS NULL` = row default global.
- No incluye `evidence_pct` en Fase 1 (señal bloqueada). La migration de Fase 2 añade la columna y actualiza el CHECK.
- `is_default = true` es flag informativo; la lógica de resolución usa IS NULL en `club_type_id`.

### 4.4. Extensión `award_categories.scope`

```sql
ALTER TABLE award_categories
  ADD COLUMN scope VARCHAR(20) NOT NULL DEFAULT 'club';

ALTER TABLE award_categories
  ADD CONSTRAINT chk_award_scope
  CHECK (scope IN ('club', 'section', 'member'));

-- NOT NULL DEFAULT 'club' garantiza que todas las filas preexistentes
-- ya tienen scope='club'. El UPDATE es defensivo y documenta la intención.
-- UPDATE award_categories SET scope = 'club' WHERE scope IS NULL;

CREATE INDEX idx_award_categories_scope
  ON award_categories(scope, is_legacy);
```

**Notas**:
- Las categorías existentes conservan `scope = 'club'` por defecto. No se rompe 8.4-C.
- El admin debe crear categorías con `scope = 'member'` y `scope = 'section'` para que 8.4-A asigne categorías.

### 4.5. Keys nuevas en `system_config`

```sql
-- Columnas confirmadas en audit A9: config_key, config_value, config_type, description, updated_at
INSERT INTO system_config (config_key, config_value, config_type, description) VALUES
  ('member_ranking.recalculation_enabled', 'true',      'boolean', 'Kill-switch enrollment+section ranking recalc'),
  ('member_ranking.member_visibility',     'self_only',  'string',  'self_only | self_and_top_n | hidden'),
  ('member_ranking.top_n',                 '5',          'integer', 'How many top to show if visibility=self_and_top_n')
ON CONFLICT (config_key) DO NOTHING;
```

### 4.6. Permisos nuevos — `permissions` + grants en `role_permissions`

```sql
-- Columna confirmada en audit A8: permission_name (NO 'name')
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
ON CONFLICT DO NOTHING;

-- Grants por rol: role_name = 'member', role_id UUID = 9567fef6-8091-494a-ac1c-fb3716ed2091 (audit A8)
-- Ejemplo de grant al rol member:
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
  FROM roles r, permissions p
  WHERE r.role_name = 'member'
    AND p.permission_name = 'member_rankings:read_self'
ON CONFLICT DO NOTHING;
-- (Repetir para cada fila de la matriz RBAC §4.7)
```

### 4.7. Matriz RBAC

| Permiso | member | asst-club | dir-club | dir-dia | asst-dia | dir-lf | asst-lf | dir-union | asst-union | admin | super_admin |
|---------|:------:|:---------:|:--------:|:-------:|:--------:|:------:|:-------:|:---------:|:----------:|:-----:|:-----------:|
| `member_rankings:read_self` | ✓ | | | | | | | | | ✓ | ✓ |
| `member_rankings:read_section` | | ✓ | ✓ | | | | | | | ✓ | ✓ |
| `member_rankings:read_club` | | ✓ | ✓ | ✓ | ✓ | | | | | ✓ | ✓ |
| `member_rankings:read_lf` | | | | | | ✓ | ✓ | | | ✓ | ✓ |
| `member_rankings:read_global` | | | | | | | | ✓ | ✓ | ✓ | ✓ |
| `member_ranking_weights:read` | | | | | | ✓ | | ✓ | ✓ | ✓ | ✓ |
| `member_ranking_weights:write` | | | | | | | | | | ✓ | ✓ |
| `section_rankings:read_club` | | ✓ | ✓ | ✓ | ✓ | | | | | ✓ | ✓ |
| `section_rankings:read_lf` | | | | | | ✓ | ✓ | | | ✓ | ✓ |
| `section_rankings:read_global` | | | | | | | | ✓ | ✓ | ✓ | ✓ |

---

## 5. Schema audit notes

> **Audit completado 2026-04-29** — commit `643b694`, fuente: `docs/superpowers/audits/2026-04-29-section-member-schema-audit.md`. El spec original asumía entidades que no existen en Neon dev. Esta sección documenta los desvíos confirmados y las decisiones tomadas. Cada sección del spec anterior a este rewrite ha sido corregida en su totalidad.

| # | Ítem spec original | Estado | Realidad confirmada | Decisión tomada |
|---|--------------------|--------|---------------------|-----------------|
| A1 | `members.member_id INTEGER` | DEVIATION | No existe tabla `members`. Entidad = `enrollments.enrollment_id` (INTEGER) + `users.user_id` (UUID) | FK usa `enrollment_id INTEGER REFERENCES enrollments(enrollment_id)`. Tabla renombrada a `enrollment_rankings`. |
| A2 | `members.member_status` | MISSING | No existe `member_status`. Equivalente: `enrollments.active BOOLEAN` + `enrollments.investiture_status` enum | Filtro de miembro activo = `enrollments.active = true`. Sin migration de ADD COLUMN necesaria. Agregación por sección filtra `IS NOT NULL` en composite. |
| A3 | `club_sections.club_section_id INTEGER` | CONFIRMED | `club_section_id INTEGER` — confirmado | Sin cambio. FK `INTEGER REFERENCES club_sections(club_section_id)`. |
| A4 | `member_class_progress` | DEVIATION | Tabla real: `class_module_progress` (cols: `module_progress_id INTEGER`, `user_id UUID`, `class_id INTEGER`, `module_id INTEGER`, `score DOUBLE PRECISION`, `active BOOLEAN`, `enrollment_id INTEGER`). Sin columna `year_id` directa. | `ClassScoreService` usa `class_module_progress JOIN enrollments USING (enrollment_id)` para filtrar por `ecclesiastical_year_id`. "Completado" = `active = true AND score IS NOT NULL` (a confirmar en OQ-A4a). |
| A5 | `evidence_attendance` per-member | MISSING | No existe tabla de asistencia per-member. Las tablas de evidencia existentes (`evidence_files`, `annual_folder_evidences`, `requirement_evidence`) son a nivel de archivos de progreso o carpetas, no per-member. | `EvidenceScoreService` bloqueado en Fase 1. Peso redistribuido al composite. Requiere decisión de negocio para Fase 2. |
| A6 | `investitures` / `member_investitures` | MISSING/DEVIATION | No existen. Datos en `enrollments.investiture_status` (enum `IN_PROGRESS` / `INVESTIDO`) + `investiture_validation_history`. | `InvestitureScoreService` usa señal binaria: `INVESTIDO` = 100, `IN_PROGRESS` = 0, sin enrollment del año = NULL. |
| A7 | `camporee_attendees` / `camporee_participants` | DEVIATION | Tabla real: `camporee_members` (`camporee_member_id INTEGER`, `camporee_id INTEGER`, `camporee_type VARCHAR`, `user_id UUID`, `status VARCHAR(20)` default `'registered'`). Sin datos en dev para validar valores de `status`. | `CamporeeScoreService` usa `camporee_members WHERE user_id = $userUuid AND status = 'approved'` (Q-RB4: valor locked con alta confianza por 7+ code paths existentes). |
| A8 | rol `member` en `roles` | CONFIRMED (estructura diferente) | Existe: `role_id UUID 9567fef6-8091-494a-ac1c-fb3716ed2091`, `role_name='member'`. Sin columna `code`. `permissions` usa `permission_name`, no `name`. | Seeds usan UUID literal del rol `member`. `INSERT INTO permissions (permission_name, ...)`. |
| A9 | `system_config` columns | CONFIRMED | `config_key`, `config_value`, `description`, `config_type`, `updated_at`. Sin columna `id` explícita. | INSERT usa `ON CONFLICT (config_key)`. Columna `description` incluida en seeds. |
| A10 | `years` vs `ecclesiastical_years` | CONFIRMED | `years` no existe. `ecclesiastical_years` con PK `year_id INTEGER`. Camporees usan `ecclesiastical_year INTEGER` (referencia informal, sin FK formal). | FK en 3 tablas nuevas: `ecclesiastical_year_id INTEGER REFERENCES ecclesiastical_years(year_id)`. |
| A11 | `investiture_requirements` | MISSING | No existe. Solo `investiture_config` e `investiture_validation_history`. | `InvestitureScoreService` adopta modelo binario (ver A6). `eligible_count` no calculable. Documentado para Fase 2 si la dirección define requisitos por club_type. |

**Nota crítica A1**: el cambio de `member_id` → `enrollment_id` y de `member_rankings` → `enrollment_rankings` es el desvío más importante. Afecta el nombre de la tabla principal, todos los calculadores (reciben `enrollmentId`), los índices, los UNIQUE constraints, el cron, y el mapping layer en DTOs.

**Nota A4 — tabla `class_module_progress`**: existe también `class_section_progress` con columna `status USER-DEFINED` y `active BOOLEAN`. La elección definitiva entre usar `class_module_progress.active` vs `class_section_progress.status = 'completed'` como denominador de `ClassScoreService` queda como OQ-A4a (§15).

---

## 6. Endpoints REST + DTOs + RBAC

### 6.1. Convención de naming y pipes

Las URLs y params externos usan la convención `member-rankings` (externo). Los IDs de parámetros:
- `enrollment_id` (INTEGER) → `ParseIntPipe` — **NO** `ParseUUIDPipe`
- `club_section_id` (INTEGER) → `ParseIntPipe`
- `id` de `enrollment_rankings.id` (UUID) → `ParseUUIDPipe`
- `id` de `enrollment_ranking_weights.id` (UUID) → `ParseUUIDPipe`

Ver engram #1883 / #1888 — bug de orden de rutas con `ParseUUIDPipe` en 8.4-C. Los controllers de 8.4-A deben declarar rutas estáticas (ej. `/me`, `/recalculate`) ANTES de las rutas dinámicas (ej. `/:enrollmentId/breakdown`).

### 6.2. Member Rankings — `/api/v1/member-rankings`

#### `GET /api/v1/member-rankings`

Parámetros: `?club_id=&ecclesiastical_year_id=&section_id=&page=&limit=`

RBAC scope-filtrado:
- `member_rankings:read_self` → solo el propio registro (ignorar filtros de club/sección)
- `member_rankings:read_section` → filtra por `club_section_id` del rol del caller
- `member_rankings:read_club` → filtra por `club_id` del rol del caller
- `member_rankings:read_lf` → filtra por `local_field_id` del caller
- `member_rankings:read_global` → sin restricción de scope

Respuesta paginada: `{ data: MemberRankingResponseDto[], total, page, limit }`

#### `GET /api/v1/member-rankings/me`

Atajo para el enrollment del usuario autenticado. Respeta el flag `member_visibility`:
- `'hidden'` → 403 `MEMBER_RANKING_HIDDEN`
- `'self_only'` → devuelve solo el propio registro
- `'self_and_top_n'` → devuelve propio + top N (N de `member_ranking.top_n`)

RBAC: `member_rankings:read_self`. Respuesta: `MemberMyRankingDto`.

#### `GET /api/v1/member-rankings/:enrollmentId/breakdown`

`ParseIntPipe` en `:enrollmentId`. Drill-down del score: 3 breakdowns + weights aplicados.

RBAC: mismo scope que `GET /`. Verificar que el caller puede ver el enrollment solicitado.

Respuesta: `MemberBreakdownDto`.

#### `POST /api/v1/member-rankings/recalculate`

Body: `{ ecclesiastical_year_id?: number, club_id?: number }`

RBAC: `member_ranking_weights:write`. Respuesta: `{ triggered: true, ecclesiastical_year_id: number, club_id?: number }`

Si kill-switch `member_ranking.recalculation_enabled = 'false'` → HTTP 400 `RECALCULATION_DISABLED`.

---

### 6.3. Section Rankings — `/api/v1/section-rankings`

#### `GET /api/v1/section-rankings`

Parámetros: `?club_id=&ecclesiastical_year_id=&page=&limit=`

RBAC scope-filtrado con permisos `section_rankings:read_*`.

Respuesta paginada: `{ data: SectionRankingResponseDto[], total, page, limit }`

#### `GET /api/v1/section-rankings/:sectionId/members`

`ParseIntPipe` en `:sectionId`. Drill-down: enrollments de la sección ordenados por `rank_position ASC NULLS LAST`.

RBAC: `section_rankings:read_club` mínimo.

Respuesta: `{ section: SectionRankingResponseDto, members: MemberRankingResponseDto[] }`

---

### 6.4. Member Ranking Weights — `/api/v1/member-ranking-weights`

| Método | Path | RBAC | Descripción |
|--------|------|------|-------------|
| `GET` | `/` | `member_ranking_weights:read` | Lista default + overrides |
| `GET` | `/:id` | `member_ranking_weights:read` | Detalle (`ParseUUIDPipe`) |
| `POST` | `/` | `member_ranking_weights:write` | Crear override por `club_type_id + ecclesiastical_year_id` |
| `PATCH` | `/:id` | `member_ranking_weights:write` | Actualizar weights; re-valida CHECK SUM=100 |
| `DELETE` | `/:id` | `member_ranking_weights:write` | Eliminar override; default global no eliminable (400) |

Validaciones:
- `class_pct + investiture_pct + camporee_pct = 100` → HTTP 400 `WEIGHTS_SUM_INVALID`
- Ningún peso individual puede ser negativo → HTTP 400
- UNIQUE `(club_type_id, ecclesiastical_year_id)` → HTTP 409 `WEIGHTS_CONFLICT`
- DELETE sobre row con `is_default = true` → HTTP 400 `DEFAULT_WEIGHTS_NOT_DELETABLE`

---

### 6.5. Award Categories — extensión (filtro por scope)

```
GET    /api/v1/award-categories?scope=club|section|member&is_legacy=false
POST   /api/v1/award-categories   -- body incluye campo scope (enum, required, default 'club')
PATCH  /api/v1/award-categories/:id  -- permite update de scope solo si caller tiene rol admin
```

---

### 6.6. DTOs

```typescript
// MemberRankingResponseDto — wraps enrollment_rankings row + campos de display
// Capa de mapeo: MemberRankingResponseDto.fromEnrollmentRanking(row: EnrollmentRanking)
interface MemberRankingResponseDto {
  enrollment_id: number;            // PK de enrollments — identificador principal
  user_id: string;                  // para /me + autenticación
  member_name: string;              // JOIN desde users.name
  club_section_id: number | null;
  section_name: string | null;
  class_score_pct: number | null;
  investiture_score_pct: number | null;
  camporee_score_pct: number | null;
  composite_score_pct: number | null;
  rank_position: number | null;
  awarded_category: {
    id: string;
    name: string;
    color: string;
    min_pct: number;
    max_pct: number;
  } | null;
  composite_calculated_at: string | null; // ISO 8601
}

// MemberBreakdownDto
interface MemberBreakdownDto extends MemberRankingResponseDto {
  weights_applied: {
    class_pct: number;
    investiture_pct: number;
    camporee_pct: number;
    source: 'default' | `override:club_type_${number}+year_${number}`;
  };
  class_breakdown: {
    completed_count: number;
    required_count: number;
    percentage: number | null;
  };
  investiture_breakdown: {
    investiture_status: 'INVESTIDO' | 'IN_PROGRESS' | null;
    score: 100 | 0 | null;
  };
  camporee_breakdown: {
    participated_count: number;
    total_camporees: number;
    percentage: number | null;
  };
}

// SectionRankingResponseDto
interface SectionRankingResponseDto {
  club_section_id: number;
  section_name: string;
  composite_score_pct: number | null;
  rank_position: number | null;
  active_enrollment_count: number;
  awarded_category: {
    id: string;
    name: string;
    color: string;
    min_pct: number;
    max_pct: number;
  } | null;
  composite_calculated_at: string | null;
}

// MemberMyRankingDto (móvil + admin /me endpoint)
interface MemberMyRankingDto {
  member: MemberRankingResponseDto;
  visibility_mode: 'self_only' | 'self_and_top_n' | 'hidden';
  top_n?: Array<{
    member_name: string;  // OQ1: privacidad — ver §15
    composite_score_pct: number | null;
    rank_position: number | null;
  }>;
}
```

---

## 7. Calculadores (lógica precisa)

### 7.1. `ClassScoreService.calculate(enrollmentId, ecclesiasticalYearId)`

Fuente: `class_module_progress` (nombre confirmado en audit A4 — NO `member_class_progress`).

```typescript
// Obtener enrollment para acceder a class_id
const enrollment = await prisma.enrollments.findUnique({
  where: { enrollment_id: enrollmentId }
});
if (!enrollment) return null;

// Completado = active=true con score registrado (ver OQ-A4a en §15)
const completedCount = await prisma.class_module_progress.count({
  where: {
    enrollment_id: enrollmentId,
    active: true,
    score: { not: null }
    // year vía enrollment.ecclesiastical_year_id ya filtrado por enrollmentId
  }
});

// Requeridos: módulos de la clase del enrollment
const requiredCount = await prisma.class_modules.count({
  where: { class_id: enrollment.class_id }
  // is_required: true — columna a confirmar en OQ-A4a
});

if (requiredCount === 0) return null;
return Math.min((completedCount / requiredCount) * 100, 100);
```

NULL si `requiredCount = 0`. Nunca lanza excepción por dato faltante.

---

### 7.2. `InvestitureScoreService.calculate(enrollmentId, ecclesiasticalYearId)` — BINARIO

Fuente: `enrollments.investiture_status` (audit A6). No existe `investiture_requirements` (audit A11).

```typescript
const enrollment = await prisma.enrollments.findFirst({
  where: {
    enrollment_id: enrollmentId,
    ecclesiastical_year_id: ecclesiasticalYearId
  }
});
if (!enrollment) return null;
return enrollment.investiture_status === 'INVESTIDO' ? 100 : 0;
```

- `'INVESTIDO'` → 100
- `'IN_PROGRESS'` → 0
- Sin enrollment para el año → NULL (peso redistribuido en composite)

---

### 7.3. `CamporeeScoreService.calculate(enrollmentId, ecclesiasticalYearId)`

Fuente: `camporee_members` (audit A7). Valor `'approved'` locked como "asistió" (Q-RB4).

```typescript
// Obtener user_id del enrollment (camporee_members usa user_id UUID)
const enrollment = await prisma.enrollments.findFirst({
  where: { enrollment_id: enrollmentId, ecclesiastical_year_id: ecclesiasticalYearId }
});
if (!enrollment) return null;

const userId = enrollment.user_id;

// Numerador: camporees aprobados del usuario
const participatedCount = await prisma.camporee_members.count({
  where: {
    user_id: userId,
    status: 'approved'
    // camporee_id debe estar en el scope del año — ver lógica de denominador
  }
});

// Denominador: camporees disponibles para el club en el año
// clubs NO tiene union_id directo (engram #1850) → resolver vía local_fields
const clubData = await prisma.clubs.findUnique({
  where: { club_id: enrollment.club_id },  // enrollment tiene club_id vía classes → clubs
  include: { local_fields: { select: { union_id: true } } }
});
const resolvedUnionId = clubData?.local_fields?.union_id ?? null;

// local_camporees y union_camporees usan campo ecclesiastical_year INTEGER (sin FK formal — audit A10)
const [localCamporees, unionCamporees] = await Promise.all([
  prisma.local_camporees.findMany({
    where: { ecclesiastical_year: ecclesiasticalYearId, active: true,
             OR: [{ union_id: resolvedUnionId }, { union_id: null }] },
    select: { local_camporee_id: true }
  }),
  prisma.union_camporees.findMany({
    where: { ecclesiastical_year: ecclesiasticalYearId, active: true,
             OR: [{ union_id: resolvedUnionId }, { union_id: null }] },
    select: { union_camporee_id: true }
  })
]);

const totalCamporees = localCamporees.length + unionCamporees.length;
if (totalCamporees === 0) return null;

return Math.min((participatedCount / totalCamporees) * 100, 100);
```

---

### 7.4. `MemberCompositeScoreService.calculate(enrollmentId, ecclesiasticalYearId)`

(Nombre externo; internamente `EnrollmentCompositeScoreService`.)

```typescript
// 1. Resolver weights
const weights = await EnrollmentWeightsResolverService.resolve({
  clubTypeId: enrollment.class.club_type_id,
  ecclesiasticalYearId
});
// Resolve: override(club_type_id, year) → override(club_type_id, null) → default global

// 2. Calcular 3 scores en paralelo
const [classScore, investitureScore, camporeeScore] = await Promise.all([
  ClassScoreService.calculate(enrollmentId, ecclesiasticalYearId),
  InvestitureScoreService.calculate(enrollmentId, ecclesiasticalYearId),
  CamporeeScoreService.calculate(enrollmentId, ecclesiasticalYearId)
]);

const scores = [classScore, investitureScore, camporeeScore];
const weightValues = [weights.class_pct, weights.investiture_pct, weights.camporee_pct];

// 3. Redistribución de NULLs (algoritmo preciso)
let totalWeightUsed = 0;
let weightedSum = 0;

for (let i = 0; i < scores.length; i++) {
  if (scores[i] !== null) {
    weightedSum += scores[i] * weightValues[i];
    totalWeightUsed += weightValues[i];
  }
}

if (totalWeightUsed === 0) return null;  // todos NULL

// composite = weighted_sum / total_weight_used (no dividir entre 100 porque ya son pct * peso)
const composite = weightedSum / totalWeightUsed;
return Math.min(Math.max(composite, 0), 100);
```

**Política de redistribución de NULLs**: si un score es NULL por datos insuficientes, su peso se redistribuye proporcionalmente entre los scores disponibles. Esto evita penalizar al enrollment por señales sin datos (un miembro nuevo sin camporees no recibe 0 en camporee; ese peso se distribuye a las otras señales disponibles).

---

### 7.5. `SectionAggregationService.aggregate(sectionId, ecclesiasticalYearId)`

```typescript
// Query: AVG de enrollment_rankings con composite calculado para la sección
// NO filtro por member_status (columna no existe — audit A2)
const rows = await prisma.enrollment_rankings.findMany({
  where: {
    club_section_id: sectionId,
    ecclesiastical_year_id: ecclesiasticalYearId,
    composite_score_pct: { not: null }
  },
  select: { composite_score_pct: true }
});

if (rows.length === 0) {
  // composite NULL, sección excluida del ranking positional
  return { composite_score_pct: null, active_enrollment_count: 0 };
}

const avg = rows.reduce((sum, r) => sum + r.composite_score_pct!, 0) / rows.length;
return {
  composite_score_pct: Math.min(Math.max(avg, 0), 100),
  active_enrollment_count: rows.length
};
```

---

### 7.6. Asignación de `rank_position` (DENSE_RANK)

Aplicar después de todos los upserts de enrollments de un club, y después de todos los upserts de secciones de un club:

```sql
-- Para enrollment_rankings:
UPDATE enrollment_rankings er
SET rank_position = sub.rnk
FROM (
  SELECT id,
    DENSE_RANK() OVER (
      PARTITION BY club_id, ecclesiastical_year_id
      ORDER BY composite_score_pct DESC NULLS LAST
    ) AS rnk
  FROM enrollment_rankings
  WHERE ecclesiastical_year_id = $1
) sub
WHERE er.id = sub.id;

-- Para section_rankings:
UPDATE section_rankings sr
SET rank_position = sub.rnk
FROM (
  SELECT id,
    DENSE_RANK() OVER (
      PARTITION BY club_id, ecclesiastical_year_id
      ORDER BY composite_score_pct DESC NULLS LAST
    ) AS rnk
  FROM section_rankings
  WHERE ecclesiastical_year_id = $1
) sub
WHERE sr.id = sub.id;
```

Política: empates comparten rank. `NULLS LAST` garantiza que secciones vacías y enrollments sin composite queden al final. Semántica densa: mismo algoritmo que 8.4-C.

---

## 8. Cron + flujo de recálculo + dark launch

### 8.1. Orden de ejecución

```typescript
@Cron('0 2 * * *', { name: 'rankings-recalculation', timeZone: 'UTC' })
async handleRankingsRecalculation(): Promise<void> {
  // Kill-switch global (8.4-C)
  const globalEnabled = await systemConfig.get('ranking.recalculation_enabled');
  if (globalEnabled === 'false') {
    logger.warn('[rankings] Global kill-switch off — skipping all recalculation');
    return;
  }

  // Paso 1: clubs (8.4-C existente, sin cambios)
  await this.recalculateClubRankings();

  // Kill-switch 8.4-A
  const memberEnabled = await systemConfig.get('member_ranking.recalculation_enabled');
  if (memberEnabled === 'false') {
    logger.warn('[rankings] member_ranking kill-switch off — skipping steps 2 and 3');
    return;
  }

  // Paso 2: enrollments
  try {
    await this.recalculateMemberRankings();
  } catch (err) {
    logger.error('[member-rankings] recalculateMemberRankings failed, continuing to section aggregates', err);
  }

  // Paso 3: secciones (corre aunque paso 2 falle parcialmente — datos parciales en DB son usables)
  await this.recalculateSectionAggregates();
}
```

### 8.2. `recalculateMemberRankings(yearId?)`

```
1. Resolver ecclesiastical_year_id activo si no se proveyó
2. Listar clubs activos con enrollments del año
3. Para cada club (batched por chunks de 50 clubs):
   a. Listar enrollments del club para el año (WHERE active = true)
   b. Para cada enrollment:
      i.  Calcular 3 component scores en Promise.all
      ii. Calcular composite con redistribución de NULLs
      iii.UPSERT enrollment_rankings ON CONFLICT (enrollment_id, ecclesiastical_year_id)
      iv. Si error: logger.error({enrollment_id, ecclesiastical_year_id, error}) + skip
   c. Asignar rank_position por club + year con DENSE_RANK NULLS LAST (SQL UPDATE)
4. Log estructurado al final (§13)
```

### 8.3. `recalculateSectionAggregates(yearId?)`

```
1. Resolver ecclesiastical_year_id activo si no se proveyó
2. Listar club_sections activas que tienen enrollments en enrollment_rankings del año
3. Para cada sección:
   a. SectionAggregationService.aggregate(sectionId, yearId)
   b. UPSERT section_rankings ON CONFLICT (club_section_id, ecclesiastical_year_id)
   c. Si error: logger.error({club_section_id, ecclesiastical_year_id, error}) + skip
4. Asignar rank_position por club + year con DENSE_RANK NULLS LAST
5. Log estructurado al final
```

### 8.4. Recálculo manual

```
POST /api/v1/member-rankings/recalculate
Body: { ecclesiastical_year_id?: number, club_id?: number }

Si club_id → scope reducido al club
Si kill-switch member_ranking.recalculation_enabled = 'false' → HTTP 400
Rate limit: 1/5min (mismo patrón 8.4-C)
```

### 8.5. Idempotencia

- `UPSERT ON CONFLICT (enrollment_id, ecclesiastical_year_id)` — idempotente por enrollment.
- `UPSERT ON CONFLICT (club_section_id, ecclesiastical_year_id)` — idempotente por sección.
- Re-ejecuciones producen el mismo resultado si los datos fuente no cambiaron.

### 8.6. Dark launch

El kill-switch `member_ranking.recalculation_enabled` se puede setear a `'true'` en backend mientras la UI móvil (Fase 2) aún no está publicada. Los datos se calculan y persisten en `enrollment_rankings` / `section_rankings`; el admin puede verificarlos desde la UI web (Fase 1) antes de habilitar la UI del miembro.

---

## 9. UI Fase 1 — Admin web (sacdia-admin)

### 9.1. `/dashboard/member-rankings`

**Componentes principales**:
- Selector de año eclesiástico + selector de club + selector de sección (cascaded)
- `<DataTable>` con columnas: `#` (rank_position) | Miembro | Sección | **Composite %** (badge color) | Clase % | Investidura | Camporees % | Categoría | Acciones
- Botón "Ver detalle" por fila → navega a breakdown (ruta dinámica o drawer lateral)
- Vacío state si no hay rankings calculados para el filtro seleccionado

**Comportamiento de badges**: verde ≥85, ámbar 65-84, rojo <65 (cutoffs más laxos que clubs — ver §11.4 seeds).

**RBAC UI**: el selector de club/sección se limita automáticamente al scope del usuario logueado.

### 9.2. `/dashboard/member-rankings/:enrollmentId/breakdown`

Reutiliza estructura de `/dashboard/rankings/:enrollmentId/breakdown` (8.4-C):
- Header: nombre miembro + sección + club + año + composite badge grande
- 3 cards: Clases | Investidura | Camporees con score + breakdown numérico
- Sección "Pesos aplicados" (readonly: 3 valores + source)
- Sección "Última actualización" + botón "Recalcular este miembro" (si permiso `member_ranking_weights:write`)

### 9.3. `/dashboard/section-rankings`

- Selector de año + selector de club
- `<DataTable>` con columnas: `#` | Sección | **Composite %** | Integrantes | Categoría | Acciones
- Botón "Ver miembros" → ruta `/dashboard/section-rankings/:sectionId/members`

### 9.4. `/dashboard/section-rankings/:sectionId/members`

- Header: nombre sección + composite + integrantes activos
- Tabla de enrollments ordenada por rank_position (mismas columnas que `/dashboard/member-rankings`)

### 9.5. `/dashboard/member-ranking-weights`

- Sección "Default global": 3 valores readonly + botón Editar → Dialog (shadcn Dialog)
- Tabla "Overrides por tipo + año": columnas `Tipo | Año | Clase | Investidura | Camporees | Suma | Acciones`
- Botón "Agregar override" → Dialog con selects `club_type_id` + `ecclesiastical_year_id` + 3 inputs
- Validación cliente: sum live en tiempo real, badge rojo si ≠ 100, disable submit si ≠ 100
- `<WeightSumIndicator>` reutilizable (mismo componente que 8.4-C si disponible)

### 9.6. `/dashboard/award-categories` — extensión

- Agregar columna "Scope" en tabla
- Filter tab: "Todos" | "Club" | "Sección" | "Miembro"
- Form CREATE/EDIT: campo `scope` (select enum con opciones Club/Sección/Miembro)

### 9.7. Stack y componentes reutilizables

Next.js 16 + shadcn/ui (new-york) + Tailwind v4 + react-hook-form + zod + TanStack Query. Refs de design: `sacdia-admin/DESIGN-SYSTEM.md` (shadcn/ui + Radix, CRUD = Dialog, delete = AlertDialog).

Componentes nuevos:
- `<MemberRankingScoreBadge value={pct} />` — similar a `<RankingScoreBadge>` de 8.4-C
- `<MemberBreakdownCard signal={'class'|'investiture'|'camporee'} data={...} />` — card reutilizable para los 3 calculadores

---

## 10. UI Fase 2 — Flutter (sacdia-app)

### 10.1. Pantalla `MyRanking`

Ruta: `/my-ranking` (gateada por `member_visibility ≠ 'hidden'`).

**Contenido**:
- Card principal: composite score % + rank_position + awarded_category (badge con color)
- 3 mini-cards: Clases % | Investidura | Camporees %
- Si `visibility = 'self_and_top_n'`: sección "Top N de mi sección/club" con lista compacta
- Pull to refresh
- Empty state: "Tu puntaje aún no fue calculado" si `composite_calculated_at = null`

**Visibilidad gateada**:
- `'hidden'` → pantalla no visible en nav; deep link devuelve error 403
- `'self_only'` → solo info propia
- `'self_and_top_n'` → info propia + top N (privacidad de nombres según OQ1 §15)

### 10.2. Pantalla `SectionRanking`

Ruta: `/section-ranking` (directores y asistentes de club).

- Header: nombre sección + composite + integrantes activos
- Lista de enrollments de la sección ordenada por rank_position
- Cada item: rank | nombre | composite % | awarded_category badge

### 10.3. Repository

```dart
abstract class MemberRankingsRepository {
  Future<MemberMyRankingDto> getMyRanking();
  Future<MemberRankingResponseDto> getMemberRanking(int enrollmentId);
  Future<List<MemberRankingResponseDto>> getSectionRankings(int sectionId, int yearId);
}

class MemberRankingsRemoteRepository implements MemberRankingsRepository {
  // HTTP calls: /api/v1/member-rankings/me + /api/v1/section-rankings
  // 403 (visibility=hidden) → return null (no throw), UI muestra empty state
}
```

### 10.4. Provider (Riverpod)

```dart
final myRankingProvider = FutureProvider.autoDispose<MemberMyRankingDto?>((ref) async {
  final repo = ref.watch(memberRankingsRepositoryProvider);
  try {
    return await repo.getMyRanking();
  } on ForbiddenException {
    return null; // visibility=hidden
  }
});

final sectionRankingProvider = FutureProvider.autoDispose
  .family<List<MemberRankingResponseDto>, ({int sectionId, int yearId})>((ref, params) async {
    final repo = ref.watch(memberRankingsRepositoryProvider);
    return repo.getSectionRankings(params.sectionId, params.yearId);
  });
```

---

## 11. Migration plan — 4 archivos atómicos

### 11.1. Orden de aplicación

Los 4 archivos se aplican **en orden** sobre Neon dev → staging → prod. No se puede omitir uno.

```
1. *_enrollment_rankings_schema.sql       -- 3 tablas nuevas + indexes
2. *_award_categories_scope.sql           -- ALTER + CHECK + backfill + index
3. *_enrollment_rankings_seeds.sql        -- weights default + system_config keys + permisos + grants
4. *_enrollment_rankings_award_seeds.sql  -- categorías default scope=member y scope=section
```

### 11.2. Archivo 1 — `enrollment_rankings_schema.sql`

Contenido: DDL de `enrollment_rankings` + `section_rankings` + `enrollment_ranking_weights` + todos sus indexes. Ver §4.1, 4.2, 4.3.

### 11.3. Archivo 2 — `award_categories_scope.sql`

Contenido: `ALTER TABLE award_categories ADD COLUMN scope` + CHECK constraint + index. Ver §4.4.

### 11.4. Archivo 3 — `enrollment_rankings_seeds.sql`

Contenido:
- `INSERT INTO enrollment_ranking_weights` (default global `50/30/20`)
- `INSERT INTO system_config` (3 keys: `member_ranking.recalculation_enabled`, `member_ranking.member_visibility`, `member_ranking.top_n`)
- `INSERT INTO permissions` (10 permisos con columna `permission_name`)
- Grants en `role_permissions` según matriz §4.7 (usando `role_name` lookup — UUID del rol `member` = `9567fef6-8091-494a-ac1c-fb3716ed2091`)

### 11.5. Archivo 4 — `enrollment_rankings_award_seeds.sql`

Categorías de premio por defecto para `scope = 'member'` y `scope = 'section'`:

| Categoría | scope | min_composite_pct | max_composite_pct |
|-----------|-------|:-----------------:|:-----------------:|
| AAA | member | 85 | 100 |
| AA | member | 75 | 84.99 |
| A | member | 65 | 74.99 |
| B | member | 50 | 64.99 |
| C | member | 0 | 49.99 |
| AAA | section | 85 | 100 |
| AA | section | 75 | 84.99 |
| A | section | 65 | 74.99 |
| B | section | 50 | 64.99 |
| C | section | 0 | 49.99 |

**Nota**: cutoffs miembro/sección más laxos que club (club usa min 80 para AAA en 8.4-C). Ajustable por admin post-migration.

### 11.6. Pattern de aplicación (engram #1204 / #1296 / #1839)

Para cada archivo, en cada branch (dev → staging → prod):

```sql
BEGIN;

\i <migration_file>.sql

INSERT INTO _prisma_migrations (
  id, checksum, finished_at, migration_name,
  logs, rolled_back_at, started_at, applied_steps_count
) VALUES (
  gen_random_uuid()::text, 'manual', NOW(),
  '<timestamp>_<name>', NULL, NULL, NOW(), 1
);

COMMIT;
```

### 11.7. Connection strings (NO hardcodear)

```bash
neonctl connection-string development --project-id wispy-hall-32797215
neonctl connection-string staging     --project-id wispy-hall-32797215
neonctl connection-string production  --project-id wispy-hall-32797215
```

### 11.8. Rollback plan

```sql
BEGIN;

DROP TABLE IF EXISTS enrollment_rankings;
DROP TABLE IF EXISTS section_rankings;
DROP TABLE IF EXISTS enrollment_ranking_weights;

ALTER TABLE award_categories DROP COLUMN IF EXISTS scope;
ALTER TABLE award_categories DROP CONSTRAINT IF EXISTS chk_award_scope;
DROP INDEX IF EXISTS idx_award_categories_scope;

DELETE FROM system_config WHERE config_key IN (
  'member_ranking.recalculation_enabled',
  'member_ranking.member_visibility',
  'member_ranking.top_n'
);

DELETE FROM permissions WHERE permission_name IN (
  'member_rankings:read_self', 'member_rankings:read_section',
  'member_rankings:read_club', 'member_rankings:read_lf',
  'member_rankings:read_global', 'member_ranking_weights:read',
  'member_ranking_weights:write', 'section_rankings:read_club',
  'section_rankings:read_lf', 'section_rankings:read_global'
);

DELETE FROM _prisma_migrations WHERE migration_name LIKE '20260429%';

COMMIT;
```

---

## 12. Error handling

### 12.1. Cron

- `try/catch` por fase (clubs / enrollments / secciones).
- Error en `recalculateMemberRankings` no bloquea `recalculateSectionAggregates` (datos parciales en DB son usables para agregación).
- Error per-enrollment: `logger.error({enrollment_id, ecclesiastical_year_id, error}) + skip`.
- Error per-sección: `logger.error({club_section_id, ecclesiastical_year_id, error}) + skip`.
- BullMQ retry 5x con exponential backoff si el job se encola (mismo patrón 8.4-C).

### 12.2. Calculadores

- Los calculadores **nunca lanzan excepciones** por dato faltante. Retornan `null` en datos insuficientes.
- División por cero siempre produce `null`, no error.
- La redistribución de NULLs en composite garantiza que ningún NULL individual rompe el composite si hay al menos 1 score válido.

### 12.3. API Guards

| Condición | HTTP | Código |
|-----------|------|--------|
| RBAC no matchea | 403 | `GUARD_PERMISSION_DENIED` |
| `visibility = 'hidden'` y miembro pide `/me` | 403 | `MEMBER_RANKING_HIDDEN` |
| `enrollmentId` no existe en `ecclesiastical_year_id` | 404 | `MEMBER_RANKING_NOT_FOUND` |
| Body weights suma ≠ 100 | 400 | `WEIGHTS_SUM_INVALID` |
| Duplicate `(club_type_id, ecclesiastical_year_id)` en weights | 409 | `WEIGHTS_CONFLICT` |
| DELETE sobre default global | 400 | `DEFAULT_WEIGHTS_NOT_DELETABLE` |
| Kill-switch off en recalculate manual | 400 | `RECALCULATION_DISABLED` |
| `ParseUUIDPipe` en param no UUID | 400 | NestJS default |

### 12.4. Alerta de naming híbrido

**Contexto crítico para implementadores**: el schema usa `enrollment_rankings` (nombre de tabla) y `enrollment_id` (nombre de columna). Los endpoints, DTOs, permissions y system_config keys usan `member_rankings` / `member_rankings:*` / `member_ranking.*`. Si hay un mismatch entre schema y API (ej. exponer `enrollment_id` en la URL en lugar de usar el convencional `memberId` del path), verificar la capa de mapeo en el controller y en el DTO.

Los parámetros INTEGER (enrollment_id, club_section_id) usan `ParseIntPipe`. Los UUIDs (award_category_id, pesos id) usan `ParseUUIDPipe`. Ver engram #1883/#1888 — bug de orden en 8.4-C: declarar rutas estáticas (`/me`, `/recalculate`) ANTES de rutas dinámicas (`/:enrollmentId`).

---

## 13. Observabilidad y logs

### 13.1. Logs estructurados

```
[member-rankings] Recalc started ecclesiastical_year_id=X club_count=Y
[member-rankings] Club X processed enrollments=N skipped=K duration_ms=Z
[member-rankings] Section aggregates started sections=M
[member-rankings] Section aggregates done sections=M empty=K errors=E
[member-rankings] Recalc done duration_ms=TOTAL enrollments_total=N sections_total=M errors=E
```

### 13.2. Métricas Prometheus (si disponible)

Siguiendo patrón 8.4-C:
- `member_ranking_calc_duration_ms{signal=class|investiture|camporee|composite}`
- `member_ranking_calc_errors_total{signal=..., reason=...}`
- `section_ranking_aggregate_duration_ms`
- `section_ranking_empty_total` (secciones con 0 enrollments con composite calculado)

### 13.3. Audit timestamp

`composite_calculated_at` por fila en `enrollment_rankings` y `section_rankings` = timestamp del último recálculo. Permite detectar stale data (composite calculado hace > 48h).

---

## 14. Testing strategy

### 14.1. Unit (Jest TDD — 7 specs)

1. `class-score.service.spec.ts`
   - Happy path: 3/5 módulos completados (active=true, score≠null) → 60.00
   - `required_count = 0` → NULL
   - `completed > required` (edge case data) → clamp a 100

2. `investiture-score.service.spec.ts`
   - `investiture_status = 'INVESTIDO'` → 100
   - `investiture_status = 'IN_PROGRESS'` → 0
   - Sin enrollment para el año → NULL

3. `camporee-score.service.spec.ts`
   - Happy path: asistió a 1/2 camporees (`status='approved'`) → 50.00
   - `total_camporees = 0` → NULL
   - Club sin `union_id` → solo camporees nacionales (`union_id IS NULL`) en denominador
   - Todos los camporees aprobados → 100.00

4. `member-composite-score.service.spec.ts`
   - Todos los scores disponibles: weighted average con pesos default (50/30/20)
   - Un score NULL (ej. investiture=NULL): redistribución proporcional entre class y camporee
   - Todos NULL → composite = NULL
   - Override de weights por `club_type_id` aplicado correctamente

5. `section-aggregation.service.spec.ts`
   - Sección con 3 enrollments con composite: AVG correcto
   - Sección con 0 enrollments con composite → NULL, count=0
   - Sección con enrollments de composite mixto (algunos NULL): AVG excluye NULLs

6. `enrollment-ranking-weights.service.spec.ts`
   - CRUD + validación CHECK SUM=100
   - Resolver: fallback default cuando no existe override
   - DELETE default → error 400

7. `award-categories-scope.spec.ts`
   - GET filtra por scope correctamente
   - POST requiere scope enum válido
   - PATCH scope solo por admin

### 14.2. Integration (NestJS Test.createTestingModule — 2 specs)

8. `member-rankings.controller.spec.ts`
   - RBAC matrix: member self → 200; member otro enrollment_id → 403; director-club mismo club → 200; director-club otro club → 403
   - GET `/me` con `visibility = 'hidden'` → 403
   - GET `/me` con `visibility = 'self_and_top_n'` → incluye `top_n`

9. `section-rankings.controller.spec.ts`
   - director-club → 200 filtrado por club; member → 403

### 14.3. E2E — detecta bugs tipo ParseUUIDPipe order (engram #1883/#1888)

10. `member-rankings.e2e-spec.ts`
    - HTTP real: `GET /member-rankings/` devuelve 200 (no 400 por ParseUUIDPipe order)
    - `GET /member-rankings/me` devuelve 200 o 403 según visibilidad
    - `POST /member-rankings/recalculate` devuelve 200 o 201

11. `section-rankings.e2e-spec.ts`
    - HTTP real: `GET /section-rankings/` devuelve 200

### 14.4. Smoke E2E manual post-merge

1. Trigger `POST /api/v1/member-rankings/recalculate` con kill-switch ON → verificar `enrollment_rankings` + `section_rankings` populated en Neon dev
2. Verificar que `section_rankings.composite_score_pct` = AVG manual de `enrollment_rankings.composite_score_pct` para una sección con ≥2 enrollments
3. Probar RBAC negativo: member intentando ver otro enrollment → 403
4. Probar `visibility = 'hidden'`: member llama `/me` → 403
5. Probar `visibility = 'self_and_top_n'`: verificar que respuesta incluye `top_n` array
6. App móvil Fase 2: smoke `MyRanking` con credenciales de member real en dev

---

## 15. Open questions (5 ítems — a resolver antes de implementación)

| # | Pregunta | Impacto | Propietario |
|---|----------|---------|-------------|
| OQ1 | **Privacidad top_n**: cuando `visibility=self_and_top_n`, ¿el array `top_n` expone `member_name` real, anonimizado (`"Miembro #5"`), o solo score+rank sin nombre? | `MemberMyRankingDto.top_n`, Task 14 (controller) | Decisión de producto — antes de implementar `/me` |
| OQ2 | **Section aggregation "active" Fase 2**: cuando/si `enrollments` agrega flag de baja (`is_active`, unsubscribed), ¿se filtra en `SectionAggregationService`? | `SectionAggregationService`, migration Fase 2 | Enhancement Fase 2 — no bloquea Fase 1 |
| OQ3 | **Evidence signal Fase 2**: cuando se agregue tracking per-enrollment de evidencias (sub-feature separada), ¿se reintroduce `EvidenceScoreService` y se actualiza `enrollment_ranking_weights` con `evidence_pct`? | Schema `enrollment_ranking_weights`, cálculo de composite | Requiere migration dedicada + redefinir CHECK |
| OQ4 | **`camporee_members.status` lifecycle**: ¿quién muta `'registered'` → `'approved'`? ¿Existe lógica inversa (rechazo)? | Numerador `CamporeeScoreService` — si hay valores además de `'approved'` que signifiquen asistencia confirmada | Gap de documentación — confirmar con datos en staging |
| OQ5 (ex-OQ-A4a) | **Completado en `ClassScoreService`**: ¿`class_module_progress.active = true AND score IS NOT NULL` define un módulo completado? ¿O es `class_section_progress.status = 'completed'` el denominador correcto? | Numerador y denominador de `ClassScoreService` | Task 2 (implementación de servicios) — consultar equipo backend |

### Fuera de scope (8.4-A Fase 1)

- Visibilidad usuario final en app (Fase 2, gateada)
- Periodicidades menores que anual (sub-feature D)
- Agrupación regional/multi-club (sub-feature E)
- Notificaciones FCM por cambio de ranking de miembro
- Ranking histórico retroactivo para años anteriores
- Export CSV / PDF del ranking de miembros
- Gráficos de evolución histórica del score de un miembro
- `EvidenceScoreService` (Fase 2, bloqueado por audit A5)
- Investidura por requisitos discretos (Fase 2, bloqueado por audit A11)

---

## 16. Criterios de aceptación — DoR / DoD

### Definition of Ready (antes de comenzar implementación)

- [x] Audit A1-A11 completado contra Neon dev (commit `643b694`)
- [ ] OQ1 respondida por producto (privacidad top_n)
- [ ] OQ5 respondida (definición de "completado" en class_module_progress)
- [ ] 4 migrations validadas en dry-run contra schema actual
- [ ] RBAC matrix revisada y aprobada por responsable de producto
- [ ] Cutoffs de categorías (§11.5) aprobados por dirección

### Definition of Done — Backend

- [ ] 3 tablas creadas en Neon dev + staging con pattern TXN atómico (engram #1204/#1296/#1839)
- [ ] `award_categories.scope` migrado con backfill y sin broken rows
- [ ] 10 permisos creados y grants asignados en seed (columna `permission_name`, UUID role `member`)
- [ ] 3 system_config keys insertadas
- [ ] 5 servicios de cálculo implementados y testeados (7 unit specs passing)
- [ ] 3 controllers implementados con RBAC correcto y orden de rutas correcto (2 integration specs + 2 e2e specs passing)
- [ ] Cron extendido con pasos 2 y 3 sin romper paso 1 (8.4-C)
- [ ] Kill-switch `member_ranking.recalculation_enabled` funciona: si `'false'`, no se recalculan enrollments/secciones
- [ ] Flag `member_visibility` funciona: `'hidden'` → 403 en `/me`
- [ ] Smoke E2E manual completado en Neon dev

### Definition of Done — Admin (Fase 1)

- [ ] 4 páginas nuevas implementadas en sacdia-admin (`/member-rankings`, `/member-rankings/:enrollmentId/breakdown`, `/section-rankings`, `/section-rankings/:sectionId/members`)
- [ ] `/dashboard/member-ranking-weights` implementada (3 columnas de peso, sin `evidence_pct`)
- [ ] `/dashboard/award-categories` extendida con tab scope
- [ ] RBAC admin respeta scope del usuario logueado
- [ ] Design System alineado: shadcn/ui, Dialog para CREATE/EDIT, AlertDialog para DELETE

### Definition of Done — Flutter (Fase 2)

- [ ] `MyRanking` pantalla implementada con manejo correcto de 3 estados de `member_visibility`
- [ ] `SectionRanking` pantalla implementada
- [ ] Repository + Provider implementados
- [ ] Smoke en dev con creds de member real

### Canon updates al cierre

- [ ] `docs/canon/runtime-rankings.md` → agregar §14 para 8.4-A (enrollment + sección)
- [ ] `docs/canon/decisiones-clave.md` → nueva decisión §23 (naming híbrido, 3 señales, schema audit)
- [ ] `docs/api/ENDPOINTS-LIVE-REFERENCE.md` → 4 nuevos grupos de endpoints
- [ ] `docs/database/SCHEMA-REFERENCE.md` → 3 tablas nuevas + extensión award_categories
- [ ] `docs/features/README.md` → entry "Clasificación sección y miembro"
