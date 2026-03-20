# ESTRUCTURA SACDIA — Guía Operativa

**Estado**: ACTIVE
**Última actualización**: 2026-03-20
**Base de autoridad**: `source-of-truth.md` (gobernanza documental)
**Propósito**: navegación práctica de la estructura del monorepo y sus convenciones.

---

## 1. Layout del Monorepo

```
sacdia/
├── sacdia-backend/          # API REST (NestJS + Prisma)
├── sacdia-admin/            # Panel web (Next.js 16 + shadcn/ui)
├── sacdia-app/              # App móvil (Flutter + Clean Architecture)
├── docs/                    # Documentación técnica centralizada
└── CLAUDE.md                # Guía global del proyecto
```

---

## 2. Backend — NestJS + Prisma

**Ubicación**: `/sacdia-backend`

### Módulos principales
```
src/
├── auth/                 # Autenticación (Supabase JWT)
├── users/                # Usuarios, progreso de clases
├── catalogs/             # Catálogos (honores, medicinas, etc.)
├── clubs/                # Gestión de clubes
├── classes/              # Clases progresivas
├── honors/               # Honores y categorías
├── activities/           # Actividades de club
├── finances/             # Finanzas
├── camporees/            # Camporees
├── certifications/       # Certificaciones Guías Mayores
├── folders/              # Carpetas de evidencias
├── inventory/            # Inventario
├── rbac/                 # Control de acceso basado en roles
├── admin/                # Endpoints de administración
├── common/               # Guards, decorators, filtros, interceptores
├── investiture/          # Validación de investiduras
├── notifications/        # Firebase FCM + notificaciones
└── prisma/               # Migraciones, seeds, esquema
```

### Stack
- **Runtime**: NestJS 11 + TypeScript
- **ORM**: Prisma 7 → PostgreSQL (Supabase)
- **Auth**: JWT vía JWKS (ES256) desde Supabase
- **Cache**: Redis (fallback in-memory)
- **Push**: Firebase Cloud Messaging
- **Prefijo API**: `/api/v1/*`

### Convenciones
- Respuesta admin: `{ status, data }`
- Guards: `JwtAuthGuard`, `GlobalRolesGuard`, `OwnerOrAdminGuard`
- Async/await para todas las operaciones
- Validación de entrada vía decoradores de NestJS

---

## 3. Admin — Next.js 16 + shadcn/ui

**Ubicación**: `/sacdia-admin`

### Estructura
```
app/
├── (auth)/               # Rutas públicas (login, register)
├── (dashboard)/          # Dashboard protegido
│   ├── clubs/
│   ├── users/
│   ├── activities/
│   ├── finances/
│   └── [otros]
├── api/                  # API Routes de Next.js
└── layout.tsx

components/
├── ui/                   # shadcn/ui componentes base
├── clubs/                # Componentes específicos del feature
├── activities/
├── finances/
└── [otros features]/

lib/
├── supabase/             # Cliente Supabase (SSR)
└── api/                  # Clientes HTTP para backend
```

### Stack
- **Framework**: Next.js 16 (App Router)
- **UI**: shadcn/ui + Tailwind CSS v4
- **Icons**: lucide-react
- **Forms**: React Hook Form + Zod
- **Auth**: Supabase Auth (SSR con cookies)
- **Design System**: Ver `DESIGN-SYSTEM.md` para detalles

### Convenciones
- Server Components por defecto; `'use client'` solo donde necesario
- CRUD dialogs: crear/editar → Dialog modal
- Delete → AlertDialog confirmación
- Semantic colors en Tailwind (no hardcoded: `bg-primary/10`, `text-muted-foreground`)

---

## 4. App Móvil — Flutter + Clean Architecture

**Ubicación**: `/sacdia-app`

### Estructura
```
lib/
├── core/
│   ├── constants/        # URLs, claves, constantes globales
│   ├── theme/            # Tema Material + colores
│   └── utils/            # Funciones utilitarias
├── data/
│   ├── models/           # Mapeos JSON ↔ Dart
│   ├── repositories/     # Implementación de repositorios
│   └── datasources/      # Clientes HTTP (Dio)
├── domain/
│   ├── entities/         # Entidades del negocio (puros)
│   ├── repositories/     # Contratos abstractos
│   └── usecases/         # Lógica de negocio
└── presentation/
    ├── screens/          # Pantallas principales
    ├── widgets/          # Componentes reutilizables
    └── providers/        # Riverpod state management
```

### Stack
- **Framework**: Flutter 3.x
- **Architecture**: Clean Architecture (3 capas)
- **State**: Riverpod (DI + state)
- **HTTP**: Dio
- **Storage local**: Hive
- **Auth**: Supabase Auth

### Convenciones
- Dependency injection via Riverpod providers
- Offline first: cache en Hive antes de red
- JWT almacenado seguro en Hive
- Async/await para operaciones de datos

---

## 5. Documentación — Estructura Centralizada

**Ubicación**: `/docs`

### Carpetas principales
```
docs/
├── canon/                # Autoridad de negocio y arquitectura
│   ├── dominio-sacdia.md
│   ├── identidad-sacdia.md
│   ├── arquitectura-sacdia.md
│   └── decisiones-clave.md
│
├── features/             # Especificaciones de dominio (16 specs)
│   ├── auth.md
│   ├── gestion-clubs.md
│   ├── actividades.md
│   └── [más dominios]
│
├── api/                  # Runtime de API
│   └── ENDPOINTS-LIVE-REFERENCE.md (220 endpoints, autoridad)
│
├── database/             # Esquema y referencias
│   ├── schema.prisma (fuente única de verdad)
│   └── SCHEMA-REFERENCE.md (~72 modelos)
│
├── steering/             # Convenciones operativas
│   ├── source-of-truth.md (gobernanza)
│   ├── STRUCTURE-GUIDE.md (ESTE documento)
│   ├── tech.md
│   ├── coding-standards.md
│   ├── data-guidelines.md
│   └── agents.md
│
├── audit/                # Auditoría y estado
│   ├── completion-matrix.md (cobertura documental)
│   └── REALITY-MATRIX.md (estado de implementación)
│
├── guides/               # Guías operativas
│   └── [walkthroughs por feature]
│
└── history/              # Documentación histórica (referencia)
    └── [archivos previos]
```

### Convención de autoridad
1. **Canon** (`canon/*.md`): identidad y decisiones duraderas
2. **API Live Reference** (`api/ENDPOINTS-LIVE-REFERENCE.md`): 220 endpoints
3. **Schema Prisma** (`schema.prisma`): fuente de verdad del modelo
4. **Feature Specs** (`features/*.md`): 16 dominios completos
5. **Steering** (`steering/*.md`): convenciones subordinadas

---

## 6. Nombrado — Convenciones Globales

### TypeScript (Backend + Admin)
- **Variables/funciones**: `camelCase`
- **Clases/interfaces**: `PascalCase`
- **Enums**: `UPPER_CASE`
- **Archivos**: `kebab-case` (`.controller.ts`, `.service.ts`)

### SQL/Prisma
- **Tablas/columnas**: `snake_case`
- **PKs**: `id` (sempre)
- **FKs**: `[tabla]_id`
- **Timestamps**: `created_at`, `updated_at`

### Flutter/Dart
- **Classes**: `PascalCase`
- **Variables/functions**: `camelCase`
- **Files**: `snake_case.dart`
- **Folders**: `snake_case`

### Git
- **Commits**: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`
- **Ramas**: `feature/`, `fix/`, `docs/`
- **PRs**: Descripción clara en body; no en título

---

## 7. Encontrar cosas rápidamente

### Buscar endpoint
→ `docs/api/ENDPOINTS-LIVE-REFERENCE.md` (Ctrl+F por módulo o método)

### Buscar modelo de datos
→ `docs/database/SCHEMA-REFERENCE.md` (referencia humana)
→ `sacdia-backend/prisma/schema.prisma` (autoridad)

### Buscar especificación de feature
→ `docs/features/{nombre-dominio}.md`
Ejemplo: `docs/features/actividades.md`

### Buscar componente de admin
→ `sacdia-admin/components/[feature]/` o `app/(dashboard)/[feature]/`

### Buscar pantalla de app
→ `sacdia-app/lib/presentation/screens/` o `lib/domain/usecases/`

### Buscar estándar de código
→ `docs/steering/coding-standards.md`

### Entender decisiones arquitectónicas
→ `docs/canon/decisiones-clave.md` o `docs/canon/arquitectura-sacdia.md`

---

## 8. URLs de desarrollo

```
Backend API:     http://localhost:3000
Admin web:       http://localhost:3001
API Docs:        http://localhost:3000/api
Supabase:        Configurar en .env de cada repo
```

---

## 9. Comandos esenciales

**Backend**
```bash
cd sacdia-backend
pnpm run start:dev       # Dev server
pnpm prisma migrate dev  # Crear/ejecutar migración
pnpm test                # Tests unitarios
```

**Admin**
```bash
cd sacdia-admin
pnpm dev                 # Dev server (puerto 3001)
pnpm build               # Build producción
```

**App**
```bash
cd sacdia-app
flutter run              # En emulador/device
flutter test             # Tests
```

---

## 10. Validación de estructura

Verificar que estás en la estructura correcta:

- ✅ Backend tiene `/src/[modulo]/` con `.module.ts`, `.service.ts`, `.controller.ts`
- ✅ Admin tiene `/app/(dashboard)/[feature]/` con `page.tsx` + componentes en `/components`
- ✅ App tiene `/lib/domain/`, `/lib/data/`, `/lib/presentation/` claros
- ✅ Docs tiene `/canon/`, `/features/`, `/api/`, `/steering/`, `/database/` como autoridad
- ✅ Commits siguen `feat:`, `fix:`, `docs:` (sin "Co-Authored-By")

---

**Última validación**: 2026-03-20 — Actualizado post-Wave 2 (GAP-W2-01 a 05 cerrados, 16 dominios implementados, 220 endpoints documentados).
