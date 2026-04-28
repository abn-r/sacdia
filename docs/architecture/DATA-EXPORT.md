# GDPR Data Export Architecture

**Feature**: "Descargar mis datos" — GDPR Article 20 (right to data portability)
**Status**: Implemented — 2026-04-17
**Branch**: development

## Overview

Users can request a full JSON export of their personal data stored in SACDIA. The export is generated asynchronously via a BullMQ job, stored in a dedicated private R2 bucket, and served via presigned URLs (TTL 15 min).

## Flow

```
Mobile App
  └── POST /users/me/data-export
        └── DataExportService.requestExport()
              ├── Check: ready export in last 24h? → 429
              ├── Check: pending/processing? → 200 (return existing)
              └── Create row (status=pending) + enqueue job → 201

BullMQ worker (data-exports queue)
  └── DataExportProcessor.process()
        ├── Fetch row — abort if not pending (idempotent)
        ├── status = 'processing', started_at = now()
        ├── Collect user data from Prisma (10 parallel queries)
        ├── Build JSON payload (schema_version: 1.0.0)
        ├── SHA-256 checksum
        ├── Upload to R2 → data-exports/{userId}/{exportId}.json
        ├── status = 'ready', expires_at = now() + 48h
        └── EmailService.sendDataExportReady() — logger-only if EMAIL_ENABLED=false

Mobile App
  └── GET /users/me/data-exports           — poll status
  └── GET /users/me/data-exports/:id/download — presigned URL (15 min TTL)
```

## Database Table

`data_export_requests`:

| Column | Type | Notes |
|--------|------|-------|
| export_id | UUID PK | returned to mobile |
| user_id | UUID FK → users | CASCADE on delete |
| status | VARCHAR(16) | pending/processing/ready/failed/expired |
| format | VARCHAR(16) | always "json" for now |
| r2_key | VARCHAR(512) | set when ready |
| file_size_bytes | BIGINT | nullable |
| sha256_checksum | VARCHAR(64) | hex digest |
| failure_reason | TEXT | set when failed |
| created_at | TIMESTAMPTZ | |
| started_at | TIMESTAMPTZ | set when processing begins |
| completed_at | TIMESTAMPTZ | set when ready/failed |
| expires_at | TIMESTAMPTZ | ready + 48h |
| downloaded_count | INT | incremented on each download |
| last_downloaded_at | TIMESTAMPTZ | updated on each download |

Indexes:
- `idx_data_export_requests_user_created` ON `(user_id, created_at DESC)`
- `idx_data_export_requests_cleanup` ON `(status, expires_at) WHERE status IN ('ready','failed')`

## R2 Storage

- **Bucket alias**: `StorageBucketAlias.DATA_EXPORTS`
- **Env vars**:
  - `R2_BUCKET_DATA_EXPORTS` — the Cloudflare R2 bucket name
  - `R2_PUBLIC_URL_DATA_EXPORTS` — required (can be the R2 endpoint URL, never exposed)
  - `R2_KEY_PREFIX_DATA_EXPORTS` — optional, defaults to `data-exports`
- **Key format**: `data-exports/{userId}/{exportId}.json`
- **Access**: private only — objects are served via presigned GET URLs (15 min TTL)
- **Lifecycle**: cleanup cron deletes R2 object when export expires (after 48h)

### Creating the bucket in Cloudflare

1. Go to Cloudflare Dashboard > R2 > Create Bucket
2. Name: e.g. `sacdia-data-exports-{env}` (separate buckets for dev/staging/prod)
3. Location: Auto (or match your other buckets)
4. Access: **Private** (no public access)
5. After creation, copy the bucket name → set `R2_BUCKET_DATA_EXPORTS`
6. For `R2_PUBLIC_URL_DATA_EXPORTS`, use the R2 API endpoint format:
   `https://{account_id}.r2.cloudflarestorage.com/{bucket_name}`
7. No CORS configuration needed (presigned URLs bypass CORS)

### Setting env vars in Render

1. Render Dashboard > sacdia-backend service > Environment
2. Add: `R2_BUCKET_DATA_EXPORTS`, `R2_PUBLIC_URL_DATA_EXPORTS`
3. Optional: `R2_KEY_PREFIX_DATA_EXPORTS` (leave unset to use default `data-exports`)

## BullMQ Queue

- **Queue name**: `data-exports` (separate from `notifications`)
- **Job name**: `data-export.generate`
- **Attempts**: 1 — fail closed, no retry
- **On failure**: status set to `failed`, failure_reason stored, job is not re-queued
- **Backpressure**: fully isolated from FCM push queue

## Email Service

`EmailService.sendDataExportReady()` is a stub:
- If `EMAIL_ENABLED=false` (default): logs a `WARN` with all relevant fields
- If `EMAIL_ENABLED=true` but no transport configured: logs a `WARN`
- To add a real transport: inject SendGrid/Resend/SES client in `EmailService` and replace the TODO block

## Cleanup Cron

Runs daily at `0 4 * * *` UTC:
1. Finds `ready` exports with `expires_at < NOW()` → deletes R2 object, marks `expired`
2. Hard-deletes `expired` rows with `completed_at < NOW() - 6 months`

## JSON Export Schema (v1.0.0)

```json
{
  "export_metadata": {
    "export_id": "uuid",
    "generated_at": "ISO8601",
    "format": "json",
    "schema_version": "1.0.0",
    "app_version": "string",
    "notice": "Evidence files are not included..."
  },
  "user": { "user_id", "name", "email", "gender", ... },
  "honors": [ { "user_honor_id", "honor_id", "validation_status", ... } ],
  "classes_progress": [ { "section_progress_id", "class_id", "status", ... } ],
  "roles": [ { "assignment_id", "role_id", "club_section_id", ... } ],
  "devices": [ { "fcm_token_id", "token": "**********<rest>", "device_type", ... } ],
  "notifications_history": [ { "delivery_id", "log_id", "read_at", ... } ],
  "sessions": [ { "id", "expires_at", "ip_address", "user_agent", ... } ],
  "notification_preferences": [ { "category", "enabled", ... } ],
  "evidence_files_metadata": [ { "evidence_file_id", "file_url", "file_type", ... } ]
}
```

Sensitive fields excluded:
- `users.account[*].password` (credential hash)
- `session.token` (BA session token)
- FCM token first 10 chars masked

## Security

- Presigned URL TTL: 15 min (900 seconds)
- Signed URL never logged in full (only last 40 chars of path logged)
- Export content never logged
- Cross-user access: 404 (not 403, avoids enumeration)
- Worker re-validates `user_id` ownership before processing
- Rate limit: 1 completed export per 24h per user

## Known Gaps / Pendientes

1. **Email transport**: `EmailService` is stub-only. Wire SendGrid/Resend when available.
2. **Evidence files download**: only metadata is exported. Actual files (images, PDFs) require a separate flow. The export JSON includes a `notice` explaining this.
3. **Account deletion cross-check**: export rows are cascade-deleted with the user. Consider whether audit retention is needed (current policy: cascade is acceptable pre-deletion).
4. **Format expansion**: `format` field is in DB/DTO but only `"json"` is supported. CSV/XLSX can be added later by extending `DataExportProcessor.process()`.

## Module Location

```
src/data-export/
  ├── data-export.module.ts
  ├── data-export.controller.ts
  ├── data-export.service.ts
  ├── data-export.processor.ts
  ├── email.service.ts
  ├── dto/
  │   ├── create-data-export.dto.ts
  │   └── data-export-response.dto.ts
  ├── data-export.service.spec.ts
  ├── data-export.controller.spec.ts
  └── data-export.processor.spec.ts
```
