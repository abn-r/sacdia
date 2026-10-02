# Revisión independiente — investidura por autorización

**Primera revisión:** 2026-09-30. **Última verificación:** 2026-10-02.
**Veredicto vigente:** P4-4 CERRADO; P4-1, P4-2 y P4-3 siguen cerrados. Backend de fase 4 verificado en el alcance revisado; puede continuar el desarrollo de fase 5. No se certifica fase 4 completa (UI/integración pendiente). Fase 2 PARCIAL; despliegue bloqueado y pipeline anterior activo.
**Estado del plan completo:** PARCIAL. Cambio de vía y despliegue siguen BLOQUEADOS.

## Undécima revisión — cierre de P4-4 residual (2026-10-02)

Esta es la **revisión vigente**, sobre backend `development` @ `9d8fe1d3d1fd0e56256043ee8208d26c9bfcc39b`, sin commit. **P4-4 CERRADO; P4-1, P4-2 y P4-3 permanecen cerrados.** El backend de fase 4 queda verificado en el alcance revisado y permite continuar el desarrollo de fase 5. No equivale a aprobar la fase 4 completa: falta su pantalla e integración, la fase 2 continúa parcial y el despliegue sigue bloqueado.

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
