# 08 · Clases progresivas: inscripción, avance e investidura

**Estado:** DRAFT · **Revisión de código local:** 2026-09-14 · **Investidura actualizada:** 2026-10-13 contra `development`  
**Alcance:** cómo una persona cursa una clase en el año eclesiástico y cómo
esa trayectoria recibe reconocimiento institucional. Los honores/especialidades
quedan para la ficha siguiente; aquí solo se declara que **no bloquean** la
investidura.

> **Cambio de la investidura (2026-10-13).** Esta ficha se escribió con el pipeline club → coordinación → campo. Ese pipeline está **retirado**: sus 17 rutas responden HTTP 410 `INVESTITURE_LEGACY_PIPELINE_RETIRED` y el panel y la app borraron sus pantallas. El modelo vigente es la **investidura por autorización** (pasos 4 y 5, matriz y demo reescritos). Mergeado en `development` (backend #465, #466, #468, #469; panel #223 a #226; app #157 a #160). El backend en línea corre hoy contra la rama `development` de Neon (ver `docs/deployment/DEPLOYMENT-GUIDE.md`); la rama `production` no se usa todavía. No hay constancia en la documentación de que el desbloqueo de bloqueos legados se haya corrido en algún entorno.
>
> No reemplaza el canon ni certifica despliegue. Autoridad API:
> `docs/api/ENDPOINTS-LIVE-REFERENCE.md`. Datos: schema efectivo de
> `sacdia-backend/prisma/schema.prisma`. Ingreso inicial y continuidad anual
> ya están en [06](06-ingreso-inicial.md) y [07](07-inscripcion-anual.md); esta
> ficha no los reescribe.

## Cinco mensajes para la presentación

1. **La clase no se elige como un curso libre.** En el alta, el backend la
   deriva por edad al inicio del año, tipo de sección y disponibilidad. Cumplir
   años a mitad de ciclo no cambia esa clase.
2. **Estar inscrito no es estar investido.** El `enrollment` es el registro
   operativo del año. La investidura es una autorización humana posterior:
   la directiva presenta y un pastor del distrito o el Campo autoriza.
3. **Hay tres circuitos distintos.** (A) registrar avance y archivos de un
   requisito; (B) revisar esa evidencia; (C) presentar a la persona en una
   solicitud de investidura y autorizarla. Aprobar un archivo no cierra la clase.
4. **Quien enseña no es automáticamente quien dirige.** El cargo en la sección
   y la asignación pedagógica de una clase son registros distintos.
5. **La política anual y la inscripción explícita no son la misma regla.** El
   año siguiente puede avanzar sin investidura de la clase inmediata; un
   `POST /users/:userId/classes/enroll` sí exige prerrequisitos investidos.

## Cómo leer la evidencia

- **Canon/contrato:** dominio, feature y referencia API.
- **Código:** backend, app y panel; demuestra existencia técnica, no piloto.
- **Pruebas leídas:** archivos de spec; **no ejecutados**.
- **Disponibilidad:** conectado en código ≠ recorrido ensayado con cuentas.

## Vocabulario

| Término | Significado operativo | No confundir con |
|---|---|---|
| Clase | Etapa formativa del catálogo (`classes`), ligada a un tipo de club | La sección del club |
| Enrollment | Inscripción anual de una persona en una clase (`enrollments`) | Membresía `member active` |
| Requisito / sección de clase | Unidad evaluable dentro de un módulo (`class_sections`) | Sección de club |
| Track | `BASIC`, `ADVANCED` o `EXTRA` | “Avanzado” como sinónimo de investidura |
| Evidencia de requisito | Archivo y estado de un `class_section_progress` | Envío de la clase a investidura |
| Investidura | Reconocimiento institucional del enrollment; se confirma al autorizar a la persona en una solicitud | Completar un módulo |
| Solicitud de investidura | Lista de personas y clases de **una sola sección**, con fecha, que la directiva presenta en la ventana del Campo | Una cadena de aprobaciones |
| Ventana del Campo | Rango de días (inclusivos) por Campo y año en que se puede presentar y autorizar | La fecha de investidura de una persona |

La verdad operativa anual vive en `enrollments`. `users_classes` ya no existe
en el schema runtime (`docs/features/clases-progresivas.md`:11-12, 70).

## Tres caminos hacia un enrollment

```text
A. Ingreso inicial (ficha 06)
   edad al inicio del año + tipo de sección
   → ClassAssignmentResolver
   → enrollment del año + membresía PENDING

B. Continuidad anual (ficha 07)
   historial regular del mismo tipo
   → NextClassResolver + política modo annual
   → enrollment en la misma transacción que activa member

C. Inscripción explícita
   POST /users/:userId/classes/enroll
   → ClassesService.enrollUser
   → prerrequisitos INVESTIDO, tope de nivel, cupo activo, cruce GM
```

**A — Alta.** El backend calcula la edad UTC al `start_date` del año vigente y
elige la clase activa del tipo con mayor `minimum_age` ≤ esa edad, disponible
en el año. Si el cliente manda otro `class_id`, responde
`POST_REG_CLASS_NOT_ELIGIBLE`
(`sacdia-backend/src/common/services/class-assignment-resolver.service.ts`:41-108).
En la UI del wizard la clase no es un selector libre
([06](06-ingreso-inicial.md) paso 5).

**B — Año siguiente.** `NextClassResolver` mira enrollments regulares
(`cross_type_enrollment=false`) del mismo tipo, de años que ya terminaron. Sin
historial: clase por edad en ese tipo (`ClassAssignmentResolver`). Con historial:
siguiente `display_order` existente, no `último + 1` aritmético
(`sacdia-backend/src/classes/next-class.resolver.ts`). Si se agota AV o CQ y hay
edad + sección destino: salto de tipo (`crossed_type`). En modo `annual`,
la política **omite** la investidura del predecesor inmediato del mismo tipo;
prerrequisitos de otro tipo y `requires_invested_gm` siguen bloqueando
(`sacdia-backend/src/classes/class-enrollment-policy.service.ts`:100-134).
`max_duration_years > 1`, catálogo vacío, edad insuficiente, sin sección destino
Guía Mayor es la última clase: la continuación deja la membresía y no abre otra inscripción ([07](07-inscripcion-anual.md)).

**C — Explícita.** `enrollUser` exige clase activa y disponible, prerrequisitos
activos en estado `INVESTIDO` (cualquier año), `requires_invested_gm` si aplica,
y no saltar más de un `display_order` por año calendario
(`CLASS_LEVEL_TOO_HIGH`). Hay como máximo una inscripción activa regular y una
cruzada por usuario/año. Un Guía Mayor investido (`asset_code = GM-01`) puede
añadir una clase de Aventureros o Conquistadores aún no investida
(`cross_type_enrollment=true`), sin exigir edad
(`sacdia-backend/src/classes/classes.service.ts`:523-787, 1567-1611;
`docs/features/clases-progresivas.md`:105-110).

El permiso del POST explícito es `classes:submit_progress` sobre el `userId`
(`sacdia-backend/src/classes/classes.controller.ts`:178-196). No es el mismo
acto que la inscripción anual de la directiva.

## Recorrido operativo (después de existir el enrollment)

```text
Enrollment IN_PROGRESS (año vigente)
  ├─ miembro o responsable pedagógico registra puntaje / archivos
  ├─ submit del requisito → class_section_progress SUBMITTED
  ├─ revisor de evidencias aprueba o rechaza (ficha 02)
  ├─ elegibilidad BASIC + EXTRA aplicables = 100% (con el % del Campo)
  ├─ director / secretario / secretario-tesorero de la sección presenta
  │     la solicitud de investidura (ventana del Campo abierta)
  │     → persona PENDING; progreso del enrollment bloqueado
  └─ pastor del distrito, director-lf o assistant-lf autoriza por persona
        → INVESTIDO (sin etapas intermedias)
        rechazo (humano o del sistema) o retiro libera el progreso
        fin de año sin resolver → CLOSED_YEAR (no se arrastra)
        EXPIRED conserva historial; no se continúa
```

### Paso 1 — Registrar avance de un requisito

**Quién puede escribir:** el propio miembro; director, subdirector, secretario
o secretario-tesorero de la misma sección/año; consejero o secretario con
asignación pedagógica activa de esa clase; o roles globales de bypass
(`ClassProgressAccessService`,
`sacdia-backend/src/classes/class-progress-access.service.ts`:10-15, 38-67,
190-201). `instructor` no es responsable formal de la trayectoria anual.

**Condiciones:** el enrollment debe ser del **año vigente**
(`CLASS_PROGRESS_YEAR_NOT_OPERATIONAL`) y mutable: no
`locked_for_validation` y no en `INVESTIDO` / `EXPIRED`
(`assertClassProgressMutable`,
`sacdia-backend/src/classes/class-progress-mutable.ts`). Los estados
intermedios de la vía anterior ya no bloquean por sí solos. Mientras haya una
persona `PENDING` en una solicitud de investidura, el progreso de ese
enrollment responde `INVESTITURE_REQUEST_PROGRESS_LOCKED`. `IN_PROGRESS` y
`REJECTED` permiten mutación.

**Resultado:** fila en `class_section_progress` (puntaje + evidencias JSON) y
proyección de módulo. Si hay varios enrollments de la misma clase, hace falta
`enrollment_id` o la API responde `ENROLLMENT_RESOLUTION_AMBIGUOUS`.

### Paso 2 — Presentar el requisito a revisión

`POST .../sections/:sectionId/submit` exige al menos un archivo y estado
`PENDING` o `REJECTED`. Pasa a `SUBMITTED` y registra `submitted_by_id`
(`classes.service.ts`:1354-1431). Subir el archivo **no** lo pone solo en la
cola: hay que enviar. Detalle de la cola: [02](02-revision-evidencias.md).

### Paso 3 — Qué cuenta como “completo” para investidura

`ClassRequirementEligibilityService` marca un requisito completo si no está
`REJECTED` y (`VALIDATED` **o** su puntaje alcanza el **porcentaje del Campo**:
80 por defecto, antes un 70 fijo; el Campo lo cambia hasta el 30 de junio y
después solo `super-admin`)
(`class-requirement-eligibility.service.ts`, `local_field_class_thresholds`).
La nota B (70) de `computeGrade` no cambia.

- `BASIC`: siempre aplica.
- `EXTRA`: solo si es aplicable al territorio/contexto; bloquea elegibilidad
  si hay EXTRA configurados y el contexto no se resolvió.
- `ADVANCED`: solo si `classes.advanced_enabled`; habilita badge/vía avanzada,
  **no** entra al cómputo obligatorio de investidura.

La app muestra el porcentaje principal como avance de investidura (BASIC +
EXTRA aplicables) y el avanzado aparte
(`docs/features/clases-progresivas.md`:57-60).

**Particularidad para no sobrevender:** la tarjeta de la app dice “requisitos
validados” al 100%, pero el backend puede contar un puntaje que alcance el
porcentaje del Campo **sin** estado `VALIDATED`. Un `REJECTED` nunca cuenta, aunque el puntaje sea alto.
En demo, no afirmar que todo requisito pasó por un revisor humano.

### Paso 4 — Presentar la solicitud de investidura

No lo hace el miembro ni el consejero. Lo hace la **directiva de la sección**:
`director`, `secretary` o `secretary-treasurer` de esa sección. No puede operar
solicitudes de otra sección del mismo club, y el subdirector (`deputy-director`)
no marca, no corrige fechas ni lee la solicitud
(`POST /club-sections/:sectionId/investiture-requests`,
`sacdia-backend/src/investiture-requests/investiture-authorization-requests.controller.ts`).

Antes de aceptar a cada persona, el backend comprueba:

- inscripción operativa válida del año y clase elegible (`GM-02` y `GM-03` no
  admiten solicitud: `INVESTITURE_REQUEST_CLASS_NOT_ELIGIBLE`);
- duración mínima/máxima por años eclesiásticos
  (`INVESTITURE_DURATION_MIN_NOT_MET` / `INVESTITURE_DURATION_EXPIRED`) y
  elegibilidad de requisitos (`INVESTITURE_REQUEST_NOT_ELIGIBLE`);
- que no esté ya `INVESTIDO` en esa clase ni tenga otra solicitud activa
  incompatible (Aventureros y Conquistadores regulares: una sola; Guías
  Mayores: una por persona y clase) y que el enrollment no siga bloqueado por la
  vía anterior (`INVESTITURE_REQUEST_LEGACY_PIPELINE_ACTIVE`);
- que el día local esté dentro de la **ventana del Campo** y del año
  eclesiástico, y que la fecha de investidura (obligatoria, igual para quienes
  se marcan juntos) caiga también en ambos. Por defecto la ventana es del 1 de
  octubre al 20 de diciembre, recortada al año; el `director-lf`,
  `assistant-lf`, `admin` y `super-admin` pueden moverla (unión y división solo
  la consultan).

Efecto: cada persona queda `PENDING`, el progreso y las evidencias de **ese**
enrollment se bloquean (`INVESTITURE_REQUEST_PROGRESS_LOCKED`; las otras
clases de la persona no) y sale un correo por envío a los pastores del distrito
y al `director-lf` y `assistant-lf` del Campo, con el enlace a la solicitud en
el panel. La directiva puede agregar personas después, quitar a un pendiente
(sin correo) o cambiar la fecha de los pendientes seleccionados.

En la app, la directiva usa la pantalla de la sección en
`sacdia-app/lib/features/investiture_requests/` (`section_investiture_view.dart`,
hoja de presentar y de cambio de fecha), con el historial y el anuario de su
sección. La vieja tarjeta de envío en el detalle de clase y `InvestitureSubmitView` ya no existen.

### Paso 5 — Autorización por persona

Autoriza **uno** de estos actores, y basta uno: el pastor asignado al distrito
del club (sección → club → iglesia → distrito), el `director-lf` o el
`assistant-lf` del Campo de la solicitud. `admin` y `super-admin` no autorizan
por esos roles; `super-admin` solo lee. La asignación de pastores es del Campo
y de la unión (cupo global, 2 por defecto, que cambia solo `super-admin`); el
pastor debe ser del mismo Campo que el distrito y debe tener el rol global
`pastor` activo.

| Acción | Ruta | Regla |
|---|---|---|
| Ver la bandeja y la solicitud | `GET /investiture-requests`, `GET /investiture-requests/:requestId` | Solo solicitudes de su distrito o Campo |
| Investir o rechazar por persona | `POST /investiture-requests/:requestId/resolutions` | Rechazo humano exige motivo; el comentario de la autorización es opcional |

Al resolver se vuelven a comprobar actor, territorio, año, ventana, fecha,
progreso y duración dentro de la transacción. Quien dejó de cumplir queda
`REJECTED_BY_SYSTEM` y las demás personas pueden quedar investidas. El
enrollment pasa a `INVESTIDO` **sin** `FIELD_APPROVED` y queda una intención
`class.completed` (logros) que se entrega una sola vez. Ante decisiones
simultáneas gana la primera confirmada.

- La persona pendiente ve «En espera de autorización.»; la rechazada ve solo
  «Falta de requisitos para investidura», nunca el motivo humano.
- Rechazar o quitar libera el progreso para corregir y volver a presentar, si
  la ventana y el año siguen abiertos.
- Cerrar la ventana con pendientes **no** los cierra: se puede ampliar dentro
  del año y los recordatorios siguen. Al terminar el año, los pendientes quedan
  `CLOSED_YEAR` y no pasan al año siguiente.
- Recordatorios por correo a las 10:00 locales del Campo: pastor lunes,
  miércoles y viernes; `director-lf` y `assistant-lf` solo el lunes con un
  resumen. `admin` y `super-admin` no reciben recordatorios.

Panel: `/dashboard/investiture-requests` (bandeja y detalle), con la página
`investiture-requests/[requestId]` que abre el enlace del correo;
`/dashboard/investiture-settings` (ventana y porcentaje del Campo) y
`/dashboard/investiture-pastors` (asignación de pastores). App: el pastor, el
`director-lf` y el `assistant-lf` ven la bandeja
(`authorizer_requests_view.dart`). No se ejecutó E2E con cuentas reales.

**Vía anterior retirada.** `submit`, `club-approve`, `coordinator-approve`,
`field-approve`, `invest`, `reject`, los bulk, `GET /investiture/pending`, los
aliases (`submit-for-validation`, `validate`, `investiture`) y el CRUD de
`/admin/investiture/config` responden **410**
`INVESTITURE_LEGACY_PIPELINE_RETIRED`, igual que la ruta de clase de
`ValidationModule`. Lo que sigue: el historial grabado, `expire-overdue` y el
desbloqueo para expedientes que quedaron con `locked_for_validation` (solo
`super-admin`, `dry_run` por defecto, por entorno). Mientras un expediente
conserve ese bloqueo, la solicitud nueva responde
`INVESTITURE_REQUEST_LEGACY_PIPELINE_ACTIVE`. Detalle en
`docs/features/validacion-investiduras.md`.

Configuración que debe existir antes de presentar: ventana y porcentaje del
Campo (`local_field_investiture_windows`, `local_field_class_thresholds`) y al
menos un autorizador para el distrito (pastor asignado o, si no, el Campo).
Sin ventana operativa, presentar falla por configuración, no por progreso.
`investiture_config` (fecha única por Campo y año) es de la vía anterior y ya no
se usa.

## Asignación pedagógica

Cargo (`club_role_assignments`) y responsabilidad de una clase
(`class_counselor_assignments`) son distintos. Asignables: `counselor` y
`secretary`. El asignado debe estar cursando Guía Mayor (activo, no
`REJECTED`/`EXPIRED`) o haberla terminado (`APPROVED`/`INVESTIDO`); si no,
`CLASS_COUNSELOR_GUIDE_MAJOR_REQUIRED`
(`class-counselor-assignments.service.ts`:31-39, 420-446). Máximo 3 activos
por clase/sección/año; máximo 2 clases por persona (la segunda exige
`exceptional` + motivo).

Director/subdirector/secretaría ven todas las clases de la sección en
`progress-scope` (`access_level=section`); el consejero asignado, solo las
suyas (`assigned`). `members-progress` añade GMs con cursado cruzado del
mismo club.

## Matriz actor × acción

| Acción | Quién (backend) | Superficie trazada |
|---|---|---|
| Derivar clase en alta | Sistema; persona no elige | App wizard; ver 06 |
| Inscribir año siguiente | Directiva con `club_members:approve` | App; admin no consume el contrato (07) |
| Enroll explícito / cruce GM | `classes:submit_progress` sobre el usuario | API; no es el flujo anual |
| Cargar/enviar requisito | Self, directiva section-wide, consejero asignado | App detalle de requisito |
| Revisar evidencia | Roles/permiso de evidence-review | App coordinador + panel; ficha 02 |
| Presentar, agregar, quitar y cambiar fecha en la solicitud | Director, secretario o secretario-tesorero de **la** sección | App (pantalla de la sección) |
| Autorizar o rechazar por persona | Pastor del distrito, `director-lf` o `assistant-lf` (basta uno) | Panel (bandeja y enlace del correo) y app |
| Configurar ventana y porcentaje del Campo | `director-lf`, `assistant-lf`, `admin`, `super-admin` (porcentaje: `super-admin` después del 30 de junio) | Panel (`investiture-settings`) |
| Asignar pastores al distrito | `director-lf`, `assistant-lf`, `director-union`, `assistant-union`; cupo: `super-admin` | Panel (`investiture-pastors`) |
| Soltar bloqueos de la vía anterior | `super-admin` exacto, `dry_run` primero | API (`POST /admin/investiture/legacy-locks/release`) |
| Vencer enrollments atrasados | admin + `catalogs:update`, `dry_run` luego apply | Panel; **no hay cron** |

El subdirector puede cargar progreso de la sección pero **no** presenta ni lee
la solicitud de investidura; el consejero tampoco la presenta (lo hace la
directiva de la sección). `admin` y `super-admin` no autorizan por esos roles.
No afirmar paridad de facultades.

## Especialidades ligadas a la clase

`class_honors` (`REQUIRED` / `RECOMMENDED` / `ELECTIVE`) es informativo:
incluso `REQUIRED` **no** bloquea módulo ni investidura
(`docs/features/clases-progresivas.md`:119-121). La app las muestra y puede
inscribir al honor por otro endpoint. Flujo propio: siguiente ficha.

## Excepciones que la demo debe poder nombrar

| Código / resultado | Qué significa | Qué no decir |
|---|---|---|
| `POST_REG_CLASS_NOT_ELIGIBLE` | Edad/tipo/disponibilidad no calzan | “Elige la clase que quiera” |
| `ANNUAL_CLASS_POLICY_UNRESOLVED` | El año no puede resolver la siguiente | “Siempre avanza automático” |
| `CLASS_PREREQUISITE_NOT_MET` | Enroll explícito sin predecesor investido | Que el anual y el explícito sean iguales |
| `CLASS_LEVEL_TOO_HIGH` | Salto de más de un nivel por año | “Puede saltar a Guía si tiene 16” |
| `CLASS_MAX_*_ACTIVE` / cruce GM | Tope de una regular + una cruzada | Dos clases regulares AV/CQ a la vez |
| `CLASS_PROGRESS_LOCKED` | `locked_for_validation` en true, o estado `INVESTIDO`/`EXPIRED` | Editar un expediente bloqueado o ya investido |
| `INVESTITURE_REQUEST_PROGRESS_LOCKED` | Hay una persona `PENDING` en una solicitud de ese enrollment | Que se bloquean las demás clases de la persona |
| `INVESTITURE_REQUEST_WINDOW_CLOSED` / `DATE_OUTSIDE_WINDOW` | Fuera de la ventana del Campo no se presenta ni se autoriza | Que cambiar solo la fecha reabre la ventana |
| `INVESTITURE_REQUEST_LEGACY_PIPELINE_ACTIVE` | El enrollment conserva `locked_for_validation` de la vía anterior | Que la vía anterior sigue operativa |
| `INVESTITURE_LEGACY_PIPELINE_RETIRED` (HTTP 410) | Una app o un panel viejo llamó una ruta retirada | Que es un fallo de permisos |
| `CLASS_PROGRESS_YEAR_NOT_OPERATIONAL` | Enrollment de otro año | “Se corrige el histórico igual que el vigente” |
| `INVESTITURE_DURATION_MIN_NOT_MET` / `EXPIRED` | Años eclesiásticos fuera de rango al presentar | Investidura el mismo día del alta si `min>0` |
| Rechazo | Motivo humano obligatorio; la persona solo ve el texto genérico; el progreso vuelve editable | Que el rechazo borre el progreso o que la persona vea el motivo |
| Fin de año sin autorizar | Queda `CLOSED_YEAR`, sin arrastre al año siguiente | Que la solicitud pasa al año siguiente |

Carga masiva OCR de certificados escribe sobre `enrollments` e historial; no
es el checklist cotidiano. No mezclarla en el recorrido principal
(`docs/features/clases-progresivas.md`:150-154).

## Disponibilidad por superficie

| Superficie | Trazado | Límite |
|---|---|---|
| Backend | Catálogo, enroll, progreso, submit de requisito, política, solicitud y autorización de investidura, ventana/porcentaje/pastores, correos y recordatorios, cierre de año, 410 de la vía anterior, desbloqueo, vencimiento manual | Mergeado en `development`; sin ensayo con cuentas reales |
| App | Camino, detalle con tracks, carga/envío de requisito, presentar y autorizar investidura, historial propio y de sección, anuario, alcance pedagógico | Sin E2E; la tarjeta de envío vieja ya no existe |
| Admin | CRUD de catálogo, asignaciones en ficha de sección, bandeja de autorización, ventana/porcentaje, pastores, expire-overdue | El CRUD de catálogo **no** opera progreso de miembros |
| Pruebas | Specs de política, progreso bloqueado, consejero GM, solicitud/autorización, 410 y desbloqueo | Leídas, no ejecutadas |
| Producción | Permisos reales, ventana y porcentaje por Campo, pastores asignados, cuentas del piloto | Pendiente de ensayo |

## Guion de demo ficticio

Personajes: “Miembro Demo 01” (Conquistadores, clase del año), “Consejero
Demo”, “Director Demo”, “Pastor Demo” (asignado al distrito). Correos
`*.invalid`. Sin datos reales.

1. Abrir “Mi Camino”: nodo cursando vs por cursar vs investido. Decir: la
   edad del nodo es `minimum_age`, no un rango de track.
2. Entrar a un requisito BASIC: cargar archivo y **enviar**. Mostrar que
   sigue sin ser clase investida.
3. Como consejero: lista pedagógica → miembro → mismo detalle. Distinguir
   cargo de director vs clase asignada.
4. Cuando el miembro llegue al 100% con el porcentaje del Campo: como
   **director (o secretario) de la sección**, presentar la solicitud con la
   fecha de investidura. Mostrar que la persona queda «En espera de
   autorización.» y que su progreso se bloquea.
5. Como pastor del distrito (o `director-lf`): abrir la solicitud desde la
   bandeja o el enlace del correo y autorizar. El enrollment pasa a
   `INVESTIDO` sin etapas intermedias. Si el piloto no tiene ventana o
   pastor configurados, detenerse en «pendiente».
6. Verbalizar: honores relacionados se ven, no cierran esta clase. Ciclo
   anual y alta inicial son otros actos.

Si falta la ventana del Campo (o hoy está fuera de ella), presentar falla:
es un hallazgo de piloto, no un fallo de “la clase no está al 100%”.

## Fuentes

- Canon: `docs/canon/dominio-sacdia.md` (proceso formativo e investidura).
- Dominio: `docs/features/clases-progresivas.md`,
  `docs/features/validacion-investiduras.md`,
  `docs/plans/2026-09-28-investidura-autorizacion.md`.
- Contrato: `docs/api/ENDPOINTS-LIVE-REFERENCE.md` (classes, counselor
  assignments, progress-scope, investiture).
- Código citado en esta ficha: `classes.service.ts`,
  `class-enrollment-policy.service.ts`, `next-class.resolver.ts`,
  `class-assignment-resolver.service.ts`,
  `class-requirement-eligibility.service.ts`,
  `class-progress-access.service.ts`,
  `class-counselor-assignments.service.ts`,
  `class-progress-mutable.ts`,
  `investiture-requests/investiture-authorization-requests.controller.ts`,
  `investiture/legacy-investiture-retired.controller.ts`,
  `investiture/legacy-lock-release.service.ts`,
  `features/investiture_requests/` (app) y las pantallas
  `dashboard/investiture-requests`, `investiture-settings` e
  `investiture-pastors` (panel).
- Relacionadas: [02](02-revision-evidencias.md), [06](06-ingreso-inicial.md),
  [07](07-inscripcion-anual.md).

**No cubierto aquí (sigue en bloque 4):** circuito de honores
(inscripción, evidencias, validación propia) y certificaciones de Guías
Mayores.
