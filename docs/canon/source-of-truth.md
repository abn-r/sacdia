# Source of Truth — precedencia documental

**Estado**: ACTIVE
**Ámbito**: autoridad documental de todo el workspace `sacdia`
**Actualizado**: 2026-10-04

> [!IMPORTANT]
> Este archivo es la **única** definición de precedencia documental. `docs/README.md`, `docs/canon/README.md`, `README.md`, `CLAUDE.md` y `AGENTS.md` la citan; no la redefinen.
> Si una fuente subordinada contradice una superior, no se sintetiza por intuición: gana la superior y el conflicto se registra para corregirlo.

---

## 1. Regla cero: código vs documentación

- La realidad efectiva del sistema es el código de la rama `development` de `sacdia-backend`, `sacdia-admin` y `sacdia-app`.
- La documentación describe ese código. Si un documento contradice el código, el documento está desactualizado y se corrige en el mismo trabajo.
- Excepción: si el código contradice la **intención de dominio** fijada en `docs/canon/dominio-sacdia.md`, se trata como bug o decisión pendiente y se escala; no se reescribe el dominio para cuadrar con el código.
- El trabajo que vive en ramas sin integrar (por ejemplo, el PR #448 de sacdia-backend) no es estado actual. Su documentación puede existir, pero debe marcarse "Pendiente de merge".

---

## 2. Cadena de precedencia

De mayor a menor autoridad:

1. **`docs/canon/source-of-truth.md`** — este archivo; arbitra la precedencia.
2. **`docs/canon/`** — canon del sistema. Orden interno:
   1. `gobernanza-canon.md` (reglas documentales);
   2. `dominio-sacdia.md` (semántica y lenguaje);
   3. `identidad-sacdia.md` (propósito, alcance y frontera);
   4. `arquitectura-sacdia.md` (organización técnica);
   5. `runtime-sacdia.md` y los `runtime-*.md` / `auth/*.md` específicos (comportamiento vigente; el más específico manda en su área);
   6. `decisiones-clave.md` (memoria de decisiones; no reemplaza a los anteriores).
3. **Contratos operativos**:
   - datos: `sacdia-backend/prisma/schema.prisma`;
   - API: `docs/api/ENDPOINTS-LIVE-REFERENCE.md` y `docs/api/ARCHITECTURE-DECISIONS.md`.
4. **Normativa técnica**: `docs/steering/*`.
5. **Documentación de dominio**: `docs/features/<dominio>.md`; `docs/features/README.md` registra el estado funcional por dominio.
6. **Documentación operativa subordinada**: el resto de `docs/api/`, `docs/database/` (espejo documental del schema), `docs/guides/`, `docs/deployment/`, `docs/runbooks/`, `docs/storage/`, `docs/testing/`, `docs/legal/`, `docs/architecture/`.
7. **Navegación**: `docs/README.md`, `README.md`, `CLAUDE.md` y `AGENTS.md` raíz, y los `CLAUDE.md`/`AGENTS.md` de cada repo runtime. Orientan; no fijan contratos.
8. **Trabajo temporal**: `docs/plans/`, `docs/reviews/`, `docs/working/`. Describen intención o trabajo en curso, no estado vigente.
9. **Histórico**: `docs/history/**`. Nunca es fuente de estado actual.

---

## 3. Consulta por tipo de pregunta

| Pregunta | Consultar en orden |
|---|---|
| Producto o alcance | `canon/dominio-sacdia.md` → `canon/identidad-sacdia.md` → `features/<dominio>.md` |
| Arquitectura o baseline técnica | `canon/arquitectura-sacdia.md` → `canon/runtime-sacdia.md` → `canon/decisiones-clave.md` → `steering/tech.md` → `steering/STRUCTURE-GUIDE.md` |
| Comportamiento de un área | `canon/runtime-<área>.md` (si existe) → `features/<dominio>.md` → código |
| API | `api/ENDPOINTS-LIVE-REFERENCE.md` → `api/ARCHITECTURE-DECISIONS.md` → `features/<dominio>.md` → controllers del backend |
| Datos o schema | `sacdia-backend/prisma/schema.prisma` → `database/README.md` → `database/SCHEMA-REFERENCE.md` |
| Estado de un dominio | `features/README.md` → `features/<dominio>.md` |
| Reglas de implementación | `steering/coding-standards.md` → `steering/data-guidelines.md` → `steering/agents.md` → `AGENTS.md` |
| Precedencia documental | este archivo → `canon/gobernanza-canon.md` |

---

## 4. Reglas por dominio de autoridad

### 4.1 Datos

- `sacdia-backend/prisma/schema.prisma` es la autoridad estructural.
- `docs/database/schema.prisma` es un espejo documental; puede quedar rezagado y nunca arbitra contra el schema del backend.
- `docs/database/SCHEMA-REFERENCE.md` es referencia de lectura humana, subordinada.

### 4.2 API

- `ENDPOINTS-LIVE-REFERENCE.md` es el contrato documentado para App y Admin.
- Si difiere de los controllers de `development`, se corrige la Live Reference (`node scripts/verify-api-docs-consistency.mjs` ayuda a detectarlo).
- `ARCHITECTURE-DECISIONS.md` manda en racionales aprobados, no reemplaza el contrato por endpoint.

### 4.3 Navegación

- `README.md` raíz es onboarding corto.
- `CLAUDE.md` y `AGENTS.md` orientan a personas y agentes; los bloques `<claude-mem-context>` autogenerados no son fuente.

---

## 5. Fuentes no autorizadas como estado actual

- todo `docs/history/**` y cualquier documento marcado `HISTORICAL` o `DEPRECATED`;
- planes, roadmaps, handoffs, reviews y bitácoras de sesión cuando pretendan describir el contrato vigente;
- documentación de trabajo en ramas sin integrar (debe marcarse "Pendiente de merge");
- bloques `<claude-mem-context>` en archivos `CLAUDE.md`.

---

## 6. Contradicciones

1. No sintetizar ni "promediar" documentos.
2. Aplicar la cadena del §2.
3. Corregir el documento inferior en el mismo trabajo, o registrar el conflicto en `docs/audit/DECISIONS-PENDING.md` si requiere decisión de producto.
4. Si el conflicto impide operar con seguridad, marcarlo `BLOCKER` y escalarlo.
