# Honores (Especialidades)

**Estado**: IMPLEMENTADO — workflow de validacion backend por modo, paquete de revision admin y maestrías configurables en rollout cross-repo.

## Descripcion de dominio

Los honores (especialidades) son unidades formativas independientes que los miembros de clubes de Aventureros, Conquistadores y Guias Mayores pueden cursar para profundizar en areas de conocimiento especificas. Cada honor pertenece a una categoria tematica y puede estar asociado a un tipo de club.

El catalogo de especialidades sigue siendo unico: Aventureros, Conquistadores y Guias Mayores no tienen tablas separadas de honores. La disponibilidad por tipo de club se modela con `honor_club_types`, mientras que la relacion curricular con una clase especifica se modela con `class_honors`.

El ciclo funcional es:

1. Catalogo publico de consulta.
2. Inscripcion del usuario en un honor con modo inicial `UNDECIDED`.
3. Eleccion de modo de finalizacion: dentro de la app (`IN_APP`) o fuera de la app (`EXTERNAL`).
4. Si el modo es `IN_APP`, avance por requisitos, respuestas y evidencia puntual por requisito cuando aplique.
5. Si el modo es `EXTERNAL`, descarga del formato/material, carga del formato completado como `document` y carga de evidencias generales.
6. Envio a revision institucional segun reglas del modo elegido.
7. Aprobacion o rechazo por revisor autorizado.
8. Correccion y reenvio cuando corresponde.

## Fuente de verdad de estado

La fuente de verdad runtime para honores de usuario es `users_honors.validation_status`:

| Estado | Significado |
|---|---|
| `IN_PROGRESS` | Honor inscrito/en avance. Editable por el usuario. |
| `PENDING_REVIEW` | Enviado a revision institucional. No debe tratarse como editable libremente. |
| `APPROVED` | Honor aprobado institucionalmente. |
| `REJECTED` | Honor rechazado; el usuario puede corregir y reenviar si hay cambios nuevos. |

`users_honors.validate` se mantiene solo por compatibilidad con codigo legado. No debe usarse como fuente primaria de decision.

## Catalogo unificado y aplicabilidad

La fuente de verdad del catalogo es `honors`. El campo `honors.code` es el identificador estable para imports y sincronizaciones; el nombre visible ya no debe usarse como identidad global porque puede repetirse entre programas o niveles.

La elegibilidad/visibilidad por tipo de club vive en `honor_club_types`:

```text
honor_id + club_type_id + active
```

Por eso `clubTypeId` en el catalogo publico filtra por aplicabilidad activa, no por el campo legacy `honors.club_type_id`.

`honors.club_type_id` se conserva temporalmente por compatibilidad con pantallas y procesos legacy durante el rollout. No debe usarse como fuente nueva de elegibilidad.

La relacion entre una especialidad y una clase vive en `class_honors`:

```text
class_id + honor_id + relation_type + module_id? + active
```

Esto permite que una especialidad de Aventureros sea especifica de una clase sin mezclar niveles de clase con categorias tematicas. Las especialidades multinivel pueden existir sin enlace a una clase concreta. `module_id` ancla la especialidad a un módulo de la misma clase (`ON DELETE SET NULL`); las filas existentes quedan con `module_id` null (nivel de clase).

**Runtime activo:** `GET /api/v1/classes/:classId/honors` (Optional JWT; con usuario incluye `user_status` desde `users_honors.validation_status`; también `module_id`, `module_name`, `material_url`) y CRUD admin `GET/POST/PATCH/DELETE /api/v1/admin/classes/:classId/honors`. `PATCH` asigna o limpia el módulo (`module_id: null`). Los módulos de `GET /classes/:classId` y `GET /classes/:classId/modules` embeben `honors[]` (sin `user_status`). En esta fase las relaciones son informativas: no bloquean progreso de módulo ni investidura, incluso `REQUIRED`. La app muestra todas las especialidades de la clase en el carrusel de sugerencias (con o sin módulo) y las repite en el módulo anclado; abre el PDF público (`honors.material_url`) e inscribe por el flujo existente `POST /users/:userId/honors`.

## Modo de finalizacion

La fuente de verdad runtime para el camino de trabajo de una especialidad inscrita es `users_honors.completion_mode`:

| Modo | Significado |
|---|---|
| `UNDECIDED` | Honor inscrito sin camino elegido. No puede enviarse a revision. |
| `IN_APP` | El miembro completa requisitos, respuestas y evidencias puntuales dentro de la app. |
| `EXTERNAL` | El miembro completa el formato fuera de la app, lo sube como documento y adjunta evidencias generales. |

Nuevas inscripciones y reactivaciones arrancan en `UNDECIDED`. El modo puede seleccionarse desde `PATCH /api/v1/users/:userId/honors/:honorId` con `completionMode` mientras el honor sea mutable. La app debe pedir confirmacion antes de persistir la seleccion, actualizar todas las vistas del flujo con el modo confirmado y no volver a pedir camino al navegar entre detalle, requisitos o evidencias. Si el miembro cambia de camino despues, debe hacerlo mediante una accion explicita de cambio de modo. El backend es la fuente canonica: la app guia la UX, pero la elegibilidad final se decide en backend.

Los estados `PENDING_REVIEW` y `APPROVED` bloquean cambios libres de modo y de archivos. Un honor rechazado puede corregirse y reenviarse si hay cambios posteriores al rechazo.

Los honores aprobados legacy anteriores a `completion_mode` no deben seguir en `UNDECIDED` si tienen artefactos externos (`document`, `certificate`, `images` o `evidence_files`). Esos registros se backfillean como `EXTERNAL` para no mostrar un estado imposible en el historico.

## Notificaciones visibles

Las notificaciones generadas por validación y logros deben usar la nomenclatura visible **especialidad**:

- `validation:honor_submitted` muestra “Especialidad lista para revisar”.
- `validation:honor_approved` muestra “¡Tu especialidad fue aprobada!”.
- `validation:honor_rejected` muestra “Tu especialidad necesita ajustes”.
- Los logros de especialidades deben evitar mostrar “Honor” en el cuerpo visible, aunque el evento interno siga siendo `honor.validated`.

Los contratos internos se mantienen como `entity_type = "honor"` y `validation:honor_*` para no romper API, datos históricos ni filtros existentes.

## Maestrías de especialidades

Las maestrías (`master_honors`) son parches/logros de banda derivados de especialidades aprobadas. No son un segundo flujo de revisión: se otorgan automáticamente porque solo cuentan especialidades previamente validadas.

### Fuente de verdad

La fuente de elegibilidad para una maestría es:

```text
users_honors.validation_status = APPROVED
users_honors.active = true
```

La fuente de estado de usuario es `users_master_honors.status`:

| Estado | Etiqueta app | Significado |
|---|---|---|
| `AWARDED` | `Vigente` | El usuario cumple los criterios actuales. |
| `REVOKED` | `No vigente` | El usuario obtuvo la maestría, pero ya no cumple los criterios vigentes. |
| `RETIRED` | `No vigente` | La maestría fue desactivada/retirada, pero se conserva el histórico. |

`REVOKED` y `RETIRED` no eliminan el registro del usuario. La banda digital y el perfil deben seguir mostrando la maestría con la leyenda **No vigente**.

### Reglas configurables

Las reglas viven en el subdominio de honores, no en `achievements`. Una maestría puede combinar:

- mínimos desde una lista explícita de especialidades;
- mínimos desde una categoría;
- grupos compuestos, donde todos los grupos activos deben cumplirse;
- opciones equivalentes configurables, donde varias especialidades pueden contar como una sola opción.

Las reglas son globales. La aplicabilidad puede ser para todas las divisiones o para divisiones específicas. En el primer otorgamiento se usa la división del club activo y se guarda `awarded_division_id` como contexto histórico; las reevaluaciones usan esa división histórica.

`honors.master_honors_id` no es fuente de verdad para requisitos. Puede servir como relación de catálogo legacy, pero la evaluación usa `master_honor_requirement_groups`, `master_honor_requirement_options` y `master_honor_requirement_option_honors`.

### Evaluación y recálculo

El backend reevalúa maestrías cuando:

- una especialidad del usuario se aprueba, deja de estar aprobada o se desactiva;
- se cambian reglas, divisiones aplicables o estado activo de una maestría;
- un admin ejecuta recálculo manual.

Cada cambio se registra en `master_honor_evaluation_history` con `evaluation_snapshot` para explicar por qué se otorgó, recuperó o marcó como **No vigente**.

### Admin

La configuración vive en el catálogo admin de maestrías:

```http
GET /api/v1/admin/master-honors
POST /api/v1/admin/master-honors
PATCH /api/v1/admin/master-honors/:id
DELETE /api/v1/admin/master-honors/:id
POST /api/v1/admin/master-honors/:id/recalculate
```

Solo admin y super-admin deben editar reglas en esta fase. Al guardar cambios, el backend persiste reglas y encola recálculo para usuarios afectados cuando la cola está disponible.

### App móvil

La app consume:

```http
GET /api/v1/users/:userId/master-honors
GET /api/v1/users/:userId/master-honors/roadmap
GET /api/v1/users/:userId/master-honors/:masterHonorId
```

La tarjeta virtual muestra maestrías vigentes y **No vigente** en la banda. El perfil muestra solo un resumen compacto, similar al resumen de logros: conteo, logos circulares de maestrías obtenidas y un acceso a la pantalla dedicada de maestrías. La pantalla dedicada (`/home/master-honors`) lista el roadmap completo y permite abrir el detalle con avance y requisitos pendientes. Para esto usa `roadmap` y no infiere reglas desde `honors.master_honors_id`. La app debe invalidar estos datos cuando recibe una notificación de cambio de maestría.

### Notificaciones y modal global

El backend emite notificaciones de cambio de maestría con `type = master_honor_changed`. La app agrupa varias maestrías en un solo modal global para evitar apilar diálogos.

Para validación de especialidades, el contrato técnico conserva `entity_type = "honor"` y fuentes `validation:honor_*`, pero el copy visible al usuario debe decir **especialidad**: "Especialidad lista para revisar", "¡Tu especialidad fue aprobada!" y "Tu especialidad necesita ajustes".

Casos que notifican:

- maestría obtenida;
- maestría recuperada;
- maestría marcada como **No vigente**.

El copy de producto debe usar español neutral, sin modismos regionales.

Ejemplo de copy para **No vigente**:

```text
La maestría {nombre} necesita ajustes para volver a estar vigente.
```

## Backend

### Catalogo publico

Controlador: `HonorsController`.

- `GET /honors` — listar honores con paginacion y filtros (`categoryId`, `clubTypeId`, `skillLevel`).
- `GET /honors/categories` — listar categorias.
- `GET /honors/grouped-by-category` — agrupar honores por categoria.
- `GET /honors/:honorId` — detalle.
- `GET /honors/:honorId/requirements` — requisitos del honor.

### Honores de usuario

Controladores: `UserHonorsController` y `UserHonorRequirementsController`.

- `GET /users/:userId/honors`
- `GET /users/:userId/honors/stats`
- `POST /users/:userId/honors`
- `POST /users/:userId/honors/bulk`
- `POST /users/:userId/honors/:honorId`
- `POST /users/:userId/honors/:honorId/files`
- `PATCH /users/:userId/honors/:honorId`
- `DELETE /users/:userId/honors/:honorId`
- `GET /users/:userId/honors/:honorId/requirements/progress`
- `PATCH /users/:userId/honors/:honorId/requirements/:requirementId/progress`
- `PATCH /users/:userId/honors/:honorId/requirements/progress/batch`
- Endpoints de evidencia por requisito: upload/link/list/delete.

### Workflow de validacion

Servicio canonico: `HonorValidationWorkflowService`.

Responsabilidades:

- Enviar honor a revision.
- Validar elegibilidad antes del submit.
- Aprobar honor.
- Rechazar honor.
- Sincronizar `validate` solo por compatibilidad.
- Registrar `validation_logs`.
- Emitir evento `honor.validated` al aprobar.

El submit se realiza con:

```http
POST /api/v1/validation/submit
```

Body:

```json
{ "entity_type": "honor", "entity_id": 123 }
```

`entity_id` es `users_honors.user_honor_id`, no `honors.honor_id`.

El backend bloquea el submit si:

- el honor no pertenece al usuario;
- el honor esta inactivo;
- ya esta aprobado;
- ya esta pendiente;
- el estado no permite submit;
- `completion_mode` esta en `UNDECIDED` o ausente para un honor editable;
- en modo `IN_APP`, faltan requisitos hoja obligatorios, no se cumple `choice_min` en grupos de opcion, o falta evidencia activa en requisitos marcados `requires_evidence`;
- en modo `EXTERNAL`, falta el formato completado en `document` o no existe al menos una evidencia general;
- fue rechazado y no hubo cambios posteriores al rechazo.

## Requisitos por especialidad

Cada honor puede tener requisitos en `honor_requirements`. El avance del usuario vive en `user_honor_requirement_progress`.

En modo `IN_APP`, la app muestra estos requisitos como checklist/arbol de trabajo. Las respuestas textuales viven en `user_honor_requirement_progress.text_response` y las evidencias puntuales viven en `requirement_evidence`.

En modo `EXTERNAL`, el checklist no es requisito de elegibilidad para submit. Puede existir progreso legacy, pero el backend no lo usa como bloqueo del flujo externo.

La regla importante es esta: **la UI puede anticipar bloqueos, pero el backend decide si el honor puede enviarse a revision**.

Cuando el usuario cambia progreso o evidencia por requisito, el backend actualiza `users_honors.modified_at`. Esto permite bloquear reenvios de honores rechazados si el usuario no corrigio nada.

## Evidencias

Hay tres superficies historicas de evidencia:

- `users_honors.document` — formato completado en modo `EXTERNAL`.
- `users_honors.images` y `certificate` — evidencia general legacy/actual de la app.
- `evidence_files.user_honor_id` — evidencia normalizada, usada por carga masiva y revision.
- `requirement_evidence` — evidencia asociada a requisitos concretos.

El limite vigente para evidencia general es de 10 imagenes totales en `users_honors.images`; `document` no consume ese cupo. El backend valida el total existente + nuevo, no solo el tamaño del request.

El flujo vigente no migra todo a una sola tabla. En su lugar, `GET /evidence-review/honor/:id` agrega un `honor_review_packet` que unifica para revision:

- modo de finalizacion (`completion_mode`);
- formato completado (`completed_format_file`) cuando exista;
- progreso total del honor;
- requisitos completados/pendientes, incluyendo `text_response`;
- evidencia general legacy/normalizada;
- evidencia por requisito.

`files` en el detalle de revision tambien incluye la evidencia reviewable agregada para que el panel pueda mostrar todos los adjuntos sin conocer las tablas historicas.

## App movil

La app Flutter consume:

- catalogo publico;
- inscripcion/inicio del honor;
- progreso por requisitos;
- carga de evidencia;
- `POST /validation/submit` para enviar a revision.
- detalle de evento de camporee en solo lectura: especialidades de preparación con PDF (`material_url`) vía `SacPdfViewer`. Ese vínculo no inscribe ni abre el flujo de cursar.

El catalogo movil se filtra por la seccion activa y no debe exponer un selector manual "Todas / Aventureros / Conquistadores-Guías" cuando ya existe contexto de seccion. La regla vigente es asimetrica: Aventureros ve `club_type_id = 1`; Conquistadores ve solo `club_type_id = 2`; Guias Mayores ve `club_type_id = 2` y `club_type_id = 3`, porque puede reutilizar especialidades de Conquistadores y ademas tener especialidades exclusivas de Guias Mayores. Si no existe contexto de seccion activa, la app puede mostrar el catalogo cargado completo como fallback defensivo.

La app debe tratar `validation_status` como estado canonico de revision y `completion_mode` como estado canonico del camino de trabajo:

- `UNDECIDED`: mostrar selector de modo y no mezclar CTAs de checklist/formato.
- `IN_APP`: mostrar requisitos, respuestas y evidencia por requisito; no pedir formato completado como accion primaria.
- `EXTERNAL`: mostrar descarga de formato/material, carga de `document`, evidencias generales y submit; no exigir checklist como accion primaria.

El perfil funciona como superficie de continuidad del trabajo del miembro. Al tocar una especialidad ya inscrita desde Perfil, la app debe abrir directamente el flujo activo segun `completion_mode`: requisitos para `IN_APP`, evidencias/formato para `EXTERNAL`, y detalle con selector solo si sigue en `UNDECIDED`. Las especialidades `APPROVED` abren el detalle historico para mostrar validacion y evidencia registrada.

Despues de una seleccion exitosa, detalle, requisitos y evidencias deben resolver el mismo `completion_mode` efectivo. Si una respuesta o refetch llega desfasado temporalmente, la app puede conservar el modo confirmado por el usuario en el estado de sesion hasta que backend devuelva el mismo estado canonico.

Puede deshabilitar botones por UX, pero no debe asumir que un honor es enviable sin respuesta backend.

Cuando `validation_status = APPROVED`, la pantalla de detalle debe dejar de mostrar el bloqueo de cambio de modo como mensaje principal. En su lugar debe mostrar un historico de lectura: modo registrado, fechas de inscripcion/envio/validacion, nombre y rol del revisor (`validated_by_name`, `validated_by_role_name`, `validated_by_role_label`), formato/evidencias generales para flujo externo y respuestas/evidencias por requisito para flujo dentro de la app. La UI no debe mostrar UUIDs de validador como texto principal de usuario.

## Panel administrativo

La revision institucional actual entra por:

```http
GET /api/v1/evidence-review/pending?type=honor
POST /api/v1/evidence-review/honor/:id/approve
POST /api/v1/evidence-review/honor/:id/reject
```

`EvidenceReviewService` delega las acciones de honor al `HonorValidationWorkflowService`, para evitar reglas duplicadas.

El detalle de un honor pendiente expone `honor_review_packet` y el panel muestra el modo de finalizacion, formato completado si aplica, avance del honor, conteo de requisitos, porcentaje completado, respuestas textuales y evidencias asociadas a requisitos. Esto evita que el revisor apruebe/rechace mirando solo archivos generales.

Para catalogo, la superficie correcta es la que consume endpoints admin (`/admin/honors-catalog`, `/admin/master-honors`, `/admin/honor-categories`). La pantalla historica que muta `/honors` debe considerarse stale si intenta crear/editar contra endpoints publicos no implementados.

## Carga masiva por certificados OCR

Los honores aprobados desde carga masiva por certificado se aplican en `users_honors` y adjuntan comprobante en `evidence_files.user_honor_id`. El flujo no crea una fuente paralela de especialidades: `certificate_bulk_import_*` conserva staging/auditoria y la verdad final sigue en `users_honors`.

## Gaps y pendientes

- Revisar/migrar pantallas admin stale que intentan mutar `/honors` en vez de endpoints `/admin/*`.
- Evaluar validacion cruzada entre tipo de club del usuario y `honors.club_type_id` al inscribirse.
- En una fase posterior, deprecar formalmente `users_honors.validate` como fuente de lectura.
