# R2 Public CDN Cache Implementation Plan

> **Estado real (revisado 2026-10-04 contra `development`)**: No ejecutado. `R2FileStorageService` no escribe `CacheControl` y los buckets públicos siguen sin dominio propio con caché. Ver `docs/storage/r2-keyprefix-conventions.md`.


> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Serve public R2 assets (profile photos, honor images/PDFs, class docs, achievement badges) through Cloudflare custom domains with `Cache-Control`, without caching authenticated API JSON or private signed objects.

**Architecture:** Keep Redis for data queries. Put Cloudflare CDN only in front of buckets already marked `isPublic: true`. Server `PutObject` writes cache headers. Custom R2 domains plus Cache Rules cover objects already uploaded without metadata. Public reads that still return raw `r2.dev` URLs (honor catalog) go through `getSignedDownloadUrl` / `resolvePublicUrl` so a host cutover rewrites live responses. Private aliases stay signed, no public cache headers.

**Tech Stack:** Cloudflare R2 custom domains + Cache Rules, NestJS `R2FileStorageService` (`@aws-sdk/client-s3`), Jest, Next.js CSP / `images.remotePatterns`, Flutter network image cache (no API change).

---

## Preconditions and execution boundaries

- Work on the current branch. Do not create git branches or worktrees unless the user asks.
- Do not put Cache Rules on `api.sacdia.app`. `TRUST_PROXY_HOPS` already assumes Cloudflare in front of Render; that is DNS/proxy, not object CDN.
- Do not flip private aliases to public: `USERS_HONORS`, `USERS_HONORS_CERT`, `ACTIVITIES_IMAGES`, `EVIDENCE_FILES`, `CLASS_EVIDENCE`, `INSURANCE_EVIDENCE`, `RESOURCES_FILES`, `DATA_EXPORTS`, `MONTHLY_REPORTS`, `MATERIALES_COMPROBANTES`, `CAMPOREE_PAYMENT_VOUCHERS`, `CERTIFICATION_EVIDENCE`.
- Do not rewrite GDPR/export/report URLs. Do not add Redis work in this change.
- Do not run a production build. Use focused Jest / admin typecheck if needed.
- `getSignedUploadUrl` is only used by private buckets (resources, certifications). Do not add `CacheControl` to presigned PUT.
- `r2.dev` stays valid during dual-run. Clients may still load old hosts until responses rewrite.
- Canonical public aliases (`isPublic: true` in `sacdia-backend/src/common/services/r2-file-storage.service.ts`):
  - `USER_PROFILES` (mutable — overwrite / replace photo)
  - `HONORS_IMAGES` (immutable catalog)
  - `HONORS_PDF` (immutable catalog)
  - `CLASSES_DOCUMENTS` (immutable catalog)
  - `ACHIEVEMENTS_BADGES` (immutable catalog; already uses `resolvePublicUrl`)

### Recommended hostnames (zone `sacdia.app`)

One R2 custom domain per public bucket (Cloudflare 1:1):

| Alias | Hostname |
|---|---|
| `USER_PROFILES` | `https://profiles.cdn.sacdia.app` |
| `HONORS_IMAGES` | `https://honors.cdn.sacdia.app` |
| `HONORS_PDF` | `https://materials.cdn.sacdia.app` |
| `CLASSES_DOCUMENTS` | `https://classes.cdn.sacdia.app` |
| `ACHIEVEMENTS_BADGES` | `https://badges.cdn.sacdia.app` |

Use **bare domain** (no path tail). `R2_KEY_PREFIX_*` still builds the object path. That matches the target state in `docs/storage/r2-keyprefix-conventions.md`.

If ops prefers fewer names, attach domains first and keep env as `pub-*.r2.dev` until DNS is green. Code tasks do not depend on the final hostname string.

### Cache header contract

```ts
export const R2_PUBLIC_IMMUTABLE_CACHE_CONTROL =
  'public, max-age=31536000, immutable';

export const R2_PUBLIC_MUTABLE_CACHE_CONTROL =
  'public, max-age=3600, stale-while-revalidate=86400';
```

- Immutable: honors images/PDFs, class docs, badges.
- Mutable: profile photos (`overwrite: true` exists; same key can change).
- Private `PutObject`: omit `CacheControl` (default private/no CDN).

### Read-path fact

`UsersService.findOne` already runs `user_image` through `getSignedDownloadUrl(USER_PROFILES, …)`. For public buckets that method returns `buildPublicUrl` from current env, so profile responses follow `R2_PUBLIC_URL_USER_PROFILES`.

Honors catalog (`honors.service.ts` grouped list) still returns raw `honor_image` / `material_url` from Postgres. Those stay on `r2.dev` until rewritten.

---

### Task 1: Cache-Control on public PutObject

**Files:**
- Create: `sacdia-backend/src/common/services/r2-cache-control.ts`
- Modify: `sacdia-backend/src/common/services/r2-file-storage.service.ts`
- Modify: `sacdia-backend/src/common/services/r2-file-storage.service.spec.ts`

**Step 1: Write the failing tests**

Add a describe block after the monthly-report upload tests in `r2-file-storage.service.spec.ts`:

```ts
describe('upload — Cache-Control for public vs private buckets', () => {
  it('sets immutable CacheControl on HONORS_PDF', async () => {
    mockS3Send
      .mockRejectedValueOnce({
        name: 'NotFound',
        $metadata: { httpStatusCode: 404 },
      })
      .mockResolvedValueOnce({});

    await service.upload(
      StorageBucketAlias.HONORS_PDF,
      'manual.pdf',
      Buffer.from('%PDF'),
      { contentType: 'application/pdf' },
    );

    const command = mockS3Send.mock.calls.find(
      (call) => call[0] instanceof PutObjectCommand,
    )?.[0] as PutObjectCommand;

    expect(command.input.CacheControl).toBe(
      'public, max-age=31536000, immutable',
    );
  });

  it('sets mutable CacheControl on USER_PROFILES', async () => {
    mockS3Send.mockResolvedValueOnce({});

    await service.upload(
      StorageBucketAlias.USER_PROFILES,
      'photo-overwrite.jpeg',
      Buffer.from('x'),
      { contentType: 'image/jpeg', overwrite: true },
    );

    const command = mockS3Send.mock.calls[0][0] as PutObjectCommand;
    expect(command.input.CacheControl).toBe(
      'public, max-age=3600, stale-while-revalidate=86400',
    );
  });

  it('does not set CacheControl on private MONTHLY_REPORTS', async () => {
    mockS3Send.mockResolvedValueOnce({});

    await service.upload(
      StorageBucketAlias.MONTHLY_REPORTS,
      '2026/08/enrollment/report.pdf',
      Buffer.from('%PDF'),
      { contentType: 'application/pdf', overwrite: true },
    );

    const command = mockS3Send.mock.calls[0][0] as PutObjectCommand;
    expect(command.input.CacheControl).toBeUndefined();
  });
});
```

**Step 2: Run the RED test**

```bash
cd sacdia-backend
pnpm test -- src/common/services/r2-file-storage.service.spec.ts --runInBand
```

Expected: FAIL because `PutObjectCommand` has no `CacheControl`.

**Step 3: Minimal implementation**

Create `r2-cache-control.ts`:

```ts
export const R2_PUBLIC_IMMUTABLE_CACHE_CONTROL =
  'public, max-age=31536000, immutable';

export const R2_PUBLIC_MUTABLE_CACHE_CONTROL =
  'public, max-age=3600, stale-while-revalidate=86400';
```

In `r2-file-storage.service.ts` `upload()`, after resolving `config`:

```ts
const cacheControl = this.resolveUploadCacheControl(config, bucketAlias);

await this.getClient().send(
  new PutObjectCommand({
    Bucket: config.bucket,
    Key: objectKey,
    Body: buffer,
    ContentType: options.contentType,
    ...(cacheControl ? { CacheControl: cacheControl } : {}),
  }),
);
```

Add:

```ts
private resolveUploadCacheControl(
  config: R2BucketConfig,
  bucketAlias: StorageBucketAlias,
): string | undefined {
  if (!config.isPublic) return undefined;
  if (bucketAlias === StorageBucketAlias.USER_PROFILES) {
    return R2_PUBLIC_MUTABLE_CACHE_CONTROL;
  }
  return R2_PUBLIC_IMMUTABLE_CACHE_CONTROL;
}
```

Do not touch `getSignedUploadUrl`.

**Step 4: Run GREEN tests**

```bash
cd sacdia-backend
pnpm test -- src/common/services/r2-file-storage.service.spec.ts --runInBand
```

Expected: PASS. Existing URL prefix tests still pass.

**Step 5: Commit** (only if the user asked to commit)

```bash
git -C sacdia-backend add src/common/services/r2-cache-control.ts \
  src/common/services/r2-file-storage.service.ts \
  src/common/services/r2-file-storage.service.spec.ts
git -C sacdia-backend commit -m "$(cat <<'EOF'
feat(storage): set Cache-Control on public R2 uploads

Public catalog objects become CDN-cacheable; profile photos use a short TTL because keys can be overwritten. Private buckets stay unsigned.
EOF
)"
```

---

### Task 2: Custom-domain host still resolves stored r2.dev keys

**Files:**
- Modify: `sacdia-backend/src/common/services/r2-file-storage.service.spec.ts`

**Why:** After env cutover, DB still holds `https://pub-*.r2.dev/...`. `getSignedDownloadUrl` on a public bucket must emit the new `R2_PUBLIC_URL_*` host. `isKnownR2UrlHost` already allows `*.r2.dev`. Lock that with a test so a future cleanup does not break dual-run.

**Step 1: Write the failing test** (fails only if current behavior regresses; if it already passes, keep it)

```ts
describe('getSignedDownloadUrl — public bucket rewrites legacy r2.dev host', () => {
  it('USER_PROFILES maps pub-xxx.r2.dev key to configured publicBaseUrl', async () => {
    const svc = await buildService({
      R2_PUBLIC_URL_USER_PROFILES: 'https://profiles.cdn.sacdia.app',
    });

    const url = await svc.getSignedDownloadUrl(
      StorageBucketAlias.USER_PROFILES,
      'https://pub-xxx.r2.dev/user-profiles/photo-abc.jpeg',
    );

    expect(url).toBe(
      'https://profiles.cdn.sacdia.app/user-profiles/photo-abc.jpeg',
    );
    expect(url).not.toContain('X-Amz-');
  });

  it('HONORS_PDF maps embedded r2.dev URL to bare custom domain + prefix', async () => {
    const svc = await buildService({
      R2_PUBLIC_URL_HONORS_PDF: 'https://materials.cdn.sacdia.app',
      R2_KEY_PREFIX_HONORS_PDF: 'honors_pdf',
    });

    const url = await svc.getSignedDownloadUrl(
      StorageBucketAlias.HONORS_PDF,
      'https://pub-zzz.r2.dev/honors_pdf/nudos.pdf',
    );

    expect(url).toBe('https://materials.cdn.sacdia.app/honors_pdf/nudos.pdf');
  });
});
```

**Step 2: Run tests**

```bash
cd sacdia-backend
pnpm test -- src/common/services/r2-file-storage.service.spec.ts --runInBand
```

Expected: PASS if `isKnownR2UrlHost` + `isPublic` rewrite already work. If FAIL, fix `resolveObjectKey` / `buildPublicUrl` only — do not add a second URL parser.

**Step 3: Commit** (only if the user asked, and only if this task added a test or a fix)

```bash
git -C sacdia-backend commit -m "$(cat <<'EOF'
test(storage): rewrite public R2 URLs from legacy r2.dev hosts

Keeps dual-run safe when R2_PUBLIC_URL_* moves to cdn.sacdia.app.
EOF
)"
```

---

### Task 3: Rewrite honor catalog public URLs on read

**Files:**
- Modify: `sacdia-backend/src/honors/honors.service.ts`
- Modify: `sacdia-backend/src/honors/honors.service.spec.ts`
- Modify only if the class-honors payload is built elsewhere: `sacdia-backend/src/classes/` (search `material_url`)

**Step 1: RED — catalog list uses storage rewrite**

In `honors.service.spec.ts`, mock `getSignedDownloadUrl` if not already, then assert grouped catalog mapping:

- `honor_image` → `getSignedDownloadUrl(HONORS_IMAGES, stored)`
- `material_url` → `getSignedDownloadUrl(HONORS_PDF, stored)`
- null/empty stays null (no storage call)

Reuse the existing fileStorage mock pattern in that spec.

**Step 2: Run RED**

```bash
cd sacdia-backend
pnpm test -- src/honors/honors.service.spec.ts --runInBand
```

Expected: FAIL because `findAll` (grouped catalog) still assigns raw Prisma strings.

**Step 3: Helper + apply to catalog mapping**

Add a private helper next to `resolvePrivateAssetUrl`:

```ts
private async resolvePublicAssetUrl(
  bucketAlias: StorageBucketAlias,
  value: string | null | undefined,
): Promise<string | null> {
  if (!value) return null;
  try {
    return await this.fileStorage.getSignedDownloadUrl(bucketAlias, value);
  } catch (error) {
    this.logger.warn(
      `Failed to resolve public URL for ${bucketAlias}. Returning original value.`,
      error,
    );
    return value;
  }
}
```

In the grouped catalog push (`honor_image` / `material_url` around line 262), await this helper. Apply the same helper in `findOne` if it returns those fields raw.

Then grep `material_url` under `sacdia-backend/src/classes` and camporee event honors. If those payloads copy Prisma `material_url` without storage, apply the same helper. Do not invent new endpoints.

**Step 4: GREEN**

```bash
cd sacdia-backend
pnpm test -- src/honors/honors.service.spec.ts --runInBand
```

If classes/camporee files changed, run their focused specs too.

**Step 5: Commit** (only if asked)

```bash
git -C sacdia-backend commit -m "$(cat <<'EOF'
fix(honors): resolve catalog image and PDF URLs through R2 public base

Existing r2.dev rows follow R2_PUBLIC_URL_* after a CDN host cutover.
EOF
)"
```

---

### Task 4: Admin CSP and next/image allow the CDN zone

**Files:**
- Modify: `sacdia-admin/next.config.ts`
- Modify: `sacdia-admin/src/app/api/annual-folders/evidence/pdf/route.ts` only if that allowlist is used for public PDFs; do not widen it to private evidence hosts

**Step 1: Dual-run hosts**

Keep current `pub-*.r2.dev` and `*.r2.cloudflarestorage.com` entries. Add:

- CSP `img-src`, `connect-src`, `frame-src`, `object-src`: `https://*.cdn.sacdia.app`
- `images.remotePatterns`: `{ protocol: "https", hostname: "*.cdn.sacdia.app", pathname: "/**" }`

Comment: dual-run until INFRA-01 + env cutover; do not remove `r2.dev` in this change.

**Step 2: Verify config parses**

```bash
cd sacdia-admin
pnpm exec tsc --noEmit --pretty false 2>&1 | head -40
```

Do not run `pnpm build`.

**Step 3: Commit** (only if asked)

```bash
git -C sacdia-admin commit -m "$(cat <<'EOF'
chore(admin): allow sacdia.app CDN hosts for R2 public assets

CSP and next/image keep r2.dev during dual-run and add *.cdn.sacdia.app.
EOF
)"
```

---

### Task 5: Canonical docs and runbook

**Files:**
- Modify: `docs/runbooks/r2-user-profiles-public-flip.md` (extend into a public-CDN runbook, keep the M-04 history)
- Modify: `docs/storage/r2-keyprefix-conventions.md`
- Modify: `sacdia-backend/docs/storage/r2-keyprefix-conventions.md` (keep in sync)
- Modify: `docs/api/EXTERNAL-SERVICES-INTEGRATION.md` (user-profiles is public CDN, not private)
- Modify: `docs/history/audit/REALITY-MATRIX.md` (`INFRA-01` stays OPEN until staging/prod DNS + env are done; note this plan)
- Modify: `sacdia-backend/.env.example` comments under `R2_PUBLIC_URL_*` (example custom domains, bare host, never S3 API endpoint for public buckets)

**Runbook checklist to add (manual, per env: development / staging / production):**

1. R2 bucket → Settings → Public access enabled (not only `r2.dev` if custom domain is used).
2. Custom Domains → attach hostname from the table above. Wait until SSL is active.
3. Cache Rules on zone `sacdia.app` (hostname is `*.cdn.sacdia.app`):
   - Eligible for cache
   - Edge TTL: honors/materials/classes/badges 1 month (or respect origin)
   - profiles: 1 hour
   - Bypass cache on `Set-Cookie` / authenticated requests (should never hit these hosts with `Authorization`)
4. CORS on public buckets: GET/HEAD from admin origin and app. Do not add `*` PUT.
5. Render env: set `R2_PUBLIC_URL_*` to `https://<host>` with **no path, no trailing slash**. Never `https://<account>.r2.cloudflarestorage.com/...` for public aliases.
6. Smoke:

```bash
curl -sI "https://profiles.cdn.sacdia.app/user-profiles/<known-key>.jpeg" | head
# Expect: 200, cf-cache-status: HIT or MISS then HIT on second request
# Expect: cache-control from origin or from the Cache Rule
# Expect: no X-Amz-* query string

curl -sI "https://materials.cdn.sacdia.app/honors_pdf/<known>.pdf" | head
```

7. API smoke: `GET` a member with `user_image` and honors catalog — hosts must be `*.cdn.sacdia.app`, not `r2.cloudflarestorage.com`.

**Out of scope in the runbook:** Cache Rules for `/api/v1/*`, Workers, Cloudflare Images, Redis.

**Step 1: Edit docs** as above. Do not mark `INFRA-01` resolved until ops completes step 5–7 on staging and production.

**Step 2: Commit docs** (only if asked; docs live in the workspace repo)

```bash
git add docs/plans/2026-09-07-r2-public-cdn-cache.md \
  docs/runbooks/r2-user-profiles-public-flip.md \
  docs/storage/r2-keyprefix-conventions.md \
  docs/api/EXTERNAL-SERVICES-INTEGRATION.md \
  docs/history/audit/REALITY-MATRIX.md
git commit -m "$(cat <<'EOF'
docs(storage): plan public R2 CDN domains and cache headers

Separates object CDN from API/Redis cache and records the staging/prod cutover.
EOF
)"
```

---

### Task 6: App default badge host (after env exists)

**Files:**
- Modify: `sacdia-app/lib/features/achievements/domain/entities/achievement.dart` only if it still hardcodes `pub-c8aa231ae66c46ff96fc5e811994d9d2.r2.dev` / `sacdia-files.r2.dev`
- Modify matching tests under `sacdia-app/test/`

**Do this last.** Runtime badge URLs already go through `resolvePublicUrl`. Hardcoded fallbacks keep working on `r2.dev`. Change them only after `R2_PUBLIC_URL_ACHIEVEMENTS_BADGES` points at `https://badges.cdn.sacdia.app`.

No Flutter cache-manager rewrite. `CachedNetworkImage` already caches by URL; a host change is a new cache key (acceptable).

**Commit** (only if asked):

```bash
git -C sacdia-app commit -m "$(cat <<'EOF'
chore(app): point default achievement badge at the public CDN host

Fallback image follows R2_PUBLIC_URL_ACHIEVEMENTS_BADGES after cutover.
EOF
)"
```

---

## Acceptance

- New public uploads send `Cache-Control` as specified; private uploads do not.
- Changing `R2_PUBLIC_URL_USER_PROFILES` / honors PDF/image env rewrites live API URLs for profiles and honor catalog without a SQL migration.
- Admin can render images/PDFs from `*.cdn.sacdia.app` without CSP violations.
- `curl -I` on a custom-domain object shows Cloudflare cache headers (`cf-cache-status`) after the second request.
- Authenticated API responses are unchanged in shape; no edge cache of JSON.
- `INFRA-01` closes only when staging and production buckets + env + smoke are done.

## Rollback

- Revert `R2_PUBLIC_URL_*` to `pub-*.r2.dev`. `isKnownR2UrlHost` still accepts both.
- Disable Cache Rules. Objects remain readable.
- Code rollback: stop sending `CacheControl` on PutObject; existing object metadata stays until overwritten.

## Explicitly not this plan

- Redis for operations dashboard / catalogs (already a separate layer; catalogs already cache-aside per `.env.example`).
- Cloudflare Cache of `GET /api/v1/catalogs/*` (geography varies by JWT).
- Merging five public buckets into one.
- Backfill CopyObject to stamp `Cache-Control` on every existing object (Cache Rule covers that).
