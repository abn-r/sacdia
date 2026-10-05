# Usuarios de prueba — rama de desarrollo

**Estado**: ACTIVE
**Actualizado**: 2026-10-04
**Fuente**: `sacdia-backend/prisma/seeds/test-users.seed.ts`

Un usuario por rol administrativo para probar flujos RBAC. Solo para la base de desarrollo de Neon: no ejecutar el seed contra `preproduction` ni producción.

## Cómo se crean

```bash
cd sacdia-backend
pnpm exec tsx prisma/seeds/test-users.seed.ts
```

- Idempotente: se puede volver a ejecutar; refresca el hash de la contraseña y reactiva usuarios y asignaciones.
- Requiere que los roles existan (`prisma/seed.ts`) y que `role-permissions.seed.sql` se haya aplicado; si un rol no existe, el seed falla.
- Todos los usuarios quedan con `email_verified`, `approval_status = approved`, acceso a la app y post-registro completo (no pasan por el onboarding).

## Credenciales

Todos comparten la misma contraseña, definida en la constante `PASSWORD` del seed. No se replica en documentación versionada; consúltala en el seed o pídela por el canal privado del equipo. Si se ha compartido fuera del equipo, cámbiala en el seed y vuelve a ejecutarlo.

## Usuarios con rol global

Asignados en `users_roles`. Todos tienen acceso al panel (`access_panel = true`) y pertenecen a la unión `20` (IOMU, Unión Mexicana Interoceánica).

| Email | Rol | Alcance |
|---|---|---|
| `director-lf@sacdia.com` | `director-lf` | Campo local `4` (ACV, Asociación Centro de Veracruz) |
| `assistant-lf@sacdia.com` | `assistant-lf` | Campo local `4` |
| `director-union@sacdia.com` | `director-union` | Unión `20` |
| `assistant-union@sacdia.com` | `assistant-union` | Unión `20` |

## Usuarios con rol de club

Asignados en `club_role_assignments` a la sección `club_section_id = 1` (Club 1, Guías Mayores) en el año eclesiástico `year_id = 1`. Solo usan la app (`access_panel = false`); campo local `4` y unión `20`.

| Email | Rol |
|---|---|
| `director-club@sacdia.com` | `director` |
| `secretary-club@sacdia.com` | `secretary` |
| `treasurer-club@sacdia.com` | `treasurer` |
| `counselor@sacdia.com` | `counselor` |

## Notas

- Los IDs (`LOCAL_FIELD_ID = 4`, `UNION_ID = 20`, `CLUB_SECTION_ID = 1`, `YEAR_ID = 1`) son constantes del seed y dependen de los datos de la base de desarrollo.
- El seed no crea usuarios para `super-admin`, `admin`, `coordinator`, `pastor`, `deputy-director`, `secretary-treasurer`, `instructor` ni `member`. Para esos roles, usa los datos de `prisma/seeds/core.ts` (`pnpm prisma:seed:core`, solo rama de desarrollo) o crea la asignación a mano.
- Los permisos de cada rol vienen de `prisma/seeds/role-permissions.seed.sql`.

Para comprobarlos en la base:

```sql
SELECT email, active, local_field_id, union_id
FROM users
WHERE email LIKE '%@sacdia.com'
ORDER BY email;
```
