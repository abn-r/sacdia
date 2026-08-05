# Monthly Report R2 Artifacts Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Persist every generated monthly-report PDF as one canonical private R2 artifact, overwrite it on regeneration, backfill historical reports and render all artifacts with the approved three-page Letter format.

**Architecture:** Keep PDFKit as the selectable-text renderer and separate rendering from storage in a new `MonthlyReportArtifactsService`. Use a deterministic private R2 key plus integrity metadata on `monthly_reports`; normal generation renders and uploads before the atomic `draft -> generated` transition, while historical downloads and a one-shot script repair missing or outdated artifacts idempotently.

**Tech Stack:** NestJS 11, Prisma/PostgreSQL, PDFKit, Cloudflare R2 through `FileStorageService`, Jest, BullMQ/distributed locks, Next.js admin adapter, pnpm.

---

## Preconditions and execution boundaries

- Execute contract-first from isolated worktrees based on fresh `development`:
  - `sacdia-backend/.worktrees/monthly-report-r2-artifacts`
  - `sacdia-admin/.worktrees/monthly-report-r2-artifacts`
  - root docs worktree for canonical documentation
- Do not merge the already-created printable-layout branch implicitly. Either
  stack the backend/admin implementation on the approved commits or merge those
  commits explicitly before wiring the admin preview.
- Do not invent brand assets. The official SVG files must be supplied before the
  renderer-logo step can pass acceptance.
- Do not run a production backfill until the R2 bucket, CORS policy and database
  migration are deployed.
- Do not run a build. Use focused tests, lint, Prisma validation and typecheck.

### Canonical constants

Create `sacdia-backend/src/monthly-reports/monthly-report-artifact.constants.ts`:

```ts
export const MONTHLY_REPORT_PDF_TEMPLATE_VERSION =
  'monthly-report-v2-three-page';

export function buildMonthlyReportPdfKey(input: {
  reportId: string;
  enrollmentId: string;
  month: number;
  year: number;
}): string {
  return [
    String(input.year),
    String(input.month).padStart(2, '0'),
    input.enrollmentId,
    `${input.reportId}.pdf`,
  ].join('/');
}
```

The storage service adds the `monthly-reports` configured prefix. Never include
the prefix twice.

---

### Task 1: Add the monthly-report PDF artifact schema

**Files:**
- Create: `sacdia-backend/prisma/migrations/20260805190000_monthly_report_pdf_artifacts/migration.sql`
- Modify: `sacdia-backend/prisma/schema.prisma:3358-3382`
- Modify: `docs/database/schema.prisma:3541-3565`
- Modify: `docs/database/SCHEMA-REFERENCE.md`

**Step 1: Write the migration first**

```sql
ALTER TABLE "monthly_reports"
  ADD COLUMN "pdf_r2_key" VARCHAR(512),
  ADD COLUMN "pdf_size_bytes" BIGINT,
  ADD COLUMN "pdf_sha256" CHAR(64),
  ADD COLUMN "pdf_generated_at" TIMESTAMPTZ(6),
  ADD COLUMN "pdf_template_version" VARCHAR(32);

CREATE INDEX "idx_monthly_reports_pdf_template_version"
  ON "monthly_reports" ("pdf_template_version");

ALTER TABLE "monthly_reports"
  ADD CONSTRAINT "monthly_reports_pdf_metadata_complete_chk" CHECK (
    ("pdf_r2_key" IS NULL
      AND "pdf_size_bytes" IS NULL
      AND "pdf_sha256" IS NULL
      AND "pdf_generated_at" IS NULL
      AND "pdf_template_version" IS NULL)
    OR
    ("pdf_r2_key" IS NOT NULL
      AND "pdf_size_bytes" IS NOT NULL
      AND "pdf_size_bytes" > 0
      AND "pdf_sha256" IS NOT NULL
      AND "pdf_sha256" ~ '^[0-9a-f]{64}$'
      AND "pdf_generated_at" IS NOT NULL
      AND "pdf_template_version" IS NOT NULL)
  );
```

**Step 2: Add the Prisma fields**

```prisma
pdf_r2_key            String?   @db.VarChar(512)
pdf_size_bytes        BigInt?
pdf_sha256            String?   @db.Char(64)
pdf_generated_at      DateTime? @db.Timestamptz(6)
pdf_template_version  String?   @db.VarChar(32)
```

Add `@@index([pdf_template_version], map: "idx_monthly_reports_pdf_template_version")`.

**Step 3: Validate both schema copies**

Run:

```bash
cd sacdia-backend
pnpm exec prisma validate
git diff --check
```

Expected: Prisma reports a valid schema and `git diff --check` exits `0`.

**Step 4: Commit**

```bash
git add prisma/schema.prisma prisma/migrations/20260805190000_monthly_report_pdf_artifacts/migration.sql
git commit -m "feat(reports): add monthly PDF artifact metadata"
```

Commit the two canonical database-document updates in the docs worktree:

```bash
git add docs/database/schema.prisma docs/database/SCHEMA-REFERENCE.md
git commit -m "docs(database): document monthly PDF artifacts"
```

---

### Task 2: Add the private R2 storage alias

**Files:**
- Modify: `sacdia-backend/src/common/services/file-storage.service.ts`
- Modify: `sacdia-backend/src/common/services/r2-file-storage.service.ts:432-575`
- Modify: `sacdia-backend/src/common/services/r2-file-storage.service.spec.ts`
- Modify: `sacdia-backend/src/config/env.validation.ts`
- Modify: `sacdia-backend/.env.example`
- Modify: `docs/storage/r2-keyprefix-conventions.md`

**Step 1: Write failing storage configuration tests**

Add tests asserting that:

```ts
expect(
  await service.upload(
    StorageBucketAlias.MONTHLY_REPORTS,
    '2026/08/enrollment/report.pdf',
    Buffer.from('%PDF'),
    { contentType: 'application/pdf', overwrite: true },
  ),
).toEqual(
  expect.objectContaining({
    key: 'monthly-reports/2026/08/enrollment/report.pdf',
  }),
);
```

Also assert `PutObjectCommand` receives `ContentType: application/pdf` and that
`overwrite: true` does not issue a pre-upload HEAD request.

**Step 2: Run the RED test**

```bash
pnpm test -- r2-file-storage.service.spec.ts --runInBand
```

Expected: FAIL because `MONTHLY_REPORTS` is not a storage alias.

**Step 3: Implement the alias and validated environment**

Add:

```ts
MONTHLY_REPORTS = 'MONTHLY_REPORTS',
```

Configure it as private:

```ts
case StorageBucketAlias.MONTHLY_REPORTS:
  return {
    bucket: this.getRequiredEnv('R2_BUCKET_MONTHLY_REPORTS'),
    publicBaseUrl: this.getRequiredEnv('R2_PUBLIC_URL_MONTHLY_REPORTS'),
    keyPrefix: this.getOptionalEnv(
      'R2_KEY_PREFIX_MONTHLY_REPORTS',
      'monthly-reports',
    ),
    isPublic: false,
  };
```

Add the three environment variables to Joi validation and `.env.example`.
Document that the bucket has no public ACL and access is signed-only.

**Step 4: Run GREEN tests**

```bash
pnpm test -- r2-file-storage.service.spec.ts --runInBand
```

Expected: PASS.

**Step 5: Commit**

```bash
git add src/common/services/file-storage.service.ts \
  src/common/services/r2-file-storage.service.ts \
  src/common/services/r2-file-storage.service.spec.ts \
  src/config/env.validation.ts .env.example
git commit -m "feat(storage): add private monthly reports bucket"
```

Commit `docs/storage/r2-keyprefix-conventions.md` separately in the docs
worktree with `docs(storage): document monthly report artifacts`.

---

### Task 3: Convert the backend renderer to the approved three-page document

**Files:**
- Create: `sacdia-backend/src/monthly-reports/monthly-report-artifact.constants.ts`
- Create: `sacdia-backend/src/monthly-reports/monthly-reports-pdf.service.spec.ts`
- Modify: `sacdia-backend/src/monthly-reports/monthly-reports-pdf.service.ts`
- Create: `sacdia-backend/assets/brand/iasd-logo-horizontal.svg`
- Create: `sacdia-backend/assets/brand/iasd-symbol.svg`
- Modify: `sacdia-backend/package.json`
- Modify: `sacdia-backend/pnpm-lock.yaml`

**Step 1: Add RED renderer tests**

Build a complete Prisma fixture containing one generated report, snapshot,
manual data, enrollment relations and submitter. Assert:

```ts
const pdf = await service.generatePdf(REPORT_ID);
expect(pdf.subarray(0, 4).toString()).toBe('%PDF');
expect((pdf.toString('latin1').match(/\/Type\s*\/Page\b/g) ?? []).length)
  .toBe(3);
```

Add a second fixture omitting unsupported historical values and assert the
renderer still returns three pages rather than fabricating values or throwing.

**Step 2: Run RED**

```bash
pnpm test -- monthly-reports-pdf.service.spec.ts --runInBand
```

Expected: FAIL because the current renderer is two pages.

**Step 3: Implement the explicit layout**

Initialize PDFKit with:

```ts
new PDFDocument({
  size: 'LETTER',
  margin: 0,
  bufferPages: true,
  autoFirstPage: false,
});
```

Render exactly three pages with fixed content boxes and no automatic section
page creation:

```ts
drawPageOne(doc, model);   // Administración + Enseñanzas
doc.addPage({ size: 'LETTER', margin: 0 });
drawPageTwo(doc, model);   // Actividades + Finanzas
doc.addPage({ size: 'LETTER', margin: 0 });
drawPageThree(doc, model); // Misión + Servicio + Firmas
drawFooters(doc, 3);
```

Use the same approved color tokens and neutral full KPI borders. Remove the old
blue card theme and colored left rules. Every text call must use PDFKit text,
not rasterized screenshots.

Add a normalized renderer model whose optional fields default to `''`, never to
invented values:

```ts
const blank = (value: unknown): string =>
  value === null || value === undefined ? '' : String(value);
```

Limit persisted lists to the available table rows and show additional counts in
an overflow note instead of creating a fourth page.

**Step 4: Embed only official vector logos**

Add `svg-to-pdfkit` and embed the official supplied SVG files. If the assets are
not available, stop this step and record the blocker; do not create substitutes.

**Step 5: Run GREEN and inspect a fixture PDF**

```bash
pnpm test -- monthly-reports-pdf.service.spec.ts --runInBand
git diff --check
```

Expected: PASS with exactly three pages.

Save a local fixture PDF under `/tmp` for visual inspection; do not commit it.
Verify all text is selectable and no section intersects the footer.

**Step 6: Commit**

```bash
git add src/monthly-reports/monthly-report-artifact.constants.ts \
  src/monthly-reports/monthly-reports-pdf.service.ts \
  src/monthly-reports/monthly-reports-pdf.service.spec.ts \
  assets/brand package.json pnpm-lock.yaml
git commit -m "feat(reports): render monthly PDF in three pages"
```

---

### Task 4: Implement the canonical R2 artifact service

**Files:**
- Create: `sacdia-backend/src/monthly-reports/monthly-report-artifacts.service.ts`
- Create: `sacdia-backend/src/monthly-reports/monthly-report-artifacts.service.spec.ts`
- Modify: `sacdia-backend/src/monthly-reports/monthly-reports.module.ts`

**Step 1: Write RED artifact tests**

Test these cases with mocked PDF, Prisma and `FILE_STORAGE_SERVICE`:

1. deterministic key generation;
2. upload uses `application/pdf` and `overwrite: true`;
3. metadata contains byte size, lowercase SHA-256, timestamp and template
   version;
4. regeneration uses the same R2 key;
5. upload failure performs no Prisma metadata update;
6. signed retrieval rejects `draft` reports;
7. missing/outdated metadata triggers lazy repair from frozen snapshot.

Example expectation:

```ts
expect(fileStorage.upload).toHaveBeenCalledWith(
  StorageBucketAlias.MONTHLY_REPORTS,
  `${year}/${monthPadded}/${enrollmentId}/${reportId}.pdf`,
  pdfBuffer,
  { contentType: 'application/pdf', overwrite: true },
);
```

**Step 2: Run RED**

```bash
pnpm test -- monthly-report-artifacts.service.spec.ts --runInBand
```

Expected: FAIL because the service does not exist.

**Step 3: Implement the service**

The public methods should be explicit:

```ts
renderAndUpload(input: {
  reportId: string;
  snapshotOverride?: SnapshotData;
}): Promise<MonthlyReportPdfArtifact>;

ensureCurrentArtifact(reportId: string): Promise<MonthlyReportPdfArtifact>;

getStoredPdfBuffer(reportId: string): Promise<Buffer>;
```

`renderAndUpload` calculates:

```ts
const sha256 = createHash('sha256').update(pdf).digest('hex');
```

Persist metadata only after a successful R2 upload. For the authorized backend
download, resolve a short-lived signed URL, fetch it server-side and return the
Buffer so the existing `application/pdf` response contract remains unchanged.
Reject non-2xx R2 responses and never log the signed URL.

**Step 4: Run GREEN**

```bash
pnpm test -- monthly-report-artifacts.service.spec.ts --runInBand
```

Expected: PASS.

**Step 5: Commit**

```bash
git add src/monthly-reports/monthly-report-artifacts.service.ts \
  src/monthly-reports/monthly-report-artifacts.service.spec.ts \
  src/monthly-reports/monthly-reports.module.ts
git commit -m "feat(reports): persist monthly PDFs in R2"
```

---

### Task 5: Make automatic generation artifact-first and retry-safe

**Files:**
- Modify: `sacdia-backend/src/monthly-reports/monthly-reports.service.ts:256-314`
- Modify: `sacdia-backend/src/monthly-reports/monthly-reports.service.spec.ts`
- Modify: `sacdia-backend/src/background-jobs/__tests__/background-jobs.processor.monthly-reports.spec.ts`

**Step 1: Add RED generation tests**

Cover:

- R2 upload happens before the `draft -> generated` update;
- PDF or R2 failure leaves status and snapshot unchanged;
- a per-report distributed lock prevents concurrent generation;
- a failed database transition after upload performs best-effort R2 cleanup;
- BullMQ propagates a storage failure so configured retries execute;
- successful auto-generation persists all artifact metadata.

**Step 2: Run RED**

```bash
pnpm test -- monthly-reports.service.spec.ts \
  background-jobs.processor.monthly-reports.spec.ts --runInBand
```

Expected: FAIL because generation currently marks the report generated before
any R2 operation.

**Step 3: Refactor `generate()`**

Use a five-minute lock:

```ts
const lockKey = `monthly-report:generate:${reportId}`;
const acquired = await this.lockService.tryAcquire(lockKey, 5 * 60_000);
if (!acquired) throw new AppConflictException(...);
```

Inside `try/finally`:

1. verify `draft`;
2. calculate preview;
3. render/upload with `snapshotOverride`;
4. conditionally update `draft -> generated` with snapshot and artifact
   metadata;
5. on transition failure, delete the uploaded key best-effort;
6. always release the lock.

Do not swallow errors in `runAutoGeneration`; keep per-record logging, but make
the BullMQ processor fail when the batch contains storage errors so its retry
policy can reconcile them. Preserve idempotent skipping of already complete
current artifacts.

**Step 4: Run GREEN**

```bash
pnpm test -- monthly-reports.service.spec.ts \
  background-jobs.processor.monthly-reports.spec.ts --runInBand
```

Expected: PASS.

**Step 5: Commit**

```bash
git add src/monthly-reports/monthly-reports.service.ts \
  src/monthly-reports/monthly-reports.service.spec.ts \
  src/background-jobs/__tests__/background-jobs.processor.monthly-reports.spec.ts
git commit -m "feat(reports): store PDFs during auto generation"
```

---

### Task 6: Serve stored PDFs and add explicit regeneration

**Files:**
- Modify: `sacdia-backend/src/monthly-reports/monthly-reports.controller.ts`
- Create: `sacdia-backend/src/monthly-reports/monthly-reports.controller.spec.ts`
- Modify: `sacdia-backend/src/monthly-reports/monthly-reports.service.ts`
- Modify: `sacdia-backend/src/monthly-reports/monthly-reports.service.spec.ts`
- Modify: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- Modify: `docs/api/FRONTEND-INTEGRATION-GUIDE.md`

**Step 1: Write RED endpoint tests**

Test that:

- `GET /:reportId/pdf` returns the stored Buffer with `application/pdf`;
- missing artifact invokes lazy repair once;
- `POST /:reportId/regenerate` accepts only `generated|submitted`;
- regeneration preserves snapshot, manual data and workflow status;
- regeneration overwrites the canonical key and updates metadata;
- permissions and `AuthorizationResource` remain enforced.

**Step 2: Run RED**

```bash
pnpm test -- monthly-reports.controller.spec.ts \
  monthly-reports.service.spec.ts --runInBand
```

Expected: FAIL because downloads render on demand and no regeneration endpoint
exists.

**Step 3: Implement the contract**

Keep download response headers compatible. Add:

```text
POST /api/v1/monthly-reports/:reportId/regenerate
Permission: reports:write
Allowed status: generated | submitted
Response: { status: "success", data: MonthlyReport }
```

The endpoint rerenders the frozen snapshot and updates only artifact metadata.
It must not change `generated_at`, `submitted_at`, `submitted_by` or status.

**Step 4: Run GREEN**

```bash
pnpm test -- monthly-reports.controller.spec.ts \
  monthly-reports.service.spec.ts --runInBand
```

Expected: PASS.

**Step 5: Commit backend and docs separately**

```bash
git add src/monthly-reports
git commit -m "feat(reports): serve and regenerate stored PDFs"
```

```bash
git add docs/api/ENDPOINTS-LIVE-REFERENCE.md \
  docs/api/FRONTEND-INTEGRATION-GUIDE.md
git commit -m "docs(api): document stored monthly PDFs"
```

---

### Task 7: Add an idempotent historical backfill

**Files:**
- Create: `sacdia-backend/scripts/backfill-monthly-report-pdfs.ts`
- Create: `sacdia-backend/scripts/backfill-monthly-report-pdfs.spec.ts`
- Modify: `sacdia-backend/package.json`
- Create: `docs/runbooks/monthly-report-pdf-backfill.md`

**Step 1: Write RED selection and continuation tests**

Assert that the script selects only `generated|submitted` rows where the key is
null or template version differs. Cover:

- `--dry-run` performs no upload/update;
- `--limit` caps total processed rows;
- `--batch-size` uses cursor pagination by `monthly_report_id`;
- one failed record is logged and later records continue;
- rerunning a successful batch skips current artifacts;
- SIGINT stops after the current record and prints the continuation cursor.

**Step 2: Run RED**

```bash
pnpm test -- scripts/backfill-monthly-report-pdfs.spec.ts --runInBand
```

Expected: FAIL because the script does not exist.

**Step 3: Implement the script**

Add package command:

```json
"reports:backfill-pdfs": "tsx scripts/backfill-monthly-report-pdfs.ts"
```

Required invocation:

```bash
pnpm reports:backfill-pdfs -- --dry-run --batch-size 25 --limit 100
```

The real run must require an explicit `--apply` flag. Never make apply the
default.

**Step 4: Run GREEN**

```bash
pnpm test -- scripts/backfill-monthly-report-pdfs.spec.ts --runInBand
```

Expected: PASS.

**Step 5: Commit**

```bash
git add scripts/backfill-monthly-report-pdfs.ts \
  scripts/backfill-monthly-report-pdfs.spec.ts package.json
git commit -m "feat(reports): add monthly PDF backfill"
```

Commit the runbook in the docs worktree:

```bash
git add docs/runbooks/monthly-report-pdf-backfill.md
git commit -m "docs(runbook): add monthly PDF backfill"
```

---

### Task 8: Reconcile the admin regeneration action and artifact metadata

**Files:**
- Modify: `sacdia-admin/src/lib/api/monthly-reports.ts`
- Modify: `sacdia-admin/src/lib/api/monthly-reports.test.ts`
- Modify: `sacdia-admin/src/components/reports/report-detail-client.tsx`
- Create or modify: `sacdia-admin/src/components/reports/report-detail-client.test.tsx`
- Modify: `sacdia-admin/src/i18n/messages.d.ts` only through the project i18n generation workflow if messages change

**Step 1: Write RED adapter tests**

Extend `MonthlyReport` with:

```ts
pdf_r2_key?: string | null;
pdf_size_bytes?: string | number | null;
pdf_sha256?: string | null;
pdf_generated_at?: string | null;
pdf_template_version?: string | null;
```

Add `regenerateReport(reportId)` and assert it calls:

```text
POST /monthly-reports/:reportId/regenerate
```

Add a component regression proving a generated report calls regenerate rather
than the draft-only generate endpoint.

**Step 2: Run RED**

```bash
pnpm exec vitest run src/lib/api/monthly-reports.test.ts \
  src/components/reports/report-detail-client.test.tsx
```

Expected: FAIL because the adapter and action do not exist.

**Step 3: Implement the minimal client change**

Keep download behavior unchanged: it still fetches the authorized backend PDF
endpoint as a Blob. Route generated reports to `regenerateReport`; route drafts
to `generateReport`. Submitted reports remain download-only unless the user's
role and product rules explicitly expose administrative regeneration.

**Step 4: Run GREEN**

```bash
pnpm exec vitest run src/lib/api/monthly-reports.test.ts \
  src/components/reports/report-detail-client.test.tsx
pnpm exec eslint src/lib/api/monthly-reports.ts \
  src/components/reports/report-detail-client.tsx
```

Expected: tests and focused lint pass.

**Step 5: Commit**

```bash
git add src/lib/api/monthly-reports.ts \
  src/lib/api/monthly-reports.test.ts \
  src/components/reports/report-detail-client.tsx \
  src/components/reports/report-detail-client.test.tsx
git commit -m "feat(reports): regenerate stored monthly PDFs"
```

---

### Task 9: Update the canonical feature contract

**Files:**
- Modify: `docs/features/monthly-reports.md`
- Modify: `docs/README.md` if the new runbook or storage document needs indexing

**Step 1: Document the final lifecycle**

Replace the statement that PDFs are always generated under demand. Document:

```text
draft
  -> render candidate PDF
  -> upload canonical private R2 object
  -> persist snapshot + artifact metadata
  -> generated
  -> submitted
```

Document lazy repair, explicit regeneration, deterministic overwrite behavior,
template version, historical blank fields and private-download authorization.

**Step 2: Cross-check code and docs**

```bash
rg -n "pdf_r2_key|pdf_template_version|regenerate|MONTHLY_REPORTS" \
  sacdia-backend docs sacdia-admin
git diff --check
```

Expected: schema, runtime, client and docs use the same names.

**Step 3: Commit**

```bash
git add docs/features/monthly-reports.md docs/README.md
git commit -m "docs(reports): document canonical PDF artifacts"
```

---

### Task 10: Verify without building and prepare deployment

**Files:**
- No production file changes unless a verification failure exposes a defect

**Step 1: Run focused backend tests**

```bash
cd sacdia-backend
pnpm test -- monthly-reports r2-file-storage \
  background-jobs.processor.monthly-reports \
  backfill-monthly-report-pdfs --runInBand
```

Expected: all focused suites pass.

**Step 2: Run backend static checks without build**

```bash
pnpm exec eslint src/monthly-reports \
  src/common/services/file-storage.service.ts \
  src/common/services/r2-file-storage.service.ts \
  scripts/backfill-monthly-report-pdfs.ts
pnpm exec tsc --noEmit
pnpm exec prisma validate
git diff --check
```

Expected: all commands pass. If repository-wide pre-existing failures appear,
record them with exact paths and prove no changed file is implicated.

**Step 3: Run focused admin checks**

```bash
cd sacdia-admin
pnpm exec vitest run src/lib/api/monthly-reports.test.ts \
  src/components/reports/report-detail-client.test.tsx \
  src/components/reports/monthly-report/monthly-report.test.tsx
pnpm exec eslint src/lib/api/monthly-reports.ts \
  src/components/reports/report-detail-client.tsx \
  src/components/reports/monthly-report
git diff --check
```

Expected: all focused checks pass.

**Step 4: Validate a real staging artifact**

After deploying migration and R2 configuration to staging:

1. generate one draft report;
2. confirm status becomes `generated` only after R2 upload;
3. HEAD the private object using operational credentials;
4. download through the API and verify SHA-256 equals `pdf_sha256`;
5. verify exactly three Letter pages and selectable text;
6. regenerate and confirm the R2 key is unchanged while checksum/timestamp are
   updated;
7. force one R2 failure and confirm the draft remains `draft`;
8. run backfill dry-run, then `--apply --limit 1`, and verify idempotent rerun.

**Step 5: Deployment order**

```text
1. Create/configure private R2 bucket or logical alias and CORS.
2. Deploy database migration.
3. Deploy backend with artifact generation and lazy repair.
4. Deploy admin regeneration adapter.
5. Run dry-run backfill.
6. Run bounded apply batches while monitoring failures and R2 usage.
```

Do not run the unbounded backfill as part of application startup or a database
migration.

---

## Final acceptance checklist

- [ ] Automatic generation writes one private R2 PDF before status transition.
- [ ] Regeneration overwrites the identical canonical key.
- [ ] Draft status survives render/upload failure.
- [ ] Stored metadata is complete and checksum-valid.
- [ ] Download reads the stored artifact and keeps authorization unchanged.
- [ ] Missing historical artifacts repair lazily.
- [ ] Backfill is dry-run-first, bounded, resumable and idempotent.
- [ ] PDF is exactly three Letter portrait pages with selectable text.
- [ ] Missing historical fields remain blank.
- [ ] Official logos are vector assets, not invented substitutes.
- [ ] Backend, admin, database and canonical documentation agree.

