# Auditoría de Servicios Externos — SACDIA

**Última actualización**: 2026-05-11
**Versión API**: v2.2.0

## Servicios Integrados

### 1. Better Auth (Autenticación, self-hosted)

**Propósito**: Identity provider self-hosted dentro del backend NestJS. Autentica usuarios con email/password y OAuth (Google, Apple). SACDIA firma JWTs HS256 sobre la sesion validada por Better Auth (Option C).

**Configuración**:
- `BETTER_AUTH_SECRET`: Secreto compartido para firmar HS256 JWTs emitidos por SACDIA
- `BETTER_AUTH_BASE_URL`: Base URL del runtime de Better Auth (montado en NestJS)
- OAuth providers (Google, Apple) configurados via Better Auth — credenciales por provider

**Módulos que lo usan**:
- `src/better-auth/*` — Runtime self-hosted (config, service, controller)
- `src/auth/*` — AuthController, AuthService, OAuthService, JwtStrategy (HS256)
- `src/auth/strategies/jwt.strategy.ts:41` — `secretOrKey: BETTER_AUTH_SECRET` (HS256)
- `src/common/guards/jwt-auth.guard.ts` — Guard de autenticación basado en Passport JWT

**Criticidad**: CRÍTICA
**Fallback**: Sin autenticación, API inutilizable. No hay fallback.

**Historico**: Migrado desde Supabase Auth en Wave 3 (2026-03 a 2026-04). Supabase ya no es identity provider — las variables `SUPABASE_*` no se usan en runtime auth actual.

---

### 2. PostgreSQL (Neon)

**Propósito**: Base de datos relacional para todo el dominio de negocio (usuarios, clubs, honores, etc.). Hosteado en Neon (3 branches: development / staging / production).

**Configuración**:
- `DATABASE_URL`: Cadena de conexión PostgreSQL nativa (Neon)
- Gestión via Prisma ORM

**Módulos que lo usan**:
- Todos los módulos de dominio (`users/`, `clubs/`, `classes/`, `honors/`, etc.)
- `src/prisma/prisma.service.ts` — Integración ORM

**Criticidad**: CRÍTICA
**Fallback**: Sin base de datos, no hay persistencia. No hay fallback.

---

### 3. Cloudflare R2 (Almacenamiento de Archivos)

**Propósito**: Almacenamiento S3-compatible para documentos, imágenes de perfil, PDFs de honores, evidencias de actividades y seguros.

**Configuración**:
- `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`
- `R2_REGION`: Por defecto `auto`
- `R2_SIGNED_URL_EXPIRES_SECONDS`: Expiración de URLs firmadas (defecto 300s)
- 8 buckets configurados con prefijos públicos/privados:
  - `user-profiles` (privado)
  - `secure-documents` → `users_honors`, `users_honors_cert`, `activities` (privados)
  - `static-assets` → `honors`, `honors_pdf`, `classes` (públicos)
  - `evidence-files`, `insurance-evidence` (privados)

**Módulos que lo usan**:
- `src/common/services/r2-file-storage.service.ts` — Operaciones S3 (upload, delete, signed URLs)
- `src/users/*`, `src/honors/*`, `src/activities/*`, `src/insurance/*`

**Criticidad**: IMPORTANTE
**Fallback**: Fallos en upload/download de archivos. Requests sin autenticación obtienen 500 InternalServerError.

---

### 4. Firebase Admin SDK (FCM Push Notifications)

**Propósito**: Envío de notificaciones push vía Firebase Cloud Messaging.

**Configuración**:
- `FIREBASE_SERVICE_ACCOUNT_JSON_BASE64`: Recomendado (service account en base64)
- `FIREBASE_SERVICE_ACCOUNT_JSON`: Alternativa (JSON escapado)
- `FIREBASE_PROJECT_ID`, `FIREBASE_PRIVATE_KEY`, `FIREBASE_CLIENT_EMAIL`: Legacy (campos separados)

**Módulos que lo usan**:
- `src/notifications/*` — Envío a usuario, broadcast y miembros de club
- `src/config/firebase-admin.module.ts` — Inicialización condicional

**Criticidad**: OPCIONAL (condicional)
**Fallback**: Si no está configurado, `isFcmConfigured()` retorna `false` y los métodos devuelven `{success: false, message: 'FCM service is not configured...'}`. Ningún error fatal.

---

### 5. Redis / Upstash (Cache y Token Blacklist)

**Propósito**: Cache distribuido, token blacklist (revocación) y gestión de sesiones.

**Configuración**:
- `REDIS_URL`: URL redis:// o rediss:// (Upstash)
- Fallback automático a cache en-memoria si falla conexión

**Módulos que lo usan**:
- `src/common/services/token-blacklist.service.ts` — Invalidación de tokens revocados
- `src/common/services/session-management.service.ts` — Sesiones activas
- Global cache via `@nestjs/cache-manager`

**Criticidad**: IMPORTANTE
**Fallback**: En-memory cache (máx 10k keys, TTL 24h). Valido en desarrollo; en producción recomendado Upstash.

---

### 6. Sentry (Monitoreo de Errores)

**Propósito**: Captura y reporte de excepciones no manejadas en producción.

**Configuración**:
- `SENTRY_DSN`: Endpoint de ingesta Sentry
- `NODE_ENV`: Determina sampling (prod: 10%, dev: 100%)
- Inicializado en `src/main.ts` (línea 20-30)

**Módulos que lo usan**:
- `src/common/interceptors/sentry.interceptor.ts` — Captura excepciones HTTP
- `src/main.ts` — Inicialización global

**Criticidad**: OPCIONAL (condicional)
**Fallback**: Si `SENTRY_DSN` no está configurado, Sentry no se inicializa. Logs locales via Pino. Sin impacto en API.

---

## Resumen de Criticidad

| Servicio | Estado | Tipo | Fallback |
|----------|--------|------|----------|
| Better Auth (self-hosted) | Requerido | Crítico | Ninguno |
| PostgreSQL (Neon) | Requerido | Crítico | Ninguno |
| Cloudflare R2 | Requerido | Importante | Error 500 |
| Firebase FCM | Opcional | Opcional | Respuesta `{success: false}` |
| Redis/Upstash | Recomendado | Importante | In-memory cache |
| Sentry | Opcional | Opcional | Logs locales |

---

## Notas Operativas

- **Variable de entorno `FRONTEND_URL`**: Configurada para CORS y URLs de callback OAuth
- **Rate Limiting**: 3 niveles (burst, sustained, long-term) en `ThrottlerModule` — independiente de servicios externos
- **Validación**: Toda entrada de usuario validada con `ValidationPipe` global — independiente de servicios externos
