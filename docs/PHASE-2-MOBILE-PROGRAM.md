# Phase 2 Mobile Program (Consolidado)

**Estado**: ACTIVE  
**Última actualización**: 2026-03-04

Documento consolidado de la línea móvil.

## Alcance consolidado

Este documento reemplaza la lectura distribuida de:
- plan de fase móvil,
- rediseño UI,
- auditoría de app,
- plan de acción,
- estandarización Riverpod.

Los documentos originales se preservan en `docs/history/phases/`.
Bitácora de ejecución consolidada: `docs/history/changelog/PHASE-2-MOBILE-CHANGELOG.md`.

## Fuente canónica para ejecución actual

1. `docs/00-STEERING/tech.md`
2. `docs/01-FEATURES/` según módulo
3. `docs/02-API/ENDPOINTS-LIVE-REFERENCE.md`
4. `docs/02-API/FRONTEND-INTEGRATION-GUIDE.md`

## Objetivos vigentes

- Mantener paridad contractual con API runtime.
- Sostener arquitectura Flutter + Riverpod estandarizada.
- Priorizar estabilidad de auth/sesión, post-registro y módulos core.
- Cerrar brechas con pruebas funcionales y smoke.

## Riesgos activos

- Cambios de contrato auth (refresh/logout) entre clientes legacy y canónicos.
- Dependencias de entorno para pruebas end-to-end.
- Deuda técnica residual en módulos no críticos.

## Trazabilidad histórica

Ver `docs/history/phases/` para detalle cronológico por sesión/plan.
