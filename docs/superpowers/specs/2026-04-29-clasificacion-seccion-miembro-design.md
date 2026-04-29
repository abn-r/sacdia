# Clasificación institucional — Sección y Miembro (8.4-A)

**Fecha**: 2026-04-29
**Estado**: SPEC APROBADO PARA IMPLEMENTACIÓN
**Origen**: línea 8.4 del roadmap `docs/bases/SACDIA_Bases_del_Proyecto-normalizado.md`, sub-feature **A** (sección + miembro) de la decomposición acordada (C → A → B → D → E)
**Depende de**: 8.4-C shipped y canonizado en `docs/canon/runtime-rankings.md` §13
**Stack agentes**: exploración Haiku/Sonnet, planeación Opus, implementación + tests Sonnet
**Engram topic key**: `sacdia/strategy/8-4-a-seccion-miembro-spec`

---

## 1. Resumen ejecutivo

La sub-feature 8.4-C (criterios ampliados) introdujo el composite ranking institucional a nivel club. La sub-feature 8.4-A extiende ese sistema hacia los dos niveles inferiores del organigrama operativo: la **sección de club** (`club_sections`) y el **miembro** (`members`). El objetivo es que cada miembro tenga un índice de progreso individual calculado automáticamente a partir de cuatro señales de actividad —clases, evidencias, investiduras y camporees— y que cada sección reciba un score derivado como promedio de sus miembros activos.

El diseño mantiene tres principios de 8.4-C: normalización 0-100, pesos configurables con CHECK SUM=100, y recálculo cron extendido con kill-switch independiente. Se introduce un pipeline secuencial dentro del mismo job cron: primero los clubs (8.4-C existente), luego los miembros, luego las secciones como agregado puro. Las secciones no tienen calculadores propios: su composite es el AVG de los composite scores de sus miembros activos. Una sección sin miembros activos recibe composite NULL y queda excluida del ranking positional.

La visibilidad del ranking de miembros está controlada por el flag `system_config.member_ranking.member_visibility`, que permite configurar si un miembro puede ver solo su propio score, su score más el top N, o nada (hidden). Los directores de club siempre ven todos los miembros del club independientemente del flag.

El plan de implementación incluye dos fases de UI: Fase 1 (admin web, sacdia-admin) y Fase 2 (Flutter, sacdia-app). El kill-switch `member_ranking.recalculation_enabled` permite habilitar el cálculo en backend antes de liberar la UI móvil, habilitando dark launch controlado.

---

## 2. Decisiones cerradas (Q1–Q9)

### Q1 — Sección como agregado puro de miembros

**Decisión**: `section_rankings.composite_score_pct` = AVG de `member_rankings.composite_score_pct` filtrado por `member_status = 'active'`. La sección no tiene calculadores propios ni pipeline paralelo de señales. Es un agregado puro sobre el resultado de los miembros.

**Rationale**: Mantener un pipeline dual (calculadores propios de sección + aggregation sobre miembros) crearía redundancia semántica y posibles inconsistencias entre los dos scores. La sección es la unidad operativa que agrupa miembros; su performance es necesariamente derivada de ellos. Además, no existen señales de sección que no sean ya señales de miembro.

---

### Q2 — Señales del miembro (4 calculadores)

**Decisión**: Cuatro señales por miembro:

| Señal | Servicio | Fuente tentativa |
|-------|----------|-----------------|
| Clases/especialidades completadas | `ClassScoreService` | `member_class_progress` |
| Evidencias asistidas individualmente | `EvidenceScoreService` | `evidence_attendance` (por verificar) |
| Investiduras logradas | `InvestitureScoreService` | `investitures` / `member_investitures` (por verificar) |
| Camporees individuales | `CamporeeScoreService` (adaptado) | `camporee_attendees` / `camporee_participants` (por verificar) |

**Fuera de scope**: asistencia regular (no hay tabla unificada per-member), finanzas individuales (no existe tracking per-member en SACDIA).

**Rationale**: Las 4 señales seleccionadas tienen fuente de datos trazable en el schema (a validar en audit §5). Las señales excluidas carecen de tabla per-member que permita un score justo e idempotente.

---

### Q3 — Tabla nueva `member_ranking_weights`

**Decisión**: Tabla separada de `ranking_weight_configs` (8.4-C). Mismo patrón: row default global (`club_type_id IS NULL`) + override opcional por `club_type_id + year_id`. La sección no tiene weights propios (es agregado puro).

**Rationale**: Los pesos de miembro son conceptualmente distintos de los pesos institucionales de club. Un club pesa carpeta/finanzas/camporees/evidencias institucionales; un miembro pesa clases/evidencias-personales/investiduras/camporees-personales. Compartir tabla crearía ambigüedad semántica y potencial drift de weights.

---

### Q4 — RBAC modelo C híbrido + flag de visibilidad

**Decisión**: Flag `system_config.member_ranking.member_visibility` con tres valores:
- `'self_only'` (default) — miembro ve solo su propio score
- `'self_and_top_n'` — miembro ve su score + top N (configurable por `member_ranking.top_n`, default `5`)
- `'hidden'` — miembro no puede ver ningún score (endpoint `/me` devuelve 403)

El director de club siempre ve todos los miembros de su club, independientemente del flag.

**Permisos nuevos**:

| Permiso | Roles |
|---------|-------|
| `member_rankings:read_self` | member |
| `member_rankings:read_section` | assistant-club, director-club |
| `member_rankings:read_club` | director-club, assistant-club, director-dia, assistant-dia |
| `member_rankings:read_lf` | director-lf, assistant-lf |
| `member_rankings:read_global` | super_admin, admin, director-union, assistant-union |
| `member_ranking_weights:read` | super_admin, admin, director-union, assistant-union, director-lf |
| `member_ranking_weights:write` | super_admin, admin |
| `section_rankings:read_club` | director-club, assistant-club, director-dia, assistant-dia |
| `section_rankings:read_lf` | director-lf, assistant-lf |
| `section_rankings:read_global` | super_admin, admin, director-union, assistant-union |

**Rationale**: El RBAC scope-escalado (self → section → club → lf → global) sigue el patrón de autorización contextual ya establecido en MoM (decisión §16) y SLA dashboard (decisión §15). El flag de visibilidad permite política institucional configurable sin redeploy.

---

### Q5 — UI en dos fases

**Decisión**:
- **Fase 1 (admin web)**: páginas `/dashboard/member-rankings`, `/dashboard/section-rankings`, `/dashboard/member-ranking-weights`, extensión de `/dashboard/award-categories` con tab `scope`.
- **Fase 2 (móvil Flutter)**: pantallas `MyRanking` + `SectionRanking`, repository + provider, gateadas por flag `member_visibility`.

**Rationale**: La UI admin es para supervisión y configuración; no depende del flag de visibilidad. La UI móvil es la superficie de self-service del miembro; depende del flag y requiere validar la experiencia antes de escalar. Separar en fases permite dark launch controlado.

---

### Q6 — Cron secuencial en mismo job + delta-only en Fase 2

**Decisión**: El cron `@Cron('0 2 * * *' UTC)` en `rankings.service.ts` ejecuta en orden secuencial:
1. `recalculateClubRankings()` (8.4-C existente, sin cambios)
2. Si `member_ranking.recalculation_enabled = 'true'`: `recalculateMemberRankings()`
3. `recalculateSectionAggregates()`

Errores per-miembro: log + skip (no bloquean al club ni a otros miembros). Sección que falla en agregación NO bloquea secciones ya procesadas.

Fase 2 optimización: delta-only — recalcular solo miembros con `last_progress_change > previous_recalc_at`.

**Rationale**: Un único job con orden garantizado evita race conditions entre el ranking de clubs y el de miembros. El delta-only en Fase 2 escala el cron sin costo linear al número de miembros.

---

### Q7 — `award_categories.scope` polimórfica

**Decisión**: `ALTER TABLE award_categories ADD COLUMN scope VARCHAR(20) NOT NULL DEFAULT 'club'` con CHECK constraint `scope IN ('club','section','member')`. Backfill existentes con `'club'`. Index `(scope, is_legacy)`.

**Rationale**: Permite que `award_categories` sea compartida entre los tres niveles sin necesidad de tablas separadas. El backfill asegura que las categorías existentes (todas de nivel club) conserven su comportamiento sin cambios.

---

### Q8 — Agregación de sección: AVG miembros activos, secciones vacías NULL

**Decisión**: `composite_pct = AVG(member.composite_pct)` filtrado `member_status = 'active'`. Si la sección tiene 0 miembros activos → `composite = NULL`, no aparece en `rank_position`. `NULLS LAST` en `DENSE_RANK`.

**Audit dependency**: si `members.member_status` no existe en Neon dev, Fase 1 opera sin filtro (TODO documentado en §5). Se agrega filtro en Fase 2 con migration `ADD COLUMN member_status`.

**Rationale**: Una sección sin miembros activos no tiene performance medible; forzar `composite = 0` la hundiría artificialmente en el ranking. NULL + NULLS LAST la excluye honestamente.

---

### Q9 — Kill-switch separado del de 8.4-C

**Decisión**: `system_config.member_ranking.recalculation_enabled` (default `'true'`). El cron checa ambas keys:
- `ranking.recalculation_enabled` (8.4-C) — si `false`, el job entero no ejecuta (incluyendo clubs)
- `member_ranking.recalculation_enabled` (8.4-A) — si `false`, solo saltan los pasos 2 y 3 (member + section)

**Rationale**: Permite deshabilitar el recálculo de miembros/secciones sin afectar el recálculo de clubs. Habilitaría un incidente en la lógica 8.4-A sin romper el sistema 8.4-C ya productivo. También permite dark launch: habilitar el cálculo en backend antes de liberar la UI móvil.

---

## 3. Arquitectura

### 3.1. Diagrama de capas (8.4-A)

```
┌─────────────────────────────────────────────────────────┐
│                     Cron Job (rankings.service.ts)       │
│   step 1: recalculateClubRankings()   [8.4-C existente]  │
│   step 2: recalculateMemberRankings() [8.4-A nuevo]      │
│   step 3: recalculateSectionAggregates() [8.4-A nuevo]   │
└──────────────┬───────────────────────────────────────────┘
               │
       ┌───────┴───────────────────────────────────┐
       │                                           │
       ▼                                           ▼
MemberCompositeScoreService            SectionAggregationService
       │                                           │
  ┌────┴────────────────────┐              AVG(member_rankings
  │  ClassScoreService      │              WHERE member_status
  │  EvidenceScoreService   │              = 'active')
  │  InvestitureScoreService│
  │  CamporeeScoreService   │
  └────────────────────────┘
       │
WeightsResolverService (member_ranking_weights)
```

### 3.2. Módulo backend

Módulo NestJS: `src/rankings/` (módulo existente o subpath `member-rankings/`).

Servicios nuevos:
- `ClassScoreService`
- `EvidenceScoreService`
- `InvestitureScoreService`
- `CamporeeScoreService` (adaptado del club-level)
- `MemberCompositeScoreService`
- `SectionAggregationService`
- `MemberWeightsResolverService`

Controllers nuevos:
- `MemberRankingsController` — `/api/v1/member-rankings`
- `SectionRankingsController` — `/api/v1/section-rankings`
- `MemberRankingWeightsController` — `/api/v1/member-ranking-weights`

### 3.3. Relación con 8.4-C

8.4-A NO toca `club_annual_rankings`, `ranking_weight_configs`, ni los score-calculators de club (folder/finance/camporee/evidence institucionales). Son dominios paralelos con tablas separadas. El único shared pattern es el cron job y el `WeightsResolver` conceptual (cada uno con su tabla propia).

---

## 4. Schema

### 4.1. Tabla `member_rankings`

```sql
CREATE TABLE member_rankings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id INTEGER NOT NULL REFERENCES members(member_id) ON DELETE CASCADE,
  club_id INTEGER NOT NULL REFERENCES clubs(club_id),
  club_section_id INTEGER REFERENCES club_sections(club_section_id),
  year_id INTEGER NOT NULL REFERENCES years(year_id),
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
  UNIQUE(member_id, year_id)
);

CREATE INDEX idx_member_rankings_club_year
  ON member_rankings(club_id, year_id);

CREATE INDEX idx_member_rankings_section_year
  ON member_rankings(club_section_id, year_id);

CREATE INDEX idx_member_rankings_composite
  ON member_rankings(club_id, year_id, composite_score_pct DESC);
```

**Notas**:
- Los 4 component scores son NULLABLE. NULL significa "dato insuficiente para calcular", distinto de 0.
- `composite_score_pct` es NULLABLE. NULL si todos los componentes son NULL.
- `awarded_category_id` es NULLABLE. Un miembro sin composite calculado no recibe categoría.
- `UNIQUE(member_id, year_id)` permite upsert idempotente.

### 4.2. Tabla `section_rankings`

```sql
CREATE TABLE section_rankings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  club_section_id INTEGER NOT NULL REFERENCES club_sections(club_section_id) ON DELETE CASCADE,
  club_id INTEGER NOT NULL REFERENCES clubs(club_id),
  year_id INTEGER NOT NULL REFERENCES years(year_id),
  composite_score_pct NUMERIC(5,2),
  active_member_count INTEGER NOT NULL DEFAULT 0,
  rank_position INTEGER,
  awarded_category_id UUID REFERENCES award_categories(award_category_id),
  composite_calculated_at TIMESTAMPTZ(6),
  created_at TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
  UNIQUE(club_section_id, year_id)
);

CREATE INDEX idx_section_rankings_club_year
  ON section_rankings(club_id, year_id);

CREATE INDEX idx_section_rankings_composite
  ON section_rankings(club_id, year_id, composite_score_pct DESC NULLS LAST);
```

**Notas**:
- `composite_score_pct` es NULLABLE. Sección con 0 miembros activos → NULL.
- `active_member_count` permite mostrar contexto ("N miembros activos") sin join a `member_rankings`.
- `NULLS LAST` en el índice soporte alinea con la política de `DENSE_RANK` (ver §7.6).

### 4.3. Tabla `member_ranking_weights`

```sql
CREATE TABLE member_ranking_weights (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  club_type_id INTEGER REFERENCES club_types(club_type_id),
  year_id INTEGER REFERENCES years(year_id),
  class_pct NUMERIC(5,2) NOT NULL,
  evidence_pct NUMERIC(5,2) NOT NULL,
  investiture_pct NUMERIC(5,2) NOT NULL,
  camporee_pct NUMERIC(5,2) NOT NULL,
  is_default BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
  CHECK (class_pct + evidence_pct + investiture_pct + camporee_pct = 100),
  UNIQUE(club_type_id, year_id)
);

-- Seed: default global
INSERT INTO member_ranking_weights
  (class_pct, evidence_pct, investiture_pct, camporee_pct, is_default)
VALUES
  (40, 25, 20, 15, true)
ON CONFLICT DO NOTHING;
```

**Notas**:
- `club_type_id IS NULL AND year_id IS NULL` = row default global (única por UNIQUE constraint).
- Override por `club_type_id + year_id` permite tuning fino por tipo de club y año.
- `is_default` es flag informativo; la lógica de resolución usa IS NULL en `club_type_id`.
- Default inicial sugerido: `class=40, evidence=25, investiture=20, camporee=15`. Ajustable por admin.

### 4.4. Extensión `award_categories.scope`

```sql
ALTER TABLE award_categories
  ADD COLUMN scope VARCHAR(20) NOT NULL DEFAULT 'club';

ALTER TABLE award_categories
  ADD CONSTRAINT chk_award_scope
  CHECK (scope IN ('club', 'section', 'member'));

-- Backfill filas existentes (ya tienen DEFAULT 'club', sentencia es no-op intencional para claridad)
-- NOT NULL DEFAULT 'club' asegura que todas las filas preexistentes ya tienen scope='club'.
-- El UPDATE es defensivo: un run explícito documenta la intención sin riesgo de side effects.

CREATE INDEX idx_award_categories_scope
  ON award_categories(scope, is_legacy);
```

**Notas**:
- Las categorías existentes conservan `scope = 'club'` por defecto. No se rompe 8.4-C.
- El GET de `award_categories` acepta `?scope=club|section|member` para filtrar.
- Admin debe crear categorías con `scope = 'member'` y `scope = 'section'` para que 8.4-A asigne categorías.

### 4.5. Keys nuevas en `system_config`

```sql
INSERT INTO system_config (config_key, config_value, config_type) VALUES
  ('member_ranking.recalculation_enabled', 'true',    'boolean'),
  ('member_ranking.member_visibility',     'self_only','string'),
  ('member_ranking.top_n',                 '5',        'integer')
ON CONFLICT (config_key) DO NOTHING;
```

### 4.6. Permisos nuevos — tabla `permissions` + grants en `role_permissions`

```sql
-- 10 permisos nuevos
INSERT INTO permissions (name) VALUES
  ('member_rankings:read_self'),
  ('member_rankings:read_section'),
  ('member_rankings:read_club'),
  ('member_rankings:read_lf'),
  ('member_rankings:read_global'),
  ('member_ranking_weights:read'),
  ('member_ranking_weights:write'),
  ('section_rankings:read_club'),
  ('section_rankings:read_lf'),
  ('section_rankings:read_global')
ON CONFLICT (name) DO NOTHING;
```

**RBAC matrix completa**:

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

> **Audit completado 2026-04-29**: ver `docs/superpowers/audits/2026-04-29-section-member-schema-audit.md` para output completo de queries y razonamiento detallado. Decisiones bloqueadas abajo.

| # | Ítem                                  | Estado    | Resultado real                                                                  | Decisión bloqueada                                                                                       |
|---|---------------------------------------|-----------|---------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------|
| A1 | `members.member_id` INTEGER          | DEVIATION | No existe tabla `members`. Entidad = `enrollments.enrollment_id` (INTEGER) + `users.user_id` (UUID) | FK en `member_rankings` → `enrollment_id INTEGER REFERENCES enrollments(enrollment_id)`. Renombrar campo. |
| A2 | `members.member_status` existe        | MISSING   | No existe `member_status`. Equivalente: `enrollments.active BOOLEAN`           | Filtro de "miembro activo" = `WHERE enrollments.active = true`. Sin migration de ADD COLUMN necesaria.    |
| A3 | `club_sections.club_section_id` INTEGER | CONFIRMED | `club_section_id INTEGER` — confirmado                                        | Sin cambio. FK `INTEGER REFERENCES club_sections(club_section_id)`.                                      |
| A4 | `member_class_progress` existe        | DEVIATION | Tabla real: `class_module_progress` (`user_id UUID`, `enrollment_id INTEGER`, sin `year_id` directo; año vía `enrollment_id → enrollments.ecclesiastical_year_id`) | `ClassScoreService` usa `class_module_progress JOIN enrollments USING (enrollment_id)` para filtrar año. |
| A5 | `evidence_attendance` per-member      | MISSING   | No existe tabla per-member de asistencia a evidencias                           | `EvidenceScoreService` retorna NULL en Fase 1. Peso redistribuido al composite. Requiere decisión de negocio para Fase 2. |
| A6 | `investitures` / `member_investitures` per-member | DEVIATION | No existen. Datos de investidura en `enrollments.investiture_status` enum (`IN_PROGRESS` / `INVESTIDO`) + `investiture_validation_history` | `InvestitureScoreService` usa señal binaria: `INVESTIDO` = 100, `IN_PROGRESS` = 0, sin enrollment = NULL. |
| A7 | `camporee_attendees` / `camporee_participants` | DEVIATION | No existen. Tabla real: `camporee_members` (`user_id UUID`, `status VARCHAR`, `camporee_id INTEGER`) | `CamporeeScoreService` usa `camporee_members WHERE user_id = $userUuid AND status = 'approved'` (valor a confirmar con datos en staging). |
| A8 | rol `member` en `roles`               | CONFIRMED | Existe: `role_id UUID 9567fef6-8091-494a-ac1c-fb3716ed2091`, `role_name='member'`, `role_category=CLUB`. Sin columna `code`. Permisos usan `permission_name`. | Seed grants usan UUID literal del rol `member`. `INSERT INTO permissions (permission_name, ...)`.         |
| A9 | `system_config` columns               | CONFIRMED | `config_key`, `config_value`, `description`, `config_type`, `updated_at` — confirmado | INSERT usa `(config_key, config_value, config_type)` con `ON CONFLICT (config_key)`. Correcto.           |
| A10 | `years` vs `ecclesiastical_years`    | CONFIRMED | `years` no existe. `ecclesiastical_years` con PK `year_id INTEGER` — confirmado | FK en 3 tablas nuevas: `year_id INTEGER REFERENCES ecclesiastical_years(year_id)`.                        |
| A11 | `investiture_requirements`            | MISSING   | No existe. Solo `investiture_config` e `investiture_validation_history`        | `InvestitureScoreService` adopta modelo binario (ver A6). `eligible_count` no calculable en Fase 1. Documentar para Fase 2 si se define tabla de requisitos. |

**Nota A1 (crítica)**: el cambio de `member_id` a `enrollment_id` es el desvío más importante. Afecta el nombre del campo en `member_rankings`, todos los calculadores (reciben `enrollmentId`), los DTOs, y los endpoints REST (`:enrollmentId` en lugar de `:memberId`). Las tablas nuevas deben usar `enrollment_id` como FK.

**Nota A5**: `EvidenceScoreService` bloqueado en Fase 1. Peso de evidencia (25% por default) se redistribuye proporcionalmente entre las otras 3 señales disponibles vía la política de redistribución de NULLs del composite (§7.5).

**Nota A11**: `InvestitureScoreService` usa señal binaria — no el modelo `achieved_count / eligible_count` del diseño original en §7.3. El §7.3 debe actualizarse en la implementación para reflejar la fuente real de datos.

---

## 6. Endpoints REST + DTOs + RBAC

### 6.1. Member Rankings — `/api/v1/member-rankings`

#### `GET /api/v1/member-rankings`

Parámetros: `?club_id=&year_id=&section_id=&page=&limit=`

RBAC scope-filtrado:
- `member_rankings:read_self` → solo devuelve el propio registro (ignorar filtros de club/section)
- `member_rankings:read_section` → filtra por `club_section_id` del rol del caller
- `member_rankings:read_club` → filtra por `club_id` del rol del caller
- `member_rankings:read_lf` → filtra por `local_field_id` del caller
- `member_rankings:read_global` → sin restricción de scope

Respuesta paginada: `{ data: MemberRankingResponseDto[], total, page, limit }`

#### `GET /api/v1/member-rankings/:memberId/breakdown`

Drill-down del score de un miembro: 4 breakdowns + weights aplicados.

RBAC: mismo scope que GET /, verificar que el caller puede ver al miembro solicitado.

Respuesta: `MemberBreakdownDto`

#### `GET /api/v1/member-rankings/me`

Atajo para el miembro autenticado. Respeta el flag `member_visibility`:
- `'hidden'` → 403 GUARD_PERMISSION_DENIED
- `'self_only'` → devuelve solo el propio registro
- `'self_and_top_n'` → devuelve propio + top N (N de `member_ranking.top_n`)

Respuesta: `MemberMyRankingDto`

RBAC: `member_rankings:read_self`

#### `POST /api/v1/member-rankings/recalculate`

Recálculo manual idempotente.

Body: `{ year_id?: number, club_id?: number }`

RBAC: `member_ranking_weights:write` (solo admin puede triggerear)

Respuesta: `{ triggered: true, year_id: number, club_id?: number }`

---

### 6.2. Section Rankings — `/api/v1/section-rankings`

#### `GET /api/v1/section-rankings`

Parámetros: `?club_id=&year_id=&page=&limit=`

RBAC scope-filtrado igual que member_rankings (usar permisos `section_rankings:read_*`).

Respuesta paginada: `{ data: SectionRankingResponseDto[], total, page, limit }`

#### `GET /api/v1/section-rankings/:sectionId/members`

Drill-down: miembros de la sección ordenados por `rank_position ASC NULLS LAST`.

RBAC: `section_rankings:read_club` mínimo.

Respuesta: `{ section: SectionRankingResponseDto, members: MemberRankingResponseDto[] }`

---

### 6.3. Member Ranking Weights — `/api/v1/member-ranking-weights`

CRUD idéntico al patrón de `ranking-weights` (8.4-C).

| Método | Path | RBAC | Descripción |
|--------|------|------|-------------|
| `GET` | `/` | `member_ranking_weights:read` | Lista default + overrides |
| `GET` | `/:id` | `member_ranking_weights:read` | Detalle de una config |
| `POST` | `/` | `member_ranking_weights:write` | Crear override por `club_type_id + year_id` |
| `PATCH` | `/:id` | `member_ranking_weights:write` | Actualizar weights; re-valida CHECK SUM=100 |
| `DELETE` | `/:id` | `member_ranking_weights:write` | Eliminar override; default global no eliminable (400) |

Validaciones:
- `class_pct + evidence_pct + investiture_pct + camporee_pct = 100` → HTTP 400 si no
- Unique `(club_type_id, year_id)` → HTTP 409 si duplicado
- DELETE sobre row con `is_default = true` → HTTP 400
- Ningún peso individual puede ser negativo → HTTP 400

---

### 6.4. Award Categories — extensión (filtro por scope)

Extender `GET /award-categories` con `?scope=club|section|member&is_legacy=false`.

Extender `POST /award-categories` body con campo `scope` (enum, required, default `'club'`).

Extender `PATCH /award-categories/:id` para permitir update de `scope` solo si caller tiene `admin`.

---

### 6.5. DTOs

```typescript
// MemberRankingResponseDto
interface MemberRankingResponseDto {
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
    evidence_pct: number;
    investiture_pct: number;
    camporee_pct: number;
    source: 'default' | `override:club_type_${number}+year_${number}`;
  };
  class_breakdown: {
    completed_count: number;
    required_count: number;
    percentage: number | null;
  };
  evidence_breakdown: {
    attended_count: number;
    total_evidences: number;
    percentage: number | null;
  };
  investiture_breakdown: {
    achieved_count: number;
    eligible_count: number;
    percentage: number | null;
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
  active_member_count: number;
  awarded_category: {
    id: string;
    name: string;
    color: string;
    min_pct: number;
    max_pct: number;
  } | null;
  composite_calculated_at: string | null;
}

// MemberMyRankingDto
interface MemberMyRankingDto {
  member: MemberRankingResponseDto;
  visibility_mode: 'self_only' | 'self_and_top_n' | 'hidden';
  top_n?: Array<{
    member_name: string;
    composite_score_pct: number | null;  // consistente con MemberRankingResponseDto
    rank_position: number | null;
  }>;
}
```

---

## 7. Calculadores (lógica)

### 7.1. `ClassScoreService.calculate(memberId, yearId)`

```
completed_count := COUNT(*)
  FROM member_class_progress  -- nombre a verificar: audit A4
  WHERE member_id = memberId
    AND year_id = yearId       -- o columna equivalente
    AND status = 'completed'   -- valor a verificar contra schema real

required_count := COUNT(*)
  FROM class_modules
  WHERE club_type_id = (SELECT club_type_id FROM members WHERE member_id = memberId)
    AND is_required = true     -- columna a verificar

score_pct := required_count > 0
  ? CLAMP((completed_count / required_count) * 100, 0, 100)
  : NULL

-- NULL si required_count = 0 (miembro sin módulos requeridos para su tipo)
-- Nunca throw por dato faltante: retorna NULL
```

### 7.2. `EvidenceScoreService.calculate(memberId, yearId)`

```
attended_count := COUNT(DISTINCT evidence_id)
  FROM evidence_attendance  -- nombre a verificar: audit A5
  WHERE member_id = memberId
    AND year_id = yearId

total_evidences := COUNT(DISTINCT evidence_id)
  FROM evidences
  WHERE club_id = (SELECT club_id FROM members WHERE member_id = memberId)
    AND year_id = yearId
    AND active = true

score_pct := total_evidences > 0
  ? CLAMP((attended_count / total_evidences) * 100, 0, 100)
  : NULL

-- NULL si total_evidences = 0 (no hay evidencias registradas para el club en el año)
```

**TODO audit A5**: si `evidence_attendance` no existe, evaluar derivar de `annual_folder_section_evaluations` per-member. Documentar workaround antes de implementar.

### 7.3. `InvestitureScoreService.calculate(memberId, yearId)`

```
achieved_count := COUNT(*)
  FROM investitures             -- nombre a verificar: audit A6
  WHERE member_id = memberId
    AND achieved_year_id = yearId
    AND status = 'approved'    -- valor a verificar

eligible_count := COUNT(*)
  FROM investiture_requirements  -- tabla de elegibilidad por club_type + antigüedad (audit A11)
  WHERE club_type_id = (SELECT club_type_id FROM members WHERE member_id = memberId)
    AND seniority_year <= member_seniority_years  -- criterio a definir en audit

score_pct := eligible_count > 0
  ? CLAMP((achieved_count / eligible_count) * 100, 0, 100)
  : NULL

-- IMPORTANTE: eligible_count = 0 → NULL (NO 100)
-- Evita inflar score de miembros sin investiduras elegibles
```

**Decisión crítica**: `eligible_count = 0` retorna NULL, NO `100`. Un miembro sin investiduras elegibles para su antigüedad no tiene performance medible en esta señal; forzar 100 inflaría artificialmente el composite de miembros nuevos.

### 7.4. `CamporeeScoreService.calculate(memberId, yearId)` — adaptado de 8.4-C

```
club_id := SELECT club_id FROM members WHERE member_id = memberId

-- Derivar resolved_union_id vía local_fields (clubs NO tiene columna union_id directa — engram #1850)
resolved_union_id := SELECT lf.union_id
  FROM clubs c
  JOIN local_fields lf ON c.local_field_id = lf.local_field_id
  WHERE c.club_id = club_id

participated_count := COUNT(DISTINCT camporee_id)
  FROM camporee_attendees         -- nombre a verificar: audit A7
  WHERE member_id = memberId
    AND year_id = yearId
    AND status = 'attended'       -- o status equivalente

total_camporees := COUNT(DISTINCT camporee_id)
  FROM (
    SELECT local_camporee_id AS camporee_id FROM local_camporees
    WHERE year_id = yearId AND active = true
      AND (union_id = resolved_union_id OR union_id IS NULL)
    UNION ALL
    SELECT union_camporee_id AS camporee_id FROM union_camporees
    WHERE year_id = yearId AND active = true
      AND (union_id = resolved_union_id OR union_id IS NULL)
  ) t

score_pct := total_camporees > 0
  ? CLAMP((participated_count / total_camporees) * 100, 0, 100)
  : NULL

-- NULL si total_camporees = 0 (no hay camporees registrados para el club en el año)
```

**Diferencia con 8.4-C**: el denominador es per-miembro (camporees a los que el miembro ASISTIÓ), no el club. El denominador de disponibles es el mismo que el del club (camporees del scope union).

### 7.5. `MemberCompositeScoreService.calculate(memberId, yearId)`

```
1. weights := MemberWeightsResolverService.resolve({
     club_type_id: member.club_type_id,
     year_id: yearId
   })
   -- Resolve: buscar override por (club_type_id, year_id)
   --          si no existe, buscar override por (club_type_id, null)
   --          si no existe, usar default global (is_default = true)

2. scores := await Promise.all([
     ClassScoreService.calculate(memberId, yearId),
     EvidenceScoreService.calculate(memberId, yearId),
     InvestitureScoreService.calculate(memberId, yearId),
     CamporeeScoreService.calculate(memberId, yearId)
   ])
   -- scores = [class_pct, evidence_pct, investiture_pct, camporee_pct]
   -- Cada valor puede ser NULL

3. null_redistribution(scores, weights):
   -- Si ALL scores NULL → composite = NULL
   -- Si ALGUNOS scores NULL:
   --   sum_null_weights  := SUM(weights[i] WHERE scores[i] IS NULL)
   --   sum_valid_weights := SUM(weights[i] WHERE scores[i] IS NOT NULL)  ← base de redistribución
   --   valid_scores := scores.filter(s => s IS NOT NULL)
   --   redistributed_weights[i] := weights[i] + (weights[i] / sum_valid_weights * sum_null_weights)
   --     (solo para i WHERE scores[i] IS NOT NULL; pesos de NULLs se descartan)
   --   composite = SUM(valid_scores[i] * redistributed_weights[i]) / 100

4. Retornar composite_pct clamped [0, 100], o NULL si paso 3 devuelve NULL
```

**Política de redistribución de NULLs**: si un score es NULL por datos insuficientes, su peso se redistribuye proporcionalmente entre los scores disponibles. Esto evita penalizar al miembro por señales que aún no tienen datos (ej. un miembro nuevo sin camporees registrados no recibe 0 en camporee, sino que ese peso se distribuye a las otras señales).

### 7.6. `SectionAggregationService.aggregate(sectionId, yearId)`

```
active_members := SELECT mr.composite_score_pct, mr.member_id
  FROM member_rankings mr
  JOIN members m ON mr.member_id = m.member_id
  WHERE mr.club_section_id = sectionId
    AND mr.year_id = yearId
    AND m.member_status = 'active'   -- TODO audit A2: si no existe, omitir este filtro en Fase 1

IF COUNT(active_members) = 0:
  composite_score_pct = NULL
  active_member_count = 0
  rank_position = NULL
ELSE:
  composite_score_pct = AVG(active_members.composite_score_pct)
    -- Excluir NULLs: AVG de PostgreSQL ignora NULLs por defecto
  active_member_count = COUNT(active_members)

UPSERT section_rankings SET (composite_score_pct, active_member_count, composite_calculated_at)
  WHERE club_section_id = sectionId AND year_id = yearId
```

### 7.7. Asignación de `rank_position`

Aplicar después de todos los upserts de miembros de un club, y después de todos los upserts de secciones de un club:

```sql
-- Para member_rankings:
DENSE_RANK() OVER (
  PARTITION BY club_id, year_id
  ORDER BY composite_score_pct DESC NULLS LAST
)

-- Para section_rankings:
DENSE_RANK() OVER (
  PARTITION BY club_id, year_id
  ORDER BY composite_score_pct DESC NULLS LAST
)
```

Política: empates comparten rank. `NULLS LAST` garantiza que secciones vacías y miembros sin composite queden al final sin rank positional. Semántica densa: mismo algoritmo que 8.4-C (decisión §12 de `decisiones-clave.md`).

---

## 8. Cron + flujo de recálculo

### 8.1. Orden de ejecución

```typescript
@Cron('0 2 * * *', { name: 'rankings-recalculation', timeZone: 'UTC' })
async handleRankingsRecalculation(): Promise<void> {
  // Paso 0: verificar kill-switch global (8.4-C)
  const globalEnabled = await systemConfig.get('ranking.recalculation_enabled');
  if (globalEnabled === 'false') {
    logger.warn('[rankings] Recalculation disabled by kill-switch');
    return;
  }

  // Paso 1: clubs (8.4-C existente, sin cambios)
  await this.recalculateClubRankings();

  // Paso 2: miembros (8.4-A nuevo)
  const memberEnabled = await systemConfig.get('member_ranking.recalculation_enabled');
  if (memberEnabled !== 'false') {
    try {
      await this.recalculateMemberRankings();
    } catch (err) {
      logger.error('[member-rankings] recalculateMemberRankings failed, continuing to section aggregates', err);
    }
    // Paso 3: secciones (8.4-A nuevo) — corre aunque paso 2 falle parcialmente (datos parciales en DB)
    await this.recalculateSectionAggregates();
  }
}
```

### 8.2. `recalculateMemberRankings(yearId?)`

```
1. Resolver año activo si yearId no recibido
2. Listar clubs activos con miembros
3. Para cada club (batched por chunks de 50 clubs):
   a. Listar members del club para el año
   b. Para cada member:
      i.  Calcular 4 component scores en Promise.all
      ii. Calcular composite con redistribución de NULLs
      iii.UPSERT member_rankings
      iv. Si error: log.error({member_id, error}) + skip (no bloquear otros miembros)
   c. Asignar rank_position por club+year con DENSE_RANK NULLS LAST
4. Log estructurado al final (ver §13)
```

### 8.3. `recalculateSectionAggregates(yearId?)`

```
1. Resolver año activo si yearId no recibido
2. Listar club_sections activas con miembros en member_rankings del año
3. Para cada sección:
   a. SectionAggregationService.aggregate(sectionId, yearId)
   b. Si error: log.error({section_id, error}) + skip
4. Asignar rank_position por club+year con DENSE_RANK NULLS LAST
5. Log estructurado al final
```

### 8.4. Recálculo manual

```
POST /api/v1/member-rankings/recalculate
Body: { year_id?: number, club_id?: number }

-- Misma lógica que cron pero scope reducido:
-- Si club_id → solo recalcular miembros/secciones del club
-- Si year_id → pasar al resolver, default año activo
-- Si kill-switch member_ranking.recalculation_enabled = 'false' → 400
-- Rate limit: 1/5min (mismo patrón 8.4-C)
```

### 8.5. Idempotencia

- `UPSERT ON CONFLICT (member_id, year_id)` garantiza idempotencia por miembro.
- `UPSERT ON CONFLICT (club_section_id, year_id)` garantiza idempotencia por sección.
- Re-ejecuciones producen el mismo resultado si los datos fuente no cambiaron.

---

## 9. UI Fase 1 — Admin web (sacdia-admin)

### 9.1. `/dashboard/member-rankings`

**Componentes principales**:
- Selector de año eclesiástico + selector de club + selector de sección (cascaded)
- `<DataTable>` con columnas: `#` (rank_position) | Miembro | Sección | **Composite %** (badge color) | Clase % | Evidencias % | Investiduras % | Camporees % | Categoría | Acciones
- Botón "Ver detalle" por fila → navega a breakdown (ruta dinámica o drawer lateral)
- Vacío state si no hay rankings calculados para el filtro seleccionado

**Comportamiento de badges**: verde ≥85, ámbar 65-84, rojo <65. Nota: cutoffs más laxos que clubs (ver §11.4 seeds).

**RBAC UI**: el selector de club/sección se limita automáticamente al scope del usuario logueado. Un director de club ve solo su club.

### 9.2. `/dashboard/member-rankings/:memberId/breakdown`

Reutiliza estructura de `/dashboard/rankings/:enrollmentId/breakdown` (8.4-C):
- Header: nombre miembro + sección + club + año + composite badge grande
- 4 cards: Clases | Evidencias | Investiduras | Camporees con score + breakdown numérico
- Sección "Pesos aplicados" (readonly: 4 valores + source)
- Sección "Última actualización" + botón "Recalcular este miembro" (si permiso `member_ranking_weights:write`)

### 9.3. `/dashboard/section-rankings`

- Selector de año + selector de club
- `<DataTable>` con columnas: `#` | Sección | **Composite %** | Miembros activos | Categoría | Acciones
- Botón "Ver miembros" → ruta `/dashboard/section-rankings/:sectionId/members`

### 9.4. `/dashboard/section-rankings/:sectionId/members`

- Header: nombre sección + composite + miembros activos
- Tabla de miembros ordenada por rank_position (misma columnas que `/dashboard/member-rankings`)

### 9.5. `/dashboard/member-ranking-weights`

- Sección "Default global": 4 valores readonly + botón Editar → form modal (shadcn Dialog)
- Tabla "Overrides por tipo + año": columns `Tipo | Año | Clase | Evidencias | Investiduras | Camporees | Suma | Acciones`
- Botón "Agregar override" → Dialog con selects `club_type_id` + `year_id` + 4 inputs
- Validación cliente: sum live en tiempo real, badge rojo si ≠ 100, disable submit si ≠ 100
- `<WeightSumIndicator>` reutilizable (mismo componente que 8.4-C si está disponible)

### 9.6. `/dashboard/award-categories` — extensión

- Agregar columna "Scope" en tabla
- Filter tab: "Todos" | "Club" | "Sección" | "Miembro"
- Form CREATE/EDIT: campo `scope` (select enum con opciones Club/Sección/Miembro)

### 9.7. Stack y componentes reutilizables

Next.js 16 + shadcn/ui + Tailwind v4 + react-hook-form + zod + TanStack Query.

Componentes nuevos:
- `<MemberRankingScoreBadge value={pct} />` — similar a `<RankingScoreBadge>` de 8.4-C con cutoffs de miembro
- `<MemberBreakdownCard signal={'class'|'evidence'|'investiture'|'camporee'} data={...} />` — card reutilizable para los 4 calculadores

Refs de design: `sacdia-admin/DESIGN-SYSTEM.md` (shadcn/ui + Radix, CRUD = Dialog, delete = AlertDialog).

---

## 10. UI Fase 2 — Flutter (sacdia-app)

### 10.1. Pantalla `MyRanking`

Ruta: `/my-ranking` (gateada por `member_visibility ≠ 'hidden'`).

**Contenido**:
- Card principal: composite score % + rank_position + awarded_category (badge con color)
- 4 mini-cards: Clases % | Evidencias % | Investiduras % | Camporees %
- Si `visibility = 'self_and_top_n'`: sección "Top N de mi sección/club" con lista compacta (nombre oculto si así configurado, rank + pct visible)
- Pull to refresh
- Empty state: "Tu puntaje aún no fue calculado" si `composite_calculated_at = null`

**Visibilidad gateada**:
- `'hidden'` → pantalla no visible en nav, deep link devuelve error 403
- `'self_only'` → solo info propia
- `'self_and_top_n'` → info propia + top N

### 10.2. Pantalla `SectionRanking`

Ruta: `/section-ranking` (accesible para directores y asistentes de club).

**Contenido**:
- Header: nombre sección + composite + miembros activos
- Lista de miembros de la sección ordenada por rank_position
- Cada item: rank | nombre | composite % | awarded_category badge

### 10.3. Repository

```dart
abstract class MemberRankingsRepository {
  Future<MemberMyRankingDto> getMyRanking();
  Future<MemberRankingResponseDto> getMemberRanking(int memberId);
  Future<List<MemberRankingResponseDto>> getSectionRankings(int sectionId, int yearId);
}

class MemberRankingsRemoteRepository implements MemberRankingsRepository {
  // HTTP calls to /api/v1/member-rankings/me + /api/v1/section-rankings
  // handles 403 (visibility=hidden) gracefully — no throw, return empty state
}
```

### 10.4. Provider (Riverpod)

```dart
final myRankingProvider = FutureProvider.autoDispose<MemberMyRankingDto?>((ref) async {
  final repo = ref.watch(memberRankingsRepositoryProvider);
  try {
    return await repo.getMyRanking();
  } on ForbiddenException {
    return null; // visibility=hidden, UI muestra empty state
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
1. *_member_rankings_schema.sql     -- 3 tablas nuevas + indexes
2. *_award_categories_scope.sql     -- ALTER + CHECK + backfill + index
3. *_member_rankings_seeds.sql      -- weights default + system_config keys + permisos + grants
4. *_member_rankings_award_seeds.sql -- categorías default scope member + section
```

### 11.2. Archivo 1 — `member_rankings_schema.sql`

Contenido: DDL de `member_rankings` + `section_rankings` + `member_ranking_weights` + todos sus indexes. Ver §4.1, 4.2, 4.3.

### 11.3. Archivo 2 — `award_categories_scope.sql`

Contenido: `ALTER TABLE award_categories ADD COLUMN scope` + CHECK constraint + `UPDATE SET scope='club'` (backfill) + index. Ver §4.4.

### 11.4. Archivo 3 — `member_rankings_seeds.sql`

Contenido:
- `INSERT INTO member_ranking_weights` (default global `40/25/20/15`)
- `INSERT INTO system_config` (3 keys: `member_ranking.recalculation_enabled`, `member_ranking.member_visibility`, `member_ranking.top_n`)
- `INSERT INTO permissions` (10 permisos)
- Grants en `role_permissions` según matriz §4.6

### 11.5. Archivo 4 — `member_rankings_award_seeds.sql`

Contenido: categorías de premio por defecto para `scope = 'member'` y `scope = 'section'`:

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

Si verification post-apply falla:

```sql
BEGIN;

DROP TABLE IF EXISTS member_rankings;
DROP TABLE IF EXISTS section_rankings;
DROP TABLE IF EXISTS member_ranking_weights;

ALTER TABLE award_categories
  DROP COLUMN IF EXISTS scope;
ALTER TABLE award_categories
  DROP CONSTRAINT IF EXISTS chk_award_scope;
DROP INDEX IF EXISTS idx_award_categories_scope;

DELETE FROM system_config WHERE config_key IN (
  'member_ranking.recalculation_enabled',
  'member_ranking.member_visibility',
  'member_ranking.top_n'
);

DELETE FROM permissions WHERE name IN (
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

- `try/catch` per fase (clubs / members / sections).
- Error en `recalculateMemberRankings` no bloquea `recalculateSectionAggregates` (ya hay datos parciales).
- Error per-miembro: `logger.error({member_id, year_id, error}) + skip`. No propaga al loop del club.
- Error per-sección: `logger.error({section_id, year_id, error}) + skip`.
- BullMQ retry 5x con exponential backoff si el job se encola (mismo patrón 8.4-C).
- Fallback a direct execution si Redis down.

### 12.2. Calculadores

- Calculadores NUNCA hacen throw por dato faltante. Retornan NULL en datos insuficientes.
- División por cero siempre produce NULL, no error.
- La redistribución de NULLs en composite garantiza que ningún NULL individual rompe el composite si hay al menos 1 score válido.

### 12.3. API Guards

| Condición | HTTP | Mensaje |
|-----------|------|---------|
| RBAC no matchea | 403 | `GUARD_PERMISSION_DENIED` |
| `visibility = 'hidden'` y miembro pide `/me` | 403 | `MEMBER_RANKING_HIDDEN` |
| `memberId` no existe en `year_id` | 404 | `MEMBER_RANKING_NOT_FOUND` |
| Body weights suma ≠ 100 | 400 | `WEIGHTS_SUM_INVALID` |
| Duplicate `(club_type_id, year_id)` en weights | 409 | `WEIGHTS_CONFLICT` |
| DELETE sobre default global | 400 | `DEFAULT_WEIGHTS_NOT_DELETABLE` |
| `ParseUUIDPipe` en param no UUID | 400 | NestJS default |

**Atención**: los `member_id` y `club_section_id` son INTEGER (no UUID). NO usar `ParseUUIDPipe` en esos params. Solo usar `ParseUUIDPipe` en `awarded_category_id` y `id` de `member_ranking_weights`. Ver bug 8.4-C documentado en engram #1883 / PR #28 (controller order bug con ParseUUIDPipe).

---

## 13. Observabilidad y logs

### 13.1. Logs estructurados

```
[member-rankings] Recalc started year_id=X club_count=Y
[member-rankings] Club X processed members=N skipped=K duration_ms=Z
[member-rankings] Section aggregates started sections=M
[member-rankings] Section aggregates done sections=M empty=K errors=E
[member-rankings] Recalc done duration_ms=TOTAL members_total=N sections_total=M errors=E
```

### 13.2. Métricas Prometheus (si disponible)

Siguiendo patrón 8.4-C:
- `member_ranking_calc_duration_ms{signal=class|evidence|investiture|camporee|composite}`
- `member_ranking_calc_errors_total{signal=..., reason=...}`
- `section_ranking_aggregate_duration_ms`
- `section_ranking_empty_total` (secciones con 0 miembros activos)

### 13.3. Audit timestamp

`composite_calculated_at` per row en `member_rankings` y `section_rankings` = timestamp del último recálculo. Permite detectar stale data (composite calculado hace > 48h).

---

## 14. Testing strategy

### 14.1. Unit (Jest TDD — 8 specs)

1. `class-score.service.spec.ts`
   - Happy path: 3/5 clases completadas → 60.00
   - required_count = 0 → NULL
   - completed > required (edge) → clamped a 100

2. `evidence-score.service.spec.ts`
   - Happy path: 8/10 evidencias → 80.00
   - total_evidences = 0 → NULL
   - 100% attended → 100.00

3. `investiture-score.service.spec.ts`
   - Happy path: 2/3 investiduras → 66.67
   - eligible_count = 0 → NULL (NO 100 — decisión crítica)
   - achieved > eligible (data corruption edge) → clamped a 100

4. `camporee-score.service.spec.ts` (per-member)
   - Happy path: asistió a 1/2 → 50.00
   - total_camporees = 0 → NULL
   - Miembro sin union_id → solo camporees nacionales en denominador

5. `member-composite-score.service.spec.ts`
   - Todos los scores disponibles: weighted average con pesos default
   - Un score NULL: redistribución proporcional
   - Todos los scores NULL → composite = NULL
   - Override de weights por club_type_id aplicado correctamente

6. `section-aggregation.service.spec.ts`
   - Sección con 3 miembros activos: AVG correcto
   - Sección con 0 miembros activos → composite = NULL, count = 0
   - Sección con miembros NULL composite: AVG ignora NULLs (PostgreSQL default)

7. `member-ranking-weights.service.spec.ts`
   - CRUD + validación CHECK SUM=100
   - Resolver: fallback default cuando no existe override
   - DELETE default → error

8. `award-categories-scope.spec.ts`
   - GET filtra por scope correctamente
   - POST requiere scope enum válido
   - PATCH scope solo por admin

### 14.2. Integration (NestJS Test.createTestingModule — 2 specs)

9. `member-rankings.controller.spec.ts`
   - RBAC matrix: member self → 200; member otro memberId → 403; director-club mismo club → 200; director-club otro club → 403; director-lf → 200 scope LF
   - GET /me con `visibility = 'hidden'` → 403
   - GET /me con `visibility = 'self_and_top_n'` → incluye `top_n`

10. `section-rankings.controller.spec.ts`
    - director-club → 200 filtrado por club; assistant-club → 200 filtrado por sección; member → 403

### 14.3. E2E (detecta bugs tipo ParseUUIDPipe order — engram #1883/#1888)

11. `member-rankings.e2e-spec.ts`
    - HTTP real: GET `/member-rankings/` devuelve 200 (no 400 por ParseUUIDPipe order)
    - POST `/member-rankings/recalculate` devuelve 200 o 201

12. `section-rankings.e2e-spec.ts`
    - HTTP real: GET `/section-rankings/` devuelve 200

### 14.4. Smoke E2E manual post-merge

1. Trigger `POST /api/v1/member-rankings/recalculate` con kill-switch ON → verificar `member_rankings` + `section_rankings` populated en Neon dev
2. Verificar que `section_rankings.composite_score_pct` = AVG manual de `member_rankings.composite_score_pct` para una sección con ≥2 miembros
3. Probar RBAC negativo: member intentando ver otro member → 403
4. Probar `visibility = 'hidden'`: member llama `/me` → 403
5. Probar `visibility = 'self_and_top_n'`: verificar que respuesta incluye `top_n` array
6. App móvil Fase 2: smoke `MyRanking` con credenciales de member real en dev

---

## 15. Open questions / fuera de scope

### 15.1. Fuera de scope (explícito para 8.4-A)

- Visibilidad usuario final en app (cubierta conceptualmente en Fase 2, implementación posterior)
- Periodicidades menores que anual (sub-feature D)
- Agrupación regional/multi-club (sub-feature E)
- Notificaciones FCM por cambio de ranking de miembro (futuro)
- Ranking histórico retroactivo para años anteriores
- Export CSV / PDF del ranking de miembros
- Gráficos de evolución histórica del score de un miembro

### 15.2. Open questions — a resolver en plan phase

| # | Pregunta | Impacto |
|---|----------|---------|
| OQ1 | ¿La tabla de investiduras per-member tiene `achieved_year_id` o `year_id`? ¿Qué valores tiene `status`? | `InvestitureScoreService` — audit A6 |
| OQ2 | ¿Existe `evidence_attendance` per-member o solo evaluaciones a nivel carpeta/sección? | `EvidenceScoreService` — audit A5 |
| OQ3 | ¿`member_class_progress` tiene columna `year_id` o se une vía `class_enrollment` → `year_id`? | `ClassScoreService` — audit A4 |
| OQ4 | ¿`camporee_attendees` registra per-member o solo per-club? Si per-club, `CamporeeScoreService` no puede implementarse sin nueva tabla | audit A7 |
| OQ5 | ¿El rol `member` es un role en tabla `roles` o es implicado por tener registro en `members`? | Grant de `member_rankings:read_self` |
| OQ6 | ¿Los IDs de años son `year_id` (tabla `years`) o `ecclesiastical_year_id` (tabla `ecclesiastical_years`)? | FK en todas las tablas nuevas — audit A10 |

---

## 16. Criterios de aceptación — DoR / DoD

### Definition of Ready (antes de comenzar implementación)

- [ ] Audit A1-A10 completado contra Neon dev; discrepancias documentadas y resoluciones acordadas
- [ ] OQ4 respondida: si `camporee_attendees` no existe per-member, `CamporeeScoreService` marcado como bloqueado con issue abierto
- [ ] 4 migrations validadas en dry-run contra schema actual
- [ ] RBAC matrix revisada y aprobada por responsable de producto
- [ ] Cutoffs de categorías (§11.5) aprobados por dirección

### Definition of Done — Backend

- [ ] 3 tablas creadas en Neon dev + staging con pattern TXN atómico (engram #1204/#1296/#1839)
- [ ] `award_categories.scope` migrado con backfill y sin broken rows
- [ ] 10 permisos creados y grants asignados en seed
- [ ] 3 system_config keys insertadas
- [ ] 6 servicios de cálculo implementados y testeados (8 unit specs passing)
- [ ] 3 controllers implementados con RBAC correcto (2 integration specs + 2 e2e specs passing)
- [ ] Cron extendido con pasos 2 y 3 sin romper paso 1 (8.4-C)
- [ ] Kill-switch `member_ranking.recalculation_enabled` funciona: si `false`, no se recalculan miembros/secciones
- [ ] Flag `member_visibility` funciona: `hidden` → 403 en `/me`
- [ ] Smoke E2E manual completado en Neon dev

### Definition of Done — Admin (Fase 1)

- [ ] 4 páginas nuevas implementadas en sacdia-admin
- [ ] `/dashboard/award-categories` extendida con tab scope
- [ ] RBAC admin respeta scope del usuario logueado
- [ ] Design System alineado: shadcn/ui, Dialog para CREATE/EDIT, AlertDialog para DELETE

### Definition of Done — Flutter (Fase 2)

- [ ] `MyRanking` pantalla implementada con manejo correcto de 3 estados de `member_visibility`
- [ ] `SectionRanking` pantalla implementada
- [ ] Repository + Provider implementados
- [ ] Smoke en dev con creds de member real

### Canon updates al cierre

- [ ] `docs/canon/runtime-rankings.md` → agregar §14 para 8.4-A (miembro + sección)
- [ ] `docs/canon/decisiones-clave.md` → nueva decisión §23
- [ ] `docs/api/ENDPOINTS-LIVE-REFERENCE.md` → 4 nuevos grupos de endpoints
- [ ] `docs/database/SCHEMA-REFERENCE.md` → 3 tablas nuevas + extensión award_categories
- [ ] `docs/features/README.md` → entry "Clasificación sección y miembro"
