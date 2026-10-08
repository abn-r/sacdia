# Investidura por autorización — Fase 8: apagar la vía vieja (Plan 3)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Que ningún enrollment pueda volver a moverse por la vía club → coordinación → campo (ni por `ValidationModule` con `entity_type` `class`), sin perder historia, sin resolver expedientes en silencio y con una operación explícita y auditable para soltar los bloqueos viejos.

**Architecture:** El backend deja registradas las 17 rutas de la vía vieja en un controlador propio que responde HTTP 410 con el código nuevo `INVESTITURE_LEGACY_PIPELINE_RETIRED`; después se borra el código muerto del servicio. `ValidationModule` responde 410 a `class` y deja honores y evidencias como están. Un endpoint de `super-admin` con `dry_run` por defecto suelta `locked_for_validation` y deja una fila `LEGACY_LOCK_RELEASED` en `investiture_validation_history`. El panel y la app quitan pantallas, rutas, textos y pruebas de esa vía. Todo va en PRs encadenados por repo.

**Tech Stack:** NestJS 11, Prisma 7.9, Jest, PostgreSQL 18 (e2e aislada); Next.js 16 + next-intl + vitest; Flutter + Riverpod + easy_localization + flutter_test.

**Depende de:** Plan 0 (`2026-10-08-investidura-ui-0-backend-soporte.md`), Plan 1 (`…-ui-1-panel.md`) y Plan 2 (`…-ui-2-app.md`). Ramas base, todas sin mergear:

| Repo | Worktree de referencia | Rama base de este plan |
| --- | --- | --- |
| Backend | `/private/tmp/sacdia-plan0` | `feat/investiture-ui-backend-support` |
| Panel | `/private/tmp/sacdia-admin-ui` | `feat/investiture-authorization-screens` |
| App | `/private/tmp/sacdia-app-ui` | `feat/investiture-authorization-app` |
| Docs | `/private/tmp/sacdia-root-docs` | `docs/investiture-ui-plans` |

Spec: `docs/plans/2026-09-28-investidura-autorizacion.md` §«Fase 8» y el inventario de `docs/features/validacion-investiduras.md` §«Preparación de fase 8».

---

## Decisiones de este plan

Las decisiones 1 a 11 del usuario no se reabren. Esta tabla fija lo que el usuario dejó para decidir aquí.

| # | Decisión | Por qué |
| --- | --- | --- |
| 1a | Las 11 escrituras de la vía vieja responden **HTTP 410** con `INVESTITURE_LEGACY_PIPELINE_RETIRED` (mensaje en `es`, `en`, `fr`, `pt-BR`). Las rutas siguen registradas en `LegacyInvestitureRetiredController`. | Las versiones viejas de la app en las tiendas siguen llamando `submit-for-validation`, `validate` e `investiture/pending`. Con 404 verían un error genérico de Nest. Con 410, el filtro traduce el mensaje y la app vieja lo muestra en su `SnackBar`. Ya hay un precedente: `CERT_LEGACY_ENDPOINT_DEPRECATED` con `HttpStatus.GONE` en `certifications.service.ts:455-459`. Las rutas retiradas no exigen permisos ni roles (`@SkipPermissions()`, solo el JWT global): un 403 daría a entender que la vía sigue viva para otro rol, y los permisos que exigían quedan inertes (ver 11a). Los handlers no reciben `@Body` ni `ParseIntPipe`, así que ningún 400 de validación tapa el 410. |
| 1b | `GET /investiture/pending` también responde **410**. Las dos lecturas de historial (`GET /investiture/enrollments/:id/history` y `GET /enrollments/:id/investiture-history`) siguen igual. | Sus únicos consumidores se borran: `/dashboard/investiture`, `/dashboard/enrollments` (ver H1), la cola de la app y el «pipeline». Una cola de «pendientes de aprobación» que nadie puede aprobar confunde. La lista operativa de los expedientes trabados la da el `dry_run` del desbloqueo (5a), que además dice cuáles tienen `PENDING`. |
| 2 | `POST /validation/submit` y `POST /validation/:entityType/:entityId/review` responden 410 cuando `entityType` es `class`. `GET /validation/pending` devuelve `classes: []` siempre y conserva la forma `{ classes, honors }`. Honores, `GET /validation/:entityType/:entityId/history`, `GET /validation/eligibility/:userId` y `/evidence-review` no cambian. | Una app vieja que lee `classes` no se rompe. La revisión de evidencias por sección alimenta `sectionMeetsThreshold`. **`ValidationController` conserva `@RequirePermissions('validation:submit')` y `('validation:review')`** (`validation.controller.ts:46` y `:80`) porque las mismas rutas siguen sirviendo a honores: un actor sin esos permisos recibe **403 antes** que el 410, y uno con ellos recibe 410 solo si `entityType` es `class`. A diferencia de las 17 rutas retiradas (`@SkipPermissions()`), este 403 es correcto: la ruta sigue viva para honores. |
| 3 | Las **cinco** rutas de `investiture_config` (dos lecturas y tres escrituras) responden 410. La tabla y sus filas se conservan. | `rg` sobre `src/` (sin `src/investiture/`), `scripts/` y `prisma/seeds/` no encuentra ningún lector fuera de `markInvestido` y `submitForValidation`, que también se retiran. La fecha que usaba ya quedó copiada en `enrollments.investiture_date`. |
| 4 | `POST /admin/classes/enrollments/expire-overdue` sigue. | Solo usa `findCurrentEcclesiasticalYear`, `countElapsedEcclesiasticalYears`, `EXPIRABLE_STATUSES` y `pendingInvestitureAuthorization`; ninguno se retira. La Task B2.1 lo deja fijo con una prueba de forma. |
| 5a | El desbloqueo es un **endpoint**: `POST /api/v1/admin/investiture/legacy-locks/release`, solo `super-admin` exacto (`ExactSuperAdminWritePolicy`), `dry_run: true` por defecto. Suelta `locked_for_validation` solo en filas `OPERATIONAL` que no están `INVESTIDO` y no tienen persona `PENDING`. No cambia `investiture_status` ni `submitted_for_validation`. Cada fila liberada deja una fila `LEGACY_LOCK_RELEASED` en `investiture_validation_history` con `performed_by` = quien ejecuta. Nuevo valor de `investiture_action_enum` en una migración propia. | Frente a un script: (1) deja el actor real en la historia de esa vía y en `audit_logs` (`HttpAuditInterceptor` global), (2) toma el mismo candado advisory `investiture-authorization-enrollment:` que presentar y resolver, en la misma transacción, así que corre con la app viva sin carreras, (3) no exige credenciales de base en una laptop ni conectarse a Neon a mano, (4) sigue el patrón ya probado de `expire-overdue` con `dry_run`. Es idempotente: una segunda corrida no encuentra filas bloqueadas que soltar y no escribe historia. No es una migración automática. **Criterio de candidatos (regla del usuario):** cualquier fila `OPERATIONAL` con `locked_for_validation = true`, `investiture_status <> 'INVESTIDO'` y sin persona `PENDING`, **sin filtro por `active`** ni por estado de la cadena: una fila inactiva también se suelta (el candado es residuo de la vía vieja, no una regla vigente). Queda fijado en `CANDIDATE_WHERE` (B3.2) y en su prueba. |
| 5b | `HISTORICAL_CERTIFICATE` nunca entra al desbloqueo. | Siempre nace `INVESTIDO` con `locked_for_validation = true` (`certificate-bulk-imports-application.service.ts:510-640`); el filtro `record_kind = 'OPERATIONAL'` lo deja explícito. |
| 6 | Los lectores que cuentan `APPROVED` como completada **siguen contándolo**: `class-investiture-progress-score.ts:34` y `validation.service.ts` (`checkInvestmentEligibility`). `clubs.service.ts` (`investidos_year`) pasa a contar `APPROVED` **o** `INVESTIDO`, solo filas `OPERATIONAL` (un certificado histórico `INVESTIDO` del año activo no cuenta como investidura del club). | Las filas `APPROVED` se conservan y ya no se escriben nuevas, así que el conteo histórico no cambia. `investidos_year` hoy cuenta solo `APPROVED` (no `INVESTIDO`): con la vía vieja apagada quedaría congelado y nunca vería una investidura nueva (ver H2). `club-role-eligibility.service.ts` (elegibilidad GM-01) **tampoco cambia**: `ACTIVE_GUIDE_MAJOR_STATUSES` (L13-19) sigue contando `IN_PROGRESS` y los cuatro estados de cadena como `ACTIVE_ENROLLMENT`, y `evaluateMany` (L108-136) sigue contando `INVESTIDO` y `APPROVED` como base `INVESTED` / `APPROVED`; B4.2 lo fija con una prueba. `class-counselor-assignments.service.ts:38` ya no contiene `APPROVED` (el inventario está desactualizado; ver H3). |
| 9a | **Panel:** se borran `/dashboard/investiture`, `/pipeline`, `/config`, **`/dashboard/enrollments`** (H1) y la pestaña «Módulos» de `/dashboard/clubs/validations`. `?tab=modules` cae en «Secciones de clase». El atajo de operaciones «Inscripciones» se quita y la cola «classes» apunta a `?tab=sections`. | `/dashboard/enrollments` solo lista `GET /investiture/pending` y aprueba con `POST /enrollments/:id/validate`. La cola «classes» cuenta `class_section_progress` (evidencias), no la cola de módulos. |
| 9b | **App:** se borra todo `lib/features/investiture/` salvo `domain/entities/investiture_status.dart` (lo usan miembros, rankings y la tarjeta propia). La ruta de historial viejo `/investiture/enrollment/:id/history` **se retira sin reemplazo en pantalla**; el historial nuevo (`/investiture/mine` y el de la sección) cubre lo que nace en `investiture_requests`. La tarjeta legada de `98414d7d` se quita y queda solo una insignia «Investido» cuando el enrollment está `INVESTIDO` y no hay entrada del flujo nuevo. | Producción tiene 0 enrollments (conteo del 2026-10-08), así que ninguna persona real tiene historial viejo; la API lo sigue leyendo. La insignia hace falta porque la tarjeta legada era lo único que mostraba «Investido» en el detalle de clase para una acreditación por certificado (`HISTORICAL_CERTIFICATE`), que no aparece en `GET /investiture-history`. |
| 9c | El screen catalog de la app y `test/fixtures/screen-catalog.snapshot.json` **no cambian**. | Las pantallas que se borran son solo `surfaces: ["admin"]` y `dumpAppCatalog()` solo serializa pantallas de la app; la app nunca tuvo una pantalla de catálogo para la vía vieja. La paridad se verifica igual (Task A3.4). |
| 11a | Los permisos `investiture:submit`, `investiture:validate`, `investiture:mark_invested` e `investiture_config:*` **se conservan** en `prisma/seeds/*.sql` y en la base. `investiture:read` sigue en uso (historial). | Ninguna ruta los exige después de este plan, así que no otorgan nada. Quitarlos exige una migración de datos en Neon (fuera de alcance) y borraría asignaciones históricas que ve la matriz RBAC. Se documentan como inertes; una limpieza posterior necesita su propia aprobación. |
| 11b | El escáner AST de asignaciones cambia: `investiture/investiture.service.ts` 7 → 2 y `validation/validation.service.ts` 3 → 1 (total 154 → 147; T08 57 → 52; T09 58 → 56). **Actualizar `club-assignment-effectivity.inventory.ts` y su spec necesita aprobación explícita del usuario** (Task B2.5). | Regla del inventario: no se reclasifica sin aprobación. |
| 11c | Notificaciones `investiture:submitted`, `validation:class_submitted`, `validation:class_approved` y `validation:class_rejected` dejan de emitirse. El SLA de analytics (`analytics.service.ts`) sigue leyendo `investiture_validation_history` y queda congelado en lo ya grabado. Crons, year-end, year-cut y reportes no dependen de la vía vieja. | Verificado con `rg`. |

### Decisiones posteriores (2026-10-08)

Cierran la antigua «Pregunta abierta» y lo que el orquestador fijó después de la revisión. No se reabren sin pedirlo.

| # | Quién | Decisión | Por qué |
| --- | --- | --- | --- |
| B5 | Usuario | Después del apagado, `enrollmentOnLegacyInvestiturePipeline` (`src/investiture-requests/investiture-request-lock.ts:129`) mira **solo** `locked_for_validation`. B5 deja de ser condicional: se ejecuta siempre, apilado sobre B4. Una fila liberada por el desbloqueo (5a) puede presentarse por la vía nueva y, si se autoriza, pasa a `INVESTIDO` desde su estado viejo. `LEGACY_INVESTITURE_PIPELINE_STATUSES` se borra (ningún otro lector la importa; `rg` lo confirma en `src` y `test`). | El desbloqueo no cambia el estado de la cadena. Sin B5, una fila liberada seguiría bloqueada hasta fin de año y el desbloqueo no serviría para volver a presentarla. |
| O1 | Orquestador | Las lecturas `GET /investiture/pending` y `GET /admin/investiture/config*` **también responden 410** (ya incluidas en las 17 rutas de 1a/1b/3). | Una app vieja que recibiera una lista de pendientes cuyas acciones fallan con 410 confunde más que un «función retirada» en la propia lectura. |
| O2 | Orquestador | `club-role-eligibility` **sigue contando `APPROVED` y los estados de cadena** igual que hoy (ver decisión 6). La historia se conserva; no se reinterpreta. | Una persona con un `APPROVED` o un expediente `CLUB_APPROVED` de Guía Mayor conserva su elegibilidad; quitarla sería una pérdida silenciosa. |
| O3 | Orquestador | **Todos los slices van con `size:exception`** (los borrados dominan el diff). Patrón aprobado: en el Review Workload Forecast cada slice dice «Decisión pendiente: ninguna; `size:exception` (patrón aprobado)». La única aprobación que sigue abierta es la del inventario del escáner (11b, Task B2.5), que no es de tamaño. | Evita preguntar por cada PR; la revisión de borrados se hace con `git diff --stat` + `--diff-filter=D`. |
| O4 | Orquestador | El mensaje del 410 llega a las apps viejas **en español**: la app no manda `Accept-Language` ni `?lang=` (`rg -i accept-language lib` solo encuentra las llamadas a Nominatim; el interceptor de red solo agrega `Authorization`), y el backend resuelve `?lang=` → `Accept-Language` → `es` (`app.module.ts:99-114`). **Se documenta, no se corrige.** | Cambiar el envío de idioma exige una versión nueva de la app y las instaladas no se actualizan. |
| O5 | Orquestador | Una app vieja que lea el historial de un enrollment liberado verá `LEGACY_LOCK_RELEASED` como **«Enviado para validación»**: `InvestitureAction.fromString` cae en `submitted` ante un valor desconocido (`investiture_history_entry.dart`, `default:`) y esa etiqueta es `investiture.history.action_submitted`. **Se documenta, no se corrige.** | Producción tiene 0 enrollments (conteo del 2026-10-08): ninguna persona real verá esa fila. Si hubiera entornos con datos, el comentario de la fila (`LEGACY_LOCK_RELEASE_COMMENT`) aclara el motivo. |

### Hallazgos que el inventario no tenía

- **H1.** `sacdia-admin/src/app/(dashboard)/dashboard/enrollments/page.tsx` + `src/components/enrollments/enrollments-table.tsx` + `src/lib/api/enrollments.ts` son otra cola de la vía vieja: `GET /investiture/pending` y `POST /enrollments/:id/validate`. Tiene entrada de sidebar («Inscripciones»), pantalla `enrollments` del catálogo y atajo en el inicio de operaciones.
- **H2.** `clubs.service.ts:1507` cuenta `investidos_year` con `investiture_status: 'APPROVED'`, no con `INVESTIDO`.
- **H3.** `class-counselor-assignments.service.ts:38` del inventario ya no cuenta `APPROVED`.
- **H4.** La app usa `extractInvestitureListFromResponse` del feature viejo desde `investiture_requests_remote_data_source.dart:6`; hay que moverla antes de borrar.
- **H5.** La app tiene una tarjeta «Investiduras» en `coordinator_hub_view.dart:139-146` y la ruta `/investiture/pending` en la lista permitida de push (`push_notification_service.dart:812`).
- **H6.** `ValidationEntityType.classProgress` de la app manda `class_progress`, que el backend ni acepta: código muerto.
- **H7.** X-1 (`enrollmentOnLegacyInvestiturePipeline`) bloquea por `locked_for_validation` **o** por estado de la cadena. Con el desbloqueo aprobado (estado sin cambios), una fila `CLUB_APPROVED` liberada seguía sin poder presentarse. Resuelto por la decisión B5 del usuario (tabla «Decisiones posteriores»).

## Reglas para quien ejecute

- TDD: prueba roja registrada antes de cada cambio. Lo que dependa de la base, también en PostgreSQL.
- **Backend.** Unitarias: `node node_modules/jest/bin/jest.js --no-coverage --forceExit <rutas>`. PostgreSQL descartable propio (nunca Neon):

```bash
export PATH=/opt/homebrew/opt/postgresql@18/bin:$PATH LC_ALL=C
SCRATCH=$(mktemp -d)
initdb -D "$SCRATCH/pg" -U postgres --auth=trust >/dev/null
echo "log_min_messages = warning" >> "$SCRATCH/pg/postgresql.conf"
pg_ctl -D "$SCRATCH/pg" -o "-p 55438" -l "$SCRATCH/pg.log" start
createdb -h localhost -p 55438 -U postgres sacdia_test
export SACDIA_TEST_DATABASE_URL=postgresql://postgres@localhost:55438/sacdia_test
export SACDIA_POSTGRES_SERVER_LOG="$SCRATCH/pg.log"
export RESEND_API_KEY=re_test_dummy
node node_modules/jest/bin/jest.js --config ./test/jest-e2e.json --no-coverage --forceExit --runInBand --testPathPatterns <suite>
# al terminar: pg_ctl -D "$SCRATCH/pg" stop
```

  Después de cada corrida PostgreSQL de una suite **que no verifica el log por sí misma** (las de certificados y evidencias): `rg -c "deadlock detected" "$SCRATCH/pg.log"` → sin coincidencias. La suite nueva `investiture-legacy-shutdown-postgres` lo verifica sola con `test/helpers/investiture-server-log.ts` (por eso exige `SACDIA_POSTGRES_SERVER_LOG`, ya exportado arriba). Tipos: `npx tsc --noEmit -p tsconfig.build.json`. Lint: `npx eslint --no-fix <archivos tocados>`. `pnpm exec prisma generate` solo regenera el cliente; no toca bases.
- **Panel.** `pnpm test <ruta>`, `pnpm lint`, `pnpm typecheck`. Al tocar `messages/*.json`: `node scripts/generate-messages-types.mjs`. Los `messages/*.json` del panel **no** llevan salto de línea final; los del backend y la app sí.
- **App.** `flutter test <ruta>`, `flutter analyze`.
- Sin builds, sin Neon, sin `git push` fuera de lo indicado. Commits por unidad de trabajo, Conventional Commits, sin atribuciones.
- Cada slice es un PR y todos llevan la etiqueta `size:exception` (decisión O3). Antes de abrir el siguiente, verificar el diff real (`git diff --stat`), no el reporte del subagente.
- CI: `ci.yml` (L276-289, «Run E2E tests (blocking suites)») corre solo un subconjunto de suites verificadas contra una base efímera con `DATABASE_URL`; ninguna suite de investidura está ahí y las de PostgreSQL necesitan `SACDIA_TEST_DATABASE_URL` y `SACDIA_POSTGRES_SERVER_LOG`, que el job no define. **Convención del repo: no se agregan.** La suite nueva y `test/investiture.e2e-spec.ts` se corren a mano con el clúster descartable de arriba; las unitarias nuevas (`src/**/*.spec.ts`) sí corren en CI con las demás.

## Archivos

### Backend (`sacdia-backend`)

| Archivo | Responsabilidad |
| --- | --- |
| `src/common/errors/error-codes.ts`, `src/i18n/{es,en,fr,pt-BR}/errors.json` | `INVESTITURE_LEGACY_PIPELINE_RETIRED` |
| `src/investiture/legacy-investiture-pipeline-retired.ts` (nuevo) | `throwLegacyInvestiturePipelineRetired()` y la tabla `RETIRED_LEGACY_INVESTITURE_ROUTES` |
| `src/investiture/legacy-investiture-retired.controller.ts` (nuevo) | Las 17 rutas que responden 410 |
| `src/investiture/investiture.controller.ts` | Queda: `expire-overdue`, los dos historiales y el desbloqueo |
| `src/investiture/investiture.service.ts` | Queda: `getHistory`, `expireOverdueEnrollments` y sus dos ayudantes |
| `src/investiture/dto/*` | Queda `expire-overdue-enrollments.dto.ts`; nuevo `release-legacy-locks.dto.ts` |
| `src/investiture/legacy-lock-release.service.ts` (nuevo) | Desbloqueo explícito |
| `src/investiture/investiture.module.ts` | Controladores y proveedores nuevos; quita módulos que ya no se usan |
| `src/validation/validation.service.ts` | 410 para `class`; borra la rama de clase |
| `src/investiture-requests/investiture-request-lock.ts` | B5: X-1 mira solo `locked_for_validation`; borra `LEGACY_INVESTITURE_PIPELINE_STATUSES` |
| `src/clubs/clubs.service.ts` | `investidos_year` cuenta `APPROVED` o `INVESTIDO` |
| `prisma/schema.prisma`, `prisma/migrations/20261009120000_investiture_legacy_lock_release_action/migration.sql` (nuevo) | Valor `LEGACY_LOCK_RELEASED` |
| `src/common/authorization/club-assignment-effectivity.inventory.ts` + `.spec.ts` | Solo con aprobación (11b) |
| `src/club-role-eligibility/club-role-eligibility.service.spec.ts` | B4.2: fija que `APPROVED` y los estados de cadena siguen contando |
| Specs y `test/investiture-legacy-shutdown-postgres.e2e-spec.ts` (nuevo, usa `test/helpers/investiture-server-log.ts`) | Pruebas |

### Panel (`sacdia-admin`)

| Archivo | Cambio |
| --- | --- |
| `src/app/(dashboard)/dashboard/investiture/**`, `src/components/investiture/**`, `src/lib/api/investiture.ts` | Borrar |
| `src/app/(dashboard)/dashboard/enrollments/page.tsx`, `src/components/enrollments/enrollments-table.tsx`, `src/lib/api/enrollments.ts` | Borrar |
| `src/navigation/sidebar/sidebar-items.ts` | Quitar el grupo «Investidura» y la hoja «Inscripciones» |
| `src/lib/auth/screen-catalog/screens/investiture.ts`, `src/lib/auth/permissions.ts` | Quitar pantallas `enrollments`, `investiture-pending`, `investiture-pipeline`, `investiture-config` y sus constantes |
| `src/lib/dashboard/operations-home.ts`, `src/components/dashboard/operations-shortcuts.tsx`, `src/components/dashboard/operations-dashboard-view.tsx` | Atajo y cola |
| `src/components/clubs/validations/validation-tabs.ts` (nuevo), `clubs-validations-client.tsx`, `src/app/(dashboard)/dashboard/clubs/validations/page.tsx` | Sin pestaña de módulos |
| `src/lib/api/validation.ts` | Borrar `submitValidation` |
| `messages/{es,en,pt-BR,fr}.json`, `src/i18n/messages.d.ts` | Textos |
| `src/lib/api/legacy-investiture-endpoints.guard.test.ts` (nuevo) | Guarda: nadie vuelve a llamar la vía vieja |

### App (`sacdia-app`)

| Archivo | Cambio |
| --- | --- |
| `lib/features/investiture_requests/data/models/json_parsing.dart` | Recibe `extractInvestitureListFromResponse` |
| `lib/features/classes/presentation/views/class_detail_with_progress_view.dart` | Sin tarjeta legada; insignia «Investido» |
| `lib/features/investiture/**` salvo `domain/entities/investiture_status.dart` | Borrar |
| `lib/core/config/router.dart`, `lib/core/config/route_names.dart`, `lib/core/constants/api_endpoints.dart` | Rutas y constantes |
| `lib/features/coordinator/presentation/views/coordinator_hub_view.dart`, `lib/core/notifications/push_notification_service.dart` | Tarjeta y lista permitida |
| `lib/features/validation/domain/entities/validation.dart` | Sin `classProgress` |
| `assets/translations/{es,en,fr,pt-BR}.json` | Textos |
| `test/legacy_investiture_pipeline_guard_test.dart` (nuevo) | Guarda |

---

## Slices y Review Workload Forecast

| Slice | Repo | Contenido | Líneas agregadas / borradas (estimado) | Riesgo | Decisión pendiente |
| --- | --- | --- | --- | --- | --- |
| **B1a** | backend | Código de error (B1.1), controlador 410, tabla de rutas, rutas fuera de `InvestitureController`, e2e HTTP con mocks (B1.2) | +310 / −1.350 | Medio: cambia contrato | Ninguna; `size:exception` (patrón aprobado) |
| **B1b** | backend | `ValidationService` responde 410 a `class` y su spec (B1.3). Apilado sobre B1a: importa `throwLegacyInvestiturePipelineRetired` | +90 / −90 | Bajo | Ninguna; `size:exception` (patrón aprobado) |
| **B2** | backend | Borrar código muerto (servicio, DTOs, specs, carreras e2e), `classes: []`, guarda de escrituras, **inventario con aprobación** | +160 / −3.900 | Bajo en lógica | Aprobación del inventario del escáner (11b, B2.5); `size:exception` (patrón aprobado) |
| **B3** | backend | Desbloqueo: migración del enum, servicio, DTO, ruta, unitarias, suite PostgreSQL | +440 / −5 | Medio: escribe datos | Ninguna; `size:exception` (patrón aprobado) |
| **B4** | backend | `investidos_year`, pruebas de lectores de `APPROVED` (incluido `club-role-eligibility`), pruebas de la spec en PostgreSQL, arquitectura de IA-51 | +300 / −5 | Bajo | Ninguna; `size:exception` (patrón aprobado) |
| **B5** | backend | X-1 solo por bloqueo (decisión B5 del usuario) y ajuste de las pruebas que dependían del estado | +110 / −25 | Medio | Ninguna; `size:exception` (patrón aprobado) |
| **A1** | panel | Borrar `/dashboard/investiture*`, catálogo, sidebar, textos | +60 / −5.300 | Bajo | Ninguna; `size:exception` (patrón aprobado) |
| **A2** | panel | Borrar `/dashboard/enrollments`, atajo, acción «Ver inscripciones» de operaciones, pantalla `enrollments` | +70 / −970 | Bajo | Ninguna; `size:exception` (patrón aprobado) |
| **A3** | panel | Pestaña de módulos, cola de operaciones, `submitValidation`, guarda, paridad | +130 / −140 | Bajo | Ninguna; `size:exception` (patrón aprobado) |
| **P1** | app | Mover el extractor; quitar tarjeta legada; insignia | +180 / −700 | Medio: UI visible | Ninguna; `size:exception` (patrón aprobado) |
| **P2** | app | Borrar feature, rutas, tarjeta del coordinador, push, enum, textos; guarda | +70 / −3.400 | Bajo | Ninguna; `size:exception` (patrón aprobado) |
| **D1** | docs | Contratos, funcional, plan, RBAC, esquema | +190 / −140 | Bajo | Ninguna; `size:exception` (patrón aprobado) |

- **Chained PRs recommended: Yes.** Cada slice se apila sobre el anterior de su repo.
- **400-line budget risk: High** por borrado en B1a, B2, A1 y P2 (y por el volumen de B3). Partir B1 en B1a/B1b deja las líneas agregadas de B1a por debajo de 400 (≈ 310); las eliminadas siguen por encima, así que todos los slices van con `size:exception` (decisión O3). El e2e con mocks (`test/investiture.e2e-spec.ts`) queda en B1a y no en B1b: ejercita las rutas que B1a mueve y quedaría en rojo si se separara. Los borrados masivos son archivos completos o métodos enteros: se revisan con `git diff --stat` + `git diff --diff-filter=D --name-only` y la lista de esta sección; no exigen leer línea a línea.
- **Decision needed before apply: Yes, solo una** — la aprobación explícita del inventario del escáner (B2.5, regla 11b). La antigua pregunta abierta quedó resuelta por la decisión B5 y el tamaño por O3: ningún otro slice espera decisión.

## Orden de despliegue

1. **Backend B1a → B5** en el mismo despliegue (o B1a + B1b primero si hay que cortar escrituras ya; B5 va después de B3 porque solo tiene sentido con el desbloqueo disponible). Requisito del plan funcional: producción solo tiene migraciones hasta `20260903180000`; el despliegue aplica en orden **todas** las pendientes desde esa fecha, incluida `20261009120000_investiture_legacy_lock_release_action`. Aplicarlas en Neon es una tarea aparte que aprueba el usuario.
2. **Panel A1 → A3** en la misma ventana, justo después del backend. Entre ambos despliegues un administrador que abra una pantalla vieja ve el mensaje 410 traducido; no hay escritura posible.
3. **App P1 → P2** en la próxima versión de tiendas. Las versiones viejas ya instaladas siguen llamando la vía vieja y reciben 410 con mensaje; el historial viejo sigue respondiendo 200.
4. **Desbloqueo**, por entorno y solo con aprobación del usuario en cada uno. **Requisito previo: la migración `20261009120000_investiture_legacy_lock_release_action` ya está aplicada en ese entorno** (junto con toda la cadena pendiente desde `20260903180000`). Sin ella, `dry_run: false` falla en la primera fila (`invalid input value for enum investiture_action_enum`), la transacción de esa fila revierte, el endpoint responde 500 y no libera nada. Comprobarlo antes, por ejemplo con `SELECT 1 FROM pg_enum e JOIN pg_type t ON t.oid = e.enumtypid WHERE t.typname = 'investiture_action_enum' AND e.enumlabel = 'LEGACY_LOCK_RELEASED';` (una fila). Después: primero `{"dry_run": true}` (no escribe, no necesita la migración), revisar `candidates` y `skipped_pending`, y solo entonces `{"dry_run": false}`. En producción hoy no hay candidatos (0 enrollments).
5. **D1** se mergea con el último PR de backend.

Por qué backend primero: el objetivo de la fase es dejar de aceptar transiciones; las apps viejas no se pueden retirar de los teléfonos, así que el corte tiene que estar en el servidor. El 410 con mensaje hace que ese corte sea entendible en clientes viejos.

## Rollback

- **B1a/B1b/B2/B4/B5:** revertir los commits del PR. No hay cambios de datos. (Revertir B5 vuelve a bloquear por estado de la cadena además del candado.)
- **B3:** revertir el código. El valor `LEGACY_LOCK_RELEASED` del enum queda en la base (PostgreSQL no borra valores de enum sin reconstruir el tipo) y no molesta. Lo liberado no se revierte solo; si el usuario lo aprueba para un entorno, este SQL vuelve a bloquear exactamente lo que soltó el endpoint:

```sql
UPDATE enrollments e
SET locked_for_validation = true
FROM investiture_validation_history h
WHERE h.enrollment_id = e.enrollment_id
  AND h.action = 'LEGACY_LOCK_RELEASED'
  AND e.investiture_status <> 'INVESTIDO'
  AND NOT EXISTS (
    SELECT 1
    FROM investiture_authorization_people p
    WHERE p.enrollment_id = e.enrollment_id
      AND p.status = 'PENDING'
  );
```

  El `NOT EXISTS` evita volver a bloquear una fila que, ya liberada, se presentó por la vía nueva y tiene una persona `PENDING`: bloquearla de nuevo dejaría la solicitud en curso con un candado de la vía vieja (con B5, al resolver se la retiraría como `LEGACY_PIPELINE_ACTIVE`). Columnas verificadas contra `schema.prisma` (`investiture_authorization_people.enrollment_id` / `.status`, `investiture_validation_history.enrollment_id` / `.action`).

- **Panel:** revertir; las pantallas viejas volverían a llamar rutas que responden 410 mientras el backend siga apagado.
- **App:** una versión publicada no se retira; un parche revierte P1/P2. No hay estado local que migrar.

---

## Backend

### Task B1.1: Código de error de la vía retirada

**Files:**
- Modify: `src/common/errors/error-codes.ts` (después de `INVESTITURE_REQUEST_LEGACY_PIPELINE_ACTIVE`, L486)
- Modify: `src/i18n/{es,en,fr,pt-BR}/errors.json`
- Test: `src/investiture/legacy-investiture-pipeline-retired.i18n.spec.ts`

- [ ] **Step 1: Prueba roja**

```ts
import { readFileSync } from 'fs';
import { join } from 'path';
import { ErrorCode } from '../common/errors/error-codes';

describe('legacy investiture pipeline retirement i18n', () => {
  it.each(['es', 'en', 'fr', 'pt-BR'])(
    'declares INVESTITURE_LEGACY_PIPELINE_RETIRED in %s',
    (locale) => {
      const errors = JSON.parse(
        readFileSync(
          join(process.cwd(), 'src', 'i18n', locale, 'errors.json'),
          'utf8',
        ),
      ) as Record<string, string>;
      expect(errors[ErrorCode.INVESTITURE_LEGACY_PIPELINE_RETIRED]).toBeTruthy();
    },
  );
});
```

- [ ] **Step 2:** `node node_modules/jest/bin/jest.js --no-coverage --forceExit src/investiture/legacy-investiture-pipeline-retired.i18n.spec.ts` → FAIL (`Property 'INVESTITURE_LEGACY_PIPELINE_RETIRED' does not exist`).

- [ ] **Step 3: Implementación.** En `error-codes.ts`, debajo de `INVESTITURE_REQUEST_LEGACY_PIPELINE_ACTIVE`:

```ts
  INVESTITURE_LEGACY_PIPELINE_RETIRED = 'INVESTITURE_LEGACY_PIPELINE_RETIRED',
```

Textos (insertados después de la misma clave para conservar el orden):

```bash
node - <<'EOF'
const fs = require('fs');
const texts = {
  es: 'La validación anterior de investidura ya no está disponible. La investidura ahora se gestiona con la solicitud de autorización de la directiva de la sección.',
  en: "The previous investiture validation is no longer available. Investiture is now handled through the section board's authorization request.",
  fr: "L'ancienne validation d'investiture n'est plus disponible. L'investiture se gère désormais par la demande d'autorisation de la direction de la section.",
  'pt-BR': 'A validação anterior de investidura não está mais disponível. A investidura agora é feita pela solicitação de autorização da diretoria da seção.',
};
for (const [locale, text] of Object.entries(texts)) {
  const path = `src/i18n/${locale}/errors.json`;
  const source = JSON.parse(fs.readFileSync(path, 'utf8'));
  const out = {};
  for (const [key, value] of Object.entries(source)) {
    out[key] = value;
    if (key === 'INVESTITURE_REQUEST_LEGACY_PIPELINE_ACTIVE') {
      out.INVESTITURE_LEGACY_PIPELINE_RETIRED = text;
    }
  }
  fs.writeFileSync(path, JSON.stringify(out, null, 2) + '\n');
}
EOF
git diff --stat src/i18n
```

Esperado: 4 archivos, 1 inserción cada uno.

- [ ] **Step 4:** Repetir el comando del Step 2 → PASS (4 casos).

- [ ] **Step 5: Commit** — `feat(investiture): add the retired legacy pipeline error code`.

---

### Task B1.2: Controlador que responde 410

**Files:**
- Create: `src/investiture/legacy-investiture-pipeline-retired.ts`
- Create: `src/investiture/legacy-investiture-retired.controller.ts`
- Modify: `src/investiture/investiture.controller.ts`, `src/investiture/investiture.module.ts`
- Test: `src/investiture/legacy-investiture-retired.controller.spec.ts`

- [ ] **Step 1: Prueba roja**

```ts
import { HttpStatus, RequestMethod } from '@nestjs/common';
import { METHOD_METADATA, PATH_METADATA } from '@nestjs/common/constants';
import { SKIP_PERMISSIONS_KEY } from '../common/decorators/skip-permissions.decorator';
import { AppException } from '../common/errors/app.exception';
import { ErrorCode } from '../common/errors/error-codes';
import { InvestitureController } from './investiture.controller';
import { RETIRED_LEGACY_INVESTITURE_ROUTES } from './legacy-investiture-pipeline-retired';
import { LegacyInvestitureRetiredController } from './legacy-investiture-retired.controller';

type Route = { method: RequestMethod; path: string };

function routeOf(prototype: object, name: string): Route {
  const handler = (prototype as Record<string, object>)[name];
  return {
    method: Reflect.getMetadata(METHOD_METADATA, handler) as RequestMethod,
    path: Reflect.getMetadata(PATH_METADATA, handler) as string,
  };
}

function expected(method: string, path: string): Route {
  return {
    method: RequestMethod[method as keyof typeof RequestMethod],
    path,
  };
}

describe('LegacyInvestitureRetiredController', () => {
  const controller = new LegacyInvestitureRetiredController() as unknown as Record<
    string,
    () => never
  >;

  it('lists the 17 retired routes', () => {
    expect(RETIRED_LEGACY_INVESTITURE_ROUTES).toHaveLength(17);
  });

  it.each(RETIRED_LEGACY_INVESTITURE_ROUTES)(
    '$method $path answers 410 with a stable code',
    ({ method, path, handler }) => {
      expect(routeOf(LegacyInvestitureRetiredController.prototype, handler)).toEqual(
        expected(method, path),
      );
      let thrown: unknown;
      try {
        controller[handler]();
      } catch (error) {
        thrown = error;
      }
      expect(thrown).toBeInstanceOf(AppException);
      expect((thrown as AppException).getStatus()).toBe(HttpStatus.GONE);
      expect((thrown as AppException).code).toBe(
        ErrorCode.INVESTITURE_LEGACY_PIPELINE_RETIRED,
      );
    },
  );

  it('asks only for a session, never for a retired permission', () => {
    expect(
      Reflect.getMetadata(SKIP_PERMISSIONS_KEY, LegacyInvestitureRetiredController),
    ).toBe(true);
  });

  it('leaves no retired route on InvestitureController', () => {
    const live = Object.getOwnPropertyNames(InvestitureController.prototype)
      .filter((name) => name !== 'constructor')
      .map((name) => routeOf(InvestitureController.prototype, name))
      .filter((route) => route.path !== undefined);
    for (const retired of RETIRED_LEGACY_INVESTITURE_ROUTES) {
      expect(live).not.toContainEqual(expected(retired.method, retired.path));
    }
    expect(live).toEqual(
      expect.arrayContaining([
        expected('POST', 'admin/classes/enrollments/expire-overdue'),
        expected('GET', 'investiture/enrollments/:enrollmentId/history'),
        expected('GET', 'enrollments/:enrollmentId/investiture-history'),
      ]),
    );
  });
});
```

- [ ] **Step 2:** `node node_modules/jest/bin/jest.js --no-coverage --forceExit src/investiture/legacy-investiture-retired.controller.spec.ts` → FAIL (módulos inexistentes).

- [ ] **Step 3: Implementación.** `src/investiture/legacy-investiture-pipeline-retired.ts`:

```ts
import { HttpStatus } from '@nestjs/common';
import { AppException } from '../common/errors/app.exception';
import { ErrorCode } from '../common/errors/error-codes';

/**
 * Fase 8: la vía club → coordinación → campo ya no escribe ni lista pendientes.
 * HTTP 410 con código estable para que una versión vieja de la app o del panel
 * muestre el mensaje traducido en lugar de un 404 genérico.
 */
export function throwLegacyInvestiturePipelineRetired(): never {
  throw new AppException(
    ErrorCode.INVESTITURE_LEGACY_PIPELINE_RETIRED,
    HttpStatus.GONE,
  );
}

export const RETIRED_LEGACY_INVESTITURE_ROUTES = [
  { method: 'POST', path: 'investiture/enrollments/:enrollmentId/submit', handler: 'submit' },
  { method: 'POST', path: 'investiture/enrollments/:enrollmentId/club-approve', handler: 'clubApprove' },
  { method: 'POST', path: 'investiture/enrollments/:enrollmentId/coordinator-approve', handler: 'coordinatorApprove' },
  { method: 'POST', path: 'investiture/enrollments/:enrollmentId/field-approve', handler: 'fieldApprove' },
  { method: 'POST', path: 'investiture/enrollments/:enrollmentId/invest', handler: 'invest' },
  { method: 'POST', path: 'investiture/enrollments/:enrollmentId/reject', handler: 'reject' },
  { method: 'POST', path: 'investiture/enrollments/bulk-approve', handler: 'bulkApprove' },
  { method: 'POST', path: 'investiture/enrollments/bulk-reject', handler: 'bulkReject' },
  { method: 'GET', path: 'investiture/pending', handler: 'pending' },
  { method: 'POST', path: 'enrollments/:enrollmentId/submit-for-validation', handler: 'submitForValidationAlias' },
  { method: 'POST', path: 'enrollments/:enrollmentId/validate', handler: 'validateAlias' },
  { method: 'POST', path: 'enrollments/:enrollmentId/investiture', handler: 'investitureAlias' },
  { method: 'GET', path: 'admin/investiture/config', handler: 'listConfigs' },
  { method: 'GET', path: 'admin/investiture/config/:configId', handler: 'getConfig' },
  { method: 'POST', path: 'admin/investiture/config', handler: 'createConfig' },
  { method: 'PATCH', path: 'admin/investiture/config/:configId', handler: 'updateConfig' },
  { method: 'DELETE', path: 'admin/investiture/config/:configId', handler: 'deleteConfig' },
] as const;
```

`src/investiture/legacy-investiture-retired.controller.ts`:

```ts
import { Controller, Delete, Get, Patch, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { SkipPermissions } from '../common/decorators/skip-permissions.decorator';
import { throwLegacyInvestiturePipelineRetired } from './legacy-investiture-pipeline-retired';

const GONE = {
  status: 410,
  description: 'INVESTITURE_LEGACY_PIPELINE_RETIRED — vía anterior apagada (fase 8)',
};

/**
 * Sin @Body ni pipes de parámetros: ningún 400 tapa el 410. Solo el JWT global;
 * sin permisos ni roles, para que ningún actor reciba un 403 engañoso.
 */
@ApiTags('investiture')
@ApiBearerAuth()
@SkipPermissions()
@Controller()
export class LegacyInvestitureRetiredController {
  @Post('investiture/enrollments/:enrollmentId/submit')
  @ApiOperation({ summary: '[RETIRADA] Enviar a la validación anterior' })
  @ApiResponse(GONE)
  submit(): never {
    return throwLegacyInvestiturePipelineRetired();
  }

  @Post('investiture/enrollments/:enrollmentId/club-approve')
  @ApiOperation({ summary: '[RETIRADA] Aprobación del club' })
  @ApiResponse(GONE)
  clubApprove(): never {
    return throwLegacyInvestiturePipelineRetired();
  }

  @Post('investiture/enrollments/:enrollmentId/coordinator-approve')
  @ApiOperation({ summary: '[RETIRADA] Aprobación de coordinación' })
  @ApiResponse(GONE)
  coordinatorApprove(): never {
    return throwLegacyInvestiturePipelineRetired();
  }

  @Post('investiture/enrollments/:enrollmentId/field-approve')
  @ApiOperation({ summary: '[RETIRADA] Aprobación del Campo' })
  @ApiResponse(GONE)
  fieldApprove(): never {
    return throwLegacyInvestiturePipelineRetired();
  }

  @Post('investiture/enrollments/:enrollmentId/invest')
  @ApiOperation({ summary: '[RETIRADA] Investir por la vía anterior' })
  @ApiResponse(GONE)
  invest(): never {
    return throwLegacyInvestiturePipelineRetired();
  }

  @Post('investiture/enrollments/:enrollmentId/reject')
  @ApiOperation({ summary: '[RETIRADA] Rechazar en la vía anterior' })
  @ApiResponse(GONE)
  reject(): never {
    return throwLegacyInvestiturePipelineRetired();
  }

  @Post('investiture/enrollments/bulk-approve')
  @ApiOperation({ summary: '[RETIRADA] Aprobación en bloque' })
  @ApiResponse(GONE)
  bulkApprove(): never {
    return throwLegacyInvestiturePipelineRetired();
  }

  @Post('investiture/enrollments/bulk-reject')
  @ApiOperation({ summary: '[RETIRADA] Rechazo en bloque' })
  @ApiResponse(GONE)
  bulkReject(): never {
    return throwLegacyInvestiturePipelineRetired();
  }

  @Get('investiture/pending')
  @ApiOperation({ summary: '[RETIRADA] Pendientes de la vía anterior' })
  @ApiResponse(GONE)
  pending(): never {
    return throwLegacyInvestiturePipelineRetired();
  }

  @Post('enrollments/:enrollmentId/submit-for-validation')
  @ApiOperation({ summary: '[RETIRADA] Alias de envío a validación' })
  @ApiResponse(GONE)
  submitForValidationAlias(): never {
    return throwLegacyInvestiturePipelineRetired();
  }

  @Post('enrollments/:enrollmentId/validate')
  @ApiOperation({ summary: '[RETIRADA] Alias de validación' })
  @ApiResponse(GONE)
  validateAlias(): never {
    return throwLegacyInvestiturePipelineRetired();
  }

  @Post('enrollments/:enrollmentId/investiture')
  @ApiOperation({ summary: '[RETIRADA] Alias de investir' })
  @ApiResponse(GONE)
  investitureAlias(): never {
    return throwLegacyInvestiturePipelineRetired();
  }

  @Get('admin/investiture/config')
  @ApiOperation({ summary: '[RETIRADA] Configuraciones de la investidura anterior' })
  @ApiResponse(GONE)
  listConfigs(): never {
    return throwLegacyInvestiturePipelineRetired();
  }

  @Get('admin/investiture/config/:configId')
  @ApiOperation({ summary: '[RETIRADA] Configuración de la investidura anterior' })
  @ApiResponse(GONE)
  getConfig(): never {
    return throwLegacyInvestiturePipelineRetired();
  }

  @Post('admin/investiture/config')
  @ApiOperation({ summary: '[RETIRADA] Crear configuración anterior' })
  @ApiResponse(GONE)
  createConfig(): never {
    return throwLegacyInvestiturePipelineRetired();
  }

  @Patch('admin/investiture/config/:configId')
  @ApiOperation({ summary: '[RETIRADA] Editar configuración anterior' })
  @ApiResponse(GONE)
  updateConfig(): never {
    return throwLegacyInvestiturePipelineRetired();
  }

  @Delete('admin/investiture/config/:configId')
  @ApiOperation({ summary: '[RETIRADA] Desactivar configuración anterior' })
  @ApiResponse(GONE)
  deleteConfig(): never {
    return throwLegacyInvestiturePipelineRetired();
  }
}
```

En `investiture.controller.ts` borrar los handlers `submitForValidation`, `clubApprove`, `coordinatorApprove`, `fieldApprove`, `markInvestido`, `reject`, `bulkApprove`, `bulkReject`, `getPending`, `submitForValidationLegacy`, `validateEnrollmentLegacy`, `markInvestidoLegacy`, `getConfigs`, `getConfig`, `createConfig`, `updateConfig` y `deleteConfig` (L57-432, L459-528, L567-664, L695-859 del archivo base, banners de comentario incluidos). Quedan `expireOverdueEnrollments`, `getHistory` y `getHistoryLegacy`. Recortar imports a lo que usan: `Controller, Post, Get, Param, Body, ParseIntPipe, UseGuards, Request, HttpCode, HttpStatus`, `ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiParam`, `ExpireOverdueEnrollmentsDto`, `JwtAuthGuard, GlobalRolesGuard, PermissionsGuard`, `GlobalRoles, AuthorizationResource, RequirePermissions`.

En `investiture.module.ts`: `controllers: [InvestitureController, LegacyInvestitureRetiredController]`.

- [ ] **Step 4:** Repetir el Step 2 → PASS. `node node_modules/jest/bin/jest.js --no-coverage --forceExit src/common/guards/permissions-metadata.spec.ts` → PASS (sigue leyendo `expireOverdueEnrollments`).

- [ ] **Step 5: e2e HTTP con mocks.** En `test/investiture.e2e-spec.ts` (880 líneas en la base) borrar, con sus banners de comentario, los `describe` de `submit-for-validation`, `validate`, `investiture` **y `GET /investiture/pending`** (un solo tramo contiguo, **L146-518**) y los cinco de `admin/investiture/config` (**L608-879**); el `describe` de `GET /enrollments/:enrollmentId/investiture-history` (L520-606) y el cierre del `describe` principal (L880) se quedan. Dejar `mockInvestitureService = { getHistory: jest.fn() }`. (Las referencias anteriores `L150-423` y `L612-880` dejaban vivo el `describe` de `pending`, L424-518, que ahora recibe 410.) Agregar al final del `describe('Investiture E2E')`:

```ts
  describe('retired legacy pipeline (fase 8)', () => {
    it.each(
      RETIRED_LEGACY_INVESTITURE_ROUTES.map((route) => [route.method, route.path] as const),
    )('%s /api/v1/%s answers 410', async (method, path) => {
      const url = `/api/v1/${path
        .replace(':enrollmentId', '42')
        .replace(':configId', '7')}`;
      const agent = request(app.getHttpServer());
      const call =
        method === 'GET'
          ? agent.get(url)
          : method === 'POST'
            ? agent.post(url)
            : method === 'PATCH'
              ? agent.patch(url)
              : agent.delete(url);
      const res = await call
        .set(authHeaders())
        .send({ action: 'invest', enrollment_ids: [42], comments: 'x' });

      expect(res.status).toBe(410);
      expect(res.body.code).toBe('INVESTITURE_LEGACY_PIPELINE_RETIRED');
      expect(mockInvestitureService.getHistory).not.toHaveBeenCalled();
    });
  });
```

con `import { RETIRED_LEGACY_INVESTITURE_ROUTES } from '../src/investiture/legacy-investiture-pipeline-retired';`. Correr: `node node_modules/jest/bin/jest.js --config ./test/jest-e2e.json --no-coverage --forceExit --runInBand --testPathPatterns test/investiture.e2e-spec.ts` → PASS (17 + historial). Esta suite no usa PostgreSQL.

- [ ] **Step 6:** `npx tsc --noEmit -p tsconfig.build.json` y `npx eslint --no-fix src/investiture test/investiture.e2e-spec.ts` → sin errores.

- [ ] **Step 7: Commit** — `feat(investiture): answer 410 on every retired legacy pipeline route`. Este commit cierra el PR **B1a** (B1.1 + B1.2).

---

### Task B1.3: `ValidationModule` deja de mover clases (PR B1b)

**Files:** Modify `src/validation/validation.service.ts`; Test `src/validation/validation.service.spec.ts`.

- [ ] **Step 1: Prueba roja.** Reemplazar el `describe('ValidationService class pipeline', …)` (L67-151) por:

```ts
describe('ValidationService retired class path', () => {
  const prisma = {
    $transaction: jest.fn(),
    enrollments: { findUnique: jest.fn() },
  };
  const honorWorkflow = {
    submitForReview: jest.fn(),
    approve: jest.fn(),
    reject: jest.fn(),
  };
  const service = new ValidationService(
    prisma as never,
    { notifySafe: jest.fn(), sendToSectionRole: jest.fn() } as never,
    honorWorkflow as never,
  );

  async function expectGone(promise: Promise<unknown>) {
    const error = await promise.then(
      () => null,
      (reason: unknown) => reason,
    );
    expect(error).toBeInstanceOf(AppException);
    expect((error as AppException).getStatus()).toBe(HttpStatus.GONE);
    expect((error as AppException).code).toBe(
      ErrorCode.INVESTITURE_LEGACY_PIPELINE_RETIRED,
    );
  }

  beforeEach(() => jest.clearAllMocks());

  it('answers 410 to a class submit without reading or writing', async () => {
    await expectGone(service.submitForReview('class', 7, 'member-1'));
    expect(prisma.enrollments.findUnique).not.toHaveBeenCalled();
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it.each(['approved', 'rejected'] as const)(
    'answers 410 to a class review (%s), even without a comment',
    async (action) => {
      await expectGone(service.review('class', 7, action, 'reviewer-1'));
      expect(prisma.$transaction).not.toHaveBeenCalled();
      expect(honorWorkflow.approve).not.toHaveBeenCalled();
      expect(honorWorkflow.reject).not.toHaveBeenCalled();
    },
  );

  it('keeps honor submit working', async () => {
    honorWorkflow.submitForReview.mockResolvedValue({ user_honor_id: 9 });
    await service.submitForReview('honor', 9, 'member-1');
    expect(honorWorkflow.submitForReview).toHaveBeenCalledWith(9, 'member-1');
  });
});
```

Imports nuevos de la spec: `import { HttpStatus } from '@nestjs/common';` y `import { AppException } from '../common/errors/app.exception';`.

- [ ] **Step 2:** `node node_modules/jest/bin/jest.js --no-coverage --forceExit src/validation/validation.service.spec.ts` → FAIL (llega a `findUnique`).

- [ ] **Step 3: Implementación** en `validation.service.ts`:

```ts
import { throwLegacyInvestiturePipelineRetired } from '../investiture/legacy-investiture-pipeline-retired';
```

```ts
  async submitForReview(
    entityType: EntityType,
    entityId: number,
    userId: string,
  ) {
    if (entityType === 'class') {
      throwLegacyInvestiturePipelineRetired();
    }
    return this.honorValidationWorkflow.submitForReview(entityId, userId);
  }
```

y en `review`, como primera línea del cuerpo (antes del chequeo del comentario):

```ts
    if (entityType === 'class') {
      throwLegacyInvestiturePipelineRetired();
    }
```

Borrar la llamada `if (entityType === 'class') { return this.reviewClass(...) }`. **No** borrar todavía `submitClassForReview`, `reviewClass`, `claimClassStatus` ni la rama de clase de `getPendingReviews`: el inventario del escáner cambia y eso va en B2 con aprobación.

- [ ] **Step 4:** Repetir el Step 2 → PASS. `npx tsc --noEmit -p tsconfig.build.json` → OK.

- [ ] **Step 5: Commit** — `feat(validation): answer 410 when a class is submitted or reviewed`.

### Task B1.4: PRs B1a y B1b

- [ ] **B1a** (después de B1.2): unitarias de `src/investiture` y `src/common/guards`; e2e `test/investiture.e2e-spec.ts`; `tsc`; ESLint de lo tocado. PR contra `feat/investiture-ui-backend-support`, `type:feature`, `size:exception`, título `feat(investiture): retire the legacy pipeline routes with HTTP 410`.
- [ ] **B1b** (después de B1.3): unitarias de `src/validation`; `tsc`; ESLint. PR apilado sobre B1a, `type:feature`, `size:exception`, título `feat(validation): answer 410 when a class is submitted or reviewed`.
- [ ] En ambos: `node node_modules/jest/bin/jest.js --no-coverage --forceExit src/common/authorization/club-assignment-effectivity.inventory.spec.ts` → PASS sin cambios (ni B1a ni B1b borran consultas de asignaciones; eso es B2).

---

### Task B2.1: Forma final de `InvestitureService` y `ValidationService`

**Files:** Modify `src/investiture/investiture.service.ts`, `src/investiture/investiture.module.ts`, `src/investiture/dto/*`, `src/validation/validation.service.ts`; Test `src/investiture/investiture.service.spec.ts`, `src/validation/validation.service.spec.ts`.

- [ ] **Step 1: Pruebas rojas.** Al principio del `describe('InvestitureService')`:

```ts
  it('keeps only the history read and the overdue expiry', () => {
    expect(
      Object.getOwnPropertyNames(InvestitureService.prototype).sort(),
    ).toEqual([
      'constructor',
      'countElapsedEcclesiasticalYears',
      'expireOverdueEnrollments',
      'findCurrentEcclesiasticalYear',
      'getHistory',
    ]);
  });
```

En `validation.service.spec.ts`, dentro de `describe('ValidationService retired class path')`:

```ts
  it('no longer carries the class workflow', () => {
    const names = Object.getOwnPropertyNames(ValidationService.prototype);
    expect(names).not.toContain('submitClassForReview');
    expect(names).not.toContain('reviewClass');
    expect(names).not.toContain('claimClassStatus');
  });

  it('lists no class submissions and keeps the response shape', async () => {
    const reader = {
      enrollments: { findMany: jest.fn() },
      users_honors: { findMany: jest.fn().mockResolvedValue([]) },
    };
    const lister = new ValidationService(reader as never, {} as never, {} as never);

    await expect(lister.getPendingReviews({ entity_type: 'class' })).resolves.toEqual({
      classes: [],
      honors: [],
    });
    await expect(lister.getPendingReviews()).resolves.toEqual({ classes: [], honors: [] });
    expect(reader.enrollments.findMany).not.toHaveBeenCalled();
  });
```

- [ ] **Step 2:** `node node_modules/jest/bin/jest.js --no-coverage --forceExit src/investiture/investiture.service.spec.ts src/validation/validation.service.spec.ts -t "keeps only|no longer carries|lists no class"` → FAIL.

- [ ] **Step 3: Implementación.**
  - `investiture.service.ts`: borrar `submitForValidation`, `clubApprove`, `coordinatorApprove`, `fieldApprove`, `reject`, `markInvestido`, `getPending`, `enrichPendingEnrollments`, `getMemberAssignment`, `pendingContextKey`, `submitterRoleContextKey`, `toPendingUser`, `deriveEcclesiasticalYearName`, `validateEnrollment`, `bulkApproveEnrollments`, `bulkRejectEnrollments`, `buildInvestitureConfigWhere`, `assertCanAccessInvestitureConfigLocalField`, `resolveAccessibleInvestitureConfigLocalFieldIds`, `getConfigs`, `getConfig`, `createConfig`, `updateConfig`, `deleteConfig`, `ensureDurationAllowsSubmission`, `ensureRequiredClassRequirementsComplete`, `claimEnrollmentStatus`, `expireEnrollment`, `canActorManageInvestitureEnrollment`, `resolveCoordinatorSectionScopeForGlobalEndpoint`, `transitionApprovalState`, `resolveInvestitureConfig`, y los tipos `Pending*` que solo usaban esos métodos. A nivel de módulo, borrar también `APPROVAL_TRANSITIONS`, `REJECTABLE_STATUSES` y `ApprovalResult` (L41-73 y L80-85 del archivo base: el comentario y la tabla de la máquina de estados de la cadena y el tipo de resultado; sus únicos lectores son los métodos borrados); **`EXPIRABLE_STATUSES` se queda** (lo usa `expireOverdueEnrollments`). Los métodos que quedan solo usan `prisma` y `authorizationContext` (`getHistory` L1100 y `expireOverdueEnrollments` L1991 en la base), así que `logger`, `posthog` y las demás dependencias del constructor también se van. Constructor final:

```ts
  constructor(
    private readonly prisma: PrismaService,
    private readonly authorizationContext: AuthorizationContextService,
  ) {}
```

  Quitar imports que queden sin uso (ESLint los marca).
  - `investiture.module.ts`: `imports: [PrismaModule]` (Notifications, Achievements, Coordination y Classes ya no se inyectan; `AuthorizationContextService` es global).
  - `src/investiture/dto/`: borrar `submit-for-validation`, `validate-enrollment`, `mark-investido`, `approve-investiture`, `reject-investiture`, `create-investiture-config`, `update-investiture-config`, `bulk-approve-enrollments`, `bulk-reject-enrollments`; `index.ts` queda con `export * from './expire-overdue-enrollments.dto';`.
  - `validation.service.ts`: borrar `submitClassForReview`, `reviewClass`, `claimClassStatus` y los imports `investiture_status_enum`, `investiture_action_enum`, `Prisma`, `AppConflictException`, `AppNotFoundException`, `rejectLegacyMutationIfAuthorizationPending` si quedan sin uso. En `getPendingReviews` borrar `shouldIncludeClasses` y su consulta; el resultado sigue siendo `{ classes: [], honors }`:

```ts
    const results: { classes: unknown[]; honors: unknown[] } = {
      classes: [],
      honors: [],
    };
    const shouldIncludeHonors =
      !filters?.entity_type || filters.entity_type === 'honor';
```

- [ ] **Step 4: Specs.** En `investiture.service.spec.ts` borrar los `describe` `submitForValidation`, `clubApprove`, `coordinatorApprove`, `fieldApprove`, `reject`, `markInvestido`, `validateEnrollment (legacy)`, `getPending`, `Full approval chain`, `legacy writes keep the status they read`, y del `describe('pending authorization blocks the old pipeline')` mover solo `it('does not expire an enrollment with a pending request')` al `describe('expireOverdueEnrollments')` y borrar el resto. El `TestingModule` queda con `PrismaService` y `AuthorizationContextService`; quitar los imports de DTOs borrados.

- [ ] **Step 5:** `node node_modules/jest/bin/jest.js --no-coverage --forceExit src/investiture src/validation` → PASS.

- [ ] **Step 6: Commit** — `refactor(investiture): drop the dead legacy pipeline code`.

---

### Task B2.2: e2e que usaban los escritores viejos

**Files:** Modify `test/investiture-authorization-requests-postgres.e2e-spec.ts`, `test/certificate-import-journey.e2e-spec.ts`.

- [ ] **Step 1:** Borrar las dos carreras que ya no tienen escritor: `it.each(['resolve-first', 'invest-first'])('keeps one INVESTIDO when %s races the other confirm', …)` (desde L3279) e `it.each([['resolve-first','submit'], …])('keeps one INVESTIDO when %s races %s', …)` (desde L3395 hasta el `});` anterior a `const HISTORICAL_REASON`). Quitar los imports de `InvestitureService` y `ValidationService` si quedan sin uso. La garantía que cubrían (un solo `INVESTIDO`, una sola `class.completed`) pasa a la suite de B3/B4 por HTTP 410.
- [ ] **Step 2:** En `certificate-import-journey.e2e-spec.ts` (L1108) el constructor queda `new InvestitureService(prisma as never, {} as never)`.
- [ ] **Step 3:** Con el clúster descartable: `--testPathPatterns 'investiture-authorization-requests-postgres|certificate-import-journey|certificate-import-postgres|evidence-review-investiture-guard-postgres'` → PASS; `rg -c "deadlock detected" "$SCRATCH/pg.log"` → nada.
- [ ] **Step 4: Commit** — `test(investiture): drop races against retired legacy writers`.

---

### Task B2.3: Guarda de escrituras de la vía vieja

**Files:** Create `src/investiture/legacy-pipeline-write.guard.spec.ts`.

La guarda busca la **forma de escritura** (`clave: ENUM` o `clave: 'LITERAL'`), no cualquier mención del estado: hay lecturas legítimas que se conservan (decisión 6 y O2) y no deben dispararla. Se evalúa sobre el archivo entero (`\s` cruza saltos de línea), así que un par partido en dos líneas por Prettier también se detecta. No se vigila `submitted_for_validation: true` solo: aparece en `select` de lectura (`admin/admin-users.service.ts:395`, `classes/classes.service.ts:876`) y la vía vieja siempre lo escribía junto con el estado, que sí se vigila. Límite conocido: `investiture_status: variable` no se detecta.

- [ ] **Step 1: Prueba**

```ts
import { readdirSync, readFileSync } from 'node:fs';
import { join, relative, sep } from 'node:path';

const SRC = join(process.cwd(), 'src');

/**
 * Formas de ESCRITURA con las que la vía vieja fijaba estados y acciones.
 * Exigen el par `clave: valor`; una comparación (`=== …APPROVED`), una lista
 * (`in: [...]`) o un `select` no las cumplen.
 */
const FORBIDDEN = [
  /\b(?:investiture_status|action)\s*:\s*investiture_(?:status|action)_enum\.(?:SUBMITTED_FOR_VALIDATION|CLUB_APPROVED|COORDINATOR_APPROVED|FIELD_APPROVED|APPROVED|SUBMITTED)\b/g,
  /\binvestiture_status\s*:\s*['"](?:SUBMITTED_FOR_VALIDATION|CLUB_APPROVED|COORDINATOR_APPROVED|FIELD_APPROVED|APPROVED)['"]/g,
];

/** Solo lectura: el tablero SLA filtra la historia ya grabada (`where: { action: FIELD_APPROVED }`). */
const READ_ONLY_ALLOWLIST = new Set(['analytics/analytics.service.ts']);

/**
 * TEMPORAL: `investidos_year` todavía cuenta `investiture_status: 'APPROVED'`
 * hasta la Task B4.1. B4.1 borra esta constante y su uso.
 */
const UNTIL_B4_1 = new Set(['clubs/clubs.service.ts']);

function sources(directory: string): string[] {
  return readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) return sources(path);
    return entry.name.endsWith('.ts') && !entry.name.endsWith('.spec.ts')
      ? [path]
      : [];
  });
}

const matches = (text: string) =>
  FORBIDDEN.flatMap((pattern) => [...text.matchAll(pattern)]);

describe('legacy investiture pipeline stays off', () => {
  it.each([
    'investiture_status: investiture_status_enum.CLUB_APPROVED',
    'action:\n    investiture_action_enum.SUBMITTED',
    "investiture_status: 'APPROVED'",
    'investiture_status: "FIELD_APPROVED"',
  ])('flags the write shape %j', (sample) => {
    expect(matches(sample)).toHaveLength(1);
  });

  it.each([
    'e.investiture_status === investiture_status_enum.APPROVED',
    'investiture_status: { in: [investiture_status_enum.INVESTIDO, investiture_status_enum.APPROVED] }',
    'investiture_status: investiture_status_enum.INVESTIDO',
    "investiture_status: 'INVESTIDO'",
    'action: investiture_action_enum.EXPIRED',
    'action: investiture_action_enum.LEGACY_LOCK_RELEASED',
    'submitted_for_validation: true',
  ])('ignores the read or still-valid shape %j', (sample) => {
    expect(matches(sample)).toHaveLength(0);
  });

  it('no production file writes a legacy pipeline state or action', () => {
    const offenders: string[] = [];
    for (const path of sources(SRC)) {
      const file = relative(SRC, path).split(sep).join('/');
      if (READ_ONLY_ALLOWLIST.has(file) || UNTIL_B4_1.has(file)) continue;
      const text = readFileSync(path, 'utf8');
      for (const match of matches(text)) {
        const line = text.slice(0, match.index).split('\n').length;
        offenders.push(`${file}:${line}: ${match[0].replace(/\s+/g, ' ')}`);
      }
    }
    expect(offenders).toEqual([]);
  });
});
```

- [ ] **Step 2: Correr contra el árbol real.** Primero, sin ejecutar Jest, el inventario crudo de coincidencias (así se ve qué entra y qué no):

```bash
rg -nUP "\binvestiture_status\s*:\s*['\"](?:SUBMITTED_FOR_VALIDATION|CLUB_APPROVED|COORDINATOR_APPROVED|FIELD_APPROVED|APPROVED)['\"]|\b(?:investiture_status|action)\s*:\s*investiture_(?:status|action)_enum\.(?:SUBMITTED_FOR_VALIDATION|CLUB_APPROVED|COORDINATOR_APPROVED|FIELD_APPROVED|APPROVED|SUBMITTED)\b" src -g '!*.spec.ts'
```

  Esperado **antes de B2.1** (árbol de la base, 16 coincidencias): `analytics/analytics.service.ts:560` (permitida), `clubs/clubs.service.ts:1507` (temporal hasta B4.1), 11 en `investiture/investiture.service.ts` (L55, L59, L63 de `APPROVAL_TRANSITIONS`, L255, L265, L469, L574, L755, L1241, L1252, L1480) y 3 en `validation/validation.service.ts` (L73, L83, L292). Los números de línea cambian con B1a/B1b; lo que importa es el conjunto de archivos. **Las lecturas legítimas no aparecen**: `validation/validation.service.ts:424` (`=== investiture_status_enum.APPROVED`), `club-role-eligibility/club-role-eligibility.service.ts:15-18` y `:112` (listas), `admin/admin-users.service.ts:395` y `classes/classes.service.ts:876` (`submitted_for_validation` en `select`).

  Con Jest, el mismo estado: `node node_modules/jest/bin/jest.js --no-coverage --forceExit src/investiture/legacy-pipeline-write.guard.spec.ts` → las 11 pruebas de forma pasan y la de árbol real **FALLA** listando 14 `offenders` (11 de `investiture.service.ts` + 3 de `validation.service.ts`).

  **Después de B2.1** (se borran esos métodos y `APPROVAL_TRANSITIONS`): el `rg` de arriba devuelve solo `analytics/analytics.service.ts:560` y `clubs/clubs.service.ts:1507`, y la guarda pasa:

```text
 PASS  src/investiture/legacy-pipeline-write.guard.spec.ts
  legacy investiture pipeline stays off
    ✓ flags the write shape … (4)
    ✓ ignores the read or still-valid shape … (7)
    ✓ no production file writes a legacy pipeline state or action
Tests:       12 passed, 12 total
```

- [ ] **Step 3: Verificar que muerde en el árbol real.** Agregar temporalmente a `src/investiture/investiture.service.ts` la línea `const x = { investiture_status: 'CLUB_APPROVED' };` y a `src/validation/validation.service.ts` `const y = { action: investiture_action_enum.SUBMITTED };` (si `investiture_action_enum` ya no se importa, agregar el import) → la prueba de árbol real **FALLA** nombrando ambos archivos y líneas; quitar las dos líneas → PASS. (`git stash` de B2.1 sobre una copia no sirve.)
- [ ] **Step 4: Commit** — `test(investiture): guard against legacy pipeline writes`.

### Task B2.4: `tsc`, lint y suites

- [ ] `npx tsc --noEmit -p tsconfig.build.json`; `npx eslint --no-fix src/investiture src/validation test/investiture-authorization-requests-postgres.e2e-spec.ts test/certificate-import-journey.e2e-spec.ts` → sin errores.
- [ ] `node node_modules/jest/bin/jest.js --no-coverage --forceExit` (todas las unitarias). Esperado: falla **solo** `club-assignment-effectivity.inventory.spec.ts` (Task B2.5).

---

### Task B2.5: Inventario del escáner — requiere aprobación del usuario

**Files:** `src/common/authorization/club-assignment-effectivity.inventory.ts` (L82 y L111), `src/common/authorization/club-assignment-effectivity.inventory.spec.ts`.

- [ ] **Step 1:** `node node_modules/jest/bin/jest.js --no-coverage --forceExit src/common/authorization/club-assignment-effectivity.inventory.spec.ts 2>&1 | rg "Stale club assignment inventory|Expected|Received"`. Esperado: `investiture/investiture.service.ts expected 7/659426390804, received 2/<digest>` y `validation/validation.service.ts expected 3/af6362f7dd6f, received 1/<digest>`.
- [ ] **Step 2: STOP.** Mostrar al usuario los dos `received`, el total (154 → 147) y los totales por dueño (T08 57 → 52, T09 58 → 56), con la causa: solo se borraron consultas de la vía retirada (`submitForValidation` L279, `getPending` L713, `enrichPendingEnrollments` L815/L891, `canActorManageInvestitureEnrollment` L2345; `submitClassForReview` L106 y la rama de clase de `getPendingReviews` L298). **No editar el inventario sin un sí explícito del usuario.** Sin ese sí, B2 no se abre como PR.
- [ ] **Step 3 (solo con aprobación):** en el inventario,

```ts
  'investiture/investiture.service.ts': 'effectiveWhere|T08|2|<digest recibido>',
  'validation/validation.service.ts': 'effectiveWhere|T09|1|<digest recibido>',
```

  y en la spec: `toHaveLength(147)`, `{ T08: 52, T09: 56, allowlist: 39 }` y `'investiture/investiture.service.ts': 2`.
- [ ] **Step 4:** Repetir el Step 1 → PASS. Unitarias completas → PASS.
- [ ] **Step 5: Commit** — `chore(authorization): reclassify assignment queries after the legacy pipeline removal`.

### Task B2.6: PR B2

- [ ] PR apilado sobre B1b, `type:refactor`, `size:exception`, título `refactor(investiture): remove the legacy pipeline implementation`. En la descripción: lista de métodos y archivos borrados y la aprobación del inventario (fecha y texto).

---

### Task B3.1: Valor `LEGACY_LOCK_RELEASED`

**Files:** Create `prisma/migrations/20261009120000_investiture_legacy_lock_release_action/migration.sql`; Modify `prisma/schema.prisma` (enum L3757).

- [ ] **Step 1:** Migración:

```sql
-- Fase 8: auditoría del desbloqueo explícito de expedientes de la vía anterior.
-- POST /api/v1/admin/investiture/legacy-locks/release deja una fila por
-- enrollment liberado. No cambia investiture_status.
ALTER TYPE "investiture_action_enum" ADD VALUE IF NOT EXISTS 'LEGACY_LOCK_RELEASED';
```

- [ ] **Step 2:** En `schema.prisma`, agregar `LEGACY_LOCK_RELEASED` al final de `enum investiture_action_enum` (después de `EXPIRED`). `pnpm exec prisma generate` (solo cliente). No se aplica en ninguna base fuera del clúster descartable: la e2e arma el esquema desde `schema.prisma`.
- [ ] **Step 3: Commit** — `feat(investiture): add the legacy lock release history action`.

---

### Task B3.2: Servicio de desbloqueo

**Files:** Create `src/investiture/legacy-lock-release.service.ts`, `src/investiture/dto/release-legacy-locks.dto.ts`; Modify `src/investiture/dto/index.ts`, `src/investiture/investiture.module.ts`; Test `src/investiture/legacy-lock-release.service.spec.ts`.

- [ ] **Step 1: Prueba roja**

```ts
import { AppForbiddenException } from '../common/errors/app.exception';
import { ErrorCode } from '../common/errors/error-codes';
import {
  LEGACY_LOCK_RELEASE_COMMENT,
  LegacyLockReleaseService,
} from './legacy-lock-release.service';

const ACTOR = '11111111-1111-4111-8111-111111111111';
const rows = [
  { enrollment_id: 1, user_id: 'u1', class_id: 3, ecclesiastical_year_id: 9, investiture_status: 'CLUB_APPROVED' },
  { enrollment_id: 2, user_id: 'u2', class_id: 3, ecclesiastical_year_id: 9, investiture_status: 'APPROVED' },
];

function build(pendingIds: number[] = [], updatedCount = 1) {
  const tx = {
    $executeRaw: jest.fn().mockResolvedValue(0),
    investiture_authorization_people: {
      findFirst: jest.fn(({ where }: { where: { enrollment_id: number } }) =>
        Promise.resolve(pendingIds.includes(where.enrollment_id) ? { person_id: 'p' } : null),
      ),
    },
    enrollments: { updateMany: jest.fn().mockResolvedValue({ count: updatedCount }) },
    investiture_validation_history: { create: jest.fn().mockResolvedValue({}) },
  };
  const prisma = {
    enrollments: { findMany: jest.fn().mockResolvedValue(rows) },
    investiture_authorization_people: tx.investiture_authorization_people,
    $transaction: jest.fn((fn: (client: typeof tx) => unknown) => fn(tx)),
  };
  const policy = { assert: jest.fn().mockResolvedValue(undefined) };
  return { service: new LegacyLockReleaseService(prisma as never, policy as never), prisma, tx, policy };
}

describe('LegacyLockReleaseService', () => {
  it('refuses anyone but super-admin before reading', async () => {
    const { service, prisma, policy } = build();
    policy.assert.mockRejectedValue(new AppForbiddenException(ErrorCode.SUPER_ADMIN_WRITE_REQUIRED));
    await expect(service.release(ACTOR, {})).rejects.toMatchObject({
      code: ErrorCode.SUPER_ADMIN_WRITE_REQUIRED,
    });
    expect(prisma.enrollments.findMany).not.toHaveBeenCalled();
  });

  it('only looks at locked operational rows that are not invested, with no active filter', async () => {
    const { service, prisma } = build();
    await service.release(ACTOR, {});
    expect(prisma.enrollments.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          locked_for_validation: true,
          record_kind: 'OPERATIONAL',
          investiture_status: { not: 'INVESTIDO' },
        },
        orderBy: { enrollment_id: 'asc' },
      }),
    );
  });

  it('is a dry run by default and writes nothing', async () => {
    const { service, prisma } = build([2]);
    await expect(service.release(ACTOR, {})).resolves.toEqual({
      dry_run: true,
      candidates: rows,
      skipped_pending: [2],
      released: [],
    });
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it('releases without a pending person, keeps the status and audits each row', async () => {
    const { service, tx } = build([2]);
    const result = await service.release(ACTOR, { dry_run: false });

    expect(result).toEqual({ dry_run: false, candidates: rows, skipped_pending: [2], released: [1] });
    expect(tx.enrollments.updateMany).toHaveBeenCalledTimes(1);
    expect(tx.enrollments.updateMany).toHaveBeenCalledWith({
      where: {
        enrollment_id: 1,
        locked_for_validation: true,
        record_kind: 'OPERATIONAL',
        investiture_status: { not: 'INVESTIDO' },
      },
      data: { locked_for_validation: false },
    });
    expect(tx.investiture_validation_history.create).toHaveBeenCalledWith({
      data: {
        enrollment_id: 1,
        action: 'LEGACY_LOCK_RELEASED',
        performed_by: ACTOR,
        comments: LEGACY_LOCK_RELEASE_COMMENT,
      },
    });
    expect(tx.$executeRaw).toHaveBeenCalledTimes(2);
  });

  it('does not audit a row that changed under the lock', async () => {
    const { service, tx } = build([], 0);
    const result = await service.release(ACTOR, { dry_run: false });
    expect(result.released).toEqual([]);
    expect(tx.investiture_validation_history.create).not.toHaveBeenCalled();
  });
});
```

- [ ] **Step 2:** `node node_modules/jest/bin/jest.js --no-coverage --forceExit src/investiture/legacy-lock-release.service.spec.ts` → FAIL (módulo inexistente).

- [ ] **Step 3: Implementación.** `src/investiture/legacy-lock-release.service.ts`:

```ts
import { Injectable } from '@nestjs/common';
import { Prisma, investiture_action_enum } from '@prisma/client';
import { pendingInvestitureAuthorization } from '../investiture-requests/investiture-request-lock';
import { PrismaService } from '../prisma/prisma.service';
import { ExactSuperAdminWritePolicy } from '../rbac/exact-super-admin-write.policy';

export const LEGACY_LOCK_RELEASE_COMMENT =
  'Bloqueo de la validación anterior liberado después del apagado (fase 8). El estado no cambia.';

/**
 * Regla del usuario: cualquier fila OPERATIONAL bloqueada que no esté INVESTIDO
 * (y sin PENDING, que se descarta aparte). Sin filtro por `active` ni por
 * estado de la cadena: una fila inactiva o REJECTED/EXPIRED también se suelta.
 */
const CANDIDATE_WHERE = {
  locked_for_validation: true,
  record_kind: 'OPERATIONAL',
  investiture_status: { not: 'INVESTIDO' },
} satisfies Prisma.enrollmentsWhereInput;

export type LegacyLockCandidate = {
  enrollment_id: number;
  user_id: string;
  class_id: number;
  ecclesiastical_year_id: number;
  investiture_status: string;
};

export type LegacyLockReleaseResult = {
  dry_run: boolean;
  candidates: LegacyLockCandidate[];
  skipped_pending: number[];
  released: number[];
};

/**
 * Suelta locked_for_validation de expedientes de la vía anterior que no están
 * INVESTIDO y no tienen una persona PENDING. Una transacción por enrollment,
 * bajo el mismo candado advisory que presentar y resolver. Idempotente.
 */
@Injectable()
export class LegacyLockReleaseService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly superAdmin: ExactSuperAdminWritePolicy,
  ) {}

  async release(
    actorId: string,
    params: { dry_run?: boolean },
  ): Promise<LegacyLockReleaseResult> {
    await this.superAdmin.assert(actorId);
    const dryRun = params.dry_run ?? true;
    const candidates = await this.prisma.enrollments.findMany({
      where: CANDIDATE_WHERE,
      select: {
        enrollment_id: true,
        user_id: true,
        class_id: true,
        ecclesiastical_year_id: true,
        investiture_status: true,
      },
      orderBy: { enrollment_id: 'asc' },
    });

    const skippedPending: number[] = [];
    const released: number[] = [];
    for (const candidate of candidates) {
      if (dryRun) {
        const pending =
          await this.prisma.investiture_authorization_people.findFirst({
            where: { enrollment_id: candidate.enrollment_id, status: 'PENDING' },
            select: { person_id: true },
          });
        if (pending) skippedPending.push(candidate.enrollment_id);
        continue;
      }
      const outcome = await this.prisma.$transaction(async (tx) => {
        if (await pendingInvestitureAuthorization(tx, candidate.enrollment_id)) {
          return 'pending' as const;
        }
        const updated = await tx.enrollments.updateMany({
          where: { enrollment_id: candidate.enrollment_id, ...CANDIDATE_WHERE },
          data: { locked_for_validation: false },
        });
        if (updated.count !== 1) {
          return 'unchanged' as const;
        }
        await tx.investiture_validation_history.create({
          data: {
            enrollment_id: candidate.enrollment_id,
            action: investiture_action_enum.LEGACY_LOCK_RELEASED,
            performed_by: actorId,
            comments: LEGACY_LOCK_RELEASE_COMMENT,
          },
        });
        return 'released' as const;
      });
      if (outcome === 'pending') skippedPending.push(candidate.enrollment_id);
      if (outcome === 'released') released.push(candidate.enrollment_id);
    }

    return {
      dry_run: dryRun,
      candidates,
      skipped_pending: skippedPending,
      released,
    };
  }
}
```

`src/investiture/dto/release-legacy-locks.dto.ts`:

```ts
import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsOptional } from 'class-validator';

export class ReleaseLegacyLocksDto {
  @ApiPropertyOptional({
    default: true,
    description:
      'true (por defecto) solo lista candidatos; false suelta locked_for_validation',
  })
  @IsOptional()
  @IsBoolean()
  dry_run?: boolean;
}
```

`dto/index.ts`: agregar `export * from './release-legacy-locks.dto';`. `investiture.module.ts`: `providers: [InvestitureService, LegacyLockReleaseService, ExactSuperAdminWritePolicy]` (la política solo necesita `PrismaService`; no se importa `RbacModule` para no acoplar módulos).

- [ ] **Step 4:** Repetir el Step 2 → PASS.

- [ ] **Step 5: Ruta.** Prueba roja en `src/common/guards/permissions-metadata.spec.ts`:

```ts
  it('marks the legacy lock release as session-only (exact super-admin in the service)', () => {
    expect(
      Reflect.getMetadata(
        SKIP_PERMISSIONS_KEY,
        InvestitureController.prototype.releaseLegacyLocks,
      ),
    ).toBe(true);
  });
```

  (importar `SKIP_PERMISSIONS_KEY` de `../decorators/skip-permissions.decorator`). FAIL. Luego, en `investiture.controller.ts`, inyectar `private readonly legacyLockRelease: LegacyLockReleaseService` y agregar:

```ts
  @Post('admin/investiture/legacy-locks/release')
  @HttpCode(HttpStatus.OK)
  @SkipPermissions()
  @ApiOperation({
    summary:
      'Soltar locked_for_validation de expedientes de la vía anterior (solo super-admin; dry_run por defecto)',
  })
  @ApiResponse({ status: 200, description: 'Candidatos, omitidos por PENDING y liberados' })
  @ApiResponse({ status: 403, description: 'SUPER_ADMIN_WRITE_REQUIRED' })
  async releaseLegacyLocks(@Body() dto: ReleaseLegacyLocksDto, @Request() req) {
    const data = await this.legacyLockRelease.release(req.user.sub, dto);
    return { status: 'success', data };
  }
```

  con `import { SkipPermissions } from '../common/decorators/skip-permissions.decorator';`. PASS.

- [ ] **Step 6: Commit** — `feat(investiture): release legacy validation locks on demand`.

---

### Task B3.3: Suite PostgreSQL + HTTP de la fase 8 (desbloqueo)

**Files:** Create `test/investiture-legacy-shutdown-postgres.e2e-spec.ts`.

- [ ] **Step 1: Prueba roja.** Archivo completo (B4.3 le agrega un `describe` **antes** del de desbloqueo):

```ts
/**
 * Fase 8 — vía club → coordinación → campo apagada.
 * AppModule real sobre PostgreSQL descartable: JWT y permisos reales;
 * BetterAuth y el cron de year-cut simulados (bootstrapAnnualCycleApp).
 * El throttler corre con los límites de NODE_ENV=test: cada request espera 550 ms.
 */
import { randomUUID } from 'node:crypto';
import { readFileSync, statSync } from 'node:fs';
import { JwtService } from '@nestjs/jwt';
import type { Client } from 'pg';
import request from 'supertest';
import {
  bootstrapAnnualCycleApp,
  prepareAnnualCycleDatabase,
  withClient,
} from './helpers/annual-cycle-db.helper';
import {
  assertServerLogHasWarningMarker,
  requireInvestitureServerLogPath,
} from './helpers/investiture-server-log';
import {
  createBearerToken,
  createTestJwtService,
} from './helpers/rbac-test-helpers';

jest.setTimeout(240000);

const SUPER_ADMIN = '81818181-8181-4181-8181-818181818181';
const ADMIN = '82828282-8282-4282-8282-828282828282';
const OPEN = [
  'SUBMITTED_FOR_VALIDATION',
  'CLUB_APPROVED',
  'COORDINATOR_APPROVED',
  'FIELD_APPROVED',
  'APPROVED',
] as const;
type OpenStatus = (typeof OPEN)[number];

type Fixture = {
  open: Record<OpenStatus, number>;
  pendingLocked: number;
  legacyInvested: number;
  certificate: number;
  inProgress: number;
  certificateMember: string;
};

const pace = () => new Promise((resolve) => setTimeout(resolve, 550));

async function insertUser(client: Client, email: string, userId?: string) {
  const row = await client.query<{ user_id: string }>(
    userId
      ? `INSERT INTO users (user_id, email, name, active, approval_status)
         VALUES ($2, $1, 'Fase8', true, 'approved') RETURNING user_id`
      : `INSERT INTO users (email, name, active, approval_status)
         VALUES ($1, 'Fase8', true, 'approved') RETURNING user_id`,
    userId ? [email, userId] : [email],
  );
  return row.rows[0].user_id;
}

async function insertEnrollment(
  client: Client,
  input: {
    userId: string;
    classId: number;
    yearId: number;
    status: string;
    locked: boolean;
    kind?: 'OPERATIONAL' | 'HISTORICAL_CERTIFICATE';
  },
) {
  const row = await client.query<{ enrollment_id: number }>(
    `INSERT INTO enrollments (
       user_id, class_id, ecclesiastical_year_id, investiture_status,
       locked_for_validation, submitted_for_validation, record_kind, active
     )
     VALUES ($1, $2, $3, $4::investiture_status_enum, $5, $6,
             $7::enrollment_record_kind, true)
     RETURNING enrollment_id`,
    [
      input.userId,
      input.classId,
      input.yearId,
      input.status,
      input.locked,
      (OPEN as readonly string[]).includes(input.status),
      input.kind ?? 'OPERATIONAL',
    ],
  );
  return row.rows[0].enrollment_id;
}

describe('fase 8: vía anterior de investidura apagada (PostgreSQL + HTTP)', () => {
  let app: Awaited<ReturnType<typeof bootstrapAnnualCycleApp>>['app'];
  let prisma: Awaited<ReturnType<typeof bootstrapAnnualCycleApp>>['prisma'];
  let jwt: JwtService;
  let fx: Fixture;
  // Posición del log del servidor al empezar: solo se revisa lo que escribió esta suite.
  let serverLog: { path: string; offset: number };

  const bearer = (userId: string) => ({
    Authorization: `Bearer ${createBearerToken(jwt, userId)}`,
  });

  async function releaseLocks(userId: string, body: Record<string, unknown>) {
    await pace();
    return request(app.getHttpServer())
      .post('/api/v1/admin/investiture/legacy-locks/release')
      .set(bearer(userId))
      .send(body);
  }

  async function locks(ids: number[]) {
    const rows = await prisma.enrollments.findMany({
      where: { enrollment_id: { in: ids } },
      select: {
        enrollment_id: true,
        investiture_status: true,
        locked_for_validation: true,
        submitted_for_validation: true,
      },
      orderBy: { enrollment_id: 'asc' },
    });
    return rows;
  }

  beforeAll(async () => {
    const url = await prepareAnnualCycleDatabase();
    // Helper existente: falla si SACDIA_POSTGRES_SERVER_LOG falta o si el log no
    // es de este servidor (marcador WARNING). Sin eso un log vacío "pasaría".
    const logPath = requireInvestitureServerLogPath();
    const marker = `sacdia-pg-warning-${randomUUID()}`;
    await withClient(url, (client) =>
      client.query(`DO $$ BEGIN RAISE WARNING '${marker}'; END $$;`),
    );
    assertServerLogHasWarningMarker(logPath, marker);
    serverLog = { path: logPath, offset: statSync(logPath).size };
    fx = await withClient(url, async (client) => {
      await client.query(`
        INSERT INTO roles (role_name, description, role_category, active)
        VALUES ('super-admin', 'Super admin', 'GLOBAL', true),
               ('admin', 'Admin', 'GLOBAL', true)
        ON CONFLICT (role_name) DO NOTHING
      `);
      await insertUser(client, 'super@fase8.test', SUPER_ADMIN);
      await insertUser(client, 'admin@fase8.test', ADMIN);
      for (const [userId, role] of [
        [SUPER_ADMIN, 'super-admin'],
        [ADMIN, 'admin'],
      ] as const) {
        await client.query(
          `INSERT INTO users_roles (user_id, role_id, active)
           SELECT $1, role_id, true FROM roles WHERE role_name = $2`,
          [userId, role],
        );
      }
      const clubType = await client.query<{ club_type_id: number }>(
        `INSERT INTO club_types (name, active) VALUES ('Conquistadores F8', true)
         RETURNING club_type_id`,
      );
      const year = await client.query<{ year_id: number }>(
        `INSERT INTO ecclesiastical_years (start_date, end_date, active)
         VALUES ('2026-01-01', '2026-12-31', true) RETURNING year_id`,
      );
      const klass = await client.query<{ class_id: number }>(
        `INSERT INTO classes (name, active, club_type_id, minimum_age, min_duration_years, max_duration_years)
         VALUES ('Amigo F8', true, $1, 10, 1, 1) RETURNING class_id`,
        [clubType.rows[0].club_type_id],
      );
      const classId = klass.rows[0].class_id;
      const yearId = year.rows[0].year_id;

      const open = {} as Record<OpenStatus, number>;
      let n = 0;
      for (const status of OPEN) {
        const member = await insertUser(client, `m${(n += 1)}@fase8.test`);
        open[status] = await insertEnrollment(client, {
          userId: member, classId, yearId, status, locked: true,
        });
        await client.query(
          `INSERT INTO investiture_validation_history (enrollment_id, action, performed_by, comments)
           VALUES ($1, 'SUBMITTED', $2, 'expediente anterior')`,
          [open[status], ADMIN],
        );
      }
      const pendingMember = await insertUser(client, 'pending@fase8.test');
      const pendingLocked = await insertEnrollment(client, {
        userId: pendingMember, classId, yearId, status: 'CLUB_APPROVED', locked: true,
      });
      const req = await client.query<{ request_id: string }>(
        `INSERT INTO investiture_authorization_requests (club_section_id, ecclesiastical_year_id, created_by_id)
         VALUES (1, $1, $2) RETURNING request_id`,
        [yearId, ADMIN],
      );
      await client.query(
        `INSERT INTO investiture_authorization_people
           (request_id, user_id, class_id, enrollment_id, investiture_date, status, single_slot)
         VALUES ($1, $2, $3, $4, '2026-11-15', 'PENDING', false)`,
        [req.rows[0].request_id, pendingMember, classId, pendingLocked],
      );
      const legacyInvested = await insertEnrollment(client, {
        userId: await insertUser(client, 'invested@fase8.test'),
        classId, yearId, status: 'INVESTIDO', locked: true,
      });
      const certificateMember = await insertUser(client, 'certificate@fase8.test');
      const certificate = await insertEnrollment(client, {
        userId: certificateMember, classId, yearId, status: 'INVESTIDO',
        locked: true, kind: 'HISTORICAL_CERTIFICATE',
      });
      const inProgress = await insertEnrollment(client, {
        userId: await insertUser(client, 'new@fase8.test'),
        classId, yearId, status: 'IN_PROGRESS', locked: false,
      });
      return { open, pendingLocked, legacyInvested, certificate, inProgress, certificateMember };
    });

    const boot = await bootstrapAnnualCycleApp();
    app = boot.app;
    prisma = boot.prisma;
    jwt = createTestJwtService();
  });

  afterAll(async () => {
    if (app) await app.close();
  });

  describe('desbloqueo explícito', () => {
    it('refuses a global admin who is not super-admin and changes nothing', async () => {
      const before = await locks([...Object.values(fx.open), fx.pendingLocked]);
      const res = await releaseLocks(ADMIN, { dry_run: false });
      expect(res.status).toBe(403);
      expect(res.body.code).toBe('SUPER_ADMIN_WRITE_REQUIRED');
      expect(await locks([...Object.values(fx.open), fx.pendingLocked])).toEqual(before);
    });

    it('lists candidates by default and writes nothing', async () => {
      const res = await releaseLocks(SUPER_ADMIN, {});
      expect(res.status).toBe(200);
      const data = res.body.data;
      expect(data.dry_run).toBe(true);
      expect(data.candidates.map((row: { enrollment_id: number }) => row.enrollment_id).sort((a: number, b: number) => a - b))
        .toEqual([...Object.values(fx.open), fx.pendingLocked].sort((a, b) => a - b));
      expect(data.skipped_pending).toEqual([fx.pendingLocked]);
      expect(data.released).toEqual([]);
      expect(
        await prisma.investiture_validation_history.count({ where: { action: 'LEGACY_LOCK_RELEASED' } }),
      ).toBe(0);
    });

    it('releases only rows without PENDING, keeps every status and audits each one', async () => {
      const res = await releaseLocks(SUPER_ADMIN, { dry_run: false });
      expect(res.status).toBe(200);
      expect([...res.body.data.released].sort((a: number, b: number) => a - b)).toEqual(
        Object.values(fx.open).sort((a, b) => a - b),
      );
      expect(res.body.data.skipped_pending).toEqual([fx.pendingLocked]);

      for (const status of OPEN) {
        const row = await prisma.enrollments.findUniqueOrThrow({ where: { enrollment_id: fx.open[status] } });
        expect(row.investiture_status).toBe(status);
        expect(row.locked_for_validation).toBe(false);
        expect(row.submitted_for_validation).toBe(true);
        expect(
          await prisma.investiture_validation_history.findMany({
            where: { enrollment_id: fx.open[status], action: 'LEGACY_LOCK_RELEASED' },
            select: { performed_by: true },
          }),
        ).toEqual([{ performed_by: SUPER_ADMIN }]);
      }
      const untouched = await locks([fx.pendingLocked, fx.legacyInvested, fx.certificate]);
      expect(untouched.every((row) => row.locked_for_validation)).toBe(true);
      expect(
        await prisma.investiture_authorization_people.findFirstOrThrow({
          where: { enrollment_id: fx.pendingLocked },
          select: { status: true },
        }),
      ).toEqual({ status: 'PENDING' });
    });

    it('is idempotent', async () => {
      const res = await releaseLocks(SUPER_ADMIN, { dry_run: false });
      expect(res.status).toBe(200);
      expect(res.body.data.candidates.map((row: { enrollment_id: number }) => row.enrollment_id)).toEqual([fx.pendingLocked]);
      expect(res.body.data.released).toEqual([]);
      expect(
        await prisma.investiture_validation_history.count({ where: { action: 'LEGACY_LOCK_RELEASED' } }),
      ).toBe(OPEN.length);
    });
  });

  // Va al final: revisa todo lo que el servidor registró desde beforeAll.
  it('el servidor no registró ningún deadlock durante la suite', () => {
    const log = readFileSync(serverLog.path).subarray(serverLog.offset).toString('utf8');
    expect(log).not.toMatch(/deadlock detected/i);
  });
});
```

- [ ] **Step 2:** Con el clúster descartable de B3 aún sin la ruta (o con la ruta comentada), `--testPathPatterns investiture-legacy-shutdown-postgres` → FAIL 404. Con B3.1-B3.2 aplicados → PASS, incluido el último caso. La verificación de `deadlock detected` ya no es un `rg` manual: la suite la hace con `requireInvestitureServerLogPath` / `assertServerLogHasWarningMarker`, así que sin `SACDIA_POSTGRES_SERVER_LOG` falla con un mensaje claro en lugar de pasar sobre un log vacío.

- [ ] **Step 3: Commit** — `test(investiture): cover the legacy lock release on PostgreSQL`.

### Task B3.4: PR B3

- [ ] Unitarias de `src/investiture` y `src/common/guards`, la suite nueva, `tsc`, ESLint. PR apilado sobre B2, `type:feature`, `size:exception`, título `feat(investiture): add the explicit legacy lock release`. En la descripción: la migración nueva entra en la cadena pendiente de producción y no se aplica en Neon desde este PR.

---

### Task B4.1: `investidos_year` cuenta `APPROVED` o `INVESTIDO`

**Files:** Modify `src/clubs/clubs.service.ts:1473-1510`, `src/investiture/legacy-pipeline-write.guard.spec.ts` (Step 5); Test `src/clubs/clubs.service.spec.ts:2094-2125`.

- [ ] **Step 1: Prueba roja.** En `getClubOverview — investidos_year`, cambiar la expectativa:

```ts
      expect(mockPrismaService.enrollments.count).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            ecclesiastical_year_id: 10,
            investiture_status: { in: ['APPROVED', 'INVESTIDO'] },
            record_kind: 'OPERATIONAL',
            active: true,
          }),
        }),
      );
```

- [ ] **Step 2:** `node node_modules/jest/bin/jest.js --no-coverage --forceExit src/clubs/clubs.service.spec.ts -t investidos_year` → FAIL.
- [ ] **Step 3:** En `clubs.service.ts` (L1500-1508 en la base) el `where` queda así:

```ts
            where: {
              user_id: { in: userIds },
              ecclesiastical_year_id: activeYear.year_id,
              investiture_status: { in: ['APPROVED', 'INVESTIDO'] },
              record_kind: 'OPERATIONAL',
              active: true,
            },
```

  `record_kind: 'OPERATIONAL'` es necesario ahora que el conteo incluye `INVESTIDO`: las acreditaciones por certificado (`HISTORICAL_CERTIFICATE`) nacen `INVESTIDO` (`certificate-bulk-imports-application.service.ts:510-640`) y, si caen en el año eclesiástico activo, inflarían el embudo del club sin ser una investidura de este año. El comentario de L1473 pasa a «6. Count members whose class is completed (legacy APPROVED or INVESTIDO, operational records only) in the active ecclesiastical year…».
- [ ] **Step 4:** Repetir → PASS.
- [ ] **Step 5: Sacar la excepción temporal de la guarda (B2.3).** En `src/investiture/legacy-pipeline-write.guard.spec.ts` borrar la constante `UNTIL_B4_1` y su uso en el `continue`; correr `node node_modules/jest/bin/jest.js --no-coverage --forceExit src/investiture/legacy-pipeline-write.guard.spec.ts` → PASS (ya no hay `investiture_status: 'APPROVED'` en `clubs.service.ts`, y `investiture_status: { in: [...] }` no cumple la forma de escritura). Verificar con el `rg` de la Task B2.3 que solo queda `analytics/analytics.service.ts:560`.
- [ ] **Step 6: Commit** — `fix(clubs): count invested members in the club overview` (incluye el cambio de la guarda).

---

### Task B4.2: Regresión de los lectores de `APPROVED`

**Files:** Test `src/annual-folders/score-calculators/class-investiture-progress-score.spec.ts`, `src/validation/validation.service.spec.ts`, `src/club-role-eligibility/club-role-eligibility.service.spec.ts`.

- [ ] **Step 1: Pruebas** (pasan sin cambio de código; fijan la decisión 6):

```ts
  it('still counts legacy APPROVED rows next to INVESTIDO as completed', async () => {
    prisma.$queryRaw.mockResolvedValueOnce([{ completed: 1n, total: 2n }]);
    await svc.calc('enrollment-id', 1);
    const sql = (prisma.$queryRaw.mock.calls[0][0] as TemplateStringsArray).join('?');
    expect(sql).toContain("IN ('APPROVED', 'INVESTIDO')");
  });
```

```ts
describe('ValidationService eligibility keeps legacy APPROVED', () => {
  it('counts APPROVED and INVESTIDO enrollments as approved', async () => {
    const prisma = {
      system_config: { findUnique: jest.fn().mockResolvedValue(null) },
      enrollments: {
        findMany: jest.fn().mockResolvedValue([
          { enrollment_id: 1, investiture_status: 'APPROVED' },
          { enrollment_id: 2, investiture_status: 'INVESTIDO' },
          { enrollment_id: 3, investiture_status: 'IN_PROGRESS' },
        ]),
      },
      users_honors: {
        aggregate: jest.fn().mockResolvedValue({ _count: { user_honor_id: 0 } }),
      },
    };
    const service = new ValidationService(prisma as never, {} as never, {} as never);
    await expect(service.checkInvestmentEligibility('u1')).resolves.toMatchObject({
      detail: { classes: { total: 3, approved: 2 } },
    });
  });
});
```

Y en `club-role-eligibility.service.spec.ts`, dentro de `describe('evaluateGuideMajor')` (decisión 6 y O2: la historia de la vía vieja sigue dando elegibilidad a Guía Mayor, `club-role-eligibility.service.ts:13-19` y `:108-136`):

```ts
    it('keeps counting legacy APPROVED and the open chain statuses (phase 8)', async () => {
      findMany.mockResolvedValue([]);
      await service.evaluateGuideMajor(userId);
      const where = findMany.mock.calls[0][0].where;
      expect(where.OR).toEqual([
        {
          investiture_status: {
            in: [investiture_status_enum.INVESTIDO, investiture_status_enum.APPROVED],
          },
        },
        {
          active: true,
          investiture_status: {
            in: [
              investiture_status_enum.IN_PROGRESS,
              investiture_status_enum.SUBMITTED_FOR_VALIDATION,
              investiture_status_enum.CLUB_APPROVED,
              investiture_status_enum.COORDINATOR_APPROVED,
              investiture_status_enum.FIELD_APPROVED,
            ],
          },
          classes: { asset_code: 'GM-01', active: true },
        },
      ]);
    });
```

  Las pruebas existentes (`eligible with active enrollment %s` por cada estado de cadena, `eligible when APPROVED (any year)`) ya cubren el resultado; esta fija además la consulta, para que quitar un estado de la lista falle aquí y no pase en silencio. Pasa sin cambio de código.

- [ ] **Step 2:** `node node_modules/jest/bin/jest.js --no-coverage --forceExit src/annual-folders/score-calculators src/validation src/club-role-eligibility` → PASS.
- [ ] **Step 3: Commit** — `test(investiture): pin legacy APPROVED as completed in readers`.

---

### Task B4.3: Pruebas de la spec de fase 8 en PostgreSQL

**Files:** Modify `test/investiture-legacy-shutdown-postgres.e2e-spec.ts` (agregar el `describe` **antes** de `describe('desbloqueo explícito')`).

- [ ] **Step 1: Pruebas.**

```ts
  const retiredCalls = (id: number) =>
    [
      ['post', `/api/v1/investiture/enrollments/${id}/submit`, {}],
      ['post', `/api/v1/investiture/enrollments/${id}/club-approve`, {}],
      ['post', `/api/v1/investiture/enrollments/${id}/coordinator-approve`, {}],
      ['post', `/api/v1/investiture/enrollments/${id}/field-approve`, {}],
      ['post', `/api/v1/investiture/enrollments/${id}/invest`, {}],
      ['post', `/api/v1/investiture/enrollments/${id}/reject`, { reason: 'fase 8' }],
      ['post', '/api/v1/investiture/enrollments/bulk-approve', { action: 'invest', enrollment_ids: [id] }],
      ['post', '/api/v1/investiture/enrollments/bulk-reject', { enrollment_ids: [id], comments: 'fase 8' }],
      ['post', `/api/v1/enrollments/${id}/submit-for-validation`, {}],
      ['post', `/api/v1/enrollments/${id}/validate`, { action: 'APPROVED' }],
      ['post', `/api/v1/enrollments/${id}/investiture`, {}],
    ] as const;

  async function callRetired(method: 'post', url: string, body: object) {
    await pace();
    return request(app.getHttpServer())[method](url).set(bearer(ADMIN)).send(body);
  }

  async function callAnonymous(method: 'get' | 'post', url: string, body: object) {
    await pace();
    const call = request(app.getHttpServer())[method](url);
    return method === 'get' ? call : call.send(body);
  }

  async function legacySnapshot() {
    const ids = [...Object.values(fx.open), fx.pendingLocked, fx.legacyInvested, fx.certificate, fx.inProgress];
    return {
      rows: await locks(ids),
      history: await prisma.investiture_validation_history.count({ where: { enrollment_id: { in: ids } } }),
      people: await prisma.investiture_authorization_people.findMany({
        where: { enrollment_id: { in: ids } },
        select: { enrollment_id: true, status: true },
        orderBy: { enrollment_id: 'asc' },
      }),
      completed: await prisma.achievement_event_log.count({ where: { event_type: 'class.completed' } }),
    };
  }

  describe('vía retirada', () => {
    it.each([
      ['FIELD_APPROVED', () => fx.open.FIELD_APPROVED],
      ['un enrollment operativo nuevo', () => fx.inProgress],
    ])('%s no llega a INVESTIDO por ninguna ruta, alias ni operación masiva', async (_label, pick) => {
      const id = pick();
      const before = await legacySnapshot();
      for (const [method, url, body] of retiredCalls(id)) {
        const res = await callRetired(method, url, body);
        expect({ url, status: res.status, code: res.body.code }).toEqual({
          url,
          status: 410,
          code: 'INVESTITURE_LEGACY_PIPELINE_RETIRED',
        });
      }
      expect(await legacySnapshot()).toEqual(before);
      const row = await prisma.enrollments.findUniqueOrThrow({ where: { enrollment_id: id } });
      expect(row.investiture_status).not.toBe('INVESTIDO');
    });

    it('ValidationModule no mueve una clase', async () => {
      const validation = app.get(ValidationService);
      const before = await legacySnapshot();
      await expect(
        validation.submitForReview('class', fx.inProgress, ADMIN),
      ).rejects.toMatchObject({ code: 'INVESTITURE_LEGACY_PIPELINE_RETIRED' });
      await expect(
        validation.review('class', fx.open.SUBMITTED_FOR_VALIDATION, 'approved', ADMIN),
      ).rejects.toMatchObject({ code: 'INVESTITURE_LEGACY_PIPELINE_RETIRED' });
      expect(await legacySnapshot()).toEqual(before);
      expect(await prisma.validation_logs.count({ where: { entity_type: 'class' } })).toBe(0);
    });

    it('ningún expediente abierto se pierde ni se resuelve en silencio', async () => {
      const before = await legacySnapshot();
      const all = [...Object.values(fx.open), fx.pendingLocked];
      for (const [method, url, body] of [
        ['post', '/api/v1/investiture/enrollments/bulk-approve', { action: 'invest', enrollment_ids: all }],
        ['post', '/api/v1/investiture/enrollments/bulk-reject', { enrollment_ids: all, comments: 'fase 8' }],
        ...all.map((id) => ['post', `/api/v1/enrollments/${id}/validate`, { action: 'REJECTED', comments: 'x' }] as const),
      ] as const) {
        expect((await callRetired(method, url, body)).status).toBe(410);
      }
      const after = await legacySnapshot();
      expect(after).toEqual(before);
      for (const status of OPEN) {
        expect(after.rows.find((row) => row.enrollment_id === fx.open[status])).toMatchObject({
          investiture_status: status,
          locked_for_validation: true,
        });
      }
    });

    it('el historial viejo sigue leyéndose', async () => {
      const history = await app.get(InvestitureService).getHistory(fx.open.CLUB_APPROVED, ADMIN);
      expect(history.history).toEqual([
        expect.objectContaining({ action: 'SUBMITTED', comments: 'expediente anterior' }),
      ]);
    });

    it('un certificado histórico no se mezcla con la solicitud', async () => {
      const before = await legacySnapshot();
      for (const [method, url, body] of retiredCalls(fx.certificate).slice(4, 5)) {
        expect((await callRetired(method, url, body)).status).toBe(410);
      }
      expect(await legacySnapshot()).toEqual(before);
      expect(
        await prisma.investiture_authorization_people.count({ where: { enrollment_id: fx.certificate } }),
      ).toBe(0);
      await pace();
      const own = await request(app.getHttpServer())
        .get('/api/v1/investiture-history')
        .set(bearer(fx.certificateMember));
      expect(own.status).toBe(200);
      expect(own.body.data).toEqual([]);
    });

    it('sin sesión responde 401 y no 410: las rutas retiradas piden el JWT global, no permisos', async () => {
      const before = await legacySnapshot();
      const id = fx.open.FIELD_APPROVED;
      for (const [method, url, body] of [
        ['post', `/api/v1/investiture/enrollments/${id}/invest`, {}],
        ['post', `/api/v1/enrollments/${id}/validate`, { action: 'APPROVED' }],
        ['get', '/api/v1/investiture/pending', {}],
        ['get', '/api/v1/admin/investiture/config', {}],
      ] as const) {
        const res = await callAnonymous(method, url, body);
        expect({ url, status: res.status }).toEqual({ url, status: 401 });
      }
      expect(await legacySnapshot()).toEqual(before);
    });

    it('las lecturas retiradas también responden 410 con sesión (decisión O1)', async () => {
      for (const url of [
        '/api/v1/investiture/pending',
        '/api/v1/admin/investiture/config',
        '/api/v1/admin/investiture/config/7',
      ]) {
        await pace();
        const res = await request(app.getHttpServer()).get(url).set(bearer(ADMIN));
        expect({ url, status: res.status, code: res.body.code }).toEqual({
          url,
          status: 410,
          code: 'INVESTITURE_LEGACY_PIPELINE_RETIRED',
        });
      }
    });
  });
```

  Imports a agregar: `import { InvestitureService } from '../src/investiture/investiture.service';` y `import { ValidationService } from '../src/validation/validation.service';`. Presupuesto del throttler: 11 + 11 + 8 + 1 + 1 + 4 + 3 = 39 llamadas a 550 ms ≈ 21,5 s (más las 4 del desbloqueo de B3.3), con 18 llamadas como máximo por ventana de 10 s: debajo de 20 por 10 s y 100 por minuto.

- [ ] **Step 2:** Correr la suite → PASS (estas pruebas pasan sobre B1a-B3; si alguna ruta todavía escribiera, `legacySnapshot()` difiere). Verificación de que muerden: en una rama temporal, reponer el handler `markInvestidoLegacy` original en `InvestitureController` y quitar `investitureAlias` del controlador retirado → FAIL por 200/400 en lugar de 410. Descartar la rama.
- [ ] **Step 3: Commit** — `test(investiture): prove the legacy pipeline is off on PostgreSQL`.

---

### Task B4.4: `class.completed` sale solo de la autorización (IA-51)

**Files:** Create `src/investiture-requests/no-legacy-pipeline-import.arch.spec.ts`. **No se modifica** `test/investiture-authorization-requests-postgres.e2e-spec.ts`.

La garantía «una investidura emite un solo `class.completed`, sin historia de la vía vieja» **ya está cubierta en PostgreSQL** por `it('invests on the last window days without the old pipeline or a second event')` (L1158 de `test/investiture-authorization-requests-postgres.e2e-spec.ts`): presenta, resuelve con `service.resolve`, comprueba `INVESTIDO`, `investiture_date`, `investiture_validation_history` en 0, exactamente un evento `class.completed` para `MEMBER`, y que una segunda resolución falla con `INVESTITURE_REQUEST_ALREADY_RESOLVED` sin un segundo evento. Una prueba nueva que repitiera eso sería ruido. Lo único que faltaba era demostrar que **no queda otro escritor** que pueda emitir el evento, y eso lo cubren pruebas que no necesitan base:

- B2.1 Step 1: `Object.getOwnPropertyNames(InvestitureService.prototype)` es exactamente la lista que queda (sin `markInvestido`, `validateEnrollment` ni `bulkApproveEnrollments`).
- B2.3: la guarda de escrituras (nadie escribe `INVESTIDO` por la vía vieja ni sus estados).
- Step 1 de esta tarea: la autorización no depende de `src/investiture`.

- [ ] **Step 1: Prueba de arquitectura**

```ts
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

describe('investiture authorization does not depend on the legacy pipeline', () => {
  it('no file under src/investiture-requests imports src/investiture', () => {
    const dir = join(process.cwd(), 'src', 'investiture-requests');
    const offenders = readdirSync(dir)
      .filter((name) => name.endsWith('.ts'))
      .filter((name) =>
        /from '\.\.\/investiture\//.test(readFileSync(join(dir, name), 'utf8')),
      );
    expect(offenders).toEqual([]);
  });
});
```

- [ ] **Step 2:** Verificar que la suite existente sigue fijando la garantía después de B2.2 (que borra las dos carreras contra los escritores viejos, no este caso): `--testPathPatterns investiture-authorization-requests-postgres -t "invests on the last window days"` → PASS.
- [ ] **Step 3:** Unitaria del arch spec → PASS (`node node_modules/jest/bin/jest.js --no-coverage --forceExit src/investiture-requests/no-legacy-pipeline-import.arch.spec.ts`); suite completa `--testPathPatterns investiture-authorization-requests-postgres` → PASS.
- [ ] **Step 4: Commit** — `test(investiture): keep the authorization flow independent of the legacy pipeline`.

### Task B4.5: PR B4

- [ ] Unitarias completas, suites PostgreSQL `investiture-authorization-requests`, `investiture-legacy-shutdown` (verifica el log sola), `certificate-import`, `evidence-review-investiture-guard`, `district-investiture-pastors` y `helpers/investiture-server-log`, con 0 `deadlock detected` (`rg -c` manual en las que no verifican el log); `tsc`; ESLint. PR apilado sobre B3, `type:test` + `type:fix`, `size:exception`, título `test(investiture): cover the phase 8 shutdown guarantees`.

---

### Task B5: X-1 solo por bloqueo (decisión B5 del usuario)

**Se ejecuta siempre**, apilado sobre B4. Decisión del usuario del 2026-10-08 (tabla «Decisiones posteriores»): después del apagado, `enrollmentOnLegacyInvestiturePipeline` mira **solo** `locked_for_validation`.

**Files:** Modify `src/investiture-requests/investiture-request-lock.ts:121-139`; Create `src/investiture-requests/investiture-request-lock.spec.ts` (no existe); Modify `src/investiture-requests/investiture-authorization-requests.service.spec.ts`, `test/investiture-authorization-requests-postgres.e2e-spec.ts`, `test/investiture-legacy-shutdown-postgres.e2e-spec.ts`.

- [ ] **Step 1: Prueba roja**

```ts
import { enrollmentOnLegacyInvestiturePipeline } from './investiture-request-lock';

describe('enrollmentOnLegacyInvestiturePipeline after phase 8', () => {
  it.each(['SUBMITTED_FOR_VALIDATION', 'CLUB_APPROVED', 'COORDINATOR_APPROVED', 'FIELD_APPROVED', 'APPROVED'])(
    'blocks %s while locked and lets it through once released',
    (status) => {
      expect(enrollmentOnLegacyInvestiturePipeline({ investiture_status: status, locked_for_validation: true })).toBe(true);
      expect(enrollmentOnLegacyInvestiturePipeline({ investiture_status: status, locked_for_validation: false })).toBe(false);
      expect(enrollmentOnLegacyInvestiturePipeline({ investiture_status: status })).toBe(false);
    },
  );
});
```

- [ ] **Step 2:** `node node_modules/jest/bin/jest.js --no-coverage --forceExit src/investiture-requests/investiture-request-lock.spec.ts` → FAIL (los casos con `locked_for_validation: false` devuelven `true`).
- [ ] **Step 3: Implementación** en `investiture-request-lock.ts`: reemplazar `LEGACY_INVESTITURE_PIPELINE_STATUSES` y la función por

```ts
/**
 * Fase 8: la vía anterior ya no escribe; un expediente viejo bloquea la
 * solicitud nueva solo mientras conserva locked_for_validation.
 */
export function enrollmentOnLegacyInvestiturePipeline(enrollment: {
  investiture_status: string;
  locked_for_validation?: boolean | null;
}): boolean {
  return enrollment.locked_for_validation === true;
}
```

  `LEGACY_INVESTITURE_PIPELINE_STATUSES` **se borra**: `rg -n LEGACY_INVESTITURE_PIPELINE_STATUSES src test` solo la encuentra en este archivo. El parámetro `investiture_status` se conserva en la firma para no tocar los dos llamadores (`investiture-presentation-rules.ts:121` y `legacyBlocksResolution`, `investiture-authorization-requests.service.ts:1747`, que hereda el cambio y sigue devolviendo `false` para `FIELD_APPROVED`).
- [ ] **Step 4: Pruebas que dependían del estado.** Con la regla nueva, un enrollment `CLUB_APPROVED` **sin** candado ya no se bloquea. Verificado en la base: `addEnrollment` de la spec pone `locked_for_validation: false` por defecto (`investiture-authorization-requests.service.spec.ts:1115`) y el esquema también (`schema.prisma:1217`). Ajustar:
  - Unitaria `rejects adding a person locked by the old pipeline` (L2309; la fila 902 se siembra en L2311-2315): el `addEnrollment({ enrollment_id: 902, class_id: 8, investiture_status: 'CLUB_APPROVED' })` pasa a llevar `locked_for_validation: true`. Los demás casos de `LEGACY_PIPELINE_ACTIVE` ya fijan el candado (L2301, L2344, L2422, L3953, L4409, L4619).
  - Unitaria nueva en el mismo `describe`: un enrollment `CLUB_APPROVED` con `locked_for_validation: false` se presenta sin `INVESTITURE_REQUEST_LEGACY_PIPELINE_ACTIVE`.
  - PostgreSQL, `test/investiture-authorization-requests-postgres.e2e-spec.ts`: `seedMember` (L5541) crea el enrollment sin `locked_for_validation`, y tres casos lo usan con `'SUBMITTED_FOR_VALIDATION'` esperando `INVESTITURE_REQUEST_LEGACY_PIPELINE_ACTIVE` (`reports eligible, old-pipeline…` L5600, `R1 blocks…` L5675, `R3 leaves institutional…` L5721). Agregar al `data` del `create`: `locked_for_validation: status === 'SUBMITTED_FOR_VALIDATION',`.
  - Suite de fase 8, al final de `desbloqueo explícito`: leer el contexto de presentación de una fila liberada `CLUB_APPROVED` (`fx.open.CLUB_APPROVED`, ya soltada por el caso «releases only rows without PENDING») con `app.get(InvestitureAuthorizationRequestService).presentationContext(…)` y esperar que su candidato **no** traiga `blocked_code: 'INVESTITURE_REQUEST_LEGACY_PIPELINE_ACTIVE'`; y que `fx.pendingLocked` (sigue bloqueada y con `PENDING`) siga sin poder presentarse. Mismo `pace()` de 550 ms por llamada.
- [ ] **Step 5:** Unitaria + `--testPathPatterns 'investiture-authorization-requests-postgres|investiture-legacy-shutdown-postgres'` → PASS; `tsc`; ESLint.
- [ ] **Step 6: Commit** — `feat(investiture): let released legacy records join the authorization flow`. PR propio apilado sobre B4, `type:feature`, `size:exception`.

---

## Panel

### Task A1.1: Pantallas `/dashboard/investiture*` fuera del catálogo

**Files:** Test `src/lib/auth/screen-catalog/screen-catalog.legacy-investiture.test.ts`; Modify `src/lib/auth/screen-catalog/screens/investiture.ts`, `src/lib/auth/screen-catalog/screen-catalog.investiture.test.ts`, `src/lib/auth/permissions.ts`, `src/navigation/sidebar/sidebar-items.ts`.

- [ ] **Step 1: Prueba roja**

```ts
import { describe, expect, it } from "vitest";

import { collectSidebarLeaves, resolvePathEntry, SCREEN_CATALOG } from "./index";

const RETIRED_SCREENS = ["investiture-pending", "investiture-pipeline", "investiture-config"];
const RETIRED_PATHS = [
  "/dashboard/investiture",
  "/dashboard/investiture/pipeline",
  "/dashboard/investiture/config",
];

describe("fase 8 — pantallas de la vía anterior", () => {
  it("no registra las pantallas retiradas", () => {
    for (const id of RETIRED_SCREENS) {
      expect(SCREEN_CATALOG.some((screen) => screen.id === id), id).toBe(false);
    }
  });

  it("no resuelve sus rutas ni las muestra en el sidebar", () => {
    const urls = collectSidebarLeaves().map((leaf) => leaf.url);
    for (const path of RETIRED_PATHS) {
      expect(resolvePathEntry(path), path).toBeUndefined();
      expect(urls).not.toContain(path);
    }
  });

  it("conserva las pantallas de autorización", () => {
    expect(resolvePathEntry("/dashboard/investiture-requests")?.screenId).toBe(
      "investiture-requests",
    );
    expect(resolvePathEntry("/dashboard/investiture-settings")?.screenId).toBe(
      "investiture-settings",
    );
  });
});
```

- [ ] **Step 2:** `pnpm test src/lib/auth/screen-catalog/screen-catalog.legacy-investiture.test.ts` → FAIL.

- [ ] **Step 3: Implementación.**
  - `screens/investiture.ts`: borrar los objetos `investiture-pending`, `investiture-pipeline`, `investiture-config` y las constantes `INVESTITURE_CONFIG_ROLES`, `INVESTITURE_CONFIG_WRITE_ROLES`; quitar de los imports `INVESTITURE_CONFIG_CREATE`, `INVESTITURE_CONFIG_DELETE`, `INVESTITURE_CONFIG_READ`, `INVESTITURE_CONFIG_UPDATE`, `INVESTITURE_MARK_INVESTED`. `investitureQueueAccess`, `adminCoordValidateGate`, `INVESTITURE_QUEUE_ROLES` e `INVESTITURE_ADMIN_COORD_ROLES` siguen hasta A2 (los usa `enrollments`).
  - `permissions.ts`: borrar `INVESTITURE_MARK_INVESTED` e `INVESTITURE_CONFIG_*` (L176-180).
  - `sidebar-items.ts`: borrar el ítem `{ id: "investiture", title: "Investidura", … }` (L239-266) y los iconos que queden sin uso (`pnpm lint` los marca).
  - `screen-catalog.investiture.test.ts`: borrar los `describe` `investiture-pipeline`, `investiture-pending`, `investiture-config`.
  - `src/lib/i18n/client-messages.test.ts` **no se toca**. Su caso `/dashboard/investiture/pipeline` (L52-55) es autocontenido: `getClientMessageNamespacesForDashboardPath` ignora la ruta y devuelve `Object.keys(messages)` (`client-messages.ts`), y el `dashboardMessages` del propio test declara `investiture: {}` (L11), así que el caso pasa aunque se borre el namespace `investiture` de `messages/*.json`. Reemplazarlo por `investiture_requests` exigiría además agregar `investiture_requests: {}` a ese fixture; no aporta nada. La ruta del `pathname` es solo un texto de ejemplo.

- [ ] **Step 4:** `pnpm test src/lib/auth src/navigation src/lib/i18n` → PASS (`client-messages.test.ts` sin cambios). **Commit** — `feat(investiture): drop the legacy pipeline screens from the catalog`.

---

### Task A1.2: Borrar páginas, componentes, API y textos

- [ ] **Step 1:** Borrar:

```bash
git rm -r "src/app/(dashboard)/dashboard/investiture" src/components/investiture src/lib/api/investiture.ts
rg -n "components/investiture/|lib/api/investiture\"" src
```

  Esperado del `rg`: sin resultados.
- [ ] **Step 2: Textos** (sin salto final en el panel):

```bash
rg -n "\"investiture\"" src/navigation src/lib/auth   # debe quedar vacío antes de borrar nav.items.investiture
node - <<'EOF'
const fs = require('fs');
for (const locale of ['es', 'en', 'pt-BR', 'fr']) {
  const path = `messages/${locale}.json`;
  const m = JSON.parse(fs.readFileSync(path, 'utf8'));
  delete m.investiture;
  for (const key of ['investiture', 'investiture_pending', 'investiture_pipeline', 'investiture_config']) {
    delete m.nav.items[key];
  }
  fs.writeFileSync(path, JSON.stringify(m, null, 2));
}
EOF
node scripts/generate-messages-types.mjs
```

- [ ] **Step 3:** `pnpm test`, `pnpm lint`, `pnpm typecheck` → verdes (si `screen-title.test.ts` reclama una clave, es que una pantalla viva la usaba: restaurarla y anotarlo).
- [ ] **Step 4: Commit** — `feat(investiture): remove the legacy pipeline admin pages`.

### Task A1.3: PR A1

- [ ] PR contra `feat/investiture-authorization-screens`, `type:feature`, `size:exception`, título `feat(investiture): remove the legacy investiture panel`. Revisión por `git diff --stat` (casi todo borrado).

---

### Task A2.1: `/dashboard/enrollments` fuera

**Files:** Modify `src/lib/auth/screen-catalog/screens/investiture.ts`, `src/lib/auth/screen-catalog/screen-catalog.investiture.test.ts`, `src/lib/auth/screen-catalog/screen-catalog.legacy-investiture.test.ts`, `src/lib/auth/require-page-access.test.ts`, `src/navigation/sidebar/sidebar-items.ts`, `src/navigation/sidebar/filter-sidebar.test.ts`, `src/lib/dashboard/operations-home.ts`, `src/lib/dashboard/operations-home.test.ts`, `src/components/dashboard/operations-shortcuts.tsx`, `src/components/dashboard/operations-dashboard-view.tsx` (también la acción de la tarjeta «Formación»), `src/lib/auth/permissions.ts`, `messages/{es,en,pt-BR,fr}.json`; Delete `src/app/(dashboard)/dashboard/enrollments/`, `src/components/enrollments/enrollments-table.tsx`, `src/lib/api/enrollments.ts`.

- [ ] **Step 1: Pruebas rojas.**
  - En `screen-catalog.legacy-investiture.test.ts`: agregar `"enrollments"` a `RETIRED_SCREENS` y `"/dashboard/enrollments"` a `RETIRED_PATHS`.
  - En `require-page-access.test.ts` reemplazar los tres casos de `enrollments` (L141-166) por:

```ts
  it("no longer opens the retired enrollments queue", () => {
    expect(
      canAccessDashboardPath(buildUser(["admin"], ["investiture:read"]), "/dashboard/enrollments"),
    ).toBe(false);
  });
```

  - En `filter-sidebar.test.ts` reemplazar los tres casos de «Inscripciones» (L84-115) por:

```ts
  it("never shows the retired enrollments queue", () => {
    const filtered = filterSidebarItems(sidebarItems, {
      isSuperAdmin: true,
      canAny: () => true,
      canAll: () => true,
      hasAnyRole: () => true,
    });
    expect(collectTitles(filtered)).not.toContain("Inscripciones");
  });
```

  - En `operations-home.test.ts`:

```ts
  it("has no shortcut to the retired enrollments queue", () => {
    expect(OPERATIONS_SHORTCUTS.map((shortcut) => shortcut.id)).not.toContain("enrollments");
  });
```

  (importar `OPERATIONS_SHORTCUTS`).
- [ ] **Step 2:** `pnpm test src/lib/auth src/navigation src/lib/dashboard` → FAIL.
- [ ] **Step 3: Implementación.**
  - `screens/investiture.ts`: borrar la pantalla `enrollments`, `investitureQueueAccess`, `adminCoordValidateGate`, `INVESTITURE_QUEUE_ROLES`, `INVESTITURE_ADMIN_COORD_ROLES` e imports `INVESTITURE_READ`, `INVESTITURE_VALIDATE`. `screen-catalog.investiture.test.ts`: borrar `describe("enrollments")`. `permissions.ts`: borrar `INVESTITURE_READ` e `INVESTITURE_VALIDATE`.
  - `sidebar-items.ts`: borrar la hoja `{ id: "enrollments", title: "Inscripciones", url: "/dashboard/enrollments", … }` (L143-149).
  - `operations-home.ts`: quitar `"enrollments"` de `OperationsShortcutId` y su entrada de `OPERATIONS_SHORTCUTS`. `operations-shortcuts.tsx`: quitar `enrollments: ClipboardList` (y el import si queda sin uso). `operations-dashboard-view.tsx` L281: quitar `enrollments: tHome("shortcuts.enrollments"),`. **Además** la tarjeta «Formación» tiene un botón al mismo destino: quitar `const enrollmentsHref = firstAccessibleHref(user, ["/dashboard/enrollments"]);` (L54) y el bloque `{enrollmentsHref ? (<CardAction>…{tHome("formationAction")}…</CardAction>) : null}` (L178-184). Si queda, `canAccessDashboardPath` devuelve `true` para cualquier ruta cuando el usuario es super-admin (`require-page-access.ts:24-26`), así que ese usuario vería «Ver inscripciones» enlazando a una página borrada (404); para los demás roles el botón simplemente no se mostraría. `CardAction`, `Button` y `Link` **siguen importados**: los usa la tarjeta de honores (L202-206). `tBento("groups.formationDescription", { enrollments: …, people: … })` (L174) es un parámetro de texto, no la ruta: se queda.
  - `git rm -r "src/app/(dashboard)/dashboard/enrollments" src/components/enrollments/enrollments-table.tsx src/lib/api/enrollments.ts` (si `src/components/enrollments/` queda vacío, se va con él).
  - Textos: borrar el namespace raíz `enrollments`, `dashboardHub.operations.home.shortcuts.enrollments` y la clave huérfana `dashboardHub.operations.home.formationAction` ("Ver inscripciones" / "Open enrollments" / "Voir les inscriptions" / "Ver inscrições"; `rg -n formationAction src messages` solo encuentra el uso quitado más las 4 traducciones y `messages.d.ts`) en los 4 idiomas. **No** borrar `nav.items.enrollments` (es el `titleKey` de `annual_continuations`, `screens/clubs.ts:103`). Regenerar tipos.

```bash
node - <<'EOF'
const fs = require('fs');
for (const locale of ['es', 'en', 'pt-BR', 'fr']) {
  const path = `messages/${locale}.json`;
  const m = JSON.parse(fs.readFileSync(path, 'utf8'));
  delete m.enrollments;
  delete m.dashboardHub.operations.home.shortcuts.enrollments;
  delete m.dashboardHub.operations.home.formationAction; // huérfana: solo la usaba el botón quitado
  fs.writeFileSync(path, JSON.stringify(m, null, 2));
}
EOF
node scripts/generate-messages-types.mjs
```

- [ ] **Step 4:** `pnpm test`, `pnpm lint`, `pnpm typecheck` → verdes. **Commit** — `feat(investiture): remove the legacy enrollments queue`.
- [ ] **Step 5:** PR apilado sobre A1, `size:exception`, título `feat(investiture): remove the legacy enrollments queue from the panel`.

---

### Task A3.1: Validaciones de club sin pestaña de módulos

**Files:** Create `src/components/clubs/validations/validation-tabs.ts` + `.test.ts`; Modify `clubs-validations-client.tsx`, `src/app/(dashboard)/dashboard/clubs/validations/page.tsx`, `src/lib/dashboard/operations-home.ts` + test, `src/components/validation/validation-review-dialog.test.tsx`, `src/components/validation/validation-history-dialog.test.tsx`, `src/lib/api/validation.ts`.

- [ ] **Step 1: Pruebas rojas.** `validation-tabs.test.ts`:

```ts
import { describe, expect, it } from "vitest";

import { CLUBS_VALIDATION_TABS, resolveClubsValidationTab } from "./validation-tabs";

describe("clubs validation tabs", () => {
  it("has no class modules tab", () => {
    expect(CLUBS_VALIDATION_TABS).toEqual(["honors", "sections", "certificates"]);
  });

  it("sends old ?tab=modules links to class sections", () => {
    expect(resolveClubsValidationTab("modules")).toBe("sections");
  });

  it("falls back to honors", () => {
    expect(resolveClubsValidationTab(undefined)).toBe("honors");
    expect(resolveClubsValidationTab("nope")).toBe("honors");
    expect(resolveClubsValidationTab("certificates")).toBe("certificates");
  });
});
```

  En `operations-home.test.ts`:

```ts
  it("sends the class queue to class section evidence", () => {
    expect(OPERATIONS_QUEUE_HREFS.classes).toBe("/dashboard/clubs/validations?tab=sections");
  });
```

- [ ] **Step 2:** `pnpm test src/components/clubs/validations src/lib/dashboard` → FAIL.
- [ ] **Step 3: Implementación.** `validation-tabs.ts`:

```ts
export type ClubsValidationTab = "honors" | "sections" | "certificates";

export const CLUBS_VALIDATION_TABS: ClubsValidationTab[] = [
  "honors",
  "sections",
  "certificates",
];

/** `modules` fue la cola de clase de la vía anterior (fase 8). */
const LEGACY_TAB_ALIASES: Record<string, ClubsValidationTab> = {
  modules: "sections",
};

export function resolveClubsValidationTab(raw: string | undefined): ClubsValidationTab {
  if (!raw) return "honors";
  if (LEGACY_TAB_ALIASES[raw]) return LEGACY_TAB_ALIASES[raw];
  return CLUBS_VALIDATION_TABS.includes(raw as ClubsValidationTab)
    ? (raw as ClubsValidationTab)
    : "honors";
}
```

  - `clubs-validations-client.tsx`: importar `ClubsValidationTab` y `CLUBS_VALIDATION_TABS` de `./validation-tabs` (re-exportar el tipo: `export type { ClubsValidationTab } from "./validation-tabs";`), borrar el tipo y `TAB_VALUES` locales, la prop `initialModules`, el `TabsTrigger value="modules"`, el `TabsContent value="modules"` y el icono `Layers`; `safeTab` usa `CLUBS_VALIDATION_TABS`.
  - `page.tsx`: `readTab` pasa a `resolveClubsValidationTab(Array.isArray(raw.tab) ? raw.tab[0] : raw.tab)`; borrar `VALID_TABS`, `modules`, la llamada `getPendingValidations({ entity_type: "class" })`, el manejo de `modulesResult` y la prop `initialModules`.
  - `operations-home.ts`: `classes: "/dashboard/clubs/validations?tab=sections",`.
  - `validation.ts`: borrar `submitValidation` y `SubmitValidationPayload` (sin llamadores: `rg -n "submitValidation" src`).
  - Tests de diálogos: el `entityType` por defecto pasa de `"class"` a `"honor"` (`validation-review-dialog.test.tsx` L93 y la expectativa L182; `validation-history-dialog.test.tsx` L128).
  - Textos: borrar `clubs.pages.validations.tabs.modules` y `clubs.pages.validations.errors.modules` en los 4 idiomas y regenerar tipos (mismo patrón de `node -` de A2).
- [ ] **Step 4:** `pnpm test src/components src/lib` → PASS. **Commit** — `feat(validation): drop the class modules queue from club validations`.

---

### Task A3.2: Guarda del panel

**Files:** Create `src/lib/api/legacy-investiture-endpoints.guard.test.ts`.

- [ ] **Step 1: Prueba**

```ts
import { readdirSync, readFileSync } from "node:fs";
import { join, relative } from "node:path";

import { describe, expect, it } from "vitest";

const SRC = join(process.cwd(), "src");
const FORBIDDEN = [
  /\/investiture\/pending/,
  /submit-for-validation/,
  /\/investiture\/enrollments\//,
  /\/admin\/investiture\/config/,
  /\/enrollments\/\$\{[^}]+\}\/(validate|investiture|investiture-history)["'`]/,
  /getPendingValidations\(\{\s*entity_type:\s*"class"/,
  /<ValidationQueuePanel\s+entityType="class"/,
  /\/dashboard\/enrollments(?![\w-])/, // pantalla borrada en A2: ningún enlace, atajo ni botón vuelve a ella
];

function files(directory: string): string[] {
  return readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) return files(path);
    return /\.(ts|tsx)$/.test(entry.name) && !/\.test\.(ts|tsx)$/.test(entry.name) ? [path] : [];
  });
}

describe("fase 8 — el panel no llama la vía anterior", () => {
  it("no source file calls a retired endpoint", () => {
    const offenders: string[] = [];
    for (const path of files(SRC)) {
      readFileSync(path, "utf8")
        .split("\n")
        .forEach((line, index) => {
          if (FORBIDDEN.some((pattern) => pattern.test(line))) {
            offenders.push(`${relative(SRC, path)}:${index + 1}`);
          }
        });
    }
    expect(offenders).toEqual([]);
  });
});
```

- [ ] **Step 2:** `pnpm test src/lib/api/legacy-investiture-endpoints.guard.test.ts` → PASS. Verificar que muerde agregando temporalmente `const x = "/investiture/pending";` a `src/lib/api/validation.ts` → FAIL; quitarlo.
- [ ] **Step 3: Commit** — `test(investiture): guard the panel against legacy pipeline calls`.

### Task A3.3: Verificación y paridad

- [ ] `pnpm test`, `pnpm lint`, `pnpm typecheck`; `node scripts/generate-messages-types.mjs` sin diferencias (`git status --short src/i18n/messages.d.ts` vacío).
- [ ] Paridad con la app: `SACDIA_APP_DIR=/private/tmp/sacdia-app-ui pnpm test src/lib/auth/screen-catalog/screen-catalog.app.test.ts` → PASS sin tocar el fixture (decisión 9c).
- [ ] PR apilado sobre A2, `size:exception`, título `feat(validation): retire the class validation queue`.

---

## App

### Task P1.1: Mover el extractor de listas

**Files:** Modify `lib/features/investiture_requests/data/models/json_parsing.dart`, `lib/features/investiture_requests/data/datasources/investiture_requests_remote_data_source.dart`, `lib/features/investiture/data/datasources/investiture_remote_data_source.dart`, `test/features/investiture/investiture_history_parsing_test.dart` (solo el import); Create `test/features/investiture_requests/json_parsing_test.dart`.

- [ ] **Step 1: Prueba roja**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sacdia_app/features/investiture_requests/data/models/json_parsing.dart';

void main() {
  group('extractInvestitureListFromResponse', () {
    test('reads a bare list', () {
      expect(extractInvestitureListFromResponse([1, 2], 'items'), [1, 2]);
    });

    test('reads data.<key> from the success envelope', () {
      expect(
        extractInvestitureListFromResponse({
          'status': 'success',
          'data': {'history': [1]},
        }, 'history'),
        [1],
      );
    });

    test('reads data as a list and data.items', () {
      expect(extractInvestitureListFromResponse({'data': [3]}, 'x'), [3]);
      expect(
        extractInvestitureListFromResponse({'data': {'items': [4]}}, 'x'),
        [4],
      );
    });

    test('returns an empty list for anything else', () {
      expect(extractInvestitureListFromResponse('nope', 'x'), isEmpty);
    });
  });
}
```

- [ ] **Step 2:** `flutter test test/features/investiture_requests/json_parsing_test.dart` → FAIL (no está en `json_parsing.dart`).
- [ ] **Step 3:** Mover la función tal cual desde `lib/features/investiture/data/datasources/investiture_remote_data_source.dart:311-332` al final de `json_parsing.dart`:

```dart
/// Extrae una lista de una respuesta que puede venir como lista, como
/// `{data: [...]}`, `{data: {<nestedKey>: [...]}}` o `{data: {items: [...]}}`.
List<dynamic> extractInvestitureListFromResponse(
  dynamic raw,
  String nestedKey,
) {
  if (raw is List) return raw;

  if (raw is Map) {
    final directNested = raw[nestedKey];
    if (directNested is List) return directNested;

    final data = raw['data'];
    if (data is List) return data;
    if (data is Map) {
      final nested = data[nestedKey];
      if (nested is List) return nested;
      final items = data['items'];
      if (items is List) return items;
    }
  }

  return const [];
}
```

  En el datasource nuevo, reemplazar el import del feature viejo (L6-7) por el `json_parsing.dart` que ya importa (L12). En el datasource viejo, borrar la función e importar `json_parsing.dart` (se borra entero en P2).

  **Que no se rompa lo que sigue compilando entre P1 y P2.** `test/features/investiture/investiture_history_parsing_test.dart` hoy importa `extractInvestitureListFromResponse` desde `investiture_remote_data_source.dart` (L2) y la llama en L8; un `import` solo expone lo que el archivo declara, así que al mover la función ese test **deja de compilar** (`flutter test` completo en rojo hasta P2, que borra el archivo). Se actualiza ahora, en el mismo commit: reemplazar su línea 2 por `import 'package:sacdia_app/features/investiture_requests/data/models/json_parsing.dart';`. Los otros imports del test (`InvestitureHistoryEntryModel`, `InvestitureAction`) siguen vivos hasta P2.2, que lo borra junto con el feature.
- [ ] **Step 4:** `flutter test test/features/investiture_requests/ test/features/investiture/` → PASS (el test viejo de historial ahora usa la función desde su sitio nuevo). `flutter analyze` → sin issues nuevos. **Commit** — `refactor(investiture): move the list extractor into the authorization feature`.

---

### Task P1.2: Detalle de clase sin tarjeta legada

**Files:** Modify `lib/features/classes/presentation/views/class_detail_with_progress_view.dart`, `test/features/classes/presentation/class_detail_own_investiture_test.dart`.

- [ ] **Step 1: Prueba roja.** En el test, borrar los grupos `legacy status while the old pipeline is still active` y `viewing a member (legacy flow stays until phase 8)`, y el caso `keeps informing about a legacy validation in flight`. Agregar:

```dart
  group('after phase 8', () {
    const legacyLabels = {
      'SUBMITTED_FOR_VALIDATION': 'Enviado a validación',
      'CLUB_APPROVED': 'Aprobado por el club',
      'COORDINATOR_APPROVED': 'Aprobado por coordinador',
      'FIELD_APPROVED': 'Aprobado por campo',
      'APPROVED': 'Aprobado',
      'REJECTED': 'Observada',
    };

    for (final entry in legacyLabels.entries) {
      testWidgets('${entry.key} shows no legacy card in the own view',
          (tester) async {
        await _pump(tester, legacyStatus: entry.key);

        expect(find.text(entry.value), findsNothing);
        expect(find.text(_legacySend), findsNothing);
      });
    }

    testWidgets('a director viewing a member gets no legacy send action',
        (tester) async {
      await _pump(tester, legacyStatus: 'IN_PROGRESS', targetUserId: 'u99');

      expect(find.text(_legacySend), findsNothing);
      expect(find.text(_legacyReady), findsNothing);
    });

    testWidgets('an INVESTIDO class without an authorization entry shows the badge',
        (tester) async {
      await _pump(tester, legacyStatus: 'INVESTIDO');

      expect(find.text('Investido'), findsOneWidget);
    });

    testWidgets('a member viewed by the board also shows the badge',
        (tester) async {
      await _pump(tester, legacyStatus: 'INVESTIDO', targetUserId: 'u99');

      expect(find.text('Investido'), findsOneWidget);
    });

    testWidgets('the authorization entry replaces the badge', (tester) async {
      await _pump(
        tester,
        legacyStatus: 'INVESTIDO',
        history: [_entry(PersonStatus.invested)],
      );

      // Solo la insignia de la tarjeta de autorización.
      expect(find.text('Investido'), findsOneWidget);
      expect(
        find.text(
          'El camino rindió fruto. Ya estás investido, y esta noticia es para celebrarla.',
        ),
        findsOneWidget,
      );
    });
  });
```

- [ ] **Step 2:** `flutter test test/features/classes/presentation/class_detail_own_investiture_test.dart` → FAIL (la tarjeta legada sigue).
- [ ] **Step 3: Implementación** en `class_detail_with_progress_view.dart`:
  - Borrar `_submitInvestiture` (L283-326), en `build` las variables `showInvestitureCard`, `clubContextAsync`, `submitState` (L349-363) y el bloque `if (showInvestitureCard) _InvestitureCompletionCard(...)` (L387-402); borrar `_shouldShowInvestitureCard`, `_shouldShowLegacyInvestitureCard`, `_canSubmitInvestiture`, `_isInvestitureReviewer`, `_InvestitureCompletionCard`, `_InvestitureStatusRow` y `_InvestitureCardStyle` (L523-828) y el import de `investiture/presentation/providers/investiture_providers.dart`. `_investitureStatusOf` y el import de `investiture_status.dart` se quedan.
  - En `build`, después de `awaitingOwnHistory`:

```dart
    // `investitureStatus` ya existe arriba: `_investitureStatusOf(classData)`.
    final showInvestedBadge =
        investitureStatus == InvestitureStatus.investido &&
            !hasOwnAuthorization &&
            !awaitingOwnHistory;
```

  y debajo de `if (isOwnView) OwnInvestitureCard(classId: widget.classId),`:

```dart
                  if (showInvestedBadge) const _EnrollmentInvestedBadge(),
```

  - Al final del archivo:

```dart
/// «Investido» para una inscripción ya investida que no tiene entrada del flujo
/// de autorización (acreditación por certificado o investidura de la vía
/// anterior). Solo lectura: no ofrece envío ni historial.
class _EnrollmentInvestedBadge extends StatelessWidget {
  const _EnrollmentInvestedBadge();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SacBadge.success(
          label: tr('investiture.status.investido'),
          icon: HugeIcons.strokeRoundedCheckmarkCircle02,
        ),
      ),
    );
  }
}
```

  (import `../../../../core/widgets/sac_badge.dart` si no está; `flutter analyze` marca los imports que sobran, p. ej. `SacDialog`, `ClubRoleNames`, `clubContextProvider` si ya no se usan).
- [ ] **Step 4:** Repetir el Step 2 → PASS. `flutter test test/hugeicons_guard_test.dart` → PASS. `flutter analyze` → sin issues nuevos.
- [ ] **Step 5: Commit** — `feat(investiture): drop the legacy status card from class detail`.
- [ ] **Step 6:** PR contra `feat/investiture-authorization-app`, `size:exception`, título `feat(investiture): stop the legacy investiture flow in class detail`.

---

### Task P2.1: Guarda de la app

**Files:** Create `test/legacy_investiture_pipeline_guard_test.dart`.

- [ ] **Step 1: Prueba roja**

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _forbidden = <RegExp>[
  RegExp(r'submit-for-validation'),
  RegExp(r'/investiture/pending'),
  RegExp(r'\$\{ApiEndpoints\.investiture\}'),
  RegExp(r"enrollments\}/\$\w+/(validate|investiture|investiture-history)'"),
  RegExp(r'features/investiture/(data|presentation)/'),
  RegExp(r'ValidationEntityType\.classProgress'),
];

void main() {
  test('the app no longer reaches the retired investiture pipeline', () {
    final root = Directory.current.path;
    final offenders = <String>[];
    for (final entity in Directory('$root/lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trimLeft();
        if (line.startsWith('//')) continue;
        if (_forbidden.any((pattern) => pattern.hasMatch(line))) {
          offenders.add('${entity.path.substring(root.length + 1)}:${i + 1}');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
```

- [ ] **Step 2:** `flutter test test/legacy_investiture_pipeline_guard_test.dart` → FAIL (router, coordinator hub, feature viejo, enum).

---

### Task P2.2: Borrar el feature viejo y sus puntos de entrada

- [ ] **Step 1: Borrar archivos**

```bash
git rm -r lib/features/investiture/data lib/features/investiture/presentation \
  lib/features/investiture/domain/repositories \
  lib/features/investiture/domain/entities/investiture_history_cluster.dart \
  lib/features/investiture/domain/entities/investiture_history_entry.dart \
  lib/features/investiture/domain/entities/investiture_member.dart \
  lib/features/investiture/domain/entities/investiture_pending.dart \
  test/features/investiture/investiture_history_cluster_test.dart \
  test/features/investiture/investiture_history_parsing_test.dart
eza -T lib/features/investiture
```

  Esperado: solo `domain/entities/investiture_status.dart`. `test/features/investiture/investiture_status_test.dart` se queda.
- [ ] **Step 2: Puntos de entrada.**
  - `router.dart`: borrar imports L26-27 y las dos `GoRoute` de `RouteNames.investiturePendingList` y `RouteNames.investitureHistory` (L763-786).
  - `route_names.dart`: borrar `investiturePendingList`, `investitureHistory` (L80-82) e `investitureHistoryPath` (L153-154).
  - `api_endpoints.dart` L70: borrar `investiture`.
  - `coordinator_hub_view.dart`: borrar el `_NavCard` de `coordinator.nav.investitures_*` y el `SizedBox(height: 10)` que lo sigue (L139-147).
  - `push_notification_service.dart` L812: borrar `RouteNames.investiturePendingList,`.
  - `validation.dart`: `enum ValidationEntityType { honor }` y el `switch` de `slug` queda con `case ValidationEntityType.honor: return 'honor';`.
- [ ] **Step 3: Textos** (con salto final):

```bash
node - <<'EOF'
const fs = require('fs');
for (const locale of ['es', 'en', 'fr', 'pt-BR']) {
  const path = `assets/translations/${locale}.json`;
  const m = JSON.parse(fs.readFileSync(path, 'utf8'));
  for (const key of ['errors', 'history', 'pending', 'submit']) delete m.investiture[key];
  delete m.coordinator.nav.investitures_title;
  delete m.coordinator.nav.investitures_subtitle;
  fs.writeFileSync(path, JSON.stringify(m, null, 2) + '\n');
}
EOF
rg -n "'investiture\.(errors|history|pending|submit)\." lib
```

  Esperado del `rg`: sin resultados (`investiture.status.*` se queda: lo usan rankings, la tarjeta propia y la insignia).
- [ ] **Step 4:** `flutter test test/legacy_investiture_pipeline_guard_test.dart` → PASS. `flutter test` completo y `flutter analyze` → verdes.
- [ ] **Step 5: Commit** — `feat(investiture): remove the legacy investiture feature from the app`.
- [ ] **Step 6:** Paridad desde el panel: `cd /private/tmp/sacdia-admin-ui && SACDIA_APP_DIR=/private/tmp/sacdia-app-ui pnpm test src/lib/auth/screen-catalog/screen-catalog.app.test.ts` → PASS; `flutter test test/core/authorization/` → PASS. Ni `kAppScreenCatalog` ni el snapshot cambian.
- [ ] **Step 7:** PR apilado sobre P1, `size:exception`, título `feat(investiture): retire the legacy investiture screens in the app`.

---

## Docs

### Task D1: Contratos y estado

**Files** (repo raíz, rama `docs/investiture-ui-plans` o la que el usuario indique):

- [ ] `docs/api/ENDPOINTS-LIVE-REFERENCE.md` §`investiture` (L1420-1446): el párrafo de L1422 dice que las 17 rutas responden HTTP 410 `INVESTITURE_LEGACY_PIPELINE_RETIRED` sin permisos ni roles, y que el historial y `expire-overdue` siguen. Cada fila retirada cambia «Uso» a «**Retirada (fase 8): 410**». Fila nueva: `POST /api/v1/admin/investiture/legacy-locks/release` — JWT; `super-admin` exacto en el servicio; cuerpo `{ dry_run?: boolean = true }`; respuesta `{ dry_run, candidates[], skipped_pending[], released[] }`; deja `LEGACY_LOCK_RELEASED` en `investiture_validation_history`. L1082: quitar la lista de escrituras de la vía anterior (ya no existen) y decir que responden 410. L1847 (`/validation/submit`) y la fila de `review`: `entity_type` `class` → 410; `GET /validation/pending` devuelve `classes: []`.
- [ ] `docs/api/FRONTEND-INTEGRATION-GUIDE.md`: cómo tratar el 410 (mostrar `message`, no reintentar) y que el panel y la app ya no llaman esas rutas; que las lecturas `GET /investiture/pending` y `GET /admin/investiture/config*` también responden 410 (O1); que el `message` llega en español a las apps viejas porque no mandan `Accept-Language` (O4, documentado, no corregido); que una app vieja muestra `LEGACY_LOCK_RELEASED` como «Enviado para validación» en el historial (O5); y que `POST /validation/submit` y `/validation/:entityType/:entityId/review` conservan `validation:submit` / `validation:review`, de modo que sin esos permisos la respuesta es 403 antes que el 410 de `class`.
- [ ] `docs/features/validacion-investiduras.md`: «Estado» del encabezado → la vía club → coordinación → campo está apagada; la sección «Preparación de fase 8» pasa a «Fase 8 — apagado» con rutas retiradas (410), pantallas borradas (incluida `/dashboard/enrollments` y la pestaña «Módulos»), el desbloqueo aprobado ya implementado y cómo correrlo (dry run primero, con la migración ya aplicada en ese entorno; criterio de candidatos sin filtro por `active`), `APPROVED` sigue contando como completada (también en la elegibilidad de Guía Mayor), `investidos_year` cuenta `APPROVED` o `INVESTIDO` operativos, y X-1 (`enrollmentOnLegacyInvestiturePipeline`) mira solo `locked_for_validation` (decisión B5). «Implementacion completada» y «Que existe» se reescriben a lo que queda (historial, `expire-overdue`, desbloqueo).
- [ ] `docs/plans/2026-09-28-investidura-autorizacion.md` §«Fase 8»: «Estado de esta entrega» con fecha, PRs y lo que falta (aplicar migraciones en producción, correr el desbloqueo por entorno con aprobación).
- [ ] `docs/features/rbac.md` y `docs/features/auth/RBAC-ENFORCEMENT-MATRIX.md`: `investiture:submit`, `investiture:validate`, `investiture:mark_invested` e `investiture_config:*` quedan inertes (se conservan en seeds y base); `rg -n "investiture" docs/features/auth/RBAC-ENFORCEMENT-MATRIX.md` confirma si la matriz las listaba.
- [ ] `docs/features/aprobaciones-masivas.md` L15 y `docs/canon/runtime-validation.md` L81/L100: rutas retiradas.
- [ ] `docs/database/SCHEMA-REFERENCE.md` (L727) y `docs/database/schema.prisma`: valor `LEGACY_LOCK_RELEASED`.
- [ ] **Commit** — `docs(investiture): record the legacy pipeline shutdown`.

---

## Verificación integral

- [ ] Backend: unitarias completas; suites PostgreSQL `investiture-legacy-shutdown`, `investiture-authorization-requests`, `certificate-import`, `certificate-import-journey`, `evidence-review-investiture-guard`, `district-investiture-pastors`, `helpers/investiture-server-log` con 0 `deadlock detected`; e2e HTTP `test/investiture.e2e-spec.ts`; `tsc`; ESLint.
- [ ] Panel: `pnpm test`, `pnpm lint`, `pnpm typecheck`, paridad con la app.
- [ ] App: `flutter test`, `flutter analyze`, `test/hugeicons_guard_test.dart`.
- [ ] Spec §«Fase 8 — Pruebas» cubierta: «no llega a `INVESTIDO`» (B4.3 + B2.3), «historial viejo se lee» (B4.3), «certificado histórico no se mezcla» (B4.3 + B3.3), «ningún expediente se pierde ni se resuelve en silencio» (B4.3 + B3.3), `class.completed` sin `markInvestido` (la prueba existente de L1158 de la suite de solicitudes + B2.1 + B2.3 + B4.4), una fila liberada puede presentarse (B5).

## Fuera de este plan

Aplicar migraciones o correr el desbloqueo en Neon; borrar permisos de la base; borrar `investiture_config` o `investiture_validation_history`; tocar honores, evidencias, certificados o `expire-overdue`; reescribir el tablero SLA de analytics.
