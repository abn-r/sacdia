# Informe de implementación — investidura por autorización

Estado para revisión independiente. Este informe no declara el trabajo aprobado.

## A. Estado y alcance

| Capa | Estado |
| --- | --- |
| Implementación | **PARCIAL** |
| Verificación | **PARCIAL** |
| Preparación para despliegue | **BLOQUEADO** |

Fundamento: quedaron en código la fase 0B (edad histórica de certificados de clase), la fase 1 de backend (porcentaje del Campo), la ventana del Campo, la asignación de pastores del distrito, el backend de marcar, quitar y cambiar fecha, y el backend de autorizar o rechazar. La fase 2 sigue parcial: W1 está cerrado en revisión independiente y no hay pantalla. La fase 3 quedó cerrada en la octava revisión solo en el alcance de cupos y asignaciones. La undécima revisión verificó el backend de la fase 4 en ese alcance; la pantalla de la app sigue pendiente. La fase 5 tiene la resolución en el API y todavía no tiene la pantalla del panel. No hay correos, recordatorios ni cierre anual del flujo nuevo. El pipeline anterior sigue aceptando transiciones. Sin eso el plan no está completo. No hay despliegue.

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
| 5 Autorizar en el panel | Backend en el árbol, sin aprobación y sin pantalla. El pastor del distrito o el Campo resuelven por API. No envía correo ni notificación. |
| 6 Correos y recordatorios | Pendiente. |
| 7 Historial, anuario y fin de año | Pendiente. |
| 8 Apagar la vía vieja | Pendiente. El pipeline club → coordinación → campo sigue aceptando transiciones. |
| 9 Documentación | Parcial: certificados, porcentaje, ventana, pastores del distrito, la solicitud de marcar y la resolución. El resto de la fase 9 no cambió. |

### Desviaciones

- IA-23, aprobada el 2026-10-01: sin intersección de octubre–diciembre y sin configuración explícita válida, la ventana permanece cerrada. W1 quedó cerrado en revisión independiente. La fase 2 sigue parcial.
- El asignado debe tener el rol global `pastor`. El plan dice «pastor asignado» y hoy ese rol no trae distrito; la asignación no convierte a cualquier usuario en pastor.
- Bajar el cupo por debajo de los pastores activos de algún distrito se rechaza y no borra filas. Quitar una asignación la deja inactiva y libera el cupo.
- P3-1: cambiar el cupo y dar de alta o reactivar toman, al inicio de la transacción, `pg_advisory_xact_lock(hashtextextended('investiture-pastor-quota', 0))` antes de leer ocupación o cupo. También cuando no hay fila. El candado va por `$executeRaw`: Prisma no deserializa el `void` de esa función con `$queryRaw`. Quitar una asignación no toma ese candado. La octava revisión cerró esta corrección en ese alcance.
- IA-06, en este corte: quien ya está `INVESTIDO` no entra. El pendiente anterior de esa persona y clase pasa a `REMOVED` con `resolution_code` `ALREADY_INVESTED`, en una transacción posterior a la que se revierte. No se usa el texto largo del rechazo del sistema ni `CLOSED_YEAR`.
- Las altas, las bajas y el cambio de fecha de la solicitud toman `pg_advisory_xact_lock(hashtextextended('investiture-authorization-user:' || user_id, 0))` antes de releer. El cambio de fecha no escribe si, ya con el candado, alguno de los seleccionados dejó de estar `PENDING`.
- Corrección P4-1 a P4-3, cerrada en la décima revisión: la duración separa el año de la solicitud del año de inicio del enrollment y aplica mínima y máxima sin reescribir el enrollment. La clase cruzada se presenta en la sección del mismo club cuyo tipo es el de la clase, con la membresía en otra sección de ese club. El progreso, la evidencia, el envío y la revisión de ese enrollment toman el mismo candado que presentar, dentro de la transacción que escribe.
- Vía residual de P4-4, en el árbol y sin aprobación: bajo el candado de sección y año, agregar a una cabecera explícita se rechaza con `INVESTITURE_REQUEST_STALE` si otra cabecera de esa sección y año ya tiene pendientes. No se mueven personas. Si esa cabecera vacía es la única, se puede volver a usar.
- Quien tiene rol de unión y de Campo asigna en los distritos de su unión. En la ventana, el rol de unión no amplía la edición.
- La aprobación masiva de un lote (`POST .../approve` del lote) ya rechazaba decidir el lote entero (`CERTIFICATE_IMPORT_ITEM_DECISION_REQUIRED`). La edad se revalida en cada `approveItem` / `approveItemInTransaction`. No se añadió una aprobación masiva nueva.
- Alta y aprobación institucionales leen el nacimiento después de resolver el año, dentro de la transacción que toma `FOR UPDATE`, y persisten el año leído en ese cliente. El cliente global y el transaccional se distinguen en la prueba de alta.

### Bloqueantes

1. Despliegue del cambio de vía: no hay inventario de expedientes del pipeline anterior. No se asume que producción está vacía. No se retiraron rutas.
2. La migración `20260930120000_local_field_class_thresholds` está creada y no aplicada. Sin ella, el cliente Prisma generado que ya conozca el modelo fallará al leer el porcentaje; el código actual hace fallback a 80 si el delegate no existe.
3. `prisma generate` se ejecutó el 2026-09-30 contra `prisma/schema.prisma` (cliente 7.9.1). La migración no se aplicó a producción ni a Neon. En la base aislada de loopback, el SQL de `20260930120000_local_field_class_thresholds` se aplicó dentro de una transacción revertida después de que el esquema completo ya había creado la tabla. El fallback a 80 si falta el delegate sigue en el código y no sustituye esa migración en un entorno real.

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

## C. Matriz IA-01 a IA-56

| Regla | Estado | Implementación | Prueba | Evidencia o pendiente |
| --- | --- | --- | --- | --- |
| IA-01 | Implementada en backend, sin aprobación | `investiture-authorization-requests.service.ts` | spec de solicitud | La solicitud y sus personas quedan en una sección. Quien no pertenece a esa sección recibe `INVESTITURE_REQUEST_OUTSIDE_SECTION`. Otro cargo recibe `INVESTITURE_REQUEST_FORBIDDEN`. |
| IA-02 | Parcial | `present` acepta varios enrollments | spec de varias personas en una solicitud | Un envío comparte solicitud y fecha. No hay notificaciones. |
| IA-03 | Pendiente | — | — | |
| IA-04 | Implementada en backend, sin aprobación | `usesSingleSlot` y el conflicto de `PENDING` | spec de la segunda clase y carrera de dos altas | Aventureros o Conquistadores: una activa por persona. |
| IA-05 | Implementada en backend, sin aprobación | excepción de Guía Mayor y `cross_type_enrollment` con GM `INVESTIDO`, también histórico | spec de dos clases cruzadas y de membresía solo en GM | Se presenta en la sección de la clase, del mismo club. La sección de GM y otro club responden `INVESTITURE_REQUEST_OUTSIDE_SECTION`. Otra clase de GM sigue independiente. No crea inscripciones nuevas. |
| IA-06 | Implementada en backend, sin aprobación | el alta rechaza `INVESTIDO` y una segunda transacción deja el pendiente en `REMOVED` / `ALREADY_INVESTED` | spec de servicio y e2e PostgreSQL | `can_authorize` queda en false. No usa el texto largo ni `CLOSED_YEAR`. |
| IA-07 | Parcial | `remove` | spec de quitar y volver a marcar | Quitar libera la solicitud activa. El rechazo humano y el del sistema no están en este corte. |
| IA-08 | Parcial | elegibilidad y duración desde el año de inicio del enrollment hasta el año de la solicitud | spec de unidad y e2e PostgreSQL | El primer año de una clase de dos años no entra. El segundo, si ya cumple la mínima, sí. La máxima y el estado `EXPIRED` responden `INVESTITURE_DURATION_EXPIRED` sin reescribir el enrollment. Autorizar no tiene ruta. |
| IA-09 | Pendiente | — | — | |
| IA-10 | Pendiente | — | — | |
| IA-11 | Implementada en backend, sin aprobación | `assertMarker` en `remove` | spec de subdirector y de secretario | El conjunto es director, secretario y secretario-tesorero. El spec ejerce director y secretario, y el 403 del subdirector. No envía correo. |
| IA-12 | Pendiente | — | — | |
| IA-13 | Implementada | `field-class-threshold.ts:1`, `field-class-threshold-config.service.ts`, `class-requirement-eligibility.service.ts` | `field-class-threshold-config.service.spec.ts`, spec de elegibilidad | Sin fila, el valor es 80 y la lectura no crea fila. El PATCH guarda el entero. |
| IA-14 | Implementada | `class-requirement-eligibility.service.ts` (ADVANCED fuera de investidura; EXTRA por contexto) | spec de elegibilidad, incluido el lote | El listado colectivo llama `calculateForEnrollments` una vez (`class-progress-scope.service.ts`). |
| IA-15 | Implementada | `field-class-threshold.ts` `sectionMeetsThreshold`, elegibilidad | specs de umbral y elegibilidad | `VALIDATED` cuenta; `REJECTED` no; el puntaje usa el porcentaje del Campo. |
| IA-16 | Implementada | `classes.service.ts` detalle con `passing_score` | `classes.service.spec.ts` caso de score 80 | No hay pantalla nueva. El detalle, el listado y la elegibilidad comparten el criterio. |
| IA-17 | Cumplida por omisión | `clubs.service.ts` `computeGrade` no se modificó; 70 sigue siendo B | No se ejecutó una prueba nueva de `computeGrade` | Lectura del código. |
| IA-18 | Implementada en backend, sin aprobación | conteo de años eclesiásticos desde el inicio del enrollment hasta el año de la solicitud | spec de mínima, de máxima y e2e PostgreSQL | Falta de mínima: `INVESTITURE_DURATION_MIN_NOT_MET`. Máxima superada o estado `EXPIRED`: `INVESTITURE_DURATION_EXPIRED`. No llama a `expireEnrollment`. |
| IA-19 | Implementada | `canEditFieldClassThreshold` y `FieldClassThresholdConfigService` | `field-class-threshold.spec.ts`, `field-class-threshold-config.service.spec.ts` | Director y asistente de su Campo hasta el 30 de junio 23:59 en la zona del Campo. Después, solo super-admin, y solo dentro del año pedido. Admin, unión, división, club y otro Campo reciben 403. Un cargo de unión no amplía el Campo. |
| IA-20 | Implementada en backend, sin aprobación | `present` exige fecha civil y la copia a las personas nuevas | spec de varias personas | Quienes se marcan juntos salen con la misma fecha. |
| IA-21 | Implementada en backend, sin aprobación | `addPeople` | spec de agregar con otra fecha | La fecha nueva no reescribe a quienes ya estaban. |
| IA-22 | Implementada en backend, sin aprobación | `assertDateInside` | spec de fecha fuera de ventana, de año y día imposible | La fecha tiene que caer en la ventana vigente y en el año. |
| IA-23 | Corregida en el árbol; fase 2 no cerrada | `defaultInvestitureWindow` devuelve null sin intersección. `FieldInvestitureWindowConfigService.get` | `field-investiture-window.spec.ts`, spec del servicio y `field-investiture-window.controller.spec.ts` | Sin fila y con intersección: 1 de octubre a 20 de diciembre, recortado al año, `operational` true. Sin intersección y sin configuración válida: fechas null, `configured` false, `operational` false, `allowsOperation` false. La lectura no inserta. Una fila inválida no abre ni se reescribe. |
| IA-24 | Implementada | `FieldInvestitureWindowConfigService` | spec de la ventana | Director y asistente en su Campo; admin y assistant-admin en su alcance; super-admin en cualquiera, solo con el año activo y el día local dentro del año. Unión y división leen y no guardan. Otro Campo: 403. |
| IA-25 | Implementada en backend, sin aprobación | `changeDates` | spec de selección parcial y de `super-admin` | Una fecha para los pendientes seleccionados. No toca al resto. `super-admin` puede corregirla. Si uno ya no está pendiente, no cambia a ninguno. |
| IA-26 | Implementada en backend, sin aprobación | `changeDates` con el día local fuera de la ventana | spec del 15 de febrero | La corrección exige año abierto y fecha dentro de la ventana. No reabre la ventana para presentar. |
| IA-27 | Parcial | `assertTodayAllowsPresentation` | spec de ventana cerrada y de día fuera | Presentar y agregar usan el predicado. Autorizar no tiene ruta. El pipeline anterior no usa el predicado. |
| IA-28 | Parcial | el mismo predicado y `changeDates` | spec de agregar fuera de la ventana y de corregir fecha | Fuera de la ventana no se presenta ni se agrega. Cambiar la fecha no reabre la ventana. No hay recordatorios. |
| IA-29 | Parcial | `assertYearOpen` en presentar, quitar y cambiar fecha | spec de año inactivo | Con el año cerrado no se presenta ni se cambia la fecha. No se autoriza: no hay esa ruta. |
| IA-30 | Pendiente | — | — | |
| IA-31 | Pendiente | — | — | |
| IA-32 | Pendiente | — | — | La política anual existente no se sustituyó. |
| IA-33 | Pendiente | — | — | Fuera del código nuevo; la política anual previa sigue. |
| IA-34 | Fuera de alcance | — | — | Unidades y finanzas quedan fuera, como dice el plan. Carpetas e inscripciones de club no se tocaron. |
| IA-35 | Pendiente | — | — | Anuario no implementado. |
| IA-36 | Pendiente | — | — | |
| IA-37 | Pendiente | — | — | |
| IA-38 | Pendiente | — | — | |
| IA-39 | Pendiente | — | — | |
| IA-40 | Implementada en backend, sin aprobación | candado `investiture-authorization-enrollment:` dentro de la transacción de puntaje, archivo, envío, baja, aprobación y rechazo | spec de clases, spec de revisión y e2e PostgreSQL | Presentar toma el mismo candado antes de insertar el pendiente. Una escritura que ya pasó un control no guarda después. `CLASS_PROGRESS_LOCKED` sigue primero donde ya se comprueba. Otra clase de la misma persona no queda bloqueada. |
| IA-41 | Pendiente | — | — | |
| IA-42 | Pendiente | — | — | |
| IA-43 | Pendiente | — | — | |
| IA-44 | Pendiente | — | — | |
| IA-45 | Pendiente | — | — | |
| IA-46 | Pendiente | — | — | |
| IA-47 | Pendiente | — | — | |
| IA-48 | Pendiente | — | — | |
| IA-49 | Pendiente | — | — | |
| IA-50 | Pendiente | — | — | |
| IA-51 | Pendiente | — | — | Presentar, quitar o cambiar fecha no dispara `class.completed`. La autorización que sí lo haría no existe. El pipeline viejo no se alteró. |
| IA-52 | Implementada | `class-certificate-historical-age.ts:49` | spec del evaluador y regresión de aprobación | Edad al inicio del año con mes y día. |
| IA-53 | Implementada | listo, alta, envío, reenvío y `approveClassItem`; la aprobación institucional corre dentro de `$transaction` | specs de servicio, aplicación e institucional, más el e2e de bloqueo | La aprobación de lote entero sigue rechazada. Una fila `READY` corregida sin pedir listo vuelve a `NEEDS_REVIEW` si la edad falla. |
| IA-54 | Implementada | mismos archivos; códigos nuevos en `error-codes.ts` | spec del evaluador | Falta nacimiento, mínimo, año ausente o ambiguo. |
| IA-55 | Implementada | el fallo de `mark_as_ready` lanza antes de escribir; OCR sigue en `NEEDS_REVIEW` | regresión de aprobación y de corrección de una fila `READY` | No se reescriben acreditaciones previas: no hay job de reescritura. |
| IA-56 | Implementada | el evaluador compara solo contra `minimum_age` | spec: clase anterior con mínimo 9 en 2025 pasa; no hay borrado de historial | |

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

Tipo de prueba: unidad con Prisma simulado, HTTP de Nest con Prisma simulado y guards sustituidos para la ventana, el cupo de pastores y la solicitud, una prueba PostgreSQL aislada de la aprobación institucional, otra del candado de pastores y otra de las carreras de la solicitud. Esas pruebas HTTP no verifican autenticación ni base de datos reales. La de pastores y la de la solicitud en PostgreSQL sí usan la base aislada y no pasan por HTTP ni por el guard. El porcentaje no tiene prueba HTTP ni de UI. El guard admite unión y división por el alias de `director-lf`; en el porcentaje el servicio los rechaza, en la ventana les deja leer y no guardar, y en los pastores la unión asigna dentro de su alcance y la división no. La solicitud no usa `GlobalRolesGuard`: el cargo de sección se resuelve en el servicio.

Rojo: la aprobación del certificado Amigo 2025 (nacimiento 2016-01-01, mínimo 10) resolvió `APPROVED`. Verde: esa aprobación rechaza `CERTIFICATE_IMPORT_AGE_BELOW_MINIMUM` y no escribe enrollment ni historial.

ESLint sobre los archivos tocados sigue marcando Prettier en líneas anteriores a esta corrección (`classes.service.ts` no se reformateó; bloques viejos de institucional, del listado y del e2e). No se aplicó `--fix` al archivo completo. Se quitó un cast que el linter marcó como innecesario en el rechazo institucional.

### No ejecutado

- Unicidad de solicitudes cubierta en unidad y en la base aislada para dos altas de la misma persona. El cierre anual no está en esta pasada. La prueba PostgreSQL de certificados cubre el bloqueo de la aprobación, no un cambio de nacimiento mientras ese bloqueo espera.
- Concurrencia de dos autorizadores: la autorización no existe.
- Suites completas de investidura, app y admin. La app no tiene la pantalla de esta solicitud.
- Builds.
- Reloj de jobs: no hay job nuevo. No se envían correos.
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

Permisos: no hay permiso nuevo en el catálogo. El porcentaje lo leen y guardan `director-lf` y `assistant-lf` de ese Campo, y `super-admin`, con el corte del 30 de junio. La ventana la consultan también admin, assistant-admin, unión y división dentro de su alcance. La guardan director y asistente de su Campo, admin y assistant-admin en su alcance, y super-admin, solo si el año está activo y el día local cae dentro del año. Guardar la ventana no cambia quién puede editar el porcentaje ni autoriza investiduras. El cupo de pastores lo cambia solo `super-admin`. Lo asignan director y asistente de Campo o de unión, dentro de su alcance. `super-admin` no asigna por ese rol. Cada pastor activo del distrito queda habilitado para autorizar; esa autorización todavía no tiene ruta. La solicitud la presentan, leen, agregan y quitan el director, el secretario o el secretario-tesorero de esa sección y año. El subdirector no. `super-admin` solo cambia la fecha.

Migraciones creadas. No aplicadas a producción ni a Neon. En la base aislada de loopback, el porcentaje, la ventana y los pastores se ejecutaron dentro de una transacción y se revirtieron. `to_regclass` vio la tabla y, después del `ROLLBACK`, no. La migración de la solicitud no se aplicó así. El e2e de la fase 4 reconstruye el esquema con `prisma migrate diff` y, encima, crea los dos índices únicos parciales en esa base de prueba. Eso no certifica la migración.

- `sacdia-backend/prisma/migrations/20260930120000_local_field_class_thresholds/migration.sql` — `minimum_percent` entre 0 y 100.
- `sacdia-backend/prisma/migrations/20261001130000_local_field_investiture_windows/migration.sql` — `start_date <= end_date`.
- `sacdia-backend/prisma/migrations/20261001143000_district_investiture_pastors/migration.sql` — cupo global `slots >= 0` y asignación por distrito.
- `sacdia-backend/prisma/migrations/20261001193000_investiture_authorization_requests/migration.sql` — solicitud, personas, llaves e índices únicos parciales. No aplicada a producción.

Documentos tocados: `docs/features/clases-progresivas.md`, `docs/features/validacion-investiduras.md`, `docs/database/SCHEMA-REFERENCE.md`, `docs/database/schema.prisma`, `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, `docs/api/FRONTEND-INTEGRATION-GUIDE.md`.

No se actualizó `communications.md`: no hay correos nuevos.

Jobs: ninguno nuevo. El pipeline y los cron de año existentes no se modificaron.

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

El pastor con asignación activa en el distrito de la iglesia del club, o `director-lf` y `assistant-lf` de ese Campo, autorizan. `admin`, `super-admin`, unión, división y el directivo de la sección no. Otro Campo u otro distrito tampoco. Una misma llamada puede investir a unos y rechazar a otros; quien no va en la selección sigue pendiente. El comentario puede ir vacío. El rechazo humano sin motivo no escribe. Quien dejó de cumplir progreso o duración queda `REJECTED_BY_SYSTEM` con el texto largo, y su enrollment no cambia. Los demás pueden quedar `INVESTIDO` sin `FIELD_APPROVED` y sin fila en `investiture_validation_history`. La auditoría de esta vía es la fila de la persona, en la misma transacción que el enrollment. El 10 de diciembre autoriza una fecha del 1 de noviembre si la ventana llega a ese día. Fuera de la ventana no autoriza, aunque se corrija la fecha. Ampliar la ventana dentro del año sí. Con el año inactivo, o con el día local después de `end_date`, no autoriza. Si la elegibilidad lanza antes de escribir, la persona sigue pendiente y el enrollment no cambia. Autorizar contra rechazar, contra quitar o contra `closePendingByYearEnd` deja una sola decisión: `INVESTIDO` solo si la fila quedó `INVESTED`. `class.completed` se emite una vez, después de confirmar, y el reintento no lo repite. Presentar no lo emite. `closePendingByYearEnd` no es una ruta y el cierre anual todavía no lo llama. No hay correo ni notificación. El panel no está integrado. Esta fase no queda aprobada.

### Riesgo

- La aprobación usa el `Prisma.TransactionClient` generado, sin convertir `tx` al contrato estrecho `HistoricalAgeDb`. `tsc --noEmit -p tsconfig.build.json` quedó en salida 0 el 2026-10-01.
- El fallback a 80 cuando falta el delegate oculta una migración no aplicada.
- El pipeline viejo sigue activo. No mezclar este slice con un apagado de rutas.

### Siguiente acción

1. Revisar de forma independiente el backend de autorización de la fase 5 antes de integrar el panel o empezar la fase 6. La undécima revisión cerró P4-4; la pantalla de la app de la fase 4 sigue pendiente. Esta entrega no aprueba la fase 5 ni certifica UI, autenticación real ni la aplicación de las migraciones. La fase 2 sigue parcial. La fase 3 permanece cerrada en el alcance de la octava revisión. No desplegar y no retirar el pipeline anterior.
2. No aplicar `20261001193000_investiture_authorization_requests` ni `20261002183000_investiture_authorization_resolution` en Neon ni en producción. El e2e usa una base de loopback cuyo nombre termina en `_test`, borra su esquema `public` y no sustituye esas migraciones.
3. La pantalla de la app y la pantalla de autorización del panel quedan fuera de este corte. El API de resolución ya está en el árbol.
