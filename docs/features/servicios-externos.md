# Servicios externos: correo, colas, OCR y analítica

**Estado**: IMPLEMENTADO
**Verificado contra código**: 2026-10-04 (rama `development` de los tres repos)

Este documento describe cuatro integraciones transversales: Resend (correo), BullMQ (colas sobre Redis), Google Vision (OCR de certificados) y PostHog (analítica de producto). Otras integraciones tienen su propio documento: Firebase Cloud Messaging en [communications.md](communications.md), Cloudflare R2 en [`docs/storage/r2-keyprefix-conventions.md`](../storage/r2-keyprefix-conventions.md), exportación de datos en [`docs/architecture/DATA-EXPORT.md`](../architecture/DATA-EXPORT.md).

## Resend (correo transaccional)

- **Código**: `sacdia-backend/src/common/email/` (`EmailModule` global, `EmailService`, `EmailProcessor`, `providers/resend.provider.ts`, plantillas en `templates/*.tsx` con `@react-email/components`).
- **Variables** (`.env.example`): `EMAIL_ENABLED` (por defecto `false`), `RESEND_API_KEY`, `RESEND_FROM_EMAIL` (por defecto `SACDIA <contacto@sacdia.com>`), `RESEND_REPLY_TO`.
- **Flujo**: `EmailService` encola en la cola `emails`; `EmailProcessor` renderiza la plantilla y llama a Resend. Con `EMAIL_ENABLED` distinto de `true`, el job se descarta con un aviso en log.
- **Tipos de correo** (`email.queue.ts`): `email.data-export-ready`, `email.email-verification`, `email.password-reset`, `email.account-deletion-confirmed`, `email.cron-alert`.
- **Límites y reintentos**: el worker limita a 90 correos cada 24 horas (`EMAIL_DAILY_LIMIT`, margen sobre el plan gratuito de 100/día); 5 intentos con backoff exponencial desde 2 s. Un error de Resend se relanza para que BullMQ reintente.
- **Idioma**: el job lleva `lang`; las cadenas salen de `src/i18n/*/emails.json` (ver [i18n.md](i18n.md)).
- **Sin Redis**: la cola no se registra; `EmailService` sigue exportado, pero encolar falla.

## BullMQ (colas)

- **Dependencias**: `bullmq` + `@nestjs/bullmq`. Cada módulo registra su cola solo si `REDIS_URL` es válida (en producción Redis es obligatorio).
- **Colas reales en `development`**:

| Cola | Processor | Jobs |
|---|---|---|
| `emails` | `common/email/email.processor.ts` | los 5 tipos de correo de arriba |
| `notifications` | `notifications/notifications.processor.ts` | `send-to-user`, `send-to-section-role`, `send-to-global-role`, `send-to-club-members`, `broadcast`, `broadcast-chunk`, `realtime.invalidate` |
| `achievements` | `achievements/achievements.processor.ts` | `evaluate`, `retroactive-evaluate` |
| `background-jobs` | `background-jobs/background-jobs.processor.ts` | `monthly-reports.auto-generate`, `monthly-reports.pdf`, `finance-period.close-month`, `rankings.recalculate`, `data-export.generate` |
| `master-honors` | `honors/master-honors-recalculation.processor.ts` | recálculo por `user`, `master-honor` o `all` |
| `certificate-import-ocr` | `certificate-bulk-imports/ocr/certificate-ocr.processor.ts` (concurrencia 1) | OCR de un lote de certificados |

- **Observabilidad**: `AnalyticsModule` registra `notifications`, `achievements`, `emails` y `background-jobs` para `GET /api/v1/admin/analytics/jobs-overview` y `queues/:queueName/health` (admin: `/dashboard/system/jobs`). `master-honors` y `certificate-import-ocr` no entran en ese panel.
- **Sin Redis**: las rutas HTTP que encolan recálculo de rankings o el informe mensual corren en línea; la exportación de datos responde 503; el OCR responde `CERTIFICATE_IMPORT_OCR_UNAVAILABLE`.

## Google Vision (OCR de certificados)

- **Uso**: importación masiva de certificados ([carga-masiva-certificados.md](carga-masiva-certificados.md)). `POST /api/v1/certificate-bulk-imports/:batchId/process-ocr` encola el job `certificate-import-ocr` (`jobId` por lote, 2 intentos con 5 s de espera); el processor llama a `CertificateBulkImportsService.runQueuedOcr`.
- **Proveedor en `development`**: `GoogleVisionCertificateOcrProvider` (`ocr/google-vision-certificate-ocr.provider.ts`), registrado como `CERTIFICATE_OCR_PROVIDER` en `CertificateBulkImportsModule`.
  - Llama por REST a `https://vision.googleapis.com/v1/images:annotate` con `DOCUMENT_TEXT_DETECTION`, imagen en base64 y la clave en el header `x-goog-api-key`.
  - Clave: `GOOGLE_VISION_API_KEY`. Sin clave responde `CERTIFICATE_IMPORT_OCR_UNAVAILABLE`. Esta variable no figura en `.env.example`.
  - Solo imágenes JPEG, PNG o WebP (`CERTIFICATE_IMPORT_OCR_UNSUPPORTED_TYPE` para el resto, incluido PDF). El archivo debe estar confirmado en el bucket de importaciones de R2 y no superar `CERTIFICATE_IMPORT_MAX_BYTES`.
  - El texto se interpreta con `CertificateOcrParser` y se guarda recortado a 20 000 caracteres.
  - Existe `NoopCertificateOcrProvider`, pero el módulo no lo usa.
- **Pendiente de merge (PR #448 de sacdia-backend)**: la rama `feat/investiture-authorization-ocr` cambia a `@google-cloud/vision` con credenciales por defecto de Google (ADC, sin clave) y agrega OCR de PDF (`pdf-lib` para contar páginas). Lo describen `docs/plans/2026-09-30-vision-adc-pdf.md` y `docs/plans/2026-10-02-vision-keyless-{design,plan}.md`.

## PostHog (analítica de producto)

- **Admin** (`posthog-js`):
  - `src/instrumentation-client.ts` inicializa PostHog solo si existen `NEXT_PUBLIC_POSTHOG_PROJECT_TOKEN` y `NEXT_PUBLIC_POSTHOG_HOST`. Configuración: `autocapture: false`, `disable_session_recording: true`, `person_profiles: 'identified_only'`.
  - `src/lib/analytics/posthog.ts`: `identifyAnalyticsUser(userId)` al iniciar sesión (`auth-context.tsx`) y `resetAnalyticsUser()` al cerrar sesión (menú de usuario).
  - No hay llamadas a `capture` en el código.
- **App** (`posthog_flutter`):
  - `lib/core/analytics/posthog_analytics.dart`: `setupPosthog()` en `main.dart`, host `https://us.i.posthog.com`, `sessionReplay = false`, perfiles solo para usuarios identificados. El token del proyecto viene de `--dart-define=POSTHOG_PROJECT_TOKEN` o, si no se pasa, del token público incluido en el código (mismo proyecto que el admin).
  - `identifyAnalyticsUser` se llama desde el router al tener sesión; `resetAnalyticsUser` en la limpieza de logout. `PosthogObserver` registra las vistas de pantalla de GoRouter.
  - No hay llamadas a `capture` en el código.
- **Backend**: no usa PostHog.

## Gaps y pendientes

- `GOOGLE_VISION_API_KEY` falta en `sacdia-backend/.env.example`.
- El tope de 90 correos al día es global para todo el backend; cuando se alcanza, los correos esperan en la cola.
- PostHog no registra eventos de negocio propios en ningún cliente.
