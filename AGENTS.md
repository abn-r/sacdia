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
3. `docs/README.md`
4. `docs/steering/tech.md`
5. `docs/steering/coding-standards.md`
6. `docs/steering/data-guidelines.md`
7. `docs/steering/agents.md` (reglas extendidas y checklist detallado)
8. `docs/steering/agent-ownership.md`
9. Si se toca un modulo runtime: `sacdia-backend/AGENTS.md`, `sacdia-admin/AGENTS.md` o `sacdia-app/AGENTS.md` segun corresponda.

## 2) Router de documentacion por tipo de cambio

### Backend y API (NestJS)

- Codigo: `sacdia-backend/`
- Contexto local: `sacdia-backend/CLAUDE.md`
- Referencia API runtime (canónica): `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- Seguridad: `docs/api/SECURITY-GUIDE.md`
- Testing: `docs/api/TESTING-GUIDE.md`

### Admin Web (Next.js)

- Codigo: `sacdia-admin/`
- Contexto local: `sacdia-admin/CLAUDE.md`
- Integracion con API: `docs/api/FRONTEND-INTEGRATION-GUIDE.md`
- Feature docs: `docs/features/`

### App Movil (Flutter)

- Codigo: `sacdia-app/`
- Contexto local: `sacdia-app/CLAUDE.md`
- Integracion con API: `docs/api/FRONTEND-INTEGRATION-GUIDE.md`
- Feature docs: `docs/features/`

### Base de datos (Supabase/PostgreSQL/Prisma)

- Contexto DB: `docs/database/README.md`
- Schema referencia: `docs/database/SCHEMA-REFERENCE.md`
- Prisma schema: `docs/database/schema.prisma`
- Migraciones SQL: `docs/database/migrations/`

### Roadmap, estado y arquitectura global

- Arquitectura/API decisiones: `docs/api/ARCHITECTURE-DECISIONS.md`
- Servicios externos: `docs/EXTERNAL-SERVICES-AUDIT.md`
- Resumenes de fase: `docs/PHASE-1-COMPLETION-SUMMARY.md`

## 3) Router de features

Para cambios de negocio, ubicar primero el dominio en `docs/features/`:

- `actividades`
- `audit-log`
- `auth`
- `catalogos`
- `certificaciones-guias-mayores`
- `clases-progresivas`
- `communications`
- `finanzas`
- `gestion-clubs`
- `gestion-seguros`
- `honores`
- `infrastructure`
- `inventario`
- `recursos`
- `validacion-investiduras`

Orden recomendado dentro de cada feature:

1. `CLAUDE.md` (si existe contexto operativo)
2. `requirements.md` (si existe)
3. `design.md` (si existe)
4. `walkthrough-*.md` (si existe)
5. `tasks.md` (si existe)

## 4) Reglas de implementacion

- No asumir contratos: validar en documentacion del dominio.
- Priorizar consistencia con patrones ya existentes.
- Implementar con pruebas y validaciones, no solo happy path.
- Si falta un requisito, detener implementacion y pedir definicion.

## 5) Regla de sincronizacion codigo-documentacion

Si se modifica codigo que cambie comportamiento, actualizar documentacion en el mismo trabajo:

- Cambio de endpoint/DTO/errores: actualizar `docs/api/`.
- Cambio de schema o relaciones: actualizar `docs/database/`.
- Cambio de flujo funcional: actualizar `docs/features/`.
- Cambio transversal de arquitectura: actualizar `docs/steering/`.

## 6) Checklist rapido antes de cerrar

- Se leyo la documentacion base y la del dominio afectado.
- La implementacion sigue los estandares del proyecto.
- Tests/lint/analyze relevantes ejecutados en el modulo afectado.
- Docs actualizadas para reflejar el estado final.

## 7) Nota sobre archivos CLAUDE con memoria

Algunos `CLAUDE.md` incluyen bloques `<claude-mem-context>` autogenerados.
No usar esos bloques como unica fuente de verdad para requisitos tecnicos.
La fuente de verdad funcional y tecnica debe ser `docs/steering/`, `docs/features/`, `docs/api/` y `docs/database/`.

## 8) Skills de workspace

| Skill | Descripcion | Archivo |
|------|-------------|---------|
| `sacdia-code-review` | Playbook reusable para revisar PRs y cambios cross-repo en `sacdia-backend`, `sacdia-admin` y `sacdia-app`, con checklist y templates. | [SKILL.md](.agents/skills/sacdia-code-review/SKILL.md) |
| `repo-researcher` | Agente liviano de solo lectura para buscar codigo, docs y datos en el repo. Usa haiku por defecto, sonnet solo para busquedas complejas. | [SKILL.md](~/.claude/skills/repo-researcher/SKILL.md) |
