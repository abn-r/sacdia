# Project Structure

> Define la organización de archivos y directorios del proyecto

---

## Estructura General

[Adapta según tu stack - este es un ejemplo para proyecto full-stack]

``
project-root/
├── .specs/                   # Sistema de especificaciones
│   ├── _templates/          # Plantillas reutilizables
│   ├── _steering/           # Archivos de configuración global
│   ├── _guides/             # Guías de uso
│   └── features/            # Specs de features individuales
│
├── frontend/ (o src/ si monorepo)
│   ├── components/          # Componentes React/Vue
│   │   ├── common/         # Componentes compartidos
│   │   └── [Feature]/      # Componentes por feature
│   │       ├── [Feature]Container.tsx
│   │       ├── [Feature]View.tsx
│   │       ├── hooks/
│   │       ├── types.ts
│   │       └── styles.module.css
│   │
│   ├── pages/              # Páginas/Rutas
│   ├── services/           # API clients, servicios externos
│   ├── store/              # State management
│   ├── hooks/              # Custom hooks globales
│   ├── utils/              # Utilidades
│   ├── types/              # TypeScript types globales
│   ├── constants/          # Constantes
│   ├── assets/             # Imágenes, fonts, etc.
│   └── styles/             # Estilos globales
│
├── backend/ (o api/)
│   ├── src/
│   │   ├── controllers/    # Request handlers
│   │   ├── services/       # Lógica de negocio
│   │   ├── models/         # Modelos de datos
│   │   ├── routes/         # Definición de rutas
│   │   ├── middleware/     # Middleware (auth, logging, etc.)
│   │   ├── validators/     # Validación de inputs
│   │   ├── utils/          # Utilidades
│   │   ├── types/          # Types
│   │   ├── config/         # Configuración
│   │   └── database/       # DB connection, migrations
│   │
│   └── tests/
│       ├── unit/
│       ├── integration/
│       └── e2e/
│
├── shared/ (si monorepo)
│   ├── types/              # Types compartidos
│   └── constants/          # Constantes compartidas
│
├── scripts/                # Scripts de utilidad
├── docs/                   # Documentación adicional
├── migrations/             # Database migrations
└── config/                 # Archivos de configuración
`

---

## Convenciones de Nombres

### Archivos

**Componentes React/Vue**:
- `PascalCase.tsx` o `PascalCase.vue`
- Ejemplo: `UserProfile.tsx`, `ProductCard.vue`

**Utilities, Services, Hooks**:
- `camelCase.ts`
- Ejemplo: `formatDate.ts`, `useAuth.ts`, `userService.ts`

**Constants**:
- `UPPER_SNAKE_CASE.ts`
- Ejemplo: `API_ENDPOINTS.ts`, `APP_CONFIG.ts`

**Tests**:
- Mismo nombre que archivo + `.test.ts` o `.spec.ts`
- Ejemplo: `UserProfile.test.tsx`, `formatDate.spec.ts`

**Styles**:
- CSS Modules: `[ComponentName].module.css`
- Regular CSS: `kebab-case.css`

### Directorios

- `kebab-case` o `camelCase` (consistente en todo el proyecto)
- Ejemplos: `user-profile/`, `auth-flow/`, o `userProfile/`, `authFlow/`

---

## Organización por Feature

Para features complejas, agrupa por funcionalidad:

```
src/components/UserManagement/
├── index.ts                  # Barrel export
├── UserList/
│   ├── UserList.tsx
│   ├── UserList.test.tsx
│   ├── UserListItem.tsx
│   └── styles.module.css
├── UserDetail/
│   ├── UserDetail.tsx
│   ├── UserForm.tsx
│   └── hooks/
│       └── useUserData.ts
└── shared/
    ├── types.ts
    └── utils.ts
```

---

## Imports

### Orden de Imports

```typescript
// 1. External libraries
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { z } from 'zod';

// 2. Internal aliased imports (@/)
import { Button } from '@/components/common';
import { useAuth } from '@/hooks';
import { API_ENDPOINTS } from '@/constants';

// 3. Relative imports
import { UserCard } from './UserCard';
import { formatDate } from './utils';
import styles from './styles.module.css';

// 4. Types (al final)
import type { User, UserRole } from '@/types';
```

### Path Aliases

Configurar en `tsconfig.json`:

```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"],
      "@components/*": ["src/components/*"],
      "@services/*": ["src/services/*"],
      "@utils/*": ["src/utils/*"],
      "@types/*": ["src/types/*"]
    }
  }
}
```

Usar así:
```typescript
// ✅ Bien
import { Button } from '@/components/common/Button';
import { formatDate } from '@/utils/date';

// ❌ Evitar
import { Button } from '../../../components/common/Button';
```

---

## Exports

### Barrel Exports

Crear `index.ts` en directorios para re-exportar:

```typescript
// components/common/index.ts
export { Button } from './Button';
export { Input } from './Input';
export { Modal } from './Modal';
export type { ButtonProps, InputProps, ModalProps } from './types';
```

Uso:
```typescript
import { Button, Input, Modal } from '@/components/common';
```

### Named Exports vs Default Exports

**Preferir Named Exports**:
```typescript
// ✅ Bien - Named export
export const UserProfile = () => { /* ... */ };

// ❌ Evitar - Default export
export default function UserProfile() { /* ... */ }
```

**Razón**: Named exports son más fáciles de refactorizar y buscar.

**Excepción**: Páginas/Rutas pueden usar default export si el framework lo requiere (Next.js, Create React App).

---

## Testing

### Ubicación de Tests

**Opción 1: Co-located** (preferido):
```
src/components/UserProfile/
├── UserProfile.tsx
├── UserProfile.test.tsx
└── UserProfile.module.css
```

**Opción 2: Separado**:
```
src/components/UserProfile/
└── UserProfile.tsx

tests/components/UserProfile/
└── UserProfile.test.tsx
```

### Nombres de Tests

```typescript
describe('UserProfile', () => {
  describe('rendering', () => {
    it('should render user name', () => {});
    it('should show loading state when loading', () => {});
  });
  
  describe('interactions', () => {
    it('should call onEdit when edit button is clicked', () => {});
  });
  
  describe('edge cases', () => {
    it('should handle missing user data gracefully', () => {});
  });
});
```

---

## Configuración

### Environment Variables

```
.env.example         # Template (commitear)
.env.development     # Dev (NO commitear)
.env.test           # Testing (NO commitear)
.env.production     # Prod (NO commitear)
```

**Nomenclatura**:
```bash
# Prefijo según contexto
NEXT_PUBLIC_API_URL=      # Frontend público (Next.js)
VITE_API_URL=             # Frontend público (Vite)
REACT_APP_API_URL=        # Frontend público (CRA)

API_SECRET_KEY=           # Backend privado
DATABASE_URL=             # Backend privado
```

### Archivos de Config

```
config/
├── default.ts           # Configuración por defecto
├── development.ts       # Overrides para dev
├── production.ts        # Overrides para prod
└── test.ts             # Overrides para testing
```

---

## Assets y Media

### Imágenes

```
assets/
├── images/
│   ├── logos/
│   │   ├── logo.svg
│   │   └── logo-dark.svg
│   ├── icons/           # Si no usas icon library
│   └── illustrations/
├── fonts/
└── videos/
```

**Optimización**:
- Usar formatos modernos (WebP para imágenes)
- Proveer múltiples tamaños para responsive
- Lazy load imágenes below the fold

---

## Database

### Migrations

```
migrations/
├── 20260109120000_create_users_table.sql
├── 20260109130000_add_indexes_to_users.sql
└── 20260110090000_create_orders_table.sql
```

**Nomenclatura**: `YYYYMMDDHHMMSS_description.sql`

### Seeds

```
seeds/
├── 01_users.sql
├── 02_products.sql
└── 03_orders.sql
```

---

## Scripts

```
scripts/
├── seed-database.ts       # Poblar DB con datos de prueba
├── generate-types.ts      # Generar tipos desde schema
├── backup-db.sh          # Backup de database
└── deploy.sh             # Script de deployment
```

---

## Documentation

```
docs/
├── api/                  # API documentation
│   └── openapi.yaml
├── architecture/         # Architecture diagrams
├── guides/              # Developer guides
└── decisions/           # ADRs (Architecture Decision Records)
    └── 001-use-postgresql.md
```

---

## Patterns y Anti-patterns

### ✅ Hacer

```typescript
// Organizar por feature, no por tipo
src/features/user-management/
├── components/
├── services/
├── hooks/
└── types.ts

// Tests junto al código
src/components/Button/
├── Button.tsx
└── Button.test.tsx

// Barrel exports para APIs limpias
src/utils/index.ts -> export { formatDate, parseDate };
```

### ❌ Evitar

```typescript
// Organizar solo por tipo técnico
src/
├── components/      // TODO mezclado
├── services/        // TODO mezclado
└── utils/          // TODO mezclado

// Tests lejos del código
src/components/Button.tsx
tests/unit/components/Button.test.tsx  // Difícil de mantener

// Imports profundos
import { something } from '../../../utils/formatters/date/format';
```

---

## Gitignore Essentials

```gitignore
# Dependencies
node_modules/
vendor/

# Environment
.env
.env.local
.env.*.local

# Build artifacts
build/
dist/
.next/
out/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Testing
coverage/
.nyc_output/

# Logs
logs/
*.log
npm-debug.log*

# Misc
.specs/features/*/     # Solo ejemplo en control de versiones
!.specs/features/example-feature/
```

---

## Notas para IA

**Al crear nuevos archivos**:

1. **Ubica según feature**: Pregunta si va en feature existente o nueva
2. **Sigue nomenclatura**: PascalCase para componentes, camelCase para utils
3. **Co-locate tests**: Test junto al código
4. **Usa path aliases**: No `../../../`, usa `@/`
5. **Barrel exports**: Si creas múltiples archivos relacionados, agrega `index.ts`

**Al sugerir reorganización**:
- Explica beneficios
- Muestra antes/después
- Lista archivos afectados
- Estima esfuerzo

**Ejemplo**:
```
Sugiero mover user-related components a su propia feature:

Antes:
src/components/UserList.tsx
src/components/UserDetail.tsx

Después:
src/features/users/
├── components/
│   ├── UserList.tsx
│   └── UserDetail.tsx
├── services/userService.ts
└── types.ts

Beneficios:
- Mejor encapsulación
- Más fácil encontrar código relacionado
- Preparado para extraer como módulo independiente

Archivos afectados: 12
Esfuerzo: ~1 hora
```

---

**Última actualización**: [YYYY-MM-DD]
