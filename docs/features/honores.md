# Honores (Especialidades)

**Estado**: IMPLEMENTADO — workflow de validacion backend normalizado, paquete de revision admin y maestrías configurables en rollout cross-repo.

## Descripcion de dominio

Los honores (especialidades) son unidades formativas independientes que los miembros de clubes de Aventureros, Conquistadores y Guias Mayores pueden cursar para profundizar en areas de conocimiento especificas. Cada honor pertenece a una categoria tematica y puede estar asociado a un tipo de club.

El ciclo funcional es:

1. Catalogo publico de consulta.
2. Inscripcion del usuario en un honor.
3. Avance por requisitos/checklist.
4. Carga de evidencias generales o por requisito.
5. Envio a revision institucional.
6. Aprobacion o rechazo por revisor autorizado.
7. Correccion y reenvio cuando corresponde.

## Fuente de verdad de estado

La fuente de verdad runtime para honores de usuario es `users_honors.validation_status`:

| Estado | Significado |
|---|---|
| `IN_PROGRESS` | Honor inscrito/en avance. Editable por el usuario. |
| `PENDING_REVIEW` | Enviado a revision institucional. No debe tratarse como editable libremente. |
| `APPROVED` | Honor aprobado institucionalmente. |
| `REJECTED` | Honor rechazado; el usuario puede corregir y reenviar si hay cambios nuevos. |

`users_honors.validate` se mantiene solo por compatibilidad con codigo legado. No debe usarse como fuente primaria de decision.

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
GET /api/v1/users/:userId/master-honors/:masterHonorId
```

La tarjeta virtual muestra maestrías vigentes y **No vigente** en la banda. El perfil muestra historial con estado y fechas relevantes. La app debe invalidar estos datos cuando recibe una notificación de cambio de maestría.

### Notificaciones y modal global

El backend emite notificaciones de cambio de maestría con `type = master_honor_changed`. La app agrupa varias maestrías en un solo modal global para evitar apilar diálogos.

Casos que notifican:

- maestría obtenida;
- maestría recuperada;
- maestría marcada como **No vigente**.

El copy de producto debe usar español neutral, sin modismos regionales.

Ejemplo de copy para **No vigente**:

```text
Las validaciones requeridas para la maestría {nombre} cambiaron.
Actualmente no cumples con los requisitos, por lo que quedó marcada como No vigente.
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

Desde PR1, el backend bloquea el submit si:

- el honor no pertenece al usuario;
- el honor esta inactivo;
- ya esta aprobado;
- ya esta pendiente;
- el estado no permite submit;
- falta evidencia minima;
- faltan requisitos obligatorios completos;
- fue rechazado y no hubo cambios posteriores al rechazo.

## Requisitos por especialidad

Cada honor puede tener requisitos en `honor_requirements`. El avance del usuario vive en `user_honor_requirement_progress`.

La app muestra estos requisitos como checklist, pero la regla importante es esta: **la UI puede anticipar bloqueos, pero el backend decide si el honor puede enviarse a revision**.

Cuando el usuario cambia progreso o evidencia por requisito, el backend actualiza `users_honors.modified_at`. Esto permite bloquear reenvios de honores rechazados si el usuario no corrigio nada.

## Evidencias

Hay tres superficies historicas de evidencia:

- `users_honors.images`, `certificate`, `document` — evidencia general legacy/actual de la app.
- `evidence_files.user_honor_id` — evidencia normalizada, usada por carga masiva y revision.
- `requirement_evidence` — evidencia asociada a requisitos concretos.

PR2 no migra todo a una sola tabla. En su lugar, `GET /evidence-review/honor/:id` agrega un `honor_review_packet` que unifica para revision:

- progreso total del honor;
- requisitos completados/pendientes;
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

La app debe tratar `validation_status` como estado canonico. Puede deshabilitar botones por UX, pero no debe asumir que un honor es enviable sin respuesta backend.

## Panel administrativo

La revision institucional actual entra por:

```http
GET /api/v1/evidence-review/pending?type=honor
POST /api/v1/evidence-review/honor/:id/approve
POST /api/v1/evidence-review/honor/:id/reject
```

`EvidenceReviewService` delega las acciones de honor al `HonorValidationWorkflowService`, para evitar reglas duplicadas.

El detalle de un honor pendiente expone `honor_review_packet` y el panel muestra el avance del honor, el conteo de requisitos, el porcentaje completado y las evidencias asociadas a requisitos. Esto evita que el revisor apruebe/rechace mirando solo archivos generales.

Para catalogo, la superficie correcta es la que consume endpoints admin (`/admin/honors-catalog`, `/admin/master-honors`, `/admin/honor-categories`). La pantalla historica que muta `/honors` debe considerarse stale si intenta crear/editar contra endpoints publicos no implementados.

## Carga masiva por certificados OCR

Los honores aprobados desde carga masiva por certificado se aplican en `users_honors` y adjuntan comprobante en `evidence_files.user_honor_id`. El flujo no crea una fuente paralela de especialidades: `certificate_bulk_import_*` conserva staging/auditoria y la verdad final sigue en `users_honors`.

## Gaps y pendientes

- Revisar/migrar pantallas admin stale que intentan mutar `/honors` en vez de endpoints `/admin/*`.
- Evaluar validacion cruzada entre tipo de club del usuario y `honors.club_type_id` al inscribirse.
- En una fase posterior, deprecar formalmente `users_honors.validate` como fuente de lectura.
