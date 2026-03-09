<!-- CANONICAL-API-NOTE -->
> [!WARNING]
> Este documento puede incluir rutas históricas/propuestas o ejemplos desactualizados.
> Para consumo de agentes (App + Panel), usar como contrato canónico:
> [ENDPOINTS-LIVE-REFERENCE.md](./ENDPOINTS-LIVE-REFERENCE.md)

# Mapeo Procesos → Endpoints - SACDIA API v2.2

**Versión**: 2.2.0 (Actualizada con Módulos Nuevos)
**Fecha**: 21 de febrero de 2026
**Base**: `docs/02-PROCESSES.md` + `docs/history/source/api/restrucura-roles.md` + `docs/03-IMPLEMENTATION-ROADMAP.md`

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
  paternal_last_name: string; // ✅ Descriptivo
  maternal_last_name: string; // ✅ Descriptivo
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
          paternal_last_name: dto.paternal_last_name, // ✅
          maternal_last_name: dto.maternal_last_name, // ✅
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
          role_name: "user",
          role_category: "GLOBAL", // ✅ Filtro por categoría
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
  birthday: string;        // YYYY-MM-DD
  baptism: boolean;
  baptism_date?: string;   // Si baptism = true
  blood?: blood_type;
  country_id?: number;
  union_id?: number;
  local_field_id?: number;
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
GET /api/v1/users/:userId/allergies
GET /api/v1/users/:userId/diseases
PUT /api/v1/users/:userId/allergies
PUT /api/v1/users/:userId/diseases
```

**Lectura - Response 200 Allergies**:

```json
{
  "status": "success",
  "data": [
    { "allergy_id": 1, "name": "Polen" },
    { "allergy_id": 2, "name": "Lactosa" }
  ]
}
```

**Lectura - Response 200 Diseases**:

```json
{
  "status": "success",
  "data": [
    { "disease_id": 10, "name": "Asma" }
  ]
}
```

**Body - Allergies**:

```json
{ "allergy_ids": [1, 2, 3] }
```

**Body - Diseases**:

```json
{ "disease_ids": [10, 12] }
```

Comportamiento:

1. `GET` requiere `users:read_detail` con `@AuthorizationResource({ type: 'user', ownerParam: 'userId' })`.
2. `GET` devuelve una lista plana de selecciones activas (`{ allergy_id, name }` o `{ disease_id, name }`).
3. `GET` responde `200` con `data: []` si el usuario existe pero no tiene selecciones activas.
4. `GET` responde `404` solo cuando el usuario no existe.
5. `PUT` reemplaza el conjunto activo completo del usuario.
6. `PUT` reactiva registros existentes inactivos.
7. `PUT` crea registros nuevos si no existen.
8. `PUT` desactiva (`active=false`) registros activos no enviados.
9. Lista vacía (`[]`) limpia el conjunto activo.

---

#### Completar Paso 2

```http
POST /api/v1/users/:userId/post-registration/step-2/complete
```

**Implementación**:

```typescript
@Post(':userId/post-registration/step-2/complete')
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
POST /api/v1/users/:userId/post-registration/step-3/complete
```

**Request Body**:

```typescript
{
  country_id: number;
  union_id: number;
  local_field_id: number;
  club_type: "adventurers" | "pathfinders" | "master_guild";
  club_instance_id: number; // ID de la instancia específica
  class_id: number;
}
```

**Implementación** (✅ Con año eclesiástico auto-asignado):

```typescript
@Post(':userId/post-registration/step-3/complete')
async completeClubSelection(
  @Param('userId') userId: string,
  @Body() dto: CompleteClubSelectionDto,
) {
  return await this.prisma.$transaction(async (tx) => {
    // 1. Actualizar país, unión, campo local
    await tx.users.update({
      where: { id: userId },
      data: {
        country_id: dto.country_id,
        union_id: dto.union_id,
        local_field_id: dto.local_field_id,
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
    const clubInstanceField = dto.club_type === 'adventurers' ? 'club_adv_id'
      : dto.club_type === 'pathfinders' ? 'club_pathf_id'
      : 'club_mg_id';

    // 5. ✅ Asignar rol "member" en club_role_assignments
    await tx.club_role_assignments.create({
      data: {
        user_id: userId,
        role_id: memberRole.id,
        [clubInstanceField]: dto.club_instance_id,
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
        class_id: dto.class_id,
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

### Post-Registro y Perfil (Actual)

```
# Paso 1: Fotografía
GET    /api/v1/users/:userId/post-registration/status
POST   /api/v1/users/:userId/profile-picture
DELETE /api/v1/users/:userId/profile-picture

# Paso 2: Info Personal
PATCH  /api/v1/users/:userId
GET    /api/v1/users/:userId/allergies
GET    /api/v1/users/:userId/diseases
PUT    /api/v1/users/:userId/allergies
PUT    /api/v1/users/:userId/diseases
POST   /api/v1/users/:userId/post-registration/step-2/complete

# Paso 2.5: Representante Legal (si edad < 18)
GET    /api/v1/users/:userId/requires-legal-representative
POST   /api/v1/users/:userId/legal-representative
GET    /api/v1/users/:userId/legal-representative
PATCH  /api/v1/users/:userId/legal-representative
DELETE /api/v1/users/:userId/legal-representative

# Paso 3: Club
POST   /api/v1/users/:userId/post-registration/step-3/complete
```

### Contactos (5)

```
GET    /api/v1/users/:userId/emergency-contacts
POST   /api/v1/users/:userId/emergency-contacts    # Validación máx 5
GET    /api/v1/users/:userId/emergency-contacts/:contactId
PATCH  /api/v1/users/:userId/emergency-contacts/:contactId
DELETE /api/v1/users/:userId/emergency-contacts/:contactId
```

### Catálogos (10) ✅ NUEVO

```
GET    /api/v1/catalogs/club-types
GET    /api/v1/catalogs/countries
GET    /api/v1/catalogs/unions                     # Query: ?countryId=
GET    /api/v1/catalogs/local-fields               # Query: ?unionId=
GET    /api/v1/catalogs/districts                  # Query: ?localFieldId=
GET    /api/v1/catalogs/churches                   # Query: ?districtId=
GET    /api/v1/catalogs/roles                      # Query: ?category=GLOBAL|CLUB
GET    /api/v1/catalogs/ecclesiastical-years
GET    /api/v1/catalogs/ecclesiastical-years/current
GET    /api/v1/catalogs/club-ideals                # Query: ?clubTypeId=
```

### Clubs (11) ✅ NUEVO

```
# CRUD de Clubs
GET    /api/v1/clubs                               # Query: ?localFieldId, ?districtId, ?churchId, ?active
GET    /api/v1/clubs/:clubId
POST   /api/v1/clubs
PATCH  /api/v1/clubs/:clubId
DELETE /api/v1/clubs/:clubId

# Instancias (Aventureros, Conquistadores, GM)
GET    /api/v1/clubs/:clubId/instances
GET    /api/v1/clubs/:clubId/instances/:type       # type = adventurers|pathfinders|master_guilds
POST   /api/v1/clubs/:clubId/instances
PATCH  /api/v1/clubs/:clubId/instances/:type/:instanceId

# Miembros y Roles
GET    /api/v1/clubs/:clubId/instances/:type/:instanceId/members
POST   /api/v1/clubs/:clubId/instances/:type/:instanceId/roles

# Asignaciones de Rol
PATCH  /api/v1/club-roles/:assignmentId
DELETE /api/v1/club-roles/:assignmentId
```

### Classes (7) ✅ NUEVO

```
# Catálogo de Clases (público)
GET    /api/v1/classes                             # Query: ?clubTypeId=
GET    /api/v1/classes/:classId
GET    /api/v1/classes/:classId/modules

# Inscripciones y Progreso (autenticado)
GET    /api/v1/users/:userId/classes               # Query: ?yearId=
POST   /api/v1/users/:userId/classes/enroll
GET    /api/v1/users/:userId/classes/:classId/progress
PATCH  /api/v1/users/:userId/classes/:classId/progress
```

### Honors (8) ✅ NUEVO

```
# Catálogo de Honores (público)
GET    /api/v1/honors                              # Query: ?categoryId, ?clubTypeId, ?skillLevel
GET    /api/v1/honors/:honorId
GET    /api/v1/honors/categories

# Honores de Usuario (autenticado)
GET    /api/v1/users/:userId/honors                # Query: ?validated
GET    /api/v1/users/:userId/honors/stats
POST   /api/v1/users/:userId/honors/:honorId       # Iniciar honor
PATCH  /api/v1/users/:userId/honors/:honorId       # Actualizar progreso
DELETE /api/v1/users/:userId/honors/:honorId       # Abandonar
```

### Activities (7) ✅ NUEVO

```
# Actividades por Club
GET    /api/v1/clubs/:clubId/activities            # Query: ?clubTypeId, ?active, ?activityType
POST   /api/v1/clubs/:clubId/activities

# Actividad Individual
GET    /api/v1/activities/:activityId
PATCH  /api/v1/activities/:activityId
DELETE /api/v1/activities/:activityId

# Asistencia
POST   /api/v1/activities/:activityId/attendance
GET    /api/v1/activities/:activityId/attendance
```

### Finances (7) ✅ NUEVO

```
# Categorías Financieras
GET    /api/v1/finances/categories                 # Query: ?type (0=Ingreso, 1=Egreso)

# Finanzas por Club
GET    /api/v1/clubs/:clubId/finances              # Query: ?year, ?month, ?clubTypeId, ?categoryId
GET    /api/v1/clubs/:clubId/finances/summary
POST   /api/v1/clubs/:clubId/finances

# Movimiento Individual
GET    /api/v1/finances/:financeId
PATCH  /api/v1/finances/:financeId
DELETE /api/v1/finances/:financeId
```

### Campaments/Camporees (8) ✅ NUEVO

```
# Listar Campamentos
GET    /api/v1/camporees                               # Query: ?page, ?limit, ?type (local|union)

# Crear Campamento (Director/Subdirector)
POST   /api/v1/camporees

# Campamento Individual
GET    /api/v1/camporees/:id
PATCH  /api/v1/camporees/:id                           # Director/Subdirector
DELETE /api/v1/camporees/:id                           # Director only

# Registro de Miembros (con validación de seguro)
POST   /api/v1/camporees/:id/register
GET    /api/v1/camporees/:id/members
DELETE /api/v1/camporees/:id/members/:userId
```

**Request Body - Crear Campamento**:

```typescript
{
  name: string;
  description?: string;
  start_date: string;           // ISO 8601
  end_date: string;
  local_field_id: number;
  includes_adventurers: boolean;
  includes_pathfinders: boolean;
  includes_master_guides: boolean;
  local_camporee_place: string;
  registration_cost?: number;
}
```

**Request Body - Registrar Miembro**:

```typescript
{
  user_id: string;
  camporee_type: 'local' | 'union';
  club_name?: string;
  insurance_id?: number;        // FK a member_insurances (REQUERIDO)
}
```

**Validaciones Críticas**:

- ✅ Validar seguro activo tipo CAMPOREE
- ✅ Validar fecha de vencimiento del seguro > fecha fin del campamento
- ✅ Usar transacciones para registro de miembros

---

### Folders/Portfolios (7) ✅ NUEVO

```
# Templates de Folders (público)
GET    /api/v1/folders                                 # Query: ?clubTypeId, ?ecclesiasticalYearId
GET    /api/v1/folders/:id
POST   /api/v1/folders                                 # Admin only

# Folders de Usuario (autenticado)
GET    /api/v1/users/:userId/folders
POST   /api/v1/users/:userId/folders/:folderId/enroll
GET    /api/v1/users/:userId/folders/:folderId/progress
PATCH  /api/v1/users/:userId/folders/:folderId/modules/:moduleId/sections/:sectionId
```

**Request Body - Crear Folder Template**:

```typescript
{
  name: string;
  description?: string;
  club_type?: number;           // 1=Aventureros, 2=Conquistadores, 3=GM
  ecclesiastical_year_id?: number;
  max_points?: number;
  minimum_points?: number;
}
```

**Request Body - Actualizar Progreso de Sección**:

```typescript
{
  points: number;
  evidences?: Record<string, any>; // JSON con archivos/fotos
}
```

**Response - Progreso de Folder**:

```json
{
  "folder_id": 1,
  "status": "active",
  "progress_percentage": 65.5,
  "total_points": 131,
  "max_points": 200,
  "modules": [
    {
      "module_id": 1,
      "name": "Módulo 1",
      "progress": 80,
      "sections": [
        {
          "section_id": 1,
          "name": "Sección 1.1",
          "points": 10,
          "max_points": 10,
          "completed": true
        }
      ]
    }
  ]
}
```

---

### Certifications (7) ✅ NUEVO

**Restricción**: Solo Guías Mayores investidos

```
# Catálogo de Certificaciones (público)
GET    /api/v1/certifications
GET    /api/v1/certifications/:id

# Inscripciones (autenticado - solo GM investidos)
POST   /api/v1/users/:userId/certifications/enroll
GET    /api/v1/users/:userId/certifications
GET    /api/v1/users/:userId/certifications/:certificationId/progress
PATCH  /api/v1/users/:userId/certifications/:certificationId/progress
DELETE /api/v1/users/:userId/certifications/:certificationId
```

**Request Body - Inscripción**:

```typescript
{
  certification_id: number;
}
```

**Validación de Elegibilidad**:

```typescript
// Backend valida:
// 1. Usuario tiene clase "Guía Mayor"
// 2. Campo investiture = true
// 3. Permite múltiples inscripciones simultáneas (a diferencia de classes)
```

**Estructura Similar a Classes**:

- Módulos y secciones
- Progreso por sección
- Tracking de completion_status
- Sin restricción de inscripción única

---

### Inventory (5) ✅ NUEVO

```
# Inventario por Club Instance
GET    /api/v1/clubs/:clubId/inventory                 # Query: ?instanceType (adv|pathf|mg)
POST   /api/v1/clubs/:clubId/inventory                 # Director/Subdirector/Tesorero
PATCH  /api/v1/inventory/:id
DELETE /api/v1/inventory/:id                           # Director only

# Catálogo de Categorías
GET    /api/v1/catalogs/inventory-categories
```

**Request Body - Crear Item**:

```typescript
{
  name: string;
  description?: string;
  inventory_category_id?: number;
  amount: number;
  // Uno de estos tres (según instanceType):
  club_adv_id?: number;
  club_pathf_id?: number;
  club_mg_id?: number;
}
```

**Response - Lista de Inventario**:

```json
{
  "data": [
    {
      "inventory_id": 1,
      "name": "Cuerdas 10m",
      "description": "Para campamentos",
      "category": {
        "category_id": 1,
        "name": "Material de Campismo"
      },
      "amount": 15,
      "active": true,
      "created_at": "2026-02-01T10:00:00Z"
    }
  ]
}
```

---

### OAuth (5) ✅ IMPLEMENTADO

**Fecha**: 5 de febrero de 2026
**Archivos**: `oauth.controller.ts`, `oauth.service.ts`

**Providers**: Google, Apple

```
# Iniciar OAuth Flow
POST   /api/v1/auth/oauth/google
POST   /api/v1/auth/oauth/apple

# Manejar Callback
GET    /api/v1/auth/oauth/callback

# Gestión de Providers (Auth required)
GET    /api/v1/auth/oauth/providers                    # Auth required
DELETE /api/v1/auth/oauth/:provider                    # Auth required
```

**Request Body - Iniciar OAuth**:

```typescript
{
  redirectUrl?: string;         // Default: https://sacdia.app/auth/callback
}
```

**Response - Iniciar OAuth**:

```json
{
  "url": "https://accounts.google.com/o/oauth2/v2/auth?..."
}
```

**Response - Callback**:

```json
{
  "access_token": "jwt_token",
  "user": {
    "id": "uuid",
    "email": "user@gmail.com",
    "google_connected": true,
    "apple_connected": false
  }
}
```

**Flags en BD**:

- `users.google_connected` (boolean)
- `users.apple_connected` (boolean)
- `users.fb_connected` (boolean) - reservado

---

### Push Notifications (6) ✅ ACTUALIZADO

**Tecnología**: Firebase Cloud Messaging (FCM)

```
# Gestión de Tokens FCM (JWT requerido)
POST   /api/v1/fcm-tokens
GET    /api/v1/fcm-tokens
DELETE /api/v1/fcm-tokens/:token
GET    /api/v1/fcm-tokens/user/:userId        # owner/admin (compatibilidad)

# Envío de notificaciones
POST   /api/v1/notifications/send             # JWT requerido
POST   /api/v1/notifications/broadcast        # solo admin|super_admin
POST   /api/v1/notifications/club/:type/:id   # solo admin|super_admin
```

**Request Body - Registrar Token**:

```typescript
{
  token: string;                // Token FCM del dispositivo
  device_type?: 'ios' | 'android' | 'web';
  device_name?: string;
}
```

**Nota de contrato**:
- `userId` ya no se envía en body al registrar token.
- El backend toma `userId` desde el JWT autenticado.

**Tabla en BD**: `user_fcm_tokens`

- Auto-cleanup de tokens inválidos
- Validación de ownership para baja/listado de tokens

---

### WebSockets (Real-time) ✅ OPCIONAL

**Namespace**: `/api/v1/ws`

**Eventos Cliente → Servidor**:

```typescript
// Unirse a sala de club
socket.emit("join-club", { clubId: number });

// Salir de sala de club
socket.emit("leave-club", { clubId: number });
```

**Eventos Servidor → Cliente**:

```typescript
// Progreso de clase actualizado
'class-updated' → { classId: number, progress: number }

// Progreso individual
'class-progress-updated' → { classId: number, progress: number }

// Nueva actividad creada
'activity-created' → { activityId: number, clubId: number }

// Nuevo miembro
'member-joined' → { userId: string, clubId: number }

// Notificación general
'notification' → { title: string, body: string, data: any }
```

**Autenticación**:

```typescript
const socket = io("http://localhost:3000/api/v1/ws", {
  auth: {
    token: "jwt_token", // O query: { token: 'jwt_token' }
  },
});
```

**Guards**: `WsJwtGuard` valida token en handshake

---

## 📊 Resumen Actualizado de Endpoints

### Total por Módulo

- Autenticación: 7 endpoints (incluye OAuth)
- Post-Registro: 11 endpoints
- Contactos: 4 endpoints
- Representantes Legales: 4 endpoints
- Catálogos: 11 endpoints
- Clubs: 11 endpoints
- Classes: 7 endpoints
- Honors: 8 endpoints
- Activities: 7 endpoints
- Finances: 7 endpoints
- **Campaments: 8 endpoints** ✅ NUEVO
- **Folders: 7 endpoints** ✅ NUEVO
- **Certifications: 7 endpoints** ✅ NUEVO
- **Inventory: 5 endpoints** ✅ NUEVO
- **OAuth: 5 endpoints** ✅ NUEVO
- **Push Notifications: 3 endpoints** ✅ NUEVO
- **WebSockets: Gateway + eventos** ✅ OPCIONAL

**Total Endpoints REST**: **105+ endpoints**
**Total Módulos**: **17 módulos**

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
- [x] Endpoints de catálogos con filtros jerárquicos
- [x] Gestión de instancias de club por tipo
- [x] Sistema de progreso por secciones y módulos
- [x] Honores con validación de instructor
- [x] Actividades con geolocalización y asistencia
- [x] Finanzas con categorías y resúmenes
- [x] Campamentos con validación de seguros
- [x] Folders/Portfolios con progreso por módulos
- [x] Certificaciones exclusivas para GM investidos
- [x] Sistema de inventario por instancia de club
- [x] OAuth con Google y Apple
- [x] Push notifications con FCM
- [x] WebSockets para actualizaciones en tiempo real

---

**Generado**: 2026-01-29
**Actualizado**: 2026-02-05
**Versión**: 2.2.0 (Con 17 módulos completos - Backend implementado 100%)
**Total Endpoints REST**: 105+
**WebSockets**: Gateway + eventos real-time
**Implementación**: Certifications, Folders, Inventory implementados en esta sesión
