# Walkthrough: Inventory (Inventario de Club)

**Módulo**: Inventory
**Versión API**: 2.2
**Fecha**: 4 de febrero de 2026

---

## 📋 Descripción General

El módulo de **Inventory** proporciona un sistema de gestión de inventario específico para cada instancia de club (Aventureros, Conquistadores, o Guías Mayores). Este módulo permite:

- Control de artículos por instancia de club
- Categorización de items (equipo, uniformes, materiales, etc.)
- Tracking de cantidades disponibles
- Gestión restringida por roles (Director, Subdirector, Tesorero)
- Organización separada por tipo de club

**Características principales**:
- ✅ Inventario separado por instancia de club
- ✅ Sistema de categorías para organización
- ✅ Control de acceso basado en roles RBAC
- ✅ Soft delete para mantener historial
- ✅ Filtrado por tipo de club instance

---

## 🎯 Flujo Completo

### 1. Listar Categorías de Inventario

Primero, consultar las categorías disponibles para clasificar items.

**Endpoint**: `GET /api/v1/catalogs/inventory-categories`
**Autenticación**: Requerida

**Request**:

```bash
curl -X GET http://localhost:3000/api/v1/catalogs/inventory-categories \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": [
    {
      "category_id": 1,
      "name": "Equipo de Campamento",
      "description": "Carpas, sleeping bags, estufas, etc.",
      "active": true
    },
    {
      "category_id": 2,
      "name": "Uniformes",
      "description": "Camisas, pantalones, pañoletas, insignias",
      "active": true
    },
    {
      "category_id": 3,
      "name": "Material Didáctico",
      "description": "Libros, manuales, cuadernos de clases",
      "active": true
    },
    {
      "category_id": 4,
      "name": "Instrumentos Musicales",
      "description": "Guitarras, tambores, flautas",
      "active": true
    },
    {
      "category_id": 5,
      "name": "Equipo Deportivo",
      "description": "Pelotas, redes, conos, etc.",
      "active": true
    },
    {
      "category_id": 6,
      "name": "Herramientas",
      "description": "Martillos, sierras, destornilladores",
      "active": true
    }
  ]
}
```

---

### 2. Listar Items del Inventario de un Club

**Endpoint**: `GET /api/v1/clubs/:clubId/inventory`
**Autenticación**: Requerida
**Roles**: Cualquier miembro del club puede ver

**Query Parameters**:
- `instanceType`: Tipo de instancia (`adv`, `pathf`, `mg`)

**Request**:

```bash
curl -X GET "http://localhost:3000/api/v1/clubs/5/inventory?instanceType=pathf" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": [
    {
      "inventory_id": 1,
      "name": "Carpas 4 personas",
      "description": "Carpas marca Coleman para 4 personas",
      "inventory_category_id": 1,
      "category": {
        "category_id": 1,
        "name": "Equipo de Campamento"
      },
      "amount": 8,
      "club_adv_id": null,
      "club_pathf_id": 5,
      "club_mg_id": null,
      "active": true,
      "created_at": "2025-03-10T00:00:00.000Z",
      "updated_at": "2026-01-15T00:00:00.000Z"
    },
    {
      "inventory_id": 2,
      "name": "Camisas Oficial Conquistadores",
      "description": "Camisas azules talla M",
      "inventory_category_id": 2,
      "category": {
        "category_id": 2,
        "name": "Uniformes"
      },
      "amount": 25,
      "club_adv_id": null,
      "club_pathf_id": 5,
      "club_mg_id": null,
      "active": true,
      "created_at": "2025-04-01T00:00:00.000Z",
      "updated_at": "2025-12-20T00:00:00.000Z"
    },
    {
      "inventory_id": 3,
      "name": "Manual de Clases Progresivas",
      "description": "Manuales impresos de clases Amigo a Guía Mayor",
      "inventory_category_id": 3,
      "category": {
        "category_id": 3,
        "name": "Material Didáctico"
      },
      "amount": 50,
      "club_adv_id": null,
      "club_pathf_id": 5,
      "club_mg_id": null,
      "active": true,
      "created_at": "2025-02-15T00:00:00.000Z",
      "updated_at": "2026-01-10T00:00:00.000Z"
    }
  ],
  "meta": {
    "total_items": 3,
    "total_value_estimated": null,
    "club_instance": {
      "club_pathf_id": 5,
      "instance_type": "pathf"
    }
  }
}
```

---

### 3. Ver Detalles de un Item

**Endpoint**: `GET /api/v1/inventory/:id`
**Autenticación**: Requerida
**Roles**: Cualquier miembro del club

**Request**:

```bash
curl -X GET http://localhost:3000/api/v1/inventory/1 \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": {
    "inventory_id": 1,
    "name": "Carpas 4 personas",
    "description": "Carpas marca Coleman para 4 personas, color azul, con mosquitero",
    "inventory_category_id": 1,
    "category": {
      "category_id": 1,
      "name": "Equipo de Campamento",
      "description": "Carpas, sleeping bags, estufas, etc."
    },
    "amount": 8,
    "club_adv_id": null,
    "club_pathf_id": 5,
    "club_mg_id": null,
    "active": true,
    "created_at": "2025-03-10T00:00:00.000Z",
    "updated_at": "2026-01-15T00:00:00.000Z",
    "history": [
      {
        "action": "CREATED",
        "date": "2025-03-10T00:00:00.000Z",
        "amount": 8,
        "user": "Director Juan Pérez"
      },
      {
        "action": "UPDATED",
        "date": "2025-08-20T00:00:00.000Z",
        "previous_amount": 8,
        "new_amount": 10,
        "user": "Subdirector María González"
      },
      {
        "action": "UPDATED",
        "date": "2026-01-15T00:00:00.000Z",
        "previous_amount": 10,
        "new_amount": 8,
        "user": "Tesorero Carlos Ramírez",
        "note": "2 carpas dañadas, retiradas del inventario"
      }
    ]
  }
}
```

---

### 4. Agregar Nuevo Item al Inventario

**Endpoint**: `POST /api/v1/clubs/:clubId/inventory`
**Autenticación**: Requerida
**Roles**: Director, Subdirector, Tesorero

**Request**:

```bash
curl -X POST http://localhost:3000/api/v1/clubs/5/inventory \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Sleeping Bags",
    "description": "Bolsas de dormir para clima frío, marca North Face",
    "inventory_category_id": 1,
    "amount": 15,
    "club_pathf_id": 5
  }'
```

**Response** (201 Created):

```json
{
  "status": "success",
  "data": {
    "inventory_id": 10,
    "name": "Sleeping Bags",
    "description": "Bolsas de dormir para clima frío, marca North Face",
    "inventory_category_id": 1,
    "amount": 15,
    "club_adv_id": null,
    "club_pathf_id": 5,
    "club_mg_id": null,
    "active": true,
    "created_at": "2026-02-04T12:30:00.000Z",
    "updated_at": "2026-02-04T12:30:00.000Z"
  }
}
```

**Validaciones**:
- ✅ Nombre requerido (máximo 150 caracteres)
- ✅ Cantidad (amount) debe ser >= 0
- ✅ Debe especificar exactamente UNA instancia de club (club_adv_id, club_pathf_id, o club_mg_id)
- ✅ Usuario debe tener rol de Director, Subdirector, o Tesorero en ese club
- ✅ Categoría debe existir y estar activa

---

### 5. Actualizar Item del Inventario

**Endpoint**: `PATCH /api/v1/inventory/:id`
**Autenticación**: Requerida
**Roles**: Director, Subdirector, Tesorero

**Request**:

```bash
curl -X PATCH http://localhost:3000/api/v1/inventory/10 \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 12,
    "description": "Bolsas de dormir para clima frío, marca North Face. 3 unidades prestadas."
  }'
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": {
    "inventory_id": 10,
    "name": "Sleeping Bags",
    "description": "Bolsas de dormir para clima frío, marca North Face. 3 unidades prestadas.",
    "inventory_category_id": 1,
    "amount": 12,
    "club_adv_id": null,
    "club_pathf_id": 5,
    "club_mg_id": null,
    "active": true,
    "created_at": "2026-02-04T12:30:00.000Z",
    "updated_at": "2026-02-04T15:45:00.000Z"
  }
}
```

**Casos de Uso Comunes**:

1. **Ajustar cantidad** después de compra o pérdida:
   ```json
   { "amount": 20 }
   ```

2. **Cambiar categoría**:
   ```json
   { "inventory_category_id": 3 }
   ```

3. **Actualizar descripción** con notas:
   ```json
   { "description": "10 carpas en buen estado, 2 requieren reparación" }
   ```

---

### 6. Eliminar Item del Inventario (Soft Delete)

**Endpoint**: `DELETE /api/v1/inventory/:id`
**Autenticación**: Requerida
**Roles**: Director únicamente

**Request**:

```bash
curl -X DELETE http://localhost:3000/api/v1/inventory/10 \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "message": "Inventory item deactivated successfully",
  "data": {
    "inventory_id": 10,
    "active": false,
    "deactivated_at": "2026-02-04T16:00:00.000Z"
  }
}
```

**Nota**: El item NO se elimina de la base de datos, solo se marca como `active: false`. Esto preserva el historial.

---

## 📚 Casos de Uso Detallados

### Caso de Uso 1: Control de Equipo de Campamento

**Escenario**: Un club de Conquistadores necesita gestionar su equipo para un camporee.

**Flujo**:

1. **Tesorero revisa inventario actual**:
   ```bash
   GET /api/v1/clubs/5/inventory?instanceType=pathf
   ```

2. **Identifica qué falta**:
   - Tienen 8 carpas, necesitan 12
   - Tienen 10 sleeping bags, necesitan 20

3. **Después de compra, actualiza cantidades**:
   ```bash
   # Actualizar carpas
   PATCH /api/v1/inventory/1
   Body: { "amount": 12 }

   # Actualizar sleeping bags
   PATCH /api/v1/inventory/2
   Body: { "amount": 20 }
   ```

4. **Después del camporee, registra pérdidas/daños**:
   ```bash
   PATCH /api/v1/inventory/1
   Body: {
     "amount": 11,
     "description": "11 carpas en buen estado. 1 carpa dañada en camporee 2026"
   }
   ```

---

### Caso de Uso 2: Gestión de Uniformes

**Escenario**: Club necesita controlar inventario de uniformes para venta/préstamo a miembros.

**Flujo**:

1. **Subdirector agrega uniformes al inventario**:
   ```bash
   POST /api/v1/clubs/5/inventory
   Body: {
     "name": "Camisa Oficial Talla S",
     "description": "Camisas azules talla S para conquistadores",
     "inventory_category_id": 2,
     "amount": 20,
     "club_pathf_id": 5
   }

   POST /api/v1/clubs/5/inventory
   Body: {
     "name": "Camisa Oficial Talla M",
     "inventory_category_id": 2,
     "amount": 30,
     "club_pathf_id": 5
   }

   POST /api/v1/clubs/5/inventory
   Body: {
     "name": "Camisa Oficial Talla L",
     "inventory_category_id": 2,
     "amount": 15,
     "club_pathf_id": 5
   }
   ```

2. **Cuando un miembro compra una camisa talla M**:
   ```bash
   PATCH /api/v1/inventory/12
   Body: { "amount": 29 }
   ```

3. **Verificar stock disponible**:
   ```bash
   GET /api/v1/clubs/5/inventory?instanceType=pathf
   # Filtrar en frontend por category_id: 2 (Uniformes)
   ```

---

### Caso de Uso 3: Separar Inventarios por Tipo de Club

**Escenario**: Una iglesia tiene club de Aventureros Y Conquistadores. Necesitan inventarios separados.

**Flujo**:

1. **Agregar items para Aventureros** (club_adv_id: 3):
   ```bash
   POST /api/v1/clubs/3/inventory
   Body: {
     "name": "Libro Mi Amigo Jesús",
     "inventory_category_id": 3,
     "amount": 25,
     "club_adv_id": 3
   }
   ```

2. **Agregar items para Conquistadores** (club_pathf_id: 5):
   ```bash
   POST /api/v1/clubs/5/inventory
   Body: {
     "name": "Manual de Clases Progresivas",
     "inventory_category_id": 3,
     "amount": 40,
     "club_pathf_id": 5
   }
   ```

3. **Listar solo items de Aventureros**:
   ```bash
   GET /api/v1/clubs/3/inventory?instanceType=adv
   # Retorna solo items con club_adv_id: 3
   ```

4. **Listar solo items de Conquistadores**:
   ```bash
   GET /api/v1/clubs/5/inventory?instanceType=pathf
   # Retorna solo items con club_pathf_id: 5
   ```

**Resultado**: Inventarios completamente separados y sin confusión.

---

### Caso de Uso 4: Reporte de Inventario para Junta Directiva

**Escenario**: Director necesita generar reporte de inventario para reunión de junta.

**Flujo**:

1. **Obtener todo el inventario**:
   ```bash
   GET /api/v1/clubs/5/inventory?instanceType=pathf
   ```

2. **Frontend agrupa por categoría**:
   ```typescript
   const inventory = response.data;

   const byCategory = inventory.reduce((acc, item) => {
     const category = item.category.name;
     if (!acc[category]) acc[category] = [];
     acc[category].push(item);
     return acc;
   }, {});

   // Resultado:
   // {
   //   "Equipo de Campamento": [8 carpas, 20 sleeping bags, ...],
   //   "Uniformes": [29 camisas M, 20 camisas S, ...],
   //   "Material Didáctico": [50 manuales, 30 libros, ...]
   // }
   ```

3. **Generar PDF o Excel** con la información agrupada.

---

## ⚠️ Validaciones y Errores Comunes

### Error 1: Intentar agregar item sin especificar instancia de club

**Código**: 400 Bad Request

**Mensaje**: `"Must specify exactly one club instance (club_adv_id, club_pathf_id, or club_mg_id)"`

**Causa**: No se especificó ninguna de las tres FKs de instancia de club, o se especificó más de una.

**Solución**:
```json
// ❌ Incorrecto (sin instancia)
{
  "name": "Carpas",
  "amount": 10
}

// ❌ Incorrecto (múltiples instancias)
{
  "name": "Carpas",
  "amount": 10,
  "club_adv_id": 3,
  "club_pathf_id": 5
}

// ✅ Correcto
{
  "name": "Carpas",
  "amount": 10,
  "club_pathf_id": 5
}
```

---

### Error 2: Usuario sin permisos intenta agregar/editar

**Código**: 403 Forbidden

**Mensaje**: `"Insufficient permissions. Required roles: director, subdirector, or treasurer"`

**Causa**: Usuario autenticado no tiene rol de Director, Subdirector, ni Tesorero en ese club.

**Solución**:
- Solo estos roles pueden agregar/editar/eliminar items
- Cualquier miembro del club puede VER el inventario (GET)
- Verificar roles del usuario antes de intentar operaciones de escritura

---

### Error 3: Categoría inválida o inactiva

**Código**: 404 Not Found

**Mensaje**: `"Inventory category not found or inactive"`

**Causa**: `inventory_category_id` no existe en la tabla `inventory_categories` o está marcada como `active: false`.

**Solución**:
1. Listar categorías activas primero:
   ```bash
   GET /api/v1/catalogs/inventory-categories
   ```
2. Usar solo IDs de categorías activas

---

### Error 4: Cantidad negativa

**Código**: 400 Bad Request

**Mensaje**: `"Amount must be greater than or equal to 0"`

**Causa**: Se intentó establecer `amount: -5` o cualquier valor negativo.

**Solución**:
- Usar `amount: 0` para indicar "sin stock"
- No permitir valores negativos
- Si se prestaron items, restar de la cantidad total

---

## 🔧 Lógica de Backend

### Validación de Creación de Item

```typescript
// inventory.service.ts
async create(clubId: number, dto: CreateInventoryItemDto) {
  // 1. Validar que se especificó exactamente UNA instancia de club
  const instanceCount = [
    dto.club_adv_id,
    dto.club_pathf_id,
    dto.club_mg_id
  ].filter(id => id !== null && id !== undefined).length;

  if (instanceCount !== 1) {
    throw new BadRequestException(
      'Must specify exactly one club instance'
    );
  }

  // 2. Validar categoría existe y está activa
  if (dto.inventory_category_id) {
    const category = await this.prisma.inventory_categories.findUnique({
      where: { category_id: dto.inventory_category_id, active: true }
    });
    if (!category) {
      throw new NotFoundException('Inventory category not found or inactive');
    }
  }

  // 3. Validar cantidad >= 0
  if (dto.amount < 0) {
    throw new BadRequestException('Amount must be >= 0');
  }

  // 4. Crear item
  return await this.prisma.club_inventory.create({
    data: {
      name: dto.name,
      description: dto.description,
      inventory_category_id: dto.inventory_category_id,
      amount: dto.amount,
      club_adv_id: dto.club_adv_id,
      club_pathf_id: dto.club_pathf_id,
      club_mg_id: dto.club_mg_id,
      active: true
    },
    include: {
      inventory_categories: true
    }
  });
}
```

### Filtrado por Instancia de Club

```typescript
async findByClubInstance(clubId: number, instanceType: string) {
  // Construir el campo dinámicamente
  const field = `club_${instanceType}_id`; // 'club_adv_id', 'club_pathf_id', 'club_mg_id'

  return await this.prisma.club_inventory.findMany({
    where: {
      [field]: clubId,
      active: true
    },
    include: {
      inventory_categories: {
        select: {
          category_id: true,
          name: true,
          description: true
        }
      }
    },
    orderBy: [
      { inventory_categories: { name: 'asc' } },
      { name: 'asc' }
    ]
  });
}
```

### Soft Delete

```typescript
async remove(inventoryId: number) {
  // No eliminar físicamente, solo desactivar
  return await this.prisma.club_inventory.update({
    where: { inventory_id: inventoryId },
    data: {
      active: false,
      updated_at: new Date()
    }
  });
}
```

---

## 📊 Schema de Base de Datos (Prisma)

### Tabla: club_inventory

```prisma
model club_inventory {
  inventory_id           Int      @id @default(autoincrement())
  name                   String   @db.VarChar(150)
  description            String?  @db.Text
  inventory_category_id  Int?
  amount                 Int      @default(0)
  club_adv_id            Int?
  club_pathf_id          Int?
  club_mg_id             Int?
  active                 Boolean  @default(true)
  created_at             DateTime @default(now())
  updated_at             DateTime @updatedAt

  inventory_categories   inventory_categories?  @relation(fields: [inventory_category_id], references: [category_id])
  club_adventurers       club_adventurers?      @relation(fields: [club_adv_id], references: [club_adv_id])
  club_pathfinders       club_pathfinders?      @relation(fields: [club_pathf_id], references: [club_pathf_id])
  club_master_guides     club_master_guides?    @relation(fields: [club_mg_id], references: [club_mg_id])

  @@index([club_adv_id])
  @@index([club_pathf_id])
  @@index([club_mg_id])
  @@index([inventory_category_id])
  @@map("club_inventory")
}
```

### Tabla: inventory_categories

```prisma
model inventory_categories {
  category_id    Int      @id @default(autoincrement())
  name           String   @db.VarChar(100)
  description    String?  @db.Text
  active         Boolean  @default(true)
  created_at     DateTime @default(now())
  updated_at     DateTime @updatedAt

  club_inventory club_inventory[]

  @@map("inventory_categories")
}
```

---

## 🧪 Tests E2E - Ejemplo

```typescript
// test/inventory.e2e-spec.ts
describe('Inventory (e2e)', () => {
  let directorToken: string;
  let memberToken: string;

  beforeAll(async () => {
    // Obtener tokens de director y miembro regular
    directorToken = await getAuthToken('director@club.com');
    memberToken = await getAuthToken('member@club.com');
  });

  it('should list inventory items for a club', async () => {
    const response = await request(app.getHttpServer())
      .get('/clubs/5/inventory?instanceType=pathf')
      .set('Authorization', `Bearer ${memberToken}`)
      .expect(200);

    expect(response.body.data).toBeInstanceOf(Array);
    expect(response.body.data[0]).toHaveProperty('inventory_id');
    expect(response.body.data[0]).toHaveProperty('name');
    expect(response.body.data[0]).toHaveProperty('category');
  });

  it('should create inventory item as director', async () => {
    const response = await request(app.getHttpServer())
      .post('/clubs/5/inventory')
      .set('Authorization', `Bearer ${directorToken}`)
      .send({
        name: 'Test Tent',
        description: 'Test description',
        inventory_category_id: 1,
        amount: 5,
        club_pathf_id: 5
      })
      .expect(201);

    expect(response.body.data.name).toBe('Test Tent');
    expect(response.body.data.amount).toBe(5);
  });

  it('should reject creation by regular member', async () => {
    await request(app.getHttpServer())
      .post('/clubs/5/inventory')
      .set('Authorization', `Bearer ${memberToken}`)
      .send({
        name: 'Test Item',
        amount: 10,
        club_pathf_id: 5
      })
      .expect(403);
  });

  it('should update inventory amount', async () => {
    // Crear item
    const created = await request(app.getHttpServer())
      .post('/clubs/5/inventory')
      .set('Authorization', `Bearer ${directorToken}`)
      .send({
        name: 'Updateable Item',
        amount: 10,
        club_pathf_id: 5
      });

    const inventoryId = created.body.data.inventory_id;

    // Actualizar
    const response = await request(app.getHttpServer())
      .patch(`/inventory/${inventoryId}`)
      .set('Authorization', `Bearer ${directorToken}`)
      .send({ amount: 15 })
      .expect(200);

    expect(response.body.data.amount).toBe(15);
  });

  it('should soft delete inventory item', async () => {
    // Crear item
    const created = await request(app.getHttpServer())
      .post('/clubs/5/inventory')
      .set('Authorization', `Bearer ${directorToken}`)
      .send({
        name: 'Deletable Item',
        amount: 5,
        club_pathf_id: 5
      });

    const inventoryId = created.body.data.inventory_id;

    // Eliminar
    const response = await request(app.getHttpServer())
      .delete(`/inventory/${inventoryId}`)
      .set('Authorization', `Bearer ${directorToken}`)
      .expect(200);

    expect(response.body.data.active).toBe(false);

    // Verificar no aparece en lista
    const list = await request(app.getHttpServer())
      .get('/clubs/5/inventory?instanceType=pathf')
      .set('Authorization', `Bearer ${memberToken}`)
      .expect(200);

    const found = list.body.data.find(
      item => item.inventory_id === inventoryId
    );
    expect(found).toBeUndefined();
  });

  it('should reject negative amounts', async () => {
    await request(app.getHttpServer())
      .post('/clubs/5/inventory')
      .set('Authorization', `Bearer ${directorToken}`)
      .send({
        name: 'Invalid Item',
        amount: -5,
        club_pathf_id: 5
      })
      .expect(400);
  });

  it('should reject multiple club instances', async () => {
    await request(app.getHttpServer())
      .post('/clubs/5/inventory')
      .set('Authorization', `Bearer ${directorToken}`)
      .send({
        name: 'Invalid Item',
        amount: 10,
        club_adv_id: 3,
        club_pathf_id: 5
      })
      .expect(400);
  });
});
```

---

## 📝 Notas Importantes

### Permisos por Rol

| Acción | Director | Subdirector | Tesorero | Instructor | Miembro |
|--------|----------|-------------|----------|------------|---------|
| Ver inventario | ✅ | ✅ | ✅ | ✅ | ✅ |
| Agregar item | ✅ | ✅ | ✅ | ❌ | ❌ |
| Editar item | ✅ | ✅ | ✅ | ❌ | ❌ |
| Eliminar item | ✅ | ❌ | ❌ | ❌ | ❌ |
| Ver categorías | ✅ | ✅ | ✅ | ✅ | ✅ |

### Diferencias entre Clubs

Cada instancia de club (Aventureros, Conquistadores, Guías Mayores) tiene su propio inventario completamente separado:

- **Club Aventureros** (club_adv_id): Items con `club_adv_id` no nulo
- **Club Conquistadores** (club_pathf_id): Items con `club_pathf_id` no nulo
- **Club Guías Mayores** (club_mg_id): Items con `club_mg_id` no nulo

No es posible compartir items entre clubs. Si un item se usa en múltiples clubs, debe crearse por separado en cada uno.

### Mejores Prácticas

1. **Usar categorías** para organizar mejor el inventario
2. **Actualizar cantidades** inmediatamente después de compras/pérdidas
3. **Agregar descripciones detalladas** (marca, modelo, estado)
4. **No eliminar físicamente**, usar soft delete para mantener historial
5. **Realizar auditorías periódicas** comparando inventario físico vs sistema

---

**Generado**: 4 de febrero de 2026
**Versión**: 2.2
**Módulo**: Inventory
**Endpoints documentados**: 5
**Estado**: Producción
