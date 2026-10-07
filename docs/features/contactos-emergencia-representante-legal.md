# Contactos de emergencia y representante legal

**Estado**: IMPLEMENTADO
**Verificado contra código**: 2026-10-04 (rama `development`)
**Dominios relacionados**: [auth.md](auth.md) (post-registro), [rbac.md](rbac.md) (permisos de subrecursos sensibles)

## Descripcion de dominio

Cada usuario registra entre uno y cinco contactos de emergencia, y los menores de 18 años, además, un representante legal. Son datos sensibles: el dueño los gestiona sin permisos adicionales y un tercero necesita el permiso fino de la familia correspondiente. El post-registro no se completa sin ellos.

## Que existe (verificado contra codigo)

### Backend

Ambos controllers usan `JwtAuthGuard` + `PermissionsGuard` y el decorador `@SensitiveUserSubresource(familia, modo)`, que aplica `RequirePermissions('{familia}:{modo}')` y `AuthorizationResource({ type: 'user', ownerParam: 'userId' })`. El dueño del recurso pasa sin permiso adicional.

| Método | Ruta (`/api/v1`) | Permiso fino | Respaldo heredado |
|---|---|---|---|
| POST | `/users/:userId/emergency-contacts` | `emergency_contacts:update` | `users:update_profile` |
| GET | `/users/:userId/emergency-contacts` | `emergency_contacts:read` | `users:read_detail` |
| GET | `/users/:userId/emergency-contacts/:contactId` | `emergency_contacts:read` | `users:read_detail` |
| PATCH / DELETE | `/users/:userId/emergency-contacts/:contactId` | `emergency_contacts:update` | `users:update_profile` |
| POST / PATCH / DELETE | `/users/:userId/legal-representative` | `legal_representative:update` | `users:update_profile` |
| GET | `/users/:userId/legal-representative` | `legal_representative:read` | `users:read_detail` |

El respaldo `users:*` para terceros sigue vigente hasta `USERS_LEGACY_OR_SUNSET_DATE = '2027-03-31'` (`sensitive-user-subresource-policy.ts`).

Reglas verificadas en `emergency-contacts.service.ts`:

- Máximo 5 contactos activos (`EC_MAX_CONTACTS_REACHED`).
- No se repite un contacto activo con el mismo nombre y teléfono (`EC_ALREADY_EXISTS`).
- `relationship_type_id` debe existir (`EC_INVALID_RELATIONSHIP_TYPE`).
- Marcar uno como `primary` desmarca los demás.
- El listado ordena primero el principal y devuelve cuántos contactos quedan disponibles.
- `DELETE` es borrado lógico (`active = false`).

Reglas verificadas en `legal-representatives.service.ts`:

- Solo se registra si el usuario lo requiere: `UsersService.requiresLegalRepresentative` devuelve `true` cuando la edad calculada es menor de 18 (si no, `LEGAL_REP_NOT_REQUIRED`).
- Uno por usuario (`user_id` único; `LEGAL_REP_ALREADY_EXISTS`).
- Se indica un usuario registrado (`representative_user_id`, que debe existir) o datos manuales con nombre, apellido paterno y teléfono como mínimo (`LEGAL_REP_DATA_REQUIRED`).
- `relationship_type_id` debe existir.
- `DELETE` borra la fila.

Relación con post-registro (`post-registration.service.ts`): el paso 2 exige al menos un contacto de emergencia (`POST_REG_EMERGENCY_CONTACT_REQUIRED`) y, si el usuario es menor de 18, un representante legal (`POST_REG_LEGAL_REP_REQUIRED`).

Otros consumidores: la validación de QR devuelve el contacto principal (ver [qr-credencial.md](qr-credencial.md)); `GET /api/v1/admin/users/:userId` incluye estos bloques solo si el actor tiene el permiso de lectura correspondiente (ver [rbac.md](rbac.md)).

### App móvil

- Post-registro (`lib/features/post_registration/`): `EmergencyContactsView`, `AddEditContactView` y `LegalRepresentativeView`, dentro de `PostRegistrationShell` y `PersonalInfoStepView`.
- Perfil: `MedicalInfoView` (`lib/features/profile/`) también consume contactos de emergencia.

### Admin

- Sin pantalla propia; los datos aparecen en el detalle de usuario según permisos.

### Base de datos

- `emergency_contacts`: `owner_id`, `contact_user_id` (opcional), `name`, `phone`, `relationship_type_id`, `primary`, `active`.
- `legal_representatives`: `user_id` (único), `representative_user_id` (opcional), `name`, `paternal_last_name`, `maternal_last_name`, `phone`, `relationship_type_id`.

## Gaps y pendientes

- Si un menor cumple 18 años, su representante legal no se elimina ni se marca como inactivo.
- El borrado del representante legal es físico; el de los contactos, lógico.
