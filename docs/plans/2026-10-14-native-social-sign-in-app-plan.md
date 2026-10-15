# Native Social Sign-In — App (Flutter) Implementation Plan

> Implementado con cambios; ver el bloque «Estado de implementación» del diseño. Donde el código difiere, manda el código.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The login screen offers "Continuar con Google" (iOS and Android) and "Continuar con Apple" (iOS only); both use the native SDK, post the `idToken` to `POST /auth/oauth/:provider/token` and land the user in the same post-login flow as email/password. Account deletion works for users without a password by re-authenticating with the provider. The browser/deep-link OAuth flow is removed.

**Architecture:** A `SocialAuthClient` in `lib/core/auth/` wraps `google_sign_in` and `sign_in_with_apple` behind one interface that returns a `SocialCredential` (or `null` on cancel) — the only thing tests mock. `AuthRemoteDataSourceImpl` uses it in `signInWithGoogle/Apple`, parses the backend response with the same code as `/auth/login`, and persists tokens as before. Repository, use cases, `AuthNotifier` and views keep their boundaries; only their internals change.

**Tech Stack:** Flutter 3.41.6 (installed; `pubspec` `sdk: ^3.6.1`), Riverpod 2, Dio 5, easy_localization, `google_sign_in` ^7.2.0, `sign_in_with_apple` ^8.1.0 (8.2.0 needs Flutter 3.44), `crypto` ^3.0.6, `flutter_svg` (already present; `assets/svg/google_logo.svg` and `apple_logo.svg` exist).

**Spec:** `docs/plans/2026-10-14-native-social-sign-in-design.md` §3, §5, §6, §7. **Backend contract:** `docs/plans/2026-10-14-native-social-sign-in-backend-plan.md` Tasks 8–10.

**Repo:** `sacdia-app`, base `origin/development` at `c8919e75` or later. Conventions: conventional commits, no attribution trailers, no `git stash`, worktrees under `/Users/abner/Documents/development/sacdia-worktrees/`, CI runs `dart format --set-exit-if-changed`, `flutter analyze --no-fatal-warnings --no-fatal-infos`, `flutter test --no-pub`. The main app checkout has uncommitted edits in `assets/translations/*.json` from another session: never work in it, always in a worktree from `origin/development`.

**Slices → PRs:** A1 = Tasks 1–9 (login), A2 = Tasks 10–13 (account deletion). A1 is testable end-to-end only after backend B2 is live on Render with `GOOGLE_OAUTH_AUDIENCES` and `APPLE_BUNDLE_ID` set; A2 needs B3 live.

---

## File map

| File | Responsibility |
|---|---|
| `lib/core/auth/social_credential.dart` | `SocialProvider`, `SocialCredential`, nonce helpers (pure Dart, unit-tested) |
| `lib/core/auth/social_auth_client.dart` | `SocialAuthClient` interface + `NativeSocialAuthClient` (SDK wrapper, not unit-tested) |
| `lib/core/auth/social_auth_provider.dart` | Riverpod provider for the client |
| `lib/core/constants/app_constants.dart` | `googleServerClientId` from `--dart-define=GOOGLE_SERVER_CLIENT_ID` |
| `lib/core/errors/exceptions.dart`, `failures.dart` | `SocialSignInCancelledException` / `SocialSignInCancelledFailure` replace the `OAuthFlowInitiated*` pair |
| `lib/features/auth/data/datasources/auth_remote_data_source.dart` | `signInWithGoogle/Apple` via the client + `POST /auth/oauth/:provider/token`; shared session parser; `handleOAuthCallback` removed; (A2) `deleteAccount(DeleteAccountReauth)`, `getConnectedProviders()` |
| `lib/features/auth/domain/repositories/auth_repository.dart`, `data/repositories/auth_repository_impl.dart` | Mapping of the cancel failure; callback removed; (A2) reauth type |
| `lib/features/auth/domain/entities/delete_account_reauth.dart` (A2) | Sealed reauth type |
| `lib/features/auth/presentation/providers/auth_providers.dart` | `SocialSignInResult`, `signInWithGoogle/Apple`, `processOAuthDeepLink` removed; (A2) `deleteAccount(DeleteAccountReauth)` |
| `lib/features/auth/presentation/widgets/social_sign_in_buttons.dart` | Divider + Google/Apple buttons |
| `lib/features/auth/presentation/views/login_view.dart` | Mounts the buttons |
| `lib/core/config/router.dart`, `route_names.dart` | `_OAuthCallbackScreen` and `/auth/callback` removed |
| `lib/core/auth/app_auth_service.dart` | `initiateOAuth`, `persistOAuthTokens` removed |
| `lib/features/profile/presentation/views/settings_view.dart` (A2) | Delete dialog with provider confirmation |
| `assets/translations/{en,es,fr,pt-BR}.json` | New keys; old OAuth-browser keys removed |
| `ios/Runner/Info.plist`, `ios/Runner/Runner.entitlements`, `ios/Runner/Runner.debug.entitlements`, `android/app/src/main/AndroidManifest.xml` | Google URL scheme + client ID, Sign in with Apple entitlement, OAuth App Link filter removed |
| `test/core/auth/social_credential_test.dart`, `test/features/auth/data/social_sign_in_datasource_test.dart`, `test/features/auth/data/delete_account_test.dart`, `test/features/auth/data/auth_repository_impl_test.dart`, `test/features/auth/presentation/providers/social_sign_in_notifier_test.dart` | Tests |

---

## Slice A1 — login with Google and Apple

### Task 1: Worktree, dependencies, dart-define

**Files:**
- Modify: `pubspec.yaml`, `pubspec.lock`
- Modify: `lib/core/constants/app_constants.dart:7-14`

- [ ] **Step 1: Create the worktree**

```bash
git -C /Users/abner/Documents/development/sacdia/sacdia-app fetch origin development && git -C /Users/abner/Documents/development/sacdia/sacdia-app worktree add -b feat/native-social-sign-in /Users/abner/Documents/development/sacdia-worktrees/app-social-a1 origin/development && cd /Users/abner/Documents/development/sacdia-worktrees/app-social-a1 && flutter pub get
```

- [ ] **Step 2: Add the dependencies**

In `pubspec.yaml`, under `dependencies:` after the `# Utilidades` block's `local_auth_darwin: ^1.6.1` line, add:

```yaml

  # Login social nativo (idToken → POST /auth/oauth/:provider/token)
  google_sign_in: ^7.2.0
  sign_in_with_apple: ^8.1.0   # 8.2.0 requiere Flutter 3.44
  crypto: ^3.0.6               # SHA-256 del nonce para Apple
```

Then:

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/app-social-a1 && flutter pub get && rg -n "^  (google_sign_in|sign_in_with_apple|crypto):" -A1 pubspec.lock
```
Expected: `google_sign_in` 7.2.x, `sign_in_with_apple` 8.1.x, `crypto` 3.0.x resolved.

- [ ] **Step 3: Add the Google server client ID define**

In `lib/core/constants/app_constants.dart`, after `static const String apiBaseUrlDefineKey = 'API_BASE_URL';` add:

```dart
  static const String googleServerClientIdDefineKey = 'GOOGLE_SERVER_CLIENT_ID';

  /// Client ID **Web** de Google Cloud. Es la `aud` del idToken que valida el
  /// backend (`GOOGLE_OAUTH_AUDIENCES`). Sin él, el botón de Google se oculta.
  /// Pasar con `--dart-define=GOOGLE_SERVER_CLIENT_ID=...apps.googleusercontent.com`.
  static const String googleServerClientId =
      String.fromEnvironment(googleServerClientIdDefineKey);
```

- [ ] **Step 4: Commit**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/app-social-a1 && dart format lib/core/constants/app_constants.dart && git add pubspec.yaml pubspec.lock lib/core/constants/app_constants.dart && git commit -m "build(auth): add google_sign_in, sign_in_with_apple and the Google server client ID define"
```

---

### Task 2: `SocialCredential` and nonce helpers

**Files:**
- Create: `lib/core/auth/social_credential.dart`
- Test: `test/core/auth/social_credential_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sacdia_app/core/auth/social_credential.dart';

void main() {
  group('SocialProvider', () {
    test('wireName matches the backend route segment', () {
      expect(SocialProvider.google.wireName, 'google');
      expect(SocialProvider.apple.wireName, 'apple');
    });
  });

  group('generateNonce', () {
    test('returns a base64url string of at least 43 chars', () {
      final nonce = generateNonce();
      expect(nonce.length, greaterThanOrEqualTo(43));
      expect(RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(nonce), isTrue);
    });

    test('is unique per call', () {
      expect(generateNonce(), isNot(generateNonce()));
    });
  });

  group('sha256Hex', () {
    test('matches package:crypto lowercase hex', () {
      const raw = 'raw-nonce-123';
      expect(sha256Hex(raw), sha256.convert(utf8.encode(raw)).toString());
    });
  });

  group('SocialCredential.toSignInBody', () {
    test('serialises only the fields that are set', () {
      const credential = SocialCredential(
        provider: SocialProvider.google,
        idToken: 'id-token',
        nonce: 'nonce-1',
      );
      expect(credential.toSignInBody(), {'idToken': 'id-token', 'nonce': 'nonce-1'});
    });

    test('includes the Apple authorization code and full name', () {
      const credential = SocialCredential(
        provider: SocialProvider.apple,
        idToken: 'id-token',
        nonce: 'nonce-1',
        authorizationCode: 'code-1',
        givenName: 'Ana',
        familyName: 'Pérez',
      );
      expect(credential.toSignInBody(), {
        'idToken': 'id-token',
        'nonce': 'nonce-1',
        'authorizationCode': 'code-1',
        'fullName': {'givenName': 'Ana', 'familyName': 'Pérez'},
      });
    });

    test('omits fullName when both parts are null', () {
      const credential = SocialCredential(
        provider: SocialProvider.apple,
        idToken: 'id-token',
        nonce: 'nonce-1',
        authorizationCode: 'code-1',
      );
      expect(credential.toSignInBody().containsKey('fullName'), isFalse);
    });
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/app-social-a1 && flutter test test/core/auth/social_credential_test.dart
```
Expected: compile error — `social_credential.dart` does not exist.

- [ ] **Step 3: Implement**

`lib/core/auth/social_credential.dart`:

```dart
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Proveedores de login social soportados por el backend
/// (`POST /auth/oauth/:provider/token`).
enum SocialProvider {
  google('google'),
  apple('apple');

  const SocialProvider(this.wireName);

  /// Segmento de ruta y valor de `providerId` en el backend.
  final String wireName;
}

/// Resultado del SDK nativo listo para enviar al backend.
///
/// - [nonce] es el valor en claro. Google lo copia tal cual al `idToken`;
///   a Apple se le envía `sha256Hex(nonce)` y el backend vuelve a hashear.
/// - [authorizationCode] solo Apple: el backend lo canjea por el refresh
///   token que necesita para revocar al borrar la cuenta.
/// - [givenName]/[familyName] solo Apple y solo en el primer login.
class SocialCredential {
  const SocialCredential({
    required this.provider,
    required this.idToken,
    required this.nonce,
    this.authorizationCode,
    this.givenName,
    this.familyName,
  });

  final SocialProvider provider;
  final String idToken;
  final String nonce;
  final String? authorizationCode;
  final String? givenName;
  final String? familyName;

  /// Cuerpo de `POST /auth/oauth/:provider/token` (SocialTokenSignInDto).
  Map<String, dynamic> toSignInBody() {
    final fullName = <String, String>{
      if (givenName != null && givenName!.isNotEmpty) 'givenName': givenName!,
      if (familyName != null && familyName!.isNotEmpty)
        'familyName': familyName!,
    };
    return {
      'idToken': idToken,
      'nonce': nonce,
      if (authorizationCode != null) 'authorizationCode': authorizationCode,
      if (fullName.isNotEmpty) 'fullName': fullName,
    };
  }

  /// Cuerpo de re-autenticación para `DELETE /auth/me`.
  Map<String, dynamic> toReauthBody() => {
        'provider': provider.wireName,
        'idToken': idToken,
        'nonce': nonce,
      };
}

final _random = Random.secure();

/// 32 bytes aleatorios en base64url (43 chars). Uno por intento de login.
String generateNonce() {
  final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

/// SHA-256 en hex minúsculas — formato que espera Apple y el backend.
String sha256Hex(String value) => sha256.convert(utf8.encode(value)).toString();
```

- [ ] **Step 4: Run the test, format, commit**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/app-social-a1 && flutter test test/core/auth/social_credential_test.dart && dart format lib/core/auth test/core/auth && git add lib/core/auth/social_credential.dart test/core/auth/social_credential_test.dart && git commit -m "feat(auth): add SocialCredential and nonce helpers"
```
Expected: 7 tests pass.

---

### Task 3: `SocialAuthClient` and its provider

**Files:**
- Create: `lib/core/auth/social_auth_client.dart`
- Create: `lib/core/auth/social_auth_provider.dart`

The native client is a thin SDK wrapper; it is exercised on device (Task 9 manual check), not in unit tests. Everything above it mocks `SocialAuthClient`.

- [ ] **Step 1: Write the interface and the native implementation**

`lib/core/auth/social_auth_client.dart`:

```dart
import 'dart:io' show Platform;

import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../utils/app_logger.dart';
import 'social_credential.dart';

/// Abre la hoja nativa del proveedor y devuelve el `idToken`.
///
/// Devuelve `null` cuando el usuario cancela. Cualquier otro fallo del SDK
/// se propaga como [SocialAuthException].
abstract class SocialAuthClient {
  Future<SocialCredential?> signIn(SocialProvider provider);

  /// Google en ambas plataformas; Apple solo en iOS (spec D5).
  bool supports(SocialProvider provider);
}

class SocialAuthException implements Exception {
  SocialAuthException(this.provider, this.message);

  final SocialProvider provider;
  final String message;

  @override
  String toString() => 'SocialAuthException(${provider.wireName}): $message';
}

class NativeSocialAuthClient implements SocialAuthClient {
  NativeSocialAuthClient({required String googleServerClientId})
      : _googleServerClientId = googleServerClientId;

  static const _tag = 'SocialAuth';

  final String _googleServerClientId;

  @override
  bool supports(SocialProvider provider) => switch (provider) {
        SocialProvider.google => _googleServerClientId.isNotEmpty,
        SocialProvider.apple => Platform.isIOS,
      };

  @override
  Future<SocialCredential?> signIn(SocialProvider provider) {
    if (!supports(provider)) {
      throw SocialAuthException(provider, 'not supported on this platform');
    }
    return switch (provider) {
      SocialProvider.google => _signInWithGoogle(),
      SocialProvider.apple => _signInWithApple(),
    };
  }

  Future<SocialCredential?> _signInWithGoogle() async {
    final nonce = generateNonce();
    try {
      // google_sign_in 7 fija el nonce en initialize(); se reinicializa por
      // intento para que cada idToken lleve un nonce nuevo.
      await GoogleSignIn.instance.initialize(
        serverClientId: _googleServerClientId,
        nonce: nonce,
      );
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw SocialAuthException(SocialProvider.google, 'no idToken returned');
      }
      return SocialCredential(
        provider: SocialProvider.google,
        idToken: idToken,
        nonce: nonce,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        AppLogger.i('Google sign-in cancelado', tag: _tag);
        return null;
      }
      AppLogger.w('Google sign-in falló: ${e.code} ${e.description}', tag: _tag);
      throw SocialAuthException(SocialProvider.google, e.description ?? e.code.name);
    }
  }

  Future<SocialCredential?> _signInWithApple() async {
    final nonce = generateNonce();
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        // Apple embebe este valor tal cual en el idToken; el backend compara
        // contra sha256Hex(nonce) y recibe el nonce en claro.
        nonce: sha256Hex(nonce),
      );
      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw SocialAuthException(SocialProvider.apple, 'no identityToken returned');
      }
      return SocialCredential(
        provider: SocialProvider.apple,
        idToken: idToken,
        nonce: nonce,
        authorizationCode: credential.authorizationCode,
        givenName: credential.givenName,
        familyName: credential.familyName,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        AppLogger.i('Apple sign-in cancelado', tag: _tag);
        return null;
      }
      AppLogger.w('Apple sign-in falló: ${e.code} ${e.message}', tag: _tag);
      throw SocialAuthException(SocialProvider.apple, e.message);
    }
  }
}
```

- [ ] **Step 2: Write the provider**

`lib/core/auth/social_auth_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import 'social_auth_client.dart';

/// Cliente de login social. Los tests lo sobreescriben con un fake.
final socialAuthClientProvider = Provider<SocialAuthClient>((ref) {
  return NativeSocialAuthClient(
    googleServerClientId: AppConstants.googleServerClientId,
  );
});
```

- [ ] **Step 3: Analyze and commit**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/app-social-a1 && dart format lib/core/auth && flutter analyze --no-fatal-warnings --no-fatal-infos lib/core/auth && git add lib/core/auth && git commit -m "feat(auth): wrap the Google and Apple SDKs in SocialAuthClient"
```
Expected: no analyzer errors. If `GoogleSignIn.instance.initialize` throws on the second call on some platform (re-initialize is not documented), fall back to initializing once per app session in the provider and reusing that nonce for the session — and note it in the PR; the backend still rejects tokens whose nonce does not match.

---

### Task 4: Cancel exception/failure replace the browser-flow pair

**Files:**
- Modify: `lib/core/errors/exceptions.dart:73-86`
- Modify: `lib/core/errors/failures.dart:95-112`

- [ ] **Step 1: Replace `OAuthFlowInitiatedException`**

In `lib/core/errors/exceptions.dart` replace the whole `OAuthFlowInitiatedException` class (from its doc comment to its closing brace) with:

```dart
/// El usuario cerró la hoja nativa de Google/Apple sin completar el login.
/// No es un error: la UI vuelve al login sin mensaje.
class SocialSignInCancelledException extends AppException {
  SocialSignInCancelledException()
      : super(message: tr('errors.social_signin_cancelled'));
}
```

- [ ] **Step 2: Replace `OAuthFlowInitiatedFailure`**

In `lib/core/errors/failures.dart` replace the whole `OAuthFlowInitiatedFailure` class with:

```dart
/// El usuario canceló la hoja nativa de Google/Apple. No se muestra error.
class SocialSignInCancelledFailure extends Failure {
  SocialSignInCancelledFailure()
      : super(message: tr('errors.social_signin_cancelled'));
}
```

- [ ] **Step 3: Verify nothing else references the old names yet**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/app-social-a1 && rg -n "OAuthFlowInitiated" lib test
```
Expected: hits only in `auth_repository_impl.dart` and `auth_providers.dart` (fixed in Tasks 6 and 7). Commit after Task 7 so the tree compiles at each commit.

---

### Task 5: Datasource — native sign-in and shared session parser

**Files:**
- Modify: `lib/features/auth/data/datasources/auth_remote_data_source.dart`
- Test: `test/features/auth/data/social_sign_in_datasource_test.dart`

- [ ] **Step 1: Write the failing test**

`test/features/auth/data/social_sign_in_datasource_test.dart`:

```dart
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sacdia_app/core/auth/social_auth_client.dart';
import 'package:sacdia_app/core/auth/social_credential.dart';
import 'package:sacdia_app/core/constants/app_constants.dart';
import 'package:sacdia_app/core/errors/exceptions.dart';
import 'package:sacdia_app/core/storage/secure_storage.dart';
import 'package:sacdia_app/features/auth/data/datasources/auth_remote_data_source.dart';

class _FakeSecureStorage implements SecureStorage {
  final _store = <String, String>{};

  @override
  Future<void> write(String key, String value) async => _store[key] = value;
  @override
  Future<String?> read(String key) async => _store[key];
  @override
  Future<bool> contains(String key) async => _store.containsKey(key);
  @override
  Future<void> delete(String key) async => _store.remove(key);
  @override
  Future<void> deleteAll() async => _store.clear();
  @override
  Future<Map<String, String>> readAll() async => Map.unmodifiable(_store);
}

class _FakeSocialAuthClient implements SocialAuthClient {
  _FakeSocialAuthClient(this.result);

  final SocialCredential? result;
  SocialProvider? requested;

  @override
  Future<SocialCredential?> signIn(SocialProvider provider) async {
    requested = provider;
    return result;
  }

  @override
  bool supports(SocialProvider provider) => true;
}

/// Adaptador Dio que responde JSON (anidado) con un status fijo.
class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.statusCode, this.body);

  final int statusCode;
  final Object body;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? _, Future<void>? __) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

const _credential = SocialCredential(
  provider: SocialProvider.apple,
  idToken: 'apple-id-token',
  nonce: 'nonce-1',
  authorizationCode: 'code-1',
  givenName: 'Ana',
  familyName: 'Pérez',
);

const _successBody = {
  'status': 'success',
  'data': {
    'accessToken': 'sacdia-jwt',
    'sessionToken': 'opaque',
    'refreshToken': 'opaque',
    'expiresAt': 1900000000,
    'tokenType': 'bearer',
    'user': {
      'id': 'user-1',
      'email': 'ana@example.com',
      'name': 'Ana',
      'paternal_last_name': 'Pérez',
      'maternal_last_name': null,
      'avatar': 'https://r2.example/u1.jpg',
      'connectedProviders': ['apple'],
    },
    'needsPostRegistration': true,
  },
};

void main() {
  late _FakeSecureStorage storage;
  late Dio dio;

  AuthRemoteDataSourceImpl build(SocialAuthClient social) => AuthRemoteDataSourceImpl(
        dio: dio,
        baseUrl: 'http://localhost:3000',
        secureStorage: storage,
        socialAuth: social,
      );

  setUp(() {
    storage = _FakeSecureStorage();
    dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
  });

  test('posts the credential to /auth/oauth/apple/token and persists the session', () async {
    final adapter = _JsonAdapter(201, _successBody);
    dio.httpClientAdapter = adapter;
    final social = _FakeSocialAuthClient(_credential);

    final user = await build(social).signInWithApple();

    expect(social.requested, SocialProvider.apple);
    expect(adapter.lastRequest?.method, 'POST');
    expect(adapter.lastRequest?.uri.path, '/auth/oauth/apple/token');
    expect(adapter.lastRequest?.data, {
      'idToken': 'apple-id-token',
      'nonce': 'nonce-1',
      'authorizationCode': 'code-1',
      'fullName': {'givenName': 'Ana', 'familyName': 'Pérez'},
    });
    expect(user.id, 'user-1');
    expect(user.email, 'ana@example.com');
    expect(user.avatar, 'https://r2.example/u1.jpg');
    expect(user.postRegisterComplete, isFalse);
    expect(await storage.read(AppConstants.tokenKey), 'sacdia-jwt');
    expect(await storage.read(AppConstants.refreshTokenKey), 'opaque');
    expect(await storage.read(AppConstants.expiresAtKey), '1900000000');
    expect(await storage.read(AppConstants.tokenTypeKey), 'bearer');
  });

  test('uses the google route for Google', () async {
    final adapter = _JsonAdapter(201, _successBody);
    dio.httpClientAdapter = adapter;
    final google = SocialCredential(
      provider: SocialProvider.google,
      idToken: 'g-token',
      nonce: 'n',
    );

    await build(_FakeSocialAuthClient(google)).signInWithGoogle();

    expect(adapter.lastRequest?.uri.path, '/auth/oauth/google/token');
    expect(adapter.lastRequest?.data, {'idToken': 'g-token', 'nonce': 'n'});
  });

  test('throws SocialSignInCancelledException and makes no request on cancel', () async {
    final adapter = _JsonAdapter(201, _successBody);
    dio.httpClientAdapter = adapter;

    await expectLater(
      build(_FakeSocialAuthClient(null)).signInWithGoogle(),
      throwsA(isA<SocialSignInCancelledException>()),
    );
    expect(adapter.lastRequest, isNull);
    expect(await storage.read(AppConstants.tokenKey), isNull);
  });

  test('maps a 401 to AuthException with the server message', () async {
    dio.httpClientAdapter = _JsonAdapter(401, {
      'status': 'error',
      'statusCode': 401,
      'code': 'AUTH_INVALID_TOKEN',
      'message': 'Token inválido o expirado',
    });

    await expectLater(
      build(_FakeSocialAuthClient(_credential)).signInWithApple(),
      throwsA(predicate((e) => e is AuthException && e.message == 'Token inválido o expirado' && e.code == 401)),
    );
    expect(await storage.read(AppConstants.tokenKey), isNull);
  });

  test('maps an SDK failure to AuthException', () async {
    final failing = _ThrowingSocialAuthClient();
    await expectLater(
      build(failing).signInWithGoogle(),
      throwsA(isA<AuthException>()),
    );
  });
}

class _ThrowingSocialAuthClient implements SocialAuthClient {
  @override
  Future<SocialCredential?> signIn(SocialProvider provider) async =>
      throw SocialAuthException(provider, 'sdk exploded');
  @override
  bool supports(SocialProvider provider) => true;
}
```

- [ ] **Step 2: Run it to verify it fails**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/app-social-a1 && flutter test test/features/auth/data/social_sign_in_datasource_test.dart
```
Expected: compile error — `socialAuth` is not a named parameter.

- [ ] **Step 3: Implement in the datasource**

In `lib/features/auth/data/datasources/auth_remote_data_source.dart`:

1. Imports: remove `import 'package:url_launcher/url_launcher.dart';`; add after the `app_logger` import:
   ```dart
   import '../../../../core/auth/social_auth_client.dart';
   import '../../../../core/auth/social_credential.dart';
   ```
2. Interface: delete `handleOAuthCallback` and its doc comment (lines 62–71). Keep `signInWithGoogle()` / `signInWithApple()` and update their doc comments to "Login nativo con Google/Apple: abre la hoja del SDK y envía el idToken al backend. Lanza [SocialSignInCancelledException] si el usuario cancela."
3. Constructor: add the field and parameter:
   ```dart
     final SocialAuthClient _socialAuth;
   ```
   and in the constructor `required SocialAuthClient socialAuth,` + `_socialAuth = socialAuth,` in the initializer list.
4. Extract the session parser. Add this private method after `_saveToken`:

```dart
  /// Persiste los tokens y arma el [UserModel] a partir de `data` de
  /// `/auth/login` y `/auth/oauth/:provider/token` (misma forma).
  Future<UserModel> _persistSessionAndBuildUser(
    Map<String, dynamic>? responseData, {
    String fallbackEmail = '',
  }) async {
    if (responseData == null) {
      throw AuthException(message: tr('errors.invalid_response'));
    }

    final token = responseData['accessToken'] as String?;
    if (token == null) {
      throw AuthException(message: tr('errors.missing_token'));
    }

    await _saveToken(
      token,
      refreshToken: responseData['refreshToken'] as String?,
      expiresAt: responseData['expiresAt'] as int?,
      tokenType: responseData['tokenType'] as String?,
    );

    final userData = responseData['user'] as Map<String, dynamic>?;
    final userId = userData?['id'] as String?;
    if (userId == null) {
      throw AuthException(message: tr('errors.missing_user_id'));
    }

    final needsPostRegistration =
        responseData['needsPostRegistration'] as bool? ?? true;

    return UserModel(
      id: userId,
      email: userData?['email'] as String? ?? fallbackEmail,
      name: userData?['name'] as String? ?? '',
      avatar: userData?['image'] as String? ?? userData?['avatar'] as String?,
      postRegisterComplete: !needsPostRegistration,
    );
  }
```

5. In `signInWithEmailAndPassword`, replace everything from `final responseData = response.data['data'] as Map<String, dynamic>?;` down to the `return UserModel(...)` statement (inclusive) with:

```dart
      final user = await _persistSessionAndBuildUser(
        response.data['data'] as Map<String, dynamic>?,
        fallbackEmail: email,
      );
      AppLogger.i('Login exitoso', tag: _tag);
      return user;
```

6. Replace the whole `// ── OAuth ───…` section (the comment block, `signInWithGoogle`, `signInWithApple`, `_extractOAuthUrl`, the `// ── OAuth Callback` comment and `handleOAuthCallback`) with:

```dart
  // ── Login social nativo ──────────────────────────────────────────────────────
  //
  //   1. SocialAuthClient abre la hoja nativa y devuelve idToken + nonce.
  //   2. POST /auth/oauth/{provider}/token con SocialTokenSignInDto.
  //   3. El backend verifica el token, crea o vincula el usuario y devuelve
  //      la misma sesión que /auth/login.

  @override
  Future<UserModel> signInWithGoogle() =>
      _signInWithProvider(SocialProvider.google);

  @override
  Future<UserModel> signInWithApple() =>
      _signInWithProvider(SocialProvider.apple);

  Future<UserModel> _signInWithProvider(SocialProvider provider) async {
    AppLogger.i('Login social iniciado: ${provider.wireName}', tag: _tag);

    final SocialCredential? credential;
    try {
      credential = await _socialAuth.signIn(provider);
    } on SocialAuthException catch (e) {
      AppLogger.w('SDK de ${provider.wireName} falló: ${e.message}', tag: _tag);
      throw AuthException(
        message: tr('errors.social_signin_failed',
            namedArgs: {'provider': _providerLabel(provider)}),
      );
    }
    if (credential == null) {
      throw SocialSignInCancelledException();
    }

    try {
      final response = await _dio.post(
        '$_baseUrl${ApiEndpoints.auth}/oauth/${provider.wireName}/token',
        data: credential.toSignInBody(),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw AuthException(
          message: response.data?['message'] ??
              tr('errors.social_signin_failed',
                  namedArgs: {'provider': _providerLabel(provider)}),
        );
      }

      final user = await _persistSessionAndBuildUser(
        response.data['data'] as Map<String, dynamic>?,
      );
      AppLogger.i('Login social exitoso: ${provider.wireName}', tag: _tag);
      return user;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final serverMessage = e.response?.data is Map
          ? e.response!.data['message'] as String?
          : null;
      AppLogger.w('Login social ${provider.wireName} rechazado: $status',
          tag: _tag);
      throw AuthException(
        message: serverMessage ??
            (status == 401
                ? tr('errors.social_signin_unverified',
                    namedArgs: {'provider': _providerLabel(provider)})
                : tr('common.error_network')),
        code: status,
      );
    }
  }

  static String _providerLabel(SocialProvider provider) => switch (provider) {
        SocialProvider.google => 'Google',
        SocialProvider.apple => 'Apple',
      };
```

- [ ] **Step 4: Run the new test and the existing datasource tests**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/app-social-a1 && flutter test test/features/auth/data/social_sign_in_datasource_test.dart test/features/auth/data/delete_account_test.dart
```
Expected: the new file passes (5 tests); `delete_account_test.dart` fails to compile because `AuthRemoteDataSourceImpl` now requires `socialAuth` — fix in Step 5.

- [ ] **Step 5: Update the existing datasource test construction**

In `test/features/auth/data/delete_account_test.dart`, add after the `_FakeSecureStorage` class:

```dart
class _NoSocialAuth implements SocialAuthClient {
  @override
  Future<SocialCredential?> signIn(SocialProvider provider) async => null;
  @override
  bool supports(SocialProvider provider) => false;
}
```

with imports `package:sacdia_app/core/auth/social_auth_client.dart` and `package:sacdia_app/core/auth/social_credential.dart`, and add `socialAuth: _NoSocialAuth(),` to each `AuthRemoteDataSourceImpl(` construction (3 places).

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/app-social-a1 && flutter test test/features/auth/data
```
Expected: pass (the repository test still fails until Task 6).

---

### Task 6: Repository and use cases

**Files:**
- Modify: `lib/features/auth/domain/repositories/auth_repository.dart:38-62`
- Modify: `lib/features/auth/data/repositories/auth_repository_impl.dart:124-166`
- Modify: `test/features/auth/data/auth_repository_impl_test.dart`

- [ ] **Step 1: Interface** — in `auth_repository.dart` delete `handleOAuthCallback` with its doc comment; change the two doc comments to `/// Inicia sesión con Google (SDK nativo). Devuelve [SocialSignInCancelledFailure] si el usuario cancela.` and the Apple equivalent.

- [ ] **Step 2: Implementation** — in `auth_repository_impl.dart` delete the `handleOAuthCallback` override, and in `signInWithGoogle` / `signInWithApple` replace

```dart
    } on core_exceptions.OAuthFlowInitiatedException catch (e) {
      return Left(OAuthFlowInitiatedFailure(provider: e.provider));
```

with

```dart
    } on core_exceptions.SocialSignInCancelledException {
      return Left(SocialSignInCancelledFailure());
```

(both methods).

- [ ] **Step 3: Repository test** — in `test/features/auth/data/auth_repository_impl_test.dart` delete the `handleOAuthCallback` override of `_FakeAuthRemoteDataSource`. Add a test group at the end of `main()`:

```dart
  group('signInWithGoogle', () {
    test('maps a cancel to SocialSignInCancelledFailure', () async {
      final ds = _FakeAuthRemoteDataSource(getCurrentUserHandler: () async => null)
        ..signInWithGoogleHandler = () async => throw core_exceptions.SocialSignInCancelledException();
      final repo = AuthRepositoryImpl(remoteDataSource: ds, networkInfo: _FakeNetworkInfo(true));

      final result = await repo.signInWithGoogle();

      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<SocialSignInCancelledFailure>()), (_) => fail('expected Left'));
    });
  });
```

and give the fake a configurable handler:

```dart
  Future<UserModel> Function()? signInWithGoogleHandler;

  @override
  Future<UserModel> signInWithGoogle() =>
      signInWithGoogleHandler?.call() ?? (throw UnimplementedError());
```

`SocialSignInCancelledException()` calls `tr(...)`; the existing tests in this file already construct `AuthException`s with `tr`-free messages, so if `tr` throws without `EasyLocalization` initialised, wrap the expectation with `TestWidgetsFlutterBinding.ensureInitialized()` at the top of `main()` and accept the untranslated key — `easy_localization` returns the key itself when not initialised.

- [ ] **Step 4: Run**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/app-social-a1 && flutter test test/features/auth/data
```
Expected: all pass.

---

### Task 7: `AuthNotifier` — result enum, no deep link

**Files:**
- Modify: `lib/features/auth/presentation/providers/auth_providers.dart:34-55, 540-640, 905-915`
- Test: `test/features/auth/presentation/providers/social_sign_in_notifier_test.dart`

- [ ] **Step 1: Write the failing notifier test**

`auth_notifier_offline_cache_test.dart` already builds a `ProviderContainer` with `authRepositoryProvider`, `sharedPreferencesProvider`, `secureStorageProvider`, `pushNotificationServiceProvider` and `unreadNotificationsCountProvider` overridden by fakes. First move those fakes and the container builder, unchanged, into `test/features/auth/presentation/providers/auth_notifier_test_support.dart` (export `_FakeAuthRepository` as `FakeAuthRepository` and the builder as `buildAuthContainer({required AuthRepository repo})`), make the offline-cache test import them, and confirm it still passes. Then write the new file:

```dart
class _SocialRepo extends FakeAuthRepository {
  _SocialRepo(this.googleResult);

  final Either<Failure, UserEntity> googleResult;

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async => googleResult;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const user = UserEntity(id: 'user-1', email: 'ana@example.com', name: 'Ana', postRegisterComplete: false);

  test('success caches the user and returns SocialSignInResult.success', () async {
    final container = buildAuthContainer(repo: _SocialRepo(const Right(user)));
    addTearDown(container.dispose);
    await container.read(authNotifierProvider.future);

    final result = await container.read(authNotifierProvider.notifier).signInWithGoogle();

    expect(result, SocialSignInResult.success);
    expect(container.read(authNotifierProvider).value?.id, 'user-1');
  });

  test('cancel leaves the state without error and returns cancelled', () async {
    final container = buildAuthContainer(repo: _SocialRepo(Left(SocialSignInCancelledFailure())));
    addTearDown(container.dispose);
    await container.read(authNotifierProvider.future);

    final result = await container.read(authNotifierProvider.notifier).signInWithGoogle();

    expect(result, SocialSignInResult.cancelled);
    expect(container.read(authNotifierProvider).hasError, isFalse);
    expect(container.read(authNotifierProvider).value, isNull);
  });

  test('failure puts the message in the error state and returns failed', () async {
    final container = buildAuthContainer(
      repo: _SocialRepo(const Left(AuthFailure(message: 'No pudimos verificar tu cuenta de Google'))),
    );
    addTearDown(container.dispose);
    await container.read(authNotifierProvider.future);

    final result = await container.read(authNotifierProvider.notifier).signInWithGoogle();

    expect(result, SocialSignInResult.failed);
    expect(container.read(authNotifierProvider).error, 'No pudimos verificar tu cuenta de Google');
  });
}
```

`buildAuthContainer(repo: …)` above is `buildAuthContainer(repo: …)` from the support file (its fake repository returns `null` from `getCurrentUser`, so `build()` resolves to `null`). `UserEntity`'s constructor fields come from `lib/features/auth/domain/entities/user_entity.dart`; adjust the `const user` to its required parameters.

- [ ] **Step 2: Run it to verify it fails**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/app-social-a1 && flutter test test/features/auth/presentation/providers/social_sign_in_notifier_test.dart
```
Expected: compile error — `SocialSignInResult` undefined.

- [ ] **Step 3: Implement in the notifier**

In `auth_providers.dart`:

1. Replace the `OAuthLaunchResult` enum (around line 908) with:

```dart
/// Resultado de un intento de login social desde la UI.
enum SocialSignInResult {
  /// Sesión iniciada; el router redirige según `postRegisterComplete`.
  success,

  /// El usuario cerró la hoja nativa. No se muestra nada.
  cancelled,

  /// Error real; el mensaje queda en `authNotifierProvider.error`.
  failed,
}
```

2. Delete `processOAuthDeepLink` entirely.

3. Replace `signInWithGoogle` and `signInWithApple` with:

```dart
  /// Login con Google (SDK nativo).
  Future<SocialSignInResult> signInWithGoogle() =>
      _signInSocial('google', ref.read(signInWithGoogleProvider));

  /// Login con Apple (SDK nativo, solo iOS).
  Future<SocialSignInResult> signInWithApple() =>
      _signInSocial('apple', ref.read(signInWithAppleProvider));

  Future<SocialSignInResult> _signInSocial(
    String provider,
    UseCase<UserEntity, NoParams> useCase,
  ) async {
    AppLogger.i('Login social iniciado: $provider', tag: _tag);
    state = const AsyncValue.loading();

    final result = await useCase(NoParams());

    return result.fold(
      (failure) {
        if (failure is SocialSignInCancelledFailure) {
          AppLogger.i('Login social cancelado: $provider', tag: _tag);
          state = const AsyncValue.data(null);
          return SocialSignInResult.cancelled;
        }
        final errorMessage = failure is AuthFailure
            ? failure.message
            : 'auth.errors.sign_in_${provider}_failed'.tr();
        AppLogger.w('Login social $provider falló: $errorMessage', tag: _tag);
        state = AsyncValue.error(errorMessage, StackTrace.current);
        return SocialSignInResult.failed;
      },
      (user) {
        AppLogger.i('Login social exitoso: $provider', tag: _tag);
        ref
            .read(sharedPreferencesProvider)
            .setBool('user_manually_logged_out', false);
        _cacheUser(user);
        // Mismos efectos que signIn(): FCM y badge de notificaciones.
        ref.read(pushNotificationServiceProvider).initialize();
        ref.read(unreadNotificationsCountProvider.notifier).refresh();
        state = AsyncValue.data(user);
        return SocialSignInResult.success;
      },
    );
  }
```

4. Wire the client into the datasource in `authRepositoryProvider`:

```dart
    remoteDataSource: AuthRemoteDataSourceImpl(
      dio: dio,
      baseUrl: baseUrl,
      secureStorage: secureStorage,
      socialAuth: ref.read(socialAuthClientProvider),
    ),
```

with `import '../../../../core/auth/social_auth_provider.dart';`.

- [ ] **Step 4: Remove the deep-link route and the old helpers**

- `lib/core/config/router.dart`: delete the `GoRoute(path: RouteNames.authCallback, …)` block, the `_OAuthCallbackScreen` + `_OAuthCallbackScreenState` classes and their doc comments, and in the redirect change
  ```dart
        if (currentPath == RouteNames.splash ||
            currentPath == RouteNames.authCallback) {
  ```
  to
  ```dart
        if (currentPath == RouteNames.splash) {
  ```
  Remove the `// Excepción: /auth/callback …` comment line. Remove now-unused imports (`LoadingAnimationWidget`, `SacAccent`) only if the analyzer reports them unused.
- `lib/core/config/route_names.dart`: delete `authCallback` and its comment.
- `lib/core/auth/app_auth_service.dart`: delete the `// ── OAuth` section (`initiateOAuth`, `persistOAuthTokens`) and the `url_launcher` import if unused afterwards.
- `lib/features/home_widgets/domain/next_activity_widget_link.dart:4`: reword the comment so it no longer mentions an OAuth deep link.

- [ ] **Step 5: Run analyzer and tests, commit**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/app-social-a1 && rg -n "OAuthFlowInitiated|OAuthLaunchResult|processOAuthDeepLink|handleOAuthCallback|authCallback|_OAuthCallbackScreen|initiateOAuth|persistOAuthTokens" lib test; dart format lib test && flutter analyze --no-fatal-warnings --no-fatal-infos && flutter test --no-pub test/features/auth test/core/auth && git add -A lib test && git commit -m "feat(auth): sign in with native Google and Apple tokens" -m "Replaces the browser + deep-link OAuth flow (GET /auth/oauth/{provider} + io.sacdia.app://auth/callback) with the native SDKs and POST /auth/oauth/:provider/token. The old flow never worked after the Better Auth migration (the app called GET on a POST route)."
```
Expected: the `rg` prints nothing; analyze clean; tests green.

---

### Task 8: Login UI and translations

**Files:**
- Create: `lib/features/auth/presentation/widgets/social_sign_in_buttons.dart`
- Modify: `lib/features/auth/presentation/views/login_view.dart:346-356`
- Modify: `assets/translations/en.json`, `es.json`, `fr.json`, `pt-BR.json`

- [ ] **Step 1: Translations**

In each locale file, inside `"auth": { … }` right after the `"register_link"` line (es.json:191), add:

| key | es | en | fr | pt-BR |
|---|---|---|---|---|
| `or_continue_with` | `"o continúa con"` | `"or continue with"` | `"ou continuer avec"` | `"ou continue com"` |
| `continue_with_google` | `"Continuar con Google"` | `"Continue with Google"` | `"Continuer avec Google"` | `"Continuar com Google"` |
| `continue_with_apple` | `"Continuar con Apple"` | `"Continue with Apple"` | `"Continuer avec Apple"` | `"Continuar com Apple"` |

Inside the top-level `"errors": { … }` block (es.json:355–385), **delete** `google_browser_open`, `google_signin_failed`, `apple_browser_open`, `apple_signin_failed`, `oauth_url_missing`, `get_oauth_url`, `oauth_callback_failed`, `oauth_redirecting`, and **add**:

| key | es | en | fr | pt-BR |
|---|---|---|---|---|
| `social_signin_cancelled` | `"Inicio de sesión cancelado"` | `"Sign-in cancelled"` | `"Connexion annulée"` | `"Login cancelado"` |
| `social_signin_failed` | `"No se pudo iniciar sesión con {provider}. Intenta de nuevo."` | `"Could not sign in with {provider}. Try again."` | `"Impossible de se connecter avec {provider}. Réessayez."` | `"Não foi possível entrar com {provider}. Tente novamente."` |
| `social_signin_unverified` | `"No pudimos verificar tu cuenta de {provider}."` | `"We could not verify your {provider} account."` | `"Nous n'avons pas pu vérifier votre compte {provider}."` | `"Não conseguimos verificar sua conta {provider}."` |

Delete the `"router": { "oauth_callback": { "completing_signin": … } }` entry (es.json:4059–4061) in all four files (remove the whole `oauth_callback` object; keep `router` if it has other keys).

Validate: `for l in en es fr pt-BR; do python3 -c "import json;json.load(open('assets/translations/$l.json'))"; done`.

- [ ] **Step 2: Write the buttons widget**

`lib/features/auth/presentation/widgets/social_sign_in_buttons.dart`:

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sacdia_app/core/auth/social_auth_provider.dart';
import 'package:sacdia_app/core/auth/social_credential.dart';
import 'package:sacdia_app/core/theme/app_theme.dart';
import 'package:sacdia_app/core/theme/sac_colors.dart';
import 'package:sacdia_app/core/widgets/sac_button.dart';
import 'package:sacdia_app/features/auth/presentation/providers/auth_providers.dart';

/// Separador "o continúa con" + botones de Google y Apple.
///
/// Apple solo aparece en iOS; Google solo cuando hay
/// `GOOGLE_SERVER_CLIENT_ID` (ver [AppConstants.googleServerClientId]).
/// Si ninguno está disponible, no se renderiza nada.
class SocialSignInButtons extends ConsumerWidget {
  const SocialSignInButtons({super.key, required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(socialAuthClientProvider);
    final providers = SocialProvider.values.where(client.supports).toList();
    if (providers.isEmpty) return const SizedBox.shrink();

    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final c = context.sac;
    final divider = Theme.of(context).dividerColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: Divider(color: divider)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'auth.or_continue_with'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: c.textSecondary),
              ),
            ),
            Expanded(child: Divider(color: divider)),
          ],
        ),
        const SizedBox(height: 16),
        for (final provider in providers) ...[
          _SocialButton(
            provider: provider,
            enabled: enabled && !isLoading,
            onPressed: () => _signIn(ref, provider),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Future<void> _signIn(WidgetRef ref, SocialProvider provider) {
    final notifier = ref.read(authNotifierProvider.notifier);
    return switch (provider) {
      SocialProvider.google => notifier.signInWithGoogle(),
      SocialProvider.apple => notifier.signInWithApple(),
    };
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.provider,
    required this.enabled,
    required this.onPressed,
  });

  final SocialProvider provider;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final (label, asset) = switch (provider) {
      SocialProvider.google => (
          'auth.continue_with_google'.tr(),
          'assets/svg/google_logo.svg',
        ),
      SocialProvider.apple => (
          'auth.continue_with_apple'.tr(),
          'assets/svg/apple_logo.svg',
        ),
    };
    return SacButton(
      text: label,
      variant: SacButtonVariant.outline,
      size: SacButtonSize.large,
      fullWidth: true,
      borderRadius: AppTheme.radiusFull,
      isEnabled: enabled,
      onPressed: onPressed,
      icon: SvgPicture.asset(asset, width: 20, height: 20),
    );
  }
}
```

`SacButton.icon` is `dynamic` and renders HugeIcons; check `sac_button.dart` for how it builds the icon — if it only accepts `HugeIconData`/`IconData`, add a `Widget` branch there (`if (icon is Widget) return icon;`) in the same commit.

- [ ] **Step 3: Mount it in the login view**

In `login_view.dart`, after the primary `SacButton(... onPressed: _signIn,)` and before `const SizedBox(height: 28),` insert:

```dart
                                    SocialSignInButtons(
                                      enabled: !_isCoolingDown,
                                    ),
```

with `import 'package:sacdia_app/features/auth/presentation/widgets/social_sign_in_buttons.dart';`. The error banner already shows `authState.error` (line 138), so a failed social login surfaces the message; a cancel leaves the state as `data(null)` and shows nothing.

- [ ] **Step 4: Format, analyze, commit**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/app-social-a1 && dart format lib assets && flutter analyze --no-fatal-warnings --no-fatal-infos && flutter test --no-pub && git add -A lib assets && git commit -m "feat(auth): add Google and Apple buttons to the login screen"
```

---

### Task 9: Platform configuration, PR

**Files:**
- Modify: `ios/Runner/Info.plist:25-35`
- Modify: `ios/Runner/Runner.entitlements`, `ios/Runner/Runner.debug.entitlements`
- Modify: `android/app/src/main/AndroidManifest.xml:60-78`

- [ ] **Step 1: iOS — Google URL scheme and client ID**

In `ios/Runner/Info.plist`, replace the `io.sacdia.app` URL scheme entry with the reversed iOS client ID, and add `GIDClientID` + `GIDServerClientID`:

```xml
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<!-- REVERSED_CLIENT_ID del client ID iOS de Google Cloud -->
				<string>com.googleusercontent.apps.REPLACE_WITH_IOS_CLIENT_ID</string>
			</array>
		</dict>
	</array>
	<key>GIDClientID</key>
	<string>REPLACE_WITH_IOS_CLIENT_ID.apps.googleusercontent.com</string>
```

The two `REPLACE_WITH_IOS_CLIENT_ID` values are the only placeholders in this plan and are filled by the user from Google Cloud (slice C1) before the first device build; CI does not build iOS. Keep `FlutterDeepLinkingEnabled` as is (other links use it).

- [ ] **Step 2: iOS — Sign in with Apple entitlement**

In both `ios/Runner/Runner.entitlements` and `ios/Runner/Runner.debug.entitlements`, inside `<dict>` add:

```xml
	<key>com.apple.developer.applesignin</key>
	<array>
		<string>Default</string>
	</array>
```

Xcode must also have the capability enabled on the App ID (user, C1); without it Apple sign-in fails silently.

- [ ] **Step 3: Android — remove the OAuth App Link filter**

In `AndroidManifest.xml` delete the `<!-- Verified App Link for OAuth callback (preferred) -->` comment, the `<!-- REQUIRED: Publish assetlinks.json … -->` comment, the `<intent-filter android:autoVerify="true">…</intent-filter>` block for `sacdia-backend.onrender.com/api/auth/callback`, and the `<!-- Custom URL scheme (io.sacdia.app://) removed … -->` comment. Keep the `home_widget` filter. `google_sign_in` 7 on Android needs no manifest entry; it needs the SHA-1 fingerprints registered in Google Cloud (C1).

- [ ] **Step 4: Commit, push, PR**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/app-social-a1 && git add ios android && git commit -m "build(auth): configure Google URL scheme and Sign in with Apple entitlement; drop the OAuth app link" && git push -u origin feat/native-social-sign-in && gh pr create -R abn-r/sacdia-app --base development --head feat/native-social-sign-in --title "feat(auth): native Google and Apple sign-in (A1)" --label "type:feature" --body "## Summary
- Login screen: \"Continuar con Google\" (iOS/Android) and \"Continuar con Apple\" (iOS). Native SDKs; the idToken goes to \`POST /auth/oauth/:provider/token\` (backend B2).
- Removes the browser + deep-link flow (\`GET /auth/oauth/{provider}\`, \`io.sacdia.app://auth/callback\`, \`_OAuthCallbackScreen\`), which never worked after the Better Auth migration.
- Shared session parser for \`/auth/login\` and the social endpoint.

Spec: workspace \`docs/plans/2026-10-14-native-social-sign-in-design.md\`. Plan: \`…-app-plan.md\`.

## Before testing on device (C1)
- Google Cloud: iOS, Android and Web client IDs; SHA-1s registered.
- \`ios/Runner/Info.plist\`: replace \`REPLACE_WITH_IOS_CLIENT_ID\` (2 places).
- Build with \`--dart-define=GOOGLE_SERVER_CLIENT_ID=<web client id>\`.
- Render: \`GOOGLE_OAUTH_AUDIENCES\` includes that Web client ID; \`APPLE_BUNDLE_ID=com.sacdia.app\`.
- Xcode: Sign in with Apple capability on the App ID.

## Test plan
- [x] \`flutter test\`, \`flutter analyze\`, \`dart format\`
- [ ] CI green
- [ ] iPhone: Google → post-registro for a new email; Apple with \"Hide my email\" → post-registro; existing email → lands in home
- [ ] iPhone: cancel both sheets → back to login, no banner
- [ ] Android: Google → same as above; no Apple button
- [ ] Render log shows \`google sign-in for user … (created=true …)\` and no \`id token rejected\`"
```

---

## Slice A2 — account deletion for social-only users

Fresh worktree after A1 merged: branch `feat/social-reauth-account-deletion`, dir `app-social-a2`, from `origin/development`.

### Task 10: `DeleteAccountReauth` and the datasource

**Files:**
- Create: `lib/features/auth/domain/entities/delete_account_reauth.dart`
- Modify: `lib/features/auth/data/datasources/auth_remote_data_source.dart` (`deleteAccount`, new `getConnectedProviders`)
- Modify: `test/features/auth/data/delete_account_test.dart`

- [ ] **Step 1: The reauth type**

```dart
import '../../../../core/auth/social_credential.dart';

/// Cómo se reautentica el usuario antes de borrar la cuenta
/// (`DELETE /auth/me`): contraseña actual o un idToken fresco del proveedor.
sealed class DeleteAccountReauth {
  const DeleteAccountReauth();

  Map<String, dynamic> toBody();
}

class PasswordReauth extends DeleteAccountReauth {
  const PasswordReauth(this.password);

  final String password;

  @override
  Map<String, dynamic> toBody() => {'password': password};
}

class SocialReauth extends DeleteAccountReauth {
  const SocialReauth(this.credential);

  final SocialCredential credential;

  @override
  Map<String, dynamic> toBody() => credential.toReauthBody();
}
```

- [ ] **Step 2: Failing tests** — in `delete_account_test.dart` change the two existing calls to `dataSource.deleteAccount(const PasswordReauth('wrong-password'))` / `const PasswordReauth('correct-password')` and add:

```dart
    test('sends provider, idToken and nonce for a social re-auth', () async {
      await storage.write(AppConstants.tokenKey, 'my-jwt-token');
      final adapter = _adapterReturning(204);
      dio.httpClientAdapter = adapter;
      dataSource = AuthRemoteDataSourceImpl(
        dio: dio, baseUrl: 'http://localhost:3000', secureStorage: storage, socialAuth: _NoSocialAuth(),
      );

      await dataSource.deleteAccount(const SocialReauth(SocialCredential(
        provider: SocialProvider.google, idToken: 'g-token', nonce: 'n-1',
      )));

      expect(adapter.lastRequest?.method, 'DELETE');
      expect(adapter.lastRequest?.data, {'provider': 'google', 'idToken': 'g-token', 'nonce': 'n-1'});
      expect(await storage.read(AppConstants.tokenKey), isNull);
    });

    test('getConnectedProviders returns the provider list', () async {
      await storage.write(AppConstants.tokenKey, 'my-jwt-token');
      dio.httpClientAdapter = _JsonAdapter(200, {'status': 'success', 'data': ['google', 'apple']});
      dataSource = AuthRemoteDataSourceImpl(
        dio: dio, baseUrl: 'http://localhost:3000', secureStorage: storage, socialAuth: _NoSocialAuth(),
      );

      expect(await dataSource.getConnectedProviders(), [SocialProvider.google, SocialProvider.apple]);
    });
```

Copy `_JsonAdapter` from `social_sign_in_datasource_test.dart` into this file (or move it to `test/helpers/json_adapter.dart` and import it from both).

- [ ] **Step 3: Implement** — in the datasource interface change `Future<void> deleteAccount(String password);` to `Future<void> deleteAccount(DeleteAccountReauth reauth);` and add `Future<List<SocialProvider>> getConnectedProviders();`. In the implementation change the signature and `data: {'password': password},` → `data: reauth.toBody(),`; add:

```dart
  @override
  Future<List<SocialProvider>> getConnectedProviders() async {
    final token = await _secureStorage.read(AppConstants.tokenKey);
    if (token == null) {
      throw AuthException(message: tr('errors.no_active_session'));
    }
    final response = await _dio.get(
      '$_baseUrl${ApiEndpoints.auth}/oauth/providers',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final names = (response.data['data'] as List?)?.cast<String>() ?? const [];
    return [
      for (final p in SocialProvider.values)
        if (names.contains(p.wireName)) p,
    ];
  }
```

Import `../../domain/entities/delete_account_reauth.dart`.

- [ ] **Step 4: Run, commit**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/app-social-a2 && flutter test test/features/auth/data/delete_account_test.dart && dart format lib test && git add -A lib test && git commit -m "feat(auth): re-authenticate account deletion with a password or a social credential"
```
(The repository/notifier still call the old signature; the tree compiles again after Task 11.)

---

### Task 11: Repository, notifier

**Files:**
- Modify: `lib/features/auth/domain/repositories/auth_repository.dart` (`deleteAccount`, `getConnectedProviders`)
- Modify: `lib/features/auth/data/repositories/auth_repository_impl.dart`
- Modify: `lib/features/auth/presentation/providers/auth_providers.dart:744-800`
- Modify: `test/features/auth/data/auth_repository_impl_test.dart` (fake datasource signature)

- [ ] **Step 1:** Repository interface: `Future<Either<Failure, void>> deleteAccount(DeleteAccountReauth reauth);` and `Future<Either<Failure, List<SocialProvider>>> getConnectedProviders();`. Implementation: pass through, mapping `AuthException` → `AuthFailure` like the sibling methods.

- [ ] **Step 2:** Notifier: `Future<String?> deleteAccount(DeleteAccountReauth reauth)`; the only body change is `.deleteAccount(reauth)`. Add:

```dart
  /// Proveedores sociales vinculados, para ofrecer la confirmación sin
  /// contraseña al borrar la cuenta. Lista vacía si la consulta falla.
  Future<List<SocialProvider>> connectedProviders() async {
    final result = await ref.read(authRepositoryProvider).getConnectedProviders();
    return result.fold((_) => const [], (list) => list);
  }
```

- [ ] **Step 3:** Fix the fake datasource in `auth_repository_impl_test.dart` (new signatures, `throw UnimplementedError()` bodies) and run `flutter test test/features/auth && flutter analyze --no-fatal-warnings --no-fatal-infos`, then commit `refactor(auth): thread DeleteAccountReauth through repository and notifier`.

---

### Task 12: Settings dialog with provider confirmation

**Files:**
- Modify: `lib/features/profile/presentation/views/settings_view.dart:365-420, 1164-1300`
- Modify: `assets/translations/*.json`

- [ ] **Step 1: Translations** — inside `"profile": { "settings": { … } }` next to `delete_account_enter_password` add:

| key | es | en | fr | pt-BR |
|---|---|---|---|---|
| `delete_account_or_confirm_with` | `"O confirma con tu cuenta vinculada:"` | `"Or confirm with your linked account:"` | `"Ou confirmez avec votre compte lié :"` | `"Ou confirme com sua conta vinculada:"` |
| `delete_account_confirm_google` | `"Confirmar con Google"` | `"Confirm with Google"` | `"Confirmer avec Google"` | `"Confirmar com Google"` |
| `delete_account_confirm_apple` | `"Confirmar con Apple"` | `"Confirm with Apple"` | `"Confirmer avec Apple"` | `"Confirmar com Apple"` |
| `delete_account_error_no_reauth` | `"Ingresa tu contraseña o confirma con tu cuenta vinculada."` | `"Enter your password or confirm with your linked account."` | `"Saisissez votre mot de passe ou confirmez avec votre compte lié."` | `"Digite sua senha ou confirme com sua conta vinculada."` |

- [ ] **Step 2: Dialog result type** — `_DeleteAccountConfirmDialog` now takes `required List<SocialProvider> providers` and pops a `DeleteAccountReauth?`:

- The password `SacTextField` stays. `_submit()` pops `PasswordReauth(_passwordCtrl.text.trim())`; when the field is empty and `providers` is empty, set `_fieldError = 'profile.settings.delete_account_error_no_password'.tr()`; when empty and providers exist, `delete_account_error_no_reauth`.
- When `providers.isNotEmpty`, below the password field render `Text('profile.settings.delete_account_or_confirm_with'.tr())` and, for each provider, a `SacButton(variant: SacButtonVariant.outline, text: 'profile.settings.delete_account_confirm_${provider.wireName}'.tr(), onPressed: () => _confirmWith(provider))` whose handler calls `socialAuthClientProvider` (the dialog becomes a `ConsumerStatefulWidget`):

```dart
  Future<void> _confirmWith(SocialProvider provider) async {
    if (_confirmCtrl.text.trim() != widget.confirmationWord.toUpperCase()) {
      setState(() => _fieldError = 'profile.settings.delete_account_error_type_wrong'
          .tr(namedArgs: {'word': widget.confirmationWord}));
      return;
    }
    final credential = await ref.read(socialAuthClientProvider).signIn(provider);
    if (!mounted || credential == null) return; // cancelled: stay in the dialog
    Navigator.of(context).pop(SocialReauth(credential));
  }
```

  Wrap the `signIn` call in `try { … } on SocialAuthException { setState(() => _fieldError = 'errors.social_signin_failed'.tr(namedArgs: {'provider': …})); }`.

- [ ] **Step 3: Caller** — in `_confirmDeleteAccount` (around line 365), before presenting the dialog load the providers, and change the result handling:

```dart
    final providers =
        await ref.read(authNotifierProvider.notifier).connectedProviders();
    if (!mounted) return;

    final reauth = await SacDialog.present<DeleteAccountReauth>(
      context,
      barrierDismissible: false,
      builder: (_) => _DeleteAccountConfirmDialog(
        confirmationWord: deleteConfirmationWord,
        providers: providers,
      ),
    );

    if (reauth == null || !mounted) return;
    …
    final error =
        await ref.read(authNotifierProvider.notifier).deleteAccount(reauth);
```

- [ ] **Step 4: Format, analyze, test, commit, PR**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/app-social-a2 && dart format lib test assets && flutter analyze --no-fatal-warnings --no-fatal-infos && flutter test --no-pub && git add -A lib test assets && git commit -m "feat(settings): confirm account deletion with Google or Apple when the account has no password" && git push -u origin feat/social-reauth-account-deletion && gh pr create -R abn-r/sacdia-app --base development --head feat/social-reauth-account-deletion --title "feat(settings): delete account with Google/Apple confirmation (A2)" --label "type:feature" --body "## Summary
- \`DELETE /auth/me\` now receives \`{ password }\` or \`{ provider, idToken, nonce }\` (backend B3).
- The delete dialog lists the linked providers (\`GET /auth/oauth/providers\`) and lets a social-only user confirm by signing in again with Google/Apple.

## Test plan
- [x] \`flutter test\`, analyze, format
- [ ] CI green
- [ ] iPhone: Apple-only test account → Confirmar con Apple → account deleted; Render log shows the revoke
- [ ] Android: Google-only test account → Confirmar con Google → deleted
- [ ] Password account → password path unchanged"
```

---

### Task 13: Close-out

- [ ] Delete the two worktrees after merge: `git -C /Users/abner/Documents/development/sacdia/sacdia-app worktree remove /Users/abner/Documents/development/sacdia-worktrees/app-social-a1` (same for `-a2`) and the local branches.
- [ ] Update `project_pending_ios_push.md`-style memory notes if the Apple capability work overlaps with the push-notification setup already pending in Xcode (both are App ID capabilities — do them in one Xcode session).

---

## Risks and notes

- **`google_sign_in` 7 nonce is set in `initialize`**, not per `authenticate()`. The client re-initialises per attempt. If a platform rejects repeated `initialize`, fall back to one nonce per app session (Task 3 Step 3 note); the backend keeps rejecting mismatches either way.
- **Apple only in iOS** (spec D5). `NativeSocialAuthClient.supports` hides the button on Android. A user created with Apple on iPhone cannot sign in on Android until "add password" exists (out of scope).
- **Apple "Hide my email"** yields a `@privaterelay.appleid.com` address; the backend creates the user with it. Email features (reset, verification) reach the relay only while the user keeps forwarding on.
- **`fullName` arrives once.** If the first Apple sign-in fails after the sheet (network), the name is lost for later attempts; the user fills it in post-registration anyway.
- **Translations** are edited in the worktree; the main checkout has uncommitted translation changes from another session — expect a trivial merge when that session's PR lands.
- **`SacButton.icon` is `dynamic`**: if it does not render a `Widget`, Task 8 adds that branch.
- **No widget test for the login view**: the social buttons are verified on device (Task 9 checklist); the notifier and datasource tests cover the logic.
