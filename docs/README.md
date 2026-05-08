# SACDIA — Documentación

**Estado**: ACTIVE

> [!IMPORTANT]
> Este directorio es la fuente de verdad documental del proyecto.
> La documentación histórica se encuentra en `docs/history/`.
> La precedencia global es: `docs/canon/source-of-truth.md` → `docs/canon/*` aplicable → `docs/README.md` → documentación operativa subordinada → material histórico.

---

## Estructura

| Carpeta | Contenido | Autoridad |
|---------|-----------|-----------|
| `canon/` | Verdad del negocio, verificada contra código | Máxima — rige sobre todo |
| `audit/` | Auditorías de código + Reality Matrix | Foto del código al 2026-03-14 |
| `features/` | Estado verificado por dominio funcional | Derivado de audit + canon |
| `api/` | Contratos API (endpoints, seguridad, testing) | Operacional, subordinado a canon |
| `database/` | Schema documental + referencia + migraciones | Operacional; si hay drift manda `sacdia-backend/prisma/schema.prisma` |
| `steering/` | Estándares técnicos y de código | Normativo |
| `guides/` | Guías operativas y workflows | Práctico |
| `plans/` | Planes de implementación activos | Temporal |
| `superpowers/` | Specs y planes de diseño (SDD) | Temporal |
| `templates/` | Plantillas para nuevos features | Referencia |
| `history/` | Todo documento inactivo, archivado | Solo contexto histórico |

## Jerarquía de Autoridad

Definida en `canon/source-of-truth.md`:

1. `canon/source-of-truth.md` (gateway operativo)
2. `canon/*` (según tipo de pregunta)
3. Este README (navegación estructural)
4. `api/ENDPOINTS-LIVE-REFERENCE.md` (runtime API)
5. `sacdia-backend/prisma/schema.prisma` (estructura de datos efectiva)
6. `steering/*` (estándares)

## Navegación por Tipo de Pregunta

| Pregunta | Consultar en orden |
|----------|-------------------|
| Producto/Alcance | canon/source-of-truth → canon/dominio → canon/identidad → features/ |
| Arquitectura | canon/source-of-truth → canon/arquitectura → canon/decisiones-clave → steering/ |
| API/Runtime | canon/source-of-truth → api/ENDPOINTS-LIVE-REFERENCE → api/ARCHITECTURE-DECISIONS |
| Datos/Schema | canon/source-of-truth → sacdia-backend/prisma/schema.prisma → database/README.md → database/schema.prisma → database/SCHEMA-REFERENCE |
| Estado de features | features/README.md → features/{dominio}.md → audit/REALITY-MATRIX.md |
| Decisiones pendientes | audit/DECISIONS-PENDING.md |

## Regla Operativa de Autoridad DB

- La autoridad estructural efectiva del modelo de datos vive en `sacdia-backend/prisma/schema.prisma`.
- `docs/database/schema.prisma` es un espejo documental y puede quedar rezagado hasta su resincronización explícita.
- `docs/database/SCHEMA-REFERENCE.md` ayuda a lectura humana, pero no arbitra drift contra el schema efectivo del backend.
- Si aparece contradicción entre docs de datos, se escala el arbitraje; no se mezclan fuentes.

---

## Rutas Canónicas por Rol

### Canon base

1. `canon/dominio-sacdia.md`
2. `canon/identidad-sacdia.md`
3. `canon/gobernanza-canon.md`
4. `canon/arquitectura-sacdia.md`
5. `canon/runtime-sacdia.md`
6. `canon/decisiones-clave.md`

### Backend

1. `canon/dominio-sacdia.md`
2. `canon/runtime-sacdia.md`
3. `steering/tech.md`
4. `api/ENDPOINTS-LIVE-REFERENCE.md`
5. `api/API-SPECIFICATION.md`
6. `database/schema.prisma`

### Mobile

1. `canon/dominio-sacdia.md`
2. `canon/runtime-sacdia.md`
3. `steering/tech.md`
4. `api/ENDPOINTS-LIVE-REFERENCE.md`
5. `features/`

### Admin Web

1. `canon/dominio-sacdia.md`
2. `canon/runtime-sacdia.md`
3. `steering/tech.md`
4. `api/ENDPOINTS-LIVE-REFERENCE.md`
5. `features/`

---

## Estado de Documento

- `ACTIVE`: documento vigente.
- `DRAFT`: documento en construcción.
- `HISTORICAL`: contexto histórico, no contrato vigente.
- `DEPRECATED`: reemplazado por documento canónico.

## Convención Editorial para Pendientes y Aspiracional

- No crear estados nuevos para "pending", "future" o "planned".
- Si un documento sigue siendo canónico, mantener `ACTIVE` y etiquetar el texto puntual como `Pendiente`, `Planificado`, `Recomendado` o `Por verificar`.
- Si el valor principal del documento es una foto de una etapa previa, marcarlo `HISTORICAL` y enlazar el reemplazo activo.
- Si un documento fue sustituido, marcarlo `DEPRECATED` y apuntar al documento vigente.

## Estado del Proyecto

Ver `audit/REALITY-MATRIX.md` para la foto completa y `features/README.md` para estado por dominio.

---

## Ver También

- `canon/README.md`
- `history/README.md`

## SDD Command Parity Workflow

Use this guardrail whenever SDD command contracts are changed.

Local run:

```bash
node scripts/check-sdd-command-parity.mjs
```

Useful options:

- `--json` for machine-readable output.
- `--command-dir <path>` to validate fixtures or CI mirrors.

Failure triage order:

1. `required-command-presence` — missing `sdd-*.md` contracts.
2. `placeholder-contract.required` — missing `{argument}`, `{project}`, `{workdir}` tokens.
3. `persistence-modes.required` — incomplete `engram|openspec|hybrid|none` guidance.
4. `result-contract.required-fields` — missing `status`, `executive_summary`, `artifacts`, `next_recommended` in phase commands.
5. `meta-state-guidance.required` — missing `sdd/{argument}/state` references for `sdd-new`, `sdd-continue`, `sdd-ff`.

CI runs this as an enforced gate; failures block the workflow.

**Última actualización**: 2026-03-14
