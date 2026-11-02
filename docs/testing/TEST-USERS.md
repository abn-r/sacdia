# Usuarios de prueba — rama de desarrollo

**Estado**: ACTIVE
**Actualizado**: 2026-10-27
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
| `admin-test@sacdia.com` | `admin` | Ancla en la unión `20` (solo `super-admin` es global) |
| `director-dia@sacdia.com` | `director-dia` | División de la unión `20` |
| `assistant-dia@sacdia.com` | `assistant-dia` | División de la unión `20` |
| `general-coordinator@sacdia.com` | `general-coordinator` | Campo local `4`; el seed le crea una asignación GENERAL sobre el campo local |
| `zone-coordinator@sacdia.com` | `zone-coordinator` | Campo local `4`; el seed le crea la zona "Zona Test" con los distritos que tienen clubes activos y una asignación ZONE de Conquistadores |
| `coordinator@sacdia.com` | `coordinator` | Campo local `4`; sus secciones se asignan en Coordinación |
| `pastor@sacdia.com` | `pastor` | Campo local `4`; su distrito se asigna en Pastores por distrito |

Un coordinador sin secciones asignadas no ve datos (el backend responde `ADMIN_USER_SCOPE_MISSING`). Un `admin` u otro rol territorial sin unión, campo ni división ve una página de bloqueo en el panel.

## Usuarios con rol de club

Asignados en `club_role_assignments` en el año eclesiástico `year_id = 1`. Solo usan la app (`access_panel = false`); campo local `4` y unión `20`.

| Email | Rol | Sección |
|---|---|---|
| `director-club@sacdia.com` | `director` | Primera sección activa del campo local `4` sin director ese año. El seed la busca al ejecutarse; en la rama de desarrollo hoy es `163` (club Estella, Aventureros). Una asignación de director ya terminada no se reutiliza: el seed crea una nueva en la sección vacante. |
| `secretary-club@sacdia.com` | `secretary` | `club_section_id = 1` (Club 1, Guías Mayores) |
| `treasurer-club@sacdia.com` | `treasurer` | `club_section_id = 1` |
| `counselor@sacdia.com` | `counselor` | `club_section_id = 1` |

`director-club` no va a la sección `1` porque ahí ya está `director@sacdia.com` del seed core. La base admite un solo director activo por sección y año (trigger `enforce_club_role_slot_limits` e índice `uniq_cra_director_status_section_year`, migración `20260908180000_director_year_slots`). Si `director-club` ya tiene una asignación de director ese año, el seed la reutiliza.

Si el cupo de un rol ya está ocupado, el seed no se detiene: avisa con `⚠ … skipped` y sigue con el siguiente usuario. El usuario y su contraseña sí se crean o se refrescan; esa asignación no se crea ni se reactiva. Pasa hoy en la sección `1` con `secretary-club` y `treasurer-club`, porque el seed core ya asignó secretario, tesorero y secretario-tesorero.

## Notas

- Los IDs (`LOCAL_FIELD_ID = 4`, `UNION_ID = 20`, `CLUB_SECTION_ID = 1`, `YEAR_ID = 1`) son constantes del seed y dependen de los datos de la base de desarrollo. La sección de `director-club` es la única que se calcula al ejecutar el seed.
- El seed no crea usuarios para `super-admin`, `assistant-admin` (el rol no existe en la base de desarrollo), `deputy-director`, `secretary-treasurer`, `instructor` ni `member`. Para esos roles, usa los datos de `prisma/seeds/core.ts` (`pnpm prisma:seed:core`, solo rama de desarrollo) o crea la asignación a mano.
- Los permisos de cada rol vienen de `prisma/seeds/role-permissions.seed.sql`.

Para comprobarlos en la base:

```sql
SELECT email, active, local_field_id, union_id
FROM users
WHERE email LIKE '%@sacdia.com'
ORDER BY email;
```
