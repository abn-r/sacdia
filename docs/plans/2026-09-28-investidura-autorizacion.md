# Investidura por autorización — plan funcional

> **Estado real (revisado 2026-10-04 contra `development`)**: Implementación: Pendiente de merge (PR #448 de sacdia-backend, rama `feat/investiture-authorization-ocr`, commit `113d8ba`). En `development` no existen todavía las tablas `local_field_class_thresholds`, `investiture_windows`, `district_investiture_pastors` ni `authorization_requests`; la vía vigente para llegar a `INVESTIDO` sigue siendo el pipeline club → coordinación → campo.


> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** El directivo de la sección marca en la app a quienes cumplen, y un pastor del distrito o el Campo Local los autoriza en el panel dentro de la ventana configurada. `INVESTIDO` solo existe después de esa autorización.

**Architecture:** Una solicitud pertenece a una sola sección y agrupa el envío y el correo. El resultado y el bloqueo de progreso son por persona y por clase. La ventana del Campo gobierna la presentación y la autorización; los recordatorios por correo tienen frecuencia según el rol. El pipeline actual club → coordinación → campo deja de ser la vía operativa para llegar a `INVESTIDO`. Se conserva el historial de certificados ya registrado; las nuevas acreditaciones de clases deben validar la edad histórica antes de aceptarse.

**Tech Stack:** NestJS, Prisma, PostgreSQL, Next.js admin, Flutter app, correo Resend, bandeja de notificaciones existente.

- **Estado:** acuerdo funcional del 2026-09-28, actualizado con las decisiones de revisión hasta el 2026-10-01. Implementación parcial; ver los informes de implementación y revisión independiente en `docs/reviews/`. W1 fue corregido y cerrado en revisión independiente; la fase 2 continúa parcial y el cambio de vía y despliegue siguen bloqueados.
- **Cambios de esta revisión:** solicitud de una sola sección; fechas sobre personas seleccionadas; excepción GM por clase sin ampliar inscripciones; bloqueo de progreso y resolución concurrente; ventana operativa sin plazo individual de siete días; permisos de consulta/edición de fechas; cierre anual sin arrastre; recordatorios acumulativos y separados por rol; logros al confirmar la investidura; validación preventiva de edad histórica en certificados de clases.
- **Reemplaza:** `docs/history/plans/2026-09-21-investiture-ceremony-functional-design.md` para este alcance. Ese documento no se implementa.
- **No es contrato runtime.** Al implementar hay que actualizar `docs/features/validacion-investiduras.md`, `docs/api/` y `docs/database/`.

## 1. Decisión central

El director, el secretario o el secretario-tesorero eligen una o varias personas dentro del alcance de su sección y las dejan pendientes. No pueden operar solicitudes de otra sección, aunque pertenezca al mismo club. Pasan a `INVESTIDO` solo cuando autoriza una de estas personas: un pastor asignado al distrito del club, el director del Campo (`director-lf`) o el asistente del Campo (`assistant-lf`). Basta una.

Se guarda quién autorizó. No hay lugar. No hay quien certifica. No hay oficiante. No hay plazo de X días antes de la fecha.

Marcar, quitar, corregir la fecha y ver la solicitud es en la app, de momento. Autorizar y rechazar se hace en el panel y, por decisión del 2026-10-08, también en la app. El enlace del correo abre esa solicitud en el panel.

**Decisión del 2026-10-08 — acceso del pastor.** Aunque `pastor` es un rol global sin club, el pastor puede iniciar sesión en el panel y en la app. En el panel ve, de momento, solo la pantalla para autorizar las solicitudes de sus distritos. En la app ve esa pantalla y su perfil. Qué más ve el pastor se define después. El `director-lf` y el `assistant-lf` conservan su acceso actual y también pueden autorizar desde la app. El backend no cambia: la autorización ya valida actor y territorio en `POST /investiture-requests/:requestId/resolutions`.

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

**Decisión del 2026-10-08 — un pastor solo se asigna a un distrito de su propio Campo.** `POST /districts/:districtId/investiture-pastors` exige que `users.local_field_id` del pastor sea igual al `local_field_id` del distrito. Un pastor de otro Campo, aunque sea de la misma unión, o sin Campo, se rechaza con 400 `INVESTITURE_PASTOR_FIELD_MISMATCH`. La regla se evalúa dentro de la transacción, después de los candados y del rol, y también al reactivar una asignación inactiva. `director-union` y `assistant-union` siguen asignando en cualquier distrito de su unión, pero solo pastores del Campo de ese distrito. La búsqueda `GET /investiture-pastor-candidates` acepta `districtId` opcional para devolver solo los pastores del Campo de ese distrito. Las asignaciones activas que ya existían no se tocan.

**Decisión del 2026-10-08 — si el pastor cambia de Campo, deja de contar.** Cuando `users.local_field_id` de un pastor cambia (a otro Campo o a nulo, como hace la eliminación de cuenta), sus asignaciones activas a distritos de otro Campo pasan a `active = false`; lo mismo ocurre con las asignaciones de otro Campo cuando un distrito pasa a otro Campo (`districts.local_field_id`). El distrito debe recibir un pastor nuevo; mientras tanto autorizan el `director-lf` y el `assistant-lf` del Campo (`fieldAuthorizesSection`, sin cambios). Como `users.local_field_id` se escribe desde varios caminos (`users`, `admin-users` con importación masiva, `post-registration`, `account-deletion`), la regla vive en la base de datos: dos triggers `AFTER UPDATE OF local_field_id` (en `users` y en `districts`) en la migración `20261008120000_district_pastor_field_change`, que además desactiva una sola vez las filas activas que ya cruzaban Campos. Solo se apaga `active`: no se borra nada y el cupo se libera porque cuenta filas activas. Reactivar sigue regido por `INVESTITURE_PASTOR_FIELD_MISMATCH` en la asignación. Esta decisión sustituye la frase anterior «las asignaciones activas que ya existían no se tocan».

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
| IA-23 | La ventana por defecto es del 1 de octubre al 20 de diciembre de ese año, recortada a `ecclesiastical_years.start_date` / `end_date`. Si no hay intersección y no existe configuración explícita válida, la ventana permanece cerrada: no se permite presentar, agregar personas ni autorizar. No se sustituye el período vacío por todo el año. Un editor autorizado según IA-24 puede configurar un rango válido dentro del año en curso; siguen aplicando IA-27 e IA-29. |
| IA-24 | `director-lf` y `assistant-lf` del Campo, `admin` y `super-admin` pueden mover o ampliar los dos extremos según su alcance. No tienen que seguir en octubre–diciembre, pero sí dentro del año eclesiástico en curso. Unión y división sólo consultan. |
| IA-25 | Si un cambio de ventana deja una fecha pendiente afuera, hay que corregirla antes de autorizar. La corrección aplica una misma fecha válida a todas las personas pendientes seleccionadas. No modifica personas no seleccionadas ni quien ya está `INVESTIDO`. Pueden corregirla el director, el secretario o el secretario-tesorero de esa sección, o `super-admin`. |
| IA-26 | Aunque la fecha siga siendo válida, el director, el secretario o el secretario-tesorero de la sección pueden cambiarla para los pendientes seleccionados. El cambio aplica a todos los seleccionados, sin tocar a los demás ni a los `INVESTIDO`. La nueva fecha debe caer en el año y en la ventana vigentes. |
| IA-27 | Se puede presentar y autorizar dentro de la ventana operativa del Campo, hasta su último día incluido, mientras el año esté abierto. No existe un límite individual de siete días después de la fecha de investidura. Ejemplo: fecha de investidura 1 de noviembre y ventana hasta el 10 de diciembre; se puede autorizar hasta el 10 de diciembre. |
| IA-28 | Fuera de la ventana no se presentan solicitudes, no se agregan personas ni se autoriza. Si la ventana termina con pendientes, se puede ampliar dentro del mismo año para volver a operar. Los pendientes y sus recordatorios continúan; cambiar sólo la fecha individual no reabre la ventana. |
| IA-29 | Pasado el fin del año, o cerrado administrativamente ese año, no se modifica la fecha ni se autoriza. La ventana no puede superar `end_date` ni reabrir solicitudes de un año cerrado. |

El ejemplo de ventana del 1 de octubre al 10 de diciembre ilustra una configuración de un Campo; no reemplaza la preconfiguración de IA-23. Cada Campo puede ajustar su rango dentro del año.

**Aclaración aprobada el 2026-10-01 (W1):** si el año eclesiástico va del 1 de enero al 30 de junio, no intersecta el período predeterminado de octubre–diciembre. Sin configuración explícita, la lectura debe comunicar que no hay ventana operativa y que hace falta configurarla, sin insertar una fila ni inventar fechas de apertura. Configurarla no habilita días fuera del rango guardado ni reabre un año terminado o cerrado. La corrección del backend fue verificada independientemente y W1 está cerrado en el árbol de trabajo sin commit. No cierra la fase 2, no autoriza despliegue y no apaga el pipeline anterior.

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

| ID | Regla |
| --- | --- |
| IA-51 | La evaluación y concesión de logros asociada a la investidura ocurre únicamente después de confirmar la autorización y el cambio a `INVESTIDO`, nunca al presentar la solicitud. Se conserva el evento existente `class.completed` y sus criterios de logros, sin crear logros nuevos ni duplicar efectos por reintentos. Un rechazo, retiro, cierre anual o transacción fallida no concede el logro de investidura. |

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
| IA-49 | El envío debe admitir reintentos sin duplicar un mismo recordatorio programado para el mismo destinatario, rol y alcance. Antes de enviarlo se vuelve a comprobar el alcance, el año y los pendientes. Esta protección técnica no fusiona correos de roles distintos ni cambia los dos correos iniciales de IA-37. |
| IA-50 | Una persona que sea pastor y director o asistente del Campo recibe dos recordatorios separados el lunes, uno por cada rol, si existen pendientes en ambos alcances. Miércoles y viernes recibe solo el pastoral. Compartir cuenta o dirección de correo no elimina un rol destinatario; `admin` y `super-admin` siguen sin recibir recordatorios por esos roles. |

**Decisiones del 2026-10-07 (cierre del backend):**

- **Recordatorio perdido:** si la ejecución de las 10:00 no ocurre porque el servicio no estaba disponible, el recordatorio sale en la primera ejecución disponible del **mismo día local** (hasta las 23:59), una sola vez. Nunca se recupera al día siguiente. Los reintentos por fallo también valen solo dentro de ese día.
- **Pastor sin rol global `pastor`:** su asignación sigue ocupando cupo hasta que el Campo o la unión la quiten, pero no autoriza, no figura entre los autorizadores y no recibe correos ni recordatorios.
- **Avisos de resultado (§3.5):** la directiva recibe como máximo dos avisos por decisión: uno de investidos y uno de rechazados. El de rechazados junta los rechazos del pastor o del Campo y los del sistema, e indica quién decidió en cada caso, sin el motivo humano.

### 3.8 Orden de requisitos y controles

1. **Preparar el año:** configurar porcentaje, ventana y zona horaria del Campo; asignar los pastores de cada distrito. Verificar permisos de lectura y edición de la configuración.
2. **Seleccionar personas:** comprobar la sección del directivo, la inscripción válida, la clase, la duración, el progreso y la ausencia de una solicitud activa incompatible o de una investidura ya obtenida en esa clase.
3. **Presentar:** validar que el año y la ventana estén abiertos y que la fecha de investidura sea válida. Crear los registros pendientes, bloquear su progreso y registrar la auditoría; después emitir el correo del grupo confirmado.
4. **Resolver:** comprobar nuevamente actor, territorio, estado pendiente, año, ventana, fecha, progreso y duración. Confirmar cada resultado de manera atómica con su enrollment y auditoría; emitir las notificaciones solo por resultados confirmados.
5. **Dar seguimiento:** enviar los recordatorios según rol, incluyendo pendientes acumulados. El vencimiento de la ventana no equivale al cierre anual.
6. **Cerrar el año:** cerrar definitivamente los pendientes como no investidos, conservar el historial y detener sus recordatorios, sin alterar la política anual de inscripción y continuidad.

### 3.9 Prevención de certificados incompatibles con la edad

Los certificados de clases son una vía de acreditación histórica distinta de la solicitud operativa, pero no pueden aceptar una clase que la persona todavía no podía cursar por edad en el año acreditado. La validación debe prevenir el dato inconsistente, no aceptarlo y después cerrar la solicitud actual para ocultar el conflicto.

| ID | Regla |
| --- | --- |
| IA-52 | Para acreditar un certificado de clase se resuelve el año eclesiástico de su fecha de realización y se calcula la edad con la fecha de nacimiento completa al inicio de ese año, usando el mismo criterio temporal del postregistro. Debe alcanzar la edad mínima de esa clase en el catálogo. No basta la edad actual ni restar únicamente los números de año. |
| IA-53 | El backend valida al confirmar los datos del ítem como listo para enviar, al enviar o reenviar el lote y nuevamente al aprobar cada ítem de clase, incluidas las aprobaciones masivas. Se reutiliza un criterio compartido; una llamada directa a la API, un reintento o datos modificados después del envío no pueden omitirlo. |
| IA-54 | Sin fecha de nacimiento válida, edad mínima definida o un año eclesiástico inequívoco para la fecha del certificado, no se acepta el ítem para validación ni se acredita. El error debe indicar qué dato falta o por qué la edad no corresponde; no se presume una edad ni se acepta por omisión. Se conservan las comprobaciones existentes de fecha futura, catálogo, permisos y reconciliación. |
| IA-55 | Subir el archivo o extraerlo por OCR no equivale a aceptar sus datos: un ítem incompatible puede conservarse como borrador para corregirlo, pero no quedar listo, enviarse ni aprobarse. Un fallo de esta validación no crea un enrollment `INVESTIDO`, no reconcilia ni modifica el enrollment operativo o su solicitud pendiente, y no emite eventos ni concede logros de acreditación. |
| IA-56 | Se compara la edad histórica con el mínimo de la clase acreditada; no se exige que sea la clase que hoy correspondería por edad ni se introduce una edad máxima. Tampoco se impone una prohibición general por coincidir con una inscripción actual: los casos compatibles siguen las reglas existentes de reconciliación y Guías Mayores. Esta validación no borra ni reescribe certificados ya acreditados; cualquier inconsistencia previa requiere inventario y tratamiento aprobado. |

**Decisiones del 2026-10-07 — certificado frente a solicitud viva.** La edad histórica (IA-52) no distingue dos casos en los que la edad sí cuadra: un certificado del mismo año eclesiástico en curso, y un Guía Mayor adulto con un certificado de años anteriores. Para esos casos rigen IA-57 a IA-60.

| ID | Regla |
| --- | --- |
| IA-57 | Un certificado de clase cuyo año eclesiástico es el año en curso de una inscripción operativa con un registro `PENDING` de esa misma persona y clase se rechaza. En el año en curso manda la autorización. Si el pastor o el Campo rechazan a la persona, o la directiva la quita, el certificado puede volver a presentarse y se evalúa con IA-58. |
| IA-58 | Un certificado del año en curso sin solicitud vigente de esa persona y clase se acepta con las reglas existentes de edad, catálogo, reconciliación y permisos. Lo aprueban los roles que ya aprueban certificados; esta regla no cambia esos roles. Si se rechaza y el año termina sin investidura, la clase queda no investida de ese año. |
| IA-59 | Un certificado de un año anterior para una persona y clase con un registro `PENDING` se acepta si cumple las demás reglas. En la misma transacción ese registro se cierra como no activo con un motivo informativo («Investidura aplicada por certificado de un año anterior»), distinto de un rechazo. No usa el texto de falta de requisitos, no emite `class.completed` desde la solicitud, sale de los recordatorios y queda visible para quienes autorizan y para la directiva de la sección. |
| IA-61 | Decisión del 2026-10-07. Si la solicitud de una persona y clase terminó sin autorización porque el año eclesiástico de esa solicitud ya terminó (registro `CLOSED_YEAR`, o `PENDING` de un año terminado), un certificado de ese mismo año puede acreditarse con la aprobación de `director-lf` o `assistant-lf` del Campo de esa solicitud, o de `admin`, `assistant-admin` o `super-admin` dentro de su alcance; basta uno. Un Campo ajeno no lo aprueba. Cubre la omisión de un pastor que nunca validó: el Campo y la administración son autoridad superior al pastor. El registro de la solicitud conserva `CLOSED_YEAR` como auditoría y las lecturas indican que la investidura de ese año se acreditó después por certificado validado por el Campo. No es el camino ordinario y puede retirarse si la iglesia lo decide. Mientras el año sigue en curso rige IA-57. |
| IA-62 | Decisión del 2026-10-07. Las clases institucionales de legado (`GM-02`, `GM-03`) no admiten solicitudes de investidura: son solo reconocimiento y su acreditación sigue por la vía institucional de certificados. Presentar o agregar una de esas clases se rechaza. Se reconsidera solo si la iglesia lo solicita. |
| IA-60 | La comprobación de IA-57 e IA-59 corre al aprobar, dentro de la transacción y bajo los mismos candados de usuario y enrollment que usan la solicitud y la resolución, para que no exista una carrera entre presentar, autorizar y aprobar el certificado. |

**Ejemplo de regresión:** nacimiento el 1 de enero de 2016, clase Amigo con edad mínima de 10 y años eclesiásticos que comienzan el 1 de enero. El postregistro de 2026 asigna Amigo a los 10 años; un certificado de Amigo fechado en 2025 se bloquea porque al inicio de ese año tenía 9. La solicitud operativa de 2026 permanece sin cambios. En cambio, un certificado de una clase anterior con edad histórica suficiente no se rechaza solo porque hoy la persona sea mayor.

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

La revisión del 2026-09-30 comprobó que `ClassAssignmentResolverService` asigna la clase del postregistro por edad al inicio del año, pero `certificate-bulk-imports` no consulta nacimiento ni edad mínima al enviar o aprobar. Una prueba aislada con los servicios reales y base de datos simulada reprodujo el ejemplo de Amigo de la sección 3.9. No es evidencia de casos existentes en producción. La nueva validación está pendiente de implementación.

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
| Seguimiento de envíos | Identidad de la ejecución programada y su destinatario, rol y alcance, estado de envío y reintentos; permite evitar duplicados sin fusionar roles distintos ni perder recordatorios ante fallos. La solución concreta se define en el diseño técnico. |

El estado de la persona en la solicitud no reemplaza el enum `investiture_status_enum` con una cadena paralela de club, coordinación y campo. Al autorizar, el enrollment pasa a `INVESTIDO`. Un rechazo o retiro libera el bloqueo de solicitud de ese enrollment, no los bloqueos de año cerrado o estado terminal. Permite corregir y volver a marcar si sigue siendo elegible. El fin de año no lo pasa a `INVESTIDO` ni lo marca con el texto de falta de requisitos.

Las restricciones de solicitudes activas deben resistir altas simultáneas, no depender solo del selector de la app. El bloqueo pertenece al enrollment, nunca a todas las clases de una persona. No se amplían los cupos de inscripción operativa vigentes: la excepción GM solo aprovecha inscripciones simultáneas que el sistema ya permite.

## 7. Implementación

Esta actualización es únicamente documental: las fases siguientes son trabajo futuro. Cada fase se implementará con pruebas antes de pasar a la siguiente, sin ejecutar builds salvo solicitud explícita del usuario. No se implementa el documento del 2026-09-21.

### Fase 0 — Contratos y diseño técnico

Definir primero los contratos backend de solicitud, selección de personas, cambio de fecha, resolución y configuración: DTOs, estados, permisos por acción, alcance territorial, errores de negocio y concurrencia. Definir la consistencia entre registro, enrollment, auditoría y envío de comunicaciones. No asumir endpoints nuevos a partir de los del pipeline anterior.

Incluir los errores de validación de edad histórica y datos faltantes de certificados, con mensajes accionables para app y panel. Definir cómo se confirma la acreditación usando los datos revalidados, sin una carrera entre comprobación y escritura. No crear una excepción administrativa que omita la edad mínima.

**Validaciones:** matriz de permisos de la sección 2; transición desde cada estado; selección de una sola sección; protección de solicitudes activas simultáneas; cierre manual y automático idempotente. Documentar el contrato antes de integrarlo en app y panel. El ajuste del admin es funcional y de integración, no un rediseño visual.

### Fase 0B — Validación preventiva de certificados de clases

Cerrar esta brecha antes de desplegar el nuevo flujo operativo. No depende de crear solicitudes ni recordatorios.

**Archivos:** `sacdia-backend/src/certificate-bulk-imports/certificate-bulk-imports.service.ts`, `sacdia-backend/src/certificate-bulk-imports/certificate-bulk-imports-application.service.ts` y sus pruebas `.spec.ts`. Reutilizar el cálculo de edad de `sacdia-backend/src/common/services/class-assignment-resolver.service.ts` y la resolución existente del año del certificado mediante una validación compartida, sin reutilizar la selección de la clase de mayor edad como criterio para certificados anteriores. Integrar los errores en los consumidores de certificados de app y panel sin rediseñarlos.

**Secuencia:** primero agregar la prueba de regresión y comprobar que falla por aceptación indebida; después implementar la validación compartida y conectarla a todas las rutas de IA-53; finalmente ejecutar las pruebas del módulo y verificar que la regresión y los casos válidos pasan. No ejecutar builds.

**Pruebas:**

- El ejemplo de Amigo de la sección 3.9 se bloquea al marcar listo, enviar, reenviar y aprobar, también mediante API directa y aprobación masiva. No crea historial investido ni modifica el pendiente de 2026.
- Edad histórica exactamente igual al mínimo permite continuar con las demás validaciones; un año menos lo impide. Cubrir cumpleaños antes, el día y después del inicio del año eclesiástico, usando mes y día completos.
- El cumpleaños posterior al inicio del ciclo no cambia la edad de referencia para acreditar ese ciclo. Cubrir un año eclesiástico cuyo inicio no sea el 1 de enero.
- Faltan nacimiento o mínimo, o la fecha corresponde a ningún año o a más de uno: error explícito, sin acreditar ni enviar el ítem.
- Cargar un archivo/OCR permite corregir un borrador inválido; el OCR o el estado recibido del cliente no sustituyen la validación del backend.
- Si nacimiento, fecha, clase o mínimo cambian después del envío, la aprobación usa los datos vigentes y bloquea la incompatibilidad. Una carrera con su modificación no confirma una acreditación basada en datos que dejaron de ser válidos.
- Un certificado históricamente válido de una clase anterior sigue siendo admisible para una persona mayor. Coincidir con una inscripción actual no omite la reconciliación explícita existente ni las restricciones de Guías Mayores.
- Fallar la validación no deja efectos parciales de acreditación, no cierra la solicitud operativa y no emite eventos/logros de investidura. Los certificados previamente acreditados siguen legibles y no se reescriben.

### Fase 1 — Porcentaje del Campo

**Archivos:** `sacdia-backend/src/classes/class-requirement-eligibility.service.ts`, `sacdia-backend/src/classes/classes.service.ts`, `sacdia-backend/src/classes/class-progress-scope.service.ts`, configuración nueva por Campo y año. No tocar el 70 de `sacdia-backend/src/clubs/clubs.service.ts`.

**Pruebas:** sin configuración, el requisito cuenta desde 80. Con 90, un 85 no cuenta. `VALIDATED` cuenta aunque el puntaje sea menor. `REJECTED` no cuenta, aunque tenga puntaje alto. `ADVANCED` no bloquea. Detalle individual, listado colectivo y elegibilidad usan el mismo criterio para `BASIC` y los requisitos `EXTRA` obligatorios/aplicables; una actividad complementaria sin contexto institucional mantiene el bloqueo existente. Hasta el 30 de junio 23:59 en la zona del Campo, `director-lf` y `assistant-lf` cambian el valor. Después, solo `super-admin`. La nota B sigue en 70.

### Fase 2 — Ventana de fechas

**Archivos:** configuración nueva junto a la del porcentaje. Zona: `LocalFieldTimezoneResolver` / `local_fields.timezone`.

**Pruebas:** el año nuevo nace del 1 de octubre al 20 de diciembre, recortado al rango del año. Se rechazan extremos fuera del año o un inicio posterior al fin. `director-lf`, `assistant-lf`, `admin` y `super-admin` pueden editar según su alcance. Unión y división consultan sus Campos, pero no editan, tampoco mediante llamadas directas a la API. No se leen ni editan Campos ajenos al alcance. El inicio y el último día son inclusivos según la zona local. La misma ventana bloquea presentación, adiciones y autorización fuera de rango. Editarla no otorga permiso de autorización ni de edición del porcentaje.

**Regresión obligatoria W1 antes de cerrar esta fase:**
- Año activo `2026-01-01`–`2026-06-30`, sin configuración, día local `2026-02-15`: lectura sin escrituras, ausencia explícita de ventana operativa y `allowsOperation = false`. No devolver todo el año como apertura ni fabricar un rango invertido para simular cierre.
- Tras guardar un rango válido con un editor autorizado, se permite operar únicamente dentro de ese rango y del año activo. Año terminado o inactivo continúa bloqueado, incluso para `super-admin`.
- Con intersección parcial se conserva el recorte; con año enero–diciembre se conserva octubre 1–diciembre 20. Mantener pruebas de límites inclusivos, zona horaria y permisos.
- Cubrir helper, servicio y respuesta HTTP del caso sin intersección; documentar la representación pública de ausencia de ventana en `docs/api/` y sincronizar `docs/features/validacion-investiduras.md`. Reemplazar la expectativa anterior de apertura anual, sin borrar la evidencia histórica de la revisión.

### Fase 3 — Pastores del distrito

**Archivos:** schema nuevo, asignación desde Campo y unión, lectura para saber quién autoriza.

**Pruebas:** el cupo global arranca en 2. `super-admin` lo cambia y el tope vale para todos los distritos. Asignan `director-lf`, `assistant-lf`, `director-union` y `assistant-union`, solo dentro de su alcance territorial. No se asigna un pastor de más. Los dos cupos quedan habilitados para autorizar. El distrito se resuelve por iglesia del club, no por un dato suelto del usuario.

La corrección P3-1 fue cerrada en la octava revisión independiente del 2026-10-01: 234 pruebas de regresión y 7 de concurrencia en PostgreSQL real, exclusivo y temporal. El cambio de cupo y el alta o la reactivación toman el mismo candado advisory antes de leer, también sin fila de cupo. El backend de cupos/asignaciones queda verificado en ese alcance y permite continuar con fase 4; no certifica UI ni integración operativa completa, no cierra la fase 2, no autoriza despliegue y no apaga el pipeline anterior. Los specs HTTP sustituyen guard y Prisma. La prueba PostgreSQL no cubre HTTP ni los `CHECK` exclusivos del SQL de la migración de pastores. Ver `docs/reviews/investidura-autorizacion-independent-review.md`.

### Fase 4 — Marcar, quitar y fecha en la app

El backend de esta fase está en el árbol de trabajo, en el módulo hermano `sacdia-backend/src/investiture-requests/`, y quedó verificado en el alcance de la undécima revisión independiente. La fase completa no está terminada: no incluye la pantalla de `sacdia-app`. No certifica UI, autenticación real ni la aplicación de la migración. La fase 2 sigue parcial. No hay despliegue y el pipeline anterior sigue activo.

La undécima revisión independiente del 2026-10-02 cierra P4-4 residual. Se verificaron `INVESTITURE_REQUEST_STALE` cuando otra cabecera está activa, reutilización sin otra activa y ambos órdenes de la carrera agregar/presentar, sin mover personas ni perder pendientes en el GET. Pasaron 291 pruebas de regresión, 9 PostgreSQL y 4 escenarios de aceptación independiente. P4-1, P4-2 y P4-3 permanecen cerrados. Puede continuar el desarrollo de fase 5, sin certificar UI, autenticación real ni aplicación de la migración. El despliegue sigue bloqueado y el pipeline anterior activo. Detalle y límites en `docs/reviews/investidura-autorizacion-independent-review.md`.

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

El backend de la resolución está en `sacdia-backend/src/investiture-requests/`. La decimoquinta revisión independiente (2026-10-05) cierra **P5-2** y mantiene cerrados **P5-1, P5-3 y la regresión del mock de ventana**. El backend queda verificado en el alcance revisado y permite continuar el desarrollo de fase 6. **No cierra la fase 5 completa:** faltan pantalla del panel e integración; los correos corresponden a fase 6. No hay despliegue y el pipeline anterior sigue activo. La pantalla de la app de la fase 4 y la fase 2 parcial siguen pendientes. Ver `docs/reviews/investidura-autorizacion-independent-review.md`.

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
- `class.completed` activa la evaluación de logros existente solo después de confirmar la investidura. Presentar, rechazar, quitar, cerrar el año o fallar la transacción no concede ese logro. Una intención ya confirmada se entrega aunque después cierren el año o la ventana; esa entrega no reabre la decisión. Reintentar no duplica eventos ni efectos.
- Ante autorización/rechazo simultáneos gana la primera decisión confirmada; la otra recibe aviso de resolución previa. También se protege la carrera con retiro y cierre anual.
- Fallar antes de confirmar no deja el registro, el enrollment y la auditoría en estados distintos. Reintentar una decisión confirmada no duplica efectos ni comunicaciones.

### Fase 6 — Correos, resultados y recordatorios

**Archivos:** `sacdia-backend/src/common/email/`, `sacdia-backend/src/notifications/`, tarea programada y seguimiento de envíos del nuevo flujo. Reutilizar el envío existente; definir el mecanismo de programación y reintentos sin asumir que ya hay una bandeja personal en el panel.

**Pruebas de presentación y resultado:** un envío produce un correo por destinatario y rol, no por persona. Pastor y director del Campo en la misma cuenta producen dos correos iniciales. El segundo envío lista solo a los nuevos. Quitar no manda correo. La directiva de la sección recibe una notificación por resultado, con los textos de la sección 4; las otras secciones no. La persona investida recibe el texto alegre. La rechazada recibe solo «Falta de requisitos para investidura». El motivo humano sigue privado en la solicitud para la directiva. El subdirector no recibe esas notificaciones.

**Pruebas de recordatorios:**

- Pastor: lunes, miércoles y viernes. Campo: solo lunes. Todos a las 10:00 a. m. locales, con casos de Campos en distintas zonas horarias.
- Una misma cuenta con rol pastoral y de director/asistente del Campo recibe dos recordatorios el lunes si ambos alcances tienen pendientes; miércoles y viernes, solo el pastoral. Los reintentos deduplican dentro del mismo rol y ejecución, nunca entre roles.
- El resumen del Campo agrupa todo su pendiente acumulado: una solicitud de hace dos semanas aparece en ambos lunes si sigue pendiente. No filtrar solo por fecha de creación desde el último corte.
- Una solicitud parcialmente resuelta cuenta una vez y muestra como accionables solo las personas pendientes.
- Solo se incluyen solicitudes del distrito o Campo del destinatario. No se envían correos a `admin` ni a `super-admin` por esos roles.
- Con ventana cerrada continúan y avisan que hace falta ampliarla; no habilitan autorización fuera de ventana.
- Sin pendientes, con año cerrado o después de `end_date`, no se envían. Se vuelven a comprobar estas condiciones antes del envío, incluidos los reintentos.
- Reejecutar la misma ejecución programada no duplica el recordatorio; un fallo de envío puede reintentarse sin perderlo.
- No se generan notificaciones periódicas en el panel. Las notificaciones de resultado de la app siguen funcionando.

**Estado de esta entrega:** el backend está en el árbol, sin commit. La vigesimoprimera revisión independiente (2026-10-06) cierra **P6-3 en el alcance comprobado**: cuerpo, destino y alcance comparten instantánea; el retiro durante render bloquea el reintento sin modificar cuerpo/clave. P6-1/P6-2/P6-4/P6-5 y P5 conservan sus cierres. **Backend de fase 6 aceptado para continuar el desarrollo de fase 7, NO para despliegue ni como cierre integral del plan.** La fase 7 está en el árbol, sin aprobación y sin pantallas. P7-2 y P7-3 quedaron cerrados. El residuo temporal de P7-1 está corregido en el árbol y la fase sigue sin aprobar. Fase 2 parcial, pantallas/integración pendientes y pipeline anterior activo. Ver verificaciones y límites en `docs/reviews/investidura-autorizacion-independent-review.md`.

### Fase 7 — Historial, anuario y fin de año

**Archivos:** `sacdia-backend/src/year-end/year-end.service.ts`, `sacdia-backend/src/year-cut/year-cut.service.ts`, `sacdia-backend/src/year-cut/year-cut-cron.service.ts`, integración con la política anual existente, historial de la app y vista de anuario del club en la app.

**Pruebas:** tanto el cierre administrativo como el corte automático cierran los registros pendientes como no investidos de ese año. Ejecutarlos de nuevo o ejecutar ambos no duplica efectos ni cambia a quienes ya estaban investidos. No se copian ni reabren solicitudes en el año siguiente. El historial conserva clase y año, sin el texto de falta de requisitos. Cesan los recordatorios del año cerrado. La continuidad anual deja a la persona por inscribir y, al inscribirla, en la clase siguiente, sin exigir la investidura anterior; no se sustituye esa política por un alta automática. El anuario lista inscripciones por clase y por año para la directiva dentro de su sección. Esta fase no cierra la máquina de estados de unidades ni de finanzas.

**Estado de esta entrega:** **backend ACEPTADO LOCALMENTE PARA CONTINUAR** por la vigesimocuarta revisión; P7-1/P7-2/P7-3 cerrados. Presentar y agregar consultan el reloj nuevamente después de los candados si no hay override explícito; los cuatro cruces de ventana/año rechazan sin insertar personas ni preparar avisos. Pasaron 103 pruebas unitarias, 38 PostgreSQL, cuatro aceptaciones del probe independiente, tipos y lint focal. La fase integral sigue pendiente de pantalla e integración: esta aceptación NO autoriza despliegue ni certifica HTTP, autenticación real o aplicación de migraciones. Fase 6 conserva su aceptación local. Cambios sin commit; fase 8 no iniciada y pipeline anterior activo. Siguiente paso: preparar fase 8 con inventario y tratamiento de expedientes anteriores antes de retirar la vía vieja. Ver `docs/reviews/investidura-autorizacion-independent-review.md`.

### Fase 8 — Apagar la vía vieja

Dejar de aceptar transiciones nuevas del pipeline club → coordinación → campo hacia `INVESTIDO`. Conservar la lectura del historial ya grabado y los certificados históricos; su nueva acreditación queda sujeta a la fase 0B. Preservar en la autorización nueva el evento `class.completed` que hoy dispara `markInvestido`, conforme a IA-51. Quitar de la app y del admin las acciones que envían, aprueban o invisten por esa vía. Cubrir también aliases de enrollments (`submit-for-validation`, `validate`, `investiture`) y operaciones masivas: no pueden quedar rutas alternativas que eludan el flujo nuevo.

**Condición de despliegue:** inventariar los expedientes del pipeline anterior antes de retirarlo. La regla de no arrastre entre años está cerrada; no equivale a haber aprobado una conversión o un reinicio masivo de expedientes del mismo año. Si existen pendientes de ese año en producción, documentar y aprobar su tratamiento antes del cambio de vía, sin perder historia ni desbloquear duplicados.

**Pruebas:** un enrollment operativo nuevo no llega a `INVESTIDO` por `markInvestido`, `FIELD_APPROVED`, un alias ni una operación masiva del pipeline retirado. Un historial viejo sigue leyéndose. Un certificado histórico no se mezcla con la solicitud. No se pierde ni se resuelve silenciosamente un expediente anterior pendiente durante el despliegue.

**Estado de esta preparación (2026-10-07):** el inventario de rutas, pantallas y expedientes está en `docs/features/validacion-investiduras.md`, sección «Preparación de fase 8». El 2026-10-07 se completó ese inventario con `ValidationModule` para `entity_type` class, la conciliación de certificados y la pantalla `/dashboard/clubs/validations`. También quedó una propuesta, sin decisión, para soltar más adelante el bloqueo de un expediente viejo. No se desactivó ninguna ruta y no se cambió la conciliación de certificados. No se consultó ni modificó producción, así que no hay conteos reales. El tratamiento vigente es conservar cada estado grabado: los expedientes abiertos no se resuelven, no se arrastran, no se copian a la solicitud nueva y no se les libera el bloqueo. La fase 8 no está ejecutada ni aprobada. El pipeline anterior sigue activo, con la exclusión mutua descrita en el informe, sección «X-1 a X-4». Esa exclusión no es el apagado. El backend de la fase 7 conserva su aceptación local para continuar, no para desplegar. La vigesimoquinta revisión cerró X-2, X-3 y X-4 con observaciones y dejó X-1 abierto. H1 a H5 están en el árbol y no están cerrados. No autorizan despliegue ni apagan el pipeline.

### Fase 9 — Documentación

Actualizar los contratos antes de integrar consumidores y mantener la documentación sincronizada en cada fase. Al cerrar la implementación, revisar en el mismo trabajo:

- `docs/features/validacion-investiduras.md`
- `docs/api/ENDPOINTS-LIVE-REFERENCE.md`
- `docs/api/FRONTEND-INTEGRATION-GUIDE.md`
- Contratos y documentación funcional de certificados: criterio de edad histórica, datos obligatorios, errores al preparar/enviar/aprobar y conservación de las reglas de reconciliación existentes.
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
- Reescribir certificados ya acreditados o corregir automáticamente datos históricos inconsistentes. La validación preventiva de nuevas acreditaciones sí está incluida.
- Crear notificaciones periódicas o una bandeja personal nueva en el panel para estos recordatorios.
- Enviar recordatorios a `admin` o `super-admin` por esos roles.
- Trasladar o reabrir solicitudes pendientes en el año siguiente.
- Definir cómo se cierran, estado por estado, las solicitudes de unidades y de finanzas.
- Resolver `ANNUAL_CLASS_POLICY_UNRESOLVED` para clases de más de un año.
- Marcar o autorizar desde la superficie que este plan no asigna. Marcar sigue solo en la app. Autorizar sigue solo en el panel.
