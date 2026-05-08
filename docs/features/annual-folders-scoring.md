# Calificacion de Carpetas Anuales (Annual Folders Scoring)

**Estado**: IMPLEMENTADO

## Descripcion de dominio

Sistema de calificacion para carpetas anuales de evidencias. Permite al campo local evaluar las secciones de evidencia de cada club, asignar puntos, y generar rankings por tipo de club con categorias de premios configurables para la premiacion de fin de ano.

## Que existe (verificado contra codigo)

### Backend (NestJS)

- **EvaluationModule**: evaluar secciones (`POST /:folderId/sections/:sectionId/evaluate`), confirmar union (`POST .../confirm-union`), reabrir secciones (`POST .../reopen`), listar evaluaciones (`GET /:folderId/evaluations`), nota de revisor por evidencia (`PATCH evidences/:evidenceId/reviewer-note`). Recalculo de totales en transaccion.
- **AwardCategoriesModule**: CRUD completo en `/award-categories`. Catalogo reutilizable sin FK de ano. Soft-delete.
- **RankingsModule**: `GET /annual-folders/rankings` (con filtros club_type, year, category), `GET .../club/:enrollmentId`, `POST .../recalculate`. Cron nocturno a las 2 AM. Dense ranking idempotente en transaccion.
- **Schema**: 3 modelos nuevos (`annual_folder_section_evaluations`, `award_categories`, `club_annual_rankings`) + campos de scoring en `folder_template_sections`, `folder_templates`, `annual_folders`.
- **11 permisos RBAC**: `annual_folder_templates:*`, `annual_folders:evaluate`, `award_categories:*`, `rankings:read/recalculate`
- **72 tests unitarios** (evaluation 27 + award-categories 23 + rankings 22)

### Admin (Next.js)

- Template forms actualizados con `max_points`, `minimum_points` por seccion, `closing_date`
- Pagina de evaluacion: busqueda por folder UUID, evaluar secciones con puntos + notas, reabrir
- Pagina de rankings: leaderboard con filtros, medallas top 3, recalculo manual
- Pagina de categorias de premios: CRUD completo
- `FolderStatusBadge` con 5 estados: open, submitted, under_evaluation, evaluated, closed
- Navegacion en sidebar bajo "Carpeta Anual"

### App (Flutter)

- Entidades y modelos actualizados con campos de scoring (`earned_points`, evaluation status)
- Banners de evaluacion y bajo evaluacion
- Cards de seccion con puntos del evaluador y notas
- Timeline extendido con pasos de evaluacion
- Solo lectura — sin UI de evaluacion

### Base de datos

- `annual_folder_section_evaluations` — UUID PK, FK a `annual_folders` (cascade) y `folder_template_sections`, `earned_points`, `max_points`, `notes`, columnas de auditoria LF (`lf_approved_by`, `lf_approved_at`) y union (`union_approved_by`, `union_approved_at`, `union_decision`), columna `status` (enum `annual_folder_section_status_enum`, default `PENDING`) como fuente unica de verdad del estado de la seccion, unique(`folder_id`, `section_id`)
- `award_categories` — UUID PK, `name`, `description`, `club_type_id` (nullable = todos), `min_points`, `max_points`, `icon`, `order`, `active` (soft-delete)
- `club_annual_rankings` — UUID PK, `club_enrollment_id`, `club_type_id`, `ecclesiastical_year_id`, `award_category_id` (sentinel UUID para general), `total_earned_points`, `total_max_points`, `progress_percentage`, `rank_position`, unique(`enrollment`, `year`, `category`)
- `folder_template_sections` — +`max_points`, +`minimum_points`
- `folder_templates` — +`minimum_points`, +`closing_date`
- `annual_folders` — +`total_earned_points`, +`total_max_points`, +`progress_percentage`, +`evaluated_at`, +`local_camporee_id`, +`union_camporee_id`, +`requires_union_confirmation` (Boolean, default false)

## Requisitos funcionales

1. El campo local puede evaluar cada seccion de evidencia asignando puntos (0 a max_points)
2. El campo local puede reabrir secciones evaluadas para que el club ajuste y se re-evalue
3. Los totales del folder se recalculan automaticamente al evaluar/reabrir secciones
4. Las categorias de premios son configurables y reutilizables entre anos
5. Los rankings se pre-calculan con un cron nocturno (dense ranking)
6. Los rankings se filtran por tipo de club, ano eclesiastico y categoria
7. La app muestra puntos y estado de evaluacion en modo solo lectura
8. El folder transiciona: open → submitted → under_evaluation → evaluated → closed

## Flujo de revision en dos niveles

La evaluacion de una seccion puede atravesar hasta dos niveles de aprobacion, controlados por el flag `requires_union_confirmation` que el folder hereda de su carpeta de camporee al momento de creacion.

- **Camino con union (`requires_union_confirmation = true`)**:
  1. El club sube evidencias y ejecuta `submitSection` por cada seccion lista para revision.
  2. Un actor de campo local (LF) califica con `POST .../sections/:sectionId/evaluate`. La seccion pasa a `PREAPPROVED_LF` y se graba `lf_approved_by` / `lf_approved_at`.
  3. Un actor de union ejecuta `POST .../sections/:sectionId/confirm-union` con decision `APPROVED` o `REJECTED_OVERRIDE`. La seccion transiciona a `VALIDATED` o `REJECTED` respectivamente. Las columnas LF se preservan intactas para auditoria.

- **Atajo sin union (`requires_union_confirmation = false`)**:
  1. El club ejecuta `submitSection`.
  2. El actor LF evalua con `POST .../evaluate`. Como el folder no requiere union, la seccion transiciona directamente de `SUBMITTED` a `VALIDATED`. Para mantener simetria de auditoria, el servicio espeja las columnas de union con el mismo actor LF (`union_approved_by`, `union_approved_at`, `union_decision = APPROVED`).

Solo las filas en estado terminal (`VALIDATED` o `REJECTED`) suman puntos al total del folder y cuentan para avanzar el folder a `evaluated`. Filas en `PENDING`, `SUBMITTED` o `PREAPPROVED_LF` no contribuyen al calculo.

## Maquina de estados de la seccion

La columna `annual_folder_section_evaluations.status` (enum `annual_folder_section_status_enum`) es la unica fuente de verdad del estado de cada seccion. Ningun consumidor debe derivar el estado a partir de timestamps o de la presencia de columnas de aprobacion. Los cinco estados y sus transiciones permitidas son:

- `PENDING` — estado inicial. Las filas se crean eagerly al momento de resolver el template del folder, una por seccion del template.
- `SUBMITTED` — el club ejecuto `submitSection` para esa seccion. Requisito: al menos una evidencia cargada.
- `PREAPPROVED_LF` — el actor LF aprobo la seccion y el folder requiere confirmacion de union. Estado no terminal.
- `VALIDATED` — estado terminal. Se alcanza desde `PREAPPROVED_LF` (decision `APPROVED` de union) o desde `SUBMITTED` en el atajo sin union.
- `REJECTED` — estado terminal. Se alcanza desde `PREAPPROVED_LF` cuando la union ejecuta `REJECTED_OVERRIDE`.

La reapertura por LF o union desde un estado terminal (`VALIDATED`, `REJECTED`) o desde `PREAPPROVED_LF` vuelve la fila a `SUBMITTED`, limpia columnas LF/union y pone `earned_points = 0`. Desde ahi la fila vuelve a ingresar al flujo de evaluacion normal.

```
PENDING ──submitSection──> SUBMITTED
                              │
                              │ evaluate (LF)
                              │
                 ┌────────────┴────────────┐
                 │                         │
    requires_union = true        requires_union = false
                 │                         │
                 ▼                         ▼
          PREAPPROVED_LF               VALIDATED (terminal)
                 │
      ┌──────────┴──────────┐
      │                     │
  confirm-union         confirm-union
   APPROVED          REJECTED_OVERRIDE
      │                     │
      ▼                     ▼
  VALIDATED             REJECTED
  (terminal)            (terminal)

Reopen (LF o union): VALIDATED | REJECTED | PREAPPROVED_LF ──> SUBMITTED
```

## Endpoint de confirmacion de union

`POST /annual-folders/:folderId/sections/:sectionId/confirm-union`

- **DTO**: `{ decision: 'APPROVED' | 'REJECTED_OVERRIDE', notes?: string }`
- **Permiso**: `annual_folders:evaluate` con `type: 'global'`
- **Precondiciones**:
  - `annual_folders.requires_union_confirmation === true`
  - La fila de evaluacion debe estar en `PREAPPROVED_LF`
  - Las columnas `lf_approved_by` y `lf_approved_at` deben estar populadas
- **Efectos**:
  - Escribe `union_approved_by`, `union_approved_at`, `union_decision` con el actor y decision recibidos
  - Transiciona `status` a `VALIDATED` (si `APPROVED`) o `REJECTED` (si `REJECTED_OVERRIDE`)
  - No modifica las columnas LF existentes
  - Recalcula totales del folder y, si todas las secciones del template estan en estado terminal, transiciona el folder a `evaluated`

## Flag `requires_union_confirmation`

- Vive en `annual_folders` como columna persistida al momento de crear el folder.
- Se calcula desde la carpeta de camporee asociada: si `union_camporee_id` es no nulo, el valor es `true`; en caso contrario `false`.
- Es historicamente inmutable para la vida del folder: una vez fijado, el flujo de revision queda comprometido a ese modelo para no invalidar auditoria previa.

## Decisiones de diseno

- **Sentinel UUID** (`00000000-...`) para rankings generales (sin categoria) evitando nullable en unique constraint
- **Evaluacion en transaccion**: upsert de evaluacion + recalculo de totales atomico
- **Rankings idempotentes**: recalcular multiples veces produce el mismo resultado
- **Dense ranking**: empates obtienen el mismo numero (1,1,2,3) no competition (1,1,3,4)
- **Categorias sin FK de ano**: catalogo maestro que persiste entre anos eclesiasticos
- **closing_date bloquea submissions pero NO evaluacion**: el campo puede evaluar despues del cierre
- **Flutter backward-compatible**: campos nullable con fallbacks para backends sin actualizar

## Gaps y pendientes

- E2E smoke test pendiente (crear template → folder → evidencia → submit → evaluar → rankings)
- No hay notificaciones push cuando el campo evalua un folder
- No hay vista de evaluacion en la app (solo admin)
- Auto-close por `closing_date` no implementado (solo manual)
