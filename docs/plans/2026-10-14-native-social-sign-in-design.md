# Login con Google y Apple nativo (app móvil)

**Fecha:** 2026-10-14
**Estado:** Diseño aprobado por el usuario sección por sección. Sin código.
**Alcance:** `sacdia-backend` (verificación de tokens, alta y vinculación de cuentas, borrado de cuenta) y `sacdia-app` (SDK nativos de Google y Apple). El admin web queda fuera.
**Base leída:** `sacdia-backend` `origin/development` en `2c5cc8a7`; `sacdia-app` `origin/development` en `c8919e75`; better-auth 1.7.7.

## 1. Problema

El login social no funciona de punta a punta desde la migración de Supabase a Better Auth (W3-008). La sesión del 2026-10-13 encontró estos huecos:

1. El handler HTTP de Better Auth nunca se montó en Nest. `GET /api/auth/callback/{provider}` responde 404, así que el proveedor no tiene a dónde regresar.
2. La URL de regreso que genera Better Auth apunta a `http://localhost:3000/...`, porque `BETTER_AUTH_BASE_URL` no está configurada en Render.
3. Apple falla con `CLIENT_ID_AND_SECRET_REQUIRED`: el config no pasa `clientSecret`.
4. La app llama `GET /auth/oauth/{provider}` y el backend solo expone `POST`.
5. El adaptador de Better Auth escribe `users` con nombres camelCase que no existen en el esquema (`id`, `emailVerified`), así que el alta de un usuario nuevo fallaría.
6. `deleteAccount` exige contraseña. Un usuario que solo entra con Google o Apple no podría borrar su cuenta.

Better Auth 1.7 además valida el esquema de Prisma antes de cada operación. #497 la apagó (`validateSchema: false`), pero eso solo devolvió el comportamiento de 1.6, no arregló los huecos.

## 2. Decisiones tomadas

| # | Decisión |
|---|---|
| D1 | Solo app móvil (iOS y Android). El admin web no tendrá login social. |
| D2 | Si el usuario no existe, se crea la cuenta automáticamente y pasa por el post-registro actual. |
| D3 | Si el correo ya existe, se vincula automáticamente. Si esa cuenta local tiene `email_verified = false`, se borra su contraseña al vincular. |
| D4 | Enfoque A: SDK nativo en la app y verificación del `idToken` en SACDIA con `jose`. Better Auth deja de participar en OAuth. |
| D5 | Apple solo en iOS; en Android solo Google. |
| D6 | El `refresh_token` de Apple se guarda en `accounts.refreshToken` en texto plano, igual que las demás columnas de tokens. Cifrarlo queda fuera de esta versión. |
| D7 | El `client_secret` de Apple se genera en cada llamada (JWT ES256 con la llave `.p8`). No hay rotación manual cada 6 meses. |

### Enfoques descartados

- **B. SDK nativo con la rama `idToken` de Better Auth.** Menos código de verificación, pero el alta pasa por el adaptador de Better Auth (hueco 5) y nos expone a cada upgrade, como pasó con 1.7.
- **C. Flujo con navegador vía Better Auth.** Necesita montar el handler, un deep link de regreso, cookies, `BETTER_AUTH_BASE_URL` y el `client_secret` de Apple. Peor experiencia en móvil y más piezas.

## 3. Arquitectura y flujo

```
App (Flutter)                          Backend (NestJS)
─────────────                          ────────────────
1. Genera nonce aleatorio
2. SDK nativo (Google / Apple) ──────▶ (Google/Apple)
   ◀── idToken (+ authorizationCode en Apple)
3. POST /auth/oauth/{provider}/token
   { idToken, nonce, authorizationCode?, fullName? }
                                        4. Verifica idToken (jose + JWKS)
                                           iss, aud, exp, nonce, email_verified
                                        5. Resuelve cuenta:
                                           a) accounts(provider, sub) existe → ese usuario
                                           b) users.email existe → vincula
                                              (si email_verified=false → borra contraseña)
                                           c) nada → crea users + accounts
                                        6. ensureSacdiaUserProvisioned (users_pr, roles)
                                        7. Apple: canjea authorizationCode → refresh_token
                                        8. createSession + signJwt
   ◀──────────────────────────────────── 9. Respuesta de POST /auth/oauth/callback + tokens de login:
                                           { accessToken, sessionToken, refreshToken, expiresAt,
                                             tokenType, user, needsPostRegistration }
10. Si needsPostRegistration → post-registro existente
```

Reglas:

- **La identidad es `(providerId, accountId)` en `accounts`**, donde `accountId` es el `sub` del proveedor. El correo solo se usa para vincular la primera vez. El `sub` no cambia aunque el usuario cambie de correo u oculte el suyo con Apple. La tabla ya tiene `@@unique([providerId, accountId])`.
- **La respuesta es la de `OAuthService.handleCallback` más los campos de token de `POST /auth/login`** (`refreshToken`, `expiresAt` en segundos y `tokenType: 'bearer'`), para que la app use el mismo parser en ambos logins. `sessionToken` y `refreshToken` llevan el mismo token opaco de sesión.
- **El nombre de Apple** llega solo en el primer login y solo al cliente. La app lo manda como `fullName`. El backend lo usa al crear el usuario y lo ignora después.
- **`providerId`** vale `google` o `apple`, los mismos valores que ya leen `GET /auth/oauth/providers` y `DELETE /auth/oauth/:provider`.

## 4. Backend

### 4.1 Módulo nuevo `src/auth/social-sign-in/`

| Unidad | Responsabilidad | Depende de |
|---|---|---|
| `IdTokenVerifier` (interfaz) | `verify(idToken, nonce): Promise<VerifiedIdentity>`, con `VerifiedIdentity = { sub, email, emailVerified, name?, picture? }`. | — |
| `GoogleIdTokenVerifier` | JWKS `https://www.googleapis.com/oauth2/v3/certs` vía `createRemoteJWKSet` (caché de `jose`). `iss` ∈ `accounts.google.com`, `https://accounts.google.com`. `aud` ∈ `GOOGLE_OAUTH_AUDIENCES`. `nonce` igual al recibido. | `jose` |
| `AppleIdTokenVerifier` | JWKS `https://appleid.apple.com/auth/keys`. `iss = https://appleid.apple.com`. `aud = APPLE_BUNDLE_ID`. `nonce` del token igual al SHA-256 hex del nonce recibido. `email_verified` puede llegar como string `"true"`. | `jose` |
| `AppleTokenClient` | `clientSecret()`: JWT ES256 con `iss = APPLE_TEAM_ID`, `sub = APPLE_BUNDLE_ID`, `aud = https://appleid.apple.com`, `kid = APPLE_KEY_ID` y `exp` de 5 minutos. `exchangeCode(code)` → `POST https://appleid.apple.com/auth/token` (`grant_type=authorization_code`) → `refresh_token`. `revoke(refreshToken)` → `POST https://appleid.apple.com/auth/revoke`. | `jose`, `fetch` |
| `SocialAccountResolver` | Regla D2/D3 en **una transacción**: buscar por `(providerId, sub)`; si no hay, buscar `users.email` y vincular (borrar `password` de la cuenta `credential` si `users.email_verified = false`, y marcar `email_verified = true`); si no hay, crear `users` y `accounts`. Dentro de la misma transacción llama la lógica de `ensureSacdiaUserProvisioned`. | Prisma |
| `SocialSignInService` | Orquesta: verificador → resolver → (Apple con `authorizationCode`) canje y guardado de `refreshToken` en la fila de `accounts` → `createSession` + `signJwt` → respuesta. | Los anteriores y `BetterAuthService` |
| `SocialSignInController` | `POST /auth/oauth/:provider/token`, `@Public()`, mismo throttle que hoy (`namedThrottle({ ttl: 60000, limit: 5 })`). | `SocialSignInService` |

DTO `SocialTokenSignInDto`:

```ts
idToken: string;            // requerido
nonce: string;              // requerido, el nonce en claro
authorizationCode?: string; // solo Apple
fullName?: { givenName?: string; familyName?: string }; // solo Apple, primer login
```

Mapeo de `fullName`: `givenName` → `users.name`; `familyName` → `users.paternal_last_name`. Si no llega nada, `name` = parte local del correo, igual que el fallback actual de `ensureSacdiaUserProvisioned`.

### 4.2 Cambios en código existente

- `oauth.controller.ts`: se quitan `POST google`, `POST apple` y `POST callback`. Se quedan `GET providers` y `DELETE :provider`.
- `oauth.service.ts`: se quitan `initiateGoogleSignIn`, `initiateAppleSignIn` y `handleCallback`. `ensureSacdiaUserProvisioned`, `resolvePrivateProfilePicture` y `getConnectedProviders` se reutilizan (si conviene, se mueven a un servicio compartido).
- `better-auth.service.ts`: se quitan `getOAuthUrl` y `handleOAuthCallback`. `createSession` y `signJwt` quedan accesibles para el nuevo servicio.
- `better-auth.config.ts`: se quitan `socialProviders` y el plugin `twoFactor` (el TOTP es código propio).
- `auth.controller.ts` y `account-deletion.service.ts` (`DELETE /auth/me`): `DeleteAccountDto` acepta `password` **o** `{ provider, idToken, nonce }`.
  - Con contraseña: igual que hoy.
  - Sin contraseña: verifica el `idToken` con el verificador del proveedor y exige que `(provider, sub)` pertenezca al usuario autenticado.
  - Si el usuario tiene cuenta `apple` con `refreshToken`, llama `AppleTokenClient.revoke` antes de borrar. Si falla, registra un warn y sigue con el borrado.
- `src/config/env.validation.ts`: valida las variables nuevas (opcionales en desarrollo, requeridas en producción si el endpoint está activo).
- `docs/api/ENDPOINTS-LIVE-REFERENCE.md` (raíz): endpoint nuevo, endpoints retirados y cambio en `DELETE /auth/me`.

### 4.3 Variables de entorno

| Variable | Uso |
|---|---|
| `GOOGLE_OAUTH_AUDIENCES` | CSV de client IDs aceptados como `aud`. Como mínimo, el client ID **Web** que la app pasa como `serverClientId`. |
| `APPLE_BUNDLE_ID` | `aud` del token de Apple y `sub`/`client_id` del `client_secret`. |
| `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY` | Ya existen. Firman el `client_secret`. |

Ya no se usan para OAuth: `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `APPLE_CLIENT_ID`, `BETTER_AUTH_BASE_URL`, `ALLOWED_OAUTH_REDIRECT_URLS`. Se retiran del código en el slice B4.

## 5. App (Flutter)

Se mantiene la arquitectura actual (datasource → repository → usecase → provider).

| Unidad | Cambio |
|---|---|
| Dependencias | Nuevas: `google_sign_in`, `sign_in_with_apple`, `crypto` (directa, para el SHA-256 del nonce). |
| `core/auth/social_auth_client.dart` (nuevo) | Envuelve los SDK. Genera el nonce (32 bytes aleatorios en base64url). Google: `serverClientId` = client ID Web y el nonce. Apple: `nonce` = SHA-256 hex del nonce y scopes `email` y `fullName`. Devuelve `SocialCredential { provider, idToken, nonce, authorizationCode?, fullName? }` o `null` si el usuario canceló. |
| `auth_remote_data_source.dart` | `signInWithGoogle()` y `signInWithApple()` llaman al `SocialAuthClient` y hacen `POST /auth/oauth/{provider}/token`. El manejo de la respuesta se reutiliza. |
| Flujo con navegador | Se eliminan `handleOAuthCallback`, el deep link de regreso y la intercepción del router. `OAuthLaunchResult` se reduce a éxito, cancelado o error. |
| Botón de Apple | Solo se muestra en iOS (`Platform.isIOS`). |
| Borrar cuenta | Si el usuario no tiene contraseña (`connectedProviders` sin `credential`), la pantalla muestra «Confirmar con Google/Apple». Abre la hoja nativa y manda `{ provider, idToken, nonce }` a `DELETE /auth/me`. |
| i18n | Textos nuevos en los ARB existentes. |

Configuración fuera del código:

- **iOS:** capability «Sign in with Apple» en `Runner.entitlements` y en el App ID de Apple Developer; URL scheme del client ID iOS (reversed) en `Info.plist`.
- **Android:** SHA-1 de debug, release y Play App Signing dados de alta en Google Cloud.
- **Google Cloud:** client ID iOS, client ID Android y client ID Web (`serverClientId` y valor de `GOOGLE_OAUTH_AUDIENCES`).
- **Apple Developer:** llave `.p8` con «Sign in with Apple» habilitado (`APPLE_KEY_ID`) asociada al App ID.

## 6. Manejo de errores

### Backend

| Situación | HTTP | Código |
|---|---|---|
| `provider` distinto de `google` o `apple` | 400 | `AUTH_OAUTH_PROVIDER_INVALID` (existe) |
| `idToken` inválido: firma, `iss`, `aud`, `exp` o `nonce` | 401 | `AUTH_INVALID_TOKEN` (existe) |
| Token sin correo o con `email_verified = false` | 401 | `AUTH_OAUTH_EMAIL_UNVERIFIED` (**nuevo**) |
| Usuario desactivado o borrado | Igual que el login con contraseña | Mismos códigos |
| JWKS no disponible | 503 | `SERVICE_UNAVAILABLE` |
| Falla el canje del `authorizationCode` de Apple | — | No bloquea el login. Warn y no se guarda `refreshToken`. |
| Falla la revocación en Apple al borrar | — | No bloquea el borrado. Warn. |

Logs: `sub` truncado y motivo del rechazo. Nunca el token, el correo completo ni el código. Ningún `catch` descarta un error sin registrarlo.

### App

- Hoja nativa cancelada → vuelve al login sin mensaje.
- 401 → «No pudimos verificar tu cuenta de Google/Apple».
- Red o 503 → mensaje genérico existente.

## 7. Pruebas

| Capa | Casos | Método |
|---|---|---|
| `GoogleIdTokenVerifier`, `AppleIdTokenVerifier` | Firma válida e inválida, `iss` y `aud` incorrectos, expirado, `nonce` equivocado (Apple con hash), `email_verified` falso o como string | Unit con un JWKS local: llaves generadas con `jose` y un `JWKSet` local inyectado. Sin red. |
| `SocialAccountResolver` | Las tres ramas, borrado de contraseña con `email_verified = false`, atomicidad | Unit con Prisma mockeado (patrón actual) |
| `AppleTokenClient` | Claims y header del `client_secret`, canje, revocación, errores HTTP | Unit con `fetch` mockeado |
| `POST /auth/oauth/:provider/token` | Contrato, misma forma que el `callback` actual, throttle | e2e con verificadores fake por inyección de dependencias |
| `DELETE /auth/me` | Contraseña, `idToken` del mismo usuario, `idToken` de otro usuario (rechazo), revocación de Apple | Unit y e2e |
| App | `SocialAuthClient` mockeado: éxito, cancelación, 401; borrar cuenta sin contraseña | Tests de Flutter |
| Prueba real | iPhone con Apple y Google; Android con Google; contra Render | Manual tras el deploy, checklist en el PR |

`jose` es una dependencia real en los tests (no un mock de módulo como `better-auth`), así que el CI ejecuta la verificación.

## 8. Entrega por slices

| Slice | Repo | Contenido | Depende de |
|---|---|---|---|
| B1 | backend | `jose` directo, `IdTokenVerifier` (Google y Apple), `AppleTokenClient`, variables de entorno, tests | — |
| B2 | backend | `SocialAccountResolver`, `SocialSignInService`, endpoint, `AUTH_OAUTH_EMAIL_UNVERIFIED`, e2e | B1 |
| B3 | backend | `DELETE /auth/me` con `idToken` y revocación de Apple | B1, B2 |
| B4 | backend | Retirar los endpoints viejos, `getOAuthUrl`, `handleOAuthCallback`, `socialProviders`, `twoFactor` y las variables sin uso | B2 |
| D1 | raíz | `ENDPOINTS-LIVE-REFERENCE.md` y guía de configuración de consolas | B2, B3 |
| A1 | app | `SocialAuthClient`, login con Google y Apple, quitar el flujo con navegador | B2 en Render |
| A2 | app | Borrar cuenta sin contraseña | B3 en Render, A1 |
| C1 | consolas | Google Cloud, Apple Developer, Xcode y variables en Render (lo hace el usuario) | Antes de probar A1 |

B4 no rompe nada en producción: los endpoints viejos ya no funcionan y la app actual llama con `GET` (404).

## 9. Fuera de alcance

- Login social en el admin web.
- Apple en Android.
- Pantalla de ajustes para vincular o desvincular proveedores desde la app (los endpoints ya existen).
- Agregar contraseña a una cuenta creada con Google o Apple.
- Cifrar los tokens guardados en `accounts`.
- Retirar Better Auth del backend por completo.
