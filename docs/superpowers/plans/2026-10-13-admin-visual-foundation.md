# Base visual del admin (antislop) — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Aplicar la escala de radios por rol en los primitivos de `sacdia-admin`, eliminar los labels `uppercase` + `tracking-*`, documentar la dirección antislop en el DS y bloquear regresiones con el audit.

**Architecture:** Cambios de clases Tailwind en `src/components/ui/*` (radios) y en ~80 archivos de dominio (mayúsculas, vía codemod de un solo uso). Las reglas del audit se extraen a un módulo testeable (`scripts/design-system-rules.mjs`) y se agregan dos reglas nuevas. Dos PRs encadenados sobre `development`.

**Tech Stack:** Next.js 16, Tailwind CSS v4, shadcn/ui, Vitest, Node ESM scripts, `sd` / `rg`.

**Spec:** `docs/superpowers/specs/2026-10-13-admin-visual-foundation-design.md`

---

## Reglas para quien ejecuta

- Repo de trabajo: `sacdia-admin/` (git propio). Todos los comandos se corren desde `sacdia-admin/` salvo que se diga otra cosa.
- Commits convencionales, en inglés, **sin** líneas de atribución de IA.
- **No** correr `pnpm build` (regla del dueño).
- Herramientas: `rg`, `fd`, `sd`, `bat`, `eza`. No usar `grep`/`find`/`sed`/`cat`/`ls`.
- Baseline verificado el 2026-10-13: `node scripts/audit-design-system.mjs --strict` → `Errors: 0 | Warnings: 42`.

## Mapa de archivos

| Archivo | Responsabilidad | PR |
|---|---|---|
| `scripts/design-system-rules.mjs` (nuevo) | Lista de reglas del audit (antes inline) + reglas `uppercase-tracking` y `pill-radius` | 1 |
| `scripts/design-system-rules.test.mjs` (nuevo) | Tests de las reglas | 1 |
| `scripts/audit-design-system.mjs` | Importa `RULES` del módulo nuevo | 1 |
| `src/components/ui/*.tsx` (~30) | Radios por rol | 1 |
| `src/components/dashboard/dashboard-version-switch.tsx` | Único `rounded-4xl` fuera de `ui/` | 1 |
| `DESIGN-SYSTEM.md` | §4.1, §5.5, §5.6, nueva sección "Dirección antislop", changelog (PR 1); §3.2, §5.4, §10.2 (PR 2) | 1 y 2 |
| `AGENTS.md`, `CLAUDE.md` | Puntero DS = `DESIGN.md` de antislop | 1 |
| `src/**/*.tsx` (~80) | Quitar `uppercase` + `tracking-*` | 2 |

## Escala de referencia (de la spec)

| Rol | Clase |
|---|---|
| Etiqueta / estado | `rounded-full` |
| Control | `rounded-lg` |
| Ítem dentro de superficie | `rounded-lg` |
| Superficie | `rounded-xl` |
| Overlay | `rounded-2xl` |
| Elemento interno de un control con padding de 3px (tab trigger, botón del version switch) | `rounded-md` (radio concéntrico) |

---

# PR 1 — Radios + DS + audit

### Task 0: Rama

- [ ] **Step 1: Crear rama desde `development` actualizado**

```bash
git checkout development
git pull --ff-only
git checkout -b feat/antislop-radius-scale
```

Expected: `Switched to a new branch 'feat/antislop-radius-scale'`.

---

### Task 1: Extraer reglas del audit y agregar `uppercase-tracking` + `pill-radius`

**Files:**
- Create: `scripts/design-system-rules.mjs`
- Create: `scripts/design-system-rules.test.mjs`
- Modify: `scripts/audit-design-system.mjs:20-73` (bloque `const RULES = [...]`)

- [ ] **Step 1: Escribir el test que falla**

Crear `scripts/design-system-rules.test.mjs`:

```js
import { describe, expect, it } from "vitest";
import { RULES } from "./design-system-rules.mjs";

const rule = (id) => {
  const found = RULES.find((r) => r.id === id);
  if (!found) throw new Error(`Rule ${id} not found`);
  return found;
};

describe("uppercase-tracking", () => {
  const r = rule("uppercase-tracking");

  it("flags uppercase combined with tracking on the same line", () => {
    expect(r.test('className="text-xs font-medium uppercase tracking-wider"')).toBe(true);
    expect(r.test('className="tracking-[0.2em] uppercase text-muted-foreground"')).toBe(true);
    expect(r.test('"uppercase tracking-wide"')).toBe(true);
  });

  it("ignores uppercase alone and tracking alone", () => {
    expect(r.test('className="text-[11px] uppercase text-muted-foreground"')).toBe(false);
    expect(r.test('"ml-auto text-xs tracking-widest text-muted-foreground"')).toBe(false);
    expect(r.test('className="font-semibold tracking-tight"')).toBe(false);
  });

  it("allows test files", () => {
    expect(r.allow("src/components/foo.test.tsx")).toBe(true);
    expect(r.allow("src/components/foo.tsx")).toBe(false);
  });

  it("is a warning until the sentence-case migration lands", () => {
    expect(r.severity).toBe("warn");
  });
});

describe("pill-radius", () => {
  const r = rule("pill-radius");

  it("flags rounded-4xl and rounded-3xl, including important and variant forms", () => {
    expect(r.test('"inline-flex rounded-4xl border"')).toBe(true);
    expect(r.test('"overflow-hidden rounded-4xl! p-0"')).toBe(true);
    expect(r.test('"before:rounded-4xl before:border"')).toBe(true);
    expect(r.test('"w-fit rounded-3xl border"')).toBe(true);
  });

  it("ignores the radii in the role scale", () => {
    expect(r.test('"rounded-full rounded-2xl rounded-xl rounded-lg rounded-md"')).toBe(false);
  });

  it("is an error", () => {
    expect(r.severity).toBe("error");
  });

  it("allows test files", () => {
    expect(r.allow("src/components/ui/button.test.tsx")).toBe(true);
  });
});

describe("existing rules are preserved", () => {
  it("keeps the previous rule ids", () => {
    const ids = RULES.map((r) => r.id);
    expect(ids).toEqual(
      expect.arrayContaining([
        "h1-font-bold",
        "h1-font-semibold",
        "tailwind-palette-bg",
        "tailwind-palette-text",
        "hardcoded-spanish-ui",
      ]),
    );
  });
});
```

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `pnpm exec vitest run scripts/design-system-rules.test.mjs`
Expected: FAIL — `Failed to resolve import "./design-system-rules.mjs"`.

- [ ] **Step 3: Crear el módulo de reglas**

Crear `scripts/design-system-rules.mjs` moviendo las 5 reglas existentes **sin cambios** desde `scripts/audit-design-system.mjs` y agregando las dos nuevas al final:

```js
/**
 * Rules for scripts/audit-design-system.mjs.
 * Each rule is line-based: `test(line)` returns true on a violation and
 * `allow(relativePath)` skips files where the rule does not apply.
 */

const isTestFile = (file) => /\.test\.(?:t|j|mj)sx?$/.test(file);

const TRACKING = String.raw`tracking-(?:wide|wider|widest|\[[^\]\s]+\])`;
const UPPERCASE_RE = /(?:^|[\s"'`])uppercase(?=[\s"'`]|$)/;
const TRACKING_RE = new RegExp(String.raw`(?:^|[\s"'\x60:])${TRACKING}(?=[\s"'\x60]|$)`);
const PILL_RADIUS_RE = /(?:^|[\s"'`:])rounded-(?:3xl|4xl)!?(?=[\s"'`]|$)/;

/** @type {Array<{ id: string, severity: "error" | "warn", description: string, test: (line: string) => boolean, allow: (file: string) => boolean }>} */
export const RULES = [
  {
    id: "h1-font-bold",
    severity: "error",
    description: "h1 must not use font-bold (use PageHeader + font-display font-normal)",
    test: (line) => /<h1\b[^>]*\bfont-bold\b/i.test(line),
    allow: (file) =>
      file.includes("page-header.tsx") ||
      file.endsWith(".test.tsx"),
  },
  {
    id: "h1-font-semibold",
    severity: "warn",
    description: "h1 should use PageHeader or font-display font-normal",
    test: (line) => /<h1\b[^>]*\bfont-semibold\b/i.test(line),
    allow: (file) =>
      file.includes("page-header.tsx") ||
      file.endsWith(".test.tsx"),
  },
  {
    id: "tailwind-palette-bg",
    severity: "warn",
    description: "Prefer semantic tokens over Tailwind palette bg-* colors",
    test: (line) =>
      /\bbg-(?:slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-\d{2,3}\b/.test(
        line,
      ),
    allow: () => false,
  },
  {
    id: "tailwind-palette-text",
    severity: "warn",
    description: "Prefer semantic tokens over Tailwind palette text-* colors",
    test: (line) =>
      /\btext-(?:slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-\d{2,3}\b/.test(
        line,
      ),
    allow: () => false,
  },
  {
    id: "hardcoded-spanish-ui",
    severity: "warn",
    description: "Possible hardcoded Spanish UI string in JSX props (use next-intl)",
    test: (line) => {
      if (!/^\s*(?:title|description|label|aria-label|placeholder)=/.test(line)) {
        return false;
      }
      if (/useTranslations|getTranslations|\{t\(/.test(line)) return false;
      return /[áéíóúñÁÉÍÓÚÑ¿¡]/.test(line) || /\b(Editar|Eliminar|Volver|Nuevo|No se pudo)\b/.test(line);
    },
    allow: (file) => file.endsWith(".test.tsx"),
  },
  {
    id: "uppercase-tracking",
    severity: "warn",
    description: "Labels use sentence case: no uppercase + tracking-* (DESIGN-SYSTEM.md §3.2, antislop R-06)",
    test: (line) => UPPERCASE_RE.test(line) && TRACKING_RE.test(line),
    allow: isTestFile,
  },
  {
    id: "pill-radius",
    severity: "error",
    description: "rounded-3xl/4xl are not in the role-based radius scale (DESIGN-SYSTEM.md §4.1)",
    test: (line) => PILL_RADIUS_RE.test(line),
    allow: isTestFile,
  },
];
```

Nota: `\x60` es el backtick dentro de `String.raw` + `RegExp`; en los literales `/.../` se usa el backtick directo.

- [ ] **Step 4: Usar el módulo en el script**

En `scripts/audit-design-system.mjs`:

1. Agregar el import debajo de `import path from "node:path";`:

```js
import { RULES } from "./design-system-rules.mjs";
```

2. Borrar completo el bloque `const RULES = [ ... ];` (líneas 23-73 actuales, desde `const RULES = [` hasta su `];`). El resto del script no cambia.

- [ ] **Step 5: Correr los tests y verificar que pasan**

Run: `pnpm exec vitest run scripts/design-system-rules.test.mjs`
Expected: PASS, 9 tests.

- [ ] **Step 6: Verificar que el audit detecta los pills existentes**

Run: `node scripts/audit-design-system.mjs --strict; echo "exit:$?"`
Expected: `pill-radius` con ~45 errores, `uppercase-tracking` con ~242 warnings, `exit:1`. Esto es correcto: las tareas 2-3 lo dejan en 0.

- [ ] **Step 7: Commit**

```bash
git add scripts/design-system-rules.mjs scripts/design-system-rules.test.mjs scripts/audit-design-system.mjs
git commit -m "test(audit): extract design system rules and flag pill radius and uppercase tracking"
```

---

### Task 2: Primitivos con un solo token a cambiar

**Files (Modify):** `src/components/ui/{button,button-group,input,input-otp,native-select,toggle,toggle-group,badge,progress,slider,dialog,alert-dialog,drawer,card,popover,hover-card,accordion,item,attachment,textarea,bubble}.tsx`

En estos archivos todas las apariciones del token tienen el mismo rol, así que el reemplazo por archivo completo es seguro (verificado el 2026-10-13).

- [ ] **Step 1: Controles → `rounded-lg`**

```bash
sd -s 'rounded-4xl' 'rounded-lg' src/components/ui/button.tsx src/components/ui/button-group.tsx src/components/ui/input.tsx src/components/ui/input-otp.tsx src/components/ui/native-select.tsx src/components/ui/toggle.tsx src/components/ui/toggle-group.tsx
sd -s 'rounded-xl' 'rounded-lg' src/components/ui/textarea.tsx
```

- [ ] **Step 2: Etiquetas / estado → `rounded-full`**

```bash
sd -s 'rounded-4xl' 'rounded-full' src/components/ui/badge.tsx src/components/ui/progress.tsx src/components/ui/slider.tsx
```

- [ ] **Step 3: Overlays → `rounded-2xl`**

```bash
sd -s 'rounded-4xl' 'rounded-2xl' src/components/ui/dialog.tsx src/components/ui/alert-dialog.tsx src/components/ui/drawer.tsx
```

- [ ] **Step 4: Superficies → `rounded-xl`**

```bash
sd -s 'rounded-2xl' 'rounded-xl' src/components/ui/card.tsx src/components/ui/popover.tsx src/components/ui/hover-card.tsx src/components/ui/accordion.tsx src/components/ui/item.tsx src/components/ui/attachment.tsx
sd -s 'rounded-3xl' 'rounded-xl' src/components/ui/bubble.tsx
```

- [ ] **Step 5: Verificar**

Run: `rg -n 'rounded-(3xl|4xl)' src/components/ui/{button,button-group,input,input-otp,native-select,toggle,toggle-group,badge,progress,slider,dialog,alert-dialog,drawer,bubble}.tsx`
Expected: sin resultados.

Run: `rg -n 'rounded-2xl' src/components/ui/{card,popover,hover-card,accordion,item,attachment}.tsx`
Expected: sin resultados.

- [ ] **Step 6: Commit**

```bash
git add src/components/ui
git commit -m "style(ui): apply role-based radius to single-role primitives"
```

---

### Task 3: Primitivos con varios roles en el mismo archivo

**Files (Modify):** `src/components/ui/{dropdown-menu,context-menu,menubar,select,combobox,command,navigation-menu,input-group,tooltip,tabs,sidebar}.tsx`, `src/components/dashboard/dashboard-version-switch.tsx`

**El orden de los comandos importa**: siempre primero `rounded-xl → rounded-lg` (ítems) y después `rounded-2xl → rounded-xl` (contenedores). Si se invierte, los contenedores terminan en `rounded-lg`.

- [ ] **Step 1: Menús (contenido `2xl→xl`, ítems `xl→lg`)**

```bash
for f in src/components/ui/dropdown-menu.tsx src/components/ui/context-menu.tsx; do
  sd -s 'rounded-xl' 'rounded-lg' "$f"
  sd -s 'rounded-2xl' 'rounded-xl' "$f"
done
```

- [ ] **Step 2: Menubar (barra `4xl→lg`, trigger e ítems `xl→lg`, contenido `2xl→xl`)**

```bash
sd -s 'rounded-xl' 'rounded-lg' src/components/ui/menubar.tsx
sd -s 'rounded-2xl' 'rounded-xl' src/components/ui/menubar.tsx
sd -s 'rounded-4xl' 'rounded-lg' src/components/ui/menubar.tsx
```

- [ ] **Step 3: Select (trigger `4xl→lg`, ítem `xl→lg`, contenido `2xl→xl`)**

```bash
sd -s 'rounded-xl' 'rounded-lg' src/components/ui/select.tsx
sd -s 'rounded-2xl' 'rounded-xl' src/components/ui/select.tsx
sd -s 'rounded-4xl' 'rounded-lg' src/components/ui/select.tsx
```

- [ ] **Step 4: Combobox (chip `4xl→full`, input `4xl→lg`, ítem `xl→lg`, contenido `2xl→xl`)**

```bash
sd -s 'gap-1 rounded-4xl bg-muted-foreground' 'gap-1 rounded-full bg-muted-foreground' src/components/ui/combobox.tsx
sd -s 'rounded-4xl' 'rounded-lg' src/components/ui/combobox.tsx
sd -s 'rounded-xl' 'rounded-lg' src/components/ui/combobox.tsx
sd -s 'rounded-2xl' 'rounded-xl' src/components/ui/combobox.tsx
```

- [ ] **Step 5: Command (raíz = superficie `xl`, en dialog = overlay `2xl`, ítem en dialog `lg`)**

```bash
sd -s 'in-data-[slot=dialog-content]:rounded-2xl' 'in-data-[slot=dialog-content]:rounded-lg' src/components/ui/command.tsx
sd -s 'rounded-4xl!' 'rounded-2xl!' src/components/ui/command.tsx
sd -s 'overflow-hidden rounded-4xl bg-popover' 'overflow-hidden rounded-xl bg-popover' src/components/ui/command.tsx
```

- [ ] **Step 6: Navigation menu (trigger y link `lg`, contenido y viewport `xl`)**

```bash
sd -s 'justify-center rounded-2xl px-4.5' 'justify-center rounded-lg px-4.5' src/components/ui/navigation-menu.tsx
sd -s 'gap-1.5 rounded-2xl p-3' 'gap-1.5 rounded-lg p-3' src/components/ui/navigation-menu.tsx
sd -s 'rounded-xl' 'rounded-lg' src/components/ui/navigation-menu.tsx
sd -s 'rounded-2xl' 'rounded-xl' src/components/ui/navigation-menu.tsx
```

- [ ] **Step 7: Input group (kbd `full`, grupo y botón `lg`)**

```bash
sd -s '**:data-[slot=kbd]:rounded-4xl' '**:data-[slot=kbd]:rounded-full' src/components/ui/input-group.tsx
sd -s 'rounded-4xl' 'rounded-lg' src/components/ui/input-group.tsx
sd -s 'rounded-2xl' 'rounded-lg' src/components/ui/input-group.tsx
sd -s 'has-[textarea]:rounded-xl' 'has-[textarea]:rounded-lg' src/components/ui/input-group.tsx
```

- [ ] **Step 8: Tooltip (kbd `full`, contenido `xl`)**

```bash
sd -s '**:data-[slot=kbd]:rounded-4xl' '**:data-[slot=kbd]:rounded-full' src/components/ui/tooltip.tsx
sd -s 'rounded-2xl' 'rounded-xl' src/components/ui/tooltip.tsx
```

- [ ] **Step 9: Tabs (lista `lg`, trigger concéntrico `md`)**

```bash
sd -s 'justify-center rounded-4xl p-[3px]' 'justify-center rounded-lg p-[3px]' src/components/ui/tabs.tsx
sd -s 'group-data-vertical/tabs:rounded-2xl' 'group-data-vertical/tabs:rounded-lg' src/components/ui/tabs.tsx
sd -s 'justify-center gap-1.5 rounded-xl' 'justify-center gap-1.5 rounded-md' src/components/ui/tabs.tsx
```

- [ ] **Step 10: Sidebar (badge `full`, ítems y acciones `md→lg`)**

```bash
sd -s 'rounded-md px-1 ' 'rounded-full px-1 ' src/components/ui/sidebar.tsx
sd -s 'rounded-md' 'rounded-lg' src/components/ui/sidebar.tsx
```

- [ ] **Step 11: Version switch del dashboard (contenedor `lg`, botones concéntricos `md`)**

```bash
sd -s 'items-center rounded-4xl bg-muted' 'items-center rounded-lg bg-muted' src/components/dashboard/dashboard-version-switch.tsx
sd -s 'className="rounded-4xl"' 'className="rounded-md"' src/components/dashboard/dashboard-version-switch.tsx
```

- [ ] **Step 12: Verificar que no queda ningún pill**

Run: `rg -n 'rounded-(3xl|4xl)' src`
Expected: sin resultados.

Run: `node scripts/audit-design-system.mjs --strict; echo "exit:$?"`
Expected: `Errors: 0`, `uppercase-tracking` con ~242 warnings (se resuelve en PR 2), `exit:0`.

- [ ] **Step 13: Revisar el diff de los archivos multirol**

Run: `git diff --word-diff=color -- src/components/ui/navigation-menu.tsx src/components/ui/combobox.tsx src/components/ui/command.tsx src/components/ui/input-group.tsx`
Expected, por archivo:
- `navigation-menu`: trigger (`h-9 w-max`) y link (`p-3`) en `rounded-lg`; viewport y content en `rounded-xl`.
- `combobox`: content `rounded-xl`, ítem `rounded-lg`, input chips `rounded-lg`, chip `rounded-full`.
- `command`: raíz `rounded-xl`, dialog `rounded-2xl!`, ítem en dialog `rounded-lg`.
- `input-group`: grupo, block-start/end, textarea y botón en `rounded-lg`; kbd `rounded-full`.

Si algo no coincide, corregirlo a mano antes de seguir.

- [ ] **Step 14: Commit**

```bash
git add src/components/ui src/components/dashboard/dashboard-version-switch.tsx
git commit -m "style(ui): apply role-based radius to multi-role primitives"
```

---

### Task 4: Verificación del código del PR 1

- [ ] **Step 1: Tests que afirman clases**

Run: `rg -ln 'rounded-(3xl|4xl|2xl|xl|lg|md|full)' src -g '*.test.*'`
Expected: lista (posiblemente vacía). Para cada archivo listado, revisar si afirma un radio que cambió y actualizar la expectativa al radio nuevo de la escala.

- [ ] **Step 2: Suite completa**

Run: `pnpm typecheck && pnpm lint && pnpm test`
Expected: los tres terminan sin errores.

- [ ] **Step 3: Commit (solo si el Step 1 cambió tests)**

```bash
git add src
git commit -m "test(ui): update radius assertions to the role-based scale"
```

---

### Task 5: DS, puntero para agentes y diales

**Files:**
- Modify: `DESIGN-SYSTEM.md` (cabecera de changelog, §4.1 líneas 212-224, §5.5 línea 439, §5.6 línea 455, §20 checklist, sección nueva antes de `## 1. Stack de UI`)
- Modify: `AGENTS.md:36`
- Modify: `CLAUDE.md:109`

- [ ] **Step 1: Reemplazar §4.1**

Reemplazar desde `### 4.1 Radios de Borde` hasta la línea `**No** uses \`rounded-md\` en buttons/inputs nuevos: el primitivo es \`rounded-4xl\`.` (inclusive) por:

```markdown
### 4.1 Radios de Borde

Base `0.625rem` (10px) en `globals.css`; `rounded-lg` equivale a `--radius`. El radio se elige por **rol**, no por gusto: crece con el tamaño del contenedor y el pill queda reservado para etiquetas.

| Rol | Clase | Componentes |
|-----|-------|-------------|
| Etiqueta / estado | `rounded-full` | Badge, StatusBadge, Avatar, Switch, Radio, Progress, Slider, dots, kbd |
| Control | `rounded-lg` | Button, Input, InputGroup, InputOTP, Select trigger, NativeSelect, Combobox, Textarea, Toggle, ToggleGroup, Tabs list, Menubar, ítems del Sidebar |
| Ítem dentro de superficie | `rounded-lg` | Ítems de DropdownMenu, ContextMenu, Menubar, Select, Combobox, Command |
| Superficie | `rounded-xl` | Card, tabla contenedora, Popover, HoverCard, menús, Select/Combobox content, Command, Tooltip, Accordion, Item, Skeleton |
| Overlay | `rounded-2xl` | Dialog, AlertDialog, Drawer, Command en dialog |
| Interno concéntrico | `rounded-md` | Tab trigger y botones dentro de un contenedor con `p-[3px]` |

**Prohibido**: `rounded-3xl` y `rounded-4xl`. `pnpm audit:design-system --strict` falla con la regla `pill-radius`. `Sheet` no lleva radio (panel pegado al borde).
```

- [ ] **Step 2: Actualizar §5.5 y §5.6**

```bash
sd -s -- '- Border radius: `rounded-4xl`' '- Border radius: `rounded-lg` (control, ver §4.1)' DESIGN-SYSTEM.md
sd -s -- '- Mismo estilo que Input (`h-9`, `rounded-4xl`)' '- Mismo estilo que Input (`h-9`, `rounded-lg`)' DESIGN-SYSTEM.md
```

- [ ] **Step 3: Agregar la sección "Dirección antislop"**

Insertar justo antes de la línea `## 1. Stack de UI`:

```markdown
## 0. Dirección antislop

Este documento es el `DESIGN.md` que espera el plugin antislop: la **dirección** del panel. antislop es el **filtro**. Si una regla de antislop choca con algo de aquí, se respeta esto y se anota la excepción.

Dial: ENERGY 1 / RHYTHM 2 / MOTION 1

- **ENERGY 1**: herramienta de trabajo; calmada, sin decoración que compita con los datos.
- **RHYTHM 2**: cada sección toma la composición que pide su contenido; no se repite la misma plantilla de cards en toda la pantalla.
- **MOTION 1**: solo hover/focus y transiciones funcionales (ver §9). Sin loops ni animaciones de entrada decorativas.

Decisiones con razón escrita:

- **Fuente — Geist** en todo el panel: sans neutra y legible para un panel denso en datos, con pesos reales y una variante mono pareada (Geist Mono) para valores tabulares y código.
- **Iconos — Hugeicons**: decisión de identidad del panel, no default de librería. El alias `lucide-react` es solo compatibilidad (§8).
- **Radios por rol**: ver §4.1.
- **Labels en sentence case**: sin `uppercase` + `tracking-*` (ver §3.2).

---

```

- [ ] **Step 4: Changelog en la cabecera**

Insertar después de la línea `> **Actualizado 2026-06-24 — Alineación con SACDIA App**. Paleta desde ...` y su lista (antes de la primera línea `---`), un bloque nuevo:

```markdown
> **Actualizado 2026-10-13 — Alineación antislop**. Radios por rol (§4.1), sin `rounded-3xl`/`rounded-4xl`. Labels en sentence case, sin `uppercase` + `tracking-*` (§3.2). Nueva §0 con diales y razones de Geist/Hugeicons. Audit: reglas `pill-radius` (error) y `uppercase-tracking`.
```

- [ ] **Step 5: Checklist §20**

Agregar estas dos líneas al final de la lista de `## 20. Checklist para Nuevas Interfaces`:

```markdown
- [ ] Radios según el rol del elemento (§4.1); nada de `rounded-3xl`/`rounded-4xl`
- [ ] Labels y encabezados en sentence case, sin `uppercase` + `tracking-*`
```

- [ ] **Step 6: Puntero en `AGENTS.md`**

Debajo de la línea `## Design system (DESIGN-SYSTEM.md)` insertar (con una línea en blanco antes y después):

```markdown
`DESIGN-SYSTEM.md` es la dirección de diseño del panel: el `DESIGN.md` que espera antislop. Para trabajo de UI, léelo primero (§0 trae los diales) y usa antislop como filtro.
```

- [ ] **Step 7: Puntero en `CLAUDE.md`**

```bash
sd -s -- '- Design system: `DESIGN-SYSTEM.md`' '- Design system: `DESIGN-SYSTEM.md` (también es el `DESIGN.md` de antislop: dirección de UI y diales en §0)' CLAUDE.md
```

- [ ] **Step 8: Verificar**

Run: `rg -n 'rounded-4xl|rounded-3xl' DESIGN-SYSTEM.md`
Expected: solo la línea de "**Prohibido**" en §4.1.

Run: `rg -n 'Dial: ENERGY' DESIGN-SYSTEM.md`
Expected: 1 resultado en §0.

- [ ] **Step 9: Commit**

```bash
git add DESIGN-SYSTEM.md AGENTS.md CLAUDE.md
git commit -m "docs(design-system): document role-based radius and antislop direction"
```

---

### Task 6: Cerrar PR 1

- [ ] **Step 1: Verificación final**

Run: `node scripts/audit-design-system.mjs --strict; echo "exit:$?"`
Expected: `Errors: 0`, `exit:0`.

- [ ] **Step 2: Revisión visual (dueño)**

Con `pnpm dev` corriendo (puerto 3001), el dueño revisa en light y dark: login, dashboard, una página CRUD de catálogo, un formulario, un dialog, un dropdown, una tabla, el sidebar.

- [ ] **Step 3: Push y PR** (solo cuando el dueño lo pida)

```bash
git push -u origin feat/antislop-radius-scale
gh pr create --base development --title "style(ui): role-based radius scale and antislop direction" --body "Implements PR 1 of docs/superpowers/specs/2026-10-13-admin-visual-foundation-design.md: role-based radius in ui primitives, antislop direction in DESIGN-SYSTEM.md, and audit rules pill-radius (error) and uppercase-tracking (warn)."
```

---

# PR 2 — Labels en sentence case

### Task 7: Rama encadenada

- [ ] **Step 1: Crear rama desde la del PR 1**

```bash
git checkout feat/antislop-radius-scale
git checkout -b feat/antislop-sentence-case-labels
```

---

### Task 8: Promover `uppercase-tracking` a error (test primero)

**Files:**
- Modify: `scripts/design-system-rules.test.mjs`
- Modify: `scripts/design-system-rules.mjs`

- [ ] **Step 1: Cambiar el test**

En `scripts/design-system-rules.test.mjs`, reemplazar:

```js
  it("is a warning until the sentence-case migration lands", () => {
    expect(r.severity).toBe("warn");
  });
```

por:

```js
  it("is an error", () => {
    expect(r.severity).toBe("error");
  });
```

- [ ] **Step 2: Verificar que falla**

Run: `pnpm exec vitest run scripts/design-system-rules.test.mjs`
Expected: FAIL — `expected 'warn' to be 'error'`.

- [ ] **Step 3: Cambiar la severidad**

En `scripts/design-system-rules.mjs`, dentro de la regla `id: "uppercase-tracking"`, cambiar `severity: "warn",` por `severity: "error",`.

- [ ] **Step 4: Verificar que pasa**

Run: `pnpm exec vitest run scripts/design-system-rules.test.mjs`
Expected: PASS.

Run: `node scripts/audit-design-system.mjs --strict; echo "exit:$?"`
Expected: ~242 errores `uppercase-tracking`, `exit:1`. La tarea 9 los elimina.

- [ ] **Step 5: Commit**

```bash
git add scripts/design-system-rules.mjs scripts/design-system-rules.test.mjs
git commit -m "test(audit): make uppercase tracking an error"
```

---

### Task 9: Codemod de mayúsculas

**Files:** ~80 archivos `src/**/*.tsx` (inventario: 202 `tracking-wider`, 22 `tracking-wide`, 18 arbitrarios). Ninguno en `src/components/ui/`.

Reglas del codemod, solo en líneas que tengan `uppercase` **y** `tracking-(wide|wider|widest|[...])`:
- Quitar el token `uppercase` y el token `tracking-*`.
- `text-[9px]` y `text-[10px]` → `text-xs` (sin mayúsculas, menos de 12px no se lee). `text-[11px]` se queda (está en la escala como micro texto).
- El resto de clases no se toca.

- [ ] **Step 1: Crear el codemod fuera del repo**

Crear `/tmp/antislop-codemod/strip-uppercase-tracking.mjs` (no se commitea):

```js
#!/usr/bin/env node
// Usage: node strip-uppercase-tracking.mjs <srcDir>
import { readdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";

const BOUNDARY_AFTER = String.raw`(?=[\s"'\x60]|$)`;
const TRACKING = String.raw`tracking-(?:wide|wider|widest|\[[^\]\s]+\])`;
const TOKEN = String.raw`(?:uppercase|${TRACKING})`;

const HAS_UPPERCASE = new RegExp(String.raw`(?:^|[\s"'\x60])uppercase${BOUNDARY_AFTER}`);
const HAS_TRACKING = new RegExp(String.raw`(?:^|[\s"'\x60])${TRACKING}${BOUNDARY_AFTER}`);
const TOKEN_AFTER_SPACE = new RegExp(String.raw` ${TOKEN}${BOUNDARY_AFTER}`, "g");
const TOKEN_AT_STRING_START = new RegExp(String.raw`(["'\x60])${TOKEN}${BOUNDARY_AFTER} ?`, "g");
const TINY_TEXT = /\btext-\[(?:9|10)px\]/g;

async function walk(dir) {
  const entries = await readdir(dir, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    if (entry.name === "node_modules" || entry.name === ".next") continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) files.push(...(await walk(full)));
    else if (full.endsWith(".tsx") && !full.endsWith(".test.tsx")) files.push(full);
  }
  return files;
}

function transformLine(line) {
  if (!HAS_UPPERCASE.test(line) || !HAS_TRACKING.test(line)) return line;
  return line
    .replace(TOKEN_AFTER_SPACE, "")
    .replace(TOKEN_AT_STRING_START, "$1")
    .replace(TINY_TEXT, "text-xs");
}

const root = path.resolve(process.argv[2] ?? "src");
let changedFiles = 0;
let changedLines = 0;

for (const file of await walk(root)) {
  const original = await readFile(file, "utf8");
  const lines = original.split("\n");
  const next = lines.map(transformLine);
  const diff = next.filter((l, i) => l !== lines[i]).length;
  if (diff > 0) {
    await writeFile(file, next.join("\n"));
    changedFiles += 1;
    changedLines += diff;
  }
}

console.log(`Changed ${changedLines} lines in ${changedFiles} files`);
```

- [ ] **Step 2: Correr el codemod**

Run: `node /tmp/antislop-codemod/strip-uppercase-tracking.mjs src`
Expected: `Changed 242 lines in 80 files` (±2 si hubo cambios en `development` desde el 2026-10-13).

- [ ] **Step 3: Verificar que no quedan combinaciones**

Run: `rg -n 'uppercase' src -g '*.tsx' | rg 'tracking-(wide|wider|widest|\[)'`
Expected: sin resultados.

Run: `rg -n 'uppercase' src -g '*.tsx'`
Expected: solo los 2 usos sueltos fuera de alcance (`activities-calendar-grid.tsx:150`, `users/detail/contacts-block.tsx:83`).

- [ ] **Step 4: Revisar espacios y comillas**

Run: `git diff -U0 | rg '^\+[^+]' | rg '="\s|\("\s|[a-z0-9\]] {2,}[a-z]|[a-z0-9\]] "$'`
Expected: sin resultados (sin clases que empiecen con espacio, sin espacios dobles entre clases, sin espacio antes de la comilla de cierre). Si aparece alguno, corregirlo a mano.

- [ ] **Step 5: Muestra manual**

Run: `git diff -- src/components/scoring-categories/scoring-categories-table.tsx src/components/campamentos/campamentos-judges-client.tsx src/components/activities/activities-calendar-grid.tsx`
Expected:
- `scoring-categories-table.tsx`: `h-9 px-3 text-xs font-medium text-muted-foreground`.
- `campamentos-judges-client.tsx`: `text-[11px] font-medium text-muted-foreground`.
- `activities-calendar-grid.tsx:191`: `px-2 py-2 text-center text-xs font-medium text-muted-foreground`; la línea 150 sigue igual.

- [ ] **Step 6: i18n**

Verificado el 2026-10-13: los únicos valores en mayúsculas en `messages/*.json` son siglas (`CLABE`, `HTTP`), que se quedan. Confirmar que no entraron nuevos:

Run: `rg -n ':\s*"[A-ZÁÉÍÓÚÑ][A-ZÁÉÍÓÚÑ ]{3,}"' messages/*.json | rg -v '"(CLABE|HTTP)"'`
Expected: sin resultados. Si aparece alguno que alimente un label afectado, pasarlo a sentence case en los 4 idiomas.

- [ ] **Step 7: Suite y audit**

Run: `pnpm typecheck && pnpm lint && pnpm test`
Expected: sin errores. Si un test afirma texto o clases con `uppercase`, actualizar la expectativa.

Run: `node scripts/audit-design-system.mjs --strict; echo "exit:$?"`
Expected: `Errors: 0`, `exit:0`.

- [ ] **Step 8: Commit**

```bash
git add src
git commit -m "style(ui): use sentence case labels instead of uppercase tracking"
```

---

### Task 10: DS — tipografía

**Files:** `DESIGN-SYSTEM.md` (§3.2 líneas 187, 192, 194; §5.4 línea 430; §10.2 línea 1349)

- [ ] **Step 1: Reemplazos**

```bash
sd -s '| Nombre de seccion (sidebar) | `text-[10px] font-semibold uppercase tracking-widest` | 10px | 600 | widest |' '| Nombre de seccion (sidebar) | `text-xs font-medium text-muted-foreground` | 0.75rem | 500 | - |' DESIGN-SYSTEM.md
sd -s '| Label tipo tag | `text-xs font-medium uppercase tracking-wider` | 0.75rem | 500 | wider |' '| Label tipo tag | `text-xs font-medium` | 0.75rem | 500 | - |' DESIGN-SYSTEM.md
sd -s '| Table header | `text-xs font-medium uppercase tracking-wider text-muted-foreground` | 0.75rem | 500 | wider |' '| Table header | `text-xs font-medium text-muted-foreground` | 0.75rem | 500 | - |' DESIGN-SYSTEM.md
sd -s '**Estilos de cabecera:** `h-9 px-3 text-xs font-medium uppercase tracking-wider text-muted-foreground`' '**Estilos de cabecera:** `h-9 px-3 text-xs font-medium text-muted-foreground`' DESIGN-SYSTEM.md
sd -s -- '- Grupos separados por `Separator` y labels `text-[10px] uppercase`' '- Grupos separados por `Separator` y labels `text-xs font-medium text-muted-foreground`' DESIGN-SYSTEM.md
```

- [ ] **Step 2: Regla en §3.3**

Agregar al final de la lista `### 3.3 Reglas Tipograficas`:

```markdown
- Labels, encabezados de tabla y nombres de sección en sentence case: nunca `uppercase` + `tracking-*` (regla `uppercase-tracking` del audit)
- Nada por debajo de `text-[11px]`
```

- [ ] **Step 3: Verificar**

Run: `rg -n 'uppercase' DESIGN-SYSTEM.md`
Expected: solo la línea de §7.4 sobre la migración del enum de evidencias (texto histórico, no es una clase) y las reglas nuevas que mencionan `uppercase` como prohibido.

- [ ] **Step 4: Commit**

```bash
git add DESIGN-SYSTEM.md
git commit -m "docs(design-system): document sentence case labels"
```

---

### Task 11: Cerrar PR 2

- [ ] **Step 1: Revisión visual (dueño)**: tablas, sidebar, calendario de actividades, jueces de camporee, en light y dark.

- [ ] **Step 2: Push y PR** (solo cuando el dueño lo pida)

```bash
git push -u origin feat/antislop-sentence-case-labels
gh pr create --base feat/antislop-radius-scale --title "style(ui): sentence case labels" --body "Implements PR 2 of docs/superpowers/specs/2026-10-13-admin-visual-foundation-design.md: removes uppercase + tracking-* from ~242 labels via a one-off codemod and makes the uppercase-tracking audit rule an error. Stacked on feat/antislop-radius-scale."
```

Nota de tamaño: el diff es ~484 líneas cambiadas, todas mecánicas y de una sola clase. Pasa del presupuesto de 400; pedir `size:exception` al revisor o, si lo rechaza, dividir el commit de la tarea 9 por carpeta de primer nivel en `src/components/`.
