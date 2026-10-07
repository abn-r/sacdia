# AGENTS.md

Guia operativa para agentes de IA en `sacdia`.
Objetivo: asegurar que cualquier implementacion use el contexto correcto antes de tocar codigo.

## 0) GGA — Gentle AI Agent Contract

Esta es la fuente de verdad operativa para agentes en el workspace SACDIA.
Los repos runtime (`sacdia-backend`, `sacdia-admin`, `sacdia-app`) tienen `AGENTS.md`
propios solo como adaptadores: no deben duplicar ni contradecir este contrato.

### Principios de trabajo

- Verificar antes de afirmar. No aceptar supuestos del usuario sin revisar codigo/docs.
- Conceptos antes que codigo: si falta contexto o requisito, detenerse y pedir definicion.
- IA como herramienta: el humano dirige, el agente ejecuta con trazabilidad.
- Respuestas cortas por defecto; ampliar solo si el usuario lo pide o el riesgo lo requiere.
- Una pregunta a la vez. Despues de preguntar, detenerse y esperar.
- No presentar menus ni enfoques multiples salvo que exista una bifurcacion real con tradeoffs.
- En español, responder con español neutro; no usar voseo rioplatense ni modismos argentinos.

### Reglas duras

- Nunca agregar `Co-Authored-By` ni atribucion de IA en commits.
- Usar conventional commits si se pide commitear.
- Nunca ejecutar builds despues de cambios, salvo pedido explicito posterior del usuario.
- No cambiar contratos, schema, endpoints o flujos sin actualizar la documentacion canonica correspondiente.
- No hardcodear secretos ni tocar `.env` reales.
- No asumir contratos runtime: validar en docs canonicas y codigo efectivo.

### Alcance por repositorio

- Cambios cross-repo: partir desde este `AGENTS.md` raiz.
- Cambios en un repo especifico: leer este archivo y luego el `AGENTS.md`/`CLAUDE.md` local del repo.
- Si un repo se abre aislado y no existe `../AGENTS.md`, el `AGENTS.md` local actua como adaptador minimo y debe indicar que el canon completo vive en el workspace `sacdia`.

### Ownership de agentes por superficie

- Para cambios integrales, seguir `docs/steering/agent-ownership.md`.
- Codex prioriza `sacdia-backend/`, `sacdia-app/`, contratos API, seguridad, datos y documentacion tecnica.
- Cursor Composer 2.5 prioriza `sacdia-admin/`, diseño visual, jerarquia de informacion, layouts y polish del panel administrativo.
- El flujo debe ser contract-first: Codex define o valida endpoints/DTOs/permisos/errores antes de que el admin los consuma.
- Codex no debe rediseñar el admin salvo pedido explicito o ajuste minimo para corregir integracion rota.

## 1) Lectura minima obligatoria (siempre)

1. `CLAUDE.md`
2. `README.md`
3. `docs/README.md` (navegacion) y `docs/canon/source-of-truth.md` (precedencia)
4. `docs/steering/tech.md`
5. `docs/steering/coding-standards.md`
6. `docs/steering/data-guidelines.md`
7. `docs/steering/agents.md` (reglas extendidas y checklist detallado)
8. `docs/steering/agent-ownership.md`
9. Si se toca un modulo runtime: `sacdia-backend/AGENTS.md` o `sacdia-admin/AGENTS.md`; en `sacdia-app` (no tiene `AGENTS.md`) leer `sacdia-app/CLAUDE.md`.

## 2) Router de documentacion por tipo de cambio

### Backend y API (NestJS)

- Codigo: `sacdia-backend/`
- Contexto local: `sacdia-backend/CLAUDE.md`, `sacdia-backend/AGENTS.md`
- Runtime base: `docs/canon/runtime-sacdia.md`; auth: `docs/canon/auth/runtime-auth.md`
- Referencia API runtime (canonica): `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- Seguridad: `docs/api/SECURITY-GUIDE.md`
- Testing: `docs/api/TESTING-GUIDE.md`
- Despliegue: `docs/deployment/DEPLOYMENT-GUIDE.md` (fuente: `sacdia-backend/render.yaml` y `.env.example`)

### Admin Web (Next.js)

- Codigo: `sacdia-admin/`
- Contexto local: `sacdia-admin/CLAUDE.md`, `sacdia-admin/AGENTS.md`
- Integracion con API: `docs/api/FRONTEND-INTEGRATION-GUIDE.md` y `docs/guides/admin-integration.md`
- Acceso a pantallas: screen catalog en `sacdia-admin/src/lib/auth/screen-catalog/`
- Feature docs: `docs/features/`

### App Movil (Flutter)

- Codigo: `sacdia-app/`
- Contexto local: `sacdia-app/CLAUDE.md`
- Integracion con API: `docs/api/FRONTEND-INTEGRATION-GUIDE.md`
- Acceso a pantallas: `sacdia-app/lib/core/authorization/` (hermano Dart del screen catalog del admin)
- Feature docs: `docs/features/`

### Base de datos (PostgreSQL en Neon + Prisma)

- Schema efectivo (autoridad): `sacdia-backend/prisma/schema.prisma`
- Migraciones: `sacdia-backend/prisma/migrations/` (Prisma Migrate)
- Contexto DB: `docs/database/README.md`
- Schema referencia (lectura humana): `docs/database/SCHEMA-REFERENCE.md`
- `docs/database/schema.prisma` es solo un espejo documental; nunca arbitra contra el del backend.

### Estado, decisiones y arquitectura global

- Estado por dominio: `docs/features/README.md`
- Decisiones de arquitectura API: `docs/api/ARCHITECTURE-DECISIONS.md`
- Decisiones del sistema: `docs/canon/decisiones-clave.md`
- Decisiones pendientes: `docs/audit/DECISIONS-PENDING.md`
- Servicios externos: `docs/api/EXTERNAL-SERVICES-INTEGRATION.md`, `docs/features/servicios-externos.md` y `docs/canon/runtime-sacdia.md` §9
- Planes pendientes: `docs/plans/` (no son estado actual)
- Historico: `docs/history/` (nunca es estado actual)

## 3) Router de features

Para cambios de negocio, ubicar primero el dominio en `docs/features/README.md`. Ese registro lista cada documento de dominio y su estado funcional declarado. Los documentos son planos (`docs/features/<dominio>.md`), con subcarpetas solo para detalle extra (por ejemplo `docs/features/auth/`).

Grupos principales:

- Acceso: `auth`, `rbac` (y `docs/features/auth/*`)
- Club: `gestion-clubs`, `membership-requests`, `actividades`, `actividades-conjuntas`, `finanzas`, `inventario`, `recursos`, `weekly-records`
- Formacion: `clases-progresivas`, `honores`, `certificaciones-guias-mayores`, `carga-masiva-certificados`, `validacion-evidencias`, `validacion-investiduras`, `achievements`, `member-of-month`
- Carpetas y clasificacion: `carpetas-evidencias`, `annual-folders-scoring`, `monthly-reports`
- Camporees: `camporees`, `camporee-events`, `camporee-orders`, `camporee-supplies`, `aprobaciones-camporees`
- Operacion: `coordinacion`, `sla-dashboard`, `operations-dashboard`, `communications`, `cron-automation`, `audit-log`, `gestion-seguros`, `catalogos`, `infrastructure`

Orden recomendado dentro de un dominio:

1. `docs/features/<dominio>.md`
2. `docs/canon/runtime-<area>.md` si existe
3. Seccion correspondiente de `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
4. Codigo en `development`

## 4) Reglas de implementacion

- No asumir contratos: validar en documentacion del dominio y en el codigo de `development`.
- Priorizar consistencia con patrones ya existentes.
- Implementar con pruebas y validaciones, no solo happy path.
- Si falta un requisito, detener implementacion y pedir definicion.
- Trabajar en ramas desde `development`; el flujo de integracion es `development` → `preproduction` (QA) → `main`.

## 5) Regla de sincronizacion codigo-documentacion

Si se modifica codigo que cambie comportamiento, actualizar documentacion en el mismo trabajo:

- Cambio de endpoint/DTO/errores: actualizar `docs/api/`.
- Cambio de schema o relaciones: actualizar `docs/database/`.
- Cambio de flujo funcional: actualizar `docs/features/` (y el canon `runtime-*` del area si existe).
- Cambio transversal de arquitectura o stack: actualizar `docs/steering/` y `docs/canon/runtime-sacdia.md`.
- Trabajo que queda en una rama sin integrar: marcar la documentacion "Pendiente de merge (PR #N de <repo>)".

## 6) Checklist rapido antes de cerrar

- Se leyo la documentacion base y la del dominio afectado.
- La implementacion sigue los estandares del proyecto.
- Tests/lint/analyze relevantes ejecutados en el modulo afectado.
- Docs actualizadas para reflejar el estado final.

## 7) Nota sobre archivos CLAUDE con memoria

Algunos `CLAUDE.md` incluyen bloques `<claude-mem-context>` autogenerados.
No usar esos bloques como unica fuente de verdad para requisitos tecnicos.
La fuente de verdad funcional y tecnica es la definida en `docs/canon/source-of-truth.md`.

## 8) Herramientas locales de agentes

- Las skills y la configuracion de agentes (`.agents/`, `.claude/`, `.opencode/` y similares) estan en `.gitignore`: son locales de cada equipo y no forman parte del repo. Si una skill existe en tu maquina, puedes usarla, pero ningun documento versionado debe depender de ella.
- `skills-lock.json` registra skills de terceros instaladas en el workspace; no es documentacion del proyecto.
- `graft/` (grafo de contexto) tambien es local y esta ignorado. Si lo tienes generado (`graft build`), puedes consultarlo con `graft ask "<pregunta>"`; si no existe, usa la documentacion y busqueda directa en el codigo.
