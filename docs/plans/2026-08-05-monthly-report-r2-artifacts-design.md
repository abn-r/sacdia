# Monthly Report R2 Artifacts — Design

**Date:** 2026-08-05  
**Status:** Approved  
**Scope:** `sacdia-backend`, `sacdia-admin`, canonical documentation and database references

## Context

Monthly report PDFs are currently rebuilt on every
`GET /api/v1/monthly-reports/:reportId/pdf` request by
`MonthlyReportsPdfService` using PDFKit. They are not durable artifacts and the
current backend renderer still uses the previous two-page visual design.

The approved behavior is:

- every automatically generated report produces a private PDF artifact in R2;
- regeneration overwrites the canonical object instead of retaining versions;
- historical reports are rendered with the new three-page Letter portrait
  format;
- fields that were never persisted remain blank;
- a failed PDF render or R2 upload must not transition a draft report to
  `generated`;
- downloads use the stored object, with lazy repair if an older report has no
  artifact yet.

## Chosen architecture

### Canonical artifact

Each report owns one deterministic private R2 object:

```text
monthly-reports/{year}/{month-padded}/{clubEnrollmentId}/{monthlyReportId}.pdf
```

The storage call uses `overwrite: true`. There is no version table and no
historical PDF retention. The database records the current object's integrity
metadata:

- `pdf_r2_key varchar(512) null`
- `pdf_size_bytes bigint null`
- `pdf_sha256 char(64) null`
- `pdf_generated_at timestamptz null`
- `pdf_template_version varchar(32) null`

`pdf_template_version` starts at `monthly-report-v2-three-page`. It enables
future backfills without guessing whether an object uses the current template.

### Private R2 alias

Add `StorageBucketAlias.MONTHLY_REPORTS` backed by:

- `R2_BUCKET_MONTHLY_REPORTS`
- `R2_PUBLIC_URL_MONTHLY_REPORTS`
- `R2_KEY_PREFIX_MONTHLY_REPORTS` with default `monthly-reports`

The bucket remains private. The configured public-base value is required by the
existing storage abstraction but must not represent a public ACL. Consumers
persist only `UploadedFileResult.key` and obtain downloads through a presigned
GET URL.

The logical alias may point to a dedicated physical bucket or an existing
private R2 bucket, but the prefix must remain exclusive to monthly reports.

### Renderer and artifact service

Keep PDFKit because it is already part of the backend runtime, preserves
selectable text and avoids introducing Chromium into production. Refactor the
current PDF service into two responsibilities:

1. `MonthlyReportsPdfService` renders a Buffer using an explicit frozen
   snapshot, manual data and report metadata. Its layout becomes the approved
   three-page design:
   - page 1: Administración and Enseñanzas;
   - page 2: Actividades del club and Finanzas;
   - page 3: Actividad misionera, Servicio and Firmas.
2. `MonthlyReportArtifactsService` computes the deterministic key and checksum,
   uploads with overwrite semantics, persists metadata and resolves signed
   downloads.

The renderer maps only fields available in `snapshot_data`, `manual_data` and
enrollment relations. Unsupported historical fields render as blank values or
blank rows; they are never synthesized.

Official SVG assets must be supplied before production. The renderer must not
invent substitute logos. Vector embedding should use the official files and a
PDFKit-compatible SVG adapter.

### Generation consistency

Generation uses a per-report distributed lock. Inside the lock:

1. re-read the report and verify it is still `draft`;
2. calculate the live preview that will become the frozen snapshot;
3. render the PDF from that candidate snapshot and current manual data;
4. upload the canonical R2 object with overwrite enabled;
5. conditionally transition `draft -> generated` while saving snapshot and PDF
   metadata;
6. if the database transition fails after upload, delete the newly uploaded
   object best-effort and leave the report as `draft`;
7. release the lock.

Therefore PDF rendering or R2 failure leaves the report in `draft`, allowing
BullMQ retry and manual retry without a false generated state.

Regeneration of a `generated` or `submitted` report does not refresh the
snapshot or mutate its workflow status. It renders the existing frozen snapshot,
overwrites the canonical object and updates only PDF metadata. R2 failure leaves
the previous object and metadata untouched whenever the provider preserves the
existing object on a failed PUT.

### Download and recovery

`GET /monthly-reports/:reportId/pdf` keeps its authorization contract.

- If current artifact metadata exists, return a temporary signed download.
- If the report is `generated|submitted` but has no current artifact, generate
  and persist it from the frozen snapshot, then return the download. This is the
  lazy repair path for historical records.
- Reports in `draft` remain non-downloadable.

The admin adapter may continue fetching the endpoint as a Blob if the backend
streams the stored object. If the endpoint redirects to R2 instead, R2 CORS must
be validated and documented. Streaming through the authorized backend is the
safer default because it preserves the existing browser contract.

### Historical backfill

Provide an idempotent one-shot script that selects `generated|submitted`
reports where:

```text
pdf_r2_key IS NULL
OR pdf_template_version <> 'monthly-report-v2-three-page'
```

The script supports `--dry-run`, `--batch-size`, `--limit` and cursor-based
continuation. Each record uses the same artifact service as normal generation,
so reruns overwrite the same key safely. Failures are recorded and do not stop
later records.

### Observability and security

- Never log signed URLs, report contents or R2 credentials.
- Log report ID, storage key, template version, byte count and checksum prefix.
- Emit counters for generated, skipped and failed backfill records.
- Preserve `reports:download` and resource-scope authorization.
- The R2 object is private and is never exposed through a permanent public URL.

## Alternatives rejected

### Derive the R2 key without database metadata

This avoids a migration but cannot prove that the object exists, matches the
current template or has the expected checksum. It also makes backfill selection
and operational diagnosis unreliable.

### Generic versioned report-artifacts table

This is appropriate when multiple artifact versions must be retained. The user
explicitly chose replacement semantics, so a separate version table would add
unnecessary lifecycle and cleanup complexity.

### Browser/Chromium rendering in the backend

It could reuse HTML/CSS more literally, but adds a large runtime dependency,
container changes and materially higher memory/startup cost. PDFKit is already
operational and meets the selectable-text requirement.

## Acceptance criteria

1. Automatic generation cannot finish as `generated` without a successfully
   uploaded current PDF artifact.
2. Regeneration overwrites the same deterministic R2 key.
3. Every stored artifact has key, size, SHA-256, generation timestamp and
   template version in `monthly_reports`.
4. Download authorization is unchanged and no permanent public URL is returned.
5. Historical generated/submitted reports can be repaired lazily or by the
   idempotent backfill.
6. The stored PDF has exactly three Letter portrait pages and selectable text.
7. Missing historical fields remain blank.
8. Tests cover R2 failure, database-transition failure, overwrite semantics,
   lazy repair, backfill selection and exact page count.

