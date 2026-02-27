# SACDIA Admin Panel — Especificación Completa para Rediseño

**Fecha**: 2026-02-24
**Destino**: Nuevo desarrollador frontend
**Objetivo**: Rehacer el panel admin desde cero en Next.js con diseño inspirado en Supabase, manteniendo paridad funcional con los módulos runtime activos
**Estado**: Documento de referencia funcional — no dicta diseño visual, solo comportamientos y flujos

---

## Tabla de Contenidos

1. [Contexto del Sistema](#1-contexto-del-sistema)
2. [Stack y Convenciones](#2-stack-y-convenciones)
3. [Sistema RBAC (Central)](#3-sistema-rbac-central)
4. [Layout del Panel](#4-layout-del-panel)
5. [Autenticación](#5-autenticación)
6. [Dashboard](#6-dashboard)
7. [Usuarios](#7-usuarios)
8. [Catálogos](#8-catálogos)
9. [Clubes](#9-clubes)
10. [Operativo — Camporees](#10-operativo--camporees)
11. [Operativo — Clases Progresivas](#11-operativo--clases-progresivas)
12. [Operativo — Honores](#12-operativo--honores)
13. [Finanzas (obligatorio en rediseño)](#13-finanzas-obligatorio-en-rediseño)
14. [Actividades (obligatorio en rediseño)](#14-actividades-obligatorio-en-rediseño)
15. [Inventario (obligatorio en rediseño)](#15-inventario-obligatorio-en-rediseño)
16. [Seguros (planificado)](#16-seguros-planificado)
17. [Certificaciones Guías Mayores (obligatorio en rediseño)](#17-certificaciones-guías-mayores-obligatorio-en-rediseño)
18. [Comunicaciones — Notificaciones](#18-comunicaciones--notificaciones)
19. [Folders — Carpetas de Evidencias](#19-folders--carpetas-de-evidencias)
20. [Sistema RBAC — Pantallas](#20-sistema-rbac--pantallas)
21. [Criterios de Aceptación, Pruebas y DoD](#21-criterios-de-aceptación-pruebas-y-dod)
22. [Glosario del Dominio](#22-glosario-del-dominio)

---

## 1. Contexto del Sistema

### ¿Qué es SACDIA?

SACDIA es un sistema de administración para clubes juveniles adventistas: **Conquistadores**, **Aventureros** y **Guías Mayores**. El sistema tiene tres aplicaciones:

- **sacdia-backend** — API REST (NestJS + Prisma + PostgreSQL vía Supabase)
- **sacdia-admin** — Panel web para administradores (este proyecto)
- **sacdia-app** — App móvil para usuarios finales (Flutter)

### ¿Quién usa el panel admin?

Solo usuarios con roles administrativos globales pueden acceder al panel. Los roles son:

| Rol | Descripción |
|-----|-------------|
| `super_admin` | Acceso total, bypass de todos los permisos |
| `admin` | Acceso amplio de gestión, sin modificar el sistema RBAC |
| `coordinator` | Acceso limitado a su ámbito geográfico (unión o campo local) |

### Principio fundamental

El panel es una herramienta de gestión back-office. Cada sección del panel está protegida por permisos granulares. El sistema RBAC es la columna vertebral de todo el panel — **cada acción visible en la UI debe validar si el usuario tiene el permiso correspondiente antes de renderizarse**.

---

## 2. Stack y Convenciones

### Tecnologías

| Capa | Tecnología |
|------|-----------|
| Framework | Next.js 14+ (App Router; versión objetivo actual del repo: 16) |
| UI | shadcn/ui (inspirado en Supabase — paleta neutra, densidad media) |
| Estilos | Tailwind CSS v4 |
| Iconos | lucide-react (exclusivo, no mezclar con otras librerías) |
| Forms | React Hook Form + Zod |
| Auth | Supabase Auth (SSR con cookies) |
| HTTP | Axios con interceptors + wrappers en `src/lib/api` |
| Server state | TanStack Query (React Query) |
| Estado global | React Context (sin Redux ni Zustand) |

### Estructura de carpetas

```
src/
├── app/
│   ├── (auth)/          — Rutas públicas: login
│   │   └── login/
│   ├── (dashboard)/     — Route Group protegido (la URL no incluye "(dashboard)")
│   │   ├── layout.tsx   — Layout con sidebar + header + auth guard
│   │   └── dashboard/   — Prefijo real de URL (`/dashboard/*`)
│   │       ├── page.tsx           — `/dashboard`
│   │       ├── users/             — `/dashboard/users`
│   │       ├── clubs/             — `/dashboard/clubs`
│   │       ├── catalogs/          — `/dashboard/catalogs`
│   │       ├── camporees/         — `/dashboard/camporees`
│   │       ├── classes/           — `/dashboard/classes`
│   │       ├── honors/            — `/dashboard/honors`
│   │       ├── finances/          — `/dashboard/finances`
│   │       ├── activities/        — `/dashboard/activities`
│   │       ├── inventory/         — `/dashboard/inventory`
│   │       ├── insurance/         — `/dashboard/insurance`
│   │       ├── certifications/    — `/dashboard/certifications`
│   │       ├── notifications/     — `/dashboard/notifications`
│   │       ├── folders/           — `/dashboard/folders`
│   │       └── rbac/              — `/dashboard/rbac`
│   └── api/
│       └── auth/        — Route handlers de autenticación
├── components/
│   ├── ui/              — Componentes shadcn/ui base
│   ├── layout/          — Sidebar, header, breadcrumbs, nav-items
│   ├── shared/          — Componentes reutilizables entre módulos
│   └── [feature]/       — Componentes específicos de cada módulo
└── lib/
    ├── supabase/        — Cliente Supabase (server + client)
    ├── auth/            — Sesión, guards, tipos, hook usePermissions
    ├── api/             — Cliente HTTP y funciones por módulo
    └── [feature]/       — Servicios, acciones y tipos por módulo
```

### Convenciones de código

- **Server Components** por defecto. Usar `'use client'` solo cuando se necesite estado, efectos o acceso al browser.
- **Autenticación en server**: siempre usar `createClient()` de `@/lib/supabase/server`.
- **Formularios**: React Hook Form con validación Zod. Envío mediante Server Actions.
- **Fetching**: `src/lib/api/` es la única capa autorizada para llamar backend. Server Components llaman servicios server-safe; Client Components usan TanStack Query.
- **Paginación**: por query params en URL (`?page=1&limit=20`). El servidor lee los params y renderiza.
- **Filtros**: formularios que hacen GET al modificarse. Los filtros activos viven en la URL.
- **Errores de API**: el cliente HTTP distingue entre errores de red, 4xx y 5xx. La UI muestra estados vacíos o banners de error según el caso.
- **Rutas**: usar route groups de Next.js (`(dashboard)`) y colgar módulos bajo `app/(dashboard)/dashboard/*` para mantener URLs limpias (`/dashboard/users`, `/dashboard/clubs`, etc.).
- **Commits**: Conventional Commits — `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`

---

## 3. Sistema RBAC (Central)

Esta sección es crítica. Todo el sistema de acceso del panel gira en torno al RBAC.

### Arquitectura de datos

```
users
  └── users_roles (tabla pivote)
        └── roles
              └── role_permissions (tabla pivote)
                    └── permissions
```

También existe `club_role_assignments` para roles de club. En el rediseño del panel se usará un **modelo dual**:

- **Roles globales + permisos** para navegación y operaciones administrativas globales.
- **Roles de club** para operaciones operativas por club/instancia.
- **Regla de integración**: el panel no debe depender de supuestos; si una operación requiere contexto club, se valida con permisos efectivos y/o role guards del backend.

### Flujo: Login → Permisos disponibles

1. Usuario hace POST `/api/v1/auth/login` con email + password
2. El backend valida con Supabase Auth y retorna JWT
3. En cada request autenticado, el panel llama `GET /api/v1/auth/me`
4. La respuesta incluye:
   ```json
   {
     "user_id": "uuid",
     "email": "admin@sacdia.org",
     "roles": ["admin"],
     "permissions": ["users:read", "users:read_detail", "clubs:read", ...]
   }
   ```
5. El `AuthContext` almacena el usuario con sus permisos
6. El hook `usePermissions()` los expone a los componentes

### Hook `usePermissions()`

```tsx
const { can, canAny, canAll, hasRole, isSuperAdmin, isAdmin } = usePermissions();

// Uso:
if (can("users:create")) { /* mostrar botón crear */ }
if (canAny(["clubs:update", "clubs:delete"])) { /* mostrar acciones */ }
if (isSuperAdmin) { /* mostrar sección sistema */ }
```

| Método | Parámetro | Retorna | Descripción |
|--------|-----------|---------|-------------|
| `can(p)` | `string` | `boolean` | ¿Tiene este permiso exacto? |
| `canAny(ps)` | `string[]` | `boolean` | ¿Tiene al menos uno? |
| `canAll(ps)` | `string[]` | `boolean` | ¿Tiene todos? |
| `hasRole(r)` | `string` | `boolean` | ¿Tiene este rol global? |
| `isSuperAdmin` | — | `boolean` | Rol `super_admin` |
| `isAdmin` | — | `boolean` | `super_admin` o `admin` o `coordinator` |

**Regla de `super_admin`**: tiene bypass total. El hook siempre retorna `true` para cualquier `can()` si el usuario es super_admin.

### Convención de permisos

Formato: `recurso:acción` en snake_case minúsculas.

| Acción estándar | Descripción |
|----------------|-------------|
| `read` | Ver listado |
| `read_detail` | Ver detalle individual |
| `create` | Crear nuevo registro |
| `update` | Editar registro existente |
| `delete` | Eliminar o desactivar |
| `export` | Exportar datos |
| `assign` | Asignar relación (ej: rol a usuario) |
| `revoke` | Revocar relación |
| `manage` | Gestionar (agrupa varias acciones) |
| `view` | Solo visualizar (sin CRUD) |

### Catálogo completo de permisos

#### Usuarios
| Permiso | Descripción |
|---------|-------------|
| `users:read` | Ver listado de usuarios |
| `users:read_detail` | Ver detalle/perfil de un usuario |
| `users:create` | Crear usuario manualmente |
| `users:update` | Editar datos de usuario |
| `users:delete` | Desactivar/eliminar usuario |
| `users:export` | Exportar listado de usuarios |

#### Roles y Permisos
| Permiso | Descripción |
|---------|-------------|
| `roles:read` | Ver roles |
| `roles:create` | Crear roles |
| `roles:update` | Editar roles |
| `roles:delete` | Eliminar roles |
| `roles:assign` | Asignar roles globales a usuarios |
| `permissions:read` | Ver permisos |
| `permissions:assign` | Asignar permisos a roles |

#### Clubes
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

#### Geografía
| Permiso | Descripción |
|---------|-------------|
| `countries:read/create/update/delete` | Gestión de países |
| `unions:read/create/update/delete` | Gestión de uniones |
| `local_fields:read/create/update/delete` | Gestión de campos locales |
| `districts:read/create/update/delete` | Gestión de distritos |
| `churches:read/create/update/delete` | Gestión de iglesias |

#### Catálogos de referencia
| Permiso | Descripción |
|---------|-------------|
| `catalogs:read` | Ver catálogos (alergias, enfermedades, etc.) |
| `catalogs:create` | Crear ítem de catálogo |
| `catalogs:update` | Editar ítem de catálogo |
| `catalogs:delete` | Eliminar ítem de catálogo |

#### Clases y Honores
| Permiso | Descripción |
|---------|-------------|
| `classes:read/create/update/delete` | Gestión de clases progresivas |
| `honors:read/create/update/delete` | Gestión de honores/especialidades |
| `honor_categories:read/create/update/delete` | Gestión de categorías de honores |

#### Actividades
| Permiso | Descripción |
|---------|-------------|
| `activities:read/create/update/delete` | Gestión de actividades |
| `attendance:read` | Ver asistencia |
| `attendance:manage` | Registrar/modificar asistencia |

#### Camporees
| Permiso | Descripción |
|---------|-------------|
| `camporees:read/create/update/delete` | Gestión de camporees |

#### Finanzas
| Permiso | Descripción |
|---------|-------------|
| `finances:read` | Ver movimientos financieros |
| `finances:create` | Crear movimiento |
| `finances:update` | Editar movimiento |
| `finances:delete` | Eliminar movimiento |
| `finances:export` | Exportar datos financieros |

#### Inventario
| Permiso | Descripción |
|---------|-------------|
| `inventory:read/create/update/delete` | Gestión de inventario |

#### Certificaciones y Folders
| Permiso | Descripción |
|---------|-------------|
| `certifications:read/manage` | Consulta y gestión administrativa de certificaciones |
| `folders:read/manage` | Consulta y gestión administrativa de carpetas de evidencias |

#### Comunicaciones
| Permiso | Descripción |
|---------|-------------|
| `notifications:send` | Envío directo de notificaciones |
| `notifications:broadcast` | Envío masivo global |
| `notifications:club` | Envío por club/instancia |

#### Dashboard y Reportes
| Permiso | Descripción |
|---------|-------------|
| `dashboard:view` | Ver el dashboard principal |
| `reports:view` | Ver reportes generales |
| `reports:export` | Exportar reportes |

#### Sistema
| Permiso | Descripción |
|---------|-------------|
| `settings:read` | Ver configuración del sistema |
| `settings:update` | Modificar configuración |
| `ecclesiastical_years:read/create/update` | Gestión de años eclesiásticos |

### Tabla de roles y accesos por defecto

| Sección del panel | `super_admin` | `admin` | `coordinator` |
|-------------------|:---:|:---:|:---:|
| Dashboard | ✅ | ✅ | ✅ |
| Usuarios (lista) | ✅ | ✅ | ✅ (solo su ámbito) |
| Usuarios (crear/editar/eliminar) | ✅ | ✅ | ❌ |
| Catálogos (lectura) | ✅ | ✅ | ✅ |
| Catálogos (CRUD) | ✅ | ✅ | ❌ |
| Clubes (lectura) | ✅ | ✅ | ✅ (solo su ámbito) |
| Clubes (crear/editar) | ✅ | ✅ | ❌ |
| Operativo (lectura) | ✅ | ✅ | ✅ |
| Clases/Honores (CRUD de catálogo admin) | ✅ | ❌ | ❌ |
| Operativo por club (mutaciones runtime) | ✅* | ✅* | ✅* |
| Finanzas | ✅ | ✅ | ✅ (solo su ámbito) |
| Notificaciones (send) | ✅ | ✅ | ❌ |
| Folders (lectura) | ✅ | ✅ | ✅ (solo su ámbito) |
| Sistema RBAC (lectura) | ✅ | ✅ | ❌ |
| Sistema RBAC (modificar) | ✅ | ❌ | ❌ |

\* Requiere autorización híbrida: permisos globales efectivos y/o club roles válidos según guard backend.

### Alineación obligatoria para módulos operativos (global + club)

Para evitar `403` funcionales en módulos operativos, se define como requisito de backend para este rediseño:

- Mantener autorización por `club_role_assignments` para operaciones de instancia/club.
- Habilitar acceso equivalente por permisos globales para actores administrativos autorizados.
- Si el endpoint runtime actual solo acepta roles de club, crear estrategia explícita:
  - guard híbrido (club-role OR permiso global), o
  - endpoint administrativo paralelo bajo prefijo `api/v1/admin/...`.
- Aplicar la regla en: camporees, activities, finances, inventory, classes/honors (lectura/progreso), certifications y folders cuando corresponda.

### Scope de sesión (ámbito geográfico)

El backend limita automáticamente qué datos puede ver el usuario según su rol y ubicación. El panel usa dos fuentes complementarias:

- `GET /api/v1/auth/me` para contexto inicial de roles e identificadores geográficos.
- `meta.scope` de `GET /api/v1/admin/users` como fuente final del alcance aplicado en consultas administrativas.

| Tipo | Descripción |
|------|-------------|
| `ALL` | Sin restricción geográfica (super_admin) |
| `UNION` | Solo usuarios/clubes de una unión específica |
| `LOCAL_FIELD` | Solo usuarios/clubes de un campo local específico |

Reglas obligatorias de alcance:

- `admin` con `union_id` => scope `UNION`.
- `admin` con solo `local_field_id` => scope `LOCAL_FIELD`.
- `admin` sin `union_id` ni `local_field_id` => backend responde `403`.
- `coordinator` sin `local_field_id` => backend responde `403`.
- La UI debe respetar scope: filtros fuera de alcance deben estar bloqueados y preservados en query.

### Proteger rutas y componentes

**Rutas enteras**: el dashboard layout llama `requireAdminUser()` en el servidor. Si el usuario no tiene rol admin, redirige a `/login`.

**Secciones y botones**: usar el hook `usePermissions()` en Client Components, o verificar directamente en Server Components consultando la sesión:

```tsx
// Server Component
const user = await getCurrentUser();
const canCreate = hasPermission(user, "users:create");

// Client Component
const { can } = usePermissions();
return can("users:create") ? <Button>Crear</Button> : null;
```

**Elementos de navegación**: los ítems del sidebar que requieren permisos específicos (ej: sección Sistema RBAC) solo se muestran si el usuario tiene acceso.

---

## 4. Layout del Panel

### Estructura visual

```
┌─────────────────────────────────────────┐
│  [Sidebar colapsable]  │  [Contenido]   │
│                        │  ┌──────────┐  │
│  SACDIA Panel Admin    │  │  Header  │  │
│  ─────────────────     │  │ breadcr. │  │
│  Dashboard             │  └──────────┘  │
│  Usuarios              │  <page>        │
│  Catálogos ▶          │                │
│  Clubes                │                │
│  ─────────────────     │                │
│  OPERATIVO             │                │
│  Camporees             │                │
│  Clases                │                │
│  Honores               │                │
│  Actividades           │                │
│  Finanzas              │                │
│  Inventario            │                │
│  Certificaciones       │                │
│  Seguros               │                │
│  ─────────────────     │                │
│  COMUNICACIONES        │                │
│  Notificaciones        │                │
│  Folders               │                │
│  ─────────────────     │                │
│  SISTEMA               │                │
│  Roles y permisos ▶   │                │
│  ─────────────────     │                │
│  [Avatar] Admin        │                │
│  admin@sacdia.org      │                │
└─────────────────────────────────────────┘
```

### Sidebar

- Colapsable: se puede colapsar a solo iconos (estado persistido en cookie `sidebar_state`)
- El estado colapso/expandido se lee al cargar el layout y se usa como `defaultOpen`
- Grupos de navegación:
  - **Sin label**: Dashboard, Usuarios, Catálogos (submenú colapsable), Clubes
  - **Operativo**: Camporees, Clases, Honores, Actividades, Finanzas, Inventario, Certificaciones, Seguros
  - **Comunicaciones**: Notificaciones, Folders
  - **Sistema**: Roles y permisos (submenú colapsable) — solo visible para usuarios con `permissions:read` o `isSuperAdmin`
- Ítems con submenú: se expanden con Collapsible. Se abren automáticamente si la ruta activa es una de sus hijas.
- El ítem activo se resalta visualmente (basado en `usePathname()`).

### Submenú de Catálogos

Cuando se expande "Catálogos" en el sidebar, muestra:

- Resumen (índice de catálogos)
- Países, Uniones, Campos locales, Distritos, Iglesias
- Tipos de relación, Alergias, Enfermedades, Años eclesiásticos, Tipos de club, Ideales de club

### Submenú de Roles y permisos

- Matriz de seguridad (`/dashboard/rbac/matrix` — por implementar)
- Catálogo de roles (`/dashboard/rbac/roles`)
- Catálogo de permisos (`/dashboard/rbac/permissions`)

### Header

- Se muestra en la parte superior del contenido principal
- Incluye breadcrumbs automáticos basados en la ruta actual
- Botón para colapsar/expandir el sidebar (en móvil aparece como drawer)

### Footer del sidebar

- Muestra avatar del usuario autenticado + nombre + email
- Al hacer clic abre un dropdown con:
  - "Mi perfil" → enlace al detalle del usuario autenticado
  - Separador
  - "Cerrar sesión" → POST `/api/auth/logout` → redirige a `/login`

### Responsive

- En desktop: sidebar lateral fijo o colapsable
- En móvil: sidebar como drawer (Sheet), se activa con botón en el header

---

## 5. Autenticación

### Flujo de login

1. Usuario accede a `/login`
2. Ve un formulario con campos: Email, Contraseña
3. Al enviar el formulario (Server Action):
   - Llama `POST /api/v1/auth/login` al backend con `{ email, password }`
   - Si la respuesta es exitosa, se persiste la sesión/JWT según la implementación vigente del panel (cookies SSR + helpers actuales), sin introducir flujo alterno
   - Redirige a `/dashboard`
4. Si las credenciales son incorrectas, se muestra un mensaje de error en el formulario

Nota: no se introduce un flujo alterno de login directo desde frontend. El origen de verdad para sesión del panel es el contrato ya implementado en backend.

### Protección de rutas privadas

El layout del route group protegido `/(dashboard)` ejecuta `requireAdminUser()` en el servidor para `/dashboard`, `/dashboard/users`, `/dashboard/clubs`, etc.:

1. Lee la sesión de Supabase desde las cookies
2. Llama `GET /api/v1/auth/me` al backend para obtener el usuario con roles y permisos
3. Verifica que el usuario tenga al menos uno de los roles: `super_admin`, `admin`, `coordinator`
4. Si no tiene acceso, redirige a `/login`
5. Si tiene acceso, renderiza el layout con el usuario disponible en `AuthContext`

### Cierre de sesión

- Botón en el footer del sidebar
- Hace POST a `/api/auth/logout` (route handler de Next.js)
- El route handler invoca `POST /api/v1/auth/logout` para invalidación backend (blacklist/sesiones) y luego `supabase.auth.signOut()`
- Limpia cookies locales de sesión
- Redirige a `/login`

### Página `/login`

- No tiene el layout del dashboard (no tiene sidebar ni header)
- Tiene su propio layout centrado
- Si el usuario ya tiene sesión activa y es admin, redirige automáticamente a `/dashboard`

---

## 6. Dashboard

**Ruta**: `/dashboard`
**Permiso requerido**: `dashboard:view`

### Descripción

Página de bienvenida con resumen general del estado del sistema. Es un Server Component que hace múltiples llamadas al backend en paralelo.

### Sección 1 — Stats Cards (4 tarjetas)

| Tarjeta | Dato | Subtexto |
|---------|------|---------|
| Usuarios registrados | Total de usuarios | "X pendientes de aprobación" |
| Clubes activos | Clubes con `active=true` | "X clubes en total" |
| Camporees | Camporees activos | "Eventos activos" |
| Honores | Total de honores | "X clases registradas" |

Si un endpoint no está disponible (403, 404, 500), la tarjeta muestra `—` en lugar de bloquear toda la página.

### Sección 2 — Tabla de usuarios recientes + Distribución de roles

Dos columnas en desktop (stack en mobile):

**Columna izquierda (2/3)**: Tabla "Usuarios recientes"
- Muestra los últimos 5 usuarios registrados (ordenados por `created_at` desc)
- Columnas: Avatar + Nombre + Email, Rol (badge), Estado (dot + texto), Registro (fecha relativa)
- Enlace "Ver todos" en la cabecera → `/dashboard/users`

**Columna derecha (1/3)**: "Distribución de roles"
- Lista de hasta 5 roles con mayor cantidad de usuarios
- Cada rol muestra: nombre del rol, cantidad, barra de progreso proporcional al total de usuarios

### Sección 3 — Accesos rápidos

Grid de 4 tarjetas (2 columnas en mobile, 4 en desktop):
- Usuarios → `/dashboard/users`
- Clubes → `/dashboard/clubs`
- Clases → `/dashboard/classes`
- Honores → `/dashboard/honors`

Cada tarjeta tiene icono, título y subtexto "Gestionar". Al hacer hover tiene efecto visual.

---

## 7. Usuarios

**Ruta base**: `/dashboard/users`
**Permiso lectura**: `users:read`
**Permiso detalle**: `users:read_detail`

### Lista de usuarios (`/dashboard/users`)

#### Filtros disponibles (en URL)

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `search` | string | Búsqueda por nombre o email |
| `role` | string | Filtro por rol (`all` = sin filtro) |
| `active` | `true`/`false`/`all` | Filtro por estado activo |
| `unionId` | number | ID de la unión |
| `localFieldId` | number | ID del campo local |
| `page` | number | Página actual (default: 1) |
| `limit` | number | Registros por página (20/50/100, default: 20) |

#### Scope del backend

El backend puede restringir automáticamente el alcance de la consulta según el rol del usuario. La respuesta de la API incluye metadatos de scope:

```json
{
  "status": "success",
  "data": {
    "data": [...],
    "meta": {
      "page": 1,
      "limit": 20,
      "total": 150,
      "totalPages": 8,
      "hasNextPage": true,
      "hasPreviousPage": false,
      "scope": { "type": "UNION", "union_id": 3, "local_field_id": null }
    }
  }
}
```

Si `scope.type` es `UNION` o `LOCAL_FIELD`, los filtros correspondientes en la UI deben mostrarse como **bloqueados** (disabled) y con un hidden input para asegurar que el valor se envíe igual.

El botón "?" de "Alcance" abre un Dialog explicando el scope actual de la sesión al usuario.

#### Tabla (desktop)

Columnas: Usuario (avatar + nombre + email), Roles, Ubicación, Estado, Accesos, Post-registro, Fecha de alta

- **Roles**: badges por cada rol. Si no tiene, muestra "Sin rol"
- **Ubicación**: `País / Unión / Campo local` (texto truncado con tooltip al hover)
- **Estado**: badge activo/inactivo
- **Accesos**: dos badges `App` y `Panel` — coloreados si tiene acceso, outline si no
- **Post-registro**: badge "Completo" o "Pendiente" según `post_registration.complete`
- **Fecha de alta**: formato corto localizado (ej: "15 ene. 2026")
- El nombre del usuario es un enlace a `/dashboard/users/[userId]`

#### Cards (mobile)

Una card por usuario con: avatar, nombre, email, estado, ubicación, roles, accesos, fecha y botón "Ver detalle".

#### Paginación

Controles Anterior / Siguiente. Muestra "Página X de Y" y rango de registros.

#### Estado sin endpoint disponible

Si el endpoint retorna 403/401/404/500, se muestra un banner con el estado del endpoint (badge + mensaje descriptivo) y un EmptyState con ícono apropiado. Si es sesión expirada, se muestra un botón "Ir a login".

### Detalle de usuario (`/dashboard/users/[userId]`)

**Permiso**: `users:read_detail`

Muestra toda la información del usuario en un formato de lectura (no formulario de edición en esta versión).

Secciones:
- **Encabezado**: Avatar + nombre completo + email + estado (badge)
- **Datos personales**: nombre, apellido paterno, apellido materno, email, teléfono, fecha de nacimiento, género
- **Ubicación**: país, unión, campo local
- **Accesos**: acceso a app, acceso a panel, estado de aprobación
- **Roles globales**: lista de roles con badges
- **Permisos efectivos**: lista de permisos asignados (desde roles)
- **Post-registro**: estado de completitud del proceso
- **Scope**: tipo de scope (ALL / UNION / LOCAL_FIELD) con ID si aplica
- **Metadatos**: fecha de registro, última actualización
- **Roles de club**: tabla con instancia de club → rol asignado

Botón "Volver" → `/dashboard/users`

---

## 8. Catálogos

**Ruta base**: `/dashboard/catalogs`
**Permiso lectura**: `catalogs:read` (general) + permisos específicos por sección geográfica
**Permiso escritura**: `catalogs:create/update/delete`

### Página índice (`/dashboard/catalogs`)

Grid de tarjetas. Cada tarjeta representa una subcategoría de catálogo y enlaza a su sección. Las tarjetas se agrupan:

**Grupo Geografía**:
- Países, Uniones, Campos Locales, Distritos, Iglesias

**Grupo Datos de referencia**:
- Tipos de relación, Alergias, Enfermedades, Años eclesiásticos, Tipos de club, Ideales de club

### Patrón de gestión de catálogos

Los catálogos simples con CRUD admin disponible (alergias, enfermedades, tipos de relación, etc.) siguen el mismo patrón:

**Página de listado** (ej: `/dashboard/catalogs/allergies`):
- Tabla con columnas: Nombre, Estado, Fecha de creación, Acciones
- Botón "Nuevo [ítem]" en el header → abre Dialog de creación
- Acciones por fila: Editar (abre Dialog de edición), Eliminar (abre AlertDialog de confirmación)
- Filtro de búsqueda por nombre
- Estado vacío si no hay datos

**Dialog Crear/Editar**:
- Formulario inline en Dialog (Modal)
- Campos: Nombre (requerido), Descripción (opcional), Estado activo (switch)
- Botones: Cancelar, Guardar
- Al guardar exitoso: cierra el dialog + refresca la tabla

**AlertDialog Eliminar**:
- Mensaje: "¿Estás seguro de que quieres eliminar [nombre]? Esta acción no se puede deshacer."
- Botones: Cancelar, Eliminar (destructivo)
- Soft delete: el registro se desactiva, no se borra físicamente

Catálogos con solo lectura runtime (`club-types`, `club-ideals`) deben mostrar estado de solo lectura hasta que se publiquen endpoints admin.

### Catálogos simples

Estos catálogos tienen solo: nombre, descripción opcional, y estado activo/inactivo.

| Catálogo | Ruta | Endpoint backend | Estado |
|----------|------|-----------------|--------|
| Alergias | `/dashboard/catalogs/allergies` | `/api/v1/admin/allergies` | CRUD admin disponible |
| Enfermedades | `/dashboard/catalogs/diseases` | `/api/v1/admin/diseases` | CRUD admin disponible |
| Tipos de relación | `/dashboard/catalogs/relationship-types` | `/api/v1/admin/relationship-types` | CRUD admin disponible |
| Tipos de club | `/dashboard/catalogs/club-types` | `/api/v1/catalogs/club-types` | Lectura runtime; CRUD admin pendiente |
| Ideales de club | `/dashboard/catalogs/club-ideals` | `/api/v1/catalogs/club-ideals` | Lectura runtime; CRUD admin pendiente |

Servicios backend requeridos para paridad CRUD administrativa de `club-types` y `club-ideals`:

```http
GET    /api/v1/admin/club-types
POST   /api/v1/admin/club-types
PATCH  /api/v1/admin/club-types/:clubTypeId
DELETE /api/v1/admin/club-types/:clubTypeId

GET    /api/v1/admin/club-ideals
POST   /api/v1/admin/club-ideals
PATCH  /api/v1/admin/club-ideals/:clubIdealId
DELETE /api/v1/admin/club-ideals/:clubIdealId
```

### Años eclesiásticos (`/dashboard/catalogs/ecclesiastical-years`)

Similar al patrón base. Campos adicionales:
- Año (número, requerido)
- Fecha de inicio
- Fecha de fin
- Estado activo (solo puede haber uno activo a la vez)

Permiso: `ecclesiastical_years:read/create/update`

### Geografía — Jerarquía

La geografía tiene una jerarquía de dependencia:

```
País
  └── Unión
        └── Campo Local
              └── Distrito
                    └── Iglesia
```

Cada nivel tiene su CRUD pero al crear un nivel inferior se debe seleccionar el padre.

#### Países (`/dashboard/catalogs/geography/countries`)

- Permiso: `countries:read/create/update/delete`
- Campos: Nombre, Código ISO (2 letras), Estado activo

#### Uniones (`/dashboard/catalogs/geography/unions`)

- Permiso: `unions:read/create/update/delete`
- Campos: Nombre, País (select — carga países activos), Estado activo

#### Campos Locales (`/dashboard/catalogs/geography/local-fields`)

- Permiso: `local_fields:read/create/update/delete`
- Campos: Nombre, Unión (select — carga uniones activas), Estado activo

#### Distritos (`/dashboard/catalogs/geography/districts`)

- Permiso: `districts:read/create/update/delete`
- Campos: Nombre, Campo Local (select), Estado activo

#### Iglesias (`/dashboard/catalogs/geography/churches`)

- Permiso: `churches:read/create/update/delete`
- Campos: Nombre, Campo Local (select), Dirección (opcional), Estado activo

---

## 9. Clubes

**Ruta base**: `/dashboard/clubs`
**Permiso lectura**: `clubs:read`
**Permiso escritura**: `clubs:create/update/delete`

### Lista de clubes (`/dashboard/clubs`)

#### Filtros (en URL)

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `q` | string | Búsqueda por nombre o ID |
| `status` | `all`/`active`/`inactive` | Estado del club |
| `page` | number | Página actual |
| `perPage` | number | Ítems por página (12/24/48, default: 12) |

#### Tabla (desktop)

Columnas: Nombre, Campo local (ID), Distrito (ID o `—`), Iglesia (ID), Estado, Acciones

- **Acciones** (solo si tiene `clubs:update`): botón Editar (→ `/dashboard/clubs/[id]`), botón Eliminar (AlertDialog)
- Si no tiene permiso de escritura: badge "Solo lectura"

#### Cards (mobile)

Card con: nombre, estado, campo/distrito/iglesia, botones de acción.

#### Botón crear

Solo visible si tiene `clubs:create`. Enlaza a `/dashboard/clubs/new`.

### Crear club (`/dashboard/clubs/new`)

Formulario con campos:
- Nombre del club (requerido)
- Campo local (select — carga campos locales activos)
- Distrito (select — carga distritos del campo local seleccionado)
- Iglesia (select — carga iglesias del campo local seleccionado)
- Latitud y Longitud (opcionales, para coordenadas del club)
- Estado activo (switch)

Al guardar: redirige al detalle del club creado.

### Detalle/Edición de club (`/dashboard/clubs/[id]`)

Dos secciones en tabs:

**Tab 1: Datos del club**
- Formulario de edición con los mismos campos que crear
- Botón "Guardar cambios"

**Tab 2: Instancias**

Un club puede tener hasta 3 instancias:
- **Aventureros** (niños 4-9 años)
- **Conquistadores** (jóvenes 10-15 años)
- **Guías Mayores** (jóvenes y adultos 16+ años)

Por cada instancia se muestra:
- Estado (activa / inactiva / sin crear)
- Si existe: meta de almas, cuota de membresía, horarios de reunión
- Botón crear/editar instancia (requiere `club_instances:create/update`)

**Instancia detalle** (`/dashboard/clubs/[id]/instances/[instanceType]/[instanceId]`):
- Campos: meta de almas (número), cuota de membresía (decimal), horarios de reunión (configuración de días y horas en formato JSON), estado activo
- Sección de roles asignados: tabla con usuario → rol en la instancia
- Botón "Asignar rol" → Dialog con select de usuario y rol (requiere `club_roles:assign`)
- Acción revocar rol en cada fila (requiere `club_roles:revoke`)

**Roles disponibles por instancia**:

| Rol | Descripción |
|-----|-------------|
| `director` | Director del club |
| `subdirector` | Subdirector |
| `secretary` | Secretario |
| `treasurer` | Tesorero |
| `counselor` | Consejero |
| `instructor` | Instructor |
| `captain` | Capitán |
| `member` | Miembro |

**Permisos por acción en instancia**:

| Acción | Permisos requeridos |
|--------|-------------------|
| Ver instancia | `club_instances:read` |
| Crear instancia | `club_instances:create` |
| Editar instancia | `club_instances:update` |
| Desactivar instancia | `club_instances:delete` |
| Ver roles asignados | `club_roles:read` |
| Asignar rol | `club_roles:assign` |
| Revocar rol | `club_roles:revoke` |

---

## 10. Operativo — Camporees

**Ruta base**: `/dashboard/camporees`
**Estado**: Obligatorio en rediseño

### Modelo de acceso

- **Consulta**: usuarios con permisos globales (RBAC) y/o roles de club permitidos por backend.
- **Mutaciones**: `super_admin` por permisos globales o actores operativos autorizados por club roles.
- **Permisos globales recomendados**: `camporees:read`, `camporees:create`, `camporees:update`, `camporees:delete`.

### Contrato runtime actual

```http
GET    /api/v1/camporees
POST   /api/v1/camporees
GET    /api/v1/camporees/:camporeeId
PATCH  /api/v1/camporees/:camporeeId
DELETE /api/v1/camporees/:camporeeId
GET    /api/v1/camporees/:camporeeId/members
POST   /api/v1/camporees/:camporeeId/register
DELETE /api/v1/camporees/:camporeeId/members/:userId
```

### Lista de camporees (`/dashboard/camporees`)

Tabla: Nombre, Fecha inicio, Fecha fin, Lugar, Estado, Acciones.
Filtros: búsqueda, estado.

### Crear/Editar camporee

Campos: nombre, descripción, fechas, ubicación, estado activo.
Regla: fecha de fin > fecha de inicio.

---

## 11. Operativo — Clases Progresivas

**Ruta base**: `/dashboard/classes`
**Estado**: Obligatorio en rediseño

### Catálogo funcional (fuente: `product.md`)

- **Aventureros (4-9 años)**: Abejitas Laboriosas, Rayitos de Sol, Constructores, Manos Ayudadoras, Exploradores, Caminantes.
- **Conquistadores (10-15 años)**: Amigo, Compañero, Explorador, Orientador, Viajero, Guía.
- **Guías Mayores (16+)**: Guía Mayor, Guía Mayor Avanzado (histórico).

### Contrato runtime actual (lectura/progreso)

```http
GET   /api/v1/classes
GET   /api/v1/classes/:classId
GET   /api/v1/classes/:classId/modules
GET   /api/v1/users/:userId/classes
POST  /api/v1/users/:userId/classes/enroll
GET   /api/v1/users/:userId/classes/:classId/progress
PATCH /api/v1/users/:userId/classes/:classId/progress
```

### Servicios backend requeridos para administración global

Se deben crear servicios y endpoints administrativos para CRUD de catálogo de clases (soft delete), manteniendo lectura abierta según contratos actuales:

```http
GET    /api/v1/admin/classes
POST   /api/v1/admin/classes
GET    /api/v1/admin/classes/:classId
PATCH  /api/v1/admin/classes/:classId
DELETE /api/v1/admin/classes/:classId
```

Reglas:

- Lectura del catálogo: disponible para globales y operativos según contrato vigente.
- Escritura (`POST/PATCH/DELETE`): solo `super_admin`.
- `DELETE` siempre lógico (`active=false`).

---

## 12. Operativo — Honores

**Ruta base**: `/dashboard/honors`
**Estado**: Obligatorio en rediseño

### Contrato runtime actual (lectura/progreso)

```http
GET    /api/v1/honors
GET    /api/v1/honors/:honorId
GET    /api/v1/honors/categories
GET    /api/v1/users/:userId/honors
POST   /api/v1/users/:userId/honors/:honorId
PATCH  /api/v1/users/:userId/honors/:honorId
DELETE /api/v1/users/:userId/honors/:honorId
GET    /api/v1/users/:userId/honors/stats
```

### Servicios backend requeridos para administración global

Se deben crear servicios y endpoints administrativos para CRUD de honores y categorías, con soft delete:

```http
GET    /api/v1/admin/honors
POST   /api/v1/admin/honors
GET    /api/v1/admin/honors/:honorId
PATCH  /api/v1/admin/honors/:honorId
DELETE /api/v1/admin/honors/:honorId

GET    /api/v1/admin/honor-categories
POST   /api/v1/admin/honor-categories
PATCH  /api/v1/admin/honor-categories/:categoryId
DELETE /api/v1/admin/honor-categories/:categoryId
```

Reglas:

- Consulta de honores/progreso: usuarios con roles globales o de club autorizados por backend.
- Escritura administrativa: solo `super_admin`.
- `DELETE` lógico.

### Vista de progreso por usuario

Desde `/dashboard/users/[userId]` se muestra progreso de honores con estatus, porcentaje y fechas.

---

## 13. Finanzas (obligatorio en rediseño)

**Ruta base**: `/dashboard/finances`
**Permisos**: `finances:read/create/update/delete/export`
**Estado**: Debe incluirse en la primera entrega del rediseño

### Contrato runtime

```http
GET    /api/v1/finances/categories
GET    /api/v1/clubs/:clubId/finances
GET    /api/v1/clubs/:clubId/finances/summary
POST   /api/v1/clubs/:clubId/finances
GET    /api/v1/finances/:financeId
PATCH  /api/v1/finances/:financeId
DELETE /api/v1/finances/:financeId
```

### Reglas de acceso

- Operación por club roles (director/subdirector/tesorero) se mantiene.
- Para panel admin, se requiere mapeo de permisos globales para consulta y orquestación de flujos sin bypass inseguro.

---

## 14. Actividades (obligatorio en rediseño)

**Ruta base**: `/dashboard/activities`
**Permisos**: `activities:read/create/update/delete`, `attendance:read/manage`
**Estado**: Debe incluirse en la primera entrega del rediseño

### Contrato runtime

```http
GET    /api/v1/clubs/:clubId/activities
POST   /api/v1/clubs/:clubId/activities
GET    /api/v1/activities/:activityId
PATCH  /api/v1/activities/:activityId
DELETE /api/v1/activities/:activityId
GET    /api/v1/activities/:activityId/attendance
POST   /api/v1/activities/:activityId/attendance
```

### Reglas de acceso

- Consulta: permitida por alcance operativo de club y/o permisos globales efectivos.
- Mutaciones: por club roles autorizados o actores globales autorizados por política RBAC.
- Si el guard actual solo evalúa rol de club, debe ampliarse a guard híbrido o endpoint admin dedicado.

---

## 15. Inventario (obligatorio en rediseño)

**Ruta base**: `/dashboard/inventory`
**Permisos**: `inventory:read/create/update/delete`
**Estado**: Debe incluirse en la primera entrega del rediseño

### Contrato runtime canónico

```http
GET    /api/v1/inventory/catalogs/inventory-categories
GET    /api/v1/inventory/clubs/:clubId/inventory
POST   /api/v1/inventory/clubs/:clubId/inventory
GET    /api/v1/inventory/inventory/:id
PATCH  /api/v1/inventory/inventory/:id
DELETE /api/v1/inventory/inventory/:id
```

### Reglas de acceso

- Consulta: permitida por alcance operativo de club y/o permisos globales efectivos.
- Mutaciones: por club roles autorizados o actores globales autorizados por política RBAC.
- Si el guard actual solo evalúa rol de club, debe ampliarse a guard híbrido o endpoint admin dedicado.

---

## 16. Seguros (planificado)

**Ruta base**: `/dashboard/insurance`
**Permisos**: por definir (`insurance:read/manage`)
**Estado**: Planeado; requiere contrato backend dedicado

### Funcionalidades esperadas

- Vigencias por miembro.
- Alertas de vencimiento.
- Validación de cobertura para actividades/camporees.

---

## 17. Certificaciones Guías Mayores (obligatorio en rediseño)

**Ruta base**: `/dashboard/certifications`
**Estado**: Obligatorio en rediseño

### Contrato runtime actual

```http
GET    /api/v1/certifications/certifications
GET    /api/v1/certifications/certifications/:id
GET    /api/v1/certifications/users/:userId/certifications
POST   /api/v1/certifications/users/:userId/certifications/enroll
GET    /api/v1/certifications/users/:userId/certifications/:certificationId/progress
PATCH  /api/v1/certifications/users/:userId/certifications/:certificationId/progress
DELETE /api/v1/certifications/users/:userId/certifications/:certificationId
```

### Objetivo UI admin

- Consulta de estado y progreso por usuario.
- Filtros por club/instancia/nivel.
- Flujos de validación administrativa conforme permisos.

### Reglas de acceso

- Consulta de certificaciones/progreso: globales y operativos autorizados por backend.
- Mutaciones administrativas de validación: restringidas por permisos globales definidos para el módulo.
- Sin bypass: si el endpoint actual no contempla permisos globales, se requiere ajuste de guard o endpoint admin.

---

## 18. Comunicaciones — Notificaciones

**Ruta base**: `/dashboard/notifications`
**Estado**: Obligatorio en rediseño (paridad funcional)

### Contrato runtime

```http
POST /api/v1/notifications/send
POST /api/v1/notifications/broadcast
POST /api/v1/notifications/club/:instanceType/:instanceId

GET  /api/v1/fcm-tokens
POST /api/v1/fcm-tokens
DELETE /api/v1/fcm-tokens/:token
GET  /api/v1/fcm-tokens/user/:userId
```

### Reglas

- `broadcast` y `club` restringidos a `admin|super_admin`.
- Manejo explícito de `401/403/429`.

---

## 19. Folders — Carpetas de Evidencias

**Ruta base**: `/dashboard/folders`
**Estado**: Obligatorio en rediseño (paridad funcional)

### Contrato runtime

```http
GET    /api/v1/folders/folders
GET    /api/v1/folders/folders/:id
GET    /api/v1/folders/users/:userId/folders
POST   /api/v1/folders/users/:userId/folders/:folderId/enroll
GET    /api/v1/folders/users/:userId/folders/:folderId/progress
PATCH  /api/v1/folders/users/:userId/folders/:folderId/modules/:moduleId/sections/:sectionId
DELETE /api/v1/folders/users/:userId/folders/:folderId
```

---

## 20. Sistema RBAC — Pantallas

**Ruta base**: `/dashboard/rbac`
**Permiso lectura**: `permissions:read`, `roles:read`
**Permiso escritura**: solo `super_admin` (`permissions:assign` + guards backend)

### Índice RBAC (`/dashboard/rbac`)

- Catálogo de permisos (`/dashboard/rbac/permissions`)
- Asignación de permisos a roles (`/dashboard/rbac/roles`)
- Matriz de seguridad (`/dashboard/rbac/matrix`) — pendiente

### Catálogo de permisos (`/dashboard/rbac/permissions`)

- Admin: lectura.
- Super admin: crear/editar/desactivar.
- Validación de código `resource:action`.

### Asignación de roles (`/dashboard/rbac/roles`)

- Admin: lectura.
- Super admin: escritura/sync completo.

Contrato runtime:

```http
GET    /api/v1/admin/rbac/permissions
GET    /api/v1/admin/rbac/permissions/:id
POST   /api/v1/admin/rbac/permissions
PATCH  /api/v1/admin/rbac/permissions/:id
DELETE /api/v1/admin/rbac/permissions/:id

GET    /api/v1/admin/rbac/roles
GET    /api/v1/admin/rbac/roles/:id
PUT    /api/v1/admin/rbac/roles/:id/permissions
DELETE /api/v1/admin/rbac/roles/:id/permissions/:permissionId
```

---

## 21. Criterios de Aceptación, Pruebas y DoD

### Matriz mínima de pruebas por módulo

- `Auth + sesión`: unit + integration + e2e (login válido, inválido, sesión expirada).
- `Scope users`: e2e obligatorio para `super_admin`, `admin(UNION)`, `admin(LOCAL_FIELD)`, `coordinator`, y casos `403`.
- `Catálogos`: unit de validación de formularios + integration de CRUD + e2e smoke.
- `Operativo (clubs/camporees/activities/finances/inventory)`: integration de contratos + e2e de lectura y mutaciones principales.
- `RBAC`: integration para sync de permisos + e2e de restricciones de escritura por rol.
- `Notifications/Folders`: e2e smoke de rutas y manejo de errores.

### Criterios de aceptación por módulo (salida)

| Módulo | Criterios obligatorios de salida |
|--------|----------------------------------|
| Auth | Login/logout funcional con backend, guard SSR en `/(dashboard)`, redirección por sesión inválida. |
| Users | Lista + detalle con shape real, scope aplicado por backend y UI bloqueando filtros fuera de alcance. |
| Catálogos | CRUD operativo para catálogos admin live; `club-types`/`club-ideals` en solo lectura hasta publicar servicios admin. |
| Clases/Honores | Lectura/progreso según runtime; CRUD de catálogo solo `super_admin`; `DELETE` lógico. |
| Clubes | CRUD + instancias + asignación/revocación de roles de club con permisos correctos. |
| Camporees/Activities/Finances/Inventory | Lectura y mutaciones bajo autorización híbrida (global + club) sin `403` espurios. |
| Certifications | Consulta y validación administrativa conforme permisos y alcance. |
| Notifications/Folders | Rutas activas con manejo de `401/403/429` y estados degradados. |
| RBAC | Permisos y roles sincronizables; escritura restringida a `super_admin`. |

### Cobertura y calidad

- Cobertura de lógica crítica: mínimo 80%.
- `tsc --noEmit` sin errores.
- Lint sin errores.
- Build de producción exitoso.
- Smoke E2E pasando en rutas críticas.

### Definition of Done (DoD)

Una historia/módulo se considera terminado cuando:

1. Cumple contrato runtime y permisos definidos.
2. Incluye casos de error (`401/403/404/429/5xx`) y estados de degradación.
3. Tiene pruebas automatizadas en el nivel correspondiente.
4. Documentación actualizada en `docs/` en el mismo trabajo.
5. No introduce rutas inconsistentes ni bypass de seguridad.

---

## 22. Glosario del Dominio

| Término | Definición |
|---------|-----------|
| **Campo local** | Unidad administrativa local de la iglesia adventista. Agrupa iglesias y clubes de una ciudad o región. Equivale a una "conferencia local". |
| **Unión** | Nivel jerárquico que agrupa varios campos locales. Equivale a una región o país. |
| **Distrito** | Subdivisión de un campo local. Agrupa varias iglesias. |
| **Iglesia** | Congregación local perteneciente a un distrito y campo local. |
| **Club** | Organización juvenil asociada a una iglesia. Puede tener hasta 3 instancias activas simultáneamente. |
| **Instancia de club** | Una de las tres modalidades del club: Aventureros, Conquistadores o Guías Mayores. Cada instancia es independiente y puede tener su propio director, tesorero, etc. |
| **Conquistadores** | Programa para jóvenes de 10 a 15 años. Las clases progresivas son: Amigo, Compañero, Explorador, Orientador, Viajero, Guía. |
| **Aventureros** | Programa para niños de 4 a 9 años. Las clases son: Abejitas Laboriosas, Rayitos de Sol, Constructores, Manos Ayudadoras, Exploradores, Caminantes. |
| **Guías Mayores** | Programa para jóvenes de 16 años en adelante con sistema de certificaciones. |
| **Honor / Especialidad** | Distintivo obtenido al completar los requisitos de una especialidad (ej: Astronomía, Primeros auxilios). El usuario puede tener múltiples honores en progreso o completados. |
| **Clase progresiva** | Nivel de avance dentro del programa. Cada clase tiene requisitos que el miembro debe cumplir antes de pasar al siguiente nivel. |
| **Camporee** | Evento de campamento grupal que reúne a varios clubes. Tiene fecha, lugar y programa. |
| **Año eclesiástico** | Período anual de actividades (generalmente enero a diciembre). Define el período de inscripciones, cuotas, seguros y actividades. |
| **Post-registro** | Proceso que el usuario completa después de registrarse en la app móvil: agrega datos personales, selecciona su club, etc. Hasta que no lo completa, no está plenamente activo. |
| **Scope** | Ámbito geográfico de la sesión administrativa. Un `coordinator` con scope `LOCAL_FIELD` solo puede ver datos de su campo local. |
| **RBAC** | Role-Based Access Control. Sistema de control de acceso donde los permisos se asignan a roles y los roles a usuarios. |
| **Permiso** | Unidad atómica de acceso en formato `resource:action` (ej: `clubs:create`). |
| **Rol global** | Rol que aplica a todo el sistema: `super_admin`, `admin`, `coordinator`. Distinto del rol de club (director, tesorero, etc.) que aplica solo dentro de una instancia. |
| **Investidura** | Certificación formal que recibe un miembro al completar los requisitos de un nivel en Guías Mayores. |

---

*Fin del documento de especificación.*

**Repositorio**: `sacdia-admin` en GitHub
**Backend**: `sacdia-backend` — API REST en NestJS, escucha en `http://localhost:3000` por defecto
**Autenticación**: Supabase Auth — configurar `NEXT_PUBLIC_SUPABASE_URL` y `NEXT_PUBLIC_SUPABASE_ANON_KEY` en `.env.local`
