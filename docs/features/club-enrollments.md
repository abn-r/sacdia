# Inscripción anual de club (club enrollments)

**Estado**: IMPLEMENTADO PARCIAL
**Verificado contra código**: 2026-10-04 (rama `development`)
**Dominios relacionados**: [gestion-clubs.md](gestion-clubs.md), [carpetas-evidencias.md](carpetas-evidencias.md), [monthly-reports.md](monthly-reports.md), [cierre-anual.md](cierre-anual.md)

## Descripcion de dominio

Cada año eclesiástico, cada sección de club se inscribe ante el Campo Local: dirección y horario de reuniones, meta de almas, cuota y directiva (director, subdirectores, secretario, tesorero o secretario-tesorero). La inscripción nace pendiente de validación; al aprobarla queda activa y se crea la carpeta anual de evidencias si hay plantilla. Los informes mensuales y las carpetas cuelgan de esta inscripción (`club_enrollment_id`).

No confundir con `enrollments` (inscripción de un miembro en una clase progresiva) ni con la inscripción anual de miembros (`annual-membership`, documentada en [gestion-clubs.md](gestion-clubs.md), "Plantilla anual de miembros").

## Que existe (verificado contra codigo)

### Backend (`src/club-enrollments/`)

Controllers con `JwtAuthGuard` + `PermissionsGuard`.

| Método | Ruta (`/api/v1`) | Permiso | Recurso |
|---|---|---|---|
| POST | `/clubs/:clubId/sections/:sectionId/enrollments` | `club_instances:create` | `club` |
| GET | `/clubs/:clubId/sections/:sectionId/enrollments` | `club_instances:read` | `club` |
| GET | `/clubs/:clubId/sections/:sectionId/enrollments/current` | `club_instances:read` | `club` |
| PATCH | `/clubs/:clubId/sections/:sectionId/enrollments/:enrollmentId` | `club_instances:update` | `club` |
| GET | `/club-enrollments/validation/queue` | `club_instances:update` | `global` |
| POST | `/club-enrollments/:enrollmentId/approve` | `club_instances:update` | `global` |
| POST | `/club-enrollments/:enrollmentId/reject` | `club_instances:update` | `global` |

Reglas verificadas en `club-enrollments.service.ts`:

- **Estados** (texto): `pending_validation`, `active`, `rejected`, `inactive`; el cierre de año los pasa a `closed`.
- **Alta**: la sección debe existir y pertenecer al club (`CE_SECTION_NOT_FOUND`). Usa el año eclesiástico vigente por fechas (`CatalogsService.getCurrentEcclesiasticalYear`; `CE_NO_ACTIVE_YEAR` si no hay). Una inscripción por sección y año (`UNIQUE (club_section_id, ecclesiastical_year_id)`): si ya existe y no está `rejected` ni `inactive`, responde `CE_ALREADY_ENROLLED`; si está `rejected` o `inactive`, se reescribe y vuelve a `pending_validation`. Comprobación y alta corren en una transacción.
- **Directiva**: no se puede indicar a la vez secretario o tesorero por separado y secretario-tesorero combinado.
- **Edición**: actualiza solo los campos enviados; si la inscripción estaba `rejected` o `inactive`, vuelve a `pending_validation`.
- **Aprobación**: idempotente si ya está `active`; si no está `pending_validation`, responde `RECORD_CONFLICT`. Al aprobar intenta crear la carpeta anual (`AnnualFoldersService.createFolderForEnrollment`); si no hay plantilla o la carpeta ya existe, lo ignora.
- **Rechazo**: solo desde `pending_validation`.
- **Bandeja de validación**: por defecto muestra `pending_validation`; filtros por estado, catálogo y texto; paginada (`limit` máximo 100). `admin` y `super-admin` ven todo; los demás, su campo local, si no su unión y, en último caso, la sección de su asignación activa.

### App móvil

- `lib/features/enrollment/`: `EnrollmentFormView` crea, consulta (`/current`) y edita la inscripción de la sección.

### Admin

- `src/lib/api/club-enrollments.ts` solo usa `GET …/enrollments/current`, desde la página de informes (`/dashboard/reports`).
- No hay pantalla para la bandeja de validación (`/club-enrollments/validation/queue`, `approve`, `reject`). `/dashboard/enrollments` era otra cosa: listaba inscripciones de clase pendientes de investidura (`/investiture/pending`). La fase 8 la borró (implementada en código, sin desplegar).

### Base de datos

- `club_enrollments`: `club_section_id`, `ecclesiastical_year_id`, `status` (por defecto `active` en el schema; el servicio crea con `pending_validation`), `address`, `meeting_days`, `latitude`, `longitude`, `meeting_schedule` (JSON), `souls_target`, `fee`, `fee_amount`, `director_id`, `deputy_director_ids` (arreglo), `secretary_id`, `treasurer_id`, `secretary_treasurer_id`, `created_by`, `closed_at`.

## Gaps y pendientes

- La violación de la regla secretario/tesorero responde con el código `CE_ECCLESIASTICAL_YEAR_REQUIRED`, que no describe el error.
- Falta UI de validación en el admin: hoy una inscripción nueva queda en `pending_validation` sin pantalla para aprobarla.
- No se registra quién aprobó o rechazó (solo log).
