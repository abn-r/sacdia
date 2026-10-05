# Feature Registry - SACDIA

**Estado**: ACTIVE
**Actualizado**: 2026-10-04 (verificado contra `development`)
**Propósito**: registrar qué dominios tienen documento en `docs/features/` y separar cobertura editorial de estado funcional declarado.

> [!IMPORTANT]
> Este archivo es un registro de cobertura documental mínima.
> No redefine autoridad canónica ni contratos runtime.
>
> Separación usada en este registro:
> - **Estado editorial**: taxonomía documental (`ACTIVE`, `DRAFT`, `HISTORICAL`, `DEPRECATED`).
> - **Estado funcional**: etiqueta declarada dentro de cada documento de dominio (`IMPLEMENTADO`, `IMPLEMENTADO PARCIAL`, `EN IMPLEMENTACIÓN`, `PARCIAL`, `NO CANON`).
>
> Si hay conflicto, usar en este orden:
> 1. `docs/canon/source-of-truth.md`
> 2. `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
> 3. `docs/database/schema.prisma` y `docs/database/SCHEMA-REFERENCE.md`
> 4. este registro para saber si un dominio tiene documentacion minima y que estado funcional declara hoy

## Como leer este registro

| Campo | Significado |
|---|---|
| Estado editorial del registro | Estado documental de este `README.md` |
| Cobertura editorial minima | Si existe un documento de dominio dentro de `docs/features/` |
| Estado funcional declarado | Estado escrito en el documento del dominio; no equivale a taxonomia editorial |

## Cobertura actual del registro

| Señal | Cantidad | Evidencia |
|---|---:|---|
| Dominios registrados | 54 | filas de la tabla de abajo (50 documentos en `docs/features/` + 2 dominios en `docs/canon/runtime-rankings.md` + `requests` en `docs/canon/runtime-requests.md` + `data-export` en `docs/architecture/DATA-EXPORT.md`) |
| Estado funcional `IMPLEMENTADO` | 42 | declarado en los documentos de dominio |
| Estado funcional `IMPLEMENTADO PARCIAL` | 7 | `camporee-events`; `camporee-orders`; `camporee-supplies`; `club-enrollments`; `i18n`; `informes-trimestrales-anuales`; `soporte` |
| Estado funcional `PARCIAL` | 2 | `audit-log`; `institutional-history` |
| Estado funcional `NO CANON` | 1 | `infrastructure` (infraestructura operativa) |
| Estado `ACTIVE` con canon externo | 1 | `achievements` |
| Estado `DEPRECATED` | 1 | `carpetas-evidencias` (retirado antes de producción) |
| Documentos complementarios | 7 | tabla «Documentos complementarios» |

## Dominios registrados

| Dominio | Documento | Cobertura editorial minima | Estado funcional declarado |
|---|---|---|---|
| `achievements` | [achievements.md](achievements.md) | Documento presente | `ACTIVE` (canon en [runtime-achievements.md](../canon/runtime-achievements.md)) |
| `actividades` | [actividades.md](actividades.md) | Documento presente | `IMPLEMENTADO` |
| `actividades-conjuntas` | [actividades-conjuntas.md](actividades-conjuntas.md) | Documento presente | `IMPLEMENTADO` |
| `annual-folders-scoring` | [annual-folders-scoring.md](annual-folders-scoring.md) | Documento presente | `IMPLEMENTADO` |
| `aprobaciones-camporees` | [aprobaciones-camporees.md](aprobaciones-camporees.md) | Documento presente | `IMPLEMENTADO` |
| `aprobaciones-masivas` | [aprobaciones-masivas.md](aprobaciones-masivas.md) | Documento presente | `IMPLEMENTADO` |
| `audit-log` | [audit-log.md](audit-log.md) | Documento presente | `PARCIAL` |
| `auth` | [auth.md](auth.md) | Documento presente | `IMPLEMENTADO` |
| `camporee-events` | [camporee-events.md](camporee-events.md) | Documento presente | `IMPLEMENTADO PARCIAL` |
| `camporee-orders` | [camporee-orders.md](camporee-orders.md) | Documento presente | `IMPLEMENTADO PARCIAL` |
| `camporee-supplies` | [camporee-supplies.md](camporee-supplies.md) | Documento presente | `IMPLEMENTADO PARCIAL` |
| `camporee-venues` | [camporee-venues.md](camporee-venues.md) | Documento presente | `IMPLEMENTADO` |
| `camporees` | [camporees.md](camporees.md) | Documento presente | `IMPLEMENTADO` |
| `carga-masiva-certificados` | [carga-masiva-certificados.md](carga-masiva-certificados.md) | Documento presente | `IMPLEMENTADO` (OCR con ADC y `pdf-lib`: pendiente de merge, PR #448) |
| `carpetas-evidencias` | [carpetas-evidencias.md](carpetas-evidencias.md) | Documento presente | `DEPRECATED` |
| `catalogos` | [catalogos.md](catalogos.md) | Documento presente | `IMPLEMENTADO` |
| `certificaciones-guias-mayores` | [certificaciones-guias-mayores.md](certificaciones-guias-mayores.md) | Documento presente | `IMPLEMENTADO` |
| `cierre-anual` | [cierre-anual.md](cierre-anual.md) | Documento presente | `IMPLEMENTADO` |
| `clases-progresivas` | [clases-progresivas.md](clases-progresivas.md) | Documento presente | `IMPLEMENTADO` |
| `clasificacion-institucional-ampliada` | [docs/canon/runtime-rankings.md](../canon/runtime-rankings.md) (8.4-C: `composite_score_pct` y `/breakdown`) | Documento presente | `IMPLEMENTADO` |
| `club-enrollments` | [club-enrollments.md](club-enrollments.md) | Documento presente | `IMPLEMENTADO PARCIAL` |
| `communications` | [communications.md](communications.md) | Documento presente | `IMPLEMENTADO` |
| `contactos-emergencia-representante-legal` | [contactos-emergencia-representante-legal.md](contactos-emergencia-representante-legal.md) | Documento presente | `IMPLEMENTADO` |
| `coordinacion` | [coordinacion.md](coordinacion.md) | Documento presente | `IMPLEMENTADO` |
| `cron-automation` | [cron-automation.md](cron-automation.md) | Documento presente | `IMPLEMENTADO` |
| `data-export` | [docs/architecture/DATA-EXPORT.md](../architecture/DATA-EXPORT.md) | Documento presente | `IMPLEMENTADO` |
| `finanzas` | [finanzas.md](finanzas.md) | Documento presente | `IMPLEMENTADO` |
| `gestion-clubs` | [gestion-clubs.md](gestion-clubs.md) | Documento presente | `IMPLEMENTADO` |
| `gestion-seguros` | [gestion-seguros.md](gestion-seguros.md) | Documento presente | `IMPLEMENTADO` |
| `honores` | [honores.md](honores.md) | Documento presente | `IMPLEMENTADO` |
| `i18n` | [i18n.md](i18n.md) | Documento presente | `IMPLEMENTADO PARCIAL` |
| `informes-trimestrales-anuales` | [informes-trimestrales-anuales.md](informes-trimestrales-anuales.md) | Documento presente | `IMPLEMENTADO PARCIAL` |
| `infrastructure` | [infrastructure.md](infrastructure.md) | Documento presente | `NO CANON` |
| `institutional-history` | [institutional-history.md](institutional-history.md) | Documento presente | `PARCIAL` |
| `inventario` | [inventario.md](inventario.md) | Documento presente | `IMPLEMENTADO` |
| `materials` | [materials.md](materials.md) | Documento presente | `IMPLEMENTADO` |
| `member-of-month` | [member-of-month.md](member-of-month.md) | Documento presente | `IMPLEMENTADO` |
| `member-rankings` | [docs/canon/runtime-rankings.md](../canon/runtime-rankings.md) §13 | Documento presente | `IMPLEMENTADO` |
| `membership-requests` | [membership-requests.md](membership-requests.md) | Documento presente | `IMPLEMENTADO` |
| `monthly-reports` | [monthly-reports.md](monthly-reports.md) | Documento presente | `IMPLEMENTADO` |
| `operations-dashboard` | [operations-dashboard.md](operations-dashboard.md) | Documento presente | `IMPLEMENTADO` |
| `ordenes-de-pago` | [ordenes-de-pago.md](ordenes-de-pago.md) | Documento presente | `IMPLEMENTADO` |
| `qr-credencial` | [qr-credencial.md](qr-credencial.md) | Documento presente | `IMPLEMENTADO` |
| `rbac` | [rbac.md](rbac.md) | Documento presente | `IMPLEMENTADO` |
| `recursos` | [recursos.md](recursos.md) | Documento presente | `IMPLEMENTADO` |
| `requests` | [docs/canon/runtime-requests.md](../canon/runtime-requests.md) | Documento presente | `IMPLEMENTADO` |
| `servicios-externos` | [servicios-externos.md](servicios-externos.md) | Documento presente | `IMPLEMENTADO` |
| `sla-dashboard` | [sla-dashboard.md](sla-dashboard.md) | Documento presente | `IMPLEMENTADO` (endpoint consumido por la app; sin página admin) |
| `soporte` | [soporte.md](soporte.md) | Documento presente | `IMPLEMENTADO PARCIAL` |
| `system-config` | [system-config.md](system-config.md) | Documento presente | `IMPLEMENTADO` |
| `units` | [units.md](units.md) | Documento presente | `IMPLEMENTADO` |
| `validacion-evidencias` | [validacion-evidencias.md](validacion-evidencias.md) | Documento presente | `IMPLEMENTADO` |
| `validacion-investiduras` | [validacion-investiduras.md](validacion-investiduras.md) | Documento presente | `IMPLEMENTADO` (ventanas, cupo de pastores y solicitudes: pendiente de merge, PR #448) |
| `weekly-records` | [weekly-records.md](weekly-records.md) | Documento presente | `IMPLEMENTADO` |

## Documentos complementarios

No son dominios propios; amplían un dominio registrado.

| Documento | Dominio | Contenido |
|---|---|---|
| [certificaciones-guias-mayores-revision-workflow.md](certificaciones-guias-mayores-revision-workflow.md) | `certificaciones-guias-mayores` | Flujo de revisión de requisitos y cierre |
| [clases-progresivas-analisis-integral.md](clases-progresivas-analisis-integral.md) | `clases-progresivas` | Diagnóstico con fecha de corte; verificar contra `development` antes de actuar |
| [auth/AUTHORIZATION-CANONICAL-CONTRACT.md](auth/AUTHORIZATION-CANONICAL-CONTRACT.md) | `auth` / `rbac` | Contrato canónico de autorización |
| [auth/CLUB-ROLE-ASSIGNMENT-FIRST-CONTRACT.md](auth/CLUB-ROLE-ASSIGNMENT-FIRST-CONTRACT.md) | `auth` / `gestion-clubs` | Asignaciones de rol de club por `club_section_id` |
| [auth/PERMISSIONS-SYSTEM.md](auth/PERMISSIONS-SYSTEM.md) | `rbac` | Catálogo de permisos |
| [auth/RBAC-ENFORCEMENT-MATRIX.md](auth/RBAC-ENFORCEMENT-MATRIX.md) | `rbac` | Matriz de enforcement por endpoint |
| [gestion-clubs/ux-reset-phase0.md](gestion-clubs/ux-reset-phase0.md) | `gestion-clubs` | Histórico (discovery Fase 0) |

## Notas de uso

- Este registro sirve para onboarding y routing minimo por dominio.
- No usar este archivo para afirmar cantidad de endpoints, tablas o cobertura UI exacta.
- Si un documento de dominio cambia su estado funcional, actualizar este registro en el mismo trabajo.
- El trabajo en ramas sin integrar se marca «Pendiente de merge (PR #N)» dentro del documento de dominio.
