# App Bootstrap Data Gate — Design Spec

**Date**: 2026-04-09
**Status**: Approved
**Scope**: sacdia-app (Flutter)

## Problem

On cold start, the app sometimes fails to load permissions, roles, and menu filtering correctly. The user sees all menu items unfiltered, the app defaults to a basic "user" profile, club enrollment status doesn't load, and roles are missing. A hot restart fixes it because all providers rebuild from scratch with cached data immediately available.

### Root Cause

The GoRouter redirect only waits for `AuthNotifier.build()` to complete. Once auth resolves with a non-null user, the router immediately navigates to `/home/dashboard` — without guaranteeing that the `UserEntity.authorization` field contains valid `effectivePermissions` and `resolvedRoleNames`. Downstream providers (`clubContextProvider`, `currentEnrollmentProvider`, menu filtering in `_MainShell`) that depend on authorization data may evaluate before it's fully propagated, producing null/empty results.

### Why Hot Restart Fixes It

Hot restart doesn't clear SecureStorage. Cached PII and active assignment data are immediately available. Providers rebuild from scratch and the timing window where authorization is null effectively disappears because cached data is synchronous.

## Solution: AppBootstrapNotifier

A centralized `AsyncNotifier` that runs after auth resolves, validates that critical data is present, and gates navigation until validation passes.

### Design Principles

- **Auth stays focused on auth** — AppBootstrapNotifier handles post-auth validation, not AuthNotifier
- **Lazy providers stay lazy** — Dashboard summary, enrollment, profile continue to load when their widgets render. The bootstrap only guarantees that authorization (permissions + roles) is ready
- **Splash stays dumb** — The splash widget reads bootstrap state and renders accordingly, no business logic
- **Follows existing patterns** — AsyncNotifier, `selectAsync`, `ref.invalidate`, same as the rest of the codebase

## Architecture

### New: `AppBootstrapState`

```dart
sealed class AppBootstrapState {
  const AppBootstrapState();
}

class AppBootstrapReady extends AppBootstrapState {
  const AppBootstrapReady();
}

class AppBootstrapError extends AppBootstrapState {
  final String message;
  final int attemptCount;
  const AppBootstrapError(this.message, this.attemptCount);
}

class AppBootstrapUnauthenticated extends AppBootstrapState {
  const AppBootstrapUnauthenticated();
}
```

Note: There is no `AppBootstrapLoading` subclass. The loading state is represented by `AsyncLoading` from Riverpod's `AsyncValue<AppBootstrapState>` wrapper, which is the default state while `build()` is executing.

### New: `AppBootstrapNotifier`

**Location**: `lib/core/providers/app_bootstrap_provider.dart`

**State**: `AsyncValue<AppBootstrapState>`

**`build()` logic**:

1. `ref.listen(authNotifierProvider, ...)` — registers listener for auth changes (login, logout, context switch). Guarded by `_inRetryLoop` flag to prevent self-cancellation during retries.
2. `await ref.read(authNotifierProvider.future)` — waits for auth to resolve (uses `ref.read`, NOT `ref.watch`, to avoid Riverpod cancelling `build()` when auth is invalidated during retries)
3. If user is `null` → return `AppBootstrapUnauthenticated`
4. Validate:
   - `user.authorization != null`
   - `user.authorization.effectivePermissions.isNotEmpty`
   - `user.authorization.resolvedRoleNames.isNotEmpty`
5. If validation passes → return `AppBootstrapReady`
6. If validation fails → enter internal retry loop (see Retry Strategy below)

**`retry()` method**: Manual retry for the splash button. Sets state to `AsyncLoading`, invalidates auth, re-reads, validates. If fails → nuclear reset.

### Retry Strategy

**Implementation note**: The retry uses `ref.listen` + `ref.read` (NOT `ref.watch`). Using `ref.watch` in `build()` combined with `ref.invalidate` inside a retry loop causes Riverpod to cancel the running `build()` and restart it, breaking the loop. The `ref.listen` approach provides auth reactivity (for login/logout/context-switch) while allowing the retry loop to run uninterrupted.

**Auto-retry loop (inside `build()`):**

The retry is an actual `for` loop inside `build()`. A `_inRetryLoop` guard flag prevents the `ref.listen` callback from calling `ref.invalidateSelf()` during the loop.

| Attempt | Delay | Action |
|---------|-------|--------|
| 1 | 0ms | `ref.invalidate(authNotifierProvider)` → `ref.read(authNotifierProvider.future)` → validate |
| 2 | 1000ms | Same |
| 3 | 2000ms | Same |

If all 3 fail → return `AppBootstrapError(message, 3)` → splash shows retry button.

**Manual retry (user taps button):**

`retry()` is a separate method (not `build()`). It:
1. Sets `state = AsyncLoading()` (splash shows loading indicator)
2. Sets `_inRetryLoop = true` (guard)
3. `ref.invalidate(authNotifierProvider)` → `ref.read(authNotifierProvider.future)` → validate
4. If valid → `state = AsyncData(AppBootstrapReady())`
5. If invalid → nuclear reset → `state = AsyncData(AppBootstrapUnauthenticated())`

**Nuclear reset:**
- Clear SecureStorage (token, PII cache, active grant)
- Clear SharedPreferences (post_register_complete)
- Invalidate all downstream providers (same list as `logout_cleanup.dart`)
- Invalidate authNotifierProvider itself

**What is NOT retried:**
- 401 from `/auth/me` → AuthNotifier returns `null` → bootstrap returns `AppBootstrapUnauthenticated` immediately, no retry
- Explicit logout → bypass bootstrap entirely

### Auth Reactivity

The `ref.listen(authNotifierProvider, ...)` callback fires when auth state changes externally (login, logout, context switch). When it fires and `_inRetryLoop` is false, it resets `_autoRetryCount` to 0 and calls `ref.invalidateSelf()` to re-run `build()`. This ensures the bootstrap re-validates after any auth change.

## Router Changes

**File**: `lib/core/config/router.dart`

### Updated Redirect Logic

```
1. authState.isLoading == true
   → stay on '/' (splash)
   Exception: '/auth/callback' stays on callback

2. bootstrapState is AsyncLoading
   → stay on '/' (splash)

3. bootstrapState.value is AppBootstrapError
   → stay on '/' (splash shows error + retry button)

4. user == null OR bootstrapState.value is AppBootstrapUnauthenticated
   → redirect to '/login'

5. user.postRegisterComplete == false
   → redirect to '/post-registration'

6. bootstrapState.value is AppBootstrapReady
   → redirect to '/home/dashboard'
```

### New Listener

Add `ref.listen(appBootstrapProvider, ...)` alongside the existing `ref.listen(authNotifierProvider, ...)` to call `router.refresh()` when bootstrap state changes. This ensures the redirect re-evaluates when bootstrap transitions from loading → ready or loading → error.

## Splash View Changes

**File**: `lib/features/auth/presentation/views/splash_view.dart`

### State → UI Mapping

| Bootstrap State | UI |
|-----------------|-----|
| `AsyncLoading` | Current UI unchanged: logo animation + SacLoading indicator |
| `AsyncData(AppBootstrapReady)` | Not visible — router already redirected |
| `AsyncData(AppBootstrapUnauthenticated)` | Not visible — router already redirected to login |
| `AsyncData(AppBootstrapError)` | Logo (static) + error icon + message + "Reintentar" button |
| `AsyncError` | Same as AppBootstrapError — unexpected failure, show retry |

### Error UI

Replace the `SacLoading` widget with:
- Error icon (lucide `AlertCircle` or similar from the existing icon set)
- Text: "No pudimos cargar tus datos" (or similar short message)
- `ElevatedButton` "Reintentar" → calls `ref.read(appBootstrapProvider.notifier).retry()`

When retry is tapped, the UI switches back to the loading state (SacLoading) while the bootstrap re-executes.

### What Doesn't Change

- Logo animation (fade + scale, 600ms) stays identical
- Layout structure (Stack, centered Column, Positioned bottom text) unchanged
- "by Sarza Roja" footer stays
- No progress bar, no percentage — loading remains indeterminate

## Logout Cleanup

**File**: `lib/features/auth/presentation/providers/logout_cleanup.dart`

Add `ref.invalidate(appBootstrapProvider)` to the existing `clearUserStateOnLogout()` function, alongside the other invalidations. This ensures bootstrap state resets on logout.

## Files Changed

| File | Change Type | Description |
|------|-------------|-------------|
| `lib/core/providers/app_bootstrap_provider.dart` | **NEW** | AppBootstrapNotifier, AppBootstrapState, provider definition |
| `lib/core/config/router.dart` | MODIFY | Add bootstrap state to redirect logic + ref.listen |
| `lib/features/auth/presentation/views/splash_view.dart` | MODIFY | Watch bootstrap state, show error/retry UI |
| `lib/features/auth/presentation/providers/logout_cleanup.dart` | MODIFY | Add appBootstrapProvider to invalidation list |

## What Is NOT In Scope

- **Offline mode**: No cache validation or offline fallback. If there's no internet, the retry loop handles it. Offline-first is a future iteration.
- **Eager loading of dashboard/enrollment**: These stay lazy. The bootstrap only gates on auth + permissions + roles.
- **Splash animation changes**: No new animations, progress bars, or visual redesign.
- **Cache freshness strategy**: No TTL, no stale-while-revalidate. The server response is the source of truth on every cold start.
- **New API endpoints**: The bootstrap uses the existing `/auth/me` response. No new backend work required.

## End-to-End Flows

### Happy Path (~700ms-1.2s on splash)

```
main() → Firebase + SharedPreferences init
  → AuthNotifier.build() → GET /auth/me → user with authorization
  → AppBootstrapNotifier.build() → validate permissions ✓ roles ✓ → ready
  → Router redirect → /home/dashboard
  → Dashboard renders, lazy providers activate with authorization guaranteed
```

### Server Returns Incomplete Data (~3.5s + user action)

```
AuthNotifier.build() → GET /auth/me → user but authorization empty
  → AppBootstrapNotifier.build() → validate fails
  → Retry 1 (0ms) → invalidate auth → re-fetch → still empty
  → Retry 2 (1s) → re-fetch → still empty
  → Retry 3 (2s) → re-fetch → still empty
  → State = error → Splash shows retry button
  → User taps Reintentar → Attempt 4 → still empty
  → Nuclear reset → clear all caches → unauthenticated → /login
```

### Invalid Token

```
AuthNotifier.build() → GET /auth/me → 401
  → state = AsyncData(null)
  → AppBootstrapNotifier.build() → user == null → unauthenticated
  → Router → /login (immediate, no retry)
```

### Server Down (5xx/Timeout)

```
AuthNotifier.build() → GET /auth/me → 500 or timeout
  → Returns failure → AuthNotifier returns null (non-NetworkFailure)
  → AppBootstrapNotifier → user == null → unauthenticated → /login
```

Note: NetworkFailure with cached data follows the existing offline fallback in AuthNotifier (returns cached user). The bootstrap then validates that cached user's authorization. If cached authorization is empty, retry loop kicks in — which will fail again (still offline), eventually leading to nuclear reset → login.

## Testing Considerations

- **Unit test AppBootstrapNotifier**: Mock authNotifierProvider with various states (null user, user without authorization, user with complete authorization, user with empty permissions)
- **Unit test retry logic**: Verify attempt counter increments, backoff delays, nuclear reset triggers at attempt 4
- **Widget test splash_view**: Verify correct UI for each bootstrap state (loading, error with retry button, transition to ready)
- **Integration test router redirect**: Verify navigation decisions for each combination of auth + bootstrap states
