# Phase 3 Admin Program (Consolidado)

**Estado**: HISTORICAL  
**Última actualización**: 2026-03-04

Revisar primero: `docs/canon/runtime-sacdia.md`, `docs/canon/arquitectura-sacdia.md`, `docs/02-API/ENDPOINTS-LIVE-REFERENCE.md`

Documento consolidado de especificación funcional y guía de integración del panel admin.

## Alcance consolidado

Este documento reemplaza la lectura distribuida de:
- plan de fase 3,
- plan de diseño,
- especificación admin extensa,
- guía de integración de users scope.

Los documentos originales se preservan en `docs/history/phases/`.
Guía de integración activa: `docs/guides/admin-integration.md`.

## Contratos y dependencias vigentes

- API runtime: `docs/02-API/ENDPOINTS-LIVE-REFERENCE.md`
- Integración frontend: `docs/02-API/FRONTEND-INTEGRATION-GUIDE.md`
- Seguridad/API hardening: `docs/02-API/EXTERNAL-SERVICES-INTEGRATION.md`

## Objetivos vigentes

- Operación estable de módulos admin core.
- RBAC consistente en navegación y acciones.
- Resiliencia de UX ante 401/403/404/429/5xx.
- Validación continua con smoke E2E.

## Guía de integración mínima

- Todo consumo de datos debe respetar scope por rol retornado por backend.
- UI debe degradar elegantemente ante contrato parcial por entorno.
- No asumir permisos por rol sin verificar payload efectivo de permisos.

## Trazabilidad histórica

Ver `docs/history/phases/` para detalle cronológico y decisiones de diseño previas.
