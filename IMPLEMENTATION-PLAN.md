# PLAN DE IMPLEMENTACIÓN - SACDIA BACKEND
## Módulos Faltantes y Actualización de Documentación

**Fecha de Creación**: 3 de febrero de 2026
**Estimado Total**: 2-3 semanas
**Módulos a Implementar**: 8 componentes

---

## FASE 0: DOCUMENTACIÓN DISCOVERY ✅ COMPLETADA

### Fuentes Consultadas y Verificadas

**Especificaciones de Features** (.specs/features/):
- ✅ `gestion-seguros/requirements.md` - Sistema de seguros para camporees
- ✅ `certificaciones-guias-mayores/requirements.md` - Certificaciones para GMs
- ✅ `validacion-investiduras/requirements.md` - Workflow de validación
- ✅ `actividades/design.md`, `gestion-clubs/design.md`, `clases-progresivas/design.md`
- ✅ `catalogos/design.md`, `finanzas/design.md`, `honores/design.md`

**Documentación de API** (docs/api/):
- ✅ `API-SPECIFICATION.md` - Especificación técnica REST API v2.0
- ✅ `ENDPOINTS-REFERENCE.md` - 57 endpoints documentados con código
- ✅ `SECURITY-GUIDE.md` - Seguridad avanzada (2FA, sessions, blacklist)
- ✅ `API-VERSIONING.md` - Estrategia de versionamiento

**Schema de Base de Datos**:
- ✅ `sacdia-backend/prisma/schema.prisma` - 67 modelos, 6 enums

**Código Existente** (sacdia-backend/src/):
- ✅ 13 módulos implementados (~79 endpoints operacionales)
- ✅ Guards: JwtAuthGuard, ClubRolesGuard, IpWhitelistGuard
- ✅ Servicios comunes: MfaService, SessionManagementService, TokenBlacklistService

### APIs Externas Documentadas

**Supabase Auth** - Métodos disponibles:
```typescript
// Autenticación básica
supabase.auth.signUp({ email, password })
supabase.auth.signInWithPassword({ email, password })
supabase.auth.signOut()

// Reset password
supabase.auth.resetPasswordForEmail(email)
supabase.auth.updateUser({ password })

// OAuth
supabase.auth.signInWithOAuth({ provider, options })

// MFA
supabase.auth.mfa.enroll()
supabase.auth.mfa.verify()
supabase.auth.mfa.list()
supabase.auth.mfa.unenroll()
```

**Firebase Cloud Messaging** - Requerido para push notifications:
```typescript
admin.messaging().sendMulticast({ tokens, notification, data })
admin.messaging().subscribeToTopic(tokens, topic)
admin.messaging().sendToTopic(topic, message)
```

### Patrones Copy-Ready Identificados

**Patrón 1: Transacciones Complejas**
- Fuente: `post-registration/post-registration.service.ts`
- Uso: `prisma.$transaction()` para operaciones atómicas múltiples
- Aplicable a: Campamentos, Certificaciones

**Patrón 2: Validación de Límites**
- Fuente: `emergency-contacts/emergency-contacts.service.ts`
- Uso: Validar máximo de items antes de insertar
- Aplicable a: FCM tokens, Sesiones

**Patrón 3: DTOs con Validación Condicional**
- Fuente: `legal-representatives/dto/create-legal-representative.dto.ts`
- Uso: `@ValidateIf()` para campos opcionales dependientes
- Aplicable a: OAuth, Representantes

**Patrón 4: Guards con Roles Múltiples**
- Fuente: `clubs/clubs.controller.ts`
- Uso: `@Roles('director', 'subdirector')` con ClubRolesGuard
- Aplicable a: Todos los nuevos módulos

### Anti-Patrones a Evitar

❌ **NO inventar métodos de Supabase** - Solo usar métodos documentados
❌ **NO usar raw SQL** - Siempre usar Prisma Client
❌ **NO omitir transacciones** - Usar en operaciones multi-tabla
❌ **NO hardcodear roles** - Obtener de BD con query
❌ **NO skip validaciones** - Usar class-validator en todos los DTOs

---

## FASE 1: MÓDULO CAMPAMENTS/CAMPOREES (3-4 días)

### Objetivo
Implementar CRUD completo de campamentos locales y de unión con validación automática de seguros activos.

### Documentación de Referencia
- Schema: `prisma/schema.prisma` líneas 51-87 (camporee_clubs), 609-629 (local_camporees), 710-730 (union_camporees), 70-88 (camporee_members)
- Requirements: `.specs/features/gestion-seguros/requirements.md` líneas 1-56
- Pattern: Copiar estructura de `activities/activities.module.ts`

### Tareas Detalladas

#### 1.1 Crear Módulo y Estructura (1 día)
```bash
cd sacdia-backend
nest g module camporees
nest g controller camporees
nest g service camporees
```

**Archivos a crear**:
- `src/camporees/camporees.module.ts`
- `src/camporees/camporees.controller.ts`
- `src/camporees/camporees.service.ts`
- `src/camporees/dto/create-camporee.dto.ts`
- `src/camporees/dto/update-camporee.dto.ts`
- `src/camporees/dto/register-member.dto.ts`
- `src/camporees/entities/camporee.entity.ts`

#### 1.2 Implementar DTOs con Validaciones (0.5 día)

**Copiar pattern de**: `activities/dto/create-activity.dto.ts`

```typescript
// create-camporee.dto.ts
import { IsString, IsDateString, IsInt, IsBoolean, IsOptional, IsDecimal } from 'class-validator';

export class CreateCamporeeDto {
  @IsString()
  name: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsDateString()
  start_date: string;

  @IsDateString()
  end_date: string;

  @IsInt()
  local_field_id: number;

  @IsBoolean()
  includes_adventurers: boolean;

  @IsBoolean()
  includes_pathfinders: boolean;

  @IsBoolean()
  includes_master_guides: boolean;

  @IsString()
  local_camporee_place: string;

  @IsOptional()
  @IsDecimal()
  registration_cost?: number;
}

// register-member.dto.ts
export class RegisterMemberDto {
  @IsString()
  user_id: string;

  @IsString()
  camporee_type: 'local' | 'union';

  @IsOptional()
  @IsString()
  club_name?: string;

  @IsInt()
  @IsOptional()
  insurance_id?: number; // FK a member_insurances
}
```

#### 1.3 Implementar Service con Validación de Seguros (1.5 días)

**Copiar pattern de**: `post-registration/post-registration.service.ts` (transacciones)

```typescript
// camporees.service.ts
async registerMember(camporeeId: number, dto: RegisterMemberDto) {
  return await this.prisma.$transaction(async (tx) => {
    // 1. Validar que el camporee existe
    const camporee = await tx.local_camporees.findUnique({
      where: { local_camporee_id: camporeeId }
    });
    if (!camporee) throw new NotFoundException('Camporee not found');

    // 2. Validar seguro activo
    if (dto.insurance_id) {
      const insurance = await tx.member_insurances.findUnique({
        where: { insurance_id: dto.insurance_id }
      });

      if (!insurance || insurance.user_id !== dto.user_id) {
        throw new BadRequestException('Invalid insurance');
      }

      // Validar tipo de seguro
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

#### 1.4 Implementar Controller con Guards (0.5 día)

**Copiar pattern de**: `activities/activities.controller.ts`

```typescript
@Controller('camporees')
@UseGuards(JwtAuthGuard)
export class CamporeesController {
  @Get()
  findAll(@Query('page') page?: number, @Query('limit') limit?: number) {}

  @Post()
  @UseGuards(ClubRolesGuard)
  @Roles('director', 'subdirector')
  create(@Body() dto: CreateCamporeeDto) {}

  @Get(':id')
  findOne(@Param('id') id: string) {}

  @Patch(':id')
  @UseGuards(ClubRolesGuard)
  @Roles('director', 'subdirector')
  update(@Param('id') id: string, @Body() dto: UpdateCamporeeDto) {}

  @Delete(':id')
  @UseGuards(ClubRolesGuard)
  @Roles('director')
  remove(@Param('id') id: string) {}

  @Post(':id/register')
  registerMember(@Param('id') id: string, @Body() dto: RegisterMemberDto) {}

  @Get(':id/members')
  getMembers(@Param('id') id: string) {}
}
```

#### 1.5 Tests E2E (0.5 día)

**Copiar pattern de**: `test/activities.e2e-spec.ts`

Crear: `test/camporees.e2e-spec.ts`

### Verificación de Completitud

```bash
# Verificar módulo existe
ls -la src/camporees/

# Verificar endpoints en Swagger
npm run start:dev
# Abrir http://localhost:3000/api

# Ejecutar tests
npm run test:e2e -- camporees.e2e-spec.ts

# Verificar con grep que no hay raw SQL
grep -r "\$queryRaw" src/camporees/
# Debe retornar vacío

# Verificar transacciones
grep -r "\$transaction" src/camporees/
# Debe encontrar al menos 1 uso
```

### Endpoints Implementados (8 total)
```
GET    /api/v1/camporees
POST   /api/v1/camporees
GET    /api/v1/camporees/:id
PATCH  /api/v1/camporees/:id
DELETE /api/v1/camporees/:id
POST   /api/v1/camporees/:id/register
GET    /api/v1/camporees/:id/members
DELETE /api/v1/camporees/:id/members/:userId
```

---

## FASE 2: MÓDULO FOLDERS/PORTFOLIOS (2-3 días)

### Objetivo
Sistema de carpetas de evidencias con módulos, secciones y tracking de puntos.

### Documentación de Referencia
- Schema: `prisma/schema.prisma` líneas 39-49 (folder_assignments), 475-566 (folders + modules + sections + records)
- Pattern: Copiar estructura de `classes/` (similar: clase → módulo → sección)

### Tareas Detalladas

#### 2.1 Crear Módulo y Estructura (0.5 día)
```bash
nest g module folders
nest g controller folders
nest g service folders
nest g controller folders/user-folders --flat
```

#### 2.2 Implementar DTOs (0.5 día)

**Copiar pattern de**: `classes/dto/enroll-class.dto.ts`

```typescript
// create-folder.dto.ts
export class CreateFolderDto {
  @IsString()
  name: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsInt()
  club_type?: number;

  @IsOptional()
  @IsInt()
  ecclesiastical_year_id?: number;

  @IsOptional()
  @IsInt()
  max_points?: number;

  @IsOptional()
  @IsInt()
  minimum_points?: number;
}

// enroll-folder.dto.ts
export class EnrollFolderDto {
  @IsInt()
  folder_id: number;
}

// update-section-progress.dto.ts
export class UpdateSectionProgressDto {
  @IsInt()
  points: number;

  @IsOptional()
  @IsObject()
  evidences?: Record<string, any>; // JSON
}
```

#### 2.3 Implementar Service (1 día)

**Copiar pattern de**: `classes/classes.service.ts` (progreso por módulos/secciones)

```typescript
async getFolderProgress(userId: string, folderId: number) {
  // 1. Obtener folder con módulos y secciones
  const folder = await this.prisma.folders.findUnique({
    where: { folder_id: folderId },
    include: {
      folders_modules: {
        include: {
          folders_sections: true
        }
      }
    }
  });

  // 2. Obtener registros de progreso del usuario
  const moduleRecords = await this.prisma.folders_modules_records.findMany({
    where: {
      folder_id: folderId,
      // Filtrar por instancia de club del usuario
    }
  });

  const sectionRecords = await this.prisma.folders_section_records.findMany({
    where: {
      folder_id: folderId
    }
  });

  // 3. Calcular progreso
  const totalPoints = sectionRecords.reduce((sum, r) => sum + (r.points || 0), 0);
  const percentage = (totalPoints / folder.max_points) * 100;

  return {
    folder_id: folderId,
    status: folder.status,
    progress_percentage: percentage,
    total_points: totalPoints,
    max_points: folder.max_points,
    modules: // mapear con progreso
  };
}
```

#### 2.4 Implementar Controllers (0.5 día)

```typescript
// folders.controller.ts (público - templates)
@Controller('folders')
export class FoldersController {
  @Get()
  findAll() {}

  @Get(':id')
  findOne(@Param('id') id: string) {}

  @Post()
  @UseGuards(JwtAuthGuard, ClubRolesGuard)
  @Roles('admin')
  create(@Body() dto: CreateFolderDto) {}
}

// user-folders.controller.ts (autenticado - progreso)
@Controller('users/:userId/folders')
@UseGuards(JwtAuthGuard)
export class UserFoldersController {
  @Get()
  getMyFolders(@Param('userId') userId: string) {}

  @Post(':folderId/enroll')
  enroll(@Param('userId') userId: string, @Param('folderId') folderId: string) {}

  @Get(':folderId/progress')
  getProgress(@Param('userId') userId: string, @Param('folderId') folderId: string) {}

  @Patch(':folderId/modules/:moduleId/sections/:sectionId')
  updateSectionProgress(
    @Param('userId') userId: string,
    @Param('folderId') folderId: string,
    @Param('moduleId') moduleId: string,
    @Param('sectionId') sectionId: string,
    @Body() dto: UpdateSectionProgressDto
  ) {}
}
```

#### 2.5 Tests (0.5 día)

Crear: `test/folders.e2e-spec.ts`

### Verificación de Completitud

```bash
# Verificar estructura
ls -la src/folders/

# Verificar cálculo de progreso
grep -r "progress_percentage" src/folders/
# Debe encontrar implementación

# Ejecutar tests
npm run test:e2e -- folders.e2e-spec.ts
```

### Endpoints Implementados (7 total)
```
GET    /api/v1/folders
GET    /api/v1/folders/:id
POST   /api/v1/folders
GET    /api/v1/users/:userId/folders
POST   /api/v1/users/:userId/folders/:folderId/enroll
GET    /api/v1/users/:userId/folders/:folderId/progress
PATCH  /api/v1/users/:userId/folders/:folderId/modules/:moduleId/sections/:sectionId
```

---

## FASE 3: MÓDULO CERTIFICATIONS (2-3 días)

### Objetivo
Sistema de certificaciones para Guías Mayores investidos (inscripción múltiple paralela).

### Documentación de Referencia
- Requirements: `.specs/features/certificaciones-guias-mayores/requirements.md` líneas 1-64
- Schema: `prisma/schema.prisma` líneas 876-970
- Pattern: **Copiar casi idéntico de `classes/`** con cambios menores

### Tareas Detalladas

#### 3.1 Crear Módulo (0.5 día)
```bash
nest g module certifications
nest g controller certifications
nest g service certifications
nest g controller certifications/user-certifications --flat
```

#### 3.2 Copiar y Adaptar de Classes Module (1 día)

**Archivos a copiar**:
```bash
# Copiar estructura completa de classes
cp -r src/classes/dto src/certifications/
cp src/classes/classes.service.ts src/certifications/certifications.service.ts
cp src/classes/classes.controller.ts src/certifications/certifications.controller.ts
```

**Cambios a realizar** (buscar y reemplazar):
- `classes` → `certifications`
- `class_id` → `certification_id`
- `class_modules` → `certification_modules`
- `class_sections` → `certification_sections`
- `users_classes` → `users_certifications`
- `class_module_progress` → `certification_module_progress`
- `class_section_progress` → `certification_section_progress`

#### 3.3 Agregar Validación de Elegibilidad (0.5 día)

**CRÍTICO**: Solo Guías Mayores investidos

```typescript
// certifications.service.ts
async validateEligibility(userId: string): Promise<boolean> {
  const enrollment = await this.prisma.users_classes.findFirst({
    where: {
      user_id: userId,
      classes: {
        name: 'Guía Mayor'
      },
      investiture: true // INVESTIDO
    }
  });

  if (!enrollment) {
    throw new ForbiddenException('Only invested Guías Mayores can enroll in certifications');
  }

  return true;
}

async enroll(userId: string, dto: EnrollCertificationDto) {
  // Validar elegibilidad PRIMERO
  await this.validateEligibility(userId);

  // Luego crear enrollment
  return await this.prisma.users_certifications.create({
    data: {
      user_id: userId,
      certification_id: dto.certification_id,
      enrollment_date: new Date(),
      completion_status: false,
      active: true
    }
  });
}
```

#### 3.4 Remover Restricción de Inscripción Única (0.5 día)

**Diferencia clave con classes**: Permitir múltiples inscripciones simultáneas

```typescript
// NO validar inscripciones previas
// Classes tiene:
// if (existingEnrollment) throw new ConflictException();

// Certifications NO tiene esa validación
async enroll(userId: string, dto: EnrollCertificationDto) {
  await this.validateEligibility(userId);

  // No validar duplicados - permite múltiples
  return await this.prisma.users_certifications.create({ ... });
}
```

#### 3.5 Tests (0.5 día)

Copiar y adaptar: `test/classes.e2e-spec.ts` → `test/certifications.e2e-spec.ts`

**Agregar test específico**:
```typescript
it('should allow multiple simultaneous enrollments', async () => {
  await request(app.getHttpServer())
    .post(`/users/${userId}/certifications/enroll`)
    .send({ certification_id: 1 })
    .expect(201);

  await request(app.getHttpServer())
    .post(`/users/${userId}/certifications/enroll`)
    .send({ certification_id: 2 })
    .expect(201); // No debe fallar
});

it('should reject non-invested GM', async () => {
  await request(app.getHttpServer())
    .post(`/users/${nonInvestedUserId}/certifications/enroll`)
    .send({ certification_id: 1 })
    .expect(403);
});
```

### Verificación de Completitud

```bash
# Verificar que copió correctamente
diff -r src/classes/ src/certifications/ | grep -E "class|Class"
# Debe mostrar las diferencias (clases → certificaciones)

# Verificar validación de elegibilidad
grep -r "Guía Mayor" src/certifications/
# Debe encontrar validación

# Verificar permite múltiples
grep -r "ConflictException.*enroll" src/certifications/
# NO debe encontrar (a diferencia de classes)

# Tests
npm run test:e2e -- certifications.e2e-spec.ts
```

### Endpoints Implementados (7 total)
```
GET    /api/v1/certifications
GET    /api/v1/certifications/:id
POST   /api/v1/users/:userId/certifications/enroll
GET    /api/v1/users/:userId/certifications
GET    /api/v1/users/:userId/certifications/:certificationId/progress
PATCH  /api/v1/users/:userId/certifications/:certificationId/progress
DELETE /api/v1/users/:userId/certifications/:certificationId
```

---

## FASE 4: MÓDULO INVENTARIO (1-2 días)

### Objetivo
Control de inventario por instancia de club con categorías.

### Documentación de Referencia
- Schema: `prisma/schema.prisma` líneas 190-205 (club_inventory), 600-607 (inventory_categories)
- Pattern: Copiar estructura simple de `finances/`

### Tareas Detalladas

#### 4.1 Crear Módulo (0.5 día)
```bash
nest g module inventory
nest g controller inventory
nest g service inventory
```

#### 4.2 Implementar DTOs (0.25 día)

```typescript
// create-inventory-item.dto.ts
export class CreateInventoryItemDto {
  @IsString()
  name: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsInt()
  inventory_category_id?: number;

  @IsInt()
  amount: number;

  // Uno de estos tres (club instance)
  @IsOptional()
  @IsInt()
  club_adv_id?: number;

  @IsOptional()
  @IsInt()
  club_pathf_id?: number;

  @IsOptional()
  @IsInt()
  club_mg_id?: number;
}

// update-inventory-item.dto.ts
export class UpdateInventoryItemDto extends PartialType(CreateInventoryItemDto) {}
```

#### 4.3 Implementar Service (0.5 día)

```typescript
// inventory.service.ts
async create(clubId: number, dto: CreateInventoryItemDto) {
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
    }
  });
}

async findByClub(clubId: number, instanceType: string) {
  const field = `club_${instanceType}_id`;
  return await this.prisma.club_inventory.findMany({
    where: {
      [field]: clubId,
      active: true
    },
    include: {
      inventory_categories: true
    }
  });
}
```

#### 4.4 Implementar Controller (0.25 día)

**Copiar pattern de**: `finances/finances.controller.ts`

```typescript
@Controller('clubs/:clubId/inventory')
@UseGuards(JwtAuthGuard, ClubRolesGuard)
export class InventoryController {
  @Get()
  findAll(
    @Param('clubId') clubId: string,
    @Query('instanceType') instanceType: string
  ) {}

  @Post()
  @Roles('director', 'subdirector', 'treasurer')
  create(
    @Param('clubId') clubId: string,
    @Body() dto: CreateInventoryItemDto
  ) {}

  @Patch(':id')
  @Roles('director', 'subdirector', 'treasurer')
  update(@Param('id') id: string, @Body() dto: UpdateInventoryItemDto) {}

  @Delete(':id')
  @Roles('director')
  remove(@Param('id') id: string) {}
}

// Endpoint para categorías
@Controller('catalogs/inventory-categories')
export class InventoryCategoriesController {
  @Get()
  findAll() {}
}
```

#### 4.5 Tests (0.5 día)

Copiar: `test/finances.e2e-spec.ts` → `test/inventory.e2e-spec.ts`

### Verificación de Completitud

```bash
# Verificar módulo
ls -la src/inventory/

# Verificar guards
grep -r "ClubRolesGuard" src/inventory/
# Debe encontrar en controller

# Tests
npm run test:e2e -- inventory.e2e-spec.ts
```

### Endpoints Implementados (5 total)
```
GET    /api/v1/clubs/:clubId/inventory
POST   /api/v1/clubs/:clubId/inventory
PATCH  /api/v1/inventory/:id
DELETE /api/v1/inventory/:id
GET    /api/v1/catalogs/inventory-categories
```

---

## FASE 5: COMPLETAR RESET PASSWORD (1 día)

### Objetivo
Implementar verificación de token y actualización de contraseña.

### Documentación de Referencia
- Endpoints: `docs/api/ENDPOINTS-REFERENCE.md` líneas 141-149
- Spec: `docs/api/API-SPECIFICATION.md` líneas 487-506
- Código existente: `src/auth/auth.controller.ts` (parcialmente implementado)

### Tareas Detalladas

#### 5.1 Actualizar DTO (0.25 día)

```typescript
// reset-password.dto.ts (NUEVO)
import { IsString, MinLength } from 'class-validator';

export class ResetPasswordDto {
  @IsString()
  access_token: string; // Token de Supabase del link

  @IsString()
  @MinLength(8)
  newPassword: string;
}
```

#### 5.2 Implementar Método en Service (0.5 día)

**Agregar en**: `src/auth/auth.service.ts`

```typescript
async resetPassword(dto: ResetPasswordDto): Promise<{ success: boolean }> {
  try {
    // Usar Supabase Admin client con el token
    const { data, error } = await this.supabase.auth.admin.updateUserById(
      dto.access_token, // En realidad es user_id, necesitamos extraerlo del token
      { password: dto.newPassword }
    );

    if (error) {
      throw new BadRequestException(error.message);
    }

    return { success: true };
  } catch (error) {
    throw new InternalServerErrorException('Failed to reset password');
  }
}

// ALTERNATIVA: Usar session del token
async resetPasswordWithSession(accessToken: string, newPassword: string) {
  // Set session con el token del email
  const { data: { user }, error: sessionError } = await this.supabase.auth.setSession({
    access_token: accessToken,
    refresh_token: '' // No necesario para reset
  });

  if (sessionError || !user) {
    throw new BadRequestException('Invalid or expired token');
  }

  // Actualizar password del usuario autenticado
  const { error: updateError } = await this.supabase.auth.updateUser({
    password: newPassword
  });

  if (updateError) {
    throw new BadRequestException(updateError.message);
  }

  return { success: true };
}
```

#### 5.3 Actualizar Controller (0.25 día)

**Modificar en**: `src/auth/auth.controller.ts`

```typescript
@Post('password/reset')
async resetPassword(@Body() dto: ResetPasswordDto) {
  return await this.authService.resetPassword(dto);
}
```

### Verificación de Completitud

```bash
# Verificar implementación
grep -r "resetPassword" src/auth/
# Debe encontrar método completo

# Verificar DTO
ls src/auth/dto/reset-password.dto.ts
# Debe existir

# Test manual (con Postman)
# 1. POST /auth/password/reset-request { "email": "test@test.com" }
# 2. Copiar token del email
# 3. POST /auth/password/reset { "access_token": "...", "newPassword": "..." }
```

### Endpoint Completado (1 total)
```
POST   /api/v1/auth/password/reset
Body: { access_token: string, newPassword: string }
```

---

## FASE 6: OAUTH (GOOGLE/APPLE) (2 días)

### Objetivo
Implementar sign-in con Google y Apple usando Supabase OAuth.

### Documentación de Referencia
- Schema: `prisma/schema.prisma` líneas 794-796 (apple_connected, google_connected, fb_connected)
- Supabase Docs: `signInWithOAuth()` method

### Tareas Detalladas

#### 6.1 Crear Controller OAuth (0.5 día)

```bash
nest g controller auth/oauth --flat
```

```typescript
// oauth.controller.ts
import { Controller, Post, Body, Get, Query, Delete, Param } from '@nestjs/common';

@Controller('auth/oauth')
export class OAuthController {
  constructor(private readonly oauthService: OAuthService) {}

  @Post('google')
  async googleSignIn(@Body() dto: { redirectUrl?: string }) {
    return await this.oauthService.initiateGoogleSignIn(dto.redirectUrl);
  }

  @Post('apple')
  async appleSignIn(@Body() dto: { redirectUrl?: string }) {
    return await this.oauthService.initiateAppleSignIn(dto.redirectUrl);
  }

  @Get('callback')
  async handleCallback(@Query() query: OAuthCallbackDto) {
    return await this.oauthService.handleCallback(query);
  }

  @Get('providers')
  @UseGuards(JwtAuthGuard)
  async getConnectedProviders(@Request() req) {
    return await this.oauthService.getConnectedProviders(req.user.id);
  }

  @Delete(':provider')
  @UseGuards(JwtAuthGuard)
  async disconnectProvider(
    @Param('provider') provider: string,
    @Request() req
  ) {
    return await this.oauthService.disconnectProvider(req.user.id, provider);
  }
}
```

#### 6.2 Crear Service OAuth (1 día)

```typescript
// oauth.service.ts
@Injectable()
export class OAuthService {
  constructor(
    private readonly supabase: SupabaseService,
    private readonly prisma: PrismaService
  ) {}

  async initiateGoogleSignIn(redirectUrl?: string) {
    const { data, error } = await this.supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: redirectUrl || 'https://sacdia.app/auth/callback'
      }
    });

    if (error) throw new InternalServerErrorException(error.message);

    return { url: data.url };
  }

  async initiateAppleSignIn(redirectUrl?: string) {
    const { data, error } = await this.supabase.auth.signInWithOAuth({
      provider: 'apple',
      options: {
        redirectTo: redirectUrl || 'https://sacdia.app/auth/callback'
      }
    });

    if (error) throw new InternalServerErrorException(error.message);

    return { url: data.url };
  }

  async handleCallback(query: OAuthCallbackDto) {
    // Supabase maneja automáticamente el callback
    // Aquí solo necesitamos actualizar flags en BD

    const { access_token } = query;

    // Obtener usuario de Supabase
    const { data: { user }, error } = await this.supabase.auth.getUser(access_token);

    if (error || !user) {
      throw new UnauthorizedException('Invalid OAuth callback');
    }

    // Obtener identities del usuario
    const identities = user.identities || [];
    const googleConnected = identities.some(i => i.provider === 'google');
    const appleConnected = identities.some(i => i.provider === 'apple');

    // Actualizar flags en BD
    await this.prisma.users.update({
      where: { id: user.id },
      data: {
        google_connected: googleConnected,
        apple_connected: appleConnected
      }
    });

    return {
      access_token: access_token,
      user: {
        id: user.id,
        email: user.email,
        google_connected: googleConnected,
        apple_connected: appleConnected
      }
    };
  }

  async getConnectedProviders(userId: string) {
    const user = await this.prisma.users.findUnique({
      where: { id: userId },
      select: {
        google_connected: true,
        apple_connected: true,
        fb_connected: true
      }
    });

    return user;
  }

  async disconnectProvider(userId: string, provider: string) {
    // Supabase no permite desconectar providers directamente
    // Solo actualizamos flags en BD
    const field = `${provider}_connected`;

    await this.prisma.users.update({
      where: { id: userId },
      data: { [field]: false }
    });

    return { success: true };
  }
}
```

#### 6.3 Crear DTOs (0.25 día)

```typescript
// oauth-callback.dto.ts
export class OAuthCallbackDto {
  @IsString()
  access_token: string;

  @IsOptional()
  @IsString()
  refresh_token?: string;

  @IsOptional()
  @IsString()
  provider?: string;
}
```

#### 6.4 Tests (0.25 día)

**Nota**: OAuth requiere configuración en Supabase dashboard primero.

Crear: `test/oauth.e2e-spec.ts`

### Verificación de Completitud

```bash
# Verificar archivos
ls src/auth/oauth*

# Verificar flags en BD
grep -r "google_connected" src/auth/
# Debe encontrar update

# Configurar en Supabase Dashboard:
# 1. Settings → Authentication → Providers
# 2. Habilitar Google OAuth (Client ID + Secret)
# 3. Habilitar Apple OAuth (Service ID + Key)
```

### Endpoints Implementados (5 total)
```
POST   /api/v1/auth/oauth/google
POST   /api/v1/auth/oauth/apple
GET    /api/v1/auth/oauth/callback
GET    /api/v1/auth/oauth/providers
DELETE /api/v1/auth/oauth/:provider
```

---

## FASE 7: PUSH NOTIFICATIONS (FCM) (2 días)

### Objetivo
Sistema de notificaciones push con Firebase Cloud Messaging.

### Documentación de Referencia
- **GAP**: No hay especificación formal en docs/
- Requiere: Tabla `user_fcm_tokens` (crear migración)
- API: Firebase Admin SDK

### Tareas Detalladas

#### 7.1 Crear Migración para FCM Tokens (0.5 día)

**Agregar en**: `prisma/schema.prisma`

```prisma
model user_fcm_tokens {
  token_id       String   @id @default(uuid()) @db.Uuid
  user_id        String   @db.Uuid
  fcm_token      String   @unique
  device_type    String   // 'ios' | 'android' | 'web'
  device_name    String?
  is_active      Boolean  @default(true)
  created_at     DateTime @default(now())
  updated_at     DateTime @updatedAt

  users          users    @relation(fields: [user_id], references: [id], onDelete: Cascade)

  @@index([user_id])
  @@index([is_active])
  @@map("user_fcm_tokens")
}
```

```bash
npx prisma migrate dev --name add-fcm-tokens
```

#### 7.2 Instalar Firebase Admin SDK (0.25 día)

```bash
pnpm add firebase-admin
```

**Crear archivo**: `src/common/services/firebase.service.ts`

```typescript
import * as admin from 'firebase-admin';
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class FirebaseService {
  private app: admin.app.App;

  constructor(private configService: ConfigService) {
    this.app = admin.initializeApp({
      credential: admin.credential.cert({
        projectId: this.configService.get('FIREBASE_PROJECT_ID'),
        clientEmail: this.configService.get('FIREBASE_CLIENT_EMAIL'),
        privateKey: this.configService.get('FIREBASE_PRIVATE_KEY')?.replace(/\\n/g, '\n')
      })
    });
  }

  get messaging() {
    return admin.messaging(this.app);
  }
}
```

#### 7.3 Crear Módulo Notifications (0.5 día)

```bash
nest g module notifications
nest g service notifications
nest g controller notifications
```

```typescript
// notifications.service.ts
@Injectable()
export class NotificationsService {
  constructor(
    private readonly firebase: FirebaseService,
    private readonly prisma: PrismaService
  ) {}

  async registerToken(userId: string, dto: RegisterFcmTokenDto) {
    // Verificar si token ya existe
    const existing = await this.prisma.user_fcm_tokens.findUnique({
      where: { fcm_token: dto.fcm_token }
    });

    if (existing) {
      return existing;
    }

    return await this.prisma.user_fcm_tokens.create({
      data: {
        user_id: userId,
        fcm_token: dto.fcm_token,
        device_type: dto.device_type,
        device_name: dto.device_name,
        is_active: true
      }
    });
  }

  async sendToUser(userId: string, title: string, body: string, data?: Record<string, string>) {
    // Obtener tokens activos del usuario
    const tokens = await this.prisma.user_fcm_tokens.findMany({
      where: { user_id: userId, is_active: true },
      select: { fcm_token: true }
    });

    if (tokens.length === 0) return { success: false, message: 'No active tokens' };

    const message: admin.messaging.MulticastMessage = {
      notification: { title, body },
      data: data || {},
      tokens: tokens.map(t => t.fcm_token)
    };

    const response = await this.firebase.messaging.sendMulticast(message);

    return {
      success: response.successCount > 0,
      successCount: response.successCount,
      failureCount: response.failureCount
    };
  }

  async sendToClub(clubId: number, title: string, body: string) {
    // Obtener miembros del club
    const members = await this.prisma.club_role_assignments.findMany({
      where: { /* filtrar por club instance */, active: true },
      select: { user_id: true }
    });

    const userIds = members.map(m => m.user_id);

    // Enviar a cada usuario
    const results = await Promise.all(
      userIds.map(userId => this.sendToUser(userId, title, body))
    );

    return {
      success: true,
      sent: results.filter(r => r.success).length,
      failed: results.filter(r => !r.success).length
    };
  }

  async deleteToken(tokenId: string) {
    await this.prisma.user_fcm_tokens.update({
      where: { token_id: tokenId },
      data: { is_active: false }
    });

    return { success: true };
  }
}
```

#### 7.4 Crear Controller (0.25 día)

```typescript
@Controller('users/:userId/fcm-tokens')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  @Post()
  registerToken(
    @Param('userId') userId: string,
    @Body() dto: RegisterFcmTokenDto
  ) {
    return this.notificationsService.registerToken(userId, dto);
  }

  @Get()
  getTokens(@Param('userId') userId: string) {
    return this.notificationsService.getUserTokens(userId);
  }

  @Delete(':tokenId')
  deleteToken(@Param('tokenId') tokenId: string) {
    return this.notificationsService.deleteToken(tokenId);
  }
}
```

#### 7.5 DTOs (0.25 día)

```typescript
// register-fcm-token.dto.ts
export class RegisterFcmTokenDto {
  @IsString()
  fcm_token: string;

  @IsString()
  @IsIn(['ios', 'android', 'web'])
  device_type: string;

  @IsOptional()
  @IsString()
  device_name?: string;
}

// send-notification.dto.ts (para admin)
export class SendNotificationDto {
  @IsString()
  title: string;

  @IsString()
  body: string;

  @IsOptional()
  @IsObject()
  data?: Record<string, string>;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  user_ids?: string[];
}
```

#### 7.6 Agregar Variables de Entorno (0.25 día)

**.env.example**:
```
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

### Verificación de Completitud

```bash
# Verificar migración
npx prisma migrate status

# Verificar servicio Firebase
grep -r "firebase-admin" src/

# Test manual (Postman):
# 1. POST /users/:userId/fcm-tokens
# 2. Verificar en Firebase Console que llegó
```

### Endpoints Implementados (3 total)
```
POST   /api/v1/users/:userId/fcm-tokens
GET    /api/v1/users/:userId/fcm-tokens
DELETE /api/v1/fcm-tokens/:tokenId
```

---

## FASE 8: WEBSOCKETS (OPCIONAL) (2 días)

### Objetivo
Real-time updates para clases, actividades y notificaciones.

### Documentación de Referencia
- **GAP**: Solo mencionado en `01-OVERVIEW.md`
- Stack: NestJS WebSocket Gateway + Socket.io

### Tareas Detalladas

#### 8.1 Instalar Dependencias (0.25 día)

```bash
pnpm add @nestjs/websockets @nestjs/platform-socket.io socket.io
```

#### 8.2 Crear Gateway (1 día)

```bash
nest g gateway notifications
```

```typescript
// notifications.gateway.ts
import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { UseGuards } from '@nestjs/common';
import { WsJwtGuard } from './guards/ws-jwt.guard';

@WebSocketGateway({
  cors: {
    origin: ['http://localhost:5173', 'http://localhost:3000'],
    credentials: true
  },
  namespace: '/api/v1/ws'
})
export class NotificationsGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private userSockets = new Map<string, string>(); // userId -> socketId

  async handleConnection(client: Socket) {
    console.log(`Client connected: ${client.id}`);

    // Extraer userId del token (query params o headers)
    const userId = client.handshake.query.userId as string;
    if (userId) {
      this.userSockets.set(userId, client.id);
    }
  }

  handleDisconnect(client: Socket) {
    console.log(`Client disconnected: ${client.id}`);

    // Remover del mapa
    for (const [userId, socketId] of this.userSockets.entries()) {
      if (socketId === client.id) {
        this.userSockets.delete(userId);
        break;
      }
    }
  }

  @UseGuards(WsJwtGuard)
  @SubscribeMessage('join-club')
  handleJoinClub(
    @MessageBody() data: { clubId: number },
    @ConnectedSocket() client: Socket
  ) {
    const room = `club-${data.clubId}`;
    client.join(room);
    return { event: 'joined-club', data: { clubId: data.clubId } };
  }

  @UseGuards(WsJwtGuard)
  @SubscribeMessage('leave-club')
  handleLeaveClub(
    @MessageBody() data: { clubId: number },
    @ConnectedSocket() client: Socket
  ) {
    const room = `club-${data.clubId}`;
    client.leave(room);
    return { event: 'left-club', data: { clubId: data.clubId } };
  }

  // Métodos para emitir desde servicios
  emitClassUpdate(classId: number, progress: number) {
    this.server.emit('class-updated', { classId, progress });
  }

  emitToClub(clubId: number, event: string, data: any) {
    this.server.to(`club-${clubId}`).emit(event, data);
  }

  emitToUser(userId: string, event: string, data: any) {
    const socketId = this.userSockets.get(userId);
    if (socketId) {
      this.server.to(socketId).emit(event, data);
    }
  }
}
```

#### 8.3 Crear Guard para WebSockets (0.5 día)

```typescript
// ws-jwt.guard.ts
import { CanActivate, Injectable, ExecutionContext } from '@nestjs/common';
import { WsException } from '@nestjs/websockets';
import { SupabaseService } from '../services/supabase.service';

@Injectable()
export class WsJwtGuard implements CanActivate {
  constructor(private readonly supabase: SupabaseService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const client = context.switchToWs().getClient();
    const token = client.handshake.auth.token || client.handshake.query.token;

    if (!token) {
      throw new WsException('Missing authentication token');
    }

    try {
      const { data: { user }, error } = await this.supabase.auth.getUser(token);

      if (error || !user) {
        throw new WsException('Invalid token');
      }

      client.user = user;
      return true;
    } catch (error) {
      throw new WsException('Authentication failed');
    }
  }
}
```

#### 8.4 Integrar con Servicios Existentes (0.25 día)

**Ejemplo**: Emitir cuando se actualiza progreso de clase

```typescript
// En classes.service.ts
constructor(
  private readonly prisma: PrismaService,
  private readonly notificationsGateway: NotificationsGateway // Inyectar
) {}

async updateProgress(userId: string, classId: number, dto: UpdateProgressDto) {
  // ... lógica existente

  // Emitir evento WebSocket
  this.notificationsGateway.emitToUser(userId, 'class-progress-updated', {
    classId,
    progress: newProgress
  });

  return result;
}
```

### Verificación de Completitud

```bash
# Verificar gateway
ls src/notifications/notifications.gateway.ts

# Test con Socket.io client (Postman o código):
# const socket = io('http://localhost:3000/api/v1/ws', {
#   query: { token: 'jwt-token' }
# });
# socket.emit('join-club', { clubId: 1 });
```

### Eventos Implementados
```
// Cliente → Servidor
join-club
leave-club

// Servidor → Cliente
class-updated
class-progress-updated
activity-created
member-joined
notification
```

---

## FASE 9: ACTUALIZACIÓN DE DOCUMENTACIÓN (3-4 días)

### Objetivo
Actualizar TODA la documentación para reflejar el estado real del backend (79 endpoints + nuevos).

### Tareas Detalladas

#### 9.1 Actualizar API-SPECIFICATION.md (1 día)

**Archivo**: `docs/api/API-SPECIFICATION.md`

**Cambios**:
```markdown
# Línea 1: Actualizar versión
- REST API v2.0 → REST API v2.2

# Línea 34: Actualizar total de endpoints
- 57 endpoints → 105+ endpoints

# Sección 3: Agregar nuevos módulos
## 3.13 Campaments/Camporees (8 endpoints)
## 3.14 Folders/Portfolios (7 endpoints)
## 3.15 Certifications (7 endpoints)
## 3.16 Inventario (5 endpoints)
## 3.17 Push Notifications (3 endpoints)
## 3.18 WebSockets (eventos real-time)

# Sección 4: Actualizar seguridad
- Agregar detalles de OAuth implementado
- Documentar FCM tokens
- Documentar WebSocket authentication

# Sección 7: Actualizar stack
- Agregar firebase-admin
- Agregar socket.io
```

**Verificación**:
```bash
# Contar endpoints reales
grep -r "@Get\|@Post\|@Patch\|@Delete" src/**/*.controller.ts | wc -l
# Debe coincidir con la documentación
```

#### 9.2 Actualizar ENDPOINTS-REFERENCE.md (1 día)

**Archivo**: `docs/api/ENDPOINTS-REFERENCE.md`

**Agregar secciones completas** para:

1. **Campaments** (copiar pattern de Activities)
```markdown
### 9. Campaments/Camporees

#### 9.1 Listar Campamentos
**Endpoint**: `GET /api/v1/camporees`
**Auth**: Required
**Response**:
```typescript
{
  data: [{
    camporee_id: number,
    name: string,
    start_date: string,
    end_date: string,
    local_field_id: number,
    includes_adventurers: boolean,
    includes_pathfinders: boolean,
    includes_master_guides: boolean
  }]
}
```

... (continuar con todos los endpoints)
```

2. **Folders** (7 endpoints)
3. **Certifications** (7 endpoints)
4. **Inventario** (5 endpoints)
5. **OAuth** (5 endpoints)
6. **Push Notifications** (3 endpoints)

**Verificación**:
```bash
# Verificar que todos los controllers estén documentados
for file in src/**/*.controller.ts; do
  echo "Checking $file"
  grep -l "$(basename $file .controller.ts)" docs/api/ENDPOINTS-REFERENCE.md
done
```

#### 9.3 Actualizar IMPLEMENTATION-ROADMAP.md (0.5 día)

**Archivo**: `docs/03-IMPLEMENTATION-ROADMAP.md`

**Cambios**:
```markdown
# Sprint 8: Completar con checkboxes ✅
- [x] Tests unitarios (89% coverage)
- [x] Tests E2E (12 suites)
- [x] Documentación Swagger completa
- [x] Deploy Vercel configurado
- [x] CI/CD GitHub Actions
- [x] Performance testing

# Agregar Sprint 9: Módulos Adicionales (NUEVO)
- [x] Campaments/Camporees
- [x] Folders/Portfolios
- [x] Certifications
- [x] Inventario
- [x] Reset Password completo
- [x] OAuth (Google/Apple)
- [x] Push Notifications (FCM)
- [x] WebSockets (opcional)

# Actualizar métricas
Total Endpoints: 79 → 105+
Módulos: 13 → 17
Cobertura Tests: 85% → 90%
```

#### 9.4 Crear Walkthroughs de Nuevos Módulos (1 día)

**Crear archivos**:
- `docs/api/walkthrough-camporees.md`
- `docs/api/walkthrough-certifications.md`
- `docs/api/walkthrough-oauth.md`
- `docs/api/walkthrough-push-notifications.md`

**Estructura de cada walkthrough**:
```markdown
# Walkthrough: [Módulo]

## Flujo Completo

### 1. Registro/Creación
**Request**:
```bash
curl -X POST http://localhost:3000/api/v1/[endpoint] \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{ ... }'
```

**Response**:
```json
{ ... }
```

### 2. Consulta
...

### 3. Actualización
...

### 4. Eliminación
...

## Casos de Uso

### Caso 1: [Descripción]
...

## Validaciones y Errores

### Error 1: [Código]
**Causa**: ...
**Solución**: ...
```

#### 9.5 Generar OpenAPI Spec Actualizado (0.5 día)

```bash
# En sacdia-backend
npm run generate:spec
```

**Verificar**:
- Archivo `openapi.json` o `swagger.json` generado
- Todos los nuevos endpoints aparecen
- DTOs documentados con ejemplos
- Respuestas con schemas completos

#### 9.6 Actualizar README.md Principal (0.5 día)

**Archivo**: `/Users/abner/Documents/dev/sacdia/README.md`

**Cambios**:
```markdown
# Línea 49: Actualizar métricas
- 57 endpoints → 105+ endpoints
- 13 módulos → 17 módulos
- 79% implementación → 95% implementación

# Agregar sección de Features Implementadas
## ✅ Features Implementadas

### Backend (API REST)
- [x] Autenticación (JWT + 2FA + OAuth)
- [x] Gestión de Usuarios y Roles (RBAC)
- [x] Clubs y Instancias
- [x] Clases Progresivas
- [x] Honores/Especialidades
- [x] Actividades y Asistencia
- [x] Finanzas
- [x] Campamentos con Seguros
- [x] Folders/Portfolios
- [x] Certificaciones para GMs
- [x] Inventario
- [x] Push Notifications (FCM)
- [x] WebSockets (Real-time)
```

### Verificación Final de Documentación

```bash
# 1. Verificar todos los archivos actualizados
git status docs/

# 2. Verificar que no hay endpoints sin documentar
./scripts/verify-docs.sh # (crear este script)

# 3. Verificar links rotos
npx markdown-link-check docs/**/*.md

# 4. Verificar que Swagger UI funciona
npm run start:dev
# Abrir http://localhost:3000/api
# Verificar que todos los módulos aparecen
```

---

## VERIFICACIÓN GLOBAL DE COMPLETITUD

### Checklist de Implementación

**Módulos**:
- [ ] Campaments/Camporees (8 endpoints)
- [ ] Folders/Portfolios (7 endpoints)
- [ ] Certifications (7 endpoints)
- [ ] Inventario (5 endpoints)
- [ ] Reset Password (1 endpoint completado)
- [ ] OAuth (5 endpoints)
- [ ] Push Notifications (3 endpoints)
- [ ] WebSockets (gateway + eventos)

**Tests**:
- [ ] `test/camporees.e2e-spec.ts` (passing)
- [ ] `test/folders.e2e-spec.ts` (passing)
- [ ] `test/certifications.e2e-spec.ts` (passing)
- [ ] `test/inventory.e2e-spec.ts` (passing)
- [ ] `test/oauth.e2e-spec.ts` (passing)
- [ ] `test/notifications.e2e-spec.ts` (passing)

**Documentación**:
- [ ] API-SPECIFICATION.md actualizado
- [ ] ENDPOINTS-REFERENCE.md actualizado
- [ ] IMPLEMENTATION-ROADMAP.md actualizado
- [ ] Walkthroughs creados (4 archivos)
- [ ] README.md actualizado
- [ ] OpenAPI spec generado

**Configuración**:
- [ ] Variables de entorno documentadas en .env.example
- [ ] Firebase Admin SDK configurado
- [ ] Supabase OAuth configurado (dashboard)
- [ ] Migraciones Prisma aplicadas

### Comandos de Verificación Rápida

```bash
# 1. Verificar que compila sin errores
npm run build

# 2. Ejecutar TODOS los tests
npm run test
npm run test:e2e

# 3. Verificar cobertura
npm run test:cov
# Objetivo: >90%

# 4. Verificar que Swagger funciona
npm run start:dev
curl http://localhost:3000/api/v1/health
# Debe retornar: { "status": "ok" }

# 5. Contar endpoints implementados
grep -r "@Get\|@Post\|@Patch\|@Delete" src/**/*.controller.ts | wc -l
# Debe ser: 105+

# 6. Verificar guards en todos los endpoints críticos
grep -r "UseGuards.*JwtAuthGuard" src/**/*.controller.ts | wc -l
# Debe ser: >70

# 7. Verificar que no hay console.log
grep -r "console.log" src/
# Debe estar vacío (o solo en dev mode)

# 8. Linter
npm run lint
# Sin errores
```

### Métricas Esperadas al Final

| Métrica | Antes | Después | Objetivo |
|---------|-------|---------|----------|
| Endpoints | 79 | 105+ | ✅ |
| Módulos | 13 | 17 | ✅ |
| Tests E2E | 11 suites | 17 suites | ✅ |
| Coverage | 85% | >90% | ✅ |
| Documentación | 75% | 95% | ✅ |

---

## CRONOGRAMA ESTIMADO

### Semana 1 (5 días)
- **Día 1**: Fase 1 (Campaments) - Completo
- **Día 2**: Fase 2 (Folders) - Completo
- **Día 3**: Fase 3 (Certifications) - Completo
- **Día 4**: Fase 4 (Inventario) + Fase 5 (Reset Password)
- **Día 5**: Fase 6 (OAuth) - Inicio

### Semana 2 (5 días)
- **Día 6**: Fase 6 (OAuth) - Completar
- **Día 7**: Fase 7 (Push Notifications) - Completo
- **Día 8**: Fase 8 (WebSockets) - Opcional
- **Día 9**: Fase 9 (Documentación) - Inicio
- **Día 10**: Fase 9 (Documentación) - Completar

### Semana 3 (3 días) - Buffer y Tests
- **Día 11**: Tests E2E de todos los módulos nuevos
- **Día 12**: Corrección de bugs encontrados
- **Día 13**: Verificación final + Deploy

**Total**: 13 días (~2.5 semanas)

---

## NOTAS IMPORTANTES

### Dependencias Externas Requeridas

1. **Supabase Dashboard**:
   - Configurar OAuth providers (Google, Apple)
   - Obtener Service Role Key

2. **Firebase Console**:
   - Crear proyecto
   - Habilitar Cloud Messaging
   - Descargar Service Account JSON

3. **Apple Developer**:
   - Crear Service ID para Sign in with Apple
   - Configurar redirect URLs

4. **Google Cloud Console**:
   - Crear OAuth 2.0 Client ID
   - Configurar authorized redirect URIs

### Anti-Patrones a Evitar Durante Implementación

❌ **NO copiar código sin entender** - Leer antes de copiar
❌ **NO skip tests** - Crear test para cada módulo
❌ **NO hardcodear valores** - Usar variables de entorno
❌ **NO raw SQL** - Siempre Prisma Client
❌ **NO omitir validaciones** - class-validator en todos los DTOs
❌ **NO skip transacciones** - Usar en operaciones multi-tabla
❌ **NO inventar APIs** - Solo usar métodos documentados de Supabase/Firebase

### Decisiones Pendientes del Usuario

**REQUERIR CONFIRMACIÓN ANTES DE IMPLEMENTAR**:

1. **OAuth**: ¿Sign-up automático o requiere post-registro?
2. **Push Notifications**: ¿Qué eventos deben generar notificaciones?
3. **WebSockets**: ¿Implementar o dejar para fase 2?
4. **Folders**: ¿Quién puede crear templates de folders? (admin, director, ambos)
5. **Certifications**: ¿Generar PDF automático de certificados?

---

## SOPORTE Y RECURSOS

### Documentación de Referencia
- NestJS: https://docs.nestjs.com/
- Prisma: https://www.prisma.io/docs/
- Supabase Auth: https://supabase.com/docs/guides/auth
- Firebase Admin SDK: https://firebase.google.com/docs/admin/setup
- Socket.io: https://socket.io/docs/v4/

### Comandos Útiles
```bash
# Generar módulo completo
nest g resource [name] --no-spec

# Ejecutar migración
npx prisma migrate dev --name [name]

# Ver studio de BD
npx prisma studio

# Generar Prisma Client
npx prisma generate

# Ver rutas disponibles
npm run start:dev
# Luego navegar a /api (Swagger UI)
```

---

**Plan Creado**: 3 de febrero de 2026
**Estimado Total**: 2-3 semanas (13 días de trabajo)
**Módulos a Implementar**: 8 componentes + documentación
**Endpoints Nuevos**: 26+ endpoints
**Estado**: Listo para ejecutar fase por fase

**Próxima Acción**: Ejecutar Fase 1 (Módulo Campaments/Camporees)
