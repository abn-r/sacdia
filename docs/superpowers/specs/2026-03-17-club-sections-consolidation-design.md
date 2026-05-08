---
title: Club Sections Consolidation
date: 2026-03-17
status: approved
scope: sacdia-backend, sacdia-admin, sacdia-app
---

# Club Sections Consolidation — Spec/Design

## Contexto

Renombrar "club-instances" a "club-sections" y consolidar 3 tablas identicas (`club_adventurers`, `club_pathfinders`, `club_master_guilds`) en una sola tabla `club_sections` con `club_type_id` como discriminador. El canon ya avala esta direccion — la estructura de 3 tablas esta documentada como transitoria.

### Scope

- 3 repos: sacdia-backend, sacdia-admin, sacdia-app
- 10 tablas dependientes afectadas (pasan de 3 FK nullables a 1 FK directa)
- 4 archivos backend con switch/if patterns que se simplifican (`clubs.service.ts`, `permissions.guard.ts`, `authorization-context.service.ts`, `activities.service.ts`)
- Deployment: big bang coordinado (3 PRs, deploy simultaneo)

---

## 1. Modelo de datos consolidado

```sql
CREATE TABLE club_sections (
  club_section_id   SERIAL PRIMARY KEY,
  active            BOOLEAN DEFAULT false,
  souls_target      INT DEFAULT 1,
  fee               INT DEFAULT 1,
  meeting_day       JSON[],
  meeting_time      JSON[],
  club_type_id      INT NOT NULL REFERENCES club_types(club_type_id),
  main_club_id      INT NULL REFERENCES clubs(club_id) ON DELETE CASCADE,  -- nullable para preservar datos existentes con main_club_id = NULL
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  modified_at       TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(main_club_id, club_type_id)
);
```

- `club_type_id` es el discriminador — no se necesita columna `section_type` VARCHAR separada.
- Las 10 tablas dependientes reemplazan 3 FK nullables (`club_adv_id`, `club_pathf_id`, `club_mg_id`) por 1 FK directa: `club_section_id`. Las tablas son: `activities`, `activity_instances`, `folder_assignments`, `camporee_clubs`, `club_inventory`, `club_role_assignments`, `finances`, `folders_modules_records`, `folders_section_records`, `units`.
- Agregar tipo nuevo = agregar fila en `club_types`, cero cambio de schema.

---

## 2. Migracion de datos

Una sola transaccion SQL con 4 fases:

**Fase 1** — Crear `club_sections` e insertar desde las 3 tablas, con tabla temporal de mapeo `(source_table, old_id) -> new_club_section_id`.

**Fase 2** — Agregar columna `club_section_id` en las 10 tablas dependientes.

**Fase 3** — Poblar `club_section_id` usando el mapeo.

**Fase 4** — Dropear las 3 columnas viejas de cada tabla, dropear las 3 tablas originales, dropear tabla temporal.

Rollback: si algo falla, la transaccion entera se revierte.

Constraints especiales:

- `club_role_assignments` tiene UNIQUE compuesto con las 3 FK viejas. Se reemplaza por `UNIQUE(user_id, role_id, club_section_id, ecclesiastical_year_id, start_date)`. NOTA: existen dos constraints con nombres distintos (`club_role_assignment_unique` y `club_role_assignment_unique_refactored`) que deben dropearse ambos. Posible migración incompleta previa.
- `activity_instances` tiene `@@unique([activity_id, club_adv_id, club_pathf_id, club_mg_id])` que se reemplaza por `UNIQUE(activity_id, club_section_id)`.

Caso especial — `folder_assignments`: tiene columnas `club_adv_id`, `club_pathf_id`, `club_mg_id` pero SIN relaciones `@relation` en Prisma (FKs huérfanas). Investigar si están en uso por raw queries antes de migrar. Si son dead columns, dropear sin mapear.

Estrategia de índices:

- `club_sections`: el UNIQUE en `(main_club_id, club_type_id)` ya cubre las queries de lookup principales.
- Cada una de las 10 tablas dependientes necesita un INDEX en `club_section_id` (reemplazando los 3 índices viejos por FK).

Comportamiento `onDelete`: el `onDelete` de `club_section_id` en cada tabla dependiente debe replicar el existente: `Cascade` donde hoy es Cascade (ej: `club_role_assignments`), `NoAction` donde hoy es NoAction (ej: `activities`). Documentar explícitamente en la migración SQL.

Rollback post-deploy: si la migración ejecuta correctamente pero el código nuevo tiene bugs, se requiere una migración reversa. Opción de mitigación: renombrar las 3 tablas originales en lugar de dropearlas (ej: `club_adventurers_deprecated`) y dropear definitivamente después de un período de gracia de 7 días.

---

## 3. Cambios en backend

### 3.1 Prisma schema

Modelo `club_sections` reemplaza los 3 modelos. 10 tablas actualizan sus relaciones.

### 3.2 Routes (API contract)

| Antes | Despues |
|-------|---------|
| `GET /clubs/:id/instances` | `GET /clubs/:id/sections` |
| `GET /clubs/:id/instances/:type/:instanceId` | `GET /clubs/:id/sections/:sectionId` |
| `POST /clubs/:id/instances` | `POST /clubs/:id/sections` |
| `PATCH /clubs/:id/instances/:type/:instanceId` | `PATCH /clubs/:id/sections/:sectionId` |
| `DELETE /clubs/:id/instances/:type/:instanceId` | `DELETE /clubs/:id/sections/:sectionId` |
| `GET /clubs/:clubId/instances/:type/:instanceId/members` | `GET /clubs/:clubId/sections/:sectionId/members` |

`:type` desaparece de la URL — el tipo se resuelve por JOIN con `club_types`.

### 3.3 Service layer

Los metodos con switch/case en `clubs.service.ts` y `activities.service.ts` se convierten en queries directos parametrizados por `club_section_id`.

### 3.4 Guards y authorization

`permissions.guard.ts` y `authorization-context.service.ts` pasan de if-chains con 3 ramas a un solo lookup por `club_section_id`. De ~150 lineas a ~30.

### 3.5 Permission strings

UPDATE en DB: `club_instances:*` -> `club_sections:*`.

### 3.6 DTOs

- `ClubInstanceType` enum se elimina (tipo viene de `club_types`).
- `club_instance_id` -> `club_section_id`.
- `instance.dto.ts` -> `section.dto.ts`.

---

## 4. Cambios en admin (Next.js)

### 4.1 API client (`src/lib/api/clubs.ts`)

**Tipos:**
- `ClubInstance` -> `ClubSection`
- `ClubInstancePayload` -> `ClubSectionPayload`
- `ClubInstanceMember` -> `ClubSectionMember`
- `ClubInstanceMembersQuery` -> `ClubSectionMembersQuery`
- `ClubInstanceType` se elimina

**Funciones:**
- `listClubInstances` -> `listClubSections`
- `createClubInstance` -> `createClubSection`
- `updateClubInstance` -> `updateClubSection`
- `listClubInstanceMembers` -> `listClubSectionMembers`
- Funciones que recibian `(clubId, instanceType, instanceId)` pasan a `(clubId, sectionId)`

### 4.2 Server actions (`src/lib/clubs/actions.ts`)

- Todos los `*Instance*` -> `*Section*`.
- `buildClubInstancePath()` -> `buildClubSectionPath()` simplificado sin `:type`.
- `parseInstanceType()` y `getInstanceByType()` se eliminan.

### 4.3 Components

- `club-instances-panel.tsx` -> `club-sections-panel.tsx`, props actualizadas.
- Notification forms: 2 campos -> 1 (`club_section_id`).

### 4.4 Permissions

Constantes y helpers renombrados:
- `CLUB_INSTANCES_*` -> `CLUB_SECTIONS_*`
- `canReadClubInstances` -> `canReadClubSections`
- etc.

### 4.5 Pages

Import y prop name actualizados en `clubs/[id]/page.tsx`.

---

## 5. Cambios en app (Flutter)

### 5.1 Models

Dos `ClubInstanceModel` duplicados se unifican en un solo `ClubSectionModel` en `club/data/models/club_section_model.dart`. Se elimina el parsing defensivo multi-key.

### 5.2 Remote data sources

- `getClubInstances(clubId)` -> `getClubSections(clubId)` — de 3 queries por slug a 1 query.
- `completeStep3(clubInstanceId)` -> `completeStep3(clubSectionId)`, payload: `club_section_id`.
- `getClubInstance(clubId, instanceType, instanceId)` -> `getClubSection(sectionId)` — URL simplificada.

### 5.3 Domain

- Entity `ClubInstance` -> `ClubSection`.
- Use cases, params y repository interface renombrados.
- Params simplificados (ya no necesitan `instanceType`).

### 5.4 Providers

- `clubInstancesProvider` -> `clubSectionsProvider`
- `selectedClubInstanceProvider` -> `selectedClubSectionProvider`
- etc.
- `derivedSelectedClubInstanceTypeSlugProvider` se elimina.

### 5.5 Views y widgets

Todas las refs actualizadas en: club_selection_step_view, post_registration_shell, club_type_selector, club_view, evidence folder views.

### 5.6 Router

Provider refs actualizadas, param `clubInstanceId` -> `clubSectionId`.

### 5.7 File renames

- `club_instance_model.dart` (post_registration) se elimina.
- Use cases renombrados.

---

## 6. Documentacion canon y verificacion

### Archivos canon a actualizar

- `docs/canon/decisiones-clave.md` — nueva decision de consolidacion
- `docs/canon/dominio-sacdia.md` L273 — actualizar mapeo a tabla unica
- `docs/canon/runtime-sacdia.md` L81, L207-208 — marcar naming como IMPLEMENTADO
- `docs/canon/gestion-clubs.md` L8 — actualizar DB listing
- `docs/features/carpetas-evidencias.md` L7-9 — endpoints actualizados

### Otros docs

- `SCHEMA-REFERENCE.md`
- `REALITY-MATRIX.md`
- `AGENTS.md`

### Criterios de verificacion

1. `npx prisma validate` pasa
2. Integridad de datos:
   - `SUM(rows)` de las 3 tablas fuente = `COUNT(*)` en `club_sections`
   - Todo `club_section_id` en tablas dependientes es NOT NULL (sin referencias huérfanas)
   - Cero filas en tablas dependientes con columnas FK viejas (deben estar dropeadas)
3. `pnpm test` y `pnpm test:e2e` pasan en backend
4. `pnpm build` exitoso en admin
5. `flutter analyze` sin errores en app
6. Query de permissions: 0 filas con `club_instances%`
7. Cero menciones de "tablas separadas por tipo" en canon
8. `scripts/e2e-smoke.mjs` pasa

### Orden de ejecucion

1. Migracion SQL
2. Prisma schema
3. Backend (services, guards, controllers, DTOs, tests)
4. Admin (API client, actions, components, permissions)
5. App (models, datasources, domain, providers, views)
6. Documentacion canon
7. Verificacion end-to-end
