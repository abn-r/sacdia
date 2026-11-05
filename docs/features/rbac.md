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
  - `GlobalJwtAuthGuard` — `APP_GUARD`: JWT por defecto salvo `@Public()` (en `src/common/guards/global-jwt-auth.guard.ts`)
  - `JwtAuthGuard` — Autenticacion JWT explicita por controller (en `src/common/guards/jwt-auth.guard.ts`)
  - `PermissionsGuard` — `APP_GUARD` fail-closed (en `src/common/guards/permissions.guard.ts`); desde la fase 4 (2026-11-04) despacha el scope de recurso a las policies de `src/common/authorization/policies/`
  - `ClubRolesGuard` — Verificacion de roles de club (en `src/common/guards/club-roles.guard.ts`)
  - `GlobalRolesGuard` — Verificacion de roles globales (en `src/common/guards/global-roles.guard.ts`); expande alias (`GLOBAL_ROLE_ALIASES`, generado) salvo cuando el handler lleva `@ExactGlobalRoles`
  - `OwnerOrAdminGuard` — Self-service o acceso admin (en `src/common/guards/owner-or-admin.guard.ts`)
  - `OptionalJwtAuthGuard` — JWT opcional (en `src/common/guards/optional-jwt-auth.guard.ts`)
- **Decorators**:
  - `@Permissions()` — en `src/common/decorators/permissions.decorator.ts`
  - `@GlobalRoles()` — en `src/common/decorators/global-roles.decorator.ts`
  - `@ExactGlobalRoles()` — roles globales sin expansión de alias (`EXACT_GLOBAL_ROLES_KEY`; fase 6, 2026-11-04). Ver «Literales de rol y `@ExactGlobalRoles`»
  - `@ClubRoles()` — en `src/common/decorators/club-roles.decorator.ts`
  - `@CurrentUser()` — en `src/common/decorators/current-user.decorator.ts`
  - `@AuthorizationResource()` — en `src/common/decorators/authorization-resource.decorator.ts`
  - `@SensitiveUserSubresource()` — en `src/common/decorators/sensitive-user-subresource.decorator.ts`
  - `@SkipPermissions()` — opt-out explicito del `PermissionsGuard` global (`src/common/decorators/skip-permissions.decorator.ts`)
- **Authorization Context Service**: `src/common/services/authorization-context.service.ts` — resuelve el contexto de autorizacion efectivo del actor
- **Sensitive Subresource Policy**: `src/common/guards/sensitive-user-subresource-policy.ts`
- **19 endpoints RBAC admin** (`src/rbac/rbac.controller.ts`, más `POST /admin/rbac/bootstrap-admin`, público y protegido por `x-bootstrap-secret`). Todos exigen JWT; el rol global solo existe donde se indica `@GlobalRoles`, el resto depende del permiso:
  - `GET /api/v1/admin/rbac/permissions`, `GET .../permissions/:id` — Listar/obtener permisos (`permissions:read`)
  - `POST /api/v1/admin/rbac/permissions`, `PATCH`/`DELETE .../permissions/:id` — Crear/actualizar/desactivar permiso (`@GlobalRoles('super-admin')` + `permissions:assign`)
  - `GET /api/v1/admin/rbac/roles`, `GET .../roles/:id` — Listar/obtener roles con sus permisos (`roles:read`)
  - `POST /api/v1/admin/rbac/roles`, `PATCH`/`DELETE .../roles/:id` — Crear/actualizar/desactivar rol (`super-admin` + `permissions:assign`)
  - `POST` / `PUT .../roles/:id/permissions`, `DELETE .../roles/:id/permissions/:permissionId` — Asignar, sincronizar o remover permisos de un rol (`super-admin` + `permissions:assign`)
  - `GET .../users/:userId/permissions` — Permisos directos de un usuario (`permissions:read`)
  - `POST .../users/:userId/permissions`, `DELETE .../users/:userId/permissions/:permissionId` — Grants directos (`super-admin` + `permissions:assign`)
  - `GET .../users/:userId/roles` — Roles globales de un usuario (`@GlobalRoles('admin', 'super-admin')` + `roles:read`)
  - `POST .../users/:userId/roles`, `DELETE .../users/:userId/roles/:roleId` — Asignar/revocar rol global (`@GlobalRoles('super-admin')` + `permissions:assign`; ver «Roles globales de usuario»)

### Admin
- **Paginas de RBAC** (bajo Configuracion; ya no existe el hub `/dashboard/rbac`):
  - `/dashboard/configuration/permissions` — CRUD completo de permisos
  - `/dashboard/configuration/roles` (+ `/new`, `/[roleId]`) — Roles con asignacion de permisos
  - `/dashboard/configuration/matrix` — Matriz interactiva roles vs permisos
  - `/dashboard/rbac/user-permissions` — Permisos directos por usuario
- Consume todos los endpoints del RbacModule
- La matriz, el listado de roles y el selector de permisos muestran **etiquetas localizadas** (`rbac.permissions.*` / `rbac.permissionGroups.*`) y dejan la clave técnica `resource:action` como texto secundario. La descripción en inglés de la DB no es la etiqueta de UI.
- Selector de permisos del rol (2026-09-17): agrupa por pantalla del catálogo, no por prefijo API. Filtro de superficie Panel / App / Compartidos (misma clave, un grant; chips si la clave vive en ambas). Dentro de cada pantalla: Ver / Alta y rutas / Acciones / Datos sensibles / Borrar. El check del grupo no marca sensibles ni delete. La clave `resource:action` queda en tooltip.
- Super-admin puede copiar permisos de un rol a otro en `/dashboard/configuration/roles` (reemplazo total via `PUT /admin/rbac/roles/:id/permissions`). No se copia desde ni hacia `super-admin`.
- El sidebar filtra por `authorization.effective.permissions` y, cuando el backend declara `@GlobalRoles`, también por roles globales. Ejemplo: editores `/dashboard/catalogs/*` (salvo certificaciones) requieren `admin`/`super-admin`; `catalogs:read` no alcanza.
- El `viewAny` de cada hoja del menú es el permiso (y rol) del GET o acción principal que hace usable esa pantalla. No se mezclan permisos parientes en OR (`classes:read` no abre investidura). Un ítem de sidebar sin mapa se oculta (fail-closed). Las pestañas de una misma ruta se ocultan si el actor no puede cargar ese tab.
- **Screen Capability Catalog** (`sacdia-admin/src/lib/auth/screen-catalog/`, 2026-09-15): un solo registro por pantalla (`id` = id del sidebar) con `viewAny` y una lista de capabilities (`button` / `tab` / `route` / `section`), cada una con `gate` = espejo literal de `@RequirePermissions` + `@GlobalRoles` del endpoint. Lo leen el sidebar (`filterSidebarItems`), el gate de página (`canAccessDashboardPath`: ruta exacta de capability → path de pantalla → prefijo más largo → fail-closed), botones y pages (`canCapability(user, screenId, capId)` puro; `useScreenAccess()` en cliente), y las superficies RBAC (picker y matriz agrupan por pantalla; "Pantalla completa" y cascadas `viewAny`↔verbos van en un solo `PUT /rbac/roles/:id/permissions` vía `setRolePermissionsAction`). Los roles del gate se expanden con la misma tabla de alias que `GlobalRolesGuard` (`screen-catalog/role-aliases.ts`; desde 2026-11-04 toma `GLOBAL_ROLE_ALIASES` del catálogo generado `src/lib/auth/generated/`, ver «Catálogo de autorización generado»). Reemplaza `NAV_ITEM_ACCESS`, `EXTRA_PATH_ACCESS`, `useCanManageUsers` y las listas `ALLOWED_PAGE_ROLES`. Tests de cierre: ids únicos, cada hoja del sidebar tiene pantalla, claves ⊆ `permissions.ts` y ⊆ seeds/migraciones del backend. Pantalla Usuarios cableada (toolbar, `/users/new`, `/users/bulk-upload`, ficha: MFA y familias sensibles). La card **Accesos** de la pestaña Roles (`access_app` / `access_panel` / `active`) usa `users.update_admin` (`admin`/`super-admin` + `users:update_admin`); directores de campo no la ven. Diseño: `docs/history/plans/2026-09-15-admin-screen-capability-catalog-design.md`.
- Oleada 2 (mismo día): gates `exactRoles` para reglas de servicio con comparación literal (`clubs.designate_director` ↔ `ALLOWED_DESIGNATION_ROLES`); capabilities `manage`/`write` de `/configuration/{roles,permissions,matrix}` y `user_grants` = `permissions:assign` + `@GlobalRoles('super-admin')` de `RbacController`; todas las pages de configuración, `clubs/[id]` y el action de designación usan `canCapability`/`canViewScreen` en vez de `extractRoles(...).includes(SUPER_ADMIN_ROLE)`. `director-succession.ts` y `PERMISSION_GROUPS` eliminados. Reglas que **no** son espejo de decorador se dejan fuera del catálogo a propósito (confirmación de unión en carpetas anuales, variante de vista del pipeline). `clubs.succeed_director` (2026-09-15) sí entra: misma lista literal que el servicio (`super-admin`/`admin`/`director-lf`/`assistant-lf`) + `club_roles:assign` y `club_roles:revoke`.
- Oleada 2, materiales y camporees: capabilities por verbo en `materials-*`, `admin-local-field-*`, `campamentos-*`, `catalogs-camporee-event-types`; 13 pages y 6 componentes de camporees/materiales usan `canCapability`/`canViewScreen`. Espejo estricto del API: eventos exigen `camporee_events:*` (no `camporees:*`), tipos de evento `camporee_event_types:*` + rol admin (no `catalogs:*`), bandeja de recibos entra con `materiales:validate-receipt`. Detalle en el plan.
- Oleada 2c (2026-09-15): asignar jueces usa `canCapability(..., camporeeScreenId(kind), "events.update")` = `camporee_events:update` (mismo gate que `POST/PATCH/DELETE` de `camporee-scoring.controller.ts`). Se eliminó `canManageCamporeeJudgeAssignments` (OR con `camporees:update` y fallback por rol).
- **Reglas fuera del catálogo** — entra al catálogo solo lo que copia un decorador o una regla de servicio con match literal y bypass de super-admin:
  - `confirm-union`: `@RequirePermissions('annual_folders:evaluate')` (`evaluation.controller.ts:136`) + regla de servicio `director-union`/`assistant-union` **sin** bypass de super-admin (`evaluation.service.ts:318-336`). UI: `UNION_CONFIRMATION_ROLES` en `evaluation-client-page.tsx`.
- Roles CLUB **no** deben recibir `camporee_events:{create,update,delete}`. `POST /camporees` crea `local_camporees` (`camporees.service.ts:452`), no un camporee de club. Los eventos cuelgan de `local-camporees/:id` y `union-camporees/:id` (`camporee-events.controller.ts:57-112` y `:140+`); no hay ruta de eventos de club. El seed da escrituras `camporee_events:*` a LF/Unión GLOBAL (`role-permissions.seed.sql:2011-2035`) y solo `camporee_events:read` a roles CLUB para la app (`:2265-2282`). El diseño “a sembrar” de `docs/features/camporee-events.md` (director/subdirector club con create/update) no se aplicó a escrituras y no se sembró ahora.
- Oleada 2d (investidura/certificaciones, seguros/finanzas/inventario, catálogos geografía y dominio): verbos por pantalla en `investiture.ts`, `operations.ts`, `catalogs-geography.ts`, `catalogs-domain.ts`; la factoría `generic-catalogs-i18n/actions.ts` gatea por `screenId`. Tres `viewAny` corregidos con evidencia del GET: `insurance-expiring` (`admin`/`coordinator`; LF por alias de coordinator, recorte a `local_field`), `catalogs-districts` (`local_fields:read`), `catalogs-divisions` (`countries:read`). Cambios visibles: `admin` pierde Crear/Eliminar en ideales/tipos de club y en años eclesiásticos, y desactivar config de investidura (todos `super-admin` en el API). Coordinator con seed recibe `investiture:mark_invested`. Detalle y evidencia en el plan.
- `clubs.create` / `clubs.bulk_create` (2026-09-17): espejo de `POST /clubs` (`clubs:create`, recurso global, sin `@GlobalRoles`). El panel deja de usar `canManageClubsByRole` (`super-admin`/`admin`/`director-lf`/`assistant-lf`). `assistant-admin` ve crear/import si el seed le da el permiso; `director-lf` no.
- Residuos admin (2026-09-15, bloques 0–4 del plan de cierre): `payment-orders` tabs `pending`/`orders`/`reassignments` espejo del hub GET `/payment-obligations/pending` y de field-payment-orders/reassignments; `activities.{create,update}`, `notifications-hub.{send_direct,broadcast,send_club}`, `resources-list`/`resources-categories` CRUD, `coordination.viewAny` ahora incluye `@GlobalRoles` de clase (pastor con `coordination:manage` pierde la pantalla). Actions de camporee events/venues/scoring ya no aceptan el OR muerto `camporees:*`. **Master honors expuesto** como `catalogs-master-honors` (sidebar + page `/dashboard/catalogs/master-honors`): mismas claves `honors:*` que `catalogs-honors` + `catalogEditorAccess`; se retiró el OR muerto `master_honors:manage || catalogs:*`. Recalcular reusa `update` (`honors:update`). **App (bloque 4, opción B):** registro Dart hermano + fixture de paridad; quick access por `screenId`. Commits (bloque 5): backend `2717db8`, admin `7eda2e5`, app `fe821117`.
- Corrección detectada por el test de seeds: `catalogs-club-ideals` y `catalogs-club-types` apuntaban a `club_ideals:read` / `club_types:read`, claves inexistentes en el API (`/admin/club-ideals` y `/admin/club-types` exigen `catalogs:read`). Ahora usan `catalogs:read` + rol admin.

### App Movil
- **Screen catalog hermano (2026-09-15, opción B):** `sacdia-app/lib/core/authorization/` copia `evaluateAccess`, alias de roles y las pantallas con `surfaces` que incluyen `app`. Quick access y tabs Clases/Actividades usan `canViewScreen(screenId)`. Hub de coordinación (`coordinator-hub`) es `@GlobalRoles('admin','coordinator')` + skip permissions (`analytics.controller.ts` SLA); `director-lf`/`assistant-lf` entran por alias de coordinator. Distinto del admin `coordination` (`coordination:manage` + roles de campo). Paridad: `test/fixtures/screen-catalog.snapshot.json` vs `dumpAppCatalog()` en admin. Judge tile sigue por asignación, fuera del catálogo.

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
- **OR transicional**: Para terceros, el sistema acepta el permiso fino O el fallback legacy `users:*` hasta `2027-03-31` (`USERS_LEGACY_OR_SUNSET_DATE`). El OR no se apaga en runtime todavia.
- **Elegibilidad de cargos de club por Guía Mayor**: independiente de los permisos; `club_roles:assign` no basta. El backend rechaza (403) cargos distintos de `member` a quien no es elegible GM y `member` de AV/CQ a quien lo es (`CLUB_ROLE_GUIDE_MAJOR_REQUIRED`, `CLUB_ROLE_MEMBER_REQUIRES_GUIDE_MAJOR_SECTION`). Detalle en `gestion-clubs.md`.
- **Membresía única por tipo de club al aprobar asignaciones**: aprobar una solicitud de asignación del rol `member` (`RequestsService.reviewAssignment`) aplica la regla del post-registro: si el usuario ya tiene otra asignación pendiente, o una activa en una sección del mismo tipo de club, responde 409 `REQUEST_ASSIGNMENT_DUPLICATE_MEMBERSHIP`. Los cargos de directiva no cambian.
- **Sync vs Assign**: `PUT` reemplaza todos los permisos (sync), `POST` agrega sin eliminar existentes (assign)
- **Cerca de rol en `/admin/*`**: los controladores `admin-*` llevan `@GlobalRoles('admin', 'super-admin')` a nivel clase (alias: `assistant-admin`). Un grant de permiso a un rol fuera de esa cerca no surte efecto ahí. Excepción (2026-09-15): `AdminUsersController` abre lectura (`GET users`, `GET users/:userId`), plantilla y alta (`POST users`, `POST users/bulk`) a `USER_MANAGEMENT_ROLES` = admin + los seis roles de campo (lf/union/dia), con `@GlobalRoles` de método que pisa la clase. Es seguro porque `AdminUsersService.resolveScope()` recorta toda consulta al territorio del actor (DIVISION/UNION/LOCAL_FIELD). `PATCH users/:userId` y `approval` siguen admin-only. El panel oculta flags `access_app` / `access_panel` / `active` (Roles, Resumen y aside) fuera de `admin` / `super-admin`. Sesiones de ficha (`GET/DELETE /admin/users/:userId/sessions`) usan la misma cerca de método + `users:read_detail` y `assertUserInActorScope` (2026-09-16); el panel admin **no** expone la pestaña Sesiones (mismo criterio que MFA: API sí, UI no). Plan de catálogo de pantallas: `docs/history/plans/2026-09-15-admin-screen-capability-catalog-design.md`.

## Permisos sensibles por sub-recurso de usuario

El sistema RBAC implementa permisos finos (fine-grained) para 4 familias de sub-recursos sensibles de `user`. Cada familia tiene un par de permisos `read`/`update` que coexisten con los permisos legacy `users:*` mediante un OR transicional.

### Tabla completa de permisos sensibles

| Familia | Permiso fino | Fallback legacy | Endpoints afectados |
| --- | --- | --- | --- |
| `health` | `health:read` | `users:read_detail` | `GET /users/:userId/allergies`, `GET /users/:userId/diseases`, `GET /users/:userId/medicines` |
| `health` | `health:update` | `users:update_profile` | `PUT /users/:userId/allergies`, `PUT /users/:userId/diseases`, `PUT /users/:userId/medicines`, `DELETE` item-level |
| `emergency_contacts` | `emergency_contacts:read` | `users:read_detail` | `GET /users/:userId/emergency-contacts` |
| `emergency_contacts` | `emergency_contacts:update` | `users:update_profile` | `POST/PATCH/DELETE /users/:userId/emergency-contacts` |
| `legal_representative` | `legal_representative:read` | `users:read_detail` | `GET /users/:userId/legal-representative` |
| `legal_representative` | `legal_representative:update` | `users:update_profile` | _(sin rutas: escritura retirada con perfiles familiares; ver [family-profiles](family-profiles.md))_ |
| `post_registration` | `post_registration:read` | `users:read_detail` | `GET /users/:userId/post-registration/status` |
| `post_registration` | `registration:complete` | _(sin fallback)_ | `POST /users/:userId/post-registration/step-{1,2,3}/complete` |

> **Nota**: `registration:complete` es un permiso global dedicado asignado a roles de campo (super_admin, admin, assistant-lf, director-lf y equivalentes union/dia por herencia). No usa fallback a `users:update`. El owner siempre puede completar su propio registro sin este permiso.

### Reglas de autorizacion

1. **Owner bypass (self-service)**: El propietario del `userId` tiene acceso completo a sus propios sub-recursos sin necesidad de permisos globales explícitos
2. **Terceros**: Solo se evaluan permisos globales. Se acepta el permiso fino **O** el fallback legacy (OR transicional). Excepcion: `registration:complete` no tiene fallback legacy
3. **Lectura club-scoped de miembros de la sección**: un permiso fino `family:read` (`health:read`, `emergency_contacts:read`, `legal_representative:read`, `post_registration:read`) en la asignación de club activa habilita **solo lectura** de ese sub-recurso cuando el `userId` es miembro **activo** (no `pending`) de la sección activa del actor. El fallback legacy `users:read_detail` **no** aplica por esta vía, y los modos `update` siguen requiriendo permiso global. Fuera de ese caso, los permisos de `authorization.active_assignment` no habilitan acceso transversal a recursos `user`

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

## Instructores de especialidad y carga por certificado (2026-10-13)

No agregan permisos ni cambian el seed: usan `user_honors:*` ya existentes o JWT + `@GlobalRoles` con `@SkipPermissions`. Matriz de enforcement en `docs/features/auth/RBAC-ENFORCEMENT-MATRIX.md`; contrato en `docs/api/ENDPOINTS-LIVE-REFERENCE.md` (secciones `instructors`, `admin-honor-instructor-proposals`, `user-honors`).

| Superficie | Guardas | Quién |
|---|---|---|
| `GET /instructor-candidates?q=` | `JwtAuthGuard` + `@SkipPermissions`; throttle 30/min | Cualquier usuario autenticado; el servicio limita al mismo Campo Local de quien consulta |
| `POST` / `DELETE /users/:userId/honors/:honorId/instructor-proposal` | `user_honors:submit` + ownership; throttle 10/min en el `POST` | Solo el dueño de la especialidad |
| `GET /admin/honor-instructor-proposals`, `POST .../:proposalId/approve`, `POST .../:proposalId/reject` | `GlobalRolesGuard` + `@SkipPermissions` | `super-admin`, `admin`, `assistant-admin`, `director-lf`, `assistant-lf`, con el mismo alcance de Campo Local que `admin/certificate-bulk-imports` |
| `GET /certificate-bulk-imports/catalog/classes`, `DELETE /certificate-bulk-imports/:batchId` | `JwtAuthGuard` + `@SkipPermissions` | Cualquier usuario autenticado; borrar exige ser el dueño y que el lote sea `DRAFT` |

- **Alcance del revisor** (`src/common/reviewer-scope`, compartido por la carga por certificado y las propuestas): `super-admin`, y `admin`/`assistant-admin` sin Campo Local, ven todo; quien tiene Campo Local (incluidos `director-lf` y `assistant-lf`) solo ve el suyo. En las propuestas el Campo Local es el **actual del dueño**.
- **Panel:** la pantalla `honor-instructor-proposals` (`/dashboard/honor-instructor-proposals`, sección investidura del catálogo de pantallas) usa `viewAny` y las capacidades `approve` y `reject` con los mismos cinco roles (`roleOnlyAccess(CERTIFICATE_BULK_ROLES)`), espejo literal del `@GlobalRoles` del controlador. El sidebar la muestra como «Propuestas de instructor».
- **`/honors*`, `/classes*` y `/catalogs/*`** son públicos con JWT opcional; la referencia live los marcaba `JWT` y se corrigió. No requieren permiso.

## Vigencia temporal, autoridad de cargos y roles globales (2026-11-04)

Backend PR #607, #608, #609 y #610, ya en `development`.

### Vigencia temporal de los cargos de club

- `buildClubGrant.operational` exige, además de `status=active`, año eclesiástico vigente y ciclo del club listo, que `ClubAssignmentEffectivityPolicy.isEffective` sea verdadero. La fecha de negocio es la del **Campo Local del club** (`local_fields.timezone`); si es `null` o no es una zona canónica se usa `America/Mexico_City`. Helper: `src/common/authorization/club-assignment-temporal.ts` (`toTemporalLocalField`, `CLUB_ASSIGNMENT_TEMPORAL_FIELDS`).
- `ClubRolesGuard` y las consultas directas de `PermissionsGuard` filtran con la misma política y la misma fecha de negocio, de modo que un cargo vencido deja de dar permisos en todos los caminos.
- `PATCH /auth/me/context` rechaza con 400 `AUTH_ASSIGNMENT_YEAR_MISMATCH` un assignment fuera de ventana (igual que `designated`, año ajeno o `status` distinto de `active`).
- Preflight de datos antes de desplegar: `prisma/scripts/authorization-effectivity-preflight.sql` (solo lectura; lista cargos `active` del año vigente que están fuera de su ventana y perderán permisos).

### Autoridad exacta sobre cargos (`SectionRoleMutationPolicy`)

`src/common/authorization/section-role-mutation.policy.ts`. Compara nombres de rol de forma literal (sin alias ni herencia) y aplica a `assignRole`, `updateRoleAssignment`, `removeRoleAssignment`, `assignInitialSectionDirector`, `succeedSectionDirector` y a `director-designation` (POST, GET, PATCH, DELETE). Puede mutar:

| Actor | Alcance |
| --- | --- |
| `super-admin`, `admin` | cualquier sección |
| `director-lf`, `assistant-lf` | secciones de clubes de **su mismo Campo Local** |
| `director` operativo de la sección | solo esa sección; **no** sobre sí mismo y **no** sobre el cargo `director` (ni para nombrar ni para leer la programación `director-designation`) |
| rol destino `member` | exento (lo rigen los flujos de membresía) |

Unión, DIA y `assistant-admin` no mutan cargos. Cualquier otro actor recibe 403 `CLUB_ROLE_MUTATION_FORBIDDEN`. Un cambio de rol (`updateRoleAssignment`) valida tanto el rol actual como el nuevo.

### Auditoría de cargos

`CriticalAuditWriterService` escribe dentro de la misma transacción del cargo: `CLUB_ROLE_ASSIGNED`, `CLUB_ROLE_UPDATED`, `CLUB_ROLE_REVOKED` (y `DIRECTOR_SUCCEEDED` en la destitución de director). El actor es el usuario autenticado. Si el writer falla, la transacción hace rollback y el cargo no cambia.

### Roles globales de usuario (`GlobalUserRoleWriteService`)

`POST /admin/rbac/users/:userId/roles` y `DELETE /admin/rbac/users/:userId/roles/:roleId` exigen `@GlobalRoles('super-admin')` y `permissions:assign`, y delegan en `src/rbac/global-user-role-write.service.ts`:

- locks advisory por usuario (`rbac-user:{id}`, actor y objetivo ordenados) y por evento;
- `Idempotency-Key` opcional (si falta se genera uno); misma clave con otro payload → 409 `IDEMPOTENCY_KEY_REUSED`; un reintento con el mismo payload devuelve el resultado original (`replayed: true`);
- `ExactSuperAdminWritePolicy` (`src/rbac/exact-super-admin-write.policy.ts`): el actor debe tener una fila activa en `users_roles` con el rol `super-admin` de categoría `GLOBAL`; si no, 403 `SUPER_ADMIN_WRITE_REQUIRED`. Un rol que no sea `GLOBAL` → 400 `RBAC_GLOBAL_ROLE_REQUIRED`;
- evento crítico en la misma transacción: `RBAC_GLOBAL_ROLE_ASSIGNED`, `RBAC_GLOBAL_ROLE_REVOKED` o `RBAC_GLOBAL_ROLE_ASSIGNMENT_NOOP`.

`RbacService.assignRoleToUser` y `removeRoleFromUser` ya no existen; el controlador invalida el cache del usuario afectado después de escribir.

### Specs de red de seguridad

- `src/common/guards/permission-catalog-parity.spec.ts`: todo permiso referenciado en el código (`@RequirePermissions`, `@SensitiveUserSubresource`, constantes de política) debe existir en el catálogo (`permissions.seed.sql` y los `INSERT INTO permissions` de las migraciones); evita permisos fantasma.
- `src/common/guards/tenant-binding-allowlist.freeze.spec.ts`: ratchet de la allowlist de rutas que aún no tienen `bind` de tenant (`tenant-binding-allowlist.ts`); nació fijada en 69 (`FROZEN_TOTAL`, más el desglose por marcador) y las fases que retiraban rutas bajaban el congelado. Desde la fase 5 (mergeado el 2026-11-04 (PR #615 de sacdia-backend)) la allowlist está vacía y el spec exige que siga vacía (ver «Tenant binding»).

## Motor de políticas: catálogo generado, policies por recurso, literales de rol, tenant binding y capabilities (2026-11-05)

Fases 3, 4 y 6 del plan `docs/history/plans/2026-11-03-rbac-policy-engine-remediation.md`, mergeadas en `development` el 2026-11-04 (backend PR #611, #612, #613 y #614; admin #288 y #289; app #226 y #228). La fase 5 (tenant binding, backend PR #615) se mergeó el mismo día. La fase 7 (capabilities y clientes: backend #617 y #618, admin #290, app #234, #236 y #238) se mergeó el 2026-11-04/05 con criterio de salida parcial (ver «Capabilities y clientes (fase 7)»). El estado por fase vive en ese plan.

### Catálogo de autorización generado (fase 3)

- **Fuente de verdad**: `prisma/seeds/permissions.seed.sql`, `prisma/seeds/role-permissions.seed.sql` y las migraciones, leídas por `scripts/authz/catalog-source.ts`. Honra los `UPDATE permissions SET active=false` del seed: esos permisos van a `DEPRECATED_PERMISSION_KEYS` (9 hoy: `classes:update`, `classes:validate`, `folders:manage`, `folders:read`, `qr:issue_self`, `user_folders:manage`, `user_folders:read`, `user_honors:update`, `users:update`). Los roles viven en `prisma/authz/roles.json`, que `prisma/seed.ts` consume.
- **Generador**: `scripts/authz/generate-catalog.ts`. Comandos: `pnpm authz:generate` (regenera) y `pnpm authz:check` (falla si los generados no coinciden; corre en el job «Lint & Type Check» del CI del backend).
- **Salidas generadas (no editar a mano)**:
  - backend `src/common/authorization/generated/{permission-keys,role-names,role-aliases}.ts`: `PERMISSION_KEYS` (224 claves activas), tipo `PermissionKey`, objeto `Permission`, `GLOBAL_ROLE_NAMES` (14), `CLUB_ROLE_NAMES` (8), `GLOBAL_ROLE_ALIASES`;
  - admin `src/lib/auth/generated/{permission-keys,role-names,role-aliases}.ts`;
  - app `lib/core/authorization/generated/{permission_keys,role_names,role_aliases}.dart`: `kPermissionKeys`, `kGlobalRoleNames`, `kClubRoleNames`, `kGlobalRoleAliases`.
- **Backend**: `@RequirePermissions` está tipado con `PermissionKey`; un permiso mal escrito no compila.
- **Admin (paso 2, #289)**: `src/lib/auth/permissions.ts` conserva sus constantes nombradas, cada una con `satisfies PermissionKey`; se borró `seeded-permission-keys.ts`; `screen-catalog/role-aliases.ts` toma `GLOBAL_ROLE_ALIASES` del generado; `permissions.test.ts` verifica la paridad. Se eliminaron 34 constantes que nombraban permisos inexistentes en el backend (`relationship_types|allergies|diseases|medicines|club_types|club_ideals|activity_types:{read,create,update,delete}`, `classes:manage`, `class_modules:manage`, `class_sections:manage`, `finance_categories:manage`, `inventory_categories:manage`, `dashboard:view`); no tenían usos. El backend protege esos catálogos con `catalogs:*` y el dashboard con `dashboard:read`.
- **App (paso 2, #228)**: `lib/core/authorization/role_aliases.dart` re-exporta el generado; `test/core/authorization/generated_catalog_parity_test.dart` exige que los nombres de rol de club, los alias y todo literal `'recurso:accion'` de `lib/` existan en el catálogo. Se eliminó el literal muerto `post_registration:update` (nunca fue grant; esa ruta usa `users:update_profile`).
- **Deriva entre repos**: el job «Cross-repo Contract» del CI del backend clona admin y app en los SHAs fijados por las variables de repositorio `SACDIA_ADMIN_CONTRACT_REF` y `SACDIA_APP_CONTRACT_REF` y corre `src/common/authorization/authz-catalog.crossrepo.spec.ts`, que compara los generados y falla ante deriva. Cada vez que cambian los generados en admin o app hay que mover la variable correspondiente. `SACDIA_ROOT_CONTRACT_REF` quedó sin uso: el job ya no clona este repo raíz (PR #612; ver «Retiro del contrato P0»).

### Policies por recurso y `ActorScope` (fase 4)

- `src/common/guards/permissions.guard.ts` pasó de 2435 a 339 líneas. Conserva lectura de metadata, `@SkipPermissions`, `GUARD_RBAC_MISCONFIGURATION`, comprobación de permisos y bypass de dueño; el scope de recurso lo despacha a un registry.
- `src/common/authorization/policies/resource-policy.ts`: `interface ResourcePolicy { type; resolve(ctx: PolicyContext): Promise<boolean> }`. `policy-registry.ts` es un tipo mapeado `{[K in AuthorizationResourceType]: ResourcePolicy<K>}`: un tipo de recurso sin policy no compila. `build-policy-registry.ts` arma el registry.
- 21 policies, cada una con spec: `policies/simple/{global,user,active-assignment}`; `policies/club/{club,club-section,activity,activity-series,finance,inventory-instance,inventory-item,club-assignment,class-counselor-assignment,investiture-enrollment,monthly-report,insurance-member,insurance-record}`; `policies/camporee/{camporee,union-camporee,camporee-event,camporee-venue,camporee-payment}`.
- Validadores compartidos: `policies/scope/instance-scope.ts` (`InstanceScopeValidator`, `AssignmentEffectivity`), `policies/scope/territory-scope.ts` (`TerritoryScopeValidator`, `CamporeeScopeLoader`), `policies/scope/club-access.ts`, `policies/request-values.ts`; `src/common/authorization/tenant-binding.enforcer.ts` (`TenantBindingEnforcer`), `section-member-access.ts` (`SectionMemberAccess`) y `permission-requirements.ts`.
- `src/common/authorization/actor-scope.ts`: `ActorScope.from(resolved)` con `hasRole`, `hasAnyRole`, `coversHierarchy`, `coversClub`, `coversSection`, `coversLocalField` e ids de club, sección y campo activos. Lo usan los validadores anteriores y `report-visibility-scope`, `camporee-supply-actor`, `camporee-order-actor` y `field-payment-orders/order-actor`.
- Diferido al corte del 2026-11-04: `actor-territory-scope`, `coordinator-section-scope`, `target-user-scope`, `member-territory-scope.service`, `class-progress-scope.service` y `operations-dashboard-scope.service` conservan su API (24 importadores).
- Cierre parcial (backend PR #621, 2026-11-05), sin cambio de API ni de comportamiento: `target-user-scope`, `operations-dashboard-scope.service`, `coordinator-section-scope` y `actor-territory-scope` delegan en `ActorScope` (`resolveActorTerritoryScope` es un adaptador sobre `ActorScope.territorialTier()`; `ActorScope` gana `territory`, `isCoordinator()` y `territorialTier()`; `toTerritoryId` vive en `territory-id.ts`). Quedan `class-progress-scope.service` (solo adopta `role-sets`; `hasSectionWideAccess` decide por sección y año del request sin filtrar `status`, excepción documentada en el código) y `member-territory-scope.service` (construye predicados Prisma, no decide roles). Detalle en el plan, «Fase 4, lo que se hizo y lo diferido».
- El constructor del guard no cambió; los 114 casos de sus tres specs siguen idénticos.

### Literales de rol y `@ExactGlobalRoles` (fase 6)

- `src/common/authorization/roles.ts`: `GlobalRole` y `ClubRole` (objetos `as const satisfies` sobre los tipos generados); `role-sets.ts` (`ADMIN_SCOPE_ROLES`, `LOCAL_FIELD_ROLES`, `UNION_ROLES`, `DIVISION_ROLES`, `FIELD_ADMIN_ROLES`, `COORDINATOR_ROLES`); `role-checks.ts`. `GlobalRoleType` y `ClubRoleType` son alias de `GlobalRoleName` / `ClubRoleName`. Se borró `src/common/constants/roles.constants.ts`.
- Regla ESLint local `local/no-role-literals` (`eslint/rules/no-role-literals.cjs`, nivel `error`, sin autofix). Los nombres inequívocos (con guion, `pastor`, `counselor`, `instructor`, `secretary`, `treasurer`) se prohíben como literal salvo en claves que no son rol (`kind`, `type`, `level`, swagger), tipos TS y decoradores de ruta; los ambiguos (`user`, `admin`, `member`, `director`, `coordinator`) solo en contexto de rol (decorador, comparación con algo llamado role, `.has` / `.includes`, arreglo con otro rol, `case`). 661 literales reemplazados. Archivos permitidos: `generated/`, `roles.ts`, `role-sets.ts`, `global-role-aliases.ts`, `club-roles.guard.ts`, `constants/club-directiva-roles.ts`.
- `@ExactGlobalRoles(...)` (`EXACT_GLOBAL_ROLES_KEY`): `GlobalRolesGuard` lo lee primero y no expande alias; `super-admin` sigue pasando; si `@GlobalRoles` y `@ExactGlobalRoles` coinciden en el mismo nivel, gana exact. Aplicado solo a `admin-certificate-bulk-imports.controller.ts` y `admin-honor-instructor-proposals.controller.ts` (`super-admin`, `admin`, `assistant-admin`, `director-lf`, `assistant-lf`), donde `reviewer-scope.ts` ya comparaba de forma exacta: el contrato del guard coincide ahora con la matriz, sin cambio en runtime.
- Decisiones de producto cerradas el 2026-11-05 (alias amplio en mutaciones; registradas en `docs/audit/DECISIONS-PENDING.md`): el alias `admin ↔ assistant-admin` se acepta en todo, así que toda ruta `@GlobalRoles(admin, super-admin)` sigue admitiendo `assistant-admin`; y «escribir en la configuración de un campo local es trabajo del campo local»: unión y división dejan de escribir y conservan la lectura en `PATCH local-fields/:id/investiture-windows/:yearId` (sin cambio de comportamiento, el servicio ya negaba a unión), las mutaciones de `district-investiture-pastors` (ahora `@ExactGlobalRoles`: super-admin, director-lf, assistant-lf; el cupo, solo super-admin) y las 7 escrituras de `admin/coordination` (`@ExactGlobalRoles`: admin, assistant-admin, super-admin, director-lf, assistant-lf). Pendiente de merge: sacdia-backend PR #631 (`feat/authz-exact-local-field-writes`) y sacdia-admin PR #291 (oculta los controles de escritura de coordinación tras `coordination.manage`).

### Tenant binding (fase 5)

Backend PR #615, mergeado en `development` el 2026-11-04.

- `src/common/guards/tenant-binding-allowlist.ts` queda vacío y `tenant-binding-allowlist.freeze.spec.ts` exige que siga vacío. `tenant-binding-inventory.ts` incluye `fieldId` en `TENANT_PATH_PARAM`.
- **Kinds de `bind` (11)**: `club`, `club_section`, `local_field`, `union`, `camporee`, `union_camporee` (solo la unión dueña), `club_enrollment_territory`, y los nuevos `union_camporee_participant` (unión dueña, o campo participante con fila activa en `union_camporee_local_fields`, o club con campo activo), `club_section_membership`, `union_membership` y `local_field_membership` (jerarquía o cualquier asignación de club operativa del actor en ese ámbito).
- **Inventario de tenant en body o query**: nuevo `tenant-body-allowlist.ts` con 55 rutas `global` / `user` / `active_assignment` que reciben `club_id`, `club_section_id`, `local_field_id`, `union_id`, `division_id`, `camporee_id` o `union_camporee_id` en body o query sin `bind`, con ratchet propio. Solo inventario por ahora.
- **Params renombrados** (las URLs no cambian; solo el nombre del parámetro en la documentación): `PATCH|DELETE /admin/divisions/:id`, `/admin/unions/:id`, `/admin/local-fields/:id` (antes `:divisionId`, `:unionId`, `:localFieldId`); `PATCH|DELETE /annual-folders/templates/sections/:templateSectionId` y `/annual-folders/:folderId/sections/:templateSectionId/{status,evidences,submit,evaluate,reopen,confirm-union}` (antes `:sectionId`; es el id de sección de plantilla); `/users/:userId/classes/:classId/sections/:moduleSectionId/{submit,files,files/:fileId}` (antes `:sectionId`).
- **39 rutas de camporee** (orders, offerings, payment-orders, configuración y planes de supplies, más `GET /camporees/union/:camporeeId`): las `global` conservan tipo y ganan `bind` (`camporee`, `union_camporee_participant`, o `union_camporee` solo-dueña en `PATCH /union-camporees/:camporeeId/orders-settings` y `PUT /union-camporees/:camporeeId/order-offerings`); las `active_assignment` pasan a tipo `camporee` / `union_camporee` con `idParam: 'camporeeId'`.
- **Resto**: coordinación `GET|POST /admin/coordination/local-fields/:localFieldId/{zones,assignments,backfill}` y `PATCH /materials/config/:localFieldId` con `local_field`; `POST /notifications/club/:instanceType/:instanceId` con `club_section`; `GET /club-sections/:sectionId/annual-ranking-progress` y `GET /section-rankings/:sectionId/members` con `club_section_membership`; `unions/:unionId/scoring-categories*` con `union_membership` y `local-fields/:fieldId/scoring-categories*` con `local_field_membership`.
- **Cambios de comportamiento a propósito**: `GET order-offerings`, `GET supply-catalog`, `GET supply-plans`, los reportes de cocina y caja, `PATCH supply-plan/lines` (local y unión) y `GET /camporees/union/:id` responden 403 `GUARD_CLUB_SCOPE_REQUIRED` fuera del ámbito del camporee (404 `CAMPOREE_NOT_FOUND` / `CAMPOREE_UNION_CAMPOREE_NOT_FOUND` si no existe); los directores de una unión que no organiza pierden el bypass en planes de insumos. Los códigos del guard preceden a `CAMPOREE_ORDER_*` / `CAMPOREE_SUPPLIES_*` en casos cross-tenant.
- **Decisiones de producto conservadas**: un consejero de club puede crear categorías de puntuación de su unión; la geografía admin no se ata a territorio.

### Capabilities y clientes (fase 7)

Backend #617 y #618, admin #290, app #234, #236 y #238, mergeados en `development` el 2026-11-04/05. El backend publica qué puede intentar el actor y los clientes lo leen en vez de reconstruir reglas de rol. Contrato HTTP en `docs/api/ENDPOINTS-LIVE-REFERENCE.md` (`GET /auth/me`); diseño de claves en `sacdia-backend/src/common/guards/README.md`, «Capabilities».

- **Contrato (`data.authorization` de `GET /auth/me`)**: `capabilities` (47 claves ordenadas del catálogo generado `generated/capability-keys.ts`; mismo archivo en admin `src/lib/auth/generated/capability-keys.ts` y app `lib/core/authorization/generated/capability_keys.dart`), `territory` (`level` ∈ `all | open | unconfigured | division | union | local_field`, más `division_id`, `union_id` y `local_field_id` nullable) y `assignable_global_roles` (tier inferior al del actor, `user-role-tiers.ts`; vacío fuera de tiers administrativos). Se calculan por request con funciones puras (`capabilities.ts`: `computeCapabilities`, `computeTerritory`, `assignableGlobalRoles`) sobre el perfil ya pasado por `stripClubContext`; nunca se cachean (la clave `auth:context:v8` no cambió).
- **Semántica**: una capability es «el actor puede intentarlo sobre al menos un objetivo». Los servicios siguen siendo la autoridad y responden 403 cuando el objetivo concreto no coincide. Las claves basadas en territorio son falsas con `level` `open` o `unconfigured`. #618 alineó con su guard o policy `club_roles.assign_section` (admite también al director operativo de club, como `SectionRoleMutationPolicy`) y `field_payment_orders.review` (exige campo local del territorio o del grant activo, como `resolveOrderActor`). Difiere del diseño del plan: no las calculan las policies de las fases 2 y 4 sino predicados puros que las reproducen.
- **Invalidación por push**: `invalidateUserAuthorizationCache` publica un FCM silencioso data-only (`resource: 'authorization'`, `action: 'UPDATED'`) vía `NotificationsService` (`@Optional()` + `forwardRef`). `AuthorizationContextService` tiene una sola instancia, provista por `CommonModule` (`@Global()`); `AuthModule` ya no la declara y `auth-module.wiring.spec.ts` lo verifica sobre el `AppModule` compilado.
- **Admin (#290)**:
  - Gates por `capabilityAccess(CapabilityKey)` sobre las capabilities de `/auth/me`; un solo evaluador decide página, sidebar, botones, slot `@modal` y Server Actions. Los gates con capability reemplazan a los `exactRoles` y a `roleOnlyAccess`, que ya no existe en el screen catalog.
  - El slot `@modal` se gatea en el layout con `canAccessDashboardPath`; cada una de las 15 páginas interceptadas llama al mismo gate que su página completa. Las Server Actions llaman a `requireCapability`. `classifyActionError` (`lib/api/action-error.ts`) es el único clasificador de 403.
  - Eliminados `NEXT_PUBLIC_RBAC_LEGACY_FALLBACK`, `extractLegacyRoles`, `extractLegacyPermissions` y `canByPermissionOrRole`; `extractRoles` usa solo `global_roles` más el rol del `active_assignment`. El ratchet `src/lib/auth/role-literal-ratchet.test.ts` falla si un archivo de `src/components` o `src/lib` decide acceso por nombre de rol fuera de su allowlist de datos de presentación.
  - `territory` ausente → `level: "open"` (fail-open, decidido); `capabilities` ausente → lista vacía (deny). `isSuperAdmin` sigue derivado de `roles.has('super-admin')` en `screen-catalog/evaluate.ts`.
- **App (#234, #236, #238)**:
  - **Guard de ruta**: el `redirect` global de GoRouter consulta `routeScreenIds` (`lib/core/config/route_screen_policy.dart`, 33 patrones de ruta de 114 `GoRoute`) y, si `canViewScreen` es falso, manda a `/access-denied`. `ForbiddenView` (`SacErrorState.forbidden`) es el estado de 403 de las 7 vistas del coordinador.
  - **Stale offline**: `AuthorizationStaleInterceptor` (posición 0 de Dio). El snapshot restaurado desde `secureStorage` sin red se marca stale y POST/PUT/PATCH/DELETE reciben un 403 sintético `AUTHORIZATION_STALE` hasta revalidar. Exentos: `sessionPaths` (`/auth/refresh`, `/auth/logout`, `/auth/me`, `/auth/me/context`) y las peticiones con `kAllowWhileAuthorizationStale` (borrado del token FCM al cerrar sesión). El helper `isAuthorizationStale` evita confundir ese 403 con un error de seguro en 9 datasources y en el registro de camporees.
  - **Refresco**: `refreshAuthorization` corre en `AppLifecycleState.resumed` (mínimo 30 s), al recuperar conectividad y al recibir el push `authorization`. `RealtimeInvalidationHandler` procesa ese push siempre, sin depender de `RealtimeFeatureFlags.realtimeInvalidationEnabled`; un push durante un refresh en vuelo se repite una vez al terminar.
  - **Paridad con el catálogo**: `test/core/authorization/generated_catalog_parity_test.dart` exige que cada literal de capability y de permiso de `lib/` exista en el catálogo generado.
- **Criterio de salida: parcial**:
  - Admin, cumplido: ningún gate por lista de roles en `src/components`; quedan listas de presentación o filtro (`camporee-scoring/camporee-judges-panel.tsx`, `COORDINATOR_ROLES` en `coordination/coordination-assignments-panel.tsx`, `isProtected` de super-admin en `rbac/roles-table.tsx`).
  - App, cumplido con app PR #240 (2026-11-05): los cinco sitios que clasificaban a otros miembros por `clubRole` con literales (`club_member.dart`, `class_counselor_assignments_view.dart`, `enrollment_form_view.dart`, `members_remote_data_source.dart`, `role_assignment_view.dart`) usan `ClubRoleNames` y los helpers de `lib/core/auth/club_role_names.dart` (`normalizeClubRoleName`, `kClubRoleSpanishAliases`, `canonicalClubRoleName`, `clubRoleLookupCandidates`); el ratchet `test/core/authorization/club_role_literal_ratchet_test.dart` impide que vuelvan. Quedan 10 comprobaciones numéricas `== 403` en datasources de `lib/features` (las de login y `ACTING_FOR_FORBIDDEN` son intencionales); no estaban en el plan.
  - Paridad admin↔app sobre capabilities, solo transitiva: `authz-catalog.crossrepo.spec.ts` compara `capability-keys` contra admin y contra app por separado (job «Cross-repo Contract»; `SACDIA_ADMIN_CONTRACT_REF` y `SACDIA_APP_CONTRACT_REF` se movieron a los SHAs de la fase 7). `test/core/authorization/screen_catalog_test.dart` sigue comparando el catálogo de pantallas contra `test/fixtures/screen-catalog.snapshot.json`.
  - QA por rol con capturas: pendiente. Sin evidencia en este corte de que se haya ejecutado.
- **Decisiones de producto** (`docs/audit/DECISIONS-PENDING.md`): decidido el 2026-11-05 que `assistant-admin` gestiona usuarios (las capabilities `users.*` y `rbac.view_user_roles` aplican el alias, como `GlobalRolesGuard`; `USER_MANAGEMENT_ROLES` del catálogo anterior del admin no lo incluía); decidido también el 2026-11-05, opción (a): se mantiene `scoring_categories.manage` reportada a consejeros de club de la unión (toda capability significa «puede intentarlo sobre al menos un objetivo»; el servicio sigue siendo la autoridad y responde 403 fuera de su unión; sin cambio de código).
- **Diferidos que siguen abiertos de fases anteriores**: 2 resolvers de scope con razón documentada (fase 4: `class-progress-scope.service`, `member-territory-scope.service`), copias privadas de `isSuperAdmin` (fase 6).

### Ratchets del motor (specs que fallan ante regresión)

| Spec | Qué congela |
| --- | --- |
| `src/common/guards/permission-catalog-parity.spec.ts` | Todo permiso referenciado en código existe en el catálogo (fase 0) |
| `src/common/guards/tenant-binding-allowlist.freeze.spec.ts` | Allowlist de rutas sin `bind`: vacía desde la fase 5; una entrada nueva rompe el build |
| `src/common/authorization/authz-catalog.crossrepo.spec.ts` | Generados de admin y app iguales a los del backend (job «Cross-repo Contract») |
| `pnpm authz:check` (job «Lint & Type Check») | Generados del backend iguales a seeds y migraciones |
| `src/common/authorization/access-decision-locality.arch.spec.ts` | 46 archivos que deciden acceso con `club_role_assignments` o `users.local_field_id` fuera de `src/common/authorization/`; un archivo nuevo rompe el build |
| `local/no-role-literals` (ESLint, `error`) | Ningún literal de nombre de rol fuera de los archivos permitidos |
| Ratchet de `tenant-body-allowlist.ts` | 55 rutas con tenant en body o query sin `bind` (fase 5; solo inventario) |
| `sacdia-admin/src/lib/auth/role-literal-ratchet.test.ts` | Decisiones de acceso por nombre de rol en `src/components` y `src/lib` del admin; solo pasa con una allowlist explícita de archivos donde el rol es dato (fase 7) |
| `sacdia-app/test/core/authorization/generated_catalog_parity_test.dart` | Todo literal de capability y de permiso de `lib/` existe en el catálogo generado (fase 7) |
| `sacdia-app/test/core/authorization/club_role_literal_ratchet_test.dart` | Ningún archivo de `lib/features` fuera de una allowlist de falsos positivos (claves JSON, l10n) contiene un literal de `kClubRoleNames` ni de los alias en español (fase 7, PR #240) |

### Retiro del contrato P0 de consumidores (backend PR #612)

`scripts/verify-authorization-director-succession-p0.ts` ya no inventaría consumidores de admin, app ni de este repo, ni verifica frases canónicas en `docs/features/gestion-clubs.md` (ese contrato de julio afirmaba que la sucesión programada no existía; existe desde septiembre). El CLI `pnpm verify:authorization-p0` conserva readiness de esquema, catálogo IANA/ICU, señales de Postgres y clasificación de fallos; `report_version` pasó a `authorization-director-succession-p0/v2` y desapareció el campo `consumer_inventory`. Se borró `verify-authorization-director-succession-p0-crossrepo.spec.ts`.

### CI del backend

El job «Lint & Type Check» corre `prisma generate` antes de `pnpm run lint`: sin cliente generado, las reglas type-aware veían `any` y el `--fix` borraba aserciones que el build necesitaba. El mismo job corre `pnpm authz:check`.

## Context Switching y permisos por seccion activa

El sistema soporta usuarios con multiples asignaciones de club (ej: Director en Conquistadores + Miembro en Guias Mayores). El contexto activo se controla mediante `PATCH /auth/me/context` y afecta los permisos visibles en toda la app.

### Fuente de verdad

- **Campo canonico**: `users_pr.active_club_assignment_id` en la DB
- **Seteo**: `PATCH /auth/me/context` con `{ assignment_id }` — escribe en DB, invalida cache Redis, re-resuelve autorizacion
- **Lectura**: Tanto `GET /auth/me` como `GET /dashboard/summary` leen del mismo campo canonico. El dashboard carga las asignaciones activas en la misma lectura de `users` y elige en memoria por `active_club_assignment_id` (si el ID ya no está activo, cae a la más reciente).
- **Cache**: Redis `auth:context:v8:{userId}` con revisión de calendario en el envelope (`AUTH_CONTEXT_CACHE_KEY`). TTL = el menor entre 5 min, el fin del año eclesiástico y la próxima frontera temporal (`start_date`, `end_date` o `expires_at`) de cualquier assignment cargado (`cacheTtlMs`). Si el TTL resulta ≤ 0 no se cachea. Se invalida en cada context switch y en cada mutación de cargos o roles; al invalidar también se borran las claves `v2`–`v7` y la clave sin versión. El corte de año ya no sube ninguna versión: la vigencia se resuelve por fecha y por TTL.

### Calculo de effectivePermissions

`AuthorizationContextService.resolveUserAuthorization` calcula `effective.permissions` como la **union de**:
1. Permisos de **global grants** (roles globales del usuario)
2. Permisos del **active club assignment** unicamente

Los permisos de asignaciones de club inactivas **NO** se incluyen en `effectivePermissions`. Esto garantiza que un Director en Conquistadores pierde permisos de director al cambiar a Guias Mayores donde es Miembro.

### Frontend: gating de UI

La app Flutter usa tres mecanismos para gating de UI, todos scoped al contexto activo:

| Mecanismo | Fuente | Uso |
| --- | --- | --- |
| `effectivePermissions` (RBAC canonico) | `authorization.effective.permissions` de `/auth/me` | Check primario de permisos (`hasAnyPermission`) |
| `capabilities` (fase 7) | `authorization.capabilities` de `/auth/me` | `hasCapability(user, 'a.b')`; sin autorización o sin capabilities publicadas es `false` (deny) |
| `resolvedRoleNames` (legacy fallback) | Solo global grants + active grant role | Fallback cuando el permiso RBAC no existe |

`resolvedRoleNames` en `AuthorizationSnapshot` solo incluye roles de grants globales y del active grant — **no** de asignaciones inactivas. Esto previene escalacion de privilegios donde un rol de una seccion inactiva otorga acceso en la seccion activa.

### Selector de sección en app móvil

Cuando un usuario tiene asignaciones en varias secciones, el selector de
contexto de la app móvil ordena siempre por ciclo formativo/edad:
`Aventureros` → `Conquistadores` → `Guías Mayores`. No debe depender del orden
de creación ni del orden en que `/auth/me` devuelve `club_assignments`.

La card de contexto de club del dashboard y el selector de sección comparten
los mismos colores de tipo de club: Conquistadores usa el color primario rojo,
Aventureros usa azul y Guías Mayores usa verde. El mapeo vive en
`sacdia-app/lib/core/theme/club_type.dart` para evitar divergencias visuales.

### Quick Access Grid — permisos por rol

| Tarjeta | Permiso RBAC | Quien lo recibe (seed) |
| --- | --- | --- |
| Coordinacion | — (rol global) | `coordinator`, `zone-coordinator`, `general-coordinator`, `admin`, `super-admin` |
| Miembros | `users:read_detail` | counselor+ (no member, no instructor) |
| Club | `clubs:update` | `director`, `deputy-director`, `secretary`, `secretary-treasurer` |
| Carpeta Anual de Evidencias | `evidence_folders:read` | secretary / deputy / director (y secretary-treasurer) |
| Camporees | `camporees:read` | secretary+ de seccion (no member/counselor/instructor) |
| Finanzas | `finances:read` | treasurer, deputy, director, secretary-treasurer |
| Unidades | `units:update` | counselor+ ; crear usa `units:create` (direccion/secretaria/tesoreria) |
| Clase Agrupada | `classes:submit_progress` | counselor+ (no member, no instructor) |
| Seguros del Club | `insurance:read` | counselor+ |
| Inventario | `inventory:read` | secretary, deputy, director, secretary-treasurer |
| Materiales | `materiales:create` | director, deputy, secretary, secretary-treasurer |
| Recursos | `resources:read` | todos los roles de club, incluido member |
| Reportes | `reports:read` | secretary / treasurer / deputy / director |

### Dashboard — inscripción anual de club

El banner de inscripción anual en la app móvil usa el permiso canónico
`club_instances:create` para mostrar la acción **Inscribirse** cuando no existe
inscripción vigente. Este permiso lo reciben roles de dirección/secretaría de
la sección activa (`director`, `secretary`, `secretary-treasurer`) y no debe
mostrarse a `member`.

Al enviarse la inscripción anual, el backend crea/actualiza
`club_enrollments.status = pending_validation`. En ese estado la app muestra el
mensaje de inscripción enviada/en validación por Campo Local; no vuelve a
mostrar el botón de inscripción. Este estado visual usa el color
amarillo/acento y escala la tarjeta al 80% respecto del aviso pendiente para
comunicar revisión sin ocupar tanto espacio del dashboard.

El panel administrativo ya no tiene la ruta `/dashboard/enrollments`: la fase 8
(panel #226, mergeado y desplegado) la borró. Esa ruta nunca consumió
`GET /club-enrollments/validation/queue` ni `POST /club-enrollments/:enrollmentId/approve|reject`
(ver `club-enrollments.md`: no hay pantalla para esa bandeja); listaba inscripciones
de clase pendientes de investidura.
Cuando Campo Local aprueba, la inscripción pasa a `active` y la app deja de
mostrar la alerta de validación.

### Permisos de la vía anterior de investidura (fase 8)

`investiture:submit`, `investiture:validate`, `investiture:mark_invested` e `investiture_config:*` quedaron **inertes** con la fase 8: las rutas que los exigían responden 410 y usan `@SkipPermissions`, y el panel borró las pantallas que los usaban. Desde el 2026-10-13 ya no existen: la migración `20261013110000_remove_retired_investiture_permissions` (backend #488) borró las concesiones y las filas del catálogo en `development`, `staging` y `production`. `investiture:read` sigue en uso: lo exigen las dos lecturas del historial. `validation:submit` y `validation:review` siguen vigentes (`ValidationModule` los exige antes del 410 de `class`). `docs/features/auth/RBAC-ENFORCEMENT-MATRIX.md` no listaba estas rutas y no cambia.

### Seed de permisos

El archivo `prisma/seeds/role-permissions.seed.sql` es **idempotente**: cada bloque de rol hace `DELETE` + `INSERT`. Despues de esos bloques hay `INSERT ... ON CONFLICT DO NOTHING` para permisos que el listado del rol no copiaba bien:

- `clubs:update` — ficha del club: `director`, `deputy-director`, `secretary`, `secretary-treasurer`
- `units:create` / `units:delete`
- `materiales:*` (si no se reafirman aqui, un re-seed borra los grants de la migracion 20260513)

Correr `permissions.seed.sql` y luego `role-permissions.seed.sql`. El snapshot Redis usa `auth:context:v8:{userId}` (TTL ≤ 5 min); mutar `users_permissions` o roles invalida esa clave.

## Bugs corregidos (2026-04-10)

1. **Redis cache no se invalidaba en context switch**: `setActiveClubContext` escribia en DB pero `resolveUserAuthorization` leia del cache stale. Fix: invalidar cache antes de re-resolver.
2. **Dashboard summary ignoraba active context**: `dashboard.service.getSummary()` usaba `findFirst(orderBy: created_at)` en vez de leer `active_club_assignment_id`. Fix: misma logica que auth service.
3. **`resolvedRoleNames` incluia roles de TODAS las secciones**: Un Member veia UI de Director porque `resolvedRoleNames` iteraba todos los `clubAssignments`. Fix: solo global grants + active grant.
4. **Seed no-idempotente**: `ON CONFLICT DO NOTHING` solo agregaba permisos, nunca removia stale. El member tenia `users:read_detail` de un seed anterior. Fix: DELETE + INSERT por rol.
5. **Legacy role names en espanol**: El grid usaba `secretario`, `tesorero` pero el backend usa `secretary`, `treasurer`. Nunca matcheaban. Fix: corregidos a ingles.
6. **`secretary_treasurer` no contemplado**: Este rol no aparecia en ninguna tarjeta del grid. Fix: agregado donde corresponde `secretary` o `treasurer`.

## Gaps y pendientes

- **Sin UI en app**: Correcto por diseno — la app no necesita interfaz de administracion de RBAC
- **Permisos directos a usuarios**: `users_permissions` entra en `effective.permissions` y en el set global del PermissionsGuard. Mutar esos grants es `super-admin`.
- **Auditoria de matriz**: las mutaciones de `role_permissions` y `users_permissions` escriben `audit_logs` de dominio (`source: service`) con actor y `changes`. Las de `users_roles` (roles globales) y las de cargos de club escriben evento crítico dentro de la transacción (ver secciones siguientes). CRUD de catalogo de permisos/roles queda en el interceptor HTTP generico.
- **`audit:read`**: solo `super-admin`. El wildcard de `admin` (todo excepto `:delete`) excluye este permiso. Protege `GET /admin/audit-logs` y `GET /admin/audit-logs/:id`. El historial de club (`GET /clubs/:clubId/history`) sigue en `clubs:read`.
- **OR `users:*`**: sunset documentado `2027-03-31`; el fallback sigue encendido.
- **PermissionsGuard es APP_GUARD**: un endpoint JWT nuevo sin `@RequirePermissions`, `@SkipPermissions` o `@Public` responde `GUARD_RBAC_MISCONFIGURATION`.

## Prioridad y siguiente accion

- **Prioridad**: Baja — feature funcional en backend, admin y app movil
- **Siguiente accion**: El 2027-03-31 apagar el OR `users:*` para terceros y exigir el permiso fino de familia.
