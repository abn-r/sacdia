# Camporee Timeline Admin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port the Variant K · Timeline redesign into `sacdia-admin` as a mock-data prototype that replaces the current Eventos tab in the camporee detail page.

**Architecture:** Copy the existing redesign components from `~/Downloads/admin - camporee/camporees-admin/src/` into `sacdia-admin`, place under `lib/camporee-timeline/` and `components/camporee-events/timeline/`, add new design tokens to `globals.css`, ensure `badge.tsx` has soft-* variants, then rewrite `camporee-events-tab.tsx` to render `<EventsTimelineView />` with a parameterized mock builder.

**Tech Stack:** Next.js 16 (App Router), React 19, TypeScript, Tailwind CSS v4 (`@theme inline`), shadcn/ui (new-york), Radix UI, lucide-react.

**Spec:** `docs/superpowers/specs/2026-05-20-camporee-timeline-admin-design.md`

**Source mockup:** `~/Downloads/admin - camporee/camporees-admin/src/`

**Out of scope:** backend, server actions, real filtering, persistence, automated tests (per spec §12). Verification = `pnpm lint` + manual browser checks.

---

## Task 1: Inspect current `globals.css` and `badge.tsx`

**Files:**
- Read: `sacdia-admin/src/app/globals.css`
- Read: `sacdia-admin/src/components/ui/badge.tsx`

- [ ] **Step 1: Read both files**

```bash
bat sacdia-admin/src/app/globals.css | head -200
bat sacdia-admin/src/components/ui/badge.tsx
```

Expected: see the `:root` block, the `.dark` block, the `@theme inline` block in `globals.css`; see the CVA variant list in `badge.tsx`.

- [ ] **Step 2: Record findings**

Note in scratchpad:
- Existing tokens in `:root` (look for `--primary`, `--muted`, `--warning`, etc.).
- Existing tokens in `.dark`.
- Existing `@theme inline` mappings (`--color-primary`, etc.).
- Existing badge variants in CVA (look for `success`, `destructive`, `warning`, `soft-*`).

If `soft-info`, `soft-success`, `soft-warning`, `soft-destructive` are absent, Task 3 adds them. If present, Task 3 is a no-op verification.

- [ ] **Step 3: No commit (read-only task)**

---

## Task 2: Add design tokens to `globals.css`

**Files:**
- Modify: `sacdia-admin/src/app/globals.css`

- [ ] **Step 1: Add `cat-*`, `section-*`, and `warning-soft` tokens to `:root`**

Insert after the last existing semantic token in the `:root` block:

```css
  /* Camporee timeline — category colors */
  --cat-espiritual: oklch(0.62 0.18 285);
  --cat-competencia: oklch(0.66 0.21 42);
  --cat-taller: oklch(0.62 0.15 200);
  --cat-ceremonial: oklch(0.58 0.18 350);
  --cat-social: oklch(0.66 0.18 140);

  /* Camporee timeline — section colors */
  --section-aventureros: oklch(0.66 0.18 60);
  --section-conquistadores: oklch(0.55 0.20 260);
  --section-guias: oklch(0.55 0.18 25);

  /* Soft warning surface */
  --warning-soft: oklch(0.95 0.05 85);
  --warning-soft-foreground: oklch(0.40 0.15 60);
```

- [ ] **Step 2: Add same tokens to `.dark` with adjusted luminosity**

Insert in the `.dark` block:

```css
  /* Camporee timeline — category colors (dark) */
  --cat-espiritual: oklch(0.70 0.18 285);
  --cat-competencia: oklch(0.74 0.21 42);
  --cat-taller: oklch(0.70 0.15 200);
  --cat-ceremonial: oklch(0.66 0.18 350);
  --cat-social: oklch(0.74 0.18 140);

  /* Camporee timeline — section colors (dark) */
  --section-aventureros: oklch(0.74 0.18 60);
  --section-conquistadores: oklch(0.65 0.20 260);
  --section-guias: oklch(0.65 0.18 25);

  /* Soft warning surface (dark) */
  --warning-soft: oklch(0.32 0.08 85);
  --warning-soft-foreground: oklch(0.88 0.10 70);
```

- [ ] **Step 3: Add mappings to `@theme inline`**

Insert in the `@theme inline` block, alongside other `--color-*` lines:

```css
  --color-cat-espiritual: var(--cat-espiritual);
  --color-cat-competencia: var(--cat-competencia);
  --color-cat-taller: var(--cat-taller);
  --color-cat-ceremonial: var(--cat-ceremonial);
  --color-cat-social: var(--cat-social);
  --color-section-aventureros: var(--section-aventureros);
  --color-section-conquistadores: var(--section-conquistadores);
  --color-section-guias: var(--section-guias);
  --color-warning-soft: var(--warning-soft);
  --color-warning-soft-foreground: var(--warning-soft-foreground);
```

- [ ] **Step 4: Verify file compiles**

```bash
cd sacdia-admin && pnpm lint --max-warnings=0
```

Expected: no new errors related to `globals.css`. CSS files are not linted by ESLint but `next.config.js` may flag PostCSS issues at build. If lint passes, OK.

- [ ] **Step 5: Commit**

```bash
git -C sacdia-admin add src/app/globals.css
git -C sacdia-admin commit -m "feat(admin): add camporee timeline design tokens"
```

---

## Task 3: Ensure `badge.tsx` has `soft-*` variants

**Files:**
- Modify (if missing variants): `sacdia-admin/src/components/ui/badge.tsx`

- [ ] **Step 1: Check if variants already exist**

```bash
rg "soft-info|soft-success|soft-warning|soft-destructive" sacdia-admin/src/components/ui/badge.tsx
```

If all four match → skip to Step 4 (no commit). If any missing, continue.

- [ ] **Step 2: Add missing variants to the CVA block**

Locate the `variant:` object in `badgeVariants = cva(...)`. Add the following entries (only those that are missing):

```ts
"soft-info":
  "border-transparent bg-primary/10 text-primary",
"soft-success":
  "border-transparent bg-success/10 text-success",
"soft-warning":
  "border-transparent bg-warning-soft text-warning-soft-foreground",
"soft-destructive":
  "border-transparent bg-destructive/10 text-destructive",
```

If the file uses a different success/warning token naming (e.g. `text-success-foreground`), match the existing convention used by `success` and `destructive` variants in the same file.

- [ ] **Step 3: Update the `VariantProps` type if it is explicit**

If the file exports a manual `BadgeVariant` union type, add the four new keys. If it uses `VariantProps<typeof badgeVariants>`, no change needed.

- [ ] **Step 4: Run lint**

```bash
cd sacdia-admin && pnpm lint --max-warnings=0
```

Expected: passes.

- [ ] **Step 5: Commit (only if changed)**

```bash
git -C sacdia-admin add src/components/ui/badge.tsx
git -C sacdia-admin commit -m "feat(admin): add soft-* badge variants for timeline status"
```

---

## Task 4: Create `lib/camporee-timeline/types.ts`

**Files:**
- Create: `sacdia-admin/src/lib/camporee-timeline/types.ts`

- [ ] **Step 1: Write the file**

```ts
export type Section = "Aventureros" | "Conquistadores" | "Guías Mayores";

export type EventCategoryId =
  | "espiritual"
  | "competencia"
  | "taller"
  | "ceremonial"
  | "social"
  | "logistico";

export type EventStatus =
  | "programado"
  | "publicado"
  | "curso"
  | "realizado"
  | "cancelado";

export type TemplateScope = "union" | "local_field";

export type CamporeeType = "union" | "local";

export interface Venue {
  id: string;
  name: string;
  capacity: number;
}

export interface CamporeeDay {
  id: string;
  numero: number;
  fecha: string;
  diaSemana: string;
  fechaFmt: string;
}

export interface EventTemplate {
  id: string;
  title: string;
  description: string;
  category: EventCategoryId;
  scope: TemplateScope;
  scopeId: string;
  durationMin: number;
  sections: Section[];
  defaultPoints?: number;
  defaultCapacity?: number;
  createdBy: string;
  uses: number;
  lastUsedAt?: string;
  lastUsedAtCamporee?: string;
}

export interface CamporeeEvent {
  id: string;
  camporeeId: string;
  templateId: string | null;
  title: string;
  description: string;
  category: EventCategoryId;
  dayNumber: number;
  startsAt: string;
  endsAt: string;
  venueId: string;
  leaderName: string;
  leaderRole?: string;
  sections: Section[];
  capacity: number;
  registered: number;
  points: number;
  status: EventStatus;
  fromCatalog: boolean;
}

export interface CamporeeEventsData {
  camporeeId: string;
  camporeeType: CamporeeType;
  unionName: string;
  localFieldName?: string;
  days: CamporeeDay[];
  venues: Venue[];
  events: CamporeeEvent[];
  templates: EventTemplate[];
  summary: {
    total: number;
    published: number;
    cancelled: number;
    venuesUsed: number;
    hoursOfContent: number;
    fromCatalog: number;
    new: number;
  };
}
```

- [ ] **Step 2: Verify typecheck via lint**

```bash
cd sacdia-admin && pnpm lint --max-warnings=0
```

Expected: passes.

- [ ] **Step 3: Commit**

```bash
git -C sacdia-admin add src/lib/camporee-timeline/types.ts
git -C sacdia-admin commit -m "feat(admin): add camporee timeline domain types"
```

---

## Task 5: Create `lib/camporee-timeline/event-categories.ts`

**Files:**
- Create: `sacdia-admin/src/lib/camporee-timeline/event-categories.ts`

- [ ] **Step 1: Write the file**

```ts
import type { EventCategoryId, EventStatus } from "./types";

export interface EventCategoryDef {
  id: EventCategoryId;
  label: string;
  tint: string;
  dot: string;
  border: string;
}

export const EVENT_CATEGORIES: EventCategoryDef[] = [
  { id: "espiritual",  label: "Espiritual",  tint: "bg-cat-espiritual/15 text-cat-espiritual",   dot: "bg-cat-espiritual",   border: "border-cat-espiritual" },
  { id: "competencia", label: "Competencia", tint: "bg-cat-competencia/15 text-cat-competencia", dot: "bg-cat-competencia",  border: "border-cat-competencia" },
  { id: "taller",      label: "Taller",      tint: "bg-cat-taller/15 text-cat-taller",           dot: "bg-cat-taller",       border: "border-cat-taller" },
  { id: "ceremonial",  label: "Ceremonial",  tint: "bg-cat-ceremonial/15 text-cat-ceremonial",   dot: "bg-cat-ceremonial",   border: "border-cat-ceremonial" },
  { id: "social",      label: "Social",      tint: "bg-cat-social/15 text-cat-social",           dot: "bg-cat-social",       border: "border-cat-social" },
  { id: "logistico",   label: "Logístico",   tint: "bg-muted text-muted-foreground",             dot: "bg-muted-foreground", border: "border-muted-foreground" },
];

export const EVENT_CATEGORY_MAP = Object.fromEntries(
  EVENT_CATEGORIES.map((c) => [c.id, c]),
) as Record<EventCategoryId, EventCategoryDef>;

export const EVENT_STATUS_LABEL: Record<EventStatus, string> = {
  programado: "Programado",
  publicado: "Publicado",
  curso: "En curso",
  realizado: "Realizado",
  cancelado: "Cancelado",
};

export const EVENT_STATUS_VARIANT: Record<
  EventStatus,
  "outline" | "soft-success" | "soft-warning" | "soft-destructive" | "soft-info"
> = {
  programado: "outline",
  publicado: "soft-info",
  curso: "soft-warning",
  realizado: "soft-success",
  cancelado: "soft-destructive",
};

export const SECTION_COLOR: Record<string, { tint: string; dot: string }> = {
  Aventureros:    { tint: "bg-section-aventureros/15 text-section-aventureros",       dot: "bg-section-aventureros" },
  Conquistadores: { tint: "bg-section-conquistadores/15 text-section-conquistadores", dot: "bg-section-conquistadores" },
  "Guías Mayores": { tint: "bg-section-guias/15 text-section-guias",                  dot: "bg-section-guias" },
};
```

- [ ] **Step 2: Lint**

```bash
cd sacdia-admin && pnpm lint --max-warnings=0
```

Expected: passes.

- [ ] **Step 3: Commit**

```bash
git -C sacdia-admin add src/lib/camporee-timeline/event-categories.ts
git -C sacdia-admin commit -m "feat(admin): add camporee timeline category catalog"
```

---

## Task 6: Create `lib/camporee-timeline/helpers.ts`

**Files:**
- Create: `sacdia-admin/src/lib/camporee-timeline/helpers.ts`

- [ ] **Step 1: Write the file**

```ts
import type { CamporeeEvent } from "./types";

export const toMin = (hhmm: string): number => {
  const [h, m] = hhmm.split(":").map(Number);
  return h * 60 + m;
};

export const durMin = (start: string, end: string): number =>
  toMin(end) - toMin(start);

export const initials = (name: string): string =>
  name
    .split(" ")
    .filter((w) => w[0] && w[0] === w[0].toUpperCase())
    .slice(0, 2)
    .map((w) => w[0])
    .join("")
    .toUpperCase() || name.slice(0, 2).toUpperCase();

export const sortByStart = (a: CamporeeEvent, b: CamporeeEvent): number =>
  toMin(a.startsAt) - toMin(b.startsAt);

export const formatHours = (minutes: number): string => (minutes / 60).toFixed(1);
```

- [ ] **Step 2: Lint**

```bash
cd sacdia-admin && pnpm lint --max-warnings=0
```

Expected: passes.

- [ ] **Step 3: Commit**

```bash
git -C sacdia-admin add src/lib/camporee-timeline/helpers.ts
git -C sacdia-admin commit -m "feat(admin): add camporee timeline helpers"
```

---

## Task 7: Create `lib/camporee-timeline/mock-data.ts`

**Files:**
- Create: `sacdia-admin/src/lib/camporee-timeline/mock-data.ts`

- [ ] **Step 1: Write the file**

```ts
import { durMin } from "./helpers";
import type {
  CamporeeEventsData,
  CamporeeType,
  CamporeeEvent,
  EventTemplate,
} from "./types";

export interface BuildMockArgs {
  camporeeId: string;
  camporeeType: CamporeeType;
  unionName: string;
  localFieldName?: string;
  startDate?: string;
}

const DAY_NAMES_ES = ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"];
const MONTHS_ES = ["ene","feb","mar","abr","may","jun","jul","ago","sep","oct","nov","dic"];

function formatDayShort(d: Date): string {
  return `${d.getDate()} ${MONTHS_ES[d.getMonth()]}`;
}

const VENUES = [
  { id: "v1", name: "Anfiteatro Central",   capacity: 1500 },
  { id: "v2", name: "Cancha A — Atletismo", capacity: 600 },
  { id: "v3", name: "Cancha B — Voleibol",  capacity: 400 },
  { id: "v4", name: "Bosque Norte",         capacity: 300 },
  { id: "v5", name: "Aula Múltiple 1",      capacity: 80 },
  { id: "v6", name: "Aula Múltiple 2",      capacity: 80 },
  { id: "v7", name: "Salón Comedor",        capacity: 1200 },
  { id: "v8", name: "Plaza de Banderas",    capacity: 1500 },
];

const EVENTS_TEMPLATE: Omit<CamporeeEvent, "camporeeId">[] = [
  // Day 1
  { id: "e01", templateId: "t22", title: "Recepción y registro de clubes",
    description: "Entrega de credenciales, kits y asignación de campamento.",
    category: "logistico", dayNumber: 1, startsAt: "14:00", endsAt: "16:00",
    venueId: "v8", leaderName: "Pedro Vázquez", leaderRole: "Director de logística",
    sections: ["Aventureros", "Conquistadores", "Guías Mayores"],
    capacity: 1500, registered: 0, points: 0, status: "publicado", fromCatalog: true },
  { id: "e02", templateId: "t14", title: "Ceremonia de apertura",
    description: "Izamiento de banderas, presentación de autoridades.",
    category: "ceremonial", dayNumber: 1, startsAt: "18:00", endsAt: "19:30",
    venueId: "v1", leaderName: "Lucía Ortiz", leaderRole: "Coordinación",
    sections: ["Aventureros", "Conquistadores", "Guías Mayores"],
    capacity: 1500, registered: 0, points: 0, status: "publicado", fromCatalog: true },
  { id: "e03", templateId: null, title: "Devoción inaugural · 'Raíces que florecen'",
    description: "Mensaje inaugural y oración pastoral.",
    category: "espiritual", dayNumber: 1, startsAt: "20:00", endsAt: "21:30",
    venueId: "v1", leaderName: "Pr. Joaquín Mendoza", leaderRole: "Pastor",
    sections: ["Aventureros", "Conquistadores", "Guías Mayores"],
    capacity: 1500, registered: 0, points: 0, status: "publicado", fromCatalog: false },
  // Day 2
  { id: "e04", templateId: "t20", title: "Aerobics matutino",
    description: "Activación física antes del desayuno.",
    category: "social", dayNumber: 2, startsAt: "06:00", endsAt: "06:45",
    venueId: "v2", leaderName: "Karla Soto", leaderRole: "Líder deportes",
    sections: ["Conquistadores", "Guías Mayores"],
    capacity: 600, registered: 412, points: 5, status: "publicado", fromCatalog: true },
  { id: "e05", templateId: "t01", title: "Competencia de nudos y amarres",
    description: "10 nudos cronometrados + amarre cuadrado en equipos de 4.",
    category: "competencia", dayNumber: 2, startsAt: "09:00", endsAt: "11:30",
    venueId: "v4", leaderName: "Erick Mora", leaderRole: "Juez de torneo",
    sections: ["Conquistadores"],
    capacity: 200, registered: 168, points: 50, status: "publicado", fromCatalog: true },
  { id: "e06", templateId: "t10", title: "Especialidad: Aves silvestres",
    description: "Taller con observación de campo en el Bosque Norte.",
    category: "taller", dayNumber: 2, startsAt: "09:00", endsAt: "10:30",
    venueId: "v5", leaderName: "Mtra. Diana Báez", leaderRole: "Instructora",
    sections: ["Conquistadores", "Guías Mayores"],
    capacity: 60, registered: 58, points: 20, status: "publicado", fromCatalog: true },
  { id: "e07", templateId: "t04", title: "Mini-olimpiadas aventureras",
    description: "Estaciones de juegos coordinados, no competitivos.",
    category: "competencia", dayNumber: 2, startsAt: "09:00", endsAt: "11:00",
    venueId: "v3", leaderName: "Lupita Cruz", leaderRole: "Coordinadora",
    sections: ["Aventureros"],
    capacity: 250, registered: 178, points: 30, status: "publicado", fromCatalog: true },
  { id: "e08", templateId: null, title: "Atletismo · Carrera de relevos",
    description: "4x100 por club. Clasificatorias y final.",
    category: "competencia", dayNumber: 2, startsAt: "14:30", endsAt: "16:00",
    venueId: "v2", leaderName: "Jorge Ruiz", leaderRole: "Entrenador",
    sections: ["Conquistadores"],
    capacity: 600, registered: 320, points: 40, status: "publicado", fromCatalog: false },
  { id: "e09", templateId: null, title: "Conferencia GM · Liderazgo",
    description: "Liderazgo de servicio en el club.",
    category: "espiritual", dayNumber: 2, startsAt: "17:00", endsAt: "18:30",
    venueId: "v6", leaderName: "Pr. Joaquín Mendoza", leaderRole: "Pastor",
    sections: ["Guías Mayores"],
    capacity: 80, registered: 72, points: 15, status: "publicado", fromCatalog: false },
  { id: "e10", templateId: "t18", title: "Fogata bíblica",
    description: "Cánticos, testimonios y reflexión nocturna.",
    category: "social", dayNumber: 2, startsAt: "20:00", endsAt: "22:00",
    venueId: "v8", leaderName: "Sofía Martín", leaderRole: "Líder GM",
    sections: ["Aventureros", "Conquistadores", "Guías Mayores"],
    capacity: 1500, registered: 0, points: 0, status: "programado", fromCatalog: true },
  // Day 3
  { id: "e11", templateId: "t02", title: "Orden cerrado",
    description: "Evaluación por jueces certificados. 12 movimientos.",
    category: "competencia", dayNumber: 3, startsAt: "08:30", endsAt: "10:30",
    venueId: "v8", leaderName: "Cap. Raúl Vega", leaderRole: "Juez principal",
    sections: ["Conquistadores", "Guías Mayores"],
    capacity: 800, registered: 542, points: 60, status: "publicado", fromCatalog: true },
  { id: "e12", templateId: "t12", title: "Taller: Manualidades pioneras",
    description: "Construcción guiada con materiales naturales.",
    category: "taller", dayNumber: 3, startsAt: "08:30", endsAt: "10:00",
    venueId: "v5", leaderName: "Beatriz Ríos", leaderRole: "Instructora",
    sections: ["Aventureros"],
    capacity: 80, registered: 64, points: 10, status: "publicado", fromCatalog: true },
  { id: "e13", templateId: "t03", title: "Primeros auxilios — práctica",
    description: "RCP, vendajes, inmovilizaciones. Equipos de 5.",
    category: "competencia", dayNumber: 3, startsAt: "11:00", endsAt: "12:30",
    venueId: "v3", leaderName: "Dra. Sofía Martín", leaderRole: "Médica",
    sections: ["Conquistadores", "Guías Mayores"],
    capacity: 400, registered: 280, points: 50, status: "publicado", fromCatalog: true },
  { id: "e14", templateId: "t07", title: "Hora del hogar",
    description: "Apertura del sábado con cantos y devoción.",
    category: "espiritual", dayNumber: 3, startsAt: "16:00", endsAt: "17:30",
    venueId: "v1", leaderName: "Pr. Joaquín Mendoza", leaderRole: "Pastor",
    sections: ["Aventureros", "Conquistadores", "Guías Mayores"],
    capacity: 1500, registered: 0, points: 0, status: "publicado", fromCatalog: true },
  { id: "e15", templateId: null, title: "Vigilia y ofrenda",
    description: "Servicio especial nocturno.",
    category: "espiritual", dayNumber: 3, startsAt: "19:00", endsAt: "21:00",
    venueId: "v1", leaderName: "Lucía Ortiz", leaderRole: "Coordinación",
    sections: ["Conquistadores", "Guías Mayores"],
    capacity: 1500, registered: 0, points: 0, status: "programado", fromCatalog: false },
  // Day 4
  { id: "e16", templateId: "t09", title: "Escuela Sabática general",
    description: "Clase plenaria con dramatización.",
    category: "espiritual", dayNumber: 4, startsAt: "09:00", endsAt: "11:00",
    venueId: "v1", leaderName: "Pr. Iván Cortés", leaderRole: "Pastor",
    sections: ["Aventureros", "Conquistadores", "Guías Mayores"],
    capacity: 1500, registered: 0, points: 0, status: "publicado", fromCatalog: true },
  { id: "e17", templateId: "t06", title: "Sermón principal",
    description: "Mensaje central del camporee.",
    category: "espiritual", dayNumber: 4, startsAt: "11:30", endsAt: "12:45",
    venueId: "v1", leaderName: "Pr. Joaquín Mendoza", leaderRole: "Pastor",
    sections: ["Aventureros", "Conquistadores", "Guías Mayores"],
    capacity: 1500, registered: 0, points: 0, status: "publicado", fromCatalog: true },
  { id: "e18", templateId: "t17", title: "Bautismos al aire libre",
    description: "Ceremonia de bautismo. Asistencia abierta a los clubes.",
    category: "ceremonial", dayNumber: 4, startsAt: "16:00", endsAt: "18:00",
    venueId: "v4", leaderName: "Pr. Iván Cortés", leaderRole: "Pastor",
    sections: ["Conquistadores", "Guías Mayores"],
    capacity: 500, registered: 22, points: 0, status: "programado", fromCatalog: true },
  { id: "e19", templateId: "t19", title: "Concurso de talentos",
    description: "Cada club presenta un número de hasta 6 minutos.",
    category: "social", dayNumber: 4, startsAt: "19:00", endsAt: "21:30",
    venueId: "v1", leaderName: "Norma Olvera", leaderRole: "MC",
    sections: ["Aventureros", "Conquistadores", "Guías Mayores"],
    capacity: 1500, registered: 412, points: 25, status: "publicado", fromCatalog: true },
  // Day 5
  { id: "e20", templateId: "t05", title: "Gran carrera de obstáculos",
    description: "Circuito de 12 estaciones. Final del torneo.",
    category: "competencia", dayNumber: 5, startsAt: "08:00", endsAt: "10:30",
    venueId: "v4", leaderName: "Cap. Raúl Vega", leaderRole: "Juez principal",
    sections: ["Conquistadores"],
    capacity: 600, registered: 488, points: 80, status: "publicado", fromCatalog: true },
  { id: "e21", templateId: "t16", title: "Investidura de Guías Mayores",
    description: "Ceremonia de investidura para 14 candidatos.",
    category: "ceremonial", dayNumber: 5, startsAt: "11:00", endsAt: "12:30",
    venueId: "v1", leaderName: "Pr. Joaquín Mendoza", leaderRole: "Pastor",
    sections: ["Guías Mayores"],
    capacity: 1500, registered: 14, points: 0, status: "programado", fromCatalog: true },
  { id: "e22", templateId: "t15", title: "Premiación y clausura",
    description: "Entrega de trofeos y palabras de despedida.",
    category: "ceremonial", dayNumber: 5, startsAt: "15:00", endsAt: "16:30",
    venueId: "v1", leaderName: "Lucía Ortiz", leaderRole: "Coordinación",
    sections: ["Aventureros", "Conquistadores", "Guías Mayores"],
    capacity: 1500, registered: 0, points: 0, status: "programado", fromCatalog: true },
];

const TEMPLATES: EventTemplate[] = [
  { id: "t01", title: "Competencia de nudos y amarres", description: "10 nudos cronometrados + amarre cuadrado.",
    category: "competencia", scope: "union", scopeId: "union-1", durationMin: 150,
    sections: ["Conquistadores"], defaultPoints: 50, defaultCapacity: 200,
    createdBy: "Erick Mora", uses: 12, lastUsedAt: "2025-07-19", lastUsedAtCamporee: "Camporee Centro 2025" },
  { id: "t02", title: "Orden cerrado", description: "12 movimientos · jueces certificados.",
    category: "competencia", scope: "union", scopeId: "union-1", durationMin: 120,
    sections: ["Conquistadores", "Guías Mayores"], defaultPoints: 60, defaultCapacity: 800,
    createdBy: "Cap. Raúl Vega", uses: 18, lastUsedAt: "2025-11-09", lastUsedAtCamporee: "Camporee Sur 2025" },
  { id: "t03", title: "Primeros auxilios — práctica", description: "RCP, vendajes e inmovilizaciones.",
    category: "competencia", scope: "union", scopeId: "union-1", durationMin: 90,
    sections: ["Conquistadores", "Guías Mayores"], defaultPoints: 50, defaultCapacity: 400,
    createdBy: "Dra. Sofía Martín", uses: 14, lastUsedAt: "2025-07-19", lastUsedAtCamporee: "Camporee Centro 2025" },
  { id: "t04", title: "Mini-olimpiadas aventureras", description: "Estaciones de juegos coordinados, no competitivos.",
    category: "competencia", scope: "union", scopeId: "union-1", durationMin: 120,
    sections: ["Aventureros"], defaultPoints: 30, defaultCapacity: 250,
    createdBy: "Lupita Cruz", uses: 9, lastUsedAt: "2024-08-14", lastUsedAtCamporee: "Camporee Norte 2024" },
  { id: "t10", title: "Especialidad: Aves silvestres", description: "Observación de campo + cuaderno.",
    category: "taller", scope: "union", scopeId: "union-1", durationMin: 90,
    sections: ["Conquistadores", "Guías Mayores"], defaultCapacity: 60,
    createdBy: "Mtra. Diana Báez", uses: 6, lastUsedAt: "2025-07-19", lastUsedAtCamporee: "Camporee Centro 2025" },
  { id: "t18", title: "Fogata bíblica", description: "Cantos, testimonios, reflexión.",
    category: "social", scope: "union", scopeId: "union-1", durationMin: 120,
    sections: ["Aventureros", "Conquistadores", "Guías Mayores"],
    createdBy: "Sofía Martín", uses: 19, lastUsedAt: "2025-07-19", lastUsedAtCamporee: "Camporee Centro 2025" },
  { id: "t08", title: "Vigilia y ofrenda", description: "Servicio especial nocturno.",
    category: "espiritual", scope: "local_field", scopeId: "field-acv", durationMin: 120,
    sections: ["Conquistadores", "Guías Mayores"],
    createdBy: "Lucía Ortiz", uses: 4, lastUsedAt: "2025-06-12", lastUsedAtCamporee: "Camporee ACV 2025" },
];

export function buildMockEvents(args: BuildMockArgs): CamporeeEventsData {
  const start = new Date(args.startDate ?? "2026-07-15T00:00:00");
  const days = Array.from({ length: 5 }, (_, i) => {
    const d = new Date(start);
    d.setDate(start.getDate() + i);
    const iso = d.toISOString().slice(0, 10);
    return {
      id: `d${i + 1}`,
      numero: i + 1,
      fecha: iso,
      diaSemana: DAY_NAMES_ES[d.getDay()],
      fechaFmt: formatDayShort(d),
    };
  });

  const events: CamporeeEvent[] = EVENTS_TEMPLATE.map((e) => ({
    ...e,
    camporeeId: args.camporeeId,
  }));

  const totalMin = events.reduce((s, e) => s + durMin(e.startsAt, e.endsAt), 0);
  const fromCatalog = events.filter((e) => e.fromCatalog).length;
  const summary = {
    total: events.length,
    published: events.filter((e) => e.status === "publicado").length,
    cancelled: events.filter((e) => e.status === "cancelado").length,
    venuesUsed: new Set(events.map((e) => e.venueId)).size,
    hoursOfContent: Math.round(totalMin / 60),
    fromCatalog,
    new: events.length - fromCatalog,
  };

  return {
    camporeeId: args.camporeeId,
    camporeeType: args.camporeeType,
    unionName: args.unionName,
    localFieldName: args.localFieldName,
    days,
    venues: VENUES,
    events,
    templates: TEMPLATES,
    summary,
  };
}
```

- [ ] **Step 2: Lint**

```bash
cd sacdia-admin && pnpm lint --max-warnings=0
```

Expected: passes.

- [ ] **Step 3: Commit**

```bash
git -C sacdia-admin add src/lib/camporee-timeline/mock-data.ts
git -C sacdia-admin commit -m "feat(admin): add camporee timeline mock builder"
```

---

## Task 8: Create `components/camporee-events/timeline/events-summary-kpis.tsx`

**Files:**
- Create: `sacdia-admin/src/components/camporee-events/timeline/events-summary-kpis.tsx`

- [ ] **Step 1: Write the file**

```tsx
"use client";

import * as React from "react";
import { Calendar, Layers, Activity, Pin } from "lucide-react";
import { Card } from "@/components/ui/card";
import type { CamporeeEventsData } from "@/lib/camporee-timeline/types";

interface Props {
  data: CamporeeEventsData;
}

interface KpiProps {
  icon: React.ReactNode;
  label: string;
  value: React.ReactNode;
  hint?: string;
}

function Kpi({ icon, label, value, hint }: KpiProps) {
  return (
    <Card className="rounded-xl border-border/60 bg-card shadow-xs px-4 py-3">
      <div className="flex items-center gap-1.5 text-[10.5px] uppercase tracking-wider font-semibold text-muted-foreground">
        <span className="[&_svg]:size-3.5">{icon}</span>
        {label}
      </div>
      <div className="mt-1 text-[22px] font-bold tracking-tight tabular-nums">{value}</div>
      {hint && <div className="text-[11.5px] text-muted-foreground mt-0.5">{hint}</div>}
    </Card>
  );
}

export function EventsSummaryKpis({ data }: Props) {
  const { summary } = data;
  const reusePct = summary.total ? Math.round((summary.fromCatalog / summary.total) * 100) : 0;
  return (
    <div className="grid grid-cols-2 md:grid-cols-4 gap-2.5 mb-4">
      <Kpi
        icon={<Calendar />}
        label="Eventos del camporee"
        value={summary.total}
        hint={`${summary.published} publicados · ${summary.cancelled} cancelado${summary.cancelled === 1 ? "" : "s"}`}
      />
      <Kpi
        icon={<Activity />}
        label="Horas de contenido"
        value={`${summary.hoursOfContent}h`}
        hint={`a lo largo de ${data.days.length} días`}
      />
      <Kpi
        icon={<Layers />}
        label="Desde catálogo"
        value={
          <span>
            {summary.fromCatalog}
            <span className="text-[14px] text-muted-foreground/70 font-medium">/{summary.total}</span>
          </span>
        }
        hint={`${reusePct}% reutilizados`}
      />
      <Kpi
        icon={<Pin />}
        label="Sedes en uso"
        value={summary.venuesUsed}
        hint={`de ${data.venues.length} disponibles`}
      />
    </div>
  );
}
```

- [ ] **Step 2: Lint**

```bash
cd sacdia-admin && pnpm lint --max-warnings=0
```

Expected: passes.

- [ ] **Step 3: Commit**

```bash
git -C sacdia-admin add src/components/camporee-events/timeline/events-summary-kpis.tsx
git -C sacdia-admin commit -m "feat(admin): add timeline KPIs component"
```

---

## Task 9: Create `components/camporee-events/timeline/events-toolbar.tsx`

**Files:**
- Create: `sacdia-admin/src/components/camporee-events/timeline/events-toolbar.tsx`

- [ ] **Step 1: Write the file**

```tsx
"use client";

import * as React from "react";
import { Search, Download, SlidersHorizontal, Plus, Library } from "lucide-react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  EVENT_CATEGORIES,
  EVENT_STATUS_LABEL,
} from "@/lib/camporee-timeline/event-categories";
import type { CamporeeEventsData } from "@/lib/camporee-timeline/types";

interface Props {
  data: CamporeeEventsData;
  onCreate: () => void;
  onImportFromCatalog?: () => void;
}

export function EventsToolbar({ data, onCreate, onImportFromCatalog }: Props) {
  return (
    <div className="rounded-xl border border-border/60 bg-card shadow-xs p-3 mb-3.5 flex items-center gap-2 flex-wrap">
      <div className="relative">
        <Search className="size-3.5 text-muted-foreground absolute left-2.5 top-1/2 -translate-y-1/2 pointer-events-none" />
        <Input
          placeholder="Buscar evento, líder o sede…"
          className="pl-8 h-9 w-[280px] text-[12.5px]"
        />
      </div>

      <Select>
        <SelectTrigger className="h-9 w-[180px] text-[12.5px]">
          <SelectValue placeholder="Cualquier categoría" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="all">Cualquier categoría</SelectItem>
          {EVENT_CATEGORIES.map((c) => (
            <SelectItem key={c.id} value={c.id}>{c.label}</SelectItem>
          ))}
        </SelectContent>
      </Select>

      <Select>
        <SelectTrigger className="h-9 w-[170px] text-[12.5px]">
          <SelectValue placeholder="Cualquier sección" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="all">Cualquier sección</SelectItem>
          <SelectItem value="aventureros">Aventureros</SelectItem>
          <SelectItem value="conquistadores">Conquistadores</SelectItem>
          <SelectItem value="guias">Guías Mayores</SelectItem>
        </SelectContent>
      </Select>

      <Select>
        <SelectTrigger className="h-9 w-[170px] text-[12.5px]">
          <SelectValue placeholder="Cualquier sede" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="all">Cualquier sede</SelectItem>
          {data.venues.map((v) => (
            <SelectItem key={v.id} value={v.id}>{v.name}</SelectItem>
          ))}
        </SelectContent>
      </Select>

      <Select>
        <SelectTrigger className="h-9 w-[160px] text-[12.5px]">
          <SelectValue placeholder="Cualquier estado" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="all">Cualquier estado</SelectItem>
          {Object.entries(EVENT_STATUS_LABEL).map(([k, v]) => (
            <SelectItem key={k} value={k}>{v}</SelectItem>
          ))}
        </SelectContent>
      </Select>

      <div className="ml-auto flex gap-2 items-center">
        <span className="text-[12px] text-muted-foreground">
          Mostrando <b className="text-foreground">{data.events.length}</b> eventos en{" "}
          <b className="text-foreground">{data.days.length} días</b>
        </span>
        <Button variant="outline" size="sm" className="h-8 text-[12px]" onClick={() => { /* TODO: wire filters */ }}>
          <SlidersHorizontal />
          Más filtros
        </Button>
        <Button variant="outline" size="sm" className="h-8 text-[12px]" onClick={() => { /* TODO: wire export */ }}>
          <Download />
          Exportar
        </Button>
        {onImportFromCatalog && (
          <Button variant="outline" size="sm" className="h-8 text-[12px]" onClick={onImportFromCatalog}>
            <Library />
            Importar
          </Button>
        )}
        <Button size="sm" className="h-8 text-[12px]" onClick={onCreate}>
          <Plus />
          Crear evento
        </Button>
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Lint**

```bash
cd sacdia-admin && pnpm lint --max-warnings=0
```

Expected: passes.

- [ ] **Step 3: Commit**

```bash
git -C sacdia-admin add src/components/camporee-events/timeline/events-toolbar.tsx
git -C sacdia-admin commit -m "feat(admin): add timeline toolbar component"
```

---

## Task 10: Create `components/camporee-events/timeline/event-row.tsx`

**Files:**
- Create: `sacdia-admin/src/components/camporee-events/timeline/event-row.tsx`

- [ ] **Step 1: Write the file**

```tsx
"use client";

import * as React from "react";
import { Clock, Pin, Copy, Edit, MoreHorizontal, Trophy } from "lucide-react";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Progress } from "@/components/ui/progress";
import { cn } from "@/lib/utils";

import {
  EVENT_CATEGORY_MAP,
  EVENT_STATUS_LABEL,
  EVENT_STATUS_VARIANT,
  SECTION_COLOR,
} from "@/lib/camporee-timeline/event-categories";
import type { CamporeeEvent, Venue } from "@/lib/camporee-timeline/types";
import { durMin, initials } from "@/lib/camporee-timeline/helpers";

interface Props {
  event: CamporeeEvent;
  venue: Venue;
  onEdit?: () => void;
}

export function EventRow({ event, venue, onEdit }: Props) {
  const cat = EVENT_CATEGORY_MAP[event.category];
  const status = event.status;
  const capPct = event.capacity > 0 ? (event.registered / event.capacity) * 100 : 0;
  const hasCapacity = event.registered > 0;

  return (
    <div
      className={cn(
        "group grid items-center gap-3.5 px-4 py-3 border-b border-border/60 last:border-b-0",
        "grid-cols-1 md:grid-cols-[88px_1fr_220px_180px_180px_140px_110px_auto]",
        "transition-colors hover:bg-muted/50 cursor-pointer relative",
      )}
    >
      <div
        aria-hidden
        className={cn(
          "absolute inset-y-0 left-0 w-[3px] opacity-0 group-hover:opacity-100 transition-opacity",
          cat.dot,
        )}
      />

      <div className="tabular-nums">
        <div className="text-[14px] font-bold tracking-tight leading-tight">{event.startsAt}</div>
        <div className="text-[11px] text-muted-foreground leading-tight">a {event.endsAt}</div>
        <div className="text-[10px] text-muted-foreground/70 mt-0.5 flex items-center gap-1">
          <Clock className="size-2.5" />
          {durMin(event.startsAt, event.endsAt)} min
        </div>
      </div>

      <div className="min-w-0">
        <div className="text-[13.5px] font-semibold tracking-tight leading-snug flex items-center gap-1.5 flex-wrap">
          {event.title}
          {event.fromCatalog && (
            <span
              className="inline-flex items-center gap-1 text-[10px] font-medium text-muted-foreground/80 bg-muted px-1.5 py-0.5 rounded"
              title="Importado del catálogo"
            >
              <Copy className="size-2.5" />
              Catálogo
            </span>
          )}
        </div>
        <div className="text-[11.5px] text-muted-foreground leading-snug mt-0.5 line-clamp-1">
          {event.description}
        </div>
        <div className="flex items-center gap-1.5 mt-1.5 flex-wrap">
          <span
            className={cn(
              "inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[10.5px] font-bold uppercase tracking-wide",
              cat.tint,
            )}
          >
            <span className={cn("size-1.5 rounded-full", cat.dot)} />
            {cat.label}
          </span>
          {event.sections.map((s) => {
            const sc = SECTION_COLOR[s];
            return (
              <span
                key={s}
                className={cn(
                  "inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-semibold",
                  sc?.tint,
                )}
              >
                {s.slice(0, 4)}
              </span>
            );
          })}
        </div>
      </div>

      <div className="flex items-start gap-1.5 text-[12px]">
        <Pin className="size-3 text-muted-foreground flex-shrink-0 mt-0.5" />
        <div className="min-w-0">
          <div className="truncate font-medium">{venue.name}</div>
          <div className="text-[10.5px] text-muted-foreground">cap. {venue.capacity}</div>
        </div>
      </div>

      <div className="flex items-center gap-2 min-w-0">
        <Avatar className="size-7">
          <AvatarFallback className="text-[10px] bg-primary text-primary-foreground font-bold">
            {initials(event.leaderName)}
          </AvatarFallback>
        </Avatar>
        <div className="min-w-0">
          <div className="text-[12px] font-medium truncate">{event.leaderName}</div>
          <div className="text-[10.5px] text-muted-foreground truncate">
            {event.leaderRole ?? "responsable"}
          </div>
        </div>
      </div>

      <div className="text-right tabular-nums">
        {hasCapacity ? (
          <>
            <div className="text-[13px] font-bold leading-tight">
              {event.registered}
              <span className="text-muted-foreground/70 font-medium"> / {event.capacity}</span>
            </div>
            <Progress
              value={capPct}
              className={cn("h-1 mt-1", capPct > 90 && "[&>div]:bg-warning")}
            />
            <div className="text-[10px] text-muted-foreground mt-0.5">
              {Math.round(capPct)}% del cupo
            </div>
          </>
        ) : (
          <div className="text-[11px] text-muted-foreground/70">
            {event.points > 0 ? "—" : "asistencia abierta"}
          </div>
        )}
      </div>

      <div className="text-center">
        {event.points > 0 ? (
          <span className="inline-flex items-center gap-1 text-[10.5px] font-bold text-warning-soft-foreground bg-warning-soft px-2 py-0.5 rounded">
            <Trophy className="size-2.5" />
            {event.points} pts
          </span>
        ) : (
          <span className="text-[11px] text-muted-foreground/60">—</span>
        )}
      </div>

      <div>
        <Badge variant={EVENT_STATUS_VARIANT[status] as never}>
          {EVENT_STATUS_LABEL[status]}
        </Badge>
      </div>

      <div className="flex gap-1 justify-end">
        <Button
          variant="ghost"
          size="icon"
          className="size-7"
          onClick={(e) => {
            e.stopPropagation();
            onEdit?.();
          }}
        >
          <Edit className="size-3.5" />
          <span className="sr-only">Editar</span>
        </Button>
        <Button
          variant="ghost"
          size="icon"
          className="size-7"
          onClick={(e) => e.stopPropagation()}
        >
          <MoreHorizontal className="size-3.5" />
          <span className="sr-only">Más opciones</span>
        </Button>
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Lint**

```bash
cd sacdia-admin && pnpm lint --max-warnings=0
```

Expected: passes. If `[&>div]:bg-warning` fails because token `warning` doesn't exist, change to `[&>div]:bg-destructive` or add a `--warning` token in a follow-up.

- [ ] **Step 3: Commit**

```bash
git -C sacdia-admin add src/components/camporee-events/timeline/event-row.tsx
git -C sacdia-admin commit -m "feat(admin): add timeline event row component"
```

---

## Task 11: Create `components/camporee-events/timeline/event-day-card.tsx`

**Files:**
- Create: `sacdia-admin/src/components/camporee-events/timeline/event-day-card.tsx`

- [ ] **Step 1: Write the file**

```tsx
"use client";

import * as React from "react";
import { Plus } from "lucide-react";
import { Card } from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import { SECTION_COLOR } from "@/lib/camporee-timeline/event-categories";
import { cn } from "@/lib/utils";

import type { CamporeeDay, CamporeeEvent, Venue } from "@/lib/camporee-timeline/types";
import { EventRow } from "./event-row";
import { durMin, sortByStart, toMin, formatHours } from "@/lib/camporee-timeline/helpers";

interface Props {
  day: CamporeeDay;
  events: CamporeeEvent[];
  venues: Venue[];
  onAdd: (dayNumber: number) => void;
  onEdit: (eventId: string) => void;
  readonly?: boolean;
}

function HeatBar({ events }: { events: CamporeeEvent[] }) {
  const buckets = Array(18).fill(0);
  events.forEach((e) => {
    const startH = Math.floor(toMin(e.startsAt) / 60) - 6;
    const endH = Math.ceil(toMin(e.endsAt) / 60) - 6;
    for (let i = Math.max(0, startH); i < Math.min(18, endH); i++) buckets[i]++;
  });
  const maxB = Math.max(...buckets, 1);
  return (
    <div>
      <div className="text-[10px] font-semibold uppercase tracking-wider text-muted-foreground/80 mb-1">
        Distribución horaria · 06–24h
      </div>
      <div className="flex gap-[1px]">
        {buckets.map((v, i) => {
          const intensity = v === 0 ? 0 : v / maxB;
          return (
            <span
              key={i}
              title={`${i + 6}:00 — ${v} evento${v === 1 ? "" : "s"}`}
              className={cn(
                "flex-1 h-1.5 rounded-[1px]",
                v === 0 && "bg-muted",
                intensity > 0 && intensity <= 0.33 && "bg-primary/40",
                intensity > 0.33 && intensity <= 0.66 && "bg-primary/70",
                intensity > 0.66 && "bg-primary",
              )}
            />
          );
        })}
      </div>
      <div className="flex justify-between text-[9px] text-muted-foreground/70 mt-0.5">
        <span>06h</span><span>09h</span><span>12h</span>
        <span>15h</span><span>18h</span><span>21h</span><span>24h</span>
      </div>
    </div>
  );
}

function DayBadge({ day }: { day: CamporeeDay }) {
  return (
    <div className="size-[52px] rounded-xl bg-primary text-primary-foreground grid place-items-center">
      <div className="text-[9px] font-bold uppercase tracking-[0.14em] opacity-90 leading-none">
        Día
      </div>
      <div className="text-[22px] font-bold tracking-tight leading-none mt-0.5 tabular-nums">
        {day.numero}
      </div>
    </div>
  );
}

export function EventDayCard({ day, events, venues, onAdd, onEdit, readonly = false }: Props) {
  const sorted = React.useMemo(() => [...events].sort(sortByStart), [events]);
  const totalMin = sorted.reduce((s, e) => s + durMin(e.startsAt, e.endsAt), 0);
  const venuesUsed = new Set(sorted.map((e) => e.venueId)).size;

  const secCount: Record<string, number> = {
    Aventureros: 0,
    Conquistadores: 0,
    "Guías Mayores": 0,
  };
  sorted.forEach((e) => e.sections.forEach((s) => { secCount[s] = (secCount[s] || 0) + 1; }));

  const venueOf = (id: string) => venues.find((v) => v.id === id) ?? { id, name: "—", capacity: 0 };

  if (sorted.length === 0) {
    return (
      <Card className="rounded-xl border-border/60 bg-card shadow-xs overflow-hidden">
        <div className="px-5 py-4 border-b border-border/60 bg-muted/30 flex items-center gap-4">
          <DayBadge day={day} />
          <div className="flex-1">
            <div className="text-[15px] font-semibold tracking-tight">
              {day.diaSemana} · {day.fechaFmt}
            </div>
            <div className="text-[12px] text-muted-foreground">Sin eventos programados</div>
          </div>
        </div>
        {!readonly && (
          <button
            type="button"
            onClick={() => onAdd(day.numero)}
            className="w-full py-5 text-[12.5px] text-muted-foreground hover:text-primary hover:bg-primary/5 transition-colors flex items-center justify-center gap-1.5 font-medium"
          >
            <Plus className="size-3.5" /> Agregar el primer evento de este día
          </button>
        )}
      </Card>
    );
  }

  return (
    <Card className="rounded-xl border-border/60 bg-card shadow-xs overflow-hidden">
      <div className="px-5 py-4 border-b border-border/60 bg-muted/30 grid grid-cols-[auto_1fr_auto] gap-5 items-center">
        <DayBadge day={day} />

        <div>
          <div className="text-[15px] font-semibold tracking-tight">
            {day.diaSemana} · {day.fechaFmt}
          </div>
          <div className="text-[12px] text-muted-foreground flex items-center gap-2 mt-0.5">
            <span>{sorted.length} eventos programados</span>
            <span className="size-0.5 rounded-full bg-muted-foreground/40" />
            <span>{formatHours(totalMin)}h de contenido</span>
            <span className="size-0.5 rounded-full bg-muted-foreground/40" />
            <span>{venuesUsed} sedes en uso</span>
            <span className="size-0.5 rounded-full bg-muted-foreground/40" />
            <span className="inline-flex items-center gap-1">
              Secciones
              <span className="inline-flex gap-0.5">
                {Object.entries(secCount).map(([s, n]) =>
                  n > 0 ? (
                    <span
                      key={s}
                      className={cn("size-1.5 rounded-full", SECTION_COLOR[s]?.dot)}
                      title={`${s}: ${n}`}
                    />
                  ) : null,
                )}
              </span>
            </span>
          </div>
        </div>

        <div className="w-[200px]">
          <HeatBar events={sorted} />
        </div>
      </div>

      <div className="flex flex-col">
        {sorted.map((ev) => (
          <EventRow
            key={ev.id}
            event={ev}
            venue={venueOf(ev.venueId)}
            onEdit={() => onEdit(ev.id)}
          />
        ))}
      </div>

      {!readonly && (
        <>
          <Separator />
          <button
            type="button"
            onClick={() => onAdd(day.numero)}
            className="w-full py-2.5 text-[12px] text-muted-foreground hover:text-primary hover:bg-primary/5 transition-colors flex items-center justify-center gap-1.5 font-medium"
          >
            <Plus className="size-3.5" /> Agregar evento al {day.diaSemana.toLowerCase()}
          </button>
        </>
      )}
    </Card>
  );
}
```

- [ ] **Step 2: Lint**

```bash
cd sacdia-admin && pnpm lint --max-warnings=0
```

Expected: passes.

- [ ] **Step 3: Commit**

```bash
git -C sacdia-admin add src/components/camporee-events/timeline/event-day-card.tsx
git -C sacdia-admin commit -m "feat(admin): add timeline day card component"
```

---

## Task 12: Create `components/camporee-events/timeline/create-event-drawer.tsx`

**Files:**
- Create: `sacdia-admin/src/components/camporee-events/timeline/create-event-drawer.tsx`

- [ ] **Step 1: Write the file**

```tsx
"use client";

import * as React from "react";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetDescription,
  SheetFooter,
} from "@/components/ui/sheet";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Checkbox } from "@/components/ui/checkbox";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs";
import { Plus, Library, Check } from "lucide-react";
import { cn } from "@/lib/utils";

import {
  EVENT_CATEGORIES,
  SECTION_COLOR,
} from "@/lib/camporee-timeline/event-categories";
import type {
  CamporeeEventsData,
  EventCategoryId,
  Section,
} from "@/lib/camporee-timeline/types";

interface Props {
  open: boolean;
  onOpenChange: (v: boolean) => void;
  data: CamporeeEventsData;
  defaultDayNumber?: number;
}

const SECTIONS: Section[] = ["Aventureros", "Conquistadores", "Guías Mayores"];

export function CreateEventDrawer({ open, onOpenChange, data, defaultDayNumber = 1 }: Props) {
  const [origin, setOrigin] = React.useState<"new" | "catalog">("new");
  const [category, setCategory] = React.useState<EventCategoryId>("competencia");
  const [sections, setSections] = React.useState<Set<Section>>(new Set(["Conquistadores"]));
  const [day, setDay] = React.useState<number>(defaultDayNumber);
  const [saveAsTemplate, setSaveAsTemplate] = React.useState(true);

  React.useEffect(() => {
    setDay(defaultDayNumber);
  }, [defaultDayNumber]);

  const toggleSection = (s: Section) => {
    const n = new Set(sections);
    if (n.has(s)) n.delete(s); else n.add(s);
    setSections(n);
  };

  const scopeLabel =
    data.camporeeType === "union" ? (
      <>
        en la <b>Unión</b> ({data.unionName})
      </>
    ) : (
      <>
        en tu <b>campo local</b> ({data.localFieldName ?? "—"})
      </>
    );

  const handleSubmit = () => {
    // TODO: wire backend
    console.log("create event", { origin, category, sections: Array.from(sections), day, saveAsTemplate });
    onOpenChange(false);
  };

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent className="w-[520px] max-w-full sm:max-w-[520px] p-0 flex flex-col">
        <SheetHeader className="px-6 pt-5 pb-3 border-b border-border/60">
          <SheetTitle className="text-[16px] font-semibold tracking-tight">Crear evento</SheetTitle>
          <SheetDescription className="text-[12px]">
            Se guardará en este camporee. Puedes marcarlo como reutilizable para futuros camporees.
          </SheetDescription>
        </SheetHeader>

        <div className="flex-1 overflow-auto px-6 py-5 space-y-5">
          <Tabs value={origin} onValueChange={(v) => setOrigin(v as typeof origin)}>
            <TabsList className="w-full">
              <TabsTrigger value="new" className="flex-1 gap-1.5">
                <Plus className="size-3.5" />
                Nuevo evento
              </TabsTrigger>
              <TabsTrigger value="catalog" className="flex-1 gap-1.5">
                <Library className="size-3.5" />
                Desde catálogo
              </TabsTrigger>
            </TabsList>
            <TabsContent value="catalog" className="mt-4 space-y-2">
              <Label className="text-[12px]">Plantilla disponible</Label>
              <Select>
                <SelectTrigger><SelectValue placeholder="Elegir del catálogo…" /></SelectTrigger>
                <SelectContent>
                  {data.templates.map((t) => (
                    <SelectItem key={t.id} value={t.id}>
                      {t.title}
                      <span className="text-muted-foreground ml-1.5 text-[11px]">
                        ({t.scope === "union" ? "Unión" : "Campo"} · usado {t.uses}x)
                      </span>
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              <p className="text-[11px] text-muted-foreground leading-relaxed">
                Importar copia las propiedades base de la plantilla. Podrás ajustar día, horario, sede y cupo para este camporee.
              </p>
            </TabsContent>
          </Tabs>

          <div className="space-y-1.5">
            <Label htmlFor="title" className="text-[12px] font-semibold">Título del evento</Label>
            <Input id="title" defaultValue="Competencia de nudos y amarres" />
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="desc" className="text-[12px] font-semibold">
              Descripción <span className="text-muted-foreground font-normal">opcional</span>
            </Label>
            <Textarea
              id="desc"
              rows={3}
              defaultValue="10 nudos cronometrados + amarre cuadrado en equipos de 4."
            />
          </div>

          <div className="space-y-1.5">
            <Label className="text-[12px] font-semibold">Categoría</Label>
            <div className="flex flex-wrap gap-1.5">
              {EVENT_CATEGORIES.map((c) => {
                const on = c.id === category;
                return (
                  <button
                    key={c.id}
                    type="button"
                    onClick={() => setCategory(c.id)}
                    className={cn(
                      "inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-full text-[12px] border transition-colors",
                      on ? cn("font-semibold", c.tint, c.border) : "border-border/60 text-foreground hover:bg-muted",
                    )}
                  >
                    <span className={cn("size-2 rounded-full", c.dot)} />
                    {c.label}
                  </button>
                );
              })}
            </div>
          </div>

          <div className="grid grid-cols-3 gap-3">
            <div className="space-y-1.5">
              <Label className="text-[12px] font-semibold">Día</Label>
              <Select value={String(day)} onValueChange={(v) => setDay(parseInt(v))}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  {data.days.map((d) => (
                    <SelectItem key={d.id} value={String(d.numero)}>
                      D{d.numero} · {d.fechaFmt}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label className="text-[12px] font-semibold">Inicio</Label>
              <Input type="time" defaultValue="09:00" />
            </div>
            <div className="space-y-1.5">
              <Label className="text-[12px] font-semibold">Fin</Label>
              <Input type="time" defaultValue="11:30" />
            </div>
          </div>

          <div className="space-y-1.5">
            <Label className="text-[12px] font-semibold">Secciones que participan</Label>
            <div className="flex flex-wrap gap-1.5">
              {SECTIONS.map((s) => {
                const on = sections.has(s);
                const sc = SECTION_COLOR[s];
                return (
                  <button
                    key={s}
                    type="button"
                    onClick={() => toggleSection(s)}
                    className={cn(
                      "inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-full text-[12px] border transition-colors",
                      on ? cn("font-semibold", sc.tint) : "border-border/60 text-foreground hover:bg-muted",
                    )}
                  >
                    <span className={cn("size-2.5 rounded-full", sc.dot, !on && "opacity-30")} />
                    {s}
                  </button>
                );
              })}
            </div>
            <p className="text-[11px] text-muted-foreground">
              Define quién puede inscribirse y filtra el evento en la app de los clubes.
            </p>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1.5">
              <Label className="text-[12px] font-semibold">Sede</Label>
              <Select defaultValue={data.venues[3]?.id}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  {data.venues.map((v) => (
                    <SelectItem key={v.id} value={v.id}>
                      {v.name} <span className="text-muted-foreground ml-1">({v.capacity})</span>
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label className="text-[12px] font-semibold">Responsable</Label>
              <Select defaultValue="erick">
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="erick">Erick Mora</SelectItem>
                  <SelectItem value="karla">Karla Soto</SelectItem>
                  <SelectItem value="raul">Cap. Raúl Vega</SelectItem>
                  <SelectItem value="sofia">Dra. Sofía Martín</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1.5">
              <Label className="text-[12px] font-semibold">Cupo máximo</Label>
              <Input type="number" defaultValue={200} />
            </div>
            <div className="space-y-1.5">
              <Label className="text-[12px] font-semibold">
                Puntos en juego <span className="text-muted-foreground font-normal">opcional</span>
              </Label>
              <Input type="number" defaultValue={50} />
            </div>
          </div>

          <div className="rounded-xl border border-primary/30 bg-primary/5 p-4 space-y-1">
            <label className="flex items-start gap-2.5 cursor-pointer">
              <Checkbox
                checked={saveAsTemplate}
                onCheckedChange={(c) => setSaveAsTemplate(Boolean(c))}
                className="mt-0.5"
              />
              <div>
                <div className="text-[13px] font-semibold text-foreground">
                  Guardar también como plantilla reutilizable
                </div>
                <div className="text-[11.5px] text-muted-foreground mt-0.5 leading-relaxed">
                  Estará disponible en el catálogo {scopeLabel} para futuros camporees.
                </div>
              </div>
            </label>
          </div>
        </div>

        <SheetFooter className="px-6 py-3 border-t border-border/60 bg-muted/30 flex sm:justify-between items-center">
          <Button variant="ghost" size="sm" onClick={() => onOpenChange(false)}>
            Cancelar
          </Button>
          <div className="flex gap-2">
            <Button variant="outline" size="sm">Guardar borrador</Button>
            <Button size="sm" onClick={handleSubmit}>
              <Check />
              Crear y publicar
            </Button>
          </div>
        </SheetFooter>
      </SheetContent>
    </Sheet>
  );
}
```

- [ ] **Step 2: Lint**

```bash
cd sacdia-admin && pnpm lint --max-warnings=0
```

Expected: passes. If `checkbox` or `textarea` components don't exist, install them with `pnpm dlx shadcn@latest add checkbox textarea` and commit separately.

- [ ] **Step 3: Commit**

```bash
git -C sacdia-admin add src/components/camporee-events/timeline/create-event-drawer.tsx
git -C sacdia-admin commit -m "feat(admin): add timeline create-event drawer"
```

---

## Task 13: Create `components/camporee-events/timeline/events-timeline-view.tsx`

**Files:**
- Create: `sacdia-admin/src/components/camporee-events/timeline/events-timeline-view.tsx`

- [ ] **Step 1: Write the file**

```tsx
"use client";

import * as React from "react";
import type { CamporeeEventsData } from "@/lib/camporee-timeline/types";
import { EventsSummaryKpis } from "./events-summary-kpis";
import { EventsToolbar } from "./events-toolbar";
import { EventDayCard } from "./event-day-card";
import { CreateEventDrawer } from "./create-event-drawer";

interface Props {
  camporeeId: string;
  data: CamporeeEventsData;
  readonly?: boolean;
}

export function EventsTimelineView({ data, readonly = false }: Props) {
  const [drawerOpen, setDrawerOpen] = React.useState(false);
  const [drawerDay, setDrawerDay] = React.useState<number>(1);

  const openCreate = (dayNumber?: number) => {
    if (readonly) return;
    if (dayNumber) setDrawerDay(dayNumber);
    setDrawerOpen(true);
  };

  const eventsByDay = React.useMemo(() => {
    const map = new Map<number, typeof data.events>();
    data.days.forEach((d) => map.set(d.numero, []));
    data.events.forEach((e) => {
      const arr = map.get(e.dayNumber);
      if (arr) arr.push(e);
    });
    return map;
  }, [data]);

  return (
    <div>
      <EventsSummaryKpis data={data} />

      {!readonly && (
        <EventsToolbar
          data={data}
          onCreate={() => openCreate()}
          onImportFromCatalog={() => openCreate()}
        />
      )}

      <div className="flex flex-col gap-4">
        {data.days.map((d) => (
          <EventDayCard
            key={d.id}
            day={d}
            events={eventsByDay.get(d.numero) ?? []}
            venues={data.venues}
            onAdd={openCreate}
            onEdit={(eventId) => {
              // TODO: wire backend (navigate to edit page)
              console.log("edit event", eventId);
            }}
            readonly={readonly}
          />
        ))}
      </div>

      {!readonly && (
        <CreateEventDrawer
          open={drawerOpen}
          onOpenChange={setDrawerOpen}
          data={data}
          defaultDayNumber={drawerDay}
        />
      )}
    </div>
  );
}
```

- [ ] **Step 2: Lint**

```bash
cd sacdia-admin && pnpm lint --max-warnings=0
```

Expected: passes.

- [ ] **Step 3: Commit**

```bash
git -C sacdia-admin add src/components/camporee-events/timeline/events-timeline-view.tsx
git -C sacdia-admin commit -m "feat(admin): add timeline view wrapper"
```

---

## Task 14: Rewrite `camporee-events-tab.tsx` to render the timeline

**Files:**
- Modify (full rewrite): `sacdia-admin/src/components/camporee-events/camporee-events-tab.tsx`

- [ ] **Step 1: Replace the file contents**

Replace the entire file with:

```tsx
"use client";

import { EventsTimelineView } from "./timeline/events-timeline-view";
import { buildMockEvents } from "@/lib/camporee-timeline/mock-data";
import type {
  CamporeeEvent,
  CamporeeEventTemplate,
} from "@/lib/api/camporee-events";

// NOTE: This tab is currently rendering a mock-data prototype of the Variant K
// timeline redesign. Backend wiring is pending — see
// docs/superpowers/specs/2026-05-20-camporee-timeline-admin-design.md.
//
// Legacy props (initialEvents, availableTemplates, canEdit, canDelete) are
// accepted for call-site compatibility but currently ignored. They will be
// re-wired once the backend schema for the new agenda model is defined.

interface CamporeeEventsTabProps {
  camporeeId: number;
  initialEvents: CamporeeEvent[];
  availableTemplates: CamporeeEventTemplate[];
  isUnionCamporee?: boolean;
  canCreate?: boolean;
  canEdit?: boolean;
  canDelete?: boolean;
}

export function CamporeeEventsTab({
  camporeeId,
  isUnionCamporee = false,
  canCreate = false,
}: CamporeeEventsTabProps) {
  const data = buildMockEvents({
    camporeeId: String(camporeeId),
    camporeeType: isUnionCamporee ? "union" : "local",
    unionName: "Tu unión", // TODO: pasar desde page.tsx (props)
    localFieldName: isUnionCamporee ? undefined : "Tu campo local",
  });

  return (
    <EventsTimelineView
      camporeeId={String(camporeeId)}
      data={data}
      readonly={!canCreate}
    />
  );
}
```

- [ ] **Step 2: Lint**

```bash
cd sacdia-admin && pnpm lint --max-warnings=0
```

Expected: passes. The unused-parameter warnings for `initialEvents`, `availableTemplates`, `canEdit`, `canDelete` are mitigated by destructuring only the props we use; the interface still documents them.

If lint flags TypeScript "unused interface property" warnings, leave them — they're informational, not errors.

- [ ] **Step 3: Commit**

```bash
git -C sacdia-admin add src/components/camporee-events/camporee-events-tab.tsx
git -C sacdia-admin commit -m "feat(admin): replace events tab with timeline mock prototype"
```

---

## Task 15: Manual verification in the browser

**Files:** none

- [ ] **Step 1: Start dev server**

```bash
cd sacdia-admin && pnpm dev
```

Expected: server starts on `http://localhost:3001`.

- [ ] **Step 2: Navigate and check**

Open `http://localhost:3001/dashboard/camporees/<any-valid-id>` and click the **Eventos** tab.

Verify:
1. 4 KPI cards visible with non-zero numbers.
2. Toolbar with search + 4 selects + 4 buttons (Más filtros, Exportar, Importar, Crear evento).
3. 5 day cards, each with: day badge (Día N), date label, stats line, heatbar, sorted event rows, footer "+ Agregar" button.
4. Event row shows: time block, title + Catálogo pill (when applicable), description, category pill, section pills, venue, leader avatar + name, capacity bar (if `registered > 0`), points pill (if `points > 0`), status badge, action buttons.
5. Click "Crear evento" → Sheet opens from the right with form. Tabs Nuevo/Catálogo switch correctly. Close button works.
6. Click "+ Agregar evento al jueves" on Day 2 footer → drawer opens with Day field preselected to D2.
7. Edit icon click → console logs `edit event <id>`.
8. Dark mode toggle (existing theme switcher) → all colors switch correctly: backgrounds, category dots/tints, section badges, status badge, heatbar, warning-soft pill.
9. Resize window to <768px → KPI strip drops to 2 columns; event rows collapse to single column stack.

If any of the above fails, return to the relevant task, fix, and re-verify.

- [ ] **Step 3: Lint clean**

```bash
cd sacdia-admin && pnpm lint --max-warnings=0
```

Expected: passes with zero warnings.

- [ ] **Step 4: No commit (verification only)**

---

## Self-review checklist (engineer should run before declaring done)

- [ ] Tab "Eventos" in `/dashboard/camporees/[id]` renders the timeline (not the old table).
- [ ] Dark mode works for every new token (category dots, section pills, warning-soft pill).
- [ ] No hardcoded Tailwind colors (`bg-blue-50`, `text-red-500`, etc.) in new files.
- [ ] No console errors when navigating to the page or opening the drawer.
- [ ] Legacy files (`event-template-form-page.tsx`, `event-template-list-client.tsx`, `participants-field.tsx`, `penalties-editor.tsx`) untouched.
- [ ] No backend / server-action changes (this is a mock prototype).
- [ ] `pnpm lint --max-warnings=0` passes.
