# Actividades

**Estado**: IMPLEMENTADO

## Descripcion de dominio

Las actividades son el eje operativo del dia a dia de un club de Conquistadores, Aventureros o Guias Mayores. Representan cualquier evento planificado por la directiva del club: reuniones regulares, campamentos, excursiones, proyectos comunitarios, ensayos de orden cerrado, clases especiales y eventos sociales. Cada actividad esta vinculada a un club especifico y puede tener un tipo categorizado (catalogo `activity_types`).

El registro de asistencia a actividades es fundamental para el seguimiento formativo de los miembros. La asistencia alimenta la trayectoria del miembro dentro del club y puede ser requisito para completar secciones de clases progresivas o para validar la participacion en investiduras. Las actividades tambien soportan geolocalizacion, permitiendo documentar el lugar exacto donde se realiza cada evento.

El modelo contempla `activity_instances` como instancias recurrentes de una actividad (por ejemplo, reuniones semanales que generan una instancia por cada fecha), aunque esta funcionalidad de recurrencia no esta completamente expuesta en la API actual.

## Que existe (verificado contra codigo)

### Backend (ActivitiesModule)
- **Controller**: `src/activities/activities.controller.ts`
- **Service**: `src/activities/activities.service.ts`
- **Guards**: JwtAuthGuard, PermissionsGuard, ClubRolesGuard
- **7 endpoints**:
  - `GET /api/v1/clubs/:clubId/activities` — Listar actividades del club
  - `POST /api/v1/clubs/:clubId/activities` — Crear actividad (roles: director, subdirector, secretary, counselor)
  - `GET /api/v1/activities/:activityId` — Obtener actividad por ID
  - `PATCH /api/v1/activities/:activityId` — Actualizar actividad
  - `DELETE /api/v1/activities/:activityId` — Desactivar actividad
  - `POST /api/v1/activities/:activityId/attendance` — Registrar asistencia
  - `GET /api/v1/activities/:activityId/attendance` — Obtener asistencia

### Admin
- **UI completa**: Pagina de lista con selector de club, pagina de detalle con panel de asistencia, dialog de creacion/edicion, confirmacion de eliminacion
- Cliente API en `src/lib/api/activities.ts`
- Consume los 7 endpoints del backend

### App Movil
- **4 screens**: ActivitiesListView, ActivityDetailView, CreateActivityView, LocationPickerView
- Consume los 7 endpoints del backend
- Incluye selector de ubicacion en mapa (LocationPickerView)
- `ActivitiesListView` resuelve `clubId` desde `clubContextProvider` (bug de hardcodeo a 1 corregido)
- Edicion y eliminacion de actividades disponibles en la vista de detalle (`EditActivityView` + confirmacion de borrado)

### Base de datos
- `activities` — Actividades del club
- `activity_types` — Catalogo de tipos de actividad
- `activity_instances` — Instancias de actividades (recurrencia)

## Requisitos funcionales

1. Un miembro con rol director, subdirector, secretario o consejero debe poder crear actividades para su club
2. Las actividades deben tener nombre, descripcion, fecha/hora, tipo y ubicacion opcional
3. El sistema debe permitir registrar asistencia de miembros a cada actividad
4. El listado de actividades debe filtrarse por club y mostrarse en orden cronologico
5. Las actividades deben poder desactivarse (soft delete) sin perder datos historicos
6. El catalogo de tipos de actividad (`GET /catalogs/activity-types`) debe estar disponible para clasificar actividades
7. La app debe permitir seleccionar ubicacion geografica en un mapa al crear una actividad
8. El panel admin debe ofrecer gestion completa de actividades por club

## Decisiones de diseno

- **Soft delete**: Las actividades se desactivan, no se eliminan fisicamente
- **Autorizacion por rol de club**: Solo roles operativos (director, subdirector, secretary, counselor) pueden crear actividades; la lectura es abierta a miembros con JWT
- **Geolocalizacion**: La app implementa seleccion de ubicacion en mapa, pero el backend almacena coordenadas como campos del modelo
- **Tipos de actividad**: Separados en tabla catalogo `activity_types` para permitir administracion independiente
- **Instancias**: El modelo `activity_instances` sugiere un diseno para actividades recurrentes, aunque la API actual no lo expone explicitamente

## Gaps y pendientes

- **`GET /catalogs/activity-types`**: Existe en backend pero sin documentacion API en ENDPOINTS-LIVE-REFERENCE.md
- **Recurrencia**: El modelo `activity_instances` existe en DB pero la API no expone endpoints para gestionar instancias recurrentes
- **Reportes de asistencia**: No hay endpoint para obtener estadisticas o reportes de asistencia agregados

## Estado de implementacion

- **Prioridad**: Completo — backend, admin y app implementados sin gaps funcionales pendientes
