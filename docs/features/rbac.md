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

## Permisos sensibles por sub-recurso de usuario

El sistema RBAC implementa permisos finos (fine-grained) para 4 familias de sub-recursos sensibles de `user`. Cada familia tiene un par de permisos `read`/`update` que coexisten con los permisos legacy `users:*` mediante un OR transicional.

### Tabla completa de permisos sensibles

| Familia | Permiso fino | Fallback legacy | Endpoints afectados |
| --- | --- | --- | --- |
| `health` | `health:read` | `users:read_detail` | `GET /users/:userId/allergies`, `GET /users/:userId/diseases`, `GET /users/:userId/medicines` |
| `health` | `health:update` | `users:update` | `PUT /users/:userId/allergies`, `PUT /users/:userId/diseases`, `PUT /users/:userId/medicines`, `DELETE` item-level |
| `emergency_contacts` | `emergency_contacts:read` | `users:read_detail` | `GET /users/:userId/emergency-contacts` |
| `emergency_contacts` | `emergency_contacts:update` | `users:update` | `POST/PATCH/DELETE /users/:userId/emergency-contacts` |
| `legal_representative` | `legal_representative:read` | `users:read_detail` | `GET /users/:userId/legal-representative` |
| `legal_representative` | `legal_representative:update` | `users:update` | `POST/PATCH/DELETE /users/:userId/legal-representative` |
| `post_registration` | `post_registration:read` | `users:read_detail` | `GET /users/:userId/post-registration/status` |
| `post_registration` | `registration:complete` | _(sin fallback)_ | `POST /users/:userId/post-registration/step-{1,2,3}/complete` |

> **Nota**: `registration:complete` es un permiso global dedicado asignado a roles de campo (super_admin, admin, assistant-lf, director-lf y equivalentes union/dia por herencia). No usa fallback a `users:update`. El owner siempre puede completar su propio registro sin este permiso.

### Reglas de autorizacion

1. **Owner bypass (self-service)**: El propietario del `userId` tiene acceso completo a sus propios sub-recursos sin necesidad de permisos globales explícitos
2. **Terceros**: Solo se evaluan permisos globales. Se acepta el permiso fino **O** el fallback legacy (OR transicional). Excepcion: `registration:complete` no tiene fallback legacy
3. **Permisos de club no aplican**: Los permisos provenientes unicamente de `authorization.active_assignment` no habilitan acceso transversal a recursos `user`

### Pruning administrativo

El endpoint `GET /api/v1/admin/users/:userId` poda automaticamente los bloques sensibles de la respuesta segun los permisos del actor que realiza la consulta. Cada bloque (`health`, `emergency_contacts`, `legal_representative`, `post_registration`) se incluye en la respuesta **solo si** el actor tiene el permiso fino `family:read` o el fallback legacy `users:read_detail`.

> Referencia completa: [`docs/api/SECURITY-GUIDE.md`](../api/SECURITY-GUIDE.md) — seccion "Pruning administrativo"

### Exclusiones (fuera de scope del tiering fino)

Las siguientes rutas de `user` permanecen bajo permisos legacy `users:*` y no forman parte del sistema de permisos finos:

- `GET/PATCH /users/:userId`
- `POST/DELETE /users/:userId/profile-picture`
- `GET /users/:userId/age`
- `GET /users/:userId/requires-legal-representative`

### Referencias cruzadas

- **Implementacion de seguridad completa**: [`docs/api/SECURITY-GUIDE.md`](../api/SECURITY-GUIDE.md)
- **Endpoints live reference**: [`docs/api/ENDPOINTS-LIVE-REFERENCE.md`](../api/ENDPOINTS-LIVE-REFERENCE.md)
- **Guard de policy**: `src/common/guards/sensitive-user-subresource-policy.ts`
- **Decorator de metadata**: `src/common/decorators/sensitive-user-subresource.decorator.ts`

## Gaps y pendientes

- **Sin UI en app**: Correcto por diseno — la app no necesita interfaz de administracion de RBAC
- **Permisos directos a usuarios poco documentados**: La tabla `users_permissions` existe pero el workflow para asignar permisos directos no esta expuesto en admin
- **Sin auditoría de cambios**: No hay log de quien modifico la matriz de permisos y cuando
- **Transicion de permisos legacy**: El OR transicional entre permisos finos y `users:*` deberia tener fecha de sunset definida

## Prioridad y siguiente accion

- **Prioridad**: Baja — feature completamente funcional en backend y admin
- **Siguiente accion**: Definir fecha de sunset para el OR transicional de permisos legacy. Considerar agregar auditoría de cambios en la matriz de permisos.
