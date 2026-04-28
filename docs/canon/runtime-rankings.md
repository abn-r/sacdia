# Runtime — Rankings institucionales y categorías de premio

**Estado**: ACTIVE
**Autoridad rectora**: `docs/canon/source-of-truth.md`
**Tipo de documento**: runtime canonizado, documented-as-built
**Ámbito**: clasificación anual de clubes por puntaje de carpetas, categorías de premio configurables y pipeline automático de cálculo

<!-- VERIFICADO contra código 2026-04-28: schema Prisma con columnas de componentes + composite, rankings.service.ts extendido con score-calculators, controllers de rankings/award-categories/ranking-weights y admin UI. 8.4-C shipped. -->

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
| `rank_position` | `int?` | asignado en dense ranking sobre `composite_score_pct DESC` (ver §6) |
| `calculated_at` | `timestamptz` | |
| `folder_score_pct` | `float` | DEFAULT 0; porcentaje de puntaje de carpeta (0-100) |
| `finance_score_pct` | `float` | DEFAULT 0; porcentaje de cierre financiero mensual (0-100) |
| `camporee_score_pct` | `float` | DEFAULT 0; porcentaje de asistencia a camporees (0-100) |
| `evidence_score_pct` | `float` | DEFAULT 0; porcentaje de evidencias validadas (0-100) |
| `composite_score_pct` | `float` | DEFAULT 0; promedio ponderado de los 4 componentes (0-100) |
| `composite_calculated_at` | `timestamptz?` | timestamp de la última actualización del composite |

Índice de soporte: `idx_rankings_composite` sobre `(ecclesiastical_year_id, club_type_id, composite_score_pct DESC)`.

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
- Kill-switch: `system_config[ranking.recalculation_enabled]` (default `true`) cortocircuita tanto el cron como el punto de entrada manual; cuando está en `false`, el pipeline retorna sin ejecutar ningún cálculo.
- El cron ahora calcula los puntajes de componente (folder / finance / camporee / evidence) y el composite mediante los servicios `score-calculators/*` antes del upsert.
- El recálculo por enrollment ejecuta los cuatro calculadores + `WeightsResolver` en `Promise.all` fuera de la transacción, para minimizar el tiempo de lock.
- Cada recálculo por enrollment emite una línea `logger.debug` estructurada con `{enrollment_id, year_id, scores, composite, weights_source}` para trazabilidad operativa.

Pasos del cálculo (`recalculateRankings`, líneas 123-264):

1. verificar `system_config[ranking.recalculation_enabled]`; si es `false`, salir sin error;
2. resolver año eclesiástico (default: año activo);
3. adquirir lock distribuido por `year_id`;
4. listar carpetas con `status ∈ {'evaluated', 'closed'}` (línea 126);
5. para cada carpeta, calcular los 4 component scores + composite (via calculadores + WeightsResolver) en paralelo;
6. upsert del ranking general (sentinel, ver §7) con todos los campos de score;
7. para cada categoría aplicable al `club_type_id` de la carpeta, upsert del ranking por categoría cuando `earned_points ∈ [min_points, max_points]` y `composite_score_pct ∈ [min_composite_pct, max_composite_pct]` según aplique;
8. asignar `rank_position` con dense ranking sobre `composite_score_pct DESC` (ver §6).

---

## 6. Política de desempate — dense ranking

Algoritmo en `rankings.service.ts:456-475`:

- agrupar por `(club_type_id, ecclesiastical_year_id, award_category_id)`;
- ordenar descendente por `composite_score_pct` (desde 8.4-C; antes se ordenaba por `total_earned_points`);
- asignar rank con semántica densa: empates comparten rank; el siguiente grupo obtiene `prevRank + 1`.

Ejemplo: `[90.0, 90.0, 70.5, 70.5, 50.0] → [1, 1, 2, 2, 3]`.

No existe campo de tiebreaker adicional. Empates perfectos en `composite_score_pct` mantienen rank compartido por diseño.

---

## 7. Sentinel UUID para ranking general

Constante: `GENERAL_CATEGORY_ID = '00000000-0000-0000-0000-000000000000'` (`rankings.service.ts:21`).

Justificación: PostgreSQL trata `NULL <> NULL` para constraints únicos. Usar `null` en `award_category_id` rompería la unicidad `(club_enrollment_id, ecclesiastical_year_id, award_category_id)`. El sentinel permite representar "ranking general sin categoría específica" preservando la constraint y habilitando `upsert` de Prisma.

Política: el sentinel no puede aparecer en `award_categories` como categoría real; es un token de ausencia.

Desde 8.4-C, las filas sentinel también llevan los cuatro component scores (`folder_score_pct`, `finance_score_pct`, `camporee_score_pct`, `evidence_score_pct`) y el `composite_score_pct`, habilitando el mismo drill-down que las filas por categoría.

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

- `GET /annual-folders/rankings?club_type_id&year_id[&category_id]` — cada fila ahora incluye los 6 campos nuevos: `folder_score_pct`, `finance_score_pct`, `camporee_score_pct`, `evidence_score_pct`, `composite_score_pct`, `composite_calculated_at`;
- `GET /annual-folders/rankings/club/:enrollmentId?year_id` — ídem;
- `GET /annual-folders/rankings/:enrollmentId/breakdown?year_id` — drill-down por enrollment: devuelve composite + pesos aplicados + detalle de cada componente. Permiso `rankings:read`;
- `POST /annual-folders/rankings/recalculate?year_id`.

Award categories (permisos `award_categories:*`):

- `POST /award-categories`;
- `GET /award-categories?club_type_id&active` — filtra `is_legacy = false` por defecto; `?include_legacy=true` para histórico;
- `GET /award-categories/:categoryId`;
- `PATCH /award-categories/:categoryId`;
- `DELETE /award-categories/:categoryId` (soft delete).

### Ranking weights (permisos `ranking_weights:read` | `ranking_weights:write`)

- `GET /ranking-weights` — lista configuraciones (default global + overrides por club_type);
- `GET /ranking-weights/:id` — detalle de una configuración;
- `POST /ranking-weights` — crear override por `club_type_id`; body requiere los 4 pesos; valida que sumen 100 (HTTP 400) y que no haya duplicado de `club_type_id` (HTTP 409);
- `PATCH /ranking-weights/:id` — actualización parcial; re-valida suma = 100;
- `DELETE /ranking-weights/:id` — eliminar override; la fila con `club_type_id = NULL` (global default) no puede eliminarse (HTTP 400).

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
- recálculo manual y cron no pueden ejecutarse concurrentemente para el mismo año (lock distribuido);
- los 4 pesos de una configuración `ranking_weight_configs` deben sumar exactamente 100 (enforced por DB CHECK + API);
- `ranking.recalculation_enabled = false` inhibe todo recálculo; no debe bypass en ninguna ruta.

---

## 13. Criterios institucionales ampliados (8.4-C)

**Vigente desde**: 2026-04-28

El composite ranking combina cuatro criterios institucionales en un único índice por club por año eclesiástico:

| Criterio | Campo | Descripción |
|----------|-------|-------------|
| **Carpeta** | `folder_score_pct` | Porcentaje de puntos obtenidos sobre el total de la carpeta anual evaluada |
| **Finanzas** | `finance_score_pct` | Proporción de meses con cierre financiero entregado antes del `ranking.finance_closing_deadline_day` (default: día 5) |
| **Camporee** | `camporee_score_pct` | Proporción de camporees disponibles en el año (local + unión) a los que el club asistió con estado aprobado |
| **Evidencias** | `evidence_score_pct` | Proporción de evidencias de carpeta en estado `VALIDATED` sobre el total de evaluadas (pending excluidos) |

### Pesos

Los pesos globales por defecto son `60 / 15 / 15 / 10` (folder / finance / camporee / evidence). Pueden sobreescribirse por `club_type_id` en `ranking_weight_configs`. La suma siempre debe ser exactamente 100 (CHECK constraint + API validation).

### Semántica temporal

Los rankings históricos (antes de 2026-04-28) retienen `0` en los 5 campos nuevos vía `DEFAULT 0`; no se ejecuta recomputación retroactiva. El composite solo es significativo desde el año eclesiástico en que se ejecute el primer recálculo post-8.4-C.

### Categorías legacy

Las filas de `award_categories` creadas antes de 2026-04-28 están marcadas con `is_legacy = true` y no participan en el composite ranking. Solo las categorías con `is_legacy = false` y `min_composite_pct`/`max_composite_pct` configurados evalúan el composite. El GET de `award_categories` excluye legacy por defecto (`?include_legacy=true` para histórico).

### Referencias

- Spec: `docs/superpowers/specs/2026-04-28-clasificacion-criterios-ampliados-design.md`
- Plan: `docs/superpowers/plans/2026-04-28-clasificacion-criterios-ampliados.md`
