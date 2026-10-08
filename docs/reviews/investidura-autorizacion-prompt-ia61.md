# Prompt — IA-61 e IA-62: certificado de un año vencido y clases de legado

## Contexto

Trabajás en `/Users/abner/Documents/development/sacdia`, rama `development` de `sacdia-backend`, sobre `113d8ba` más los cambios sin commit. Esta entrega va **después** de C1RR-1 a C1RR-3 (`docs/reviews/investidura-autorizacion-prompt-c1rr.md`). Las reglas nuevas, **IA-61 e IA-62**, se aprobaron el 2026-10-07 y están en `docs/plans/2026-09-28-investidura-autorizacion.md` §3.9; leelas junto con IA-57 a IA-60. Contexto: la observación de C1R-N2 en la revisión 29 de `docs/reviews/investidura-autorizacion-independent-review.md`.

## IA-61 — Certificado de un año cuya solicitud venció sin autorizar

Una persona tuvo una solicitud de investidura de una clase que terminó sin autorización porque su año eclesiástico ya terminó. Eso incluye el registro `CLOSED_YEAR` y también un `PENDING` de un año terminado que el barrido todavía no cerró. Para un certificado de **ese mismo año**, de esa persona y clase:

- **Puede acreditarse.** Lo aprueba cualquiera de los roles que ya aprueban certificados, cada uno dentro de su alcance:
  - `director-lf` o `assistant-lf` del Campo de esa solicitud;
  - `admin`, `assistant-admin` o `super-admin`.

  Basta uno. Un `director-lf` o `assistant-lf` de **otro** Campo no lo aprueba. Verificá si la aprobación actual ya limita a los roles de Campo a su propio Campo. Si no lo hace, aplicá esa limitación al menos en este caso y documentá el resultado.
- **La solicitud conserva `CLOSED_YEAR` como auditoría:** no se reabre ni se reescribe. Si estaba `PENDING` de un año terminado, primero se cierra como `CLOSED_YEAR` con la regla única de C1RR-2, en la misma transacción.
- **Las lecturas lo indican:** la de la solicitud (directiva de la sección y autorizador) y el historial de la persona muestran que la investidura de ese año se acreditó después por certificado. Proponé y documentá el texto; por ejemplo, «Investidura acreditada posteriormente mediante certificado validado».
- **`class.completed` y los logros** siguen las reglas existentes de acreditación por certificado. No se emiten desde la solicitud ni se duplican.
- **Las demás reglas no cambian:** mientras el año de la solicitud sigue en curso rige IA-57 (el certificado se rechaza). IA-58 e IA-59 quedan igual.

## IA-62 — Clases institucionales de legado sin solicitudes

`GM-02` y `GM-03` (`INSTITUTIONAL_CLASS_ASSET_CODES`) son clases de legado, solo de reconocimiento. **No admiten solicitudes de investidura.** Su acreditación sigue por la vía institucional de certificados (`admin-institutional-certificate-requests.controller.ts:29`, `super-admin`), sin cambios.

- Verificá si hoy presentar o agregar una de esas clases es posible. Si lo es, rechazalo con un código explícito, por ejemplo `INVESTITURE_REQUEST_CLASS_NOT_ELIGIBLE`, con i18n es/en/fr/pt-BR. Comprobalo también al resolver, por si existiera un registro previo.
- Usá una sola fuente para la lista de clases institucionales. Hoy está duplicada en `certificate-bulk-imports-application.service.ts:47` y en `admin-certificate-bulk-imports.service.ts:32`: consolidala o reutilizala.

## Restricciones

- No desplegar, no commitear, no aplicar migraciones en Neon ni tocar producción. No ejecutar builds.
- **PostgreSQL:** un clúster descartable propio, con `SACDIA_POSTGRES_SERVER_LOG`. No uses el servicio de Homebrew.
- No modificar el informe independiente ni los probes existentes.
- No reabrir cierres previos: P3-1, P4 a P7, W1, X-1 a X-4, R26, C1-H1 a C1-H5, C1R-N1 a C1R-N5 y C1RR.
- **TDD:** registrá la prueba roja antes de corregir.
- Unitarias completas con `node node_modules/jest/bin/jest.js --no-coverage --forceExit`, con 0 fallos. Las tres suites de PostgreSQL en verde. ESLint `--no-fix` sobre los archivos TS de `git status`.
- El alcance de Campo se resuelve igual que en el resto del flujo: sección → club → Campo de la solicitud.

## Aceptación

**IA-61, unidad:**
- `CLOSED_YEAR` más un certificado del mismo año: acreditado por `director-lf`, por `assistant-lf`, por `admin`, por `assistant-admin` y por `super-admin`. La solicitud sigue `CLOSED_YEAR` y muestra la nota.
- Aprobado por un `director-lf` de otro Campo: rechazado, sin efectos.
- `PENDING` de un año terminado más un certificado de ese año: se cierra `CLOSED_YEAR` y se acredita, en una sola transacción.
- Año en curso: IA-57 sin cambios.

**IA-61, PostgreSQL aislado:** la aprobación contra el barrido de `year-cut` del mismo año, en ambos órdenes. Sin `deadlock detected` en el log, con un solo `INVESTIDO` y la solicitud en `CLOSED_YEAR`.

**IA-62:** presentar y agregar `GM-02` o `GM-03` se rechaza sin efectos. La vía institucional de certificados sigue funcionando.

## Entrega esperada

Agregá a `docs/reviews/investidura-autorizacion-implementation-report.md` una sección «IA-61 e IA-62» con:

1. Archivo y línea, salida roja, salida verde y las decisiones: el texto informativo, los códigos de error y el resultado de la verificación del alcance de Campo.
2. El resultado de la verificación de IA-62: si hoy era posible presentar `GM-02` o `GM-03`.
3. Los conteos de las unitarias completas (con el comando exacto), de las tres suites de PostgreSQL (con el puerto y el log), de `tsc` y de ESLint.
4. El contrato actualizado en `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, `docs/api/FRONTEND-INTEGRATION-GUIDE.md` y `docs/features/validacion-investiduras.md`.
5. Los límites de la evidencia y la confirmación de que los cierres previos siguen pasando.

No des IA-61 ni IA-62 por cerrados: quedan pendientes de revisión independiente.
