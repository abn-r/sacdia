# Admin Integration Guide

**Estado**: ACTIVE
**Actualizado**: 2026-10-04

Guía resumida para integrar pantallas de `sacdia-admin` con los contratos del backend.

## Fuentes de verdad

- Contrato API: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- Integración frontend: `docs/api/FRONTEND-INTEGRATION-GUIDE.md`
- Dominio: `docs/features/<dominio>.md`
- Acceso a pantallas: screen catalog en `sacdia-admin/src/lib/auth/screen-catalog/`
- Reparto de trabajo backend/admin: `docs/steering/agent-ownership.md`

## Sesión y llamadas a la API

- El login guarda access y refresh token en cookies httpOnly (`sacdia_admin_access_token`, `sacdia_admin_refresh_token`) a través de `src/app/api/auth/*`. El código cliente no lee tokens.
- `src/proxy.ts` redirige a login cualquier `/dashboard/*` sin token.
- Las llamadas pasan por `src/lib/api/client.ts` (un archivo por recurso en `src/lib/api/`). Ante un 401 el cliente intenta `POST /api/auth/refresh` una vez; un 403 es permiso denegado y no cierra la sesión.

## Acceso a pantallas

- Cada pantalla tiene una definición en `src/lib/auth/screen-catalog/screens/*.ts` (`viewAny` con permisos o roles, más `capabilities` para acciones dentro de la pantalla).
- La visibilidad se decide con `canViewScreen(subject, screenId)` y las acciones con `canCapability(...)`. No comprobar roles nominales a mano.
- El id de la pantalla se reutiliza en `src/navigation/sidebar/sidebar-items.ts`.
- Los permisos del catálogo deben coincidir con los `@RequirePermissions(...)` / `@GlobalRoles(...)` del backend para ese endpoint.
- Si una pantalla también existe en la app (`surfaces: ["admin", "app"]` o `["app"]`), el cambio afecta al fixture `sacdia-app/test/fixtures/screen-catalog.snapshot.json`.

## Reglas de integración

1. Usar solo endpoints vigentes en `ENDPOINTS-LIVE-REFERENCE.md` (y verificados en el controller).
2. Respetar el alcance por rol que devuelve el backend; no filtrar en cliente datos que el backend no debería enviar.
3. Tratar 401, 403, 404, 409, 429 y 5xx como estados esperados con UX de degradación.
4. Textos con `next-intl` en los cuatro `messages/*.json`.
5. Si falta un endpoint o un campo, no inventarlo: preparar un handoff para backend con la plantilla de `agent-ownership.md`.

## Checklist mínimo

- [ ] Pantalla registrada en el screen catalog y en el sidebar con el mismo id.
- [ ] Permisos alineados con el backend.
- [ ] Estados de carga, vacío y error implementados.
- [ ] Textos traducidos en los cuatro locales.
- [ ] `pnpm test` y `pnpm typecheck` en verde.
