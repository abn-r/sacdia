# Tasks: Módulo de Investiduras

**Feature**: Validación de Investiduras (#23)
**Propuesta**: `docs/features/investiture-proposal.md`
**Diseño técnico**: `docs/features/investiture-design.md`
**Estado de DB**: completa — no se requieren migraciones para el MVP
**Fecha**: 2026-03-20

---

## Orden de dependencias

```
Task 1 (scaffold + DTOs)
    │
    ▼
Task 2 (service — submitForValidation)
    │
Task 3 (service — validateEnrollment)
    │
Task 4 (service — markInvestido)
    │
Task 5 (service — getPending + getHistory)
    │
    ▼
Task 6 (controller + guards + Swagger)
    │
    ▼
Task 7 (registro en AppModule)
    │
    ▼
Task 8 (unit tests)
```

Tasks 2–5 son paralelas entre sí (todos implementan métodos del mismo service). Tasks 6 y 7 dependen de que las tareas de service estén completas. Task 8 depende de Task 6.

---

## Task 1: Scaffold del módulo + DTOs

### Archivos a crear

```
src/investiture/
├── investiture.module.ts
├── investiture.controller.ts          ← esqueleto vacío (sin endpoints aún)
├── investiture.service.ts             ← esqueleto vacío (sin métodos aún)
└── dto/
    ├── submit-for-validation.dto.ts
    ├── validate-enrollment.dto.ts
    ├── mark-investido.dto.ts
    └── index.ts
```

### Contenido de cada archivo

**`investiture.module.ts`**
```typescript
@Module({
  imports: [PrismaModule],
  controllers: [InvestitureController],
  providers: [InvestitureService],
  exports: [InvestitureService],
})
export class InvestitureModule {}
```

**`investiture.service.ts`** (esqueleto)
```typescript
@Injectable()
export class InvestitureService {
  constructor(private readonly prisma: PrismaService) {}
}
```

**`investiture.controller.ts`** (esqueleto)
```typescript
@ApiTags('investiture')
@ApiBearerAuth()
@Controller('api/v1')
export class InvestitureController {
  constructor(private readonly investitureService: InvestitureService) {}
}
```

**`dto/submit-for-validation.dto.ts`**
- Campo `comments?: string`
  - `@IsOptional()`
  - `@IsString()`
  - `@MaxLength(500)`
  - `@ApiPropertyOptional({ description: 'Comentario opcional del consejero/director', maxLength: 500 })`
- Campo `club_id: number`
  - `@IsInt()`
  - `@IsPositive()`
  - `@ApiProperty({ description: 'ID del club desde el que se envía (requerido por ClubRolesGuard)' })`

**`dto/validate-enrollment.dto.ts`**
- Campo `action: 'APPROVED' | 'REJECTED'`
  - `@IsEnum(['APPROVED', 'REJECTED'])`
  - `@IsNotEmpty()`
  - `@ApiProperty({ enum: ['APPROVED', 'REJECTED'], description: 'Decisión de validación' })`
- Campo `comments?: string`
  - `@IsOptional()`
  - `@IsString()`
  - `@MaxLength(1000)`
  - `@ApiPropertyOptional({ description: 'Requerido si action=REJECTED', maxLength: 1000 })`

**`dto/mark-investido.dto.ts`**
- Campo `comments?: string`
  - `@IsOptional()`
  - `@IsString()`
  - `@MaxLength(500)`
  - `@ApiPropertyOptional({ description: 'Comentario opcional del acto de investidura', maxLength: 500 })`

**`dto/index.ts`**
- Re-exportar los tres DTOs

### Criterios de aceptación

- [ ] Todos los archivos del directorio `src/investiture/` creados y compilables
- [ ] Los DTOs importan correctamente desde `class-validator` y `@nestjs/swagger`
- [ ] El módulo usa `PrismaModule` importado desde `src/prisma/prisma.module`
- [ ] El controller y service son esqueletos funcionales — sin métodos aún
- [ ] `pnpm run build` pasa sin errores

---

## Task 2: Service — submitForValidation

### Archivos a modificar

```
src/investiture/investiture.service.ts    ← agregar método + helper privado
```

### Método público: `submitForValidation`

**Firma**: `submitForValidation(enrollmentId: number, actorId: string, dto: SubmitForValidationDto): Promise<...>`

**Lógica paso a paso** (implementar en este orden):

1. Buscar enrollment por `enrollmentId` con `select` mínimo:
   ```
   { enrollment_id, user_id, class_id, ecclesiastical_year_id, investiture_status, locked_for_validation, active }
   include: { users: { select: { local_field_id } } }
   ```
2. Si no existe o `active === false` → lanzar `NotFoundException('Enrollment no encontrado')`
3. Verificar que `investiture_status` es `IN_PROGRESS` o `REJECTED`. Si es cualquier otro estado → lanzar `BadRequestException` con mensaje: `'Transición inválida. El enrollment está en estado ${currentStatus}'`
4. Resolver `investiture_config` con el helper privado `resolveInvestitureConfig` (ver abajo). Si no existe → `NotFoundException('No existe configuración de investidura para este campo local y año eclesiástico')`
5. Calcular `is_late`: comparar `new Date()` con `investiture_config.submission_deadline`. Si fecha actual supera el deadline → `is_late = true`. NO lanzar error — continuar el flujo.
6. Abrir transacción Prisma (forma de array):
   ```typescript
   prisma.$transaction([
     prisma.enrollments.update({
       where: { enrollment_id },
       data: {
         investiture_status: 'SUBMITTED_FOR_VALIDATION',
         submitted_for_validation: true,
         submitted_at: new Date(),
         locked_for_validation: true,
       }
     }),
     prisma.investiture_validation_history.create({
       data: {
         enrollment_id,
         action: 'SUBMITTED',
         performed_by: actorId,
         comments: dto.comments ?? null,
       }
     })
   ])
   ```
7. Retornar: `{ enrollment_id, investiture_status: 'SUBMITTED_FOR_VALIDATION', submitted_at, is_late }`

### Método privado helper: `resolveInvestitureConfig`

**Firma**: `private async resolveInvestitureConfig(enrollment: { user_id: string; ecclesiastical_year_id: number; users: { local_field_id: number } })`

**Lógica**:
1. Extraer `localFieldId = enrollment.users.local_field_id`
2. Extraer `yearId = enrollment.ecclesiastical_year_id`
3. `findFirst` en `investiture_config` donde: `{ local_field_id: localFieldId, ecclesiastical_year_id: yearId, active: true }`
4. Si no existe → lanzar `NotFoundException('No existe configuración de investidura para este campo local y año eclesiástico')`
5. Retornar el config encontrado

### Criterios de aceptación

- [ ] Caso feliz: enrollment `IN_PROGRESS` → status cambia a `SUBMITTED_FOR_VALIDATION`, `locked_for_validation = true`, `submitted_at` poblado
- [ ] Caso feliz: enrollment `REJECTED` → mismo resultado (re-envío funciona)
- [ ] Error: enrollment con `active = false` → `NotFoundException`
- [ ] Error: estado inválido (`APPROVED`, `SUBMITTED_FOR_VALIDATION`, `INVESTIDO`) → `BadRequestException` con estado actual en el mensaje
- [ ] Error: sin `investiture_config` activo para el campo local/año → `NotFoundException`
- [ ] Respuesta incluye `is_late: true` cuando se supera `submission_deadline`
- [ ] Registro creado en `investiture_validation_history` con `action = 'SUBMITTED'`
- [ ] La transacción es atómica — si falla el history, el enrollment no se actualiza

---

## Task 3: Service — validateEnrollment

### Archivos a modificar

```
src/investiture/investiture.service.ts    ← agregar método
```

### Método: `validateEnrollment`

**Firma**: `validateEnrollment(enrollmentId: number, actorId: string, dto: ValidateEnrollmentDto): Promise<...>`

**Lógica paso a paso**:

1. Buscar enrollment. Si no existe → `NotFoundException('Enrollment no encontrado')`
2. Verificar que `investiture_status === 'SUBMITTED_FOR_VALIDATION'`. Si no → `ConflictException('El enrollment no está en estado SUBMITTED_FOR_VALIDATION. Estado actual: ${currentStatus}')`
3. **Validación de negocio** (no está en el DTO): si `dto.action === 'REJECTED'` y `(!dto.comments || dto.comments.trim() === '')` → `BadRequestException('El campo comments es requerido para rechazar un enrollment')`
4. Abrir transacción Prisma (forma callback interactivo):

   **Si `dto.action === 'APPROVED'`**:
   ```typescript
   await tx.enrollments.update({
     where: { enrollment_id },
     data: {
       investiture_status: 'APPROVED',
       validated_by: actorId,
       validated_at: new Date(),
       rejection_reason: null,
       locked_for_validation: true,   // sigue bloqueado hasta investidura
     }
   })
   await tx.investiture_validation_history.create({
     data: { enrollment_id, action: 'APPROVED', performed_by: actorId, comments: dto.comments ?? null }
   })
   ```

   **Si `dto.action === 'REJECTED'`**:
   ```typescript
   await tx.enrollments.update({
     where: { enrollment_id },
     data: {
       investiture_status: 'REJECTED',
       validated_by: actorId,
       validated_at: new Date(),
       rejection_reason: dto.comments,
       locked_for_validation: false,       // DESBLOQUEAR para corrección
       submitted_for_validation: false,    // permitir re-envío
     }
   })
   await tx.investiture_validation_history.create({
     data: { enrollment_id, action: 'REJECTED', performed_by: actorId, comments: dto.comments }
   })
   ```

5. Retornar: `{ enrollment_id, investiture_status, validated_by, validated_at, rejection_reason }`

### Validaciones de negocio críticas

- `REJECTED` **debe** desbloquear el enrollment (`locked_for_validation = false`) — esto es lo que permite al club editar y re-enviar
- `APPROVED` **mantiene** `locked_for_validation = true` — el enrollment queda bloqueado hasta que se registre la investidura
- `comments` es obligatorio cuando `action === 'REJECTED'` — validar en el service, no en el DTO

### Criterios de aceptación

- [ ] Caso feliz: `SUBMITTED_FOR_VALIDATION` + `APPROVED` → status cambia a `APPROVED`, enrollment sigue bloqueado
- [ ] Caso feliz: `SUBMITTED_FOR_VALIDATION` + `REJECTED` → status cambia a `REJECTED`, enrollment desbloqueado (`locked_for_validation = false`, `submitted_for_validation = false`)
- [ ] Error: `REJECTED` sin `comments` → `BadRequestException`
- [ ] Error: estado distinto de `SUBMITTED_FOR_VALIDATION` → `ConflictException`
- [ ] `rejection_reason` se popula en enrollment al rechazar
- [ ] `rejection_reason` se limpia a `null` al aprobar
- [ ] Registro creado en `investiture_validation_history` con la acción correcta (`APPROVED` o `REJECTED`)
- [ ] La transacción es atómica

---

## Task 4: Service — markInvestido

### Archivos a modificar

```
src/investiture/investiture.service.ts    ← agregar método
```

### Método: `markInvestido`

**Firma**: `markInvestido(enrollmentId: number, actorId: string, dto: MarkInvestidoDto): Promise<...>`

**Lógica paso a paso**:

1. Buscar enrollment con `select`:
   ```
   { enrollment_id, user_id, class_id, ecclesiastical_year_id, investiture_status }
   include: { users: { select: { local_field_id } } }
   ```
2. Si no existe → `NotFoundException('Enrollment no encontrado')`
3. Si `investiture_status === 'INVESTIDO'` → `ConflictException('El enrollment ya fue investido')`
4. Si `investiture_status !== 'APPROVED'` → `BadRequestException('El enrollment debe estar en estado APPROVED para ser investido. Estado actual: ${currentStatus}')`
5. Resolver `investiture_config` usando el helper `resolveInvestitureConfig`. Si no existe → `NotFoundException`
6. Abrir transacción Prisma (forma callback interactivo — tres operaciones en secuencia):

   ```typescript
   prisma.$transaction(async (tx) => {
     // 6a. Actualizar enrollment
     const updated = await tx.enrollments.update({
       where: { enrollment_id },
       data: {
         investiture_status: 'INVESTIDO',
         investiture_date: investiture_config.investiture_date,
       }
     })

     // 6b. Registrar en history
     // NOTA: investiture_action_enum no tiene valor 'INVESTIDO'.
     // Usar 'APPROVED' con comentario contextual hasta agregar el valor al enum.
     await tx.investiture_validation_history.create({
       data: {
         enrollment_id,
         action: 'APPROVED',
         performed_by: actorId,
         comments: dto.comments ?? 'Investidura formal registrada',
       }
     })

     // 6c. [ARCHIVADO] Auto-sync users_classes ya no aplica — tabla removida.
     // El histórico se consulta directamente desde enrollments.

     return updated
   })
   ```

   **NOTA HISTÓRICA**: El sincronismo con `users_classes` fue removido. La tabla se archivó como `users_classes_archive`. No es necesario hacer upsert ni sync manual.
   }
   ```

7. Retornar: `{ enrollment_id, investiture_status: 'INVESTIDO', investiture_date }`

### Criterios de aceptación

- [ ] Caso feliz: enrollment `APPROVED` → status cambia a `INVESTIDO`, `investiture_date` poblado con la fecha de `investiture_config`
- [ ] `investiture_date` en el enrollment coincide con `investiture_config.investiture_date` (no acepta fecha del body)
- [ ] Error: enrollment ya en `INVESTIDO` → `ConflictException`
- [ ] Error: enrollment en estado distinto de `APPROVED` → `BadRequestException`
- [ ] Error: sin `investiture_config` activo → `NotFoundException`
- [ ] Registro creado en `investiture_validation_history`
- [ ] La transacción es atómica

---

## Task 5: Service — getPending + getHistory

### Archivos a modificar

```
src/investiture/investiture.service.ts    ← agregar dos métodos
```

### Método: `getPending`

**Firma**: `getPending(localFieldId?: number, ecclesiasticalYearId?: number, page?: number, limit?: number): Promise<...>`

**Lógica**:

1. Construir cláusula `where`:
   ```typescript
   const where: Prisma.enrollmentsWhereInput = {
     investiture_status: 'SUBMITTED_FOR_VALIDATION',
     active: true,
   }
   if (localFieldId) {
     where.users = { local_field_id: localFieldId }
   }
   if (ecclesiasticalYearId) {
     where.ecclesiastical_year_id = ecclesiasticalYearId
   }
   ```

2. Ejecutar `findMany` con `include`:
   ```typescript
   {
     users: { select: { first_name: true, last_name: true, email: true } },
     classes: { select: { name: true } },
     ecclesiastical_year: { select: { start_date: true, end_date: true } },
   }
   ```

3. Aplicar paginación usando `PaginationDto` y el helper `createPaginatedResult` del módulo `common`. Referencia de uso: ver cualquier service en `src/honors/` o `src/activities/`.

4. Retornar resultado paginado. Cada item debe incluir:
   `{ enrollment_id, user: { first_name, last_name, email }, class_name, submitted_at, ecclesiastical_year, investiture_status }`

### Método: `getHistory`

**Firma**: `getHistory(enrollmentId: number, actorId: string, actorGlobalRoles: string[]): Promise<...>`

**Lógica**:

1. Buscar enrollment para verificar que existe. Si no → `NotFoundException('Enrollment no encontrado')`

2. **Verificación de autorización programática** (dual-role access):
   ```typescript
   const hasGlobalAccess = actorGlobalRoles.some(r => ['admin', 'coordinator', 'super_admin'].includes(r))
   if (!hasGlobalAccess) {
     // Verificar que el actor tiene rol activo en el club del enrollment
     const roleAssignment = await this.prisma.club_role_assignments.findFirst({
       where: {
         user_id: actorId,
         active: true,
         club_sections: {
           clubs: {
             members: {
               some: { user_id: enrollment.user_id, active: true }
             }
           }
         }
       }
     })
     if (!roleAssignment) throw new ForbiddenException('Sin acceso al historial de este enrollment')
   }
   ```

3. Buscar todos los registros de `investiture_validation_history` donde `enrollment_id = enrollmentId`, ordenados por `created_at ASC`:
   ```typescript
   include: { users: { select: { first_name: true, last_name: true } } }
   ```

4. Retornar:
   ```typescript
   {
     enrollment_id,
     history: [
       { history_id, action, performed_by: { first_name, last_name }, comments, created_at }
     ]
   }
   ```

### Criterios de aceptación — getPending

- [ ] Retorna solo enrollments con `investiture_status = SUBMITTED_FOR_VALIDATION` y `active = true`
- [ ] Filtra por `local_field_id` del usuario del enrollment cuando se provee `localFieldId`
- [ ] Filtra por `ecclesiastical_year_id` cuando se provee
- [ ] Si no se provee ningún filtro, retorna todos los pendientes
- [ ] Paginación funciona con `page` y `limit` estándar
- [ ] Cada resultado incluye información del usuario, clase y año eclesiástico

### Criterios de aceptación — getHistory

- [ ] Admin o coordinator pueden ver el historial de cualquier enrollment
- [ ] Director/consejero puede ver historial si tiene rol activo en el club del enrollment
- [ ] Actor sin acceso al club del enrollment → `ForbiddenException`
- [ ] Enrollment no encontrado → `NotFoundException`
- [ ] Los registros están ordenados por `created_at ASC` (cronológico)
- [ ] Cada entrada incluye el nombre del actor que realizó la acción

---

## Task 6: Controller + guards + Swagger

### Archivos a modificar

```
src/investiture/investiture.controller.ts    ← implementar los 5 endpoints
```

### Dependencias de guards existentes a importar

Buscar en el codebase los guards necesarios (no crear nuevos):
- `JwtAuthGuard` — en `src/auth/`
- `GlobalRolesGuard` — en `src/rbac/` o `src/auth/`
- `ClubRolesGuard` — en `src/rbac/` o `src/clubs/`
- Decoradores `@GlobalRoles(...)` y `@ClubRoles(...)` — buscar donde están definidos

### Endpoint 1: POST /enrollments/:enrollmentId/submit-for-validation

```typescript
@Post('enrollments/:enrollmentId/submit-for-validation')
@UseGuards(JwtAuthGuard, ClubRolesGuard)
@ClubRoles('director', 'counselor')
@ApiOperation({ summary: 'Enviar enrollment a validación de investidura' })
@ApiParam({ name: 'enrollmentId', type: Number })
@ApiResponse({ status: 200, description: 'Enrollment enviado a validación' })
@ApiResponse({ status: 400, description: 'Estado actual no permite la transición' })
@ApiResponse({ status: 403, description: 'Sin rol de director o consejero' })
@ApiResponse({ status: 404, description: 'Enrollment o config no encontrado' })
@ApiResponse({ status: 409, description: 'Ya está en SUBMITTED_FOR_VALIDATION' })
async submitForValidation(
  @Param('enrollmentId', ParseIntPipe) enrollmentId: number,
  @Body() dto: SubmitForValidationDto,
  @Request() req,
)
```

Extraer `actorId = req.user.sub` (o `req.user.id` — verificar la propiedad correcta en el payload JWT revisando otros controllers del proyecto).

### Endpoint 2: POST /enrollments/:enrollmentId/validate

```typescript
@Post('enrollments/:enrollmentId/validate')
@UseGuards(JwtAuthGuard, GlobalRolesGuard)
@GlobalRoles('admin', 'coordinator')
@ApiOperation({ summary: 'Aprobar o rechazar enrollment' })
@ApiParam({ name: 'enrollmentId', type: Number })
@ApiResponse({ status: 200, description: 'Validación registrada' })
@ApiResponse({ status: 400, description: 'Estado inválido o rechazo sin comentarios' })
@ApiResponse({ status: 403, description: 'Sin rol de admin o coordinador' })
@ApiResponse({ status: 404, description: 'Enrollment no encontrado' })
@ApiResponse({ status: 409, description: 'Enrollment no está en SUBMITTED_FOR_VALIDATION' })
async validateEnrollment(
  @Param('enrollmentId', ParseIntPipe) enrollmentId: number,
  @Body() dto: ValidateEnrollmentDto,
  @Request() req,
)
```

### Endpoint 3: POST /enrollments/:enrollmentId/investiture

```typescript
@Post('enrollments/:enrollmentId/investiture')
@UseGuards(JwtAuthGuard, GlobalRolesGuard)
@GlobalRoles('admin', 'coordinator')
@ApiOperation({ summary: 'Registrar investidura formal' })
@ApiParam({ name: 'enrollmentId', type: Number })
@ApiResponse({ status: 200, description: 'Investidura registrada' })
@ApiResponse({ status: 400, description: 'Enrollment no está en APPROVED' })
@ApiResponse({ status: 404, description: 'Enrollment o config no encontrado' })
@ApiResponse({ status: 409, description: 'Ya está en INVESTIDO' })
async markInvestido(
  @Param('enrollmentId', ParseIntPipe) enrollmentId: number,
  @Body() dto: MarkInvestidoDto,
  @Request() req,
)
```

### Endpoint 4: GET /investiture/pending

```typescript
@Get('investiture/pending')
@UseGuards(JwtAuthGuard, GlobalRolesGuard)
@GlobalRoles('admin', 'coordinator')
@ApiOperation({ summary: 'Listar enrollments pendientes de validación' })
@ApiQuery({ name: 'local_field_id', required: false, type: Number })
@ApiQuery({ name: 'ecclesiastical_year_id', required: false, type: Number })
@ApiQuery({ name: 'page', required: false, type: Number })
@ApiQuery({ name: 'limit', required: false, type: Number })
@ApiResponse({ status: 200, description: 'Lista paginada de enrollments en SUBMITTED_FOR_VALIDATION' })
@ApiResponse({ status: 403, description: 'Sin rol de admin o coordinador' })
async getPending(
  @Query('local_field_id', new ParseIntPipe({ optional: true })) localFieldId?: number,
  @Query('ecclesiastical_year_id', new ParseIntPipe({ optional: true })) ecclesiasticalYearId?: number,
  @Query('page', new ParseIntPipe({ optional: true })) page?: number,
  @Query('limit', new ParseIntPipe({ optional: true })) limit?: number,
)
```

### Endpoint 5: GET /enrollments/:enrollmentId/investiture-history

```typescript
@Get('enrollments/:enrollmentId/investiture-history')
@UseGuards(JwtAuthGuard)
@ApiOperation({ summary: 'Historial de validación de un enrollment' })
@ApiParam({ name: 'enrollmentId', type: Number })
@ApiResponse({ status: 200, description: 'Historial de validación' })
@ApiResponse({ status: 403, description: 'Sin acceso al historial' })
@ApiResponse({ status: 404, description: 'Enrollment no encontrado' })
async getHistory(
  @Param('enrollmentId', ParseIntPipe) enrollmentId: number,
  @Request() req,
)
```

Para este endpoint, el controller extrae los roles globales del JWT (`req.user.roles` o equivalente — verificar la estructura del payload en otros controllers) y los pasa al service. La autorización dual (club OR global) se hace programáticamente en el service.

### Criterios de aceptación

- [ ] Los 5 endpoints están declarados con los decoradores correctos de Swagger (`@ApiTags`, `@ApiOperation`, `@ApiParam`, `@ApiResponse`)
- [ ] Todos los endpoints tienen `@UseGuards(JwtAuthGuard, ...)` como primer guard
- [ ] Los endpoints con `GlobalRolesGuard` retornan 403 para requests sin los roles requeridos
- [ ] Los endpoints con `ClubRolesGuard` retornan 403 para requests sin roles de club
- [ ] El endpoint `investiture-history` no tiene guard de autorización de roles en el decorator — la lógica es programática en el service
- [ ] `actorId` se extrae correctamente del JWT en todos los endpoints
- [ ] `pnpm run build` pasa sin errores
- [ ] Los endpoints son visibles en Swagger (`/api`) con sus parámetros y respuestas documentados

---

## Task 7: Registro del módulo en AppModule

### Archivos a modificar

```
src/app.module.ts    ← agregar import de InvestitureModule
```

### Cambios requeridos

1. Agregar import al inicio del archivo:
   ```typescript
   import { InvestitureModule } from './investiture/investiture.module';
   ```

2. Agregar `InvestitureModule` al array de `imports` del `@Module`, junto al resto de módulos de aplicación (en el bloque `// MÓDULOS DE APLICACIÓN`), después de `InsuranceModule`.

### Criterios de aceptación

- [ ] `src/app.module.ts` importa `InvestitureModule`
- [ ] `InvestitureModule` está presente en el array `imports` del módulo raíz
- [ ] `pnpm run build` pasa sin errores
- [ ] El servidor arranca sin errores (`pnpm run start:dev`)
- [ ] Los 5 endpoints son accesibles en `http://localhost:3000/api` (Swagger UI)

---

## Task 8: Unit tests del service

### Archivos a crear

```
src/investiture/investiture.service.spec.ts
```

### Referencia de patrón de mocks

Usar como referencia: `src/admin/admin-users.service.spec.ts` y `src/insurance/insurance.service.spec.ts`.

### Suite de tests

**`submitForValidation`** (6 casos):
1. Caso feliz: `IN_PROGRESS` → `SUBMITTED_FOR_VALIDATION` — verifica status, `locked_for_validation = true`, `submitted_at` poblado, history creado con `action = 'SUBMITTED'`
2. Caso feliz: `REJECTED` → `SUBMITTED_FOR_VALIDATION` (re-envío)
3. Error: enrollment no encontrado → `NotFoundException`
4. Error: estado `APPROVED` → `BadRequestException` con mensaje que incluye el estado actual
5. Error: estado `INVESTIDO` → `BadRequestException`
6. Advertencia suave: fecha actual > `submission_deadline` → respuesta incluye `is_late: true` (no lanza error)

**`validateEnrollment`** (5 casos):
1. Caso feliz: `SUBMITTED_FOR_VALIDATION` + `APPROVED` → status `APPROVED`, `locked_for_validation = true`, `rejection_reason = null`, history con `action = 'APPROVED'`
2. Caso feliz: `SUBMITTED_FOR_VALIDATION` + `REJECTED` + comments → status `REJECTED`, `locked_for_validation = false`, `submitted_for_validation = false`, `rejection_reason` poblado
3. Error: `REJECTED` sin comments → `BadRequestException`
4. Error: enrollment en estado `IN_PROGRESS` → `ConflictException`
5. Error: enrollment en estado `APPROVED` → `ConflictException`

**`markInvestido`** (4 casos):
1. Caso feliz: `APPROVED` → `INVESTIDO`, `investiture_date` igual a `investiture_config.investiture_date`
2. Error: ya está en `INVESTIDO` → `ConflictException`
3. Error: estado `SUBMITTED_FOR_VALIDATION` → `BadRequestException`
4. Error: `investiture_config` no encontrado → `NotFoundException`

**`getPending`** (3 casos):
1. Retorna solo enrollments `SUBMITTED_FOR_VALIDATION` y `active = true`
2. Filtra por `local_field_id` cuando se provee (verifica que el where tiene `users: { local_field_id }`)
3. Aplica paginación correctamente (verifica `skip` y `take` en la query)

**`getHistory`** (3 casos):
1. Actor con rol `admin` → puede ver historial sin verificación de club
2. Actor con rol de club perteneciente al club del enrollment → acceso permitido
3. Actor sin rol global y sin pertenencia al club → `ForbiddenException`

### Criterios de aceptación

- [ ] Todos los tests pasan (`pnpm run test investiture`)
- [ ] Los mocks de Prisma están correctamente tipados — no se usa `any` para los mocks
- [ ] Cada test verifica tanto el efecto en el enrollment como el registro en `investiture_validation_history`
- [ ] Los tests de error verifican el mensaje de la excepción, no solo el tipo

---

## Notas de implementación transversales

### Extracción del actorId desde JWT

Verificar cómo otros controllers del proyecto extraen el ID del usuario autenticado. Buscar en `src/users/users.controller.ts` o `src/clubs/clubs.controller.ts` el patrón `@Request() req` y cómo se accede a `req.user`. El campo exacto puede ser `req.user.sub` o `req.user.id` — no asumir, verificar.

### Nota histórica: Modelo users_classes en Prisma

La tabla `users_classes` fue archivada como `users_classes_archive`. Ya no es necesario verificar el schema ni implementar upserts relacionados con esa tabla.

### investiture_action_enum sin valor INVESTIDO

El enum `investiture_action_enum` en la base de datos tiene: `SUBMITTED`, `APPROVED`, `REJECTED`, `REINVESTITURE_REQUESTED`. No tiene `INVESTIDO`. En el acto de investidura (`markInvestido`), usar `action: 'APPROVED'` con `comments: 'Investidura formal registrada'` como workaround hasta que se agregue el valor al enum mediante migración.

### Endpoint submit-for-validation y ClubRolesGuard

`ClubRolesGuard` extrae `clubId` de `params.clubId` o `body.club_id`. Como el endpoint de submit-for-validation no tiene `clubId` en la URL, el DTO incluye `club_id: number` como campo requerido. El cliente debe enviarlo. Esta es la solución preferida del diseño técnico (opción 1).

### Verificar PaginationDto y createPaginatedResult

Estos helpers existen en `src/common/`. Antes de Task 5, leer cómo se usan en un service existente (ej: `src/honors/honors.service.ts` o `src/activities/activities.service.ts`) para aplicar el mismo patrón.
