# Runtime — Categorías de puntuación

**Estado**: ACTIVE
**Autoridad rectora**: `docs/canon/source-of-truth.md`
**Tipo de documento**: runtime canonizado, documented-as-built
**Ámbito**: catálogo jerárquico de categorías de puntuación aplicadas al scoring semanal + agregados derivados (weekly-records, member-of-month, annual-folders-scoring)

<!-- VERIFICADO contra código 2026-04-22: scoring-categories.controller.ts, schema Prisma y consumo por features dependientes cruzados con implementación real. -->

---

## 1. Propósito

Canoniza el subsistema de **categorías de puntuación** como capa de configuración jerárquica que alimenta a los features de scoring (weekly-records, member-of-month, annual-folders-scoring). Define cómo se heredan categorías entre niveles institucionales (division → union → local-field) y qué roles tienen autoridad sobre cada nivel.

Las categorías son catálogo de configuración, NO datos operativos del miembro. Los puntos que se registran contra ellas viven en `weekly_record_scores` (ver `docs/features/weekly-records.md`).

---

## 2. Alcance canonizado

Dentro del canon:
- jerarquía division → union → local-field;
- herencia de categorías entre niveles;
- scope de autoridad por rol;
- permisos propios del dominio.

Fuera del canon:
- fórmulas de agregación (viven en features consumidores);
- UI de configuración (admin flow);
- política de cap `max_points` (configuración, no canon estructural).

---

## 3. Jerarquía

Tres niveles institucionales pueden declarar categorías:

| Nivel | Alcance | Autoridad típica |
|-------|---------|------------------|
| `division` | globales para toda DIA | administradores globales |
| `union` | por unión | liderazgo de unión (`director-union`, `assistant-union`) |
| `local-field` | por campo local | liderazgo de campo (`director-lf`, `assistant-lf`) |

Las categorías de niveles superiores se heredan automáticamente a los niveles inferiores — un `local-field` recibe las categorías globales + las de su `union` + las propias. Esta herencia es responsabilidad del servicio de scoring, no de duplicación en datos.

---

## 4. Permisos canonizados

Permisos vigentes (dominio propio, migrados desde `units:*` en 2026-04-22):

- `scoring_categories:read` — consulta de categorías en cualquier nivel jerárquico;
- `scoring_categories:manage` — crear/actualizar/eliminar categorías de unión y campo local.

Distribución:
- `scoring_categories:read` — todos los roles de club + globales field-level+ + admin/super_admin.
- `scoring_categories:manage` — mismo listado excepto `member`.

El permiso `scoring_categories:read` también cubre los endpoints de `division`-level que antes carecían de `@RequirePermissions` (gap de seguridad cerrado en la misma ola de migración).

---

## 5. Superficie API canonizada

| Path | Método | Permiso |
|------|--------|---------|
| `/divisions/scoring-categories` | GET | `scoring_categories:read` |
| `/divisions/scoring-categories` | POST | `scoring_categories:manage` |
| `/divisions/scoring-categories/:id` | PATCH | `scoring_categories:manage` |
| `/divisions/scoring-categories/:id` | DELETE | `scoring_categories:manage` |
| `/unions/:unionId/scoring-categories` | GET | `scoring_categories:read` |
| `/unions/:unionId/scoring-categories` | POST | `scoring_categories:manage` |
| `/unions/:unionId/scoring-categories/:id` | PATCH | `scoring_categories:manage` |
| `/unions/:unionId/scoring-categories/:id` | DELETE | `scoring_categories:manage` |
| `/local-fields/:fieldId/scoring-categories` | GET | `scoring_categories:read` |
| `/local-fields/:fieldId/scoring-categories` | POST | `scoring_categories:manage` |
| `/local-fields/:fieldId/scoring-categories/:id` | PATCH | `scoring_categories:manage` |
| `/local-fields/:fieldId/scoring-categories/:id` | DELETE | `scoring_categories:manage` |

Todos los endpoints de division también usan `@GlobalRolesGuard + @GlobalRoles('admin', 'super_admin')` para limitar la edición a roles globales, alineado con el scope del nivel.

---

## 6. Consumo por features

Features que leen categorías:
- **weekly-records** (`docs/features/weekly-records.md`) — captura semanal registra puntos por categoría heredada del local-field del club.
- **member-of-month** (`docs/canon/runtime-member-of-month.md`) — agrega `weekly_record_scores` por categoría para determinar ganador del mes.
- **annual-folders-scoring** (`docs/features/annual-folders-scoring.md`) — categorías pueden usarse en secciones de carpeta anual.

Ninguno muta categorías — solo las leen. La autoridad de configuración vive exclusivamente en este subsistema.

---

## 7. Relación con otros canones

- `docs/canon/runtime-member-of-month.md` — consumidor principal del scoring semanal agregado.
- `docs/canon/runtime-rankings.md` — rankings anuales usan categorías indirectamente a través de carpetas.
- `docs/canon/dominio-sacdia.md` — jerarquía institucional (division/union/local-field).
- `docs/canon/decisiones-clave.md` §17 — canonización del dominio scoring-categories.

---

## 8. Invariantes

- ningún feature consumidor debe crear categorías propias — la autoridad de catálogo vive solo aquí;
- categorías de nivel superior se heredan sin duplicación en datos;
- el permiso `scoring_categories:*` es el único canónico para estos endpoints; reutilizar `units:*` en nuevos endpoints rompe la frontera de concerns;
- los 4 endpoints de division-level deben preservar `@GlobalRolesGuard` además del permiso — son configuración global reservada.
