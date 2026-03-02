# Session: Auth Cutover + Session Hardening

Fecha: **2026-03-01**
Estado: **Aplicado**

## Contexto

Se ejecutó retiro inmediato de compatibilidad `snake_case` en contrato Auth, con hardening de continuidad de sesión y validación JWT/MFA.

## Cambios de contrato (runtime)

1. `POST /api/v1/auth/login` responde tokens solo en camelCase:
   - `accessToken`, `refreshToken`, `expiresAt`, `tokenType`.
2. `POST /api/v1/auth/refresh` acepta `refreshToken` en request body.
3. `refresh_token` en refresh queda retirado por default y responde:
   - `400` con `code: LEGACY_SNAKE_CASE_REMOVED`
   - `removedAt: 2026-03-01`
   - `use: refreshToken`
4. Excepción documentada de entrada OAuth:
   - `GET /api/v1/auth/oauth/callback` mantiene `access_token`/`refresh_token` en query por proveedor
   - respuesta backend en camelCase.

## Hardening técnico

1. Continuidad de sesión `refresh -> me` validada post-reinicio de backend.
2. JWT revocation efectiva en rutas protegidas:
   - token individual revocado
   - revocación global por usuario (`iat`)
3. Guard con logging de causa interna (`missing`, `expired`, `invalid_signature`, `revoked`) y respuesta externa genérica `Unauthorized`.
4. Blacklist normalizada a segundos UNIX con compatibilidad para registros históricos en ms.
5. MFA endurecido con header opcional `x-refresh-token` y error controlado:
   - `code: MFA_SESSION_BIND_FAILED` cuando Supabase requiere refresh token y no se envía.

## Operación y rollback

- Variable de entorno de control:
  - `AUTH_REJECT_SNAKE_CASE=true` (default)
- Rollback temporal:
  - `AUTH_REJECT_SNAKE_CASE=false` para aceptar `refresh_token` mientras se corrigen clientes legacy.

## Monitoreo recomendado (14 días)

- `event:auth_refresh_legacy_rejected`
- `event:auth_refresh_success`
- `event:auth_refresh_failed`
- `event:auth_guard_unauthorized url:/api/v1/auth/me`
- `event:auth_jwt_revoked_token OR event:auth_jwt_user_blacklisted`
- `event:mfa_session_bind_failed`
