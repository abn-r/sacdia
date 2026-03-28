# Flutter App — Comprehensive Data Flow Trace

**Date:** 2026-03-27
**App:** sacdia-app (Flutter 3.x, Clean Architecture, Riverpod)
**Scope:** Full analysis of router, providers, repositories, and screen-level data consumption

---

## 1. Architecture Overview

### State Management

The app uses **Riverpod** exclusively. No BLoC, no GetX, no Provider package.

Provider types in use:
- `Provider` — synchronous singletons (infrastructure, use cases)
- `FutureProvider` / `FutureProvider.autoDispose` — one-shot async fetches
- `FutureProvider.autoDispose.family` — async fetches keyed by parameter
- `AsyncNotifierProvider` / `AsyncNotifierProvider.autoDispose` — stateful async notifiers
- `NotifierProvider` / `NotifierProvider.autoDispose` — stateful sync notifiers
- `StateProvider` — simple mutable state

`autoDispose` is the default for screen-level data. Providers that must survive tab switches use `keepAlive()` (called inside `FutureProvider.autoDispose` body) or are declared without `autoDispose`.

### Navigation

**GoRouter** with `StatefulShellRoute.indexedStack`. This is the central architectural decision for data flow because:

- The shell preserves the widget tree of **all 16 branches** across tab switches.
- `autoDispose` providers inside branches are **not disposed when the user switches tabs** — they stay alive as long as the shell is alive.
- Routes outside the shell (detail views, modal routes) use `context.push()` or `context.go()` and pass IDs as path parameters.

### Data Layer

```
API (Dio HTTP client)
    |
    v
RemoteDataSource (one per feature, injected with Dio + baseUrl)
    |
    v
Repository (implements domain interface, wraps network calls in Either<Failure, T>)
    |
    v
UseCase (one per operation, calls repository)
    |
    v
Provider / Notifier (Riverpod, watches auth context and club context)
    |
    v
ConsumerWidget / ConsumerStatefulWidget (screen)
```

There is **no local database cache** (no Hive, no SQLite, no WatermelonDB in active use). The CLAUDE.md mentions Hive for offline storage but the actual code does not wire it up. Offline resilience is limited to:
- JWT + user PII stored in `flutter_secure_storage` (SecureStorage).
- `SharedPreferences` for `post_register_complete` flag.
- `AuthNotifier.build()` restores session from SecureStorage cache when the network is unreachable.

### Shared Infrastructure Providers

These are instantiated once and shared across all features:

| Provider | Type | Description |
|---|---|---|
| `dioProvider` | `Provider<Dio>` | Single Dio instance with AuthInterceptor, ErrorInterceptor, RetryInterceptor |
| `sharedPreferencesProvider` | overridden at app start | Injected from `main.dart` |
| `secureStorageProvider` | `Provider` | flutter_secure_storage wrapper |
| `networkInfoProvider` | `Provider<NetworkInfo>` | Connectivity check |
| `authNotifierProvider` | `AsyncNotifierProvider<AuthNotifier, UserEntity?>` | Global auth state — root of all context derivation |

---

## 2. Data Flow Diagram (Text)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  App Startup                                                                │
│  main() → SharedPreferences.getInstance() → Firebase.initializeApp()       │
│         → ProviderScope with sharedPreferencesProvider + isUserLoggedOut   │
└─────────────────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  AuthNotifier.build()                                                       │
│  1. Check local JWT (SecureStorage)                                         │
│  2. Call GET /auth/me                                                       │
│  3. Cache user PII to SecureStorage                                         │
│  4. Emit UserEntity? (null = unauthenticated)                               │
└─────────────────────────────────────────────────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
          ▼               ▼               ▼
   null → /login   post_reg=false   post_reg=true
                     → /post-reg     → /home/dashboard
                                          │
          ┌───────────────────────────────┼──────────────────────────┐
          │               │               │               │          │
          ▼               ▼               ▼               ▼          ▼
   clubContextProvider  membersNotifier  dashboardNotifier  profileNotifier  ...
   (derives clubId +    (watches club   (watches userId)   (watches userId)
    sectionId from       context)
    authNotifier)
          │
          └──────────── consumed by ─────────────────────────────────┐
                   activities, finances, insurance, inventory,        │
                   units, club, enrollment, evidence_folder          │
                   (all depend on clubContextProvider)               │
```

### Key Dependency Chain

```
authNotifierProvider
    └── [selectAsync activeGrant] ──► clubContextProvider
                                            ├──► membersNotifierProvider
                                            ├──► currentEnrollmentProvider
                                            ├──► currentClubSectionProvider
                                            ├──► clubActivitiesProvider (via view)
                                            ├──► financeMonthProvider (via currentClubIdProvider)
                                            ├──► membersInsuranceProvider
                                            ├──► inventoryItemsProvider (via inventoryClubIdProvider)
                                            ├──► unitsNotifierProvider
                                            └──► clubSectionsForActivityProvider
```

---

## 3. Screen-by-Screen Trace Table

### Pre-Auth Screens

| Screen | Route | Data Sources | Fetch Trigger | Shares Data With | Redundancy Notes |
|---|---|---|---|---|---|
| SplashView | `/` | `authNotifierProvider` | On widget build (auto) | Drives all routing decisions | None — pivot screen only |
| LoginView | `/login` | None — form only | N/A | Writes to `authNotifierProvider` on success | None |
| RegisterView | `/register` | None — form only | N/A | Writes to `authNotifierProvider` on success | None |
| ForgotPasswordView | `/forgot-password` | None — form only | N/A | None | None |
| PostRegistrationShell | `/post-registration` | `completionStatusProvider` (GET /post-registration/status) | On widget build | `currentStepProvider`, `selectedPhotoPathProvider` — scoped state | None |

---

### Main Shell (StatefulShellRoute — 16 branches, all kept alive)

#### Branch 0: Dashboard

| Screen | Route | Data Sources | Fetch Trigger | Shares Data With | Redundancy Notes |
|---|---|---|---|---|---|
| DashboardView | `/home/dashboard` | `dashboardNotifierProvider` (GET /dashboard/summary), `authNotifierProvider` (avatar only via select) | `dashboardNotifierProvider.build()` — watches `authNotifierProvider.selectAsync(user?.id)`, triggers on user ID change | None (consumes only) | **REDUNDANCY:** Dashboard summary from the API likely includes club info, member counts, upcoming activities — data that is also fetched independently by MembersView, ActivitiesListView, ClubView. No deduplication. |

#### Branch 1: Classes

| Screen | Route | Data Sources | Fetch Trigger | Shares Data With | Redundancy Notes |
|---|---|---|---|---|---|
| ClassesListView | `/home/classes` | `userClassesProvider` (GET /classes/user/{userId}), `authNotifierProvider` (for hasActiveClub check) | `userClassesProvider.build()` — watches `authNotifierProvider` for userId | `_ActiveClassDetailShell` (Branch 9) also watches `userClassesProvider` — **shared, no double fetch** | Good: the same provider instance is reused across Branch 1 and Branch 9 |
| ClassDetailWithProgressView | `/class/:classId` | `classWithProgressProvider(classId)` (GET /classes/{userId}/{classId}/progress), `authNotifierProvider` | On route push (parameter-keyed) | Invalidates self on any requirement mutation | None |

#### Branch 2: Activities

| Screen | Route | Data Sources | Fetch Trigger | Shares Data With | Redundancy Notes |
|---|---|---|---|---|---|
| ActivitiesListView | `/home/activities` | `clubContextProvider` (shared), `clubActivitiesProvider(ClubActivitiesParams)` (GET /activities/club/{clubId}), `activityTypesProvider` (GET /catalog/activity-types) | On build — resolves clubId from `clubContextProvider`, then fetches | `activityTypesProvider` is `keepAlive` — shared with CreateActivityView if both alive | **ISSUE:** `activityTypesProvider` is fetched here even though `activityTypesProvider` is also accessible from `catalogsProvider`. Both point to the same endpoint but through different call sites if the detail view also needs activity types. Activity type filter is applied locally — good design. |

#### Branch 3: Profile

| Screen | Route | Data Sources | Fetch Trigger | Shares Data With | Redundancy Notes |
|---|---|---|---|---|---|
| ProfileView | `/home/profile` | `profileNotifierProvider` (GET /users/{userId}/profile), `authNotifierProvider`, `userClassesProvider` (reused — no extra call), `userHonorsProvider` (reused — no extra call), `completionStatusProvider` | `profileNotifierProvider.build()` watches `authNotifierProvider.selectAsync(user?.id)` | `userClassesProvider` and `userHonorsProvider` are the same provider instances used in Branches 1 and 13 — **no double fetch due to StatefulShellRoute preserving them** | **ISSUE:** `userHonorsProvider` is declared WITHOUT `autoDispose` and watches `authNotifierProvider` — it stays alive globally. The ProfileView watches it, and so does HonorsCatalogView and HonorDetailView. Good deduplication, but the always-alive nature means it never frees memory even when the user logs out. Auth logout clears `authNotifierProvider` which should cascade. |

#### Branch 4: Members

| Screen | Route | Data Sources | Fetch Trigger | Shares Data With | Redundancy Notes |
|---|---|---|---|---|---|
| MembersView | `/home/members` | `membersNotifierProvider` (GET /members/club/{clubId}/{sectionId} + GET /members/club/{clubId}/{sectionId}/join-requests), `clubContextProvider`, `memberFiltersProvider`, `joinRequestFiltersProvider` | `MembersNotifier.build()` watches `clubContextProvider.future` | `filteredMembersProvider`, `filteredJoinRequestsProvider`, `pendingRequestsCountProvider`, `availableClassesProvider`, `availableRolesProvider`, `membersByClassProvider` — all derived from `membersNotifierProvider` without extra API calls | None — excellent local derivation pattern |

#### Branch 5: Club

| Screen | Route | Data Sources | Fetch Trigger | Shares Data With | Redundancy Notes |
|---|---|---|---|---|---|
| ClubView | `/home/club` | `currentClubSectionProvider` (GET /clubs/{clubId}/sections/{sectionId}), `clubContextProvider`, `currentEnrollmentProvider` (GET /enrollment/current?clubId=...&sectionId=...) | On widget build — watches both providers | `currentEnrollmentProvider` is `FutureProvider` (not autoDispose) — shared with AnnualFolderView, MonthlyReportsListView indirectly | **ISSUE:** `currentClubSectionProvider` calls `getClubSectionUseCaseProvider` which hits `/clubs/{clubId}/sections/{sectionId}`. `ClubDetailView` hits `/clubs/{clubId}` for the parent club. These are two separate endpoints returning overlapping data. |

#### Branch 6: Evidence Folder

| Screen | Route | Data Sources | Fetch Trigger | Shares Data With | Redundancy Notes |
|---|---|---|---|---|---|
| EvidenceFolderView (via `_EvidenceFolderShell`) | `/home/evidences` | `currentClubSectionProvider` (to resolve sectionId), then `evidenceFolderProvider(clubSectionId)` (GET /evidence-folder/{clubSectionId}) | Shell watches `currentClubSectionProvider`, then EvidenceFolderView watches `evidenceFolderProvider` | `EvidenceSectionNotifier` invalidates `evidenceFolderProvider` on mutations | **ISSUE:** `_EvidenceFolderShell` calls `currentClubSectionProvider` which itself calls `getClubSectionUseCaseProvider` — hitting the same `/clubs/{clubId}/sections/{sectionId}` endpoint already called by `ClubView` (Branch 5). Two API calls for identical data. |

#### Branch 7: Finances

| Screen | Route | Data Sources | Fetch Trigger | Shares Data With | Redundancy Notes |
|---|---|---|---|---|---|
| FinancesView | `/home/finances` | `currentClubIdProvider` (derived from `clubContextProvider`), `financeMonthProvider` (GET /finances/club/{clubId}?year=...&month=...), `financeSummaryProvider` (GET /finances/club/{clubId}/summary), `financeCategoriesProvider` (GET /finances/categories), `canManageFinancesProvider`, `selectedMonthProvider` | `financeMonthProvider` and `financeSummaryProvider` watch `currentClubIdProvider.future` and `selectedMonthProvider` | `TransactionFormNotifier` invalidates both on mutation | **ISSUE:** `currentClubIdProvider` re-derives `clubId` from `clubContextProvider` — this is a thin wrapper but creates an extra future chain. Minor. |

#### Branch 8: Units

| Screen | Route | Data Sources | Fetch Trigger | Shares Data With | Redundancy Notes |
|---|---|---|---|---|---|
| UnitsListView | `/home/units` | `unitsNotifierProvider` (GET /clubs/{clubId}/units), `clubContextProvider` | `UnitsNotifier.build()` calls `_loadUnits()` which reads `clubContextProvider.future` | Unit detail is loaded lazily on `selectUnit()` call (GET /clubs/{clubId}/units/{unitId}) if members not pre-loaded | None — good lazy loading |

#### Branch 9: Grouped Class (Active Class Detail)

| Screen | Route | Data Sources | Fetch Trigger | Shares Data With | Redundancy Notes |
|---|---|---|---|---|---|
| _ActiveClassDetailShell → ClassDetailWithProgressView | `/home/grouped-class` | `userClassesProvider` (reused), then `classWithProgressProvider(classId)` | Watches `userClassesProvider`, picks `classes.first.id` | **Shares `userClassesProvider` with Branch 1** — zero double fetches | Good pattern. However, always showing `classes.first` means no navigation to other enrolled classes from this branch. |

#### Branch 10: Insurance

| Screen | Route | Data Sources | Fetch Trigger | Shares Data With | Redundancy Notes |
|---|---|---|---|---|---|
| InsuranceView | `/home/insurance` | `membersInsuranceProvider` (GET /insurance/club/{clubId}/{sectionId}), `clubContextProvider`, `canManageInsuranceProvider`, `expiringInsuranceProvider` (GET /insurance/expiring?days=30), `insuranceFiltersProvider` | On build — `membersInsuranceProvider` watches `clubContextProvider.future` | `filteredMembersInsuranceProvider` and `insuranceSummaryProvider` derived locally | **ISSUE:** `expiringInsuranceProvider` also watches `clubContextProvider.future` only to trigger reactivity — it doesn't use clubId in the request. This means the endpoint `/insurance/expiring` is called AND `/insurance/club/{clubId}/{sectionId}` is called — two separate API calls whose data partially overlaps (expiring members are a subset of the full member list). The expiring list could be derived locally from `membersInsuranceProvider`. |

#### Branch 11: Inventory

| Screen | Route | Data Sources | Fetch Trigger | Shares Data With | Redundancy Notes |
|---|---|---|---|---|---|
| InventoryView | `/home/inventory` | `inventoryClubIdProvider` (derives clubId), `inventoryItemsProvider` (GET /inventory/{clubId}), `inventoryCategoriesProvider` (GET /inventory/categories), `canManageInventoryProvider`, `inventoryFiltersProvider` | On build — `inventoryItemsProvider` watches `inventoryClubIdProvider.future` | `filteredInventoryItemsProvider` and `inventorySummaryProvider` derived locally | `inventoryClubIdProvider` is a thin wrapper around `clubContextProvider` — same minor redundancy as `currentClubIdProvider` in finances. |

#### Branch 12: Resources

| Screen | Route | Data Sources | Fetch Trigger | Shares Data With | Redundancy Notes |
|---|---|---|---|---|---|
| ResourcesView | `/home/resources` | `resourcesListNotifierProvider` (paginated GET /resources with filters), `resourceCategoriesProvider` (GET /resources/categories), filter state providers | `ResourcesListNotifier.build()` calls `loadFirstPage()` via `Future.microtask`. Watches filter state — rebuilds and reloads on filter change | `signedUrlNotifierProvider` is ephemeral (autoDispose) per download action | None |

#### Branch 13: Honors

| Screen | Route | Data Sources | Fetch Trigger | Shares Data With | Redundancy Notes |
|---|---|---|---|---|---|
| HonorsCatalogView | `/home/honors` | `honorCategoriesProvider` (GET /honors/categories), `honorsWithStatusProvider` (derived), `filteredHonorsProvider` (GET /honors?categoryId=...), `userHonorsProvider` (GET /honors/user/{userId}), `userHonorStatsProvider` (GET /honors/stats/{userId}), `searchQueryProvider`, `selectedCategoryProvider` | On build — all providers initialize | `userHonorsProvider` is **non-autoDispose** and shared with ProfileView (Branch 3) and HonorDetailView | **ISSUE 1:** `filteredHonorsProvider` fetches from the API on every category change. Since the full list is already loaded on first visit with no category filter, subsequent category changes re-fetch the server instead of filtering locally. The design comment in the code says `activityTypeId` is intentionally excluded from activity family keys for local filtering — but honors uses a DIFFERENT pattern and actually re-fetches. **ISSUE 2:** `userHonorStatsProvider` and `userHonorsProvider` are two separate API calls that likely return overlapping data (stats are derivable from the user honors list). |

#### Branch 14: Certifications

| Screen | Route | Data Sources | Fetch Trigger | Shares Data With | Redundancy Notes |
|---|---|---|---|---|---|
| CertificationsListView | `/home/certifications` | `certificationsProvider` (GET /certifications), `userCertificationsProvider` (GET /certifications/user/{userId}) | On build | None shared outside this feature | None |

#### Branch 15: Camporees

| Screen | Route | Data Sources | Fetch Trigger | Shares Data With | Redundancy Notes |
|---|---|---|---|---|---|
| CamporeesListView | `/home/camporees` | `camporeesProvider` (GET /camporees?active=true) | On build | None shared outside this feature | None |

---

### Routes Outside the Shell (Push/Navigate)

| Screen | Route | Data Sources | Fetch Trigger | Shares Data With | Redundancy Notes |
|---|---|---|---|---|---|
| MedicalInfoView | `/home/medical-info` | `profileNotifierProvider` (reused — already alive from ProfileView) | N/A — consumes live provider | ProfileView | None |
| ClubDetailView | `/club/:clubId` | `clubInfoProvider(clubId)` (GET /clubs/{clubId}), `canEditClubProvider`, `currentClubSectionProvider` | On route push | None shared; `currentClubSectionProvider` potentially already alive | **ISSUE:** `currentClubSectionProvider` is also alive in `_EvidenceFolderShell` (Branch 6). ClubDetailView watches it separately — Riverpod deduplicates since it's the same provider instance, so no double API call. But `clubInfoProvider` (parent club) and `currentClubSectionProvider` (section detail) could potentially return from a single endpoint. |
| ClassDetailWithProgressView | `/class/:classId` | `classWithProgressProvider(classId)` (GET /classes/{userId}/{classId}/progress) | On route push with classId | Invalidates on `RequirementNotifier` mutations | `userClassesProvider` is NOT re-fetched. Good. |
| HonorDetailView | `/honor/:honorId` | `honorsProvider(GetHonorsParams())` (GET /honors — full list) if `initialHonor` is null; `userHonorForHonorProvider(honorId)` (derived from `userHonorsProvider`) | On route push | `userHonorsProvider` reused from catalog | **ISSUE:** When navigating from HonorsCatalogView (which already has the honor data), `initialHonor` is `null` in the current route construction — the router does NOT pass the honor object. So HonorDetailView fetches the **entire honors list** again (`honorsProvider(GetHonorsParams())`) just to find one item by ID. This is a significant redundant fetch. |
| HonorEvidenceView | `/honor/:honorId/evidence/:userHonorId` | `userHonorForHonorProvider(honorId)` (derived from `userHonorsProvider`), `honorRequirementsProvider(honorId)` (GET /honors/{honorId}/requirements) | On route push | `userHonorsProvider` reused | None beyond HonorDetailView's issue |
| HonorRequirementsView | `/honor/:honorId/requirements/:userHonorId` | `honorRequirementsProvider(honorId)` (GET /honors/{honorId}/requirements), `userHonorProgressProvider(params)` (GET /honors/progress/{userId}/{honorId}), `authNotifierProvider` | On route push | `honorRequirementsProvider` shared with HonorEvidenceView if both alive | `RequirementProgressNotifier` invalidates `userHonorProgressProvider` on toggle |
| HonorCompletionView | `/honor/:honorId/completion/:userHonorId` | `userHonorForHonorProvider(honorId)` (derived from `userHonorsProvider`) | On route push | `userHonorsProvider` reused | None |
| CertificationDetailView | `/certification/:certificationId` | `certificationDetailProvider(certificationId)` (GET /certifications/{id}), `userCertificationsProvider` (reused) | On route push | `userCertificationsProvider` potentially alive from CertificationsListView | **ISSUE:** `certificationDetailProvider` fetches full detail. `certificationsProvider` (list) already loaded with summary data. If the list response includes all fields, this is a redundant call. Depends on API payload. |
| CertificationProgressView | `/certification/:certificationId/progress/:enrollmentId` | `certificationProgressProvider(certificationId)` (GET /certifications/progress/{userId}/{certificationId}), `authNotifierProvider` | On route push | `SectionProgressNotifier` invalidates `certificationProgressProvider` and `userCertificationsProvider` | None |
| InvestiturePendingListView | `/investiture/pending` | `pendingInvestituresProvider` (GET /investiture/pending) | On route push | None shared | None |
| InvestitureHistoryView | `/investiture/enrollment/:enrollmentId/history` | `investitureHistoryProvider(enrollmentId)` (GET /investiture/enrollment/{enrollmentId}/history) | On route push | None shared | None |
| CamporeeDetailView | `/camporee/:camporeeId` | `camporeeDetailProvider(camporeeId)` (GET /camporees/{id}) | On route push | `camporeesProvider` (list) is NOT reused — separate fetch | **ISSUE:** `camporeesProvider` fetches the list and `camporeeDetailProvider` fetches the same entity again. If the list response includes all fields needed for the detail view, this is a redundant call. |
| CamporeeMembersView | `/camporee/:camporeeId/members` | `camporeeMembersProvider(camporeeId)` (GET /camporees/{id}/members) — camporee name passed as query param | On route push | None | None |
| CamporeeRegisterMemberView | `/camporee/:camporeeId/register` | `membersNotifierProvider` (reused — alive from Branch 4), `authNotifierProvider` | On route push | `CamporeeRegistrationNotifier` invalidates `camporeeMembersProvider` and `camporeeDetailProvider` on success | **ISSUE:** This view watches `membersNotifierProvider` to get the member list for the enrollment form. If the user navigated here without having visited MembersView (Branch 4), `membersNotifierProvider` is not yet populated — Riverpod will trigger its build and fetch the members list. This is a cross-feature dependency that the camporees feature has on the members feature. |
| CamporeePaymentsView | `/camporee/:camporeeId/member/:memberId/payments` | `camporeeMemberPaymentsProvider(params)` (GET /camporees/{id}/members/{userId}/payments) — memberName passed as query param | On route push | `CreateCamporeePaymentNotifier` invalidates both payment providers | None |
| CamporeeEnrollClubView | `/camporee/:camporeeId/enroll-club` | `currentClubSectionProvider` (reused), catalog providers potentially | On route push | `currentClubSectionProvider` potentially already alive | None |
| AnnualFolderView | `/annual-folder/:enrollmentId` | `annualFolderByEnrollmentProvider(enrollmentId)` (GET /annual-folders/enrollment/{enrollmentId}) | On route push | None | None |
| MonthlyReportsListView | `/monthly-reports/:enrollmentId` | `monthlyReportsByEnrollmentProvider(enrollmentId)` (GET /monthly-reports/enrollment/{enrollmentId}) | On route push | None | None |
| MonthlyReportDetailView | `/monthly-report/:reportId` | `monthlyReportDetailProvider(reportId)` (GET /monthly-reports/{reportId}), `monthlyReportPdfUrlProvider(reportId)` (GET /monthly-reports/{reportId}/pdf-url) | On route push | None | **ISSUE:** Detail AND PDF URL are two separate API calls. If the PDF URL is included in the detail response, this could be merged. |
| TransferRequestsView | `/transfers` | `myTransferRequestsProvider` (GET /transfers/my) | On route push | None | None |
| TransferRequestDetailView | `/transfer/:requestId` | `transferRequestDetailProvider(requestId)` (GET /transfers/{requestId}) | On route push | None | **ISSUE:** `myTransferRequestsProvider` already has the list. If the detail endpoint returns the same fields as the list item, this is a redundant fetch. |
| RoleAssignmentsView | `/role-assignments` | `roleAssignmentsProvider` (GET /role-assignments) | On route push | None | None |

---

## 4. Global / Cross-Cutting Providers

These providers are consumed by multiple features and are worth treating as shared infrastructure:

| Provider | Declared In | Scope | Consumed By | Notes |
|---|---|---|---|---|
| `authNotifierProvider` | `auth_providers.dart` | Global (no autoDispose) | Every feature that needs userId or authorization | Root of all context. Auth changes cascade everywhere. |
| `clubContextProvider` | `members_providers.dart` | Global (`FutureProvider`, no autoDispose) | activities, club, enrollment, evidence_folder, finances, insurance, inventory, units, club_sections_for_activity | This is the **single source of truth** for clubId/sectionId. Correctly placed in members_providers.dart even though it's used everywhere. |
| `userHonorsProvider` | `honors_providers.dart` | Global (no autoDispose) | honors_catalog_view, honor_detail_view, profile_view | Intentionally kept alive to avoid 429 rate limit on re-navigation. |
| `userClassesProvider` | `classes_providers.dart` | `autoDispose` + `keepAlive()` via `ref.keepAlive()` — NO, actually just `autoDispose` no keepAlive | classes_list_view, _active_class_detail_shell, profile_view (widget that watches it) | Since it is inside `StatefulShellRoute`, it lives as long as the shell is alive. |
| `membersNotifierProvider` | `members_providers.dart` | Global (no autoDispose) | members_view, camporee_register_member_view | Members list is fetched once and reused. |
| `currentEnrollmentProvider` | `enrollment_providers.dart` | Global (`FutureProvider`, no autoDispose) | club_view, annual_folder (context-driven), profile_view enrollment card | Not explicitly autoDispose, so survives tab switches. |
| `currentClubSectionProvider` | `club_providers.dart` | `autoDispose` | _evidence_folder_shell, club_detail_view, camporee_enroll_club_view | **autoDispose means it CAN be re-fetched if all listeners are gone and then a new one attaches.** Since `_EvidenceFolderShell` is inside the StatefulShellRoute, it stays alive, so this provider stays alive as long as Branch 6 is alive. |
| `clubTypesProvider` | `catalogs_provider.dart` | `autoDispose` + `keepAlive()` | post_registration, possibly activity creation | keepAlive prevents disposal after first fetch |
| `activityTypesProvider` | `catalogs_provider.dart` | `autoDispose` + `keepAlive()` | activities_list_view, create_activity_view | keepAlive prevents re-fetch on filter changes |
| `currentEcclesiasticalYearProvider` | `catalogs_provider.dart` | `autoDispose` + `keepAlive()` | classes_providers.dart (aliased as `currentEccYearProvider`) | keepAlive correct |
| `dioProvider` | `dio_provider.dart` | Global (no autoDispose) | Every remote data source | Single Dio instance with interceptors |

---

## 5. Findings — Optimization Opportunities

### FINDING 1: HonorDetailView Fetches Full Honors List on Every Open

**Severity: High**

When navigating to `/honor/:honorId`, the router creates `HonorDetailView(honorId: honorId)` with `initialHonor: null`. The view then watches `honorsProvider(const GetHonorsParams())` which issues `GET /honors` — the full catalog — just to find one item by ID.

The honors catalog list is already in memory in `filteredHonorsProvider` / `honorsWithStatusProvider` from the HonorsCatalogView (Branch 13). The fix is to pass the `Honor` object from the catalog card to `HonorDetailView` as `initialHonor` at the call site in `HonorsCatalogView`. The route construction in the router already supports this (`initialHonor` parameter exists on the widget), but the router does not pass it because GoRouter only passes serializable path/query parameters.

**Options:**
- Pass the `Honor` object via `extra` in `context.push()` and read it from `state.extra` in the router (best option for navigation from within the app).
- Add a `FutureProvider.autoDispose.family<Honor, int>` that fetches a single honor by ID (new endpoint needed), only triggered when `initialHonor` is null.
- Store the last-viewed honor in a `StateProvider` as a temporary cache.

---

### FINDING 2: `userHonorStatsProvider` Duplicates Data from `userHonorsProvider`

**Severity: Medium**

`HonorsCatalogView` watches both `userHonorsProvider` (GET /honors/user/{userId}) and `userHonorStatsProvider` (GET /honors/stats/{userId}). The stats (completed count, in-progress count, total) are trivially derivable from the user honors list on the client side.

**Recommendation:** Remove `userHonorStatsProvider` and derive stats locally from `userHonorsProvider` using a `Provider` that computes them synchronously.

---

### FINDING 3: `currentClubSectionProvider` Called in Multiple Branches (Double Network Fetch Possible)

**Severity: Medium**

`currentClubSectionProvider` (GET /clubs/{clubId}/sections/{sectionId}) is watched by:
- `_EvidenceFolderShell` (Branch 6)
- `ClubDetailView` (route outside shell)
- `CamporeeEnrollClubView`

Since `currentClubSectionProvider` is `autoDispose`, it COULD be disposed and re-fetched between listeners. In practice, the StatefulShellRoute keeps Branch 6 alive, so it likely remains cached. However, if the user navigates to `ClubDetailView` from outside the shell while Branch 6 has not been visited, a second fetch will occur.

**Recommendation:** Remove `autoDispose` from `currentClubSectionProvider` or call `ref.keepAlive()` inside its body to ensure it stays alive for the session lifetime, similar to how `clubContextProvider` is handled (non-autoDispose).

---

### FINDING 4: `expiringInsuranceProvider` Overlaps with `membersInsuranceProvider`

**Severity: Low-Medium**

`InsuranceView` fetches both:
- `membersInsuranceProvider` — all insurance records for club section
- `expiringInsuranceProvider` — insurance records expiring in 30 days (separate endpoint)

The expiring records are a subset of all records. The client already has the full list; the "expiring" logic could be a local filter:

```dart
final expiringInsuranceProvider = Provider.autoDispose<List<MemberInsurance>>((ref) {
  final allAsync = ref.watch(membersInsuranceProvider);
  final all = allAsync.valueOrNull ?? [];
  final cutoff = DateTime.now().add(const Duration(days: 30));
  return all.where((i) => i.endDate != null && i.endDate!.isBefore(cutoff)).toList();
});
```

This eliminates the extra API call.

---

### FINDING 5: CamporeeDetail vs CamporeeList — Double Fetch

**Severity: Low-Medium**

`CamporeesListView` fetches `camporeesProvider` (all active camporees). Navigating to `CamporeeDetailView` fetches `camporeeDetailProvider(camporeeId)` — the same camporee again from a different endpoint.

If the list endpoint returns the same fields as the detail endpoint, this is wasted. The fix depends on the API: if the list returns full objects, `camporeeDetailProvider` can be seeded from the list cache. If the detail endpoint returns additional fields (e.g., enrolled clubs, payment summary), the separate call is justified.

**Recommendation:** Add a `FutureProvider.autoDispose.family` that first checks if the camporee is already in `camporeesProvider` before hitting the network (similar to the `initialHonor` pattern).

---

### FINDING 6: CertificationDetail vs CertificationList — Potential Double Fetch

**Severity: Low**

Same pattern as camporees. `CertificationsListView` loads `certificationsProvider`. `CertificationDetailView` loads `certificationDetailProvider`. Verify whether the list endpoint returns all necessary fields for the detail screen.

---

### FINDING 7: Transfer Request Detail vs List — Double Fetch

**Severity: Low**

`TransferRequestsView` loads `myTransferRequestsProvider` (list). `TransferRequestDetailView` loads `transferRequestDetailProvider(requestId)`. The list already contains the transfer object. The detail provider could check the list cache first.

---

### FINDING 8: `CamporeeRegisterMemberView` Has Hidden Cross-Feature Dependency

**Severity: Medium (architectural)**

`CamporeeRegisterMemberView` imports and watches `membersNotifierProvider` from the members feature to populate a member picker. This means:
- Navigating directly to `/camporee/:id/register` (e.g., via deep link) will trigger a full members list fetch from `membersNotifierProvider` even if the user has not visited MembersView.
- This creates an implicit boot-time dependency between the camporees feature and the members feature.

**Recommendation:** The member picker in camporee registration should either use a dedicated `memberSearchProvider` scoped to that screen, or explicitly document the dependency on `membersNotifierProvider` being pre-populated.

---

### FINDING 9: `MonthlyReportDetailView` Makes Two Separate Calls for Detail + PDF URL

**Severity: Low**

`monthlyReportDetailProvider` and `monthlyReportPdfUrlProvider` fire two sequential GET requests when loading a report detail. If the PDF URL is included in the detail response payload, the second call is redundant. Verify the API response shape.

---

### FINDING 10: `filteredHonorsProvider` Re-Fetches API on Category Change

**Severity: Medium**

The activities feature correctly handles filtering: `clubActivitiesProvider` fetches all activities, and `activityTypeId` is excluded from the family key so filter chip changes do NOT trigger new network requests — filtering is local.

The honors feature uses a DIFFERENT approach: `filteredHonorsProvider` uses `categoryId` as a parameter to `getHonors(GetHonorsParams(categoryId: categoryId))` — this means changing the selected category triggers a NEW API call (`GET /honors?categoryId=X`).

Since the full honors catalog is already fetched on first load (when `selectedCategoryProvider` is null), all category-filtered results are subsets of the data already in memory. The API call is wasted.

**Recommendation:** Adopt the same pattern as activities. Fetch all honors once (no category filter), store in a `keepAlive` provider, and derive the filtered view locally via a `Provider` that filters in memory.

---

### FINDING 11: `profileNotifierProvider` and `authNotifierProvider` Contain Overlapping User Data

**Severity: Low (design note)**

`authNotifierProvider` stores `UserEntity` (id, email, name, avatar, metadata, authorization grants). `profileNotifierProvider` fetches `UserDetail` (likely a superset with birthdate, phone, address, medical info, etc.) from a separate endpoint.

This is generally correct — they serve different purposes. However, the name/avatar shown in `ProfileView` comes from both providers simultaneously (`authUser` for avatar from the auth state, `profileState` for the rest). Ensure these two sources are kept in sync on profile updates (`profileNotifierProvider` updates do NOT invalidate `authNotifierProvider`, meaning the avatar shown in the top-of-profile may lag after an update until the next `/auth/me` call).

---

## 6. Provider Lifecycle Summary

| Provider | autoDispose | keepAlive | Lifecycle |
|---|---|---|---|
| `authNotifierProvider` | No | — | Global, entire app lifetime |
| `clubContextProvider` | No | — | Global, survives tab switches |
| `membersNotifierProvider` | No | — | Global, survives tab switches |
| `currentEnrollmentProvider` | No | — | Global, survives tab switches |
| `dashboardNotifierProvider` | No | — | Global, rebuilds on userId change |
| `profileNotifierProvider` | No | — | Global, rebuilds on userId change |
| `userHonorsProvider` | No | — | Global, intentionally kept alive |
| `unitsNotifierProvider` | No | — | Global |
| `userClassesProvider` | Yes | No keepAlive | Lives while Branch 1 or Branch 9 is in the widget tree (preserved by StatefulShellRoute) |
| `clubActivitiesProvider` | Yes | `ref.keepAlive()` called | Lives after first fetch even if branch is "hidden" |
| `activityTypesProvider` | Yes | `ref.keepAlive()` called | Lives after first fetch |
| `clubTypesProvider` | Yes | `ref.keepAlive()` called | Lives after first fetch |
| `honorCategoriesProvider` | Yes | No | Lives while HonorsCatalogView is in tree |
| `filteredHonorsProvider` | Yes | No | Re-fetched on category change (see Finding 10) |
| `currentClubSectionProvider` | Yes | No | Lives while any listener is alive; autoDispose risk (see Finding 3) |
| `certificationDetailProvider` | Yes | No | Per route push, disposed on pop |
| `camporeeDetailProvider` | Yes | No | Per route push |
| `classWithProgressProvider` | Yes | No | Per route push |

---

## 7. Relevant Files

```
lib/main.dart                                      — App entry, ProviderScope, Firebase init
lib/core/config/router.dart                        — GoRouter, StatefulShellRoute, redirect logic
lib/core/config/route_names.dart                   — All route path constants
lib/core/network/dio_client.dart                   — Dio + interceptors (Auth, Error, Retry)
lib/providers/dio_provider.dart                    — Global Dio provider
lib/providers/catalogs_provider.dart               — Catalog providers (club types, activity types, etc.)
lib/providers/storage_provider.dart                — SecureStorage + SharedPreferences providers
lib/features/auth/presentation/providers/auth_providers.dart     — AuthNotifier, clubContextProvider
lib/features/members/presentation/providers/members_providers.dart — clubContextProvider (source of truth)
lib/features/dashboard/presentation/providers/dashboard_providers.dart
lib/features/classes/presentation/providers/classes_providers.dart
lib/features/activities/presentation/providers/activities_providers.dart
lib/features/honors/presentation/providers/honors_providers.dart
lib/features/certifications/presentation/providers/certifications_providers.dart
lib/features/camporees/presentation/providers/camporees_providers.dart
lib/features/club/presentation/providers/club_providers.dart
lib/features/enrollment/presentation/providers/enrollment_providers.dart
lib/features/evidence_folder/presentation/providers/evidence_folder_providers.dart
lib/features/finances/presentation/providers/finances_providers.dart
lib/features/insurance/presentation/providers/insurance_providers.dart
lib/features/inventory/presentation/providers/inventory_providers.dart
lib/features/units/presentation/providers/units_providers.dart
lib/features/resources/presentation/providers/resources_providers.dart
lib/features/transfers/presentation/providers/transfer_providers.dart
lib/features/investiture/presentation/providers/investiture_providers.dart
lib/features/annual_folders/presentation/providers/annual_folders_providers.dart
lib/features/monthly_reports/presentation/providers/monthly_reports_providers.dart
lib/features/validation/presentation/providers/validation_providers.dart
lib/features/role_assignments/presentation/providers/role_assignments_providers.dart
lib/features/profile/presentation/providers/profile_providers.dart
lib/features/post_registration/presentation/providers/post_registration_providers.dart
```
