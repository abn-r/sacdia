# Runbook: SQL manual, seeds y scripts que activan roles de club (compuerta de consentimiento)

**Verificado contra código**: 2026-10-19 (backend, rama `feat/family-profiles`)
**Dominio**: [family-profiles.md](../features/family-profiles.md)

## Contexto

Un menor sin cuenta (un **dependiente**: usuario con fila en `dependent_profiles`) solo puede tener un rol de club activo si tiene una tutoría con `consent_status = 'verified'` que no sea de prueba (`is_test_data = false`). Esa regla vive en **código de la aplicación**: `src/membership-requests/assignment-activation-gate.ts`, llamada por cada escritura del backend que activa una fila de `club_role_assignments` (inventario en [ENDPOINTS-LIVE-REFERENCE.md](../api/ENDPOINTS-LIVE-REFERENCE.md), «Compuerta de consentimiento en las activaciones de rol»).

La base de datos **no** la hace cumplir: la migración `20261016120000_family_profiles` no crea ningún trigger sobre `club_role_assignments`. Por eso cualquier escritura que no pase por el servicio **se salta la compuerta**:

- SQL manual con `psql` (por ejemplo `UPDATE club_role_assignments SET status = 'active' ...` o un `INSERT` con `status` por defecto, que es `active`).
- Seeds de Prisma: p. ej. `prisma/seeds/core.ts` (`upsertClubAssignment` escribe `status: 'active'`) y `prisma/seeds/test-users.seed.ts` (crea asignaciones anidadas).
- Scripts y SQL de operación que tocan la tabla: p. ej. `prisma/scripts/club-role-gm-cleanup.sql` y `prisma/scripts/club-role-gm-restore.sql`, que actualizan o insertan filas y pueden dejar una asignación en `active`.
- Cualquier script nuevo con un cliente Prisma propio (`new PrismaClient()`), porque la compuerta es una función del backend que hay que llamar a propósito.

## Regla

**Quien ejecute SQL manual, un seed o un script que active roles de club debe verificar el consentimiento a mano antes** para todo usuario que sea dependiente. Activar a un dependiente sin consentimiento verificado deja un rol operativo sobre un menor sin la ficha firmada que el sistema exige en el resto de rutas.

## Procedimiento

1. Identifica a los usuarios que vas a activar (ids de `user_id`).
2. Detecta cuáles son dependientes y si tienen consentimiento verificado:

   ```sql
   SELECT dp.user_id,
          EXISTS (
            SELECT 1
              FROM guardianships g
             WHERE g.dependent_user_id = dp.user_id
               AND g.consent_status = 'verified'
               AND g.is_test_data = false
          ) AS consentimiento_verificado
     FROM dependent_profiles dp
    WHERE dp.user_id IN ('<user_id_1>', '<user_id_2>');
   ```

   - Un `user_id` que **no** aparece no es dependiente: la compuerta no le aplica.
   - Si aparece con `consentimiento_verificado = false`: **no lo actives**. Haz que el tutor suba la ficha y que un director la verifique desde la app o el panel (`POST .../membership-requests/:assignmentId/verify-consent`). Esa es la única vía que escribe `verified` con evidencia y auditoría.
3. Para una asignación que ya existe y vas a pasar a `active`, comprueba lo mismo sobre `club_role_assignments.user_id` de esa fila antes del `UPDATE`.
4. Para un script que toca muchos usuarios, añade la comprobación del paso 2 como filtro (excluye a los dependientes sin consentimiento verificado) y deja registrado en el resultado a quiénes omitiste.
5. Después de una activación manual, el backend no se entera: el caché de autorización del usuario y su versión de contexto no se invalidan solos. Aplica el procedimiento habitual de la operación que estés haciendo para refrescarlos.

## Qué no hacer

- No marques `guardianships.consent_status = 'verified'` a mano para "desbloquear" una activación: se pierden la ficha, el verificador (`verified_by_user_id`), `verification_method` y el evento de auditoría `guardianship.consent_verified`.
- No uses filas con `is_test_data = true` (las de `scripts/family-profiles/seed-dev-guardianships.ts --placeholders`) como si fueran consentimiento: nunca cuentan, ni en el servicio ni en la consulta de arriba.
- No ejecutes `seed-dev-guardianships.ts` contra producción: el script se niega a correr con `NODE_ENV=production`.

## Referencias

- Código de la compuerta: `sacdia-backend/src/membership-requests/assignment-activation-gate.ts`.
- Guard de pruebas que obliga a gatear cada escritura nueva del servicio: `src/membership-requests/assignment-activation-gate.inventory.spec.ts`.
- Contexto de decisiones: [family-profiles.md](../features/family-profiles.md), «Compuerta de consentimiento».
