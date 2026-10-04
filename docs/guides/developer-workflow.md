# Developer Workflow Guide

**Estado**: ACTIVE
**Actualizado**: 2026-10-04

Guía unificada para trabajar con código y documentación en SACDIA. Las reglas para agentes de IA están en `AGENTS.md` y `docs/steering/agents.md`.

## Ramas

Repos runtime (`sacdia-backend`, `sacdia-admin`, `sacdia-app`):

```text
feat/<tema> ──PR──▶ development ──▶ preproduction (QA) ──▶ main (release)
```

- Crea tu rama desde `development` actualizado.
- Integra con PR a `development`; la CI de backend y app corre en `development`, `preproduction` y `main`.
- `preproduction` es el entorno de QA. El producto todavía no está en producción.
- El repo `sacdia` (documentación) trabaja igual con ramas de trabajo y PR.

## Flujo recomendado

1. Leer contexto:
   - `docs/README.md` y `docs/canon/source-of-truth.md`
   - `docs/steering/tech.md`, `docs/steering/STRUCTURE-GUIDE.md`, `docs/steering/coding-standards.md`
2. Ubicar el dominio afectado:
   - `docs/features/README.md` → `docs/features/<dominio>.md`
   - `docs/canon/runtime-<área>.md` si existe
   - `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
   - `sacdia-backend/prisma/schema.prisma` y `docs/database/`
3. Verificar el estado real en el código de `development`.
4. Definir alcance: qué cambia, qué no cambia, impacto en API, datos y UI. Si es grande, diseño/plan en `docs/plans/`.
5. Implementar con pruebas.
6. Actualizar la documentación en el mismo cambio.

## Reglas prácticas

- No implementar desde documentos de `docs/history/`.
- Si cambia el contrato de un endpoint, actualizar `docs/api/ENDPOINTS-LIVE-REFERENCE.md` (y comprobar con `node scripts/verify-api-docs-consistency.mjs`).
- Si cambia el schema o las relaciones, actualizar `docs/database/`.
- Si cambia un flujo de negocio, actualizar `docs/features/<dominio>.md` y, si aplica, el canon del área.
- Si cambia el stack o la arquitectura, actualizar `docs/steering/` y `docs/canon/runtime-sacdia.md`.
- Si el trabajo queda en una rama sin integrar, marcar la documentación "Pendiente de merge (PR #N de <repo>)".

## Verificaciones por repo

| Repo | Comandos |
|---|---|
| `sacdia-backend` | `pnpm run lint`, `pnpm test`, `pnpm run test:e2e` |
| `sacdia-admin` | `pnpm lint`, `pnpm typecheck`, `pnpm test` |
| `sacdia-app` | `dart format .`, `flutter analyze`, `flutter test` |

## Checklist pre-implementación

- [ ] Leí steering y la documentación del dominio.
- [ ] Confirmé el contrato vigente en el código de `development`.
- [ ] Identifiqué las pruebas a ejecutar.

## Checklist post-implementación

- [ ] Pruebas relevantes ejecutadas.
- [ ] Documentación sincronizada.
- [ ] Sin referencias a rutas inexistentes ni a documentos históricos como estado actual.
