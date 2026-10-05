# SACDIA — Documentación

**Estado**: ACTIVE
**Actualizado**: 2026-10-04

> [!IMPORTANT]
> Este README es un índice de navegación. La precedencia documental se define **solo** en [`canon/source-of-truth.md`](canon/source-of-truth.md); aquí se resume.
> La realidad efectiva es el código de la rama `development` de los repos runtime. Si un documento la contradice, se corrige el documento.

---

## Precedencia (resumen)

1. `canon/source-of-truth.md`
2. `canon/*` (gobernanza → dominio → identidad → arquitectura → runtime → decisiones)
3. Contratos: `sacdia-backend/prisma/schema.prisma` (datos) y `api/ENDPOINTS-LIVE-REFERENCE.md` (API)
4. `steering/*`
5. `features/*`
6. Documentación operativa (`api/`, `database/`, `guides/`, `deployment/`, `runbooks/`, `storage/`, `testing/`, `legal/`, `architecture/`)
7. Navegación: este README, `README.md`, `CLAUDE.md` y `AGENTS.md` raíz
8. Trabajo temporal: `plans/`, `reviews/`, `working/`
9. `history/`: nunca es estado actual

---

## Estructura

| Carpeta | Contenido | Nivel |
|---------|-----------|-------|
| `canon/` | Verdad del negocio y del runtime, verificada contra código | Canon |
| `api/` | Contrato de endpoints, decisiones de arquitectura API, seguridad, testing e integración | Contrato / operativo |
| `database/` | Guía de datos, referencia del schema y espejo documental `schema.prisma` | Operativo (manda `sacdia-backend/prisma/schema.prisma`) |
| `api-database/` | Trazabilidad servicio backend → tablas | Operativo |
| `steering/` | Stack, estructura, estándares de código y datos, reglas para agentes | Normativo |
| `features/` | Un documento por dominio funcional; `features/README.md` registra el estado | Dominio |
| `guides/` | Guías prácticas (setup, flujo de trabajo, correo, OCR, material de estudio) | Operativo |
| `deployment/` | Guía de despliegue alineada con `sacdia-backend/render.yaml` | Operativo |
| `runbooks/` | Procedimientos puntuales de operación | Operativo |
| `storage/` | Convenciones de buckets y prefijos en Cloudflare R2 | Operativo |
| `testing/` | Usuarios de prueba del seed | Operativo |
| `legal/` | Aviso de privacidad, términos y checklist para tiendas | Operativo |
| `architecture/` | Notas de arquitectura de áreas concretas (exportación de datos) | Operativo |
| `performance/` | Guía de profiling | Operativo |
| `audit/` | Decisiones pendientes y auditoría de servicios externos | Operativo |
| `bases/`, `strategy/` | Visión institucional y posicionamiento | Contexto de producto |
| `plans/` | Planes y roadmaps **pendientes** | Temporal |
| `reviews/` | Revisiones de trabajo en curso | Temporal |
| `working/` | Material de trabajo y fuentes para seeds | Temporal |
| `history/` | Documentos archivados con valor de contexto | Histórico |

El portal de manuales vive en el repo `sacdia-docs` (gitlink en la raíz de este workspace) y está pendiente de rediseño como portal sin permisos por rol.

---

## Navegación por tipo de pregunta

| Pregunta | Consultar en orden |
|----------|-------------------|
| Producto o alcance | `canon/dominio-sacdia.md` → `canon/identidad-sacdia.md` → `features/` |
| Arquitectura | `canon/arquitectura-sacdia.md` → `canon/runtime-sacdia.md` → `canon/decisiones-clave.md` → `steering/` |
| API | `api/ENDPOINTS-LIVE-REFERENCE.md` → `api/ARCHITECTURE-DECISIONS.md` → `features/<dominio>.md` |
| Datos | `sacdia-backend/prisma/schema.prisma` → `database/README.md` → `database/SCHEMA-REFERENCE.md` |
| Estado de un dominio | `features/README.md` → `features/<dominio>.md` |
| Decisiones pendientes | `audit/DECISIONS-PENDING.md` |
| Despliegue | `deployment/DEPLOYMENT-GUIDE.md` |
| Poner en marcha un equipo | `guides/SETUP-NEW-PC.md` → `guides/developer-workflow.md` |

---

## Rutas de lectura por rol

### Canon base

1. `canon/source-of-truth.md`
2. `canon/dominio-sacdia.md`
3. `canon/identidad-sacdia.md`
4. `canon/gobernanza-canon.md`
5. `canon/arquitectura-sacdia.md`
6. `canon/runtime-sacdia.md`
7. `canon/decisiones-clave.md`

### Backend

1. `canon/runtime-sacdia.md`
2. `canon/auth/runtime-auth.md`
3. `steering/tech.md` y `steering/coding-standards.md`
4. `api/ENDPOINTS-LIVE-REFERENCE.md`
5. `sacdia-backend/prisma/schema.prisma` y `database/README.md`

### App móvil

1. `canon/runtime-sacdia.md`
2. `steering/tech.md` y `steering/STRUCTURE-GUIDE.md`
3. `api/ENDPOINTS-LIVE-REFERENCE.md` y `api/FRONTEND-INTEGRATION-GUIDE.md`
4. `features/`

### Admin web

1. `canon/runtime-sacdia.md`
2. `steering/tech.md` y `steering/STRUCTURE-GUIDE.md`
3. `api/ENDPOINTS-LIVE-REFERENCE.md` y `api/FRONTEND-INTEGRATION-GUIDE.md`
4. `guides/admin-integration.md`
5. `features/`

---

## Estados de documento

- `ACTIVE`: vigente.
- `DRAFT`: en construcción.
- `HISTORICAL`: contexto histórico, no contrato vigente.
- `DEPRECATED`: reemplazado; debe apuntar al documento vigente.

Convención para pendientes:

- No crear estados nuevos como "pending", "future" o "planned".
- En un documento `ACTIVE`, marcar el texto puntual como `Pendiente`, `Planificado`, `Recomendado` o `Por verificar`.
- Si lo descrito vive en una rama sin integrar, añadir "Pendiente de merge (PR #N de <repo>)".
- En los planes, la cabecera indica qué está hecho, qué falta y en qué rama vive el trabajo.

---

## Scripts de verificación documental

Viven en `scripts/` y corren en CI (`.github/workflows/`):

| Script | Workflow | Qué comprueba |
|---|---|---|
| `scripts/verify-api-docs-consistency.mjs` | `docs-api-consistency.yml` | Consistencia de `api/ENDPOINTS-LIVE-REFERENCE.md` con las rutas del backend |
| `scripts/verify-permissions-consistency.mjs` | `rbac-permissions-consistency.yml` | Permisos del seed frente a la navegación del admin. **Hoy apunta a `sacdia-admin/src/components/layout/nav-config.ts`, que se borró el 2026-07-14: imprime `SKIP` y no valida nada.** Debe migrarse al screen catalog (`src/lib/auth/screen-catalog/`). |
| `scripts/check-sdd-command-parity.mjs` | `sdd-command-parity.yml` | Contratos de comandos SDD (`sdd-*.md`); en CI usa `scripts/__fixtures__`, en local busca `~/.config/opencode/commands` (`--command-dir <ruta>` para otra ubicación, `--json` para salida máquina) |

---

## Ver también

- `canon/README.md`
- `features/README.md`
- `history/README.md`
