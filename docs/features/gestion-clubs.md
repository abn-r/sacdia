# Gestion de Clubs (clubes, secciones, cargos)

**Estado**: IMPLEMENTADO

## Descripcion de dominio

El club es la entidad organizacional raiz del sistema SACDIA. En la estructura de la Iglesia Adventista, cada iglesia local puede tener un club que opera una o mas secciones por tipo: Aventureros (ninos de 4-9 anos), Conquistadores (jovenes de 10-15 anos) y Guias Mayores (16+ anos). El club es la identidad institucional permanente; las secciones son las unidades operativas donde se ejecuta el programa formativo.

La jerarquia organizacional completa es: Pais > Union > Campo Local > Distrito > Iglesia > Club > Seccion de Club. Cada nivel tiene su propia entidad en la base de datos y la cadena determina la jurisdiccion administrativa. Los miembros pertenecen a secciones (no directamente al club) mediante asignaciones de rol (`club_role_assignments`) que son anuales (vinculadas a un ano eclesiastico).

Los roles de club (director, subdirector, secretario, tesorero, consejero, miembro) determinan las capacidades operativas de cada persona dentro de una seccion. Estos roles son diferentes de los roles globales del sistema (super_admin, admin, coordinator, user). Un usuario puede tener multiples roles en diferentes secciones y anos eclesiasticos simultaneamente.

Las unidades (`units`) son subdivisiones informales dentro de una seccion (tipicamente 6-8 miembros con un consejero), usadas para organizar actividades en grupos menores. Los enrollments registran la inscripcion anual operativa de cada miembro en una clase progresiva.

La asignacion de un consejero/secretario a una clase progresiva concreta vive en `class_counselor_assignments`: depende de un rol activo en la seccion, pero no forma parte del cargo operativo. Esto permite que un consejero tenga unidad y tambien clase a cargo sin mezclar permisos, cupos de roles y trayectoria pedagógica.

## Que existe (verificado contra codigo)

### Backend (ClubsModule)
- **Controllers**: `src/clubs/clubs.controller.ts` (ClubsController + ClubRolesController en mismo archivo)
- **Service**: `src/clubs/clubs.service.ts`
- **Guards**: JwtAuthGuard, PermissionsGuard, ClubRolesGuard
- **14 endpoints**:
  - `GET /api/v1/clubs` — Listar clubs
  - `POST /api/v1/clubs` — Crear club y, en la misma transaccion, una fila de `club_sections` por cada `club_types` activo. El body exige `enabled_club_type_ids` (minimo 1) para marcar cuales quedan `active=true`; el resto se crea inactivo.
  - `GET /api/v1/clubs/:clubId` — Obtener club por ID
  - `PATCH /api/v1/clubs/:clubId` — Actualizar ficha del club (roles: director, deputy-director, secretary, secretary-treasurer; permiso `clubs:update`)
  - `DELETE /api/v1/clubs/:clubId` — Desactivar club (roles: director)
  - `GET /api/v1/clubs/:clubId/sections` — Listar secciones (por defecto solo `active=true`; `?includeInactive=true` para gestion de director/admin). Sin columna `name`; el tipo viene en `club_types`.
  - `GET /api/v1/clubs/:clubId/sections/:sectionId` — Obtener seccion por ID
  - `POST /api/v1/clubs/:clubId/sections` — Camino residual para clubs pre-migracion si falta el tipo; 409 si el tipo ya existe. No acepta nombre propio.
  - `PATCH /api/v1/clubs/:clubId/sections/:sectionId` — Actualizar seccion; `active` es el unico switch de “este club opera esa seccion” (roles: director, deputy-director, secretary, secretary-treasurer)
  - `DELETE /api/v1/clubs/:clubId/sections/:sectionId` — Eliminar seccion (roles: director)
  - `GET /api/v1/clubs/:clubId/sections/:sectionId/members` — Listar miembros de la seccion con rol y clase anual activa (`current_class`) resuelta desde `enrollments`
  - `POST /api/v1/clubs/:clubId/sections/:sectionId/roles` — Asignar rol a miembro (roles: director, subdirector, secretary)
  - `POST /api/v1/clubs/:clubId/sections/:sectionId/director-assignment` — Asignación inicial de director operativo del año indicado
  - `POST /api/v1/clubs/:clubId/sections/:sectionId/director-designation` — Preelegir director de un año futuro (`director_succession_plans`); header `Idempotency-Key`; no crea CRA `designated`
  - `GET /api/v1/clubs/:clubId/sections/:sectionId/director-designation?yearId=` — Programación abierta del año pedido o `null`
  - `PATCH /api/v1/clubs/:clubId/sections/:sectionId/director-designation` — Reemplazar sucesor (`succession_id`, `version`, `successor_user_id`)
  - `DELETE /api/v1/clubs/:clubId/sections/:sectionId/director-designation` — Cancelar plan no activado (`successionId`, `version`)
  - `POST /api/v1/clubs/:clubId/sections/:sectionId/director-succession` — Destitucion del director en el **mismo** año que `current_assignment_id`
  - `GET /api/v1/clubs/:clubId/leadership` — Liderazgo operativo: solo `status=active` del año eclesiastico vigente
  - `PATCH /api/v1/club-roles/:assignmentId` — Actualizar asignacion de rol
  - `DELETE /api/v1/club-roles/:assignmentId` — Remover rol de miembro
  - `GET /api/v1/clubs/:clubId/sections/:sectionId/class-counselor-assignments` — Listar responsables pedagógicos por clase
  - `POST /api/v1/clubs/:clubId/sections/:sectionId/class-counselor-assignments` — Asignar consejero/secretario a clase
  - `PATCH /api/v1/class-counselor-assignments/:assignmentId` — Editar responsabilidad/excepción/fechas
  - `DELETE /api/v1/class-counselor-assignments/:assignmentId` — Revocar asignación pedagógica

### Admin
- **3 paginas funcionales**: clubs list, clubs/new, clubs/[id]
- CRUD completo de clubs
- Creacion de club con seleccion encadenada Campo Local > Distrito > Iglesia y checkboxes para habilitar tipos (Aventureros, Conquistadores, Guias Mayores). No hay input de nombre de seccion.
- Gestion de secciones desde el detalle del club: siempre las 3 cards del catalogo, con badge activo/inactivo y toggle `active`. No hay formulario de alta con nombre.
- Gestion de unidades por club/seccion, enviando `club_section_id` al backend
- Listado de miembros por seccion
- Perfil de miembro desde el listado de seccion: actores con lectura de miembros en su seccion activa pueden abrir el perfil basico, clases y honores si el usuario tiene asignacion activa o pendiente en esa misma seccion
- Asignacion y revocacion de roles de club
- Asignacion inicial de director por seccion cuando la seccion todavia no tiene director activo, visible para `super-admin`, `admin`, `director-lf` y `assistant-lf`
- Designacion de director del año siguiente (`DesignationBlock` en el tab de secciones): un bloque aparte del director operativo, copy “Designar director del próximo año”. Visible para `super-admin`, `admin`, `director-lf` y `assistant-lf`
- Destitucion del director **del año vigente** (`POST .../director-succession`): cierra esa asignacion y nombra otro director del **mismo** año. No usar este flujo para el nombramiento de diciembre / N+1

### App Movil
- **3 features relacionados**:
  - Club: 1 screen (ClubView) — informacion general del club contenedor y tipo de seccion (`{club.name} · {club_types.name}`); no se edita nombre propio de seccion
  - Members: 3 screens (MembersView, MemberProfileView, RoleAssignmentView) — listado y gestion de miembros
  - Units: 2 screens (UnitsListView, UnitDetailView) — gestion de unidades con data layer propio, miembros, registros semanales y categorias de scoring
- Consume endpoints de clubs, sections, members, role assignments, units y scoring-categories

### Base de datos
- `clubs` — Clubs contenedores (uno por iglesia)
- `club_sections` — Slots tipados del club (una fila por `club_type` activo). Sin nombre propio; `active` habilita o deshabilita el tipo. Consolidado de las antiguas tablas `club_adventurers`, `club_pathfinders`, `club_master_guilds` (Decision 10, 2026-03-17)
- `club_types` — Catalogo de tipos de club (Aventureros, Conquistadores, Guias Mayores)
- `club_role_assignments` — Asignaciones de roles a usuarios en secciones (anual)
- `class_counselor_assignments` — Asignaciones pedagógicas por usuario + sección + clase + año, vinculadas opcionalmente al `club_role_assignment` activo
- `role_slot_limits` — Limites maximos de asignaciones activas por rol y seccion
- `units` — Unidades dentro de secciones
- `unit_members` — Miembros asignados a unidades
- `enrollments` — Inscripciones anuales operativas

### Contrato de miembros por sección

El listado de miembros no debe inferir "Sin clase" desde la ausencia de datos en el cliente. El backend expone `current_class` por cada asignación activa de rol tomando la inscripción activa del año eclesiástico vigente y filtrándola por el `club_type_id` de la sección consultada. Si un miembro está inscrito en "Guía" de Conquistadores, la app y el panel deben renderizar esa clase en el grupo/ficha correspondiente.

## Requisitos funcionales

1. Debe ser posible crear clubs asociados a una iglesia
2. Al crear un club se generan siempre las filas de `club_types` activos (hoy Aventureros, Conquistadores, Guias Mayores). Los checkboxes solo marcan `club_sections.active`; al menos un tipo debe quedar habilitado.
3. La constraint unique `(main_club_id, club_type_id)` impide duplicar secciones del mismo tipo
4. Los miembros se vinculan a secciones mediante asignaciones de rol anuales
5. Los roles de club determinan los permisos operativos (quien puede crear actividades, gestionar finanzas, etc.)
6. Debe ser posible listar miembros de una seccion con sus roles activos
7. Debe ser posible abrir el perfil basico, clases y honores de miembros activos o solicitantes pendientes de la seccion activa sin exponer subrecursos sensibles por defecto
8. Las secciones deben registrar dias y horarios de reunion, cuota y meta de almas
9. El director del club es el unico que puede eliminar secciones y desactivar el club
10. Las asignaciones de rol deben estar vinculadas a un ano eclesiastico para mantener historico
11. Las unidades deben pertenecer a una seccion activa; sus miembros deben pertenecer a esa misma seccion
12. Una seccion no puede tener mas cargos activos que los definidos para la directiva: `director` 1, `deputy-director` 2, `secretary` 1, `treasurer` 1 y `secretary-treasurer` 1
13. `secretary-treasurer` es excluyente con `secretary` y `treasurer` separados dentro de la misma seccion
14. Una clase de la sección puede tener máximo 3 responsables pedagógicos activos por año: 1 principal y hasta 2 apoyos/suplentes.
15. Una persona puede tener hasta 2 clases activas en la misma sección/año; la segunda requiere marca de excepción y justificación.

## Decisiones de diseno

- **Club como identidad, seccion como slot tipado**: El club (`clubs.name`) es la identidad visible. Las secciones no tienen nombre propio; la etiqueta canonica es `{clubs.name} · {club_types.name}` (ej. `Panteras · Conquistadores`). Unirse, post-registro, camporee y QR solo usan secciones `active=true`. Directores y admin ven las tres para encender o apagar.
- **Consolidacion de secciones**: Las tres tablas originales (`club_adventurers`, `club_pathfinders`, `club_master_guilds`) se consolidaron en `club_sections` con un `club_type_id` discriminador (Decision 10)
- **Roles anuales**: Las asignaciones de rol tienen `ecclesiastical_year_id`, permitiendo que un miembro cambie de rol entre anos sin perder historico
- **Asignacion inicial de director**: para una seccion sin director operativo del año vigente, el Admin usa `POST /clubs/:clubId/sections/:sectionId/director-assignment`, que crea una asignacion `director` `status=active` para el usuario y **año eclesiástico vigente**. Un year distinto del vigente → 400 `CLUB_DIRECTOR_DESIGNATION_YEAR_INVALID`. Si ya existe director operativo de ese año, el backend rechaza el alta.
- **Preelección vs operativo**: Campo Local preelige al director del año **siguiente** con `POST /clubs/:clubId/sections/:sectionId/director-designation` (fila en `director_succession_plans`, no CRA `designated`). Año no futuro → 400 `CLUB_DIRECTOR_PLAN_YEAR_INVALID`. Eso **no** destituye al director del año vigente ni aparece en `/auth/me` ni invalida la caché del sucesor. `GET /clubs/:clubId/leadership` solo lista `status=active` del año eclesiastico vigente. En UI hay un solo bloque de director operativo; la programación se consulta por el GET restringido.
- **Destitucion (año vigente)**: `POST /clubs/:clubId/sections/:sectionId/director-succession` cierra `current_assignment_id` (`active=false`, `status=ended`, `end_date`) y crea un director `active` del **año vigente**. El year del body y el de la asignación deben coincidir con `getCurrentYear()`; si no → 400 `CLUB_DIRECTOR_DESIGNATION_YEAR_INVALID`. **No** es la herramienta de diciembre para N+1: para el próximo año usar designation. `assignRole` / `updateRoleAssignment` no pueden escribir `status=designated` ni mover un director a un año no vigente. Una fila `designated` legado no reconciliada rechaza cualquier mutación → 409 `CLUB_DIRECTOR_DESIGNATED_UNRECONCILED`.
- **Corte de año**: cron `5 6 * * *` UTC más `OnModuleInit` de recuperación, `job_name` `ecclesiastical-year-cut`. Unidad = club + año: lock `pg_advisory_xact_lock`, ledger `club_year_transitions`. Cierra cargos **vencidos por fecha** (`ecclesiastical_years.end_date < año vigente.start_date`) a `status=ended` con `end_date` = fin del periodo saliente (conserva un `end_date` anterior más temprano). Activa planes `scheduled` de `director_succession_plans` creando director `active`; **no** activa CRA `designated` legado. Junta AV/CQ retorna a GM como `member inactive` (política T1); consejero/member siguen no inscritos en **su** sección. No llama `closeYear`, no blacklistea JWT. Queda **un** director operativo visible por seccion. SQL del ledger/índices anuales puede existir solo en migraciones locales.
- **Limites de directiva**: `role_slot_limits` define los cupos por seccion y el backend tambien conserva fallback canonico para cargos criticos aunque falte el seed. La regla se aplica al crear asignaciones directas, al actualizar un rol y al revisar solicitudes de asignacion.
- **Contexto activo**: `users_pr.active_club_assignment_id` persiste el contexto de club activo del usuario, usado por `ClubRolesGuard` para resolver autorizacion
- **Autorizacion por jerarquia de roles**: Director y subdirector cubren la mayoria de escrituras; secretary y secretary-treasurer tambien editan la ficha del club (`clubs:update`) y la seccion (`club_sections:update`)
- **Cargo vs responsabilidad pedagógica**: `club_role_assignments` define el cargo en la sección; `class_counselor_assignments` define qué clase acompaña ese actor durante el año.

## Gaps y pendientes

- **Vinculacion institucional incompleta**: Canon define estados de vinculacion (activo, cerrado, suspendido, pendiente) y tipos (formativa, liderazgo, apoyo) — el runtime solo tiene `club_role_assignments` sin esa granularidad
- **Sin trayectoria historica**: Canon define preservar transiciones entre secciones — no hay estructura dedicada para historico de secciones
- **Trazabilidad historica de unidades**: No hay auditoria dedicada para cambios de unidad o movimientos entre unidades
- **Sin invitaciones**: No hay flujo para invitar miembros a un club/seccion; la vinculacion es manual
- **Transferencias parciales**: existe flujo de solicitudes de transferencia entre secciones; al aprobar, mueve la asignacion activa a la seccion destino del mismo tipo de club y conserva la clase anual actual. Aun falta auditoria dedicada de trayectoria historica de secciones.

## Prioridad y siguiente accion

- **Prioridad**: Baja — feature funcional en las tres capas; quedan mejoras de trazabilidad y vinculacion institucional
- **Siguiente accion**: Considerar agregar estados de vinculacion al modelo de `club_role_assignments` y auditoria de movimientos de unidades para alinearse con el canon.

## Plantilla anual de miembros

- **Plantilla anual**: La directiva vigente con `club_members:approve` en la **sección destino** lista e inscribe no inscritos del año eclesiástico vigente (`GET`/`POST /club-sections/:sectionId/annual-continuations`). Fuente: pertenencia actual no inscrita (`member inactive` + política T1), no el roster exclusivo del año pasado. Paginación `page`/`limit` y `search`. El dueño del perfil no autoriza el POST.
- **Activación**: POST activa la fila `member inactive` del año actual en esa sección y, en la misma transacción, matricula la siguiente clase del mismo tipo (`enrollment_id` en outcome `enrolled`). Si ya hay `member active` ahí, `already_enrolled`. Un cargo de director en otra sección no cuenta como inscrito aquí. No se copian cargos. Catálogo incompleto, tipo agotado o clase de otra sección: `blocked` `ANNUAL_CLASS_POLICY_UNRESOLVED` (D02; no se habilita cruce AV→CQ ni GM investido/multianual).
- **Fantasma (ghost)**: El corte no reescribe filas históricas a `inactive` para representar el año actual. Cargos vencidos quedan `ended`. La pertenencia actual no inscrita es una fila `member` `status=inactive` del año vigente (`AnnualMembershipPolicyService.ensureNotEnrolled`). Copy: "No inscrito este año. La directiva realiza tu inscripción".
- **Autoinscripción (D01 pendiente)**: `POST /users/:userId/membership/annual-enroll` responde **403** `ANNUAL_ENROLL_REQUIRES_DIRECTIVE` y no escribe nada. No convertir en `pending` de post-registro.
- **No se copian cargos**: La inscripción anual no sustituye un director operativo de la sección destino por `member`. El director del año siguiente se nombra vía designation (Campo Local) o succession (destitución año vigente).
