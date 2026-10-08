# Prompt — C-1 residual (C1-H1 a C1-H5) + R26-1 a R26-5

## Contexto

Trabajás en `/Users/abner/Documents/development/sacdia`, rama `development` de `sacdia-backend`, sobre `113d8ba` más los cambios sin commit. La revisión independiente 27 (2026-10-07, en `docs/reviews/investidura-autorizacion-independent-review.md`) dejó **C-1 NO CERRADO** y confirmó que **R26-1 a R26-5 no se aplicaron**, así que la CI sigue en rojo.

Leé:

- Las secciones de las revisiones 26 y 27.
- El prompt `docs/reviews/investidura-autorizacion-prompt-r26.md`, que sigue vigente y forma parte de esta entrega.
- Los probes `docs/reviews/investidura-autorizacion-review-evidence/c1-multiyear-deadlock-probe.cjs`, `c1-cert-race-reason-probe.cjs` y `h1h5-flag-off-queued-probe.cjs`, con sus `.log`, y `c1-deadlock-pglog.txt`.
- La spec, en IA-57 a IA-60 del plan (§3.9).

## Restricciones

- No desplegar, no commitear, no aplicar migraciones en Neon ni tocar producción. No ejecutar builds.
- Se permite: Jest, `tsc --noEmit -p tsconfig.build.json`, ESLint y PostgreSQL o Redis aislados de loopback.
- No modificar el informe independiente ni los probes existentes.
- No reabrir cierres previos: P3-1, P4, P5, P6, P7, W1, X-1 (H1–H5), X-2, X-3, X-4, IA-58, ni lo verificado de IA-59 e IA-60.
- **TDD:** registrá la prueba roja antes de cada corrección.
- **Criterio de entrega no negociable:** `pnpm run test` completo con **0 fallos**, y las tres suites PostgreSQL (`investiture-authorization-requests`, `district-investiture-pastors` y `certificate-import`) en verde. Si algo falla, la entrega no está lista: no la reportes como hecha.

## Parte 1 — R26-1 a R26-5

Aplicá **íntegro** `docs/reviews/investidura-autorizacion-prompt-r26.md`:

- R26-1: `resend.provider.spec.ts`.
- R26-2: lint de las specs.
- R26-3: el procesador de correo debe consultar `INVESTITURE_EMAIL_ENABLED`.
- R26-4: la prueba real del apagado.
- R26-5: la validación cruzada de interruptores.

## Parte 2 — C-1 residual

### C1-H1 (Alta) — «Mismo año» decidido con el año de inicio del enrollment

**Hoy:** `class-certificate-live-authorization.ts:86-89` (`operationalYearId`) y `:162-195` (`sameYearPeople`, `earlierPeople`) comparan el año del certificado con `enrollment.ecclesiastical_year_id`. En las clases con `max_duration_years > 1`, ese valor es el año de **inicio** de la inscripción, no el año de la solicitud (ver P4-1).

**Escenarios reproducidos** (enrollment iniciado en 2025, persona `PENDING` en la solicitud de 2026):

- **Certificado de 2026:** se acepta. Crea un histórico `INVESTIDO` y la persona sigue `PENDING`. El certificado le gana a la autorización en el año en curso, y eso viola IA-57.
- **Guía Mayor con certificado de 2026:** la inscripción operativa pasa a histórica, el `PENDING` queda huérfano y la persona sigue recibiendo recordatorios.
- **Certificado de 2025:** se rechaza indebidamente. Según IA-59 debía acreditarse y retirar a la persona.

**Corrección:** la regla se decide contra el año eclesiástico de la **solicitud** del registro `PENDING` (`investiture_authorization_requests.ecclesiastical_year_id`):

- Si el año del certificado es el de la solicitud, aplica IA-57: se rechaza.
- Si el año del certificado es anterior al de la solicitud, aplica IA-59: se acredita y la persona se retira con `HISTORICAL_CERTIFICATE_APPLIED`.
- Sin `PENDING`, todo queda como hoy.

La misma regla vale para el aviso temprano (marcar listo, enviar, reenviar), para `substituteGuideMajor` y para la aprobación institucional.

**Aceptación:** pruebas de unidad y PostgreSQL para los tres escenarios de arriba, más el control con un certificado de 2019. Con una clase de un año el comportamiento no cambia.

### C1-H2 (Media) — Interbloqueo con `closeYear`

**Hoy:**

- **La aprobación** toma `FOR SHARE` sobre la fila de `ecclesiastical_years` (`class-certificate-historical-age.ts:160`) y después espera el candado advisory de usuario (`class-certificate-live-authorization.ts:234`).
- **`closeYear`** toma los candados de año, sección, usuario y enrollment (`investiture-year-close.ts:80-88`) y después hace `UPDATE ecclesiastical_years` (`year-end.service.ts:184`).
- PostgreSQL detectó `deadlock detected` (`c1-deadlock-pglog.txt`). La aprobación institucional tiene el mismo riesgo.

**Corrección:** un orden global de candados sin ciclos. Una opción: que la aprobación tome el candado advisory del año (el mismo que usan presentar y `closeYear`) **antes** del `FOR SHARE` de filas y del candado de usuario. Otra: no mantener el `FOR SHARE` del año mientras espera los candados advisory. Elegí una y justificala con el orden completo de cada camino:

- presentar y agregar;
- resolver;
- `closeYear`;
- el barrido de `year-cut`;
- guardar la ventana;
- retirar un pastor;
- las vías anteriores;
- la aprobación por ítem;
- la aprobación institucional.

Además, el candado de usuario solo debería tomarse si existe un `PENDING` relevante. Si no se puede, documentá por qué.

**Aceptación:** prueba PostgreSQL de `closeYear` contra la aprobación de un certificado, en ambos órdenes, **sin** `deadlock detected` en el log del servidor y con un resultado coherente (cierre aplicado y certificado aprobado o rechazado según IA-57/IA-59).

### C1-H3 (Baja) — `certificate-import-postgres` en 9/10

**Hoy:** «keeps one historical enrollment when two approvals race» falla con `CERTIFICATE_IMPORT_BIRTHDAY_REQUIRED`, porque el fixture no tiene fecha de nacimiento desde la fase 0B.

**Corrección:** agregar una fecha de nacimiento válida al fixture y verificar que la prueba vuelve a ejercer la carrera.

**Aceptación:** 10/10.

### C1-H4 (Baja, bloquea CI) — `club-assignment-effectivity.inventory.spec.ts` en rojo

**Hoy:** falla por dos consultas sin clasificar:

- el anuario (`investiture-authorization-requests.service.ts:489`);
- `investiture-communications.loader.ts:84`.

Además, ya estaba rojo en `113d8ba` por un inventario vencido de `class-requirement-eligibility`.

**Corrección:** clasificar esas consultas según el criterio del inventario (efectividad de asignaciones de club) y actualizar la entrada vencida. No relajes la prueba.

**Aceptación:** la suite en verde, con la justificación de cada clasificación en el informe.

### C1-H5 (Baja) — Lectura informativa no determinista

**Hoy:** `list()` elige la solicitud informativa con `findFirst` sin `orderBy` (`investiture-authorization-requests.service.ts:366`).

**Corrección:** agregar un orden determinista y documentar el criterio.

## Fuera de esta entrega

Las pantallas y la fase 8.

## Entrega esperada

Agregá a `docs/reviews/investidura-autorizacion-implementation-report.md` dos secciones: «R26-1 a R26-5» y «C-1 residual (C1-H1 a C1-H5)». Cada una con:

1. Por hallazgo: archivo y línea, salida roja, salida verde y la decisión tomada.
2. El orden global de candados, en una tabla por camino.
3. `pnpm run test` completo **con 0 fallos** (suites y pruebas), las tres suites PostgreSQL con su conteo, `tsc` y ESLint `--no-fix` sobre la lista de archivos tocados, specs incluidas.
4. Cambios de configuración y de contrato, en `.env.example`, el runbook y `docs/api/`.
5. Límites de la evidencia y la confirmación de que los cierres previos siguen pasando.

No des nada por cerrado: queda pendiente de revisión independiente.
