# Club-Sections Consolidation — Tareas Post-Merge

> Código mergeado a `main` en los 4 repos (2026-03-18).
> Migración aplicada a la DB de desarrollo (2026-03-18).

---

## Tarea 1: Pre-migration audit ✅ COMPLETADA

**Resultado** (2026-03-18):
- `club_adventurers`: 0 filas
- `club_pathfinders`: 0 filas
- `club_master_guilds`: 1 fila (Guías Mayores)
- Multi-FK anomalies: 0
- Orphan FKs: 0
- 4 permisos `club_instances:*` detectados para migrar

---

## Tarea 2: Ejecutar migración ✅ COMPLETADA

**Resultado** (2026-03-18):
- Migración `20260317170419_consolidate_club_sections` aplicada exitosamente
- Fix aplicado: unique indexes (no constraints) necesitaban `DROP INDEX IF EXISTS` además de `DROP CONSTRAINT IF EXISTS`
- Commit del fix: `4be407a`

---

## Tarea 3: Post-migration verify ✅ COMPLETADA

**Resultado** (2026-03-18):
- `club_sections` count: 1 (PASS)
- Orphan FKs: 0 en 6 tablas (PASS)
- Old columns dropped (PASS)
- 10 FK constraints creados (PASS)
- 12 indexes creados (PASS)
- Tablas `_deprecated` existen (PASS)
- Permisos migrados a `club_sections:*` (PASS)

---

## Tarea 4: E2E tests ✅ COMPLETADA

**Resultado** (2026-03-18):
- Primera corrida: 6 tests fallando (mocks con columnas viejas, path de docs desactualizado)
- Fix: 4 archivos e2e actualizados + `prisma generate`
- Commit: `5db959d`
- **16 suites, 106 tests, ALL PASSING**

---

## Tarea 5: Fix backend `dist/` en .gitignore ✅ COMPLETADA

**Resultado** (2026-03-18):
- 479 archivos de `dist/` eliminados del tracking
- Commit: `aabad57`
- PR: https://github.com/abn-r/sacdia-backend/pull/5 (`development → preproduction`)
- Pendiente: mergear PR #5, luego crear PR `preproduction → main`

---

## Tarea 6: Drop tablas deprecated ✅ COMPLETADA

**Resultado** (2026-03-18):
- 3 tablas deprecated dropeadas: `club_adventurers_deprecated`, `club_pathfinders_deprecated`, `club_master_guilds_deprecated`
- Verificado: 0 tablas `*_deprecated` en la DB
- Grace period omitido (producto no está en producción)

---

## Orden de ejecución

```
Tarea 5 (gitignore fix) ← independiente, se puede hacer en cualquier momento
Tarea 4 (e2e tests) ← siguiente pendiente
Tarea 6 (drop deprecated) ← después del 2026-03-25
```
