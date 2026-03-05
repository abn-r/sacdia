# Plan de Actualización - Documentos Técnicos SACDIA

**Fecha**: 29 de enero de 2026  
**Objetivo**: Alinear todos los documentos con decisiones finales

---

## 📋 Decisiones Implementadas

1. ✅ Nombres de campos: `paternal_last_name`, `maternal_last_name`
2. ✅ `users_pr`: Tracking individual (Opción B)
3. ✅ Representante legal: Nueva tabla `legal_representatives`
4. ✅ Año eclesiástico: Auto-asignado (nunca seleccionado por usuario)
5. ✅ Membresía: Todos tienen rol en `club_role_assignments`

---

## 🔄 Cambios en Especificación Técnica

### Archivo: `especificacion-tecnica-nueva-api.md`

#### 1. Actualizar DTOs (Sección: DTOs y Validación)

**ANTES**:
```typescript
export class CreateActivityDto {
  @IsString()
  @IsNotEmpty()
  title: string;
  // ...
}
```

**DESPUÉS** (agregar nueva sección):
```typescript
// === DTOs de Usuario ===

export class RegisterDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  paternal_last_name: string;  // ✅ Cambio: era p_lastname

  @IsString()
  @IsNotEmpty()
  maternal_last_name: string;  // ✅ Cambio: era m_lastname

  @IsEmail()
  email: string;

  @IsString()
  @MinLength(8)
  password: string;
}

export class UpdatePersonalInfoDto {
  @IsEnum(['M', 'F'])
  gender: string;

  @IsDateString()
  @Validate(AgeValidator, { min: 3, max: 99 })
  birthdate: string;

  @IsBoolean()
  is_baptized: boolean;

  @IsOptional()
  @IsDateString()
  @ValidateIf(o => o.is_baptized === true)
  baptism_date?: string;
}

// === DTOs de Representante Legal ===

export class CreateLegalRepresentativeDto {
  // Opción 1: Es usuario registrado
  @IsOptional()
  @IsUUID()
  representative_user_id?: string;

  // Opción 2: Solo datos
  @IsOptional()
  @IsString()
  @ValidateIf(o => !o.representative_user_id)
  name?: string;

  @IsOptional()
  @IsString()
  @ValidateIf(o => !o.representative_user_id)
  paternal_last_name?: string;

  @IsOptional()
  @IsString()
  @ValidateIf(o => !o.representative_user_id)
  maternal_last_name?: string;

  @IsOptional()
  @IsString()
  @ValidateIf(o => !o.representative_user_id)
  phone?: string;

  @IsUUID()
  relationship_type_id: string;
}

// === Validador de Edad ===

@ValidatorConstraint({ name: 'AgeValidator', async: false })
export class AgeValidator implements ValidatorConstraintInterface {
  validate(birthdate: string, args: ValidationArguments) {
    const { min, max } = args.constraints[0];
    const age = calculateAge(birthdate);
    return age >= min && age <= max;
  }

  defaultMessage(args: ValidationArguments) {
    const { min, max } = args.constraints[0];
    return `Age must be between ${min} and ${max} years`;
  }
}

function calculateAge(birthdate: string): number {
  const today = new Date();
  const birth = new Date(birthdate);
  let age = today.getFullYear() - birth.getFullYear();
  const monthDiff = today.getMonth() - birth.getMonth();
  
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
    age--;
  }
  
  return age;
}
```

#### 2. Agregar Módulo Legal Representatives

**DESPUÉS de Módulo Users** (agregar nueva sección):

```markdown
### 3. Módulo Legal Representatives
**Responsabilidad**: Gestión de representantes legales para menores de 18 años

**Tabla principal**: `legal_representatives`

**Endpoints**:
\`\`\`typescript
POST   /api/v1/users/:userId/legal-representative
GET    /api/v1/users/:userId/legal-representative
PATCH  /api/v1/users/:userId/legal-representative
DELETE /api/v1/users/:userId/legal-representative
\`\`\`

**Validaciones**:
- Solo requerido si edad < 18 años
- Máximo 1 representante por usuario
- Puede ser usuario registrado o solo datos
```

#### 3. Actualizar Sistema de Roles (Sección: Sistema de Permisos)

**AGREGAR antes de "Roles Globales"**:

```markdown
### Categorías de Roles

Los roles se clasifican en dos categorías mediante el campo `role_category`:

**GLOBAL**: Roles que aplican a todo el sistema
- Almacenados en: `users_roles`
- Ejemplos: super_admin, admin, coordinator, user

**CLUB**: Roles específicos de instancias de club
- Almacenados en: `club_role_assignments`
- Vinculados a: ecclesiastical_year, club_instance
- Ejemplos: director, subdirector, secretary, treasurer, counselor, member

**Tabla `roles`**:
\`\`\`sql
CREATE TABLE roles (
  id UUID PRIMARY KEY,
  role_name VARCHAR(50) UNIQUE NOT NULL,
  role_category VARCHAR(10) NOT NULL CHECK (role_category IN ('GLOBAL', 'CLUB')),
  description TEXT,
  active BOOLEAN DEFAULT true
);
\`\`\`
```

#### 4. Actualizar Tabla users_pr

**REEMPLAZAR sección actual** con:

```markdown
### Tabla `users_pr` - Post-Registro

Tracking detallado del progreso de post-registro:

\`\`\`sql
CREATE TABLE users_pr (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  complete BOOLEAN DEFAULT false,
  profile_picture_complete BOOLEAN DEFAULT false,
  personal_info_complete BOOLEAN DEFAULT false,
  club_selection_complete BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
\`\`\`

**Flujo**:
1. Foto subida → `profile_picture_complete = true`
2. Info personal guardada → `personal_info_complete = true`
3. Club seleccionado → `club_selection_complete = true` AND `complete = true`

**Endpoints de verificación**:
\`\`\`typescript
GET /api/v1/auth/profile/completion-status

Response:
{
  "complete": false,
  "steps": {
    "profilePicture": true,    // Paso 1 completo
    "personalInfo": false,     // Paso 2 pendiente
    "clubSelection": false     // Paso 3 pendiente
  },
  "nextStep": "personalInfo"   // Siguiente paso a mostrar
}
\`\`\`
```

---

## 🔄 Cambios en Mapeo de Procesos

### Archivo: `mapeo-procesos-endpoints.md`

#### 1. Actualizar PROCESO 2 (Registro)

**EN la sección Request Body**, CAMBIAR nombres:

```typescript
// ANTES
{
  name: string;
  p_lastname: string;
  m_lastname: string;
  // ...
}

// DESPUÉS
{
  name: string;
  paternal_last_name: string;  // ✅ Descriptivo
  maternal_last_name: string;  // ✅ Descriptivo
  email: string;
  password: string;
  confirmPassword: string;
}
```

#### 2. Actualizar Implementación de Registro (Backend)

**REEMPLAZAR** implementación transaccional con:

```typescript
@Injectable()
export class AuthService {
  async register(dto: RegisterDto): Promise<RegisterResponse> {
    return await this.prisma.$transaction(async (tx) => {
      try {
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
            paternal_last_name: dto.paternal_last_name,  // ✅ Actualizado
            maternal_last_name: dto.maternal_last_name,  // ✅ Actualizado
          },
        });

        // 3. Crear registro en users_pr con tracking
        await tx.users_pr.create({
          data: {
            user_id: user.id,
            complete: false,
            profile_picture_complete: false,  // ✅ Nuevo
            personal_info_complete: false,    // ✅ Nuevo
            club_selection_complete: false,   // ✅ Nuevo
          },
        });

        // 4. Asignar rol "user" (GLOBAL)
        const userRole = await tx.roles.findFirst({
          where: { 
            role_name: 'user',
            role_category: 'GLOBAL'  // ✅ Nuevo filtro
          },
        });

        await tx.users_roles.create({
          data: {
            user_id: user.id,
            role_id: userRole.id,
          },
        });

        return {
          success: true,
          userId: user.id,
          email: user.email,
        };
      } catch (error) {
        await this.logService.error('REGISTER_FAILED', error);
        throw error;
      }
    });
  }
}
```

#### 3. AGREGAR Proceso Post-Registro - Paso 1.5 (Representante Legal)

**AGREGAR nueva sección DESPUÉS de Proceso 1 (Fotografía)**:

```markdown
### PROCESO 1.5: Representante Legal (Condicional)

**Objetivo**: Registrar representante legal si el usuario es menor de 18 años.

**Trigger**: Después de completar fotografía, al verificar edad en info personal.

#### Endpoint de Verificación
\`\`\`http
GET /api/v1/users/:userId/requires-legal-representative
Authorization: Bearer {token}
\`\`\`

**Response**:
\`\`\`json
{
  "status": "success",
  "data": {
    "required": true,
    "userAge": 15,
    "reason": "Usuario es menor de 18 años"
  }
}
\`\`\`

---

#### Endpoints de Gestión

##### 1. Crear Representante Legal
\`\`\`http
POST /api/v1/users/:userId/legal-representative
Authorization: Bearer {token}
\`\`\`

**Request Body - Opción A (Usuario registrado)**:
\`\`\`typescript
{
  representative_user_id: "uuid-del-usuario",
  relationship_type_id: "uuid-tipo-relacion"
}
\`\`\`

**Request Body - Opción B (Solo datos)**:
\`\`\`typescript
{
  name: "María",
  paternal_last_name: "González",
  maternal_last_name: "López",
  phone: "+52 555 123 4567",
  relationship_type_id: "uuid-tipo-relacion"  // Madre, Padre, Tutor
}
\`\`\`

**Implementación**:
\`\`\`typescript
@Post(':userId/legal-representative')
@UseGuards(SupabaseGuard)
async createLegalRepresentative(
  @Param('userId') userId: string,
  @Body() dto: CreateLegalRepresentativeDto,
) {
  // 1. Verificar que usuario sea menor de 18
  const user = await this.prisma.users.findUnique({
    where: { id: userId },
    select: { birthdate: true }
  });

  const age = calculateAge(user.birthdate);
  if (age >= 18) {
    throw new BadRequestException('Legal representative only required for minors');
  }

  // 2. Verificar que no tenga ya un representante
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
\`\`\`

---

##### 2. Obtener Representante Legal
\`\`\`http
GET /api/v1/users/:userId/legal-representative
\`\`\`

---

##### 3. Actualizar Representante Legal
\`\`\`http
PATCH /api/v1/users/:userId/legal-representative
\`\`\`

---

##### 4. Eliminar Representante Legal
\`\`\`http
DELETE /api/v1/users/:userId/legal-representative
\`\`\`

**Nota**: Solo permite eliminar si usuario ya tiene 18+ años.
```

#### 4. Actualizar PROCESO 2 - Validación de Contactos

**AGREGAR validación de límite**:

```typescript
@Post(':userId/emergency-contacts')
@UseGuards(SupabaseGuard)
async addEmergencyContact(
  @Param('userId') userId: string,
  @Body() dto: CreateEmergencyContactDto,
) {
  // ✅ NUEVO: Validar máximo 5 contactos
  const count = await this.prisma.emergency_contacts.count({
    where: { user_id: userId }
  });

  if (count >= 5) {
    throw new BadRequestException('Maximum 5 emergency contacts allowed');
  }

  // ✅ NUEVO: Validar no duplicados (nombre + teléfono)
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

#### 5. Actualizar PROCESO 3 - Selección de Club

**REEMPLAZAR** implementación completa con:

```typescript
@Post(':userId/post-registration/complete-step-3')
@UseGuards(SupabaseGuard)
async completeClubSelection(
  @Param('userId') userId: string,
  @Body() dto: CompleteClubSelectionDto,
) {
  return await this.prisma.$transaction(async (tx) => {
    // 1. Actualizar país, unión, campo local en users
    await tx.users.update({
      where: { id: userId },
      data: {
        country_id: dto.countryId,
        union_id: dto.unionId,
        local_field_id: dto.localFieldId,
      },
    });

    // 2. ✅ NUEVO: Obtener año eclesiástico actual
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
        role_category: 'CLUB'  // ✅ Nuevo filtro
      },
    });

    // 4. Asignar a club con rol "member"
    const clubInstanceField = dto.clubType === 'adventurers' ? 'club_adv_id'
      : dto.clubType === 'pathfinders' ? 'club_pathf_id'
      : 'club_mg_id';

    await tx.club_role_assignments.create({
      data: {
        user_id: userId,
        role_id: memberRole.id,
        [clubInstanceField]: dto.clubInstanceId,
        ecclesiastical_year_id: currentYear.id,  // ✅ Auto-asignado
        start_date: new Date(),
        active: true,
        status: 'pending',
      },
    });

    // 5. Inscribir en clase
    await tx.users_classes.create({
      data: {
        user_id: userId,
        class_id: dto.classId,
        current_class: true,
      },
    });

    // 6. ✅ NUEVO: Marcar post-registro como completo con tracking
    await tx.users_pr.update({
      where: { user_id: userId },
      data: {
        club_selection_complete: true,  // ✅ Paso 3 completo
        complete: true,                  // ✅ Todo completo
      },
    });

    return { success: true };
  });
}
```

---

## 📊 Resumen de Nuevos Endpoints

### Módulo Auth
- `GET /api/v1/auth/profile/completion-status` (actualizado con tracking)

### Módulo Users - Legal Representatives
- `GET /api/v1/users/:userId/requires-legal-representative`
- `POST /api/v1/users/:userId/legal-representative`
- `GET /api/v1/users/:userId/legal-representative`
- `PATCH /api/v1/users/:userId/legal-representative`
- `DELETE /api/v1/users/:userId/legal-representative`

### Módulo Users - Emergency Contacts (actualizado)
- Validación de máximo 5 contactos
- Validación de no duplicados

---

## ✅ Checklist de Actualización

### Documentos
- [ ] Actualizar `especificacion-tecnica-nueva-api.md`
- [ ] Actualizar `mapeo-procesos-endpoints.md`
- [ ] Copiar `decisiones-estandarizacion.md` a `docs/`

### Base de Datos (Migration)
- [ ] Renombrar `p_lastname` → `paternal_last_name`
- [ ] Renombrar `m_lastname` → `maternal_last_name`
- [ ] Agregar campos a `users_pr`
- [ ] Crear tabla `legal_representatives`
- [ ] Agregar `role_category` a tabla `roles`

### Backend
- [ ] Actualizar todos los DTOs
- [ ] Crear módulo `LegalRepresentativesModule`
- [ ] Actualizar validación de contactos (máx 5)
- [ ] Auto-asignar `ecclesiastical_year_id`
- [ ] Filtrar roles por `role_category`

---

**Generado**: 2026-01-29  
**Status**: Listo para aplicar cambios
