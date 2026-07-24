# Camporee Events — Timeline View (Variant K) — Admin Design

**Fecha**: 2026-05-20
**Estado**: PROPUESTO
**Alcance esta sesión**: Solo `sacdia-admin` frontend con datos mock. Sin tocar backend.
**Reemplaza**: contenido del tab "Eventos" en `/dashboard/camporees/[id]` (componente `camporee-events-tab.tsx`).
**Relación con feature existente**: el spec `docs/features/camporee-events.md` (competencias con puntaje, templates, participantes por clase) queda como dominio backend pendiente. La fase frontend de esta sesión usa un modelo de **agenda/timeline** distinto (días + horario + sede + responsable + secciones + categoría + estado) que **conceptualmente reemplaza** al tab actual una vez exista el backend correspondiente.

## 1. Objetivo

Portar la vista **Variant K · Timeline** entregada como rediseño (`~/Downloads/admin - camporee/camporees-admin`) al panel `sacdia-admin`, con datos mock parametrizables por contexto del camporee. Sirve como prototipo navegable para validar UX antes de definir el schema/API definitivo.

## 2. Decisiones clave

1. **Mock parametrizable, no hardcoded**: una función `buildMockEvents({ camporeeId, unionName, localFieldName?, camporeeType })` devuelve la estructura `CamporeeEventsData`. Los nombres de unión/campo provienen del contexto real del camporee.
2. **Tab actual se reescribe**: `camporee-events-tab.tsx` deja de renderizar la tabla y pasa a renderizar `<EventsTimelineView />`. Los componentes legacy (`event-template-form-page.tsx`, `event-template-list-client.tsx`, `participants-field.tsx`, `penalties-editor.tsx`) **no se borran** — siguen disponibles para la fase backend futura.
3. **Props legacy compat**: el tab sigue aceptando `camporeeId`, `initialEvents`, `availableTemplates`, `isUnionCamporee`, `canCreate`, `canEdit`, `canDelete` para no romper el call site en `page.tsx`. Los que no aplican al mock se ignoran con comentario `// TODO: wire backend`.
4. **Interactividad mínima**: drawer abre/cierra (state local), filtros del toolbar son cosméticos, acciones de fila son no-op con `console.log` placeholder. AlertDialog de delete se muestra pero no borra. Todo marcado `// TODO`.
5. **Tokens CSS nuevos**: `cat-*` (5 categorías), `section-*` (3 secciones), `warning-soft` + `warning-soft-foreground`. Definidos en `:root` y `.dark` de `globals.css`, expuestos vía `@theme inline` para Tailwind v4.
6. **Badge variants**: se verifica `badge.tsx` antes de codear. Si faltan `soft-info`, `soft-success`, `soft-warning`, `soft-destructive`, se agregan al CVA del componente.

## 3. Estructura de archivos

```
sacdia-admin/src/
├── lib/camporee-timeline/
│   ├── types.ts                 — Section, EventCategoryId, EventStatus, TemplateScope,
│   │                              CamporeeType, Venue, CamporeeDay, EventTemplate,
│   │                              CamporeeEvent, CamporeeEventsData
│   ├── event-categories.ts      — EVENT_CATEGORIES, EVENT_CATEGORY_MAP, EVENT_STATUS_LABEL,
│   │                              EVENT_STATUS_VARIANT, SECTION_COLOR
│   ├── mock-data.ts             — buildMockEvents({ camporeeId, unionName, localFieldName?,
│   │                              camporeeType }): CamporeeEventsData
│   └── helpers.ts               — toMin, durMin, initials, sortByStart, formatHours
├── components/camporee-events/
│   ├── timeline/
│   │   ├── events-timeline-view.tsx     — wrapper: KPIs + toolbar + day cards + drawer
│   │   ├── event-day-card.tsx           — header día + heatbar + rows + footer "+ agregar"
│   │   ├── event-row.tsx                — fila densa 8-col responsive
│   │   ├── events-toolbar.tsx           — search, filtros, export, crear/importar
│   │   ├── events-summary-kpis.tsx      — 4 KPIs (eventos, horas, catálogo, sedes)
│   │   └── create-event-drawer.tsx      — Sheet lateral con tabs Nuevo/Catálogo
│   └── camporee-events-tab.tsx          — REESCRITO: render <EventsTimelineView />
└── app/globals.css                       — + tokens cat-*, section-*, warning-soft
```

## 4. Modelo de datos (TypeScript)

Idéntico al `src/lib/types.ts` del rediseño:

- `Section = "Aventureros" | "Conquistadores" | "Guías Mayores"`
- `EventCategoryId = "espiritual" | "competencia" | "taller" | "ceremonial" | "social" | "logistico"`
- `EventStatus = "programado" | "publicado" | "curso" | "realizado" | "cancelado"`
- `CamporeeType = "union" | "local"`
- `Venue { id, name, capacity }`
- `CamporeeDay { id, numero, fecha, diaSemana, fechaFmt }`
- `CamporeeEvent { id, camporeeId, templateId, title, description, category, dayNumber, startsAt, endsAt, venueId, leaderName, leaderRole?, sections, capacity, registered, points, status, fromCatalog }`
- `EventTemplate { id, title, description, category, scope, scopeId, durationMin, sections, defaultPoints?, defaultCapacity?, createdBy, uses, lastUsedAt?, lastUsedAtCamporee? }`
- `CamporeeEventsData { camporeeId, camporeeType, unionName, localFieldName?, days, venues, events, templates, summary }`

## 5. Mock builder

Firma:

```ts
interface BuildMockArgs {
  camporeeId: string;
  camporeeType: CamporeeType;
  unionName: string;
  localFieldName?: string;
}
function buildMockEvents(args: BuildMockArgs): CamporeeEventsData
```

Comportamiento:
- Genera 5 días fijos a partir de fecha base `2026-07-15` (días Miércoles → Domingo). Fecha base se puede sobreescribir vía argumento opcional `startDate?: string`.
- Lista de 8 venues + 22 eventos + 7 templates copiados del mock del rediseño.
- `summary` recalculado a partir de `events`: `total`, `published` (status `publicado`), `cancelled`, `venuesUsed` (Set venueIds), `hoursOfContent` (suma de duraciones en horas), `fromCatalog` (count flag), `new = total - fromCatalog`.

## 6. Reescritura de `camporee-events-tab.tsx`

Firma original conservada:

```ts
interface CamporeeEventsTabProps {
  camporeeId: number;
  initialEvents: CamporeeEvent[];          // ← ignorado
  availableTemplates: CamporeeEventTemplate[]; // ← ignorado
  isUnionCamporee?: boolean;
  canCreate?: boolean;                     // ← se mapea a readonly = !canCreate
  canEdit?: boolean;                       // ← ignorado
  canDelete?: boolean;                     // ← ignorado
}
```

Body:

```tsx
const data = buildMockEvents({
  camporeeId: String(camporeeId),
  camporeeType: isUnionCamporee ? "union" : "local",
  unionName: "Tu unión",            // TODO: pasar desde page.tsx (props)
  localFieldName: isUnionCamporee ? undefined : "Tu campo local",
});

return (
  <EventsTimelineView
    camporeeId={String(camporeeId)}
    data={data}
    readonly={!canCreate}
  />
);
```

Notas:
- `unionName` real se pasa desde `page.tsx` en fase posterior (TODO de bajo costo). Por ahora string genérico es suficiente para prototipo.
- `readonly = !canCreate` colapsa `canEdit` y `canDelete` en un solo flag visual. Si en producción se necesita distinguir (ej. usuario puede crear pero no eliminar), agregar props granulares al `EventsTimelineView`. Para esta fase, suficiente.

## 7. Tokens CSS (`globals.css`)

Agregar en `:root`:

```css
--cat-espiritual:   oklch(0.62 0.18 285);
--cat-competencia:  oklch(0.66 0.21 42);
--cat-taller:       oklch(0.62 0.15 200);
--cat-ceremonial:   oklch(0.58 0.18 350);
--cat-social:       oklch(0.66 0.18 140);

--section-aventureros:    oklch(0.66 0.18 60);
--section-conquistadores: oklch(0.55 0.20 260);
--section-guias:          oklch(0.55 0.18 25);

--warning-soft:            oklch(0.95 0.05 85);
--warning-soft-foreground: oklch(0.40 0.15 60);
```

Equivalentes en `.dark` con luminosidad ajustada (~+0.05 para superficies soft, ~0 para colores vivos).

`@theme inline`:

```css
--color-cat-espiritual:   var(--cat-espiritual);
--color-cat-competencia:  var(--cat-competencia);
--color-cat-taller:       var(--cat-taller);
--color-cat-ceremonial:   var(--cat-ceremonial);
--color-cat-social:       var(--cat-social);
--color-section-aventureros:    var(--section-aventureros);
--color-section-conquistadores: var(--section-conquistadores);
--color-section-guias:          var(--section-guias);
--color-warning-soft:            var(--warning-soft);
--color-warning-soft-foreground: var(--warning-soft-foreground);
```

Resultado: clases `bg-cat-espiritual`, `text-cat-espiritual`, `border-cat-espiritual`, `bg-section-aventureros/15`, `bg-warning-soft`, `text-warning-soft-foreground`, etc.

Categoría `logistico` reutiliza tokens `muted` existentes (sin token propio).

## 8. Badge variants

Verificar `src/components/ui/badge.tsx` antes de codear. Si faltan, agregar al CVA:

```ts
"soft-info":        "bg-primary/10 text-primary border-transparent",
"soft-success":     "bg-success/10 text-success border-transparent",
"soft-warning":     "bg-warning-soft text-warning-soft-foreground border-transparent",
"soft-destructive": "bg-destructive/10 text-destructive border-transparent",
```

(Memoria de proyecto confirma variants `success`, `destructive`, `warning` existentes — falta verificar las soft-*.)

## 9. Comportamiento e interacciones

| Acción | Comportamiento en esta fase |
|---|---|
| Click "Crear evento" | Abre drawer con form vacío. Submit → `console.log(payload)` + cierra. |
| Click "Importar" / tab "Desde catálogo" | Idem drawer pero precarga campos desde template seleccionado. |
| Click "+ Agregar evento al {día}" en footer del día | Abre drawer con `defaultDayNumber` precargado. |
| Click fila / "Editar" | `console.log("edit", event.id)`. No abre nada. |
| Click "Más opciones" | Dropdown placeholder con items deshabilitados ("Editar", "Duplicar", "Cancelar evento"). |
| Filtros toolbar (search, category, section, venue, status) | State local, sin filtrado real. UI se renderiza igual. |
| Export | `console.log("export")`. |
| `readonly = true` | Oculta botones primarios (Crear, Importar, "+ Agregar"). |

Todos los handlers llevan comentario `// TODO: wire backend`.

## 10. Responsive

Mantener breakpoints del rediseño:
- `≥1280px`: 4 col KPI strip + filas 8-col completas.
- `768–1279px`: 3 col KPI strip + filas colapsan responsable + cupo.
- `<768px`: 2 col KPI strip + filas como Card stack (grid → block).

Implementado vía clases responsive ya presentes en el código del rediseño (`md:grid-cols-[88px_1fr_...]`, etc.). No requiere CSS adicional.

## 11. Modo oscuro

Todo el código del rediseño usa tokens semánticos (`bg-card`, `text-muted-foreground`, `border-border/60`). Los tokens nuevos (`cat-*`, `section-*`, `warning-soft`) tienen versión `.dark`. Sin colores hardcoded.

## 12. No incluido en esta fase

- Backend (Prisma schema, endpoints, server actions, RBAC nuevo).
- Filtrado/búsqueda real.
- Persistencia del drawer (crear evento, guardar template).
- AlertDialog de cancelar evento (UI presente, no hace mutación).
- Drag-and-drop para reorder entre días/horarios.
- Tests unitarios (mock-only, prototipo visual).
- Internacionalización de las categorías (strings fijos en español).

## 13. Verificación manual

1. `pnpm lint` en `sacdia-admin/`.
2. `pnpm dev` y navegar a `http://localhost:3001/dashboard/camporees/{id}` → tab "Eventos".
3. Verificar:
   - 4 KPIs visibles con números del summary.
   - Toolbar con search/3 selects/estado + botones derecha.
   - 5 day cards con header (día + fecha + stats + heatbar) y filas de eventos.
   - Día vacío (si aplica) muestra CTA.
   - Click "Crear evento" abre drawer; tabs Nuevo/Catálogo funcionan.
   - Modo oscuro: toggle tema, verificar tokens.
   - Responsive: redimensionar a `<768px`, verificar stack.

## 14. Riesgos

- **Categorías hardcoded**: la lista `EVENT_CATEGORIES` no es i18n ni administrable. Al integrar backend, hay que decidir si las 6 categorías visuales corresponden a `event_type_id` del spec o a un campo nuevo `display_category`. Decisión deferida.
- **Mock `unionName` genérico**: si el call site del tab no pasa el nombre real, se ve "Tu unión" en el drawer. Cosmético — bajo impacto.
- **Componentes legacy huérfanos**: `event-template-form-page.tsx`, `participants-field.tsx`, etc. quedan sin uso visible (los referencia el spec backend futuro). Marcarlos con `// TODO: replace with timeline templates` o documentar en este spec evita confusión.

## 15. Próximos pasos sugeridos (fuera de scope)

1. Backend: schema unificado (agenda + competencias) o decisión final de separarlas.
2. Reemplazar mock por fetch real (`getCamporeeAgenda(id)` server component).
3. Implementar server actions: `createEvent`, `updateEvent`, `cancelEvent`, `cloneFromTemplate`.
4. Cleanup de componentes legacy una vez backend nuevo esté en producción.
