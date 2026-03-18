# Bloque 1: Auth Features Faltantes

> 3 endpoints que el admin panel o la app móvil consumen pero el backend no implementa.
> Complejidad: MODERADA

---

## Contexto

| Endpoint | Consumido por | Backend | DB |
|----------|---------------|---------|-----|
| `PATCH /admin/users/:userId/approval` | Admin panel | ❌ | ❌ No hay campo approval |
| `PATCH /admin/users/:userId` | Admin panel (fallback) | ❌ | ⚠️ Campos existen |
| `POST /auth/update-password` | App móvil | ❌ | ✅ Supabase Auth |

---

## Tarea 1.1: Agregar campo de aprobación al schema

**Archivo**: `sacdia-backend/prisma/schema.prisma`

**Qué hacer**:
1. Agregar un enum `user_approval_status` con valores: `pending`, `approved`, `rejected`
2. Agregar campo `approval_status` al modelo `users` con default `pending`
3. Agregar campo `rejection_reason` (String?, nullable) al modelo `users`
4. Crear migración: `npx prisma migrate dev --name add_user_approval_status`
5. Correr `npx prisma generate`

**Verificación**: `npx prisma migrate status` muestra migración aplicada.

**Status**: 🔲

---

## Tarea 1.2: Implementar PATCH /admin/users/:userId/approval

**Archivos a modificar**:
- `sacdia-backend/src/admin/dto/users.dto.ts` — agregar DTO
- `sacdia-backend/src/admin/admin-users.controller.ts` — agregar endpoint
- `sacdia-backend/src/admin/admin-users.service.ts` — agregar lógica

**Qué hacer**:

1. **DTO** en `users.dto.ts`:
```typescript
export class UpdateUserApprovalDto {
  @IsBoolean()
  approved: boolean;

  @IsString()
  @IsOptional()
  rejection_reason?: string;
}
```

2. **Controller** en `admin-users.controller.ts`:
```typescript
@Patch('users/:userId/approval')
@RequirePermissions('users:update')
@ApiOperation({ summary: 'Approve or reject a user' })
async updateUserApproval(
  @Param('userId') userId: string,
  @Body() dto: UpdateUserApprovalDto,
) {
  const data = await this.adminUsersService.updateUserApproval(userId, dto);
  return { status: 'success', data };
}
```

3. **Service** en `admin-users.service.ts`:
```typescript
async updateUserApproval(userId: string, dto: UpdateUserApprovalDto) {
  return this.prisma.users.update({
    where: { user_id: userId },
    data: {
      approval_status: dto.approved ? 'approved' : 'rejected',
      rejection_reason: dto.approved ? null : dto.rejection_reason,
      active: dto.approved,
    },
  });
}
```

**Verificación**: `pnpm run test` pasa. Probar con curl o desde el admin panel.

**Status**: 🔲

---

## Tarea 1.3: Implementar PATCH /admin/users/:userId (update general)

**Archivos a modificar**:
- `sacdia-backend/src/admin/dto/users.dto.ts` — agregar DTO
- `sacdia-backend/src/admin/admin-users.controller.ts` — agregar endpoint
- `sacdia-backend/src/admin/admin-users.service.ts` — agregar lógica

**Qué hacer**:

1. **DTO** en `users.dto.ts`:
```typescript
export class UpdateAdminUserDto {
  @IsOptional() @IsBoolean() active?: boolean;
  @IsOptional() @IsBoolean() access_app?: boolean;
  @IsOptional() @IsBoolean() access_panel?: boolean;
  @IsOptional() @IsString() approval_status?: string;
  @IsOptional() @IsString() rejection_reason?: string;
}
```

2. **Controller**:
```typescript
@Patch('users/:userId')
@RequirePermissions('users:update')
@ApiOperation({ summary: 'Update user administrative fields' })
async updateUser(
  @Param('userId') userId: string,
  @Body() dto: UpdateAdminUserDto,
) {
  const data = await this.adminUsersService.updateUser(userId, dto);
  return { status: 'success', data };
}
```

3. **Service**:
```typescript
async updateUser(userId: string, dto: UpdateAdminUserDto) {
  return this.prisma.users.update({
    where: { user_id: userId },
    data: dto,
  });
}
```

**Verificación**: `pnpm run test` pasa.

**Status**: 🔲

---

## Tarea 1.4: Implementar POST /auth/update-password

**Archivos a modificar**:
- `sacdia-backend/src/auth/dto/` — crear `update-password.dto.ts`
- `sacdia-backend/src/auth/auth.controller.ts` — agregar endpoint
- `sacdia-backend/src/auth/auth.service.ts` — agregar lógica

**Qué hacer**:

1. **DTO** — crear `src/auth/dto/update-password.dto.ts`:
```typescript
import { IsString, MinLength } from 'class-validator';

export class UpdatePasswordDto {
  @IsString()
  @MinLength(8)
  password: string;
}
```

2. **Controller** en `auth.controller.ts`:
```typescript
@Post('update-password')
@UseGuards(JwtAuthGuard)
@ApiOperation({ summary: 'Update authenticated user password' })
async updatePassword(
  @CurrentUser() user: JwtPayload,
  @Body() dto: UpdatePasswordDto,
) {
  await this.authService.updatePassword(user.sub, dto.password);
  return { status: 'success', message: 'Password updated' };
}
```

3. **Service** en `auth.service.ts` — usar Supabase Admin API:
```typescript
async updatePassword(userId: string, newPassword: string) {
  const { error } = await this.supabaseAdmin.auth.admin.updateUserById(
    userId,
    { password: newPassword },
  );
  if (error) {
    throw new InternalServerErrorException('Failed to update password');
  }
}
```

**Nota**: Verificar que `this.supabaseAdmin` esté disponible en AuthService. Si no, inyectar el client de Supabase Admin.

**Verificación**: `pnpm run test` pasa. Probar desde la app: la llamada ya existe en `auth_remote_data_source.dart` pero retorna mock.

**Status**: 🔲

---

## Tarea 1.5: Tests unitarios

**Archivos a crear/modificar**:
- `sacdia-backend/src/admin/admin-users.controller.spec.ts` — agregar tests para approval y update
- `sacdia-backend/src/auth/auth.service.spec.ts` — agregar test para updatePassword

**Qué testear**:
- Approval: approve user → `approval_status = approved`, `active = true`
- Approval: reject user → `approval_status = rejected`, `active = false`, `rejection_reason` guardada
- Update user: partial update funciona
- Update password: llama a Supabase Admin con el userId correcto
- Update password: error de Supabase lanza InternalServerErrorException

**Verificación**: `pnpm run test` — todos pasan.

**Status**: 🔲

---

## Tarea 1.6: Commit, push y PR

**Comandos**:
```bash
cd sacdia-backend
git add -A
git commit -m "feat(auth): implement user approval, admin update, and password change endpoints"
git push origin development
gh pr create --base preproduction --head development --title "feat(auth): user approval, admin update, password change"
```

**Status**: 🔲

---

## Orden de ejecución
```
1.1 (schema) → 1.2 (approval) → 1.3 (update) → 1.4 (password) → 1.5 (tests) → 1.6 (commit)
```
