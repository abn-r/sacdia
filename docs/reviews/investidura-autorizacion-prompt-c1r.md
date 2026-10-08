# Prompt — C1R-N1 a C1R-N5 y lint residual

## Contexto

Trabajás en `/Users/abner/Documents/development/sacdia`, rama `development` de `sacdia-backend`, sobre `113d8ba` más los cambios sin commit. La revisión independiente 28 (2026-10-07, en `docs/reviews/investidura-autorizacion-independent-review.md`) dejó C-1 **cerrado con observaciones** y abrió C1R-N1 a C1R-N5. Leé esa sección y los probes `docs/reviews/investidura-autorizacion-review-evidence/c1r-submit-year-order-probe.cjs` y `c1r-crossyear-close-probe.cjs`, con sus `.log`, y `c1r-pglog.txt`.

**Ojo:** otra sesión puede estar editando `certificate-import-files.service.spec.ts` y `certificate-import-pdf*`. No toques esos archivos fuera de lo necesario y, si tu suite falla ahí, verificá si el cambio es tuyo antes de corregir.

## Restricciones

- No desplegar, no commitear, no aplicar migraciones en Neon ni tocar producción. No ejecutar builds.
- Se permite: Jest, `tsc --noEmit -p tsconfig.build.json`, ESLint y PostgreSQL o Redis aislados de loopback.
- No modificar el informe independiente ni los probes existentes.
- No reabrir cierres previos: P3-1, P4, P5, P6, P7, W1, X-1, X-2 a X-4, R26-1, R26-3, R26-4, C1-H1 a C1-H5.
- **TDD:** registrá la prueba roja antes de cada corrección.
- **Unitarias completas con `node node_modules/jest/bin/jest.js --no-coverage --forceExit`.** No uses `pnpm run test -- …`: no ejecuta pruebas. Tienen que quedar 0 fallos.
- Corré las tres suites de PostgreSQL (`investiture-authorization-requests`, `district-investiture-pastors` y `certificate-import`) en verde.
- **Interbloqueos:** la evidencia es el log del servidor PostgreSQL (sin `deadlock detected`), no `pg_stat_database.deadlocks`, que se actualiza con retraso (C1R-N5).

## C1R-N1 (Media) — Interbloqueo entre envíos de lotes

**Hoy:** `assertClassCertificateHistoricalAge` toma el candado advisory de año (`class-certificate-historical-age.ts:168-175`). `submit()` (`certificate-bulk-imports.service.ts:465-484`) lo llama por cada ítem, en el orden de un `findMany` sin `orderBy`. Si dos lotes se envían a la vez, uno con ítems 2026→2025 y otro 2025→2026, se produce `deadlock detected` 3 de 3 veces.

**Corrección:** en todo camino que procese varios ítems o varios años (enviar, reenviar, aprobación en lote si existe, aprobación institucional y el barrido de `year-cut` con varios años terminados), resolver primero **todos** los años involucrados y tomar sus candados en orden ascendente **antes** del bucle. Dentro del bucle, la validación por ítem no debe tomar candados de año fuera de ese orden: que reutilice los ya tomados, sin volver a adquirirlos en otro orden.

**Aceptación:**
- El probe `c1r-submit-year-order-probe` reproducido como e2e de PostgreSQL: dos lotes con años cruzados, ambos órdenes, sin `deadlock detected` en el log del servidor y con los dos envíos terminados correctamente.
- Lo mismo para el barrido de `year-cut` con dos años terminados contra un envío de lote, o la justificación de por qué no puede ciclar.

## C1R-N2 (Baja) — Certificado de un año posterior a la solicitud

**Hoy:** una solicitud de 2025 sigue `PENDING` porque el año terminó pero el barrido de `year-cut` todavía no corrió. Si llega un certificado de 2026, se aprueba y la persona sigue `PENDING`. En Guía Mayor, `substituteGuideMajor` deja ese `PENDING` huérfano.

**Corrección:** según IA-30, un `PENDING` cuyo año de solicitud ya terminó (año inactivo o día local posterior a `end_date`) está muerto aunque el cierre no haya corrido. Al aprobar, cerralo como `CLOSED_YEAR` reutilizando la operación idempotente del cierre anual: misma transacción, candado del año de la solicitud dentro del orden global de C1R-N1, sin texto de falta de requisitos y sin evento. Después, el certificado se evalúa como si no hubiera `PENDING`.

**Aceptación:** pruebas de unidad y PostgreSQL con solicitud de 2025 terminada y certificado de 2026, en clase normal y en Guía Mayor: la persona queda `CLOSED_YEAR`, el certificado se acredita y no queda `PENDING` huérfano.

## C1R-N3 (Media) — La bandeja de resultados no se recupera con el interruptor apagado

**Hoy:** `deliverPending` (`investiture-communications.service.ts:261-267`) retorna antes de recuperar `RESULT` si `INVESTITURE_EMAIL_ENABLED` está apagado, que es el valor por defecto. Las notificaciones de resultado fallidas nunca se reintentan. Es una regresión de la recuperación de P6-1.

**Corrección:** con el interruptor apagado, solo se omiten y se marcan `PRESENTATION` y `REMINDER`. La recuperación de `RESULT` corre siempre.

**Aceptación:** con el interruptor apagado, un `RESULT` fallido se recupera y llega a la bandeja una sola vez, y ningún correo sale. Con el interruptor encendido no cambia nada.

## C1R-N4 (Baja) — Fila posiblemente enviada queda `skipped`

**Hoy:** el procesador consulta el interruptor antes de `providerAttempt` (`email.processor.ts:207`). Una fila con un intento previo, que el proveedor quizá aceptó, termina `skipped`.

**Corrección:** si ya existe un intento ante el proveedor cuyo resultado se desconoce, la fila queda `uncertain` (como en P6-2), no `skipped`. `skipped` solo vale cuando el proveedor nunca recibió el envío.

**Aceptación:** prueba con un intento registrado, el interruptor apagado y un reintento: la fila queda `uncertain` y el proveedor no se vuelve a llamar.

## C1R-N5 (Baja) — Evidencia débil de interbloqueo

**Corrección:** que las e2e de candados verifiquen la ausencia de interbloqueo con el código de error del cliente (sin `40P01`) y documenten el log del servidor como evidencia. Quitá o corregí cualquier aserción basada solo en el delta inmediato de `pg_stat_database.deadlocks`.

## Lint residual (R26-2)

`src/common/guards/permissions.guard.spec.ts` tiene 2 errores de prettier (L5 y L342). Corregilos sin reformatear líneas ajenas. ESLint `--no-fix` debe dar 0 sobre **todos** los archivos TS modificados en el árbol de este trabajo; la lista se saca de `git status`, no a mano.

## Fuera de esta entrega

Las pantallas y la fase 8.

## Entrega esperada

Agregá a `docs/reviews/investidura-autorizacion-implementation-report.md` una sección «C1R-N1 a C1R-N5» con:

1. Por hallazgo: archivo y línea, salida roja, salida verde y la decisión tomada.
2. La tabla actualizada del orden global de candados por camino.
3. Los conteos de las unitarias completas (comando exacto), de las tres suites de PostgreSQL y de `tsc`, y ESLint sobre la lista sacada de `git status`.
4. Los extractos del log del servidor PostgreSQL usados como evidencia.
5. Los límites de la evidencia y la confirmación de que los cierres previos siguen pasando.

No des nada por cerrado: queda pendiente de revisión independiente.
