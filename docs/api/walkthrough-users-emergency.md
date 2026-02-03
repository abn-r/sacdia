# Walkthrough - Users & Emergency Contacts Modules

**Fecha**: 30 de enero de 2026  
**Duración**: ~60 minutos  
**Fase completada**: 3 (Users + Emergency Contacts)

---

## 🎯 Objetivos Completados

### Fase 3.1: Users Module ✅

1. ✅ CRUD de usuarios
2. ✅ Upload de fotos a Supabase Storage
3. ✅ Validación de formatos (JPG, PNG, WEBP)
4. ✅ Validación de tamaño (máx 5MB)
5. ✅ Cálculo de edad
6. ✅ Verificación de representante legal requerido
7. ✅ 6 endpoints documentados

### Fase 3.2: Emergency Contacts Module ✅

8. ✅ CRUD de contactos de emergencia
9. ✅ Validación máximo 5 contactos por usuario
10. ✅ Prevención de duplicados
11. ✅ Manejo de contacto primario
12. ✅ Soft delete
13. ✅ 5 endpoints documentados

---

## 📦 Dependencias Instaladas

```json
{
  "@nestjs/platform-express": "latest",
  "multer": "2.0.2"
}
```

```json
{
  "@types/multer": "2.0.0"
}
```

---

## 📁 Archivos Creados

### Users Module (4 archivos)

#### 1. [src/users/dto/update-user.dto.ts](file:///Users/abner/Documents/dev/sacdia/sacdia-backend/src/users/dto/update-user.dto.ts)

```typescript
export class UpdateUserDto {
  @IsOptional()
  @IsIn(["M", "F"])
  gender?: "M" | "F";

  @IsOptional()
  @IsDateString()
  birthday?: string;

  @IsOptional()
  @IsBoolean()
  baptism?: boolean;

  @IsOptional()
  @IsDateString()
  @ValidateIf((o) => o.baptism === true)
  baptism_date?: string;

  @IsOptional()
  @IsEnum(blood_type)
  blood?: blood_type; // Enum de Prisma
}
```

**Validaciones**:

- `gender`: Solo 'M' o 'F'
- `birthday`: Formato fecha ISO
- `baptism_date`: Requerido solo si `baptism=true`
- `blood`: Enum de tipos de sangre de Prisma

#### 2. [src/users/users.service.ts](file:///Users/abner/Documents/dev/sacdia/sacdia-backend/src/users/users.service.ts)

**Métodos implementados**:

##### `findOne(userId: string)`

Obtiene información completa del usuario

##### `update(userId: string, dto: UpdateUserDto)`

Actualiza datos personales con validaciones:

- No permite `baptism_date` si `baptism=false`

##### `uploadProfilePicture(userId, file)`

**Validaciones**:

- Formato: JPG, PNG, WEBP
- Tamaño: Máx 5MB

**Flujo**:

1. Validar formato y tamaño
2. Upload a Supabase Storage bucket `profile-pictures`
3. Nombre: `photo-{userId}.{ext}`
4. Opción `upsert: true` (sobrescribe si existe)
5. Obtener URL pública
6. Actualizar `user_image` en BD

```typescript
const { error } = await this.supabase.admin.storage
  .from("profile-pictures")
  .upload(fileName, file.buffer, {
    contentType: file.mimetype,
    upsert: true,
  });

const {
  data: { publicUrl },
} = this.supabase.admin.storage.from("profile-pictures").getPublicUrl(fileName);

await this.prisma.users.update({
  where: { user_id: userId },
  data: { user_image: publicUrl },
});
```

##### `deleteProfilePicture(userId)`

1. Verifica que el usuario tenga foto
2. Elimina de Supabase Storage
3. Actualiza `user_image: null` en BD

##### `calculateAge(userId): number | null`

Calcula edad exacta considerando mes y día

##### `requiresLegalRepresentative(userId): boolean`

Retorna `true` si edad < 18

#### 3. [src/users/users.controller.ts](file:///Users/abner/Documents/dev/sacdia/sacdia-backend/src/users/users.controller.ts)

**Endpoints**:

| Método | Ruta                                           | Descripción              |
| ------ | ---------------------------------------------- | ------------------------ |
| GET    | `/users/:userId`                               | Obtener usuario          |
| PATCH  | `/users/:userId`                               | Actualizar info personal |
| POST   | `/users/:userId/profile-picture`               | Subir foto               |
| DELETE | `/users/:userId/profile-picture`               | Eliminar foto            |
| GET    | `/users/:userId/age`                           | Calcular edad            |
| GET    | `/users/:userId/requires-legal-representative` | Verificar si < 18        |

**Upload con validación**:

```typescript
@Post(':userId/profile-picture')
@UseInterceptors(FileInterceptor('file'))
@ApiConsumes('multipart/form-data')
async uploadProfilePicture(
  @Param('userId') userId: string,
  @UploadedFile(
    new ParseFilePipe({
      validators: [
        new MaxFileSizeValidator({ maxSize: 5 * 1024 * 1024 }),
        new FileTypeValidator({ fileType: /(jpg|jpeg|png|webp)$/ }),
      ],
    }),
  )
  file: Express.Multer.File,
) {
  return this.usersService.uploadProfilePicture(userId, file);
}
```

#### 4. [src/users/users.module.ts](file:///Users/abner/Documents/dev/sacdia/sacdia-backend/src/users/users.module.ts)

```typescript
@Module({
  controllers: [UsersController],
  providers: [UsersService, SupabaseService],
  exports: [UsersService], // Para usar en otros módulos
})
export class UsersModule {}
```

---

### Emergency Contacts Module (5 archivos)

#### 5. [src/emergency-contacts/dto/create-emergency-contact.dto.ts](file:///Users/abner/Documents/dev/sacdia/sacdia-backend/src/emergency-contacts/dto/create-emergency-contact.dto.ts)

```typescript
export class CreateEmergencyContactDto {
  @IsString()
  @MaxLength(100)
  name: string;

  @IsInt()
  relationship_type: number; // ⚠️ Actualmente Int (pendiente migración a UUID)

  @IsString()
  @MaxLength(20)
  phone: string;

  @IsOptional()
  @IsBoolean()
  primary?: boolean; // Contacto principal
}
```

> [!WARNING]
> El campo `relationship_type` es `Int` porque hace referencia a la tabla antigua `relationship_type` que fue eliminada. Actualmente no tiene FK válida. En una migración futura se debe cambiar a UUID para usar `relationship_types`.

#### 6. [src/emergency-contacts/dto/update-emergency-contact.dto.ts](file:///Users/abner/Documents/dev/sacdia/sacdia-backend/src/emergency-contacts/dto/update-emergency-contact.dto.ts)

```typescript
export class UpdateEmergencyContactDto extends PartialType(
  CreateEmergencyContactDto,
) {}
```

#### 7. [src/emergency-contacts/emergency-contacts.service.ts](file:///Users/abner/Documents/dev/sacdia/sacdia-backend/src/emergency-contacts/emergency-contacts.service.ts)

**Constante**:

```typescript
private readonly MAX_CONTACTS = 5;
```

**Métodos implementados**:

##### `create(userId, dto)`

**Validaciones**:

1. **Máximo 5 contactos activos**

   ```typescript
   if (activeCount >= this.MAX_CONTACTS) {
     throw new BadRequestException("Máximo 5 contactos permitidos");
   }
   ```

2. **No duplicados** (mismo nombre + teléfono)

   ```typescript
   const duplicate = await this.prisma.emergency_contacts.findFirst({
     where: {
       owner_id: userId,
       name: dto.name,
       phone: dto.phone,
       active: true,
     },
   });
   ```

3. **Solo un contacto primario**
   Si marcan `primary: true`, desmarca todos los demás:
   ```typescript
   if (dto.primary) {
     await this.prisma.emergency_contacts.updateMany({
       where: { owner_id: userId, active: true },
       data: { primary: false },
     });
   }
   ```

##### `findAll(userId)`

Retorna contactos ordenados por:

1. Primario primero (`primary: desc`)
2. Fecha de creación (`created_at: asc`)

**Response**:

```json
{
  "status": "success",
  "data": [...],
  "meta": {
    "total": 3,
    "remaining": 2
  }
}
```

##### `update(contactId, userId, dto)`

- Verifica pertenencia al usuario
- Si marcan como primario, desmarca otros
- No permite cambiar `owner_id`

##### `remove(contactId, userId)`

**Soft delete**: Marca `active: false` en lugar de eliminar

```typescript
await this.prisma.emergency_contacts.update({
  where: { emergency_id: contactId },
  data: { active: false },
});
```

#### 8. [src/emergency-contacts/emergency-contacts.controller.ts](file:///Users/abner/Documents/dev/sacdia/sacdia-backend/src/emergency-contacts/emergency-contacts.controller.ts)

**Endpoints**:

| Método | Ruta                                           | Descripción     |
| ------ | ---------------------------------------------- | --------------- |
| POST   | `/users/:userId/emergency-contacts`            | Crear contacto  |
| GET    | `/users/:userId/emergency-contacts`            | Listar todos    |
| GET    | `/users/:userId/emergency-contacts/:contactId` | Obtener uno     |
| PATCH  | `/users/:userId/emergency-contacts/:contactId` | Actualizar      |
| DELETE | `/users/:userId/emergency-contacts/:contactId` | Eliminar (soft) |

**Rutas anidadas**:

```typescript
@Controller('users/:userId/emergency-contacts')
```

Esto genera rutas RESTful anidadas bajo el recurso `users`.

---

## 🧪 Pruebas Manuales

### Users Module

#### 1. Actualizar información personal

```bash
curl -X PATCH http://localhost:3000/users/{userId} \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "gender": "M",
    "birthday": "2000-05-15",
    "baptism": true,
    "baptism_date": "2015-08-20",
    "blood": "A_POSITIVE"
  }'
```

**Response esperado**:

```json
{
  "status": "success",
  "data": {
    "user_id": "uuid",
    "gender": "M",
    "birthday": "2000-05-15T00:00:00.000Z",
    "baptism": true,
    "baptism_date": "2015-08-20T00:00:00.000Z",
    "blood": "A_POSITIVE",
    ...
  },
  "message": "Usuario actualizado exitosamente"
}
```

---

#### 2. Subir foto de perfil

```bash
curl -X POST http://localhost:3000/users/{userId}/profile-picture \
  -H "Authorization: Bearer {token}" \
  -F "file=@/path/to/photo.jpg"
```

**Validaciones automáticas**:

- ✅ Solo JPG, PNG, WEBP
- ✅ Máximo 5MB
- ❌ Error 400 si no cumple

**Response esperado**:

```json
{
  "status": "success",
  "data": {
    "url": "https://your-project.supabase.co/storage/v1/object/public/profile-pictures/photo-uuid.jpg",
    "fileName": "photo-uuid.jpg"
  },
  "message": "Foto de perfil actualizada exitosamente"
}
```

**Verificación en Supabase**:

1. Ir a Storage → profile-pictures
2. Debe aparecer `photo-{userId}.jpg`

---

#### 3. Calcular edad

```bash
curl -X GET http://localhost:3000/users/{userId}/age \
  -H "Authorization: Bearer {token}"
```

**Response esperado**:

```json
{
  "status": "success",
  "data": {
    "age": 23
  }
}
```

---

#### 4. Verificar si requiere representante legal

```bash
curl -X GET http://localhost:3000/users/{userId}/requires-legal-representative \
  -H "Authorization: Bearer {token}"
```

**Response esperado (menor de 18)**:

```json
{
  "status": "success",
  "data": {
    "required": true,
    "userAge": 15,
    "reason": "Usuario es menor de 18 años"
  }
}
```

**Response esperado (mayor de 18)**:

```json
{
  "status": "success",
  "data": {
    "required": false,
    "userAge": 23,
    "reason": "Usuario es mayor de edad"
  }
}
```

---

### Emergency Contacts Module

#### 5. Crear contacto de emergencia

```bash
curl -X POST http://localhost:3000/users/{userId}/emergency-contacts \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "María García López",
    "relationship_type": 1,
    "phone": "+52 55 1234 5678",
    "primary": true
  }'
```

**Response esperado**:

```json
{
  "status": "success",
  "data": {
    "emergency_id": 1,
    "name": "María García López",
    "relationship_type": 1,
    "phone": "+52 55 1234 5678",
    "primary": true,
    "active": true,
    "owner_id": "uuid",
    "created_at": "2026-01-30T...",
    "modified_at": "2026-01-30T..."
  },
  "message": "Contacto de emergencia creado exitosamente"
}
```

---

#### 6. Intentar crear 6to contacto (validación)

```bash
# Crear 5 contactos primero...
# Luego intentar crear el 6to:

curl -X POST http://localhost:3000/users/{userId}/emergency-contacts \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Sexto Contacto",
    "relationship_type": 1,
    "phone": "+52 55 9999 9999"
  }'
```

**Response esperado (error 400)**:

```json
{
  "statusCode": 400,
  "message": "Máximo 5 contactos de emergencia permitidos",
  "error": "Bad Request"
}
```

---

#### 7. Listar contactos

```bash
curl -X GET http://localhost:3000/users/{userId}/emergency-contacts \
  -H "Authorization: Bearer {token}"
```

**Response esperado**:

```json
{
  "status": "success",
  "data": [
    {
      "emergency_id": 1,
      "name": "María García López",
      "relationship_type": 1,
      "phone": "+52 55 1234 5678",
      "primary": true,
      "created_at": "...",
      "modified_at": "..."
    },
    {
      "emergency_id": 2,
      "name": "Juan Pérez",
      "relationship_type": 2,
      "phone": "+52 55 8888 8888",
      "primary": false,
      "created_at": "...",
      "modified_at": "..."
    }
  ],
  "meta": {
    "total": 2,
    "remaining": 3
  }
}
```

**Orden**:

1. Contacto primario primero
2. Resto por fecha de creación

---

#### 8. Actualizar contacto

```bash
curl -X PATCH http://localhost:3000/users/{userId}/emergency-contacts/2 \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "primary": true,
    "phone": "+52 55 7777 7777"
  }'
```

**Efecto**:

- Contacto ID 2 se marca como primario
- Contacto ID 1 se desmarca automáticamente

---

#### 9. Eliminar contacto (soft delete)

```bash
curl -X DELETE http://localhost:3000/users/{userId}/emergency-contacts/2 \
  -H "Authorization: Bearer {token}"
```

**Response esperado**:

```json
{
  "status": "success",
  "message": "Contacto eliminado exitosamente"
}
```

**Verificación en BD**:

```sql
SELECT * FROM emergency_contacts WHERE emergency_id = 2;
-- active = false
```

---

## 📖 Swagger Documentation

### Users Endpoints

**GET /users/{userId}**

- Requires: Bearer Token
- Response: 200 (User data) | 404 (Not found)

**PATCH /users/{userId}**

- Requires: Bearer Token
- Body: UpdateUserDto
- Response: 200 (Updated) | 404 (Not found)

**POST /users/{userId}/profile-picture**

- Requires: Bearer Token
- Content-Type: multipart/form-data
- Body: `file` (binary)
- Response: 201 (Uploaded) | 400 (Invalid format/size)

**DELETE /users/{userId}/profile-picture**

- Requires: Bearer Token
- Response: 200 (Deleted) | 404 (No picture)

**GET /users/{userId}/age**

- Requires: Bearer Token
- Response: 200 (Age calculated)

**GET /users/{userId}/requires-legal-representative**

- Requires: Bearer Token
- Response: 200 (Required status)

---

### Emergency Contacts Endpoints

**POST /users/{userId}/emergency-contacts**

- Requires: Bearer Token
- Body: CreateEmergencyContactDto
- Response: 201 (Created) | 400 (Max reached)

**GET /users/{userId}/emergency-contacts**

- Requires: Bearer Token
- Response: 200 (List with meta)

**GET /users/{userId}/emergency-contacts/{contactId}**

- Requires: Bearer Token
- Response: 200 (Contact) | 404 (Not found)

**PATCH /users/{userId}/emergency-contacts/{contactId}**

- Requires: Bearer Token
- Body: UpdateEmergencyContactDto
- Response: 200 (Updated) | 404 (Not found)

**DELETE /users/{userId}/emergency-contacts/{contactId}**

- Requires: Bearer Token
- Response: 200 (Deleted) | 404 (Not found)

---

## 🏗️ Estructura Actualizada

```
src/
├── common/
│   ├── guards/
│   │   └── jwt-auth.guard.ts
│   ├── decorators/
│   │   └── current-user.decorator.ts
│   ├── supabase.service.ts
│   └── common.module.ts
│
├── auth/
│   ├── dto/
│   │   ├── register.dto.ts
│   │   ├── login.dto.ts
│   │   └── reset-password-request.dto.ts
│   ├── strategies/
│   │   └── jwt.strategy.ts
│   ├── auth.controller.ts
│   ├── auth.service.ts
│   └── auth.module.ts
│
├── users/                               ✅ NUEVO
│   ├── dto/
│   │   └── update-user.dto.ts           ✅
│   ├── users.controller.ts              ✅
│   ├── users.service.ts                 ✅
│   └── users.module.ts                  ✅
│
├── emergency-contacts/                  ✅ NUEVO
│   ├── dto/
│   │   ├── create-emergency-contact.dto.ts ✅
│   │   └── update-emergency-contact.dto.ts ✅
│   ├── emergency-contacts.controller.ts    ✅
│   ├── emergency-contacts.service.ts       ✅
│   └── emergency-contacts.module.ts        ✅
│
├── prisma/
│   ├── prisma.service.ts
│   └── prisma.module.ts
│
├── app.module.ts
└── main.ts
```

---

## ✅ Checklist de Implementación

### Users Module

- [x] DTO de actualización con validaciones
- [x] Service con 6 métodos
- [x] Upload de fotos a Supabase Storage
- [x] Validación de formatos y tamaño
- [x] Cálculo de edad
- [x] Verificación de representante legal
- [x] Controller con 6 endpoints
- [x] Swagger documentado

### Emergency Contacts Module

- [x] DTOs (Create, Update)
- [x] Service con 5 métodos
- [x] Validación máximo 5 contactos
- [x] Prevención de duplicados
- [x] Manejo de contacto primario
- [x] Soft delete
- [x] Controller con 5 endpoints
- [x] Rutas anidadas RESTful
- [x] Swagger documentado

### Verificación

- [x] Build exitoso
- [x] Corrección de errores Prisma (emergency_id, blood_type)
- [x] Todos los endpoints expuestos

---

## 📊 Estadísticas

| Métrica                 | Valor                     |
| ----------------------- | ------------------------- |
| **Archivos creados**    | 12                        |
| **DTOs**                | 3                         |
| **Services**            | 2                         |
| **Controllers**         | 2                         |
| **Endpoints totales**   | 11 (6 Users + 5 Contacts) |
| **Líneas de código**    | ~800                      |
| **Validaciones custom** | 5                         |

---

## 🔧 Configuración de Supabase Storage

### Crear bucket `profile-pictures`

**SQL**:

```sql
-- 1. Crear bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-pictures', 'profile-pictures', true);

-- 2. Permitir uploads autenticados
CREATE POLICY "Authenticated users can upload"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'profile-pictures');

-- 3. Permitir acceso público a lectura
CREATE POLICY "Public read access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'profile-pictures');

-- 4. Permitir actualizar propias fotos
CREATE POLICY "Users can update own pictures"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'profile-pictures');
```

**O desde Supabase Dashboard**:

1. Ir a Storage
2. Create Bucket: `profile-pictures`
3. Public Bucket: ✅ Yes
4. File size limit: 5MB
5. Allowed MIME types: `image/jpeg, image/png, image/webp`

---

## ⚠️ Pendientes Identificados

### 1. Migración de `relationship_type`

> [!CAUTION]
> **Problema**: `emergency_contacts.relationship_type` es `Int` sin FK válida (la tabla `relationship_type` original fue eliminada).

**Solución recomendada**:

1. Crear migración para cambiar tipo a `String @db.Uuid`
2. Agregar FK a `relationship_types`
3. Migrar datos existentes (si hay)
4. Actualizar DTO para usar UUID

**SQL ejemplo**:

```sql
-- Paso 1: Agregar nueva columna
ALTER TABLE emergency_contacts
ADD COLUMN relationship_type_id UUID;

-- Paso 2: Migrar datos (mapeo manual)
-- ...

-- Paso 3: Eliminar columna antigua
ALTER TABLE emergency_contacts
DROP COLUMN relationship_type;

-- Paso 4: Renombrar
ALTER TABLE emergency_contacts
RENAME COLUMN relationship_type_id TO relationship_type;

-- Paso 5: Agregar FK
ALTER TABLE emergency_contacts
ADD CONSTRAINT fk_relationship_type
FOREIGN KEY (relationship_type)
REFERENCES relationship_types(relationship_type_id);
```

---

## 🚀 Próximos Pasos

### Fase 4: Legal Representatives (Día 7)

1. Crear módulo `LegalRepresentatives`
2. Validar edad < 18
3. Soportar usuario registrado O datos manuales
4. Máximo 1 por usuario

### Fase 5: Post-Registration (Días 8-9)

1. Crear módulo `PostRegistration`
2. Paso 1: Marcar foto completa
3. Paso 2: Validar info personal + contactos
4. Paso 3: Transacción de club selection

### Fase 6: Catalogs (Día 8)

1. Crear módulo `Catalogs`
2. Endpoints para países, uniones, campos, clubes
3. Cascadas jerárquicas
4. Cache opcional

---

## 🎯 Lecciones Aprendidas

### ✅ Buenas Prácticas

1. **Rutas anidadas RESTful** - `/users/:userId/emergency-contacts`
2. **Validación de archivos** - ParseFilePipe + validators
3. **Soft deletes** - Mejor trazabilidad
4. **Prevención de duplicados** - Antes de INSERT
5. **Manejo de contacto primario** - Desmarca automático

### ⚠️ Consideraciones

1. **Bucket de Supabase** - Debe estar creado antes de usar
2. **Errors de Prisma** - Verificar nombres exactos de campos
3. **Enums de Prisma** - Importar desde `@prisma/client`
4. **File size** - Validar antes de upload (evitar costos)

---

**Status final**: ✅ **Fase 3 COMPLETADA**

**Total endpoints**: 18 (7 Auth + 6 Users + 5 Emergency Contacts)

**Build**: ✅ Exitoso

**Próxima fase**: Legal Representatives module
