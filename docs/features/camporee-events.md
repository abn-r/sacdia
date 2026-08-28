# Camporee Events

**Estado**: IMPLEMENTADO PARCIAL
**Última actualización**: 2026-07-20
**Owner**: Backend/App/Admin
**Dominio relacionado**: [camporees.md](./camporees.md)

## Descripción de dominio

Un camporee se compone de **eventos** competitivos donde clubes y miembros son evaluados (orden cerrado, primeros auxilios, nudos, cocina, conocimiento bíblico, deportes, espirituales, etc.). Cada evento tiene reglas, puntuación, materiales requeridos, participantes esperados y penalizaciones.

El dominio camporees modela `local_camporees` y `union_camporees` y cuenta con instancias de eventos en `camporee_events`. Esta feature agrega:

1. Un **catálogo i18n de tipos de evento** administrable. Los códigos base sembrados son `scoring`, `recreational`, `rest`, `spiritual`, `devotional` y `general`.
2. Una **biblioteca de templates reusables** (scoped por unión o por campo local) — un mismo evento se diseña una vez y se reutiliza en varios camporees.
3. **Instancias** del evento asignadas a un camporee concreto (local o de unión) — al asignar un template se clona como instancia editable, permitiendo overrides locales (más participantes, menos puntos, materiales distintos) sin modificar el template original.
4. **Agenda liberable por fecha**: antes de `agenda_visible_from`, la app muestra preview de eventos/requisitos/puntos, pero oculta día/hora/sede/responsables/bloques.
5. **Bloques de agenda opcionales**: un mismo evento puede dividirse en ventanas horarias con asignaciones por sección de club.
6. **Asignaciones flexibles de personal**: cada actividad/evento puede tener responsable y apoyos/evaluadores tomados del roster previo del camporee.

La separación template ↔ instancia evita que ajustes específicos de un camporee contaminen futuros camporees que reutilicen el mismo evento base.

## Decisiones de diseño

- **Catálogo separado para tipos de evento (`camporee_event_types`)**: en vez de un enum hardcodeado, el catálogo es administrable e i18n (Approach X: español en columna principal, traducciones en tabla `_translations`). Razón: permite agregar tipos (cultural, deportivo, técnico) sin migración.
- **Patrón template + instancia (híbrido)**: la instancia (`camporee_events`) se materializa al asignar un template a un camporee. Cambios posteriores en la instancia NO se propagan al template, y cambios al template NO afectan instancias ya creadas. El template queda como punto de partida histórico.
- **Scope del template**: cada template pertenece exclusivamente a una **unión** O a un **campo local** (CHECK constraint exclusivo). Templates de unión son visibles en todos los camporees de unión + camporees de campos locales que pertenecen a esa unión. Templates de campo local solo visibles en camporees de ese campo local.
- **Instancia única tabla**: `camporee_events` con dos FK opcionales (`local_camporee_id`, `union_camporee_id`) + CHECK exclusivo. Evita duplicar lógica de servicio por scope.
- **Penalizaciones como `jsonb`**: lista de reglas `[{description, points_deducted, time_seconds}]` para soportar múltiples penalizaciones por evento.
- **Participantes**: `participants_mode` (`count` | `by_class`). Si `by_class`, `participants_by_class` es jsonb `[{class_id, count}]` referenciando el catálogo `classes` existente.
- **Soft delete (`active`)** y campos de auditoría (`created_at`, `modified_at`, `created_by`, `modified_by`).
- **Reasignar template**: una instancia recuerda el `event_template_id` que la originó (nullable, `ON DELETE SET NULL`) para trazabilidad. Si el template se borra (soft), la instancia sobrevive con datos clonados.
- **Puntuación desacoplada del tipo**: `event_type.code='scoring'` clasifica la agenda, pero el puntaje oficial sólo existe cuando `camporee_events.scoring_enabled=true` y hay rúbricas válidas.
- **Personal operativo desacoplado del scoring**: las asignaciones de agenda (`camporee_event_staff_assignments`) explican quién se encarga de la actividad; las asignaciones de scoring (`camporee_event_judge_assignments`) siguen definiendo quién evalúa una sección y quién puede subir puntaje.
- **Agenda segura para app**: `GET /events/preview` aplica `agenda_visible_from`; los usuarios administrativos con permisos de gestión pueden ver agenda completa por el endpoint normal.

## Estado real verificado (2026-07-06)

- Backend: `CamporeeEventsController` expone lectura y mutación para eventos locales y de unión:
  - `GET /api/v1/local-camporees/:camporeeId/events`
  - `GET /api/v1/local-camporees/:camporeeId/events/preview`
  - `GET /api/v1/union-camporees/:camporeeId/events`
  - `GET /api/v1/union-camporees/:camporeeId/events/preview`
  - `POST /api/v1/local-camporees/:camporeeId/events`
  - `POST /api/v1/union-camporees/:camporeeId/events`
  - `PATCH /api/v1/camporee-events/:eventId`
  - `GET /api/v1/camporee-events/:eventId/staff-assignments`
  - `PUT /api/v1/camporee-events/:eventId/staff-assignments`
  - `PUT /api/v1/camporee-events/:eventId/schedule-blocks`
  - `DELETE /api/v1/camporee-events/:eventId`
- El roster de jueces expone email/notas en sus listados y permite actualización o soft-deactivate por UUID con scope del camporee:
  - `PATCH /api/v1/camporee-judges/:judgeId`
  - `DELETE /api/v1/camporee-judges/:judgeId`
- App móvil: el detalle de Camporí consume `GET /api/v1/local-camporees/:camporeeId/events/preview`; la lista principal muestra sólo icono, nombre y puntaje total. Al abrir un evento, antes de la liberación de agenda se omite horario/sede/bloques, y después se muestra el detalle con día/hora/sede y bloques segmentados si existen.
- RBAC: la lectura móvil de eventos se concede a director, subdirector, secretario, secretario-tesorero, tesorero y consejero con `camporee_events:read`.
- Las respuestas de eventos incluyen `staff_assignments` para conservar el registro operativo, aunque la tarjeta móvil compacta no los muestra por defecto.

## Modelo de datos

### Tabla `camporee_event_types`

| Columna                     | Tipo                    | Notas                                                   |
| --------------------------- | ----------------------- | ------------------------------------------------------- |
| `event_type_id`             | `INT PK`                | autoincrement                                           |
| `code`                      | `VARCHAR(40) UNIQUE`    | slug estable (`spiritual`, `recreational`, `sports`...) |
| `name`                      | `VARCHAR(100) NOT NULL` | nombre en español                                       |
| `description`               | `TEXT NULL`             | descripción opcional                                    |
| `display_order`             | `INT NULL`              | orden sugerido para listas                              |
| `active`                    | `BOOL DEFAULT true`     | soft delete                                             |
| `created_at`, `modified_at` | `TIMESTAMPTZ`           | auditoría                                               |

Tipos base sembrados por migración:

| Código | Uso |
| ------ | --- |
| `scoring` | Evento puntuable/competitivo; requiere `scoring_enabled` + rúbricas para contar puntos |
| `recreational` | Actividad recreativa |
| `rest` | Descanso, comidas o traslados |
| `spiritual` | Culto o actividad espiritual |
| `devotional` | Devocional |
| `general` | Evento general/logístico |

### Tabla `camporee_event_types_translations`

Approach X estándar para i18n: PK `BIGSERIAL`, FK `event_type_id`, `locale` `VARCHAR(10)`, `name`, `description`, `created_at`, `updated_at`. Constraint:

```
@@unique([event_type_id, locale], name: "camporee_event_types_translations_unique_locale",
         map: "camporee_event_types_translations_unique_locale")
@@index([locale])
@@index([event_type_id])
CHECK (locale <> 'es')
ON DELETE CASCADE
```

### Tabla `camporee_event_templates`

| Columna                     | Tipo                                   | Notas                                                   |
| --------------------------- | -------------------------------------- | ------------------------------------------------------- |
| `event_template_id`         | `INT PK`                               |                                                         |
| `scope`                     | `VARCHAR(20) NOT NULL`                 | `'union'` o `'local_field'`                             |
| `union_id`                  | `INT NULL FK unions`                   | exclusivo con `local_field_id`                          |
| `local_field_id`            | `INT NULL FK local_fields`             | exclusivo con `union_id`                                |
| `event_type_id`             | `INT NOT NULL FK camporee_event_types` |                                                         |
| `title`                     | `VARCHAR(150) NOT NULL`                |                                                         |
| `description`               | `TEXT NULL`                            |                                                         |
| `requirements`              | `TEXT NULL`                            | requisitos para participar                              |
| `development`               | `TEXT NULL`                            | desarrollo / cómo se ejecuta                            |
| `prerequisites`             | `TEXT NULL`                            | requisitos previos del club/miembro                     |
| `materials`                 | `TEXT NULL`                            | materiales necesarios                                   |
| `auxiliaries`               | `TEXT NULL`                            | auxiliares / personal de apoyo                          |
| `max_points`                | `INT NOT NULL`                         | puntaje máximo posible                                  |
| `scoring_enabled`           | `BOOL DEFAULT false`                   | habilita rúbricas reutilizables del template            |
| `min_points`                | `INT NOT NULL DEFAULT 0`               | piso de participación                                   |
| `penalties`                 | `JSONB NOT NULL DEFAULT '[]'`          | `[{description, points_deducted, time_seconds}]`        |
| `participants_mode`         | `VARCHAR(20) NOT NULL`                 | `'count'` o `'by_class'`                                |
| `participants_count`        | `INT NULL`                             | requerido si `mode = 'count'`                           |
| `participants_by_class`     | `JSONB NULL`                           | requerido si `mode = 'by_class'`, `[{class_id, count}]` |
| `duration_seconds`          | `INT NULL`                             | duración estimada                                       |
| `active`                    | `BOOL DEFAULT true`                    |                                                         |
| `created_at`, `modified_at` | `TIMESTAMPTZ`                          |                                                         |
| `created_by`, `modified_by` | `UUID NULL FK users`                   |                                                         |

Constraints:

```
CHECK (
  (scope = 'union' AND union_id IS NOT NULL AND local_field_id IS NULL)
  OR
  (scope = 'local_field' AND local_field_id IS NOT NULL AND union_id IS NULL)
)
CHECK (max_points >= min_points)
CHECK (participants_mode IN ('count','by_class'))
CHECK (
  (participants_mode = 'count' AND participants_count IS NOT NULL AND participants_count > 0)
  OR
  (participants_mode = 'by_class' AND participants_by_class IS NOT NULL)
)
@@index([scope, union_id])
@@index([scope, local_field_id])
@@index([event_type_id])
```

### Tabla `camporee_events` (instancias)

| Columna                                                  | Tipo                                                      | Notas                                   |
| -------------------------------------------------------- | --------------------------------------------------------- | --------------------------------------- |
| `camporee_event_id`                                      | `INT PK`                                                  |                                         |
| `local_camporee_id`                                      | `INT NULL FK local_camporees`                             | exclusivo con `union_camporee_id`       |
| `union_camporee_id`                                      | `INT NULL FK union_camporees`                             | exclusivo con `local_camporee_id`       |
| `event_template_id`                                      | `INT NULL FK camporee_event_templates ON DELETE SET NULL` | trazabilidad                            |
| `event_type_id`                                          | `INT NOT NULL FK camporee_event_types`                    | snapshot — sobrevive si template cambia |
| Todos los campos del template                            | (clonados al crear instancia)                             |                                         |
| `display_order`                                          | `INT DEFAULT 0`                                           | orden en la lista del camporee          |
| `day_number`, `starts_at`, `ends_at`, `venue_id`          | campos de agenda                                          | ocultables por `events/preview`         |
| `display_category`, `status`, `capacity`, `sections`      | campos de agenda                                          |                                         |
| `scoring_enabled`                                        | `BOOL DEFAULT false`                                      | habilita scoring oficial por rúbricas   |
| `active`                                                 | `BOOL DEFAULT true`                                       |                                         |
| `created_at`, `modified_at`, `created_by`, `modified_by` |                                                           |                                         |

Constraints:

```
CHECK (
  (local_camporee_id IS NOT NULL AND union_camporee_id IS NULL)
  OR
  (local_camporee_id IS NULL AND union_camporee_id IS NOT NULL)
)
+ los mismos CHECK de max_points / participants_mode que template
@@index([local_camporee_id])
@@index([union_camporee_id])
@@index([event_template_id])
```

### Tabla `camporee_event_schedule_blocks`

Bloques opcionales para partir un evento en varios horarios/grupos.

| Columna | Tipo | Notas |
| --- | --- | --- |
| `camporee_event_schedule_block_id` | `UUID PK` | |
| `camporee_event_id` | `INT FK camporee_events ON DELETE CASCADE` | |
| `title`, `description`, `notes` | texto nullable | |
| `day_number`, `starts_at`, `ends_at` | `INT`, `VARCHAR(5)` | horarios `HH:MM`; `ends_at` debe ser posterior si ambos existen |
| `venue_id` | `INT NULL FK camporee_venues ON DELETE SET NULL` | |
| `display_order`, `capacity`, `active` | orden/cupo/soft-delete | |

### Tabla `camporee_event_schedule_block_assignments`

Asignaciones opcionales de bloques a secciones inscritas. Si un bloque no tiene asignaciones, aplica como bloque general.

| Columna | Tipo | Notas |
| --- | --- | --- |
| `camporee_event_schedule_block_assignment_id` | `UUID PK` | |
| `schedule_block_id` | `UUID FK camporee_event_schedule_blocks ON DELETE CASCADE` | |
| `camporee_club_id` | `INT NULL FK camporee_clubs ON DELETE SET NULL` | sección inscrita al camporee |
| `club_section_id` | `INT FK club_sections` | obligatorio para validar sección |
| `active` | `BOOL DEFAULT true` | soft-delete |

### Tabla `camporee_staff_members`

Roster operativo previo del camporee. Cada fila apunta a un usuario y a exactamente un camporee local o de unión.

| Columna | Tipo | Notas |
| --- | --- | --- |
| `camporee_staff_member_id` | `UUID PK` | |
| `local_camporee_id` | `INT NULL FK local_camporees` | exclusivo con `union_camporee_id` |
| `union_camporee_id` | `INT NULL FK union_camporees` | exclusivo con `local_camporee_id` |
| `user_id` | `UUID FK users` | persona asignable |
| `category` | `VARCHAR(30)` | `judge`, `administrative`, `kitchen`, `support`, `spiritual`, `leadership`, `other` |
| `role_label`, `notes` | texto nullable | etiqueta humana y notas operativas |
| `status`, `active` | texto/bool | desactivación auditada |

### Tabla `camporee_event_staff_assignments`

Asignaciones de personas del roster a una actividad/evento. No obliga a incluir todos los tipos de personal.

| Columna | Tipo | Notas |
| --- | --- | --- |
| `camporee_event_staff_assignment_id` | `UUID PK` | |
| `camporee_event_id` | `INT FK camporee_events ON DELETE CASCADE` | |
| `camporee_staff_member_id` | `UUID FK camporee_staff_members ON DELETE CASCADE` | debe pertenecer al mismo camporee |
| `assignment_role` | `VARCHAR(30)` | `responsible`, `assistant`, `evaluator`, `support` |
| `title_override`, `notes` | texto nullable | etiqueta/nota por actividad |
| `display_order`, `active` | orden/soft-delete | |

Reglas:

- Para publicar un evento debe existir al menos una asignación activa con `assignment_role='responsible'` y staff activo.
- `POST` de evento con `status=publicado` se rechaza (`CAMPOREE_EVENT_RESPONSIBLE_REQUIRED`): el evento aún no existe y no puede tener staff. El alta queda en `programado`. `leader_user_id` / `leader_name_override` son etiqueta de agenda, no sustituyen el roster.
- Pueden existir varios asistentes/evaluadores/apoyos.
- Desactivar un miembro del roster no debe dejarlo satisfaciendo el responsable de un evento.

### Tabla `camporee_event_honors`

Especialidades de preparación ligadas a una **instancia** de evento. Consultivo: no inscribe, no bloquea puntaje ni inscripción.

| Columna | Tipo | Notas |
| --- | --- | --- |
| `camporee_event_honor_id` | `INT PK` | identity |
| `camporee_event_id` | `INT FK camporee_events ON DELETE CASCADE` | |
| `honor_id` | `INT FK honors ON DELETE RESTRICT` | catálogo |
| `display_order` | `INT DEFAULT 0` | orden de `honor_ids` |
| `created_at` | `TIMESTAMPTZ` | |

`@@unique([camporee_event_id, honor_id])`. Máx. 20 por evento. No vive en templates; clonar desde template no copia honores.

### Scoring por rúbricas

Los templates pueden traer rúbricas reutilizables (`camporee_event_template_rubrics`) cuando `camporee_event_templates.scoring_enabled=true`. Al crear un evento desde template, el backend copia esas rúbricas hacia `camporee_event_rubrics` y conserva `camporee_events.scoring_enabled=true`.

Los eventos puntuables (`camporee_events.scoring_enabled=true`) usan rúbricas obligatorias. La suma de `camporee_event_rubrics.max_points` debe coincidir con `camporee_events.max_points`; el puntaje oficial se calcula desde ítems de rúbrica y queda activo en `camporee_event_section_results`.

Tablas agregadas:

- `camporee_event_template_rubrics` — criterios puntuables reutilizables del template.
- `camporee_event_rubrics` — criterios puntuables del evento.
- `camporee_judges` — roster de jueces por camporee local o de unión.
- `camporee_event_judge_assignments` — asignación por evento/sección con rol `primary` o `assistant`; máximo un `primary` activo por evento/sección.
- `camporee_event_score_submissions` y `camporee_event_score_submission_items` — carga auditable de puntajes.
- `camporee_event_section_results` — resultado oficial activo por evento/sección.

Estado y bloqueo del resultado:

- `score_status='scored'` representa una calificación normal; `score_status='no_show'` representa "club no se presentó" y se duplica en `is_no_show=true` para filtros simples.
- `camporee_event_score_submissions.override_of_submission_id` enlaza una corrección manual con la submission oficial anterior.
- El juez `primary` activo puede crear el primer resultado oficial, pero no puede modificarlo ni reenviarlo si ya existe un resultado activo para el evento/sección.
- Gestores LF/Unión dentro de scope o admins globales permitidos pueden reemplazar el resultado activo; el backend deriva `manual_lf`/`admin_override`, exige motivo y deja la corrección auditada. El permiso `camporee_events:update` aislado no autoriza scoring.
- El backend aplica piso de puntos con `camporee_events.min_points`: bajo el mínimo se ajusta al mínimo cuando es `> 0`; nunca se permite superar el máximo de rúbricas/evento.
- Para `no_show`, el backend permite `items: []`, asigna `min_points` si está configurado y conserva evidencia de ausencia con `score_status`/`is_no_show`.
- Con clave idempotente, el submit oficial toma primero el overload bigint sobre `hashtextextended(prefijo + actor + clave, 0)` y luego `pg_advisory_xact_lock(eventId::integer, clubSectionId::integer)`, antes del lookup y del resultado activo. Los casts explícitos compensan el binding `INT8` de números JavaScript realizado por Prisma y fuerzan el overload PostgreSQL `(integer, integer)`. Los keyspaces son distintos; persiste riesgo teórico de colisión hash que sólo sobre-serializa.
- El header opcional `Idempotency-Key` se asocia a `submitted_by` y a un hash canónico de target, fuente, estado, notas, `expected_active_result_id` e ítems ordenados. El mismo hash devuelve el receipt persistido; otro hash devuelve `409 IDEMPOTENCY_KEY_REUSED`.
- Overrides manuales existentes requieren `expected_active_result_id` y `notes.trim()` no vacío; una diferencia devuelve `409 CAMPOREE_SCORING_RESULT_STALE` y un motivo ausente `400 CAMPOREE_SCORING_OVERRIDE_REASON_REQUIRED`. El primer score manual sin activo puede omitir ambos.
- Si una carrera residual produce P2002, el backend relee la submission por actor+clave tras rollback: mismo hash y receipt completo retorna replay; hash distinto retorna `409 IDEMPOTENCY_KEY_REUSED`; receipt sin resultado retorna error interno canónico.
- El receipt conserva `active=true` como snapshot del momento de emisión aun si un override posterior inactiva la fila de resultado; no comunica el estado actual.

Autorización:

- Lectura de rúbricas/scoring targets: `camporee_events:read` o juez activo asignado. Esos GET y el `POST .../scores` usan `@SkipPermissions()`; el servicio autoriza al juez asignado o al gestor con permiso+scope.
- Gestión de rúbricas, roster, personal de agenda y asignaciones: `camporee_events:update` con scope del camporee.
- La edición/desactivación de un juez resuelve el camporee padre desde `judgeId` y vuelve a validar `camporee_events:update` + scope `current-write` en el servicio.
- Envío de puntaje: juez principal activo desde app móvil, o carga manual por `assistant-lf`/`director-lf` con scope institucional. La app consume `GET /camporee-judges/me/assignments`, filtra asignaciones `primary`, carga rúbricas del evento y envía exactamente un ítem por rúbrica.
- Mutaciones de rúbricas, asignación de jueces y envío de puntaje requieren inscripción de clubes cerrada; lecturas permanecen disponibles.

## Endpoints (backend)

Prefijo `/api/v1`.

### Catálogo de tipos (admin)

| Método   | Path                              | Permiso                                           | Descripción  |
| -------- | --------------------------------- | ------------------------------------------------- | ------------ |
| `GET`    | `/admin/camporee-event-types`     | `camporee_event_types:read` o `catalogs:read`     | Listar tipos |
| `POST`   | `/admin/camporee-event-types`     | `camporee_event_types:create` o `catalogs:create` | Crear tipo   |
| `PATCH`  | `/admin/camporee-event-types/:id` | `camporee_event_types:update` o `catalogs:update` | Editar tipo  |
| `DELETE` | `/admin/camporee-event-types/:id` | `camporee_event_types:delete` o `catalogs:delete` | Soft delete  |

### Templates (scope union o local_field)

| Método   | Path                                                                           | Permiso                  | Descripción                                          |
| -------- | ------------------------------------------------------------------------------ | ------------------------ | ---------------------------------------------------- |
| `GET`    | `/camporee-event-templates?scope&union_id&local_field_id&event_type_id&active` | `camporee_events:read`   | Listar templates visibles para el rol                |
| `GET`    | `/camporee-event-templates/:id`                                                | `camporee_events:read`   | Detalle                                              |
| `POST`   | `/camporee-event-templates`                                                    | `camporee_events:create` | Crear template (valida scope + permisos sobre owner) |
| `PATCH`  | `/camporee-event-templates/:id`                                                | `camporee_events:update` | Editar                                               |
| `DELETE` | `/camporee-event-templates/:id`                                                | `camporee_events:delete` | Soft delete                                          |

Visibilidad de templates:

- Admin de unión: ve templates de su unión + templates de campos locales bajo su unión.
- Admin de campo local: ve templates de su campo local + templates de su unión padre.
- Super-admin: ve todo.

### Instancias por camporee

| Método   | Path                                                    | Permiso                                     | Descripción                            |
| -------- | ------------------------------------------------------- | ------------------------------------------- | -------------------------------------- |
| `GET`    | `/local-camporees/:id/events`                           | director/subdirector + camporee_events:read | Listar eventos del camporee local      |
| `GET`    | `/local-camporees/:id/events/preview`                   | camporee_events:read                        | Preview app-safe; oculta agenda antes de `agenda_visible_from` |
| `GET`    | `/union-camporees/:id/events`                           | director-unión + camporee_events:read       | Listar eventos del camporee de unión   |
| `GET`    | `/union-camporees/:id/events/preview`                   | camporee_events:read                        | Preview app-safe para camporee de unión |
| `POST`   | `/local-camporees/:id/events`                           | camporee_events:create                      | Crear evento (custom o desde template) |
| `POST`   | `/union-camporees/:id/events`                           | camporee_events:create                      | Idem unión                             |
| `POST`   | `/local-camporees/:id/events/from-template/:templateId` | camporee_events:create                      | Clonar template a instancia            |
| `POST`   | `/union-camporees/:id/events/from-template/:templateId` | camporee_events:create                      | Idem unión                             |
| `PATCH`  | `/camporee-events/:id`                                  | camporee_events:update                      | Editar instancia (overrides)           |
| `GET`    | `/camporee-events/:id/staff-assignments`                | camporee_events:read                        | Listar personal asignado a la actividad |
| `PUT`    | `/camporee-events/:id/staff-assignments`                | camporee_events:update                      | Reemplazar personal asignado a la actividad |
| `PUT`    | `/camporee-events/:id/schedule-blocks`                  | camporee_events:update                      | Reemplazar bloques y asignaciones de agenda |
| `DELETE` | `/camporee-events/:id`                                  | camporee_events:delete                      | Soft delete                            |
| `PATCH`  | `/camporee-events/:id/reorder`                          | camporee_events:update                      | Cambiar `display_order`                |

### Roster operativo del camporee

| Método   | Path                                      | Permiso                  | Descripción |
| -------- | ----------------------------------------- | ------------------------ | ----------- |
| `GET`    | `/local-camporees/:id/staff`              | camporee_events:read     | Listar personal del camporee local |
| `GET`    | `/local-camporees/:id/staff-candidates`   | camporee_events:update   | Listar usuarios candidatos para roster local |
| `POST`   | `/local-camporees/:id/staff`              | camporee_events:update   | Agregar persona al roster local |
| `GET`    | `/union-camporees/:id/staff`              | camporee_events:read     | Listar personal del camporee de unión |
| `GET`    | `/union-camporees/:id/staff-candidates`   | camporee_events:update   | Listar usuarios candidatos para roster de unión |
| `POST`   | `/union-camporees/:id/staff`              | camporee_events:update   | Agregar persona al roster de unión |
| `PATCH`  | `/camporee-staff/:staffMemberId`          | camporee_events:update   | Editar categoría/etiqueta/notas |
| `DELETE` | `/camporee-staff/:staffMemberId`          | camporee_events:update   | Desactivar persona del roster |

### Roster de jueces de scoring

| Método   | Path                            | Permiso                                     | Descripción                                                       |
| -------- | ------------------------------- | ------------------------------------------- | ----------------------------------------------------------------- |
| `GET`    | `/local-camporees/:id/judges`   | camporee_events:read + scope                | Listar jueces activos con email, notas e imagen opcional          |
| `GET`    | `/union-camporees/:id/judges`   | camporee_events:read + scope                | Listar jueces activos con email, notas e imagen opcional          |
| `PATCH`  | `/camporee-judges/:judgeId`     | camporee_events:update + scope del camporee | Editar notas/estado/actividad                                     |
| `DELETE` | `/camporee-judges/:judgeId`     | camporee_events:update + scope del camporee | Soft-deactivate del juez y de todas sus asignaciones activas      |

La desactivación se ejecuta en una transacción. Los scores históricos permanecen auditables y no bloquean la operación; las filas de `camporee_staff_members` no se desactivan automáticamente porque representan un roster operativo independiente.

## Permisos RBAC (a sembrar)

Nuevos permisos:

- `camporee_event_types:read|create|update|delete` (admin/super-admin)
- `camporee_events:read|create|update|delete` (director/subdirector club, `director-lf`/`assistant-lf`, `director-union`/`assistant-union`, admin)

Mapeos sugeridos:

- Director club: read + create + update + delete (sobre camporees de su scope)
- Subdirector club: read + create + update
- Admin unión: read + create + update + delete sobre templates de su unión
- Super-admin: todo

## UI Admin (sacdia-admin)

### 1. Catálogo de tipos de evento

Ruta: `/dashboard/catalogs/camporee-event-types`

- List page con `PhaseECatalogCrudPage` patrón (Dialog con tabs i18n) — ≤4 campos planos: name, description, display_order, active.
- Reutiliza factory `makeActions` con `hasDescription=true`, traducciones `['name', 'description']`.

### 2. Biblioteca de templates

Ruta: `/dashboard/camporees/event-templates`

- List page con filtros: scope (union/local), event_type, búsqueda por título.
- Dedicated form pages (`new/page.tsx`, `[id]/edit/page.tsx`) — patrón club-ideal-form-page por la cantidad de campos (>4) + jsonb editors + select de event_type.
- Editores específicos:
  - `PenaltiesEditor`: lista dinámica de reglas (add/remove row, campos description/points/time)
  - `ParticipantsField`: toggle count vs by_class. Si by_class, multiselect de clases + input count por clase.

### 3. Eventos asignados a un camporee

Tab "Eventos" en `/dashboard/camporees/[id]` para camporee local y en
`/dashboard/camporees/union/[id]` para camporee de unión.

- Lista de instancias con orden drag-handle (display_order).
- Botones: "Agregar desde template" (picker), "Crear personalizado" (form modal/page).
- Acciones por fila: editar (form prellenado), eliminar, reordenar.
- El formulario de evento permite seleccionar tipo de evento, un líder de agenda (usuario o nombre externo), bloques de horario opcionales con asignaciones a secciones inscritas y especialidades de preparación del catálogo. El alta siempre queda `programado`; publicar pide un responsable del roster de personal, distinto del líder de agenda.
- Las rutas dedicadas de creación/edición existen para ambos scopes:
  `/dashboard/camporees/[id]/events/new`,
  `/dashboard/camporees/[id]/events/[eventId]/edit`,
  `/dashboard/camporees/union/[id]/events/new` y
  `/dashboard/camporees/union/[id]/events/[eventId]/edit`.

### 4. Personal del camporee

Tab "Personal" en el detalle del camporee, antes de "Eventos".

- Permite cargar personas del camporee con categoría descriptiva.
- Los candidatos salen de usuarios del scope del camporee.
- El roster se reutiliza para asignar responsables/apoyos/evaluadores en eventos.
- No reemplaza el scoring: para puntajes por sección se siguen usando jueces y asignaciones de scoring.

## UI App (sacdia-app)

- Sección "Eventos" dentro del detalle de camporee.
- Read-only en la lista: mostrar sólo icono, nombre del evento y puntaje total.
- Read-only en detalle antes de `agenda_visible_from`: ver descripción, tipo, puntos/requisitos y especialidades de preparación (PDF), sin día/hora/sede/bloques.
- Read-only en detalle después de `agenda_visible_from`: ver tipo, día/hora, puntos máximos, sede opcional, descripción, especialidades de preparación, personal asignado y bloques segmentados por horario/grupo cuando existan.
- La sección de miembros inscritos aparece antes que la sección de eventos en el detalle móvil.
- La capa de datos puede consumir preview local o unión (`local-camporees` /
  `union-camporees`) según `camporeeType`.
- No CRUD desde móvil en esta iteración.

## Cache

- Catálogo `camporee_event_types`: cache-aside Redis TTL 1h, invalidación en mutación admin.
- Templates: NO cache (pocas filas por scope, lecturas frecuentes pero pequeñas).
- Instancias: NO cache.

## Migración

Una sola migración SQL `prisma/migrations/<timestamp>_camporee_events/migration.sql` con:

1. `CREATE TABLE camporee_event_types` + translations + named unique constraint.
2. `CREATE TABLE camporee_event_templates` + CHECK constraints + índices.
3. `CREATE TABLE camporee_events` + CHECK constraints + índices.
4. Seed inicial de event_types (espiritual, recreativo, cultural, deportivo, técnico).
5. Inserción de permisos RBAC nuevos en tabla `permissions`.

Sin transformación de datos existentes — feature aditiva.

## Plan de implementación (fases)

| Fase | Alcance                                                                 | Owner   | Estado               |
| ---- | ----------------------------------------------------------------------- | ------- | -------------------- |
| 0    | Documentación (este archivo)                                            | Backend | ACTUALIZADO          |
| 1    | Migración SQL + Prisma model                                            | Backend | IMPLEMENTADO         |
| 2    | DTOs + service + controller + tests para `camporee_event_types`         | Backend | IMPLEMENTADO PARCIAL |
| 3    | DTOs + service + controller + tests para `camporee_event_templates`     | Backend | IMPLEMENTADO         |
| 4    | DTOs + service + controller + tests para `camporee_events` (instancias) | Backend | IMPLEMENTADO         |
| 5    | Seed permisos + asignación a roles existentes                           | Backend | IMPLEMENTADO         |
| 6    | Admin: catálogo tipos                                                   | Admin   | PENDIENTE            |
| 7    | Admin: biblioteca templates (list + form pages)                         | Admin   | PENDIENTE            |
| 8    | Admin: tab eventos en detalle de camporee                               | Admin   | IMPLEMENTADO         |
| 9    | App: pantalla read-only de eventos en camporee                          | App     | IMPLEMENTADO         |

## Open questions

1. ¿Director de club puede crear templates o solo admins de unión/campo? **Tentativa**: admin/coordinator-level only para templates, director crea instancias custom dentro de su camporee.
2. ¿Hay límite de puntos totales por camporee (suma de max_points de eventos)? **Tentativa**: no, validar a futuro si surge.
3. ¿Penalizaciones se aplican automáticamente al puntaje del club o son informativas? **Tentativa**: informativas en esta iteración; un módulo "Evaluación de camporee" futuro las consumirá.
4. ¿Idiomas de los templates? **Tentativa**: solo `name`/`description` del catálogo de tipos. Templates y instancias en español únicamente (es contenido operativo, no UI).

## Referencias

- [Camporees existentes](./camporees.md)
- [Catálogos i18n](./catalogos.md)
- [RBAC](./rbac.md)
- Schema base: `sacdia-backend/prisma/schema.prisma` (modelos `local_camporees`, `union_camporees`, `classes`)
