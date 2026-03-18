# Riverpod Corrections Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Standardize Riverpod usage across sacdia-app by fixing a correctness bug (duplicate dioProvider), migrating deprecated StateNotifier patterns, cleaning up the home feature mock data, eliminating redundant setState in auth views, migrating ThemeProvider, and removing dead code.

**Architecture:** Incremental corrections ordered by risk — lowest blast radius first. Each task touches isolated files. No new abstractions are introduced; only existing patterns are aligned to the modern AsyncNotifier API already used in auth/dashboard/profile.

**Tech Stack:** Flutter 3.x, flutter_riverpod ^2.6.1, Dart ^3.6.1

---

## Task 1: Fix duplicate `dioProvider` in auth_providers.dart

**Files:**
- Modify: `sacdia-app/lib/features/auth/presentation/providers/auth_providers.dart`

**Context:**
`auth_providers.dart` declares its own `dioProvider` (raw Dio, no interceptors) at lines 22–29.
The canonical one is at `lib/providers/dio_provider.dart` which uses `DioClient.createDio()` with interceptors.
All other features (honors, classes, activities, dashboard) import `dioProvider` from `auth_providers.dart`, meaning they all use the unconfigured Dio instance.

**Step 1: Add import for the canonical dioProvider**

In `sacdia-app/lib/features/auth/presentation/providers/auth_providers.dart`, add this import after line 4:

```dart
import '../../../../providers/dio_provider.dart';
```

**Step 2: Remove the duplicate dioProvider declaration**

Delete lines 21–29 (the comment and the inline `dioProvider`):

```dart
// DELETE these lines:
/// Provider para el cliente Dio
final dioProvider = Provider((ref) {
  return Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    contentType: 'application/json',
    validateStatus: (_) => true,
  ));
});
```

Also delete the unused `import 'package:dio/dio.dart';` from line 5 (only needed for the deleted Dio constructor).

**Step 3: Verify the app still analyzes cleanly**

```bash
cd sacdia-app && flutter analyze
```
Expected: no errors related to `dioProvider`. The import from `dio_provider.dart` re-exports the same symbol name.

**Step 4: Commit**

```bash
cd sacdia-app
git add lib/features/auth/presentation/providers/auth_providers.dart lib/providers/dio_provider.dart
git commit -m "fix: consolidate dioProvider to use configured DioClient with interceptors"
```

---

## Task 2: Migrate `HonorEnrollmentNotifier` from StateNotifier to AsyncNotifier

**Files:**
- Modify: `sacdia-app/lib/features/honors/presentation/providers/honors_providers.dart`

**Context:**
`HonorEnrollmentNotifier extends StateNotifier<AsyncValue<UserHonor?>>` at lines 130–148.
`honorEnrollmentNotifierProvider` uses `StateNotifierProvider` at lines 151–154.
Migrate to `AsyncNotifier<UserHonor?>` + `AsyncNotifierProvider` — the same pattern used in `auth`, `dashboard`, `profile`.

**Step 1: Replace the StateNotifier class with AsyncNotifier**

Replace lines 129–154 with:

```dart
/// Notifier para manejar inscripciones en especialidades
class HonorEnrollmentNotifier extends AsyncNotifier<UserHonor?> {
  @override
  Future<UserHonor?> build() async => null;

  /// Inscribir a un usuario en una especialidad
  Future<void> enrollInHonor(String userId, int honorId) async {
    state = const AsyncValue.loading();

    final result = await ref.read(startHonorProvider)(
      StartHonorParams(userId: userId, honorId: honorId),
    );

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (userHonor) => AsyncValue.data(userHonor),
    );
  }
}

/// Provider para el notifier de inscripción en especialidades
final honorEnrollmentNotifierProvider =
    AsyncNotifierProvider<HonorEnrollmentNotifier, UserHonor?>(() {
  return HonorEnrollmentNotifier();
});
```

**Step 2: Verify no view references the old StateNotifier API**

```bash
grep -r "honorEnrollmentNotifierProvider" sacdia-app/lib --include="*.dart"
```

Check all usages. Any `.state =` access from outside should be `.notifier.enrollInHonor(...)` instead.

**Step 3: Analyze**

```bash
cd sacdia-app && flutter analyze
```
Expected: no errors.

**Step 4: Commit**

```bash
cd sacdia-app
git add lib/features/honors/presentation/providers/honors_providers.dart
git commit -m "refactor: migrate HonorEnrollmentNotifier from StateNotifier to AsyncNotifier"
```

---

## Task 3: Migrate `ClassProgressNotifier` from StateNotifier to AsyncNotifier

**Files:**
- Modify: `sacdia-app/lib/features/classes/presentation/providers/classes_providers.dart`

**Context:**
`ClassProgressNotifier extends StateNotifier<AsyncValue<ClassProgress?>>` at lines 99–125.
`classProgressNotifierProvider` uses `StateNotifierProvider` at lines 128–131.

**Step 1: Replace the StateNotifier class with AsyncNotifier**

Replace lines 98–131 with:

```dart
/// Notifier para manejar actualizaciones de progreso
class ClassProgressNotifier extends AsyncNotifier<ClassProgress?> {
  @override
  Future<ClassProgress?> build() async => null;

  /// Actualizar progreso de una sección
  Future<void> updateProgress(
    String userId,
    int classId,
    Map<String, dynamic> progressData,
  ) async {
    state = const AsyncValue.loading();

    final result = await ref.read(updateClassProgressProvider)(
      UpdateClassProgressParams(
        userId: userId,
        classId: classId,
        progressData: progressData,
      ),
    );

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (progress) => AsyncValue.data(progress),
    );
  }
}

/// Provider para el notifier de progreso de clase
final classProgressNotifierProvider =
    AsyncNotifierProvider<ClassProgressNotifier, ClassProgress?>(() {
  return ClassProgressNotifier();
});
```

**Step 2: Analyze**

```bash
cd sacdia-app && flutter analyze
```

**Step 3: Commit**

```bash
cd sacdia-app
git add lib/features/classes/presentation/providers/classes_providers.dart
git commit -m "refactor: migrate ClassProgressNotifier from StateNotifier to AsyncNotifier"
```

---

## Task 4: Migrate `AttendanceNotifier` from StateNotifier to AsyncNotifier

**Files:**
- Modify: `sacdia-app/lib/features/activities/presentation/providers/activities_providers.dart`

**Context:**
`AttendanceNotifier extends StateNotifier<AsyncValue<int?>>` at lines 73–99.
`attendanceNotifierProvider` uses `StateNotifierProvider` at lines 102–105.

**Step 1: Replace with AsyncNotifier**

Replace lines 72–105 with:

```dart
/// Notifier para manejar el registro de asistencia
class AttendanceNotifier extends AsyncNotifier<int?> {
  @override
  Future<int?> build() async => null;

  /// Registrar asistencia de múltiples usuarios
  Future<void> registerMultiple(int activityId, List<String> userIds) async {
    state = const AsyncValue.loading();

    final result = await ref.read(registerAttendanceProvider)(
      RegisterAttendanceParams(
        activityId: activityId,
        userIds: userIds,
      ),
    );

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (count) => AsyncValue.data(count),
    );
  }

  /// Registrar asistencia de un solo usuario (conveniencia)
  Future<void> register(int activityId, String userId) async {
    await registerMultiple(activityId, [userId]);
  }
}

/// Provider para el notifier de asistencia
final attendanceNotifierProvider =
    AsyncNotifierProvider<AttendanceNotifier, int?>(() {
  return AttendanceNotifier();
});
```

**Step 2: Analyze**

```bash
cd sacdia-app && flutter analyze
```

**Step 3: Commit**

```bash
cd sacdia-app
git add lib/features/activities/presentation/providers/activities_providers.dart
git commit -m "refactor: migrate AttendanceNotifier from StateNotifier to AsyncNotifier"
```

---

## Task 5: Fix `home` feature — remove mock data, remove manual SharedPreferences logout

**Files:**
- Modify: `sacdia-app/lib/features/home/presentation/views/home_view.dart`
- Modify: `sacdia-app/lib/features/home/presentation/providers/home_providers.dart`
- Delete: `sacdia-app/lib/features/home/domain/entities/dashboard_entity.dart`
- Delete: `sacdia-app/lib/features/home/domain/repositories/home_repository.dart`

**Context:**
`HomeView` calls `homeNotifierProvider` which loads mock data. The real dashboard data lives in `dashboardNotifierProvider` (in the `dashboard` feature). `HomeView` also does manual `SharedPreferences.remove` calls for logout, which is already handled by `authNotifierProvider.signOut()`.

The strategy: keep `HomeView` as the shell (it's used by `AuthGate` and the router) but make it consume `dashboardNotifierProvider` instead of `homeNotifierProvider`. The UI of `HomeView` can be simplified to delegate to the proper `DashboardSummary` fields.

**Step 1: Rewrite home_providers.dart**

Replace the entire content of `home_providers.dart` with a re-export shim that forwards to dashboard's provider, keeping the filename stable so no router/auth_gate imports break:

```dart
// home_providers.dart — forwards to dashboard feature
// HomeView now consumes dashboardNotifierProvider directly.
// This file is kept for backward-compatibility of any existing imports.
export 'package:sacdia_app/features/dashboard/presentation/providers/dashboard_providers.dart'
    show dashboardNotifierProvider;
```

**Step 2: Rewrite home_view.dart**

Replace the entire `home_view.dart`. The new version consumes `dashboardNotifierProvider` directly, removes mock data, removes manual SharedPreferences logout, and maps `DashboardSummary` fields to the existing widgets.

```dart
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sacdia_app/core/theme/app_colors.dart';
import 'package:sacdia_app/core/utils/responsive.dart';
import 'package:sacdia_app/core/widgets/sac_button.dart';
import 'package:sacdia_app/core/widgets/sac_card.dart';
import 'package:sacdia_app/core/widgets/sac_dialog.dart';
import 'package:sacdia_app/core/widgets/sac_loading.dart';

import '../../../../core/utils/extensions.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/recent_activity_list.dart';

/// Vista principal de la aplicación después del login.
/// Consumes real dashboard data from dashboardNotifierProvider.
class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardNotifierProvider);
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final hPad = Responsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: dashboardState.when(
          loading: () => const Center(child: SacLoading()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedAlert02,
                    size: 56,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar datos',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.lightTextSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SacButton.primary(
                    text: 'Reintentar',
                    icon: HugeIcons.strokeRoundedRefresh,
                    onPressed: () =>
                        ref.read(dashboardNotifierProvider.notifier).refresh(),
                  ),
                ],
              ),
            ),
          ),
          data: (dashboard) => RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async =>
                ref.read(dashboardNotifierProvider.notifier).refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(hPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with greeting and logout
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¡Bienvenido de nuevo!',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (user != null)
                              Text(
                                user.name ?? user.email,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.lightTextSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedLogout01,
                          color: AppColors.lightTextTertiary,
                          size: 24,
                        ),
                        onPressed: () => _handleLogout(context, ref),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (dashboard != null) ...[
                    DashboardCard(
                      title: 'Especialidades completadas',
                      value: dashboard.honorsCompleted.toString(),
                      icon: HugeIcons.strokeRoundedTaskDone01,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedClock05,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Actividades próximas',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (dashboard.upcomingActivities.isNotEmpty)
                      RecentActivityList(
                        activities: dashboard.upcomingActivities
                            .map((a) => a.title)
                            .toList(),
                      )
                    else
                      SacCard(
                        child: Center(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'No hay actividades próximas',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.lightTextSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await SacDialog.show(
      context,
      title: 'Cerrar sesión',
      content: '¿Estás seguro que deseas cerrar sesión?',
      confirmLabel: 'Cerrar sesión',
      confirmIsDestructive: true,
    );

    if (confirmed == true) {
      final success =
          await ref.read(authNotifierProvider.notifier).signOut();
      if (success && context.mounted) {
        context.showSnackBar('Sesión cerrada correctamente');
      } else if (!success && context.mounted) {
        context.showSnackBar('Error al cerrar sesión');
      }
    }
  }
}
```

**Step 3: Delete orphan files**

```bash
cd sacdia-app
rm lib/features/home/domain/entities/dashboard_entity.dart
rm lib/features/home/domain/repositories/home_repository.dart
```

**Step 4: Analyze**

```bash
cd sacdia-app && flutter analyze
```
Expected: no errors. If `DashboardEntity` is referenced elsewhere it will appear here — fix any remaining references.

**Step 5: Commit**

```bash
cd sacdia-app
git add -A lib/features/home/
git commit -m "refactor: replace home mock data with real dashboardNotifierProvider, remove manual SharedPreferences logout"
```

---

## Task 6: Eliminate redundant setState in LoginView

**Files:**
- Modify: `sacdia-app/lib/features/auth/presentation/views/login_view.dart`

**Context:**
`_LoginViewState` maintains `_isLoading` (bool) and `_errorMessage` (String?) using `setState`. The `authNotifierProvider` already exposes `AsyncValue` with `.isLoading` and `.error`. Replace local state with provider-derived state.

**Step 1: Convert to ConsumerStatefulWidget watching the provider**

In `login_view.dart`:

1. Remove fields `bool _isLoading = false;` and `String? _errorMessage;` (lines 32–33).

2. Replace `_signIn()` method — remove all `setState` calls. The error display will come from the provider:

```dart
Future<void> _signIn() async {
  if (!_formKey.currentState!.validate()) return;

  await ref.read(authNotifierProvider.notifier).signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
  // Navigation is handled by the router watching authNotifierProvider.
  // Error is surfaced via ref.watch below.
}
```

3. In `build()`, add a `ref.watch` to derive `isLoading` and `errorMessage`:

```dart
@override
Widget build(BuildContext context) {
  final authState = ref.watch(authNotifierProvider);
  final isLoading = authState.isLoading;
  final errorMessage = authState.hasError
      ? (authState.error?.toString() ?? 'Error al iniciar sesión')
      : null;
  // ... rest of build unchanged, replace _isLoading with isLoading
  // and _errorMessage with errorMessage
```

4. Replace `isLoading: _isLoading` → `isLoading: isLoading` in `SacButton.primary`.

5. Replace `if (_errorMessage != null)` → `if (errorMessage != null)` and `_errorMessage!` → `errorMessage!`.

**Step 2: Analyze**

```bash
cd sacdia-app && flutter analyze
```

**Step 3: Commit**

```bash
cd sacdia-app
git add lib/features/auth/presentation/views/login_view.dart
git commit -m "refactor: derive loading/error state in LoginView from authNotifierProvider, remove setState"
```

---

## Task 7: Eliminate redundant setState in RegisterView

**Files:**
- Modify: `sacdia-app/lib/features/auth/presentation/views/register_view.dart`

**Context:**
`_RegisterViewState` maintains `_isLoading` and `_errorMessage` with `setState`. Same pattern as LoginView. Note: `_isButtonEnabled` must stay as local state since it's derived from text controller values (field validation), not from the auth provider.

**Step 1: Remove _isLoading and _errorMessage local state**

1. Remove `bool _isLoading = false;` and `String? _errorMessage;` (lines 35–37).

2. Replace `_signUp()` — remove all `setState` for loading/error:

```dart
Future<void> _signUp() async {
  if (!_formKey.currentState!.validate()) return;

  final success = await ref.read(authNotifierProvider.notifier).signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        paternalSurname: _paternalController.text.trim(),
        maternalSurname: _maternalController.text.trim(),
      );

  if (success && mounted) {
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cuenta creada. Ya puedes iniciar sesión.'),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
  // Error is surfaced via ref.watch in build().
}
```

3. In `build()`, watch the provider for loading/error:

```dart
@override
Widget build(BuildContext context) {
  final authState = ref.watch(authNotifierProvider);
  final isLoading = authState.isLoading;
  final errorMessage = authState.hasError
      ? (authState.error?.toString() ?? 'Error al registrar la cuenta')
      : null;
  // ... rest of build, replace _isLoading → isLoading, _errorMessage → errorMessage
```

4. `_isButtonEnabled` remains as local setState (it reacts to text field content, not auth state).

**Step 2: Analyze**

```bash
cd sacdia-app && flutter analyze
```

**Step 3: Commit**

```bash
cd sacdia-app
git add lib/features/auth/presentation/views/register_view.dart
git commit -m "refactor: derive loading/error state in RegisterView from authNotifierProvider, remove setState"
```

---

## Task 8: Migrate ThemeProvider from ChangeNotifier to Notifier

**Files:**
- Modify: `sacdia-app/lib/core/theme/theme_provider.dart`
- Modify: `sacdia-app/lib/main.dart`

**Context:**
`ThemeProvider extends ChangeNotifier` with `ChangeNotifierProvider` in `main.dart`. Migrate to `Notifier<ThemeMode>` + `NotifierProvider` for consistency with all other providers.

Note: `ThemeProvider` exposes `lightTheme`, `darkTheme`, and `themeMode` getters. In `main.dart`, `MyApp` accesses all three via `ref.watch(themeProvider)`. After migration, `themeMode` will be the provider's state, and `lightTheme`/`darkTheme` are static — expose them from `AppTheme` directly.

**Step 1: Rewrite theme_provider.dart**

Replace the entire file content:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sacdia_app/core/constants/app_constants.dart';
import 'package:sacdia_app/core/storage/local_storage.dart';

/// Notifier para manejar el tema de la aplicación
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Load persisted theme synchronously (LocalStorage uses SharedPreferences
    // which is already initialized before ProviderScope).
    final localStorage = ref.read(localStorageProvider);
    final saved = localStorage.getString(AppConstants.themeKey);
    if (saved == 'light') return ThemeMode.light;
    if (saved == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  Future<void> setLightTheme() async {
    state = ThemeMode.light;
    await ref.read(localStorageProvider).saveString(AppConstants.themeKey, 'light');
  }

  Future<void> setDarkTheme() async {
    state = ThemeMode.dark;
    await ref.read(localStorageProvider).saveString(AppConstants.themeKey, 'dark');
  }

  Future<void> setSystemTheme() async {
    state = ThemeMode.system;
    await ref.read(localStorageProvider).saveString(AppConstants.themeKey, 'system');
  }

  Future<void> toggleTheme() async {
    if (state == ThemeMode.light) {
      await setDarkTheme();
    } else {
      await setLightTheme();
    }
  }
}

final themeNotifierProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});
```

**Important:** The `ThemeNotifier.build()` uses `ref.read(localStorageProvider)`. Check that `localStorageProvider` exists or create it. If `LocalStorage` / `SharedPreferencesStorage` is already provided via `sharedPreferencesProvider`, use that instead:

```dart
// Alternative if no localStorageProvider exists:
@override
ThemeMode build() {
  final prefs = ref.read(sharedPreferencesProvider);
  final saved = prefs.getString(AppConstants.themeKey);
  if (saved == 'light') return ThemeMode.light;
  if (saved == 'dark') return ThemeMode.dark;
  return ThemeMode.system;
}

Future<void> setLightTheme() async {
  state = ThemeMode.light;
  ref.read(sharedPreferencesProvider).setString(AppConstants.themeKey, 'light');
}
// etc.
```

Verify which storage abstraction is available by reading `lib/core/storage/local_storage.dart` before implementing.

**Step 2: Update main.dart**

1. Remove the `themeProvider` declaration from `main.dart` (lines 80–83):
```dart
// DELETE:
final themeProvider = ChangeNotifierProvider<ThemeProvider>((ref) {
  final localStorage = SharedPreferencesStorage(ref.read(sharedPreferencesProvider));
  return ThemeProvider(localStorage);
});
```

2. Remove import of `theme_provider.dart` from main.dart (it will be re-imported from the new file if needed, but the provider is now declared inside `theme_provider.dart`).

3. In `MyApp.build()`, update the watch call:
```dart
// BEFORE:
final themeProviderState = ref.watch(themeProvider);
// ...
theme: themeProviderState.lightTheme,
darkTheme: themeProviderState.darkTheme,
themeMode: themeProviderState.themeMode,

// AFTER:
final themeMode = ref.watch(themeNotifierProvider);
// ...
theme: AppTheme.lightTheme,
darkTheme: AppTheme.darkTheme,
themeMode: themeMode,
```

4. Add import: `import 'core/theme/app_theme.dart';` and `import 'core/theme/theme_provider.dart';` to main.dart.

**Step 3: Analyze**

```bash
cd sacdia-app && flutter analyze
```

**Step 4: Commit**

```bash
cd sacdia-app
git add lib/core/theme/theme_provider.dart lib/main.dart
git commit -m "refactor: migrate ThemeProvider from ChangeNotifier to NotifierProvider<ThemeMode>"
```

---

## Task 9: Remove unused core/auth/auth_providers.dart

**Files:**
- Delete: `sacdia-app/lib/core/auth/auth_providers.dart`

**Context:**
`lib/core/auth/auth_providers.dart` declares `authStateProvider` (StreamProvider<AuthState>), `currentUserProvider`, and `isAuthenticatedProvider`. None are consumed anywhere (confirmed by grep: only the file itself).

**Step 1: Verify no consumers**

```bash
grep -r "currentUserProvider\|isAuthenticatedProvider\|core/auth/auth_providers" sacdia-app/lib --include="*.dart"
```
Expected: only `core/auth/auth_providers.dart` itself appears.

**Step 2: Delete the file**

```bash
rm sacdia-app/lib/core/auth/auth_providers.dart
```

**Step 3: Analyze**

```bash
cd sacdia-app && flutter analyze
```
Expected: no errors.

**Step 4: Commit**

```bash
cd sacdia-app
git add -A lib/core/auth/
git commit -m "chore: remove unused core/auth/auth_providers.dart (currentUserProvider, isAuthenticatedProvider never consumed)"
```

---

## Task 10: Remove riverpod_generator and riverpod_annotation from pubspec.yaml

**Files:**
- Modify: `sacdia-app/pubspec.yaml`

**Context:**
`riverpod_annotation: ^2.6.1` (prod dep) and `riverpod_generator: ^2.6.5` (dev dep) are declared but no file uses `@riverpod` annotations. `build_runner` stays — it's also used by `freezed` and `json_serializable`.

**Step 1: Edit pubspec.yaml**

Remove line 24: `  riverpod_annotation: ^2.6.1` from `dependencies:`.
Remove line 60: `  riverpod_generator: ^2.6.5` from `dev_dependencies:`.

**Step 2: Run flutter pub get**

```bash
cd sacdia-app && flutter pub get
```
Expected: clean resolution, no errors.

**Step 3: Analyze**

```bash
cd sacdia-app && flutter analyze
```

**Step 4: Commit**

```bash
cd sacdia-app
git add pubspec.yaml pubspec.lock
git commit -m "chore: remove unused riverpod_generator and riverpod_annotation dependencies"
```

---

## Verification Checklist

After all tasks:

```bash
cd sacdia-app
flutter analyze          # zero errors, zero warnings
flutter pub get          # clean dependency resolution
```

Manually verify:
- [ ] `dioProvider` is imported from `lib/providers/dio_provider.dart` in all features
- [ ] No `StateNotifier` or `StateNotifierProvider` in honors/classes/activities/home
- [ ] No `_isLoading` / `_errorMessage` setState in LoginView or RegisterView
- [ ] `HomeView` uses `dashboardNotifierProvider` — no mock data
- [ ] `DashboardEntity` file deleted
- [ ] `core/auth/auth_providers.dart` deleted
- [ ] `ThemeProvider` uses `NotifierProvider`
- [ ] `pubspec.yaml` has no `riverpod_annotation` or `riverpod_generator`
