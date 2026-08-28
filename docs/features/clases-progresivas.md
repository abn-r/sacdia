# Clases Progresivas

**Estado**: IMPLEMENTADO

## Descripcion de dominio

Las clases progresivas son el eje central del proceso formativo institucional en los clubes de Aventureros, Conquistadores y Guias Mayores. Representan un camino secuencial de avance donde cada miembro cursa una clase determinada por su edad al inicio del ano eclesiastico. Las clases de Conquistadores, por ejemplo, siguen la secuencia: Amigo, Companero, Explorador, Orientador, Viajero, Guia.

Cada clase se compone de modulos tematicos, y cada modulo contiene secciones evaluables. El progreso se registra por seccion (puntaje + evidencias) y se proyecta a nivel de modulo. La regla fundamental es que la clase se determina por la edad al inicio del ano eclesiastico y NO cambia durante ese ciclo — un miembro que cumple anos a mitad de ano sigue en su clase original. En post-registro, el backend deriva la clase esperada desde `users.birthday`, el inicio del ano eclesiastico activo, el `club_type_id` de la seccion seleccionada y `classes.minimum_age`; si el cliente envia un `class_id` que no coincide, la API lo rechaza.

El sistema adopta una única fuente de verdad: el **ciclo anual operativo** es gestionado enteramente por `enrollments` con sus proyecciones de progreso (`class_module_progress`, `class_section_progress`). La tabla legacy `users_classes` fue retirada del schema actual y ya no participa en el modelo operativo. El histórico consolidado se consulta directamente desde `enrollments` con filtros históricos por año eclesiástico.

La culminacion exitosa de una clase lleva a la investidura, que es el acto institucional de reconocimiento formal. El flujo de validacion e investidura ya existe y ahora valida tambien la ventana de disponibilidad de la clase y su duracion minima/maxima por ano eclesiastico (ver feature `validacion-investiduras`).

Las secciones ahora se separan en `BASIC`, `ADVANCED` y `EXTRA`: `BASIC` + `EXTRA` aplicables cuentan para investidura, mientras `ADVANCED` habilita la via/badge avanzado de la clase por separado.

## Que existe (verificado contra codigo)

### Backend (ClassesModule)
- **Controladores**: `ClassesController` (catalogo publico, progreso/evidencias e inscripciones) + `AdminPhaseECatalogsController` (CRUD admin de clases) + `InvestitureController` (vencimiento manual de enrollments atrasados)
- **Catalogo publico** (OptionalJwtAuthGuard):
  - `GET /classes` — listar clases con paginacion y filtro por clubTypeId; por defecto solo devuelve clases disponibles para inscripcion en el ano eclesiastico vigente
  - `GET /classes/:classId` — detalle de clase con modulos/secciones y `prerequisites` activos (`[{ class_id, name }]`)
  - `GET /classes/:classId/modules` — módulos de una clase con sus secciones y `honors[]` embebidos
  - `GET /classes/:classId/honors` — especialidades relacionadas via `class_honors` (informativas; JWT opcional agrega `user_status`; incluye `module_id`, `module_name`, `material_url`)
- **Inscripciones de usuario** (JwtAuthGuard + PermissionsGuard):
  - `GET /users/:userId/classes` — listar inscripciones del usuario (filtro por yearId)
  - `POST /users/:userId/classes/enroll` — inscribir usuario en clase (class_id + ecclesiastical_year_id); bloquea clases inactivas o fuera de ventana de disponibilidad
  - `GET /users/:userId/classes/:classId/progress` — progreso anual (acepta ?enrollmentId= como override)
  - `PATCH /users/:userId/classes/:classId/progress` — actualizar progreso de seccion (module_id, section_id, score, evidences, enrollment_id opcional)
- **Asignación pedagógica de clases** (JwtAuthGuard + PermissionsGuard):
  - `GET /clubs/:clubId/sections/:sectionId/class-counselor-assignments` — listar responsables de clases de una sección (`yearId`, `classId`, `active` opcionales)
  - `POST /clubs/:clubId/sections/:sectionId/class-counselor-assignments` — asignar consejero/secretario a una clase
  - `PATCH /class-counselor-assignments/:assignmentId` — editar responsabilidad, excepción o fechas
  - `DELETE /class-counselor-assignments/:assignmentId` — revocar asignación (soft delete)
  - `GET /clubs/:clubId/sections/:sectionId/classes/progress-scope` — listar clases que el actor puede supervisar en la sección (`yearId` opcional)
  - `GET /clubs/:clubId/sections/:sectionId/classes/:classId/members-progress` — listar avance resumido de miembros activos de esa sección inscritos en la clase (`yearId` opcional)
- **Servicio**: `ClassesService` con spec de tests
- **DTOs**: EnrollClassDto, UpdateProgressDto
- **Decoradores**: lecturas/escrituras de progreso usan `@RequirePermissions('classes:read'/'classes:submit_progress')` + `@AuthorizationResource({ type: 'active_assignment' })`; las escrituras propias declaran además `ownerParam: 'userId'` para permitir self-service antes de exigir permisos de club. La autorización fina de self, directiva de sección y consejero/secretario asignado vive en `ClassProgressAccessService`.

### Admin (sacdia-admin)
- CRUD de clases activo desde catalogos/admin, incluyendo traducciones, disponibilidad por ano eclesiastico y duracion minima/maxima.
- Consume `GET|POST|PATCH|DELETE /admin/classes` para administrar el catalogo.
- En el detalle de club, la pestaña de secciones incluye una tarjeta “Clases asignadas” por sección para listar, crear, editar y revocar responsables pedagógicos mediante `class_counselor_assignments`.
- La UI filtra candidatos asignables a roles `counselor` y `secretary`; `instructor` no aparece como responsable formal de clase.
- Incluye proceso manual auditable para vencer enrollments atrasados: primero `dry_run`, luego confirmacion explicita antes de aplicar `POST /admin/classes/enrollments/expire-overdue`.
- No gestiona progreso operativo de miembros desde el CRUD de catalogos.

### App (sacdia-app)
- 9 screens: ClassesListView, ClassDetailView, ClassDetailWithProgressView, ClassModulesView, SectionDetailView, RequirementDetailView, TeachingScopeView, ClassMembersProgressView, ClassCounselorAssignmentsView.
- Consume endpoints de listado, detalle, modulos, inscripcion, progreso, subida/borrado de archivos de evidencia, alcance pedagógico por sección y asignación pedagógica de clases.
- En post-registro, la app preselecciona la sección por edad (Aventureros 4-9, Conquistadores 10-15, Guías Mayores 16+) y la clase progresiva elegible por la mayor `minimum_age` menor o igual a la edad; el backend sigue siendo la autoridad final de la derivación.
- El acceso rápido `/home/grouped-class` abre `TeachingScopeView`: directores/subdirectores/secretaría ven las clases de toda la sección; consejeros con asignación ven sólo sus clases asignadas.
- Desde `TeachingScopeView`, los usuarios con `club_roles:assign`/`club_roles:revoke` pueden abrir “Gestionar clases” para crear, editar y revocar asignaciones de consejeros/secretaría a clases de la sección.
- `ClassMembersProgressView` lista los miembros activos de la sección inscritos en la clase y navega al detalle de progreso con `targetUserId` + `enrollmentId`; las evidencias se guardan sobre el enrollment del miembro objetivo y el actor sigue siendo el usuario autenticado.
- `ClassDetailWithProgressView` consume progreso separado por `basic_progress`, `advanced_progress`, `extra_progress`, `investiture_eligibility` y `advanced_eligibility`; la tarjeta de investidura usa `overall_progress` como progreso de requisitos obligatorios, no como avance total de actividades opcionales.
- En `ClassDetailWithProgressView`, los requisitos se presentan en secciones visuales separadas: `DESARROLLO DE CLASE` para requisitos básicos, `AVANZADO` para puntos avanzados opcionales y `ACTIVIDADES COMPLEMENTARIAS` para requisitos institucionales aplicables.
- La tarjeta resumen de avance unifica el porcentaje principal como avance de investidura (`Desarrollo de clase` + `Actividades complementarias` aplicables); debajo sólo muestra `Sección avanzada` como avance independiente cuando la clase la tiene habilitada.

### Base de datos
- `classes` — catalogo de clases (class_id, name, club_type_id, order) con `advanced_enabled`, `available_from_year_id`, `available_until_year_id`, `min_duration_years`, `max_duration_years`
- `class_modules` — modulos por clase
- `class_sections` — secciones evaluables por modulo, segmentadas por `requirement_track` (`BASIC`, `ADVANCED`, `EXTRA`) y con owner opcional por division/union/campo local; `EXTRA` requiere exactamente un owner, `ADVANCED` nunca bloquea investidura
- `enrollments` — inscripcion anual operativa (enrollment_id, user_id, class_id, ecclesiastical_year_id, investiture_status, active). UNIQUE: (user_id, class_id, ecclesiastical_year_id). El estado `EXPIRED` preserva progreso historico cuando la duracion maxima ya vencio.
- `class_section_progress` — progreso por seccion con enrollment_id como owner anual. UNIQUE: (enrollment_id, module_id, section_id)
- `class_module_progress` — proyeccion de progreso por modulo. UNIQUE: (enrollment_id, module_id)
- `class_counselor_assignments` — asignación anual de responsables pedagógicos por usuario + sección + clase + año; máximo 3 activos por clase/sección/año y máximo 2 clases activas por persona/sección/año.
- `users_classes` — [RETIRADA] trayectoria consolidada legacy; no existe en el schema runtime actual

## Asignación pedagógica de clases

El rol operativo (`club_role_assignments`) y la responsabilidad pedagógica de una clase son conceptos distintos. Un usuario primero debe tener rol activo en la sección; luego puede recibir una clase mediante `class_counselor_assignments`.

Reglas vigentes:

- Roles asignables formalmente: `counselor` y `secretary`.
- `instructor` no es responsable formal de la trayectoria anual; sólo imparte segmentos o especialidades.
- El responsable asignable debe estar cursando o haber completado la clase `Guía Mayor`; esta elegibilidad aplica para todas las secciones (Aventureros, Conquistadores y Guías Mayores) y se valida también en backend.
- Cada clase/sección/año puede tener 1 `primary` y hasta 2 apoyos (`assistant`/`substitute`), máximo 3 activos.
- Una persona normalmente tiene 1 clase; la segunda clase requiere `exceptional=true` y `exception_reason`.
- Director, subdirector, secretario y secretario-tesorero tienen alcance de toda la sección para progreso/evidencias aunque no tengan asignación pedagógica directa.
- En evidencias delegadas, el owner del progreso sigue siendo el `enrollment` del miembro objetivo; `uploaded_by_id`/`submitted_by_id` representan al actor que subió o envió la evidencia.
- `ClassProgressAccessService` centraliza la autorización runtime: self access, bypass global ya permitido por guards (`super-admin`, admin/assistant-admin, coordinadores), asignación pedagógica activa o rol section-wide en la misma sección/año del miembro objetivo.
- `ClassProgressScopeService` expone el scope pedagógico colectivo: `progress-scope` devuelve `access_level = section|assigned`, y `members-progress` reusa ese scope pero filtra los enrollments por membresía activa en la sección solicitada para no mezclar miembros de otras secciones que cursen la misma clase.

## Requisitos funcionales

1. El catalogo de clases debe ser consultable sin autenticacion (OptionalJwtAuthGuard)
2. Las clases deben filtrarse por tipo de club (Aventureros=1, Conquistadores=2, GM=3)
3. La inscripcion anual crea un enrollment unico por (user_id, class_id, ecclesiastical_year_id)
4. El progreso se resuelve contra una inscripcion anual unica del ano eclesiastico actual
5. Si la resolucion class-scoped es ambigua (multiples enrollments), la API responde 409 con ENROLLMENT_RESOLUTION_AMBIGUOUS
6. El progreso de seccion registra puntaje y evidencias (JSON)
7. El progreso de modulo se calcula como proyeccion sincronizada de sus secciones
8. Si el usuario re-ejecuta post-registro por correccion/cambio de club, el backend deriva la clase por edad/tipo de club y desactiva otros enrollments activos del mismo ano antes de resolver el seleccionado
9. Si una transferencia de club/seccion es aprobada, el backend aplica la misma regla: deriva la clase para el `club_type_id` destino y resuelve el enrollment anual activo
10. Una clase con `available_until_year_id = null` no expira para nuevas inscripciones; si tiene valor, deja de aparecer para inscripcion despues de ese ano eclesiastico
11. La duracion de cursado se cuenta por anos eclesiasticos desde `enrollments.ecclesiastical_year_id`
12. Antes de solicitar investidura, el backend exige respetar `min_duration_years` y `max_duration_years`
13. Si un enrollment supera la duracion maxima sin investidura, pasa formalmente a `EXPIRED` y conserva su progreso como trayectoria historica
14. Un consejero o secretario asignado a una clase puede ver el avance de miembros inscritos en esa clase, siempre que cumpla la elegibilidad de estar cursando o haber completado `Guía Mayor`.
15. La carga delegada de evidencias debe distinguir miembro objetivo (`:userId`) de actor autenticado (`currentUser.sub`).
16. Solo puede haber **una inscripción activa por usuario/año** (índice parcial `uniq_enrollments_active_user_year`); el servicio GM alineado lanza `CLASS_MAX_GM_ACTIVE` al intentar una segunda.
17. PATCH/upload/delete de progreso se rechazan con `CLASS_PROGRESS_LOCKED` si `locked_for_validation` o el enrollment está en estado terminal (`SUBMITTED`/`CLUB_APPROVED`/`COORDINATOR_APPROVED`/`FIELD_APPROVED`/`INVESTIDO`/`EXPIRED`). `IN_PROGRESS` y `REJECTED` permiten mutación.
18. Un requisito con evidencia `REJECTED` nunca computa como completo para progreso ni elegibilidad, aunque `score >= 70`.
19. El rechazo individual de evidencia de clase exige `SUBMITTED` (`EVIDENCE_REVIEW_RECORD_NOT_PENDING` en otro estado).

## Prerrequisitos entre clases

Tabla aditiva `class_prerequisites` (`class_id`, `prerequisite_class_id`, `active`). En inscripción, cada prerrequisito activo debe estar `INVESTIDO` para el usuario (cualquier año). Error: `CLASS_PREREQUISITE_NOT_MET` (403). `requires_invested_gm` sigue vigente y no se migra a esta tabla: la clase de entrada `Guía Mayor` debe tenerlo en `false` (primera inscripción GM sin investidura previa); `Guía Mayor Avanzado` e `Instructor` lo usan en `true`. Error: `CLASS_GM_INVESTITURE_REQUIRED` (403). Admin: `GET/POST/DELETE /admin/classes/:classId/prerequisites` con validación anti-ciclos (`ADMIN_CLASS_PREREQUISITE_CYCLE`).

## Especialidades relacionadas

`class_honors` activo en runtime (`REQUIRED` | `RECOMMENDED` | `ELECTIVE`), con `module_id` opcional que ancla la especialidad a un módulo de la misma clase. Relaciones **informativas**: no bloquean progreso de módulo ni investidura, incluso `REQUIRED`. Público: `GET /classes/:classId/honors` (`module_id`, `module_name`, `material_url`; JWT opcional agrega `user_status`). `GET /classes/:classId` y `GET /classes/:classId/modules` embeben `honors[]` por módulo (sin `user_status`). Admin: `GET/POST/PATCH/DELETE /admin/classes/:classId/honors` (`PATCH` asigna o limpia `module_id`). La app muestra todas las especialidades de la clase en el carrusel de sugerencias (aunque tengan módulo) y las repite dentro del módulo anclado; abre el PDF de `honors.material_url` e inscribe por `POST /users/:userId/honors`.

## Decisiones de diseno

- **Decision 9 (enrollments vs users_classes)**: la verdad operativa anual vive en `enrollments`; `users_classes` fue retirada y no participa más en el modelo operativo
- **Clase derivada en post-registro**: el cliente no decide libremente la clase; puede omitir `class_id` y el backend la asigna, o enviarlo solo como confirmacion. Si no coincide con la clase calculada por edad/tipo de club, se devuelve `POST_REG_CLASS_NOT_ELIGIBLE`.
- **Resolucion de enrollment**: el backend resuelve automaticamente una inscripcion activa del ano eclesiastico actual; enrollmentId es override aditivo
- **Dos controladores separados**: ClassesController (catalogo) y UserClassesController (inscripciones) con guards diferentes
- **PermissionsGuard con permisos finos**: los endpoints de progreso usan permisos de club vía `active_assignment`; las escrituras propias de `:userId` usan bypass owner explícito, y `ClassProgressAccessService` decide si el actor puede ver/modificar ese enrollment concreto (self, section-wide o asignación pedagógica activa).
- **Backfill acotado**: filas legacy de progress sin enrollment_id solo se backfillean si mapean deterministicamente a una unica inscripcion
- **Clases legacy por disponibilidad**: `available_until_year_id = null` significa sin vencimiento; no se usa ano sentinel tipo 2100
- **Duracion configurable por clase**: defaults `min_duration_years = 1` y `max_duration_years = 1`; Guia Mayor Avanzado/Instructor pueden extenderse por configuracion
- **Trayectoria inmutable**: `EXPIRED` impide continuar o solicitar investidura, pero no borra progreso ni historial
- **Asignación pedagógica separada**: `class_counselor_assignments` no reemplaza ni extiende `club_role_assignments`; evita mezclar cargo operativo, permisos y responsabilidad anual de una clase.

## Gaps y pendientes

- [RESUELTO] La frontera de autoridad entre enrollments y users_classes ha sido resuelta: `users_classes` fue retirada y `enrollments` es la única autoridad
- [RESUELTO] `/home/grouped-class` en app ya no abre una clase fija/propia: resuelve el alcance pedagógico por sección y luego el miembro objetivo.
- No hay proceso cron automatico para vencer enrollments; la primera iteracion usa proceso admin/manual auditable
- Reporteria historica de clases vencidas queda para iteracion posterior

## Prioridad y siguiente accion

- **Media**: Definir automatizacion futura (cron/job) para vencimiento de enrollments si el proceso manual demuestra estabilidad
- **Media**: Agregar reportes historicos de clases legacy/vencidas por campo local/club
- **Siguiente accion concreta**: Ejecutar el proceso manual de vencimiento con `dry_run` al cierre de cada ano eclesiastico antes de aplicar cambios

## Carga masiva por certificados OCR

Las clases aprobadas desde la carga masiva por certificado se aplican sobre `enrollments` y registran evento en `investiture_validation_history`. No se usa `users_classes` ni se crea una tabla paralela para clases importadas.

La aprobacion de Campo Local puede marcar el enrollment como `FIELD_APPROVED` usando la fecha de completado/certificacion detectada o corregida por el miembro. La UI de registros importados debe mostrar una vista simplificada del comprobante, separada del flujo normal de checklist/progreso.
