# Historial de Documentación SACDIA

Esta carpeta guarda documentación **histórica**: bitácoras, decisiones de diseño ya implementadas y auditorías con fecha de corte.

Nada de lo que hay aquí es contrato operativo. Para implementar, consultar `docs/canon/`, `docs/features/`, `docs/api/` y `docs/database/`.

## Limpieza del 2026-10-04

Se eliminó el material redundante: walkthroughs de la etapa Supabase, copias viejas de documentos de `docs/features/auth/`, backups del schema Prisma, stubs `CLAUDE.md` de navegación, planes de implementación paso a paso, handoffs y tasks. Git conserva todo; para recuperar un archivo, usar `git log --diff-filter=D -- <ruta>`.

## Convención de estado

- `ACTIVE`: documento canónico y vigente.
- `HISTORICAL`: bitácora, sesión, plan cerrado o auditoría de fecha puntual.
- `DEPRECATED`: documento sustituido por otro canónico.

## Estructura

| Carpeta o archivo | Contenido |
|---|---|
| `02-PROCESSES.md` | Descripción original de los flujos de negocio (etapa Supabase). |
| `BACKEND-PANORAMA-2026-03-04.md`, `CHANGELOG-IMPLEMENTATION.md` | Foto del backend y bitácora de implementación de marzo de 2026. |
| `implementation/` | Sesiones de implementación de febrero y marzo de 2026. |
| `changelog/` | Bitácoras consolidadas (API Q1 2026, app móvil fase 2). |
| `phases/` | Roadmap original y programas de las fases 2 (app) y 3 (admin). |
| `plans/` | Diseños y ADR de funcionalidades ya implementadas (2026-02 a 2026-09). Los planes vigentes siguen en `docs/plans/`. |
| `superpowers/specs/` | Specs de diseño con decisiones de valor (migración Wave 3, club-sections, rankings, inscripción anual, etc.). |
| `decisions/` | Trazas de decisión de la reestructuración de roles y del versionado de endpoints (enero de 2026). |
| `audit/` | `REALITY-MATRIX` del 2026-03-26, auditorías de admin/app/backend, inventario i18n, revisión de seguridad de camporees, dictamen de readiness del 2026-07-17, sus manifiestos y SQL, y la auditoría de servicios externos de mayo (reemplazada por `docs/api/EXTERNAL-SERVICES-INTEGRATION.md`). |
| `reports/` | Informes de ejecución de agosto de 2026 (certificaciones configurables, prerrequisitos de clases, órdenes de pago territoriales). |
| `security/` | Escaneo de seguridad del 2026-06-10 (informe, cobertura y validación). |
| `templates/` | Plantillas del formato requirements/design/tasks, ya no usado por `docs/features/`. |
| `specs/` | Spec del rediseño en grid de logros y prompts de imágenes de insignias. |
| `canon/`, `features/`, `architecture/` | Documentos retirados de esas carpetas: lápida de `runtime-user-folders`, panel admin v2 y viabilidad offline-first. |
| `01-FEATURES/auth/` | `future-rbac-user-stories.md` (borrador con historias aún por revisar) y `CLUB-ROLE-ASSIGNMENT-FIRST-CONTRACT.md` (pendiente de rescatar a `docs/features/auth/`). |

## Pendientes conocidos en documentos archivados

- `audit/2026-07-09-camporee-flow-security-review.md`: el hallazgo CAMP-FLOW-001 sigue abierto en el código (`replaceEventRubrics()` aún exige el registro cerrado).
- `security/codex-security-scan-2026-06-10/`: no hay seguimiento por hallazgo de la remediación.

## Regla de uso

No usar `docs/history/` como contrato operativo para implementación nueva.
