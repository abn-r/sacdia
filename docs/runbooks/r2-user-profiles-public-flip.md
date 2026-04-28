# Runbook: USER_PROFILES bucket public flip

## Context

M-04 (shipped 2026-04-17) changed the `user-profiles` R2 bucket from private
(signed URLs) to public CDN delivery. The service now sets `isPublic: true` for
this bucket and calls `getRequiredEnv('R2_PUBLIC_URL_USER_PROFILES')` to build
CDN URLs instead of generating signed URLs. The relevant commit is `78f9e41`.

In the dev environment the bucket was flipped to public and
`R2_PUBLIC_URL_USER_PROFILES` now points to
`https://pub-c0e79f5fa4634581867fab5b0fed605c.r2.dev`.

Staging and production use **separate R2 resources**. Before deploying commit
`78f9e41` to those environments, the steps below MUST be completed or profile
images will return 401/403.

---

## Prerequisites per environment

Complete all three steps for the target environment before the deploy.

### 1. Cloudflare R2 dashboard — enable public access

1. Log in to the Cloudflare dashboard and open the R2 section.
2. Open the bucket for the target environment (confirm actual names with ops —
   expected: `user-profiles-staging`, `user-profiles-prod`).
3. Go to **Settings → Public Development URL → Enable**.
4. Copy the generated `pub-<hash>.r2.dev` value — you need it in step 2.
5. *(Optional)* Connect a custom domain (e.g. `cdn.sacdia.com`) under
   **Settings → Custom Domains** for better caching and latency. If you do
   this, use the custom domain as the value in step 2 instead of `pub-*.r2.dev`.

### 2. Env secrets — update `R2_PUBLIC_URL_USER_PROFILES`

The backend is deployed on Render.com. Update the environment variable in the
Render dashboard (service → Environment) for the target service.

```
# OLD value (S3 API endpoint — will NOT work for public objects):
R2_PUBLIC_URL_USER_PROFILES=https://<account-id>.r2.cloudflarestorage.com/user-profiles

# NEW value — pick one:
R2_PUBLIC_URL_USER_PROFILES=https://pub-<hash>.r2.dev          # r2.dev managed
R2_PUBLIC_URL_USER_PROFILES=https://cdn.sacdia.com             # custom domain
```

The `getRequiredEnv` call in the service throws at startup if this variable is
missing, so the service will not start at all with an unset value.

### 3. Smoke test — verify public access before deploy

Before triggering the deploy, confirm the bucket is actually serving objects:

```bash
# Replace with a real object key that exists in the bucket
curl -I "https://pub-<hash>.r2.dev/user-profiles/<any-known-key>.jpeg"
# Expected: HTTP/2 200
# Expected headers: Content-Type: image/jpeg (or image/*)
# If you get 403 → public access was not enabled correctly in step 1.
# If you get 404 → key path is wrong — try another known object.
```

---

## Deploy steps

1. Confirm all three prerequisites above are done for the target environment.
2. Deploy/merge the commit `78f9e41` (or the branch containing M-04) to the
   target environment.
3. After the service restarts, verify the response of a members endpoint
   that returns profile image URLs — e.g.:

   ```
   GET /api/v1/camporees/:id/members
   ```

   URLs in the response should be clean CDN URLs (`https://pub-*.r2.dev/...`
   or your custom domain). There should be **no** `X-Amz-*` query parameters
   (those indicate a signed URL was generated instead of a CDN URL).

4. Open one of the returned image URLs in a browser and confirm the image
   renders without authentication errors.

---

## Rollback

If a problem is found after deploy:

1. Revert commit `78f9e41` in the deployed branch and redeploy.
2. Images that were fetched as public CDN URLs during the window remain
   accessible — the bucket public-access flag is independent of the code.
3. To fully return to signed-URL mode, toggle **Public Development URL → Disable**
   in the Cloudflare dashboard for the bucket. This does not affect in-flight
   requests but stops new unauthenticated fetches.

---

## Risk

| Risk | Mitigation |
|------|-----------|
| Bucket public access not enabled but `isPublic: true` in code | Service returns CDN URLs that 401/403. Mitigation: complete prerequisite step 1 **before** deploy, and run smoke test in step 3 to confirm. |
| `R2_PUBLIC_URL_USER_PROFILES` not set | `getRequiredEnv` throws at service startup — service will not start. Set the variable before deploying. |
| S3 API endpoint used instead of CDN URL | Images return 401/403 because the S3 API endpoint requires auth. Always use the `pub-*.r2.dev` or custom domain URL. |

---

## Security tradeoff

Profile images in the `user-profiles` bucket are **world-readable by URL** after
this change. This was reviewed and accepted by product/legal in the 2026-04-17
decision associated with M-04. No further action required unless the decision
is revisited.

---

## Related

- Backend commit: `78f9e41`
- `.env.example` entry: `R2_PUBLIC_URL_USER_PROFILES` (updated 2026-04-17 with
  warning comment — see `sacdia-backend/.env.example`)
- Joi schema note: `R2_PUBLIC_URL_USER_PROFILES` is currently `.optional()` in
  `src/config/env.validation.ts:42`. Because `getRequiredEnv` enforces the
  variable at runtime when `isPublic: true`, consider making it `.required()`
  in Joi for environments where R2 storage is active. This is a **SUGGESTION
  only** — changing it to required could break CI pipelines or dev setups that
  omit R2 config entirely. Evaluate before changing.
