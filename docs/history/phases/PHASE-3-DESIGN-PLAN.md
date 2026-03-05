# Plan de Diseño - Fase 3: Panel Administrativo SACDIA

**Fecha**: 10 de febrero de 2026
**Estado**: PLANIFICACIÓN
**Basado en**: Análisis de `desing-admin-portal/` mockups + documentación existente

---

## 1. Resumen Ejecutivo

Este documento define la estrategia de diseño visual para transformar el panel administrativo SACDIA de un boilerplate básico a una interfaz de producción distintiva y memorable, basándose en los mockups proporcionados en `desing-admin-portal/`.

### Estado Actual vs. Objetivo

| Aspecto | Estado Actual | Objetivo (Mockups) |
|---------|---------------|-------------------|
| **Tema** | ~~Teal-green~~ (a eliminar) | Dark mode + Light mode (blanco/hueso) |
| **Login** | ✅ Implementado (actualizar colores) | Adaptar a nueva paleta |
| **Dashboard** | ❌ No existe | Estadísticas + gráficos + tablas |
| **Sidebar** | ❌ No existe | Navegación jerárquica con iconos |
| **Tablas** | Básicas (shadcn) | Estilizadas con hover states |
| **Cards** | Básicas | Shadows + borders + glass effects |

### Cambio Importante: Eliminar Tema Teal-Green

El tema actual `teal-green` (hue 165) será **completamente reemplazado** por:
- **Dark Mode:** Navy oscuro (#101022) con acento azul eléctrico (#2b2bee)
- **Light Mode:** Blanco/hueso con acento azul eléctrico (#2b2bee)

---

## 2. Sistema de Diseño

### 2.1 Paleta de Colores

El sistema soporta **Dark Mode** (principal, basado en mockups) y **Light Mode** (blanco/hueso).

#### Dark Mode (Principal - Basado en Mockups)

```css
:root.dark {
  /* Fondos */
  --background: #101022;       /* Fondo principal - Navy muy oscuro */
  --card: #16162c;             /* Tarjetas y paneles */
  --popover: #16162c;          /* Popovers y dropdowns */
  --muted: #1a1a36;            /* Elementos secundarios */

  /* Acento Primario - Azul Eléctrico */
  --primary: #2b2bee;
  --primary-foreground: #ffffff;

  /* Secundario */
  --secondary: #232342;
  --secondary-foreground: #e2e8f0;

  /* Bordes */
  --border: rgba(148, 163, 184, 0.15);  /* Sutil */
  --input: rgba(148, 163, 184, 0.12);
  --ring: #2b2bee;

  /* Texto */
  --foreground: #ffffff;
  --muted-foreground: #94a3b8;  /* slate-400 */

  /* Estados */
  --destructive: #ef4444;
  --destructive-foreground: #ffffff;
  --success: #22c55e;
  --success-foreground: #ffffff;
  --warning: #f59e0b;
  --warning-foreground: #1a1a2e;

  /* Sidebar específico */
  --sidebar: #101022;
  --sidebar-foreground: #94a3b8;
  --sidebar-primary: #2b2bee;
  --sidebar-accent: rgba(43, 43, 238, 0.1);
  --sidebar-border: rgba(148, 163, 184, 0.1);
}
```

#### Light Mode (Blanco/Hueso)

```css
:root {
  /* Fondos - Blanco/Hueso */
  --background: #fafaf9;       /* Hueso muy claro (stone-50) */
  --card: #ffffff;             /* Blanco puro para cards */
  --popover: #ffffff;
  --muted: #f5f5f4;            /* stone-100 */

  /* Acento Primario - Mismo azul eléctrico */
  --primary: #2b2bee;
  --primary-foreground: #ffffff;

  /* Secundario */
  --secondary: #f5f5f4;        /* stone-100 */
  --secondary-foreground: #1c1917;  /* stone-900 */

  /* Bordes */
  --border: #e7e5e4;           /* stone-200 */
  --input: #e7e5e4;
  --ring: #2b2bee;

  /* Texto */
  --foreground: #1c1917;       /* stone-900 */
  --muted-foreground: #78716c; /* stone-500 */

  /* Estados */
  --destructive: #dc2626;      /* red-600 */
  --destructive-foreground: #ffffff;
  --success: #16a34a;          /* green-600 */
  --success-foreground: #ffffff;
  --warning: #d97706;          /* amber-600 */
  --warning-foreground: #ffffff;

  /* Sidebar específico */
  --sidebar: #ffffff;
  --sidebar-foreground: #57534e;  /* stone-600 */
  --sidebar-primary: #2b2bee;
  --sidebar-accent: rgba(43, 43, 238, 0.08);
  --sidebar-border: #e7e5e4;
}
```

#### Colores Semánticos Compartidos

```css
/* Estados y badges (funcionan en ambos modos) */
--status-active: #22c55e;       /* green-500 */
--status-active-bg: rgba(34, 197, 94, 0.1);
--status-pending: #f59e0b;      /* amber-500 */
--status-pending-bg: rgba(245, 158, 11, 0.1);
--status-inactive: #ef4444;     /* red-500 */
--status-inactive-bg: rgba(239, 68, 68, 0.1);
--status-draft: #64748b;        /* slate-500 */
--status-draft-bg: rgba(100, 116, 139, 0.1);

/* Colores por tipo de club */
--club-pathfinder: #2b2bee;     /* Azul eléctrico */
--club-adventurer: #a855f7;     /* Púrpura */
--club-master-guide: #3b82f6;   /* Azul cielo */
```

#### Migración de globals.css (ANTES → DESPUÉS)

**ELIMINAR** (tema teal-green actual):
```css
/* ❌ ELIMINAR - Paleta SACDIA teal-green hue 165 */
--primary: oklch(0.44 0.11 165);    /* Teal */
--ring: oklch(0.50 0.11 165);
/* ... todas las variables con hue 165 */
```

**REEMPLAZAR CON** (nueva paleta):
```css
/* ✅ NUEVA - Light Mode (blanco/hueso) */
:root {
  --background: 30 6% 98%;           /* #fafaf9 stone-50 */
  --foreground: 24 10% 10%;          /* #1c1917 stone-900 */
  --card: 0 0% 100%;                 /* #ffffff */
  --card-foreground: 24 10% 10%;
  --popover: 0 0% 100%;
  --popover-foreground: 24 10% 10%;
  --primary: 241 86% 55%;            /* #2b2bee azul eléctrico */
  --primary-foreground: 0 0% 100%;
  --secondary: 30 6% 96%;            /* #f5f5f4 stone-100 */
  --secondary-foreground: 24 10% 10%;
  --muted: 30 6% 96%;
  --muted-foreground: 24 6% 46%;     /* #78716c stone-500 */
  --accent: 30 6% 96%;
  --accent-foreground: 24 10% 10%;
  --destructive: 0 72% 51%;          /* #dc2626 red-600 */
  --destructive-foreground: 0 0% 100%;
  --border: 24 6% 90%;               /* #e7e5e4 stone-200 */
  --input: 24 6% 90%;
  --ring: 241 86% 55%;               /* #2b2bee */
  --radius: 0.5rem;
}

/* ✅ NUEVA - Dark Mode (navy oscuro) */
.dark {
  --background: 240 33% 10%;         /* #101022 */
  --foreground: 0 0% 100%;
  --card: 240 33% 13%;               /* #16162c */
  --card-foreground: 0 0% 100%;
  --popover: 240 33% 13%;
  --popover-foreground: 0 0% 100%;
  --primary: 241 86% 55%;            /* #2b2bee */
  --primary-foreground: 0 0% 100%;
  --secondary: 240 25% 17%;          /* #232342 */
  --secondary-foreground: 210 40% 90%;
  --muted: 240 25% 17%;
  --muted-foreground: 215 16% 62%;   /* #94a3b8 slate-400 */
  --accent: 241 86% 55% / 0.1;       /* primary con alpha */
  --accent-foreground: 0 0% 100%;
  --destructive: 0 84% 60%;          /* #ef4444 red-500 */
  --destructive-foreground: 0 0% 100%;
  --border: 215 16% 47% / 0.15;      /* slate-500 con alpha */
  --input: 215 16% 47% / 0.12;
  --ring: 241 86% 55%;
}
```

**Actualizar Login** (`src/app/(auth)/login/page.tsx`):
```css
/* ❌ ELIMINAR */
from-[#00b4a0] to-[#008878]   /* Gradientes teal */
rgba(0,180,160,...)           /* Glows teal */
#00b4a0                       /* Color teal */

/* ✅ REEMPLAZAR CON */
from-[#2b2bee] to-[#1e1ebd]   /* Gradientes azul eléctrico */
rgba(43,43,238,...)           /* Glows azul */
#2b2bee                       /* Color primario */
```

### 2.2 Tipografía

```css
/* Fuentes principales */
--font-sans: "Inter", "SF Pro Display", -apple-system, sans-serif;
--font-mono: "JetBrains Mono", "SF Mono", monospace;

/* Escala tipográfica */
--text-xs: 0.625rem;    /* 10px - Labels, badges */
--text-sm: 0.75rem;     /* 12px - Secondary text */
--text-base: 0.875rem;  /* 14px - Body text */
--text-lg: 1rem;        /* 16px - Subtitles */
--text-xl: 1.25rem;     /* 20px - Section headers */
--text-2xl: 1.5rem;     /* 24px - Page titles */
--text-3xl: 1.875rem;   /* 30px - Hero text */

/* Pesos */
--font-medium: 500;
--font-semibold: 600;
--font-bold: 700;
--font-black: 900;

/* Tracking (letter-spacing) */
--tracking-tight: -0.025em;
--tracking-normal: 0;
--tracking-wide: 0.025em;
--tracking-wider: 0.05em;
--tracking-widest: 0.1em;   /* Para labels uppercase */
```

### 2.3 Espaciado y Radios

```css
/* Espaciado base (8px grid) */
--space-1: 0.25rem;   /* 4px */
--space-2: 0.5rem;    /* 8px */
--space-3: 0.75rem;   /* 12px */
--space-4: 1rem;      /* 16px */
--space-6: 1.5rem;    /* 24px */
--space-8: 2rem;      /* 32px */
--space-10: 2.5rem;   /* 40px */
--space-12: 3rem;     /* 48px */

/* Border radius */
--radius-sm: 0.375rem;  /* 6px - Badges, pills */
--radius-md: 0.5rem;    /* 8px - Buttons, inputs */
--radius-lg: 0.75rem;   /* 12px - Cards pequeñas */
--radius-xl: 1rem;      /* 16px - Cards grandes */
--radius-2xl: 1.25rem;  /* 20px - Panels */
--radius-full: 9999px;  /* Pills, avatars */
```

### 2.4 Sombras y Efectos

```css
/* Sombras */
--shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.3);
--shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.3);
--shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.4);
--shadow-xl: 0 20px 25px -5px rgba(0, 0, 0, 0.5);
--shadow-glow: 0 0 20px var(--primary-glow);
--shadow-primary: 0 4px 20px rgba(43, 43, 238, 0.25);

/* Glass effects */
--glass-bg: rgba(22, 22, 44, 0.8);
--glass-blur: blur(12px);
--glass-border: 1px solid rgba(255, 255, 255, 0.05);
```

---

## 3. Componentes Clave

### 3.1 Sidebar Navigation

```
┌─────────────────────────┐
│  [S] SACDIA             │ ← Logo + Brand
├─────────────────────────┤
│                         │
│  📊 Dashboard           │ ← Active state: bg-primary/10
│  👤 Approvals    [12]   │ ← Badge para pending items
│  👥 Members             │
│  🗺️  Geographical       │
│  🏕️  Events & Camporee  │
│  📋 Curriculum          │
│  🏆 Live Scoring        │
│  🔐 Security Matrix ▼   │ ← Expandable submenu
│     ├─ Assignment       │
│     ├─ Roles Catalog    │
│     └─ Permissions      │
│  🎖️  Credentials        │
│  ⚙️  Settings           │
│                         │
├─────────────────────────┤
│  [Avatar] Admin User    │ ← User profile section
│  admin@sacdia.org       │
│  🚪 Sign Out            │
└─────────────────────────┘
```

**Especificaciones:**
- Ancho: 256px (w-64)
- Background: `#101022`
- Border right: `border-slate-800`
- Item height: 44px (py-3)
- Icon size: 20px
- Active indicator: `bg-[#2b2bee]/10 text-white`
- Hover: `hover:bg-slate-800 hover:text-white`

### 3.2 Header

```
┌────────────────────────────────────────────────────────────────┐
│  SACDIA > Dashboard                    🔍 Search...    🔔  👤  │
└────────────────────────────────────────────────────────────────┘
```

**Especificaciones:**
- Height: 64px (h-16)
- Background: `#101022/80` con `backdrop-blur-sm`
- Position: sticky top-0
- Breadcrumbs con separador `ChevronRight`
- Search input: 256px width
- Notification bell con badge rojo

### 3.3 Stat Cards

```
┌─────────────────────────────┐
│  [Icon watermark]    ↗ 12%  │
│                             │
│  Total Users                │
│  12,450                     │
└─────────────────────────────┘
```

**Especificaciones:**
- Background: `#16162c`
- Border: `border-slate-800`
- Radius: `rounded-xl`
- Padding: `p-6`
- Icon: 48px, opacity-10, posición top-right
- Trend indicator: Verde para up, rojo para down
- Valor: `text-2xl font-bold`

### 3.4 Data Tables

**Especificaciones:**
- Container: `bg-[#16162c] border border-slate-800 rounded-xl overflow-hidden`
- Header row: `bg-slate-900/50` con texto uppercase 10px tracking-widest
- Body rows: hover `bg-slate-800/30`
- Dividers: `divide-y divide-slate-800`
- Pagination: Botones numéricos con active state `bg-[#2b2bee]`

### 3.5 Status Badges

| Status | Background | Text | Border |
|--------|-----------|------|--------|
| Active/Approved | `bg-green-500/10` | `text-green-500` | `border-green-500/20` |
| Pending | `bg-amber-500/10` | `text-amber-500` | `border-amber-500/20` |
| Inactive/Denied | `bg-red-500/10` | `text-red-500` | `border-red-500/20` |
| Draft | `bg-slate-500/10` | `text-slate-500` | `border-slate-500/20` |

**Estilo:**
```css
.status-badge {
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 10px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
```

### 3.6 Form Inputs

```css
.input-field {
  background: var(--bg-input);
  border: 1px solid var(--border-default);
  border-radius: var(--radius-lg);
  padding: 12px 16px;
  font-size: 14px;
  color: var(--text-primary);
  transition: all 0.2s;
}

.input-field:focus {
  border-color: var(--primary);
  outline: none;
  box-shadow: 0 0 0 3px var(--primary-glow);
}
```

### 3.7 Buttons

| Variante | Estilo |
|----------|--------|
| **Primary** | `bg-[#2b2bee] hover:bg-[#1e1ebd] text-white shadow-lg shadow-[#2b2bee]/20` |
| **Secondary** | `bg-slate-900 border border-slate-800 text-slate-300 hover:text-white hover:bg-slate-800` |
| **Destructive** | `text-red-500 hover:bg-red-500/10` |
| **Ghost** | `text-slate-400 hover:text-white hover:bg-slate-800` |

---

## 4. Páginas a Implementar

### 4.1 Prioridad Alta (Bloquean Fase 2)

| Página | Complejidad | Referencia Mockup |
|--------|-------------|-------------------|
| Dashboard Layout (Sidebar + Header) | Alta | `App.tsx` |
| Dashboard Overview | Alta | `Dashboard.tsx` |
| Geographical Hierarchy | Alta | `GeographicalHierarchy.tsx` |
| Member Approvals | Media | `MemberApprovals.tsx` |
| Club Members | Media | `ClubMembers.tsx` |

### 4.2 Prioridad Media

| Página | Complejidad | Referencia Mockup |
|--------|-------------|-------------------|
| Curriculum Management | Alta | `CurriculumManagement.tsx` |
| Roles & Permissions Matrix | Alta | `RolesPermissions.tsx` |
| Roles Catalog | Media | `RolesCatalog.tsx` |
| Permissions Catalog | Media | `PermissionsCatalog.tsx` |
| Settings | Media | `SettingsPage.tsx` |

### 4.3 Prioridad Baja (Post-MVP)

| Página | Complejidad | Referencia Mockup |
|--------|-------------|-------------------|
| Live Scoring | Alta | `LiveScoring.tsx` |
| Event Management | Alta | `EventManagement.tsx` |
| ID Generator | Media | `IDGenerator.tsx` |

---

## 5. Arquitectura de Componentes

### 5.1 Estructura de Carpetas Propuesta

```
src/
├── components/
│   ├── ui/                      # shadcn/ui base components
│   │   ├── button.tsx
│   │   ├── input.tsx
│   │   ├── table.tsx
│   │   └── ...
│   │
│   ├── layout/                  # Layout components
│   │   ├── app-sidebar.tsx      # Navegación principal
│   │   ├── sidebar-nav-item.tsx # Item de navegación
│   │   ├── app-header.tsx       # Header con breadcrumbs
│   │   ├── breadcrumbs.tsx      # Breadcrumbs dinámicos
│   │   └── user-nav.tsx         # Menú de usuario
│   │
│   ├── shared/                  # Componentes reutilizables
│   │   ├── data-table.tsx       # Tabla genérica
│   │   ├── data-table-pagination.tsx
│   │   ├── data-table-toolbar.tsx
│   │   ├── stat-card.tsx        # Card de estadística
│   │   ├── status-badge.tsx     # Badge de estado
│   │   ├── page-header.tsx      # Header de página
│   │   ├── loading-skeleton.tsx # Skeleton loader
│   │   ├── empty-state.tsx      # Estado vacío
│   │   └── confirm-dialog.tsx   # Diálogo de confirmación
│   │
│   ├── dashboard/               # Componentes del dashboard
│   │   ├── stats-overview.tsx
│   │   ├── members-chart.tsx
│   │   ├── registrations-chart.tsx
│   │   └── recent-registrations-table.tsx
│   │
│   ├── catalogs/                # Componentes de catálogos
│   │   ├── geography/
│   │   │   ├── geography-breadcrumb.tsx
│   │   │   ├── country-form.tsx
│   │   │   ├── union-form.tsx
│   │   │   └── ...
│   │   └── ...
│   │
│   ├── clubs/                   # Componentes de clubes
│   │   ├── club-detail-card.tsx
│   │   ├── member-list.tsx
│   │   └── ...
│   │
│   └── security/                # Componentes de seguridad
│       ├── role-card.tsx
│       ├── permission-toggle.tsx
│       └── ...
│
├── app/
│   ├── (auth)/
│   │   ├── layout.tsx           # Layout de auth (centrado)
│   │   └── login/page.tsx       # ✅ Ya implementado
│   │
│   └── (dashboard)/
│       ├── layout.tsx           # Layout con sidebar + header
│       ├── page.tsx             # Dashboard principal
│       ├── catalogs/            # Rutas de catálogos
│       ├── clubs/               # Rutas de clubes
│       ├── users/               # Rutas de usuarios
│       └── security/            # Rutas de seguridad
│
└── styles/
    └── globals.css              # Variables CSS del tema
```

### 5.2 Convenciones de Nombrado

| Tipo | Convención | Ejemplo |
|------|-----------|---------|
| Componentes | PascalCase | `StatCard.tsx` |
| Páginas | kebab-case folders | `member-approvals/page.tsx` |
| Utilidades | camelCase | `formatCurrency.ts` |
| CSS Variables | kebab-case | `--bg-card` |
| Tailwind Classes | Directamente en JSX | `className="..."` |

---

## 6. Plan de Implementación

### Fase 3.0: Setup del Sistema de Diseño (2-3 días)

**Tareas:**
1. **ELIMINAR tema teal-green** de `globals.css`:
   - Reemplazar todas las variables OKLCH hue 165
   - Light mode: paleta stone (blanco/hueso)
   - Dark mode: paleta navy oscuro (#101022, #16162c)
   - Primary: azul eléctrico #2b2bee en ambos modos
2. **Actualizar página de login**:
   - Cambiar gradientes teal → azul eléctrico
   - Actualizar glows y shadows
3. Configurar dark mode por defecto con toggle
4. Instalar componentes shadcn/ui faltantes:
   - `sidebar`, `chart`, `sonner`, `command`
5. Crear componentes base:
   - `StatCard`
   - `StatusBadge` (actualizar el existente)
   - `PageHeader`
   - `EmptyState`

**Entregable:** Sistema de diseño configurado, tema teal eliminado, componentes base listos.

### Fase 3.1: Layout Principal (3-4 días)

**Tareas:**
1. Implementar `AppSidebar` con navegación completa
2. Implementar `AppHeader` con breadcrumbs y search
3. Crear `DashboardLayout` que combine ambos
4. Configurar navegación con Next.js `usePathname`
5. Implementar responsive behavior (sidebar colapsable en mobile)

**Entregable:** Shell de la aplicación funcional con navegación.

### Fase 3.2: Dashboard Principal (2-3 días)

**Tareas:**
1. Implementar grid de `StatCard`s
2. Integrar Recharts para gráficos:
   - `AreaChart` para registros
   - Progress bars para miembros por tipo
3. Crear tabla de registros recientes
4. Conectar con API endpoints existentes

**Entregable:** Dashboard funcional con datos reales.

### Fase 3.3: Actualizar Páginas de Catálogos (3-4 días)

**Tareas:**
1. Aplicar nuevo estilo a páginas existentes de geografía
2. Implementar vista master-detail para jerarquía geográfica
3. Actualizar formularios con nuevo estilo de inputs
4. Añadir animaciones de transición

**Entregable:** Catálogos visuales y funcionales.

### Fase 3.4: Gestión de Clubes y Miembros (3-4 días)

**Tareas:**
1. Crear página de detalle de club con tabs
2. Implementar lista de miembros con filtros
3. Crear cards de aprobación de miembros
4. Implementar acciones de aprobar/rechazar

**Entregable:** Flujo completo de gestión de clubes.

### Fase 3.5: Security Matrix (2-3 días)

**Tareas:**
1. Implementar catálogo de roles (grid de cards)
2. Implementar catálogo de permisos (tabla)
3. Crear matriz de asignación roles-permisos
4. Implementar toggles de permisos

**Entregable:** Sistema de seguridad visual.

### Fase 3.6: Polish y QA (2-3 días)

**Tareas:**
1. Revisar consistencia visual en todas las páginas
2. Añadir estados de loading con skeletons
3. Implementar toast notifications
4. Testing de responsive design
5. Optimización de performance

**Entregable:** Panel admin pulido y listo para producción.

---

## 7. Decisiones de Diseño

### 7.1 Eliminar Tema Teal-Green

**Decisión:** Eliminar completamente la paleta teal-green (hue 165) del `globals.css`.

**Justificación:**
- El cliente prefiere una paleta neutra (blanco/hueso) para light mode
- El azul eléctrico (#2b2bee) de los mockups será el nuevo acento
- Consistencia con el diseño de los mockups

**Implementación:**
- Reemplazar todas las variables OKLCH hue 165 en `globals.css`
- Usar paleta stone (hueso) para light mode
- Usar paleta navy-oscuro para dark mode
- Mantener #2b2bee como color primario en ambos modos

### 7.2 Dark Mode por Defecto con Soporte Light Mode

**Decisión:** Dark mode como default, con toggle para light mode.

**Justificación:**
- Los mockups fueron diseñados en dark mode
- Los administradores suelen trabajar largas horas
- Light mode disponible para preferencia del usuario

**Implementación:**
- Añadir clase `dark` al `<html>` por defecto
- Implementar toggle de tema en settings o header
- Persistir preferencia en localStorage

### 7.3 Actualizar Login a Nueva Paleta

**Decisión:** Adaptar el login actual a la nueva paleta azul eléctrico.

**Justificación:**
- El login actual usa teal (#00b4a0) que será eliminado
- Debe usar el nuevo color primario #2b2bee
- Mantener el diseño limpio y animaciones existentes

**Implementación:**
- Cambiar gradientes de teal a azul eléctrico
- Actualizar glows y shadows al nuevo color
- Mantener animaciones de orbs y shimmer

### 7.4 shadcn/ui como Base

**Decisión:** Usar shadcn/ui como base y extender con estilos custom.

**Justificación:**
- Consistencia con el setup existente
- Componentes accesibles por defecto
- Fácil de customizar con CSS variables
- Mantenibilidad a largo plazo

### 7.4 Recharts para Gráficos

**Decisión:** Usar Recharts para todos los gráficos.

**Justificación:**
- Ya usado en los mockups
- Buena integración con React
- Fácil de estilizar para match con el tema

---

## 8. Métricas de Éxito

| Métrica | Objetivo |
|---------|----------|
| Páginas implementadas | 12+ páginas principales |
| Consistencia visual | 100% adherencia al sistema de diseño |
| Responsive | Funcional en desktop y tablet |
| Performance | LCP < 2.5s, FID < 100ms |
| Accesibilidad | WCAG 2.1 AA compliance |

---

## 9. Recursos y Referencias

### Mockups Disponibles

| Archivo | Descripción |
|---------|-------------|
| `Dashboard.tsx` | Dashboard principal con stats y gráficos |
| `MemberApprovals.tsx` | Grid de cards para aprobar miembros |
| `GeographicalHierarchy.tsx` | Vista master-detail de geografía |
| `ClubMembers.tsx` | Detalle de club con tabla de miembros |
| `CurriculumManagement.tsx` | Tree view con panel de edición |
| `LiveScoring.tsx` | Leaderboard con tabs y stats |
| `RolesPermissions.tsx` | Matriz de permisos por rol |
| `RolesCatalog.tsx` | Grid de cards de roles |
| `PermissionsCatalog.tsx` | Tabla de permisos |
| `EventManagement.tsx` | Hero de evento + grid de eventos |
| `IDGenerator.tsx` | Generador de credenciales + live feed |
| `SettingsPage.tsx` | Configuración con navegación lateral |

### Mockups de Imágenes

Ubicación: `desing-admin-portal/mockups/*/screen.png`

---

## 10. Próximos Pasos

1. **Inmediato:** Aprobar este plan de diseño
2. **Día 1-2:** Configurar sistema de diseño (variables CSS, dark mode)
3. **Día 3-5:** Implementar layout principal (sidebar + header)
4. **Día 6-8:** Dashboard con estadísticas y gráficos
5. **Día 9+:** Continuar con páginas según prioridad

---

**Creado:** 2026-02-10
**Última actualización:** 2026-02-10
**Status:** PENDIENTE APROBACIÓN
