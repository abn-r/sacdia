# Panorama Backend SACDIA (2026-03-04)

## Resumen ejecutivo

Backend operativo con cobertura funcional amplia. El foco activo de estabilidad es **Auth/sesiones** para eliminar bloqueos por expiración de access token y sostener refresh continuo.

## Estado consolidado de sesiones/Auth

1. `POST /api/v1/auth/login` retorna envelope completo:
   - `accessToken`, `refreshToken`, `expiresAt`, `tokenType`.
2. `POST /api/v1/auth/refresh` mantiene `refreshToken` como contrato oficial.
3. Ventana temporal legacy vigente:
   - `AUTH_REJECT_SNAKE_CASE=false`
   - Del **2026-03-04** al **2026-03-18**.
4. `POST /api/v1/auth/logout` en modo fail-safe:
   - Bearer opcional.
   - `refreshToken` opcional.
   - Respuesta 200 para desbloquear UX aun si revocación no procede.
5. `GET /api/v1/auth/me` + `PATCH /api/v1/auth/me/context` soportan contexto activo de instancia.

## Seguimiento operativo recomendado (ventana temporal)

- `event:auth_refresh_success`
- `event:auth_refresh_failed`
- `event:auth_refresh_legacy_allowed`
- `event:auth_refresh_legacy_rejected`
- `event:auth_logout_best_effort`
- `event:auth_logout_revoke_failed`

## Inventario documental actualizado (fuente de verdad)

1. `README.md` (índice consolidado).
2. `02-API/ENDPOINTS-LIVE-REFERENCE.md` (contrato runtime canónico).
3. `CHANGELOG-IMPLEMENTATION.md` (bitácora consolidada).
4. `history/implementation/IMPLEMENTATION-SESSION-2026-03-04-session-stabilization.md` (detalle de sesión Auth).
5. `PHASE-2-MOBILE-PROGRAM.md` (programa móvil consolidado).

## Hitos inmediatos

1. Mantener monitoreo diario hasta **2026-03-18**.
2. Ejecutar cutback a estricto (`AUTH_REJECT_SNAKE_CASE=true`) el **2026-03-18** si métricas están estables.
3. Publicar sesión de cierre post-cutback con smoke y métricas 24h.
