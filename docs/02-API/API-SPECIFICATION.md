<!-- CANONICAL-API-NOTE -->
> [!WARNING]
> Documento de especificación técnica/arquitectura.
> Para endpoints runtime consumibles por agentes, usar:
> [ENDPOINTS-LIVE-REFERENCE.md](./ENDPOINTS-LIVE-REFERENCE.md)

# Especificación Técnica - REST API SACDIA

**Versión**: 3.0.0 (contrato runtime unificado)
**Fecha**: 21 de febrero de 2026
**Status**: ✅ Producción - Endpoints canónicos en ENDPOINTS-LIVE-REFERENCE.md

**Nota**:
- Este documento conserva decisiones de arquitectura, seguridad y contratos.
- El listado y conteo vigente de endpoints se mantiene en [ENDPOINTS-LIVE-REFERENCE.md](ENDPOINTS-LIVE-REFERENCE.md).

---

## 📋 Referencias y Decisiones Aplicadas

Este documento integra:

- ✅ **Product vision**: `docs/00-STEERING/product.md`
- ✅ **Stack tecnológico**: `docs/00-STEERING/tech.md`
- ✅ **Procesos de negocio**: `docs/02-PROCESSES.md`
- ✅ **Sistema de roles**: `docs/history/source/api/restrucura-roles.md` (histórico)
- ✅ **Queries SQL (histórico)**: `docs/history/source/api/queries-club-role-assignments.md`

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

- **Backend**: NestJS 11.x + TypeScript 5.x
- **Database**: PostgreSQL 15.x (Supabase)
- **ORM**: Prisma 7.x
- **Auth**: Supabase Auth (JWT + OAuth)
- **Storage**: Supabase Storage
- **Push Notifications**: Firebase Cloud Messaging (FCM)
- **Real-time**: Socket.io (WebSockets)
- **Cache**: Redis (Upstash)
- **Hosting**: Vercel Serverless

### Versionado

**Estrategia**: URI-based (`/api/v1/`)

- Visible, cacheable, simple
- Swagger multi-version
- Máximo 2 versiones mayores simultáneas

📖 **Documentación completa**: [API-VERSIONING.md](./API-VERSIONING.md)

### Seguridad (Desde Día 1)

**Fase 1-3 (Básico)**:

- Helmet (security headers)
- @nestjs/throttler (rate limiting: 3/seg, 20/10seg, 100/min)
- CORS configurado con whitelist
- JWT validation con Supabase
- Secrets en variables de entorno
- Validación con class-validator
- Sanitización XSS (sanitize-html)
- Compression (gzip)

**Fase 4 (Avanzado)** ✅ NUEVO:

- **2FA con Supabase MFA** (TOTP)
- **Token Blacklist** (revocación antes de expiración)
- **Session Limits** (máximo 5 sesiones por usuario)
- **IP Whitelist** para endpoints admin (soporte CIDR)
- **Audit Logging** (todas las requests)
- **Error Handling seguro** (oculta detalles en producción)

---

## 📐 Arquitectura de Módulos

```
src/
├── modules/
│   ├── auth/                    # Autenticación y autorización (JWT + OAuth)
│   ├── users/                   # Gestión de usuarios y perfiles
│   ├── legal-representatives/   # Representantes legales
│   ├── clubs/                   # Gestión de clubes e instancias
│   ├── classes/                 # Clases progresivas
│   ├── honors/                  # Especialidades
│   ├── activities/              # Actividades
│   ├── finances/                # Finanzas
│   ├── inventory/               # ✅ Inventarios por instancia de club
│   ├── camporees/               # ✅ Campamentos con validación de seguros
│   ├── folders/                 # ✅ Portfolios/Carpetas de evidencias
│   ├── certifications/          # ✅ Certificaciones para GMs investidos
│   ├── notifications/           # ✅ Push notifications (FCM)
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
  GLOBAL = "GLOBAL", // Roles de sistema
  CLUB = "CLUB", // Roles de instancia de club
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
-super_admin - // Acceso total al sistema
  admin - // Administrador de campo local
  coordinator - // Coordinador de asociación/unión
  user; // Usuario estándar (asignado en registro)
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
-director - // Director del club
  subdirector - // Subdirector
  secretary - // Secretario
  treasurer - // Tesorero
  counselor - // Consejero
  member; // Miembro regular (asignado en post-registro)
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

-- Ver queries completas en: docs/history/source/api/queries-club-role-assignments.md
```

---

### Guards en NestJS

```typescript
@Controller("clubs/:clubId/activities")
@UseGuards(SupabaseGuard, RolesGuard)
export class ActivitiesController {
  @Post()
  @Roles("director", "subdirector", "secretary")
  @Permissions("CREATE:ACTIVITIES")
  async create(
    @Param("clubId") clubId: string,
    @Body() dto: CreateActivityDto,
  ) {
    // Solo usuarios con rol de director/subdirector/secretary en este club
  }

  @Delete(":id")
  @ClubRole("director") // ✅ Decorator personalizado
  async remove(@Param("id") id: string) {
    // Solo director del club
  }
}
```

---

## 🧩 Tablas Principales

### 1. Tabla `users`

```sql
CREATE TABLE users (
  user_id UUID PRIMARY KEY,  -- Mismo UUID de Supabase Auth
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(100),
  paternal_last_name VARCHAR(100),
  maternal_last_name VARCHAR(100),

  -- Info personal
  gender CHAR(1) CHECK (gender IN ('M', 'F')),
  birthday DATE,
  baptism BOOLEAN,
  baptism_date DATE,
  blood TEXT,

  -- Ubicación
  country_id INTEGER REFERENCES countries(country_id),
  union_id INTEGER REFERENCES unions(union_id),
  local_field_id INTEGER REFERENCES local_fields(local_field_id),

  -- Avatar/imagen de perfil
  user_image TEXT,  -- URL de Supabase Storage

  -- Metadata
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  modified_at TIMESTAMP DEFAULT NOW()
);
```

---

### 2. Tabla `users_pr` (Post-Registro)

**Con tracking granular** (Opción B):

```sql
CREATE TABLE users_pr (
  user_id UUID PRIMARY KEY REFERENCES users(user_id),

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
  user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,

  -- Opción 1: Representante es usuario registrado
  representative_user_id UUID REFERENCES users(user_id),

  -- Opción 2: Solo datos del representante
  name VARCHAR(100),
  paternal_last_name VARCHAR(100),
  maternal_last_name VARCHAR(100),
  phone VARCHAR(20),

  -- Tipo de relación (padre, madre, tutor)
  relationship_type_id UUID REFERENCES relationship_types(relationship_type_id),

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
  emergency_id SERIAL PRIMARY KEY,
  owner_id UUID NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
  contact_user_id UUID REFERENCES users(user_id) ON DELETE SET NULL,
  name VARCHAR(100) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  relationship_type_id UUID NOT NULL REFERENCES relationship_types(relationship_type_id),
  primary BOOLEAN DEFAULT false,
  active BOOLEAN DEFAULT true,

  created_at TIMESTAMP DEFAULT NOW(),
  modified_at TIMESTAMP DEFAULT NOW(),

  -- Evitar duplicados
  CONSTRAINT unique_owner_contact UNIQUE (owner_id, name, phone)
);

-- Trigger para validar máximo 5
CREATE OR REPLACE FUNCTION check_max_emergency_contacts()
RETURNS TRIGGER AS $$
BEGIN
  IF (SELECT COUNT(*) FROM emergency_contacts WHERE owner_id = NEW.owner_id AND active = true) >= 5 THEN
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
import {
  IsString,
  IsNotEmpty,
  IsEmail,
  MinLength,
  Matches,
} from "class-validator";

export class RegisterDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  paternal_last_name: string; // ✅ Descriptivo

  @IsString()
  @IsNotEmpty()
  maternal_last_name: string; // ✅ Descriptivo

  @IsEmail()
  email: string;

  @IsString()
  @MinLength(8)
  @Matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/, {
    message: "Password must contain uppercase, lowercase and number",
  })
  password: string;
}
```

---

### UpdateUserDto

```typescript
export class UpdateUserDto {
  @IsEnum(["M", "F"])
  @IsOptional()
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
  blood?: blood_type;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  country_id?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  union_id?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  local_field_id?: number;
}
```

---

### UpdateUserAllergiesDto

```typescript
export class UpdateUserAllergiesDto {
  @IsArray()
  @ArrayUnique()
  @Type(() => Number)
  @IsInt({ each: true })
  @Min(1, { each: true })
  allergy_ids: number[];
}
```

---

### UpdateUserDiseasesDto

```typescript
export class UpdateUserDiseasesDto {
  @IsArray()
  @ArrayUnique()
  @Type(() => Number)
  @IsInt({ each: true })
  @Min(1, { each: true })
  disease_ids: number[];
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
  @ValidateIf((o) => !o.representative_user_id)
  @IsString()
  name?: string;

  @IsOptional()
  @ValidateIf((o) => !o.representative_user_id)
  @IsString()
  paternal_last_name?: string;

  @IsOptional()
  @ValidateIf((o) => !o.representative_user_id)
  @IsString()
  maternal_last_name?: string;

  @IsOptional()
  @ValidateIf((o) => !o.representative_user_id)
  @IsString()
  phone?: string;

  @IsUUID()
  relationship_type_id: string;
}
```

---

## 🔗 Endpoints Principales

> [!IMPORTANT]
> El listado completo y vigente de endpoints del backend está en [ENDPOINTS-LIVE-REFERENCE.md](ENDPOINTS-LIVE-REFERENCE.md).
> Esta especificación se mantiene para arquitectura, seguridad, contratos y decisiones técnicas.

### Módulos Runtime (Resumen)

- `/api/v1/auth`
- `/api/v1/users`
- `/api/v1/activities`
- `/api/v1/admin`
- `/api/v1/camporees`
- `/api/v1/catalogs`
- `/api/v1/certifications`
- `/api/v1/classes`
- `/api/v1/club-roles`
- `/api/v1/clubs`
- `/api/v1/fcm-tokens`
- `/api/v1/finances`
- `/api/v1/folders`
- `/api/v1/health`
- `/api/v1/honors`
- `/api/v1/inventory`
- `/api/v1/notifications`

## 📊 Respuestas Estándar

### Success

```json
{
  "status": "success",
  "data": {
    /* resource */
  },
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
  "data": [
    /* items */
  ],
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
    "details": [{ "field": "email", "message": "must be a valid email" }]
  }
}
```

### Contrato Canónico: Health Profile Baseline

El baseline health activo del runtime queda anclado sobre sub-recursos sensibles de `user`:

- `allergies`
- `diseases`
- `medicines`

Fuera de scope del baseline activo actual:

- vínculo `medicine <-> disease`;
- dosis, frecuencia, prescripción o historial clínico.

Rutas verificadas en backend:

```http
GET /api/v1/users/:userId/allergies
GET /api/v1/users/:userId/diseases
GET /api/v1/users/:userId/medicines
PUT /api/v1/users/:userId/allergies
PUT /api/v1/users/:userId/diseases
PUT /api/v1/users/:userId/medicines
DELETE /api/v1/users/:userId/allergies/:allergyId
DELETE /api/v1/users/:userId/diseases/:diseaseId
DELETE /api/v1/users/:userId/medicines/:medicineId
```

Reglas:

- Son sub-recursos sensibles `user`, no recursos health globales.
- Deben usar `@AuthorizationResource({ type: 'user', ownerParam: 'userId' })`.
- Owner-or-global: ownership sobre `userId` habilita self-service; para terceros, lectura acepta `health:read` o fallback legacy `users:read_detail`, y escritura acepta `health:update` o fallback legacy `users:update`.
- Permisos de club provenientes solo de `active_assignment` no habilitan acceso a health de terceros.
- Responden con envelope `{ status: 'success', data: [...] }`.
- `GET` devuelve una lista plana de selecciones activas:
  - alergias: `{ allergy_id, name }`
  - enfermedades: `{ disease_id, name }`
- Si el usuario existe sin selecciones activas, la respuesta es `200` con `data: []`.
- `PUT` reemplaza el conjunto activo completo.
- `DELETE` por item existe en runtime y desactiva logicamente una seleccion puntual (`active=false`) sin inventar un recurso nuevo.
- `DELETE` responde `404` cuando la seleccion puntual no esta activa en ese usuario.
- `404` aplica en `GET` solo cuando `userId` no existe.

### Contrato Canónico: User ownership y sub-recursos sensibles

Para las rutas sensibles que cuelgan de `/api/v1/users/:userId/...`, el runtime vigente verificable en backend es:

- ownership sobre `userId` habilita self-service;
- para terceros, solo cuentan permisos globales resueltos explicitamente;
- lecturas finas aceptan `family:read` o fallback legacy `users:read_detail`;
- escrituras finas aceptan `family:update` o fallback legacy `users:update`;
- permisos de club provenientes solo de `active_assignment` no habilitan acceso a datos `user` de terceros.

Familias sensibles confirmadas en runtime:

- `health` (`allergies`, `diseases`, `medicines`);
- `emergency-contacts`;
- `legal-representative`;
- `post-registration/status` y `step-{1,2,3}/complete`;

Exclusiones explicitas fuera del tiering fino actual:

- `GET /users/:userId`;
- `PATCH /users/:userId`;
- `POST /users/:userId/profile-picture`;
- `DELETE /users/:userId/profile-picture`;
- `GET /users/:userId/age`;
- `GET /users/:userId/requires-legal-representative`.

Límites documentales:

- Los permisos finos dedicados vigentes son `health:*`, `emergency_contacts:*`, `legal_representative:*` y `post_registration:*`.
- `GET /users/:userId/post-registration/status` permite lectura administrativa mínima de terceros con `post_registration:read` o fallback legacy `users:read_detail`.
- `POST /users/:userId/post-registration/step-{1,2,3}/complete` permite completion administrativa mínima de terceros con `post_registration:update` o fallback legacy `users:update`.
- Para terceros no owner, el backend debe devolver estado administrativo mínimo y respuestas saneadas, sin inferir datos sensibles ni causas detalladas del paso 2.

### Contrato Transicional Formativo FS-01 (`GET /api/v1/admin/users/:userId`)

Este endpoint mantiene envelope `{ status, data }` y añade semántica explícita para estado formativo:

- `data.current_operational_enrollment`
  - Nullable.
  - Fuente de verdad operativa anual: **solo** `enrollments` del año eclesiástico activo.
  - No usa `users_classes.current_class` para inferir presente.
- `data.trajectory_classes`
  - Arreglo (puede ser vacío).
  - Fuente de verdad de trayectoria consolidada/histórica: **solo** `users_classes`.
- `data.classes`
  - Alias legacy **deprecado** de `trajectory_classes` para compatibilidad.
  - Mantiene semántica de trayectoria (NO semántica operativa anual).

Reglas de nulidad para `current_operational_enrollment`:

- no hay año eclesiástico activo resoluble;
- no hay enrollment activo del usuario para el año activo;
- hay más de un enrollment candidato para el año activo.

En esos casos se retorna `null` sin selección silenciosa ni inferencia desde trayectoria.

#### Nota de rollout

- Consumidores actualizados deben usar `current_operational_enrollment` para estado anual presente y `trajectory_classes` para histórico.
- Consumidores deben tolerar `current_operational_enrollment = null`.
- Durante FS-01 no se eliminan writes legacy ni se retira `classes`.

---

## 🚀 Estado de Implementación

- API backend en producción con contrato runtime centralizado en [ENDPOINTS-LIVE-REFERENCE.md](ENDPOINTS-LIVE-REFERENCE.md).
- Módulos activos: auth, users, clubs, classes, honors, activities, camporees, finances, inventory, folders, notifications, catalogs, admin geography/reference y rbac.
- Para consumo por agentes (App + Panel Admin), usar siempre el documento canónico de endpoints en vivo.

## 📝 Recursos Adicionales

- **Queries SQL (histórico)**: [queries-club-role-assignments.md](../history/source/api/queries-club-role-assignments.md)
- **Análisis de Roles (histórico)**: [analisis-club-members-vs-roles.md](../history/source/api/analisis-club-members-vs-roles.md)
- **Decisiones (histórico)**: [decisiones-estandarizacion.md](../history/source/api/decisiones-estandarizacion.md)

---

**Generado**: 2026-01-29
**Actualizado**: 2026-02-17
**Versión**: 3.0.0 (contrato runtime unificado)
**Status**: ✅ Producción - Endpoints canónicos en ENDPOINTS-LIVE-REFERENCE.md
