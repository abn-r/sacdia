# Prompt — R26-1 a R26-5 (higiene de CI e interruptor de correo)

## Contexto

Trabajás en `/Users/abner/Documents/development/sacdia`, rama `development` de `sacdia-backend`, sobre `113d8ba` más los cambios sin commit. La revisión independiente 26 (2026-10-07, en `docs/reviews/investidura-autorizacion-independent-review.md`) dejó X-1 **cerrado con observaciones** y abrió R26-1 a R26-5. Leé esa sección y el probe `docs/reviews/investidura-autorizacion-review-evidence/h1h5-flag-off-queued-probe.cjs` junto con su `.log`.

## Restricciones

- No desplegar, no commitear, no aplicar migraciones en Neon ni tocar producción. No ejecutar builds.
- Se permite: Jest, `tsc --noEmit -p tsconfig.build.json`, ESLint y PostgreSQL o Redis aislados de loopback.
- No modificar el informe independiente ni los probes existentes.
- No reabrir cierres previos: P3-1, P4, P5, P6, P7, W1, X-1 (H1–H5), X-2, X-3 y X-4.
- **TDD:** registrá la prueba roja antes de corregir R26-3, R26-4 y R26-5.
- **Corré la suite unitaria completa** (`pnpm run test`), no solo un filtro. En la entrega anterior se rompió `resend.provider.spec.ts` porque no se corrió.

## R26-1 (Media, bloquea CI) — `resend.provider.spec.ts` en rojo

`ResendProvider.send` ahora recibe un segundo argumento (la clave de idempotencia) y dos pruebas de `src/common/email/providers/resend.provider.spec.ts` fallan: reciben `(payload, undefined)`.

**Corrección:** actualizar las pruebas al contrato nuevo y agregar una que verifique que la clave de idempotencia llega al SDK cuando se envía.

**Aceptación:** `pnpm run test` completo en verde, con el conteo total en el informe.

## R26-2 (Baja) — Lint de las specs nuevas

Hay 171 errores de prettier en `investiture-authorization-requests.service.spec.ts:1763-1793` y en `test/investiture-authorization-requests-postgres.e2e-spec.ts:3254+`, y 5 `no-useless-assignment` en L3337-3341. Además, el informe anterior declaró ESLint 0, y no era cierto.

**Corrección:** formatear solo esos bloques nuevos y corregir las asignaciones inútiles, sin reformatear líneas viejas ajenas.

**Aceptación:** ESLint `--no-fix` en salida 0 sobre todos los archivos tocados por X-1 y R26, specs incluidas, con la lista de archivos en el informe.

## R26-3 (Baja) — El procesador de correo no consulta el interruptor

**Hoy:**
- `email.processor.ts:190-255` solo mira `EMAIL_ENABLED`.
- `prepare` (`investiture-communications.service.ts:302`) solo descarta filas `sent` o `skipped`.
- Un job de presentación o de recordatorio encolado con `INVESTITURE_EMAIL_ENABLED` encendido sale aunque después se apague (probe S1: 1 envío, fila `sent`).
- `skipOpenInvestitureMail` (`:532`) marca `queued`/`sending` como `skipped` aunque el job siga vivo en Redis.

**Corrección:**
1. Antes de llamar al proveedor, el camino de entrega de investidura (`prepare`/`deliveryStillAllowed` o el gate del procesador) vuelve a comprobar el interruptor. Si está apagado, la fila queda `skipped` con `investiture_email_disabled` y el proveedor no recibe nada.
2. La fila nunca debe quedar `skipped` si el proveedor aceptó el envío, ni `sent` si no lo aceptó.
3. Los resultados (`RESULT`, la bandeja de la app) siguen sin depender del interruptor.

**Aceptación:** prueba con Redis aislado o con el doble actual: encolar con el interruptor encendido, apagarlo y procesar. El resultado debe ser 0 envíos y la fila `skipped`. Con el interruptor encendido el envío sigue funcionando.

## R26-4 (Baja) — El apagado no tiene prueba real

**Hoy:** el doble en memoria (`matchesDispatch`, `investiture-communications.delivery.spec.ts` ~L103) no soporta `kind: { in: [...] }`. La prueba «does not send investiture mail while the switch is off…» pasa sin filas `REMINDER`, porque un `.every` sobre una lista vacía siempre da verdadero.

**Corrección:** que el doble soporte `in` y que la prueba siembre filas `PRESENTATION` y `REMINDER` en `pending`, `failed`, `queued` y `sending`. Debe afirmar explícitamente la cantidad de filas `skipped` y que las `RESULT` no se tocan.

**Aceptación:** con el código actual de `skipOpenInvestitureMail`, la prueba nueva tiene que fallar (o explicar por qué no) y quedar en verde junto con R26-3.

## R26-5 (Baja) — Falta validación cruzada de interruptores

**Hoy:** `INVESTITURE_EMAIL_ENABLED=true` con `EMAIL_ENABLED=false` es válido en Joi. Los jobs quedan `failed`, `deliverPending` los reintenta y, al encender el correo global, podría salir un lote acumulado.

**Corrección (elegí una y justificala):**
- Opción a: `env.validation` rechaza `INVESTITURE_EMAIL_ENABLED=true` cuando `EMAIL_ENABLED` no es `true`.
- Opción b: en esa combinación, la investidura trata el correo como apagado (`skipped`, sin reintentos).

**Aceptación:** prueba de `env.validation` o de entrega según la opción elegida, demostrando que al encender el correo global no sale ningún lote acumulado.

## Fuera de esta entrega

La conciliación de certificados, las pantallas y la fase 8.

## Entrega esperada

Agregá a `docs/reviews/investidura-autorizacion-implementation-report.md` una sección «R26-1 a R26-5» con:

1. Por hallazgo: archivo y línea, la salida roja (si corresponde), la salida verde y la decisión tomada.
2. El conteo total de `pnpm run test` (suites y pruebas), más PostgreSQL y Redis aislados si los corriste, `tsc` y ESLint sobre la lista de archivos.
3. Los cambios de configuración, documentados en `.env.example` y en el runbook.
4. Los límites de la evidencia.
5. La confirmación de que los cierres previos siguen pasando.

No des R26-1 a R26-5 por cerrados: quedan pendientes de revisión independiente.
