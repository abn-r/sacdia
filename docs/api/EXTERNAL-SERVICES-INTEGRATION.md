# Integración de Servicios Externos

**Estado**: ACTIVE

**Versión**: 3.0  
**Fecha**: 2026-10-04  
**Status**: 🟡 Implementado en código (`development`); el producto aún no está en producción. Falta cerrar credenciales y verificación por entorno (preproduction/main).

---

## Resumen Ejecutivo

Servicios externos que usa el backend SACDIA en `development`:

1. **Redis**: caché (`CACHE_MANAGER`), rate limiting distribuido, blacklist JWT y colas BullMQ. Obligatorio en producción.
2. **BullMQ** (sobre Redis): colas de trabajo en segundo plano.
3. **Firebase FCM**: push y mensajes silenciosos de invalidación de caché.
4. **Resend**: correo transaccional (plantillas con `react-email`).
5. **Cloudflare R2**: almacenamiento de archivos vía `FileStorageService` (URLs firmadas).
6. **Google Vision OCR**: lectura de certificados en la importación masiva.
7. **Sentry**: monitoreo de errores, condicional por `SENTRY_DSN`.
8. **Health check**: `GET /api/v1/health` reporta `database`, `cache`, `fcm` y `sentry`.

Los nombres canónicos de variables de entorno están en `sacdia-backend/.env.example`.

---

## 1) Redis

### Estado

- ✅ Caché registrada en `src/common/common.module.ts` con `buildCacheOptions` (`src/config/cache.config.ts`).
- ✅ Rate limiting con storage Redis (`src/config/throttler.config.ts`, `src/config/redis-throttler.storage.ts`).
- ✅ **Producción: fail-fast.** Si `NODE_ENV=production` y `REDIS_URL` falta, es inválida o no conecta, la app no inicia (caché y throttler lanzan error).
- ✅ Development/test: fallback a caché in-memory. Si Redis cae en runtime, las lecturas de catálogo caen a la base de datos.

### Variable de entorno

```bash
REDIS_URL=redis://default:password@host:port
```

---

## 2) BullMQ

### Estado

- ✅ Configuración en `src/config/bullmq.config.ts` (lee `REDIS_URL`; sin Redis válido las colas quedan deshabilitadas).
- ✅ Colas registradas: `emails`, `notifications`, `achievements`, `background-jobs`, `master-honors` y `certificate-import-ocr`.
- ✅ Monitoreo admin: `GET /api/v1/admin/analytics/jobs-overview`, `GET /api/v1/admin/analytics/queues/:queueName/health` y `POST /api/v1/admin/analytics/jobs/:queue/:jobId/retry` (super-admin).
- Sin Redis, el recálculo de rankings y la generación del informe mensual corren inline; la exportación de datos responde 503.

---

## 3) Firebase Cloud Messaging (FCM)

### Estado

- ✅ Tabla `user_fcm_tokens` (migración aplicada por `prisma migrate deploy`; verificador `pnpm run verify:fcm-migration`).
- ✅ Endpoints protegidos con JWT, restricción por rol en envíos masivos y validación de ownership de tokens.
- ✅ Invalidación realtime: job `realtime.invalidate` en la cola `notifications`. API pública `NotificationsService.sendSilentToSection(...)`; payload data-only `type: 'cache_invalidate'`.
- ⚠️ Pendiente: credenciales FCM válidas por entorno.

### Contrato API

El listado vigente está en [ENDPOINTS-LIVE-REFERENCE.md](./ENDPOINTS-LIVE-REFERENCE.md), secciones `Notifications`, `FCM Tokens`, `User Notification Preferences` y `admin-notifications`. Resumen:

- Tokens: `POST/GET /fcm-tokens`, `DELETE /fcm-tokens/by-token`, `DELETE /fcm-tokens/:id`, `GET /fcm-tokens/user/:userId` (owner/admin), `POST /users/me/fcm-tokens`, `DELETE /users/me/fcm-tokens/:tokenId`.
- Envío: `POST /notifications/send`, `POST /notifications/broadcast`, `POST /notifications/club/:instanceType/:instanceId`, `GET /notifications/targets/club`.
- Bandeja y preferencias: `GET /notifications/history`, `GET /notifications/unread-count`, `PATCH /notifications/read-all`, `PATCH /notifications/:deliveryId/read`, `GET /notifications/preferences`, `PUT /notifications/preferences/:category`, `GET/PATCH /users/me/notification-preferences`.
- Admin: `GET /admin/notifications/stats`, `GET/PATCH /admin/notifications/categories`.

### Variables de entorno

```bash
# Opción preferida: service account completo
FIREBASE_SERVICE_ACCOUNT_JSON_BASE64=...
# o FIREBASE_SERVICE_ACCOUNT_JSON=...
# Fallback por campos
FIREBASE_PROJECT_ID=...
FIREBASE_CLIENT_EMAIL=...
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

---

## 4) Resend (correo)

- ✅ Proveedor `src/common/email/providers/resend.provider.ts`; envío encolado en la cola `emails` (`src/common/email/email.queue.ts`).
- ✅ Plantillas con `@react-email/components` y `@react-email/render`.
- Solo envía cuando `EMAIL_ENABLED=true`.

```bash
EMAIL_ENABLED=false
RESEND_API_KEY=re_<api-key>
RESEND_FROM_EMAIL=SACDIA <contacto@sacdia.com>
RESEND_REPLY_TO=contacto@sacdia.com
```

---

## 5) Cloudflare R2

- ✅ Abstracción `FileStorageService` (`src/common/services/file-storage.service.ts`) con implementación `r2-file-storage.service.ts`.
- ✅ Un bucket por dominio (`R2_BUCKET_*`, `R2_PUBLIC_URL_*`, `R2_KEY_PREFIX_*`) y URLs firmadas con `R2_SIGNED_URL_EXPIRES_SECONDS`.
- Ver `docs/storage/` para el detalle de buckets y prefijos.

---

## 6) Google Vision OCR

- ✅ Proveedor `src/certificate-bulk-imports/ocr/google-vision-certificate-ocr.provider.ts`, registrado como `CERTIFICATE_OCR_PROVIDER` en `CertificateBulkImportsModule`.
- ✅ Procesamiento asíncrono en la cola `certificate-import-ocr` cuando BullMQ está configurado.
- Autenticación por `GOOGLE_VISION_API_KEY` (opcional en `env.validation.ts`). Si falta, la extracción responde `400 CERTIFICATE_IMPORT_OCR_UNAVAILABLE`.
- La variante con ADC y `pdf-lib` está en la rama `feat/investiture-authorization-ocr` (**pendiente de merge, PR #448 de sacdia-backend**).

---

## 7) Sentry

- ✅ Inicialización condicional en `src/main.ts` cuando existe `SENTRY_DSN`.
- ✅ `SentryInterceptor` (`src/common/interceptors/sentry.interceptor.ts`) solo se activa cuando Sentry está habilitado.
- ⚠️ Pendiente: DSN real por entorno y alertas operativas.

```bash
SENTRY_DSN=https://<key>@<org>.ingest.sentry.io/<project>
```

---

## 8) Health Check de Dependencias

Endpoint: `GET /api/v1/health` (`src/health/health.controller.ts`). El estado global es `ok` cuando base de datos y caché responden; si no, `degraded`.

```json
{
  "status": "ok",
  "dependencies": {
    "database": { "ok": true },
    "cache": { "ok": true },
    "fcm": { "configured": true, "initialized": true },
    "sentry": { "configured": true }
  }
}
```

---

## Pendiente para cierre por entorno

1. Configurar `REDIS_URL` válida en preproduction y main (obligatoria).
2. Configurar credenciales FCM, `RESEND_API_KEY`, `GOOGLE_VISION_API_KEY` y buckets R2 por entorno.
3. Configurar `SENTRY_DSN` y reglas de alerta.
4. Verificar `GET /api/v1/health` y colas BullMQ en cada entorno con evidencia.

---

## Referencias

- `sacdia-backend/.env.example`
- `sacdia-backend/src/common/common.module.ts`
- `sacdia-backend/src/config/{cache,throttler,bullmq}.config.ts`
- `sacdia-backend/src/config/firebase-admin.module.ts`
- `sacdia-backend/src/notifications/notifications.processor.ts`
- `sacdia-backend/src/common/email/providers/resend.provider.ts`
- `sacdia-backend/src/certificate-bulk-imports/ocr/google-vision-certificate-ocr.provider.ts`
- `sacdia-backend/src/health/health.controller.ts`
