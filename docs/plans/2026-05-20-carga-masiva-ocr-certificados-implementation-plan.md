# Carga Masiva OCR de Certificados Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a member-initiated OCR-assisted certificate bulk import flow for mixed honores/especialidades and clases, with mobile review, admin approval, correction/resubmission, and application into existing SACDIA domain tables.

**Architecture:** Add a backend `certificate-bulk-imports` workflow module that owns draft batches, extracted rows, OCR metadata, files, and audit events. Approved rows are applied transactionally and idempotently into existing tables (`users_honors`, `enrollments`, `evidence_files`, `investiture_validation_history`) instead of creating a parallel source of truth. The mobile app owns member upload/review/correction; the admin web owns Local Field approval/rejection.

**Tech Stack:** NestJS 11 + Prisma 7 + PostgreSQL + Jest; Flutter 3 + Riverpod + Dio + SACDIA `Sac*` widgets; Next.js 16 + shadcn/ui + Tailwind v4 + Vitest.

---

## Ground Rules

- Do **not** run builds. Use targeted tests/analyze only when needed.
- Use TDD: write failing tests before implementation code.
- Work in isolated worktrees for runtime repos because current `sacdia-backend`, `sacdia-admin`, and `sacdia-app` trees are not clean.
- OCR provider is intentionally abstracted. First implementation ships a pluggable `CertificateOcrProvider` with a safe stub/parser seam. Real provider selection can be added behind the same interface without changing UX/API.
- Do not add AI attribution or `Co-Authored-By` to commits.

## Existing Context

- Design doc: `/Users/abner/Documents/development/sacdia/docs/plans/2026-05-20-carga-masiva-ocr-certificados-design.md`
- Backend schema authority: `/Users/abner/Documents/development/sacdia/sacdia-backend/prisma/schema.prisma`
- App design system: `/Users/abner/Documents/development/sacdia/sacdia-app/DESIGN-SYSTEM.md`
- Admin design system: `/Users/abner/Documents/development/sacdia/sacdia-admin/DESIGN-SYSTEM.md`

---

## Phase 0: Isolated Worktrees

### Task 0.1: Create backend worktree

**Files:** none

**Step 1: Verify backend worktree directory is ignored**

Run:
```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend
git check-ignore -q .worktrees && echo ignored
```
Expected: `ignored`.

**Step 2: Create branch/worktree**

Run:
```bash
git worktree add .worktrees/codex/ocr-bulk-certificates -b codex/ocr-bulk-certificates
```
Expected: new backend worktree at `/Users/abner/Documents/development/sacdia/sacdia-backend/.worktrees/codex/ocr-bulk-certificates`.

### Task 0.2: Create app worktree

**Files:** none

**Step 1: Verify app worktree directory is ignored**

Run:
```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app
git check-ignore -q .worktrees && echo ignored
```
Expected: `ignored`.

**Step 2: Create branch/worktree**

Run:
```bash
git worktree add .worktrees/codex/ocr-bulk-certificates -b codex/ocr-bulk-certificates
```
Expected: new app worktree at `/Users/abner/Documents/development/sacdia/sacdia-app/.worktrees/codex/ocr-bulk-certificates`.

### Task 0.3: Create admin worktree

**Files:** maybe modify `/Users/abner/Documents/development/sacdia/sacdia-admin/.gitignore` if `.worktrees/` is not ignored.

**Step 1: Check for worktree directory preference**

Run:
```bash
cd /Users/abner/Documents/development/sacdia/sacdia-admin
ls -d .worktrees worktrees 2>/dev/null || true
git check-ignore -q .worktrees && echo ignored || echo not-ignored
```

**Step 2: If `.worktrees` is not ignored, add it**

Modify `/Users/abner/Documents/development/sacdia/sacdia-admin/.gitignore`:
```gitignore
.worktrees/
```

Commit separately:
```bash
git add .gitignore
git commit -m "chore: ignore local worktrees"
```

**Step 3: Create branch/worktree**

Run:
```bash
git worktree add .worktrees/codex/ocr-bulk-certificates -b codex/ocr-bulk-certificates
```

---

## Phase 1: Backend schema and workflow foundation

### Task 1.1: Add Prisma models/enums for import workflow

**Files:**
- Modify: `/Users/abner/Documents/development/sacdia/sacdia-backend/.worktrees/codex/ocr-bulk-certificates/prisma/schema.prisma`
- Create: `/Users/abner/Documents/development/sacdia/sacdia-backend/.worktrees/codex/ocr-bulk-certificates/src/certificate-bulk-imports/certificate-bulk-imports.schema.spec.ts`

**Step 1: Write schema expectation test**

Create a lightweight test that checks Prisma DMMF exposes required models once generated:
```ts
import { Prisma } from '@prisma/client';

describe('certificate bulk import schema', () => {
  it('exposes workflow models', () => {
    const modelNames = Prisma.dmmf.datamodel.models.map((model) => model.name);

    expect(modelNames).toEqual(
      expect.arrayContaining([
        'certificate_bulk_import_batches',
        'certificate_bulk_import_items',
        'certificate_bulk_import_files',
        'certificate_bulk_import_item_events',
      ]),
    );
  });
});
```

**Step 2: Run test and verify RED**

Run:
```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend/.worktrees/codex/ocr-bulk-certificates
pnpm exec jest src/certificate-bulk-imports/certificate-bulk-imports.schema.spec.ts --runInBand
```
Expected: FAIL because models do not exist.

**Step 3: Add enums and models**

Add enums:
```prisma
enum certificate_bulk_import_batch_status_enum {
  DRAFT
  READY_TO_SUBMIT
  SUBMITTED
  PARTIALLY_APPROVED
  APPROVED
  REJECTED
  NEEDS_CORRECTION
}

enum certificate_bulk_import_item_status_enum {
  NEEDS_REVIEW
  READY
  SUBMITTED
  APPROVED
  REJECTED
  RESUBMITTED
}

enum certificate_bulk_import_item_type_enum {
  HONOR
  CLASS
}

enum certificate_bulk_import_applied_entity_type_enum {
  USER_HONOR
  ENROLLMENT
}
```

Add models with FK relations to `users`, `honors`, `classes`, and timestamps. Use `String @db.Uuid` for batch IDs or `Int @default(autoincrement())`; prefer UUID for external API safety.

Required fields:
- batch: id, user_id, local_field_id nullable/int, status, raw_ocr_payload Json?, submitted_at, reviewed_at, active, created_at, modified_at.
- item: id, batch_id, type, honor_id?, class_id?, detected_name?, detected_date?, completed_at?, ocr_confidence?, field_confidence Json?, status, rejection_reason?, reviewed_by_id?, reviewed_at?, applied_entity_type?, applied_entity_id?, active, created_at, modified_at.
- file: id, batch_id, file_url, file_name, file_type, uploaded_by_id, ocr_raw_text?, active, created_at.
- event: id, batch_id, item_id?, action, performed_by_id?, comment?, payload Json?, created_at.

**Step 4: Generate Prisma client**

Run:
```bash
pnpm exec prisma generate
```
Expected: Prisma client regenerated.

**Step 5: Run test and verify GREEN**

Run:
```bash
pnpm exec jest src/certificate-bulk-imports/certificate-bulk-imports.schema.spec.ts --runInBand
```
Expected: PASS.

**Step 6: Commit**

```bash
git add prisma/schema.prisma src/certificate-bulk-imports/certificate-bulk-imports.schema.spec.ts
git commit -m "feat(certificate-imports): add workflow schema"
```

### Task 1.2: Add DTOs and constants

**Files:**
- Create: `/src/certificate-bulk-imports/dto/create-certificate-bulk-import.dto.ts`
- Create: `/src/certificate-bulk-imports/dto/update-certificate-import-item.dto.ts`
- Create: `/src/certificate-bulk-imports/dto/reject-certificate-import.dto.ts`
- Create: `/src/certificate-bulk-imports/dto/index.ts`
- Create: `/src/certificate-bulk-imports/certificate-bulk-imports.types.ts`
- Test: `/src/certificate-bulk-imports/dto/certificate-bulk-imports.dto.spec.ts`

**Step 1: Write failing DTO validation tests**

Test cases:
- reject reason required for item/batch rejection;
- item update requires `type`, target id, and `completed_at` before READY;
- invalid item type fails.

Run:
```bash
pnpm exec jest src/certificate-bulk-imports/dto/certificate-bulk-imports.dto.spec.ts --runInBand
```
Expected: FAIL.

**Step 2: Implement DTOs using `class-validator`**

Use `IsEnum`, `IsOptional`, `IsUUID`, `IsInt`, `IsDateString`, `IsString`, `MaxLength`, `ValidateIf`.

**Step 3: Run test GREEN and commit**

```bash
pnpm exec jest src/certificate-bulk-imports/dto/certificate-bulk-imports.dto.spec.ts --runInBand
git add src/certificate-bulk-imports/dto src/certificate-bulk-imports/certificate-bulk-imports.types.ts
git commit -m "feat(certificate-imports): add DTO contracts"
```

---

## Phase 2: Backend OCR seam and member workflow

### Task 2.1: Add OCR provider abstraction

**Files:**
- Create: `/src/certificate-bulk-imports/ocr/certificate-ocr.provider.ts`
- Create: `/src/certificate-bulk-imports/ocr/noop-certificate-ocr.provider.ts`
- Create: `/src/certificate-bulk-imports/ocr/certificate-ocr.parser.ts`
- Test: `/src/certificate-bulk-imports/ocr/certificate-ocr.parser.spec.ts`

**Step 1: Write failing parser tests**

Examples:
```ts
describe('CertificateOcrParser', () => {
  it('extracts mixed honor and class candidates from OCR text', () => {
    const parser = new CertificateOcrParser();

    const result = parser.parse(`
      Certificado de finalización
      Especialidades: Primeros Auxilios, Nudos y Amarras
      Clase: Amigo
      Fecha: 2026-04-12
    `);

    expect(result.items).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ type: 'HONOR', detectedName: 'Primeros Auxilios' }),
        expect.objectContaining({ type: 'HONOR', detectedName: 'Nudos y Amarras' }),
        expect.objectContaining({ type: 'CLASS', detectedName: 'Amigo' }),
      ]),
    );
    expect(result.items.every((item) => item.completedAt === '2026-04-12')).toBe(true);
  });
});
```

**Step 2: Run RED**

```bash
pnpm exec jest src/certificate-bulk-imports/ocr/certificate-ocr.parser.spec.ts --runInBand
```

**Step 3: Implement minimal parser**

Initial parser can be heuristic, not authoritative:
- extracts raw text;
- detects comma-separated specialties after known labels;
- detects class after `Clase:`;
- detects first ISO-ish date;
- marks confidence medium/low if uncertain.

**Step 4: Run GREEN and commit**

```bash
pnpm exec jest src/certificate-bulk-imports/ocr/certificate-ocr.parser.spec.ts --runInBand
git add src/certificate-bulk-imports/ocr
git commit -m "feat(certificate-imports): add OCR provider seam"
```

### Task 2.2: Add member workflow service

**Files:**
- Create: `/src/certificate-bulk-imports/certificate-bulk-imports.service.ts`
- Create: `/src/certificate-bulk-imports/certificate-bulk-imports.module.ts`
- Test: `/src/certificate-bulk-imports/certificate-bulk-imports.service.spec.ts`

**Step 1: Write failing service tests**

Behaviors:
- create draft batch for owner;
- process OCR creates items in `NEEDS_REVIEW` or `READY`;
- patch item can move it to `READY` when required fields exist;
- submit fails if any active item is incomplete;
- submit sets batch/items to `SUBMITTED`;
- rejected item can be resubmitted after correction.

**Step 2: Run RED**

```bash
pnpm exec jest src/certificate-bulk-imports/certificate-bulk-imports.service.spec.ts --runInBand
```

**Step 3: Implement service**

Use `PrismaService` and transactions. Keep upload storage integration as existing R2/storage utility if available; otherwise store file metadata after controller upload gives URL/key.

**Step 4: Run GREEN and commit**

```bash
pnpm exec jest src/certificate-bulk-imports/certificate-bulk-imports.service.spec.ts --runInBand
git add src/certificate-bulk-imports
git commit -m "feat(certificate-imports): add member workflow service"
```

### Task 2.3: Add member controller endpoints

**Files:**
- Create: `/src/certificate-bulk-imports/certificate-bulk-imports.controller.ts`
- Test: `/src/certificate-bulk-imports/certificate-bulk-imports.controller.spec.ts`
- Modify: `/src/app.module.ts`

**Step 1: Write failing controller tests**

Verify route methods delegate to service and enforce owner from JWT `req.user.sub`.

**Step 2: Implement controller**

Endpoints:
- `POST /certificate-bulk-imports`
- `POST /certificate-bulk-imports/:id/process-ocr`
- `GET /certificate-bulk-imports/:id`
- `PATCH /certificate-bulk-imports/:id/items/:itemId`
- `POST /certificate-bulk-imports/:id/submit`
- `POST /certificate-bulk-imports/:id/items/:itemId/resubmit`

Use `JwtAuthGuard`. Do not expose admin decisions here.

**Step 3: Register module and commit**

```bash
pnpm exec jest src/certificate-bulk-imports/certificate-bulk-imports.controller.spec.ts --runInBand
git add src/app.module.ts src/certificate-bulk-imports
git commit -m "feat(certificate-imports): expose member import endpoints"
```

---

## Phase 3: Backend admin approval and application rules

### Task 3.1: Add application service tests for HONOR rows

**Files:**
- Create/Modify: `/src/certificate-bulk-imports/certificate-bulk-imports-application.service.ts`
- Test: `/src/certificate-bulk-imports/certificate-bulk-imports-application.service.spec.ts`

**Step 1: Write failing tests**

Behaviors:
- approved HONOR creates `users_honors` if missing;
- approved HONOR reactivates inactive row;
- approved HONOR does not duplicate active row;
- proof is linked in `evidence_files.user_honor_id`;
- repeated approval is idempotent.

**Step 2: Implement minimal transactional application**

Set `validation_status = APPROVED`, `validate = true`, `date = completed_at`, `validated_by_id`, `validated_at`, `certificate`.

**Step 3: Test and commit**

```bash
pnpm exec jest src/certificate-bulk-imports/certificate-bulk-imports-application.service.spec.ts --runInBand
git add src/certificate-bulk-imports/certificate-bulk-imports-application.service.ts src/certificate-bulk-imports/certificate-bulk-imports-application.service.spec.ts
git commit -m "feat(certificate-imports): apply approved honors"
```

### Task 3.2: Add application service tests for CLASS rows

**Files:** same as Task 3.1

**Step 1: Write failing tests**

Behaviors:
- approved CLASS creates/reuses `enrollments` by `(user_id, class_id, ecclesiastical_year_id)`;
- does not use `users_classes`;
- stores reviewer metadata;
- records `investiture_validation_history` event;
- repeated approval is idempotent.

**Step 2: Implement class application**

Use existing `investiture_status_enum` carefully. Initial implementation should mark a certificate-approved class as `FIELD_APPROVED` or the final project-approved state only if existing investiture service confirms the transition. If uncertain, use a dedicated event and keep transition conservative.

**Step 3: Test and commit**

```bash
pnpm exec jest src/certificate-bulk-imports/certificate-bulk-imports-application.service.spec.ts --runInBand
git add src/certificate-bulk-imports/certificate-bulk-imports-application.service.ts src/certificate-bulk-imports/certificate-bulk-imports-application.service.spec.ts
git commit -m "feat(certificate-imports): apply approved classes"
```

### Task 3.3: Add admin service/controller endpoints

**Files:**
- Modify/Create: `/src/certificate-bulk-imports/admin-certificate-bulk-imports.controller.ts`
- Modify: `/src/certificate-bulk-imports/certificate-bulk-imports.service.ts`
- Test: `/src/certificate-bulk-imports/admin-certificate-bulk-imports.controller.spec.ts`

**Step 1: Write failing admin endpoint tests**

Endpoints:
- `GET /admin/certificate-bulk-imports/pending`
- `GET /admin/certificate-bulk-imports/:id`
- `POST /admin/certificate-bulk-imports/:id/approve`
- `POST /admin/certificate-bulk-imports/:id/reject`
- `POST /admin/certificate-bulk-imports/:id/items/:itemId/approve`
- `POST /admin/certificate-bulk-imports/:id/items/:itemId/reject`

**Step 2: Implement controller**

Use `JwtAuthGuard` + proper Local Field authorization. Start with roles `admin`, `super-admin`, `assistant-lf`, `director-lf` only if role naming exists in code; otherwise use canonical guards already used for LF scope. Do **not** rely on UI-only authorization.

**Step 3: Test and commit**

```bash
pnpm exec jest src/certificate-bulk-imports/admin-certificate-bulk-imports.controller.spec.ts --runInBand
git add src/certificate-bulk-imports
git commit -m "feat(certificate-imports): add admin review endpoints"
```

---

## Phase 4: Mobile app data layer

### Task 4.1: Add domain entities and models

**Files:**
- Create: `/sacdia-app/.worktrees/codex/ocr-bulk-certificates/lib/features/certificate_import/domain/entities/certificate_import_batch.dart`
- Create: `/lib/features/certificate_import/domain/entities/certificate_import_item.dart`
- Create: `/lib/features/certificate_import/data/models/certificate_import_batch_model.dart`
- Create: `/lib/features/certificate_import/data/models/certificate_import_item_model.dart`
- Test: `/sacdia-app/.worktrees/codex/ocr-bulk-certificates/test/features/certificate_import/data/models/certificate_import_model_test.dart`

**Step 1: Write failing model tests**

Verify JSON parses batch with mixed `HONOR` and `CLASS` rows.

**Step 2: Implement entities/models**

Use existing model style from honors/classes features.

**Step 3: Test and commit**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app/.worktrees/codex/ocr-bulk-certificates
flutter test test/features/certificate_import/data/models/certificate_import_model_test.dart
git add lib/features/certificate_import test/features/certificate_import
git commit -m "feat(certificate-imports): add mobile import models"
```

### Task 4.2: Add datasource/repository/providers

**Files:**
- Create: `/lib/features/certificate_import/data/datasources/certificate_import_remote_data_source.dart`
- Create: `/lib/features/certificate_import/data/repositories/certificate_import_repository_impl.dart`
- Create: `/lib/features/certificate_import/domain/repositories/certificate_import_repository.dart`
- Create: `/lib/features/certificate_import/domain/usecases/*.dart`
- Create: `/lib/features/certificate_import/presentation/providers/certificate_import_providers.dart`
- Tests under `/test/features/certificate_import/`

**Step 1: Write failing datasource/repository tests**

Mock Dio/client according to existing feature patterns.

**Step 2: Implement API calls**

Methods:
- create batch/upload files;
- process OCR;
- get batch;
- update item;
- submit batch;
- resubmit item.

**Step 3: Test and commit**

```bash
flutter test test/features/certificate_import
git add lib/features/certificate_import test/features/certificate_import
git commit -m "feat(certificate-imports): add mobile data flow"
```

---

## Phase 5: Mobile app UI

### Task 5.1: Add upload and processing screens

**Files:**
- Create: `/lib/features/certificate_import/presentation/views/certificate_import_upload_view.dart`
- Create: `/lib/features/certificate_import/presentation/views/certificate_import_processing_view.dart`
- Create widgets under `/lib/features/certificate_import/presentation/widgets/`
- Widget tests under `/test/features/certificate_import/presentation/`

**Step 1: Write widget tests**

Verify:
- upload screen shows `Subir comprobante`, `Tomar foto`, `Elegir archivo`;
- processing screen shows three states and manual fallback action.

**Step 2: Implement UI using `Sac*` widgets**

No raw buttons/cards if `Sac*` equivalent exists. Use `context.sac` colors.

**Step 3: Test and commit**

```bash
flutter test test/features/certificate_import/presentation/certificate_import_upload_view_test.dart
git add lib/features/certificate_import test/features/certificate_import
git commit -m "feat(certificate-imports): add mobile upload flow"
```

### Task 5.2: Add editable review cards and row editor

**Files:**
- Create: `/lib/features/certificate_import/presentation/views/certificate_import_review_view.dart`
- Create: `/lib/features/certificate_import/presentation/views/certificate_import_item_edit_view.dart`
- Create: `/lib/features/certificate_import/presentation/widgets/certificate_import_item_card.dart`
- Create: `/lib/features/certificate_import/presentation/widgets/certificate_import_summary_header.dart`
- Tests under `/test/features/certificate_import/presentation/`

**Step 1: Write widget tests**

Verify:
- mixed HONOR/CLASS cards render badges;
- CTA disabled when item missing target/date;
- edit view requires date and catalog match;
- rejected row shows correction CTA.

**Step 2: Implement list with efficient builder**

Use `ListView.builder`/slivers, not unbounded `SingleChildScrollView` with many children.

**Step 3: Test and commit**

```bash
flutter test test/features/certificate_import/presentation/certificate_import_review_view_test.dart
git add lib/features/certificate_import test/features/certificate_import
git commit -m "feat(certificate-imports): add mobile review cards"
```

### Task 5.3: Add status and imported-record proof view

**Files:**
- Create: `/lib/features/certificate_import/presentation/views/certificate_import_status_view.dart`
- Create: `/lib/features/certificate_import/presentation/views/imported_certificate_record_view.dart`
- Modify: honors/classes detail routing to route imported records to simplified proof view once backend metadata is present.

**Step 1: Write tests**

Verify imported record does not render progress/checklist modules; it renders proof, approved by, and approval date.

**Step 2: Implement view**

Use proof preview via existing image/pdf viewer widgets (`SacImageViewer`, `SacPdfViewer` as appropriate).

**Step 3: Test and commit**

```bash
flutter test test/features/certificate_import/presentation/imported_certificate_record_view_test.dart
git add lib/features/certificate_import lib/core/config test/features/certificate_import
git commit -m "feat(certificate-imports): add imported proof views"
```

### Task 5.4: Add routes and entry points

**Files:**
- Modify: `/lib/core/config/route_names.dart`
- Modify: `/lib/core/config/router.dart`
- Modify relevant home/profile/honors/classes entry point to expose `Carga por certificado`.

**Step 1: Add route tests if existing router tests exist; otherwise add smoke widget test**

**Step 2: Implement routes**

Route names suggested:
- `/certificate-imports/new`
- `/certificate-imports/:batchId/review`
- `/certificate-imports/:batchId/status`
- `/certificate-imports/:batchId/items/:itemId/edit`
- `/certificate-imports/imported-record/:type/:id`

**Step 3: Test and commit**

```bash
flutter test test/features/certificate_import
git add lib/core/config lib/features/certificate_import
git commit -m "feat(certificate-imports): wire mobile routes"
```

---

## Phase 6: Admin web API and UI

### Task 6.1: Add admin API client

**Files:**
- Create: `/sacdia-admin/.worktrees/codex/ocr-bulk-certificates/src/lib/api/certificate-bulk-imports.ts`
- Test: `/sacdia-admin/.worktrees/codex/ocr-bulk-certificates/src/lib/api/certificate-bulk-imports.test.ts`

**Step 1: Write failing API tests**

Verify functions call expected paths and parse `{ status, data }`.

**Step 2: Implement client**

Functions:
- `getCertificateBulkImportsPending`
- `getCertificateBulkImportDetail`
- `approveCertificateBulkImport`
- `rejectCertificateBulkImport`
- `approveCertificateBulkImportItem`
- `rejectCertificateBulkImportItem`

**Step 3: Test and commit**

```bash
cd /Users/abner/Documents/development/sacdia/sacdia-admin/.worktrees/codex/ocr-bulk-certificates
pnpm test src/lib/api/certificate-bulk-imports.test.ts
git add src/lib/api/certificate-bulk-imports.ts src/lib/api/certificate-bulk-imports.test.ts
git commit -m "feat(certificate-imports): add admin API client"
```

### Task 6.2: Add admin list page

**Files:**
- Create: `/src/app/(dashboard)/dashboard/certificate-bulk-imports/page.tsx`
- Create: `/src/components/certificate-bulk-imports/certificate-bulk-imports-client-page.tsx`
- Create: `/src/components/certificate-bulk-imports/certificate-bulk-imports-table.tsx`
- Create badges/KPI cards as needed.
- Tests under `/src/components/certificate-bulk-imports/`

**Step 1: Write component tests**

Verify table renders pending batch, status badges, progress counts, and Review action.

**Step 2: Implement page and client components**

Follow evidence-review pattern: Server Component loads initial data; client component handles refresh/tabs/filters.

**Step 3: Test and commit**

```bash
pnpm test src/components/certificate-bulk-imports
git add src/app src/components/certificate-bulk-imports
git commit -m "feat(certificate-imports): add admin review list"
```

### Task 6.3: Add admin detail split view and dialogs

**Files:**
- Create: `/src/app/(dashboard)/dashboard/certificate-bulk-imports/[batchId]/page.tsx`
- Create: `/src/components/certificate-bulk-imports/certificate-bulk-import-detail.tsx`
- Create: `/src/components/certificate-bulk-imports/certificate-bulk-import-file-viewer.tsx`
- Create: `/src/components/certificate-bulk-imports/certificate-bulk-import-items-table.tsx`
- Create: `/src/components/certificate-bulk-imports/certificate-bulk-import-approve-dialog.tsx`
- Create: `/src/components/certificate-bulk-imports/certificate-bulk-import-reject-dialog.tsx`
- Tests for dialogs/detail.

**Step 1: Write tests**

Verify:
- split proof viewer + item list render;
- reject dialog requires reason;
- approve batch confirms only valid pending rows;
- item approve/reject calls correct API.

**Step 2: Implement components**

Use `Card`, `Table`, `Dialog`, `Button`, `Textarea`, `StatusBadge`, `sonner`. Keep evidence preview sticky on desktop.

**Step 3: Test and commit**

```bash
pnpm test src/components/certificate-bulk-imports
git add src/app src/components/certificate-bulk-imports
git commit -m "feat(certificate-imports): add admin review detail"
```

### Task 6.4: Add navigation and messages

**Files:**
- Modify: `/src/components/layout/*` or nav config file where dashboard entries live.
- Modify: `/messages/es.json` and any active locale files.

**Step 1: Add navigation tests if existing; otherwise use targeted component tests**

**Step 2: Implement nav label**

Suggested label: `Cargas por certificado` under validation/investiture area.

**Step 3: Test and commit**

```bash
pnpm test src/components/certificate-bulk-imports
git add src/components/layout messages
git commit -m "feat(certificate-imports): expose admin navigation"
```

---

## Phase 7: Docs and contracts

### Task 7.1: Update API and feature docs

**Files:**
- Modify: `/Users/abner/Documents/development/sacdia/docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- Modify: `/Users/abner/Documents/development/sacdia/docs/features/honores.md`
- Modify: `/Users/abner/Documents/development/sacdia/docs/features/clases-progresivas.md`
- Create: `/Users/abner/Documents/development/sacdia/docs/features/carga-masiva-certificados.md`

**Step 1: Document endpoints and domain rules**

Add member/admin endpoint tables and the invariant: OCR proposes, member confirms, Campo Local validates.

**Step 2: Commit docs**

```bash
git add docs/api/ENDPOINTS-LIVE-REFERENCE.md docs/features/honores.md docs/features/clases-progresivas.md docs/features/carga-masiva-certificados.md
git commit -m "docs: document certificate bulk imports"
```

---

## Phase 8: Verification before PRs

### Task 8.1: Backend targeted verification

Run only targeted tests, no build:
```bash
cd /Users/abner/Documents/development/sacdia/sacdia-backend/.worktrees/codex/ocr-bulk-certificates
pnpm exec jest src/certificate-bulk-imports --runInBand
```

### Task 8.2: App targeted verification

Run:
```bash
cd /Users/abner/Documents/development/sacdia/sacdia-app/.worktrees/codex/ocr-bulk-certificates
flutter test test/features/certificate_import
flutter analyze
```

### Task 8.3: Admin targeted verification

Run:
```bash
cd /Users/abner/Documents/development/sacdia/sacdia-admin/.worktrees/codex/ocr-bulk-certificates
pnpm test src/components/certificate-bulk-imports src/lib/api/certificate-bulk-imports.test.ts
pnpm exec tsc --noEmit
```

### Task 8.4: Manual UI verification

- Mobile: open local app if requested by user only; do not build.
- Admin: use Browser plugin on `localhost:3001` only if dev server is already running or user explicitly asks to start it.

---

## Review Workload Forecast

- Chained PRs recommended: Yes.
- 400-line budget risk: High.
- Estimated changed lines: >2,000 across backend/app/admin/docs.
- Decision needed before apply: Yes.

Recommended PR chain:
1. Backend workflow schema + member/admin endpoints.
2. Mobile app member upload/review/status UI.
3. Admin approval console.
4. Docs and polish.

