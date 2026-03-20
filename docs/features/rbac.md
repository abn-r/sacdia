# RBAC (Permisos y Roles)

**Estado**: IMPLEMENTADO

## Descripcion de dominio

El sistema RBAC (Role-Based Access Control) de SACDIA implementa un modelo de autorizacion en dos niveles: roles globales y roles de club. Los roles globales (`super_admin`, `admin`, `assistant_admin`, `coordinator`, `user`) controlan el acceso a funcionalidades administrativas del sistema completo. Los roles de club (`director`, `subdirector`, `secretary`, `treasurer`, `counselor`, `member`) controlan las operaciones dentro de cada seccion de club.

Los permisos siguen la convencion `resource:action` (ej: `users:read_detail`, `health:read`, `emergency_contacts:update`). El sistema permite asignar permisos a roles (tabla pivote `role_permissions`) y, excepcionalmente, permisos directos a usuarios (`users_permissions`). La cadena de autorizacion se resuelve en runtime mediante guards de NestJS que consultan los permisos efectivos del usuario autenticado.

El modulo RBAC esta disenado para ser administrado desde el panel admin, donde los administradores pueden gestionar permisos, ver roles con sus permisos asignados, y modificar la matriz de permisos. La app movil no tiene interfaz de RBAC pero consume el sistema implicitamente a traves de los guards que protegen cada endpoint.

El sistema incluye un mecanismo de permisos sensibles para sub-recursos de usuario (salud, contactos de emergencia, representante legal, post-registro) que coexisten con los permisos legacy de la familia `users:*` durante un periodo transicional.

## Que existe (verificado contra codigo)

### Backend (RbacModule)
- **Controller**: `src/rbac/rbac.controller.ts`
- **Guards utilizados en todo el sistema**:
  - `JwtAuthGuard` — Autenticacion JWT (en `src/common/guards/jwt-auth.guard.ts`)
  - `PermissionsGuard` — Verificacion de permisos globales (en `src/common/guards/permissions.guard.ts`)
  - `ClubRolesGuard` — Verificacion de roles de club (en `src/common/guards/club-roles.guard.ts`)
  - `GlobalRolesGuard` — Verificacion de roles globales (en `src/common/guards/global-roles.guard.ts`)
  - `OwnerOrAdminGuard` — Self-service o acceso admin (en `src/common/guards/owner-or-admin.guard.ts`)
  - `OptionalJwtAuthGuard` — JWT opcional (en `src/common/guards/optional-jwt-auth.guard.ts`)
  - `IpWhitelistGuard` — Restriccion por IP (en `src/common/guards/ip-whitelist.guard.ts`)
- **Decorators**:
  - `@Permissions()` — en `src/common/decorators/permissions.decorator.ts`
  - `@GlobalRoles()` — en `src/common/decorators/global-roles.decorator.ts`
  - `@ClubRoles()` — en `src/common/decorators/club-roles.decorator.ts`
  - `@CurrentUser()` — en `src/common/decorators/current-user.decorator.ts`
  - `@AuthorizationResource()` — en `src/common/decorators/authorization-resource.decorator.ts`
  - `@SensitiveUserSubresource()` — en `src/common/decorators/sensitive-user-subresource.decorator.ts`
- **Authorization Context Service**: `src/common/services/authorization-context.service.ts` — resuelve el contexto de autorizacion efectivo del actor
- **Sensitive Subresource Policy**: `src/common/guards/sensitive-user-subresource-policy.ts`
- **10 endpoints RBAC admin**:
  - `GET /api/v1/admin/rbac/permissions` — Listar todos los permisos (roles: super_admin, admin)
  - `GET /api/v1/admin/rbac/permissions/:id` — Obtener permiso por ID (roles: super_admin, admin)
  - `POST /api/v1/admin/rbac/permissions` — Crear permiso (roles: super_admin)
  - `PATCH /api/v1/admin/rbac/permissions/:id` — Actualizar permiso (roles: super_admin)
  - `DELETE /api/v1/admin/rbac/permissions/:id` — Desactivar permiso (roles: super_admin)
  - `GET /api/v1/admin/rbac/roles` — Listar roles con sus permisos (roles: super_admin, admin)
  - `GET /api/v1/admin/rbac/roles/:id` — Obtener rol con permisos (roles: super_admin, admin)
  - `POST /api/v1/admin/rbac/roles/:id/permissions` — Asignar permisos a rol (roles: super_admin)
  - `PUT /api/v1/admin/rbac/roles/:id/permissions` — Sincronizar permisos de rol (roles: super_admin)
  - `DELETE /api/v1/admin/rbac/roles/:id/permissions/:permissionId` — Remover permiso de rol (roles: super_admin)

### Admin
- **3 paginas funcionales**:
  - `rbac/permissions` — CRUD completo de permisos
  - `rbac/roles` — Listado de roles con asignacion de permisos
  - `rbac/matrix` — Matriz interactiva roles vs permisos
- Hub de navegacion en `/dashboard/rbac`
- Consume todos los endpoints del RbacModule

### App Movil
- **No tiene UI de RBAC** — La app consume el sistema de permisos implicitamente a traves de guards y decorators del backend

### Base de datos
- `roles` — Roles del sistema con `role_category` (GLOBAL | CLUB)
- `permissions` — Permisos con convencion `resource:action`
- `role_permissions` — Tabla pivote roles-permisos
- `users_roles` — Asignacion de roles globales a usuarios
- `users_permissions` — Permisos directos a usuarios (excepcional)

## Requisitos funcionales

1. Solo `super_admin` puede crear, actualizar y eliminar permisos
2. Solo `super_admin` puede asignar o remover permisos de roles
3. Los roles `super_admin` y `admin` pueden ver la lista completa de permisos y roles
4. El sistema debe distinguir entre roles globales (GLOBAL) y roles de club (CLUB)
5. Los permisos deben seguir la convencion `resource:action` en minusculas
6. La matriz interactiva debe permitir visualizar y modificar la relacion roles-permisos
7. El sincronizado de permisos (`PUT`) debe reemplazar todos los permisos de un rol atomicamente
8. Los permisos sensibles (health, emergency_contacts, legal_representative, post_registration) deben coexistir con permisos legacy `users:*` durante la transicion
9. El guard de autorizacion debe resolver self-service (owner) vs acceso administrativo (terceros con permiso)

## Decisiones de diseno

- **Dos categorias de roles**: `GLOBAL` para administracion del sistema, `CLUB` para operacion dentro de secciones
- **Guards como middleware**: La autorizacion se resuelve en la capa de guards de NestJS, no en la logica de negocio del servicio
- **Contexto de autorizacion**: `AuthorizationContextService` resuelve el actor, sus roles, permisos y el contexto de club activo para cada request
- **Permisos finos para sub-recursos sensibles**: `health:read`, `emergency_contacts:update`, etc. permiten granularidad mayor que el permiso legacy `users:read_detail`
- **OR transicional**: Para terceros, el sistema acepta el permiso fino O el fallback legacy `users:*` durante el periodo de transicion
- **Sync vs Assign**: `PUT` reemplaza todos los permisos (sync), `POST` agrega sin eliminar existentes (assign)

## Gaps y pendientes

- **Sin UI en app**: Correcto por diseno — la app no necesita interfaz de administracion de RBAC
- **Permisos directos a usuarios poco documentados**: La tabla `users_permissions` existe pero el workflow para asignar permisos directos no esta expuesto en admin
- **Sin auditoría de cambios**: No hay log de quien modifico la matriz de permisos y cuando
- **Transicion de permisos legacy**: El OR transicional entre permisos finos y `users:*` deberia tener fecha de sunset definida

## Prioridad y siguiente accion

- **Prioridad**: Baja — feature completamente funcional en backend y admin
- **Siguiente accion**: Definir fecha de sunset para el OR transicional de permisos legacy. Considerar agregar auditoría de cambios en la matriz de permisos.
