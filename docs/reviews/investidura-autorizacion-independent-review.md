# Revisión independiente — investidura por autorización

**Primera revisión:** 2026-09-30. **Última verificación:** 2026-10-07.
**Veredicto vigente:** X-1 CERRADO CON OBSERVACIONES (revisión 26): H1, H2, H4 y H5 cerrados; H3 cerrado con observaciones. Pendientes R26-1 a R26-5 (CI en rojo por `resend.provider.spec.ts`, lint de specs, interruptor no consultado por el procesador, prueba vacía del apagado, validación cruzada de interruptores). Conciliación de certificados pendiente. X-2, X-3 y X-4 cerrados con observaciones. Backend de fases 6 y 7 conserva su aceptación local; P3-1, P4, P5, P6, P7 y W1 conservan sus cierres. Fase 8 no ejecutada. Fase 2 PARCIAL; pantallas e integración pendientes, despliegue bloqueado y pipeline anterior activo.
**Actualización revisión 27 (2026-10-07):** C-1 **NO CERRADO** (C1-H1 alta: bypass de IA-57 en clases plurianuales; C1-H2 media: interbloqueo nuevo con `closeYear`). R26-1 a R26-5 **no aplicados** por el implementador; CI sigue en rojo.

**Actualización revisión 28 (2026-10-07):** R26-1, R26-3, R26-4 cerrados; R26-2 y R26-5 con observaciones. C1-H1 a C1-H5 cerrados (C1-H1 con observación). **C-1 cerrado con observaciones**; abiertos C1R-N1 (media, interbloqueo entre envíos de lotes), C1R-N3 (media, la bandeja de resultados no se recupera con el interruptor apagado), C1R-N2, C1R-N4, C1R-N5 y lint residual.

**Actualización revisión 29 (2026-10-07):** C1R-N1, N3, N5 y lint residual cerrados; N2 y N4 cerrados con observaciones. **C-1 cerrado con observaciones.** Abiertos de prioridad baja: C1RR-1 (el cron marca `skipped` filas con intento ante el proveedor), C1RR-2 (zona horaria inconsistente para decidir año terminado) y C1RR-3 (verificación de log del servidor con respaldo fijo). Pendiente de decisión de producto: certificado del mismo año de una solicitud que murió sin autorizar.

**Actualización revisión 30 (2026-10-07):** IA-61 cerrable con observaciones (código correcto; evidencia PostgreSQL del implementador inválida, IA61-H1). IA-62 cerrado con observación. C1RR-1 y C1RR-3 **no aplicados**; C1RR-2 parcial. Abiertos: IA61-H1 a IA61-H5.

**Actualización revisión 31 (2026-10-07):** C1RR-1 a C1RR-3 e IA61-H1 a IA61-H5 **cerrados**. IA-61 e IA-62 cerrados. C-1 cerrado. Abiertos de prioridad baja: C1RR1-R1 y C1RR2-N1. Siguen abiertos los hallazgos medios y bajos de la revisión transversal del 2026-10-07 no asignados todavía (vista de la persona, nombres en lecturas, lectura de super-admin, pastor sin rol, recordatorio perdido, `createDraft` en READY, entre otros).

**Actualización revisión 32 (2026-10-07):** cierre del backend **no aprobado todavía**. BC-1, BC-2, BC-3, BC-6, BC-10, BC-12, BC-13, BC-14 y BC-15 aceptados; BC-5, BC-7 y BC-9 con observaciones; BC-4 parcial (BCR-1, media); BC-11 excede el contrato y bloquea revisión de evidencias del flujo anterior (BCR-2, media); BC-8 parcial (BCR-3).

**Actualización revisión 33 (2026-10-07):** cierre del backend **APROBADO CON OBSERVACIONES**. BCR-1, BCR-2, BCR-4, BCR-6 y BCR-8 cerrados; BCR-3, BCR-5 y BCR-9 cerrados con observaciones; BCR-7 incompleto (BCR33-N1). Abiertos de prioridad baja: BCR33-N1 a BCR33-N5.

**Actualización revisión 34 (2026-10-07):** BCR33-N1 a N5 **cerrados**. **Backend CERRADO frente al plan (IA-01 a IA-62)**, con observaciones informativas. Excepción conocida: la decisión central e IA-27/28 dependen de apagar el flujo anterior (fase 8).

**Estado del plan completo:** PARCIAL. Backend cerrado; pantallas (app y panel), fase 8, migraciones en Neon, commits y despliegue pendientes.

## Trigesimocuarta revisión — BCR33-N1 a N5 (2026-10-07)

Base: backend `eac821e` más el árbol sin commit. No se modificó runtime. Evidencia: `docs/reviews/investidura-autorizacion-review-evidence/bcr33rev-*`.

**Verificación ejecutada:** unitarias completas 368 suites, 4754 passed, 34 skipped, 0 failed; `tsc` 0; ESLint `--no-fix` sobre 86 TS de `git status` 0; PostgreSQL 18 descartable (`127.0.0.1:55525`, `log_min_messages=warning`, `--runInBand`, eliminado) 5/5 suites, 115/115 (incluye las 3 del helper movido), 8 ERROR provocados por las pruebas, 0 `deadlock detected`; suite Redis 36/36 con servidor propio.

**Veredictos (todos cerrados):**
- **N1:** `changeDates` usa `marker ? 'board' : 'authorizer'`; `marker` sale de `sectionRole` (`investiture-authorization-requests.service.ts:1633-1654`) y solo es verdadero con cargo directivo activo de la sección y del año. Probe re-ejecutado: `leaks_human_reason: false`.
- **N2:** `rules.ts:580` descarta borradores parciales del Campo que falla; el DELETE (`investiture-communications.service.ts:322-337`) solo libera filas reclamadas por la misma transacción y solo de ese Campo. Concurrencia con PostgreSQL real (`bcr33rev-reminder-release-concurrency-probe.sh`): la segunda instancia espera y reclama una sola vez; sin doble envío. Copia del probe original: 10:00 → 0, 11:00 → 3, 12:00 → 0 (el probe original no soporta `tx.$executeRaw`: límite del probe).
- **N3:** `reviewReason` (`certificate-bulk-imports.service.ts:675-695`) solo traduce `BadRequestException` de Nest; dentro de `addItem` y `downgradeInvalidReadyItems` el único que se convierte en motivo es `CERTIFICATE_IMPORT_CATALOG_NOT_FOUND` (`:948-984`). Permisos, 404, Prisma y errores internos se siguen relanzando. `updateItem` y `resubmitItem` mantienen 400.
- **N4:** recordatorios con `attempts: 1` (`email.service.ts:157-160`), demás tipos con 5 (`email.queue.ts:133`); cada reintento consume el tope en `claimRetry`; restricción del mismo día preservada vía `prepare`/`freshMail`. Redis: `BCR33-N4 reaches the provider at most 5 times...` pasa.
- **N5:** helper en `test/helpers/`; nada en `src` lo importa; la configuración unitaria no lo recoge y la e2e sí.

**Observaciones informativas:** `investiture-mail-redis.spec.ts:10` importa `delivery.spec` (pruebas de entrega corren dos veces); un job atascado reprocesado por BullMQ podría exceder 5 llamadas (mitigado por `idempotencyKey`, deducido por lectura); el índice de `graft/` apunta a la ruta vieja del helper; recordatorios encolados antes del despliegue conservan `attempts: 5` (ventana transitoria aceptada).

**Siguiente paso:** commits por unidad de trabajo, pantallas de app y panel, fase 8 (inventario con conteos reales autorizados por el usuario), migraciones en Neon y despliegue.

## Trigesimotercera revisión — BCR-1 a BCR-9 (2026-10-07)

Prompt: `docs/reviews/investidura-autorizacion-prompt-bcr.md`. Implementado por cuatro subagentes coordinados en paralelo por archivo. Backend en HEAD `eac821e` (los commits posteriores a `113d8ba` son trabajo de OCR/PDF ajeno); los cambios de investidura siguen sin commit. No se modificó runtime en la revisión. Evidencia: `docs/reviews/investidura-autorizacion-review-evidence/bcr-rev-*`.

**Verificación ejecutada:**
- Unitarias completas: 369 suites, 4741 passed, 34 skipped, 0 failed. `tsc`: 0. ESLint `--no-fix` sobre 86 TS de `git status`: 0.
- PostgreSQL 18 descartable (`127.0.0.1:55515`, `log_min_messages=warning`, `--runInBand`, eliminado): 4/4 suites, 111/111 (solicitudes 82, evidencias 12, certificados 10, pastores 7). 8 ERROR provocados por las pruebas, 0 `deadlock detected`.
- Re-ejecución de `bc-section-name-pg-probe` (nombre real de la sección) y `bc-reminder-retry-cap-probe` (4 re-encolados, `attempts=5`, luego `skipped reminder_retry_limit`).
- Sin conflictos de integración entre los cambios paralelos.

**Veredictos:**
- **BCR-1 cerrado.** `requestLabels` (`service.ts:1896-1900`) selecciona `club_types`; sin rama `section?.name`.
- **BCR-2 cerrado.** Guarda `INVESTIDO`/`EXPIRED` dentro de la transacción y bajo el candado (`class-progress-mutable.ts:32-61`, `evidence-review.service.ts:1340-1345`, `classes.service.ts:1608-1612`); en `113d8ba` esas rutas no tenían guarda de estado. Informativo: `markInvestido` no toma el candado de enrollment (fase 8).
- **BCR-3 cerrado con observación (BCR33-N4).** Reclamo con CAS (`investiture-communications.service.ts:903-922`), tope en `rules.ts:691`; solo REMINDER, como pide el contrato; sin regresión de P6-2.
- **BCR-4 cerrado.** 30 anclas de la matriz C verificadas.
- **BCR-5 cerrado con observación (BCR33-N2).** Reclamo y filas `pending` en la misma transacción; con el interruptor apagado no se consume el día; reintentos dentro del día preservados; `local_date` por zona del Campo.
- **BCR-6 cerrado.** Regla única (`investiture-pastor-eligibility.ts:39`) sin N+1; `account_inactive` expuesto; la asignación rechaza cuentas inactivas (`district-investiture-pastors.service.ts:318-330`); la resolución consulta la base dentro de la transacción tras el candado del pastor (sin bloqueo de la fila de `users`: carrera de microsegundos, aceptada). La roja de PostgreSQL mostró que antes un pastor con cuenta eliminada podía investir.
- **BCR-7 incompleto (BCR33-N1).**
- **BCR-8 cerrado.**
- **BCR-9 cerrado con observación (BCR33-N3).**

### BCR33-N1 — Baja (privacidad): `changeDates` devuelve la forma de la directiva a `super-admin`

`changeDates` (`service.ts:371`) devuelve `readRequest(tx, requestId)` con la audiencia por defecto `'board'` (`:1789-1792`). Si `super-admin` corrige la fecha de una solicitud con una persona rechazada por el pastor, la respuesta incluye el motivo humano (probe `bcr-rev-super-admin-change-dates-shape-probe`: `leaks_human_reason: true`).

### BCR33-N2 — Baja: un error de render consume el día del recordatorio

`claimDayAndStage` (`investiture-communications.service.ts:290-344`) confirma el reclamo del día aunque `dueReminders` capture un error por Campo (`rules.ts:574`, `onFieldError`). Con `ADMIN_PANEL_URL` vacío, la corrida de las 10:00 consume el día con 0 recordatorios y, al corregir la configuración, ya no sale nada ese día (probe `bcr-rev-reminder-claim-on-render-error-probe`).

### BCR33-N3 — Baja: catálogo inválido al crear devuelve 400 (desviación de BC-9)

Con Nest 11.2, `BadRequestException.getResponse()` es un objeto; `reviewReason` (`certificate-bulk-imports.service.ts:670-683`) devuelve null y relanza. En `createDraft` con `items[]` falla el lote completo (`:686-728`). La revisión 32 había dado por bueno BC-9 en catálogo: esa conclusión fue incorrecta. Sin prueba unitaria del caso (probe `bcr-rev-bc9-catalog-at-create-probe`).

### BCR33-N4 — Baja: el tope cuenta entregas a la cola, no llamadas al proveedor

`email.queue.ts:134` usa `attempts: 5` y `:177-181` `resetAttemptsMade: true`: hasta 25 llamadas HTTP con la misma `idempotencyKey` para un recordatorio. El contrato pedía «5 intentos ante el proveedor». Deducido por lectura; no ejercitado contra Redis real.

### BCR33-N5 — Informativa: helper de pruebas en `src/`

`src/investiture-requests/investiture-server-log.ts` solo lo usan las pruebas, pero entra al build de producción. Conviene moverlo a `test/helpers`. Menor: crear con fecha futura y `mark_as_ready: false` deja `rejection_reason` en el ítem, mientras `updateItem` responde 400 ante la misma fecha.

**Siguiente paso:** corregir BCR33-N1 a N5. Luego: pantallas, fase 8, migraciones en Neon y commits.

## Trigesimosegunda revisión — Cierre del backend BC-1 a BC-15 (2026-10-07)

Prompt: `docs/reviews/investidura-autorizacion-prompt-backend-cierre.md`. Decisiones del usuario: plan §3.7 «Decisiones del 2026-10-07 (cierre del backend)». Base `development` @ `113d8ba`, cambios sin commit. No se modificó runtime. Evidencia: `docs/reviews/investidura-autorizacion-review-evidence/bc-*`. El implementador no registró corrida roja por ítem (solo BC-1 vía probe previo).

**Verificación ejecutada:**
- Unitarias completas: 369 suites, 4695 passed, 34 skipped, 0 failed. `tsc`: 0. ESLint `--no-fix` sobre 105 TS de `git status`: 0.
- PostgreSQL descartable (`127.0.0.1:55485`, `log_min_messages=warning`, `sacdia_bcrev_test`, eliminado): 68/68, 7/7, 10/10; 8 ERROR provocados, 0 `deadlock detected`.
- Migraciones `20261007180000_district_investiture_pastor_user_fk` y `20261007180100_investiture_date_change_audit`: aplican limpias sobre el schema previo dentro de una transacción (FK `ON DELETE RESTRICT` y columnas presentes, ROLLBACK correcto); con un pastor huérfano la FK falla como corresponde; `migrate diff` posterior sin diferencias salvo un default preexistente de `club_annual_rankings`. **Observación de despliegue:** el historial completo de migraciones no se reproduce desde cero porque falla `20260409100000_legacy_scoring_migration` (preexistente, ajeno a esta entrega).
- Probes: `bc-skip-jsonpath-pg-probe` (BC-1 en PostgreSQL real), `bc-section-name-pg-probe`, `bc-reminder-retry-cap-probe`; re-ejecución de `c1rr2-skip-toctou` (R1 `sent`, R2 `uncertain`, R3 `skipped`). `c1rr2-timezone-normalization` reimplementa la lógica vieja y no aporta evidencia.

**Veredictos:** BC-1 OK (filtro JSON traducido correctamente en PostgreSQL). BC-2 OK (detalle: zona inválida también hace fallar la lectura de `super-admin`, vía `loadContext`). BC-3 OK. BC-4 parcial (BCR-1); que el autorizador no vea el motivo humano coincide con §3.6. BC-5 OK con observación (`super-admin` recibe la forma de la directiva, con motivo humano). BC-6 OK con observaciones (comparación de rol distinta entre listado y cargador de correos; un pastor con cuenta eliminada lógicamente sigue `can_authorize: true`). BC-7 OK con desviación (envía hasta 23:59 a destinatarios sin fila del día aunque la corrida de las 10:00 haya ocurrido; `rules.ts:419-500`). BC-8 parcial (BCR-3). BC-9 OK en edad y catálogo; falta `assertNotFuture` al crear (`certificate-bulk-imports.service.ts:684-713`). BC-10, BC-12, BC-15 OK. BC-11 excede el contrato (BCR-2). BC-13 OK. BC-14 OK; la eliminación de cuentas es lógica (`account-deletion.service.ts:131`) y no hay borrado físico, por lo que `RESTRICT` no bloquea flujos.

### BCR-1 — Media: `section_name` siempre null (IA-12)

`requestLabels` (`investiture-authorization-requests.service.ts:1890-1897`) hace `club_sections.findUnique` sin `include: { club_types }`; `club_sections` no tiene columna `name`. La unitaria pasa porque el mock devuelve `club_types`. Reproducido en PostgreSQL real (`bc-section-name-pg-probe.log`).

### BCR-2 — Media: BC-11 bloquea más que `INVESTIDO`/`EXPIRED`

`assertEnrollmentProgressOpen` (`evidence-review.service.ts:1094`, `:1186`, `:1337`) usa `assertClassProgressMutable` (`class-progress-mutable.ts:4-23`), que también bloquea `locked_for_validation` y `SUBMITTED`/`CLUB_APPROVED`/`COORDINATOR_APPROVED`/`FIELD_APPROVED`. Aprobar o rechazar evidencias ahora responde 409 mientras un expediente del flujo anterior está en curso, lo que en `113d8ba` funcionaba; la fase 8 no se ejecutó. El contrato pedía solo `INVESTIDO` y `EXPIRED` (además del bloqueo de `PENDING` ya existente). La comprobación corre fuera de la transacción: carrera estrecha contra un `INVESTIDO` recién confirmado.

### BCR-3 — Baja: tope de reintentos de recordatorio

`recoverRow` re-encola el job `failed` mediante `retryFailedInvestitureJob` (`investiture-communications.service.ts:776`) sin incrementar `attempts` (probe: 20 corridas, 20 re-encolados, `attempts` en 1); el tope no aplica en ese camino. Error por uno: el quinto claim ya da `reminder_retry_limit`, salen 4 envíos (`bc-reminder-retry-cap-probe.log`).

### BCR-4 — Baja: matriz C del informe desactualizada

La matriz C del informe de implementación marca «Pendiente» o «Autorizar no tiene ruta» en IA-03, 07, 09, 10, 27, 28 y 29; `resolve` existe (`:626`) y valida año, ventana y fecha (`:675-718`, `:785-795`).

**Matriz IA en backend:** todo implementado salvo IA-12 parcial (BCR-1); IA-40 implementado con el riesgo de BCR-2; IA-43/IA-49 con las desviaciones de BC-7/BC-8; IA-34 fuera de alcance (unidades y finanzas); IA-17 e IA-32/33 se cumplen sin código nuevo. La decisión central e IA-27 siguen abiertas por el flujo anterior (`markInvestido` aún inviste fuera de ventana): corresponde a la fase 8.

**Siguiente paso:** BCR-1 a BCR-4 y las observaciones bajas de BC-2, BC-5, BC-6, BC-7 y BC-9.

## Trigesimoprimera revisión — C1RR e IA61-H (2026-10-07)

Prompt: `docs/reviews/investidura-autorizacion-prompt-c1rr-ia61r.md`. Base `development` @ `113d8ba`, cambios sin commit. No se modificó runtime. Evidencia: `docs/reviews/investidura-autorizacion-review-evidence/c1rr2-*`.

**Verificación ejecutada:**
- Unitarias completas: 4609 passed, 34 skipped, 0 failed. `tsc`: 0. ESLint `--no-fix` sobre 86 TS de `git status`: 0.
- PostgreSQL descartable (`127.0.0.1:55475`, `LC_ALL=C`, `SHOW log_min_messages` = `warning`, eliminado): 68/68, 7/7, 10/10; log con 8 ERROR de control, 0 `deadlock detected`, 13 marcadores. Con `log_min_messages=log`: 13 fallos por el marcador. Sin `SACDIA_POSTGRES_SERVER_LOG`: 13 fallos con mensaje claro.
- Probes `c1rr` e `ia61` re-ejecutados sin regresión.

**Veredictos (todos cerrados):**
- **C1RR-1:** el cron separa filas (`investiture-communications.service.ts:574-592`); con intento → `uncertain` (`markUncertain`, `:458-484`); «24 horas» solo con intento viejo; probe A/B/C → `uncertain`, 0 envíos.
- **C1RR-2:** helper único con respaldo único (`ecclesiastical-year-local-day.ts:1-25`), usado por `assertYearOpen` (`service.ts:1632-1646`) y `requestYearEnded` (`class-certificate-live-authorization.ts:265-272`). Sin duplicados ni literal de zona en las rutas que deciden el año (solo queda en el reloj de recordatorios, `investiture-communications.rules.ts:415`, `:633`). Pruebas de borde Tijuana/Bogotá con `active=true` en `service.spec:1095`, `application.service.spec:1645` y e2e `:4700` (discriminación razonada, no mutada).
- **C1RR-3:** sin respaldo de Homebrew (`investiture-server-log.ts`); marcador `RAISE WARNING` verificado (`e2e-spec:4944-4962`).
- **IA61-H1:** evidencia rehecha y reproducida.
- **IA61-H2:** compuerta `application.service.ts:431-474` rechaza rol de Campo sin Campo y actor sin roles.
- **IA61-H3:** documentado (`validacion-investiduras.md:133`, `:228`).
- **IA61-H4:** `REMOVED`/`CLASS_NOT_ELIGIBLE` (`service.ts:713-736`) sin evento ni resultado; excluido de recordatorios (`rules.ts:543`). Solo prueba unitaria.
- **IA61-H5:** `ErrorCode` (`error-codes.ts:225`), i18n en cuatro idiomas, 403 (`application.service.ts:472`), `docs/api` sincronizado.

### C1RR1-R1 — Baja: carrera entre leer y escribir en `skipOpenInvestitureMail`

El `updateMany` que escribe `skipped` (`service.ts:586-590`) filtra solo por `dispatch_id`, sin estado ni «sin intento». Si un worker registra el intento o confirma `sent` entre el `findMany` y la escritura, la fila queda `skipped` y puede pisar `sent` (probe `c1rr2-skip-toctou-probe`: R1 `sent`→`skipped`, R2 con intento→`skipped`).

### C1RR2-N1 — Baja: normalización distinta de la zona

Ruta del pastor: `timezone || FALLBACK` sin `trim` (`service.ts:1543-1545`); ruta del certificado: `trim() || FALLBACK` (`live-authorization.ts:317-320`). Con una zona en blanco o con espacios, la ruta del pastor lanza `RangeError` y el certificado decide. Solo filas antiguas o inactivas (admin valida al escribir; `CHECK` en `NOT VALID`).

**Siguiente paso:** cierre del backend: C1RR1-R1, C1RR2-N1 y los hallazgos pendientes de la revisión transversal.

## Trigésima revisión — IA-61, IA-62 y estado de C1RR (2026-10-07)

Prompts: `docs/reviews/investidura-autorizacion-prompt-ia61.md` y `docs/reviews/investidura-autorizacion-prompt-c1rr.md`. Reglas IA-61 e IA-62 (plan §3.9). Base `development` @ `113d8ba`, cambios sin commit. No se modificó runtime. El informe de implementación **no tiene sección C1RR**. Evidencia: `docs/reviews/investidura-autorizacion-review-evidence/ia61-*`.

**Verificación ejecutada:**
- Unitarias completas: 4584 passed, 34 skipped, 0 failed (365/371 suites). `tsc`: 0. ESLint `--no-fix` sobre 84 TS de `git status`: 0.
- PostgreSQL descartable propio (`127.0.0.1:55465`, `sacdia_ia61rev_test`, `log_min_messages=warning`, marcador `RAISE WARNING` presente en el log, eliminado): investidura 66/66, pastores 7/7, certificados 10/10; 0 `deadlock detected` y el log sí registra los 9 ERROR provocados por las pruebas.

**Veredictos:**
- **IA-61 cerrable con observaciones.** `assertEndedYearCertificateReviewer` (`certificate-bulk-imports-application.service.ts:431-470`) aplica la definición de alcance del módulo de certificados (`admin-certificate-bulk-imports.service.ts:279-302`): admin/assistant-admin con `local_field_id` quedan limitados a su Campo; sin Campo, globales. Probe: admin/assistant-admin del Campo 8 contra solicitud del Campo 7 → `FORBIDDEN`; assistant-lf de otro Campo → `FORBIDDEN`. Difiere de la definición territorial de IA-24 (`actor-territory-scope.ts:193-211`); se acepta como coherente con las aprobaciones de certificados existentes. La nota en `system_reason` no se interpreta como rechazo: el único consumidor de rechazo del sistema (`investiture-communications.loader.ts:128-131`) solo recibe `rejectedSystemIds` de `resolve`; el historial (`service.ts:1786-1814`) solo muestra `person_text` con la nota; IA-31 intacto; admin y app no leen `system_reason`. Orden en una transacción: candado de año → `findEnded` → compuerta de rol → cierre del PENDING → acreditación → nota (`:337-391`); sin `class.completed`. Carrera contra el barrido en ambos órdenes, limpia en clúster propio (solo con `super-admin` y año `active=false`).
- **IA-62 cerrado con observación.** Presentar, agregar y resolver rechazan dentro de la transacción (`service.ts:709`, `:1220`); lista única (`institutional-class-codes.ts:1`); vía institucional sin cambios.
- **C1RR-1 abierto (no aplicado).** `skipOpenInvestitureMail` (`investiture-communications.service.ts:562-573`, llamado en `:264`) no filtra filas con intento ante el proveedor.
- **C1RR-2 parcial.** Ambas rutas comparten `localCivilDay` y el respaldo; el probe coincide en Tijuana y Bogotá con `active=true` en el borde de `end_date`. Pero la comparación sigue duplicada (`class-certificate-live-authorization.ts:268-273` frente a `service.ts:1607`), queda el literal `'America/Mexico_City'` en `service.ts:1520` y no existen pruebas de borde con `active=true` en unidad ni en PostgreSQL.
- **C1RR-3 abierto (no aplicado).** Respaldo a `/opt/homebrew/var/log/postgresql@18.log` en `test/investiture-authorization-requests-postgres.e2e-spec.ts:4748-4749`.

### IA61-H1 — Media (evidencia): el log del implementador no registra ERROR

El clúster del implementador (`/tmp/sacdia-ia61-pg/postgresql.conf:890`) usa `log_min_messages = log`, nivel superior a ERROR: los errores no se escriben en el log del servidor. Su `server.log` tiene 0 líneas ERROR aunque las suites provocan ERROR esperados. Probe `ia61-log-min-messages-deadlock-probe`: un interbloqueo forzado no aparece con `log` y sí con `warning`. «Sin `deadlock detected`» en esa corrida no prueba nada; las aserciones del cliente siguen valiendo. El marcador de C1RR-3 debe ser `RAISE WARNING` (se usó `RAISE LOG`).

### IA61-H2 — Baja: compuerta permisiva sin Campo

La compuerta de IA-61 deja pasar a un `director-lf` sin `local_field_id` y a un actor sin roles. Por HTTP no es alcanzable (`resolveReviewerAccess` lanza `SCOPE_REQUIRED`); defensa en profundidad.

### IA61-H3 — Baja: lote con Campo distinto al de la solicitud

Si el lote está etiquetado con un Campo distinto al de la solicitud (por ejemplo, la persona cambió de Campo), ningún rol de Campo puede acreditar; solo un admin global o `super-admin`.

### IA61-H4 — Baja: un PENDING previo de GM-02/GM-03 no se puede resolver

El chequeo de `:709` también bloquea el rechazo: la llamada falla entera y el registro sigue en recordatorios hasta que la sección lo quite.

### IA61-H5 — Baja: error sin código ni i18n

`CERTIFICATE_IMPORT_ENDED_YEAR_FIELD_FORBIDDEN` es un `ForbiddenException` en texto plano, sin `ErrorCode` ni i18n. Faltan pruebas unitarias de admin con otro Campo y de assistant-lf con otro Campo.

**Siguiente paso:** aplicar C1RR-1 y C1RR-3, completar C1RR-2 y corregir IA61-H1, H2, H4 y H5 (H3 se documenta). Luego: pantallas, fase 2, fase 8 y migraciones.

## Vigesimonovena revisión — C1R-N1 a C1R-N5 (2026-10-07)

Prompt: `docs/reviews/investidura-autorizacion-prompt-c1r.md`. Base `development` @ `113d8ba`, cambios sin commit. No se modificó runtime. Evidencia: `docs/reviews/investidura-autorizacion-review-evidence/c1rr-*`.

**Verificación ejecutada:**
- Unitarias completas (`node node_modules/jest/bin/jest.js --no-coverage --forceExit`): 365 suites, **4570 passed, 34 skipped, 0 failed**, una sola corrida sin SIGSEGV.
- `tsc`: 0. ESLint `--no-fix` sobre 81 TS de `git status` (incluye no rastreados): 0.
- PostgreSQL descartable propio (`127.0.0.1:55447`, `sacdia_c1rr_test`, log controlado con `-l`, eliminado): investidura 64/64, pastores 7/7, certificate-import 10/10. Sin `deadlock detected`; el log registra los `ERROR` provocados y un WARNING de control, por lo que la evidencia es válida.
- Probes re-ejecutados: `c1r-submit-year-order` 3/3, `c1r-crossyear-close` 6 rondas (probe L: clase normal y Guía Mayor `CLOSED_YEAR` con certificado acreditado), `c1-multiyear-deadlock` y `h1h5` sin regresión.

**Veredictos:**
- **C1R-N1 cerrado.** Envío (`certificate-bulk-imports.service.ts:476-496`), reenvío (549-560), aprobación de ítem (`certificate-bulk-imports-application.service.ts:278-296`) e institucional (`institutional-certificate-requests.service.ts:149-158`, 301-318) toman los años ascendentes antes del bucle (`skipYearAdvisory`). Solo caminos de un año llaman a `lockInvestitureAuthorizationYear`. El barrido de `year-cut` pasa años ordenados y `closePending` lanza `INVESTITURE_YEAR_LOCK_ORDER` ante un año menor.
- **C1R-N2 cerrado con observación.** `closeEndedRequests` (`class-certificate-live-authorization.ts:261-308`) escribe `CLOSED_YEAR` sin `system_reason` ni evento, idempotente, respetando `heldYearIds`. Observación de producto: un certificado del mismo año que una solicitud ya terminada cierra el `PENDING` y acredita ese año, por lo que el historial muestra «no investido» e `INVESTIDO` del mismo año (deducido por lectura).
- **C1R-N3 cerrado.** `deliverPending` (`investiture-communications.service.ts:261-306`) recupera `RESULT` siempre; con el interruptor apagado no sale correo.
- **C1R-N4 cerrado con observación** (procesador correcto, `email.processor.ts:150-163`, 214-218; ver C1RR-1).
- **C1R-N5 cerrado.** `assertNoClientDeadlock` verifica 40P01 y el log; ya no se usa `pg_stat_database`.
- **Lint residual cerrado.**

### C1RR-1 — Baja: el cron marca `skipped` filas con intento ante el proveedor

`skipOpenInvestitureMail` (`investiture-communications.service.ts:562-573`), llamado desde `deliverPending:264`, no filtra filas con intento registrado. Si el cron corre antes que el job, la fila queda `skipped` en vez de `uncertain` (probe `c1rr-bulk-skip-attempt-probe`, escenarios A y B; el C, solo procesador, queda `uncertain`). El texto de `uncertain` menciona «24 horas» aunque el intento sea reciente.

### C1RR-2 — Baja: zona horaria inconsistente para «año de la solicitud terminado»

`requestYearEnded` (`class-certificate-live-authorization.ts:238-258`) usa `America/Mexico_City` duplicando `ECCLESIASTICAL_YEAR_TIMEZONE` (`ecclesiastical-year.service.ts:12-18`), mientras `assertYearOpen` (`investiture-authorization-requests.service.ts:1568-1576`) usa `local_fields.timezone`. Campo al oeste: en las últimas horas de `end_date`, una aprobación de certificado cierra `CLOSED_YEAR` a alguien que el pastor aún podía autorizar. Campo al este: el `PENDING` sigue vivo unas horas hasta el barrido. Ninguna prueba ejercita la rama por día con `active=true`. Recomendación: una sola regla, el día local del Campo de la solicitud con el mismo helper de `assertYearOpen`.

### C1RR-3 — Baja: verificación de log del servidor con respaldo fijo

El implementador corrió las e2e contra el PostgreSQL de Homebrew (`127.0.0.1:5432`, desde `.env.test.local`), no un clúster aislado; su log corresponde a ese servidor. Pero `openServerLog` (`test/investiture-authorization-requests-postgres.e2e-spec.ts:4574-4591`) cae a `/opt/homebrew/var/log/postgresql@18.log` si falta `SACDIA_POSTGRES_SERVER_LOG`: contra otro servidor, la comprobación pasaría sin verificar nada.

**Siguiente paso:** C1RR-1 a C1RR-3 (prioridad baja) y decisión de producto sobre el certificado del mismo año de una solicitud vencida. Luego: pantallas, fase 2, fase 8 y migraciones.

## Vigesimoctava revisión — R26-1 a R26-5 y C-1 residual (2026-10-07)

Prompt: `docs/reviews/investidura-autorizacion-prompt-c1-residual-r26.md`. Base `development` @ `113d8ba`, cambios sin commit. No se modificó runtime. Evidencia: `docs/reviews/investidura-autorizacion-review-evidence/c1r-*`.

**Verificación ejecutada:**
- Unitarias completas (`node node_modules/jest/bin/jest.js --no-coverage --forceExit`; `pnpm run test -- …` no ejecuta pruebas): 365 suites, **4562 passed, 34 skipped, 0 failed** (`c1r-unit-rerun.log`). Una primera pasada tuvo 1 fallo en `certificate-import-files.service.spec.ts:299` mientras otra sesión editaba ese spec y `certificate-import-pdf*` (14:09–14:17), fuera de este alcance; la segunda pasada quedó en 0.
- PostgreSQL descartable (`127.0.0.1:55445`, `sacdia_c1r_test`, eliminado): investidura 58/58, pastores 7/7, certificate-import 10/10; sin `deadlock detected` durante las suites.
- `tsc`: 0. ESLint `--no-fix` sobre 81 archivos TS tocados: 2 errores de prettier en `src/common/guards/permissions.guard.spec.ts` (L5, L342).
- Re-ejecución de `c1-multiyear-deadlock-probe` y `h1h5-flag-off-queued-probe`; probes nuevos `c1r-crossyear-close-probe` y `c1r-submit-year-order-probe`.

**Veredictos:** R26-1 cerrado. R26-2 con observación (2 errores de prettier; además se reformatearon líneas viejas de `certificate-import-postgres.e2e-spec`). R26-3 cerrado: el gate (`email.processor.ts:150-158`) reconsulta antes de cada envío; S1 → 0 envíos y `skipped`. R26-4 cerrado: 8 filas sembradas, 8 `skipped`, `RESULT` intacto. R26-5 con observación (opción b, `investiture-mail.gate.ts:4-8`). C1-H1 cerrado con observación: 2026 rechazado, 2025 acreditado con `REMOVED`/`HISTORICAL_CERTIFICATE_APPLIED`, Guía Mayor 2026 rechazado, 2019 correcto; dos `PENDING` de la misma persona y clase no pueden coexistir (índice `uniq_investiture_authorization_people_pending_class`). C1-H2 cerrado para `closeYear`: la aprobación solo hace `FOR SHARE` del año del certificado; `closeYear(2026)` contra certificado 2025 en ambos órdenes y 6 carreras libres, sin interbloqueo y con resultado coherente. C1-H3 cerrado (la carrera real se ejecuta). C1-H4 cerrado (solo conteos, sin relajar lógica). C1-H5 cerrado (`request_id asc, person_id asc`, determinista, no cronológico).

### C1R-N1 — Media, reproducido: interbloqueo entre envíos de lotes (regresión de C1-H2)

`assertClassCertificateHistoricalAge` toma el candado advisory de año (`class-certificate-historical-age.ts:168-175`). `submit()` (`certificate-bulk-imports.service.ts:465-484`) lo invoca por ítem, en el orden de un `findMany` sin `orderBy`. Dos lotes enviados a la vez (ítems 2026→2025 y 2025→2026): 3/3 rondas con `deadlock detected` (`c1r-pglog.txt`), un envío aborta con P2010. El barrido de `year-cut` con varios años terminados tiene el mismo riesgo.

### C1R-N3 — Media: los resultados de la bandeja no se recuperan con el interruptor apagado

`deliverPending` (`investiture-communications.service.ts:261-267`) retorna antes de recuperar `RESULT` si `INVESTITURE_EMAIL_ENABLED` está apagado, que es el valor por defecto. Las notificaciones de resultado fallidas nunca se reintentan: regresión del invariante de recuperación de P6-1 y contradice el comentario de `env.validation.ts`.

### C1R-N2 — Baja: certificado de un año posterior a la solicitud

Solicitud de 2025 aún `PENDING` (año terminado, barrido de `year-cut` todavía no ejecutado) y certificado de 2026: se aprueba y la persona sigue `PENDING`. En Guía Mayor, `substituteGuideMajor` deja el `PENDING` huérfano (probe L).

### C1R-N4 — Baja: fila posiblemente enviada queda `skipped`

El procesador consulta el interruptor antes de `providerAttempt` (`email.processor.ts:207`): una fila con intento previo, quizá aceptado por el proveedor, termina `skipped` en vez de `uncertain`.

### C1R-N5 — Baja: evidencia débil de interbloqueo en la e2e

`pg_stat_database.deadlocks` se actualiza con retraso (lectura inmediata delta 0 con 3 interbloqueos reales). La evidencia fiable es el log del servidor.

**Siguiente paso:** corregir C1R-N1 a C1R-N5 y el lint residual. No ejecutar fase 8 ni desplegar.

## Vigesimoséptima revisión — C-1 certificados frente a solicitud viva (2026-10-07)

Prompt: `docs/reviews/investidura-autorizacion-prompt-c1-certificados.md`. Reglas IA-57 a IA-60 (plan §3.9). Base `development` @ `113d8ba`, cambios sin commit. No se modificó runtime.

**Veredictos:** IA-57 **no cerrado**. IA-58 **cerrado** (`investiture-year-close.ts:90-99` no toca enrollments). IA-59 **cerrado con observaciones**. IA-60 **cerrado con observaciones** (sin ciclo con presentar/resolver; interbloqueo con `closeYear`). **C-1 NO CERRADO.**

**Verificación ejecutada:**
- `pnpm run test`: 3 failed, 34 skipped, 4535 passed (4572). Coincide con lo reportado: 2 en `resend.provider.spec.ts` (R26-1 no aplicado) y 1 en `club-assignment-effectivity.inventory.spec.ts` (ver C1-H4).
- `tsc --noEmit -p tsconfig.build.json`: 0. ESLint `--no-fix` sobre 15 archivos tocados: 0.
- PostgreSQL aislado (`127.0.0.1:55443`, `sacdia_c1_review_test`, eliminado): `investiture-authorization-requests` 51/51, `district-investiture-pastors` 7/7, `certificate-import` **9/10** (C1-H3).
- Evidencia: `c1-multiyear-deadlock-probe.cjs/.log`, `c1-cert-race-reason-probe.cjs`, `c1-deadlock-pglog.txt`, `c1-pg-*.log`, `c1-unit-tail.log`.

**Lo verificado correcto:** IA-59 retira en la misma transacción con `rejection_reason` null, sin evento ni correo; recordatorios filtran `PENDING` (`investiture-communications.loader.ts:35,152`); lecturas de sección (`:366`) y autorizador (`:393`) muestran el motivo; X-2 sigue retirando con `ALREADY_INVESTED` (`:705-735`); aprobación institucional y por ítem usan la misma guarda (`:295`, `:313`, aviso temprano `:149`). Orden de candados de presentar/agregar/resolver sin ciclo con la aprobación.

### C1-H1 — Alta, reproducido: «mismo año» se decide con el año de inicio del enrollment

`class-certificate-live-authorization.ts:86-89` (`operationalYearId`) y `:162-195` comparan el año del certificado con `enrollment.ecclesiastical_year_id`, que en clases con `max_duration_years > 1` es el año de inicio, no el de la solicitud (P4-1). Probe en PostgreSQL, enrollment iniciado en 2025 y persona `PENDING` en la solicitud de 2026:
- Certificado de 2026: se aprueba, crea un histórico `INVESTIDO` de 2026 y la persona sigue `PENDING`; al resolver sale `ALREADY_INVESTED` con 0 `class.completed`. **El certificado gana a la autorización en el año en curso**, contra IA-57.
- Guía Mayor con certificado de 2026: `substituteGuideMajor` convierte la operativa en `HISTORICAL_CERTIFICATE` de 2026; el `PENDING` queda huérfano (`INVESTITURE_REQUEST_NOT_OPERATIONAL` al resolver) y sigue en recordatorios hasta el cierre.
- Certificado de 2025 (anterior al año en curso): se rechaza indebidamente con `CERTIFICATE_IMPORT_AUTHORIZATION_PENDING` en lugar de acreditar y retirar (IA-59).
- Control, certificado de 2019: correcto.

**Corrección requerida:** decidir «año en curso» contra el año eclesiástico de la **solicitud** del registro `PENDING` (`investiture_authorization_requests.ecclesiastical_year_id`), no contra el año del enrollment.

### C1-H2 — Media, reproducido: interbloqueo nuevo con `closeYear`

Aprobación: `FOR SHARE` de la fila de `ecclesiastical_years` (`class-certificate-historical-age.ts:160`) y luego espera el candado de usuario (`class-certificate-live-authorization.ts:234`). `closeYear`: candados de año, sección, usuario y enrollment (`investiture-year-close.ts:80-88`) y luego `UPDATE ecclesiastical_years` (`year-end.service.ts:184`). PostgreSQL detectó `deadlock detected` (`c1-deadlock-pglog.txt`); esta vez la víctima fue el certificado (P2010), otra vez podría ser el cierre. Basta un certificado del año que cierra para un usuario con cualquier `PENDING` en ese año, porque la aprobación toma el candado de usuario aunque el `PENDING` sea de otra clase. La aprobación institucional comparte el riesgo. Antes de C-1 no existía.

### C1-H3 — Baja: `certificate-import-postgres` en 9/10

«keeps one historical enrollment when two approvals race» falla con `CERTIFICATE_IMPORT_BIRTHDAY_REQUIRED` en ambas aprobaciones: el fixture no tiene nacimiento desde la fase 0B. El archivo no cambió desde `113d8ba`; el implementador no reportó esta suite.

### C1-H4 — Baja (bloquea CI): `club-assignment-effectivity.inventory.spec.ts` en rojo

En el árbol actual falla por consultas sin clasificar de esta implementación: anuario (`investiture-authorization-requests.service.ts:489`) e `investiture-communications.loader.ts:84`. En `113d8ba` limpio también estaba rojo por un inventario vencido de `class-requirement-eligibility`. Los unit tests son bloqueantes en CI.

### C1-H5 — Baja: lectura informativa no determinista

`list()` elige la solicitud informativa con `findFirst` sin `orderBy` (`investiture-authorization-requests.service.ts:366`).

**Siguiente paso:** corregir C1-H1 a C1-H5 junto con R26-1 a R26-5, con `pnpm run test` completo en verde y las tres suites PostgreSQL. No ejecutar fase 8 ni desplegar.

## Vigesimosexta revisión — X-1 residual H1–H5 (2026-10-07)

Prompt de corrección: `docs/reviews/investidura-autorizacion-prompt-x1-residual.md`. Base `development` @ `113d8ba`, cambios sin commit. No se modificó runtime.

**Veredictos:** H1 **cerrado**. H2 **cerrado**. H3 **cerrado con observaciones**. H4 **cerrado**. H5 **cerrado**. **X-1 cerrado con observaciones.**

**Verificación ejecutada:**
- Jest, 32 suites: 444/446. Fallan 2 en `src/common/email/providers/resend.provider.spec.ts` (confirmado de forma independiente: 2 failed, 3 passed) — ver R26-1.
- PostgreSQL e2e en clúster descartable PG18 (`127.0.0.1:55441`, `sacdia_h1h5_review_test`, eliminado): 46/46.
- `tsc --noEmit -p tsconfig.build.json`: salida 0. ESLint: runtime 0; dos specs nuevos con 176 errores (R26-2).
- Re-ejecución de `x1x4-legacy-submit-race-probe` y `x1x4-resolution-guard-probe` (logs `h1h5-rerun-*.log`): ambos escenarios responden 409, `INVESTIDO`, `locked_for_validation=false`, un `class.completed`. Ya no hay sobrescritura. Probe nuevo `h1h5-flag-off-queued-probe.cjs`.

**H1:** todas las escrituras de la vía anterior (submit L250, reject L433, validate L1236/1261, aprobaciones L2495, invest L571, bloque L1477/1534/1744, vencimientos L1884/L2306; clase `validation.service.ts` L68/L201) usan `updateMany` condicionado al estado de origen, dentro de la transacción y tras el candado `investiture-authorization-enrollment:`. `count ≠ 1` → 409 `INVESTITURE_CONCURRENT_UPDATE` antes de historial; eventos y notificaciones solo después del commit. Sin otros escritores fuera de la conciliación de certificados (diferida).

**H2:** la persona desalineada queda `REMOVED` (`ALREADY_INVESTED` en el probe) y la otra `INVESTED` con un evento. Retirados sin resultado. Re-presentación posible (índices parciales sobre `PENDING`).

**H3:** interruptor `INVESTITURE_EMAIL_ENABLED` apagado por defecto; `ADMIN_PANEL_URL` obligatorio solo con él (`env.validation.ts:94-100,133`). La intención de presentación queda `skipped` en la misma transacción (P6-1 intacto). Recordatorios no se generan ni se recuperan al encender. `render.yaml` y runbook actualizados.

**H4/H5:** error por Campo aislado y registrado; `deliverPending` siempre corre. Todas las apariciones de `/investiture-requests/` exigen origen absoluto.

### R26-1 — Media (bloquea CI): `resend.provider.spec.ts` en rojo

`send` recibe un segundo argumento (clave de idempotencia) y la prueba no se actualizó. Los unit tests son bloqueantes en CI. La entrega no corrió esa suite.

### R26-2 — Baja: lint de specs nuevos

`investiture-authorization-requests.service.spec.ts:1763-1793` y `test/investiture-authorization-requests-postgres.e2e-spec.ts:3254+`: 171 errores de prettier y 5 `no-useless-assignment` (L3337-3341). El informe declara ESLint 0.

### R26-3 — Baja: el procesador de correo no consulta el interruptor

`email.processor.ts:190-255` solo mira `EMAIL_ENABLED`; `prepare` (`investiture-communications.service.ts:302`) solo descarta filas `sent`/`skipped`. Un job encolado con el interruptor encendido sale aunque se apague antes de procesarlo (probe S1: 1 envío, fila `sent`). Además `skipOpenInvestitureMail` (`:532`) marca `queued`/`sending` como `skipped` aunque el job siga vivo. Alcanzable solo tras encender y apagar el interruptor.

### R26-4 — Baja: el apagado no tiene prueba real

El doble en memoria del spec de entrega (`matchesDispatch`, L103) no soporta `kind: {in: [...]}`; la prueba «does not send investiture mail while the switch is off…» pasa sin filas `REMINDER` (`.every` vacío). No se ejercitan filas `queued`/`sending`.

### R26-5 — Baja: falta validación cruzada de interruptores

`INVESTITURE_EMAIL_ENABLED=true` con `EMAIL_ENABLED=false` es válido; los jobs quedan `failed` y `deliverPending` los reintenta, lo que podría liberar un lote acumulado al encender el correo global (deducido por lectura, no probado).

**Siguiente paso:** corregir R26-1 a R26-5 y la conciliación de certificados (A2/X-2) antes de pantallas. No ejecutar fase 8 ni desplegar.

## Vigesimoquinta revisión — X-1 a X-4, separación de vías (2026-10-07)

Revisión transversal del plan contra el código (2026-10-07) que originó X-1 a X-4; prompt de corrección en `docs/reviews/investidura-autorizacion-prompt-x1-x4.md`. Base: `development` @ `113d8ba`, cambios sin commit. No se modificó runtime.

**Veredictos:** X-1 **NO CERRADO**. X-2 cerrado con observaciones. X-3 cerrado con observaciones; H3 bloquea despliegue. X-4 cerrado con observaciones.

**Verificación ejecutada:**
- Seis suites del informe: 191/191. Juego ampliado (`investiture-requests/*` incluido Redis con servidor propio, `classes.service`, `evidence-review`, `year-cut/*`, `year-end`): 16 suites, 352/352. Los cierres previos siguen pasando.
- PostgreSQL e2e en clúster descartable de loopback (`127.0.0.1:55439`, `sacdia_x1x4_review_test`, ya eliminado): 40/40, incluidos `resolve-first` e `invest-first`.
- `tsc --noEmit -p tsconfig.build.json` y ESLint de los 12 archivos tocados: salida 0.
- Probes nuevos: `x1x4-legacy-submit-race-probe.cjs` y `x1x4-resolution-guard-probe.cjs`, con sus `.log`.

**Lo que sí quedó correcto:** presentar/agregar releen el enrollment después del candado y rechazan estados de la vía anterior, incluido `APPROVED`. Todas las rutas viejas toman el candado `investiture-authorization-enrollment:` y comprueban `PENDING` dentro de la transacción. Orden de candados sin riesgo de interbloqueo. `invest` condicionado a `FIELD_APPROVED`: un `INVESTIDO` y un `class.completed` en ambos órdenes. Honores sin cambios. X-2 mira cualquier `INVESTIDO` de persona y clase.

### H1 — Alta, reproducido: la vía anterior sobrescribe un INVESTIDO de la vía nueva

`InvestitureService.submitForValidation` valida `IN_PROGRESS` fuera de la transacción (`investiture.service.ts` ~L186-228) y dentro hace `tx.enrollments.update` incondicional (~L250). `ValidationService.submitForReview` para clase igual (`validation.service.ts:58` fuera, `:66` dentro). Si la resolución confirma entre lectura y escritura, el `PENDING` ya no existe, la comprobación pasa y el submit escribe encima.

Probe, 2/2 escenarios: persona `INVESTED`, enrollment `SUBMITTED_FOR_VALIDATION` con `locked_for_validation=true`, `class.completed` ya emitido. Luego la cadena vieja puede volver a investir y emitir otro evento. La ventana abarca todo el trabajo previo del submit. `reject` (~L414/431) tiene el mismo patrón ante un `FIELD_APPROVED`+`PENDING` heredado; `validateEnrollment` y `reviewClass` solo entre operaciones de la vía vieja.

**Corrección requerida:** toda escritura de la vía anterior condiciona el estado de origen dentro de la transacción con candado (`updateMany` con estado esperado y verificación de `count`, o relectura bajo candado), sin emitir ni registrar historial si no coincide.

### H2 — Baja, reproducido: un desajuste en la resolución anula todo el POST

Si el `updateMany` de la resolución no coincide, el 409 `INVESTITURE_REQUEST_LEGACY_PIPELINE_ACTIVE` revierte la resolución completa: otras personas sin relación quedan `PENDING` (IA-03 pide resolución por persona). El código engaña si quien escribió fue la conciliación de certificados. Hoy solo alcanzable por escritores sin candado.

### H3 — Media, bloquea despliegue: ADMIN_PANEL_URL obligatorio con el interruptor global

`EMAIL_ENABLED` gobierna todo el correo, incluida autenticación; no hay interruptor propio de investidura. `docs/runbooks/resend-setup.md` deja staging y producción con `EMAIL_ENABLED=true` y no menciona `ADMIN_PANEL_URL`; `render.yaml` tampoco. Sin la variable el backend no arranca (`app.module.ts:91`, `env.validation.ts:94-100`); con ella, los correos de investidura enlazan a una ruta del panel que no existe. «No activar el correo de investidura hasta que exista la ruta» no se puede cumplir hoy.

### H4 — Baja: sin ADMIN_PANEL_URL y correo apagado, los recordatorios abortan

`requestUrl` lanza dentro de `dueReminders` (rules ~L449/473) y aborta los de todos los Campos; el cron (`investiture-reminder.cron.ts:40`) omite `deliverPending` y las intenciones de presentación quedan pendientes indefinidamente.

### H5 — Baja: la guarda de enlace relativo es parcial

`assertNoRelativeInvestitureLink` evalúa solo la primera coincidencia y acepta un enlace relativo si antes aparece cualquier `https://`. Afecta solo reenvíos de mensajes guardados por código anterior a X-3.

### Observaciones

- **X-2:** la conciliación de certificados no toma los candados de usuario/enrollment; puede crear un `INVESTIDO` entre comprobación y escritura. Se corrige con la entrega diferida de conciliación.
- **X-4:** inventario completo. Imprecisión: `POST /validation/submit` (class) no lo usa ningún cliente vivo; `ValidationSection` de la app envía `class_progress`, que el DTO rechaza. La propuesta de desbloqueo es razonable y sigue sin aprobarse.
- **Corrida roja ausente:** la mayoría de las pruebas nuevas fallarían con `113d8ba`. Huecos: `invests once from FIELD_APPROVED when that confirm races the old invest` no discrimina; ninguna prueba ejercita el `count` distinto en la resolución; ninguna verifica clave/orden del candado en unidad y PostgreSQL solo lo prueba en `invest`. H1 pasó por esos huecos.

**Siguiente paso:** corregir H1 (con regresión PostgreSQL en submit de la vía anterior, validación de clase y `reject`), H3 y H4; H2 y H5 en la misma entrega si no amplían alcance. No ejecutar fase 8 ni desplegar.

## Vigesimocuarta revisión — cierre del residuo temporal P7-1 (2026-10-06)

**Backend de fase 7 ACEPTADO LOCALMENTE PARA CONTINUAR.** P7-1 queda cerrado junto con P7-2/P7-3, cuyo alcance aceptado se conserva. No se encontraron nuevos hallazgos en esta revisión focal. No equivale a completar la fase con pantallas ni a autorizar el cambio de vía/despliegue. Base revisada: `development` @ `113d8ba9b5f0befc7c5a913ebbc7d7c872d2174a`, cambios sin commit. Solo se agregaron evidencias y estado documental; no se modificó runtime.

### P7-1 cerrado: instante efectivo después de esperar

`present` y `addPeople` reciben ahora `now?: Date`. La comprobación inicial usa `enteredAt = decisionInstant(now)`, pero se propaga **el override original**, no `enteredAt`, a `writePeople`. Si el controlador no pasa hora —como ocurre en las dos rutas—, la validación transaccional vuelve a llamar al reloj inyectado después de los candados y de releer el contexto. Una hora explícita conserva el comportamiento fijo para pruebas. El orden año → calendario → sección → usuarios → enrollments se mantiene.

El nuevo probe independiente reproduce el montaje anterior, sin modificar el probe histórico: omite `now`, observa una espera real de advisory lock en `pg_locks`, adelanta el reloj dos segundos y libera el candado de sección. Los cuatro casos pasan:

| Operación | Cruce local en America/Mexico_City | Resultado |
| --- | --- | --- |
| Presentar / agregar | 20 diciembre 23:59:59 → 21 diciembre 00:00:01 | `INVESTITURE_REQUEST_WINDOW_CLOSED` |
| Presentar / agregar | 31 diciembre 23:59:59 → 1 enero 00:00:01 | `INVESTITURE_REQUEST_YEAR_CLOSED` |

En cada caso hay **dos lecturas del reloj, cero personas insertadas, cero llamadas a `stagePresentation` y ningún aumento de filas de dispatch**. Para el cruce de año se configuró ventana hasta el 31 y se dejó el año activo: se rechaza por vencimiento temporal, sin depender de que haya corrido el cierre administrativo. El servicio de comunicaciones del probe es un centinela que falla si se intenta preparar o entregar un aviso; no prueba la entrega real de correo. La suite PostgreSQL existente conserva las carreras de cierre y corte y agrega sus cuatro regresiones temporales.

### Evidencia nueva

| Comprobación | Resultado |
| --- | --- |
| Cierre, historial, anuario, corte, entrega, solicitud y cron | **103 pruebas en 7 suites**, salida 0 |
| Suite PostgreSQL de solicitudes | **38 pruebas**, salida 0 |
| Probe independiente `p7r2-postgres-probe.cjs` | **4 aceptaciones**, salida 0 |
| `tsc --noEmit --incremental false -p tsconfig.build.json` | Salida 0 |
| ESLint `--no-fix` del servicio y del e2e PostgreSQL | Salida 0 |

Archivos: `docs/reviews/investidura-autorizacion-review-evidence/p7r2-{unit.log,types.log,lint.log,postgres-tests.log,probe.log,identity.log,stop.log,exit-code,source-sha256.txt}`, `p7r2-postgres-run.sh` y `p7r2-postgres-probe.cjs`. Los hashes de los cinco archivos runtime/pruebas revisados se conservaron durante la ejecución. Los probes históricos no se tocaron.

**Límites y siguiente paso:** PostgreSQL temporal exclusivo de loopback `sacdia_p7r2_review_test`, bajo `/tmp`, ya detenido. La suite reconstruye su esquema con `prisma migrate diff`; no acredita aplicar las migraciones. Autorización y elegibilidad sintéticas en el probe: no certifica HTTP, JWT/guards reales, UI, Redis ni correo. No hubo build, commit, Neon ni producción. Se puede continuar con la preparación de fase 8, empezando por el inventario y tratamiento explícito de expedientes del pipeline anterior; esta revisión no ejecuta ese inventario ni retira rutas. Fase 2, pantallas e integración siguen pendientes. P5 y fase 6 conservan su aceptación previa.

## Vigesimotercera revisión — correcciones P7-1/P7-2/P7-3 (2026-10-06)

**Fase 7 NO APROBADA: queda un residuo de P7-1.** P7-2 y P7-3 quedan cerrados en el alcance backend probado. La coordinación de P7-1 con el cierre administrativo y el barrido automático sí pasa; falta actualizar el instante efectivo después de esperar. Base: `development` @ `113d8ba9b5f0befc7c5a913ebbc7d7c872d2174a`, cambios sin commit. No se modificó runtime ni se inició fase 8. P5 y la aceptación local de fase 6 se conservan.

### P7-1 residual — Alta / P1: presentar y agregar conservan el reloj anterior a la espera

**Ubicación:** `sacdia-backend/src/investiture-requests/investiture-authorization-requests.service.ts:189,203,213,1077-1079`.

Las dos entradas declaran `now = new Date()` y propagan ese valor a `append`/`writePeople`. Aunque la transacción ahora toma año → calendario → sección → usuarios → enrollments y relee el contexto, `decisionInstant(now)` recibe siempre un valor: devuelve la hora de entrada y **no consulta el reloj después de los candados**. El controlador no pasa `now`; por tanto, también usa ese valor por defecto congelado. No es un defecto limitado a pruebas con fechas explícitas.

**Reproducción independiente en PostgreSQL real:** una segunda conexión sostiene el candado de sección. Se invoca `present` o `addPeople` sin argumento temporal, como el controlador. `pg_locks` confirma la espera; se adelanta el reloj controlado dos segundos y se libera el candado. Se reproducen cuatro casos:

| Operación | Cruce en America/Mexico_City | Resultado incorrecto |
| --- | --- | --- |
| Presentar | 20 diciembre 23:59:59 → 21 diciembre 00:00:01; ventana termina el 20 | Crea `PENDING` |
| Agregar | Mismo cruce de ventana | Crea `PENDING` |
| Presentar | 31 diciembre 23:59:59 → 1 enero 00:00:01; ventana configurada hasta el 31 | Crea `PENDING` en el año terminado |
| Agregar | Mismo cruce de año | Crea `PENDING` en el año terminado |

Año de prueba 2035; no se simuló una espera de meses. El avance fue de dos segundos sobre `Date` controlado y un reloj inyectado equivalente; PostgreSQL, transacciones, lecturas y candados fueron reales. El reloj inyectado recibió **cero lecturas** en cada operación. El año permanece `active=true` en estos casos para aislar el vencimiento por fecha de un cierre administrativo: alcanzar `end_date` también debe impedir nuevas altas.

**Corrección requerida:** no convertir la hora de entrada implícita en un override permanente. Cuando el llamador no proporciona una fecha explícita, usar el reloj inyectable para cada validación temporal y volver a leerlo después de esperar, antes de escribir. Conservar el protocolo de candados corregido. Cubrir ambos métodos sin `now` explícito, cruzando fin de ventana y fin de año; comprobar ausencia de nuevas personas pendientes y de intenciones de presentación. Mantener las carreras ya aceptadas. No hace falta reabrir P7-2/P7-3 ni modificar probes históricos.

### Correcciones aceptadas en este alcance

- **P7-1, coordinación del cierre:** la suite PostgreSQL confirma que una presentación/agregado que obtuvo el candado del año primero queda incluida en el cierre; si el año pasa a inactivo mientras espera, no inserta. El corte también incluye altas en espera sin pendientes iniciales. Esto no cubre el reloj congelado descrito arriba.
- **P7-2 cerrado:** el barrido toma los candados de los años terminados antes de leer pendientes. La prueba real cubre club con transición completada y otro sin actividad de corte, conserva `INVESTED`, no crea solicitud del año siguiente ni activa cargos ni reinscribe, y un segundo corte cierra cero filas.
- **P7-3 cerrado:** el anuario combina membresías históricas del mismo club con el tipo de clase de la sección consultada. La prueba real coloca la clase cruzada de Conquistadores del miembro GM en Conquistadores, mantiene GM separado, devuelve vacío para otro club y no exige solicitud de investidura. Los permisos focales siguen pasando en unidad; no se certifica autenticación real.

### Evidencia repetida y límites

| Comprobación | Resultado |
| --- | --- |
| Cierre, historial, anuario, corte, entrega, solicitud y cron | **103 pruebas en 7 suites**, salida 0 |
| Suite PostgreSQL de solicitudes | **34 pruebas**, salida 0; incluye las ocho incorporadas desde la revisión 22 |
| Probe independiente `p7r1-postgres-probe.cjs` | **Cuatro reproducciones** del residuo temporal; salida 0 porque las assertions comprueban el defecto, NO porque se acepte la fase |
| `tsc --noEmit --incremental false -p tsconfig.build.json` | Salida 0 |
| ESLint `--no-fix` sobre los diez archivos de cierre/solicitud y sus pruebas | Salida 0 |

Evidencias nuevas: `docs/reviews/investidura-autorizacion-review-evidence/p7r1-{unit.log,types.log,lint.log,postgres-tests.log,probe.log,identity.log,stop.log,exit-code,source-sha256.txt}`; ejecutables `p7r1-postgres-run.sh` y `p7r1-postgres-probe.cjs`. No se tocaron probes ni evidencias históricas. El runner crea un clúster exclusivo bajo `/tmp`, escucha solo loopback y usa `sacdia_p7r1_review_test`; al finalizar quedó detenido. El helper de la suite reconstruye `public` con `prisma migrate diff`: esto **no certifica aplicación de migraciones**. El probe usa autorización y elegibilidad sintéticas y no conecta comunicaciones; no certifica HTTP, JWT/guards reales, UI, Redis ni correo. No hubo build, Neon, producción, commit ni despliegue. Fase 2 parcial, pantallas e integración pendientes y pipeline anterior activo.

## Vigesimosegunda revisión — fase 7: cierre anual, historial y anuario (2026-10-06)

**Fase 7 NO APROBADA.** Se reproducen **dos hallazgos de prioridad alta y uno de prioridad media** con Prisma/PostgreSQL reales, en una base temporal exclusiva de loopback. Base revisada: `development` @ `113d8ba9b5f0befc7c5a913ebbc7d7c872d2174a`, cambios sin commit. El backend de fase 6 conserva su aceptación local; no se reabren sus cierres ni los de P5. No se modificó runtime, no se inició fase 8 y no hay autorización de despliegue.

### P7-1 — Alta / P1: una presentación en espera puede confirmar un pendiente después del cierre anual

**Ubicación:** `sacdia-backend/src/investiture-requests/investiture-authorization-requests.service.ts:180-198,1008-1025`; integración con `sacdia-backend/src/year-end/year-end.service.ts:175-187`.

`present` y `addPeople` comprueban año/ventana antes de entrar a la transacción. `writePeople` bloquea sección, usuarios y enrollments, pero no toma el candado del año ni vuelve a comprobar su estado después de esperar. `closeYear` sí bloquea el año, cierra los pendientes visibles y marca el año inactivo. Si todavía no hay pendientes, el helper retorna sin tomar el candado de sección; la presentación puede continuar después del cierre con el contexto anterior.

**Reproducción real:** una conexión sostiene el advisory lock de sección/año. Se llama a `present` real con un año activo y fecha permitida; `pg_locks` confirma una espera no concedida. Mientras espera, `closeYear` real confirma el año inactivo y cero pendientes cerrados. Se libera el lock: **`present` responde con éxito y persiste una fila `PENDING` en ese año ya cerrado**. Repetir `closeYear` devuelve HTTP-semántico 400 `YEAR_END_YEAR_CLOSED` desde el servicio y no barre esa fila tardía. No se invocó un endpoint HTTP.

**Impacto:** el año puede quedar cerrado pero con solicitudes activas sin historia `CLOSED_YEAR`; el bloqueo de progreso asociado al pendiente tampoco queda liberado por ese cierre. Esto viola el cierre exhaustivo exigido por IA-30.

**Corrección requerida:** coordinar presentación/agregado y cierre con el mismo protocolo de candados del año, en orden consistente, y releer el estado/calendario con el instante efectivo después de esperar y antes de escribir. La comprobación externa no basta. Garantizar que una operación previa o queda incluida en el cierre o es rechazada si el cierre confirmó primero. Cubrir presentar y agregar contra cierre administrativo y corte automático en PostgreSQL, incluida ausencia inicial de pendientes; no basta comprobar llamadas a `$executeRaw` en un mock.

### P7-2 — Alta / P1: el corte automático no descubre clubes con solo solicitudes pendientes

**Ubicación:** `sacdia-backend/src/year-cut/year-cut.service.ts:166-206`; cierre invocado desde `cutClub` en `:209-224`.

`collectClubIds` solo reúne cargos activos vencidos, sucesiones programadas y transiciones de club no completadas. **No incluye los clubes de solicitudes pendientes de años terminados.** Aunque `cutClub` intenta cerrar investiduras antes de retornar por una transición `completed`, esa protección no se ejecuta si el club nunca entra a la lista.

**Reproducción real:** se conserva una fila `PENDING` del año terminado; ya no hay cargos activos vencidos ni planes programados y la transición del club para el año entrante está `completed`. `applyCut` real retorna todos los contadores en cero, con el mensaje de que no hay nada que procesar; **la fila del año anterior permanece `PENDING`**. En el probe se utiliza la fila tardía del caso anterior, pero el problema de descubrimiento también aplica a cualquier pendiente preexistente con esos mismos estados de membresía/transición.

**Corrección requerida:** incorporar al barrido los clubes/secciones con pendientes de años terminados, independientemente de si terminó su transición de membresía, o ejecutar un barrido equivalente separado. Repetirlo debe cerrar solicitudes sin volver a inscribir, activar cargos ni crear solicitudes del año siguiente. Cubrir explícitamente club con transición completada y club sin otra actividad de corte. Mantener `INVESTED` intacto.

### P7-3 — Media / P2: el anuario filtra miembros de la sección, pero mezcla sus clases de otras secciones

**Ubicación:** `sacdia-backend/src/investiture-requests/investiture-authorization-requests.service.ts:438-462`.

El gate comprueba correctamente el cargo sobre la sección solicitada. Sin embargo, la consulta de enrollments solo usa `record_kind: OPERATIONAL` y pares **usuario/año** de sus membresías. No resuelve la sección correspondiente a cada clase; devuelve todas las clases operativas de esa persona/año, aunque su tipo corresponda a otra sección. El contrato de anuario de la fase 7 lo circunscribe a la sección; la regla vigente de clases cruzadas distingue sección de membresía y sección de la clase.

**Reproducción real:** una persona con membresía en Guías Mayores y enrollments operativos de Amigo/Conquistadores (cruzado) y Guía Mayor en el mismo año. El anuario de la sección GM devuelve **ambas clases**. También se comprueba que consultar otra sección y actuar como subdirector son rechazados: el defecto está en la selección de filas, no en ese gate.

**Corrección requerida:** atribuir cada inscripción a su sección/clase y club correspondientes, incluyendo la regla de clase cruzada, antes de listar el anuario. No resolverlo simplemente descartando toda clase cruzada: la clase de Conquistadores de alguien con membresía GM debe aparecer en la sección que le corresponde del mismo club. Cubrir persona con dos clases de tipos distintos, membresía GM con clase cruzada, y otro club, además de los permisos ya aceptados. Conservar la lectura histórica sin exigir una solicitud de investidura para aparecer en el anuario.

### Qué sí se comprobó

- Las suites de cierre, historial y anuario pasan sus casos secuenciales: se actualiza solo `PENDING`, no se inventa una solicitud del año siguiente y `CLOSED_YEAR` conserva clase/año sin el texto de rechazo en el historial.
- Las pruebas existentes de continuidad mantienen el corte ya completado sin otra inscripción; las de recordatorio excluyen `CLOSED_YEAR`. No se extiende este resultado al descubrimiento exhaustivo ni a la carrera de P7-1.
- En el probe con DB real, el gate del anuario acepta director, secretario y secretario-tesorero y rechaza otra sección/subdirector. El `AuthorizationSnapshot` es sintético: no certifica JWT, resolución real de cargos ni guard HTTP.

### Evidencia repetida y límites

| Comprobación | Resultado |
| --- | --- |
| Cierre, historial, anuario, corte, entrega, solicitud y cron | **101 pruebas en 7 suites**, salida 0. Los conteos 42 y 31 reportados por el implementador se solapan; no se sumaron como pruebas distintas. |
| Suite de regresión PostgreSQL de solicitudes | **26 pruebas**, salida 0 en la base temporal propia. No equivale a 26 pruebas nuevas de fase 7. |
| Probe independiente PostgreSQL | Reproduce P7-1 con espera real de advisory lock, P7-2 y P7-3; acepta los gates focales. Segundo pase completo salida 0: las assertions incluyen reproducciones de defectos. |
| Tipos runtime y ESLint focal `--no-fix` | Salida 0. |
| `git diff --check` raíz/backend y hashes de fuentes | Sin diagnósticos / fuentes revisadas sin cambios al cierre. |

El primer pase del probe reprodujo P7-1/P7-2 y se detuvo por un **error del fixture** al intentar crear una sección GM ya sembrada. Se corrigió únicamente el probe para reutilizarla y se repitió todo en otra base nueva; se conservan los logs del primer pase. No fue un defecto runtime adicional. Los dos servidores PostgreSQL temporales se detuvieron al finalizar y no se usó una base preexistente, Neon ni producción.

El schema de la suite se reconstruye con `prisma migrate diff`, más sus índices de prueba: **no certifica aplicación de las migraciones SQL**. En el probe son reales los servicios, consultas, transacciones y locks; son sintéticos el snapshot de autorización, el resultado de elegibilidad, el servicio de año actual del corte y dependencias sin uso en esos escenarios. No se envió correo ni se ejecutó UI, autenticación HTTP real, build, commit o despliegue. No se ampliaron unidades ni finanzas.

**Evidencia nueva:** `docs/reviews/investidura-autorizacion-review-evidence/p7-postgres-probe.cjs`, `p7-postgres-run.sh`, logs `p7-postgres-*`, logs iniciales `p7-first-*`, `p7-unit.log`, `p7-types.log`, `p7-lint.log` y `p7-source-sha256.txt`. Probes de revisiones anteriores intactos.

**Siguiente paso:** corregir P7-1/P7-2/P7-3 y repetir aceptación. No iniciar fase 8 ni retirar el pipeline anterior. La fase 2 parcial, pantallas e integración siguen pendientes.

## Vigesimoprimera revisión — cierre local de P6-3 (2026-10-06)

**P6-3 CERRADO en el alcance revisado.** El backend de fase 6 queda **aceptado para continuar el desarrollo de fase 7**, no certificado para producción ni como entrega integral del plan. No se encontraron nuevos bloqueantes en esta revisión focal. P6-1/P6-2/P6-4/P6-5 y los cierres de P5 se conservan. Base: `development` @ `113d8ba9b5f0befc7c5a913ebbc7d7c872d2174a`, cambios sin commit. Esta revisión no modifica runtime ni inicia fase 7.

### Corrección comprobada

El worker copia el borrador de `prepare` antes del render y usa la misma instantánea para el destino, los párrafos renderizados y el alcance que entrega a `recordProviderAttempt`. Este último ya no reconstruye el alcance con una segunda `freshMail`; copia los metadatos recibidos junto al cuerpo. La lectura actual del reintento decide si ese contenido sigue permitido, sin redefinir qué contenía el intento original.

**Intercalación aceptada:** retirar el distrito 5 durante el render, antes de persistir el intento. El body y el scope conservan a Bruno del distrito 5; el borrador posterior ya no. Tras un primer fallo del proveedor antes de aceptar, el reintento termina `skipped`, con **0 aceptaciones**, sin cambiar el intento persistido ni su clave. Ya no se reproduce el desajuste de la revisión 20.

También se comprobaron:

- Retiro parcial de uno de dos distritos después del primer fallo: `skipped`, 0 aceptaciones.
- Retiro completo del pastor, traslado del director de Campo, año cerrado y cero pendientes: sin segunda llamada al proveedor.
- Estados `sent`, `skipped`, `uncertain`: el reintento no los reactiva.
- Cambio de dirección de correo y un intento antiguo sin scope: cierre conservador, sin reenvío ni modificación del intento. El cierre de este último caso no certifica una estrategia de recuperación operativa para datos antiguos.
- Acuse perdido con cambio de ventana pero contenido aún autorizado: conserva body/clave, una aceptación y `sent`.
- Límites de 24 horas exactas y 25 horas: no vuelve a enviar, queda `uncertain` cuando las demás condiciones siguen siendo válidas.
- Intención durable, recuperación parcial sin correo duplicado al pastor, preferencias, persistencia de bandeja simulada y ventana efectiva: regresiones focales conservadas.

### Verificaciones y límites

| Comprobación | Resultado |
| --- | --- |
| Reglas, entrega, solicitud y correo | **90 pruebas, 4 suites**, salida 0. |
| Redis temporal exclusivo en loopback | **12 pruebas del archivo: 2 propias + 10 importadas de entrega**, salida 0. Cola y worker reales; proveedor y render sustituidos, sin correo real. |
| Nuevo probe independiente | **24 escenarios aceptados**, salida 0. Runtime real con datos Prisma/proveedor/render simulados y assertions propias. Incluye correspondencia de la instantánea, revocación durante render, cambio de correo y scope ausente. |
| Tipos y lint focal | `tsc --noEmit --incremental false -p tsconfig.build.json` y ESLint `--no-fix` de los archivos revisados: salida 0. |
| Integridad | Hashes de cuatro fuentes revisadas sin cambios; `git diff --check` raíz/backend, salida 0. |

No se reejecutó PostgreSQL en esta revisión focal: las **26 pruebas y el probe real de la revisión 18 son evidencia histórica**, no una nueva ejecución. No se certifican la aplicación de migraciones, HTTP/autenticación real, render final (continúa la limitación local React), Resend/FCM reales, pantallas ni despliegue. Redis se ejecutó en un puerto temporal de loopback, con teardown de la suite.

Este cierre **no promete exactly-once externo ni elimina la posibilidad de cambios después de la última lectura de autorización**. Se cierra el desajuste persistente entre body y scope y las regresiones reproducidas, no toda carrera posible entre una lectura y una llamada de red. No hubo builds, commits, cambios runtime, Neon ni correo real.

**Evidencia nueva:** `docs/reviews/investidura-autorizacion-review-evidence/p6r5-acceptance-probe.cjs`, `p6r5-acceptance.log`, `p6r5-unit.log`, `p6r5-redis.log`, `p6r5-types.log`, `p6r5-lint.log`, `p6r5-source-sha256.txt`. Los probes históricos se conservaron sin modificar; que el probe anterior se detenga en una assertion del defecto viejo no es por sí solo evidencia de aceptación, por eso se ejecutó esta nueva versión completa.

**Siguiente paso:** fase 7 del plan — historial, anuario y cierre anual. En el backend, priorizar cierre administrativo y automático idempotentes: pendientes quedan no investidos en su año, sin arrastre ni reapertura, y cesan sus recordatorios. La fase 7 no se implementó en esta revisión. La fase 2 parcial, pantallas, integración y condición de inventario/apagado del pipeline anterior mantienen bloqueado el despliegue.

## Vigésima revisión — alcance del contenido congelado (2026-10-06)

**Fase 6 NO APROBADA.** El caso territorial de la revisión 19 ya está corregido, pero **P6-3 sigue abierto por un desajuste reproducible al registrar el intento**. El alcance guardado puede proceder de una lectura distinta de la usada para construir el cuerpo. Se conservan los demás cierres; sin cambios runtime, commits ni fase 7. Base revisada: `development` @ `113d8ba9b5f0befc7c5a913ebbc7d7c872d2174a`.

### Aceptaciones

- El retiro de uno de dos distritos **después del primer fallo del proveedor** deja ahora `skipped` y 0 aceptaciones. El proveedor no recibe el distrito retirado.
- Siguen pasando los cuatro bloqueos totales, los estados terminales y los límites de 24/25 horas.
- Se conservan las regresiones focales de intención durable, recuperación parcial sin duplicado, bandeja, preferencias y ventana. Cambiar la ventana sin retirar el contenido autorizado conserva el cuerpo y la clave del intento.

### P6-3 residual — Alta / P1: el alcance guardado no necesariamente describe el cuerpo guardado

**Ubicación:** `sacdia-backend/src/investiture-requests/investiture-communications.service.ts:366-375`; origen del mensaje en `sacdia-backend/src/common/email/email.processor.ts:216-234`.

El worker obtiene `fresh`, espera el render y construye `message` con esos datos. Después, `recordProviderAttempt` recibe ese mensaje pero vuelve a consultar `freshMail` para fabricar `scope`. Guarda el cuerpo de la primera lectura junto al alcance de la segunda. `frozenScopeCovered` compara correctamente el alcance persistido, pero este puede no describir el correo que se va a reenviar.

**Reproducción independiente:**

1. `prepare` obtiene Ana del distrito 4 y Bruno del distrito 5, ambos asignados al pastor.
2. Durante el render asíncrono se retira al pastor del distrito 5. El cuerpo ya construido contiene a ambos.
3. La nueva lectura de `recordProviderAttempt` solo incluye a Ana. Se persiste **body: Ana + Bruno; scope: Ana**.
4. El primer proveedor falla **antes de aceptar**. Al reintentar, el mundo sigue igual: solo distrito 4 autorizado.
5. El alcance reducido pasa la validación, pero se envía el cuerpo completo: **1 aceptación con Bruno fuera de alcance y estado `sent`**.

El probe verifica explícitamente que `scope.paragraphs` y el borrador fresco excluyen a Bruno, mientras `body` y el mensaje aceptado lo incluyen. Son métodos runtime reales con datos Prisma, proveedor y render simulados; la intercalación se fuerza durante el `await` de render, sin depender de tiempos aleatorios. No se afirma una incidencia real en producción ni una carrera demostrada con PostgreSQL. No es simplemente una revocación que ocurre después de la última lectura: el intento queda persistentemente incoherente y un reintento posterior con permisos ya estables sigue pasando.

**Corrección requerida:** derivar cuerpo, destino y alcance de **la misma instantánea inmutable** que se usa para renderizar. Pasar esa instantánea/metadatos a la persistencia del intento; no reconstruir su alcance con otra lectura. Una lectura adicional puede decidir si todavía se permite enviar, pero no debe reducir silenciosamente el alcance que describe el cuerpo anterior. Conservar la clave, el cuerpo y el horizonte del intento; no eludir el problema renovando la clave. Agregar la regresión con retiro entre `prepare` y persistencia y comprobar tanto la correspondencia body/scope como cero entregas fuera de alcance. Mantener todas las aceptaciones anteriores.

### Evidencia y límites

- **89 pruebas unitarias, 4 suites**, salida 0.
- `tsc --noEmit --incremental false -p tsconfig.build.json` y ESLint `--no-fix` focal: salida 0. `git diff --check` raíz/backend y hashes de cuatro fuentes revisadas sin cambios.
- **11 pruebas del archivo Redis**, salida 0: 2 propias y 9 importadas de entrega. Redis temporal exclusivo en loopback, cola/worker reales, proveedor y render simulados; teardown de la suite.
- Probe nuevo **22 escenarios**, salida 0: **21 aceptaciones y 1 reproducción del desajuste**. El exit 0 acredita las assertions del probe, no aprobación de la fase.
- No se reejecutó PostgreSQL: la evidencia de 26 pruebas de la revisión 18 sigue siendo histórica. Sin correo real, render final, HTTP/autenticación real, UI ni aplicación de migraciones. Sin Neon, builds ni despliegue.

**Evidencia nueva:** `docs/reviews/investidura-autorizacion-review-evidence/p6r4-acceptance-probe.cjs`, `p6r4-acceptance.log`, `p6r4-unit.log`, `p6r4-redis.log`, `p6r4-types.log`, `p6r4-lint.log`, `p6r4-source-sha256.txt`. Los probes históricos permanecen sin cambios.

**Siguiente paso:** corregir la correspondencia entre cuerpo y alcance de P6-3 y repetir aceptación. Fase 7 no iniciada; fase 2 parcial, pantallas pendientes, pipeline anterior activo y despliegue bloqueado.

## Decimonovena revisión — revalidación del reintento congelado (2026-10-06)

**Fase 6 NO APROBADA.** Los cuatro casos de P6-3 de la revisión 18 quedaron corregidos, pero **P6-3 sigue abierto por un residuo de alcance parcial**. Se conservan los cierres anteriores de P6-1/P6-2/P6-4/P6-5 y P5. Revisión de `development` @ `113d8ba9b5f0befc7c5a913ebbc7d7c872d2174a`, cambios sin commit. No se modificó runtime ni se inició fase 7.

### Qué quedó aceptado

- Tras un primer fallo del proveedor **antes de aceptar**, el retiro completo del pastor, traslado del director a otro Campo, cierre del año y cero pendientes dejan el aviso `skipped`, con **0 aceptaciones** y sin segunda llamada al proveedor.
- Un reintento congelado respeta los estados `sent`, `skipped` y `uncertain`, sin envío adicional.
- Permanecen los casos de recuperación parcial sin segundo correo al pastor y contenido congelado tras acuse perdido/cambio de ventana. A las 25 horas queda `uncertain`; se agregó además el límite **exacto de 24 horas**, sin nueva llamada.

### P6-3 residual — Alta / P1: basta conservar un distrito para recibir el contenido de otro ya revocado

**Ubicación:** `sacdia-backend/src/investiture-requests/investiture-communications.service.ts:341-346`; envío del cuerpo congelado en `sacdia-backend/src/common/email/email.processor.ts:202-212`.

`deliveryStillAllowed` devuelve `true` si `freshMail` devuelve cualquier borrador. El borrador nuevo filtra correctamente los distritos actuales, pero no se compara ese alcance con el contenido del intento persistido. El worker no envía el borrador filtrado: envía el cuerpo completo guardado. Por tanto, comprobar que existe algún contenido permitido NO comprueba que todo el contenido congelado siga permitido.

**Reproducción independiente:**

1. Un pastor está asignado a los distritos 4 y 5 del mismo Campo. El recordatorio agrupa a Ana del 4 y Bruno del 5.
2. El primer intento guarda el cuerpo y el proveedor simulado falla **antes de aceptar**.
3. Se retira al pastor únicamente del distrito 5; conserva el 4.
4. `prepare` devuelve un borrador que ya no contiene a Bruno: el cálculo territorial fresco funciona. Sin embargo, `deliveryStillAllowed` acepta ese borrador no vacío y el reintento envía el cuerpo congelado que **sí contiene a Bruno**. Resultado: **1 aceptación fuera de alcance y dispatch `sent`**.

Se ejecutaron processor, servicio, loader y reglas reales con datos Prisma, renderer y proveedor simulados. No se afirma que haya ocurrido en producción. Este caso no está cubierto por retirar toda la asignación del único distrito del fixture anterior.

**Corrección requerida:** comprobar que **todo el contenido y destino del intento congelado** continúan autorizados, no solo que queda alguna solicitud válida. Conservar metadatos estructurados suficientes del intento para validar su alcance completo; si parte ya no corresponde, detener ese envío congelado sin marcarlo como entregado. No sustituir el cuerpo bajo la misma clave ni generar otra clave para eludir la idempotencia. Mantener los casos aceptados de cuerpo estable, ventana modificada, límites de 24 horas y estados terminales. Añadir la regresión de dos distritos con retiro de uno y una comprobación negativa de que no llegan datos del distrito retirado.

### Evidencia y límites

- **88 pruebas, 4 suites**, salida 0: reglas, entrega, solicitud y correo.
- **10 pruebas del archivo Redis**, salida 0: 2 propias y 8 importadas de entrega. Redis temporal exclusivo en loopback, cola/worker reales, proveedor/render simulados; teardown de la suite.
- `tsc --noEmit --incremental false -p tsconfig.build.json` y ESLint `--no-fix` de los cuatro archivos revisados: salida 0. `git diff --check` raíz/backend y hashes de fuentes comprobados.
- Nuevo `p6r3-acceptance-probe.cjs`: **21 escenarios**, salida 0, con **20 aceptaciones y 1 reproducción del residuo parcial**. El éxito del proceso significa que las assertions —incluida la reproducción— se cumplieron; no que la fase esté aprobada.
- No se reejecutó PostgreSQL en esta revisión focal. Las 26 pruebas y el probe de la revisión 18 son evidencia anterior, no resultados nuevos. No cambió el cierre acotado de identidad transaccional/bandeja.
- Sin correo real, render final, HTTP/autenticación real, UI ni aplicación de migraciones. No builds, commits, Neon ni despliegue. Los probes históricos permanecen intactos.

**Evidencia nueva:** `docs/reviews/investidura-autorizacion-review-evidence/p6r3-acceptance-probe.cjs`, `p6r3-acceptance.log`, `p6r3-unit.log`, `p6r3-redis.log`, `p6r3-types.log`, `p6r3-lint.log` y `p6r3-source-sha256.txt`.

**Siguiente paso:** resolver este residuo territorial de P6-3 y repetir aceptación. La fase 7 no se inició; fase 2 parcial, pantallas pendientes, pipeline anterior activo y despliegue bloqueado.

## Decimoctava revisión — identidad y acuse ambiguo (2026-10-06)

**Fase 6 NO APROBADA.** Se cierran **P6-1 residual A/B y P6-2 residual** en los escenarios comprobados. **P6-3 se REABRE**: el nuevo camino de reintento congelado omite la validación que sí ejecuta el primer intento. P6-4/P6-5 y los cierres de P5 se conservan. Revisión sobre `development` @ `113d8ba9b5f0befc7c5a913ebbc7d7c872d2174a`, cambios sin commit. Sin implementación runtime ni fase 7.

### Correcciones aceptadas en alcance

- **P6-1 A, identidad y PostgreSQL:** cada `writePeople` genera una identidad y la propaga a la intención transaccional y a la materialización posterior. `stage` usa `INSERT ... ON CONFLICT DO NOTHING`. El probe independiente con Prisma/PostgreSQL reales confirma que dos operaciones nuevas sobre los mismos enrollments y distintas cabeceras dejan **2 marcadores y 2 intenciones**. Reintentar una identidad explícita conserva esas 2 intenciones y confirma los marcadores escritos antes y después del conflicto: no deja abortada la transacción. La suite PostgreSQL repetida también cubre quitar y volver a agregar en la misma cabecera, presentar en otra y volver tras rechazo, usando servicios reales y elegibilidad simulada; no HTTP real.
- **P6-1 B, recuperación parcial:** fallo al crear el destinatario director-lf después de encolar al pastor; se entrega al pastor, se resuelve Ana y se recupera el aviso de Ana/Bruno. Ahora conserva **1 dispatch y 1 aceptación para ese pastor**, sin cambiar la identidad por el subconjunto pendiente.
- **P6-2, contenido y horizonte:** se persisten destino, remitente, asunto, HTML, texto y clave del intento. Tras aceptación simulada y acuse local perdido, cambiar la ventana no cambia el cuerpo reintentado: **1 aceptación y estado `sent`**. A las 25 horas, **1 aceptación y estado `uncertain`**, sin segundo envío automático. Son pruebas con proveedor simulado, no garantía de entrega única ni comprobación en Resend. Este cierre no absorbe la regresión de autorización descrita abajo.

### P6-3 reabierto — Alta / P1: el reintento congelado omite las condiciones de entrega

**Ubicación:** `sacdia-backend/src/common/email/email.processor.ts:200-212`; `sacdia-backend/src/investiture-requests/investiture-communications.service.ts:320-326`.

`processInvestiture` consulta `providerAttempt` antes de `prepare`. Si existe un intento de menos de 24 horas, deserializa el cuerpo, llama al proveedor y confirma, sin pasar por `prepare`/`freshMail`. `providerAttempt` solo lee el payload: no valida destinatario, rol, territorio, año ni pendientes. Congelar el mensaje preserva idempotencia, pero NO conserva el permiso para enviarlo.

**Reproducción independiente, cuatro escenarios:**

1. Encolar un recordatorio válido y ejecutar el worker. El proveedor simulado falla **antes de aceptar**; queda guardado `providerAttempt`.
2. Antes del reintento, retirar al pastor; en casos separados, trasladar al director a otro Campo, cerrar el año o dejar cero pendientes.
3. Reejecutar el mismo job antes de 24 horas. En los cuatro casos el proveedor acepta **1 correo obsoleto** y el dispatch acaba en **`sent`**. Hubo 2 llamadas: una fallida antes de aceptación y una aceptación posterior al cambio.

No depende de una aceptación previa que el proveedor pueda deduplicar: el primer intento no se aceptó. Viola la regla explícita del plan de comprobar condiciones antes de enviar, **incluidos los reintentos**. Los cuatro casos de primer intento sin `providerAttempt` siguen pasando; por eso las pruebas anteriores no detectaban esta rama nueva.

**Corrección requerida:** separar la validación actual de entrega de la reconstrucción del contenido. Antes de cualquier llamada al proveedor, también con intento congelado, validar estado del dispatch, destinatario/rol/territorio, año y pendientes. Si ya no corresponde, no enviar ni marcar éxito de entrega. Conservar el cuerpo y la clave del intento cuando sí siga autorizado; NO volver al payload mutable ni renovar la clave. Respetar `uncertain` y los estados terminales. Añadir las cuatro regresiones con fallo previo a aceptación y conservar los casos de acuse perdido/contenido cambiado y horizonte de 24 horas.

### Evidencia repetida y límites

| Comprobación | Resultado |
| --- | --- |
| Reglas, entrega, solicitud y correo | 4 suites, **87 pruebas aprobadas**, salida 0. |
| PostgreSQL temporal exclusivo | **26 aprobadas**, salida 0; base nueva `sacdia_p6r2_review_test`, loopback. |
| Probe PostgreSQL independiente | Identidad nueva y reintento transaccional comprobados; bandeja conserva 1 log/1 delivery tras acuse fallido y reintentos concurrentes. Push simulado invocado 2 veces, sin promesa exactly-once de push. |
| Redis temporal exclusivo | **9 aprobadas**: 2 propias y 7 importadas de entrega. Cola/worker reales, proveedor simulado y render sustituido. |
| Probe de aceptación nuevo | **16 escenarios**, salida 0: 12 aceptaciones focales y 4 reproducciones de la regresión P6-3. Assertions independientes, runtime real, fixture Prisma/proveedor/render sintéticos. |
| Tipos y lint focal | `tsc --noEmit --incremental false -p tsconfig.build.json` y ESLint `--no-fix` de cinco archivos runtime revisados, ambos salida 0. |
| Integridad | `git diff --check` raíz/backend, salida 0; hashes de cinco fuentes revisadas sin cambios al cierre. |

El PostgreSQL se creó solo para esta revisión y se detuvo al terminar; el primer intento sandbox no pudo abrir el puerto y no ejecutó la suite. Se repitió con permiso. La suite reconstruye el schema con `prisma migrate diff`: no prueba aplicar las migraciones SQL. Redis se detiene en su teardown. No se enviaron correos reales; no se certifican render final (limitación React existente), HTTP/autenticación real, UI, migraciones en Neon ni despliegue.

**Evidencia nueva:** `docs/reviews/investidura-autorizacion-review-evidence/p6r2-acceptance-probe.cjs`, `p6r2-acceptance.log`, `p6r2-postgres-probe.cjs`, `p6r2-postgres-run.sh`, logs `p6r2-postgres-*`, `p6r2-unit.log`, `p6r2-redis.log`, `p6r2-types.log`, `p6r2-lint.log` y `p6r2-source-sha256.txt`. Los probes históricos `p6-dispatch-probe.cjs` y `p6r1-*` no se modificaron.

**Siguiente paso:** corregir únicamente la regresión P6-3 y repetir estos casos antes de aprobar fase 6. La fase 2 sigue parcial, pantallas pendientes, pipeline anterior activo y despliegue bloqueado.

## Decimoséptima revisión — correcciones P6-1 a P6-5 (2026-10-06)

**Fase 6 NO APROBADA.** Se cierran **P6-3, P6-4 y P6-5 en el alcance comprobado**. **P6-1 y P6-2 siguen abiertos** por los residuos descritos abajo. Se verificó `development` @ `113d8ba9b5f0befc7c5a913ebbc7d7c872d2174a`, sin commit. P5-1/P5-2/P5-3 conservan su cierre. Fase 7 no iniciada; despliegue bloqueado, pipeline anterior activo y pantallas pendientes.

### Qué sí quedó comprobado

- **P6-1, avance parcial:** `stagePresentation` y `stageResults` se llaman con `tx` dentro de las escrituras de negocio. Un fallo posterior de lectura deja la intención y la recuperación materializa los destinatarios. No se acepta todavía la identidad de operación ni la recuperación parcial (ver residuos).
- **P6-2, avance parcial:** `queued` ya no equivale a `sent`; el worker llama a `acknowledge` tras el acuse del proveedor. Un claim vencido se recupera. La prueba Redis real repite cinco fallos, reinicia el worker y reactiva el mismo job; pasa. Esto no resuelve todas las variantes de acuse ambiguo con el proveedor real.
- **P6-3 CERRADO, recordatorios:** processor y gate reales comprueban nuevamente el mundo antes de llamar al proveedor. Retiro pastoral, traslado del cargo de Campo, año cerrado y cero pendientes dejan el dispatch `skipped` y **cero llamadas al proveedor** en cuatro escenarios independientes. Se mantiene la separación por rol. No certifica cambios concurrentes que ocurran después de esa última lectura ni HTTP/auth real.
- **P6-4 CERRADO, persistencia de bandeja:** ya no depende del éxito best-effort de `sendToUser`. En PostgreSQL real, una escritura de acuse inyectada que falla y dos reintentos concurrentes dejan **1 log, 1 delivery y dispatch `sent`**. La clave única evita duplicar bandeja. Los fallos de persistencia siguen reintentables. La prueba con `NotificationPreferencesService` real y datos simulados confirma que `approvals=false` impide persistir/emitir este aviso. El push es best-effort: en el escenario del acuse perdido hubo dos invocaciones al doble de push; este cierre NO promete exactly-once de FCM ni certifica entrega real al dispositivo.
- **P6-5 CERRADO:** primer envío y `prepare` usan la misma ventana efectiva. Se probaron default octubre–diciembre abierto, ventana explícita vencida y W1 (año enero–junio, febrero, sin intersección). W1 conserva el aviso de ventana cerrada; no abre todo el año.

### P6-1 residual A — Alta / P1: otra presentación válida del mismo enrollment colisiona y revierte la transacción

**Ubicación:** `sacdia-backend/src/investiture-requests/investiture-communications.service.ts:97-109,315-341`; integración `investiture-authorization-requests.service.ts:946-949`.

La intención se identifica únicamente por el hash de `enrollmentIds`, con destinatario/rol/alcance constantes `intent`. No identifica el evento de presentación ni incluye la solicitud. Quitar/rechazar y volver a presentar los mismos enrollments es una **operación nueva permitida**, pero choca con la intención anterior, incluso en otra cabecera. `stage` captura el `P2002` del insert como si fuera un reintento inocuo; dentro de PostgreSQL la transacción ya quedó abortada.

**Reproducción PostgreSQL/Prisma reales:** dos transacciones usan `stagePresentation` real con requests distintos y el mismo enrollment sintético; antes de cada llamada se escribe un marcador de negocio. La primera persiste. La segunda retorna sin excepción al llamador (`error: null`), pero el marcador 2 desaparece: **solo marcador 1 y la intención de la primera solicitud**. Esto demuestra rollback real causado por la colisión, no una emulación de transacciones. No se ejecutó un endpoint HTTP ni un ciclo completo presentar/quitar/presentar: el impacto en esa ruta se deriva de la llamada a `stagePresentation` dentro de `writePeople`.

**Corrección requerida:** dar identidad propia e inmutable a cada operación nueva de presentación/agregado. No usar solo enrollment IDs ni solo request ID (también se reutiliza una cabecera vacía). Resolver deduplicación de reintentos con una escritura que no deje abortada la transacción; capturar una violación única no la recupera. Cubrir PostgreSQL real con presentar → quitar/rechazar → volver a presentar, en la misma y otra cabecera, y comprobar tanto la solicitud persistida como su nueva intención.

### P6-1 residual B — Alta / P1: recuperar una intención parcial puede volver a avisar a un destinatario ya atendido

**Ubicación:** `sacdia-backend/src/investiture-requests/investiture-communications.service.ts:360-390`; `investiture-communications.rules.ts`, función `presentationDrafts`.

El ID de cada correo se recalcula con las personas que **siguen pendientes al materializar**, no con una identidad estable de la intención. Si se interrumpe la creación de destinatarios y luego se resuelve parte del grupo, el mismo evento produce otra `executionKey`. El destinatario ya atendido deja de reconocerse como duplicado.

**Reproducción:** presentar Ana y Bruno; el primer correo al pastor se entrega, pero falla el insert del destinatario director-lf y queda la intención pendiente. Se resuelve Ana y se recupera la intención. Resultado: **2 dispatches de presentación y 2 llamadas aceptadas por el proveedor simulado para el mismo pastor**, con claves diferentes; el segundo vuelve a anunciar a Bruno, que ya figuraba en el primero. Métodos reales; fixture Prisma/proveedor/render sintéticos. No es otra presentación ni otro rol.

**Corrección requerida:** conservar la identidad de la intención y del envío por destinatario/rol/alcance aunque cambie el contenido elegible. Recuperar solo destinatarios no materializados/entregados; no deducir identidad a partir del subconjunto mutable de pendientes. Regresión con fallo a mitad de destinatarios y resolución parcial antes de recuperar.

### P6-2 residual — Alta / P1: el acuse ambiguo no respeta los límites de idempotencia del proveedor

**Ubicación:** `sacdia-backend/src/common/email/email.processor.ts:197-215`; `investiture-communications.service.ts:457-480`; `src/common/email/email.queue.ts:177-189`.

Cada reintento reconstruye asunto/cuerpo/destino, pero reutiliza `investiture-mail-{dispatchId}`. Si el proveedor aceptó y se perdió el acuse local, modificar la ventana o resolver parte del grupo cambia el payload del siguiente intento bajo la misma clave. Además, la recuperación de jobs agotados no tiene horizonte para resultados ambiguos.

Resend documenta **409 `invalid_idempotent_request`** para una misma clave con payload distinto y conserva las claves **24 horas**. Por tanto un Map perpetuo indexado solo por clave no demuestra el contrato real. Fuente primaria consultada el 2026-10-06: [Idempotency Keys — Resend](https://resend.com/docs/dashboard/emails/idempotency-keys).

**Dos reproducciones con processor/gate reales y proveedor simulado según ese contrato (NO llamadas a Resend):**

1. El proveedor acepta; falla `acknowledge`; se acorta la ventana y el recordatorio agrega el aviso de cierre. El reintento usa la misma clave y contenido distinto: el doble estricto devuelve `invalid_idempotent_request`. Hay **1 aceptación**, pero el dispatch no llega a `sent`.
2. El proveedor acepta; falla el acuse; se reintenta 25 horas después, con pendientes/año aún válidos y una simulación de retención de 24 horas. Hay **2 mensajes aceptados** y el seguimiento acaba en `sent`. Es evidencia de falta de protección local bajo el límite publicado, no un caso observado en Resend/producción.

**Corrección requerida:** modelar el intento potencialmente aceptado y reconciliar su acuse con identidad/contenido persistidos y horizonte explícito. Mantener la revalidación de autorización/alcance antes de cualquier nueva entrega, pero no cambiar silenciosamente el payload de un intento ambiguo ni renovar su clave para eludir el conflicto. Pasado el horizonte del proveedor, no reenviar automáticamente como si se supiera que nunca se aceptó: conservar un estado incierto recuperable/escalable. Cubrir acuse perdido con contenido cambiado y recuperación posterior a 24 horas usando un proveedor de prueba fiel al contrato; no hace falta correo real.

### Verificaciones repetidas y límites

| Comprobación | Resultado |
| --- | --- |
| Reglas, entrega, solicitud y correo | **4 suites, 84 pruebas aprobadas**, salida 0. |
| Redis exclusivo temporal, loopback | **7 aprobadas: 2 propias + 5 importadas**. Primero bloqueado por sandbox (`listen EPERM`); repetido con permiso, salida 0. Cola/worker reales, provider simulado, renderer sustituido. |
| PostgreSQL exclusivo temporal | **25 pruebas aprobadas**, salida 0. Base `sacdia_p6r1_review_test`, creada para esta revisión; no una base local preexistente. |
| Probe independiente adicional PostgreSQL | Colisión/rollback de intención reproducida; idempotencia de bandeja con acuse fallido comprobada (1 log/1 delivery). |
| Nuevo probe de aceptación e intercalaciones | **12 escenarios**, salida 0: 9 aceptaciones focales y 3 reproducciones residuales (duplicación al rematerializar y dos casos de proveedor). Usa fixture de datos sintético de la spec de entrega sin ejecutar sus tests; assertions propias y métodos runtime reales. |
| Tipos runtime `tsc --noEmit --incremental false -p tsconfig.build.json` | Salida 0. |
| ESLint focal sin `--fix`, `git diff --check` raíz/backend y hash de fuentes | Salida 0 / sin cambios de las fuentes verificadas. |

El schema PostgreSQL de las suites se materializa con `prisma migrate diff`; **no certifica aplicación del SQL de las migraciones**. Los procesos PostgreSQL creados para ambos pases se detuvieron al terminar (trap del runner, logs conservados). Redis usa el teardown de su suite. No se certifican Resend/FCM reales, render final (continúa la limitación local React previamente documentada), autenticación HTTP, UI, despliegue ni Neon.

Evidencia nueva, sin alterar probes históricos: `docs/reviews/investidura-autorizacion-review-evidence/p6r1-acceptance-probe.cjs`, `p6r1-acceptance.log`, `p6r1-postgres-probe.cjs`, `p6r1-postgres-run.sh`, logs `p6r1-postgres-*`, `p6r1-unit.log`, `p6r1-types.log`, `p6r1-lint.log`, `p6r1-redis.log`, `p6r1-redis-sandbox.log` y `p6r1-source-sha256.txt`.

**Siguiente paso:** corregir P6-1 residual A/B y P6-2 residual, sin reabrir los cierres comprobados. Repetir las regresiones de aceptación antes de aprobar fase 6. Sin cambios runtime, builds, commits, despliegues ni fase 7 en esta revisión.

## Decimosexta revisión — fase 6: comunicaciones (2026-10-05)

Revisión focal de `development` @ `113d8ba9b5f0befc7c5a913ebbc7d7c872d2174a`, con cambios sin commit. **Fase 6 NO APROBADA.** Se reproducen cuatro hallazgos de prioridad alta y uno de prioridad media. P5-1/P5-2/P5-3 conservan su cierre: los defectos siguientes pertenecen al nuevo seguimiento de comunicaciones, no a la reconciliación de logros. No se inició fase 7 ni se modificó código runtime.

### P6-1 — Alta / P1: presentación y resultado pueden perderse antes de crear el seguimiento

**Ubicación:** `sacdia-backend/src/investiture-requests/investiture-communications.service.ts:65-86,97-108`; llamadas posteriores al commit en `investiture-authorization-requests.service.ts:681-693,871-874`.

Los handlers cargan datos y crean los dispatches DESPUÉS de confirmar la operación. Si falla una lectura o la creación del seguimiento, capturan el error y solo lo registran. No se guarda una intención de comunicación en la transacción de negocio. `deliverPending` solo recorre filas existentes; no puede reconstruir lo que nunca se registró. Repetir una resolución ya confirmada no invoca `recordResults` para recuperarla.

**Reproducción:** inyectar un fallo transitorio en la lectura del request dentro de ambos handlers reales. Ambos retornan sin excepción; quedan **0 filas**, **0 envíos** y `deliverPending()` devuelve **0**. El probe modela la llamada postcommit; no ejecuta una transacción de negocio PostgreSQL. La posición posterior al commit se verificó en el servicio de solicitudes.

**Corrección requerida:** registrar intención durable del envío/grupo y del resultado en la misma transacción que confirma el negocio; materializar destinatarios/entregar posteriormente con recuperación autónoma. Una interrupción entre commit y handler, o fallo en mitad de los destinatarios, debe poder recuperarse sin duplicar ni perder los restantes.

### P6-2 — Alta / P1: el seguimiento confunde encolado con envío y deja `sending` irrecuperable

**Ubicación:** `sacdia-backend/src/investiture-requests/investiture-dispatch.ts:68-95`; `investiture-communications.service.ts:129-132,265-275`; `src/common/email/email.processor.ts:90-108,119-128`.

`sendInvestitureNotice` retorna cuando `queue.add` acepta el job. Inmediatamente el dispatch pasa a `sent`, antes de que el proveedor entregue. Si el worker falla, solo registra el fallo; no devuelve el dispatch a un estado recuperable. El reconciliador ignora `sent`. Además, una interrupción después del claim deja `sending`: ni `deliverOnce` ni `deliverPending` recuperan ese estado. El índice único evita filas duplicadas, no asegura entrega.

**Reproducción:** producer y servicio reales con cola simulada; aceptación inicial deja `sent`. Ejecutar el processor real cinco veces con proveedor que lanza conserva `sent`, un job capturado y **0 reconciliaciones**. Es una secuencia de llamadas al processor, NO una prueba del scheduler/reintentos de BullMQ real. Para el estado durable que quedaría tras una interrupción después del claim, `deliverOnce` devuelve `duplicate` y ejecuta **0 envíos**. No se mató un proceso real.

**Corrección requerida:** diferenciar aceptación en cola y entrega, enlazar resultado del worker con el dispatch, recuperar fallos agotados y claims abandonados mediante lease/ownership. Mantener identidad estable y protección ante acuses ambiguos; no basta reinsertar un job fallido con el mismo ID. Verificar con Redis aislado, reinicio y fallo del proveedor sin correo real.

### P6-3 — Alta / P1: el reintento no comprueba el alcance vigente y el worker envía datos obsoletos

**Ubicación:** `sacdia-backend/src/investiture-requests/investiture-communications.service.ts:189-240`; `src/common/email/email.processor.ts:119-128`.

`mailDraftFrom` vuelve a cargar el mundo, pero usa solo `fields`; ignora los pastores y cargos actuales. Conserva `recipient_user_id`, `role` y el correo del payload anterior. Por tanto puede reenviar nombres de pendientes a quien ya perdió la asignación. Después de encolar, el worker solo tiene asunto/texto/destino: no revisa año, pendientes ni alcance antes de entregar o reintentar, contra IA-48/IA-49. La demora no es solo hipotética: la cola existente tiene backoff y limitador.

**Reproducción:** recordatorio falla al encolar; se retira la asignación pastoral y se restaura la cola. `deliverPending()` envía **1 correo con Ana al expastor**, aun con lista actual de pastores vacía. Segundo caso: encolar, cerrar el año y dejar cero pendientes, luego ejecutar el processor; el proveedor simulado recibe **1 correo**. Se usan loader/servicio/processor reales y datos sintéticos, no correo real.

**Corrección requerida:** conservar IDs/identidad de ejecución en el trabajo y recomputar elegibilidad del destinatario, rol, territorio, año y pendientes al entregar, también al reintentar. Cancelar/saltar lo que dejó de corresponder y recortar lo parcialmente resuelto; no reenviar snapshots antiguos fuera de alcance. Cubrir revocación pastoral, traslado de Campo, año cerrado y resolución de todos los pendientes mientras el job espera.

### P6-4 — Alta / P1: el resultado in-app puede perderse o duplicarse aunque exista un solo dispatch

**Ubicación:** `sacdia-backend/src/investiture-requests/investiture-communications.service.ts:279-313`; `investiture-dispatch.ts:82-95`. Comportamiento existente consumido por esta integración: `src/notifications/notifications.service.ts:147-162,917-941`.

La integración usa un servicio de notificaciones best-effort como si su retorno confirmara persistencia durable. Su fallback captura el fallo de la transacción de bandeja y devuelve éxito. Además, no recibe una clave idempotente de este dispatch: si la bandeja se guarda pero falla el posterior cambio a `sent`, el reintento crea otra entrada. En modo encolado tampoco se pasa un job ID propio desde `sendResult`. No es un cambio nuevo dentro de NotificationsService: el defecto nuevo es depender de ese contrato sin adaptar las garantías requeridas para investidura.

**Reproducción con NotificationsService real, sin Redis/FCM:** fallo de la transacción de bandeja → **0 entradas**, dispatch **sent**, **0 reintentos**. Fallo de la escritura de acuse después de persistir → primer intento deja **1 entrada** y dispatch `failed`; `deliverPending` deja **2 entradas** y **una sola fila de dispatch**, ahora `sent`.

**Corrección requerida:** persistir la entrega in-app con identidad única vinculada al dispatch/resultado y un acuse comprobable; propagar fallos de persistencia para esta vía. Separar push best-effort de persistencia de bandeja. Cubrir fallo antes del insert, después del insert/antes del acuse y dos reintentos concurrentes, sin duplicar entrada ni ocultar pérdida.

### P6-5 — Media / P2: el reintento dice que la ventana está cerrada cuando rige el default abierto

**Ubicación:** `sacdia-backend/src/investiture-requests/investiture-communications.service.ts:234-239`.

El envío inicial resuelve `defaultInvestitureWindow` cuando no hay fila. El reintento, en cambio, interpreta `windowStart/windowEnd == null` como cierre. Un Campo con año enero–diciembre, sin fila y el 5 de octubre tiene la ventana por defecto abierta; el mismo recordatorio cambia a «La ventana de autorización está cerrada» después de un fallo de cola.

**Reproducción:** el primer intento no contiene el aviso de cierre; el reintento, sin cambiar calendario, sí. Se observa en el escenario de revocación de P6-3, pero el defecto de calendario es independiente de la revocación.

**Corrección requerida:** compartir la misma resolución de ventana efectiva y predicado entre primer envío y reintentos; mantener W1 cerrado sin intersección. Añadir regresiones de ausencia de fila con default abierto, sin intersección y ventana explícita.

### Evidencia y límites de esta revisión

| Comprobación | Resultado independiente |
| --- | --- |
| Reglas de comunicaciones + solicitud + servicio de correo | **3 suites, 77 pruebas aprobadas**, salida 0. |
| Probe adicional con métodos reales y dependencias simuladas | **7 escenarios reproducidos**, salida 0 (confirma defectos, NO aceptación de fase). |
| `tsc --noEmit --incremental false -p tsconfig.build.json` | Salida 0, sin emitir build. |
| ESLint sin `--fix` de comunicaciones, dispatch, cron, cola/servicio/processor de correo y template | Salida 0. |
| `git diff --check` backend | Salida 0. |
| PostgreSQL, Redis, HTTP/auth real, UI, correo real y migración | **No ejecutados en esta revisión**. Los 25 tests PostgreSQL del implementador no se presentan como repetidos. |

El primer intento de ejecutar el renderer real falló por dependencias instaladas incompatibles: **react 19.2.8 / react-dom 19.2.4**. No hay diff de `package.json`/`pnpm-lock.yaml`; no se atribuye este problema de entorno a fase 6. Para aislar los defectos de entrega, los probes del processor sustituyen únicamente `renderTemplate` por HTML/texto sintéticos, además de la cola/proveedor simulados. **No certifican renderizado del template.** Se conserva el error original para diagnóstico. No se instalaron paquetes ni cambiaron dependencias.

Evidencia nueva: `docs/reviews/investidura-autorizacion-review-evidence/p6-dispatch-probe.cjs`, `p6-dispatch-probe.log`, `p6-unit-tests.log`, `p6-runtime-types.log`, `p6-lint.log`, `p6-render-environment.log`, `p6-source-sha256.txt`. No se cambiaron probes históricos.

Repetición (desde `sacdia-backend`):

```sh
NODE_ENV=test DOTENV_CONFIG_PATH=/dev/null node \
  ../docs/reviews/investidura-autorizacion-review-evidence/p6-dispatch-probe.cjs
```

**Siguiente paso:** corregir P6-1 a P6-5 y aportar regresiones de la integración real, no solo helpers; repetir revisión antes de aprobar fase 6. Fase 7 no iniciada. Sin build, commit, despliegue ni aplicación de migraciones; pipeline anterior activo y pantallas pendientes.

## Decimoquinta revisión — cierre de P5-2 residual (2026-10-05)

Revisión de cambios sin commit sobre `development` @ `113d8ba9b5f0befc7c5a913ebbc7d7c872d2174a`. **P5-2 CERRADO. P5-1, P5-3 y la regresión del mock de ventana conservan su cierre.** El backend de fase 5 queda verificado en el alcance revisado y permite continuar el desarrollo de fase 6. No equivale a aprobar la fase 5 completa, las pantallas ni el despliegue. No se identificaron nuevos bloqueos en esta corrección focal.

### Corrección comprobada

`AchievementsService.enqueueEvaluation` inspecciona el trabajo obtenido con el ID estable. `recoverFailedEvaluation` (`sacdia-backend/src/achievements/achievements.service.ts:191-229`) solo actúa sobre `failed` y comprueba que el evento no esté procesado antes de `retry('failed', { resetAttemptsMade: true, resetAttemptsStarted: true })`. Si otro reconciliador lo movió de estado, reconoce esa situación; si sigue fallido, propaga el error. Conserva ID y fila de evento, sin volver a autorizar la investidura.

### Aceptación independiente con PostgreSQL y Redis reales

El probe nuevo ejecuta **ocho escenarios**, conservando intactos los reproductores históricos:

1. Cierre del año durante espera: rechazo; persona pendiente e inscripción sin investir.
2. Ventana acortada durante espera: mismo resultado.
3. Retiro del pastor durante espera: mismo resultado.
4. Cruce de medianoche al terminar la ventana: rechazo con reloj leído después del candado.
5. Cruce de medianoche al terminar el año: rechazo, sin intención/evento.
6. Fallo del primer insert y año cerrado: arranque y reconciliación concurrentes recuperan una sola fila; el POST sigue rechazando por año cerrado.
7. Autorización y dos reintentos con Queue/Worker reales: una fila, una evaluación, trabajo `completed`.
8. **Fallo agotado recuperado:** se inyectan tres fallos transitorios de lectura en el processor, respetando sus intentos/backoff. Queda `failed`. Con lectura restaurada y año cerrado, dos reconciliaciones concurrentes reactivan **el mismo ID**. Con el worker pausado se comprueba `waiting` y `attemptsMade=0`; otra reconciliación en espera no duplica. Al reanudar, termina `completed`, `attemptsMade=1`, `processed=true` y una fila. Total: tres intentos fallidos y uno exitoso. Otras dos reconciliaciones devuelven 0/0 y no vuelven a evaluar. El POST conserva `INVESTITURE_REQUEST_YEAR_CLOSED`.

Los dos reconciliadores pueden contar entrega de la misma intención (1/1), pero el estado real y los contadores verifican **una sola reactivación efectiva y una sola evaluación posterior**, no dos trabajos ni dos eventos.

### Verificación repetida

| Comprobación | Resultado |
| --- | --- |
| 23 suites seleccionadas de regresión, incluida `certificate-import-files.service.spec.ts` | **417 pruebas aprobadas**, salida 0. |
| Suite PostgreSQL de solicitudes | **24 pruebas aprobadas**, salida 0. |
| Probe independiente PostgreSQL + Redis | **8 escenarios aprobados**, salida 0. |
| `tsc --noEmit --incremental false -p tsconfig.build.json` | Salida 0. |
| ESLint de los archivos focales, sin `--fix` | Salida 0. |
| `git diff --check` raíz/backend | Salida 0. |

La suite entregada `achievements-failed-job.spec.ts` se inspeccionó pero no se ejecutó por separado; el escenario se verificó con el probe independiente, usando además PostgreSQL real. No se suma esa prueba al conteo anterior.

**Cambio ajeno:** se inspeccionó el enum de `upload_status` y la comprobación `current != null` de `certificate-import-files.service.ts`; typecheck y su suite pasan. El diff completo de ese archivo contiene también trabajo concurrente OCR/CAS ajeno. Esta revisión no atribuye todos esos cambios a investidura ni aprueba por ello el flujo OCR completo; se preservaron sin modificación.

**Aislamiento y límites:** PostgreSQL 18.3 y Redis 8.6.2 exclusivos, recién creados en puertos efímeros de loopback; BullMQ 5.81.0, Queue/Worker y processor de la aplicación reales. URLs explícitas, `DOTENV_CONFIG_PATH=/dev/null`, sin DB/colas existentes, `.env` reales, Neon ni producción. PG detenido (status 3), Redis con cierre ordenado registrado; logs conservados y directorio temporal eliminado. El helper reconstruye con `prisma migrate diff` e índices parciales, **no aplica el SQL de las migraciones**. Sin builds, generación Prisma, commits ni cambios runtime por el revisor.

Auth por snapshots, elegibilidad simulada, reloj y fallos DB controlados. **Sin logro coincidente sembrado:** se verifica entrega/evaluación y `processed=true`, no concesión ni notificación de un logro real. No certifica autenticación, HTTP integrado con DB, UI ni despliegue. No se arrancó AppModule completo ni se simuló la caída del proceso del backend.

**Continuidad:** puede continuar el desarrollo de fase 6 y la integración de consumidores contra este backend revisado. Mantener pendientes las pantallas, la fase 2 parcial y la validación integral. No retirar el pipeline anterior sin inventario/transición ni desplegar por este cierre. P4-1 a P4-4 conservan su cierre previo.

Evidencia: `docs/reviews/investidura-autorizacion-review-evidence/p5r3-verification.json`, `p5r3-queue-acceptance-probe.cjs`, `p5r3-postgres-run.sh` y logs `p5r3-*`. Los artefactos previos permanecen históricos e intactos.

---

## Decimocuarta revisión — reloj, reconciliación y cola real (2026-10-05)

**Sección histórica; P5-2 se cerró en la decimoquinta revisión.** Revisión de cambios sin commit sobre `development` @ `113d8ba9b5f0befc7c5a913ebbc7d7c872d2174a`. **P5-1 y P5-3 CERRADOS; regresión HTTP de ventana corregida. P5-2 conserva un residuo abierto. Fase 5 backend NO APROBADA.** No se modificó runtime ni el informe de implementación ni los probes históricos.

### P5-2 residual — Alta / P1: el reconciliador no reactiva un trabajo que agotó sus intentos

**Ubicación:** `sacdia-backend/src/achievements/achievements.service.ts:24-31,151-164`; `sacdia-backend/src/investiture-requests/investiture-authorization-requests.service.ts:699-726`.

El reconciliador encuentra correctamente intenciones sin procesar, pero la entrega solo vuelve a llamar a `queue.add` con el mismo identificador estable. Los trabajos fallidos se conservan (`removeOnFail: { count: 50 }`). En BullMQ, agregar de nuevo ese ID **no reactiva un trabajo existente en estado `failed`**. El método devuelve `queued: true` y el reconciliador cuenta una entrega, aunque no haya un nuevo intento de evaluación.

**Reproducción independiente con PostgreSQL y Redis reales:**

1. Confirmar una investidura crea una fila de evento y encola un trabajo con ID válido.
2. Inyectar un fallo transitorio en la lectura inicial de `achievement_event_log` del `AchievementsProcessor` durante sus **tres intentos**, respetando el backoff original. El trabajo queda `failed`, el evento `processed=false`.
3. Agotar la inyección deja la lectura disponible de nuevo; se cierra el año y se ejecutan **dos reconciliaciones concurrentes**.
4. Ambas reportan **1 entrega**, pero el trabajo sigue **`failed`**, el contador continúa en **3 intentos** y `processed` sigue **false**. No se provocó una caída real de DB: la falla se inyectó en el método de lectura, mientras la cola/worker y persistencia fueron reales.

El sistema ahora recupera un insert fallido o un primer encolado fallido, pero todavía puede dejar abandonada la evaluación si un problema temporal dura más que los reintentos automáticos. No corresponde retirar la deduplicación ni cambiar el ID aleatoriamente como solución.

**Corrección requerida:** distinguir los estados del trabajo existente. Recuperar de forma segura y coordinada los trabajos fallidos cuya intención/evento sigue sin procesar, con política de reintentos/backoff y observabilidad; no duplicar uno activo/en espera ni volver a conceder un evento procesado. No reportar entrega efectiva solo porque `add` retornó un objeto para un ID existente. Conservar una sola fila de evento e idempotencia de efectos.

**Aceptación:** con Redis/BullMQ reales, agotar los tres intentos por fallo transitorio, restaurar el servicio y reconciliar concurrentemente con el año cerrado. Debe ocurrir una evaluación posterior exitosa y `processed=true`, sin duplicar evento ni efectos. Mantener los casos de trabajo activo/completado, primer insert/encolado fallido, cron/arranque simultáneos y ausencia de eventos en rollback/rechazo/retiro/cierre. Cubrir también recuperación tras reinicio sin depender de volver a autorizar.

### Cierres y avances verificados

- **P5-1 CERRADO:** el reloj inyectable se lee después de los candados (`resolve:450-453`). Probe independiente observa la espera real y avanza el reloj a través de medianoche del fin de ventana y del fin de año: ambos rechazan, persona `PENDING`, enrollment `IN_PROGRESS`, intención nula y cero emisiones. No pasa `now` explícito. Los tres intercalados originales año/ventana/pastor siguen rechazando.
- **P5-3 CERRADO:** la clave de BD permanece estable; el ID de cola es `achievement-<sha256>` sin `:`. El validador real lo acepta y rechaza la clave original. En **Queue + Worker BullMQ reales sobre Redis exclusivo**, una autorización y dos reintentos concurrentes producen una fila, una evaluación y un trabajo `completed`; `processed=true`.
- **Recuperación tras cierre corregida:** fallo del primer insert, año cerrado, POST continúa rechazado; una nueva instancia llama al arranque del reconciliador y otra a su ejecución periódica concurrentemente. Se recupera una sola fila sin volver a autorizar. La anotación cron de cinco minutos y el registro del provider/módulo/scheduler se comprobaron en código. No se esperaron cinco minutos ni se arrancó AppModule completo.
- **Mock de ventana corregido:** el caso HTTP vuelve a pasar con su contrato transaccional adaptado; la regresión completa seleccionada está en verde.

### Verificación repetida

| Comprobación | Resultado |
| --- | --- |
| 22 suites de regresión | **394 pruebas aprobadas**, salida 0. |
| Suite PostgreSQL entregada | **24 pruebas aprobadas**, salida 0. |
| Probe independiente nuevo | **7 aceptaciones y 1 defecto reproducido**, salida 0 de comprobación de observaciones. |
| `tsc --noEmit --incremental false -p tsconfig.build.json` | Salida 0. |
| ESLint de archivos revisados, sin `--fix` | Salida 0. |

**Aislamiento y límites:** PostgreSQL 18.3 y Redis 8.6.2 recién creados y exclusivos en puertos efímeros de `127.0.0.1`, sin conectar a DB/colas existentes, `.env` reales, Neon ni producción. URLs explícitas y `DOTENV_CONFIG_PATH=/dev/null`. PostgreSQL `read committed`; BullMQ instalado 5.81.0. Ambos servidores quedaron detenidos (PG status 3; Redis salida ordenada registrada) y se eliminó el directorio temporal después de copiar los logs. El helper usa `prisma migrate diff` e índices parciales: no aplica el SQL de migraciones como despliegue. No hubo builds, generación Prisma, commits ni cambios runtime.

Los probes usan snapshots de autorización y elegibilidad simulada. El processor de la aplicación es real, pero **no se sembró un logro coincidente**: la evaluación exitosa demuestra entrega al processor y `processed=true`, no concesión/notificación de un logro real. No se certifican autenticación, HTTP con DB, UI ni migraciones en producción.

**Continuidad:** concentrar la siguiente corrección en el residuo P5-2 de trabajos fallidos y regresar a revisión. No reabrir P5-1/P5-3 ni la regresión del mock sin evidencia nueva. Fase 5 completa y despliegue siguen bloqueados; no retirar la vía anterior ni dar por completadas las pantallas o la fase 2.

Evidencia: `docs/reviews/investidura-autorizacion-review-evidence/p5r2-verification.json`, `p5r2-queue-acceptance-probe.cjs`, `p5r2-postgres-run.sh` y logs `p5r2-*`. Un exit 0 del probe verifica tanto las aceptaciones como el defecto residual, no la aprobación global.

---

## Decimotercera revisión — correcciones P5-1/P5-2 (2026-10-05)

**Sección histórica; ver decimocuarta revisión para el estado vigente. Fase 5 backend NO APROBADA.** Revisión de cambios sin commit sobre `development` @ `113d8ba9b5f0befc7c5a913ebbc7d7c872d2174a`. Se verifican avances reales, pero **P5-1 y P5-2 no se cierran**; se añade **P5-3**. No se modificó runtime, el informe de implementación ni los probes históricos.

### P5-3 — Alta / P1: el identificador de la intención no es un jobId válido de BullMQ

**Ubicación:** `sacdia-backend/src/achievements/achievements.service.ts:80-85,141-145`; clave producida en `sacdia-backend/src/investiture-requests/investiture-authorization-requests.service.ts:35-37,688`.

Se pasa `investiture-authorization:<UUID>` directamente como `jobId`. La versión instalada de BullMQ **5.81.0** rechaza ese formato: **`Custom Id cannot contain :`**. Por tanto, con cola configurada se persiste el evento, pero su evaluación no se encola por esta vía. La autorización inicial oculta el error y devuelve éxito; el reintento vuelve a fallar con la misma clave.

**Reproducción:** `AchievementsService` y PostgreSQL reales, cola sustituida únicamente para ejecutar el validador real instalado `Job.prototype.validateOptions` con las opciones que recibe. Dos intentos producen el error; queda una fila de evento con `processed=false`. No se conectó a Redis ni se afirma haber ejecutado un worker. Las pruebas entregadas con cola ausente o `queue.add` simulado no detectan este fallo determinista de validación.

**Corrección/aceptación:** separar clave de idempotencia persistida e identificador de cola, usando una representación estable admitida por BullMQ. No intentar sortear la restricción añadiendo separadores. Probar las opciones contra la librería real y verificar en cola aislada que el evento llega a evaluación una sola vez pese a reintentos, sin depender de un mock que acepte cualquier jobId.

### P5-1 residual — Alta / P1: el reloj sigue siendo el de entrada a la petición

**Ubicación:** `sacdia-backend/src/investiture-requests/investiture-authorization-requests.service.ts:354-359,434-444`.

La relectura transaccional corrige los cambios de datos originales, pero ambas validaciones reutilizan `now`, capturado al entrar a `resolve`. Si la petición espera un candado y cruza el último instante permitido, autoriza con el día anterior.

**Reproducción independiente:** sin pasar el argumento opcional `now`, el reloj JS marca **20 de diciembre, 23:59:59, America/Mexico_City**. `resolve` espera un candado real de sección/año, observado en `pg_locks`; se avanza el reloj JS a **21 de diciembre, 00:00:01** y se libera. Confirma `INVESTIDO`. Un intento nuevo devuelve `INVESTITURE_REQUEST_WINDOW_CLOSED`. No se cambió el reloj del sistema operativo. El reloj de prueba fue controlado; la espera y la escritura fueron PostgreSQL reales.

**Corrección/aceptación:** obtener el instante de decisión después de las esperas, preferentemente mediante el reloj inyectable existente, y comprobar calendario/año con ese instante dentro de la sección protegida. Cubrir cruce de medianoche al final de ventana y año; deben quedar `PENDING`, sin investidura ni evento. Conservar los tres intercalados corregidos y el orden consistente de candados.

### P5-2 residual — Alta / P1: recuperar una decisión confirmada depende de volver a poder autorizar

**Ubicación:** `sacdia-backend/src/investiture-requests/investiture-authorization-requests.service.ts:396-403,434-444,464-478,664-670`.

La intención se conserva y un reintento recupera el evento mientras el calendario está abierto. Sin embargo, la única llamada de recuperación está en `resolve`, después de comprobar los permisos y el calendario para una **nueva autorización**. No se encontró un consumidor independiente de `achievement_intent_key` en `src/`. La respuesta inicial sigue siendo éxito si falla el insert: el cliente no tiene por qué reintentar.

**Reproducción:** se inyecta un fallo transitorio únicamente en el primer `achievement_event_log.create`; la resolución confirma `INVESTED` con intención y cero eventos. Se desactiva el año. Un nuevo servicio intenta recuperar y recibe `INVESTITURE_REQUEST_YEAR_CLOSED` **antes de entregar el evento**; siguen cero filas para esa intención. Reabrir el año no debe ser requisito para entregar un efecto ya confirmado. La ausencia de recuperación autónoma se comprobó por inspección/búsqueda de consumidores; no por esperar indefinidamente un cron.

**Corrección/aceptación:** entrega/reconciliación durable desacoplada de la elegibilidad actual para autorizar, que procese intenciones confirmadas después de reinicio o fallo aunque la ventana/año hayan cerrado o el autorizador haya perdido su asignación. Mantener autorización segura para nuevas decisiones y no reabrirlas. Cubrir fallo de insert, fallo de cola, recuperación sin repetir el POST, año cerrado y reintentos concurrentes; una sola fila/evento y efectos idempotentes. No basta guardar una clave si nadie la procesa posteriormente.

### Correcciones comprobadas

- Los tres intercalados originales de año cerrado, ventana acortada y pastor retirado ahora rechazan después de la espera: persona `PENDING`, enrollment `IN_PROGRESS`, sin intención. Los escritores de ventana, baja pastoral y cierre administrativo/anual incorporan los candados compartidos; la suite PostgreSQL verifica también que un escritor que respeta el candado no se intercala antes de la escritura.
- Un fallo del primer insert seguido por **dos reintentos concurrentes desde una nueva instancia de servicio** produce una sola fila `achievement_event_log`; ambos reintentos terminan con `INVESTITURE_REQUEST_ALREADY_RESOLVED`. Se usó `AchievementsService` real con Prisma real y fallo inyectado en su insert. Nueva instancia no equivale a haber matado/reiniciado el proceso.
- Las 21 pruebas PostgreSQL entregadas pasan, incluidos los casos negativos de rechazo/retiro/cierre. Estos avances no eliminan los residuos anteriores ni validan un worker real.

### Regresión y verificación

| Comprobación | Resultado |
| --- | --- |
| 21 suites de regresión (incluye logros, catálogo de años y cierre anual) | **20 suites pasan; 1 falla. 388 pruebas pasan; 1 falla; salida 1.** |
| Pruebas PostgreSQL entregadas | **21 aprobadas**, salida 0. |
| Probe independiente nuevo | **4 aceptaciones y 3 defectos reproducidos**, salida 0 de comprobación de observaciones. |
| `tsc --noEmit --incremental false -p tsconfig.build.json` | Salida 0. |
| ESLint de archivos revisados | Salida 0, sin `--fix`. |

**Prueba que requiere adaptación:** `sacdia-backend/src/classes/field-investiture-window.controller.spec.ts:61-80,141-146`, caso `opens only the range an authorized editor saves`. Espera 200, obtiene 500: `this.prisma.$transaction is not a function` en el nuevo servicio de ventana. Su doble Prisma no fue actualizado al contrato transaccional. Esto demuestra una regresión de la prueba, **no un 500 probado en producción**; adaptar el doble sin debilitar el caso ni desactivar la prueba. No se puede declarar la regresión completa en verde.

**Límites:** PostgreSQL 18.3 recién creado y exclusivo en loopback, DB `sacdia_p5fix_review_test`; se verificó identidad/aislamiento `read committed`. URLs explícitas y `DOTENV_CONFIG_PATH=/dev/null`, sin DB compartida/existente, `.env` real, Neon ni producción. Helper con `prisma migrate diff` e índices parciales: no se aplicaron migraciones mediante su SQL. Servidor detenido (status 3), logs preservados y directorio temporal eliminado. Auth por snapshots y elegibilidad simulada, sin autenticación/HTTP+DB/UI reales. Sin builds, generación Prisma, cambios runtime, commits ni despliegue.

**Continuidad:** corregir P5-1 residual, P5-2 residual y P5-3, restaurar la regresión HTTP y volver a revisión antes de aprobar fase 5. No comenzar fase 6 como si esta estuviera aprobada. Mantener bloqueado despliegue/cambio de vía; fases y pantallas pendientes conservan su estado.

Evidencia: `docs/reviews/investidura-autorizacion-review-evidence/p5fix-verification.json`, `p5fix-acceptance-residual-probe.cjs`, `p5fix-postgres-run.sh` y logs `p5fix-*`. Los artefactos `phase5-*` permanecen históricos e intactos.

---

## Duodécima revisión — resoluciones de fase 5 (2026-10-02)

**Sección histórica; ver decimotercera revisión para el estado vigente. Fase 5 backend NO APROBADA. P5-1 y P5-2 ABIERTOS en esta revisión.** Se revisó `development` @ `113d8ba9b5f0befc7c5a913ebbc7d7c872d2174a`, árbol backend limpio al verificar. El código ya está en un commit externo a esta revisión; no se debe describir esta entrega como cambios sin commit. No se modificó runtime.

### P5-1 — Alta / P1: se confirma usando permisos y calendario anteriores al candado

**Ubicación:** `sacdia-backend/src/investiture-requests/investiture-authorization-requests.service.ts:379-404`, contexto en `:961-1043`, autorización pastoral en `:1298-1321`.

`resolve` obtiene el año, ventana y asignación pastoral y los valida **antes** de entrar a la transacción y esperar los candados. Después relee personas e inscripciones, pero conserva aquel contexto. No vuelve a validar los datos que permiten autorizar.

**Reproducción independiente en PostgreSQL real:** una tercera conexión retiene el candado de sección/año; se inicia una autorización válida y se observa su espera no concedida en `pg_locks`. Mientras espera, otra conexión confirma uno de estos cambios. Solo entonces se libera el candado:

| Cambio confirmado antes de reanudar | Resultado incorrecto | Un intento nuevo sí lo detecta |
| --- | --- | --- |
| Año `active=false` | Confirma `INVESTIDO` | `INVESTITURE_REQUEST_YEAR_CLOSED` |
| Ventana pasa a terminar el 14 de octubre; día actual 15 | Confirma `INVESTIDO` | `INVESTITURE_REQUEST_WINDOW_CLOSED` |
| Asignación del pastor pasa a `active=false` | El pastor confirma `INVESTIDO` | `INVESTITURE_REQUEST_FORBIDDEN` |

No es la carrera ya cubierta contra `closePendingByYearEnd(personId)`: aquí el pendiente no se ha cerrado, pero la autorización perdió una condición necesaria. Es particularmente importante cuando el cierre anual todavía no recorrió todas las personas.

**Corrección requerida:** validar contexto/autorización efectivos dentro de la transacción, después de las esperas relevantes, y coordinar sus lecturas con los escritores de configuración/revocación/cierre mediante un protocolo de bloqueo consistente (también cuando no existe fila de ventana). Una simple lectura anterior a otro candado no cierra la carrera. Evaluar el instante operativo al decidir, no únicamente al entrar a la petición. Mantener orden de candados y evitar introducir deadlocks.

**Aceptación:** repetir los tres intercalados con espera observada en PostgreSQL y exigir rechazo, persona `PENDING`, enrollment sin investir y cero eventos; conservar los casos de autorización válida y las carreras autorización/rechazo/retiro/cierre ya entregadas. Cubrir además cruce del último instante permitido y demostrar que un cambio concurrente no se intercala entre la validación protegida y la escritura.

### P5-2 — Alta / P1: el evento de logro se pierde si falla su persistencia después del commit

**Ubicación:** `sacdia-backend/src/investiture-requests/investiture-authorization-requests.service.ts:610-629`; persistencia del evento en `sacdia-backend/src/achievements/achievements.service.ts:63-75`.

La resolución confirma primero la investidura. Después llama a `emitEvent`; si este falla, solo registra un warning y devuelve éxito. `AchievementsService` persiste `achievement_event_log` antes de encolar: sus reintentos de cola no pueden recuperar un evento que nunca se insertó. Reintentar la resolución tampoco lo recupera: la persona ya no está pendiente y devuelve `INVESTITURE_REQUEST_ALREADY_RESOLVED`.

**Reproducción:** servicio de resoluciones y PostgreSQL reales; `AchievementsService` real, con fallo transitorio inyectado únicamente en su primer insert de evento. La resolución devuelve éxito y el enrollment queda `INVESTIDO`; se agregan **0 eventos**. El reintento responde 409 y el contador de intentos de inserción sigue en **1**, aunque el insert siguiente ya estaría disponible. No se simuló una caída real de infraestructura. El escenario también identifica una brecha entre commit y emisión ante caída del proceso, pero ese cierre de proceso no se probó.

**Corrección requerida:** registrar atómicamente con la decisión una intención durable de emisión, con identidad única de autorización y entrega recuperable después del commit; puede reutilizarse infraestructura existente si satisface ese contrato. Garantizar deduplicación de evento y efectos del consumidor durante reintentos. No ejecutar la concesión del logro antes del commit ni simplemente lanzar error después de haber confirmado la investidura.

**Aceptación:** fallo antes de persistir, fallo/reinicio después del commit y reintento concurrente deben terminar con una sola evaluación/evento efectivo recuperado. Rollback, rechazo, retiro y cierre anual no generan `class.completed`. Conservar el flujo de logros existente, sin inventar logros nuevos.

### Verificación repetida y límites

| Comprobación | Resultado |
| --- | --- |
| 17 suites de regresión | **302 pruebas aprobadas**, salida 0. |
| Suite PostgreSQL entregada | **17 pruebas aprobadas**, salida 0. |
| Probe independiente | **4 escenarios reproducen los defectos**, salida 0 del reproductor; NO es aceptación. |
| `tsc --noEmit --incremental false -p tsconfig.build.json` | Salida 0, sin emisión. |
| ESLint módulo de solicitudes y spec PostgreSQL | Salida 0. |

El primer intento de tests HTTP falló por `listen EPERM` del sandbox; la repetición con permiso para puertos locales pasó. Las tres pruebas del controlador cubren rutas previas de fase 4: **no prueban el POST de resoluciones**, su DTO ni autenticación real. Los snapshots de autorización y la elegibilidad son seams simulados en los tests PostgreSQL/probe. Estas pruebas no certifican integración HTTP con DB, AppModule ni panel.

PostgreSQL 18.3 exclusivo, recién creado, en puerto efímero de `127.0.0.1`, base `sacdia_phase5_review_test`; identidad y `read committed` conservados. URLs fijadas explícitamente y `DOTENV_CONFIG_PATH=/dev/null`. No se usó una base existente, Neon ni producción. El helper reconstruye esquema con `prisma migrate diff` y agrega índices parciales: **no aplica la migración de investiduras**. Se detuvo el servidor (status 3), se conservaron logs y se eliminó su directorio temporal. No hubo builds, cambios runtime, generación Prisma, commits ni despliegues.

**Continuidad:** corregir P5-1/P5-2 y regresar a revisión antes de aprobar el backend de fase 5. P4-1/P4-2/P4-3/P4-4 mantienen el cierre previo en su alcance; no se certifican pantallas. Fase 2 sigue parcial. El cambio de vía y despliegue siguen bloqueados; no retirar el pipeline anterior sin inventario y transición.

Evidencia nueva: `docs/reviews/investidura-autorizacion-review-evidence/phase5-verification.json`, `phase5-race-event-probe.cjs`, `phase5-postgres-run.sh` y logs `phase5-*`. Los probes históricos permanecen intactos. Un exit 0 del probe nuevo significa que reproduce los fallos descritos, no que el backend cumple el contrato.

---

## Undécima revisión — cierre de P4-4 residual (2026-10-02)

Esta sección es **histórica; ver duodécima revisión para el estado vigente**. Sobre backend `development` @ `9d8fe1d3d1fd0e56256043ee8208d26c9bfcc39b`, sin commit. **P4-4 CERRADO; P4-1, P4-2 y P4-3 permanecen cerrados.** El backend de fase 4 queda verificado en el alcance revisado y permite continuar el desarrollo de fase 5. No equivale a aprobar la fase 4 completa: falta su pantalla e integración, la fase 2 continúa parcial y el despliegue sigue bloqueado.

### Corrección comprobada

`writePeople` consulta ahora la cabecera activa **tanto para presentar como para agregar**, después de tomar el candado de sección/año y dentro de la misma transacción (`sacdia-backend/src/investiture-requests/investiture-authorization-requests.service.ts:330-366`). Si el destino explícito es distinto de la cabecera activa, lanza `AppConflictException(INVESTITURE_REQUEST_STALE)` antes de insertar personas. Sin otra activa, permite reutilizar la cabecera vacía. Conserva el orden sección/año → usuarios ordenados → enrollments ordenados.

Se verificaron el error tipado, las traducciones y el contrato documentado de 409 y recarga del listado en las referencias API e integración. No se trasladan personas ni se borra historial para corregir un ID obsoleto. No se identificaron nuevos bloqueos en este cambio focal. Los hashes comparados con la décima revisión muestran que, de los fuentes registrados entonces, cambiaron solo el servicio de solicitudes, su spec y el spec PostgreSQL; los escritores de progreso revisados en P4-3 permanecen iguales.

### Aceptación independiente PostgreSQL

Además de repetir las nueve pruebas entregadas, `p44-acceptance-probe.cjs` comprueba con servicio y base reales:

1. **Ana en A → quitar Ana → Bruno en B → agregar Ana a A:** rechaza con estado de excepción 409 y `INVESTITURE_REQUEST_STALE`. Bruno queda pendiente y visible en B; la fila histórica de Ana continúa `REMOVED`. Una sola cabecera activa.
2. **Sin cabecera activa:** después de quitar a Bruno, agregar a Ana reutiliza A y conserva el historial.
3. **Carrera, presentar primero:** una tercera conexión retiene el candado de sección/año. Se observa un waiter, se inicia agregar, se observan dos waiters en `pg_locks` y se libera. Presentar confirma B; agregar a A recibe `STALE`. Un pendiente y uno visible.
4. **Carrera, agregar primero:** el mismo procedimiento invierte el orden. Agregar reutiliza A y presentar añade a la misma cabecera. Dos pendientes, ambos visibles, una sola cabecera activa.

La prueba independiente fuerza ambos órdenes; no depende de que una única carrera casual cubra las dos ramas. El 409 se comprobó en la excepción del servicio, no mediante HTTP con autenticación real.

### Verificación repetida

| Comprobación | Resultado |
| --- | --- |
| 17 suites de regresión | **291 pruebas aprobadas, salida 0**. |
| Suite PostgreSQL de solicitudes | **9 pruebas aprobadas, salida 0**. |
| Probe independiente de aceptación | **4 escenarios aprobados, salida 0**, incluidos ambos órdenes concurrentes. |
| `tsc --noEmit --incremental false -p tsconfig.build.json` | Salida 0, sin emisión. |
| ESLint módulo de solicitudes y spec PostgreSQL | Salida 0. |
| `git diff --check` raíz/backend | Salida 0. |

**Aislamiento y límites:** PostgreSQL 18.3 exclusivo, recién creado en puerto efímero de `127.0.0.1`, base `sacdia_p44_review_test`, identidad y `read committed` comprobados. Las tres URL de DB se fijaron explícitamente y `DOTENV_CONFIG_PATH=/dev/null` evitó cargar `.env`; no se reutilizó una base existente ni se contactó Neon. El servidor quedó detenido y su directorio temporal se eliminó tras conservar logs. El helper usa `prisma migrate diff` e índices parciales: **no aplica la migración nueva**. Los tests/probe usan elegibilidad simulada y snapshots de autorización; no certifican HTTP con base real, autenticación, UI ni R2. No se ejecutaron builds, generación Prisma, despliegues ni commits. No se modificó runtime. Los probes históricos `phase4-*` y `p4fix-*` quedaron intactos y no se usaron como pruebas de aceptación.

**Continuidad:** puede continuar el desarrollo de fase 5 con el contrato backend revisado. Esto no cierra la pantalla pendiente de fase 4 ni la integración de fase 2, no aprueba el plan completo y no permite desplegar o retirar el pipeline anterior sin su inventario/transición. Fase 3 conserva el cierre de la octava revisión.

Evidencia: `docs/reviews/investidura-autorizacion-review-evidence/p44-verification.json`, `p44-acceptance-probe.cjs`, `p44-postgres-run.sh` y logs `p44-*`.

---

## Décima revisión — correcciones P4-1 a P4-4 (2026-10-02)

Esta sección es **histórica; P4-4 residual se cerró en la undécima revisión**. Backend `development` @ `9d8fe1d3d1fd0e56256043ee8208d26c9bfcc39b`, sin commit. **P4-1, P4-2 y P4-3 cerrados en el alcance de las correcciones revisadas; P4-4 permanece abierto por una vía residual. Fase 4 NO APROBADA.** No se modificó runtime ni los probes históricos de la novena revisión.

### P4-4 residual — Alta / P1: agregar a una cabecera antigua vuelve a duplicar grupos activos

**Ubicación:** `sacdia-backend/src/investiture-requests/investiture-authorization-requests.service.ts:340-364`; entrada `addPeople` en `:111-139`.

El candado sección/año corrige la carrera original entre dos presentaciones, pero no alcanza para garantizar una sola cabecera activa. `writePeople` solo busca la cabecera con pendientes cuando `requestId` es nulo. Si `addPeople` proporciona una cabecera anterior, la usa directamente sin verificar si otra ya concentra los pendientes de la sección/año.

**Reproducción independiente en PostgreSQL real, sin concurrencia:**

1. Presentar a Ana crea la solicitud A.
2. Quitar a Ana deja A sin pendientes; GET devuelve `null`.
3. Presentar a Bruno crea B en la misma sección y año.
4. Agregar nuevamente a Ana mediante `addPeople(A, Ana)` confirma con éxito.

Resultado: **2 grupos activos / 2 personas pendientes**, pero GET muestra **solo 1 pendiente**. Son personas distintas, inscripciones válidas y un mismo actor autorizado en su sección; no depende de saltar permisos ni de superar el límite por persona. Puede ocurrir con una pantalla que conserva el ID anterior. Los índices por persona/clase no impiden esta fragmentación.

**Corrección requerida:** bajo el candado sección/año, validar también el destino explícito de `addPeople`. Si existe otra cabecera activa, no reactivar la anterior. Recomendación: rechazar la petición obsoleta con conflicto documentado y pedir al cliente recargar, preservando historial y sin mover personas silenciosamente. Regresión obligatoria: la secuencia anterior no deja dos grupos y ningún pendiente desaparece del GET; cubrir además `addPeople` contra `present` concurrentes. Mantener las pruebas que ya verifican dos altas distintas y dos altas de la misma persona.

### Correcciones verificadas

- **P4-1:** se elimina la igualdad obligatoria entre año de origen y año de solicitud; se cuenta desde el inicio del enrollment hasta el año de membresía/solicitud. Las pruebas PostgreSQL admiten el segundo año, conservan el enrollment y rechazan primer año o duración superior a la máxima. Unidad cubre también `EXPIRED`. El estado no se reescribe por este rechazo. Este cierre es del defecto de duración; no certifica el flujo anual completo ni la elegibilidad integrada sin mocks.
- **P4-2:** la clase cruzada se presenta desde la sección del tipo de la clase y exige pertenencia vigente de otro tipo en el mismo club, `cross_type_enrollment` e investidura GM previa. La prueba PostgreSQL usa membresía solo GM, admite CQ del mismo club y rechaza sección GM u otro club. La independencia de otra clase sigue cubierta en unidad. No se amplían límites de inscripción.
- **P4-3:** presentar/agregar y los escritores de puntaje, archivo, envío, baja, aprobación y rechazo usan el mismo advisory lock por enrollment dentro de la transacción. Los escritores consultan pendientes después de tomarlo. La espera observada en `pg_locks` permite confirmar primero la solicitud y la escritura de puntaje termina rechazada sin guardar. Unidad verifica las rutas antes omitidas, otro enrollment independiente y ausencia de llamadas a storage si ya hay pendiente. La baja lógica se confirma bajo el bloqueo y la eliminación física va después. No se probó R2 real, fallos distribuidos ni concurrencia de cada ruta de archivos/revisión; no se afirma atomicidad entre PostgreSQL y storage.
- **P4-4 original:** el orden sección/año → usuarios ordenados → enrollments ordenados evita dos cabeceras en las dos altas simultáneas entregadas. La prueba PostgreSQL pasa. **No se cierra el hallazgo completo**, porque `addPeople` a una cabecera vacía mantiene la vía descrita arriba.

### Evidencia repetida

| Comprobación | Resultado |
| --- | --- |
| 17 suites de regresión (incluida revisión de evidencias) | **288 pruebas aprobadas, salida 0**. |
| `investiture-authorization-requests-postgres.e2e-spec.ts` | **7 pruebas aprobadas, salida 0**. |
| `p4fix-request-reuse-probe.cjs` | Salida 0: reproduce P4-4 residual en PostgreSQL real; **no es aceptación**. |
| `tsc --noEmit --incremental false -p tsconfig.build.json` | Salida 0, sin emisión. |
| ESLint módulo nuevo, spec PostgreSQL y spec de revisión de evidencias | Salida 0. No se reformatearon clases ni sus avisos previos. |
| `git diff --check` raíz/backend | Salida 0. |

**Aislamiento:** clúster PostgreSQL 18.3 nuevo y exclusivo, puerto efímero de `127.0.0.1`, base `sacdia_p4fix_review_test`, aislamiento `read committed`. Se fijaron las tres URL de base y `DOTENV_CONFIG_PATH=/dev/null`; no se leyó `.env.test.local` ni `.env` real. Al finalizar se verificó que el servidor estaba detenido, se conservaron logs y se eliminaron solo sus datos temporales. La primera solicitud de permiso no se ejecutó por indisponibilidad del revisor automático; después de «continua» se reintentó por la misma vía de autorización y se ejecutó correctamente.

**Límites:** los tests y el probe PostgreSQL usan elegibilidad positiva simulada y snapshots de autorización. La prueba de puntaje sustituye servicios de acceso y política anual. No se certifica HTTP con base, autenticación real, UI, almacenamiento remoto ni aplicación de la migración. El helper reconstruye `public` con `prisma migrate diff` y añade los dos índices parciales, no aplica `20261001193000_investiture_authorization_requests`. Los HTTP de unidad conservan guards/Prisma sustituidos y carecen de prefijo público. No se ejecutaron builds, generación Prisma, despliegues o commits. Los probes históricos permanecen intactos y no se usaron como aceptación del código corregido.

**Continuidad:** corregir únicamente la vía residual P4-4 y volver a revisión antes de fase 5. Fase 2 parcial; fase 3 cerrada en el alcance de la octava revisión; pipeline anterior activo y despliegue bloqueado. Evidencia: `docs/reviews/investidura-autorizacion-review-evidence/p4fix-verification.json`, logs `p4fix-*`, runner y nuevo probe.

---

## Novena revisión — solicitudes de fase 4 (2026-10-02)

Esta sección es **histórica; ver décima revisión para el estado de P4-1 a P4-4**. Backend `development` @ `9d8fe1d3d1fd0e56256043ee8208d26c9bfcc39b`, sin commit. **Backend de fase 4 NO APROBADO: cuatro hallazgos de prioridad alta requieren corrección.** Se revisaron contratos, módulo, DTOs, permisos de servicio, migración, escritores de progreso y pruebas. No se corrigió runtime; solo se añadieron este informe, el estado del plan y evidencia independiente.

### P4-1 — Alta / P1: una clase de varios años no puede llegar a presentarse

**Ubicaciones:** `sacdia-backend/src/investiture-requests/investiture-authorization-requests.service.ts:382-385` y `:443-451`. Requisitos IA-08 / IA-18.

Se exige que el año de origen de la inscripción sea el año de la solicitud. Después se cuenta la duración entre el inicio de **ese mismo año** y el inicio del año de la solicitud. Con años distintos y no duplicados, una inscripción que pasa la primera condición cuenta siempre 1. Una clase de duración mínima 2 queda excluida incluso cuando ya llegó al segundo año. El flujo existente calcula hasta el año actual sin reemplazar el año de origen (`investiture.service.ts:2138-2176`).

**Reproducción PostgreSQL:** clase de Guías Mayores con mínimo 2 / máximo 3, inscripción operativa activa de 2025, membresía de la sección en 2026, año y ventana 2026 abiertos y elegibilidad simulada positiva. El conteo real de años es 2, pero presentar devuelve `INVESTITURE_REQUEST_OUTSIDE_SECTION`. Reetiquetar la inscripción como 2026 tampoco resuelve el defecto: devuelve `INVESTITURE_DURATION_MIN_NOT_MET` y perdería la referencia de inicio.

**Corrección requerida:** separar año de la solicitud/membresía y año de inicio de una inscripción plurianual válida. Conservar el inicio y aplicar duración mínima/máxima y estado vigente; no habilitar indiscriminadamente inscripciones históricas, caducadas o de otros años. Regresión: primer año rechaza, segundo año válido admite, vencimiento máximo sigue bloqueado, sin modificar la política anual ni duplicar inscripciones.

### P4-2 — Alta / P1: la inscripción cruzada de un GM queda sin sección desde la cual presentar

**Ubicación:** `sacdia-backend/src/investiture-requests/investiture-authorization-requests.service.ts:387-405`. Requisito IA-05.

La implementación exige a la vez que el tipo de la clase coincida con el de la sección y que exista una asignación de esa persona en esa misma sección. Para un GM investido cuya membresía es GM y que cursa legítimamente una clase cruzada CQ, ninguna de las dos secciones cumple ambas condiciones: GM falla por tipo de clase; CQ falla por membresía. Nunca se alcanza `usesSingleSlot`, aunque ahí esté codificada la excepción GM.

**Reproducción PostgreSQL:** matrícula histórica GM investida, matrícula operativa CQ con `cross_type_enrollment=true` y única membresía vigente en sección GM del mismo club. Tanto presentar desde GM como desde CQ devuelve `INVESTITURE_REQUEST_OUTSIDE_SECTION`. La prueba entregada de dos clases cruzadas tiene membresía del mismo tipo que la clase, por lo que no cubre esta configuración.

**Corrección requerida:** resolver explícitamente la sección responsable de la inscripción cruzada válida, en consistencia con la pertenencia y la política existentes. No pedir una membresía artificial para sortear el fallo ni permitir cruces arbitrarios entre secciones/clubes. Probar GM con membresía solo GM, clase cruzada válida, límites de inscripción, permisos de sección y conservación independiente de otra clase pendiente.

### P4-3 — Alta / P1: el bloqueo de progreso es incompleto y no es atómico

**Ubicaciones:** `sacdia-backend/src/classes/classes.service.ts:1292-1314`, `:1533-1603`; `src/investiture-requests/investiture-request-lock.ts:5-18`; `src/evidence-review/evidence-review.service.ts:1075-1125` y `:1152-1214`. Requisito IA-40.

Hay dos vías del mismo defecto:

1. `submitSection`, `approveClass` y `rejectClass` no consultan pendientes de autorización. Una solicitud puede estar `PENDING` y el progreso pasar de pendiente a enviado y después a rechazado. Ese rechazo modifica la elegibilidad, porque un requisito `REJECTED` deja de contar.
2. En los tres escritores que sí llaman al helper, la consulta de pendientes no comparte transacción/candado con la creación de la solicitud. Por ejemplo, `updateSectionProgress` puede leer “sin pendiente”, confirmar otra operación la solicitud y luego guardar el cambio de progreso. El advisory lock del módulo nuevo no protege a escritores que no lo toman.

**Reproducción con servicios reales y DB simulada:** el helper rechaza una inscripción pendiente, pero `submitSection` seguido de `rejectClass` realiza dos escrituras y cero consultas al bloqueo. Una segunda intercalación pausa `updateSectionProgress` después de su consulta, simula la confirmación de la solicitud y reanuda: se guarda puntaje 0 mientras el pendiente ya existe. Este segundo probe **no es concurrencia PostgreSQL ni una prueba de autenticación**.

**Corrección requerida:** inventariar todos los escritores de progreso/evidencias y establecer una barrera transaccional compartida con presentar/agregar, con orden de locks consistente. Cubrir envío/revisión, actualización de puntaje y alta/baja de archivos, incluidos efectos en storage. No basta agregar una consulta previa. Mantener el bloqueo limitado al enrollment y conservar `EXPIRED`/`INVESTIDO`/año cerrado al quitar el pendiente. Exigir pruebas concurrentes PostgreSQL que intercalen presentar con una escritura de progreso y regresiones de las rutas omitidas.

### P4-4 — Alta / P1: dos personas distintas crean dos solicitudes activas de la misma sección

**Ubicaciones:** `sacdia-backend/src/investiture-requests/investiture-authorization-requests.service.ts:325-351` y `:244-258`. Contrato público: una solicitud por sección/año mientras haya pendientes.

El candado se toma por usuario. Dos altas de **usuarios diferentes** no se bloquean entre sí: ambas pueden leer que la sección/año no tiene cabecera con pendientes y crear una cada una. Los índices únicos parciales por usuario/clase no impiden esta duplicación. El GET devuelve solo la cabecera encontrada por `findFirst`, no todas; por lo tanto oculta parte de los pendientes de esa sección.

**Reproducción PostgreSQL con dos transacciones reales:** una barrera determinista retiene cada lectura de “sin solicitud abierta” hasta que ambas la hayan completado. Ambas altas confirman, quedan **2 cabeceras / 2 personas pendientes**, y el GET devuelve **solo 1 persona**. No se duplicó una persona: se fragmentó el grupo por falta de coordinación de la cabecera.

**Corrección requerida:** coordinar atómicamente la búsqueda/creación del grupo por sección y año, incluso cuando todavía no existe fila, además de las restricciones por persona. Mantener un orden de locks consistente. Prueba de aceptación: dos personas distintas presentadas a la vez producen una sola cabecera visible y el GET incluye ambas; conservar también la prueba de dos altas de la misma persona.

### Verificación independiente

| Comprobación | Resultado |
| --- | --- |
| 16 suites de regresión: fases previas + solicitud + clases | **266 pruebas aprobadas, salida 0**. Incluye las 120 entregadas en las tres suites de solicitud/clases. |
| Suite PostgreSQL entregada | **3 pruebas aprobadas, salida 0** en clúster exclusivo temporal. |
| `phase4-postgres-probe.cjs` | Salida 0: reproduce P4-1, P4-2 y P4-4 con PostgreSQL real. **No significa que los defectos estén corregidos.** |
| `phase4-progress-probe.cjs` | Salida 0: reproduce ambas vías de P4-3 con DB simulada y métodos reales. |
| `tsc --noEmit --incremental false -p tsconfig.build.json` | Salida 0, sin emisión. |
| ESLint del módulo nuevo y spec PostgreSQL | Salida 0. No se reformatearon archivos previos. |
| `git diff --check` raíz/backend | Salida 0. |

**Aislamiento:** PostgreSQL 18.3 local, clúster recién creado y exclusivo, puerto efímero de `127.0.0.1`, base `sacdia_phase4_review_test`, identidad y `read committed` comprobados. Se fijaron `SACDIA_TEST_DATABASE_URL`, `DATABASE_URL`, `DATABASE_DIRECT_URL` y `DOTENV_CONFIG_PATH=/dev/null`. No se usó una base local preexistente, Neon, producción ni `.env` real. Se detuvieron los clústeres temporales y se conservaron sus logs antes de eliminar sus datos. La primera reproducción usó una clase de dos años genérica; se repitió específicamente con clase GM, con el mismo resultado.

**Límites:** los 3 tests PostgreSQL y el probe usan elegibilidad simulada positiva y snapshots de autorización; no verifican autenticación/HTTP, UI ni el cálculo completo de elegibilidad. El helper reconstruye `public` mediante `prisma migrate diff` y añade los índices parciales; no aplica `20261001193000_investiture_authorization_requests`. Los specs HTTP sustituyen guard y Prisma y omiten `/api/v1`. El primer intento HTTP en sandbox falló al abrir el puerto y se repitió con permiso local; no se contabiliza como defecto de negocio. No hubo build, despliegue, `prisma generate` ni modificación de código runtime. Los probes son reproducciones de fallos, no sustituyen los tests de aceptación de las correcciones.

**Continuidad:** corregir P4-1 a P4-4 y volver a revisión antes de aprobar este backend o avanzar a fase 5. La fase 2 sigue parcial. El pipeline anterior continúa activo y el despliegue permanece bloqueado. W1, P3-1, F1, N1 y N2 no se reabren por estos hallazgos. Cambios concurrentes ajenos quedan fuera del veredicto.

Evidencia y comandos: `docs/reviews/investidura-autorizacion-review-evidence/phase4-verification.json`, logs `phase4-*` y ambos probes. No se crearon commits.

---

## Octava revisión — cierre independiente de P3-1 (2026-10-01)

Esta sección es **histórica; P3-1 permanece cerrado**. Backend `development` @ `9d8fe1d3d1fd0e56256043ee8208d26c9bfcc39b`, sin commit. Se inspeccionaron los caminos de cupo/alta/reactivación/baja, los tests nuevos y los límites del helper PostgreSQL. No se modificó código runtime ni se ejecutaron builds, generación de cliente, despliegues o migraciones sobre bases existentes.

### P3-1 cerrado

- `updateQuota` y `assign` toman `pg_advisory_xact_lock(hashtextextended('investiture-pastor-quota', 0))` mediante `$executeRaw`, dentro de sus transacciones y **antes** de leer ocupación/cupo. Alta y reactivación comparten el mismo camino. La identidad del candado no depende de que exista la fila global.
- El orden de alta/reactivación es candado global → bloqueo de distrito → validación/lecturas → escritura. La reducción de cupo cuenta y guarda bajo el mismo candado global; no borra asignaciones.
- GET sigue sin bloquear ni insertar. `remove` no toma el candado global, pero solo disminuye la ocupación y mantiene el bloqueo de distrito: no introduce una vía que aumente activos por encima del cupo.
- Las cuatro combinaciones de orden/fila global y las carreras por el último cupo ya preservan el invariante. Una operación espera y después revalida o rechaza, en lugar de confirmar usando el cupo u ocupación anteriores.
- **Trade-off:** el candado común también serializa altas/reactivaciones de distritos distintos frente a modificaciones del cupo global. No se midió rendimiento bajo carga; es una limitación de concurrencia, no una reapertura del defecto corregido.

No se identificaron nuevos bloqueos para esta corrección. El probe `phase3-quota-race-probe.cjs` se conserva intacto como evidencia histórica: su mock no implementa `$executeRaw` y no es una prueba vigente de aceptación. No se ejecutó ni se presentó su incompatibilidad como regresión del backend.

### Verificación independiente repetida

| Comprobación | Resultado |
| --- | --- |
| Mismas 14 suites de la séptima revisión | **234 pruebas aprobadas, salida 0**; 20 de pastores (18 servicio + 2 HTTP). |
| `test/district-investiture-pastors-postgres.e2e-spec.ts` | **7 pruebas / 1 suite aprobadas, salida 0**, sobre PostgreSQL 18.3 real y exclusivo. |
| `tsc --noEmit --incremental false -p tsconfig.build.json` | **Salida 0**, sin diagnósticos ni emisión. |
| ESLint de servicio, spec de servicio, spec HTTP y spec PostgreSQL de pastores | **Salida 0**. |
| `git diff --check`, raíz y backend | Salida 0. |

**Aislamiento:** se creó un clúster temporal propio en `/tmp`, con puerto efímero en `127.0.0.1` y base nueva `sacdia_p31_review_test`. No se reutilizó una base local del usuario. Se comprobaron identidad de base/servidor/directorio e aislamiento `read committed`. Se fijaron explícitamente las tres URL de base y `DOTENV_CONFIG_PATH=/dev/null`: no se leyó `.env` ni `.env.test.local`, no se conectó a Neon. El servidor quedó detenido y sus datos temporales se eliminaron después de conservar los logs. El primer intento de inicialización usó el binario de `libpq`, que carece del servidor; falló antes de crear un clúster y se repitió con `/opt/homebrew/opt/postgresql@18/bin`.

Los tests PostgreSQL usan una conexión que retiene el candado y observan un waiter no concedido en `pg_locks`; tras liberarlo comprueban ambos órdenes con y sin fila de cupo. También compiten dos altas, y una reactivación contra un alta, por un solo cupo. La suite verifica que siempre quede una sola asignación activa en esos casos.

**Límites de evidencia:** el helper destruye/reconstruye `public` exclusivamente en la base nueva mediante `prisma migrate diff` y añade algunas garantías SQL previas del ciclo anual. No aplica los `CHECK` exclusivos del SQL de la nueva migración de pastores: estas siete pruebas **no certifican el despliegue de esa migración**. PostgreSQL no pasa por HTTP/autenticación; los specs HTTP siguen con guards/Prisma sustituidos y sin prefijo público. No se ejecutó UI ni el rojo histórico del implementador. Otros cambios concurrentes del checkout quedan fuera del alcance.

Evidencia en `docs/reviews/investidura-autorizacion-review-evidence/`: `p31-unit-tests.log`, `p31-postgres-tests.log`, `p31-postgres-identity.log`, `p31-postgres-stop.log`, `p31-runtime-types.log`, `p31-lint.log` y `p31-verification.json` (comandos, resultados, hashes y límites).

**Continuidad:** P3-1 ya no bloquea avanzar a fase 4 conforme al plan. Esto no implementa solicitudes, autorización operativa ni pantallas pendientes, no cierra la fase 2 y no permite desplegar o retirar el pipeline anterior. No se crearon commits.

---

## Séptima revisión — pastores del distrito (2026-10-01)

Esta sección es **histórica; P3-1 fue corregido y cerrado en la octava revisión**. Backend `development` @ `9d8fe1d3d1fd0e56256043ee8208d26c9bfcc39b`, sin commit. Se revisaron servicio, controlador, DTOs, registro en módulo, schema/migración, pruebas y contratos. No se modificó runtime, no hubo build, migración, despliegue ni acceso productivo. Cambios concurrentes ajenos (incluida instrumentación PostHog del pipeline anterior) no forman parte de esta aprobación.

### P3-1 — Alta / P1: el cupo puede quedar por debajo de las asignaciones activas

**Ubicaciones:** `sacdia-backend/src/classes/district-investiture-pastors.service.ts:90-108` y `:134-163`.

`updateQuota` cuenta asignaciones activas y después guarda el cupo, sin transacción ni bloqueo compartido con `assign`. La asignación bloquea la fila del **distrito**, pero la edición del cupo global no adquiere ese bloqueo ni otro que la coordine con el alta. Por tanto, el control secuencial de ocupación no protege el invariante ante operaciones simultáneas.

**Reproducción independiente con servicio real y DB simulada, en dos órdenes:**

1. Cupo 2 y un pastor activo. La reducción a 1 lee una ocupación de 1; antes de guardar, otra solicitud asigna el segundo pastor usando cupo 2. La reducción guarda 1. Ambas tienen éxito: **2 activos / cupo 1**.
2. Cupo 2 y ningún pastor. Un alta lee cupo 2; antes de crear la fila, otra solicitud reduce a 0 porque todavía ve cero activos. El alta guarda después: **1 activo / cupo 0**.

Se reprodujeron ambos órdenes tanto con fila global existente como sin ella (default 2): **cuatro casos**. `phase3-quota-race-probe.cjs` termina con salida 0 porque sus aserciones confirman la reproducción del defecto, no su corrección. Es intercalación sintética, **no una prueba PostgreSQL concurrente ni evidencia de datos productivos**. El SQL revisado impone `slots >= 0` y unicidad distrito/usuario, pero no impide estos estados.

**Corrección requerida:** coordinar atómicamente la lectura, validación y escritura del cupo con altas/reactivaciones. Usar una estrategia de bloqueo común y orden consistente para todos los caminos relevantes; envolver solamente `updateQuota` en una transacción no basta. Debe funcionar sin fila inicial: bloquear una fila inexistente tampoco protege ese caso. Mantener GET sin inserciones, no eliminar asignaciones al reducir cupo y conservar los permisos actuales.

**Pruebas de aceptación:** cubrir los dos órdenes anteriores, con y sin fila de cupo; una de las operaciones debe esperar/revalidar o rechazar, y nunca confirmar `activos > slots`. Añadir carrera de dos altas/reactivaciones por el último cupo. Probar con conexiones independientes sobre PostgreSQL aislado para demostrar bloqueos reales, además de las regresiones unitarias. Reportar expresamente cualquier límite de esa evidencia.

### Comportamiento confirmado en el alcance revisado

- Sin fila, GET devuelve 2 y no escribe. Solo el rol `super-admin` cambia el cupo. Una reducción secuencial incompatible devuelve conflicto sin borrar filas.
- Director/asistente de Campo asignan dentro de su Campo; director/asistente de Unión dentro de su Unión. La combinación Unión + Campo usa Unión para esta acción y la regresión correspondiente pasa; no se cambió la restricción de edición de ventana.
- Super-admin, admin y División no adquieren asignación por esos roles. Super-admin conserva lectura. El alta exige usuario activo y rol global `pastor` activo.
- Dos asignaciones secuenciales ocupan los cupos; una tercera se rechaza. Quitar desactiva y libera un cupo. `can_authorize` refleja la asignación, no una autorización ejecutada.
- El club se resuelve mediante `clubs.church_id` y `churches.districlub_type_id`; la prueba incluye un distrito señuelo en el club y obtiene el de la iglesia. Las nuevas rutas no invocan el pipeline anterior.

### Verificación independiente

| Comprobación | Resultado |
| --- | --- |
| Doce suites anteriores + servicio y controlador de pastores | **226 pruebas / 14 suites aprobadas, salida 0**; 12 pruebas de pastores. |
| `tsc --noEmit --incremental false -p tsconfig.build.json` | **Salida 0**, sin diagnósticos ni emisión. |
| ESLint de servicio/spec, controlador/spec, dos DTOs y `classes.module.ts` | **Salida 0**. No es lint global. |
| `phase3-quota-race-probe.cjs` | P3-1 reproducido en cuatro intercalaciones; salida 0 del reproductor. |
| `git diff --check`, raíz y backend | Salida 0. |

Jest se ejecutó mediante escalación autorizada para permitir los servidores efímeros de los specs HTTP. Estos usan guards/Prisma sustituidos, sin `AppModule`, autenticación real, base real ni prefijo `/api/v1`; no se amplía esa evidencia a e2e productivo. No se repitieron `prisma generate`, el rojo inicial ni la aplicación/reversión de la migración: siguen siendo evidencia reportada por el implementador. No había `SACDIA_TEST_DATABASE_URL` configurada y no se usó otra base. No se ejecutó UI.

Evidencia en `docs/reviews/investidura-autorizacion-review-evidence/`: `phase3-tests.log`, `phase3-runtime-types.log`, `phase3-lint.log`, `phase3-quota-race-probe.cjs`, `phase3-quota-race-probe.log` y `phase3-verification.json`.

**Siguiente paso:** corregir P3-1 y entregar diff/pruebas para revisión independiente antes de aprobar fase 3 y continuar con fase 4. No desplegar ni retirar el pipeline anterior. Los cierres anteriores W1/F1/N1/N2 no se reabren por este hallazgo.

---

## Sexta revisión — cierre independiente de W1 (2026-10-01)

Esta sección es **histórica; el cierre de W1 sigue vigente**. Se revisó backend `development` @ `9d8fe1d3d1fd0e56256043ee8208d26c9bfcc39b`, con cambios sin commit y archivos de ventana todavía sin seguimiento. Se revisaron helper, servicio, controlador, pruebas y contrato actualizado. No se modificó runtime ni se ejecutaron builds, migraciones o despliegues. Los cambios concurrentes ajenos a investidura quedan fuera del alcance.

### W1 cerrado: ausencia de ventana no abre el año

- `defaultInvestitureWindow` devuelve `null` si no existe intersección; `allowsOperation` devuelve `false` sin extremos válidos.
- Se repitió el caso de año `2026-01-01`–`2026-06-30`, sin fila, día local `2026-02-15`: fechas `null`, `configured: false`, `operational: false`, `can_edit: true` para director del Campo, sin escrituras.
- Un rango guardado por ese director (`2026-02-01`–`2026-02-20`) abre únicamente sus días locales inclusivos. Se probaron los segundos inmediatamente anteriores y posteriores a sus límites. Año inactivo o día posterior al año bloquean operación y edición, incluso para `super-admin`.
- Filas fuera del año o con extremos invertidos, en ese año sin intersección predeterminada, quedan sin efecto operativo y no se reescriben al leer. Se mantienen el default octubre–diciembre para el año completo y los recortes parciales.
- API, guía de integración, feature y referencia DB reflejan la ausencia de ventana. `operational` significa **existe un rango efectivo**, no «abierto hoy» ni permiso de autorización; puede seguir siendo `true` fuera de sus fechas. `can_edit` tiene una evaluación independiente.

No se identificaron nuevos bloqueos para **esta corrección W1**. El probe independiente nuevo es `w1-closure-probe.cjs`; el anterior `phase2-default-probe.cjs` se conserva intacto como reproducción histórica del defecto, no como prueba de aceptación del código corregido.

### Verificación independiente

| Comprobación | Resultado |
| --- | --- |
| Once suites anteriores + `field-investiture-window.controller.spec.ts` | **214 pruebas / 12 suites aprobadas, salida 0**; 29 pruebas de ventana. |
| `tsc --noEmit --incremental false -p tsconfig.build.json` | **Salida 0**, sin emisión ni diagnósticos. |
| ESLint de siete archivos de ventana, incluido el nuevo spec HTTP y DTO | **Salida 0**. No es lint global del backend. |
| `w1-closure-probe.cjs` | **Salida 0**. Servicio real con reloj/persistencia sintéticos; sin DB ni red. Una única escritura, exclusivamente al configurar. |
| `git diff --check`, raíz y backend | Salida 0. |

La primera ejecución Jest encontró `listen EPERM` en las dos pruebas HTTP por restricciones del sandbox (212 pasaron). Se repitió el comando completo con escalación autorizada para el servidor efímero y pasaron las 214. Se conservan ambos logs.

**Límites:** el HTTP usa Nest de prueba, guards sustituidos, Prisma/snapshot/reloj simulados, sin `AppModule`, pipes globales de producción ni prefijo `/api/v1`; prueba serialización y recorrido controlador/servicio, no autenticación real ni integración completa. No se ejecutaron PostgreSQL, migraciones, UI ni el rojo histórico informado por el implementador. La búsqueda de llamadas confirma que `allowsOperation` sigue usado solo en tests; no protege las rutas operativas actuales.

Evidencias: `docs/reviews/investidura-autorizacion-review-evidence/w1-closure-probe.cjs`, `w1-closure-probe.log`, `w1-tests-sandbox.log`, `w1-tests.log`, `w1-runtime-types.log`, `w1-lint.log` y `w1-verification.json` (comandos, resultados y hashes).

**Continuidad:** W1 ya no bloquea el desarrollo de fase 3 (pastores del distrito). Mantener explícitos los pendientes de integración de fase 2 y del plan, así como el inventario previo al cambio de vía. No desplegar ni retirar el pipeline anterior. Los archivos sin seguimiento deberán incluirse en una futura entrega versionada; no se creó ningún commit en esta revisión.

---

## Quinta revisión — configuración de ventana (2026-10-01)

Esta sección es **histórica; W1 fue corregido y cerrado en la sexta revisión**. Misma base del backend `9d8fe1d3d1fd0e56256043ee8208d26c9bfcc39b`, cambios sin commit. Se revisaron helper, servicio, controlador/DTO, registro de módulo, alcance territorial, pruebas, SQL/schema y documentación. No se cambió código runtime ni se ejecutaron builds o migraciones.

### W1 — Media / P2: sin intersección se abre todo el año; debe permanecer cerrado

**Ubicación:** `/Users/abner/Documents/development/sacdia/sacdia-backend/src/classes/field-investiture-window.ts:24-27`.

Al revisar la entrega, IA-23 establecía octubre 1–diciembre 20, recortado al año eclesiástico, sin definir la intersección vacía. El código agrega un comportamiento distinto: devuelve todo el año como ventana. **Recortar un rango no autoriza sustituirlo por otro más amplio**. La definición posterior del usuario exige mantenerlo cerrado, como se registra abajo.

**Reproducción independiente:** ciclo sintético `2026-01-01`–`2026-06-30`, activo, sin fila configurada, día local `2026-02-15`. `get` devuelve enero 1–junio 30, `configured: false`; `allowsOperation` devuelve **true** sin que nadie haya configurado esa apertura. Como control, con el ciclo enero–diciembre devuelve octubre 1–diciembre 20 y **false** para ese mismo día de febrero. No hubo escrituras.

El test actual que espera el año completo confirma la implementación, no su aprobación funcional. No se afirma que haya solicitudes productivas aceptadas indebidamente: el predicado todavía no está conectado a rutas de solicitudes/autorización.

**Decisión aprobada el 2026-10-01:** el usuario respondió «adelante con la recomendación». Si no hay intersección y no existe configuración explícita válida, mantener cerradas las operaciones hasta que un editor autorizado configure un rango válido dentro del año. La lectura debe comunicar la ausencia de ventana operativa, sin insertar una fila ni inventar una apertura. IA-23 y las pruebas exigidas en la fase 2 ya reflejan esta decisión. **W1 sigue abierto: aprobar la regla no equivale a corregir el código.** No se modificó runtime ni se repitieron pruebas de código en esta actualización documental.

**Entrega requerida al implementador:** reemplazar la expectativa de apertura anual por una regresión que falle antes de corregir y pase después; cubrir helper, servicio y respuesta HTTP sin intersección/sin configuración, ausencia de escrituras al leer, configuración explícita válida, recorte parcial y control octubre–diciembre. Mantener año activo, límites locales inclusivos y permisos existentes. Documentar en API y feature la representación pública de ausencia de ventana, sin fechas ficticias. Entregar diff, comandos, salidas, conteos y limitaciones en el informe de implementación. No borrar los probes/logs históricos, desplegar, ejecutar builds ni retirar el pipeline anterior.

### Comprobaciones y cierres

- **F1 cerrado:** la referencia API y la guía de integración ya distinguen correctamente el HTTP 400 de `I18nValidationPipe`, sin `code`, del `CLASS_THRESHOLD_PERCENT_INVALID` interno.
- La lectura por defecto no inserta; fechas configuradas se guardan por Campo/año. Validación de fechas imposibles, extremos fuera del ciclo e inicio posterior al fin en el servicio.
- Lectura y edición tienen comprobaciones separadas. El alcance territorial se valida antes de leer la ventana; director/asistente de Campo no adquieren escritura en otros Campos por tener además un cargo de Unión. Unión/División consultan su alcance y no escriben. Admin/assistant-admin usan el alcance del resolvedor existente; super-admin no obtiene excepción a año inactivo o día fuera del ciclo.
- Se comprueba año activo y día civil de la zona del Campo. Los límites de la ventana son inclusivos. Guardar la ventana no otorga autorización ni edición del porcentaje; la regresión que intenta cambiar porcentaje con admin tras guardar ventana pasa.
- `allowsOperation` solo tiene llamadas en la suite nueva, no en el pipeline anterior. Se considera un predicado preparado para integración futura, **no evidencia de que presentación/adiciones/autorizaciones runtime ya estén bloqueadas por la ventana**.

### Verificación independiente

| Comprobación | Resultado |
| --- | --- |
| Nueve suites previas + dos suites de ventana | **208 pruebas / 11 suites aprobadas, salida 0**. |
| `tsc --noEmit --incremental false -p tsconfig.build.json` | **Salida 0**, sin diagnósticos. |
| ESLint de seis archivos nuevos de ventana: helper/spec, servicio/spec, controlador y DTO | **Salida 0**. |
| Probe de intersección vacía | W1 reproducido con servicio real y persistencia/reloj sintéticos; salida 0 del script que comprueba el caso. |
| `git diff --check`, raíz y backend | Salida 0. |
| PostgreSQL, migración, HTTP de ventana, UI | No repetidos por este revisor. No hay `SACDIA_TEST_DATABASE_URL` configurada. El SQL local aplicado/revertido sigue siendo evidencia del implementador, no verificación independiente nueva. |

Evidencia en `/Users/abner/Documents/development/sacdia/docs/reviews/investidura-autorizacion-review-evidence/`: `phase2-unit-tests.log`, `phase2-runtime-types.log`, `phase2-lint.log`, `phase2-default-probe.cjs`, `phase2-default-probe.log` y `phase2-verification.json`.

El probe HTTP del porcentaje de la cuarta revisión sigue disponible como evidencia acotada anterior; no equivale a e2e con autenticación/DB reales y no se repitió para esta entrega. No hay pantalla. Solicitudes por persona, duración IA-18, conexión del predicado al nuevo flujo, fases 3–8 e inventario de transición siguen pendientes.

**Siguiente paso:** implementar la regla aprobada para W1, sincronizar el contrato y repetir las regresiones antes de aprobar fase 2. La definición de negocio ya no está pendiente; la corrección y su revisión independiente sí. No desplegar ni retirar rutas anteriores.

---

## Cuarta revisión — API del porcentaje del Campo (2026-10-01)

Esta sección es **histórica; F1 fue corregido y cerrado en la quinta revisión**. Se revisó el nuevo controlador, DTO, servicio, registro en `ClassesModule`, cálculo de fecha/corte, alcance, errores y documentación canónica. Misma base de backend `9d8fe1d3d1fd0e56256043ee8208d26c9bfcc39b`, cambios sin commit. No se modificó runtime.

### F1 — Media / P2: el error HTTP de porcentaje inválido no coincide con la documentación

**Ubicaciones:** `/Users/abner/Documents/development/sacdia/docs/api/ENDPOINTS-LIVE-REFERENCE.md:1021` y `/Users/abner/Documents/development/sacdia/docs/api/FRONTEND-INTEGRATION-GUIDE.md:70`.

Ambos documentos prometen `CLASS_THRESHOLD_PERCENT_INVALID` para un porcentaje fuera de rango. Sin embargo, `@IsInt`, `@Min` y `@Max` del DTO son procesados por el `I18nValidationPipe` global **antes de ejecutar el controlador/servicio**. Por HTTP, `101`, `-1`, `90.5`, `"90"` y `null` producen HTTP 400 con `statusCode`, `message` y `error`, sin ese `code`. El guard del servicio que emite el código específico sigue protegiendo llamadas internas, pero no determina esta respuesta pública.

**Evidencia:** probe HTTP local con controlador, servicio, `GlobalRolesGuard`, DTO, pipes y filtro I18n reales. Para `101`, la estructura obtenida fue `{ "statusCode": 400, "message": ["minimum_percent must not be greater than 100"], "error": "Bad Request" }`. La traducción fue simulada: se verificó la estructura/código ausente, no el texto localizado de producción. No hubo escritura para ninguno de los cinco cuerpos inválidos.

**Corrección recomendada:** alinear ambos documentos con el HTTP 400 de validación de DTO que usa el backend, distinguiéndolo del error de dominio del servicio. Si se exige conservar el código específico como contrato público, debe implementarse y probarse explícitamente en la ruta; no basta con la prueba unitaria del servicio. Resolverlo antes de que app/panel dependan de ese código.

**Impacto:** no es bypass de permisos ni aceptación de valores inválidos. No impide continuar el desarrollo de fase 2, pero queda pendiente para cerrar el contrato público de fase 1.

### Comportamiento verificado

- GET sin fila devuelve 80 y `configured: false`, sin insertar. PATCH acepta 0, 90 y 100; la lectura posterior devuelve el valor guardado en el doble de persistencia.
- Director/asistente del Campo operan solo dentro de su Campo. Admin, directores/asistentes de Unión/División y director de club reciben 403; el probe comprueba que esas negativas no leen datos del Campo/umbral. La combinación director de Campo + director de Unión no habilita otro Campo.
- El alias amplio de `GlobalRolesGuard` no se convierte en permiso efectivo: el servicio vuelve a exigir rol exacto y Campo. Se verificaron GET y PATCH por la ruta.
- El último instante de junio se acepta y julio se rechaza para Campo, tanto en `America/Mexico_City` como en `America/New_York`. Super-admin puede escribir después del corte, pero no fuera del año solicitado. GET puede devolver `can_edit: false`.
- El DTO y el servicio restringen el porcentaje a enteros 0–100. El controlador obtiene el actor desde la petición autenticada; no acepta `updated_by_id` del cuerpo.
- `CLOCK` y `LocalFieldTimezoneResolver` están exportados por `CommonModule` global; controlador/servicio están registrados en `ClassesModule`. Revisión estática, no arranque completo de `AppModule`.
- `computeGrade` no tiene diff y conserva B desde 70 en `clubs.service.ts:1507-1515`; se inspeccionó el código, no se ejecutó su suite.

### Verificación independiente

| Verificación | Resultado |
| --- | --- |
| Ocho suites previas + `field-class-threshold-config.service.spec.ts` | **185 pruebas / 9 suites aprobadas, salida 0**. |
| `tsc --noEmit --incremental false -p tsconfig.build.json` | **Salida 0**, sin diagnósticos. Sin build. |
| ESLint del servicio nuevo, controlador, spec, DTO y helper del porcentaje | **Salida 0**. No significa lint limpio de todo el repositorio. |
| Probe HTTP sintético | **32 peticiones verificadas, salida 0**. Detecta F1 y confirma la matriz probada de roles, Campo, corte y DTO. |
| `git diff --check`, raíz y backend | Salida 0. |
| PostgreSQL / migración / UI / autenticación real | No ejecutados. No aprobados por estas pruebas. |

**Límite del probe HTTP:** usa servidor efímero en `127.0.0.1`; JWT, snapshot de autorización, Prisma, reloj y traducción son dobles sintéticos. No carga `AppModule`, `.env`, DB, Redis ni servicios externos. No sustituye e2e con autenticación y PostgreSQL reales. El sandbox inicialmente rechazó `listen` con EPERM; la ejecución se repitió mediante la escalación normal aprobada, sin eludir la restricción.

Evidencia en `/Users/abner/Documents/development/sacdia/docs/reviews/investidura-autorizacion-review-evidence/`: `phase1-unit-tests.log`, `phase1-runtime-types.log`, `phase1-lint.log`, `phase1-http-probe.cjs`, `phase1-http-probe.log` y `phase1-verification.json`.

**Continuidad:** se puede corregir F1 y avanzar con fase 2 conforme al plan, sin desplegar, aplicar migraciones productivas ni retirar la vía vieja. Pantalla del porcentaje, pruebas con PostgreSQL real y fases restantes siguen pendientes. Este cierre no implementa IA-18 ni certifica el flujo integral de autorización.

---

## Tercera revisión — cierre independiente de N1 y N2 (2026-10-01)

Esta sección documenta el **cierre histórico de N1/N2, que sigue vigente**. Sus conteos corresponden al árbol de trabajo anterior a la API del porcentaje; las revisiones siguientes en este documento son todavía anteriores.

**Alcance:** verificar las correcciones de N1/N2 sobre el mismo HEAD `9d8fe1d3d1fd0e56256043ee8208d26c9bfcc39b`, sin commit. No se modificó código runtime, no hubo build, despliegue, migración, acceso productivo ni envío de correos. El checkout contiene otros cambios concurrentes (Vision/PDF, reportes, camporee-scoring, QR); esta revisión no los certifica ni los atribuye al plan de investidura.

### Hallazgos cerrados

- **N1 — cerrado:** `InstitutionalStore` usa los delegados del cliente generado mediante `Pick<Prisma.TransactionClient, ...>` y ya no se convierte `tx` al contrato incompatible. El cálculo por lote descarta `enrollment_id == null` antes de agrupar. La comprobación de tipos runtime termina sin diagnósticos, salida 0.
- **N2 — cerrado:** `submit` invoca el guard de edad con `tx` dentro de `$transaction`; persiste el `age.yearId` devuelto por esa validación y escribe solicitud, clasificación del archivo y evento dentro de la misma transacción. Las regresiones diferencian el cliente global del transaccional y verifican que el año guardado proviene del segundo.

**Repetición independiente del fallo N2:** se mantuvo la intercalación del probe anterior —nacimiento válido antes de comenzar, corrección a edad histórica 8 con mínimo 16 justo al entrar en la transacción— y se cambiaron únicamente las expectativas hacia el comportamiento correcto. Ahora rechaza `CERTIFICATE_IMPORT_AGE_BELOW_MINIMUM`, no crea solicitud ni evento ni actualiza el archivo; lee nacimiento una vez dentro y cero fuera. Las tres sentencias de bloqueo se ejecutan dentro de la transacción simulada. Se usó el servicio real con objetos sintéticos: **no es una prueba de concurrencia PostgreSQL**.

### Evidencia ejecutada

Directorio de ejecución: `/Users/abner/Documents/development/sacdia/sacdia-backend`.

| Verificación | Resultado |
| --- | --- |
| Mismo comando de ocho suites documentado en la primera revisión | **171 pruebas / 8 suites aprobadas, salida 0** en el checkout actual. No se reutiliza el conteo de 165 reportado por el implementador. |
| `./node_modules/.bin/tsc --noEmit --incremental false -p tsconfig.build.json` | **Salida 0, sin diagnósticos**. No ejecuta un build ni emite archivos. |
| `n1n2-submit-probe.cjs` | **Salida 0**; rechazo y ausencia de efectos parciales comprobados. |
| ESLint de los mismos ocho archivos runtime, sin `--fix` | **52 errores de formato, salida 1**; no se declara lint global limpio. `field-class-threshold.ts`, `class-certificate-historical-age.ts` y `class-requirement-eligibility.service.ts` tienen cero errores. Los 14 diagnósticos del servicio institucional no coinciden con líneas añadidas frente a HEAD. |
| `git diff --check`, backend y raíz | Salida 0. |
| PostgreSQL / migración / contrato HTTP / UI | No ejecutados en esta pasada. No hay `SACDIA_TEST_DATABASE_URL` definida. Se mantiene explícitamente el límite de evidencia de PostgreSQL indicado en la segunda revisión. |

Evidencias nuevas en `/Users/abner/Documents/development/sacdia/docs/reviews/investidura-autorizacion-review-evidence/`: `n1n2-unit-tests.log`, `n1n2-runtime-types.log`, `n1n2-lint.json`, `n1n2-submit-probe.cjs`, `n1n2-submit-probe.log` y `n1n2-verification.json` (comandos, salidas y huellas de fuentes). Los logs y probes previos se conservan como evidencia histórica, no como fallos vigentes.

### Continuidad autorizable

**Ya no hay un bloqueo N1/N2 para continuar implementando.** El siguiente bloque debe completar los pendientes de fase 1 —configuración/edición del porcentaje con sus permisos y fecha de corte— antes de darla por terminada y avanzar según las dependencias del plan. No interpretar este cierre como certificación exhaustiva de fase 0B, integración global, migración aplicada ni autorización de producción.

Mantener la vía anterior activa hasta implementar la nueva y cumplir el inventario y aprobación de transición. Cada entrega siguiente debe indicar alcance, archivos, pruebas ejecutadas, limitaciones y pendientes para revisión independiente. El formato previo pendiente se puede tratar separadamente sin mezclar un reformateo masivo con cambios funcionales.

---

## Segunda revisión — correcciones R1–R4 (cierre 2026-10-01)

Esta sección es **histórica, anterior al cierre de N1/N2**. Se revisó el diff sin commit sobre el mismo HEAD `9d8fe1d3d1fd0e56256043ee8208d26c9bfcc39b`. Los cambios concurrentes de camporee-scoring y QR quedan fuera del alcance.

### Resultado de las cuatro correcciones

| Hallazgo original | Resultado actual |
| --- | --- |
| R1 — Campo en cursado cruzado | Caso funcional corregido. La regresión con Campo 90 y puntaje 85 rechaza elegibilidad tanto individual como por lote. Hay prueba separada de Campo no resuelto (sin consulta) frente a Campo resuelto sin fila (consulta y default 80). |
| R2 — Aprobación institucional | La lectura y la decisión ahora usan el cliente de `$transaction`; solicitud, persona, clase y año se bloquean, y estado/evento se escriben dentro. Pasan las regresiones de nacimiento y año. Hay un error de tipos nuevo en esta implementación (N1). La prueba PostgreSQL añadida se inspeccionó, pero no se repitió en esta revisión. |
| R3 — Fila READY editada | Caso funcional corregido: fecha inválida con `mark_as_ready` omitido o `false` termina en `NEEDS_REVIEW`; con `true` rechaza sin guardar. La misma función valida el `class_id` resultante de la edición. |
| R4 — Consultas por miembro | Fanout corregido en el camino revisado. El listado llama una vez a `calculateForEnrollments`; la regresión de cuatro miembros de una clase/año comprueba una consulta de secciones, progreso, asignaciones y umbrales. Hay errores de tipos nuevos en el agrupamiento (N1). |

Esto valida las correcciones funcionales indicadas, **no aprueba el bloque para integración ni da por terminada fase 0B**.

### N1 — Alta / P1: tres errores nuevos impiden pasar la comprobación de tipos runtime

`./node_modules/.bin/tsc --noEmit --incremental false -p tsconfig.build.json` termina con **salida 2** y tres diagnósticos, todos en líneas incorporadas para las correcciones:

- `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/institutional-certificate-requests.service.ts:270`: **TS2352**. La conversión directa de `tx` a `InstitutionalStore` no es compatible con el contrato `HistoricalAgeDb`, concretamente el delegado genérico `users.findUnique` del cliente generado.
- `/Users/abner/Documents/development/sacdia/sacdia-backend/src/classes/class-requirement-eligibility.service.ts:209,215`: **TS2345**. Prisma tipa `row.enrollment_id` como `number | null`, pero el `Map` exige `number`. El filtro SQL no estrecha automáticamente ese tipo en TypeScript.

**Corrección requerida:** hacer compatible el contrato del cliente transaccional con el cliente Prisma generado, sin desactivar el chequeo; estrechar explícitamente `enrollment_id` antes del agrupamiento. Repetir el mismo `tsc --noEmit` y las ocho suites. La primera revisión pasaba este chequeo; las 163 pruebas actuales no reemplazan la validación de tipos. No se ejecutó ningún build.

### N2 — Media / P2: el alta institucional todavía valida fuera de la transacción

**Ubicación:** `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/institutional-certificate-requests.service.ts:142-159`.

Pendiente reconocido por el implementador y confirmado independientemente. `submit` resuelve `yearId` y valida edad usando el cliente global; después abre la transacción para crear solicitud y evento. Sus sentencias `FOR UPDATE` previas no protegen la posterior creación.

**Reproducción:** servicio real con DB simulada; edad histórica inicial 18, mínimo 16. Se cambia nacimiento a una edad histórica de 8 inmediatamente antes de entrar a `$transaction`. Se guardan `PENDING_REVIEW` y `REQUEST_SUBMITTED`, con una lectura de edad fuera y cero dentro. No es una prueba PostgreSQL concurrente ni evidencia de datos productivos. **No demuestra acreditación indebida:** `approve` vuelve a validar.

**Corrección requerida:** validar edad y resolver el año que se persiste dentro de la misma transacción de alta, conservando sus bloqueos hasta guardar. Añadir una regresión que diferencie explícitamente el cliente global del transaccional. No marcar IA-53/fase 0B completamente cerrados mientras persista este caso.

### Verificación repetida y límites

| Comprobación | Resultado independiente actual |
| --- | --- |
| Mismo comando de ocho suites indicado abajo | **163 pruebas / 8 suites aprobadas; salida 0.** |
| `tsc --noEmit --incremental false -p tsconfig.build.json` | **3 errores; salida 2**, confirmado nuevamente al cierre del 2026-10-01. |
| Probe de alta institucional | Pendiente N2 reproducido; salida 0 del script que comprueba la reproducción. |
| ESLint, mismos ocho archivos runtime, sin `--fix` | **54 errores de formato; salida 1**. No se atribuyen todos al diff. El helper nuevo `field-class-threshold.ts:5,42` también tiene errores; no todo corresponde a líneas antiguas. |
| `git diff --check`, raíz y backend | Salida 0. |
| Referencia API e integración | Ya documentan códigos de edad histórica y transición READY → NEEDS_REVIEW. |
| PostgreSQL / migración | **No repetidos independientemente.** No estaba definida `SACDIA_TEST_DATABASE_URL`. El helper de la suite elimina/recrea el schema y requiere una base loopback dedicada; no se usó una base compartida ni se leyó `.env`. La ejecución local y reversión de migración siguen siendo evidencia reportada por el implementador. |

La prueba PostgreSQL añadida verifica un caso inicialmente inválido y una aprobación que espera el bloqueo de la persona; luego libera ese bloqueo **sin cambiar el nacimiento**. No debe describirse como una reproducción PostgreSQL del cambio de nacimiento durante la espera; esa intercalación sí tiene cobertura unitaria.

Evidencias nuevas en `/Users/abner/Documents/development/sacdia/docs/reviews/investidura-autorizacion-review-evidence/`: `rereview-unit-tests.log`, `rereview-runtime-types.log`, `rereview-lint.log`, `rereview-submit-probe.cjs` y `rereview-submit-probe.log`. El probe se ejecuta igual que el original, sustituyendo el nombre del archivo. Los probes antiguos prueban fallos del snapshot anterior: no son una suite de aceptación del código corregido.

**Siguiente paso:** corregir N1 y N2, atender el formato del código nuevo y repetir los gates. Mantener el plan parcial y el despliegue bloqueado: las fases 2–8 y el reemplazo controlado del pipeline anterior no forman parte de estas correcciones. Esta revisión solo agregó documentación/evidencia; no modificó runtime ni creó commits.

---

## Primera revisión — histórico anterior a las correcciones

## Alcance

Revisado el árbol de trabajo de `/Users/abner/Documents/development/sacdia/sacdia-backend`, rama `development`, sobre `9d8fe1d3d1fd0e56256043ee8208d26c9bfcc39b`, incluidos archivos nuevos no rastreados. Contraste con el plan IA-01–IA-56 y con `/Users/abner/Documents/development/sacdia/docs/reviews/investidura-autorizacion-implementation-report.md`.

No se modificó código de aplicación, no hubo builds, migraciones, commits, envíos de correo ni acceso a datos productivos. Los archivos creados por esta revisión son este informe y sus evidencias. No se revisó UI: admin no tiene cambios y los cambios previos de app son ajenos.

## Hallazgos

### R1 — Alta / P1: el cursado cruzado GM pierde el porcentaje de su Campo

**Ubicación del cambio:** `/Users/abner/Documents/development/sacdia/sacdia-backend/src/classes/class-requirement-eligibility.service.ts:134-136,256-290`.

`resolvePassingScore` obtiene el Campo desde `resolveRequirementContext`, pero ese contexto busca asignaciones con el mismo `club_type_id` de la clase (`:368-384`). Un GM que pertenece a la sección GM y cursa una clase AV/CQ cruzada es un caso permitido; no necesita una asignación regular a esa sección AV/CQ. En ese caso el contexto queda vacío, no se consulta `local_field_class_thresholds` y se usa 80 aunque su Campo tenga 90.

**Reproducción:** servicio real con Prisma simulado y requisito BASIC con puntaje 85. Control regular: umbral 90, no elegible. GM cruzado del mismo Campo: umbral 80, elegible, cero consultas a la configuración. No hay endpoint de edición todavía, pero la lectura de una configuración existente ya da un resultado incorrecto.

**Corrección requerida:** resolver el Campo efectivo del cursado cruzado sin exigir una asignación de miembro al tipo de club de la clase. No confundir «no se resolvió el Campo» con «Campo resuelto sin configuración». Añadir regresión con un GM cruzado, Campo 90 y puntaje 85, contrastando detalle, elegibilidad y listado colectivo.

### R2 — Alta / P1: la aprobación institucional no protege la edad hasta confirmar

**Ubicación del cambio:** `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/institutional-certificate-requests.service.ts:272-278`.
**Apoyo:** `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/class-certificate-historical-age.ts:130-168` y el método `decide` institucional (`:310-355`).

Se pasa el cliente Prisma global al validador, no un cliente transaccional. Los dos `SELECT ... FOR UPDATE` son sentencias independientes: sus bloqueos no se mantienen durante la posterior lectura/validación y escritura de la decisión. `decide` también escribe fuera de una transacción compartida. Una corrección concurrente de nacimiento o mínimo puede dejar una solicitud institucional `APPROVED` con datos que ya no satisfacen la edad.

**Reproducción:** intercalación controlada con el servicio real y DB simulada: se lee una edad histórica de 18, cambia el nacimiento a una edad histórica de 8 antes de guardar, con mínimo 16, y la respuesta queda `APPROVED`. Se registran dos sentencias de bloqueo y cero transacciones. Esto demuestra la secuencia desprotegida; no es una prueba de concurrencia con PostgreSQL real ni de casos en producción. En esta vía aprobar no crea enrollment, por lo que el hallazgo no afirma que se haya creado una investidura operativa.

**Corrección requerida:** revalidar con los datos vigentes y confirmar solicitud/auditoría dentro de la misma transacción que mantiene los bloqueos necesarios. Cubrir también la dependencia del año acreditado. Añadir pruebas de intercalación y una prueba PostgreSQL aislada antes de declarar satisfecha la protección de concurrencia de fase 0B.

### R3 — Media / P2: un certificado inválido puede conservar el estado READY

**Ubicación:** `/Users/abner/Documents/development/sacdia/sacdia-backend/src/certificate-bulk-imports/certificate-bulk-imports.service.ts:329-340`.

La validación nueva solo corre si el PATCH envía `mark_as_ready: true`. Si un ítem ya está `READY`, se puede cambiar su fecha o clase omitiendo esa propiedad; el código conserva `existing.status` sin volver a validar la edad.

**Reproducción:** un ítem Amigo `READY` de 2026 se edita a `completed_at: 2025-06-01` para un usuario nacido en 2016, sin `mark_as_ready`. Sigue `READY` y hay cero lecturas de nacimiento. El envío y la aprobación posteriores sí revalidan: este hallazgo es una violación del estado «listo» exigido por IA-55, no un bypass demostrado de la acreditación final.

**Corrección requerida:** ante cambios relevantes de un ítem listo, revalidarlo antes de conservar ese estado o devolverlo explícitamente a borrador/`NEEDS_REVIEW`. Añadir pruebas omitiendo la propiedad y enviándola en `false`.

### R4 — Media / P2: el listado colectivo introduce consultas por cada miembro

**Ubicación:** `/Users/abner/Documents/development/sacdia/sacdia-backend/src/classes/class-progress-scope.service.ts:283-296`.

Se sustituyen dos consultas agregadas por una llamada completa a `calculateForEnrollment` por miembro, lanzadas con `Promise.all` sin límite. Cada llamada vuelve a leer inscripción, secciones de la misma clase, progreso, contexto y configuración del Campo. El endpoint devuelve toda la lista, sin paginación en esta consulta.

**Reproducción:** para 30 miembros regulares, el simulador contó 181 invocaciones a delegates (incluida la consulta de miembros y excluida la resolución inicial de permisos/scope), frente a las tres consultas de esa parte del flujo anterior. Es conteo de llamadas, no medición de latencia ni de viajes físicos a PostgreSQL; Prisma puede agrupar algunas lecturas. Aun así, se repiten por persona los `findMany` de secciones, progreso y asignaciones.

**Corrección requerida:** conservar el criterio de elegibilidad compartido, pero alimentar su evaluación con datos precargados por lote y reutilizar catálogo/umbral/contexto cuando corresponda. Limitar concurrencia por sí solo no elimina las lecturas repetidas. Añadir una prueba de presupuesto de consultas para un listado de varias personas.

## Verificación independiente

Directorio de comandos: `/Users/abner/Documents/development/sacdia/sacdia-backend`.

| Verificación | Resultado |
| --- | --- |
| Ocho suites del slice, completas, con Jest `--runInBand --no-coverage` | **157 pruebas aprobadas**, salida 0. |
| Tipos de código runtime: `./node_modules/.bin/tsc --noEmit --incremental false -p tsconfig.build.json` | **Salida 0**. Usa la configuración de exclusión de tests, no ejecuta un build ni emite artefactos. |
| Probes adicionales con servicios reales y DB simulada | R1 y R3 reproducidos; intercalación R2 y conteo R4 reproducidos. |
| ESLint sin `--fix` sobre ocho archivos runtime afectados | **79 errores, salida 1**. Hay problemas de formato y dos aserciones de tipos innecesarias. No se atribuyen todos al diff: también hay deuda previa; los helpers nuevos ya contienen errores de formato. |
| `git diff --check` del backend | Salida 0. |
| PostgreSQL aislado / migración / contratos HTTP / UI | No ejecutados. No se consideran aprobados. |

También se intentó `tsc --noEmit --incremental false` con el tsconfig global: produjo errores masivos de tipos en tests. No se presenta como verificación aprobada ni se atribuyen esos errores a este slice. El chequeo runtime acotado de la tabla sí finalizó satisfactoriamente.

### Comando de suites

```sh
./node_modules/.bin/jest --runInBand --no-coverage --runTestsByPath \
  src/certificate-bulk-imports/class-certificate-historical-age.spec.ts \
  src/certificate-bulk-imports/certificate-bulk-imports-application.service.spec.ts \
  src/certificate-bulk-imports/certificate-bulk-imports.service.spec.ts \
  src/certificate-bulk-imports/institutional-certificate-requests.service.spec.ts \
  src/classes/field-class-threshold.spec.ts \
  src/classes/class-requirement-eligibility.service.spec.ts \
  src/classes/class-progress-scope.service.spec.ts \
  src/classes/classes.service.spec.ts
```

Evidencias en `/Users/abner/Documents/development/sacdia/docs/reviews/investidura-autorizacion-review-evidence/`: `unit-tests.log`, `runtime-types.log`, `lint.log`, `probes.cjs` y `probes.log`. El script de probes usa rutas del checkout revisado y solo objetos sintéticos; no instancia un cliente de base de datos.

Para repetir los probes desde el mismo directorio backend:

```sh
TS_NODE_SKIP_PROJECT=true \
TS_NODE_COMPILER_OPTIONS='{"module":"CommonJS","moduleResolution":"Node","ignoreDeprecations":"6.0","experimentalDecorators":true,"emitDecoratorMetadata":true,"target":"ES2022"}' \
node -r ./node_modules/ts-node/register/transpile-only \
  /Users/abner/Documents/development/sacdia/docs/reviews/investidura-autorizacion-review-evidence/probes.cjs
```

## Pendientes adicionales antes de integrar

- Corregir R1–R4 y añadir sus regresiones; no declarar fase 0B completamente cerrada mientras falten sus garantías de concurrencia.
- Resolver lint del código nuevo/modificado sin mezclar reformateos ajenos; separar explícitamente deuda previa.
- Generar/verificar el cliente Prisma con el modelo nuevo y probar la migración en PostgreSQL aislado. El fallback por ausencia del delegate no demuestra que la configuración funcione y no sustituye la preparación de despliegue.
- Documentar los nuevos errores de edad y sus condiciones en la referencia API/integración. No crear endpoints nuevos no elimina esta obligación: cambió el contrato de errores de los existentes.
- Conservar la vía vieja hasta implementar la nueva y cumplir el inventario/aprobación de expedientes heredados. Un inventario por sí solo no hace desplegable el plan completo.

**Siguiente paso recomendado:** devolver este informe al implementador para corregir el slice y repetir las comprobaciones antes de continuar con las demás fases.
