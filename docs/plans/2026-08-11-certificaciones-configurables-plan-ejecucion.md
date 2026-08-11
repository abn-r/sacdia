# Plan de ejecución: motor de certificaciones configurables

> **Para el agente ejecutor:** sigue este plan fase por fase, en orden. Este documento define el CÓMO (orden, branches, gates, commits, reporte). El QUÉ (modelo de datos, contratos API, invariantes, casos de test por tarea) vive en el plan base `docs/plans/2026-08-05-configurable-certifications-engine-implementation-plan.md` — léelo COMPLETO antes de empezar y trátalo como fuente de diseño no negociable. Si un supuesto de cualquiera de los dos documentos no coincide con el código real (nombres de campos, rutas, líneas, scripts de package.json), verifica en el archivo indicado y adapta el detalle, pero NO cambies el diseño ni el alcance. Registra toda desviación en el reporte final (Fase 9).

**Objetivo:** convertir el módulo parcial de certificaciones en un motor configurable, versionado y auditable: definiciones versionadas e inmutables al publicar, elegibilidad por reglas configurables, ejecución y revisión requisito por requisito con evidencias privadas en R2, cierre institucional con comprobante de junta, y la certificación "Capacitación básica para el personal del Club de Conquistadores" cargada como datos (seed), no como código.

**Arquitectura:** monorepo con `sacdia-backend` (NestJS 11 + Prisma 7 + PostgreSQL/Neon), `sacdia-app` (Flutter, Clean Architecture, Riverpod) y `sacdia-admin` (Next.js 16 + shadcn/ui). Contract-first: backend define endpoints/DTOs/permisos/errores antes de que app y admin los consuman.

**Contexto obligatorio antes de empezar (leer en este orden):**
1. `AGENTS.md` raíz.
2. `docs/plans/2026-08-05-configurable-certifications-engine-implementation-plan.md` (plan base: brechas, invariantes, modelo, contrato API, Tasks 1–14).
3. `docs/canon/runtime-user-certifications.md` (invariante de permisos).
4. `docs/features/certificaciones-guias-mayores.md` (estado actual del feature).
5. `sacdia-backend/CLAUDE.md` y `sacdia-backend/src/certifications/` (módulo actual).

**Reglas duras (de AGENTS.md):**
- Conventional commits. Nunca `Co-Authored-By` ni atribución de IA.
- No ejecutar builds; sí ejecutar tests del módulo afectado, typecheck, lint dirigido, `prisma validate` y `flutter analyze`.
- No tocar `.env` reales ni secretos.
- No aplicar migraciones contra bases de datos reales (Neon). La migración queda versionada; el usuario la aplica después.
- Actualizar documentación canónica en el mismo trabajo (Fase 7).
- No mezclar cambios locales ajenos preexistentes en ninguno de los repos.

**Decisiones ya tomadas (no re-discutir):**
1. **Branch única por repo** en lugar de los 7 PRs encadenados que recomienda el plan base: un solo agente ejecuta secuencialmente y el usuario valida al final, igual que en el trabajo previo de clases progresivas. Los "PR 1–7" del plan base se ejecutan como Fases 1–7 con checkpoint (tests verdes + commits) al cierre de cada una. Branch: `feat/configurable-certifications` en los tres repos.
2. **Certificaciones ≠ clases progresivas.** Dominio separado; se reutilizan patrones (árbol, evidencias R2, honores), no ciclo de vida.
3. **Bandeja de revisión propia** (`/certifications/reviews/*`), separada de `evidence-review`. Decisión fechada 2026-08-11 en el plan base; se registra en `docs/api/ARCHITECTURE-DECISIONS.md` en Fase 7.
4. **Versionado inmutable:** `PUBLISHED` no se edita; se clona a `DRAFT`. Cada inscripción fija exactamente una versión publicada.
5. **Estados:** inscripción `ENROLLED → IN_PROGRESS → READY_FOR_CLOSEOUT → SUBMITTED_FOR_FINAL_REVIEW → APPROVED → CERTIFIED` (más `WITHDRAWN`/`EXPIRED`/`CHANGES_REQUESTED`); requisito `DRAFT → SUBMITTED → APPROVED | CHANGES_REQUESTED → SUBMITTED`. No usar el vocabulario de clases (`VALIDATED`/`REJECTED`).
6. **Migración expand/backfill sin destrucción:** no se eliminan columnas legacy ni los 7 endpoints actuales (quedan como adaptadores deprecated). `certification_module_progress` deja de ser fuente de verdad pero NO se elimina en esta entrega.
7. **Patrón R2:** presign de carga + confirm siguiendo `sacdia-backend/src/resources/` (NO el spec de `annual-folders`, que presigna descargas). Objetos privados, URL firmada corta solo tras autorización.
8. **`LINKED_HONOR`:** reutilizar el patrón de consulta `users_honors.validation_status` de `ClassesService.getClassHonors` (`sacdia-backend/src/classes/classes.service.ts`).
9. **Fuente del contenido del seed (Fase 4):** el mapeo de 8 módulos / 19 requisitos ya transcrito en el plan base, Task 9 Step 2. El PDF original (`/Users/abner/Downloads/document_compress-2.pdf`) es referencia; si no está disponible, el mapeo del plan base es canónico.
10. **Permisos nuevos** (`certifications:configure|publish|review|certify`) no se mezclan con `certifications:read` (browse) ni `user_certifications:*` (progresión). Invariante de `docs/canon/runtime-user-certifications.md`.

---

## Fase 0 — Preparación

### Task 0.1: Branches y baseline

**Step 1:** crear branch en los tres repos desde `development` actualizado:

```bash
cd sacdia-backend && git checkout development && git pull && git checkout -b feat/configurable-certifications && cd ..
cd sacdia-app && git checkout development && git pull && git checkout -b feat/configurable-certifications && cd ..
cd sacdia-admin && git checkout development && git pull && git checkout -b feat/configurable-certifications && cd ..
```

**Step 2:** verificar runners y scripts reales:
- Backend: `sacdia-backend/package.json` — confirmar comando de test (jest), test:e2e, `prisma validate`, y cómo se estructuran los seeds reales bajo `prisma/seeds/` (el plan base asume `permissions.seed.sql`, `role-permissions.seed.sql`, `core.ts`; si el layout difiere, adaptar y anotar en el reporte).
- App: `flutter test` desde `sacdia-app/`.
- Admin: `sacdia-admin/package.json` — identificar test runner (vitest esperado), `typecheck`, `lint`, y si existe `audit:design-system`.

**Step 3:** baseline del área afectada (guardar resúmenes para el reporte; si hay fallos preexistentes, anotarlos y NO arreglarlos):

```bash
cd sacdia-backend && npm test -- src/certifications
cd sacdia-app && flutter test test/features/certifications
cd sacdia-admin && <runner> src/lib/certifications  # o el área de certificaciones que exista
```

**Step 4:** confirmar en el schema actual (`sacdia-backend/prisma/schema.prisma`) los modelos existentes de certificaciones (`certifications`, `certification_modules`, `certification_sections`, `users_certifications`, `certification_module_progress`, `certification_section_progress` con `evidences Json?` sin uso). Anotar cualquier discrepancia con el plan base.

---

## Fase 1 — Definición versionada y migración segura (plan base: PR 1, Tasks 1–3)

Ejecutar **Task 1** (dominio puro + máquina de estados), **Task 2** (schema + migración expand/backfill + script verificador) y **Task 3** (CRUD de borradores, publicación, permisos) del plan base, con sus steps RED→GREEN→commit tal como están escritos.

**Precisiones de ejecución:**

- Task 1: los errores nuevos van en `sacdia-backend/src/common/errors/error-codes.ts` junto a un bloque `CERT_*`: `CERT_VERSION_NOT_PUBLISHED`, `CERT_VERSION_IMMUTABLE`, `CERT_REQUIREMENT_LOCKED`, `CERT_REQUIREMENT_INCOMPLETE`, `CERT_INVALID_TRANSITION`, `CERT_EVIDENCE_INVALID_TYPE`, `CERT_EVIDENCE_TOO_LARGE`, `CERT_REVIEW_SCOPE_FORBIDDEN`, `CERT_CLOSEOUT_INCOMPLETE`, `CERT_CONCURRENT_UPDATE`. Buscar cómo se mapean códigos→HTTP/mensajes (buscar usos de `CLASS_PROGRESS_LOCKED`, agregado recientemente, como referencia del patrón completo).
- Task 2: nombrar la migración con timestamp del día de ejecución (`YYYYMMDDHHMMSS_configurable_certifications_engine`). Redactarla idempotente donde sea posible (`IF NOT EXISTS`). NO ejecutarla contra Neon; solo `prisma validate` + tests estructurales. El backfill (crear versión 1 publicada por certificación existente, fijar inscripciones, rellenar `enrollment_id` en progreso) va DENTRO de la migración SQL, con los casos ambiguos documentados en el verificador.
- Task 3: antes de tocar seeds de permisos, leer el layout real de `sacdia-backend/prisma/seeds/`. Los 4 permisos nuevos se agregan también a la matriz de roles que corresponda (mínimo: rol admin de configuración obtiene `configure`+`publish`; roles institucionales de revisión obtienen `review`+`certify` según scope). Anotar la asignación exacta en el reporte.

**Gate de fase:**

```bash
cd sacdia-backend
npm test -- src/certifications
npx prisma validate
npx tsc --noEmit
```

Expected: todo verde. Commits mínimos de la fase: 3 (uno por task, mensajes del plan base).

---

## Fase 2 — Elegibilidad, inscripción y ejecución por requisito (plan base: PR 2, Tasks 4–5)

Ejecutar **Task 4** (elegibilidad configurable explicable) y **Task 5** (borradores y envíos por requisito) del plan base.

**Precisiones de ejecución:**

- Task 4: la regla `INVESTED_CLASS` se evalúa contra `enrollments.investiture_status = 'INVESTIDO'` por FK de clase, nunca por `classes.name`. El endpoint de elegibilidad usa el JWT del usuario autenticado; rechazar consultas de elegibilidad de terceros.
- Task 4: al eliminar la elegibilidad por texto `'Guía Mayor'`, los 7 endpoints legacy siguen funcionando (adaptadores); el catálogo público con `OptionalJwtAuthGuard` se restringe según el contrato del plan base (participante elegible o revisor autorizado). Documentar el cambio de visibilidad en el reporte.
- Task 5: el PATCH legacy de checkbox responde error deprecado (410 o código de error explícito) para inscripciones fijadas a versiones configurables; para datos legacy proyecta `completed = status == APPROVED` en lectura.
- Task 5: concurrencia con `lock_version` + transacción; enviar dos veces no duplica evento de historial.

**Gate de fase:**

```bash
cd sacdia-backend
npm test -- src/certifications
npx tsc --noEmit
```

Commits mínimos: 2.

---

## Fase 3 — Evidencias, revisión y cierre institucional (plan base: PR 3, Tasks 6–8)

Ejecutar **Task 6** (cargas privadas R2), **Task 7** (bandeja y revisión por requisito) y **Task 8** (comprobante de junta + cierre final + e2e) del plan base.

**Precisiones de ejecución:**

- Task 6: la API genera el object key bajo namespace de inscripción; nunca aceptar URL/key del cliente. MIME permitidos para evidencias y comprobante: `image/jpeg`, `image/png`, `image/webp`, `application/pdf`. Verificar MIME/tamaño en presign Y en confirm (contra metadata real del objeto vía `getObjectInfo`). Estado `PENDING_UPLOAD → CONFIRMED`; eliminación bloqueada tras envío del requisito.
- Task 7: comentario obligatorio al devolver (`CHANGES_REQUESTED`); aprobar solo desde `SUBMITTED`; historial append-only sin cascada de borrado; revisor ≠ participante; scope institucional verificado antes de firmar URLs.
- Task 8: `certify` re-verifica TODO dentro de la transacción (requisitos obligatorios `APPROVED` + comprobante aprobado); idempotente. El e2e cubre participante, revisor válido, revisor fuera de scope y cierre completo.

**Gate de fase:**

```bash
cd sacdia-backend
npm test -- src/certifications
npm run test:e2e -- test/certifications.e2e-spec.ts   # adaptar al script real
npx tsc --noEmit
```

Commits mínimos: 3.

---

## Fase 4 — Seed de la certificación del PDF (plan base: PR 4, Task 9)

Ejecutar **Task 9** del plan base: seed idempotente de "Capacitación básica para el personal del Club de Conquistadores".

**Precisiones de ejecución:**

- Contenido canónico: mapeo de 8 módulos del plan base Task 9 Step 2 (estilos de enseñanza, estilos de aprendizaje, necesidades especiales, valores cristianos, objetivos de investidura, aplicaciones prácticas, enseñanza de honores, disciplina), 19 requisitos principales, reglas de elegibilidad (18 años, bautizado, Guía Mayor investido), duración 1–2 años.
- Los honores referenciados (Contabilidad, Anti-bullying I, etc.) se resuelven por lookup contra el catálogo `honors` existente; si un honor no existe en la DB de desarrollo, el seed lo reporta y omite el componente `LINKED_HONOR` sin romper (anotar en reporte).
- Invariante 12 del plan base: el requisito de "base de datos de miembros y padres" se modela como constancia/formato controlado (`ATTESTATION`), nunca como planilla descargable con datos de menores.
- NO ejecutar el seed contra Neon; solo el test del árbol (fixture) y la verificación de idempotencia vía test.

**Gate de fase:** test del seed verde. Commit mínimo: 1.

---

## Fase 5 — App móvil del participante (plan base: PR 5, Tasks 10–12)

Ejecutar **Task 10** (contratos/entidades/navegación), **Task 11** (ejecución de requisitos y evidencias) y **Task 12** (borradores locales + cierre) del plan base.

**Precisiones de ejecución:**

- Task 10 corrige el bug de identidad existente: `CertificationProgressView` consulta el provider con `enrollmentId` aunque este espera `certificationId`, y el toggle invalida con `certificationId` (~L459 de `certification_progress_view.dart`). Tras el fix: provider de ejecución recibe `enrollmentId`; `certificationId` solo para catálogo/enroll.
- Task 11: la UI interpreta `component.type` (`TEXT_RESPONSE`, `FILE_EVIDENCE`, `LINKED_HONOR`, `LINKED_ACTIVITY`, `ATTESTATION`, `AUTO_VALIDATION`); prohibido condicionar por nombre o ID de la certificación del PDF. Reusar `evidence_staging_manager.dart` y como referencia visual `features/classes/presentation/views/requirement_detail_view.dart`.
- Task 12: borradores locales por `enrollmentId + requirementId` (Hive), restauración tras reinicio, limpieza tras envío. NO prometer envío offline. i18n completo en los 4 locales (`es`, `en`, `fr`, `pt-BR`).
- Mapear los códigos de error `CERT_*` a mensajes de usuario donde el feature ya mapea errores del backend.

**Gate de fase:**

```bash
cd sacdia-app
dart format lib/features/certifications test/features/certifications
flutter test test/features/certifications
flutter analyze lib/features/certifications
```

Commits mínimos: 3.

---

## Fase 6 — Panel administrativo contract-first (plan base: PR 6, Task 13)

Ejecutar **Task 13** del plan base: primero el documento de handoff, después la UI.

**Precisiones de ejecución:**

- **Step 1 obligatorio:** crear `docs/plans/handoffs/configurable-certifications-admin-handoff.md` (repo raíz) con endpoints/DTOs REALES ya implementados en Fases 1–3 (no los teóricos del plan base si divergieron), permisos, errores, estados de UI, criterio de publicación y la regla de no editar versiones publicadas.
- UI: editor de versiones (borrador, orden de módulos/requisitos, componentes múltiples, reglas de elegibilidad), clonado y diálogo de confirmación de publicación. Mantener `PageHeader`, tokens semánticos, shadcn/ui, i18n en los 4 locales de `sacdia-admin/messages/`.
- Corregir de paso el desajuste `title` vs `name` en `src/lib/api/certifications.ts` alineando al contrato real del backend (hoy mitigado con `title ?? name` en `catalog-normalize.ts`).
- No modificar backend desde `sacdia-admin`. Si el contrato no alcanza, detener, anotar en el reporte y ajustar backend en commit separado del repo backend.

**Gate de fase:**

```bash
cd sacdia-admin
<runner> src/components/certifications
npm run typecheck   # o pnpm, según lo detectado en Fase 0
npm run lint -- src/components/certifications src/lib/certifications src/lib/api/certifications.ts
```

Commits mínimos: 2 (handoff en repo raíz + UI en sacdia-admin).

---

## Fase 7 — Integración, compatibilidad y documentación (plan base: PR 7, Task 14)

Ejecutar **Task 14** del plan base.

**Docs canónicas a actualizar (repo raíz `sacdia`):**
- `docs/api/ENDPOINTS-LIVE-REFERENCE.md`: todos los endpoints nuevos (participante, revisor, admin), códigos `CERT_*`, y los 7 endpoints legacy marcados deprecated con fecha.
- `docs/api/SECURITY-GUIDE.md`: permisos nuevos, ownership de evidencias, URLs firmadas.
- `docs/api/ARCHITECTURE-DECISIONS.md`: decisión de bandeja propia vs `evidence-review` + divergencia de vocabulario de estados (`APPROVED/CHANGES_REQUESTED` vs `VALIDATED/REJECTED`).
- `docs/api/FRONTEND-INTEGRATION-GUIDE.md`: envelopes y ejemplos por tipo de componente.
- `docs/database/SCHEMA-REFERENCE.md` y `docs/database/schema.prisma`: tablas nuevas (copiar modelos desde el schema del backend).
- `docs/features/certificaciones-guias-mayores.md`: estado nuevo del feature.
- Create: `docs/features/certificaciones-guias-mayores-revision-workflow.md`: flujo de revisión por requisito y cierre.
- `docs/canon/runtime-user-certifications.md`: si los permisos efectivos cambiaron la matriz, actualizar SIN romper la invariante browse/progresión.

**Matriz mínima de pruebas de integración (e2e backend, 10 casos del plan base Task 14 Step 2):** no investido denegado; inscripción fija versión; borrador+carga+envío; revisor fuera de scope 403; devolución y reenvío; cierre bloqueado sin junta; certificación bloqueada con junta sin aprobar; certificación idempotente; versión nueva no afecta inscripción vieja; reinscripción no hereda progreso.

**Verificación de migración dry-run:**

```bash
cd sacdia-backend
npx tsx scripts/verify-certifications-migration.ts --dry-run
```

Expected: cero inscripciones sin versión, cero progresos huérfanos, cero versiones publicadas inválidas (contra la DB local/de test que se use; NO contra Neon).

**Commit documental (repo raíz):**

```bash
git add docs && git commit -m "docs(certifications): document configurable certification workflow"
```

---

## Fase 8 — Regresión global

```bash
cd sacdia-backend && npm test && npx tsc --noEmit && npx prisma validate
cd sacdia-app && flutter test test/features/certifications && flutter analyze lib/features/certifications
cd sacdia-admin && <runner completo del área> && npm run typecheck
```

Expected: todo verde (fallos preexistentes del baseline de Fase 0 se reportan, no se arreglan). Guardar resúmenes (N passed / N failed) para el reporte. NO ejecutar builds.

---

## Fase 9 — Reporte final (obligatorio)

### Task 9.1: Generar reporte

**Create:** `docs/reports/2026-08-11-implementacion-certificaciones-configurables.md` (repo raíz)

Estructura exacta:

```markdown
# Reporte de implementación — motor de certificaciones configurables

**Fecha:** <fecha>
**Branches:** <branch por repo, con conteo de commits>
**Planes seguidos:** docs/plans/2026-08-05-configurable-certifications-engine-implementation-plan.md + docs/plans/2026-08-11-certificaciones-configurables-plan-ejecucion.md

## 1. Resumen ejecutivo
<3-5 líneas: qué se implementó, qué quedó pendiente>

## 2. Tareas del plan
| Fase/Tarea | Estado (completa/parcial/omitida) | Commit(s) | Notas |
|---|---|---|---|
<una fila por Task 0.1 y Tasks 1–14 del plan base + 9.1>

## 3. Desviaciones del plan
<toda diferencia entre lo que los planes decían y lo que se hizo, con motivo.
Incluir supuestos que resultaron incorrectos (layout de seeds, scripts de
package.json, nombres de campos, guards, ubicación de componentes)>

## 4. Tests
| Repo | Comando | Resultado (passed/failed) |
|---|---|---|
<baseline de Fase 0 y regresión de Fase 8; pegar resúmenes>

## 5. Archivos modificados/creados
<lista por repo, con una línea de propósito por archivo>

## 6. Decisiones tomadas durante la ejecución
<decisiones no cubiertas por los planes, con justificación>

## 7. Pendientes y riesgos
<mínimo esperado:
- migración configurable_certifications_engine versionada pero NO aplicada a Neon
- seed del PDF NO ejecutado contra Neon
- endpoints legacy deprecated pero activos (fecha de retiro pendiente)
- certification_module_progress como proyección, eliminación en migración futura
- honores del seed no encontrados en catálogo, si aplica
- cualquier fallo preexistente del baseline>

## 8. Verificación manual sugerida
<pasos concretos para que un humano valide en dev: aplicar migración,
correr seed, cursar como participante elegible, revisar como institucional,
cerrar con comprobante de junta, configurar una versión en admin>
```

**Commit (repo raíz):**

```bash
git add docs/reports && git commit -m "docs: implementation report for configurable certifications engine"
```

---

## Criterios de aceptación finales (del plan base)

- Solo un usuario que cumple la regla configurable de Guía Mayor investido puede inscribirse y cursar como participante.
- La certificación del PDF existe como datos configurados, no como código especial.
- Cada requisito conserva respuestas, evidencias, estado e historial de revisión propios; se envía y revisa individualmente.
- Evidencias y comprobante de junta aceptan imagen/PDF con almacenamiento privado y URLs firmadas post-autorización.
- Un revisor solo ve y decide expedientes dentro de su permiso y scope.
- Ningún cierre ocurre sin requisitos obligatorios aprobados y comprobante de junta aprobado.
- Las versiones publicadas no cambian durante una inscripción activa; reinscribirse no hereda progreso.
- App, admin, API y documentación usan el mismo contrato.
- Tests dirigidos, e2e, prisma validate, typecheck y analyze pasan sin ejecutar builds.

## Fuera de alcance (NO hacer)

- OCR o validación automática del contenido de documentos.
- Firma digital criptográfica de la junta.
- Sincronización offline de envíos y revisiones; solo borradores locales.
- Generador visual arbitrario de formularios fuera de los tipos de componente definidos.
- Unificar certificaciones con clases progresivas, honores, `evidence-review` o carpeta anual.
- Aplicar migraciones o seeds contra Neon (development, staging o production).
- Eliminar `certification_module_progress`, columnas legacy o los 7 endpoints actuales.
- Ejecutar builds de cualquiera de los tres proyectos.
