# Estandarización de Riverpod — sacdia-app

> **Fecha**: 23 de febrero de 2026
> **Tipo**: Refactor / Corrección de deuda técnica
> **Rama**: `development`
> **App**: `sacdia-app` (Flutter)

---

## 1. Resumen Ejecutivo

Se realizó una auditoría y corrección completa del uso de Riverpod en la app Flutter de SACDIA. Se identificaron y resolvieron 7 categorías de brechas que causaban inconsistencia en patrones de estado, un bug de correctness en la configuración de Dio, y código muerto.

**Resultado final:**

| Métrica | Antes | Después |
|---------|-------|---------|
| `flutter analyze` errors | 0 | 0 |
| `StateNotifier` deprecated | 4 instancias | 0 |
| `ChangeNotifier` en Riverpod | 1 | 0 |
| `dioProvider` duplicados | 2 | 1 (canónico) |
| `setState` redundante en vistas auth | 2 vistas | 0 |
| Providers sin consumidores | 3 | 0 |
| Dependencias no utilizadas | 2 | 0 |

---

## 2. Brechas Identificadas y Correcciones

### 2.1 `dioProvider` Duplicado (Bug de Correctness)

**Problema:** `auth_providers.dart` declaraba su propio `dioProvider` con un `Dio` sin configurar (sin interceptores, sin timeouts del `DioClient`). Todos los features que importaban `dioProvider` desde `auth_providers.dart` (transitivamente) usaban esta instancia sin interceptores en lugar del `DioClient.createDio()` canónico definido en `lib/providers/dio_provider.dart`.

**Features afectados:** `auth`, `honors`, `classes`, `activities`, `dashboard`, `post_registration`, `profile`.

**Corrección:**
- Se eliminó el bloque `dioProvider` inline de `auth_providers.dart`
- Se agregó `import '../../../../providers/dio_provider.dart'` al archivo
- Se agregaron imports directos a `dio_provider.dart` en los 8 archivos de providers que resolvían el símbolo transitivamente

**Commit:** `6b35136`

---

### 2.2 Migración de `StateNotifier` → `AsyncNotifier`

**Problema:** Tres features usaban el patrón `StateNotifier<AsyncValue<T>>` / `StateNotifierProvider` de Riverpod 1.x (deprecado desde Riverpod 2.0). El resto del proyecto (`auth`, `dashboard`, `profile`, `post_registration`) ya usaba el patrón moderno `AsyncNotifier<T>` / `AsyncNotifierProvider`.

**Patrón deprecado:**
```dart
class HonorEnrollmentNotifier extends StateNotifier<AsyncValue<UserHonor?>> {
  final StartHonor startHonor;
  HonorEnrollmentNotifier(this.startHonor) : super(const AsyncValue.data(null));
  // ...
}
final honorEnrollmentNotifierProvider =
    StateNotifierProvider<HonorEnrollmentNotifier, AsyncValue<UserHonor?>>((ref) {
  return HonorEnrollmentNotifier(ref.read(startHonorProvider));
});
```

**Patrón moderno (aplicado):**
```dart
class HonorEnrollmentNotifier extends AsyncNotifier<UserHonor?> {
  @override
  Future<UserHonor?> build() async => null;

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
final honorEnrollmentNotifierProvider =
    AsyncNotifierProvider<HonorEnrollmentNotifier, UserHonor?>(() {
  return HonorEnrollmentNotifier();
});
```

**Diferencias clave del patrón moderno:**
- La clase extiende `AsyncNotifier<T>` (no `StateNotifier<AsyncValue<T>>`)
- El tipo del provider es `T` directamente (no `AsyncValue<T>`)
- `build()` retorna el estado inicial — no hay constructor con parámetros
- Las dependencias se leen con `ref.read(...)` dentro de los métodos (no inyección por constructor)
- El provider usa `AsyncNotifierProvider` (no `StateNotifierProvider`)

**Archivos migrados:**

| Feature | Notifier | Commit |
|---------|----------|--------|
| `honors` | `HonorEnrollmentNotifier` | `3f5f851` |
| `activities` | `AttendanceNotifier` | `465aa97` |
| `classes` | `ClassProgressNotifier` | `de386f3` |

---

### 2.3 Feature `home` — Datos Mock y Duplicación

**Problema:**
- `HomeNotifier` usaba `Future.delayed` con **datos hardcodeados** en lugar de datos reales de la API
- `HomeView` hacía llamadas manuales a `SharedPreferences.remove(...)` para el logout, duplicando lógica que ya maneja `authNotifierProvider.signOut()`
- `DashboardEntity` en `home/domain/entities/` duplicaba `DashboardSummary` del feature `dashboard`
- `home_repository.dart` declaraba una interfaz sin implementación

**Corrección:**
- `HomeView` ahora consume `dashboardNotifierProvider` (datos reales del feature `dashboard`)
- `_handleLogout` delega a `ref.read(authNotifierProvider.notifier).signOut()` sin tocar `SharedPreferences`
- Se eliminaron `DashboardEntity`, `home_repository.dart` y los directorios `domain/` vacíos del feature `home`
- `home_providers.dart` se convirtió en un shim de re-exportación para compatibilidad

**Commit:** `6637442`

---

### 2.4 `setState` Redundante en Vistas de Auth

**Problema:** `LoginView` y `RegisterView` mantenían `_isLoading` y `_errorMessage` con `setState`, creando una fuente de verdad duplicada. El `authNotifierProvider` ya expone `AsyncValue` con `.isLoading` y `.error`.

**Antes (LoginView):**
```dart
bool _isLoading = false;
String? _errorMessage;

Future<void> _signIn() async {
  setState(() { _isLoading = true; _errorMessage = null; });
  try {
    final success = await ref.read(authNotifierProvider.notifier).signIn(...);
    if (!success && mounted) setState(() { _errorMessage = 'Credenciales incorrectas'; });
  } catch (e) {
    if (mounted) setState(() { _errorMessage = 'Error al iniciar sesión'; });
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

**Después:**
```dart
// En build():
final authState = ref.watch(authNotifierProvider);
final isLoading = authState.isLoading;
final errorMessage = authState.hasError
    ? (authState.error?.toString() ?? 'Error al iniciar sesión')
    : null;

// El método simplificado:
Future<void> _signIn() async {
  if (!_formKey.currentState!.validate()) return;
  await ref.read(authNotifierProvider.notifier).signIn(
    email: _emailController.text.trim(),
    password: _passwordController.text.trim(),
  );
  // Navegación manejada por el router que observa authNotifierProvider.
  // Error surfaced via ref.watch.
}
```

> **Nota:** `_isButtonEnabled` en `RegisterView` se mantiene como estado local porque deriva de los controllers de texto, no del estado de autenticación.

**Commits:** `5ba9acb` (LoginView), `2edd6a3` (RegisterView)

---

### 2.5 `ThemeProvider` — `ChangeNotifier` → `NotifierProvider`

**Problema:** `ThemeProvider extends ChangeNotifier` era el único `ChangeNotifier` del proyecto, inconsistente con todos los demás providers.

**Corrección:** Migración a `ThemeNotifier extends Notifier<ThemeMode>`. El estado es directamente el `ThemeMode`. Las propiedades estáticas `lightTheme` y `darkTheme` se leen desde `AppTheme` directamente en `MyApp`.

```dart
class ThemeNotifier extends Notifier<ThemeMode> {
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
    await ref.read(sharedPreferencesProvider).setString(AppConstants.themeKey, 'light');
  }
  // setDarkTheme / setSystemTheme / toggleTheme — misma estructura
}

final themeNotifierProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});
```

**Commit:** `bdd14de`

---

### 2.6 Providers Sin Consumidores — `core/auth/auth_providers.dart`

**Problema:** `lib/core/auth/auth_providers.dart` declaraba tres providers (`authStateProvider`, `currentUserProvider`, `isAuthenticatedProvider`) que **nunca fueron consumidos** en ninguna parte del proyecto.

**Corrección:** Eliminación del archivo.

**Commit:** `2a9d40e`

---

### 2.7 Dependencias No Utilizadas — `riverpod_generator`

**Problema:** `pubspec.yaml` incluía `riverpod_annotation: ^2.6.1` (dep) y `riverpod_generator: ^2.6.5` (dev dep) pero ningún archivo del proyecto usa la anotación `@riverpod`. Añadían overhead de build sin beneficio.

**Corrección:** Se eliminaron ambas entradas del `pubspec.yaml`. `build_runner` se mantiene (usado por `freezed` y `json_serializable`).

**Commit:** `79512b0`

---

## 3. Patrones Estándar de Riverpod en sacdia-app

Después de esta estandarización, los patrones oficiales del proyecto son:

### Provider de solo lectura (datos de API)
```dart
final myDataProvider = FutureProvider.autoDispose<MyEntity>((ref) async {
  final result = await ref.read(myUseCaseProvider)(params);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (data) => data,
  );
});
```

### Notifier con mutaciones (CRUD, acciones)
```dart
class MyNotifier extends AsyncNotifier<MyEntity?> {
  @override
  Future<MyEntity?> build() async {
    // Cargar estado inicial o retornar null si no aplica
    return null;
  }

  Future<void> doAction(Params params) async {
    state = const AsyncValue.loading();
    final result = await ref.read(myUseCaseProvider)(params);
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (data) => AsyncValue.data(data),
    );
  }
}

final myNotifierProvider = AsyncNotifierProvider<MyNotifier, MyEntity?>(() {
  return MyNotifier();
});
```

### Consumo en vistas
```dart
class MyView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myNotifierProvider);

    return state.when(
      loading: () => const Center(child: SacLoading()),
      error: (error, _) => ErrorWidget(message: error.toString()),
      data: (data) => MyContent(data: data),
    );
  }
}
```

### Reglas de `ref.watch` vs `ref.read`
- `ref.watch` → en `build()` para estado reactivo
- `ref.read` → en callbacks (`onPressed`, `onRefresh`) y dentro de métodos de Notifier

---

## 4. Checklist de Verificación

Al crear un nuevo feature o provider, verificar:

- [ ] Usa `AsyncNotifier<T>` (no `StateNotifier<AsyncValue<T>>`)
- [ ] Usa `AsyncNotifierProvider` (no `StateNotifierProvider`)
- [ ] No declara `dioProvider` localmente — importa de `lib/providers/dio_provider.dart`
- [ ] No usa `ChangeNotifier` ni `notifyListeners()`
- [ ] Las vistas no mantienen `_isLoading`/`_errorMessage` con `setState` si el provider ya expone `AsyncValue`
- [ ] No hay providers declarados sin consumidores

---

## 5. Historial de Commits

```
2a9d40e chore: remove unused core/auth/auth_providers.dart
79512b0 chore: remove unused riverpod_generator and riverpod_annotation dependencies
bdd14de refactor: migrate ThemeProvider from ChangeNotifier to NotifierProvider<ThemeMode>
2edd6a3 refactor: derive loading/error state in RegisterView from authNotifierProvider, remove setState
5ba9acb refactor: derive loading/error state in LoginView from authNotifierProvider, remove setState
6637442 refactor: replace home mock data with real dashboardNotifierProvider, remove manual SharedPreferences logout
de386f3 refactor: migrate ClassProgressNotifier from StateNotifier to AsyncNotifier
465aa97 refactor: migrate AttendanceNotifier from StateNotifier to AsyncNotifier
3f5f851 refactor: migrate HonorEnrollmentNotifier from StateNotifier to AsyncNotifier
6b35136 fix: consolidate dioProvider to use configured DioClient with interceptors
```
