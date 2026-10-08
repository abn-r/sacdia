# Prompt — corrección X-1 a X-4 (investidura por autorización)

> Copiar desde «Contexto» hasta el final y entregarlo al agente implementador.

## Contexto

Trabajás en `/Users/abner/Documents/development/sacdia`, rama `development` de `sacdia-backend`, sobre `113d8ba` más los cambios sin commit de las fases 0B–7. Spec: `docs/plans/2026-09-28-investidura-autorizacion.md`. Informe de implementación: `docs/reviews/investidura-autorizacion-implementation-report.md`. Revisión independiente: `docs/reviews/investidura-autorizacion-independent-review.md`.

Una revisión transversal del plan contra el código (2026-10-07) encontró cuatro hallazgos de prioridad alta que las revisiones por fase no cubrían. Se corrigen **antes** de cualquier pantalla y antes de ejecutar la fase 8. Los cierres previos (P3-1, P4-1..P4-4, P5-1..P5-3, P6-1..P6-5, P7-1..P7-3, W1) no se reabren: si una corrección los toca, sus pruebas deben seguir pasando.

## Restricciones

- No desplegar, no commitear, no aplicar migraciones en Neon ni tocar producción.
- No ejecutar builds. Sí: Jest focal, `tsc --noEmit -p tsconfig.build.json`, ESLint de los archivos tocados y PostgreSQL aislado de loopback (base terminada en `_test`).
- No apagar todavía la vía vieja ni quitar pantallas: eso es la fase 8. Aquí solo se impide que las dos vías se pisen.
- No modificar el informe independiente ni los probes de `docs/reviews/investidura-autorizacion-review-evidence/`.
- TDD: primero la prueba roja que reproduce cada hallazgo, después la corrección.

## X-1 (Alta) — Las dos vías actúan sobre el mismo enrollment

**Hoy:**
- `acceptEnrollment` en `src/investiture-requests/investiture-authorization-requests.service.ts` (~L1133-1215) no revisa `locked_for_validation` ni los estados del pipeline viejo (`SUBMITTED_FOR_VALIDATION`, `CLUB_APPROVED`, `COORDINATOR_APPROVED`, `FIELD_APPROVED`).
- `src/investiture/investiture.service.ts` (submit, club-approve, coordinator-approve, field-approve, invest, reject, bulk-approve, bulk-reject y los alias `submit-for-validation`, `validate`, `investiture`) y `src/validation/validation.service.ts` (`submit` con `entity_type` class, `class/:id/review`) no consultan `investiture_authorization_people`.
- La resolución hace `tx.enrollments.update` a `INVESTIDO` (~L782) sin condicionar el estado previo del enrollment.

**Escenario:** Ana está `PENDING` en una solicitud nueva. Por la vía vieja se envía y se le hace `invest`: queda `INVESTIDO` sin el pastor, el registro nuevo sigue `PENDING` y entra a recordatorios. A la inversa, un expediente viejo en `FIELD_APPROVED` se presenta por la vía nueva. Si ambas confirman a la vez, `class.completed` puede salir dos veces.

**Corrección requerida:**
1. La vía nueva rechaza al presentar y al agregar un enrollment con `locked_for_validation = true` o con estado del pipeline viejo, con un código nuevo (p. ej. `INVESTITURE_REQUEST_LEGACY_PIPELINE_ACTIVE`, con i18n en es/en/fr/pt-BR). La resolución vuelve a comprobarlo dentro de la transacción. Si ocurre, esa persona no queda `INVESTIDO` y no se emite evento. Definí y documentá cómo queda el registro (por ejemplo `REMOVED` con `resolution_code`) sin usar el texto de falta de requisitos.
2. Toda ruta vieja que cambie `investiture_status`, `locked_for_validation` o el progreso de clase de un enrollment rechaza la operación si existe un registro `PENDING` de ese enrollment en `investiture_authorization_people`. Incluye las operaciones masivas: rechazar solo los ítems afectados o todo el lote, documentado.
3. Ambas comprobaciones corren bajo el mismo candado por enrollment que ya usa el flujo nuevo (`investiture-request-lock.ts`), para que no exista una carrera entre comprobar y escribir.
4. La escritura a `INVESTIDO` en la resolución se condiciona al estado previo esperado (`updateMany` con condición y verificación de `count`). Si no coincide, la persona no se inviste y la transacción no deja efectos parciales.
5. No se cambia la validación de honores: `/validation` para `entity_type` distinto de class sigue igual.

**Aceptación:** pruebas de unidad para cada ruta vieja y para presentar/agregar/resolver. En PostgreSQL aislado, ambos órdenes de la carrera `invest` (vía vieja) contra `resolutions` (vía nueva) sobre el mismo enrollment terminan con exactamente un `INVESTIDO`, un solo `class.completed` y ningún `PENDING` huérfano.

## X-2 (Alta) — IA-06 solo mira el mismo enrollment

**Hoy:** `acceptEnrollment` (~L1164) y la resolución (~L680) comprueban `enrollment.investiture_status === 'INVESTIDO'` del enrollment de la solicitud. No buscan otro `INVESTIDO` de la misma persona y clase (por ejemplo, un `HISTORICAL_CERTIFICATE`).

**Escenario:** Ana tiene un certificado histórico de Amigo `INVESTIDO` y una inscripción operativa de Amigo. La operativa entra a la solicitud y se autoriza: quedan dos `INVESTIDO` de Amigo.

**Corrección requerida:** al presentar, agregar y resolver, comprobar si existe cualquier enrollment `INVESTIDO` de esa persona y clase, de cualquier `record_kind`. Al presentar o agregar se rechaza con `INVESTITURE_REQUEST_ALREADY_INVESTED`. Al resolver se aplica el tratamiento existente de IA-06: `REMOVED` con `ALREADY_INVESTED`, sin evento ni texto de falta de requisitos. Antes de corregir, verificá y documentá si `enrollUser` o `validateDisplayOrderProgression` ya impiden ese escenario en la práctica; aunque lo impidan, la comprobación por persona y clase es obligatoria según IA-06.

**Aceptación:** unidad para presentar, agregar y resolver, con el investido en otro enrollment. Las pruebas existentes de `ALREADY_INVESTED` siguen pasando.

## X-3 (Alta) — El enlace del correo apunta a una página inexistente

**Hoy:** el correo usa `{ADMIN_PANEL_URL}/investiture-requests/{requestId}`. `sacdia-admin/src/app` no tiene esa ruta y `ADMIN_PANEL_URL` es `optional()` en `src/config/env.validation.ts:94`, así que el enlace puede salir relativo.

**Corrección requerida (solo backend en esta entrega):**
1. `ADMIN_PANEL_URL` es obligatorio cuando el correo de investidura está habilitado, o el envío falla de forma explícita y observable antes de llamar al proveedor. Nunca se envía un enlace relativo. Actualizá `.env.example` y la validación.
2. Documentá en `docs/api/FRONTEND-INTEGRATION-GUIDE.md` que la pantalla del panel debe existir exactamente en `/investiture-requests/[requestId]`, como contrato para la integración del panel. No crees la pantalla en esta entrega.
3. Registrá en el informe que los correos no deben habilitarse en un entorno hasta que esa ruta exista.

**Aceptación:** prueba del render o de la validación de configuración: sin `ADMIN_PANEL_URL` no sale un enlace relativo.

## X-4 (Alta) — El inventario de la fase 8 está incompleto

**Hoy:** `docs/features/validacion-investiduras.md`, sección «Preparación de fase 8», omite tres cosas:
- **`ValidationModule` con `entity_type` class.** `POST /validation/submit` lleva el enrollment a `SUBMITTED_FOR_VALIDATION` con bloqueo. `POST /validation/class/:id/review` lo lleva a `APPROVED` con bloqueo, o lo devuelve a `IN_PROGRESS` liberándolo, y actúa también sobre expedientes enviados por la vía vieja. `APPROVED` cuenta como completado en `class-investiture-progress-score.ts:34`, `clubs.service.ts:1464`, `class-counselor-assignments.service.ts:38` y `validation.service.ts:413`.
- **La reconciliación de certificados.** `certificate-bulk-imports-application.service.ts`, `reconcileOperationalEnrollment` (~L531) y `substituteGuideMajor` (~L468), lleva un enrollment operativo a `INVESTIDO` o a `HISTORICAL_CERTIFICATE` sin mirar solicitudes `PENDING`. Su corrección se hará en la próxima entrega; aquí solo se inventaría.
- **La pantalla del admin `/dashboard/clubs/validations`**, panel «class» (`clubs-validations-client.tsx:123`, `reviewValidation`).

**Corrección requerida:**
1. Completar el inventario con ruta, archivo y línea, qué escribe y su consumidor en admin y app.
2. Agregar el tratamiento propuesto para el expediente viejo con `locked_for_validation = true` después del apagado. Hoy, si la vía nueva lo rechaza, nada libera ese bloqueo y queda trabado hasta fin de año. Con X-1, la vía nueva ya no lo acepta: documentá cómo sale de ese estado. Es una propuesta pendiente de aprobación, no una decisión tomada.
3. Solo documentación. No apagar nada.

## Entrega esperada

Actualizá `docs/reviews/investidura-autorizacion-implementation-report.md` con una sección «X-1 a X-4» que incluya:

1. Por hallazgo: qué cambió, en qué archivo y línea, el rojo observado antes de la corrección y el verde después.
2. Una tabla de pruebas: suite, cantidad y salida (unidad, PostgreSQL aislado, `tsc`, ESLint de los archivos tocados).
3. Códigos de error nuevos y su contrato HTTP, sincronizados en `docs/api/ENDPOINTS-LIVE-REFERENCE.md` y `docs/api/FRONTEND-INTEGRATION-GUIDE.md`.
4. Migraciones nuevas, si las hubiera, sin aplicar en Neon.
5. Límites de la evidencia: qué no certifica (HTTP real, autenticación, UI, migraciones aplicadas).
6. La confirmación explícita de que los cierres previos siguen pasando, con las suites ejecutadas.
7. El estado vigente: fase 2 parcial, pantallas pendientes, fase 8 sin ejecutar, despliegue bloqueado, sin commit.

No des X-1 a X-4 por cerrados: quedan pendientes de revisión independiente.
