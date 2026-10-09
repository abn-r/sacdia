# Prompt — C1RR-1 a C1RR-3 (pendientes) + IA61-H1 a IA61-H5

## Contexto

Trabajás en `/Users/abner/Documents/development/sacdia`, rama `development` de `sacdia-backend`, sobre `113d8ba` más los cambios sin commit. La revisión independiente 30 (2026-10-07, en `docs/reviews/investidura-autorizacion-independent-review.md`) dejó:

- IA-61 cerrable con observaciones e IA-62 cerrado con observación.
- **C1RR-1 y C1RR-3 sin aplicar**; el informe no tiene sección C1RR.
- C1RR-2 parcial.
- Hallazgos nuevos: IA61-H1 a IA61-H5.

Leé:

- las secciones de las revisiones 29 y 30;
- `docs/reviews/investidura-autorizacion-prompt-c1rr.md`, que sigue vigente;
- los probes `docs/reviews/investidura-autorizacion-review-evidence/c1rr-bulk-skip-attempt-probe.cjs`, `ia61-scope-and-boundary-probe.cjs` e `ia61-log-min-messages-deadlock-probe.sh`, con sus `.log`.

## Restricciones

- No desplegar, no commitear, no aplicar migraciones en Neon ni tocar producción. No ejecutar builds.
- No modificar el informe independiente ni los probes existentes.
- No reabrir cierres previos: P3-1, P4 a P7, W1, X-1 a X-4, R26, C1-H1 a C1-H5, C1R-N1 a C1R-N5, ni lo cerrado de IA-61 e IA-62.
- **TDD:** registrá la prueba roja antes de cada corrección.
- **Unitarias completas** con `node node_modules/jest/bin/jest.js --no-coverage --forceExit`: 0 fallos.
- **ESLint** `--no-fix` sobre los archivos TS de `git status`.
- **PostgreSQL:** las tres suites en un clúster descartable propio, configurado así (sin esto, la evidencia de interbloqueos no vale):
  - `initdb` + `pg_ctl -l <log>`, con un puerto distinto de 5432 y la base terminada en `_test`;
  - **`log_min_messages = warning`** (o más bajo). Con `log`, los ERROR no se escriben en el log;
  - `SACDIA_POSTGRES_SERVER_LOG=<log>`;
  - no uses el servicio de Homebrew.

## Parte 1 — C1RR (pendiente)

### C1RR-1 — El cron marca `skipped` filas con intento ante el proveedor

`skipOpenInvestitureMail` (`investiture-communications.service.ts:562-573`, llamado en `:264`) todavía no filtra las filas que ya tuvieron un intento ante el proveedor. Aplicá **íntegro** el C1RR-1 de `docs/reviews/investidura-autorizacion-prompt-c1rr.md`:

- una fila con intento ante el proveedor pasa a `uncertain` y no se reenvía;
- `skipped` queda solo para las filas que nunca llegaron al proveedor;
- el texto de `uncertain` no debe mencionar «24 horas» cuando el intento es reciente.

**Aceptación:** los escenarios A, B y C del probe, como prueba.

### C1RR-2 — Completar la regla única de «año terminado»

Hoy las dos rutas coinciden en el borde (lo confirma el probe), pero:

- la comparación está duplicada en `class-certificate-live-authorization.ts:268-273` y en `investiture-authorization-requests.service.ts:1607`;
- queda el literal `'America/Mexico_City'` en `service.ts:1520`;
- no hay pruebas con `active=true` en el borde.

**Corrección:** un solo helper que decida si el año de una solicitud terminó, usado por `assertYearOpen` y por `requestYearEnded`, y el respaldo de zona desde una sola constante.

**Aceptación:** pruebas de borde de `end_date` con `active=true` para `America/Tijuana` y `America/Bogota`, en unidad y en PostgreSQL. La aprobación del certificado y la autorización del pastor tienen que coincidir siempre.

### C1RR-3 — Verificación del log del servidor

`test/investiture-authorization-requests-postgres.e2e-spec.ts:4748-4749` todavía tiene el respaldo a `/opt/homebrew/var/log/postgresql@18.log`.

**Corrección:**

1. Quitá el respaldo. Sin `SACDIA_POSTGRES_SERVER_LOG`, las pruebas que dependen del log fallan con un mensaje claro.
2. Al inicio, emití un **`RAISE WARNING`** con un marcador único y verificá que aparece en ese archivo. **No uses `RAISE LOG`.** Así se detecta tanto un archivo equivocado como un `log_min_messages` que no registra ERROR.

**Aceptación:**

- Sin la variable, la prueba falla con un mensaje claro.
- Con un archivo ajeno, falla la verificación del marcador.
- Con `log_min_messages = log` en el servidor, también falla la verificación.
- Con la configuración correcta, pasa.

## Parte 2 — IA61-H1 a IA61-H5

### IA61-H1 (Media, evidencia) — El log de la entrega anterior no registraba ERROR

Rehacé la evidencia de interbloqueos de IA-61, C1R-N1 y C-1 con el clúster configurado como dicen las restricciones. En el informe incluí:

- el valor de `log_min_messages` (sacalo con `SHOW log_min_messages`);
- la cantidad de líneas ERROR provocadas que aparecen en el log, como control de que el log registra errores;
- la cantidad de `deadlock detected`, que debe ser 0.

### IA61-H2 (Baja) — Compuerta permisiva sin Campo

La compuerta de IA-61 deja pasar a un `director-lf` o `assistant-lf` sin `local_field_id`, y a un actor sin roles.

**Corrección:** que la compuerta rechace esos casos por sí misma, aunque por HTTP hoy no se alcancen.

### IA61-H3 (Baja) — Lote con un Campo distinto al de la solicitud

Solo documentarlo en `docs/features/validacion-investiduras.md`: si la persona cambió de Campo, la acreditación de IA-61 queda para un admin global o `super-admin`. No cambies el comportamiento.

### IA61-H4 (Baja) — Un PENDING previo de GM-02/GM-03 no se puede resolver

Hoy el chequeo de `:709` hace fallar toda la resolución.

**Corrección:** al resolver, retirá a esa persona como `REMOVED` con un `resolution_code` explícito, por ejemplo `CLASS_NOT_ELIGIBLE`, sin `INVESTIDO`, sin evento y sin texto de falta de requisitos. El resto de la resolución se confirma, igual que en H2 de X-1. Además, excluí esos registros de los recordatorios.

**Aceptación:** una resolución con una persona GM-02 `PENDING` y otra elegible: la primera queda `REMOVED/CLASS_NOT_ELIGIBLE` y la segunda se resuelve.

### IA61-H5 (Baja) — Error sin código ni i18n

`CERTIFICATE_IMPORT_ENDED_YEAR_FIELD_FORBIDDEN` es un `ForbiddenException` en texto plano.

**Corrección:** darle un `ErrorCode` con i18n es/en/fr/pt-BR, manteniendo HTTP 403, y sincronizar `docs/api/`. Agregá pruebas unitarias para `admin` con otro Campo y para `assistant-lf` con otro Campo.

## Fuera de esta entrega

Las pantallas, la fase 2 y la fase 8.

## Entrega esperada

Agregá a `docs/reviews/investidura-autorizacion-implementation-report.md` dos secciones: «C1RR-1 a C1RR-3» e «IA61-H1 a IA61-H5». Cada una con:

1. Por hallazgo: archivo y línea, salida roja, salida verde y la decisión tomada.
2. Las unitarias completas, con el comando exacto.
3. Las tres suites de PostgreSQL, con el puerto, la ruta del log, el valor de `log_min_messages`, las líneas ERROR de control y las de `deadlock detected`.
4. `tsc` y ESLint.
5. Los contratos actualizados en `docs/api/` y en `docs/features/validacion-investiduras.md`.
6. Los límites de la evidencia y la confirmación de que los cierres previos siguen pasando.

Si alguna parte queda sin aplicar, decilo explícitamente en el informe. No la omitas.

No des nada por cerrado: queda pendiente de revisión independiente.
