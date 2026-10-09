# Informe de implementación — investidura por autorización

Estado para revisión independiente. Este informe no declara el trabajo aprobado.

## A. Estado y alcance

| Capa | Estado |
| --- | --- |
| Implementación | **PARCIAL** |
| Verificación | **PARCIAL** |
| Preparación para despliegue | **BLOQUEADO** |

Fundamento: quedaron en código la fase 0B (edad histórica de certificados de clase), la fase 1 de backend (porcentaje del Campo), la ventana del Campo, la asignación de pastores del distrito, el backend de marcar, quitar y cambiar fecha, y el backend de autorizar o rechazar. La fase 2 sigue parcial: W1 está cerrado en revisión independiente y no hay pantalla. La fase 3 quedó cerrada en la octava revisión solo en el alcance de cupos y asignaciones. La undécima revisión verificó el backend de la fase 4 en ese alcance; la pantalla de la app sigue pendiente. La decimoquinta revisión cerró P5-2 y mantuvo cerrados P5-1, P5-3 y el mock de ventana. El backend de la fase 5 queda verificado en ese alcance y no incluye la pantalla del panel. La fase 6 tiene en el árbol el correo de presentación, las notificaciones de resultado y los recordatorios por rol y zona horaria. La decimosexta revisión no la aprobó. La vigésima revisión dejó cerrado el retiro parcial posterior al fallo y señaló que el alcance del intento salía de una segunda lectura. Cuerpo, destino y alcance quedan en la misma instantánea. La vigesimoprimera revisión cerró P6-3 y aceptó el backend de la fase 6 para continuar con la fase 7, no para desplegar. La revisión 24 aceptó el backend de la fase 7 para continuar, no para desplegar. La preparación de la fase 8 documenta el inventario y el tratamiento de la vía anterior. El 2026-10-07 se completó ese inventario y se separaron las dos vías en el árbol. Esa separación no apaga la vía anterior. No se tocó producción. La vigesimoquinta revisión cerró X-2, X-3 y X-4 con observaciones y dejó X-1 abierto. H1 a H5 están en el árbol, en «X-1 residual (H1–H5)», y no están cerrados. P6-1, P6-2, P6-4 y P6-5 siguen cerrados. P5-1, P5-2 y P5-3 siguen cerrados. El pipeline anterior sigue aceptando transiciones. Sin eso el plan no está completo. No hay despliegue.

No se ejecutaron builds. No hay commits, push ni migraciones aplicadas a producción.

### Fases

| Fase | Estado |
| --- | --- |
| 0 Contratos | Pendiente como documento. Las rutas de solicitud están en la fase 4 y no están aprobadas. |
| 0B Edad histórica | Implementada en backend. Alta y aprobación institucionales leen edad y año dentro de su `$transaction`. La aprobación espera el bloqueo de la persona en PostgreSQL aislado. Esa prueba libera el bloqueo sin cambiar el nacimiento; el cambio de nacimiento durante la espera está cubierto en unidad. |
| 1 Porcentaje | Implementada en backend. Sin pantalla. El HTTP 400 de un porcentaje mal formado no trae `CLASS_THRESHOLD_PERCENT_INVALID`; ese código queda en el servicio. |
| 2 Ventana | Parcial. W1 cerrado en revisión independiente. Sin pantalla. El pipeline anterior no consulta esta ventana. Las rutas nuevas de solicitud sí leen el rango. |
| 3 Pastores | Cerrada en la octava revisión independiente del 2026-10-01, solo en cupos y asignaciones. Sin pantalla y sin ruta de autorización. El pipeline anterior no consulta estas asignaciones. |
| 4 Marcar en la app | Backend verificado en la undécima revisión para P4-1 a P4-4. La fase completa no está terminada: no hay pantalla en la app. No certifica UI, autenticación real ni la aplicación de la migración. |
| 5 Autorizar en el panel | P5-1, P5-2, P5-3 y el mock de ventana cerrados en la decimoquinta revisión. Backend verificado en ese alcance. Sin pantalla del panel. |
| 6 Correos y recordatorios | Backend aceptado en el alcance revisado para continuar con la fase 7, no para desplegar. La vigesimoprimera revisión cerró P6-3: cuerpo, destino y alcance salen de la misma instantánea. P6-1, P6-2, P6-4, P6-5 y P5 siguen cerrados. Sin commit y sin pantalla. |
| 7 Historial, anuario y fin de año | Backend aceptado en el alcance revisado para continuar, no para desplegar. La revisión 24 cerró P7-1, P7-2 y P7-3. Sin commit y sin pantalla. |
| 8 Apagar la vía vieja | Preparación documentada. El inventario incluye la validación de clase, la conciliación de certificados y la pantalla `/dashboard/clubs/validations`. Ninguna ruta se apagó. No se consultó ni modificó producción. El pipeline club → coordinación → campo sigue activo, salvo cuando el enrollment ya tiene una persona `PENDING` en la solicitud nueva. |
| 9 Documentación | Parcial: certificados, porcentaje, ventana, pastores del distrito, la solicitud, la resolución, los avisos de la fase 6, el cierre anual, el historial, el anuario y el inventario de la vía anterior. La fase 8 no está ejecutada. |

### Desviaciones

- IA-23, aprobada el 2026-10-01: sin intersección de octubre–diciembre y sin configuración explícita válida, la ventana permanece cerrada. W1 quedó cerrado en revisión independiente. La fase 2 sigue parcial.
- El asignado debe tener el rol global `pastor`. El plan dice «pastor asignado» y hoy ese rol no trae distrito; la asignación no convierte a cualquier usuario en pastor.
- Bajar el cupo por debajo de los pastores activos de algún distrito se rechaza y no borra filas. Quitar una asignación la deja inactiva y libera el cupo.
- P3-1: cambiar el cupo y dar de alta o reactivar toman, al inicio de la transacción, `pg_advisory_xact_lock(hashtextextended('investiture-pastor-quota', 0))` antes de leer ocupación o cupo. También cuando no hay fila. El candado va por `$executeRaw`: Prisma no deserializa el `void` de esa función con `$queryRaw`. Quitar una asignación no toma ese candado. La octava revisión cerró esta corrección en ese alcance.
- IA-06, en este corte: quien ya está `INVESTIDO` en esa persona y clase no entra, aunque el `INVESTIDO` esté en otro enrollment y sea `HISTORICAL_CERTIFICATE`. El pendiente anterior de esa persona y clase pasa a `REMOVED` con `resolution_code` `ALREADY_INVESTED`. No se usa el texto largo del rechazo del sistema ni `CLOSED_YEAR`. `enrollUser` solo rechaza el caso de Guía Mayor investida y la clase destino también investida. `validateDisplayOrderProgression` no mira `investiture_status`. La comprobación de persona y clase sigue siendo obligatoria.
- Las altas, las bajas y el cambio de fecha de la solicitud toman `pg_advisory_xact_lock(hashtextextended('investiture-authorization-user:' || user_id, 0))` antes de releer. El cambio de fecha no escribe si, ya con el candado, alguno de los seleccionados dejó de estar `PENDING`.
- Corrección P4-1 a P4-3, cerrada en la décima revisión: la duración separa el año de la solicitud del año de inicio del enrollment y aplica mínima y máxima sin reescribir el enrollment. La clase cruzada se presenta en la sección del mismo club cuyo tipo es el de la clase, con la membresía en otra sección de ese club. El progreso, la evidencia, el envío y la revisión de ese enrollment toman el mismo candado que presentar, dentro de la transacción que escribe.
- Vía residual de P4-4, en el árbol y sin aprobación: bajo el candado de sección y año, agregar a una cabecera explícita se rechaza con `INVESTITURE_REQUEST_STALE` si otra cabecera de esa sección y año ya tiene pendientes. No se mueven personas. Si esa cabecera vacía es la única, se puede volver a usar.
- Quien tiene rol de unión y de Campo asigna en los distritos de su unión. En la ventana, el rol de unión no amplía la edición.
- La aprobación masiva de un lote (`POST .../approve` del lote) ya rechazaba decidir el lote entero (`CERTIFICATE_IMPORT_ITEM_DECISION_REQUIRED`). La edad se revalida en cada `approveItem` / `approveItemInTransaction`. No se añadió una aprobación masiva nueva.
- Alta y aprobación institucionales leen el nacimiento después de resolver el año, dentro de la transacción que toma `FOR UPDATE`, y persisten el año leído en ese cliente. El cliente global y el transaccional se distinguen en la prueba de alta.

### Bloqueantes

1. Despliegue del cambio de vía: el inventario está en `docs/features/validacion-investiduras.md` y no está aprobado. No se asume que producción está vacía. No se retiraron rutas. Un expediente con `locked_for_validation` después del apagado solo tiene una propuesta, no una decisión.
2. La migración `20260930120000_local_field_class_thresholds` está creada y no aplicada. Sin ella, el cliente Prisma generado que ya conozca el modelo fallará al leer el porcentaje; el código actual hace fallback a 80 si el delegate no existe.
3. `prisma generate` se ejecutó el 2026-09-30 contra `prisma/schema.prisma` (cliente 7.9.1). La migración no se aplicó a producción ni a Neon. En la base aislada de loopback, el SQL de `20260930120000_local_field_class_thresholds` se aplicó dentro de una transacción revertida después de que el esquema completo ya había creado la tabla. El fallback a 80 si falta el delegate sigue en el código y no sustituye esa migración en un entorno real.

## X-1 a X-4

Fecha: 2026-10-07. Estas correcciones están en el árbol y no están cerradas. Siguen pendientes de revisión independiente. No apagan la vía anterior, no crean la pantalla del panel y no despliegan.

No quedó una corrida roja separada. Las pruebas nuevas se escribieron junto con la corrección. La primera ejecución de `investiture-authorization-requests.service.spec.ts` falló un caso ya existente de clase cruzada: el certificado histórico de Guía Mayor usaba el mismo `class_id` 7 que el enrollment operativo, y la comprobación nueva de persona y clase lo rechazó. El arreglo fue dar a ese certificado `class_id` 30. Eso no es una corrida roja del código anterior.

### X-1. Las dos vías sobre el mismo enrollment

Presentar y agregar rechazan el enrollment si `locked_for_validation` es true o si el estado es `SUBMITTED_FOR_VALIDATION`, `CLUB_APPROVED`, `COORDINATOR_APPROVED`, `FIELD_APPROVED` o `APPROVED`. El código es 409 `INVESTITURE_REQUEST_LEGACY_PIPELINE_ACTIVE`. La comprobación corre después del candado del enrollment, en `acceptEnrollment` (`investiture-authorization-requests.service.ts`, alrededor de la línea 1193).

La resolución vuelve a leer dentro de la transacción. Si hay otro `INVESTIDO` de la misma persona y clase, o si el expediente anterior todavía no está en `FIELD_APPROVED`, la persona queda `REMOVED` con `ALREADY_INVESTED` o `LEGACY_PIPELINE_ACTIVE`. No se escribe el enrollment, no se emite `class.completed` y `person_text`, `rejection_reason` y `system_reason` siguen null. `legacyBlocksResolution` está alrededor de la línea 1305 y devuelve false cuando el estado es `FIELD_APPROVED`.

Decisión de esta entrega, revisable: un `FIELD_APPROVED` que ya tiene una persona `PENDING` lo escribe solo la resolución, aunque `locked_for_validation` sea true. El `updateMany` exige el estado releído. Presentar y agregar siguen rechazando ese `FIELD_APPROVED`, así que no se crean solapes nuevos. Si la resolución retirara también el `FIELD_APPROVED` y `invest` rechazara el `PENDING`, los dos órdenes de la carrera terminarían sin ningún `INVESTIDO`. El 409 de toda la resolución cuando ese `updateMany` no coincidía quedó sustituido en «X-1 residual (H1–H5)».

La vía anterior toma solo el candado `investiture-authorization-enrollment:` dentro de la transacción que escribe, en `pendingInvestitureAuthorization` (`investiture-request-lock.ts`, alrededor de la línea 137). Si hay un `PENDING`, la ruta individual responde 409 `INVESTITURE_REQUEST_PROGRESS_LOCKED`. Entran submit, los alias `submit-for-validation`, `validate` e `investiture`, club-approve, coordinator-approve, field-approve, invest, reject, y la validación de clase. En `bulk-approve` y `bulk-reject` solo el ítem con `PENDING` va a `failed` con ese código; el resto continúa. `expire-overdue` omite ese enrollment y no aborta el lote. El honor no cambia.

`invest` escribe con `updateMany` condicionado a `FIELD_APPROVED`. Si la resolución ya dejó `INVESTIDO`, el conteo es 0, responde `INVESTITURE_CONCURRENT_UPDATE` (código eliminado en la fase 8) y no emite. Si `invest` toma el candado primero y ve el `PENDING`, no escribe y no emite; después escribe la resolución.

### X-2. IA-06 por persona y clase

`findSameClassInvested` busca cualquier `INVESTIDO` de esa `user_id` y `class_id`, sin filtrar `record_kind` (`investiture-authorization-requests.service.ts`, alrededor de la línea 1315). Presentar y agregar responden 409 `INVESTITURE_REQUEST_ALREADY_INVESTED`. La resolución deja `REMOVED` con `ALREADY_INVESTED`, sin evento y sin el texto de falta de requisitos.

Antes de corregirlo se revisó el alta. `enrollUser` lanza `CLASS_ALREADY_INVESTED` solo en la rama de Aventureros o Conquistadores cuando ya hay Guía Mayor investida y también un `INVESTIDO` de la clase destino (`classes.service.ts`, alrededor de la línea 736). `validateDisplayOrderProgression` no consulta `investiture_status` (`classes.service.ts`, alrededor de la línea 1766). Un certificado histórico `INVESTIDO` y un enrollment operativo de la misma clase pueden coexistir. La comprobación de persona y clase no estaba cubierta y queda obligatoria.

### X-3. Enlace del correo

`requestUrl` lanza `InvestiturePanelUrlMissingError` si la base no empieza por `http://` o `https://` (`investiture-communications.rules.ts`, alrededor de la línea 65). `assertNoRelativeInvestitureLink` hace lo mismo si aparece `/investiture-requests/` sin ese origen. `email.processor.ts` lo comprueba antes de los dos `provider.send`, el reintento y el render nuevo (alrededor de las líneas 213 y 230). El acople de `ADMIN_PANEL_URL` a `EMAIL_ENABLED` quedó sustituido en «X-1 residual (H1–H5)». `.env.example` dice que no se active el correo de investidura hasta que exista la ruta. No se creó la pantalla. El contrato de que el panel debe vivir en `/investiture-requests/[requestId]` está en `docs/api/FRONTEND-INTEGRATION-GUIDE.md`. No hay que activar esos correos en un entorno hasta que esa ruta exista.

### X-4. Inventario de fase 8

Solo documentación. No se apagó nada y no se modificó la conciliación de certificados. `docs/features/validacion-investiduras.md`, sección «Preparación de fase 8», ahora incluye:

- `POST /validation/submit` y `POST /validation/class/:id/review` para `entity_type` class, con archivo, línea, escritura y consumidor.
- Que `APPROVED` cuenta como completada en el puntaje, el club, la asignación de consejero y el resumen de validación.
- `substituteGuideMajor` y `reconcileOperationalEnrollment`, que pueden dejar `INVESTIDO` sin mirar un `PENDING`. Su corrección de código queda para la entrega siguiente.
- La pantalla `/dashboard/clubs/validations`, pestaña de clase, y `reviewValidation`.
- Una propuesta, sin decisión: después del apagado, una operación explícita soltaría `locked_for_validation` solo si el enrollment no está `INVESTIDO` y no tiene una persona `PENDING`. El estado no cambiaría. Hasta aprobarla, la fila sigue bloqueada.

### Pruebas

| Suite | Resultado |
| --- | --- |
| `src/investiture-requests/investiture-authorization-requests.service.spec.ts` | 63 passed |
| `src/investiture/investiture.service.spec.ts` | 61 passed |
| `src/validation/validation.service.spec.ts` | 5 passed |
| `src/investiture-requests/investiture-communications.rules.spec.ts` | 16 passed |
| `src/investiture-requests/investiture-communications.delivery.spec.ts` | 11 passed |
| `src/config/env.validation.spec.ts` | 35 passed |
| `test/investiture-authorization-requests-postgres.e2e-spec.ts` | 40 passed, incluidos los dos órdenes `keeps one INVESTIDO` |
| `tsc --noEmit -p tsconfig.build.json` | salida 0 |
| ESLint de los archivos tocados | salida 0 |

Las 191 pruebas unitarias de esas seis suites salieron en una sola ejecución, success true. El archivo PostgreSQL aislado pasó las 40, incluidos `resolve-first` e `invest-first`: un `INVESTIDO`, un `class.completed` y cero `PENDING`.

### Contrato HTTP

No hay migración nueva. No se aplicó nada a Neon ni a producción.

| Código | HTTP | Dónde |
| --- | --- | --- |
| `INVESTITURE_REQUEST_LEGACY_PIPELINE_ACTIVE` | 409 | Presentar y agregar. El desajuste del `updateMany` en la resolución ya no usa este 409; ver «X-1 residual (H1–H5)». Textos en es, en, fr y pt-BR. |
| `INVESTITURE_REQUEST_ALREADY_INVESTED` | 409 | Presentar y agregar cuando otro enrollment de la misma persona y clase ya está `INVESTIDO`. |
| `INVESTITURE_REQUEST_PROGRESS_LOCKED` | 409 | Rutas individuales de la vía anterior y la validación de clase, si hay un `PENDING`. En bloque, el ítem va a `failed` con ese código. |
| `INVESTITURE_CONCURRENT_UPDATE` (código eliminado en la fase 8) | 409 | `invest` si el enrollment ya no está `FIELD_APPROVED` al escribir. |

La resolución que retira por `ALREADY_INVESTED` o `LEGACY_PIPELINE_ACTIVE` no responde esos códigos: deja `REMOVED` y `resolution_code`. El honor no usa `INVESTITURE_REQUEST_PROGRESS_LOCKED`.

### Límites

No hubo HTTP real, autenticación real, pantalla ni build. La prueba PostgreSQL usa la base aislada de loopback cuyo nombre termina en `_test`. No sustituye una migración aplicada. No se consultó producción. Esa entrega dejó X-1 a X-4 sin cerrar. La vigesimoquinta revisión cerró después X-2, X-3 y X-4. X-1 sigue abierto.

### Cierres que siguen

P3-1, P4-1 a P4-4, P5-1 a P5-3, P6-1 a P6-5, P7-1 a P7-3 y W1 no se reabren. Las suites de solicitud, investidura, validación, reglas, entrega de correos y entorno, y las 40 de PostgreSQL aislado, pasaron en esa corrida. La fase 2 sigue parcial. Faltan las pantallas. La fase 8 no está ejecutada. El despliegue sigue bloqueado. No hay commit.

## X-1 residual (H1–H5)

Fecha: 2026-10-07. Estas correcciones están en el árbol y no están cerradas. Siguen pendientes de revisión independiente. No apagan la vía anterior, no crean la pantalla del panel y no despliegan. X-1 sigue abierto. X-2, X-3 y X-4 quedaron cerrados en la vigesimoquinta revisión, con observaciones, y esta entrega no los reabre.

La corrida roja se ejecutó antes de cambiar el código de producción. El comando de unidad, en `sacdia-backend`, fue:

`node node_modules/jest/bin/jest.js --no-coverage --testPathPatterns 'investiture.service.spec|validation.service.spec|env.validation.spec|investiture-communications.rules.spec|investiture-authorization-requests.service.spec|investiture-communications.delivery.spec|investiture-reminder.cron.spec' --testNamePattern 'locks the enrollment before the conditional submit write|does not submit when the enrollment left|does not reject when FIELD_APPROVED|does not submit a class when the status changed|keeps the other person invested|allows global email without|requires the admin panel URL only|keeps the other field reminder|does not send investiture mail|still delivers pending|does not build a relative link' --forceExit`

Salida roja: exit 1. 7 suites failed, 10 failed, 190 skipped, 1 passed, 201 total. El único pase fue `requires the admin panel URL only when investiture email is on`, y pasó por la razón equivocada: `EMAIL_ENABLED=true` ya exigía `ADMIN_PANEL_URL`, y el mensaje también decía que `INVESTITURE_EMAIL_ENABLED` no estaba permitido.

Fallos de esa corrida:

- `allows global email without the admin panel URL while investiture email is off`: `"ADMIN_PANEL_URL" is required. "INVESTITURE_EMAIL_ENABLED" is not allowed`.
- `does not submit a class when the status changed under the lock`: la promesa se resolvió. El submit de clase seguía en `enrollments.update`.
- `keeps the other field reminder when one field fails`: `TypeError: Cannot read properties of null (reading 'filter')` en `includableRequests`.
- `does not build a relative link when ADMIN_PANEL_URL is missing`: el HTML con un enlace absoluto y después uno relativo no lanzó.
- `still delivers pending reminders when one field fails`: `deliverPending` recibió 0 llamadas. El cron registró `Fallo el cron de recordatorios de investidura: field down`.
- `keeps the other person invested when one enrollment no longer matches`: `AppConflictException` `INVESTITURE_REQUEST_LEGACY_PIPELINE_ACTIVE` en el `updateMany` de la resolución.
- `locks the enrollment before the conditional submit write`: el candado apareció y la escritura condicional no (`writeAt` -1).
- `does not submit when the enrollment left IN_PROGRESS under the lock`: se resolvió `SUBMITTED_FOR_VALIDATION`.
- `does not reject when FIELD_APPROVED changed under the lock`: se resolvió en lugar de `INVESTITURE_CONCURRENT_UPDATE` (código eliminado en la fase 8).
- `does not send investiture mail while the switch is off and does not flush it later`: `dispatchReminders` devolvió 3.

La corrida roja de PostgreSQL aislado fue:

`node node_modules/jest/bin/jest.js --config ./test/jest-e2e.json --no-coverage --forceExit --testPathPatterns investiture-authorization-requests-postgres --testNamePattern 'keeps one INVESTIDO when'`

Salida roja: exit 1. 3 failed, 38 skipped, 5 passed, 46 total. Fallaron `resolve-first` / `class-submit` (el enrollment quedó `SUBMITTED_FOR_VALIDATION`), y `reject` en los dos órdenes (quedó `INVESTIDO` con `locked_for_validation` true). Pasaron `submit` en los dos órdenes, `legacy-first` / `class-submit` y las dos carreras viejas de `invest`. Ese pase de `submit` no demuestra que el código anterior fuera seguro: el probe independiente `x1x4-legacy-submit-race-probe.log` sí reprodujo el sobrescrito de `submitForValidation`. La escritura condicional se aplicó igual.

### H1. La vía anterior sobrescribe un INVESTIDO

`submitForValidation` (`investiture.service.ts`, línea 250), `reject` (línea 433), `validateEnrollment` (líneas 1236 y 1261) y la validación de clase (`validation.service.ts`, líneas 68 y 201) escriben con `updateMany` condicionado al estado leído, dentro de la transacción que ya tomó `investiture-authorization-enrollment:`. Si `count` no es 1, responden 409 `INVESTITURE_CONCURRENT_UPDATE` (código eliminado en la fase 8) y no escriben historial, evento ni notificación. El helper está en `claimEnrollmentStatus` (línea 2272) y `claimClassStatus` (línea 467).

En bloque, `bulk-approve` invest (línea 1494), el approve que no es invest (línea 1550) y `bulk-reject` (línea 1762) mandan solo ese ítem a `failed` con el mismo código. El historial se escribe solo para las filas con `count` 1. `expireEnrollment` (línea 2323) usa el mismo 409 si la fila ya no está en un estado vencible. `expire-overdue` ya limitaba el historial a las filas que sí quedaron `EXPIRED`; no se le agregó una lista `failed` porque esa ruta no la tiene. `transitionApprovalState` y `markInvestido` ya condicionaban la escritura y se dejaron así.

La resolución que sí inviste ahora pone `locked_for_validation` en false (`investiture-authorization-requests.service.ts`, línea 783). Sin eso, el rechazo que no llega a escribir dejaba el bloqueo que la prueba había puesto en el `FIELD_APPROVED`.

`invests once from FIELD_APPROVED when that confirm races the old invest` no discrimina H1. El mock deja el enrollment en `FIELD_APPROVED` y no lo cambia entre la lectura y la escritura, así que el `update` incondicional anterior y el `updateMany` nuevo terminan igual. Se conservó como cobertura del único escritor de ese estado. La discriminación está en las seis carreras de PostgreSQL, que con el código anterior dejaron el sobrescrito de la clase y el bloqueo del rechazo.

Salida verde del mismo filtro de unidad, después de la corrección: exit 0. 7 suites passed, 12 passed, 189 skipped, 201 total. La salida verde de PostgreSQL con el mismo filtro: exit 0. 1 suite passed, 8 passed, 38 skipped, 46 total. Los seis casos nuevos quedan en un `INVESTIDO`, `locked_for_validation` false, un `class.completed` y cero filas de historial o de `validation_logs` de la vía anterior.

### H2. Un desajuste no anula el POST

Si el `updateMany` del enrollment no coincide, la persona sigue `PENDING` hasta ese momento y pasa a `REMOVED` (`investiture-authorization-requests.service.ts`, alrededor de la línea 794). No se escribe el enrollment y no se emite el evento. `resolution_code` es `ALREADY_INVESTED` si la relectura está en `INVESTIDO`, `LEGACY_PIPELINE_ACTIVE` si el expediente sigue en la vía anterior, y `CONCURRENT_STATUS` en otro desajuste. No se usa el texto de falta de requisitos. El resto de la llamada se confirma. La persona se marca `INVESTED` solo después de que el enrollment coincidió.

La salida roja es el `AppConflictException` de arriba. La salida verde está en las 12 pruebas de unidad de ese filtro y, dentro de ellas, `keeps the other person invested when one enrollment no longer matches`.

### H3. Interruptor propio del correo de investidura

`INVESTITURE_EMAIL_ENABLED` sale en `false` (`env.validation.ts`, líneas 133–135). `ADMIN_PANEL_URL` es obligatorio solo cuando ese valor es `true` (líneas 94–100). `EMAIL_ENABLED=true` sin esa URL arranca.

Con el interruptor apagado no se llama al proveedor. La intención de presentación se inserta y enseguida queda `skipped` con `last_error` `investiture_email_disabled` (`investiture-communications.service.ts`, línea 127). Los recordatorios no se crean (línea 228). `dispatchReminders` y `deliverPending` marcan además las filas abiertas de `PRESENTATION` y `REMINDER` como `skipped` con esa causa (`skipOpenInvestitureMail`, línea 532). Al encender el interruptor, esas filas no se reenvían. La bandeja de resultados no consulta el interruptor.

`.env.example`, `docs/runbooks/resend-setup.md` y `render.yaml` dejan el interruptor en false y dicen que se enciende solo cuando exista `/investiture-requests/[requestId]`. Staging y producción del runbook siguen con `EMAIL_ENABLED=true` y el interruptor de investidura apagado.

La salida roja es el rechazo de `ADMIN_PANEL_URL` y la clave desconocida, y los 3 envíos de `dispatchReminders`. La salida verde del filtro incluye `allows global email without the admin panel URL while investiture email is off`, `requires the admin panel URL only when investiture email is on` y `does not send investiture mail while the switch is off and does not flush it later`. La suite completa de entorno quedó en 37 passed.

### H4. Un Campo no aborta a los demás

`dueReminders` atrapa el error de cada Campo y llama `onFieldError` (`investiture-communications.rules.ts`, líneas 408 y 500). El servicio lo registra con el id del Campo (línea 240). El cron atrapa el fallo de `dispatchReminders` y llama `deliverPending` de todos modos (`investiture-reminder.cron.ts`, línea 47).

La salida roja es el `TypeError` de `people.filter` y las 0 llamadas a `deliverPending`. La salida verde es `keeps the other field reminder when one field fails` (el error queda en el Campo 20 y los borradores son del Campo 10) y `still delivers pending reminders when one field fails`.

### H5. Cada enlace de investidura exige origen absoluto

`assertNoRelativeInvestitureLink` recorre todas las apariciones de `/investiture-requests/` y exige que el texto inmediato anterior sea un origen `http` o `https` (`investiture-communications.rules.ts`, línea 80). Un `https://` anterior en el mismo HTML no alcanza.

La salida roja es el HTML absoluto-luego-relativo que no lanzaba. La salida verde está en `does not build a relative link when ADMIN_PANEL_URL is missing`, que ahora lanza en los dos órdenes.

### Pruebas de esta corrida

| Suite | Cantidad | Salida |
| --- | --- | --- |
| `src/investiture-requests/investiture-authorization-requests.service.spec.ts` | 64 | passed |
| `src/investiture/investiture.service.spec.ts` | 64 | passed |
| `src/validation/validation.service.spec.ts` | 6 | passed |
| `src/investiture-requests/investiture-communications.rules.spec.ts` | 17 | passed |
| `src/investiture-requests/investiture-communications.delivery.spec.ts` | 12 | passed |
| `src/investiture-requests/investiture-reminder.cron.spec.ts` | 1 | passed |
| `src/config/env.validation.spec.ts` | 37 | passed |
| `src/investiture-requests/investiture-mail-redis.spec.ts` | 14 | passed |
| `test/investiture-authorization-requests-postgres.e2e-spec.ts` | 46 | passed, incluidos los seis órdenes nuevos y los dos de `invest` |
| `tsc --noEmit -p tsconfig.build.json` | — | salida 0 |
| ESLint de los archivos tocados | — | salida 0 |

Las 201 de las siete suites unitarias salieron juntas, success true. El filtro rojo, repetido después de la corrección, quedó en 12 passed. PostgreSQL aislado pasó las 46. Redis aislado de loopback pasó las 14 de correo. No se imprimió la URL de la base.

### Contrato y configuración

No hay migración nueva. No se aplicó nada a Neon ni a producción.

| Cambio | Dónde |
| --- | --- |
| 409 `INVESTITURE_CONCURRENT_UPDATE` (código eliminado en la fase 8) si la vía anterior escribe y el estado de origen ya no coincide. En bloque, solo ese ítem va a `failed`. | `docs/api/ENDPOINTS-LIVE-REFERENCE.md` y `docs/api/FRONTEND-INTEGRATION-GUIDE.md` |
| Desajuste de la resolución: esa persona queda `REMOVED` con `ALREADY_INVESTED`, `LEGACY_PIPELINE_ACTIVE` o `CONCURRENT_STATUS`. El resto se confirma. El `INVESTIDO` deja `locked_for_validation` en false. | Los mismos dos documentos |
| `INVESTITURE_EMAIL_ENABLED` apagado por defecto. `ADMIN_PANEL_URL` solo si está encendido. Intenciones de presentación y recordatorios `skipped` con `investiture_email_disabled`, sin reenvío al encender. La bandeja no depende del interruptor. | `.env.example`, `render.yaml`, `docs/runbooks/resend-setup.md` y los dos documentos de API |

### Límites

No hubo HTTP real, autenticación real, pantalla ni build. La prueba PostgreSQL usa la base aislada de loopback cuyo nombre termina en `_test` y no sustituye una migración. No se consultó producción. No se modificó el informe independiente ni los probes `x1x4-*`. `invests once from FIELD_APPROVED when that confirm races the old invest` no es la prueba que habría fallado con el código anterior. El pase rojo de `submit` en PostgreSQL tampoco lo es; el fallo que reprodujo el probe fue `class-submit` en `resolve-first`, y el del rechazo fue el bloqueo que la resolución no soltaba. H1 a H5 y X-1 no están cerrados.

### Cierres que siguen

P3-1, P4, P5, P6, P7, W1, X-2, X-3 y X-4 no se reabren. Las suites de arriba, incluidas las 46 de PostgreSQL aislado y las 14 de Redis aislado, pasaron después de la corrección. La fase 2 sigue parcial. Faltan las pantallas. La fase 8 no está ejecutada. El pipeline anterior sigue activo. El despliegue sigue bloqueado. No hay commit.

## C-1 certificados frente a solicitud viva

Fecha: 2026-10-07. Esta entrega implementa IA-57 a IA-60 en el árbol de `sacdia-backend`, sobre `113d8ba` más los cambios sin commit. No está cerrada: queda pendiente de revisión independiente. No implementa R26. La revisión 26 cerró X-1 con observaciones y dejó R26 abierto; este texto no reabre esos cierres ni los da por rehechos.

No hay migración. `investiture_authorization_people.resolution_code` ya es `String? @db.VarChar(80)` en `docs/database/schema.prisma`. `HISTORICAL_CERTIFICATE_APPLIED` es un valor de esa columna, no un enum. No se aplicó nada en Neon ni en producción.

Los roles que aprueban no cambian: `admin-certificate-bulk-imports.controller.ts` líneas 34-40, y la aprobación institucional sigue en `assertSuperAdmin`.

### IA-57

Mismo año eclesiástico, inscripción operativa y persona `PENDING`: la aprobación rechaza con HTTP 400 `CERTIFICATE_IMPORT_AUTHORIZATION_PENDING`. No escribe enrollment, historial, evento ni conciliación, y el ítem no queda aprobado. El mismo aviso sale al marcar listo, al enviar y al reenviar. La autoridad es la aprobación.

| Pieza | Archivo y línea |
| --- | --- |
| Código y mensajes es, en, fr, pt-BR | `src/common/errors/error-codes.ts:224`; `src/i18n/es/errors.json:631`; `en:631`; `fr:626`; `pt-BR:626` |
| Rechazo temprano | `class-certificate-live-authorization.ts:197` `rejectSameYearLiveAuthorization` |
| Rechazo dentro de la transacción | `class-certificate-live-authorization.ts:250` |
| Aprobación de lote | `certificate-bulk-imports-application.service.ts:313` |
| Envío | `certificate-bulk-imports.service.ts:479` |
| Marcar listo y edición que baja a `NEEDS_REVIEW` | `certificate-bulk-imports.service.ts:752` y `:789` |
| Alta y aprobación institucional | `institutional-certificate-requests.service.ts:149` y `:295` |

Salida roja, antes de la corrección, con `--testNamePattern C-1`: 4 suites failed, 2 skipped, 1 passed; 10 failed, 95 skipped, 3 passed, 108 total. El caso del mismo año con `PENDING` resolvió la promesa en vez de rechazar. Marcar listo, enviar y reenviar también resolvieron. La aprobación institucional del mismo año siguió hasta `decide` y falló con `Cannot read properties of undefined (reading 'count')`.

Salida verde de ese filtro, después de la corrección: 5 suites passed, 2 skipped; 13 passed, 95 skipped. El caso sin `PENDING` y el reintento después de `REMOVED` ya pasaban en rojo y siguen pasando.

### IA-58

Sin un `PENDING` de esa persona y clase, el mismo año sigue `reconcileOperationalEnrollment`. Un rechazo o un retiro dejan de coincidir con el filtro `status: 'PENDING'`, así que un certificado posterior del mismo año se acepta.

El cierre anual no necesita código nuevo. `investiture-year-close.ts:90` pasa esas personas a `CLOSED_YEAR` con `resolution_code` `CLOSED_YEAR` y no escribe `enrollments`. Si el Campo rechazó el certificado, la clase de ese año sigue sin investirse. La caracterización está en `investiture-year-close.spec.ts:62`: `enrollments.update` y `enrollments.updateMany` no se llaman. Esa aserción ya era verde; no hubo una roja propia de este caso.

### IA-59

Certificado de un año anterior, comparado por `start_date` del año eclesiástico, con un `PENDING` operativo de esa persona y clase: se acredita y, en la misma transacción, la persona pasa a `REMOVED`. `resolution_code` es `HISTORICAL_CERTIFICATE_APPLIED`. `system_reason` es «Investidura aplicada por certificado de un año anterior». `rejection_reason` queda null. Cubre `substituteGuideMajor` y la variante AV/CQ, que crea la fila histórica y no convierte la operativa del año en curso.

No usa «Falta de requisitos para investidura». No llama `recordResults`. No emite `class.completed` desde la solicitud. El historial `INVESTIDO` del certificado, cuando la acreditación lo escribía, se conserva. La persona sale de los recordatorios porque solo entra quien sigue `PENDING`. Sigue en la lectura de la sección (`investiture-authorization-requests.service.ts:366`), en la del autorizador (`:393`) y en la persona (`resolution_code` en `:1724`).

Decisión de bandeja: no se envía correo ni aviso nuevo. El motivo queda en la lectura.

Salida roja: Guía Mayor de un año anterior acreditaba y `investiture_authorization_people.updateMany` tenía 0 llamadas. La variante AV/CQ igual, 0 llamadas. La primera corrida de Guía Mayor falló antes por edad de la persona de prueba; se corrigió el cumpleaños del fixture y la roja limpia fue la ausencia del retiro.

Salida verde: las dos variantes dejan `REMOVED`, `HISTORICAL_CERTIFICATE_APPLIED` y el texto indicado. La aprobación institucional de un año anterior deja la solicitud `APPROVED`, retira a la persona y no crea enrollment.

En PostgreSQL, si gana la resolución, queda un `INVESTIDO`, la persona `INVESTED` y un `class.completed`. Si gana el certificado anterior, queda un `INVESTIDO`, la persona `REMOVED` con ese código y cero `class.completed`: la solicitud no emite el evento y el certificado tampoco. Nunca quedan dos eventos ni un `PENDING` huérfano. «Un solo `class.completed` en los dos órdenes» no se cumple junto con IA-59; el orden que acredita el certificado deja el evento en cero.

### IA-60

Las dos comprobaciones corren dentro de `approveItem` / `approveItemInTransaction` y de la aprobación institucional, bajo los candados que ya usan presentar y resolver.

Orden, y por qué no hay ciclo:

1. `FOR SHARE` de `users`, `classes` y `ecclesiastical_years` (`class-certificate-historical-age.ts:152`, `:156`, `:163`). La aprobación no modifica esas filas. Presentar y resolver no las bloquean con `FOR UPDATE`. `FOR SHARE` impide que otra transacción les cambie cumpleaños, edad mínima o límites del año, y no toma el exclusivo que pelearía con un escritor de esas tablas.
2. Candado advisory `investiture-authorization-user:`, una sola vez (`class-certificate-live-authorization.ts:234`).
3. Lectura de enrollments y de personas `PENDING`.
4. Candados `investiture-authorization-enrollment:` en orden ascendente (`:217`).
5. Relectura y, según el año, rechazo IA-57 o retiro IA-59, y después la acreditación que ya existía.

La aprobación del certificado no toma los candados de año, sección ni calendario. Presentar los toma antes del de usuario. Tomarlos aquí después del enrollment invertiría ese orden. La vía anterior solo bloquea el enrollment, así que usuario y después enrollment no cicla con ella.

`FOR SHARE` sustituye a `FOR UPDATE` en esas tres lecturas. La revisión de las fases 0B a 3 pedía evaluarlo. Se adopta porque esta transacción observa esas filas y no las escribe.

Salida roja del `FOR SHARE`: el SQL seguía con `FOR UPDATE` en usuarios, clases y años. La prueba de orden recibió `CERTIFICATE_IMPORT_ENROLLMENT_MISMATCH` en vez del código nuevo. Verde: el SQL contiene `FOR SHARE` y no `FOR UPDATE`; el orden observado es usuario, enrollment 5, enrollment 20, y después el rechazo, sin `updateMany`.

### PostgreSQL aislado

Base de loopback cuyo nombre termina en `_test`. No se imprimió la URL. No es Neon.

| Prueba | Qué fija |
| --- | --- |
| `C-1 shows the earlier-certificate reason on the request read` | La lectura del autorizador y la de la sección muestran el texto. Una fila histórica `INVESTIDO`. Cero `class.completed`. |
| `C-1 does not leave a certificate INVESTIDO beside a PENDING when present-first` y `approve-first` | Nunca quedan juntos un `INVESTIDO` por certificado y un `PENDING`. El mensaje no contiene `deadlock`. |
| `C-1 keeps one INVESTIDO and at most one class.completed when resolve-first` y `approve-first` | Un solo `INVESTIDO`. Si gana la resolución, un `class.completed` y persona `INVESTED`. Si gana el certificado, cero `class.completed` y persona `REMOVED`. Sin `PENDING` huérfano. El mensaje no contiene `deadlock`. |

El filtro C-1 de esa suite pasó 5 y saltó 46. La suite completa pasó 51 de 51. Se repitió después de Prettier, con `tsc` en el mismo comando: otra vez 51 de 51, salida 0.

### Conteo

| Comando | Resultado |
| --- | --- |
| Filtro unitario C-1, rojo | 10 failed, 3 passed, 95 skipped, 108 total. Salida 1. |
| Filtro unitario C-1, verde | 13 passed, 95 skipped. 5 suites passed, 2 skipped. |
| Suites unitarias tocadas, después de la corrección | 7 suites, 154 passed. |
| `pnpm run test`, suite unitaria completa, sola | 2 suites failed, 6 skipped, 363 passed, 365 de 371. Tests: 3 failed, 34 skipped, 4535 passed, 4572. Salida 1. Tiempo 58.8 s. |
| PostgreSQL aislado, suite completa | 51 passed, 51 total, salida 0. La primera tardó 134 s. La repetición después de Prettier también pasó 51, en 8.7 s, con la base ya preparada. |
| `tsc --noEmit -p tsconfig.build.json` | La primera salida fue 2: `CertificateImportApplicationTransaction` no entraba en `LiveAuthorizationStore` por `$executeRaw`. Se alineó la llamada con `tx as never`, igual que el aviso temprano. La repetición, también después de Prettier, salió 0. |
| ESLint `--no-fix` sobre los archivos tocados, specs incluidas | Primera pasada: 229 errores, 224 de Prettier y 5 `no-useless-assignment` en variables de una carrera previa del e2e. Se formateó y se quitó la asignación inicial que nadie leía. La pasada `--no-fix` siguiente salió 0. |

Los 3 fallos de `pnpm run test` no son de IA-57 a IA-60:

- `resend.provider.spec.ts`, dos pruebas de remitente y Reply-To. Es el residuo R26-1. No se corrige aquí.
- `club-assignment-effectivity.inventory.spec.ts`: predicados sin clasificar en `investiture-authorization-requests.service.ts:489` (`yearbook`) y `investiture-communications.loader.ts:84`. C-1 no agrega consultas a `club_role_assignments`. No se reclasifica el inventario en esta entrega.

Una corrida anterior de `pnpm run test`, en paralelo con PostgreSQL y `tsc`, sumó 43 fallos. Al repetirla sola, los de PDF, OCR, QR y Better Auth no se reprodujeron: eran tiempo de espera de esa máquina ocupada.

### Contrato

| Código | Contrato |
| --- | --- |
| HTTP 400 `CERTIFICATE_IMPORT_AUTHORIZATION_PENDING` | Misma persona y clase, año del certificado igual al de la inscripción operativa `PENDING`. Mensaje: la autorización tiene prioridad. No acredita. |
| `resolution_code` `HISTORICAL_CERTIFICATE_APPLIED` | Certificado de un año anterior. Persona `REMOVED`. `system_reason`: «Investidura aplicada por certificado de un año anterior». Visible para quien autoriza y para la directiva. Sin correo. |

Quedó en `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, `docs/api/FRONTEND-INTEGRATION-GUIDE.md` y `docs/features/validacion-investiduras.md`. El plan IA-57 a IA-60 no se reescribió como cierre.

### Límites

No hubo build, despliegue, commit ni migración aplicada. No hubo HTTP real ni autenticación real. Las pantallas y la fase 8 quedan fuera. La prueba PostgreSQL no sustituye una migración: `prepareAnnualCycleDatabase` reconstruye con `prisma migrate diff` y no aplica índices únicos parciales que solo viven en SQL. No se modificó el informe independiente ni los probes anteriores. La aprobación institucional no crea enrollment: «se acredita» ahí significa dejar la solicitud `APPROVED` y retirar a la persona. C-1 no está cerrado.

### Cierres que siguen

P3-1, P4, P5, P6, P7, W1, X-1, X-2, X-3, X-4 y R26 no se reabren. La suite PostgreSQL de investidura, que cubre esos cierres en el alcance ya aceptado para continuar, pasó 51 de 51 otra vez después del formato. La fase 2 sigue parcial. Faltan las pantallas. La fase 8 no está ejecutada. El pipeline anterior sigue activo. El despliegue sigue bloqueado. No hay commit.

Los números rojos de esta sección son los de la entrega anterior. R26-1 a R26-5 y el residuo C1-H1 a C1-H5 están en las dos secciones siguientes y siguen pendientes de revisión independiente.

## R26-1 a R26-5

Se aplicó `docs/reviews/investidura-autorizacion-prompt-r26.md`. Nada de esto se da por cerrado.

### R26-1 — segundo argumento de Resend

Archivo: `sacdia-backend/src/common/email/providers/resend.provider.spec.ts`. `ResendEmailProvider.send` pasa el payload y, como segundo argumento, la clave de idempotencia o `undefined`.

Salida roja: la revisión 27 y la suite unitaria anterior. Las dos pruebas de remitente y Reply-To esperaban un solo argumento y recibieron `(payload, undefined)`.

Salida verde: esas aserciones aceptan el segundo argumento `undefined`. La prueba `forwards the idempotency key to the Resend SDK` comprueba que la clave llega al SDK cuando está definida. En la suite unitaria final esa spec entra en las 4557 pruebas pasadas.

Decisión: alinear la spec con la firma real del proveedor. No se quitó el segundo argumento del SDK.

### R26-2 — lint de las specs

Salida roja: ESLint `--no-fix` sobre la lista de esta entrega salió 1, con 19 errores de Prettier en `auth.service.spec.ts`, `class-certificate-historical-age.spec.ts`, `club-assignment-effectivity.inventory.ts`, `investiture-communications.delivery.spec.ts`, `certificate-import-postgres.e2e-spec.ts` y `investiture-authorization-requests-postgres.e2e-spec.ts`.

Salida verde: Prettier sobre esos archivos y una pasada `--no-fix` posterior con salida 0. Quedaban 3 avisos de imports sin uso en `auth.service.spec.ts` (`BadRequestException`, `InternalServerErrorException`, `NotImplementedException`). Se quitaron. La spec de auth pasó 56 de 56. La pasada `--no-fix` que incluye ese archivo salió 0.

Decisión: formatear y quitar solo esos tres imports. No se usó `--fix` como comando de verificación.

### R26-3 — el procesador consulta el interruptor

Archivo: `sacdia-backend/src/common/email/email.processor.ts`, `investitureDeliveryOpen` en las líneas 150–158, llamado en 210, 227 y 268. La decisión está en `investiture-mail.gate.ts:4-8`: `investitureMailDeliveryEnabled()` exige `INVESTITURE_EMAIL_ENABLED === 'true'` y `EMAIL_ENABLED === 'true'`. Si está apagado, `skipDisabled` marca la fila `skipped` con `last_error` `investiture_email_disabled` y el proveedor no recibe el envío. La misma consulta se repite inmediatamente antes de cada `provider.send`.

Salida roja: `R26-3 does not send a queued investiture job after the switch is turned off`. Esperado `[]`. Recibido `["sent"]`.

Salida verde: esa prueba pasa dentro de la suite unitaria final (4557 passed, 0 failed).

Decisión: el procesador deja de lanzar por `EMAIL_ENABLED` en el camino de investidura y usa el interruptor combinado. `acknowledge` (`investiture-communications.service.ts:345`) incluye `skipped`, así un envío que ganó la carrera contra el salto termina en `sent`. El salto no pisa una fila ya `sent`. La bandeja de resultados no usa este interruptor.

### R26-4 — apagado real de presentación y recordatorio

Archivo: `investiture-communications.service.ts`, `deliverPending` líneas 261–267 y `skipOpenInvestitureMail` línea 550. El doble en memoria de la spec acepta `kind: { in: [...] }`.

Salida roja: `C1 R26-4 skips open presentation and reminder rows and leaves results alone`. Esperada longitud 8. Recibida longitud 0.

Salida verde: la misma prueba pasa en la suite unitaria final. Ocho filas de presentación y recordatorio en `pending`, `failed`, `queued` y `sending` quedan `skipped` con `investiture_email_disabled`. El resultado `pending` sigue `pending`. `deliverPending` retorna 0 y no recupera ese resultado.

Decisión: con el interruptor apagado, `deliverPending` y `dispatchReminders` saltan las filas abiertas y no siguen hacia el proveedor.

### R26-5 — validación cruzada de interruptores

Se eligió la opción b del prompt. No se agregó un rechazo de Joi al arranque. Un rechazo solo al boot no detiene un job que ya está `queued` o `failed`.

`investitureMailDeliveryEnabled()` trata como apagada cualquier combinación en la que falte uno de los dos valores `true`. Esas filas pasan a `skipped`. `deliverPending` no reintenta `skipped`, así que encender después el correo global no vacía un lote acumulado.

La primera prueba de R26-5 pasó por una razón vacía: el borrador incompleto caía en `skipDispatch` y no demostraba el lote. Se reemplazó por `R26-5 does not flush a queued investiture job when global email is turned on later`. Esa sustitución está escrita para fallar en el procesador anterior (enviaría, o lanzaría `email disabled`), pero no se ejecutó en rojo antes del cambio de compuerta. La evidencia verde es la suite unitaria final. `investiture-communications.delivery.spec.ts` enciende ambos interruptores en `beforeEach` y restaura ambos en `afterAll`.

### Orden de candados

El orden de esta entrega está en la sección «C-1 residual». R26 no cambia candados.

### Conteo de esta parte

Los comandos y conteos compartidos están al final de «C-1 residual». R26 entra en la misma suite unitaria de 0 fallos.

### Contrato y configuración

| Cambio | Dónde |
| --- | --- |
| La entrega exige los dos interruptores. Un job ya encolado se vuelve a consultar antes del proveedor. Una fila `skipped` no se reenvía al encender. La bandeja de resultados no depende de esos interruptores. | `sacdia-backend/.env.example` (comentario de `INVESTITURE_EMAIL_ENABLED`), `sacdia-backend/render.yaml`, `sacdia-backend/docs/runbooks/resend-setup.md` |
| El párrafo de correo de la referencia viva dice lo mismo. | `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, `docs/api/FRONTEND-INTEGRATION-GUIDE.md` (actualización 2026-10-07) |

No existe `docs/runbooks/resend-setup.md` en la raíz del workspace. El runbook actualizado es el de `sacdia-backend/docs/runbooks/resend-setup.md`.

No hay variable nueva. `INVESTITURE_EMAIL_ENABLED` sigue apagado por defecto. No hay cambio de esquema.

## C-1 residual (C1-H1 a C1-H5)

Pendiente de revisión independiente. No se reabren P3-1, P4, P5, P6, P7, W1, X-1 (H1–H5), X-2, X-3, X-4, IA-58, ni lo ya verificado de IA-59 e IA-60.

### C1-H1 — el año que decide es el de la solicitud

Archivo: `sacdia-backend/src/certificate-bulk-imports/class-certificate-live-authorization.ts`, `requestYearId` líneas 89–92, `sameYearPeople` línea 166 y `earlierPeople` línea 175. El año comparado es `investiture_authorization_requests.ecclesiastical_year_id` del `PENDING`, y solo si el enrollment vinculado sigue `OPERATIONAL`. El año de inicio del enrollment deja de decidir.

Salida roja, unidad, antes de la corrección:

- Certificado de 2026 con enrollment iniciado en 2025: `TypeError: Cannot read properties of undefined (reading 'enrollment_id')`. La aprobación seguía y el mock de `create` no devolvía fila.
- Certificado de 2025: se rechazaba con `CERTIFICATE_IMPORT_AUTHORIZATION_PENDING` porque se usaba el año de inicio.
- Guía Mayor con certificado de 2026: la promesa se resolvía.
- Control 2019: `updateMany` con 0 llamadas. El mock no incluía el año de inicio 2025; la comparación vieja no veía el año de la solicitud.
- Aviso al marcar listo: la promesa se resolvía.

Salida verde: las pruebas de unidad de esos cuatro casos y el aviso temprano pasan en la suite de 4557. En PostgreSQL, dentro de las 58 de `investiture-authorization-requests`:

- Certificado 2026: rechazo `CERTIFICATE_IMPORT_AUTHORIZATION_PENDING`. La persona sigue `PENDING`. Cero `INVESTIDO`.
- Certificado 2025: se acredita y la persona queda `REMOVED` / `HISTORICAL_CERTIFICATE_APPLIED`.
- Certificado 2019: histórico `INVESTIDO` y persona `REMOVED`.
- Guía Mayor 2026: rechazo. La inscripción operativa sigue `OPERATIONAL` e `IN_PROGRESS` en el año de inicio 2025.

Decisión: si el año del certificado es el de la solicitud, IA-57 rechaza. Si es anterior por `start_date` del año eclesiástico, IA-59 acredita y retira con el `system_reason` «Investidura aplicada por certificado de un año anterior» y `rejection_reason` nulo. Sin `PENDING`, el camino actual no cambia. La misma guarda cubre el aviso temprano, `substituteGuideMajor` y la aprobación institucional. En una clase de un año el año de inicio y el de la solicitud coinciden, así que el comportamiento previo se mantiene. Los fixtures de unidad que solo cargaban el año del enrollment ahora cargan también `request.ecclesiastical_year_id`.

### C1-H2 — orden de candados frente a `closeYear`

Salida roja: `docs/reviews/investidura-autorizacion-review-evidence/c1-deadlock-pglog.txt`, línea del `2026-10-07 12:39:25.881 CST`: `ERROR: deadlock detected`. La aprobación tomaba `FOR SHARE` de `ecclesiastical_years` y después esperaba el candado advisory de usuario. `closeYear` tomaba los candados advisory y después hacía `UPDATE` de esa fila.

Decisión: el candado advisory del año (`lockInvestitureAuthorizationYear`, prefijo `investiture-authorization-year:`) se toma en `assertClassCertificateHistoricalAge` (`class-certificate-historical-age.ts:165-174`) antes del `FOR SHARE` de usuario, clase y años, y antes del candado de usuario. La lectura preliminar de años por fecha no lleva `FOR SHARE`. Los `year_id` se ordenan ascendente. No se toman en este camino los candados de sección, calendario ni pastor. `$executeRaw` no está en la interfaz `HistoricalAgeDb`: Prisma no asigna esa firma (TS2345 en los tres llamadores). Se lee con un cast y se llama `lockInvestitureAuthorizationYear(db as never, yearId)`.

El candado de usuario sigue siendo incondicional, después del candado de año (`class-certificate-live-authorization.ts:236-241`). No se toma solo cuando la primera lectura ve un `PENDING`. Una presentación de un año posterior toma el candado de ese año posterior, no el del año del certificado. Una lectura «sin pendiente» bajo solo el candado del año del certificado no queda estable frente a IA-59.

Salida verde: `C1-H2` en la suite PostgreSQL de investidura, ambos órdenes (`close-first` y `approve-first`), dentro de las 58 pasadas. El certificado de la carrera es del mismo año (2026-06-01), sin ficha de conciliación. `pg_stat_database.deadlocks` de `current_database()` no sube. El error del cliente no contiene `deadlock`. En `close-first`, cero `RowShareLock` concedidos sobre `ecclesiastical_years` mientras ambos esperan. El cierre queda aplicado, el año inactivo, la persona `CLOSED_YEAR` y el enrollment no `INVESTIDO`. La aprobación termina en `CERTIFICATE_IMPORT_AUTHORIZATION_PENDING` (vio el `PENDING`, IA-57) o en `CERTIFICATE_IMPORT_ENROLLMENT_RECONCILIATION_REQUIRED` (el cierre ganó antes y ya no hay `PENDING`; IA-58 sin ficha). No se usó un certificado de 2019 para esa aserción de `RowShareLock`: el `FOR SHARE` de 2019 no choca con el `UPDATE` de 2026. No se usó ficha de conciliación del mismo año: producía `CERTIFICATE_IMPORT_ENROLLMENT_VERSION_CONFLICT` aunque las marcas de tiempo coincidieran.

#### Orden global

| Camino | Orden |
| --- | --- |
| Presentar y agregar (`writePeople`, línea 1134) | Advisory de año, calendario, sección, usuarios ordenados, enrollments ordenados. |
| Resolver (línea 599 lee personas; línea 605 toma candados) | Advisory de año, calendario, pastor si no autoriza el Campo, sección, usuarios, enrollments. |
| `closeYear` (`year-end.service.ts:176`, luego `investiture-year-close.ts`) | Advisory de año. `closePending` vuelve a tomar los años declarados ordenados, lee pendientes, toma los años descubiertos ordenados y, por grupo `año:sección` ordenado, sección, usuarios ordenados y enrollments ordenados. Después `UPDATE ecclesiastical_years` (`active: false`, línea 184). No escribe el enrollment de clase. |
| Barrido `year-cut` (`year-cut.service.ts:284`) | Primero `pg_advisory_xact_lock(clubId, year_id)`, otro espacio de dos enteros. Después `closeEndedInvestiture` llama a `closePending` con los años terminados ordenados. No actualiza `ecclesiastical_years`. `sweepEndedInvestiturePending` solo llama a `closePending`. |
| Guardar la ventana (`field-investiture-window-config.service.ts:101`) | Advisory de año, calendario, upsert de la ventana. Sin candado de usuario y sin `UPDATE` del año. |
| Retirar un pastor (`district-investiture-pastors.service.ts:205`) | Advisory de pastor y después `FOR UPDATE` de `districts`. Sin candado de año ni de usuario de investidura. |
| Vía anterior | Solo el advisory de enrollment (`classes.service.ts:83`, `lockPendingInvestitureProgress`). |
| Aprobación por ítem | Advisory de año, ordenado, dentro de la comprobación de edad. Después `FOR SHARE` de usuario, clase y años. Después advisory de usuario, advisories de enrollment ascendentes, relectura, IA-57 o IA-59, y la acreditación que ya existía. |
| Aprobación institucional | `FOR UPDATE` de `institutional_certificate_requests` (línea 276) y después el mismo orden de edad y guarda. No crea enrollment. |

`pg_advisory_xact_lock` del mismo texto es reentrante en la transacción. Por eso `closeYear` puede tomar el año y `closePending` volver a tomarlo.

### C1-H3 — carrera de `certificate-import` en 10/10

Archivo: `sacdia-backend/test/certificate-import-postgres.e2e-spec.ts`, `INSERT` de usuario del `seed()` con `birthday` `1990-01-01`.

Salida roja: la revisión 27. «keeps one historical enrollment when two approvals race» fallaba con `CERTIFICATE_IMPORT_BIRTHDAY_REQUIRED`. No se volvió a ejecutar en rojo en esta sesión antes de poner la fecha.

Salida verde: la suite `certificate-import-postgres` pasó 10 de 10, en 4.119 s, incluida esa carrera. La variable de la base de prueba se cargó dentro del proceso desde `.env.test.local` y no se imprimió.

Decisión: la fecha de nacimiento válida devuelve la prueba a la carrera de dos aprobaciones. No se relajó la aserción.

### C1-H4 — inventario de asignaciones de club

Archivo: `sacdia-backend/src/common/authorization/club-assignment-effectivity.inventory.ts`. La spec no se relajó. Totales: 145 hallazgos, 55 entradas de inventario, T08 55, T09 58, allowlist 32.

Salida roja, en este orden:

- `classes/class-requirement-eligibility.service.ts`: esperado `1/f0f7540f4594`, recibido `2/c91bbc988489`. Ya estaba vencido en `113d8ba`.
- `common/guards/permissions.guard.ts`: esperado `3/e8b370c41349`, recibido `3/2bd237ed53eb`.
- Dos digestos provisionales `000000000000` del anuario y del loader, reemplazados por los digestos reales antes de la pasada verde.

Salida verde: `club-assignment-effectivity.inventory.spec.ts` pasa dentro de las 4557.

| Consulta | Clasificación | Por qué |
| --- | --- | --- |
| Anuario, `investiture-authorization-requests.service.ts:490` | `historicalWhere\|allowlist\|1\|c1ad58990f7d` | `status` en `active`, `inactive` y `ended`. No otorga autoridad vigente. |
| Oficiales del aviso, `investiture-communications.loader.ts:84` | `effectiveWhere\|T09\|1\|75a40441727f` | `active: true` y `status: 'active'` para el aviso de resultado de esa sección y ese año. No usa `start`/`end`/`expires` ni `toPrismaWhere`. El inventario ya clasifica avisos como T09. |
| Elegibilidad, `class-requirement-eligibility.service.ts` | `effectiveWhere\|T08\|2\|c91bbc988489` | La segunda consulta, cerca de la línea 607, tiene la misma intención `active` + `status` activo. El conteo pasa de 1 a 2. La clase T08 no cambia. |
| `permissions.guard.ts` | `effectiveWhere\|T08\|3\|2bd237ed53eb` | El conteo sigue en 3. El digest cambia porque `status: { in: ['active','pending'] }` pasó a `in: allowedStatuses`. Se conserva T08: la clasificación anterior ya incluía `pending`. |
| `qr/qr.service.ts` | `effectiveWhere\|T08\|3\|fb413b5f37eb` | El conteo sigue en 3. Las consultas siguen en `active: true` para identidad y asistencia. El diff de git de ese archivo contra `113d8ba` está vacío: la línea base ya no coincidía con el código. |

### C1-H5 — lectura informativa determinista

Archivo: `investiture-authorization-requests.service.ts:366-376`. El `findFirst` informativo ahora lleva `orderBy: [{ request_id: 'asc' }, { person_id: 'asc' }]` y selecciona `person_id`.

Salida roja: esperado `11111111-1111-4111-8111-111111111111`, recibido `ffffffff-ffff-4fff-8fff-ffffffffffff`. El `findFirst` sin orden devolvía la fila insertada primero, que era la de mayor `request_id`.

Salida verde: la prueba de unidad `C1-H5 lists the informative request with the smallest request id` y la de PostgreSQL pasan. La sección ve la solicitud de menor `request_id`.

Decisión: ese orden es el criterio. El `findFirst` de `PENDING` no lleva `orderBy`: sigue habiendo una sola solicitud activa por sección y año.

### Conteo

| Comando | Resultado |
| --- | --- |
| Suite unitaria completa, sola, después del formato, del cast de `$executeRaw` y de quitar los imports sin uso | 6 suites skipped, 365 passed, 365 de 371. Tests: 34 skipped, 4557 passed, 4591. 0 failed. 37.479 s. Salida 0. |
| PostgreSQL `investiture-authorization-requests` | 58 passed, 58 total. 9.005 s. Salida 0. |
| PostgreSQL `district-investiture-pastors` | 7 passed, 7 total. 3.69 s. Salida 0. |
| PostgreSQL `certificate-import` | 10 passed, 10 total. 4.119 s. Salida 0. |
| `tsc --noEmit -p tsconfig.build.json` | La primera pasada salió 1: TS2345 en `certificate-bulk-imports-application.service.ts:271`, `certificate-bulk-imports.service.ts:804` e `institutional-certificate-requests.service.ts:144` y `:290`, porque `$executeRaw` de Prisma no entra en la firma de `HistoricalAgeDb`. Se quitó el campo de la interfaz y se lee con cast. La repetición salió 0. |
| ESLint `--no-fix` | Primera pasada de esta entrega: 19 errores de Prettier, salida 1. Después de Prettier y de quitar los tres imports sin uso, salida 0 sobre `class-certificate-live-authorization.ts`, `class-certificate-historical-age.ts` y su spec, las specs de aplicación, importación e institucional, `email.processor.ts`, `investiture-mail.gate.ts`, `resend.provider.spec.ts`, `investiture-communications.service.ts` y `investiture-communications.delivery.spec.ts`, el servicio y la spec de solicitudes, `club-assignment-effectivity.inventory.ts` y su spec, `auth.service.spec.ts`, y las dos specs e2e de PostgreSQL tocadas. |

El comando de la suite unitaria fue `node node_modules/jest/bin/jest.js --no-coverage --forceExit` desde `sacdia-backend`. `pnpm run test -- --no-coverage` no sirve: pnpm entrega `--` a Jest como ruta.

### Contrato

| Tema | Dónde |
| --- | --- |
| El año que decide es el de la solicitud. Orden de candados: advisory de año, `FOR SHARE`, usuario, enrollment. La lista de la sección, si no hay `PENDING`, devuelve la informativa de menor `request_id`. | `docs/api/ENDPOINTS-LIVE-REFERENCE.md` |
| Misma regla de año y de lista, y los dos interruptores de correo. | `docs/api/FRONTEND-INTEGRATION-GUIDE.md` |
| Filas «Año de la solicitud» y «Año anterior a la solicitud», más la frase del orden de candados. | `docs/features/validacion-investiduras.md` |

El texto de IA-57 a IA-60 en el plan no se reescribió. No hay migración nueva. No hay código HTTP nuevo.

### Límites

No hubo build, despliegue, commit ni migración en Neon. No hubo HTTP real ni autenticación real. El log del servidor de PostgreSQL de la carrera nueva no se capturó: la ausencia de interbloqueo se midió con `pg_stat_database.deadlocks` de la base actual, con cero `RowShareLock` en el orden cierre-primero, y con la ausencia de `deadlock` en el error del cliente. El probe y `c1-deadlock-pglog.txt` no se modificaron. `prepareAnnualCycleDatabase` sigue reconstruyendo con `prisma migrate diff` y no aplica índices únicos parciales que solo viven en SQL. La aprobación institucional sigue sin crear enrollment. Las pantallas y la fase 8 quedan fuera.

### Cierres que siguen

P3-1, P4, P5, P6, P7, W1, X-1 (H1–H5), X-2, X-3, X-4, IA-58 y lo ya verificado de IA-59 e IA-60 no se reabren. La suite PostgreSQL de investidura, que los cubre en el alcance ya aceptado para continuar, pasó 58 de 58 después de estas correcciones. La fase 2 sigue parcial. Faltan las pantallas. La fase 8 no está ejecutada. El pipeline anterior sigue activo. El despliegue sigue bloqueado. No hay commit. C-1, C1-H1 a C1-H5 y R26-1 a R26-5 quedan pendientes de revisión independiente.

## C1R-N1 a C1R-N5

Pendiente de revisión independiente. Esta sección no cierra C1R-N1 a C1R-N5 ni reabre P3-1, P4, P5, P6, P7, W1, X-1, X-2 a X-4, R26-1, R26-3, R26-4 ni C1-H1 a C1-H5. La revisión 28 ya había dejado C-1 cerrado con observaciones. No se modificó el informe independiente ni los probes.

La prueba roja, antes de cada corrección, fue:

`node node_modules/jest/bin/jest.js --no-coverage --forceExit --testPathPatterns 'class-certificate-historical-age.spec|investiture-year-close.spec|certificate-bulk-imports-application.service.spec|investiture-communications.delivery.spec' -t 'C1R-N'`

Salida 1. 6 pruebas fallaron.

### C1R-N1 — Interbloqueo entre envíos de lotes

Archivo: `sacdia-backend/src/certificate-bulk-imports/certificate-bulk-imports.service.ts` (envío alrededor de 476–496, reenvío alrededor de 549–560). El candado de año vive en `class-certificate-historical-age.ts` (`lockInvestitureYearsAscending`, 172–184; el ítem lo omite con `skipYearAdvisory` en 196). El cierre anual está en `investiture-year-close.ts` 64–69.

Salida roja: `investiture-year-close.spec.ts` resolvió la promesa con `1` en lugar de rechazar. `class-certificate-historical-age.spec.ts` esperaba que el orden no contuviera `advisory` y recibió `["advisory"]`.

Salida verde: esas dos pruebas pasan dentro de la suite unitaria de abajo. En PostgreSQL, `C1R-N1 submits crossed certificate years` (órdenes `a-then-b` y `b-then-a`) y `C1R-N1 closes two ended years against a batch submit` (órdenes `submit-first` y `close-first`) terminan los dos lados y no escriben `deadlock detected`. El cliente no ve `40P01`.

Decisión: antes del bucle se resuelven todos los años del lote y se toman en orden ascendente de `year_id`. Dentro del bucle la edad histórica no vuelve a adquirirlos. Lo mismo en el reenvío de un ítem, en el envío y la aprobación institucional, y en la aprobación de ítem. Esa aprobación también mete en el mismo conjunto los años de las solicitudes `PENDING` de la persona y la clase, porque C1R-N2 tiene que tomar el año de la solicitud dentro de ese orden. `approveBatch` (`admin-certificate-bulk-imports.service.ts` 99–105) no recorre ítems y lanza `CERTIFICATE_IMPORT_ITEM_DECISION_REQUIRED`: no toma candados de año, así que no puede ciclar. `closePendingInvestitureAuthorizations` toma primero los años declarados, ya ordenados. Si después descubre un año menor que el máximo declarado y fuera de ese conjunto, lanza `INVESTITURE_YEAR_LOCK_ORDER` y no lo toma. Un extra mayor se toma al final, todavía en orden ascendente. Los llamadores de producción pasan el mismo conjunto en el filtro y en la lista de candados. El barrido de `year-cut` (`sweepEndedInvestiturePending`, 254–270, y `closeEndedInvestiture`, 450–453) ya entrega los años terminados ordenados. `cutClub` toma antes el advisory de dos enteros del club, que es otro espacio de claves.

### C1R-N2 — Certificado de un año posterior a la solicitud

Archivo: `class-certificate-live-authorization.ts` (`requestYearEnded` 255–258, `closeEndedRequests` 261–308, llamada en 377). La aprobación de ítem pasa `heldYearIds` en `certificate-bulk-imports-application.service.ts` 278–296. La institucional, en `institutional-certificate-requests.service.ts` 301–318, después del `FOR UPDATE` de la solicitud.

Salida roja: las dos pruebas de `certificate-bulk-imports-application.service.spec.ts` esperaban `updateMany` con `CLOSED_YEAR` y recibieron 0 llamadas.

Salida verde: esas pruebas pasan. En PostgreSQL, una solicitud de 2025 inactiva con certificado de 2026 deja a la persona `CLOSED_YEAR`, acredita el certificado y no deja `PENDING`. En clase normal crea un `HISTORICAL_CERTIFICATE` `INVESTIDO` del año del certificado y no escribe `class.completed`. En Guía Mayor actualiza la única inscripción operativa a `HISTORICAL_CERTIFICATE` `INVESTIDO` de ese año. `system_reason` y `rejection_reason` quedan null.

Decisión: un `PENDING` cuyo año ya terminó (inactivo, o el día local de `America/Mexico_City` posterior a `end_date`) se cierra con `status` y `resolution_code` `CLOSED_YEAR` en la misma transacción, sin texto de falta de requisitos y sin evento. El candado de ese año ya está en el conjunto ascendente. No se llama a `closePendingInvestitureAuthorizations` desde la aprobación: esa función toma la sección antes que el usuario, y la aprobación ya tiene el usuario. Después, IA-57 e IA-59 ven solo lo que sigue vivo. La guarda no carga la zona del campo: usa `America/Mexico_City`, la misma zona por defecto de la solicitud. Si el llamador pasa `heldYearIds` y el año de la solicitud no está ahí, no se cierra. La prueba institucional de mismo año, que usaba 2008 inactivo, quedó con el año todavía abierto (`active` y `end_date` en 2099) para que IA-57 siga rechazando `CERTIFICATE_IMPORT_AUTHORIZATION_PENDING`. Un año ya terminado no es ese caso.

### C1R-N3 — La bandeja de resultados con el interruptor apagado

Archivo: `investiture-communications.service.ts` `deliverPending` 261–298.

Salida roja: `deliverPending` devolvió 0. El log decía que la entrega se omitía porque `INVESTITURE_EMAIL_ENABLED` estaba apagado.

Salida verde: `C1R-N3 recovers a failed result into the inbox while investiture email is off` pasa. Con los dos interruptores apagados, un `RESULT` fallido entra a la bandeja una vez (la segunda llamada devuelve 0), las filas quedan `sent` y el arreglo de correos enviados queda vacío.

Decisión: con el interruptor apagado se omiten y se marcan `PRESENTATION` y `REMINDER`. El bucle sigue. Solo se materializan y se recuperan filas `RESULT` cuyo `payload.channel` es `result`. Un `RESULT` de carga vacía sigue `pending`, como en R26-4. Con el interruptor encendido el camino anterior no cambia.

### C1R-N4 — Fila con intento previo y el interruptor apagado

Archivo: `email.processor.ts` `investitureDeliveryOpen` 150–163. `processInvestiture` lee `providerAttempt` antes de la compuerta (215–218).

Salida roja: el estado esperado era `uncertain` y el recibido fue `skipped`.

Salida verde: `C1R-N4 leaves a provider attempt uncertain when the switch is off` pasa. La fila queda `uncertain` y el proveedor no se llama.

Decisión: si el envío está apagado y ya hay un intento cuyo resultado se desconoce, la fila queda `uncertain` con el mismo texto que P6-2. `skipped` queda para cuando el proveedor nunca recibió el envío. El reintento de un intento previo pasa `providerAlreadyAttempted: true`. El registro del intento en la misma invocación, antes de llamar al proveedor, pasa `false`.

### C1R-N5 — Evidencia de interbloqueo

Archivo: `test/investiture-authorization-requests-postgres.e2e-spec.ts`. Se quitó la lectura de `pg_stat_database.deadlocks` y la comparación del delta inmediato en la carrera de C1-H2. Las carreras de candados usan `assertNoClientDeadlock`: el error del cliente no puede traer `40P01` ni la palabra `deadlock`. El tramo nuevo del log del servidor no puede traer `deadlock detected`. Si el archivo de log no se puede abrir, la prueba falla.

### Orden global de candados

| Camino | Orden |
| --- | --- |
| Presentar y agregar | Año, calendario, sección, usuarios ordenados, enrollments ordenados. |
| Resolver | Año, calendario, pastor si no es el autorizador de campo, sección, usuarios, enrollments. |
| `closeYear` | Advisory del año. `closePending` vuelve a tomar los años declarados en orden ascendente, lee pendientes y solo toma años extra mayores. Si un extra es menor que el máximo declarado, lanza `INVESTITURE_YEAR_LOCK_ORDER`. Por grupo `año:sección`: sección, usuarios, enrollments, `PENDING` a `CLOSED_YEAR`. Después `ecclesiastical_years.active = false`. No escribe enrollments de clase. |
| `year-cut` `cutClub` | Advisory de dos enteros del club. Luego `closeEndedInvestiture` con los años terminados ordenados. No actualiza `ecclesiastical_years`. |
| Barrido `sweepEndedInvestiturePending` | `closePending` con los `year_id` terminados, ya ordenados. |
| Guardar la ventana | Año, calendario, upsert. Sin candado de usuario y sin actualizar la fila del año. |
| Quitar pastor | Advisory de pastor y después `FOR UPDATE` de distritos. Sin candado de año ni de usuario de investidura. |
| Vía anterior de clases | Solo el advisory de enrollment. |
| Enviar y reenviar un lote | Años de los ítems en orden ascendente, antes del bucle. El bucle no toma candados de año. Marcar listo un solo ítem sigue tomando el suyo dentro de la validación. |
| Aprobar un ítem | Años del certificado y años de solicitud `PENDING`, ascendentes. Edad histórica sin volver a tomarlos. Usuario. Enrollments ascendentes. Relectura. `CLOSED_YEAR` de lo ya terminado. IA-57 o IA-59. Acreditación. |
| Envío institucional | Años de la fecha, ascendentes. Edad histórica sin volver a tomarlos. Rechazo de mismo año. |
| Aprobación institucional | `FOR UPDATE` de `institutional_certificate_requests`. Luego el mismo conjunto de años que la aprobación de ítem. No crea enrollment. |
| `approveBatch` | No toma candados de año. Rechaza el lote entero y pide decisión por ítem. |

### Conteos

| Comando | Resultado |
| --- | --- |
| `node node_modules/jest/bin/jest.js --no-coverage --forceExit` desde `sacdia-backend`, sola | 6 suites skipped, 365 passed, 365 de 371. Tests: 34 skipped, 4570 passed, 4604. 0 failed. 36.655 s. Salida 0. |
| PostgreSQL `investiture-authorization-requests` | 64 passed, 64 total. 8.661 s. Salida 0. |
| PostgreSQL `district-investiture-pastors` | 7 passed, 7 total. 3.381 s. Salida 0. |
| PostgreSQL `certificate-import` | 10 passed, 10 total. 3.837 s. Salida 0. |
| `node node_modules/typescript/bin/tsc --noEmit -p tsconfig.build.json` | Salida 0. |
| ESLint `--no-fix` sobre los 81 archivos TS de `git status` en `sacdia-backend` | Salida 0. |

Las tres suites de PostgreSQL corrieron una después de otra. Comparten la base aislada y cada una reconstruye `public`.

### Log del servidor PostgreSQL

Archivo `/opt/homebrew/var/log/postgresql@18.log`. `logging_collector` está apagado, el destino es stderr y `log_min_messages` es `warning`. Durante las cuatro carreras de C1R-N1 el archivo no creció:

```text
C1R-N1 a-then-b postgres-log bytes=0 deadlock_lines=0
C1R-N1 b-then-a postgres-log bytes=0 deadlock_lines=0
C1R-N1 submit-first postgres-log bytes=0 deadlock_lines=0
C1R-N1 close-first postgres-log bytes=0 deadlock_lines=0
```

Un `RAISE WARNING` de control, fuera de esas carreras, sí se escribió en ese archivo:

```text
2026-10-07 14:53:44.210 CST [42862] WARNING:  c1r-log-probe-marker
```

`deadlock detected` es un `ERROR`. Con 0 bytes agregados, el servidor no lo escribió. Los dos envíos, y el envío contra el cierre de dos años, terminaron `fulfilled`. No hubo error de cliente que pudiera traer `40P01`.

### Límites

No hubo build, despliegue, commit ni migración en Neon. No hubo HTTP real ni autenticación real. El día local del cierre al aprobar usa `America/Mexico_City`, no la zona del campo. `INVESTITURE_YEAR_LOCK_ORDER` es un error interno de respaldo: los llamadores de producción no deberían verlo. `approveBatch` no participa del orden porque no toma candados de año. La primera corrida de la suite unitaria murió por `SIGSEGV` en `annual-folders-get-folder-by-enrollment.service.spec.ts`, un archivo que esta entrega no toca. La repetición, sola, es el conteo de arriba. No se editaron `certificate-import-pdf*` ni `certificate-import-files.service.spec.ts`. ESLint los incluyó porque `git status` los lista. Los probes y el informe independiente no se modificaron. `prepareAnnualCycleDatabase` sigue reconstruyendo con `prisma migrate diff`.

### Cierres que siguen

P3-1, P4, P5, P6, P7, W1, X-1, X-2 a X-4, R26-1, R26-3, R26-4 y C1-H1 a C1-H5 no se reabren. La suite de PostgreSQL de investidura, que los cubre en el alcance ya aceptado para continuar, pasó 64 de 64, incluidas las carreras anteriores ahora medidas con el log del servidor y sin el delta de `pg_stat_database.deadlocks`. Pastores 7 de 7. Importación de certificados 10 de 10. La fase 2 sigue parcial. Faltan las pantallas. La fase 8 no está ejecutada. El pipeline anterior sigue activo. El despliegue sigue bloqueado. No hay commit. C1R-N1 a C1R-N5 quedan pendientes de revisión independiente.

### Contrato

| Tema | Dónde |
| --- | --- |
| Un `PENDING` cuyo año ya terminó se cierra al aprobar un certificado posterior. El conjunto de candados de año incluye las fechas y las solicitudes vivas, en orden ascendente. | `docs/api/ENDPOINTS-LIVE-REFERENCE.md` |
| El mismo cierre y el error de autorización de mismo año. | `docs/api/FRONTEND-INTEGRATION-GUIDE.md` |
| Fila «Año de la solicitud ya terminado y certificado posterior». | `docs/features/validacion-investiduras.md` |

El texto de IA-57 a IA-60 en el plan no se reescribió. No hay migración nueva. No hay código HTTP nuevo. El interruptor de correo no cambió de nombre.

## IA-61 e IA-62

Fecha: 2026-10-07. No están cerradas. Quedan pendientes de revisión independiente.

### Verificación previa

La aprobación HTTP ya limita `director-lf`, `assistant-lf` y el admin con `users.local_field_id` al Campo del lote (`batch.local_field_id`), en `assertCanAccessBatch`. No mira el Campo de la solicitud (sección → club → Campo). Un director de otro Campo, si el lote está etiquetado con el suyo, podía acreditar. IA-61 agrega esa comparación dentro de la transacción de aprobación, antes de escribir.

Presentar o agregar `GM-02` y `GM-03` era posible. La prueba roja de presentar `GM-02` creó la persona `PENDING`. Agregar `GM-03` sobre una solicitud vacía también la creó. Resolver un `PENDING` previo de `GM-02` lo dejó `INVESTED`. El primer intento de agregar chocó con `INVESTITURE_REQUEST_ACTIVE_EXISTS` solo porque ya había otro pendiente; no era un rechazo de la clase.

### IA-61

Texto: «Investidura acreditada posteriormente mediante certificado validado». Queda en `system_reason`. El estado y `resolution_code` siguen `CLOSED_YEAR`. No se reabre la solicitud.

La lectura de la sección (`list`) y la del autorizador (`listForAuthorizer`) incluyen esa fila cuando no hay un `PENDING` que tenga prioridad. El historial de la persona muestra el texto en `person_text`. El de la sección lo muestra en `system_reason`. Un `CLOSED_YEAR` con otro `system_reason` sigue oculto.

Código de rechazo de otro Campo: `CERTIFICATE_IMPORT_ENDED_YEAR_FIELD_FORBIDDEN` (403). Se aplica si el revisor tiene `director-lf`, `assistant-lf`, `admin` o `assistant-admin` y su `local_field_id` no es el de la solicitud. `super-admin`, y `admin` o `assistant-admin` con `local_field_id` nulo, siguen en alcance global. Un llamado interno sin esos roles no entra en esta compuerta: la ruta HTTP ya exige un rol de certificado, y la carrera C1-H2 aprueba con el id del miembro dentro del servicio de aplicación. Si esta compuerta lo rechazara, C1-H2 dejaría de ver `CERTIFICATE_IMPORT_ENROLLMENT_RECONCILIATION_REQUIRED`.

El año terminado se decide como en `assertYearOpen`: inactivo, o el día local del Campo de la solicitud posterior a `end_date`. La zona sale de sección → club → Campo. Si falta, `America/Mexico_City`. El mismo helper es `localCivilDay`. Un `PENDING` de un año terminado se cierra `CLOSED_YEAR` en la misma transacción, antes de acreditar, y después se escribe la nota. Si la acreditación falla, la transacción deshace el cierre. Un certificado de un año posterior no escribe esta nota y no usa esta compuerta de Campo.

`class.completed` no se emite desde la solicitud. La acreditación sigue `reconcileOperationalEnrollment` del mismo año.

Salida roja, antes de la corrección, con `node node_modules/jest/bin/jest.js --no-coverage --forceExit --testPathPatterns 'certificate-bulk-imports-application.service.spec|investiture-authorization-requests.service.spec|investiture-history.spec' -t 'IA-61|IA-62'`: 13 fallos, 1 pasó (el año en curso ya respondía `CERTIFICATE_IMPORT_AUTHORIZATION_PENDING`). El `CLOSED_YEAR` acreditaba sin `system_reason`. El `director-lf` de otro Campo resolvía `APPROVED`. El historial devolvía `person_text` null. Presentar `GM-02` y resolver `GM-02` no rechazaban. Agregar `GM-03` en una solicitud vacía creaba la persona.

Salida verde de esas pruebas: 14 pasaron, 97 omitidas por el filtro.

Archivos: `src/certificate-bulk-imports/class-certificate-live-authorization.ts` (`findEndedSameYearCertificatePeople`), `src/certificate-bulk-imports/certificate-bulk-imports-application.service.ts` (`assertEndedYearCertificateReviewer` y la nota), `src/investiture-requests/investiture-request-lock.ts` (el texto), `src/investiture-requests/investiture-authorization-requests.service.ts` (lecturas e historial).

### IA-62

Código: `INVESTITURE_REQUEST_CLASS_NOT_ELIGIBLE` (400). Textos en `src/i18n/es/errors.json`, `en`, `fr` y `pt-BR`. Presentar, agregar y resolver lo lanzan dentro de la transacción, antes de crear la persona o de investir. La lista única está en `src/certificate-bulk-imports/institutional-class-codes.ts` (`GM-02`, `GM-03`). La reutilizan la aplicación de certificados, el admin de lotes, el servicio de lotes y la solicitud institucional. Esa vía institucional no cambió: `GM-02` y `GM-03` siguen fuera del lote ordinario y entran por `admin-institutional-certificate-requests`.

### PostgreSQL

Clúster descartable propio, no el servicio de Homebrew. `127.0.0.1:55462`, base `sacdia_ia61_test`, log `/tmp/sacdia-ia61-pg/server.log`. `log_min_messages = log`. El control `ia61-log-probe-marker` quedó en el log a las 15:58:03 CST. El archivo no contiene `deadlock detected`.

`IA-61 approves a same-year certificate against the year-cut sweep` en `approve-first` y `close-first`: los dos lados `fulfilled`, un solo `INVESTIDO`, la solicitud `CLOSED_YEAR` con la nota, sin `class.completed`. El tramo del log de cada orden midió `bytes=0` y `deadlock_lines=0`: la espera no escribió, y un interbloqueo sí habría quedado en ese archivo.

Suites, en serie, con `SACDIA_POSTGRES_SERVER_LOG` apuntando a ese log:

| Suite | Resultado | Tiempo |
| --- | --- | --- |
| `investiture-authorization-requests-postgres.e2e-spec` | 66/66 | 8.047 s |
| `district-investiture-pastors-postgres.e2e-spec` | 7/7 | 3.29 s |
| `certificate-import-postgres.e2e-spec` | 10/10 | 3.742 s |

Comando de cada una: `node node_modules/jest/bin/jest.js --config ./test/jest-e2e.json --no-coverage --forceExit --testPathPatterns <suite>`, desde `sacdia-backend`.

### Conteos

Unitarias, desde `sacdia-backend`: `node node_modules/jest/bin/jest.js --no-coverage --forceExit`. Suites: 6 omitidas, 365 pasaron, 365 de 371. Pruebas: 34 omitidas, 4584 pasaron, 4618. 37.112 s. Cero fallos.

`node node_modules/typescript/bin/tsc --noEmit -p tsconfig.build.json`: salida 0.

ESLint `--no-fix` sobre los 84 archivos TS de `git status` en `sacdia-backend`: salida 0. Antes, 22 errores eran solo Prettier en los archivos de esta entrega; se formatearon y la corrida `--no-fix` quedó en 0.

### Límites

No hubo build, despliegue, commit ni migración en Neon. No hubo HTTP real. El alcance de Campo de esta compuerta no envuelve a un llamado interno sin rol de certificado. El control del lote no se reemplazó. C1RR-1 y el fallback del log de Homebrew no son parte de esta entrega. `prepareAnnualCycleDatabase` sigue reconstruyendo con `prisma migrate diff`. Los probes existentes y el informe independiente no se editaron.

### Cierres que siguen

P3-1, P4, P5, P6, P7, W1, X-1, X-2 a X-4, R26-1, R26-3, R26-4, C1-H1 a C1-H5, C1R-N1 a C1R-N5 y C1RR no se reabren. La suite de investidura en este clúster pasó 66 de 66, incluidas esas carreras. Pastores 7 de 7. Importación de certificados 10 de 10. IA-57 sigue rechazando el mismo año mientras el año está en curso. IA-58 e IA-59 no se modificaron en el plan. La fase 2 sigue parcial. La fase 8 no está ejecutada. El pipeline anterior sigue activo. El despliegue sigue bloqueado. No hay commit. IA-61 e IA-62 quedan pendientes de revisión independiente.

### Contrato

| Tema | Dónde |
| --- | --- |
| Certificado del mismo año ya terminado, nota, roles y `CERTIFICATE_IMPORT_ENDED_YEAR_FIELD_FORBIDDEN`. | `docs/api/ENDPOINTS-LIVE-REFERENCE.md` |
| La misma nota en lecturas e historial, y `INVESTITURE_REQUEST_CLASS_NOT_ELIGIBLE` para `GM-02` y `GM-03`. | `docs/api/FRONTEND-INTEGRATION-GUIDE.md` |
| Filas del certificado del mismo año y de las clases institucionales. | `docs/features/validacion-investiduras.md` |

## C1RR-1 a C1RR-3

Pendiente de revisión independiente. No cierra C1RR.

### C1RR-1

`skipOpenInvestitureMail` en `sacdia-backend/src/investiture-requests/investiture-communications.service.ts:574`, llamado al entregar y al despachar recordatorios. `markUncertain` en `:458`.

Roja: la prueba A/B/C esperaba `uncertain` y recibió `skipped` con `investiture_email_disabled`. El cron marcaba también las filas que ya tenían intento ante el proveedor.

Verde: la misma prueba pasa. Una fila con intento reciente o viejo queda `uncertain` y no se reenvía. `skipped` queda para la fila que nunca llegó al proveedor. El texto reciente no contiene «24 horas»; el intento de más de 24 horas sí. R26-4, sin intento, sigue en `skipped`.

Decisión: el cron separa las filas. `markUncertain` elige el texto según la edad del intento guardado.

### C1RR-2

Comparación duplicada en `requestYearEnded` (`class-certificate-live-authorization.ts:265`) y `assertYearOpen` (`investiture-authorization-requests.service.ts:1635`). El literal de zona estaba en la carga del contexto.

Roja: `investitureRequestYearEnded` no existía (`is not a function`). Las cuatro pruebas de borde del pastor y las cuatro del certificado, con `active=true`, ya pasaban antes de extraer el helper: Tijuana `2026-01-01T07:30:00.000Z` abierto y `08:30:00.000Z` cerrado; Bogotá `04:30:00.000Z` abierto y `05:30:00.000Z` cerrado.

Verde: el helper en `ecclesiastical-year-local-day.ts:12` es el único que decide si el año terminó. Lo usan las dos rutas. El respaldo es `INVESTITURE_REQUEST_TIME_ZONE_FALLBACK` (`service.ts:1545`). En PostgreSQL, la misma cuarteta deja al pastor y a la aprobación del certificado del mismo lado: abierto rechaza el certificado con `CERTIFICATE_IMPORT_AUTHORIZATION_PENDING`; cerrado responde `INVESTITURE_REQUEST_YEAR_CLOSED` y la persona queda `CLOSED_YEAR`.

Decisión: no se copió la comparación. Un año inactivo sigue terminado sin leer la zona.

### C1RR-3

`openServerLog` en `test/investiture-authorization-requests-postgres.e2e-spec.ts:4944`.

Roja: el módulo del log no existía y el fallback seguía siendo `/opt/homebrew/var/log/postgresql@18.log`.

Verde: sin `SACDIA_POSTGRES_SERVER_LOG` la prueba unitaria falla nombrando esa variable. Un archivo ajeno no contiene el marcador y falla. En el clúster, `SET log_min_messages = log` en la sesión hace fallar el marcador `RAISE WARNING`. Con `warning` y el log de este servidor, el marcador aparece y las carreras pasan. No se usa `RAISE LOG`.

Decisión: se quitó el respaldo de Homebrew. Cada carrera emite un `RAISE WARNING` único y exige verlo en el archivo antes de medir el tramo.

### Unitarias, PostgreSQL, tsc y ESLint

Unitarias, desde `sacdia-backend`: `node node_modules/jest/bin/jest.js --no-coverage --forceExit`. Suites: 6 omitidas, 367 pasaron, 367 de 373. Pruebas: 34 omitidas, 4609 pasaron, 4643. 36.313 s. Cero fallos.

PostgreSQL descartable, puerto `55471`, log `/tmp/sacdia-c1rr-pg/server.log`. `SHOW log_min_messages` = `warning`. Líneas `ERROR` de control: 8. `deadlock detected`: 0. Marcadores `RAISE WARNING`: 13. `initdb` + `pg_ctl -l`, sin el servicio de Homebrew.

| Suite | Resultado |
| --- | --- |
| `investiture-authorization-requests-postgres.e2e-spec` | 68 de 68, 6.867 s |
| `district-investiture-pastors-postgres.e2e-spec` | 7 de 7, 3.099 s |
| `certificate-import-postgres.e2e-spec` | 10 de 10, 3.493 s |

Los tramos de carrera de C1R-N1 (cuatro órdenes) e IA-61 (approve-first y close-first) informaron `bytes=0` y `deadlock_lines=0`. El log completo, que sí registra ERROR, no tiene `deadlock detected`.

`node node_modules/typescript/bin/tsc --noEmit -p tsconfig.build.json`: salida 0.

ESLint `--no-fix` sobre los 84 archivos TS de `git status` en `sacdia-backend`: salida 0, después de formatear solo los archivos que Prettier marcó.

### Contratos

| Tema | Dónde |
| --- | --- |
| Un solo criterio de año terminado y el mismo respaldo de zona. | `docs/features/validacion-investiduras.md` |
| 403 `CERTIFICATE_IMPORT_ENDED_YEAR_FIELD_FORBIDDEN` traducible, y director sin Campo. | `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, `docs/api/FRONTEND-INTEGRATION-GUIDE.md` |

### Límites

No hubo build, despliegue, commit ni migración en Neon. No hubo HTTP real. `prepareAnnualCycleDatabase` sigue reconstruyendo con `prisma migrate diff`. Los probes y el informe independiente no se editaron. La carrera de C1-H2 ahora aprueba con un `super-admin`: la aserción de `AUTHORIZATION_PENDING` o `RECONCILIATION_REQUIRED` no se cambió. Hace falta porque la compuerta ya no deja pasar a un actor sin rol.

### Cierres que siguen

P3-1, P4 a P7, W1, X-1 a X-4, R26, C1-H1 a C1-H5, C1R-N1 a C1R-N5 y lo ya cerrado de IA-61 e IA-62 no se reabren. Las tres suites de este clúster pasaron, incluidas esas carreras. La fase 2 sigue parcial. La fase 8 no está ejecutada. El pipeline anterior sigue activo. El despliegue sigue bloqueado. C1RR-1 a C1RR-3 quedan pendientes de revisión independiente.

## IA61-H1 a IA61-H5

Pendiente de revisión independiente. No cierra IA-61 ni IA-62.

### IA61-H1

La entrega anterior usó `log_min_messages = log`. Con ese valor el servidor no escribe ERROR, así que cero `deadlock detected` no probaba la ausencia de interbloqueos.

Esta corrida rehace IA-61, C1R-N1 y C-1 (C1-H2) en el clúster de arriba. `SHOW log_min_messages` = `warning`. ERROR de control: 8. `deadlock detected`: 0. Los tramos de esas carreras quedaron en `bytes=0` y `deadlock_lines=0`.

Decisión: no se reescribió la evidencia vieja de la sección IA-61. Esta sección la reemplaza para el interbloqueo.

### IA61-H2

`assertEndedYearCertificateReviewer` en `certificate-bulk-imports-application.service.ts:473`.

Roja: `director-lf` sin Campo, `assistant-lf` sin Campo y un actor sin roles aprobaban el ítem.

Verde: los tres reciben `CERTIFICATE_IMPORT_ENDED_YEAR_FIELD_FORBIDDEN` y no escriben el enrollment. Siguen pasando `super-admin`, el admin global sin Campo y el rol cuyo Campo coincide con la solicitud.

Decisión: la compuerta rechaza esos casos aunque HTTP no los alcance hoy. C1-H2 usa un `super-admin` para no cambiar su aserción.

### IA61-H3

Solo documentación. Si la persona cambió de Campo, el lote puede quedar en un Campo distinto al de la solicitud. Entonces ningún rol de Campo acredita el certificado del año terminado: queda para un admin global o `super-admin`. El comportamiento no se cambió. Texto en `docs/features/validacion-investiduras.md`.

### IA61-H4

El chequeo de `investiture-authorization-requests.service.ts:709` abortaba toda la resolución.

Roja: resolver una persona `GM-02` `PENDING` junto con otra elegible lanzaba `INVESTITURE_REQUEST_CLASS_NOT_ELIGIBLE`. El recordatorio seguía nombrando a la persona `GM-02`.

Verde: la primera queda `REMOVED` / `CLASS_NOT_ELIGIBLE`, sin `INVESTIDO`, sin evento y sin texto de requisitos. La segunda queda `INVESTED`. El recordatorio nombra solo a la elegible.

Decisión: presentar y agregar `GM-02` y `GM-03` siguen rechazando con `INVESTITURE_REQUEST_CLASS_NOT_ELIGIBLE` y no crean la persona. Un `PENDING` previo se retira y el resto de la resolución se confirma. Los recordatorios excluyen esas clases aunque sigan `PENDING`.

### IA61-H5

Roja: `admin` de otro Campo y `assistant-lf` de otro Campo lanzaban `ForbiddenException` sin `code`.

Verde: ambos reciben `code` `CERTIFICATE_IMPORT_ENDED_YEAR_FIELD_FORBIDDEN` y HTTP 403. El código está en `error-codes.ts` y en `es`, `en`, `fr` y `pt-BR`.

Decisión: se mantiene el 403. El mensaje visible lo traduce el filtro.

### Unitarias, PostgreSQL, tsc y ESLint

La misma corrida unitaria de C1RR: 4609 pasaron, 0 fallos, 36.313 s. El mismo clúster: puerto `55471`, log `/tmp/sacdia-c1rr-pg/server.log`, `log_min_messages=warning`, 8 ERROR, 0 `deadlock detected`. Suites 68, 7 y 10, todas en verde. `tsc --noEmit` salida 0. ESLint `--no-fix` sobre 84 archivos TS, salida 0.

### Contratos

| Tema | Dónde |
| --- | --- |
| Lote de otro Campo: solo admin global o `super-admin`. `REMOVED` / `CLASS_NOT_ELIGIBLE` al resolver un `PENDING` de `GM-02` o `GM-03`. | `docs/features/validacion-investiduras.md` |
| HTTP 403 traducible y el retiro al resolver esas clases. | `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, `docs/api/FRONTEND-INTEGRATION-GUIDE.md` |

### Límites

No quedó ninguna parte de C1RR-1 a C1RR-3 ni de IA61-H1 a IA61-H5 sin aplicar. No hubo build, despliegue, commit ni migración en Neon. No hubo HTTP real. Los probes y el informe independiente no se editaron. La evidencia de interbloqueo vale solo para este clúster con `log_min_messages=warning`.

### Cierres que siguen

P3-1, P4 a P7, W1, X-1 a X-4, R26, C1-H1 a C1-H5, C1R-N1 a C1R-N5 y lo cerrado de IA-61 e IA-62 siguen pasando en las tres suites. Presentar y agregar `GM-02` y `GM-03` sigue rechazado. IA-57 sigue rechazando el mismo año en curso. La fase 2 sigue parcial. La fase 8 no está ejecutada. El pipeline anterior sigue activo. El despliegue sigue bloqueado. IA61-H1 a IA61-H5 quedan pendientes de revisión independiente.

## Cierre del backend (BC-1 a BC-15)

Pendiente de revisión independiente. No cierra ningún ítem. No reabre P3-1, P4 a P7, W1, X-1 a X-4, R26, C1-H, C1R-N, C1RR, IA61-H, IA-61 ni IA-62.

No hubo una corrida roja de Jest dedicada antes de cada edición, salvo la evidencia ya registrada del probe de BC-1. Esa ausencia queda dicha aquí. No se inventa una salida roja.

### BC-1

`retireOpenInvestitureMail` en `sacdia-backend/src/investiture-requests/investiture-communications.service.ts:593`.

Roja: el probe `docs/reviews/investidura-autorizacion-review-evidence/c1rr2-skip-toctou-probe.log` dejó R1 y R2 en `skipped`. R1 tenía `sent_at` puesto. Este trabajo no volvió a ejecutar ni a editar ese probe.

Verde: `BC-1 does not skip a row that became sent` y `BC-1 marks uncertain when an attempt appears before the skip`, dentro de la suite unitaria de abajo. Una fila `sent` no pasa a `skipped`. Si aparece un intento (`providerAttempt.at`) antes de la escritura, la fila queda `uncertain`. Si la escritura condicional no coincide, se vuelve a leer y se aplica la misma regla.

Decisión: la escritura exige el estado leído y que no haya `providerAttempt.at`. Un objeto de intento vacío no cuenta como intento ante el proveedor.

### BC-2

`normalizeInvestitureTimeZone` en `sacdia-backend/src/investiture-requests/ecclesiastical-year-local-day.ts:6`. La usa `loadContext` de la solicitud y `sectionField` del certificado.

Roja: no se capturó una corrida de Jest previa a la edición.

Verde: pruebas de zona en blanco, con espacios e inválida en `investiture-authorization-requests.service.spec.ts` y en `investiture-section-time-zone.spec.ts`.

Decisión: blanco o solo espacios usa `America/Mexico_City`. Una zona IANA inválida responde `INVESTITURE_REQUEST_TIME_ZONE_INVALID` y no deja salir un `RangeError`. El recordatorio atrapa esa zona y omite ese Campo.

### BC-3

`ownHistory` en `investiture-authorization-requests.service.ts:486` y `historyEntry` en la línea 2000.

Roja: no se capturó una corrida de Jest previa a la edición.

Verde: `BC-3 shows each own state without revealing who rejected` en `investiture-history.spec.ts`.

Decisión: la persona ve `PENDING` con «En espera de autorización.», la investidura con fecha, clase y comentario, y los dos rechazos como `REJECTED` con solo «Falta de requisitos para investidura». `CLOSED_YEAR` no usa ese texto. Las notas de IA-59 e IA-61 quedan en `person_text`. La respuesta no trae `rejection_reason`, `system_reason` ni el tipo de rechazo. La lectura de la sección no cambia.

### BC-4

`personView` en `investiture-authorization-requests.service.ts:1903`.

Roja: no se capturó una corrida de Jest previa a la edición.

Verde: `BC-4 names people for the board and hides the human reason from the authorizer`.

Decisión: la respuesta trae `user_name`, `class_name`, `section_name` y `resolved_by_name`. El autorizador recibe `rejection_reason` en null y conserva `system_reason`. La directiva ve el motivo humano y el texto largo. Un rechazo del sistema nombra «Sistema». La respuesta de `resolve` para el autorizador también oculta el motivo humano; la fila lo conserva.

### BC-5

`readForAuthorizer` en `investiture-authorization-requests.service.ts:466`.

Roja: no se capturó una corrida de Jest previa a la edición.

Verde: `BC-5 lets super-admin read the request and forbids present and resolve`.

Decisión: `super-admin` lee la solicitud por id, con `person_id`, nombres y la forma de la directiva. Presentar y resolver responden 403 `INVESTITURE_REQUEST_FORBIDDEN`. El listado `GET /api/v1/investiture-requests` sigue en 403: no tiene territorio de autorizador.

### BC-6

`pastorView` en `sacdia-backend/src/classes/district-investiture-pastors.service.ts:386`. El cargador de correos filtra el rol en `investiture-communications.loader.ts`.

Roja: no se capturó una corrida de Jest previa a la edición.

Verde: `BC-6 keeps the quota when the global pastor role is gone` y `BC-6 does not mail a pastor who can no longer authorize`.

Decisión, plan §3.7: la asignación sigue `active` y sigue ocupando cupo. El listado muestra `can_authorize: false` y `role_missing: true`. No aparece en los autorizadores del club. No recibe presentación ni recordatorio. Volver a asignar a otra persona con el cupo lleno sigue en `INVESTITURE_PASTOR_QUOTA_FULL`.

### BC-7

`dueReminders` en `investiture-communications.rules.ts:410`.

Roja: no se capturó una corrida de Jest previa a la edición. El caso de las 10:15 que antes no disparaba ahora sí entra en la ventana.

Verde: `BC-7 recovers the same local day after 10:00 and not another day` y `BC-7 does not send the same reminder twice or on the next day`.

Decisión, plan §3.7: el día programado, desde las 10:00 hasta las 23:59 locales. Antes de las 10:00 no sale. Una corrida perdida a las 10:00 sale en la primera corrida de ese mismo día. El martes no recupera el lunes. La deduplicación sigue siendo la clave única de ejecución, destinatario, rol y alcance.

### BC-8

`reminderRetrySkipReason` en `investiture-communications.rules.ts:610`. `REMINDER_RETRY_LIMIT` es 5, en la línea 17. `prepare` y `deliveryStillAllowed` usan el reloj del servicio (`bindClock`); en producción es el reloj de pared.

Roja: no se capturó una corrida de Jest previa a la edición.

Verde: `BC-8 does not retry a Monday failure on Tuesday and retries once the same Monday`.

Decisión: el reintento vale solo el día local de `execution_key`. Al día siguiente queda `skipped` con `reminder_day_elapsed`. Al quinto intento queda `skipped` con `reminder_retry_limit`. No se recupera un día anterior.

### BC-9

`downgradeInvalidReadyItems` en `sacdia-backend/src/certificate-bulk-imports/certificate-bulk-imports.service.ts:684`.

Roja: no se capturó una corrida de Jest previa a la edición.

Verde: `BC-9 keeps a valid ready item and sends an invalid age to review`.

Decisión: al crear, se aplica la misma validación que al marcar listo. Edad inválida: el ítem nace `NEEDS_REVIEW` con `rejection_reason`. Datos válidos: nace `READY`. Marcar listo, enviar y aprobar no se aflojaron.

### BC-10

`resultDrafts` en `investiture-communications.rules.ts:328`.

Roja: no se capturó una corrida de Jest previa a la edición.

Verde: `BC-10 sends the board two notices when invested, human and system rejections share a group`.

Decisión, plan §3.7: la directiva recibe como máximo dos avisos, uno de investidos y uno de rechazados. El de rechazados junta el rechazo humano y el del sistema, nombra a cada persona y dice quién decidió. El del sistema incluye el texto largo. No incluye el motivo humano. El aviso de la persona no cambia. El subdirector sigue fuera.

### BC-11

`assertClassProgressMutable` en `sacdia-backend/src/classes/class-progress-mutable.ts:13`. `submitSection` lo llama después de resolver el enrollment. Aprobar y rechazar evidencia llaman `assertEnrollmentProgressOpen` antes de la transacción.

Roja: no se capturó una corrida de Jest previa a la edición.

Verde: `BC-11 rejects section submit on INVESTIDO or EXPIRED without writing` y `BC-11 does not approve or reject evidence on INVESTIDO or EXPIRED`.

Decisión: esas escrituras responden `CLASS_PROGRESS_LOCKED` y no entran a la escritura. Otra clase de la misma persona no queda bloqueada.

### BC-12

`canEdit` en `sacdia-backend/src/classes/field-class-threshold-config.service.ts:167`.

Roja: no se capturó una corrida de Jest previa a la edición.

Verde: `BC-12 rejects an inactive year even when today is inside its dates`.

Decisión: `ecclesiastical_years.active` en false cierra la edición para todos los roles, incluido `super-admin`, aunque el día caiga dentro de las fechas. El código sigue siendo `CLASS_THRESHOLD_EDIT_CLOSED`.

### BC-13

`changeDates` en `investiture-authorization-requests.service.ts:313`. Escribe `date_changed_by_id` y `date_changed_at`. `remove` y `changeDates` usan `decisionInstant`.

Roja: no se capturó una corrida de Jest previa a la edición.

Verde: `BC-13 stores the actor and uses the injected clock`.

Decisión: el actor y el instante salen del reloj inyectado, no de `new Date()` como valor por omisión. Columnas nuevas en `sacdia-backend/prisma/migrations/20261007180100_investiture_date_change_audit/migration.sql`. No aplicada en Neon. No hay llave foránea del actor.

### BC-14

Relación Prisma `district_investiture_pastor_user` en `sacdia-backend/prisma/schema.prisma` y en `docs/database/schema.prisma`. Migración `sacdia-backend/prisma/migrations/20261007180000_district_investiture_pastor_user_fk/migration.sql`. No aplicada en Neon.

Roja: no se capturó una corrida de Jest previa a la edición.

Verde: en el clúster de abajo, `pg_constraint` muestra `district_investiture_pastors_user_id_fkey` como `FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE RESTRICT`. La primera corrida de la suite de solicitudes falló dos altas de pastor porque `ACTOR` no existía en `users`; esas dos líneas ERROR del log son esa restricción. Después el sembrado crea al usuario y la suite verde pasa. No quedó una prueba que inserte a propósito un huérfano. En la base ya reconstruida, el conteo de pastores sin usuario fue 0 porque no quedaban filas.

Decisión: la llave es `ON DELETE RESTRICT`. `migrate diff` del clúster de prueba sí la crea, porque es una relación de Prisma.

### BC-15

Se eliminó `closePendingByYearEnd`. La carrera de unidad y las dos del e2e llaman a `closePendingInvestitureAuthorizations` dentro de `$transaction`. No se encontró otro helper de esta implementación que hubiera quedado sin uso y se pudiera quitar con la misma certeza. No se hizo un barrido de código muerto de todo el módulo.

Roja: no se capturó una corrida de Jest previa a la edición.

Verde: la suite de solicitudes y el e2e de PostgreSQL, incluidas las carreras que antes llamaban al método eliminado.

Decisión: el cierre de año usa el closer de producción. No se restauró el método.

### Unitarias, PostgreSQL, tsc y ESLint

Unitarias, después del formato final:

```bash
cd sacdia-backend && node node_modules/jest/bin/jest.js --no-coverage --forceExit
```

Salida 0. Suites: 6 omitidas, 369 pasaron, 369 de 375. Pruebas: 34 omitidas, 4695 pasaron, 4729. 0 fallos. 59.467 s.

PostgreSQL descartable, no el servicio de Homebrew. Puerto `55481`. Log `/tmp/sacdia-bc-pg/server.log`. `SHOW log_min_messages` = `warning`. `deadlock detected`: 0. Líneas con `ERROR`: 11. Ocho son restricciones provocadas por las suites verdes (clave única de envío, enrollment, forma histórica, `ENROLLMENT_GM_SINGLE_ROW`, solape de años, certificado institucional). Dos son la llave de `user_id` de la primera corrida, antes de sembrar a `ACTOR`. Una es la clave única de envío de esa misma corrida fallida. La corrida verde, en secuencia:

| Suite | Pruebas |
| --- | --- |
| `investiture-authorization-requests-postgres.e2e-spec` | 68 pasaron |
| `district-investiture-pastors-postgres.e2e-spec` | 7 pasaron |
| `certificate-import-postgres.e2e-spec` | 10 pasaron |

`node node_modules/typescript/bin/tsc --noEmit -p tsconfig.build.json`: salida 0.

ESLint `--no-fix` sobre 102 archivos TS de `git status` en `sacdia-backend`: salida 0. Antes, el mismo listado tenía solo fallos de Prettier y una asignación inútil; se corrigieron y se volvió a correr `--no-fix`.

### Migraciones nuevas, sin aplicar

- `sacdia-backend/prisma/migrations/20261007180000_district_investiture_pastor_user_fk/migration.sql`
- `sacdia-backend/prisma/migrations/20261007180100_investiture_date_change_audit/migration.sql`

No se aplicaron en Neon ni en producción. `prisma generate` se corrió en local para que el cliente conozca las columnas. No es un build de la aplicación.

### Contratos

| Tema | Dónde |
| --- | --- |
| Historial de la persona, nombres, lectura de `super-admin`, pastor sin rol, dos avisos, ventana de recordatorio, tope de reintento, año inactivo, auditoría de fecha, zona inválida, alta `NEEDS_REVIEW` | `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, `docs/api/FRONTEND-INTEGRATION-GUIDE.md` |
| Los mismos comportamientos, en el lenguaje del dominio | `docs/features/validacion-investiduras.md` |
| Llave de `user_id` y columnas `date_changed_by_id` / `date_changed_at` | `docs/database/SCHEMA-REFERENCE.md`, `docs/database/schema.prisma` |

### Límites

Ningún ítem BC-1 a BC-15 quedó sin aplicar en el árbol. BC-14 no tiene una prueba que inserte un huérfano a propósito; la evidencia es la restricción del clúster y las dos líneas ERROR de la primera corrida. BC-15 no incluye un barrido completo de helpers sin uso. No hubo build de la aplicación, despliegue, commit ni migración en Neon. No hubo HTTP real. Los probes y el informe independiente no se editaron. La fase 8 no está ejecutada. Las pantallas no están en esta entrega. El pipeline anterior sigue activo. El despliegue sigue bloqueado.

### Cierres que siguen

P3-1, P4 a P7, W1, X-1 a X-4, R26, C1-H, C1R, C1RR, IA61-H, IA-61 e IA-62 siguen en el árbol. Las tres suites de este clúster pasaron, incluidas las carreras que ahora usan `closePendingInvestitureAuthorizations`. BC-1 a BC-15 quedan pendientes de revisión independiente.

## BCR-1 a BCR-9

Implementado por subagentes coordinados el 2026-10-07. Sin commit. Migración nueva `20261007190000_investiture_reminder_runs` sin aplicar en Neon. Pendiente de revisión independiente.

Rutas: `sacdia-backend/` salvo indicación. Comandos desde `sacdia-backend/`. Clústeres PostgreSQL propios, nunca el 5432 ni Neon. Binarios de PostgreSQL 18.3 de `/opt/homebrew/opt/postgresql@18`. Puertos: BCR-1 55501, BCR-2 55502 (`log_min_messages = warning`), BCR-3/5/6 55503 (`log_min_messages = warning`). El agente de BCR-1 no declaró `log_min_messages`.

### BCR-1 (Media): `section_name` siempre null (IA-12)

- Cambio: `src/investiture-requests/investiture-authorization-requests.service.ts:1896-1900` (`requestLabels`). Consulta con `select: { club_types: { select: { name: true } } }` y `sectionName = section?.club_types?.name ?? null`. Se quitó la rama `section?.name`, porque `club_sections` no tiene esa columna. Mock de `investiture-authorization-requests.service.spec.ts` ajustado al modelo real (`club_types` es relación).
- Rojo unitario: `node node_modules/jest/bin/jest.js --no-coverage --forceExit src/investiture-requests/investiture-authorization-requests.service.spec.ts -t "BCR-|BC-4|BC-5|BC-2"` → `Tests: 5 failed`. Extracto: `Expected "section_name": "Conquistadores"  Received: null` (BC-4 y BCR-1).
- Rojo PostgreSQL: `-t "BCR-"` → `BCR-1 returns the real club type name ... Expected: "Conquistadores" Received: null`.
- Verde PostgreSQL: lee como directiva (`present()`), como autorizador (`fieldAuth()`) y como super-admin, y obtiene `Conquistadores`.
- Decisión: `select` anidado en vez de `include` completo. Mismo efecto, sin traer columnas de la sección. La prueba unitaria acepta `select` o `include`.

### BCR-2 (Media): guarda BC-11 más amplia que `INVESTIDO` y `EXPIRED`

- Cambios:
  - `src/classes/class-progress-mutable.ts:34-62`: nuevos `assertClassProgressNotTerminal` (solo `INVESTIDO` y `EXPIRED`) y `assertEnrollmentNotTerminalInTransaction` (lee `investiture_status` con el cliente de la transacción). `assertClassProgressMutable` queda intacto para los demás usuarios.
  - `src/evidence-review/evidence-review.service.ts:1333-1345` (`lockClassProgress`): se quitan las llamadas previas a `assertEnrollmentProgressOpen` en aprobar y rechazar. La guarda corre dentro de la transacción, después del candado de enrollment.
  - `src/classes/classes.service.ts:1608-1612` (`submitSection`): se quita `assertProgressMutable` previo. La guarda corre dentro de la transacción, después de `lockPendingInvestitureProgress`.
- Hallazgo contra `113d8ba`: revisión de evidencias y `submitSection` no tenían guarda de estado; el bloqueo amplio vino de cambios posteriores.
- Rojo unitario evidencias: `node node_modules/jest/bin/jest.js --no-coverage --forceExit src/evidence-review/evidence-review.service.spec.ts` → `Tests: 5 failed, 20 passed, 25 total`. Extractos: `reads the enrollment status inside the transaction, after the enrollment lock: Expected number of calls: 0 / Received number of calls: 1`; `CLUB_APPROVED / COORDINATOR_APPROVED / FIELD_APPROVED / IN_PROGRESS (locked_for_validation=true): Received promise rejected instead of resolved`.
- Rojo unitario `submitSection`: `node node_modules/jest/bin/jest.js --no-coverage --forceExit src/classes/classes.service.spec.ts -t "submitSection guard"` → `Tests: 7 failed, 91 skipped, 1 passed`. INVESTIDO y EXPIRED: `Received promise resolved instead of rejected`. Legacy: `AppConflictException CLASS_PROGRESS_LOCKED (class-progress-mutable.ts:22)`.
- Rojo PostgreSQL: `Tests: 6 failed, 6 passed, 12 total`. Se obtuvo quitando temporalmente las dos llamadas dentro de la transacción y restaurando después desde copia verificada. Los 6 rojos son INVESTIDO/EXPIRED comprometido primero, en approve, reject y submitSection (`Received promise resolved instead of rejected`: la escritura ocurrió después de INVESTIDO).
- Verde unitario: `jest src/classes src/evidence-review` → 19 suites, 259 passed. `jest src/classes src/evidence-review src/investiture-requests` → 30 suites, 431 passed.
- Verde PostgreSQL: `SACDIA_TEST_DATABASE_URL=postgresql://abner@127.0.0.1:55502/sacdia_bcrb_test node node_modules/jest/bin/jest.js --config test/jest-e2e.json --no-coverage --forceExit test/evidence-review-investiture-guard-postgres.e2e-spec.ts` → 1 suite, 12 passed. PostgreSQL 18.3 de `/opt/homebrew/opt/postgresql@18`, `LC_ALL=C`.
- Cobertura PostgreSQL:
  - Orden A (INVESTIDO/EXPIRED comprometido primero): approve ×2, reject ×2 y submitSection ×2 → `CLASS_PROGRESS_LOCKED`, sin escritura. La fila sigue `SUBMITTED` o `PENDING`, sin `validated_by_id`, con 0 `validation_logs`.
  - Orden B (evidencia primero, la resolución que inviste espera el candado): orden observado `['review','invest']`; la fila queda `VALIDATED` o `REJECTED` y el enrollment `INVESTIDO`.
  - Legacy (`SUBMITTED_FOR_VALIDATION`, `CLUB_APPROVED`, `IN_PROGRESS` + `locked_for_validation`): approve, reject y submitSection escriben.
  - Estrés (20 rondas sin sincronizar): probabilístico, no concluyente; los casos deterministas son el contrato.
- Log del servidor: 0 líneas `ERROR`, 0 `deadlock detected`. Única línea no benigna del primer arranque: `FATAL: postmaster became multithreaded during startup` (sin `LC_ALL`, reintentado). Clúster detenido y directorio borrado.
- Decisión: la guarda nueva bloquea solo `INVESTIDO` y `EXPIRED`, leída bajo el candado `investiture-authorization-enrollment:<id>` dentro de la transacción que escribe. Se conserva el `PENDING` de la solicitud nueva (P4-3) y el comportamiento de `113d8ba` para `locked_for_validation` y estados legacy. En `submitSection`, un error de acceso puede salir antes que `CLASS_PROGRESS_LOCKED`.
- Límites:
  - La resolución que inviste se emula con una transacción que toma el mismo candado y hace `UPDATE enrollments SET investiture_status='INVESTIDO'`. No se ejercita `InvestitureAuthorizationRequestsService.resolve` real.
  - `uploadSectionFile` y `deleteSectionFile` conservan la guarda amplia (ya la tenían en `113d8ba`; fuera de alcance).
  - El e2e usa `ClassesService` con dependencias de acceso, política y almacenamiento simuladas.

### BCR-3 (Baja): tope de reintentos de recordatorio

- Cambio:
  - `src/investiture-requests/investiture-communications.service.ts:903` (`claimRetry`), usado en :856 (antes de `retryFailedInvestitureJob`) y en :879 (antes de `sendInvestitureNotice` con fila `queued`). `freshMail` (:930) compara `attempts + 1` antes del reclamo y `attempts` en el trabajador.
  - `src/investiture-requests/investiture-communications.rules.ts:17` (`REMINDER_RETRY_LIMIT = 5`), :691 (`reminderAttemptsExhausted`, `n > REMINDER_RETRY_LIMIT`), :697 (`reminderRetrySkipReason`), :721 (`reminderRetryDraft`).
  - Semántica: `attempts` cuenta entregas al canal de correo (reclamo de `deliverOnce` o re-encolado), incluida la que sale. El tope cuenta entregas a la cola, no llamadas HTTP.
- Rojo unitario: `node node_modules/jest/bin/jest.js --no-coverage --forceExit src/investiture-requests/investiture-communications.delivery.spec.ts -t "BCR-3"`. Q1 recibió `{attempts:1, requeues:20, status:'queued'}` y esperaba `{attempts:5, requeues:4, status:'skipped'}`. Q2 recibió `providerAttempts: 4` y esperaba 5.
- Rojo PostgreSQL: `BCR-3 counts every re-queue with two concurrent instances` → `{requeues: 40, attempts: 1, status:'queued'}` (2 instancias × 20 corridas). `BCR-3 reaches the provider exactly 5 times` → `attempts: 6`. Nota: el código viejo ya no existe; el rojo se obtuvo parcheando temporalmente `claimRetry` y `freshMail` a su semántica anterior y restaurando desde copia verificada.
- Verde PostgreSQL: `-t "BCR-"` → 14/14. Exactamente 5 intentos ante el canal; el sexto no sale. Fila `skipped`, `last_error = reminder_retry_limit`, con dos instancias en carrera `requeues = 4`.
- Decisión: el 5.º reclamo ya salía como `reminder_retry_limit` con el código viejo (4 envíos). Corregido sumando el intento antes del reclamo.
- Límites: los reintentos internos de BullMQ (`attempts: 5` con backoff dentro de una misma entrega) no se cuentan. Cada hand-off que el proveedor repite usa la misma `idempotencyKey`.

### BCR-4 (Baja): matriz C desactualizada

Ver matriz C actualizada.

Lo que cambió: `resolve` existe (`investiture-authorization-requests.service.ts:629`). IA-03, 07, 09 y 10 pasan a Implementado. IA-27 y 28 quedan Parcial por el flujo anterior (`markInvestido`). IA-29 pasa a Implementado en la vía nueva.

### BCR-5 (Baja): recordatorio tardío cuando la corrida de las 10:00 sí ocurrió (BC-7)

- Cambio:
  - Migración nueva, NO aplicada: `prisma/migrations/20261007190000_investiture_reminder_runs/migration.sql`. PK `(local_field_id, role, local_date)`, FK a `local_fields` con `ON DELETE CASCADE`. Modelo `investiture_reminder_runs` en `prisma/schema.prisma:3363`. `npx prisma generate` ejecutado.
  - `src/investiture-requests/investiture-communications.rules.ts:406` (`reminderSchedule`), :438 (`reminderRunsDue`: corridas por Campo y rol), :460 (`dueReminders({ claimed })`, solo genera borradores de corridas reclamadas).
  - `src/investiture-requests/investiture-communications.loader.ts:157` (`scheduleFields` = todos los Campos, tengan o no pendientes).
  - `src/investiture-requests/investiture-communications.service.ts:241` (`dispatchReminders`), :290 (`claimDayAndStage`: en una transacción, `INSERT ... SELECT unnest(...) ON CONFLICT DO NOTHING RETURNING`, timeout 30000; deja las filas `pending`), :347 (`deliverPending` retoma las `pending` tras una caída).
- Rojo PostgreSQL, con la tabla generada y antes del servicio nuevo, `-t "BCR-5"`:
  - (a) Corrida de las 10:00 sin pendientes y pendiente a las 15:00: esperaba 0 y recibió 2 recordatorios.
  - (a2) Pastor asignado después de la corrida de las 10:00: recibió `[LIVE, CASE]` en vez de `[LIVE]`.
  - (e) Tabla de corridas vacía: `[]` en vez de `assistant-lf, director-lf, pastor`.
  - (b), (b2) y (c) ya pasaban con el código viejo y se conservan como regresión.
- Verde PostgreSQL: `-t "BCR-"` 14/14; suite completa 82/82. Escenarios: (a) 0 recordatorios; (a2) nada para el destinatario nuevo; (b) corrida de las 10:00 perdida: la de las 13:00 envía una vez, y las de las 14:00 y 23:45 no duplican; (b2) el día siguiente no recupera; (c) martes y jueves sin filas de corrida; (d) miércoles envía una vez; (e) dos instancias en la misma ranura: 2 filas, ledger con los 3 roles, sin duplicados.
- Verde unitario: describe `BCR-5 reminder day ledger` (incluye «apagado no consume el día» y «caída de la cola conserva el día y `deliverPending` lo termina»), y `investiture-communications.rules.spec.ts` (`BCR-5 lists the runs due...`, `BCR-5 produces drafts only for the runs this execution claimed`).
- Decisión: ledger por Campo, rol y día programado. Con el correo de investidura apagado no se reclama el día. Una caída tras el commit no pierde el día.
- Límites:
  - El registro crece 2 o 3 filas por Campo y día programado. Sin purga; se puede podar por `local_date`.
  - Un Campo creado después de las 10:00 de un día programado reclama su corrida en la primera ejecución disponible.
  - No se obtuvo rojo de la carrera del ledger con el código viejo (no tenía ledger). La prueba (e) demuestra la unicidad con el nuevo.
  - La migración no está aplicada en Neon.

### BCR-6 (Baja): detalles del pastor sin rol o con cuenta eliminada (BC-6)

- Cambio:
  - Nuevo `src/investiture-requests/investiture-pastor-eligibility.ts`: `pastorEligibility` (:39), `pastorCanAuthorize` (:79), `eligiblePastorUserIds` (:88). Regla: rol global `pastor` activo (sin distinguir mayúsculas, `roles.active`, `role_category = GLOBAL`, `users_roles.active`) y `users.active = true`.
  - Usos: `src/classes/district-investiture-pastors.service.ts:314` (`assertPastorUser`), :349 (`activePastors`), campo `account_inactive` (:35, :386). `src/investiture-requests/investiture-authorization-requests.service.ts:2110` (`authorizerMatches`, usa `pastorCanAuthorize` en :2135), :2174 (`pastorDistrictIds`, :2187). `src/investiture-requests/investiture-communications.loader.ts:293`.
- Decisión: cuenta eliminada = asignación que sigue ocupando cupo, con `can_authorize: false` y `account_inactive: true`. No se reutiliza `role_missing`, porque el rol puede existir. Aditivo: `sacdia-admin` no se tocó.
- Rojo PostgreSQL, `-t "BCR-6"`, 3 fallos:
  - Listado: `DELETED_PASTOR` esperaba `{can_authorize:false, account_inactive:true}` y recibió `can_authorize: true`.
  - Resolución: `attempt(DELETED_PASTOR)` → `Received promise resolved instead of rejected`.
  - Correos: presentación esperaba `[CASE_PASTOR, LIVE_PASTOR]` y solo recibió `LIVE_PASTOR` (rol `Pastor` fuera por comparación exacta). La cuenta eliminada ya no recibía correo, porque el cargador filtraba `users.active`.
- Verde PostgreSQL: los 3 pasan.
- Verde unitario nuevo: `district-investiture-pastors.service.spec.ts` (`BCR-6 keeps the quota, marks account_inactive...`), `investiture-authorization-requests.service.spec.ts` (`BCR-6 rejects and lists nothing...`), `investiture-communications.delivery.spec.ts` (describe `BCR-6 pastor eligibility in mails`).
- Efecto en pruebas existentes: el ACTOR del e2e recibe en `beforeAll` el rol `pastor` GLOBAL; los mocks de clases y entrega pasan a `users.findMany` con `users_roles`.
- Límite: la comprobación de cuenta y rol en `resolve` ocurre dentro de la transacción, sin candado sobre `users`. Una eliminación confirmada justo después de la comprobación no se detiene.

### BCR-7 (Baja): `super-admin` con forma de directiva (BC-5)

- Cambio: `src/investiture-requests/investiture-authorization-requests.service.ts:484-486` (`readForAuthorizer` siempre llama `readRequest(..., 'authorizer')`; antes usaba `'board'` para `super-admin`). Ningún campo ni controlador cambió.
- Rojo unitario, `-t "BCR-|BC-4|BC-5|BC-2"`: `BCR-7 ... Expected rejection_reason: null  Received: "motivo-humano"`.
- Verde unitario: `rejection_reason: null` y `JSON.stringify(read)` no contiene el motivo humano. La fila sigue guardando `motivo-humano`. `sectionHistory` no cambia.
- Efecto en API: la lectura por id de `super-admin` ya no incluye el motivo humano. Doc: `docs/api/FRONTEND-INTEGRATION-GUIDE.md:117`.
- Decisión: `super-admin` recibe la forma del autorizador; le alcanza para corregir fechas.

### BCR-8 (Baja): zona inválida bloquea la lectura (BC-2)

- Cambio:
  - `src/investiture-requests/investiture-authorization-requests.service.ts:1516-1520` (`loadContext` con `options: { validateTimeZone?: boolean }`).
  - :1581-1583: con `false` usa `readTimeZone`.
  - :1593 (`readTimeZone`): cae a `America/Mexico_City` si la zona es inválida.
  - :476-480 (`readForAuthorizer` pasa `{ validateTimeZone: false }`).
  - Las escrituras (`present`, `addPeople`, `remove`, `changeDates`, `resolve`, y las cargas de contexto de escritura) siguen validando.
- Rojo unitario: `AppBadRequestException ... at normalizeInvestitureTimeZone ... at loadContext ... at readForAuthorizer`. Y `BCR-8 still denies a non-authorizer ... Expected INVESTITURE_REQUEST_FORBIDDEN Received INVESTITURE_REQUEST_TIME_ZONE_INVALID`.
- Rojo PostgreSQL: `AppBadRequestException ... loadContext ... readForAuthorizer` con `local_fields.timezone = 'Not/AZone'`.
- Verde PostgreSQL: lectura correcta como autorizador y como `super-admin` con zona inválida. `present()` y `resolve()` siguen rechazando con `INVESTITURE_REQUEST_TIME_ZONE_INVALID`, y la persona queda `PENDING`. Un no autorizador recibe `INVESTITURE_REQUEST_FORBIDDEN`.
- Decisión: la lectura de autorización no usa la zona (`authorizerMatches` usa Campo y distrito).

### BCR-9 (Baja): fecha futura al crear (BC-9)

- Cambio en `src/certificate-bulk-imports/certificate-bulk-imports.service.ts`:
  - `addItem` (:285): `futureDateReason(dto.completed_at)` (:294) antes de la validación de catálogo y edad. Si hay motivo, el ítem nace `NEEDS_REVIEW` con `rejection_reason`.
  - `downgradeInvalidReadyItems` (:686), ruta de `createDraft` con `items[]`: por cada `READY` recién creado, `futureDateReason(civilDate(item.completed_at))` (:695) y `update` a `NEEDS_REVIEW`.
  - Helper `futureDateReason` (:846): envuelve `assertNotFuture` (:838) y devuelve `CERTIFICATE_IMPORT_DATE_IN_FUTURE` o `null`.
- Rojo unitario: `node node_modules/jest/bin/jest.js --no-coverage --forceExit src/certificate-bulk-imports/certificate-bulk-imports.service.spec.ts -t BCR-9` → `Tests: 2 failed, 36 skipped, 1 passed, 39 total`. Extractos: `Expected: ObjectContaining {"data": ... "rejection_reason": "CERTIFICATE_IMPORT_DATE_IN_FUTURE", "status": "NEEDS_REVIEW"} ... Number of calls: 0` y `"status": "NEEDS_REVIEW"` contra `Received: "status": "READY"`. La tercera prueba (fecha pasada → `READY`) ya pasaba y queda como regresión.
- Hallazgo durante la implementación: un primer intento con `assertNotFuture` dentro del `try` y `reviewReason(error)` falló. `reviewReason()` no reconoce el `BadRequestException` de Nest 11 (`getResponse()` es objeto), así que relanzó el error.
- Decisión: no se tocó `reviewReason`, porque cambiaría el comportamiento de otros `BadRequestException` (por ejemplo `CERTIFICATE_IMPORT_CATALOG_NOT_FOUND`) y reabriría BC ya aceptados. Se usa un helper dedicado que lee `error.message`. Para el revisor: la rama `typeof response === 'string'` de `reviewReason` es código muerto con Nest 11; no se corrigió.
- Verde unitario: `src/certificate-bulk-imports` → 21/21 suites, 356/356 tests (353 previos + 3 nuevos). Spec del servicio: 39/39.
- Límites: pruebas unitarias con mocks de Prisma; no hay PostgreSQL para este ítem. La comparación de fecha usa `new Date().toISOString().slice(0,10)` (UTC), como `assertNotFuture` ya existente; cerca de medianoche UTC puede diferir un día respecto de la hora local. El `git diff --stat` de ese archivo incluye entregas BCR previas.

### Verificación integral

Corrida única después de BCR-1 a BCR-9, sobre el árbol completo. HEAD del backend en `eac821e`: los commits `f9983e1..eac821e` (OCR y PDF de certificados, otra sesión) son posteriores a `113d8ba` y no incluyen los cambios de investidura, que siguen sin commit.

| Comprobación | Resultado |
| --- | --- |
| `node node_modules/jest/bin/jest.js --no-coverage --forceExit` | 369 suites pasadas, 6 omitidas (375). 4741 pruebas pasadas, 34 omitidas, 0 fallos. Salida 0. |
| `npx tsc --noEmit -p tsconfig.build.json` | Salida 0. |
| `npx eslint --no-fix` sobre los 85 `.ts` de `git status --porcelain` | Salida 0, sin errores ni advertencias. |
| PostgreSQL 18.3 descartable, `127.0.0.1:55510`, `SHOW log_min_messages` = `warning`, `--config ./test/jest-e2e.json --runInBand` | 111/111: `investiture-authorization-requests` 82, `evidence-review-investiture-guard` 12, `certificate-import` 10, `district-investiture-pastors` 7. |
| Log del servidor | 8 `ERROR` por corrida, todas violaciones de restricciones provocadas por las pruebas (`ENROLLMENT_GM_SINGLE_ROW` ×2, `uniq_enrollments_active_user_year_regular` ×2, `enrollments_historical_certificate_shape`, `uq_investiture_message_dispatch`, `uniq_institutional_certificate_request_open`, `ecclesiastical_years_no_overlap`). 0 `deadlock detected`. |
| Migraciones | Las 7 sin commit posteriores al 2026-09-30 aplican en orden sobre el schema de HEAD; el diff contra `schema.prisma` deja solo un default preexistente de `club_annual_rankings.award_category_id`, ajeno a esta entrega. Ninguna aplicada en Neon. |

Notas de entorno: las suites PostgreSQL deben correr con `--runInBand` (en paralelo reconstruyen el mismo schema y fallan en cascada). Prisma 7.9.1 usa `--to-schema` y `--from-config-datasource` en `migrate diff`.

## BCR33-N1 a BCR33-N5

Corrección de las observaciones bajas de la revisión 33. Un solo implementador, TDD estricto: rojo capturado antes de cada cambio. Backend en HEAD `eac821e`, cambios de investidura sin commit. No se tocaron `certificate-import-files.service*`, `certificate-import-pdf*` ni `src/certificate-bulk-imports/ocr/*`.

### BCR33-N1 — `changeDates` de `super-admin` devuelve la forma del autorizador

- Código: `src/investiture-requests/investiture-authorization-requests.service.ts:373` (`changeDates`): `this.readRequest(tx, requestId, marker ? 'board' : 'authorizer')`. `marker` es el cargo de directiva de la sección; la directiva conserva `board`, `super-admin` (sin `marker`) recibe `authorizer`, es decir `rejection_reason: null`.
- Rojo: `node node_modules/jest/bin/jest.js --no-coverage --forceExit src/investiture-requests/investiture-authorization-requests.service.spec.ts -t BCR33-N1` → `Tests: 1 failed, 87 skipped, 1 passed`. Extracto: `Expected substring: not "motivo-humano"` con `"rejection_reason":"motivo-humano"` dentro de la respuesta de `changeDates` de `super-admin` (dos personas: una `PENDING`, otra `REJECTED_BY_PERSON` con motivo humano).
- Verde: la misma suite, 89/89. Pruebas nuevas (`describe` «BCR-1, BCR-7 and BCR-8 read paths»): `BCR33-N1 changeDates by super-admin returns the authorizer shape without the human reason` y `BCR33-N1 changeDates by the section directiva keeps the board shape with the human reason`.
- Decisión: la forma depende de quién corrige, igual que en `readForAuthorizer` (BCR-7). Solo mocks: el comportamiento no depende de SQL, así que no se añadió prueba PostgreSQL. Contrato actualizado en `docs/api/ENDPOINTS-LIVE-REFERENCE.md` (PATCH `/dates`) y corregida la fila del GET por id, que seguía diciendo que `super-admin` ve el motivo humano.

### BCR33-N2 — un error de render no consume el día del recordatorio

- Código:
  - `investiture-communications.rules.ts:488` y `:580` (`dueReminders`): un Campo cuyo render falla no aporta borradores parciales (`drafts.length = draftsBeforeField`) y se informa por `onFieldError`.
  - `investiture-communications.service.ts:255-270` (`dispatchReminders`): `build` devuelve `{ drafts, failedFieldIds }`.
  - `investiture-communications.service.ts:296-352` (`claimDayAndStage`): en la misma transacción, `DELETE FROM "investiture_reminder_runs"` de las corridas reclamadas de esos Campos. Los demás Campos conservan su reclamo.
- Rojo unitario: `... src/investiture-requests/investiture-communications.delivery.spec.ts -t BCR33-N2` → `Expected: 0 / Received: 3` en `expect(ledger.size).toBe(0)` tras la corrida de las 10:00 con panel vacío.
- Rojo PostgreSQL (con el DELETE desactivado a propósito, restaurado después): `... --config ./test/jest-e2e.json --runInBand test/investiture-authorization-requests-postgres.e2e-spec.ts -t BCR33-N2` → `Expected: 0 / Received: 3` en `investiture_reminder_runs.count({ local_field_id, local_date })`.
- Verde: unitaria (`BCR33-N2 a render error does not consume the day: a later run recovers it once`) y PostgreSQL (`BCR33-N2 a render error at 10:00 does not consume the day; the 11:00 run after the fix sends once`): a las 10:00 con `ADMIN_PANEL_URL` vacío 0 enviados y 0 filas en `investiture_reminder_runs`; a las 11:00 ya corregido salen 2 recordatorios y quedan las 3 filas; a las 12:00 no sale nada más.
- Decisión: la unidad que se libera es el Campo completo (todos sus roles reclamados), porque el render falla por Campo y `dueReminders` ya aislaba los errores por Campo. Un recordatorio del mismo día no se duplica porque `investiture_message_dispatches` tiene la clave única y las filas del Campo con error no llegaron a crearse. «Los demás Campos no se ven afectados» queda cubierto por la prueba existente `keeps the other field reminder when one field fails` (rules); no se añadió una prueba multi-Campo con PostgreSQL.
- Nota de prueba: el mock `$executeRaw` se asigna solo en la prueba nueva; el mock compartido `world()` no lo tiene a propósito (otras pruebas dependen de que no exista).

### BCR33-N3 — catálogo inválido al crear nace `NEEDS_REVIEW` (BC-9)

- Código: `src/certificate-bulk-imports/certificate-bulk-imports.service.ts:~678-695` (`reviewReason`): si `getResponse()` es objeto, toma `message` cuando es un código en mayúsculas (`/^[A-Z][A-Z0-9_]+$/`); la rama de cadena queda igual y cualquier otra `BadRequestException` sigue relanzándose.
- Llamadores de `reviewReason`: `addItem` (creación), `downgradeInvalidReadyItems` (creación vía `createDraft` con `items[]`). `updateItem` y `resubmitItem` no lo usan y siguen respondiendo 400 con `assertCatalogChoice`: es la ruta de edición explícita y se mantiene.
- Rojo: `... src/certificate-bulk-imports/certificate-bulk-imports.service.spec.ts -t BCR33-N3` → `Tests: 2 failed, 39 skipped, 1 passed`. Extractos: `Received promise rejected instead of resolved / Rejected to value: [BadRequestException: CERTIFICATE_IMPORT_CATALOG_NOT_FOUND]` (createDraft) y `BadRequestException: CERTIFICATE_IMPORT_CATALOG_NOT_FOUND` (addItem).
- Verde: `src/certificate-bulk-imports` 21/21 suites. Pruebas nuevas: createDraft con honor inactivo (el lote se crea y el ítem pasa a `NEEDS_REVIEW` con `CERTIFICATE_IMPORT_CATALOG_NOT_FOUND`), addItem con clase inexistente (nace `NEEDS_REVIEW` con ese código) y updateItem con `mark_as_ready` y catálogo inválido (sigue 400, no escribe).
- Sin prueba PostgreSQL: la corrección es la lectura del objeto de excepción de Nest; no depende de SQL ni de restricciones de la base.
- Contrato: `ENDPOINTS-LIVE-REFERENCE.md` y `validacion-investiduras.md` ahora dicen que el catálogo inválido al crear no falla el lote.

### BCR33-N4 — tope de recordatorio contado ante el proveedor

- Causa: `email.queue.ts` usaba `attempts: 5` por entrega y la recuperación reactivaba el job con `resetAttemptsMade`, de modo que cada una de las 5 entregas contadas podía llegar hasta 5 veces al proveedor (25).
- Código:
  - `src/common/email/email.queue.ts:117-140`: `enqueue(..., { attempts? })`; por defecto sigue en 5 con backoff exponencial.
  - `src/common/email/email.service.ts:143-165`: `sendInvestitureNotice({ dispatchId, kind })` pasa `attempts: 1` solo si `kind === 'REMINDER'`.
  - `investiture-communications.service.ts:914` y `:1070`: el servicio pasa `row.kind` / `draft.kind`.
- Rojo: `... email.service.spec.ts email.queue.spec.ts investiture-communications.delivery.spec.ts -t BCR33-N4` → `Tests: 3 failed` (opciones del job sin `attempts: 1`; `queue.add` sin override; el puerto de correo no recibe `kind`). Rojo con Redis real (`redis-server` descartable en puerto libre de loopback, patrón de `investiture-mail-redis.spec.ts`): `-t BCR33-N4` → `Expected: 1 / Received: 5` en el número de llamadas al proveedor tras la primera entrega con proveedor siempre caído.
- Verde: unitarias de correo y servicio, y Redis: `BCR33-N4 reaches the provider at most 5 times per reminder across every hand-off` (1 llamada tras la primera entrega; luego `deliverPending` repetido hasta `skipped`/`reminder_retry_limit`; total exactamente 5).
- Pruebas existentes ajustadas, no relajadas:
  - `retries an exhausted provider failure after a worker restart...`: esperaba `attemptsMade >= 5`; ahora espera 1 y comprueba una sola llamada al proveedor.
  - `does not send a second message when the ack fails after the provider accepts`: antes lo resolvía el reintento interno de BullMQ; ahora la entrega falla con la fila `failed`, la siguiente (`deliverPending`) reenvía el cuerpo guardado con la misma clave de idempotencia y reconoce. El proveedor sigue aceptando un solo mensaje (2 llamadas, una clave).
- Decisión: solo los recordatorios. PRESENTATION y RESULT conservan `attempts: 5` (el contrato de «5 intentos ante el proveedor» es de REMINDER), igual que los correos de autenticación y demás tipos. Los reintentos de un recordatorio fallido pasan a ser los de `deliverPending`/cron, no los backoff internos de BullMQ.
- Límite: los jobs de recordatorio ya encolados con `attempts: 5` antes del despliegue conservan ese valor hasta terminar; es una ventana transitoria.

### BCR33-N5 — helper de prueba fuera de `src/` y consistencia al crear

- `src/investiture-requests/investiture-server-log.ts` pasó a `test/helpers/investiture-server-log.ts`, y su spec a `test/helpers/investiture-server-log.e2e-spec.ts` (el jest unitario solo recoge `src/**/*.spec.ts`; el de e2e recoge `*.e2e-spec.ts`). Se actualizó el import de `test/investiture-authorization-requests-postgres.e2e-spec.ts`. Ningún archivo de `src` lo importa (`rg investiture-server-log src` sin resultados). Efecto: el conteo unitario baja una suite y 3 pruebas, que ahora corren en la configuración e2e (3/3).
- Consistencia: se documentó en el código (`addItem`) y en `ENDPOINTS-LIVE-REFERENCE.md` / `validacion-investiduras.md`: al crear (`items[]` y `POST` de un ítem), fecha futura, catálogo inválido o edad inválida dejan el ítem en `NEEDS_REVIEW` con el código en `rejection_reason`, también con `mark_as_ready: false`, y no fallan el lote; `PATCH` (`updateItem`) es la ruta de edición explícita y responde 400 con esos códigos. No se cambió el comportamiento. Prueba de caracterización `BCR33-N5 documents that a future date is born NEEDS_REVIEW on creation but is a 400 on updateItem` (pasa sin rojo previo porque fija el comportamiento existente).

### Verificación BCR33

| Comprobación | Resultado |
| --- | --- |
| `node node_modules/jest/bin/jest.js --no-coverage --forceExit` | 368 suites pasadas, 6 omitidas (374). 4754 pruebas pasadas, 34 omitidas, 0 fallos. (Una suite menos que antes por la mudanza del spec del helper.) |
| `npx tsc --noEmit -p tsconfig.build.json` | Salida 0. |
| `npx eslint --no-fix` sobre los 86 `.ts` de `git status --porcelain` | Salida 0 tras corregir dos avisos de prettier en pruebas nuevas. |
| PostgreSQL 18.3 descartable (`127.0.0.1:55520`, base `sacdia_bcr33_test`, `--config ./test/jest-e2e.json --runInBand`), `SHOW log_min_messages` | `warning`. 4/4 suites, 112/112 (solicitudes 83, evidencias 12, certificados 10, pastores 7). |
| Log del servidor | 8 `ERROR`, todos provocados por las pruebas: `uniq_enrollments_active_user_year_regular` ×2, `ENROLLMENT_GM_SINGLE_ROW` ×2, `enrollments_historical_certificate_shape` ×1, `uq_investiture_message_dispatch` ×1, `uniq_institutional_certificate_request_open` ×1, `ecclesiastical_years_no_overlap` ×1. `deadlock detected`: 0. |
| Limpieza | Clúster detenido y directorio `/private/tmp/bcr33-pg` eliminado. El Redis de la prueba N4 es un proceso hijo en puerto libre que se cierra con la suite; no se tocó el Redis del sistema, Neon ni producción. |

### Límites

- N1, N3 y N5 se cubren con pruebas unitarias con mocks; su comportamiento no depende de SQL.
- N2 se cubre con un solo Campo en PostgreSQL; el aislamiento entre Campos se apoya en la prueba existente de `dueReminders`.
- N4: el cálculo de «≤ 5 llamadas» se verificó con Redis real y un proveedor simulado; no contra Resend. Los jobs ya encolados antes del despliegue conservan `attempts: 5`.
- Las migraciones siguen sin aplicarse en Neon; pantallas y fase 8 siguen pendientes.

Pendiente de revisión independiente.

## B. Código revisable

No hay commits de este trabajo. El SHA final es el SHA base. Los diffs son el árbol de trabajo.

| Repo | Ruta | Rama | SHA base y final | Árbol |
| --- | --- | --- | --- | --- |
| docs / workspace | `/Users/abner/Documents/development/sacdia` | `development` | `c8bf1361442e92dd7f1d4497d062fcca86a49b4c` | El plan `docs/plans/2026-09-28-investidura-autorizacion.md` ya estaba modificado antes de este trabajo. No se revirtió. |
| backend | `/Users/abner/Documents/development/sacdia/sacdia-backend` | `development` | `9d8fe1d3d1fd0e56256043ee8208d26c9bfcc39b` | Limpio al inicio. Los cambios de esta sesión están sin commit. |
| admin | `/Users/abner/Documents/development/sacdia/sacdia-admin` | `development` | `d9d1f554798d509ed3820b5f64d3246db2001549` | Sin cambios de esta sesión. |
| app | `/Users/abner/Documents/development/sacdia/sacdia-app` | `development` | `3e6502891dddaf2b98c1bab33dc1e466c705c15b` | Cambios previos ajenos (`sac_top_bar.dart`, camporee, unidades, logos). No se tocaron. |

### Archivos de esta sesión

Backend, creados:

- `src/certificate-bulk-imports/class-certificate-historical-age.ts` — criterio de edad histórica y lectura con bloqueo opcional.
- `src/certificate-bulk-imports/class-certificate-historical-age.spec.ts`
- `src/classes/field-class-threshold.ts` — default 80, corte del 30 de junio y requisito cumplido.
- `src/classes/field-class-threshold.spec.ts`
- `src/classes/field-class-threshold-config.service.ts` — lectura y guardado del porcentaje con alcance y corte.
- `src/classes/field-class-threshold-config.service.spec.ts`
- `src/classes/field-class-threshold.controller.ts`
- `src/classes/dto/update-field-class-threshold.dto.ts`
- `src/classes/field-investiture-window.ts` — default 1 oct–20 dic recortado al año; sin intersección devuelve null. Días inclusivos y quién puede editar.
- `src/classes/field-investiture-window.spec.ts`
- `src/classes/field-investiture-window-config.service.ts`
- `src/classes/field-investiture-window-config.service.spec.ts`
- `src/classes/field-investiture-window.controller.ts`
- `src/classes/field-investiture-window.controller.spec.ts` — HTTP del caso sin intersección y del rango guardado, con Prisma simulado.
- `src/classes/dto/update-investiture-window.dto.ts`
- `src/classes/district-investiture-pastors.service.ts` — cupo global, asignación por distrito, lectura por iglesia del club y candado compartido con el cambio de cupo.
- `src/classes/district-investiture-pastors.service.spec.ts`
- `src/classes/district-investiture-pastors.controller.ts`
- `src/classes/district-investiture-pastors.controller.spec.ts` — HTTP con guard y Prisma sustituidos. No verifica autenticación ni base reales.
- `test/district-investiture-pastors-postgres.e2e-spec.ts` — dos conexiones y `pg_locks` en la base aislada de loopback.
- `src/classes/dto/update-investiture-pastor-quota.dto.ts`
- `src/classes/dto/assign-district-investiture-pastor.dto.ts`
- `prisma/migrations/20260930120000_local_field_class_thresholds/migration.sql`
- `prisma/migrations/20261001130000_local_field_investiture_windows/migration.sql`
- `prisma/migrations/20261001143000_district_investiture_pastors/migration.sql`
- `src/investiture-requests/investiture-authorization-requests.service.ts` — presentar, agregar, quitar, leer y cambiar fecha. Candado de sección y año, de usuario y de enrollment.
- `src/investiture-requests/investiture-authorization-requests.service.spec.ts`
- `src/investiture-requests/investiture-authorization-requests.controller.ts`
- `src/investiture-requests/investiture-authorization-requests.controller.spec.ts` — HTTP con `JwtAuthGuard` sustituido y Prisma simulado. No verifica autenticación ni base reales. No monta el prefijo `/api/v1`.
- `src/investiture-requests/investiture-request-lock.ts` — candado del enrollment y lectura del pendiente dentro de la misma transacción.
- `src/investiture-requests/investiture-requests.module.ts`
- `src/investiture-requests/dto/present-investiture-request.dto.ts`
- `src/investiture-requests/dto/add-investiture-request-people.dto.ts`
- `src/investiture-requests/dto/change-investiture-request-dates.dto.ts`
- `test/investiture-authorization-requests-postgres.e2e-spec.ts` — carreras en la base aislada de loopback. No certifica la aplicación de la migración.
- `prisma/migrations/20261001193000_investiture_authorization_requests/migration.sql`

Backend, modificados:

- Servicios y specs de certificados (listo, envío, reenvío, aprobación de clase e institucional).
- `class-requirement-eligibility.service.ts`, `classes.service.ts`, `class-progress-scope.service.ts` y sus specs.
- `error-codes.ts` e i18n `es` / `en` / `fr` / `pt-BR`.
- `classes.module.ts` registra el porcentaje, la ventana y los pastores del distrito.
- `app.module.ts` registra `InvestitureRequestsModule` al lado de `InvestitureModule`.
- `classes.service.ts` toma el candado del enrollment dentro de la transacción de puntaje, archivo, envío y baja de evidencia.
- `evidence-review.service.ts` toma ese candado al aprobar o rechazar progreso de clase. Los honores no entran en este candado.
- `prisma/schema.prisma`

Docs de esta sesión:

- `docs/features/clases-progresivas.md`
- `docs/features/validacion-investiduras.md`
- `docs/database/SCHEMA-REFERENCE.md`
- `docs/database/schema.prisma` (modelo nuevo y relaciones)
- Este informe y `docs/reviews/investidura-autorizacion-logs/`

Revisión del diff, sin commit:

```bash
git -C /Users/abner/Documents/development/sacdia/sacdia-backend diff
git -C /Users/abner/Documents/development/sacdia/sacdia-backend status --short
git -C /Users/abner/Documents/development/sacdia diff -- docs/features docs/database docs/reviews
```

No se generaron parches. El revisor con este filesystem puede leer el árbol. No hay secretos en estos diffs.

## C. Matriz IA-01 a IA-62

Rutas relativas a `sacdia-backend/src/`. Abreviaturas: SRV = `investiture-requests/investiture-authorization-requests.service.ts`; RUL = `investiture-requests/investiture-communications.rules.ts`; COM = `investiture-requests/investiture-communications.service.ts`; LDR = `investiture-requests/investiture-communications.loader.ts`; CYC = `investiture-requests/investiture-year-close.ts`; LOCK = `investiture-requests/investiture-request-lock.ts`; REC = `investiture-requests/investiture-achievement-intent.reconciler.ts`; PAST = `investiture-requests/investiture-pastor-eligibility.ts`; DTO = `investiture-requests/dto/resolve-investiture-request.dto.ts`; CERT = `certificate-bulk-imports/certificate-bulk-imports.service.ts`; CAPP = `certificate-bulk-imports/certificate-bulk-imports-application.service.ts`; CINST = `certificate-bulk-imports/institutional-certificate-requests.service.ts`; CLIVE = `certificate-bulk-imports/class-certificate-live-authorization.ts`; CHIST = `certificate-bulk-imports/class-certificate-historical-age.ts`; INST = `certificate-bulk-imports/institutional-class-codes.ts`; THR = `classes/field-class-threshold.ts`; THRS = `classes/field-class-threshold-config.service.ts`; WIN = `classes/field-investiture-window.ts`; WINS = `classes/field-investiture-window-config.service.ts`; ELIG = `classes/class-requirement-eligibility.service.ts`; CLS = `classes/classes.service.ts`; CPM = `classes/class-progress-mutable.ts`; EVR = `evidence-review/evidence-review.service.ts`; CLUBS = `clubs/clubs.service.ts`; YCUT = `year-cut/year-cut.service.ts`; YEND = `year-end/year-end.service.ts`; EMQ = `common/email/email.queue.ts`.

Líneas verificadas con `rg -n` sobre el árbol el 2026-10-07.

| Regla | Estado en backend | Evidencia (archivo:línea) |
| --- | --- | --- |
| IA-01 | Implementado | SRV:208 (`present`), :218 (`assertMarker`), :1318 y :1333 (`INVESTITURE_REQUEST_OUTSIDE_SECTION`) |
| IA-02 | Implementado | SRV:208 (`present` acepta varios enrollments), :234 (`addPeople`), :1152 (`append`) |
| IA-03 | Implementado | SRV:629 (`resolve`, decisión por persona). Updates por persona con `status: 'PENDING'` en :766, :821, :849, :877, :932 y :955. Lo no resuelto queda `PENDING` |
| IA-04 | Implementado | SRV:1435 (`usesSingleSlot`), :1354 (uso en `acceptEnrollment`), :1466 (`findSameClassInvested`) |
| IA-05 | Implementado | SRV:1399 (`hasCrossTypeHome`), :1404 y :1442 (`cross_type_enrollment`), :1435 (`usesSingleSlot`) |
| IA-06 | Implementado | SRV:1336 (alta rechaza `INVESTIDO`), :816-818 (`resolve` deja el pendiente previo como `REMOVED` / `ALREADY_INVESTED`), :1466 (`findSameClassInvested`) |
| IA-07 | Implementado | SRV:267 (`remove`), :848-853 (rechazo humano deja de ser `PENDING`), :876-881 (rechazo del sistema), :1216 (`writePeople` vuelve a marcar) |
| IA-08 | Implementado | SRV:1306 (`acceptEnrollment`), :1364 (elegibilidad), :1377-1394 (duración). Se repite al resolver en :874 (`failsRequirements`) |
| IA-09 | Implementado | SRV:874 (`failsRequirements`), :881 y :895 (`REJECTED_BY_SYSTEM` con `INVESTITURE_SYSTEM_REJECTION_TEXT`, :69) |
| IA-10 | Implementado | SRV:629 (`resolve` investe y rechaza en la misma llamada), :651-657 (motivo obligatorio); DTO:32 |
| IA-11 | Implementado | SRV:267 (`remove`), :1601 (`assertMarker`: director, secretario, secretario-tesorero). No envía correo |
| IA-12 | Implementado | SRV:1819 (`requestLabels`), :1896-1900 (`section_name` desde `club_types`), :1904 (`personView`; el autorizador no recibe `rejection_reason`, :1940-1941). Pantallas fuera de backend |
| IA-13 | Implementado | THR:1 (`DEFAULT_CLASS_THRESHOLD_PERCENT = 80`); THRS:42 (`get`, sin fila no crea) |
| IA-14 | Implementado | ELIG:367-378 (BASIC y EXTRA aplicables; ADVANCED fuera de los requeridos para investidura) |
| IA-15 | Implementado | THR:62 (`sectionMeetsThreshold`): VALIDATED cuenta, REJECTED no |
| IA-16 | Implementado | CLS:1160 (`passing_score` en detalle y elegibilidad). Sin pantalla nueva |
| IA-17 | Implementado | CLUBS:1507 (`computeGrade` sin cambios; 70 sigue siendo B) |
| IA-18 | Implementado | SRV:1306 (`acceptEnrollment`), :1377-1394 (`INVESTITURE_DURATION_MIN_NOT_MET` / `INVESTITURE_DURATION_EXPIRED`). No llama a `expireEnrollment` |
| IA-19 | Implementado | THR:36 (`canEditFieldClassThreshold`), THRS:59 (`update`) |
| IA-20 | Implementado | SRV:208 (`present` exige fecha civil y la copia a las personas) |
| IA-21 | Implementado | SRV:234 (`addPeople` con su fecha; no reescribe a quienes ya estaban) |
| IA-22 | Implementado | SRV:1714 (`assertDateInside`) |
| IA-23 | Implementado | WIN:3 (`defaultInvestitureWindow`, null sin intersección); WINS:67 (`get`) |
| IA-24 | Implementado | WIN:51 (`canEditInvestitureWindow`); WINS:84 (`update`), :217 (`canEdit`) |
| IA-25 | Implementado | SRV:315 (`changeDates`; solo los pendientes seleccionados, updateMany en :363) |
| IA-26 | Implementado | SRV:315 (`changeDates`), :341-342 (año abierto y fecha dentro de la ventana; no reabre la ventana) |
| IA-27 | Parcial | SRV:1693 (`assertTodayAllowsPresentation`, usado en :222, :255, :679, :721 y :1248). El flujo anterior (`markInvestido`) aún no usa este predicado |
| IA-28 | Parcial | SRV:1693 (presentar, agregar y resolver); :341-342 (cambiar fecha no reabre la ventana). Mismo límite de IA-27 en el flujo anterior |
| IA-29 | Implementado | SRV:1678 (`assertYearOpen`, usado en :221, :254, :285, :341, :678 y :720). Vía nueva |
| IA-30 | Implementado | CYC:24 (`closePendingInvestitureAuthorizations`), llamado desde YEND:178 y YCUT:267 y :453; SRV:1247 (`writePeople` relee el año bajo candado) |
| IA-31 | Implementado | SRV:520 (`sectionHistory`), :2004 (`CLOSED_YEAR` en la lectura) |
| IA-32 | Implementado | YCUT:718 (`ensureNotEnrolled`, política anual existente; sin código nuevo) |
| IA-33 | Implementado | YCUT:718 (continuación anual existente; sin código nuevo) |
| IA-34 | Fuera de alcance | Unidades y finanzas, según el plan. Carpetas e inscripciones de club no se tocaron |
| IA-35 | Implementado | `investiture-requests/investiture-authorization-requests.controller.ts:185` (`GET club-sections/:sectionId/investiture-yearbook`) |
| IA-36 | Implementado | RUL:148 (`presentationRecipients`); PAST:88 (`eligiblePastorUserIds`); LDR:293 |
| IA-37 | Implementado | RUL:218 (`presentationDrafts`): dos borradores si la cuenta tiene los dos roles |
| IA-38 | Implementado | RUL:218 (`presentationDrafts`); RUL:83 (enlace `/investiture-requests/{id}`) |
| IA-39 | Implementado | SRV:1152 (`append`) llama a SRV:1208 (`recordPresentation`); COM:187 |
| IA-40 | Implementado | CPM:14 (`assertClassProgressMutable`), :34 y :48 (guardas de INVESTIDO/EXPIRED dentro de la transacción); EVR:1333 (`lockClassProgress`); CLS:1608-1612 (`submitSection`); LOCK:101 (candado de enrollment) |
| IA-41 | Implementado | SRV:743 (solo actúa sobre `PENDING`); updateMany con `status: 'PENDING'` en :766, :821, :849, :877, :932 y :955; SRV:1006 y :1027 (`INVESTITURE_REQUEST_ALREADY_RESOLVED`) |
| IA-42 | Implementado | COM:1024-1036 (`deliverOnce` → `sendInvestitureNotice`); EMQ:24 (`EMAIL_JOB_INVESTITURE_NOTICE`). No hay cron de bandeja |
| IA-43 | Implementado | RUL:406 (`reminderSchedule`), :438 (`reminderRunsDue`), :460 (`dueReminders`); LDR:157 (`scheduleFields`); COM:241 (`dispatchReminders`), :290 (`claimDayAndStage`) |
| IA-44 | Implementado | RUL:460 (`dueReminders`: pendientes acumulados, sin filtro por `created_at`) |
| IA-45 | Implementado | LDR:293 (`eligiblePastorUserIds`); RUL:460 (`dueReminders` ignora admin, super-admin, unión y división) |
| IA-46 | Implementado | RUL:460 (solicitudes con al menos un pendiente, dentro del alcance del destinatario); RUL:83 (enlace por solicitud) |
| IA-47 | Implementado | RUL:20 (texto de ventana cerrada: pedir ampliación, no editar) |
| IA-48 | Implementado | RUL:438 (`reminderRunsDue`), :460 (`dueReminders`: año inactivo, fuera de rango, sin pendientes o `CLOSED_YEAR`) |
| IA-49 | Implementado | RUL:17 (`REMINDER_RETRY_LIMIT = 5`), :697 (`reminderRetrySkipReason`), :721 (`reminderRetryDraft`); COM:903 (`claimRetry`), :930 (`freshMail`) |
| IA-50 | Implementado | RUL:438 (`reminderRunsDue`: lunes pastor, director y asistente de Campo; miércoles y viernes solo pastor) |
| IA-51 | Implementado | SRV:1131 (`class.completed` después de `INVESTIDO`), :961 (`achievement_intent_key`); REC:9 (`InvestitureAchievementIntentReconciler`) |
| IA-52 | Implementado | CHIST:50 (`evaluateClassCertificateHistoricalAge`), :186 (`assertClassCertificateHistoricalAge`) |
| IA-53 | Implementado | CERT:929 (aprobación de ítem), :103 y :686 (`downgradeInvalidReadyItems`); CAPP:292; CINST:151 y :311 |
| IA-54 | Implementado | CHIST:50 (evaluador: falta de nacimiento, mínimo, año ausente o ambiguo) |
| IA-55 | Implementado | CERT:686 (`downgradeInvalidReadyItems`), :902 (`isReady`). No reescribe acreditaciones previas |
| IA-56 | Implementado | CHIST:50 (compara solo con `minimum_age` de la clase acreditada) |
| IA-57 | Implementado | CLIVE:107 (`isCertificateAuthorizationPending`), :232 (`rejectSameYearLiveAuthorization`); llamado en CERT:930 y CINST:160 |
| IA-58 | Implementado | CLIVE:543 (`HISTORICAL_CERTIFICATE_APPLIED_REASON`; el registro pasa a `REMOVED`) |
| IA-59 | Implementado | LOCK:26 (texto «Investidura aplicada por certificado de un año anterior»); SRV:2008 (`personView` según audiencia) |
| IA-60 | Implementado | CLIVE:504 (`guardCertificateApprovalAuthorization`), llamado en CAPP:354 y CINST:320, bajo los candados de usuario y enrollment |
| IA-61 | Implementado | CLIVE:410 (`findEndedSameYearCertificatePeople`), :504 (guarda); CAPP:338 y :390 (`LATER_CERTIFICATE_ACCREDITATION_REASON`) |
| IA-62 | Implementado | INST:1 (`GM-02`, `GM-03`), :3 (`isInstitutionalInvestitureClass`); SRV:764 (`resolve` rechaza), :1279 (`writePeople`) |

La decisión central e IA-27 siguen abiertas por el flujo anterior (`markInvestido` aún puede investir fuera de ventana): corresponde a la fase 8. La interfaz (app y panel) está fuera de backend.


## D. Verificación reproducible

No se ejecutaron builds.

| Directorio | Comando | Resultado | Salida | Pruebas | Log |
| --- | --- | --- | --- | --- | --- |
| `sacdia-backend` | `./node_modules/.bin/jest src/certificate-bulk-imports/certificate-bulk-imports-application.service.spec.ts -t "blocks an Amigo certificate" --no-coverage` | Falló como se esperaba, antes del arreglo | 1 | 1 failed, 17 skipped | `docs/reviews/investidura-autorizacion-logs/0b-red-amigo.log` |
| `sacdia-backend` | jest de edad + servicios de certificado | Pasó después del arreglo | 0 | 55 passed | `.../0b-green.log` |
| `sacdia-backend` | jest de umbral, elegibilidad y listado colectivo | Pasó | 0 | 14 passed | `.../phase1.log` |
| `sacdia-backend` | jest `-t "counts a PENDING section"` en `classes.service.spec.ts` | Pasó | 0 | 1 passed, 87 skipped | `.../phase1-detail.log` |
| `sacdia-backend` | jest final de edad, certificados, umbral y elegibilidad | Pasó | 0 | 61 passed | `.../final.log` |
| `sacdia-backend` | las once suites de edad, certificados, porcentaje, ventana, elegibilidad, listado y detalle, `--runInBand --no-coverage` | Pasó | 0 | 11 suites, 208 passed (23 son de la ventana) | 2026-10-01, antes de W1 |
| `sacdia-backend` | `./node_modules/.bin/jest --runInBand --no-coverage --runTestsByPath src/classes/field-investiture-window.spec.ts` con la expectativa de cierre y el helper todavía devolviendo el año | Falló como se esperaba | 1 | 1 failed, 10 passed. Recibió `2026-01-01`–`2026-06-30` | 2026-10-01, rojo de W1 |
| `sacdia-backend` | las once suites anteriores más `src/classes/field-investiture-window.controller.spec.ts`, `--runInBand --no-coverage` | Pasó | 0 | 12 suites, 214 passed (29 son de la ventana: helper, servicio y HTTP) | 2026-10-01, después de W1 |
| `sacdia-backend` | `./node_modules/.bin/tsc --noEmit --incremental false -p tsconfig.build.json` | Pasó | 0 | sin diagnósticos | 2026-10-01, después de W1 |
| `sacdia-backend` | `./node_modules/.bin/eslint` de los seis archivos de ventana | Pasó | 0 | sin diagnósticos | 2026-10-01, después de W1 |
| `sacdia-backend` | `./node_modules/.bin/jest --runInBand --no-coverage --runTestsByPath src/classes/district-investiture-pastors.service.spec.ts` con el servicio todavía sin implementar | Falló como se esperaba | 1 | 10 failed. `not implemented` | 2026-10-01, rojo de la fase 3 |
| `sacdia-backend` | las doce suites de W1 más `district-investiture-pastors.service.spec.ts` y `district-investiture-pastors.controller.spec.ts`, `--runInBand --no-coverage` | Pasó | 0 | 14 suites, 226 passed (12 son de pastores: 10 de servicio y 2 HTTP) | 2026-10-01, fase 3 |
| `sacdia-backend` | `./node_modules/.bin/tsc --noEmit --incremental false -p tsconfig.build.json` | Pasó | 0 | sin diagnósticos | 2026-10-01, después de `prisma generate` de los pastores |
| `sacdia-backend` | `./node_modules/.bin/eslint` de los archivos nuevos de pastores y `classes.module.ts` | Pasó | 0 | sin diagnósticos | 2026-10-01, fase 3 |
| `sacdia-backend` | SQL de `20261001143000_district_investiture_pastors` en la base aislada de loopback, dentro de una transacción | Pasó y se revirtió | 0 | `to_regclass` vio las dos tablas y, tras `ROLLBACK`, las dos quedaron en null | 2026-10-01 |
| `sacdia-backend` | `./node_modules/.bin/jest --runInBand --no-coverage --testPathPatterns 'district-investiture-pastors.(service|controller).spec.ts'` | Pasó | 0 | 2 suites, 20 passed. 18 de servicio, incluidos los cuatro intercalados y las dos carreras del último cupo. 2 HTTP | 2026-10-01, P3-1 |
| `sacdia-backend` | `./node_modules/.bin/jest --config test/jest-e2e.json --runInBand --no-coverage --testPathPatterns district-investiture-pastors-postgres.e2e-spec.ts` con `SACDIA_TEST_DATABASE_URL` de loopback y nombre terminado en `_test` | Pasó | 0 | 1 suite, 7 passed | 2026-10-01, P3-1 |
| `sacdia-backend` | `./node_modules/.bin/tsc --noEmit --incremental false -p tsconfig.build.json` | Pasó | 0 | sin diagnósticos | 2026-10-01, después del candado de P3-1 |
| `sacdia-backend` | `./node_modules/.bin/eslint` del servicio, los dos specs de pastores y el e2e PostgreSQL | Pasó | 0 | sin diagnósticos | 2026-10-01, P3-1 |
| `sacdia-backend` | `./node_modules/.bin/tsc --noEmit --incremental false -p tsconfig.build.json` | Pasó | 0 | sin diagnósticos | 2026-10-01, después del modelo de ventana |
| `sacdia-backend` | eslint de los archivos nuevos de la ventana, más el módulo | Pasó | 0 | sin diagnósticos en esos archivos | 2026-10-01 |
| `sacdia-backend` | SQL de `20261001130000_local_field_investiture_windows` en la base aislada de loopback, dentro de una transacción | Pasó y se revirtió | 0 | `to_regclass` devolvió la tabla y, tras `ROLLBACK`, ya no estaba | 2026-10-01 |
| `sacdia-backend` | `jest --config ./test/jest-e2e.json --runInBand --testPathPatterns certificate-import-postgres.e2e-spec -t "keeps institutional approval"` con `SACDIA_TEST_DATABASE_URL` de loopback | Pasó | 0 | 1 passed, 9 skipped | esta sesión |
| `sacdia-backend` | `./node_modules/.bin/jest --runInBand --no-coverage --testPathPatterns 'investiture-authorization-requests.(service|controller).spec.ts'` | Pasó | 0 | 2 suites, 30 passed. 27 de servicio y 3 HTTP | 2026-10-01, fase 4 backend |
| `sacdia-backend` | `./node_modules/.bin/jest --runInBand --no-coverage --testPathPatterns classes.service.spec.ts` | Pasó | 0 | 1 suite, 90 passed. Incluye el bloqueo de progreso del enrollment pendiente y que otro enrollment de la misma persona sigue | 2026-10-01, fase 4 backend |
| `sacdia-backend` | `./node_modules/.bin/jest --config test/jest-e2e.json --runInBand --no-coverage --testPathPatterns investiture-authorization-requests-postgres.e2e-spec.ts` con `SACDIA_TEST_DATABASE_URL` de loopback y nombre terminado en `_test` | Pasó | 0 | 1 suite, 3 passed. Dos altas, quitar contra cambio de fecha, y retiro de un pendiente ya investido | 2026-10-01, fase 4 backend |
| `sacdia-backend` | `./node_modules/.bin/tsc --noEmit --incremental false -p tsconfig.build.json` | Pasó | 0 | sin diagnósticos | 2026-10-01, después de `prisma generate` de la solicitud |
| `sacdia-backend` | `./node_modules/.bin/eslint` de `src/investiture-requests`, `src/app.module.ts`, `src/common/errors/error-codes.ts` y el e2e PostgreSQL de la solicitud | Pasó | 0 | sin diagnósticos en esos archivos. `classes.service.ts` conserva 30 avisos Prettier anteriores; las líneas nuevas del bloqueo no están entre ellos | 2026-10-01, fase 4 backend |
| `sacdia-backend` | `./node_modules/.bin/jest --no-coverage --testPathPatterns 'investiture-authorization-requests.(service\|controller).spec\|classes.service.spec\|evidence-review.service.spec'` | Pasó | 0 | 4 suites, 142 passed. Incluye duración plurianual, clase cruzada con membresía solo en GM, una cabecera para dos personas, y el bloqueo de envío, archivo, baja, aprobación y rechazo | 2026-10-02, corrección P4-1 a P4-4 |
| `sacdia-backend` | `./node_modules/.bin/jest --config ./test/jest-e2e.json --no-coverage --forceExit --testPathPatterns investiture-authorization-requests-postgres` con `SACDIA_TEST_DATABASE_URL` de loopback y nombre terminado en `_test` | Pasó | 0 | 1 suite, 7 passed. Las 3 anteriores más duración de dos años, clase cruzada, dos personas en una cabecera, y presentar contra una escritura de progreso con espera en `pg_locks` | 2026-10-02, corrección P4-1 a P4-4 |
| `sacdia-backend` | `./node_modules/.bin/tsc --noEmit --incremental false -p tsconfig.build.json` | Pasó | 0 | sin diagnósticos | 2026-10-02, después de P4-1 a P4-4 |
| `sacdia-backend` | `./node_modules/.bin/eslint` de `src/investiture-requests`, el e2e PostgreSQL de la solicitud y `evidence-review.service.spec.ts` | Pasó | 0 | sin diagnósticos en esos archivos. `classes.service.ts` y `classes.service.spec.ts` conservan avisos Prettier anteriores; las líneas nuevas de esta corrección no se reformatearon en bloque | 2026-10-02, corrección P4-1 a P4-4 |
| `sacdia-backend` | `./node_modules/.bin/jest --no-coverage --testPathPatterns investiture-authorization-requests.service.spec` | Pasó | 0 | 1 suite, 34 passed. Incluye el rechazo al agregar a la cabecera vacía, la reutilización cuando es la única y la carrera de agregar contra presentar | 2026-10-02, vía residual P4-4 |
| `sacdia-backend` | `./node_modules/.bin/jest --config ./test/jest-e2e.json --no-coverage --forceExit --testPathPatterns investiture-authorization-requests-postgres` con `SACDIA_TEST_DATABASE_URL` de loopback y nombre terminado en `_test` | Pasó | 0 | 1 suite, 9 passed. Las 7 anteriores más la secuencia Ana/Bruno y la carrera de `addPeople` contra `present` | 2026-10-02, vía residual P4-4 |
| `sacdia-backend` | `./node_modules/.bin/tsc --noEmit --incremental false -p tsconfig.build.json` | Pasó | 0 | sin diagnósticos | 2026-10-02, después de `INVESTITURE_REQUEST_STALE` |
| `sacdia-backend` | `./node_modules/.bin/eslint` de `src/investiture-requests`, `src/common/errors/error-codes.ts` y el e2e PostgreSQL de la solicitud | Pasó | 0 | sin diagnósticos en esos archivos | 2026-10-02, vía residual P4-4 |
| `sacdia-backend` | `./node_modules/.bin/jest --no-coverage --testPathPatterns investiture-authorization-requests.service.spec` | Pasó | 0 | 1 suite, 45 passed. Incluye territorio, ventana, rechazo del sistema, carrera de autorizar contra rechazar, quitar y cierre, y un solo `class.completed` | 2026-10-02, fase 5 backend |
| `sacdia-backend` | `./node_modules/.bin/jest --no-coverage --testPathPatterns investiture-authorization-requests.controller.spec` | Pasó | 0 | 1 suite, 3 passed. HTTP con guard y Prisma simulados. No cubre la resolución | 2026-10-02, fase 5 backend |
| `sacdia-backend` | `./node_modules/.bin/jest --config ./test/jest-e2e.json --no-coverage --forceExit --testPathPatterns investiture-authorization-requests-postgres` con `SACDIA_TEST_DATABASE_URL` de loopback y nombre terminado en `_test` | Pasó | 0 | 1 suite, 17 passed. Las 9 anteriores más autorización el 10 de diciembre, roles, ventana ampliada, año vencido, rechazo parcial del sistema, motivo humano y las tres carreras | 2026-10-02, fase 5 backend |
| `sacdia-backend` | `./node_modules/.bin/tsc --noEmit --incremental false -p tsconfig.build.json` | Pasó | 0 | sin diagnósticos | 2026-10-02, fase 5 backend |
| `sacdia-backend` | `./node_modules/.bin/eslint --fix` de `src/investiture-requests`, el DTO de resolución y el e2e PostgreSQL de la solicitud | Pasó | 0 | sin diagnósticos en esos archivos | 2026-10-02, fase 5 backend |
| `sacdia-backend` | `./node_modules/.bin/jest --no-coverage --testPathPatterns investiture-authorization-requests.service.spec` | Pasó | 0 | 1 suite, 50 passed. Las 45 anteriores más año, ventana y pastor cerrados durante la espera, el último día de la ventana, y la recuperación de `class.completed` | 2026-10-02, corrección P5-1 y P5-2 |
| `sacdia-backend` | `./node_modules/.bin/jest --no-coverage --testPathPatterns investiture-authorization-requests.controller.spec` | Pasó | 0 | 1 suite, 3 passed. HTTP con guard y Prisma simulados. No cubre la resolución | 2026-10-02, corrección P5-1 y P5-2 |
| `sacdia-backend` | `./node_modules/.bin/jest --config ./test/jest-e2e.json --no-coverage --forceExit --testPathPatterns investiture-authorization-requests-postgres` con `SACDIA_TEST_DATABASE_URL` de loopback y nombre terminado en `_test` | Pasó | 0 | 1 suite, 21 passed. Las 17 anteriores más las tres esperas en `pg_locks`, el cambio de ventana retenido hasta después de la escritura, la recuperación de un solo `class.completed` y la ausencia del evento al rechazar, quitar o cerrar | 2026-10-02, corrección P5-1 y P5-2 |
| `sacdia-backend` | `./node_modules/.bin/tsc --noEmit --incremental false -p tsconfig.build.json` | Pasó | 0 | sin diagnósticos | 2026-10-02, corrección P5-1 y P5-2 |
| `sacdia-backend` | `./node_modules/.bin/eslint --fix` de los archivos de esta corrección: solicitud, logros, ventana, pastores, fin de año, catálogo de años y el e2e PostgreSQL | Pasó | 0 | sin diagnósticos en esos archivos | 2026-10-02, corrección P5-1 y P5-2 |
| `sacdia-backend` | `./node_modules/.bin/jest --no-coverage --testPathPatterns investiture-authorization-requests.service.spec` | Pasó | 0 | 1 suite, 53 passed. Las 50 anteriores más el cruce de medianoche al final de la ventana y del año, y la entrega de la intención con el año cerrado sin volver a resolver | 2026-10-05, residuos P5-1, P5-2 y P5-3 |
| `sacdia-backend` | `./node_modules/.bin/jest --no-coverage --testPathPatterns investiture-achievement-intent.reconciler.spec` | Pasó | 0 | 1 suite, 1 passed. Al arrancar llama a la reconciliación y no a `resolve` | 2026-10-05, residuos P5-1, P5-2 y P5-3 |
| `sacdia-backend` | `./node_modules/.bin/jest --no-coverage --testPathPatterns achievements.service.spec` | Pasó | 0 | 1 suite, 31 passed. Incluye el validador real de BullMQ: la clave con `:` se rechaza, el `jobId` derivado se acepta, y dos reintentos dejan una fila y una evaluación | 2026-10-05, residuos P5-1, P5-2 y P5-3 |
| `sacdia-backend` | `./node_modules/.bin/jest --no-coverage --testPathPatterns field-investiture-window.controller.spec` | Pasó | 0 | 1 suite, 2 passed. El doble de Prisma ahora tiene `$transaction` y `$executeRaw`. `opens only the range an authorized editor saves` responde 200 | 2026-10-05, residuos P5-1, P5-2 y P5-3 |
| `sacdia-backend` | `./node_modules/.bin/jest --config ./test/jest-e2e.json --no-coverage --forceExit --testPathPatterns investiture-authorization-requests-postgres` con `SACDIA_TEST_DATABASE_URL` de loopback y nombre terminado en `_test` | Pasó | 0 | 1 suite, 24 passed. Las 21 anteriores más las dos medianoches en `pg_locks`, la reconciliación con el año cerrado y una sola evaluación tras el fallo de cola | 2026-10-05, residuos P5-1, P5-2 y P5-3 |
| `sacdia-backend` | `./node_modules/.bin/tsc --noEmit --incremental false -p tsconfig.build.json` | Pasó | 0 | sin diagnósticos | 2026-10-05, residuos P5-1, P5-2 y P5-3 |
| `sacdia-backend` | `./node_modules/.bin/eslint` de los archivos de esta corrección, con `--fix` solo donde Prettier lo pedía | Pasó | 0 | sin diagnósticos en esos archivos | 2026-10-05, residuos P5-1, P5-2 y P5-3 |
| `sacdia-backend` | `./node_modules/.bin/jest --no-coverage --testPathPatterns investiture-authorization-requests.service.spec` | Pasó | 0 | 1 suite, 54 passed. Las 53 anteriores más la reactivación de un solo trabajo `failed` tras cerrar el año: dos reconciliaciones, un `retry` | 2026-10-05, residuo P5-2 de trabajo `failed` |
| `sacdia-backend` | `./node_modules/.bin/jest --no-coverage --testPathPatterns investiture-achievement-intent.reconciler.spec` | Pasó | 0 | 1 suite, 1 passed | 2026-10-05, residuo P5-2 de trabajo `failed` |
| `sacdia-backend` | `./node_modules/.bin/jest --no-coverage --testPathPatterns achievements.service.spec` | Pasó | 0 | 1 suite, 31 passed. La ejecución conjunta, por el punto de ese patrón, también corrió `admin-achievements.service.spec` (21 passed). No es parte de esta corrección | 2026-10-05, residuo P5-2 de trabajo `failed` |
| `sacdia-backend` | `./node_modules/.bin/jest --no-coverage --testPathPatterns achievements-failed-job.spec` | Pasó | 0 | 1 suite, 1 passed. `redis-server` exclusivo en loopback, cola y worker reales de BullMQ 5.81. Tres fallos de lectura, backoff real, dos reconciliaciones: una fila, `processed=true`, trabajo `completed`, `attemptsMade` 1. Sin logro coincidente, así que no hay concesión ni notificación | 2026-10-05, residuo P5-2 de trabajo `failed` |
| `sacdia-backend` | `./node_modules/.bin/jest --no-coverage --testPathPatterns field-investiture-window.controller.spec` | Pasó | 0 | 1 suite, 2 passed | 2026-10-05, residuo P5-2 de trabajo `failed` |
| `sacdia-backend` | `./node_modules/.bin/jest --config ./test/jest-e2e.json --no-coverage --forceExit --testPathPatterns investiture-authorization-requests-postgres` con `SACDIA_TEST_DATABASE_URL` de loopback y nombre terminado en `_test` | Pasó | 0 | 1 suite, 24 passed. Incluye la recuperación con el año cerrado cuando todavía no hay trabajo `failed` | 2026-10-05, residuo P5-2 de trabajo `failed` |
| `sacdia-backend` | `./node_modules/.bin/tsc --noEmit --incremental false -p tsconfig.build.json` | Pasó | 0 | sin diagnósticos. Para llegar ahí se estrechó `upload_status` al enum de Prisma y el nulo de una lectura en `certificate-import-files.service.ts`. Ese archivo ya estaba modificado y no forma parte del flujo de investidura | 2026-10-05, residuo P5-2 de trabajo `failed` |
| `sacdia-backend` | `./node_modules/.bin/eslint` de logros, la solicitud, el reconciliador, el controlador de ventana y el archivo de certificados tocado solo en tipos | Pasó | 0 | sin diagnósticos en esos archivos | 2026-10-05, residuo P5-2 de trabajo `failed` |
| `sacdia-backend` | `./node_modules/.bin/jest --no-coverage --testPathPatterns investiture-communications.rules.spec` | Pasó | 0 | 1 suite, 12 passed. Destinatarios y roles, segundo lote, privacidad del motivo, 10:00 por zona, solicitud antigua, ventana cerrada, año cerrado, reintento y reclamo concurrente | 2026-10-05, fase 6 |
| `sacdia-backend` | `./node_modules/.bin/jest --no-coverage --testPathPatterns investiture-authorization-requests.service.spec` | Pasó | 0 | 1 suite, 56 passed. Las 54 anteriores más el correo al confirmar el grupo, sin correo al quitar, y la notificación solo en la decisión nueva | 2026-10-05, fase 6 |
| `sacdia-backend` | `./node_modules/.bin/jest --no-coverage --testPathPatterns email.service.spec` | Pasó | 0 | 1 suite, 9 passed. El aviso de investidura entra a la cola con `required` y un `jobId` estable | 2026-10-05, fase 6 |
| `sacdia-backend` | `./node_modules/.bin/jest --config ./test/jest-e2e.json --no-coverage --forceExit --testPathPatterns investiture-authorization-requests-postgres` con `SACDIA_TEST_DATABASE_URL` de loopback y nombre terminado en `_test` | Pasó | 0 | 1 suite, 25 passed. Las 24 anteriores más una fila por rol y el rechazo de la fila repetida | 2026-10-05, fase 6 |
| `sacdia-backend` | `./node_modules/.bin/tsc --noEmit --incremental false -p tsconfig.build.json` | Pasó | 0 | sin diagnósticos | 2026-10-05, fase 6 |
| `sacdia-backend` | `./node_modules/.bin/eslint --fix` de los archivos nuevos de avisos y el cron, y revisión posterior | Pasó | 0 | Prettier en esos archivos; sin diagnósticos después | 2026-10-05, fase 6 |
| `sacdia-backend` | `./node_modules/.bin/jest --no-coverage --testPathPatterns 'investiture-communications.delivery.spec\|investiture-communications.rules.spec\|investiture-authorization-requests.service.spec\|email.service.spec'` | Pasó | 0 | 4 suites, 84 passed. Las 77 anteriores más 5 de entrega y 2 de reglas: intención durable, pastor retirado, ventana por defecto, bandeja y claim vencido | 2026-10-05, corrección P6-1 a P6-5 |
| `sacdia-backend` | `./node_modules/.bin/jest --no-coverage --forceExit --testPathPatterns investiture-mail-redis.spec` | Pasó | 0 | El archivo importa la spec de entrega, así que Jest reportó 7. Las dos propias usan `redis-server` en un puerto de loopback distinto de 6379, cola y worker reales, y `renderTemplate` sustituido por el desajuste ya existente de React. Un proveedor que falla cinco veces deja `failed` y, tras reiniciar el worker, un solo mensaje aceptado. Un acuse que falla después de aceptar no abre otro mensaje. No hubo correo real ni acuse de Resend | 2026-10-05, corrección P6-1 a P6-5 |
| `sacdia-backend` | `./node_modules/.bin/jest --config ./test/jest-e2e.json --no-coverage --forceExit --testPathPatterns investiture-authorization-requests-postgres` con `SACDIA_TEST_DATABASE_URL` de loopback y nombre terminado en `_test` | Pasó | 0 | 1 suite, 25 passed. El esquema de prueba incluye `queued`, el lease y la clave de bandeja | 2026-10-05, corrección P6-1 a P6-5 |
| `sacdia-backend` | `./node_modules/.bin/tsc --noEmit --incremental false -p tsconfig.build.json` | Pasó | 0 | sin diagnósticos. `prisma generate` regeneró el cliente 7.9.1; no se cambió la versión | 2026-10-05, corrección P6-1 a P6-5 |
| `sacdia-backend` | `./node_modules/.bin/eslint` de comunicaciones, dispatch, reglas, solicitud, correo, Resend y notificaciones | Pasó | 0 | sin diagnósticos en esos archivos | 2026-10-05, corrección P6-1 a P6-5 |
| `sacdia-backend` | `NODE_ENV=test DOTENV_CONFIG_PATH=/dev/null node ../docs/reviews/investidura-autorizacion-review-evidence/p6-dispatch-probe.cjs` | El probe sale 1 | 1 | No se modificó el probe. El primer escenario ya no reproduce la pérdida: quedan 2 filas de intención y la aserción `2 !== 0` detiene el archivo. No vuelve a ejercer P6-2 a P6-5. No es aceptación de la fase | 2026-10-05, corrección P6-1 a P6-5 |
| `sacdia-backend` | `./node_modules/.bin/jest --no-coverage --testPathPatterns 'investiture-communications.delivery.spec\|investiture-communications.rules.spec\|investiture-authorization-requests.service.spec\|email.service.spec'` | Pasó | 0 | 4 suites, 87 passed. Las 84 anteriores más la identidad estable del grupo y dos de acuse: el reintento conserva el contenido aceptado y, pasadas 24 horas, queda `uncertain` sin un segundo envío | 2026-10-06, residuos P6-1 y P6-2 |
| `sacdia-backend` | `./node_modules/.bin/jest --no-coverage --forceExit --testPathPatterns investiture-mail-redis.spec` | Pasó | 0 | El archivo importa la spec de entrega, así que Jest reportó 9. Las dos propias siguen en `redis-server` de loopback distinto de 6379, con `renderTemplate` sustituido por el desajuste ya existente de React. Cinco fallos y un reinicio dejan un solo mensaje aceptado. Un acuse perdido dentro de 24 horas repite la misma clave. No hubo correo real ni acuse de Resend | 2026-10-06, residuos P6-1 y P6-2 |
| `sacdia-backend` | `./node_modules/.bin/jest --config ./test/jest-e2e.json --no-coverage --forceExit --testPathPatterns investiture-authorization-requests-postgres` con `SACDIA_TEST_DATABASE_URL` de loopback y nombre terminado en `_test` | Pasó | 0 | 1 suite, 26 passed. La misma identidad dos veces no aborta la transacción. Quitar y volver a presentar, en la misma cabecera y en otra, y volver a presentar después de un rechazo, dejan dos intenciones y la fila de negocio | 2026-10-06, residuos P6-1 y P6-2 |
| `sacdia-backend` | `./node_modules/.bin/tsc --noEmit --incremental false -p tsconfig.build.json` | Pasó | 0 | sin diagnósticos. El cliente Prisma 7.9.1 ya estaba regenerado por el valor `uncertain`; no se cambió la versión | 2026-10-06, residuos P6-1 y P6-2 |
| `sacdia-backend` | `./node_modules/.bin/eslint` de comunicaciones, reglas, solicitud, procesador, gate y el e2e de PostgreSQL | Pasó | 0 | sin diagnósticos en esos archivos | 2026-10-06, residuos P6-1 y P6-2 |
| `sacdia-backend` | `NODE_ENV=test DOTENV_CONFIG_PATH=/dev/null node ../docs/reviews/investidura-autorizacion-review-evidence/p6r1-acceptance-probe.cjs` | El probe sale 1 | 1 | No se modificó el probe. Nueve aceptaciones pasan, incluidas P6-3, P6-4 y P6-5. La recuperación parcial queda en 1 envío al pastor y la aserción `1 !== 2` detiene el archivo antes de los dos acuses. No es aceptación de la fase | 2026-10-06, residuos P6-1 y P6-2 |
| `sacdia-backend` | `./node_modules/.bin/jest --no-coverage --forceExit --testPathPatterns 'investiture-communications.delivery.spec\|investiture-communications.rules.spec\|investiture-authorization-requests.service.spec\|email.service.spec'` | Pasó | 0 | 4 suites, 88 passed. Las 87 anteriores más el reintento congelado: pastor retirado, director trasladado, año cerrado y cero pendientes quedan `skipped` y el proveedor no acepta un segundo correo | 2026-10-06, regresión P6-3 |
| `sacdia-backend` | `./node_modules/.bin/jest --no-coverage --forceExit --testPathPatterns investiture-mail-redis.spec` | Pasó | 0 | El archivo importa la spec de entrega, así que Jest reportó 10. Las dos propias siguen en `redis-server` de loopback distinto de 6379, con `renderTemplate` sustituido. No hubo correo real | 2026-10-06, regresión P6-3 |
| `sacdia-backend` | `./node_modules/.bin/tsc --noEmit --incremental false -p tsconfig.build.json` | Pasó | 0 | sin diagnósticos | 2026-10-06, regresión P6-3 |
| `sacdia-backend` | `./node_modules/.bin/eslint` del procesador, el gate, el servicio de comunicaciones y la spec de entrega | Pasó | 0 | sin diagnósticos en esos archivos | 2026-10-06, regresión P6-3 |
| `sacdia-backend` | `NODE_ENV=test DOTENV_CONFIG_PATH=/dev/null node ../docs/reviews/investidura-autorizacion-review-evidence/p6r2-acceptance-probe.cjs` | El probe sale 1 | 1 | No se modificó el probe. Doce aceptaciones pasan, incluidos P6-1, P6-2, P6-4 y P6-5. El primer caso de P6-3 queda en 0 aceptaciones y la aserción `0 !== 1` detiene el archivo. No es aceptación de la fase | 2026-10-06, regresión P6-3 |
| `sacdia-backend` | `./node_modules/.bin/jest --no-coverage --forceExit --testPathPatterns 'investiture-communications.delivery.spec\|investiture-communications.rules.spec\|investiture-authorization-requests.service.spec\|email.service.spec'` | Pasó | 0 | 4 suites, 89 passed. Las 88 anteriores más el pastor con dos distritos: al retirar uno, el reintento congelado queda `skipped`, el cuerpo sigue citando el distrito retirado y el proveedor no lo recibe | 2026-10-06, residuo parcial P6-3 |
| `sacdia-backend` | `./node_modules/.bin/jest --no-coverage --forceExit --testPathPatterns investiture-mail-redis.spec` | Pasó | 0 | El archivo importa la spec de entrega, así que Jest reportó 11. Las dos propias siguen en `redis-server` de loopback distinto de 6379, con `renderTemplate` sustituido. No hubo correo real | 2026-10-06, residuo parcial P6-3 |
| `sacdia-backend` | `./node_modules/.bin/tsc --noEmit --incremental false -p tsconfig.build.json` | Pasó | 0 | sin diagnósticos | 2026-10-06, residuo parcial P6-3 |
| `sacdia-backend` | `./node_modules/.bin/eslint` del gate, el servicio de comunicaciones y la spec de entrega | Pasó | 0 | sin diagnósticos en esos archivos | 2026-10-06, residuo parcial P6-3 |
| `sacdia-backend` | `NODE_ENV=test DOTENV_CONFIG_PATH=/dev/null node ../docs/reviews/investidura-autorizacion-review-evidence/p6r3-acceptance-probe.cjs` | El probe sale 1 | 1 | No se modificó el probe. Veinte aceptaciones pasan, incluidos los cuatro bloqueos totales, los estados terminales y el límite de 24 horas. El caso de un distrito entre dos queda en 0 aceptaciones y la aserción `0 !== 1` detiene el archivo. No es aceptación de la fase | 2026-10-06, residuo parcial P6-3 |
| `sacdia-backend` | `./node_modules/.bin/jest --no-coverage --forceExit --testPathPatterns 'investiture-communications.delivery.spec\|investiture-communications.rules.spec\|investiture-authorization-requests.service.spec\|email.service.spec'` | Pasó | 0 | 4 suites, 90 passed. Las 89 anteriores más el retiro de un distrito durante el render: el cuerpo y el alcance guardados citan a Bruno, el borrador posterior ya no, el reintento queda `skipped` con 0 aceptaciones y la clave no cambia | 2026-10-06, instantánea cuerpo/alcance P6-3 |
| `sacdia-backend` | `./node_modules/.bin/jest --no-coverage --forceExit --testPathPatterns investiture-mail-redis.spec` | Pasó | 0 | El archivo importa la spec de entrega, así que Jest reportó 12. Las dos propias siguen en `redis-server` de loopback distinto de 6379, con `renderTemplate` sustituido. No hubo correo real | 2026-10-06, instantánea cuerpo/alcance P6-3 |
| `sacdia-backend` | `./node_modules/.bin/tsc --noEmit --incremental false -p tsconfig.build.json` | Pasó | 0 | sin diagnósticos | 2026-10-06, instantánea cuerpo/alcance P6-3 |
| `sacdia-backend` | `./node_modules/.bin/eslint` del procesador, el gate, el servicio de comunicaciones y la spec de entrega | Pasó | 0 | sin diagnósticos en esos archivos | 2026-10-06, instantánea cuerpo/alcance P6-3 |
| `sacdia-backend` | `NODE_ENV=test DOTENV_CONFIG_PATH=/dev/null node ../docs/reviews/investidura-autorizacion-review-evidence/p6r4-acceptance-probe.cjs` | El probe sale 1 | 1 | No se modificó el probe. Veintiuna aceptaciones pasan, incluido el retiro parcial posterior al fallo. La aserción de la línea 178 espera que el alcance no cite a Bruno y ahora sí lo cita, así que el archivo se detiene ahí. No es aceptación de la fase | 2026-10-06, instantánea cuerpo/alcance P6-3 |
| `sacdia-backend` | `./node_modules/.bin/jest --no-coverage --forceExit --testPathPatterns 'investiture-year-close.spec\|investiture-history.spec\|year-end.service.spec\|year-cut.service.spec\|investiture-communications.delivery.spec'` | Pasó | 0 | 5 suites, 42 passed. El cierre administrativo y el corte dejan el pendiente en `CLOSED_YEAR`, no tocan al investido, no crean otra solicitud y no escriben el texto de falta de requisitos. Un corte ya completado no vuelve a inscribir. El historial conserva clase y año. El anuario queda en la sección. Una persona `CLOSED_YEAR` no recibe recordatorio. Prisma simulado, sin correo real | 2026-10-06, fase 7 cierre anual |
| `sacdia-backend` | `./node_modules/.bin/jest --no-coverage --forceExit --testPathPatterns 'investiture-authorization-requests.service.spec\|year-cut-cron.service.spec'` | Pasó | 0 | 2 suites, 59 passed. El cambio de candado no alteró la solicitud. El cron sigue sin llamar a `closeYear` | 2026-10-06, fase 7 cierre anual |
| `sacdia-backend` | `./node_modules/.bin/jest --no-coverage --forceExit --testPathPatterns 'investiture-year-close.spec\|investiture-history.spec\|year-end.service.spec\|year-cut.service.spec'` | Pasó | 0 | 4 suites, 31 passed, después del formato. Misma cobertura de cierre, historial y anuario | 2026-10-06, fase 7 cierre anual |
| `sacdia-backend` | `./node_modules/.bin/tsc --noEmit --incremental false -p tsconfig.build.json` | Pasó | 0 | sin diagnósticos | 2026-10-06, fase 7 cierre anual |
| `sacdia-backend` | `./node_modules/.bin/eslint --no-fix` del cierre, el historial, la solicitud, el fin de año y el corte | Pasó | 0 | sin diagnósticos en esos archivos | 2026-10-06, fase 7 cierre anual |
| `sacdia-backend` | `node node_modules/jest/bin/jest.js --no-coverage --testPathPatterns 'investiture-history.spec\|investiture-year-close.spec\|year-cut.service.spec\|year-end.service.spec'` | Pasó | 0 | 4 suites, 33 passed. El corte incluye un club cuyo único pendiente es una solicitud de un año terminado, con transición ya completa y también sin cargos. No reinscribe ni crea una solicitud del año siguiente. El anuario deja la clase de Conquistadores en su sección y la de Guías Mayores en la suya. Prisma simulado | 2026-10-06, correcciones P7-1 a P7-3 |
| `sacdia-backend` | `node node_modules/jest/bin/jest.js --no-coverage --testPathPatterns 'investiture-authorization-requests.service.spec\|year-cut-cron.service.spec\|investiture-communications.delivery.spec'` | Pasó | 0 | 3 suites, 70 passed. La relectura del año no rompió presentar, agregar ni los recordatorios | 2026-10-06, correcciones P7-1 a P7-3 |
| `sacdia-backend` | `node node_modules/jest/bin/jest.js --config ./test/jest-e2e.json --testPathPatterns investiture-authorization-requests-postgres --runInBand --forceExit` | Pasó | 0 | 1 suite, 34 passed. PostgreSQL aislado. Presentar y agregar, sin pendientes iniciales, quedan `CLOSED_YEAR` si el cierre administrativo o el corte ganan el candado, y se rechazan si el año ya quedó inactivo. Un club con transición completa y otro sin otra actividad de corte cierran el pendiente, conservan `INVESTED` y no crean solicitud del año siguiente. El anuario separa la clase cruzada. No certifica HTTP, JWT ni la aplicación de migraciones | 2026-10-06, correcciones P7-1 a P7-3 |
| `sacdia-backend` | `npx tsc --noEmit --incremental false -p tsconfig.build.json` | Pasó | 0 | sin diagnósticos | 2026-10-06, correcciones P7-1 a P7-3 |
| `sacdia-backend` | `npx eslint` del cierre, la solicitud, el historial, el fin de año, el corte y el e2e de solicitudes | Pasó | 0 | sin diagnósticos en esos archivos | 2026-10-06, correcciones P7-1 a P7-3 |
| `sacdia-backend` | `node node_modules/jest/bin/jest.js --no-coverage --testPathPatterns 'investiture-authorization-requests.service.spec\|investiture-history.spec\|investiture-year-close.spec\|year-cut.service.spec\|year-end.service.spec\|year-cut-cron.service.spec\|investiture-communications.delivery.spec'` | Pasó | 0 | 7 suites, 103 passed. Sin hora explícita el reloj sigue siendo el de la entrada en estas pruebas simuladas; no cruzan medianoche | 2026-10-06, residuo temporal P7-1 |
| `sacdia-backend` | `node node_modules/jest/bin/jest.js --config ./test/jest-e2e.json --testPathPatterns investiture-authorization-requests-postgres --runInBand --forceExit` | Pasó | 0 | 1 suite, 38 passed. PostgreSQL aislado. Presentar y agregar, sin `now`, esperan el candado de sección y el reloj inyectado pasa de 20 a 21 de diciembre y de 31 de diciembre a 1 de enero. No queda `PENDING` ni intención de presentación. Las carreras ya aceptadas de cierre y corte siguen pasando | 2026-10-06, residuo temporal P7-1 |
| `sacdia-backend` | `npx tsc --noEmit --incremental false -p tsconfig.build.json` | Pasó | 0 | sin diagnósticos | 2026-10-06, residuo temporal P7-1 |
| `sacdia-backend` | `npx eslint` de la solicitud y el e2e de solicitudes | Pasó | 0 | sin diagnósticos en esos archivos | 2026-10-06, residuo temporal P7-1 |

Tipo de prueba: unidad con Prisma simulado, HTTP de Nest con Prisma simulado y guards sustituidos para la ventana, el cupo de pastores y la solicitud, una prueba PostgreSQL aislada de la aprobación institucional, otra del candado de pastores y otra de las carreras de la solicitud. Esas pruebas HTTP no verifican autenticación ni base de datos reales. La de pastores y la de la solicitud en PostgreSQL sí usan la base aislada y no pasan por HTTP ni por el guard. El porcentaje no tiene prueba HTTP ni de UI. El guard admite unión y división por el alias de `director-lf`; en el porcentaje el servicio los rechaza, en la ventana les deja leer y no guardar, y en los pastores la unión asigna dentro de su alcance y la división no. La solicitud no usa `GlobalRolesGuard`: el cargo de sección se resuelve en el servicio.

Rojo: la aprobación del certificado Amigo 2025 (nacimiento 2016-01-01, mínimo 10) resolvió `APPROVED`. Verde: esa aprobación rechaza `CERTIFICATE_IMPORT_AGE_BELOW_MINIMUM` y no escribe enrollment ni historial.

ESLint sobre los archivos tocados sigue marcando Prettier en líneas anteriores a esta corrección (`classes.service.ts` no se reformateó; bloques viejos de institucional, del listado y del e2e). No se aplicó `--fix` al archivo completo. Se quitó un cast que el linter marcó como innecesario en el rechazo institucional.

### No ejecutado

- Unicidad de solicitudes cubierta en unidad y en la base aislada para dos altas de la misma persona. El cierre anual no está en esta pasada. La prueba PostgreSQL de certificados cubre el bloqueo de la aprobación, no un cambio de nacimiento mientras ese bloqueo espera.
- El cierre anual no está en esta pasada.
- Suites completas de investidura, app y admin. La app no tiene la pantalla de esta solicitud y el panel no tiene la de autorizar.
- Builds.
- No se envió correo a un proveedor real. Las pruebas de fase 6 usan un puerto de correo simulado. No hizo falta Redis para esas pruebas de unidad. El cron de recordatorios no se ejecutó contra un reloj de producción.
- Prueba HTTP del porcentaje. El predicado de la ventana no está conectado a las rutas del pipeline anterior. El HTTP de la ventana, el de los pastores y el de la solicitud cubren respuestas con guards sustituidos y sin `AppModule`, base ni `.env`. Esas pruebas pegan al controlador sin el prefijo `/api/v1` y no verifican autenticación ni base de datos reales. La prueba PostgreSQL de la solicitud no certifica que la migración quedó aplicada: `prepareAnnualCycleDatabase` borra el esquema `public` de esa base aislada y lo reconstruye con `prisma migrate diff`. Ese diff no aplica las llaves ni los índices únicos parciales que viven solo en el SQL. El e2e crea esos dos índices en esa base de prueba. La elegibilidad va simulada en ese e2e.

Fallos preexistentes: no se corrió la suite completa, así que no hay lista nueva de fallos ajenos. Los cambios de la app listados arriba son ajenos y no se ejecutaron sus tests.

## E. Contratos, datos y operación

Endpoints nuevos:

- `GET /api/v1/local-fields/:localFieldId/class-thresholds/:ecclesiasticalYearId`
- `PATCH /api/v1/local-fields/:localFieldId/class-thresholds/:ecclesiasticalYearId`
- `GET /api/v1/local-fields/:localFieldId/investiture-windows/:ecclesiasticalYearId`
- `PATCH /api/v1/local-fields/:localFieldId/investiture-windows/:ecclesiasticalYearId`
- `GET /api/v1/investiture-pastor-quota`
- `PATCH /api/v1/investiture-pastor-quota`
- `GET /api/v1/districts/:districtId/investiture-pastors`
- `POST /api/v1/districts/:districtId/investiture-pastors`
- `DELETE /api/v1/districts/:districtId/investiture-pastors/:userId`
- `GET /api/v1/clubs/:clubId/investiture-authorizers`
- `POST /api/v1/club-sections/:sectionId/investiture-requests`
- `GET /api/v1/club-sections/:sectionId/investiture-requests?ecclesiastical_year_id=`
- `POST /api/v1/investiture-requests/:requestId/people`
- `DELETE /api/v1/investiture-requests/:requestId/people/:personId`
- `PATCH /api/v1/investiture-requests/:requestId/dates`

Errores nuevos:

- `CERTIFICATE_IMPORT_BIRTHDAY_REQUIRED`
- `CERTIFICATE_IMPORT_CLASS_MINIMUM_AGE_REQUIRED`
- `CERTIFICATE_IMPORT_AGE_BELOW_MINIMUM`
- `CLASS_THRESHOLD_EDIT_CLOSED`
- `CLASS_THRESHOLD_FIELD_NOT_FOUND`
- `CLASS_THRESHOLD_YEAR_NOT_FOUND`
- `CLASS_THRESHOLD_PERCENT_INVALID` — lo lanza el servicio. La ruta HTTP, si el cuerpo no es un entero 0–100, responde 400 del `I18nValidationPipe` con `statusCode`, `message` y `error`, sin ese `code`.
- `INVESTITURE_WINDOW_EDIT_CLOSED`
- `INVESTITURE_WINDOW_FIELD_NOT_FOUND`
- `INVESTITURE_WINDOW_YEAR_NOT_FOUND`
- `INVESTITURE_WINDOW_DATE_INVALID`
- `INVESTITURE_WINDOW_OUTSIDE_YEAR`
- `INVESTITURE_WINDOW_START_AFTER_END`
- `INVESTITURE_PASTOR_QUOTA_INVALID` — lo lanza el servicio. La ruta HTTP, si `slots` no es un entero mayor o igual a 0, responde 400 del `I18nValidationPipe` sin ese `code`.
- `INVESTITURE_PASTOR_QUOTA_BELOW_ASSIGNMENTS`
- `INVESTITURE_PASTOR_QUOTA_FULL`
- `INVESTITURE_PASTOR_ALREADY_ASSIGNED`
- `INVESTITURE_PASTOR_ROLE_REQUIRED`
- `INVESTITURE_PASTOR_USER_NOT_FOUND`
- `INVESTITURE_PASTOR_DISTRICT_NOT_FOUND`
- `INVESTITURE_PASTOR_CLUB_NOT_FOUND`
- `INVESTITURE_PASTOR_CHURCH_NOT_FOUND`
- `INVESTITURE_PASTOR_NOT_ASSIGNED`
- `INVESTITURE_REQUEST_FORBIDDEN`
- `INVESTITURE_REQUEST_SECTION_NOT_FOUND`
- `INVESTITURE_REQUEST_OUTSIDE_SECTION`
- `INVESTITURE_REQUEST_WINDOW_CLOSED`
- `INVESTITURE_REQUEST_DATE_OUTSIDE_WINDOW`
- `INVESTITURE_REQUEST_DATE_OUTSIDE_YEAR`
- `INVESTITURE_REQUEST_DATE_INVALID`
- `INVESTITURE_REQUEST_YEAR_CLOSED`
- `INVESTITURE_REQUEST_NOT_ELIGIBLE`
- `INVESTITURE_REQUEST_ALREADY_INVESTED`
- `INVESTITURE_REQUEST_ACTIVE_EXISTS`
- `INVESTITURE_REQUEST_NOT_OPERATIONAL`
- `INVESTITURE_REQUEST_NOT_PENDING`
- `INVESTITURE_REQUEST_PROGRESS_LOCKED`
- `INVESTITURE_REQUEST_NOT_FOUND`
- `INVESTITURE_REQUEST_EMPTY`

Un cuerpo de ventana que no tiene forma `YYYY-MM-DD` también lo rechaza el pipe con HTTP 400 sin `code`.

Permisos: no hay permiso nuevo en el catálogo. El porcentaje lo leen y guardan `director-lf` y `assistant-lf` de ese Campo, y `super-admin`, con el corte del 30 de junio. La ventana la consultan también admin, assistant-admin, unión y división dentro de su alcance. La guardan director y asistente de su Campo, admin y assistant-admin en su alcance, y super-admin, solo si el año está activo y el día local cae dentro del año. Guardar la ventana no cambia quién puede editar el porcentaje ni autoriza investiduras. El cupo de pastores lo cambia solo `super-admin`. Lo asignan director y asistente de Campo o de unión, dentro de su alcance. `super-admin` no asigna por ese rol. Cada pastor activo del distrito queda habilitado para autorizar, igual que el director y el asistente de ese Campo. La solicitud la presentan, leen, agregan y quitan el director, el secretario o el secretario-tesorero de esa sección y año. El subdirector no. `super-admin` solo cambia la fecha. El correo de presentación no suma a admin, super-admin, unión ni división. La notificación de resultado no suma al subdirector. El recordatorio tampoco suma a admin ni a super-admin por esos cargos.

Migraciones creadas. No aplicadas a producción ni a Neon. En la base aislada de loopback, el porcentaje, la ventana y los pastores se ejecutaron dentro de una transacción y se revirtieron. `to_regclass` vio la tabla y, después del `ROLLBACK`, no. La migración de la solicitud no se aplicó así. El e2e de la fase 4 reconstruye el esquema con `prisma migrate diff` y, encima, crea los dos índices únicos parciales en esa base de prueba. Eso no certifica la migración.

- `sacdia-backend/prisma/migrations/20260930120000_local_field_class_thresholds/migration.sql` — `minimum_percent` entre 0 y 100.
- `sacdia-backend/prisma/migrations/20261001130000_local_field_investiture_windows/migration.sql` — `start_date <= end_date`.
- `sacdia-backend/prisma/migrations/20261001143000_district_investiture_pastors/migration.sql` — cupo global `slots >= 0` y asignación por distrito.
- `sacdia-backend/prisma/migrations/20261001193000_investiture_authorization_requests/migration.sql` — solicitud, personas, llaves e índices únicos parciales. No aplicada a producción.
- `sacdia-backend/prisma/migrations/20261002183000_investiture_authorization_resolution/migration.sql` — comentario, motivo y texto del sistema. No aplicada a producción.
- `sacdia-backend/prisma/migrations/20261002200000_investiture_authorization_achievement_intent/migration.sql` — intención del logro. No aplicada a producción.
- `sacdia-backend/prisma/migrations/20261005190000_investiture_message_dispatches/migration.sql` — seguimiento de correos y notificaciones. No aplicada a producción.
- `sacdia-backend/prisma/migrations/20261005200000_investiture_message_delivery/migration.sql` — estado `queued`, lease del claim y `notification_logs.idempotency_key`. No aplicada a producción.
- `sacdia-backend/prisma/migrations/20261006120000_investiture_message_uncertain/migration.sql` — estado `uncertain`. No aplicada a producción.

Documentos tocados: `docs/features/clases-progresivas.md`, `docs/features/validacion-investiduras.md`, `docs/features/communications.md`, `docs/features/cron-automation.md`, `docs/database/SCHEMA-REFERENCE.md`, `docs/database/schema.prisma`, `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, `docs/api/FRONTEND-INTEGRATION-GUIDE.md`.

Job nuevo: `investiture-authorization-reminders`, cada 15 minutos en UTC. El de logros de la fase 5 sigue igual. El pipeline y los cron de año existentes no se modificaron. No se envió correo real.

Orden de activación, cuando exista el resto: las dos migraciones → backend → recién después app y panel del flujo nuevo. Hoy no hay feature flag. Revertir este slice es revertir el diff de backend y no aplicar las migraciones.

Transición de expedientes viejos: **despliegue bloqueado**. Hace falta inventario y aprobación antes de apagar la vía anterior.

## F. UI y skills

Skills leídas:

- `emil-design-eng` (`/Users/abner/.agents/skills/emil-design-eng/SKILL.md`). No se aplicó a pantallas: no hay pantallas nuevas. No se celebró un éxito de UI.
- `improve-animations` y sus referencias `AUDIT.md` / `PLAN-TEMPLATE.md`. Auditoría focal: no hay código de movimiento nuevo. No se inventaron defectos ni se auditó toda la app. Recomendación, no cambio: al construir la solicitud y la autorización, usar la duración y el easing ya existentes, respetar `prefers-reduced-motion` y no animar el estado de carga ni el teclado.
- `app-ui-design`. No hubo cambios Flutter. La app conserva sus tokens. Accesibilidad de pantallas nuevas: no aplica todavía.

| Before | After | Why |
| --- | --- | --- |
| Pantallas de certificado e investidura sin este diff | Sin cambio visual | El alcance de UI del plan llega con las fases 4 y 5, que no se implementaron. Las skills no autorizan un rediseño. |
| OCR deja el ítem en `NEEDS_REVIEW` | Igual | Subir o extraer no acredita (`certificate-bulk-imports.service.ts` ~183). |
| Aprobación de clase sin mirar la edad | La API rechaza antes de escribir | La confirmación de acreditación queda en el backend, no en un estado de éxito de la UI. |

Capturas: no hay. No se levantó la app ni el admin. Verificación visual pendiente. Lo revisado es código.

Accesibilidad, texto ampliado y movimiento reducido: no inspeccionados en dispositivo. Inspección de código: este slice no añade controles.

## G. Guía para el revisor

### Certificado Amigo 2025

Datos sintéticos, sin producción:

- Nacimiento `2016-01-01`
- Clase Amigo, `minimum_age` 10
- Años `2025-01-01`–`2025-12-31` y `2026-01-01`–`2026-12-31`
- Certificado con `completed_at` en 2025

Esperado: no queda `READY`, no se envía, no se reenvía, no se aprueba, no hay enrollment `INVESTIDO` ni historial. El pendiente de 2026 no se actualiza. Un certificado 2026 de la misma persona sí pasa el criterio de edad. Una clase con mínimo 9 en 2025 también.

Comando: el jest de `class-certificate-historical-age.spec.ts` y el caso `blocks an Amigo certificate` en el spec de aplicación.

### Porcentaje

Sin fila de umbral, 79 no completa un requisito pendiente y 80 sí. Con `minimum_percent` 90, 85 no cuenta. `VALIDATED` cuenta con puntaje bajo. `REJECTED` con 100 no cuenta. `computeGrade` no se tocó.

La API: sin fila responde 80 y no inserta. Un director del Campo guarda 90 hasta el 30 de junio 23:59 en `America/Mexico_City` (`2026-07-01T05:59:00.000Z` para el año 2025-09-01–2026-08-31). A las 00:00 del 1 de julio local (`2026-07-01T06:00:00.000Z`) ese director recibe `CLASS_THRESHOLD_EDIT_CLOSED` y el super-admin todavía guarda. Fuera del año, también el super-admin recibe ese 403. Admin, unión, división, director de club y director de otro Campo reciben `GUARD_PERMISSION_DENIED` y no leen la fila. 0 y 100 se aceptan. 101 y 90.5 los rechaza el servicio con `CLASS_THRESHOLD_PERCENT_INVALID`. Por HTTP, el `I18nValidationPipe` responde antes, con 400 `statusCode` / `message` / `error` y sin ese `code`.

### Ventana

Sin fila, un año 2026-01-01–2026-12-31 responde 2026-10-01–2026-12-20, `operational` true, y no inserta. Un año 2025-09-01–2026-08-31 responde 2025-10-01–2025-12-20. Si el 1 de octubre o el 20 de diciembre caen fuera, se recortan. Si octubre–diciembre no intersecta el año y no hay configuración válida, el GET responde `start_date` null, `end_date` null, `configured` false y `operational` false. No devuelve el año completo. `operational` significa que existe un rango, no que el día local esté dentro. El 15 de febrero de 2026, con año 2026-01-01–2026-06-30 y sin fila, `allowsOperation` es false y el GET no llama a `upsert`. Un director del Campo puede guardar 2026-02-01–2026-02-20; el predicado abre el 15 de febrero y cierra el 21 de febrero y el 15 de enero. Con el año `active` false, también cierra dentro de ese rango. Una fila de agosto sobre un año que termina en junio no abre y no se reescribe. Director, asistente, admin en su alcance y super-admin guardan fechas dentro del año mientras el año está activo y el día local cae dentro. Unión y división leen y reciben 403 al guardar. El primer y el último día local abren presentar, agregar y autorizar; el día anterior y el siguiente los cierran. Esa comprobación no está conectada a `submit`, `club-approve`, `coordinator-approve`, `field-approve` ni `invest`. Un admin que guarda la ventana sigue sin poder cambiar el porcentaje. El probe histórico `docs/reviews/investidura-autorizacion-review-evidence/phase2-default-probe.cjs` sigue esperando el año completo; no se editó.

### Pastores del distrito

Sin fila, el cupo es 2 y la lectura no inserta ni toma el candado. Solo `super-admin` lo cambia. Con el tope en 1, el segundo pastor del mismo distrito recibe `INVESTITURE_PASTOR_QUOTA_FULL` y otro distrito de la misma unión también se queda en un pastor. Bajar el cupo por debajo de los activos se rechaza y no reescribe la fila. El cambio de cupo y el alta o la reactivación toman el mismo candado advisory antes de leer. En unidad, los dos órdenes (bajar con un pastor activo, y alta con cero pastores mientras otro baja a 0) quedan cubiertos con fila y sin fila: la segunda operación espera y no queda `activos` por encima de `slots`. Dos altas, o una reactivación y un alta, por el último cupo dejan un solo pastor activo. En PostgreSQL aislado, una tercera conexión sostiene ese candado y `pg_locks` muestra la espera no concedida; al soltarla, el primer waiter corre primero y se cumple el mismo invariante, con fila y sin fila. La carrera real del último cupo usa dos conexiones del pool, sin esa tercera. Director y asistente del Campo asignan su distrito. Unión asigna un distrito de otro Campo de su unión, no uno de otra unión. `super-admin`, admin y división no asignan y no listan pastores en ese rechazo. Los dos cupos activos responden `can_authorize: true`. Un usuario sin rol `pastor` recibe `INVESTITURE_PASTOR_ROLE_REQUIRED`. Quitar libera el cupo y no toma el candado del cupo. La lectura de un club usa `churches.districlub_type_id` y no `clubs.districlub_type_id` ni un dato del usuario. El HTTP de cupo y de cupo lleno sustituye `JwtAuthGuard`, `GlobalRolesGuard` y Prisma. No prueba autenticación ni base reales. El e2e PostgreSQL no prueba HTTP ni autenticación. Estas rutas no llaman a `submit`, `club-approve`, `coordinator-approve`, `field-approve` ni `invest`. El probe histórico `docs/reviews/investidura-autorizacion-review-evidence/phase3-quota-race-probe.cjs` no se editó. Su mock no tiene `$executeRaw`, así que contra este servicio ya no reproduce el defecto; sigue siendo el registro de P3-1, no la prueba de aceptación.

### Solicitud

El director, el secretario o el secretario-tesorero de la sección presentan. El subdirector recibe 403 al presentar, leer, agregar, quitar y cambiar fecha. `super-admin` no presenta y sí cambia la fecha. Varias personas de un envío comparten solicitud y fecha. Agregar con otra fecha no reescribe a las anteriores. Cambiar fecha mueve solo a los pendientes seleccionados; si uno ya no está pendiente, no cambia a ninguno. El 15 de febrero, con una fecha de noviembre válida, no se presenta y sí se corrige la fecha de quien ya está pendiente. Un año que termina en junio, sin intersección con octubre, no admite presentación. Un certificado histórico no entra. Sin progreso o sin la duración mínima, no entra. Una clase de dos años iniciada el año anterior entra cuando el conteo ya llega a la mínima; el primer año no. Si el conteo pasa la máxima, o el estado ya es `EXPIRED`, responde `INVESTITURE_DURATION_EXPIRED` y el enrollment sigue igual. Aventureros o Conquistadores no aceptan una segunda activa de la misma persona. Guía Mayor acepta dos clases distintas y rechaza la misma clase dos veces. Un GM ya investido, con membresía solo en la sección de GM del mismo club, presenta la clase cruzada en la sección de esa clase. La sección de GM y un club distinto no. Otra clase de GM sigue independiente. Quien ya está `INVESTIDO` no entra, y el pendiente anterior de esa persona y clase queda `REMOVED` con `ALREADY_INVESTED`. Quitar deja `REMOVED` y permite volver a marcar. Puntaje, archivo, envío, baja, aprobación y rechazo de ese enrollment quedan bloqueados mientras sigue pendiente; otro enrollment de la misma persona no. Presentar y esa escritura toman el mismo candado del enrollment. Dos altas de la misma persona dejan una sola `PENDING`. Dos personas distintas de la misma sección y año dejan una sola cabecera, y la lectura trae a las dos. Vaciar una solicitud y luego agregar a esa cabecera, cuando ya existe otra con pendientes, responde `INVESTITURE_REQUEST_STALE`: no revive el grupo anterior y el pendiente visible sigue en el GET. Si esa cabecera vacía es la única, se puede volver a usar. Agregar y presentar a la vez tampoco dejan dos grupos activos. En la base aislada pasaron las tres carreras anteriores y, además, la duración, la clase cruzada, la cabecera única y la espera de `pg_locks` entre presentar y guardar un puntaje. Esa base se reconstruye con `prisma migrate diff` y el e2e crea ahí los dos índices únicos parciales. No certifica la migración, ni HTTP, ni autenticación, ni la app. No se envía correo y no se llama al pipeline anterior. La undécima revisión cerró P4-4. La pantalla de la app sigue pendiente.

### Autorización

El pastor con asignación activa en el distrito de la iglesia del club, o `director-lf` y `assistant-lf` de ese Campo, autorizan. `admin`, `super-admin`, unión, división y el directivo de la sección no. Otro Campo u otro distrito tampoco. Una misma llamada puede investir a unos y rechazar a otros; quien no va en la selección sigue pendiente. El comentario puede ir vacío. El rechazo humano sin motivo no escribe. Quien dejó de cumplir progreso o duración queda `REJECTED_BY_SYSTEM` con el texto largo, y su enrollment no cambia. Los demás pueden quedar `INVESTIDO` sin `FIELD_APPROVED` y sin fila en `investiture_validation_history`. La auditoría de esta vía es la fila de la persona, en la misma transacción que el enrollment. El 10 de diciembre autoriza una fecha del 1 de noviembre si la ventana llega a ese día. Fuera de la ventana no autoriza, aunque se corrija la fecha. Ampliar la ventana dentro del año sí. Con el año inactivo, o con el día local después de `end_date`, no autoriza. El último día local de la ventana sí autoriza.

P5-1: la comprobación de año, ventana y pastor que corre antes de la transacción no decide. Dentro, y después de esperar, se vuelven a leer. El instante de esa segunda comprobación se toma después de los candados. Si la llamada no trae un `now` fijo, ese instante es el reloj inyectable en ese momento, no el de la entrada. El orden es año, calendario del Campo (aunque no exista fila), pastor si quien autoriza no es el Campo, sección, usuarios y enrollments. Esos candados se sostienen hasta escribir. Guardar la ventana toma año y luego calendario. Cerrar o desactivar el año toma el candado del año. Quitar al pastor toma el de la asignación y después el de la fila del distrito. En PostgreSQL, con una espera observada en `pg_locks`, cerrar el año, mover el fin de la ventana al 14 de octubre o desactivar al pastor deja la persona `PENDING`, el enrollment sin `INVESTIDO` y cero eventos. Lo mismo si la espera cruza la medianoche del 20 de diciembre o la del 31 de diciembre en `America/Mexico_City`: la persona sigue `PENDING`, sin investidura y sin evento. Un cambio de ventana que toma el mismo candado no entra entre la comprobación y la escritura: la investidura queda `INVESTIDO` y el fin de ventana nuevo aparece después.

P5-2: `INVESTED` guarda `achievement_intent_key` en la misma escritura. `class.completed` se inserta después del commit, con `idempotency_key` igual a esa intención y un candado advisory de esa clave. El insert que puede fallar es `achievement_event_log.create` del cliente de `AchievementsService`, también si ese cliente no tiene `$transaction`. Si el primer insert falla, la respuesta sigue en éxito. El reintento, también dos a la vez, recupera una sola fila y después responde `INVESTITURE_REQUEST_ALREADY_RESOLVED` mientras el calendario sigue abierto. Si ese insert vuelve a fallar, el error sale y no se convierte en 409. Si después se cierra el año, ese POST responde `INVESTITURE_REQUEST_YEAR_CLOSED` y no entrega el evento. La entrega la hace `InvestitureAchievementIntentReconciler`: al arrancar el proceso y cada cinco minutos llama a `reconcileConfirmedAchievementIntents`, que no comprueba año, ventana ni asignación y no cambia la decisión. Dos reconciliaciones a la vez dejan una sola fila. Si el trabajo agotó sus tres intentos y BullMQ lo conserva en `failed`, volver a llamar a `queue.add` con el mismo id no lo reactiva. En ese caso se llama a `Job.retry('failed')` con los intentos en cero, así vuelve a correr el backoff de tres intentos. Un trabajo en espera, activo o completado no se duplica. Un evento ya `processed` no se vuelve a conceder. Con Redis aislado, tres fallos de lectura, el año sin leerse y dos reconciliaciones concurrentes dejan una fila, un trabajo `completed` y `processed=true`. Rechazar, quitar, cerrar la fila y un fallo de elegibilidad antes de escribir no crean la intención ni el evento. No se concede el logro antes del commit.

P5-3: la clave persistida puede llevar `:`. El `jobId` es `achievement-` más el SHA-256 de esa clave, sin `:`. `Job.prototype.validateOptions` de BullMQ 5.81.0 acepta ese identificador y rechaza la clave con `:`. Si la cola falla después de guardar la fila, la reconciliación la encola una vez. Dos evaluaciones del mismo trabajo dejan el evento `processed` y no agregan otra fila. No se conectó Redis ni se afirma que un worker de producción haya corrido: la cola de la prueba ejecuta el validador instalado y el procesador real sobre esa base aislada.

Si la elegibilidad lanza antes de escribir, la persona sigue pendiente y el enrollment no cambia. Autorizar contra rechazar, contra quitar o contra `closePendingByYearEnd` deja una sola decisión: `INVESTIDO` solo si la fila quedó `INVESTED`. Presentar no emite `class.completed`. `closePendingByYearEnd` no es una ruta y el cierre anual todavía no lo llama. El panel no está integrado. P5-1, P5-2 y P5-3 siguen cerrados. Esta fase no queda aprobada. El informe independiente y los probes no se modificaron.

### Correos y recordatorios

Después de confirmar el grupo, presentar y agregar dejan la intención del correo en esa misma transacción y después preparan un correo por destinatario y por rol: pastores activos del distrito de la iglesia, y `director-lf` y `assistant-lf` de ese Campo. La misma cuenta con los dos cargos recibe dos correos. El segundo envío lista solo a quienes se acaban de agregar. Quitar no manda correo. `admin`, `super-admin`, unión y división no entran por esos cargos. El enlace es `{ADMIN_PANEL_URL}/investiture-requests/{requestId}`.

La notificación de resultado usa la bandeja existente, con origen `investiture:invested` o `investiture:rejected` y una clave de idempotencia por aviso. Llega al director, al secretario y al secretario-tesorero de la sección de la solicitud, y a la persona. El subdirector y otra sección no. Si hay investidos y rechazados, la directiva recibe una notificación por resultado. La persona investida recibe el texto alegre, sin el comentario. La persona rechazada recibe solo «Falta de requisitos para investidura». El motivo humano no sale de la solicitud. El rechazo del sistema le dice a la directiva que decidió el sistema e incluye el texto largo.

El recordatorio es solo correo. El cron `investiture-authorization-reminders` corre cada 15 minutos en UTC y envía cuando en `local_fields.timezone` son las 10:00, de lunes a viernes según el rol: pastor lunes, miércoles y viernes; Campo solo lunes. Una solicitud de hace dos semanas sigue si queda alguien pendiente. Una solicitud parcial cuenta una vez y lista solo a los pendientes. Con la ventana cerrada y el año abierto, el correo avisa que hay que ampliarla y no concede permiso para editarla. Sin pendientes, con el año inactivo o pasada `end_date`, no se envía. `investiture_message_dispatches` deja una fila por kind, ejecución, destinatario, rol y alcance. Otra ejecución o el otro rol no se fusionan. No se crean avisos periódicos en el panel.

La vigésima revisión dejó cerrado el retiro parcial posterior al primer fallo. El residuo de la segunda lectura quedó corregido: cuerpo, destino y alcance salen de la misma instantánea. La vigesimoprimera revisión cerró ese caso y aceptó el backend para continuar con la fase 7, no para desplegar. Si después falta una parte de ese alcance, el envío se detiene y no se cambia el cuerpo ni la clave. P6-1, P6-2, P6-4 y P6-5 siguen cerrados. Cada presentación o agregado tiene una identidad propia. Volver a presentar los mismos enrollments, en la misma cabecera o en otra, es otra operación. Reintentar la misma identidad no aborta la transacción. La recuperación conserva esa identidad y no vuelve a escribir el correo de quien ya fue atendido, aunque cambie el grupo pendiente. La intención del grupo y del resultado se escribe en la misma transacción que confirma el negocio. Si después falla la lectura, esa fila queda y una recuperación posterior materializa lo que falte sin duplicar lo ya creado. `queued` es la aceptación de la cola. `sent` es el acuse del proveedor o de la bandeja. Si ese acuse se pierde y el envío sigue permitido, el reintento reutiliza el contenido ya enviado durante 24 horas. Pasado ese plazo el aviso queda `uncertain` y no se reenvía solo. Antes de esa llamada, también con el contenido congelado, se vuelven a leer destinatario, rol, territorio, año y pendientes. Si ya no corresponde, o si solo queda autorizada una parte del contenido congelado, el aviso queda `skipped`, no se llama al proveedor y no se cambia el cuerpo ni la clave. Un `sending` sin lease vigente se puede reclamar. Un trabajo de BullMQ que agotó sus intentos y quedó `failed` se reactiva con `Job.retry` y el mismo id. Al entregar un envío nuevo, el worker vuelve a leer destinatario, rol, territorio, año, ventana y pendientes. Si el pastor ya no está asignado, el cargo salió de ese Campo, el año cerró o no queda nadie pendiente, no sale el texto viejo. La ventana por defecto abierta se resuelve igual en el primer envío y en el reintento. Sin intersección sigue cerrada. La bandeja del resultado usa `notification_logs.idempotency_key`. Un fallo de esa escritura no se marca `sent`. El push es aparte y no confirma la bandeja. Quien apaga `approvals` no recibe el aviso. Esta fase no queda aprobada.

### Riesgo

- La aprobación usa el `Prisma.TransactionClient` generado, sin convertir `tx` al contrato estrecho `HistoricalAgeDb`. `tsc --noEmit -p tsconfig.build.json` quedó en salida 0 el 2026-10-01.
- El fallback a 80 cuando falta el delegate oculta una migración no aplicada.
- El pipeline viejo sigue activo. No mezclar este slice con un apagado de rutas.

### Siguiente acción

1. Revisar H1 a H5. X-1 sigue abierto. X-2, X-3 y X-4 quedaron cerrados en la vigesimoquinta revisión, con observaciones. No apagar nada. El inventario está en `docs/features/validacion-investiduras.md`. Las rutas, los alias, el bloque, el vencimiento y las pantallas del panel y de la app siguen activos. No hay conteos de producción. Los expedientes abiertos (`SUBMITTED_FOR_VALIDATION`, `CLUB_APPROVED`, `COORDINATOR_APPROVED`, `FIELD_APPROVED`) se conservan: no se resuelven, no se arrastran, no se copian a la solicitud nueva y no se les libera el bloqueo. Hace falta aprobar ese tratamiento, con una lectura real de esos expedientes, antes de retirar la vía. La revisión 24 aceptó el backend de la fase 7 para continuar, no para desplegar, y cerró P7-1, P7-2 y P7-3. P6-3 quedó cerrado en la vigesimoprimera revisión. P6-1, P6-2, P6-4 y P6-5 también. El backend de la fase 6 está aceptado para continuar, no para desplegar. No reabrir P5-1, P5-2, P5-3 ni el mock de ventana. La fase 5 completa sigue sin pantalla. La undécima revisión cerró P4-4; la pantalla de la app de la fase 4 sigue pendiente. Esta entrega no certifica UI, autenticación real ni la aplicación de las migraciones. La fase 2 sigue parcial. La fase 3 permanece cerrada en el alcance de la octava revisión. No desplegar y no retirar el pipeline anterior.
2. No aplicar `20261001193000_investiture_authorization_requests`, `20261002183000_investiture_authorization_resolution`, `20261002200000_investiture_authorization_achievement_intent`, `20261005190000_investiture_message_dispatches` ni `20261005200000_investiture_message_delivery` ni `20261006120000_investiture_message_uncertain` en Neon ni en producción. El e2e usa una base de loopback cuyo nombre termina en `_test`, borra su esquema `public` y no sustituye esas migraciones.
3. La pantalla de la app y la pantalla de autorización del panel quedan fuera de este corte. El API de resolución ya está en el árbol.
