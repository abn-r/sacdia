# Reporte de implementación — motor de certificaciones configurables

**Fecha:** 2026-08-11  
**Branches:**
- `sacdia-backend`: `feat/configurable-certifications` (11 commits de feature)
- `sacdia-app`: `feat/configurable-certifications` (4 commits de feature)
- `sacdia-admin`: `feat/configurable-certifications` (1 commit de feature)
- `sacdia` (docs): `feat/configurable-certifications` (4 commits documentales + este reporte)

**Planes seguidos:** `docs/plans/2026-08-05-configurable-certifications-engine-implementation-plan.md` + `docs/plans/2026-08-11-certificaciones-configurables-plan-ejecucion.md`

## 1. Resumen ejecutivo

Se implementó de extremo a extremo el motor de certificaciones configurables: dominio versionado e inmutable al publicar, migración expand/backfill, CRUD admin de borradores/publicación, elegibilidad por reglas, ejecución por requisito con evidencias R2 privadas, bandeja de revisión propia, cierre con comprobante de junta + certify, seed de la capacitación básica Pathfinder, app móvil del participante, panel admin de versiones y documentación canónica.

Quedan pendientes de operación humana: aplicar la migración y el seed contra Neon, y agregar GET admin de versiones/árbol (hoy el workbench es write-first en memoria de sesión).

## 2. Tareas del plan

| Fase/Tarea | Estado | Commit(s) | Notas |
|---|---|---|---|
| 0.1 Branches + baseline | completa | branches creadas | Backend 34/34 cert baseline; app sin tests previos; admin 33 fallos preexistentes en diálogos |
| 1 Domain invariants | completa | `9155029` | Máquina de estados + `CERT_*` + i18n |
| 2 Schema + migración | completa | `b47724c` (+ docs `3575262`) | `20260811180000_configurable_certifications_engine`; **no aplicada a Neon** |
| 3 Draft/publish CRUD | completa | `753cec5` | Permisos configure/publish/review/certify |
| 4 Elegibilidad configurable | completa | `4cc724d` | Reglas por FK; cero reglas → no elegible |
| 5 Draft/submit requisitos | completa | `1fbb013` (+ `89346ae`) | Legacy PATCH → 410 |
| 6 Evidencias R2 | completa | `cce65e4` | Presign+confirm; `getObjectInfo` |
| 7 Bandeja revisión | completa | `00da269` | `/certifications/reviews/*` |
| 8 Closeout + certify + e2e | completa | `65735d1` (+ `5d8b187`) | 17/17 e2e |
| 9 Seed PDF | completa | `8c9817e` | Idempotente; **no ejecutado en Neon** |
| 10 App contratos | completa | `e329cf9` | |
| 11 App UI requisitos | completa | `07a0ecc` | |
| 12 App drafts + closeout | completa | `d673261` (+ `5799a1b`) | Hive + i18n restaurados |
| 13 Admin + handoff | completa | handoff `a8b1274`; admin `13ae9d5` | Sin GET admin → workbench en sesión |
| 14 Docs integración | completa | `8013f5a` | Canon API/DB/features/canon |
| 9.1 Reporte | completa | este commit | |

## 3. Desviaciones del plan

1. **[RESUELTA 2026-08-12] Rutas de participante usaban `certificationId`** en lugar de `.../certification-enrollments/:enrollmentId/...` del plan base. Corregido: controllers y services de requisitos/evidencias/cierre reciben `enrollmentId` directo y validan ownership (inscripción existente, activa y del `userId` autenticado); el draft pasó de `PUT` a `PATCH` según el contrato. App y docs (`ENDPOINTS-LIVE-REFERENCE`) actualizados en el mismo trabajo.
2. **Specs de migración/seed bajo `src/certifications/`** porque Jest `rootDir=src` no descubre `prisma/` ni `scripts/*.spec.ts`.
3. **[RESUELTA 2026-08-12] Admin sin GET** de versiones/árbol/reglas. Follow-up en la misma branch agregó `GET /admin/certifications` (lista con resumen de versiones) y `GET /admin/certifications/:certificationId/versions/:versionId` (árbol completo + reglas); el workbench admin ahora carga la lista real al montar, hidrata el editor por versión (incluidos clones) y muestra PUBLISHED/RETIRED en modo lectura. Warning de "memoria de sesión" eliminado.
4. **Retiro de versión:** `DELETE .../publish` en runtime vs `POST .../retire` del plan.
5. **Reglas/árbol admin:** `PATCH` vs `PUT` del plan.
6. **Historial participante:** no hay `GET .../history` dedicado; historial vía detalle de revisor / proyección en requirement view.
7. **Honores faltantes en seed:** no omiten el requisito; sustituyen `LINKED_HONOR` por `TEXT_RESPONSE` y reportan en `skippedHonors` (Guía Mayor class sí es load-bearing y lanza).
8. **Commits de app 10–12** se fragmentaron; un fix posterior restauró Hive/`main.dart`/i18n perdidos por `git reset --hard` intermedio.
9. **Baseline admin** tenía fallos en `user-progress-dialog`/worktrees; no se “arreglaron”.
10. **Verificador dry-run contra DB** no ejecutado (sin DB local autorizada); solo tests estructurales del script.

## 4. Tests

| Repo | Comando | Resultado |
|---|---|---|
| backend (Fase 0) | `npm test -- src/certifications` | 34/34 passed |
| backend (Fase 8) | `npm test -- --runInBand src/certifications` | **270/270 passed** (15 suites) |
| backend | `npx tsc --noEmit -p tsconfig.build.json` | clean |
| backend | `npx prisma validate` | valid |
| backend | `npm run test:e2e -- --runInBand test/certifications.e2e-spec.ts` | **17/17 passed** |
| app (Fase 8) | `flutter test test/features/certifications` | **47/47 passed** |
| admin (Fase 0) | vitest área certs | fallos preexistentes (diálogos/worktrees) |
| admin (Fase 8) | vitest editors nuevos | **14/14 passed** |
| admin | `npm run typecheck` | clean |

## 5. Archivos modificados/creados

### sacdia-backend (selección)

- `prisma/migrations/20260811180000_configurable_certifications_engine/migration.sql` — expand/backfill versionado
- `prisma/schema.prisma` — modelos/enums del motor
- `prisma/seeds/certifications/basic-pathfinder-staff-training.seed.ts` + wiring en `core.ts`
- `prisma/seeds/permissions.seed.sql` / `role-permissions.seed.sql` — 4 permisos nuevos
- `scripts/verify-certifications-migration.ts` — verificador read-only
- `src/certifications/domain/*` — tipos + state machine
- `src/certifications/definitions/*` — CRUD borrador/publicación + parsers
- `src/certifications/eligibility/*` — reglas explicables
- `src/certifications/requirements/*` — draft/submit
- `src/certifications/evidence/*` — R2 presign/confirm/delete
- `src/certifications/review/*` — bandeja por requisito
- `src/certifications/closeout/*` — junta + certify
- Controllers admin/requirements/review/closeout + DTOs
- `test/certifications.e2e-spec.ts`
- `src/common/services/*file-storage*` — `getObjectInfo`
- `src/app.module.ts` / `exact-super-admin-write.policy.ts` — hardening e2e/DI

### sacdia-app

- Contratos/entidades/modelos/providers de requisitos, evidencias, review events
- `requirement_detail_view`, `certification_closeout_view`, component fields, status badge
- Hive drafts (`certification_draft_local_data_source` + `main.dart`)
- i18n es/en/fr/pt-BR; rutas nuevas
- Tests bajo `test/features/certifications/`

### sacdia-admin

- Workbench de versiones, tree editor, eligibility editor, create dialog, panel
- API client alineado a `name`/`sort_order`; permisos configure/publish
- i18n `certificationsAdmin`

### docs (raíz)

- Handoff admin, SCHEMA/API/SECURITY/ADR/FRONTEND, features + revision workflow, canon permisos, este reporte

## 6. Decisiones tomadas durante la ejecución

- Mantener bandeja `/certifications/reviews/*` separada de `evidence-review` (decisión congelada del plan).
- Unique parcial de inscripción activa excluye `WITHDRAWN`/`EXPIRED`.
- Trigger DB de inmutabilidad en `certification_versions` además de la política de aplicación.
- E2e con AppModule real + dobles de Prisma/R2/AuthContext (sandbox sin Neon).
- Admin workbench write-first hasta existir GET de versiones.

## 7. Pendientes y riesgos

- Migración `20260811180000_configurable_certifications_engine` **versionada, no aplicada a Neon**.
- Seed PDF **no ejecutado** contra Neon.
- Endpoints legacy activos con `CERT_LEGACY_ENDPOINT_DEPRECATED` (410) en PATCH progreso versionado; fecha de retiro pendiente.
- `certification_module_progress` permanece como proyección legacy.
- Honores Contabilidad / Anti-bullying I pueden faltar en catálogo → fallback TEXT_RESPONSE.
- Fallos preexistentes admin en diálogos/worktrees.

## 8. Verificación manual sugerida

1. En un entorno de desarrollo **no Neon de producción**: aplicar `prisma migrate deploy` de `20260811180000_configurable_certifications_engine`.
2. Ejecutar seed core / `seedBasicPathfinderStaffTraining` y confirmar 8 módulos / 19 requisitos / reglas 18+bautismo+GM.
3. Como Guía Mayor investido: ver catálogo → enroll → completar requisito con texto/archivo → submit.
4. Como revisor in-scope (`certifications:review`): aprobar; fuera de scope → 403 `CERT_REVIEW_SCOPE_FORBIDDEN`.
5. Subir comprobante de junta → submit-final → aprobar closeout → certify (repetir certify = idempotente).
6. En admin con `certifications:configure`/`publish`: crear borrador, árbol, reglas, publish; intentar editar PUBLISHED → conflicto.
7. Correr `CERTIFICATIONS_MIGRATION_VERIFY_DATABASE_URL=... npx tsx scripts/verify-certifications-migration.ts --dry-run` (sin Neon salvo opt-in).
