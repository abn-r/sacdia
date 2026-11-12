# Finanzas

**Estado**: IMPLEMENTADO

## Descripcion de dominio

El modulo de finanzas gestiona los movimientos economicos de cada club de Conquistadores, Aventureros o Guias Mayores. Los clubes manejan fondos provenientes de cuotas de miembros, ventas de alimentos, donaciones, patrocinios y actividades de recaudacion. Estos ingresos se utilizan para cubrir uniformes, materiales, campamentos, camporees, transporte y actividades formativas.

Cada club tiene su propia contabilidad independiente, con registro de ingresos y egresos categorizados. El sistema ofrece un resumen financiero por club que permite a la directiva (particularmente al tesorero) tener visibilidad del balance general. Los movimientos financieros son filtrables por ano y mes, lo que facilita el cierre contable por periodo eclesiastico.

El campo `balance` del resumen es el **saldo acumulado de toda la historia** del club (o de la seccion) hasta el fin del periodo pedido: el dinero en caja no se reinicia cada ano eclesiastico. Los ingresos y egresos se informan aparte, por periodo (mes, ano o todo). Todo se calcula en tiempo real con los movimientos activos; las fotos de cierre (`finance_period_closings`) ya no se usan para sumar. Decision 2026-11-11.

Las categorias financieras son un catalogo compartido que permite clasificar los movimientos de forma estandar entre clubes. Esto posibilita eventuales reportes consolidados a nivel de campo local o union.

## Que existe (verificado contra codigo)

### Backend (FinancesModule)
- **Controller**: `src/finances/finances.controller.ts`
- **Service**: `src/finances/finances.service.ts`
- **Guards**: JwtAuthGuard, PermissionsGuard, ClubRolesGuard
- **Servicios**: `FinancesService` (movimientos, categorias, resumen), `FinanceAggregationService` (unica fuente de totales), `FinanceReportsService` (por categoria, Excel, vista consolidada), `FinancePeriodService` (cierre mensual y reglas de mes cerrado), `FinanceReminderService` (recordatorio de fin de mes)
- **12 endpoints**:
  - `GET /api/v1/finances/categories` — Listar categorias financieras
  - `GET /api/v1/clubs/:clubId/finances/transactions` — Listado paginado de transacciones con `page`, `limit`, `type`, `search`, `startDate`, `endDate`, `sortBy`, `sortOrder`
  - `GET /api/v1/clubs/:clubId/finances` — Listar movimientos financieros del club, paginado (`page`, `limit` hasta 100), con filtros `year`, `month`, `clubTypeId`, `categoryId` y `club_section_id` (seccion exacta; un miembro con alcance de seccion que pide otra recibe 403, una seccion de otro club devuelve lista vacia)
  - `GET /api/v1/clubs/:clubId/finances/summary` — Resumen financiero del club (ver «Contrato del resumen»)
  - `GET /api/v1/clubs/:clubId/finances/by-category` — Totales por categoria
  - `GET /api/v1/clubs/:clubId/finances/monthly` — Serie mensual de ingresos, egresos y saldo
  - `GET /api/v1/clubs/:clubId/finances/export` — Descarga Excel o PDF
  - `GET /api/v1/finances/overview` — Vista consolidada por club para campo local, union y division
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
- `finances` — Movimientos financieros (ingresos/egresos por club). `active` ahora es `true` por defecto (migracion `20261111140000_finances_active_default_true`); antes era `false` y solo el servicio lo corregia al crear
- `finance_period_closings` — Foto historica de cada mes cerrado por club (la escribe el cron del dia 1). Ya no se usa para calcular totales; sigue sirviendo para saber si un mes esta cerrado y para el puntaje del ranking
- `finance_evidence_files` — Fotos de evidencia asociadas a movimientos financieros
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
9. Cada ingreso o egreso puede tener hasta 3 fotos de evidencia; las fotos no modifican saldos ni reabren periodos cerrados

## Decisiones de diseno

- **Autorizacion por rol de club**: La creacion de movimientos esta restringida a `director`, `deputy_director` y `treasurer` mediante `ClubRolesGuard`
- **Soft delete**: Los movimientos se desactivan; esto implica que el resumen financiero debe considerar solo registros activos
- **Evidencias separadas por dominio**: Las fotos de soporte financiero viven en `finance_evidence_files`, con FK a `finances` y al usuario que sube el archivo. Se almacenan en R2 bajo el alias `EVIDENCE_FILES` y se sirven con URLs firmadas de corta duracion.
- **Categorias compartidas**: Las categorias financieras son globales, no por club, permitiendo estandarizacion
- **Resumen con saldo acumulado de toda la historia**: reemplaza al saldo arrastrado del ano eclesiastico (ver F1 y F2 abajo)
- **Doble superficie de lectura**: `GET /clubs/:clubId/finances` resuelve la vista mensual/anual del dashboard y `GET /clubs/:clubId/finances/transactions` cubre busqueda, filtros avanzados y paginacion server-side
- **Filtrado temporal**: Los filtros por ano/mes se aplican a nivel de query, no como entidades separadas
- **Ranking anual mide movimientos antes del cierre**: el cierre mensual es automático (cron UTC día 1, 00:00), así que `finance_compliance` ya no puntúa la fecha del cierre. Un mes suma si el club tiene cierre y al menos un movimiento activo, de una sección del club, creado antes de `closed_at`. Puntaje = meses que suman / 12. Los movimientos creados después del cierre (solo admin) no cuentan. El desglose del ranking expone `months_with_movements`, `months_total` y `missed_months` (meses cerrados sin movimiento previo); `deadline_day` desaparece y `ranking.finance_closing_deadline_day` ya no se usa.

## Decisiones 2026-11-11

- **F1 Saldo = acumulado de toda la historia.** El dinero en caja no se reinicia con el ano eclesiastico. `balance` = suma de todos los ingresos menos todos los egresos activos hasta el fin del periodo. Los ingresos y egresos del periodo se informan por separado.
- **F2 Una sola agregacion.** `FinanceAggregationService` calcula en vivo, desde movimientos activos, `income`, `expenses`, `net`, `movements` y `balance` para un club completo o una seccion. Lo usan el resumen del club, el informe mensual, el trimestral y el anual, asi que siempre coinciden. Las fotos de cierre ya no entran en los totales. Informes: `finances.balance` sigue siendo el neto del periodo y se agrego `finances.total_balance` (saldo acumulado al fin del periodo) en trimestral y anual; el mensual ya lo tenia.
- **F3 Mes cerrado exige motivo.** Crear, editar o eliminar un movimiento de un mes cerrado solo lo puede hacer admin o super-admin, y debe llevar `post_closing_note` (5 a 500 caracteres, sin espacios al inicio y al final). Sin nota: `400 FINANCE_CLOSED_PERIOD_NOTE_REQUIRED`; sin rol: `403 FINANCE_PERIOD_CLOSED`. Eliminar recibe la nota en el body `{ "reason": "..." }` o en `?reason=` (el body gana). Los movimientos viejos sin seccion no se pueden ligar a un club, asi que se tratan como cerrados: solo admin y con nota. El resumen del mes pedido y cada movimiento (listado y detalle) traen `period_closed`.
- **F4 Sin historial de cierres.** Por ahora no se guarda un historial de cambios por cierre ni se reabre un mes. Cada modificacion posterior al cierre guarda su nota en el propio movimiento (`post_closing_note`); el borrado es logico (`active = false`). Un historial dedicado se evaluara si hace falta.
- **F5 Exportar a Excel o PDF.** `GET /clubs/:clubId/finances/export?year=&month=&club_section_id=&format=xlsx|pdf`; sin `month` exporta el ano completo; `format` es opcional (por defecto `xlsx`, otro valor responde 400). Archivo `finanzas-<club>-<periodo>.xlsx|pdf` (nombre ASCII). Con `format=pdf` el PDF carta («Reporte de finanzas») sigue el diseno aprobado: encabezado de marca (logos de SACDIA y de la IASD), periodo con su rango de fechas, recuadro con club, seccion o «Todas las secciones», Campo local y fecha de generacion (hora de Ciudad de Mexico), etiqueta «Mes cerrado el <fecha>» si aplica, resumen (saldo acumulado al fin del periodo, ingresos, egresos, neto y saldo anterior), «Por categoria» en dos columnas con barras y porcentaje, tabla «Movimientos» (empieza en la primera pagina, repite encabezado con «Continuacion» y muestra la nota de cierre bajo la descripcion), «Responsables» (director(a) y tesorero(a) vigentes por seccion; «—» si esta vacante), nota «Reporte generado por <nombre> (<rol>)» al pie de la ultima pagina y pie con logo y «Pagina X de Y»; si falta un logo se genera sin el; ambos formatos salen de la misma consulta. Hoja «Movimientos» (Fecha, Seccion, Tipo, Categoria, Descripcion, Monto, Registro, Evidencias, Nota de cierre) y hoja «Resumen» (ingresos, egresos, neto, saldo acumulado, movimientos). Maximo 20 000 filas. Mismo permiso y alcance que el listado.
- **F6 Por categoria.** `GET /clubs/:clubId/finances/by-category?year=&month=&club_section_id=` devuelve ingresos y egresos por categoria, de mayor a menor, con el nombre traducido al idioma de la peticion.
- **F6b Serie mensual.** `GET /clubs/:clubId/finances/monthly?from=YYYY-MM&to=YYYY-MM&club_section_id=` devuelve `{ club_id, club_section_id, from, to, items }` con un item por mes `{ year, month, income, expenses, net, balance }` (pesos enteros; `balance` = saldo acumulado de todos los tiempos al cierre del mes; los meses sin movimientos van en cero para que la grafica sea continua). `to` por defecto es el mes actual; sin `from` arranca en el mes del primer movimiento activo (sin movimientos: `items: []`, `from`/`to` nulos). Maximo 120 meses y `from <= to`, si no `400 VALIDATION_FAILED`. Misma resolucion de club/seccion y mismo permiso que `by-category`; una sola consulta SQL (`FinanceAggregationService.aggregateMonthlySeries`) mas otra para el primer movimiento. Lo usa la grafica de la app para 3M, 6M, 1A y Todo.
- **F7 Vista consolidada.** `GET /finances/overview?local_field_id=&year=&month=&page=&limit=`. Permiso `finances:read` sobre recurso `global`; el servicio exige un rol global (no el rol base) que lleve `finances:read` y filtra los clubes por el territorio del rol (campo local, union, division; admin segun su territorio; super-admin ve todo). Un tesorero de club no tiene rol global y recibe 403. `local_field_id` se valida contra el territorio. Por club: ingresos, egresos, neto, saldo acumulado, movimientos, meses sin movimientos (meses cerrados del ano sin movimiento previo al cierre, misma regla del ranking via `FinanceScoreService.getMonthsStatus`) y fecha del ultimo movimiento. Los totales cubren todos los clubes del territorio; la lista pagina de 100 en 100.
- **F8 Pagos aislados de finanzas.** Los pagos de cuota anual, camporee y seguros siguen en sus propios modulos y no generan movimientos en finanzas del club. Si el club quiere reflejarlos, el tesorero los registra a mano.
- **F9 Sin presupuesto.** No se agrega presupuesto por categoria ni por ano en esta revision.
- **F10 Recordatorio de fin de mes.** El dia 25 a las 10:00 (America/Mexico_City) el job `finance-month-end-reminder` avisa (push y bandeja, fuente `finances:reminder`, categoria recordatorios) al tesorero, secretario-tesorero y director de cada seccion activa sin movimientos activos del mes en curso. Titulo «Registra tus movimientos del mes»; cuerpo «{Club} ({seccion}) aun no tiene movimientos de {mes}. Se cierra automaticamente el dia 1.». Datos de la notificacion: `{ type: 'finances_reminder', club_section_id, year, month }` (todos texto). No repite: si la seccion ya recibio el aviso este mes (registro en `notification_logs`), se omite. Respeta las preferencias de notificacion del usuario. Ver `docs/features/cron-automation.md`.

### Contrato del resumen (`GET /clubs/:clubId/finances/summary`)

Query: `year`, `month`, `club_section_id` (opcional; un miembro de seccion solo puede pedir la suya, otra da 403; una seccion de otro club da 404).

| Campo | Significado |
|---|---|
| `total_income`, `total_expense`, `net`, `movement_count` | Solo el periodo pedido: el mes si hay `year`+`month`, el ano si hay solo `year`, todo si no hay nada. **Cambio**: con `year`+`month` antes eran acumulados del ano eclesiastico |
| `balance` | Saldo acumulado de toda la historia hasta el fin del periodo. **Cambio**: antes era el acumulado del ano eclesiastico |
| `year_income`, `year_expenses` | Acumulado del ano eclesiastico hasta el mes pedido (lo que antes eran `total_*`). Sin `year`+`month` igualan a los totales del periodo |
| `period_closed` | `true` si el mes pedido esta cerrado; `null` si no se pidio un mes |

## Gaps y pendientes

- **Sin cierre manual**: el cierre mensual es solo automático (decisión 2026-11-11); no hay endpoint para que el club cierre un mes
- **Sin tendencias ni comparativas entre periodos** (la exportacion a Excel y PDF y el desglose por categoria ya existen)
- **Vista consolidada sin cache**: `GET /finances/overview` calcula en cada llamada (una consulta agrupada y una consulta por club de la pagina para los meses sin movimientos)
- **Movimientos sin seccion**: los viejos sin `club_section_id` no entran en ningun total de club; hay que ligarlos a una seccion con un script de datos (hoy solo admin los puede tocar, con nota)
- **Recordatorio sin interruptor**: el aviso del dia 25 no tiene un parametro de sistema para apagarlo; solo las preferencias de cada usuario
- **Sin auditoría avanzada**: los movimientos registran `created_by` (UUID, NOT NULL) y `modified_by_id` (UUID, nullable, FK a users); no hay audit trail de acciones en formato log
- **Sin presupuesto**: no hay modelo para definir presupuestos anuales por categoría y comparar ejecución vs presupuesto

## Estado de implementacion

- **Prioridad**: Funcional — backend, admin y app implementados; los gaps abiertos están en la sección anterior
