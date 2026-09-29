# 09 · Especialidades (honores): inscripción, caminos y revisión

**Estado:** DRAFT · **Revisión de código local:** 2026-09-14  
**Alcance:** cómo una persona cursa una especialidad y cómo se reconoce.
Maestrías se cubren aquí como consecuencia automática, no como segundo
pipeline. Certificaciones de Guías Mayores quedan fuera.

> En pantalla y en la cita decir **especialidad**. En API, tablas y eventos
> el nombre interno sigue siendo `honor`. No reemplaza el canon ni certifica
> despliegue. Clases e investidura: [08](08-clases-progresivas.md). Cola de
> revisión: [02](02-revision-evidencias.md).

## Cinco mensajes para la presentación

1. **No es una clase.** No vive en el año eclesiástico. Un registro por
   persona y especialidad (`users_honors`). Aprobarla no investe una clase;
   una especialidad ligada a una clase **no** cierra la investidura.
2. **La persona elige el camino y ella misma envía.** Tras inscribirse el
   modo queda `UNDECIDED` hasta confirmar `IN_APP` (en la app) o `EXTERNAL`
   (formato fuera). El envío es `POST /validation/submit` con
   `entity_id = user_honor_id`, y el backend exige que el dueño sea quien
   envía.
3. **Revisión en un solo acto.** `admin` / `super-admin` / `coordinator` con
   `validation:review` aprueban o rechazan el paquete completo. No hay
   club → coordinación → campo como en investidura.
4. **La cola mira el paquete, no un archivo suelto.** El detalle agrega modo,
   formato, requisitos, respuestas y evidencias
   (`honor_review_packet`).
5. **La maestría no se “pide”.** Se evalúa cuando una especialidad se
   aprueba, se pierde o cambian las reglas. Puede quedar **No vigente**
   (`REVOKED` / `RETIRED`) sin borrar el histórico.

## Cómo leer la evidencia

Canon/contrato, código, specs leídas (no ejecutadas), disponibilidad no
ensayada. `users_honors.validate` es legado; manda `validation_status`.

## Vocabulario

| Término | Significado | No confundir con |
|---|---|---|
| Especialidad / honor | Unidad del catálogo `honors` | Clase progresiva |
| `users_honors` | Inscripción de una persona | `enrollments` del año |
| `completion_mode` | Camino de trabajo | Estado de revisión |
| `validation_status` | `IN_PROGRESS` / `PENDING_REVIEW` / `APPROVED` / `REJECTED` | Pipeline de investidura |
| Maestría | Parche por especialidades ya `APPROVED` | Segunda revisión humana |
| `class_honors` | Relación informativa con una clase | Requisito que bloquea investidura |

Identidad estable del catálogo: `honors.code`, no el nombre visible.

## Recorrido

```text
Catálogo (filtrado por sección activa)
  └─ Inscribirme → users_honors IN_PROGRESS, modo UNDECIDED
        ├─ IN_APP: requisitos, respuesta, evidencia puntual
        └─ EXTERNAL: formato PDF + evidencias generales
              └─ POST /validation/submit (dueño + validation:submit)
                    → PENDING_REVIEW (no editable)
                          ├─ evidence-review APPROVED
                          │     → evalúa maestrías; notifica “especialidad”
                          └─ REJECTED + motivo
                                → corrige (modified_at > validated_at) y reenvía
```

### Paso 1 — Ver e inscribir

Catálogo unificado. La visibilidad por tipo de club se declara en
`honor_club_types`; `honors.club_type_id` es legado.

**App (catálogo):** Aventureros ve tipo 1; Conquistadores ve tipo 2; Guías
Mayores ve tipos 2 y 3
(`honors_providers.dart`:616-627, 696-703). Sin sección activa, muestra el
catálogo cargado (fallback). No hay selector “todas las ramas” cuando ya hay
contexto.

**Backend al inscribir:** exige sección activa
(`HONOR_ACTIVE_SECTION_REQUIRED`) y compara `honors.club_type_id` con un
pool: Aventureros = [1]; Conquistadores **o** Guías Mayores = [2, 3]
(`honors.service.ts`:405-449). Una sección de Conquistadores **puede**
inscribir una especialidad de GM por API aunque la app no la liste. Gap ya
anotado en el dominio; no vender paridad perfecta.

`POST /users/:userId/honors/:honorId` (`startHonor`) crea o reactiva. Si ya
está activa: `HONOR_USER_ALREADY_IN_PROGRESS`. Reactivar limpia modo,
archivos y validación y vuelve a `UNDECIDED`
(`honors.service.ts`:486-608). Permiso `user_honors:create` sobre el
`userId`. Abandonar (`DELETE`) pone `active=false`; no borra la fila única.

Desde una clase, el carrusel usa el mismo `POST`; la relación `class_honors`
es informativa ([08](08-clases-progresivas.md)). Un evento de camporee puede
mostrar PDF de preparación; eso **no** inscribe.

### Paso 2 — Elegir camino

`PATCH .../honors/:honorId` con `completionMode` mientras el estado sea
mutable (`IN_PROGRESS` o `REJECTED`). `PENDING_REVIEW` y `APPROVED`
bloquean (`HONOR_MUTATION_BLOCKED_STATUSES`,
`honors.service.ts`:46, 1186-1199). La app pide confirmación y no reabre el
selector al navegar.

Sin camino: `VALIDATION_HONOR_COMPLETION_MODE_REQUIRED`.

| Modo | Trabajo | Elegibilidad de envío |
|---|---|---|
| `IN_APP` | Árbol de requisitos; hoja con respuesta; evidencia si `requires_evidence` | Hojas/grupos (`choice_min`) completos + evidencia puntual donde aplica |
| `EXTERNAL` | Formato en `document` + evidencias generales (`images` o `evidence_files`) | Formato no vacío **y** al menos una evidencia general |
| `UNDECIDED` | Solo elegir camino | No se envía |

En `EXTERNAL` el checklist no bloquea. Límite de evidencias generales: 10
imágenes en `images`; el PDF de formato no consume ese cupo.

La app exige texto para marcar un requisito; el submit `IN_APP` del backend
mira `completed` y evidencias, **no** revalida `text_response`
(`honor-validation-workflow.service.ts`:308-333, 377-447;
`honor-requirements.service.ts`:200-223). No afirmar que el servidor exige
el mismo texto que la UI.

### Paso 3 — Enviar

Dueño + `validation:submit` + `active_assignment`
(`validation.controller.ts`:44-71). El workflow rechaza si el `user_id` no
es el actor (`VALIDATION_HONOR_NOT_OWNED`,
`honor-validation-workflow.service.ts`:71-80). **No** es el envío de
investidura (ficha 08: consejero/director).

La app llama `POST /validation/submit` con `entity_type=honor` y
`entity_id=user_honor_id` (`honor_evidence_view.dart`:157-161;
`validation_remote_data_source.dart`:62-75). Ese mismo endpoint acepta
`class`; para clases el circuito canónico de reconocimiento es investidura,
no este submit.

Tras envío: `PENDING_REVIEW`, `submitted_at`, log `submitted`, notificación
interna `validation:honor_submitted` con copy “Especialidad lista para
revisar”.

Rechazo sin cambios posteriores: `VALIDATION_HONOR_NO_CHANGES_AFTER_REJECTION`
(`modified_at <= validated_at`).

### Paso 4 — Revisar

Misma cola que evidencias de clase, filtro `type=honor`:

`GET /evidence-review/pending?type=honor`  
`POST /evidence-review/honor/:id/approve|reject`

Roles: `admin`, `super-admin`, `coordinator` + `validation:review`
(`evidence-review.controller.ts`:38-41). El servicio **delega** en
`HonorValidationWorkflowService` (no duplicar reglas). Solo desde
`PENDING_REVIEW`. Rechazo exige motivo. Bulk hasta 200, un solo tipo por
lote.

El detalle trae `honor_review_packet` (modo, formato, avance, respuestas,
adjuntos). Aprobar mirando solo una foto general es el anti-patrón que el
paquete evita.

App coordinador: lista/detalle ruteados. Panel: diálogo de evidencia con
paquete. Catálogo admin: `/admin/honors-catalog`, requisitos, maestrías.
Pantallas viejas que mutan `POST /honors` se consideran stale.

### Paso 5 — Maestrías

No hay submit de maestría. Criterio: especialidades `APPROVED` y `active`.
Estados de usuario: `AWARDED` (Vigente), `REVOKED` / `RETIRED` (No vigente).
El registro no se borra.

Se recalcula al aprobar/desaprobar/desactivar, al cambiar reglas o con
`POST /admin/master-honors/:id/recalculate`. Historial con snapshot.
App: `/home/master-honors`, banda de tarjeta, modal agrupado
`master_honor_changed`.

## Matriz actor × acción

| Acción | Quién (backend) | Superficie |
|---|---|---|
| Consultar catálogo | JWT (catálogo público) | App; filtro local por sección |
| Inscribir / reactivar / abandonar | `user_honors:create` / `delete` sobre el usuario | App |
| Elegir modo y cargar trabajo | `user_honors:submit` / `create`; dueño; estado mutable | App IN_APP o EXTERNAL |
| Enviar a revisión | Dueño + `validation:submit` | App |
| Aprobar / rechazar | admin, super-admin, coordinator + `validation:review` | App coordinador + panel |
| Configurar catálogo / maestrías | admin, super-admin + permisos honors:* | Panel |
| Recibir maestría | Sistema | App (roadmap / tarjeta) |

El consejero de clase **no** sustituye al miembro en el submit de
especialidad. Puede coincidir como coordinador en la cola si tiene ese rol
global.

## Contraste con clases (para no mezclarlos en la cita)

| | Especialidad | Clase (ficha 08) |
|---|---|---|
| Tiempo | Sin año eclesiástico; una fila por persona | Enrollment por año |
| Quién envía | El miembro | Consejero o director (investidura) |
| Revisión | Un paso en evidence-review | Club → coordinación → campo → INVESTIDO |
| Ligazón mutua | `class_honors` informativo | Honores no cierran la clase |
| Copy | “Especialidad” | “Clase” / “investidura” |

La cola [02](02-revision-evidencias.md) mezcla tipos. Para honor, el `id` es
`user_honor_id` (el paquete entero). Para clase, el ítem de esa cola es un
**requisito** enviado, no la investidura.

## Excepciones que la demo debe nombrar

| Código / resultado | Significado | Qué no decir |
|---|---|---|
| `HONOR_ACTIVE_SECTION_REQUIRED` | Sin sección activa no inscribe | “El catálogo basta para cursar” |
| `HONOR_CLUB_TYPE_NOT_ALLOWED` | Tipo no permitido en esa sección | Que app y API filtran igual |
| `HONOR_USER_ALREADY_IN_PROGRESS` | Ya está activa | Duplicar la misma especialidad |
| `VALIDATION_HONOR_COMPLETION_MODE_REQUIRED` | No eligió camino | Enviar desde UNDECIDED |
| `VALIDATION_HONOR_REQUIREMENTS_INCOMPLETE` / `_MISSING_EVIDENCE` | Falta trabajo del modo | “La UI habilitó el botón, ya está” |
| `VALIDATION_HONOR_NOT_OWNED` | Otro usuario no envía | Que el consejero envía como en la clase |
| `VALIDATION_HONOR_NO_CHANGES_AFTER_REJECTION` | Reenvío sin corrección | Reenviar el mismo paquete |
| `VALIDATION_HONOR_ALREADY_PENDING` / `_VALIDATED` | Ya en cola o aprobada | Editar mientras se revisa |
| Maestría No vigente | Dejó de cumplir reglas | Que “se perdió el parche para siempre” |

Carga masiva OCR escribe en `users_honors` + `evidence_files`. No es el
recorrido cotidiano.

## Disponibilidad por superficie

| Superficie | Trazado | Límite |
|---|---|---|
| Backend | Catálogo, start/update/abandon, requisitos, workflow, evidence-review, maestrías | Inscripción usa `club_type_id` legado; catálogo `honor_club_types` |
| App | Catálogo filtrado, modos, submit, cola coordinador, roadmap de maestrías | Filtro CQ más estricto que el pool de enroll |
| Admin | Catálogo, requisitos, maestrías, revisión con paquete | CRUD contra `/admin/*`, no `/honors` público |
| Pruebas | Specs de workflow, modos, enroll por tipo | Leídas, no ejecutadas |
| Producción | Permiso `validation:submit` real, coordinadores del piloto | Pendiente de ensayo |

## Guion de demo ficticio

Copy en voz: **especialidad**, no “honor”.

1. Sección Conquistadores: catálogo sin especialidades solo de GM. Decir que
   Guías Mayores sí reutilizan las de Conquistadores.
2. Inscribir → selector de camino. Confirmar `IN_APP` o `EXTERNAL` (uno
   basta).
3. Completar el mínimo del modo. Mostrar que sin envío sigue “en progreso”.
4. Enviar. Estado “enviado”. Intentar editar: bloqueado.
5. Como coordinador: cola `honor`, abrir paquete, aprobar. Copy de
   notificación: especialidad aprobada.
6. Si hay maestría configurable: vigente o no vigente. No pedir “validar
   maestría”.
7. Verbalizar: esto no cierra la clase ni reemplaza la investidura.

## Fuentes

- Dominio: `docs/features/honores.md`.
- Contrato: `docs/api/ENDPOINTS-LIVE-REFERENCE.md` (honors, user-honors,
  evidence-review, validation/submit, master-honors).
- Código: `honors.service.ts`, `honor-validation-workflow.service.ts`,
  `honor-requirements.service.ts`, `validation.controller.ts`,
  `evidence-review.controller.ts`, `honors_providers.dart`,
  `honor_evidence_view.dart`, `validation_remote_data_source.dart`.
- Relacionadas: [02](02-revision-evidencias.md), [08](08-clases-progresivas.md).

**Sigue en bloque 4:** certificaciones de Guías Mayores (recorte corto), no
el catálogo entero.
