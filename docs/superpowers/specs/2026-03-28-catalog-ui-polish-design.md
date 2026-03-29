# Catalog UI Polish — Design Spec

## Scope
Visual polish of the entire catalog system in sacdia-admin. No architectural changes, no new dependencies, no backend changes.

## Approach
Enfoque A: Polish visual sobre componentes existentes.

## Files to Modify

| File | Change |
|------|--------|
| `src/app/(dashboard)/dashboard/catalogs/page.tsx` | Index page redesign |
| `src/components/catalogs/catalog-crud-page.tsx` | Table + header polish |
| `src/components/catalogs/catalog-form-dialog.tsx` | Form dialog refinement |
| `src/components/catalogs/catalog-delete-dialog.tsx` | Delete confirmation polish |

## Files NOT Modified
- Entity configs (`entities.ts`), server actions, service layer, auth, API endpoints

---

## 1. Catalogs Index Page

### Current
- Cards with gray icons, title, description
- Grid 1→2→3 columns
- Two sections: Geografía, Datos de referencia

### Target
- Each card gets a **colored icon container** (emerald for geo, blue/amber/violet for reference data) — same pattern as dashboard stat cards
- **Hover effect**: `hover:-translate-y-0.5 hover:shadow-md transition-all` + arrow icon `group-hover:translate-x-0.5`
- **Section headers**: Cleaner separator, muted label with icon
- **Card descriptions**: Shorter, more actionable text in `text-muted-foreground`
- **Read-only badge**: For club-types and club-ideals cards, show a small "Solo lectura" badge

### Constraints
- Keep Link component wrapping each card
- Keep the same grid responsive breakpoints
- Use only existing shadcn/ui components (Card, Badge) + lucide-react icons

---

## 2. CatalogCrudPage (CRUD Table)

### Current
- PageHeader with title + description + create button
- Basic table with columns from entity config
- Action buttons (edit/delete) per row
- Simple empty state

### Target

#### Page Header
- Title in `text-2xl font-semibold tracking-tight`
- Description in `text-muted-foreground`
- **Badge** next to title showing item count (e.g., "24 items")
- Create button: `size="default"` with Plus icon, not `size="sm"`

#### Table
- `hover:bg-muted/50 transition-colors` on rows
- Status column: Use Badge component variants — `variant="success"` for active, `variant="secondary"` for inactive (uses existing custom Badge variants)
- Better cell padding and text alignment
- Header cells in `text-muted-foreground font-medium text-xs uppercase tracking-wide`

#### Empty State
- Larger icon (48px) in muted circular container
- Bolder title, descriptive subtitle
- CTA button prominent with Plus icon

### Constraints
- Keep server component pattern (CatalogEntityPage feeds data to client CatalogCrudPage)
- Keep existing action buttons functionality
- Keep read-only mode support (`allowMutations: false`)

---

## 3. Form Dialog (Create/Edit)

### Current
- Dialog with stacked fields, basic styling
- Checkbox with hidden input pattern
- Error display with red text
- Cancel + Submit buttons

### Target
- **Dialog header**: Icon (PenLine for edit, Plus for create) + "Crear [singular]" / "Editar [singular]"
- **Field spacing**: `space-y-5` instead of `space-y-4`
- **Labels**: `font-medium text-sm` with subtle red asterisk for required (`text-destructive/70`)
- **Inputs**: Clean focus ring using shadcn defaults
- **Error state**: Alert-style box with `AlertCircle` icon, `bg-destructive/10 text-destructive` rounded container
- **Footer buttons**: Cancel as `variant="ghost"`, Submit as `variant="default"` with icon (Plus for create, Check for edit)
- **Loading state**: Loader2 spinner + "Guardando..." text on submit button

### Constraints
- Keep `useActionState` form pattern
- Keep hidden input for checkbox state
- Keep all existing field type support (text, number, date, textarea, checkbox, select)

---

## 4. Delete Dialog

### Current
- AlertDialog with text description
- Cancel + Delete buttons
- Error display

### Target
- **Warning icon**: `AlertTriangle` in `text-destructive` centered above title
- **Title**: "Eliminar [singular]"
- **Description**: Item name in `font-semibold` within the confirmation text
- **Delete button**: `variant="destructive"` with `Trash2` icon
- **Loading state**: Loader2 spinner + "Eliminando..." text

### Constraints
- Keep AlertDialog component
- Keep server action form submission pattern
- Keep soft-delete explanation in description

---

## Design Tokens
All colors use existing semantic tokens from globals.css:
- `bg-muted`, `text-muted-foreground` for secondary content
- `bg-destructive/10`, `text-destructive` for errors/warnings
- Badge variants: `success`, `secondary`, `destructive` (already defined in project)
- Colored icon containers: `bg-emerald-500/10 text-emerald-600` etc. (same as dashboard)

## Dark Mode
All changes use semantic tokens or Tailwind opacity modifiers — dark mode works automatically.

## Testing
Visual only — no behavioral changes. Manual verification in browser.
