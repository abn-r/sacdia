# Finanzas

**Estado**: IMPLEMENTADO (superficie legacy) / WU1 entregado (fundamento v2, sin API v2)

## Descripcion de dominio

El modulo de finanzas gestiona los movimientos economicos de cada club de Conquistadores, Aventureros o Guias Mayores. Los clubes manejan fondos provenientes de cuotas de miembros, ventas de alimentos, donaciones, patrocinios y actividades de recaudacion. Estos ingresos se utilizan para cubrir uniformes, materiales, campamentos, camporees, transporte y actividades formativas.

Cada club tiene su propia contabilidad independiente, con registro de ingresos y egresos categorizados. El sistema ofrece un resumen financiero por club que permite a la directiva (particularmente al tesorero) tener visibilidad del balance general. Los movimientos financieros son filtrables por ano y mes, lo que facilita el cierre contable por periodo eclesiastico.

Cuando el resumen se consulta con `year` y `month`, el campo `balance` representa el saldo acumulado del ano eclesiastico que contiene ese mes, desde el inicio del ano eclesiastico hasta el cierre del mes seleccionado. Los meses ya cerrados se toman desde `finance_period_closings`; los meses abiertos se calculan con movimientos activos en tiempo real.

Las categorias financieras son un catalogo compartido que permite clasificar los movimientos de forma estandar entre clubes. Cada categoria tiene un tipo fijo: `0` para ingreso o `1` para egreso. Solo categorias activas y con uno de esos tipos pueden asignarse a un movimiento. Esto posibilita eventuales reportes consolidados a nivel de campo local o union.

## Que existe (verificado contra codigo)

### Backend (FinancesModule)
- **Controller**: `src/finances/finances.controller.ts`
- **Service**: `src/finances/finances.service.ts`
- **Guards**: JwtAuthGuard, PermissionsGuard, ClubRolesGuard
- **9 endpoints**:
  - `GET /api/v1/finances/categories` — Listar categorias financieras
  - `GET /api/v1/clubs/:clubId/finances/transactions` — Listado paginado de transacciones con `page`, `limit`, `type`, `search`, `startDate`, `endDate`, `sortBy`, `sortOrder`
  - `GET /api/v1/clubs/:clubId/finances` — Listar movimientos financieros del club
  - `GET /api/v1/clubs/:clubId/finances/summary` — Resumen financiero del club
  - `POST /api/v1/clubs/:clubId/finances` — Crear movimiento financiero (roles: director, deputy_director, treasurer)
  - `GET /api/v1/finances/:financeId` — Obtener movimiento por ID
  - `POST /api/v1/finances/:financeId/evidences` — Subir foto de evidencia del ingreso/egreso (maximo 3 fotos activas por movimiento)
  - `PATCH /api/v1/finances/:financeId` — Actualizar movimiento
  - `DELETE /api/v1/finances/:financeId` — Desactivar movimiento

### Admin
- **Dashboard completo**: Tarjetas resumen (ingresos/egresos/balance), tabla de transacciones con filtros por ano/mes, dialog de creacion/edicion, confirmacion de eliminacion
- Cliente API en `src/lib/api/finances.ts`
- **Consumo verificado**: usa `GET /api/v1/clubs/:clubId/finances`, `GET /summary`, `GET /finances/categories`, `POST /clubs/:clubId/finances`, `GET /finances/:financeId`, `POST /finances/:financeId/evidences`, `PATCH /finances/:financeId`, `DELETE /finances/:financeId`
- El dialog de creacion/edicion permite adjuntar evidencias fotograficas del comprobante, respetando el limite de 3 fotos por movimiento.
- **Filtro actual admin**: el dashboard trabaja sobre la superficie mensual/anual de `GET /api/v1/clubs/:clubId/finances`; no usa hoy el endpoint paginado `/transactions`

### App Movil
- **Superficies principales**: `FinancesView`, `AddTransactionSheet`, `TransactionDetailView`, `AllTransactionsView`
- Consume el listado mensual (`GET /clubs/:clubId/finances`), resumen (`GET /summary`), CRUD, categorias y el listado paginado `GET /clubs/:clubId/finances/transactions`
- Soporta filtros por ano/mes en la vista principal
- Soporta busqueda, filtro por tipo, rango de fechas, orden y paginacion infinita en la vista completa de transacciones
- Muestra resumen financiero (balance, total ingresos, total egresos)
- CRUD completo de transacciones desde la app, incluyendo eliminacion con confirmacion via AlertDialog en la vista de detalle
- Permite adjuntar hasta 3 fotos de evidencia por ingreso o egreso desde el formulario y visualizarlas en el detalle con visor interno.

### Base de datos
- `finances` — Movimientos financieros (ingresos/egresos por club)
- `finance_evidence_files` — Fotos de evidencia asociadas a movimientos financieros
- `finances_categories` — Catalogo de categorias de movimientos financieros
- WU1 añade, sin exponer todavía escritura o lectura v2: `finance_currencies`, `finance_ledger_entries`, `finance_vouchers`, `finance_receipt_allocations`, `finance_ledger_events` y `finance_idempotency_receipts`.

## Fundamento del ledger v2 (WU1)

Esta entrega es únicamente de base de datos, permisos, rollout y backfill. No añade endpoints, DTOs, pantallas ni cambia los endpoints legacy descritos arriba.

- Las nuevas entradas usan importes enteros en centavos, moneda ISO 4217 del catálogo y estados `pending_approval`, `approved` o `rejected`. Las reglas DB impiden decisiones incompletas y conservan `registered_by`, decisión y motivo cuando corresponde.
- Un comprobante monetario v2 (`finance_vouchers`) está ligado a una entrada y puede referenciarse por asignaciones a obligaciones. WU1 sólo crea el modelo e integridad local del par comprobante/obligación; las operaciones, autorización de ciclo y límite agregado de capacidad pertenecen a WU2.
- Cada evento del ledger exige actor, payload y un único objetivo. La base prohíbe actualizar o borrar eventos; por tanto, el historial durable es append-only.
- Los permisos específicos son `finances:register` para tesorero y secretario-tesorero activos de categoría `CLUB`, y `finances:approve` sólo para director activo de categoría `CLUB`. `finances:read` permanece. Estos grants todavía no sustituyen los guards de los endpoints legacy.
- El feature flag `finance.ledger_v2_writes_enabled` nace en `false`; el reseed no revierte una activación explícita del operador.
- El backfill manual e idempotente mantiene el flag apagado y transforma cada registro legacy activo válido en una entrada `approved` MXN con su evento `MIGRATED_LEGACY`. Antes de confirmar compara scope, categoría, importes, conteos, totales, campos y lineage; cualquier anomalía aborta la transacción completa.
- Las fotos de `finance_evidence_files` se conservan como adjuntos del flujo legacy y de doble lectura. No son comprobantes v2 ni crean capacidad de pago/asignación.

Fuera de alcance de WU1: API/DTOs v2, transacciones de aprobación, idempotencia de requests, asignaciones con capacidad agregada, lecturas compatibles v2, camporees, cuotas/cupos y seguros.

### Registro interno v2 (WU2a1, sin endpoint)

La rama de backend WU2a1 incorpora `FinanceLedgerService.registerEntry` como servicio transaccional interno; todavía no se registra en `FinancesModule`, no habilita el flag y no agrega ruta, DTO ni consumidor. Por eso los nueve endpoints legacy de arriba siguen siendo la única superficie HTTP vigente. Cuando un adaptador autorizado exponga el registro, debe conservar estos contratos de error del servicio:

| Código | HTTP | Condición |
| --- | --- | --- |
| `FINANCE_LEDGER_DISABLED` | 403 | `finance.ledger_v2_writes_enabled` no es `true`. |
| `GUARD_PERMISSION_DENIED` | 403 | El adaptador niega al actor el registro efectivo en club/sección; también se evalúa en replay. |
| `FINANCE_LEDGER_INPUT_INVALID` | 400 | Centavos, moneda ISO o fecha inválidos; también moneda inactiva. |
| `FINANCE_LEDGER_IDEMPOTENCY_REUSED` | 409 | La misma `Idempotency-Key` del actor tiene otro payload canónico. |
| `FINANCE_CATEGORY_NOT_FOUND` | 404 | La categoría solicitada no existe. |
| `FINANCE_CATEGORY_INACTIVE` | 400 | La categoría existe pero está inactiva. |
| `FINANCE_CATEGORY_TYPE_INVALID` | 400 | El tipo de categoría no coincide con `income` o `expense|payable`. |

Los replays con la misma llave y payload retornan el receipt persistido; aun así vuelven a pasar por la autorización del adaptador. No hay contrato HTTP v2 hasta que el wiring y su endpoint se publiquen explícitamente.

### Decisión interna v2 (WU2a2, sin endpoint)

La rama de backend WU2a2 incorpora `FinanceLedgerService.decideEntry` como servicio de decisión interno; permanece sin registro en `FinancesModule` y sin ruta, DTO, consumidor ni permiso HTTP v2. Solo un movimiento en `pending_approval` puede pasar a `approved` o `rejected`. Un rechazo exige motivo recortado de máximo 500 caracteres. Todo intento o replay evalúa la autorización efectiva de decisión antes del maker-checker; el registrador y el actor que decide deben ser usuarios distintos en `approve` y `reject`. Una auto-decisión falla cerrada antes de consultar el receipt de idempotencia o mutar. Contratos de error del servicio:

| Código | HTTP | Condición |
| --- | --- | --- |
| `FINANCE_LEDGER_DISABLED` | 403 | `finance.ledger_v2_writes_enabled` no es `true`. |
| `GUARD_PERMISSION_DENIED` | 403 | El adaptador niega la decisión efectiva del actor en club/sección; también en replay. |
| `FINANCE_LEDGER_SELF_DECISION_FORBIDDEN` | 403 | El actor intenta aprobar o rechazar un movimiento que él mismo registró. |
| `FINANCE_LEDGER_INPUT_INVALID` | 400 | Decisión inválida o motivo de rechazo mayor a 500 caracteres. |
| `FINANCE_LEDGER_REJECTION_REASON_REQUIRED` | 400 | Un `reject` llega sin motivo usable tras el trim. |
| `FINANCE_LEDGER_IDEMPOTENCY_REUSED` | 409 | La misma `Idempotency-Key` del actor tiene otro payload canónico. |
| `FINANCE_LEDGER_ENTRY_NOT_FOUND` | 404 | El movimiento solicitado no existe. |
| `FINANCE_LEDGER_STATUS_INVALID` | 409 | El movimiento ya no está en `pending_approval`. |

No hay contrato HTTP v2 de decisión hasta que el wiring y su endpoint se publiquen explícitamente.

## Requisitos funcionales

1. Solo roles de tesorero, director o `deputy_director` deben poder crear movimientos financieros
2. Cada movimiento debe registrar: monto, tipo (ingreso/egreso), categoria, descripcion, fecha
3. El sistema debe calcular y exponer un resumen financiero por club (balance, total ingresos, total egresos)
4. Los movimientos deben ser filtrables por ano y mes
5. Los movimientos deben poder desactivarse (soft delete) sin perder datos historicos
6. Las categorias financieras deben ser un catalogo compartido entre clubes
7. El panel admin debe permitir gestion y supervision financiera de los clubes
8. El resumen financiero debe actualizarse en tiempo real conforme se registran movimientos
9. Cada ingreso o egreso puede tener hasta 3 fotos de evidencia; las fotos no modifican saldos ni reabren periodos cerrados

## Decisiones de diseno

- **Autorizacion por rol de club**: La creacion de movimientos esta restringida a `director`, `deputy_director` y `treasurer` mediante `ClubRolesGuard`
- **Soft delete**: Los movimientos se desactivan; esto implica que el resumen financiero debe considerar solo registros activos
- **Evidencias separadas por dominio**: Las fotos de soporte financiero viven en `finance_evidence_files`, con FK a `finances` y al usuario que sube el archivo. Se almacenan en R2 bajo el alias `EVIDENCE_FILES` y se sirven con URLs firmadas de corta duracion.
- **Categorias compartidas**: Las categorias financieras son globales, no por club, permitiendo estandarizacion
- **Integridad de categoria**: El alta y la edicion de movimientos verifican que la categoria exista, este activa y tenga tipo `0` (ingreso) o `1` (egreso); el tipo del movimiento se deriva de esa categoria
- **Resumen acumulado por ano eclesiastico**: El endpoint `summary` con `year` + `month` calcula el saldo arrastrado del ano eclesiastico hasta el mes seleccionado; los meses cerrados usan el snapshot de `finance_period_closings` y los meses abiertos se calculan desde movimientos activos
- **Doble superficie de lectura**: `GET /clubs/:clubId/finances` resuelve la vista mensual/anual del dashboard y `GET /clubs/:clubId/finances/transactions` cubre busqueda, filtros avanzados y paginacion server-side
- **Filtrado temporal**: Los filtros por ano/mes se aplican a nivel de query, no como entidades separadas
- **Rollout de ledger v2**: La migración es aditiva y conserva `finances` como lectura legacy. El backfill no se ejecuta automáticamente por Prisma; se opera manualmente sólo con escrituras v2 deshabilitadas y con paridad validada antes de `COMMIT`.

## Gaps y pendientes

- **Sin reportes avanzados**: No hay endpoints para reportes por categoria, tendencias temporales o comparativas entre periodos
- **Sin exportacion**: No hay funcionalidad para exportar movimientos a PDF o Excel
- **Sin auditoría avanzada para movimientos legacy**: Los movimientos de `finances` registran `created_by` (UUID, NOT NULL) y `modified_by_id` (UUID, nullable, FK a users), pero no tienen audit trail de acciones en formato log. Esto no aplica a `finance_ledger_events` del ledger v2: sus eventos requieren actor y son append-only; WU1 todavía no expone operaciones v2 que los generen.
- **Sin presupuesto**: No hay modelo para definir presupuestos anuales por categoria y comparar ejecucion vs presupuesto
- **Ledger v2 sin API aún**: WU1 no habilita el feature flag ni expone endpoints. WU2 entregará las escrituras seguras; WU3, las lecturas y el contrato compatible.

## Estado de implementacion

- **Prioridad**: La superficie legacy está implementada en backend, admin y app. El ledger v2 tiene WU1 de infraestructura entregado; WU2–WU5 permanecen pendientes.
