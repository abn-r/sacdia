# Inventario actual del panel administrativo SACDIA — reestructura UI

**Estado:** DRAFT / inventario re-auditado contra código
**Fecha:** 2026-06-26
**Alcance:** `sacdia-admin/src/app`, `nav-config.ts`, RBAC frontend, rutas API internas del admin y seeds/migrations/backend docs.

## 1. Regla base de acceso

Todas las rutas bajo `/dashboard/*` pasan por `src/app/(dashboard)/layout.tsx`, que ejecuta `requireAdminUser()`.

Un usuario entra al panel solo si tiene al menos uno de estos roles administrativos globales:

- `super-admin`
- `admin`
- `coordinator`
- `zone-coordinator`
- `general-coordinator`
- `pastor`
- `assistant-lf`
- `director-lf`
- `assistant-union`
- `director-union`
- `assistant-dia`
- `director-dia`

Los roles de club puros (`director`, `secretary`, `treasurer`, `counselor`, etc.) pueden tener permisos de negocio, pero **no entran al panel administrativo si no tienen además un rol global permitido**.

La visibilidad en sidebar/command palette usa `navConfig.permission`. `super-admin` tiene bypass visual; los demás requieren el permiso exacto en `authorization.effective.permissions`.

> Hallazgo crítico: el menú usa `dashboard:view`, pero backend/seed usan `dashboard:read`. Hoy esa pantalla queda visible en menú solo para `super-admin` por bypass, aunque el layout permita a otros roles admin entrar directo a `/dashboard`.

## 2. Grupos de usuarios para diseño

| Grupo UI | Roles actuales | Lectura práctica |
|---|---|---|
| Plataforma | `super-admin`, `admin` | Administración global; `super-admin` todo, `admin` casi todo excepto deletes según seed. |
| Institucional | `assistant-lf`, `director-lf`, `assistant-union`, `director-union`, `assistant-dia`, `director-dia` | Operación territorial, clubes, reportes, evidencias, rankings, recursos. |
| Coordinación/pastoral | `coordinator`, `zone-coordinator`, `general-coordinator`, `pastor` | Lectura/supervisión parcial; no todo el menú operativo. |
| Club operativo | `director`, `secretary`, `secretary-treasurer`, etc. | Tiene permisos API/móvil, pero no panel web por sí solo. Requiere decisión si se les abrirá UI admin. |

## 2.1 Reauditoría contra el panel

Resultado verificado el 2026-06-26:

- `140` rutas `page.tsx` totales en `sacdia-admin/src/app`.
- `138` rutas pertenecen a `/dashboard/*`.
- `2` rutas son entrada/acceso del panel: `/` y `/login`.
- `73` URLs únicas en `nav-config.ts`; todas apuntan a una pantalla existente.
- `27` pantallas estáticas bajo `/dashboard` no aparecen como entrada directa del sidebar. La mayoría son `new/edit/detail`, aliases o pantallas internas, pero deben seguir inventariadas.
- `5` rutas API internas del admin no son pantallas, pero sí superficies de soporte del panel.

## 3. Matriz principal de pantallas del panel

| Sección | Pantalla | Ruta(s) | Acceso UI actual | Acciones actuales detectadas | Prioridad reingeniería |
|---|---|---|---|---|---|
| Acceso | Redirección raíz | `/` | Pública; redirige a `/dashboard` | Entrada base del producto. | Media |
| Acceso | Login | `/login` | Pública/no dashboard | Login con parámetro `next`. | Alta |
| General | Dashboard | `/dashboard` | `dashboard:view` (**drift**, backend usa `dashboard:read`) | Ver KPIs, usuarios recientes, distribución de roles, accesos rápidos. | Alta |
| General | Usuarios | `/dashboard/users`, `/dashboard/users/[userId]`, `/dashboard/users/new`, `/dashboard/users/bulk-upload` | `users:read`; detalle sensible por `users:read_detail`/familias | Listar, filtrar, ver detalle, aprobar/rechazar, crear, carga masiva, roles, MFA, sesiones, post-registro. | Alta |
| Catálogos | Hub de catálogos | `/dashboard/catalogs` | sin permiso específico en overview | Navegar a catálogos por dominio. | Media |
| Catálogos / Geografía | Países | `/dashboard/catalogs/geography/countries` | `countries:read` | Listar, crear, editar, eliminar si permisos `countries:*` o `catalogs:*`. | Media |
| Catálogos / Geografía | Uniones | `/dashboard/catalogs/geography/unions`, `new`, `[id]`, `[id]/edit` | `unions:read` | Listar, crear, detalle, editar, eliminar. | Media |
| Catálogos / Geografía | Campos locales | `/dashboard/catalogs/geography/local-fields`, `new`, `[id]`, `[id]/edit` | `local_fields:read` | Listar, crear, detalle, editar, eliminar. | Media |
| Catálogos / Geografía | Distritos | `/dashboard/catalogs/geography/districts`, `new`, `[id]/edit` | `districts:read` | Listar, crear, editar, eliminar. | Media |
| Catálogos / Geografía | Iglesias | `/dashboard/catalogs/geography/churches`, `new`, `[id]/edit` | `churches:read` | Listar, crear, editar, eliminar. | Media |
| Catálogos / Salud | Alergias | `/dashboard/catalogs/allergies` | `catalogs:read` | CRUD con permisos `allergies:*` o `catalogs:*`. | Baja |
| Catálogos / Salud | Enfermedades | `/dashboard/catalogs/diseases` | `catalogs:read` | CRUD con permisos `diseases:*` o `catalogs:*`. | Baja |
| Catálogos / Salud | Medicamentos | `/dashboard/catalogs/medicines` | `catalogs:read` | CRUD con permisos `medicines:*` o `catalogs:*`. | Baja |
| Catálogos / Clubes | Tipos de club | `/dashboard/catalogs/club-types` | `catalogs:read` | CRUD con permisos `club_types:*` o `catalogs:*`. | Media |
| Catálogos / Clubes | Ideales de club | `/dashboard/catalogs/club-ideals`, `new`, `[id]/edit` | `catalogs:read` | Listar, crear, editar, eliminar ideales. | Media |
| Catálogos / Clubes | Años eclesiásticos | `/dashboard/catalogs/ecclesiastical-years` | `ecclesiastical_years:read` | Listar/gestionar entidad catálogo. | Alta |
| Catálogos / Clubes | Tipos de relación | `/dashboard/catalogs/relationship-types` | `catalogs:read` | CRUD con permisos específicos o `catalogs:*`. | Baja |
| Catálogos / Camporees | Tipos de evento camporee | `/dashboard/catalogs/camporee-event-types` | oculto en nav actual; pantalla física | CRUD con `camporee_event_types:*` o fallback `catalogs:*`. | Alta |
| Catálogos / Académico | Clases | `/dashboard/catalogs/classes` | `catalogs:read` | CRUD de catálogo de clases; depende de `classes:manage` o `catalogs:*`. | Alta |
| Catálogos / Académico | Módulos de clase | `/dashboard/catalogs/class-modules` | `catalogs:read` | CRUD de módulos; depende de `class_modules:manage` o `catalogs:*`. | Alta |
| Catálogos / Académico | Secciones de clase | `/dashboard/catalogs/class-sections` | `catalogs:read` | CRUD de secciones; depende de `class_sections:manage` o `catalogs:*`. | Alta |
| Catálogos / Académico | Tipos de actividad | `/dashboard/catalogs/activity-types` | `catalogs:read` | CRUD de tipos de actividad. | Media |
| Catálogos / Negocio | Categorías de finanzas | `/dashboard/catalogs/finance-categories` | `catalogs:read` | CRUD de categorías financieras. | Media |
| Catálogos / Negocio | Categorías de inventario | `/dashboard/catalogs/inventory-categories` | `catalogs:read` | CRUD de categorías de inventario. | Media |
| Catálogos / Honores | Especialidades catálogo | `/dashboard/catalogs/honors-catalog` | `honors:read` | CRUD de definiciones de especialidades. | Alta |
| Catálogos / Honores | Maestrías | `/dashboard/catalogs/master-honors` | `catalogs:read` | CRUD de maestrías/requisitos. | Alta |
| Catálogos / Honores | Categorías de especialidades | `/dashboard/catalogs/honor-categories`, `[categoryId]` | `honor_categories:read` | Listar categorías, ver especialidades por categoría, CRUD. | Alta |
| Catálogos | Recursos | `/dashboard/resources` | `resources:read` | Listar, crear, editar, eliminar recursos; filtros territoriales. | Media |
| Catálogos | Categorías de recursos | `/dashboard/resources/categories` | `resource_categories:read` | CRUD de categorías de recursos. | Media |
| Gestión de clubes | Clubes | `/dashboard/clubs`, `/dashboard/clubs/new`, `/dashboard/clubs/import`, `/dashboard/clubs/[id]`, unidades | `clubs:read` | Listar, crear, importar, editar, detalle, secciones, unidades, roles, directores. | Alta |
| Gestión de clubes | Coordinación | `/dashboard/coordination` | `coordination:manage` | Administrar zonas/asignaciones de coordinación. | Alta |
| Gestión de clubes | Camporees locales | `/dashboard/camporees`, detalle, pagos, eventos | `camporees:read` | Listar, crear/editar eventos, pagos, inscripciones, aprobaciones. | Alta |
| Gestión de clubes | Camporees unión | `/dashboard/camporees/union` | `camporees:read` | Supervisar/gestionar camporees de unión. | Alta |
| Gestión de clubes | Plantillas de eventos camporee | `/dashboard/camporees/event-templates` + new/edit | oculto en nav; vinculado a camporees | CRUD de plantillas de eventos. | Media |
| Gestión de clubes | Clases | `/dashboard/classes`, `/dashboard/classes/[classId]` | `classes:read` | Ver clases, progreso, miembros, responsables/consejeros. | Alta |
| Gestión de clubes | Inscripciones | `/dashboard/enrollments` | `classes:read` | Listar/filtrar inscripciones anuales. | Alta |
| Gestión de clubes | Especialidades | `/dashboard/honors`, `new`, `[honorId]`, edit, requirements | `honors:read` | Listar, crear, editar, ver detalle, gestionar requisitos. | Alta |
| Gestión de clubes | Revisión de requisitos de especialidades | `/dashboard/honors/requirements/review` | oculto en nav actual; backend requiere `honors:read` para listar y `honors:update` para revisar | Listar requisitos con `needs_review`, filtrar, aprobar/rechazar en lote o split view. | Alta |
| Gestión de clubes | Logros | `/dashboard/achievements`, categorías, new/edit | `achievements:manage` | CRUD de categorías y logros. | Media |
| Gestión de clubes | Actividades | `/dashboard/activities`, `[id]` | `activities:read` | Listar, ver detalle, asistencia, acciones de actividad. | Media |
| Gestión de clubes | Finanzas | `/dashboard/finances` | `finances:read` | Ver/gestionar finanzas según permisos. | Alta |
| Gestión de clubes | Inventario | `/dashboard/inventory` | `inventory:read` | Ver/gestionar inventario según permisos. | Media |
| Gestión de clubes | Certificaciones | `/dashboard/certifications`, `[id]` | `user_certifications:read` | Ver certificaciones/progreso de usuarios. | Media |
| Gestión de clubes | Seguros por sección | `/dashboard/insurance` | `insurance:read` | Ver/gestionar seguros de miembros por sección. | Alta |
| Gestión de clubes | Seguros por vencer | `/dashboard/insurance/expiring` | `insurance:read` | Monitorear vencimientos y filtros territoriales. | Alta |
| Materiales | Bandeja | `/dashboard/materials/inbox`, detalle pedido | `materiales:read` | Ver órdenes, aprobar/cancelar líneas, subir comprobantes según permisos. | Alta |
| Materiales | Comprobantes | `/dashboard/materials/receipts`, `[folio]` | `materiales:validate-receipt` | Revisar/aprobar/rechazar comprobantes. | Alta |
| Materiales | Inventario de materiales | `/dashboard/materials/inventory` | `materiales:manage-inventory` | CRUD de productos, stock, historial. | Alta |
| Materiales | Categorías | `/dashboard/materials/categories` | `materiales:manage-inventory` | CRUD de categorías. | Media |
| Materiales | Configuración | `/dashboard/materials/config` | `materiales:configure` | Config bancaria/entrega por campo local. | Alta |
| Operaciones | Validación | `/dashboard/validation` | `validation:read` | Revisar evidencias/progreso pendiente. | Alta |
| Operaciones | Revisión de evidencias de usuario | `/dashboard/evidence-review` | `user_honors:validate` | Revisar evidencias de especialidades/progreso de usuario. | Alta |
| Operaciones | Cargas por certificado | `/dashboard/certificate-bulk-imports`, `[batchId]` | `investiture:read` | Listar lotes, aprobar/rechazar lote o filas. | Alta |
| Operaciones | Investidura pendientes | `/dashboard/investiture` | `investiture:read` | Revisar pendientes de investidura. | Alta |
| Operaciones | Pipeline investidura | `/dashboard/investiture/pipeline` | `investiture:read` | Seguimiento de flujo/estado. | Alta |
| Operaciones | Config investidura | `/dashboard/investiture/config` | `investiture:read` | Configurar fechas/reglas de investidura. | Alta |
| Operaciones | Carpeta anual | `/dashboard/annual-folders` | `annual_folders:evaluate` en child; parent `evidence_folders:read` | Ver/evaluar carpetas anuales por club/sección. | Alta |
| Operaciones | Plantillas carpeta anual | `/dashboard/annual-folders/templates` | `annual_folder_templates:read` | Gestionar plantillas. | Alta |
| Operaciones | Rankings carpeta anual | `/dashboard/annual-folders/rankings`, breakdown | `rankings:read` | Ver rankings y desglose. | Media |
| Operaciones | Config rankings carpeta anual | `/dashboard/annual-folders/ranking-config` + new/edit | `ranking_weights:read` | Ver/crear/editar configuración de pesos. | Media |
| Operaciones | Cierre de año | `/dashboard/year-end` | `permissions:read` | Procesos de cierre/sucesión anual. | Alta |
| Rankings y análisis | SLA | `/dashboard/sla` | `investiture:read` | Ver métricas SLA/colas operativas. | Media |
| Rankings y análisis | Pesos de rankings | `/dashboard/ranking-weights` | `ranking_weights:read` | Ver/configurar pesos institucionales. | Media |
| Rankings y análisis | Rankings de miembros | `/dashboard/member-rankings`, breakdown | oculto en nav actual | Ver ranking por miembro y desglose. | Media |
| Rankings y análisis | Pesos rankings miembros | `/dashboard/member-ranking-weights` + new/edit | oculto en nav actual | CRUD de pesos por miembro. | Media |
| Rankings y análisis | Rankings de secciones | `/dashboard/section-rankings`, members | oculto en nav actual | Ver ranking por sección y miembros. | Media |
| Comunicaciones | Notificaciones | `/dashboard/notifications` | `notifications:send` | Enviar directo, broadcast o por club según permisos. | Media |
| Comunicaciones | Historial notificaciones | `/dashboard/notifications/history` | `notifications:send` en nav | Ver historial/auditoría. | Media |
| Solicitudes y reportes | Transferencias | `/dashboard/requests/transfers` | `requests:read` | Listar/revisar transferencias. | Alta |
| Solicitudes y reportes | Asignaciones | `/dashboard/requests/assignments` | `requests:read` | Listar/revisar asignaciones. | Alta |
| Solicitudes y reportes | Membresías | `/dashboard/requests/membership` | `club_members:approve` | Aprobar/rechazar solicitudes de membresía. | Alta |
| Solicitudes y reportes | Mis reportes | `/dashboard/reports`, `[reportId]` | `reports:read` | Listar, ver detalle, descargar. | Media |
| Solicitudes y reportes | Supervisión reportes | `/dashboard/reports/supervision` | `reports:read` | Supervisar reportes por territorio. | Media |
| Solicitudes y reportes | Soporte | `/dashboard/support` | sin permiso en nav | Ver reportes de soporte. | Media |
| Solicitudes y reportes | Miembro del mes | `/dashboard/member-of-month` | `mom:supervise` | Supervisar/evaluar miembro del mes. | Media |
| Administración | RBAC hub | `/dashboard/rbac` | `permissions:read` | Navegar a permisos/roles. | Alta |
| Administración | Permisos | `/dashboard/rbac/permissions` | `permissions:read` | CRUD permisos. | Alta |
| Administración | Roles | `/dashboard/rbac/roles`, new, `[roleId]` | `roles:read` | Crear/editar/desactivar roles, sincronizar permisos. | Alta |
| Administración | Matriz RBAC | `/dashboard/rbac/matrix` | oculto en nav actual | Ver/editar matriz de permisos por rol. | Alta |
| Administración | Permisos de usuario | `/dashboard/rbac/user-permissions` | oculto en nav actual | Buscar usuario, asignar/remover roles/permisos. | Alta |
| Administración | Config sistema | `/dashboard/settings` | `permissions:read` | Ver/editar configuraciones del sistema. | Alta |
| Administración | Categorías de puntuación | `/dashboard/settings/scoring-categories` | `scoring_categories:read` | Configurar puntuaciones por división. | Media |
| Administración | Jobs y colas | `/dashboard/system/jobs`, history | `permissions:read` | Ver jobs, historial, retry según backend. | Media |

## 4. Rutas alias / redirecciones detectadas

| Ruta | Redirige a | Nota |
|---|---|---|
| `/dashboard/materials` | `/dashboard/materials/inbox` | Alias de módulo. |
| `/dashboard/clubs/v2` | `/dashboard/clubs` | Ruta legacy. |
| `/dashboard/clubs/v2/[id]` | `/dashboard/clubs/[id]` | Ruta legacy. |
| `/dashboard/annual-folders/categories` | `/dashboard/annual-folders/ranking-config` | Alias legacy. |
| `/dashboard/annual-folders/evaluate` | `/dashboard/annual-folders` | Alias legacy. |

## 4.1 Rutas API internas del admin

Estas no son pantallas, pero impactan la reestructura porque sostienen autenticación, sesión y generación de PDF:

| Ruta API | Uso |
|---|---|
| `/api/auth/logout` | Cierre de sesión desde panel. |
| `/api/auth/me` | Lectura de usuario/sesión actual. |
| `/api/auth/refresh` | Refresh de sesión/token. |
| `/api/auth/token` | Entrega/puente de token para cliente. |
| `/api/evidence-review/pdf` | Generación/descarga de PDF de revisión de evidencias. |

## 5. Hallazgos de arquitectura/UX para la reingeniería

1. **Hay drift de permiso en Dashboard:** frontend usa `dashboard:view`; backend usa `dashboard:read`.
2. **No hay guard por permiso en cada página:** el layout valida rol admin global, y muchas pantallas confían en menú/API/acciones para RBAC fino. Para reestructura conviene definir un `screenAccess` canónico por ruta.
3. **Menú y rutas no están alineados:** hay pantallas reales no visibles en sidebar (`member-rankings`, `section-rankings`, `member-ranking-weights`, `rbac/matrix`, `rbac/user-permissions`, plantillas de eventos camporee).
4. **Acciones y pantallas están mezcladas:** varios módulos tienen permisos de lectura en nav, pero acciones internas usan permisos más finos (`create/update/delete/approve/validate`). La UI nueva debe separar `canViewScreen` de `canPerformAction`.
5. **Roles de club tienen permisos, pero no panel:** si queremos que directores/secretarios entren al panel, hay que cambiar `ALLOWED_ADMIN_ROLES` o crear un shell operativo separado. Esto es una decisión de producto, no solo UI.
6. **Hay rutas legacy/alias:** deben conservarse con redirect o limpiarse con decisión explícita para no romper links existentes.
7. **Omisiones corregidas en esta reauditoría:** `/`, `/login`, `/dashboard/catalogs/camporee-event-types`, `/dashboard/honors/requirements/review` y las rutas API internas del admin no estaban suficientemente representadas en la matriz inicial.
8. **Hay drift seed/migrations en permisos de módulos recientes:** `materiales:*`, `camporee_event_types:*` y `camporee_events:*` aparecen en migraciones/backend/admin, pero no en `permissions.seed.sql` activo. Si se re-seedea una base desde seeds actuales, esas pantallas pueden quedar invisibles o bloqueadas por RBAC.
9. **Hay constantes frontend-only o heredadas:** `classes:manage`, `class_modules:manage`, `class_sections:manage`, `finance_categories:manage`, `inventory_categories:manage`, `master_honors:manage` y permisos granulares de catálogos genéricos no aparecen en el seed activo. Varias acciones tienen fallback a `catalogs:*`, pero no todas.

### 5.1 Auditoría de permisos cruzada contra panel/backend

| Hallazgo | Evidencia | Impacto |
|---|---|---|
| `dashboard:view` vs `dashboard:read` | `nav-config.ts` usa `dashboard:view`; `permissions.seed.sql` y `role-permissions.seed.sql` usan `dashboard:read`. | Usuarios admin que no sean `super-admin` pueden perder acceso visual al dashboard en sidebar/command palette aunque el layout los deje entrar directo. |
| `materiales:*` no está en seed activo | Backend/admin usan `materiales:read`, `materiales:validate-receipt`, `materiales:manage-inventory`, `materiales:configure`; migraciones los crean, pero `permissions.seed.sql` no los lista. | Una DB reconstruida solo con seeds actuales puede dejar Materiales sin permisos/grants reales. |
| `camporee_event_types:*` y `camporee_events:*` no están en seed activo | Controllers backend requieren esos permisos y migraciones los crean; `permissions.seed.sql` no los lista. | Tipos/plantillas/eventos de camporee pueden fallar por RBAC en ambientes nuevos o re-seedeados. |
| `classes:manage` y otros `*:manage` heredados | Admin usa esas constantes; el seed activo no las declara. | Algunas acciones dependen de fallback `catalogs:*`; donde no haya fallback, la acción queda bloqueada para todos. |

Regla para el nuevo agente: no usar `navConfig.permission` como fuente única. La fuente operativa debe salir de `authorization.effective.permissions` + seed/backend/docs canónicos, y cualquier drift debe resolverse antes de rediseñar navegación.

## 6. Prompt base para el próximo agente UI

Usá este inventario como verdad inicial. No implementes pantallas nuevas sin validar contratos API y RBAC. La reestructura debe producir una navegación por dominios, con matriz `screen -> permission -> actions -> role group`, manteniendo rutas legacy con redirect hasta decisión explícita.

Tareas del agente UI por pantalla:

1. Confirmar objetivo de negocio de la pantalla.
2. Confirmar permiso de lectura (`canViewScreen`).
3. Separar acciones por permiso (`create`, `update`, `delete`, `approve`, `validate`, `download`, `configure`).
4. Definir estados: loading, empty, forbidden, error, offline/API unavailable.
5. Definir prioridad: Alta si afecta usuarios, clubes, inscripciones, seguros, validación, carpetas anuales, materiales, RBAC o cierre de año.
6. No rediseñar contratos API desde UI; si falta contrato, marcar bloqueo para backend/docs.

## 7. Fuentes verificadas

- `sacdia-admin/src/app/(dashboard)/layout.tsx`
- `sacdia-admin/src/components/layout/nav-config.ts`
- `sacdia-admin/src/components/layout/app-sidebar.tsx`
- `sacdia-admin/src/components/layout/command-palette.tsx`
- `sacdia-admin/src/lib/auth/session.ts`
- `sacdia-admin/src/lib/auth/roles.ts`
- `sacdia-admin/src/lib/auth/permission-utils.ts`
- `sacdia-admin/src/lib/auth/permissions.ts`
- `sacdia-admin/src/app/page.tsx`
- `sacdia-admin/src/app/(auth)/login/page.tsx`
- `sacdia-admin/src/app/api/**/route.ts`
- `sacdia-backend/prisma/seeds/permissions.seed.sql`
- `sacdia-backend/prisma/seeds/role-permissions.seed.sql`
- `sacdia-backend/prisma/migrations/20260513190000_seed_materiales_permissions/migration.sql`
- `sacdia-backend/prisma/migrations/20260520225303_camporee_events/migration.sql`
- `sacdia-backend/src/admin/admin-camporee-event-types.controller.ts`
- `sacdia-backend/src/camporee-events/camporee-events.controller.ts`
- `sacdia-backend/src/camporee-event-templates/camporee-event-templates.controller.ts`
- `sacdia-backend/src/materials/shared/permissions.ts`
- `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- `docs/api/SECURITY-GUIDE.md`
- `docs/canon/source-of-truth.md`
- `docs/canon/auth/modelo-autorizacion.md`
- `docs/features/camporee-events.md`

## 8. Inventario completo de rutas físicas (`page.tsx`)

| Sección inferida | Ruta | Archivo |
|---|---|---|
| Acceso | `/` | `sacdia-admin/src/app/page.tsx` |
| Acceso | `/login` | `sacdia-admin/src/app/(auth)/login/page.tsx` |
| Gestión de clubes | `/dashboard/achievements/[categoryId]/[achievementId]/edit` | `sacdia-admin/src/app/(dashboard)/dashboard/achievements/[categoryId]/[achievementId]/edit/page.tsx` |
| Gestión de clubes | `/dashboard/achievements/[categoryId]/new` | `sacdia-admin/src/app/(dashboard)/dashboard/achievements/[categoryId]/new/page.tsx` |
| Gestión de clubes | `/dashboard/achievements/[categoryId]` | `sacdia-admin/src/app/(dashboard)/dashboard/achievements/[categoryId]/page.tsx` |
| Gestión de clubes | `/dashboard/achievements` | `sacdia-admin/src/app/(dashboard)/dashboard/achievements/page.tsx` |
| Gestión de clubes | `/dashboard/activities/[id]` | `sacdia-admin/src/app/(dashboard)/dashboard/activities/[id]/page.tsx` |
| Gestión de clubes | `/dashboard/activities` | `sacdia-admin/src/app/(dashboard)/dashboard/activities/page.tsx` |
| Operaciones | `/dashboard/annual-folders/categories` | `sacdia-admin/src/app/(dashboard)/dashboard/annual-folders/categories/page.tsx` |
| Operaciones | `/dashboard/annual-folders/evaluate` | `sacdia-admin/src/app/(dashboard)/dashboard/annual-folders/evaluate/page.tsx` |
| Operaciones | `/dashboard/annual-folders` | `sacdia-admin/src/app/(dashboard)/dashboard/annual-folders/page.tsx` |
| Operaciones | `/dashboard/annual-folders/ranking-config/[id]` | `sacdia-admin/src/app/(dashboard)/dashboard/annual-folders/ranking-config/[id]/page.tsx` |
| Operaciones | `/dashboard/annual-folders/ranking-config/new` | `sacdia-admin/src/app/(dashboard)/dashboard/annual-folders/ranking-config/new/page.tsx` |
| Operaciones | `/dashboard/annual-folders/ranking-config` | `sacdia-admin/src/app/(dashboard)/dashboard/annual-folders/ranking-config/page.tsx` |
| Operaciones | `/dashboard/annual-folders/rankings/[enrollmentId]/breakdown` | `sacdia-admin/src/app/(dashboard)/dashboard/annual-folders/rankings/[enrollmentId]/breakdown/page.tsx` |
| Operaciones | `/dashboard/annual-folders/rankings` | `sacdia-admin/src/app/(dashboard)/dashboard/annual-folders/rankings/page.tsx` |
| Operaciones | `/dashboard/annual-folders/templates` | `sacdia-admin/src/app/(dashboard)/dashboard/annual-folders/templates/page.tsx` |
| Gestión de clubes | `/dashboard/camporees/[id]/events/[eventId]/edit` | `sacdia-admin/src/app/(dashboard)/dashboard/camporees/[id]/events/[eventId]/edit/page.tsx` |
| Gestión de clubes | `/dashboard/camporees/[id]/events/new` | `sacdia-admin/src/app/(dashboard)/dashboard/camporees/[id]/events/new/page.tsx` |
| Gestión de clubes | `/dashboard/camporees/[id]` | `sacdia-admin/src/app/(dashboard)/dashboard/camporees/[id]/page.tsx` |
| Gestión de clubes | `/dashboard/camporees/[id]/payments/[paymentId]/edit` | `sacdia-admin/src/app/(dashboard)/dashboard/camporees/[id]/payments/[paymentId]/edit/page.tsx` |
| Gestión de clubes | `/dashboard/camporees/[id]/payments/new` | `sacdia-admin/src/app/(dashboard)/dashboard/camporees/[id]/payments/new/page.tsx` |
| Gestión de clubes | `/dashboard/camporees/event-templates/[id]/edit` | `sacdia-admin/src/app/(dashboard)/dashboard/camporees/event-templates/[id]/edit/page.tsx` |
| Gestión de clubes | `/dashboard/camporees/event-templates/new` | `sacdia-admin/src/app/(dashboard)/dashboard/camporees/event-templates/new/page.tsx` |
| Gestión de clubes | `/dashboard/camporees/event-templates` | `sacdia-admin/src/app/(dashboard)/dashboard/camporees/event-templates/page.tsx` |
| Gestión de clubes | `/dashboard/camporees` | `sacdia-admin/src/app/(dashboard)/dashboard/camporees/page.tsx` |
| Gestión de clubes | `/dashboard/camporees/union` | `sacdia-admin/src/app/(dashboard)/dashboard/camporees/union/page.tsx` |
| Catálogos | `/dashboard/catalogs/activity-types` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/activity-types/page.tsx` |
| Catálogos | `/dashboard/catalogs/allergies` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/allergies/page.tsx` |
| Catálogos | `/dashboard/catalogs/camporee-event-types` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/camporee-event-types/page.tsx` |
| Catálogos | `/dashboard/catalogs/class-modules` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/class-modules/page.tsx` |
| Catálogos | `/dashboard/catalogs/class-sections` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/class-sections/page.tsx` |
| Catálogos | `/dashboard/catalogs/classes` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/classes/page.tsx` |
| Catálogos | `/dashboard/catalogs/club-ideals/[id]/edit` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/club-ideals/[id]/edit/page.tsx` |
| Catálogos | `/dashboard/catalogs/club-ideals/new` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/club-ideals/new/page.tsx` |
| Catálogos | `/dashboard/catalogs/club-ideals` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/club-ideals/page.tsx` |
| Catálogos | `/dashboard/catalogs/club-types` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/club-types/page.tsx` |
| Catálogos | `/dashboard/catalogs/diseases` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/diseases/page.tsx` |
| Catálogos | `/dashboard/catalogs/ecclesiastical-years` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/ecclesiastical-years/page.tsx` |
| Catálogos | `/dashboard/catalogs/finance-categories` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/finance-categories/page.tsx` |
| Catálogos | `/dashboard/catalogs/geography/churches/[id]/edit` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/geography/churches/[id]/edit/page.tsx` |
| Catálogos | `/dashboard/catalogs/geography/churches/new` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/geography/churches/new/page.tsx` |
| Catálogos | `/dashboard/catalogs/geography/churches` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/geography/churches/page.tsx` |
| Catálogos | `/dashboard/catalogs/geography/countries` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/geography/countries/page.tsx` |
| Catálogos | `/dashboard/catalogs/geography/districts/[id]/edit` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/geography/districts/[id]/edit/page.tsx` |
| Catálogos | `/dashboard/catalogs/geography/districts/new` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/geography/districts/new/page.tsx` |
| Catálogos | `/dashboard/catalogs/geography/districts` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/geography/districts/page.tsx` |
| Catálogos | `/dashboard/catalogs/geography/local-fields/[id]/edit` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/geography/local-fields/[id]/edit/page.tsx` |
| Catálogos | `/dashboard/catalogs/geography/local-fields/[id]` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/geography/local-fields/[id]/page.tsx` |
| Catálogos | `/dashboard/catalogs/geography/local-fields/new` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/geography/local-fields/new/page.tsx` |
| Catálogos | `/dashboard/catalogs/geography/local-fields` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/geography/local-fields/page.tsx` |
| Catálogos | `/dashboard/catalogs/geography/unions/[id]/edit` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/geography/unions/[id]/edit/page.tsx` |
| Catálogos | `/dashboard/catalogs/geography/unions/[id]` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/geography/unions/[id]/page.tsx` |
| Catálogos | `/dashboard/catalogs/geography/unions/new` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/geography/unions/new/page.tsx` |
| Catálogos | `/dashboard/catalogs/geography/unions` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/geography/unions/page.tsx` |
| Catálogos | `/dashboard/catalogs/honor-categories/[categoryId]` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/honor-categories/[categoryId]/page.tsx` |
| Catálogos | `/dashboard/catalogs/honor-categories` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/honor-categories/page.tsx` |
| Catálogos | `/dashboard/catalogs/honors-catalog` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/honors-catalog/page.tsx` |
| Catálogos | `/dashboard/catalogs/inventory-categories` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/inventory-categories/page.tsx` |
| Catálogos | `/dashboard/catalogs/master-honors` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/master-honors/page.tsx` |
| Catálogos | `/dashboard/catalogs/medicines` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/medicines/page.tsx` |
| Catálogos | `/dashboard/catalogs` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/page.tsx` |
| Catálogos | `/dashboard/catalogs/relationship-types` | `sacdia-admin/src/app/(dashboard)/dashboard/catalogs/relationship-types/page.tsx` |
| Operaciones | `/dashboard/certificate-bulk-imports/[batchId]` | `sacdia-admin/src/app/(dashboard)/dashboard/certificate-bulk-imports/[batchId]/page.tsx` |
| Operaciones | `/dashboard/certificate-bulk-imports` | `sacdia-admin/src/app/(dashboard)/dashboard/certificate-bulk-imports/page.tsx` |
| Gestión de clubes | `/dashboard/certifications/[id]` | `sacdia-admin/src/app/(dashboard)/dashboard/certifications/[id]/page.tsx` |
| Gestión de clubes | `/dashboard/certifications` | `sacdia-admin/src/app/(dashboard)/dashboard/certifications/page.tsx` |
| Gestión de clubes | `/dashboard/classes/[classId]` | `sacdia-admin/src/app/(dashboard)/dashboard/classes/[classId]/page.tsx` |
| Gestión de clubes | `/dashboard/classes` | `sacdia-admin/src/app/(dashboard)/dashboard/classes/page.tsx` |
| Gestión de clubes | `/dashboard/clubs/[id]` | `sacdia-admin/src/app/(dashboard)/dashboard/clubs/[id]/page.tsx` |
| Gestión de clubes | `/dashboard/clubs/[id]/units/[unitId]` | `sacdia-admin/src/app/(dashboard)/dashboard/clubs/[id]/units/[unitId]/page.tsx` |
| Gestión de clubes | `/dashboard/clubs/[id]/units/new` | `sacdia-admin/src/app/(dashboard)/dashboard/clubs/[id]/units/new/page.tsx` |
| Gestión de clubes | `/dashboard/clubs/import` | `sacdia-admin/src/app/(dashboard)/dashboard/clubs/import/page.tsx` |
| Gestión de clubes | `/dashboard/clubs/new` | `sacdia-admin/src/app/(dashboard)/dashboard/clubs/new/page.tsx` |
| Gestión de clubes | `/dashboard/clubs` | `sacdia-admin/src/app/(dashboard)/dashboard/clubs/page.tsx` |
| Gestión de clubes | `/dashboard/clubs/v2/[id]` | `sacdia-admin/src/app/(dashboard)/dashboard/clubs/v2/[id]/page.tsx` |
| Gestión de clubes | `/dashboard/clubs/v2` | `sacdia-admin/src/app/(dashboard)/dashboard/clubs/v2/page.tsx` |
| Gestión de clubes | `/dashboard/coordination` | `sacdia-admin/src/app/(dashboard)/dashboard/coordination/page.tsx` |
| Gestión de clubes | `/dashboard/enrollments` | `sacdia-admin/src/app/(dashboard)/dashboard/enrollments/page.tsx` |
| Operaciones | `/dashboard/evidence-review` | `sacdia-admin/src/app/(dashboard)/dashboard/evidence-review/page.tsx` |
| Gestión de clubes | `/dashboard/finances` | `sacdia-admin/src/app/(dashboard)/dashboard/finances/page.tsx` |
| Gestión de clubes | `/dashboard/honors/[honorId]/edit` | `sacdia-admin/src/app/(dashboard)/dashboard/honors/[honorId]/edit/page.tsx` |
| Gestión de clubes | `/dashboard/honors/[honorId]` | `sacdia-admin/src/app/(dashboard)/dashboard/honors/[honorId]/page.tsx` |
| Gestión de clubes | `/dashboard/honors/[honorId]/requirements` | `sacdia-admin/src/app/(dashboard)/dashboard/honors/[honorId]/requirements/page.tsx` |
| Gestión de clubes | `/dashboard/honors/new` | `sacdia-admin/src/app/(dashboard)/dashboard/honors/new/page.tsx` |
| Gestión de clubes | `/dashboard/honors` | `sacdia-admin/src/app/(dashboard)/dashboard/honors/page.tsx` |
| Gestión de clubes | `/dashboard/honors/requirements/review` | `sacdia-admin/src/app/(dashboard)/dashboard/honors/requirements/review/page.tsx` |
| Gestión de clubes | `/dashboard/insurance/expiring` | `sacdia-admin/src/app/(dashboard)/dashboard/insurance/expiring/page.tsx` |
| Gestión de clubes | `/dashboard/insurance` | `sacdia-admin/src/app/(dashboard)/dashboard/insurance/page.tsx` |
| Gestión de clubes | `/dashboard/inventory` | `sacdia-admin/src/app/(dashboard)/dashboard/inventory/page.tsx` |
| Operaciones | `/dashboard/investiture/config` | `sacdia-admin/src/app/(dashboard)/dashboard/investiture/config/page.tsx` |
| Operaciones | `/dashboard/investiture` | `sacdia-admin/src/app/(dashboard)/dashboard/investiture/page.tsx` |
| Operaciones | `/dashboard/investiture/pipeline` | `sacdia-admin/src/app/(dashboard)/dashboard/investiture/pipeline/page.tsx` |
| Materiales | `/dashboard/materials/categories` | `sacdia-admin/src/app/(dashboard)/dashboard/materials/categories/page.tsx` |
| Materiales | `/dashboard/materials/config` | `sacdia-admin/src/app/(dashboard)/dashboard/materials/config/page.tsx` |
| Materiales | `/dashboard/materials/inbox` | `sacdia-admin/src/app/(dashboard)/dashboard/materials/inbox/page.tsx` |
| Materiales | `/dashboard/materials/inventory` | `sacdia-admin/src/app/(dashboard)/dashboard/materials/inventory/page.tsx` |
| Materiales | `/dashboard/materials` | `sacdia-admin/src/app/(dashboard)/dashboard/materials/page.tsx` |
| Materiales | `/dashboard/materials/receipts/[folio]` | `sacdia-admin/src/app/(dashboard)/dashboard/materials/receipts/[folio]/page.tsx` |
| Materiales | `/dashboard/materials/receipts` | `sacdia-admin/src/app/(dashboard)/dashboard/materials/receipts/page.tsx` |
| Materiales | `/dashboard/materials/request/[folio]` | `sacdia-admin/src/app/(dashboard)/dashboard/materials/request/[folio]/page.tsx` |
| Solicitudes y reportes | `/dashboard/member-of-month` | `sacdia-admin/src/app/(dashboard)/dashboard/member-of-month/page.tsx` |
| Rankings y análisis | `/dashboard/member-ranking-weights/[id]/edit` | `sacdia-admin/src/app/(dashboard)/dashboard/member-ranking-weights/[id]/edit/page.tsx` |
| Rankings y análisis | `/dashboard/member-ranking-weights/new` | `sacdia-admin/src/app/(dashboard)/dashboard/member-ranking-weights/new/page.tsx` |
| Rankings y análisis | `/dashboard/member-ranking-weights` | `sacdia-admin/src/app/(dashboard)/dashboard/member-ranking-weights/page.tsx` |
| Rankings y análisis | `/dashboard/member-rankings/[enrollmentId]/breakdown` | `sacdia-admin/src/app/(dashboard)/dashboard/member-rankings/[enrollmentId]/breakdown/page.tsx` |
| Rankings y análisis | `/dashboard/member-rankings` | `sacdia-admin/src/app/(dashboard)/dashboard/member-rankings/page.tsx` |
| Comunicaciones | `/dashboard/notifications/history` | `sacdia-admin/src/app/(dashboard)/dashboard/notifications/history/page.tsx` |
| Comunicaciones | `/dashboard/notifications` | `sacdia-admin/src/app/(dashboard)/dashboard/notifications/page.tsx` |
| General / Dashboard | `/dashboard` | `sacdia-admin/src/app/(dashboard)/dashboard/page.tsx` |
| Rankings y análisis | `/dashboard/ranking-weights` | `sacdia-admin/src/app/(dashboard)/dashboard/ranking-weights/page.tsx` |
| Administración | `/dashboard/rbac/matrix` | `sacdia-admin/src/app/(dashboard)/dashboard/rbac/matrix/page.tsx` |
| Administración | `/dashboard/rbac` | `sacdia-admin/src/app/(dashboard)/dashboard/rbac/page.tsx` |
| Administración | `/dashboard/rbac/permissions` | `sacdia-admin/src/app/(dashboard)/dashboard/rbac/permissions/page.tsx` |
| Administración | `/dashboard/rbac/roles/[roleId]` | `sacdia-admin/src/app/(dashboard)/dashboard/rbac/roles/[roleId]/page.tsx` |
| Administración | `/dashboard/rbac/roles/new` | `sacdia-admin/src/app/(dashboard)/dashboard/rbac/roles/new/page.tsx` |
| Administración | `/dashboard/rbac/roles` | `sacdia-admin/src/app/(dashboard)/dashboard/rbac/roles/page.tsx` |
| Administración | `/dashboard/rbac/user-permissions` | `sacdia-admin/src/app/(dashboard)/dashboard/rbac/user-permissions/page.tsx` |
| Solicitudes y reportes | `/dashboard/reports/[reportId]` | `sacdia-admin/src/app/(dashboard)/dashboard/reports/[reportId]/page.tsx` |
| Solicitudes y reportes | `/dashboard/reports` | `sacdia-admin/src/app/(dashboard)/dashboard/reports/page.tsx` |
| Solicitudes y reportes | `/dashboard/reports/supervision` | `sacdia-admin/src/app/(dashboard)/dashboard/reports/supervision/page.tsx` |
| Solicitudes y reportes | `/dashboard/requests/assignments` | `sacdia-admin/src/app/(dashboard)/dashboard/requests/assignments/page.tsx` |
| Solicitudes y reportes | `/dashboard/requests/membership` | `sacdia-admin/src/app/(dashboard)/dashboard/requests/membership/page.tsx` |
| Solicitudes y reportes | `/dashboard/requests/transfers` | `sacdia-admin/src/app/(dashboard)/dashboard/requests/transfers/page.tsx` |
| Catálogos / Recursos | `/dashboard/resources/categories` | `sacdia-admin/src/app/(dashboard)/dashboard/resources/categories/page.tsx` |
| Catálogos / Recursos | `/dashboard/resources` | `sacdia-admin/src/app/(dashboard)/dashboard/resources/page.tsx` |
| Rankings y análisis | `/dashboard/section-rankings/[sectionId]/members` | `sacdia-admin/src/app/(dashboard)/dashboard/section-rankings/[sectionId]/members/page.tsx` |
| Rankings y análisis | `/dashboard/section-rankings` | `sacdia-admin/src/app/(dashboard)/dashboard/section-rankings/page.tsx` |
| Administración | `/dashboard/settings` | `sacdia-admin/src/app/(dashboard)/dashboard/settings/page.tsx` |
| Administración | `/dashboard/settings/scoring-categories` | `sacdia-admin/src/app/(dashboard)/dashboard/settings/scoring-categories/page.tsx` |
| Rankings y análisis | `/dashboard/sla` | `sacdia-admin/src/app/(dashboard)/dashboard/sla/page.tsx` |
| Solicitudes y reportes | `/dashboard/support` | `sacdia-admin/src/app/(dashboard)/dashboard/support/page.tsx` |
| Administración | `/dashboard/system/jobs/history` | `sacdia-admin/src/app/(dashboard)/dashboard/system/jobs/history/page.tsx` |
| Administración | `/dashboard/system/jobs` | `sacdia-admin/src/app/(dashboard)/dashboard/system/jobs/page.tsx` |
| General / Usuarios | `/dashboard/users/[userId]` | `sacdia-admin/src/app/(dashboard)/dashboard/users/[userId]/page.tsx` |
| General / Usuarios | `/dashboard/users/bulk-upload` | `sacdia-admin/src/app/(dashboard)/dashboard/users/bulk-upload/page.tsx` |
| General / Usuarios | `/dashboard/users/new` | `sacdia-admin/src/app/(dashboard)/dashboard/users/new/page.tsx` |
| General / Usuarios | `/dashboard/users` | `sacdia-admin/src/app/(dashboard)/dashboard/users/page.tsx` |
| Operaciones | `/dashboard/validation` | `sacdia-admin/src/app/(dashboard)/dashboard/validation/page.tsx` |
| Operaciones | `/dashboard/year-end` | `sacdia-admin/src/app/(dashboard)/dashboard/year-end/page.tsx` |

## 9. Mapa de endpoints, datos y relaciones por pantalla

**Estado:** mapa operativo inicial, extraído contra `sacdia-admin/src/app`, `sacdia-admin/src/lib/api/*`, server actions y rutas API internas del admin.
**Uso:** este bloque es el handoff para que el próximo agente diseñe la IA/navegación sin inventar contratos.

Convenciones:

- **Solicita/recibe** = datos que la pantalla carga para renderizarse.
- **Envía/muta** = formularios, acciones o payloads enviados por la pantalla o sus componentes.
- **Relación** = pantallas que comparten entidad, navegación, filtros o resultado de acciones.
- `apiRequest` agrega el prefijo `/api/v1` del backend, salvo rutas internas Next `/api/*`.
- Donde dice `FormData`, puede incluir archivos o payload multipart.

### 9.1 Acceso y shell

| Pantalla | Solicita / recibe | Envía / muta | Relación con pantallas |
|---|---|---|---|
| `/` | No llama API; redirige a `/dashboard`. | No envía datos. | Entrada raíz hacia Dashboard. |
| `/login` | `POST /auth/login` recibe token/user; luego `GET /auth/me` recibe perfil y `authorization.effective.permissions`. | Envía `{ email, password }` y `next`. Guarda cookies de sesión. | Si login OK redirige a `/dashboard` o `next`; si no tiene rol admin, bloquea acceso al panel. |
| Shell dashboard `/dashboard/*` | `requireAdminUser()` lee sesión/cookies y usuario actual. Cliente usa `/api/auth/me`, `/api/auth/token`, `/api/auth/refresh`. | `/api/auth/logout` limpia sesión; `/api/auth/refresh` renueva; `/api/auth/token` entrega token al cliente same-origin. | Afecta todas las pantallas protegidas; sidebar/command palette dependen de permisos efectivos. |

### 9.2 General y usuarios

| Pantalla | Solicita / recibe | Envía / muta | Relación con pantallas |
|---|---|---|---|
| Dashboard `/dashboard` | `GET /admin/users?limit=1&page=1`, `GET /admin/users?limit=5&page=1`, `GET /admin/users?limit=100&page=1`. Recibe conteos/listas de usuarios, roles y usuarios recientes. | No muta datos. | Accesos a Usuarios, Clubes, Reportes/RBAC. Impactado por drift `dashboard:view` vs `dashboard:read`. |
| Usuarios `/dashboard/users` | `GET /admin/users` con filtros/paginación. Recibe usuarios, roles, estado, scopes y flags como `is_deleted`. | Desde acciones relacionadas: actualizar/aprobar/rechazar usuario vía `PATCH /admin/users/:userId` o rutas de approval. | Relación directa con detalle de usuario, creación, bulk upload, RBAC user-permissions, post-registro. |
| Nuevo usuario `/dashboard/users/new` | Carga catálogos auxiliares según formulario. | `POST /admin/users`. Envía datos administrativos del usuario, roles, perfil inicial. | Vuelve a listado y detalle de usuario. |
| Carga masiva usuarios `/dashboard/users/bulk-upload` | No requiere listado previo salvo estado de UI. | `POST /admin/users/bulk` con archivo `FormData`. Recibe resumen de creados/errores. | Impacta listado Usuarios y Dashboard. |
| Detalle usuario `/dashboard/users/[userId]` | `GET /admin/users/:userId`; también puede cargar MFA/sesiones/post-registro/foto según tabs. Recibe perfil, salud, familia, roles, asignaciones, permisos y estado de registro. | `PATCH /admin/users/:userId`, acciones de aprobación, post-registro y sesión según tab. Envía campos administrativos o decisiones. | Relación con RBAC, Clubes, Certificaciones, Seguros, Validación/Evidencias. |

### 9.3 Catálogos y datos maestros

| Pantalla | Solicita / recibe | Envía / muta | Relación con pantallas |
|---|---|---|---|
| Hub catálogos `/dashboard/catalogs` | No llama API crítica; muestra accesos. | No muta. | Agrupa todos los catálogos. |
| Países | `GET /admin/countries`. Recibe países paginados/filtrados. | `POST/PATCH/DELETE /admin/countries(/:id)`. Envía nombre/código/activo. | Uniones, campos locales, reportes territoriales. |
| Uniones | `GET /admin/unions`, `GET /admin/countries`, detalle `GET /admin/unions/:id`. | `POST/PATCH/DELETE /admin/unions(/:id)`. Envía país, nombre/código/activo. | Campos locales, reportes, recursos, rankings. |
| Campos locales | `GET /admin/local-fields`, `GET /admin/unions`, detalle `GET /admin/local-fields/:id`. | `POST/PATCH/DELETE /admin/local-fields(/:id)`. Envía unión, nombre/código/activo. | Distritos, iglesias, clubes, materiales config, coordinación. |
| Distritos | `GET /admin/districts`, `GET /admin/local-fields`. | `POST/PATCH/DELETE /admin/districts(/:id)`. Envía campo local, nombre/código/activo. | Iglesias, clubes y coordinación. |
| Iglesias | `GET /admin/churches`, `GET /admin/districts`. | `POST/PATCH/DELETE /admin/churches(/:id)`. Envía distrito, nombre/datos básicos/activo. | Clubes y usuarios. |
| Salud: alergias/enfermedades/medicinas | `GET /admin/allergies`, `/admin/diseases`, `/admin/medicines`. | `POST/PATCH/DELETE` del endpoint correspondiente. Envía nombre/descripción/activo. | Detalle de usuario y registro médico. |
| Tipos de club | `GET /admin/club-types`. | `POST/PATCH/DELETE /admin/club-types(/:id)`. Envía nombre/código/orden/activo. | Clubes, clases, honores, reportes, rankings. |
| Ideales de club | `GET /admin/club-ideals`, `GET /admin/club-types`, detalle `GET /admin/club-ideals/:id`. | `POST/PATCH/DELETE /admin/club-ideals(/:id)`. Envía club type, contenido, orden/activo. | Pantallas públicas/clubes por tipo. |
| Años eclesiásticos | `GET /admin/ecclesiastical-years`. Recibe años, vigencia y activo. | `POST/PATCH/DELETE /admin/ecclesiastical-years(/:id)`. Envía fechas, nombre y estado. | Inscripciones, carpetas anuales, investidura, rankings, cierre de año. |
| Tipos de relación | `GET /admin/relationship-types`. | `POST/PATCH/DELETE /admin/relationship-types(/:id)`. Envía nombre/código/activo. | Familia/representantes de usuarios. |
| Tipos de evento camporee | `GET /admin/camporee-event-types`. | `POST/PATCH/DELETE /admin/camporee-event-types(/:id)`. Envía nombre, código, descripción, activo. | Plantillas/eventos de camporee. Riesgo: permisos no están en seed activo. |
| Catálogo de clases | `GET /admin/classes`. | `POST/PATCH/DELETE /admin/classes(/:id)`. Envía nombre, club type, nivel, duración, requisitos base. | Clases operativas, inscripciones, investidura, validación. |
| Módulos/secciones de clase | `GET /admin/class-modules`, `GET /admin/class-sections`. | `POST/PATCH/DELETE` de módulos/secciones. Envía clase/módulo, nombre, orden, puntaje. | Clase detalle, progreso, validación. |
| Tipos de actividad | `GET /admin/activity-types`. | `POST/PATCH/DELETE /admin/activity-types(/:id)`. Envía nombre/código/activo. | Actividades. |
| Categorías finanzas/inventario | `GET /admin/finance-categories`, `GET /admin/inventory-categories`. | `POST/PATCH/DELETE` de categoría. Envía nombre, tipo/activo. | Finanzas e Inventario. |
| Especialidades catálogo | `GET /admin/honors-catalog` o `GET /honors`. | `POST/PATCH/DELETE /admin/honors-catalog(/:id)` o `/honors(/:id)`. Envía nombre, categoría, club types, descripción, materiales. | Especialidades operativas, requisitos, validación, evidencia. |
| Maestrías | `GET /admin/master-honors`, `GET /admin/honor-categories`, `GET /admin/honors-catalog`, `GET /catalogs/divisions`. | `POST/PATCH/DELETE /admin/master-honors(/:id)`, `POST /admin/master-honors/:id/recalculate`. Envía metadata, reglas/requisitos y divisiones. | Catálogo honores, app móvil, perfil de usuario. |
| Categorías de especialidades | `GET /admin/honor-categories`, detalle `GET /admin/honor-categories/:id`, especialidades por categoría `GET /honors`. | CRUD de categorías. Envía nombre, descripción, orden, activo. | Especialidades catálogo y honores operativos. |
| Recursos | `GET /resources`, `GET /resource-categories`, `GET /catalogs/club-types`, `/catalogs/divisions`, `/catalogs/unions`, `/catalogs/local-fields`. | `POST /resources` con `FormData`; `PATCH/DELETE /resources/:id`; `GET /resources/:id/signed-url` para descarga. | Categorías de recursos, territorios, usuarios consumidores. |
| Categorías de recursos | `GET /resource-categories`. | `POST/PATCH/DELETE /resource-categories(/:id)`. Envía nombre, descripción, activo. | Recursos. |

### 9.4 Gestión de clubes, clases, camporees y operaciones de club

| Pantalla | Solicita / recibe | Envía / muta | Relación con pantallas |
|---|---|---|---|
| Clubes listado | `GET /clubs` con filtros; catálogos de uniones/campos/distritos según filtros. Recibe clubes, secciones y metadatos. | Acciones de creación/importación/eliminación dependen de pantallas hijas. | Detalle de club, coordinación, actividades, finanzas, inventario, seguros. |
| Nuevo/importar club | `GET /admin/unions` y catálogos territoriales. | `POST /clubs` o importación por archivo. Envía datos de club, iglesia, secciones, tipo. | Listado y detalle de club. |
| Detalle club | `GET /clubs/:clubId`, `/clubs/:clubId/overview`, `/clubs/:clubId/leadership`, `/clubs/:clubId/sections`, `/clubs/:clubId/sections/:sectionId/members`. | `PATCH/DELETE /clubs/:id`; CRUD secciones; asignar/revocar roles `/clubs/:clubId/sections/:sectionId/roles`; sucesión/asignación director; consejeros de clase. | Unidades, miembros, seguros, actividades, reportes, ranking de secciones. |
| Unidades de club | `GET /clubs/:clubId`, `GET /clubs/:clubId/sections`, `GET /clubs/:clubId/units/:unitId`. | `POST /clubs/:clubId/units`, actualización de unidad, miembros de unidad. | Detalle club y miembros. |
| Coordinación | `GET /clubs`, `/catalogs/club-types`, `/catalogs/local-fields`, `/catalogs/districts`; API coordinación `/admin/coordination/local-fields/:id/zones` y assignments. | Crear/editar zonas, asignar coordinadores, agregar/quitar distritos. | Clubes, distritos, scope territorial, reportes. |
| Camporees locales | `GET /camporees`, detalle `GET /camporees/:id`, miembros/clubes/pagos/pending/eventos/venues/templates. | CRUD `/camporees`; inscribir miembros/clubes; pagos; aprobar/rechazar clubes, miembros y pagos; eventos y venues. | Camporee unión, seguros, eventos, pagos, rankings. |
| Camporees unión | `GET /camporees/union`, detalle `GET /camporees/union/:id`; usa endpoints de miembros, clubes, pagos y pending de unión. | CRUD `/camporees/union`; aprobaciones de unión; pagos; eventos de unión. | Camporees locales, campos/uniones, plantillas de eventos. |
| Plantillas de eventos camporee | `GET /camporee-event-templates`, detalle `GET /camporee-event-templates/:id`; catálogos `/admin/camporee-event-types`, `/admin/unions`, `/admin/local-fields`, `/classes`. | `POST/PATCH/DELETE /camporee-event-templates(/:id)`. Envía tipo, scope, puntos, penalizaciones, participantes, materiales/requisitos. | Eventos dentro de camporees locales/unión. Riesgo de permisos `camporee_events:*`. |
| Eventos de camporee | `GET /camporees/:id`, `GET /camporee-events/:eventId`, `GET /local-camporees/:id/venues` o `/union-camporees/:id/venues`. | `POST /local-camporees/:id/events`, `POST /union-camporees/:id/events`, clonar desde template, `PATCH/DELETE /camporee-events/:id`, `PATCH /camporee-events/:id/reorder`. | Detalle camporee tab eventos y plantillas. |
| Clases | `GET /classes`, `GET /catalogs/club-types`; detalle `GET /classes/:classId`, módulos/progreso. | Acción especial `POST /admin/classes/enrollments/expire-overdue` desde admin cuando aplica. | Inscripciones, validación, investidura, catálogo de clases. |
| Inscripciones | `GET /investiture/pending` con filtros. Recibe enrollments, usuario, clase, club, sección, estado. | Validación legacy `POST /enrollments/:id/validate` según componente. | Investidura, clases, usuarios. |
| Especialidades | `GET /honors`, `GET /honors/categories`, `GET /catalogs/club-types`; detalle `GET /honors/:honorId`. | `POST /honors`, `PATCH /honors/:id`; requisitos vía endpoints admin. | Catálogos honores, requisitos, revisión, evidencia. |
| Requisitos de especialidad | `GET /admin/honors/:honorId/requirements`, `GET /honors/:honorId`. | `POST /admin/honors/:honorId/requirements`, `PATCH/DELETE /admin/honors/requirements/:requirementId`, `PATCH /admin/honors/:honorId/requirements/reorder`. | Detalle honor y revisión de requisitos. |
| Revisión requisitos especialidad | `GET /admin/honors/requirements/pending-review`, `GET /honors`, `GET /honors/categories`. | `PATCH /admin/honors/requirements/batch-review` con `{ requirementIds, approved }`. | Requisitos de especialidad y catálogo honores. |
| Logros | `GET /admin/achievements/categories`, `GET /admin/achievements`, detalle `/admin/achievements/:id`, stats. | CRUD categorías/logros; upload imagen `/admin/achievements/:id/image`; retroactivo `/admin/achievements/retroactive/:id`. | Perfil/app móvil, eventos de progreso. |
| Actividades | `GET /clubs`, `/clubs/:clubId/sections`, `/clubs/:clubId/activities`, detalle `/activities/:id`, `/activities/:id/attendance`. | `POST /clubs/:clubId/activities`, `PATCH/DELETE /activities/:id`, `POST /activities/:id/attendance`. | Clubes, asistencia, rankings/achievements. |
| Finanzas | `GET /clubs`, `GET /finances/categories`, `GET /clubs/:clubId/finances`, `GET /clubs/:clubId/finances/summary`, detalle `/finances/:id`. | `POST /clubs/:clubId/finances`, `PATCH/DELETE /finances/:id`, `POST /finances/:id/evidences` con archivo/evidencia. | Clubes, reportes mensuales, rankings. |
| Inventario | `GET /clubs`, `GET /inventory/catalogs/inventory-categories`, `GET /inventory/clubs/:clubSectionId/inventory`. | `POST /inventory/clubs/:clubSectionId/inventory`, `PATCH/DELETE /inventory/inventory/:id`, historial `/inventory/:id/history`. | Clubes, categorías inventario, reportes. |
| Certificaciones | `GET /certifications/certifications`, detalle `/certifications/certifications/:id`, usuario `/certifications/users/:userId/certifications`. | Enroll/progress/delete vía `/certifications/users/:userId/certifications...`. | Usuarios, clases/honores, investidura. |
| Seguros | `GET /clubs`, miembros por sección `/clubs/:clubId/sections/:sectionId/members/insurance`, detalle `/users/:memberId/insurance`. | `POST /users/:memberId/insurance` FormData, `PATCH /insurance/:insuranceId` actualizar/estado. | Usuarios, camporees, clubes. |
| Seguros por vencer | `GET /insurance/expiring` con filtros. | Acciones de renovación derivan a Seguros/detalle usuario. | Seguros, usuarios, clubes/camporees. |

### 9.5 Materiales

| Pantalla | Solicita / recibe | Envía / muta | Relación con pantallas |
|---|---|---|---|
| Bandeja materiales | `GET /materials/orders` con filtros. Recibe órdenes, folio, estado, líneas, totales. | Acciones en detalle: aprobar/cancelar/entregar orden o líneas. | Detalle pedido, comprobantes, inventario, config. |
| Detalle pedido materiales | `GET /materials/orders/:folioOrId`. | `PATCH /materials/orders/:folioOrId/lines/:lineId`, `POST /materials/orders/:folioOrId/approve`, `/cancel`, `/deliver`. | Bandeja, comprobantes, inventario. |
| Comprobantes materiales | `GET /materials/receipts/:folioOrId` y orden asociada. | `POST /materials/receipts/:folioOrId/approve` o `/reject`. Envía decisión/observación. | Detalle pedido y bandeja. |
| Inventario materiales | `GET /materials/inventory`, `GET /materials/catalog/categories`, opcional `GET /admin/local-fields`. | `POST /materials/inventory`, `PATCH/DELETE /materials/inventory/:id`, variantes `/materials/inventory/:productId/variants/:variantId`. | Categorías, órdenes, config. |
| Categorías materiales | `GET /materials/categories`. | `POST/PATCH/DELETE /materials/categories(/:id)`. | Inventario materiales. |
| Configuración materiales | `GET /materials/config`, opcional `/materials/config/all`, `GET /admin/local-fields`. | `PATCH /materials/config` con datos bancarios/entrega por campo. | Bandeja, órdenes, recibos. |

### 9.6 Operaciones, validación e investidura

| Pantalla | Solicita / recibe | Envía / muta | Relación con pantallas |
|---|---|---|---|
| Validación | `GET /validation/pending`, historial `/validation/:entityType/:entityId/history`, elegibilidad `/validation/eligibility/:userId`. | `POST /validation/:entityType/:entityId/review` con `{ action, comment? }`; `POST /validation/submit` si se expone envío. | Clases, honores, usuarios, evidencia review. |
| Revisión de evidencias | `GET /evidence-review/pending`, detalle `/evidence-review/:type/:id`, historial `/evidence-review/:type/:id/history`. | `POST /evidence-review/:type/:id/approve`, `/reject`; bulk approve/reject. Envía ids, tipo y razón si rechazo. | Validación, usuarios, honores/clases. PDF usa `/api/evidence-review/pdf`. |
| PDF evidencia interno | `/api/evidence-review/pdf` llama backend detail y descarga archivo upstream. | Query con tipo/id; no muta dominio. | Revisión de evidencias. |
| Cargas por certificado | `GET /admin/certificate-bulk-imports/pending`, detalle `/admin/certificate-bulk-imports/:batchId`. | `POST /admin/certificate-bulk-imports/:batchId/approve|reject`, items approve/reject. | Certificaciones, usuarios, investidura. |
| Investidura pendientes | `GET /investiture/pending`, historial `/investiture/enrollments/:id/history`. | `POST /investiture/enrollments/:id/submit|club-approve|coordinator-approve|field-approve|invest|reject`, bulk approve/reject. | Inscripciones, clases, validación, cierre de año. |
| Pipeline investidura | `GET /investiture/pending` con filtros/estados; recibe timeline/historial por enrollment. | Mutaciones del pipeline de investidura. | Investidura pendientes, usuarios, clases. |
| Config investidura | `GET /admin/investiture/config`, detalle `/admin/investiture/config/:id`. | `POST/PATCH/DELETE /admin/investiture/config(/:id)`. Envía fechas/reglas por campo/año. | Investidura, cierre de año, años eclesiásticos. |
| Carpeta anual | `GET /annual-folders/evaluation/queue`, detalle `/annual-folders/:folderId`, by enrollment/section. | Crear carpeta, subir evidencias, submit carpeta/sección, evaluar/reabrir/confirmar unión. | Plantillas carpeta, rankings, clubes. |
| Plantillas carpeta anual | `GET /annual-folders/templates`, detalle `/annual-folders/templates/:id`, club types/años. | `POST/PATCH/DELETE /annual-folders/templates`, copy, CRUD secciones. | Carpeta anual, cierre de año, rankings. |
| Rankings carpeta anual | `GET /annual-folders/rankings`, breakdown `/annual-folders/rankings/:enrollmentId/breakdown`, categorías premio. | `POST /annual-folders/rankings/recalculate` si permiso. | Carpeta anual, pesos ranking, clubes. |
| Config ranking carpeta | `GET /annual-ranking-configs`, tiers `/ranking-tiers`, award categories. | `POST/PATCH/DELETE /annual-ranking-configs`, actualizar tiers/categorías. | Rankings carpeta anual y cierre de año. |
| Cierre de año | `GET /year-end/:yearId/preview`. | `POST /year-end/:yearId/close`. Envía confirmación/opciones del cierre. | Años eclesiásticos, inscripciones, directores, carpetas, investidura. |

### 9.7 Rankings y analítica

| Pantalla | Solicita / recibe | Envía / muta | Relación con pantallas |
|---|---|---|---|
| SLA | `GET /admin/analytics/sla-dashboard`. Recibe KPIs de pendientes, overdue, throughput y tasas. | No muta; refresh recarga consulta. | Validación, investidura, camporees. |
| Pesos rankings institucionales | `GET /ranking-weights`. | `POST/PATCH/DELETE /ranking-weights(/:id)`. Envía pesos que deben sumar 100. | Rankings carpeta anual. |
| Rankings miembros | `GET /member-rankings`, breakdown `/member-rankings/:enrollmentId/breakdown`. | Recalcular vía `POST /member-rankings/recalculate` si se expone. | Miembros, clases, camporees, secciones. |
| Pesos rankings miembros | `GET /member-ranking-weights`, detalle `/:id`; catálogos `/catalogs/club-types`. | `POST/PATCH/DELETE /member-ranking-weights(/:id)`. Envía pesos por tipo/año; suma 100. | Rankings miembros. |
| Rankings secciones | `GET /section-rankings`, miembros `/section-rankings/:sectionId/members`. | No muta desde listado. | Clubes, miembros, rankings miembros. |

### 9.8 Comunicaciones, solicitudes y reportes

| Pantalla | Solicita / recibe | Envía / muta | Relación con pantallas |
|---|---|---|---|
| Notificaciones | Si `notifications:club`, `GET /notifications/targets/club`. Recibe clubes/secciones autorizadas. | `POST /notifications/send` con `{ userId, title, body }`; `POST /notifications/broadcast`; `POST /notifications/club/:instanceType/:instanceId`. | Historial notificaciones, usuarios, clubes. |
| Historial notificaciones | `GET /notifications/history` con page/limit. | No muta. | Notificaciones. |
| Transferencias | `GET /requests/transfers`, detalle `/requests/transfers/:requestId`. | `POST /requests/transfers/:requestId/review` con decisión y comentario. | Clubes, asignaciones, membresías. |
| Asignaciones | `GET /requests/assignments`, detalle `/requests/assignments/:requestId`. | `POST /requests/assignments/:requestId/review`. | Usuarios, clubes, RBAC contextual. |
| Membresías | `GET /clubs` para contexto; `GET /club-sections/:sectionId/membership-requests`. | `POST /club-sections/:sectionId/membership-requests/:assignmentId/approve|reject`. | Clubes, usuarios, requests. |
| Mis reportes | `GET /enrollments/me/active`, fallback `/enrollments/my`; reportes por enrollment `/monthly-reports/enrollment/:enrollmentId`. | Crear/generar/enviar reporte mensual vía `/monthly-reports/:enrollmentId`, `/manual-data`, `/generate`, `/submit`. | Supervisión reportes, detalle reporte, clubes. |
| Detalle reporte | `GET /monthly-reports/:reportId`. | Manual data/generate/submit si acciones disponibles; PDF `/monthly-reports/:reportId/pdf`. | Mis reportes y supervisión. |
| Supervisión reportes | `GET /monthly-reports/admin/list` + catálogos `club-types`, `divisions`, `unions`, `local-fields`. | Descarga PDF; cambio de estado si componente lo habilita. | Detalle reporte, clubes, territorios. |
| Soporte | `GET /admin/support/reports`. | `PATCH /admin/support/reports/:reportId/status`. Envía nuevo estado/seguimiento. | Usuarios/operaciones; no está atado a un dominio único. |
| Miembro del mes | `GET /member-of-month/admin/list`, `GET /clubs/:clubId/sections/:sectionId/member-of-month`. | Historial/evaluación: `/clubs/:clubId/sections/:sectionId/member-of-month/history|evaluate`. | Clubes, secciones, rankings/achievements. |

### 9.9 Administración y sistema

| Pantalla | Solicita / recibe | Envía / muta | Relación con pantallas |
|---|---|---|---|
| RBAC hub | No llama API; lista accesos a permisos, roles, matriz y permisos de usuario. | No muta. | Todas las pantallas con permisos. |
| Permisos | `GET /admin/rbac/permissions`, detalle `/:id`. | `POST/PATCH/DELETE /admin/rbac/permissions(/:id)`. Envía `permission_name`, descripción, activo. | Roles, matriz, user permissions. |
| Roles | `GET /admin/rbac/roles?active=all`. | `POST/PATCH/DELETE /admin/rbac/roles(/:id)`. Envía nombre, descripción, activo. | Permisos, matriz, usuarios. |
| Editar rol | `GET /admin/rbac/roles/:roleId`, `GET /admin/rbac/permissions`. | `PUT /admin/rbac/roles/:roleId/permissions`, `DELETE /admin/rbac/roles/:roleId/permissions/:permissionId`, PATCH rol. | Roles y matriz RBAC. |
| Matriz RBAC | `GET /admin/rbac/roles`, `GET /admin/rbac/permissions`. | `PUT /admin/rbac/roles/:roleId/permissions` con `permission_ids`. | Roles, permisos, navegación completa. |
| Permisos de usuario | `GET /admin/rbac/permissions`; al buscar usuario usa `/admin/users`/RBAC user endpoints. | `POST/DELETE /admin/rbac/users/:userId/permissions`, `POST/DELETE /admin/rbac/users/:userId/roles`. | Usuarios, roles, permisos. |
| Config sistema | `GET /system-config`. | `PATCH /system-config/:key` con valor/config. | SLA, rankings, feature flags, jobs. |
| Categorías puntuación | `GET /divisions/scoring-categories`, `/unions/:id/scoring-categories`, `/local-fields/:id/scoring-categories`. | `POST/PATCH/DELETE` por nivel territorial. | Rankings, carpeta anual, territorios. |
| Jobs y colas | `GET /admin/analytics/jobs-overview`, `GET /admin/analytics/cron-runs`. | `POST /admin/analytics/jobs/:queue/:jobId/retry`. | Historial jobs, notificaciones, achievements, reportes. |
| Historial jobs | `GET /admin/analytics/cron-runs/history` con filtros (`job_name`, `status`, `since`, `until`, `page`). | No muta. | Jobs y colas. |

### 9.10 Pantallas alias, detalle y rutas derivadas

| Ruta | Contrato de datos | Relación |
|---|---|---|
| `/dashboard/materials` | No llama API; redirige a `/dashboard/materials/inbox`. | Materiales bandeja. |
| `/dashboard/clubs/v2`, `/dashboard/clubs/v2/[id]` | No llama API; redirige a rutas nuevas. | Compatibilidad links legacy de Clubes. |
| `/dashboard/annual-folders/categories`, `/dashboard/annual-folders/evaluate` | No llama API; redirige a ranking-config o carpeta anual. | Compatibilidad links legacy de Carpeta anual. |
| Rutas `new/edit/detail` | Usan el mismo contrato del módulo padre más `GET detalle` cuando aplica. | Siempre deben mantener breadcrumb/volver al listado padre. |
