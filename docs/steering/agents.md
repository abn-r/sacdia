# Agents Configuration

**Estado**: ACTIVE
**Actualizado**: 2026-10-04

> Reglas extendidas para agentes de IA en SACDIA. El contrato corto está en `AGENTS.md` (raíz); este archivo lo detalla y no lo contradice. Reparto de trabajo entre agentes: `docs/steering/agent-ownership.md`.

---

## 1. Principios

1. **Verificar antes de afirmar**: cada dato técnico que se escribe (endpoint, permiso, tabla, versión, ruta) se comprueba en el código de `development`.
2. **Contract-first**: backend define o valida endpoints, DTOs, permisos y errores antes de que el admin o la app los consuman.
3. **Documentación viva**: si cambia comportamiento, la documentación se actualiza en el mismo trabajo.
4. **Preguntar antes de asumir**: si falta un requisito, se detiene la implementación y se pide definición. Una pregunta a la vez.

---

## 2. Flujo de trabajo

```text
1. Leer contexto: AGENTS.md → CLAUDE.md del repo → docs/features/<dominio>.md → canon/runtime del área
2. Verificar el estado real en el código de development
3. Si el cambio es grande: escribir diseño/plan en docs/plans/
4. Implementar en una rama desde development
5. Tests y verificaciones del repo afectado
6. Actualizar documentación (api, database, features, canon, steering)
7. PR a development → QA en preproduction → release en main
```

### Planes

- Los diseños y planes de trabajo grande viven en `docs/plans/` con nombre `YYYY-MM-DD-<tema>-design.md` / `-plan.md`.
- La cabecera del plan indica su estado real: qué está hecho, qué falta y en qué rama vive el código.
- Al terminar: el diseño con decisiones de valor se archiva en `docs/history/`; los planes paso a paso, handoffs y listas de tareas se eliminan (git conserva el historial). Lo vigente se refleja en `docs/features/` y, si aplica, en `docs/canon/`.

### Trabajo sin integrar

- Lo que vive en una rama o PR sin merge no es estado actual. Si se documenta, se marca "Pendiente de merge (PR #N de <repo>)".

---

## 3. Lectura de contexto

Orden mínimo antes de tocar código: ver `AGENTS.md` §1. Además:

- precedencia documental: `docs/canon/source-of-truth.md`;
- stack y modelo de auth: `docs/steering/tech.md`;
- dónde vive cada cosa: `docs/steering/STRUCTURE-GUIDE.md`;
- reglas de código y datos: `docs/steering/coding-standards.md` y `docs/steering/data-guidelines.md`.

No usar como fuente de estado actual: `docs/history/**`, planes ya cerrados, bloques `<claude-mem-context>`.

---

## 4. Reglas por repositorio

### Backend

- Todo handler nuevo declara `@Public()`, `@SkipPermissions()` o `@RequirePermissions(...)` (guard global deny-by-default).
- Permisos nuevos: `permissions.seed.sql` + reparto en `role-permissions.seed.sql` + screen catalog si afecta a una pantalla.
- Cambio de schema: migración Prisma + actualización de `docs/database/`.
- Cambio de endpoint: actualización de `docs/api/ENDPOINTS-LIVE-REFERENCE.md`.

### Admin

- Pantalla nueva = página en `src/app/(dashboard)/dashboard/` + entrada en el screen catalog + entrada de sidebar con el mismo id + textos en los cuatro `messages/*.json`.
- No modificar `sacdia-backend` desde un trabajo de admin: entregar handoff (plantilla en `docs/steering/agent-ownership.md`).

### App

- Feature nueva en `lib/features/<feature>/{data,domain,presentation}`.
- Gate de pantalla con `canViewScreen`; si cambia un gate `app` en el admin, regenerar `test/fixtures/screen-catalog.snapshot.json`.
- Textos en los cuatro `assets/translations/*.json`.

---

## 5. Git

- Conventional Commits. No añadir atribución de IA ni `Co-Authored-By` salvo que el usuario lo pida.
- Ramas permanentes: `development` (integración), `preproduction` (QA), `main` (release). Ramas de trabajo con prefijo de tipo (`feat/`, `fix/`, `perf/`...).
- Commitear, hacer push o abrir PR solo cuando el usuario lo pide.
- No reescribir historia de ramas compartidas.

---

## 6. Verificaciones

- No ejecutar builds salvo pedido explícito del usuario.
- Sí ejecutar, cuando el cambio lo amerita, las verificaciones rápidas del repo: `pnpm test`/`pnpm run lint` (backend), `pnpm test`/`pnpm typecheck` (admin), `flutter analyze`/`flutter test` (app).
- En `sacdia`: `node scripts/verify-api-docs-consistency.mjs` tras tocar la Live Reference.

---

## 7. Seguridad

- No tocar archivos `.env` reales ni escribir secretos en código o documentación.
- No publicar contraseñas de usuarios de prueba ni datos personales en documentación versionada.
- No relajar guards, CORS, Swagger en producción ni el alcance territorial sin decisión explícita.

---

## 8. Comunicación con el usuario

- Español neutro; sin voseo ni modismos regionales.
- Respuestas cortas por defecto; ampliar solo si se pide o si el riesgo lo exige.
- No presentar menús de opciones salvo que exista una bifurcación real con tradeoffs.
- Al proponer un cambio: qué se cambia, por qué, qué archivos toca y cómo se verifica.

---

## 9. Checklists

### Antes de implementar

- [ ] Leí la documentación del dominio y verifiqué el estado en `development`.
- [ ] El contrato (endpoint, DTO, permisos, errores) está definido.
- [ ] Sé qué documentos tendré que actualizar.

### Antes de cerrar

- [ ] Tests y verificaciones relevantes ejecutados.
- [ ] Documentación actualizada (api, database, features, canon, steering según corresponda).
- [ ] Trabajo sin integrar marcado como "Pendiente de merge".
- [ ] Sin secretos ni datos personales en el diff.
