# Sacdia Admin Adaptive iOS Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implementar la composición adaptativa nativa de Sacdia Admin para iPhone/iPad, cerrar auth productiva contract-first y conservar los contratos, permisos y view-models actuales.

**Architecture:** El backend mantiene autoridad sobre autenticación/autorización y los contratos REST; iOS agrega un transporte HTTP testeable, conserva `AuthSession`/repositorios como puertos y cambia sólo la composición SwiftUI por size class. iPhone usa cuatro tabs y sheets; iPad usa split/sidebar/detalle. La entrega evita una mega-refactorización y se divide en slices con commits pequeños.

**Tech Stack:** Swift 6, SwiftUI, iOS 17.4+, `URLSession`/`URLProtocol`, Observation, Keychain Services, XCTest/Testing y UI tests existentes en `sacdia-admin-ios`.

---

## Reglas de ejecución

1. Leer `AGENTS.md`, este plan y el diseño antes de cada batch.
2. No hardcodear 430×932; usar `horizontalSizeClass`, `dynamicTypeSize`, safe areas y espacio disponible.
3. No inventar endpoints, DTOs, permisos ni campos. La fuente primaria es `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, `docs/api/SECURITY-GUIDE.md` y el runtime backend.
4. Mantener `AppState`, `AppRouter`, `AdminNavigationProjection`, view-models y protocolos existentes salvo cambios mínimos justificados por el contrato.
5. No guardar access tokens en disco, no loggear secretos y no permitir que el cliente sustituya guards backend.
6. Cada task sigue RED → comando que demuestra FAIL → implementación mínima → comando GREEN → commit convencional.
7. Los comandos de test/build se documentan aquí para ejecución futura; **no se ejecutan durante la creación de este plan**.
8. No hacer `build` en este trabajo documental. Los artefactos sólo se validan con revisión y `git diff --check`.

## Comandos base para ejecución futura

Desde `/Users/abner/Documents/development/sacdia`:

```bash
xcodebuild -project sacdia-admin-ios/SacdiaAdmin.xcodeproj \
  -scheme SacdiaAdmin \
  -destination 'platform=iOS Simulator,name=iPhone 12,OS=latest' \
  test

xcodebuild -project sacdia-admin-ios/SacdiaAdmin.xcodeproj \
  -scheme SacdiaAdmin \
  -destination 'platform=iOS Simulator,name=iPad (10th generation),OS=latest' \
  -only-testing:SacdiaAdminUITests \
  test

bundle exec ruby sacdia-admin-ios/scripts/verify_project.rb
bundle exec ruby sacdia-admin-ios/scripts/verify_project_test.rb
```

Si el simulador no está instalado, registrar el nombre/OS disponible y usar el equivalente; no cambiar la referencia visual ni ocultar el caso.

## Batch 0 — cerrar contrato auth y gate B2/P0 antes de Release

### Task 0.1: Fijar contrato backend de login, MFA, refresh, `/me` y `access_panel`

**Files:**
- Inspect: `docs/api/ENDPOINTS-LIVE-REFERENCE.md:415-437`
- Inspect: `docs/api/SECURITY-GUIDE.md:128-170`
- Inspect: `sacdia-backend/src/auth/auth.controller.ts:55-150,240-337`
- Inspect: `sacdia-backend/src/auth/mfa.controller.ts:35-150`
- Inspect: `sacdia-backend/src/auth/auth.service.ts:189-330`
- Inspect/modify: `sacdia-backend/src/auth/auth.controller.spec.ts`
- Inspect/modify: `sacdia-backend/src/auth/auth.service.spec.ts`
- Create: `sacdia-backend/src/auth/mfa.controller.spec.ts`
- Inspect/modify: `sacdia-backend/src/common/guards/jwt-auth.guard.ts`, `global-roles.guard.ts`, `permissions.guard.ts`
- Inspect/modify: `sacdia-backend/src/admin/admin-users.service.ts:100-170,1300-1360`
- Modify: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- Modify: `docs/api/SECURITY-GUIDE.md`

**Step 1: Escribir tests RED contractuales**

Cubrir explícitamente:

```ts
it('documents the login envelope and the mfa_pending signal used by clients');
it('allows POST /auth/mfa/verify with AAL1 and returns the AAL2 transition');
it('refreshes with camelCase refreshToken and rejects legacy snake_case');
it('defines the /auth/me authorization fields needed by AdminCurrentSession');
it('denies a role-eligible user when access_panel is false');
it('keeps deny-by-default when a required permission is absent');
```

Run:

```bash
cd sacdia-backend
pnpm exec jest src/auth/auth.controller.spec.ts src/auth/auth.service.spec.ts src/auth/mfa.controller.spec.ts --runInBand
```

Expected: FAIL where current tests/documentation do not prove the mobile contract or `access_panel` enforcement.

**Step 2: Implement only the smallest contract closure**

Document the exact existing response fields and claim semantics. If a field required by iOS is absent, choose one of the following only after backend approval: use an existing follow-up `GET /api/v1/auth/me`, or extend the existing response contract. Do not create an untracked endpoint. Ensure `access_panel` is enforced server-side or record an approved compensating control that blocks Release.

**Step 3: Run GREEN and update canonical docs**

```bash
cd sacdia-backend
pnpm exec jest src/auth/auth.controller.spec.ts src/auth/auth.service.spec.ts src/auth/mfa.controller.spec.ts --runInBand
```

Expected: PASS; `ENDPOINTS-LIVE-REFERENCE.md` and `SECURITY-GUIDE.md` describe the same fields, AAL transitions and deny behavior as runtime tests.

**Step 4: Commit**

```bash
git add sacdia-backend/src/auth sacdia-backend/src/common/guards sacdia-backend/src/admin/admin-users.service.ts docs/api/ENDPOINTS-LIVE-REFERENCE.md docs/api/SECURITY-GUIDE.md
git commit -m "fix(auth): close mobile session contract"
```

### Checkpoint 0 — Auth gate

Stop before iOS production auth if any of these are unresolved:

- login/MFA/refresh response cannot be decoded without guessing;
- AAL1 cannot be exchanged for AAL2 and revalidated;
- `/auth/me` lacks the authorization/session fields required by iOS;
- `access_panel` is client-only or undocumented.

Report the exact failing test and keep Release on `contractUnavailable`/safe denial.

## Batch 1 — productive iOS transport and auth lifecycle

### Task 1.1: Add a redacted, injectable HTTP client

**Files:**
- Create: `sacdia-admin-ios/SacdiaAdmin/Infrastructure/HTTP/AdminHTTPClient.swift`
- Create: `sacdia-admin-ios/SacdiaAdmin/Infrastructure/HTTP/AdminHTTPError.swift`
- Modify: `sacdia-admin-ios/SacdiaAdmin/Core/Configuration/AppConfiguration.swift`
- Test: `sacdia-admin-ios/SacdiaAdminTests/AdminHTTPClientTests.swift`

**Step 1: Write tests RED**

Cover base URL joining `/api/v1`, bearer header, JSON decoding, HTTP 401/403/429/5xx mapping, timeout/cancellation and absence of token/password in `CustomStringConvertible`/debug output.

Run:

```bash
xcodebuild -project sacdia-admin-ios/SacdiaAdmin.xcodeproj -scheme SacdiaAdmin -destination 'platform=iOS Simulator,name=iPhone 12,OS=latest' -only-testing:SacdiaAdminTests/AdminHTTPClientTests test
```

Expected: FAIL because the client/types do not exist.

**Step 2: Implement minimal client**

Use an injected `URLSession`/`URLProtocol` configuration, `URLRequest`, `Accept: application/json`, `Content-Type` only for bodies, `Authorization: Bearer`, and strict decoding of documented envelopes. Keep base URL in `AppConfiguration`; never put secrets in source or `.env`.

**Step 3: Run GREEN**

Run the same focused command. Expected: PASS with redaction assertions.

**Step 4: Commit**

```bash
git add sacdia-admin-ios/SacdiaAdmin/Infrastructure/HTTP sacdia-admin-ios/SacdiaAdmin/Core/Configuration/AppConfiguration.swift sacdia-admin-ios/SacdiaAdminTests/AdminHTTPClientTests.swift
git commit -m "feat(ios): add redacted admin http client"
```

### Task 1.2: Implement productive `AdminAuthAPI` and session adapters

**Files:**
- Create: `sacdia-admin-ios/SacdiaAdmin/Features/Auth/Data/AdminAuthHTTPAPI.swift`
- Modify: `sacdia-admin-ios/SacdiaAdmin/Features/Auth/Domain/AdminAuthAPI.swift:1-30`
- Modify: `sacdia-admin-ios/SacdiaAdmin/Features/Auth/Domain/AdminAuthModels.swift:1-190`
- Modify: `sacdia-admin-ios/SacdiaAdmin/Features/Auth/Session/AuthSession.swift:220-420`
- Modify: `sacdia-admin-ios/SacdiaAdmin/Features/Auth/Session/AdminAuthFailure.swift`
- Create: `sacdia-admin-ios/SacdiaAdminTests/AdminAuthHTTPAPITests.swift`
- Modify: `sacdia-admin-ios/SacdiaAdminTests/AuthSessionBootstrapTests.swift`, `AuthSessionInteractionTests.swift`

**Step 1: Write tests RED**

Cover login success, invalid credentials, explicit MFA pending challenge, invalid/expired MFA, refresh rotation with `refreshToken` camelCase, `/auth/me` permission snapshot, logout best effort and malformed/missing fields. Include the contract gate as a test fixture: a role with `access_panel=false` cannot reach `.authenticated`.

Run:

```bash
xcodebuild -project sacdia-admin-ios/SacdiaAdmin.xcodeproj -scheme SacdiaAdmin -destination 'platform=iOS Simulator,name=iPhone 12,OS=latest' -only-testing:SacdiaAdminTests/AdminAuthHTTPAPITests -only-testing:SacdiaAdminTests/AuthSessionBootstrapTests -only-testing:SacdiaAdminTests/AuthSessionInteractionTests test
```

Expected: FAIL against `UnavailableAdminAuthAPI`/missing decoder.

**Step 2: Implement the adapter**

Map documented status/data envelopes into existing redacted models. Preserve refresh token from login through MFA when the documented MFA response returns only a new access token; revalidate with `/auth/me` according to the closed Batch 0 contract. Refresh must persist the replacement token only after the response validates. On logout, purge local credentials regardless of remote best-effort result.

**Step 3: Run GREEN and security checks**

Run the focused command above; expected PASS. Verify no raw credential appears in test failure descriptions or logs.

**Step 4: Commit**

```bash
git add sacdia-admin-ios/SacdiaAdmin/Features/Auth sacdia-admin-ios/SacdiaAdminTests/AdminAuthHTTPAPITests.swift sacdia-admin-ios/SacdiaAdminTests/AuthSessionBootstrapTests.swift sacdia-admin-ios/SacdiaAdminTests/AuthSessionInteractionTests.swift
git commit -m "feat(ios): add productive admin auth transport"
```

### Task 1.3: Wire production composition and authenticated repositories

**Files:**
- Modify: `sacdia-admin-ios/SacdiaAdmin/App/AppComposition.swift:1-43`
- Modify: `sacdia-admin-ios/SacdiaAdmin/App/SacdiaAdminApp.swift:20-60`
- Create: `sacdia-admin-ios/SacdiaAdmin/Features/Users/Data/AdminUsersHTTPRepository.swift`
- Create: `sacdia-admin-ios/SacdiaAdmin/Features/Users/Data/AdminUserDetailHTTPRepository.swift`
- Create: `sacdia-admin-ios/SacdiaAdmin/Features/Clubs/Data/ClubsListHTTPRepository.swift`
- Create: `sacdia-admin-ios/SacdiaAdmin/Features/Clubs/Data/ClubDetailHTTPRepository.swift`
- Modify: `sacdia-admin-ios/SacdiaAdminTests/AppCompositionTests.swift`
- Create: `sacdia-admin-ios/SacdiaAdminTests/AdminRepositoriesHTTPTests.swift`

**Step 1: Write tests RED**

Assert DEBUG fake injection is available only with `-ui-testing-fake-admin-auth`; Release never selects fake or unavailable repositories when the contract configuration is enabled. Assert Users query maps `search/role/active/page` to `/api/v1/admin/users`, detail maps to `/api/v1/admin/users/:id`, and Clubs maps only documented `/api/v1/clubs` fields/filters.

Run:

```bash
xcodebuild -project sacdia-admin-ios/SacdiaAdmin.xcodeproj -scheme SacdiaAdmin -destination 'platform=iOS Simulator,name=iPhone 12,OS=latest' -only-testing:SacdiaAdminTests/AppCompositionTests -only-testing:SacdiaAdminTests/AdminRepositoriesHTTPTests test
```

Expected: FAIL until composition and HTTP repositories exist.

**Step 2: Implement composition**

Inject one authenticated HTTP client into auth and repositories. Keep fakes under `#if DEBUG`; keep Unavailable implementations as a safe fallback only when configuration/contract is unavailable. Do not alter public repository protocols or existing view-model query semantics.

**Step 3: Run GREEN**

Run the focused command; expected: PASS.

**Step 4: Commit**

```bash
git add sacdia-admin-ios/SacdiaAdmin/App sacdia-admin-ios/SacdiaAdmin/Features/Users/Data sacdia-admin-ios/SacdiaAdmin/Features/Clubs/Data sacdia-admin-ios/SacdiaAdminTests/AppCompositionTests.swift sacdia-admin-ios/SacdiaAdminTests/AdminRepositoriesHTTPTests.swift
git commit -m "feat(ios): wire authenticated admin repositories"
```

## Batch 2 — design system before screen composition

### Task 2.1: Add adaptive visual tokens and surfaces

**Files:**
- Modify: `sacdia-admin-ios/SacdiaAdmin/DesignSystem/SacdiaTokens.swift:21-53`
- Modify: `sacdia-admin-ios/SacdiaAdmin/DesignSystem/SacdiaChrome.swift:16-75`
- Create: `sacdia-admin-ios/SacdiaAdmin/DesignSystem/SacdiaComponents.swift`
- Modify: `sacdia-admin-ios/SacdiaAdminTests/SacdiaTokensTests.swift`
- Modify: `sacdia-admin-ios/SacdiaAdminTests/SacdiaChromeTests.swift`

**Step 1: Write tests RED**

Test screen margin 16, section gap 24, control height 48, minimum target 44, Dynamic Type style mapping, elevation values/dark fallback, reduce-transparency opaque fallback and no per-row shadow policy.

Run:

```bash
xcodebuild -project sacdia-admin-ios/SacdiaAdmin.xcodeproj -scheme SacdiaAdmin -destination 'platform=iOS Simulator,name=iPhone 12,OS=latest' -only-testing:SacdiaAdminTests/SacdiaTokensTests -only-testing:SacdiaAdminTests/SacdiaChromeTests test
```

Expected: FAIL for missing tokens/components.

**Step 2: Implement tokens/components**

Use semantic SwiftUI fonts with `.fontDesign(.rounded)` only for large titles/hero/primary action; body/data use system Dynamic Type. Add `SacdiaSurface`, `SacdiaSectionHeader`, `SacdiaPrimaryAction`, `SacdiaStatusBadge`, `SacdiaStateView`, and tokenized shadow/elevation. Material/glass is optional; opaque semantic surface is complete and accessible.

**Step 3: Run GREEN and commit**

```bash
xcodebuild -project sacdia-admin-ios/SacdiaAdmin.xcodeproj -scheme SacdiaAdmin -destination 'platform=iOS Simulator,name=iPhone 12,OS=latest' -only-testing:SacdiaAdminTests/SacdiaTokensTests -only-testing:SacdiaAdminTests/SacdiaChromeTests test
git add sacdia-admin-ios/SacdiaAdmin/DesignSystem sacdia-admin-ios/SacdiaAdminTests/SacdiaTokensTests.swift sacdia-admin-ios/SacdiaAdminTests/SacdiaChromeTests.swift
git commit -m "feat(ios): define adaptive admin design system"
```

## Batch 3 — adaptive shell and module discovery

### Task 3.1: Build compact tabs and regular split composition

**Files:**
- Create: `sacdia-admin-ios/SacdiaAdmin/Features/Shell/AdaptiveAdminRootView.swift`
- Create: `sacdia-admin-ios/SacdiaAdmin/Features/Shell/ModuleIndexView.swift`
- Create: `sacdia-admin-ios/SacdiaAdmin/Features/Shell/ModuleSheetView.swift`
- Modify: `sacdia-admin-ios/SacdiaAdmin/Features/Shell/AdminShellView.swift:32-172`
- Modify: `sacdia-admin-ios/SacdiaAdmin/Features/Shell/AdminSidebarView.swift:10-136`
- Modify: `sacdia-admin-ios/SacdiaAdmin/Core/AppRouter.swift`, `AppRoute.swift`, `AppState.swift` only where path preservation requires it
- Create: `sacdia-admin-ios/SacdiaAdminTests/AdaptiveNavigationTests.swift`
- Modify: `sacdia-admin-ios/SacdiaAdminTests/AdminNavigationProjectionTests.swift`, `AppRouterTests.swift`

**Step 1: Write tests RED**

Cover four compact tabs, authorized module projection in Más, path/selection preservation when size class changes, regular split visibility, denied destination fallback, and Dynamic Type accessibility behavior.

Run:

```bash
xcodebuild -project sacdia-admin-ios/SacdiaAdmin.xcodeproj -scheme SacdiaAdmin -destination 'platform=iOS Simulator,name=iPhone 12,OS=latest' -only-testing:SacdiaAdminTests/AdaptiveNavigationTests -only-testing:SacdiaAdminTests/AdminNavigationProjectionTests -only-testing:SacdiaAdminTests/AppRouterTests test
```

Expected: FAIL because compact composition/module sheet do not exist.

**Step 2: Implement minimal adaptive shell**

Use `horizontalSizeClass` and available layout, not device bounds. Compact uses `TabView` + per-tab `NavigationStack`; regular uses current `NavigationSplitView` with sidebar/content/detail. Más presents a searchable sheet with explicit Cancel/selection. Preserve `AppDestination` authorization and current detail routes.

**Step 3: Run GREEN and commit**

```bash
xcodebuild -project sacdia-admin-ios/SacdiaAdmin.xcodeproj -scheme SacdiaAdmin -destination 'platform=iOS Simulator,name=iPhone 12,OS=latest' -only-testing:SacdiaAdminTests/AdaptiveNavigationTests -only-testing:SacdiaAdminTests/AdminNavigationProjectionTests -only-testing:SacdiaAdminTests/AppRouterTests test
git add sacdia-admin-ios/SacdiaAdmin/Features/Shell sacdia-admin-ios/SacdiaAdmin/Core sacdia-admin-ios/SacdiaAdminTests/AdaptiveNavigationTests.swift sacdia-admin-ios/SacdiaAdminTests/AdminNavigationProjectionTests.swift sacdia-admin-ios/SacdiaAdminTests/AppRouterTests.swift
git commit -m "feat(ios): add adaptive admin navigation"
```

## Batch 4 — screens and reusable states

### Task 4.1: Recompose Dashboard for compact and regular

**Files:**
- Modify: `sacdia-admin-ios/SacdiaAdmin/Features/Dashboard/DashboardView.swift:16-202`
- Modify: `sacdia-admin-ios/SacdiaAdmin/Features/Dashboard/DashboardCapability.swift`
- Modify: `sacdia-admin-ios/SacdiaAdminTests/DashboardCapabilityTests.swift`, `DashboardLocalizationTests.swift`
- Create: `sacdia-admin-ios/SacdiaAdminTests/DashboardAdaptiveLayoutTests.swift`

**Steps:**

1. RED: assert one-column task-first compact layout, preserved manifest capabilities, accessible labels and reduced-motion behavior.
2. Run focused `xcodebuild ... -only-testing:SacdiaAdminTests/DashboardAdaptiveLayoutTests ... test`; expect FAIL.
3. Implement hero/status/primary action plus compact capability rows; allow wider regular arrangement only when space permits.
4. Run focused tests; expect PASS.
5. Commit `feat(ios): simplify adaptive admin dashboard`.

### Task 4.2: Recompose Users without changing query/view-model contracts

**Files:**
- Modify: `sacdia-admin-ios/SacdiaAdmin/Features/Users/UI/UsersView.swift:17-212`
- Modify: `sacdia-admin-ios/SacdiaAdmin/Features/Users/UI/UserDetailView.swift:14-196`
- Modify: `sacdia-admin-ios/SacdiaAdmin/Features/Users/Presentation/UsersListViewModel.swift` only for cancellation/state behavior proven by tests
- Create: `sacdia-admin-ios/SacdiaAdmin/Features/Users/UI/UsersFilterSheet.swift`
- Create: `sacdia-admin-ios/SacdiaAdminTests/UsersAdaptiveLayoutTests.swift`
- Modify: `sacdia-admin-ios/SacdiaAdminTests/UsersListTests.swift`, `UsersDetailTests.swift`

**Steps:**

1. RED: compact list is one column; search is discoverable in toolbar; filters open in sheet; table is regular-only with sufficient width; pagination labels remain accessible.
2. Run `xcodebuild ... -only-testing:SacdiaAdminTests/UsersAdaptiveLayoutTests -only-testing:SacdiaAdminTests/UsersListTests -only-testing:SacdiaAdminTests/UsersDetailTests test`; expect FAIL.
3. Implement cards/rows using existing models, `SacdiaFilterSheet`, reusable states and native detail navigation. Keep `search`, `role`, `active`, `page` query semantics unchanged.
4. Run focused tests; expect PASS.
5. Commit `feat(ios): adapt admin users flow`.

### Task 4.3: Recompose Clubs with filter sheet

**Files:**
- Modify: `sacdia-admin-ios/SacdiaAdmin/Features/Clubs/UI/ClubsView.swift:10-74`
- Modify: `sacdia-admin-ios/SacdiaAdmin/Features/Clubs/UI/ClubDetailView.swift:2-10`
- Modify: `sacdia-admin-ios/SacdiaAdmin/Features/Clubs/Presentation/ClubsListViewModel.swift` only for tested apply/cancel behavior
- Create: `sacdia-admin-ios/SacdiaAdmin/Features/Clubs/UI/ClubsFilterSheet.swift`
- Create: `sacdia-admin-ios/SacdiaAdminTests/ClubsAdaptiveLayoutTests.swift`
- Modify: `sacdia-admin-ios/SacdiaAdminTests/ClubsListTests.swift`, `ClubDetailTests.swift`

**Steps:**

1. RED: compact list does not show five compressed controls; sheet preserves active/geography filters and Apply; detail retains summary/location/sections and native back.
2. Run `xcodebuild ... -only-testing:SacdiaAdminTests/ClubsAdaptiveLayoutTests -only-testing:SacdiaAdminTests/ClubsListTests -only-testing:SacdiaAdminTests/ClubDetailTests test`; expect FAIL.
3. Implement one-column list, sheet filters, reusable states and regular-width enhancement only where available.
4. Run focused tests; expect PASS.
5. Commit `feat(ios): adapt admin clubs flow`.

### Task 4.4: Rebuild Auth/MFA screens on productive session states

**Files:**
- Modify: `sacdia-admin-ios/SacdiaAdmin/Features/Auth/UI/AuthRootView.swift:13-290`
- Modify: `sacdia-admin-ios/SacdiaAdmin/Resources/Localizable.xcstrings`
- Create: `sacdia-admin-ios/SacdiaAdminTests/AuthAdaptiveLayoutTests.swift`
- Modify: `sacdia-admin-ios/SacdiaAdminTests/AuthSessionInteractionTests.swift`
- Modify: `sacdia-admin-ios/SacdiaAdminUITests/SacdiaAdminUITests.swift`

**Steps:**

1. RED: assert branded Rounded title hierarchy, labels, 48pt CTA, keyboard-safe MFA, retry/recovery states and no shell access while AAL1/MFA pending.
2. Run `xcodebuild ... -only-testing:SacdiaAdminTests/AuthAdaptiveLayoutTests -only-testing:SacdiaAdminTests/AuthSessionInteractionTests test`; expect FAIL.
3. Implement content-width adaptive form, safe-area CTA, focus management, error announcement, and existing purge/remote-logout debt recovery. Keep fake credentials only in DEBUG UI tests.
4. Run focused tests; expect PASS.
5. Commit `feat(ios): refine adaptive admin authentication`.

### Task 4.5: Standardize loading, empty, error and denied states

**Files:**
- Modify: `sacdia-admin-ios/SacdiaAdmin/DesignSystem/SacdiaComponents.swift`
- Modify: `sacdia-admin-ios/SacdiaAdmin/Features/Dashboard/DashboardView.swift`
- Modify: `sacdia-admin-ios/SacdiaAdmin/Features/Users/UI/UsersView.swift`, `UserDetailView.swift`
- Modify: `sacdia-admin-ios/SacdiaAdmin/Features/Clubs/UI/ClubsView.swift`, `ClubDetailView.swift`
- Create: `sacdia-admin-ios/SacdiaAdminTests/SacdiaStateViewTests.swift`

**Steps:**

1. RED: verify identifiers, VoiceOver labels, retry actions, denied semantics and skeleton/reduced-motion behavior.
2. Run `xcodebuild ... -only-testing:SacdiaAdminTests/SacdiaStateViewTests test`; expect FAIL.
3. Implement shared state component and replace ad hoc `ProgressView`/`ContentUnavailableView` only where semantics remain identical.
4. Run focused tests; expect PASS.
5. Commit `feat(ios): standardize admin screen states`.

## Batch 5 — visual/accessibility verification and documentation closure

### Task 5.1: Add UI journeys and visual matrix hooks

**Files:**
- Modify: `sacdia-admin-ios/SacdiaAdminUITests/SacdiaAdminUITests.swift`
- Create: `sacdia-admin-ios/SacdiaAdminUITests/AdaptiveNavigationUITests.swift`
- Modify: `sacdia-admin-ios/Documentation/Parity/README.md` only if evidence contract changes
- Modify: `docs/api/FRONTEND-INTEGRATION-GUIDE.md` only if auth/session fields changed in Batch 0

**Steps:**

1. RED: add journeys for compact tabs, Más sheet, Users/Clubs detail, empty/error/denied, dark mode, Dynamic Type accessibility5 and Reduce Motion.
2. Run iPhone UI tests:

```bash
xcodebuild -project sacdia-admin-ios/SacdiaAdmin.xcodeproj -scheme SacdiaAdmin -destination 'platform=iOS Simulator,name=iPhone 12,OS=latest' -only-testing:SacdiaAdminUITests test
```

Expected: FAIL until journeys exist.

3. Implement only missing identifiers/behavior; do not weaken assertions to hide clipping or missing controls.
4. Run the iPhone command and the iPad command from “Comandos base”; expected PASS.
5. Record manual screenshot checks for iPhone 11, iPhone 12, 430×932 reference, modern iPhone, iPad portrait/landscape, light/dark, Dynamic Type and Reduce Motion.
6. Commit `test(ios): cover adaptive admin journeys`.

### Task 5.2: Final verification and docs reconciliation

**Files:**
- Inspect: all files changed by Tasks 0–5
- Modify if required: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, `docs/api/SECURITY-GUIDE.md`, `docs/api/FRONTEND-INTEGRATION-GUIDE.md`, `sacdia-admin-ios/Documentation/Parity/*`

**Step 1: Run focused/full verification**

```bash
xcodebuild -project sacdia-admin-ios/SacdiaAdmin.xcodeproj -scheme SacdiaAdmin -destination 'platform=iOS Simulator,name=iPhone 12,OS=latest' test
bundle exec ruby sacdia-admin-ios/scripts/verify_project.rb
bundle exec ruby sacdia-admin-ios/scripts/verify_project_test.rb
git diff --check
```

Expected: all tests/project checks pass; no whitespace errors; no undocumented endpoint/DTO/permission drift.

**Step 2: Confirm Release gates**

- Productive `AdminAuthHTTPAPI` is injected when configured.
- `FakeAdminAuthAPI` and in-memory tokens are compiled only under DEBUG.
- Release cannot enter shell with unresolved `access_panel`/AAL2 contract.
- Keychain remains non-synchronizable and access token remains memory-only.

**Step 3: Commit docs/code reconciliation**

```bash
git add docs/api sacdia-admin-ios/Documentation/Parity
git commit -m "docs(ios): reconcile adaptive admin contracts"
```

## Review checkpoints

- **After Batch 0:** auth contract, MFA/AAL2 and `access_panel` gate approved.
- **After Batch 1:** HTTP/auth/repository tests green; no secret leakage.
- **After Batch 2:** tokens/elevation/surface policy approved before screen work.
- **After Batch 3:** compact/regular navigation preserves routes and permissions.
- **After Batch 4:** Dashboard, Users, Clubs and Auth use one-column mobile composition and reusable states.
- **After Batch 5:** test matrix and canonical docs reconcile; visual evidence recorded.
