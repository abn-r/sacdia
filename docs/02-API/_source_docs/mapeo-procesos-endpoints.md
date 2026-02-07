# Mapeo Procesos → Endpoints - SACDIA API v2.0

**Versión**: 2.0.0 (Actualizada)  
**Fecha**: 29 de enero de 2026  
**Base**: `docs/procesos-sacdia.md` + `docs/restapi/restructura-roles.md`

---

## 📖 Decisiones Aplicadas

✅ Nombres: `paternal_last_name`, `maternal_last_name`  
✅ Roles: `role_category` (GLOBAL | CLUB)  
✅ `legal_representatives`: Nueva tabla  
✅ `users_pr`: Tracking granular  
✅ `club_role_assignments`: Con `ecclesiastical_year_id`  
✅ Contactos: Máximo 5 por usuario

---

## MÓDULO: Autenticación

### PROCESO 1: Inicio de Sesión

#### Endpoint Principal
```http
POST /api/v1/auth/login
```

**Request Body**:
```typescript
{
  email: string;
  password: string;
}
```

**Response Success (200)**:
```json
{
  "status": "success",
  "data": {
    "accessToken": "jwt_token",
    "refreshToken": "refresh_token",
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "name": "John",
      "paternal_last_name": "Doe",
      "maternal_last_name": "Smith"
    },
    "needsPostRegistration": true
  }
}
```

---

### PROCESO 2: Registro de Usuarios

#### Endpoint
```http
POST /api/v1/auth/register
```

**Request Body** (✅ Nombres actualizados):
```typescript
{
  name: string;
  paternal_last_name: string;  // ✅ Descriptivo
  maternal_last_name: string;  // ✅ Descriptivo
  email: string;
  password: string;
}
```

**Implementación Backend** (✅ Con users_pr tracking):
```typescript
@Injectable()
export class AuthService {
  async register(dto: RegisterDto): Promise<RegisterResponse> {
    return await this.prisma.$transaction(async (tx) => {
      // 1. Crear usuario en Supabase Auth
      const { data: authUser, error } = await this.supabase.auth.signUp({
        email: dto.email,
        password: dto.password,
      });
      
      if (error) throw new BadRequestException(error.message);

      // 2. Crear en tabla users
      const user = await tx.users.create({
        data: {
          id: authUser.user.id,
          email: dto.email,
          name: dto.name,
          paternal_last_name: dto.paternal_last_name,  // ✅
          maternal_last_name: dto.maternal_last_name,  // ✅
        },
      });

      // 3. ✅ Crear en users_pr con tracking granular
      await tx.users_pr.create({
        data: {
          user_id: user.id,
          complete: false,
          profile_picture_complete: false,
          personal_info_complete: false,
          club_selection_complete: false,
        },
      });

      // 4. ✅ Asignar rol "user" (GLOBAL)
      const userRole = await tx.roles.findFirst({
        where: { 
          role_name: 'user',
          role_category: 'GLOBAL'  // ✅ Filtro por categoría
        },
      });

      await tx.users_roles.create({
        data: {
          user_id: user.id,
          role_id: userRole.id,
        },
      });

      return { success: true, userId: user.id };
    });
  }
}
```

---

### PROCESO 3: Recuperar Contraseña

```http
POST /api/v1/auth/password/reset-request
Body: { email: string }

POST /api/v1/auth/password/reset
Body: { token: string, newPassword: string }
```

---

### PROCESO 4: Cerrar Sesión

```http
POST /api/v1/auth/logout
Authorization: Bearer {token}
```

---

## MÓDULO: Post-Registro

### PROCESO 1: Fotografía de Perfil

#### Verificar Estado
```http
GET /api/v1/auth/profile/completion-status
```

**Response** (✅ Con tracking granular):
```json
{
  "status": "success",
  "data": {
    "complete": false,
    "steps": {
      "profilePicture": false,
      "personalInfo": false,
      "clubSelection": false
    },
    "nextStep": "profilePicture"
  }
}
```

---

#### Subir Fotografía
```http
POST /api/v1/users/:userId/profile-picture
Content-Type: multipart/form-data
```

**Implementación**:
```typescript
@Post(':userId/profile-picture')
async uploadProfilePicture(
  @Param('userId') userId: string,
  @UploadedFile() file: Express.Multer.File,
) {
  // 1. Validar formato y tamaño
  if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.mimetype)) {
    throw new BadRequestException('Invalid format');
  }

  // 2. Upload a Supabase Storage
  const fileName = `photo-${userId}.${file.mimetype.split('/')[1]}`;
  const { data, error } = await this.supabase.storage
    .from('profile-pictures')
    .upload(fileName, file.buffer, { upsert: true });

  if (error) throw new InternalServerErrorException('Upload failed');

  // 3. Obtener URL pública
  const { data: { publicUrl } } = this.supabase.storage
    .from('profile-pictures')
    .getPublicUrl(fileName);

  // 4. Actualizar users y marcar paso 1 completo
  await this.prisma.$transaction([
    this.prisma.users.update({
      where: { id: userId },
      data: { avatar: publicUrl },
    }),
    this.prisma.users_pr.update({
      where: { user_id: userId },
      data: { profile_picture_complete: true },  // ✅ Marcar paso 1
    }),
  ]);

  return { success: true, url: publicUrl };
}
```

---

### PROCESO 2: Información Personal

#### Actualizar Info Personal
```http
PATCH /api/v1/users/:userId
```

**Request Body**:
```typescript
{
  gender: 'M' | 'F';
  birthdate: string;      // YYYY-MM-DD
  is_baptized: boolean;
  baptism_date?: string;  // Si is_baptized = true
}
```

---

#### Contactos de Emergencia (✅ Máximo 5)

```http
POST /api/v1/users/:userId/emergency-contacts
```

**Implementación con validación**:
```typescript
@Post(':userId/emergency-contacts')
async addEmergencyContact(
  @Param('userId') userId: string,
  @Body() dto: CreateEmergencyContactDto,
) {
  // ✅ Validar máximo 5 contactos
  const count = await this.prisma.emergency_contacts.count({
    where: { user_id: userId }
  });

  if (count >= 5) {
    throw new BadRequestException('Maximum 5 emergency contacts allowed');
  }

  // ✅ Validar no duplicados
  const duplicate = await this.prisma.emergency_contacts.findFirst({
    where: {
      user_id: userId,
      name: dto.name,
      phone: dto.phone
    }
  });

  if (duplicate) {
    throw new ConflictException('Contact already exists');
  }

  const contact = await this.prisma.emergency_contacts.create({
    data: {
      user_id: userId,
      name: dto.name,
      relationship_type_id: dto.relationship_type_id,
      phone: dto.phone,
    },
  });

  return { success: true, data: contact };
}
```

---

#### Alergias y Enfermedades
```http
GET    /api/v1/users/:userId/allergies
POST   /api/v1/users/:userId/allergies
DELETE /api/v1/users/:userId/allergies/:allergyId

GET    /api/v1/users/:userId/diseases
POST   /api/v1/users/:userId/diseases
DELETE /api/v1/users/:userId/diseases/:diseaseId
```

---

#### Completar Paso 2
```http
POST /api/v1/users/:userId/post-registration/complete-step-2
```

**Implementación**:
```typescript
@Post(':userId/post-registration/complete-step-2')
async completePersonalInfo(@Param('userId') userId: string) {
  const user = await this.prisma.users.findUnique({
    where: { id: userId },
    include: {
      emergency_contacts: true,
    },
  });

  // Verificar que datos estén completos
  const isComplete =
    user.gender !== null &&
    user.birthdate !== null &&
    user.is_baptized !== null &&
    user.emergency_contacts.length > 0;

  if (!isComplete) {
    throw new BadRequestException('Información incompleta');
  }

  // ✅ Marcar paso 2 completo
  await this.prisma.users_pr.update({
    where: { user_id: userId },
    data: { personal_info_complete: true },
  });

  return { success: true };
}
```

---

### PROCESO 2.5: Representante Legal (✅ NUEVO - Condicional)

**Trigger**: Si edad < 18 años

#### Verificar Si Requiere
```http
GET /api/v1/users/:userId/requires-legal-representative
```

**Response**:
```json
{
  "required": true,
  "userAge": 15,
  "reason": "Usuario es menor de 18 años"
}
```

---

#### Crear Representante Legal
```http
POST /api/v1/users/:userId/legal-representative
```

**Request Body - Opción A** (Usuario registrado):
```typescript
{
  representative_user_id: "uuid",
  relationship_type_id: "uuid"
}
```

**Request Body - Opción B** (Solo datos):
```typescript
{
  name: "María",
  paternal_last_name: "González",
  maternal_last_name: "López",
  phone: "+52 555 123 4567",
  relationship_type_id: "uuid"  // Padre, Madre, Tutor
}
```

**Implementación**:
```typescript
@Post(':userId/legal-representative')
async createLegalRepresentative(
  @Param('userId') userId: string,
  @Body() dto: CreateLegalRepresentativeDto,
) {
  // 1. Verificar edad < 18
  const user = await this.prisma.users.findUnique({
    where: { id: userId },
    select: { birthdate: true }
  });

  const age = calculateAge(user.birthdate);
  if (age >= 18) {
    throw new BadRequestException('Legal representative only required for minors');
  }

  // 2. Verificar que no tenga ya uno
  const existing = await this.prisma.legal_representatives.findUnique({
    where: { user_id: userId }
  });

  if (existing) {
    throw new ConflictException('User already has a legal representative');
  }

  // 3. Crear representante
  const representative = await this.prisma.legal_representatives.create({
    data: {
      user_id: userId,
      representative_user_id: dto.representative_user_id,
      name: dto.name,
      paternal_last_name: dto.paternal_last_name,
      maternal_last_name: dto.maternal_last_name,
      phone: dto.phone,
      relationship_type_id: dto.relationship_type_id,
    },
  });

  return { success: true, data: representative };
}
```

---

### PROCESO 3: Selección de Club

#### Catálogos
```http
GET /api/v1/catalogs/countries
GET /api/v1/catalogs/countries/:countryId/unions
GET /api/v1/catalogs/unions/:unionId/local-fields
GET /api/v1/catalogs/local-fields/:localFieldId/clubs
GET /api/v1/clubs/:clubId/instances
GET /api/v1/catalogs/classes?clubTypeId={uuid}
```

---

#### Completar Paso 3 (✅ Con ecclesiastical_year_id)
```http
POST /api/v1/users/:userId/post-registration/complete-step-3
```

**Request Body**:
```typescript
{
  countryId: string;
  unionId: string;
  localFieldId: string;
  clubId: string;
  clubType: 'adventurers' | 'pathfinders' | 'master_guild';
  clubInstanceId: number;  // ID de la instancia específica
  classId: string;
}
```

**Implementación** (✅ Con año eclesiástico auto-asignado):
```typescript
@Post(':userId/post-registration/complete-step-3')
async completeClubSelection(
  @Param('userId') userId: string,
  @Body() dto: CompleteClubSelectionDto,
) {
  return await this.prisma.$transaction(async (tx) => {
    // 1. Actualizar país, unión, campo local
    await tx.users.update({
      where: { id: userId },
      data: {
        country_id: dto.countryId,
        union_id: dto.unionId,
        local_field_id: dto.localFieldId,
      },
    });

    // 2. ✅ Obtener año eclesiástico actual (AUTO-ASIGNADO)
    const currentYear = await tx.ecclesiastical_years.findFirst({
      where: {
        start_date: { lte: new Date() },
        end_date: { gte: new Date() }
      }
    });

    if (!currentYear) {
      throw new InternalServerErrorException('No active ecclesiastical year');
    }

    // 3. Obtener rol "member" (CLUB category)
    const memberRole = await tx.roles.findFirst({
      where: { 
        role_name: 'member',
        role_category: 'CLUB'  // ✅ Filtro por categoría
      },
    });

    // 4. ✅ Determinar campo de instancia
    const clubInstanceField = dto.clubType === 'adventurers' ? 'club_adv_id'
      : dto.clubType === 'pathfinders' ? 'club_pathf_id'
      : 'club_mg_id';

    // 5. ✅ Asignar rol "member" en club_role_assignments
    await tx.club_role_assignments.create({
      data: {
        user_id: userId,
        role_id: memberRole.id,
        [clubInstanceField]: dto.clubInstanceId,
        ecclesiastical_year_id: currentYear.id,  // ✅ Auto-asignado
        start_date: new Date(),
        active: true,
        status: 'pending',  // Pendiente de aprobación
      },
    });

    // 6. Inscribir en clase
    await tx.users_classes.create({
      data: {
        user_id: userId,
        class_id: dto.classId,
        current_class: true,
      },
    });

    // 7. ✅ Marcar paso 3 y todo post-registro completo
    await tx.users_pr.update({
      where: { user_id: userId },
      data: {
        club_selection_complete: true,  // ✅ Paso 3
        complete: true,                  // ✅ Todo completo
      },
    });

    return { success: true };
  });
}
```

---

## 📊 Resumen de Endpoints

### Autenticación (6)
```
POST   /api/v1/auth/register
POST   /api/v1/auth/login
POST   /api/v1/auth/logout
POST   /api/v1/auth/password/reset-request
POST   /api/v1/auth/password/reset
GET    /api/v1/auth/me
GET    /api/v1/auth/profile/completion-status
```

### Post-Registro (11)
```
# Paso 1: Fotografía
GET    /api/v1/users/:userId/post-registration/photo-status
POST   /api/v1/users/:userId/profile-picture
DELETE /api/v1/users/:userId/profile-picture

# Paso 2: Info Personal
PATCH  /api/v1/users/:userId
POST   /api/v1/users/:userId/post-registration/complete-step-2

# Paso 2.5: Representante Legal (si edad < 18)
GET    /api/v1/users/:userId/requires-legal-representative  # ✅ NUEVO
POST   /api/v1/users/:userId/legal-representative          # ✅ NUEVO
GET    /api/v1/users/:userId/legal-representative          # ✅ NUEVO
PATCH  /api/v1/users/:userId/legal-representative          # ✅ NUEVO
DELETE /api/v1/users/:userId/legal-representative          # ✅ NUEVO

# Paso 3: Club
POST   /api/v1/users/:userId/post-registration/complete-step-3
```

### Contactos (4)
```
GET    /api/v1/users/:userId/emergency-contacts
POST   /api/v1/users/:userId/emergency-contacts    # ✅ Validación máx 5
PATCH  /api/v1/emergency-contacts/:contactId
DELETE /api/v1/emergency-contacts/:contactId
```

---

## ✅ Checklist de Validaciones

- [x] Nombres de campos descriptivos (`paternal_last_name`, `maternal_last_name`)
- [x] Roles filtrados por `role_category`
- [x] `users_pr` con tracking granular (profile_picture_complete, personal_info_complete, club_selection_complete)
- [x] Auto-asignación de `ecclesiastical_year_id` en club_role_assignments
- [x] Validación máximo 5 contactos de emergencia
- [x] Validación no duplicados en contactos
- [x] Representante legal requerido si edad < 18
- [x] Máximo 1 representante por usuario
- [x] Transacciones completas en registro y post-registro

---

**Generado**: 2026-01-29  
**Versión**: 2.0.0 (Con todas las decisiones finales)  
**Siguiente**: Ver [queries-club-role-assignments.md](file:///Users/abner/Documents/dev/sacdia/docs/restapi/queries-club-role-assignments.md) para queries SQL
