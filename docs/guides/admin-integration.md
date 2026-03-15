# Admin Integration Guide

**Estado**: ACTIVE

Guía operativa resumida para integrar frontend admin con contratos backend vigentes.

## Contrato fuente de verdad

- `docs/02-API/ENDPOINTS-LIVE-REFERENCE.md`
- `docs/02-API/FRONTEND-INTEGRATION-GUIDE.md`
- `docs/PHASE-3-ADMIN-PROGRAM.md`

## Reglas de integración

1. Usar siempre endpoints runtime vigentes en `ENDPOINTS-LIVE-REFERENCE.md`.
2. Respetar alcance por rol (scope) retornado por backend.
3. Tratar 401/403/404/429/5xx como estados esperados con degradación de UX.
4. No asumir permisos por rol nominal: validar permisos efectivos en sesión.

## Checklist mínimo

- [ ] Guard auth JWT funcionando.
- [ ] Scope por rol representado en UI.
- [ ] Manejo de errores estándar implementado.
- [ ] Smoke E2E ejecutado en rutas críticas.

