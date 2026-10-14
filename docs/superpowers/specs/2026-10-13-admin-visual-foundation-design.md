# Base visual del admin (alineación antislop) — Diseño

- **Fecha**: 2026-10-13
- **Repo**: `sacdia-admin`
- **Subproyecto**: 1 de 3 (1 base visual → 2 alcance de coordinador en backend → 3 rediseño del inicio por rol)
- **Estado**: aprobado para spec

## Contexto

Se instaló el plugin `antislop` (v3.2.20). Al compararlo con `sacdia-admin/DESIGN-SYSTEM.md` aparecieron choques. Decisiones del dueño:

| Tema | Decisión |
|---|---|
| Labels `uppercase` + `tracking-*` | Eliminar |
| Fuente Geist | Mantener, con razón escrita |
| Hugeicons | Mantener |
| Pill (`rounded-4xl`) en casi todo | Reemplazar por escala de radios por rol |
| Shell default del dashboard | Rediseñar (fuera de este spec, subproyecto 3) |

## Objetivo

Dejar la base visual del admin consistente con antislop para que el rediseño del inicio (subproyecto 3) se construya sobre ella, y evitar que los patrones eliminados regresen.

## Alcance

### A. Eliminar mayúsculas con tracking

Inventario actual en `src/**/*.tsx` (80 archivos, ninguno en `src/components/ui/`):

| Patrón | Usos |
|---|---|
| `uppercase tracking-wider` | 202 |
| `uppercase tracking-wide` | 22 |
| `uppercase tracking-[0.2em]` | 7 |
| `uppercase tracking-[0.14em]` | 7 |
| `uppercase tracking-[0.08em]` | 2 |
| `uppercase tracking-[0.16em]` | 1 |
| `uppercase tracking-[0.06em]` | 1 |

Reglas de reemplazo:

- Se quitan `uppercase` y la clase `tracking-*` que lo acompaña. El resto de clases (tamaño, peso, color) se conserva.
- Encabezado de tabla: `text-xs font-medium text-muted-foreground`.
- Nombre de sección del sidebar: `text-xs font-medium text-muted-foreground` (sube de `text-[10px]` a `text-xs`, que ya existe en la escala, para mantener legibilidad sin mayúsculas).
- Label tipo tag: `text-xs font-medium`.
- Strings i18n escritos en mayúsculas en `messages/{es,en,fr,pt-BR}.json` que alimenten esos labels se pasan a sentence case en los 4 idiomas.
- `uppercase` solo, sin `tracking-*`, queda fuera de alcance salvo que forme parte de los mismos labels (se revisa caso por caso en el mismo archivo).

### B. Escala de radios por rol

| Rol | Clase | Componentes en `src/components/ui/` |
|---|---|---|
| Etiqueta / estado | `rounded-full` | badge, progress, slider (track/range), avatar, switch, radio-group, dots, scroll-area thumb, carousel dots |
| Control | `rounded-lg` | button, button-group, input, input-group, input-otp, select trigger, native-select, combobox (input/trigger), toggle, toggle-group, tabs list/trigger, textarea, command input |
| Superficie | `rounded-xl` | card, popover, dropdown-menu content, context-menu content, menubar content, hover-card, select content, combobox content, command, tooltip, accordion, item, navigation-menu content, skeleton, attachment |
| Overlay | `rounded-2xl` | dialog, alert-dialog, drawer. `sheet` no cambia: es un panel pegado al borde y hoy no tiene radio |

Reglas:

- Ítems dentro de una superficie (menu item, select item, command item) usan `rounded-lg`, un nivel por debajo del contenedor.
- Las imágenes dentro de una card siguen el radio de la card (`*:[img:first-child]:rounded-t-xl` ya está bien).
- `rounded-4xl` y `rounded-3xl` desaparecen de `src/components/ui/`.
- Fuera de `ui/`, el único uso de `rounded-4xl` es `src/components/dashboard/dashboard-version-switch.tsx`; se alinea a la misma escala.
- `--radius: 0.625rem` no cambia. `rounded-lg` equivale a `--radius`.
- `sidebar.tsx`: los ítems de navegación (`rounded-md` hoy) son controles y pasan a `rounded-lg`.

### C. Actualizar `DESIGN-SYSTEM.md`

- §3.2: quitar las filas en mayúsculas (sección de sidebar, label tipo tag, table header) y documentar los reemplazos de A.
- §4.1: reemplazar la tabla de radios por la escala por rol de B. Quitar la nota "el primitivo es `rounded-4xl`".
- §5.4 y otros ejemplos de código que muestren `uppercase tracking-*` o `rounded-4xl`: actualizar.
- Nueva sección **"Dirección antislop"**:
  - **Fuente**: Geist en todo el panel. Razón: sans neutra y legible para un panel denso en datos, con pesos reales y una variante mono pareada (Geist Mono) para valores tabulares y código.
  - **Iconos**: Hugeicons como decisión, no como default de librería.
  - **Diales**: `Dial: ENERGY 1 / RHYTHM 2 / MOTION 1`. ENERGY 1: herramienta de trabajo, calmada. RHYTHM 2: las secciones varían su composición según el contenido, no repiten la misma plantilla de cards. MOTION 1: solo estados de hover/focus y transiciones funcionales, ya alineado con §9.
  - **Radios**: referencia a la escala por rol.
- Changelog en la cabecera: entrada 2026-10-13.

### D. Puntero para agentes

En `sacdia-admin/AGENTS.md` y `sacdia-admin/CLAUDE.md`, una línea: para trabajo de UI, `DESIGN-SYSTEM.md` es la dirección de diseño (el `DESIGN.md` que espera antislop).

### E. Prevención de regresión

Extender `scripts/audit-design-system.mjs` (`pnpm audit:design-system`) con dos reglas de severidad error:

1. `uppercase` en la misma clase que `tracking-*` dentro de `src/**/*.tsx`.
2. `rounded-4xl` o `rounded-3xl` en `src/**/*.tsx`.

Con `--strict` deben fallar. Tras aplicar A y B, el audit en `--strict` pasa limpio.

## Fuera de alcance

- Rediseño del inicio (subproyecto 3).
- Cambios de paleta, tipografía (familia) o iconografía.
- `uppercase` sin `tracking-*` fuera de los labels afectados.
- `sacdia-app` (Flutter) y `sacdia-admin-ios`.

## Entrega

Supera el presupuesto de 400 líneas por PR. Dos PRs encadenados sobre `development`:

1. **PR 1 — radios + DS + puntero + audit**: B, C, D, y la regla 2 de E. La regla 1 de E entra como `warning` para no romper CI.
2. **PR 2 — mayúsculas**: A + i18n, y la regla 1 de E sube a `error`.

## Verificación

- `pnpm typecheck`, `pnpm test`, `pnpm lint`.
- `pnpm audit:design-system --strict` limpio al final del PR 2.
- Tests que afirmen clases (`rounded-4xl`, `uppercase`) se actualizan.
- Revisión visual manual del dueño en light y dark: login, dashboard, una página CRUD de catálogo, un formulario, un dialog, un menú desplegable, una tabla.
- Por regla del dueño, el agente no ejecuta `pnpm build`.

## Riesgos

- **Cambio visual amplio**: los botones pierden el look pill. Aceptado por el dueño.
- **Snapshots/tests de clases**: pueden fallar; se actualizan en el mismo PR.
- **Strings i18n**: un label en mayúsculas en el JSON pasaría desapercibido si solo se tocan clases; por eso A incluye revisión de `messages/`.
