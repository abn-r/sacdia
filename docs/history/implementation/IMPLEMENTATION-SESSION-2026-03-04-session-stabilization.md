# Session: Session Stabilization (Auth)

Fecha: **2026-03-04**
Estado: **Activo**

## Objetivo

Eliminar bloqueo de sesión cuando expira el access token (~24h), mantener refresh continuo y garantizar salida segura aun con token expirado.

## Causa raíz confirmada

1. Desde **2026-03-01**, `POST /api/v1/auth/refresh` rechaza `refresh_token` por defecto cuando `AUTH_REJECT_SNAKE_CASE=true`.
2. Clientes legacy que seguían enviando snake_case quedaban sin refresh al vencer access token.
3. `POST /api/v1/auth/logout` exigía JWT válido; con access expirado, el usuario podía quedar bloqueado en UX.

## Cambios aplicados

1. `POST /api/v1/auth/login` normalizado con envelope de tokens:
   - `accessToken`
   - `refreshToken`
   - `expiresAt`
   - `tokenType`
2. `POST /api/v1/auth/refresh` mantiene contrato oficial camelCase (`refreshToken`).
3. Ventana temporal de compatibilidad legacy:
   - `AUTH_REJECT_SNAKE_CASE=false`
   - Vigencia: **2026-03-04** a **2026-03-18**
4. `POST /api/v1/auth/logout` en modo fail-safe (best effort):
   - Sin guard JWT obligatorio.
   - `Authorization` opcional.
   - `refreshToken` opcional en body.
   - Responde `200` aunque no se logre revocación, para no bloquear salida de la app.
5. Observabilidad auth reforzada:
   - `auth_refresh_success`
   - `auth_refresh_failed`
   - `auth_refresh_legacy_allowed`
   - `auth_refresh_legacy_rejected`
   - `auth_logout_best_effort`
   - `auth_logout_revoke_failed`

## Contrato operativo recomendado para apps

1. Guardar `refreshToken` de login.
2. Refrescar usando únicamente:
   - `POST /api/v1/auth/refresh` con body `{ "refreshToken": "..." }`.
3. En logout enviar, cuando exista:
   - Header `Authorization: Bearer <access>`
   - Body `{ "refreshToken": "..." }`
4. Limpiar sesión local siempre que logout responda 200.

## Ventana temporal y cutback

1. Compatibilidad legacy activa del **2026-03-04** al **2026-03-18**.
2. Fecha objetivo de retorno a estricto:
   - **2026-03-18** con `AUTH_REJECT_SNAKE_CASE=true`.
3. Smoke post-cutback:
   - `refreshToken` => 200
   - `refresh_token` => 400 (`LEGACY_SNAKE_CASE_REMOVED`)
