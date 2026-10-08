# Prompt — Residuos del cierre del backend (BCR-1 a BCR-9)

## Contexto

Trabajás en `/Users/abner/Documents/development/sacdia`, rama `development` de `sacdia-backend`, sobre `113d8ba` más los cambios sin commit. La revisión independiente 32 (2026-10-07, en `docs/reviews/investidura-autorizacion-independent-review.md`) **no aprobó todavía el cierre del backend**:

- **Aceptados:** BC-1, BC-2, BC-3, BC-6, BC-10, BC-12, BC-13, BC-14 y BC-15.
- **Con observaciones:** BC-5, BC-7 y BC-9.
- **Con problemas:** BC-4 parcial, BC-11 excede el contrato y BC-8 parcial.

Leé esa sección, el contrato original en `docs/reviews/investidura-autorizacion-prompt-backend-cierre.md`, las decisiones del usuario en el plan (§3.7, «Decisiones del 2026-10-07 (cierre del backend)») y los probes `docs/reviews/investidura-autorizacion-review-evidence/bc-section-name-pg-probe.cjs` y `bc-reminder-retry-cap-probe.cjs` con sus `.log`.

## Restricciones

- **No tocar entornos remotos:** no desplegar, no commitear, no aplicar migraciones en Neon ni tocar producción, no ejecutar builds.
- **No reabrir cierres previos ni los BC aceptados.**
- **No modificar** el informe independiente ni los probes existentes.
- **TDD obligatorio, con corrida roja registrada por ítem antes de editar.** En las dos últimas entregas no se hizo, y BCR-1 pasó justo por un mock que ocultaba el defecto. Para lo que toque datos reales, la prueba roja tiene que ser de PostgreSQL, no solo de unidad con mocks.
- **Verificación obligatoria:**
  - unitarias completas con `node node_modules/jest/bin/jest.js --no-coverage --forceExit`: 0 fallos;
  - `tsc --noEmit -p tsconfig.build.json`: salida 0;
  - ESLint `--no-fix` sobre los archivos TS de `git status`;
  - las tres suites de PostgreSQL en un clúster descartable propio: puerto distinto de 5432, `log_min_messages = warning`, `SACDIA_POSTGRES_SERVER_LOG` apuntando a su log, sin usar Homebrew.
- **Si algo queda sin aplicar, decilo explícitamente en el informe.**

## Ítems

### BCR-1 (Media) — `section_name` siempre sale null (IA-12)

**Hoy:** `requestLabels` (`investiture-authorization-requests.service.ts:1890-1897`) llama a `club_sections.findUnique` sin `include: { club_types }`, y `club_sections` no tiene columna `name`. La prueba unitaria pasa solo porque el mock devuelve `club_types`.

**Corrección:**
- Incluir `club_types` en la consulta.
- Quitar la rama `section?.name`, que no existe en el modelo.
- Ajustar el mock al modelo real.

**Aceptación:** una prueba de PostgreSQL que lea la solicitud como directiva y como autorizador, y obtenga el nombre real de la sección.

### BCR-2 (Media) — BC-11 bloquea más que `INVESTIDO` y `EXPIRED`

**Hoy:** `assertEnrollmentProgressOpen` (`evidence-review.service.ts:1094`, `:1186`, `:1337`) usa `assertClassProgressMutable` (`class-progress-mutable.ts:4-23`). Ese helper también bloquea `locked_for_validation` y los estados `SUBMITTED`, `CLUB_APPROVED`, `COORDINATOR_APPROVED` y `FIELD_APPROVED`. Por eso aprobar o rechazar evidencias falla ahora mientras hay un expediente del flujo anterior en curso, y en `113d8ba` eso funcionaba.

**Corrección:**
- La guarda nueva de BC-11 en revisión de evidencias y en `submitSection` bloquea **solo** `INVESTIDO` y `EXPIRED`, como pedía el contrato.
- Se conservan el bloqueo de `PENDING` de la solicitud nueva (P4-3) y el comportamiento que el flujo anterior tenía en `113d8ba`.
- La comprobación corre dentro de la transacción que escribe, bajo el candado de enrollment que ya usan esas rutas, para cerrar la carrera contra un `INVESTIDO` recién confirmado.

**Aceptación:**
- Revisar evidencias de un enrollment en `SUBMITTED_FOR_VALIDATION` o con `locked_for_validation` se comporta igual que en `113d8ba`.
- Con `INVESTIDO` o `EXPIRED`, responde `CLASS_PROGRESS_LOCKED` sin escribir.
- Una prueba de PostgreSQL cubre la carrera entre una resolución que inviste y una aprobación de evidencia, en ambos órdenes.

### BCR-3 (Baja) — Tope de reintentos de recordatorio

**Hoy:**
- `recoverRow` re-encola el job `failed` mediante `retryFailedInvestitureJob` (`investiture-communications.service.ts:776`) sin incrementar `attempts`. En 20 corridas hubo 20 re-encolados y `attempts` quedó en 1.
- Error por uno: salen 4 envíos en lugar de 5.

**Corrección:** que todo camino de reintento cuente contra el mismo tope de 5, incluido el re-encolado, y que el tope signifique exactamente 5 intentos ante el proveedor.

**Aceptación:** el probe `bc-reminder-retry-cap-probe` convertido en prueba, con exactamente 5 intentos y después `skipped` con la causa del tope.

### BCR-4 (Baja) — La matriz C del informe está desactualizada

**Hoy:** marca «Pendiente» o «Autorizar no tiene ruta» en IA-03, 07, 09, 10, 27, 28 y 29.

**Corrección:** actualizar la matriz IA-01 a IA-62 completa con el estado real y una referencia `archivo:línea` por regla.

### BCR-5 (Baja) — BC-7: envío tardío cuando la corrida de las 10:00 sí ocurrió

**Hoy:** `dueReminders` (`investiture-communications.rules.ts:419-500`) no guarda estado. Entre las 10:00 y las 23:59 le envía a cualquier destinatario sin fila del día, aunque la corrida de las 10:00 haya ocurrido y esa persona no tuviera pendientes en ese momento.

La decisión del usuario dice que el recordatorio se recupera **si la corrida de las 10:00 no ocurrió**.

**Corrección:** registrar la ejecución del día por Campo y por rol, o un equivalente. Si la corrida del día ya se hizo, no generar recordatorios tardíos para destinatarios nuevos.

**Aceptación:**
- Corrida de las 10:00 hecha sin pendientes, pendiente nuevo a las 15:00: no sale recordatorio ese día.
- Corrida de las 10:00 perdida: la de las 13:00 envía una sola vez.

### BCR-6 (Baja) — BC-6: detalles del pastor sin rol

**Hoy:**
- El listado compara el rol sin distinguir mayúsculas y con `GLOBAL`; el cargador de correos compara `'pastor'` exacto.
- Un pastor con la cuenta eliminada lógicamente sigue con `can_authorize: true` en el listado y entre los autorizadores.

**Corrección:**
- Una sola función decide si una asignación habilita autorizar. Exige el rol global `pastor` y una cuenta activa, no eliminada.
- La usan el listado, los autorizadores, la resolución y los correos.
- La cuenta eliminada se trata igual que el rol faltante: sigue ocupando cupo, aparece marcada y no autoriza ni recibe correos.

**Aceptación:** pruebas del listado, de los autorizadores, de la resolución y de los correos con una cuenta eliminada.

### BCR-7 (Baja) — BC-5: privacidad de `super-admin`

**Hoy:** `super-admin` recibe la forma de la directiva, que incluye el motivo humano, y §3.6 no se lo asigna.

**Corrección:** `super-admin` recibe la forma del autorizador, sin el motivo humano. Le alcanza para corregir fechas.

**Aceptación:** prueba de forma de la respuesta.

### BCR-8 (Baja) — BC-2: una zona inválida bloquea la lectura

**Hoy:** `readForAuthorizer` llama a `loadContext`. Si la zona guardada es inválida, la lectura (incluida la de `super-admin`) responde 400.

**Corrección:** que la lectura no dependa de la validez de la zona. Las operaciones de escritura siguen rechazando una zona inválida con `INVESTITURE_REQUEST_TIME_ZONE_INVALID`.

**Aceptación:** lectura correcta con una zona inválida; presentar y resolver siguen rechazados.

### BCR-9 (Baja) — BC-9: falta validar la fecha futura al crear

**Hoy:** al crear no se aplica `assertNotFuture` (`certificate-bulk-imports.service.ts:684-713`). El contrato pedía la misma validación que al marcar listo, con edad, catálogo y fecha.

**Corrección:** aplicar `assertNotFuture` al crear. Si falla, el ítem nace `NEEDS_REVIEW` con su motivo.

**Aceptación:** alta con `mark_as_ready: true` y fecha futura: el ítem nace `NEEDS_REVIEW`.

## Fuera de esta entrega

- Las pantallas y la fase 8.
- Las migraciones en Neon.
- La falla preexistente de `20260409100000_legacy_scoring_migration` al reproducir el historial desde cero. Si la encontrás, documentala, pero no la corrijas aquí.

## Entrega esperada

Agregá a `docs/reviews/investidura-autorizacion-implementation-report.md` una sección «BCR-1 a BCR-9» con:

1. Por ítem: archivo y línea, el comando y la salida de la corrida roja, la salida verde y la decisión tomada.
2. Los conteos completos:
   - unitarias, con el comando exacto;
   - PostgreSQL, con el puerto, el log, `log_min_messages`, las líneas ERROR de control y las de `deadlock detected`;
   - `tsc` y ESLint.
3. La matriz IA-01 a IA-62 actualizada (BCR-4).
4. Los límites de la evidencia y la confirmación de que los cierres previos siguen pasando.

No des nada por cerrado: queda pendiente de revisión independiente.
