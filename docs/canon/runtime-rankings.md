# Runtime — Rankings institucionales y categorías de premio

**Estado**: ACTIVE
**Autoridad rectora**: `docs/canon/source-of-truth.md`
**Tipo de documento**: runtime canonizado, documented-as-built
**Ámbito**: clasificación anual de clubes por puntaje de carpetas, categorías de premio configurables y pipeline automático de cálculo

<!-- VERIFICADO contra código 2026-04-22: schema Prisma, rankings.service.ts, controllers de rankings/award-categories y admin UI cruzados con implementación real. -->
<!-- VERIFICADO 8.4-A 2026-04-29: modelos enrollment_rankings, section_rankings, enrollment_ranking_weights — field names, indexes y awarded_category_id confirmados contra schema.prisma y migrations 20260429000000–20260429000003. -->

---

## 1. Propósito

Canoniza el subsistema de **clasificación institucional de clubes** basado en puntaje de carpetas anuales evaluadas y categorías de premio configurables.

Este sistema es distinto del sistema de tiers de achievements (`docs/canon/runtime-achievements.md`). Los rankings operan a nivel club y año eclesiástico, no a nivel miembro.

---

## 2. Alcance canonizado

Dentro del canon:
- modelos `club_annual_rankings`, `award_categories`, `annual_folder_section_evaluations`;
- pipeline automático (cron) y recálculo manual;
- política de dense ranking y desempates;
- relación club_type ↔ award_category;
- interacción con carpetas cerradas y reopen.

Fuera del canon:
- visualización admin (iconografía, Trophy/Medal);
- comunicación pública de resultados (premiaciones, ceremonias).

---

## 3. Modelo de puntaje

Fuente primaria: `annual_folder_section_evaluations` (`schema.prisma:1953-1980`).

- `earned_points` (int, default 0) — puntos obtenidos por sección evaluada;
- `max_points` (int, default 0) — tope posible de la sección;
- `status` (enum `annual_folder_section_status_enum`, default `PENDING`): `PENDING | SUBMITTED | PREAPPROVED_LF | VALIDATED | REJECTED` (`schema.prisma:1688-1694`);
- `union_decision` (enum): `APPROVED | REJECTED_OVERRIDE`.

Fuente agregada: `club_annual_rankings` (`schema.prisma:2026-2051`).

| Campo | Tipo | Nota |
|-------|------|------|
| `ranking_id` | `uuid` | PK, `gen_random_uuid()` |
| `club_enrollment_id` | `uuid` | FK a `club_enrollments` |
| `club_type_id` | `int` | FK a `club_types` |
| `ecclesiastical_year_id` | `int` | FK a `ecclesiastical_years` |
| `award_category_id` | `uuid` | FK a `award_categories`, default sentinel (ver §7) |
| `total_earned_points` | `int` | suma sobre secciones |
| `total_max_points` | `int` | |
| `progress_percentage` | `float` | |
| `rank_position` | `int?` | asignado en dense ranking |
| `calculated_at` | `timestamptz` | |

Uniqueness: `(club_enrollment_id, ecclesiastical_year_id, award_category_id)`.

---

## 4. Categorías de premio (`award_categories`)

Modelo en `schema.prisma:2006-2024`:

- `award_category_id` (uuid, PK);
- `name` (varchar 200);
- `club_type_id` (int, nullable): `null` significa "aplica a todos los tipos";
- `min_points` (int, default 0) — umbral inferior para calificar;
- `max_points` (int, nullable) — `null` significa sin tope superior;
- `active` (boolean, default true) — soft delete;
- `order` (int) para orden visual.

Filtrado canonizado (`rankings.service.ts:207-209`):
- `club_type_id IS NULL` ⇒ categoría aplica a todos los tipos;
- `club_type_id = X` ⇒ categoría aplica solo al tipo X.

Un club califica para una categoría cuando `total_earned_points ∈ [min_points, max_points]` (con `max_points = null` ⇒ unbounded).

---

## 5. Pipeline automático

Servicio: `sacdia-backend/src/annual-folders/rankings.service.ts`.

- Cron `@Cron('0 2 * * *')` (línea 66) ejecuta `handleRankingsRecalculation()` diariamente a las 02:00 UTC;
- recálculo manual vía endpoint `POST /annual-folders/rankings/recalculate?year_id=...` (controller línea 125). Rate limit: 1 vez cada 5 minutos;
- lock distribuido de 10 minutos por año eclesiástico (evita concurrencia entre cron y manual).

Pasos del cálculo (`recalculateRankings`, líneas 123-264):

1. resolver año eclesiástico (default: año activo);
2. adquirir lock distribuido por `year_id`;
3. listar carpetas con `status ∈ {'evaluated', 'closed'}` (línea 126);
4. para cada carpeta, upsert del ranking general (sentinel, ver §7);
5. para cada categoría aplicable al `club_type_id` de la carpeta, upsert del ranking por categoría cuando `earned_points ∈ [min_points, max_points]`;
6. asignar `rank_position` con dense ranking (ver §6).

---

## 6. Política de desempate — dense ranking

Algoritmo en `rankings.service.ts:456-475`:

- agrupar por `(club_type_id, ecclesiastical_year_id, award_category_id)`;
- ordenar descendente por `total_earned_points`;
- asignar rank con semántica densa: empates comparten rank; el siguiente grupo obtiene `prevRank + 1`.

Ejemplo: `[90, 90, 70, 70, 50] → [1, 1, 2, 2, 3]`.

No existe campo de tiebreaker adicional. Empates perfectos en puntos mantienen rank compartido por diseño.

---

## 7. Sentinel UUID para ranking general

Constante: `GENERAL_CATEGORY_ID = '00000000-0000-0000-0000-000000000000'` (`rankings.service.ts:21`).

Justificación: PostgreSQL trata `NULL <> NULL` para constraints únicos. Usar `null` en `award_category_id` rompería la unicidad `(club_enrollment_id, ecclesiastical_year_id, award_category_id)`. El sentinel permite representar "ranking general sin categoría específica" preservando la constraint y habilitando `upsert` de Prisma.

Política: el sentinel no puede aparecer en `award_categories` como categoría real; es un token de ausencia.

---

## 8. Interacción con carpetas cerradas

- `closeFolder()` (`annual-folders.service.ts:1382`) transiciona `status → 'closed'` desde `'submitted'` o `'evaluated'`;
- carpetas `closed` **sí participan** en ranking (la query incluye ambos estados, `rankings.service.ts:126`);
- carpetas `closed` **no admiten reopen** de secciones (`evaluation.service.ts:462-468`).

Implicación canónica: el cierre fija el resultado institucional del club para ese periodo operativo; el ranking puede recalcularse en posteriores ejecuciones del cron sin afectar la fuente de verdad.

---

## 9. Alcance institucional

- rankings cubren cualquier `club_type_id` con folder template activo para el año eclesiástico y folders evaluadas o cerradas;
- categorías con `club_type_id = null` aplican universalmente;
- categorías con `club_type_id = X` aplican solo a ese tipo.

No hay lista de clubes excluidos. El criterio de inclusión es operativo (tener folder evaluada/cerrada), no administrativo.

---

## 10. Superficie API canonizada

Rankings (permiso `rankings:read` | `rankings:recalculate`):

- `GET /annual-folders/rankings?club_type_id&year_id[&category_id]`;
- `GET /annual-folders/rankings/club/:enrollmentId?year_id`;
- `POST /annual-folders/rankings/recalculate?year_id`.

Award categories (permisos `award_categories:*`):

- `POST /award-categories`;
- `GET /award-categories?club_type_id&active`;
- `GET /award-categories/:categoryId`;
- `PATCH /award-categories/:categoryId`;
- `DELETE /award-categories/:categoryId` (soft delete).

Evaluations:

- `POST /annual-folders/:folderId/sections/:sectionId/evaluate`;
- `POST /annual-folders/:folderId/sections/:sectionId/reopen`;
- `POST /annual-folders/:folderId/sections/:sectionId/confirm-union`;
- `GET /annual-folders/:folderId/evaluations`.

Contrato exacto en `docs/features/annual-folders-scoring.md` y `docs/api/ENDPOINTS-LIVE-REFERENCE.md`.

---

## 11. Relación con otros canones

- `docs/canon/runtime-sacdia.md` — carpeta anual como fuente de verdad operativa de evaluaciones.
- `docs/canon/runtime-achievements.md` — sistema de tiers de miembro (no confundir).
- `docs/canon/dominio-sacdia.md` — club raíz, sección operativa.
- `docs/canon/decisiones-clave.md` — decisión 12 (canonización de rankings y award categories).

---

## 12. Invariantes

- ningún ranking puede existir sin carpeta evaluada o cerrada que lo respalde;
- el sentinel UUID nunca puede usarse como `award_category_id` real en `award_categories`;
- dense ranking es la única semántica de ranking permitida;
- recálculo manual y cron no pueden ejecutarse concurrentemente para el mismo año (lock distribuido).

---

## 13. Clasificación de miembros y secciones (8.4-A)

**Estado**: shipped 2026-04-29
**Spec**: `docs/superpowers/specs/2026-04-29-clasificacion-seccion-miembro-design.md`
**Audit**: `docs/superpowers/audits/2026-04-29-section-member-schema-audit.md` (commit `643b694`)
**Canon de decisión**: `docs/canon/decisiones-clave.md` §22

Este subsistema extiende el pipeline existente de clasificación institucional de clubes hacia un nivel más granular: enrollment (miembro activo) y sección de club. Funciona de forma independiente con dark-launch propio (kill-switches separados) y no altera el pipeline club-level §5.

---

### 13.1 Modelos de persistencia

Tres tablas nuevas creadas por la migración `20260429000000_enrollment_rankings_schema`:

**`enrollment_rankings`** — registro por (enrollment_id, ecclesiastical_year_id):

| Campo | Tipo | Nota |
|-------|------|------|
| `id` | `uuid` PK | `gen_random_uuid()` |
| `enrollment_id` | `integer` NOT NULL | FK → `enrollments(enrollment_id)` ON DELETE CASCADE |
| `user_id` | `uuid` NOT NULL | FK → `users(user_id)` |
| `club_id` | `integer` NOT NULL | FK → `clubs(club_id)` |
| `club_section_id` | `integer` | FK → `club_sections(club_section_id)`, nullable |
| `ecclesiastical_year_id` | `integer` NOT NULL | FK → `ecclesiastical_years(year_id)` |
| `class_score_pct` | `NUMERIC(5,2)` | señal clases, NULL si sin progreso |
| `investiture_score_pct` | `NUMERIC(5,2)` | señal investidura binaria, NULL si sin enrollment |
| `camporee_score_pct` | `NUMERIC(5,2)` | señal camporees, NULL si sin camporees del año |
| `composite_score_pct` | `NUMERIC(5,2)` | puntaje compuesto final ∈ [0, 100] |
| `rank_position` | `integer?` | asignado vía DENSE_RANK, NULLS LAST |
| `awarded_category_id` | `uuid?` | FK → `award_categories`, nullable |
| `composite_calculated_at` | `timestamptz` | timestamp del último cálculo |

Uniqueness: `UNIQUE(enrollment_id, ecclesiastical_year_id)`.
Índices: `(club_id, ecclesiastical_year_id)`, `(club_section_id, ecclesiastical_year_id)`, `(club_id, ecclesiastical_year_id, composite_score_pct DESC)`, `(user_id)`, `(awarded_category_id)`.
CHECK constraints: cada señal ∈ [0, 100] o NULL; composite ∈ [0, 100] o NULL.

**`section_rankings`** — agregado puro por (club_section_id, ecclesiastical_year_id):

| Campo | Tipo | Nota |
|-------|------|------|
| `id` | `uuid` PK | |
| `club_section_id` | `integer` NOT NULL | FK → `club_sections` |
| `ecclesiastical_year_id` | `integer` NOT NULL | FK → `ecclesiastical_years` |
| `club_id` | `integer` NOT NULL | FK → `clubs` |
| `composite_score_pct` | `NUMERIC(5,2)` | AVG de enrollment_rankings.composite WHERE NOT NULL |
| `active_enrollment_count` | `integer` | enrollments activos en la sección (default 0) |
| `rank_position` | `integer?` | DENSE_RANK NULLS LAST |
| `awarded_category_id` | `uuid?` | FK → `award_categories`, nullable |
| `calculated_at` | `timestamptz` | |

Uniqueness: `UNIQUE(club_section_id, ecclesiastical_year_id)`.
Índices: `(club_id, ecclesiastical_year_id)`, `(composite_score_pct)`.

**`enrollment_ranking_weights`** — pesos por (club_type_id, ecclesiastical_year_id):

| Campo | Tipo | Nota |
|-------|------|------|
| `id` | `uuid` PK | |
| `club_type_id` | `integer?` | FK → `club_types`, NULL = fila global por defecto |
| `ecclesiastical_year_id` | `integer?` | FK → `ecclesiastical_years`, NULL = fila global |
| `class_pct` | `DECIMAL(5,2)` | peso señal clases |
| `investiture_pct` | `DECIMAL(5,2)` | peso señal investidura |
| `camporee_pct` | `DECIMAL(5,2)` | peso señal camporees |
| `is_default` | `boolean` | true solo en la fila global única |

Uniqueness: `UNIQUE(club_type_id, ecclesiastical_year_id)`.
Constraint sum=100: aplicada en servicio con tolerancia IEEE `Math.abs(sum − 100) ≤ 0.01`. No existe constraint DB equivalente (Decimal precision no garantiza comparación exacta).
Seeded en migración `20260429000002_enrollment_rankings_seeds`: fila global `is_default=true` con pesos 50/30/20.

---

### 13.2 Pipeline de cálculo

Orquestador: `MemberRankingsRecalculateService.recalculateAll(yearId?)` en `sacdia-backend/src/rankings/member-rankings/services/`.

**Calculadores por enrollment** (3 señales, Fase 1):

- `ClassScoreService` — lee `class_module_progress` filtrando por `enrollment.ecclesiastical_year_id`. Score = (módulos activos con score IS NOT NULL / total módulos activos) × 100. NULL si sin progreso.
- `InvestitureScoreService` — lee `enrollments.investiture_status`. `INVESTIDO` → 100; `IN_PROGRESS` → 0; sin enrollment → NULL.
- `CamporeeScoreService` — lee `camporee_members` filtrado por `user_id` y camporees del año vía `local_camporees.ecclesiastical_year`/`union_camporees.ecclesiastical_year`. Score = (camporees aprobados / total camporees del año) × 100. NULL si sin camporees del año.

**Composite y sección**:

- `MemberCompositeScoreService` — combina las 3 señales con pesos resueltos por `WeightsResolverService` (busca override de `(club_type_id, year_id)`, fallback a fila `is_default=true`). NULL redistribution proporcional: si una señal es NULL su peso se distribuye entre las señales presentes. Si todas NULL → composite NULL.
- `EnrollmentClubResolverService` — resuelve `club_id` y `club_section_id` desde el enrollment (necesario porque `enrollments` → `club_sections` → `clubs`).
- `SectionAggregationService` — calcula `section_rankings` como AVG de `enrollment_rankings.composite_score_pct WHERE NOT NULL` agrupado por `(club_section_id, ecclesiastical_year_id)`.

Rutas de archivo:
- `sacdia-backend/src/rankings/member-rankings/services/`
- `sacdia-backend/src/rankings/section-rankings/services/`
- `sacdia-backend/src/annual-folders/rankings.service.ts` — orquestador cron (integra club + enrollment + section secuencialmente)

---

### 13.3 Pesos (weights)

Resolución:
1. Buscar fila en `enrollment_ranking_weights` WHERE `club_type_id = X AND ecclesiastical_year_id = Y`.
2. Si no existe, usar fila `is_default = true` (única fila global).
3. Los tres pesos deben sumar 100 ± 0.01 (validado en `MemberRankingWeightsService` en CREATE y PATCH).

Errores canónicos:
- `WEIGHTS_SUM_INVALID` — suma fuera del rango de tolerancia.
- `WEIGHTS_CONFLICT` — ya existe un override para ese (club_type_id, ecclesiastical_year_id).
- `DEFAULT_WEIGHTS_NOT_DELETABLE` — intento de eliminar la fila `is_default=true`.

---

### 13.4 Cron y recálculo

- Cron: mismo job `0 2 * * *` UTC extendido. Secuencia: club → enrollment → section.
- Orquestador de recálculo: `recalculateAll(yearId?)` — sin `yearId` usa año eclesiástico activo.
- BullMQ jobId dedup: cada ejecución usa `jobId` único por año para evitar duplicados en cola.
- Kill-switches duales en `system_config`:
  - `ranking.recalculation_enabled` (boolean) — controla el pipeline club-level existente.
  - `member_ranking.recalculation_enabled` (boolean) — controla exclusivamente el pipeline 8.4-A (enrollment + section). Validado en `POST /api/v1/member-rankings/recalculate` antes de ejecutar; responde `400 RECALCULATION_DISABLED` si está deshabilitado.
- Rate limit manual: 5 minutos entre disparos de `POST /api/v1/member-rankings/recalculate`.

---

### 13.5 Asignación de posición de ranking

**Enrollment rankings** (`enrollment_rankings.rank_position`):
- `DENSE_RANK() OVER (PARTITION BY (club_id, ecclesiastical_year_id) ORDER BY composite_score_pct DESC NULLS LAST)`.
- Empates comparten rank; el grupo siguiente obtiene `prevRank + 1`.
- Enrollments sin composite (NULL) reciben `rank_position = NULL`.

**Section rankings** (`section_rankings.rank_position`):
- `DENSE_RANK() OVER (PARTITION BY (club_id, ecclesiastical_year_id) ORDER BY composite_score_pct DESC NULLS LAST)`.
- Secciones sin miembros con composite reciben composite NULL y `rank_position = NULL`.

Invariante: `rank_position ∈ ℕ⁺` cuando NOT NULL; NULL es semánticamente "sin posición asignada" (no es cero ni último).

---

### 13.6 Redistribución NULL en composite

Cuando una o más señales son NULL (ej. primer mes sin clases abiertas → `class_score_pct = NULL`), `MemberCompositeScoreService` redistribuye el peso de las señales ausentes de forma proporcional entre las señales presentes:

```
peso_redistribuido_i = peso_i + (peso_nulls × peso_i / sum(pesos_presentes))
```

Si **todas** las señales son NULL → `composite_score_pct = NULL`.

Esto evita penalizar a miembros cuya falta de señal se debe a datos no disponibles (sin camporees del año, sin clases abiertas) en lugar de inactividad real.

Para el algoritmo exacto, ver `MemberCompositeScoreService` en `sacdia-backend/src/rankings/member-rankings/services/`.

---

### 13.7 Visibilidad / RBAC

**Perfiles de autorización**: `ResolvedAuthorizationProfile` (patrón existente del sistema RBAC).

**5-tier waterfall para member-rankings** (`GET /api/v1/member-rankings` y `GET /:enrollmentId/breakdown`):

1. `member_rankings:read_global` — admin/super_admin: ve todos los enrollments sin filtro de club.
2. `member_rankings:read_lf` — coordinador de campo local: ve enrollments de clubes en su campo.
3. `member_rankings:read_club` — director de club: ve enrollments de su club.
4. `member_rankings:read_section` — director de sección: ve enrollments de su sección.
5. `member_rankings:read_self` — miembro: solo su propio ranking (endpoint `/me`).

Sin ninguno de estos permisos → acceso denegado (403).

**3-tier para section-rankings** (`GET /api/v1/section-rankings`):

1. `section_rankings:read_global` — admin/super_admin.
2. `section_rankings:read_lf` — coordinador campo local.
3. `section_rankings:read_club` — director de club.

**Kill-switch de visibilidad**: `member_ranking.recalculation_enabled=false` no bloquea lecturas. La visibilidad de `/me` se valida en el servicio contra el perfil RBAC del llamante.

---

### 13.8 MEMENTO — Naming híbrido (Audit A11, lock permanente)

Este sistema usa una convención de naming híbrido que NO debe revertirse post-implementación (decisión §23).

| Capa | Nombre usado | Ejemplo |
|------|-------------|---------|
| Schema DB (tablas físicas) | `enrollment_*` | `enrollment_rankings`, `enrollment_ranking_weights` |
| Prisma model | `EnrollmentRanking`, `EnrollmentRankingWeight` | — |
| FK en DB | `enrollment_id` (INTEGER) | campo en `enrollment_rankings` |
| API REST (rutas externas) | `member-*` | `/api/v1/member-rankings`, `/api/v1/member-ranking-weights` |
| Permisos RBAC | `member_rankings:*`, `member_ranking_weights:*` | `member_rankings:read_club` |
| DTOs (capa API) | `MemberRanking*` | `MemberRankingResponseDto`, `MemberBreakdownDto` |
| system_config keys | `member_ranking.*` | `member_ranking.recalculation_enabled` |
| UI / strings user-facing | `member` / `miembro` | — |

**Razón del híbrido**: La entidad real en DB es `enrollment` (una inscripción puede tener múltiples miembros históricos en teoría). El término user-facing es "miembro" (más claro para directores y padres). El audit A11 verificó que la dualidad es intencional y que ambos naming están correctamente aislados en sus respectivas capas.

**Audit lock**: las tablas `enrollment_rankings` y `enrollment_ranking_weights` **NO se renombran** post-implementación. Las rutas `/api/v1/member-rankings` y `/api/v1/member-ranking-weights` **NO se cambian**. Cualquier propuesta de unificación requiere una nueva decisión de arquitectura con migración explícita.

---

### 13.9 Invariantes 8.4-A

- `composite_score_pct ∈ [0, 100]` cuando NOT NULL (CHECK constraint en DB + validación de servicio).
- `rank_position ∈ ℕ⁺` cuando NOT NULL; NULL es semánticamente "sin posición asignada".
- `sum(class_pct, investiture_pct, camporee_pct) = 100 ± 0.01` (validado en servicio en CREATE/PATCH de weights).
- El filtrado RBAC de scope (club_id / section_id / field_id) se aplica **antes** de devolver datos; ningún endpoint expone datos fuera del scope autorizado.
- La fila `is_default=true` en `enrollment_ranking_weights` no puede eliminarse (`DEFAULT_WEIGHTS_NOT_DELETABLE`).
- El pipeline enrollment + section corre **después** del pipeline club en el mismo cron (secuencia garantizada por diseño del orquestador).
