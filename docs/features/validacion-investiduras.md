# Validacion de Investiduras

**Estado**: IMPLEMENTADO (pipeline de abajo, en `development`)

> [!WARNING]
> **Pendiente de merge (PR #448 de sacdia-backend).** La ventana del Campo, el cupo y la asignación de pastores, `investiture-authorizers` y las solicitudes `investiture-requests` descritas en esta nota están en la rama `feat/investiture-authorization-ocr`, no en `development`.

> El pipeline descrito abajo sigue siendo el runtime. El acuerdo nuevo, todavía sin implementar en la operación, está en `docs/plans/2026-09-28-investidura-autorizacion.md`. El documento de ceremonia colectiva del 2026-09-21 quedó reemplazado. La ventana del Campo (`GET` y `PATCH /api/v1/local-fields/:localFieldId/investiture-windows/:ecclesiasticalYearId`) ya se puede leer y guardar. Sin fila, si octubre–diciembre intersecta el año, la respuesta trae ese recorte, `configured: false` y `operational: true`. Si no hay intersección y no hay una configuración válida dentro del año, `start_date` y `end_date` son `null`, `configured` es false y `operational` es false: no se abre el año completo y la lectura no inserta una fila. `operational` indica que existe un rango, no que el día local esté dentro. El cupo de pastores del distrito y su asignación (`/api/v1/investiture-pastor-quota`, `/api/v1/districts/:districtId/investiture-pastors`, `/api/v1/clubs/:clubId/investiture-authorizers`) ya se pueden leer y guardar. El cambio de cupo y las altas o reactivaciones se coordinan en la misma transacción, también si todavía no hay fila de cupo. El distrito de esa lectura sale de la iglesia del club. Esa configuración y esa asignación no pasan por las rutas `submit`, `club-approve`, `coordinator-approve`, `field-approve` ni `invest`, y no las apagan. La solicitud nueva (`POST /api/v1/club-sections/:sectionId/investiture-requests` y las rutas de personas, lectura y fecha) marca, quita y corrige la fecha dentro de la sección. Una clase de varios años conserva el enrollment de inicio. Una clase cruzada de Guía Mayor se presenta en la sección de esa clase, del mismo club. Mientras hay un pendiente, el progreso de ese enrollment no se escribe. Agregar a una solicitud anterior, cuando ya hay otra con pendientes, se rechaza y hay que volver a cargar el listado. La autorización (`GET /api/v1/investiture-requests` y `POST /api/v1/investiture-requests/:requestId/resolutions`) la hace el pastor del distrito de la iglesia o el Campo de esa solicitud. Vuelve a comprobar año, ventana y pastor dentro de la transacción, con el instante leído después de los candados. Pasa el enrollment a `INVESTIDO` sin el pipeline de abajo y deja una intención de `class.completed`. Esa intención se entrega una sola vez aunque después cierren el año o la ventana; esa entrega no vuelve a autorizar. El identificador de la cola no es la clave guardada. Si ese trabajo queda en `failed`, se reintenta el mismo id sin abrir otra fila. Después de confirmar la presentación, la intención del correo queda en esa transacción con una identidad propia de esa operación, y el envío se materializa después. Recuperar no cambia esa identidad ni reenvía a quien ya fue atendido. Encolar no es entregar. Si el acuse del proveedor se pierde y el envío sigue permitido, el reintento conserva el mismo contenido durante 24 horas y después queda incierto, sin reenviar solo. Antes de esa llamada se vuelven a comprobar destinatario, año y pendientes. Si ya no corresponde, o si solo queda autorizada una parte del contenido congelado, no se envía y no se cambia el cuerpo ni la clave. Ese cuerpo, su destino y su alcance salen de la misma instantánea con la que se armó el correo. La resolución confirmada avisa en la bandeja de la app con una clave única, sin el motivo humano. El recordatorio sale por correo a las 10:00 locales, se vuelve a comprobar al entregar y no abre una bandeja nueva en el panel. El cierre administrativo del año y el corte automático dejan cada pendiente de ese año en `CLOSED_YEAR`, sin el texto de falta de requisitos y sin copiar la solicitud al año siguiente. Repetirlos no cambia a quien ya estaba investido. El historial (`GET /api/v1/investiture-history` y `GET /api/v1/club-sections/:sectionId/investiture-history`) conserva clase y año. El anuario (`GET /api/v1/club-sections/:sectionId/investiture-yearbook`) lista la inscripción operativa en la sección de su tipo de clase, dentro del mismo club, para el director, el secretario o el secretario-tesorero. Una clase de Conquistadores de quien tiene membresía en Guías Mayores no aparece en el anuario de Guías Mayores. No inscribe solo ni cierra unidades o finanzas. El panel todavía no muestra esa pantalla. No apaga el pipeline de abajo. La app no tiene la pantalla de presentar. Este corte no está aprobado.

## Descripcion de dominio

La validacion de investiduras es el proceso institucional mediante el cual el avance formativo de un miembro recibe reconocimiento formal. Es el cierre del ciclo formativo: un miembro completa su clase progresiva durante el ano eclesiastico, su progreso es validado por las autoridades del club y del campo local, y finalmente es investido en una ceremonia oficial.

El proceso tiene multiples etapas definidas por el canon: (1) el miembro completa los requisitos de su clase dentro de la duracion configurada, (2) el consejero o director envia el registro a validacion, (3) el registro queda bloqueado y pasa a revision institucional, (4) la autoridad competente aprueba o rechaza, (5) si es aprobado, se programa la investidura, (6) el miembro es investido formalmente. Este flujo es central para la identidad del sistema — sin validacion de investiduras, SACDIA puede registrar avance pero no puede reconocerlo institucionalmente.

La Decision 6 del canon establece que registrar y validar son actos distintos: la captura operativa (registrar progreso dia a dia) y la validacion institucional (aprobar y reconocer formalmente) tienen actores, momentos y reglas diferentes. Al entrar en validacion, el registro deja de ser editable — esto es un efecto de dominio critico que protege la integridad del proceso.

El schema de base de datos y el runtime ya sostienen investiduras como superficie activa. El backend expone flujo multietapa, compatibilidad legacy, operaciones bulk y CRUD de configuracion; el admin tiene pantallas ruteadas para pendientes, pipeline y configuracion; la app tiene pantallas ruteadas para pendientes e historial, y expone el envio a validacion desde el detalle de clase cuando el enrollment esta 100% completado.

Los requisitos `BASIC` y `EXTRA` cuentan para investidura; `ADVANCED` activa el estado/badge avanzado de la clase por separado y no entra como requisito obligatorio del flujo.

## Que existe (verificado contra codigo)

### Backend (InvestitureModule)
- **InvestitureModule implementado** — `InvestitureController`, `InvestitureService`, DTOs de pipeline/config/bulk, registrado en `AppModule`
- **Superficie canonica activa**:
  - `POST /investiture/enrollments/:enrollmentId/submit`
  - `POST /investiture/enrollments/:enrollmentId/club-approve`
  - `POST /investiture/enrollments/:enrollmentId/coordinator-approve`
  - `POST /investiture/enrollments/:enrollmentId/field-approve`
  - `POST /investiture/enrollments/:enrollmentId/invest`
  - `POST /investiture/enrollments/:enrollmentId/reject`
  - `GET /investiture/pending`
  - `GET /investiture/enrollments/:enrollmentId/history`
  - `POST /investiture/enrollments/bulk-approve`
  - `POST /investiture/enrollments/bulk-reject`
  - `GET|POST|PATCH|DELETE /admin/investiture/config`
  - `POST /admin/classes/enrollments/expire-overdue` — proceso admin/manual para vencer enrollments atrasados por duracion maxima de clase
- **Compatibilidad legacy aun activa**:
  - `POST /enrollments/:enrollmentId/submit-for-validation`
  - `POST /enrollments/:enrollmentId/validate`
  - `POST /enrollments/:enrollmentId/investiture`
  - `GET /enrollments/:enrollmentId/investiture-history`
- El `enrollments` model en Prisma tiene campos de investidura expuestos via los endpoints anteriores:
  - `investiture_status` (investiture_status_enum)
  - `submitted_for_validation` (Boolean, default false)
  - `submitted_at` (DateTime?)
  - `validated_by` (UUID?)
  - `validated_at` (DateTime?)
  - `rejection_reason` (String?)
  - `investiture_date` (DateTime?)
  - `locked_for_validation` (Boolean, default false)

### Admin (sacdia-admin)
- **Implementado y ruteado** — paginas y navegacion activas en:
  - `/dashboard/investiture` — pendientes con datos operables por defecto: miembro, clase, ano eclesiastico, club, seccion, remitente, cargo/rol del remitente, fecha de envio, estado y detalle con historial, modulos/secciones completadas, evidencias enviadas y validador por seccion
    - La etiqueta visible de seccion es `{clubs.name} · {club_types.name}`. Las secciones no tienen nombre propio.
  - `/dashboard/investiture/pipeline` — seguimiento operativo de investiduras del ano eclesiastico en curso, con solicitudes por etapa y registros ya tratados (`club-approve`, `coordinator-approve`, `field-approve`, `reject`, `invest`)
  - `/dashboard/investiture/config` — CRUD de `investiture_config`
  - Entry en sidebar bajo "Investiduras"

### App (sacdia-app)
- **Implementado y expuesto en flujos principales**:
  - `InvestiturePendingListView` esta ruteada en GoRouter (`/investiture/pending`) y permite aprobar/rechazar/marcar investido segun rol
  - `InvestitureHistoryView` esta ruteada en GoRouter (`/investiture/enrollment/:enrollmentId/history`)
  - `ClassDetailWithProgressView` muestra una tarjeta de investidura cuando la clase tiene 100% de requisitos validados:
    - si el usuario activo es `director` o `counselor`, permite enviar el enrollment a validacion
    - si el usuario no tiene ese rol, muestra la indicacion de que un consejero/director debe enviarlo
    - si ya fue enviado/aprobado/investido, muestra el estado y acceso al historial
  - `InvestitureSubmitView` existe en codigo para un listado de miembros, pero no tiene entrada de navegacion dedicada
  - Data layer, providers y widgets de estado existen para submit, pending e history

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
- SUBMITTED, CLUB_APPROVED, COORDINATOR_APPROVED, FIELD_APPROVED, APPROVED, REJECTED, REINVESTITURE_REQUESTED, INVESTIDO, EXPIRED

**Enum `evidence_validation_enum`**:
- PENDING, VALIDATED, REJECTED

## Requisitos funcionales

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

- **Maquina de estados en enrollments**: El campo `investiture_status` define el pipeline vigente: IN_PROGRESS -> SUBMITTED_FOR_VALIDATION -> CLUB_APPROVED -> COORDINATOR_APPROVED -> FIELD_APPROVED -> INVESTIDO, con `REJECTED` como salida de correccion y `EXPIRED` como salida terminal por vencimiento de duracion maxima
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

## Preparación de fase 8 — inventario, sin apagado

Fecha: 2026-10-06. Esta sección inventaría la vía club → coordinación → campo y fija su tratamiento. No apaga rutas, no borra pantallas y no modifica filas. No se consultó Neon ni producción: no hay conteos reales en este documento. Esos conteos, si se necesitan, exigen una lectura aparte y aprobada. La fase 8 no está ejecutada.

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

**Desbloqueo aprobado (2026-10-08).** Después del apagado, una operación explícita suelta `locked_for_validation` solo si el enrollment no está `INVESTIDO` y no tiene una persona `PENDING`; el estado no cambia. Con producción vacía hoy, aplica a datos que se creen antes del apagado o a otros entornos (por ejemplo `development`).

Un expediente de esta vía es un `enrollments` con `record_kind = OPERATIONAL` y un `investiture_status` de la cadena, más las filas ya grabadas en `investiture_validation_history`. El certificado histórico (`HISTORICAL_CERTIFICATE`) no es este expediente. Si hay una persona `PENDING` de esa clase, el mismo año rechaza el certificado y un año anterior retira a esa persona al acreditar. Las rutas de esta vía siguen activas.

### Rutas que siguen activas

Todas responden bajo `/api/v1`. El controlador es `sacdia-backend/src/investiture/investiture.controller.ts`.

| Método y ruta | Escritura | Efecto actual |
| --- | --- | --- |
| `POST /investiture/enrollments/:enrollmentId/submit` | Sí | `IN_PROGRESS` → `SUBMITTED_FOR_VALIDATION`. Deja `locked_for_validation`. |
| `POST /enrollments/:enrollmentId/submit-for-validation` | Sí | El mismo `submitForValidation`. Alias. |
| `POST /investiture/enrollments/:enrollmentId/club-approve` | Sí | `SUBMITTED_FOR_VALIDATION` → `CLUB_APPROVED`. |
| `POST /investiture/enrollments/:enrollmentId/coordinator-approve` | Sí | `CLUB_APPROVED` → `COORDINATOR_APPROVED`. |
| `POST /investiture/enrollments/:enrollmentId/field-approve` | Sí | `COORDINATOR_APPROVED` → `FIELD_APPROVED`. |
| `POST /investiture/enrollments/:enrollmentId/invest` | Sí | Solo desde `FIELD_APPROVED` → `INVESTIDO`. Copia la fecha de `investiture_config` y emite `class.completed`. |
| `POST /enrollments/:enrollmentId/investiture` | Sí | El mismo `markInvestido`. Alias. |
| `POST /investiture/enrollments/:enrollmentId/reject` | Sí | Desde `SUBMITTED_FOR_VALIDATION`, `CLUB_APPROVED`, `COORDINATOR_APPROVED` o `FIELD_APPROVED` → `REJECTED`. Libera `locked_for_validation`. |
| `POST /enrollments/:enrollmentId/validate` | Sí | Alias. Solo si está `SUBMITTED_FOR_VALIDATION`. `APPROVED` escribe `CLUB_APPROVED`. `REJECTED` escribe `REJECTED` y libera el bloqueo. |
| `POST /investiture/enrollments/bulk-approve` | Sí | `coordinator-approve`, `field-approve` o `invest`. No incluye `club-approve`. `invest` también llega a `INVESTIDO`. |
| `POST /investiture/enrollments/bulk-reject` | Sí | Los cuatro estados rechazables → `REJECTED`. |
| `POST /admin/classes/enrollments/expire-overdue` | Sí | `IN_PROGRESS` o `REJECTED` que superan la duración → `EXPIRED`, con historia `EXPIRED`. |
| `GET /investiture/pending` | No | Lista operativos activos en los cuatro estados de la cadena. Por defecto los cuatro; `status` filtra uno. |
| `GET /investiture/enrollments/:enrollmentId/history` | No | Lee `investiture_validation_history`. |
| `GET /enrollments/:enrollmentId/investiture-history` | No | La misma lectura. Alias. |
| `GET /admin/investiture/config` y `GET /admin/investiture/config/:configId` | No | Leen la fecha que usa `markInvestido`. |
| `POST`, `PATCH` y `DELETE /admin/investiture/config` | Sí | Crean, editan o dejan inactiva esa configuración. El `DELETE` no borra la fila: pone `active = false`. |

### Pantallas que siguen activas

| Superficie | Ruta | Qué hace hoy |
| --- | --- | --- |
| Panel | `/dashboard/investiture` | Pendientes. Llama `GET /investiture/pending`. |
| Panel | `/dashboard/investiture/pipeline` | Aprueba, rechaza e inviste por la cadena, también en bloque. |
| Panel | `/dashboard/investiture/config` | Alta, edición y baja lógica de `investiture_config`. |
| App | `/investiture/pending` | Lista pendientes y llama `POST /enrollments/:enrollmentId/validate`. |
| App | `/investiture/enrollment/:enrollmentId/history` | Lee el historial alias. |
| App | Detalle de clase completada | Llama `POST /enrollments/:enrollmentId/submit-for-validation`. |
| App | `InvestitureSubmitView` | Existe en código y no tiene ruta propia. |
| App | Proveedor `markInvestido` | Llama `POST /enrollments/:enrollmentId/investiture`. Ninguna vista lo invoca. |

### Expedientes y tratamiento

Hasta una aprobación posterior, el tratamiento es conservar el estado grabado.

| Estado o registro | Papel | Tratamiento mientras la vía siga activa, y también como condición previa a apagarla |
| --- | --- | --- |
| `IN_PROGRESS` | Todavía no entra a la cadena. | No se convierte ni se envía solo. Sigue en el enrollment. |
| `SUBMITTED_FOR_VALIDATION`, `CLUB_APPROVED`, `COORDINATOR_APPROVED`, `FIELD_APPROVED` | Expediente abierto del mismo año. `locked_for_validation` está en true. | No se resuelve en silencio, no se arrastra al año siguiente, no se copia a `investiture_authorization_requests` y no se libera el bloqueo. Un apagado posterior no puede cerrarlos ni duplicar su investidura por la vía nueva sin una decisión aparte. |
| `REJECTED` | Salió de la cadena para corrección. El bloqueo de esa validación ya está en false. | No se reinicia en masa. |
| `INVESTIDO` | Terminal de esta vía. | Se conserva. No se reescribe. |
| `EXPIRED` | Terminal por duración. | Se conserva. No se reabre. |
| `APPROVED` | Lo escribe `POST /validation/class/:id/review` con acción approved, y deja `locked_for_validation` en true. El alias `validate` no deja el enrollment en `APPROVED`: escribe `CLUB_APPROVED`. Cuenta como clase completada en el puntaje, el club, la asignación de consejero y el resumen de validación. | Esta preparación no convierte una fila `APPROVED`. El apagado tiene que tratarla junto con el resto de expedientes abiertos. |
| `investiture_validation_history` | Auditoría ya grabada. | Solo se lee. No se borra. |
| `investiture_config` | Fecha de la investidura formal vieja. | Sigue. Esta preparación no apaga su CRUD ni borra filas. |
| `HISTORICAL_CERTIFICATE` | Fuera de esta cadena. | Sigue la fase 0B. |

No hay conversión ni reinicio masivo de expedientes del mismo año. La regla de no arrastre entre años pertenece a la solicitud nueva y no autoriza ese reinicio.

`class.completed` de una investidura nueva sale de la autorización, después de confirmar `INVESTIDO`. `markInvestido` sigue pudiendo emitirlo mientras esta vía esté activa. Esta preparación no cambia ninguno de los dos.

### Validación de clase

`ValidationModule` también mueve el enrollment de una clase. El honor no entra en esta fila: `entity_type` distinto de `class` sigue en el flujo de honores y esta entrega no lo cambia.

| Método y ruta | Archivo | Qué escribe | Quién lo consume |
| --- | --- | --- | --- |
| `POST /api/v1/validation/submit` con `entity_type` `class` | `sacdia-backend/src/validation/validation.controller.ts:44` y `validation.service.ts` `submitClassForReview` (líneas 43–72) | De `IN_PROGRESS` a `SUBMITTED_FOR_VALIDATION`, `submitted_for_validation` true y `locked_for_validation` true. También escribe `investiture_validation_history`. | El miembro, con permiso `validation:submit`. |
| `POST /api/v1/validation/class/:id/review` | `validation.controller.ts:78` y `reviewClass` (líneas 162–207) | Aprobar deja `APPROVED` y el bloqueo en true. Rechazar vuelve a `IN_PROGRESS`, suelta el bloqueo y limpia el envío. También actúa sobre un expediente que ya envió la vía club → coordinación → campo, si ese enrollment está `SUBMITTED_FOR_VALIDATION`. | Panel `/dashboard/clubs/validations`, pestaña de clase. `clubs-validations-client.tsx` línea 123 arma esa cola. `reviewValidation` en `sacdia-admin/src/lib/api/validation.ts:177` llama el POST. El diálogo está en `validation-review-dialog.tsx`. |

`APPROVED` cuenta como completada en:

- `sacdia-backend/src/annual-folders/score-calculators/class-investiture-progress-score.ts:34`
- `sacdia-backend/src/clubs/clubs.service.ts:1464`
- `sacdia-backend/src/classes/class-counselor-assignments.service.ts:38`
- `sacdia-backend/src/validation/validation.service.ts:413`

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

Pendiente de revisión independiente. No apaga el pipeline de arriba.

- La persona, en `GET /api/v1/investiture-history`, ve su pendiente con «En espera de autorización.», la investidura con fecha, clase y comentario, y cualquier rechazo como `REJECTED` con solo «Falta de requisitos para investidura». No ve el motivo humano, el texto largo ni quién rechazó. El cierre anual no usa ese texto. Las notas de certificado posterior e histórico se conservan.
- La directiva ve el motivo humano y el texto largo. El autorizador ve el texto largo y no el motivo humano. Ambas lecturas traen el nombre de la persona, la clase, la sección y quien decidió. Un rechazo del sistema nombra «Sistema». `super-admin` lee una solicitud por id, con esa forma de directiva, y no presenta ni autoriza.
- Una asignación de pastor sigue ocupando cupo si el usuario pierde el rol global o si su cuenta se elimina (eliminación lógica, `users.active = false`). El listado la marca `can_authorize: false` y, según el caso, `role_missing: true` (falta el rol) o `account_inactive: true` (cuenta eliminada). Una sola regla (`investiture-pastor-eligibility.ts`) exige el rol global `pastor` activo, comparado sin distinguir mayúsculas y solo en la categoría `GLOBAL`, y una cuenta activa. La usan el listado, los autorizadores, la resolución (también aunque el token aún lleve el rol) y los correos de presentación y de recordatorio. Una asignación que no la cumple no sale entre los autorizadores, no autoriza ni recibe correos.
- El recordatorio del día programado puede salir desde las 10:00 hasta las 23:59 locales solo si la corrida de las 10:00 no ocurrió. La corrida del día se registra por Campo, rol y día local en `investiture_reminder_runs` (clave primaria `(local_field_id, role, local_date)`), también cuando ese día no había pendientes. La primera ejecución del día reclama la corrida con una inserción idempotente y deja en la misma transacción las filas `pending`; las siguientes, aunque sean de otra instancia, no generan recordatorios para destinatarios nuevos. Con el correo de investidura apagado no se reclama el día. Si el render del recordatorio de un Campo falla (por ejemplo `ADMIN_PANEL_URL` vacío), ese Campo no consume el día: su reclamo se libera en la misma transacción y una ejecución posterior del mismo día local, ya corregida la configuración, lo recupera una sola vez; los demás Campos conservan su reclamo. No se recupera un día anterior ni se duplica. Un reintento de un fallo vale solo ese día local. El tope son exactamente 5 intentos de entrega al canal de correo, contando tanto el reclamo de la fila como cada re-encolado de un job `failed` o ausente. El intento 6 no sale: la fila queda `skipped` con `reminder_retry_limit` (o `reminder_day_elapsed`). Cada entrega de un recordatorio a la cola es un único intento ante el proveedor (`attempts: 1`; presentación y resultado conservan el valor por defecto de la cola), así que el total no pasa de 5 llamadas al proveedor por recordatorio.
- La directiva recibe como máximo dos avisos de resultado: investidos y rechazados. El de rechazados junta el pastor o el Campo y el sistema, sin el motivo humano.
- Un año eclesiástico con `active` en false no admite cambiar el porcentaje, aunque el día de hoy caiga dentro de sus fechas.
- Cambiar la fecha guarda `date_changed_by_id` y `date_changed_at`. Quitar y cambiar la fecha usan el reloj inyectable.
- `district_investiture_pastors.user_id` referencia `users` con `ON DELETE RESTRICT`. La migración no está aplicada en Neon.
- Enviar una sección, o aprobar o rechazar una evidencia, sobre un enrollment `INVESTIDO` o `EXPIRED` responde `CLASS_PROGRESS_LOCKED` y no escribe.
- Crear un lote de certificados con `mark_as_ready: true` aplica la misma validación que marcar listo. Si la edad no alcanza, o el catálogo no existe o está inactivo (`CERTIFICATE_IMPORT_CATALOG_NOT_FOUND`), el ítem nace `NEEDS_REVIEW` con ese código en `rejection_reason` y no falla el lote; una fecha futura se trata igual aunque `mark_as_ready` sea false. Editar un ítem existente (`PATCH`) sigue respondiendo 400 con esos códigos.

### Propuesta, sin decisión: expediente bloqueado después del apagado

Hoy, si la vía nueva rechaza un expediente con `locked_for_validation` true, nadie suelta ese bloqueo y el enrollment sigue trabado hasta el fin de año. Con la exclusión de X-1 la vía nueva ya no lo acepta al presentar ni al agregar.

Propuesta, pendiente de aprobación y no aplicada: una operación posterior y explícita soltaría `locked_for_validation` solo en filas que no están `INVESTIDO` y que no tienen una persona `PENDING` en la solicitud nueva. El `investiture_status` no cambiaría. Hasta esa aprobación, la fila sigue bloqueada y no se presenta por la vía nueva. Esta entrega no ejecuta ese desbloqueo ni apaga rutas.

## Gaps y pendientes

- `InvestitureSubmitView` de listado existe en app pero no esta expuesta por una ruta dedicada; el envio visible principal se realiza desde el detalle de clase completada
- No hay notificaciones asociadas a cambios de estado de validacion — Iteracion 2
- No hay reportes de investiduras por periodo/campo local/club — Iteracion 2
- No hay cron automatico de vencimiento; el proceso inicial es admin/manual

## Implementacion completada

- ✅ Backend: modulo activo con pipeline multietapa, compat legacy, bulk ops y CRUD de configuracion
- ✅ Admin: pendientes, pipeline y configuracion accesibles desde rutas del dashboard y sidebar
- ✅ App: pending/history ruteados; envio visible desde detalle de clase completada para `director`/`counselor`
- ✅ Bulk operations: hasta 200 enrollments por operacion; `club-approve` sigue siendo individual
- ✅ Vencimiento manual de enrollments atrasados por duracion maxima con modo `dry_run` y auditoria `EXPIRED`
