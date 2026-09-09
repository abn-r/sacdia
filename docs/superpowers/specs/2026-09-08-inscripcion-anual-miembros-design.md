# Inscripción anual, nombramientos y cambio de año eclesiástico

**Fecha original**: 2026-09-08  
**Revisión**: 2026-09-09  
**Estado**: DRAFT — requisitos de retorno e inscripción confirmados por el usuario; diseño técnico corregido para implementación. No representa funcionalidad desplegada.  
**Alcance**: backend, app y consumo administrativo; sin pagos ni rediseño visual.  
**Plan ejecutable**: [2026-09-08-inscripcion-anual-miembros.md](../plans/2026-09-08-inscripcion-anual-miembros.md)

> Esta revisión sustituye la versión que inscribía automáticamente al exdirectivo al regresar a GM. El usuario aclaró dos reglas: vuelve a **no inscritos** y **la directiva realiza la inscripción anual**. No volver a implementar ni probar el comportamiento anterior.

## 1. Fuentes y precedencia

- Requisitos explícitos de esta conversación, incluidos los ajustes del 2026-09-09.
- [Fuente de verdad](../../canon/source-of-truth.md), [gestión de clubes](../../features/gestion-clubs.md), [membresías](../../features/membership-requests.md), [clases](../../features/clases-progresivas.md).
- [Contrato API](../../api/ENDPOINTS-LIVE-REFERENCE.md) y `sacdia-backend/prisma/schema.prisma` describen el estado efectivo; este documento prescribe cambios, no los declara implementados.
- Si una regla de negocio no está resuelta aquí, aplicar §10; no deducirla de comentarios, tests antiguos o nombres de tablas.

## 2. Reglas confirmadas

| ID | Regla obligatoria |
|---|---|
| R01 | Campo Local registra anticipadamente al director del periodo siguiente, sin destituir al actual ni dar acceso o visibilidad del cargo al futuro director. |
| R02 | Hay como máximo un director operativo por sección en un instante. Un periodo futuro no es un segundo director operativo. |
| R03 | Los cargos terminan con su vigencia. No se copian al nuevo año; un nuevo nombramiento es un acto distinto. |
| R04 | Quien termina su cargo AV/CQ y regresa a su sección GM queda en la lista **no inscritos**, no como miembro operativo. No se crea clase por regresar. |
| R05 | La directiva autorizada de la sección realiza la inscripción anual de sus miembros, incluidos quienes retornaron a GM. No es una obligación de autorregistro del miembro. |
| R06 | Si esa persona tiene nombramiento de director de GM para el año entrante, se respeta ese cargo al entrar en vigor: no sustituirlo por `member`, ni perderlo por ejecutar después el retorno. |
| R07 | Conservar identidad, investidura e historial no implica conservar acceso a actividades de una sección cuyo cargo terminó. |
| R08 | Año eclesiástico significa intervalo de fechas institucionales, no necesariamente año calendario. El corte no espera reuniones ni enero. |
| R09 | Inscripción anual no repite alta de cuenta ni post-registro. No cerrar sesiones ni invalidar JWT solamente por cambio de año. |
| R10 | La inscripción institucional de sección (`club_enrollments`) y su validación por Campo Local no son la inscripción de cada miembro. |
| R11 | Avanzar al siguiente nivel del ciclo anual no equivale a investir la clase anterior. El historial anterior no se borra ni se reescribe. |
| R12 | El cursado cruzado permitido a GM investido no lo convierte en miembro de AV/CQ ni le devuelve un cargo. |

AV/CQ = Aventureros/Conquistadores. GM = Guías Mayores.

## 3. Separación de conceptos y representación propuesta

### 3.1 Pertenencia, participación, cargo y clase

- **Pertenencia base**: sección de referencia del miembro dentro del club. Puede existir sin inscripción anual vigente.
- **Participación anual**: no inscrito / inscrito en el periodo actual. No se confunde con una solicitud inicial `pending`.
- **Nombramiento**: autoridad operativa en una sección durante su periodo. Puede coexistir con pertenencia base en otra sección.
- **Inscripción a clase**: registro formativo con año, avance e investidura propios. Un nombramiento no crea por sí solo una clase.

No crear una tabla `member_enrollments` por duplicación conceptual. Reutilizar asignaciones con estados explícitos y separar la programación de cargos.

### 3.2 No inscrito del año nuevo

Representación técnica propuesta: una fila `club_role_assignments`, rol `member`, año **nuevo**, sección base, `status=inactive`, `active=true`.

`active=true` significa fila conservada, NO autorización. Solo `status=active` y vigencia válida pueden otorgar permisos. La directiva convierte esa fila anual `inactive` en `active` al completar la inscripción; no crea otra fila idéntica. Esta transición ocurre en el año actual, no sobre el cargo ni la matrícula del año anterior.

- Nunca convertir un cargo terminado `ended` en `inactive` ni cambiar su `role_id` a `member`.
- Nunca cambiar la sección de una asignación histórica para simular el retorno.
- Conservar el historial de participación pasada aunque el usuario no continúe.
- No usar indiscriminadamente «última asignación» como pertenencia base: puede ser un cargo externo, una solicitud rechazada o un club abandonado.
- Resolver la base con membresía válida conocida y movimientos aceptados; en el caso confirmado de retorno AV/CQ a GM, usar GM del mismo club. Investidura GM-01 y vínculo GM válido son evidencias, no permiso para inventar un club.
- Si no se puede resolver una sección base única y habilitada, registrar incidencia administrativa. No crear un vínculo arbitrario ni dar acceso como fallback.

### 3.3 Precedencia por usuario y sección

1. Se conserva cualquier nuevo nombramiento válido del periodo entrante.
2. El retorno no duplica un `member` en la misma sección si el resultado ya es director de GM.
3. Sin ese nombramiento, retorno GM produce **no inscrito**.
4. Inscribir a la persona no hereda cargos antiguos, no elimina cargos nuevos y no inscribe otras secciones.
5. La condición de no inscrito en una sección no revoca un nombramiento legítimo en otra. La autorización se evalúa por sección y causa del acceso, no con un booleano global de «fantasma».

## 4. Calendario y autorización

### 4.1 Año vigente

Unificar `EcclesiasticalYearService` usando el reloj inyectable y `America/Mexico_City` para convertir el instante a fecha institucional. El año vigente contiene esa fecha entre `start_date` y `end_date`, ambos inclusive según columnas DATE.

- Cero años coincidentes: no conceder acceso operativo de club y comunicar incidencia.
- Más de uno: conflicto de calendario, no elegir silenciosamente el primero.
- Validar intervalos al administrarlos: inicio <= fin, sin solapamientos. No inventar continuidad si falta un periodo.
- Para cerrar años pasados comparar **fechas**, no `year_id != vigente`, `year_id < vigente` ni restar uno al ID.
- Al cerrar un cargo, respetar su fecha final anterior si ya acabó antes; para fin anual usar fin del periodo saliente, no reescribir todos los finales con la fecha del siguiente periodo.

### 4.2 Permisos y caché

Resolver vigencia antes de aceptar una caché de autorización. La clave o metadatos deben identificar periodo y revisión del calendario; el TTL no puede cruzar el límite efectivo. Una invalidación push no constituye una barrera de seguridad.

Antes de conceder operación del nuevo periodo, asegurar que la transición del club terminó; si está pendiente, reconciliarla de forma acotada o rechazar temporalmente la operación con error recuperable. Nunca servir permisos del periodo anterior mientras se espera al cron.

- `/auth/me` y contexto activo solo otorgan autoridad por asignaciones operativas vigentes.
- Ningún consumidor secundario puede autorizar a partir de roles vencidos o permisos almacenados en grants no operativos.
- La información de **nombramientos programados** no se incluye en `/auth/me` del designado ni en selectores operativos. Se consulta por API restringida a Campo Local/admin autorizado.
- Exponer al usuario sus estados actuales de pertenencia no inscrita con permisos vacíos; no tratarlos como cargos operativos ni mostrar tabs de club por tener `active=true`.
- `PATCH /auth/me/context` rechaza una asignación vencida, no inscrita o futura.
- Conservar sesión; limpiar datos de sección en cliente al recibir nuevo contexto, al reanudar la app o al recibir un rechazo por cambio de ciclo.

## 5. Nombramientos programados y corte

### 5.1 Programación, no asignación anticipada

Reutilizar `director_succession_plans` como única fuente de programación futura. Ya existe en schema/migraciones; su existencia no prueba que esté operativa.

- Campo Local/admin autorizado registra sucesor + sección + año futuro configurado; fecha efectiva = inicio de ese año.
- No crear una fila CRA `director designated` nueva. Adaptar el endpoint local de designación a la entidad programada o reemplazarlo con compatibilidad explícita.
- Permitir programación de sección vacante: `outgoing_assignment_id` debe poder ser nulo. No inventar director saliente.
- Un plan no cancelado por sección/año; cambios antes del inicio requieren control de versión, idempotencia y auditoría. Reprogramar no altera al director vigente.
- Inicio/final del calendario con planes asociados requiere validación y actualización coherente; no dejar fechas efectivas divergentes.
- Migrar filas `designated` existentes solo con datos y procedencia verificables. No inventar `scheduled_by_id`; si faltan, emitir reporte y pedir regularización administrativa.
- Nombramientos activados son históricos. Reemplazo inmediato dentro del periodo es otro flujo, restringido a año vigente, con fechas coherentes.

### 5.2 Transición por club

El club completo es la unidad de transición porque el retorno puede relacionar CQ y GM. Procesar todas sus secciones, incluidas vacantes y miembros sin directiva, no solo aquellas con un director saliente.

Dentro de una transacción y lock de DB por club/año:

1. Releer filas y validar calendario, candidatos, planes y versión; no confiar en snapshots leídos antes del lock.
2. Terminar cargos vencidos; incluyen cargos operativos no directivos cuando su vigencia finalizó. Los vínculos pedagógicos viejos no otorgan autoridad nueva.
3. Materializar nombramientos programados del nuevo año con una única asignación operativa por director/sección; registrar plan activado y assignment resultante.
4. Resolver **estado final** por persona/sección, independientemente del orden: nuevo cargo tiene precedencia; demás miembros/retornados quedan no inscritos en su base.
5. Crear/reutilizar filas `member inactive` del nuevo periodo. No crear clases ni matricular automáticamente.
6. Incrementar versiones de autorización de afectados y registrar transición completada.

Propuesta de registro durable: `club_year_transitions`, único `(club_id, ecclesiastical_year_id)`, con versión, estado y fecha de finalización. No duplicar una estructura equivalente si ya existe al implementar. Un fallo no puede dejar cargos cerrados sin la parte correspondiente de la transición confirmada.

Tras commit: invalidar caché, notificar por usuario afectado y actualizar UI. Registrar/reintentar efectos externos fallidos; no revertir una transición confirmada por fallo de FCM. Lock Redis del cron no sustituye lock/transacción de DB.

La reconciliación sirve al job, al arranque/recuperación y a la autorización del nuevo periodo; evitar dependencias circulares con `AuthorizationContextService`. `closeYear` institucional sigue separado.

## 6. Inscripción realizada por la directiva

### 6.1 Actores y lista

Actor: director, subdirector, secretario o secretario-tesorero autorizado **en la sección correspondiente**, usando permisos de gestión de miembros. No habilitar actores nuevos solamente porque el usuario sea dueño de su perfil.

Fuente operativa de la lista: **miembros no inscritos del año vigente cuya pertenencia corresponde a esa sección**, no «todos los roles activos de esa sección el año pasado».

Debe incluir:

- Miembros que continúan y aún no están inscritos.
- Personas que retornaron a GM, aunque el año anterior solo tuvieran cargo en CQ.
- Personas con pertenencia válida que no participaron el año inmediatamente anterior.

No incluir automáticamente por antecedentes históricos a quien abandonó ese club o cambió de pertenencia. El GET y el POST deben usar el mismo resolver de pertenencia y autorización. El POST reconoce también una inscripción ya completada para responder idempotentemente, aunque haya desaparecido de GET de no inscritos. Un cargo cerrado `active=false` sirve como evidencia histórica, no como exclusión automática del retorno.

### 6.2 Comando de inscripción

La directiva selecciona al miembro y completa el proceso anual. El backend revalida pertenencia, año, alcance de quien actúa, estado y clase aplicable.

- Activar `member inactive` del año actual; si ya está inscrito, resultado idempotente.
- No quitar ni duplicar un cargo nuevo para forzar `member`.
- No usar «tiene cualquier rol activo en cualquier sección del club» como sinónimo de «ya se inscribió aquí».
- Inscripción a clase aplicable y participación anual deben confirmarse juntas o no confirmarse para esa persona; compartir la transacción de DB.
- El lote devuelve resultados por usuario (`enrolled`, `already_enrolled`, `blocked`, `failed`); no prometer atomicidad total si se procesa por persona. Duplicados de un usuario en el body se deduplican.
- Si el destino formativo es otra sección, no otorgar al actor autoridad allí por pertenecer al mismo club: dirigir a la directiva destino o comprobar autorización explícita sobre ambas.
- Registrar actor, fecha y motivo; notificaciones después de commit.

### 6.3 Solicitud propia y primera inscripción

La frase del usuario «quiero inscribirme» no autoriza a convertir automáticamente al propietario en miembro activo. El flujo confirmado aquí lo realiza la directiva.

**D01 — pendiente**: definir si habrá botón de solicitud personal y su revisión/notificación. Hasta resolverlo, no publicar activación directa desde `annual-enroll` ni presentar el botón como proceso obligatorio del miembro. Rechazar esa activación con error de dominio documentado; no reutilizar `pending` de post-registro ni inventar un workflow de aprobación nuevo.

El primer ingreso mantiene el proceso existente de post-registro y revisión. No reabrir post-registro por una renovación anual.

## 7. Clases e historial

- La selección de siguiente clase usa trayectoria regular previa al año objetivo; excluir cursado cruzado y registros futuros de esa decisión.
- Comparar periodos por fechas y niveles por catálogo, no IDs ni `display_order + 1` como supuesto de numeración contigua.
- Resolver el siguiente nivel de la trayectoria; validar disponibilidad, edad cuando aplique y sección destino habilitada. Ausencia de catálogo o sección no significa «fin de trayectoria».
- El avance anual permitido sin investidura no elimina exigencias institucionales independientes, especialmente `requires_invested_gm`. `class_prerequisites` debe distinguir explícitamente el prerrequisito del nivel anterior que no debe bloquear R11 de otros prerrequisitos. Sin ese mapeo confirmado, devolver conflicto de configuración, no desactivar todos los controles.
- **D02 — pendiente acotado**: selección de clase para GM ya investido, clases GM de duración extendida y detalle de transiciones entre tipos cuando edad/trayectoria discrepan. No imponer clase avanzada automáticamente ni asumir ausencia de clase por falta de datos. Resolver antes de habilitar esos escenarios; los casos de corte/retorno no dependen de D02.
- No matricular por cambio de año sin acción de directiva. No confundir inscripción anual de sección con `enrollments` formativos.
- Historial pasado conserva estado y evidencias. Lectura histórica no implica escritura histórica: bloquear progreso, archivos y submit de ciclos no operativos incluso con `enrollmentId` explícito o owner bypass. Toda excepción GM multianual depende de D02.
- Recuperación de clase pendiente por GM investido: inscripción nueva del año autorizado, progreso inicial cero; no reactivar silenciosamente un registro con evidencias. Repetición del mismo comando devuelve lo ya creado, no borra progreso reciente.
- Cursado cruzado en lista de clase: mismo club y año, marca explícita, sin membresía extra en AV/CQ ni poderes de consejero por el mero cursado.

## 8. Contrato de estados visible

| Situación | Quién actúa | Resultado visible | No debe suceder |
|---|---|---|---|
| Director futuro preelegido | Campo Local | Solo administración autorizada ve programación | Cargo/permisos visibles al futuro director |
| Cargo AV/CQ termina, sin nuevo nombramiento | Sistema | GM, no inscrito; directiva GM puede encontrarlo | Inscripción automática o conservar acceso AV/CQ |
| Director CQ pasa a director GM | Sistema al inicio de vigencia | Director GM | Convertirlo a `member`, duplicar cargo o dejar acceso CQ por cargo viejo |
| Miembro no inscrito | Directiva de su sección | Inscrito tras completar proceso | Exigir repetir registro o autoactivación del usuario |
| No hay acción de directiva | Nadie | Continúa no inscrito | Inscribirlo por cron o por abrir la app |
| Reintento | Mismo actor autorizado | Mismo resultado, sin duplicados | Repetir cargo, clase o efectos irreversibles |

## 9. Criterios verificables

| ID | Escenario obligatorio |
|---|---|
| A01 | Director CQ termina: no tiene permiso CQ, no tiene `member active` GM ni clase nueva por el corte. |
| A02 | Retornado figura en no inscritos GM aun sin fila GM en el año anterior; GET y POST admiten el mismo candidato. |
| A03 | Directiva GM inscribe: activa fila anual actual; el miembro no ejecuta el trámite. Actor de otra sección no puede hacerlo. |
| A04 | Director GM programado conserva cargo al cambiar el año y tras procesar retornos en cualquier orden. |
| A05 | Preselección no cambia al director vigente ni aparece en auth/perfil/contexto del futuro director. |
| A06 | Caché caliente, cron detenido y cruce de fecha institucional: cero permisos viejos; transición pendiente no concede operación prematura. |
| A07 | Dos procesos simultáneos o reinicio tras fallo: una transición, un director y ninguna matrícula duplicada. |
| A08 | Dos miembros y dos subdirectores permitidos según cupos; segundo director simultáneo rechazado. |
| A09 | Año faltante/solapado, sección base ambigua o inhabilitada: incidencia explícita, sin asignación arbitraria. |
| A10 | No modificar roles/membresías históricos para representar no inscrito actual; no cerrar asignaciones futuras. |
| A11 | Inscripción anual repite correctamente, revierte miembro+clase al fallar y no usa cargo de otra sección como `already_enrolled`. |
| A12 | No investido anterior avanza en caso anual autorizado; prerrequisitos independientes siguen vigentes; no salto indebido ni influencia de inscripción futura/cruzada. |
| A13 | PATCH progreso, upload y submit históricos rechazados incluso por propietario; GET histórico permitido conforme a alcance. |
| A14 | Cursado cruzado visible en clase del mismo club; nunca matrícula de miembro AV/CQ por ese hecho. |
| A15 | Usuario no puede autoactivar membresía anual; D01 sin resolver no se convierte en aceptación automática. |

## 10. Límites y control de cambios

- Confirmado: R01–R12, especialmente retorno no inscrito e inscripción por directiva.
- Propuesto técnicamente: estados de nuevas filas, reutilización de planes de sucesión, registro de transición y contratos del plan.
- Pendiente de negocio: D01/D02. El ejecutor pregunta una sola cuestión a la vez cuando alcance el escenario afectado y se detiene en ese punto; puede completar tareas independientes.
- No modificar pagos, seguros, inscripción institucional de sección, logout, cuotas ni UX visual fuera de integración.
- Actualizar API, features, schema documental y manuales afectados en la misma entrega del comportamiento, sin presentarlo como desplegado antes de verificarlo.
