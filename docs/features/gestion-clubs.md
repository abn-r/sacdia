# Gestion de Clubs (clubes, secciones, cargos)

**Estado**: IMPLEMENTADO

## Descripcion de dominio

El club es la entidad organizacional raiz del sistema SACDIA. En la estructura de la Iglesia Adventista, cada iglesia local puede tener un club que opera una o mas secciones por tipo: Aventureros (ninos de 6-9 anos), Conquistadores (jovenes de 10-15 anos) y Guias Mayores (16+ anos). El club es la identidad institucional permanente; las secciones son las unidades operativas donde se ejecuta el programa formativo.

La jerarquia organizacional completa es: Pais > Union > Campo Local > Distrito > Iglesia > Club > Seccion de Club. Cada nivel tiene su propia entidad en la base de datos y la cadena determina la jurisdiccion administrativa. Los miembros pertenecen a secciones (no directamente al club) mediante asignaciones de rol (`club_role_assignments`) que son anuales (vinculadas a un ano eclesiastico).

Los roles de club (director, subdirector, secretario, tesorero, consejero, miembro) determinan las capacidades operativas de cada persona dentro de una seccion. Estos roles son diferentes de los roles globales del sistema (super_admin, admin, coordinator, user). Un usuario puede tener multiples roles en diferentes secciones y anos eclesiasticos simultaneamente.

Las unidades (`units`) son subdivisiones informales dentro de una seccion (tipicamente 6-8 miembros con un consejero), usadas para organizar actividades en grupos menores. Los enrollments registran la inscripcion anual operativa de cada miembro en una clase progresiva.

## Que existe (verificado contra codigo)

### Backend (ClubsModule)
- **Controllers**: `src/clubs/clubs.controller.ts` (ClubsController + ClubRolesController en mismo archivo)
- **Service**: `src/clubs/clubs.service.ts`
- **Guards**: JwtAuthGuard, PermissionsGuard, ClubRolesGuard
- **14 endpoints**:
  - `GET /api/v1/clubs` — Listar clubs
  - `POST /api/v1/clubs` — Crear nuevo club
  - `GET /api/v1/clubs/:clubId` — Obtener club por ID
  - `PATCH /api/v1/clubs/:clubId` — Actualizar club (roles: director, subdirector)
  - `DELETE /api/v1/clubs/:clubId` — Desactivar club (roles: director)
  - `GET /api/v1/clubs/:clubId/sections` — Listar secciones del club
  - `GET /api/v1/clubs/:clubId/sections/:sectionId` — Obtener seccion por ID
  - `POST /api/v1/clubs/:clubId/sections` — Crear seccion (roles: director, subdirector)
  - `PATCH /api/v1/clubs/:clubId/sections/:sectionId` — Actualizar seccion (roles: director, subdirector, secretary)
  - `DELETE /api/v1/clubs/:clubId/sections/:sectionId` — Eliminar seccion (roles: director)
  - `GET /api/v1/clubs/:clubId/sections/:sectionId/members` — Listar miembros de la seccion
  - `POST /api/v1/clubs/:clubId/sections/:sectionId/roles` — Asignar rol a miembro (roles: director, subdirector, secretary)
  - `PATCH /api/v1/club-roles/:assignmentId` — Actualizar asignacion de rol
  - `DELETE /api/v1/club-roles/:assignmentId` — Remover rol de miembro

### Admin
- **3 paginas funcionales**: clubs list, clubs/new, clubs/[id]
- CRUD completo de clubs
- Gestion de secciones (crear, actualizar, eliminar)
- Listado de miembros por seccion
- Asignacion y revocacion de roles de club

### App Movil
- **3 features relacionados**:
  - Club: 1 screen (ClubView) — informacion general del club
  - Members: 3 screens (MembersView, MemberProfileView, RoleAssignmentView) — listado y gestion de miembros
  - Units: 2 screens (UnitsListView, UnitDetailView) — gestion de unidades (solo presentacion, sin data layer propio)
- Consume endpoints de clubs, sections, members y role assignments

### Base de datos
- `clubs` — Clubs contenedores (uno por iglesia)
- `club_sections` — Secciones de club (unidad operativa por tipo), consolidado de las antiguas tablas `club_adventurers`, `club_pathfinders`, `club_master_guilds` (Decision 10, 2026-03-17)
- `club_types` — Catalogo de tipos de club (Aventureros, Conquistadores, Guias Mayores)
- `club_role_assignments` — Asignaciones de roles a usuarios en secciones (anual)
- `units` — Unidades dentro de secciones
- `unit_members` — Miembros asignados a unidades
- `enrollments` — Inscripciones anuales operativas

## Requisitos funcionales

1. Debe ser posible crear clubs asociados a una iglesia
2. Cada club puede tener multiples secciones, una por tipo de club (Aventureros, Conquistadores, Guias Mayores)
3. La constraint unique `(main_club_id, club_type_id)` impide duplicar secciones del mismo tipo
4. Los miembros se vinculan a secciones mediante asignaciones de rol anuales
5. Los roles de club determinan los permisos operativos (quien puede crear actividades, gestionar finanzas, etc.)
6. Debe ser posible listar miembros de una seccion con sus roles activos
7. Las secciones deben registrar dias y horarios de reunion, cuota y meta de almas
8. El director del club es el unico que puede eliminar secciones y desactivar el club
9. Las asignaciones de rol deben estar vinculadas a un ano eclesiastico para mantener historico

## Decisiones de diseno

- **Club como identidad, seccion como operacion**: El club es la entidad permanente; las secciones son las que ejecutan el programa (Decision 2 y 3 del canon)
- **Consolidacion de secciones**: Las tres tablas originales (`club_adventurers`, `club_pathfinders`, `club_master_guilds`) se consolidaron en `club_sections` con un `club_type_id` discriminador (Decision 10)
- **Roles anuales**: Las asignaciones de rol tienen `ecclesiastical_year_id`, permitiendo que un miembro cambie de rol entre anos sin perder historico
- **Contexto activo**: `users_pr.active_club_assignment_id` persiste el contexto de club activo del usuario, usado por `ClubRolesGuard` para resolver autorizacion
- **Autorizacion por jerarquia de roles**: Director tiene todos los permisos; subdirector la mayoria; secretary puede gestionar roles y secciones

## Gaps y pendientes

- **Vinculacion institucional incompleta**: Canon define estados de vinculacion (activo, cerrado, suspendido, pendiente) y tipos (formativa, liderazgo, apoyo) — el runtime solo tiene `club_role_assignments` sin esa granularidad
- **Sin trayectoria historica**: Canon define preservar transiciones entre secciones — no hay estructura dedicada para historico de secciones
- **Units sin data layer en app**: El feature de unidades en la app es solo presentacion, sin endpoints propios ni logica de datos
- **Sin invitaciones**: No hay flujo para invitar miembros a un club/seccion; la vinculacion es manual
- **Sin transferencias**: No hay proceso para transferir un miembro entre clubes o secciones de forma trazable

## Prioridad y siguiente accion

- **Prioridad**: Baja — feature completamente funcional en las tres capas
- **Siguiente accion**: Implementar data layer para units en la app. Considerar agregar estados de vinculacion al modelo de `club_role_assignments` para alinearse con el canon.
