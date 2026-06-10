# Security Review: SACDIA workspace

## Scope

- In-scope code: `/Users/abner/Documents/development/sacdia`, including `sacdia-backend`, `sacdia-admin`, `sacdia-app`, `sacdia-docs`, root `docs`, root scripts, and GitHub workflows.
- Scan mode: Codex Security repository/scoped-path scan across every project repo.
- Generated context: the threat model below was generated during Phase 1 of this scan and copied to `/tmp/codex-security-scans/sacdia/7a15ebd9a216_20260610T213223Z/artifacts/01_context/threat_model.md`.
- Artifacts reviewed: worker discovery reports under `/tmp/codex-security-scans/sacdia/7a15ebd9a216_20260610T213223Z/artifacts/02_discovery/workers`, local source traces, scoped rank inputs, and the coverage ledger.
- Runtime/test status: no builds were executed, per project instruction. Validation used static source tracing and existing tests/docs as evidence.
- Explicit exclusions and limitations: live deployment env values, real CI token scopes, live databases, and external OAuth/mobile device runtime behavior were not exercised.

### Scan Summary

| Field | Value |
|---|---|
| Reportable findings | 9 |
| Severity mix | high: 7; medium: 2 |
| Confidence mix | high: 7; medium: 2 |
| Coverage | backend, admin, app, docs/root with scoped rank inputs and worker discovery reports |
| Validation mode | static trace / code understanding; no builds executed |
| Scan directory | `/tmp/codex-security-scans/sacdia/7a15ebd9a216_20260610T213223Z` |


## Threat Model

# SACDIA Repository Threat Model

## Scope

Workspace: `/Users/abner/Documents/development/sacdia`.
Runtime repositories in scope:

- `sacdia-backend`: NestJS REST API, Prisma/PostgreSQL, Better Auth/JWT, Redis/BullMQ, FCM, R2, Sentry.
- `sacdia-admin`: Next.js admin panel consuming the backend API with HTTP-only cookie auth patterns.
- `sacdia-app`: Flutter mobile app using Dio/Riverpod, local token/cache storage, FCM, signed URL file flows.
- `sacdia-docs` and root `docs/scripts`: documentation/static site and workspace automation; lower runtime privilege unless deployment or generated content can affect production behavior.

## Assets and privileges that matter

- User identities, JWTs, refresh/session state, MFA assurance state, OAuth flows, and password/reset flows.
- Institutional RBAC: global roles, active club/section assignments, contextual permissions, owner-only user sub-resources.
- Sensitive personal and health data: allergies, diseases, medicines, emergency contacts, legal representative data, minors' data.
- Evidence and storage objects in Cloudflare R2: profile photos, honors/classes/folders evidence, signed upload/download URLs, migrated legacy URLs.
- PostgreSQL integrity: annual enrollments, club sections, roles, progress/validation state, finances, reports, rankings, audit/event journals.
- Notification and realtime invalidation channels: FCM tokens, silent invalidation payloads, queues/processors.
- Admin operational capabilities: catalogs, users, reports, evidence review, investiture, rankings, resources, bulk operations.
- Deployment/runtime secrets: DATABASE_URL, BETTER_AUTH_SECRET, R2 keys, Firebase credentials, Redis URL, Sentry DSN, Google Maps keys.

## Trust boundaries

- Public internet/client boundary into `sacdia-backend` REST API.
- Admin browser boundary into backend API through Next.js routes/server actions and cookies.
- Mobile device boundary, including local token/cache storage and foreground/background FCM handling.
- Backend-to-database boundary through Prisma and occasional raw SQL/scripts/migrations.
- Backend-to-R2 boundary for object keys, public URLs, signed URLs and legacy URL migration.
- Backend-to-FCM boundary for visible notifications and silent cache invalidation.
- Worker/queue boundary between request handlers and BullMQ processors.
- CI/deployment boundary reading repository scripts, generated specs, env examples and workflow files.
- Documentation/static-site boundary where markdown/content might become rendered HTML or operational guidance.

## Attacker-controlled inputs

- HTTP request paths, params, query strings, bodies, multipart/file metadata, headers including Origin/Authorization/Accept-Language.
- JWTs, refresh tokens, OAuth callback parameters and device/session identifiers.
- Admin form data, filters, search strings, bulk-action payloads and server-action inputs.
- Mobile API responses interpreted by UI, deep-link/intent data if present, local cached state and FCM payload data.
- Uploaded evidence/profile files, filenames, MIME types, object keys and URLs.
- Catalog translations and rich/plain text fields later rendered by admin/mobile/docs.
- Environment variables and deployment configuration.
- Markdown/content inputs in docs/static site if rendered without sanitization.

## Security invariants

- Backend is the only authority for authorization and business rules; clients must not broaden scope by sending IDs or filters.
- Authentication must fail closed: invalid/revoked JWTs, MFA-pending JWTs and expired/sessionless states must not reach protected handlers unless an explicit skip is documented.
- Contextual RBAC must bind actor privileges to the target club/section/user/resource; global wildcard behavior must not bypass target-specific constraints where docs say exact active assignment is required.
- Owner/self-service access must be limited to the owner's own sensitive sub-resources and must not leak administrative detail to third parties.
- File flows must constrain key prefixes, MIME/content type, object ownership, signed URL lifetime and public URL migration behavior.
- Database access must use parameterized Prisma/prepared APIs; raw SQL and dynamic filters must not permit injection or broad tenant/section bypass.
- Queues, cache and FCM failures must not corrupt transactional truth or silently grant privileges.
- Logs, errors, health checks and Sentry context must not expose secrets, tokens or sensitive personal/health data.
- Secrets must live in environment/secret stores only; examples may name variables but must not include real values.
- Mobile local storage must not make token theft or stale authorization worse than the backend's server-side checks allow.

## High-impact failure modes to prioritize

1. Broken object-level authorization across users, club sections, annual folders, evidence, finances, reports, notifications or admin detail endpoints.
2. JWT/session/MFA/refresh mistakes that allow privilege use with stale, revoked or MFA-pending tokens.
3. IDOR through admin/mobile clients passing `userId`, `clubId`, `sectionId`, `folderId`, `activityId`, `honorId` or report filters.
4. Insecure file upload/download/key handling in R2 evidence and profile-photo paths.
5. SQL/query injection or unsafe raw Prisma usage in search, reports, migrations, scripts or dynamic sorting/filtering.
6. Stored/reflected XSS in admin-rendered names/descriptions/translations/resources/docs content.
7. CSRF/cookie-origin/CORS weaknesses in browser-based admin auth flows.
8. FCM token/invalidation misuse that leaks membership/section data or causes unauthorized cache state changes.
9. Sensitive data exposure via logs, errors, health checks, generated API docs or repo-committed config.
10. Dependency/config supply-chain issues in JS/Flutter tooling, CI workflows and generated artifacts.

## Assumptions to verify during discovery

- Effective Prisma schema is `sacdia-backend/prisma/schema.prisma`.
- API route truth is code plus `docs/api/ENDPOINTS-LIVE-REFERENCE.md`; docs can lag and must be checked against implementation.
- The admin does not use Supabase clients and should use backend API/cookies only.
- Mobile is documented as cache + invalidation rather than true offline-first in current canon, even if some local docs still say Hive/offline-first.
- No builds should be executed as part of this scan.


## Findings

| Finding | Severity | Confidence | Category |
|---|---|---|---|
| [Self-service profile updates can retarget the territory used by global RBAC](#1-self-service-profile-updates-can-retarget-the-territory-used-by-global-rbac) | high | high | Authorization bypass / privilege escalation |
| [Admin resource read endpoints ignore resource scope and issue cross-scope signed URLs](#2-admin-resource-read-endpoints-ignore-resource-scope-and-issue-cross-scope-signed-urls) | high | high | Authorization bypass / IDOR |
| [Admin resource update and delete endpoints mutate resources outside the actor scope](#3-admin-resource-update-and-delete-endpoints-mutate-resources-outside-the-actor-scope) | high | high | Authorization bypass / IDOR |
| [Annual folder read routes expose private evidence across clubs](#4-annual-folder-read-routes-expose-private-evidence-across-clubs) | high | high | Authorization bypass / IDOR |
| [Annual folder upload accepts evidence for folders owned by another club](#5-annual-folder-upload-accepts-evidence-for-folders-owned-by-another-club) | high | high | Authorization bypass / cross-tenant write |
| [Annual folder evaluation actions are not bound to the reviewer territory](#6-annual-folder-evaluation-actions-are-not-bound-to-the-reviewer-territory) | high | high | Authorization bypass / cross-territory integrity |
| [Membership request approval checks the wrong resource and updates by assignment ID only](#7-membership-request-approval-checks-the-wrong-resource-and-updates-by-assignment-id-only) | high | high | Authorization bypass / IDOR |
| [Development docs publish shared test credentials and fail open when Basic Auth envs are missing](#8-development-docs-publish-shared-test-credentials-and-fail-open-when-basic-auth-envs-are-missing) | medium | medium | Credential exposure / fail-open access control |
| [Docs sync workflow persists cross-repo tokens while running installs and generators](#9-docs-sync-workflow-persists-cross-repo-tokens-while-running-installs-and-generators) | medium | medium | CI credential exposure / supply-chain hardening |

### Confidence Scale

| Label | Meaning |
|---|---|
| high | direct source, configuration, or runtime evidence supports the finding, with no material unresolved reachability or exploitability blocker. |
| medium | source evidence supports a plausible issue, but runtime behavior, deployment configuration, role reachability, type constraints, or exploit reliability still need proof. |
| low | weak or incomplete evidence; include only when the user explicitly wants follow-up candidates in the final report. |

### [1] Self-service profile updates can retarget the territory used by global RBAC

| Field | Value |
|---|---|
| Severity | high |
| Confidence | high |
| Confidence rationale | Static trace shows the owner bypass, the whitelisted geography fields, the direct update sink, and RBAC later deriving global scope from those same fields. |
| Category | Authorization bypass / privilege escalation |
| CWE | CWE-269 Improper Privilege Management; CWE-863 Incorrect Authorization |
| Affected lines | /Users/abner/Documents/development/sacdia/sacdia-backend/src/users/users.controller.ts:124-134; /Users/abner/Documents/development/sacdia/sacdia-backend/src/users/dto/update-user.dto.ts:88-116; /Users/abner/Documents/development/sacdia/sacdia-backend/src/users/users.service.ts:237-250; /Users/abner/Documents/development/sacdia/sacdia-backend/src/common/services/authorization-context.service.ts:387-391,537-615,636-671 |

#### Summary
A user updating their own profile passes `@AuthorizationResource({ type: user, ownerParam: userId })`, and `UpdateUserDto` explicitly accepts `country_id`, `union_id`, and `local_field_id`. `UsersService.update()` only validates that the geography is real and coherent, then persists the whole DTO. For users with scoped global roles, `AuthorizationContextService` later uses those same geography columns as the effective global RBAC scope.

#### Validation
Used repository static trace. Checklist: [x] attacker input is owner profile PATCH body; [x] broken control is owner bypass plus profile DTO including RBAC scope fields; [x] sink persists the fields; [x] downstream RBAC consumes those fields; [x] no service-level admin-only guard was found. Runtime proof was not attempted because the scan was read-only and no environment was provided.

#### Dataflow
`PATCH /api/v1/users/:userId` body with `local_field_id` or `union_id` -> `UsersController.update()` -> `UsersService.validateGeographyReferences()` validates existence/coherence only -> `prisma.users.update({ data: updateUserDto })` -> later `resolveUserAuthorization()` -> `buildUserScope()` -> `canAccessHierarchyScope()` grants LF/union/division access based on the modified user row.

#### Reachability
Any authenticated user can update their own user row when they have `users:update_profile`. The serious path is a scoped global actor such as `assistant-lf`, `director-lf`, `assistant-union`, or `director-union`: after changing their own territory fields and refreshing auth context, they can act in the new territory.

#### Severity
High: this is a direct privilege-boundary break for scoped administrative roles. It is not unauthenticated, so it does not reach critical, but it can move a real admin capability across territories. Evidence that global role assignment is immutable elsewhere would lower severity; runtime proof with two local fields would raise confidence further.

#### Remediation
Split personal profile DTO from administrative geography changes. For self-service updates, reject `country_id`, `union_id`, and `local_field_id` or make them read-only after onboarding. Move territory reassignment to an admin-only endpoint with explicit target-scope checks and add tests proving scoped global actors cannot retarget themselves.

### [2] Admin resource read endpoints ignore resource scope and issue cross-scope signed URLs

| Field | Value |
|---|---|
| Severity | high |
| Confidence | high |
| Confidence rationale | The admin controller requires only global `resources:read`; service read and signed-url paths query by ID/filter without `buildVisibleResourceConditions`, while app-safe alternatives show the missing control. |
| Category | Authorization bypass / IDOR |
| CWE | CWE-639 Authorization Bypass Through User-Controlled Key; CWE-862 Missing Authorization |
| Affected lines | /Users/abner/Documents/development/sacdia/sacdia-backend/src/resources/resources.controller.ts:176-227; /Users/abner/Documents/development/sacdia/sacdia-backend/src/resources/resources.service.ts:379-449,665-685; /Users/abner/Documents/development/sacdia/sacdia-backend/src/resources/resources-app.controller.ts:43-119; /Users/abner/Documents/development/sacdia/sacdia-backend/src/resources/resources.service.ts:456-545 |

#### Summary
The admin resource routes are protected by `@AuthorizationResource({ type: global })`, which verifies permission presence but not whether the target resource belongs to the actor territory. `findAll()`, `findOne()`, and `getSignedUrl()` then return arbitrary active resources or sign private R2 object keys by `resource_id`.

#### Validation
Used static source/control/sink comparison. Checklist: [x] attacker controls query or `resource_id`; [x] admin path lacks contextual scope; [x] sink returns metadata or signed download URL; [x] sibling `/resources/me*` path demonstrates the intended scope filter; [x] no later service check closes the gap.

#### Dataflow
Bearer token with `resources:read` -> `GET /resources`, `GET /resources/:id`, or `GET /resources/:id/signed-url` -> `PermissionsGuard` validates global permission only -> `ResourcesService.findAll/findOne/getSignedUrl()` -> unscoped Prisma query -> optional R2 signed download URL.

#### Reachability
Scoped global roles and the `coordinator` role receive resource read capabilities in seeds. `findAll()` itself can enumerate unscoped resources, making the `resource_id` precondition much weaker than a random UUID guess.

#### Severity
High: the path exposes private institutional resources and R2 signed URLs across territory boundaries to actors that should only see their own scope. It is authenticated and role-limited, so it is not critical. Evidence that all resources are public would lower severity.

#### Remediation
Pass `req.authorization` to admin read methods and use the same `buildVisibleResourceConditions()` logic as `/resources/me*`. Add integration tests for LF-A actor reading/signing LF-B resources and expect 403/404.

### [3] Admin resource update and delete endpoints mutate resources outside the actor scope

| Field | Value |
|---|---|
| Severity | high |
| Confidence | high |
| Confidence rationale | The controller omits authorization context for update/delete, and the service mutates by UUID without checking either the existing resource scope or a requested new scope. |
| Category | Authorization bypass / IDOR |
| CWE | CWE-639 Authorization Bypass Through User-Controlled Key; CWE-863 Incorrect Authorization |
| Affected lines | /Users/abner/Documents/development/sacdia/sacdia-backend/src/resources/resources.controller.ts:234-273; /Users/abner/Documents/development/sacdia/sacdia-backend/src/resources/resources.service.ts:552-658; /Users/abner/Documents/development/sacdia/sacdia-backend/src/resources/resources.service.ts:696-777 |

#### Summary
`PATCH /resources/:id` and `DELETE /resources/:id` require the global permission name but do not bind the target resource to the actor. The update method also accepts `scope_level` and `scope_id`, so an actor can modify metadata, replace a file, move a resource, or soft-delete resources outside their territory.

#### Validation
Static trace. Checklist: [x] attacker controls `id` and update body; [x] guard only checks global permission; [x] service loads target by UUID; [x] service writes update/soft-delete; [x] existing helper `validateScopeAuthorization()` is not used in these methods.

#### Dataflow
`PATCH/DELETE /api/v1/resources/:id` -> global `resources:update` or `resources:delete` check -> `ResourcesService.update/remove(id, ...)` -> `findUnique({ resource_id: id })` -> `prisma.resources.update()` with no contextual authorization.

#### Reachability
Any scoped actor with `resources:update` or `resources:delete` can reach the route. Resource IDs are enumerable via the unscoped read path described in the previous finding.

#### Severity
High: this enables cross-territory integrity attacks against institutional resources and can remove or relocate content. It is role-limited and not direct code execution, so high is appropriate rather than critical.

#### Remediation
Authorize both the existing resource and any requested target scope before mutation. Pass `req.authorization` to the service, require existing-scope access, and rerun `validateScopeAuthorization()` for changed `scope_level/scope_id`. Add negative tests for cross-scope update/delete.

### [4] Annual folder read routes expose private evidence across clubs

| Field | Value |
|---|---|
| Severity | high |
| Confidence | high |
| Confidence rationale | The read controllers use `active_assignment`, which does not bind folder/section IDs to the active club, and the service presigns evidence without receiving actor context. |
| Category | Authorization bypass / IDOR |
| CWE | CWE-639 Authorization Bypass Through User-Controlled Key; CWE-862 Missing Authorization |
| Affected lines | /Users/abner/Documents/development/sacdia/sacdia-backend/src/annual-folders/annual-folders.controller.ts:160-220,223-260; /Users/abner/Documents/development/sacdia/sacdia-backend/src/annual-folders/annual-folder-by-section.controller.ts:27-86; /Users/abner/Documents/development/sacdia/sacdia-backend/src/annual-folders/annual-folders.service.ts:338-427,433-522,1534-1545; /Users/abner/Documents/development/sacdia/sacdia-backend/src/common/guards/permissions.guard.ts:121-125 |

#### Summary
Annual folder reads require `evidence_folders:read` on the caller active assignment but never compare the target `folderId`, enrollment, or path `sectionId` to that assignment. The service loads the folder and then presigns every evidence file.

#### Validation
Static trace. Checklist: [x] attacker controls `folderId`, `enrollmentId`, or integer `sectionId`; [x] guard returns true for `active_assignment` after permission check; [x] service has no actor parameter; [x] service calls `presignFolderEvidences`; [x] other methods contain `assertFolderClubAccess`, proving a known missing control.

#### Dataflow
Authenticated club member -> `GET /annual-folders/:folderId`, `GET /annual-folders/by-enrollment/:enrollmentId`, or `GET /club-sections/:sectionId/annual-folder` -> `PermissionsGuard` checks only active-assignment permission -> service `findUnique()` by target ID -> `presignFolderEvidences()` -> response with evidence metadata and signed URLs.

#### Reachability
Club members have evidence folder permissions. The section-based route uses sequential integer section IDs, reducing the difficulty of finding another club annual folder compared with random UUID-only access.

#### Severity
High: this exposes private evidence and evaluation data across clubs. It is authenticated and object-ID dependent, so it is high rather than critical. A runtime proof with two clubs would mainly strengthen exploitability confidence.

#### Remediation
Bind folder/enrollment/section reads to the actor. Use `club_section` or `club_assignment` resource resolution, or call `assertFolderClubAccess()` before returning data. Prefer 404 for cross-club IDs and add tests for member of Club A reading Club B folder.

### [5] Annual folder upload accepts evidence for folders owned by another club

| Field | Value |
|---|---|
| Severity | high |
| Confidence | high |
| Confidence rationale | The upload route checks only active-assignment permission; the service verifies folder state and template section but never calls the existing folder ownership guard before writing evidence. |
| Category | Authorization bypass / cross-tenant write |
| CWE | CWE-639 Authorization Bypass Through User-Controlled Key; CWE-863 Incorrect Authorization |
| Affected lines | /Users/abner/Documents/development/sacdia/sacdia-backend/src/annual-folders/annual-folders.controller.ts:263-314; /Users/abner/Documents/development/sacdia/sacdia-backend/src/annual-folders/annual-folders.service.ts:533-619,733-806 |

#### Summary
`uploadEvidence()` receives the caller user ID but uses it only as `uploaded_by`. It validates that the folder exists, is open, and the section belongs to the template, then uploads to R2 and creates an evidence row without checking that the caller belongs to the club that owns the folder.

#### Validation
Static trace. Checklist: [x] attacker controls `folderId` and `sectionId`; [x] guard only validates active-assignment permission; [x] service writes R2 object and DB row; [x] `assertFolderClubAccess()` exists nearby but is not called; [x] file MIME validation does not address ownership.

#### Dataflow
`POST /annual-folders/:folderId/sections/:sectionId/evidences` multipart file -> active assignment permission -> `AnnualFoldersService.uploadEvidence()` -> folder/template checks -> R2 upload -> `annual_folder_evidences.create({ annual_folder_id: folderId, uploaded_by: userId })`.

#### Reachability
A user with `evidence_folders:update` in any active club assignment can reach the route. The read vulnerability can reveal the needed folder and section identifiers, so this write path chains naturally from the previous finding.

#### Severity
High: unauthorized evidence upload can corrupt another club evidence folder and influence later review/ranking flows. It is authenticated and needs an open folder, so it remains high rather than critical.

#### Remediation
Call `assertFolderClubAccess(folderId, userId)` at the start of `uploadEvidence()`, before file upload. Add a regression test where Club A member tries to upload into Club B folder and assert no R2 upload or DB row occurs.

### [6] Annual folder evaluation actions are not bound to the reviewer territory

| Field | Value |
|---|---|
| Severity | high |
| Confidence | high |
| Confidence rationale | Evaluation, reopen, and union confirmation require only a global permission; the service mutates evaluation rows by folder/section without checking the folder territory against the actor. |
| Category | Authorization bypass / cross-territory integrity |
| CWE | CWE-639 Authorization Bypass Through User-Controlled Key; CWE-863 Incorrect Authorization |
| Affected lines | /Users/abner/Documents/development/sacdia/sacdia-backend/src/annual-folders/evaluation.controller.ts:63-189; /Users/abner/Documents/development/sacdia/sacdia-backend/src/annual-folders/evaluation.service.ts:40-46,186-204,420-439,514-595; /Users/abner/Documents/development/sacdia/sacdia-backend/src/annual-folders/annual-folders.service.ts:1066-1074,829-850 |

#### Summary
Annual folder evaluation routes use `@AuthorizationResource({ type: global })`, so the guard checks the permission name but not the folder territory. `EvaluationService` then updates section evaluations, reopens sections, and records union decisions by folder and section IDs without comparing against the actor local field or union.

#### Validation
Static trace. Checklist: [x] attacker controls folder/section IDs; [x] controller uses global resource; [x] service updates evaluation rows; [x] no territory check appears in the service methods; [x] `assertEvidenceTerritoryAccess()` demonstrates a local pattern for the missing check.

#### Dataflow
LF/union actor with `annual_folders:evaluate` -> `POST /annual-folders/:folderId/sections/:sectionId/evaluate`, `/reopen`, or `/confirm-union` -> global permission check -> `EvaluationService` transaction -> `annual_folder_section_evaluations.update()` and folder total recalculation.

#### Reachability
This requires a reviewer-tier global role, but the intended boundary is territorial. A reviewer from LF-A or Union-A can affect folders in LF-B or Union-B if they know or discover the folder and section IDs.

#### Severity
High: cross-territory approval, rejection, reopening, and union confirmation can alter institutional scoring and final validation. It is privileged but crosses a meaningful authorization boundary. Runtime tests with two territories would further confirm exploitability.

#### Remediation
Resolve the folder hierarchy before every evaluation mutation and enforce `authorizationContext.canAccessHierarchyScope()` or a folder-specific territory assertion. For union confirmation, require the folder union to match the actor union unless super-admin. Add cross-territory negative tests.

### [7] Membership request approval checks the wrong resource and updates by assignment ID only

| Field | Value |
|---|---|
| Severity | high |
| Confidence | high |
| Confidence rationale | The controller labels `clubSectionId` as a club ID for authorization, while approve/reject ignore that path value and update any pending assignment by UUID. |
| Category | Authorization bypass / IDOR |
| CWE | CWE-639 Authorization Bypass Through User-Controlled Key; CWE-863 Incorrect Authorization |
| Affected lines | /Users/abner/Documents/development/sacdia/sacdia-backend/src/membership-requests/membership-requests.controller.ts:70-98,100-129; /Users/abner/Documents/development/sacdia/sacdia-backend/src/membership-requests/membership-requests.service.ts:78-87,122-136; /Users/abner/Documents/development/sacdia/sacdia-backend/src/common/guards/permissions.guard.ts:322-343,1042-1077 |

#### Summary
The membership controller path is `/club-sections/:clubSectionId/...`, but the authorization metadata uses `{ type: club, clubIdParam: clubSectionId }`. `validateClubScope()` therefore interprets a section ID slot as a main club ID. The approve/reject handlers then drop `clubSectionId` and call service methods that update by `assignment_id` only.

#### Validation
Static trace. Checklist: [x] attacker controls path `clubSectionId` and `assignmentId`; [x] guard validates the path number as a main club ID; [x] service omits section binding; [x] updateMany mutates by assignment UUID/status/active only; [x] an existing `club_assignment` resolver could bind the target assignment but is not used.

#### Dataflow
Approver in Club A -> `POST /club-sections/{clubAId}/membership-requests/{victimAssignmentId}/approve` or `/reject` -> guard validates Club A permission because it treats the path value as `clubId` -> `MembershipRequestsService.approve/reject(assignmentId, actorId)` -> `club_role_assignments.updateMany({ assignment_id, status: pending, active: true })`.

#### Reachability
The attacker needs `club_members:approve` in their own club and a pending assignment UUID from another section/club. UUID knowledge is a precondition, but the write is a real cross-club membership decision once the ID is known.

#### Severity
High: unauthorized approval or rejection of role assignments changes membership and authorization state in another club. UUID knowledge limits likelihood, but the impact is a meaningful cross-boundary integrity break.

#### Remediation
Use `@AuthorizationResource({ type: club_assignment, idParam: assignmentId })` or explicitly resolve `assignmentId` to its `club_section_id` and compare it with the path section. Pass `clubSectionId` into service `approve/reject` and include it in the `updateMany` where clause. Add tests proving Club A approver cannot approve Club B assignment.

### [8] Development docs publish shared test credentials and fail open when Basic Auth envs are missing

| Field | Value |
|---|---|
| Severity | medium |
| Confidence | medium |
| Confidence rationale | The credentials and fail-open middleware are directly present in the repo; deployment exposure and data sensitivity were not proven locally. |
| Category | Credential exposure / fail-open access control |
| CWE | CWE-798 Use of Hard-coded Credentials; CWE-306 Missing Authentication for Critical Function |
| Affected lines | /Users/abner/Documents/development/sacdia/sacdia-docs/src/middleware.ts:3-10,35-36; /Users/abner/Documents/development/sacdia/sacdia-docs/content/dev/testing/usuarios-prueba.mdx:12-35; /Users/abner/Documents/development/sacdia/docs/testing/TEST-USERS.md:7-30; /Users/abner/Documents/development/sacdia/sacdia-docs/.source/server.ts:135 |

#### Summary
The docs repo contains a `/dev/testing/usuarios-prueba` page and root test-user document listing a shared password and role-specific test emails. The docs middleware protects `/dev`, but explicitly allows access when either `DEV_DOCS_USER` or `DEV_DOCS_PASSWORD` is not configured.

#### Validation
Static validation. Checklist: [x] credential values are committed; [x] generated docs source includes the testing page; [x] middleware fails open without envs; [ ] production env exposure was not verified; [ ] whether the Neon development branch contains sensitive data was not verified.

#### Dataflow
Visitor requests `/dev/testing/usuarios-prueba` -> `middleware.ts` reads Basic Auth envs -> if one is missing returns `NextResponse.next()` -> Fumadocs renders committed MDX with shared password and test account emails.

#### Reachability
Reachability depends on deployment configuration. If `sacdia-docs` is publicly deployed without both Basic Auth env vars, anonymous users can read the credentials. Even with auth enabled, the credentials remain versioned in repo/docs artifacts.

#### Severity
Medium: exposed shared QA credentials can compromise development accounts and role workflows, but production-data impact is not proven. If development contains copied real data or is internet-accessible with weak isolation, severity should be raised.

#### Remediation
Rotate the test password, remove concrete passwords from versioned docs, and store test credentials in a private runbook or secret manager. Make production middleware fail closed unless an explicit `DEV_DOCS_PUBLIC=true` override is set.

### [9] Docs sync workflow persists cross-repo tokens while running installs and generators

| Field | Value |
|---|---|
| Severity | medium |
| Confidence | medium |
| Confidence rationale | Workflow evidence shows cross-repo token checkouts before `pnpm install` and generation steps; exact PAT scopes and runtime git config were not observed. |
| Category | CI credential exposure / supply-chain hardening |
| CWE | CWE-522 Insufficiently Protected Credentials; CWE-829 Inclusion of Functionality from Untrusted Control Sphere |
| Affected lines | /Users/abner/Documents/development/sacdia/sacdia-docs/.github/workflows/sync-docs.yml:29-48,58-74; /Users/abner/Documents/development/sacdia/sacdia-docs/package.json:13 |

#### Summary
`sync-docs.yml` checks out backend/admin/app using `secrets.SACDIA_REPO_TOKEN` and does not set `persist-credentials: false`. It then runs dependency installation and code generation in the workspace. By default, checkout credentials can remain in Git config for later steps.

#### Validation
Static workflow validation. Checklist: [x] cross-repo token is used; [x] no `persist-credentials: false` appears; [x] install/generator steps run after token checkout; [ ] token scopes were not verified; [ ] no malicious dependency or script was executed in this scan.

#### Dataflow
Scheduled/manual/repository-dispatch workflow -> `actions/checkout` with PAT for sibling repos -> credentials persist in checkout config by default -> `pnpm install`, `prisma generate`, `tsx`, and docs sync scripts run in the same job workspace.

#### Reachability
A compromised dependency/lifecycle script, malicious merged generator, or compromised source repo code running in this scheduled job could read or use the persisted token. The workflow does not run on arbitrary fork PRs, reducing likelihood.

#### Severity
Medium: this is a credible CI secret-handling weakness with cross-repo impact if the token is broad. Lack of token-scope evidence and absence of PR-triggered untrusted code keep it below high.

#### Remediation
Set `persist-credentials: false` on all checkouts that use PATs, prefer a GitHub App or read-only token per repo, run installs with `--ignore-scripts` where possible, and separate trusted generation from token-bearing checkout steps.



## Reviewed Surfaces

| Surface | Risk Area | Outcome | Notes |
|---|---|---|---|
| sacdia-backend users profile | RBAC territory / self-service profile | Reported | BACKEND-CAND-01 |
| sacdia-backend resources admin reads | Private resources / signed URLs | Reported | BACKEND-CAND-02 |
| sacdia-backend resources admin mutations | Resource integrity | Reported | BACKEND-CAND-03 |
| sacdia-backend annual folder reads | Evidence confidentiality | Reported | BACKEND-CAND-04 |
| sacdia-backend annual folder uploads | Evidence integrity | Reported | BACKEND-CAND-05 |
| sacdia-backend annual folder evaluations | Territorial review integrity | Reported | BACKEND-CAND-06 |
| sacdia-backend membership requests | Club assignment approval integrity | Reported | BACKEND-CAND-07 |
| sacdia-backend auth/session/MFA/JWT | Authn hardening | No issue found | JWT strategy, MFA guard, CORS, Helmet and Sentry redaction reviewed; no reportable issue promoted. |
| sacdia-backend raw SQL/SSRF/upload keys | Injection/file handling | No issue found | Reviewed Prisma raw usages, R2 key generation, file magic-byte validation, and outbound fetch callsites. |
| sacdia-admin token bridge | Browser token containment | Rejected | Same-origin `/api/auth/token` weakens httpOnly against XSS, but no standalone attacker path was proven. |
| sacdia-admin honors material URL | XSS/navigation/iframe | Rejected | Stored URL needs allowlist hardening, but author is privileged and CSP/default frame policy limits iframe impact; no proven token theft path. |
| sacdia-admin CSRF/redirects/secrets | Browser security | No issue found | SameSite strict cookies, safe relative redirects, Sentry redaction, and empty env example reviewed. |
| sacdia-app iOS OAuth custom scheme | OAuth callback interception | Needs follow-up | Code registers `io.sacdia.app`, but OAuth buttons are currently commented out, app calls GET while backend exposes POST, and backend default redirect is HTTPS. Re-check before re-enabling OAuth. |
| sacdia-app certificate import file_url | Client-supplied file references | Rejected | Current backend OCR provider does not dereference `file_url`; risk is provenance/hardening rather than proven SSRF. |
| sacdia-app annual folder legacy upload | Client/backend contract drift | Rejected | Mobile legacy JSON `file_url` endpoint no longer matches backend multipart route. |
| sacdia-app token storage/TLS/FCM | Mobile client security | No issue found | Secure storage, release HTTPS guard, debug-only logging, and FCM handling reviewed. |
| sacdia-docs dev credentials | Credential exposure | Reported | DOCS-CAND-01 |
| sacdia-docs generated MDX | Stored XSS in docs | Needs follow-up | Escaping is incomplete for MDX expression contexts, but source requires contributor/generator control and no runtime PoC was executed. |
| sacdia-docs sync workflow | CI token exposure | Reported | DOCS-CAND-03 |
| root RBAC workflow | CI secret handling | Needs follow-up | PR same-repo risk exists, but fork PRs do not receive secrets by default and token scopes were not verified. |


## Open Questions And Follow Up

- Re-run a focused OAuth mobile review before enabling the commented Google/Apple buttons in `/Users/abner/Documents/development/sacdia/sacdia-app/lib/features/auth/presentation/views/login_view.dart`; verify iOS Universal Links and backend redirect allowlist together.
- Run a CI secrets hardening pass over `/Users/abner/Documents/development/sacdia/sacdia-docs/.github/workflows/sync-docs.yml` and `/Users/abner/Documents/development/sacdia/.github/workflows/rbac-permissions-consistency.yml` with the actual GitHub token scopes.
- Add dynamic two-tenant regression tests for every backend authorization finding before remediation is considered complete.

Report artifacts:

- Markdown: `/tmp/codex-security-scans/sacdia/7a15ebd9a216_20260610T213223Z/report.md`
- HTML: `/tmp/codex-security-scans/sacdia/7a15ebd9a216_20260610T213223Z/report.html`
- Coverage ledger: `/tmp/codex-security-scans/sacdia/7a15ebd9a216_20260610T213223Z/artifacts/03_coverage/repository_coverage_ledger.md`
- Validation summary: `/tmp/codex-security-scans/sacdia/7a15ebd9a216_20260610T213223Z/artifacts/05_findings/validation_summary.md`
- Attack-path summary: `/tmp/codex-security-scans/sacdia/7a15ebd9a216_20260610T213223Z/artifacts/05_findings/attack_path_analysis_report.md`
