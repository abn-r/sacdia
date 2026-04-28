# SACDIA Docs — Fumadocs Documentation Site Design

## Overview

A documentation site for the SACDIA project built with Fumadocs (Next.js App Router). Two audience sections: public (club leaders/users) and development (engineering team).

**Repository**: https://github.com/abn-r/sacdia-docs.git
**Location in monorepo**: `/sacdia-docs/` (alongside sacdia-backend, sacdia-admin, sacdia-app)

## Decision

**Approach**: Fumadocs with `fumadocs-mdx` (Option A — file-based MDX content source)

**Why**: Simplest setup, well-documented, content lives as `.mdx` files in the repo. No external CMS or database needed. The team already works with git, so editing docs is natural. Scales to more features later if needed.

**Rejected alternatives**:
- Option B (fumadocs-core custom source): Overkill — runtime data sources not needed
- Option C (CMS headless): Unnecessary infrastructure for a git-native team

## Stack

| Technology | Version | Purpose |
|-----------|---------|---------|
| Next.js | Latest (App Router) | Framework |
| fumadocs-ui | Latest | Theme, layout components, search dialog |
| fumadocs-mdx | Latest | MDX content source provider |
| fumadocs-core | Latest | Search engine (Orama), loaders |
| @types/mdx | Latest | TypeScript MDX definitions |
| Tailwind CSS | v4 | Styling |
| Zod | (bundled) | Frontmatter schema validation |

**Runtime**: Node.js 22+

## Architecture

### Two Content Sections

| Section | URL Base | Audience | Content |
|---------|----------|----------|---------|
| Docs | `/docs` | Public (club leaders, users) | Usage guides, feature docs, onboarding |
| Dev | `/dev` | Development team | API reference, database schema, architecture decisions, coding standards |

Each section has its own:
- `defineDocs()` collection in `source.config.ts`
- `loader()` instance in `lib/source.ts`
- Route group with `DocsLayout` and catch-all page
- Sidebar navigation via `meta.json`
- Content directory under `content/`

### Project Structure

```
sacdia-docs/
├── source.config.ts              # Two collections: docs + dev
├── next.config.mjs               # createMDX plugin
├── tsconfig.json                 # Path alias: collections/* -> .source/*
├── .source/                      # Auto-generated (gitignored)
├── content/
│   ├── docs/                     # Public content
│   │   ├── meta.json             # Sidebar ordering
│   │   ├── index.mdx             # /docs landing
│   │   ├── getting-started/
│   │   │   ├── meta.json
│   │   │   └── index.mdx
│   │   ├── features/
│   │   │   ├── meta.json
│   │   │   └── index.mdx
│   │   └── guides/
│   │       ├── meta.json
│   │       └── index.mdx
│   └── dev/                      # Development content
│       ├── meta.json             # Sidebar ordering
│       ├── index.mdx             # /dev landing
│       ├── api/
│       │   ├── meta.json
│       │   └── index.mdx
│       ├── database/
│       │   ├── meta.json
│       │   └── index.mdx
│       ├── architecture/
│       │   ├── meta.json
│       │   └── index.mdx
│       └── standards/
│           ├── meta.json
│           └── index.mdx
├── lib/
│   ├── source.ts                 # Two loaders: docsSource + devSource
│   └── layout.shared.tsx         # Shared nav config (title, links)
├── components/
│   └── mdx.tsx                   # MDX component overrides
├── app/
│   ├── global.css                # Tailwind + SACDIA theme variables
│   ├── layout.tsx                # Root layout with RootProvider
│   ├── (home)/
│   │   ├── layout.tsx            # HomeLayout (navbar only)
│   │   └── page.tsx              # Landing page at /
│   ├── docs/
│   │   ├── layout.tsx            # DocsLayout with docsSource sidebar
│   │   └── [[...slug]]/
│   │       └── page.tsx          # Renders public docs MDX
│   ├── dev/
│   │   ├── layout.tsx            # DocsLayout with devSource sidebar
│   │   └── [[...slug]]/
│   │       └── page.tsx          # Renders dev docs MDX
│   └── api/
│       └── search/
│           └── route.ts          # Multi-source search endpoint
└── package.json
```

## Branding / Theme

Custom SACDIA brand colors applied via CSS variables:

| Color | Hex | CSS Variable | Usage |
|-------|-----|-------------|-------|
| sacRed | #F06151 | --color-fd-primary | Links, buttons, focus rings, primary actions |
| sacGreen | #4FBF9F | --color-fd-accent | Hover states, highlights, accent backgrounds |
| sacBlack | #183651 | --color-fd-foreground (light) / --color-fd-background (dark) | Text (light mode), background (dark mode) |
| sacWhite | #E1E6E7 | --color-fd-background (light) | Page background (light mode) |
| sacYellow | #FBBD5E | (reserved) | Available for future callouts/warnings |
| sacBlue | #2EA0DA | (reserved) | Available for future info elements |

Both light and dark mode supported with appropriate contrast.

## Frontmatter Schema

Extended Zod schema in `source.config.ts`:

```typescript
pageSchema.extend({
  author: z.string().optional(),
  version: z.string().default('1.0.0'),
})
```

Plus `lastModified` automatically from git history via `fumadocs-mdx/plugins/last-modified`.

Example frontmatter:
```yaml
---
title: Gestión de Clubes
description: Cómo administrar tu club en SACDIA
author: Abner Reyes
version: 1.0.0
---
```

## Search

- Engine: Orama (built into fumadocs-core), client-side
- Multi-source: indexes both `/docs` and `/dev` content with tags for filtering
- Trigger: Ctrl+K / Cmd+K
- Language: Spanish support
- API route: `app/api/search/route.ts` using `createSearchAPI('advanced', ...)`

## Initial Content

Placeholder pages to establish structure:

### Public (/docs)
- `index.mdx` — Welcome, what is SACDIA
- `getting-started/index.mdx` — Quick start for club leaders
- `features/index.mdx` — Feature overview placeholder

### Development (/dev)
- `index.mdx` — Stack overview, repo structure
- `api/index.mdx` — API reference placeholder
- `database/index.mdx` — Database schema placeholder
- `architecture/index.mdx` — Architecture decisions placeholder
- `standards/index.mdx` — Coding standards placeholder

## Git Integration

- `lastModified` plugin reads git history for automatic timestamps
- Displayed on each page via metadata
- Requires non-shallow clone (full git history)

## Deployment Considerations

- Static export compatible (SSG)
- Can deploy to Vercel, Cloudflare Pages, or similar
- Search works client-side (no server needed for search)
