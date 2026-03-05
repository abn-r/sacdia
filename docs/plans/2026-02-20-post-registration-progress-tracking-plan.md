# Post-Registration Progress Tracking Plan (Consolidado)

**Fecha original**: 2026-02-20  
**Estado**: HISTORICAL (consolidado)

Este documento unifica el diseño y el plan de implementación del tracking de progreso de post-registro.

## Resumen

Problema central resuelto: desalineación entre parsing de estado, endpoints de completitud y navegación del shell de onboarding.

## Decisiones consolidadas

- Parsing de `completion-status` con envelope `data.steps`.
- Corrección de rutas `step-2/complete` y `step-3/complete`.
- Inclusión de `club_type` en payload de step 3.
- Manejo idempotente de step 3 (conflict como éxito controlado).
- Actualización explícita de estado auth local al completar onboarding.

## Fuente histórica completa

- `docs/history/plans/2026-02-20-post-registration-progress-tracking-design.md`
- `docs/history/plans/2026-02-20-post-registration-progress-tracking.md`

