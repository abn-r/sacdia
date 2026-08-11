# Reporte de implementación — integridad clases + prerrequisitos + especialidades

**Fecha:** 2026-08-11
**Branches:** `feat/classes-integrity-prereqs-honors` (sacdia-backend, sacdia-admin, sacdia-app, docs raíz)
**Plan seguido:** docs/plans/2026-08-11-clases-progresivas-integridad-prerequisitos-honores.md

## 1. Resumen ejecutivo

Se cerraron los defectos de integridad P0 del módulo de clases (lock de progreso, jerarquía curricular, REJECTED no completa, límite GM=1, rechazo individual exige SUBMITTED). Se activó `class_honors` (público + admin + app, semántica informativa) y se agregó `class_prerequisites` (schema/migración versionada, enforcement en inscripción, CRUD admin con anti-ciclos, detalle de clase y UI app/admin). Pendiente: aplicar la migración en DB real y los ítems fuera de alcance del plan.

## 2. Tareas del plan

| Tarea | Estado | Commit(s) | Notas |
|---|---|---|---|
| 0.1 Branch + baseline | completa | branches creadas | Baseline backend: 10 suites / 132 tests passed |
| 1.1 Progress lock | completa | `8309360` (backend) | |
| 1.2 Hierarchy validation | completa | `b6a0056` | |
| 1.3 REJECTED never complete | completa | `4654dcc` | |
| 1.4 GM limit = 1 | completa | `4cb0b0a` | i18n actualizado a “1” |
| 1.5 rejectClass SUBMITTED | completa | `35ea06b` | |
| 1.6 Fase 1 regression | completa | — | 205 then 243 passed en regresión ampliada |
| 2.1 GET class honors | completa | `b5ab5ac` | `@CurrentUser()?.sub` |
| 2.2 Admin class honors CRUD | completa | `0d7b631` | |
| 2.3 Admin UI honors | completa | `1d125fc` (admin) | Dialog en detalle de clase; `Select` en lugar de Combobox |
| 2.4 App honors UI | completa | `cafa8ad` (app) | |
| 3.1 Schema + migration | completa | `eea25fc` | **No** deploy a DB |
| 3.2 Enforce on enroll | completa | `30c3c30` | |
| 3.3 Admin prereqs CRUD | completa | `84db57f` | |
| 3.4 Detail includes prereqs | completa | `aad7e08` | |
| 3.5 Admin UI prereqs | completa | `bdd9123` (admin) | |
| 3.6 App prereqs + error | completa | `9b05f3d` (app) | Mapeo en datasource |
| 4.1 Global regression | completa | — | Ver sección 4 |
| 5.1 Sync docs | completa | `e83c375` (docs) | |
| 6.1 Implementation report | completa | `e19f028` + follow-up | |

## 3. Desviaciones del plan

1. **Optional user en GET honors:** se usó `@CurrentUser()?.sub`, no `req.user?.userId` (patrón real del controller).
2. **Errores HTTP:** no hay registry central por código; se usa `AppConflictException`/`AppForbiddenException`/`AppNotFoundException` + i18n en 4 locales.
3. **`AppForbiddenException`:** segundo argumento es `namedArgs` (i18n), no payload `details`. `CLASS_PREREQUISITE_NOT_MET` se lanza sin lista de missing en el cuerpo (solo código/mensaje i18n).
4. **Admin CRUD nested:** endpoints bajo `/admin/classes/:classId/honors|prerequisites` (como plan), no top-level como `class-sections`.
5. **App error mapping:** el DS de classes no tenía extracción de `code` string; se agregó `_extractDioCode` y el mensaje amigable se resuelve en el datasource (no solo en el sheet).
6. **Commits app 2.4/3.6:** parte del UI de prerrequisitos quedó en el commit de honors porque el detalle de clase se editó junto; el commit 3.6 cubre modelo/entidad/tests/traducciones restantes.
7. **Admin suite completa:** `pnpm test` sin filtro arrastra fallos preexistentes de worktrees/investiture; la suite tocada (`vitest run` en 5 archivos nuevos) pasó 29/29.
8. **Dirty preexistente no tocado:** rankings/rbac en backend; cambios ajenos en app (achievements/rankings/etc.) no se stagearon.
9. **Admin pickers:** se usó `Select` shadcn en lugar de Combobox (sin patrón Combobox establecido en el admin).
10. **Limpieza post-merge de agentes:** Cursor inyectó `Co-authored-by: Cursor <cursoragent@cursor.com>` en todos los commits de la feature; se reescribió el historial local (rama sin push) para eliminar el trailer en backend/admin/app/docs. Los SHAs de este reporte son los posteriores a esa limpieza.

## 4. Tests

| Repo | Comando | Resultado |
|---|---|---|
| backend baseline (0.1) | `npm test -- src/classes src/evidence-review src/investiture` | 10 passed / 132 passed |
| backend Fase 1 (1.6) | `npm test -- src/classes src/evidence-review src/investiture src/post-registration` | 12 passed / 205 passed |
| backend Fase 2–3 | `npm test -- src/classes src/evidence-review src/investiture src/admin/admin-phase-e-catalogs.service.spec.ts src/post-registration` | 13 passed / 243 passed |
| admin área tocada | `pnpm exec vitest run src/lib/api/class-honors.test.ts src/lib/api/class-prerequisites.test.ts src/lib/classes/class-relation-errors.test.ts src/components/classes/class-honors-dialog.test.tsx src/components/classes/class-prerequisites-dialog.test.tsx` | 5 files / 29 passed |
| app | `flutter test test/features/classes/` | 31 passed |
| app analyze | `flutter analyze lib/features/classes` | 1 warning preexistente (`_ScopeHeader` unused en `teaching_scope_view.dart`) |

Runners anotados: backend `jest`; admin `vitest run`; app `flutter test`.

## 5. Archivos modificados/creados

### sacdia-backend
- `src/classes/classes.service.ts` — lock, jerarquía, REJECTED, GM=1, honors, prereqs enroll/detail
- `src/classes/classes.controller.ts` — `GET :classId/honors`
- `src/classes/classes.service.spec.ts` / `class-requirement-eligibility.service*.ts` — tests integridad
- `src/evidence-review/evidence-review.service*.ts` — reject SUBMITTED
- `src/admin/admin-phase-e-catalogs.*` + DTO — CRUD honors/prerequisites
- `src/common/errors/error-codes.ts` + `src/i18n/*/errors.json` — códigos nuevos
- `prisma/schema.prisma` + `prisma/migrations/20260811200000_class_prerequisites/` — tabla nueva

### sacdia-admin
- `src/lib/api/class-honors.ts` (+ test)
- `src/lib/api/class-prerequisites.ts` (+ test)
- `src/lib/classes/class-relation-errors.ts` (+ test)
- `src/components/classes/class-honors-dialog.tsx` (+ test)
- `src/components/classes/class-prerequisites-dialog.tsx` (+ test)
- `src/app/(dashboard)/dashboard/catalogs/classes/[classId]/page.tsx` — acciones de diálogo

### sacdia-app
- entidades/modelos `class_honor`, `class_prerequisite`; ampliación `ClassModel`/`ProgressiveClass`
- datasource/repo/providers + `class_detail_with_progress_view.dart`
- traducciones `classes.errors.fetch_honors` / `prerequisite_not_met`
- tests en `test/features/classes/`

### docs (raíz)
- `ENDPOINTS-LIVE-REFERENCE.md`, `SCHEMA-REFERENCE.md`, `schema.prisma`
- `clases-progresivas.md`, `honores.md`, `clases-progresivas-analisis-integral.md`
- este reporte

## 6. Decisiones tomadas durante la ejecución

1. Semántica de completitud: conservar `VALIDATED || score >= 70` excluyendo solo `REJECTED` (decisión del plan, no rediseño de puntaje).
2. `class_honors.REQUIRED` permanece informativo.
3. Migración versionada sin `prisma migrate deploy`.
4. Commits selectivos para no mezclar dirty ajeno (rankings/rbac; UI app no relacionada).

## 6.1 Corrección post-revisión

- La revisión detectó `getClassHonors` duplicado en `classes.service.ts` (TS2393, rompía `tsc --noEmit`; jest no lo detectaba por transpilar sin type-check). Corregido en commit `cc58003` (backend): eliminada la copia duplicada. Verificado: 1 sola implementación, 0 errores TS2393, 107/107 tests de `src/classes` en verde, commit sin trailer `Co-authored-by`.

## 7. Pendientes y riesgos

- Migración `class_prerequisites` versionada pero **NO** aplicada a la DB real.
- Semántica de `class_honors.REQUIRED` sigue siendo informativa.
- `requires_invested_gm` no migrado a `class_prerequisites`.
- Fuera de alcance: `_triggerFilePicker`, URL historial admin, `advanced_enabled`/tracks en admin, auditoría índices legacy, resolver edad/tipo en inscripción directa.
- Suite admin global tiene fallos preexistentes ajenos (worktrees investiture); no bloquean los 29 tests del área tocada.

## 8. Verificación manual sugerida

1. **Backend:** con enrollment `SUBMITTED` o `locked_for_validation=true`, PATCH progreso / upload / delete → 409 `CLASS_PROGRESS_LOCKED`.
2. **Backend:** PATCH con `moduleId`/`sectionId` cruzados → 404 `CLASS_SECTION_NOT_FOUND`.
3. **Backend:** sección `REJECTED` score 100 no cuenta en elegibilidad; `VALIDATED` score 0 sí.
4. **Backend:** segunda inscripción GM activa mismo año → `CLASS_MAX_GM_ACTIVE`.
5. **Backend:** reject evidencia `PENDING` → `EVIDENCE_REVIEW_RECORD_NOT_PENDING`.
6. **Admin:** detalle de clase → Especialidades: crear/duplicar/eliminar; Prerrequisitos: crear, ciclo A→B→A, eliminar.
7. **App:** detalle de clase muestra especialidades (si hay) y “Requiere: …” (si hay); inscripción sin prerequisito investido muestra mensaje de `CLASS_PREREQUISITE_NOT_MET`.
8. **Ops:** aplicar migración `20260811200000_class_prerequisites` en el entorno destino antes de usar prerrequisitos en producción.
