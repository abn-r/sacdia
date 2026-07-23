# Panel Administrativo v2

Panel Studio Admin en paralelo al panel v1, sin reemplazarlo.

## Rutas

| Versión | Prefijo | Ejemplo |
|---------|---------|---------|
| v1 (clásico) | `/dashboard/*` | `/dashboard/users` |
| v2 (Studio) | `/v2/dashboard/*` | `/v2/dashboard/users` |

## Arquitectura

- **Auth**: misma sesión JWT (`requireAdminUser`, `proxy.ts` protege ambos prefijos)
- **API**: sin cambios — `src/lib/api/*`, server actions existentes
- **Shell v2**: `src/components/studio-shell/*` + layout `src/app/(dashboard-v2)/layout.tsx`
- **UI v2**: `src/components/v2/**` (primitivas Studio + pantallas custom)
- **Loaders**: `src/lib/v2/loaders/**` — fetch compartido extraído de pages v1
- **Bridged pages**: generadas desde v1 vía `pnpm run scaffold:v2` — copia nativa sin `V2ContentFrame` (studio layout + `panelRedirect` en server redirects)

## Toggle v1 ↔ v2

Header de ambos paneles incluye enlace al equivalente (`lib/v2/route-map.ts`).

## Pantallas con UI Studio completa

- Home (`/v2/dashboard`)
- Usuarios (`/v2/dashboard/users`) — TanStack Table
- Detalle usuario (`/v2/dashboard/users/[userId]`) — reutiliza `UserDetailScreen`
- Clubes (`/v2/dashboard/clubs`)
- Detalle club (`/v2/dashboard/clubs/[id]`) — reutiliza `ClubDetailView` + loader
- Inscripciones (`/v2/dashboard/enrollments`)
- Validación de evidencias (`/v2/dashboard/evidence-review`)
- Investiduras pending (`/v2/dashboard/investiture`)
- Investiduras pipeline (`/v2/dashboard/investiture/pipeline`)
- Investiduras config (`/v2/dashboard/investiture/config`)
- Solicitudes de membresía (`/v2/dashboard/requests/membership`)
- Solicitudes de asignación (`/v2/dashboard/requests/assignments`)
- Solicitudes de transferencia (`/v2/dashboard/requests/transfers`)
- SLA (`/v2/dashboard/sla`)
- Carpetas anuales hub (`/v2/dashboard/annual-folders`)
- Carpetas anuales rankings (`/v2/dashboard/annual-folders/rankings`)
- Carpetas anuales plantillas (`/v2/dashboard/annual-folders/templates`)
- Ranking config list/new/edit (`/v2/dashboard/annual-folders/ranking-config/*`)
- Ranking breakdown (`/v2/dashboard/annual-folders/rankings/[enrollmentId]/breakdown`)
- Legacy redirects: `evaluate` → hub, `categories` → `ranking-config`
- Catálogos Phase E (15) — `V2PhaseECatalogPage` + `PhaseECatalogCrudPage`:
  - `catalogs/activity-types`, `allergies`, `camporee-event-types`, `class-modules`, `class-sections`, `classes`, `club-types`, `diseases`, `finance-categories`, `honors-catalog`, `inventory-categories`, `master-honors`, `medicines`, `relationship-types`, `geography/countries`
- Geografía con padre FK (4) — `V2CatalogListShell` + `GeographyListClient`:
  - `catalogs/geography/unions`, `local-fields`, `districts`, `churches`
- Ideales de club (`/v2/dashboard/catalogs/club-ideals`) — `V2CatalogListShell` + `ClubIdealListClient`
- Hub catálogos (`/v2/dashboard/catalogs`) — `V2PageShell` + `CatalogsHubPage`
- Categorías de especialidades (`/v2/dashboard/catalogs/honor-categories`) — `V2CatalogListShell` + `HonorCategoriesCrudPage`
- Años eclesiásticos (`/v2/dashboard/catalogs/ecclesiastical-years`) — `V2CatalogListShell` + `CatalogEntityPage`
- Camporees de unión (`/v2/dashboard/camporees/union`, `.../union/[id]`, eventos new/edit) — páginas nativas con `panelRedirect` / `toV2Path` / `PanelDashboardLink`

Las demás rutas v2 (~91) replican lógica v1 directamente en el studio layout (`usePanelPath` / `panelRedirect` para navegación).

## Comandos

```bash
pnpm run scaffold:v2   # Regenerar pages bridged desde v1
```

## Convenciones

- Nuevas pantallas v2: Server Component delgado + loader + `V2PageShell` / `V2DataTable`
- No duplicar contratos API — reutilizar `lib/api/*`
- i18n: keys existentes; chrome v2 en `nav.v2.*`
- **Compose panel (Sheet)**: acciones secundarias sobre listados — seguir `DESIGN-SYSTEM.md` §6.1.2 y §11.5. Referencia: `src/components/notifications/notification-compose-sheet.tsx`
