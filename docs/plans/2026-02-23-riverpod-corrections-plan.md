# Riverpod Corrections Plan (Consolidado)

**Fecha original**: 2026-02-23  
**Estado**: HISTORICAL (consolidado)

Este documento unifica diseño e implementación de correcciones Riverpod en `sacdia-app`.

## Resumen

Se corrigieron inconsistencias de patrones de estado, providers duplicados y deuda técnica de arquitectura de estado.

## Decisiones consolidadas

- Unificación de `dioProvider` canónico.
- Migración de `StateNotifier` heredado a `AsyncNotifier`.
- Eliminación de providers/código muerto.
- Simplificación de vistas auth para usar estado centralizado.
- Normalización de theme provider hacia patrón Riverpod consistente.

## Fuente histórica completa

- `docs/history/plans/2026-02-23-riverpod-corrections-design.md`
- `docs/history/plans/2026-02-23-riverpod-corrections.md`

