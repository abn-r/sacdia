# Clasificación institucional ampliada — Criterios ampliados (8.4-C)

**Fecha**: 2026-04-28
**Estado**: SPEC APROBADO PARA IMPLEMENTACIÓN
**Origen**: línea 8.4 del roadmap `docs/bases/SACDIA_Bases_del_Proyecto-normalizado.md`, sub-feature **C** (criterios ampliados) de la decomposición acordada (C → A → B → D → E)
**Stack agentes**: exploración Haiku/Sonnet, planeación Opus, implementación + tests Sonnet
**Engram topic key**: `sacdia/strategy/8-4-c-criterios-ampliados-spec`

---

## 1. Contexto y motivación

Hoy `club_annual_rankings.total_earned_points` viene 100% de evaluación de carpetas anuales (`annual_folder_section_evaluations`). El roadmap 8.4 plantea ampliar la clasificación institucional. La sub-feature C agrega 3 criterios institucionales adicionales como porcentajes 0-100 que se combinan en un **composite score** ponderado:

| Criterio | Fuente | Métrica |
|---|---|---|
| Folder (existente, re-expresado) | `annual_folder_section_evaluations` | `SUM(earned_points) / SUM(max_points) × 100` |
| Finanzas | `finance_period_closing` | `meses_cerrados_a_tiempo / 12 × 100` |
| Camporees | `camporee_clubs` ∪ `local_camporees` ∪ `union_camporees` | `% participación en camporees del scope del club (filtrado por union_id)` |
| Evidencias | `folders_section_records` | `VALIDATED / (VALIDATED + REJECTED) × 100`; default 0 si denom = 0 |

El composite score se calcula como weighted average con pesos configurables (default global + override opcional por `club_type`).

### Decisiones canónicas tomadas en brainstorming

| # | Decisión |
|---|---|
| Q3 | Criterios iniciales: Finanzas (4) + Camporees (6) + Evidencias (7). Asistencia, progresión clases, honores, investiduras, comunicaciones, achievements, solicitudes membresía → fuera de scope inicial. |
| Q4 | Integración: opción **C** — sub-scores extendiendo `club_annual_rankings` con columnas adicionales + `composite_score_pct`. |
| Q5 | Pesos: opción **D** — defaults globales en `system_config` + override opcional por `club_type` en tabla nueva. |
| Q6 | Normalización: opción **A** — todos los componentes a porcentaje 0-100. Composite = weighted average de porcentajes. |
| Q7 | Históricos: opción **A** — solo current year forward. Años previos quedan con `0` en columnas nuevas (vía `DEFAULT 0`); su `rank_position` legacy no se recalcula. |
| Q8 | Finanzas deadline: opción **B** — `system_config.ranking.finance_closing_deadline_day` (default 5). |
| Q9 | Camporees max: opción **B** — denominador filtrado por `union_id` del club; nacionales (`union_id IS NULL`) aplican a todos. |
| Q10 | Evidencias denom: opción **A + default 0** — `VALIDATED / (VALIDATED + REJECTED)`, default 0 si denom = 0. |
| Q11 | Recálculo: opción **C** — cron diario `@Cron('0 2 * * *')` UTC + endpoint manual existente, lock distribuido 10min. |
| Q12 | Award categories: opción **A** para fase inicial — categorías solo sobre composite. Reconocimientos por componente quedan para fase posterior. |
| Q13 | Migración award_categories: opción **B** — columnas nuevas `min_composite_pct` / `max_composite_pct` + flag `is_legacy`. Columnas viejas (`min_points`/`max_points`) quedan inertes. Admin debe re-configurar para 2026+. |
| Q14 | Validación pesos: opción **A** — suma estricta = 100, validación dura DB (`CHECK`) + API (HTTP 400). |
| Q15 | API: opción **A + D** — extender DTOs existentes con sub-scores + composite, agregar sub-resource `/breakdown` para drill-down. |
| Q16 | Admin UI: opción **B** — extender vista rankings + nueva pantalla `/dashboard/ranking-weights`. Drill-down (Pantalla 2) entra como apoyo a Pantalla 1. |

---

## 2. Modelo de datos

### 2.1. Extensión de `club_annual_rankings`

```sql
ALTER TABLE club_annual_rankings
  ADD COLUMN folder_score_pct numeric(5,2) NOT NULL DEFAULT 0,
  ADD COLUMN finance_score_pct numeric(5,2) NOT NULL DEFAULT 0,
  ADD COLUMN camporee_score_pct numeric(5,2) NOT NULL DEFAULT 0,
  ADD COLUMN evidence_score_pct numeric(5,2) NOT NULL DEFAULT 0,
  ADD COLUMN composite_score_pct numeric(5,2) NOT NULL DEFAULT 0,
  ADD COLUMN composite_calculated_at timestamptz;

CREATE INDEX idx_rankings_composite
  ON club_annual_rankings (ecclesiastical_year_id, composite_score_pct DESC);
```

- `total_earned_points` y `progress_percentage` quedan (legacy folder absoluto, sigue mostrándose para detalle).
- `rank_position` se reasigna basado en `composite_score_pct DESC` con dense ranking (mantiene política canónica `runtime-rankings.md` §6).
- Unicidad existente `(club_enrollment_id, ecclesiastical_year_id, award_category_id)` no cambia.

### 2.2. Tabla nueva `ranking_weight_configs`

```sql
CREATE TABLE ranking_weight_configs (
  ranking_weight_config_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  club_type_id int UNIQUE,
  folder_weight int NOT NULL,
  finance_weight int NOT NULL,
  camporee_weight int NOT NULL,
  evidence_weight int NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid,
  CONSTRAINT weights_sum_100 CHECK (
    folder_weight + finance_weight + camporee_weight + evidence_weight = 100
  ),
  CONSTRAINT weight_ranges CHECK (
    folder_weight BETWEEN 0 AND 100
    AND finance_weight BETWEEN 0 AND 100
    AND camporee_weight BETWEEN 0 AND 100
    AND evidence_weight BETWEEN 0 AND 100
  ),
  FOREIGN KEY (club_type_id) REFERENCES club_types(club_type_id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX idx_ranking_weights_default
  ON ranking_weight_configs ((club_type_id IS NULL))
  WHERE club_type_id IS NULL;

INSERT INTO ranking_weight_configs (club_type_id, folder_weight, finance_weight, camporee_weight, evidence_weight)
VALUES (NULL, 60, 15, 15, 10);
```

- `club_type_id IS NULL` → row default global (única, garantizada por índice parcial).
- `club_type_id = X` → override específico para ese tipo.
- Service resuelve override por `club_type_id`, fallback al default.

### 2.3. Extensión de `award_categories`

```sql
ALTER TABLE award_categories
  ADD COLUMN min_composite_pct numeric(5,2),
  ADD COLUMN max_composite_pct numeric(5,2),
  ADD COLUMN is_legacy boolean NOT NULL DEFAULT false;

UPDATE award_categories SET is_legacy = true WHERE created_at < '2026-04-28';
```

- Service nuevo lee solo categorías con `is_legacy = false AND min_composite_pct IS NOT NULL`.
- Admin debe crear nuevas categorías para 2026+ con thresholds en escala 0-100.
- Categorías viejas (`is_legacy = true`) preservadas para auditoría histórica.

### 2.4. `system_config` — keys nuevas

```sql
INSERT INTO system_config (key, value, description) VALUES
  ('ranking.finance_closing_deadline_day', '5',
   'Día del mes siguiente para considerar cierre financiero a tiempo'),
  ('ranking.recalculation_enabled', 'true',
   'Kill-switch para recálculo extendido')
ON CONFLICT (key) DO NOTHING;
```

---

## 3. Fórmulas de cálculo

Todas las fórmulas operan por `(club_enrollment_id, ecclesiastical_year_id)`.

### 3.1. `folder_score_pct`

```
SUM(earned_points) / NULLIF(SUM(max_points), 0) × 100
  FROM annual_folder_section_evaluations e
  JOIN annual_folders f ON f.annual_folder_id = e.annual_folder_id
  WHERE f.club_enrollment_id = X
    AND f.ecclesiastical_year_id = Y
    AND e.status IN ('VALIDATED', 'closed')
```

Default 0 si `SUM(max_points) = 0`.

### 3.2. `finance_score_pct`

```
deadline_day := system_config['ranking.finance_closing_deadline_day']  -- default 5

months_closed_on_time := COUNT(*)
  FROM finance_period_closing
  WHERE club_id = X
    AND (year, month) ∈ months_of(ecclesiastical_year_id = Y)
    AND closed_at IS NOT NULL
    AND closed_at <= make_timestamptz(year, month + 1, deadline_day, 23, 59, 59, 'UTC')

finance_score_pct := MIN((months_closed_on_time / 12.0) × 100, 100)
```

### 3.3. `camporee_score_pct`

```
union_id_of_club := club.union_id (vía club_enrollment.club_id → clubs.union_id)

denom_camporees := SELECT camporee_id, source FROM (
    SELECT local_camporee_id AS camporee_id, 'local' AS source, union_id
      FROM local_camporees
      WHERE ecclesiastical_year = Y AND active = true
    UNION ALL
    SELECT union_camporee_id AS camporee_id, 'union' AS source, union_id
      FROM union_camporees
      WHERE ecclesiastical_year = Y AND active = true
  ) t
  WHERE union_id = union_id_of_club OR union_id IS NULL  -- nacionales aplican a todos

numer := COUNT(DISTINCT camporee_id)
  FROM camporee_clubs
  WHERE club_id = X
    AND status = 'approved'
    AND camporee_id ∈ denom_camporees

camporee_score_pct := denom > 0 ? (numer / denom) × 100 : 0
```

Edge case: club sin `union_id` → solo cuentan camporees con `union_id IS NULL`.

### 3.4. `evidence_score_pct`

```
validated := COUNT(*)
  FROM folders_section_records r
  JOIN folders f ON f.folder_id = r.folder_id
  WHERE r.club_section_id ∈ sections_of_club(X)
    AND f.year = Y
    AND r.status = 'VALIDATED'

rejected := COUNT(*)
  FROM folders_section_records r
  JOIN folders f ON f.folder_id = r.folder_id
  WHERE r.club_section_id ∈ sections_of_club(X)
    AND f.year = Y
    AND r.status = 'REJECTED'

denom := validated + rejected
evidence_score_pct := denom > 0 ? (validated / denom) × 100 : 0
```

### 3.5. `composite_score_pct`

```
weights := SELECT folder_weight, finance_weight, camporee_weight, evidence_weight
  FROM ranking_weight_configs
  WHERE club_type_id = X.club_type_id
  LIMIT 1

IF weights NOT FOUND THEN
  weights := SELECT ... FROM ranking_weight_configs WHERE club_type_id IS NULL LIMIT 1
END

composite_score_pct := (
    folder_score_pct    × weights.folder_weight
  + finance_score_pct   × weights.finance_weight
  + camporee_score_pct  × weights.camporee_weight
  + evidence_score_pct  × weights.evidence_weight
) / 100.0
```

Resultado garantizado en rango `[0.00, 100.00]` por validación `weights_sum_100`.

---

## 4. Recálculo (cron + manual)

**Archivo target**: `sacdia-backend/src/annual-folders/rankings.service.ts` (extensión, no nuevo módulo).

### 4.1. Cron

```typescript
@Cron('0 2 * * *', { name: 'rankings-recalculation', timeZone: 'UTC' })
async handleRankingsRecalculation()
```

Sin cambio en firma. Lógica interna extendida a 4 calculadores + composite + reasignación de `rank_position`.

### 4.2. Endpoint manual

```
POST /annual-folders/rankings/recalculate?year_id=...
```

Sin cambio contractual. Mismo lock + rate limit (1/5min). Internamente trigger del flow extendido.

### 4.3. Lifecycle

```
1. Verificar system_config['ranking.recalculation_enabled']
   - Si false → log.warn + return { skipped: true }
2. Adquirir lock distribuido (year_id, 'extended-rankings')  TTL 10min
3. Resolver año eclesiástico (default = activo)
4. Listar club_enrollments con folder.status ∈ ('evaluated', 'closed') del año
5. Para cada enrollment (batched por chunks de 50):
   a. folder_score_pct  := calcFolderScore(enrollment, year)
   b. finance_score_pct := calcFinanceScore(club_id, year)
   c. camporee_score_pct := calcCamporeeScore(club_id, union_id, year)
   d. evidence_score_pct := calcEvidenceScore(club_id, year)
   e. weights := resolveWeights(club_type_id)
   f. composite_score_pct := sumWeighted(scores, weights)
   g. UPSERT club_annual_rankings:
      - row sentinel (award_category_id = '00000000-...')
      - row por cada award_category aplicable (composite ∈ [min_composite_pct, max_composite_pct])
      SET *_score_pct, composite_score_pct, composite_calculated_at = now()
6. assignRankPositions(year_id):
   - GROUP BY (club_type_id, ecclesiastical_year_id, award_category_id)
   - ORDER BY composite_score_pct DESC
   - dense ranking (mantiene política canónica)
7. Liberar lock
8. Log estructurado por enrollment + métricas Prometheus por componente
```

### 4.4. Idempotencia

- Cada calculador es función pura: `(club_id | enrollment_id, year_id) → numeric(5,2)`.
- UPSERT usa unique key `(club_enrollment_id, ecclesiastical_year_id, award_category_id)` existente.
- Re-ejecuciones producen mismos valores si data fuente no cambió.

### 4.5. Observabilidad

- Métricas (Prometheus): `ranking_calc_duration_ms{component=folder|finance|camporee|evidence|composite}`.
- Log estructurado: `{enrollment_id, year_id, scores: {...}, composite, weights_source: 'default'|'override', duration_ms}`.
- `cron_alerts_log` (Phase 3.2 existente) recibe alert si duración > 5min o exception en lote.
- Métricas de error: `ranking_calc_errors_total{component=...}`.

### 4.6. Kill-switch

`system_config['ranking.recalculation_enabled'] = 'false'` frena cron y manual sin redeploy. Útil para incidentes.

---

## 5. API

### 5.1. Endpoints existentes — extendidos (no breaking)

#### `GET /annual-folders/rankings?club_type_id&year_id[&category_id]`
Permiso: `rankings:read`. Response shape extendida:

```json
{
  "rankings": [
    {
      "ranking_id": "uuid",
      "club_enrollment_id": "uuid",
      "club_name": "...",
      "club_type_id": 1,
      "ecclesiastical_year_id": 5,
      "award_category_id": "uuid",
      "rank_position": 1,
      "total_earned_points": 1240,
      "progress_percentage": 78.5,
      "folder_score_pct": 78.50,
      "finance_score_pct": 91.66,
      "camporee_score_pct": 50.00,
      "evidence_score_pct": 88.00,
      "composite_score_pct": 76.85,
      "composite_calculated_at": "2026-04-28T02:00:13Z",
      "calculated_at": "2026-04-28T02:00:13Z"
    }
  ]
}
```

`rank_position` ahora se calcula sobre `composite_score_pct`. Es un cambio semántico intencional, comunicado en CHANGELOG y canon update. No hay consumers prod del ranking ampliado (feature nueva).

#### `GET /annual-folders/rankings/club/:enrollmentId?year_id`
Mismo shape extendido.

#### `POST /annual-folders/rankings/recalculate?year_id`
Sin cambios contractuales. Internamente flow extendido.

### 5.2. Endpoint nuevo — drill-down

#### `GET /annual-folders/rankings/:enrollmentId/breakdown?year_id`
Permiso: `rankings:read`.

```json
{
  "enrollment_id": "uuid",
  "year_id": 5,
  "composite_score_pct": 76.85,
  "weights_applied": {
    "folder": 60, "finance": 15, "camporee": 15, "evidence": 10,
    "source": "default" | "club_type_override"
  },
  "components": {
    "folder": {
      "score_pct": 78.50,
      "earned_points": 1240,
      "max_points": 1580,
      "sections_evaluated": 12
    },
    "finance": {
      "score_pct": 91.66,
      "months_closed_on_time": 11,
      "months_total": 12,
      "deadline_day": 5,
      "missed_months": [3]
    },
    "camporee": {
      "score_pct": 50.00,
      "attended": 1,
      "available_in_scope": 2,
      "events": [
        { "id": "uuid", "name": "Camporee Unión 2026", "status": "approved" },
        { "id": "uuid", "name": "Camporee Local Q2", "status": null }
      ]
    },
    "evidence": {
      "score_pct": 88.00,
      "validated": 22,
      "rejected": 3,
      "pending_excluded": 8
    }
  }
}
```

### 5.3. CRUD para `ranking_weight_configs`

Permisos nuevos: `ranking_weights:read`, `ranking_weights:write`.

```
GET    /ranking-weights              -> lista (default + overrides)
GET    /ranking-weights/:id          -> detalle
POST   /ranking-weights              -> crear override por club_type
PATCH  /ranking-weights/:id          -> update
DELETE /ranking-weights/:id          -> eliminar override (default no eliminable)
```

Validaciones:
- `folder + finance + camporee + evidence = 100` (HTTP 400 si no)
- `club_type_id` único en tabla (HTTP 409 si duplicate)
- DELETE sobre row con `club_type_id = NULL` → HTTP 400

### 5.4. CRUD para `award_categories` — extendido

Sin endpoints nuevos, solo nuevos campos en POST/PATCH body:
- `min_composite_pct`, `max_composite_pct` (numeric 0-100, opcionales).
- Validación: `min_composite_pct >= 0 AND max_composite_pct <= 100 AND min_composite_pct < max_composite_pct`.
- GET filtra `is_legacy = false` por default; `?include_legacy=true` para histórico.

---

## 6. Admin UI

### 6.1. `/dashboard/rankings` (extendida)

Tabla con columnas (de izq a der): `#` (rank_position) | Club | **Composite %** (badge color: verde ≥80, ámbar 60-79, rojo <60) | Folder % | Finance % | Camporee % | Evidence % | Categoría premio | Acciones (link a breakdown).

Header: select año + select club_type + button "Recalcular ahora" (con confirmation modal por rate limit).

Vacío state: si año sin rankings calculados → CTA "Ejecutar primer cálculo" (requiere `rankings:recalculate`).

### 6.2. `/dashboard/rankings/:enrollmentId/breakdown` (nueva)

Header: nombre club + tipo + año + composite badge grande. 4 cards (folder, finance, camporee, evidence) con `score_pct` + breakdown numérico (ver §5.2). Sección "Pesos aplicados" readonly (los 4 weights + source). Sección "Última actualización" + button "Recalcular este club" si permiso.

### 6.3. `/dashboard/ranking-weights` (nueva)

- Sección "Default global": readonly visual, click para editar inline form (4 inputs + suma live, badge rojo si != 100).
- Tabla "Overrides por tipo de club": columns `Tipo de club | Folder | Finance | Camporee | Evidence | Suma | Acciones`. Button "Agregar override" → modal con select `club_type_id` (solo tipos sin override existente) + 4 inputs.
- Validación cliente: sum live, disable submit si != 100.
- Validación server: cubierto en API (HTTP 400).

Permisos UI:
- `ranking_weights:read` → ver pantallas
- `ranking_weights:write` → forms editables + acciones CRUD

### 6.4. `/dashboard/award-categories` (extendida)

Form CRUD agrega:
- Inputs `min_composite_pct` / `max_composite_pct` (numeric 0-100).
- Marcar visualmente categorías `is_legacy = true` (badge "Legacy" + readonly).
- Tab/filter "Activas" (default) / "Legacy" para inspección.

### 6.5. Componentes reutilizables

- `<RankingScoreBadge value={pct} />` — color-coded por rango.
- `<WeightInput weight={n} onChange={...} />` — input numérico 0-100.
- `<WeightSumIndicator weights={...} />` — muestra suma + badge OK/error.

### 6.6. Stack

Next.js 16 + shadcn/ui + Tailwind v4 + react-hook-form + zod + TanStack Query. `<DataTable>` componente existente. Refs en `sacdia-admin/DESIGN-SYSTEM.md`.

---

## 7. Permisos RBAC

Agregar en `sacdia-backend/prisma/seed-permissions.ts`:
- `ranking_weights:read`
- `ranking_weights:write`

Asignación a roles globales:
- `super_admin` → `read` + `write`
- `union_admin` → `read` + `write`
- `field_admin`, `local_admin` → `read` solamente

CI verifica drift admin↔seed (existente per commit 534d3a5).

---

## 8. Tests

### 8.1. Backend

Unit (`sacdia-backend/src/annual-folders/rankings.service.spec.ts`):
- `calcFolderScore`: refactor + tests existentes preservados, agregar test de `SUM(max_points) = 0` → 0.
- `calcFinanceScore`:
  - 12 cerrados a tiempo → 100.
  - 0 cerrados → 0.
  - 6 cerrados, 3 tarde (excede deadline) → 50 con `months_closed_on_time = 6`.
  - Año parcial (mes 4 actual) → calcula sobre 12 meses (no se ajusta por año en curso).
  - `deadline_day` configurable: setear a 10, repetir test de "tarde" para verificar.
- `calcCamporeeScore`:
  - Club sin `union_id` (NULL) → solo cuenta camporees con `union_id IS NULL`.
  - Unión con 0 camporees activos → 0 (con `denom = 0`).
  - Asistió a todos del scope → 100.
  - Mix local + union + nacional → calcular bien denom + numer.
- `calcEvidenceScore`:
  - 0 evaluadas → 0 (default).
  - 100% validated → 100.
  - 100% rejected → 0.
  - Mix 22 validated + 3 rejected → 88.00.
- `composite`:
  - Weights default (60/15/15/10) sobre scores conocidos.
  - Weights override por `club_type` aplicado correctamente.
  - Weights que no suman 100 → DB rechaza el INSERT/UPDATE (constraint test).

Integration (controllers):
- `ranking-weights.controller.spec.ts` — CRUD + validaciones HTTP 400/409.
- `rankings.controller.spec.ts` — extended response shape + `/breakdown` endpoint.
- Cron: simular `handleRankingsRecalculation` con kill-switch on/off, lock acquired.

### 8.2. Admin

- `RankingWeightsForm.test.tsx` — sum validation live, default no eliminable.
- `BreakdownView.test.tsx` — render por componente con data mocked.
- `RankingsTable.test.tsx` — composite column + color rangos.

### 8.3. E2E manual smoke

1. Setear weights override Conquistadores (50/20/20/10).
2. Trigger recálculo manual → breakdown muestra `weights_applied.source = 'club_type_override'`.
3. Crear award_category `min_composite_pct=80, max_composite_pct=100` → club con composite 85 califica + aparece en ranking de esa categoría.

---

## 9. Migración (Neon)

Neon shadow DB roto → `prisma migrate dev` no funciona. Aplicar **manual con `psql`** contra las 3 ramas, registrando atómicamente en `_prisma_migrations`. Pattern reproducible engram #1204 → #1296 → #1839.

### 9.1. Connection strings

NO hardcodear URLs ni passwords en el spec, código, env vars, ni shell history. Resolver runtime vía neonctl:

```bash
neonctl connection-string development --project-id wispy-hall-32797215
neonctl connection-string staging     --project-id wispy-hall-32797215
neonctl connection-string production  --project-id wispy-hall-32797215
```

(Si los nombres reales de branch difieren, validar con `neonctl branches list --project-id wispy-hall-32797215` antes de aplicar.)

### 9.2. Binario psql

Usar el cliente moderno (no el viejo del system):

```bash
/opt/homebrew/opt/libpq/bin/psql
```

Si falta: `brew install libpq`.

### 9.3. Migration files (hand-written)

Crear bajo `sacdia-backend/prisma/migrations/`:

```
20260428000000_extended_rankings_schema/
  migration.sql          -- DDL: ALTER club_annual_rankings + ALTER award_categories + UPDATE legacy flag
20260428000100_ranking_weight_configs/
  migration.sql          -- DDL: CREATE TABLE ranking_weight_configs + índice parcial + seed default global
20260428000200_ranking_system_config/
  migration.sql          -- DDL: INSERT system_config keys (deadline_day + recalculation_enabled)
```

Separar en 3 archivos para granularidad de rollback y tracking en `_prisma_migrations`.

### 9.4. Pattern atómico TXN + registro

Para cada branch + cada migration:

```sql
BEGIN;

\i sacdia-backend/prisma/migrations/<timestamp>_<name>/migration.sql

INSERT INTO _prisma_migrations (
  id,
  checksum,
  finished_at,
  migration_name,
  logs,
  rolled_back_at,
  started_at,
  applied_steps_count
) VALUES (
  gen_random_uuid()::text,
  'manual',
  NOW(),
  '<timestamp>_<name>',
  NULL,
  NULL,
  NOW(),
  1
);

COMMIT;
```

Si el bloque falla en cualquier punto → ROLLBACK automático, branch queda como estaba.

### 9.5. Order de execution

Por cada migration (3 archivos), aplicar en orden de branches **dev → staging → production**.

```bash
# Por migration:
PGPASSWORD=... psql "$(neonctl connection-string development --project-id wispy-hall-32797215)" \
  -v ON_ERROR_STOP=1 -f apply_<timestamp>.sql

PGPASSWORD=... psql "$(neonctl connection-string staging --project-id wispy-hall-32797215)" \
  -v ON_ERROR_STOP=1 -f apply_<timestamp>.sql

PGPASSWORD=... psql "$(neonctl connection-string production --project-id wispy-hall-32797215)" \
  -v ON_ERROR_STOP=1 -f apply_<timestamp>.sql
```

`ON_ERROR_STOP=1` aborta el script al primer error.

### 9.6. Pre-check antes de cada apply

```sql
-- Para migration extended_rankings_schema (verificar columnas missing):
SELECT column_name FROM information_schema.columns
  WHERE table_name = 'club_annual_rankings'
    AND column_name IN ('folder_score_pct','finance_score_pct','camporee_score_pct','evidence_score_pct','composite_score_pct','composite_calculated_at');
-- Esperado: 0 rows (columnas missing)

-- Para migration ranking_weight_configs (verificar tabla missing):
SELECT to_regclass('public.ranking_weight_configs');
-- Esperado: NULL

-- Para migration system_config keys (verificar keys missing):
SELECT key FROM system_config
  WHERE key IN ('ranking.finance_closing_deadline_day','ranking.recalculation_enabled');
-- Esperado: 0 rows
```

Si pre-check muestra estado parcial → no aplicar, investigar drift.

### 9.7. Verification post-apply

Por branch, después de cada migration:

```sql
-- 1. Tabla/columnas creadas físicamente:
SELECT column_name FROM information_schema.columns
  WHERE table_name = 'club_annual_rankings' AND column_name LIKE '%_score_pct';
-- Esperado: 5 rows

SELECT to_regclass('public.ranking_weight_configs');
-- Esperado: oid (no NULL)

-- 2. Default global insertado:
SELECT folder_weight, finance_weight, camporee_weight, evidence_weight
  FROM ranking_weight_configs WHERE club_type_id IS NULL;
-- Esperado: 60, 15, 15, 10

-- 3. Legacy flag aplicado:
SELECT COUNT(*) FROM award_categories WHERE is_legacy = true;
-- Esperado: COUNT igual al pre-existing total

-- 4. _prisma_migrations registrado:
SELECT migration_name, applied_steps_count FROM _prisma_migrations
  WHERE migration_name LIKE '20260428%';
-- Esperado: 3 rows con applied_steps_count=1
```

### 9.8. Post-migration en backend

```bash
cd sacdia-backend
pnpm prisma generate           # regenerar Prisma Client con nuevas columnas/tabla
pnpm tsc --noEmit              # verify TS clean (Prisma types up-to-date)
```

### 9.9. Permisos RBAC

`seed-permissions.ts` (Phase E) corre vía:

```bash
cd sacdia-backend
pnpm prisma db seed -- --only=permissions
```

Aplicar contra las 3 ramas seteando `DATABASE_URL` temporalmente al output de `neonctl connection-string`.

### 9.10. Rollback plan

Si verification post-apply falla en una branch:
- Migration está dentro de TXN → estado de la branch sin cambios (BEGIN/COMMIT garantiza atomicidad).
- Si COMMIT pasó pero verification falla por bug en pre-check → DDL reverso manual:

```sql
BEGIN;
ALTER TABLE club_annual_rankings
  DROP COLUMN IF EXISTS folder_score_pct,
  DROP COLUMN IF EXISTS finance_score_pct,
  DROP COLUMN IF EXISTS camporee_score_pct,
  DROP COLUMN IF EXISTS evidence_score_pct,
  DROP COLUMN IF EXISTS composite_score_pct,
  DROP COLUMN IF EXISTS composite_calculated_at;

DROP TABLE IF EXISTS ranking_weight_configs;

ALTER TABLE award_categories
  DROP COLUMN IF EXISTS min_composite_pct,
  DROP COLUMN IF EXISTS max_composite_pct,
  DROP COLUMN IF EXISTS is_legacy;

DELETE FROM system_config WHERE key IN ('ranking.finance_closing_deadline_day','ranking.recalculation_enabled');
DELETE FROM _prisma_migrations WHERE migration_name LIKE '20260428%';
COMMIT;
```

### 9.11. Referencias

- Engram #1204 — pattern original psql manual + TXN atómico.
- Engram #1296 — primera aplicación documentada (`notification_deliveries`).
- Engram #1839 — última aplicación reciente (cron_alerts_log + quarterly/annual reports), confirmó pattern sigue válido.
- Reglas durables: NO hardcodear connection strings, NO usar `prisma migrate dev` (shadow roto), aplicar dev → staging → prod en ese orden, pre-check antes de cada apply, verification post-apply en cada branch.

---

## 10. Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Recálculo extendido excede 5min en producción | Kill-switch + cron alert existente. Si excede, batchear por chunks de 50 enrollments. |
| Categorías legacy confunden admin | UI explícita "Legacy" + filter. Doc canon clarifica que viejas no rankean. |
| Weights drift via raw SQL UPDATE | `CHECK weights_sum_100` rechaza el UPDATE. |
| Cambio semántico `rank_position` rompe consumers | No hay consumers prod del ranking ampliado (feature nueva). Comunicar en CHANGELOG + canon update. |
| Cron lock se queda colgado | Lock TTL 10min ya implementado. No se cambia. |
| `composite_score_pct = 0` empata muchos clubes al inicio del año | Esperado. Dense ranking permite empates. UI muestra "sin datos suficientes" si composite=0 AND folder=0. |
| Migration rompe rows existentes | `DEFAULT 0` en ALTER ADD COLUMN garantiza sin null. Backward-compat preservada. |
| Race en `prisma/schema.prisma` con subagents paralelos | Pattern engram: serializar subagents en mismo repo + schema. Implementación: 1 subagent backend a la vez para schema/migrations. |
| `union_id IS NULL` en club causa NaN o error | Edge case explícito: si club sin union, denom = COUNT(camporees nacionales del año). Test cubre. |

---

## 11. Out-of-scope (explícitos)

Para evitar scope creep en C, los siguientes ítems quedan **fuera** y serán abordados en sub-features posteriores:

- Niveles sección/miembro (= sub-feature **A**).
- Visibilidad usuario final / app móvil (= sub-feature **B**).
- Periodicidades menores que anual (= sub-feature **D**).
- Agrupación regional/multi-club (= sub-feature **E**).
- Premiación por componente / multi-categoría por club (= fase posterior).
- Refactor de `award_categories` legacy schema → su deprecation no requiere borrado físico.
- Notificaciones FCM por cambio de ranking (futuro, requiere extensión canon comm).

---

## 12. Canon updates al cierre

Tras implementación + verificación, actualizar:

- `docs/canon/runtime-rankings.md` → §3 Modelo de puntaje (agregar columnas), §5 Pipeline (extendido), §10 Superficie API (extendida + nuevos endpoints), §11 Relación (referenciar este spec).
- `docs/canon/decisiones-clave.md` → nueva decisión §13 (criterios ampliados, weights configurables).
- `docs/api/ENDPOINTS-LIVE-REFERENCE.md` → nuevos endpoints + cambios en existentes.
- `docs/database/SCHEMA-REFERENCE.md` → nuevas columnas + tabla nueva.
- `docs/features/README.md` → nueva entry "Clasificación institucional ampliada".
- `docs/bases/SACDIA_Bases_del_Proyecto-normalizado.md` → §6.2 (Clasificación) pasa de [PARCIAL] a [VIGENTE] con referencia a este spec.

---

## 13. Stack agentes para implementación

Confirmado por usuario, persistido en engram (`sacdia/strategy/agent-stack-8-4`):

- **Exploración**: subagents Haiku + Sonnet (Haiku ya usada para mapping de data sources, ver task `a13609bda22c78cc2`).
- **Planeación**: Opus (próximo paso vía `writing-plans` skill).
- **Implementación + tests**: Sonnet con `model: "sonnet"` explícito por subagent.

**Race-safe pattern** (engram #1842): serializar subagents en mismo repo + schema.prisma. Para fases con backend + admin paralelos, OK porque son repos distintos.
