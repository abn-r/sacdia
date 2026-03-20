# Finanzas

**Estado**: PARCIAL

## Descripcion de dominio

El modulo de finanzas gestiona los movimientos economicos de cada club de Conquistadores, Aventureros o Guias Mayores. Los clubes manejan fondos provenientes de cuotas de miembros, ventas de alimentos, donaciones, patrocinios y actividades de recaudacion. Estos ingresos se utilizan para cubrir uniformes, materiales, campamentos, camporees, transporte y actividades formativas.

Cada club tiene su propia contabilidad independiente, con registro de ingresos y egresos categorizados. El sistema ofrece un resumen financiero por club que permite a la directiva (particularmente al tesorero) tener visibilidad del balance general. Los movimientos financieros son filtrables por ano y mes, lo que facilita el cierre contable por periodo eclesiastico.

Las categorias financieras son un catalogo compartido que permite clasificar los movimientos de forma estandar entre clubes. Esto posibilita eventuales reportes consolidados a nivel de campo local o union.

## Que existe (verificado contra codigo)

### Backend (FinancesModule)
- **Controller**: `src/finances/finances.controller.ts`
- **Service**: `src/finances/finances.service.ts`
- **Guards**: JwtAuthGuard, PermissionsGuard, ClubRolesGuard
- **7 endpoints**:
  - `GET /api/v1/finances/categories` — Listar categorias financieras
  - `GET /api/v1/clubs/:clubId/finances` — Listar movimientos financieros del club
  - `GET /api/v1/clubs/:clubId/finances/summary` — Resumen financiero del club
  - `POST /api/v1/clubs/:clubId/finances` — Crear movimiento financiero (roles: director, subdirector, treasurer)
  - `GET /api/v1/finances/:financeId` — Obtener movimiento por ID
  - `PATCH /api/v1/finances/:financeId` — Actualizar movimiento
  - `DELETE /api/v1/finances/:financeId` — Desactivar movimiento

### Admin
- **Placeholder** — Redirige a seleccionar club. No consume endpoints. Sin funcionalidad real.

### App Movil
- **3 screens**: FinancesView, AddTransactionSheet, TransactionDetailView
- Consume los 7 endpoints del backend
- Soporta filtros por ano/mes en el listado
- Muestra resumen financiero (balance, total ingresos, total egresos)
- CRUD completo de transacciones desde la app

### Base de datos
- `finances` — Movimientos financieros (ingresos/egresos por club)
- `finances_categories` — Catalogo de categorias de movimientos financieros

## Requisitos funcionales

1. Solo roles de tesorero, director o subdirector deben poder crear movimientos financieros
2. Cada movimiento debe registrar: monto, tipo (ingreso/egreso), categoria, descripcion, fecha
3. El sistema debe calcular y exponer un resumen financiero por club (balance, total ingresos, total egresos)
4. Los movimientos deben ser filtrables por ano y mes
5. Los movimientos deben poder desactivarse (soft delete) sin perder datos historicos
6. Las categorias financieras deben ser un catalogo compartido entre clubes
7. El panel admin debe permitir gestion y supervision financiera de los clubes (actualmente placeholder)
8. El resumen financiero debe actualizarse en tiempo real conforme se registran movimientos

## Decisiones de diseno

- **Autorizacion por rol de club**: La creacion de movimientos esta restringida a director, subdirector y tesorero mediante `ClubRolesGuard`
- **Soft delete**: Los movimientos se desactivan; esto implica que el resumen financiero debe considerar solo registros activos
- **Categorias compartidas**: Las categorias financieras son globales, no por club, permitiendo estandarizacion
- **Resumen calculado**: El endpoint `summary` calcula el balance en tiempo real desde los movimientos activos, no desde un campo pre-calculado
- **Filtrado temporal**: Los filtros por ano/mes se aplican a nivel de query, no como entidades separadas

## Gaps y pendientes

- **Admin es placeholder**: Backend y app completos pero el panel admin no tiene UI funcional
- **Sin reportes avanzados**: No hay endpoints para reportes por categoria, tendencias temporales o comparativas entre periodos
- **Sin exportacion**: No hay funcionalidad para exportar movimientos a PDF o Excel
- **Sin auditoría avanzada**: Los movimientos registran `created_by` (UUID, NOT NULL) y `modified_by_id` (UUID, nullable, FK a users); no hay audit trail de acciones en formato log
- **Sin presupuesto**: No hay modelo para definir presupuestos anuales por categoria y comparar ejecucion vs presupuesto

## Prioridad y siguiente accion

- **Prioridad**: Media — backend y app funcionales; admin es el gap principal
- **Siguiente accion**: Implementar UI de finanzas en sacdia-admin consumiendo los 7 endpoints existentes.
