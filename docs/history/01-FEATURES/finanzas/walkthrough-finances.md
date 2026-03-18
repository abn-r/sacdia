# Walkthrough: Finances (Finanzas de Club)

**Módulo**: Finances
**Versión API**: 2.2
**Fecha**: 4 de febrero de 2026

---

## 📋 Descripción General

El módulo de **Finances** proporciona un sistema completo de gestión financiera para clubes. Este módulo permite:

- Registro de ingresos y egresos
- Categorización de transacciones
- Tracking por año eclesiástico
- Generación de balances y resúmenes
- Control de acceso estricto (Tesorero, Director)
- Reportes mensuales y anuales
- Auditoría de movimientos

**Características principales**:
- ✅ CRUD completo de movimientos financieros
- ✅ Sistema de categorías (ingresos/egresos)
- ✅ Cálculo automático de balance
- ✅ Filtros por fecha, categoría, tipo
- ✅ Resúmenes financieros
- ✅ Separación por instancia de club
- ✅ Soft delete para auditoría

---

## 🎯 Flujo Completo

### 1. Listar Categorías Financieras

Primero, consultar las categorías disponibles para clasificar transacciones.

**Endpoint**: `GET /api/v1/finances/categories`
**Autenticación**: Requerida

**Query Parameters**:
- `type`: Tipo de categoría (0 = Ingreso, 1 = Egreso)

**Request**:

```bash
curl -X GET "http://localhost:3000/api/v1/finances/categories?type=0" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": [
    {
      "category_id": 1,
      "name": "Cuotas de Membresía",
      "description": "Cuotas mensuales o anuales de los miembros",
      "type": 0,
      "active": true
    },
    {
      "category_id": 2,
      "name": "Ofrendas",
      "description": "Ofrendas voluntarias",
      "type": 0,
      "active": true
    },
    {
      "category_id": 3,
      "name": "Donaciones",
      "description": "Donaciones de benefactores",
      "type": 0,
      "active": true
    },
    {
      "category_id": 4,
      "name": "Venta de Uniformes",
      "description": "Ingresos por venta de uniformes y materiales",
      "type": 0,
      "active": true
    }
  ]
}
```

**Categorías de Egresos (type=1)**:

```bash
curl -X GET "http://localhost:3000/api/v1/finances/categories?type=1" \
  -H "Authorization: Bearer ${TOKEN}"
```

```json
{
  "status": "success",
  "data": [
    {
      "category_id": 10,
      "name": "Material Didáctico",
      "description": "Compra de manuales, libros, material para clases",
      "type": 1,
      "active": true
    },
    {
      "category_id": 11,
      "name": "Equipo de Campamento",
      "description": "Carpas, sleeping bags, estufas",
      "type": 1,
      "active": true
    },
    {
      "category_id": 12,
      "name": "Uniformes",
      "description": "Compra de uniformes para inventario",
      "type": 1,
      "active": true
    },
    {
      "category_id": 13,
      "name": "Transporte",
      "description": "Gastos de transporte para actividades",
      "type": 1,
      "active": true
    },
    {
      "category_id": 14,
      "name": "Mantenimiento",
      "description": "Reparación de equipo, mantenimiento de instalaciones",
      "type": 1,
      "active": true
    }
  ]
}
```

---

### 2. Listar Movimientos Financieros de un Club

**Endpoint**: `GET /api/v1/clubs/:clubId/finances`
**Autenticación**: Requerida
**Roles**: Director, Subdirector, Tesorero

**Query Parameters**:
- `year`: Año (YYYY)
- `month`: Mes (1-12)
- `clubTypeId`: Tipo de club (1=ADV, 2=PATHF, 3=MG)
- `categoryId`: Filtrar por categoría
- `type`: Tipo de movimiento (0=Ingreso, 1=Egreso)
- `page`: Número de página
- `limit`: Items por página

**Request**:

```bash
curl -X GET "http://localhost:3000/api/v1/clubs/5/finances?year=2026&month=2&clubTypeId=2" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": [
    {
      "finance_id": 1,
      "description": "Cuotas de febrero 2026 - 30 miembros",
      "amount": 3000.00,
      "type": 0,
      "transaction_date": "2026-02-01T00:00:00.000Z",
      "category": {
        "category_id": 1,
        "name": "Cuotas de Membresía",
        "type": 0
      },
      "club_pathf_id": 5,
      "ecclesiastical_year_id": 5,
      "receipt_number": "R-2026-001",
      "notes": "Cobro mensual de cuotas",
      "active": true,
      "created_at": "2026-02-01T10:00:00.000Z",
      "created_by": {
        "name": "Carlos",
        "paternal_last_name": "Ramírez"
      }
    },
    {
      "finance_id": 2,
      "description": "Compra de manuales de clases",
      "amount": 1200.00,
      "type": 1,
      "transaction_date": "2026-02-05T00:00:00.000Z",
      "category": {
        "category_id": 10,
        "name": "Material Didáctico",
        "type": 1
      },
      "club_pathf_id": 5,
      "ecclesiastical_year_id": 5,
      "receipt_number": "E-2026-001",
      "notes": "50 manuales para nuevos miembros",
      "active": true,
      "created_at": "2026-02-05T14:30:00.000Z"
    }
  ],
  "meta": {
    "total": 15,
    "page": 1,
    "limit": 20,
    "totalPages": 1,
    "summary": {
      "total_income": 3500.00,
      "total_expenses": 1800.00,
      "balance": 1700.00
    }
  }
}
```

---

### 3. Registrar Ingreso

**Endpoint**: `POST /api/v1/clubs/:clubId/finances`
**Autenticación**: Requerida
**Roles**: Director, Subdirector, Tesorero

**Request**:

```bash
curl -X POST http://localhost:3000/api/v1/clubs/5/finances \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Cuotas de febrero 2026 - 30 miembros",
    "amount": 3000.00,
    "type": 0,
    "transaction_date": "2026-02-01T00:00:00.000Z",
    "finance_category_id": 1,
    "club_pathf_id": 5,
    "ecclesiastical_year_id": 5,
    "receipt_number": "R-2026-001",
    "notes": "Cobro mensual de cuotas"
  }'
```

**Response** (201 Created):

```json
{
  "status": "success",
  "data": {
    "finance_id": 1,
    "description": "Cuotas de febrero 2026 - 30 miembros",
    "amount": 3000.00,
    "type": 0,
    "transaction_date": "2026-02-01T00:00:00.000Z",
    "finance_category_id": 1,
    "club_adv_id": null,
    "club_pathf_id": 5,
    "club_mg_id": null,
    "ecclesiastical_year_id": 5,
    "receipt_number": "R-2026-001",
    "notes": "Cobro mensual de cuotas",
    "active": true,
    "created_at": "2026-02-04T18:00:00.000Z",
    "created_by_user_id": "uuid-treasurer",
    "updated_at": "2026-02-04T18:00:00.000Z"
  }
}
```

**Validaciones**:
- ✅ Descripción requerida
- ✅ Monto debe ser > 0
- ✅ Tipo requerido (0 = Ingreso, 1 = Egreso)
- ✅ Fecha de transacción requerida
- ✅ Categoría debe existir y estar activa
- ✅ Debe especificar exactamente UNA instancia de club
- ✅ Usuario debe tener rol de Tesorero, Director o Subdirector

---

### 4. Registrar Egreso

**Request**:

```bash
curl -X POST http://localhost:3000/api/v1/clubs/5/finances \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Compra de carpas para campamento",
    "amount": 5000.00,
    "type": 1,
    "transaction_date": "2026-02-10T00:00:00.000Z",
    "finance_category_id": 11,
    "club_pathf_id": 5,
    "ecclesiastical_year_id": 5,
    "receipt_number": "F-1234",
    "notes": "Compradas 5 carpas marca Coleman"
  }'
```

**Response** (201 Created):

```json
{
  "status": "success",
  "data": {
    "finance_id": 10,
    "description": "Compra de carpas para campamento",
    "amount": 5000.00,
    "type": 1,
    "transaction_date": "2026-02-10T00:00:00.000Z",
    "finance_category_id": 11,
    "club_pathf_id": 5,
    "ecclesiastical_year_id": 5,
    "receipt_number": "F-1234",
    "notes": "Compradas 5 carpas marca Coleman",
    "active": true,
    "created_at": "2026-02-10T16:00:00.000Z"
  }
}
```

---

### 5. Obtener Resumen Financiero

**Endpoint**: `GET /api/v1/clubs/:clubId/finances/summary`
**Autenticación**: Requerida
**Roles**: Director, Subdirector, Tesorero

**Query Parameters**:
- `year`: Año (default: año actual)
- `month`: Mes (opcional, si no se especifica = resumen anual)
- `clubTypeId`: Tipo de club

**Request (Resumen mensual)**:

```bash
curl -X GET "http://localhost:3000/api/v1/clubs/5/finances/summary?year=2026&month=2&clubTypeId=2" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": {
    "period": {
      "year": 2026,
      "month": 2,
      "club_pathf_id": 5
    },
    "summary": {
      "total_income": 8500.00,
      "total_expenses": 6200.00,
      "balance": 2300.00,
      "transaction_count": 15
    },
    "income_by_category": [
      {
        "category_id": 1,
        "category_name": "Cuotas de Membresía",
        "amount": 6000.00,
        "percentage": 70.59
      },
      {
        "category_id": 2,
        "category_name": "Ofrendas",
        "amount": 1500.00,
        "percentage": 17.65
      },
      {
        "category_id": 3,
        "category_name": "Donaciones",
        "amount": 1000.00,
        "percentage": 11.76
      }
    ],
    "expenses_by_category": [
      {
        "category_id": 11,
        "category_name": "Equipo de Campamento",
        "amount": 3000.00,
        "percentage": 48.39
      },
      {
        "category_id": 10,
        "category_name": "Material Didáctico",
        "amount": 2000.00,
        "percentage": 32.26
      },
      {
        "category_id": 13,
        "category_name": "Transporte",
        "amount": 1200.00,
        "percentage": 19.35
      }
    ],
    "monthly_trend": [
      { "month": 1, "income": 7000.00, "expenses": 5500.00, "balance": 1500.00 },
      { "month": 2, "income": 8500.00, "expenses": 6200.00, "balance": 2300.00 }
    ]
  }
}
```

**Request (Resumen anual)**:

```bash
curl -X GET "http://localhost:3000/api/v1/clubs/5/finances/summary?year=2026&clubTypeId=2" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": {
    "period": {
      "year": 2026,
      "club_pathf_id": 5
    },
    "summary": {
      "total_income": 45000.00,
      "total_expenses": 38000.00,
      "balance": 7000.00,
      "transaction_count": 98
    },
    "income_by_category": [...],
    "expenses_by_category": [...],
    "monthly_breakdown": [
      { "month": 1, "income": 7000.00, "expenses": 5500.00, "balance": 1500.00 },
      { "month": 2, "income": 8500.00, "expenses": 6200.00, "balance": 2300.00 },
      // ... meses 3-12
    ]
  }
}
```

---

### 6. Ver Detalles de un Movimiento

**Endpoint**: `GET /api/v1/finances/:financeId`
**Autenticación**: Requerida
**Roles**: Director, Subdirector, Tesorero

**Request**:

```bash
curl -X GET http://localhost:3000/api/v1/finances/1 \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": {
    "finance_id": 1,
    "description": "Cuotas de febrero 2026 - 30 miembros",
    "amount": 3000.00,
    "type": 0,
    "transaction_date": "2026-02-01T00:00:00.000Z",
    "category": {
      "category_id": 1,
      "name": "Cuotas de Membresía",
      "description": "Cuotas mensuales o anuales de los miembros",
      "type": 0
    },
    "club_instance": {
      "club_pathf_id": 5,
      "club_name": "Club Conquistadores Emanuel"
    },
    "ecclesiastical_year": {
      "year_id": 5,
      "year": 2026,
      "start_date": "2026-01-01",
      "end_date": "2026-12-31"
    },
    "receipt_number": "R-2026-001",
    "notes": "Cobro mensual de cuotas",
    "active": true,
    "created_at": "2026-02-01T10:00:00.000Z",
    "created_by": {
      "user_id": "uuid-treasurer",
      "name": "Carlos",
      "paternal_last_name": "Ramírez",
      "maternal_last_name": "López"
    },
    "updated_at": "2026-02-01T10:00:00.000Z"
  }
}
```

---

### 7. Actualizar Movimiento Financiero

**Endpoint**: `PATCH /api/v1/finances/:financeId`
**Autenticación**: Requerida
**Roles**: Director, Tesorero

**Request**:

```bash
curl -X PATCH http://localhost:3000/api/v1/finances/1 \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 3200.00,
    "notes": "Cobro mensual de cuotas. Actualizado: 2 miembros pagaron cuotas atrasadas"
  }'
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": {
    "finance_id": 1,
    "description": "Cuotas de febrero 2026 - 30 miembros",
    "amount": 3200.00,
    "notes": "Cobro mensual de cuotas. Actualizado: 2 miembros pagaron cuotas atrasadas",
    "updated_at": "2026-02-04T19:00:00.000Z"
  }
}
```

**Campos Actualizables**:
- description
- amount
- transaction_date
- finance_category_id
- receipt_number
- notes

**Restricción**: Solo se puede actualizar dentro de los primeros 30 días de creación (configurable).

---

### 8. Eliminar Movimiento (Soft Delete)

**Endpoint**: `DELETE /api/v1/finances/:financeId`
**Autenticación**: Requerida
**Roles**: Director únicamente

**Request**:

```bash
curl -X DELETE http://localhost:3000/api/v1/finances/1 \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "message": "Finance record deactivated successfully",
  "data": {
    "finance_id": 1,
    "active": false,
    "deactivated_at": "2026-02-04T19:30:00.000Z"
  }
}
```

**Nota**: El registro NO se elimina de la base de datos. Solo se marca como `active: false` para mantener auditoría.

---

## 📚 Casos de Uso Detallados

### Caso de Uso 1: Cobro Mensual de Cuotas

**Escenario**: El tesorero cobra las cuotas mensuales de los miembros.

**Flujo**:

1. **Tesorero registra el ingreso**:
   ```bash
   POST /api/v1/clubs/5/finances
   Body: {
     "description": "Cuotas de febrero 2026",
     "amount": 3000.00,
     "type": 0,
     "transaction_date": "2026-02-01",
     "finance_category_id": 1,
     "club_pathf_id": 5,
     "ecclesiastical_year_id": 5,
     "receipt_number": "R-2026-001"
   }
   ```

2. **Verifica el balance actualizado**:
   ```bash
   GET /api/v1/clubs/5/finances/summary?year=2026&month=2
   # Response incluye: balance actualizado
   ```

3. **Exporta comprobante** (PDF/Excel) desde frontend con los datos del response.

---

### Caso de Uso 2: Compra de Equipo

**Escenario**: El club compra equipo de campamento.

**Flujo**:

1. **Tesorero verifica balance disponible**:
   ```bash
   GET /api/v1/clubs/5/finances/summary?year=2026
   # balance: $7,000.00
   ```

2. **Registra el egreso** después de la compra:
   ```bash
   POST /api/v1/clubs/5/finances
   Body: {
     "description": "Compra de 5 carpas Coleman",
     "amount": 5000.00,
     "type": 1,
     "transaction_date": "2026-02-10",
     "finance_category_id": 11,
     "club_pathf_id": 5,
     "ecclesiastical_year_id": 5,
     "receipt_number": "F-5678",
     "notes": "Factura #5678 de Tienda Outdoor"
   }
   ```

3. **Actualiza inventario** (módulo de Inventory):
   ```bash
   POST /api/v1/clubs/5/inventory
   Body: {
     "name": "Carpas Coleman 4 personas",
     "amount": 5,
     "inventory_category_id": 1,
     "club_pathf_id": 5
   }
   ```

4. **Verifica nuevo balance**:
   ```bash
   GET /api/v1/clubs/5/finances/summary
   # balance actualizado: $2,000.00
   ```

---

### Caso de Uso 3: Reporte de Tesorería Mensual

**Escenario**: El tesorero debe presentar reporte mensual en junta directiva.

**Flujo**:

1. **Obtener resumen del mes**:
   ```bash
   GET /api/v1/clubs/5/finances/summary?year=2026&month=2&clubTypeId=2
   ```

2. **Obtener lista detallada de movimientos**:
   ```bash
   GET /api/v1/clubs/5/finances?year=2026&month=2&clubTypeId=2
   ```

3. **Frontend genera reporte** con:
   - Balance inicial
   - Total de ingresos por categoría
   - Total de egresos por categoría
   - Balance final
   - Gráficos de pastel (ingresos/egresos)
   - Lista detallada de transacciones

4. **Exportar a PDF o Excel** para la junta.

---

### Caso de Uso 4: Auditoría Anual

**Escenario**: Auditoría de fin de año para verificar movimientos.

**Flujo**:

1. **Obtener resumen anual**:
   ```bash
   GET /api/v1/clubs/5/finances/summary?year=2026&clubTypeId=2
   ```

2. **Verificar todos los movimientos** mes por mes:
   ```bash
   GET /api/v1/clubs/5/finances?year=2026&month=1&clubTypeId=2
   GET /api/v1/clubs/5/finances?year=2026&month=2&clubTypeId=2
   # ... meses 3-12
   ```

3. **Verificar movimientos desactivados** (soft deleted):
   ```bash
   GET /api/v1/clubs/5/finances?year=2026&includeInactive=true
   # Incluye registros con active: false
   ```

4. **Generar informe completo**:
   - Total de ingresos por categoría (anual)
   - Total de egresos por categoría (anual)
   - Balance mensual
   - Tendencias de gasto
   - Comparativa con año anterior

---

## ⚠️ Validaciones y Errores Comunes

### Error 1: Monto negativo o cero

**Código**: 400 Bad Request

**Mensaje**: `"Amount must be greater than 0"`

**Causa**: Intentar registrar movimiento con `amount: 0` o `amount: -100`.

**Solución**:
```json
// ❌ Incorrecto
{ "amount": -500 }

// ✅ Correcto
{ "amount": 500.00 }
```

---

### Error 2: Categoría inválida para el tipo

**Código**: 400 Bad Request

**Mensaje**: `"Category type doesn't match transaction type"`

**Causa**: Intentar usar categoría de "Ingreso" (type=0) para un egreso (type=1) o viceversa.

**Solución**:
- Verificar que `category.type` coincida con `transaction.type`
- Listar categorías filtradas por tipo antes de crear movimiento

---

### Error 3: Usuario sin permisos

**Código**: 403 Forbidden

**Mensaje**: `"Insufficient permissions. Required roles: director, subdirector, or treasurer"`

**Causa**: Usuario con rol de "member", "counselor" o "secretary" intenta crear/editar movimientos.

**Solución**:
- Solo Director, Subdirector y Tesorero pueden gestionar finanzas
- Otros roles pueden VER reportes (según configuración del club)

---

### Error 4: Fecha de transacción en el futuro

**Código**: 400 Bad Request

**Mensaje**: `"Transaction date cannot be in the future"`

**Causa**: Intentar registrar movimiento con fecha posterior a hoy.

**Solución**:
- Validar fechas en frontend
- Usar fecha actual por defecto
- Permitir fechas pasadas para registro histórico

---

### Error 5: Intento de eliminar movimiento antiguo

**Código**: 403 Forbidden

**Mensaje**: `"Cannot delete transaction older than 30 days"`

**Causa**: Intentar eliminar movimiento creado hace más de 30 días.

**Solución**:
- Solo permitir eliminación dentro de ventana de tiempo
- Para movimientos antiguos, crear movimiento de ajuste (reversión)
- Director puede override esta restricción

---

## 🔧 Lógica de Backend

### Validación de Creación de Movimiento

```typescript
// finances.service.ts
async create(clubId: number, dto: CreateFinanceDto) {
  // 1. Validar que se especificó exactamente UNA instancia de club
  const instanceCount = [
    dto.club_adv_id,
    dto.club_pathf_id,
    dto.club_mg_id
  ].filter(id => id !== null && id !== undefined).length;

  if (instanceCount !== 1) {
    throw new BadRequestException('Must specify exactly one club instance');
  }

  // 2. Validar monto > 0
  if (dto.amount <= 0) {
    throw new BadRequestException('Amount must be greater than 0');
  }

  // 3. Validar que categoría existe y tipo coincide
  const category = await this.prisma.finance_categories.findUnique({
    where: { category_id: dto.finance_category_id, active: true }
  });

  if (!category) {
    throw new NotFoundException('Finance category not found');
  }

  if (category.type !== dto.type) {
    throw new BadRequestException('Category type doesn\'t match transaction type');
  }

  // 4. Validar fecha no esté en futuro
  if (new Date(dto.transaction_date) > new Date()) {
    throw new BadRequestException('Transaction date cannot be in the future');
  }

  // 5. Crear movimiento
  return await this.prisma.club_finances.create({
    data: {
      description: dto.description,
      amount: dto.amount,
      type: dto.type,
      transaction_date: dto.transaction_date,
      finance_category_id: dto.finance_category_id,
      club_adv_id: dto.club_adv_id,
      club_pathf_id: dto.club_pathf_id,
      club_mg_id: dto.club_mg_id,
      ecclesiastical_year_id: dto.ecclesiastical_year_id,
      receipt_number: dto.receipt_number,
      notes: dto.notes,
      active: true,
      created_by_user_id: userId
    },
    include: {
      finance_categories: true
    }
  });
}
```

### Generación de Resumen Financiero

```typescript
async getFinancialSummary(clubId: number, year: number, month?: number) {
  const whereClause = {
    club_pathf_id: clubId, // O club_adv_id, club_mg_id
    active: true,
    transaction_date: {
      gte: month
        ? new Date(year, month - 1, 1)
        : new Date(year, 0, 1),
      lt: month
        ? new Date(year, month, 1)
        : new Date(year + 1, 0, 1)
    }
  };

  // Obtener todos los movimientos
  const transactions = await this.prisma.club_finances.findMany({
    where: whereClause,
    include: {
      finance_categories: true
    }
  });

  // Separar ingresos y egresos
  const income = transactions.filter(t => t.type === 0);
  const expenses = transactions.filter(t => t.type === 1);

  // Calcular totales
  const totalIncome = income.reduce((sum, t) => sum + Number(t.amount), 0);
  const totalExpenses = expenses.reduce((sum, t) => sum + Number(t.amount), 0);
  const balance = totalIncome - totalExpenses;

  // Agrupar por categoría
  const incomeByCategory = this.groupByCategory(income);
  const expensesByCategory = this.groupByCategory(expenses);

  return {
    period: { year, month, club_pathf_id: clubId },
    summary: {
      total_income: totalIncome,
      total_expenses: totalExpenses,
      balance: balance,
      transaction_count: transactions.length
    },
    income_by_category: incomeByCategory,
    expenses_by_category: expensesByCategory,
    monthly_trend: month ? null : await this.getMonthlyTrend(clubId, year)
  };
}

private groupByCategory(transactions: any[]) {
  const grouped = transactions.reduce((acc, t) => {
    const catId = t.finance_category_id;
    if (!acc[catId]) {
      acc[catId] = {
        category_id: catId,
        category_name: t.finance_categories.name,
        amount: 0
      };
    }
    acc[catId].amount += Number(t.amount);
    return acc;
  }, {});

  // Calcular porcentajes
  const total = Object.values(grouped).reduce((sum: number, g: any) => sum + g.amount, 0);

  return Object.values(grouped).map((g: any) => ({
    ...g,
    percentage: ((g.amount / total) * 100).toFixed(2)
  }));
}
```

---

## 📊 Schema de Base de Datos (Prisma)

### Tabla: club_finances

```prisma
model club_finances {
  finance_id             Int       @id @default(autoincrement())
  description            String    @db.VarChar(255)
  amount                 Decimal   @db.Decimal(10,2)
  type                   Int       // 0 = Ingreso, 1 = Egreso
  transaction_date       DateTime
  finance_category_id    Int

  // Club instance (solo UNA con valor)
  club_adv_id            Int?
  club_pathf_id          Int?
  club_mg_id             Int?

  ecclesiastical_year_id Int
  receipt_number         String?   @db.VarChar(50)
  notes                  String?   @db.Text

  active                 Boolean   @default(true)
  created_by_user_id     String    @db.Uuid
  created_at             DateTime  @default(now())
  updated_at             DateTime  @updatedAt

  // Relations
  finance_categories     finance_categories      @relation(fields: [finance_category_id], references: [category_id])
  club_adventurers       club_adventurers?       @relation(fields: [club_adv_id], references: [club_adv_id])
  club_pathfinders       club_pathfinders?       @relation(fields: [club_pathf_id], references: [club_pathf_id])
  club_master_guides     club_master_guides?     @relation(fields: [club_mg_id], references: [club_mg_id])
  ecclesiastical_years   ecclesiastical_years    @relation(fields: [ecclesiastical_year_id], references: [year_id])
  created_by             users                   @relation(fields: [created_by_user_id], references: [id])

  @@index([club_adv_id])
  @@index([club_pathf_id])
  @@index([club_mg_id])
  @@index([transaction_date])
  @@index([type])
  @@index([finance_category_id])
  @@map("club_finances")
}
```

### Tabla: finance_categories

```prisma
model finance_categories {
  category_id    Int       @id @default(autoincrement())
  name           String    @db.VarChar(100)
  description    String?   @db.Text
  type           Int       // 0 = Ingreso, 1 = Egreso
  active         Boolean   @default(true)
  created_at     DateTime  @default(now())
  updated_at     DateTime  @updatedAt

  club_finances  club_finances[]

  @@map("finance_categories")
}
```

---

## 🧪 Tests E2E - Ejemplo

```typescript
// test/finances.e2e-spec.ts
describe('Finances (e2e)', () => {
  let treasurerToken: string;
  let memberToken: string;
  let financeId: number;

  beforeAll(async () => {
    treasurerToken = await getAuthToken('treasurer@club.com');
    memberToken = await getAuthToken('member@club.com');
  });

  it('should list finance categories', async () => {
    const response = await request(app.getHttpServer())
      .get('/finances/categories?type=0')
      .set('Authorization', `Bearer ${treasurerToken}`)
      .expect(200);

    expect(response.body.data).toBeInstanceOf(Array);
    expect(response.body.data[0]).toHaveProperty('category_id');
    expect(response.body.data[0].type).toBe(0);
  });

  it('should create income transaction as treasurer', async () => {
    const response = await request(app.getHttpServer())
      .post('/clubs/5/finances')
      .set('Authorization', `Bearer ${treasurerToken}`)
      .send({
        description: 'Test Income',
        amount: 1000.00,
        type: 0,
        transaction_date: '2026-02-04',
        finance_category_id: 1,
        club_pathf_id: 5,
        ecclesiastical_year_id: 5
      })
      .expect(201);

    expect(response.body.data.amount).toBe('1000.00');
    financeId = response.body.data.finance_id;
  });

  it('should reject creation by regular member', async () => {
    await request(app.getHttpServer())
      .post('/clubs/5/finances')
      .set('Authorization', `Bearer ${memberToken}`)
      .send({
        description: 'Unauthorized Transaction',
        amount: 500.00,
        type: 0,
        transaction_date: '2026-02-04',
        finance_category_id: 1,
        club_pathf_id: 5
      })
      .expect(403);
  });

  it('should reject negative amounts', async () => {
    await request(app.getHttpServer())
      .post('/clubs/5/finances')
      .set('Authorization', `Bearer ${treasurerToken}`)
      .send({
        description: 'Invalid Amount',
        amount: -100.00,
        type: 1,
        transaction_date: '2026-02-04',
        finance_category_id: 10,
        club_pathf_id: 5
      })
      .expect(400);
  });

  it('should get financial summary', async () => {
    const response = await request(app.getHttpServer())
      .get('/clubs/5/finances/summary?year=2026&month=2&clubTypeId=2')
      .set('Authorization', `Bearer ${treasurerToken}`)
      .expect(200);

    expect(response.body.data).toHaveProperty('summary');
    expect(response.body.data.summary).toHaveProperty('total_income');
    expect(response.body.data.summary).toHaveProperty('total_expenses');
    expect(response.body.data.summary).toHaveProperty('balance');
  });

  it('should update transaction', async () => {
    const response = await request(app.getHttpServer())
      .patch(`/finances/${financeId}`)
      .set('Authorization', `Bearer ${treasurerToken}`)
      .send({
        amount: 1200.00,
        notes: 'Updated amount'
      })
      .expect(200);

    expect(response.body.data.amount).toBe('1200.00');
  });

  it('should soft delete transaction', async () => {
    const response = await request(app.getHttpServer())
      .delete(`/finances/${financeId}`)
      .set('Authorization', `Bearer ${treasurerToken}`)
      .expect(200);

    expect(response.body.data.active).toBe(false);
  });
});
```

---

## 📝 Mejores Prácticas

### 1. Numeración de Recibos

Usar formato consistente para `receipt_number`:

```typescript
// Ingresos: R-YYYY-NNN
"R-2026-001"
"R-2026-002"

// Egresos: E-YYYY-NNN o F-NNN (factura)
"E-2026-001"
"F-12345"
```

### 2. Categorización Correcta

Crear categorías específicas y descriptivas:

```
INGRESOS:
- Cuotas de Membresía
- Ofrendas
- Donaciones
- Venta de Uniformes
- Eventos Especiales
- Rifas/Sorteos

EGRESOS:
- Material Didáctico
- Equipo de Campamento
- Uniformes (compra)
- Transporte
- Alimentos
- Mantenimiento
- Servicios
- Honorarios
```

### 3. Notas Descriptivas

Incluir información útil en `notes`:

```json
{
  "notes": "Cuotas de 30 miembros @ $100 c/u. Recibo del 1 al 30 de feb."
}

{
  "notes": "Factura #5678 de Tienda Outdoor. Compradas 5 carpas Coleman 4p."
}
```

### 4. Conciliación Regular

- Revisar balance mensual
- Comparar con estados de cuenta bancarios
- Verificar recibos físicos vs digitales
- Generar reportes para junta directiva

---

**Generado**: 4 de febrero de 2026
**Versión**: 2.2
**Módulo**: Finances
**Endpoints documentados**: 7
**Estado**: Producción
