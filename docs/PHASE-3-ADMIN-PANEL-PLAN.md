# Plan de Desarrollo - Fase 3: Panel Administrativo Web

**Fecha**: 8 de febrero de 2026
**Duración estimada**: 4-5 semanas (en paralelo con Fase 2)
**Estado**: PLANIFICACIÓN
**Prerequisito**: Fase 1 (Backend API) COMPLETADA - 105+ endpoints, 17 módulos

---

## Justificación: ¿Por qué iniciar Fase 3 junto con Fase 2?

La app móvil (Fase 2) depende de catálogos poblados en la base de datos para funcionar:
- **Post-Registro Paso 2**: Necesita catálogos de `relationship_types`, `allergies`, `diseases`
- **Post-Registro Paso 3**: Necesita catálogos de `countries`, `unions`, `local_fields`, `districts`, `churches`, `clubs`, `club_instances`, `classes`, `ecclesiastical_years`
- **Dashboard/Clases/Honores**: Necesita catálogos de `honor_categories`, `honors`, `classes`, `class_modules`, `class_sections`

**Sin el panel admin, no hay forma de gestionar estos catálogos**, por lo que la app móvil no tendría datos con los cuales funcionar.

---

## Estado Actual del Proyecto Admin

El proyecto `sacdia-admin/` ya tiene la base inicializada:

- ✅ Next.js 16 (App Router) configurado
- ✅ shadcn/ui + Tailwind CSS v4 configurado
- ✅ React Hook Form + Zod instalados
- ✅ Supabase Auth (SSR) configurado (client + server)
- ✅ Lucide React para iconos
- ❌ Sin páginas funcionales (solo boilerplate)
- ❌ Sin componentes shadcn/ui instalados
- ❌ Sin Axios ni TanStack Query
- ❌ Sin layout de dashboard ni sidebar
- ❌ Sin sistema de autenticación funcional

### Dependencias Faltantes

```bash
pnpm add axios @tanstack/react-query
pnpm add @tanstack/react-table   # Tablas de datos
pnpm add recharts                # Gráficos para dashboard
pnpm add sonner                  # Toast notifications
pnpm add date-fns                # Manejo de fechas
```

### Componentes shadcn/ui Necesarios

```bash
npx shadcn@latest add button input label select textarea
npx shadcn@latest add table card badge separator
npx shadcn@latest add dialog sheet alert-dialog
npx shadcn@latest add form checkbox switch
npx shadcn@latest add dropdown-menu sidebar breadcrumb
npx shadcn@latest add tabs tooltip avatar
npx shadcn@latest add skeleton command pagination
npx shadcn@latest add sonner
```

---

## Hallazgo Crítico: Backend necesita endpoints CRUD Admin

Los endpoints de catálogos actuales son **SOLO LECTURA** (GET). Para que el panel admin pueda gestionar catálogos, se necesitan **nuevos endpoints** en el backend.

### Endpoints Backend Faltantes (por módulo)

#### Jerarquía Geográfica (NUEVO: ~20 endpoints)

```
# Países
POST   /api/v1/admin/countries
PATCH  /api/v1/admin/countries/:id
DELETE /api/v1/admin/countries/:id

# Uniones
POST   /api/v1/admin/unions
PATCH  /api/v1/admin/unions/:id
DELETE /api/v1/admin/unions/:id

# Campos Locales
POST   /api/v1/admin/local-fields
PATCH  /api/v1/admin/local-fields/:id
DELETE /api/v1/admin/local-fields/:id

# Distritos
POST   /api/v1/admin/districts
PATCH  /api/v1/admin/districts/:id
DELETE /api/v1/admin/districts/:id

# Iglesias
POST   /api/v1/admin/churches
PATCH  /api/v1/admin/churches/:id
DELETE /api/v1/admin/churches/:id
```

#### Catálogos de Datos (NUEVO: ~15 endpoints)

```
# Tipos de Relación
GET    /api/v1/admin/relationship-types
POST   /api/v1/admin/relationship-types
PATCH  /api/v1/admin/relationship-types/:id
DELETE /api/v1/admin/relationship-types/:id

# Alergias
GET    /api/v1/admin/allergies
POST   /api/v1/admin/allergies
PATCH  /api/v1/admin/allergies/:id
DELETE /api/v1/admin/allergies/:id

# Enfermedades
GET    /api/v1/admin/diseases
POST   /api/v1/admin/diseases
PATCH  /api/v1/admin/diseases/:id
DELETE /api/v1/admin/diseases/:id

# Años Eclesiásticos
POST   /api/v1/admin/ecclesiastical-years
PATCH  /api/v1/admin/ecclesiastical-years/:id
DELETE /api/v1/admin/ecclesiastical-years/:id
```

#### Clases y Honores Admin (NUEVO: ~12 endpoints)

```
# Clases (CRUD)
POST   /api/v1/admin/classes
PATCH  /api/v1/admin/classes/:id
DELETE /api/v1/admin/classes/:id

# Módulos de Clase
POST   /api/v1/admin/classes/:classId/modules
PATCH  /api/v1/admin/class-modules/:id
DELETE /api/v1/admin/class-modules/:id

# Secciones de Módulo
POST   /api/v1/admin/class-modules/:moduleId/sections
PATCH  /api/v1/admin/class-sections/:id
DELETE /api/v1/admin/class-sections/:id

# Categorías de Honores
POST   /api/v1/admin/honor-categories
PATCH  /api/v1/admin/honor-categories/:id
DELETE /api/v1/admin/honor-categories/:id

# Honores (CRUD)
POST   /api/v1/admin/honors
PATCH  /api/v1/admin/honors/:id
DELETE /api/v1/admin/honors/:id
```

**Nota**: Todos los endpoints admin requieren rol `super_admin` o `admin`. Se recomienda un guard `@Roles('super_admin', 'admin')` y prefijo `/admin/`.

---

## MICROFASE 3.0: Setup del Proyecto + Autenticación (3-4 días)

### Objetivo
Configurar el proyecto admin con todas las dependencias, layout base, sistema de autenticación y protección de rutas.

### 3.0.1 Instalar Dependencias y Componentes

**Dependencias npm**:
```bash
pnpm add axios @tanstack/react-query @tanstack/react-table
pnpm add recharts sonner date-fns
```

**Componentes shadcn/ui**: Instalar los listados en la sección anterior.

### 3.0.2 Configurar Axios + TanStack Query

**Archivos a crear**:
```
src/lib/
  api/
    client.ts                    # Axios instance con interceptors
    query-client.ts              # TanStack Query client
  providers/
    query-provider.tsx           # Provider wrapper
```

**Funcionalidad**:
- Axios instance con baseURL de `NEXT_PUBLIC_API_URL`
- Interceptor de auth que inyecta JWT en headers
- Interceptor de error que maneja 401 → redirect a login
- TanStack Query con configuración global (staleTime, retry, etc.)

### 3.0.3 Sistema de Autenticación Admin

**Archivos a crear**:
```
src/app/(auth)/
  login/
    page.tsx                     # Página de login
  layout.tsx                     # Layout de auth (centrado)

src/lib/
  auth/
    auth-context.tsx             # Context de autenticación
    auth-guard.tsx               # HOC/Component de protección
    actions.ts                   # Server actions para auth
```

**Flujo de Auth**:
1. Admin ingresa email + password
2. Se autentica con Supabase Auth
3. Se valida que el usuario tenga rol `super_admin`, `admin` o `coordinator` vía `/auth/me`
4. Si no tiene rol admin → mostrar error "Acceso no autorizado"
5. Si tiene rol → guardar sesión, redirigir a dashboard
6. Middleware de Next.js protege todas las rutas `/dashboard/*`

**Archivo middleware**:
```
src/middleware.ts                 # Protección de rutas con Supabase SSR
```

### 3.0.4 Layout Principal con Sidebar

**Archivos a crear**:
```
src/app/(dashboard)/
  layout.tsx                     # Layout con sidebar + header
  page.tsx                       # Dashboard principal (placeholder)

src/components/
  layout/
    app-sidebar.tsx              # Sidebar con navegación
    header.tsx                   # Header con user menu
    breadcrumbs.tsx              # Breadcrumbs dinámicos
    user-nav.tsx                 # Menú de usuario (avatar, logout)
```

**Estructura del Sidebar**:
```
📊 Dashboard
📂 Catálogos
  ├── 🌍 Jerarquía Geográfica
  │   ├── Países
  │   ├── Uniones
  │   ├── Campos Locales
  │   ├── Distritos
  │   └── Iglesias
  ├── 📋 Datos de Referencia
  │   ├── Tipos de Relación
  │   ├── Alergias
  │   ├── Enfermedades
  │   └── Tipos de Club
  ├── 📅 Años Eclesiásticos
  └── 🎯 Ideales de Club
🏕️ Clubes
  ├── Listado de Clubes
  └── Instancias de Club
👥 Usuarios
  ├── Listado de Usuarios
  ├── Aprobación de Miembros
  └── Asignación de Roles
📚 Clases
  ├── Catálogo de Clases
  └── Módulos y Secciones
🏅 Honores
  ├── Categorías
  └── Catálogo de Honores
📊 Finanzas
📦 Inventario
🏕️ Camporees
📜 Certificaciones
```

### 3.0.5 Componentes Reutilizables Base

**Archivos a crear**:
```
src/components/
  shared/
    data-table.tsx               # Tabla genérica con TanStack Table
    data-table-pagination.tsx    # Paginación reutilizable
    data-table-toolbar.tsx       # Barra de herramientas (filtros, búsqueda)
    confirm-dialog.tsx           # Diálogo de confirmación genérico
    page-header.tsx              # Header de página con título y acciones
    loading-skeleton.tsx         # Skeleton de carga
    empty-state.tsx              # Estado vacío
    status-badge.tsx             # Badge de estado (activo/inactivo)
```

### Entregable Microfase 3.0
- Proyecto configurado con todas las dependencias
- Login funcional para admins (con validación de rol)
- Layout con sidebar y header
- Protección de rutas
- Componentes reutilizables base (DataTable, dialogs, etc.)
- Dashboard placeholder

---

## MICROFASE 3.1: Jerarquía Geográfica (3-4 días) 🔴 CRÍTICO para Fase 2

### Objetivo
CRUD completo para la jerarquía País → Unión → Campo Local → Distrito → Iglesia. **Esto es lo que más bloquea el post-registro paso 3 de la app móvil.**

### 3.1.0 Backend: Endpoints Admin de Geografía

**Archivo a crear/modificar en sacdia-backend**:
```
src/catalogs/
  admin-catalogs.controller.ts   # NUEVO: Controller admin
  admin-catalogs.service.ts      # NUEVO: Service admin
  dto/
    create-country.dto.ts
    update-country.dto.ts
    create-union.dto.ts
    update-union.dto.ts
    create-local-field.dto.ts
    update-local-field.dto.ts
    create-district.dto.ts
    update-district.dto.ts
    create-church.dto.ts
    update-church.dto.ts
```

**Endpoints** (protegidos con `@Roles('super_admin', 'admin')`):
- CRUD para cada entidad geográfica (countries, unions, local_fields, districts, churches)
- Borrado lógico (soft delete: `active = false`)
- Validación de integridad referencial (no borrar un país con uniones activas)

### 3.1.1 Admin Panel: Páginas de Geografía

**Archivos a crear**:
```
src/app/(dashboard)/catalogs/
  geography/
    page.tsx                     # Vista general con tabs por nivel
    countries/
      page.tsx                   # Lista de países
      [id]/
        page.tsx                 # Editar país
      new/
        page.tsx                 # Crear país
    unions/
      page.tsx                   # Lista de uniones (filtro por país)
      [id]/page.tsx
      new/page.tsx
    local-fields/
      page.tsx                   # Lista de campos locales (filtro por unión)
      [id]/page.tsx
      new/page.tsx
    districts/
      page.tsx
      [id]/page.tsx
      new/page.tsx
    churches/
      page.tsx
      [id]/page.tsx
      new/page.tsx

src/lib/api/
  geography.ts                   # Funciones API para geografía

src/components/catalogs/
  geography/
    country-form.tsx             # Formulario de país
    union-form.tsx               # Formulario de unión (con selector de país)
    local-field-form.tsx
    district-form.tsx
    church-form.tsx
    geography-breadcrumb.tsx     # Breadcrumb jerárquico
```

**Funcionalidad por pantalla**:
- **Lista**: DataTable con columnas (nombre, abreviación, activo, acciones)
- **Filtro jerárquico**: Al estar en "Uniones", poder filtrar por país
- **Crear/Editar**: Formulario con validación Zod
- **Desactivar**: Diálogo de confirmación + soft delete
- **Breadcrumb jerárquico**: País > Unión > Campo Local > ...

### Entregable Microfase 3.1
- Backend: 15 endpoints CRUD admin para geografía
- Admin: CRUD completo para los 5 niveles geográficos
- Navegación jerárquica entre niveles
- Validación de integridad referencial

---

## MICROFASE 3.2: Catálogos de Datos de Referencia (2-3 días) 🔴 CRÍTICO para Fase 2

### Objetivo
CRUD para catálogos necesarios en el post-registro: tipos de relación, alergias, enfermedades.

### 3.2.0 Backend: Endpoints Admin de Catálogos

**Endpoints nuevos**:
- CRUD `relationship_types` (padre, madre, tutor, etc.)
- CRUD `allergies` (catálogo de alergias)
- CRUD `diseases` (catálogo de enfermedades)
- CRUD `ecclesiastical_years` (años eclesiásticos)
- CRUD `club_types` (si se necesita gestionar)
- CRUD `club_ideals` (ideales de club por tipo)

### 3.2.1 Admin Panel: Páginas de Catálogos

**Archivos a crear**:
```
src/app/(dashboard)/catalogs/
  relationship-types/
    page.tsx                     # CRUD tipos de relación
  allergies/
    page.tsx                     # CRUD alergias
  diseases/
    page.tsx                     # CRUD enfermedades
  ecclesiastical-years/
    page.tsx                     # CRUD años eclesiásticos
  club-types/
    page.tsx                     # Vista de tipos de club
  club-ideals/
    page.tsx                     # CRUD ideales por tipo de club

src/lib/api/
  catalogs.ts                    # Funciones API para catálogos

src/components/catalogs/
  catalog-form.tsx               # Formulario genérico de catálogo (nombre, descripción, activo)
  ecclesiastical-year-form.tsx   # Formulario específico (con fechas inicio/fin)
  club-ideal-form.tsx            # Formulario con selector de tipo de club
```

**Patrón genérico para catálogos simples**:
Muchos catálogos tienen la misma estructura (id, name, active). Crear un componente genérico `CatalogCrudPage` que reciba:
- Título
- Endpoint base
- Columnas de la tabla
- Campos del formulario
- Schema Zod de validación

### Entregable Microfase 3.2
- Backend: ~18 endpoints CRUD admin para catálogos de referencia
- Admin: CRUD para tipos de relación, alergias, enfermedades
- Admin: Gestión de años eclesiásticos (con fechas)
- Admin: Gestión de ideales de club
- Componente genérico reutilizable para catálogos simples

---

## MICROFASE 3.3: Gestión de Clubes (3-4 días) 🟡 IMPORTANTE para Fase 2

### Objetivo
Gestión completa de clubes e instancias. **Los endpoints de clubs ya existen en el backend**, solo se necesita la interfaz admin.

### 3.3.1 Admin Panel: Clubes

**Archivos a crear**:
```
src/app/(dashboard)/clubs/
  page.tsx                       # Lista de clubes con filtros
  [clubId]/
    page.tsx                     # Detalle de club
    instances/
      page.tsx                   # Instancias del club
      new/page.tsx               # Crear instancia
    members/
      page.tsx                   # Miembros del club
  new/
    page.tsx                     # Crear club

src/lib/api/
  clubs.ts                       # Funciones API para clubes

src/components/clubs/
  club-form.tsx                  # Formulario de club
  club-instance-form.tsx         # Formulario de instancia
  club-detail-card.tsx           # Tarjeta de detalle
  instance-type-badge.tsx        # Badge por tipo (Aventureros, Conquistadores, GM)
  member-list.tsx                # Lista de miembros con roles
```

**Funcionalidades**:
- **Lista de Clubes**: Filtrar por campo local, distrito, iglesia, estado
- **Detalle de Club**: Info general + instancias + estadísticas
- **Instancias**: Ver/crear instancias por tipo (Aventureros, Conquistadores, GM)
- **Miembros**: Lista de miembros por instancia con rol y estado

### 3.3.2 Admin Panel: Aprobación de Miembros

**Archivos a crear**:
```
src/app/(dashboard)/clubs/
  [clubId]/
    pending-members/
      page.tsx                   # Miembros pendientes de aprobación

src/components/clubs/
  pending-member-card.tsx        # Tarjeta de miembro pendiente
  approve-reject-dialog.tsx      # Diálogo de aprobación/rechazo
```

**Funcionalidades**:
- Lista de miembros con status `pending`
- Botones de aprobar/rechazar
- Vista de info del miembro antes de aprobar
- Bulk actions (aprobar/rechazar varios)

### 3.3.3 Admin Panel: Asignación de Roles de Club

**Archivos a crear**:
```
src/app/(dashboard)/clubs/
  [clubId]/
    role-assignments/
      page.tsx                   # Asignaciones de roles
      new/page.tsx               # Nueva asignación

src/components/clubs/
  role-assignment-form.tsx       # Formulario de asignación
  role-assignment-table.tsx      # Tabla de asignaciones
```

**Funcionalidades**:
- Ver asignaciones actuales por instancia y año
- Asignar rol a un usuario (con validación de GM investido para director/subdirector de GM)
- Modificar/revocar asignaciones

### Entregable Microfase 3.3
- CRUD completo de clubes (usando endpoints existentes)
- Gestión de instancias de club
- Pantalla de aprobación de miembros pendientes
- Asignación de roles de club
- Filtros por campo local, tipo, estado

---

## MICROFASE 3.4: Clases y Honores (3-4 días) 🟡 IMPORTANTE

### Objetivo
Gestión del catálogo de clases progresivas (con módulos y secciones) y del catálogo de honores.

### 3.4.0 Backend: Endpoints Admin para Clases y Honores

**Endpoints nuevos**:
- CRUD `classes` (crear/editar/desactivar clases)
- CRUD `class_modules` (módulos de cada clase)
- CRUD `class_sections` (secciones de cada módulo)
- CRUD `honor_categories` (categorías de honores)
- CRUD `honors` (honores individuales)

### 3.4.1 Admin Panel: Clases

**Archivos a crear**:
```
src/app/(dashboard)/classes/
  page.tsx                       # Catálogo de clases (tabs por tipo de club)
  [classId]/
    page.tsx                     # Detalle de clase
    modules/
      page.tsx                   # Módulos de la clase
      [moduleId]/
        sections/
          page.tsx               # Secciones del módulo
  new/
    page.tsx                     # Crear clase

src/lib/api/
  classes.ts

src/components/classes/
  class-form.tsx
  module-form.tsx
  section-form.tsx
  class-structure-tree.tsx       # Árbol visual: Clase > Módulos > Secciones
```

**Funcionalidades**:
- Lista de clases agrupadas por tipo de club
- Crear/editar clases con nombre, orden, tipo de club
- Gestión jerárquica: Clase → Módulos → Secciones
- Vista de árbol para ver toda la estructura
- Drag & drop para reordenar (opcional)

### 3.4.2 Admin Panel: Honores

**Archivos a crear**:
```
src/app/(dashboard)/honors/
  categories/
    page.tsx                     # Categorías de honores
  page.tsx                       # Catálogo de honores
  [honorId]/
    page.tsx                     # Detalle/editar honor
  new/
    page.tsx                     # Crear honor

src/lib/api/
  honors.ts

src/components/honors/
  honor-form.tsx                 # Con selector de categoría, tipo de club, dificultad
  honor-category-form.tsx
  honor-card.tsx
```

### Entregable Microfase 3.4
- Backend: ~12 endpoints CRUD admin para clases y honores
- Admin: CRUD de clases con estructura jerárquica (módulos/secciones)
- Admin: CRUD de categorías de honores
- Admin: CRUD de honores con filtros
- Vista de árbol para estructura de clases

---

## MICROFASE 3.5: Gestión de Usuarios (2-3 días)

### Objetivo
Panel de gestión de usuarios del sistema con información detallada, roles y estados.

### 3.5.1 Admin Panel: Usuarios

**Archivos a crear**:
```
src/app/(dashboard)/users/
  page.tsx                       # Lista de usuarios con filtros
  [userId]/
    page.tsx                     # Detalle del usuario

src/lib/api/
  users.ts

src/components/users/
  user-detail-card.tsx           # Info personal
  user-roles-card.tsx            # Roles globales y de club
  user-classes-card.tsx          # Clases inscritas
  user-club-info-card.tsx        # Info del club
  user-filters.tsx               # Filtros avanzados
```

**Funcionalidades**:
- **Lista**: Nombre, email, club, tipo, rol, estado, fecha registro
- **Filtros**: Por club, tipo de club, rol, estado de post-registro, activo/inactivo
- **Búsqueda**: Por nombre o email
- **Detalle de usuario**:
  - Info personal (nombre, email, género, edad, bautismo)
  - Foto de perfil
  - Estado de post-registro (paso 1, 2, 3)
  - Roles globales
  - Asignaciones de club (rol, instancia, año)
  - Clases inscritas con progreso
  - Contactos de emergencia
  - Representante legal (si aplica)

### 3.5.2 Admin Panel: Roles Globales

**Archivos a crear**:
```
src/app/(dashboard)/users/
  [userId]/
    roles/
      page.tsx                   # Gestión de roles del usuario

src/components/users/
  assign-role-dialog.tsx         # Diálogo para asignar rol global
```

### Entregable Microfase 3.5
- Lista de usuarios con filtros avanzados y búsqueda
- Detalle completo de usuario
- Asignación/revocación de roles globales
- Vista de estado de post-registro por usuario

---

## MICROFASE 3.6: Módulos Operativos (3-4 días)

### Objetivo
Pantallas de gestión para actividades, finanzas, inventario, camporees y certificaciones.

### 3.6.1 Finanzas

**Archivos a crear**:
```
src/app/(dashboard)/finances/
  page.tsx                       # Overview de finanzas por club
  categories/
    page.tsx                     # CRUD categorías financieras

src/lib/api/
  finances.ts

src/components/finances/
  finance-summary-card.tsx
  finance-category-form.tsx
  finance-entry-table.tsx
```

### 3.6.2 Inventario

```
src/app/(dashboard)/inventory/
  page.tsx                       # Inventario por club
  categories/
    page.tsx                     # CRUD categorías de inventario

src/lib/api/
  inventory.ts
```

### 3.6.3 Camporees

```
src/app/(dashboard)/camporees/
  page.tsx                       # Lista de camporees
  [id]/
    page.tsx                     # Detalle + miembros

src/lib/api/
  camporees.ts
```

### 3.6.4 Certificaciones

```
src/app/(dashboard)/certifications/
  page.tsx                       # CRUD certificaciones
  [id]/
    page.tsx                     # Detalle + módulos

src/lib/api/
  certifications.ts
```

### 3.6.5 Actividades

```
src/app/(dashboard)/activities/
  page.tsx                       # Vista general de actividades

src/lib/api/
  activities.ts
```

### Entregable Microfase 3.6
- Vista de finanzas con resumen por club
- CRUD de categorías financieras y de inventario
- Lista de camporees con miembros
- CRUD de certificaciones con módulos
- Vista de actividades

---

## MICROFASE 3.7: Dashboard y Reportes (2-3 días)

### Objetivo
Dashboard principal con estadísticas y gráficos.

### 3.7.1 Dashboard

**Archivos a crear**:
```
src/app/(dashboard)/
  page.tsx                       # Dashboard principal (reemplazar placeholder)

src/components/dashboard/
  stats-cards.tsx                # Cards de estadísticas generales
  clubs-chart.tsx                # Gráfico de clubes por tipo
  members-chart.tsx              # Gráfico de miembros activos
  recent-registrations.tsx       # Registros recientes
  pending-approvals-card.tsx     # Aprobaciones pendientes
  class-progress-chart.tsx       # Progreso de clases
```

**Estadísticas del Dashboard**:
- Total de usuarios registrados
- Total de clubes activos
- Miembros por tipo de club (Aventureros, Conquistadores, GM)
- Aprobaciones pendientes
- Registros recientes (últimos 7 días)
- Progreso promedio de clases
- Gráfico de miembros por mes
- Top 5 clubes por número de miembros

### Entregable Microfase 3.7
- Dashboard con estadísticas en tiempo real
- Gráficos con Recharts
- Cards de resumen
- Lista de acciones pendientes

---

## MICROFASE 3.8: Pulido, Testing y Deploy (2-3 días)

### Objetivo
Pulido visual, manejo de errores, testing y deploy a Vercel.

### 3.8.1 Pulido

- Estados de carga consistentes (Skeleton)
- Manejo de errores con error boundaries
- Empty states en todas las tablas
- Toast notifications en operaciones CRUD
- Responsive design (sidebar colapsable en mobile)
- Breadcrumbs en todas las páginas
- Dark mode (ya configurado base)

### 3.8.2 Testing

```
__tests__/
  components/
    data-table.test.tsx
    confirm-dialog.test.tsx
  pages/
    login.test.tsx
    dashboard.test.tsx
  lib/
    api-client.test.ts
```

### 3.8.3 Deploy

- Configurar `vercel.json`
- Variables de entorno en Vercel
- Build de producción
- Verificar en preview deployment
- Deploy a producción

### Entregable Microfase 3.8
- UI pulida y consistente
- Tests básicos
- Deploy funcional en Vercel
- Panel admin en producción

---

## Resumen de Microfases

| # | Microfase | Duración | Prioridad | Backend Nuevo | Archivos Admin |
|---|-----------|----------|-----------|---------------|----------------|
| 3.0 | Setup + Auth + Layout | 3-4 días | 🔴 CRÍTICO | 0 | ~20 |
| 3.1 | Jerarquía Geográfica | 3-4 días | 🔴 CRÍTICO | ~15 endpoints | ~25 |
| 3.2 | Catálogos de Referencia | 2-3 días | 🔴 CRÍTICO | ~18 endpoints | ~15 |
| 3.3 | Gestión de Clubes | 3-4 días | 🟡 IMPORTANTE | 0 (existen) | ~20 |
| 3.4 | Clases y Honores | 3-4 días | 🟡 IMPORTANTE | ~12 endpoints | ~20 |
| 3.5 | Gestión de Usuarios | 2-3 días | 🟢 MEDIA | 0 (existen) | ~12 |
| 3.6 | Módulos Operativos | 3-4 días | 🟢 MEDIA | ~5 endpoints | ~25 |
| 3.7 | Dashboard y Reportes | 2-3 días | 🟢 MEDIA | 0 | ~10 |
| 3.8 | Pulido + Deploy | 2-3 días | 🟢 MEDIA | 0 | ~10 |

**Totales**:
- **Duración**: ~23-32 días (~4-5 semanas)
- **Endpoints backend nuevos**: ~50 endpoints admin
- **Archivos admin nuevos**: ~157 archivos estimados

---

## Dependencias entre Fase 2 y Fase 3

```
Fase 2 (App Móvil)              Fase 3 (Admin Panel)
─────────────────               ─────────────────────

Microfase 2.1 (Auth)       ──── No depende ────

Microfase 2.2 (Foto)       ──── No depende ────

Microfase 2.3 (Info Personal) ← DEPENDE DE → Microfase 3.2 (Catálogos)
  - relationship_types                         (alergias, enfermedades,
  - allergies catalog                           tipos de relación)
  - diseases catalog

Microfase 2.4 (Selección Club) ← DEPENDE DE → Microfase 3.1 (Geografía)
  - countries, unions, etc.                     + Microfase 3.3 (Clubes)
  - clubs, instances
  - classes

Microfase 2.5 (Dashboard)  ← DEPENDE DE → Microfase 3.3 (Clubes)
  - club data                                 (datos de club poblados)

Microfase 2.7-2.8 (Clases, ← DEPENDE DE → Microfase 3.4 (Clases/Honores)
  Honores)                                    (catálogos poblados)
```

### Orden de Ejecución Recomendado (Paralelo)

```
Semana 1: F3-MF3.0 (Setup Admin)     | F2-MF2.1 (Auth App)
Semana 2: F3-MF3.1 (Geografía)       | F2-MF2.2 (Foto Post-Reg)
          F3-MF3.2 (Catálogos)       |
Semana 3: F3-MF3.3 (Clubes)          | F2-MF2.3 (Info Personal)
Semana 4: F3-MF3.4 (Clases/Honores)  | F2-MF2.4 (Selección Club)
Semana 5: F3-MF3.5 (Usuarios)        | F2-MF2.5 (Dashboard)
          F3-MF3.6 (Operativos)      | F2-MF2.6 (Perfil)
Semana 6: F3-MF3.7 (Dashboard Admin) | F2-MF2.7 (Clases)
          F3-MF3.8 (Deploy)          | F2-MF2.8 (Honores)
```

---

## Decisiones Técnicas

### 1. Prefijo `/admin/` para endpoints de gestión
Separar endpoints admin de los endpoints públicos/usuario para facilitar protección y auditoría.

### 2. Componente genérico CatalogCrudPage
Muchos catálogos comparten la misma estructura (tabla + formulario CRUD). Un componente genérico reduce duplicación.

### 3. Server Components por defecto
Usar Server Components de Next.js para páginas de listado. Solo marcar `'use client'` para componentes interactivos (formularios, tablas con sorting).

### 4. TanStack Query para cache
Usar TanStack Query para cachear datos de catálogos y reducir llamadas al backend. Los catálogos cambian poco, así que un `staleTime` de 5 minutos es apropiado.

### 5. Soft delete siempre
Nunca borrar registros. Siempre marcar como `active = false` y filtrar en las consultas.

---

**Creado**: 2026-02-08
**Status**: PLANIFICACIÓN
**Próximo paso**: Comenzar con Microfase 3.0 (Setup + Auth + Layout)
