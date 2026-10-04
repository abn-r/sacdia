# 15 · Catálogo integral de flujos para usuarios de SACDIA

**Estado:** DRAFT · **Fecha de síntesis:** 2026-09-15 · **Última actualización focalizada:** 2026-09-22 (02, 15 y nuevo 49)
**Audiencia:** miembros, directivas, consejeros, coordinadores, campo local, unión y administración del sistema.

Esta guía reúne **49 flujos y familias de flujos funcionales** para explicar el sistema de una sola vez: las 48 familias anteriores, con sus límites de evidencia, y una nueva definición funcional de ceremonia colectiva **sin implementación acreditada** (49). Conserva la numeración previa. Agrupa variantes del mismo proceso; no pretende convertir cada endpoint o botón en un flujo independiente ni afirmar que los 49 están operativos.

**Idea central:** SACDIA conecta la trayectoria de las personas, la operación de las secciones y la supervisión institucional. La app y el panel son herramientas de esos procesos, no dos sistemas independientes.

> **Límite de evidencia.** Es una síntesis de documentos de dominio, contratos API y fichas con revisión local del 2026-09-14, ampliada con inspección de código el 2026-09-15 para excepciones, conectividad y recorridos pendientes. No certifica despliegue, permisos de cuentas reales ni pruebas completas de extremo a extremo. Los documentos fuente pueden contener desfases; se señalan las diferencias relevantes sin convertirlas en capacidades garantizadas.

**Actualización del 2026-09-22:** se contrastaron con código la continuidad anual y la obligatoriedad de Guías Mayores; se incorporaron los acuerdos de ceremonia del 2026-09-21. No es una nueva auditoría de todas las familias. Las 104 pruebas citadas más adelante corresponden al 2026-09-16, no a esta actualización documental.

## Cómo leer y presentar la guía

- **D — Documentado:** recorrido descrito en documentos funcionales o fichas de revisión. No equivale a certificado en producción.
- **V — Verificado en código local:** se inspeccionó el comportamiento o la conexión de pantalla indicados. No significa probado visualmente ni de extremo a extremo; la verificación solo cubre la parte señalada.
- **C — Contrato:** API identificada; en esta síntesis no se comprobó el recorrido completo por pantallas.
- **P — Parcial o condicionado:** desarrollo, diferencias entre clientes, configuración o rama de entrega pendientes de comprobar.
- **A — Acuerdo funcional:** comportamiento futuro confirmado en diseño, sin implementación acreditada. Se explica como propuesta acordada, no como demostración disponible.
- **Actor autorizado:** requiere permiso, alcance territorial/sección y vigencia; el título eclesiástico por sí solo no concede acceso.
- **Canales:** indican la superficie descrita por las fuentes, no paridad entre app y panel. API no significa que el usuario tenga un botón visible.

**Orden recomendado para explicarlo:** ingreso → organización y año → formación → vida cotidiana → seguros y eventos → informes y supervisión. Los números son referencias editoriales, no un orden obligatorio de ejecución. Por ejemplo, crear y habilitar una sección es previo a que una persona pueda solicitar ingresar en ella.

### Índice general

| Bloque | Flujos |
|---|---|
| A. Recorrido principal | [01 Ingreso](#f01) · [02 Continuidad anual](#f02) · [03 Responsabilidades](#f03) · [04 Avance de clase](#f04) |
| B. Reconocimiento y trayectoria | [05 Investidura](#f05) · [06 Especialidades](#f06) · [07 Maestrías](#f07) · [08 Certificaciones](#f08) · [09 Certificados previos/OCR](#f09) |
| C. Cuenta y datos personales | [10 Acceso y recuperación](#f10) · [11 Perfil](#f11) · [12 Contexto activo](#f12) · [13 Seguridad de sesión](#f13) · [14 Exportación y eliminación](#f14) |
| D. Organización institucional | [15 Club y secciones](#f15) · [16 Matrícula anual de sección](#f16) · [17 Dirección actual/futura](#f17) · [18 Solicitudes de cargo](#f18) · [19 Transferencias](#f19) · [20 Coordinación](#f20) · [21 Cierre y corte de año](#f21) |
| E. Operación de la sección | [22 Actividades](#f22) · [23 Asistencia y QR](#f23) · [24 Planilla semanal](#f24) · [25 Miembro del mes](#f25) · [26 Finanzas](#f26) · [27 Inventario](#f27) · [28 Seguros](#f28) · [29 Materiales generales](#f29) |
| F. Camporees | [30 Configuración](#f30) · [31 Inscripción de sección](#f31) · [32 Personas y pago](#f32) · [33 Aprobaciones tardías](#f33) · [34 Agenda y personal](#f34) · [35 Evaluación oficial](#f35) · [36 Mercancía](#f36) · [37 Insumos](#f37) |
| G. Rendición y supervisión | [38 Informe mensual](#f38) · [39 Informes trimestrales/anuales](#f39) · [40 Carpeta anual](#f40) · [41 Clasificaciones](#f41) · [42 Tableros](#f42) · [43 Revisión por lotes](#f43) |
| H. Servicios transversales | [44 Recursos digitales](#f44) · [45 Notificaciones](#f45) · [46 Soporte](#f46) · [47 Administración y configuración](#f47) · [48 Auditoría](#f48) |
| I. Definición funcional pendiente de implementación | [49 Solicitud colectiva y ceremonia de investidura](#f49) — **A**, no sustituye al 05 |

**Complementos para capacitación:** [Excepciones y correcciones](#excepciones) · [Conexión y operaciones sin confirmar](#recuperacion) · [Recorridos localizados en código](#pantallas-verificadas).

## A. Recorrido principal

<a id="f01"></a>
### 01 · Ingreso inicial de un miembro

- **Objetivo e inicio:** una persona nueva quiere participar en una sección habilitada.
- **Actores:** persona, representante cuando corresponda y directiva autorizada de la sección.
- **Recorrido:** crear cuenta → cargar foto → completar datos personales y emergencia → registrar representante si aplica → elegir territorio/club/sección → sistema determina clase y registra inscripción → membresía pendiente → directiva revisa.
- **Decisiones y resultado:** aprobar activa la membresía; rechazar no la activa. Cancelar permite volver a elegir sección sin borrar perfil. La solicitud también puede vencer. La clase se registra al completar el post-registro, no después de aprobar la membresía.
- **Canales/evidencia:** **D**, app para ingreso; app/panel para revisión según autorización. No presentar la verificación de correo como bloqueo previo al formulario sin comprobarlo.
- **Para explicar:** “Crear la cuenta inicia el proceso; la aprobación de la directiva habilita la participación operativa”. [Fuente: ingreso inicial](06-ingreso-inicial.md).

<a id="f02"></a>
### 02 · Continuidad anual de miembros existentes

- **Objetivo e inicio:** confirmar quién continúa durante un nuevo año eclesiástico, sin crear otra cuenta.
- **Actores:** directiva autorizada de la sección destino (`club_members:approve`) y sistema; no es autoinscripción del miembro.
- **Recorrido:** periodo vigente → lista de personas no inscritas → directiva selecciona continuidades → sistema verifica pertenencia y política de clase → activa membresía y resuelve inscripción formativa en una misma operación por persona.
- **Progresión y cambio de tipo:** sin trayectoria previa del tipo, se resuelve la clase por edad; con trayectoria previa, la siguiente clase activa por orden. Al haber cursado la última clase del tipo se contemplan **Aventureros → Conquistadores desde los 10 años** y **Conquistadores → Guías Mayores desde los 16**, calculados al inicio del año destino, con sección destino activa del mismo club y catálogo resoluble. No es un traslado automático al cumplir años ni el cursado cruzado de un Guía Mayor.
- **Decisiones y resultado:** inscrito, trayectoria completa (`path_complete`), ya inscrito, bloqueado o fallido. Al terminar el recorrido de Guías Mayores, la continuidad conserva la membresía anual sin inventar otra clase. Si la clase no puede resolverse, no queda una activación parcial. Sin confirmación permanece no inscrito; no se transforma en solicitud de primer ingreso.
- **Límites:** no copia cargos. La ausencia de investidura de la clase inmediatamente anterior no bloquea por sí sola la continuidad; no elimina otros prerrequisitos curriculares. El retorno de directivos AV/CQ a GM y las clases GM multianuales conservan pendientes; no se generaliza a cualquier cambio de sección.
- **Canales/evidencia:** **D/V/P**, app documentada y bloque web localizado en detalle de club → secciones, condicionado por autorización. Verificación estática del 2026-09-22, no prueba autenticada. La ausencia web señalada por la ficha 07 corresponde a su corte anterior.
- **Para explicar:** “Se conserva la trayectoria, pero la directiva confirma cada año; el cambio de tipo depende de la trayectoria, la edad y la sección disponible”. [Fuentes: ficha histórica](07-inscripcion-anual.md), [reglas actuales](../../features/gestion-clubs.md), [resolver](../../../sacdia-backend/src/classes/next-class.resolver.ts), [operación anual](../../../sacdia-backend/src/annual-membership/annual-membership.service.ts), [bloque web](../../../sacdia-admin/src/components/clubs/detail/annual-continuations-block.tsx).

<a id="f03"></a>
### 03 · Organización de responsabilidades, unidades y clases

- **Objetivo e inicio:** una sección habilitada necesita organizar su equipo y a sus miembros.
- **Actores:** administración/dirección autorizadas y responsables de formación.
- **Recorrido:** establecer director vigente → asignar cargos dentro de los cupos → crear unidades → incorporar miembros de esa sección → asignar responsables pedagógicos elegibles a las clases.
- **Decisiones y resultado:** el sistema verifica pertenencia, vigencia y cupos. Una persona solo integra una unidad activa de la misma sección. Un consejero no obtiene automáticamente responsabilidad sobre todas las clases.
- **Canales/evidencia:** **D**, app/panel con coberturas distintas. La asignación pedagógica exige rol activo y elegibilidad de Guía Mayor según reglas del dominio. Secretaría-tesorería combinada excluye los cargos separados.
- **Para explicar:** “Cargo es responsabilidad; unidad es grupo; clase es formación”. [Fuentes: operación](13-operacion-seccion.md), [clases](../../features/clases-progresivas.md).

<a id="f04"></a>
### 04 · Avance de clase y revisión de evidencias

- **Objetivo e inicio:** un miembro tiene una inscripción formativa vigente y editable.
- **Actores:** miembro, responsable autorizado y revisor de evidencias.
- **Recorrido:** consultar módulos/requisitos → realizar trabajo → registrar avance y archivos → enviar explícitamente el requisito → revisar → aprobar o rechazar con motivo → corregir y reenviar cuando el estado lo permita.
- **Decisiones y resultado:** progreso actualizado y decisión sobre evidencia. Cargar un archivo no equivale a enviarlo. El requisito rechazado no cuenta como completo aunque tenga puntaje alto.
- **Canales/evidencia:** **D**, app para trabajo; revisión en panel/app autorizada. El cálculo admite `VALIDATED` o puntaje ≥70, siempre sin rechazo: 100% no certifica revisión humana de todo. Para investidura cuentan requisitos obligatorios aplicables de desarrollo/complementarios, no la vía avanzada.
- **Para explicar:** “Registrar trabajo, revisar evidencia e investir son tres momentos distintos”. [Fuente: clases progresivas](08-clases-progresivas.md).

## B. Reconocimiento y trayectoria

<a id="f05"></a>
### 05 · Validación e investidura de clase

- **Objetivo e inicio:** presentar una clase elegible para reconocimiento institucional.
- **Actores:** consejero/director que envía, director de sección y revisores autorizados de las etapas de coordinación/campo.
- **Recorrido:** comprobar requisitos, duración y configuración del periodo → enviar → bloquear edición → aprobación de club → coordinación → campo → registrar investidura y fecha.
- **Decisiones y resultado:** aprobación permite avanzar de etapa; rechazo con motivo habilita corrección según las reglas de año/estado. Investido es un reconocimiento distinto de tener el formulario completo. Una inscripción vencida conserva historia, pero no continúa normalmente.
- **Canales/evidencia:** **D/P**, app y panel; la app envía desde detalle de clase. La capacidad concreta depende de los roles del contrato: no atribuir aprobación final a cualquier cargo territorial por su nombre. El vencimiento masivo documentado es manual, no cron automático.
- **No confundir con el nuevo diseño:** este es el pipeline individual existente. La [solicitud colectiva de ceremonia (49)](#f49) propone envío directo a Campo Local y cierre automático; su incorporación a esta guía no reemplaza este proceso ni acredita migración de trámites en curso.
- **Para explicar:** “La clase completa se presenta a las autoridades; la investidura se registra como un acto institucional”. [Fuentes: ficha 08](08-clases-progresivas.md), [investiduras](../../features/validacion-investiduras.md).

<a id="f06"></a>
### 06 · Cursar y validar una especialidad

- **Objetivo e inicio:** un miembro con contexto elegible desea cursar una especialidad del catálogo.
- **Actores:** miembro y revisor autorizado.
- **Recorrido:** consultar catálogo → inscribirse → elegir trabajo dentro de la app o mediante formato externo → completar requisitos/evidencias del modo → el propietario envía → revisión del paquete completo.
- **Decisiones y resultado:** aprobada o rechazada con motivo. Para reenviar tras rechazo debe haber correcciones. Mientras está en revisión o aprobada no se modifica libremente. Abandonar y reactivar tiene reglas propias; no es una nueva copia independiente.
- **Canales/evidencia:** **D/P**, app y panel de revisión. La ficha documenta diferencias entre filtro de catálogo móvil y elegibilidad API. No se organiza por matrícula anual ni utiliza el pipeline de investidura.
- **Para explicar:** “La especialidad tiene su propia inscripción y aprobación; no investe automáticamente una clase”. [Fuente: especialidades](09-honores.md).

<a id="f07"></a>
### 07 · Obtención y vigencia de maestrías

- **Objetivo e inicio:** reconocer un conjunto de especialidades aprobadas que cumple las reglas de una maestría.
- **Actores:** sistema, miembro y administración que configura las reglas.
- **Recorrido:** aprobar o modificar la vigencia de especialidades → evaluar condiciones → registrar resultado de maestría → mostrar vigencia e historial.
- **Decisiones y resultado:** maestría vigente o no vigente si se dejan de cumplir condiciones o se retira. Los cambios no borran el historial.
- **Canales/evidencia:** **D**, consulta móvil y configuración administrativa. No existe una solicitud adicional de maestría equivalente al envío de especialidad; el cálculo también puede dispararse por cambios de reglas.
- **Para explicar:** “La maestría se deriva de especialidades reconocidas; no se solicita como otra especialidad”. [Fuente: maestrías](09-honores.md).

<a id="f08"></a>
### 08 · Certificación electiva de un programa

- **Objetivo e inicio:** una persona elegible solicita cursar un programa con versión publicada.
- **Actores:** participante, revisor de requisitos, revisor de cierre y certificador autorizado.
- **Recorrido:** consultar elegibilidad → inscribirse a una versión → trabajar y enviar requisitos → aprobación o devolución para ajustes → completar obligatorios → presentar comprobante de junta → revisión final → certificación.
- **Decisiones y resultado:** solicitudes de cambios permiten corregir; la certificación final requiere volver a verificar requisitos y comprobante. El participante no se revisa a sí mismo.
- **Canales/evidencia:** **P**, app de participante y panel de revisión descritos; el registro funcional sigue parcial y no se ensayó un programa publicado. Versión nueva no reescribe inscripciones existentes; sin reglas configuradas no se asume elegibilidad.
- **Para explicar:** “Es un programa con requisitos y cierre propios, no otra clase ni una especialidad”. [Fuente: certificaciones](10-certificaciones.md).

<a id="f09"></a>
### 09 · Incorporar certificados previos mediante carga masiva

- **Objetivo e inicio:** un miembro posee comprobantes de clases o especialidades ya realizadas.
- **Actores:** miembro, extractor OCR y revisor de campo autorizado.
- **Recorrido:** subir comprobantes → intentar extraer datos → miembro completa/corrige filas → enviar lote → revisión por fila o lote → aplicar registros aprobados a la trayectoria existente.
- **Decisiones y resultado:** lote aprobado, parcial o devuelto; filas rechazadas pueden corregirse y reenviarse. Aprobar de nuevo una fila no debe duplicar la trayectoria.
- **Canales/evidencia:** **P**, flujo app/panel documentado en implementación. Hay un proveedor OCR sustituible y una implementación sin extracción (`Noop`); no prometer lectura automática operativa sin comprobar proveedor y entorno.
- **Para explicar:** “La lectura propone datos, la persona los confirma y el campo valida; subir un certificado no lo aprueba”. [Fuente: carga masiva](../../features/carga-masiva-certificados.md).

## C. Cuenta y datos personales

<a id="f10"></a>
### 10 · Acceso, recuperación de contraseña y cierre de sesión

- **Objetivo e inicio:** una persona necesita entrar a su cuenta, recuperar acceso o salir.
- **Actores:** usuario y sistema de autenticación.
- **Recorrido normal:** proporcionar credenciales → verificar acceso a la superficie → recuperar contexto y estado de registro → entrar a las funciones permitidas → cerrar sesión al terminar.
- **Variantes y resultado:** si olvidó la contraseña, solicita recuperación y sigue el mecanismo recibido; si su sesión ya no puede renovarse, debe autenticarse nuevamente. Verificar correo es un subflujo de identidad, no aprobación de membresía.
- **Canales/evidencia:** **D/P**, login app/panel y recuperación documentados. OAuth Google/Apple existe en contrato, pero la documentación móvil declara integración no disponible: no presentarlo como camino garantizado.
- **Para explicar:** “Poder iniciar sesión, acceder al panel y operar una sección son autorizaciones diferentes”. [Fuente: autenticación](../../features/auth.md).

<a id="f11"></a>
### 11 · Mantener perfil, salud, contactos y representante

- **Objetivo e inicio:** el miembro necesita completar o actualizar información personal.
- **Actores:** titular o persona autorizada para el recurso correspondiente.
- **Recorrido:** abrir perfil → consultar datos → editar información/foto → gestionar alergias, enfermedades o medicamentos → actualizar contactos de emergencia y representante cuando aplique → guardar.
- **Decisiones y resultado:** datos inválidos o accesos no autorizados se rechazan. Ver un perfil básico no concede automáticamente acceso a todos los datos sensibles. Una lista vacía de salud no prueba una declaración explícita de ausencia de condiciones.
- **Canales/evidencia:** **D/C**, app y endpoints de perfil; no se comprobó paridad de todos los subrecursos administrativos. Un representante registrado no implica que exista una cuenta vinculada con portal de tutores.
- **Para explicar:** “El perfil acompaña a la persona; sus datos sensibles no se vuelven públicos por pertenecer al club”. [Fuentes: auth](../../features/auth.md), [API, users/emergency/legal](../../api/ENDPOINTS-LIVE-REFERENCE.md).

<a id="f12"></a>
### 12 · Cambiar contexto de sección o responsabilidad activa

- **Objetivo e inicio:** una persona tiene varias asignaciones válidas y necesita operar en otra sección.
- **Actores:** usuario y sistema de autorización.
- **Recorrido:** consultar contextos disponibles → seleccionar asignación → validar vigencia/estado → guardar contexto activo → recargar datos y capacidades correspondientes.
- **Decisiones y resultado:** una asignación inactiva, terminada, futura o de otro año no habilita operación. Un corte anual pendiente puede bloquear temporalmente el cambio.
- **Canales/evidencia:** **D/C**, cambio móvil y contrato API documentados; no inferir que todas las pantallas administrativas tengan el mismo selector. Cambiar contexto no concede un cargo nuevo.
- **Para explicar:** “La misma persona puede tener varias responsabilidades, pero cada operación debe conservar su contexto”. [Fuentes: auth](../../features/auth.md), [roles y contexto](03-roles-permisos-contexto.md).

<a id="f13"></a>
### 13 · Proteger la sesión y revisar dispositivos

- **Objetivo e inicio:** el usuario quiere reforzar o recuperar el control de su acceso.
- **Actores:** titular de la cuenta y autenticación.
- **Recorridos independientes:** consultar sesiones → cerrar una u otras sesiones; configurar MFA → confirmar código → verificarlo cuando el contrato lo exija; activar bloqueo biométrico local en la app con sesión existente.
- **Decisiones y resultado:** código incorrecto no completa verificación; revocar sesión elimina ese acceso. La biometría protege la app local, no crea ni restaura una sesión backend por sí misma.
- **Canales/evidencia:** **P/C**, contratos de sesiones/MFA y bloqueo móvil documentados. La documentación del panel declara que no tiene UI de MFA, OAuth ni gestión de sesiones; verificar las pantallas disponibles antes de una demo.
- **Para explicar:** “Cerrar una sesión, usar segundo factor y bloquear la app con biometría son protecciones distintas”. [Fuente: autenticación](../../features/auth.md).

<a id="f14"></a>
### 14 · Exportar datos propios o eliminar la cuenta

- **Objetivo e inicio:** el titular desea obtener una copia de sus datos o dejar de utilizar su cuenta.
- **Actores:** titular y sistema.
- **Dos ramas independientes:** exportación: solicitar → consultar estado → descargar cuando esté lista; eliminación: confirmar explícitamente → solicitar eliminación → revocar sesiones y limpiar acceso local.
- **Decisiones y resultado:** exportar no elimina nada; no exige eliminar después. La eliminación documentada desactiva y anonimiza datos personales, no promete borrar de inmediato toda la historia institucional.
- **Canales/evidencia:** **D/V**, eliminación descrita en app; exportación localizada en Ajustes → descargar mis datos: solicitar, consultar preparación y abrir descarga externa. Puede pedir confirmación biométrica si está habilitada. Las descargas requieren autorización del titular. Ver [recorridos localizados](#pantallas-verificadas); no se descargaron datos reales.
- **Para explicar:** “Obtener una copia y eliminar una cuenta son decisiones separadas; la eliminación tiene efectos específicos sobre identidad e historial”. [Fuentes: auth](../../features/auth.md), [API, data-export](../../api/ENDPOINTS-LIVE-REFERENCE.md).

## D. Organización institucional

<a id="f15"></a>
### 15 · Crear un club y habilitar sus secciones

- **Objetivo e inicio:** la institución necesita registrar un club dentro de su estructura territorial.
- **Actores:** administración autorizada y dirección con permisos de mantenimiento.
- **Recorrido:** identificar campo/distrito/iglesia → registrar club → mantener Guías Mayores habilitada y elegir si también operan Aventureros/Conquistadores → crear las secciones del catálogo → completar datos operativos → mantener las secciones según autorización.
- **Decisiones y resultado:** **Guías Mayores debe permanecer activa**; AV/CQ son opcionales. Con catálogo válido, el backend incorpora GM aunque no venga seleccionada y rechaza desactivar su sección. No se duplican secciones del mismo tipo. Las secciones no tienen nombre libre: se presentan como nombre de club + tipo.
- **Canales/evidencia:** **D/V**, panel documentado para altas y mantenimiento; verificados `create` y `updateSection` del backend el 2026-09-22. App para contexto/consulta y operaciones permitidas. Crear el club no equivale a aprobar su matrícula anual ni a inscribir personas.
- **Límite de consistencia:** si el catálogo activo no contiene el tipo GM, el alta inspeccionada no lo agrega ni rechaza explícitamente esa ausencia cuando hay otro tipo seleccionado. Es una brecha respecto de la regla, no una excepción de negocio autorizada; no se corrigió código en esta actualización.
- **Para explicar:** “El club mantiene la identidad institucional; Guías Mayores es su sección obligatoria y Aventureros/Conquistadores se habilitan según su operación”. [Fuentes: gestión de clubes](../../features/gestion-clubs.md), [servicio de clubes](../../../sacdia-backend/src/clubs/clubs.service.ts).

<a id="f16"></a>
### 16 · Inscribir anualmente la sección como unidad institucional

- **Objetivo e inicio:** una sección necesita su matrícula del periodo, distinta de las inscripciones de personas.
- **Actores:** actor de sección con permiso de creación y revisor de campo local.
- **Recorrido:** registrar matrícula anual de sección → queda pendiente de validación → campo consulta su bandeja → aprueba o rechaza → al aprobar se activa la matrícula.
- **Decisiones y resultado:** la matrícula activa sirve de contexto para informes y carpeta anual. Si hay plantilla publicada, el sistema intenta crear la carpeta; si no, la ausencia de plantilla no debe describirse como inscripción de personas ni como carpeta ya creada.
- **Canales/evidencia:** **D/C**, API y revisión administrativa documentadas; entrada exacta de creación móvil pendiente de comprobación en esta síntesis.
- **Para explicar:** “Inscribir la sección, inscribir a un miembro e inscribirlo en una clase son tres registros distintos”. [Fuentes: carpeta anual](../../features/annual-folders-scoring.md), [API, club-enrollments](../../api/ENDPOINTS-LIVE-REFERENCE.md).

<a id="f17"></a>
### 17 · Nombrar, reemplazar o programar un director

- **Objetivo e inicio:** cubrir una vacante actual, reemplazar dirección vigente o preparar el siguiente periodo.
- **Actores:** autoridad administrativa/territorial con permisos y alcance.
- **Tres ramas:** sin director actual → asignación inicial; reemplazo actual → cerrar asignación vigente y nombrar sustituto del mismo año; próximo año → crear o actualizar un plan de sucesión futura.
- **Decisiones y resultado:** un plan futuro no destituye al director actual ni concede permisos hoy. Al corte se intenta activar el plan; conflictos como puesto ocupado requieren atención, no asumir activación exitosa.
- **Canales/evidencia:** **D/P**, preelección expuesta en panel; la ficha señala huecos en interfaz de sustitución actual y cancelación del plan. No equiparar contrato existente con botones conectados.
- **Para explicar:** “Nombrar para el próximo año no es sustituir a quien dirige hoy”. [Fuente: corte y sucesión](07-inscripcion-anual.md).

<a id="f18"></a>
### 18 · Solicitar y revisar una asignación institucional de cargo

- **Objetivo e inicio:** un actor privilegiado solicita asignar un rol a una persona mediante revisión.
- **Actores:** solicitante institucional y revisor autorizado.
- **Recorrido:** crear solicitud de asignación → consultar estado/detalle → revisar → aprobar o rechazar → aplicar efectos conforme a las reglas del módulo de cargos.
- **Decisiones y resultado:** rechazo no concede el cargo; aprobación no evita las reglas de cupo, contexto y vigencia. No es autoservicio del miembro ni la aprobación de ingreso inicial.
- **Canales/evidencia:** **D/C**, API y bandeja administrativa documentadas; no se comprobó aquí la cobertura móvil.
- **Para explicar:** “Pedir un cargo y recibirlo son actos diferentes; la solicitud tiene su propia revisión”. [Fuente: solicitudes institucionales](../../canon/runtime-requests.md).

<a id="f19"></a>
### 19 · Solicitar traslado entre secciones o clubes

- **Objetivo e inicio:** un miembro necesita cambiar su pertenencia institucional.
- **Actores:** solicitante y dirección receptora/autoridad con alcance de revisión.
- **Recorrido:** indicar destino y origen cuando corresponda → registrar motivo → enviar solicitud → receptor autorizado revisa → aprobar o rechazar → resolver efectos de membresía y clase conforme al destino.
- **Decisiones y resultado:** rechazo no ejecuta el traslado. Aprobar no significa copiar indiscriminadamente cargos ni elegir cualquier clase. El historial completo de todos los cambios de vinculación sigue siendo una limitación documental.
- **Canales/evidencia:** **D/C**, canon y API de transferencias, bandeja administrativa; sin ensayo integral en esta entrega.
- **Para explicar:** “Cambiar de club requiere un traslado institucional, no crear otra identidad”. [Fuentes: solicitudes](../../canon/runtime-requests.md), [clases y transferencias](../../features/clases-progresivas.md).

<a id="f20"></a>
### 20 · Organizar zonas y asignaciones de coordinación

- **Objetivo e inicio:** un campo local necesita distribuir la supervisión de sus secciones.
- **Actores:** administración territorial autorizada y coordinadores asignados.
- **Recorrido:** crear zonas → asociar distritos → asignar coordinación general, por zona/tipo o directamente a sección → resolver alcance → coordinador consulta y atiende procesos permitidos.
- **Decisiones y resultado:** no se debe coordinar la misma sección que se dirige; las asignaciones determinan el alcance real. Ser coordinador no concede autoridad automática sobre todo el campo ni aprobaciones de camporee.
- **Canales/evidencia:** **P**, documento en implementación, con panel de asignaciones y hub móvil descritos. Coberturas agregadas y datos heredados tienen límites.
- **Para explicar:** “El rol permite coordinar; la asignación define a quién puede supervisar”. [Fuente: coordinación](../../features/coordinacion.md).

<a id="f21"></a>
### 21 · Cierre administrativo del año y corte operativo

- **Objetivo e inicio:** concluir un periodo y habilitar la operación del siguiente sin borrar el pasado.
- **Actores:** administración autorizada y procesos programados del sistema.
- **Dos procesos distintos:** cierre administrativo: consultar impacto → decidir ejecutar cierre; corte operativo: detectar periodo vigente → cerrar cargos vencidos → procesar sucesores → dejar pertenencias por confirmar.
- **Decisiones y resultado:** el corte no ejecuta automáticamente el endpoint de cierre ni inscribe a todos. Los efectos concretos del cierre deben revisarse en su vista previa; no prometer que liquida toda obligación o vence toda clase.
- **Canales/evidencia:** **D/V**, cierre web localizado en `/dashboard/year-end`: seleccionar año → vista previa → confirmar cierre → consultar resultado. El corte sigue siendo otro proceso. No se ejecutaron cierres ni se verificaron cron o entorno real.
- **Para explicar:** “Cerrar el año, cambiar cargos e inscribir a quienes continúan son procesos coordinados, pero separados”. [Fuentes: ficha anual](07-inscripcion-anual.md), [API, year-end](../../api/ENDPOINTS-LIVE-REFERENCE.md).

## E. Operación de la sección

<a id="f22"></a>
### 22 · Planificar actividades, series y actividades conjuntas

- **Objetivo e inicio:** la directiva necesita programar reuniones o actividades.
- **Actores:** organizador autorizado y secciones participantes.
- **Recorrido:** definir actividad, fecha, modalidad y lugar → elegir sección → guardar → consultar calendario → editar o desactivar cuando corresponda.
- **Variantes y resultado:** repetición genera sesiones con fechas propias; editar una no modifica sus hermanas. Conjunta vincula varias secciones a una actividad; no es recurrencia. Puede extenderse una serie o cancelarse sus sesiones futuras por el flujo previsto.
- **Canales/evidencia:** **D**, app/panel; la captura conjunta móvil está documentada. Una actividad creada no prueba realización, asistencia ni aprobación de requisitos.
- **Para explicar:** “El calendario dice qué se planea; la asistencia registra quién participó”. [Fuentes: actividades](../../features/actividades.md), [conjuntas](../../features/actividades-conjuntas.md).

<a id="f23"></a>
### 23 · Identificar miembros y registrar asistencia por QR o panel

- **Objetivo e inicio:** una actividad requiere registrar participantes reales.
- **Actores:** miembro que presenta identificación y responsable autorizado que registra.
- **Recorrido:** abrir actividad → miembro muestra su QR/credencial → responsable valida identificación → registra asistencia → consulta listado. El panel ofrece captura por el contrato de asistencia.
- **Decisiones y resultado:** identificar no siempre equivale a registrar asistencia: depende de la acción usada. El miembro no se da asistencia a sí mismo mediante un botón de confirmación. No asumir una única captura unificada para todas las secciones de una actividad conjunta.
- **Canales/evidencia:** **D/C**, app QR, asistencia administrativa y contrato de credencial/PDF. La autorización y validez del QR se verifican en servidor.
- **Para explicar:** “El QR identifica; una persona autorizada registra la participación”. [Fuentes: actividades](../../features/actividades.md), [API, qr](../../api/ENDPOINTS-LIVE-REFERENCE.md).

<a id="f24"></a>
### 24 · Capturar la planilla semanal de una unidad

- **Objetivo e inicio:** registrar puntajes por categorías para miembros de una unidad en la semana vigente.
- **Actores:** responsable autorizado de la unidad/sección.
- **Recorrido:** abrir unidad → cargar categorías del campo y miembros activos → registrar puntos o respuestas sí/no según categoría → guardar planilla → consultar totales.
- **Decisiones y resultado:** se validan pertenencia, máximos y semana; un lote móvil inválido no se guarda parcialmente. Semanas anteriores están cerradas a edición por este flujo.
- **Canales/evidencia:** **D**, app con planilla y panel con captura. Semana domingo–sábado, hora México. No equivale a la lista de asistencia de una actividad ni al puntaje de camporee.
- **Para explicar:** “La planilla resume el desempeño semanal del grupo mediante categorías definidas”. [Fuente: registros semanales](../../features/weekly-records.md).

<a id="f25"></a>
### 25 · Calcular y consultar el miembro del mes

- **Objetivo e inicio:** reconocer el mayor puntaje semanal acumulado de una sección en un mes.
- **Actores:** sistema, miembros y directiva; actor autorizado para evaluación manual cuando se use API.
- **Recorrido:** capturar planillas → evaluar periodo → determinar máximo y posibles empates → guardar resultados → consultar ganadores/historial y notificaciones.
- **Decisiones y resultado:** puede haber varios ganadores; sin datos no se inventa uno. Una reevaluación puede sustituir el resultado del periodo. Las semanas se atribuyen al mes del sábado que las cierra.
- **Canales/evidencia:** **D/P**, consulta app/panel y cron documentados; evaluación manual por API sin interfaz conectada certificada en las fichas.
- **Para explicar:** “El reconocimiento se calcula con los registros semanales; no es una votación ni una maestría”. [Fuente: miembro del mes](../../features/member-of-month.md).

<a id="f26"></a>
### 26 · Registrar finanzas y consultar cierres de periodo

- **Objetivo e inicio:** una persona autorizada necesita registrar un ingreso o egreso del club.
- **Actores:** tesorería/dirección autorizadas y sistema.
- **Recorrido:** elegir tipo y categoría → capturar monto, fecha y descripción → adjuntar comprobantes cuando corresponda → guardar → consultar movimientos y resumen → conservar cierre del periodo según reglas del sistema.
- **Decisiones y resultado:** corrección/desactivación respeta autorización y periodos. Una foto de comprobante no cambia por sí misma el saldo ni reabre un mes cerrado. El cierre programado y el resumen acumulado no deben confundirse con saldo exclusivamente mensual.
- **Canales/evidencia:** **D**, app/panel; no se auditaron cifras reales. No asumir que todas las órdenes de otros dominios crean automáticamente movimientos en tesorería.
- **Para explicar:** “Se documenta cada movimiento y se consulta el saldo con contexto del periodo”. [Fuentes: finanzas](../../features/finanzas.md), [automatización](../../features/cron-automation.md).

<a id="f27"></a>
### 27 · Mantener el inventario de bienes de la sección

- **Objetivo e inicio:** registrar o actualizar equipamiento de la sección.
- **Actores:** responsable con permisos de inventario.
- **Recorrido:** seleccionar sección/categoría → registrar artículo, cantidad, condición y evidencia fotográfica → consultar → actualizar cuando cambie → desactivar al darlo de baja → consultar historial disponible.
- **Decisiones y resultado:** los bienes quedan asociados a su sección y se conserva auditoría técnica. La baja no implica borrado físico de toda la historia.
- **Canales/evidencia:** **D**, app/panel; no es un sistema de préstamos/devoluciones ni asignación de equipos a actividades. Esas capacidades están declaradas como pendientes.
- **Para explicar:** “El inventario permite saber qué tiene la sección; no gestiona todavía toda la logística de préstamo”. [Fuente: inventario](../../features/inventario.md).

<a id="f28"></a>
### 28 · Gestionar seguros, pagos y reasignaciones

- **Objetivo e inicio:** una sección necesita cobertura para miembros elegibles.
- **Actores:** directiva emisora y revisor autorizado de campo local.
- **Recorrido con órdenes:** elegir ciclo/producto y beneficiarios → emitir orden → consultar instrucciones/PDF → realizar pago fuera del sistema → subir comprobante → campo revisa → aprobación materializa coberturas.
- **Variantes y resultado:** comprobante rechazado permite corrección; el cargador no aprueba su propio comprobante. Reasignar cobertura entre miembros del mismo club requiere solicitud y revisión de campo. La vía directa de registro de póliza sigue documentada; el camino visible depende de configuración.
- **Excepciones verificadas:** una orden territorial emitida o con comprobante rechazado puede cancelarse por un actor autorizado de su alcance. Una orden aprobada no admite esa transición. Revertir una compra de cupos de seguro pertenece al circuito legacy y exige compra confirmada sin cupos usados/no disponibles; no es una devolución automática ni el mecanismo para anular una orden nominada aprobada. Ver [casos E1–E2](#excepciones).
- **Canales/evidencia:** **D/P**, app/panel; distinguir orden emitida, comprobante recibido y cobertura activa. No garantizar historial completo ni notificaciones de vencimiento en todas las superficies.
- **Para explicar:** “Solicitar seguro no basta: debe quedar registrada una cobertura vigente y aplicable”. [Fuente: seguros](../../features/gestion-seguros.md).

<a id="f29"></a>
### 29 · Pedir, pagar y recibir materiales generales del campo

- **Objetivo e inicio:** un usuario autorizado necesita productos del catálogo de materiales de su campo.
- **Actores:** solicitante, responsable de existencias, aprobador de pedido, validador de comprobante y responsable de entrega.
- **Recorrido:** consultar catálogo → crear pedido → campo revisa disponibilidad → aprobar pedido y afectar existencias → subir comprobante → validar pago → marcar entrega.
- **Decisiones y resultado:** comprobante rechazado no marca pagado; entrega exige estado pagado. El solicitante autorizado puede cancelar su pedido en revisión; después de aprobado o pagado se requiere autoridad de aprobación. Se exige motivo. Cancelar un pedido aprobado restaura existencias; si estaba pagado, además deja devolución pendiente, no reembolso automático. Entregado y cancelado son terminales. Ver [caso E3](#excepciones).
- **Canales/evidencia:** **V/P**, app con catálogo, carrito, resumen, historial, detalle y carga de comprobante; panel con bandeja, detalle, comprobantes y acciones de aprobación/entrega. Conexiones localizadas en código, no ensayadas con cuentas reales. Requiere sección/contexto válido. Es distinto de recursos digitales, inventario de la sección y mercancía de camporee.
- **Para explicar:** “El pedido, la comprobación del pago y la entrega son confirmaciones diferentes”. [Fuente: API, Materials](../../api/ENDPOINTS-LIVE-REFERENCE.md).

## F. Camporees

<a id="f30"></a>
### 30 · Configurar un camporee local o de unión

- **Objetivo e inicio:** el organizador territorial prepara un evento institucional.
- **Actores:** autoridad organizadora autorizada.
- **Recorrido:** elegir alcance local/unión → registrar datos, lugar y fechas → definir participantes territoriales/tipos → establecer plazos de clubes, personas y pagos → configurar visibilidad de agenda y condiciones operativas.
- **Decisiones y resultado:** un evento local y uno de unión son registros con alcance distinto. Estar creado no significa que todas sus inscripciones ya estén abiertas o que agenda y puntajes sean visibles.
- **Canales/evidencia:** **D/P**, panel de gestión y app de consulta; configuración real del entorno pendiente de ensayo.
- **Para explicar:** “El organizador define qué evento es, quién participa y en qué plazos”. [Fuente: camporees](11-camporees.md).

<a id="f31"></a>
### 31 · Inscribir una sección a un camporee

- **Objetivo e inicio:** el director quiere que su sección participe en un evento compatible.
- **Actores:** director de la sección activa y autoridad revisora cuando aplique.
- **Recorrido:** consultar evento → validar tipo y ventana → inscribir sección → quedar registrada a tiempo o pendiente de aprobación tardía → consultar estado.
- **Decisiones y resultado:** ventana no abierta o cierre manual impiden la operación. Inscribir sección no crea asistentes. El cierre de clubes delimita las secciones que podrán competir.
- **Canales/evidencia:** **D**, inscripción móvil y supervisión administrativa documentadas.
- **Para explicar:** “Primero participa la sección; después se registra a cada persona”. [Fuente: camporees](11-camporees.md).

<a id="f32"></a>
### 32 · Inscribir personas y comprobar el pago de camporee

- **Objetivo e inicio:** una sección ya inscrita necesita registrar asistentes con cobertura aplicable.
- **Actores:** director/emisor autorizado y revisor de campo local.
- **Recorrido con órdenes habilitadas:** elegir beneficiarios elegibles → verificar cobertura y costo → emitir orden → pagar fuera del sistema → subir comprobante → aprobación de campo → crear asistentes aprobados.
- **Variante y resultado:** con la función de órdenes deshabilitada existe registro directo legado bajo sus reglas. No mezclar los dos caminos en una demo. En camporee de unión, el cobro documentado pasa por campo; no hay transferencia bancaria automática campo→unión.
- **Canales/evidencia:** **D/P**, app y bandeja administrativa; depende de configuración territorial. El comprobante cargado no equivale a pago aprobado ni a asistentes creados.
- **Para explicar:** “La lista de asistentes debe reflejar inscripción, cobertura y validaciones del camino de pago activo”. [Fuente: camporees](11-camporees.md).

<a id="f33"></a>
### 33 · Resolver inscripciones o pagos tardíos de camporee

- **Objetivo e inicio:** una operación llega fuera del plazo ordinario y requiere excepción institucional.
- **Actores:** autoridad con permiso de aprobación tardía y alcance correspondiente.
- **Recorrido:** consultar pendientes → revisar sección, miembro o pago → aprobar o rechazar con motivo según el proceso → actualizar estado → consultar resultado.
- **Decisiones y resultado:** aprobación habilita continuar cuando las demás condiciones se cumplen; rechazo no equivale a registro confirmado. Los niveles de campo/unión dependen del tipo de evento y solicitud.
- **Canales/evidencia:** **D/P**, bandejas administrativas descritas. El rol de coordinador de evidencias no concede esta autoridad; tampoco se garantiza push para cada decisión.
- **Para explicar:** “Llegar tarde no da aprobación automática; requiere una decisión de la autoridad del evento”. [Fuentes: ficha camporees](11-camporees.md), [aprobaciones](../../features/aprobaciones-camporees.md).

<a id="f34"></a>
### 34 · Organizar agenda, sedes y personal del camporee

- **Objetivo e inicio:** el evento necesita programa, espacios y responsables.
- **Actores:** organizadores, personal operativo y participantes con acceso.
- **Recorrido:** configurar eventos/bloques y sedes → asignar personal → ajustar horarios y visibilidad → participantes consultan agenda y eventos disponibles.
- **Decisiones y resultado:** la agenda incluye más que competencias; la pestaña de eventos puntuables no representa todo el programa. Plantillas clonadas e instancias se mantienen separadas. Personal de apoyo no equivale a juez con capacidad de puntuar.
- **Canales/evidencia:** **D/C**, panel de organización, app de agenda; sedes identificadas además en contrato. No se certifica transporte, hospedaje ni logística integral.
- **Para explicar:** “La agenda organiza el tiempo y los responsables; las competencias tienen evaluación propia”. [Fuentes: camporees](11-camporees.md), [API, camporee-venues/staff/events](../../api/ENDPOINTS-LIVE-REFERENCE.md).

<a id="f35"></a>
### 35 · Evaluar competencias y publicar resultados oficiales

- **Objetivo e inicio:** un evento puntuable tiene secciones participantes definidas.
- **Actores:** organizador, juez principal y autoridades de excepción autorizadas.
- **Recorrido:** cerrar inscripción de clubes → configurar rúbricas y jueces → juez principal evalúa por sección/evento → enviar resultado → consultar clasificación oficial.
- **Decisiones y resultado:** no se puntúa por ser personal del evento; un juez auxiliar no tiene automáticamente capacidad de envío. Reabrir inscripción está limitado cuando existen jueces/puntajes. No se inventa un promedio entre jueces.
- **Canales/evidencia:** **D/P**, app de juez y panel descritos; confirmar disponibilidad por versión. Inscripción y asistencia no son puntajes; los resultados oficiales y su contribución al ranking anual se leen bajo configuración propia, no por el hecho de inscribirse.
- **Para explicar:** “La competencia produce un resultado oficial mediante rúbricas y un responsable autorizado”. [Fuentes: camporees](11-camporees.md), [ranking anual](../../features/annual-folders-scoring.md).

<a id="f36"></a>
### 36 · Pedir mercancía nominada para participantes de camporee

- **Objetivo e inicio:** una sección inscrita necesita artículos para asistentes elegibles.
- **Actores:** emisor de sección, campo que revisa/cobra y director que distribuye.
- **Recorrido documentado:** elegir oferta y talla por asistente inscrito → emitir pedido independiente → pagar/comprobar → revisar → entregar a sección → director registra entrega a cada miembro.
- **Decisiones y resultado:** entrega al club no prueba entrega a todas las personas. Correcciones y ampliaciones usan cancelación/reemisión o pedido suplementario según estado. No comparte pago/folio con inscripción.
- **Canales/evidencia:** **P**, documento ubica implementación en rama y migraciones no desplegadas en su corte. No se comprobó integración posterior; no presentarlo como disponible por defecto en el entorno actual.
- **Para explicar:** “Los artículos del evento se piden y distribuyen aparte de la inscripción”. [Fuente: pedidos de camporee](../../features/camporee-orders.md).

<a id="f37"></a>
### 37 · Planificar, pagar y recibir insumos de camporee

- **Objetivo e inicio:** una sección inscrita necesita insumos de cocina por día y horario.
- **Actores:** dirección/secretaría de sección y responsables de caja/entrega del campo.
- **Recorrido documentado:** seleccionar productos, días y horarios → armar plan → enviar y emitir obligación principal → registrar pago → recibir entregas parciales → ajustar días abiertos con cargos/devoluciones separados.
- **Decisiones y resultado:** días congelados no se editan libremente; excepciones requieren autorización y motivo. La entrega es a la sección, no nominada a cada miembro; el contrato no exige pago principal completo como condición universal de entrega.
- **Canales/evidencia:** **P**, desarrollo documentado en otra rama, sin despliegue certificado. No confundir con mercancía ni con inventario general.
- **Para explicar:** “Se programa lo que recibirá la sección cada día y se conservan los ajustes y entregas”. [Fuente: insumos](../../features/camporee-supplies.md).

## G. Rendición y supervisión

<a id="f38"></a>
### 38 · Preparar y enviar el informe mensual

- **Objetivo e inicio:** una sección con matrícula anual necesita informar un mes de operación.
- **Actores:** dirección/secretaría y supervisores territoriales autorizados.
- **Recorrido:** consultar vista previa calculada → completar datos manuales en borrador → generar instantánea/PDF → esperar generación → enviar formalmente → supervisores consultan cobertura y documento.
- **Decisiones y resultado:** borrador, generado y enviado son estados distintos. Campo/unión no tienen un paso de aprobar/rechazar ese informe en el contrato descrito. Recordatorios/generación automática dependen de configuración.
- **Canales/evidencia:** **D/P**, app/panel, con diferencias documentadas entre campos de formularios y contrato. No usar una plantilla visual local como si fuera un informe generado real.
- **Para explicar:** “El informe congela lo reportado del mes y lo pone a disposición de la supervisión”. [Fuente: supervisión](12-supervision-institucional.md).

<a id="f39"></a>
### 39 · Consolidar informes trimestrales y anuales

- **Objetivo e inicio:** existe un informe de periodo mayor que necesita revisión o consulta.
- **Actores:** administración con permisos de edición y usuarios con lectura/descarga de su alcance.
- **Recorrido contractual:** listar y abrir informe → actualizar datos manuales cuando corresponda → regenerar calculados → finalizar → consultar o descargar PDF.
- **Decisiones y resultado:** consultar no permite editar; finalizar no debe interpretarse como el mismo acto que aprobar una carpeta anual. El mecanismo exacto de creación inicial y todas las restricciones por estado no se auditaron en esta síntesis.
- **Canales/evidencia:** **V/C**, panel → detalle del club → pestaña de informes muestra tablas anuales/trimestrales. Esa pantalla no demuestra edición, regeneración, finalización ni descarga: esas operaciones permanecen verificadas solo por contrato. Una lista vacía tampoco prueba ausencia de informes, porque la carga revisada convierte errores en listas vacías. Ver [recorridos localizados](#pantallas-verificadas).
- **Para explicar:** “Los cortes trimestrales y anuales tienen documentos propios, no son una carpeta de evidencias”. [Fuente: API, annual-reports/quarterly-reports](../../api/ENDPOINTS-LIVE-REFERENCE.md).

<a id="f40"></a>
### 40 · Construir, evaluar y confirmar la carpeta anual

- **Objetivo e inicio:** una sección tiene matrícula activa y plantilla anual publicada aplicable.
- **Actores:** dirección/secretaría/subdirección para carga; campo local para evaluación; unión cuando el expediente lo requiere.
- **Recorrido:** crear/obtener carpeta → cargar evidencias por apartado → enviar apartados → campo evalúa → validar directamente o preaprobar para confirmación de unión → consultar puntos; enviar carpeta completa cuando cumpla requisitos.
- **Decisiones y resultado:** se puede evaluar un apartado enviado mientras otros siguen en carga. Solo apartados validados suman; rechazo aporta cero. La confirmación de unión no aplica a todas las carpetas. Correcciones/reaperturas dependen del estado y autoridad, no de edición libre del club.
- **Canales/evidencia:** **D/P**, operación de club y evaluación administrativa documentadas; no prometer evaluación desde app. El antiguo módulo de carpetas fue retirado.
- **Para explicar:** “Es el expediente anual de la sección, no el expediente individual de una clase”. [Fuentes: carpeta anual](../../features/annual-folders-scoring.md), [supervisión](12-supervision-institucional.md).

<a id="f41"></a>
### 41 · Calcular y consultar clasificaciones institucionales y personales

- **Objetivo e inicio:** se necesita visualizar desempeño según criterios y periodo configurados.
- **Actores:** administración que configura, sistema que calcula y lectores autorizados.
- **Recorrido:** definir configuración del año/alcance → registrar datos en dominios fuente → calcular o recalcular → consultar puntaje y desglose → interpretar pendientes y reconocimiento.
- **Variantes y resultado:** clasificación anual institucional, ranking de miembros y agregado por sección son lecturas distintas. La app documenta progreso anual de su propia sección; el panel tiene comparativas autorizadas. Miembro del mes es otro cálculo.
- **Canales/evidencia:** **D/C**, documentos y API; no se auditaron todas las fórmulas ni cifras reales. Configuraciones de un año no se clonan automáticamente al siguiente. Inscripción a camporee no equivale a puntos oficiales.
- **Para explicar:** “El puntaje necesita fuente, periodo y reglas; no es una cifra universal del club”. [Fuentes: ranking anual](../../features/annual-folders-scoring.md), [canon de rankings](../../canon/runtime-rankings.md).

<a id="f42"></a>
### 42 · Supervisar territorio y atender colas de trabajo

- **Objetivo e inicio:** una autoridad necesita detectar faltantes, cobertura y asuntos pendientes.
- **Actores:** autoridades territoriales, coordinadores o administradores según tablero.
- **Recorrido:** entrar con alcance válido → consultar indicadores → identificar una cola o entidad → abrir proceso correspondiente → actuar allí si tiene permiso → volver a consultar estado.
- **Decisiones y resultado:** dashboard operativo, tablero de campo y SLA no son intercambiables. Club activo en catálogo no equivale a sección operativa matriculada. Consultar indicadores no aprueba registros.
- **Canales/evidencia:** **D/P**, panel operativo y hub móvil. La ficha señala diferencias de datos en SLA móvil; no atribuir SLA a director-unión ni usar conteos de camporee como bandeja fiable de aprobación.
- **Para explicar:** “El tablero orienta la atención; cada decisión se toma en el flujo correspondiente”. [Fuente: supervisión institucional](12-supervision-institucional.md).

<a id="f43"></a>
### 43 · Resolver revisiones por lotes

- **Objetivo e inicio:** un revisor necesita atender varios registros compatibles sin repetir cada acción manualmente.
- **Actores:** revisor autorizado en el dominio y etapa.
- **Recorrido:** filtrar pendientes → seleccionar registros → elegir acción permitida → confirmar, agregando motivo si se rechaza → procesar → revisar resultados y fallos individuales según contrato.
- **Decisiones y resultado:** el lote no evita permisos, etapas ni requisitos. Evidencias deben ser del mismo tipo; investidura tiene acciones masivas específicas y no incluye aprobación de club en la ficha revisada. Importación de certificados tiene su propio lote.
- **Canales/evidencia:** **D/P**, contratos de evidencias/investiduras/importación; no se supone paridad UI ni que todo lote sea una transacción única.
- **Para explicar:** “Revisar en grupo ahorra pasos, pero conserva las reglas de cada registro”. [Fuentes: evidencias](../../features/validacion-evidencias.md), [investidura](08-clases-progresivas.md), [OCR](../../features/carga-masiva-certificados.md).

## H. Servicios transversales

<a id="f44"></a>
### 44 · Publicar y consultar recursos digitales

- **Objetivo e inicio:** una autoridad quiere distribuir materiales o un usuario necesita consultarlos.
- **Actores:** editor autorizado y usuarios dentro del alcance.
- **Recorrido:** crear categoría/recurso → adjuntar archivo, enlace o texto → definir territorio y tipo de club → publicar registro → usuario consulta → abre/reproduce/descarga según formato.
- **Decisiones y resultado:** territorio y tipo restringen visibilidad. Desactivar retira disponibilidad operativa; no implica borrar inmediatamente el archivo de almacenamiento. Editar metadatos no equivale a sustituir cualquier archivo por ese mismo endpoint.
- **Canales/evidencia:** **D**, panel de gestión y app de consumo. No es venta de materiales ni préstamo de inventario.
- **Para explicar:** “Los recursos son contenidos que llegan a las personas a quienes corresponde verlos”. [Fuente: recursos](../../features/recursos.md).

<a id="f45"></a>
### 45 · Enviar, recibir y consultar notificaciones

- **Objetivo e inicio:** una acción del sistema o un emisor autorizado necesita comunicar algo.
- **Actores:** emisor, sistema y destinatario.
- **Recorrido:** definir destinatario/alcance → enviar o producir evento soportado → registrar entrega en bandeja → intentar push cuando sea posible → usuario abre y marca leído → ajusta preferencias disponibles.
- **Decisiones y resultado:** ausencia de token o servicio push no implica necesariamente ausencia en bandeja. Los permisos para mensaje directo, global y de sección son diferentes. No todos los cambios de estado tienen notificación integrada.
- **Canales/evidencia:** **D/P**, envío/historial administrativo y bandeja móvil. No hay programación de mensajes futuros como producto ni fallback universal por SMS/correo.
- **Para explicar:** “La bandeja conserva los avisos; recibir un push depende también del dispositivo y la configuración”. [Fuente: comunicaciones](../../features/communications.md).

<a id="f46"></a>
### 46 · Reportar un problema y dar seguimiento administrativo

- **Objetivo e inicio:** un usuario autenticado necesita reportar un problema del sistema.
- **Actores:** usuario y equipo de soporte autorizado.
- **Recorrido móvil localizado:** Ajustes → soporte → reportar problema → elegir categoría y escribir título/descripción → enviar → recibir confirmación o error. La app agrega información de dispositivo y contexto. El hub también ofrece preguntas frecuentes y contacto.
- **Continuación contractual:** administración/coordinación autorizada consulta lista/detalle → investiga → actualiza estado. La confirmación móvil de recepción no confirma resolución.
- **Decisiones y resultado:** el reporte queda registrado y puede cambiar de estado. No se infieren chat, adjuntos, SLA contractual, notificación al resolver ni una bandeja personal completa si el contrato consultado no los demuestra.
- **Canales/evidencia:** **V/C**, alta móvil conectada a API localizada; no se localizó consumidor de la API administrativa de soporte en los clientes revisados. Seguimiento personal del ticket y aviso de resolución no acreditados. No se enviaron reportes reales.
- **Para explicar:** “Reportar un problema lo ingresa al circuito de atención; no significa que ya esté resuelto”. [Fuente: API, support/admin-support](../../api/ENDPOINTS-LIVE-REFERENCE.md).

<a id="f47"></a>
### 47 · Administrar usuarios, permisos, catálogos y reglas

- **Objetivo e inicio:** la institución necesita preparar o mantener los datos que habilitan la operación.
- **Actores:** administradores técnicos o territoriales autorizados para cada dominio.
- **Recorridos por objeto:** usuarios/acceso a app o panel; roles/permisos; estructura territorial; catálogos formativos y categorías; periodos; plantillas/versiones; precios, límites y configuraciones.
- **Secuencia común y resultado:** consultar contexto → crear o editar objeto permitido → validar dependencias/alcance → guardar o publicar si ese dominio lo requiere → consumidores usan configuración efectiva. No existe una aprobación universal común para todos los catálogos.
- **Canales/evidencia:** **D/C**, panel y API. Revisión excepcional de cuenta no es aprobación global obligatoria de cada persona ni aprobación de membresía. Configurar permisos requiere más autoridad que operar un club.
- **Para explicar:** “La administración mantiene las reglas y los datos base; no sustituye las decisiones de cada proceso”. [Fuentes: RBAC](../../features/rbac.md), [catálogos](../../features/catalogos.md), [API](../../api/ENDPOINTS-LIVE-REFERENCE.md).

<a id="f48"></a>
### 48 · Consultar historial y auditoría de operaciones

- **Objetivo e inicio:** una persona autorizada necesita explicar qué cambió, quién actuó y cuándo.
- **Actores:** lectores del historial de dominio y administración de auditoría global.
- **Recorrido:** seleccionar entidad/periodo → consultar eventos disponibles → abrir detalle permitido → contrastar con estado actual → atender inconsistencia mediante el flujo autorizado, no editando el log.
- **Decisiones y resultado:** historial de club y visor global tienen permisos distintos. El visor global documentado es de superadministración; no cualquier administrador o directivo accede a todos los detalles.
- **Canales/evidencia:** **P**, auditoría global y algunas historias de dominio implementadas, con cobertura parcial. Parte del registro es de mejor esfuerzo; existen exclusiones. No prometer trazabilidad perfecta ni captura de cada lectura.
- **Para explicar:** “La auditoría ayuda a reconstruir decisiones dentro de su cobertura; no reemplaza la revisión del proceso”. [Fuente: audit log](../../features/audit-log.md).

## I. Definición funcional pendiente de implementación

<a id="f49"></a>
### 49 · Solicitud colectiva y ceremonia de investidura

> **A — Acuerdo funcional, sin implementación acreditada.** Sí se incluye para explicar el proceso acordado; no se presenta como pantalla disponible. El [flujo individual 05](#f05) conserva su descripción actual. La compatibilidad y transición entre ambos siguen pendientes.

- **Objetivo e inicio:** el club prepara una ceremonia del año en curso con personas identificadas y sus clases; los conteos por clase se calculan desde esa lista, no sustituyen nombres.
- **Actores:** responsables del club, revisores del Campo Local, oficiante, pastor certificador y servicio automático. Los permisos concretos de creación, envío, aprobación inicial y configuración quedan por definir; coordinación no es una etapa de aprobación de esta solicitud.
- **Recorrido acordado:** identificar candidatos que cumplan requisitos → completar fecha/horario y responsables → enviar **directamente al Campo Local** → aprobar total o parcialmente → gestionar cambios dentro del plazo → finalizar la ceremonia → registrar automáticamente las investiduras de la lista aprobada vigente → consultar resultados individuales.

#### Decisiones y excepciones confirmadas

| Momento | Regla que debe explicarse |
|---|---|
| Preparar candidatos | Cada persona debe cumplir los requisitos de su clase; la elegibilidad de un compañero no habilita al grupo. El significado técnico de cumplimiento todavía requiere definición. |
| Identificar autoridades | Oficiante y pastor certificador son funciones distintas. «El oficiante también certifica» inicia activado y puede separarse. Se prioriza buscar usuarios SACDIA; como alternativa secundaria se capturan nombre completo, cargo y entidad de procedencia de personas sin cuenta. No crea cuentas ni permisos; no se acordaron correo/teléfono obligatorios. |
| Aprobar parcialmente | Campo Local puede excluir personas sin frenar al resto. Cada exclusión exige motivo y notificación con esa justificación al **director, subdirector, secretario y secretario-tesorero** del club: cuatro cargos destinatarios distintos. Los canales siguen pendientes. |
| Solicitar cambios | Antes del corte, el club puede solicitar altas, bajas y cambios. Una baja requiere aprobación del Campo Local; mientras esté pendiente o no aprobada, **no suspende una investidura ya autorizada**. Una incorporación aún no autorizada tampoco integra la lista aprobada. |
| Configurar y aplicar el corte | Cada Campo Local debe disponer de configuración del plazo de anticipación: **mínimo cinco días naturales**, incluidos fines de semana y festivos; puede ser mayor, sin máximo global acordado. Después del corte el club no modifica la lista; la excepción corresponde solo al **director o asistente del Campo Local**. No implica un plazo ya definido para el envío inicial. |
| Cerrar la ceremonia | Al terminar el horario, el servicio automático registra `INVESTIDO` **por persona y clase de la lista aprobada vigente**, sin exigir confirmación manual general posterior. No inviste a todos los integrantes del club/clase ni acredita asistencia por sí mismo. |
| Continuar el siguiente año | No celebrar la ceremonia anterior no debe bloquear por sí solo la continuidad anual. El cierre no inscribe automáticamente en la siguiente clase ni sustituye el [flujo 02](#f02). |

- **Resultado esperado:** reconocimiento individual trazable a la lista autorizada de la ceremonia, no una aprobación genérica de toda la sección.
- **Canales/evidencia:** **A**, acuerdos RF-01–RF-19 del documento funcional. Solicitud, revisión, seguimiento y configuración son superficies propuestas; su distribución entre app y panel y sus contratos no están definidos. No se acreditan endpoints, jobs ni notificaciones implementados para este nuevo proceso.
- **Pendientes antes de implementar:** hora/zona/cálculo exacto del corte; alcance por sección y número de ceremonias; ventanas y cambios de configuración; elegibilidad y clases multianuales; permisos y autoridades; entrega de notificaciones; cancelación/reprogramación/correcciones; transición del pipeline individual y manejo de fallos automáticos. Son P-01–P-08 del documento fuente, **no decisiones resueltas por esta guía**.
- **Para explicar:** “El club propone quiénes se investirán; Campo Local autoriza la lista y, según el diseño acordado, el sistema registrará esas investiduras al terminar la ceremonia”. [Fuente completa: acuerdos, pendientes y contraste con runtime](../../history/plans/2026-09-21-investiture-ceremony-functional-design.md).

<a id="excepciones"></a>
## Excepciones y correcciones que completan el recorrido

Estos casos amplían las familias existentes: **no agregan familias ni cambian su numeración**. Antes de actuar, identificar el objeto, su estado actual y quién tiene permiso. No existe un botón universal de “deshacer”. Las excepciones futuras de ceremonia se distinguen en el flujo 49.

### E1 · Cancelar una orden territorial de seguro o camporee — flujos 28 y 32

- **Inicio:** ya no se necesita una orden o debe reemplazarse antes de su aprobación.
- **Actor:** usuario con `field-payment-orders:cancel` y alcance válido de sección; el servicio contempla acceso global. Poder revisar pagos del campo no sustituye por sí solo el alcance requerido para cancelar.
- **Pasos:** abrir orden → comprobar folio, beneficiarios y estado → elegir cancelar si está disponible → confirmar → volver a consultar el estado.
- **Resultado permitido:** `ISSUED` o `PROOF_REJECTED` → `CANCELLED`. Se conserva la orden y se liberan los bloqueos de sus líneas (`active_guard`); una nueva emisión sigue sujeta a elegibilidad y validaciones.
- **Bloqueos:** con comprobante enviado (`PROOF_SUBMITTED`) o aprobada (`APPROVED`) no se cancela por esta transición. Si una orden emitida ya venció, el servicio puede marcarla `EXPIRED` al intentar operarla. No repetir la acción indefinidamente.
- **Evidencia:** **V**, [servicio, método `cancel`](../../../sacdia-backend/src/field-payment-orders/field-payment-orders.service.ts), [transiciones](../../../sacdia-backend/src/field-payment-orders/state-machine.ts), [controlador](../../../sacdia-backend/src/field-payment-orders/field-payment-orders.controller.ts) y [confirmación móvil](../../../sacdia-app/lib/features/payment_orders/presentation/views/payment_order_detail_view.dart).
- **Para explicar:** “Cancelar detiene esa orden; no devuelve dinero ni anula por sí solo una cobertura ya aprobada”.

### E2 · Revertir una compra confirmada de cupos de seguro — variante legacy del flujo 28

- **Inicio:** una compra de cupos confirmada necesita dejarse sin efecto. No confundirla con la orden territorial nominada del caso E1.
- **Actor:** revisor con `insurance:review` y alcance territorial válido.
- **Pasos:** identificar compra → comprobar que sigue `CONFIRMED` → verificar que todos sus cupos están `AVAILABLE` → ejecutar reversión autorizada → consultar compra y movimientos resultantes.
- **Resultado:** compra `REVERSED`, cupos disponibles `VOID` y movimientos `VOIDED` registrados. El método no ejecuta devolución bancaria.
- **Bloqueos:** si la compra no está confirmada o tiene cualquier cupo en un estado distinto de disponible, se rechaza la reversión. No se debe enseñar a retirar coberturas de personas para forzar esta operación.
- **Evidencia:** **V/C**, reglas de [reversión en backend](../../../sacdia-backend/src/insurance/insurance-purchases.service.ts) y [permiso en controlador](../../../sacdia-backend/src/insurance/insurance-purchases.controller.ts); no se localizó consumidor en los clientes admin/app revisados el 2026-09-16. Fuera de la demo de usuario final; su uso debe confirmarse con el circuito de seguro habilitado en el entorno.
- **Para explicar:** “Esta reversión invalida cupos todavía disponibles, no cualquier seguro activo”.

### E3 · Cancelar un pedido de materiales — flujo 29

- **Inicio:** un pedido no debe continuar. Abrir su detalle y comprobar estado antes de prometer una cancelación o devolución.
- **Actor y decisión:**

| Estado del pedido | Quién puede cancelar, además de los controles de acceso | Efecto verificado |
|---|---|---|
| En revisión | Creador del pedido o actor con autoridad de aprobación | Pasa a cancelado; aún no corresponde restaurar el stock descontado por aprobación. |
| Aprobado | Actor con `materiales:approve` | Pasa a cancelado y restaura existencias. |
| Pagado | Actor con `materiales:approve` | Restaura existencias y marca `refund_pending`; el dinero no se devuelve por esta operación. |
| Entregado o cancelado | Ninguno mediante esta transición | Estado terminal; se rechaza cancelar. |

- **Pasos:** abrir pedido → seleccionar cancelar → registrar motivo obligatorio → confirmar → consultar estado y, si estaba pagado, identificar devolución pendiente para atención administrativa. La gestión posterior del reembolso no se verificó como flujo automatizado.
- **Pantallas:** el panel muestra la acción a quien puede aprobar, con aviso específico para pedidos aprobados/pagados; el detalle móvil incluye cancelación según su estado. Que el backend permita una acción no implica que ambas interfaces la expongan igual.
- **Evidencia:** **V**, [servicio `cancel`](../../../sacdia-backend/src/materials/orders/orders.service.ts), [estados terminales](../../../sacdia-backend/src/materials/orders/state-machine.ts), [motivo requerido](../../../sacdia-backend/src/materials/orders/dto/cancel-order.dto.ts), [acciones del panel](../../../sacdia-admin/src/app/%28dashboard%29/dashboard/materials/request/%5Bfolio%5D/_components/order-sticky-bar.tsx) y [detalle móvil](../../../sacdia-app/lib/features/materials/presentation/views/order_review_view.dart).
- **Para explicar:** “Cancelar, devolver existencias y devolver dinero son efectos distintos”.

### E4 · Corregir después de un rechazo o solicitar reapertura

| Situación | Recorrido que debe explicarse | Límite |
|---|---|---|
| Comprobante territorial rechazado | Leer motivo → corregir comprobante → volver a subir → quedar nuevamente en revisión. También puede cancelarse si corresponde. | Reenviar no equivale a aprobar; el revisor debe decidir otra vez. **V**, transiciones de E1. |
| Evidencia formativa rechazada | Leer observación → corregir el trabajo/archivo → enviar de nuevo cuando sea editable → esperar revisión. | Depende de año, inscripción y estado. No desbloquea una investidura automáticamente. **D**, flujos 04–05. |
| Evaluación de apartado de carpeta anual que necesita reapertura | Actor autorizado reabre una evaluación validada, rechazada o preaprobada por campo → vuelve a `SUBMITTED` → se limpian decisiones y puntos → se evalúa de nuevo. | La carpeta debe estar abierta, en evaluación o evaluada. Se recalculan totales; una carpeta evaluada vuelve a evaluación. No es un retorno automático a borrador para editar archivos ni reapertura del año. **V**, reglas backend y acción web localizadas; demostración autenticada pendiente. |
| Inscripción de secciones a camporee cerrada | Organizador autorizado revisa necesidad → solicita reapertura local o de unión → si no hay registros activos de evaluación/competencia que la bloqueen, se retira el cierre del registro → se comprueban condiciones para continuar. | El servicio rechaza si encuentra registros activos mediante `countActiveScoringArtifacts`. No aprueba solicitudes tardías ni reabre pagos u otros plazos por sí solo. **V**, reglas backend y acción web localizadas; demostración autenticada pendiente. |

Las dos últimas filas tienen evidencia en [reapertura de evaluación](../../../sacdia-backend/src/annual-folders/evaluation.service.ts), método `reopenSection`, y [reapertura de inscripción local/unión](../../../sacdia-backend/src/camporees/camporees.service.ts), métodos `reopenLocalCamporeeClubRegistration` y `reopenUnionCamporeeClubRegistration`. Complemento de permisos: [referencia API](../../api/ENDPOINTS-LIVE-REFERENCE.md). Las acciones web también se localizaron el 2026-09-16: carpeta → apartado → Reabrir → confirmar, y detalle del camporee local/unión → reabrir inscripción → confirmar. Ver [rutas y evidencia de interfaces](16-verificacion-flujos-pendientes.md). Sigue pendiente probarlas con autorización efectiva y datos de prueba.

<a id="recuperacion"></a>
## Recuperación ante conexión interrumpida u operación sin confirmar

**Regla para todos los usuarios:** un error o una espera agotada no demuestra que el servidor no haya guardado. Antes de volver a crear, pagar o enviar, consultar el registro. Esta es una pauta segura de capacitación, **no una garantía técnica de ausencia de duplicados**.

| Qué observa la persona | Qué hacer | Resultado esperado o límite |
|---|---|---|
| No carga una lista o detalle | Recuperar conexión y usar reintentar/actualizar donde exista. | En listas y detalle de órdenes móviles se localizaron controles que vuelven a consultar. No se promete el mismo control en cada pantalla. |
| Pulsó guardar/enviar, pero no recibió confirmación | Evitar repetir de inmediato; volver al historial/detalle y comprobar estado, folio o comprobante. | Si aparece el registro, continuar desde él. Si no puede confirmar el resultado, reportar el caso antes de duplicar una operación sensible. |
| El registro aparece con el estado anterior | Actualizar y comprobar que se consulta la sección, año y registro correctos. | Puede haber datos conservados en caché o una operación todavía en proceso; una lectura antigua no prueba rechazo. |
| Se perdió la sesión | Volver a autenticarse si el sistema lo solicita y consultar el estado de la operación antes de reenviar. | Hay recuperación de token en el cliente móvil, pero no es garantía de conservar formularios ni de recuperar toda solicitud. |
| Se deniega una acción | Revisar contexto y pedir revisión de permisos al responsable. | Reintentar una y otra vez no otorga acceso ni cambia un estado terminal. |

**Comportamiento observado y lo que no se debe prometer:**

- El [interceptor móvil de reintentos](../../../sacdia-app/lib/core/network/dio_client.dart) limita sus reintentos de red a `GET`, `HEAD`, `DELETE` y `PUT`; excluye `POST` y `PATCH` en esa política. Eso no certifica que cada endpoint sea idempotente ni que toda petición use exactamente ese camino.
- La recuperación por sesión expirada es un mecanismo separado en [AuthInterceptor](../../../sacdia-app/lib/core/network/interceptors/auth_interceptor.dart); no debe confundirse con una cola de trabajo sin conexión.
- Se localizaron controles de recarga en [órdenes territoriales](../../../sacdia-app/lib/features/payment_orders/presentation/views/payment_orders_view.dart), [detalle de orden](../../../sacdia-app/lib/features/payment_orders/presentation/views/payment_order_detail_view.dart) e [historial de materiales](../../../sacdia-app/lib/features/materials/presentation/views/order_history_view.dart).
- El [canon de resiliencia](../../canon/runtime-resiliencia-red.md) distingue caché e invalidación de un sistema offline-first. Su corte es anterior a esta revisión: no se usa como prueba de cada detalle actual. **Esta guía no promete guardado sin conexión, envío posterior automático ni conservación universal de borradores.**

**Para explicar:** “Si no viste la confirmación, primero consulta qué quedó registrado; después decide si hace falta repetir”.

<a id="pantallas-verificadas"></a>
## Recorridos localizados en código y pendientes de demostración

Revisión estática del **2026-09-15**, ampliada el **2026-09-16** y, para continuidad anual, el **2026-09-22**. Las rutas ayudan a preparar una demostración; no sustituyen permisos ni aseguran que un menú esté visible para cualquier cuenta. La comprobación visual del panel local llegó al login; no se realizaron operaciones autenticadas ni se modificaron registros reales.

| Flujo y público | Recorrido localizado | Evidencia y límite |
|---|---|---|
| 02 · Directiva autorizada en panel | Detalle del club → secciones → continuidades → seleccionar personas elegibles → inscribir → consultar resultado. | [Montaje condicionado en sección](../../../sacdia-admin/src/components/clubs/detail/sections-tab.tsx), [bloque de selección y envío](../../../sacdia-admin/src/components/clubs/detail/annual-continuations-block.tsx). Localizado el 2026-09-22; muestra resultados de inscripción/trayectoria completa/bloqueos/fallos. Sin prueba autenticada ni garantía de despliegue. |
| 14 · Titular en app | Ajustes → descargar mis datos → solicitar → consultar preparación → abrir descarga. | [Entrada en ajustes](../../../sacdia-app/lib/features/profile/presentation/views/settings_view.dart), [pantalla de exportación](../../../sacdia-app/lib/features/profile/presentation/views/data_export_view.dart). Actualiza solicitudes en proceso y abre URL externa. No se probó preparación real ni descarga. |
| 21 · Administración autorizada | `/dashboard/year-end` → elegir año → vista previa → confirmación → resultado. | [Página](../../../sacdia-admin/src/app/%28dashboard%29/dashboard/year-end/page.tsx), [acciones de cierre](../../../sacdia-admin/src/components/year-end/year-end-client-page.tsx). No se ejecutó el cierre; no acredita el cron de corte anual. |
| 28/32 · Emisor de orden en app | Lista de órdenes → detalle → comprobante/PDF o cancelar según estado → confirmación. | [Lista](../../../sacdia-app/lib/features/payment_orders/presentation/views/payment_orders_view.dart), [detalle](../../../sacdia-app/lib/features/payment_orders/presentation/views/payment_order_detail_view.dart). La reversión legacy E2 no está acreditada por esta pantalla. |
| 29 · Solicitante en app | Catálogo → producto/carrito → resumen y entrega → confirmar → detalle/historial → datos de pago → comprobante. | [Catálogo](../../../sacdia-app/lib/features/materials/presentation/views/catalog_view.dart), [confirmación](../../../sacdia-app/lib/features/materials/presentation/views/order_summary_view.dart), [carga de comprobante](../../../sacdia-app/lib/features/materials/presentation/views/upload_receipt_view.dart). El alta toma la sección activa; no presentar como garantizado un pedido sin ese contexto. |
| 29 · Campo local autorizado | `/dashboard/materials/inbox` → pedido → resolver partidas/aprobar → revisar comprobantes → marcar entrega o cancelar si aplica. | [Bandeja](../../../sacdia-admin/src/app/%28dashboard%29/dashboard/materials/inbox/page.tsx), [detalle](../../../sacdia-admin/src/app/%28dashboard%29/dashboard/materials/request/%5Bfolio%5D/page.tsx), [acciones](../../../sacdia-admin/src/app/%28dashboard%29/dashboard/materials/request/%5Bfolio%5D/_components/order-sticky-bar.tsx). Capacidades separadas de aprobación, validación y entrega. |
| 39 · Lector autorizado del club | Detalle del club → pestaña informes → tablas anuales/trimestrales. | [Pestaña](../../../sacdia-admin/src/components/clubs/detail/reports-tab.tsx) y [carga](../../../sacdia-admin/src/app/%28dashboard%29/dashboard/clubs/%5Bid%5D/page.tsx). No contiene acciones de edición/finalización. La carga convierte errores en `[]`; una tabla vacía no garantiza inexistencia de informes. |
| 46 · Usuario de app | Ajustes → soporte → reportar problema → categoría, título y descripción → enviar → confirmación o error. | [Hub](../../../sacdia-app/lib/features/support/presentation/views/support_view.dart), [formulario](../../../sacdia-app/lib/features/support/presentation/views/report_problem_view.dart), [envío a API](../../../sacdia-app/lib/features/support/data/datasources/support_remote_data_source.dart). Sin verificación de bandeja personal, interfaz de resolución administrativa ni aviso al resolver. |

**Ampliación 2026-09-16:** la reapertura de carpeta se localizó en `/dashboard/clubs/evidence-folders/[folderId]`; la de camporee, en `/dashboard/campamentos/[id]` y `/dashboard/campamentos/union/[id]`. Ambas incluyen confirmación y llamada API. Los detalles de estados, búsquedas negativas y **104 pruebas aprobadas** están en la [ficha de verificación](16-verificacion-flujos-pendientes.md).

### Qué falta para afirmar que una capacitación está validada

- [ ] Recorrer las pantallas con cuentas de prueba representativas y permisos reales en un entorno autorizado.
- [ ] Confirmar en ese entorno los flags de órdenes/seguros y la versión de app/panel usada.
- [ ] Ensayar rechazo, cancelación permitida y operación bloqueada sin afectar registros reales.
- [ ] Probar interrupción de red y recuperación; observar duplicados, conservación de datos y estado final, sin suponer resultados.
- [x] Revisar UI de reversión legacy, mantenimiento de informes mayores y soporte administrativo: no se localizaron consumidores en admin/app; quedan fuera de la demo en este corte. Véase [alcance y resultados](16-verificacion-flujos-pendientes.md).
- [x] Localizar acciones web de reapertura de carpeta y camporees.
- [x] Ejecutar pruebas focalizadas con dependencias simuladas: 99 backend y 5 admin aprobadas. No sustituyen las comprobaciones reales pendientes.

La revisión documental y de código permite preparar la explicación; **estas comprobaciones pendientes son necesarias para certificar la demostración**, no nuevos flujos supuestamente implementados.

## Conexiones entre flujos: mapa narrativo

```text
Preparación institucional
  Club/secciones + permisos + año + catálogos + responsables
       |
       +-- Persona nueva → perfil → solicitud → membresía aprobada
       +-- Persona existente → continuidad anual por directiva
       |
       +-- Clase → avance/evidencias → revisión → investidura
       +-- Especialidad → paquete/revisión → aprobación → maestrías
       +-- Certificación → requisitos → junta/cierre → certificación
       +-- Certificados previos → carga/revisión → trayectoria reconocida
       |
       +-- Unidad → actividades/asistencia → planilla → miembro del mes
       +-- Finanzas / inventario / seguros / pedidos de materiales
       +-- Camporee → sección → personas/pago → agenda/competencia
       |
       +-- Matrícula de sección → informes / carpeta anual
       +-- Datos institucionales → rankings / tableros / supervisión
       |
       +-- Nuevo periodo → corte + cargos + nuevas continuidades

Soporte transversal: cuenta, privacidad, recursos, avisos y auditoría.

Diseño futuro separado (49; sin implementación acreditada):
  Club → solicitud colectiva → Campo Local → lista aprobada vigente
       → fin de ceremonia → registro automático individual de investiduras
```

Las ramas no implican que todo miembro deba cursar los tres caminos formativos, ni que una operación dispare automáticamente todas las siguientes. Matrícula anual de sección y continuidad anual de personas siguen siendo actos distintos.

## Quién necesita entender qué

| Público | Prioridad de explicación |
|---|---|
| Miembro | 01, 02, 04–14, 19, 23, 25, 44–46 |
| Consejero/responsable de clase | 03–05, 22–25; distinguir apoyo de permisos de aprobación |
| Director/directiva | 01–05, 15–19, 22–29, 31–38, 40–45 |
| Coordinador | 04–08 según autorización, 20, 42–43, 46; no asumir facultades de campo en camporees |
| Campo local/unión | 15–21, 28–43 según territorio y permisos; no todos cierran los mismos procesos |
| Administración técnica | 10–14, 21, 29–30, 39, 41–43, 47–48; configuración no equivale a decisión eclesiástica |

Esta tabla es un orden didáctico, **no una matriz de permisos**. Para autorización usar la [matriz de roles](05-matriz-roles-verificada.md), su evidencia y las reglas vigentes.

**Complemento de diseño:** explicar el 49 a directivas, Campo Local y participantes como proceso acordado pendiente de implementación; a coordinación, aclararle que no interviene como aprobador de esa solicitud. No usarlo como práctica disponible de capacitación.

## Distinciones que deben quedar claras al finalizar

| No son equivalentes | Por qué importa |
|---|---|
| Cuenta / membresía / acceso al panel | Identidad, pertenencia y superficie tienen controles distintos. |
| Miembro inscrito / sección matriculada / clase inscrita | Son tres contextos anuales diferentes. |
| Cargo / unidad / responsabilidad pedagógica | No conceden automáticamente las mismas funciones. |
| Archivo cargado / enviado / aprobado | Cada paso tiene una decisión o condición diferente. |
| 100% de avance / revisión humana completa / investidura | El porcentaje no sustituye el reconocimiento institucional. |
| Pipeline individual actual / solicitud colectiva acordada | El 05 incluye coordinación; el diseño 49 va directamente a Campo Local. No son dos nombres de la misma operación implementada. |
| Baja solicitada / exclusión autorizada en ceremonia | En el diseño 49, una baja pendiente no modifica la lista aprobada ni suspende una investidura autorizada. |
| Especialidad / maestría / certificación / clase | Tienen criterios y cierres distintos. |
| Informe mensual / carpeta anual | El informe se envía; la carpeta se evalúa. |
| Orden emitida / comprobante / pago aprobado / entrega | Ningún estado prueba automáticamente el siguiente. |
| Cancelación / reversión / reembolso | Detener una orden o invalidar cupos no devuelve automáticamente dinero. |
| Error de conexión / operación no registrada | Sin confirmación, consultar estado antes de repetir una escritura sensible. |
| Recursos digitales / materiales generales / mercancía de camporee / inventario | No comparten necesariamente registros, cobros ni flujo. |
| Inscripción a camporee / asistencia / resultado oficial | Registrar participación no equivale a puntuar. |
| Director futuro / director vigente | Programar una sucesión no otorga autoridad inmediata. |
| API disponible / pantalla conectada / sistema desplegado | Son niveles de evidencia diferentes. |

## Disponibilidad y pendientes que no se deben ocultar

1. **Ningún flujo fue certificado en producción en esta entrega.** El 2026-09-16 pasaron 104 pruebas automatizadas focalizadas con dependencias simuladas; la inspección visual local llegó al login. No se ejecutaron recorridos autenticados de extremo a extremo, builds, seeds o migraciones.
2. **OAuth/MFA/sesiones:** hay contratos, pero no UI completa uniforme; la documentación móvil aún señala OAuth no disponible. No repetir “Google/Apple listo” solo porque exista API.
3. **Continuidad anual:** app documentada y bloque web localizado el 2026-09-22. La ausencia web de la ficha 07 es histórica, no un diagnóstico vigente. Los saltos AV→CQ/CQ→GM tienen condiciones de trayectoria, edad y sección; no toda transición está resuelta.
4. **Sucesión de directores:** preelección, sustitución vigente y cancelación de planes no tienen cobertura UI idéntica.
5. **OCR y certificaciones:** contienen implementación parcial/condicionada. OCR no es validador institucional; sin proveedor efectivo no prometer extracción automática.
6. **Mercancía e insumos de camporee:** documentos declaran rama/migración pendientes en su corte. Su presencia en la referencia API no prueba disponibilidad en el entorno del usuario.
7. **Informes y SLA:** hay diferencias cliente/contrato declaradas. El informe mensual no tiene aprobación de unión; el SLA no es el home territorial.
8. **Clases:** no prometer cambio automático de sección por cumpleaños, resolución de toda clase multianual o investidura automática por porcentaje. Los saltos soportados forman parte de la continuidad confirmada por la directiva. El diseño 49 propone automatizar el registro al terminar la ceremonia sobre una lista autorizada, no sobre un porcentaje aislado.
9. **Carpetas:** usar `annual-folders`, no el flujo legacy retirado. Confirmación de unión es condicional. Las fichas discrepan en el detalle de carga móvil; aquí no se certifica cada pantalla de esa superficie.
10. **Notificaciones y auditoría:** no todos los eventos tienen push y no todos los registros tienen auditoría exhaustiva. Historial técnico no es logística de préstamos.
11. **Rankings/camporee:** una frase resumida de la ficha 11 puede interpretarse como “ningún puntaje de camporee suma al anual”; el documento de ranking sí contempla resultados oficiales como componente. Esta guía distingue inscripción, resultado oficial y configuración, sin certificar fórmulas.
12. **Pantallas revisadas posteriormente:** materiales, exportación, alta móvil de soporte y cierre anual web tienen evidencia V localizada arriba. Informes mayores tienen lectura localizada, no mantenimiento completo verificado. No se localizaron consumidores administrativos para soporte, reversión legacy ni mantenimiento de informes mayores en los clientes revisados; quedan fuera de la demo según la [verificación focalizada](16-verificacion-flujos-pendientes.md). No se inventan pantallas para completar el relato.
13. **Excepciones y recuperación:** E1–E3 y las reaperturas de E4 tienen reglas verificadas en código; las acciones web de reapertura están localizadas y la reversión legacy no tiene consumidor encontrado en este corte. Los pasos de recuperación son pautas para usuarios, no una certificación de funcionamiento offline ni de ausencia de duplicados.
14. **Ceremonia colectiva:** el 49 está acordado funcionalmente, no acreditado en runtime. Falta cerrar P-01–P-08 y realizar diseño técnico, implementación y verificación; no se autorizó reemplazar el pipeline actual ni migrar trámites.
15. **GM obligatoria:** la creación depende de identificar el tipo en el catálogo activo; se encontró una brecha de validación si falta GM. El rechazo de desactivación sí se verificó para una sección identificada como Guías Mayores. No presentar un catálogo inconsistente como caso soportado.

## Matriz de cobertura documental

| Dominio o familia | Flujos que lo explican |
|---|---|
| Auth, post-registro, membresía, perfil, salud y representante | 01, 10–14 |
| Continuidad, club/sección, cargos, unidades, traslado y solicitudes | 02–03, 15–19, 21 |
| Clases, evidencias, investidura, especialidades, maestrías | 04–07, 43 |
| Solicitud colectiva y ceremonia de investidura | 49 — acuerdo funcional, no implementación acreditada; separado del 05 |
| Certificaciones y certificados previos | 08–09 |
| Coordinación y RBAC | 12, 20, 42, 47 |
| Actividades, conjuntas, recurrentes, QR, asistencia, planillas | 22–24 |
| Miembro del mes y rankings personales/institucionales | 25, 41 |
| Finanzas, cierre financiero, inventario | 26–27 |
| Seguros, órdenes territoriales y reasignaciones | 28, 32 |
| Materiales, catálogo, existencias, pedidos y comprobantes | 29 |
| Cancelación, reversión y corrección | E1–E4 amplían 04–05, 28–32 y 40; no se contabilizan como nuevas familias |
| Interrupción de conexión y resultado incierto | Complemento transversal de recuperación; código localizado y límites declarados |
| Camporees, staff, sedes, eventos, scoring, aprobaciones | 30–35 |
| Mercancía, insumos y obligaciones separadas de pago | 36–37, 29, 32 |
| Matrícula de sección, informes mensuales/trimestrales/anuales | 16, 38–39 |
| Plantillas y carpeta anual de evidencias | 40, 47 |
| Operaciones, SLA y lectura territorial | 42 |
| Recursos, comunicaciones, soporte, exportación | 14, 44–46 |
| Catálogos, usuarios, reglas, permisos, auditoría | 47–48 |
| Cron/automatización | Integrados en 01–02, 21–22, 25–26, 38, 41, 45; no un menú autónomo para todos |
| Logros gamificados (`achievements`) | Fuera de la explicación institucional: documento marcado NO CANON; no confundir con maestrías ni miembro del mes |
| Infraestructura, salud técnica del API y fachada nativa en desarrollo | Fuera del recorrido de usuario; no se presentan como flujos funcionales adicionales |

## Guion de apertura y cierre para la explicación

**Apertura:** “Vamos a recorrer cómo una persona entra a SACDIA, participa en su sección, registra su formación y recibe reconocimiento. Después veremos cómo la directiva administra la operación y cómo campo y unión supervisan lo que les corresponde”.

**Cierre:** “El valor no está en tener muchos formularios: está en conectar lo que se registra, quién lo revisa, qué resultado obtiene y cómo se conserva la historia. No todos los usuarios hacen lo mismo ni todas las funciones tienen la misma disponibilidad”.

## Key Learnings:

1. El sistema tiene varios circuitos de revisión; no existe una aprobación universal que sustituya membresía, evidencia, investidura, certificación, carpeta y pago.
2. Los flujos anuales de persona, sección y clase deben explicarse por separado aunque compartan el periodo.
3. Un catálogo funcional integral debe incluir soporte, privacidad, materiales e informes mayores, no solo los módulos visibles del recorrido formativo.
4. La disponibilidad debe probarse por superficie y entorno; el contrato API y los documentos de otra rama no bastan para prometer un flujo operativo.
5. Cancelación de orden, reversión legacy de cupos y reembolso son operaciones distintas; materiales pagados cancelados quedan con devolución pendiente.
6. Un resultado de envío incierto exige consultar antes de repetir; las pantallas y reintentos localizados no prueban una garantía universal contra duplicados.
7. Una definición funcional acordada debe estar visible sin confundirse con runtime: la ceremonia colectiva no reemplaza todavía el pipeline individual.
8. La continuidad anual contempla saltos formativos condicionados y un resultado de trayectoria completa; no equivale a mover personas automáticamente por cumpleaños.
