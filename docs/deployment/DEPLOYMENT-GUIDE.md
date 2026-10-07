# SACDIA — Deployment Guide

**Estado**: ACTIVE
**Actualizado**: 2026-10-04
**Fuentes**: `sacdia-backend/render.yaml`, `sacdia-backend/.env.example`, `sacdia-backend/src/config/env.validation.ts`, `.github/workflows/ci.yml` de cada repo.

> [!IMPORTANT]
> El producto **todavía no está en producción**. Esta guía describe cómo desplegar cada entorno. Si contradice `render.yaml` o `.env.example`, mandan esos archivos y esta guía se corrige.

**Infraestructura:**

| Pieza | Servicio |
|---|---|
| Backend (NestJS) | Render (blueprint `render.yaml`) |
| Admin (Next.js) | Vercel |
| Base de datos | Neon (PostgreSQL) |
| Cache, colas y rate limit | Redis (Upstash recomendado) |
| Archivos | Cloudflare R2 |
| Auth | Better Auth dentro del backend (JWT HS256) |
| Push | Firebase Cloud Messaging |
| Correo | Resend |
| Monitoreo | Sentry |
| App | Flutter → App Store y Play Store |

---

## 1. Entornos y ramas

Los tres repos runtime siguen el mismo flujo:

```text
development  →  preproduction (QA)  →  main (release)
```

| Rama | Uso |
|---|---|
| `development` | Integración diaria. Base de datos: rama de desarrollo de Neon |
| `preproduction` | QA antes de release |
| `main` | Release |

Reglas:

- Cada entorno tiene su propia base Neon, su propio Redis y sus propios secretos. No compartir `BETTER_AUTH_SECRET`, `QR_JWT_SECRET` ni la base de Redis entre entornos (`.env.example` lo exige para Upstash).
- Se promueve código mergeando `development` → `preproduction` → `main`; las migraciones viajan con el código y se aplican en el deploy.
- La CI de backend y app corre en las tres ramas; la del admin, en sus workflows `build`, `tests` y `typecheck`.

---

## 2. Requisitos

```bash
node --version     # 24.x (backend: engines >=24 <25; CI 24.13.1)
pnpm --version     # 10.x (backend fija pnpm@10.29.3 en packageManager)
flutter --version  # estable; el CI de la app usa 3.41.6
```

Cuentas: Neon, Render, Vercel, Upstash (o Redis compatible con TLS), Cloudflare (R2), Firebase, Google Cloud (OAuth y Maps), Apple Developer, Resend y Sentry.

---

## 3. Neon (PostgreSQL)

1. Crear una base por entorno (o una rama de Neon por entorno).
2. Anotar dos cadenas de conexión:
   - **pooled** (host con `-pooler`): `DATABASE_URL`, la usa la app;
   - **direct** (sin `-pooler`): `DATABASE_DIRECT_URL`, la usan las migraciones (`prisma.config.ts`).
3. Las migraciones se aplican solas en Render (`preDeployCommand`). Para aplicarlas a mano:

   ```bash
   cd sacdia-backend
   DATABASE_URL="<pooled>" DATABASE_DIRECT_URL="<direct>" pnpm prisma migrate deploy
   ```

   Nunca usar `prisma db push` contra un entorno compartido.

4. Base nueva: cargar catálogos, roles y permisos en este orden (`prisma/seeds/README.md`):

   ```bash
   pnpm prisma db seed                                   # prisma/seed.ts: catálogos y roles
   psql "$DATABASE_URL" -f prisma/seeds/permissions.seed.sql
   psql "$DATABASE_URL" -f prisma/seeds/role-permissions.seed.sql
   ```

   El SQL de grants no crea roles: si `seed.ts` no corrió antes, los grants no se aplican. Los seeds de datos de prueba (`core.ts`, `test-users.seed.ts`) son solo para desarrollo.

---

## 4. Render (backend)

### 4.1 Blueprint

El servicio se define en `sacdia-backend/render.yaml`:

| Campo | Valor |
|---|---|
| Tipo / runtime | `web` / `node` |
| Nombre | `sacdia-backend` |
| Región / plan | `oregon` / `starter` |
| Build | `pnpm install --frozen-lockfile && pnpm prisma generate && pnpm build` |
| Pre-deploy | `pnpm prisma migrate deploy` (aplica migraciones antes de servir tráfico) |
| Start | `pnpm start:prod` (`node dist/src/main.js`) |
| Health check | `/api/v1/health` |

Variables fijadas en el blueprint: `NODE_ENV=production`, `TRUST_PROXY_HOPS=1`, `SWAGGER_ENABLED=false`, `AUTH_REJECT_SNAKE_CASE=true`. Las secretas (`sync: false`) se cargan en el dashboard de Render: `ALLOWED_ORIGINS`, `DATABASE_URL`, `BETTER_AUTH_SECRET`, `QR_JWT_SECRET`, `REDIS_URL` y el resto de la tabla 4.2.

Crear el servicio: Render → New → Blueprint → repo `abn-r/sacdia-backend`, y elegir la rama que despliega cada entorno.

### 4.2 Variables de entorno

Catálogo completo y comentado: `sacdia-backend/.env.example`. Las marcadas como obligatorias impiden el arranque si faltan (`env.validation.ts`).

| Grupo | Variables | Obligatoria en producción |
|---|---|---|
| App | `NODE_ENV`, `PORT` (3000), `TRUST_PROXY_HOPS`, `FRONTEND_URL`, `REQUEST_TIMEOUT_MS`, `LOG_LEVEL`, `LOG_PRETTY` | — |
| CORS y OAuth | `ALLOWED_ORIGINS` (lista separada por comas de orígenes del admin/app), `ALLOWED_OAUTH_REDIRECT_URLS` | `ALLOWED_ORIGINS` sí |
| Seguridad | `SWAGGER_ENABLED` (debe ser `false`), `AUTH_REJECT_SNAKE_CASE`, `BOOTSTRAP_SECRET` (opcional, habilita `POST /admin/rbac/bootstrap-admin`) | — |
| Base de datos | `DATABASE_URL`, `DATABASE_DIRECT_URL`, `DATABASE_APPLICATION_NAME`, `PRISMA_POOL_*` | `DATABASE_URL` sí |
| Auth | `BETTER_AUTH_SECRET` (≥ 32 caracteres), `QR_JWT_SECRET` (≥ 32, distinto del anterior), `BETTER_AUTH_BASE_URL` | Los dos secretos sí |
| OAuth | `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `APPLE_CLIENT_ID`, `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY` | Si se usa el proveedor |
| Redis | `REDIS_URL` (`redis://` o `rediss://`), `CACHE_DEFAULT_TTL_MS`, `CACHE_REDIS_CONNECTION_TIMEOUT_MS` | Sí (cache, rate limit y colas fallan al arrancar sin Redis) |
| R2 | `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_REGION=auto`, `R2_SIGNED_URL_EXPIRES_SECONDS` y, por alias, `R2_BUCKET_*`, `R2_PUBLIC_URL_*`, `R2_KEY_PREFIX_*` | `HONORS_PDF`, `EVIDENCE_FILES`, `INSURANCE_EVIDENCE`, `DATA_EXPORTS`, `MONTHLY_REPORTS` y `RESOURCES_FILES` sí; el resto, al usarse |
| Carga de certificados | `CERTIFICATE_IMPORT_ALLOWED_FILE_HOSTS`, `GOOGLE_VISION_API_KEY` (OCR de imágenes; vacío = lectura manual) | — |
| Firebase | `FIREBASE_SERVICE_ACCOUNT_JSON_BASE64` (recomendado) o `FIREBASE_SERVICE_ACCOUNT_JSON` o `FIREBASE_PROJECT_ID` + `FIREBASE_PRIVATE_KEY` + `FIREBASE_CLIENT_EMAIL` | Para push |
| Correo | `EMAIL_ENABLED`, `RESEND_API_KEY`, `RESEND_FROM_EMAIL`, `RESEND_REPLY_TO` | Si `EMAIL_ENABLED=true`, también `RESEND_API_KEY`, `RESEND_FROM_EMAIL` y `REDIS_URL` |
| Sentry | `SENTRY_DSN`, `SENTRY_RELEASE` (si no se define, se usa `RENDER_GIT_COMMIT`, que inyecta Render) | — |

Buckets, prefijos y acceso de cada alias: `docs/storage/r2-keyprefix-conventions.md`. Operación del correo: `docs/guides/domain-email-operations.md`.

Generar secretos:

```bash
openssl rand -hex 32   # BETTER_AUTH_SECRET
openssl rand -hex 32   # QR_JWT_SECRET (otro valor)
```

> **Pendiente de merge (PR #448 de sacdia-backend).** Esa rama sustituye `GOOGLE_VISION_API_KEY` por ADC (`GOOGLE_APPLICATION_CREDENTIALS` como Secret File de Render, `GOOGLE_CLOUD_PROJECT`, `GOOGLE_CLOUD_QUOTA_PROJECT`) y añade `POSTHOG_PROJECT_TOKEN`/`POSTHOG_HOST`. Ver `docs/guides/google-vision-certificate-ocr.md`.

### 4.3 Verificar

```bash
curl https://<backend>/api/v1/health
# {"status":"ok","timestamp":"..."}
```

`GET /api/v1/health/details` (solo admin, con JWT) devuelve el estado de base de datos, cache, FCM y Sentry; `status` es `ok` si base de datos y cache responden y `degraded` si no.

---

## 5. Vercel (admin)

1. Vercel → Add New → Project → repo `abn-r/sacdia-admin` (framework Next.js autodetectado).
2. Elegir la rama de cada entorno (por ejemplo, `main` como producción y `preproduction` como preview de QA).
3. Variables:

| Variable | Uso |
|---|---|
| `NEXT_PUBLIC_API_URL` | URL del backend. Acepta `https://<host>`, `https://<host>/api` o `https://<host>/api/v1` (el cliente normaliza a `/api/v1`). Sin valor cae a `http://localhost:3000/api/v1` |
| `NEXT_PUBLIC_APP_URL` | URL pública del admin |
| `NEXT_PUBLIC_GOOGLE_MAPS_API_KEY`, `NEXT_PUBLIC_GOOGLE_MAPS_MAP_ID` | Mapas |
| `NEXT_PUBLIC_SENTRY_DSN` | Sentry (release por `VERCEL_GIT_COMMIT_SHA`, que inyecta Vercel) |
| `NEXT_PUBLIC_POSTHOG_PROJECT_TOKEN`, `NEXT_PUBLIC_POSTHOG_HOST` | Analítica |
| `NEXT_PUBLIC_RBAC_LEGACY_FALLBACK` | Opcional |

4. Añadir el dominio del admin a `ALLOWED_ORIGINS` del backend del mismo entorno.
5. Verificar: la URL debe mostrar el login; tras iniciar sesión, `/dashboard` carga con las cookies `sacdia_admin_access_token` y `sacdia_admin_refresh_token`.

---

## 6. Google OAuth

1. Google Cloud Console → APIs & Services → Credentials → OAuth client ID (Web application).
2. Authorized redirect URIs: la callback de Better Auth en cada backend, `https://<backend>/api/auth/callback/google` (y `http://localhost:3000/api/auth/callback/google` para desarrollo).
3. Cargar `GOOGLE_CLIENT_ID` y `GOOGLE_CLIENT_SECRET` en Render.
4. Pantalla de consentimiento: tipo External, scopes `email`, `profile`, `openid`.
5. Registrar en `ALLOWED_OAUTH_REDIRECT_URLS` las URLs de retorno exactas de admin y app.

## 7. Apple Sign In

Requiere Apple Developer Program.

1. App ID de la app (bundle `com.sacdia.app` en `ios/Runner.xcodeproj`) con "Sign in with Apple".
2. Services ID (es el valor de `APPLE_CLIENT_ID`, no el bundle ID) con dominio del backend y Return URL `https://<backend>/api/auth/callback/apple`.
3. Key de "Sign in with Apple": descargar el `.p8` y anotar el Key ID.
4. Cargar `APPLE_CLIENT_ID`, `APPLE_TEAM_ID`, `APPLE_KEY_ID` y `APPLE_PRIVATE_KEY` (contenido del `.p8`, saltos de línea como `\n`) en Render.

---

## 8. App móvil (Flutter)

La URL del backend se inyecta en compilación; `AppConstants.resolveBaseUrl` lanza error en release si `API_BASE_URL` falta o no es HTTPS.

```bash
cd sacdia-app
flutter pub get

# Android (Play Store)
flutter build appbundle --release \
  --obfuscate --split-debug-info=build/app/outputs/symbols \
  --dart-define=API_BASE_URL=https://<backend>/api/v1 \
  --dart-define=GOOGLE_MAPS_API_KEY=<key> \
  -P GOOGLE_MAPS_API_KEY=<key>

# iOS (App Store / TestFlight)
flutter build ipa --release \
  --dart-define=API_BASE_URL=https://<backend>/api/v1 \
  --dart-define=GOOGLE_MAPS_API_KEY=<key>
```

- Identificadores: Android `applicationId = com.sacdia.app`; iOS `com.sacdia.app`. El esquema de deep link para OAuth es `io.sacdia.app` (`Info.plist`).
- Archivos de Firebase (`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`) no están en el repo.
- CI (`sacdia-app/.github/workflows/ci.yml`): con los secrets `API_BASE_URL`, `GOOGLE_SERVICES_JSON_BASE64`, `GOOGLE_MAPS_API_KEY` y `ANDROID_KEYSTORE_*` genera el AAB firmado y sube símbolos a Sentry (`SENTRY_AUTH_TOKEN`, `dart run sentry_dart_plugin`). Sin keystore solo genera un APK de verificación firmado con la clave debug.
- Subida: Play Console (Internal testing) y App Store Connect (TestFlight). Antes del envío a tiendas revisar `docs/legal/store-submission-privacy-checklist.md`.

---

## 9. Verificación de extremo a extremo

```bash
API="https://<backend>/api/v1"

curl -s "$API/health"

LOGIN=$(curl -s -X POST "$API/auth/login" -H "Content-Type: application/json" \
  -d '{"email":"<usuario>","password":"<contraseña>"}')
AT=$(echo "$LOGIN" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['accessToken'])")
RT=$(echo "$LOGIN" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['refreshToken'])")

curl -s "$API/auth/me" -H "Authorization: Bearer $AT"
curl -s -X POST "$API/auth/refresh" -H "Content-Type: application/json" -d "{\"refreshToken\":\"$RT\"}"
curl -s -X POST "$API/auth/logout" -H "Authorization: Bearer $AT" -H "Content-Type: application/json" -d "{\"refreshToken\":\"$RT\"}"
curl -s -o /dev/null -w "%{http_code}\n" "$API/auth/me" -H "Authorization: Bearer $AT"   # esperado 401
```

Usuarios de prueba (solo desarrollo): `docs/testing/TEST-USERS.md`.

Checklist:

- [ ] `/api/v1/health` responde `ok` y `/health/details` muestra base de datos y cache OK.
- [ ] Login, `GET /auth/me`, refresh y logout funcionan.
- [ ] El admin inicia sesión y carga `/dashboard`.
- [ ] La app conecta con el `API_BASE_URL` del entorno.
- [ ] Sentry recibe eventos con el release correcto.

---

## 10. Troubleshooting

| Síntoma | Causa probable | Solución |
|---|---|---|
| El arranque falla con error de validación de entorno | Falta una variable obligatoria (por ejemplo `ALLOWED_ORIGINS`, `QR_JWT_SECRET`, un `R2_BUCKET_*` requerido) o `SWAGGER_ENABLED=true` en producción | Revisar el mensaje de Joi y la tabla 4.2 |
| `REDIS_URL is required ... in production` | Producción sin Redis | Configurar `REDIS_URL` del entorno |
| `QR_JWT_SECRET must be distinct from BETTER_AUTH_SECRET` | Mismo valor en ambos | Generar otro secreto |
| Error de Prisma en el pre-deploy | Migración que no aplica sobre la base del entorno | Revisar la migración en local contra una rama de Neon; no usar `db push` |
| `Property X does not exist on type PrismaService` al compilar | No se generó el cliente | El build del blueprint ya ejecuta `pnpm prisma generate`; en local, `pnpm prisma generate` |
| El registro responde que no existe el rol `user` | Base sin `prisma/seed.ts` | Ejecutar los seeds del §3 |
| `redirect_uri_mismatch` en OAuth | URL de callback no registrada | Añadir `https://<backend>/api/auth/callback/<provider>` en el proveedor |
| El navegador bloquea las llamadas del admin (CORS) | Origen del admin fuera de `ALLOWED_ORIGINS` | Añadirlo y redeplegar |
| La app release se cierra al abrir | Falta `API_BASE_URL` HTTPS en el build | Compilar con `--dart-define=API_BASE_URL=https://...` |
