# SACDIA — Deployment Guide

**Estado**: ACTIVE
**Actualizado**: 2026-10-13
**Fuentes**: `sacdia-backend/render.yaml`, `sacdia-backend/src/config/env.validation.ts`, `.github/workflows/ci.yml` de cada repo, el dashboard de Render y Neon (topología informada por el responsable de infraestructura el 2026-10-13) y `docs/guides/ocr-proxy-preprod-infra.md`.

> [!IMPORTANT]
> Hoy existe **un solo entorno en línea**, y se despliega desde la rama `development`: el servicio de Render "API Sacdia" y el admin de Vercel construyen `development` y usan la rama `development` de Neon como base viva. Las ramas `staging` y `production` de Neon existen pero **no se usan**. La sección 0 describe esa topología real. Las secciones 1 a 10 son la receta de referencia para levantar entornos separados cuando se creen; donde difieren de la topología actual, manda la sección 0. Si algo contradice `render.yaml` o `env.validation.ts`, mandan esos archivos y esta guía se corrige (ojo: `render.yaml` ya no describe el servicio real, ver 0.2).

**Infraestructura:**

| Pieza | Servicio |
|---|---|
| Backend (NestJS) | Render, web service "API Sacdia" (Free) |
| Admin (Next.js) | Vercel, `https://admin.sacdia.com` |
| Base de datos | Neon (PostgreSQL), un proyecto con 3 ramas |
| Proxy OCR | Cloud Run (proxy keyless hacia Google Vision) |
| Cache, colas y rate limit | Redis (Upstash recomendado) |
| Archivos | Cloudflare R2 |
| Auth | Better Auth dentro del backend (JWT HS256) |
| Push | Firebase Cloud Messaging |
| Correo | Resend |
| Monitoreo | Sentry |
| App | Flutter → App Store y Play Store |

---

## 0. Topología actual (2026-10-13)

```text
GitHub (rama development)
   ├─ push ─► Render "API Sacdia" (auto-deploy) ─► Neon rama development  ◄── base viva
   │              └─ OCR firmado ─► Cloud Run (proxy OCR) ─► Google Vision
   └─ push ─► Vercel (admin.sacdia.com)
Neon ramas staging y production: existen y están migradas, sin uso.
```

| Pieza | Estado real |
|---|---|
| Backend | Render web service **"API Sacdia"**, plan **Free**, rama **`development`**, auto-deploy **activado** |
| Admin | Vercel, `https://admin.sacdia.com`, despliega **`development`** |
| Base de datos | Neon. `DATABASE_URL` del backend apunta a la rama **`development`** (endpoint `ep-rough-hill-anztwk76`): es la base viva. Las ramas `staging` y `production` existen y tienen las migraciones aplicadas, pero ningún servicio las usa |
| OCR | Proxy keyless en Cloud Run; runbook en `docs/guides/ocr-proxy-preprod-infra.md` |
| Otros servicios | Redis, R2, Firebase, Resend y Sentry según la tabla 4.2; su cuenta y plan concretos no se documentan aquí |

> No hay entorno de preproducción separado: cada merge a `development` de backend o admin llega a la instancia en línea. Y como el pre-deploy de Render corre `prisma migrate deploy` contra la base viva, **cada migración que se mergea se aplica de inmediato a datos reales**. Revisar migraciones con ese criterio antes de mergear (ver 0.4).

### 0.1 Render "API Sacdia"

| Campo | Valor |
|---|---|
| Tipo / plan | web service / **Free** (512 MB de RAM) |
| Rama | `development`, auto-deploy activado |
| Pre-deploy | `prisma migrate deploy` (aplica migraciones antes de servir tráfico; nunca `db push`) |
| Start | `node --max-old-space-size=320 --max-semi-space-size=2 dist/src/main.js` |
| Health check | endpoint `GET /api/v1/health` (recomendado fijarlo como Health Check Path, ver abajo) |

- **Start con límites de memoria.** El comando de arranque salta `pnpm start:prod` (que es `node dist/src/main.js`) y limita el heap de V8 a 320 MiB y el semi-espacio a 2 MiB para dejar margen bajo los 512 MB del plan Free. Si el proceso supera el límite de memoria de la instancia, Render lo reinicia.
- **Health Check Path (recomendado).** Configurar en Render → Settings → Health Check Path el valor `/api/v1/health`. Así Render solo pasa el tráfico al deploy nuevo cuando responde `{"status":"ok"}` y reinicia la instancia si deja de responder. El servicio real difiere del blueprint (ver más abajo), así que lo que declara `render.yaml` (`healthCheckPath`) no se aplica solo.
- **Diferencias con `render.yaml`.** El blueprint del repo define otro servicio (`sacdia-backend`, plan `starter`, start `pnpm start:prod`). El servicio real se llama "API Sacdia", es Free y usa el start de arriba. Los cambios de nombre, plan, start o health se hacen en el dashboard; cambiar `render.yaml` no los toca. Alinear el blueprint con la realidad (o documentar que es solo referencia) es un pendiente.
- **Plan Free.** Según la documentación de Render, los web services Free se suspenden tras un periodo sin tráfico y la primera petición posterior paga un arranque en frío. Es esperable en este entorno.
- **Registro de memoria.** El backend escribe una línea estructurada con el mensaje `Process memory` al arrancar (`phase: boot`) y luego cada `PROCESS_MEMORY_LOG_INTERVAL_MINUTES` minutos (`phase: interval`). Por defecto 15; `0` desactiva el intervalo y deja la línea de arranque; valor entero ≥ 0. Campos: `rss_mib`, `heap_used_mib`, `heap_total_mib`, `external_mib`, `array_buffers_mib`, `heap_size_limit_mib`, `uptime_seconds`; sin datos personales. Para ver la presión real de memoria, filtrar los logs de Render por `Process memory` y comparar `rss_mib` con los 512 MB del plan (código: `sacdia-backend/src/common/observability/process-memory-logger.service.ts`).
- **Variables.** Las secretas se cargan en el dashboard (tabla 4.2). Las de OCR remoto, en 0.3.

### 0.2 Neon

- Un proyecto, tres ramas: `development`, `staging`, `production`.
- **`development` es la base viva**: `DATABASE_URL` de "API Sacdia" apunta a su endpoint (`ep-rough-hill-anztwk76`, cadena pooled). Es lo que el servicio en línea lee y escribe.
- `staging` y `production` existen y están migradas, pero **ningún servicio las consume**. No tratarlas como respaldo de `development`: no reciben sus datos.
- Las migraciones se aplican solas en el pre-deploy de Render contra la rama que indique `DATABASE_URL`. Para aplicarlas a mano a otra rama, ver el §3.
- Nunca incluir cadenas de conexión completas ni contraseñas en docs, tickets o chats; el endpoint (`ep-…`) identifica la rama, el resto es secreto.

### 0.3 Admin y OCR

- **Admin (Vercel).** `https://admin.sacdia.com`, desplegando la rama `development`. Variables en el §5; el dominio del admin debe estar en `ALLOWED_ORIGINS` del backend.
- **OCR (Cloud Run).** El OCR de certificados no usa llave de API: el backend firma la solicitud (HMAC) hacia un proxy en Cloud Run que habla con Vision con identidad de servicio, sin claves. Procedimiento, rollback y costos en `docs/guides/ocr-proxy-preprod-infra.md` (el documento conserva el estado "propuesto" de su redacción del 2026-10-07; el proxy ya está desplegado según el responsable). En Render, con `NODE_ENV=production`, `OCR_MODE` es obligatorio; con `OCR_MODE=remote` también `OCR_PROXY_URL` (URL completa del endpoint, `https://<host>/v1/ocr`), `OCR_PROXY_ENV`, `OCR_PROXY_KID` y `OCR_PROXY_SECRET`. Si falta alguna, el arranque falla (no hay fallback a credenciales por defecto). Solo nombres aquí; los valores viven en Render y Secret Manager.

### 0.4 Reglas de migraciones

- **Nunca `CREATE INDEX CONCURRENTLY` en una migración que también tenga bloques `DO`.** Prisma ejecuta el archivo como un solo lote; Postgres rechaza `CONCURRENTLY` dentro de una transacción y `migrate deploy` falla con **P3018** (error de base de datos **25001**). Pasó con `20261013100000_honor_instructor_proposals` y se corrigió en sacdia-backend (PR #485: índices sin `CONCURRENTLY` y una prueba que lo exige).
- Para tablas nuevas y vacías (el caso habitual), un `CREATE INDEX` normal es instantáneo. Escribir las migraciones **re-ejecutables** (`IF NOT EXISTS`, `DROP CONSTRAINT IF EXISTS`, manejo de `duplicate_object`) para que un reintento tras un fallo parcial no tropiece.
- Si de verdad hace falta un índice concurrente sobre una tabla grande y existente, hacerlo fuera de `migrate deploy` (a mano con `psql`, con aprobación) y dejar la migración sin ese índice o con `IF NOT EXISTS`.
- Una migración fallida queda registrada en `_prisma_migrations` y bloquea los deploys siguientes (**P3009**) hasta resolverla (corregir y `prisma migrate resolve`). Con auto-deploy sobre la base viva, un fallo así deja el servicio sin desplegar: vigilar el log del pre-deploy tras cada merge con migraciones.
- La shadow DB no es fiable en este proyecto: las migraciones se escriben a mano y se aplican con `migrate deploy`.

---

## 1. Entornos y ramas

> **Hoy** solo la rama `development` está conectada a un entorno en línea (ver sección 0). Lo que sigue es el flujo objetivo, para cuando existan los demás entornos.

Los tres repos runtime siguen el mismo flujo:

```text
development  →  preproduction (QA)  →  main (release)
```

| Rama | Uso |
|---|---|
| `development` | Integración diaria. **Hoy también es el entorno en línea**; base de datos: rama `development` de Neon |
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

> **Solo referencia.** El servicio real ("API Sacdia", Free) no sale de este blueprint y difiere en nombre, plan y comando de arranque (ver 0.1). Usar esta tabla para crear un servicio nuevo, no para describir el actual.

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
| Carga de certificados y OCR | `CERTIFICATE_IMPORT_ALLOWED_FILE_HOSTS`, `OCR_MODE` (`direct` o `remote`), y con `remote`: `OCR_PROXY_URL`, `OCR_PROXY_ENV`, `OCR_PROXY_KID`, `OCR_PROXY_SECRET` | `OCR_MODE` sí en producción; las `OCR_PROXY_*` si es `remote` |
| Observabilidad | `PROCESS_MEMORY_LOG_INTERVAL_MINUTES` (entero ≥ 0, por defecto 15; `0` solo desactiva el intervalo), `POSTHOG_PROJECT_TOKEN`, `POSTHOG_HOST` | — |
| Firebase | `FIREBASE_SERVICE_ACCOUNT_JSON_BASE64` (recomendado) o `FIREBASE_SERVICE_ACCOUNT_JSON` o `FIREBASE_PROJECT_ID` + `FIREBASE_PRIVATE_KEY` + `FIREBASE_CLIENT_EMAIL` | Para push |
| Correo | `EMAIL_ENABLED`, `RESEND_API_KEY`, `RESEND_FROM_EMAIL`, `RESEND_REPLY_TO` | Si `EMAIL_ENABLED=true`, también `RESEND_API_KEY`, `RESEND_FROM_EMAIL` y `REDIS_URL` |
| Sentry | `SENTRY_DSN`, `SENTRY_RELEASE` (si no se define, se usa `RENDER_GIT_COMMIT`, que inyecta Render) | — |

Buckets, prefijos y acceso de cada alias: `docs/storage/r2-keyprefix-conventions.md`. Operación del correo: `docs/guides/domain-email-operations.md`.

Generar secretos:

```bash
openssl rand -hex 32   # BETTER_AUTH_SECRET
openssl rand -hex 32   # QR_JWT_SECRET (otro valor)
```

> `GOOGLE_VISION_API_KEY` ya no existe en la validación de entorno. El OCR directo usa credenciales por defecto de Google (`GOOGLE_APPLICATION_CREDENTIALS`, `GOOGLE_CLOUD_PROJECT`, `GOOGLE_CLOUD_QUOTA_PROJECT`) y el remoto usa el proxy de Cloud Run (0.3). Ver `docs/guides/google-vision-certificate-ocr.md`.

### 4.3 Verificar

```bash
curl https://<backend>/api/v1/health
# {"status":"ok","timestamp":"..."}
```

En "API Sacdia" (plan Free) la primera llamada tras un periodo inactivo puede tardar por el arranque en frío (0.1); repetirla antes de dar el servicio por caído.

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
| `prisma migrate deploy` falla con P3018 / 25001 (`CREATE INDEX CONCURRENTLY cannot run inside a transaction block`) | Migración con `CONCURRENTLY` junto a bloques `DO` | Quitar `CONCURRENTLY` (ver 0.4), dejar la migración re-ejecutable y resolver el registro fallido (P3009) antes de redeplegar |
| El navegador bloquea las llamadas del admin (CORS) | Origen del admin fuera de `ALLOWED_ORIGINS` | Añadirlo y redeplegar |
| La app release se cierra al abrir | Falta `API_BASE_URL` HTTPS en el build | Compilar con `--dart-define=API_BASE_URL=https://...` |
