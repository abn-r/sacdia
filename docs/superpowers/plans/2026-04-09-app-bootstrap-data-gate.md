# App Bootstrap Data Gate — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an `AppBootstrapNotifier` that validates user authorization (permissions + roles) before allowing navigation from splash to dashboard, fixing the cold-start race condition where menu/permissions fail to load.

**Architecture:** A new `AsyncNotifier<AppBootstrapState>` sits between auth resolution and router navigation. It uses `ref.listen` for auth reactivity and `ref.read(authNotifierProvider.future)` for data access, avoiding `ref.watch` conflicts during the retry loop. The router gates on both auth AND bootstrap state before redirecting.

**Tech Stack:** Flutter, Riverpod (AsyncNotifier), GoRouter, flutter_test + mockito

**Design Spec:** `docs/superpowers/specs/2026-04-09-app-bootstrap-data-gate-design.md`

---

### Task 1: Create AppBootstrapState and AppBootstrapNotifier

**Files:**
- Create: `sacdia-app/lib/core/providers/app_bootstrap_provider.dart`

- [ ] **Step 1: Create the provider directory if needed**

Run: `mkdir -p sacdia-app/lib/core/providers`

- [ ] **Step 2: Write the complete provider file**

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';
import '../../providers/storage_provider.dart';
import '../../features/dashboard/presentation/providers/dashboard_providers.dart';
import '../../features/honors/presentation/providers/honors_providers.dart';
import '../../features/members/presentation/providers/members_providers.dart';
import '../../features/profile/presentation/providers/profile_providers.dart';
import '../../features/enrollment/presentation/providers/enrollment_providers.dart';
import '../../features/activities/presentation/providers/activities_providers.dart';
import '../../features/club/presentation/providers/club_providers.dart';

// ─── State ───────────────────────────────────────────────────────────────────

/// Sealed hierarchy for bootstrap states.
/// Loading is represented by [AsyncLoading] from Riverpod's [AsyncValue].
sealed class AppBootstrapState {
  const AppBootstrapState();
}

/// Authorization validated — safe to navigate to dashboard.
class AppBootstrapReady extends AppBootstrapState {
  const AppBootstrapReady();
}

/// Auto-retries exhausted — splash shows retry button.
class AppBootstrapError extends AppBootstrapState {
  final String message;
  final int attemptCount;
  const AppBootstrapError(this.message, this.attemptCount);
}

/// No authenticated user, or nuclear reset completed — redirect to login.
class AppBootstrapUnauthenticated extends AppBootstrapState {
  const AppBootstrapUnauthenticated();
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class AppBootstrapNotifier extends AsyncNotifier<AppBootstrapState> {
  int _autoRetryCount = 0;
  bool _inRetryLoop = false;

  static const _maxAutoRetries = 3;
  static const _tag = 'AppBootstrap';

  @override
  Future<AppBootstrapState> build() async {
    // React to external auth changes (login, logout, context switch).
    // Guard: skip during retry loop to prevent self-cancellation.
    ref.listen(authNotifierProvider, (_, __) {
      if (!_inRetryLoop) {
        _autoRetryCount = 0;
        ref.invalidateSelf();
      }
    });

    return _validateAndRetry();
  }

  Future<AppBootstrapState> _validateAndRetry() async {
    final user = await ref.read(authNotifierProvider.future);

    if (user == null) {
      _autoRetryCount = 0;
      return const AppBootstrapUnauthenticated();
    }

    if (_isValidAuthorization(user)) {
      _autoRetryCount = 0;
      return const AppBootstrapReady();
    }

    // Authorization incomplete — enter auto-retry loop.
    _inRetryLoop = true;
    try {
      for (var attempt = 1; attempt <= _maxAutoRetries; attempt++) {
        _autoRetryCount = attempt;
        final delay = Duration(seconds: attempt - 1); // 0s, 1s, 2s
        if (delay > Duration.zero) await Future.delayed(delay);

        AppLogger.d('Auto-retry $attempt/$_maxAutoRetries', tag: _tag);

        ref.invalidate(authNotifierProvider);
        final freshUser = await ref.read(authNotifierProvider.future);

        if (freshUser != null && _isValidAuthorization(freshUser)) {
          _autoRetryCount = 0;
          return const AppBootstrapReady();
        }
      }
    } finally {
      _inRetryLoop = false;
    }

    AppLogger.w('Auto-retries exhausted', tag: _tag);
    return AppBootstrapError(
      'No pudimos cargar tus permisos',
      _autoRetryCount,
    );
  }

  /// Checks that the user has non-empty permissions and roles.
  bool _isValidAuthorization(UserEntity user) {
    final auth = user.authorization;
    if (auth == null) return false;
    if (auth.effectivePermissions.isEmpty) return false;
    if (auth.resolvedRoleNames.isEmpty) return false;
    return true;
  }

  /// Manual retry triggered by splash "Reintentar" button.
  /// One attempt — if it fails, nuclear reset and redirect to login.
  Future<void> retry() async {
    AppLogger.d('Manual retry triggered', tag: _tag);
    state = const AsyncLoading();

    _inRetryLoop = true;
    try {
      ref.invalidate(authNotifierProvider);
      final user = await ref.read(authNotifierProvider.future);

      if (user != null && _isValidAuthorization(user)) {
        _autoRetryCount = 0;
        state = const AsyncData(AppBootstrapReady());
        return;
      }
    } finally {
      _inRetryLoop = false;
    }

    AppLogger.w('Manual retry failed — nuclear reset', tag: _tag);
    await _nuclearReset();
    state = const AsyncData(AppBootstrapUnauthenticated());
  }

  /// Clears all local state and invalidates every user-specific provider.
  Future<void> _nuclearReset() async {
    AppLogger.w('Clearing all user state', tag: _tag);

    final secureStorage = ref.read(secureStorageProvider);
    final prefs = ref.read(sharedPreferencesProvider);

    // Auth tokens
    await secureStorage.delete(AppConstants.tokenKey);
    await secureStorage.delete(AppConstants.refreshTokenKey);
    await secureStorage.delete(AppConstants.expiresAtKey);
    await secureStorage.delete(AppConstants.tokenTypeKey);

    // Cached PII
    await secureStorage.delete(AppConstants.cachedUserId);
    await secureStorage.delete(AppConstants.cachedUserEmail);
    await secureStorage.delete(AppConstants.cachedUserName);
    await secureStorage.delete(AppConstants.cachedUserAvatar);

    // Cached active grant
    await secureStorage.delete(AppConstants.cachedActiveAssignmentId);
    await secureStorage.delete(AppConstants.cachedActiveRoleName);
    await secureStorage.delete(AppConstants.cachedActiveClubName);
    await secureStorage.delete(AppConstants.cachedActiveClubType);
    await secureStorage.delete('cached_post_register_complete');

    // SharedPreferences
    prefs.remove('cached_post_register_complete');
    prefs.remove('user_manually_logged_out');

    // Downstream providers (same list as logout_cleanup.dart)
    ref.invalidate(dashboardNotifierProvider);
    ref.invalidate(userHonorsProvider);
    ref.invalidate(clubContextProvider);
    ref.invalidate(currentClubSectionProvider);
    ref.invalidate(profileNotifierProvider);
    ref.invalidate(currentEnrollmentProvider);
    ref.invalidate(clubActivitiesProvider);
    ref.invalidate(authNotifierProvider);
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final appBootstrapProvider =
    AsyncNotifierProvider<AppBootstrapNotifier, AppBootstrapState>(() {
  return AppBootstrapNotifier();
});
```

- [ ] **Step 3: Verify it compiles**

Run: `cd sacdia-app && flutter analyze lib/core/providers/app_bootstrap_provider.dart`
Expected: No errors (warnings about unused imports are OK at this stage).

- [ ] **Step 4: Commit**

```bash
git add sacdia-app/lib/core/providers/app_bootstrap_provider.dart
git commit -m "feat(app): add AppBootstrapNotifier for post-auth data gate"
```

---

### Task 2: Modify router redirect to include bootstrap gate

**Files:**
- Modify: `sacdia-app/lib/core/config/router.dart`

**Context:** The router's redirect callback (lines 116-175) currently only checks `authNotifierProvider`. We add bootstrap state as a second gate. The existing Phase 3 routing logic is unchanged.

- [ ] **Step 1: Add imports at top of router.dart**

After the existing auth imports (around line 62), add:

```dart
import '../providers/app_bootstrap_provider.dart';
```

- [ ] **Step 2: Add bootstrap state reading in the redirect callback**

In the redirect callback (line 116), after the existing auth state reading:

```dart
// EXISTING (keep as-is):
final authState = ref.read(authNotifierProvider);
final isLoading = authState.isLoading;
final user = authState.valueOrNull;
final isLoggedIn = user != null;
final currentPath = state.matchedLocation;
```

Add immediately after:

```dart
// NEW: Read bootstrap state
final bootstrapAsync = ref.read(appBootstrapProvider);
```

- [ ] **Step 3: Add bootstrap gate after the auth loading check**

After the existing `if (isLoading)` block (around line 140), insert a new block BEFORE the `if (currentPath == RouteNames.splash)` line:

```dart
// ── Bootstrap gate (authenticated users only) ──
if (isLoggedIn) {
  final isBootstrapLoading = bootstrapAsync.isLoading;
  final bootstrapValue = bootstrapAsync.valueOrNull;

  // Still validating permissions → stay on splash
  if (isBootstrapLoading) {
    if (currentPath == RouteNames.splash) return null;
    return RouteNames.splash;
  }

  // Retry UI shown → stay on splash
  if (bootstrapValue is AppBootstrapError) {
    if (currentPath == RouteNames.splash) return null;
    return RouteNames.splash;
  }

  // Nuclear reset happened → go to login
  if (bootstrapValue is AppBootstrapUnauthenticated) {
    return RouteNames.login;
  }

  // AppBootstrapReady → fall through to normal routing
}
```

- [ ] **Step 4: Add bootstrap listener for router.refresh()**

After the existing `ref.listen(authNotifierProvider, ...)` block (around line 866), add:

```dart
ref.listen<AsyncValue<AppBootstrapState>>(appBootstrapProvider, (_, __) {
  router.refresh();
});
```

- [ ] **Step 5: Verify compile**

Run: `cd sacdia-app && flutter analyze lib/core/config/router.dart`
Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add sacdia-app/lib/core/config/router.dart
git commit -m "feat(router): gate navigation on AppBootstrapNotifier state"
```

---

### Task 3: Modify splash view for error/retry UI

**Files:**
- Modify: `sacdia-app/lib/features/auth/presentation/views/splash_view.dart`

**Context:** The splash is currently a dumb animation widget (135 lines). We add a `ref.watch(appBootstrapProvider)` to conditionally show either the loading indicator or an error/retry widget.

- [ ] **Step 1: Add imports**

After the existing imports (line 4), add:

```dart
import '../../../../core/providers/app_bootstrap_provider.dart';
```

- [ ] **Step 2: Replace the loading indicator section**

In `build()` (around lines 108-111), replace this block:

```dart
// Loading indicator
FadeTransition(
  opacity: _fadeAnimation,
  child: const SacLoading(),
),
```

With:

```dart
// Loading indicator or error/retry
FadeTransition(
  opacity: _fadeAnimation,
  child: _buildStatusWidget(),
),
```

- [ ] **Step 3: Add the _buildStatusWidget and _buildErrorWidget methods**

Add these methods to the `_SplashViewState` class, before the `build()` method:

```dart
Widget _buildStatusWidget() {
  final bootstrapAsync = ref.watch(appBootstrapProvider);

  return bootstrapAsync.when(
    loading: () => const SacLoading(),
    error: (_, __) => _buildErrorWidget('Ocurrió un error inesperado'),
    data: (state) => switch (state) {
      AppBootstrapError(:final message) => _buildErrorWidget(message),
      _ => const SacLoading(),
    },
  );
}

Widget _buildErrorWidget(String message) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        Icons.error_outline_rounded,
        color: Theme.of(context).colorScheme.error,
        size: 40,
      ),
      const SizedBox(height: 12),
      Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.sac.textSecondary,
            ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: () =>
            ref.read(appBootstrapProvider.notifier).retry(),
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Reintentar'),
      ),
    ],
  );
}
```

- [ ] **Step 4: Verify compile**

Run: `cd sacdia-app && flutter analyze lib/features/auth/presentation/views/splash_view.dart`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add sacdia-app/lib/features/auth/presentation/views/splash_view.dart
git commit -m "feat(splash): show error/retry UI from AppBootstrapNotifier state"
```

---

### Task 4: Add bootstrap to logout cleanup

**Files:**
- Modify: `sacdia-app/lib/features/auth/presentation/providers/logout_cleanup.dart`

- [ ] **Step 1: Add import**

After the existing imports (around line 10), add:

```dart
import '../../../../core/providers/app_bootstrap_provider.dart';
```

- [ ] **Step 2: Add invalidation call**

Inside `clearUserStateOnLogout()`, after the existing `ref.invalidate(clubActivitiesProvider);` line (around line 47), add:

```dart
ref.invalidate(appBootstrapProvider);
```

- [ ] **Step 3: Verify compile**

Run: `cd sacdia-app && flutter analyze lib/features/auth/presentation/providers/logout_cleanup.dart`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add sacdia-app/lib/features/auth/presentation/providers/logout_cleanup.dart
git commit -m "feat(logout): invalidate appBootstrapProvider on logout cleanup"
```

---

### Task 5: Write unit tests for AppBootstrapNotifier

**Files:**
- Create: `sacdia-app/test/core/providers/app_bootstrap_provider_test.dart`

**Context:** The project uses `flutter_test` + `mockito`. We test the notifier by overriding `authNotifierProvider` with controlled values in a `ProviderContainer`.

- [ ] **Step 1: Create test directory**

Run: `mkdir -p sacdia-app/test/core/providers`

- [ ] **Step 2: Write the test file**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sacdia_app/core/providers/app_bootstrap_provider.dart';
import 'package:sacdia_app/features/auth/domain/entities/authorization_snapshot.dart';
import 'package:sacdia_app/features/auth/domain/entities/user_entity.dart';
import 'package:sacdia_app/features/auth/presentation/providers/auth_providers.dart';

/// Builds a [UserEntity] with the given authorization state.
UserEntity _buildUser({
  List<String> permissions = const [],
  List<AuthorizationGrant> globalGrants = const [],
  List<AuthorizationGrant> clubAssignments = const [],
  String? activeAssignmentId,
}) {
  return UserEntity(
    id: 'test-user-id',
    email: 'test@example.com',
    name: 'Test User',
    postRegisterComplete: true,
    authorization: AuthorizationSnapshot(
      effectivePermissions: permissions,
      globalGrants: globalGrants,
      clubAssignments: clubAssignments,
      activeAssignmentId: activeAssignmentId,
    ),
  );
}

UserEntity _buildValidUser() {
  return _buildUser(
    permissions: ['classes:read', 'activities:read'],
    clubAssignments: [
      const AuthorizationGrant(
        assignmentId: 'assignment-1',
        roleName: 'conquistador',
        permissions: ['classes:read', 'activities:read'],
        clubId: 1,
        sectionId: 1,
      ),
    ],
    activeAssignmentId: 'assignment-1',
  );
}

void main() {
  group('AppBootstrapNotifier', () {
    test('returns AppBootstrapReady when user has valid authorization',
        () async {
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => _FakeAuthNotifier(_buildValidUser()),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Wait for the bootstrap to resolve
      final state = await container.read(appBootstrapProvider.future);
      expect(state, isA<AppBootstrapReady>());
    });

    test('returns AppBootstrapUnauthenticated when user is null', () async {
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => _FakeAuthNotifier(null),
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(appBootstrapProvider.future);
      expect(state, isA<AppBootstrapUnauthenticated>());
    });

    test(
        'returns AppBootstrapError when user has empty permissions after retries',
        () async {
      final userWithNoPermissions = _buildUser();

      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => _FakeAuthNotifier(userWithNoPermissions),
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(appBootstrapProvider.future);
      expect(state, isA<AppBootstrapError>());
      expect(
        (state as AppBootstrapError).attemptCount,
        equals(3),
      );
    });

    test('returns AppBootstrapError when authorization is null after retries',
        () async {
      final userWithNoAuth = const UserEntity(
        id: 'test-id',
        email: 'test@test.com',
        postRegisterComplete: true,
      );

      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => _FakeAuthNotifier(userWithNoAuth),
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(appBootstrapProvider.future);
      expect(state, isA<AppBootstrapError>());
    });

    test('returns Ready when permissions present but no global grants',
        () async {
      final user = _buildUser(
        permissions: ['dashboard:read'],
        clubAssignments: [
          const AuthorizationGrant(
            assignmentId: 'a1',
            roleName: 'member',
            permissions: ['dashboard:read'],
            clubId: 1,
            sectionId: 1,
          ),
        ],
        activeAssignmentId: 'a1',
      );

      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => _FakeAuthNotifier(user),
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(appBootstrapProvider.future);
      expect(state, isA<AppBootstrapReady>());
    });
  });
}

/// Fake AuthNotifier that returns a fixed user without network calls.
class _FakeAuthNotifier extends AuthNotifier {
  final UserEntity? _user;

  _FakeAuthNotifier(this._user);

  @override
  Future<UserEntity?> build() async => _user;
}
```

- [ ] **Step 3: Run the tests**

Run: `cd sacdia-app && flutter test test/core/providers/app_bootstrap_provider_test.dart -v`
Expected: All tests pass. The "empty permissions after retries" test may take ~3s due to retry delays.

- [ ] **Step 4: Commit**

```bash
git add sacdia-app/test/core/providers/app_bootstrap_provider_test.dart
git commit -m "test(bootstrap): add unit tests for AppBootstrapNotifier"
```

---

### Task 6: Full compilation and smoke verification

**Files:** None (verification only)

- [ ] **Step 1: Run full analysis**

Run: `cd sacdia-app && flutter analyze`
Expected: No errors. Warnings are acceptable if pre-existing.

- [ ] **Step 2: Run all tests**

Run: `cd sacdia-app && flutter test`
Expected: All tests pass, including existing tests.

- [ ] **Step 3: Verify the app builds**

Run: `cd sacdia-app && flutter build apk --debug 2>&1 | tail -5`
Expected: Build succeeds.

- [ ] **Step 4: Final commit if any fixes were needed**

```bash
git add -A
git commit -m "fix(bootstrap): address compilation or test issues"
```
