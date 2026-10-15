# Technology Stack

**Estado**: ACTIVE
**Actualizado**: 2026-10-04 (verificado contra `development` de los tres repos runtime)

> [!IMPORTANT]
> Baseline tecnológica real del workspace. Solo lista lo que está en `package.json`, `pubspec.yaml`, `render.yaml` y el código.
> Para la topología completa y las cifras del sistema ver `docs/canon/runtime-sacdia.md`.

---

## 1. Visión general

- **Tipo**: full-stack con backend REST y dos clientes (admin web y app móvil).
- **Repos**: `sacdia-backend`, `sacdia-admin`, `sacdia-app` (independientes) y `sacdia` (documentación). `sacdia-docs` es el portal de manuales (pendiente de rediseño).
- **Ramas**: `development` → `preproduction` (QA) → `main`. El producto aún no está en producción.

## 2. Puertos y URLs de desarrollo

| Servicio | URL | Fuente |
|---|---|---|
| Backend | `http://localhost:3000/api/v1` | `PORT` por defecto 3000 (`src/main.ts`) |
| Swagger | `http://localhost:3000/api` (solo con `SWAGGER_ENABLED=true`) | `src/main.ts` |
| Health | `GET http://localhost:3000/api/v1/health` | `src/health/health.controller.ts` |
| Admin | `http://localhost:3001` | `next dev -p 3001` |
| App | `API_BASE_URL` por `--dart-define`; en debug cae a `http://localhost:3000/api/v1` | `lib/core/constants/app_constants.dart` |
| Redis local | `redis://localhost:6379` | `.env.example` |

## 3. Backend (`sacdia-backend`)

| Área | Dependencia (versión declarada) |
|---|---|
| Runtime | Node.js `>=24 <25` (CI `24.13.1`), pnpm `10.29.3` (`packageManager`) |
| Framework | NestJS `^11.2` (`common`, `core`, `platform-express`, `config`, `jwt`, `passport`, `schedule`, `swagger`, `throttler`, `bullmq`, `cache-manager`) |
| Lenguaje | TypeScript `^6.0` |
| ORM | Prisma `^7.9.1` + `@prisma/adapter-pg` + `pg` |
| Auth | `better-auth ^1.6`, `passport-jwt`, `otplib` (TOTP), `bcryptjs` |
| Validación | `class-validator`, `class-transformer` (DTOs); `joi` (variables de entorno) |
| i18n | `nestjs-i18n` (`src/i18n/{es,en,fr,pt-BR}`) |
| Colas y cache | `bullmq`, `redis`, `@keyv/redis`, `cache-manager` |
| Storage | `@aws-sdk/client-s3`, `@aws-sdk/s3-request-presigner` (Cloudflare R2) |
| Push | `firebase-admin` |
| Correo | `resend`, `@react-email/components`, `@react-email/render` |
| Documentos | `pdfkit`, `qrcode`, `xlsx` (SheetJS desde su CDN oficial) |
| Seguridad HTTP | `helmet`, `compression`, `sanitize-html` |
| Logs y errores | `nestjs-pino`, `pino`, `@sentry/nestjs`, `@sentry/node`, `@sentry/profiling-node` |
| Tests | Jest `^30` + `ts-jest`, `@nestjs/testing`, `supertest`; e2e en `test/` |

Redis es obligatorio en producción (cache, rate limiting y BullMQ fallan al arrancar si falta). En desarrollo hay fallback en memoria.

## 4. Admin web (`sacdia-admin`)

| Área | Dependencia |
|---|---|
| Framework | Next.js `16.2.4` (App Router), React `19.2.3` |
| UI | Tailwind CSS v4, shadcn/ui (`radix-ui`, `@base-ui/react`), `lucide-react`, `@hugeicons/react`, `recharts`, `sonner`, `vaul`, `cmdk` |
| Datos | `axios` (cliente en `src/lib/api/client.ts`), `@tanstack/react-query`, `@tanstack/react-table` |
| Formularios | `react-hook-form` + `zod` (`@hookform/resolvers`) |
| Estado | `zustand` (preferencias de tema, layout y sidebar) |
| i18n | `next-intl` (`messages/{es,en,fr,pt-BR}.json`) |
| Mapas | `@vis.gl/react-google-maps` |
| Observabilidad | `@sentry/nextjs`, `posthog-js` |
| Tests | Vitest `^3`, Testing Library, `msw`, `jsdom` |
| CI | GitHub Actions con Node 22 + pnpm 10: `pnpm build`, `pnpm test`, `pnpm typecheck` |

## 5. App móvil (`sacdia-app`)

| Área | Dependencia |
|---|---|
| SDK | Flutter estable (CI `3.41.6`), Dart `^3.6.1` |
| Estado | `flutter_riverpod ^2.6` |
| HTTP | `dio ^5.8`, `connectivity_plus` |
| Navegación | `go_router ^15.2` |
| Errores funcionales | `dartz` (`Either<Failure, T>` en repositorios) |
| Almacenamiento | `flutter_secure_storage` (tokens), `shared_preferences`, `hive` + `hive_flutter` (borradores locales), `flutter_cache_manager`, `cached_network_image` |
| i18n | `easy_localization` (`assets/translations/{es,en,fr,pt-BR}.json`) |
| Firebase | `firebase_core`, `firebase_messaging`, `firebase_app_check` |
| Mapas y ubicación | `google_maps_flutter`, `geolocator`, `geocoding` |
| Otros | `mobile_scanner`, `qr_flutter`, `pdf`, `image_picker`, `image_cropper`, `file_picker`, `local_auth`, `home_widget`, `secure_application`, `showcaseview` |
| Observabilidad | `sentry_flutter`, `posthog_flutter` |
| Generación de código | `build_runner`, `freezed`, `json_serializable`; tests con `flutter_test`, `mockito` |
| CI | `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test` sobre `main`, `preproduction` y `development` |

## 6. Datos e infraestructura

| Componente | Proveedor | Notas |
|---|---|---|
| Base de datos | PostgreSQL en Neon | `DATABASE_URL` (pooler) para la app; `DATABASE_DIRECT_URL` para migraciones |
| Migraciones | Prisma Migrate | `prisma/migrations/`; en Render, `preDeployCommand: pnpm prisma migrate deploy`. Nunca `prisma db push` contra entornos compartidos |
| Cache / colas | Redis (Upstash recomendado, un base por entorno) | `REDIS_URL` |
| Archivos | Cloudflare R2 | Un alias por tipo de archivo; ver `docs/storage/r2-keyprefix-conventions.md` |
| Hosting backend | Render | Blueprint `sacdia-backend/render.yaml` |
| Hosting admin | Vercel | Release de Sentry por `VERCEL_GIT_COMMIT_SHA` |
| Push | Firebase Cloud Messaging | Notificaciones visibles y mensajes silenciosos de invalidación |
| Correo | Resend | Activado con `EMAIL_ENABLED=true` |
| OCR | Google Cloud Vision | Certificados; ADC local (`OCR_MODE=direct`) o proxy keyless en Cloud Run (`OCR_MODE=remote`, no desplegado) |
| Observabilidad | Sentry (3 runtimes), PostHog (admin y app) | |

## 7. Modelo de autenticación

Better Auth autentica; SACDIA firma su propio JWT (Option C).

- **Access token**: JWT HS256 firmado con `BETTER_AUTH_SECRET`, claims `iss=https://api.sacdia.app`, `aud=sacdia:access`, `sub`, `email` y `sid` (id de sesión de Better Auth, cuando existe); expira en 8 h. Lo emite el backend (`BetterAuthService.signJwt`).
- **Refresh**: la sesión de Better Auth dura 7 días (`updateAge` de 1 día). `POST /auth/refresh` rota el access token.
- **Sesiones**: máximo 5 concurrentes por usuario; blacklist de JWT en Redis.
- **MFA**: TOTP; un token con `mfa_pending: true` solo sirve para completar `POST /auth/mfa/verify`.
- **OAuth**: Google y Apple vía Better Auth (`ALLOWED_OAUTH_REDIRECT_URLS`).
- **QR de miembro**: JWT aparte firmado con `QR_JWT_SECRET` (distinto obligatoriamente de `BETTER_AUTH_SECRET`), `aud=sacdia:qr-member`. No sirve como token de API.
- **Admin**: guarda access y refresh en cookies httpOnly (`sacdia_admin_access_token` 8 h, `sacdia_admin_refresh_token` 7 días; `sameSite=strict`, `secure` en producción) mediante las rutas `src/app/api/auth/{token,refresh,me,logout}`. Las rutas `/dashboard/*` se protegen en `src/proxy.ts`.
- **App**: guarda los tokens en `flutter_secure_storage` (`lib/core/auth/app_auth_service.dart`) y los envía como `Authorization: Bearer` desde el interceptor de Dio.

Detalle canónico: `docs/canon/auth/runtime-auth.md`.

## 8. Autorización

- Guards globales: throttler, `GlobalJwtAuthGuard` y `PermissionsGuard` (deny-by-default: cada handler declara `@Public()`, `@SkipPermissions()` o `@RequirePermissions(...)`).
- Permisos `recurso:acción` en `permissions`, asignados a roles en `role_permissions` (seeds SQL en `prisma/seeds/`).
- Admin y app deciden qué pantallas mostrar con el screen catalog (`sacdia-admin/src/lib/auth/screen-catalog/` y su hermano Dart `sacdia-app/lib/core/authorization/`), que debe reflejar los permisos del backend.

## 9. Restricciones técnicas vigentes

- No introducir Supabase (retirado en la migración de 2026-03) ni otro proveedor de auth.
- No exponer Swagger en producción (`SWAGGER_ENABLED` no puede ser `true` con `NODE_ENV=production`).
- `ALLOWED_ORIGINS` es obligatoria en producción.
- No hay pasarela de pagos: órdenes de pago, pedidos y seguros registran comprobantes de pagos externos.
- La app no es offline-first: cache local + invalidación (`docs/canon/runtime-resiliencia-red.md`).
- No añadir dependencias nuevas sin acuerdo explícito del responsable del repo.

## 10. Decisiones técnicas puntuales

### OCR de certificados con ADC y proxy keyless (decisión 2026-10-01; revisada 2026-10-07)

Bibliotecas **autorizadas explícitamente por el usuario**: `@google-cloud/vision` (SDK oficial 6.1.1) y `pdf-lib` (1.17.1), solo backend. Reemplazan autenticación por API key y permiten analizar PDFs reales. No añadir una dependencia PDF ni credenciales Google al frontend.

- `GoogleVisionCertificateOcrProvider` (modo `OCR_MODE=direct`, solo ADC local en la Mac): cliente singleton lazy por instancia Nest, ADC validado antes de RPC, `fallback: false` (gRPC), Buffer/protobuf. Evita expansión base64 REST/JSON para conservar el límite binario existente 10 MiB. No GCS, objeto público ni renovación OAuth manual. Envío gRPC limitado a 12 MiB, recepción 16 MiB; deadline 25 s/sin retries SDK; cola BullMQ independiente mantiene dos intentos/concurrencia 1.
- PDF de 1–5 páginas completas; `pdf-lib` valida estructura/conteo y rechaza cifrado sin `ignoreEncryption`. Helper compartido en confirmación y OCR; verificación mínima de cierre/xref, **no** conformidad ISO completa. La contención (TaskR, aprobada en local) usa un parche de `pdf-lib` 1.17.1 (tope de descompresión) y un `worker_thread` descartable con heap acotado, un worker a la vez, dimensionado para Render Free (512 MB, 0,1 CPU); `confirm` responde HTTP 429 `CERTIFICATE_IMPORT_PDF_BUSY` sin turno. Buffer validado se sella con clave PDF exclusiva por intento para no depender de staging mutable/concurrente.
- ADC (modo `direct`) opcional al arrancar: `GOOGLE_APPLICATION_CREDENTIALS`, `GOOGLE_CLOUD_PROJECT`, `GOOGLE_CLOUD_QUOTA_PROJECT`. Render no tiene ADC ni claves de cuenta de servicio (la organización las bloquea). `GOOGLE_VISION_API_KEY` no autentica este proveedor. Sin Redis/ADC no hay éxito OCR, pero captura manual con evidencia válida sigue posible.
- Tradeoff: SDK/gRPC agrega dependencias; parser de entrada es una superficie no confiable y requiere monitorización. Pin `@grpc/grpc-js` 1.14.5 en lockfile para la corrección auditada; no afirmar que todo el audit del backend está limpio: persisten hallazgos ajenos del baseline (Joi, brace-expansion, engine.io). Sin prueba Vision live ni despliegue en este trabajo.
- **Proxy keyless (`OCR_MODE=remote`)**: Render → HTTPS con HMAC-SHA256 → proxy `sacdia-ocr-proxy` en Cloud Run (`us-east4`) → Vision en `us-vision.googleapis.com`. Paquete autónomo Node 24 con type stripping, sin Nest; dependencias `@google-cloud/firestore` 9.3.1 y `@google-cloud/vision` 6.1.1; ledger Firestore Standard solo con metadata; 400 páginas por día UTC y por entorno. El backend tiene su propio firmante (`ocr-proxy-signer.ts`); no importa el proxy. Variables del backend: `OCR_MODE`, `OCR_PROXY_URL` (URL completa con `/v1/ocr`), `OCR_PROXY_ENV`, `OCR_PROXY_KID`, `OCR_PROXY_SECRET` (base64 de ≥ 32 bytes). Variables del proxy: `OCR_ENV`, `OCR_KID_CURRENT`, `OCR_SECRET_CURRENT`, `OCR_KID_PREVIOUS`, `OCR_SECRET_PREVIOUS`, `OCR_MAX_PAGES_PER_ENV_PER_DAY`, `GOOGLE_CLOUD_PROJECT`, `PORT`, `OCR_SHUTDOWN_GRACE_MS`. Con `NODE_ENV=production`, `OCR_MODE` es obligatorio y la URL exige https; `remote` incompleto no arranca ni cae a ADC. Los servicios de Render están en plan Free y `render.yaml` (que declara `starter`) está desincronizado.
- **Estado (2026-10-07)**: Task0, 1, 1b, 2, R, 3 y 4 **aprobados en local** (`PASS_LOCAL_SLICE`). **No desplegado**: no existen Cloud Run, Firestore, Secret Manager ni el modo `remote` en Render. Alternativa API key descartada (Vision solo tiene cuotas por minuto; una key filtrada expone del orden de US$19 000 por día frente a unos US$0,60 por día de un HMAC acotado). Decisión completa: [ADR 11](../api/ARCHITECTURE-DECISIONS.md).
- [Runbook Mac/Render, modos, rotación del secreto y operación](../guides/google-vision-certificate-ocr.md) · [infraestructura de preproducción](../guides/ocr-proxy-preprod-infra.md). Canonical workflow de aprobación humana/investidura no cambia.
