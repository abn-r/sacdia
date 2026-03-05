# Post-Registration Progress Tracking — Design Document

**Date:** 2026-02-20
**Status:** Approved

---

## Problem

El flujo de post-registro no persiste el progreso del usuario en el backend. Hay 6 bugs raíz:

| # | Problema | Archivo |
|---|---|---|
| 1 | `CompletionStatusModel.fromJson()` parsea claves planas (`photo_complete`) pero el API devuelve estructura anidada (`data.steps.profilePicture`) | `completion_status_model.dart` |
| 2 | `completeStep1` no existe en ningún datasource ni repositorio | — |
| 3 | `completeStep2` URL incorrecta: `/complete-step-2` vs spec `/step-2/complete` | `personal_info_remote_data_source.dart` |
| 4 | `completeStep3` URL incorrecta + falta `club_type` en body | `club_selection_remote_data_source.dart` |
| 5 | `getClubInstances` parsea lista plana pero el API devuelve objeto por buckets (`adventurers`, `pathfinders`, `master_guilds`) — `clubTypeSlug` no existe en el modelo | `club_selection_remote_data_source.dart` + `club_instance_model.dart` |
| 6 | `_onContinue()` en el shell solo navega — no llama ningún endpoint de completitud | `post_registration_shell.dart` |

---

## API Contract

### GET /auth/profile/completion-status
```json
{
  "data": {
    "complete": false,
    "steps": {
      "profilePicture": true,
      "personalInfo": false,
      "clubSelection": false
    },
    "nextStep": "personalInfo"
  }
}
```

**Reglas de navegación:**
- `nextStep == "profilePicture"` → currentStep = 1
- `nextStep == "personalInfo"` → currentStep = 2
- `nextStep == "clubSelection"` → currentStep = 3
- `complete == true && nextStep == null` → onboarding terminado → navegar al home directamente
- `complete == false && nextStep == null` → fallback a currentStep = 1

### Endpoints de completitud
- `POST /users/{userId}/post-registration/step-1/complete` — sin body
- `POST /users/{userId}/post-registration/step-2/complete` — sin body (validaciones en backend)
- `POST /users/{userId}/post-registration/step-3/complete` — body con selección de club

**Body step 3:**
```json
{
  "country_id": 1,
  "union_id": 1,
  "local_field_id": 1,
  "club_type": "adventurers",
  "club_instance_id": 1,
  "class_id": 1
}
```
`club_type` acepta exactamente: `adventurers | pathfinders | master_guild`

### GET /clubs/{clubId}/instances
Devuelve objeto con buckets por tipo (no lista plana):
```json
{
  "adventurers": [{ "id": 1, "club_type_id": 1, "club_id": 5 }],
  "pathfinders": [{ "id": 2, "club_type_id": 2, "club_id": 5 }],
  "master_guilds": [{ "id": 3, "club_type_id": 3, "club_id": 5 }]
}
```
Normalización requerida: `master_guilds → master_guild` al enviar step 3.

---

## Diseño por Capa

### Capa 1 — Data Parsing

**`completion_status_model.dart`**
- Parsear `json['data']['steps']['profilePicture']`, `['personalInfo']`, `['clubSelection']`
- Usar `json['data']['nextStep']` para determinar `currentStep` según reglas descritas arriba
- Si `complete == true && nextStep == null` → `isComplete = true`, `currentStep = 3` (valor no usado en este caso)

### Capa 2 — Datasources

**`club_instance_model.dart`**
- Agregar campo `final String clubTypeSlug` (el enum slug canónico)
- Constructor recibe `clubTypeSlug` como required
- `fromJson` NO lo parsea directamente (se inyecta desde `getClubInstances`)
- Agregar factory `ClubInstanceModel.fromJsonWithSlug(Map json, String slug)`

**`club_selection_remote_data_source.dart`**
- `getClubInstances`: cambiar parsing de `response.data as List` a iteración por buckets del objeto:
  - Normalizar: `master_guilds → master_guild`
  - Crear instancias con `ClubInstanceModel.fromJsonWithSlug(item, normalizedSlug)`
- `completeStep3`:
  - Corregir URL: `/users/$userId/post-registration/step-3/complete`
  - Agregar parámetro `required String clubTypeSlug`
  - Agregar `'club_type': clubTypeSlug` al body del request
  - Signature nueva: `completeStep3({userId, countryId, unionId, localFieldId, clubTypeSlug, clubInstanceId, classId})`

**`personal_info_remote_data_source.dart`**
- Corregir URL `completeStep2`: `/users/$userId/post-registration/step-2/complete`

**`post_registration_remote_data_source.dart`**
- Agregar método `completeStep1(String userId)`:
  - `POST /users/$userId/post-registration/step-1/complete`
  - Sin body
  - Lanza `ServerException` en error no-2xx

### Capa 3 — Repository

**`post_registration_repository.dart` (interface)**
- Agregar: `Future<Either<Failure, void>> completeStep1();`

**`post_registration_repository_impl.dart`**
- Implementar `completeStep1()` con guard de conectividad + try/catch

### Capa 4 — Providers

**`club_selection_providers.dart`**
- Agregar `selectedClubTypeSlugProvider = StateProvider<String?>((ref) => null)`
- En `clubInstancesProvider`, al hacer auto-selección, también setear `selectedClubTypeSlugProvider`
- Al seleccionar instancia manualmente (en el widget), también setear `selectedClubTypeSlugProvider`
- Actualizar `canCompleteStep3Provider` para incluir `selectedClubTypeSlugProvider != null`
- Actualizar `completeStep3` call en el datasource para incluir `clubTypeSlug`

### Capa 4 — Shell

**`post_registration_shell.dart`**

`_loadCompletionStatus()`: si `status.isComplete == true` → `context.go(RouteNames.homeDashboard)` directamente.

`_onContinue()` convertir a `async`:

```
Step 1:
  → await repository.completeStep1(userId)
  → si error: SnackBar con mensaje, return (no navegar)
  → si éxito: _goToStep(2)

Step 2:
  → savePersonalInfoProvider ya llama updatePersonalInfo + completeStep2
    (verificado en personal_info_providers.dart línea 310)
  → await ref.read(savePersonalInfoProvider)()
  → si error: SnackBar con mensaje del backend, return
  → si éxito: _goToStep(3)

Step 3:
  → ref.read(isSavingStep3Provider.notifier).state = true (deshabilita botón)
  → try:
      await dataSource.completeStep3(...)
  → catch 409 / "ya completado": tratar como éxito (idempotencia)
  → catch otros errores: SnackBar + return
  → finally: ref.read(isSavingStep3Provider.notifier).state = false
  → actualizar auth cache (ambos flags):
      final user = ref.read(authNotifierProvider).valueOrNull!
      final updated = UserEntity(
        id: user.id, email: user.email, name: user.name,
        avatar: user.avatar,
        postRegisterComplete: true,  // flag principal del router
      )
      ref.read(authNotifierProvider.notifier).state = AsyncValue.data(updated)
      // También actualizar SharedPreferences cache
      prefs.setString('cached_user_id', updated.id)
      prefs.setBool('cached_post_register_complete', true)
  → context.go(RouteNames.homeDashboard)
```

---

## Idempotencia (Step 3)

- El botón se deshabilita via `isSavingStep3Provider` durante la llamada → no double-tap
- Error 409 (Conflict) se trata como éxito → procede al home
- Otros errores: SnackBar descriptivo, no se navega

## Validación savePersonalInfoProvider (Step 2)

`savePersonalInfoProvider` en `personal_info_providers.dart:309-310`:
```dart
// Completar paso 2
await dataSource.completeStep2(userId);
```
Ya incluye la llamada. El shell solo necesita invocarla y manejar su error. No hay duplicación.

---

## Archivos a modificar

1. `lib/features/post_registration/data/models/completion_status_model.dart`
2. `lib/features/post_registration/data/models/club_instance_model.dart`
3. `lib/features/post_registration/data/datasources/post_registration_remote_data_source.dart`
4. `lib/features/post_registration/data/datasources/personal_info_remote_data_source.dart`
5. `lib/features/post_registration/data/datasources/club_selection_remote_data_source.dart`
6. `lib/features/post_registration/domain/repositories/post_registration_repository.dart`
7. `lib/features/post_registration/data/repositories/post_registration_repository_impl.dart`
8. `lib/features/post_registration/presentation/providers/club_selection_providers.dart`
9. `lib/features/post_registration/presentation/views/post_registration_shell.dart`
