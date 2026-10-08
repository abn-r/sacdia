# Prompt — X-1 residual (H1–H5)

> Copiar desde «Contexto» hasta el final y entregarlo al agente implementador.

## Contexto

Trabajás en `/Users/abner/Documents/development/sacdia`, rama `development` de `sacdia-backend`, sobre `113d8ba` más los cambios sin commit. La revisión independiente del 2026-10-07 (vigesimoquinta, en `docs/reviews/investidura-autorizacion-independent-review.md`) dejó **X-1 NO CERRADO** y X-2, X-3 y X-4 cerrados con observaciones. Leé esa sección y los probes `docs/reviews/investidura-autorizacion-review-evidence/x1x4-legacy-submit-race-probe.cjs` y `x1x4-resolution-guard-probe.cjs`, junto con sus `.log`.

## Restricciones

- No desplegar, no commitear, no aplicar migraciones en Neon ni tocar producción. No ejecutar builds.
- Se permite: Jest focal, `tsc --noEmit -p tsconfig.build.json`, ESLint de los archivos tocados y PostgreSQL aislado de loopback (base terminada en `_test`).
- No modificar el informe independiente ni los probes existentes.
- No reabrir cierres previos: P3-1, P4, P5, P6, P7, W1, X-2, X-3 y X-4 tienen que seguir pasando.
- **TDD obligatorio:** corré y registrá la prueba roja **antes** de corregir. En la entrega anterior no se hizo, y H1 pasó justo por ese hueco. Para cada hallazgo, el informe incluye el comando, la salida roja y después la salida verde.

## H1 (Alta) — La vía anterior sobrescribe un INVESTIDO de la vía nueva

**Hoy:**
- `InvestitureService.submitForValidation` valida `IN_PROGRESS` fuera de la transacción (`investiture.service.ts` ~L186-228) y dentro hace `tx.enrollments.update` incondicional (~L250).
- `ValidationService.submitForReview` para clase hace lo mismo: valida en `validation.service.ts:58` y escribe en `:66`.
- `reject` (~L414/431), `validateEnrollment` y `reviewClass` siguen el mismo patrón.

**Escenario:** la resolución nueva confirma `INVESTIDO` entre la lectura y la escritura del submit. El `PENDING` ya no existe, así que la comprobación pasa y el submit deja el enrollment en `SUBMITTED_FOR_VALIDATION` con `locked_for_validation=true`. Para entonces `class.completed` ya salió, y la cadena vieja puede volver a investir y emitir otro evento.

**Corrección:** en **cada** escritura de la vía anterior que cambie `investiture_status` o `locked_for_validation`, el estado de origen se condiciona dentro de la transacción que ya toma el candado: `updateMany` con el estado esperado y verificación de `count`, o relectura bajo candado. Aplica a submit, sus alias, club-approve, coordinator-approve, field-approve, reject, validate, las operaciones en bloque, `expire-overdue`/`expireEnrollment` y la validación de clase (submit y review). Si el estado no coincide:
- no se escribe historial, no se emite evento y no se envía notificación;
- la respuesta es un 409 explícito (reutilizá `INVESTITURE_CONCURRENT_UPDATE` o justificá un código nuevo);
- en bloque, solo ese ítem va a `failed`.

**Aceptación:**
- PostgreSQL aislado, ambos órdenes, para: resolución nueva contra `submitForValidation`, contra `submitForReview` de clase y contra `reject` sobre un `FIELD_APPROVED`+`PENDING` heredado. Resultado esperado en todos: un solo `INVESTIDO`, `locked_for_validation=false`, un solo `class.completed` y ningún historial de la vía anterior escrito después.
- Una prueba de unidad que verifique la clave y el orden del candado en una ruta de la vía anterior.
- Reemplazá `invests once from FIELD_APPROVED when that confirm races the old invest` por una prueba que falle con el código anterior, o explicá en el informe por qué la actual discrimina.

## H2 (Baja) — Un desajuste en la resolución anula todo el POST

**Hoy:** si el `updateMany` de la resolución no coincide para una persona, el 409 revierte la resolución entera y las demás personas quedan `PENDING`. Eso contradice IA-03.

**Corrección:** esa persona queda retirada o bloqueada con un `resolution_code` que describa la causa real, sin escribir el enrollment ni emitir evento. El resto de la resolución se confirma. El código no debe decir `LEGACY_PIPELINE_ACTIVE` si el estado actual es `INVESTIDO` escrito por otra vía; en ese caso corresponde `ALREADY_INVESTED`.

**Aceptación:** prueba de unidad con dos personas donde una no coincide: la otra queda `INVESTIDO` con su evento.

## H3 (Media, bloquea despliegue) — ADMIN_PANEL_URL obligatorio con el interruptor global

**Hoy:** `EMAIL_ENABLED` gobierna todo el correo, incluida la autenticación, así que exigir `ADMIN_PANEL_URL` bajo ese interruptor puede impedir el arranque del backend en staging y producción. Y si la variable se define, los correos de investidura enlazan a una ruta que todavía no existe.

**Corrección:**
1. Agregar un interruptor propio, por ejemplo `INVESTITURE_EMAIL_ENABLED`, apagado por defecto.
2. `ADMIN_PANEL_URL` pasa a ser obligatorio solo cuando ese interruptor está encendido.
3. `EMAIL_ENABLED=true` sin `ADMIN_PANEL_URL` debe arrancar.
4. Con el interruptor apagado no se envían correos de presentación ni recordatorios de investidura. Definí y documentá qué pasa con las intenciones mientras está apagado. Al encenderlo **no** debe salir un lote acumulado de correos viejos: o no se crean intenciones, o se marcan `skipped` con su causa. La bandeja de resultados de la app no depende de este interruptor.
5. Actualizar `.env.example`, `docs/runbooks/resend-setup.md` y `render.yaml` si corresponde, indicando que el interruptor se enciende solo cuando exista `/investiture-requests/[requestId]` en el panel.

**Aceptación:**
- Pruebas de `env.validation`: `EMAIL_ENABLED=true` sin URL y con el interruptor apagado es válido; con el interruptor encendido y sin URL, falla.
- Prueba de que con el interruptor apagado no se envía nada y, al encenderlo, no sale backlog.

## H4 (Baja) — Sin URL, los recordatorios abortan

**Hoy:** `requestUrl` lanza dentro de `dueReminders` (rules ~L449/473), lo que aborta los recordatorios de todos los Campos y hace que el cron (`investiture-reminder.cron.ts:40`) se salte `deliverPending`.

**Corrección:** con la corrección de H3 este camino no debería alcanzarse. Aun así, un error de configuración o de un Campo no debe abortar a los demás Campos ni impedir `deliverPending`. Registrá el error de forma observable.

**Aceptación:** prueba con dos Campos, uno con fallo: el otro recibe su recordatorio y `deliverPending` corre.

## H5 (Baja) — La guarda de enlace relativo es parcial

**Hoy:** `assertNoRelativeInvestitureLink` evalúa solo la primera coincidencia y acepta un enlace relativo si antes aparece cualquier `https://`.

**Corrección:** que evalúe todas las apariciones de `/investiture-requests/` y exija que cada una tenga origen absoluto.

**Aceptación:** pruebas con HTML que mezcle un enlace absoluto y uno relativo, en ambos órdenes.

## Fuera de esta entrega

- La conciliación de certificados (candados y respeto del `PENDING`): va en la entrega siguiente.
- Las pantallas y la fase 8.

## Entrega esperada

Agregá a `docs/reviews/investidura-autorizacion-implementation-report.md` una sección «X-1 residual (H1–H5)» con:

1. Por hallazgo: archivo y línea, la salida roja previa, la salida verde y la decisión tomada.
2. Una tabla de pruebas con suite, cantidad y salida (unidad, PostgreSQL aislado, `tsc`, ESLint).
3. Los cambios de contrato y de configuración, sincronizados en `docs/api/` y en el runbook.
4. Los límites de la evidencia.
5. La confirmación de que los cierres previos siguen pasando.

No des X-1 ni H1–H5 por cerrados: quedan pendientes de revisión independiente.
