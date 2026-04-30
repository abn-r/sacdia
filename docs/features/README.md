# Feature Registry - SACDIA

**Estado**: ACTIVE
**Actualizado**: 2026-04-14
**Propósito**: registrar qué dominios tienen documento en `docs/features/` y separar cobertura editorial de estado funcional declarado.

> [!IMPORTANT]
> Este archivo es un registro de cobertura documental mínima.
> No redefine autoridad canónica ni contratos runtime.
>
> Separación usada en este registro:
> - **Estado editorial**: taxonomía documental (`ACTIVE`, `DRAFT`, `HISTORICAL`, `DEPRECATED`).
> - **Estado funcional**: etiqueta declarada dentro de cada documento de dominio (`IMPLEMENTADO`, `PARCIAL`, `NO CANON`).
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
| Documentos de dominio presentes | 29 | archivos `docs/features/*.md` + entradas en canon, excluyendo este `README.md` |
| Estado funcional `IMPLEMENTADO` | 26 | declarado en los documentos de dominio |
| Estado funcional `PARCIAL` | 1 | `certificaciones-guias-mayores` |
| Estado funcional `NO CANON` | 2 | `achievements`; `infrastructure` declara la variante `NO CANON (infraestructura operativa)` |

## Dominios registrados

| Dominio | Documento | Cobertura editorial minima | Estado funcional declarado |
|---|---|---|---|
| `actividades` | [actividades.md](actividades.md) | Documento presente | `IMPLEMENTADO` |
| `actividades-conjuntas` | [actividades-conjuntas.md](actividades-conjuntas.md) | Documento presente | `IMPLEMENTADO` |
| `annual-folders-scoring` | [annual-folders-scoring.md](annual-folders-scoring.md) | Documento presente | `IMPLEMENTADO` |
| `achievements` | [achievements.md](achievements.md) | Documento presente | `NO CANON` |
| `aprobaciones-camporees` | [aprobaciones-camporees.md](aprobaciones-camporees.md) | Documento presente | `IMPLEMENTADO` |
| `aprobaciones-masivas` | [aprobaciones-masivas.md](aprobaciones-masivas.md) | Documento presente | `IMPLEMENTADO` |
| `auth` | [auth.md](auth.md) | Documento presente | `IMPLEMENTADO` |
| `camporees` | [camporees.md](camporees.md) | Documento presente | `IMPLEMENTADO` |
| `carpetas-evidencias` | [carpetas-evidencias.md](carpetas-evidencias.md) | Documento presente | `IMPLEMENTADO` |
| `catalogos` | [catalogos.md](catalogos.md) | Documento presente | `IMPLEMENTADO` |
| `certificaciones-guias-mayores` | [certificaciones-guias-mayores.md](certificaciones-guias-mayores.md) | Documento presente | `PARCIAL` |
| `clases-progresivas` | [clases-progresivas.md](clases-progresivas.md) | Documento presente | `IMPLEMENTADO` |
| `communications` | [communications.md](communications.md) | Documento presente | `IMPLEMENTADO` |
| `finanzas` | [finanzas.md](finanzas.md) | Documento presente | `IMPLEMENTADO` |
| `gestion-clubs` | [gestion-clubs.md](gestion-clubs.md) | Documento presente | `IMPLEMENTADO` |
| `gestion-seguros` | [gestion-seguros.md](gestion-seguros.md) | Documento presente | `IMPLEMENTADO` |
| `honores` | [honores.md](honores.md) | Documento presente | `IMPLEMENTADO` |
| `infrastructure` | [infrastructure.md](infrastructure.md) | Documento presente | `NO CANON` |
| `inventario` | [inventario.md](inventario.md) | Documento presente | `IMPLEMENTADO` |
| `member-of-month` | [member-of-month.md](member-of-month.md) | Documento presente | `IMPLEMENTADO` |
| `member-rankings` | [docs/canon/runtime-rankings.md](../canon/runtime-rankings.md) §13 | Documento presente | `IMPLEMENTADO` |
| `membership-requests` | [membership-requests.md](membership-requests.md) | Documento presente | `IMPLEMENTADO` |
| `monthly-reports` | [monthly-reports.md](monthly-reports.md) | Documento presente | `IMPLEMENTADO` |
| `rbac` | [rbac.md](rbac.md) | Documento presente | `IMPLEMENTADO` |
| `recursos` | [recursos.md](recursos.md) | Documento presente | `IMPLEMENTADO` |
| `sla-dashboard` | [sla-dashboard.md](sla-dashboard.md) | Documento presente | `IMPLEMENTADO` |
| `validacion-evidencias` | [validacion-evidencias.md](validacion-evidencias.md) | Documento presente | `IMPLEMENTADO` |
| `validacion-investiduras` | [validacion-investiduras.md](validacion-investiduras.md) | Documento presente | `IMPLEMENTADO` |
| `weekly-records` | [weekly-records.md](weekly-records.md) | Documento presente | `IMPLEMENTADO` |

## Notas de uso

- Este registro sirve para onboarding y routing minimo por dominio.
- No usar este archivo para afirmar cantidad de endpoints, tablas o cobertura UI exacta.
- Si un documento de dominio cambia su estado funcional, actualizar este registro en el mismo trabajo.
