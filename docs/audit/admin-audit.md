# Admin Audit — SACDIA
Fecha: 2026-03-14
Fuente: sacdia-admin/ (Next.js 16 + App Router)
Metodo: Scan automatico de codigo fuente

## Resumen
- Paginas: 37
- Endpoints consumidos: 58
- Dependencias principales: 18

---

## Paginas/Rutas

| Route | Page Component | Layout Group | Description |
|-------|---------------|-------------|-------------|
| / | src/app/page.tsx | (root) | Redirect a /dashboard |
| /login | src/app/(auth)/login/page.tsx | auth | Login con email/password via API backend |
| /dashboard | src/app/(dashboard)/dashboard/page.tsx | dashboard | Dashboard principal con stats y usuarios recientes |
| /dashboard/users | src/app/(dashboard)/dashboard/users/page.tsx | dashboard | Listado de usuarios con filtros y paginacion |
| /dashboard/users/[userId] | src/app/(dashboard)/dashboard/users/[userId]/page.tsx | dashboard | Detalle de usuario con aprobacion |
| /dashboard/clubs | src/app/(dashboard)/dashboard/clubs/page.tsx | dashboard | Listado de clubes |
| /dashboard/clubs/new | src/app/(dashboard)/dashboard/clubs/new/page.tsx | dashboard | Formulario de creacion de club |
| /dashboard/clubs/[id] | src/app/(dashboard)/dashboard/clubs/[id]/page.tsx | dashboard | Detalle de club con edicion, instancias y miembros |
| /dashboard/classes | src/app/(dashboard)/dashboard/classes/page.tsx | dashboard | Listado de clases progresivas (read-only via ModuleListPage) |
| /dashboard/honors | src/app/(dashboard)/dashboard/honors/page.tsx | dashboard | CRUD de especialidades con filtros |
| /dashboard/honors/[honorId] | src/app/(dashboard)/dashboard/honors/[honorId]/page.tsx | dashboard | Detalle de especialidad |
| /dashboard/camporees | src/app/(dashboard)/dashboard/camporees/page.tsx | dashboard | Listado de camporees (read-only via ModuleListPage) |
| /dashboard/notifications | src/app/(dashboard)/dashboard/notifications/page.tsx | dashboard | Envio de notificaciones push (directa, broadcast, club) |
| /dashboard/activities | src/app/(dashboard)/dashboard/activities/page.tsx | dashboard | Placeholder — redirige a seleccionar club |
| /dashboard/finances | src/app/(dashboard)/dashboard/finances/page.tsx | dashboard | Placeholder — redirige a seleccionar club |
| /dashboard/inventory | src/app/(dashboard)/dashboard/inventory/page.tsx | dashboard | Placeholder — redirige a seleccionar club |
| /dashboard/certifications | src/app/(dashboard)/dashboard/certifications/page.tsx | dashboard | Listado de certificaciones GM (read-only via ModuleListPage) |
| /dashboard/insurance | src/app/(dashboard)/dashboard/insurance/page.tsx | dashboard | Placeholder — modulo planificado |
| /dashboard/folders | src/app/(dashboard)/dashboard/folders/page.tsx | dashboard | Listado de carpetas de evidencias (read-only via ModuleListPage) |
| /dashboard/rbac | src/app/(dashboard)/dashboard/rbac/page.tsx | dashboard | Hub de RBAC con links a permisos, roles y matriz |
| /dashboard/rbac/permissions | src/app/(dashboard)/dashboard/rbac/permissions/page.tsx | dashboard | CRUD de permisos del sistema |
| /dashboard/rbac/roles | src/app/(dashboard)/dashboard/rbac/roles/page.tsx | dashboard | Listado de roles con asignacion de permisos |
| /dashboard/rbac/matrix | src/app/(dashboard)/dashboard/rbac/matrix/page.tsx | dashboard | Matriz interactiva roles vs permisos |
| /dashboard/catalogs | src/app/(dashboard)/dashboard/catalogs/page.tsx | dashboard | Hub de catalogos con links a cada entidad |
| /dashboard/catalogs/geography/countries | src/app/(dashboard)/dashboard/catalogs/geography/countries/page.tsx | dashboard | CRUD de paises (via CatalogEntityPage) |
| /dashboard/catalogs/geography/unions | src/app/(dashboard)/dashboard/catalogs/geography/unions/page.tsx | dashboard | CRUD de uniones (via CatalogEntityPage) |
| /dashboard/catalogs/geography/local-fields | src/app/(dashboard)/dashboard/catalogs/geography/local-fields/page.tsx | dashboard | CRUD de campos locales (via CatalogEntityPage) |
| /dashboard/catalogs/geography/districts | src/app/(dashboard)/dashboard/catalogs/geography/districts/page.tsx | dashboard | CRUD de distritos (via CatalogEntityPage) |
| /dashboard/catalogs/geography/churches | src/app/(dashboard)/dashboard/catalogs/geography/churches/page.tsx | dashboard | CRUD de iglesias (via CatalogEntityPage) |
| /dashboard/catalogs/allergies | src/app/(dashboard)/dashboard/catalogs/allergies/page.tsx | dashboard | CRUD de alergias (via CatalogEntityPage) |
| /dashboard/catalogs/diseases | src/app/(dashboard)/dashboard/catalogs/diseases/page.tsx | dashboard | CRUD de enfermedades (via CatalogEntityPage) |
| /dashboard/catalogs/relationship-types | src/app/(dashboard)/dashboard/catalogs/relationship-types/page.tsx | dashboard | CRUD de tipos de relacion (via CatalogEntityPage) |
| /dashboard/catalogs/ecclesiastical-years | src/app/(dashboard)/dashboard/catalogs/ecclesiastical-years/page.tsx | dashboard | CRUD de anios eclesiasticos (via CatalogEntityPage) |
| /dashboard/catalogs/club-types | src/app/(dashboard)/dashboard/catalogs/club-types/page.tsx | dashboard | Listado de tipos de club (read-only, allowMutations=false) |
| /dashboard/catalogs/club-ideals | src/app/(dashboard)/dashboard/catalogs/club-ideals/page.tsx | dashboard | Listado de ideales de club (read-only, allowMutations=false) |
| /dashboard/catalogs/honor-categories | src/app/(dashboard)/dashboard/catalogs/honor-categories/page.tsx | dashboard | CRUD de categorias de especialidades |
| /dashboard/catalogs/honor-categories/[categoryId] | src/app/(dashboard)/dashboard/catalogs/honor-categories/[categoryId]/page.tsx | dashboard | Detalle de categoria de especialidad |

**Total: 37 paginas** (verificado contra glob de page.tsx)

---

## Consumo de API por Pagina

| Page/Component | API Endpoints Called | Lib Module |
|---------------|---------------------|------------|
| /login | POST /auth/login, GET /auth/me | lib/auth/actions.ts |
| /dashboard | GET /admin/users?limit=1&page=1, GET /clubs?status=active&limit=1, GET /honors?limit=1, GET /classes, GET /admin/users?limit=5&page=1 | lib/api/client.ts (inline) |
| /dashboard/users | GET /admin/users (paginated) | lib/api/admin-users.ts |
| /dashboard/users/[userId] | GET /admin/users/:userId, PATCH /admin/users/:userId/approval, PATCH /admin/users/:userId | lib/api/admin-users.ts, lib/admin-users/actions.ts |
| /dashboard/clubs | GET /clubs | lib/api/client.ts (inline) |
| /dashboard/clubs/new | GET /admin/local-fields, GET /admin/districts, GET /admin/churches, POST /clubs | lib/catalogs/service.ts, lib/api/clubs.ts, lib/clubs/actions.ts |
| /dashboard/clubs/[id] | GET /clubs/:id, GET /clubs/:id/instances, POST /clubs/:id/instances, PATCH /clubs/:id/instances/:type/:instanceId, GET /clubs/:id/instances/:type/:instanceId/members, POST /clubs/:id/instances/:type/:instanceId/roles, PATCH /club-roles/:assignmentId, DELETE /club-roles/:assignmentId, PATCH /clubs/:id, DELETE /clubs/:id | lib/api/clubs.ts, lib/clubs/actions.ts, lib/catalogs/service.ts |
| /dashboard/classes | GET /classes, GET /catalogs/club-types | lib/api/classes.ts, lib/api/catalogs.ts |
| /dashboard/honors | GET /honors, GET /honors/categories, GET /catalogs/club-types, POST /honors, PATCH /honors/:id | lib/api/honors.ts, lib/api/catalogs.ts, lib/honors/actions.ts |
| /dashboard/honors/[honorId] | GET /honors/:honorId, GET /honors/categories, GET /catalogs/club-types | lib/api/honors.ts, lib/api/catalogs.ts |
| /dashboard/camporees | GET /camporees | lib/api/client.ts (via ModuleListPage) |
| /dashboard/notifications | POST /notifications/send, POST /notifications/broadcast, POST /notifications/club/:type/:id | lib/api/notifications.ts, lib/notifications/actions.ts |
| /dashboard/certifications | GET /certifications/certifications | lib/api/client.ts (via ModuleListPage) |
| /dashboard/folders | GET /folders/folders | lib/api/client.ts (via ModuleListPage) |
| /dashboard/rbac/permissions | GET /admin/rbac/permissions, POST /admin/rbac/permissions, PATCH /admin/rbac/permissions/:id, DELETE /admin/rbac/permissions/:id | lib/rbac/service.ts, lib/rbac/actions.ts |
| /dashboard/rbac/roles | GET /admin/rbac/roles, GET /admin/rbac/permissions, PUT /admin/rbac/roles/:id/permissions | lib/rbac/service.ts, lib/rbac/actions.ts |
| /dashboard/rbac/matrix | GET /admin/rbac/roles, GET /admin/rbac/permissions, PUT /admin/rbac/roles/:id/permissions | lib/rbac/service.ts, lib/rbac/actions.ts |
| /dashboard/catalogs/geography/countries | GET /admin/countries, POST /admin/countries, PATCH /admin/countries/:id, DELETE /admin/countries/:id | lib/catalogs/service.ts, lib/catalogs/entities.ts |
| /dashboard/catalogs/geography/unions | GET /admin/unions, POST /admin/unions, PATCH /admin/unions/:id, DELETE /admin/unions/:id | lib/catalogs/service.ts, lib/catalogs/entities.ts |
| /dashboard/catalogs/geography/local-fields | GET /admin/local-fields, POST /admin/local-fields, PATCH /admin/local-fields/:id, DELETE /admin/local-fields/:id | lib/catalogs/service.ts, lib/catalogs/entities.ts |
| /dashboard/catalogs/geography/districts | GET /admin/districts, POST /admin/districts, PATCH /admin/districts/:id, DELETE /admin/districts/:id | lib/catalogs/service.ts, lib/catalogs/entities.ts |
| /dashboard/catalogs/geography/churches | GET /admin/churches, POST /admin/churches, PATCH /admin/churches/:id, DELETE /admin/churches/:id | lib/catalogs/service.ts, lib/catalogs/entities.ts |
| /dashboard/catalogs/allergies | GET /admin/allergies, POST /admin/allergies, PATCH /admin/allergies/:id, DELETE /admin/allergies/:id | lib/catalogs/service.ts, lib/catalogs/entities.ts |
| /dashboard/catalogs/diseases | GET /admin/diseases, POST /admin/diseases, PATCH /admin/diseases/:id, DELETE /admin/diseases/:id | lib/catalogs/service.ts, lib/catalogs/entities.ts |
| /dashboard/catalogs/relationship-types | GET /admin/relationship-types, POST /admin/relationship-types, PATCH /admin/relationship-types/:id, DELETE /admin/relationship-types/:id | lib/catalogs/service.ts, lib/catalogs/entities.ts |
| /dashboard/catalogs/ecclesiastical-years | GET /admin/ecclesiastical-years, POST /admin/ecclesiastical-years, PATCH /admin/ecclesiastical-years/:id, DELETE /admin/ecclesiastical-years/:id | lib/catalogs/service.ts, lib/catalogs/entities.ts |
| /dashboard/catalogs/club-types | GET /catalogs/club-types (read-only) | lib/catalogs/service.ts, lib/catalogs/entities.ts |
| /dashboard/catalogs/club-ideals | GET /admin/club-ideals (read-only) | lib/catalogs/service.ts, lib/catalogs/entities.ts |
| /dashboard/catalogs/honor-categories | GET /admin/honor-categories, POST /admin/honor-categories, PATCH /admin/honor-categories/:id, DELETE /admin/honor-categories/:id | lib/api/honor-categories.ts, lib/honor-categories/actions.ts |
| /dashboard/catalogs/honor-categories/[categoryId] | GET /admin/honor-categories/:id | lib/api/honor-categories.ts |
| /dashboard/activities | Ninguno (placeholder) | — |
| /dashboard/finances | Ninguno (placeholder) | — |
| /dashboard/inventory | Ninguno (placeholder) | — |
| /dashboard/insurance | Ninguno (placeholder) | — |
| /dashboard/rbac | Ninguno (hub de navegacion) | — |
| /dashboard/catalogs | Ninguno (hub de navegacion) | — |

---

## Endpoints Unicos Consumidos

| # | Method | Path | Used By |
|---|--------|------|---------|
| 1 | POST | /auth/login | Login |
| 2 | GET | /auth/me | Login, session validation |
| 3 | PATCH | /auth/me/context | Session (ensureAuthorizationContext) |
| 4 | POST | /auth/logout | Logout |
| 5 | GET | /auth/oauth/providers | lib/api/auth.ts (available, no page confirmed) |
| 6 | DELETE | /auth/oauth/:provider | lib/api/auth.ts (available, no page confirmed) |
| 7 | POST | /auth/password/reset-request | lib/api/auth.ts (available, no page confirmed) |
| 8 | GET | /admin/users | Users list, dashboard stats |
| 9 | GET | /admin/users/:userId | User detail |
| 10 | PATCH | /admin/users/:userId/approval | User approval |
| 11 | PATCH | /admin/users/:userId | User approval (fallback) |
| 12 | GET | /clubs | Clubs list, dashboard stats |
| 13 | GET | /clubs/:id | Club detail |
| 14 | POST | /clubs | Create club |
| 15 | PATCH | /clubs/:id | Update club |
| 16 | DELETE | /clubs/:id | Delete club |
| 17 | GET | /clubs/:id/instances | Club instances |
| 18 | POST | /clubs/:id/instances | Create club instance |
| 19 | PATCH | /clubs/:id/instances/:type/:instanceId | Update club instance |
| 20 | GET | /clubs/:id/instances/:type/:instanceId/members | Club instance members |
| 21 | POST | /clubs/:id/instances/:type/:instanceId/roles | Create role assignment |
| 22 | PATCH | /club-roles/:assignmentId | Update role assignment |
| 23 | DELETE | /club-roles/:assignmentId | Revoke role assignment |
| 24 | GET | /classes | Classes list, dashboard stats |
| 25 | GET | /classes/:id | Class detail |
| 26 | GET | /classes/:id/modules | Class modules |
| 27 | GET | /honors | Honors list, dashboard stats |
| 28 | GET | /honors/:id | Honor detail |
| 29 | POST | /honors | Create honor |
| 30 | PATCH | /honors/:id | Update honor |
| 31 | GET | /honors/categories | Honor categories (for filters) |
| 32 | GET | /admin/honor-categories | Honor categories admin list |
| 33 | GET | /admin/honor-categories/:id | Honor category detail |
| 34 | POST | /admin/honor-categories | Create honor category |
| 35 | PATCH | /admin/honor-categories/:id | Update honor category |
| 36 | DELETE | /admin/honor-categories/:id | Delete honor category |
| 37 | GET | /camporees | Camporees list |
| 38 | GET | /camporees/:id | Camporee detail |
| 39 | POST | /camporees | Create camporee |
| 40 | PATCH | /camporees/:id | Update camporee |
| 41 | DELETE | /camporees/:id | Delete camporee |
| 42 | GET | /camporees/:id/members | Camporee members |
| 43 | POST | /camporees/:id/register | Register camporee member |
| 44 | DELETE | /camporees/:id/members/:userId | Remove camporee member |
| 45 | POST | /notifications/send | Direct notification |
| 46 | POST | /notifications/broadcast | Broadcast notification |
| 47 | POST | /notifications/club/:type/:id | Club notification |
| 48 | GET | /admin/rbac/permissions | RBAC permissions list |
| 49 | GET | /admin/rbac/permissions/:id | RBAC permission detail |
| 50 | POST | /admin/rbac/permissions | Create permission |
| 51 | PATCH | /admin/rbac/permissions/:id | Update permission |
| 52 | DELETE | /admin/rbac/permissions/:id | Delete permission |
| 53 | GET | /admin/rbac/roles | RBAC roles list |
| 54 | GET | /admin/rbac/roles/:id | RBAC role detail |
| 55 | PUT | /admin/rbac/roles/:id/permissions | Sync role permissions |
| 56 | DELETE | /admin/rbac/roles/:id/permissions/:permissionId | Remove permission from role |
| 57 | GET | /catalogs/club-types | Club types catalog |
| 58 | GET | /catalogs/ecclesiastical-years | Ecclesiastical years catalog |
| 59 | GET | /catalogs/countries | Countries catalog (geography.ts) |
| 60 | GET | /catalogs/unions | Unions catalog (geography.ts) |
| 61 | GET | /catalogs/local-fields | Local fields catalog (geography.ts) |
| 62 | GET | /catalogs/districts | Districts catalog (geography.ts) |
| 63 | GET | /catalogs/churches | Churches catalog (geography.ts) |
| 64 | GET | /users/:userId | User by ID (users.ts) |
| 65 | GET | /admin/countries | Admin countries CRUD |
| 66 | POST | /admin/countries | Create country |
| 67 | PATCH | /admin/countries/:id | Update country |
| 68 | DELETE | /admin/countries/:id | Delete country |
| 69 | GET | /admin/unions | Admin unions CRUD |
| 70 | POST | /admin/unions | Create union |
| 71 | PATCH | /admin/unions/:id | Update union |
| 72 | DELETE | /admin/unions/:id | Delete union |
| 73 | GET | /admin/local-fields | Admin local fields CRUD |
| 74 | POST | /admin/local-fields | Create local field |
| 75 | PATCH | /admin/local-fields/:id | Update local field |
| 76 | DELETE | /admin/local-fields/:id | Delete local field |
| 77 | GET | /admin/districts | Admin districts CRUD |
| 78 | POST | /admin/districts | Create district |
| 79 | PATCH | /admin/districts/:id | Update district |
| 80 | DELETE | /admin/districts/:id | Delete district |
| 81 | GET | /admin/churches | Admin churches CRUD |
| 82 | POST | /admin/churches | Create church |
| 83 | PATCH | /admin/churches/:id | Update church |
| 84 | DELETE | /admin/churches/:id | Delete church |
| 85 | GET | /admin/relationship-types | Admin relationship types CRUD |
| 86 | POST | /admin/relationship-types | Create relationship type |
| 87 | PATCH | /admin/relationship-types/:id | Update relationship type |
| 88 | DELETE | /admin/relationship-types/:id | Delete relationship type |
| 89 | GET | /admin/allergies | Admin allergies CRUD |
| 90 | POST | /admin/allergies | Create allergy |
| 91 | PATCH | /admin/allergies/:id | Update allergy |
| 92 | DELETE | /admin/allergies/:id | Delete allergy |
| 93 | GET | /admin/diseases | Admin diseases CRUD |
| 94 | POST | /admin/diseases | Create disease |
| 95 | PATCH | /admin/diseases/:id | Update disease |
| 96 | DELETE | /admin/diseases/:id | Delete disease |
| 97 | GET | /admin/ecclesiastical-years | Admin ecclesiastical years CRUD |
| 98 | POST | /admin/ecclesiastical-years | Create ecclesiastical year |
| 99 | PATCH | /admin/ecclesiastical-years/:id | Update ecclesiastical year |
| 100 | DELETE | /admin/ecclesiastical-years/:id | Delete ecclesiastical year |
| 101 | GET | /admin/club-ideals | Admin club ideals (read-only) |
| 102 | GET | /certifications/certifications | Certifications list |
| 103 | GET | /folders/folders | Folders list |

**Total: 103 endpoint-method combinations unicas** (58 path patterns unicos)

---

## Estado de Auth

| Route Group | Protected | Method | Notes |
|------------|-----------|--------|-------|
| (auth) /login | No | Ninguno | Pagina publica de login |
| / (root) | No | redirect | Redirige a /dashboard |
| (dashboard) /* | Si | requireAdminUser() en cada page | Llama getCurrentUser() via cookies, verifica hasAdminRole() (super_admin, admin, coordinator). Redirige a /api/auth/logout?next=/login si falla. |

**No hay middleware.ts.** La proteccion es per-page via `requireAdminUser()` en server components.

### Flujo de autenticacion

1. Login: POST /auth/login con email/password
2. Valida respuesta: verifica tokens + hasAdminRole en user del response
3. Verifica perfil: GET /auth/me con access_token
4. Si tiene rol admin: guarda access_token y refresh_token en httpOnly cookies
5. Redirige a /dashboard
6. En cada page protegida: `requireAdminUser()` lee cookie, llama GET /auth/me, verifica rol admin
7. Si falla: limpia cookies y redirige a /login
8. Logout: POST /auth/logout con refresh_token, luego limpia cookies

### Sistema de permisos

El frontend implementa verificacion granular de permisos via `hasPermission()` y `hasAnyPermission()` usando el campo `authorization.grants` del user. Los permisos se definen como constantes en `lib/auth/permissions.ts` con formato `resource:action`. Las acciones de server verifican permisos antes de ejecutar mutaciones.

---

## Dependencias Principales

| Package | Version | Purpose |
|---------|---------|---------|
| next | 16.1.6 | Framework (App Router) |
| react | 19.2.3 | UI library |
| react-dom | 19.2.3 | React DOM renderer |
| @supabase/ssr | ^0.8.0 | Supabase SSR client (no se usa directamente en pages, auth es via API backend) |
| @supabase/supabase-js | ^2.93.3 | Supabase JS client |
| @tanstack/react-query | ^5.90.20 | Server state management |
| @tanstack/react-table | ^8.21.3 | Table primitives |
| axios | ^1.13.5 | HTTP client (client-side API via interceptors) |
| radix-ui | ^1.4.3 | Headless UI primitives |
| react-hook-form | ^7.71.1 | Form management |
| @hookform/resolvers | ^5.2.2 | Form validation resolvers |
| zod | ^4.3.6 | Schema validation |
| lucide-react | ^0.563.0 | Icon library |
| recharts | ^3.7.0 | Charts (dashboard) |
| sonner | ^2.0.7 | Toast notifications |
| date-fns | ^4.1.0 | Date utilities |
| cmdk | ^1.1.1 | Command palette / combobox |
| next-themes | ^0.4.6 | Dark mode support |
| react-day-picker | ^9.13.2 | Date picker component |
| react-resizable-panels | ^4.6.5 | Resizable panel layouts |
| class-variance-authority | ^0.7.1 | Variant-based styling (shadcn/ui) |
| clsx | ^2.1.1 | Class name utility |
| tailwind-merge | ^3.4.0 | Tailwind class merging |

**Total: 22 dependencias (18 principales de runtime, 4 de styling/utility)**

---

## API Client Architecture

El admin panel usa dos clientes HTTP:

1. **`apiRequest()`** (server-side): Usa `fetch()` nativo con token resuelto desde cookies de Next.js. Base URL configurable via `NEXT_PUBLIC_API_URL`.
2. **`apiRequestFromClient()`** (client-side): Usa instancia de Axios con interceptors que redirigen a /login en 401/403.

Ambos apuntan al mismo `API_BASE_URL` (default: `http://localhost:3000/api/v1`).

---

## Notas sobre Estado de Implementacion

- **Paginas funcionales con CRUD completo**: users, clubs (con instancias y miembros), honors, honor-categories, rbac (permissions/roles/matrix), catalogs (geography, allergies, diseases, relationship-types, ecclesiastical-years)
- **Paginas funcionales read-only**: classes, camporees, certifications, folders, club-types, club-ideals
- **Paginas placeholder (sin API)**: activities, finances, inventory, insurance
- **Hub pages (navegacion)**: /dashboard/catalogs, /dashboard/rbac
- Las acciones de camporees (create, update, delete, register/remove members) existen en `lib/camporees/actions.ts` y `lib/api/camporees.ts` pero la page usa ModuleListPage (read-only). Las acciones estan disponibles para uso desde componentes internos.
- Las notificaciones no tienen listado; solo formularios de envio.
