# 08 · Clases progresivas: inscripción, avance e investidura

**Estado:** DRAFT · **Revisión de código local:** 2026-09-14  
**Alcance:** cómo una persona cursa una clase en el año eclesiástico y cómo
esa trayectoria recibe reconocimiento institucional. Los honores/especialidades
quedan para la ficha siguiente; aquí solo se declara que **no bloquean** la
investidura.

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
   operativo del año. La investidura es un pipeline humano posterior.
3. **Hay tres circuitos distintos.** (A) registrar avance y archivos de un
   requisito; (B) revisar esa evidencia; (C) enviar la clase completa a
   investidura. Aprobar un archivo no cierra la clase.
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
| Investidura | Reconocimiento institucional del enrollment | Completar un módulo |

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
o última GM: `ANNUAL_CLASS_POLICY_UNRESOLVED` ([07](07-inscripcion-anual.md)).

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
  ├─ elegibilidad BASIC + EXTRA aplicables = 100%
  ├─ consejero o director envía la clase a investidura
  │     → SUBMITTED_FOR_VALIDATION + locked_for_validation
  ├─ director de sección: club-approve
  ├─ coordinador/admin: coordinator-approve
  ├─ admin: field-approve
  └─ coordinador/admin: mark INVESTIDO
         REJECTED desbloquea corrección y reenvío
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
`locked_for_validation` y no en `CLUB_APPROVED` /
`COORDINATOR_APPROVED` / `FIELD_APPROVED` / `INVESTIDO` / `EXPIRED`
(`sacdia-backend/src/classes/classes.service.ts`:66-87, 1097-1121;
`class-enrollment-policy.service.ts`:140-145). `IN_PROGRESS` y `REJECTED`
permiten mutación.

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
`REJECTED` y (`VALIDATED` **o** `score >= 70`)
(`class-requirement-eligibility.service.ts`:130-138).

- `BASIC`: siempre aplica.
- `EXTRA`: solo si es aplicable al territorio/contexto; bloquea elegibilidad
  si hay EXTRA configurados y el contexto no se resolvió.
- `ADVANCED`: solo si `classes.advanced_enabled`; habilita badge/vía avanzada,
  **no** entra al cómputo obligatorio de investidura.

La app muestra el porcentaje principal como avance de investidura (BASIC +
EXTRA aplicables) y el avanzado aparte
(`docs/features/clases-progresivas.md`:57-60).

**Particularidad para no sobrevender:** la tarjeta de la app dice “requisitos
validados” al 100%, pero el backend puede contar un puntaje ≥ 70 **sin**
estado `VALIDATED`. Un `REJECTED` nunca cuenta, aunque el puntaje sea alto.
En demo, no afirmar que todo requisito pasó por un revisor humano.

### Paso 4 — Enviar la clase a investidura

No lo hace el miembro desde el contrato canónico. Guard: roles de club
`director` o `counselor` + permiso `investiture:submit` + recurso
`investiture_enrollment`
(`sacdia-backend/src/investiture/investiture.controller.ts`:62-108).

Antes de aceptar: duración mínima/máxima por años eclesiásticos y
`investiture_eligibility.eligible === true`
(`investiture.service.ts`:2127-2165, 2167-2187). El plazo de
`investiture_config` es **aviso** (`is_late`); no bloquea el envío.

Efecto: `SUBMITTED_FOR_VALIDATION`, `locked_for_validation=true`, historial
`SUBMITTED`. El progreso deja de ser editable.

La app conecta el envío desde el detalle de clase cuando hay elegibilidad;
si el contexto activo no es director/consejero, muestra que otro debe
enviarla (`class_detail_with_progress_view.dart`:498-514, 601-625). El data
source móvil usa la ruta **legacy**
`POST /enrollments/:id/submit-for-validation`, no
`/investiture/enrollments/:id/submit`
(`investiture_remote_data_source.dart`:11-16, 124-137). Ambas están
documentadas contra el mismo servicio
(`docs/api/ENDPOINTS-LIVE-REFERENCE.md`:1305, 1316).

`InvestitureSubmitView` (listado) **no** tiene ruta en el router; no
presentarla como bandeja de envío.

### Paso 5 — Pipeline institucional

| Transición | Actor aceptado por API | Desde |
|---|---|---|
| `club-approve` | Director de sección + `investiture:validate` | `SUBMITTED_FOR_VALIDATION` |
| `coordinator-approve` | `admin` o `coordinator` + `investiture:validate` | `CLUB_APPROVED` |
| `field-approve` | `admin` + `investiture:validate` | `COORDINATOR_APPROVED` |
| `invest` | `admin` o `coordinator` + `investiture:mark_invested` | `FIELD_APPROVED` |
| `reject` | `admin` o `coordinator` + `investiture:validate` | etapas de aprobación; exige motivo |

Bulk (hasta 200) cubre coordinator-approve, field-approve e invest; **no**
club-approve (`docs/api/ENDPOINTS-LIVE-REFERENCE.md`:1306-1312).

Panel: `/dashboard/investiture`, `/pipeline`, `/config`
(`sacdia-admin/src/navigation/sidebar/sidebar-items.ts`:245-259). App:
pendientes e historial ruteados; no se ejecutó E2E.

Configuración: `investiture_config` por campo local y año (deadline y fecha
de ceremonia). Sin esa fila, el envío falla por configuración, no por
progreso.

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
| Enviar investidura | Director o consejero + `investiture:submit` | App detalle de clase (ruta legacy) |
| Aprobar club | Director + `investiture:validate` | Individual; no bulk |
| Aprobar coordinación/campo e investir | admin/coordinator según fila | App pendientes + panel pipeline |
| Vencer enrollments atrasados | admin + `catalogs:update`, `dry_run` luego apply | Panel; **no hay cron** |

Subdirector y secretario pueden cargar progreso de la sección y **no**
aparecen en el guard de envío a investidura. No afirmar paridad de facultades.

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
| `CLASS_PROGRESS_LOCKED` | En validación o estado terminal | Editar mientras se revisa la investidura |
| `CLASS_PROGRESS_YEAR_NOT_OPERATIONAL` | Enrollment de otro año | “Se corrige el histórico igual que el vigente” |
| `INVESTITURE_DURATION_MIN_NOT_MET` / `EXPIRED` | Años eclesiásticos fuera de rango | Investidura el mismo día del alta si `min>0` |
| `INVESTITURE_REQUIREMENTS_INCOMPLETE` | Elegibilidad BASIC+EXTRA incompleta | Enviar “casi listo” |
| Rechazo | Motivo obligatorio; vuelve editable | Que el rechazo borre el progreso |

Carga masiva OCR de certificados escribe sobre `enrollments` e historial; no
es el checklist cotidiano. No mezclarla en el recorrido principal
(`docs/features/clases-progresivas.md`:150-154).

## Disponibilidad por superficie

| Superficie | Trazado | Límite |
|---|---|---|
| Backend | Catálogo, enroll, progreso, submit de requisito, política, pipeline de investidura, vencimiento manual | Código + API; no despliegue |
| App | Camino, detalle con tracks, carga/envío de requisito, envío de investidura, pendientes, historial, alcance pedagógico | Ruta legacy de submit; `InvestitureSubmitView` sin ruta |
| Admin | CRUD de catálogo, asignaciones en ficha de sección, pipeline/config de investidura, expire-overdue | El CRUD de catálogo **no** opera progreso de miembros |
| Pruebas | Specs de política, progreso bloqueado, consejero GM, investidura | Leídas, no ejecutadas |
| Producción | Permisos reales, `investiture_config` por campo, cuentas del piloto | Pendiente de ensayo |

## Guion de demo ficticio

Personajes: “Miembro Demo 01” (Conquistadores, clase del año), “Consejero
Demo”, “Director Demo”, “Coordinador Demo”. Correos `*.invalid`. Sin datos
reales.

1. Abrir “Mi Camino”: nodo cursando vs por cursar vs investido. Decir: la
   edad del nodo es `minimum_age`, no un rango de track.
2. Entrar a un requisito BASIC: cargar archivo y **enviar**. Mostrar que
   sigue sin ser clase investida.
3. Como consejero: lista pedagógica → miembro → mismo detalle. Distinguir
   cargo de director vs clase asignada.
4. Cuando la tarjeta muestre 100%: enviar a validación **como consejero o
   director**. Mostrar bloqueo. Si el miembro no tiene ese rol, la tarjeta
   pide que otro lo envíe.
5. Como director: `club-approve`. Como coordinador/admin: etapas siguientes
   hasta `INVESTIDO` (o detenerse en “enviado al club” si el piloto no tiene
   campo configurado).
6. Verbalizar: honores relacionados se ven, no cierran esta clase. Ciclo
   anual y alta inicial son otros actos.

Si falta `investiture_config` del campo, el envío falla: es un hallazgo de
piloto, no un fallo de “la clase no está al 100%”.

## Fuentes

- Canon: `docs/canon/dominio-sacdia.md` (proceso formativo e investidura).
- Dominio: `docs/features/clases-progresivas.md`,
  `docs/features/validacion-investiduras.md`.
- Contrato: `docs/api/ENDPOINTS-LIVE-REFERENCE.md` (classes, counselor
  assignments, progress-scope, investiture).
- Código citado en esta ficha: `classes.service.ts`,
  `class-enrollment-policy.service.ts`, `next-class.resolver.ts`,
  `class-assignment-resolver.service.ts`,
  `class-requirement-eligibility.service.ts`,
  `class-progress-access.service.ts`,
  `class-counselor-assignments.service.ts`,
  `investiture.controller.ts`, `investiture.service.ts`,
  `class_detail_with_progress_view.dart`,
  `investiture_remote_data_source.dart`.
- Relacionadas: [02](02-revision-evidencias.md), [06](06-ingreso-inicial.md),
  [07](07-inscripcion-anual.md).

**No cubierto aquí (sigue en bloque 4):** circuito de honores
(inscripción, evidencias, validación propia) y certificaciones de Guías
Mayores.
