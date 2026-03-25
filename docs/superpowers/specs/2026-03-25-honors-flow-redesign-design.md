# Honors Flow Redesign — Design Spec

**Date:** 2026-03-25
**Status:** Approved (v2 — post review)
**Scope:** sacdia-app (Flutter) + minor backend changes
**Mockup:** `.superpowers/brainstorm/honors-redesign-mockup-v2.html`

## Context

The honors (especialidades) feature in sacdia-app has 4 views and 3 widgets following Clean Architecture. The current UI is functional but feels flat and basic. Users range from 5 to 99 years old across Conquistadores, Aventureros, and Guías Mayores clubs.

### Real-world workflow

1. Member enrolls in an honor via the app
2. Member downloads the workbook/material PDF (`materialUrl` field already exists on `Honor`)
3. Member completes activities offline with an instructor (fills out worksheets, the instructor signs them)
4. Member scans/photographs the signed worksheets and uploads them as evidence (PDF or images)
5. Member submits evidence for review
6. A **coordinador**, **assistant-lf**, or **director-lf** validates or rejects the submission

Key constraint: **users may not always have internet access**. Evidence upload must be prepared offline and synced when connectivity returns.

### Problems with current design
- Boring/basic visual appearance
- Category selection uses a dropdown (not visual enough)
- No progress visualization per honor
- No celebration or feedback on completion
- `UserHonor.validate` is binary (true/false) — no intermediate states

### Design direction
**Hybrid Cards (Clean & Progressive)** — Minimalist style with solid SACDIA brand colors (no gradients), category chips replacing the dropdown, state-based progress visualization, and clear state differentiation through color-coded border-left indicators.

Inspiration: Duolingo gamification (progress, feedback) + Scout badge essence (achievement, merit).

## Brand Colors (from `app_colors.dart`)

| Name | Hex | Usage |
|------|-----|-------|
| sacBlack | `#183651` | Headers, primary text |
| sacBlue | `#2EA0DA` | Active chips, links, info actions |
| sacRed | `#F06151` | In-progress/evidence header, accent |
| sacYellow | `#FBBD5E` | Submitted/pending state, badges |
| sacGreen | `#4FBF9F` | Completed/validated state, CTA primary |
| sacGreenLight | `#43A78A` | Completed accent |
| sacWhite | `#E1E6E7` | Borders, disabled state |
| sacGrey | `#B9B9B9` | Muted text |

**Dark mode:** Out of scope for this redesign. Use hardcoded light palette. Dark mode will be addressed in a follow-up.

## Honor Status Model

The current `UserHonor` has a single `validate: bool`. This redesign requires a proper status field:

| Status | Color | Meaning |
|--------|-------|---------|
| `inscripto` | `#2EA0DA` (blue) | Enrolled, no evidence yet |
| `en_progreso` | `#F06151` (red) | Has uploaded some evidence but not submitted |
| `enviado` | `#FBBD5E` (yellow) | Submitted for review, waiting validation |
| `validado` | `#4FBF9F` (green) | Approved by coordinator/assistant-lf/director-lf |
| `rechazado` | `#F06151` (red) | Rejected with reason, can resubmit |

### Data layer changes required

**Backend (`users_honors` table):**
- Add `status` enum column: `inscripto`, `en_progreso`, `enviado`, `validado`, `rechazado` (default: `inscripto`)
- Add `submitted_at` timestamp (nullable)
- Add `validated_by_id` FK to users (nullable)
- Add `validated_at` timestamp (nullable)
- Add `rejection_reason` text (nullable)
- Existing `validate: bool` becomes derived: `true` when `status = 'validado'`

**Backend (API):**
- `PATCH /users/:userId/honors/:honorId` — update status, upload evidence
- `POST /users/:userId/honors/:honorId/submit` — submit for review (sets status to `enviado`)
- `POST /users/:userId/honors/:honorId/validate` — coordinator validates/rejects

**Flutter (`UserHonor` entity):**
- Add `status: String` field
- Add `submittedAt`, `validatedById`, `validatedAt`, `rejectionReason` fields
- Keep `validate` as computed: `status == 'validado'`

## Screens

### Screen 1: Catalog (`honors_catalog_view`)

**Header:** Solid `#183651` background. Title "Especialidades" left-aligned, bold 20px. Badge pill top-right showing completed/total count (e.g. "5/17") with green highlight on completed number. Search bar below with subtle `rgba(255,255,255,0.08)` background.

**Search behavior:** Client-side filter on `honor.name`. Debounced 300ms, minimum 2 characters. New `searchQueryProvider` (StateProvider<String>).

**Category chips:** Horizontal scrollable row below header. First chip is "Todas" (selected by default, shows all honors). Active chip: solid `#2EA0DA` with white text. Inactive: `#F4F6F7` background, `#64748B` text. Rounded corners (`border-radius: 10px`). No emojis in chips — text only.

**Honor cards:** Vertical list. Each card:
- Background: `#FAFBFB`, border-radius 12px
- Left border 3px indicating state:
  - `#4FBF9F` = validado (completed)
  - `#FBBD5E` = enviado (submitted, awaiting review)
  - `#F06151` = en_progreso or rechazado
  - `#2EA0DA` = inscripto
  - none = available (not enrolled)
- Icon area: 44x44px rounded square (12px radius)
  - Validado: solid green with white checkmark SVG
  - Enrolled states: light tinted background with honor image
  - Available: `#F0F4F5` background with honor image
- Text: honor name (14px, bold, `#183651`), status subtitle below
- Validado: gold star badge (28px circle, `#FBBD5E`)
- Enrolled states: status label text
- Available: chevron-right icon

**States:**
- Loading: skeleton shimmer (3 placeholder cards with rounded rect shapes)
- Empty (no honors in category): illustration + "No hay especialidades en esta categoría"
- Error: retry button

### Screen 2: Detail (`honor_detail_view`)

**Header:** Solid `#183651`. Back arrow + breadcrumb (category name). Large icon (68px, rounded 18px) + honor name (22px bold) + badges (level, category) as small pills.

**Body (white):**
- Description text: `#64748B`, 13px, line-height 1.7
- Material download card: blue-tinted background (`#F0F8FF`), PDF icon in blue square (`#2EA0DA`), "Material de estudio" + file size, download arrow icon. Tapping downloads the PDF from `materialUrl` for offline use.
- CTA: full-width button, solid `#4FBF9F`, white text "Inscribirme", border-radius 12px, 16px padding

**Navigation states:**
- Not enrolled: show description + material + CTA "Inscribirme"
- Enrolled (any status): navigate to Screen 3 (evidence/progress view)
- Tapping a completed honor from catalog also goes to Screen 3 (read-only, showing validated state)

### Screen 3: Evidence & Progress (`honor_evidence_view` — new name)

This is the main working screen after enrollment.

**Header:** Color depends on status:
- `inscripto`/`en_progreso`: solid `#F06151`
- `enviado`: solid `#FBBD5E`
- `validado`: solid `#4FBF9F`
- `rechazado`: solid `#F06151`

Back arrow + "Mi especialidad". Honor icon (56px) + name (18px bold) + status badge pill.

**Status card:** Below header, a card showing current status with icon and description:
- `inscripto`: "Descargá el material, completá las actividades con tu instructor y subí la evidencia"
- `en_progreso`: "Tenés evidencia cargada. Cuando estés listo, enviala a revisión"
- `enviado`: "Tu evidencia fue enviada. Un coordinador la revisará pronto"
- `validado`: "¡Especialidad completada!" (with link to Screen 4 celebration)
- `rechazado`: "Tu evidencia fue rechazada: [rejection_reason]. Podés corregir y reenviar"

**Material download:** Same blue card as Screen 2, always visible for reference.

**Evidence section:**
- Title "Evidencia" (14px bold)
- 3-column grid of uploaded files (images show thumbnail, PDFs show PDF icon + filename)
- Last cell: dashed border "+" to add more (opens file picker: camera, gallery, or file browser for PDFs)
- Tapping a file opens fullscreen viewer (existing `SacImageViewer` for images, `flutter_pdfview` for PDFs)
- Long-press to delete (with confirmation dialog)
- Maximum: 10 files per honor (images + PDFs combined)
- File size limit: 10MB per file

**Actions (bottom):**
- `inscripto` with no evidence: "Subir evidencia" button (blue)
- `en_progreso` (has evidence): "Enviar a revisión" button (green) + "Subir más" (outline)
- `enviado`: No action buttons (waiting for review)
- `validado`: "Ver insignia" button (goes to Screen 4)
- `rechazado`: "Corregir y reenviar" button (green) — allows editing evidence and resubmitting

**Offline behavior:**
- Files selected offline are queued locally (Hive)
- Show "Pendiente de subir" indicator on queued files
- Auto-sync when connectivity returns
- "Enviar a revisión" disabled while files are pending upload

### Screen 4: Completed / Celebration (`honor_completion_view`)

**Header:** Solid `#4FBF9F`. Large checkmark in circle (72px), title "Especialidad Completa" (22px bold), completion date.

**Body:**
- Large badge circle (88px, `#FBBD5E`) with honor image
- Honor name (18px bold)
- Status pills: level (green tint), "Insignia obtenida" (yellow tint)
- Stats row: 3 columns in `#FAFBFB` card — Evidencias count (blue), Fecha inscripción (red), Duración total (green)
- Primary CTA: "Ver más especialidades" solid `#2EA0DA` (navigates back to catalog)
- Secondary: "Volver" outline button

Note: "Compartir logro" deferred to future enhancement (requires share_plus integration + card image generation).

## Navigation Flow

```
Catalog ──tap card──> Detail (not enrolled)
                        │
                        └──"Inscribirme"──> Evidence View (inscripto)
                                              │
Catalog ──tap card──> Evidence View (enrolled, any status)
                        │
                        └──"Enviar a revisión"──> Evidence View (enviado)
                        │
                        └──validated by coordinator──> Evidence View (validado)
                        │                                │
                        │                                └──"Ver insignia"──> Completion View
                        │
                        └──rejected──> Evidence View (rechazado)
                                        │
                                        └──"Corregir y reenviar"──> Evidence View (en_progreso)
```

## Widgets to modify/create

| Widget | Action | Notes |
|--------|--------|-------|
| `honor_category_chip` | **Create** | Horizontal chip for category selection |
| `honor_card` | **Redesign** | New card with border-left, status colors, handles all states |
| `honor_progress_card` | **Remove** | Merged into `honor_card` |
| `honor_category_card` | **Remove** | Replaced by `honor_category_chip` |
| `honors_catalog_view` | **Redesign** | New header with search, chips row, card list |
| `honor_detail_view` | **Redesign** | New header, description, material card, CTA |
| `honor_evidence_view` | **Create** | Evidence upload screen with status-based UI (replaces `add_honor_view`) |
| `honor_completion_view` | **Create** | Celebration screen |
| `add_honor_view` | **Remove** | Replaced by enrollment CTA in detail + evidence view |
| `my_honors_view` | **Keep/adapt** | Reuse new `honor_card` widget |

Final inventory: 4 views + 2 widgets (down from 4 views + 3 widgets, but 2 views are new).

## Design Principles

1. **No gradients** — solid colors only from SACDIA palette
2. **SVG icons** — no emojis in UI chrome (emojis OK for honor images when no real image exists)
3. **Touch targets** ≥ 44px per mobile-design skill
4. **State colors** — green=validado, yellow=enviado, red=en_progreso, blue=inscripto, grey=available
5. **Status-driven UI** — header color, actions, and content adapt to current honor status
6. **Border-left as state indicator** — 3px colored bar on catalog cards
7. **Chips not dropdowns** — category selection is horizontal scrollable chips with "Todas" default
8. **Offline-ready** — evidence files queue locally and sync when online

## Technical Notes

- **Data layer changes required** — new `status` field on `users_honors`, new API endpoints for submit/validate
- Presentation layer: 4 views redesigned/created, 2 widgets created, 3 removed
- Providers: add `searchQueryProvider`, update `HonorEnrollmentNotifier` for new status flow
- Backups created for all 7 original presentation files (`.backup.dart`)
- `HonorCard` widget accepts `Honor` + optional `UserHonor` to render all states
- Category chips use existing `honorCategoriesProvider` + prepend "Todas"
- Evidence upload reuses existing `StorageBucketAlias.EVIDENCE_FILES` infrastructure
- File picker: `file_picker` for PDFs, `image_picker` for camera/gallery (both already in project)
- Offline queue: store pending uploads in Hive, sync via `ConnectivityNotifier`
- Validation permissions: `honors:validate` permission required for coordinador/assistant-lf/director-lf roles
