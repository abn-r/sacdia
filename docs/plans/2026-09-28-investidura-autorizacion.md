# Investidura por autorización — plan funcional

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** El directivo de la sección marca en la app a quienes cumplen, y un pastor del distrito o el Campo Local los autoriza en el panel dentro de la ventana configurada. `INVESTIDO` solo existe después de esa autorización.

**Architecture:** Una solicitud pertenece a una sola sección y agrupa el envío y el correo. El resultado y el bloqueo de progreso son por persona y por clase. La ventana del Campo gobierna la presentación y la autorización; los recordatorios por correo tienen frecuencia según el rol. El pipeline actual club → coordinación → campo deja de ser la vía operativa para llegar a `INVESTIDO`. Los certificados históricos no cambian.

**Tech Stack:** NestJS, Prisma, PostgreSQL, Next.js admin, Flutter app, correo Resend, bandeja de notificaciones existente.

- **Estado:** acuerdo funcional del 2026-09-28, actualizado con las decisiones de revisión hasta el 2026-09-29. Sin implementación.
- **Cambios de esta revisión:** solicitud de una sola sección; fechas sobre personas seleccionadas; excepción GM por clase sin ampliar inscripciones; bloqueo de progreso y resolución concurrente; ventana operativa sin plazo individual de siete días; permisos de consulta/edición de fechas; cierre anual sin arrastre y recordatorios acumulativos por rol.
- **Reemplaza:** `docs/plans/2026-09-21-investiture-ceremony-functional-design.md` para este alcance. Ese documento no se implementa.
- **No es contrato runtime.** Al implementar hay que actualizar `docs/features/validacion-investiduras.md`, `docs/api/` y `docs/database/`.

## 1. Decisión central

El director, el secretario o el secretario-tesorero eligen una o varias personas dentro del alcance de su sección y las dejan pendientes. No pueden operar solicitudes de otra sección, aunque pertenezca al mismo club. Pasan a `INVESTIDO` solo cuando autoriza una de estas personas: un pastor asignado al distrito del club, el director del Campo (`director-lf`) o el asistente del Campo (`assistant-lf`). Basta una.

Se guarda quién autorizó. No hay lugar. No hay quien certifica. No hay oficiante. No hay plazo de X días antes de la fecha.

Marcar, quitar, corregir la fecha y ver la solicitud es en la app, de momento. Autorizar y rechazar es solo en el panel. El enlace del correo abre esa solicitud en el panel.

El subdirector (`deputy-director`) no marca, no corrige fechas, no ve la solicitud y no recibe las notificaciones de resultado.

Al terminar el año eclesiástico, lo pendiente se cierra como no investido de ese año. La solicitud no se traslada al año siguiente. Cerrar la ventana operativa antes de esa fecha impide presentar y autorizar, pero no cierra las solicitudes pendientes: permite ampliar la ventana y mantiene los recordatorios.

## 2. Actores

| Acción | Quién |
| --- | --- |
| Marcar, quitar, cambiar fecha, ver la solicitud en la app | `director`, `secretary`, `secretary-treasurer` de la sección de la solicitud. Esos dos últimos siguen siendo excluyentes entre sí. |
| Autorizar o rechazar | Pastor asignado al distrito del club, `director-lf` o `assistant-lf` de ese Campo. Uno basta. |
| Asignar pastores del distrito | `director-lf`, `assistant-lf` de ese Campo, `director-union`, `assistant-union`. |
| Cantidad de cupos de pastor por distrito | `super-admin`. Arranca en 2 y aplica a todos los distritos. |
| Configurar o ampliar la ventana del Campo en el panel | `director-lf` y `assistant-lf` de ese Campo; también `admin` y `super-admin`, respetando el alcance institucional de cada actor. |
| Consultar ventanas en el panel | Campo Local; `director-union` y `assistant-union` para sus Campos; `director-dia` y `assistant-dia` dentro de su división; `admin` y `super-admin` según su alcance. Unión y división no editan. |
| Porcentaje mínimo | `director-lf` y `assistant-lf` hasta el 30 de junio 23:59 en la zona del Campo, dentro del año eclesiástico en curso. Después, solo `super-admin`. |
| Recordatorio por correo lunes, miércoles y viernes | Pastores asignados al distrito; únicamente sus solicitudes pendientes. |
| Resumen por correo los lunes | `director-lf` y `assistant-lf`; todas las solicitudes pendientes de su Campo. `admin` y `super-admin` no reciben recordatorios. |
| Cierre del año | Cierre administrativo y corte automático del año, sin duplicar efectos. |

El distrito de la solicitud es el del club: sección → club → iglesia → distrito (`club_sections` → `clubs.church_id` → `churches.districlub_type_id` → `districts`). El club también guarda `districlub_type_id` y `local_field_id`. Una solicitud es de una sola sección y un solo club, así que tiene un solo distrito y un solo Campo.

Consultar o editar fechas no habilita a autorizar investiduras. Tampoco amplía los permisos sobre el porcentaje mínimo. La API debe aplicar los permisos por acción y el alcance territorial; no basta ocultar controles en el panel.

Hoy `pastor` es un rol global, sin iglesia ni distrito. La asignación al distrito no existe y hay que crearla. Los dos cupos pueden autorizar.

## 3. Reglas

### 3.1 Solicitud y personas

| ID | Regla |
| --- | --- |
| IA-01 | La solicitud pertenece a una sola sección. No puede mezclar secciones, aunque sean del mismo club. Puede incluir clases distintas dentro de su alcance autorizado; cada registro conserva su clase y enrollment. |
| IA-02 | El directivo puede mandar a todos los que cumplen dentro de su sección en un solo envío, o por lotes. La lectura, las acciones y las notificaciones de la directiva se limitan a esa sección. |
| IA-03 | Cada registro de persona y clase es independiente. Autorizar o rechazar a unos no cierra a los demás. Quienes siguen pendientes se resuelven después, mientras la ventana del Campo y el año permanezcan abiertos. |
| IA-04 | Aventureros y Conquistadores regulares: una sola solicitud activa por persona. Si ya está pendiente en una, no entra a otra. |
| IA-05 | Guías Mayores, incluidos quienes ya están investidos de GM y cursan Aventureros o Conquistadores, pueden tener una solicitud activa por persona y clase, siempre que sus inscripciones simultáneas sean válidas. Nunca dos activas de la misma persona y clase. Autorizar, rechazar o bloquear el progreso de una clase no afecta a la otra. Esta excepción no amplía las clases que se pueden cursar ni los límites de inscripción vigentes. |
| IA-06 | Quien ya está `INVESTIDO` en una clase no entra a una nueva solicitud para esa clase. Si existen pendientes anteriores de esa misma persona y clase, dejan de contar como activos y no se pueden autorizar. |
| IA-07 | Un rechazo humano, un rechazo del sistema o quitar a la persona dejan de ser solicitud activa. Se puede corregir el progreso y volver a marcar, siempre que cumpla los requisitos, no esté ya investida en esa clase y la ventana y el año estén abiertos. |
| IA-08 | Solo se agrega a quien ya cumple el progreso de la clase y la duración mínima. La misma comprobación corre otra vez al autorizar. |
| IA-09 | Si al autorizar alguien ya no cumple, el sistema rechaza solo a esa persona. Las demás de la solicitud pueden quedar `INVESTIDO`. El motivo lo escribe el sistema, no quien autoriza. |
| IA-10 | Quien autoriza puede, en la misma solicitud, investir a unos y rechazar a otros. Cada rechazo humano lleva su motivo obligatorio. El comentario de la autorización es opcional. |
| IA-11 | El director, el secretario o el secretario-tesorero pueden quitar a alguien mientras sigue pendiente. Quitar no envía correo. |
| IA-12 | El panel, al autorizar, muestra quién quedó investido y quién fue rechazado. Quien autoriza ve el texto largo del sistema. |
| IA-40 | Mientras un registro está pendiente, el progreso y las evidencias de su enrollment quedan bloqueados. Rechazarlo o quitarlo libera ese bloqueo para corregir y volver a solicitar, sin anular otros bloqueos vigentes como año cerrado, `EXPIRED` o `INVESTIDO`. No se bloquean las otras clases de la persona. |
| IA-41 | Ante decisiones simultáneas sobre el mismo registro, la primera confirmada queda firme. La segunda recibe aviso de que ya fue resuelto. Estado de la solicitud, enrollment y auditoría se confirman atómicamente; los reintentos no sobrescriben la decisión ni duplican sus efectos. |

### 3.2 Progreso y duración

| ID | Regla |
| --- | --- |
| IA-13 | El porcentaje es el del Campo Local. Arranca en 80 al inicio del año eclesiástico. Hoy está fijo en 70 y hay que sustituirlo. |
| IA-14 | Cuentan Desarrollo de clase (`BASIC`) y las actividades complementarias (`EXTRA`) aplicables a división, unión o Campo. Avanzado (`ADVANCED`) no cuenta. |
| IA-15 | Un requisito cuenta si no está `REJECTED` y está `VALIDATED` o su puntaje alcanza el porcentaje del Campo. |
| IA-16 | El porcentaje se aplica al ir registrando el avance, para que la persona vea cómo va. No es un cálculo que solo ocurre al marcar. |
| IA-17 | La escala de letras A/B/C no cambia. El 70 de `computeGrade` en `clubs.service.ts` sigue siendo la nota B. |
| IA-18 | La duración mínima no cambia. Una clase de dos años no se puede marcar en el año 1. Si se pasa la duración máxima, el enrollment vence como hoy. |
| IA-19 | El Campo puede cambiar el porcentaje hasta el 30 de junio a las 23:59 en `local_fields.timezone`, dentro del año eclesiástico en curso. Después solo `super-admin`. |

La comprobación reutiliza `ClassRequirementEligibilityService`, con el porcentaje del Campo en lugar del 70. El mismo criterio debe alimentar `classes.service.ts` (`isCompletedProgress`) y `ClassProgressScopeService.getClassMembersProgress` en `class-progress-scope.service.ts`: no basta sustituir dos constantes y dejar el listado colectivo con otra fórmula. Detalle, listado colectivo y autorización deben coincidir en porcentaje, exclusión de `REJECTED` y requisitos obligatorios/aplicables. Una actividad complementaria configurada sin contexto institucional sigue bloqueando la elegibilidad, como hoy.

### 3.3 Fechas y ventana operativa

La fecha de investidura y los extremos de la ventana son días civiles, sin hora. La ventana se configura por Campo Local y año eclesiástico en el panel. Su inicio y fin son inclusivos en `local_fields.timezone` y habilitan tanto presentar nuevas solicitudes/agregar personas como autorizar. La hora de los recordatorios es independiente de estas fechas.

| ID | Regla |
| --- | --- |
| IA-20 | La fecha es obligatoria. Quienes se marcan juntos salen con la misma fecha. |
| IA-21 | Al agregar más personas, se muestra la fecha anterior. Si se cambia en ese momento, el cambio vale solo para quienes se están agregando. |
| IA-22 | Se aceptan fechas futuras, de hoy y pasadas, si caen en la ventana del Campo y en el año eclesiástico en curso. |
| IA-23 | La ventana por defecto es del 1 de octubre al 20 de diciembre de ese año. Si alguna de esas fechas cae fuera de `ecclesiastical_years.start_date` / `end_date`, el valor por defecto se recorta al rango del año. |
| IA-24 | `director-lf` y `assistant-lf` del Campo, `admin` y `super-admin` pueden mover o ampliar los dos extremos según su alcance. No tienen que seguir en octubre–diciembre, pero sí dentro del año eclesiástico en curso. Unión y división sólo consultan. |
| IA-25 | Si un cambio de ventana deja una fecha pendiente afuera, hay que corregirla antes de autorizar. La corrección aplica una misma fecha válida a todas las personas pendientes seleccionadas. No modifica personas no seleccionadas ni quien ya está `INVESTIDO`. Pueden corregirla el director, el secretario o el secretario-tesorero de esa sección, o `super-admin`. |
| IA-26 | Aunque la fecha siga siendo válida, el director, el secretario o el secretario-tesorero de la sección pueden cambiarla para los pendientes seleccionados. El cambio aplica a todos los seleccionados, sin tocar a los demás ni a los `INVESTIDO`. La nueva fecha debe caer en el año y en la ventana vigentes. |
| IA-27 | Se puede presentar y autorizar dentro de la ventana operativa del Campo, hasta su último día incluido, mientras el año esté abierto. No existe un límite individual de siete días después de la fecha de investidura. Ejemplo: fecha de investidura 1 de noviembre y ventana hasta el 10 de diciembre; se puede autorizar hasta el 10 de diciembre. |
| IA-28 | Fuera de la ventana no se presentan solicitudes, no se agregan personas ni se autoriza. Si la ventana termina con pendientes, se puede ampliar dentro del mismo año para volver a operar. Los pendientes y sus recordatorios continúan; cambiar sólo la fecha individual no reabre la ventana. |
| IA-29 | Pasado el fin del año, o cerrado administrativamente ese año, no se modifica la fecha ni se autoriza. La ventana no puede superar `end_date` ni reabrir solicitudes de un año cerrado. |

El ejemplo de ventana del 1 de octubre al 10 de diciembre ilustra una configuración de un Campo; no reemplaza la preconfiguración de IA-23. Cada Campo puede ajustar su rango dentro del año.

`admin` y `super-admin` no obtienen permiso para autorizar por poder editar la ventana, ni dentro ni fuera de ella. `super-admin` conserva la edición del porcentaje cuando ya no puede el Campo y la corrección de fechas pendientes que quedaron fuera de la ventana. Cambiar la fecha individual ya no reinicia ningún plazo de siete días.

No se reutiliza `investiture_config.investiture_date` como fecha de estas personas. Esa fila sigue siendo la configuración vieja de una sola fecha por Campo y año.

### 3.4 Fin de año y año siguiente

| ID | Regla |
| --- | --- |
| IA-30 | Al terminar el año eclesiástico, cada registro pendiente se cierra como no investido de ese año. No se traslada, reinicia ni conserva como solicitud activa en el año siguiente. Se conserva el historial y no se muestra «Falta de requisitos para investidura» por este cierre. |
| IA-31 | Esa clase queda en el historial de la persona como no investida de ese año. No la repite. |
| IA-32 | Queda encaminada a la siguiente clase. Amigo pasa a Compañero. Al cerrar el año queda por inscribir (`member inactive`). Hasta que la directiva la inscriba al club, no ve ni hace lo de un miembro inscrito. Al inscribirla, entra en la clase siguiente. |
| IA-33 | No investir no bloquea esa continuidad. El modo anual ya omite la investidura de la clase inmediata anterior. |
| IA-34 | Al fin del año también se cierran las solicitudes abiertas de clases, carpetas, unidades y finanzas. Carpetas anuales e inscripciones de club al año ya se cierran en `YearEndService.closeYear`. El cierre concreto de solicitudes de unidades y finanzas queda fuera de la implementación de esta investidura: el acuerdo existe, su máquina de estados no. |
| IA-35 | La directiva ve, en una parte del club, un anuario: quiénes se inscribieron, de qué clase, cada año. No es un aviso. |

Las clases con `max_duration_years > 1` siguen devolviendo `ANNUAL_CLASS_POLICY_UNRESOLVED` en modo anual. Este plan no resuelve ese caso.

El cierre administrativo (`YearEndService.closeYear`) y el corte automático (`YearCutService`, invocado por `YearCutCronService`) son caminos distintos: el cron actual no llama a `closeYear`. Ambos deben integrar el cierre de solicitudes sin duplicar efectos. El corte y `AnnualMembershipPolicyService` mantienen la continuidad como no inscrito del nuevo año; cerrar solicitudes no debe sustituir esa política ni inscribir personas automáticamente. Aunque un proceso de cierre se retrase, las comprobaciones de fecha y año deben impedir nuevas autorizaciones fuera del año.

### 3.5 Correo y notificaciones

El correo sale al marcar un grupo y al agregar personas después. Usa el correo existente (`src/common/email/`).

| ID | Regla |
| --- | --- |
| IA-36 | Un correo por envío, no por persona. Destinatarios: los pastores del distrito y el director y el asistente del Campo. |
| IA-37 | Si la misma persona es pastor del distrito y `director-lf`, recibe dos correos, por separado. |
| IA-38 | El correo lleva el enlace a la solicitud en el panel, los nombres y, por persona, la fecha, la clase y la sección. |
| IA-39 | Agregar personas después manda otro correo, solo con las recién agregadas. |

Las notificaciones de resultado son in-app, por la bandeja existente (`src/notifications/`). No son correo. Llegan al director, al secretario y al secretario-tesorero de la sección de la solicitud, y a la persona. Si en un grupo hay investidos y rechazados, la directiva recibe dos notificaciones: una por cada resultado. Cada una lista a las personas de ese resultado y quién decidió. En un rechazo del sistema, quien decidió es el sistema.

Estos correos de presentación y las notificaciones de resultado son distintos de los recordatorios periódicos de la sección 3.7. Para los recordatorios se usa únicamente correo; no se necesita crear una bandeja personal de notificaciones en el panel.

### 3.6 Qué ve cada quien

| Dónde | Qué |
| --- | --- |
| Solicitud, directiva, app | Estado, fechas, clases y la sección propia. El comentario opcional de la autorización. El motivo humano de rechazo. El texto largo del sistema. Sin acceso a solicitudes de otras secciones. |
| Notificación de autorización | El texto alegre y los nombres. Sin el comentario. |
| Notificación de rechazo a la directiva | Los nombres y quién decidió. Sin el motivo humano. Si fue el sistema, con el texto largo. |
| Persona pendiente | «En espera de autorización.», la fecha y la clase. |
| Persona investida | La fecha, la clase y, en el estado, el comentario si existe. El comentario no va en la notificación. |
| Persona rechazada | La fecha, la clase y «Falta de requisitos para investidura». No ve el motivo humano ni el texto largo. |
| Persona, fin de año sin investir | Historial de esa clase como no investida. Sin el texto de falta de requisitos. |
| Panel, quien autoriza | Quién quedó investido, quién fue rechazado y el texto largo del sistema. |

### 3.7 Recordatorios de pendientes por correo

Todos se envían a las **10:00 a. m. en `local_fields.timezone`**, no a una hora UTC fija para todos los Campos.

| Destinatario | Frecuencia | Alcance |
| --- | --- | --- |
| Pastor asignado al distrito | Lunes, miércoles y viernes | Solicitudes pendientes de sus distritos asignados, dentro del Campo correspondiente. |
| `director-lf` y `assistant-lf` | Solo lunes | Un resumen semanal agrupado de todas las solicitudes pendientes de su Campo. |
| `admin` y `super-admin` | Ninguna | No reciben correos de recordatorio por esos roles. |

| ID | Regla |
| --- | --- |
| IA-42 | El canal de recordatorios es correo. No se agregan avisos periódicos a la bandeja del panel ni se cambian por esto las notificaciones de resultado de la app. |
| IA-43 | Los pastores reciben el recordatorio lunes, miércoles y viernes a las 10:00 a. m. en la zona del Campo, con sus solicitudes pendientes de autorización. |
| IA-44 | El director y el asistente del Campo reciben solo el lunes a las 10:00 a. m. un resumen de todos los pendientes acumulados. El corte del lunes anterior organiza la periodicidad, no excluye solicitudes antiguas: una solicitud pendiente desde hace dos semanas vuelve a aparecer hasta resolverse o cerrar el año. |
| IA-45 | No se envían recordatorios a `admin` ni a `super-admin` por esos roles. Tampoco se incorpora a unión o división como destinatarios. Esto no cambia los destinatarios de otros correos del sistema. |
| IA-46 | El correo informa cuántas solicitudes siguen pendientes y permite abrirlas en el panel. Una solicitud parcialmente resuelta cuenta como pendiente mientras tenga al menos una persona pendiente; las personas ya resueltas no se presentan como pendientes de validar. Se respeta el alcance territorial del destinatario. |
| IA-47 | Si termina la ventana y aún quedan pendientes, los recordatorios continúan con la misma frecuencia. Deben indicar que la ventana está cerrada y que es necesario ampliarla para autorizar, siempre dentro del año. El pastor solicita esa ampliación al Campo; el recordatorio no le concede permisos para editarla. |
| IA-48 | Sin solicitudes pendientes no se envía recordatorio. Al terminar o cerrarse administrativamente el año, cesan los recordatorios de esas solicitudes aunque el proceso de cierre todavía esté pendiente de ejecución. No se arrastran al año siguiente. |
| IA-49 | El envío debe admitir reintentos sin duplicar un mismo recordatorio programado. Antes de enviarlo se vuelve a comprobar el alcance, el año y los pendientes. Esta protección técnica no cambia la regla de dos correos iniciales por rol de IA-37. |

### 3.8 Orden de requisitos y controles

1. **Preparar el año:** configurar porcentaje, ventana y zona horaria del Campo; asignar los pastores de cada distrito. Verificar permisos de lectura y edición de la configuración.
2. **Seleccionar personas:** comprobar la sección del directivo, la inscripción válida, la clase, la duración, el progreso y la ausencia de una solicitud activa incompatible o de una investidura ya obtenida en esa clase.
3. **Presentar:** validar que el año y la ventana estén abiertos y que la fecha de investidura sea válida. Crear los registros pendientes, bloquear su progreso y registrar la auditoría; después emitir el correo del grupo confirmado.
4. **Resolver:** comprobar nuevamente actor, territorio, estado pendiente, año, ventana, fecha, progreso y duración. Confirmar cada resultado de manera atómica con su enrollment y auditoría; emitir las notificaciones solo por resultados confirmados.
5. **Dar seguimiento:** enviar los recordatorios según rol, incluyendo pendientes acumulados. El vencimiento de la ventana no equivale al cierre anual.
6. **Cerrar el año:** cerrar definitivamente los pendientes como no investidos, conservar el historial y detener sus recordatorios, sin alterar la política anual de inscripción y continuidad.

## 4. Textos cerrados

| Uso | Texto |
| --- | --- |
| Panel y directiva, rechazo del sistema | Al comprobar el avance, esta persona no cubría los requisitos mínimos. Revisar sus evidencias de avance. |
| Persona, cualquier rechazo | Falta de requisitos para investidura. |
| Persona, notificación de investidura | El camino rindió fruto. Ya estás investido, y esta noticia es para celebrarla. |
| Directiva, notificación de autorización | Llegó una buena noticia: la investidura fue autorizada. Celebramos con estas personas: {nombres}. Autorizó: {quien}. |
| Persona pendiente | En espera de autorización. |

## 5. Qué hay hoy y qué no se reutiliza

El pipeline operativo actual sigue en `sacdia-backend/src/investiture/`:

- `POST /investiture/enrollments/:enrollmentId/submit`
- `POST /investiture/enrollments/:enrollmentId/club-approve`
- `POST /investiture/enrollments/:enrollmentId/coordinator-approve`
- `POST /investiture/enrollments/:enrollmentId/field-approve`
- `POST /investiture/enrollments/:enrollmentId/invest`
- `POST /investiture/enrollments/:enrollmentId/reject`

`markInvestido` exige `FIELD_APPROVED` y copia `investiture_config.investiture_date`. Este plan no pasa por esos estados. `INVESTIDO` operativo sale solo de IA-10, después de IA-08 e IA-09.

`is_late` en el envío actual no bloquea. No se trae a este flujo.

La app ya tiene pendientes, envío e historial en `sacdia-app/lib/features/investiture/`. El admin ya tiene `sacdia-admin/src/components/investiture/`. Esas pantallas siguen el pipeline viejo. Hay que sustituir la operación, no pintar la solicitud nueva encima del pipeline.

Los certificados históricos (`enrollment_record_kind = HISTORICAL_CERTIFICATE`) no entran en esta solicitud.

## 6. Datos nuevos

Estas piezas requieren diseño e implementación para el flujo nuevo. Sus nombres son conceptuales, no nombres definitivos de tablas ni un contrato de schema. Se reutilizan las entidades y mecanismos existentes cuando corresponda.

| Pieza | Contenido |
| --- | --- |
| Cupos de pastor | Un entero global. Valor inicial 2. Lo cambia `super-admin`. |
| Asignación pastor–distrito | Usuario, `districlub_type_id`, cupo. Como máximo, los cupos configurados. La asignan Campo y unión, según la sección 2. |
| Porcentaje del Campo | `local_field_id`, `ecclesiastical_year_id`, porcentaje. Al crear el año, 80. |
| Ventana del Campo | `local_field_id`, `ecclesiastical_year_id`, inicio y fin inclusivos. Habilita presentación y autorización. Por defecto, IA-23. Lectura y edición según la sección 2. |
| Solicitud | Una sección, su club, año eclesiástico, quién la creó y cuándo. Puede agrupar clases distintas, pero nunca secciones distintas. |
| Persona en la solicitud | Persona, clase y enrollment asociado, fecha, estado pendiente / investido / rechazado por persona / rechazado por sistema / quitado / cerrado por fin de año. Quién autorizó o rechazó, cuándo, comentario opcional, motivo humano, motivo del sistema. |
| Seguimiento de envíos | Identidad de la ejecución programada y su destinatario/alcance, estado de envío y reintentos; permite evitar duplicados sin perder recordatorios ante fallos. La solución concreta se define en el diseño técnico. |

El estado de la persona en la solicitud no reemplaza el enum `investiture_status_enum` con una cadena paralela de club, coordinación y campo. Al autorizar, el enrollment pasa a `INVESTIDO`. Un rechazo o retiro libera el bloqueo de solicitud de ese enrollment, no los bloqueos de año cerrado o estado terminal. Permite corregir y volver a marcar si sigue siendo elegible. El fin de año no lo pasa a `INVESTIDO` ni lo marca con el texto de falta de requisitos.

Las restricciones de solicitudes activas deben resistir altas simultáneas, no depender solo del selector de la app. El bloqueo pertenece al enrollment, nunca a todas las clases de una persona. No se amplían los cupos de inscripción operativa vigentes: la excepción GM solo aprovecha inscripciones simultáneas que el sistema ya permite.

## 7. Implementación

Esta actualización es únicamente documental: las fases siguientes son trabajo futuro. Cada fase se implementará con pruebas antes de pasar a la siguiente, sin ejecutar builds salvo solicitud explícita del usuario. No se implementa el documento del 2026-09-21.

### Fase 0 — Contratos y diseño técnico

Definir primero los contratos backend de solicitud, selección de personas, cambio de fecha, resolución y configuración: DTOs, estados, permisos por acción, alcance territorial, errores de negocio y concurrencia. Definir la consistencia entre registro, enrollment, auditoría y envío de comunicaciones. No asumir endpoints nuevos a partir de los del pipeline anterior.

**Validaciones:** matriz de permisos de la sección 2; transición desde cada estado; selección de una sola sección; protección de solicitudes activas simultáneas; cierre manual y automático idempotente. Documentar el contrato antes de integrarlo en app y panel. El ajuste del admin es funcional y de integración, no un rediseño visual.

### Fase 1 — Porcentaje del Campo

**Archivos:** `sacdia-backend/src/classes/class-requirement-eligibility.service.ts`, `sacdia-backend/src/classes/classes.service.ts`, `sacdia-backend/src/classes/class-progress-scope.service.ts`, configuración nueva por Campo y año. No tocar el 70 de `sacdia-backend/src/clubs/clubs.service.ts`.

**Pruebas:** sin configuración, el requisito cuenta desde 80. Con 90, un 85 no cuenta. `VALIDATED` cuenta aunque el puntaje sea menor. `REJECTED` no cuenta, aunque tenga puntaje alto. `ADVANCED` no bloquea. Detalle individual, listado colectivo y elegibilidad usan el mismo criterio para `BASIC` y los requisitos `EXTRA` obligatorios/aplicables; una actividad complementaria sin contexto institucional mantiene el bloqueo existente. Hasta el 30 de junio 23:59 en la zona del Campo, `director-lf` y `assistant-lf` cambian el valor. Después, solo `super-admin`. La nota B sigue en 70.

### Fase 2 — Ventana de fechas

**Archivos:** configuración nueva junto a la del porcentaje. Zona: `LocalFieldTimezoneResolver` / `local_fields.timezone`.

**Pruebas:** el año nuevo nace del 1 de octubre al 20 de diciembre, recortado al rango del año. Se rechazan extremos fuera del año o un inicio posterior al fin. `director-lf`, `assistant-lf`, `admin` y `super-admin` pueden editar según su alcance. Unión y división consultan sus Campos, pero no editan, tampoco mediante llamadas directas a la API. No se leen ni editan Campos ajenos al alcance. El inicio y el último día son inclusivos según la zona local. La misma ventana bloquea presentación, adiciones y autorización fuera de rango. Editarla no otorga permiso de autorización ni de edición del porcentaje.

### Fase 3 — Pastores del distrito

**Archivos:** schema nuevo, asignación desde Campo y unión, lectura para saber quién autoriza.

**Pruebas:** el cupo global arranca en 2. `super-admin` lo cambia y el tope vale para todos los distritos. Asignan `director-lf`, `assistant-lf`, `director-union` y `assistant-union`, solo dentro de su alcance territorial. No se asigna un pastor de más. Los dos cupos quedan habilitados para autorizar. El distrito se resuelve por iglesia del club, no por un dato suelto del usuario.

### Fase 4 — Marcar, quitar y fecha en la app

**Archivos:** módulo nuevo de solicitud en `sacdia-backend/src/investiture/` o un módulo hermano. App: flujo nuevo en `sacdia-app/lib/features/investiture/`, sin reutilizar el envío a validación como si fuera esta solicitud.

**Pruebas:**

- Sin progreso o sin duración mínima, no entra.
- La solicitud, su lectura y sus acciones pertenecen a una sola sección. Mezclar secciones o acceder a otra sección del mismo club se rechaza en backend.
- Aventureros o Conquistadores con una solicitud activa no entran a otra.
- Un Guía Mayor, incluido el ya investido de GM que cursa AV/CQ, entra a otra solicitud si la clase es distinta y sus inscripciones son válidas. No se permiten dos activas de la misma persona y clase ni se amplían los límites de inscripción existentes.
- Dos altas simultáneas no crean solicitudes activas incompatibles.
- Quien ya está `INVESTIDO` en esa clase no entra, y una solicitud pendiente de esa clase deja de poder autorizarse.
- Quitar o rechazar a un pendiente lo saca de la solicitud activa y permite corregir y volver a marcar dentro de ventana y año abiertos.
- Mientras está pendiente, no se cambia el progreso ni las evidencias de ese enrollment por ninguna ruta de escritura. Otra clase válida de la misma persona no queda bloqueada.
- Quitar o rechazar libera solo el bloqueo de solicitud; no habilita escrituras sobre `EXPIRED`, `INVESTIDO` o un año cerrado.
- El subdirector recibe 403 al marcar, quitar, cambiar fecha o leer la solicitud.
- La fecha fuera de la ventana o del año se rechaza.
- No se presentan ni se agregan personas si el día actual queda fuera de la ventana, aunque la fecha de investidura sí sea válida.
- Agregar con otra fecha no reescribe a quienes ya estaban.
- Cambiar o corregir fecha aplica una misma fecha válida a todos los pendientes seleccionados, aunque antes tuvieran fechas distintas. No cambia a los no seleccionados ni a los `INVESTIDO`.
- Una persona resuelta concurrentemente no vuelve a pendiente ni cambia de fecha por una selección desactualizada.

### Fase 5 — Autorizar en el panel

**Archivos:** resolución del flujo nuevo en `sacdia-backend/src/investiture/` o módulo hermano; integración admin en `sacdia-admin/src/components/investiture/`, separada de `investiture-client-page.tsx` del pipeline viejo. El enlace del correo abre esta solicitud.

**Pruebas:**

- Autoriza un pastor del distrito, `director-lf` o `assistant-lf`. Otro rol, incluidos `admin`, `super-admin`, unión y división, no autoriza por esos roles. Se rechaza también a un autorizador de otro territorio.
- Se autoriza desde el inicio hasta el último día de la ventana, inclusive, en la zona del Campo. Antes o después, no.
- Una fecha de investidura del 1 de noviembre puede autorizarse el 10 de diciembre si ese día está incluido en la ventana; no existe un límite individual de siete días.
- Ampliar la ventana dentro del mismo año permite resolver pendientes. Cambiar solo la fecha de investidura no reabre una ventana cerrada.
- Si la fecha de una persona quedó fuera de la ventana por una modificación, debe corregirse antes de autorizarla.
- Con el año cerrado, no autoriza y no cambia la fecha.
- Pasado `end_date`, no autoriza aunque el cron de cierre se haya retrasado. Ninguna ampliación puede superar ese límite.
- Una persona que dejó de cumplir queda rechazada por el sistema, con el texto largo. Las demás pueden quedar `INVESTIDO`.
- Rechazo humano sin motivo se rechaza. El comentario de autorización puede ir vacío.
- Unos quedan investidos y otros pendientes en la misma solicitud.
- El enrollment autorizado queda `INVESTIDO` sin pasar por `FIELD_APPROVED`.
- Ante autorización/rechazo simultáneos gana la primera decisión confirmada; la otra recibe aviso de resolución previa. También se protege la carrera con retiro y cierre anual.
- Fallar antes de confirmar no deja el registro, el enrollment y la auditoría en estados distintos. Reintentar una decisión confirmada no duplica efectos ni comunicaciones.

### Fase 6 — Correos, resultados y recordatorios

**Archivos:** `sacdia-backend/src/common/email/`, `sacdia-backend/src/notifications/`, tarea programada y seguimiento de envíos del nuevo flujo. Reutilizar el envío existente; definir el mecanismo de programación y reintentos sin asumir que ya hay una bandeja personal en el panel.

**Pruebas de presentación y resultado:** un envío produce un correo por destinatario y rol, no por persona. Pastor y director del Campo en la misma cuenta producen dos correos iniciales. El segundo envío lista solo a los nuevos. Quitar no manda correo. La directiva de la sección recibe una notificación por resultado, con los textos de la sección 4; las otras secciones no. La persona investida recibe el texto alegre. La rechazada recibe solo «Falta de requisitos para investidura». El motivo humano sigue privado en la solicitud para la directiva. El subdirector no recibe esas notificaciones.

**Pruebas de recordatorios:**

- Pastor: lunes, miércoles y viernes. Campo: solo lunes. Todos a las 10:00 a. m. locales, con casos de Campos en distintas zonas horarias.
- El resumen del Campo agrupa todo su pendiente acumulado: una solicitud de hace dos semanas aparece en ambos lunes si sigue pendiente. No filtrar solo por fecha de creación desde el último corte.
- Una solicitud parcialmente resuelta cuenta una vez y muestra como accionables solo las personas pendientes.
- Solo se incluyen solicitudes del distrito o Campo del destinatario. No se envían correos a `admin` ni a `super-admin` por esos roles.
- Con ventana cerrada continúan y avisan que hace falta ampliarla; no habilitan autorización fuera de ventana.
- Sin pendientes, con año cerrado o después de `end_date`, no se envían. Se vuelven a comprobar estas condiciones antes del envío, incluidos los reintentos.
- Reejecutar la misma ejecución programada no duplica el recordatorio; un fallo de envío puede reintentarse sin perderlo.
- No se generan notificaciones periódicas en el panel. Las notificaciones de resultado de la app siguen funcionando.

### Fase 7 — Historial, anuario y fin de año

**Archivos:** `sacdia-backend/src/year-end/year-end.service.ts`, `sacdia-backend/src/year-cut/year-cut.service.ts`, `sacdia-backend/src/year-cut/year-cut-cron.service.ts`, integración con la política anual existente, historial de la app y vista de anuario del club en la app.

**Pruebas:** tanto el cierre administrativo como el corte automático cierran los registros pendientes como no investidos de ese año. Ejecutarlos de nuevo o ejecutar ambos no duplica efectos ni cambia a quienes ya estaban investidos. No se copian ni reabren solicitudes en el año siguiente. El historial conserva clase y año, sin el texto de falta de requisitos. Cesan los recordatorios del año cerrado. La continuidad anual deja a la persona por inscribir y, al inscribirla, en la clase siguiente, sin exigir la investidura anterior; no se sustituye esa política por un alta automática. El anuario lista inscripciones por clase y por año para la directiva dentro de su sección. Esta fase no cierra la máquina de estados de unidades ni de finanzas.

### Fase 8 — Apagar la vía vieja

Dejar de aceptar transiciones nuevas del pipeline club → coordinación → campo hacia `INVESTIDO`. Conservar la lectura del historial ya grabado y los certificados históricos. Quitar de la app y del admin las acciones que envían, aprueban o invisten por esa vía. Cubrir también aliases de enrollments (`submit-for-validation`, `validate`, `investiture`) y operaciones masivas: no pueden quedar rutas alternativas que eludan el flujo nuevo.

**Condición de despliegue:** inventariar los expedientes del pipeline anterior antes de retirarlo. La regla de no arrastre entre años está cerrada; no equivale a haber aprobado una conversión o un reinicio masivo de expedientes del mismo año. Si existen pendientes de ese año en producción, documentar y aprobar su tratamiento antes del cambio de vía, sin perder historia ni desbloquear duplicados.

**Pruebas:** un enrollment operativo nuevo no llega a `INVESTIDO` por `markInvestido`, `FIELD_APPROVED`, un alias ni una operación masiva del pipeline retirado. Un historial viejo sigue leyéndose. Un certificado histórico no se mezcla con la solicitud. No se pierde ni se resuelve silenciosamente un expediente anterior pendiente durante el despliegue.

### Fase 9 — Documentación

Actualizar los contratos antes de integrar consumidores y mantener la documentación sincronizada en cada fase. Al cerrar la implementación, revisar en el mismo trabajo:

- `docs/features/validacion-investiduras.md`
- `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- `docs/api/FRONTEND-INTEGRATION-GUIDE.md`
- `docs/database/SCHEMA-REFERENCE.md` y `docs/database/schema.prisma`
- `docs/features/clases-progresivas.md`, por el porcentaje 80 y la continuidad sin investidura previa
- `docs/features/communications.md`, por los recordatorios de investidura y su diferencia frente a las notificaciones de resultado
- `docs/guides/conocimiento-sistema/07-inscripcion-anual.md`, para documentar el cierre de pendientes sin arrastre y su integración con la continuidad anual existente, sin cambiar el comportamiento de por inscribir

## 8. Fuera de este plan

- Implementar el documento de ceremonia colectiva del 2026-09-21.
- Lugar, oficiante, certificador, hora de inicio y hora de fin de la ceremonia. Esto no excluye el horario de los recordatorios.
- Plazo de N días antes de la fecha para poder autorizar.
- Plazo individual de siete días después de la fecha: lo reemplaza la ventana operativa del Campo.
- Solicitudes que mezclen secciones o acceso de la directiva a solicitudes de otra sección.
- Ampliar el número o tipo de inscripciones simultáneas permitidas para Guías Mayores.
- Crear notificaciones periódicas o una bandeja personal nueva en el panel para estos recordatorios.
- Enviar recordatorios a `admin` o `super-admin` por esos roles.
- Trasladar o reabrir solicitudes pendientes en el año siguiente.
- Definir cómo se cierran, estado por estado, las solicitudes de unidades y de finanzas.
- Resolver `ANNUAL_CLASS_POLICY_UNRESOLVED` para clases de más de un año.
- Marcar o autorizar desde la superficie que este plan no asigna. Marcar sigue solo en la app. Autorizar sigue solo en el panel.
