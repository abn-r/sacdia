# Completion Matrix - SACDIA

**Estado**: ACTIVE
**Actualizado**: 2026-04-12
**Base de autoridad**: `docs/canon/source-of-truth.md`
**Propósito**: tablero diagnostico de cobertura documental, sin vender precision falsa ni redefinir autoridad.

> [!IMPORTANT]
> Esta matriz queda temporalmente degradada como tablero de control.
> Los numeros detallados de versiones anteriores ya no son confiables frente a las fuentes vivas actuales.
>
> Hasta una resincronizacion completa, usar como autoridad operativa:
> - `docs/api/ENDPOINTS-LIVE-REFERENCE.md` para runtime API
> - `sacdia-backend/prisma/schema.prisma` para estructura de datos efectiva
> - `docs/database/schema.prisma` y `docs/database/SCHEMA-REFERENCE.md` solo como capa documental subordinada
> - `docs/features/README.md` para registro minimo de dominios documentados

---

## Estado de confiabilidad por area

| Area | Estado de esta matriz | Fuente viva a usar | Motivo |
|---|---|---|---|
| Gobernanza y rutas de lectura | `USABLE` | `docs/canon/source-of-truth.md`, `docs/README.md` | La autoridad documental se arbitra fuera de esta matriz |
| Runtime API | `OUTDATED` | `docs/api/ENDPOINTS-LIVE-REFERENCE.md` | La fuente viva hoy declara 269 endpoints; las cifras historicas de esta matriz ya no son seguras |
| Modelo de datos | `ARBITRATED_PENDING_RESYNC` | `sacdia-backend/prisma/schema.prisma`, `docs/database/README.md` | El arbitraje de autoridad ya quedó resuelto, pero la resincronizacion completa de `docs/database/` sigue pendiente |
| Baseline técnica global | `ARBITRATED` | `docs/steering/tech.md` | Batch P1.1 corrigió baseline mínima comprobable y removió afirmaciones runtime obsoletas |
| Registro de features | `USE_REGISTRY` | `docs/features/README.md` | El registro fue normalizado para separar cobertura editorial de estado funcional |
| Cierre ejecutivo de completitud | `PENDING_RESYNC` | N/A | Requiere resincronizacion posterior a P1/P4 |

## Uso permitido

- Sirve para detectar que areas necesitan resincronizacion documental.
- No sirve para afirmar totales exactos de endpoints, modelos, enums o porcentaje de cierre por dominio.
- No debe usarse para contradecir fuentes vivas ni para declarar una baseline cerrada.

## Trabajo pendiente para volver a precisión alta

| Bloque | Dependencia | Resultado esperado |
|---|---|---|
| P1 - baseline tecnica y datos | Resincronizar `docs/database/schema.prisma` y `docs/database/SCHEMA-REFERENCE.md` contra `sacdia-backend/prisma/schema.prisma` | poder reemitir estado real del modelo de datos sin contradicciones |
| P4 - cierre y sostenimiento | consolidacion final de olas previas | volver a una matriz ejecutiva con cifras verificadas y reglas de mantenimiento |

## Nota editorial

- La version detallada anterior se retiro porque mezclaba fotografia historica con exactitud operativa ya superada por fuentes vivas.
- Este batch resuelve arbitraje de autoridad DB y baseline técnica mínima comprobable, pero NO cierra la resincronizacion integral del modelo de datos.
- Hasta la resincronizacion, este archivo debe leerse como advertencia de alcance, no como inventario exacto.
