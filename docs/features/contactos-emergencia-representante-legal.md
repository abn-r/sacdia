# Contactos de emergencia y representante legal

**Estado**: IMPLEMENTADO. Contactos de emergencia: sin cambios. Representante legal: **de solo lectura** en la rama `feat/family-profiles` (Fase 2 de perfiles familiares, pendiente de merge); en `development` aún existen las rutas de escritura
**Verificado contra código**: contactos de emergencia, 2026-10-04 (rama `development`); representante legal, 2026-10-19 (backend `feat/family-profiles` `603d3d8e`)
**Dominios relacionados**: [auth.md](auth.md) (post-registro), [rbac.md](rbac.md) (permisos de subrecursos sensibles), [family-profiles.md](family-profiles.md) (tutorías, que reemplazan al representante legal)

## Descripcion de dominio

Cada usuario registra entre uno y cinco contactos de emergencia. Son datos sensibles: el dueño los gestiona sin permisos adicionales y un tercero necesita el permiso fino de la familia correspondiente. El post-registro no se completa sin al menos un contacto.

> [!NOTE]
> **Representante legal retirado (perfiles familiares, Fase 2)**: ya no se registra un representante legal. Las **tutorías** (`guardianships`) lo reemplazan: el tutor adulto registra al menor de 13 años y un director verifica la ficha de consentimiento. La tabla `legal_representatives` y su lectura quedan solo como historial hasta la Fase 4, que la elimina. Detalle en [family-profiles.md](family-profiles.md). Mientras la Fase 3 no exista, un adolescente de 13 a 17 años que se registra solo no tiene ni tutor ni representante legal.

## Que existe (verificado contra codigo)

### Backend

Los controllers de contactos y de representante legal usan `JwtAuthGuard` + `PermissionsGuard` y el decorador `@SensitiveUserSubresource(familia, modo)`, que aplica `RequirePermissions('{familia}:{modo}')` y `AuthorizationResource({ type: 'user', ownerParam: 'userId' })`. El dueño del recurso pasa sin permiso adicional.

| Método | Ruta (`/api/v1`) | Permiso fino | Respaldo heredado |
|---|---|---|---|
| POST | `/users/:userId/emergency-contacts` | `emergency_contacts:update` | `users:update_profile` |
| GET | `/users/:userId/emergency-contacts` | `emergency_contacts:read` | `users:read_detail` |
| GET | `/users/:userId/emergency-contacts/:contactId` | `emergency_contacts:read` | `users:read_detail` |
| PATCH / DELETE | `/users/:userId/emergency-contacts/:contactId` | `emergency_contacts:update` | `users:update_profile` |
| GET | `/users/:userId/legal-representative` (solo lectura) | `legal_representative:read` | `users:read_detail` |

El respaldo `users:*` para terceros sigue vigente hasta `USERS_LEGACY_OR_SUNSET_DATE = '2027-03-31'` (`sensitive-user-subresource-policy.ts`).

Reglas verificadas en `emergency-contacts.service.ts`:

- Máximo 5 contactos activos (`EC_MAX_CONTACTS_REACHED`).
- No se repite un contacto activo con el mismo nombre y teléfono (`EC_ALREADY_EXISTS`).
- `relationship_type_id` debe existir (`EC_INVALID_RELATIONSHIP_TYPE`).
- Marcar uno como `primary` desmarca los demás.
- El listado ordena primero el principal y devuelve cuántos contactos quedan disponibles.
- `DELETE` es borrado lógico (`active = false`).

Representante legal (`legal-representatives.controller.ts` y `legal-representatives.service.ts`, solo lectura desde la Fase 2):

- `GET /users/:userId/legal-representative` es la única ruta que queda (`legal-representatives.controller.ts:27`); devuelve el representante o `data = null` si no existe, y 404 `LEGAL_REP_OWNER_NOT_FOUND` si el usuario no existe. Es un dato sensible (`legal_representative:read`) y **no** declara `@ActingScope`: un tutor no puede leerlo actuando por un menor.
- `POST`, `PATCH` y `DELETE /users/:userId/legal-representative` se **retiraron** junto con sus DTO, servicios y specs: el servidor responde 404. El permiso `legal_representative:update` sigue en el catálogo y en los seeds de otros roles, pero ninguna ruta lo usa.
- Los códigos `LEGAL_REP_*` (salvo `LEGAL_REP_OWNER_NOT_FOUND`) siguen en `ErrorCode` y en los `errors.json`, pero ninguna ruta los emite.
- `GET /users/:userId/requires-legal-representative` sigue, marcado como deprecado en Swagger; calcula la mayoría de edad con el país del usuario (`UsersService.requiresLegalRepresentative`: edad menor a `ageOfMajority`), ya no un 18 fijo (`users.controller.ts:370-395`, `users.service.ts:989-992`).
- **Despliegue conjunto**: la app anterior a la Fase 2 sigue llamando a las rutas de escritura retiradas durante el post-registro; el backend y la app de la Fase 2 se despliegan juntos.

Relación con post-registro (`post-registration.service.ts`): el paso 2 exige datos personales completos y al menos un contacto de emergencia (`POST_REG_EMERGENCY_CONTACT_REQUIRED`). Ya **no** exige representante legal para menores: `POST_REG_LEGAL_REP_REQUIRED` sigue en `ErrorCode` pero ningún flujo lo emite (el cierre de ese paso en `post-registration.service.ts:170-205` solo valida género, fecha de nacimiento, bautismo y contactos).

Otros consumidores: la validación de QR devuelve el contacto principal (ver [qr-credencial.md](qr-credencial.md)); `GET /api/v1/admin/users/:userId` incluye estos bloques solo si el actor tiene el permiso de lectura correspondiente (ver [rbac.md](rbac.md)).

### App móvil

- Post-registro (`lib/features/post_registration/`): `EmergencyContactsView` y `AddEditContactView`, dentro de `PostRegistrationShell` y `PersonalInfoStepView`. La vista `LegalRepresentativeView` ya no existe en la rama `feat/family-profiles`; el menor lo registra su tutor desde «Mi familia» (ver [family-profiles.md](family-profiles.md)).
- Perfil: `MedicalInfoView` (`lib/features/profile/`) también consume contactos de emergencia.

### Admin

- Sin pantalla propia; los datos aparecen en el detalle de usuario según permisos.

### Base de datos

- `emergency_contacts`: `owner_id`, `contact_user_id` (opcional), `name`, `phone`, `relationship_type_id`, `primary`, `active`.
- `legal_representatives`: `user_id` (único), `representative_user_id` (opcional), `name`, `paternal_last_name`, `maternal_last_name`, `phone`, `relationship_type_id`. Solo lectura hasta la Fase 4; `scripts/family-profiles/seed-dev-guardianships.ts --from-legal-reps` (solo desarrollo) las convierte en tutorías `pending` con `verification_method = 'legacy_import'`.

## Gaps y pendientes

- Si un menor cumple 18 años, su representante legal no se elimina ni se marca como inactivo; la tabla se elimina entera en la Fase 4 (liberación a los 18 años).
- Ya no hay forma de registrar, corregir ni borrar un representante legal. Los existentes se leen, y la cadena de consentimiento nueva es la de tutorías.
- Los contactos se borran de forma lógica.
