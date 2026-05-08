# Finanzas

**Estado**: IMPLEMENTADO

## Descripcion de dominio

El modulo de finanzas gestiona los movimientos economicos de cada club de Conquistadores, Aventureros o Guias Mayores. Los clubes manejan fondos provenientes de cuotas de miembros, ventas de alimentos, donaciones, patrocinios y actividades de recaudacion. Estos ingresos se utilizan para cubrir uniformes, materiales, campamentos, camporees, transporte y actividades formativas.

Cada club tiene su propia contabilidad independiente, con registro de ingresos y egresos categorizados. El sistema ofrece un resumen financiero por club que permite a la directiva (particularmente al tesorero) tener visibilidad del balance general. Los movimientos financieros son filtrables por ano y mes, lo que facilita el cierre contable por periodo eclesiastico.

Las categorias financieras son un catalogo compartido que permite clasificar los movimientos de forma estandar entre clubes. Esto posibilita eventuales reportes consolidados a nivel de campo local o union.

## Que existe (verificado contra codigo)

### Backend (FinancesModule)
- **Controller**: `src/finances/finances.controller.ts`
- **Service**: `src/finances/finances.service.ts`
- **Guards**: JwtAuthGuard, PermissionsGuard, ClubRolesGuard
- **8 endpoints**:
  - `GET /api/v1/finances/categories` — Listar categorias financieras
  - `GET /api/v1/clubs/:clubId/finances/transactions` — Listado paginado de transacciones con `page`, `limit`, `type`, `search`, `startDate`, `endDate`, `sortBy`, `sortOrder`
  - `GET /api/v1/clubs/:clubId/finances` — Listar movimientos financieros del club
  - `GET /api/v1/clubs/:clubId/finances/summary` — Resumen financiero del club
  - `POST /api/v1/clubs/:clubId/finances` — Crear movimiento financiero (roles: director, deputy_director, treasurer)
  - `GET /api/v1/finances/:financeId` — Obtener movimiento por ID
  - `PATCH /api/v1/finances/:financeId` — Actualizar movimiento
  - `DELETE /api/v1/finances/:financeId` — Desactivar movimiento

### Admin
- **Dashboard completo**: Tarjetas resumen (ingresos/egresos/balance), tabla de transacciones con filtros por ano/mes, dialog de creacion/edicion, confirmacion de eliminacion
- Cliente API en `src/lib/api/finances.ts`
- **Consumo verificado**: usa `GET /api/v1/clubs/:clubId/finances`, `GET /summary`, `GET /finances/categories`, `POST /clubs/:clubId/finances`, `GET /finances/:financeId`, `PATCH /finances/:financeId`, `DELETE /finances/:financeId`
- **Filtro actual admin**: el dashboard trabaja sobre la superficie mensual/anual de `GET /api/v1/clubs/:clubId/finances`; no usa hoy el endpoint paginado `/transactions`

### App Movil
- **Superficies principales**: `FinancesView`, `AddTransactionSheet`, `TransactionDetailView`, `AllTransactionsView`
- Consume el listado mensual (`GET /clubs/:clubId/finances`), resumen (`GET /summary`), CRUD, categorias y el listado paginado `GET /clubs/:clubId/finances/transactions`
- Soporta filtros por ano/mes en la vista principal
- Soporta busqueda, filtro por tipo, rango de fechas, orden y paginacion infinita en la vista completa de transacciones
- Muestra resumen financiero (balance, total ingresos, total egresos)
- CRUD completo de transacciones desde la app, incluyendo eliminacion con confirmacion via AlertDialog en la vista de detalle

### Base de datos
- `finances` — Movimientos financieros (ingresos/egresos por club)
- `finances_categories` — Catalogo de categorias de movimientos financieros

## Requisitos funcionales

1. Solo roles de tesorero, director o `deputy_director` deben poder crear movimientos financieros
2. Cada movimiento debe registrar: monto, tipo (ingreso/egreso), categoria, descripcion, fecha
3. El sistema debe calcular y exponer un resumen financiero por club (balance, total ingresos, total egresos)
4. Los movimientos deben ser filtrables por ano y mes
5. Los movimientos deben poder desactivarse (soft delete) sin perder datos historicos
6. Las categorias financieras deben ser un catalogo compartido entre clubes
7. El panel admin debe permitir gestion y supervision financiera de los clubes
8. El resumen financiero debe actualizarse en tiempo real conforme se registran movimientos

## Decisiones de diseno

- **Autorizacion por rol de club**: La creacion de movimientos esta restringida a `director`, `deputy_director` y `treasurer` mediante `ClubRolesGuard`
- **Soft delete**: Los movimientos se desactivan; esto implica que el resumen financiero debe considerar solo registros activos
- **Categorias compartidas**: Las categorias financieras son globales, no por club, permitiendo estandarizacion
- **Resumen calculado**: El endpoint `summary` calcula el balance en tiempo real desde los movimientos activos, no desde un campo pre-calculado
- **Doble superficie de lectura**: `GET /clubs/:clubId/finances` resuelve la vista mensual/anual del dashboard y `GET /clubs/:clubId/finances/transactions` cubre busqueda, filtros avanzados y paginacion server-side
- **Filtrado temporal**: Los filtros por ano/mes se aplican a nivel de query, no como entidades separadas

## Gaps y pendientes

- **Sin reportes avanzados**: No hay endpoints para reportes por categoria, tendencias temporales o comparativas entre periodos
- **Sin exportacion**: No hay funcionalidad para exportar movimientos a PDF o Excel
- **Sin auditoría avanzada**: Los movimientos registran `created_by` (UUID, NOT NULL) y `modified_by_id` (UUID, nullable, FK a users); no hay audit trail de acciones en formato log
- **Sin presupuesto**: No hay modelo para definir presupuestos anuales por categoria y comparar ejecucion vs presupuesto

## Estado de implementacion

- **Prioridad**: Completo — backend, admin y app implementados sin gaps funcionales pendientes
