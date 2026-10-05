# Actividades recurrentes (creación masiva independiente)

**Fecha**: 2026-09-02
**Estado**: APROBADO
**Alcance**: `sacdia-backend`, `sacdia-admin`, `sacdia-app`
**Dominio**: [actividades.md](../../features/actividades.md) + [actividades-conjuntas.md](../../features/actividades-conjuntas.md)

## 1. Objetivo

Un director (u otro rol que ya puede crear actividades) programa una reunión que se repite — por ejemplo todos los domingos a las 10:00 hasta el fin del año eclesiástico, o cada 3 días — **sin crear 52 formularios**.

El sistema **materializa de inmediato** N actividades reales, independientes. Editar la sesión 33 (hora, lugar, secciones) no cambia a las demás ni la receta de la serie.

Crear **una** actividad para un día concreto sigue siendo el camino por defecto. La serie es un interruptor opcional, apagado al abrir el formulario.

## 2. Decisiones

1. Cabecera `activity_series` (la receta) + N filas `activities` con `activity_series_id`. No cron. No reutilizar `activity_instances` para recurrencia (esa tabla sigue siendo “una actividad × sección”).
2. Copias independientes: `PATCH`/`DELETE` actuales no tocan hermanas ni cabecera.
3. Serie conjunta: cada copia nace con las mismas secciones e instancias propias.
4. Cierre por fecha `until` (inclusive). Si se omite, se usa el fin del año eclesiástico activo.
5. Solo año eclesiástico activo. Primera sesión ≥ hoy (calendario). Nada de años vecinos ni fechas pasadas.
6. Regla v1: `interval` (cada N días) **o** `weekly` (un día de la semana). `weekdays` es un array de longitud 1 ahora; el schema permite varios para una fase posterior.
7. Superficies: admin y app, mismos permisos `activities:create|read|update|delete` y roles de club actuales. Sin permiso nuevo.
8. Tras crear: ver serie, cancelar futuras (soft delete, fecha ≥ hoy), agregar más (nuevo `until`, solo fechas que aún no existen como fila). Las canceladas no se resucitan. Las nuevas copias salen de la cabecera, no de una sesión editada.
9. Interruptor “Repetir esta actividad” en el formulario de crear existente. Apagado → `POST .../activities` de siempre. Encendido → preview + `POST .../activity-series`.
10. Una notificación de serie, no N notificaciones. Invalidación realtime una vez por sección.
11. Sin `PATCH` de la receta en esta fase. Sin excepciones/feriados. Sin varios días de la semana en una serie.

## 3. Datos

### 3.1 `activity_series`

| Columna | Tipo | Notas |
| --- | --- | --- |
| `activity_series_id` | `INT PK` identity | |
| `club_id` | `INT FK clubs` | club dueño |
| `ecclesiastical_year_id` | `INT FK ecclesiastical_years` | año activo al crear; no se cambia |
| `created_by` | `UUID FK users` | |
| `name` | `VARCHAR(80)` | plantilla |
| `description` | `TEXT?` | plantilla |
| `club_type_id` | `INT` | igual que actividades |
| `club_section_id` | `INT? FK club_sections` | sección dueña |
| `is_joint` | `BOOLEAN DEFAULT false` | |
| `lat` / `long` | `FLOAT` | plantilla |
| `activity_time` | `VARCHAR(10)` | `HH:mm` |
| `duration_days` | `INT NOT NULL DEFAULT 0` | `activity_end_date - activity_date` de la primera; 0 = mismo día |
| `activity_place` | `TEXT` | plantilla |
| `image` | `TEXT` | URL copiada a cada sesión |
| `platform` | `INT` | 0/1/2 |
| `activity_type_id` | `INT FK activity_types` | |
| `link_meet` | `TEXT?` | |
| `additional_data` | `TEXT?` | |
| `classes` | `JSONB?` | |
| `first_date` | `DATE` | primera ocurrencia real generada (ancla del patrón; no se pierde si se cancela esa sesión) |
| `kind` | `VARCHAR(16)` | `interval` \| `weekly` |
| `interval_days` | `INT?` | requerido si `kind=interval`; 1–365 |
| `weekdays` | `SMALLINT[]` | ISO 8601: 1=lunes … 7=domingo. v1: exactamente 1 valor |
| `until_date` | `DATE` | inclusive; ≤ fin del año eclesiástico de la fila |
| `active` | `BOOLEAN DEFAULT true` | |
| `created_at` / `modified_at` | `TIMESTAMPTZ` | |

Tabla de unión `activity_series_sections` (`activity_series_id`, `club_section_id`) para recordar las secciones de una serie conjunta al extender. Unique `(activity_series_id, club_section_id)`.

Índices: `(club_id)`, `(ecclesiastical_year_id)`, `(created_by)`.

Check: `kind=interval` ⇒ `interval_days IS NOT NULL`; `kind=weekly` ⇒ `weekdays` longitud ≥ 1.

### 3.2 `activities`

- `activity_series_id INT? FK activity_series ON DELETE SET NULL`
- Índice `(activity_series_id)`
- Índice parcial unique `(activity_series_id, activity_date) WHERE activity_series_id IS NOT NULL` — una fecha por serie. Actividades sueltas (`NULL`) no entran. Filas inactivas también ocupan la fecha (extender no las resucita).

Cada copia se crea con `active: true` y las mismas `activity_instances` que el `create` actual (una sección o varias si `is_joint`).

## 4. Expansión de fechas

Zona de calendario: `America/Mexico_City` (default institucional ya usado en camporees). `hoy` = fecha local en esa zona. `activity_date` sigue siendo `DATE` (sin hora).

Año eclesiástico: `GET /api/v1/catalogs/ecclesiastical-years/current`. `start_date` y `end_date` inclusive.

Algoritmo:

1. `start` = `activity_date` del formulario. Debe ser ≥ `hoy` y estar dentro de `[year.start, year.end]`.
2. `until` = body o `year.end`. Debe ser ≥ primera ocurrencia y ≤ `year.end`.
3. Si `kind=interval`: fechas `start`, `start+N`, … mientras `<= until`.
4. Si `kind=weekly`: primera fecha = el primer día cuyo weekday ISO esté en `weekdays` y sea ≥ `start`; luego +7 días (v1 un solo weekday; el bucle ya admite varios sin cambiar el contrato).
5. 0 fechas → `ACTIVITY_SERIES_EMPTY` (no se inserta cabecera).
6. Más de 366 → `ACTIVITY_SERIES_TOO_MANY`.

Cada actividad: `activity_date = D`, `activity_end_date = D + duration_days`, resto copiado de la plantilla. Mismo `name` (sin sufijo “#33”).

## 5. API

Prefijo `/api/v1`. `POST .../clubs/:clubId/activities` **no cambia**.

| Método | Ruta | Permiso | Rol club (igual que crear/borrar actividad) |
| --- | --- | --- | --- |
| `POST` | `/clubs/:clubId/activity-series/preview` | `activities:create` | director, deputy-director, secretary, secretary-treasurer, counselor |
| `POST` | `/clubs/:clubId/activity-series` | `activities:create` | idem |
| `GET` | `/activity-series/:seriesId` | `activities:read` | visibilidad de actividades del club |
| `POST` | `/activity-series/:seriesId/cancel-future` | `activities:delete` | idem delete |
| `POST` | `/activity-series/:seriesId/extend` | `activities:create` | idem create |

Autorización conjunta: las mismas reglas que una actividad conjunta (todas las secciones participantes).

### 5.1 Body de preview/create

Campos de `CreateActivityDto` (nombre, lugar, hora, tipo, `activity_date`, `activity_end_date`, sección o `club_section_ids` + `is_joint`, etc.) más:

```json
{
  "recurrence": {
    "kind": "weekly",
    "interval_days": null,
    "weekdays": [7],
    "until": "2026-12-12"
  }
}
```

- `kind=interval`: `interval_days` 1–365; no enviar `weekdays` o `[]`.
- `kind=weekly`: `weekdays` v1 longitud exactamente 1, valores 1–7 únicos; no enviar `interval_days`.
- `until` opcional.
- `activity_date` es obligatorio en serie (en el alta suelta sigue siendo opcional como hoy).

**Preview** no escribe. Respuesta:

```json
{
  "count": 41,
  "dates": ["2026-03-08", "2026-03-15"],
  "until": "2026-12-12",
  "ecclesiastical_year": {
    "year_id": 1,
    "start_date": "2026-01-01",
    "end_date": "2026-12-12"
  }
}
```

**Create** en una transacción: cabecera + secciones de serie + N actividades + instancias. Respuesta: serie + `created_count` + `activity_ids`. No se devuelven N payloads completos. El cliente refresca el listado.

### 5.2 GET serie

Receta, `until_date`, conteos (`total`, `active`, `upcoming`, `past`), sin embeber todas las ocurrencias.

Listado existente `GET /clubs/:clubId/activities`: cada ítem incluye `activity_series_id` (nullable). Query opcional `seriesId` para “ver serie”.

### 5.3 Cancelar futuras

Desactiva (`active=false`) actividades de la serie con `activity_date >= hoy` y `active=true`. No toca pasadas ni asistencia. Cabecera sigue `active=true`.

`200 { "canceled_count": N }` — `N=0` no es error.

### 5.4 Extender

Body `{ "until": "YYYY-MM-DD" }`. Nuevo `until` ≥ `until_date` actual y ≤ fin del año eclesiástico de la serie. Recalcula el patrón desde `first_date`.

Inserta solo fechas del patrón ≤ nuevo `until` que **no** tengan ya una fila (activa o no). Actualiza `until_date`. Plantilla = columnas de la cabecera + `activity_series_sections`.

`200 { "created_count": N, "activity_ids": [] }` — `N=0` no es error.

### 5.5 Errores

| Código | HTTP | Cuándo |
| --- | --- | --- |
| `ACTIVITY_SERIES_DATE_IN_PAST` | 400 | primera sesión &lt; hoy |
| `ACTIVITY_SERIES_OUTSIDE_ECCLESIASTICAL_YEAR` | 400 | start o until fuera del año activo |
| `ACTIVITY_SERIES_UNTIL_BEFORE_START` | 400 | until &lt; primera ocurrencia |
| `ACTIVITY_SERIES_INVALID_RULE` | 400 | kind/N/weekdays inválidos o mezcla interval+weekly |
| `ACTIVITY_SERIES_EMPTY` | 400 | 0 fechas |
| `ACTIVITY_SERIES_TOO_MANY` | 400 | &gt; 366 |
| `ACTIVITY_SERIES_NOT_FOUND` | 404 | serie inexistente o de otro club |
| `ACTIVITY_SERIES_EXTEND_UNTIL_REGRESSION` | 400 | nuevo until &lt; until actual |
| 403 | 403 | mismos guards que actividades |

Códigos nuevos en `ErrorCode` + `src/i18n/*/errors.json`.

Editar una sesión y chocar fecha con otra de la misma serie → unique violation → conflicto de registro existente (no se fusionan).

## 6. Admin (`sacdia-admin`)

Formulario de crear actividad actual:

- Interruptor **Repetir esta actividad**, default off.
- Off: botón guarda 1 actividad (endpoint actual).
- On: frecuencia (N días o día de la semana), “Hasta” (default fin de año eclesiástico, date picker max = `end_date`, min = fecha de inicio / hoy), preview (fechas + conteo), confirmar crea la serie. El botón debe decir cuántas se van a crear.

Detalle de actividad con `activity_series_id`:

- Badge de serie.
- Acciones (con permiso): Ver serie (listado filtrado), Cancelar sesiones futuras (confirmación), Agregar más (nuevo until + preview de fechas nuevas).

Listado: no obliga agrupación. Filtro/enlace por serie basta.

Quien no tiene `activities:create` no ve interruptor ni Guardar, igual que hoy.

## 7. App (`sacdia-app`)

Mismo comportamiento en `CreateActivityView`: interruptor, preview, confirmar.

`ActivityDetailView`: mismas acciones de serie si hay `activity_series_id` y el usuario puede update/delete.

`ActivitiesListView`: puede mostrar badge; el filtro `seriesId` cubre “ver serie”.

## 8. Efectos colaterales

- **Notificaciones**: un aviso de serie (“N reuniones programadas”), no N avisos.
- **Realtime**: una invalidación por sección afectada, no N.
- **Asistencia, QR, recordatorios**: por actividad, sin cambio de contrato.
- **Puntaje de carpetas / actividades registradas**: cada copia cuenta como actividad (son reuniones reales).

## 9. Pruebas

Backend:

- Expansión: domingos hasta `until` inclusive; cada 3 días; `start` miércoles + weekly domingo → primer domingo ≥ start; 0 fechas; 367 fechas.
- Año: ayer; until en año siguiente; until omitido = fin de año activo.
- Create: N filas independientes; PATCH hora en una no cambia hermanas ni cabecera; conjunta replica secciones en cada copia.
- Cancel-future: no toca `activity_date < hoy`; `canceled_count=0` → 200.
- Extend: no resucita inactivas; no pasa del año de la serie; plantilla de cabecera (no de sesión editada).
- Permisos: sin `activities:create` → 403 en preview/create/extend.
- Create suelto: `activity_series_id` null.

Admin/app: interruptor off no llama a `/activity-series`; on muestra preview antes de persistir.

## 10. Fuera de alcance

- Varios weekdays en una serie (el array ya existe; solo relajar validación “longitud 1”).
- Editar la receta y reescribir futuras.
- Jobs de materialización.
- Excepciones (saltar un domingo).
- Permisos nuevos.
- Crear en fechas pasadas del año activo.

## 11. Docs a actualizar en la implementación

- `docs/features/actividades.md` (recurrencia; aclarar que `activity_instances` no es recurrencia).
- `docs/api/ENDPOINTS-LIVE-REFERENCE.md` y `docs/api/FRONTEND-INTEGRATION-GUIDE.md`.
- `docs/database/SCHEMA-REFERENCE.md` + `schema.prisma` canónico si el flujo del repo lo exige.
- `docs/features/README.md` si se registra gap cerrado.

## 12. Ownership de implementación

Contract-first: backend (endpoints, DTO, schema, errores, tests) antes de admin y app. Admin: Cursor sobre contratos ya definidos. App: misma API.
