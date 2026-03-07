# Sistema de Permisos - SACDIA Admin Panel

**Fecha**: 9 de febrero de 2026  
**Status**: ACTIVE

> [!IMPORTANT]
> Este documento sigue siendo útil como catálogo de permisos y convención de nombres.
> El contrato oficial de autorización ya no es el arreglo plano `permissions` del cliente.
> La fuente de verdad actual para autorización es:
> - `docs/01-FEATURES/auth/AUTHORIZATION-CANONICAL-CONTRACT.md`
> - `docs/01-FEATURES/auth/RBAC-ENFORCEMENT-MATRIX.md`
> - `docs/01-FEATURES/auth/CLUB-ROLE-ASSIGNMENT-FIRST-CONTRACT.md`

> [!NOTE]
> Varias secciones históricas de este documento describen un modelo donde el frontend
> resolvía más cosas localmente. Desde 2026-03-07 la dirección técnica oficial es:
> backend enforced permissions + clientes consumidores del bloque `authorization`.

---

## Resumen

El sistema de permisos de SACDIA utiliza un modelo RBAC (Role-Based Access Control) con permisos granulares. Los permisos se asignan a roles, y los roles se asignan a usuarios.

### Arquitectura

```
users ──→ users_roles ──→ roles ──→ role_permissions ──→ permissions
                                         ↑
club_role_assignments ───────────────────┘
```

- **Fuente de verdad**: tabla `permissions` en la base de datos
- **Frontend**: constantes en `src/lib/auth/permissions.ts` (solo para autocompletado)
- **Verificación**: hook `usePermissions()` que valida contra permisos reales del usuario

---

## Convención de Nomenclatura

### Formato: `recurso:acción`

```
{resource}:{action}
```

| Componente | Reglas | Ejemplos |
|------------|--------|----------|
| `resource` | snake_case, sustantivo plural | `users`, `club_instances`, `local_fields` |
| `action` | snake_case, verbo | `read`, `create`, `update`, `delete` |
| Separador | `:` (colon) | `users:create`, `clubs:read` |

### Acciones Estándar

| Acción | Descripción |
|--------|-------------|
| `read` | Ver listado de recursos |
| `read_detail` | Ver detalle de un recurso específico |
| `create` | Crear nuevo recurso |
| `update` | Editar recurso existente |
| `delete` | Eliminar/desactivar recurso |
| `export` | Exportar datos |
| `assign` | Asignar relación (ej: rol a usuario) |
| `revoke` | Revocar relación |
| `manage` | Gestionar (agrupa varias acciones) |
| `view` | Solo visualizar (sin CRUD) |

---

## Catálogo de Permisos por Módulo

### Usuarios
| Permiso | Descripción |
|---------|-------------|
| `users:read` | Ver listado de usuarios |
| `users:read_detail` | Ver detalle/perfil de un usuario |
| `users:create` | Crear usuario manualmente |
| `users:update` | Editar datos de usuario |
| `users:delete` | Desactivar/eliminar usuario |
| `users:export` | Exportar listado de usuarios |

### Roles y Permisos
| Permiso | Descripción |
|---------|-------------|
| `roles:read` | Ver roles |
| `roles:create` | Crear roles |
| `roles:update` | Editar roles |
| `roles:delete` | Eliminar roles |
| `roles:assign` | Asignar roles globales a usuarios |
| `permissions:read` | Ver permisos |
| `permissions:assign` | Asignar permisos a roles |

### Clubes
| Permiso | Descripción |
|---------|-------------|
| `clubs:read` | Ver clubes |
| `clubs:create` | Crear club |
| `clubs:update` | Editar club |
| `clubs:delete` | Desactivar club |
| `club_instances:read` | Ver instancias (Aventureros, Conquistadores, GM) |
| `club_instances:create` | Crear instancia de club |
| `club_instances:update` | Editar instancia |
| `club_instances:delete` | Desactivar instancia |
| `club_roles:read` | Ver asignaciones de rol de club |
| `club_roles:assign` | Asignar rol de club a usuario |
| `club_roles:revoke` | Revocar rol de club |

### Jerarquía Geográfica
| Permiso | Descripción |
|---------|-------------|
| `countries:read` | Ver países |
| `countries:create` | Crear país |
| `countries:update` | Editar país |
| `countries:delete` | Eliminar país |
| `unions:read` | Ver uniones |
| `unions:create` | Crear unión |
| `unions:update` | Editar unión |
| `unions:delete` | Eliminar unión |
| `local_fields:read` | Ver campos locales |
| `local_fields:create` | Crear campo local |
| `local_fields:update` | Editar campo local |
| `local_fields:delete` | Eliminar campo local |
| `churches:read` | Ver iglesias |
| `churches:create` | Crear iglesia |
| `churches:update` | Editar iglesia |
| `churches:delete` | Eliminar iglesia |

### Catálogos de Referencia
| Permiso | Descripción |
|---------|-------------|
| `catalogs:read` | Ver catálogos (alergias, enfermedades, etc.) |
| `catalogs:create` | Crear ítem de catálogo |
| `catalogs:update` | Editar ítem de catálogo |
| `catalogs:delete` | Eliminar ítem de catálogo |

### Clases y Honores
| Permiso | Descripción |
|---------|-------------|
| `classes:read` | Ver clases progresivas |
| `classes:create` | Crear clase |
| `classes:update` | Editar clase |
| `classes:delete` | Eliminar clase |
| `honors:read` | Ver honores/especialidades |
| `honors:create` | Crear honor |
| `honors:update` | Editar honor |
| `honors:delete` | Eliminar honor |
| `honor_categories:read` | Ver categorías de honores |
| `honor_categories:create` | Crear categoría |
| `honor_categories:update` | Editar categoría |
| `honor_categories:delete` | Eliminar categoría |

### Actividades
| Permiso | Descripción |
|---------|-------------|
| `activities:read` | Ver actividades |
| `activities:create` | Crear actividad |
| `activities:update` | Editar actividad |
| `activities:delete` | Eliminar actividad |
| `attendance:read` | Ver asistencia |
| `attendance:manage` | Registrar/modificar asistencia |

### Finanzas
| Permiso | Descripción |
|---------|-------------|
| `finances:read` | Ver finanzas |
| `finances:create` | Crear registro financiero |
| `finances:update` | Editar registro financiero |
| `finances:delete` | Eliminar registro financiero |
| `finances:export` | Exportar datos financieros |

### Inventario
| Permiso | Descripción |
|---------|-------------|
| `inventory:read` | Ver inventario |
| `inventory:create` | Crear ítem |
| `inventory:update` | Editar ítem |
| `inventory:delete` | Eliminar ítem |

### Reportes y Dashboard
| Permiso | Descripción |
|---------|-------------|
| `reports:view` | Ver reportes generales |
| `reports:export` | Exportar reportes |
| `dashboard:view` | Ver dashboard |

### Sistema
| Permiso | Descripción |
|---------|-------------|
| `settings:read` | Ver configuración del sistema |
| `settings:update` | Modificar configuración |
| `ecclesiastical_years:read` | Ver años eclesiásticos |
| `ecclesiastical_years:create` | Crear año eclesiástico |
| `ecclesiastical_years:update` | Editar año eclesiástico |

---

## Implementación en el Admin Panel

### Archivos clave

| Archivo | Propósito |
|---------|-----------|
| `src/lib/auth/permissions.ts` | Constantes de permisos + agrupación por módulo |
| `src/lib/auth/use-permissions.ts` | Hook `usePermissions()` |
| `src/lib/auth/types.ts` | Tipo `AuthUser` con campo `permissions` |
| `src/lib/auth/auth-context.tsx` | Contexto de autenticación |

### Uso en componentes

```tsx
import { usePermissions } from "@/lib/auth/use-permissions";
import { USERS_CREATE, USERS_DELETE } from "@/lib/auth/permissions";

function UsersPage() {
  const { can, canAny, canAll, isSuperAdmin } = usePermissions();

  return (
    <div>
      {can(USERS_CREATE) && <button>Crear usuario</button>}
      {canAny([USERS_CREATE, USERS_DELETE]) && <AdminToolbar />}
    </div>
  );
}
```

### API del hook `usePermissions()`

| Método | Parámetro | Retorno | Descripción |
|--------|-----------|---------|-------------|
| `can(permission)` | `string` | `boolean` | ¿Tiene este permiso? |
| `canAny(permissions)` | `string[]` | `boolean` | ¿Tiene al menos uno? |
| `canAll(permissions)` | `string[]` | `boolean` | ¿Tiene todos? |
| `hasRole(role)` | `string` | `boolean` | ¿Tiene este rol? |
| `isSuperAdmin` | — | `boolean` | ¿Es super_admin? |
| `isAdmin` | — | `boolean` | ¿Es admin/super_admin/coordinator? |

### Reglas especiales

- **`super_admin`** tiene **todos los permisos** implícitamente (bypass en el hook)
- Los permisos se obtienen del backend en `GET /auth/me` → campo `permissions: string[]`
- Si un permiso existe en DB pero no en las constantes del frontend, el sistema **no se rompe**

---

## Módulo Backend (NestJS)

El backend expone un módulo `RbacModule` bajo el prefix `/admin/rbac`, protegido por `JwtAuthGuard` + `GlobalRolesGuard`.

### Archivos backend

| Archivo | Propósito |
|---------|-----------|
| `src/rbac/rbac.module.ts` | Módulo NestJS, registrado en `app.module.ts` |
| `src/rbac/rbac.controller.ts` | Controller con 8 endpoints |
| `src/rbac/rbac.service.ts` | Lógica CRUD + sync de permisos |
| `src/rbac/dto/create-permission.dto.ts` | DTO con validación regex `resource:action` |
| `src/rbac/dto/update-permission.dto.ts` | DTO para actualización parcial |
| `src/rbac/dto/assign-permissions.dto.ts` | DTO para asignación bulk |

### Endpoints

| Método | Ruta | Rol mínimo | Descripción |
|--------|------|------------|-------------|
| `GET` | `/admin/rbac/permissions` | admin | Listar permisos |
| `GET` | `/admin/rbac/permissions/:id` | admin | Detalle permiso |
| `POST` | `/admin/rbac/permissions` | super_admin | Crear permiso |
| `PATCH` | `/admin/rbac/permissions/:id` | super_admin | Editar permiso |
| `DELETE` | `/admin/rbac/permissions/:id` | super_admin | Desactivar permiso (soft delete) |
| `GET` | `/admin/rbac/roles` | admin | Listar roles con permisos |
| `GET` | `/admin/rbac/roles/:id` | admin | Detalle rol con permisos |
| `PUT` | `/admin/rbac/roles/:id/permissions` | super_admin | Sync permisos (reemplaza lista completa) |
| `DELETE` | `/admin/rbac/roles/:id/permissions/:pid` | super_admin | Remover permiso de rol |

### Flujo de datos: Login → Permisos

1. `POST /auth/login` → retorna `user.roles: string[]`
2. `GET /auth/me` → retorna `roles: string[]` + `permissions: string[]` (aplanados desde `users_roles → roles → role_permissions → permissions`)
3. Frontend almacena en `AuthContext` → `usePermissions()` los consume

---

## Pantallas del Admin Panel

### Archivos frontend (RBAC)

| Archivo | Propósito |
|---------|-----------|
| `src/lib/rbac/types.ts` | Tipos `Permission`, `Role`, `RolePermission` |
| `src/lib/rbac/service.ts` | Llamadas API con unwrap de `{ status, data }` |
| `src/lib/rbac/actions.ts` | Server Actions para formularios |
| `src/components/rbac/permission-form.tsx` | Formulario crear/editar permiso |
| `src/components/rbac/role-permissions-matrix.tsx` | Matriz interactiva de asignación permisos↔roles |

### Rutas

| Ruta | Descripción |
|------|-------------|
| `/dashboard/rbac` | Índice con tarjetas de navegación |
| `/dashboard/rbac/permissions` | Tabla de permisos (listado, editar, desactivar) |
| `/dashboard/rbac/permissions/new` | Formulario crear permiso |
| `/dashboard/rbac/permissions/[id]` | Formulario editar permiso |
| `/dashboard/rbac/roles` | Matriz de asignación permisos a roles |

### Pantalla: Permisos (`/dashboard/rbac/permissions`)

- Tabla con columnas: Nombre (code), Recurso, Acción, Descripción, Estado, Acciones
- Botón "Nuevo Permiso" → formulario con validación `resource:action`
- Acciones por fila: Editar, Desactivar

### Pantalla: Roles y Permisos (`/dashboard/rbac/roles`)

- Tabs por rol (super_admin, admin, coordinator, etc.)
- Permisos agrupados por recurso con checkboxes
- Checkbox de grupo para seleccionar/deseleccionar todos los permisos de un recurso
- Búsqueda por nombre de permiso o descripción
- Botón "Guardar" que ejecuta `PUT /admin/rbac/roles/:id/permissions` (sync completo)
- Indicador visual de estado indeterminado cuando solo algunos permisos del grupo están seleccionados

### Navegación

Sección "Seguridad" en el sidebar con:
- Permisos (`KeyRound` icon) → `/dashboard/rbac/permissions`
- Roles (`Shield` icon) → `/dashboard/rbac/roles`

---

## Agregar un Nuevo Permiso

### Desde la UI del Admin Panel

1. Navegar a `/dashboard/rbac/permissions/new`
2. Ingresar nombre en formato `resource:action` y descripción
3. Guardar → el permiso se crea en la DB
4. Ir a `/dashboard/rbac/roles` → seleccionar el rol → marcar el checkbox del nuevo permiso → Guardar

### Manualmente (SQL / API)

1. Insertar en tabla `permissions` de la DB
2. Asignar al rol correspondiente en `role_permissions`
3. *(Opcional)* Agregar constante en `src/lib/auth/permissions.ts` para autocompletado
4. *(Opcional)* Agregar al `PERMISSION_GROUPS` si debe aparecer en la UI de asignación

---

## Migración desde formato anterior

El backend original usaba formato `ACTION:ENTITY` en uppercase (ej: `CREATE:USERS`).  
El formato estandarizado es `resource:action` en lowercase (ej: `users:create`).

Script de migración: `docs/03-DATABASE/migrations/script_06_admin_permissions.sql`

---

## Ver También

- [SCHEMA-REFERENCE.md](../../03-DATABASE/SCHEMA-REFERENCE.md) — Tablas `permissions`, `role_permissions`, `roles`
- [ARCHITECTURE-DECISIONS.md](../../02-API/ARCHITECTURE-DECISIONS.md#5-sistema-de-membresía-y-roles) — ADR de roles
- [restrucura-roles.md](../../history/source/api/restrucura-roles.md) — Guía histórica de integración Flutter

---

**Generado**: 2026-02-09  
**Última actualización**: 2026-02-09 (v2 — módulo RBAC backend + pantallas admin)
