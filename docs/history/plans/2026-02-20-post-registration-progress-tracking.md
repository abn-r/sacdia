# Post-Registration Progress Tracking Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix 6 bugs so the app correctly reads completion status from the backend, calls the right completion endpoints at each step, and updates auth state after finishing onboarding.

**Architecture:** Pure bug-fix pass — no new screens, no new providers beyond `selectedClubTypeSlugProvider`. Changes flow Data → Domain → Presentation in dependency order. Each task is independent except Task 9 (shell) which depends on all others.

**Tech Stack:** Flutter, Riverpod, Dio, dartz (Either), FlutterSecureStorage, SharedPreferences

---

### Task 1: Fix `CompletionStatusModel.fromJson()` — nested API envelope

**Files:**
- Modify: `sacdia-app/lib/features/post_registration/data/models/completion_status_model.dart`

**Context:**
The API returns `{ "data": { "complete": bool, "steps": { "profilePicture": bool, "personalInfo": bool, "clubSelection": bool }, "nextStep": string|null } }`.
The current code reads flat keys like `json['photo_complete']` — they don't exist.

Navigation rules from `nextStep`:
- `"profilePicture"` → currentStep = 1
- `"personalInfo"` → currentStep = 2
- `"clubSelection"` → currentStep = 3
- `complete == true && nextStep == null` → isComplete = true, currentStep = 3 (not used)
- `complete == false && nextStep == null` → fallback currentStep = 1

**Step 1: Replace `fromJson` with the correct nested parsing**

Replace the entire `fromJson` factory:

```dart
factory CompletionStatusModel.fromJson(Map<String, dynamic> json) {
  final data = json['data'] as Map<String, dynamic>? ?? json;
  final steps = data['steps'] as Map<String, dynamic>? ?? {};

  final isComplete = data['complete'] as bool? ?? false;
  final nextStep = data['nextStep'] as String?;

  final photoComplete = steps['profilePicture'] as bool? ?? false;
  final personalInfoComplete = steps['personalInfo'] as bool? ?? false;
  final clubSelectionComplete = steps['clubSelection'] as bool? ?? false;

  int currentStep;
  if (isComplete && nextStep == null) {
    currentStep = 3; // isComplete=true is the real signal — shell will navigate home
  } else {
    switch (nextStep) {
      case 'profilePicture':
        currentStep = 1;
        break;
      case 'personalInfo':
        currentStep = 2;
        break;
      case 'clubSelection':
        currentStep = 3;
        break;
      default:
        currentStep = 1; // complete==false && nextStep==null → fallback
    }
  }

  return CompletionStatusModel(
    isComplete: isComplete,
    currentStep: currentStep,
    photoComplete: photoComplete,
    personalInfoComplete: personalInfoComplete,
    clubSelectionComplete: clubSelectionComplete,
  );
}
```

The full file after the change:

```dart
import '../../domain/entities/completion_status.dart';

/// Modelo de datos para el estado de completitud del post-registro
class CompletionStatusModel extends CompletionStatus {
  const CompletionStatusModel({
    required super.isComplete,
    required super.currentStep,
    required super.photoComplete,
    required super.personalInfoComplete,
    required super.clubSelectionComplete,
  });

  /// Crea una instancia desde JSON
  factory CompletionStatusModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final steps = data['steps'] as Map<String, dynamic>? ?? {};

    final isComplete = data['complete'] as bool? ?? false;
    final nextStep = data['nextStep'] as String?;

    final photoComplete = steps['profilePicture'] as bool? ?? false;
    final personalInfoComplete = steps['personalInfo'] as bool? ?? false;
    final clubSelectionComplete = steps['clubSelection'] as bool? ?? false;

    int currentStep;
    if (isComplete && nextStep == null) {
      currentStep = 3;
    } else {
      switch (nextStep) {
        case 'profilePicture':
          currentStep = 1;
          break;
        case 'personalInfo':
          currentStep = 2;
          break;
        case 'clubSelection':
          currentStep = 3;
          break;
        default:
          currentStep = 1;
      }
    }

    return CompletionStatusModel(
      isComplete: isComplete,
      currentStep: currentStep,
      photoComplete: photoComplete,
      personalInfoComplete: personalInfoComplete,
      clubSelectionComplete: clubSelectionComplete,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'complete': isComplete,
      'current_step': currentStep,
      'photo_complete': photoComplete,
      'personal_info_complete': personalInfoComplete,
      'club_selection_complete': clubSelectionComplete,
    };
  }
}
```

**Step 2: Verify with `flutter analyze`**

```bash
cd sacdia-app && flutter analyze lib/features/post_registration/data/models/completion_status_model.dart
```
Expected: No issues found.

---

### Task 2: Add `clubTypeSlug` to `ClubInstanceModel`

**Files:**
- Modify: `sacdia-app/lib/features/post_registration/data/models/club_instance_model.dart`

**Context:**
The API returns instances bucketed by type: `{ "adventurers": [...], "pathfinders": [...], "master_guilds": [...] }`.
Each item has `id`, `club_type_id`, `club_id` — but NO `club_type_name` and NO slug field.
We must inject `clubTypeSlug` from the bucket key when parsing (Task 3 handles this).
We also need to drop the now-absent `clubTypeName` field to avoid a cast error — or keep it optional.

Since `clubTypeName` is used elsewhere in the UI (club selection view), we keep it but make it optional and derive it from `clubTypeSlug` if not present.

**Step 1: Rewrite the model**

```dart
import 'package:equatable/equatable.dart';

/// Modelo de instancia de club (tipo específico de club)
class ClubInstanceModel extends Equatable {
  final int id;
  final int clubTypeId;
  final int clubId;
  /// Slug canónico del tipo de club: adventurers | pathfinders | master_guild
  final String clubTypeSlug;
  /// Nombre legible (puede ser null si el API no lo devuelve)
  final String? clubTypeName;

  const ClubInstanceModel({
    required this.id,
    required this.clubTypeId,
    required this.clubId,
    required this.clubTypeSlug,
    this.clubTypeName,
  });

  /// Parsea un item individual desde el bucket de instancias.
  /// [slug] es la clave del bucket normalizada (master_guilds → master_guild).
  factory ClubInstanceModel.fromJsonWithSlug(
      Map<String, dynamic> json, String slug) {
    return ClubInstanceModel(
      id: json['id'] as int,
      clubTypeId: json['club_type_id'] as int,
      clubId: json['club_id'] as int,
      clubTypeSlug: slug,
      clubTypeName: json['club_type_name'] as String?,
    );
  }

  /// Legacy factory — kept for compatibility; slug defaults to empty string.
  factory ClubInstanceModel.fromJson(Map<String, dynamic> json) {
    return ClubInstanceModel(
      id: json['id'] as int,
      clubTypeId: json['club_type_id'] as int,
      clubId: json['club_id'] as int,
      clubTypeSlug: json['club_type_slug'] as String? ?? '',
      clubTypeName: json['club_type_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'club_type_id': clubTypeId,
      'club_id': clubId,
      'club_type_slug': clubTypeSlug,
      if (clubTypeName != null) 'club_type_name': clubTypeName,
    };
  }

  ClubInstanceModel copyWith({
    int? id,
    int? clubTypeId,
    int? clubId,
    String? clubTypeSlug,
    String? clubTypeName,
  }) {
    return ClubInstanceModel(
      id: id ?? this.id,
      clubTypeId: clubTypeId ?? this.clubTypeId,
      clubId: clubId ?? this.clubId,
      clubTypeSlug: clubTypeSlug ?? this.clubTypeSlug,
      clubTypeName: clubTypeName ?? this.clubTypeName,
    );
  }

  @override
  List<Object?> get props => [id, clubTypeId, clubId, clubTypeSlug];
}
```

**Step 2: Verify**

```bash
cd sacdia-app && flutter analyze lib/features/post_registration/data/models/club_instance_model.dart
```
Expected: No issues found.

---

### Task 3: Fix `ClubSelectionRemoteDataSource` — bucket parsing + step-3 URL/body

**Files:**
- Modify: `sacdia-app/lib/features/post_registration/data/datasources/club_selection_remote_data_source.dart`

**Context:**
Bug A: `getClubInstances` casts `response.data` as `List` — but API returns an object with bucket keys (`adventurers`, `pathfinders`, `master_guilds`). Need to iterate keys, normalize `master_guilds → master_guild`, and use `fromJsonWithSlug`.

Bug B: `completeStep3` URL is `/complete-step-3` instead of `/step-3/complete`, and missing `club_type` in the body. Need to add `clubTypeSlug` param.

**Step 1: Update the interface** — add `clubTypeSlug` param to `completeStep3`

In the `abstract class ClubSelectionRemoteDataSource`, replace:
```dart
  Future<void> completeStep3({
    required String userId,
    required int countryId,
    required int unionId,
    required int localFieldId,
    required int clubInstanceId,
    required int classId,
  });
```
With:
```dart
  Future<void> completeStep3({
    required String userId,
    required int countryId,
    required int unionId,
    required int localFieldId,
    required String clubTypeSlug,
    required int clubInstanceId,
    required int classId,
  });
```

**Step 2: Fix `getClubInstances` implementation**

Replace the entire `getClubInstances` method body (lines 167–188):

```dart
  @override
  Future<List<ClubInstanceModel>> getClubInstances(int clubId) async {
    try {
      final options = await _authOptions();
      final response = await _dio.get(
        '$_baseUrl/clubs/$clubId/instances',
        options: options,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> buckets =
            response.data as Map<String, dynamic>;
        final List<ClubInstanceModel> result = [];

        for (final entry in buckets.entries) {
          // Normalize: master_guilds → master_guild (drop trailing 's')
          final rawKey = entry.key; // e.g. 'adventurers', 'master_guilds'
          final slug = rawKey == 'master_guilds' ? 'master_guild' : rawKey;
          final items = entry.value as List<dynamic>;
          for (final item in items) {
            result.add(ClubInstanceModel.fromJsonWithSlug(
                item as Map<String, dynamic>, slug));
          }
        }

        return result;
      }

      throw ServerException(message: 'Error al obtener tipos de club');
    } catch (e) {
      log('Error al obtener tipos de club: $e');
      if (e is DioException) {
        throw ServerException(message: e.message ?? 'Error de conexión');
      }
      if (e is AppException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
```

**Step 3: Fix `completeStep3` implementation**

Replace the entire `completeStep3` method (lines 217–251):

```dart
  @override
  Future<void> completeStep3({
    required String userId,
    required int countryId,
    required int unionId,
    required int localFieldId,
    required String clubTypeSlug,
    required int clubInstanceId,
    required int classId,
  }) async {
    try {
      final options = await _authOptions();
      final response = await _dio.post(
        '$_baseUrl/users/$userId/post-registration/step-3/complete',
        data: {
          'country_id': countryId,
          'union_id': unionId,
          'local_field_id': localFieldId,
          'club_type': clubTypeSlug,
          'club_instance_id': clubInstanceId,
          'class_id': classId,
        },
        options: options,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
            message: 'Error al completar el paso 3 del post-registro');
      }
    } catch (e) {
      log('Error al completar paso 3: $e');
      if (e is DioException) {
        throw ServerException(message: e.message ?? 'Error de conexión');
      }
      if (e is AppException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
```

**Step 4: Verify**

```bash
cd sacdia-app && flutter analyze lib/features/post_registration/data/datasources/club_selection_remote_data_source.dart
```
Expected: No issues found.

---

### Task 4: Fix `completeStep2` URL in `PersonalInfoRemoteDataSource`

**Files:**
- Modify: `sacdia-app/lib/features/post_registration/data/datasources/personal_info_remote_data_source.dart`

**Context:**
Current URL: `/users/$userId/post-registration/complete-step-2`
Correct URL: `/users/$userId/post-registration/step-2/complete`

**Step 1: Fix the URL** at line 375:

Replace:
```dart
        '$_baseUrl/users/$userId/post-registration/complete-step-2',
```
With:
```dart
        '$_baseUrl/users/$userId/post-registration/step-2/complete',
```

**Step 2: Verify**

```bash
cd sacdia-app && flutter analyze lib/features/post_registration/data/datasources/personal_info_remote_data_source.dart
```

---

### Task 5: Add `completeStep1` to `PostRegistrationRemoteDataSource`

**Files:**
- Modify: `sacdia-app/lib/features/post_registration/data/datasources/post_registration_remote_data_source.dart`

**Context:**
`completeStep1` endpoint: `POST /users/{userId}/post-registration/step-1/complete` — no body.
This method doesn't exist at all. Add it to the interface and implementation.

**Step 1: Add to the abstract interface**

After `getPhotoStatus`, add:
```dart
  /// Completa el paso 1 del post-registro (foto de perfil)
  Future<void> completeStep1(String userId);
```

**Step 2: Add the implementation**

After the `getPhotoStatus` implementation (end of class, before closing `}`):

```dart
  @override
  Future<void> completeStep1(String userId) async {
    try {
      final options = await _authOptions();
      final response = await _dio.post(
        '$_baseUrl/users/$userId/post-registration/step-1/complete',
        options: options,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
            message: 'Error al completar el paso 1 del post-registro');
      }
    } catch (e) {
      log('Error al completar paso 1: $e');
      if (e is DioException) {
        throw ServerException(message: e.message ?? 'Error de conexión');
      }
      if (e is AppException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
```

**Step 3: Verify**

```bash
cd sacdia-app && flutter analyze lib/features/post_registration/data/datasources/post_registration_remote_data_source.dart
```

---

### Task 6: Add `completeStep1` to the repository interface and implementation

**Files:**
- Modify: `sacdia-app/lib/features/post_registration/domain/repositories/post_registration_repository.dart`
- Modify: `sacdia-app/lib/features/post_registration/data/repositories/post_registration_repository_impl.dart`

**Step 1: Add to interface**

In `post_registration_repository.dart`, after `getPhotoStatus`, add:
```dart
  /// Completa el paso 1 del post-registro
  Future<Either<Failure, void>> completeStep1(String userId);
```

**Step 2: Add the implementation**

In `post_registration_repository_impl.dart`, after `getPhotoStatus` implementation, add:

```dart
  @override
  Future<Either<Failure, void>> completeStep1(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.completeStep1(userId);
        return const Right(null);
      } on core_exceptions.ServerException catch (e) {
        return Left(ServerFailure(message: e.message, code: e.code));
      } on core_exceptions.AuthException catch (e) {
        return Left(AuthFailure(message: e.message, code: e.code));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No hay conexión a internet'));
    }
  }
```

**Step 3: Verify**

```bash
cd sacdia-app && flutter analyze lib/features/post_registration/domain/repositories/post_registration_repository.dart lib/features/post_registration/data/repositories/post_registration_repository_impl.dart
```

---

### Task 7: Add `selectedClubTypeSlugProvider` to club selection providers

**Files:**
- Modify: `sacdia-app/lib/features/post_registration/presentation/providers/club_selection_providers.dart`

**Context:**
The shell needs to pass `clubTypeSlug` to `completeStep3`. We track the selected instance's slug in a dedicated provider. When `clubInstancesProvider` auto-selects, it must also set this slug provider.

**Step 1: Add the provider** — add after `selectedClubInstanceProvider` (line 153):

```dart
/// Provider para el slug del tipo de club de la instancia seleccionada
/// Valores posibles: 'adventurers' | 'pathfinders' | 'master_guild'
final selectedClubTypeSlugProvider = StateProvider<String?>((ref) => null);
```

**Step 2: Wire auto-selection in `clubInstancesProvider`** — update the auto-selection block to also set slug.

Replace the existing auto-selection section (the `if (instances.length == 1)` block, roughly lines 118–147) with:

```dart
  // Auto-selección basada en edad si está disponible
  final age = ref.read(userAgeProvider);
  if (instances.length == 1) {
    Future.microtask(() {
      ref.read(selectedClubInstanceProvider.notifier).state = instances.first.id;
      ref.read(selectedClubTypeSlugProvider.notifier).state =
          instances.first.clubTypeSlug;
    });
  } else if (age != null && instances.isNotEmpty) {
    // Pre-selección basada en edad
    ClubInstanceModel? recommended;
    if (age >= 4 && age <= 9) {
      recommended = instances.firstWhere(
        (instance) =>
            instance.clubTypeSlug == 'adventurers' ||
            (instance.clubTypeName?.toLowerCase().contains('aventurero') ??
                false),
        orElse: () => instances.first,
      );
    } else if (age >= 10 && age <= 15) {
      recommended = instances.firstWhere(
        (instance) =>
            instance.clubTypeSlug == 'pathfinders' ||
            (instance.clubTypeName?.toLowerCase().contains('conquistador') ??
                false),
        orElse: () => instances.first,
      );
    } else if (age >= 16) {
      recommended = instances.firstWhere(
        (instance) =>
            instance.clubTypeSlug == 'master_guild' ||
            (instance.clubTypeName?.toLowerCase().contains('guía') ?? false),
        orElse: () => instances.first,
      );
    }

    if (recommended != null) {
      Future.microtask(() {
        ref.read(selectedClubInstanceProvider.notifier).state = recommended!.id;
        ref.read(selectedClubTypeSlugProvider.notifier).state =
            recommended.clubTypeSlug;
      });
    }
  }
```

**Step 3: Include slug in `canCompleteStep3Provider`**

Replace the `canCompleteStep3Provider` provider:

```dart
/// Provider para determinar si se puede completar el paso 3
final canCompleteStep3Provider = Provider<bool>((ref) {
  final country = ref.watch(selectedCountryProvider);
  final union = ref.watch(selectedUnionProvider);
  final localField = ref.watch(selectedLocalFieldProvider);
  final clubInstance = ref.watch(selectedClubInstanceProvider);
  final classId = ref.watch(selectedClassProvider);
  final clubTypeSlug = ref.watch(selectedClubTypeSlugProvider);

  return country != null &&
      union != null &&
      localField != null &&
      clubInstance != null &&
      classId != null &&
      clubTypeSlug != null;
});
```

**Step 4: Verify**

```bash
cd sacdia-app && flutter analyze lib/features/post_registration/presentation/providers/club_selection_providers.dart
```

---

### Task 8: Wire `_onContinue()` in the shell with async completion calls

**Files:**
- Modify: `sacdia-app/lib/features/post_registration/presentation/views/post_registration_shell.dart`

**Context:**
Current `_onContinue()` just calls `_goToStep(currentStep + 1)` — it never hits any completion endpoint. We need to:
- Step 1: call `completeStep1`, show SnackBar on error
- Step 2: call `savePersonalInfoProvider` (which already calls `completeStep2`), show SnackBar on error
- Step 3: call `completeStep3`, handle 409 as success, update both auth state + SharedPreferences, navigate home
- `_loadCompletionStatus()`: if `status.isComplete == true` → navigate home immediately

We also need to read the `postRegistrationRepositoryProvider`. Let's check where it's defined.

**Step 1: Find the repository provider**

```bash
grep -r "postRegistrationRepositoryProvider" sacdia-app/lib --include="*.dart" -l
```

Note the file path for the import. It's likely in `post_registration_providers.dart`.

**Step 2: Add needed imports** — at the top of `post_registration_shell.dart`, after existing imports, add:

```dart
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/domain/entities/user_entity.dart';
```

(Check if `user_entity.dart` is already imported indirectly — if so, skip.)

**Step 3: Replace `_loadCompletionStatus()`**

Replace:
```dart
  Future<void> _loadCompletionStatus() async {
    final status = await ref.read(completionStatusProvider.future);
    if (status != null && mounted) {
      final step = status.currentStep;
      ref.read(currentStepProvider.notifier).state = step;
      if (step > 1) {
        _pageController.jumpToPage(step - 1);
      }
    }
  }
```

With:
```dart
  Future<void> _loadCompletionStatus() async {
    final status = await ref.read(completionStatusProvider.future);
    if (status == null || !mounted) return;

    if (status.isComplete) {
      context.go(RouteNames.homeDashboard);
      return;
    }

    final step = status.currentStep;
    ref.read(currentStepProvider.notifier).state = step;
    if (step > 1) {
      _pageController.jumpToPage(step - 1);
    }
  }
```

**Step 4: Replace `_onContinue()` with async version**

Replace:
```dart
  void _onContinue() {
    final currentStep = ref.read(currentStepProvider);
    if (currentStep < 3) {
      _goToStep(currentStep + 1);
    } else {
      context.go(RouteNames.homeDashboard);
    }
  }
```

With:
```dart
  Future<void> _onContinue() async {
    final currentStep = ref.read(currentStepProvider);

    if (currentStep == 1) {
      await _completeStep1();
    } else if (currentStep == 2) {
      await _completeStep2();
    } else {
      await _completeStep3();
    }
  }

  Future<void> _completeStep1() async {
    final authState = ref.read(authNotifierProvider);
    final userId = authState.valueOrNull?.id;
    if (userId == null) return;

    final repository = ref.read(postRegistrationRepositoryProvider);
    final result = await repository.completeStep1(userId);

    result.fold(
      (failure) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (_) {
        if (mounted) _goToStep(2);
      },
    );
  }

  Future<void> _completeStep2() async {
    try {
      final saveInfo = ref.read(savePersonalInfoProvider);
      await saveInfo();
      if (mounted) _goToStep(3);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _completeStep3() async {
    final authState = ref.read(authNotifierProvider);
    final userId = authState.valueOrNull?.id;
    if (userId == null) return;

    ref.read(isSavingStep3Provider.notifier).state = true;

    try {
      final dataSource = ref.read(clubSelectionDataSourceProvider);
      await dataSource.completeStep3(
        userId: userId,
        countryId: ref.read(selectedCountryProvider)!,
        unionId: ref.read(selectedUnionProvider)!,
        localFieldId: ref.read(selectedLocalFieldProvider)!,
        clubTypeSlug: ref.read(selectedClubTypeSlugProvider)!,
        clubInstanceId: ref.read(selectedClubInstanceProvider)!,
        classId: ref.read(selectedClassProvider)!,
      );
    } on Exception catch (e) {
      final msg = e.toString();
      // 409 Conflict = already completed → treat as success
      if (!msg.contains('409') && mounted) {
        ref.read(isSavingStep3Provider.notifier).state = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg.replaceFirst('Exception: ', ''))),
        );
        return;
      }
    } finally {
      if (mounted) {
        ref.read(isSavingStep3Provider.notifier).state = false;
      }
    }

    if (!mounted) return;

    // Update auth state so router redirects correctly
    final user = ref.read(authNotifierProvider).valueOrNull!;
    final updated = UserEntity(
      id: user.id,
      email: user.email,
      name: user.name,
      avatar: user.avatar,
      metadata: user.metadata,
      postRegisterComplete: true,
    );
    ref.read(authNotifierProvider.notifier).state = AsyncValue.data(updated);

    // Also persist to SharedPreferences cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cached_post_register_complete', true);

    if (mounted) context.go(RouteNames.homeDashboard);
  }
```

**Step 5: Update `BottomNavigationButtons` — the `onContinue` callback type**

The `BottomNavigationButtons` likely declares `onContinue` as `VoidCallback`. We need to verify — if it's `VoidCallback`, wrap the async call.

Run:
```bash
grep -n "onContinue" sacdia-app/lib/features/post_registration/presentation/widgets/bottom_navigation_buttons.dart
```

If `onContinue` is declared as `VoidCallback` (not `AsyncCallback`), keep the `_onContinue` signature but call it with `() => _onContinue()` and don't await inside the widget — the async just runs in the background. Actually, `void Function()` works fine with async; Flutter calls it and the Future is fire-and-forget which is acceptable here because we control state internally.

So change the widget call from `onContinue: _onContinue` to remain `onContinue: _onContinue` — Flutter accepts `Future<void> Function()` as `void Function()` without a cast. No widget change needed.

**Step 6: Find `postRegistrationRepositoryProvider`**

```bash
grep -rn "postRegistrationRepositoryProvider" sacdia-app/lib --include="*.dart"
```

Add the import to the shell file for wherever `postRegistrationRepositoryProvider` is defined (likely `post_registration_providers.dart` already imported, or add it).

**Step 7: Verify full build**

```bash
cd sacdia-app && flutter analyze lib/features/post_registration/
```
Expected: No issues found.

---

### Task 9: Manual smoke test checklist

No code changes — verify the complete flow manually or with flutter run.

**Checklist:**
1. **Fresh install**: open app → log in → `getCompletionStatus` returns `nextStep: "profilePicture"` → lands on step 1 ✓
2. **Returning user mid-flow**: `nextStep: "personalInfo"` → app opens at step 2 ✓
3. **Onboarding already complete**: `complete: true` → app immediately goes to home ✓
4. **Step 1 → 2**: upload photo → tap Continuar → `POST /step-1/complete` called → moves to step 2 ✓
5. **Step 2 → 3**: fill form + contacts → tap Continuar → `savePersonalInfoProvider` (includes `completeStep2`) → moves to step 3 ✓
6. **Step 3 → home**: select club → tap Finalizar → `POST /step-3/complete` with `club_type` field → auth state updated → navigates home ✓
7. **Step 3 idempotency**: tap Finalizar twice fast — button disabled during save → no double-submit ✓
8. **Network error on step 1**: server unavailable → SnackBar shown → stays on step 1 ✓
