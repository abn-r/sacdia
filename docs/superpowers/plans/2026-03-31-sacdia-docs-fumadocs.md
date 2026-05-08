# SACDIA Docs — Fumadocs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a documentation site for SACDIA using Fumadocs with two sections: public docs for club leaders and development docs for the engineering team.

**Architecture:** Next.js App Router + Fumadocs (fumadocs-ui, fumadocs-mdx, fumadocs-core). Two independent content sources (content/docs and content/dev) with separate route groups, custom SACDIA branding, multi-source search, git-based lastModified, and custom frontmatter (author, version).

**Tech Stack:** Next.js, Fumadocs, Tailwind CSS v4, Orama search, TypeScript

---

## Task 1: Clone repo and initialize Next.js project

**Files:** `sacdia-docs/package.json`, `sacdia-docs/.gitignore`, `sacdia-docs/tsconfig.json`

- [ ] **Step 1.1** — Clone the repository into the monorepo root:

```bash
cd /Users/abner/Documents/development/sacdia
git clone https://github.com/abn-r/sacdia-docs.git sacdia-docs
cd sacdia-docs
```

- [ ] **Step 1.2** — Initialize `package.json` with `pnpm init` and replace its contents with the following:

```json
{
  "name": "sacdia-docs",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "postinstall": "fumadocs-mdx"
  },
  "dependencies": {
    "fumadocs-core": "latest",
    "fumadocs-mdx": "latest",
    "fumadocs-ui": "latest",
    "next": "^15",
    "react": "^19",
    "react-dom": "^19"
  },
  "devDependencies": {
    "@tailwindcss/postcss": "^4",
    "@types/mdx": "^2",
    "@types/node": "^22",
    "@types/react": "^19",
    "@types/react-dom": "^19",
    "postcss": "^8",
    "tailwindcss": "^4",
    "typescript": "^5"
  }
}
```

- [ ] **Step 1.3** — Install all dependencies:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-docs
pnpm install
```

- [ ] **Step 1.4** — Create `tsconfig.json` at `sacdia-docs/tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "collections/*": ["./.source/*"],
      "@/*": ["./src/*"]
    }
  },
  "include": [
    "next-env.d.ts",
    "**/*.ts",
    "**/*.tsx",
    ".source/**/*.ts",
    ".source/**/*.tsx"
  ],
  "exclude": ["node_modules"]
}
```

- [ ] **Step 1.5** — Create `.gitignore` at `sacdia-docs/.gitignore`:

```
# dependencies
/node_modules
/.pnp
.pnp.js
.yarn/install-state.gz

# testing
/coverage

# next.js
/.next/
/out/

# production
/build

# misc
.DS_Store
*.pem

# debug
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# env files
.env*.local
.env

# vercel
.vercel

# typescript
*.tsbuildinfo
next-env.d.ts

# fumadocs
.source/
```

- [ ] **Step 1.6** — Commit the initial project scaffold:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-docs
git add package.json pnpm-lock.yaml tsconfig.json .gitignore
git commit -m "feat: initialize Next.js project with Fumadocs dependencies"
```

---

## Task 2: Core configuration files

**Files:** `sacdia-docs/source.config.ts`, `sacdia-docs/next.config.mjs`, `sacdia-docs/postcss.config.mjs`

- [ ] **Step 2.1** — Create `source.config.ts` at `sacdia-docs/source.config.ts`:

```ts
import { defineDocs, defineConfig } from 'fumadocs-mdx/config';
import { z } from 'zod';
import { pageSchema } from 'fumadocs-core/source/schema';
import lastModified from 'fumadocs-mdx/plugins/last-modified';

export const docs = defineDocs({
  dir: 'content/docs',
  docs: {
    schema: pageSchema.extend({
      author: z.string().optional(),
      version: z.string().default('1.0.0'),
    }),
  },
});

export const devDocs = defineDocs({
  dir: 'content/dev',
  docs: {
    schema: pageSchema.extend({
      author: z.string().optional(),
      version: z.string().default('1.0.0'),
    }),
  },
});

export default defineConfig({
  plugins: [lastModified()],
});
```

- [ ] **Step 2.2** — Create `next.config.mjs` at `sacdia-docs/next.config.mjs`:

```js
import { createMDX } from 'fumadocs-mdx/next';

/** @type {import('next').NextConfig} */
const config = {
  reactStrictMode: true,
};

const withMDX = createMDX();

export default withMDX(config);
```

- [ ] **Step 2.3** — Create `postcss.config.mjs` at `sacdia-docs/postcss.config.mjs`:

```js
/** @type {import('postcss').Config} */
const config = {
  plugins: {
    '@tailwindcss/postcss': {},
  },
};

export default config;
```

- [ ] **Step 2.4** — Commit configuration files:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-docs
git add source.config.ts next.config.mjs postcss.config.mjs
git commit -m "feat: add Fumadocs core configuration (source, next, postcss)"
```

---

## Task 3: App shell — root layout, global CSS, shared layout config

**Files:** `sacdia-docs/src/app/global.css`, `sacdia-docs/src/app/layout.tsx`, `sacdia-docs/src/lib/layout.shared.tsx`, `sacdia-docs/src/components/mdx.tsx`

- [ ] **Step 3.1** — Create `src/app/global.css` at `sacdia-docs/src/app/global.css`:

```css
@import 'tailwindcss';
@import 'fumadocs-ui/css/neutral.css';
@import 'fumadocs-ui/css/preset.css';

@theme {
  --color-fd-primary: #F06151;
  --color-fd-primary-foreground: #ffffff;
  --color-fd-background: #fafbfb;
  --color-fd-foreground: #183651;
  --color-fd-accent: rgba(79, 191, 159, 0.15);
  --color-fd-accent-foreground: #183651;
  --color-fd-muted: #e8eced;
  --color-fd-muted-foreground: rgba(24, 54, 81, 0.6);
  --color-fd-popover: #f0f3f4;
  --color-fd-popover-foreground: #183651;
  --color-fd-card: #f0f2f3;
  --color-fd-card-foreground: #183651;
  --color-fd-secondary: #e8eced;
  --color-fd-secondary-foreground: #183651;
  --color-fd-border: rgba(24, 54, 81, 0.12);
  --color-fd-ring: #F06151;
}

.dark {
  --color-fd-background: #0f1e2e;
  --color-fd-foreground: #E1E6E7;
  --color-fd-primary: #F06151;
  --color-fd-primary-foreground: #ffffff;
  --color-fd-accent: rgba(79, 191, 159, 0.15);
  --color-fd-accent-foreground: #E1E6E7;
  --color-fd-muted: #1a3450;
  --color-fd-muted-foreground: rgba(225, 230, 231, 0.6);
  --color-fd-popover: #152d48;
  --color-fd-popover-foreground: #E1E6E7;
  --color-fd-card: #132a44;
  --color-fd-card-foreground: #E1E6E7;
  --color-fd-secondary: #1a3450;
  --color-fd-secondary-foreground: #E1E6E7;
  --color-fd-border: rgba(225, 230, 231, 0.1);
  --color-fd-ring: #F06151;
}
```

- [ ] **Step 3.2** — Create `src/app/layout.tsx` at `sacdia-docs/src/app/layout.tsx`:

```tsx
import { RootProvider } from 'fumadocs-ui/provider/next';
import type { ReactNode } from 'react';
import './global.css';

export default function Layout({ children }: { children: ReactNode }) {
  return (
    <html lang="es" suppressHydrationWarning>
      <body className="flex flex-col min-h-screen">
        <RootProvider>{children}</RootProvider>
      </body>
    </html>
  );
}
```

- [ ] **Step 3.3** — Create `src/lib/layout.shared.tsx` at `sacdia-docs/src/lib/layout.shared.tsx`:

```tsx
import type { BaseLayoutProps } from 'fumadocs-ui/layouts/shared';

export function baseOptions(): BaseLayoutProps {
  return {
    nav: {
      title: 'SACDIA Docs',
    },
    githubUrl: 'https://github.com/abn-r/sacdia-docs',
    links: [
      { text: 'Documentación', url: '/docs' },
      { text: 'Desarrollo', url: '/dev' },
    ],
  };
}
```

- [ ] **Step 3.4** — Create `src/components/mdx.tsx` at `sacdia-docs/src/components/mdx.tsx`:

```tsx
import defaultMdxComponents from 'fumadocs-ui/mdx';
import type { MDXComponents } from 'mdx/types';

export function getMDXComponents(components?: MDXComponents) {
  return {
    ...defaultMdxComponents,
    ...components,
  } satisfies MDXComponents;
}

export const useMDXComponents = getMDXComponents;

declare global {
  type MDXProvidedComponents = ReturnType<typeof getMDXComponents>;
}
```

- [ ] **Step 3.5** — Commit app shell files:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-docs
git add src/app/global.css src/app/layout.tsx src/lib/layout.shared.tsx src/components/mdx.tsx
git commit -m "feat: add app shell with SACDIA theme, root layout, and MDX components"
```

---

## Task 4: Source loaders

**Files:** `sacdia-docs/src/lib/source.ts`

- [ ] **Step 4.1** — Create `src/lib/source.ts` at `sacdia-docs/src/lib/source.ts`:

```ts
import { docs, devDocs } from 'collections/server';
import { loader } from 'fumadocs-core/source';

export const docsSource = loader({
  baseUrl: '/docs',
  source: docs.toFumadocsSource(),
});

export const devSource = loader({
  baseUrl: '/dev',
  source: devDocs.toFumadocsSource(),
});
```

- [ ] **Step 4.2** — Commit source loaders:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-docs
git add src/lib/source.ts
git commit -m "feat: add dual source loaders for docs and dev content"
```

---

## Task 5: Landing page

**Files:** `sacdia-docs/src/app/(home)/layout.tsx`, `sacdia-docs/src/app/(home)/page.tsx`

- [ ] **Step 5.1** — Create `src/app/(home)/layout.tsx` at `sacdia-docs/src/app/(home)/layout.tsx`:

```tsx
import { HomeLayout } from 'fumadocs-ui/layouts/home';
import { baseOptions } from '@/lib/layout.shared';
import type { ReactNode } from 'react';

export default function Layout({ children }: { children: ReactNode }) {
  return <HomeLayout {...baseOptions()}>{children}</HomeLayout>;
}
```

- [ ] **Step 5.2** — Create `src/app/(home)/page.tsx` at `sacdia-docs/src/app/(home)/page.tsx`:

```tsx
import Link from 'next/link';

export default function HomePage() {
  return (
    <main className="flex flex-1 flex-col items-center justify-center text-center px-4 py-16">
      <h1 className="text-4xl font-bold mb-4 text-fd-foreground">
        SACDIA Docs
      </h1>
      <p className="text-fd-muted-foreground text-lg mb-8 max-w-xl">
        Documentación del Sistema de Administración de Clubes de
        Conquistadores, Aventureros y Guías Mayores
      </p>
      <div className="flex gap-4">
        <Link
          href="/docs"
          className="rounded-lg bg-fd-primary px-6 py-3 text-fd-primary-foreground font-medium hover:opacity-90 transition-opacity"
        >
          Documentación
        </Link>
        <Link
          href="/dev"
          className="rounded-lg border border-fd-border px-6 py-3 text-fd-foreground font-medium hover:bg-fd-accent transition-colors"
        >
          Desarrollo
        </Link>
      </div>
    </main>
  );
}
```

- [ ] **Step 5.3** — Commit landing page:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-docs
git add "src/app/(home)/layout.tsx" "src/app/(home)/page.tsx"
git commit -m "feat: add landing page with links to docs and dev sections"
```

---

## Task 6: Public docs route group

**Files:** `sacdia-docs/src/app/docs/layout.tsx`, `sacdia-docs/src/app/docs/[[...slug]]/page.tsx`

- [ ] **Step 6.1** — Create `src/app/docs/layout.tsx` at `sacdia-docs/src/app/docs/layout.tsx`:

```tsx
import { DocsLayout } from 'fumadocs-ui/layouts/docs';
import { baseOptions } from '@/lib/layout.shared';
import { docsSource } from '@/lib/source';
import type { ReactNode } from 'react';

export default function Layout({ children }: { children: ReactNode }) {
  return (
    <DocsLayout tree={docsSource.getPageTree()} {...baseOptions()}>
      {children}
    </DocsLayout>
  );
}
```

- [ ] **Step 6.2** — Create `src/app/docs/[[...slug]]/page.tsx` at `sacdia-docs/src/app/docs/[[...slug]]/page.tsx`:

```tsx
import { docsSource } from '@/lib/source';
import {
  DocsBody,
  DocsDescription,
  DocsPage,
  DocsTitle,
} from 'fumadocs-ui/layouts/docs/page';
import { notFound } from 'next/navigation';
import { getMDXComponents } from '@/components/mdx';
import { createRelativeLink } from 'fumadocs-ui/mdx';
import type { Metadata } from 'next';

export default async function Page(props: {
  params: Promise<{ slug?: string[] }>;
}) {
  const params = await props.params;
  const page = docsSource.getPage(params.slug);
  if (!page) notFound();

  const MDX = page.data.body;

  return (
    <DocsPage toc={page.data.toc} full={page.data.full}>
      <DocsTitle>{page.data.title}</DocsTitle>
      <DocsDescription>{page.data.description}</DocsDescription>
      <DocsBody>
        <MDX
          components={getMDXComponents({
            a: createRelativeLink(docsSource, page),
          })}
        />
      </DocsBody>
    </DocsPage>
  );
}

export async function generateStaticParams() {
  return docsSource.generateParams();
}

export async function generateMetadata(props: {
  params: Promise<{ slug?: string[] }>;
}): Promise<Metadata> {
  const params = await props.params;
  const page = docsSource.getPage(params.slug);
  if (!page) notFound();

  return {
    title: page.data.title,
    description: page.data.description,
  };
}
```

- [ ] **Step 6.3** — Commit public docs route group:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-docs
git add src/app/docs/layout.tsx "src/app/docs/[[...slug]]/page.tsx"
git commit -m "feat: add public docs route group with DocsLayout and dynamic page"
```

---

## Task 7: Dev docs route group

**Files:** `sacdia-docs/src/app/dev/layout.tsx`, `sacdia-docs/src/app/dev/[[...slug]]/page.tsx`

- [ ] **Step 7.1** — Create `src/app/dev/layout.tsx` at `sacdia-docs/src/app/dev/layout.tsx`:

```tsx
import { DocsLayout } from 'fumadocs-ui/layouts/docs';
import { baseOptions } from '@/lib/layout.shared';
import { devSource } from '@/lib/source';
import type { ReactNode } from 'react';

export default function Layout({ children }: { children: ReactNode }) {
  return (
    <DocsLayout tree={devSource.getPageTree()} {...baseOptions()}>
      {children}
    </DocsLayout>
  );
}
```

- [ ] **Step 7.2** — Create `src/app/dev/[[...slug]]/page.tsx` at `sacdia-docs/src/app/dev/[[...slug]]/page.tsx`:

```tsx
import { devSource } from '@/lib/source';
import {
  DocsBody,
  DocsDescription,
  DocsPage,
  DocsTitle,
} from 'fumadocs-ui/layouts/docs/page';
import { notFound } from 'next/navigation';
import { getMDXComponents } from '@/components/mdx';
import { createRelativeLink } from 'fumadocs-ui/mdx';
import type { Metadata } from 'next';

export default async function Page(props: {
  params: Promise<{ slug?: string[] }>;
}) {
  const params = await props.params;
  const page = devSource.getPage(params.slug);
  if (!page) notFound();

  const MDX = page.data.body;

  return (
    <DocsPage toc={page.data.toc} full={page.data.full}>
      <DocsTitle>{page.data.title}</DocsTitle>
      <DocsDescription>{page.data.description}</DocsDescription>
      <DocsBody>
        <MDX
          components={getMDXComponents({
            a: createRelativeLink(devSource, page),
          })}
        />
      </DocsBody>
    </DocsPage>
  );
}

export async function generateStaticParams() {
  return devSource.generateParams();
}

export async function generateMetadata(props: {
  params: Promise<{ slug?: string[] }>;
}): Promise<Metadata> {
  const params = await props.params;
  const page = devSource.getPage(params.slug);
  if (!page) notFound();

  return {
    title: page.data.title,
    description: page.data.description,
  };
}
```

- [ ] **Step 7.3** — Commit dev docs route group:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-docs
git add src/app/dev/layout.tsx "src/app/dev/[[...slug]]/page.tsx"
git commit -m "feat: add dev docs route group with DocsLayout and dynamic page"
```

---

## Task 8: Search API

**Files:** `sacdia-docs/src/app/api/search/route.ts`

- [ ] **Step 8.1** — Create `src/app/api/search/route.ts` at `sacdia-docs/src/app/api/search/route.ts`:

```ts
import { docsSource, devSource } from '@/lib/source';
import { createSearchAPI } from 'fumadocs-core/search/server';

export const { GET } = createSearchAPI('advanced', {
  indexes: [
    ...docsSource.getPages().map((page) => ({
      title: page.data.title,
      description: page.data.description,
      url: page.url,
      id: page.url,
      structuredData: page.data.structuredData,
      tag: 'docs',
    })),
    ...devSource.getPages().map((page) => ({
      title: page.data.title,
      description: page.data.description,
      url: page.url,
      id: page.url,
      structuredData: page.data.structuredData,
      tag: 'dev',
    })),
  ],
});
```

- [ ] **Step 8.2** — Commit search API:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-docs
git add src/app/api/search/route.ts
git commit -m "feat: add multi-source Orama search API for docs and dev"
```

---

## Task 9: Public content — docs section

**Files:** `sacdia-docs/content/docs/meta.json`, `sacdia-docs/content/docs/index.mdx`, `sacdia-docs/content/docs/getting-started/meta.json`, `sacdia-docs/content/docs/getting-started/index.mdx`, `sacdia-docs/content/docs/features/meta.json`, `sacdia-docs/content/docs/features/index.mdx`, `sacdia-docs/content/docs/guides/meta.json`, `sacdia-docs/content/docs/guides/index.mdx`

- [ ] **Step 9.1** — Create `content/docs/meta.json` at `sacdia-docs/content/docs/meta.json`:

```json
{
  "title": "Documentación",
  "pages": ["index", "getting-started", "features", "guides"]
}
```

- [ ] **Step 9.2** — Create `content/docs/index.mdx` at `sacdia-docs/content/docs/index.mdx`:

```mdx
---
title: Bienvenido a SACDIA
description: Documentación oficial del Sistema de Administración de Clubes JA
author: Abner Reyes
version: "1.0.0"
---

## ¿Qué es SACDIA?

SACDIA es el Sistema de Administración de Clubes de Conquistadores, Aventureros y Guías Mayores. Permite gestionar clubes, miembros, actividades, finanzas e inventario de manera centralizada.

## Secciones

- **Primeros Pasos** — Guía rápida para comenzar a usar SACDIA
- **Funcionalidades** — Descripción detallada de cada módulo
- **Guías** — Tutoriales paso a paso para tareas comunes
```

- [ ] **Step 9.3** — Create `content/docs/getting-started/meta.json` at `sacdia-docs/content/docs/getting-started/meta.json`:

```json
{
  "title": "Primeros Pasos",
  "pages": ["index"]
}
```

- [ ] **Step 9.4** — Create `content/docs/getting-started/index.mdx` at `sacdia-docs/content/docs/getting-started/index.mdx`:

```mdx
---
title: Primeros Pasos
description: Guía rápida para comenzar a usar SACDIA
author: Abner Reyes
version: "1.0.0"
---

## Comenzando con SACDIA

Bienvenido a SACDIA. Esta guía te ayudará a configurar tu club y empezar a gestionar tus miembros.

## Requisitos

- Acceso al panel de administración
- Credenciales de tu club asignadas por tu campo local

## Próximos pasos

Una vez que tengas acceso, podrás:
1. Registrar los miembros de tu club
2. Crear actividades y eventos
3. Gestionar el inventario
4. Administrar las finanzas
```

- [ ] **Step 9.5** — Create `content/docs/features/meta.json` at `sacdia-docs/content/docs/features/meta.json`:

```json
{
  "title": "Funcionalidades",
  "pages": ["index"]
}
```

- [ ] **Step 9.6** — Create `content/docs/features/index.mdx` at `sacdia-docs/content/docs/features/index.mdx`:

```mdx
---
title: Funcionalidades
description: Módulos y funcionalidades de SACDIA
author: Abner Reyes
version: "1.0.0"
---

## Módulos de SACDIA

SACDIA cuenta con los siguientes módulos principales:

### Gestión de Clubes
Administra la información básica de tu club, miembros y estructura organizativa.

### Actividades
Crea y gestiona actividades, eventos y campamentos.

### Finanzas
Lleva el control financiero de tu club con ingresos, egresos y reportes.

### Inventario
Gestiona el inventario de materiales y recursos de tu club.

### Especialidades (Honores)
Registra y da seguimiento al avance de los miembros en sus especialidades.
```

- [ ] **Step 9.7** — Create `content/docs/guides/meta.json` at `sacdia-docs/content/docs/guides/meta.json`:

```json
{
  "title": "Guías",
  "pages": ["index"]
}
```

- [ ] **Step 9.8** — Create `content/docs/guides/index.mdx` at `sacdia-docs/content/docs/guides/index.mdx`:

```mdx
---
title: Guías
description: Tutoriales y guías de uso de SACDIA
author: Abner Reyes
version: "1.0.0"
---

## Guías de Uso

Aquí encontrarás tutoriales paso a paso para las tareas más comunes en SACDIA.

### Guías disponibles

Las guías se irán agregando progresivamente. Próximamente:

- Cómo registrar un nuevo miembro
- Cómo crear una actividad
- Cómo gestionar las finanzas del club
```

- [ ] **Step 9.9** — Commit public docs content:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-docs
git add content/docs/
git commit -m "feat: add public docs content (index, getting-started, features, guides)"
```

---

## Task 10: Dev content — development section

**Files:** `sacdia-docs/content/dev/meta.json`, `sacdia-docs/content/dev/index.mdx`, `sacdia-docs/content/dev/api/meta.json`, `sacdia-docs/content/dev/api/index.mdx`, `sacdia-docs/content/dev/database/meta.json`, `sacdia-docs/content/dev/database/index.mdx`, `sacdia-docs/content/dev/architecture/meta.json`, `sacdia-docs/content/dev/architecture/index.mdx`, `sacdia-docs/content/dev/standards/meta.json`, `sacdia-docs/content/dev/standards/index.mdx`

- [ ] **Step 10.1** — Create `content/dev/meta.json` at `sacdia-docs/content/dev/meta.json`:

```json
{
  "title": "Desarrollo",
  "pages": ["index", "api", "database", "architecture", "standards"]
}
```

- [ ] **Step 10.2** — Create `content/dev/index.mdx` at `sacdia-docs/content/dev/index.mdx`:

```mdx
---
title: Documentación de Desarrollo
description: Guía técnica para el equipo de desarrollo de SACDIA
author: Abner Reyes
version: "1.0.0"
---

## Stack Tecnológico

| Componente | Tecnología |
|-----------|-----------|
| Backend | NestJS + Prisma |
| Admin Panel | Next.js + shadcn/ui |
| App Móvil | Flutter |
| Base de Datos | PostgreSQL (Neon) |
| Autenticación | Better Auth |
| Storage | Cloudflare R2 |

## Repositorios

- **sacdia-backend** — API REST
- **sacdia-admin** — Panel Web de Administración
- **sacdia-app** — Aplicación Móvil
- **sacdia-docs** — Este sitio de documentación

## Secciones

- **API Reference** — Documentación de la API REST
- **Base de Datos** — Schema y migraciones
- **Arquitectura** — Decisiones de diseño y arquitectura
- **Estándares** — Convenciones y estándares de código
```

- [ ] **Step 10.3** — Create `content/dev/api/meta.json` at `sacdia-docs/content/dev/api/meta.json`:

```json
{
  "title": "API Reference",
  "pages": ["index"]
}
```

- [ ] **Step 10.4** — Create `content/dev/api/index.mdx` at `sacdia-docs/content/dev/api/index.mdx`:

```mdx
---
title: API Reference
description: Documentación de la API REST de SACDIA
author: Abner Reyes
version: "1.0.0"
---

## API REST de SACDIA

La API de SACDIA está construida con NestJS y expone endpoints RESTful para todas las operaciones del sistema.

### Base URL

- **Desarrollo**: `http://localhost:3000`
- **Producción**: Configurado en variables de entorno

### Autenticación

Todos los endpoints (excepto `/auth/*`) requieren un JWT válido en el header `Authorization: Bearer <token>`.

### Documentación interactiva

La documentación Swagger está disponible en `/api` cuando el backend está corriendo en desarrollo.
```

- [ ] **Step 10.5** — Create `content/dev/database/meta.json` at `sacdia-docs/content/dev/database/meta.json`:

```json
{
  "title": "Base de Datos",
  "pages": ["index"]
}
```

- [ ] **Step 10.6** — Create `content/dev/database/index.mdx` at `sacdia-docs/content/dev/database/index.mdx`:

```mdx
---
title: Base de Datos
description: Schema y estructura de la base de datos de SACDIA
author: Abner Reyes
version: "1.0.0"
---

## Base de Datos

SACDIA utiliza PostgreSQL como base de datos, gestionada a través de Prisma ORM y alojada en Neon.

### Schema

El schema de Prisma es la fuente de verdad para la estructura de datos. Se encuentra en `sacdia-backend/prisma/schema.prisma`.

### Migraciones

Las migraciones se gestionan con Prisma Migrate. Cada cambio al schema requiere una nueva migración.
```

- [ ] **Step 10.7** — Create `content/dev/architecture/meta.json` at `sacdia-docs/content/dev/architecture/meta.json`:

```json
{
  "title": "Arquitectura",
  "pages": ["index"]
}
```

- [ ] **Step 10.8** — Create `content/dev/architecture/index.mdx` at `sacdia-docs/content/dev/architecture/index.mdx`:

```mdx
---
title: Arquitectura
description: Decisiones de arquitectura y diseño de SACDIA
author: Abner Reyes
version: "1.0.0"
---

## Arquitectura de SACDIA

### Visión General

SACDIA sigue una arquitectura de monorepo con tres aplicaciones principales que comparten una API REST centralizada.

### Decisiones Clave

- **Autenticación**: Better Auth self-hosted con JWT HS256
- **RBAC**: Roles globales + roles por club
- **Storage**: Cloudflare R2 para archivos y medios
- **Base de datos**: PostgreSQL en Neon con Prisma ORM
```

- [ ] **Step 10.9** — Create `content/dev/standards/meta.json` at `sacdia-docs/content/dev/standards/meta.json`:

```json
{
  "title": "Estándares",
  "pages": ["index"]
}
```

- [ ] **Step 10.10** — Create `content/dev/standards/index.mdx` at `sacdia-docs/content/dev/standards/index.mdx`:

```mdx
---
title: Estándares de Código
description: Convenciones y estándares del equipo de desarrollo
author: Abner Reyes
version: "1.0.0"
---

## Estándares de Código

### Commits

Usamos Conventional Commits:
- `feat:` — Nueva funcionalidad
- `fix:` — Corrección de bug
- `docs:` — Documentación
- `refactor:` — Refactorización
- `test:` — Tests

### Naming

- **TypeScript/Dart**: camelCase
- **SQL**: snake_case
- **Componentes React**: PascalCase
- **Archivos**: kebab-case

### Async

Siempre usar `async/await`, nunca `.then()` chains.
```

- [ ] **Step 10.11** — Commit dev content:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-docs
git add content/dev/
git commit -m "feat: add dev docs content (index, api, database, architecture, standards)"
```

---

## Task 11: Verify — run dev server and test

**Files:** None (verification only)

- [ ] **Step 11.1** — Run the fumadocs-mdx postinstall to generate the `.source` directory:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-docs
pnpm fumadocs-mdx
```

- [ ] **Step 11.2** — Start the dev server and verify it compiles without errors:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-docs
pnpm dev
```

- [ ] **Step 11.3** — Verify the following routes load correctly in the browser:

  - `http://localhost:3000` — Landing page with "Documentación" and "Desarrollo" buttons
  - `http://localhost:3000/docs` — Public docs index page ("Bienvenido a SACDIA")
  - `http://localhost:3000/docs/getting-started` — Getting started page
  - `http://localhost:3000/docs/features` — Features page
  - `http://localhost:3000/docs/guides` — Guides page
  - `http://localhost:3000/dev` — Dev docs index page ("Documentación de Desarrollo")
  - `http://localhost:3000/dev/api` — API reference page
  - `http://localhost:3000/dev/database` — Database page
  - `http://localhost:3000/dev/architecture` — Architecture page
  - `http://localhost:3000/dev/standards` — Standards page

- [ ] **Step 11.4** — Verify search works: click the search bar (or press Ctrl+K / Cmd+K) and search for "SACDIA". Results from both docs and dev sections should appear.

- [ ] **Step 11.5** — Verify dark mode: toggle the theme switcher. Both light and dark themes should use SACDIA brand colors (red primary #F06151, dark blue foreground #183651).

- [ ] **Step 11.6** — Verify sidebar navigation: in both `/docs` and `/dev`, the sidebar should show the section structure defined in `meta.json` files.

- [ ] **Step 11.7** — If any fixes are needed, apply them and commit:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-docs
git add -A
git commit -m "fix: resolve issues found during verification"
```

- [ ] **Step 11.8** — Push the completed project to the remote:

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-docs
git push -u origin main
```
