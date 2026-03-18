# Bloque 2: Honor Categories CRUD

> 5 endpoints admin CRUD que el panel consume pero el backend no implementa.
> Complejidad: MODERADA — seguir el patrón de AdminReferenceController.
> La tabla `honors_categories` ya existe en la DB.

---

## Contexto

| Endpoint | Admin panel | Backend |
|----------|-------------|---------|
| `GET /admin/honor-categories` | ✅ Página + componente | ❌ |
| `GET /admin/honor-categories/:id` | ✅ | ❌ |
| `POST /admin/honor-categories` | ✅ Formulario | ❌ |
| `PATCH /admin/honor-categories/:id` | ✅ Formulario | ❌ |
| `DELETE /admin/honor-categories/:id` | ✅ Confirm dialog | ❌ |

**Patrón a seguir**: `sacdia-backend/src/admin/admin-reference.controller.ts` y `admin-reference.service.ts` — ya manejan allergies, diseases, medicines, ecclesiastical-years con el mismo patrón.

**Tabla DB**: `honors_categories` con campos: `honor_category_id` (PK), `name` (unique), `description`, `icon` (int, NOT NULL), `active`, timestamps.

**Discrepancia**: El admin no envía `icon` en create/update. El campo es NOT NULL en DB. Decidir si hacerlo nullable o agregar default.

---

## Tarea 2.1: Resolver discrepancia del campo `icon`

**Archivo**: `sacdia-backend/prisma/schema.prisma`

**Opciones**:
- A) Hacer `icon` nullable: `icon Int?` → crear migración
- B) Agregar default: `icon Int @default(0)` → crear migración
- C) Mantener NOT NULL y agregar `icon` al formulario del admin

**Recomendación**: Opción A (nullable) — el icon no es crítico y el admin no lo maneja.

**Qué hacer**:
1. Cambiar `icon Int` a `icon Int?` en el modelo `honors_categories`
2. `npx prisma migrate dev --name make_honor_category_icon_nullable`
3. `npx prisma generate`

**Status**: 🔲

---

## Tarea 2.2: Agregar CRUD de honor-categories al AdminReferenceController

**Archivos a modificar**:
- `sacdia-backend/src/admin/admin-reference.controller.ts`
- `sacdia-backend/src/admin/admin-reference.service.ts`

**Qué hacer** — seguir el patrón exacto de allergies/diseases:

1. **Controller** — agregar 5 métodos en `admin-reference.controller.ts`:
```typescript
// LIST
@Get('honor-categories')
@RequirePermissions('honor_categories:read')
@ApiOperation({ summary: 'List honor categories' })
async listHonorCategories(@Query() query: PaginationDto) {
  const data = await this.service.listHonorCategories(query);
  return { status: 'success', data };
}

// GET ONE
@Get('honor-categories/:id')
@RequirePermissions('honor_categories:read')
async getHonorCategory(@Param('id', ParseIntPipe) id: number) {
  const data = await this.service.getHonorCategory(id);
  return { status: 'success', data };
}

// CREATE
@Post('honor-categories')
@RequirePermissions('honor_categories:create')
async createHonorCategory(@Body() dto: CreateHonorCategoryDto, @CurrentUser() user) {
  const data = await this.service.createHonorCategory(dto, user.sub);
  return { status: 'success', data };
}

// UPDATE
@Patch('honor-categories/:id')
@RequirePermissions('honor_categories:update')
async updateHonorCategory(
  @Param('id', ParseIntPipe) id: number,
  @Body() dto: UpdateHonorCategoryDto,
  @CurrentUser() user,
) {
  const data = await this.service.updateHonorCategory(id, dto, user.sub);
  return { status: 'success', data };
}

// DELETE
@Delete('honor-categories/:id')
@RequirePermissions('honor_categories:delete')
async deleteHonorCategory(@Param('id', ParseIntPipe) id: number, @CurrentUser() user) {
  await this.service.deleteHonorCategory(id, user.sub);
  return { status: 'success' };
}
```

2. **Service** — agregar métodos en `admin-reference.service.ts`:
```typescript
async listHonorCategories(query: PaginationDto) {
  const { page = 1, limit = 20, search } = query;
  const where = search ? { name: { contains: search, mode: 'insensitive' } } : {};
  const [data, total] = await Promise.all([
    this.prisma.honors_categories.findMany({
      where,
      skip: (page - 1) * limit,
      take: limit,
      orderBy: { name: 'asc' },
      include: { _count: { select: { honors: true } } },
    }),
    this.prisma.honors_categories.count({ where }),
  ]);
  return { items: data, total, page, limit };
}

async getHonorCategory(id: number) {
  return this.prisma.honors_categories.findUniqueOrThrow({
    where: { honor_category_id: id },
    include: { _count: { select: { honors: true } } },
  });
}

async createHonorCategory(dto: CreateHonorCategoryDto, actorId: string) {
  this.logger.log(`[createHonorCategory] actor=${actorId}`);
  return this.prisma.honors_categories.create({ data: dto });
}

async updateHonorCategory(id: number, dto: UpdateHonorCategoryDto, actorId: string) {
  this.logger.log(`[updateHonorCategory] id=${id} actor=${actorId}`);
  return this.prisma.honors_categories.update({
    where: { honor_category_id: id },
    data: dto,
  });
}

async deleteHonorCategory(id: number, actorId: string) {
  this.logger.log(`[deleteHonorCategory] id=${id} actor=${actorId}`);
  return this.prisma.honors_categories.update({
    where: { honor_category_id: id },
    data: { active: false },
  });
}
```

3. **DTOs** — crear en `sacdia-backend/src/admin/dto/honor-categories.dto.ts`:
```typescript
export class CreateHonorCategoryDto {
  @IsString() name: string;
  @IsOptional() @IsString() description?: string;
  @IsOptional() @IsBoolean() active?: boolean;
}

export class UpdateHonorCategoryDto extends PartialType(CreateHonorCategoryDto) {}
```

**Verificación**: `pnpm run test` pasa. El admin panel debería poder listar, crear, editar y eliminar categorías.

**Status**: 🔲

---

## Tarea 2.3: Agregar permisos a la DB

**Qué hacer**: Insertar los 4 permisos `honor_categories:*` en la tabla `permissions` (si no existen).

```sql
INSERT INTO permissions (permission_id, permission_name, description, active)
VALUES
  (gen_random_uuid(), 'honor_categories:read', 'Read honor categories', true),
  (gen_random_uuid(), 'honor_categories:create', 'Create honor categories', true),
  (gen_random_uuid(), 'honor_categories:update', 'Update honor categories', true),
  (gen_random_uuid(), 'honor_categories:delete', 'Delete honor categories', true)
ON CONFLICT (permission_name) DO NOTHING;
```

Ejecutar via psql contra la DB.

**Status**: 🔲

---

## Tarea 2.4: Tests y commit

1. Escribir tests unitarios para los 5 métodos del service
2. `pnpm run test` — todos pasan
3. Commit:
```bash
git add -A
git commit -m "feat(admin): implement honor categories CRUD endpoints"
git push origin development
gh pr create --base preproduction --head development --title "feat(admin): honor categories CRUD"
```

**Status**: 🔲

---

## Orden de ejecución
```
2.1 (schema fix) → 2.2 (controller + service + DTOs) → 2.3 (permisos DB) → 2.4 (tests + commit)
```
