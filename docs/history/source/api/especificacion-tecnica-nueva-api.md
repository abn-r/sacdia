# Especificación Técnica - Nueva REST API SACDIA v2.0

**Versión**: 2.0.0 (Actualizada)  
**Fecha**: 29 de enero de 2026  
**Status**: Listo para implementación

---

## 📋 Referencias y Decisiones Aplicadas

Este documento integra:
- ✅ **Product vision**: `.specs/_steering/product.md`
- ✅ **Stack tecnológico**: `.specs/_steering/tech.md`
- ✅ **Procesos de negocio**: `docs/procesos-sacdia.md`
- ✅ **Sistema de roles**: `docs/restapi/restructura-roles.md`
- ✅ **Queries SQL**: `docs/restapi/queries-club-role-assignments.md`

###Decisiones Finales Aplicadas

1. ✅ Nombres de campos descriptivos: `paternal_last_name`, `maternal_last_name`
2. ✅ Sistema RBAC con `role_category` (GLOBAL | CLUB)
3. ✅ Tabla `legal_representatives` para menores
4. ✅ `users_pr` con tracking granular por paso
5. ✅ `club_role_assignments` con `ecclesiastical_year_id`
6. ✅ Validación máximo 5 contactos de emergencia

---

## 🎯 Decisiones Arquitectónicas

### Stack Final
- **Backend**: NestJS 10.x + TypeScript 5.x
- **Database**: PostgreSQL 15.x (Supabase)
- **ORM**: Prisma 6.x
- **Auth**: Supabase Auth (JWT)
- **Storage**: Supabase Storage
- **Cache**: Redis (Upstash)
- **Hosting**: Vercel Serverless

### Versionado
**Estrategia**: URI-based (`/api/v1/`)
- Visible, cacheable, simple
- Swagger multi-version
- Máximo 2 versiones mayores simultáneas

### Seguridad (Desde Día 1)
- Helmet (security headers)
- @nestjs/throttler (rate limiting)
- CORS configurado
- JWT validation con Supabase
- Secrets en variables de entorno
- Validación con class-validator

---

## 📐 Arquitectura de Módulos

```
src/
├── modules/
│   ├── auth/                    # Autenticación y autorización
│   ├── users/                   # Gestión de usuarios y perfiles
│   ├── legal-representatives/   # ✅ NUEVO: Representantes legales
│   ├── clubs/                   # Gestión de clubes e instancias
│   ├── classes/                 # Clases progresivas
│   ├── honors/                  # Especialidades
│   ├── activities/              # Actividades
│   ├── finances/                # Finanzas
│   ├── inventory/               # Inventarios
│   ├── camporees/               # Campamentos
│   ├── catalogs/                # Catálogos maestros
│   └── files/                   # Gestión de archivos
├── common/
│   ├── guards/                  # SupabaseGuard, RolesGuard
│   ├── decorators/              # @Roles(), @Permissions(), @ClubRole()
│   ├── interceptors/            # Response transformation
│   ├── filters/                 # Exception handling
│   └── pipes/                   # Validation pipes
└── prisma.service.ts
```

---

## 🔐 Sistema de Autenticación y Autorización

### Sistema RBAC Completo

#### Categorías de Roles (`role_category`)

```typescript
enum RoleCategory {
  GLOBAL = 'GLOBAL',  // Roles de sistema
  CLUB = 'CLUB'       // Roles de instancia de club
}
```

**Tabla `roles`**:
```sql
CREATE TABLE roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role_name VARCHAR(50) UNIQUE NOT NULL,
  role_category VARCHAR(10) NOT NULL CHECK (role_category IN ('GLOBAL', 'CLUB')),
  description TEXT,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

#### Roles Globales (tabla: `users_roles`)

Asignados directamente al usuario, aplican a todo el sistema:

```typescript
- super_admin   // Acceso total al sistema
- admin         // Administrador de campo local
- coordinator   // Coordinador de asociación/unión
- user          // Usuario estándar (asignado en registro)
```

**Tabla `users_roles`**:
```sql
CREATE TABLE users_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role_id UUID NOT NULL REFERENCES roles(id),
  assigned_at TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT unique_user_global_role UNIQUE (user_id, role_id)
);
```

---

#### Roles de Club (tabla: `club_role_assignments`)

Asignados a instancias específicas de club, vinculados a año eclesiástico:

```typescript
- director       // Director del club
- subdirector    // Subdirector
- secretary      // Secretario
- treasurer      // Tesorero
- counselor      // Consejero
- member         // Miembro regular (asignado en post-registro)
```

**Tabla `club_role_assignments`** (con `ecclesiastical_year_id`):
```sql
CREATE TABLE club_role_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  role_id UUID NOT NULL REFERENCES roles(id),  -- Debe tener role_category = 'CLUB'
  
  -- Instancia de club (solo UNA con valor)
  club_adv_id INT REFERENCES club_adventurers(id),
  club_pathf_id INT REFERENCES club_pathfinders(id),
  club_mg_id INT REFERENCES club_master_guild(id),
  
  -- ✅ Año eclesiástico
  ecclesiastical_year_id INT NOT NULL REFERENCES ecclesiastical_years(id),
  
  -- Metadata
  start_date DATE NOT NULL DEFAULT CURRENT_DATE,
  end_date DATE,
  active BOOLEAN DEFAULT true,
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('pending', 'active', 'inactive')),
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT one_club_instance CHECK (
    (club_adv_id IS NOT NULL)::int + 
    (club_pathf_id IS NOT NULL)::int + 
    (club_mg_id IS NOT NULL)::int = 1
  ),
  
  CONSTRAINT unique_user_role_instance_year UNIQUE NULLS NOT DISTINCT (
    user_id, role_id, club_adv_id, club_pathf_id, club_mg_id, ecclesiastical_year_id
  )
);

-- Ver queries completas en: docs/restapi/queries-club-role-assignments.md
```

---

### Guards en NestJS

```typescript
@Controller('clubs/:clubId/activities')
@UseGuards(SupabaseGuard, RolesGuard)
export class ActivitiesController {
  
  @Post()
  @Roles('director', 'subdirector', 'secretary')
  @Permissions('CREATE:ACTIVITIES')
  async create(@Param('clubId') clubId: string, @Body() dto: CreateActivityDto) {
    // Solo usuarios con rol de director/subdirector/secretary en este club
  }
  
  @Delete(':id')
  @ClubRole('director')  // ✅ Decorator personalizado
  async remove(@Param('id') id: string) {
    // Solo director del club
  }
}
```

---

## 🧩 Tablas Principales

### 1. Tabla `users`

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY,  -- Mismo UUID de Supabase Auth
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(100) NOT NULL,
  paternal_last_name VARCHAR(100) NOT NULL,  -- ✅ Descriptivo
  maternal_last_name VARCHAR(100) NOT NULL,  -- ✅ Descriptivo
  
  -- Info personal
  gender CHAR(1) CHECK (gender IN ('M', 'F')),
  birthdate DATE,
  is_baptized BOOLEAN,
  baptism_date DATE,
  
  -- Ubicación
  country_id UUID REFERENCES countries(id),
  union_id UUID REFERENCES unions(id),
  local_field_id UUID REFERENCES local_fields(id),
  
  -- Avatar
  avatar TEXT,  -- URL de Supabase Storage
  
  -- Metadata
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

---

### 2. Tabla `users_pr` (Post-Registro)

**Con tracking granular** (Opción B):

```sql
CREATE TABLE users_pr (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  
  -- Tracking por paso
 complete BOOLEAN DEFAULT false,
  profile_picture_complete BOOLEAN DEFAULT false,  -- ✅ Paso 1
  personal_info_complete BOOLEAN DEFAULT false,    -- ✅ Paso 2
  club_selection_complete BOOLEAN DEFAULT false,   -- ✅ Paso 3
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

**Flujo**:
1. Foto subida → `profile_picture_complete = true`
2. Info personal guardada → `personal_info_complete = true`
3. Club seleccionado → `club_selection_complete = true` AND `complete = true`

---

### 3. Tabla `legal_representatives` (✅ NUEVA)

Para usuarios menores de 18 años:

```sql
CREATE TABLE legal_representatives (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Opción 1: Representante es usuario registrado
  representative_user_id UUID REFERENCES users(id),
  
  -- Opción 2: Solo datos del representante
  name VARCHAR(100),
  paternal_last_name VARCHAR(100),
  maternal_last_name VARCHAR(100),
  phone VARCHAR(20),
  
  -- Tipo de relación (padre, madre, tutor)
  relationship_type_id UUID REFERENCES relationship_types(id),
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT one_representative_per_user UNIQUE(user_id),
  CONSTRAINT representative_data_check CHECK (
    (representative_user_id IS NOT NULL) OR 
    (name IS NOT NULL AND paternal_last_name IS NOT NULL AND phone IS NOT NULL)
  )
);
```

---

### 4. Tabla `emergency_contacts`

**Validación**: Máximo 5 contactos por usuario

```sql
CREATE TABLE emergency_contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  relationship_type_id UUID REFERENCES relationship_types(id),
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  -- Evitar duplicados
  CONSTRAINT unique_user_contact UNIQUE (user_id, name, phone)
);

-- Trigger para validar máximo 5
CREATE OR REPLACE FUNCTION check_max_emergency_contacts()
RETURNS TRIGGER AS $$
BEGIN
  IF (SELECT COUNT(*) FROM emergency_contacts WHERE user_id = NEW.user_id) >= 5 THEN
    RAISE EXCEPTION 'User cannot have more than 5 emergency contacts';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_max_emergency_contacts
BEFORE INSERT ON emergency_contacts
FOR EACH ROW EXECUTE FUNCTION check_max_emergency_contacts();
```

---

## 📦 DTOs y Validación

### RegisterDto

```typescript
import { IsString, IsNotEmpty, IsEmail, MinLength, Matches } from 'class-validator';

export class RegisterDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  paternal_last_name: string;  // ✅ Descriptivo

  @IsString()
  @IsNotEmpty()
  maternal_last_name: string;  // ✅ Descriptivo

  @IsEmail()
  email: string;

  @IsString()
  @MinLength(8)
  @Matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/, {
    message: 'Password must contain uppercase, lowercase and number'
  })
  password: string;
}
```

---

### UpdatePersonalInfoDto

```typescript
export class UpdatePersonalInfoDto {
  @IsEnum(['M', 'F'])
  gender: string;

  @IsDateString()
  @Validate(AgeValidator, [{ min: 3, max: 99 }])
  birthdate: string;

  @IsBoolean()
  is_baptized: boolean;

  @IsOptional()
  @IsDateString()
  @ValidateIf(o => o.is_baptized === true)
  baptism_date?: string;
}

// Validador personalizado
@ValidatorConstraint({ name: 'AgeValidator', async: false })
export class AgeValidator implements ValidatorConstraintInterface {
  validate(birthdate: string, args: ValidationArguments) {
    const { min, max } = args.constraints[0];
    const age = calculateAge(birthdate);
    return age >= min && age <= max;
  }
}
```

---

### CreateLegalRepresentativeDto

```typescript
export class CreateLegalRepresentativeDto {
  // Opción 1: Usuario registrado
  @IsOptional()
  @IsUUID()
  representative_user_id?: string;

  // Opción 2: Solo datos
  @IsOptional()
  @ValidateIf(o => !o.representative_user_id)
  @IsString()
  name?: string;

  @IsOptional()
  @ValidateIf(o => !o.representative_user_id)
  @IsString()
  paternal_last_name?: string;

  @IsOptional()
  @ValidateIf(o => !o.representative_user_id)
  @IsString()
  maternal_last_name?: string;

  @IsOptional()
  @ValidateIf(o => !o.representative_user_id)
  @IsString()
  phone?: string;

  @IsUUID()
  relationship_type_id: string;
}
```

---

## 🔗 Endpoints Principales

### Módulo Auth

```typescript
POST   /api/v1/auth/register
POST   /api/v1/auth/login
POST   /api/v1/auth/logout
POST   /api/v1/auth/password/reset-request
POST   /api/v1/auth/password/reset
GET    /api/v1/auth/me                            // Incluye global_roles + club_role_assignments
GET    /api/v1/auth/profile/completion-status     // ✅ Con tracking granular
```

### Módulo Users

```typescript
GET    /api/v1/users/:userId
PATCH  /api/v1/users/:userId
POST   /api/v1/users/:userId/profile-picture
DELETE /api/v1/users/:userId/profile-picture

// Emergency Contacts (máx 5)
GET    /api/v1/users/:userId/emergency-contacts
POST   /api/v1/users/:userId/emergency-contacts    // ✅ Validación de máx 5
PATCH  /api/v1/emergency-contacts/:contactId
DELETE /api/v1/emergency-contacts/:contactId

// Allergies & Diseases
GET    /api/v1/users/:userId/allergies
POST   /api/v1/users/:userId/allergies
DELETE /api/v1/users/:userId/allergies/:allergyId

GET    /api/v1/users/:userId/diseases
POST   /api/v1/users/:userId/diseases
DELETE /api/v1/users/:userId/diseases/:diseaseId
```

### Módulo Legal Representatives (✅ NUEVO)

```typescript
GET    /api/v1/users/:userId/requires-legal-representative  // Verifica si edad < 18
POST   /api/v1/users/:userId/legal-representative
GET    /api/v1/users/:userId/legal-representative
PATCH  /api/v1/users/:userId/legal-representative
DELETE /api/v1/users/:userId/legal-representative          // Solo si edad >= 18
```

### Módulo Clubs

```typescript
POST   /api/v1/clubs
GET    /api/v1/clubs
GET    /api/v1/clubs/:clubId
PATCH  /api/v1/clubs/:clubId

// Instancias
POST   /api/v1/clubs/:clubId/instances/adventurers
POST   /api/v1/clubs/:clubId/instances/pathfinders
POST   /api/v1/clubs/:clubId/instances/master-guides
GET    /api/v1/clubs/:clubId/instances

// Miembros (via club_role_assignments)
GET    /api/v1/clubs/:clubId/members                    // ✅ Ver queries SQL
POST   /api/v1/clubs/:clubId/members                    // Crea role assignment
DELETE /api/v1/clubs/:clubId/members/:userId

// Roles de club (club_role_assignments)
POST   /api/v1/clubs/:clubId/members/:userId/roles      // Asignar rol adicional
GET    /api/v1/users/:userId/club-roles                 // Obtener todos sus roles de club
DELETE /api/v1/club-role-assignments/:assignmentId
```

### Módulo Classes

```typescript
GET    /api/v1/classes
GET    /api/v1/classes/:classId
POST   /api/v1/users/:userId/classes                    // Inscripción
GET    /api/v1/users/:userId/classes
DELETE /api/v1/users/:userId/classes/:classId

// Progreso
GET    /api/v1/users/:userId/classes/:classId/progress
POST   /api/v1/users/:userId/classes/:classId/modules/:moduleId/sections/:sectionId
POST   /api/v1/users/:userId/classes/:classId/submit-for-validation
POST   /api/v1/classes/:classId/validate-investiture/:userId
```

---

## 📊 Respuestas Estándar

### Success
```json
{
  "status": "success",
  "data": { /* resource */ },
  "meta": {
    "timestamp": "2026-01-29T17:00:00Z",
    "version": "1.0.0",
    "requestId": "uuid"
  }
}
```

### Paginated
```json
{
  "status": "success",
  "data": [ /* items */ ],
  "meta": {
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 150,
      "totalPages": 8
    }
  }
}
```

### Error
```json
{
  "status": "error",
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": [
      { "field": "email", "message": "must be a valid email" }
    ]
  }
}
```

---

## 🚀 Plan de Implementación

### Fase 1: Fundamentos (Semana 1-2)
- [ ] Setup NestJS con versionado `/api/v1/`
- [ ] Configurar Prisma + Supabase
- [ ] Implementar Helmet + Throttler + CORS
- [ ] Crear SupabaseGuard
- [ ] Configurar Swagger

### Fase 2: Auth + RBAC (Semana 3-4)
- [ ] Módulo Auth completo
- [ ] Sistema de roles con `role_category`
- [ ] Tablas `users_roles` y `club_role_assignments`
- [ ] RolesGuard y decorators
- [ ] Tests E2E de auth

### Fase 3: Users + Post-Registro (Semana 5-6)
- [ ] Módulo Users básico
- [ ] Tabla `users_pr` con tracking granular
- [ ] Upload de fotografía (Supabase Storage)
- [ ] Contactos de emergencia (validación máx 5)
- [ ] Alergias y enfermedades

### Fase 4: Legal Representatives (Semana 7)
- [ ] Módulo Legal Representatives
- [ ] Validación de edad < 18
- [ ] Flujo completo en post-registro

### Fase 5: Clubs + Classes (Semana 8-10)
- [ ] Módulo Clubs (CRUD + instancias)
- [ ] `club_role_assignments` con `ecclesiastical_year_id`
- [ ] Auto-asignación rol "member"
- [ ] Módulo Classes (catálogo + enrollment)
- [ ] Validación de investiduras

### Fase 6: Módulos Adicionales + Testing (Semana 11-12)
- [ ] Activities, Finances, Inventory
- [ ] Catalogs unificados
- [ ] Tests unitarios (>70% coverage)
- [ ] Tests E2E completos
- [ ] Performance testing

---

## 📝 Recursos Adicionales

- **Queries SQL**: [queries-club-role-assignments.md](file:///Users/abner/Documents/development/sacdia/docs/02-API/_source_docs/queries-club-role-assignments.md)
- **Análisis de Roles**: [analisis-club-members-vs-roles.md](file:///Users/abner/Documents/development/sacdia/docs/02-API/_source_docs/analisis-club-members-vs-roles.md)
- **Decisiones**: [decisiones-estandarizacion.md](file:///Users/abner/Documents/development/sacdia/docs/02-API/_source_docs/decisiones-estandarizacion.md)

---

**Generado**: 2026-01-29  
**Versión**: 2.0.0 (Con todas las decisiones finales)  
**Status**: ✅ Listo para implementación
