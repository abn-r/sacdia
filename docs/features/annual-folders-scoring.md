# Calificacion de Carpetas Anuales (Annual Folders Scoring)

**Estado**: IMPLEMENTADO

## Descripcion de dominio

Sistema de calificacion para carpetas anuales de evidencias. Permite al campo local evaluar las secciones de evidencia de cada club, asignar puntos, y generar rankings por tipo de club con categorias de premios configurables para la premiacion de fin de ano.

## Que existe (verificado contra codigo)

### Backend (NestJS)

- **EvaluationModule**: evaluar secciones (`POST /:folderId/sections/:sectionId/evaluate`), reabrir secciones (`POST .../reopen`), listar evaluaciones (`GET /:folderId/evaluations`). Recalculo de totales en transaccion.
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

- `annual_folder_section_evaluations` — UUID PK, FK a `annual_folders` (cascade) y `folder_template_sections`, `earned_points`, `max_points`, `notes`, `evaluated_by_id`, unique(`folder_id`, `section_id`)
- `award_categories` — UUID PK, `name`, `description`, `club_type_id` (nullable = todos), `min_points`, `max_points`, `icon`, `order`, `active` (soft-delete)
- `club_annual_rankings` — UUID PK, `club_enrollment_id`, `club_type_id`, `ecclesiastical_year_id`, `award_category_id` (sentinel UUID para general), `total_earned_points`, `total_max_points`, `progress_percentage`, `rank_position`, unique(`enrollment`, `year`, `category`)
- `folder_template_sections` — +`max_points`, +`minimum_points`
- `folder_templates` — +`minimum_points`, +`closing_date`
- `annual_folders` — +`total_earned_points`, +`total_max_points`, +`progress_percentage`, +`evaluated_at`

## Requisitos funcionales

1. El campo local puede evaluar cada seccion de evidencia asignando puntos (0 a max_points)
2. El campo local puede reabrir secciones evaluadas para que el club ajuste y se re-evalue
3. Los totales del folder se recalculan automaticamente al evaluar/reabrir secciones
4. Las categorias de premios son configurables y reutilizables entre anos
5. Los rankings se pre-calculan con un cron nocturno (dense ranking)
6. Los rankings se filtran por tipo de club, ano eclesiastico y categoria
7. La app muestra puntos y estado de evaluacion en modo solo lectura
8. El folder transiciona: open → submitted → under_evaluation → evaluated → closed

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
