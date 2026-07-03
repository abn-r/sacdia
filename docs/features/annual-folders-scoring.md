# Calificacion de Carpeta Anual de Evidencias (Annual Folders Scoring)

**Estado**: IMPLEMENTADO

## Descripcion de dominio

Sistema de calificacion para la Carpeta Anual de Evidencias. Permite al campo local evaluar las secciones de evidencia de cada club, asignar puntos, y generar rankings por tipo de club con categorias de premios configurables para la premiacion de fin de ano.

La Carpeta Anual de Evidencias conserva su propio flujo de carga de archivos e imagenes. No forma parte de la cola generica `EvidenceReview` (reservada para clases y honores); se carga, envia, evalúa y confirma dentro del módulo `annual-folders`.

## Que existe (verificado contra codigo)

### Backend (NestJS)

- **EvaluationModule**: evaluar secciones (`POST /:folderId/sections/:sectionId/evaluate`), confirmar union (`POST .../confirm-union`), reabrir secciones (`POST .../reopen`), listar evaluaciones (`GET /:folderId/evaluations`), nota de revisor por evidencia (`PATCH evidences/:evidenceId/reviewer-note`). Recalculo de totales en transaccion.
- **AwardCategoriesModule**: CRUD completo en `/award-categories`. Catalogo reutilizable sin FK de ano. Soft-delete.
- **RankingsModule**: `GET /annual-folders/rankings` (con filtros club_type, year, category), `GET .../club/:enrollmentId`, `POST .../recalculate`. Cron nocturno a las 2 AM. Dense ranking idempotente en transaccion.
- **Schema**: 3 modelos nuevos (`annual_folder_section_evaluations`, `award_categories`, `club_annual_rankings`) + campos de scoring en `folder_template_sections`, `folder_templates`, `annual_folders` + lifecycle explícito de plantillas (`folder_template_status_enum`).
- **11 permisos RBAC**: `annual_folder_templates:*`, `annual_folders:evaluate`, `award_categories:*`, `rankings:read/recalculate`
- **72 tests unitarios** (evaluation 27 + award-categories 23 + rankings 22)

### Admin (Next.js)

- La entrada principal del módulo es el listado operativo de carpetas creadas. Permite filtrar por jerarquía (Unión/Campo Local), estado de carpeta, estado de revisión, tipo de club, año y avance; desde ahí se revisan/evalúan secciones y se navega internamente al detalle.
- Template forms alineados con ranking anual: la plantilla muestra el presupuesto efectivo de `annual_evidence_folder.max_points`, no expone puntos manuales de plantilla, y cada seccion configura solo los puntos asignados que deben sumar exactamente el total requerido antes de publicar.
- Plantillas con lifecycle: `DRAFT` se puede editar/eliminar; publicar cambia a `PUBLISHED`, la bloquea y la habilita para generar carpetas; `PUBLISHED`/`ARCHIVED` se reutilizan con "copiar como borrador" para el siguiente año.
- Pagina de club: carga la carpeta de la sección activa con `GET /club-sections/:sectionId/annual-folder`; si ya existe inscripción anual aprobada (`club_enrollments.status = active`) y template activo pero falta la carpeta, permite crearla con `POST /club-sections/:sectionId/annual-folder`; permite subir evidencias, enviar secciones con `POST /annual-folders/:folderId/sections/:sectionId/submit` y luego enviar la carpeta completa; no pide UUIDs internos al usuario.
- Pagina de evaluacion: cola legible por club, sección, campo, unión, template y estado; muestra evidencias dentro del panel y del modal de evaluación, con visor interno para imágenes/PDF y zoom; para secciones `PREAPPROVED_LF` muestra confirmación/rechazo de Unión a roles `director-union`/`assistant-union`; desde esa cola se abren carpetas por deep link técnico (`?folder=`) solo como navegación interna.
- Pagina de rankings: leaderboard con filtros, medallas top 3, recalculo manual
- La configuración de reconocimientos/premios operativos vive en `ranking_tiers` dentro de Configuración de ranking. La ruta legacy `/dashboard/annual-folders/categories` redirige a esa configuración para no mantener dos flujos de premios.
- `FolderStatusBadge` con 5 estados: open, submitted, under_evaluation, evaluated, closed
- Navegacion en sidebar bajo "Carpeta Anual de Evidencias"

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
- `folder_templates` — +`minimum_points`, +`closing_date`, +`status folder_template_status_enum` (`DRAFT`, `PUBLISHED`, `ARCHIVED`)
- `annual_folders` — +`total_earned_points`, +`total_max_points`, +`progress_percentage`, +`evaluated_at`, +`local_camporee_id`, +`union_camporee_id`, +`requires_union_confirmation` (Boolean, default false)


## Roles y permisos vigentes

- `evidence_folders:read/update` habilita la lectura/carga operativa de evidencias de la carpeta anual. Lo tienen dirección/secretaría del club: `secretary`, `secretary-treasurer`, `deputy-director`, `director`.
- `member`, `counselor`, `instructor` y `treasurer` no tienen `evidence_folders:read/update`; no cargan ni leen esta carpeta desde el flujo anual.
- `annual_folders:submit` envía la carpeta completa a revisión. Lo ejecuta `director`, `secretary` o `secretary-treasurer`; los usuarios operativos envían secciones, no la carpeta completa.
- `assistant-lf` y `director-lf` participan como lectura/supervisión institucional y evaluación mediante `annual_folders:evaluate`; no envían la carpeta completa en nombre del club.

## Requisitos funcionales

1. El campo local puede evaluar cada seccion de evidencia asignando puntos (0 a max_points)
2. El campo local puede reabrir secciones evaluadas para que el club ajuste y se re-evalue
3. Los totales del folder se recalculan automaticamente al evaluar/reabrir secciones
4. Una inscripción anual de sección queda primero en `pending_validation` y Campo Local la aprueba desde el panel administrativo. Al aprobar (`pending_validation -> active`) se intenta crear automaticamente su Carpeta Anual de Evidencias cuando existe template vigente; si no existe template, la inscripción queda activa y la carpeta puede crearse manualmente por flujo interno con `POST /annual-folders/enrollments/:enrollmentId` o desde la UX de club con `POST /club-sections/:sectionId/annual-folder` sin exponer UUIDs al usuario.
5. El envío de sección y de carpeta completa respeta `folder_templates.closing_date`; la evaluación institucional sigue permitida después del cierre.
6. La carpeta completa solo puede enviarla dirección/secretaría del club cuando todas las secciones requeridas tienen submission y evidencia vigente.
4. Las categorias de premios son configurables y reutilizables entre anos
5. Los rankings se pre-calculan con un cron nocturno (dense ranking)
6. Los rankings se filtran por tipo de club, ano eclesiastico, categoria y campo local (`local_field_id`) cuando se necesita comparar clubes dentro de una asociación/campo. El backend valida el alcance jerárquico del usuario y puede inferir el campo local desde la asignación activa de club o el perfil efectivo cuando el filtro no viene explícito.
7. La app muestra un scorecard de progreso anual de su propia sección (`/club-sections/:sectionId/annual-ranking-progress`): puntos actuales, máximo anual, reconocimiento, ejes (`axes`), componentes y pendientes; no muestra el leaderboard de otros clubes.
8. El panel administrativo puede consultar el leaderboard por campo local/año/tipo de club vía `/annual-rankings`, con puntos derivados por eje desde `annual_ranking_configs` y rangos de `ranking_tiers`.
9. El panel administrativo no expone buscadores manuales por UUID para carpetas anuales. Los roles de club entran por su contexto activo de sección; los roles institucionales entran por la cola/listado de carpetas.
10. El panel administrativo configura los rangos globales vía `/ranking-tiers` y los presupuestos anuales por Unión o Campo Local/año/tipo de club vía `/annual-ranking-configs`. Los rangos son globales del sistema; los puntos máximos se dividen en ejes configurables `administrative` y `operational` (50/50 recomendado inicialmente), y cada eje contiene componentes canónicos soportados por backend: `annual_evidence_folder`, `monthly_reports_timeliness`, `finance_compliance`, `institutional_data_completeness`, `activities_registered`, `attendance_participation`, `camporee_events`, `class_investiture_progress` y `sacdia_operational_usage`.
11. La configuración de ranking anual es histórica por alcance lógico: existe una fila activa por `union_id + ecclesiastical_year_id + club_type_id` o por `local_field_id + ecclesiastical_year_id + club_type_id`. Para un Campo Local, la configuración efectiva se resuelve como Unión primero y Campo Local después. Para 2027 se debe crear una configuración nueva de ese año; el sistema no clona automáticamente 2026. Editar una configuración existente modifica esa fila de año/scope y reemplaza ejes/componentes, por lo que todavía no hay versionado inmutable de cambios intra-año.
12. El componente `annual_evidence_folder.max_points` del ranking anual es la fuente de verdad para el máximo de la Carpeta Anual de Evidencias. Una plantilla `PUBLISHED` debe distribuir exactamente ese total entre sus secciones; plantillas `DRAFT` pueden tener suma parcial, pero no generan carpetas hasta publicarse válidamente.
13. El folder transiciona a nivel carpeta completa como `open → submitted → under_evaluation → evaluated → closed`; sin embargo, una sección ya enviada (`annual_folder_section_evaluations.status = SUBMITTED`) puede evaluarse mientras la carpeta sigue `open`, porque otras secciones pueden continuar en carga/envío incremental.
14. Las plantillas `PUBLISHED` o `ARCHIVED` no se editan ni eliminan para preservar auditoría. Si se necesita reutilizar una estructura, el admin crea una copia `DRAFT`; si sigue siendo borrador y no tiene carpetas generadas, puede eliminarse.

## Flujo de revision en dos niveles

La evaluacion de una seccion puede atravesar hasta dos niveles de aprobacion, controlados por el flag `requires_union_confirmation` que el folder hereda de su carpeta de camporee al momento de creacion.

- **Camino con union (`requires_union_confirmation = true`)**:
  1. El club sube evidencias y ejecuta `submitSection` por cada seccion lista para revision.
  2. Un actor de campo local (LF) califica con `POST .../sections/:sectionId/evaluate`. La carpeta puede seguir `open`; la precondición real es que la fila de sección esté `SUBMITTED`. La seccion pasa a `PREAPPROVED_LF` y se graba `lf_approved_by` / `lf_approved_at`.
  3. Un actor de union ejecuta `POST .../sections/:sectionId/confirm-union` con decision `APPROVED` o `REJECTED_OVERRIDE`. La seccion transiciona a `VALIDATED` o `REJECTED` respectivamente. Las columnas LF se preservan intactas para auditoria.
  4. Si antes de la confirmación de Unión se requiere corregir la evaluación LF, el backend aún permite re-evaluar una fila `PREAPPROVED_LF`; la UX principal del panel prioriza `confirm-union` para evitar confundir esa corrección con la decisión final de Unión.

- **Atajo sin union (`requires_union_confirmation = false`)**:
  1. El club ejecuta `submitSection`.
  2. El actor LF evalua con `POST .../evaluate`. La carpeta puede seguir `open`; la precondición real es que la fila de sección esté `SUBMITTED`. Como el folder no requiere union, la seccion transiciona directamente de `SUBMITTED` a `VALIDATED`. Para mantener simetria de auditoria, el servicio espeja las columnas de union con el mismo actor LF (`union_approved_by`, `union_approved_at`, `union_decision = APPROVED`).

Solo las filas `VALIDATED` suman puntos al total del folder. Las filas `REJECTED` son terminales para el flujo y cuentan para avanzar el folder a `evaluated`, pero aportan 0 puntos. Filas en `PENDING`, `SUBMITTED` o `PREAPPROVED_LF` no contribuyen al calculo.

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
- **Premios operativos en ranking config**: el panel usa `ranking_tiers` como fuente de verdad visual para rangos de reconocimiento. El CRUD backend de `award_categories` permanece disponible como catálogo legacy/API, pero no se expone como flujo principal del módulo.
- **closing_date bloquea submissions pero NO evaluacion**: el campo puede evaluar despues del cierre
- **Flutter backward-compatible**: campos nullable con fallbacks para backends sin actualizar
- **Separacion de colas**: `EvidenceReview` no revisa la Carpeta Anual de Evidencias; el módulo `annual-folders` usa endpoints propios por folder/seccion (`POST /annual-folders/:folderId/sections/:sectionId/evidences`, `submit`, `evaluate`, `confirm-union`)
- **Nombre visible de evidencias**: Los adjuntos del módulo `annual-folders` se etiquetan como `Evidencia 01`, `Evidencia 02`, etc. El nombre original del archivo y la clave técnica de R2 no deben presentarse como título visible; uploader, fecha y sección quedan como metadata.
- **Ranking anual no es solo carpeta**: la app y el panel calculan componentes configurables mediante el registry de score. La Carpeta Anual de Evidencias es un componente, no el ranking completo.
- **Ranking manda el máximo de carpeta**: `annual_evidence_folder.max_points` define el total obligatorio que las secciones de la plantilla activa deben sumar. Config Unión tiene precedencia sobre Campo Local.
- **Lifecycle de plantillas**: `active` indica capacidad runtime de generar carpetas; `status` explica el ciclo administrativo (`DRAFT`, `PUBLISHED`, `ARCHIVED`). La UX no debe permitir editar una publicada; debe copiarla para una nueva iteración.
- **Componentes de ranking registrados**: la UI puede reorganizar y agregar/quitar componentes soportados por el registry backend, pero no inventar claves arbitrarias sin implementar su fórmula de scoring.
- **Uso operativo sin vanity metrics**: `sacdia_operational_usage` mide acciones útiles registradas en SACDIA (asistencia semanal, clases/progreso, informes, actividades), no sesiones ni logins.

## Formulas actuales del ranking anual por ejes

| Componente | Formula |
|---|---|
| `annual_evidence_folder` | puntos reales de Carpeta Anual (`total_earned_points / total_max_points`); el máximo debe coincidir con `annual_evidence_folder.max_points` del ranking efectivo |
| `monthly_reports_timeliness` | informes mensuales `submitted` a tiempo / meses del año eclesiástico; deadline configurable en `ranking.monthly_report_deadline_day` (default 5) |
| `finance_compliance` | cierres financieros mensuales a tiempo / 12; deadline configurable en `ranking.finance_closing_deadline_day` (default 5) |
| `institutional_data_completeness` | 10 campos institucionales completos: dirección, horario, director, secretaría, tesorería, nombre, teléfono, email, coordenadas y meta de almas |
| `activities_registered` | actividades activas de la sección durante el año / `ranking.activities_registered_target` (default 12) |
| `attendance_participation` | promedio de `weekly_records.attendance` para miembros activos de la sección |
| `camporee_events` | resultados oficiales activos de eventos puntuables: `sum(camporee_event_section_results.total_awarded_points) / sum(camporee_events.max_points)` por sección; inscripciones/asistencia no otorgan puntos |
| `class_investiture_progress` | clases activas investidas/aprobadas / clases activas de miembros de la sección |
| `sacdia_operational_usage` | usuarios activos de la sección con acciones operativas útiles / usuarios activos de la sección |

## Gaps y pendientes

- E2E smoke test pendiente (crear template → folder → evidencia → submit → evaluar → rankings)
- No hay notificaciones push cuando el campo evalua un folder
- No hay vista de evaluacion en la app (solo admin)
- Auto-close por `closing_date` no implementado (solo manual)
- No hay versionado inmutable intra-año de configuraciones de ranking; se conserva una fila activa por año/scope/tipo de club.

## Reglas de scoring de carpeta anual

- El revisor LF asigna `earned_points` entre 0 y `max_points`.
- Solo secciones `VALIDATED` aportan puntos al total de carpeta.
- Secciones `REJECTED` son terminales para el flujo, pero aportan 0 puntos.
- Cuando Unión aplica `REJECTED_OVERRIDE`, el servicio fuerza `earned_points = 0` antes de recalcular totales.
