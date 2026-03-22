# Infrastructure (Health, Logging, Seguridad)

**Estado**: NO CANON (infraestructura operativa)

> Este dominio no es parte del canon de negocio. Es infraestructura operativa documentada por referencia en `docs/canon/runtime-sacdia.md` (seccion 9.1).

## Descripcion de dominio

La infraestructura de SACDIA comprende los componentes transversales que soportan la operacion del backend: health checks, logging, seguridad, rate limiting, validacion, serializacion, manejo de errores, y las integraciones con servicios externos de monitoreo y cache. Estos componentes no implementan logica de negocio pero son fundamentales para la disponibilidad, seguridad y observabilidad del sistema.

El backend esta construido sobre NestJS con una arquitectura modular donde el `CommonModule` centraliza toda la infraestructura compartida: guards de autorizacion (7), decorators (7), services transversales (6), pipes de validacion (1), filters de excepciones (2) e interceptors (2). Este modulo es importado por todos los modulos de dominio.

Las integraciones externas de infraestructura incluyen Sentry para monitoreo de errores (condicional), Redis/Upstash para cache y blacklist de tokens (condicional), y Cloudflare R2 para almacenamiento de archivos. La seguridad global se implementa mediante helmet, compression y un sistema de rate limiting en tres capas.

## Que existe (verificado contra codigo)

### Backend

#### Health Check
- **Controller**: `src/health/health.controller.ts`
- **1 endpoint publico**: `GET /api/v1/health` — Check API status
- **1 endpoint root**: `GET /api/v1` — via `src/app.controller.ts`

#### CommonModule (`src/common/`)
- **Module**: `src/common/common.module.ts`
- **Guards (7)**:
  - `jwt-auth.guard.ts` — Validacion JWT via Supabase
  - `permissions.guard.ts` — Verificacion de permisos `resource:action`
  - `club-roles.guard.ts` — Verificacion de roles de club en seccion activa
  - `global-roles.guard.ts` — Verificacion de roles globales
  - `owner-or-admin.guard.ts` — Self-service o acceso administrativo
  - `optional-jwt-auth.guard.ts` — JWT opcional (endpoints mixtos)
  - `ip-whitelist.guard.ts` — Restriccion por IP
- **Decorators (7)**:
  - `permissions.decorator.ts` — `@Permissions()`
  - `global-roles.decorator.ts` — `@GlobalRoles()`
  - `club-roles.decorator.ts` — `@ClubRoles()`
  - `current-user.decorator.ts` — `@CurrentUser()`
  - `get-user.decorator.ts` — `@GetUser()`
  - `authorization-resource.decorator.ts` — `@AuthorizationResource()`
  - `sensitive-user-subresource.decorator.ts` — `@SensitiveUserSubresource()`
- **Services (6)**:
  - `authorization-context.service.ts` — Resolucion de contexto de autorizacion del actor
  - `mfa.service.ts` — Logica de autenticacion multifactor
  - `session-management.service.ts` — Gestion de sesiones activas
  - `token-blacklist.service.ts` — Blacklist de tokens revocados (Redis)
  - `file-storage.service.ts` — Interfaz abstracta de almacenamiento
  - `r2-file-storage.service.ts` — Implementacion Cloudflare R2 (S3-compatible)
- **Pipes (1)**: Validacion global con class-validator y class-transformer
- **Filters (2)**:
  - `all-exceptions.filter.ts` — Captura global de excepciones
  - `http-exception.filter.ts` — Manejo de excepciones HTTP
- **Interceptors (2)**:
  - `audit.interceptor.ts` — Interceptor de auditoria
  - `sentry.interceptor.ts` — Reporte de errores a Sentry
- **Policy**: `sensitive-user-subresource-policy.ts` — Politica de acceso a sub-recursos sensibles
- **Supabase**: `supabase.service.ts` — Servicio de integracion con Supabase

#### Seguridad Global (configurada en `main.ts`)
- **Helmet**: Headers de seguridad HTTP
- **Compression**: Compresion gzip de respuestas
- **Rate Limiting**: Tres capas configuradas:
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
| Redis/Upstash | Configurado | Si (env) | Cache, token blacklist, rate limiting |
| Cloudflare R2 | Configurado | No | Almacenamiento de archivos (fotos, evidencias, polizas) |
| Firebase Admin | Configurado | Si (env) | Push notifications (FCM) |
| Supabase Auth | Configurado | No | Identity provider |

### Admin
- **No implementado** — No hay paginas de infraestructura, monitoreo o diagnostico

### App Movil
- **No implementado** — No hay pantallas de estado o diagnostico

### Base de datos
- `error_logs` — Tabla para logs de errores

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
- **Guards como capas**: La autorizacion se compone apilando guards (JWT -> Permissions -> ClubRoles); cada uno es independiente
- **Rate limiting en tres capas**: Proteccion contra burst, sustained y DDoS sin afectar uso normal
- **Storage abstraction**: `FileStorageService` como interfaz con `R2FileStorageService` como implementacion, permitiendo cambio de proveedor
- **Condicional por env**: Sentry, Redis y Firebase se activan solo si las variables de entorno estan configuradas, evitando fallos en desarrollo local
- **Pino para logging**: Logger estructurado JSON para facilitar parseo en herramientas de observabilidad

## Gaps y pendientes

- **Sin UI de monitoreo**: No hay dashboard de salud, metricas o diagnostico en admin
- **Sin alertas**: No hay sistema de alertas configurado mas alla de Sentry para errores
- **Storage drift**: Canon documenta Supabase Storage pero el runtime usa Cloudflare R2 — reemplazo no documentado en canon
- **Error logs sin uso claro**: La tabla `error_logs` existe pero no esta claro como se puebla o se consulta
- **Sin metricas de negocio**: No hay instrumentacion de metricas de negocio (usuarios activos, actividades creadas, etc.)

## Prioridad y siguiente accion

- **Prioridad**: Baja — infraestructura operativa estable; no afecta canon de negocio
- **Siguiente accion**: Actualizar canon para documentar Cloudflare R2 como storage provider real (reemplazando Supabase Storage). Considerar agregar dashboard de salud en admin para administradores.
