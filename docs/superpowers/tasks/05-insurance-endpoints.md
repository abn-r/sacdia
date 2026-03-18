# Bloque 5: Insurance (Seguros) Endpoints

> 4 endpoints que la app móvil consume pero el backend no implementa.
> Complejidad: ALTA — requiere nuevo módulo, posible migración para evidence files.
> La tabla `member_insurances` ya existe. La app tiene implementación completa.

---

## Contexto

| Endpoint | App móvil | Backend |
|----------|-----------|---------|
| `GET /clubs/:clubId/sections/:sectionId/members/insurance` | ✅ | ❌ |
| `GET /users/:memberId/insurance` | ✅ | ❌ |
| `POST /users/:memberId/insurance` (multipart) | ✅ | ❌ |
| `PATCH /insurance/:insuranceId` (multipart) | ✅ | ❌ |

**DB existente**: Tabla `member_insurances` con: `insurance_id`, `user_id`, `insurance_type` (enum: GENERAL_ACTIVITIES, CAMPOREE, HIGH_RISK), `policy_number`, `provider`, `start_date`, `end_date`, `coverage_amount`, `active`, timestamps.

**Discrepancia**: La app espera `evidence_file_url` y `evidence_file_name` pero la DB NO tiene estos campos.

**Backend existente**: `camporees.service.ts` ya valida insurance en registro de miembros a camporees.

---

## Tarea 5.1: Migración DB — agregar campos de evidencia

**Archivo**: `sacdia-backend/prisma/schema.prisma`

**Qué hacer**:
1. Agregar al modelo `member_insurances`:
```prisma
evidence_file_url   String?   @db.VarChar(500)
evidence_file_name  String?   @db.VarChar(255)
created_by_id       String?   @db.Uuid
modified_by_id      String?   @db.Uuid
```

2. Crear migración:
```bash
npx prisma migrate dev --name add_insurance_evidence_fields
npx prisma generate
```

**Status**: 🔲

---

## Tarea 5.2: Crear InsuranceModule, Controller, Service y DTOs

**Archivos nuevos**:
- `sacdia-backend/src/insurance/insurance.module.ts`
- `sacdia-backend/src/insurance/insurance.controller.ts`
- `sacdia-backend/src/insurance/insurance.service.ts`
- `sacdia-backend/src/insurance/dto/create-insurance.dto.ts`
- `sacdia-backend/src/insurance/dto/update-insurance.dto.ts`

**Controller** — 4 endpoints:

```typescript
@Controller('api/v1')
@UseGuards(JwtAuthGuard)
@ApiTags('Insurance')
export class InsuranceController {
  constructor(private readonly service: InsuranceService) {}

  // GET /clubs/:clubId/sections/:sectionId/members/insurance
  @Get('clubs/:clubId/sections/:sectionId/members/insurance')
  async listMembersInsurance(
    @Param('clubId', ParseIntPipe) clubId: number,
    @Param('sectionId', ParseIntPipe) sectionId: number,
  ) { ... }

  // GET /users/:memberId/insurance
  @Get('users/:memberId/insurance')
  async getMemberInsurance(@Param('memberId') memberId: string) { ... }

  // POST /users/:memberId/insurance (multipart)
  @Post('users/:memberId/insurance')
  @UseInterceptors(FileInterceptor('evidence'))
  async createInsurance(
    @Param('memberId') memberId: string,
    @Body() dto: CreateInsuranceDto,
    @UploadedFile() file?: Express.Multer.File,
    @CurrentUser() user,
  ) { ... }

  // PATCH /insurance/:insuranceId (multipart)
  @Patch('insurance/:insuranceId')
  @UseInterceptors(FileInterceptor('evidence'))
  async updateInsurance(
    @Param('insuranceId', ParseIntPipe) insuranceId: number,
    @Body() dto: UpdateInsuranceDto,
    @UploadedFile() file?: Express.Multer.File,
    @CurrentUser() user,
  ) { ... }
}
```

**DTOs**:

```typescript
// create-insurance.dto.ts
export class CreateInsuranceDto {
  @IsEnum(['GENERAL_ACTIVITIES', 'CAMPOREE', 'HIGH_RISK'])
  insurance_type: string;

  @IsDateString()
  start_date: string;

  @IsDateString()
  end_date: string;

  @IsOptional() @IsString() policy_number?: string;
  @IsOptional() @IsString() provider?: string;
  @IsOptional() @IsNumber() coverage_amount?: number;
}

// update-insurance.dto.ts
export class UpdateInsuranceDto extends PartialType(CreateInsuranceDto) {}
```

**Status**: 🔲

---

## Tarea 5.3: Implementar InsuranceService

**Lógica por endpoint**:

1. **listMembersInsurance**: Buscar miembros del club/section vía `club_role_assignments`. Para cada miembro, buscar su seguro activo más reciente. Devolver lista con datos de usuario + insurance.

2. **getMemberInsurance**: Buscar el seguro activo del usuario. Incluir datos del usuario (name, last_name, user_image). Devolver con current_class si existe.

3. **createInsurance**:
   - Si hay file multipart → subir a R2 → guardar URL
   - Crear registro en `member_insurances`
   - Guardar `created_by_id`

4. **updateInsurance**:
   - Si hay file multipart → subir a R2 → actualizar URL
   - Update parcial del registro
   - Guardar `modified_by_id`

**Formato de respuesta para listMembersInsurance** (lo que la app espera):
```json
[
  {
    "user_id": "uuid",
    "name": "Juan",
    "paternal_last_name": "García",
    "maternal_last_name": "López",
    "user_image": "https://...",
    "current_class": { "name": "Explorador" },
    "insurance": {
      "insurance_id": 1,
      "insurance_type": "GENERAL_ACTIVITIES",
      "policy_number": "POL-001",
      "provider": "Seguros SACDIA",
      "start_date": "2025-01-01",
      "end_date": "2025-12-31",
      "coverage_amount": 500.00,
      "active": true,
      "evidence_file_url": "https://...",
      "evidence_file_name": "comprobante.pdf",
      "created_at": "...",
      "modified_at": "...",
      "created_by_name": "Director Juan",
      "modified_by_name": null
    }
  }
]
```

**Status**: 🔲

---

## Tarea 5.4: Registrar en AppModule

**Archivo**: `sacdia-backend/src/app.module.ts`

Agregar `InsuranceModule` al array de imports.

**Status**: 🔲

---

## Tarea 5.5: Tests unitarios y e2e

1. Tests unitarios para `InsuranceService` (mock Prisma + R2)
2. Test e2e para los 4 endpoints
3. `pnpm run test` y `pnpm run test:e2e` pasan

**Status**: 🔲

---

## Tarea 5.6: Commit, push y PR

```bash
git add -A
git commit -m "feat(insurance): implement insurance CRUD endpoints for mobile app"
git push origin development
gh pr create --base preproduction --head development --title "feat(insurance): member insurance management endpoints"
```

**Status**: 🔲

---

## Orden de ejecución
```
5.1 (migration) → 5.2 (module + controller + DTOs) → 5.3 (service) → 5.4 (app.module) → 5.5 (tests) → 5.6 (commit)
```

## Dependencias
- Cloudflare R2 configurado para upload de evidence files
- Multer configurado para multipart
- Bloque 4 (Evidence Folder) puede compartir la misma infra de R2 upload
