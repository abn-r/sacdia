# Walkthrough: Campaments/Camporees

**Módulo**: Campaments/Camporees
**Versión API**: 2.2
**Fecha**: 3 de febrero de 2026

---

## 📋 Descripción General

El módulo de **Campaments/Camporees** permite la gestión completa de campamentos locales y de unión, incluyendo:

- Creación y administración de campamentos
- Registro de miembros con validación de seguros activos
- Control de asistencia y participación
- Tipos de campamento: Local y de Unión
- Validación automática de seguros tipo CAMPOREE

---

## 🎯 Flujo Completo

### 1. Crear un Campamento

**Endpoint**: `POST /api/v1/camporees`
**Autenticación**: Requerida
**Roles**: Director, Subdirector

**Request**:

```bash
curl -X POST http://localhost:3000/api/v1/camporees \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Campamento de Verano 2026",
    "description": "Campamento de aventureros y conquistadores",
    "start_date": "2026-07-15T00:00:00Z",
    "end_date": "2026-07-20T00:00:00Z",
    "local_field_id": 1,
    "includes_adventurers": true,
    "includes_pathfinders": true,
    "includes_master_guides": false,
    "local_camporee_place": "Campo Los Pinos, Monterrey",
    "registration_cost": 500.00
  }'
```

**Response** (201 Created):

```json
{
  "status": "success",
  "data": {
    "local_camporee_id": 1,
    "name": "Campamento de Verano 2026",
    "description": "Campamento de aventureros y conquistadores",
    "start_date": "2026-07-15T00:00:00.000Z",
    "end_date": "2026-07-20T00:00:00.000Z",
    "local_field_id": 1,
    "includes_adventurers": true,
    "includes_pathfinders": true,
    "includes_master_guides": false,
    "local_camporee_place": "Campo Los Pinos, Monterrey",
    "registration_cost": 500.00,
    "active": true,
    "created_at": "2026-02-03T14:30:00.000Z"
  }
}
```

---

### 2. Listar Campamentos

**Endpoint**: `GET /api/v1/camporees`
**Autenticación**: Requerida
**Query Parameters**:
- `page` (optional): Número de página (default: 1)
- `limit` (optional): Items por página (default: 20)
- `type` (optional): Tipo de campamento ("local" | "union")

**Request**:

```bash
curl -X GET "http://localhost:3000/api/v1/camporees?page=1&limit=10&type=local" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": [
    {
      "local_camporee_id": 1,
      "name": "Campamento de Verano 2026",
      "start_date": "2026-07-15T00:00:00.000Z",
      "end_date": "2026-07-20T00:00:00.000Z",
      "local_field_id": 1,
      "local_field": {
        "local_field_id": 1,
        "name": "Norte de México"
      },
      "includes_adventurers": true,
      "includes_pathfinders": true,
      "includes_master_guides": false,
      "registration_cost": 500.00,
      "members_count": 25,
      "active": true
    }
  ],
  "meta": {
    "total": 1,
    "page": 1,
    "limit": 10,
    "totalPages": 1
  }
}
```

---

### 3. Obtener Detalles de un Campamento

**Endpoint**: `GET /api/v1/camporees/:id`
**Autenticación**: Requerida

**Request**:

```bash
curl -X GET http://localhost:3000/api/v1/camporees/1 \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": {
    "local_camporee_id": 1,
    "name": "Campamento de Verano 2026",
    "description": "Campamento de aventureros y conquistadores",
    "start_date": "2026-07-15T00:00:00.000Z",
    "end_date": "2026-07-20T00:00:00.000Z",
    "local_field_id": 1,
    "local_field": {
      "local_field_id": 1,
      "name": "Norte de México",
      "union_id": 1
    },
    "includes_adventurers": true,
    "includes_pathfinders": true,
    "includes_master_guides": false,
    "local_camporee_place": "Campo Los Pinos, Monterrey",
    "registration_cost": 500.00,
    "active": true,
    "members": [
      {
        "member_id": 1,
        "user_id": "uuid-123",
        "user": {
          "name": "Juan",
          "paternal_last_name": "Pérez",
          "maternal_last_name": "González"
        },
        "club_name": "Club Aventureros Luz",
        "insurance_verified": true,
        "registration_date": "2026-02-03T10:00:00.000Z"
      }
    ],
    "created_at": "2026-02-03T14:30:00.000Z"
  }
}
```

---

### 4. Registrar Miembro en Campamento

**Endpoint**: `POST /api/v1/camporees/:id/register`
**Autenticación**: Requerida
**Validación Crítica**: Seguro activo tipo CAMPOREE

**Request**:

```bash
curl -X POST http://localhost:3000/api/v1/camporees/1/register \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "uuid-123",
    "camporee_type": "local",
    "club_name": "Club Aventureros Luz",
    "insurance_id": 10
  }'
```

**Response** (201 Created):

```json
{
  "status": "success",
  "data": {
    "member_id": 1,
    "camporee_id": 1,
    "camporee_type": "local",
    "user_id": "uuid-123",
    "club_name": "Club Aventureros Luz",
    "insurance_verified": true,
    "insurance_id": 10,
    "active": true,
    "registration_date": "2026-02-03T15:00:00.000Z"
  }
}
```

---

### 5. Listar Miembros de un Campamento

**Endpoint**: `GET /api/v1/camporees/:id/members`
**Autenticación**: Requerida

**Request**:

```bash
curl -X GET http://localhost:3000/api/v1/camporees/1/members \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": [
    {
      "member_id": 1,
      "user_id": "uuid-123",
      "user": {
        "name": "Juan",
        "paternal_last_name": "Pérez",
        "maternal_last_name": "González",
        "email": "juan.perez@example.com",
        "birthdate": "2010-05-15"
      },
      "club_name": "Club Aventureros Luz",
      "insurance_verified": true,
      "insurance": {
        "insurance_id": 10,
        "insurance_type": "CAMPOREE",
        "start_date": "2026-01-01T00:00:00.000Z",
        "end_date": "2026-12-31T00:00:00.000Z",
        "status": "active"
      },
      "registration_date": "2026-02-03T15:00:00.000Z",
      "active": true
    }
  ],
  "meta": {
    "total": 25,
    "insured": 23,
    "pending_insurance": 2
  }
}
```

---

### 6. Actualizar Campamento

**Endpoint**: `PATCH /api/v1/camporees/:id`
**Autenticación**: Requerida
**Roles**: Director, Subdirector

**Request**:

```bash
curl -X PATCH http://localhost:3000/api/v1/camporees/1 \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "registration_cost": 550.00,
    "local_camporee_place": "Campo Los Pinos, Monterrey - Área Norte"
  }'
```

**Response** (200 OK):

```json
{
  "status": "success",
  "data": {
    "local_camporee_id": 1,
    "name": "Campamento de Verano 2026",
    "registration_cost": 550.00,
    "local_camporee_place": "Campo Los Pinos, Monterrey - Área Norte",
    "updated_at": "2026-02-03T16:00:00.000Z"
  }
}
```

---

### 7. Eliminar Miembro de Campamento

**Endpoint**: `DELETE /api/v1/camporees/:id/members/:userId`
**Autenticación**: Requerida
**Roles**: Director, Subdirector

**Request**:

```bash
curl -X DELETE http://localhost:3000/api/v1/camporees/1/members/uuid-123 \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "message": "Member removed from camporee successfully"
}
```

---

### 8. Eliminar Campamento

**Endpoint**: `DELETE /api/v1/camporees/:id`
**Autenticación**: Requerida
**Roles**: Director only

**Request**:

```bash
curl -X DELETE http://localhost:3000/api/v1/camporees/1 \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response** (200 OK):

```json
{
  "status": "success",
  "message": "Camporee deleted successfully"
}
```

---

## 💡 Casos de Uso

### Caso 1: Campamento Local con Validación de Seguros

**Escenario**: Un director quiere organizar un campamento local y asegurarse de que todos los participantes tengan seguro activo.

**Flujo**:

1. **Crear campamento** (Director)
   ```bash
   POST /api/v1/camporees
   ```

2. **Usuario solicita registro**
   - Frontend obtiene el `insurance_id` activo del usuario
   - Valida tipo CAMPOREE y fecha de vencimiento

3. **Registrar miembro con seguro**
   ```bash
   POST /api/v1/camporees/1/register
   Body: { user_id, insurance_id, club_name, camporee_type: "local" }
   ```

4. **Backend valida automáticamente**:
   - ✅ Seguro existe y pertenece al usuario
   - ✅ Tipo de seguro = CAMPOREE
   - ✅ Fecha de vencimiento > fecha fin del campamento
   - ✅ Marca `insurance_verified = true`

5. **Director consulta lista de miembros**
   ```bash
   GET /api/v1/camporees/1/members
   ```
   - Ve quiénes tienen seguro verificado
   - Ve quiénes están pendientes de seguro

---

### Caso 2: Campamento Multi-Club

**Escenario**: Un campamento de unión con participantes de múltiples clubes.

**Flujo**:

1. **Crear campamento de unión**
   ```json
   {
     "name": "Campamento de Unión 2026",
     "includes_adventurers": true,
     "includes_pathfinders": true,
     "includes_master_guides": true,
     "local_field_id": 1
   }
   ```

2. **Registrar miembros de diferentes clubes**
   - Club A: POST con `club_name: "Club Aventureros Norte"`
   - Club B: POST con `club_name: "Club Conquistadores Sur"`
   - Club C: POST con `club_name: "Club Guías Mayores Este"`

3. **Consultar participación por club**
   ```bash
   GET /api/v1/camporees/1/members
   ```
   - Response incluye `club_name` para agrupar

---

### Caso 3: Registro sin Seguro (Pendiente)

**Escenario**: Permitir registro pero marcar como pendiente de seguro.

**Flujo**:

1. **Registrar sin insurance_id**
   ```json
   {
     "user_id": "uuid-456",
     "camporee_type": "local",
     "club_name": "Club Aventureros Luz"
     // Sin insurance_id
   }
   ```

2. **Backend crea registro**
   - `insurance_verified = false`
   - `insurance_id = null`

3. **Actualizar más tarde con seguro**
   ```bash
   PATCH /api/v1/camporees/1/members/uuid-456
   Body: { insurance_id: 15 }
   ```
   - Backend valida seguro
   - Actualiza `insurance_verified = true`

---

## 🔒 Validaciones y Errores

### Error 1: Seguro Inválido

**Causa**: El `insurance_id` no pertenece al usuario o no existe.

**Response** (400 Bad Request):

```json
{
  "statusCode": 400,
  "message": "Invalid insurance",
  "error": "Bad Request"
}
```

**Solución**: Verificar que el `insurance_id` pertenece al `user_id` correcto.

---

### Error 2: Tipo de Seguro Incorrecto

**Causa**: El seguro no es de tipo CAMPOREE.

**Response** (400 Bad Request):

```json
{
  "statusCode": 400,
  "message": "Insurance type must be CAMPOREE",
  "error": "Bad Request"
}
```

**Solución**: Obtener o crear un seguro de tipo CAMPOREE para el usuario.

---

### Error 3: Seguro Expirado

**Causa**: La fecha de vencimiento del seguro es anterior a la fecha fin del campamento.

**Response** (400 Bad Request):

```json
{
  "statusCode": 400,
  "message": "Insurance expires before camporee ends",
  "error": "Bad Request"
}
```

**Solución**: Renovar el seguro o usar uno con fecha de vencimiento válida.

---

### Error 4: Campamento No Encontrado

**Causa**: El `camporee_id` no existe.

**Response** (404 Not Found):

```json
{
  "statusCode": 404,
  "message": "Camporee not found",
  "error": "Not Found"
}
```

**Solución**: Verificar que el ID del campamento es correcto.

---

### Error 5: Miembro Ya Registrado

**Causa**: El usuario ya está registrado en este campamento.

**Response** (409 Conflict):

```json
{
  "statusCode": 409,
  "message": "User already registered in this camporee",
  "error": "Conflict"
}
```

**Solución**: Verificar el registro existente antes de intentar duplicar.

---

### Error 6: Sin Permisos

**Causa**: Usuario sin rol de Director o Subdirector intenta crear/modificar campamento.

**Response** (403 Forbidden):

```json
{
  "statusCode": 403,
  "message": "Forbidden resource",
  "error": "Forbidden"
}
```

**Solución**: Solo Directores y Subdirectores pueden gestionar campamentos.

---

## 🔑 Validaciones del Backend

El backend implementa las siguientes validaciones automáticas:

### Al Crear Campamento

```typescript
// Validaciones en DTO
- name: string (required)
- start_date: ISO 8601 date string (required)
- end_date: ISO 8601 date string (required)
- start_date < end_date
- local_field_id: number (required, debe existir en BD)
- registration_cost: decimal (optional, >= 0)
```

### Al Registrar Miembro

```typescript
// Validaciones en Service
1. Campamento existe
2. Usuario no está ya registrado
3. Si insurance_id proporcionado:
   - Seguro existe
   - Seguro pertenece al usuario
   - Tipo = CAMPOREE
   - end_date >= campamento.end_date
4. Usar transacción para atomicidad
```

### Código de Validación de Seguro

```typescript
async registerMember(camporeeId: number, dto: RegisterMemberDto) {
  return await this.prisma.$transaction(async (tx) => {
    // 1. Validar campamento existe
    const camporee = await tx.local_camporees.findUnique({
      where: { local_camporee_id: camporeeId }
    });
    if (!camporee) throw new NotFoundException('Camporee not found');

    // 2. Validar seguro activo (si proporcionado)
    if (dto.insurance_id) {
      const insurance = await tx.member_insurances.findUnique({
        where: { insurance_id: dto.insurance_id }
      });

      // Validar pertenencia
      if (!insurance || insurance.user_id !== dto.user_id) {
        throw new BadRequestException('Invalid insurance');
      }

      // Validar tipo
      if (insurance.insurance_type !== 'CAMPOREE') {
        throw new BadRequestException('Insurance type must be CAMPOREE');
      }

      // Validar fecha de vencimiento
      if (insurance.end_date < camporee.end_date) {
        throw new BadRequestException('Insurance expires before camporee ends');
      }
    }

    // 3. Registrar miembro
    const member = await tx.camporee_members.create({
      data: {
        camporee_id: camporeeId,
        camporee_type: dto.camporee_type,
        user_id: dto.user_id,
        club_name: dto.club_name,
        insurance_verified: !!dto.insurance_id,
        insurance_id: dto.insurance_id,
        active: true
      }
    });

    return member;
  });
}
```

---

## 📊 Modelos de Base de Datos

### Tabla: `local_camporees`

```prisma
model local_camporees {
  local_camporee_id      Int       @id @default(autoincrement())
  name                   String
  description            String?
  start_date             DateTime
  end_date               DateTime
  local_field_id         Int
  includes_adventurers   Boolean   @default(false)
  includes_pathfinders   Boolean   @default(false)
  includes_master_guides Boolean   @default(false)
  local_camporee_place   String
  registration_cost      Decimal?
  active                 Boolean   @default(true)
  created_at             DateTime  @default(now())
  updated_at             DateTime  @updatedAt

  local_fields           local_fields @relation(fields: [local_field_id], references: [local_field_id])
  camporee_members       camporee_members[]
}
```

### Tabla: `camporee_members`

```prisma
model camporee_members {
  member_id          Int       @id @default(autoincrement())
  camporee_id        Int
  camporee_type      String    // 'local' | 'union'
  user_id            String    @db.Uuid
  club_name          String?
  insurance_verified Boolean   @default(false)
  insurance_id       Int?
  active             Boolean   @default(true)
  registration_date  DateTime  @default(now())

  users              users @relation(fields: [user_id], references: [id])
  local_camporees    local_camporees? @relation(fields: [camporee_id], references: [local_camporee_id])
  member_insurances  member_insurances? @relation(fields: [insurance_id], references: [insurance_id])

  @@index([user_id])
  @@index([camporee_id])
}
```

---

## 🧪 Testing

### Test E2E: `camporees.e2e-spec.ts`

```typescript
describe('Camporees API (e2e)', () => {
  it('POST /camporees - should create camporee (director)', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/camporees')
      .set('Authorization', `Bearer ${directorToken}`)
      .send({
        name: 'Test Camporee',
        start_date: '2026-07-15',
        end_date: '2026-07-20',
        local_field_id: 1,
        includes_adventurers: true,
        includes_pathfinders: true,
        includes_master_guides: false,
        local_camporee_place: 'Test Location'
      })
      .expect(201);

    expect(response.body.data.name).toBe('Test Camporee');
  });

  it('POST /camporees/:id/register - should validate insurance', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/camporees/1/register')
      .set('Authorization', `Bearer ${userToken}`)
      .send({
        user_id: userId,
        camporee_type: 'local',
        club_name: 'Test Club',
        insurance_id: invalidInsuranceId
      })
      .expect(400);
  });
});
```

---

## 📝 Notas Importantes

1. **Transacciones**: Todos los registros de miembros usan transacciones para garantizar atomicidad.

2. **Soft Deletes**: Los campamentos y miembros usan `active = false` en lugar de eliminación física.

3. **Permisos**:
   - Crear/Actualizar campamentos: Director, Subdirector
   - Eliminar campamentos: Solo Director
   - Registrar miembros: Cualquier usuario autenticado
   - Ver campamentos: Cualquier usuario autenticado

4. **Seguros Opcionales**: Es posible registrar miembros sin seguro (`insurance_verified = false`), pero se recomienda validar el seguro antes de la fecha del campamento.

5. **Tipos de Campamento**:
   - `local`: Campamentos organizados por campo local
   - `union`: Campamentos organizados por unión

---

**Documento creado**: 2026-02-03
**Versión**: 1.0
**Autor**: Sistema SACDIA
