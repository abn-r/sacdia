# Integración de Servicios Externos

**Estado**: ACTIVE

**Versión**: 2.0  
**Fecha**: 2026-02-13  
**Status**: 🟡 Implementado en código, pendiente cierre por entorno (staging/prod)

---

## Resumen Ejecutivo

Estado actual de servicios externos en backend SACDIA:

1. **Redis**: integración con fallback a in-memory implementada.
2. **Firebase FCM**: módulo y endpoints operativos con hardening de seguridad aplicado.
3. **Sentry**: inicialización condicional por `SENTRY_DSN` + interceptor global condicional.
4. **Health check**: `GET /api/v1/health` reporta estado de `database`, `cache`, `fcm`, `sentry`.

---

## 1) Redis

### Estado

- ✅ Integración en `src/common/common.module.ts`.
- ✅ Fallback controlado a cache in-memory si Redis no conecta.
- ⚠️ Pendiente: configurar `REDIS_URL` productiva válida por entorno.

### Variable de entorno

```bash
REDIS_URL=redis://default:password@host:port
```

### Criterio operativo

- Si Redis falla, la app **debe iniciar** en modo degradado sin romper requests.

---

## 2) Firebase Cloud Messaging (FCM)

### Estado

- ✅ Tabla `user_fcm_tokens` y migración `20260204_add_user_fcm_tokens` aplicable por `prisma migrate deploy`.
- ✅ Endpoints protegidos con JWT.
- ✅ Restricción por rol en envíos masivos.
- ✅ Validación de ownership en operación de tokens.
- ⚠️ Pendiente: credenciales FCM válidas por entorno para inicialización real.

### Contrato API vigente (2026-02-13)

#### Gestión de Tokens

- `POST /api/v1/fcm-tokens` (JWT requerido)
  - `userId` se obtiene del JWT autenticado.
- `GET /api/v1/fcm-tokens` (JWT requerido)
  - Lista tokens del usuario autenticado.
- `DELETE /api/v1/fcm-tokens/:token` (JWT requerido)
  - Solo permite desactivar tokens propios.
- `GET /api/v1/fcm-tokens/user/:userId` (JWT requerido, owner/admin)
  - Endpoint de compatibilidad para owner o admin.

#### Envío de Notificaciones

- `POST /api/v1/notifications/send` (JWT requerido)
- `POST /api/v1/notifications/broadcast` (JWT + rol `admin|super_admin`)
- `POST /api/v1/notifications/club/:sectionId` (JWT + rol `admin|super_admin`)

### Variables de entorno

```bash
FIREBASE_PROJECT_ID=...
FIREBASE_CLIENT_EMAIL=...
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

---

## 3) Sentry

### Estado

- ✅ Inicialización condicional en `src/main.ts` cuando existe `SENTRY_DSN`.
- ✅ `SentryInterceptor` solo se activa cuando Sentry está habilitado.
- ⚠️ Pendiente: DSN real por entorno + alertas operativas.

### Variable de entorno

```bash
SENTRY_DSN=https://<key>@<org>.ingest.sentry.io/<project>
```

---

## 4) Health Check de Dependencias

Endpoint:

- `GET /api/v1/health`

Respuesta de referencia:

```json
{
  "status": "ok",
  "dependencies": {
    "database": { "ok": true },
    "cache": { "ok": true },
    "fcm": { "configured": true, "initialized": false },
    "sentry": { "configured": true }
  }
}
```

---

## Validación Ejecutada (Local)

Checklist técnico ejecutado el 2026-02-13:

1. `pnpm run build` ✅
2. `pnpm run test -- src/notifications/fcm-tokens.service.spec.ts` ✅
3. `pnpm run test:e2e -- test/notifications-security.e2e-spec.ts test/admin-catalogs.e2e-spec.ts` ✅
4. `pnpm prisma migrate deploy` ✅
5. `pnpm run verify:fcm-migration` ✅
6. `GET /api/v1/health` en `start:prod` ✅

---

## Pendiente para Cierre Productivo

1. Configurar `REDIS_URL` válida en staging/prod.
2. Configurar `FIREBASE_PRIVATE_KEY` válida (PEM correcto) en staging/prod.
3. Configurar `SENTRY_DSN` y reglas de alerta en entorno productivo.
4. Repetir checklist completo en staging/prod con evidencia.

---

## Referencias

- `docs/history/implementation/IMPLEMENTATION-SESSION-2026-02-13-admin-hardening.md`
- `sacdia-backend/src/common/common.module.ts`
- `sacdia-backend/src/config/firebase-admin.module.ts`
- `sacdia-backend/src/notifications/notifications.controller.ts`
- `sacdia-backend/src/notifications/fcm-tokens.service.ts`
- `sacdia-backend/src/health/health.controller.ts`
