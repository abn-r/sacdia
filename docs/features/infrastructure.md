# Infrastructure (Health, Logging, Seguridad)

**Estado**: NO CANON (infraestructura operativa)

> Este dominio no es parte del canon de negocio. Es infraestructura operativa documentada por referencia en `docs/canon/runtime-sacdia.md` (seccion 9.1).

## Descripcion de dominio

La infraestructura de SACDIA comprende los componentes transversales que soportan la operacion del backend: health checks, logging, seguridad, rate limiting, validacion, serializacion, manejo de errores, y las integraciones con servicios externos de monitoreo y cache. Estos componentes no implementan logica de negocio pero son fundamentales para la disponibilidad, seguridad y observabilidad del sistema.

El backend esta construido sobre NestJS con una arquitectura modular donde el `CommonModule` (`src/common/common.module.ts`) centraliza la infraestructura compartida: guards, decorators, servicios transversales, pipes, filters, interceptors, email y caché. Dos guards son `APP_GUARD` globales en `src/app.module.ts`: `GlobalJwtAuthGuard` (JWT por defecto salvo `@Public()`) y `PermissionsGuard` (fail-closed: exige `@RequirePermissions`, `@SkipPermissions` o `@Public`). El throttler (`UserAwareThrottlerGuard`) también es `APP_GUARD`.

Las integraciones externas de infraestructura son Sentry (condicional), Redis (caché, blacklist de tokens, rate limiting distribuido y colas BullMQ; obligatorio en producción), Resend (correo), Firebase FCM y Cloudflare R2. La autenticación es Better Auth self-hosted (`src/better-auth/`) con JWT HS256 firmados por SACDIA; no hay Supabase en el backend. El detalle de servicios externos está en `docs/api/EXTERNAL-SERVICES-INTEGRATION.md`.

## Que existe (verificado contra codigo)

### Backend

#### Health Check
- **Controller**: `src/health/health.controller.ts`
- **1 endpoint publico**: `GET /api/v1/health` — Check API status
- **1 endpoint root**: `GET /api/v1` — via `src/app.controller.ts`

#### CommonModule (`src/common/`)
- **Module**: `src/common/common.module.ts`
- **Guards** (`src/common/guards/`):
  - `global-jwt-auth.guard.ts` — `APP_GUARD`: valida el JWT HS256 de SACDIA en todas las rutas salvo `@Public()`
  - `jwt-auth.guard.ts` — Validacion JWT (Passport) usada explicitamente por controllers
  - `permissions.guard.ts` — `APP_GUARD` fail-closed: permisos `resource:action` + `@AuthorizationResource`
  - `global-roles.guard.ts` — Verificacion de roles globales (con alias, `GLOBAL_ROLE_ALIASES`)
  - `club-roles.guard.ts` — Verificacion de roles de club en seccion activa
  - `owner-or-admin.guard.ts` — Self-service o acceso administrativo (`admin` / `assistant-admin` / `super-admin`; el coordinador no es atajo)
  - `optional-jwt-auth.guard.ts` — JWT opcional (endpoints mixtos)
  - `mfa.guard.ts` — Bloquea JWT con `mfa_pending` salvo `@SkipMfaCheck()`
- **Decorators** (`src/common/decorators/`): `@RequirePermissions` (`permissions.decorator.ts`), `@SkipPermissions`, `@Public`, `@SkipMfaCheck`, `@GlobalRoles`, `@ClubRoles`, `@AuthorizationResource`, `@SensitiveUserSubresource`, `@CurrentUser`, `@GetUser`, `@Audit`
- **Services** (`src/common/services/`): `authorization-context.service.ts`, `mfa.service.ts`, `session-management.service.ts`, `token-blacklist.service.ts` (Redis), `file-storage.service.ts` + `r2-file-storage.service.ts`, `distributed-lock.service.ts`, `cleanup.service.ts`, `cron-run-logger.service.ts`, `cron-alert.service.ts`, `translation.service.ts`, `institutional-hierarchy.service.ts`, `ecclesiastical-year.service.ts`, `club-cycle-readiness.service.ts`, `class-assignment-resolver.service.ts`
- **Pipes**: `sanitize.pipe.ts` (XSS), `file-validation.pipe.ts`; ValidationPipe global (class-validator + class-transformer)
- **Filters**:
  - `all-exceptions.filter.ts` — Captura global de excepciones
  - `http-exception.filter.ts` — Manejo de excepciones HTTP
- **Interceptors**:
  - `sentry.interceptor.ts` — Reporte de errores a Sentry
  - Auditoria HTTP durable: `src/audit-logs/http-audit.interceptor.ts` (modulo `audit-logs`, ver [audit-log.md](audit-log.md))
- **Email**: `src/common/email/` (proveedor Resend, cola BullMQ `emails`)
- **Policy**: `sensitive-user-subresource-policy.ts` — Politica de acceso a sub-recursos sensibles

#### Colas y jobs en segundo plano
- BullMQ sobre Redis (`src/config/bullmq.config.ts`). Colas: `emails`, `notifications`, `achievements`, `background-jobs`, `master-honors`, `certificate-import-ocr`.
- `src/background-jobs/` procesa trabajos encolados por HTTP (recalculo de rankings, informe mensual). Sin Redis, esos flujos corren inline.
- Monitoreo admin en `/dashboard/system/jobs` (ver [cron-automation.md](cron-automation.md)).

#### Seguridad Global (configurada en `main.ts`)
- **Helmet**: Headers de seguridad HTTP
- **Compression**: Compresion gzip de respuestas
- **Rate Limiting** (`src/config/throttler.config.ts`, storage Redis distribuido): Tres capas configuradas (en `development`: 30/s, 200/10s, 1000/min):
  - 3 requests / 1 segundo (burst)
  - 20 requests / 10 segundos (sustained)
  - 100 requests / 60 segundos (long-term)
- **Validation**: ValidationPipe global con whitelist, transform y forbidNonWhitelisted
- **Sanitization**: Sanitizacion de inputs
- **API Versioning**: Prefijo global `/api/v1`
- **Logging**: nestjs-pino como logger estructurado

#### Integraciones externas
| Servicio | Estado | Condicional | Uso |
|----------|--------|-------------|-----|
| Sentry | Configurado | Si (env) | Monitoreo de errores en produccion |
| Redis | Configurado | Obligatorio en produccion; fallback in-memory solo en development/test | Cache, token blacklist, rate limiting, colas BullMQ |
| Resend | Configurado | Si (`EMAIL_ENABLED`) | Correo transaccional |
| Google Vision | Configurado | Si (`GOOGLE_VISION_API_KEY`) | OCR de importacion de certificados |
| Cloudflare R2 | Configurado | No | Almacenamiento de archivos (fotos, evidencias, polizas) |
| Firebase Admin | Configurado | Si (env) | Push notifications (FCM) |
| Better Auth | Configurado | No | Identity provider self-hosted (`src/better-auth/`) |

### Admin
- `/dashboard/system/jobs` y `/dashboard/system/jobs/history` — colas BullMQ y ejecuciones de cron (`/admin/analytics/jobs-overview`, `/admin/analytics/cron-runs`)
- No hay pagina de health check

### App Movil
- **No implementado** — No hay pantallas de estado o diagnostico

### Base de datos
- `error_logs` — Tabla legacy marcada DEPRECATED (ningun servicio escribe en ella)
- `cron_run_log`, `cron_alerts_log` — Ejecuciones y alertas de cron
- `audit_logs` — Auditoria durable

## Requisitos funcionales

1. El endpoint `GET /health` debe responder con el estado del servicio sin autenticacion
2. El rate limiting debe aplicarse globalmente a todos los endpoints
3. Los errores deben reportarse a Sentry en ambientes de produccion
4. Los tokens revocados deben blacklistearse en Redis para invalidacion inmediata
5. Los archivos deben almacenarse en Cloudflare R2 con URLs firmadas para acceso
6. La validacion de inputs debe ser global y rechazar campos no declarados en DTOs
7. El logging estructurado debe capturar request/response con correlacion de request ID

## Decisiones de diseno

- **CommonModule global**: Toda la infraestructura compartida vive en un solo modulo importado universalmente
- **Guards como capas**: `GlobalJwtAuthGuard` y `PermissionsGuard` corren globalmente (fail-closed); `GlobalRolesGuard`, `ClubRolesGuard` y `OwnerOrAdminGuard` se agregan por controller
- **Rate limiting en tres capas**: Proteccion contra burst, sustained y DDoS sin afectar uso normal
- **Storage abstraction**: `FileStorageService` como interfaz con `R2FileStorageService` como implementacion, permitiendo cambio de proveedor
- **Condicional por env**: Sentry, Firebase, Resend y Google Vision se activan solo si sus variables estan configuradas. Redis es opcional en desarrollo, pero en produccion la app falla al iniciar sin Redis
- **Pino para logging**: Logger estructurado JSON para facilitar parseo en herramientas de observabilidad

## Gaps y pendientes

- **Sin UI de health**: el admin muestra colas y cron, pero no el estado de `GET /health`
- **Sin alertas**: No hay sistema de alertas configurado mas alla de Sentry para errores
- **`error_logs` deprecated**: la tabla sigue en el schema sin escritores; pendiente de migracion de borrado
- **Sin metricas de negocio**: No hay instrumentacion de metricas de negocio (usuarios activos, actividades creadas, etc.)

## Prioridad y siguiente accion

- **Prioridad**: Baja — infraestructura operativa estable; no afecta canon de negocio
- **Siguiente accion**: Considerar exponer el estado de `GET /health` en el admin y retirar `error_logs`.
