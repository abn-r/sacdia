# Contactos de emergencia y representante legal

**Estado**: IMPLEMENTADO. Contactos de emergencia: sin cambios. Representante legal: **de solo lectura** en la rama `feat/family-profiles` (Fase 2 de perfiles familiares; Pendiente de merge (PR #530 de sacdia-backend, PR #178 de sacdia-app)); en `development` aún existen las rutas de escritura
**Fase 4 (backend #654, app #257, admin #305)**: el representante legal se **eliminó por completo** de `development` (módulo, rutas, bloque del panel y permisos renombrados). La tabla `legal_representatives` ya no tiene modelo Prisma, pero se borra de la base con la migración `20261114100000` (**Pendiente de merge (backend PR #655, en borrador)**; aplicada solo en Neon `development`). Lo histórico de este documento se conserva como contexto. Ver «Eliminación del representante legal (Fase 4)».
**Verificado contra código**: contactos de emergencia, 2026-10-04 (rama `development`); representante legal, 2026-10-19 (backend `feat/family-profiles` `603d3d8e`)
**Dominios relacionados**: [auth.md](auth.md) (post-registro), [rbac.md](rbac.md) (permisos de subrecursos sensibles), [family-profiles.md](family-profiles.md) (tutorías, que reemplazan al representante legal)

## Descripcion de dominio

Cada usuario registra entre uno y cinco contactos de emergencia. Son datos sensibles: el dueño los gestiona sin permisos adicionales y un tercero necesita el permiso fino de la familia correspondiente. El post-registro no se completa sin al menos un contacto.

> [!IMPORTANT]
> **Eliminación del representante legal (Fase 4, backend #654, app #257, admin #305)**
>
> - Se borra el módulo `src/legal-representatives/` y se retiran `GET /users/:userId/legal-representative` y `GET /users/:userId/requires-legal-representative` (ya no existen; responden 404). Ningún cliente las usa: la sección 06 «Representante legal (heredado)» del Resumen del panel y los tipos asociados se quitaron; la app no tiene referencias (una prueba lo vigila).
> - El bloque `legal_representative` desaparece de `GET /admin/users/:userId`. El permiso `legal_representative:read|update` pasa a `guardianship:read|update` (mismos ids, respaldo `users:*` hasta 2027-03-31; ver [rbac.md](rbac.md)).
> - El modelo Prisma `legal_representatives` ya no existe en `development`. La tabla se borra con la migración `20261114100000_family_drop_legal_representatives` (**Pendiente de merge (backend PR #655, en borrador)**; ya aplicada en Neon `development`), **irreversible**, después de la copia `pg_dump` por ambiente y con este cambio ya desplegado. **No se migra ningún dato a `guardianships`**: las tutorías no heredan los representantes antiguos (el script de desarrollo `seed-dev-guardianships.ts --from-legal-reps` se quitó). Un representante legal histórico solo se recupera de la copia.
> - Se conservan los códigos `LEGAL_REP_*` en `ErrorCode` y en los `errors.json` (sin ruta que los emita), y el eliminar un tipo de parentesco (`DELETE /admin/relationship-types/:id`) ahora solo se bloquea si lo usa una tutoría.
> - La liberación a los 18 años (Fase 4) reemplaza el tema que antes quedaba como pendiente: ver [family-profiles.md](family-profiles.md), «Fase 4».

> [!NOTE]
> **Representante legal retirado (perfiles familiares, Fase 2)**: ya no se registra un representante legal. Las **tutorías** (`guardianships`) lo reemplazan: el tutor adulto registra al menor de 13 años y un director verifica la ficha de consentimiento. La tabla `legal_representatives` y su lectura quedan solo como historial hasta la Fase 4, que la elimina. Detalle en [family-profiles.md](family-profiles.md). Mientras la Fase 3 no exista, un adolescente de 13 a 17 años que se registra solo no tiene ni tutor ni representante legal.

## Que existe (verificado contra codigo)

### Backend

El controller de contactos (y, hasta la Fase 4, el de representante legal) usa `JwtAuthGuard` + `PermissionsGuard` y el decorador `@SensitiveUserSubresource(familia, modo)`, que aplica `RequirePermissions('{familia}:{modo}')` y `AuthorizationResource({ type: 'user', ownerParam: 'userId' })`. El dueño del recurso pasa sin permiso adicional.

| Método | Ruta (`/api/v1`) | Permiso fino | Respaldo heredado |
|---|---|---|---|
| POST | `/users/:userId/emergency-contacts` | `emergency_contacts:update` | `users:update_profile` |
| GET | `/users/:userId/emergency-contacts` | `emergency_contacts:read` | `users:read_detail` |
| GET | `/users/:userId/emergency-contacts/:contactId` | `emergency_contacts:read` | `users:read_detail` |
| PATCH / DELETE | `/users/:userId/emergency-contacts/:contactId` | `emergency_contacts:update` | `users:update_profile` |

El respaldo `users:*` para terceros sigue vigente hasta `USERS_LEGACY_OR_SUNSET_DATE = '2027-03-31'` (`sensitive-user-subresource-policy.ts`).

Reglas verificadas en `emergency-contacts.service.ts`:

- Máximo 5 contactos activos (`EC_MAX_CONTACTS_REACHED`).
- No se repite un contacto activo con el mismo nombre y teléfono (`EC_ALREADY_EXISTS`).
- `relationship_type_id` debe existir (`EC_INVALID_RELATIONSHIP_TYPE`).
- Marcar uno como `primary` desmarca los demás.
- El listado ordena primero el principal y devuelve cuántos contactos quedan disponibles.
- `DELETE` es borrado lógico (`active = false`).

Representante legal (módulo `legal-representatives`, **eliminado en la Fase 4**; antes de solo lectura desde la Fase 2). Lo que sigue es histórico:

- `GET /users/:userId/legal-representative` es la única ruta que queda (`legal-representatives.controller.ts:27`); devuelve el representante o `data = null` si no existe, y 404 `LEGAL_REP_OWNER_NOT_FOUND` si el usuario no existe. Es un dato sensible (`legal_representative:read`) y **no** declara `@ActingScope`: un tutor no puede leerlo actuando por un menor.
- `POST`, `PATCH` y `DELETE /users/:userId/legal-representative` se **retiraron** junto con sus DTO, servicios y specs: el servidor responde 404. El permiso `legal_representative:update` sigue en el catálogo y en los seeds de otros roles, pero ninguna ruta lo usa.
- Los códigos `LEGAL_REP_*` (salvo `LEGAL_REP_OWNER_NOT_FOUND`) siguen en `ErrorCode` y en los `errors.json`, pero ninguna ruta los emite.
- `GET /users/:userId/requires-legal-representative` sigue, marcado como deprecado en Swagger; calcula la mayoría de edad con el país del usuario (`UsersService.requiresLegalRepresentative`: edad menor a `ageOfMajority`), ya no un 18 fijo (`users.controller.ts:370-395`, `users.service.ts:989-992`).
- **Fase 4 (backend #654)**: todo este bloque de rutas desapareció, incluido `GET /users/:userId/requires-legal-representative` (ver la nota de arriba).
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
- `legal_representatives`: `user_id` (único), `representative_user_id` (opcional), `name`, `paternal_last_name`, `maternal_last_name`, `phone`, `relationship_type_id`. Sin modelo Prisma desde la Fase 4 (backend #654); la tabla se elimina de la base con la migración `20261114100000` (**Pendiente de merge (backend PR #655, en borrador)**). La opción `--from-legal-reps` de `scripts/family-profiles/seed-dev-guardianships.ts` se quitó.

## Gaps y pendientes

- Si un menor cumple 18 años, su representante legal no se elimina ni se marca como inactivo; la tabla se elimina entera en la Fase 4 (backend #654; el borrado de la tabla, backend PR #655, está pendiente de merge), junto con la liberación a la mayoría de edad.
- Ya no hay forma de registrar, corregir, borrar ni leer un representante legal. La cadena de consentimiento nueva es la de tutorías.
- Los contactos se borran de forma lógica.
