# Clases Progresivas

**Estado**: IMPLEMENTADO

## Descripcion de dominio

Las clases progresivas son el eje central del proceso formativo institucional en los clubes de Aventureros, Conquistadores y Guias Mayores. Representan un camino secuencial de avance donde cada miembro cursa una clase determinada por su edad al inicio del ano eclesiastico. Las clases de Conquistadores, por ejemplo, siguen la secuencia: Amigo, Companero, Explorador, Orientador, Viajero, Guia.

Cada clase se compone de modulos tematicos, y cada modulo contiene secciones evaluables. El progreso se registra por seccion (puntaje + evidencias) y se proyecta a nivel de modulo. La regla fundamental es que la clase se determina por la edad al inicio del ano eclesiastico y NO cambia durante ese ciclo — un miembro que cumple anos a mitad de ano sigue en su clase original. En post-registro, el backend deriva la clase esperada desde `users.birthday`, el inicio del ano eclesiastico activo, el `club_type_id` de la seccion seleccionada y `classes.minimum_age`; si el cliente envia un `class_id` que no coincide, la API lo rechaza.

El sistema adopta una única fuente de verdad: el **ciclo anual operativo** es gestionado enteramente por `enrollments` con sus proyecciones de progreso (`class_module_progress`, `class_section_progress`). La tabla legacy `users_classes` fue retirada del schema actual y ya no participa en el modelo operativo. El histórico consolidado se consulta directamente desde `enrollments` con filtros históricos por año eclesiástico.

La culminacion exitosa de una clase lleva a la investidura, que es el acto institucional de reconocimiento formal. El flujo de validacion e investidura ya existe y ahora valida tambien la ventana de disponibilidad de la clase y su duracion minima/maxima por ano eclesiastico (ver feature `validacion-investiduras`).

## Que existe (verificado contra codigo)

### Backend (ClassesModule)
- **Controladores**: `ClassesController` (catalogo publico, progreso/evidencias e inscripciones) + `AdminPhaseECatalogsController` (CRUD admin de clases) + `InvestitureController` (vencimiento manual de enrollments atrasados)
- **Catalogo publico** (OptionalJwtAuthGuard):
  - `GET /classes` — listar clases con paginacion y filtro por clubTypeId; por defecto solo devuelve clases disponibles para inscripcion en el ano eclesiastico vigente
  - `GET /classes/:classId` — detalle de clase con modulos y secciones
  - `GET /classes/:classId/modules` — modulos de una clase con sus secciones
- **Inscripciones de usuario** (JwtAuthGuard + PermissionsGuard):
  - `GET /users/:userId/classes` — listar inscripciones del usuario (filtro por yearId)
  - `POST /users/:userId/classes/enroll` — inscribir usuario en clase (class_id + ecclesiastical_year_id); bloquea clases inactivas o fuera de ventana de disponibilidad
  - `GET /users/:userId/classes/:classId/progress` — progreso anual (acepta ?enrollmentId= como override)
  - `PATCH /users/:userId/classes/:classId/progress` — actualizar progreso de seccion (module_id, section_id, score, evidences, enrollment_id opcional)
- **Servicio**: `ClassesService` con spec de tests
- **DTOs**: EnrollClassDto, UpdateProgressDto
- **Decoradores**: @RequirePermissions('classes:read'/'classes:update'), @AuthorizationResource({ type: 'user', ownerParam: 'userId' })

### Admin (sacdia-admin)
- CRUD de clases activo desde catalogos/admin, incluyendo traducciones, disponibilidad por ano eclesiastico y duracion minima/maxima.
- Consume `GET|POST|PATCH|DELETE /admin/classes` para administrar el catalogo.
- Incluye proceso manual auditable para vencer enrollments atrasados: primero `dry_run`, luego confirmacion explicita antes de aplicar `POST /admin/classes/enrollments/expire-overdue`.
- No gestiona progreso operativo de miembros desde el CRUD de catalogos.

### App (sacdia-app)
- 6 screens: ClassesListView, ClassDetailView, ClassDetailWithProgressView, ClassModulesView, SectionDetailView, RequirementDetailView
- Consume 8 endpoints incluyendo listado, detalle, modulos, inscripcion, progreso y subida/borrado de archivos de evidencia

### Base de datos
- `classes` — catalogo de clases (class_id, name, club_type_id, order) con `available_from_year_id`, `available_until_year_id`, `min_duration_years`, `max_duration_years`
- `class_modules` — modulos por clase
- `class_sections` — secciones evaluables por modulo
- `enrollments` — inscripcion anual operativa (enrollment_id, user_id, class_id, ecclesiastical_year_id, investiture_status, active). UNIQUE: (user_id, class_id, ecclesiastical_year_id). El estado `EXPIRED` preserva progreso historico cuando la duracion maxima ya vencio.
- `class_section_progress` — progreso por seccion con enrollment_id como owner anual. UNIQUE: (enrollment_id, module_id, section_id)
- `class_module_progress` — proyeccion de progreso por modulo. UNIQUE: (enrollment_id, module_id)
- `users_classes` — [RETIRADA] trayectoria consolidada legacy; no existe en el schema runtime actual

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

## Decisiones de diseno

- **Decision 9 (enrollments vs users_classes)**: la verdad operativa anual vive en `enrollments`; `users_classes` fue retirada y no participa más en el modelo operativo
- **Clase derivada en post-registro**: el cliente no decide libremente la clase; puede omitir `class_id` y el backend la asigna, o enviarlo solo como confirmacion. Si no coincide con la clase calculada por edad/tipo de club, se devuelve `POST_REG_CLASS_NOT_ELIGIBLE`.
- **Resolucion de enrollment**: el backend resuelve automaticamente una inscripcion activa del ano eclesiastico actual; enrollmentId es override aditivo
- **Dos controladores separados**: ClassesController (catalogo) y UserClassesController (inscripciones) con guards diferentes
- **PermissionsGuard con permisos finos**: classes:read y classes:update con AuthorizationResource para owner detection
- **Backfill acotado**: filas legacy de progress sin enrollment_id solo se backfillean si mapean deterministicamente a una unica inscripcion
- **Clases legacy por disponibilidad**: `available_until_year_id = null` significa sin vencimiento; no se usa ano sentinel tipo 2100
- **Duracion configurable por clase**: defaults `min_duration_years = 1` y `max_duration_years = 1`; Guia Mayor Avanzado/Instructor pueden extenderse por configuracion
- **Trayectoria inmutable**: `EXPIRED` impide continuar o solicitar investidura, pero no borra progreso ni historial

## Gaps y pendientes

- [RESUELTO] La frontera de autoridad entre enrollments y users_classes ha sido resuelta: `users_classes` fue retirada y `enrollments` es la única autoridad
- `/home/grouped-class` en app tiene classId hardcodeado a 1
- No hay proceso cron automatico para vencer enrollments; la primera iteracion usa proceso admin/manual auditable
- Reporteria historica de clases vencidas queda para iteracion posterior

## Prioridad y siguiente accion

- **Media**: Definir automatizacion futura (cron/job) para vencimiento de enrollments si el proceso manual demuestra estabilidad
- **Media**: Agregar reportes historicos de clases legacy/vencidas por campo local/club
- **Siguiente accion concreta**: Ejecutar el proceso manual de vencimiento con `dry_run` al cierre de cada ano eclesiastico antes de aplicar cambios

## Carga masiva por certificados OCR

Las clases aprobadas desde la carga masiva por certificado se aplican sobre `enrollments` y registran evento en `investiture_validation_history`. No se usa `users_classes` ni se crea una tabla paralela para clases importadas.

La aprobacion de Campo Local puede marcar el enrollment como `FIELD_APPROVED` usando la fecha de completado/certificacion detectada o corregida por el miembro. La UI de registros importados debe mostrar una vista simplificada del comprobante, separada del flujo normal de checklist/progreso.
