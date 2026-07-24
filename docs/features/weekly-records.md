# Weekly Records (registros semanales)

**Estado**: IMPLEMENTADO

## Descripcion de dominio

Los registros semanales consolidan puntajes por categorias para miembros de una unidad. Son la base operativa del scoring semanal y, en runtime, tambien alimentan procesos derivados como `member-of-month`.

El modelo vigente es por unidad + usuario + semana ISO + ano. Cada registro tiene puntajes desglosados por categoria en `weekly_record_scores`, y el total materializado en `weekly_records.points` se recalcula desde esas categorias. `attendance` y `punctuality` quedan como columnas legacy de compatibilidad: no son fuente de puntos.

## Que existe (verificado contra codigo)

### Backend (UnitsModule + soporte de scoring categories)
- **Controller**: `src/units/units.controller.ts`
- **Service**: `src/units/units.service.ts`
- **DTOs**: `src/units/dto/units.dto.ts`
- **4 endpoints directos**:
  - `GET /api/v1/clubs/:clubId/units/:unitId/weekly-records` - listar registros activos de miembros activos de la unidad
  - `POST /api/v1/clubs/:clubId/units/:unitId/weekly-records` - crear registro semanal individual solo para la semana ISO vigente
  - `POST /api/v1/clubs/:clubId/units/:unitId/weekly-records/bulk` - crear o actualizar atomica e idempotentemente la planilla semanal de la unidad
  - `PATCH /api/v1/clubs/:clubId/units/:unitId/weekly-records/:recordId` - actualizar estado activo o puntajes por categoria solo si el registro pertenece a la semana ISO vigente
- **Soporte relacionado**:
  - `GET /api/v1/local-fields/:fieldId/scoring-categories` provee categorias activas que el admin y la app usan para capturar puntajes, incluyendo `scoring_mode`
- **Permisos**:
  - `GET` requiere `units:read`
  - `POST`/`POST bulk` y `PATCH` requieren `units:update`
  - los endpoints resuelven alcance con `@AuthorizationResource({ type: 'club', clubIdParam: 'clubId' })`
- **Reglas verificadas**:
  - solo se puede crear para miembros activos de la unidad
  - la tupla nueva `(unit_id, user_id, week, year)` es unica; registros legacy con `unit_id = null` se leen como fallback
  - las escrituras de weekly records se limitan a la semana ISO vigente; semanas anteriores quedan cerradas para edicion retroactiva
  - el endpoint bulk ejecuta toda la planilla dentro de una unica transaccion; si un miembro/categoria/periodo falla, no se persiste ningun registro del lote
  - las categorias de puntaje se validan contra el campo local del club de la unidad
  - cada score se valida segun `scoring_mode`: `numeric` permite enteros `0..max_points`; `boolean_full` solo permite `0` o `max_points`
  - `max_points` de cada categoria esta limitado por el cap global `system_config['scoring.category_max_points_cap']` (default `20`)
  - `PATCH` hace upsert por categoria y recalcula el total de puntos
  - no hay endpoint DELETE; la baja operativa se resuelve con `PATCH` sobre `active`

### Admin
- **Surface verificada en detalle de unidad**: `WeeklyRecordsPanel` dentro de `UnitDetailPanel`
- Permite lazy load de registros y categorias, crear nuevos registros en la semana ISO vigente y editar inline scores por categoria solo para la semana abierta
- El total mostrado en la UI se deriva de los scores cargados para cada fila
- Las categorias `boolean_full` se capturan como si/no; las `numeric` como valor numerico con acciones rapidas `0` y `maximo`

### App Movil
- **Capture UI verificada**: `UnitDetailView`
- La app opera como planilla semanal: precarga los registros de la semana ISO vigente y guarda la unidad completa mediante el endpoint bulk atomico
- Pueden registrar o ajustar puntajes directores, subdirectores/secretarios del contexto activo, consejeros y capitan de la unidad
- La lista movil filtra unidades por seccion activa del contexto; una unidad creada en Aventureros no debe mostrarse al cambiar a otra seccion del mismo club
- La UI movil incluye acciones por miembro para asignar todos los puntos configurados o limpiar todos los puntos
- La UI movil renderiza `boolean_full` como switch/chip si/no y `numeric` como selector numerico con maximo
- Tambien existe data layer para listar, crear y actualizar weekly records, pero en este batch no se verifico una pantalla movil dedicada de historial tabular equivalente al admin

### Base de datos
- `weekly_records` - registro cabecera por unidad/usuario/semana/anio con asistencia/puntualidad legacy, total, `created_by` y `active`
- `weekly_record_scores` - detalle por categoria con unique `(record_id, category_id)`
- `scoring_categories` - catalogo jerarquico de categorias heredadas o propias por division/union/campo local; `scoring_mode` define captura `numeric` o `boolean_full`
- Relaciones de soporte con `units`, `unit_members`, `club_sections`, `clubs` y `users`

## Requisitos funcionales

1. Debe ser posible registrar puntaje semanal para miembros activos de una unidad
2. No debe permitirse duplicar un registro para la misma unidad/usuario/semana/anio
3. Los puntajes por categoria deben validarse contra categorias activas del campo local correspondiente
4. Ninguna categoria puede exceder su `max_points`; si es `boolean_full`, solo acepta `0` o `max_points`
5. Debe ser posible ajustar puntajes existentes de la semana ISO vigente sin recrear el registro completo
6. El total de puntos debe quedar consistente con el detalle por categoria
7. Debe ser posible guardar la planilla semanal completa de una unidad sin partial success

## Decisiones de diseno

- **Modelo por semana ISO y ano**: evita ambiguedad cuando la semana cruza meses o anos
- **Semana vigente como periodo abierto**: la captura semanal se puede corregir durante la semana ISO actual; semanas anteriores quedan cerradas
- **Planilla semanal, no sesion diaria**: si el club se reune varias veces en la misma semana, se actualiza el mismo registro semanal por miembro en lugar de crear registros diarios
- **Total materializado + detalle normalizado**: `weekly_records.points` acelera lecturas, mientras `weekly_record_scores` conserva el desglose editable. El total suma solo categorias.
- **Asistencia/puntualidad como categorias reales**: si asistencia, puntualidad, Biblia, uniforme u otro concepto debe puntuar, debe existir como `scoring_category`.
- **Modo de captura por categoria**: `numeric` permite valores intermedios; `boolean_full` representa todo-o-nada.
- **Categorias jerarquicas**: la disponibilidad depende del campo local heredando niveles superiores
- **Soft deactivation**: la superficie publica privilegia `active` en lugar de borrado fisico

## Gaps y pendientes

- **Sin delete explicito**: el contrato publico no ofrece borrado dedicado
- **UI movil de historial no verificada**: la app tiene capa de datos para weekly records, pero no se confirmo en este batch una vista de tabla/historial como la del admin
- **Attendance/punctuality legacy**: `attendance` y `punctuality` siguen siendo columnas separadas por compatibilidad, pero ya no se exponen como captura principal ni suman al total.
- **Sin historial por reunion dentro de la semana**: el modelo actual consolida por unidad/usuario/semana/anio. No conserva auditoria de multiples reuniones semanales salvo que se agregue una entidad de reuniones.
- **Fallback legacy con `unit_id = null`**: las lecturas prefieren registros con `unit_id`; si no existen, pueden usar registros antiguos sin unidad para no perder historico.

## Prioridad y siguiente accion

- **Prioridad**: Media - feature funcional en backend, admin y app movil
- **Siguiente accion**: si el club necesita varias reuniones con historico independiente en una misma semana, disenar una entidad de reuniones/sesiones separada de la planilla semanal agregada
