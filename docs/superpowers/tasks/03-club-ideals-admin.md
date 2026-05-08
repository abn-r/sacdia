# Bloque 3: Club Ideals Admin Endpoint

> 1 endpoint read-only que el admin panel consume pero el backend no expone en la ruta admin.
> Complejidad: TRIVIAL — la lógica ya existe en CatalogsService, solo falta la ruta admin.

---

## Contexto

- El admin define `allowMutations: false` — es read-only
- El endpoint público `GET /catalogs/club-ideals` YA EXISTE y funciona
- Solo falta `GET /admin/club-ideals` que devuelva TODOS los registros (no solo activos) con formato `{ status, data }`
- La tabla `club_ideals` existe con campos: `club_ideal_id`, `name`, `ideal`, `ideal_order`, `club_type_id`, `active`, timestamps

---

## Tarea 3.1: Agregar endpoint admin read-only

**Archivos a modificar**:
- `sacdia-backend/src/admin/admin-reference.controller.ts`
- `sacdia-backend/src/admin/admin-reference.service.ts`

**Qué hacer**:

1. **Controller** en `admin-reference.controller.ts`:
```typescript
@Get('club-ideals')
@RequirePermissions('catalogs:read')
@ApiOperation({ summary: 'List club ideals for admin' })
async listClubIdeals() {
  const data = await this.service.listClubIdeals();
  return { status: 'success', data };
}
```

2. **Service** en `admin-reference.service.ts`:
```typescript
async listClubIdeals() {
  return this.prisma.club_ideals.findMany({
    orderBy: [{ club_type_id: 'asc' }, { ideal_order: 'asc' }],
  });
}
```

Eso es todo. No necesita DTOs, no necesita create/update/delete.

**Verificación**: `pnpm run test` pasa. Admin panel carga la página de club-ideals.

**Status**: ✅ DONE — endpoint exists in admin-reference.controller.ts

---

## Tarea 3.2: Commit

```bash
git add -A
git commit -m "feat(admin): add read-only club-ideals endpoint"
git push origin development
```

Se puede agrupar con otro bloque en el mismo PR si se implementan juntos.

**Status**: ✅ DONE — included in batch PRs #10/#11 merged to main
