# Prompt — C1RR-1 a C1RR-3

## Contexto

Trabajás en `/Users/abner/Documents/development/sacdia`, rama `development` de `sacdia-backend`, sobre `113d8ba` más los cambios sin commit. La revisión independiente 29 (2026-10-07, en `docs/reviews/investidura-autorizacion-independent-review.md`) dejó **C-1 cerrado con observaciones** y abrió tres hallazgos de prioridad baja: C1RR-1, C1RR-2 y C1RR-3. Leé esa sección y el probe `docs/reviews/investidura-autorizacion-review-evidence/c1rr-bulk-skip-attempt-probe.cjs` junto con su `.log`.

## Restricciones

- No desplegar, no commitear, no aplicar migraciones en Neon ni tocar producción. No ejecutar builds.
- Se permite: Jest, `tsc --noEmit -p tsconfig.build.json`, ESLint y PostgreSQL aislado de loopback.
- **PostgreSQL:** usá un clúster descartable propio (`initdb` + `pg_ctl -l <log>` en un puerto que no sea 5432, base terminada en `_test`) y pasale su log con `SACDIA_POSTGRES_SERVER_LOG`. No uses el servicio de Homebrew del usuario.
- No modificar el informe independiente ni los probes existentes.
- No reabrir cierres previos: P3-1, P4, P5, P6, P7, W1, X-1, X-2 a X-4, R26, C1-H1 a C1-H5, C1R-N1 a C1R-N5.
- **TDD:** registrá la prueba roja antes de cada corrección.
- Unitarias completas con `node node_modules/jest/bin/jest.js --no-coverage --forceExit`, con 0 fallos. Las tres suites de PostgreSQL en verde. ESLint `--no-fix` sobre los archivos TS de `git status`.

## C1RR-1 — El cron marca `skipped` filas con intento ante el proveedor

**Hoy:** con el interruptor apagado, `skipOpenInvestitureMail` (`investiture-communications.service.ts:562-573`), llamado desde `deliverPending:264`, marca `skipped` sin filtrar filas que ya tienen un intento registrado. Si el cron corre antes que el job, una fila que el proveedor quizá aceptó queda `skipped` en vez de `uncertain` (escenarios A y B del probe).

**Corrección:**
- Aplicar la misma regla de C1R-N4 que ya usa el procesador: una fila con intento ante el proveedor pasa a `uncertain` y no se reenvía; `skipped` queda solo para filas que el proveedor nunca recibió.
- Corregir el texto de `uncertain` para que no afirme «24 horas» cuando el intento es reciente.

**Aceptación:** los escenarios A, B y C del probe, convertidos en prueba, terminan `uncertain` con 0 llamadas al proveedor. Una fila sin intento termina `skipped`.

## C1RR-2 — Zona horaria inconsistente para «año de la solicitud terminado»

**Hoy:**
- `requestYearEnded` (`class-certificate-live-authorization.ts:238-258`) usa `America/Mexico_City`, duplicando como constante propia `ECCLESIASTICAL_YEAR_TIMEZONE` (`ecclesiastical-year.service.ts:12-18`).
- `assertYearOpen` (`investiture-authorization-requests.service.ts:1568-1576`) usa `local_fields.timezone`.
- Consecuencia: en un Campo al oeste de Ciudad de México, en las últimas horas de `end_date`, aprobar un certificado cierra como `CLOSED_YEAR` a una persona que el pastor todavía podía autorizar.

**Corrección:**
- Una sola regla decide si el año de la solicitud terminó: el día local en la zona del Campo de la solicitud, con el respaldo que ya usa `assertYearOpen`.
- Reutilizar el mismo helper de `assertYearOpen`, no una copia.
- Que nunca se cierre algo que todavía es autorizable, y que nunca se autorice algo que la aprobación ya considera vencido.

**Aceptación:**
- Pruebas con `active=true` y el día local en el borde de `end_date` para un Campo al oeste (por ejemplo `America/Tijuana`) y uno al este (por ejemplo `America/Bogota`). La aprobación del certificado y la autorización del pastor tienen que coincidir siempre en «abierto» o «terminado».
- Hoy ninguna prueba ejercita esa rama por día: agregala en unidad y en PostgreSQL.

## C1RR-3 — Verificación de log del servidor con respaldo fijo

**Hoy:** `openServerLog` (`test/investiture-authorization-requests-postgres.e2e-spec.ts:4574-4591`) cae a `/opt/homebrew/var/log/postgresql@18.log` si falta `SACDIA_POSTGRES_SERVER_LOG`. Contra otro servidor, la comprobación de interbloqueos pasaría sin verificar nada.

**Corrección:**
1. Quitar el respaldo fijo. Si falta `SACDIA_POSTGRES_SERVER_LOG`, las pruebas que dependen del log fallan con un mensaje claro.
2. Al inicio, demostrar que el log pertenece al servidor de la prueba: emitir un `RAISE WARNING` con un marcador único y verificar que aparece en ese archivo antes de usarlo como evidencia.

**Aceptación:** sin la variable, esas pruebas fallan con un mensaje explícito. Con un archivo de log que no es el del servidor, falla la verificación del marcador. Con el log correcto, pasan.

## Fuera de esta entrega

Las pantallas, la fase 2, la fase 8 y la decisión de producto sobre los certificados del mismo año de una solicitud vencida.

## Entrega esperada

Agregá a `docs/reviews/investidura-autorizacion-implementation-report.md` una sección «C1RR-1 a C1RR-3» con:

1. Por hallazgo: archivo y línea, salida roja, salida verde y decisión.
2. Los conteos: unitarias completas (con el comando exacto), las tres suites de PostgreSQL con el puerto y el log usados, `tsc` y ESLint.
3. Los límites de la evidencia y la confirmación de que los cierres previos siguen pasando.

No des nada por cerrado: queda pendiente de revisión independiente.
