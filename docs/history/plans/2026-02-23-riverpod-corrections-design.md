# Riverpod Corrections Design — sacdia-app
**Date**: 2026-02-23
**Strategy**: Incremental (Opción A)

## Scope

7 corrections to standardize Riverpod usage across the Flutter app.

---

## 1. Fix Duplicate `dioProvider` (Priority 1 - Bug)

**Problem**: `dioProvider` declared twice — one in `lib/providers/dio_provider.dart` (with `DioClient.createDio()` interceptors) and one in `features/auth/presentation/providers/auth_providers.dart` (raw `Dio`, no interceptors).

**Fix**: Remove inline `dioProvider` from `auth_providers.dart`. Import from `lib/providers/dio_provider.dart`.

**Files**: `lib/features/auth/presentation/providers/auth_providers.dart`

---

## 2. Migrate `StateNotifier` → `AsyncNotifier` (Priority 2 - Deprecated API)

**Problem**: `honors`, `classes`, `activities` use `StateNotifier<AsyncValue<T>>` / `StateNotifierProvider` (Riverpod 1.x deprecated).

**Fix**: Migrate to `AsyncNotifier<T>` / `AsyncNotifierProvider`. Public API (method names) stays the same.

**Files**:
- `lib/features/honors/presentation/providers/honors_providers.dart`
- `lib/features/classes/presentation/providers/classes_providers.dart`
- `lib/features/activities/presentation/providers/activities_providers.dart`

---

## 3. Fix `home` Feature (Priority 3 - Mock data + duplication)

**Problem**: `HomeNotifier` uses hardcoded mock data. `DashboardEntity` duplicates `DashboardSummary`. Manual `SharedPreferences` logout in `HomeView` bypasses Riverpod DI.

**Fix**:
- `HomeView` consumes `dashboardNotifierProvider` (real data, already exists in dashboard feature)
- Remove `HomeNotifier`, `HomeState`, `DashboardEntity`
- Replace manual SharedPreferences logout with `ref.read(authNotifierProvider.notifier).signOut()`
- Remove unimplemented `home_repository.dart` and `home_repository_impl.dart` stubs

**Files**: `lib/features/home/`

---

## 4. Eliminate Redundant `setState` in Auth Views (Priority 4)

**Problem**: `LoginView` and `RegisterView` maintain `_isLoading`/`_errorMessage` with `setState` while `authNotifierProvider` already exposes `AsyncValue` with loading/error state.

**Fix**: Remove local state fields. Use `ref.watch(authNotifierProvider)` + `.when()` / `.isLoading` / `.error` to derive UI state.

**Files**:
- `lib/features/auth/presentation/views/login_view.dart`
- `lib/features/auth/presentation/views/register_view.dart`

---

## 5. Migrate `ThemeProvider` to `NotifierProvider` (Priority 5)

**Problem**: `ThemeProvider extends ChangeNotifier` — the only `ChangeNotifier` in the app. Inconsistent with all other providers.

**Fix**: `ThemeNotifier extends Notifier<ThemeMode>`. `ChangeNotifierProvider` → `NotifierProvider<ThemeNotifier, ThemeMode>`. SharedPreferences persistence retained.

**Files**: `lib/core/theme/theme_provider.dart`

---

## 6. Remove Unused `core/auth` Providers (Priority 6)

**Problem**: `currentUserProvider` and `isAuthenticatedProvider` in `lib/core/auth/auth_providers.dart` are declared but never consumed anywhere.

**Fix**: Delete the file. Auth state is already centralized in `features/auth/presentation/providers/auth_providers.dart`.

**Files**: `lib/core/auth/auth_providers.dart`

---

## 7. Remove `riverpod_generator` from pubspec (Priority 7)

**Problem**: `riverpod_generator`, `riverpod_annotation`, and `build_runner` declared but no `@riverpod` annotations exist anywhere. Adds build overhead with zero benefit.

**Fix**: Remove from `pubspec.yaml`. Delete `build.yaml` if present. Run `flutter pub get`.

**Files**: `pubspec.yaml`, `build.yaml` (if exists)
