# Diseño: catálogo de capacidades por pantalla (admin)

**Fecha:** 2026-09-15 (revisado 2026-09-15 contra código)  
**Estado:** OLEADAS 1, 2, 2b, 2c y 2d IMPLEMENTADAS (2026-09-15) — residuos menores y oleada 3 pendientes  
**Alcance:** panel admin primero; app móvil después, mismas claves API  
**No toca:** nombres de permisos `resource:action`, `PermissionsGuard`, schema de grants, territorio

El administrador asigna **qué se puede hacer en cada pantalla**. El sidebar, los botones y la matriz de roles leen **un solo registro**. El API sigue fall-closed con las mismas claves.

---

## Qué revisar primero

1. Decisión: catálogo de pantallas en código, no permisos nuevos por pantalla.
2. Endpoints `/admin/*`: se mantienen; decisión (a)/(b) para `admin-users`.
3. Ejemplo Usuarios (tabla de capacidades con `roles`).
4. Matriz: checkbox “pantalla completa” + verbos; `viewAny` se marca solo; bundle vía `PUT`.
5. Fuera de alcance y oleadas.

---

## Decisión

Hay **tres mapas** que se desalinean:

| Mapa | Hoy | Problema |
|------|-----|----------|
| Sidebar / `requirePageAccess` | `NAV_ITEM_ACCESS` | Alineado a `viewAny` del API (cambio 2026-09-15) **salvo `users`**: falta `roles` (ver sección `/admin/*`) |
| Botones y subrutas | hooks ad hoc (`useCanManageUsers`, `ALLOWED_PAGE_ROLES`, …) | OR de roles + permiso; a veces **solo rol**, ignora el permiso real. Hoy: 2 hooks client con `hasRole`, 14 pages server con `extractRoles` |
| Picker de permisos (crear/editar rol) | `PERMISSION_GROUPS` (`permission-picker.tsx`, `roles-table.tsx`) | Grupos por recurso, incompletos (`users:create` / `users:bulk_create` no aparecen) |
| Matriz `/configuration/matrix` | `listPermissions()` del API, plana | Completa pero sin agrupar; toggle por celda (`toggleRolePermissionAction`) |
| API | `@RequirePermissions` + `@GlobalRoles` | Fuente de verdad. No se cambia |

**Elegido:** un **Screen Capability Catalog** (TypeScript en admin). Cada pantalla declara `viewAny` y la lista de verbos de UI. Cada verbo apunta a claves `resource:action` (y roles globales si el endpoint ya los exige).

No se inventan claves tipo `usuarios_pantalla:ver`. Eso rompería backend, seed, app y docs.

```
Rol  ──asigna──►  claves resource:action (DB, igual que hoy)
                      ▲
Pantalla UI  ──declara──┘  catálogo (código)
   ├─ sidebar / page gate = viewAny
   └─ botón / tab / subruta = capability.gate
```

---

## Alternativas descartadas

| Opción | Por qué no |
|--------|------------|
| **A.** Renombrar permisos a `pantalla:verbo` | Rompe API, seed, Flutter, matriz histórica. Costo alto, ganancia nula en enforcement |
| **B.** Pantallas como filas en DB | El menú vive en código. Dos fuentes. Quien agrega ruta olvida el seed |
| **C.** Seguir con 3 mapas | Es el dolor actual: sidebar bien, botón mal, matriz incompleta |

---

## Modelo

### Pantalla

Unidad que el operador reconoce: ítem de sidebar (o hub con tabs). `id` = `id` del nav.

```ts
type NavAccess = {
  permissions: string[];      // resource:action
  roles?: string[];           // @GlobalRoles / aliases ya documentados
  requireAll?: boolean;       // default false = OR
};

type ScreenCapability = {
  id: string;                 // estable: "users.create"
  labelKey: string;           // i18n
  kind: "button" | "tab" | "route" | "section";
  gate: NavAccess;            // mismo contrato que el nav
  href?: string;              // kind: "route"
};

type ScreenDefinition = {
  id: string;                 // "users"
  path: string;               // "/dashboard/users"
  surfaces: Array<"admin" | "app">;
  viewAny: NavAccess;         // entrar / ver en sidebar
  capabilities: ScreenCapability[];
};
```

`bundleKeys(screen)` = unión de `viewAny.permissions` + `capability.gate.permissions`. Eso es lo que marca **pantalla completa**.

`gate.roles` **copia literal** el `@GlobalRoles` del endpoint (clase o método, el método pisa a la clase — `getAllAndOverride`). El evaluador expande alias igual que `GLOBAL_ROLE_ALIASES` del backend (`admin` ⇒ `assistant-admin`; `coordinator` ⇒ `zone-coordinator`, `general-coordinator`; cualquier rol de campo ⇒ los seis roles lf/union/dia). Hoy `canAccessDashboardPath` hace match exacto; el catálogo trae la tabla de alias al admin.

`surfaces` es metadato para el operador y para tests. Flutter no importa TS: la app consume claves, no el catálogo (ver oleada 3).

### Entrar a la pantalla

Sidebar y `requirePageAccess` usan **solo** `viewAny`.

Un verbo (crear, exportar) **no** enseña la pantalla por sí solo. Si el rol debe entrar, se le da `viewAny` (casi siempre `*:read`).

Excepción ya existente: hubs (órdenes de pago). `viewAny` = OR de los `viewAny` de cada tab. El catálogo lo declara explícito; no se infiere.

### Territorio

Sigue fuera del catálogo. Ver la pantalla no implica ver todos los registros. El API recorta por alcance.

### Super-admin

Sigue bypass de UI. El API puede seguir exigiendo permisos puntuales en endpoints especiales (igual que hoy).

---

## Endpoints `/admin/*` y `@GlobalRoles` a nivel clase

Verificado en `sacdia-backend/src/admin/`: 8 de 9 controladores llevan `@GlobalRoles('admin', 'super-admin')` **en la clase** (`admin-users`, `admin-reference`, `admin-geography`, `admin-honors`, `admin-phase-e-catalogs`, `admin-camporee-event-types`, `admin-notifications`, `admin-cron-alerts`; también `member-ranking-weights`, `admin-achievements`). Con alias, solo `admin`, `assistant-admin`, `super-admin` pasan. El panel deja entrar a 13 roles (`ALLOWED_ADMIN_ROLES`), incluidos los seis roles de campo, coordinadores y pastor.

**Se mantienen.** No se mueven ni renombran. Razones:

- Son la cerca gruesa de "quién opera esta zona del API"; los permisos son el grano fino. Dos capas, ambas fall-closed.
- El sidebar ya modela esto para catálogos: `catalogEditorAccess(permisos)` = permiso **y** `CATALOG_EDITOR_ROLES`. El catálogo generaliza ese patrón: si el controlador tiene `@GlobalRoles` en clase, `viewAny.roles` lo declara. Regla ya escrita en `docs/canon/auth/modelo-autorizacion.md` (permiso amplio + `@GlobalRoles` ⇒ el panel no ofrece la pantalla solo por el permiso).
- La cerca de rol hace que un grant de permiso a un rol custom **no surta efecto** en `/admin/*` salvo que el rol sea admin. Es una limitación conocida de la matriz, no un bug del catálogo. Se documenta en la UI de la matriz ("requiere rol admin en el API") por pantalla, leyendo `viewAny.roles`.

**Excepción a resolver en oleada 1 — `admin-users`:**

| Endpoint | Roles efectivos | Permiso |
|----------|-----------------|---------|
| `GET /admin/users` (L78) | clase: admin, assistant-admin, super-admin | `users:read` |
| `GET /admin/users/:id` (L147) | clase: ídem | `users:read_detail` |
| `PATCH /admin/users/:id` (L234) | clase: ídem | `users:update_admin` |
| `POST /admin/users` (L252) | método: admin + los seis de campo | `users:create` |
| `POST /admin/users/bulk` (L290) | método: ídem | `users:bulk_create` |

Inconsistencia real: director-lf **puede crear** pero **no puede listar ni abrir ficha**. El seed ya le da `users:create`/`users:bulk_create` (heredado desde `assistant-lf`). Con la regla "verbo no enseña pantalla", el catálogo escondería Usuarios a los roles de campo y el botón Alta con él.

Decisión tomada **2026-09-15: opción (a), ya aplicada en backend.**

- **(a) Ampliar** `GET /admin/users` y `GET /admin/users/:userId` con `@GlobalRoles` de método igual al de `POST` (los seis de campo + admin). Seguro: `AdminUsersService.listUsers` / `getUserById` ya recortan por territorio (`resolveScope` + `buildScopeWhere`, L503-L548). Habilita el ejemplo "director de unión solo ficha". **Hecho**: constante `USER_MANAGEMENT_ROLES` exportada en `admin-users.controller.ts`, aplicada a list, detail, bulk-template, create y bulk; test de metadata en `admin-users.controller.spec.ts`; `ENDPOINTS-LIVE-REFERENCE.md` y `docs/features/rbac.md` actualizados.
- ~~(b) Mantener la cerca admin en lectura y quitar a los roles de campo de `POST users` / `POST users/bulk`.~~ Descartada.

Con (a) aplicada: `users.viewAny = { permissions: ['users:read'], roles: USER_MANAGEMENT_ROLES }`. `PATCH users/:userId` y `approval` siguen admin-only ⇒ `users.update_admin.gate.roles = ['admin','super-admin']`. Fase 1 ya no tiene dependencia de backend pendiente.

Rumbo largo (fuera de alcance, oleada ≥ 3): donde el servicio ya recorta por territorio, la cerca de clase puede bajar a método o retirarse y dejar el permiso como único gate. Eso hace que la matriz sea efectiva para roles custom. Un controlador por PR, con test de scope.

---

## Ejemplo canónico: Usuarios

Hoy el drift es medible:

| Superficie | Qué usa | API real |
|------------|---------|----------|
| Sidebar | `users:read`, sin roles | `GET` listado: `users:read` **y** rol admin (clase) |
| Picker de rol | `read`, `read_detail`, `update_profile`, `update_admin` | Faltan `create` y `bulk_create` |
| Toolbar alta / carga (`useCanManageUsers`) | `users:create` **o** lista fija de 8 roles | `users:create` **y** `@GlobalRoles` de método |
| `/users/new` y `/users/bulk-upload` (`ALLOWED_PAGE_ROLES`) | **solo roles** | Permisos anteriores |

Con el catálogo (`roles` = espejo literal del `@GlobalRoles` efectivo; `ADMIN` = `['admin','super-admin']`, `FIELD` = los seis roles lf/union/dia):

| Capability | UI | `gate` |
|------------|----|--------|
| *(viewAny)* | Sidebar + listado | `users:read` + `roles: ADMIN ∪ FIELD` (= `USER_MANAGEMENT_ROLES`, opción (a) aplicada) |
| `users.view_detail` | Abrir ficha | `users:read_detail` + `roles: ADMIN ∪ FIELD` |
| `users.create` | Botón alta + `/users/new` | `users:create` + `roles: ADMIN ∪ FIELD` |
| `users.bulk_create` | Botón carga + `/users/bulk-upload` + plantilla | `users:bulk_create` + `roles: ADMIN ∪ FIELD` |
| `users.update_profile` | Editar perfil | `users:update_profile` |
| `users.update_admin` | Editar admin / aprobación | `users:update_admin` + `roles: ADMIN` |
| `users.health.read` | Sección salud | `health:read` **OR** `users:read_detail` (OR legado vigente; mismo set que `authorization_utils.dart`) |
| `users.health.update` | Editar salud | `health:update` **OR** `users:update_profile` |
| … familias `emergency_contacts`, `legal_representative`, `post_registration` | igual | `<familia>:read` OR `users:read_detail`; `<familia>:update` OR `users:update_profile` |
| `users.registration.complete` | Completar post-registro | `registration:complete` |
| `users.roles.assign` | Asignar roles globales | `roles:assign` (si la ficha lo expone) |

Regla: el gate de familia copia el OR que el API acepta hoy. Cuando backend haga sunset del legado, se quita la clave de `users:*` del gate en el mismo PR.

**Director de unión “solo ficha”:** `users:read` + `users:read_detail`. Sin create/bulk/update. Sigue viendo el listado (filtrado por territorio). Habilitado por la opción (a), ya aplicada. No hay modo “solo deep-link” en esta oleada: el detalle se alcanza desde la lista.

Quitar el OR de roles en toolbar y páginas new/bulk; pasa a **AND** (permiso y rol), como el API. Seed verificado: `users:create`/`users:bulk_create` están en `assistant-lf` y se heredan a director-lf, assistant/director-union, assistant/director-dia (`role-permissions.seed.sql:1519-1524`); admin y super-admin por wildcard. Nadie seedeado pierde el botón. Un rol custom con la clave pero fuera de `FIELD ∪ ADMIN` no ve el botón — correcto, el API le daría 403.

---

## Matriz de roles (UX)

Agrupar por **pantalla**, no por recurso suelto.

```
Usuarios                         [pantalla completa]
  ☑ Ver listado                  ← viewAny (users:read)
  ☐ Ver ficha
  ☐ Alta
  ☐ Carga masiva
  ☐ Editar perfil
  ☐ …
```

Reglas:

1. **Pantalla completa** marca/desmarca todo el bundle.
2. Marcar un verbo **marca** `viewAny` (sin listado no hay botón útil).
3. Desmarcar `viewAny` **desmarca** todos los verbos.
4. Claves que aparecen en varias pantallas (ej. `roles:assign`, `users:read_detail` en familias) se muestran en cada una; asignar es la misma fila en DB. La UI puede mostrar “también en Roles” sin duplicar el grant.
5. Permisos huérfanos (en seed, sin pantalla) van a un grupo **Otros** al final, para no perder enforcement.
6. Si `viewAny.roles` está definido, la pantalla muestra aviso “el API exige rol: admin” — el grant solo surte efecto en roles que lo cumplan.

Escritura:

- Toggle de una celda sigue por `toggleRolePermissionAction` (`POST/DELETE /rbac/roles/:id/permissions`).
- **Pantalla completa** y cascadas (reglas 1-3) tocan N claves. Se hacen con **una** llamada a `PUT /rbac/roles/:id/permissions` (existe, `rbac.controller.ts:217`, `permissions:assign`) con el set final. No N toggles secuenciales: fallo a medias dejaría estado inconsistente.
- El catálogo habla en claves (`resource:action`); la matriz en `permission.id`. Se construye `keyToId` desde `listPermissions()` una vez por render. Clave del catálogo sin id en el API ⇒ se muestra deshabilitada con aviso, no se oculta.

`PERMISSION_GROUPS` deja de ser la fuente de `permission-picker.tsx` y `roles-table.tsx`; la matriz `/configuration/matrix` deja de ser plana. Ambas se generan desde el catálogo + huérfanos.

---

## Runtime admin

| Consumidor | Lee |
|------------|-----|
| `filterSidebarItems` | `screen.viewAny` |
| `requirePageAccess(path)` | `screen` cuyo `path` cubre la ruta |
| Botón / tab / subruta | `capability.gate` vía helper `canCapability(screenId, capabilityId)` |
| Matriz | `bundleKeys` + labels i18n |

Un helper, no N hooks con listas de roles distintas.

Dos formas del mismo evaluador, una sola lógica:

- `canCapability(user, screenId, capabilityId)` — **función pura** (`AuthUser` → boolean). La usan pages y layouts server (`requireAdminUser` + `extractPermissions`/`extractRoles`, como hoy `canAccessDashboardPath`) y las 14 pages con `extractRoles` sueltos.
- `useCanCapability(screenId, capabilityId)` — hook delgado sobre `usePermissions`, para toolbar y botones client.

Si solo existe el hook, las pages server siguen con listas de roles a mano.

Subrutas (`/dashboard/users/new`) se registran como `kind: "route"` de la pantalla padre. El page gate de esa URL es la capability, no el `viewAny` del listado. Orden de resolución explícito: (1) `href` exacto de una capability `route`, (2) `path` de pantalla por prefijo más largo, (3) fail closed. `EXTRA_PATH_ACCESS` desaparece: sus entradas pasan a `route` de la pantalla correspondiente.

---

## Dónde vive

| Qué | Dónde | Dueño |
|-----|-------|--------|
| Catálogo TS | `sacdia-admin/src/lib/auth/screen-catalog/` — **un archivo por familia de nav** (`users.ts`, `clubs.ts`, `catalogs.ts`, …) + `index.ts` que arma el registro. `NAV_ITEM_ACCESS` tiene ~95 entradas; con capabilities serán varios cientos, no cabe en un archivo | Cursor (admin) |
| Alias de roles | `screen-catalog/role-aliases.ts`, copia de `GLOBAL_ROLE_ALIASES` del backend con test de igualdad contra `sacdia-backend/src/common/guards/global-roles.guard.ts` cuando el workspace lo tenga | Cursor |
| Tests de cierre | admin vitest: ids únicos; cada hoja de sidebar tiene pantalla; ningún `route.href` colisiona con `path` de otra pantalla; cada clave del catálogo existe en `permissions.ts`; opcional cross-repo: claves ⊆ `sacdia-backend/prisma/seeds/permissions.seed.sql` (skip si no existe el path) | Cursor |
| Docs de feature | `docs/features/rbac.md` + `docs/canon/auth/modelo-autorizacion.md` + este plan | al implementar |
| `@GlobalRoles` en `GET /admin/users` y `/admin/users/:userId` | `sacdia-backend` — **hecho 2026-09-15** (`USER_MANAGEMENT_ROLES`) | — |
| Seed / `@RequirePermissions` | `sacdia-backend` | Codex, **solo** si falta una clave nueva |
| App | más tarde: mismas claves; registro Dart hermano **o** artefacto JSON generado desde el catálogo TS | Codex |

Fase 1 ya no pide cambios de backend: el ajuste de `/admin/users` está aplicado. Las claves (`users:create`, `users:bulk_create`) ya existen en controller y seed; no se crean permisos nuevos.

---

## Cómo se agrega una pantalla nueva

Checklist (el test lo hace obligatorio):

1. Endpoint: `@RequirePermissions` (+ `@GlobalRoles` si aplica). Documentar en `ENDPOINTS-LIVE-REFERENCE.md`.
2. Constante en `permissions.ts`.
3. Entrada en el catálogo: `viewAny` = el `viewAny` del listado; una capability por botón/tab/ruta.
4. Ítem de sidebar con el mismo `id`.
5. UI: `canCapability(...)` — cero listas de roles sueltas.
6. Strings i18n de la matriz (4 idiomas).
7. Si el verbo no tiene clave API: **no** se muestra. Handoff a Codex para crearla.

---

## Oleadas

| Oleada | Qué | Qué no |
|--------|-----|--------|
| **0** | Hecho: `NAV_ITEM_ACCESS` = `viewAny` del API, salvo `users` (falta `roles`) | — |
| **0b** | Hecho 2026-09-15: opción (a) en `/admin/users` (`USER_MANAGEMENT_ROLES` en list/detail) | — |
| **1** ✅ | Tipos + alias + catálogo con `viewAny` migrado 1:1 desde `NAV_ITEM_ACCESS` (+ `roles` en `users`). Usuarios: capabilities cableadas (toolbar, new, bulk, ficha, familias). Picker y matriz agrupados por pantalla para esas claves; bundle vía `PUT`. `EXTRA_PATH_ACCESS` → routes | No reescribir todas las pantallas |
| **2** | Resto de pantallas, una familia por PR (clubes, materiales, camporees, …). Retirar las 14 `extractRoles` sueltas y `useCanManageUsers` | No app |
| **3** | App: registro Dart hermano con las mismas claves **o** `screen-catalog.json` generado desde TS y copiado como asset; test de claves compartidas en ambos repos. Opcional backend: bajar cerca de clase a método en `/admin/*` donde el servicio ya recorta territorio | No rediseño de grants |

`NAV_ITEM_ACCESS` desaparece cuando el catálogo lo sustituye (oleada 1). Hasta entonces el catálogo puede reexportar el mapa actual para no duplicar.

---

## Estado de implementación (oleada 1, 2026-09-15)

Archivos (`sacdia-admin/src/lib/auth/screen-catalog/`): `types.ts`, `role-aliases.ts`, `evaluate.ts`, `index.ts`, `matrix-plan.ts`, `screen-title.ts`, `use-screen-access.ts`, `screens/{_helpers,home,users,clubs,investiture,operations,campamentos,notifications,catalogs,admin-system}.ts`, tests `screen-catalog.test.ts` y `matrix-plan.test.ts`.

Hecho:

- `NAV_ITEM_ACCESS` y `EXTRA_PATH_ACCESS` eliminados; `sidebar-item-access.ts` es adaptador sobre `getScreenViewAny`. `require-page-access.ts` resuelve por catálogo.
- `path` de pantalla opcional: se toma de la `url` del sidebar con el mismo `id`. Test exige que toda pantalla resuelva path y que toda hoja del sidebar tenga pantalla.
- Alias de roles (`GLOBAL_ROLE_ALIASES`) en sidebar, page gate y capabilities; test compara con `global-roles.guard.ts`.
- Usuarios: `useCanManageUsers` y `ALLOWED_PAGE_ROLES` eliminados; toolbar, `/users/new`, `/users/bulk-upload` y ficha (MFA = `update_admin`, familias = `*.read`) usan `canCapability`.
- Picker (`permission-picker.tsx`) y matriz (`permissions-matrix.tsx`) agrupan por pantalla con `groupByScreen`; huérfanos en "Otros permisos"; aviso de rol requerido por pantalla. Matriz: checkbox "Pantalla completa" tri-estado y cascadas (`planToggle`/`planBundle`) con un solo `PUT` (`setRolePermissionsAction`).
- i18n: `rbac.pages.matrix.{fullScreen,otherGroup,requiresRoles,bundleUpdatedTitle,bundleUpdatedDesc}`, `rbac.permissionPicker.{otherGroup,requiresRoles}`, `rbac.permissions.{users:create,users:bulk_create}` en es/en/fr/pt-BR; `messages.d.ts` regenerado.
- Corrección: `catalogs-club-ideals` / `catalogs-club-types` usaban claves inexistentes (`club_ideals:read`, `club_types:read`); ahora `catalogs:read` + admin, como el API.

## Estado de implementación (oleada 2, 2026-09-15)

- `CapabilityGate = NavAccess & { exactRoles?: boolean }`. `exactRoles: true` solo para reglas que viven en un *servicio* con comparación literal de `role_name` (no pasan por `GlobalRolesGuard`, no expanden alias). Primer uso: `clubs.designate_director` ↔ `ALLOWED_DESIGNATION_ROLES` de `director-designation.service.ts`.
- Capabilities nuevas: `clubs.manage_roles` (`club_roles:assign`), `clubs.designate_director` (`club_roles:assign` + exactRoles super-admin/admin/director-lf/assistant-lf); `admin-system-roles.manage`, `admin-system-permissions.manage`, `admin-system-matrix.write` (todas `permissions:assign` + `@GlobalRoles('super-admin')`, como `RbacController`); `user_grants` comparte ese gate.
- `extractRoles` sueltos retirados de: `configuration/{permissions,roles,roles/new,roles/[roleId],matrix,audit}`, `rbac/user-permissions`, `clubs/[id]` y el server action `designateClubSectionDirectorAction`. Módulo `director-succession.ts` (+test) eliminado: quedó sin consumidores.
- Se conservan a propósito (no son espejo de un decorador): `investiture/pipeline` (`resolveUserRole` elige variante de vista), `users/new` (`resolveAllowedRoles` = jerarquía de roles creables), `evidence-folders` → `EvaluationClientPage.currentUserRoles` (regla de servicio `confirm-union` director-union/assistant-union **sin** bypass de super-admin), `succeedClubSectionDirectorAction` (regla solo-UI director-lf/assistant-lf; el API no la exige). `payment-orders/page.tsx` no se tocó: tiene cambios locales en curso ajenos a este trabajo.
- Títulos: `getScreenTitle` prueba `titleKey` → alias `NAV_KEY_BY_SCREEN_ID` → `snake_case(id)` contra `nav.items`; 15 pantallas siguen con título literal del sidebar (lista fija en `screen-title.test.ts`; agregar clave en `nav.items` o alias para sacarlas).
- `roles-table.tsx` (popover de permisos) agrupa por pantalla. `PERMISSION_GROUPS` eliminado de `permissions.ts`.

### Materiales y camporees (2026-09-15, mismo día)

- **Materiales** (módulo solo-permiso, sin `@GlobalRoles`): `materials-inbox.{approve,deliver}`, `materials-inventory.manage`, `materials-categories.manage`, `materials-receipts.validate`, `admin-local-field-{payment-methods,delivery}.configure`. `materials-receipts.viewAny` pasó de `materiales:read` a `materiales:validate-receipt` (la página ya exigía el verbo; el sidebar mostraba un ítem inusable). 8 pages de materiales/configuración usan `canViewScreen`/`canCapability`.
- **Camporees**: `campamentos-list-{local,union}` comparten `CAMPOREE_DETAIL_CAPABILITIES` (`create/update/delete`, `events.*`, `orders.configure_offering`, `supplies.*`); `campamentos-plantillas.{create,update,delete}`; `campamentos-judges.manage`; `campamentos-pedidos-catalogo.manage`; `campamentos-pedidos-bandeja.{review,authorize_without_proof,deliver}` (dueño de los verbos de pedido aunque el detalle se renderice en otra pestaña); tipos de evento `{create,update,delete}` = `camporee_event_types:*` + rol admin, compartidos por `catalogs-camporee-event-types` y `admin-campamentos-config-*`. `camporeeScreenId(kind)` para componentes que viven en ambos detalles.
- **Cambio de comportamiento (espejo del API)**: la UI hacía `camporee_events:* OR camporees:*` para eventos y `camporee_event_types:* OR catalogs:*` para tipos; el API solo acepta la primera clave de cada par. El seed da `camporees:create` a 5 roles y `camporee_events:create` a 2 → esos 3 roles dejan de ver botones que devolvían 403. Jueces: entrada solo con `camporee_events:read` (antes también `camporees:read`), como `GET */judges`.
- **Asignar jueces (oleada 2c)**: `canManageCamporeeJudgeAssignments` se sustituyó por `canCapability(user, camporeeScreenId(kind), "events.update")`. El API exige exactamente `camporee_events:update` (`camporee-scoring.controller.ts` POST judges / POST judge-assignments / PATCH+DELETE assignments y judges; el servicio `assertCanManageCamporeeJudge` en `:796-803` revalida el mismo permiso, sin fallback por rol — las lecturas de `role_name` en `:86/:102/:254` pueblan candidatos). Roles LF/Unión sin el permiso dejan de ver el botón (antes 403); el seed ya lo otorga a `assistant-lf`/`director-lf`/`assistant-union`/`director-union`.
- **Roles CLUB y eventos: no sembrar `camporee_events:{create,update,delete}`.** `POST /camporees` crea un camporee de campo local (`local_camporees`, `camporees.service.ts:452` + `assertCanManageLocalField`), no un evento de club. No existe ruta `clubs/:id/events`; las mutaciones viven en `local-camporees/:id/events` y `union-camporees/:id/events` (`camporee-events.controller.ts:93` y equivalente unión). El restore del seed (`role-permissions.seed.sql:2011`, “LF/Unión manage events”) es GLOBAL; a roles CLUB solo se les da `camporee_events:read` para el detalle móvil (`:2265-2282`). El mapping “a sembrar” de `docs/features/camporee-events.md` (director/subdirector club con create/update) quedó como diseño no aplicado; no se concede ahora.
- `CAMPOREE_SUPPLIES_{CONFIGURE,REVIEW_PAY,DELIVER}` centralizados en `permissions.ts` (`types/camporee-supplies.ts` reexporta). Tests de `camporee-order-review` y `camporee-supplies-tab` dejaron de mockear `hasPermission` y pasan permisos efectivos reales.

## Estado de implementación (oleada 2c, 2026-09-15)

- Jueces: `events.update` del detalle sustituye a `canManageCamporeeJudgeAssignments`. Sin OR de `camporees:update` ni fallback por rol.
- Seed de `camporee_events:{create,update,delete}` para roles CLUB: **no**. Eventos son de camporee local/unión.
- `confirm-union` y sucesión anual LF siguen fuera del catálogo. Decisión abierta en `docs/audit/DECISIONS-PENDING.md`.

### Oleada 2d — cuatro familias en paralelo (2026-09-15, subagentes Grok 4.6; brief en `docs/plans/2026-09-15-screen-catalog-oleada-2d-familias.md`)

Preparación: `screens/catalogs.ts` dividido en `catalogs-geography.ts` y `catalogs-domain.ts`; `catalogs-certifications` movido a `investiture.ts`. Un archivo de pantallas y un test por agente; docs y archivos compartidos los consolidó el orquestador.

- **Investidura / inscripciones / certificaciones GM** (`investiture.ts`): `enrollments.validate`; `investiture-pending.{validate,mark_invested}`; `investiture-pipeline.{club_approve,coordinator_approve,field_approve,invest,reject,bulk_approve,bulk_reject}` (cada etapa con su `@GlobalRoles` real; se retiró el `userRole` ad hoc del pipeline); `investiture-config.{create,update,delete}`; `certifications-list.manage`; `certifications-reviews.{approve,request_changes,certify}`; `certificate-bulk-imports.{approve,reject}`; `catalogs-certifications.{configure,publish}`. Constantes `INVESTITURE_*`, `INVESTITURE_CONFIG_*` añadidas. Visible: coordinator con `investiture:validate` pierde "Marcar investido" y `field_approve` individual (API 403); admin pierde desactivar config (`investiture_config:delete` solo super-admin).
- **Seguros / finanzas / inventario** (`operations.ts`): `finances.{create,update,delete}`, `club-inventory.{create,update,delete}`, `insurance-by-section.{create,update,delete}` (`delete` = PATCH `active=false`, no existe `insurance:delete`), `insurance-config.{configure,configure_payment_instructions}` (tabs). **`insurance-expiring.viewAny` cambió** de `insurance:read` a rol `admin`/`coordinator` (el GET es `@GlobalRoles('admin','coordinator')` + `@SkipPermissions`): director-lf, pastor y roles de club dejan de ver Vencimientos (el API ya les daba 403). `INSURANCE_CREATE/UPDATE` añadidas.
- **Catálogos geografía / taxonomía club** (`catalogs-geography.ts`): `create/update/delete` en 8 pantallas espejo de `admin-geography.controller.ts` y `admin-reference.controller.ts`. **`viewAny` cambió** en distritos (`districts:read` → `local_fields:read`) y divisiones (solo `countries:read`). Visible: `admin` pierde Crear/Eliminar en ideales y tipos de club (método `@GlobalRoles('super-admin')`); distritos escriben con `local_fields:update`/`:delete`.
- **Catálogos dominio** (`catalogs-domain.ts`): `create/update/delete` en 13 pantallas (`catalogs:*`, `honor_categories:*`, `honors:*`, `ecclesiastical_years:*`). 10 claves del OR viejo (`allergies:*`, `classes:manage`, `finance_categories:manage`, …) nunca estuvieron sembradas: letra muerta. Visible: `admin` pierde Eliminar en años eclesiásticos (`ecclesiastical_years:delete` solo super-admin). `ECCLESIASTICAL_YEARS_DELETE` añadida.
- Orquestador: `lib/generic-catalogs-i18n/actions.ts` (factoría de 13 catálogos) pasó de `CrudPermissions` con OR a `screenId` + `canCapability(user, screenId, verbo)`; test `catalog CRUD screens` fija que 22 pantallas de catálogo declaren `create/update/delete`; `requirement-review-tray.test.tsx` mockea `useAuth` con permisos efectivos.
- Suite completa admin: **945/945**.

Pendiente al cierre de 2d (residuos, ~20 gates): `clubs/activities`, `configuration/notifications/*`, `resources/*`, `coordination`, y actions `notifications`, `camporee-events` (15, venues), `resources`, `phase-e-catalogs` (master honors: `MASTER_HONORS_MANAGE || CATALOGS_*`, sin pantalla en sidebar). `payment-orders/page.tsx` fuera por WIP local. Oleada 3 (app) sin cambios.

## Estado de implementación (residuos 0–4, 2026-09-15)

- **Bloque 0 — payment-orders.** El WIP local de tabs se cerró migrándolo al catálogo (3 tabs reales, no 4): `pending` = hub GET `/payment-obligations/pending` (`payment-obligations.controller.ts:25-34` mode `any`: `camporee-orders:read` | `camporee-supplies:read` | `field-payment-orders:read` | `materiales:read`); `orders` = list `:read` OR review-queue `:review`; `reassignments` = `insurance:read`. `viewAny` sigue siendo la unión. La page pasa booleans de `canCapability` al client.
- **Bloque 1 — pages/actions ad hoc.** `activities.{create,update}` (no `delete` propio: la UI borra detrás de `update`; ClubRoles de escritura queda API-side). `notifications-hub.{send_direct,broadcast,send_club}` y actions. `resources-list`/`resources-categories` CRUD (permission-only; recorte territorial sigue en `assertResourceTerritory`). `coordination.viewAny` ahora exige también los `@GlobalRoles` de clase (`USER_MANAGEMENT_ROLES`). Visible: pastor (u otro rol fuera de esa lista) con `coordination:manage` deja de ver Coordinación.
- **Bloque 2 — camporees.** Actions de events/templates/venues/scoring ya no aceptan `camporees:*`. Templates → `campamentos-plantillas.{create,update,delete}`; instancias → `events.*` vía `camporeeScreenId`; venues → `venues.*` (`camporee_events:*`, verificado en `camporee-venues.controller.ts`); scoring write → `events.update`; lectura leaderboard → `scoring.read` = `camporee_events:read`.
- **Bloque 3 — master honors.** Expuesto (no deep-link, no borrar actions). `catalogs-master-honors` en `catalogs-domain.ts` = `honors:{read,create,update,delete}` + `catalogEditorAccess` (`admin-phase-e-catalogs.controller.ts` L651-722). Sidebar hoja bajo Especialidades. Page `PhaseECatalogCrudPage` + extras (honors/categorías/divisiones; fallos de extras no bloquean el listado). Actions y recalc → `canCapability(..., "update")`. Mismas claves que `catalogs-honors` (un grant, dos pantallas). Se retiró `master_honors:manage`.
- **Bloque 4 — app Flutter.** Opción B: `lib/core/authorization/` hermano de `evaluateAccess` + alias. Quick access y tabs Clases/Actividades por `screenId`. `coordinator-hub` ≠ admin `coordination`. Fixture de paridad en `test/fixtures/screen-catalog.snapshot.json`.
- **Pendiente:** bloque 5 commits.

---

## Fuera de alcance

- Renombrar o fusionar permisos del API.
- Mover o renombrar controladores `/admin/*`; retirar `@GlobalRoles` de clase en general (solo el ajuste puntual de `admin-users` si se elige (a)).
- Guardar pantallas en Postgres.
- Permiso DB `screen:users:full` — el checkbox es azúcar de UI.
- Cambiar recorte territorial.
- Rehacer seed de todos los roles en el mismo PR (oleada 1: Usuarios + roles que deban seguir creando gente).
- iOS/Android en oleada 1.

---

## Riesgos

| Riesgo | Mitigación |
|--------|------------|
| Catálogo desactualizado vs API | Test: claves ⊆ constantes (+ seed cross-repo); revisión en el PR de endpoint |
| `gate.roles` desalineado con `@GlobalRoles` de clase | Checklist de pantalla nueva exige leer el controlador, no solo el método; test de alias contra el guard |
| Rol que hoy crea usuarios **por rol** pierde el botón | Seed verificado: los ocho roles de `ROLES_ALLOWED_TO_CREATE_USERS` tienen la clave. Riesgo cerrado |
| Bundle a medias en la matriz | `PUT /rbac/roles/:id/permissions` con set final; una sola llamada |
| Alias copiados a mano divergen del backend | Test de igualdad con `global-roles.guard.ts`; si no está el workspace, skip con aviso |
| Misma clave en dos pantallas, operador se confunde | Nota “también en…”; un solo grant |
| Oleada 2 eterna | Definition of done por familia de nav, no “todo el panel” |

---

## Criterio de éxito (oleada 1)

- Quien no tiene `users:read` (o no cumple `viewAny.roles`) no ve Usuarios en el sidebar ni abre `/dashboard/users`.
- Quien tiene `users:read` y no `users:create` **no** ve Alta ni Carga masiva (hoy a veces sí, por rol).
- Quien tiene `users:create` **y** rol en `FIELD ∪ ADMIN` ve Alta; `/users/new` no se abre por rol sin permiso ni por permiso sin rol.
- assistant-admin ve lo mismo que admin (alias), sin listarlo a mano.
- Picker de rol y matriz de Usuarios listan create y bulk_create; “pantalla completa” hace una sola llamada `PUT`.
- `EXTRA_PATH_ACCESS` eliminado; `require-page-access.test.ts` sigue en verde.
- `pnpm` tests del catálogo + sidebar en verde.
- Sin build de producción.

---

## Aprobación

Marcar al revisar:

- [ ] Catálogo en código, claves API intactas
- [ ] `viewAny` ≠ verbo; verbo no enseña la pantalla
- [ ] `gate.roles` espejo literal de `@GlobalRoles` (clase o método) + alias del backend
- [ ] Endpoints `/admin/*` se mantienen; cerca de rol declarada en `viewAny.roles`
- [x] `/admin/users`: opción (a) ampliar lectura a roles de campo — aplicada 2026-09-15
- [ ] Director unión: listado + ficha, sin alta
- [ ] Picker + matriz por pantalla + “pantalla completa” vía `PUT`
- [ ] Helper puro + hook, no solo hook
- [ ] Oleada 1 = Usuarios + sustituir `NAV_ITEM_ACCESS` y `EXTRA_PATH_ACCESS`; resto después
- [ ] App fuera de oleada 1; mecanismo (registro hermano vs JSON) se decide en oleada 3
