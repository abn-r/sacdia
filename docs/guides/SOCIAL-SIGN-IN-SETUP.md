# Login con Google y Apple: configuración de consolas

**Estado**: ACTIVE
**Actualizado**: 2026-10-14

Diseño: `docs/plans/2026-10-14-native-social-sign-in-design.md`. Contrato del endpoint: `docs/api/ENDPOINTS-LIVE-REFERENCE.md` (sección OAuth). Este documento lista lo que se configura fuera del código (slice C1). Sin esto el endpoint responde 401 a todos los tokens y la app no muestra el botón de Google.

Nunca pongas IDs, llaves ni secretos reales en este documento ni en el repositorio. Van en Render (backend) y en `--dart-define` (app).

## Google

### 1. Firebase: habilitar Google

Proyecto `sacdia-dev`: **Firebase → Authentication → Sign-in method → Google → Enable**. Al habilitarlo, Firebase crea solo el client ID **Web** en Google Cloud. Hazlo primero: sin esto los archivos de configuración no traen clientes OAuth.

### 2. SHA-1 de Android

En **Firebase → Project settings → tu app Android → SHA certificate fingerprints**, agrega el SHA-1 de:

- la llave de **debug** (`keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`);
- la llave de **release** (el keystore con el que firmas el AAB);
- la llave de **Play App Signing** (Play Console → la app → **Test and release → App integrity → App signing**, campo «SHA-1 certificate fingerprint»).

### 3. Volver a descargar la configuración

Después de los pasos 1 y 2, descarga de nuevo `google-services.json` (Android) y `GoogleService-Info.plist` (iOS) y reemplaza los de la app. Los archivos anteriores no traen los clientes OAuth. Verifica que el `plist` ahora tenga `CLIENT_ID` y `REVERSED_CLIENT_ID`.

### 4. Client IDs que usa SACDIA

En Google Cloud → **APIs & Services → Credentials**:

| Client ID | Para qué | Dónde va |
|---|---|---|
| Web | `serverClientId` de la app. Es la `aud` del `idToken` en Android. | `--dart-define=GOOGLE_SERVER_CLIENT_ID` y `GOOGLE_OAUTH_AUDIENCES` en Render |
| iOS | SDK de Google en iPhone. Su `aud` es el propio client ID iOS. | `--dart-define=GOOGLE_IOS_CLIENT_ID`, `GOOGLE_OAUTH_AUDIENCES` en Render y URL scheme invertido en `Info.plist` |
| Android | SDK de Google en Android. Package name + SHA-1. | Solo en la consola (no se usa en código) |

### 5. App

Compila con los dos `--dart-define`:

```bash
flutter run \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<client id Web> \
  --dart-define=GOOGLE_IOS_CLIENT_ID=<client id iOS>
```

- El botón de Google se oculta si falta `GOOGLE_SERVER_CLIENT_ID`. En iOS también se oculta si falta `GOOGLE_IOS_CLIENT_ID`.
- El botón de Apple solo aparece en iOS.
- `ios/Runner/Info.plist` trae el URL scheme con el marcador `REPLACE_WITH_IOS_CLIENT_ID`. Reemplázalo por el `REVERSED_CLIENT_ID` (`com.googleusercontent.apps.<...>`) del `GoogleService-Info.plist`.

## Apple Developer

1. **Identifiers** → el App ID `com.sacdia.app` → habilita la capability **Sign in with Apple** y guarda.
2. **Keys** → crea una llave nueva con **Sign in with Apple** habilitado, asóciala al App ID y descarga el `.p8` (solo se descarga una vez). Anota el **Key ID**.
3. **Team ID**: aparece en **Membership details** de tu cuenta de desarrollador.
4. Xcode → **Signing & Capabilities** → **Sign in with Apple** (actualiza `Runner.entitlements`).

## Render (backend)

Variables nuevas o requeridas:

| Variable | Valor |
|---|---|
| `GOOGLE_OAUTH_AUDIENCES` | CSV con el client ID **Web** y el client ID **iOS**, sin espacios: `<web>,<ios>` |
| `APPLE_BUNDLE_ID` | `com.sacdia.app` (es la `aud` del token de Apple y el `client_id` del endpoint de tokens) |
| `APPLE_TEAM_ID` | Team ID de Membership details |
| `APPLE_KEY_ID` | Key ID de la llave `.p8` |
| `APPLE_PRIVATE_KEY` | Contenido del `.p8`. Si Render guarda los saltos como `\n` literales, el backend los convierte |

Variables que ya no se usan y se pueden borrar: `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `APPLE_CLIENT_ID`, `ALLOWED_OAUTH_REDIRECT_URLS`.

Reinicia el servicio después de cambiar variables.

## Verificación

1. `POST /api/v1/auth/oauth/google/token` con `{}` → 400 (validación del DTO). Si responde 404, el backend desplegado no tiene el endpoint.
2. Desde la app en un iPhone: Google y Apple → 201 con `accessToken`.
3. Desde la app en Android: Google → 201.
4. En el log de Render no deben aparecer líneas de rechazo de id token. Si aparece una por `aud`, falta ese client ID en `GOOGLE_OAUTH_AUDIENCES`.
5. Borra una cuenta de prueba creada con Google o Apple y confirma con el mismo proveedor: debe borrarse sin pedir contraseña.
