# Weekly Records (registros semanales)

**Estado**: IMPLEMENTADO

## Descripcion de dominio

Los registros semanales consolidan asistencia, puntualidad y puntaje por categorias para miembros de una unidad. Son la base operativa del scoring semanal y, en runtime, tambien alimentan procesos derivados como `member-of-month`.

El modelo vigente es por usuario + semana ISO + ano. Cada registro puede tener puntajes desglosados por categoria en `weekly_record_scores`, y el total materializado en `weekly_records.points` se recalcula desde esas categorias cuando corresponde.

## Que existe (verificado contra codigo)

### Backend (UnitsModule + soporte de scoring categories)
- **Controller**: `src/units/units.controller.ts`
- **Service**: `src/units/units.service.ts`
- **DTOs**: `src/units/dto/units.dto.ts`
- **3 endpoints directos**:
  - `GET /api/v1/clubs/:clubId/units/:unitId/weekly-records` - listar registros activos de miembros activos de la unidad
  - `POST /api/v1/clubs/:clubId/units/:unitId/weekly-records` - crear registro semanal
  - `PATCH /api/v1/clubs/:clubId/units/:unitId/weekly-records/:recordId` - actualizar asistencia, puntualidad, estado activo o puntajes por categoria
- **Soporte relacionado**:
  - `GET /api/v1/local-fields/:fieldId/scoring-categories` provee categorias activas que el admin y la app usan para capturar puntajes
- **Permisos**:
  - `GET` requiere `units:read`
  - `POST` y `PATCH` requieren `units:update`
  - los tres endpoints resuelven alcance con `@AuthorizationResource({ type: 'club', clubIdParam: 'clubId' })`
- **Reglas verificadas**:
  - solo se puede crear para miembros activos de la unidad
  - la tupla `(user_id, week, year)` es unica
  - las categorias de puntaje se validan contra el campo local del club de la unidad
  - cada score no puede superar `max_points` de su categoria
  - `PATCH` hace upsert por categoria y recalcula el total de puntos
  - no hay endpoint DELETE; la baja operativa se resuelve con `PATCH` sobre `active`

### Admin
- **Surface verificada en detalle de unidad**: `WeeklyRecordsPanel` dentro de `UnitDetailPanel`
- Permite lazy load de registros y categorias, crear nuevos registros y editar inline asistencia, puntualidad y scores por categoria
- El total mostrado en la UI se deriva de los scores cargados para cada fila

### App Movil
- **Capture UI verificada**: `UnitDetailView`
- La app permite registrar una sesion diaria de puntos para miembros de la unidad y la persiste creando registros semanales para la semana/anio ISO actual
- Pueden registrar o ajustar puntajes directores, subdirectores/secretarios del contexto activo, consejeros y capitan de la unidad
- Tambien existe data layer para listar, crear y actualizar weekly records, pero en este batch no se verifico una pantalla movil dedicada de historial tabular equivalente al admin

### Base de datos
- `weekly_records` - registro cabecera por usuario/semana/anio con asistencia, puntualidad, total, `created_by` y `active`
- `weekly_record_scores` - detalle por categoria con unique `(record_id, category_id)`
- `scoring_categories` - catalogo jerarquico de categorias heredadas o propias por division/union/campo local
- Relaciones de soporte con `units`, `unit_members`, `club_sections`, `clubs` y `users`

## Requisitos funcionales

1. Debe ser posible registrar puntaje semanal para miembros activos de una unidad
2. No debe permitirse duplicar un registro para el mismo usuario/semana/anio
3. Los puntajes por categoria deben validarse contra categorias activas del campo local correspondiente
4. Ninguna categoria puede exceder su `max_points`
5. Debe ser posible ajustar puntajes existentes sin recrear el registro completo
6. El total de puntos debe quedar consistente con el detalle por categoria

## Decisiones de diseno

- **Modelo por semana ISO y ano**: evita ambiguedad cuando la semana cruza meses o anos
- **Total materializado + detalle normalizado**: `weekly_records.points` acelera lecturas, mientras `weekly_record_scores` conserva el desglose editable
- **Categorias jerarquicas**: la disponibilidad depende del campo local heredando niveles superiores
- **Soft deactivation**: la superficie publica privilegia `active` en lugar de borrado fisico

## Gaps y pendientes

- **Sin delete explicito**: el contrato publico no ofrece borrado dedicado
- **UI movil de historial no verificada**: la app tiene capa de datos para weekly records, pero no se confirmo en este batch una vista de tabla/historial como la del admin
- **Sin cierre semanal formal**: no se verifico un estado de bloqueo o cierre que impida ediciones retroactivas

## Prioridad y siguiente accion

- **Prioridad**: Media - feature funcional en backend y admin, con captura movil operativa pero cobertura UI mas acotada
- **Siguiente accion**: arbitrar si la app necesita exponer historial/edicion explicita de registros existentes mas alla de la captura de sesion diaria
