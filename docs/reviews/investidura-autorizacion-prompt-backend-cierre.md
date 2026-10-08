# Prompt — Cierre del backend (BC-1 a BC-15)

## Contexto

Trabajás en `/Users/abner/Documents/development/sacdia`, rama `development` de `sacdia-backend`, sobre `113d8ba` más los cambios sin commit.

- **Revisión independiente 31** (2026-10-07, en `docs/reviews/investidura-autorizacion-independent-review.md`): cerró C-1, X-1 a X-4, R26, C1R, C1RR, IA-61 e IA-62.
- **Esta entrega** junta los dos hallazgos bajos de esa revisión y los pendientes de la **revisión transversal del plan contra el código** del 2026-10-07. Esos pendientes nunca se asignaron.
- **Objetivo:** dejar el backend completo frente al plan `docs/plans/2026-09-28-investidura-autorizacion.md` (IA-01 a IA-62), listo para integrar pantallas.

## Restricciones

- **No tocar entornos remotos ni hacer commits:**
  - no desplegar ni commitear;
  - no aplicar migraciones en Neon ni tocar producción;
  - no ejecutar builds.
- **No reabrir cierres previos:** P3-1, P4 a P7, W1, X-1 a X-4, R26, C1-H, C1R-N, C1RR, IA61-H, IA-61 e IA-62.
- **TDD:** registrá la prueba roja antes de cada corrección.
- **Unitarias completas** con `node node_modules/jest/bin/jest.js --no-coverage --forceExit`: 0 fallos.
- **`tsc --noEmit -p tsconfig.build.json`** en 0. **ESLint `--no-fix`** sobre los archivos TS de `git status`.
- **PostgreSQL:** las tres suites en un clúster descartable propio:
  - puerto distinto de 5432, base terminada en `_test`, `log_min_messages = warning`;
  - `SACDIA_POSTGRES_SERVER_LOG` apuntando a su log;
  - nunca el servicio de Homebrew.
- **Contratos:** sincronizá `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, `docs/api/FRONTEND-INTEGRATION-GUIDE.md`, `docs/features/validacion-investiduras.md` y `docs/database/SCHEMA-REFERENCE.md` cuando corresponda.
- **Informe:** si algún ítem queda sin aplicar, el informe tiene que decirlo explícitamente.

## Ítems

### BC-1 (Baja) — Carrera entre leer y escribir en `skipOpenInvestitureMail`

**Hoy:** el `updateMany` que escribe `skipped` (`investiture-communications.service.ts:586-590`) filtra solo por `dispatch_id`. Un worker puede registrar el intento o confirmar `sent` entre la lectura y la escritura, y la fila termina `skipped` (probe `c1rr2-skip-toctou-probe`).

**Corrección:** condicioná la escritura al estado leído y a que no haya intento ante el proveedor, y verificá `count`. Si no coincide, volvé a leer la fila y aplicá la regla de nuevo (`uncertain` o nada).

**Aceptación:** los escenarios R1 y R2 del probe, como prueba. Una fila `sent` nunca pasa a `skipped`.

### BC-2 (Baja) — La zona horaria se normaliza distinto en cada ruta

**Hoy:**
- La ruta del pastor usa `timezone || FALLBACK`, sin `trim` (`investiture-authorization-requests.service.ts:1543-1545`).
- La del certificado usa `trim() || FALLBACK` (`class-certificate-live-authorization.ts:317-320`).

**Corrección:** que las dos rutas normalicen con una sola función. Si la zona es inválida, que respondan con el mismo error controlado; nunca un `RangeError` sin manejar.

**Aceptación:** pruebas con la zona en blanco, con espacios e inválida en las dos rutas.

### BC-3 (Media) — La persona no ve su propio estado (§3.6, §4)

**Hoy:**
- `ownHistory` (`GET investiture-history`) excluye `PENDING`.
- El texto «En espera de autorización.» no existe en el backend.
- La persona investida no recibe su comentario.
- Se expone la diferencia entre `REJECTED_BY_PERSON` y `REJECTED_BY_SYSTEM`.

**Corrección:** la persona ve su propio estado por clase, según §3.6:

| Estado | Qué ve la persona |
| --- | --- |
| Pendiente | «En espera de autorización.», la fecha y la clase |
| Investida | La fecha, la clase y el comentario, si existe |
| Rechazada, por persona o por el sistema | La fecha, la clase y solo «Falta de requisitos para investidura» |
| Cierre anual | No investida, sin texto de requisitos |
| IA-59 / IA-61 | La nota informativa ya definida |

La persona nunca ve el motivo humano ni el texto largo del sistema. La lectura no permite distinguir quién rechazó.

**Aceptación:** una prueba por cada estado, más una de privacidad que verifique que la respuesta no trae `rejection_reason`, `system_reason` ni el tipo de rechazo.

### BC-4 (Media) — Las lecturas devuelven solo IDs (IA-12)

**Hoy:** las vistas de la solicitud para la directiva y para el autorizador devuelven `user_id`, `class_id` y `resolved_by_id`, sin nombres.

**Corrección:** agregá los nombres de la persona, la clase, la sección y quien decidió (o «Sistema» en un rechazo del sistema), respetando la privacidad de §3.6. La directiva ve el motivo humano y el texto largo; el autorizador ve el texto largo.

**Aceptación:** prueba de forma de la respuesta para cada rol.

### BC-5 (Baja) — `super-admin` no puede leer lo que debe corregir (IA-25)

**Hoy:** `super-admin` puede cambiar fechas (`PATCH .../dates`), pero no tiene un endpoint para leer la solicitud ni los `person_id`.

**Corrección:** dale a `super-admin` lectura de la solicitud, sin permiso para autorizar ni para presentar.

**Aceptación:** `super-admin` lee la solicitud. Las acciones que no le corresponden siguen respondiendo 403.

### BC-6 (Media) — Un pastor sin el rol global `pastor` sigue activo

**Hoy:** si se le quita el rol global, la asignación sigue `active`:
- ocupa cupo;
- aparece con `can_authorize: true` en el listado y en `clubs/:id/investiture-authorizers`;
- recibe correos y recordatorios, porque `investiture-communications.loader.ts:268` y `:348` no verifican el rol;
- recibe 403 cuando intenta autorizar.

**Corrección (decisión del usuario, plan §3.7):** una asignación cuyo usuario ya no tiene el rol `pastor`:
- **sigue ocupando cupo** hasta que el Campo o la unión la quiten, para no permitir que se exceda el cupo si el rol vuelve;
- se muestra con `can_authorize: false` y una marca explícita (por ejemplo `role_missing: true`);
- no figura entre los autorizadores;
- no recibe correos de presentación ni recordatorios.

Documentá el comportamiento.

**Aceptación:** prueba de listado, de autorizadores y de los dos tipos de correo. El cupo no cambia.

### BC-7 (Media) — Un recordatorio perdido no se recupera

**Hoy:** el cron envía solo entre las 10:00 y las 10:14 locales (`investiture-communications.rules.ts:393-398`). Si esa corrida no ocurre (caída, despliegue o candado tomado), el recordatorio del día se pierde.

**Corrección (decisión del usuario, plan §3.7):** si el recordatorio del día programado no se ejecutó porque el servicio no estaba disponible, sale en la **primera corrida disponible** del **mismo día local**, desde las 10:00 hasta las 23:59. La deduplicación sigue por ejecución, destinatario, rol y alcance. Nunca sale dos veces el mismo día ni se recupera un día anterior.

**Aceptación:** prueba de una corrida perdida a las 10:00 y recuperada a las 13:00. Otra corrida a las 14:00 no lo duplica. Un día no programado no recupera nada.

### BC-8 (Baja) — Reintentos de recordatorio fuera de calendario

**Hoy:** `reminderRetryDraft` no verifica el día. Un fallo del lunes puede salir el martes, y el miércoles llega otro. Un fallo sin intento ante el proveedor se reintenta cada 15 minutos sin tope.

**Corrección:** el reintento de un recordatorio vale solo dentro del mismo día local de su ejecución. Pasado ese día queda `skipped`, con una causa explícita. Poné un tope de reintentos o un backoff y documentalo.

**Aceptación:** pruebas con un fallo el lunes reintentado el martes (no sale) y un reintento el mismo lunes (sale una vez).

### BC-9 (Media) — `createDraft` deja ítems READY sin validar (IA-55)

**Hoy:** `toItemCreateData` (`certificate-bulk-imports.service.ts:672`) marca `READY` con solo `isReady(item)`, sin la validación de edad, catálogo ni fecha que se aplica al marcar listo.

**Corrección:** al crear, aplicá la misma validación que al marcar listo. Si falla, el ítem nace `NEEDS_REVIEW` con su motivo.

**Aceptación:** un `POST` con `mark_as_ready: true` y la edad inválida deja el ítem en `NEEDS_REVIEW`. Con datos válidos, nace `READY`.

### BC-10 (Baja) — Tres avisos de resultado en lugar de dos (§3.5)

**Hoy:** si en un mismo grupo hay un rechazo humano y uno del sistema, la directiva recibe tres avisos.

**Corrección (decisión del usuario, plan §3.7):** la directiva recibe como máximo dos avisos: uno de investidos y uno de rechazados. El de rechazados junta los rechazos del pastor o del Campo y los del sistema; lista lista a cada persona e indica quién decidió en cada caso (la persona o «el sistema», con el texto largo cuando decidió el sistema). Sin el motivo humano.

**Aceptación:** prueba con un grupo mixto de tres tipos de resultado: exactamente dos avisos a la directiva, con el contenido correcto.

### BC-11 (Baja) — Escrituras de progreso sobre INVESTIDO o EXPIRED

**Hoy:**
- `submitSection` (`classes.service.ts` ~L1546) no llama a `assertProgressMutable`.
- La aprobación y el rechazo de evidencias no tienen guarda para `INVESTIDO` ni `EXPIRED`.

La prueba de IA-40 exige que esas escrituras no se habiliten.

**Corrección:** aplicá la guarda existente en esas rutas.

**Aceptación:** sobre un enrollment `INVESTIDO` o `EXPIRED`, enviar una sección y aprobar o rechazar una evidencia responden con el error de progreso bloqueado, sin escribir.

### BC-12 (Baja) — El porcentaje se puede editar en un año cerrado

**Hoy:** `field-class-threshold-config.service.ts` no verifica `year.active`. Un año cerrado administrativamente se puede editar si el día de hoy cae dentro de sus fechas.

**Corrección:** rechazá la edición si el año no está activo, para todos los roles.

**Aceptación:** prueba con el año inactivo y la fecha dentro del rango.

### BC-13 (Baja) — Falta auditoría y reloj en `changeDates` y `remove`

**Hoy:**
- El cambio de fecha no guarda quién lo hizo (`_actorId`).
- `remove` y `changeDates` usan `new Date()` en lugar del reloj inyectable.

**Corrección:** guardá el actor y el instante del cambio de fecha y usá el reloj inyectable. Si hace falta una columna nueva, creá su migración y no la apliques en Neon.

**Aceptación:** pruebas del actor guardado y del reloj inyectado.

### BC-14 (Baja) — `district_investiture_pastors.user_id` sin FK

**Corrección:** agregá la FK a `users` en una migración nueva, verificando antes que no haya huérfanos en la base de prueba. No la apliques en Neon. Actualizá `docs/database/`.

### BC-15 (Baja) — Código muerto

**Corrección:** eliminá `closePendingByYearEnd` (`investiture-authorization-requests.service.ts` ~L950), si sigue sin uso, junto con cualquier otro helper que haya quedado sin uso en esta implementación.

## Fuera de esta entrega

- Las pantallas de la app y del panel.
- La fase 8, que es apagar la vía vieja.
- La aplicación de migraciones en Neon y el despliegue.

## Entrega esperada

Agregá a `docs/reviews/investidura-autorizacion-implementation-report.md` una sección «Cierre del backend (BC-1 a BC-15)» con:

1. Por ítem: el archivo y la línea, la salida roja, la salida verde y la decisión tomada.
2. Las unitarias completas (con el comando exacto), las tres suites de PostgreSQL (con el puerto, el log, `log_min_messages`, las líneas ERROR de control y las de `deadlock detected`), `tsc` y ESLint.
3. Las migraciones nuevas, sin aplicar.
4. Los contratos actualizados.
5. Una matriz IA-01 a IA-62 actualizada con el estado del backend de cada regla (implementado, parcial o fuera de backend), con evidencia.
6. Los límites de la evidencia y la confirmación de que los cierres previos siguen pasando.

No des nada por cerrado: queda pendiente de revisión independiente.
