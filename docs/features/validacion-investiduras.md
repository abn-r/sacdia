# Validacion de Investiduras

**Estado**: la vía club → coordinación → campo (envío, aprobaciones de club, coordinación y Campo, `invest`, operaciones en bloque, aliases de `enrollments` y `ValidationModule` para clases) está **apagada en el código** de la fase 8: sus rutas responden HTTP 410 `INVESTITURE_LEGACY_PIPELINE_RETIRED` y el panel y la app borraron sus pantallas. **Nada está desplegado ni mergeado**, las migraciones no están aplicadas en Neon y el desbloqueo no se ejecutó en ningún entorno. Lo que queda de esa vía: lectura del historial, `expire-overdue` y el desbloqueo de bloqueos.

> [!WARNING]
> **Pendiente de merge (PR #448 de sacdia-backend).** La ventana del Campo, el cupo y la asignación de pastores, `investiture-authorizers` y las solicitudes `investiture-requests` descritas en esta nota están en la rama `feat/investiture-authorization-ocr`, no en `development`.

> **Fase 8 implementada en código, sin desplegar (2026-10-09).** Ramas: backend `feat/investiture-legacy-shutdown` (sobre `f52e684`, PR #466), panel `feat/investiture-legacy-screens-removal` y app `feat/investiture-legacy-app-removal`. Los PRs están pendientes. Migraciones sin aplicar en Neon: `20261008120000_district_pastor_field_change` y `20261009120000_investiture_legacy_lock_release_action`, además de las anteriores de investidura. El desbloqueo de la sección «Fase 8 — apagado» no se corrió en ningún entorno.

> El acuerdo vigente es la autorización por solicitud, en `docs/plans/2026-09-28-investidura-autorizacion.md`. Las secciones que describen el flujo multietapa (descripción de dominio, requisitos funcionales y decisiones de diseño) documentan la vía anterior tal como era antes del apagado. El documento de ceremonia colectiva del 2026-09-21 quedó reemplazado. La ventana del Campo (`GET` y `PATCH /api/v1/local-fields/:localFieldId/investiture-windows/:ecclesiasticalYearId`) ya se puede leer y guardar. Sin fila, si octubre–diciembre intersecta el año, la respuesta trae ese recorte, `configured: false` y `operational: true`. Si no hay intersección y no hay una configuración válida dentro del año, `start_date` y `end_date` son `null`, `configured` es false y `operational` es false: no se abre el año completo y la lectura no inserta una fila. `operational` indica que existe un rango, no que el día local esté dentro. El cupo de pastores del distrito y su asignación (`/api/v1/investiture-pastor-quota`, `/api/v1/districts/:districtId/investiture-pastors`, `/api/v1/clubs/:clubId/investiture-authorizers`) ya se pueden leer y guardar. El cambio de cupo y las altas o reactivaciones se coordinan en la misma transacción, también si todavía no hay fila de cupo. El distrito de esa lectura sale de la iglesia del club. Esa configuración y esa asignación nunca pasaron por las rutas `submit`, `club-approve`, `coordinator-approve`, `field-approve` ni `invest`, que hoy responden 410. La solicitud nueva (`POST /api/v1/club-sections/:sectionId/investiture-requests` y las rutas de personas, lectura y fecha) marca, quita y corrige la fecha dentro de la sección. Una clase de varios años conserva el enrollment de inicio. Una clase cruzada de Guía Mayor se presenta en la sección de esa clase, del mismo club. Mientras hay un pendiente, el progreso de ese enrollment no se escribe. Agregar a una solicitud anterior, cuando ya hay otra con pendientes, se rechaza y hay que volver a cargar el listado. La autorización (`GET /api/v1/investiture-requests` y `POST /api/v1/investiture-requests/:requestId/resolutions`) la hace el pastor del distrito de la iglesia o el Campo de esa solicitud. Vuelve a comprobar año, ventana y pastor dentro de la transacción, con el instante leído después de los candados. Pasa el enrollment a `INVESTIDO` sin el pipeline de abajo y deja una intención de `class.completed`. Esa intención se entrega una sola vez aunque después cierren el año o la ventana; esa entrega no vuelve a autorizar. El identificador de la cola no es la clave guardada. Si ese trabajo queda en `failed`, se reintenta el mismo id sin abrir otra fila. Después de confirmar la presentación, la intención del correo queda en esa transacción con una identidad propia de esa operación, y el envío se materializa después. Recuperar no cambia esa identidad ni reenvía a quien ya fue atendido. Encolar no es entregar. Si el acuse del proveedor se pierde y el envío sigue permitido, el reintento conserva el mismo contenido durante 24 horas y después queda incierto, sin reenviar solo. Antes de esa llamada se vuelven a comprobar destinatario, año y pendientes. Si ya no corresponde, o si solo queda autorizada una parte del contenido congelado, no se envía y no se cambia el cuerpo ni la clave. Ese cuerpo, su destino y su alcance salen de la misma instantánea con la que se armó el correo. La resolución confirmada avisa en la bandeja de la app con una clave única, sin el motivo humano. El recordatorio sale por correo a las 10:00 locales, se vuelve a comprobar al entregar y no abre una bandeja nueva en el panel. El cierre administrativo del año y el corte automático dejan cada pendiente de ese año en `CLOSED_YEAR`, sin el texto de falta de requisitos y sin copiar la solicitud al año siguiente. Repetirlos no cambia a quien ya estaba investido. El historial (`GET /api/v1/investiture-history` y `GET /api/v1/club-sections/:sectionId/investiture-history`) conserva clase y año. El anuario (`GET /api/v1/club-sections/:sectionId/investiture-yearbook`) lista la inscripción operativa en la sección de su tipo de clase, dentro del mismo club, para el director, el secretario o el secretario-tesorero. Una clase de Conquistadores de quien tiene membresía en Guías Mayores no aparece en el anuario de Guías Mayores. No inscribe solo ni cierra unidades o finanzas. El panel y la app todavía no tienen las pantallas de presentar y autorizar en `development`; están en los planes `docs/plans/2026-10-08-investidura-ui-1-panel.md` y `docs/plans/2026-10-08-investidura-ui-2-app.md`.

## Descripcion de dominio

La validacion de investiduras es el proceso institucional mediante el cual el avance formativo de un miembro recibe reconocimiento formal. Es el cierre del ciclo formativo: un miembro completa su clase progresiva durante el ano eclesiastico, su progreso es validado por las autoridades del club y del campo local, y finalmente es investido en una ceremonia oficial.

El proceso tiene multiples etapas definidas por el canon: (1) el miembro completa los requisitos de su clase dentro de la duracion configurada, (2) el consejero o director envia el registro a validacion, (3) el registro queda bloqueado y pasa a revision institucional, (4) la autoridad competente aprueba o rechaza, (5) si es aprobado, se programa la investidura, (6) el miembro es investido formalmente. Este flujo es central para la identidad del sistema — sin validacion de investiduras, SACDIA puede registrar avance pero no puede reconocerlo institucionalmente.

La Decision 6 del canon establece que registrar y validar son actos distintos: la captura operativa (registrar progreso dia a dia) y la validacion institucional (aprobar y reconocer formalmente) tienen actores, momentos y reglas diferentes. Al entrar en validacion, el registro deja de ser editable — esto es un efecto de dominio critico que protege la integridad del proceso.

El schema conserva las tablas y los enums del flujo multietapa (`investiture_validation_history`, `investiture_config`, los campos de investidura de `enrollments`). Desde la fase 8 el backend ya no lo expone: las rutas de envío, aprobación, investidura, rechazo, bloque, aliases y configuración responden 410, y el panel y la app borraron sus pantallas. Quedan la lectura del historial, `expire-overdue` y el desbloqueo de `locked_for_validation`.

Los requisitos `BASIC` y `EXTRA` cuentan para investidura; `ADVANCED` activa el estado/badge avanzado de la clase por separado y no entra como requisito obligatorio del flujo.

## Que existe (verificado contra codigo)

Verificado contra las ramas de la fase 8 (backend `feat/investiture-legacy-shutdown`, panel `feat/investiture-legacy-screens-removal`, app `feat/investiture-legacy-app-removal`). No está desplegado.

### Backend (InvestitureModule)
- `InvestitureController`: `POST /admin/classes/enrollments/expire-overdue`, `POST /admin/investiture/legacy-locks/release`, `GET /investiture/enrollments/:enrollmentId/history` y su alias `GET /enrollments/:enrollmentId/investiture-history`.
- `LegacyInvestitureRetiredController`: las 17 rutas retiradas, todas 410 `INVESTITURE_LEGACY_PIPELINE_RETIRED`, sin cuerpo ni pipes, con `@SkipPermissions` (solo el JWT global). Ver «Fase 8 — apagado».
- `LegacyLockReleaseService` (con `ExactSuperAdminWritePolicy`): el desbloqueo.
- `InvestitureService` conserva solo `getHistory` y `expireOverdueEnrollments`. Se borró el código muerto de la cadena y de la configuración.
- Campos de `enrollments` que la vía anterior escribía y hoy solo se leen o se conservan:
  - `investiture_status` (investiture_status_enum)
  - `submitted_for_validation` (Boolean, default false)
  - `submitted_at` (DateTime?)
  - `validated_by` (UUID?)
  - `validated_at` (DateTime?)
  - `rejection_reason` (String?)
  - `investiture_date` (DateTime?)
  - `locked_for_validation` (Boolean, default false)

### Admin (sacdia-admin)
- Borrado en la fase 8: `/dashboard/investiture`, `/dashboard/investiture/pipeline`, `/dashboard/investiture/config`, `/dashboard/enrollments` (la cola de inscripciones pendientes de investidura que llamaba `GET /investiture/pending`) y la pestaña «Módulos» (clases) de `/dashboard/clubs/validations`, con sus entradas de sidebar, catálogo de pantallas y textos. `/dashboard/clubs/validations` conserva honores.
- La pantalla de autorización nueva está en el plan `docs/plans/2026-10-08-investidura-ui-1-panel.md`.

### App (sacdia-app)
- Borrada en la fase 8 la feature de investidura vieja: pendientes, historial, envío, rutas, capa de datos, tarjeta del hub de coordinación y entrada del push en la lista permitida. El detalle de clase ya no muestra la tarjeta de envío a validación: una clase investida muestra la insignia «Investido».
- Las pantallas de autorización nuevas están en el plan `docs/plans/2026-10-08-investidura-ui-2-app.md`.

### Base de datos (schema y runtime alineados)

**Tabla `investiture_validation_history`**:
- `history_id` (INT, PK)
- `enrollment_id` (INT, FK -> enrollments)
- `action` (investiture_action_enum)
- `performed_by` (UUID, FK -> users)
- `comments` (String?)
- `created_at` (DateTime)
- Indice: idx_investiture_history_enrollment

**Tabla `investiture_config`**:
- `config_id` (INT, PK)
- `local_field_id` (INT, FK -> local_fields)
- `ecclesiastical_year_id` (INT, FK -> ecclesiastical_years)
- `submission_deadline` (Date) — fecha limite de envio a validacion
- `investiture_date` (Date) — fecha de ceremonia de investidura
- `active` (Boolean)
- UNIQUE: (local_field_id, ecclesiastical_year_id)

**Enum `investiture_status_enum`**:
- IN_PROGRESS, SUBMITTED_FOR_VALIDATION, CLUB_APPROVED, COORDINATOR_APPROVED, FIELD_APPROVED, APPROVED, REJECTED, INVESTIDO, EXPIRED

**Enum `investiture_action_enum`**:
- SUBMITTED, CLUB_APPROVED, COORDINATOR_APPROVED, FIELD_APPROVED, APPROVED, REJECTED, REINVESTITURE_REQUESTED, INVESTIDO, EXPIRED, LEGACY_LOCK_RELEASED
- `LEGACY_LOCK_RELEASED` es de la fase 8 (migración `20261009120000_investiture_legacy_lock_release_action`, sin aplicar en Neon). Solo la escribe el desbloqueo y no cambia `investiture_status`.

**Enum `evidence_validation_enum`**:
- PENDING, VALIDATED, REJECTED

## Requisitos funcionales

> Los requisitos 1 a 11 describen la vía anterior y ya no se cumplen por HTTP desde la fase 8 (sus rutas responden 410). Los 12 a 15 siguen vigentes (duración, vencimiento manual y requisitos que cuentan).

1. Un consejero o director debe poder enviar un enrollment a validacion (cambiar status a SUBMITTED_FOR_VALIDATION)
2. Al enviar a validacion, el enrollment debe bloquearse (locked_for_validation = true) y dejar de ser editable
3. Las autoridades del flujo (director de seccion, coordinacion, admin/campo local) deben poder aprobar o rechazar segun la etapa correspondiente
4. Si se rechaza, se debe registrar la razon y el enrollment debe volver a estado editable
5. Si se aprueba, se debe poder programar la fecha de investidura
6. El acto de investidura debe marcar el status como INVESTIDO y registrar la fecha
7. Cada transicion de estado debe quedar registrada en investiture_validation_history con actor, accion, comentarios y timestamp
8. La configuracion de investidura (deadline de envio, fecha de ceremonia) debe ser configurable por campo local y ano eclesiastico
9. Debe existir una vista de administracion que muestre todos los enrollments pendientes de validacion para un campo local
10. El flujo debe respetar la jerarquia de autorizacion: consejero/director envia, director aprueba a nivel club, coordinacion aprueba su etapa y admin/campo local completa la autorizacion final
11. Debe soportarse reinvestidura (REINVESTITURE_REQUESTED) para casos de miembros que necesitan re-evaluacion
12. Antes de enviar a validacion, el enrollment debe cumplir la duracion minima de su clase y no haber superado la duracion maxima
13. Si el enrollment supera `classes.max_duration_years`, el backend debe moverlo a `EXPIRED`, registrar auditoria y preservar el progreso como trayectoria historica
14. El vencimiento masivo debe iniciarse como `dry_run` y solo aplicar cambios con confirmacion admin/manual
15. La validacion solo considera requisitos `BASIC` obligatorios y `EXTRA` aplicables; `ADVANCED` se refleja como avance/badge separado en la clase

## Decisiones de diseno

- **Maquina de estados en enrollments** (vía anterior, apagada por la fase 8; los estados grabados se conservan): El campo `investiture_status` define el pipeline vigente: IN_PROGRESS -> SUBMITTED_FOR_VALIDATION -> CLUB_APPROVED -> COORDINATOR_APPROVED -> FIELD_APPROVED -> INVESTIDO, con `REJECTED` como salida de correccion y `EXPIRED` como salida terminal por vencimiento de duracion maxima
- **Bloqueo en validacion**: `locked_for_validation` impide edicion de progreso mientras esta en revision — proteccion de integridad de dominio
- **Historia de validacion**: Tabla dedicada `investiture_validation_history` con audit trail completo de cada accion
- **Configuracion por campo local**: `investiture_config` permite que cada campo local defina sus propias fechas de deadline y ceremonia por ano eclesiastico
- **Separacion de registrar y validar** (Decision 6): Actores diferentes (consejero vs coordinador), momentos diferentes, reglas diferentes
- **Duracion por ano eclesiastico**: la elegibilidad se calcula desde `enrollments.ecclesiastical_year_id`; no desde fechas sueltas de progreso
- **Vencimiento auditable**: el proceso manual usa `investiture_validation_history.action = EXPIRED` para dejar rastro del cambio

## Acreditación histórica por certificado

Distinta del pipeline anual de esta página. La aprobación de certificado CLASS ya la escribe así.

El cursado anual sigue exigiendo requisitos, duración y ceremonia, y termina en `INVESTIDO` solo después de `FIELD_APPROVED`. Un comprobante histórico no recorre esas etapas: Campo Local acredita el hecho ya ocurrido como `INVESTIDO`, con la fecha del certificado y la fecha de validación por separado, si al inicio del año eclesiástico acreditado la persona ya tenía la edad mínima de esa clase. Esa edad se vuelve a leer, junto con el año, dentro de la transacción de aprobación institucional. No exige que sea la clase actual ni una edad máxima. No exige clase en curso ni secuencia curricular.

Si el año del certificado es el de la solicitud `PENDING` de esa persona y clase, y la inscripción vinculada sigue operativa, la aprobación responde `CERTIFICATE_IMPORT_AUTHORIZATION_PENDING` y no acredita. El año comparado es el de la solicitud, no el de inicio del enrollment. Si el certificado es anterior a esa solicitud y la persona sigue `PENDING`, se acredita y la misma transacción la deja `REMOVED` con `resolution_code` `HISTORICAL_CERTIFICATE_APPLIED`. El motivo visible es «Investidura aplicada por certificado de un año anterior». No emite `class.completed` desde la solicitud y no envía correo. Si el año de esa solicitud ya terminó (año inactivo, o el día local del Campo de la solicitud posterior a `end_date`) aunque el barrido de year-cut no haya corrido, la misma aprobación la deja `CLOSED_YEAR` con `resolution_code` `CLOSED_YEAR`, sin texto de falta de requisitos y sin evento. El día se lee en `local_fields.timezone` de la sección → club → Campo, con el mismo cálculo que usa la ventana al presentar; si falta la zona, `America/Mexico_City`. Un certificado de un año posterior no escribe `system_reason`. Un certificado de ese mismo año ya terminado acredita la clase, conserva `CLOSED_YEAR` y escribe `system_reason` «Investidura acreditada posteriormente mediante certificado validado». Lo aprueba uno de estos roles, dentro de su alcance: `director-lf` o `assistant-lf` del Campo de esa solicitud, o `admin`, `assistant-admin` o `super-admin`. Un rol de otro Campo responde HTTP 403 `CERTIFICATE_IMPORT_ENDED_YEAR_FIELD_FORBIDDEN` y no acredita ni cierra. La misma compuerta rechaza a `director-lf` o `assistant-lf` sin Campo y a un actor sin esos roles. Si la persona cambió de Campo, el lote puede quedar con un Campo distinto al de la solicitud: ningún rol de Campo acredita ese certificado y queda para un `admin` o `assistant-admin` global, o para `super-admin`. El control del lote sigue comparando el Campo del revisor con el Campo del lote. Mientras el año sigue en curso, el certificado del mismo año se rechaza. Si no hay `PENDING` ni ese `CLOSED_YEAR` del mismo año, el mismo año no cambia. Si el certificado se rechaza y el año cierra, el cierre deja la persona en `CLOSED_YEAR` y no inviste el enrollment. `GM-02` y `GM-03` no admiten una solicitud nueva: presentar o agregar responde `INVESTITURE_REQUEST_CLASS_NOT_ELIGIBLE` y no escribe la persona ni la inviste. Si ya había una persona `PENDING` de esas clases, resolver la retira como `REMOVED` con `resolution_code` `CLASS_NOT_ELIGIBLE`, sin `INVESTIDO`, sin evento y sin texto de falta de requisitos, y confirma el resto de la resolución. Esos registros no entran a los recordatorios. Su acreditación sigue por la solicitud institucional de certificados.

La excepción de Guía Mayor (`GM-01`) sustituye la inscripción actual de esa clase y deja una sola fila. Guía Mayor Avanzado e Instructor no entran a este pipeline ni a la acreditación ordinaria de certificados.

## Fase 8 — apagado

Fecha del inventario: 2026-10-06. Ejecución en código: 2026-10-09. **Implementada en ramas locales; no desplegada, no mergeada, migraciones sin aplicar en Neon y desbloqueo no ejecutado en ningún entorno.** Esta sección conserva el inventario original (columnas «Antes») y registra qué quedó apagado. No se consultó Neon para esta ejecución; el único conteo real es el de producción de abajo.

**Conteo real en producción (2026-10-08, aprobado por el usuario).** Lectura en una transacción `READ ONLY` sobre la rama `production` de Neon (endpoint `ep-dark-thunder-anpobd36`):

| Dato | Valor |
| --- | --- |
| Usuarios / clubes / años eclesiásticos | 0 / 0 / 0 |
| Enrollments (total) | 0 |
| Expedientes abiertos del flujo anterior (`SUBMITTED_FOR_VALIDATION`, `CLUB_APPROVED`, `COORDINATOR_APPROVED`, `FIELD_APPROVED`, `APPROVED`) | 0 |
| Enrollments con `locked_for_validation` y sin `INVESTIDO` | 0 |
| Última migración aplicada | `20260903180000_cross_type_active_enrollment_slots` |

Consecuencias:
- En producción no hay expedientes del flujo anterior que tratar: el apagado no requiere conversión ni desbloqueo de datos.
- Ninguna migración de investidura posterior al 2026-09-03 está aplicada en producción (no existen `record_kind`, `investiture_authorization_*`, `local_field_*`, `district_investiture_pastors`). El despliegue debe aplicar en orden todas las migraciones pendientes desde esa fecha, no solo las de esta entrega.
- La rama `staging` está archivada.

**Desbloqueo aprobado (2026-10-08) e implementado en código (2026-10-09), sin ejecutar.** Después del apagado, una operación explícita suelta `locked_for_validation` y deja el `investiture_status` como estaba. Con producción vacía hoy, aplica a datos que se creen antes del apagado o a otros entornos (por ejemplo `development`). Ver «Desbloqueo de la vía anterior» más abajo.

Un expediente de esta vía es un `enrollments` con `record_kind = OPERATIONAL` y un `investiture_status` de la cadena, más las filas ya grabadas en `investiture_validation_history`. El certificado histórico (`HISTORICAL_CERTIFICATE`) no es este expediente. Si hay una persona `PENDING` de esa clase, el mismo año rechaza el certificado y un año anterior retira a esa persona al acreditar. Las rutas de esta vía responden 410.

### Rutas retiradas (410) y rutas que siguen

Todas responden bajo `/api/v1`. Las 17 retiradas están en `sacdia-backend/src/investiture/legacy-investiture-retired.controller.ts` y devuelven 410 `INVESTITURE_LEGACY_PIPELINE_RETIRED` sin leer cuerpo ni parámetros, con `@SkipPermissions` (solo el JWT global): ningún actor recibe un 403 ni un 400 que oculte el 410. Las que siguen están en `investiture.controller.ts`. El `message` sale del catálogo del idioma de la petición; una app o un panel viejos, que no mandan `Accept-Language`, lo reciben en español.

| Método y ruta | Antes (inventario del 2026-10-06) | Ahora |
| --- | --- | --- |
| `POST /investiture/enrollments/:enrollmentId/submit` | `IN_PROGRESS` → `SUBMITTED_FOR_VALIDATION`. Dejaba `locked_for_validation`. | **410** |
| `POST /enrollments/:enrollmentId/submit-for-validation` | Alias de `submit`. | **410** |
| `POST /investiture/enrollments/:enrollmentId/club-approve` | `SUBMITTED_FOR_VALIDATION` → `CLUB_APPROVED`. | **410** |
| `POST /investiture/enrollments/:enrollmentId/coordinator-approve` | `CLUB_APPROVED` → `COORDINATOR_APPROVED`. | **410** |
| `POST /investiture/enrollments/:enrollmentId/field-approve` | `COORDINATOR_APPROVED` → `FIELD_APPROVED`. | **410** |
| `POST /investiture/enrollments/:enrollmentId/invest` | Solo desde `FIELD_APPROVED` → `INVESTIDO`. Copiaba la fecha de `investiture_config` y emitía `class.completed`. | **410** |
| `POST /enrollments/:enrollmentId/investiture` | Alias de `invest` (`markInvestido`). | **410** |
| `POST /investiture/enrollments/:enrollmentId/reject` | Cualquiera de los cuatro estados de la cadena → `REJECTED`; liberaba el bloqueo. | **410** |
| `POST /enrollments/:enrollmentId/validate` | Alias de aprobar o rechazar desde `SUBMITTED_FOR_VALIDATION`. | **410** |
| `POST /investiture/enrollments/bulk-approve` | `coordinator-approve`, `field-approve` o `invest` en bloque. | **410** |
| `POST /investiture/enrollments/bulk-reject` | Rechazo en bloque. | **410** |
| `GET /investiture/pending` | Lista de los cuatro estados de la cadena. | **410** (la lectura también) |
| `GET /admin/investiture/config` y `GET /admin/investiture/config/:configId` | Leían la fecha que usaba `markInvestido`. | **410** (la lectura también) |
| `POST`, `PATCH` y `DELETE /admin/investiture/config` | Creaban, editaban o dejaban inactiva esa configuración. | **410** |
| `POST /admin/classes/enrollments/expire-overdue` | `IN_PROGRESS` o `REJECTED` que superan la duración → `EXPIRED`, con historia `EXPIRED`. | Sigue. Omite al enrollment con una persona `PENDING`. |
| `GET /investiture/enrollments/:enrollmentId/history` y `GET /enrollments/:enrollmentId/investiture-history` | Leían `investiture_validation_history`. | Siguen. Pueden devolver `LEGACY_LOCK_RELEASED`. |
| `POST /admin/investiture/legacy-locks/release` | No existía. | Nuevo: el desbloqueo. |

### Pantallas borradas

| Superficie | Ruta | Estado |
| --- | --- | --- |
| Panel | `/dashboard/investiture` | Borrada. |
| Panel | `/dashboard/investiture/pipeline` | Borrada. |
| Panel | `/dashboard/investiture/config` | Borrada. |
| Panel | `/dashboard/enrollments` | Borrada. Era la cola de inscripciones pendientes de investidura (`GET /investiture/pending`). |
| Panel | `/dashboard/clubs/validations`, pestaña «Módulos» (clases) | Borrada. La pantalla conserva honores. |
| App | `/investiture/pending` | Borrada. |
| App | `/investiture/enrollment/:enrollmentId/history` | Borrada. |
| App | Detalle de clase: tarjeta de envío a validación | Borrada; una clase investida muestra la insignia «Investido». |
| App | `InvestitureSubmitView`, proveedor `markInvestido`, tarjeta del hub de coordinación, entrada del push | Borrados. |

### Desbloqueo de la vía anterior

`POST /api/v1/admin/investiture/legacy-locks/release`, `sacdia-backend/src/investiture/legacy-lock-release.service.ts`. **No se ejecutó en ningún entorno.**

- **Quién:** solo `super-admin` exacto (`ExactSuperAdminWritePolicy`, 403 `SUPER_ADMIN_WRITE_REQUIRED` para otro actor). La ruta usa `@SkipPermissions`; la comprobación está en el servicio.
- **Cuerpo:** `{ "dry_run"?: boolean }`, por defecto `true`. Con `dry_run: true` solo lista.
- **Candidatos:** `enrollments` con `locked_for_validation` true, `record_kind` `OPERATIONAL` e `investiture_status` distinto de `INVESTIDO`. Sin filtro por `active` ni por el estado de la cadena: una fila inactiva o `REJECTED`/`EXPIRED` que conserve el bloqueo también se suelta.
- **Omisión:** un enrollment con una persona `PENDING` en `investiture_authorization_people` no se toca y va a `skipped_pending`.
- **Escritura** (`dry_run: false`): una transacción por enrollment, bajo el candado `investiture-authorization-enrollment:`. Pone `locked_for_validation` en false y deja una fila `LEGACY_LOCK_RELEASED` en `investiture_validation_history`, con el `super-admin` como `performed_by`. El `investiture_status` no cambia. Idempotente.
- **Respuesta:** `{ "status": "success", "data": { "dry_run", "candidates": [], "skipped_pending": [], "released": [] } }`.
- **Cómo correrlo, por entorno y solo con aprobación del usuario en cada uno:** (1) confirmar que la migración `20261009120000_investiture_legacy_lock_release_action` ya está aplicada en ese entorno; (2) correr `dry_run` y revisar `candidates` y `skipped_pending`; (3) solo entonces `dry_run: false`. Sin la migración, el `INSERT` del historial falla por el valor de enum.
- **Después:** un expediente liberado se puede presentar por la solicitud nueva aunque su estado sea `CLUB_APPROVED` o similar (decisión B5, abajo). Uno que no se libera sigue bloqueado y la solicitud nueva responde `INVESTITURE_REQUEST_LEGACY_PIPELINE_ACTIVE`.

### Decisión B5 (2026-10-08): X-1 mira solo `locked_for_validation`

`enrollmentOnLegacyInvestiturePipeline` (`sacdia-backend/src/investiture-requests/investiture-request-lock.ts`) ya no mira el estado de la cadena: devuelve true solo si `locked_for_validation` es true. Presentar y agregar rechazan con `INVESTITURE_REQUEST_LEGACY_PIPELINE_ACTIVE` únicamente con el bloqueo. Al resolver, un enrollment bloqueado que no está en `FIELD_APPROVED` deja a la persona `REMOVED` con `LEGACY_PIPELINE_ACTIVE`; un `FIELD_APPROVED` con la persona `PENDING` lo escribe la resolución, aunque el bloqueo siga activo. Una fila sin bloqueo en `CLUB_APPROVED` ya no se bloquea sola.

### Expedientes y tratamiento

El apagado conserva el estado grabado de cada expediente. Lo único que se puede cambiar después es `locked_for_validation`, con el desbloqueo.

| Estado o registro | Papel | Tratamiento tras el apagado |
| --- | --- | --- |
| `IN_PROGRESS` | Todavía no entra a la cadena. | No se convierte ni se envía solo. Sigue en el enrollment. |
| `SUBMITTED_FOR_VALIDATION`, `CLUB_APPROVED`, `COORDINATOR_APPROVED`, `FIELD_APPROVED` | Expediente abierto del mismo año. `locked_for_validation` está en true. | No se resuelve en silencio, no se arrastra al año siguiente y no se copia a `investiture_authorization_requests`. Siguen bloqueados hasta que un `super-admin` corra el desbloqueo en ese entorno; la solicitud nueva responde `LEGACY_PIPELINE_ACTIVE` mientras el bloqueo esté en true. Ya liberados, se presentan por la solicitud nueva. |
| `REJECTED` | Salió de la cadena para corrección. El bloqueo de esa validación ya está en false. | No se reinicia en masa. Si por algún motivo conserva el bloqueo, el desbloqueo lo suelta. |
| `INVESTIDO` | Terminal de esta vía. | Se conserva. No se reescribe. |
| `EXPIRED` | Terminal por duración. | Se conserva. No se reabre. |
| `APPROVED` | Lo escribía `POST /validation/class/:id/review` con acción approved, y dejaba `locked_for_validation` en true. Esa ruta ya responde 410 para `class`. Sigue contando como clase completada (ver «Validación de clase»). | El apagado no convierte una fila `APPROVED`: se conserva y cuenta como completada. Si conserva el bloqueo, el desbloqueo la suelta. |
| `investiture_validation_history` | Auditoría ya grabada. | Solo se lee. No se borra. El desbloqueo agrega filas `LEGACY_LOCK_RELEASED`. |
| `investiture_config` | Fecha de la investidura formal vieja. | La tabla y sus filas se conservan. Su CRUD y sus lecturas responden 410. |
| `HISTORICAL_CERTIFICATE` | Fuera de esta cadena. | Sigue la fase 0B. |

No hay conversión ni reinicio masivo de expedientes del mismo año. La regla de no arrastre entre años pertenece a la solicitud nueva y no autoriza ese reinicio.

`class.completed` sale solo de la autorización nueva, después de confirmar `INVESTIDO`. `markInvestido` se borró: ya no hay otra ruta que lo emita.

### Validación de clase

`ValidationModule` también movía el enrollment de una clase. Desde la fase 8, `entity_type` `class` responde 410 `INVESTITURE_LEGACY_PIPELINE_RETIRED` en `POST /validation/submit` y en `POST /validation/:entityType/:entityId/review` (aprobar o rechazar, con o sin comentario), sin leer ni escribir. Esas rutas conservan `validation:submit` y `validation:review`, así que sin el permiso la respuesta es 403 antes que el 410. `GET /validation/pending` devuelve `classes: []`. `GET /validation/:entityType/:entityId/history` sigue leyendo. El honor no cambia: `entity_type` distinto de `class` sigue en el flujo de honores.

| Método y ruta | Antes | Ahora |
| --- | --- | --- |
| `POST /api/v1/validation/submit` con `entity_type` `class` | De `IN_PROGRESS` a `SUBMITTED_FOR_VALIDATION` con `locked_for_validation` true, más historia. | 410 |
| `POST /api/v1/validation/class/:id/review` | Aprobar dejaba `APPROVED` y el bloqueo en true; rechazar volvía a `IN_PROGRESS`. | 410 |
| Panel `/dashboard/clubs/validations`, pestaña de clase | Armaba esa cola y llamaba el POST. | Pestaña borrada. |

`APPROVED` sigue contando como clase completada (se conserva el estado grabado y hay pruebas que lo fijan) en:

- `sacdia-backend/src/annual-folders/score-calculators/class-investiture-progress-score.ts`
- `sacdia-backend/src/validation/validation.service.ts` (resumen de elegibilidad de investidura)
- `sacdia-backend/src/club-role-eligibility/club-role-eligibility.service.ts` (elegibilidad de Guía Mayor, base `APPROVED`)
- `sacdia-backend/src/clubs/clubs.service.ts`: `investidos_year` del resumen del club cuenta `APPROVED` o `INVESTIDO` con `record_kind` `OPERATIONAL`. Antes solo contaba `APPROVED`, que la vía nueva nunca escribe.

### Conciliación de certificados

La aprobación de un certificado de clase mira `investiture_authorization_people` dentro de la misma transacción. Antes toma el candado advisory del año del certificado, después `FOR SHARE` de las filas, y luego el candado de usuario y el de enrollment. C-1 está en el árbol y no está cerrado.

| Caso | Qué hace |
| --- | --- |
| Año de la solicitud y `PENDING` | Rechaza con `CERTIFICATE_IMPORT_AUTHORIZATION_PENDING`. No escribe el enrollment. El año es el de la solicitud, no el de inicio de la inscripción. |
| Mismo año sin `PENDING` | Sigue `reconcileOperationalEnrollment`: el operativo pasa a `INVESTIDO` si la versión coincide. |
| Año anterior y `PENDING`, Guía Mayor | `substituteGuideMajor` deja una fila `HISTORICAL_CERTIFICATE` `INVESTIDO` y la persona pasa a `REMOVED` con `HISTORICAL_CERTIFICATE_APPLIED`. |
| Año anterior a la solicitud y `PENDING`, otra clase | Retira el `PENDING` con el mismo código. Si el certificado cae en el año de la inscripción operativa, esa fila se reconcilia. Si es anterior también a ese inicio, crea la fila histórica `INVESTIDO`. |
| Año anterior sin `PENDING` | No retira a nadie. Sigue la acreditación histórica que ya existía. |
| Año de la solicitud ya terminado y certificado posterior | La persona queda `CLOSED_YEAR` en la misma transacción, sin motivo de falta de requisitos y sin la nota del certificado del mismo año. El certificado se acredita como si no hubiera `PENDING`. |
| Año de la solicitud ya terminado y certificado de ese mismo año | La persona queda o sigue `CLOSED_YEAR`. `system_reason` es «Investidura acreditada posteriormente mediante certificado validado». El operativo de ese año pasa a `INVESTIDO`. Otro Campo, un director sin Campo o un actor sin rol reciben HTTP 403 `CERTIFICATE_IMPORT_ENDED_YEAR_FIELD_FORBIDDEN`. Si el lote quedó en otro Campo, solo un admin global o `super-admin` acredita. |
| Clase `GM-02` o `GM-03` | Presentar y agregar responden `INVESTITURE_REQUEST_CLASS_NOT_ELIGIBLE`. Un `PENDING` previo, al resolver, queda `REMOVED` / `CLASS_NOT_ELIGIBLE` y el resto de la resolución sigue. No hay investidura ni recordatorio. El certificado institucional no cambia. |

### Lecturas, cupo y avisos (2026-10-07)

Pendiente de revisión independiente.

- La persona, en `GET /api/v1/investiture-history`, ve su pendiente con «En espera de autorización.», la investidura con fecha, clase y comentario, y cualquier rechazo como `REJECTED` con solo «Falta de requisitos para investidura». No ve el motivo humano, el texto largo ni quién rechazó. El cierre anual no usa ese texto. Las notas de certificado posterior e histórico se conservan.
- La directiva ve el motivo humano y el texto largo. El autorizador ve el texto largo y no el motivo humano. Ambas lecturas traen el nombre de la persona, la clase, la sección y quien decidió. Un rechazo del sistema nombra «Sistema». `super-admin` lee una solicitud por id, con esa forma de directiva, y no presenta ni autoriza.
- Una asignación de pastor sigue ocupando cupo si el usuario pierde el rol global o si su cuenta se elimina (eliminación lógica, `users.active = false`). El listado la marca `can_authorize: false` y, según el caso, `role_missing: true` (falta el rol) o `account_inactive: true` (cuenta eliminada). Una sola regla (`investiture-pastor-eligibility.ts`) exige el rol global `pastor` activo, comparado sin distinguir mayúsculas y solo en la categoría `GLOBAL`, y una cuenta activa. La usan el listado, los autorizadores, la resolución (también aunque el token aún lleve el rol) y los correos de presentación y de recordatorio. Una asignación que no la cumple no sale entre los autorizadores, no autoriza ni recibe correos.
- El recordatorio del día programado puede salir desde las 10:00 hasta las 23:59 locales solo si la corrida de las 10:00 no ocurrió. La corrida del día se registra por Campo, rol y día local en `investiture_reminder_runs` (clave primaria `(local_field_id, role, local_date)`), también cuando ese día no había pendientes. La primera ejecución del día reclama la corrida con una inserción idempotente y deja en la misma transacción las filas `pending`; las siguientes, aunque sean de otra instancia, no generan recordatorios para destinatarios nuevos. Con el correo de investidura apagado no se reclama el día. Si el render del recordatorio de un Campo falla (por ejemplo `ADMIN_PANEL_URL` vacío), ese Campo no consume el día: su reclamo se libera en la misma transacción y una ejecución posterior del mismo día local, ya corregida la configuración, lo recupera una sola vez; los demás Campos conservan su reclamo. No se recupera un día anterior ni se duplica. Un reintento de un fallo vale solo ese día local. El tope son exactamente 5 intentos de entrega al canal de correo, contando tanto el reclamo de la fila como cada re-encolado de un job `failed` o ausente. El intento 6 no sale: la fila queda `skipped` con `reminder_retry_limit` (o `reminder_day_elapsed`). Cada entrega de un recordatorio a la cola es un único intento ante el proveedor (`attempts: 1`; presentación y resultado conservan el valor por defecto de la cola), así que el total no pasa de 5 llamadas al proveedor por recordatorio.
- La directiva recibe como máximo dos avisos de resultado: investidos y rechazados. El de rechazados junta el pastor o el Campo y el sistema, sin el motivo humano.
- Un año eclesiástico con `active` en false no admite cambiar el porcentaje, aunque el día de hoy caiga dentro de sus fechas.
- Cambiar la fecha guarda `date_changed_by_id` y `date_changed_at`. Quitar y cambiar la fecha usan el reloj inyectable.
- `district_investiture_pastors.user_id` referencia `users` con `ON DELETE RESTRICT`. La migración no está aplicada en Neon.
- Si el pastor cambia de Campo o queda sin Campo (por ejemplo al eliminar su cuenta), o si el distrito pasa a otro Campo, la asignación pasa a `active = false` y libera el cupo; hasta que el distrito tenga un pastor nuevo autorizan el `director-lf` y el `assistant-lf` del Campo. Lo hacen dos triggers de la migración `20261008120000_district_pastor_field_change`, que no está aplicada en Neon. Esto acota la regla de arriba: una cuenta eliminada que pierde su Campo ya no sigue ocupando cupo.
- Enviar una sección, o aprobar o rechazar una evidencia, sobre un enrollment `INVESTIDO` o `EXPIRED` responde `CLASS_PROGRESS_LOCKED` y no escribe.
- Crear un lote de certificados con `mark_as_ready: true` aplica la misma validación que marcar listo. Si la edad no alcanza, o el catálogo no existe o está inactivo (`CERTIFICATE_IMPORT_CATALOG_NOT_FOUND`), el ítem nace `NEEDS_REVIEW` con ese código en `rejection_reason` y no falla el lote; una fecha futura se trata igual aunque `mark_as_ready` sea false. Editar un ítem existente (`PATCH`) sigue respondiendo 400 con esos códigos.

### Qué falta para cerrar la fase 8

- Mergear los PRs de backend, panel y app (pendientes).
- Aplicar en orden, en cada entorno, las migraciones pendientes de investidura desde `20260903180000`, incluidas `20261008120000_district_pastor_field_change` y `20261009120000_investiture_legacy_lock_release_action`. En producción no hay ninguna aplicada (ver el conteo de arriba).
- Correr el desbloqueo por entorno, con `dry_run` primero y con aprobación del usuario en cada uno. Hoy no se corrió en ninguno.
- Este documento no certifica el despliegue: describe lo implementado en las ramas.

## Gaps y pendientes

- Las pantallas de presentar y autorizar (panel y app) siguen en los planes `docs/plans/2026-10-08-investidura-ui-*.md`.
- No hay notificaciones asociadas a la vía anterior; la solicitud nueva avisa en la bandeja de la app.
- No hay reportes de investiduras por periodo/campo local/club — Iteracion 2.
- No hay cron automatico de vencimiento; el proceso es admin/manual (`expire-overdue`).
- El tablero SLA de analytics sigue leyendo la historia ya grabada (`FIELD_APPROVED`); no se reescribió.

## Implementacion completada

- ✅ Backend (rama `feat/investiture-legacy-shutdown`, sin desplegar): 17 rutas retiradas con 410, `ValidationModule` `class` con 410, historial y `expire-overdue` intactos, desbloqueo para `super-admin`, `investidos_year` contando `APPROVED` o `INVESTIDO`, X-1 solo por `locked_for_validation`
- ✅ Admin (rama `feat/investiture-legacy-screens-removal`): pantallas de investidura vieja, `/dashboard/enrollments` y pestaña «Módulos» borradas
- ✅ App (rama `feat/investiture-legacy-app-removal`): feature vieja, rutas, tarjeta del hub, entrada del push y tarjeta de estado de clase quitadas; insignia «Investido»
- ✅ Vencimiento manual de enrollments atrasados por duracion maxima con modo `dry_run` y auditoria `EXPIRED`
- ⏳ Sin mergear, sin desplegar, migraciones sin aplicar en Neon, desbloqueo sin ejecutar
