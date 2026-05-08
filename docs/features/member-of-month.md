# Member of Month (miembro del mes)

**Estado**: IMPLEMENTADO

## Descripcion de dominio

Miembro del Mes reconoce al integrante con mayor puntaje semanal acumulado dentro de una seccion para un mes y ano determinados. El ranking se calcula sobre `weekly_record_scores` asociados a miembros activos de unidades activas de esa seccion y admite empates.

La feature combina consulta del ganador vigente, historial paginado, evaluacion manual protegida e evaluacion automatica por cron para el mes anterior. Tambien dispara notificaciones hacia ganadores y directores de la seccion.

## Que existe (verificado contra codigo)

### Backend (MemberOfMonthModule)
- **Controller**: `src/member-of-month/member-of-month.controller.ts`
- **Service**: `src/member-of-month/member-of-month.service.ts`
- **Cron**: `src/member-of-month/member-of-month-cron.service.ts`
- **4 endpoints**:
  - `GET /api/v1/clubs/:clubId/sections/:sectionId/member-of-month` - obtener ganador(es) del mes actual
  - `GET /api/v1/clubs/:clubId/sections/:sectionId/member-of-month/history` - historial paginado por periodo
  - `POST /api/v1/clubs/:clubId/sections/:sectionId/member-of-month/evaluate` - disparar evaluacion manual de un mes/anio
  - `GET /api/v1/member-of-month/admin/list` - **supervision multi-seccion para admin/coordinator** (agregado 2026-04-22). Query params: `club_type_id`, `local_field_id`, `club_id`, `section_id`, `year`, `month`, `notified`, `page`, `limit`. Scope: admin/super_admin ve todo; coordinator es forzado a su `local_field_id` resuelto via `AuthorizationContextService`. Response paginada con user_name, section_name, club_type, club_name, local_field, total_points, notified.
- **Permisos y reglas** (migrados a dominio propio 2026-04-22):
  - lectura por seccion requiere `mom:read`
  - supervision multi-seccion (endpoint admin/list) requiere `mom:supervise`
  - evaluacion manual requiere `mom:evaluate`, throttle de `5` requests por minuto y validacion adicional de rol director/sub-director/directora activo en la seccion
  - la evaluacion es idempotente: borra e inserta de nuevo el periodo antes de persistir ganadores
  - el historial pagina por periodos distintos `(year, month)` y limita `limit` a `100`
- **Cron operativo**:
  - corre el dia `1` de cada mes a las `00:05 UTC`
  - evalua el mes anterior para todas las secciones activas en lotes de `10`
  - corta la corrida si supera `5` minutos y deja log de timeout
- **Notificaciones**:
  - al ganador: tipo `member_of_month`
  - a directores de la seccion: tipo `member_of_month_director`
  - la tabla persiste `notified=true` solo para ganadores notificados exitosamente

### Admin
- **Lectura verificada en panel de secciones**: `MemberOfMonthCard` dentro de `ClubSectionsPanel`
- Muestra ganador actual e historial paginado por seccion
- Existe dialogo reusable para evaluacion manual, pero la unica integracion verificada monta la card con `isDirector={false}`, por lo que el admin hoy queda en modo lectura para esta feature

### App Movil
- **Surface verificada en Units**:
  - `UnitsListView` muestra una card destacada cuando existe ganador actual
  - `MemberOfMonthHistoryView` expone historial con scroll infinito
  - `PushNotificationService` deep-linkea notificaciones `member_of_month` al historial y `member_of_month_director` a la vista de unidades
- No se verifico consumo movil del endpoint manual de evaluacion

### Base de datos
- `member_of_month` - persistencia de ganadores por seccion/mes/anio con `total_points` y `notified`
- `weekly_records` y `weekly_record_scores` - fuente del puntaje agregado
- `unit_members`, `units`, `club_sections`, `club_role_assignments` - relaciones usadas para resolver miembros elegibles y directores a notificar

## Requisitos funcionales

1. Debe ser posible consultar el ganador actual por seccion
2. Debe existir historial paginado por mes/anio
3. La evaluacion debe permitir empates cuando varios miembros comparten el maximo puntaje
4. Solo directores de la seccion pueden disparar evaluacion manual
5. La evaluacion automatica mensual debe cubrir todas las secciones activas
6. Ganadores y directores deben recibir notificaciones relacionadas al resultado

## Decisiones de diseno

- **Fuente unica de verdad: weekly scores** - no se guarda un ranking manual paralelo; el resultado se deriva de `weekly_record_scores`
- **Persistencia idempotente por periodo** - revaluar un mes reemplaza el resultado previo del mismo periodo
- **Empate nativo** - la tabla permite multiples filas por periodo y seccion porque la unicidad incluye `user_id`
- **Read model directo para clientes** - la API devuelve `members: null` si el mes actual aun no tiene evaluacion, evitando inventar un ganador vacio

## Gaps y pendientes

- **UI admin de evaluacion no conectada**: el backend soporta evaluacion manual, pero la integracion admin verificada hoy la deja fuera de alcance visible
- **Sin arbitraje de periodos fuera de rango**: el DTO limita anos `2020-2100`, pero no se verifico una politica de negocio mas fina sobre meses cerrados
- **Sin pantalla movil para evaluar**: la app consume lectura e historial, no la mutacion manual

## Prioridad y siguiente accion

- **Prioridad**: Media - feature real en backend, con lectura en admin/app y automatizacion mensual activa
- **Siguiente accion**: decidir si el admin debe exponer explicitamente la evaluacion manual o mantenerse como proceso principalmente automatico
