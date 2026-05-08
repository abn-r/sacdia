# Actividades Conjuntas

**Estado**: IMPLEMENTADO

## Descripcion de dominio

Las actividades conjuntas permiten a los directores de club crear una sola actividad que abarca dos o mas secciones del club (por ejemplo, Conquistadores + Aventureros). Esto elimina la necesidad de crear actividades duplicadas cuando un evento involucra a multiples secciones, y centraliza la gestion de asistencia y visibilidad en un unico registro.

El concepto se implementa sobre la tabla `activity_instances` ya existente: una actividad conjunta genera una instancia por cada seccion participante, mientras que una actividad normal genera solo una instancia para la seccion de origen. Cualquier director de las secciones participantes puede gestionar la actividad (editar, eliminar), no solo el creador original.

## Que existe (verificado contra codigo)

### Backend (ActivitiesModule)

- **Campo `is_joint`**: Booleano en `activities`, default `false`. Indica que la actividad abarca multiples secciones.
- **Creacion conjunta**: `POST /api/v1/clubs/:clubId/activities` acepta `club_section_ids: number[]` e `is_joint: boolean`. Cuando `is_joint=true` y se envian multiples secciones, se crean multiples `activity_instances` (una por seccion).
- **Actualizacion conjunta**: `PATCH /api/v1/activities/:activityId` tambien acepta `club_section_ids` e `is_joint`. Usa patron upsert para reasociar secciones: activa instancias nuevas, desactiva las removidas, y reactiva existentes inactivas. El unique constraint `(activity_id, club_section_id)` impide usar delete+create en la misma transaccion — por eso se usa upsert.
- **Autorizacion conjunta**: El `PermissionsGuard` verifica autorizacion contra TODAS las secciones participantes, no solo la seccion creadora. Cualquier director de una seccion participante puede editar/eliminar la actividad.
- **Listado**: Las actividades conjuntas aparecen en el listado de cada seccion participante gracias a las instancias.

### App Movil

- **Auto-deteccion de seccion**: Para usuarios no-directores (consejeros, secretarios), la app detecta automaticamente su seccion desde el contexto del club, sin mostrar un selector de tipo de club.
- **Toggle conjunta**: Cuando el usuario es director y tiene 2+ secciones, aparece un `SwitchListTile` "Actividad conjunta" en `CreateActivityView`. Al activarlo, se muestra un picker de secciones con `FilterChip`.
- **Edicion conjunta**: `EditActivityView` soporta actividades conjuntas — carga las secciones existentes y permite modificar la seleccion.
- **Badge "Conjunta"**: Las actividades conjuntas muestran un badge visual en la lista y detalle.
- **Entidades nuevas**: `ActivityInstance` (value object con `activityInstanceId`, `activityId`, `clubSectionId`, `active`) y `ClubSectionModel` (modelo de seccion con `clubSectionId`, `clubTypeId`, `clubTypeName`).
- **Sin picker de tipo de club**: El antiguo selector de `club_type_name` fue eliminado; la app resuelve la seccion desde los grants del miembro y el contexto del club.

### Base de datos

- `activities.is_joint` — `BOOLEAN DEFAULT false`, indica actividad conjunta
- `activity_instances` — Ya existia, ahora se usa activamente para multiples secciones
- Constraint `UNIQUE (activity_id, club_section_id)` — previene instancias duplicadas

## Requisitos funcionales

1. Un director con acceso a 2+ secciones debe poder marcar una actividad como conjunta al crearla
2. Al activar el toggle conjunta, debe poder seleccionar que secciones participan (minimo 2)
3. La actividad conjunta debe ser visible en el listado de todas las secciones participantes
4. Cualquier director de una seccion participante puede editar o eliminar la actividad
5. Al editar, se pueden agregar o quitar secciones de la actividad conjunta
6. Usuarios no-directores (consejeros, secretarios) ven auto-deteccion de su seccion sin selector

## Decisiones de diseno

- **Upsert en vez de delete+create**: El unique constraint `(activity_id, club_section_id)` cubre filas activas e inactivas. No se puede eliminar y recrear en la misma transaccion, por lo que se usa upsert (activar/desactivar) para reasociar secciones.
- **Autorizacion distribuida**: No solo el creador puede gestionar la actividad — cualquier director de una seccion participante tiene autorizacion. Esto evita bloqueos operativos si el creador original no esta disponible.
- **Auto-deteccion de seccion**: La app enriquece el `ClubContext` con `club_type_name` desde los grants del miembro. Para no-directores se auto-selecciona la unica seccion disponible; para directores se ofrece el toggle conjunta.
- **SwitchListTile sin `activeColor`**: El override de `activeColor` fue removido porque interferia con el theme global del switch. Se deja que el `switchTheme` de la app maneje el color.

## Endpoints afectados

| Method | Path | Cambios |
|--------|------|---------|
| POST | `/api/v1/clubs/:clubId/activities` | Acepta `club_section_ids: number[]` e `is_joint: boolean` |
| PATCH | `/api/v1/activities/:activityId` | Acepta `club_section_ids: number[]` e `is_joint: boolean` |

## Gaps y pendientes

- **Asistencia conjunta**: No hay un endpoint unificado de asistencia para actividades conjuntas — cada seccion registra asistencia por separado
- **Reportes**: No hay metricas o reportes especificos para actividades conjuntas
