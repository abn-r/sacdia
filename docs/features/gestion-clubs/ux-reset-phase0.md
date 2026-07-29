# UX Reset — Fase 0 Discovery (Clubs pilot, preset Maia)

**Fecha**: 2026-07-07

**Actualizado**: 2026-07-07 — entrevista stakeholder (3 respuestas)

**Estado**: Fase 0 completada — listo para Fase 1 (foundation)
**Decisiones tomadas**:
- Preset visual: **Maia** (`radix-maia`)
- Módulo piloto: **Clubs**
- Enfoque: journey-driven, no feature-driven

---

## 1. Problema

El panel admin SACDIA expone funcionalidad correcta pero **no está diseñado alrededor de tareas reales**. El módulo Clubs es representativo del patrón global:

- Pantallas construidas como CRUD + tablas + permisos
- Navegación por dominio técnico (8 tabs en detalle, columnas administrativas en listado)
- Iteraciones parciales abandonadas (`v2/` redirects, `hero.tsx` sin uso, keys i18n `switchToV2`)
- Flujos críticos enterrados (membresía pendiente en tab 5 de 8)

**Hipótesis de diseño**: un coordinador/director no piensa en "secciones, responsables, unidades" como tabs iguales — piensa en *"¿cómo está mi club? ¿quién falta aprobar? ¿qué hago hoy?"*

---

## 2. Personas (inferidas de RBAC + dominio)

Validar con usuarios reales en entrevistas cortas (30 min c/u).

| Persona | Rol típico | Scope territorial | Tarea #1 esperada |
|---------|-----------|-------------------|-------------------|
| **P1 — Director de club** | `director` en sección | 1 club, 1-3 secciones | Ver estado del club + aprobar miembros pendientes |
| **P2 — Secretario** | `secretary` en sección | 1 club | Gestionar miembros, roles, inscripciones |
| **P3 — Coordinador de campo** | `director-lf`, `assistant-lf` | Campo local (N clubes) | Encontrar un club rápido + ver salud operativa |
| **P4 — Admin unión/división** | `admin`, scope union/division | Muchos clubes | Listar/filtrar + crear club + import masivo |
| **P5 — Super admin** | `super-admin` | Global | Todo lo anterior + configuración |

### Entrevista stakeholder (2026-07-07)

| Pregunta | Respuesta | Implicación diseño |
|----------|-----------|-------------------|
| ¿Qué esperas ver al abrir el panel? | **Estadísticas según mi rol y jerarquía** | Dashboard contextual por scope territorial (`AdminTerritoryScope`). |
| ¿Dónde buscaste para aprobar un miembro? | **Usuarios y Clubes** | Cola de pendientes en inicio + usuarios + clubes. |
| ¿Qué columnas del listado de clubes usas? | **Las que ya están en pantalla** | Mantener columnas; agregar badges de pendientes. |

**Restricción de producto (2026-07-07):** directores y roles operativos de club **no acceden al panel** (`hasAdminRole` / `access_panel`). Usan la app móvil. El panel es para roles territoriales/admin: `director-lf`, `assistant-lf`, `director-union`, `assistant-union`, `director-dia`, `assistant-dia`, `coordinator`, `admin`, `super-admin`.

**Persona piloto corregida:** coordinador de campo (`director-lf` / `assistant-lf`), no director de club.

### Conclusión entrevista

El problema **no es el listado de clubes** — es la **ausencia de un inicio contextual** y la **dispersión del flujo de aprobación** entre Usuarios y Clubes.

Prioridad ajustada:
1. Dashboard scoped por rol/jerarquía (nuevo en pilot, mínimo viable)
2. Puente Usuarios ↔ Clubes para pendientes de membresía
3. Detalle club (hub) — simplificar tabs, no tocar columnas del listado

### Preguntas abiertas (opcional, siguientes entrevistas)

1. ¿Cuántas veces al día entras al panel? ¿Desde dónde (móvil/desktop)?
2. ¿Sabías que membresía pendiente también está en tab "Membresía" del detalle del club?

---

## 3. Inventario actual — Clubs

### Rutas

| Ruta | Propósito |
|------|-----------|
| `/dashboard/clubs` | Listado paginado + filtros |
| `/dashboard/clubs/new` | Crear club (form largo + mapa + secciones iniciales) |
| `/dashboard/clubs/import` | Import masivo Excel |
| `/dashboard/clubs/[id]` | Detalle hub (8 tabs) |
| `/dashboard/clubs/[id]/units/new` | Crear unidad |
| `/dashboard/clubs/[id]/units/[unitId]` | Detalle unidad |
| `/dashboard/clubs/v2/*` | **Redirects** a rutas principales (legado) |

### Componentes

- **~10k líneas** en `src/components/clubs/`
- **33 archivos** TSX en clubs + detail/
- **5 tests** (sections panel, section director succession)

### Tabs actuales en detalle (8)

| Tab | Contenido | Problema UX |
|-----|-----------|-------------|
| Resumen | Charts, score, liderazgo | Bueno — debería ser home |
| Secciones | CRUD secciones + historial | Mezcla gestión + historial |
| Responsables | Asignación de cargos | Separado de secciones (mismo concepto) |
| Unidades | Lista unidades | OK pero desconectado de miembros |
| Membresía | Pendientes + transferencias | **Flujo crítico enterrado** |
| Info | Datos estáticos del club | Duplica resumen |
| Historial | Auditoría | Admin, no daily driver |
| Editar | Form completo | No debería ser tab — es acción |

### Listado actual

Columnas: Nombre, Campo local, Distrito, Iglesia, Secciones (activas/total), Estado, Acciones.

- Orientado a **admin territorial** (P3/P4), no a director (P1)
- Filtros en caja separada con hint técnico
- Acciones: dropdown ⋯ + iconos ghost (ver/editar)
- `ClubsCreateMenu`: manual vs import masivo (bien)

### Código muerto / deuda detectada

| Item | Evidencia |
|------|-----------|
| `ClubDetailHero` | Existe en `detail/hero.tsx`, **no importado** en `view.tsx` |
| Rutas `v2/` | Solo `redirect()` a rutas actuales |
| i18n `switchToV2` / `switchToClassic` | Keys huérfanas en `messages/*.json` |
| Tabs custom `ClubTabsNav` | Componente alternativo no usado; `view.tsx` usa shadcn `Tabs` |
| Namespace i18n mixto | `clubs.pages.list` + `clubs.pages.v2` + `clubs.pages.detail` |

### Módulos relacionados (fuera de Clubs pero en el journey)

| Módulo | Ruta nav | Relación con Clubs |
|--------|----------|-------------------|
| Enrollments | `/dashboard/enrollments` | Inscripciones anuales por miembro |
| Membership requests | `/dashboard/requests/membership` | **Duplica** tab Membresía del club |
| Coordination | `/dashboard/coordination` | Vista territorial de clubes |
| Units | Dentro de club detail | Subdivisión de sección |
| Classes | `/dashboard/classes` | Clase progresiva del miembro |

---

## 4. User journeys

### Journey A — Director: "¿Quién espera aprobación?" (P1)

**Hoy (pasos reales)**:
1. Login → sidebar "Clubes" → listado
2. Click en su club → detalle
3. Scroll horizontal en 8 tabs → tab "Membresía" (5/8)
4. Selector de sección → tabla pendientes → aprobar/rechazar

**Fricción**: 4+ clicks, tab no obvio, sin badge de pendientes en listado ni sidebar.

**Ideal (propuesto — ajustado post-entrevista)**:
1. Login → dashboard con stats **scoped a rol/jerarquía** + card *"3 solicitudes pendientes"*
2. Click → puede ir a Usuarios o Clubes (ambos válidos) → misma cola de pendientes
3. Aprobar → toast + stats del dashboard se actualizan

---

### Journey B — Coordinador LF: "¿Cómo están mis clubes?" (P3)

**Hoy**:
1. Clubes → filtros (campo local pre-seleccionado si scope) → tabla
2. Click club → tab Resumen → charts

**Fricción**: Listado no muestra señales de salud (pendientes, miembros, score). Hay que entrar a cada club.

**Ideal (ajustado — columnas actuales se mantienen)**:
1. Clubes → misma tabla + **badge de pendientes** por fila (adicional, no reemplaza columnas)
2. Filtros colapsados por defecto, scope territorial automático
3. Click → hub con resumen accionable

---

### Journey C — Admin: "Crear club nuevo" (P4)

**Hoy**:
1. Clubes → dropdown "Crear" → manual o import
2. `/clubs/new` → form largo (geografía encadenada + mapa + secciones)

**Fricción**: Form único intimidante. No hay wizard ni progreso.

**Ideal**:
1. Wizard 3 pasos: Datos básicos → Ubicación → Secciones iniciales
2. Resumen antes de guardar
3. Redirect a detalle del club creado con checklist "próximos pasos"

---

### Journey D — Secretario: "Consultar director de sección" (P2)

**Hoy**:
1. Club → tab Secciones → consultar la sección
2. Tab Responsables → selector de sección → ver al director vigente
3. El Secretario no programa ni activa sucesiones

**Fricción**: El `section-director-succession-card` puede sugerir una acción que
el Secretario no debe ejecutar.

**Ideal**:
1. Club → sección "Mi equipo" con las 3 secciones como cards
2. Cada card: director actual, miembros count y sucesión en modo solo lectura
   para Secretario

#### Restriccion contractual del flujo de sucesion

El card de accion actual consume el `POST .../director-succession` inmediato. El pilot no
debe presentar esa accion como preasignacion segura para el siguiente ano:
mientras el backend P0 no este implementado y habilitado, ejecutar el POST
termina al director vigente y crea la nueva asignacion activa en la misma
operacion.

La UX futura podra consultar los endpoints planeados
`GET /clubs/:clubId/sections/:sectionId/director-succession` y
`GET /clubs/:clubId/sections/:sectionId/capabilities` para mostrar preflight y
estado. Esas lecturas no crean assignment ni grant. Una capability positiva no autoriza por sí sola.
`can_schedule_director_succession` solo puede ser positiva para
`director-lf` o `assistant-lf` exactos, del mismo Campo Local y dentro de la
ventana inclusiva del 1 de octubre al 31 de diciembre. Secretario permanece
view-only. El backend reautoriza SCHED al recibir el comando; la activacion
posterior aplica ACT-003 y no vuelve a exigir la ventana ni la autoridad
original de quien programo.

---

## 5. Principios de diseño para el rebuild (Maia)

### Preset Maia — implicaciones

| Aspecto | Cambio | Impacto en pilot |
|---------|--------|------------------|
| Iconos | Lucide → **Hugeicons** | Migrar solo iconos de módulo Clubs primero; resto del shell sigue Lucide hasta Fase 1 global |
| Tipografía | Geist → **Figtree** | Aplicar en foundation reset (layout.tsx) |
| Radius/spacing | Más suave, redondeado | Re-add componentes `ui/` con `radix-maia` |
| Paleta SACDIA | Mantener `--brand-primary` etc. | Maia es estilo, no reemplaza marca |

### 5 patrones de página (target)

1. **`ListPage`** — filtros colapsables, empty states, acciones primarias claras
2. **`DetailHub`** — hero + métricas + secciones de contenido (no 8 tabs planos)
3. **`WizardPage`** — crear/editar complejo en pasos
4. **`ActionPage`** — flujo enfocado (aprobar membresía, import)
5. **`DashboardCard`** — widget reutilizable para métricas

### Reglas UX del pilot

- Máximo **4 secciones visibles** en detalle de club (no 8 tabs)
- **Cero acciones destructivas** en header principal (delete en menú ⋯)
- **Badges de atención** en listado (pendientes, inactivo)
- **Scope territorial automático** — no pedir filtro de campo local si el usuario ya tiene scope
- **Mobile-first** en listado (cards en `<md`, tabla en `≥md`)
- **Columnas del listado de clubes**: mantener las actuales; solo agregar indicadores (badges)
- **Dashboard**: stats filtradas por `resolveAdminTerritoryScope()` + rol del usuario
- **Aprobación de miembros**: entry points en Usuarios, Clubes e inicio (misma cola)

---

## 6. Arquitectura de información propuesta — Club detail

Reemplazar 8 tabs por **hub con secciones**:

```
┌─────────────────────────────────────────────────────┐
│  [Hero] Club Name · Activo · 142 miembros · Score  │
│  Campo local · Distrito · Iglesia                   │
├─────────────────────────────────────────────────────┤
│  ⚠ 3 solicitudes pendientes          [Revisar →]   │  ← alerta accionable
├─────────────────────────────────────────────────────┤
│  RESUMEN                                            │
│  [composición] [salud] [asistencia] [ranking]       │
├─────────────────────────────────────────────────────┤
│  MI EQUIPO (3 secciones)                            │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐            │
│  │Aventur.  │ │Conquist. │ │Guías     │            │
│  │Dir: Juan │ │Dir: —    │ │Dir: Ana  │            │
│  │42 miemb. │ │38 miemb. │ │62 miemb. │            │
│  └──────────┘ └──────────┘ └──────────┘            │
├─────────────────────────────────────────────────────┤
│  UNIDADES · MEMBRESÍA · HISTORIAL        [ver todo] │  ← links secundarios
└─────────────────────────────────────────────────────┘
```

Editar / eliminar → menú `⋯` en hero, no botones rojos visibles.

---

## 7. Scope del pilot (qué se reconstruye vs qué se reutiliza)

### Reutilizar (sin cambios)

- `lib/clubs/actions.ts`, `lib/api/*`, server pages data fetching
- Permisos RBAC, territory scope
- i18n keys (limpiar huérfanas, no reescribir todo)
- Tests de lógica de negocio existentes

### Reconstruir (UI/UX)

| Pieza | Archivo actual | Acción |
|-------|---------------|--------|
| Dashboard inicio | `dashboard/page.tsx` | Widgets scoped por rol/jerarquía + card pendientes |
| Listado | `clubs-list-client.tsx` | Restyle Maia + badge pendientes por fila; **columnas iguales** |
| Detalle hub | `detail/view.tsx` + 8 tabs | Nuevo `club-hub-page` con secciones |
| Puente pendientes | `pending-members-panel.tsx` + users | Componente compartido `PendingMembershipQueue` |
| Crear club | `create-club-form.tsx` | Wizard 3 pasos |
| Shell parcial | Solo breadcrumb + header del módulo | Maia tokens en scope pilot |

### Eliminar en pilot

- `detail/hero.tsx` (o integrar en hub nuevo)
- `detail/tabs-nav.tsx` (custom no usado)
- Redirects `v2/` (después de validar sin tráfico)
- Keys i18n `switchToV2` / `switchToClassic`

### Fuera de scope pilot (oleadas posteriores)

- Units detail (`/units/[unitId]`)
- Import masivo (mantener funcional, solo restyle)
- Enrollments global
- `/dashboard/requests/membership` (unificar con hub en ola B)
- Shell global / sidebar / nav restructure

---

## 8. Métricas de éxito

| Métrica | Baseline (estimado) | Target pilot |
|---------|--------------------|--------------|
| Clicks para aprobar miembro | 4+ | ≤2 |
| Tabs visibles en detalle | 8 | ≤4 secciones |
| Tiempo crear club (usuario nuevo) | ? medir en entrevista | -30% percibido |
| `audit:design-system --strict` | 0 errores | mantener 0 |
| Líneas en `clubs-list` + `detail/view` | ~700 combinadas | <400 con patrones |

---

## 9. Riesgos

| Riesgo | Mitigación |
|--------|-----------|
| Maia = cambio de iconos global | Pilot Clubs con Hugeicons; shell mantiene Lucide temporalmente |
| Usuarios acostumbrados a tabs | Pilot en branch + preview Vercel antes de merge |
| Duplicar membership (tab + `/requests`) | Documentar; unificar en ola B post-pilot |
| Scope creep a units/enrollments | Checklist estricto sección 7 |

---

## 10. Próximos pasos — Fase 1 (Foundation + pilot ajustado)

Orden de implementación (según entrevista):

1. Branch `feat/ui-reset-maia-clubs`
2. `components.json` → `"style": "radix-maia"` + Figtree
3. Re-add `ui/` base + sandbox `/dashboard/design-system`
4. **`RoleScopedDashboard`** — stats por jerarquía (widget mínimo en `/dashboard`)
5. **`PendingMembershipQueue`** — componente compartido (Usuarios + Clubes + dashboard)
6. **`clubs-list-client`** — restyle Maia + badge pendientes; columnas sin cambio
7. **`club-hub-page`** — detalle simplificado (8 tabs → hub)
8. Preview → validación stakeholder
9. Iterar → merge pilot

**Duración estimada**: 2-3 semanas (dashboard scoped añade ~3-4 días vs plan original).

---

## 11. Checklist Fase 0

- [x] Inventario rutas y componentes Clubs
- [x] Personas inferidas de dominio/RBAC
- [x] 4 user journeys documentados (actual vs ideal)
- [x] Deuda UX/código identificada
- [x] Arquitectura de información propuesta
- [x] Scope pilot delimitado
- [x] Entrevista stakeholder (3 respuestas clave)
- [ ] Entrevistas campo con director/coordinador *(opcional, refinar)*
- [ ] Baseline métricas medido con usuario *(pendiente)*

---

## Referencias

- `docs/features/gestion-clubs.md` — dominio verificado
- `docs/features/membership-requests.md` — flujo pendientes
- `sacdia-admin/DESIGN-SYSTEM.md` — tokens actuales
- `sacdia-admin/src/components/clubs/` — código pilot
- [shadcn Maia preset](https://ui.shadcn.com/docs/changelog/2026-07-base-ui-default) — estilos 2026
