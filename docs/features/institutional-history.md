# Histórico institucional

**Estado**: PARCIAL
**Verificado contra código**: 2026-10-04 (rama `development`)
**Plan vigente**: [`docs/plans/2026-07-23-institutional-history-implementation-plan.md`](../plans/2026-07-23-institutional-history-implementation-plan.md) · ADR: [`docs/plans/2026-07-23-institutional-history-architecture-decision.md`](../plans/2026-07-23-institutional-history-architecture-decision.md) · decisión canónica: `docs/canon/decisiones-clave.md` §25

## Descripcion de dominio

Las estructuras de la iglesia cambian: una unión pasa a otra división, un campo local se divide, un club cambia de iglesia. El histórico institucional guarda a qué jerarquía pertenecía cada entidad en cada fecha, para que los actos oficiales cerrados (carpetas anuales, rankings) conserven el contexto que tenían y no se reinterpreten con la estructura actual.

En `development` existe la base: tablas de historial de relaciones, tablas de reorganización y nombres versionados, un servicio que resuelve la jerarquía a una fecha y que guarda instantáneas. No hay módulo HTTP: `src/institutional-history/` no tiene controller ni está registrado como módulo de Nest.

## Que existe (verificado contra codigo)

### Backend

- **`InstitutionalHierarchyService`** (`src/common/services/institutional-hierarchy.service.ts`):
  - `resolveCurrent(input)`: jerarquía vigente desde las FKs actuales.
  - `resolveAsOf(entity, asOf)`: jerarquía a una fecha desde las tablas `*_history`. Si no hay fila histórica, usa la jerarquía actual y marca `precision = 'unknown'`.
  - `snapshotForClub(clubId, asOf, createdBy?)`: inserta una fila en `hierarchy_contexts` (`source = 'snapshot'`) y devuelve su `hierarchy_context_id`.
- **Consumidores**: cierre de carpetas anuales (`annual-folders.service.ts`, `evaluation.service.ts`), cierre de año (`year-end.service.ts`), rankings de clubes (`annual-folders/rankings.service.ts`) y rankings de miembros (`member-rankings.service.ts`, `camporee-score.service.ts`).
- **Escritura de historial**: solo el cambio de división de una unión escribe historial (`union_division_history`, en `admin-geography.service.ts`). Campo local, distrito, iglesia y club cambian sus FKs sin crear fila de historial.
- **Utilidades de dominio** (`src/institutional-history/`), hoy solo usadas por tests:
  - `domain/temporal-interval.policy.ts`: intervalos semiabiertos `[valid_from, valid_to)`, `valid_to` nulo = abierto, rechazo de `valid_to <= valid_from`, revisiones de corrección. Precisiones admitidas: `exact`, `day`, `month`, `year`, `system_backfill`, `unknown`.
  - `sensitive-context.policy.ts`: lista de claves prohibidas en `hierarchy_contexts.context` (salud, contactos de emergencia, representante legal, documentos, teléfono, contraseñas, tokens) y SQL recursivo para detectarlas.

### Base de datos

Migración base: `20260723120000_institutional_history_foundation`.

- Historial de relaciones (bitemporal: `valid_from/valid_to` + `recorded_from/recorded_to`, `precision`, `reorganization_id`): `union_division_history`, `local_field_union_history`, `district_local_field_history`, `church_district_history`, `club_institutional_history`.
- Instantáneas: `hierarchy_contexts` (división, unión, campo local, distrito, iglesia, club, `as_of`, `source`, `precision`, `context` JSON). La referencian `annual_folders`, `club_annual_rankings`, `enrollment_rankings` y `section_rankings` (`ON DELETE SET NULL`).
- Reorganizaciones y nombres (sin uso en código todavía): `institutional_reorganizations` (con `idempotency_key` único y `authority_source` por defecto `WORLD_CHURCH_EXECUTIVE`), `institutional_reorganization_participants`, `institutional_lineage_edges`, `institutional_name_versions`, `institutional_name_version_translations`.
- En el schema, la columna de distrito se llama `districlub_type_id` (nombre heredado; contiene el id de distrito).

`institutional_certificate_requests` no pertenece a este dominio: son solicitudes de certificados de Guía Mayor Avanzado e Instructor (ver [carga-masiva-certificados.md](carga-masiva-certificados.md)).

### Admin y app

- Sin pantallas.

## Gaps y pendientes

Los recoge el plan vigente. Los más visibles en código:

- `resolveAsOf` combina relaciones históricas con nombres actuales; `institutional_name_versions` no se lee.
- El fallback a la jerarquía actual con `precision = 'unknown'` es silencioso.
- Solo `union → division` registra historial desde el CRUD geográfico.
- No hay API ni UI para registrar reorganizaciones (fusiones, divisiones, cambios de nombre).
