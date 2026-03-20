# Diseño Técnico: Módulo de Investiduras

**Estado**: DISEÑO APROBADO — listo para implementación
**Fecha**: 2026-03-20
**Autor**: Diseño técnico basado en decisiones aprobadas

---

## Contexto

La validación de investiduras es el cierre institucional del ciclo formativo. Las tablas, enums y campos en `enrollments` ya existen en el schema de Prisma — no se requieren migraciones para el MVP. El único gap es runtime: no existe ningún módulo, servicio, controlador ni endpoint que exponga esta funcionalidad.

---

## Máquina de estados

```
IN_PROGRESS
    │
    ▼  (director o consejero envía)
SUBMITTED_FOR_VALIDATION  ─────────────────────────────────┐
    │                                                        │
    ▼  (admin/coordinador aprueba)                          │  (admin/coordinador rechaza)
APPROVED                                                    REJECTED
    │                                                            │
    ▼  (admin/coordinador marca como investido)                 ▼  (club edita y reenvía)
INVESTIDO                                          SUBMITTED_FOR_VALIDATION (re-ingresa al flujo)
```

**Regla clave**: REJECTED no es un estado terminal. El club puede editar y re-enviar, lo que transiciona de nuevo a SUBMITTED_FOR_VALIDATION.

**Estados terminales del MVP**: INVESTIDO únicamente. APPROVED es intermedio — queda aprobado pero aún no investido formalmente.

**Fuera de MVP**: REINVESTITURE_REQUESTED no se implementa. El enum existe en base de datos pero no se expone en ningún endpoint.

---

## Estructura de archivos

```
src/investiture/
├── investiture.module.ts
├── investiture.controller.ts
├── investiture.service.ts
└── dto/
    ├── submit-for-validation.dto.ts
    ├── validate-enrollment.dto.ts
    └── mark-investido.dto.ts
```

El módulo se registra en `src/app.module.ts` junto al resto de módulos del sistema.

---

## DTOs

### `SubmitForValidationDto`

Usado en `POST /enrollments/:enrollmentId/submit-for-validation`.

```
SubmitForValidationDto
  comments?: string
    - @IsOptional()
    - @IsString()
    - @MaxLength(500)
    - @ApiPropertyOptional({ description: 'Comentario opcional del consejero/director', maxLength: 500 })
```

**Campos requeridos en URL**: `enrollmentId` (number, `@ParseIntPipe`).

No se requieren más campos en el body — la transición de estado es determinista (IN_PROGRESS o REJECTED → SUBMITTED_FOR_VALIDATION).

---

### `ValidateEnrollmentDto`

Usado en `POST /enrollments/:enrollmentId/validate`.

```
ValidateEnrollmentDto
  action: 'APPROVED' | 'REJECTED'
    - @IsEnum(['APPROVED', 'REJECTED'])
    - @IsNotEmpty()
    - @ApiProperty({ enum: ['APPROVED', 'REJECTED'], description: 'Decisión de validación' })

  comments?: string
    - @IsOptional()
    - @IsString()
    - @MaxLength(1000)
    - @ApiPropertyOptional({ description: 'Comentarios del validador. Requerido si action=REJECTED', maxLength: 1000 })
```

**Validación cruzada de negocio** (en el service, no en el DTO): si `action === 'REJECTED'`, `comments` no puede ser null ni vacío. El DTO lo hace opcional para no romper el pipe de validación antes de que el service aplique la regla.

---

### `MarkInvestidoDto`

Usado en `POST /enrollments/:enrollmentId/investiture`.

```
MarkInvestidoDto
  comments?: string
    - @IsOptional()
    - @IsString()
    - @MaxLength(500)
    - @ApiPropertyOptional({ description: 'Comentario opcional del acto de investidura', maxLength: 500 })
```

No se acepta `investiture_date` en el body — la fecha se toma siempre de `investiture_config.investiture_date` resuelto por `local_field_id` + `ecclesiastical_year_id`. Ver sección "Resolución de local_field_id".

---

## Controller

### Prefijo y versión

```
@ApiTags('investiture')
@ApiBearerAuth()
@Controller('api/v1')
```

No se usa un prefijo único de módulo tipo `/investiture/` porque los endpoints de acción viven bajo `/enrollments/:enrollmentId/` para mantener coherencia con el recurso principal.

### Declaración de guards por endpoint

Todos los endpoints requieren `JwtAuthGuard` como primer guard. Los guards de autorización van después.

---

#### 1. POST /enrollments/:enrollmentId/submit-for-validation

```
@Post('enrollments/:enrollmentId/submit-for-validation')
@UseGuards(JwtAuthGuard, ClubRolesGuard)
@ClubRoles('director', 'counselor')
@ApiOperation({ summary: 'Enviar enrollment a validación' })
@ApiParam({ name: 'enrollmentId', type: Number })
@ApiResponse({ status: 200 })     — transición exitosa
@ApiResponse({ status: 400 })     — estado actual no permite la transición
@ApiResponse({ status: 403 })     — sin rol de director o consejero en el club
@ApiResponse({ status: 404 })     — enrollment no encontrado
@ApiResponse({ status: 409 })     — ya está en SUBMITTED_FOR_VALIDATION
```

**Nota sobre ClubRolesGuard**: el guard extrae `clubId` del request. En este endpoint, el `clubId` NO está en `params`. El service debe resolverlo internamente a partir del enrollment, y el guard necesita que la request lo exponga. Alternativa arquitectónica: el guard busca `clubId` en body — para este endpoint se puede incluir `club_id` como campo oculto/derivado en el body, o bien extender el guard para buscar también en un campo calculado. **Decisión preferida**: el endpoint acepta `club_id` en el body (opcional, para satisfacer al guard) o se crea un guard especializado que resuelve el club a partir del enrollmentId. Ver sección "Validaciones de negocio" para la discusión completa.

---

#### 2. POST /enrollments/:enrollmentId/validate

```
@Post('enrollments/:enrollmentId/validate')
@UseGuards(JwtAuthGuard, GlobalRolesGuard)
@GlobalRoles('admin', 'coordinator')
@ApiOperation({ summary: 'Aprobar o rechazar enrollment' })
@ApiParam({ name: 'enrollmentId', type: Number })
@ApiResponse({ status: 200 })     — validación registrada
@ApiResponse({ status: 400 })     — estado inválido para validar / rechazo sin comentarios
@ApiResponse({ status: 403 })     — sin rol de admin o coordinador
@ApiResponse({ status: 404 })     — enrollment no encontrado
@ApiResponse({ status: 409 })     — enrollment no está en SUBMITTED_FOR_VALIDATION
```

---

#### 3. POST /enrollments/:enrollmentId/investiture

```
@Post('enrollments/:enrollmentId/investiture')
@UseGuards(JwtAuthGuard, GlobalRolesGuard)
@GlobalRoles('admin', 'coordinator')
@ApiOperation({ summary: 'Marcar como INVESTIDO' })
@ApiParam({ name: 'enrollmentId', type: Number })
@ApiResponse({ status: 200 })     — investidura registrada
@ApiResponse({ status: 400 })     — enrollment no está en APPROVED
@ApiResponse({ status: 404 })     — enrollment no encontrado / investiture_config no encontrado
@ApiResponse({ status: 409 })     — ya está en INVESTIDO
```

---

#### 4. GET /investiture/pending

```
@Get('investiture/pending')
@UseGuards(JwtAuthGuard, GlobalRolesGuard)
@GlobalRoles('admin', 'coordinator')
@ApiOperation({ summary: 'Listar enrollments pendientes de validación' })
@ApiQuery({ name: 'local_field_id', required: false, type: Number })
@ApiQuery({ name: 'ecclesiastical_year_id', required: false, type: Number })
@ApiQuery({ name: 'page', required: false })
@ApiQuery({ name: 'limit', required: false })
@ApiResponse({ status: 200 })     — lista paginada de enrollments en SUBMITTED_FOR_VALIDATION
@ApiResponse({ status: 403 })     — sin rol de admin o coordinador
```

El filtro por `local_field_id` es opcional pero recomendado para coordinadores que tienen scope de un campo local específico. Si no se envía, devuelve todos los pendientes (solo para admin/super_admin).

---

#### 5. GET /enrollments/:enrollmentId/investiture-history

```
@Get('enrollments/:enrollmentId/investiture-history')
@UseGuards(JwtAuthGuard, ClubRolesGuard)   — OR GlobalRolesGuard
@ClubRoles('director', 'counselor', 'secretary')
@ApiOperation({ summary: 'Historial de validación de un enrollment' })
@ApiParam({ name: 'enrollmentId', type: Number })
@ApiResponse({ status: 200 })     — lista de eventos del historial
@ApiResponse({ status: 404 })     — enrollment no encontrado
```

**Nota de doble guard**: el historial debe ser accesible tanto por el club (consejero/director) como por el admin/coordinador. La estrategia recomendada es una verificación programática en el service: si el usuario tiene un rol global (admin/coordinator) se permite siempre; si no, se verifica que tenga rol de club en el club correspondiente al enrollment. Esto evita tener que combinar guards en el decorador, lo cual NestJS no soporta nativamente con OR semántico.

---

## Service

### Dependencias

```
InvestitureService
  constructor(private readonly prisma: PrismaService)
```

No requiere otros servicios inyectados en el MVP.

---

### Método: submitForValidation

**Firma**: `submitForValidation(enrollmentId: number, actorId: string, dto: SubmitForValidationDto)`

**Lógica paso a paso**:

1. Buscar enrollment por `enrollmentId` con `select` mínimo: `{ enrollment_id, user_id, class_id, ecclesiastical_year_id, investiture_status, locked_for_validation, active }`.
2. Si no existe o `active === false` → lanzar `NotFoundException('Enrollment no encontrado')`.
3. Verificar que `investiture_status` es `IN_PROGRESS` o `REJECTED`. Si es cualquier otro estado → lanzar `BadRequestException` con código `INVALID_STATUS_TRANSITION` e indicar el estado actual.
4. Resolver `investiture_config` para el campo local del enrollment (ver sección "Resolución de local_field_id"). Si no existe config → lanzar `NotFoundException('No existe configuración de investidura para este campo local y año eclesiastico')`.
5. Verificar deadline (advertencia suave): comparar `Date.now()` con `investiture_config.submission_deadline`. Si la fecha actual supera el deadline, NO bloquear la operación — continuar y marcar `is_late = true` en la respuesta.
6. Abrir transacción Prisma:
   a. Actualizar enrollment: `investiture_status = SUBMITTED_FOR_VALIDATION`, `submitted_for_validation = true`, `submitted_at = now()`, `locked_for_validation = true`.
   b. Crear registro en `investiture_validation_history`: `action = SUBMITTED`, `performed_by = actorId`, `comments = dto.comments ?? null`.
7. Retornar: `{ enrollment_id, investiture_status, submitted_at, is_late, history_entry }`.

---

### Método: validateEnrollment

**Firma**: `validateEnrollment(enrollmentId: number, actorId: string, dto: ValidateEnrollmentDto)`

**Lógica paso a paso**:

1. Buscar enrollment. Si no existe → `NotFoundException`.
2. Verificar que `investiture_status === SUBMITTED_FOR_VALIDATION`. Si no → `ConflictException('El enrollment no está en estado SUBMITTED_FOR_VALIDATION')`.
3. Si `dto.action === 'REJECTED'` y `(!dto.comments || dto.comments.trim() === '')` → `BadRequestException('El campo comments es requerido para rechazar')`.
4. Abrir transacción Prisma:

   **Si `dto.action === 'APPROVED'`**:
   a. Actualizar enrollment: `investiture_status = APPROVED`, `validated_by = actorId`, `validated_at = now()`, `rejection_reason = null`, `locked_for_validation = true`.
   b. Crear history entry: `action = APPROVED`, `performed_by = actorId`, `comments = dto.comments ?? null`.

   **Si `dto.action === 'REJECTED'`**:
   a. Actualizar enrollment: `investiture_status = REJECTED`, `validated_by = actorId`, `validated_at = now()`, `rejection_reason = dto.comments`, `locked_for_validation = false`, `submitted_for_validation = false`.
   b. Crear history entry: `action = REJECTED`, `performed_by = actorId`, `comments = dto.comments`.

5. Retornar: `{ enrollment_id, investiture_status, validated_by, validated_at, rejection_reason }`.

**Efecto de REJECTED**: el unlock (`locked_for_validation = false`) permite que el club edite el progreso del miembro antes de re-enviar. Este es el único camino para que un enrollment bloqueado vuelva a ser editable.

---

### Método: markInvestido

**Firma**: `markInvestido(enrollmentId: number, actorId: string, dto: MarkInvestidoDto)`

**Lógica paso a paso**:

1. Buscar enrollment con `select`: `{ enrollment_id, user_id, class_id, ecclesiastical_year_id, investiture_status }`.
2. Si no existe → `NotFoundException`.
3. Verificar `investiture_status === APPROVED`. Si ya es `INVESTIDO` → `ConflictException('El enrollment ya fue investido')`. Si es cualquier otro estado → `BadRequestException('El enrollment debe estar en estado APPROVED para ser investido')`.
4. Resolver `investiture_config` por local_field_id + ecclesiastical_year_id del enrollment. Si no existe → `NotFoundException`.
5. Abrir transacción Prisma:
   a. Actualizar enrollment: `investiture_status = INVESTIDO`, `investiture_date = investiture_config.investiture_date`.
   b. Crear history entry: `action = APPROVED` (reutilizamos el enum — no existe un valor `INVESTIDO` en `investiture_action_enum`; usar `APPROVED` con un comentario contextual que indique el acto de investidura, hasta que se agregue el valor al enum).
   c. **(Archivado)** El sincronismo con `users_classes` ya no aplica — la tabla fue archivada como `users_classes_archive`.
6. Retornar: `{ enrollment_id, investiture_status, investiture_date }`.

**Nota sobre investiture_action_enum**: el enum solo tiene `SUBMITTED`, `APPROVED`, `REJECTED`, `REINVESTITURE_REQUESTED`. No existe `INVESTIDO`. Para el acto de investidura formal se recomienda agregar `INVESTIDO` al enum en una migración futura. En el MVP, usar `APPROVED` con comments descriptivo o bien crear la migración como parte del MVP.

---

### Método: getPending

**Firma**: `getPending(localFieldId?: number, ecclesiasticalYearId?: number, pagination?: PaginationDto)`

**Lógica paso a paso**:

1. Construir cláusula `where`:
   - `investiture_status: 'SUBMITTED_FOR_VALIDATION'`
   - `active: true`
   - Si `localFieldId` se provee: filtrar por enrollments cuyo usuario pertenece al campo local (ver join en subsección "Filtro por campo local").
   - Si `ecclesiasticalYearId` se provee: `ecclesiastical_year_id = ecclesiasticalYearId`.

2. Ejecutar `findMany` con `include`:
   - `users`: `{ first_name, last_name, email }`
   - `classes`: `{ name }`
   - `ecclesiastical_year`: `{ start_date, end_date }`

3. Aplicar paginación estándar con `PaginationDto` y `createPaginatedResult`.

4. Retornar lista paginada con campos: `{ enrollment_id, user: { nombre, email }, class_name, submitted_at, ecclesiastical_year }`.

**Filtro por campo local** (join): Para filtrar por `local_field_id`, el enrollment no tiene ese campo directamente. El join es: enrollment → enrollment.user_id → users → users.local_field_id. El modelo `users` tiene `local_field_id` directamente (verificado en schema). Por lo tanto el filtro es `where: { users: { local_field_id: localFieldId } }`.

---

### Método: getHistory

**Firma**: `getHistory(enrollmentId: number, actorId: string, actorGlobalRoles: string[])`

**Lógica paso a paso**:

1. Buscar enrollment para verificar que existe. Si no → `NotFoundException`.
2. Verificar autorización programática:
   - Si el actor tiene rol `admin` o `coordinator` (en `actorGlobalRoles`) → acceso permitido.
   - Si no, verificar que el actor tiene una `club_role_assignments` activa cuyo `club_section_id` corresponde a un club al que pertenece el usuario del enrollment. Si no → `ForbiddenException`.
3. Buscar todos los registros de `investiture_validation_history` donde `enrollment_id = enrollmentId`, ordenados por `created_at DESC`.
4. Para cada registro, incluir `users: { first_name, last_name }` (el actor que realizó la acción).
5. Retornar: `{ enrollment_id, history: [{ history_id, action, performed_by: { nombre }, comments, created_at }] }`.

---

## Resolución de local_field_id desde enrollment

Este es el join más crítico del módulo y se usa en `submitForValidation` y `markInvestido`.

**El problema**: dado un `enrollmentId`, necesitamos el `local_field_id` para buscar el `investiture_config` correspondiente.

**La cadena de resolución**:

```
enrollment.user_id
    │
    ▼  JOIN users
users.local_field_id   ←── directo, el modelo users tiene local_field_id
    │
    ▼  JOIN investiture_config
investiture_config WHERE local_field_id = users.local_field_id
                    AND ecclesiastical_year_id = enrollment.ecclesiastical_year_id
                    AND active = true
```

**La cadena alternativa** (a través de club_role_assignments) es innecesariamente compleja dado que `users.local_field_id` ya está disponible. Usar el camino directo.

**Pseudocódigo del helper privado** `resolveInvestitureConfig(enrollmentId)`:

```
1. Buscar enrollment con include:
   {
     select: { user_id, ecclesiastical_year_id },
     include: { users: { select: { local_field_id } } }
   }
   Si no existe → NotFoundException

2. const localFieldId = enrollment.users.local_field_id
   const yearId = enrollment.ecclesiastical_year_id

3. Buscar investiture_config donde:
   { local_field_id: localFieldId, ecclesiastical_year_id: yearId, active: true }
   Si no existe → NotFoundException('No existe configuración de investidura para este campo local y año eclesiastico')

4. Retornar { config, localFieldId }
```

Este método se extrae como `private resolveInvestitureConfig(enrollmentId: number)` y se llama desde `submitForValidation` y `markInvestido`.

---

## Validaciones de negocio

### Transiciones de estado válidas

| Estado actual | Acción permitida | Nuevo estado |
|---|---|---|
| IN_PROGRESS | submit-for-validation | SUBMITTED_FOR_VALIDATION |
| REJECTED | submit-for-validation | SUBMITTED_FOR_VALIDATION |
| SUBMITTED_FOR_VALIDATION | validate (APPROVED) | APPROVED |
| SUBMITTED_FOR_VALIDATION | validate (REJECTED) | REJECTED |
| APPROVED | investiture | INVESTIDO |
| INVESTIDO | ninguna | — (estado final) |

Cualquier transición fuera de esta tabla lanza `BadRequestException` con código `INVALID_STATUS_TRANSITION`.

### Regla de bloqueo de progreso

Cuando `locked_for_validation = true`, los endpoints de actualización de progreso de clases deben rechazar modificaciones con `ForbiddenException`. Esta validación **no** es responsabilidad del módulo de investiduras — debe implementarse en el service de clases como guardia previa a cualquier `updateSectionProgress`. Se incluye aquí como recordatorio de dependencia cross-módulo.

### Deadline como advertencia suave

`submission_deadline` en `investiture_config` es informativo. El endpoint `submit-for-validation` NO lanza error si se supera. La respuesta incluye el campo `is_late: boolean` para que el cliente pueda mostrar una advertencia. Un enrollment tardío es válido y sigue el flujo normal.

### Rechazo requiere justificación

`ValidateEnrollmentDto.comments` es técnicamente opcional en el DTO (para pasar la validación de pipe sin error de campo), pero el service aplica la regla: si `action === REJECTED` y comments es null/vacío → `BadRequestException`.

### Solo un config por campo local y año

La tabla `investiture_config` tiene constraint `UNIQUE(local_field_id, ecclesiastical_year_id)`. El service puede asumir que `findFirst` devuelve el único registro válido sin necesidad de manejar múltiples resultados.

### Club ID en ClubRolesGuard

`ClubRolesGuard` extrae `clubId` de `params.clubId` o `body.club_id`. Los endpoints de investidura no tienen `clubId` en la URL. Soluciones posibles (en orden de preferencia):

1. **Solución recomendada**: El endpoint `submit-for-validation` requiere que el cliente envíe `club_id` en el body (ya que sabe desde qué club está operando). El DTO puede incluir `@IsInt() @IsPositive() club_id: number` para satisfacer al guard.
2. **Alternativa**: Crear un guard especializado `InvestitureClubGuard` que resuelve el club desde el enrollment (usando el mismo join descrito en "Resolución de local_field_id") y verifica el rol del actor. Más complejo pero más ergonómico para el cliente.

---

## Transacciones Prisma

### Transacción 1: submitForValidation

```
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

Usar forma de array (no callback interactivo) ya que no hay dependencias entre las dos operaciones.

### Transacción 2: validateEnrollment

Usar forma de callback interactivo (`prisma.$transaction(async (tx) => {...})`) ya que la historia depende del resultado para incluir el estado anterior:

```
prisma.$transaction(async (tx) => {
  const updated = await tx.enrollments.update({ ... })
  await tx.investiture_validation_history.create({ ... })
  return updated
})
```

### Transacción 3: markInvestido

Usar callback interactivo — tres operaciones en secuencia:

```
prisma.$transaction(async (tx) => {
  const config = await resolveInvestitureConfig(tx, enrollmentId)  // lectura dentro de tx
  const updated = await tx.enrollments.update({ ... investiture_date: config.investiture_date })
  await tx.investiture_validation_history.create({ ... })
  // users_classes sync ya no aplica — tabla archivada como users_classes_archive
  return updated
})
```

**Nota histórica**: El sincronismo con `users_classes` fue removido. La tabla se archivó como `users_classes_archive`. El histórico de investiduras se consulta desde `enrollments` directamente.

---

## Manejo de errores

| Situación | Excepción NestJS | Código HTTP |
|---|---|---|
| Enrollment no encontrado | `NotFoundException` | 404 |
| investiture_config no encontrada | `NotFoundException` | 404 |
| Transición de estado inválida | `BadRequestException` | 400 |
| Rechazo sin comentarios | `BadRequestException` | 400 |
| Ya está en estado objetivo | `ConflictException` | 409 |
| Sin rol de club requerido | `ForbiddenException` (del guard) | 403 |
| Sin rol global requerido | `ForbiddenException` (del guard) | 403 |
| Sin permiso para ver historial | `ForbiddenException` | 403 |

Todos los errores deben incluir un mensaje descriptivo en español, consistente con el patrón del resto del sistema.

---

## Módulo

```
InvestitureModule
  imports: [PrismaModule]
  controllers: [InvestitureController]
  providers: [InvestitureService]
  exports: [InvestitureService]   — por si otros módulos necesitan verificar estado
```

El módulo se importa en `AppModule` al igual que `CertificationsModule`, `ClassesModule`, etc.

---

## Sync con users_classes [ARCHIVADO]

**Estado**: ❌ **REMOVIDO** — La tabla `users_classes` fue archivada como `users_classes_archive`.

**Cómo se verifica elegibilidad de Guías Mayores ahora**: `certifications.service.ts` debe validar contra `enrollments` directamente, filtrando por `investiture_status = 'INVESTIDO'`. No consultar `users_classes`.

**Histórico de investiduras**: Se obtiene directamente desde `enrollments` con filtros históricos por año eclesiástico y estado de investidura.

---

## Testing strategy

### Unit tests (InvestitureService)

Para cada método del service, escribir tests usando el patrón de mocks de Prisma ya establecido en el proyecto (ver `src/admin/admin-users.service.spec.ts` como referencia).

**Tests críticos**:

1. `submitForValidation`
   - Caso feliz: IN_PROGRESS → SUBMITTED_FOR_VALIDATION
   - Caso feliz: REJECTED → SUBMITTED_FOR_VALIDATION (re-envío)
   - Error: enrollment no encontrado → NotFoundException
   - Error: estado inválido (APPROVED, INVESTIDO) → BadRequestException
   - Error: investiture_config no existe → NotFoundException
   - Advertencia tardía: retorna `is_late: true` cuando se supera deadline

2. `validateEnrollment`
   - Caso feliz: SUBMITTED_FOR_VALIDATION → APPROVED
   - Caso feliz: SUBMITTED_FOR_VALIDATION → REJECTED con comments
   - Error: rechazo sin comments → BadRequestException
   - Error: estado distinto de SUBMITTED_FOR_VALIDATION → ConflictException
   - Verificar que REJECTED desbloquea el enrollment (`locked_for_validation = false`)

3. `markInvestido`
   - Caso feliz: APPROVED → INVESTIDO con fecha de investiture_config
   - Error: estado distinto de APPROVED → BadRequestException
   - Error: ya es INVESTIDO → ConflictException
   - Error: investiture_config no encontrado → NotFoundException
   - Verificar que `investiture_date` en enrollment coincide con `investiture_config.investiture_date`

4. `getPending`
   - Retorna solo enrollments en SUBMITTED_FOR_VALIDATION
   - Filtra por local_field_id cuando se provee
   - Aplica paginación correctamente

5. `getHistory`
   - Admin puede ver historial de cualquier enrollment
   - Coordinador puede ver historial de su campo local
   - Club role sin pertenencia al club del enrollment → ForbiddenException

### Integration / E2E tests (opcional para MVP)

Cubrir el flujo completo: submit → approve → investiture en un solo test de integración usando una base de datos de test. Referencia: `src/insurance/insurance.service.spec.ts`.

---

## Registro de decisiones de diseño

| Decisión | Razonamiento |
|---|---|
| REJECTED persiste y permite re-submit | El bloqueo perpetuo crea casos sin salida; el club debe poder corregir y reenviar |
| submission_deadline es advertencia suave | Realidad operacional: los plazos se cumplen parcialmente; bloquear crearía un cuello de botella administrativo |
| investiture_date siempre viene de investiture_config | Una sola fuente de verdad por campo local/año; evita inconsistencias si cada enrollment tuviera su propia fecha |
| users_classes archivada | La tabla fue archivada como users_classes_archive. El histórico se consulta directamente desde enrollments. |
| REINVESTITURE_REQUESTED fuera de MVP | Caso de uso excepcional; el flujo base debe estabilizarse primero |
| No hay endpoint de configuración en MVP | investiture_config se gestiona directamente en DB por ahora; se puede agregar como módulo separado en iteración siguiente |
