# Solicitudes colectivas de investidura — documento funcional

> **Reemplazado el 2026-09-28.** Este alcance no se implementa. El acuerdo vigente es `docs/plans/2026-09-28-investidura-autorizacion.md`.

- **Estado**: REEMPLAZADO
- **Fecha**: 2026-09-21
- **Alcance**: consolidación de acuerdos funcionales, sin implementación
- **Dominios**: validación de investiduras, clases progresivas y notificaciones

> **Decisión central:** el club presenta una solicitud colectiva directamente al Campo Local. Este autoriza a los participantes y, al finalizar el horario de la ceremonia, un proceso automático registra sus investiduras individuales usando la lista aprobada vigente.
>
> Las reglas de la sección 2 fueron confirmadas por el usuario. Las recomendaciones y los pendientes están separados en las secciones 6 y 7. Este documento **no describe funcionalidad ya implementada**, no reemplaza el contrato runtime y no autoriza cambios de código.

## 1. Objetivo y alcance

Representar la operación habitual de Aventureros, Conquistadores y Guías Mayores: comunicar quiénes se investirán, en qué clases, cuántas personas hay por clase, cuándo será la ceremonia y quiénes oficiarán y certificarán.

La solicitud es colectiva, pero el reconocimiento continúa siendo **por persona y clase**. No se inviste automáticamente a todos los inscritos en una clase por el hecho de que algunos participen en la ceremonia.

La ceremonia es el camino institucional esperado. No celebrarla no debe impedir, por sí mismo, la inscripción anual siguiente. Esta funcionalidad no sustituye la acreditación de investiduras históricas mediante certificados.

## 2. Reglas confirmadas

### 2.1 Solicitud, candidatos y aprobación

| ID | Acuerdo |
| --- | --- |
| RF-01 | La solicitud identifica a los participantes y sus clases, en el contexto del club y del año eclesiástico en curso. Los conteos por clase se obtienen de esa lista; no sustituyen la identificación de personas. |
| RF-02 | Solo pueden participar quienes hayan cumplido los requisitos de su clase en curso. El cumplimiento de un compañero no habilita al resto de la clase. La interpretación técnica de cumplimiento se precisa en P-04. |
| RF-03 | La solicitud incluye fecha y horario de la ceremonia, oficiante y pastor certificador. El instante de finalización necesario para automatizar el cierre se precisa en P-01. |
| RF-04 | El envío es **club → Campo Local**, sin revisión ni aprobación de coordinación en esta solicitud colectiva. |
| RF-05 | El Campo Local puede aprobar la solicitud parcialmente, excluyendo a participantes específicos sin impedir la autorización del resto. |
| RF-06 | Cada exclusión requiere **motivo obligatorio**, registrado como parte de la decisión e incluido en la notificación correspondiente. |
| RF-07 | La exclusión se notifica al **director, subdirector, secretario y secretario-tesorero** del club solicitante. Son cuatro cargos destinatarios; no omitir al subdirector ni tratar secretario y secretario-tesorero como un único cargo. |

### 2.2 Cambios en la lista y plazo de anticipación

| ID | Acuerdo |
| --- | --- |
| RF-08 | El club puede solicitar altas, bajas y cambios antes del límite establecido. Una baja solicitada por el club necesita validación del Campo Local para hacerse efectiva. |
| RF-09 | Una baja pendiente o no aprobada **no suspende ni niega una investidura ya autorizada**. Hasta una decisión autorizada, sigue vigente la lista aprobada anterior. |
| RF-10 | Cada Campo Local configura el plazo de anticipación para cerrar cambios de la lista. El valor no puede ser inferior a **cinco días naturales**, incluidos fines de semana y festivos. Puede establecer un plazo mayor; no se ha fijado un tope numérico global. |
| RF-11 | Debe existir una **pantalla de configuración por Campo Local** para administrar ese plazo. |
| RF-12 | Después del corte, el club ya no puede modificar la lista. La excepción corresponde exclusivamente al **director o asistente del Campo Local**. No se extiende por defecto a coordinación. |

**Ejemplo del plazo:** si el Campo Local fija diez días, el club debe gestionar sus cambios con esa anticipación; no dispone de los últimos diez días para modificar la lista. El momento exacto del corte todavía requiere definición en P-01.

**Distinción obligatoria entre solicitud y decisión:**

- Solicitar una baja no equivale a retirar a la persona de la lista aprobada.
- Una exclusión decidida por el Campo Local sí cambia quién está autorizado a investirse.
- Una incorporación aún no autorizada no forma parte de la lista aprobada utilizada por el cierre automático.
- Se descartó expresamente suspender preventivamente la investidura de una persona por una baja pendiente.

El plazo de cambios no define, por sí solo, un plazo para presentar la solicitud inicial ni impone que todas las ceremonias ocurran en el último trimestre; ver P-02 y P-03.

### 2.3 Oficiante y pastor certificador

| ID | Acuerdo |
| --- | --- |
| RF-13 | Son responsabilidades diferenciadas. Habitualmente las desempeña una misma persona, pero se permite que sean personas distintas. |
| RF-14 | La opción **«El oficiante también certifica»** aparece activada por defecto. Si no corresponde, se indica al pastor certificador por separado. |
| RF-15 | Para ambas responsabilidades, la vía principal es buscar y seleccionar a un **usuario SACDIA**. También se admite una persona sin cuenta mediante una alternativa de captura manual menos visible. |
| RF-16 | La captura manual incluye **nombre completo, cargo y entidad de procedencia** —distrito, Campo Local o unión—. No se acordaron teléfono ni correo como obligatorios. |

La interfaz prioriza el buscador de usuarios; debajo presenta una alternativa secundaria, como **«¿No está en SACDIA? Registrar sus datos»**. Registrar estos datos no implica crear una cuenta ni conceder permisos administrativos.

Como contexto operativo, el usuario mencionó como oficiantes habituales al pastor distrital, al director del Campo Local o a un director de unión. Esto no constituye todavía una lista exhaustiva de personas o cargos habilitados; ver P-05.

### 2.4 Investidura automática y continuidad anual

| ID | Acuerdo |
| --- | --- |
| RF-17 | Al finalizar el horario de la ceremonia, un servicio automático registra como `INVESTIDO` a los participantes de la **lista aprobada vigente**. No se exige una confirmación manual general posterior como condición para cerrar. |
| RF-18 | La investidura queda vinculada individualmente a la persona y clase correspondientes. Quienes no están autorizados en la lista no se invisten por pertenecer al mismo club o clase. |
| RF-19 | No haber celebrado la investidura de la clase anterior **no debe bloquear por sí mismo la continuidad anual**. La ceremonia sigue siendo lo esperado, pero algunas secciones pueden no realizarla. |

El cierre automático no es una inscripción automática en la siguiente clase. Tampoco es prueba independiente de asistencia: aplica la decisión institucional y la lista vigente. Las correcciones posteriores por ausencias o errores requieren la política pendiente P-07, no un nuevo bloqueo manual implícito.

## 3. Flujo funcional consolidado

1. **Preparación del club.** Identificar candidatos elegibles, agruparlos por clase y completar los datos de la ceremonia y sus responsables.
2. **Envío directo al Campo Local.** Presentar la solicitud sin pasar por coordinación.
3. **Revisión institucional.** Autorizar a los participantes. Si hay exclusiones, registrar el motivo obligatorio y notificar a los cuatro cargos indicados en RF-07.
4. **Gestión de cambios.** Aplicar el plazo territorial en días naturales. Una baja pendiente no modifica la autorización vigente; después del corte solo actúan director o asistente del Campo Local.
5. **Cierre automático.** Al finalizar el horario, registrar las investiduras individuales autorizadas sin esperar una confirmación manual general.
6. **Consulta y continuidad.** Conservar el resultado individual y tramitar la inscripción del siguiente año por el flujo anual correspondiente, sin exigir esta ceremonia como nueva barrera.

Este flujo no fija todavía los nombres de estados de base de datos, endpoints o permisos. Tampoco convierte a coordinación en aprobador técnico oculto para satisfacer el pipeline anterior.

## 4. Superficies funcionales necesarias

La siguiente organización es una **propuesta de presentación**, no un diseño visual aprobado ni una implementación de pantallas.

| Superficie | Información y acciones esperadas |
| --- | --- |
| Solicitud del club | Personas y clases, conteos calculados, fecha/horario, selección de oficiante y certificador, envío al Campo Local. |
| Revisión del Campo Local | Datos de ceremonia, candidatos y cumplimiento, aprobación parcial, exclusiones con motivo y decisión sobre bajas solicitadas. |
| Seguimiento | Lista aprobada vigente diferenciada de cambios pendientes, exclusiones y motivos, plazo de cambios y resultado del cierre. |
| Configuración territorial | Plazo en días naturales, validación del mínimo de cinco días e identificación del Campo Local al que aplica. |

La distribución entre app móvil y panel administrativo se definirá al diseñar los contratos. No se acuerda aquí un rediseño general del admin.

## 5. Diferencias respecto al sistema actual

Esta comparación es una lectura del código y la documentación durante el análisis, no una declaración de despliegue. Los enlaces permiten volver a verificarla antes de implementar.

| Aspecto | Situación observada | Cambio solicitado |
| --- | --- | --- |
| Unidad de trabajo | Inscripciones individuales, con operaciones masivas sobre ellas. | Solicitud colectiva persistente vinculada a una ceremonia y a sus participantes. |
| Revisión | Pipeline individual con aprobación de club, coordinación y Campo Local. | Solicitud colectiva directamente al Campo Local, sin coordinación. |
| Fecha | `investiture_config` es único por Campo Local y año; su fecha de investidura es `Date`, sin hora. `markInvestido` copia esa fecha. | Horario propio de la ceremonia y cierre automático al finalizar; no depender de una única fecha general para todos los clubes. |
| Plazo | `submitForValidation` calcula `is_late` a partir de `submission_deadline`, pero no bloquea el envío por esa fecha. | Un corte efectivo para cambios del club, calculado con anticipación a cada ceremonia. No confundirlo con el aviso de envío tardío existente. |
| Requisitos | El envío individual verifica requisitos y duración. El cálculo acepta una sección no rechazada si está `VALIDATED` **o** tiene `score >= 70`; considera obligatorios `BASIC` y `EXTRA` aplicables, no `ADVANCED`. | Conservar el requisito de cumplimiento, resolviendo explícitamente P-04 antes de cambiar su significado. |
| Registro final | `markInvestido` exige `FIELD_APPROVED`, actualiza una inscripción y registra historial; no recalcula allí los requisitos. | Ejecución automática según ceremonia y lista autorizada, con las garantías de operación por definir. |
| Continuidad anual | En modo anual se omite el prerrequisito de investidura de la clase inmediatamente anterior del mismo tipo. No se eliminan todos los demás prerrequisitos. | No introducir un bloqueo nuevo por ausencia de ceremonia ni eliminar otras reglas curriculares por extensión. |

Fuentes del contraste:

- [Feature vigente de investiduras](../features/validacion-investiduras.md) y [referencia API](../api/ENDPOINTS-LIVE-REFERENCE.md#investiture).
- [Servicio de investidura](../../sacdia-backend/src/investiture/investiture.service.ts): `submitForValidation`, `markInvestido` y `resolveInvestitureConfig`.
- [Cálculo de elegibilidad](../../sacdia-backend/src/classes/class-requirement-eligibility.service.ts): `calculateForEnrollmentRecord`.
- [Política de inscripción](../../sacdia-backend/src/classes/class-enrollment-policy.service.ts): `evaluate`, modo `annual`.
- [Schema efectivo](../../sacdia-backend/prisma/schema.prisma): `enrollments`, `investiture_validation_history` e `investiture_config`.

## 6. Recomendaciones para el diseño técnico — aún no aprobadas

Estas recomendaciones no agregan requisitos de negocio confirmados ni sustituyen las decisiones pendientes.

1. **Separar solicitud, participantes y cambios propuestos.** Mantener una lista aprobada efectiva sin sobrescribirla con una baja o alta pendiente; conservar historial individual en lugar de crear un segundo historial incompatible.
2. **Precisar el tiempo de la ceremonia.** Capturar inicio, finalización y zona horaria; distinguir el momento de la ceremonia del momento en que el servicio procesa el cierre. Resolver P-01 antes de establecer una fórmula de corte.
3. **Reutilizar infraestructura programada del backend.** Procesar ceremonias aprobadas cuyo final haya pasado, con reintentos y recuperación de pendientes tras interrupciones. La frecuencia —por ejemplo, cada minuto— no está acordada y no debe prometerse ejecución al segundo exacto.
4. **Proteger la actualización automática.** Transacciones, control de concurrencia, prevención de duplicados y auditoría del actor automático, sin inventar una acción humana. Consultar el estado vigente para evitar aplicar una programación cancelada o reemplazada una vez que P-07 defina esas operaciones.
5. **Entregar notificaciones de forma confiable.** Vincular motivo y participante excluido con la decisión registrada, reintentar entregas y evitar mensajes duplicados cuando una persona ocupe varios cargos. Resolver canales y cargos vacantes en P-06.

El backend ya dispone de [procesos programados](../features/cron-automation.md); un ejemplo es [MembershipRequestsCronService](../../sacdia-backend/src/membership-requests/membership-requests-cron.service.ts). Eso ofrece infraestructura reutilizable, pero no significa que el cierre de ceremonias ya exista.

## 7. Puntos pendientes de definición

No deben resolverse silenciosamente al implementar. Los ejemplos de esta tabla señalan decisiones faltantes; no son reglas aprobadas.

| ID | Tema | Definición pendiente |
| --- | --- | --- |
| P-01 | Horario y corte | Confirmar captura de inicio y fin, zona horaria y hora exacta del corte. Definir inclusión del día límite. «Días naturales» no decide por sí solo si el corte es a medianoche o a la hora de inicio, ni equivale siempre a restar bloques de 24 horas. |
| P-02 | Unidad y cantidad de solicitudes | Precisar si cada solicitud corresponde exclusivamente a una sección o puede reunir varias, y si puede haber más de una ceremonia por sección y año. La propuesta inicial por sección no debe convertirse sin confirmación en una restricción de una sola solicitud anual. |
| P-03 | Ventanas y configuración | Definir plazo de envío inicial, alcance de configuración por año o permanente, valor inicial y efecto de cambiarlo sobre ceremonias existentes. Precisar tratamiento de solicitudes de cambio recibidas antes del corte pero resueltas después. |
| P-04 | Elegibilidad | Acordar si se mantiene el criterio actual `VALIDATED` o puntuación mínima, o se exige validación formal de todos los requisitos obligatorios. Definir cuándo se verifica y qué ocurre si cambia tras aprobar. Precisar clases plurianuales y su relación con el año de ceremonia, sin inventar exenciones ni bloqueos. |
| P-05 | Actores y permisos | Precisar cargos del club que crean/envían/solicitan cambios, quién aprueba inicialmente y quién administra configuración. Mapear director/asistente del Campo Local a permisos y territorio reales. Definir validación de autoridad del oficiante/certificador y aprobación de altas u otros cambios; la aprobación de bajas ya está confirmada. |
| P-06 | Notificaciones | Definir canales, destinatarios efectivos si hay cargos vacantes o acumulados y eventual aviso al participante. Los cuatro cargos y el motivo obligatorio ya están confirmados; no se ha aprobado un canal específico. |
| P-07 | Excepciones de ceremonia | Definir cancelación, reprogramación, aprobación después del horario, correcciones posteriores al cierre y reincorporación de una persona excluida. Ninguna de estas decisiones puede reintroducir suspensión por una baja pendiente. |
| P-08 | Compatibilidad y operación | Resolver trámites individuales ya en curso, endpoints anteriores y transición sin perder historial. Acordar tolerancia de demora del servicio, seguimiento de fallos y resultado ante fallos parciales. No se ha autorizado migración ni sustitución inmediata del flujo actual. |

La falta de firma o confirmación manual posterior **no** se convierte en un pendiente que bloquee el cierre: el usuario pidió expresamente automatización. Si se requiere un comprobante adicional de certificación, debe definirse por separado y no presumirse obligatorio.

## 8. Criterios de aceptación funcionales

Estos escenarios sirven para verificar una implementación futura. **No son pruebas ejecutadas ni indican que la funcionalidad esté terminada.**

| Caso | Resultado esperado | Reglas |
| --- | --- | --- |
| Seleccionar cinco de Amigo y dos de Compañero | La solicitud identifica siete personas y calcula cinco/dos por clase; no incorpora automáticamente a sus compañeros. | RF-01, RF-18 |
| Consultar la solicitud de ceremonia | Se identifican fecha, horario, oficiante y pastor certificador; el detalle temporal se concreta en P-01. | RF-03 |
| Intentar incluir a quien no cumple requisitos | No queda habilitado para investidura por pertenecer al grupo. El criterio de cumplimiento se cierra en P-04. | RF-02 |
| Enviar solicitud | Llega al Campo Local sin paso obligatorio por coordinación. | RF-04 |
| Aprobar con una exclusión | Los demás pueden quedar autorizados; excluir sin motivo no está permitido. | RF-05, RF-06 |
| Excluir con motivo | Se genera aviso con la justificación para director, subdirector, secretario y secretario-tesorero. | RF-06, RF-07 |
| Solicitar baja de una persona aprobada y dejarla pendiente | La persona conserva su autorización; su investidura no se suspende por esa solicitud. | RF-08, RF-09, RF-17 |
| Configurar cuatro días | El sistema rechaza el valor; cinco o un valor mayor cumplen el mínimo. | RF-10, RF-11 |
| El plazo cruza fin de semana o festivo | Esos días cuentan; no se extiende el plazo como si fueran días hábiles. | RF-10 |
| El club intenta modificar después del corte | No puede hacerlo; se mantiene la excepción de director/asistente del Campo Local. | RF-12 |
| Oficiante y certificador coinciden | Se usa la opción activada por defecto, sin obligar a capturar dos personas. | RF-13, RF-14 |
| Son personas distintas o alguna no tiene cuenta | Se pueden identificar por separado; se prioriza el buscador SACDIA y la captura manual admite nombre, cargo y procedencia. | RF-15, RF-16 |
| Finaliza el horario de una ceremonia aprobada | El servicio registra `INVESTIDO` para la lista autorizada vigente sin cierre manual general; no inviste excluidos ni personas ajenas a esa lista. | RF-17, RF-18 |
| La sección no celebró ceremonia y comienza otro año | La falta de investidura anterior no introduce un bloqueo nuevo en la continuidad anual; tampoco genera una inscripción automática. | RF-19 |

## 9. Límites de esta entrega y siguiente paso

Esta entrega crea únicamente este documento. No define un schema definitivo, endpoints nuevos, migraciones, cron desplegado, asignaciones de permisos ni pantallas implementadas. Tampoco modifica la documentación del comportamiento vigente para presentarlo como reemplazado.

Quedan fuera de este cambio la acreditación histórica por certificados y la eliminación indiscriminada de prerrequisitos curriculares. El flujo nuevo no autoriza borrar registros previos ni atribuir al oficiante las acciones del servicio automático.

**Siguiente paso recomendado:** revisar los pendientes de la sección 7 y cerrar primero calendario/corte, unidad de solicitud y elegibilidad. Después preparar diseño técnico, contratos y plan de implementación con actualización coordinada de documentación. No iniciar implementación por el solo hecho de existir este documento.

### Trazabilidad de acuerdos

Fuente principal: decisiones expresas del usuario en la conversación de análisis. Recuperación complementaria en Engram, proyecto `sacdia`:

| Tema | Clave de memoria |
| --- | --- |
| Cierre automático y continuidad anual | `investiture/automatic-ceremony-close` |
| Baja pendiente sin suspensión | `investiture/participant-withdrawal-approval` |
| Plazo territorial en días naturales | `investiture/roster-change-cutoff` |
| Oficiante y certificador | `investiture/ceremony-officiant-certifier` |
| Identificación SACDIA o externa | `investiture/ceremony-authority-identification` |
| Ruta directa al Campo Local | `investiture/ceremony-approval-route` |
| Aprobación parcial, motivo y notificaciones | `investiture/partial-approval-and-notifications` |
