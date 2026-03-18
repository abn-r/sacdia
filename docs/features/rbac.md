# RBAC (Permisos y Roles)
Estado: IMPLEMENTADO

## Que existe (verificado contra codigo)
- **Backend**: RbacModule — 10 endpoints (CRUD permissions, list roles with permissions, role detail, assign permissions to role, sync permissions, remove permission from role). Controller: RbacController. Guards: JwtAuthGuard, PermissionsGuard.
- **Admin**: 3 pages funcionales (rbac/permissions con CRUD completo, rbac/roles con listado y asignacion de permisos, rbac/matrix con matriz interactiva roles vs permisos). Hub de navegacion en /dashboard/rbac. Consume todos los endpoints del RbacModule.
- **App**: No implementado. No hay screens de RBAC. La app consume permisos implicitamente a traves del sistema de autorizacion (guards, decorators).
- **DB**: permissions, roles, role_permissions, users_roles, users_permissions

## Que define el canon
- Canon auth/ define modelo de autorizacion con roles globales y roles de club
- Canon runtime-auth.md documenta guards, decorators y politicas de autorizacion
- Canon define role_category enum (GLOBAL, CLUB) para distinguir tipos de roles

## Gap
- Sin gaps detectados — backend y admin implementan CRUD completo, app no necesita UI de RBAC

## Prioridad
- A definir por el desarrollador
