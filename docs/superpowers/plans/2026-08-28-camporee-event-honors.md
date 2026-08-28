# Camporee Event Honors Implementation Plan

> **For agentic workers:** Execute inline in this session. Spec: `docs/superpowers/specs/2026-08-28-camporee-event-honors-design.md`.

**Goal:** Relacionar eventos de camporee con especialidades del catálogo para preparación; admin asigna; app consulta el PDF.

**Architecture:** Tabla puente `camporee_event_honors`. Mutación por `honor_ids[]` en create/update del evento. GET/preview embeben `honors[]`. Admin picker en `EventFormPage`. App read-only + `SacPdfViewer`.

**Tech Stack:** NestJS + Prisma, Next.js admin, Flutter app.

---

### Task 1: Schema + migración backend

**Files:**
- Create: `sacdia-backend/prisma/migrations/20260828120000_camporee_event_honors/migration.sql`
- Modify: `sacdia-backend/prisma/schema.prisma` (`honors`, `camporee_events`, nuevo model)
- Modify: `docs/database/schema.prisma` (espejo)
- Modify: `docs/database/SCHEMA-REFERENCE.md`

- [ ] Añadir model `camporee_event_honors` y relaciones.
- [ ] SQL: CREATE TABLE + unique + FKs + indexes.
- [ ] `npx prisma generate` en backend.

### Task 2: Error codes + DTOs

**Files:**
- Modify: `sacdia-backend/src/common/errors/error-codes.ts`
- Modify: `sacdia-backend/src/camporee-events/dto/camporee-events.dto.ts`

Códigos:
- `CAMPOREE_EVENT_HONOR_NOT_FOUND`
- `CAMPOREE_EVENT_HONOR_DUPLICATE`
- `CAMPOREE_EVENT_HONOR_LIMIT`

`honor_ids?: number[]` en Create y Update, `ArrayMaxSize(20)`, `IsInt` each, `Min(1)` each.

### Task 3: Service + tests

**Files:**
- Modify: `sacdia-backend/src/camporee-events/camporee-events.service.ts`
- Modify: `sacdia-backend/src/camporee-events/camporee-events.service.spec.ts`

Helpers: `MAX_EVENT_HONORS = 20`, `assertHonorIds`, `replaceEventHonors`, `loadEventHonors`, `mapEventHonor`, `attachEventHonors`.

Wire: `createEvent`, `updateEvent` (si `honor_ids !== undefined`), `getEvent`, `listEvents` (también preview).

Tests Jest: set on create, omit on patch, empty clears, duplicate, limit, inactive honor, preview keeps honors.

Run: `npx jest src/camporee-events/camporee-events.service.spec.ts --no-coverage`

### Task 4: Docs canónicas API/feature

**Files:**
- Modify: `docs/features/camporee-events.md`
- Modify: `docs/api/ENDPOINTS-LIVE-REFERENCE.md` (nota de contrato, sin ruta nueva)
- Modify: `docs/features/honores.md` (vínculo consultivo desde eventos)

### Task 5: Admin contratos + picker + form

**Files:**
- Modify: `sacdia-admin/src/lib/api/camporee-events.ts`
- Modify: `sacdia-admin/src/lib/camporee-events/actions.ts`
- Create: `sacdia-admin/src/components/camporee-events/event-honors-picker.tsx`
- Modify: `sacdia-admin/src/components/camporee-events/event-form-page.tsx`
- Modify: `sacdia-admin/src/components/camporee-events/event-form-page.test.tsx`

`buildAgendaPayload` lee `honor_ids` JSON. Picker: Command + chips. Copy: Especialidades de preparación.

### Task 6: App entidad, parseo, UI, i18n

**Files:**
- Modify: `sacdia-app/lib/features/camporees/domain/entities/camporee_event.dart`
- Modify: `sacdia-app/lib/features/camporees/data/models/camporee_event_model.dart`
- Modify: `sacdia-app/lib/features/camporees/presentation/views/camporee_detail_view.dart`
- Modify: `sacdia-app/assets/translations/{es,en,pt-BR,fr}.json`
- Test: parse honors + empty list

CTA abre `SacPdfViewer.show(context, pdfSource: url, title: name)`.

### Task 7: Verificación

- Backend jest del servicio.
- Admin vitest del form (sección visible).
- App `flutter test` del modelo/vista afectados si hay tests.
- Browser: formulario admin si el panel corre.
