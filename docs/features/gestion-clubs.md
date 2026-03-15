# Gestion de Clubs (clubes, secciones, cargos)
Estado: IMPLEMENTADO

## Que existe (verificado contra codigo)
- **Backend**: ClubsModule — 13 endpoints (CRUD clubs, instances CRUD, members listing, role assignment). Controllers: ClubsController, ClubRolesController. Guards: JwtAuthGuard, PermissionsGuard, ClubRolesGuard.
- **Admin**: 3 pages funcionales (clubs list, clubs/new, clubs/[id]). CRUD completo de clubs. Gestion de instancias (crear, actualizar). Listado de miembros por instancia. Asignacion/revocacion de roles de club.
- **App**: 3 features relacionados — club (1 screen: ClubView), members (3 screens: MembersView, MemberProfileView, RoleAssignmentView), units (2 screens: UnitsListView, UnitDetailView). Consume endpoints de clubs, instances, members y role assignments.
- **DB**: clubs, club_adventurers, club_pathfinders, club_master_guilds, club_types, club_role_assignments, units, unit_members, enrollments

## Que define el canon
- Club es la entidad institucional raiz con identidad y continuidad (Decision 2)
- Seccion de club es la unidad operativa real; "instance" es termino tecnico relegado al runtime (Decision 5)
- Tipo de club clasifica; la seccion ejecuta (Decision 3)
- La pertenencia se interpreta mediante vinculacion contextual, no plana (Decision 4)
- Canon define jerarquia organizacional: pais > union > campo local > distrito > iglesia > club

## Gap
- Canon define vinculacion institucional con estados (activo, cerrado, suspendido, pendiente) y tipos (formativa, liderazgo, apoyo) — runtime actual solo tiene club_role_assignments sin esa granularidad
- Canon define trayectoria historica del miembro a traves de secciones — no hay estructura dedicada para preservar transiciones entre secciones
- App tiene units feature sin data layer propio (solo presentacion)

## Prioridad
- A definir por el desarrollador
