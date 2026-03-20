# Clases Progresivas

**Estado**: IMPLEMENTADO

## Descripcion de dominio

Las clases progresivas son el eje central del proceso formativo institucional en los clubes de Aventureros, Conquistadores y Guias Mayores. Representan un camino secuencial de avance donde cada miembro cursa una clase determinada por su edad al inicio del ano eclesiastico. Las clases de Conquistadores, por ejemplo, siguen la secuencia: Amigo, Companero, Explorador, Orientador, Viajero, Guia.

Cada clase se compone de modulos tematicos, y cada modulo contiene secciones evaluables. El progreso se registra por seccion (puntaje + evidencias) y se proyecta a nivel de modulo. La regla fundamental es que la clase se determina por la edad al inicio del ano eclesiastico y NO cambia durante ese ciclo — un miembro que cumple anos a mitad de ano sigue en su clase original.

El sistema mantiene una separacion critica entre dos conceptos: el **ciclo anual operativo** (gestionado por `enrollments`) y la **trayectoria consolidada** (gestionado por `users_classes`). La inscripcion anual en enrollments es la fuente de verdad para el progreso del ano en curso, mientras que users_classes mantiene el historico consolidado y la proyeccion legacy de compatibilidad.

La culminacion exitosa de una clase lleva a la investidura, que es el acto institucional de reconocimiento formal. Este flujo de validacion e investidura aun no tiene runtime implementado (ver feature `validacion-investiduras`).

## Que existe (verificado contra codigo)

### Backend (ClassesModule)
- **Controladores**: `ClassesController` (catalogo publico, 3 endpoints) + `UserClassesController` (inscripciones de usuario, 4 endpoints) = **7 endpoints totales**
- **Catalogo publico** (OptionalJwtAuthGuard):
  - `GET /classes` — listar clases con paginacion y filtro por clubTypeId
  - `GET /classes/:classId` — detalle de clase con modulos y secciones
  - `GET /classes/:classId/modules` — modulos de una clase con sus secciones
- **Inscripciones de usuario** (JwtAuthGuard + PermissionsGuard):
  - `GET /users/:userId/classes` — listar inscripciones del usuario (filtro por yearId)
  - `POST /users/:userId/classes/enroll` — inscribir usuario en clase (class_id + ecclesiastical_year_id)
  - `GET /users/:userId/classes/:classId/progress` — progreso anual (acepta ?enrollmentId= como override)
  - `PATCH /users/:userId/classes/:classId/progress` — actualizar progreso de seccion (module_id, section_id, score, evidences, enrollment_id opcional)
- **Servicio**: `ClassesService` con spec de tests
- **DTOs**: EnrollClassDto, UpdateProgressDto
- **Decoradores**: @RequirePermissions('classes:read'/'classes:update'), @AuthorizationResource({ type: 'user', ownerParam: 'userId' })

### Admin (sacdia-admin)
- 1 pagina read-only: listado de clases via ModuleListPage
- Consume: `GET /classes`, `GET /catalogs/club-types`
- Sin CRUD de clases ni gestion de progreso ni inscripciones

### App (sacdia-app)
- 6 screens: ClassesListView, ClassDetailView, ClassDetailWithProgressView, ClassModulesView, SectionDetailView, RequirementDetailView
- Consume 8 endpoints incluyendo listado, detalle, modulos, inscripcion, progreso y subida/borrado de archivos de evidencia

### Base de datos
- `classes` — catalogo de clases (class_id, name, club_type_id, order)
- `class_modules` — modulos por clase
- `class_sections` — secciones evaluables por modulo
- `enrollments` — inscripcion anual operativa (enrollment_id, user_id, class_id, ecclesiastical_year_id, investiture_status, active). UNIQUE: (user_id, class_id, ecclesiastical_year_id)
- `class_section_progress` — progreso por seccion con enrollment_id como owner anual. UNIQUE: (enrollment_id, module_id, section_id)
- `class_module_progress` — proyeccion de progreso por modulo. UNIQUE: (enrollment_id, module_id)
- `users_classes` — trayectoria consolidada legacy (user_id, class_id, current_class, investiture, date_investiture, certificate)

## Requisitos funcionales

1. El catalogo de clases debe ser consultable sin autenticacion (OptionalJwtAuthGuard)
2. Las clases deben filtrarse por tipo de club (Aventureros=1, Conquistadores=2, GM=3)
3. La inscripcion anual crea un enrollment unico por (user_id, class_id, ecclesiastical_year_id)
4. El progreso se resuelve contra una inscripcion anual unica del ano eclesiastico actual
5. Si la resolucion class-scoped es ambigua (multiples enrollments), la API responde 409 con ENROLLMENT_RESOLUTION_AMBIGUOUS
6. El progreso de seccion registra puntaje y evidencias (JSON)
7. El progreso de modulo se calcula como proyeccion sincronizada de sus secciones
8. Si el usuario cambia de clase en el mismo ano, el backend desactiva otros enrollments activos de ese ano

## Decisiones de diseno

- **Decision 9 (enrollments vs users_classes)**: la verdad operativa anual vive en `enrollments`; `users_classes` es solo proyeccion legacy de compatibilidad
- **Resolucion de enrollment**: el backend resuelve automaticamente una inscripcion activa del ano eclesiastico actual; enrollmentId es override aditivo
- **Dos controladores separados**: ClassesController (catalogo) y UserClassesController (inscripciones) con guards diferentes
- **PermissionsGuard con permisos finos**: classes:read y classes:update con AuthorizationResource para owner detection
- **Backfill acotado**: filas legacy de progress sin enrollment_id solo se backfillean si mapean deterministicamente a una unica inscripcion

## Gaps y pendientes

- La frontera de autoridad entre enrollments y users_classes no esta implementada de forma consistente (Decision 9 advierte cautela)
- App consume endpoints de archivos por seccion (POST/DELETE files) que **no aparecen en backend audit** — posibles endpoints FANTASMA o no capturados
- Admin es solo lectura — no permite gestionar inscripciones, progreso ni administrar clases
- `/home/grouped-class` en app tiene classId hardcodeado a 1
- No hay endpoint de administracion de clases (CRUD admin) — el catalogo se gestiona solo por base de datos directa
- No existe runtime de investidura ni validacion de completitud de clase

## Prioridad y siguiente accion

- **Alta**: Resolver los endpoints de archivos por seccion que la app consume (POST/DELETE files) — verificar si existen o implementar
- **Media**: Implementar gestion de clases en admin (al menos lectura enriquecida con progreso de miembros)
- **Siguiente accion concreta**: Auditar si los endpoints POST/DELETE files por seccion de la app existen en el backend o son FANTASMA, y alinear
