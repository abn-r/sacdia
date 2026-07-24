# Production Readiness Remediation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Corregir los P0 de datos y contratos, completar la configuración anual de ACV y certificar un piloto administrativo E2E con Conquistadores ACV.

**Architecture:** Ejecutar datos y código en un orden seguro: baseline/attestation → saneamiento de development → migraciones aditivas → backend canónico → consumidores admin/app → configuración anual → piloto en clon → verificación en staging. Cada cambio de comportamiento sigue TDD; cada modificación de datos usa preflight, backup, verificación y salida segura.

**Tech Stack:** PostgreSQL 17, Prisma, NestJS/Jest, Next.js/Vitest, Flutter y scripts TypeScript con `tsx`.

---

## Reglas de ejecución y entrega

- Usar ramas/worktrees separados por repositorio; no mezclar cambios ajenos.
- No usar `sacdia-backend/prisma/seed.ts`.
- No ejecutar builds durante implementación normal. El build Android release es un gate posterior y requiere autorización explícita.
- Backend y documentación API se entregan antes de admin/app.
- PRs encadenados: backend datos/schema → backend contratos → app → admin → piloto/docs.
- Nunca aplicar datos sin `dry-run`, attestation vigente, backup restaurable y ventana de mantenimiento.
- El SQL baseline de 2026-07-17 no se sobrescribe; cada postflight genera un archivo fechado nuevo.

## Task 0: Cerrar inputs funcionales y roster

**Files:**
- Create: `docs/audit/manifests/annual-2026-acv.schema.json`
- Create: `docs/audit/manifests/pilot-role-roster.schema.json`
- Create before scoped approval: `docs/audit/manifests/annual-2026-acv.proposal.json`
- Create before scoped approval: `docs/audit/manifests/pilot-role-roster.proposal.json`
- Create after owner approval: `docs/audit/manifests/annual-2026-acv.json`
- Create after owner approval: `docs/audit/manifests/pilot-role-roster.json`

**Steps:**

1. Definir schema anual obligatorio:
   - `year_id=1`, `owner_scope=local_field`, `owner_id=4`;
   - ranking GM con máximo, ejes, componentes y pesos;
   - plantillas AV/CQ/GM con secciones funcionales, puntos, `minimum_points` equivalente al 80% y `closing_date=2026-12-15`;
   - normalización de la plantilla CQ existente, eliminando placeholders y conservando su `folder_template_id`;
   - `approved_by`, rol, fecha y checksum.
2. Definir roster obligatorio:
   - director real de Aventureros ACV;
   - secretario y tesorero reales de Conquistadores ACV; las cuentas Test no desbloquean el piloto ni la capacitación;
   - cuentas scoped de Unión, Campo Local, director, secretario, tesorero y member.
   - las cuentas genéricas de Unión y Campo Local se aceptan exclusivamente para E2E territorial en development, con usuario activo, aprobado, acceso al panel y scope efectivo; no sustituyen cargos operativos ni se promueven a production.
3. Unión firma valores de ranking; Campo Local firma plantillas/fechas; ACV firma roster.
4. Validar JSON contra schema.
5. Bloquear Tasks 8 y 10 hasta recibir ambos archivos completos. El implementador no elige valores ni personas.

## Task 1: Crear baseline, backup y attestation de remediación

**Files:**
- Create: `sacdia-backend/scripts/manifests/production-readiness-development-2026-07-17.json`
- Create: `sacdia-backend/scripts/remediate-production-readiness.ts`
- Create: `sacdia-backend/scripts/remediate-production-readiness.spec.ts`
- Reference: `docs/audit/sql/development-database-readiness-2026-07-17.sql`

**Manifest técnico exacto:**

- Cadena ACV: division `1`, country `25`, union `20`, local field `4`, old district `20`, target district `17`, church `1`, club `1`.
- Assignments a cerrar:
  - `317367b1-a2ea-4d9d-896c-8ef156c8cac5`;
  - `2764cf15-09a3-4c51-94f6-b8567c14f4b6`;
  - `046861d5-d2cc-4f2f-875b-672841a47d76`;
  - `b05ce76c-2005-464d-ade7-4757a0e6cbb1`.
- Titulares: Carlos `a0000001-0000-4000-8000-000000000001`, Ana `a0000001-0000-4000-8000-000000000003`, Pedro `a0000001-0000-4000-8000-000000000004`, Abner `104a2549-2056-4b9b-aaeb-51d8fd43191d`.
- Assignments Test no duplicados que deben sustituirse al aplicar el roster CQ: secretary `5d9c8962-8891-4842-abf2-a062ee57cdf2` y treasurer `d28d1499-0efb-4d30-8e74-ec49e0a169ee`.
- Annual enrollments: GM `75c538e1-fa18-4dc7-bfa5-b08f62d4dbf7`, CQ `621ea0d0-4779-4a06-98eb-25e13b1af398`.
- Matrículas: `100-105`, `108-113`, `116-121`, `124-127`.
- Secciones Estella: `163`, `164`, `165`.
- Honores: 637 entradas explícitas `{honor_id,code,expected_hct:1,expected_legacy:2,target_hct:2,target_legacy:2}` y Bioseguridad `{honor_id:649,code:'LEGACY-649',expected_hct:3,expected_legacy:2,target_hct:3,target_legacy:3}`.

**Steps:**

1. Escribir tests fallidos para entorno incorrecto, manifest parcial, fila divergente, attestation vencida y backup no restaurable.
2. Implementar modos `dry-run|apply|verify|rollback-clone|compensate`.
3. Calcular fingerprint por fase con host/database hasheado, schema, año y lista ordenada `migration_name+checksum+finished_at`; no fijar siempre “138” porque el plan agrega migraciones.
4. `dry-run` crea bajo la ruta absoluta externa exigida en `SACDIA_REMEDIATION_ARTIFACT_DIR/<run_id>/`:
   - `backup.json.enc` modo 0600, cifrado AES-256-GCM con clave base64 de 32 bytes desde `REMEDIATION_BACKUP_KEY` del secret manager;
   - `backup.sha256`;
   - `attestation.json` sin firma con `run_id`, fingerprint, manifest SHA, backup SHA, actor y expiración.
5. Un aprobador distinto ejecuta `--mode approve --attestation <path>` con `REMEDIATION_APPROVAL_KEY` desde el secret manager; el comando crea `approval.json` con identidad del aprobador y HMAC-SHA256. El proceso de dry-run no recibe esa clave.
6. `apply` verifica HMAC, hashes, separación actor/aprobador, expiración, advisory lock y fingerprint dentro de transacción serializable; conocer la clave de backup no permite autorizar apply.
7. Backup incluye filas completas, IDs HCT, `active`, timestamps e historial.
8. Implementar `--mode restore-backup --backup <path> --approval <path> --target-url-env DATABASE_URL_PILOT_CLONE`; solo acepta un clon y verifica auth tag, SHA y conteos restaurados.
9. Ejecutar `pnpm exec jest scripts/remediate-production-readiness.spec.ts --runInBand`.
10. Ensayar ciclo completo y restore en clon. Después ejecutar un nuevo `dry-run` READ ONLY contra el development objetivo, obtener aprobación separada y aplicar únicamente esa attestation.

## Task 2: Sanear jerarquía, cargos, matrículas y Estella

**Files:**
- Modify: `sacdia-backend/scripts/remediate-production-readiness.ts`
- Modify: `sacdia-backend/scripts/remediate-production-readiness.spec.ts`
- Reference: `docs/audit/sql/development-database-readiness-2026-07-17.sql`
- Create: `docs/audit/sql/development-database-readiness-postflight-<timestamp>.sql`

**Steps:**

1. Escribir tests fallidos que aborten si cualquier fila objetivo difiere o si cambia una columna no aprobada.
2. ACV:
   - cerrar historia abierta id `1`;
   - actualizar `clubs.districlub_type_id=17` y `modified_at=cutover`;
   - insertar historia exacta con cadena aprobada y actor técnico.
3. Directiva:
   - GM enrollment queda Carlos/Ana/Pedro;
   - CQ enrollment cambia solo director a Abner;
   - cerrar exactamente los cuatro assignments duplicados con `active=false`, `status='ended'`, `end_date=cutover`, `modified_at=cutover`.
4. Aplicar el roster CQ dentro de la misma transacción: crear/activar assignments de secretario y tesorero reales, cerrar los assignments Test `5d9c8962-8891-4842-abf2-a062ee57cdf2` y `d28d1499-0efb-4d30-8e74-ec49e0a169ee`, y sincronizar `club_enrollments.secretary_id/treasurer_id`. Abortar si el roster no está firmado.
5. Matrículas: poner `active=false`, `modified_at=cutover` en los 22 IDs; no tocar `class_id`, progreso ni historia.
6. Estella: desactivar secciones `163-165` y actualizar `modified_at`; no crear inscripciones ficticias.
7. Postcommit: reinicio controlado del backend para invalidar caches de autorización/jerarquía; verificar `/auth/me` de usuarios afectados.
8. `verify` ejecuta:
   - semántica exacta del trigger: todo `active=true` por sección+rol;
   - semántica del año vigente;
   - una historia abierta coherente;
   - cero matrícula activa en clase inactiva;
   - Estella sin secciones activas.
9. En clon probar `apply → verify → rollback-clone → verify-baseline → apply → verify`.
10. En entorno operativo, `compensate` conserva historia y nunca reactiva las 22 matrículas. Si `current_date <= valid_from` de la historia abierta, falla explícitamente con `INTRADAY_HISTORY_COMPENSATION_UNSUPPORTED`, mantiene NO-GO y exige ejecutar la compensación en una fecha posterior.

## Task 3: Migrar y remediar aplicabilidad de honores

**Files:**
- Create: `sacdia-backend/prisma/migrations/<timestamp>_honor_enrollment_club_type_snapshot/migration.sql`
- Modify: `sacdia-backend/prisma/schema.prisma`
- Modify: `sacdia-backend/src/honors/honors.service.ts`
- Modify: `sacdia-backend/src/honors/honor-validation-workflow.service.ts`
- Modify: `sacdia-backend/src/analytics/local-field-dashboard.service.ts`
- Modify: `sacdia-backend/src/admin/admin-phase-e-catalogs.service.ts`
- Modify: `sacdia-backend/src/admin/dto/phase-e-catalogs.dto.ts`
- Test: specs correspondientes, incluido `adventurer-specialties-importer.spec.ts`

**Schema y rollout:**

1. Añadir `users_honors.enrollment_club_type_id INT NULL`, FK a `club_types` e índice.
2. Mantener nullable durante un release. Nuevos start/create/bulk/reactivate lo fijan.
3. Históricos NULL usan fallback legacy documentado; no hacer backfill por asignación actual sin entrada explícita en manifest.
4. Ventana de mantenimiento: bloquear escrituras del catálogo.
5. Ejecutar dry-run/backup y aplicar primero la corrección de datos:
   - 637 HCT tipo 1→2;
   - Bioseguridad conserva HCT 3 y cambia legacy 2→3.
6. Postflight exacto: 175 Aventureros, 692 Conquistadores, 1 Guías Mayores, cero divergencias y 17 progresos con status intacto.
7. Solo entonces desplegar backend canónico/dual-write y reabrir escrituras.

**Public contract:**

- GET de catálogo/detalle/user honors/admin incluye `applicable_club_types` ordenado y solo activo.
- Create/update acepta `applicable_club_type_ids: number[]`.
- Compatibilidad:
  - create requiere array o legacy; legacy-only produce singleton;
  - update sin array preserva HCT;
  - update legacy-only reemplaza por singleton;
  - ambos campos contradictorios devuelven 400;
  - array vacío, duplicado o tipo inactivo/inexistente devuelve error estable;
  - proyección legacy conserva valor si pertenece a la lista; si no, usa el menor ID.
- Política efectiva: A→`[1]`, C→`[2]`, GM→`[2,3]`.
- Aplicabilidad se valida al iniciar/reactivar; submit/approve no invalida retroactivamente progreso.
- Eventos y analítica usan snapshot; fallback legacy solo para históricos NULL.

**Tests:**

1. RED para filtros A/C/GM, detalle, start/create/bulk/reactivate, admin atómico y analytics.
2. RED para omisión vs reemplazo, compat legacy, conflicto de campos y tipos inválidos.
3. Implementar `HonorApplicabilityPolicy` compartida.
4. Ejecutar Jest focalizado y migración en clon; no build.
5. Actualizar schema espejo, `docs/features/honores.md`, API live reference y guía frontend.

## Task 4A: Alinear admin de honores

**Files:**
- Modify: `sacdia-admin/src/lib/api/admin-honors-catalog.ts`
- Modify: `sacdia-admin/src/lib/catalogs/honors/{types,schema,actions}.ts`
- Modify: `sacdia-admin/src/components/catalogs/honors/honor-form-dialog.tsx`
- Test: tests Vitest junto a schema/actions/dialog

**Steps:**

1. Escribir RED para lista, hidratación, omisión/reemplazo, array vacío y error 400.
2. Sustituir selector único por multiselección.
3. No exponer legacy como decisión de negocio.
4. Ejecutar `pnpm test -- <tests>` y `pnpm typecheck`; no build.

## Task 4B: Alinear app de honores

**Files:**
- Modify: `sacdia-app/lib/features/honors/data/models/honor_model.dart`
- Modify: `sacdia-app/lib/features/honors/data/models/honor_group_model.dart`
- Modify: `sacdia-app/lib/features/honors/data/datasources/honors_remote_data_source.dart`
- Modify: repositorio/providers de honors
- Test: `honors_remote_data_source_test.dart` y `honor_catalog_scope_filter_test.dart`

**Steps:**

1. Escribir RED para parsear `applicable_club_types`, enviar `clubTypeId` y no refiltrar por legacy.
2. Con sección activa, catálogo e inicio usan el mismo scope.
3. Sin sección activa, catálogo es solo lectura y CTA “iniciar” queda deshabilitado hasta seleccionar sección.
4. Ejecutar Flutter tests focalizados y `flutter analyze`; no build.

## Task 5: Hacer aprobación anual scoped, atómica y durable

**Files:**
- Create: migración Prisma para review fields y notification outbox
- Modify: `sacdia-backend/prisma/schema.prisma`
- Modify: `sacdia-backend/src/club-enrollments/club-enrollment-validation.controller.ts`
- Modify: `sacdia-backend/src/club-enrollments/club-enrollments.service.ts`
- Modify: `sacdia-backend/src/audit-logs/audit-logs.service.ts`
- Create: `RejectClubEnrollmentDto`
- Test: specs controller/service/outbox worker

**Schema:**

- `club_enrollments.reviewed_by UUID NULL`, `reviewed_at TIMESTAMPTZ NULL`, `rejection_reason VARCHAR(500) NULL`.
- `notification_outbox`: UUID, aggregate type/id, event type, JSON payload, unique idempotency key, status, attempts, next attempt, created/processed timestamps.

**Behavior:**

1. Controller pasa `authorizationProfile` a approve/reject.
2. Servicio carga sección→club→Campo→Unión y autoriza: super-admin global, Unión subordinada, Campo propio; fuera de scope devuelve 403.
3. Reject exige `reason` trim 1..500.
4. Resubmit desde rejected limpia review fields/reason y vuelve a pending.
5. Approve preflight exige plantilla publicada/configuración efectiva; si falta devuelve 409 y no cambia estado.
6. Approve crea estado active + review fields + audit + outbox + carpeta dentro de una transacción. Extender helpers de AuditLogs/AnnualFolders para aceptar `Prisma.TransactionClient`; no tragar errores transaccionales.
7. Audit usa `entity_type='club_enrollment'`, entity id, `action='UPDATED'`, actor, club y changes from/to.
8. Outbox notifica director/secretario/tesorero con idempotency key `club-enrollment:<id>:<status>:<reviewed_at>`; worker reintenta exponencialmente hasta 8 intentos, cap 24h.
9. Approve de active es 200 no-op sin nuevos side effects. Reject de cualquier estado no-pending es 409.
10. Tests cubren template ausente, folder failure, fuera de scope, doble approve, reject duplicado, audit/outbox exactly-once y worker retry.

## Task 6: Corregir contrato móvil de inscripción anual

**Files:**
- Modify: `sacdia-app/lib/features/enrollment/data/datasources/enrollment_remote_data_source.dart`
- Modify: `sacdia-app/lib/features/enrollment/data/models/enrollment_model.dart`
- Test: `enrollment_model_test.dart`
- Create: `enrollment_remote_data_source_test.dart`

**Steps:**

1. RED para payload `meeting_schedule: [{day,time}]`, `latitude`, `longitude` y Decimal.
2. Corregir serialización sin doble JSON y lectura de UUID.
3. Leer año desde `ecclesiastical_year_id`/objeto canónico, no solo `year` plano.
4. Aceptar `fee_amount` string o número sin convertirlo en null.
5. Cubrir nulos, múltiples días y response completo.
6. Ejecutar Flutter tests y analyze; no build.

## Task 7: Crear cola admin anual independiente

**Files:**
- Create: `sacdia-admin/src/app/(dashboard)/dashboard/annual-enrollments/page.tsx`
- Create: `sacdia-admin/src/components/annual-enrollments/annual-enrollments-table.tsx`
- Modify: `sacdia-admin/src/lib/api/club-enrollments.ts`
- Modify: sidebar/i18n/permisos
- Test: API/componente Vitest

**Steps:**

1. No modificar `/dashboard/enrollments`; continúa siendo investiduras.
2. RED para UUID, estados anuales, filtros, scope, approve, reject con razón y error 403.
3. Implementar tabla, búsqueda, año/tipo/estado, detalle y confirmaciones.
4. Mostrar reviewer/date/reason; refrescar tras transición.
5. Ocultar acciones sin permiso, manteniendo backend como autoridad.
6. Ejecutar Vitest y typecheck; no build.

## Task 8: Completar configuración anual de ACV

**Prerequisite:** Task 0 aprobada; sin valores firmados esta tarea no inicia.

**Steps:**

1. Unión/super-admin crea ranking GM scoped a Campo Local ACV.
2. Campo Local crea plantillas DRAFT AV/GM con valores exactos del manifest.
3. Validar suma de ejes/componentes y correspondencia con `annual_evidence_folder.max_points`.
4. Publicar plantillas y verificar resolver efectivo Unión→Campo.
5. Completar `closing_date` CQ dentro de 2026.
6. Crear carpeta GM manualmente porque su enrollment ya está active.
7. Asignar director AV real, crear inscripción desde app, aprobar desde admin y comprobar folder atómico.
8. Postflight: una plantilla efectiva por tipo/año/scope, AV/CQ/GM coherentes y Estella sin secciones activas.

## Task 9: Cerrar Android release y reportes

**Files:**
- Modify: `sacdia-app/.github/workflows/ci.yml`
- Modify: `sacdia-app/lib/core/constants/app_constants.dart`
- Test/Fix if reproduced: contrato mensual admin/backend

**Steps:**

1. Test/guard falla si release resuelve localhost, secret vacío o URL no HTTPS.
2. CI inyecta `--dart-define=API_BASE_URL=...`; no hardcodear secreto/URL.
3. Ejecutar smoke de reportes antes del E2E. Si pasa, no cambiar; si falla, escribir RED y corregir UUID/payload.
4. Actualizar deployment guide.
5. Gate separado: solicitar autorización, construir release y probarlo contra piloto. Sin build/smoke autorizado, estado permanece NO-GO.

## Task 10: Ejecutar piloto E2E en clon y staging

**Files:**
- Create: `sacdia-backend/scripts/create-pilot-clone.sh`
- Create: `sacdia-backend/scripts/prepare-conquerors-acv-pilot.ts`
- Create: `sacdia-backend/test/production-readiness-pilot.e2e-spec.ts`
- Create: `sacdia-admin/scripts/e2e-production-readiness-pilot.mjs`
- Create: reporte postflight fechado nuevo bajo `docs/audit/`

**Clone/fixture:**

1. Infra entrega `DATABASE_URL_PILOT_CLONE`, owner y TTL.
2. Script rechaza mismo host/database, producción o destino no vacío.
3. `pg_dump --format=custom` development y `pg_restore` al clone; guardar hashes.
4. Fixture captura enrollment CQ, folder y children; elimina folder (cascade evidences/evaluations/submissions), pone enrollment rejected y review metadata controlada. No borra archivos R2.
5. Fixture es idempotente y solo funciona con fingerprint/clone guard.

**E2E:**

1. Cuentas scoped activas. Las identidades genéricas se limitan a E2E en development y no se reutilizan en production.
2. Login/scope → corregir/resubmit → cola admin → approve → folder 4,000 → evidencia → actividad/asistencia → ingreso/egreso → inventario → reporte → ranking.
3. Verificar historial del club, audit event, outbox, notification log/delivery/inbox y cola sin dead letters.
4. Negativos:
   - LF propio permite; LF externo 403 esperado;
   - Unión solo subordinados;
   - member/treasurer/director de club no aprueban;
   - actor fuera de scope no ve ACV;
   - honor no aplicable no inicia.
5. No aceptar 5xx, 403 inesperado, folder ausente ni puntos divergentes.
6. Exportar evidencia, destruir clone por TTL y repetir SQL read-only en staging/ambiente objetivo.
7. Solo después emitir GO/NO-GO para capacitación administrativa.

## Criterios finales

- Cadena exacta: DIA 1 → México 25 → UMI 20 → Campo 4 → Veracruz 17 → Díaz Aragón 1 → ACV 1.
- Cero slot violations bajo trigger y regla anual.
- GM enrollment refleja Carlos/Ana/Pedro; CQ director es Abner; el roster operativo usa personas nominales y reserva las cuentas genéricas para E2E territorial en development.
- Cero matrículas activas en clases inactivas; 22 IDs permanecen auditables.
- Honores: 175 AV, 692 CQ, 1 GM; 17 progresos sin cambio de status.
- Catálogo/inicio/validación comparten HCT canónico.
- App/backend comparten payload anual.
- Approve/reject valida scope y persiste review, audit, outbox y folder atómico.
- ACV AV/CQ/GM completa ciclo anual; Estella queda inactiva.
- Reportes pasan smoke.
- CI bloquea release sin API HTTPS; certificación del binario requiere build autorizado.
- E2E pasa en clon y verificaciones read-only pasan en staging.

## Rollback y compensación

- `rollback-clone` puede borrar la historia nueva y reabrir baseline únicamente en clon descartable.
- `compensate` operativo preserva historia, crea transición posterior y marca NO-GO.
- Nunca reactivar las 22 matrículas mientras clase 14 esté inactiva.
- Rollback HCT exige hash y estado post-apply exactos para no pisar escrituras posteriores.
- Schema se revierte con migración compensatoria, nunca editando historial Prisma.
- Si falla cualquier postflight, detener rollout; no desplegar consumidores sobre datos no saneados.
