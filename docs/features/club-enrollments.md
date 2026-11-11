# Registro anual del club (club enrollments)

**Estado**: IMPLEMENTADO. La validación por alcance (permiso `club_enrollments:validate`, motivo de rechazo, revisor registrado y avisos) entró en `development` con el PR #650 de sacdia-backend, el #253 de sacdia-app y el #302 de sacdia-admin (2026-11-11).
**Verificado contra código**: 2026-11-11 (`development` tras el merge del PR #650 de sacdia-backend)
**Dominios relacionados**: [gestion-clubs.md](gestion-clubs.md), [carpetas-evidencias.md](carpetas-evidencias.md), [monthly-reports.md](monthly-reports.md), [cierre-anual.md](cierre-anual.md)

## Descripcion de dominio

Cada año eclesiástico, cada sección de club envía su registro anual (en el código y las rutas sigue llamándose `club_enrollments` / `enrollments`): dirección y horario de reuniones, meta de almas, cuota y directiva (director, subdirectores, secretario, tesorero o secretario-tesorero). La directiva no la escribe el cliente: sale de los cargos de club activos de la sección (ver «Directiva desde los cargos»). El registro nace pendiente de validación; un revisor con alcance sobre esa sección la aprueba (queda activa y se crea la carpeta anual de evidencias si hay plantilla) o la rechaza con un motivo para que la sección corrija y vuelva a enviarla. Los informes mensuales y las carpetas cuelgan de esta inscripción (`club_enrollment_id`).

No confundir con `enrollments` (inscripción de un miembro en una clase progresiva) ni con la inscripción anual de miembros (`annual-membership`, documentada en [gestion-clubs.md](gestion-clubs.md), "Plantilla anual de miembros").

## Que existe (verificado contra codigo)

### Backend (`src/club-enrollments/`)

Controllers con `JwtAuthGuard` + `PermissionsGuard`.

| Método | Ruta (`/api/v1`) | Permiso | Recurso |
|---|---|---|---|
| POST | `/clubs/:clubId/sections/:sectionId/enrollments` | `club_instances:create` | `club_section` |
| GET | `/clubs/:clubId/sections/:sectionId/enrollments` | `club_instances:read` | `club_section` |
| GET | `/clubs/:clubId/sections/:sectionId/enrollments/current` | `club_instances:read` | `club_section` |
| PATCH | `/clubs/:clubId/sections/:sectionId/enrollments/:enrollmentId` | `club_instances:update` | `club_section` |
| GET | `/club-enrollments/validation/queue` | `club_enrollments:validate` | `global` |
| POST | `/club-enrollments/:enrollmentId/approve` | `club_enrollments:validate` | `global` |
| POST | `/club-enrollments/:enrollmentId/reject` | `club_enrollments:validate` | `global` |

El recurso de las cuatro rutas de sección es `club_section` (`clubIdParam: 'clubId'`, `idParam: 'sectionId'`), no `club`. Las tres rutas de validación ya no llevan el bind `club_enrollment_territory`: el permiso abre la puerta y el alcance lo decide el servicio.

### Reglas de la sección (alta y edición)

Verificadas en `club-enrollments.service.ts`:

- **Estados** (texto): `pending_validation`, `active`, `rejected`, `inactive`; el cierre de año los pasa a `closed`.
- **Alta**: la sección debe existir y pertenecer al club (`CE_SECTION_NOT_FOUND`). Usa el año eclesiástico vigente por fechas (`CatalogsService.getCurrentEcclesiasticalYear`; `CE_NO_ACTIVE_YEAR` si no hay). Una inscripción por sección y año (`UNIQUE (club_section_id, ecclesiastical_year_id)`): si ya existe y no está `rejected` ni `inactive`, responde `CE_ALREADY_ENROLLED`; si está `rejected` o `inactive`, se reescribe y vuelve a `pending_validation`. Comprobación y alta corren en una transacción.
- **Directiva desde los cargos**: `CreateClubEnrollmentDto` (y por herencia el PATCH) ya no tiene `director_id`, `deputy_director_ids`, `secretary_id`, `treasurer_id` ni `secretary_treasurer_id`; un cliente que los envíe recibe 400 (`forbidNonWhitelisted`). El servidor guarda una foto de los cargos de club de la sección en el año eclesiástico del registro (`SectionBoardSnapshotService`, `src/common/authorization/section-board-snapshot.service.ts`), en cada POST (también sobre uno rechazado o inactivo) y en cada PATCH:
  - Cuentan solo asignaciones `active = true`, `status = 'active'` y sin `end_date` vencido, de esa sección y ese año. Otras secciones, otros años y asignaciones terminadas o inactivas se ignoran.
  - `director` → `director_id`; `secretary` → `secretary_id`; `treasurer` → `treasurer_id`; `secretary-treasurer` → `secretary_treasurer_id`; cada uno el titular más antiguo (por `start_date`, luego `user_id`) o `NULL` si no hay.
  - `deputy-director` → `deputy_director_ids`: hasta 2, en orden de `start_date` y luego `user_id`; `[]` si no hay.
  - Ya no se valida la exclusión secretario/tesorero vs secretario-tesorero: la regla la imponen los cupos de cargos. `CE_SECRETARY_TREASURER_EXCLUSIVE` sigue en el enum y las traducciones porque los clientes lo conocen.
- **Fecha de envío** (`submitted_at`): se fija al crear y cada vez que el registro vuelve a `pending_validation` (POST o PATCH sobre uno rechazado o inactivo). Aprobar, rechazar y editar uno aprobado no la tocan.
- **Edición**: actualiza solo los campos enviados; si la inscripción estaba `rejected` o `inactive`, vuelve a `pending_validation`.
- **Reenvío (D3)**: al volver a `pending_validation` (POST sobre una rechazada o inactiva, o PATCH sobre una rechazada o inactiva) se ponen en `NULL` `reviewed_by_id`, `reviewer_role`, `reviewed_at` y `decision_reason`.
- **Editar una aprobada (D4)**: sigue `active`, no se revalida y conserva su revisión.
- **Lo que ve la dirección**: `GET …/enrollments/current`, el POST y el PATCH devuelven la fila completa, con `status`, `decision_reason` y `reviewed_at`.

### Validación (`club-enrollment-review.service.ts`)

#### Decisiones de producto (aprobadas)

| Id | Decisión |
|---|---|
| D1 | Valida quien tiene alcance sobre la sección, cada uno solo dentro de su alcance: Campo Local (`director-lf`, `assistant-lf`) los clubes de su campo local; Unión (`director-union`, `assistant-union`) los de su unión; División (`director-dia`, `assistant-dia`) los de su división; coordinación (`coordinator`, `zone-coordinator`, `general-coordinator`) las secciones de sus asignaciones de coordinación activas; `pastor` los clubes de sus distritos mientras sea pastor elegible; `admin`, `assistant-admin` y `super-admin`, todo. |
| D2 | Rechazar exige un motivo (se recorta; 5 a 500 caracteres). Lo ven la dirección y quien envió la inscripción. |
| D3 | El rechazo no es terminal: la sección corrige y reenvía; al reenviar se borran los cuatro campos de revisión. |
| D4 | Editar una inscripción aprobada la deja `active` (sin revalidar). |
| D5 | Al aprobar o rechazar se envía push + bandeja al `director_id` y a `created_by` de la inscripción (sin duplicados y sin avisar al propio revisor). No se avisa a los revisores cuando llega una inscripción. |
| D6 | Autorrevisión bloqueada: quien tenga un cargo de club activo (cualquier rol salvo `member`) en esa sección y en el año de la inscripción no puede aprobarla ni rechazarla: 403 `CE_SELF_REVIEW`. |
| D7 | Aprobar conserva solo los efectos de hoy: estado `active` y crear la carpeta anual si hay plantilla. Sin condiciones nuevas. |

#### Alcance del revisor

`ReviewerScopeService` (`src/common/authorization/reviewer-scope.service.ts`) resuelve los canales del revisor para un permiso dado, en este orden: administración (todo), Campo Local, Unión, División, coordinación, pastor. Un rol solo cuenta si lleva el permiso. La revisión de constancias de consejería (`ServiceCredentialReviewScopeService`) hereda de él con el mismo comportamiento de siempre y **sin** canales de unión ni de división; las inscripciones sí los abren (`includeUnionDivision`) y suman a `assistant-admin` entre los roles que ven todo.

- Un rol de Campo Local, Unión o División sin su id territorial no abre canal.
- La coordinación usa `CoordinationService.getEffectiveCoordinatorSectionIds`; sin asignaciones vigentes no abre canal.
- El pastor cuenta solo si tiene asignaciones activas en `district_investiture_pastors` y `pastorCanAuthorize` lo da por elegible.
- `reviewer_role` guarda el rol del primer canal que cubre la sección (por ejemplo `director-lf`), igual que las constancias.

#### Bandeja: `GET /club-enrollments/validation/queue`

Consulta: `status` (`pending_validation` por defecto, `active`, `rejected`), `search` (cada palabra debe coincidir con club, tipo de club, campo local o nombre de quien envió o dirige; nunca correo ni teléfono), `ecclesiastical_year_id` (por defecto el año vigente), `local_field_id`, `club_type_id`, `page`, `limit` (1 a 100, 20 por defecto). Pendientes: el de `submitted_at` más antiguo primero (sin fecha al final, luego `created_at`); revisadas: la revisión más reciente primero.

Respuesta `{ status: 'success', data: { items, meta: { page, limit, total, counts: { pending, approved, rejected } } } }`. `counts` cubre todo el alcance del revisor para el año elegido con los demás filtros y sin el filtro de estado.

Cada `item`:

```json
{
  "enrollment_id": "0b0c…",
  "status": "pending_validation",
  "ecclesiastical_year": { "id": 7, "name": "2026" },
  "club": { "id": 9, "name": "Club Águila" },
  "section": { "id": 44, "club_type_id": 3, "club_type_name": "Conquistadores" },
  "local_field": { "id": 1, "name": "Campo Centro" },
  "address": "Av. Central 1",
  "latitude": 19.4,
  "longitude": -99.1,
  "meeting_days": "Sábado",
  "meeting_schedule": [{ "day": "Sábado", "time": "09:00" }],
  "souls_target": 12,
  "fee": true,
  "fee_amount": 25.5,
  "board": {
    "director": { "user_id": "…", "name": "Dora Pérez" },
    "deputies": [{ "user_id": "…", "name": "Dani Pérez" }],
    "secretary": null,
    "treasurer": null,
    "secretary_treasurer": { "user_id": "…", "name": "Tomás Pérez" }
  },
  "submitted_by": { "user_id": "…", "name": "Sara Pérez" },
  "created_at": "2026-11-01T10:00:00.000Z",
  "submitted_at": "2026-11-01T12:00:00.000Z",
  "modified_at": "2026-11-02T10:00:00.000Z",
  "reviewed_by": null,
  "reviewer_role": null,
  "reviewed_at": null,
  "decision_reason": null
}
```

Los nombres son el nombre completo; la bandeja nunca devuelve correo ni teléfono.

#### Decidir: `approve` y `reject`

- `POST /club-enrollments/:enrollmentId/approve` (sin cuerpo) y `POST /club-enrollments/:enrollmentId/reject` con `{ "reason": "Falta la dirección del templo" }`. Responden 200 y `{ status: 'success', data: <item> }` (la misma forma que la bandeja). Límite de 30 por minuto.
- Orden de las comprobaciones: inscripción inexistente → 404 `CE_ENROLLMENT_NOT_FOUND`; fuera del alcance del revisor → el mismo 404 (para que no se puedan sondear ids); autorrevisión (D6) → 403 `CE_SELF_REVIEW`; aprobar una ya `active` → 200 sin cambios, sin avisos ni carpeta; cualquier otro estado distinto de `pending_validation` → 409 `CE_ENROLLMENT_NOT_PENDING`. Motivo ausente o fuera de 5 a 500 caracteres → 400 de validación.
- La escritura es una transacción con reclamo condicional (`WHERE status = 'pending_validation'`): si dos revisores deciden a la vez, el segundo recibe 409 `CE_ENROLLMENT_NOT_PENDING`. Escribe `status`, `reviewed_by_id`, `reviewer_role`, `reviewed_at` y `decision_reason` (`NULL` al aprobar), y una fila de auditoría crítica (`CLUB_ENROLLMENT_APPROVED` / `CLUB_ENROLLMENT_REJECTED`, entidad `club_enrollments`; la clave del evento lleva el instante porque una inscripción rechazada puede decidirse otra vez tras reenviarse).
- Aprobar intenta crear la carpeta anual (`AnnualFoldersService.createFolderForEnrollment`); sin plantilla o con carpeta existente, lo ignora.

#### Avisos (D5)

Fuente `club-enrollments:reviewed` (categoría `approvals`), vía `notifySafe` (nunca rompe la decisión). Datos: `{ type: 'club_enrollment_reviewed', entity_id, action: 'approved' | 'rejected', club_section_id }`. Títulos «Registro anual aprobado» / «Registro anual rechazado»; cuerpos «El registro anual 2026 de Estella (Aventureros) fue aprobado.» y «…fue rechazado: {motivo}». Los textos de los errores `CE_*` en los cuatro idiomas también dicen «registro anual».

#### Códigos de error

| Código | HTTP | Cuándo |
|---|---|---|
| `CE_ENROLLMENT_NOT_FOUND` | 404 | No existe, o está fuera del alcance del revisor |
| `CE_SELF_REVIEW` | 403 | El revisor tiene un cargo de club activo en esa sección y año |
| `CE_ENROLLMENT_NOT_PENDING` | 409 | Ya no está pendiente (o alguien decidió antes) |
| `CE_SECRETARY_TREASURER_EXCLUSIVE` | 400 | Sin uso hoy (la directiva sale de los cargos); el miembro del enum se conserva |
| `CE_ECCLESIASTICAL_YEAR_REQUIRED` | 400 | Sin uso hoy; el miembro del enum se conserva por si algún cliente lo conoce |

### Permiso `club_enrollments:validate`

Concedido a `super-admin`, `admin`, `assistant-admin`, `director-lf`, `assistant-lf`, `director-union`, `assistant-union`, `director-dia`, `assistant-dia`, `coordinator`, `zone-coordinator`, `general-coordinator` y `pastor`. Nunca a roles de club. Capacidad publicada en `GET /auth/me`: `club_enrollments.validate`. Migración `20261111130000_club_enrollments_validate_permission` (solo datos, idempotente) y semilla con limpieza que retira el permiso a cualquier otro rol.

### App móvil

- `lib/features/enrollment/`: `EnrollmentFormView` crea, consulta (`/current`) y edita la inscripción de la sección. Ahora recibe `decision_reason` y `reviewed_at` para mostrar por qué se rechazó.
- La tarjeta del registro anual del inicio (`EnrollmentStatusCard`: falta, enviado, rechazado) solo la ve la directiva de la sección activa: capacidad `club.administrative_staff` (director, subdirector, secretario, tesorero y secretario-tesorero). Consejeros, instructores y miembros no la ven.

### Admin

- `src/lib/api/club-enrollments.ts` usa `GET …/enrollments/current` desde la página de informes (`/dashboard/reports`).
- La pantalla de validación de la bandeja (`/club-enrollments/validation/queue`, `approve`, `reject`) es trabajo de la PR #650 de sacdia-backend del admin. `/dashboard/enrollments` era otra cosa (inscripciones de clase pendientes de investidura, borrada en la fase 8).

### Base de datos

- `club_enrollments`: `club_section_id`, `ecclesiastical_year_id`, `status` (por defecto `active` en el schema; el servicio crea con `pending_validation`), `address`, `meeting_days`, `latitude`, `longitude`, `meeting_schedule` (JSON), `souls_target`, `fee`, `fee_amount`, `director_id`, `deputy_director_ids` (arreglo), `secretary_id`, `treasurer_id`, `secretary_treasurer_id`, `created_by`, `closed_at`. La directiva (`director_id`, `deputy_director_ids`, `secretary_id`, `treasurer_id`, `secretary_treasurer_id`) es una foto de los cargos de club, no entrada del cliente.
- Envío (misma migración): `submitted_at` (`timestamptz(6)`, nulo; se rellena con `created_at` en las filas existentes).
- Revisión (migración `20261111120000_club_enrollment_review`): `reviewed_by_id` (uuid, FK `users`, sin acción), `reviewer_role` (`varchar(50)`), `reviewed_at` (`timestamptz(6)`), `decision_reason` (`text`); todas nulas. Relación `reviewer` (`enrollment_reviewer`).

### Datos de demostración

`sacdia-backend/scripts/demo/seed-enrollments-demo.ts` (solo desarrollo): `--demo` planea y `--demo --apply` crea hasta 3 inscripciones `pending_validation` del año vigente en secciones activas sin inscripción y con director; es idempotente (ids determinísticos) y `--cleanup --apply` las retira.

## Gaps cerrados con la validación

- El rechazo ya no pierde el motivo: se guarda en `decision_reason` y lo ven la dirección y quien envió.
- Se registra quién decidió, con qué rol y cuándo (`reviewed_by_id`, `reviewer_role`, `reviewed_at`) y hay auditoría crítica.
- La bandeja suma todos los alcances del revisor (antes se elegía solo el primero que coincidía: campo local, luego unión, luego asignación; la división, las coordinaciones y los pastores veían una bandeja vacía).
- Aprobar y rechazar exigen `club_enrollments:validate` y comprueban el alcance en el servicio, en vez de pedir `club_instances:update` global más el bind territorial.
- La directiva del registro sale de los cargos activos de la sección; ya no hay regla secretario/tesorero en el registro y `CE_SECRETARY_TREASURER_EXCLUSIVE` quedó sin uso (el código ya no se confunde con `CE_ECCLESIASTICAL_YEAR_REQUIRED`).
- Quien envía recibe push + bandeja al aprobar o rechazar.
- La tabla de rutas decía `club` como tipo de recurso; el código usa `club_section`.

## Gaps y pendientes

- La clave `club_enrollment_territory` del `AuthorizationResource` sigue existiendo en el decorador y en `TenantBindingEnforcer`, pero ninguna ruta la usa ya.
