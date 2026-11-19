# Actividades

**Estado**: IMPLEMENTADO

**Actualizado**: 2026-11-19 (`development`; rediseño del flujo en la app, sacdia-app #274, y lista de asistencia para todas las modalidades, sacdia-backend #666).

## Descripcion de dominio

Las actividades son el eje operativo del dia a dia de un club de Conquistadores, Aventureros o Guias Mayores. Representan cualquier evento planificado por la directiva del club: reuniones regulares, campamentos, excursiones, proyectos comunitarios, ensayos de orden cerrado, clases especiales y eventos sociales. Cada actividad esta vinculada a un club especifico y puede tener un tipo categorizado (catalogo `activity_types`).

El registro de asistencia a actividades es fundamental para el seguimiento formativo de los miembros. La asistencia alimenta la trayectoria del miembro dentro del club y puede ser requisito para completar secciones de clases progresivas o para validar la participacion en investiduras. Las actividades tambien soportan geolocalizacion, permitiendo documentar el lugar exacto donde se realiza cada evento.

El modelo contempla `activity_instances` como instancias de una actividad por seccion. Eso **no es recurrencia**: cada fila es “una actividad × una seccion”. La recurrencia vive en `activity_series` (cabecera) + N filas `activities` con `activity_series_id`. La funcionalidad principal de instancias sigue siendo **actividades conjuntas** — actividades que abarcan multiples secciones del club (ver [actividades-conjuntas](actividades-conjuntas.md)). Cuando una actividad es conjunta (`is_joint=true`), se crea una instancia por cada seccion participante.

Las series recurrentes materializan de inmediato copias independientes (cada N dias o un dia de la semana, hasta una fecha `until` dentro del año eclesiastico activo). Editar una sesion no cambia a las hermanas ni la receta. `POST /clubs/:clubId/activities` sigue creando una sola actividad; el interruptor “Repetir” usa `POST /clubs/:clubId/activity-series`.

## Que existe (verificado contra codigo)

### Backend (ActivitiesModule)
- **Controller**: `src/activities/activities.controller.ts`
- **Service**: `src/activities/activities.service.ts`
- **Guards**: JwtAuthGuard, PermissionsGuard, ClubRolesGuard
- **Endpoints**:
  - `GET /api/v1/clubs/:clubId/activities` — Listar actividades del club (query opcional `seriesId`)
  - `POST /api/v1/clubs/:clubId/activities` — Crear actividad (roles: director, subdirector, secretary, counselor)
  - `POST /api/v1/clubs/:clubId/activity-series/preview` — Vista previa de fechas de una serie
  - `POST /api/v1/clubs/:clubId/activity-series` — Crear serie y materializar N actividades
  - `GET /api/v1/activity-series/:seriesId` — Receta y conteos de la serie
  - `POST /api/v1/activity-series/:seriesId/cancel-future` — Desactivar sesiones de hoy en adelante
  - `POST /api/v1/activity-series/:seriesId/extend` — Alargar `until` y crear fechas que aun no existen
  - `GET /api/v1/activities/:activityId` — Obtener actividad por ID
  - `PATCH /api/v1/activities/:activityId` — Actualizar actividad
  - `DELETE /api/v1/activities/:activityId` — Desactivar actividad
  - `POST /api/v1/activities/:activityId/image` — Subir imagen
  - `POST /api/v1/activities/:activityId/attendance` — Registrar asistencia confirmada
  - `GET /api/v1/activities/:activityId/attendance` — Obtener asistencia confirmada
  - `GET /api/v1/activities/:activityId/rsvp` — Intención del usuario en una actividad virtual
  - `PUT /api/v1/activities/:activityId/rsvp` — Marcar `going` o `not_going` (no confirma asistencia)
  - `GET /api/v1/activities/:activityId/attendance-roster` — Miembros activos de las secciones de la actividad, con `rsvp` y `confirmed`. Sirve para cualquier modalidad desde sacdia-backend #666: la app lo usa para marcar asistencia a mano también en presencial e híbrido. `rsvp` solo trae valor en virtual

### Admin
- **UI completa**: Pagina de lista con selector de club, pagina de detalle con panel de asistencia, dialog de creacion/edicion, confirmacion de eliminacion
- Dialog de alta con interruptor **Repetir esta actividad**, preview de fechas y `POST .../activity-series`. Con repetición activa se oculta la fecha de fin de la sesión; el límite de la serie es `until`
- El alta elige público: toda la sección, directiva, o clases del tipo de club seleccionado, con el logo de cada clase. Por defecto van todas marcadas. El panel crea una sola sección; la conjunta sigue en la app
- El listado y el detalle muestran ese público. Si es por clases, el detalle incluye el logo y el nombre. El API agrega `audience_classes` en el listado y en el detalle
- El detalle no ofrece ver la serie, cancelar sesiones futuras ni agregar más sesiones
- Cliente API en `src/lib/api/activities.ts`

### App Movil
- **Pantallas**: `ActivitiesListView` (agenda), `ActivityDetailView`, `CreateActivityView`, `EditActivityView`, `LocationPickerView` y, desde el rediseño de sacdia-app #274, `ActivityAttendanceView`, `ActivityMyQrView` y `ActivityManualAttendanceView`
- Mismo interruptor de repeticion y preview al crear. El detalle no muestra acciones de serie
- Incluye selector de ubicacion en mapa (LocationPickerView)
- `ActivitiesListView` resuelve `clubId` desde `clubContextProvider` (bug de hardcodeo a 1 corregido)
- El listado pide todas las páginas de `GET /clubs/:clubId/activities` (el API devuelve 20 por defecto). Sin eso, la vista de todas se corta en las actividades más recientes
- Al crear se elige el público: toda la sección, directiva, o clases. Por defecto, todas las clases de las secciones elegidas. En conjunta se listan las clases de esas secciones con su logo. `audience=board` la ven solo director, subdirector, secretario, tesorero y secretario-tesorero. `audience=classes` la ven quienes están en una clase marcada y también la directiva de la sección, para poder operarla
- El listado y el detalle muestran para quién es. En clases se ven el logo y el nombre (`audience_classes`)
- Edicion y eliminacion de actividades disponibles en la vista de detalle (`EditActivityView` + confirmacion de borrado)
- El boton "Agregar" en `ActivitiesListView` solo se muestra a usuarios con permiso `activities:create` o con roles legacy `director`, `deputy_director`, `secretary`, `counselor` — evaluado via `canByPermissionOrLegacyRole`
- Widget de inicio **Próxima actividad** (iOS WidgetKit y Android App Widget). Muestra título, fecha y club de la primera `upcomingActivities` del dashboard. Se actualiza al cargar o refrescar el inicio y se vacía al cerrar sesión. Un toque abre `/activity/:activityId`. En iOS hace falta el App Group `group.com.sacdia.app` en el equipo de firma.

**Entidad Activity — campos adicionales (post-rediseno):**
- `lat`, `longitude` — coordenadas de la ubicacion
- `activityDate`, `activityEndDate` — fecha/hora de inicio y fin
- `attendees` — lista de participantes con nombre e imagen
- `classes` — secciones/clases asociadas a la actividad
- `additionalData` — datos extra sin esquema fijo
- `creatorName`, `creatorImage` — datos del organizador
- Getters computados: `isPast` (actividad ya ocurrio), `hasVirtualLink` (tiene link de videoconferencia), `hasLocation` (tiene coordenadas validas)

**Rediseño del flujo (sacdia-app #274, 2026-11-19):**

La agenda (`ActivitiesListView`) y el formulario de crear y editar conservan su diseño. El formulario solo cambió el título a «Nueva actividad» y «Editar actividad», sin subtítulo.

*Detalle (`ActivityDetailView`)*, de arriba abajo:
- `SacTopBar` con «⋯» (`activity_more_sheet.dart`): Editar y Eliminar, cada uno solo si el usuario puede. Eliminar va al final, en rojo.
- Encabezado sobrio: cuadro de fecha (`activity_date_tile.dart`, día sobre el mes en tres letras), título y tipo (`activity_type_style.dart`).
- Mapa integrado arriba (`activity_map_card.dart`), visible antes de bajar. Solo en presencial e híbrido con coordenadas (`activityHasMapCard`). Un toque abre las opciones de mapa (`activity_map_options_sheet.dart`). El mapa no recibe gestos: evita que el scroll se quede atrapado en el mapa nativo.
- Panel de estado en tarjeta (`activity_state_panel.dart`, sobre `SacStatePanel`), calculado con fecha y hora: próxima (cuenta regresiva, día y hora), en curso o terminada (hace cuánto y, si el backend manda asistentes, cuántos vinieron). Es de solo lectura, sin línea de pasos.
- DETALLES en filas (`activity_detail_row.dart`): fecha completa, para quién es (`audience_classes` con logo) y modalidad.
- Descripción completa en varias líneas (`activity_description_block.dart`), sin «ver más».
- En virtual, la intención Asistiré / No asistiré (`activity_virtual_attendance.dart`). No confirma asistencia.
- ASISTENCIA (`activity_attendees_section.dart`) y ORGANIZA.
- Una sola acción en el pie (`activity_detail_actions.dart`):
  - Presencial e híbrido, con `attendance:manage` o capacidad `club.operational_staff`: «Asistencia» (también después de terminada).
  - Presencial e híbrido, resto de miembros: «Mostrar mi QR» hasta que termina.
  - Virtual: «Unirse a la reunión» mientras no termina y hay enlace. Quien confirma lo hace desde una fila del grupo de asistencia.
- Carga con `activity_detail_skeleton.dart`.

*Asistencia (`ActivityAttendanceView`)*, para la directiva:
- Resumen «n de total» con número rodante y barra de dos partes. Los registrados usan el color de acento de la app; el resto, el borde.
- Lista REGISTRADOS, el último registrado primero (orden inverso de `attendees`; no hay hora por asistente).
- Pie con dos botones apilados del mismo tamaño y con su texto completo: «Escanear QR» (principal) y «Marcar a mano». En virtual solo «Marcar a mano».

*Mi QR (`ActivityMyQrView`)*: el QR del miembro, grande. Mientras está abierta consulta la actividad cada 5 s. Cuando el miembro aparece en `attendees`, el panel pasa a «Asistencia registrada» y el QR se desvanece.

*Resultado del escaneo (`QrScanResultSheet` en `qr_scanner_view.dart`)*: hoja con foto, nombre y palomita dibujada (`SacDrawReveal`), y «Asistencia registrada · n de total».

*Marcar a mano (`ActivityManualAttendanceView`)*:
- Lista estable en orden alfabético de `GET /activities/:id/attendance-roster`: las filas no cambian de lugar al marcar.
- Toda la fila es el área de toque (56 px mínimo). La fila marcada lleva un tinte del acento, una palomita sobre el avatar y el interruptor encendido. Vibración ligera en cada cambio.
- Subtítulo «n de total presentes». Búsqueda y filtros Todos / Faltan / Presentes con contador. Si una fila deja de cumplir el filtro, se desvanece y se cierra en 200 ms.
- Cada cambio muestra un solo aviso a la vez, «Asistencia marcada: {nombre}» o «Asistencia quitada: {nombre}», con «Deshacer» durante 4 s. El texto es neutro en género.
- Salir con cambios sin guardar pide confirmación («Seguir marcando» / «Salir»).
- «Guardar» envía la lista completa a `POST /activities/:id/attendance`, que reemplaza `attendees`.

*Movimiento* (tokens de `SacMotion`): entrada escalonada de la agenda y del detalle (`SacEntrance`), deslizamiento en la dirección del día al cambiar de día en la agenda, palomita dibujada al escanear y número rodante en el resumen. Con movimiento reducido, se muestran sin animación.

*Pendiente conocido*: un toque durante la animación de entrada a veces no se registra.

**CreateActivityView — cambios de formulario:**
- Agregados date pickers para fecha de inicio y fecha de fin. Con «Repetir esta actividad» se oculta la fecha de fin y no se envía `activity_end_date`; el límite queda en «Repetir hasta»
- `SacDropdownField` reemplazado por `BottomSheetPicker` para seleccion de tipo y seccion

### Base de datos
- `activities` — Actividades del club (`activity_series_id` opcional agrupa copias de una serie; `rsvp` guarda la intención en virtuales)
- `activity_types` — Catalogo de tipos de actividad
- `activity_instances` — Instancias de una actividad por seccion (conjuntas; **no** es recurrencia)
- `activity_series` — Receta de una serie recurrente (kind `interval` | `weekly`, `until_date`)
- `activity_series_sections` — Secciones de una serie conjunta, usadas al extender

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
- **Asistencia confirmada no es self-service**: En presencial e híbrido la asistencia la registran usuarios autorizados via QR (`attendance:manage` o roles operacionales de club), a mano desde la app con la lista de `attendance-roster`, o desde el panel admin (`POST /activities/:id/attendance`). En virtual (`platform = 1`) el QR no registra asistencia. El miembro marca intención en `activities.rsvp` (`going` = hará lo posible, `not_going` = no asistirá, reversible). Esa intención no escribe `attendees` ni emite `activity.attended`. Quien tiene `attendance:manage` confirma la asistencia real entre todos los miembros activos de las secciones de la actividad, aunque hayan dicho que no irían
- **BottomSheetPicker en formularios**: El formulario de creacion de actividad adopta `BottomSheetPicker` en lugar de `SacDropdownField` para la seleccion de tipo y seccion, alineandose con el patron de pickers del resto de la app
- **Geolocalizacion**: La app implementa seleccion de ubicacion en mapa (LocationPickerView) usando `google_maps_flutter` + `geolocator`. El backend almacena coordenadas en campos `lat`/`longitude` del modelo. En el detalle, presencial e híbrido con coordenadas muestran una tarjeta de mapa bajo el encabezado, antes de los detalles; virtual no muestra mapa. La migracion de `flutter_map` a `google_maps_flutter` requiere API keys configuradas en `ios/Runner/AppDelegate.swift` y `android/app/src/main/AndroidManifest.xml`
- **URLs privadas no bloqueantes**: Las imagenes privadas de actividades y perfiles se firman con R2 cuando la configuracion esta disponible. Si R2 no puede firmar una URL en lectura, el backend registra un warning y devuelve el valor almacenado para no romper listados, dashboard ni detalle por un asset no critico.
- **Tipos de actividad**: Separados en tabla catalogo `activity_types` para permitir administracion independiente
- **Instancias**: El modelo `activity_instances` se usa para actividades conjuntas (multiples secciones). Ver [actividades-conjuntas](actividades-conjuntas.md)
- **`user_ids` acepta cualquier versión de UUID** (`@IsUUID('all')` desde sacdia-backend #666). Antes exigía v4 y rechazaba los usuarios de seed, que usan v5

## Gaps y pendientes

- **`GET /catalogs/activity-types`**: Existe en backend pero sin documentacion API en ENDPOINTS-LIVE-REFERENCE.md
- **Reportes de asistencia**: No hay endpoint para obtener estadisticas o reportes de asistencia agregados

## Estado de implementacion

- **Prioridad**: Completo — backend, admin y app implementados sin gaps funcionales pendientes
