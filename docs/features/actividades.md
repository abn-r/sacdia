# Actividades

**Estado**: IMPLEMENTADO

## Descripcion de dominio

Las actividades son el eje operativo del dia a dia de un club de Conquistadores, Aventureros o Guias Mayores. Representan cualquier evento planificado por la directiva del club: reuniones regulares, campamentos, excursiones, proyectos comunitarios, ensayos de orden cerrado, clases especiales y eventos sociales. Cada actividad esta vinculada a un club especifico y puede tener un tipo categorizado (catalogo `activity_types`).

El registro de asistencia a actividades es fundamental para el seguimiento formativo de los miembros. La asistencia alimenta la trayectoria del miembro dentro del club y puede ser requisito para completar secciones de clases progresivas o para validar la participacion en investiduras. Las actividades tambien soportan geolocalizacion, permitiendo documentar el lugar exacto donde se realiza cada evento.

El modelo contempla `activity_instances` como instancias de una actividad por seccion. La funcionalidad principal actual es soportar **actividades conjuntas** — actividades que abarcan multiples secciones del club (ver [actividades-conjuntas](actividades-conjuntas.md)). Cuando una actividad es conjunta (`is_joint=true`), se crea una instancia por cada seccion participante.

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
- El boton "Agregar" en `ActivitiesListView` solo se muestra a usuarios con permiso `activities:create` o con roles legacy `director`, `deputy_director`, `secretary`, `counselor` — evaluado via `canByPermissionOrLegacyRole`

**Entidad Activity — campos adicionales (post-rediseno):**
- `lat`, `longitude` — coordenadas de la ubicacion
- `activityDate`, `activityEndDate` — fecha/hora de inicio y fin
- `attendees` — lista de participantes con nombre e imagen
- `classes` — secciones/clases asociadas a la actividad
- `additionalData` — datos extra sin esquema fijo
- `creatorName`, `creatorImage` — datos del organizador
- Getters computados: `isPast` (actividad ya ocurrio), `hasVirtualLink` (tiene link de videoconferencia), `hasLocation` (tiene coordenadas validas)

**ActivityDetailView — rediseno completo:**
- Hero edge-to-edge: mapa interactivo (`flutter_map`) para actividades presenciales, imagen para virtuales; se extiende detras del AppBar
- Grid 2×3 de metadata con tarjetas tintadas por color (fecha, hora, lugar, tipo, seccion, modalidad)
- Badge de modalidad (Presencial / Virtual / Hibrido) en la fila del titulo, no sobre el hero
- Seccion de participantes con avatares apilados en paleta calida
- Footer card de organizador con nombre e imagen del creador
- Estado de carga con shimmer skeleton (`activity_detail_skeleton.dart`)
- Boton "Confirmar asistencia" eliminado — la asistencia es gestionada por administradores, no es opt-in del usuario

**Nuevos widgets extraidos:**
- `activity_hero_section.dart` — hero condicional: google_maps_flutter (presencial) o imagen (virtual/hibrido)
- `activity_metadata_grid.dart` — grid 2×3 con acento de color por tarjeta
- `activity_attendees_section.dart` — avatares apilados con paleta calida
- `activity_detail_skeleton.dart` — skeleton shimmer de carga

**CreateActivityView — cambios de formulario:**
- Agregados date pickers para fecha de inicio y fecha de fin
- `SacDropdownField` reemplazado por `BottomSheetPicker` para seleccion de tipo y seccion

### Base de datos
- `activities` — Actividades del club
- `activity_types` — Catalogo de tipos de actividad
- `activity_instances` — Instancias de actividades (recurrencia)

## Requisitos funcionales

1. Un miembro con rol director, subdirector, secretario o consejero debe poder crear actividades para su club; el boton de creacion debe ocultarse para usuarios sin ese permiso/rol
2. Las actividades deben tener nombre, descripcion, fecha/hora, tipo y ubicacion opcional
3. El sistema debe permitir registrar asistencia de miembros a cada actividad
4. El listado de actividades debe filtrarse por club y mostrarse en orden cronologico
5. Las actividades deben poder desactivarse (soft delete) sin perder datos historicos
6. El catalogo de tipos de actividad (`GET /catalogs/activity-types`) debe estar disponible para clasificar actividades
7. La app debe permitir seleccionar ubicacion geografica en un mapa al crear una actividad
8. El panel admin debe ofrecer gestion completa de actividades por club

## Decisiones de diseno

- **Soft delete**: Las actividades se desactivan, no se eliminan fisicamente
- **Autorizacion por rol de club**: Solo roles operativos (director, subdirector, secretary, counselor) pueden crear actividades; la lectura es abierta a miembros con JWT. La app oculta el boton de creacion si el usuario no tiene el permiso `activities:create` ni alguno de esos roles legacy
- **Campo `image` opcional en `CreateActivityDto`**: El campo `image` es opcional (`@IsOptional()`) — solo aplica para actividades virtuales. En el DTO de actualizacion (`UpdateActivityDto`) tambien es opcional
- **Asistencia no es self-service**: El boton "Confirmar asistencia" fue eliminado de la app. La asistencia la registran los administradores via el panel admin (`POST /activities/:id/attendance`), no los propios miembros
- **BottomSheetPicker en formularios**: El formulario de creacion de actividad adopta `BottomSheetPicker` en lugar de `SacDropdownField` para la seleccion de tipo y seccion, alineandose con el patron de pickers del resto de la app
- **Geolocalizacion**: La app implementa seleccion de ubicacion en mapa (LocationPickerView) usando `google_maps_flutter` + `geolocator`. El backend almacena coordenadas en campos `lat`/`longitude` del modelo. En el detalle, actividades presenciales muestran un hero edge-to-edge con Google Maps; virtuales muestran una imagen de portada. La migracion de `flutter_map` a `google_maps_flutter` requiere API keys configuradas en `ios/Runner/AppDelegate.swift` y `android/app/src/main/AndroidManifest.xml`
- **Tipos de actividad**: Separados en tabla catalogo `activity_types` para permitir administracion independiente
- **Instancias**: El modelo `activity_instances` se usa para actividades conjuntas (multiples secciones). Ver [actividades-conjuntas](actividades-conjuntas.md)

## Gaps y pendientes

- **`GET /catalogs/activity-types`**: Existe en backend pero sin documentacion API en ENDPOINTS-LIVE-REFERENCE.md
- **Reportes de asistencia**: No hay endpoint para obtener estadisticas o reportes de asistencia agregados

## Estado de implementacion

- **Prioridad**: Completo — backend, admin y app implementados sin gaps funcionales pendientes
