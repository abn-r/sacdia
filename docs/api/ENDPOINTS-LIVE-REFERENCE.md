# ENDPOINTS LIVE REFERENCE (Runtime Truth)

<!-- Generado estáticamente contra sacdia-backend/src/**/*controller.ts el 2026-07-07. Resincronizado contra la rama development (commit 66f4ade) el 2026-10-04: conteos recalculados con el mismo extractor estático de decoradores, 12 rutas reales añadidas y 20 rutas de la rama feat/investiture-authorization-ocr marcadas como pendientes de merge. No se levantó la app ni se ejecutó build. -->

> [!IMPORTANT]
> Documento canónico operativo para clientes SACDIA. Base URL: `/api/v1`.
> La tabla refleja los decoradores HTTP efectivos en controllers NestJS; DTOs, ejemplos y errores finos viven en Swagger/runtime y docs de feature cuando aplique.

**Estado**: ACTIVE
**Actualizado**: 2026-10-21 (cola de consentimientos del coordinador, jobs bajo demanda y cobertura de zona; ver la nota «Seguimientos 2026-10-21»). Antes, 2026-10-20 (perfiles familiares, Fase 2 completa: sub-fases 2a, 2b y 2c, y las sub-fases 3a, 3b y 3c pendientes de merge; ver también aceptación legal 2026-10-15 y la nota de resincronización 2026-10-13)
**Total endpoints**: 866 decoradores HTTP en 108 archivos `*.controller.ts` de `development`. La matriz tiene además 20 filas **pendientes de merge (PR #448 de sacdia-backend)**: secciones `class-thresholds`, `investiture-windows`, `investiture-pastors`, `investiture-requests` y el `GET .../sections/:clubSectionId/score` de camporee-scoring.
**Métodos (development)**: GET 353 · POST 279 · PATCH 125 · DELETE 96 · PUT 13
**Auth detectada (development)**: Public 13 · JWT u Optional JWT 853

> [!NOTE]
> **Resincronización parcial 2026-10-13** contra `development` (backend #471 a #480): carga por certificado (incluye `catalog/classes` y el borrado de borradores), instructores de especialidad, propuestas de instructor, mutabilidad de especialidades y certificaciones, y la autenticación de `catalogs`, `honors` y `classes`. Los totales y el conteo de métodos/auth de arriba **no se recalcularon**: el recuento estático actual de decoradores en `*controller.ts` es 900 (GET 371 · POST 287 · PATCH 129 · DELETE 100 · PUT 13) en 115 archivos, distinto del de la cabecera por estos endpoints y por otros cambios posteriores al 2026-10-04.

> [!NOTE]
> **Aceptación legal 2026-10-15** (sacdia-backend, rama `feat/legal-acceptance`): se añaden 3 endpoints (sección `legal`), los campos `accepted_terms_version` y `accepted_privacy_version` en `POST /auth/register`, el bloque `legal` en `GET /auth/me` y la clave `legal_acceptances` en la exportación de datos. Los totales de la cabecera tampoco incluyen estos 3 endpoints.

> [!NOTE]
> **Perfiles familiares 2026-10-19** (sacdia-backend, rama `feat/family-profiles`, Fase 2 completa, Pendiente de merge (PR #530 de sacdia-backend)): se añade el header `X-Acting-For` (tutor que actúa por un menor sin cuenta; sección siguiente) y **16 endpoints nuevos** y **3 retirados**:
>
> - Nuevos: 11 de `guardianships` (8 de la sub-fase 2a, subir y leer la ficha de consentimiento del tutor, y `GET /guardianships/relationship-types`), 3 de `membership-requests` (subir y leer la ficha, `verify-consent`), 1 de `admin` (leer la ficha desde el detalle de usuario) y `POST .../post-registration/step-3/guardian-only`.
> - Retirados: `POST`, `PATCH` y `DELETE /users/:userId/legal-representative` (los representantes legales quedan de solo lectura; ver la sección `legal-representatives`).
> - Cambian de contrato: `POST /auth/register` (`birthday` y `country_id`, 422 por edad mínima), `PATCH /users/:userId` (422 al ponerse una fecha por debajo de la edad mínima de cuenta), `POST .../membership-requests/:assignmentId/approve` (409 `MR_CONSENT_NOT_VERIFIED`), `GET .../membership-requests` (bloque `consent`), `GET /admin/users/:userId` (bloque `guardianships`), `GET /clubs` y `GET /clubs/:clubId/sections` (llevan `@ActingScope('registration:write')`: pasan de 62 a 64 las rutas con scope), `GET /auth/me` (`acting_for`, `family`, `email` nullable), `DELETE /auth/me` (`acknowledge_dependents`), el post-registro paso 2 (ya no pide representante legal), y `POST /guardianships/me/dependents` y `POST /guardianships/link-codes/redeem` (el parentesco se limita a una lista por nombre: 400 `GUARDIANSHIP_RELATIONSHIP_TYPE_NOT_ALLOWED`; ver «Parentesco del tutor»).
>
> - **Compuerta de consentimiento en toda activación de rol de club** (409 `MR_CONSENT_NOT_VERIFIED`): además de `approve`, la aplican `PATCH /club-roles/:assignmentId` (cuyo `status` ahora es un enum cerrado), `POST /clubs/:clubId/sections/:sectionId/{roles,director-assignment,director-succession}`, `POST /requests/{assignments,transfers}/:requestId/review` y `POST /club-sections/:sectionId/annual-continuations` (como `blocked` por usuario). Detalle en «Compuerta de consentimiento en las activaciones de rol» (sección `membership-requests`). Subir una ficha con el consentimiento ya verificado responde 409 `GUARDIANSHIP_CONSENT_ALREADY_VERIFIED`, y verificar tiene reglas de cuatro ojos (`GUARDIANSHIP_GUARDIAN_SELF_VERIFY`, `GUARDIANSHIP_CUSTODIAN_SELF_VERIFY`).
> - **28 códigos de error nuevos** en total (lista por área en cada sección; todos están en `ErrorCode` y en los 4 `errors.json`).
>
> Nada de esto existe en `development` hasta el merge, y sin el header el comportamiento de las rutas existentes no cambia. Los totales de la cabecera no incluyen los 16 endpoints nuevos ni descuentan los 3 retirados. Requiere el bucket privado de R2 `R2_BUCKET_GUARDIANSHIP_EVIDENCE` antes del deploy; mientras no exista, los endpoints de ficha responden 503 `GUARDIANSHIP_EVIDENCE_UNAVAILABLE` y el resto de la API sigue igual (ver la sección `guardianships`). Backend y app de la Fase 2 deben desplegarse juntos: la app anterior sigue llamando a las rutas retiradas del representante legal.

> [!NOTE]
> **Perfiles familiares, Fase 3a** (sacdia-backend, rama `feat/family-profiles-phase3`, Pendiente de merge (PR #531 de sacdia-backend)). Describe el comportamiento **implementado** de la sub-fase 3a (cuentas supervisadas de 13 a 17 años), verificado contra el código de la rama y contra el QA en simulador (`docs/testing/FAMILY-PROFILES-PHASE3A-QA.md`). Los totales de la cabecera tampoco incluyen estos endpoints.
>
> - Nuevos (10): 6 de `guardianships` (`supervised-login` GET, POST, `disable`, `reactivate`, `password`, y `summary`), 3 de la sección `users/me` de supervisión (`POST /users/me/guardian-link-codes`, `GET /users/me/supervision`, `POST /users/me/guardian-links/:guardianshipId/revoke`), y 1 de `post-registration` (`step-3/consent-evidence`).
> - Cambian de contrato: `POST /auth/login` (identificador, bloqueo, `principal`), `GET /auth/me` (`principal`, `family_features`, modo incl. `profile_incomplete`, analítica), `POST /auth/register` (guarda `birthday` y `country_id`; fila de supervisión para 13-17), `POST /auth/update-password` y `POST /auth/verify-email/send` (scope `self:password`), `PATCH /users/:userId` (bloqueo de fecha de nacimiento), `POST /guardianships/me/dependents` (tope de edad = mayoría de edad), `POST /guardianships/link-codes/redeem` (propósito `teen_guardian_link`), `POST /guardianships/:guardianshipId/revoke` y `GET .../deletion-impact` (resultado `pending_guardian`), `GET`/`POST .../membership-requests/...` (compuerta por edad, bloque `consent`, `verify-consent` sobre asignación activa), `GET`/`POST /users/me/legal-acceptance` y `POST /auth/register` (versión legal `2.0.0-family`, solo cuando se apruebe el texto; ver `docs/legal/README.md`) y las rutas existentes que se reetiquetan con scopes de adolescente (la lista exacta la fija el snapshot `acting-scope-metadata.spec.ts`).
> - Detalle en «Cuentas supervisadas de 13 a 17 años (Fase 3a)» (antes de «Resumen por dominio»).

> [!NOTE]
> **Perfiles familiares, Fase 3b** (sacdia-backend, rama `feat/family-profiles-phase3`, dieciséis commits `f31c24cb..1054af7a` sobre `4cf7070f`, Pendiente de merge (PR #531 de sacdia-backend)). Describe el comportamiento **implementado en el backend** de la sub-fase 3b (dispositivo vinculado de menores de 13 años), verificado contra el código de la rama (con referencias a archivo y, donde no se mueven, a línea). La app (tareas A01 a A11) y el QA ya están hechos en la rama (app `41388c13`); el registro del QA vive en `docs/testing/FAMILY-PROFILES-PHASE3B-QA.md`. Sigue pendiente de merge. La sub-fase 3c (barrido por cron y desvinculación desde el panel) ya está implementada; ver «Registro de menores por un director y acceso familiar en el panel (Fase 3c)». Todo queda detrás de `FAMILY_LINKED_DEVICE_ENABLED` (por defecto `false`). Los totales de la cabecera tampoco incluyen estos endpoints.
>
> - Nuevos (4): `POST /auth/device/pair` (público) y, en `guardianships`, `POST .../devices/pairing-tokens`, `GET .../devices` y `POST .../devices/:deviceId/revoke`.
> - Cambian de contrato: `POST /auth/refresh` y `POST /auth/logout` (sesiones de dispositivo), `GET /auth/me` (`mode: "device"` y `principal.device`), `GET /auth/sessions` y `GET /admin/users/:userId/sessions` (campo `kind`), `GET /guardianships/me/dependents` (`limits.max_devices` y `linked_devices_count` real), `POST /users/me/fcm-tokens` (liga el token al dispositivo), `GET /clubs/:clubId/activities` y `GET /activities/:activityId` (sin listas de asistentes para el dispositivo) y las cuatro rutas de evidencia de especialidades, que pasan de `evidence:upload` a `honors:write`.
> - 6 códigos de error nuevos (`AUTH_DEVICE_REVOKED`, `AUTH_DEVICE_SESSION_EXPIRED`, `DEVICE_PAIRING_TOKEN_INVALID`, `DEVICE_PAIRING_NOT_ELIGIBLE`, `DEVICE_LIMIT_REACHED`, `DEVICE_NOT_FOUND`) en `ErrorCode` y en los 4 `errors.json`.
> - Esquema: `docs/database/SCHEMA-REFERENCE.md`, «Dispositivos vinculados (Fase 3b)». Detalle en «Dispositivo vinculado de menores de 13 años (Fase 3b)» (antes de «Resumen por dominio»).

> [!NOTE]
> **Perfiles familiares, Fase 3c** (sacdia-backend, rama `feat/family-profiles-phase3`, Pendiente de merge (PR #531 de sacdia-backend)). Describe el comportamiento **implementado en el backend** de la sub-fase 3c (el director registra menores, verificación independiente del consentimiento, tarjeta de acceso familiar en el panel, cron de cambios de edad). Los totales de la cabecera tampoco incluyen estos endpoints.
>
> - Nuevos (3): `POST /club-sections/:clubSectionId/dependents` (sección `guardianships`), `POST /admin/users/:userId/supervised-login/disable` y `POST /admin/users/:userId/linked-devices/:deviceId/revoke` (sección `admin-users`).
> - Cambian de contrato: `POST .../membership-requests/:assignmentId/verify-consent` (permiso `club_members:approve` **o** `consent:verify`; `approve: true` exige `club_members:approve`), `GET .../membership-requests` (`consent.viewer_can_verify` y `consent.viewer_verify_block`), `GET /admin/users/:userId` (`data.family_access`), el cron de vencimiento de solicitudes (congela al menor en custodia) y los avisos de dispositivo por `majority` y `expired`.
> - Permisos nuevos: `dependents:create` y `consent:verify` (migración de datos `20261022130000_seed_family_permissions`; los coordinadores reciben `consent:verify` aparte, con `20261023120000_grant_consent_verify_to_coordinators`, rama `feat/coordinator-consent-verify`, aplicada en `development`); columna nueva `dependent_profiles.teen_login_nudged_at` (migración `20261022120000_family_director_minors`). 1 código de error nuevo (`MR_APPROVE_PERMISSION_REQUIRED`). Cron nuevo `family-age-transitions`.
> - **Resumen de la Fase 3 completa**: 17 endpoints nuevos (3a: 10, 3b: 4, 3c: 3). Detalle en «Registro de menores por un director y acceso familiar en el panel (Fase 3c)» (antes de «Resumen por dominio»).

> [!NOTE]
> **Seguimientos 2026-10-21** (todos **mergeados en `development`**, sin cambios de esquema): (1) `GET /coordination/me/consent-pending`, la cola del coordinador (sacdia-backend `feat/coordinator-pending-consents`, PR #534); ver «`GET /api/v1/coordination/me/consent-pending`» (dentro de «Registro de menores por un director y acceso familiar en el panel (Fase 3c)», tras «Revisor solo-verificación»). (2) `GET /admin/cron-jobs` y `POST /admin/cron-jobs/:jobName/run` («Ejecutar ahora», sacdia-backend `feat/admin-run-cron-now`, PR #535), y los campos `trigger` y `triggered_by` en `recent[]` de `GET /admin/analytics/cron-runs`; ver «Jobs programados bajo demanda» en la sección `admin`. (3) Cambio de comportamiento sin ruta nueva: la cobertura `ZONE` de un coordinador exige también que el **distrito** esté activo (sacdia-backend `test/coordinator-scope-postgres`, PR #536, commit `eec8e5aa`); ver `docs/canon/runtime-coordination.md`. Los totales de la cabecera no incluyen las 3 rutas nuevas.

## Cómo leer esta referencia

- `Auth`: `JWT` cuando el controller/método declara `JwtAuthGuard`, `AuthGuard` o `ApiBearerAuth`; `Public` cuando no se detecta guard bearer en el controller/método.
- `Roles/Permisos`: combina `@RequirePermissions`, `@GlobalRoles`, `@ClubRoles` y `@Roles` detectados a nivel clase/método. Celda `-` en un endpoint JWT significa `@SkipPermissions` (JWT es el lock: picker post-registro, self-service o superficie `GlobalRoles`).
- Runtime: `PermissionsGuard` es `APP_GUARD` fail-closed. Un handler JWT nuevo sin `@RequirePermissions`, `@SkipPermissions` o `@Public` no queda abierto.
- `Uso`: sale de `@ApiOperation.summary` cuando existe; si no existe, se infiere desde el nombre del handler y el método HTTP.
- `Uso backend`: primeras llamadas a servicios/repositorios inyectados detectadas en el handler. `-` significa que el handler responde inline o usa lógica privada no capturada por esta extracción estática.
- `Source`: controller de origen para verificar el contrato antes de tocar clientes.

## Actuar en nombre de un dependiente (`X-Acting-For`)

> [!NOTE]
> Perfiles familiares (Fase 2), rama `feat/family-profiles` de sacdia-backend, Pendiente de merge (PR #530 de sacdia-backend). Un **dependiente** es un menor sin cuenta propia ni correo (`users.email` null), registrado por un tutor desde `POST /api/v1/guardianships/me/dependents`. Esquema y reglas de datos: `docs/database/SCHEMA-REFERENCE.md`, sección «Perfiles familiares».

### Cómo se pide

- El tutor usa su **propio JWT** y añade `X-Acting-For: <user_id del dependiente>` (UUID). No hay token nuevo ni endpoint de «cambio de perfil».
- Sin el header, nada cambia. Un header repetido o que no sea UUID responde 400 `ACTING_FOR_HEADER_INVALID` (nunca se interpreta como «yo»).
- `@Public` ignora el header: la estrategia JWT no corre en esas rutas.
- La firma, la audiencia y la revocación del JWT se validan siempre sobre el **tutor**. Un token de dispositivo vinculado (audiencia `sacdia:device`, Fase 3b) **no** puede usar este header: con `X-Acting-For` responde 403 `ACTING_FOR_FORBIDDEN` (ver «Dispositivo vinculado de menores de 13 años (Fase 3b)»). Hasta la Fase 3b esa audiencia se rechazaba con 401 `GUARD_JWT_UNAUTHORIZED`; ahora solo se rechaza si el conjunto de claims no es exactamente el de un dispositivo.

### Qué cambia en la petición

`JwtStrategy.validate` **sustituye el principal**: `sub`, `userId` y `user_id` pasan a ser el dependiente, así que todo handler que lee el usuario actual (`/auth/me`, `/users/:userId/...`, QR, notificaciones) ve al menor sin cambios. Además:

| Campo del principal | Valor mientras se actúa |
| --- | --- |
| `kind` | `guardian_acting` (sin header: `user`) |
| `actor_sub` | `user_id` del tutor (sin header: igual a `sub`) |
| `acting_for` | `true` |
| `email` | `null` |
| `scopes` | los del consentimiento (tabla de abajo); `null` = sin restricción en `user` |
| `guardianship_id`, `consent_status` | de la tutoría usada |

El guard de ownership sigue igual: como `sub` es el dependiente, el bypass de dueño (`/users/:userId/...` con `:userId` = el menor) funciona; los scopes solo **restringen** lo que ese bypass permite. Un tutor no gana ningún permiso de club por actuar.

### Cuándo se concede

`ActingForResolver` concede acceso solo si existe una fila de `guardianships` con **todo** esto:

- `guardian_user_id` = quien llama, `is_custodian = false`, `is_test_data = false` y `consent_status` en `pending` o `verified`.
- El tutor está **activo** (`users.active`): un tutor eliminado o desactivado no puede actuar aunque su fila siga ahí.
- El dependiente está `active`, **no tiene fila `account`** y su `dependent_profiles` no está congelado ni purgado.
- Tiene fecha de nacimiento y su edad hoy (zona horaria del país) es **menor que la mayoría de edad** del país.

La mayoría de edad, no los 13 años, es el corte para actuar: el límite de 13 solo se aplica al crear el dependiente. Así un niño que cumple 13 antes de la Fase 3 no queda fuera. En cuanto exista una fila `account` para él, actuar deja de funcionar.

> **Fase 3a** (Pendiente de merge (PR #531 de sacdia-backend)): «tiene `account`» se precisa con el fragmento `GUARDIAN_MANAGED_DEPENDENT`. El tutor **no** actúa mientras el menor tenga un acceso propio **habilitado** (causa de denegación `supervised_login_active`, mismo 403 uniforme) y **vuelve a poder actuar** si el acceso se deshabilita, pero solo cuando el acceso lo habilitó el tutor (`origin = guardian_enabled`); un adolescente que se registró solo (`self_registered`) nunca es «actuable». Ver «Acceso propio del adolescente y resumen».

Cualquier otro caso responde el **mismo** 403 `ACTING_FOR_FORBIDDEN` (sin tutoría, revocada, de otro tutor, custodia o tutor externo, datos de prueba, tutor o dependiente inactivo, dependiente con cuenta, congelado, sin fecha de nacimiento, mayor de edad, token `mfa_pending` o header igual al propio `user_id`), para que no se pueda enumerar quién es dependiente de quién. La causa real solo va al log `acting_for_denied`.

### Scopes (denegado por defecto)

Una ruta es accesible actuando solo si declara `@ActingScope(<scope>)` con un scope que el principal tiene. Sin decorador, o con un scope que no tiene: 403 `ACTING_FOR_SCOPE_DENIED`.

| Consentimiento | Scopes concedidos |
| --- | --- |
| `pending` | `self:read`, `health:read`, `profile:write`, `registration:write`, `legal:accept`, `consent:evidence`, `credential:read`, `club:context` (`GUARDIAN_PENDING_SCOPES`) |
| `verified` | los anteriores más `classes:write`, `evidence:submit`, `honors:write`, `evidence:upload` (`GUARDIAN_VERIFIED_SCOPES`) |

Esta tabla ya incluye lo que añadieron las fases 3a y 3b (`health:read`, `consent:evidence`, `evidence:submit`, `credential:read`, `club:context`); el vocabulario completo y los conjuntos de los otros tipos de principal están en «Scopes de la Fase 3a». El tutor **nunca** recibe los scopes del adolescente ni del dispositivo (`member:*`, `agenda:read`, `push:register`, `self:password`, `self:preferences`, `guardian_link:issue`, `account:manage`).

`pending` alcanza para completar el registro del menor (pasos 1 a 3 del post-registro, que crean la solicitud de club) y aceptar los términos. `verified` añade lo que solo importa después de que el club aprueba. El consentimiento pasa a `verified` cuando un director verifica la ficha firmada (`POST .../membership-requests/:assignmentId/verify-consent`); los scopes se amplían en la **siguiente** petición del tutor, porque la verificación sube el `epoch` del caché. Las filas `revoked`, de custodia, de tutor externo o `is_test_data` no dan ningún scope.

Rutas con scope (64 en la Fase 2; la Fase 3a reetiqueta algunas y suma las del adolescente, ver «Scopes de la Fase 3a» más abajo; la lista exacta la fija el snapshot `src/auth/acting-for/acting-scope-metadata.spec.ts`, así que ampliar lo que un tutor puede hacer es siempre un cambio explícito en review):

| Scope | Rutas (`/api/v1`) |
| --- | --- |
| `self:read` | `GET /auth/me` · `GET /auth/profile/completion-status` · `GET /dashboard/summary` · `GET /users/:userId` · `GET /users/:userId/{allergies,diseases,medicines,age}` · `GET /users/:userId/emergency-contacts[/:contactId]` · `GET /users/:userId/post-registration/{status,photo-status}` · `GET /users/:userId/classes` · `GET /users/:userId/classes/:classId/progress` · `GET /users/:userId/honors` · `GET /users/:userId/honors/stats` · `GET /users/:userId/honors/:honorId/requirements/progress` · `GET /users/:userId/honors/:honorId/requirements/:requirementId/evidence` · `GET /notifications/history` · `GET /notifications/unread-count` · `PATCH /notifications/read-all` · `PATCH /notifications/:deliveryId/read` · `GET /users/me/legal-acceptance` |
| `profile:write` | `PATCH /users/:userId` · `PUT /users/:userId/{allergies,diseases,medicines}` · `DELETE /users/:userId/{allergies/:allergyId,diseases/:diseaseId,medicines/:medicineId}` · `POST` y `DELETE /users/:userId/profile-picture` · `POST /users/:userId/emergency-contacts` · `PATCH` y `DELETE /users/:userId/emergency-contacts/:contactId` |
| `credential:read` | `GET /qr/member/token` · `GET /qr/me` · `GET /qr/me/card` · `GET /qr/me/card.pdf` (antes `self:read`; ver «Scopes de la Fase 3a») |
| `club:context` | `PATCH /auth/me/context` (antes `profile:write`; ver «Scopes de la Fase 3a») |
| `registration:write` | `POST /users/:userId/post-registration/step-{1,2,3}/complete` · `POST /users/:userId/post-registration/membership-request/cancel` · `POST /users/:userId/membership/annual-enroll` · `GET /clubs` · `GET /clubs/:clubId/sections` |
| `classes:write` | `POST /users/:userId/classes/enroll` · `PATCH /users/:userId/classes/:classId/progress` · `POST /users/:userId/classes/:classId/sections/:sectionId/submit` |
| `evidence:upload` | `POST /users/:userId/classes/:classId/sections/:sectionId/files` · `DELETE .../files/:fileId` (`src/classes/classes.controller.ts:331` y `:389`). **Fase 3b**: las cuatro rutas de evidencia de especialidades que antes llevaban este scope pasaron a `honors:write` (fila siguiente) para que el dispositivo vinculado, que tiene `evidence:upload`, no pueda tocarlas; tutores y adolescentes tienen ambos scopes, así que su comportamiento no cambia |
| `honors:write` | `POST /users/:userId/honors` · `POST /users/:userId/honors/bulk` · `POST`, `PATCH` y `DELETE /users/:userId/honors/:honorId` · `PATCH /users/:userId/honors/:honorId/requirements/progress/batch` · `PATCH .../requirements/:requirementId/progress` · (Fase 3b) `POST /users/:userId/honors/:honorId/files` · `POST .../requirements/:requirementId/evidence/{upload,link}` · `DELETE .../evidence/:evidenceId` (`src/honors/honors.controller.ts:247`, `src/honors/honor-requirements.controller.ts:195`, `:238` y `:299`) |
| `legal:accept` | `POST /users/me/legal-acceptance` (el servicio guarda `accepted_by_user_id` = el tutor) |

**Nunca llevan scope** (el spec lo comprueba): `POST /auth/update-password`, `DELETE /auth/me`, `/auth/sessions*`, `/auth/mfa/*`, `/auth/oauth*`, `/users/me/data-export*`, `/fcm-tokens*`, `/users/me/notification-preferences*`, `/notifications/preferences*`, `/guardianships/*` (incluidas las rutas de la ficha de consentimiento del tutor), `POST /club-sections/:clubSectionId/dependents/:userId/claim-codes`, `POST /users/:userId/post-registration/step-3/guardian-only`, `/users/:userId/legal-representative*`, `GET /users/:userId/requires-legal-representative`, solicitud de instructor de especialidad, `/users/:userId/master-honors*`, `/certifications*`, `/admin*`, `/clubs*` (con **dos excepciones**, las lecturas del selector de club del paso 3: `GET /clubs` y `GET /clubs/:clubId/sections`), `/club-sections*`, `POST /qr/validate|scan`, los envíos de notificaciones y `GET /legal/current`. Por eso los endpoints de `guardianships` se llaman **sin** `X-Acting-For`: el tutor administra su familia desde su propio perfil.

**Selector de club del paso 3 actuando** (`GET /clubs` y `GET /clubs/:clubId/sections`, `src/clubs/clubs.controller.ts:75` y `:192`): el paso 3 del post-registro del menor necesita listar clubes y secciones mientras el tutor actúa, así que estas dos lecturas llevan `@ActingScope('registration:write')`. Es `registration:write` y no `self:read` a propósito: el dispositivo vinculado de la Fase 3b tiene `self:read` y `evidence:upload`, y no debe poder explorar clubes (`DEVICE_SCOPES` no incluye `registration:write`); solo un tutor que completa el registro del menor (consentimiento `pending` basta) llega a ellas. **Cualquier otra ruta `/clubs/*` sigue denegada** actuando (403 `ACTING_FOR_SCOPE_DENIED`: `GET /clubs/:clubId`, `.../overview`, `.../leadership`, `.../sections/:sectionId` y `.../members` lo comprueba el e2e, `test/acting-for.e2e-spec.ts:403-417`). Por eso la regla «nunca» del spec de metadatos es ahora una expresión regular con excepción: `/^(?!GET \/clubs$|GET \/clubs\/:clubId\/sections$)[A-Z]+ \/clubs(\/|$)/` (`acting-scope-metadata.spec.ts:263-269`); sin la excepción el spec fallaría al ver estas dos rutas con scope. Sin el header ambas rutas no cambian.

`OptionalJwtAuthGuard` (rutas públicas con sesión opcional, como los catálogos del paso 3): los errores de `X-Acting-For` se propagan y nunca se degradan a anónimo; un principal sustituido en una ruta sin scope se trata como **anónimo** (mínimo privilegio).

### Errores

| Status | `code` | Cuándo |
| --- | --- | --- |
| 400 | `ACTING_FOR_HEADER_INVALID` | Header repetido o que no es UUID |
| 403 | `ACTING_FOR_FORBIDDEN` | Cualquier causa de la lista de arriba (cuerpo uniforme) |
| 403 | `ACTING_FOR_SCOPE_DENIED` | La ruta no declara un scope que el principal tenga |
| 503 | `AUTH_REVOCATION_CHECK_UNAVAILABLE` | Falla la base de datos al resolver la tutoría. Nunca se concede por defecto |

Los guards no convierten estos errores en 401: el JWT del tutor sigue siendo válido, así que el cliente no debe cerrar sesión. **Los clientes no deben leer `details`**: `HttpExceptionFilter` quita `details` de las `AppException` cuando `NODE_ENV=production` (en `ACTING_FOR_SCOPE_DENIED`, `details.required_scope` solo aparece fuera de producción). Basta con el `code`.

### Caché, auditoría y límites de tasa

- **Caché**: la decisión se guarda en Redis con clave `acting:v1:{dependentId}:{epoch}:{guardianId}`: 60 s si se concede, 10 s si se deniega. El `epoch` (`acting:epoch:{dependentId}`) sube tras cada cambio de tutorías (crear dependiente, canjear código, revocar, salida de tutor por cierre de cuenta, purga, verificar consentimiento), de modo que un tutor revocado o recién vinculado se refleja en la **siguiente** petición. El `epoch` también sube al verificar el consentimiento. Si falla Redis se consulta la base; el caché nunca convierte un rechazo en acceso. Un `epoch` que falta (expiró o se vació Redis) cuenta como fallo de caché: el resolver estrena uno nuevo antes de leer la base y nunca lee decisiones antiguas bajo él.
- **Auditoría**: las filas de `audit_logs` escritas mientras se actúa (HTTP o de servicio) llevan `actor_user_id` = tutor, `actor_kind = guardian_acting`, `target_user_id` = dependiente y `request_context.acting_for = { guardian_user_id, dependent_user_id, guardianship_id }`. No hay cambio de schema. Las columnas de dominio (quién subió una evidencia, por ejemplo) siguen registrando al dependiente; el rastro del actor real está en la auditoría. El log de peticiones muestra `tutor>dependiente`. En `legal_acceptances`, `accepted_by_user_id` es el tutor.
- **Rate limit**: `UserAwareThrottlerGuard` cuenta por `actor_sub`, es decir, todo el tráfico del tutor actuando se suma al tutor, no al menor.

## Cuentas supervisadas de 13 a 17 años (Fase 3a)

> [!NOTE]
> Perfiles familiares, Fase 3a, rama `feat/family-profiles-phase3` de sacdia-backend. Pendiente de merge (PR #531 de sacdia-backend).
> Describe el comportamiento **implementado**: cada afirmación se verificó contra el código de la rama (`src/auth`, `src/guardianships`, `src/better-auth`) y contra el QA en simulador y API (`docs/testing/FAMILY-PROFILES-PHASE3A-QA.md`). Esquema: `docs/database/SCHEMA-REFERENCE.md`, sección «Cuentas supervisadas (Fase 3a)». Feature: `docs/features/family-profiles.md`. Texto legal asociado (borrador): `docs/legal/README.md`, «Versión 2.0.0-family».

Antes de la Fase 3a, un adolescente de 13 a 17 años con cuenta propia se trataba como adulto: podía registrarse solo y entrar a un club sin ningún consentimiento. Ahora es un **usuario supervisado**: el servidor lo reconoce por su edad, le limita lo que puede hacer (denegado por defecto) y le da a un tutor poderes de control **solo cuando un director verificó el consentimiento**.

### Quién es un usuario supervisado (`kind: supervised_user`)

`JwtStrategy.validate` resuelve el tipo de principal **en el servidor, en cada petición**, a partir del estado de la base (nunca de un claim del JWT; un claim falso se ignora). Así vale igual para contraseña, inicio de sesión social, refresh y MFA. Corre después de las comprobaciones de revocación y **antes** de leer `X-Acting-For`.

| Condición del usuario | Principal |
| --- | --- |
| Con edad igual o mayor que la mayoría de edad del país | `user` (como siempre) |
| **Sin fecha de nacimiento** (`NULL`) en una cuenta propia con el post-registro abierto (ver abajo) | `age_unknown_user` → scopes `AGE_UNKNOWN_SCOPES` |
| Sin fecha de nacimiento en una cuenta de staff, de admin o heredada (sin fila `users_pr`, post-registro completo, `access_panel`, o un rol global distinto de `user`) | `user` (como siempre). La compuerta de activación **falla cerrada** igual (409; ver `membership-requests`) |
| Con cuenta, menor de la mayoría de edad, **sin** tutoría verificada | `supervised_user`, `supervision: "pending_guardian"` → scopes `TEEN_PENDING_SCOPES` |
| Con cuenta, menor, con una tutoría verificada, no custodia, no `is_test_data` | `supervised_user`, `supervision: "active"` → scopes `TEEN_SCOPES` |
| Acceso deshabilitado por el tutor o un admin, o cuenta congelada | 401 `AUTH_SUPERVISED_ACCESS_REVOKED` |

- **Qué saca del modo pendiente**: solo una tutoría `verified`, de persona (no custodia del club) y real. Una custodia del club, un vínculo `pending` o una tutoría revocada **no** sacan al adolescente del modo pendiente.
- **Principal**: `{ kind: "supervised_user", sub, actor_sub: sub, acting_for: false, scopes, supervision }`. Las filas de `audit_logs` llevan `actor_kind = supervised_user`. Las peticiones sin ese contexto quedan idénticas.
- **Caché**: `supv:v3:{userId}:{epoch}` (`src/auth/supervised/supervised-principal.cache.ts`; la `v2` llegó con el estado `profile_incomplete`, porque una entrada `v1` decía «adulto» para una fecha `NULL`, y la `v3` añade el método de acceso para la bandera `FAMILY_TEEN_LOGIN_ENABLED`; una entrada anterior no se lee nunca; la sesión va aparte en `supv:sid:v1:...`) sobre el mismo `acting:epoch:{userId}` de actuar por un menor. TTL: adulto 1 h, supervisado y edad desconocida 60 s, bloqueado 10 s, **recortado a la próxima medianoche** de la zona horaria del país (la mayoría de edad se aplica sin esperar el TTL). Redis falla → se lee la base; la base falla → 503 `AUTH_REVOCATION_CHECK_UNAVAILABLE`, nunca se concede por defecto.
- **Revocación inmediata**: para un principal supervisado, además se comprueba (con caché ligada al `epoch`) que la sesión `sid` del token siga existiendo. Deshabilitar, restablecer la contraseña, congelar o perder al tutor corta el acceso en la **siguiente** petición aunque el JWT (8 h) siga vigente. Los adultos mantienen su comportamiento actual.
- **`X-Acting-For` con un token de adolescente** → 403 `ACTING_FOR_FORBIDDEN` (uniforme; se registra `cause=supervised_token`). Un adolescente nunca es tutor.

### Edad desconocida (`kind: age_unknown_user`)

Una cuenta propia sin fecha de nacimiento no puede probar que es mayor de edad. Antes se trataba como adulto (por ejemplo, un alta con Google o Apple creaba la cuenta sin fecha y recibía poderes de adulto hasta el paso 2 del post-registro). Ahora queda **restringida** hasta que el paso 2 guarde la fecha.

**Cuándo aplica** (`SupervisedPrincipalResolver`, función `isOnboardingWithUnknownAge`, `src/auth/supervised/supervised-principal.resolver.ts:59`), las cuatro a la vez:

1. `users.birthday` es `NULL`.
2. Existe la fila `users_pr` y `users_pr.complete = false` (post-registro abierto).
3. La cuenta **no** tiene acceso al panel (`access_panel` distinto de `true`).
4. No tiene ningún rol global activo distinto de `user` (`role_category = 'GLOBAL'`, `role_name <> 'user'`).

Las condiciones 3 y 4 existen para que un admin o un miembro del staff que inicia sesión por primera vez con Google, y recibe una fila `users_pr` nueva e incompleta, no pierda el panel. Una cuenta sin fecha que no cumple las cuatro sigue siendo `user`.

**Cómo se sale**: el paso 2 del post-registro guarda la fecha de nacimiento. Con una fecha de adulto la cuenta es `user` de inmediato; con una fecha de menor pasa a `supervised_user`. Guardar la fecha mueve el `epoch` del principal (`UsersService.afterBirthdayChanged`, `src/users/users.service.ts:357`), igual que cualquier cambio de `users_pr.complete` (paso 3, salida `guardian-only`, cancelar la solicitud de membresía, inicio de sesión social de una cuenta existente), así que el cambio se ve en la siguiente petición. El paso 3 se niega con la fecha en `NULL` (400 `POST_REG_PERSONAL_INFO_INCOMPLETE`, `src/post-registration/post-registration.service.ts:185`): una edad desconocida no se vuelve adulta saltándose el paso 2.

**Qué cambia en la respuesta**:

- `GET /auth/me`: `data.mode = "profile_incomplete"`, `data.principal.kind = "age_unknown_user"`, `data.family` y `data.principal.supervision` en `null`, y `data.analytics_anonymous = true` (la app no identifica en PostHog ni Sentry). La app solo puede terminar el post-registro; no muestra nada más.
- `POST /auth/login`: `data.user.principal.kind = "age_unknown_user"` (`AuthService.loginPrincipalOf`, `src/auth/auth.service.ts:518-531`).
- `PRINCIPAL_SCOPE_DENIED` (ver «Errores de denegación y de acceso») puede llevar `kind: "age_unknown_user"`; `supervision` no aplica.
- `X-Acting-For` con un token de edad desconocida → 403 `ACTING_FOR_FORBIDDEN` (uniforme; se registra `cause=age_unknown_token`). Una edad desconocida no es un tutor.

**`AGE_UNKNOWN_SCOPES`** (`src/auth/acting-for/auth-principal.ts`): `self:read`, `health:read`, `profile:write`, `registration:write`, `legal:accept`, `self:password`, `push:register` y `account:manage`. Es la superficie del post-registro (perfil y salud propios, aceptación legal, contraseña, token de push) y nada de club: sin `member:*`, sin `guardian_link:issue`, sin `self:preferences`. Nunca es más ancho que `TEEN_PENDING_SCOPES` salvo por `account:manage`.

**`account:manage`** lo tiene **solo** `AGE_UNKNOWN_SCOPES` (ni el adolescente, ni el tutor actuando, ni el dispositivo). Lo llevan:

| Ruta | Archivo |
| --- | --- |
| `GET /auth/oauth/providers` | `src/auth/oauth.controller.ts:44` |
| `DELETE /auth/me` | `src/auth/auth.controller.ts:591` |
| `GET /auth/sessions`, `DELETE /auth/sessions/:sessionId`, `DELETE /auth/sessions` | `src/auth/sessions.controller.ts:60`, `:87`, `:137` |

Por qué: la regla 5.1.1(v) de la App Store exige que quien puede crear una cuenta en la app pueda **eliminarla** desde la app. Una cuenta de edad desconocida (la que se creó con Google o Apple y todavía no tiene fecha) es la única que no tiene aún un modo normal; si no pudiera eliminarse, el usuario quedaría atrapado. Para eliminar una cuenta social la app debe reautenticar con el proveedor, y para eso necesita saber qué proveedores tiene vinculados: de ahí `GET /auth/oauth/providers` (corregido en `7e9d5156` tras el QA). Las otras rutas de `/auth/oauth*` (vincular y desvincular) siguen sin scope para todos los tipos.

### Scopes de la Fase 3a (denegado por defecto)

El vocabulario crece y los conjuntos son por tipo de principal. Un conjunto no incluye lo que el tipo no necesita; cualquier ruta sin `@ActingScope`, o con un scope que el principal no tiene, se deniega.

| Conjunto | Scopes |
| --- | --- |
| `TEEN_PENDING_SCOPES` (adolescente sin tutor verificado) | `self:read`, `health:read`, `profile:write`, `registration:write`, `legal:accept`, `guardian_link:issue`, `self:password`, `self:preferences`, `push:register` |
| `AGE_UNKNOWN_SCOPES` (edad desconocida, ver arriba) | `self:read`, `health:read`, `profile:write`, `registration:write`, `legal:accept`, `self:password`, `push:register`, `account:manage` |
| `TEEN_SCOPES` (con tutor verificado) | `self:read`, `health:read`, `profile:write`, `registration:write`, `classes:write`, `evidence:submit`, `honors:write`, `evidence:upload`, `legal:accept`, `member:read`, `member:write`, `agenda:read`, `push:register`, `self:password`, `self:preferences`, `credential:read`, `club:context` |
| Tutor actuando, consentimiento `pending` | `self:read`, `health:read`, `profile:write`, `registration:write`, `legal:accept`, `consent:evidence`, `credential:read`, `club:context` |
| Tutor actuando, consentimiento `verified` | los anteriores más `classes:write`, `evidence:submit`, `honors:write`, `evidence:upload` |
| `DEVICE_SCOPES` (dispositivo vinculado, Fase 3b) | `self:read`, `evidence:upload`, `evidence:submit`, `push:register`, `agenda:read`, `credential:read` (ver «Dispositivo vinculado de menores de 13 años (Fase 3b)») |

Cambios sobre la tabla de scopes de la Fase 2 (reetiquetados deliberados; el snapshot `acting-scope-metadata.spec.ts` los fija):

- **`self:read` → `health:read`** en las lecturas de salud y contacto: `GET /users/:userId/{allergies,diseases,medicines}` y `GET /users/:userId/emergency-contacts[/:contactId]`. Un tutor actuando y un adolescente con tutor mantienen acceso porque sus conjuntos incluyen `health:read`.
- **`classes:write` → `evidence:submit`** en `POST /users/:userId/classes/:classId/sections/:sectionId/submit`. Los dos conjuntos con `classes:write` también tienen `evidence:submit`, así que el comportamiento del tutor no cambia.
- **Scopes nuevos** (solo para el tipo que se indica; la lista final la fija el snapshot y `teen-route-walk.spec.ts`, que recorre el registro real de rutas y el seed de permisos del rol `member`):
  - `member:read` (adolescente): lecturas de miembro: `GET /clubs/:clubId`, `.../sections/:sectionId`, `.../leadership`, unidades y registros semanales, mejor miembro del mes, `GET /member-rankings/me`, `GET /activities/:activityId/rsvp` (la intención propia) y `GET /activities/:activityId/attendance`, logros, recursos y categorías de recursos, historial y elegibilidad de validación, solicitudes (lecturas), historial de investidura y categorías de puntuación, más dos lecturas que la pantalla de inicio de miembro pide a todos: `GET /clubs/:clubId/sections/:sectionId/enrollments/current` (inscripción vigente de la propia sección; `src/club-enrollments/club-enrollments.controller.ts:105`, conserva `club_instances:read`) y `GET /camporee-judges/me/assignments` (¿soy juez?: filtra por el usuario del token y a un adolescente le responde `[]`; `src/camporee-scoring/camporee-scoring.controller.ts:348`). Sin ellas el inicio del adolescente activo recibía un 403 por cada una (hallazgo del QA 3a, corregido en `83ffe7cf`). Las rutas de jueces para calificar siguen denegadas.
  - `member:write` (adolescente): `PUT /activities/:activityId/rsvp`, `POST /validation/submit`, `POST` y `DELETE /users/:userId/honors/:honorId/instructor-proposal`.
  - `agenda:read` (adolescente): `GET /clubs/:clubId/activities`, `GET /activities/:activityId`, `GET /activity-series/:seriesId`.
  - `push:register`: `POST /users/me/fcm-tokens` y `DELETE /users/me/fcm-tokens/:tokenId` (los `/fcm-tokens*` heredados siguen sin scope).
  - `self:password`: `POST /auth/update-password` y `POST /auth/verify-email/send`.
  - `self:preferences`: `GET` y `PATCH /users/me/notification-preferences`.
  - `guardian_link:issue`: `POST /users/me/guardian-link-codes` y `POST /users/me/guardian-links/:guardianshipId/revoke` (adolescente en modo pendiente).
  - `consent:evidence` (solo tutor actuando): `POST /users/:userId/post-registration/step-3/consent-evidence`.
  - `credential:read`: la credencial QR de miembro, `GET /qr/me`, `GET /qr/me/card`, `GET /qr/me/card.pdf` y `GET /qr/member/token` (`src/qr/qr.controller.ts:55`, `:77`, `:98`, `:119`; antes `self:read`). La tienen el adolescente **activo**, el tutor actuando (`pending` o `verified`) y el dispositivo vinculado (`TEEN_SCOPES`, `GUARDIAN_PENDING_SCOPES`, `GUARDIAN_VERIFIED_SCOPES` y `DEVICE_SCOPES`, `src/auth/acting-for/auth-principal.ts`). **No** la tienen el adolescente pendiente (`TEEN_PENDING_SCOPES`) ni la edad desconocida (`AGE_UNKNOWN_SCOPES`): reciben 403 `PRINCIPAL_SCOPE_DENIED`, también con una asignación de club activa anterior al despliegue.
  - `club:context`: `PATCH /auth/me/context`, cambiar la asignación de club activa (`src/auth/auth.controller.ts:539`; antes `profile:write`). Mismos titulares que `credential:read` **menos el dispositivo** (`DEVICE_SCOPES` no lo incluye); el adolescente pendiente y la edad desconocida reciben 403 `PRINCIPAL_SCOPE_DENIED`.
- **Salen de la lista «nunca llevan scope»** porque ahora los lleva el adolescente: `POST /auth/update-password`, las preferencias de notificación, la propuesta de instructor de especialidad y las rutas `/clubs*` de lectura de miembro. Siguen sin scope para **todos** los tipos (y por tanto denegadas a cualquier principal no `user`): `/auth/mfa*`, vincular y desvincular proveedores (`/auth/oauth*` salvo `GET /auth/oauth/providers`), exportación de datos, `/fcm-tokens*` heredados, `/guardianships*` (salvo lo que el adolescente usa por `/users/me/...`), representante legal, `/admin*`, `/club-sections*` y los envíos de notificaciones. Un adolescente con acceso por nombre de usuario tampoco puede agregar correo ni vincular un proveedor social (403). **Eliminar cuenta (`DELETE /auth/me`), `/auth/sessions*` y `GET /auth/oauth/providers` llevan `account:manage`**, que solo tiene la edad desconocida (ver «Edad desconocida»); un adolescente, un tutor actuando y un dispositivo reciben 403 en ellas.
- **Rutas que el adolescente no alcanza aunque el RBAC se lo permita** (`TEEN_DENIED`, cada una con motivo en el spec): `POST /requests/transfers` (el tutor gestiona cambios de club), vistas de progreso para staff, `.../overview` e historial del club, `/users/:userId/master-honors*`, catálogos de `/admin/*` y camporees. Un adolescente con un rol de club de staff solo recibe la superficie de miembro (limitación documentada).

### Sin datos de club ni credencial hasta que haya un tutor verificado

> Decisión de producto (opción A, hallazgos FP3-03 y FP3-07 de la verificación 3a; backend `58669c63`, `cce8c687`, `be1456f6`).

**Regla**: un adolescente sin tutoría verificada (`supervised_user` con `supervision: "pending_guardian"`, o con `supervision` ausente) y una cuenta de edad desconocida **no ven datos de club ni tienen credencial de miembro**, aunque su asignación de club ya estuviera `active` antes del despliegue. La Fase 3a no hace excepción por antigüedad: mientras ningún tutor tenga el consentimiento verificado, el servidor no revela el club ni emite la credencial QR.

**Por qué**: la regla de la Fase 3a es que el consentimiento de un tutor se verifica antes de que un menor de 18 años participe en un club. Dejar pasar a los que ya estaban dentro habría mantenido abierto, para exactamente la población que ya está expuesta, el hueco que esta fase cierra. Una credencial QR vigente además se escanea en actividades de club y acredita pertenencia.

**Cómo se aplica** (una sola función decide, `principalSeesClubData`, `src/auth/acting-for/auth-principal.ts:206`): devuelve `false` para `age_unknown_user` y para `supervised_user` cuya `supervision` no es `active`; para cualquier otro tipo (`user`, `guardian_acting`, `linked_device`) devuelve `true` y no cambia nada. Por eso un `supervised_user` sin estado de supervisión falla cerrado.

| Ruta | Para un principal sin datos de club |
| --- | --- |
| `GET /qr/me`, `/qr/me/card`, `/qr/me/card.pdf`, `/qr/member/token` | 403 `PRINCIPAL_SCOPE_DENIED` (falta `credential:read`) |
| `PATCH /auth/me/context` | 403 `PRINCIPAL_SCOPE_DENIED` (falta `club:context`) |
| `GET /auth/me` | 200, sin contexto de club (ver debajo) |
| `GET /dashboard/summary` | 200, sin datos de club (ver sección `dashboard`) |

**`GET /auth/me` sin contexto de club** (`AuthService.getProfile` llama a `stripClubContext`, `src/auth/auth.service.ts:930-935`; `src/auth/acting-for/strip-club-context.ts`). La forma de la respuesta no cambia (listas vacías y `null`, nunca un bloque ausente), pero:

- `data.authorization.grants.club_assignments` es `[]`;
- `data.authorization.active_assignment.assignment_id` es `null`;
- `data.authorization.effective.scope.club` es `null`;
- `data.authorization.effective.permissions` solo lleva los permisos de los roles globales y los directos, sin los que aportaba el rol de club;
- `data.club` es `null` y `data.club_context` queda vacío (`active_assignment_id: null`, `active: null`, `available: []`);
- los roles globales, los permisos directos y el perfil no cambian. La función es pura: no modifica la entrada del caché de autorización compartido.

**Impacto en producción**: los miembros de 13 a 17 años con una asignación `active` anterior al despliegue pasan a este modo en su **primera petición** posterior: pierden la credencial QR, el cambio de contexto y el nombre del club en el inicio hasta que un tutor quede vinculado y verificado. Antes de desplegar conviene avisar a los directores y a las familias afectadas.

**Salida**: el adolescente emite su código de vínculo (`POST /users/me/guardian-link-codes`), un adulto lo canjea, sube la ficha firmada y **el director verifica el consentimiento sobre la asignación que ya está `active`** (`POST .../membership-requests/:assignmentId/verify-consent`; ver «Fase 3a — verificar sobre una asignación ya `active`» en `membership-requests`). La verificación sube el `epoch` y en la siguiente petición el adolescente pasa a `TEEN_SCOPES` y recupera el club y la credencial.

**Limitación conocida**: un token QR de miembro emitido **antes** de que el adolescente pasara a pendiente (TTL de 24 h) sigue validándose en un escaneo (`POST /qr/validate|scan`) hasta que caduca. El escaneo no vuelve a evaluar al portador y el cierre cuando el adolescente queda pendiente solo impide emitir tokens nuevos. Residual aceptado, acotado por el TTL.

### Errores de denegación y de acceso

| Status | `code` | Cuándo |
| --- | --- | --- |
| 403 | `PRINCIPAL_SCOPE_DENIED` | Un `supervised_user`, un `age_unknown_user` o un `linked_device` llama a una ruta sin el scope requerido. Es lo que recibe un adolescente pendiente o una edad desconocida en la credencial QR (`credential:read`) y en `PATCH /auth/me/context` (`club:context`). Lleva `{ required_scope, kind, supervision }` (en producción solo el `code`); `kind` puede ser `supervised_user`, `age_unknown_user` o `linked_device`, y `supervision` solo existe para el primero. También lo devuelve `POST /users/me/guardian-link-codes` a un adulto (`kind: "user"`; ver «supervision»). Nunca provoca la salida del modo actuar de la app |
| 403 | `ACTING_FOR_SCOPE_DENIED` | Igual que en la Fase 2, **solo** para `guardian_acting` |
| 403 | `ACTING_FOR_FORBIDDEN` | `X-Acting-For` en un token de adolescente o de edad desconocida |
| 401 | `AUTH_SUPERVISED_ACCESS_REVOKED` | Token de un adolescente cuyo acceso se deshabilitó, se restableció, se congeló o perdió a su tutor |
| 403 | `AUTH_SUPERVISED_LOGIN_DISABLED` | **Inicio de sesión** con credenciales correctas de un acceso deshabilitado (solo se revela con la contraseña correcta) |
| 403 | `AUTH_ACCOUNT_FROZEN` | Inicio de sesión con credenciales correctas de una cuenta congelada por el plazo de 90 días sin tutor |
| 429 | `AUTH_LOGIN_LOCKED` | Bloqueo por intentos fallidos. La espera va **solo** en la cabecera `Retry-After` (segundos); el cuerpo no lleva `details` (el filtro mueve `retry_after_seconds` a la cabecera, `src/common/filters/http-exception.filter.ts:90-99`). Los clientes leen la cabecera |
| 422 | `USER_BIRTHDAY_CHANGE_REQUIRES_GUARDIAN` | Un adolescente intenta cambiar su propia fecha de nacimiento |
| 422 | `SUPERVISED_LOGIN_NOT_ELIGIBLE` | Habilitar o reactivar un acceso fuera de edad o sin cumplir una precondición; `details.reason` (`age_below_min`, `age_over_majority`, `consent_not_verified`, `feature_disabled`, `custodian_only`) |
| 409 | `SUPERVISED_LOGIN_ALREADY_ENABLED` | Habilitar dos veces |
| 404 | `SUPERVISED_LOGIN_NOT_FOUND` | Deshabilitar o restablecer sin un acceso |
| 409 | `SUPERVISED_LOGIN_EMAIL_UNAVAILABLE` | El correo elegido ya existe |
| 422 | `SUPERVISED_LOGIN_PASSWORD_INVALID` | La contraseña no cumple la política de registro |
| 403 | `GUARDIANSHIP_CONSENT_NOT_VERIFIED` | Un tutor con vínculo `pending` usa un poder de control: habilitar, deshabilitar, reactivar o restablecer el acceso (`GuardianPowersPolicy`, `src/guardianships/guardian-powers.policy.ts:68-74`) |
| 409 | `GUARDIANSHIP_CONSENT_NOT_VERIFIED` | Un tutor con vínculo `pending` pide el resumen (mismo código, otro status). `GET .../supervised-login` **no** da error: responde 200 con `ineligible_reason: "consent_not_verified"` |
| 404 | `FAMILY_FEATURE_DISABLED` | Bandera apagada (ver «Banderas») |

Todos están en `ErrorCode` y en los 4 `errors.json` del backend y en las 4 traducciones de la app.

### Inicio de sesión por identificador

`POST /api/v1/auth/login` acepta `{ "identifier": "ana-7kq4m9m3" | "x@y.com", "password": "..." }`. El campo `email` heredado sigue funcionando (apps anteriores); mandar los dos o ninguno → 400.

- `identifier`: 3 a 254 caracteres, recortado. Si contiene `@` es un correo; si no, es un **nombre de usuario** (minúsculas, insensible a mayúsculas). Un valor de 10 000 caracteres → 400 antes de tocar la base.
- **Respuesta uniforme y tiempo uniforme**: identificador desconocido, contraseña incorrecta, cuenta sin credencial, acceso deshabilitado (con contraseña incorrecta) y bandera apagada devuelven el mismo 401 `AUTH_INVALID_CREDENTIALS`, y la ruta del «no existe» ejecuta una comparación bcrypt con un hash ficticio. Esto también corrige el canal de tiempo que existía para correos desconocidos.
- Con la **contraseña correcta**: acceso deshabilitado → 403 `AUTH_SUPERVISED_LOGIN_DISABLED`; cuenta congelada → 403 `AUTH_ACCOUNT_FROZEN`.
- `data.user.principal` (`kind`, `supervision`) se agrega a la respuesta 200; el resto del contrato no cambia (JWT de acceso de 8 h, sesión de 7 días deslizantes).
- **Bloqueo progresivo** (Redis): 5 fallos por identificador en 15 min → bloqueo de 15 min, que se duplica con cada repetición hasta 24 h; 30 fallos por IP en 15 min → bloqueo. Mientras dura, 429 `AUTH_LOGIN_LOCKED` incluso con la contraseña correcta, y no reinicia el contador. La respuesta es idéntica para identificadores que no existen. Si Redis no responde se aplica un límite en proceso conservador (nunca se queda sin límite). Se mantiene el throttle de 5 por minuto del endpoint. Un atacante puede bloquear 15 min un identificador conocido (costo aceptado).
- **Logs**: `identifier` y `password` se redactan; el nombre de usuario nunca sale en errores ni en logs.
- `POST /api/v1/auth/password/reset-request` sigue siendo solo por correo: con un nombre de usuario devuelve la respuesta neutral y **no** encola ningún correo. Un adolescente con nombre de usuario recupera su acceso a través del tutor.

**Nombre de usuario** (login handle): lo genera el servidor al habilitar el acceso, `{primer nombre, hasta 20 caracteres}-{8 caracteres Crockford base32}` (40 bits), con forma `^[a-z0-9][a-z0-9-]{5,39}$`, único sin distinguir mayúsculas y que no choca con ningún correo. El tutor no puede elegirlo. Solo lo ven los tutores verificados y el propio adolescente; nunca aparece en búsquedas, listas de miembros, tarjeta QR, notificaciones, exportaciones de auditoría ni payloads públicos.

### Banderas de configuración

Tres variables booleanas en `config/env.validation.ts` (por defecto `false`; `src/config/env.validation.ts:237-` y `src/guardianships/family-feature-flags.service.ts`):

| Variable | Qué apaga | Fase |
| --- | --- | --- |
| `FAMILY_TEEN_LOGIN_ENABLED` | Los endpoints de `supervised-login` (habilitar, deshabilitar, reactivar, restablecer y el `GET`; apagada → 404 `FAMILY_FEATURE_DISABLED`, `SupervisedLoginsService`) y el **inicio de sesión** por nombre de usuario (401 uniforme `AUTH_INVALID_CREDENTIALS`, `src/better-auth/better-auth.service.ts:369`). Las sesiones de nombre de usuario ya abiertas dan 401 `AUTH_SUPERVISED_ACCESS_REVOKED` en su siguiente petición y el refresh se rechaza (ver debajo) | 3a |
| `FAMILY_LINKED_DEVICE_ENABLED` | Dispositivo vinculado de menores de 13 años: crear el token QR (apagada → 404 `FAMILY_FEATURE_DISABLED`), canjearlo (400 uniforme `DEVICE_PAIRING_TOKEN_INVALID`) y **autenticar** con un token de dispositivo (401 `AUTH_DEVICE_REVOKED` en cada petición y en el refresh, sin cambiar datos). Listar y desvincular dispositivos no dependen de la bandera. Ver «Dispositivo vinculado de menores de 13 años (Fase 3b)» | 3b |
| `FAMILY_DIRECTOR_CREATE_MINOR_ENABLED` | Registro de menores por un director: `POST /club-sections/:clubSectionId/dependents` (apagada → 404 `FAMILY_FEATURE_DISABLED`, después de los guards). No afecta a lo ya creado ni a la verificación, el reclamo o el vencimiento. Ver «Registro de menores por un director y acceso familiar en el panel (Fase 3c)» | 3c |

**Apagar `FAMILY_TEEN_LOGIN_ENABLED` corta las sesiones de nombre de usuario ya abiertas** (hallazgo C1 de la verificación 3a, FP3-35; backend `035c633f`):

- `SupervisedPrincipalResolver` guarda el método de acceso (`supervised_logins.method`) en el estado cacheado y aplica la bandera **en cada llamada**, encima del estado cacheado (`applyTeenLoginFlag`, `src/auth/supervised/supervised-principal.resolver.ts`). Una cuenta con `method = 'handle'` se resuelve como `blocked` con causa `teen_login_disabled`.
- Resultado: con un token de esa cuenta, la siguiente petición es 401 `AUTH_SUPERVISED_ACCESS_REVOKED` (la estrategia JWT trata cualquier `blocked` igual), y `POST /auth/refresh` también lo rechaza con el mismo 401 (`AuthService.refreshSession`, `src/auth/auth.service.ts:619`), de modo que la sesión no se desliza. Un inicio de sesión nuevo da el 401 uniforme `AUTH_INVALID_CREDENTIALS`.
- Aplica también a un adulto que todavía inicia sesión con nombre de usuario. **No** toca a los adolescentes con acceso por correo.
- Las sesiones **no se borran**: el corte es perezoso, así que volver a encender la bandera las restaura sin tocar la base. Para cortar un acceso concreto de forma definitiva, `.../supervised-login/disable` sí borra las sesiones.
- La bandera no necesita subir el `epoch`: se lee por petición, no se guarda en la caché (clave `supv:v3`, ver «Quién es un usuario supervisado»).
- **Cambiar la bandera exige reiniciar el servidor desplegado**: `FamilyFeatureFlagsService` llama a `ConfigService.get` en cada petición, pero `ConfigService` resuelve primero el valor validado por Joi en el arranque (`ConfigModule.forRoot({ validationSchema })`, `src/app.module.ts:93-99`) y solo después `process.env`. Esa lectura es una **foto del entorno al arrancar el proceso**: cambiar la variable en el panel de la plataforma no surte efecto hasta el siguiente reinicio o redespliegue. «Por petición» significa que no hay otro caché de por medio, no que se relea el entorno. Lo mismo vale para `FAMILY_LINKED_DEVICE_ENABLED` y `FAMILY_DIRECTOR_CREATE_MINOR_ENABLED`. Para cortar sesiones de nombre de usuario en una emergencia: apagar la bandera **y reiniciar**.

**Enlace obligatorio `SUPERVISED_LOGIN_EVENTS`** (backend `c8d3590b`, FP3-23): los avisos de seguridad al tutor dependen del token de inyección `SUPERVISED_LOGIN_EVENTS`, que `GuardianshipsModule` enlaza a `GuardianSecurityNotificationsService` (`src/guardianships/guardianships.module.ts:68`). Los cuatro consumidores (`AuthService`, `LoginFailureCounter`, `SocialSignInService`, `LinkCodesService`) ya **no** lo inyectan con `@Optional()`: si el enlace falta, el servidor **no arranca** (error de arranque de Nest). Antes arrancaba sin él y todos los avisos al tutor se volvían una no-operación silenciosa. Es un cambio de despliegue: quien componga el módulo a mano (pruebas, scripts) debe enlazar el token, o `NOOP_SUPERVISED_LOGIN_EVENTS` si no le importan los avisos.

**No tienen bandera** (cerrar el hueco nunca es opcional): la compuerta de consentimiento por edad, el modo pendiente de tutor, el principal `supervised_user`, los códigos de vinculación del adolescente, los avisos de seguridad, el resumen del tutor, la subida de ficha actuando, los crones y el inicio de sesión de adolescentes con correo. `GET /auth/me` expone las tres banderas en `family_features`.

### Avisos de seguridad al tutor (`family:security`)

- **Eventos**: nuevo inicio de sesión de un adolescente (por contraseña o inicio social; el refresh no avisa), cambio de contraseña por el adolescente (solo tras la contraseña actual correcta), restablecimiento de contraseña por un tutor (a los **otros** tutores) o por correo, acceso habilitado o deshabilitado (a los otros tutores), bloqueo por intentos fallidos (una vez por episodio), y vínculo de un tutor nuevo (al **adolescente**, con el vínculo pendiente de verificación).
- **Destinatarios**: tutores activos, no de prueba, no custodia y con tutoría **verificada** (máximo 4), menos quien actúa. Un vínculo pendiente no recibe avisos.
- **Canal**: push y bandeja, nunca correo (tope de 90 correos al día de Resend). El título lleva el primer nombre del menor; el cuerpo **nunca** lleva contraseña, nombre de usuario, IP ni tokens. Aviso de nueva sesión deduplicado en ventanas de 15 min. Es de mejor esfuerzo: nunca falla ni retrasa el inicio de sesión que lo origina.
- **No se pueden silenciar**: `family:security` se agrega al conjunto de fuentes obligatorias (`MANDATORY_SOURCE_PREFIXES = ['admin','family:security']`) y mapea a la categoría `approvals`. Fuentes nuevas de la categoría `reminders`: `family:teen_reminder` (recordatorios al adolescente) y `family:age_nudge` (Fase 3c).
- **Copias de pushes del club**: un adolescente con acceso propio **no** genera copias para sus tutores (`DependentPushRouter` solo copia a dependientes sin cuenta o con acceso deshabilitado por el tutor). Las subidas de evidencia del adolescente no avisan al tutor (el resumen cubre el seguimiento).

### Plazo de 90 días sin tutor

Un adolescente con cuenta y sin tutoría activa de persona (un vínculo `pending` cuenta como vinculado) tiene un reloj que arranca en la **primera evaluación** tras el despliegue, al revocarse el último tutor o al revocar el adolescente su vínculo pendiente.

Cron `pending-teen-guardian` (`40 4 * * *` UTC, candado `cron:pending-teen-guardian` de 23 h, lotes de 100): recordatorio al adolescente (push y bandeja, nunca correo) a los **7, 30 y 83 días** (solo el último vencido, una vez cada uno); a los **90 días** congela la cuenta en una transacción (`dependent_profiles.frozen_at = now`, `purge_after = now + 90 días`, `supervised_logins.disabled_reason = 'unlinked_purged'`, sesiones borradas, tokens a la lista negra). El cron `dependent-profiles-purge` existente lo elimina y anonimiza 90 días después y ahora también borra credencial y filas `account` (OAuth), `verification`, sesiones y tokens FCM, y deja el correo libre para reutilizarse. Alcanzar la mayoría de edad lo excluye del reloj.

Cuando sale el último tutor de un adolescente **con cuenta**, el resultado `dependent_outcome` es `pending_guardian` (no se congela): vuelve al modo pendiente en su siguiente petición y el reloj reinicia. Con asignación de club activa o pendiente se crea además la custodia del club (`club_custody`) y sigue en modo pendiente. Los dependientes sin cuenta mantienen `frozen`.

## Dispositivo vinculado de menores de 13 años (Fase 3b)

> [!NOTE]
> Perfiles familiares, Fase 3b, rama `feat/family-profiles-phase3` de sacdia-backend (dieciséis commits `f31c24cb..1054af7a`). Pendiente de merge (PR #531 de sacdia-backend).
> Describe el comportamiento **implementado en el backend**; las referencias `archivo:línea` son de la rama en el commit `1054af7a` y se desvían con cualquier edición: la referencia estable es el archivo y la función. La app de la Fase 3b (commit `41388c13`) y el QA en vivo ya están hechos; resultados en `docs/testing/FAMILY-PROFILES-PHASE3B-QA.md`. Esquema: `docs/database/SCHEMA-REFERENCE.md`, «Dispositivos vinculados (Fase 3b)». Resumen para quien toque los guards: `src/common/guards/README.md`.

Un **dispositivo vinculado** es el teléfono de un menor de 13 años (sin cuenta, sin correo, sin contraseña) que un tutor verificado enlaza con un QR de un solo uso. El teléfono recibe una sesión propia y un JWT de **audiencia distinta** (`sacdia:device`); el servidor lo trata como un tipo de principal más (`linked_device`) con una superficie mínima. Todo depende de la bandera `FAMILY_LINKED_DEVICE_ENABLED` (por defecto `false`; ver «Banderas de configuración»).

### Principal `linked_device` y token de dispositivo

- **JWT**: HS256 con `BETTER_AUTH_SECRET`, `iss = https://api.sacdia.app`, `aud` **exactamente** la cadena `sacdia:device` (`DEVICE_AUDIENCE`, `src/common/constants/jwt-audiences.ts:20`), vigencia **1 hora** (`DEVICE_JWT_TTL`, `src/better-auth/better-auth.service.ts:105`) y claims `sub` (el menor), `sid` (la sesión del dispositivo), `dev` (el `linked_device_id`) y `jti` aleatorio (`signDeviceJwt`, `:1232`; sin él, dos tokens firmados en el mismo segundo serían la misma cadena y el refresh pone en lista negra el token presentado). No lleva correo ni `mfa_pending`. Lo que el dispositivo puede hacer **nunca** va en el token.
- **Verificación**: la estrategia JWT acepta las audiencias `sacdia:access` y `sacdia:device` (`ACCEPTED_BEARER_AUDIENCES`, `jwt-audiences.ts:23`) y `validate` las distingue por el conjunto de claims (`isDeviceJwtClaims`, `:70`). Un token con **las dos** audiencias o con la audiencia de dispositivo como arreglo (aunque sea `["sacdia:device"]`) responde 401 `GUARD_JWT_UNAUTHORIZED`. Un `dev` falso en un token de acceso se ignora. El principal se arma desde la base, no desde los claims.
- **Orden de `JwtStrategy.validateDeviceToken`** (`src/auth/strategies/jwt.strategy.ts:283`): conjunto de claims → bandera apagada (401 `AUTH_DEVICE_REVOKED`, `:301`) → `sub`, `sid` y `dev` presentes y `sub`/`dev` UUID (si no, 401 `GUARD_JWT_UNAUTHORIZED`, `:318`) → lista negra de tokens → header `X-Acting-For` → compuerta del dispositivo (`:350`).
- **`X-Acting-For` con un token de dispositivo** (cualquier valor) → 403 `ACTING_FOR_FORBIDDEN` (uniforme; se registra `cause=device_token`, `jwt.strategy.ts:331`). Un dispositivo nunca actúa por nadie.
- **Principal resultante**: `{ kind: "linked_device", sub = actor_sub = el menor, acting_for: false, email: null, mfa_pending: false, sid, scopes: DEVICE_SCOPES, guardianship_id, linked_device_id }` (`jwt.strategy.ts:366-379`). `UserAwareThrottlerGuard` también acepta el token y cuenta por `user:{dependentId}`, no por IP (`src/config/user-aware-throttler.guard.ts`).
- **Registro y auditoría**: el log de peticiones muestra `device:<linked_device_id>` (nunca el id del menor; `src/audit-logs/http-audit.interceptor.ts`); las filas de `audit_logs` llevan `actor_kind = linked_device`, actor = el menor y `request_context.linked_device_id`. `pairing_token` y `qr_payload` se redactan en pino (`src/app.module.ts`), en Sentry (`src/common/interceptors/sentry.interceptor.ts`) y en el filtro de excepciones (`src/common/filters/http-exception.filter.ts`).

### Compuerta por petición (`LinkedDeviceGate`)

Un JWT de dispositivo vive una hora; lo que corta el acceso en la **siguiente** petición es esta compuerta (`src/auth/device/linked-device.gate.ts`, `assertActive` en `:127`). Revisa, en este orden (`loadFromDatabase`, `:220`):

| # | Condición que falla | Respuesta | Motivo que se registra en la fila |
| --- | --- | --- | --- |
| 0 | Bandera `FAMILY_LINKED_DEVICE_ENABLED` apagada (se lee cada vez, sin caché) | 401 `AUTH_DEVICE_REVOKED` | ninguno (no cambia datos) |
| 1 | No hay fila `linked_devices` con ese id, ese menor y esa `sid` | 401 `AUTH_DEVICE_REVOKED` | ninguno |
| 2 | La fila está revocada | 401 `AUTH_DEVICE_REVOKED` | ninguno (ya lo tiene) |
| 3 | `absolute_expires_at` pasó (tope de 180 días desde el emparejamiento) | 401 `AUTH_DEVICE_SESSION_EXPIRED` | `expired` |
| 4 | La sesión no existe, venció o es de otro usuario | 401 `AUTH_DEVICE_REVOKED` | `session_revoked` |
| 5 | El menor está inactivo | 401 `AUTH_DEVICE_REVOKED` | `dependent_frozen` |
| 6 | El menor está congelado o purgado | 401 `AUTH_DEVICE_REVOKED` | `dependent_frozen` |
| 7 | El menor tiene un acceso propio **habilitado** (`supervised_logins` con `disabled_at` nulo) | 401 `AUTH_DEVICE_REVOKED` | `teen_login_enabled` |
| 8 | Sin fecha de nacimiento, o edad igual o mayor que la mayoría de edad del país (zona horaria del país) | 401 `AUTH_DEVICE_REVOKED` | `majority` |
| 9 | La tutoría con que se emparejó ya no es `verified`, es de custodia o de prueba, está revocada o no tiene tutor | 401 `AUTH_DEVICE_REVOKED` | `guardianship_revoked` |

- **Cumplir 13 años no desvincula**: la compuerta no mira la edad mínima de acceso propio, solo la mayoría de edad; esa edad se exige únicamente para **vincular** teléfonos nuevos (token y canje). Un dispositivo ya vinculado sigue funcionando después de los 13 hasta la mayoría de edad, hasta que se habilite el acceso propio o hasta que se desvincule (comprobado por el e2e `test/linked-devices.e2e-spec.ts`, caso «the child turning 13 does NOT revoke an existing device»).
- **Motivo registrado sin esperar**: una causa de ciclo de vida (filas 3 a 9) dispara una revocación sin esperar la respuesta (`autoRevoke`, `:339`), para que la fila diga por qué. Esas revocaciones **no avisan** al tutor. Si la revocación falla, la petición igual responde 401.
- **Caché**: clave `device:v1:{dependentId}:{epoch}:{deviceId}` sobre el **mismo** `epoch` de acting-for (`acting:epoch:{dependentId}`). Decisión positiva 30 s, negativa 10 s (`DEVICE_GATE_ACTIVE_TTL_MS = 30000`, `:24`), recortada al tope absoluto, a la expiración de la sesión y a la medianoche local del menor. Revocar borra la sesión y sube el `epoch`, así que la entrada deja de leerse y la siguiente petición va a la base. Un `epoch` ausente cuenta como fallo de caché.
- **Fallas**: Redis falla → se consulta la base; la base falla → 503 `AUTH_REVOCATION_CHECK_UNAVAILABLE`. Nunca se concede por defecto.
- **`last_seen_at`** se escribe como máximo una vez cada 5 minutos por dispositivo (`DEVICE_LAST_SEEN_INTERVAL_MS`, `:27`); un fallo de esa escritura nunca falla la petición.
- `JwtAuthGuard` relanza los dos códigos `AUTH_DEVICE_*` sin convertirlos en el 401 genérico (`src/common/guards/jwt-auth.guard.ts`), para que la app distinga «este dispositivo fue desvinculado» de un token vencido.

### `DEVICE_SCOPES` y superficie alcanzable

`DEVICE_SCOPES` (`src/auth/acting-for/auth-principal.ts`): `self:read`, `evidence:upload`, `evidence:submit`, `push:register`, `agenda:read`, `credential:read`. **No** tiene `health:read`, `profile:write`, `registration:write`, `classes:write`, `honors:write`, `legal:accept`, `club:context`, `member:read`, `member:write`, `self:password`, `self:preferences`, `guardian_link:issue`, `consent:evidence` ni `account:manage`. El conjunto de la Fase 2 (`LINKED_DEVICE_SCOPES`) quedó reemplazado.

El snapshot `acting-scope-metadata.spec.ts` fija la superficie ruta por ruta (`DEVICE_SURFACE`, 31 rutas) y falla si una ruta nueva con `self:read` aparece sin revisión. Un scope es **necesario, no suficiente**: el RBAC y la propiedad del recurso (`:userId` = el menor) se siguen aplicando como en cualquier petición.

| Grupo | Rutas (`/api/v1`) |
| --- | --- |
| Lecturas propias (`self:read`) | `GET /auth/me` · `GET /auth/profile/completion-status` · `GET /dashboard/summary` · `GET /notifications/history` · `GET /notifications/unread-count` · `PATCH /notifications/read-all` · `PATCH /notifications/:deliveryId/read` · `GET /users/:userId` · `GET /users/:userId/age` · `GET /users/:userId/post-registration/{status,photo-status}` · `GET /users/:userId/classes` · `GET /users/:userId/classes/:classId/progress` · `GET /users/:userId/honors` · `GET /users/:userId/honors/stats` · `GET /users/:userId/honors/:honorId/requirements/progress` · `GET /users/:userId/honors/:honorId/requirements/:requirementId/evidence` · `GET /users/me/legal-acceptance` · `GET /users/me/supervision` (para un dispositivo responde `status: null`: la ruta solo devuelve datos a un `supervised_user`) |
| Evidencia de clases | `POST /users/:userId/classes/:classId/sections/:sectionId/files` (`evidence:upload`) · `DELETE .../files/:fileId` (`evidence:upload`) · `POST .../sections/:sectionId/submit` (`evidence:submit`, enviar a validación) |
| Agenda **sin asistentes** (`agenda:read`) | `GET /clubs/:clubId/activities` · `GET /activities/:activityId` · `GET /activity-series/:seriesId` |
| Push propio (`push:register`) | `POST /users/me/fcm-tokens` · `DELETE /users/me/fcm-tokens/:tokenId` |
| Credencial QR (`credential:read`) | `GET /qr/member/token` · `GET /qr/me` · `GET /qr/me/card` · `GET /qr/me/card.pdf` |

- **Agenda sin asistentes**: para un `linked_device`, las respuestas de `GET /clubs/:clubId/activities` y `GET /activities/:activityId` salen sin `attendees` (ids de usuario), `rsvp` (id de usuario a intención) ni `attendee_profiles` (nombres y avatares); el resto del payload no cambia (`withoutMemberLists`, `src/activities/activities.service.ts:60`, usado en `:222` y `:255`; el controlador lo activa con `req.user.kind === 'linked_device'`, `src/activities/activities.controller.ts:121` y `:286`). `GET /activity-series/:seriesId` no cambia: su payload ya solo lleva conteos.
- **Evidencia de especialidades**: el dispositivo **no** puede subir, enlazar ni borrar evidencia de especialidades. Esas cuatro rutas pasaron de `evidence:upload` a `honors:write` (ver la tabla de scopes de la Fase 2), que el dispositivo no tiene.
- **`GET /users/:userId` sin tipo de sangre**: para un `linked_device` la respuesta omite `blood` (commit `1054af7a`; `UsersController.findOne` pasa `withoutHealth` cuando `req.user.kind === 'linked_device'` y `UsersService.findOne` quita la columna del `select`). El dispositivo tiene `self:read` pero no `health:read`, así que no recibe ningún dato de salud; el resto de la ficha no cambia, y para el tutor actuando y el adolescente `blood` sigue presente.
- **Datos de club**: `principalSeesClubData` devuelve `true` para `linked_device` (`auth-principal.ts`), así que `GET /auth/me` y `GET /dashboard/summary` incluyen el club de su menor. No tiene `club:context`: `PATCH /auth/me/context` responde 403 `PRINCIPAL_SCOPE_DENIED` con `kind: "linked_device"`.
- **Todo lo demás** responde 403 `PRINCIPAL_SCOPE_DENIED` (`kind: "linked_device"`): salud y contactos de emergencia, edición de perfil, registro, legal (aceptar), contraseña, sesiones, eliminar cuenta, `/guardianships*`, preferencias de notificación, `/fcm-tokens*` heredados, exploración de clubes, escrituras de especialidades y clases (salvo la evidencia de arriba) y `/admin*`.

### `POST /api/v1/guardianships/me/dependents/:dependentId/devices/pairing-tokens`

Crea el token que el QR lleva. Se llama **como el tutor, sin `X-Acting-For`** (la ruta no declara `@ActingScope`: actuando responde 403 `ACTING_FOR_SCOPE_DENIED`). Throttle 10 por hora. Sin cuerpo.

```json
{
  "status": "success",
  "data": {
    "pairing_token": "q3JfB1x0kT9wYzA7u2NcDg",
    "qr_payload": "sacdia://pair?t=q3JfB1x0kT9wYzA7u2NcDg",
    "expires_at": "2026-10-20T18:10:00.000Z",
    "expires_in": 600
  }
}
```

201. El QR codifica `qr_payload` (`sacdia://pair?t=<token>`; es `?t=`, no `?c=`). Código: `DevicePairingService.issue`, `src/guardianships/device-pairing.service.ts`; controlador `src/guardianships/guardianships.controller.ts:429`.

- **Token**: 16 bytes aleatorios en base64url (22 caracteres, `^[A-Za-z0-9_-]{22}$`), vigencia 600 s (`DEVICE_PAIRING_TOKEN_TTL_MS`), de un solo uso. En la base solo se guarda su HMAC-SHA256 en hexadecimal (64 caracteres, `token_hash`), con una clave HKDF derivada de `BETTER_AUTH_SECRET` (`info = sacdia:device-pairing-token`; no hay variable de entorno nueva). El token en claro sale una única vez, en esta respuesta; nunca se registra ni se audita. Un token nuevo **revoca** (`revoked_at`) los abiertos del mismo menor.
- **Reglas, en este orden**:
  1. Bandera apagada → 404 `FAMILY_FEATURE_DISABLED`.
  2. Tutor verificado, no custodia, no de prueba (`GuardianPowersPolicy.assertVerifiedGuardian`): extraño, custodia, tutoría revocada o menor ajeno → 404 `GUARDIANSHIP_NOT_FOUND`; vínculo `pending` → 403 `GUARDIANSHIP_CONSENT_NOT_VERIFIED`.
  3. Con el candado por dependiente: menor inactivo, congelado, purgado o sin perfil → 404 `GUARDIANSHIP_NOT_FOUND`; el menor tiene alguna fila `account` o un `supervised_logins` (cualquiera, habilitado o no) → 422 `DEVICE_PAIRING_NOT_ELIGIBLE` con `reason = has_supervised_login`; sin fecha de nacimiento o con edad igual o mayor que `minSelfLoginAge` del país (13 por defecto) → 422 `DEVICE_PAIRING_NOT_ELIGIBLE` con `reason = age_not_under_min_self_login`.
  4. Dos dispositivos activos (`revoked_at IS NULL`) → 409 `DEVICE_LIMIT_REACHED`.
- **Cuerpo de los errores**: `reason` viaja en `details`, que `HttpExceptionFilter` quita cuando `NODE_ENV=production`; **en producción el cliente solo ve `code`**. `max_devices` **no** está en el cuerpo del 409 (el código lo pasa como argumento de la plantilla del mensaje, que no lo usa): el tope se lee de `limits.max_devices` en `GET .../devices` y en `GET /guardianships/me/dependents`. Los clientes no deben depender de `details`.

### `POST /api/v1/auth/device/pair` (público)

Lo llama el teléfono del menor; nada autentica a un usuario, **el token es la credencial**. Código: `src/auth/device/device-auth.controller.ts:39` y `DevicePairingService.pair`, `device-pairing.service.ts`. Throttle por IP: 5 por minuto y 20 por hora (`PAIR_THROTTLE`, `device-auth.controller.ts:21`; el 429 del throttler es el genérico de Nest, sin `code` de dominio).

```json
{
  "pairing_token": "q3JfB1x0kT9wYzA7u2NcDg",
  "platform": "ios",
  "app_version": "2.4.0",
  "label": "Tablet de Ana"
}
```

- `pairing_token`: cadena de hasta 256 caracteres (la validación fina la hace el servicio, para que un token mal formado responda igual que uno desconocido). `platform`: `ios` o `android` (otro valor → 400 de validación del DTO, el 400 genérico, no el uniforme). `app_version` (opcional, hasta 64; se guardan 32 sin caracteres de control ni marcado) y `label` (opcional, hasta 500; se limpia: sin caracteres de control ni `<` `>`, espacios colapsados, 40 caracteres como máximo, por defecto `Dispositivo`).
- **200**:

```json
{
  "status": "success",
  "data": {
    "accessToken": "<JWT de dispositivo, 1 h>",
    "refreshToken": "<token de sesión opaco>",
    "expiresAt": 1792598400,
    "tokenType": "bearer",
    "device": { "linked_device_id": "uuid", "label": "Tablet de Ana" },
    "user": { "id": "uuid", "name": "Ana", "avatar": null }
  }
}
```

  `expiresAt` son segundos Unix de la **sesión** (30 días desde el emparejamiento), no del JWT. `user.name` es solo el primer nombre y `avatar` el valor de `users.user_image`. No hay datos de tutores, apellidos ni de otros menores, ni se devuelve el token de emparejamiento.
- **Qué hace**, en una sola transacción y con el candado por dependiente: busca el token por hash; **vuelve a validar todo** lo que `issue` comprobó (tutoría emparejante todavía `verified`, no custodia, no de prueba, `guardian_user_id` igual al creador del token, menor visible, sin cuenta ni acceso propio, menor que `minSelfLoginAge`) y el tope de 2 dispositivos; crea la sesión del dispositivo (30 días), la fila `linked_devices` (tope absoluto a 180 días) y **al final** consume el token con compare-and-set (el perdedor de una carrera hace rollback y recibe el 400 uniforme). La fila del dispositivo se crea antes de consumir el token porque la FK y el CHECK `device_pairing_tokens_consumed_ck` lo exigen. Audita `linked_device.paired` (sin el token) y, tras confirmar, sube el `epoch` y avisa a los tutores (abajo).
- **400 uniforme `DEVICE_PAIRING_TOKEN_INVALID`** para: token desconocido, mal formado, vencido, ya consumido, revocado, tutoría que ya no es válida, familia cambiada desde que se hizo el QR (cuenta o acceso propio, edad, menor congelado) y **bandera apagada**. Mismo cuerpo en todos los casos.
- **409 `DEVICE_LIMIT_REACHED`**: token válido pero el menor ya tiene dos dispositivos activos. No consume el token ni cuenta como fallo de IP.
- **429 `AUTH_LOGIN_LOCKED`**: 30 canjes fallidos (solo los 400 `DEVICE_PAIRING_TOKEN_INVALID` cuentan) desde la misma IP en una ventana de 24 h anclada en el primer fallo bloquean la IP, incluso con un token válido. Cabecera `Retry-After: 3600`; el cuerpo no lleva `details`. Contador atómico en Redis (clave `device-pairing:failures:v1:{ip}`, `src/guardianships/device-pairing-failure-counter.ts`); si Redis falla, el límite diario no aplica y solo queda el throttle por minuto y hora.

### `GET /api/v1/guardianships/me/dependents/:dependentId/devices`

Cualquier tutor **verificado** del menor (no solo quien emparejó el teléfono), como él mismo. Pendiente → 403 `GUARDIANSHIP_CONSENT_NOT_VERIFIED`; extraño → 404 `GUARDIANSHIP_NOT_FOUND`. No depende de la bandera. Código: `LinkedDevicesService.list`, `src/guardianships/linked-devices.service.ts:122`.

```json
{
  "status": "success",
  "data": {
    "devices": [
      {
        "linked_device_id": "uuid",
        "label": "Tablet de Ana",
        "platform": "ios",
        "app_version": "2.4.0",
        "paired_at": "2026-10-20T18:00:00.000Z",
        "paired_by_display_name": "Marta Pérez",
        "last_seen_at": null,
        "absolute_expires_at": "2027-04-18T18:00:00.000Z",
        "status": "active",
        "revoked_at": null,
        "revoked_reason": null
      }
    ],
    "limits": { "max_devices": 2 }
  }
}
```

Orden: `paired_at` descendente. Lista los activos y los revocados en los últimos 30 días (`REVOKED_DEVICE_HISTORY_MS`). `status` es `active` o `revoked`.

### `POST /api/v1/guardianships/me/dependents/:dependentId/devices/:deviceId/revoke`

Desvincula un dispositivo, de forma inmediata e **idempotente**. Sin cuerpo; throttle 30 por hora; 200. Cualquier tutor verificado. No depende de la bandera. Código: `LinkedDevicesService.revoke`, `linked-devices.service.ts:149`.

```json
{ "status": "success", "data": { "linked_device_id": "uuid", "revoked_at": "2026-10-20T19:00:00.000Z", "revoked_reason": "guardian" } }
```

- Errores: 403 `GUARDIANSHIP_CONSENT_NOT_VERIFIED` (vínculo pendiente); 404 `GUARDIANSHIP_NOT_FOUND` (extraño o menor ajeno); 404 `DEVICE_NOT_FOUND` (el dispositivo no existe o es de **otro menor**).
- **Idempotente**: repetirlo responde 200 con el `revoked_at` y el `revoked_reason` **originales** (aunque el motivo original no fuera `guardian`) y no escribe nada ni avisa de nuevo.
- **Efectos** (`LinkedDeviceRevocation.revokeInTx`, `src/auth/device/linked-device-revocation.ts:66`, en una transacción con el candado del menor): fija `revoked_at`, `revoked_by_user_id` y `revoked_reason = guardian` con compare-and-set sobre `revoked_at IS NULL`; **borra la sesión** del dispositivo (su refresh token muere); desactiva el token FCM que el dispositivo registró (solo si aún es del menor) y, si no queda otro dispositivo activo, todos los tokens FCM activos del menor; escribe la fila `linked_device.revoked` en `audit_logs`. Tras confirmar sube el `epoch`: la siguiente petición del teléfono es 401 `AUTH_DEVICE_REVOKED` aunque su JWT siga vigente. Los **otros** tutores verificados (no quien revoca) reciben el aviso `family:security` «{nombre} · dispositivo desvinculado».

### Refresh, cierre de sesión y sesiones de dispositivo

- **`POST /auth/refresh`** (cuerpo `{ "refreshToken": "..." }`): se detecta una sesión de dispositivo por su fila `linked_devices` (no por claims). Antes de deslizar la sesión corre la compuerta (`AuthService.refreshSession`, `src/auth/auth.service.ts`) y responde solo un **JWT de dispositivo** (nunca uno de acceso, aunque el dispositivo esté revocado o vencido: esa ruta no cae al camino de usuario). La sesión desliza `min(ahora + 30 días, tope absoluto)` (`DEVICE_SESSION_DURATION_MS`, `better-auth.service.ts:108`), así que nunca pasa de 180 días desde el emparejamiento. El token de acceso presentado se pone en lista negra como en cualquier refresh. Sin MFA. Errores: tope vencido con la sesión aún viva → 401 `AUTH_DEVICE_SESSION_EXPIRED`; fila revocada o compuerta inactiva con la sesión aún viva (bandera apagada, tutoría inválida, mayoría de edad, acceso propio habilitado, ...) → 401 `AUTH_DEVICE_REVOKED`; si la revocación ya **borró la sesión** (el caso normal tras desvincular) el refresh token no tiene dueño y responde el 401 genérico `AUTH_REFRESH_TOKEN_INVALID`. La app debe tratar los tres como «volver a vincular».
- **`POST /auth/logout`** con el refresh token de un dispositivo (commit `0d40ac40`): primero busca el dispositivo activo de esa sesión, **luego lo revoca con motivo `device_logout` y después cierra la sesión** (`betterAuthService.signOut`). El orden importa: la revocación es una sola transacción que marca la fila como revocada **y** borra la sesión, así que nunca queda una sesión borrada con el dispositivo aún activo, y el cierre de sesión posterior no tiene nada que borrar. Es de mejor esfuerzo: si la revocación falla solo se registra (`auth_logout_device_revoke_failed`) y el cierre de sesión se ejecuta igual; la fila huérfana (activa, sin sesión) se cura la próxima vez que se comprueba el tope de dispositivos (ver «Dispositivos huérfanos y tope de dos»). Si la búsqueda del dispositivo falla, el logout sigue como el de un usuario normal (`AuthService.logout`, `src/auth/auth.service.ts`). Los tutores reciben el aviso de desvinculación.
- **Listas de sesiones**: `GET /auth/sessions` y `GET /admin/users/:userId/sessions` llevan `kind: "user" | "device"` en cada ítem (y `linked_device_id` / `linkedDeviceId`, `null` salvo en un dispositivo). Es una sesión de dispositivo solo si una fila `linked_devices` nombra su id.
- **Revocar sesiones** (`DELETE /auth/sessions/:sessionId`, `DELETE /auth/sessions` y las rutas de admin): tras borrar las filas, los dispositivos cuya sesión desapareció quedan marcados `session_revoked` (`markMissingSessionsRevoked`). Las rutas de `/auth/sessions*` solo las alcanza la edad desconocida (`account:manage`); el efecto práctico es del lado de admin.

### Dispositivos huérfanos y tope de dos

Un dispositivo **huérfano** es una fila `linked_devices` activa (`revoked_at IS NULL`) cuya sesión ya no existe, por ejemplo un `POST /auth/logout` que falló a medias (commit `0d40ac40`). Sin cuidado ocuparía para siempre uno de los dos cupos. Por eso la comprobación del tope (`DevicePairingService.assertUnderDeviceCap`, que usan `issue` y `pair`) **primero cura**: `LinkedDeviceRevocation.healOrphansInTx` busca las filas activas del menor sin fila en `session` y las revoca con motivo `session_revoked` (`revoked_by_user_id = null`), dentro de la misma transacción y con el candado del menor, y **después** cuenta los activos contra `MAX_LINKED_DEVICES_PER_DEPENDENT` (2). Efectos:

- Un teléfono muerto no bloquea crear el QR (`issue`) ni canjearlo (`pair`) con un 409 `DEVICE_LIMIT_REACHED` falso.
- En `issue`, tras confirmar la transacción se llama a `bumpAfterCommit` con los dispositivos curados para invalidar las decisiones cacheadas de la compuerta. En `pair` el `epoch` del menor se sube igualmente al terminar el canje.
- La revocación por curación pasa por `revokeInTx`: escribe el `audit_logs` `linked_device.revoked` y desactiva el token FCM ligado. No avisa a los tutores (`healOrphansInTx` no usa `afterCommit`).

### Cuándo se revoca un dispositivo (motivos)

`linked_devices.revoked_reason` está limitado por un CHECK de la base. Quién escribe cada motivo:

| Motivo | Cuándo | Dónde |
| --- | --- | --- |
| `guardian` | Un tutor lo desvincula | `POST .../devices/:deviceId/revoke` |
| `guardianship_revoked` | Sale o es quitado el tutor que emparejó (`guardian_left`, `removed_by_primary`); sale el último tutor y el menor queda en custodia del club o en modo pendiente; la compuerta ve la tutoría inválida | `GuardianshipLifecycleService` (`guardianship-lifecycle.service.ts:174`, `:222`, `:268`); compuerta |
| `guardian_account_closed` | El tutor que emparejó elimina su cuenta (los dispositivos de su tutoría) | `deviceReasonOf`, `guardianship-lifecycle.service.ts:553`; `src/auth/account-deletion.service.ts:230` |
| `teen_login_enabled` | Se habilita el acceso propio del menor, o el menor canjea el código de vínculo de adolescente; también lo registra la compuerta | `supervised-logins.service.ts:384`, `link-codes.service.ts:602`; compuerta |
| `dependent_frozen` | El último tutor sale y el menor se congela; el cron de 90 días sin tutor; la purga; la compuerta ve al menor inactivo o congelado | `guardianship-lifecycle.service.ts:288`, `pending-teen-cron.service.ts:378`, `dependent-profiles-purge-cron.service.ts`; compuerta |
| `majority` | El menor llega a la mayoría de edad | La compuerta, de forma perezosa (siguiente petición o refresh), y el barrido diario del cron `family-age-transitions` (3c, `LinkedDevicesService.revokeBySystem`). Avisa a los tutores verificados (ruling W6) |
| `device_logout` | El teléfono cierra sesión (se revoca antes de borrar la sesión) | `POST /auth/logout` |
| `session_revoked` | Se borró su sesión por otro camino (usuario o admin), la compuerta no la encuentra, o el chequeo del tope de dispositivos encuentra una fila activa sin sesión (autocuración) | `markMissingSessionsRevoked`; compuerta; `LinkedDeviceRevocation.healOrphansInTx` |
| `admin` | Un administrador lo desvincula desde el panel con un motivo escrito (3c): `POST /admin/users/:userId/linked-devices/:deviceId/revoke` | `LinkedDevicesService.revokeAsAdmin` |
| `expired` | Pasó el tope absoluto de 180 días | La compuerta y el barrido del cron `family-age-transitions` (3c). Avisa a los tutores verificados (ruling W6) |

- **Los motivos de 3a se revocan dentro de la transacción del llamador** (el dispositivo y el cambio de familia se confirman o se revierten juntos) a través del puerto `LINKED_DEVICE_REVOKER`, que desde la 3b es **obligatorio** y está ligado a `LinkedDevicesService` (ya no hay no-op; `src/guardianships/guardianships.module.ts:80`). El `epoch` lo sube el llamador tras confirmar.
- **Avisos al tutor por revocación**: solo para `guardian` (a los otros tutores), `guardianship_revoked`, `guardian_account_closed`, `device_logout`, `session_revoked`, `admin`, `majority` y `expired` (`NOTIFIED_REASONS`, `linked-devices.service.ts`). **No** avisan `teen_login_enabled` (ya tiene su aviso) ni `dependent_frozen` (lo causa una acción de un adulto). Desde la 3c (ruling W6) **sí** avisan `majority` y `expired`, y las revocaciones que origina la propia compuerta también anuncian: el aviso sale una sola vez, de quien logre el compare-and-set de la revocación (el barrido o la compuerta). Cuando la revocación ocurre dentro de la transacción de otro servicio (3a), el aviso se envía solo cuando la revocación ya es visible desde otra conexión (reintentos a los 50 ms, 250 ms, 1 s, 3 s y 8 s); si la transacción se revirtió no se anuncia nada.
- **Purga** (`dependent-profiles-purge`, commit `a8af9091`): revoca los dispositivos que queden (`dependent_frozen`), borra todos los tokens FCM y todos los tokens de emparejamiento del menor y anonimiza sus filas de `linked_devices` (`label` = `Dispositivo`, `app_version` y `fcm_token_id` en `NULL`); las filas se conservan como auditoría. Detalle en `docs/database/SCHEMA-REFERENCE.md`, «Retención y purga».
- Los dispositivos ya vinculados **no** se revocan por cumplir 13 años (ver la compuerta).

### Avisos y pushes

- **Vincular**: tras un canje correcto, los tutores verificados no custodia (hasta 4) reciben `family:security` «{nombre} · dispositivo vinculado» con «{etiqueta} ({plataforma})» (`GuardianSecurityNotificationsService.onDevicePaired`, `guardian-security-notifications.service.ts:168`). Push y bandeja, nunca correo; no se puede silenciar.
- **Subida de evidencia del dispositivo**: cada subida correcta de evidencia de una clase hecha con un token de dispositivo avisa a los tutores verificados del menor con `family:evidence_uploaded`, título «{nombre} subió evidencia» y cuerpo «Se subió evidencia de una clase: {etiqueta}.» (`GuardianNotificationsService.onDependentEvidenceUploaded`, `src/guardianships/guardian-notifications.service.ts`, llamado tras confirmar la subida en `ClassesService`). Destinatarios: solo tutores **verificados** (`consent_status = verified`), de persona, no custodia, no de prueba y con tutoría no revocada, sin quien subió (commit `08ca4338`): un vínculo `pending`, por ejemplo alguien con un código filtrado, no recibe avisos hasta que el director verifique. Es por **subida**: borrar o enviar a validación no avisa. Mejor esfuerzo: nunca falla la subida. El aviso se suprime solo cuando quien sube es un tutor actuando o un adolescente supervisado; la comprobación es por tipo de principal, no por sujeto, porque el dispositivo también deja el sujeto de auditoría en el menor.
- **Pushes del club al menor**: el teléfono registra su token con `POST /users/me/fcm-tokens` (`push:register`); el servicio lo liga a la fila del dispositivo (`linked_devices.fcm_token_id`) y, si el token rota, desactiva el anterior (`src/notifications/fcm-tokens.service.ts:91`). Un push del club dirigido al menor llega al **token del dispositivo** y, además, los tutores conservan la copia con la etiqueta «{nombre} · {título}» (`DependentPushRouterService`: tutores activos, hasta 4, con las preferencias de cada uno; las fuentes `family:*` no se vuelven a repartir). La 3b no cambió código aquí: lo verifican las pruebas `notifications.service.spec.ts` y `dependent-push-router.service.spec.ts`. Revocar el dispositivo desactiva su token, así que el menor deja de recibir y los tutores siguen recibiendo la copia.
- **Analítica**: `GET /auth/me` devuelve `analytics_anonymous: true` siempre para un dispositivo; la app no identifica al menor en PostHog ni en Sentry. En la app (`lib/main.dart`, `analytics_policy.dart` y `posthog_analytics.dart`) un arranque en frío con una sesión de dispositivo persistida llama a `blockAnalyticsForDevice()` antes de inicializar PostHog, que queda sin inicializar; en una sesión ya abierta, `AnalyticsPolicy.apply` llama a `disableAnalyticsForDevice()` (reset y disable) cuando el usuario es un dispositivo vinculado. No se capturó tráfico de red hacia PostHog: la afirmación se apoya en el código.

### Errores de la Fase 3b

| Status | `code` | Cuándo |
| --- | --- | --- |
| 401 | `AUTH_DEVICE_REVOKED` | Token de dispositivo: desvinculado o con la compuerta inactiva (tabla de arriba), o bandera apagada. También en `POST /auth/refresh` con la sesión aún viva |
| 401 | `AUTH_DEVICE_SESSION_EXPIRED` | Pasó el tope absoluto de 180 días (petición o refresh) |
| 503 | `AUTH_REVOCATION_CHECK_UNAVAILABLE` | La base falla al evaluar la compuerta. Nunca se concede por defecto |
| 403 | `ACTING_FOR_FORBIDDEN` | `X-Acting-For` con un token de dispositivo |
| 403 | `PRINCIPAL_SCOPE_DENIED` | Un dispositivo llama a una ruta sin un scope que tenga (`kind: "linked_device"`) |
| 400 | `DEVICE_PAIRING_TOKEN_INVALID` | `POST /auth/device/pair`: cualquier problema del token o de la familia, o bandera apagada (cuerpo uniforme) |
| 422 | `DEVICE_PAIRING_NOT_ELIGIBLE` | Crear el token: el menor tiene cuenta o acceso propio, o ya tiene la edad mínima de acceso propio. `reason` solo fuera de producción |
| 409 | `DEVICE_LIMIT_REACHED` | Crear el token o canjearlo con dos dispositivos activos. Sin `max_devices` en el cuerpo |
| 404 | `DEVICE_NOT_FOUND` | Desvincular un dispositivo que no existe o es de otro menor |
| 404 | `FAMILY_FEATURE_DISABLED` | Crear el token con la bandera apagada |
| 429 | `AUTH_LOGIN_LOCKED` | Canje: 30 fallos al día por IP (`Retry-After: 3600`) |

Los seis códigos están en `ErrorCode` (`src/common/errors/error-codes.ts:880-885`) y en los 4 `errors.json` del backend (`es`, `en`, `fr`, `pt-BR`).

### Bandera `FAMILY_LINKED_DEVICE_ENABLED`

Por defecto `false` (`src/config/env.validation.ts:240`). Apagada: no se crean tokens (404), no se canjean (400 uniforme), y todo token de dispositivo y todo refresh de dispositivo responde 401 `AUTH_DEVICE_REVOKED` **sin cambiar datos** (las filas siguen activas; al volver a encenderla los dispositivos funcionan otra vez). Listar y desvincular siguen disponibles. **Cambiar la bandera en un servidor desplegado exige reiniciarlo**, igual que `FAMILY_TEEN_LOGIN_ENABLED` (ver «Banderas de configuración»: `ConfigService` lee la foto del entorno del arranque). `GET /auth/me` la expone en `family_features.linked_device`. Para cortar todos los dispositivos en una emergencia: apagarla y reiniciar.

## Registro de menores por un director y acceso familiar en el panel (Fase 3c)

> [!NOTE]
> Perfiles familiares, Fase 3c, rama `feat/family-profiles-phase3` de sacdia-backend (los diez commits de la 3c son `cf3d6ce2`, `ef6baa39`, `aecd39d1`, `7b51015b`, `44b7b334`, `490dd33a`, `eb574871`, `09e4016d`, `43bbd35d` y `32022392`, en ese orden). Pendiente de merge (PR #531 de sacdia-backend).
> Describe el comportamiento **implementado en el backend**, verificado contra el código de la rama. La app (tareas A01 a A06) y el panel (M01 a M05) están hechos en sus ramas `feat/family-profiles-phase3`. El QA en vivo de la 3c sigue **Pendiente**: `docs/testing/FAMILY-PROFILES-PHASE3C-QA.md`. Esquema: `docs/database/SCHEMA-REFERENCE.md`, «Registro por director y acceso familiar (Fase 3c)». Las migraciones `20261022120000_family_director_minors` y `20261022130000_seed_family_permissions` están aplicadas en Neon `development` desde el 2026-10-20 (con aprobación del usuario); no en producción.

Tres piezas: (1) un director registra a un menor de 0 a 17 años en su sección y el club lo custodia hasta que lo reclame una familia, (2) la verificación del consentimiento la hace **otra persona** distinta de quien lo creó, y (3) el panel puede cortar el acceso propio o un dispositivo de un menor, mientras un cron avisa a los tutores cuando el menor cumple la edad de acceso propio o cuando un dispositivo vence.

### Permisos nuevos y quién los tiene

Los crea la migración `20261022130000_seed_family_permissions` (solo DML, `ON CONFLICT`; las mismas filas viven en `prisma/seeds/permissions.seed.sql` y `prisma/seeds/role-permissions.seed.sql`, y una prueba comprueba que coinciden).

| Permiso | Para qué | Roles que lo tienen |
| --- | --- | --- |
| `dependents:create` | Registrar un menor en una sección (`POST /club-sections/:clubSectionId/dependents`) | Rol de club `director` y `deputy-director`; globales `admin`, `assistant-admin` y `super-admin` |
| `consent:verify` | Verificar el consentimiento de un menor **sin** poder aprobar la solicitud (`verify-consent` con `approve: false`) | Rol de club `director`, `deputy-director`, `secretary` y `secretary-treasurer`; globales `admin`, `assistant-admin`, `super-admin`, y (migración `20261023120000_grant_consent_verify_to_coordinators`, aplicada en `development`) `coordinator`, `zone-coordinator` y `general-coordinator` |

La migración da las filas de admin de forma explícita porque una migración no puede apoyarse en los comodines de los seeds. En Neon `development` no existe el rol `assistant-admin`, así que ahí se insertaron **10** asignaciones y no 12 (la migración une solo roles activos que existen).

> [!NOTE]
> **Coordinadores: `consent:verify` por asignación (antes limitación B11, resuelta).** La migración `20261022130000` dejó fuera a los coordinadores porque `PermissionsGuard` no resolvía su territorio: `canManageClub` y `resolveActorTerritoryScope` no conocen a `coordinator`, `zone-coordinator` ni `general-coordinator` (403 `GUARD_CLUB_SCOPE_REQUIRED` incluso dentro de su zona), y ampliarlos habría dado a un coordinador poder de gestión de club en todas partes. La regla nueva (rama `feat/coordinator-consent-verify`, migración `20261023120000_grant_consent_verify_to_coordinators`, solo DML, **aplicada en `development`**, pendiente en `staging` y `production`) es **estrecha y por ruta**:
>
> - La migración da `consent:verify` a los roles globales `coordinator`, `zone-coordinator` y `general-coordinator` (`ON CONFLICT DO NOTHING`, solo roles y permiso activos). Los mismos datos viven en el bloque `-- BEGIN/END coordinator consent:verify` de `prisma/seeds/role-permissions.seed.sql`.
> - Solo tres rutas lo honran, con `@AuthorizationResource({ coordinatorSections: true })`: `GET .../membership-requests`, `GET .../consent-evidence` y `POST .../verify-consent`. El `POST .../consent-evidence` (subir la ficha) es solo de quien aprueba. `approve` y `reject` no cambian.
> - Un coordinador pasa **solo** en las secciones que cubren sus `coordinator_assignments` activas (vigentes hoy): `GENERAL` (todas las secciones del campo local), `ZONE` (los distritos de la zona, en el tipo de club de la asignación) o `SECTION` (esa sección). Es la **asignación** y no ser miembro del club lo que da la autoridad: un coordinador que es miembro de la sección sin asignación que la cubra recibe 403 `GUARD_CLUB_SCOPE_REQUIRED`. Si además es director o secretario de esa sección, conserva sus poderes de club como cualquier otro.
> - Es un revisor **solo-verificación**: nunca aprueba (ver «Revisor solo-verificación», abajo).
>
> `canManageClub` y `resolveActorTerritoryScope` **no cambian**. Hasta aplicar la migración, un coordinador no tiene el permiso y todo sigue como antes.

### Revisor solo-verificación (`consent:verify` sin `club_members:approve`)

Un revisor es **solo-verificación** cuando el llamante entró por la vía de coordinador, o `club_members:approve` no figura entre sus permisos efectivos (por ejemplo un coordinador, o un rol de club que tuviera `consent:verify` sin `club_members:approve`; hoy los cuatro roles de club con `consent:verify` también aprueban). Si no hay autorización resuelta se trata como solo-verificación (falla cerrado). Para esos revisores (opción B, decisión del 2026-10-20):

| Ruta | Permisos | Comportamiento solo-verificación |
| --- | --- | --- |
| `GET .../membership-requests` | `club_members:approve` **o** `consent:verify` | Ven **únicamente** menores con el consentimiento `pending` **y** una ficha vigente subida. Adultos, menores ya verificados y menores sin ficha no aparecen. Las filas con `viewer_verify_block` (`self_guardian` o `self_custodian`) **sí** se muestran, con el bloqueo, para que la interfaz explique por qué no pueden actuar. Quien tiene `club_members:approve` en la sección ve la lista completa como siempre. |
| `GET .../consent-evidence` | igual | Solo dentro de su lista (solicitud `pending`, menor, consentimiento `pending`, ficha vigente); fuera, 404 `MR_NOT_FOUND`. |
| `POST .../consent-evidence` | solo `club_members:approve` | Un solo-verificación **no puede subir** la ficha (decisión W5): 403 `GUARD_PERMISSION_DENIED` (sin el permiso) o 403 `GUARD_CLUB_SCOPE_REQUIRED` (su `club_members:approve` pertenece a otro club), antes de leer nada. La subida es del tutor o del director. |
| `POST .../verify-consent` | `club_members:approve` **o** `consent:verify` | Fuera de su lista (adulto, solicitud no `pending`, sin tutoría principal, sin ficha vigente, ya verificado, solicitud `active`) responde 404 `MR_NOT_FOUND`, sin distinguir qué hay detrás. Los 403 de cuatro ojos siguen. `approve: true` → 403 `MR_APPROVE_PERMISSION_REQUIRED`. |
| `POST .../approve` y `.../reject` | solo `club_members:approve` | Sin cambios: 403 para un coordinador. |

Quien aprueba después necesita `club_members:approve`. Cobertura: pruebas unitarias de guard y servicios, y e2e `test/director-created-minor.e2e-spec.ts` (viaje A2: coordinador con asignación `SECTION` cubierta verifica con `approve: false`; coordinador de otra sección, con asignación vencida o miembro de la sección sin asignación reciben 403 `GUARD_CLUB_SCOPE_REQUIRED`; subir ficha 403 `GUARD_PERMISSION_DENIED`; `approve: true` 403 `MR_APPROVE_PERMISSION_REQUIRED`). El e2e no evalúa el filtro relacional de zona contra una base real; el alcance se verifica con `src/common/authorization/coordinator-section-scope.postgres.spec.ts` (Postgres real, gated; ver `docs/api/TESTING-GUIDE.md`, «Specs contra Postgres real»). QA en vivo (2026-10-21, rama temporal de Neon `qa-coord-20261021`): se ejercitó la verificación de un coordinador `ZONE` (`approve: false`: consentimiento `verified`, solicitud `pending`) y el 404 `MR_NOT_FOUND` al repetirla. Sigue sin verificarse en vivo la lista por sección, la lectura de la ficha, los rechazos (otra sección, asignación vencida, miembro sin asignación, subir ficha, aprobar) y los coordinadores `SECTION` y `GENERAL`.

### `GET /api/v1/coordination/me/consent-pending`

> [!NOTE]
> Rama `feat/coordinator-pending-consents` de sacdia-backend (commit `a8688f81`), **mergeada en `development` (PR #534 de sacdia-backend, 2026-10-21)**. Verificado contra el código de la rama (`src/coordination/coordination.controller.ts`, `coordinator-consent-queue.service.ts`, `dto/coordinator-consent-pending-query.dto.ts`, `membership-requests.service.ts` `listVerifyWorkAcrossSections`). La app (sacdia-app, commit `78ff697b`) y el panel (sacdia-admin, commit `07247d1`) ya lo consumen desde su rama `feat/coordinator-pending-consents`, mergeada en `development` como PR #181 de sacdia-app y PR #246 de sacdia-admin. Las filas de esta ruta no cuentan en los totales de la cabecera.

La **cola del coordinador**: una sola llamada devuelve todas las fichas de consentimiento que esperan verificación en **todas** las secciones que cubren sus `coordinator_assignments` vigentes. Sustituye al recorrido sección por sección que hacían la app y el panel con `GET .../membership-requests` (que sigue siendo la ruta para quien no es coordinador y para una sola sección).

- **Qué lista**: lo mismo que la lista por sección muestra a un revisor solo-verificación (ver «Revisor solo-verificación»): solicitudes `pending` de menores con consentimiento `pending` **y** una ficha vigente subida. Se omiten adultos, consentimientos ya verificados y menores sin ficha. Las filas con `viewer_verify_block` se incluyen con el bloqueo. El predicado es el mismo (`consentHasVerifyWork`), no una copia.
- **Cobertura**: la expansión de `GET /coordination/me/scope` (solo territorio activo; ver `docs/canon/runtime-coordination.md`). Una asignación vencida o con el territorio inactivo no aporta secciones.
- **Autorización**: `@RequirePermissions('consent:verify')` con `@AuthorizationResource({ type: 'global' })`, es decir, el permiso se evalúa como **global**: un `consent:verify` que viene de un rol de club **no cuenta**. Además el servicio exige que el permiso provenga de un **rol de coordinador** (`coordinator`, `zone-coordinator` o `general-coordinator`) y que las asignaciones activas cubran al menos una sección. Quien tiene `consent:verify` por otra vía (director, secretario, admin) usa la lista por sección. Sin `@ActingScope`: un tutor actuando, un adolescente supervisado y un dispositivo vinculado quedan denegados por defecto.

**Query** (`CoordinatorConsentPendingQueryDto`; el `ValidationPipe` global tiene `forbidNonWhitelisted`, así que cualquier otro parámetro es 400):

| Parámetro | Requerido | Validación |
| --- | --- | --- |
| `limit` | No | Entero de 1 a 100. Por defecto 50 |
| `offset` | No | Entero `>= 0`. Por defecto 0 |

**Respuesta 200**:

```json
{
  "status": "success",
  "data": {
    "items": [
      {
        "assignment_id": "3f0c8a52-6a58-4b1e-9d2a-0e5b7c1d9a11",
        "user_id": "8d1f0b34-2c6e-4f0a-bb7e-5a3c9e2d4f10",
        "club_section_id": 10,
        "status": "pending",
        "created_at": "2026-10-01T12:00:00.000Z",
        "expires_at": "2026-10-09T12:00:00.000Z",
        "effective_expires_at": "2026-10-31T12:00:00.000Z",
        "consent_form_uploaded_at": "2026-10-03T09:30:00.000Z",
        "club_name": "Club Orion",
        "club_type_name": "Conquistadores",
        "district_name": "Distrito Norte",
        "users": { "user_id": "…", "name": "Mateo", "email": null, "paternal_last_name": "Pérez", "maternal_last_name": "López", "user_image": null },
        "roles": { "role_id": "…", "role_name": "member" },
        "consent": { "required": true, "dependent": true, "guardian_linked": false, "guardianship_id": "…", "status": "pending", "evidence_uploaded": true, "guardians": [], "viewer_can_verify": true, "viewer_verify_block": null }
      }
    ],
    "total": 1,
    "limit": 50,
    "offset": 0,
    "by_section": [
      { "club_section_id": 10, "club_name": "Club Orion", "club_type_name": "Conquistadores", "district_name": "Distrito Norte", "pending_consent_count": 1 }
    ]
  }
}
```

- **`items`**: cada elemento es el elemento de `GET /club-sections/:id/membership-requests` (mismo bloque `consent`, con `viewer_can_verify` y `viewer_verify_block`, y `effective_expires_at`) más `consent_form_uploaded_at`, `club_name`, `club_type_name` y `district_name`. Los tres nombres pueden ser `null` si la sección ya no figura en la expansión (carrera entre la lectura de la cola y la del alcance).
- **`total`** y **`by_section`** cuentan la cola **completa**, no la página. `by_section` trae solo las secciones con al menos una ficha pendiente (`pending_consent_count >= 1`), ordenadas por `club_section_id`. `limit` y `offset` repiten los valores aplicados.
- **Orden**: la ficha vigente más antigua primero (`guardianship_consent_evidences.uploaded_at` ascendente, es decir, la que más lleva esperando), luego `created_at` de la solicitud ascendente y, por último, `assignment_id`.
- **Paginación por `offset`**: el total se calcula en memoria sobre los candidatos, así que no hay cursor. Una fila que otro revisor verifica entre dos páginas puede desplazar las siguientes; los clientes deben tratar la página como instantánea y refrescar tras verificar.

**Errores**:

| Estado | Código | Cuándo |
| --- | --- | --- |
| 400 | validación genérica | `limit` fuera de 1..100, `offset` negativo, valores no enteros o parámetros desconocidos |
| 403 | `GUARD_PERMISSION_DENIED` | `consent:verify` no proviene de un rol de coordinador (un coordinador cuyo permiso sale solo de un rol de club, o un director, secretario o admin sin ese rol) |
| 403 | `GUARD_CLUB_SCOPE_REQUIRED` | El coordinador no tiene asignaciones vigentes que cubran alguna sección activa (ninguna, vencidas o solo territorio inactivo) |
| 403 | `ACTING_FOR_SCOPE_DENIED` | Tutor actuando con `X-Acting-For` |
| 403 | `PRINCIPAL_SCOPE_DENIED` | Adolescente supervisado o dispositivo vinculado |

Costo: el número de consultas no crece con el de secciones. Son una lectura de candidatas (solicitudes pendientes de todas las secciones cubiertas, solo ids), la consulta de trabajo de verificación para esos usuarios (lecturas de tutorías y de la política de edad), una lectura de la página y las cargas por lote del consentimiento de los usuarios de esa página.

**Clientes**: la app («Fichas por verificar») pide páginas de 50 con «Cargar más», muestra el total y el resumen por sección desde `by_section`, y decide los estados de pantalla por `code` (403 `GUARD_CLUB_SCOPE_REQUIRED` → sin secciones; `GUARD_PERMISSION_DENIED`, `ACTING_FOR_SCOPE_DENIED` y `PRINCIPAL_SCOPE_DENIED` → denegado; otros → error con reintento). La insignia del hub sale de `limit=1` y el `total`. El panel muestra la vista «Todas mis secciones» por defecto para coordinadores en `/dashboard/requests/membership`, con páginas de 25; el resumen por sección cambia el selector a la lista de esa sección (no filtra en el cliente, porque la paginación por `offset` ocultaría fichas de otras páginas). Verificar usa `verify-consent` con la `club_section_id` del propio elemento.

### `POST /api/v1/club-sections/:clubSectionId/dependents`

Un director registra a un menor en su sección. Controller `DirectorDependentsController` (`src/guardianships/director-dependents.controller.ts`), servicio `DirectorDependentsService`.

- **Autorización**: `@RequirePermissions('dependents:create')` con `@AuthorizationResource({ type: 'club_section', idParam: 'clubSectionId' })`, es decir, el permiso se exige **en esa sección** (un director de otra sección recibe 403). Sin `@ActingScope`: un tutor actuando recibe 403 `ACTING_FOR_SCOPE_DENIED`, y un adolescente supervisado o un dispositivo 403 `PRINCIPAL_SCOPE_DENIED` (denegado por defecto).
- **Bandera** `FAMILY_DIRECTOR_CREATE_MINOR_ENABLED` (por defecto `false`): apagada → 404 `FAMILY_FEATURE_DISABLED`. La bandera se comprueba **dentro del handler, después de los guards**, de modo que un llamante sin permiso recibe 403 aunque la bandera esté apagada. Apagarla no toca nada de lo ya creado (verificar, reclamar, vencer siguen funcionando). `GET /auth/me` la expone como `family_features.director_create_minor`.
- **Límite**: 30 por hora por director (429).
- **Cuerpo** (`CreateDirectorDependentDto`; `forbidNonWhitelisted` está activo, así que cualquier clave extra es 400):

```json
{
  "name": "Luis",
  "paternal_last_name": "Pérez",
  "maternal_last_name": "López",
  "birthday": "2016-02-10",
  "gender": "M",
  "sworn_declaration": true,
  "accepted_terms_version": "2.0.0-family",
  "accepted_privacy_version": "2.0.0-family"
}
```

  `name` y `paternal_last_name` obligatorios (hasta 50 caracteres, recortados); `maternal_last_name` opcional; `birthday` `YYYY-MM-DD`; `gender` opcional `M` o `F`; `sworn_declaration` debe ser `true` (el director declara bajo protesta que el tutor firmó la autorización en papel); las dos versiones legales deben ser las vigentes (`GET /legal/current`). **No hay** `email`, `access_mode`, `account`, contraseña ni `relationship_type_id` (el director no es de la familia: quien tiene al menor es el club).
- **Edad**: `0 <= edad < mayoría de edad del país de la sección` (política de país del club de la sección, no la del director). Es más ancha que la del tutor (un menor de 15 años es válido). Fecha futura, edad negativa o mayor de edad → 422 `GUARDIANSHIP_DEPENDENT_AGE_OUT_OF_RANGE`.
- **Qué crea** (todo en **una** transacción; si algo falla no queda nada): `users` (UUID nuevo, `email` NULL, `country_id` del club de la sección; no se fijan `union_id` ni `local_field_id`), `users_pr` con todo en `false`, `users_roles` con el rol global `user`, `dependent_profiles` (`created_by_user_id` = el director), una tutoría de **custodia del club** (`is_custodian`, `custodian_club_id` = club principal de la sección, principal, `consent_status = pending`, `sworn_declaration_at`), una asignación `member` **`pending`** en la sección y el año eclesiástico vigente (nunca `active`), las aceptaciones de Términos y Privacidad **del menor registradas por el director** (`accepted_by_user_id` = director) y la fila de auditoría `dependent` / `created_by_director`. No existe fila `account`: el menor no tiene acceso.
- **Después de confirmar**: sube el `epoch` del menor y avisa a los revisores de la sección (asignación **activa** de `director`, `deputy-director`, `secretary` o `secretary-treasurer`), **sin** avisar a quien lo creó: título «Menor · consentimiento pendiente», fuente `membership_requests:new_request`, de mejor esfuerzo (nunca falla ni retrasa la respuesta).
- **Respuesta 201**:

```json
{
  "status": "success",
  "data": {
    "dependent": { "user_id": "uuid", "name": "Luis", "birthday": "2016-02-10", "age": 10 },
    "guardianship": { "guardianship_id": "uuid", "is_custodian": true, "consent_status": "pending" },
    "assignment": { "assignment_id": "uuid", "status": "pending", "club_section_id": 163 }
  }
}
```

- **Errores**: 400 de validación (`sworn_declaration` distinto de `true`, clave desconocida, formato) o 400 `LEGAL_VERSION_MISMATCH` (versión no vigente; es lo primero que se comprueba, antes de tocar la base); 403 (sin `dependents:create` en esa sección, o principal no permitido); 404 `FAMILY_FEATURE_DISABLED` (bandera apagada); 404 `CLUB_SECTION_NOT_FOUND` (sección inexistente o sin club principal); 422 `GUARDIANSHIP_DEPENDENT_AGE_OUT_OF_RANGE`; 429 (31.ª en una hora); 500 `POST_REG_NO_ACTIVE_YEAR` (no hay año eclesiástico vigente: no se crea nada).
- **El menor no es miembro** hasta que **otra persona** verifique la ficha firmada y se apruebe la solicitud (secciones siguientes).

### Verificación independiente del consentimiento (`verify-consent`)

`POST /club-sections/:clubSectionId/membership-requests/:assignmentId/verify-consent` (sección `membership-requests`) cambia así en la 3c:

- **Permisos con «cualquiera de»**: `club_members:approve` **o** `consent:verify` (`@RequirePermissions({ permissions: [...], mode: 'any' })`). Los coordinadores (`consent:verify` por la migración `20261023120000_grant_consent_verify_to_coordinators`) solo entran en las secciones que cubren sus `coordinator_assignments` (ver «Revisor solo-verificación»); un revisor solo-verificación fuera de su lista recibe 404 `MR_NOT_FOUND`.
- **`approve: true` exige además `club_members:approve`**: si el llamante solo tiene `consent:verify` (o entró por la vía de coordinador), responde 403 `MR_APPROVE_PERMISSION_REQUIRED` **antes de leer o escribir nada** (la comprobación está en el controller y falla cerrada si el guard no dejó la autorización resuelta). Quien solo tiene `consent:verify` puede llamar con `approve: false` (u omitido); la aprobación la hace después alguien con `club_members:approve`.
- **Cuatro ojos por id de usuario** (regla A14, sin cambios de contrato, con más escenarios probados): para un menor bajo custodia del club no pueden verificar **quien lo creó** (`dependent_profiles.created_by_user_id`), **quien subió la ficha vigente** ni el último tutor que lo dejó en custodia → 403 `GUARDIANSHIP_CUSTODIAN_SELF_VERIFY`, sin escribir nada; un tutor vigente del menor → 403 `GUARDIANSHIP_GUARDIAN_SELF_VERIFY`. La regla va por **id de usuario**: un creador que además es administrador sigue bloqueado, y sigue bloqueado aunque después pierda el rol. No hay un código de verificador nuevo.
- Si quien creó al menor llama a `approve` mientras el consentimiento sigue `pending`, la compuerta responde 409 `MR_CONSENT_NOT_VERIFIED`.
- **Camino completo**: el director crea al menor → (cualquier revisor con `club_members:approve` o el propio director sube la ficha; si la sube el creador, ese creador sigue sin poder verificar) → **otra persona** (subdirector, secretario, secretario-tesorero u otro director, `admin` o un coordinador cuya asignación cubra la sección) verifica con `verify-consent` → alguien con `club_members:approve` aprueba (`approve: true` en la misma llamada, o `approve` aparte). El evento `guardianship.consent_verified` queda con el verificador como actor.

### `consent.viewer_can_verify` y `consent.viewer_verify_block`

`GET /club-sections/:clubSectionId/membership-requests` añade **dos campos al bloque `consent`** de cada solicitud de un menor (commit `32022392`). Se calculan para **quien consulta** con el mismo predicado que aplica `verify-consent` (un solo módulo, `src/membership-requests/consent-four-eyes.ts`), de modo que la lista y el endpoint no pueden discrepar:

```json
{
  "required": true,
  "dependent": true,
  "guardian_linked": false,
  "guardianship_id": "uuid",
  "status": "pending",
  "evidence_uploaded": true,
  "guardians": [{ "display_name": "Club Estella", "relationship_type_name": null, "is_primary": true }],
  "viewer_can_verify": false,
  "viewer_verify_block": "self_custodian"
}
```

| Campo | Valores | Significado |
| --- | --- | --- |
| `viewer_can_verify` | `true` / `false` | `true` **solo si** hay algo que verificar (el menor tiene una tutoría principal activa, no de prueba y no revocada, todavía `pending`, **y** una ficha vigente subida) y quien consulta no está impedido |
| `viewer_verify_block` | `"self_guardian"`, `"self_custodian"` o `null` | `self_guardian`: quien consulta tiene **cualquier** tutoría no revocada del menor (los datos de prueba cuentan, igual que en `verify-consent`). `self_custodian`: la tutoría principal es de custodia **y** quien consulta subió la ficha vigente, creó al menor o es el tutor de la **última** cesión (las cesiones más antiguas no impiden). Si se cumplen las dos, gana `self_guardian` |

- `viewer_can_verify = false` con `viewer_verify_block = null` significa **nada que verificar todavía** (sin ficha subida, ya verificado, sin tutoría principal, o un adolescente que se registró solo y no tiene `dependent_profiles`). `viewer_verify_block` es `null` incluso para quien creó al menor hasta que exista una ficha.
- No dice nada de **permisos** (listar exige `club_members:approve` **o** `consent:verify`; un revisor solo-verificación ve únicamente las filas con trabajo de verificación, es decir `viewer_can_verify = true` o `viewer_verify_block` distinto de `null`) y nunca expone los ids de creador, de quien subió la ficha ni de la cesión. Los adultos siguen con `consent: null`.
- Es una **pista para la interfaz**: la autoridad sigue siendo `verify-consent` (403). Es una instantánea del momento de la consulta: quien sube la ficha después de cargar la lista pasa a ser el subidor vigente.
- Costo: constante por página. La consulta de la página también lee quién subió la ficha y quién creó al menor; se añaden una consulta de las tutorías de quien consulta y otra de las cesiones (solo si hay candidatos de custodia), y se omiten si ninguna solicitud tiene tutoría principal pendiente con ficha.

### Código de reclamo para un menor bajo custodia

`POST /club-sections/:clubSectionId/dependents/:userId/claim-codes` (sección `guardianships`, **sin cambios de contrato** en la 3c) sirve ahora también para los menores que registra un director: exige `club_members:approve` en la sección (no `dependents:create` ni `consent:verify`), el menor debe tener perfil de dependiente sin congelar y una asignación `pending` o `active` en esa sección, y ningún tutor activo (si ya lo hay, 409 `GUARDIANSHIP_ALREADY_GUARDIAN`; si no cumple, 404 `GUARDIANSHIP_NOT_FOUND`). Código `XXXX-XXXX`, 7 días, 10 por hora.

Al canjearlo (`POST /guardianships/link-codes/redeem`, propósito `director_claim`) el comportamiento de la Fase 2 **no cambió**, tampoco para un menor de 13 a 17 años:

- El adulto que canjea queda como tutor **principal**, de persona (no custodia), en consentimiento **`pending`**: la verificación **no se hereda**. La fila de custodia del club pasa a `revoked` con `revoked_reason = claimed`.
- El creador original **sí puede** verificar la ficha **nueva del tutor**: la regla de cuatro ojos de custodia aplica solo a las filas de custodia (decisión P3-A26). Sigue sin poder si es tutor vigente del menor.
- Un menor de 13 a 17 años reclamado puede después recibir acceso propio (`supervised-login`), pero solo con el tutor ya **verificado**.
- `director_claim` solo existe para menores **sin cuenta**; si el menor ya tiene una, el canje responde el 400 uniforme.

### Solicitud vencida de un menor en custodia

El cron de membresía (`expireStaleRequests`, `MembershipRequestsService`) sigue venciendo las solicitudes `pending` (para un menor con consentimiento sin verificar, a los 30 días como mínimo; ver «Expiración»). **Nuevo en la 3c** (ruling P3-A18): cuando vence la solicitud de un menor que solo tiene la **custodia del club** (sin ningún tutor de persona, ni siquiera `pending` o con una reclamación en curso, y sin otra membresía `pending` o `active`), el menor se **congela** con el calendario de la Fase 2: `dependent_profiles.frozen_at = now`, `purge_after = now + 90 días`, se revocan sus dispositivos (`dependent_frozen`) y se sube el `epoch`. El cron `dependent-profiles-purge` lo anonimiza después. Un menor con tutor, o con otra membresía, no se toca. Los candados de dependiente se toman **antes** de la escritura masiva (el orden contrario podría bloquearse con `approve`).

### Cron `family-age-transitions`

`FamilyAgeTransitionsCronService` (`src/guardianships/family-age-transitions-cron.service.ts`, registrado en `GuardianshipsModule`). `@Cron('0 14 * * *')` en UTC, nombre de trabajo `family-age-transitions`, candado `cron:family-age-transitions` de 23 horas, lotes de 100 (cursor por id), registrado en `CronRunLogger` (una corrida omitida por el candado también queda anotada). Es idempotente; si hubo fallos en algún envío o revocación la corrida se registra como fallida. Tiene dos fases:

1. **Aviso a los 13 años (nudge)**. Candidatos: usuarios activos **sin cuenta** y con fecha de nacimiento, con `dependent_profiles` sin congelar ni purgar, `teen_login_nudged_at IS NULL` y sin acceso propio habilitado (sin fila `supervised_logins` o desactivado), cuya edad, en la política y la zona horaria de su país, sea `>=` la edad mínima de acceso propio y `<` la mayoría de edad. Se usa `>=`, no «cumple hoy», para que un día de cron perdido se recupere solo.
   - **Destinatarios**: los que da `GuardianSecurityNotificationsService.recipientsOf` (tutores activos, no de prueba, no custodia, con tutoría **verificada**, máximo 4). Un menor con tutoría `pending`, solo con custodia del club o sin tutor se **omite** y queda en NULL: se le avisará cuando haya un tutor verificado.
   - **Mensaje**: push y bandeja, nunca correo; fuente `family:age_nudge` (categoría `reminders`); `data.type = dependent_age_milestone` (con `event: age_milestone` y `dependent_user_id`); título «{Nombre} ya puede tener su propio acceso» y cuerpo «Puedes activar el inicio de sesión propio de {Nombre} desde su perfil.». No incluye edad ni fecha de nacimiento.
   - **Una sola vez**: la corrida **reclama** `teen_login_nudged_at = now` con un compare-and-set (`updateMany` con `teen_login_nudged_at IS NULL`) **antes** de enviar, así que dos instancias o un reintento no pueden avisar dos veces. Si **todos** los envíos fallan, se libera la marca y se cuenta como fallo (se reintenta mañana); con al menos un envío logrado la marca se queda.
   - **Bandera**: con `FAMILY_TEEN_LOGIN_ENABLED` apagada la fase ni lee candidatos: no envía ni marca nada.
2. **Barrido de dispositivos vinculados** (**sin** bandera: el mantenimiento debe correr aunque la bandera esté apagada). Recorre los dispositivos activos: si el menor ya tiene la **mayoría de edad** (zona horaria del país) se revoca con motivo `majority`; si pasó `absolute_expires_at` (180 días) con motivo `expired`; `majority` gana a `expired`. Un niño que cumple 13 años **no** se revoca. Un dispositivo cuyo menor no tiene fecha de nacimiento se deja a la compuerta por petición, que lo revoca como `majority` (falla cerrada). Usa `LinkedDevicesService.revokeBySystem`, que revoca en una transacción con el candado del menor y la fecha de nacimiento releída bajo el candado (`majority`), o con el tope releído en el `WHERE` (`expired`).
   - **Aviso a los tutores (ruling W6)**: los motivos `majority` y `expired` avisan a los tutores verificados restantes con `family:security` «{nombre} · dispositivo desvinculado» y una frase propia («{nombre} ya tiene la edad para usar su propia cuenta.» / «La vinculación venció después de 180 días; puedes vincularlo de nuevo.»). **Una sola vez**, gane el barrido o la compuerta por petición (el aviso sale de quien logra el compare-and-set de la revocación). Para `majority` se salta el corte habitual «los avisos paran a la mayoría de edad», porque es justo el caso. Los motivos `teen_login_enabled` y `dependent_frozen` siguen sin avisar.

### Pushes: `data.type` frente a fuentes `family:*`

El servidor usa dos vocabularios y la app entiende **ambos** (`lib/core/notifications/family_push_route.dart`). La **fuente** (`source`, la categoría de preferencias y la bandeja) es `family:*`; el `data.type` del payload del push es otro nombre:

| Fuente de la notificación | `data.type` realmente enviado | Quién lo recibe |
| --- | --- | --- |
| `family:security` | `dependent_security` (con `event`, p. ej. `teen_login_disabled`, `device_paired`, `device_revoked`, y `dependent_user_id`) | Tutores verificados del menor |
| `family:evidence_uploaded` | `dependent_evidence_uploaded` | Tutores verificados del menor |
| `family:age_nudge` (3c) | `dependent_age_milestone` | Tutores verificados del menor |
| `family:teen_reminder` | `teen_guardian_reminder` (con `days_left`) | El adolescente sin tutor |
| `family:guardian_linked` | `teen_guardian_linked` | El adolescente, cuando un adulto se vincula |

La tabla lista los cinco `data.type` que la app enruta al tocar un push de familia; las demás fuentes `family:*` (`family:consent_verified`, `family:custody_transferred`) y el aviso a revisores (`membership_requests:new_request`) no entran en ese ruteo.

### Acceso familiar en el detalle de usuario y acciones del panel

Solo para el panel (`sacdia-admin`). Todo con el envoltorio `{ status: 'success', data }`.

**`GET /api/v1/admin/users/:userId` → `data.family_access`** (junto a `guardianships`). Es `null` si el actor no puede leer la familia sensible `legal_representative` (permiso `legal_representative:read`, o el respaldo `users:read_detail` hasta 2027-03-31); un usuario sin acceso ni dispositivos recibe el bloque vacío `{ "supervision": null, "supervised_login": null, "linked_devices": [] }`.

```json
{
  "supervision": "active",
  "supervised_login": {
    "status": "active",
    "method": "handle",
    "login_handle": "mateo-k3j9q2xz",
    "origin": "guardian_enabled",
    "enabled_at": "2026-10-20T15:00:00.000Z",
    "enabled_by": { "user_id": "uuid", "display_name": "María Pérez" },
    "disabled_at": null,
    "disabled_reason": null,
    "password_set_by": "guardian",
    "pending_since": null
  },
  "linked_devices": [
    {
      "linked_device_id": "uuid",
      "label": "iPhone de Sofi",
      "platform": "ios",
      "app_version": "1.4.0",
      "status": "active",
      "paired_by": { "user_id": "uuid", "display_name": "María Pérez" },
      "paired_at": "2026-10-20T15:00:00.000Z",
      "last_seen_at": null,
      "absolute_expires_at": "2027-04-18T15:00:00.000Z",
      "revoked_at": null,
      "revoked_reason": null
    }
  ]
}
```

- `supervision` es `pending_guardian` o `active` (o `null` si no hay acceso propio). Se deriva del acceso guardado y de una tutoría `verified` real (no de prueba, no revocada; la custodia cuenta). **No considera la edad.**
- `supervised_login.status` es `active`, `pending_guardian` o `disabled`; `disabled_reason` es `guardian`, `admin` o `unlinked_purged`. `login_handle` solo llega con el permiso sensible (nunca el correo); en un acceso por correo es `null`.
- `linked_devices` incluye los activos y los revocados en los últimos 30 días, del más reciente al más antiguo; `status` es `active` o `revoked`.
- `GET /admin/users/:userId/sessions` (sección `admin-auth`) ya trae `kind: "user" | "device"` y `linkedDeviceId` (camelCase) desde la 3b; la 3c no lo cambia.

**`POST /api/v1/admin/users/:userId/supervised-login/disable`** — corta el acceso propio de un menor. Controller `AdminUsersController` (clase `@GlobalRoles('admin','super-admin')`), `@RequirePermissions('users:update_admin')` con `@SensitiveUserSubresource('legal_representative','update')` (permiso `legal_representative:update`, con el respaldo `users:update_profile` hasta 2027-03-31), recorte territorial del actor antes de actuar. Responde **200**.

- Cuerpo `{ "reason": "..." }`: el motivo es **obligatorio**, recortado, de **5 a 500** caracteres, y es la **única** clave aceptada (cualquier otra, 400).
- Efectos iguales a los del tutor: se borran todas las sesiones, la siguiente petición del menor es 401 `AUTH_SUPERVISED_ACCESS_REVOKED`, se sube el `epoch` y se avisa a **todos** los tutores verificados (`family:security`, «acceso desactivado»). El motivo escrito **solo** queda en la fila de auditoría `admin.supervised_login.disabled` (`changes: { reason, sessions_revoked }`, actor = el admin); `disabled_reason` queda en `admin` y `disabled_by_user_id` en el admin. **No** se guarda en el acceso, no se muestra al menor ni a los tutores.
- No depende de `FAMILY_TEEN_LOGIN_ENABLED` ni de la edad, y es **idempotente**. No crea filas.
- Respuesta: `{ "supervised_login": { "status": "disabled", "method", "origin", "enabled_at", "disabled_at", "disabled_reason": "admin", "password_set_by" } }` (nunca el nombre de usuario ni el correo).
- Errores: 400 (motivo ausente, corto, largo o clave extra), 403 (sin permisos), 404 `ADMIN_USER_NOT_FOUND` (también fuera del alcance territorial), 404 `SUPERVISED_LOGIN_NOT_FOUND` (el usuario no tiene acceso propio).

**`POST /api/v1/admin/users/:userId/linked-devices/:deviceId/revoke`** — desvincula un dispositivo. Mismos permisos, alcance y cuerpo que el anterior; `:deviceId` es un UUID. Responde **200**.

- Efectos iguales a los del tutor (sesión borrada, limpieza de FCM, `epoch`, la siguiente petición del teléfono es 401 `AUTH_DEVICE_REVOKED`, aviso `family:security` «dispositivo desvinculado» a **todos** los tutores verificados). Una sola fila de auditoría `admin.linked_device.revoked` con `changes: { reason, revoked_reason: 'admin', label, platform }`; el dispositivo queda con `revoked_reason = admin`.
- Respuesta: `{ "linked_device_id", "revoked_at", "revoked_reason": "admin" }`. **Idempotente**: repetirlo devuelve los valores originales sin escribir ni avisar de nuevo.
- Errores: 400 (motivo), 403, 404 `ADMIN_USER_NOT_FOUND` o 404 `DEVICE_NOT_FOUND` (el dispositivo no existe o es de **otra familia**).

**No existe ninguna ruta de admin para habilitar, reactivar, restablecer ni leer una contraseña** del menor (las pruebas comprueban que responden 404 o 405). Corregir un acceso es cosa del tutor.

### Errores de la Fase 3c

Solo hay **un código nuevo** en `ErrorCode` y en los 4 `errors.json` (`es`, `en`, `fr`, `pt-BR`); el resto reutiliza los existentes.

| Status | `code` | Cuándo |
| --- | --- | --- |
| 403 | `MR_APPROVE_PERMISSION_REQUIRED` | `verify-consent` con `approve: true` sin `club_members:approve` (solo `consent:verify`, incluida la vía de coordinador) |
| 403 | `GUARDIANSHIP_CUSTODIAN_SELF_VERIFY` | Verifica quien creó al menor, subió la ficha vigente o cedió al menor (custodia del club) |
| 403 | `GUARDIANSHIP_GUARDIAN_SELF_VERIFY` | Verifica un tutor vigente del menor |
| 409 | `MR_CONSENT_NOT_VERIFIED` | Aprobar mientras el consentimiento sigue `pending` |
| 422 | `GUARDIANSHIP_DEPENDENT_AGE_OUT_OF_RANGE` | Registrar un menor con edad fuera de `0 <= edad < mayoría de edad del país de la sección` |
| 500 | `POST_REG_NO_ACTIVE_YEAR` | Registrar un menor sin año eclesiástico vigente (no se crea nada) |
| 404 | `FAMILY_FEATURE_DISABLED` | Registrar un menor con `FAMILY_DIRECTOR_CREATE_MINOR_ENABLED` apagada |
| 404 | `SUPERVISED_LOGIN_NOT_FOUND` | Desactivar desde el panel un usuario sin acceso propio |
| 404 | `DEVICE_NOT_FOUND` | Revocar desde el panel un dispositivo inexistente o de otra familia |

### Bandera `FAMILY_DIRECTOR_CREATE_MINOR_ENABLED`

Por defecto `false` (`config/env.validation.ts`; se lee del arranque como las otras dos: cambiarla exige reiniciar). Solo gobierna el `POST /club-sections/:clubSectionId/dependents`. Apagada no se deshace nada. Las valida `env.validation.ts` y las comprueba la prueba de cableado `family-phase3c.wiring.spec.ts`. `.env.example` no pudo leerse ni editarse durante la implementación (regla de denegación del agente): comprobar a mano que liste las tres banderas `FAMILY_*` antes de abrir el PR.

## Resumen por dominio

Conteo de filas por sección de la matriz. Las filas marcadas como pendientes de merge no cuentan en el total de `development`. Las secciones de perfiles familiares (`guardianships`, `admin-users`, `membership-requests`, `post-registration`) y `legal-representatives` (3 rutas retiradas) ya reflejan la rama `feat/family-profiles`.

| Dominio/API tag | Endpoints |
| --- | ---: |
| Achievements | 4 |
| Admin - Achievements | 12 |
| activities | 16 |
| admin-auth | 6 |
| admin-camporee-event-types | 4 |
| admin | 2 |
| admin-audit-logs | 2 |
| admin-geography | 24 |
| admin-honor-instructor-proposals | 3 |
| Admin - Honors Requirements | 7 |
| admin-notifications | 3 |
| Admin - Phase E Catalogs (i18n) | 36 |
| admin-reference | 38 |
| admin-users | 8 |
| analytics | 8 |
| Annual Evidence Folders | 13 |
| Annual Evidence Folders - Templates | 9 |
| Award Categories | 5 |
| Annual Evidence Folders - Evaluation | 5 |
| Annual Evidence Folders - Rankings | 4 |
| annual-reports | 9 |
| app.controller.ts | 1 |
| auth | 20 |
| OAuth | 3 |
| camporee-event-templates | 5 |
| camporee-events | 16 |
| camporee-scoring | 20 (el `GET .../score` entró con el PR #448) |
| camporee-staff | 8 |
| camporee-venues | 9 |
| camporees | 50 |
| catalogs | 16 |
| admin-certificate-bulk-imports | 6 |
| certificate-bulk-imports | 15 |
| certificate-import-institutional-requests | 3 |
| admin-certificate-import-institutional-requests | 4 |
| certifications | 27 |
| Admin - Certifications | 10 |
| class-counselor-assignments | 4 |
| class-progress-scope | 2 |
| class-thresholds | 2 |
| investiture-windows | 2 |
| investiture-pastors | 6 |
| investiture-requests | 8 |
| classes | 4 |
| user-classes | 7 |
| club-enrollments | 7 |
| clubs | 20 |
| club-roles | 2 |
| admin-coordination | 9 |
| coordination | 1 |
| dashboard | 1 |
| data-export | 3 |
| emergency-contacts | 5 |
| evidence-review | 7 |
| finances | 9 |
| guardianships | 17 |
| health | 2 |
| honors | 5 |
| user-honors | 17 |
| user-master-honors | 3 |
| instructors | 1 |
| insurance | 18 |
| field-payment-orders | 19 |
| camporee order products | 6 |
| camporee order offerings | 6 |
| camporee orders | 14 |
| payment obligations | 1 |
| camporee supplies | 29 |
| inventory | 8 |
| investiture | 20 |
| legal | 3 |
| legal-representatives | 1 |
| Materials — Catalog | 4 |
| Materials — Categories (admin) | 4 |
| Materials — Config | 4 |
| Materials — Inventory | 5 |
| Materials — Orders | 8 |
| Materials — Receipts | 4 |
| member-of-month | 4 |
| annual-membership | 3 |
| membership-requests | 6 |
| monthly-reports | 10 |
| Notifications | 10 |
| FCM Tokens | 5 |
| User Notification Preferences | 4 |
| supervision (adolescente) | 3 |
| post-registration | 8 |
| qr | 6 |
| quarterly-reports | 9 |
| Ranking Weights | 5 |
| Annual Ranking Configs | 4 |
| Annual Ranking Progress | 1 |
| Annual Rankings | 1 |
| Ranking Tiers | 2 |
| Member Ranking Weights | 5 |
| Member Rankings | 4 |
| Section Rankings | 2 |
| rbac | 19 |
| rbac-bootstrap | 1 |
| requests | 8 |
| resource-categories | 5 |
| Resources (App) | 3 |
| Resources | 8 |
| scoring-categories | 12 |
| admin-support | 3 |
| support | 1 |
| system-config | 3 |
| units | 11 |
| users | 15 |
| validation | 5 |
| year-end | 2 |

## Endpoint matrix

### Achievements

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/achievements/me` | JWT | - | Get current user's achievements with progress | AchievementsService.getUserAchievements() | `src/achievements/achievements.controller.ts` |
| GET | `/api/v1/achievements/categories` | JWT | - | List active achievement categories | AchievementsService.findActiveCategories() | `src/achievements/achievements.controller.ts` |
| GET | `/api/v1/achievements` | JWT | - | List all active achievements grouped by category | AchievementsService.findAllAchievements(), AchievementsService.getCompletedAchievementIds() | `src/achievements/achievements.controller.ts` |
| GET | `/api/v1/achievements/:achievementId` | JWT | - | Get achievement detail with user progress | AchievementsService.getAchievementDetail() | `src/achievements/achievements.controller.ts` |

### Admin - Achievements

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/achievements/stats` | JWT | Global: admin, super-admin; Permisos: achievements:manage | Get achievement dashboard stats | AdminAchievementsService.getStats() | `src/achievements/admin/admin-achievements.controller.ts` |
| GET | `/api/v1/admin/achievements/categories` | JWT | Global: admin, super-admin; Permisos: achievements:manage | List all achievement categories (admin view) | AdminAchievementsService.getCategories() | `src/achievements/admin/admin-achievements.controller.ts` |
| POST | `/api/v1/admin/achievements/categories` | JWT | Global: admin, super-admin; Permisos: achievements:manage | Create a new achievement category | AdminAchievementsService.createCategory() | `src/achievements/admin/admin-achievements.controller.ts` |
| PATCH | `/api/v1/admin/achievements/categories/:categoryId` | JWT | Global: admin, super-admin; Permisos: achievements:manage | Update an achievement category | AdminAchievementsService.updateCategory() | `src/achievements/admin/admin-achievements.controller.ts` |
| DELETE | `/api/v1/admin/achievements/categories/:categoryId` | JWT | Global: admin, super-admin; Permisos: achievements:manage | Soft-delete a category | AdminAchievementsService.deleteCategory() | `src/achievements/admin/admin-achievements.controller.ts` |
| GET | `/api/v1/admin/achievements` | JWT | Global: admin, super-admin; Permisos: achievements:manage | List all achievements (admin view, paginated) | AdminAchievementsService.getAchievements() | `src/achievements/admin/admin-achievements.controller.ts` |
| POST | `/api/v1/admin/achievements` | JWT | Global: admin, super-admin; Permisos: achievements:manage | Create a new achievement | AdminAchievementsService.createAchievement() | `src/achievements/admin/admin-achievements.controller.ts` |
| GET | `/api/v1/admin/achievements/:achievementId` | JWT | Global: admin, super-admin; Permisos: achievements:manage | Get a single achievement by ID (admin view) | AdminAchievementsService.getAchievementById() | `src/achievements/admin/admin-achievements.controller.ts` |
| PATCH | `/api/v1/admin/achievements/:achievementId` | JWT | Global: admin, super-admin; Permisos: achievements:manage | Update an achievement | AdminAchievementsService.updateAchievement() | `src/achievements/admin/admin-achievements.controller.ts` |
| DELETE | `/api/v1/admin/achievements/:achievementId` | JWT | Global: admin, super-admin; Permisos: achievements:manage | Soft-delete an achievement | AdminAchievementsService.deleteAchievement() | `src/achievements/admin/admin-achievements.controller.ts` |
| POST | `/api/v1/admin/achievements/:achievementId/image` | JWT | Global: admin, super-admin; Permisos: achievements:manage | Upload badge image for an achievement | AdminAchievementsService.uploadBadgeImage() | `src/achievements/admin/admin-achievements.controller.ts` |
| POST | `/api/v1/admin/achievements/retroactive/:achievementId` | JWT | Global: admin, super-admin; Permisos: achievements:manage | Trigger retroactive achievement evaluation | AdminAchievementsService.triggerRetroactiveEvaluation() | `src/achievements/admin/admin-achievements.controller.ts` |

### activities

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/clubs/:clubId/activities` | JWT | Permisos: activities:read | Listar actividades del club | ActivitiesService.findByClub() | `src/activities/activities.controller.ts` |
| POST | `/api/v1/clubs/:clubId/activities` | JWT | Permisos: activities:create; Club: director, deputy-director, secretary, secretary-treasurer, counselor | Crear actividad | ActivitiesService.create() | `src/activities/activities.controller.ts` |
| POST | `/api/v1/clubs/:clubId/activity-series/preview` | JWT | Permisos: activities:create; Club: director, deputy-director, secretary, secretary-treasurer, counselor | Vista previa de serie de actividades | ActivitiesService.previewActivitySeries() | `src/activities/activities.controller.ts` |
| POST | `/api/v1/clubs/:clubId/activity-series` | JWT | Permisos: activities:create; Club: director, deputy-director, secretary, secretary-treasurer, counselor | Crear serie de actividades | ActivitiesService.createActivitySeries() | `src/activities/activities.controller.ts` |
| GET | `/api/v1/activity-series/:seriesId` | JWT | Permisos: activities:read | Obtener serie de actividades | ActivitiesService.findActivitySeries() | `src/activities/activities.controller.ts` |
| POST | `/api/v1/activity-series/:seriesId/cancel-future` | JWT | Permisos: activities:delete | Cancelar sesiones futuras de una serie | ActivitiesService.cancelFutureActivitySeries() | `src/activities/activities.controller.ts` |
| POST | `/api/v1/activity-series/:seriesId/extend` | JWT | Permisos: activities:create | Agregar más sesiones a una serie | ActivitiesService.extendActivitySeries() | `src/activities/activities.controller.ts` |
| GET | `/api/v1/activities/:activityId` | JWT | Permisos: activities:read | Obtener actividad por ID | ActivitiesService.findOne() | `src/activities/activities.controller.ts` |
| PATCH | `/api/v1/activities/:activityId` | JWT | Permisos: activities:update | Actualizar actividad | ActivitiesService.update() | `src/activities/activities.controller.ts` |
| DELETE | `/api/v1/activities/:activityId` | JWT | Permisos: activities:delete | Desactivar actividad | ActivitiesService.remove() | `src/activities/activities.controller.ts` |
| POST | `/api/v1/activities/:activityId/image` | JWT | Permisos: activities:update | Subir imagen de actividad | ActivitiesService.uploadImage() | `src/activities/activities.controller.ts` |
| POST | `/api/v1/activities/:activityId/attendance` | JWT | Permisos: attendance:manage | Registrar asistencia confirmada. En virtual solo miembros de la sección | ActivitiesService.recordAttendance() | `src/activities/activities.controller.ts` |
| GET | `/api/v1/activities/:activityId/attendance` | JWT | Permisos: attendance:read | Obtener asistencia confirmada | ActivitiesService.getAttendance() | `src/activities/activities.controller.ts` |
| GET | `/api/v1/activities/:activityId/rsvp` | JWT | Permisos: activities:read | Intención de asistencia del usuario (solo virtual) | ActivitiesService.getMyRsvp() | `src/activities/activities.controller.ts` |
| PUT | `/api/v1/activities/:activityId/rsvp` | JWT | Permisos: activities:read | Marcar going o not_going. No confirma asistencia | ActivitiesService.setRsvp() | `src/activities/activities.controller.ts` |
| GET | `/api/v1/activities/:activityId/attendance-roster` | JWT | Permisos: attendance:manage | Miembros de la sección con intención y confirmación (solo virtual) | ActivitiesService.getAttendanceRoster() | `src/activities/activities.controller.ts` |

### admin-auth

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/users/:userId/sessions` | JWT | Global: USER_MANAGEMENT_ROLES (admin + lf/union/dia); Permisos: users:read_detail; recorte territorial | List all active sessions for a user | AdminAuthService.listUserSessions() | `src/admin/admin-auth.controller.ts` |
| DELETE | `/api/v1/admin/users/:userId/sessions/:sessionId` | JWT | Global: USER_MANAGEMENT_ROLES; Permisos: users:read_detail; recorte territorial | Revoke a specific session for a user | AdminAuthService.revokeUserSession() | `src/admin/admin-auth.controller.ts` |
| DELETE | `/api/v1/admin/users/:userId/sessions` | JWT | Global: USER_MANAGEMENT_ROLES; Permisos: users:read_detail; recorte territorial | Revoke all sessions for a user | AdminAuthService.revokeAllUserSessions() | `src/admin/admin-auth.controller.ts` |
| GET | `/api/v1/admin/users/:userId/mfa/status` | JWT | Global: admin, super-admin; Permisos: users:update_admin | Get MFA enrollment status for a user | AdminAuthService.getUserMfaStatus() | `src/admin/admin-auth.controller.ts` |
| DELETE | `/api/v1/admin/users/:userId/mfa` | JWT | Global: admin, super-admin; Permisos: users:update_admin | Reset (disable) MFA for a user | AdminAuthService.resetUserMfa() | `src/admin/admin-auth.controller.ts` |
| POST | `/api/v1/admin/users/:userId/password` | JWT | Global: admin, super-admin; Permisos: users:update_admin | Set a new password for a user | AdminAuthService.setUserPassword() | `src/admin/admin-auth.controller.ts` |

### admin-camporee-event-types

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/camporee-event-types` | JWT | Global: admin, super-admin; Permisos: camporee_event_types:read | List camporee event types | AdminCamporeeEventTypesService.listCamporeeEventTypes() | `src/admin/admin-camporee-event-types.controller.ts` |
| POST | `/api/v1/admin/camporee-event-types` | JWT | Global: admin, super-admin; Permisos: camporee_event_types:create | Create camporee event type | AdminCamporeeEventTypesService.createCamporeeEventType() | `src/admin/admin-camporee-event-types.controller.ts` |
| PATCH | `/api/v1/admin/camporee-event-types/:eventTypeId` | JWT | Global: admin, super-admin; Permisos: camporee_event_types:update | Update camporee event type | AdminCamporeeEventTypesService.updateCamporeeEventType() | `src/admin/admin-camporee-event-types.controller.ts` |
| DELETE | `/api/v1/admin/camporee-event-types/:eventTypeId` | JWT | Global: admin, super-admin; Permisos: camporee_event_types:delete | Soft delete camporee event type | AdminCamporeeEventTypesService.deleteCamporeeEventType() | `src/admin/admin-camporee-event-types.controller.ts` |

### admin

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/cron-alerts` | JWT | Global: admin, super-admin | Paginated cron alert history | AdminCronAlertsService.getAlertHistory() | `src/admin/admin-cron-alerts.controller.ts` |
| POST | `/api/v1/admin/cron-alerts/:id/resolve` | JWT | Global: admin, super-admin; Global: super-admin | Manually resolve a cron alert (super-admin only) | AdminCronAlertsService.resolveAlert() | `src/admin/admin-cron-alerts.controller.ts` |
| GET | `/api/v1/admin/cron-jobs` | JWT | Global: super-admin | Listar los jobs programados que se pueden ejecutar bajo demanda (mergeada en `development`, PR #535 de sacdia-backend; rama `feat/admin-run-cron-now`) | AdminCronJobsService.list() | `src/admin/cron-jobs/admin-cron-jobs.controller.ts` |
| POST | `/api/v1/admin/cron-jobs/:jobName/run` | JWT | Global: super-admin (límite 10 por minuto) | Ejecutar ahora un job programado y esperar su resultado (mergeada en `development`, PR #535 de sacdia-backend; rama `feat/admin-run-cron-now`) | AdminCronJobsService.run() | `src/admin/cron-jobs/admin-cron-jobs.controller.ts` |

#### Jobs programados bajo demanda («Ejecutar ahora»)

> [!NOTE]
> Rama `feat/admin-run-cron-now` de sacdia-backend (commits `2bacda55` y `bb57a925`) y de sacdia-admin (commits `34d9e4e`, `ac40318`, `1c21151` y `5026a0a`), **mergeadas en `development` (PR #535 de sacdia-backend y PR #247 de sacdia-admin, 2026-10-21)**. Verificado contra el código de las ramas (`src/admin/cron-jobs/*`, `src/common/services/cron-run-context.ts`, `cron-run-logger.service.ts`, `src/analytics/cron-runs.service.ts`). Sin cambios de esquema. Las filas no cuentan en los totales de la cabecera.

Un **super-admin** puede disparar un `@Cron` sin esperar a su hora. Hace falta porque el servicio `development` está en el plan Free de Render, que se suspende por inactividad y entonces **ningún cron en proceso corre** (ver `docs/deployment/DEPLOYMENT-GUIDE.md`, §0.1 y §0.6); en desarrollo este es el camino para ejecutarlos. Guards: `JwtAuthGuard` + `GlobalRolesGuard` con `@GlobalRoles('super-admin')` y `@SkipPermissions()`. Sin `@ActingScope`: un tutor actuando, un adolescente supervisado o un dispositivo no pasan.

**`GET /api/v1/admin/cron-jobs`** devuelve `{ status: 'success', data: { jobs: [...] } }`. Cada job: `job_name`, `schedule` (cron de **5 campos**, normalizado: sin segundos ni ceros a la izquierda; sale de los metadatos del propio `@Cron`, no se repite a mano), `time_zone` (`null` si el `@Cron` no declara zona horaria), `runnable` (`false` si el proveedor dueño no está cargado en esta app) y `description` (español).

**`POST /api/v1/admin/cron-jobs/:jobName/run`** (200, sin cuerpo; `@Throttle` de 10 por minuto):

- Ejecuta el **mismo método** que invoca el scheduler, con el **mismo candado** que la ejecución programada (`cron-run:<job>` en los jobs del candado de corrida compartido; `cron:<job>` en los que tienen candado propio; ver `docs/features/cron-automation.md`) y la **misma fila** en `cron_run_log`, y **espera** a que termine. La fila queda marcada con `metadata.trigger = 'manual'` y `metadata.triggered_by = <user_id del super-admin>`.
- **Allowlist** de 20 jobs (todos los `@Cron` del código; `cron-job.registry.spec.ts` falla si aparece o desaparece uno sin entrada, así que añadir un job es una decisión revisada). No hay invocación dinámica por nombre. Un nombre desconocido, fuera de la lista o cuyo proveedor no esté cargado responde 404 `CRON_JOB_NOT_FOUND`.
- **Solape**: si el candado del job ya está tomado (por el scheduler o por otra ejecución manual), la respuesta es `status: "skipped"` y se escribe una fila `skipped`, con `reason` (`run_lock_held` en los jobs del candado de corrida compartido). No hay un candado manual aparte: la ejecución manual y la programada comparten la misma clave.
- **Auditoría**: cada llamada que llega al servicio registra `admin.cron_job.run` (`entity_type: cron_job`, `entity_id: <job>`, `result: succeeded | failed`, y en `changes` el `job_name`, `status`, `run_id`, `items_processed`, `duration_ms` y `error_message`). Un 404 no audita.
- **Respuesta** `{ status: 'success', data }` con `job_name`, `run_id` (`null` si el job no escribe fila o solo encoló), `status` (`completed | failed | skipped`), `items_processed`, `duration_ms`, `error_message` y `enqueued`.
- **`enqueued: true`**: los tres jobs respaldados por BullMQ (`monthly-reports-auto-generate`, `rankings-recalculate`, `finance-period-closing`) solo **encolan** el trabajo cuando hay Redis; el worker lo termina después y escribe su propia fila (marcada manual por el `manualTriggeredBy` del payload). La respuesta llega antes de que termine: `run_id` es `null` y el resultado se ve en el historial. Sin Redis, el job corre en línea como siempre y se espera.
- Los handlers tragan sus propios errores, así que el resultado se lee del `CronRunLogger` (mediante `AsyncLocalStorage`). Si un handler lanza, el resultado es `failed` con el mensaje.

**`GET /api/v1/admin/analytics/cron-runs`**: cada elemento de `recent[]` suma `trigger` (`'manual' | 'scheduled'`; las filas anteriores y las programadas son `scheduled`) y `triggered_by` (`user_id` del super-admin o `null`). `stats[]` no cambia y `recent` sigue siendo la **última** fila por job: una ejecución manual reemplaza a la programada en esa vista. El historial (`/cron-runs/history`) ya devolvía `metadata`, donde viaja el marcador.

**Notas operativas**

- **Notificaciones reales.** Ejecutar un job en `development` corre la lógica de producción contra los datos reales de esa base: no hay modo de prueba. Los jobs que envían push, bandeja o correo a personas (por lectura del código; ver la lista abajo) pueden **notificar de verdad**. Los más sensibles: `activities-reminder` (push a la sección por cada actividad en ventana) y `cron-alert-check` (correo y aviso a los super-admin). Antes de ejecutar uno de esta lista, confirma que los destinatarios son de prueba.
- **Jobs de larga duración y tiempo de espera HTTP.** La petición dura lo que dure el job. El middleware global responde **408** a los 30 s por defecto (`REQUEST_TIMEOUT_MS`), pero **no cancela** el trabajo: sigue en el servidor, conserva el candado hasta terminar, escribe su fila y la auditoría. Detrás de Render también puede cortar la conexión un proxy (502/504). El panel trata 408/502/504 como «la ejecución sigue en el servidor» y refresca el historial pasados unos segundos. Con un cliente propio, no reintentes por un 408: consulta el historial.
- **Datos que se modifican.** Son los mismos efectos que el cron: `ecclesiastical-year-cut` termina cargos, `dependent-profiles-purge` borra datos de perfiles congelados vencidos, `finance-period-closing` cierra periodos, `data-export-cleanup` borra archivos. Ejecutarlos fuera de hora es válido, pero no es una simulación.
- **Panel.** `/dashboard/system/jobs` muestra el botón «Ejecutar ahora» (con `AlertDialog` de confirmación) solo a un super-admin y en los **20 jobs del catálogo** (`GET /admin/cron-jobs`; el panel muestra y ejecuta todos). Muestra la insignia «Manual» en las filas manuales y avisa «En cola» cuando `enqueued` es `true`.

Jobs de la allowlist y qué envían (lectura estática del código de la rama, siguiendo el job y su servicio directo; no se ejecutó ninguno y un envío más profundo en la cadena, por ejemplo desde un procesador de BullMQ, puede no estar en la lista):

| Job | Envía a personas |
| --- | --- |
| `activities-reminder` | Push a la sección por cada actividad próxima |
| `cron-alert-check` | Correo y notificación en la app a los super-admin si otro job falla o deja de correr (además registra la alerta) |
| `monthly-reports-reminders` | Push por rol de sección (solo en los días del ciclo) |
| `member-of-month-auto-evaluate` | Aviso al miembro elegido y a los directores |
| `pending-teen-guardian` | Push y bandeja al adolescente (días 7, 30 y 83) |
| `family-age-transitions` | Push y bandeja a los tutores verificados |
| `investiture-authorization-reminders` | Correo de recordatorio de la autorización (condicionado por `INVESTITURE_EMAIL_ENABLED`). Además reintenta con `deliverPending()` los avisos de resultado pendientes de investidura, que salen por bandeja y push |
| `ecclesiastical-year-cut` | Aviso a `super-admin`, `admin` y a la dirección del campo local solo si omite un plan de directiva |
| Resto (`rankings-recalculate`, `annual-reports-auto-generate`, `cleanup-expired-records`, `fcm-tokens-cleanup`, `fcm-tokens-stale-cleanup`, `data-export-cleanup`, `finance-period-closing`, `dependent-profiles-purge`, `investiture-achievement-intent`, `membership-requests-expiry`, `monthly-reports-auto-generate`, `quarterly-reports-auto-generate`) | No envían avisos a personas |

`fcm-tokens-stale-cleanup` es el `cleanupOldTokens` de `FcmTokensService`; no escribe fila en `cron_run_log`. Su `@Cron` compartía el nombre `fcm-tokens-cleanup` con el de `cleanup.service.ts` y, con nombres duplicados, solo uno de los dos se programaba. Se corrigió renombrando el de `FcmTokensService` a `fcm-tokens-stale-cleanup` en la rama `feat/admin-run-cron-now` (sin hash todavía).

### admin-audit-logs

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/audit-logs` | JWT | Global: super-admin; Permisos: audit:read. Sin recorte territorial. `admin` → 403. | Listar audit logs globales (cursor `audit_log_id` desc; default 50, max 100). Query: `entity_type`, `actor_user_id`, `action`, `result`, `source`, `from`, `to`, `club_id`, `correlation_id`, `limit`, `cursor`. List no incluye `changes` ni `request_context`. | AuditLogsService.listAdmin() | `src/audit-logs/admin-audit-logs.controller.ts` |
| GET | `/api/v1/admin/audit-logs/:id` | JWT | Global: super-admin; Permisos: audit:read | Detalle con `changes` (solo dominio) y `request_context`. Nunca body de request. | AuditLogsService.getById() | `src/audit-logs/admin-audit-logs.controller.ts` |


### admin-geography

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/divisions` | JWT | Global: admin, super-admin; Permisos: countries:read | List institutional divisions for admin management | AdminGeographyService.listDivisions() | `src/admin/admin-geography.controller.ts` |
| POST | `/api/v1/admin/divisions` | JWT | Global: admin, super-admin; Permisos: countries:create | Create institutional division | AdminGeographyService.createDivision() | `src/admin/admin-geography.controller.ts` |
| PATCH | `/api/v1/admin/divisions/:divisionId` | JWT | Global: admin, super-admin; Permisos: countries:update | Update institutional division | AdminGeographyService.updateDivision() | `src/admin/admin-geography.controller.ts` |
| DELETE | `/api/v1/admin/divisions/:divisionId` | JWT | Global: admin, super-admin; Permisos: countries:delete | Soft delete institutional division | AdminGeographyService.deleteDivision() | `src/admin/admin-geography.controller.ts` |
| GET | `/api/v1/admin/countries` | JWT | Global: admin, super-admin; Permisos: countries:read | List countries for admin management | AdminGeographyService.listCountries() | `src/admin/admin-geography.controller.ts` |
| POST | `/api/v1/admin/countries` | JWT | Global: admin, super-admin; Permisos: countries:create | Create country | AdminGeographyService.createCountry() | `src/admin/admin-geography.controller.ts` |
| PATCH | `/api/v1/admin/countries/:countryId` | JWT | Global: admin, super-admin; Permisos: countries:update | Update country | AdminGeographyService.updateCountry() | `src/admin/admin-geography.controller.ts` |
| DELETE | `/api/v1/admin/countries/:countryId` | JWT | Global: admin, super-admin; Permisos: countries:delete | Soft delete country | AdminGeographyService.deleteCountry() | `src/admin/admin-geography.controller.ts` |
| GET | `/api/v1/admin/unions` | JWT | Global: admin, super-admin; Permisos: unions:read | List unions for admin management | AdminGeographyService.listUnions() | `src/admin/admin-geography.controller.ts` |
| POST | `/api/v1/admin/unions` | JWT | Global: admin, super-admin; Permisos: unions:create | Create union | AdminGeographyService.createUnion() | `src/admin/admin-geography.controller.ts` |
| PATCH | `/api/v1/admin/unions/:unionId` | JWT | Global: admin, super-admin; Permisos: unions:update | Update union | AdminGeographyService.updateUnion() | `src/admin/admin-geography.controller.ts` |
| DELETE | `/api/v1/admin/unions/:unionId` | JWT | Global: admin, super-admin; Permisos: unions:delete | Soft delete union | AdminGeographyService.deleteUnion() | `src/admin/admin-geography.controller.ts` |
| GET | `/api/v1/admin/local-fields` | JWT | Global: admin, super-admin; Permisos: local_fields:read | List local fields for admin management | AdminGeographyService.listLocalFields() | `src/admin/admin-geography.controller.ts` |
| POST | `/api/v1/admin/local-fields` | JWT | Global: admin, super-admin; Permisos: local_fields:create | Create local field | AdminGeographyService.createLocalField() | `src/admin/admin-geography.controller.ts` |
| PATCH | `/api/v1/admin/local-fields/:localFieldId` | JWT | Global: admin, super-admin; Permisos: local_fields:update | Update local field | AdminGeographyService.updateLocalField() | `src/admin/admin-geography.controller.ts` |
| DELETE | `/api/v1/admin/local-fields/:localFieldId` | JWT | Global: admin, super-admin; Permisos: local_fields:delete | Soft delete local field | AdminGeographyService.deleteLocalField() | `src/admin/admin-geography.controller.ts` |
| GET | `/api/v1/admin/districts` | JWT | Global: admin, super-admin; Permisos: local_fields:read | List districts for admin management | AdminGeographyService.listDistricts() | `src/admin/admin-geography.controller.ts` |
| POST | `/api/v1/admin/districts` | JWT | Global: admin, super-admin; Permisos: local_fields:update | Create district | AdminGeographyService.createDistrict() | `src/admin/admin-geography.controller.ts` |
| PATCH | `/api/v1/admin/districts/:districtId` | JWT | Global: admin, super-admin; Permisos: local_fields:update | Update district | AdminGeographyService.updateDistrict() | `src/admin/admin-geography.controller.ts` |
| DELETE | `/api/v1/admin/districts/:districtId` | JWT | Global: admin, super-admin; Permisos: local_fields:delete | Soft delete district | AdminGeographyService.deleteDistrict() | `src/admin/admin-geography.controller.ts` |
| GET | `/api/v1/admin/churches` | JWT | Global: admin, super-admin; Permisos: churches:read | List churches for admin management | AdminGeographyService.listChurches() | `src/admin/admin-geography.controller.ts` |
| POST | `/api/v1/admin/churches` | JWT | Global: admin, super-admin; Permisos: churches:create | Create church | AdminGeographyService.createChurch() | `src/admin/admin-geography.controller.ts` |
| PATCH | `/api/v1/admin/churches/:churchId` | JWT | Global: admin, super-admin; Permisos: churches:update | Update church | AdminGeographyService.updateChurch() | `src/admin/admin-geography.controller.ts` |
| DELETE | `/api/v1/admin/churches/:churchId` | JWT | Global: admin, super-admin; Permisos: churches:delete | Soft delete church | AdminGeographyService.deleteChurch() | `src/admin/admin-geography.controller.ts` |

### admin-honor-instructor-proposals

Cola del Campo Local para las propuestas de instructor sobre especialidades ya aprobadas. Mismo revisor y alcance que `admin-certificate-bulk-imports` (`@GlobalRoles('super-admin','admin','assistant-admin','director-lf','assistant-lf')` + `@SkipPermissions`, helper `src/common/reviewer-scope`): `super-admin` y `admin`/`assistant-admin` sin Campo Local ven todo; quien tiene Campo Local solo las propuestas cuyo dueño tiene el mismo `users.local_field_id` actual (si no, 403 `HONOR_INSTRUCTOR_PROPOSAL_FORBIDDEN`).

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/honor-instructor-proposals` | JWT | Global: super-admin, admin, assistant-admin, director-lf, assistant-lf | Cola, la más antigua primero. `status` = `PENDING` (por defecto), `APPROVED` o `REJECTED`; `page`, `limit` (máx. 100). Responde `{ items, total, page, limit }`; cada ítem trae `proposal_id`, `status`, `created_at`, `honor`, `member { user_id, display_name }`, `current_instructor`, `proposed_instructor` (sin correo ni foto), `rejection_reason` y `reviewed_at` | HonorInstructorProposalsService.list() | `src/honors/admin-honor-instructor-proposals.controller.ts` |
| POST | `/api/v1/admin/honor-instructor-proposals/:proposalId/approve` | JWT | Global: super-admin, admin, assistant-admin, director-lf, assistant-lf | Aprobar: revalida que la especialidad siga activa y `APPROVED` (si no, 409 `HONOR_INSTRUCTOR_PROPOSAL_NOT_APPROVED`) y que el instructor siga siendo elegible (si no, 400 `HONOR_INSTRUCTOR_INVALID` y la propuesta sigue `PENDING`). Escribe solo `users_honors.instructor_*` y `modified_at` | HonorInstructorProposalsService.approve() | `src/honors/admin-honor-instructor-proposals.controller.ts` |
| POST | `/api/v1/admin/honor-instructor-proposals/:proposalId/reject` | JWT | Global: super-admin, admin, assistant-admin, director-lf, assistant-lf | Rechazar con `reason` (3 a 500 caracteres, visible para el miembro). No toca `users_honors` | HonorInstructorProposalsService.reject() | `src/honors/admin-honor-instructor-proposals.controller.ts` |

Errores: 404 `HONOR_INSTRUCTOR_PROPOSAL_NOT_FOUND`; 409 `HONOR_INSTRUCTOR_PROPOSAL_NOT_PENDING` (ya resuelta o retirada, o resolución simultánea). Auditoría en `validation_logs` (`instructor_proposed`, `instructor_withdrawn`, `instructor_approved`, `instructor_rejected`) sin el nombre libre del instructor.

### Admin - Honors Requirements

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/honors/requirements/pending-review` | JWT | Global: admin, super-admin; Permisos: honors:read | List requirements pending admin review (paginated) | AdminHonorsService.getPendingReview() | `src/admin/admin-honors.controller.ts` |
| PATCH | `/api/v1/admin/honors/requirements/batch-review` | JWT | Global: admin, super-admin; Permisos: honors:update | Batch-review flagged requirements | AdminHonorsService.batchReview() | `src/admin/admin-honors.controller.ts` |
| PATCH | `/api/v1/admin/honors/requirements/:requirementId` | JWT | Global: admin, super-admin; Permisos: honors:update | Update a requirement | AdminHonorsService.updateRequirement() | `src/admin/admin-honors.controller.ts` |
| DELETE | `/api/v1/admin/honors/requirements/:requirementId` | JWT | Global: admin, super-admin; Permisos: honors:delete | Soft-delete a requirement (and its children) | AdminHonorsService.deleteRequirement() | `src/admin/admin-honors.controller.ts` |
| GET | `/api/v1/admin/honors/:honorId/requirements` | JWT | Global: admin, super-admin; Permisos: honors:read | List requirements tree for an honor (admin view) | AdminHonorsService.getRequirements() | `src/admin/admin-honors.controller.ts` |
| POST | `/api/v1/admin/honors/:honorId/requirements` | JWT | Global: admin, super-admin; Permisos: honors:create | Create a requirement for an honor | AdminHonorsService.createRequirement() | `src/admin/admin-honors.controller.ts` |
| PATCH | `/api/v1/admin/honors/:honorId/requirements/reorder` | JWT | Global: admin, super-admin; Permisos: honors:update | Reorder requirements for an honor | AdminHonorsService.reorderRequirements() | `src/admin/admin-honors.controller.ts` |

### admin-notifications

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/notifications/stats` | JWT | Global: admin, super-admin | FCM notification delivery metrics for administrators | AdminNotificationsService.getStats() | `src/admin/admin-notifications.controller.ts` |
| GET | `/api/v1/admin/notifications/categories` | JWT | Global: admin, super-admin | Listar la configuración global de entrega por categoría de notificación | NotificationCategorySettingsService.listCategorySettings() | `src/admin/admin-notifications.controller.ts` |
| PATCH | `/api/v1/admin/notifications/categories` | JWT | Global: admin, super-admin | Actualizar una categoría (`PatchNotificationCategorySettingDto`: `category`, `mobileEnabled`, `defaultEnabled`); responde la lista completa | NotificationCategorySettingsService.updateCategorySetting() | `src/admin/admin-notifications.controller.ts` |

### Admin - Phase E Catalogs (i18n)

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/classes` | JWT | Global: admin, super-admin; Permisos: catalogs:read | List all classes with their full translations (admin editor) | AdminPhaseECatalogsService.findAllClasses() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| POST | `/api/v1/admin/classes` | JWT | Global: admin, super-admin; Permisos: catalogs:create | Create a class with optional translations | AdminPhaseECatalogsService.createClass() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| PATCH | `/api/v1/admin/classes/:id` | JWT | Global: admin, super-admin; Permisos: catalogs:update | Update a class and upsert/delete translations | AdminPhaseECatalogsService.updateClass() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| DELETE | `/api/v1/admin/classes/:id` | JWT | Global: admin, super-admin; Permisos: catalogs:delete | Soft-delete a class (active = false) | AdminPhaseECatalogsService.deleteClass() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| GET | `/api/v1/admin/classes/:classId/honors` | JWT | Global: admin, super-admin; Permisos: catalogs:read | List class-honor relations (incluye inactivas; filtro `active?`; `module_id`/`module`/`material_url`) | AdminPhaseECatalogsService.findClassHonors() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| POST | `/api/v1/admin/classes/:classId/honors` | JWT | Global: admin, super-admin; Permisos: catalogs:create | Create class-honor relation (`REQUIRED`/`RECOMMENDED`/`ELECTIVE`; `module_id?` del mismo `class_id`) | AdminPhaseECatalogsService.createClassHonor() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| PATCH | `/api/v1/admin/classes/:classId/honors/:classHonorId` | JWT | Global: admin, super-admin; Permisos: catalogs:update | Asigna o limpia el módulo (`module_id` number o `null`; omitir deja el módulo igual) | AdminPhaseECatalogsService.updateClassHonor() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| DELETE | `/api/v1/admin/classes/:classId/honors/:classHonorId` | JWT | Global: admin, super-admin; Permisos: catalogs:delete | Soft-delete class-honor relation | AdminPhaseECatalogsService.deleteClassHonor() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| GET | `/api/v1/admin/classes/:classId/prerequisites` | JWT | Global: admin, super-admin; Permisos: catalogs:read | List class prerequisites (incluye inactivas; filtro `active?`) | AdminPhaseECatalogsService.findClassPrerequisites() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| POST | `/api/v1/admin/classes/:classId/prerequisites` | JWT | Global: admin, super-admin; Permisos: catalogs:create | Create class prerequisite with cycle validation | AdminPhaseECatalogsService.createClassPrerequisite() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| DELETE | `/api/v1/admin/classes/:classId/prerequisites/:prerequisiteId` | JWT | Global: admin, super-admin; Permisos: catalogs:delete | Soft-delete class prerequisite | AdminPhaseECatalogsService.deleteClassPrerequisite() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| GET | `/api/v1/admin/class-modules` | JWT | Global: admin, super-admin; Permisos: catalogs:read | List all class modules with their full translations (admin editor) | AdminPhaseECatalogsService.findAllClassModules() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| POST | `/api/v1/admin/class-modules` | JWT | Global: admin, super-admin; Permisos: catalogs:create | Create a class module with optional translations | AdminPhaseECatalogsService.createClassModule() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| PATCH | `/api/v1/admin/class-modules/:id` | JWT | Global: admin, super-admin; Permisos: catalogs:update | Update a class module and upsert/delete translations | AdminPhaseECatalogsService.updateClassModule() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| DELETE | `/api/v1/admin/class-modules/:id` | JWT | Global: admin, super-admin; Permisos: catalogs:delete | Soft-delete a class module (active = false) | AdminPhaseECatalogsService.deleteClassModule() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| GET | `/api/v1/admin/class-sections` | JWT | Global: admin, super-admin; Permisos: catalogs:read | List all class sections with their full translations (admin editor) | AdminPhaseECatalogsService.findAllClassSections() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| POST | `/api/v1/admin/class-sections` | JWT | Global: admin, super-admin; Permisos: catalogs:create | Create a class section with optional translations | AdminPhaseECatalogsService.createClassSection() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| PATCH | `/api/v1/admin/class-sections/:id` | JWT | Global: admin, super-admin; Permisos: catalogs:update | Update a class section and upsert/delete translations | AdminPhaseECatalogsService.updateClassSection() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| DELETE | `/api/v1/admin/class-sections/:id` | JWT | Global: admin, super-admin; Permisos: catalogs:delete | Soft-delete a class section (active = false) | AdminPhaseECatalogsService.deleteClassSection() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| GET | `/api/v1/admin/finance-categories` | JWT | Global: admin, super-admin; Permisos: catalogs:read | List all finance categories with their full translations (admin editor) | AdminPhaseECatalogsService.findAllFinanceCategories() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| POST | `/api/v1/admin/finance-categories` | JWT | Global: admin, super-admin; Permisos: catalogs:create | Create a finance category with optional translations | AdminPhaseECatalogsService.createFinanceCategory() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| PATCH | `/api/v1/admin/finance-categories/:id` | JWT | Global: admin, super-admin; Permisos: catalogs:update | Update a finance category and upsert/delete translations | AdminPhaseECatalogsService.updateFinanceCategory() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| DELETE | `/api/v1/admin/finance-categories/:id` | JWT | Global: admin, super-admin; Permisos: catalogs:delete | Soft-delete a finance category (active = false) | AdminPhaseECatalogsService.deleteFinanceCategory() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| GET | `/api/v1/admin/inventory-categories` | JWT | Global: admin, super-admin; Permisos: catalogs:read | List all inventory categories with their full translations (admin editor) | AdminPhaseECatalogsService.findAllInventoryCategories() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| POST | `/api/v1/admin/inventory-categories` | JWT | Global: admin, super-admin; Permisos: catalogs:create | Create an inventory category with optional translations | AdminPhaseECatalogsService.createInventoryCategory() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| PATCH | `/api/v1/admin/inventory-categories/:id` | JWT | Global: admin, super-admin; Permisos: catalogs:update | Update an inventory category and upsert/delete translations | AdminPhaseECatalogsService.updateInventoryCategory() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| DELETE | `/api/v1/admin/inventory-categories/:id` | JWT | Global: admin, super-admin; Permisos: catalogs:delete | Soft-delete an inventory category (active = false) | AdminPhaseECatalogsService.deleteInventoryCategory() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| GET | `/api/v1/admin/honors-catalog` | JWT | Global: admin, super-admin; Permisos: honors:read | List all honors with their full translations (admin editor) | AdminPhaseECatalogsService.findAllHonors() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| POST | `/api/v1/admin/honors-catalog` | JWT | Global: admin, super-admin; Permisos: honors:create | Create an honor with optional translations | AdminPhaseECatalogsService.createHonor() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| PATCH | `/api/v1/admin/honors-catalog/:id` | JWT | Global: admin, super-admin; Permisos: honors:update | Update an honor and upsert/delete translations | AdminPhaseECatalogsService.updateHonor() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| DELETE | `/api/v1/admin/honors-catalog/:id` | JWT | Global: admin, super-admin; Permisos: honors:delete | Soft-delete an honor (active = false) | AdminPhaseECatalogsService.deleteHonor() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| GET | `/api/v1/admin/master-honors` | JWT | Global: admin, super-admin; Permisos: honors:read | List all master honors with their full translations (admin editor) | AdminPhaseECatalogsService.findAllMasterHonors() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| POST | `/api/v1/admin/master-honors` | JWT | Global: admin, super-admin; Permisos: honors:create | Create a master honor with optional translations | AdminPhaseECatalogsService.createMasterHonor() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| PATCH | `/api/v1/admin/master-honors/:id` | JWT | Global: admin, super-admin; Permisos: honors:update | Update a master honor and upsert/delete translations | AdminPhaseECatalogsService.updateMasterHonor() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| DELETE | `/api/v1/admin/master-honors/:id` | JWT | Global: admin, super-admin; Permisos: honors:delete | Soft-delete a master honor (active = false) | AdminPhaseECatalogsService.deleteMasterHonor() | `src/admin/admin-phase-e-catalogs.controller.ts` |
| POST | `/api/v1/admin/master-honors/:id/recalculate` | JWT | Global: admin, super-admin; Permisos: honors:update | Queue recalculation of affected users for one master honor | AdminPhaseECatalogsService.recalculateMasterHonor() | `src/admin/admin-phase-e-catalogs.controller.ts` |

### admin-reference

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/admin/catalogs/cache/invalidate` | JWT | Global: admin, super-admin; Permisos: catalogs:update | Invalidate all catalog caches (SCAN `cache:catalogs:*` + epoch bump de honores) | CatalogCacheService.invalidateAll() | `src/admin/admin-reference.controller.ts` |
| GET | `/api/v1/admin/activity-types` | JWT | Global: admin, super-admin; Permisos: catalogs:read | List activity types for admin management | AdminReferenceService.listActivityTypes() | `src/admin/admin-reference.controller.ts` |
| POST | `/api/v1/admin/activity-types` | JWT | Global: admin, super-admin; Permisos: catalogs:create | Create activity type | AdminReferenceService.createActivityType() | `src/admin/admin-reference.controller.ts` |
| PATCH | `/api/v1/admin/activity-types/:activityTypeId` | JWT | Global: admin, super-admin; Permisos: catalogs:update | Update activity type | AdminReferenceService.updateActivityType() | `src/admin/admin-reference.controller.ts` |
| DELETE | `/api/v1/admin/activity-types/:activityTypeId` | JWT | Global: admin, super-admin; Permisos: catalogs:delete | Soft delete activity type | AdminReferenceService.deleteActivityType() | `src/admin/admin-reference.controller.ts` |
| GET | `/api/v1/admin/relationship-types` | JWT | Global: admin, super-admin; Permisos: catalogs:read | List relationship types for admin management | AdminReferenceService.listRelationshipTypes() | `src/admin/admin-reference.controller.ts` |
| POST | `/api/v1/admin/relationship-types` | JWT | Global: admin, super-admin; Permisos: catalogs:create | Create relationship type | AdminReferenceService.createRelationshipType() | `src/admin/admin-reference.controller.ts` |
| PATCH | `/api/v1/admin/relationship-types/:relationshipTypeId` | JWT | Global: admin, super-admin; Permisos: catalogs:update | Update relationship type | AdminReferenceService.updateRelationshipType() | `src/admin/admin-reference.controller.ts` |
| DELETE | `/api/v1/admin/relationship-types/:relationshipTypeId` | JWT | Global: admin, super-admin; Permisos: catalogs:delete | Soft delete relationship type. Si lo usa un `legal_representatives` o una `guardianships`, 409 `ADMIN_RELATIONSHIP_TYPE_IN_USE` | AdminReferenceService.deleteRelationshipType() | `src/admin/admin-reference.controller.ts` |
| GET | `/api/v1/admin/allergies` | JWT | Global: admin, super-admin; Permisos: catalogs:read | List allergies for admin management | AdminReferenceService.listAllergies() | `src/admin/admin-reference.controller.ts` |
| POST | `/api/v1/admin/allergies` | JWT | Global: admin, super-admin; Permisos: catalogs:create | Create allergy | AdminReferenceService.createAllergy() | `src/admin/admin-reference.controller.ts` |
| PATCH | `/api/v1/admin/allergies/:allergyId` | JWT | Global: admin, super-admin; Permisos: catalogs:update | Update allergy | AdminReferenceService.updateAllergy() | `src/admin/admin-reference.controller.ts` |
| DELETE | `/api/v1/admin/allergies/:allergyId` | JWT | Global: admin, super-admin; Permisos: catalogs:delete | Soft delete allergy | AdminReferenceService.deleteAllergy() | `src/admin/admin-reference.controller.ts` |
| GET | `/api/v1/admin/diseases` | JWT | Global: admin, super-admin; Permisos: catalogs:read | List diseases for admin management | AdminReferenceService.listDiseases() | `src/admin/admin-reference.controller.ts` |
| POST | `/api/v1/admin/diseases` | JWT | Global: admin, super-admin; Permisos: catalogs:create | Create disease | AdminReferenceService.createDisease() | `src/admin/admin-reference.controller.ts` |
| PATCH | `/api/v1/admin/diseases/:diseaseId` | JWT | Global: admin, super-admin; Permisos: catalogs:update | Update disease | AdminReferenceService.updateDisease() | `src/admin/admin-reference.controller.ts` |
| DELETE | `/api/v1/admin/diseases/:diseaseId` | JWT | Global: admin, super-admin; Permisos: catalogs:delete | Soft delete disease | AdminReferenceService.deleteDisease() | `src/admin/admin-reference.controller.ts` |
| GET | `/api/v1/admin/club-ideals` | JWT | Global: admin, super-admin; Permisos: catalogs:read | List club ideals for admin | AdminReferenceService.listClubIdeals() | `src/admin/admin-reference.controller.ts` |
| POST | `/api/v1/admin/club-ideals` | JWT | Global: admin, super-admin; Permisos: catalogs:create; Global: super-admin | Create club ideal (super-admin only) | AdminReferenceService.createClubIdeal() | `src/admin/admin-reference.controller.ts` |
| PATCH | `/api/v1/admin/club-ideals/:clubIdealId` | JWT | Global: admin, super-admin; Permisos: catalogs:update | Update club ideal (admin: edit only; super-admin: full edit) | AdminReferenceService.updateClubIdeal() | `src/admin/admin-reference.controller.ts` |
| DELETE | `/api/v1/admin/club-ideals/:clubIdealId` | JWT | Global: admin, super-admin; Permisos: catalogs:delete; Global: super-admin | Soft delete club ideal (super-admin only) | AdminReferenceService.deleteClubIdeal() | `src/admin/admin-reference.controller.ts` |
| GET | `/api/v1/admin/club-types` | JWT | Global: admin, super-admin; Permisos: catalogs:read | List all club types for admin management | AdminReferenceService.listClubTypes() | `src/admin/admin-reference.controller.ts` |
| POST | `/api/v1/admin/club-types` | JWT | Global: admin, super-admin; Permisos: catalogs:create; Global: super-admin | Create club type (super-admin only) | AdminReferenceService.createClubType() | `src/admin/admin-reference.controller.ts` |
| PATCH | `/api/v1/admin/club-types/:clubTypeId` | JWT | Global: admin, super-admin; Permisos: catalogs:update | Update club type (admin: edit only; super-admin: full edit) | AdminReferenceService.updateClubType() | `src/admin/admin-reference.controller.ts` |
| DELETE | `/api/v1/admin/club-types/:clubTypeId` | JWT | Global: admin, super-admin; Permisos: catalogs:delete; Global: super-admin | Soft delete club type (super-admin only) | AdminReferenceService.deleteClubType() | `src/admin/admin-reference.controller.ts` |
| GET | `/api/v1/admin/honor-categories` | JWT | Global: admin, super-admin; Permisos: honor_categories:read | List honor categories for admin management | AdminReferenceService.listHonorCategories() | `src/admin/admin-reference.controller.ts` |
| POST | `/api/v1/admin/honor-categories` | JWT | Global: admin, super-admin; Permisos: honor_categories:create | Create honor category | AdminReferenceService.createHonorCategory() | `src/admin/admin-reference.controller.ts` |
| GET | `/api/v1/admin/honor-categories/:id` | JWT | Global: admin, super-admin; Permisos: honor_categories:read | Get honor category by ID | AdminReferenceService.getHonorCategory() | `src/admin/admin-reference.controller.ts` |
| PATCH | `/api/v1/admin/honor-categories/:id` | JWT | Global: admin, super-admin; Permisos: honor_categories:update | Update honor category | AdminReferenceService.updateHonorCategory() | `src/admin/admin-reference.controller.ts` |
| DELETE | `/api/v1/admin/honor-categories/:id` | JWT | Global: admin, super-admin; Permisos: honor_categories:delete | Soft delete honor category | AdminReferenceService.deleteHonorCategory() | `src/admin/admin-reference.controller.ts` |
| GET | `/api/v1/admin/medicines` | JWT | Global: admin, super-admin; Permisos: catalogs:read | List medicines for admin management | AdminReferenceService.listMedicines() | `src/admin/admin-reference.controller.ts` |
| POST | `/api/v1/admin/medicines` | JWT | Global: admin, super-admin; Permisos: catalogs:create | Create medicine | AdminReferenceService.createMedicine() | `src/admin/admin-reference.controller.ts` |
| PATCH | `/api/v1/admin/medicines/:medicineId` | JWT | Global: admin, super-admin; Permisos: catalogs:update | Update medicine | AdminReferenceService.updateMedicine() | `src/admin/admin-reference.controller.ts` |
| DELETE | `/api/v1/admin/medicines/:medicineId` | JWT | Global: admin, super-admin; Permisos: catalogs:delete | Soft delete medicine | AdminReferenceService.deleteMedicine() | `src/admin/admin-reference.controller.ts` |
| GET | `/api/v1/admin/ecclesiastical-years` | JWT | Global: admin, super-admin; Permisos: ecclesiastical_years:read | List ecclesiastical years for admin management | AdminReferenceService.listEcclesiasticalYears() | `src/admin/admin-reference.controller.ts` |
| POST | `/api/v1/admin/ecclesiastical-years` | JWT | Global: super-admin; Permisos: ecclesiastical_years:create | Create ecclesiastical year | AdminReferenceService.createEcclesiasticalYear() | `src/admin/admin-reference.controller.ts` |
| PATCH | `/api/v1/admin/ecclesiastical-years/:yearId` | JWT | Global: admin, super-admin; Permisos: ecclesiastical_years:update | Update ecclesiastical year | AdminReferenceService.updateEcclesiasticalYear() | `src/admin/admin-reference.controller.ts` |
| DELETE | `/api/v1/admin/ecclesiastical-years/:yearId` | JWT | Global: super-admin; Permisos: ecclesiastical_years:delete | Soft delete ecclesiastical year | AdminReferenceService.deleteEcclesiasticalYear() | `src/admin/admin-reference.controller.ts` |

### admin-users

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/users` | JWT | Global: admin, super-admin, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia (USER_MANAGEMENT_ROLES, pisa la cerca de clase); Permisos: users:read | Listar usuarios administrativos con alcance por rol (ALL/DIVISION/UNION/LOCAL_FIELD). Ordena el conjunto filtrado **antes** de `skip`/`take`. Query: `search`, `role` (OR global o club), `active`, `unionId`, `localFieldId`, `sortBy` (`name` | `created_at`, default `name`), `sortOrder` (`asc` | `desc`, default `asc`), `page`, `limit`. `sortBy=name`: `name`, `paternal_last_name`, `maternal_last_name` (nulls last) + `user_id` asc. `sortBy=created_at`: `created_at` + `user_id` asc. Enum inválido → 400. Cada ítem incluye `roles` (slugs únicos global+club) y `club_assignments` compactos `{ assignment_id, role_name, section_name, club_name }`. El panel de lista muestra un badge por cargo (sin sección; el mismo cargo en varias secciones se colapsa). | AdminUsersService.listUsers() | `src/admin/admin-users.controller.ts` |
| GET | `/api/v1/admin/users/bulk-template` | JWT | Global: admin, super-admin; Permisos: users:bulk_create; Global: admin, super-admin, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Descarga plantilla .xlsx para carga masiva de usuarios | AdminUsersService.getBulkTemplateBuffer() | `src/admin/admin-users.controller.ts` |
| GET | `/api/v1/admin/users/:userId` | JWT | Global: admin, super-admin, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia (USER_MANAGEMENT_ROLES, pisa la cerca de clase); Permisos: users:read_detail | Obtener detalle de usuario validando alcance por rol del actor. `email` puede ser `null` (dependientes). Añade `guardianships` (quién responde por el usuario y por quién responde; ver «Tutorías en el detalle de usuario» debajo), `null` si el actor no tiene `legal_representative:read` ni el respaldo transitorio `users:read_detail`. Fase 3c: añade `family_access` (acceso propio y dispositivos vinculados; mismo `null`; ver «Acceso familiar en el detalle de usuario y acciones del panel») | AdminUsersService.getUserById() | `src/admin/admin-users.controller.ts` |
| GET | `/api/v1/admin/users/:userId/guardianships/:guardianshipId/consent-evidence` | JWT | Global: USER_MANAGEMENT_ROLES; Permisos: `legal_representative:read` (respaldo transitorio `users:read_detail` hasta 2027-03-31); recorte territorial | URL firmada (15 min) de la ficha de consentimiento vigente de esa tutoría. 200 `{ url, expires_in: 900, content_type, uploaded_at }`. La tutoría debe pertenecer a `:userId` como menor; si no, 404 `GUARDIANSHIP_NOT_FOUND`. Sin ficha vigente, 404 `GUARDIANSHIP_EVIDENCE_NOT_FOUND`; sin bucket configurado, 503 `GUARDIANSHIP_EVIDENCE_UNAVAILABLE`. Cada lectura se audita (`guardianship_consent_evidence` / `read`, `via: admin`) antes de devolver la URL | GuardianEvidenceService.getForAdmin() | `src/admin/admin-users.controller.ts` |
| POST | `/api/v1/admin/users/:userId/supervised-login/disable` | JWT | Global: admin, super-admin; Permisos: users:update_admin + sensible `legal_representative:update` (respaldo `users:update_profile` hasta 2027-03-31); recorte territorial | Fase 3c. Desactiva el acceso propio de un menor desde el panel. Cuerpo `{ reason }` (5 a 500 caracteres, única clave; el motivo solo va a la auditoría `admin.supervised_login.disabled`). 200. Sesiones borradas, siguiente petición del menor 401 `AUTH_SUPERVISED_ACCESS_REVOKED`, todos los tutores verificados reciben aviso. Idempotente; sin bandera ni regla de edad. 404 `ADMIN_USER_NOT_FOUND` o `SUPERVISED_LOGIN_NOT_FOUND`. No existe ruta de admin para activar, reactivar ni cambiar la contraseña | AdminFamilyAccessService.disableSupervisedLogin() | `src/admin/admin-users.controller.ts` |
| POST | `/api/v1/admin/users/:userId/linked-devices/:deviceId/revoke` | JWT | Global: admin, super-admin; Permisos: users:update_admin + sensible `legal_representative:update` (respaldo `users:update_profile` hasta 2027-03-31); recorte territorial | Fase 3c. Desvincula un dispositivo de un menor desde el panel. Cuerpo `{ reason }` (5 a 500 caracteres; solo auditoría `admin.linked_device.revoked`). 200 `{ linked_device_id, revoked_at, revoked_reason: "admin" }`. Siguiente petición del teléfono 401 `AUTH_DEVICE_REVOKED`; aviso a todos los tutores verificados. Idempotente. 404 `ADMIN_USER_NOT_FOUND` o `DEVICE_NOT_FOUND` (también el dispositivo de otra familia) | AdminFamilyAccessService.revokeLinkedDevice() | `src/admin/admin-users.controller.ts` |
| PATCH | `/api/v1/admin/users/:userId/approval` | JWT | Global: admin, super-admin; Permisos: users:update_admin | Approve or reject a user | AdminUsersService.updateUserApproval() | `src/admin/admin-users.controller.ts` |
| PATCH | `/api/v1/admin/users/:userId` | JWT | Global: admin, super-admin; Permisos: users:update_admin | Update user administrative fields | AdminUsersService.updateUser() | `src/admin/admin-users.controller.ts` |
| POST | `/api/v1/admin/users` | JWT | Global: admin, super-admin; Permisos: users:create; Global: admin, super-admin, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Crear usuario manualmente (admin-iniciado, con invite por email) | AdminUsersService.createAdminUser() | `src/admin/admin-users.controller.ts` |
| POST | `/api/v1/admin/users/bulk` | JWT | Global: admin, super-admin; Permisos: users:bulk_create; Global: admin, super-admin, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Carga masiva de usuarios desde archivo .xlsx o .csv | AdminUsersService.bulkCreateAdminUsers() | `src/admin/admin-users.controller.ts` |

#### Tutorías en el detalle de usuario

> Perfiles familiares, rama `feat/family-profiles`, Pendiente de merge (PR #530 de sacdia-backend). Mismo envoltorio `{ status: 'success', data }`; el bloque cuelga de `data.guardianships`.

`data.guardianships` es `null` si el actor no puede leer la familia sensible `legal_representative` (permiso `legal_representative:read`, o `users:read_detail` mientras dure el respaldo transitorio). Para un adulto sin familia llega con listas vacías y `dependent_profile: null`. No hay bloque de escritura: las tutorías las gestiona el tutor desde la app.

```json
{
  "as_dependent": [
    {
      "guardianship_id": "uuid",
      "guardian": { "user_id": "uuid", "display_name": "María Pérez", "email": "maria@example.com" },
      "custodian_club": null,
      "external_name": null,
      "relationship_type_name": "Madre",
      "is_primary": true,
      "is_custodian": false,
      "consent_status": "verified",
      "verification_method": "director_paper_form",
      "verified_at": "2026-10-19T15:00:00.000Z",
      "verified_by": { "user_id": "uuid", "display_name": "Ana Soto" },
      "evidence_uploaded": true,
      "is_test_data": false,
      "created_at": "2026-10-16T12:00:00.000Z",
      "revoked_at": null,
      "revoked_reason": null
    }
  ],
  "as_guardian": [
    {
      "guardianship_id": "uuid",
      "dependent": { "user_id": "uuid", "display_name": "Ana Pérez", "birthday": "2017-04-02T00:00:00.000Z" },
      "relationship_type_name": "Madre",
      "is_primary": true,
      "consent_status": "pending"
    }
  ],
  "dependent_profile": { "created_at": "iso", "created_by_user_id": "uuid", "frozen_at": null, "purge_after": null }
}
```

- `as_dependent` incluye el **historial**: también las filas revocadas, con `revoked_at` y `revoked_reason`, ordenadas por `created_at` ascendente. Una fila de custodia trae `custodian_club` en vez de `guardian`; un tutor externo trae `external_name` (se anula al purgar al menor).
- `guardian.email` es `null` si la cuenta del tutor fue eliminada.
- `evidence_uploaded` refleja la ficha vigente **de esa fila**. La ficha se guarda en la fila principal, así que las filas secundarias salen con `false`.
- `as_guardian` lista solo las tutorías vivas del usuario como tutor (no revocadas ni de custodia).
- Contacto: solo el correo del tutor. No hay teléfonos ni claves de archivos.

### analytics

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/analytics/sla-dashboard` | JWT | Global: admin, coordinator (alias: zone/general + director-lf/assistant-lf; LF recorta a secciones del campo) | SLA Dashboard | AnalyticsService.getSlaDashboard() | `src/analytics/analytics.controller.ts` |
| GET | `/api/v1/admin/analytics/local-field-dashboard` | JWT | Global: admin, super-admin, coordinator, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Dashboard operativo del campo local (miembros activos, inscripciones anuales, cobertura de informes mensuales, distribución por clase, especialidades y actividades). Query opcional `local_field_id`: los roles de campo ven su propio campo; admin puede filtrar | LocalFieldDashboardService.getDashboard() | `src/analytics/analytics.controller.ts` |
| GET | `/api/v1/admin/analytics/operations-dashboard` | JWT | Global: admin (alias: assistant-admin), super-admin, director-dia, assistant-dia, director-union, assistant-union, director-lf, assistant-lf | Dashboard operativo jerárquico con scope forzado en servidor | OperationsDashboardService.getDashboard() | `src/analytics/analytics.controller.ts` |
| GET | `/api/v1/admin/analytics/jobs-overview` | JWT | Global: admin, super-admin | Overview de jobs y colas BullMQ (admin only) | JobsOverviewService.getOverview() | `src/analytics/analytics.controller.ts` |
| POST | `/api/v1/admin/analytics/jobs/:queue/:jobId/retry` | JWT | Global: super-admin | Retry failed BullMQ job (super-admin only) | JobsOverviewService.retryFailedJob() | `src/analytics/analytics.controller.ts` |
| GET | `/api/v1/admin/analytics/queues/:queueName/health` | JWT | Global: admin, super-admin | Queue health snapshot (admin only) | JobsOverviewService.getQueueHealth() | `src/analytics/analytics.controller.ts` |
| GET | `/api/v1/admin/analytics/cron-runs` | JWT | Global: admin, super-admin | Resumen de ejecuciones de cron jobs (admin only); `recent[]` trae `trigger` y `triggered_by` (mergeado en `development`, PR #535 de sacdia-backend) | CronRunsService.getSummary() | `src/analytics/analytics.controller.ts` |
| GET | `/api/v1/admin/analytics/cron-runs/history` | JWT | Global: admin, super-admin | Historial paginado de cron runs con filtros | CronRunsService.getHistory() | `src/analytics/analytics.controller.ts` |

#### `GET /api/v1/admin/analytics/operations-dashboard`

Endpoint read-only agregado. El controller admite los roles enumerados en la tabla; `assistant-admin` es aceptado por el alias `admin ↔ assistant-admin` de `GlobalRolesGuard`. Solo `super-admin` obtiene scope global. Los demás actores reciben el scope territorial resuelto por `OperationsDashboardScopeService`.

##### Query

| Parámetro | Requerido | Validación y comportamiento |
| --- | --- | --- |
| `ecclesiastical_year_id` | No | Entero `>= 1`. Si se omite, selecciona el año activo más reciente por `start_date`. |
| `division_id` | No | Entero `>= 1`; solo puede mantener o reducir el scope autorizado. |
| `union_id` | No | Entero `>= 1`; debe pertenecer a la cadena solicitada y al scope del actor. |
| `local_field_id` | No | Entero `>= 1`; debe pertenecer a la cadena solicitada y al scope del actor. |
| `report_year` | Condicional | Entero `>= 1`; debe enviarse junto con `report_month`. |
| `report_month` | Condicional | Entero `1..12`; debe enviarse junto con `report_year`. |

El periodo mensual explícito debe caer entre los meses inicial y final del año eclesiástico, inclusive. Si ambos parámetros se omiten, el servicio resuelve el último mes calendario cerrado dentro del año. Cuando el año todavía no contiene un mes cerrado, `reporting_month` es `null`, los conteos mensuales son `0`, `coverage_pct` es `null` y la calidad es `not_applicable`.

El `ValidationPipe` global transforma strings numéricos, rechaza propiedades no declaradas y responde `400` ante enteros inválidos, IDs no positivos, mes fuera de rango o un periodo incompleto.

##### Envelope y shape de éxito

```ts
type ScopeLevel = 'all' | 'division' | 'union' | 'local_field';
type ChildLevel = 'division' | 'union' | 'local_field' | 'club';
type MetricQuality =
  | 'exact'
  | 'current_affiliation'
  | 'unavailable'
  | 'not_applicable';

type DashboardMetrics = {
  administrative_clubs: {
    total: number;
    active: number;
    inactive: number;
  };
  operations: {
    operational_clubs: number;
    non_operational_clubs: number;
    operational_sections: number;
    operational_rate_pct: number | null;
  };
  people: {
    institutionally_active: number;
    platform_accounts: { active: number; inactive: number };
  };
  classes: {
    total_enrollments: number;
    distinct_people: number;
    by_class: Array<{
      class_id: number;
      class_name: string;
      club_type_id: number;
      club_type_name: string;
      display_order: number;
      enrollment_count: number;
    }>;
  };
  monthly_reports: {
    expected_sections: number;
    submitted_sections: number;
    draft_sections: number;
    generated_sections: number;
    missing_sections: number;
    coverage_pct: number | null;
  };
  honors: {
    in_progress: number | null;
    pending_review: number | null;
    approved: number | null;
    attribution: 'current_affiliation' | 'unavailable';
  };
  activities: {
    registered: number;
    joint_registered: number;
    distinct_participating_sections: number;
  };
  queues: {
    role_assignments_pending: number;
    transfers_pending: number;
    class_validations_pending: number;
    honors_review_pending: number | null;
    annual_folders_pending_union: number;
  };
};

type OperationsDashboardResponse = {
  status: 'ok';
  data: {
    meta: {
      computed_at: string; // ISO 8601
      cached: boolean;
      cache_ttl_seconds: number; // runtime actual: 60
      definitions_version: string; // runtime actual: "1"
      scope: {
        level: ScopeLevel;
        id: number | null;
        name: string;
        path: Array<{
          level: Exclude<ScopeLevel, 'all'>;
          id: number;
          name: string;
        }>;
      };
      period: {
        ecclesiastical_year: {
          id: number;
          start_date: string; // YYYY-MM-DD
          end_date: string; // YYYY-MM-DD
          active: boolean;
        };
        reporting_month: { year: number; month: number } | null;
      };
    };
    summary: DashboardMetrics;
    children: Array<
      {
        id: number;
        name: string;
        level: ChildLevel;
      } & DashboardMetrics
    >;
    data_quality: Array<{
      metric: string;
      status: MetricQuality;
      note: string;
    }>;
  };
};
```

`children` siempre representa el nivel inmediato: global → División → Unión → Campo local → Club. También contiene `classes.by_class`; no es un resumen compacto. Los totales de `summary` se recalculan de forma independiente y no deben reconstruirse sumando children.

Para un año histórico (`ecclesiastical_year.active = false`), los conteos de especialidades y `queues.honors_review_pending` son `null`, no `0`. `operations.operational_rate_pct` es `null` cuando no hay clubes administrativos y `monthly_reports.coverage_pct` es `null` cuando no hay denominador.

##### Errores

| HTTP | Código/causa | Regla |
| ---: | --- | --- |
| `400` | Validación DTO | Query desconocida, número inválido/no positivo, periodo incompleto o `report_month` fuera de `1..12`. |
| `400` | `ANALYTICS_SCOPE_CHAIN_INVALID` | Los IDs territoriales enviados no forman una misma cadena. |
| `400` | `ANALYTICS_REPORTING_PERIOD_OUTSIDE_ECCLESIASTICAL_YEAR` | El mes solicitado queda fuera del año seleccionado. |
| `401` | JWT faltante o inválido | Rechazo de `JwtAuthGuard`. |
| `403` | `GUARD_PERMISSION_DENIED` | Rol no admitido, destino fuera de scope o geografía desconocida solicitada por un actor scoped. |
| `403` | `ADMIN_USER_SCOPE_MISSING` | El rol requiere scope territorial, pero el perfil efectivo no contiene el ID numérico necesario. |
| `404` | `ADMIN_ECCLESIASTICAL_YEAR_NOT_FOUND` | No existe el año explícito o no hay año activo al omitirlo. |
| `404` | `ADMIN_DIVISION_NOT_FOUND`, `ADMIN_UNION_NOT_FOUND`, `ADMIN_LOCAL_FIELD_NOT_FOUND` | Solo para `super-admin` global que consulta geografía inexistente. |

Los errores de dominio siguen el envelope canónico:

```json
{
  "status": "error",
  "statusCode": 403,
  "code": "GUARD_PERMISSION_DENIED",
  "message": "...",
  "timestamp": "2026-07-15T00:00:00.000Z",
  "path": "/api/v1/admin/analytics/operations-dashboard"
}
```

Un actor territorial recibe el mismo `403 GUARD_PERMISSION_DENIED` tanto para un territorio existente fuera de alcance como para un ID geográfico inexistente. Esto evita enumeración. El `404` geográfico está reservado al actor global.

##### Caché

- `Map` en memoria por réplica, con TTL de 60 segundos.
- Key por `scope.level`, `scope.id`, año eclesiástico y periodo mensual o `none`.
- Un hit devuelve `cached: true` y conserva el `computed_at` del snapshot original.
- Una entrada vencida se elimina y recalcula; no existe stale-on-error.
- `cached: true` no significa stale y el contrato no expone `freshness`.

Semántica funcional y límites: [operations-dashboard.md](../features/operations-dashboard.md).

### Annual Evidence Folders

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/club-sections/:sectionId/annual-folder` | JWT | Permisos: evidence_folders:read | Get annual evidence folder for a club section (current year) | CatalogsService.getCurrentEcclesiasticalYear(), ClubEnrollmentsService.findCurrentBySectionId(), AnnualFoldersService.getFolderByEnrollment() | `src/annual-folders/annual-folder-by-section.controller.ts` |
| GET | `/api/v1/club-sections/:sectionId/annual-folder/template-availability` | JWT | Permisos: evidence_folders:read | Check whether an annual evidence folder can be created for a club section | ClubEnrollmentsService.findCurrentBySectionId(), AnnualFoldersService.getTemplateAvailabilityForEnrollment() | `src/annual-folders/annual-folder-by-section.controller.ts` |
| POST | `/api/v1/club-sections/:sectionId/annual-folder` | JWT | Permisos: evidence_folders:update | Create annual evidence folder for a club section | ClubEnrollmentsService.findCurrentBySectionId(), AnnualFoldersService.createFolderForEnrollment() | `src/annual-folders/annual-folder-by-section.controller.ts` |
| POST | `/api/v1/annual-folders/enrollments/:enrollmentId` | JWT | Permisos: evidence_folders:update | Create annual evidence folder for a club enrollment | AnnualFoldersService.createFolderForEnrollment() | `src/annual-folders/annual-folders.controller.ts` |
| GET | `/api/v1/annual-folders/evaluation/queue` | JWT | Permisos: annual_folders:evaluate | List annual evidence folders available for evaluation | AnnualFoldersService.getEvaluationQueue() | `src/annual-folders/annual-folders.controller.ts` |
| GET | `/api/v1/annual-folders/:folderId` | JWT | Permisos: evidence_folders:read | Get annual evidence folder with sections and evidences | AnnualFoldersService.getFolder() | `src/annual-folders/annual-folders.controller.ts` |
| GET | `/api/v1/annual-folders/by-enrollment/:enrollmentId` | JWT | Permisos: evidence_folders:read | Get annual evidence folder by enrollment ID | AnnualFoldersService.getFolderByEnrollment() | `src/annual-folders/annual-folders.controller.ts` |
| POST | `/api/v1/annual-folders/:folderId/sections/:sectionId/evidences` | JWT | Permisos: evidence_folders:update | Upload evidence to a folder section | AnnualFoldersService.uploadEvidence() | `src/annual-folders/annual-folders.controller.ts` |
| PATCH | `/api/v1/annual-folders/evidences/:evidenceId` | JWT | Permisos: evidence_folders:update | Update evidence metadata | AnnualFoldersService.updateEvidence() | `src/annual-folders/annual-folders.controller.ts` |
| DELETE | `/api/v1/annual-folders/evidences/:evidenceId` | JWT | Permisos: evidence_folders:update | Delete evidence | AnnualFoldersService.deleteEvidence() | `src/annual-folders/annual-folders.controller.ts` |
| GET | `/api/v1/annual-folders/:folderId/sections/:sectionId/status` | JWT | Permisos: evidence_folders:read | Get the current status of a single section within an annual evidence folder | AnnualFoldersService.getSectionStatus() | `src/annual-folders/annual-folders.controller.ts` |
| POST | `/api/v1/annual-folders/:folderId/sections/:sectionId/submit` | JWT | Permisos: evidence_folders:update | Submit a single section of an annual evidence folder | AnnualFoldersService.submitSection() | `src/annual-folders/annual-folders.controller.ts` |
| POST | `/api/v1/annual-folders/:folderId/submit` | JWT | Permisos: annual_folders:submit | Submit entire folder for review (director/secretariat only) | AnnualFoldersService.submitFolder() | `src/annual-folders/annual-folders.controller.ts` |
| POST | `/api/v1/annual-folders/:folderId/close` | JWT | Permisos: evidence_folders:update | Close folder (field-level action) | AnnualFoldersService.closeFolder() | `src/annual-folders/annual-folders.controller.ts` |

### Annual Evidence Folders - Templates

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/annual-folders/templates` | JWT | Permisos: annual_folder_templates:create | Create folder template for a club type and year | AnnualFoldersService.createTemplate() | `src/annual-folders/annual-folders.controller.ts` |
| GET | `/api/v1/annual-folders/templates/:templateId` | JWT | Permisos: annual_folder_templates:read | Get template by ID with all sections | AnnualFoldersService.getTemplate() | `src/annual-folders/annual-folders.controller.ts` |
| GET | `/api/v1/annual-folders/templates` | JWT | Permisos: annual_folder_templates:read | List templates or get template by club type and year | AnnualFoldersService.listTemplates(), AnnualFoldersService.getTemplateByClubTypeAndYear() | `src/annual-folders/annual-folders.controller.ts` |
| PATCH | `/api/v1/annual-folders/templates/:templateId` | JWT | Permisos: annual_folder_templates:update | Update annual folder template metadata | AnnualFoldersService.updateTemplate() | `src/annual-folders/annual-folders.controller.ts` |
| POST | `/api/v1/annual-folders/templates/:templateId/copy` | JWT | Permisos: annual_folder_templates:create | Copy an annual folder template as a draft | AnnualFoldersService.copyTemplate() | `src/annual-folders/annual-folders.controller.ts` |
| POST | `/api/v1/annual-folders/templates/:templateId/sections` | JWT | Permisos: annual_folder_templates:update | Add section to template | AnnualFoldersService.addTemplateSection() | `src/annual-folders/annual-folders.controller.ts` |
| PATCH | `/api/v1/annual-folders/templates/sections/:sectionId` | JWT | Permisos: annual_folder_templates:update | Update template section | AnnualFoldersService.updateTemplateSection() | `src/annual-folders/annual-folders.controller.ts` |
| DELETE | `/api/v1/annual-folders/templates/sections/:sectionId` | JWT | Permisos: annual_folder_templates:delete | Remove template section | AnnualFoldersService.removeTemplateSection() | `src/annual-folders/annual-folders.controller.ts` |
| DELETE | `/api/v1/annual-folders/templates/:templateId` | JWT | Permisos: annual_folder_templates:delete | Delete a draft annual folder template | AnnualFoldersService.removeTemplate() | `src/annual-folders/annual-folders.controller.ts` |

### Award Categories

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/award-categories` | JWT | Permisos: award_categories:create | Create an award category | AwardCategoriesService.create() | `src/annual-folders/award-categories.controller.ts` |
| GET | `/api/v1/award-categories` | JWT | Permisos: award_categories:read | List award categories with optional filters | AwardCategoriesService.findAll() | `src/annual-folders/award-categories.controller.ts` |
| GET | `/api/v1/award-categories/:categoryId` | JWT | Permisos: award_categories:read | Get a single award category by ID | AwardCategoriesService.findOne() | `src/annual-folders/award-categories.controller.ts` |
| PATCH | `/api/v1/award-categories/:categoryId` | JWT | Permisos: award_categories:update | Update an award category | AwardCategoriesService.update() | `src/annual-folders/award-categories.controller.ts` |
| DELETE | `/api/v1/award-categories/:categoryId` | JWT | Permisos: award_categories:delete | Deactivate an award category (soft delete) | AwardCategoriesService.remove() | `src/annual-folders/award-categories.controller.ts` |

### Annual Evidence Folders - Evaluation

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/annual-folders/:folderId/sections/:sectionId/evaluate` | JWT | Permisos: annual_folders:evaluate | Evaluate a section of an annual evidence folder | EvaluationService.evaluateSection() | `src/annual-folders/evaluation.controller.ts` |
| POST | `/api/v1/annual-folders/:folderId/sections/:sectionId/reopen` | JWT | Permisos: annual_folders:evaluate | Reopen a section for re-evaluation (removes existing evaluation) | EvaluationService.reopenSection() | `src/annual-folders/evaluation.controller.ts` |
| POST | `/api/v1/annual-folders/:folderId/sections/:sectionId/confirm-union` | JWT | Permisos: annual_folders:evaluate | Union actor confirms or overrides a pre-approved section | EvaluationService.confirmUnion() | `src/annual-folders/evaluation.controller.ts` |
| GET | `/api/v1/annual-folders/:folderId/evaluations` | JWT | Permisos: annual_folders:evaluate, evidence_folders:read (any) | Get all section evaluations for a folder | AnnualFoldersService.assertFolderReadAccessForUser(), EvaluationService.getFolderEvaluations() | `src/annual-folders/evaluation.controller.ts` |
| PATCH | `/api/v1/annual-folders/evidences/:evidenceId/reviewer-note` | JWT | Permisos: annual_folders:evaluate | Set or clear a reviewer note on a specific evidence file | AnnualFoldersService.setReviewerNote() | `src/annual-folders/evaluation.controller.ts` |

### Annual Evidence Folders - Rankings

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/annual-folders/rankings` | JWT | Permisos: rankings:read | Get club rankings for a given year and club type | RankingsService.getRankings() | `src/annual-folders/rankings.controller.ts` |
| GET | `/api/v1/annual-folders/rankings/club/:enrollmentId` | JWT | Permisos: rankings:read | Get all rankings for a specific club enrollment | RankingsService.getRankingForClub() | `src/annual-folders/rankings.controller.ts` |
| GET | `/api/v1/annual-folders/rankings/:enrollmentId/breakdown` | JWT | Permisos: rankings:read | Per-component score breakdown for a club enrollment | RankingsService.getBreakdown() | `src/annual-folders/rankings.controller.ts` |
| POST | `/api/v1/annual-folders/rankings/recalculate` | JWT | Permisos: rankings:recalculate | Encola recálculo de rankings de club (202). Poll GET rankings. | RankingsService.enqueueRecalculation() | `src/annual-folders/rankings.controller.ts` |

### annual-reports

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/annual-reports` | JWT | Permisos: reports:read | Listar informes anuales (admin) | AnnualReportsService.listForAdmin() | `src/annual-reports/annual-reports.controller.ts` |
| GET | `/api/v1/admin/annual-reports/:id` | JWT | Permisos: reports:read | Obtener informe anual por ID (admin) | AnnualReportsService.getReport() | `src/annual-reports/annual-reports.controller.ts` |
| PATCH | `/api/v1/admin/annual-reports/:id` | JWT | Permisos: reports:update | Actualizar datos manuales del informe anual (admin) | AnnualReportsService.updateManualData() | `src/annual-reports/annual-reports.controller.ts` |
| POST | `/api/v1/admin/annual-reports/:id/regenerate` | JWT | Permisos: reports:update | Regenerar datos calculados del informe anual (admin) | AnnualReportsService.regenerate() | `src/annual-reports/annual-reports.controller.ts` |
| POST | `/api/v1/admin/annual-reports/:id/finalize` | JWT | Permisos: reports:update | Finalizar informe anual (admin) | AnnualReportsService.finalize() | `src/annual-reports/annual-reports.controller.ts` |
| GET | `/api/v1/admin/annual-reports/:id/pdf` | JWT | Permisos: reports:download | Descargar PDF anual. Nombre: `informe-anual-{club}-{tipo}-{año}.pdf` | AnnualReportsPdfService.generatePdf() | `src/annual-reports/annual-reports.controller.ts` |
| GET | `/api/v1/clubs/:clubId/annual-reports` | JWT | Permisos: reports:read | Listar informes anuales de un club (usuario) | AnnualReportsService.listForClub() | `src/annual-reports/annual-reports.controller.ts` |
| GET | `/api/v1/clubs/:clubId/annual-reports/:id` | JWT | Permisos: reports:read | Obtener informe anual por ID (usuario) | AnnualReportsService.getReport() | `src/annual-reports/annual-reports.controller.ts` |
| GET | `/api/v1/clubs/:clubId/annual-reports/:id/pdf` | JWT | Permisos: reports:download | Descargar PDF anual. Nombre: `informe-anual-{club}-{tipo}-{año}.pdf` | AnnualReportsPdfService.generatePdf() | `src/annual-reports/annual-reports.controller.ts` |

### app.controller.ts

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/` | Public | - | Endpoint raíz de bienvenida/liveness básico | AppService.getHello() | `src/app.controller.ts` |

### auth

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/auth/register` | Public | - | Registrar nuevo usuario. El body exige `accepted_terms_version` y `accepted_privacy_version` (ver «Aceptación legal en registro» más abajo). Versión distinta de la vigente → 400 `LEGAL_VERSION_MISMATCH` sin crear usuario. Opcionales `birthday` (`YYYY-MM-DD`) y `country_id`: si la edad queda por debajo del mínimo del país (13 por defecto) → 422 `AUTH_REGISTRATION_AGE_BELOW_MINIMUM` sin crear nada (ver «Edad mínima de la cuenta»). Fase 3a: con edad de 13 a 17 años, la misma transacción crea una fila `supervised_logins` (`origin = self_registered`, `method = email`, `password_set_by = self`, `pending_since = now`) y la persona queda en modo pendiente de tutor | AuthService.register() | `src/auth/auth.controller.ts` |
| POST | `/api/v1/auth/login` | Public | - | Iniciar sesión. Fase 3a: acepta `identifier` (correo o nombre de usuario) o el `email` heredado; respuesta uniforme y tiempo uniforme; bloqueo progresivo 429 `AUTH_LOGIN_LOCKED`; 403 `AUTH_SUPERVISED_LOGIN_DISABLED` / `AUTH_ACCOUNT_FROZEN` solo con la contraseña correcta; `data.user.principal`. Ver «Inicio de sesión por identificador» | AuthService.login() | `src/auth/auth.controller.ts` |
| POST | `/api/v1/auth/refresh` | Public | - | Refrescar sesión con refresh token. Fase 3b: si la sesión es la de un dispositivo vinculado (la identifica su fila `linked_devices`), pasa por la compuerta del dispositivo ANTES de deslizar la sesión y devuelve solo un JWT de dispositivo (audiencia `sacdia:device`, 1 h; la sesión desliza 30 días sin pasar de su tope absoluto de 180 días). Ver «Dispositivo vinculado de menores de 13 años (Fase 3b)» | AuthService.refreshSession() | `src/auth/auth.controller.ts` |
| POST | `/api/v1/auth/device/pair` | Public | `@SkipPermissions` | Fase 3b. El teléfono del menor canjea el token del QR y recibe su sesión de dispositivo (200 con `accessToken`, `refreshToken`, `device`, `user`). Throttle 5/min y 20/h por IP; 30 canjes fallidos al día por IP → 429. Todo fallo del token o de la familia es el mismo 400 `DEVICE_PAIRING_TOKEN_INVALID`. Contrato en «Dispositivo vinculado de menores de 13 años (Fase 3b)» | DevicePairingService.pair() | `src/auth/device/device-auth.controller.ts` |
| POST | `/api/v1/auth/logout` | Public | - | Cerrar sesión. Fase 3b: cerrar sesión con el refresh token de un dispositivo vinculado lo desvincula (`revoked_reason = device_logout`) | AuthService.logout() | `src/auth/auth.controller.ts` |
| POST | `/api/v1/auth/password/reset-request` | Public | - | Solicitar recuperación de contraseña | AuthService.requestPasswordReset() | `src/auth/auth.controller.ts` |
| POST | `/api/v1/auth/password/reset` | Public | - | Confirmar recuperación de contraseña (`ResetPasswordDto`). Throttle 5/min. No emite sesión ni JWT: el cliente debe iniciar sesión de nuevo. Token inválido o expirado → 400 | AuthService.confirmPasswordReset() | `src/auth/auth.controller.ts` |
| POST | `/api/v1/auth/verify-email/send` | JWT | Scope `self:password` (Fase 3a) | Enviar email de verificación al usuario autenticado | AuthService.sendVerificationEmail() | `src/auth/auth.controller.ts` |
| POST | `/api/v1/auth/verify-email/confirm` | Public | - | Confirmar verificación de email con token | AuthService.confirmEmailVerification() | `src/auth/auth.controller.ts` |
| POST | `/api/v1/auth/update-password` | JWT | Scope `self:password` (Fase 3a: lo tiene el adolescente, pendiente o con tutor; ningún otro tipo no `user`) | Update authenticated user password. Fase 3a: un adolescente avisa a sus tutores verificados (`family:security`, nunca la contraseña) tras una contraseña actual correcta; fija `password_set_by = self` | AuthService.updateOwnPassword() | `src/auth/auth.controller.ts` |
| GET | `/api/v1/auth/me` | JWT | - | Perfil + autorización. Pertenencia no inscrita actual con permisos vacíos. No incluye programación de director. Año solapado → 409 `ECCLESIASTICAL_YEAR_AMBIGUOUS`. Incluye `data.legal` (estado de aceptación legal; ver sección `legal`), siempre leído de la base y fuera del caché de autorización. Perfiles familiares: `data.email` puede ser `null` (dependientes); `data.family` es `{ is_guardian, dependents_count }` con los dependientes activos del usuario (`null` mientras se actúa por un menor); `data.acting_for` es `null`, o con `X-Acting-For` válido `{ actor_user_id, dependent_user_id, guardianship_id, consent_status: "pending"\|"verified", scopes }`. Con el header la respuesta describe al **dependiente** (ver «Actuar en nombre de un dependiente»). **Fase 3a**: añade `data.principal` (`{ kind: "user"|"guardian_acting"|"supervised_user"|"linked_device"|"age_unknown_user", scopes, supervision: null | { status: "pending_guardian"|"active", pending_since, guardians: [{ guardianship_id, consent_status: "pending"|"verified", display_name, relationship_type_name }], summary_visible_to_guardians, days_left } }`, sin datos de contacto), `data.family_features` (`{ teen_login, linked_device, director_create_minor }`), `data.analytics_anonymous` (`true` para cualquier edad menor que la mayoría de edad **y para la edad desconocida**; ausente o desconocido = la app queda anónima) y `data.mode`: `adult\|teen_pending\|teen_supervised\|profile_incomplete` (`profile_incomplete` = `age_unknown_user`, ver «Edad desconocida»). `data.family` es `null` para un adolescente y para la edad desconocida. `acting_for` y `legal` no cambian. **Sin datos de club** para un adolescente pendiente, una edad desconocida y un `supervised_user` sin estado de supervisión (`principalSeesClubData` falso): `authorization.grants.club_assignments` `[]`, `authorization.active_assignment.assignment_id` `null`, `authorization.effective.scope.club` `null`, `authorization.effective.permissions` solo global y directo, `club` `null` y `club_context` vacío, también con una asignación activa anterior al despliegue (ver «Sin datos de club ni credencial hasta que haya un tutor verificado»). **Fase 3b**: con un token de dispositivo vinculado, `data.mode` es `device`, `data.principal.kind` es `linked_device` y `data.principal.device` es `{ linked_device_id, label, paired_at }` (el bloque solo existe para un dispositivo), `data.family` y `data.principal.supervision` son `null` y `data.analytics_anonymous` es siempre `true`; el dispositivo sí ve el contexto de club de su menor (`principalSeesClubData` devuelve `true` para `linked_device`, `src/auth/acting-for/auth-principal.ts:213`). `data.family_features.linked_device` expone la bandera | AuthService.getProfile() | `src/auth/auth.controller.ts` |
| PATCH | `/api/v1/auth/me/context` | JWT | - | Cambiar contexto activo. `inactive`/`ended`/año no vigente/`designated` → 400 `AUTH_ASSIGNMENT_YEAR_MISMATCH`. Corte del club no completado → 503 `CLUB_CYCLE_NOT_READY`. No invalida JWT. Scope `club:context` (Fase 3a): lo tienen el tutor actuando y el adolescente activo, **no** el dispositivo vinculado; un adolescente pendiente o una edad desconocida reciben 403 `PRINCIPAL_SCOPE_DENIED` | AuthService.setActiveClubContext() | `src/auth/auth.controller.ts` |
| GET | `/api/v1/auth/profile/completion-status` | JWT | - | Obtener estado del post-registro | AuthService.getCompletionStatus() | `src/auth/auth.controller.ts` |
| DELETE | `/api/v1/auth/me` | JWT | - | Eliminar cuenta del usuario autenticado (contraseña o `{ provider, idToken, nonce }`; nunca ambos → 400). Throttle 3/hora. Tutores: si tiene dependientes activos, el body debe llevar `"acknowledge_dependents": true` (opcional, boolean); sin él responde 409 `AUTH_DELETE_DEPENDENTS_ACK_REQUIRED` **sin cambiar nada** (la comprobación va después de re-autenticar y antes de revocar Apple). El cliente obtiene la lista y el resultado de cada menor de `GET /api/v1/guardianships/me/deletion-impact`, no del 409. Al confirmar, en la misma transacción cada menor pasa a otro tutor, a custodia del club o se congela 90 días; si algo falla, la cuenta no se elimina. No disponible actuando por un menor | AccountDeletionService.deleteAccount() | `src/auth/auth.controller.ts` |
| POST | `/api/v1/auth/mfa/enroll` | JWT | - | Habilitar 2FA (TOTP) | MfaService.enrollMfa() | `src/auth/mfa.controller.ts` |
| POST | `/api/v1/auth/mfa/verify` | JWT | - | Verificar código TOTP | MfaService.verifyMfa() | `src/auth/mfa.controller.ts` |
| DELETE | `/api/v1/auth/mfa/disable` | JWT | - | Deshabilitar 2FA | MfaService.disableMfa() | `src/auth/mfa.controller.ts` |
| GET | `/api/v1/auth/mfa/status` | JWT | - | Estado de 2FA | MfaService.getMfaStatus() | `src/auth/mfa.controller.ts` |
| GET | `/api/v1/auth/sessions` | JWT | - | List active sessions. Fase 3b: cada ítem lleva `kind` (`user` o `device`) y `linked_device_id` (`null` salvo en una sesión de dispositivo; se sabe por la fila `linked_devices`, `src/auth/sessions.service.ts`) | SessionsService.listSessions() | `src/auth/sessions.controller.ts` |
| DELETE | `/api/v1/auth/sessions/:sessionId` | JWT | - | Revoke a specific session. Fase 3b: si la sesión era la de un dispositivo vinculado, el dispositivo queda revocado con motivo `session_revoked` | SessionsService.revokeSession() | `src/auth/sessions.controller.ts` |
| DELETE | `/api/v1/auth/sessions` | JWT | - | Revoke all other sessions. Fase 3b: ídem `session_revoked` para los dispositivos cuya sesión se borra | SessionsService.revokeAllOtherSessions() | `src/auth/sessions.controller.ts` |

### OAuth

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/auth/oauth/:provider/token` | Public | - | Iniciar sesión con un id token nativo de Google o Apple (`provider` = `google` \| `apple`). Throttle 5/min por IP. Contrato abajo | SocialSignInService.signIn() | `src/auth/social-sign-in/social-sign-in.controller.ts` |
| GET | `/api/v1/auth/oauth/providers` | JWT | - | Obtener providers OAuth conectados | OAuthService.getConnectedProviders() | `src/auth/oauth.controller.ts` |
| DELETE | `/api/v1/auth/oauth/:provider` | JWT | - | Desconectar un provider OAuth | OAuthService.disconnectProvider() | `src/auth/oauth.controller.ts` |

#### Contrato `POST /api/v1/auth/oauth/:provider/token`

Diseño: `docs/plans/2026-10-14-native-social-sign-in-design.md`. Configuración de consolas y variables: `docs/guides/SOCIAL-SIGN-IN-SETUP.md`. Los endpoints `POST /auth/oauth/google`, `/apple` y `/callback` (flujo con navegador de Better Auth) se retiran en el slice B4 de sacdia-backend, pendiente de merge junto con el cambio de `DELETE /auth/me` (B3).

##### Request

```json
{
  "idToken": "<id token del SDK nativo>",
  "nonce": "<nonce en claro>",
  "authorizationCode": "<solo Apple>",
  "fullName": { "givenName": "...", "familyName": "..." }
}
```

- `idToken` y `nonce` son obligatorios. `authorizationCode` y `fullName` son opcionales y solo los manda Apple (el nombre llega únicamente en el primer login).
- La app manda el nonce **en claro**. El claim `nonce` del id token debe ser igual a `sha256hex(nonce)` para **Google y Apple**: la app entrega el hash al SDK.
- Se rechazan los tokens de más de 10 minutos de antigüedad (tolerancia de reloj de 30 s).

##### Éxito (201)

Envuelto en `{ "status": "success", "data": ... }`:

```json
{
  "accessToken": "<JWT HS256>",
  "sessionToken": "<token opaco de sesión>",
  "refreshToken": "<token opaco de sesión>",
  "expiresAt": 1760000000,
  "tokenType": "bearer",
  "user": {
    "id": "...",
    "email": "...",
    "name": "...",
    "paternal_last_name": "...",
    "maternal_last_name": "...",
    "avatar": "...",
    "connectedProviders": ["google"]
  },
  "needsPostRegistration": false
}
```

`expiresAt` está en segundos Unix. `needsPostRegistration` es `true` cuando el usuario se acaba de crear. Si el usuario tiene TOTP activo, `accessToken` es un JWT `mfa_pending`, igual que en `POST /auth/login`.

##### Errores

| HTTP | Código | Cuándo |
| --- | --- | --- |
| 400 | `AUTH_OAUTH_PROVIDER_INVALID` | `provider` distinto de `google` o `apple` |
| 400 | (validación) | Body inválido, por ejemplo `{}` |
| 401 | `AUTH_INVALID_TOKEN` | Firma, `iss`, `aud` o `exp` inválidos; token de más de 10 minutos; `nonce` que no coincide; correo de más de 100 caracteres |
| 401 | `AUTH_OAUTH_EMAIL_UNVERIFIED` | El token no trae correo o `email_verified` es falso |
| 409 | `AUTH_OAUTH_PROVIDER_ALREADY_LINKED` | La cuenta verificada ya está vinculada a otra identidad del mismo proveedor |
| 429 | - | Throttle (5/min por IP) |
| 503 | `AUTH_OAUTH_PROVIDER_UNAVAILABLE` | No se pueden obtener las llaves públicas de Google o Apple |

##### Resolución de cuenta

- La identidad es `(provider, sub)`. Si existe, entra ese usuario.
- Si no, se busca por correo y se vincula. Si esa cuenta local nunca verificó su correo, se toma: se borran todas sus sesiones, sus filas de `accounts` (contraseña incluida) y su secreto TOTP, y sus JWT entran a la lista negra.
- Si el correo no existe, se crea el usuario y `needsPostRegistration` es `true`.
- La foto del proveedor solo llena un avatar vacío.
- Apple: `authorizationCode` se canjea en el servidor por un refresh token. Se guarda solo si el `sub` del id token de ese canje coincide con el del login. Sirve para revocar el acceso al borrar la cuenta.

##### `DELETE /api/v1/auth/me`

Body: `{ "password": "..." }` **o** `{ "provider", "idToken", "nonce" }`. Mandar ambos es 400. El id token debe pertenecer a un proveedor vinculado al usuario autenticado. Antes de borrar se revoca el refresh token de Apple (si existe), se eliminan las sesiones y el TOTP de la cuenta y sus JWT entran a la lista negra.

**Tutores con dependientes** (perfiles familiares): si el usuario tiene dependientes activos, el body debe llevar `"acknowledge_dependents": true`; sin él, 409 `AUTH_DELETE_DEPENDENTS_ACK_REQUIRED` sin cambiar nada. Primero se re-autentica (contraseña o id token): el 409 solo llega con credenciales válidas. El cliente no depende de `details` del 409: pide la lista y el resultado de cada menor a `GET /api/v1/guardianships/me/deletion-impact` antes de llamar a `DELETE`. En la misma transacción de la eliminación cada menor pasa a otro tutor, a custodia del club o se congela 90 días. También se borran la IP y el user agent de las filas de `legal_acceptances` del propio usuario **y de las aceptaciones que hizo en nombre de sus dependientes** (`accepted_by_user_id` = el tutor), porque llevan la IP y el dispositivo del tutor.

#### Aceptación legal en registro

`POST /api/v1/auth/register` agrega dos campos obligatorios al body, con la versión vigente que devuelve `GET /api/v1/legal/current`:

```json
{
  "accepted_terms_version": "1.0.0-store",
  "accepted_privacy_version": "1.0.0-store"
}
```

- Ambos son string, se recortan (`trim`) y tienen máximo 32 caracteres.
- Falta, vacío, en blanco, no string o más largo de 32 → 400 de validación genérica (`ValidationPipe`), no `LEGAL_VERSION_MISMATCH`.
- Texto distinto de la versión vigente (comparación exacta, sensible a mayúsculas, tras `trim`) → 400 `{ "status": "error", "statusCode": 400, "code": "LEGAL_VERSION_MISMATCH", "message": "<traducido>", "timestamp": "...", "path": "..." }`.
- La validación ocurre antes de `createUser`: con 400 no se crea usuario, cuenta ni sesión.
- Con éxito, las dos filas de `legal_acceptances` (`method = register_checkbox`, con IP y user agent de la petición) se escriben en la misma transacción del registro.

#### Edad mínima de la cuenta

> Perfiles familiares, rama `feat/family-profiles`, Pendiente de merge (PR #530 de sacdia-backend). Quien tiene menos de la edad mínima de cuenta de su país (`countries.minor_self_login_min_age`, 13 por defecto si el país es desconocido) no puede tener cuenta propia: lo registra un tutor desde `POST /api/v1/guardianships/me/dependents`. Dos puntos de control; el segundo es el autoritativo.

| Dónde | Regla | Error |
| --- | --- | --- |
| `POST /api/v1/auth/register` | `birthday` es **opcional** en la API (la app lo exige). Si llega, la edad se calcula con el calendario de la zona horaria del país (`country_id` opcional; sin él, los valores por defecto 13 y `America/Mexico_City`). Va **antes** de `createUser`: con 422 no se crea usuario, cuenta ni sesión. Fase 3a: la fecha **se guarda** junto con la cuenta (`users.birthday`, UTC medianoche) y `country_id` también, cuando el país existe (`AuthService.register`, `src/auth/auth.service.ts:211-221`); antes solo se validaba y por eso un adolescente recién registrado figuraba como adulto hasta el paso 2 (corregido en `9f83891d`). Una fecha que no sea un `YYYY-MM-DD` real → 400 de validación | 422 `AUTH_REGISTRATION_AGE_BELOW_MINIMUM` |
| `PATCH /api/v1/users/:userId` | Aplica a cualquier titular de una cuenta (también con inicio de sesión social) que edita **su propio** perfil con una `birthday` por debajo del mínimo de su país. No aplica a un tutor actuando por un menor, ni a ediciones de admin sobre otra persona | 422 `USER_SELF_ACCOUNT_BELOW_MINIMUM_AGE` |

El registro sin `birthday` sigue siendo posible por API, y el inicio de sesión social crea la cuenta sin pasar por `register`. En ambos casos el PATCH cubre el hueco en cuanto el usuario guarda su fecha de nacimiento (paso 2 del post-registro). Entre tanto la cuenta existe, pero desde la Fase 3a **queda restringida** (`age_unknown_user`, ver «Edad desconocida (`kind: age_unknown_user`)»).

> **Fase 3a** (Pendiente de merge (PR #531 de sacdia-backend)): la regla de la Fase 2 sigue (por debajo del mínimo no hay cuenta), pero **de 13 a 17 años ya se puede registrar solo**: queda en modo pendiente de tutor (`supervised_user`) y no entra a un club hasta que un tutor se vincule y un director verifique el consentimiento (ver «Cuentas supervisadas de 13 a 17 años (Fase 3a)»). Una cuenta sin fecha de nacimiento cuyo post-registro está incompleto es `age_unknown_user` (restringida, solo puede terminar el post-registro y salir de la cuenta); en cualquier otra cuenta sin fecha el principal es `user`, pero la compuerta de activación falla cerrada.

### camporee-event-templates

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/camporee-event-templates` | JWT | Permisos: camporee_events:read | List camporee event templates (filtered by role scope) | CamporeeEventTemplatesService.listTemplates() | `src/camporee-event-templates/camporee-event-templates.controller.ts` |
| GET | `/api/v1/camporee-event-templates/:templateId` | JWT | Permisos: camporee_events:read | Get camporee event template by ID | CamporeeEventTemplatesService.getTemplate() | `src/camporee-event-templates/camporee-event-templates.controller.ts` |
| POST | `/api/v1/camporee-event-templates` | JWT | Permisos: camporee_events:create | Create camporee event template | CamporeeEventTemplatesService.createTemplate() | `src/camporee-event-templates/camporee-event-templates.controller.ts` |
| PATCH | `/api/v1/camporee-event-templates/:templateId` | JWT | Permisos: camporee_events:update | Update camporee event template | CamporeeEventTemplatesService.updateTemplate() | `src/camporee-event-templates/camporee-event-templates.controller.ts` |
| DELETE | `/api/v1/camporee-event-templates/:templateId` | JWT | Permisos: camporee_events:delete | Soft delete camporee event template | CamporeeEventTemplatesService.deleteTemplate() | `src/camporee-event-templates/camporee-event-templates.controller.ts` |

### camporee-events

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/camporee-event-types` | JWT | Permisos: camporee_events:read | List active camporee event types for event forms | CamporeeEventsService.listEventTypes() | `src/camporee-events/camporee-events.controller.ts` |
| GET | `/api/v1/local-camporees/:camporeeId/events` | JWT | Permisos: camporee_events:read | List events for a local camporee | CamporeeEventsService.listEvents() | `src/camporee-events/camporee-events.controller.ts` |
| GET | `/api/v1/local-camporees/:camporeeId/events/preview` | JWT | Permisos: camporee_events:read | List app-safe event preview for a local camporee, hiding agenda until configured release | CamporeeEventsService.listEvents() | `src/camporee-events/camporee-events.controller.ts` |
| POST | `/api/v1/local-camporees/:camporeeId/events` | JWT | Permisos: camporee_events:create | Create custom event for a local camporee | CamporeeEventsService.createEvent() | `src/camporee-events/camporee-events.controller.ts` |
| POST | `/api/v1/local-camporees/:camporeeId/events/from-template/:templateId` | JWT | Permisos: camporee_events:create | Clone a template as an event for a local camporee | CamporeeEventsService.createFromTemplate() | `src/camporee-events/camporee-events.controller.ts` |
| GET | `/api/v1/union-camporees/:camporeeId/events` | JWT | Permisos: camporee_events:read | List events for a union camporee | CamporeeEventsService.listEvents() | `src/camporee-events/camporee-events.controller.ts` |
| GET | `/api/v1/union-camporees/:camporeeId/events/preview` | JWT | Permisos: camporee_events:read | List app-safe event preview for a union camporee, hiding agenda until configured release | CamporeeEventsService.listEvents() | `src/camporee-events/camporee-events.controller.ts` |
| POST | `/api/v1/union-camporees/:camporeeId/events` | JWT | Permisos: camporee_events:create | Create custom event for a union camporee | CamporeeEventsService.createEvent() | `src/camporee-events/camporee-events.controller.ts` |
| POST | `/api/v1/union-camporees/:camporeeId/events/from-template/:templateId` | JWT | Permisos: camporee_events:create | Clone a template as an event for a union camporee | CamporeeEventsService.createFromTemplate() | `src/camporee-events/camporee-events.controller.ts` |
| GET | `/api/v1/camporee-events/:eventId` | JWT | Permisos: camporee_events:read | Get a camporee event instance by ID | CamporeeEventsService.getEvent() | `src/camporee-events/camporee-events.controller.ts` |
| PATCH | `/api/v1/camporee-events/:eventId` | JWT | Permisos: camporee_events:update | Update a camporee event instance (overrides) | CamporeeEventsService.updateEvent() | `src/camporee-events/camporee-events.controller.ts` |
| GET | `/api/v1/camporee-events/:eventId/staff-assignments` | JWT | Permisos: camporee_events:read | List staff assignments for a camporee event | CamporeeEventsService.listEventStaffAssignments() | `src/camporee-events/camporee-events.controller.ts` |
| PUT | `/api/v1/camporee-events/:eventId/staff-assignments` | JWT | Permisos: camporee_events:update | Replace staff assignments for a camporee event | CamporeeEventsService.replaceEventStaffAssignments() | `src/camporee-events/camporee-events.controller.ts` |
| PUT | `/api/v1/camporee-events/:eventId/schedule-blocks` | JWT | Permisos: camporee_events:update | Replace optional schedule blocks and club-section assignments for a camporee event | CamporeeEventsService.replaceScheduleBlocks() | `src/camporee-events/camporee-events.controller.ts` |
| DELETE | `/api/v1/camporee-events/:eventId` | JWT | Permisos: camporee_events:delete | Soft delete a camporee event instance | CamporeeEventsService.deleteEvent() | `src/camporee-events/camporee-events.controller.ts` |
| PATCH | `/api/v1/camporee-events/:eventId/reorder` | JWT | Permisos: camporee_events:update | Update display_order of a camporee event instance | CamporeeEventsService.reorderEvent() | `src/camporee-events/camporee-events.controller.ts` |

POST/PATCH de instancia aceptan `honor_ids?: number[]` (máx. 20, únicos, honores activos). Omitir en PATCH no toca la lista; `[]` la vacía. GET, list y preview incluyen `honors[]` (`honor_id`, `name`, `honor_image`, `material_url`, `honors_category_id`, `category_name`, `skill_level`, `active`, `display_order`). Preview no oculta honores aunque la agenda esté cerrada. Errores: `CAMPOREE_EVENT_HONOR_NOT_FOUND`, `CAMPOREE_EVENT_HONOR_DUPLICATE`, `CAMPOREE_EVENT_HONOR_LIMIT`. No hay ruta dedicada. Templates y `from-template` no copian honores.

### camporee-scoring

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/camporee-events/:eventId/rubrics` | JWT | - | List active rubrics for a camporee event | CamporeeScoringService.getEventRubrics() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| PUT | `/api/v1/camporee-events/:eventId/rubrics` | JWT | Permisos: camporee_events:update | Replace rubrics for a camporee event | CamporeeScoringService.replaceEventRubrics() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| GET | `/api/v1/local-camporees/:camporeeId/judges` | JWT | Permisos: camporee_events:read | Listar/consultar local-camporees/{id}/judges | CamporeeScoringService.listCamporeeJudges() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| GET | `/api/v1/local-camporees/:camporeeId/judge-candidates` | JWT | Permisos: camporee_events:update | Listar/consultar local-camporees/{id}/judge-candidates | CamporeeScoringService.listCamporeeJudgeCandidates() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| POST | `/api/v1/local-camporees/:camporeeId/judges` | JWT | Permisos: camporee_events:update | Crear/ejecutar local-camporees/{id}/judges | CamporeeScoringService.addJudgeToCamporee() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| GET | `/api/v1/union-camporees/:camporeeId/judges` | JWT | Permisos: camporee_events:read | Listar/consultar union-camporees/{id}/judges | CamporeeScoringService.listCamporeeJudges() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| GET | `/api/v1/union-camporees/:camporeeId/judge-candidates` | JWT | Permisos: camporee_events:update | Listar/consultar union-camporees/{id}/judge-candidates | CamporeeScoringService.listCamporeeJudgeCandidates() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| POST | `/api/v1/union-camporees/:camporeeId/judges` | JWT | Permisos: camporee_events:update | Crear/ejecutar union-camporees/{id}/judges | CamporeeScoringService.addJudgeToCamporee() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| PATCH | `/api/v1/camporee-judges/:judgeId` | JWT | Permisos: camporee_events:update + scope del camporee del juez | Actualizar `notes`, `status` o `active` del juez | CamporeeScoringService.updateCamporeeJudge() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| DELETE | `/api/v1/camporee-judges/:judgeId` | JWT | Permisos: camporee_events:update + scope del camporee del juez | Desactivar al juez (`status=inactive`, `active=false`) y sus asignaciones activas | CamporeeScoringService.deactivateCamporeeJudge() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| GET | `/api/v1/camporee-events/:eventId/judge-assignments` | JWT | Permisos: camporee_events:read | Listar/consultar camporee-events/{id}/judge-assignments | CamporeeScoringService.listEventJudgeAssignments() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| POST | `/api/v1/camporee-events/:eventId/judge-assignments` | JWT | Permisos: camporee_events:update | Crear/ejecutar camporee-events/{id}/judge-assignments | CamporeeScoringService.assignJudgeToSection() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| PATCH | `/api/v1/camporee-event-judge-assignments/:assignmentId` | JWT | - | Actualizar camporee-event-judge-assignments/{id} | CamporeeScoringService.updateJudgeAssignment() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| DELETE | `/api/v1/camporee-event-judge-assignments/:assignmentId` | JWT | - | Eliminar/desactivar camporee-event-judge-assignments/{id} | CamporeeScoringService.deactivateJudgeAssignment() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| GET | `/api/v1/camporee-events/:eventId/scoring-targets` | JWT | - | List enrolled sections that can receive scores; each row includes `active_result_id` (`null` if the section has no official result yet) | CamporeeScoringService.getScoringTargets() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| GET | `/api/v1/camporee-events/:eventId/sections/:clubSectionId/score` | JWT | - | Mergeado con el PR #448 de sacdia-backend (antes solo existía el `POST .../scores`). Active official score for one section, or `data: null` when none exists. Includes items, totals and `evaluator_name` | CamporeeScoringService.getOfficialScore() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| POST | `/api/v1/camporee-events/:eventId/sections/:clubSectionId/scores` | JWT | Header opcional `Idempotency-Key: <UUID>`; juez primary o override autorizado | Submit official camporee score/no-show with serialized target and replay-safe receipt | CamporeeScoringService.submitScore() | `src/camporee-scoring/camporee-scoring.controller.ts` |

#### Contrato de captura oficial de score

- Los listados `GET .../judges` devuelven `camporee_judge_id`, `user_id`, `name`, `email`, `notes`, `user_image`, `status` y `active`. Sólo incluyen filas activas del roster solicitado.
- `PATCH /camporee-judges/:judgeId` acepta `{ notes?: string | null, status?: "active" | "inactive", active?: boolean }`. Requiere `camporee_events:update`; el servicio resuelve el camporee padre desde el UUID del juez y valida acceso `current-write` antes de mutar. Un UUID inexistente devuelve `404 CAMPOREE_SCORING_JUDGE_NOT_FOUND` y un actor sin scope devuelve `403 CAMPOREE_EVENT_ACCESS_DENIED`.
- Cuando `PATCH` deja `active=false` o un `status` distinto de `active`, y siempre en `DELETE`, el juez y todas sus asignaciones activas se desactivan en la misma transacción. Las submissions/resultados históricos no se eliminan ni bloquean la operación: conservan su vínculo auditable con la asignación inactiva, por lo que este flujo no devuelve `409` por scores existentes.
- Desactivar el roster de scoring no desactiva automáticamente la fila independiente de `camporee_staff_members`; esa persona puede seguir cumpliendo una función operativa no relacionada con scoring.

- `GET /camporee-events/:eventId/rubrics` responde `{ data: rúbricas, min_points }`. `min_points` es el piso del evento; si es mayor que cero y la suma de criterios queda debajo, el puntaje oficial sube a ese piso. El listado de criterios sigue en `data`. `GET /camporee-events/:eventId/scoring-targets` no exige `camporee_events:read` en el guard: un juez activo asignado al evento también puede leer. El servicio rechaza al resto con `CAMPOREE_SCORING_FORBIDDEN`. Cada scoring-target incluye `active_result_id` para que admin envíe `expected_active_result_id` en un override.
- `POST /camporee-events/:eventId/sections/:clubSectionId/scores` tampoco exige `camporee_events:update` en el guard. El servicio acepta juez `primary` asignado (`judge_primary`) o gestores LF/Unión/admin con scope (`manual_lf`/`admin_override`).
- `Idempotency-Key` es opcional por compatibilidad, pero si llega debe ser UUID. El replay del mismo actor, clave y payload canónico devuelve el receipt original sin mutación; reutilizar la clave con otro payload devuelve `409 IDEMPOTENCY_KEY_REUSED`.
- `source` es una intención no confiable: el servidor deriva `judge_primary` para el juez principal asignado cuando no solicita override, `manual_lf` para gestores LF/Unión autorizados y `admin_override` sólo para `admin`, `assistant-admin` o `super-admin`. El permiso `camporee_events:update` por sí solo no autoriza scoring.
- El payload canónico incluye target, source efectiva, `no_show`/estado, notas, `expected_active_result_id` e ítems ordenados por rúbrica; no incluye timestamps.
- Con `Idempotency-Key`, el orden de serialización es fijo: lock bigint por `hashtextextended(prefijo + submitted_by + key, 0)`, lock `pg_advisory_xact_lock(eventId::integer, clubSectionId::integer)`, lookup idempotente y lectura del resultado activo. Los casts explícitos compensan que Prisma enlaza números JavaScript como `INT8` y fuerzan el overload PostgreSQL `(integer, integer)`. Ambos overloads usan keyspaces separados; el hash de 64 bits conserva un riesgo teórico de colisión que sólo sobre-serializa.
- Si el índice único produce `P2002` pese al lock, el servicio relee fuera de la transacción: mismo hash y receipt completo devuelve replay; hash distinto devuelve `409 IDEMPOTENCY_KEY_REUSED`; ausencia de fila relanza el error original. Un receipt sin resultado asociado falla con `500 CAMPOREE_SCORING_RECEIPT_INCOMPLETE`.
- Un override efectivo `manual_lf` o `admin_override` sobre resultado activo debe enviar `expected_active_result_id` igual al ID activo y `notes` no vacío como motivo; si falta el motivo devuelve `400 CAMPOREE_SCORING_OVERRIDE_REASON_REQUIRED`, y si el resultado no coincide devuelve `409 CAMPOREE_SCORING_RESULT_STALE`. El primer score manual, sin activo, puede omitir ambos.
- El receipt estable incluye `camporee_event_section_result_id`, `camporee_event_score_submission_id`, `score_status`, `raw_awarded_points`, `minimum_adjustment_points`, `total_awarded_points`, `total_max_points`, `percentage`, actor/timestamps de submit/finalización, `notes` e `items`. Su `active=true` es un snapshot del estado al emitirse; no representa el estado actual del resultado después de un override.
| GET | `/api/v1/local-camporees/:camporeeId/leaderboard` | JWT | Permisos: camporee_events:read | Obtener local-camporees/{id}/leaderboard | CamporeeScoringService.getCamporeeLeaderboard() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| GET | `/api/v1/union-camporees/:camporeeId/leaderboard` | JWT | Permisos: camporee_events:read | Obtener union-camporees/{id}/leaderboard | CamporeeScoringService.getCamporeeLeaderboard() | `src/camporee-scoring/camporee-scoring.controller.ts` |
| GET | `/api/v1/camporee-judges/me/assignments` | JWT | - | List current user camporee judge assignments (`event_title`, `club_name`, `section_name`, `can_submit_score`) | CamporeeScoringService.getMyJudgeAssignments() | `src/camporee-scoring/camporee-scoring.controller.ts` |

### camporee-staff

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/local-camporees/:camporeeId/staff` | JWT | Permisos: camporee_events:read | List staff roster for a local camporee | CamporeeStaffService.listStaff() | `src/camporee-staff/camporee-staff.controller.ts` |
| GET | `/api/v1/local-camporees/:camporeeId/staff-candidates` | JWT | Permisos: camporee_events:update | List active users eligible for a local camporee roster | CamporeeStaffService.listStaffCandidates() | `src/camporee-staff/camporee-staff.controller.ts` |
| POST | `/api/v1/local-camporees/:camporeeId/staff` | JWT | Permisos: camporee_events:update | Add a staff member to a local camporee roster | CamporeeStaffService.addStaffMember() | `src/camporee-staff/camporee-staff.controller.ts` |
| GET | `/api/v1/union-camporees/:camporeeId/staff` | JWT | Permisos: camporee_events:read | List staff roster for a union camporee | CamporeeStaffService.listStaff() | `src/camporee-staff/camporee-staff.controller.ts` |
| GET | `/api/v1/union-camporees/:camporeeId/staff-candidates` | JWT | Permisos: camporee_events:update | List active users eligible for a union camporee roster | CamporeeStaffService.listStaffCandidates() | `src/camporee-staff/camporee-staff.controller.ts` |
| POST | `/api/v1/union-camporees/:camporeeId/staff` | JWT | Permisos: camporee_events:update | Add a staff member to a union camporee roster | CamporeeStaffService.addStaffMember() | `src/camporee-staff/camporee-staff.controller.ts` |
| PATCH | `/api/v1/camporee-staff/:staffMemberId` | JWT | Permisos: camporee_events:update | Update a camporee staff roster member | CamporeeStaffService.updateStaffMember() | `src/camporee-staff/camporee-staff.controller.ts` |
| DELETE | `/api/v1/camporee-staff/:staffMemberId` | JWT | Permisos: camporee_events:update | Deactivate a camporee staff roster member | CamporeeStaffService.deactivateStaffMember() | `src/camporee-staff/camporee-staff.controller.ts` |

### camporee-venues

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/camporee-venues` | JWT | Permisos: camporee_events:read | List all venues with optional filters | CamporeeVenuesService.listVenues() | `src/camporee-venues/camporee-venues.controller.ts` |
| GET | `/api/v1/camporee-venues/:venueId` | JWT | Permisos: camporee_events:read | Get a single venue by ID | CamporeeVenuesService.getVenueById() | `src/camporee-venues/camporee-venues.controller.ts` |
| POST | `/api/v1/camporee-venues` | JWT | Permisos: camporee_events:create | Create a venue (explicit scope + union/local_field) | CamporeeVenuesService.createVenue() | `src/camporee-venues/camporee-venues.controller.ts` |
| PATCH | `/api/v1/camporee-venues/:venueId` | JWT | Permisos: camporee_events:update | Update a venue | CamporeeVenuesService.updateVenue() | `src/camporee-venues/camporee-venues.controller.ts` |
| DELETE | `/api/v1/camporee-venues/:venueId` | JWT | Permisos: camporee_events:delete | Soft-delete a venue (sets active = false) | CamporeeVenuesService.deleteVenue() | `src/camporee-venues/camporee-venues.controller.ts` |
| GET | `/api/v1/local-camporees/:camporeeId/venues` | JWT | Permisos: camporee_events:read | List venues accessible to a local camporee | CamporeeVenuesService.listVenuesForCamporee() | `src/camporee-venues/camporee-venues.controller.ts` |
| POST | `/api/v1/local-camporees/:camporeeId/venues` | JWT | Permisos: camporee_events:create | Create a venue scoped to the local camporee's local_field | CamporeeVenuesService.createVenueForLocalCamporee() | `src/camporee-venues/camporee-venues.controller.ts` |
| GET | `/api/v1/union-camporees/:camporeeId/venues` | JWT | Permisos: camporee_events:read | List venues accessible to a union camporee | CamporeeVenuesService.listVenuesForCamporee() | `src/camporee-venues/camporee-venues.controller.ts` |
| POST | `/api/v1/union-camporees/:camporeeId/venues` | JWT | Permisos: camporee_events:create | Create a venue scoped to the union camporee's union | CamporeeVenuesService.createVenueForUnionCamporee() | `src/camporee-venues/camporee-venues.controller.ts` |

### camporees

Los `POST` y `PATCH` de camporees locales y de unión aceptan `start_date` y `end_date` exclusivamente como `YYYY-MM-DD` válido. `club_registration_opens_at`, `club_registration_deadline`, `member_registration_deadline` y `payment_deadline` exigen ISO-8601 con `Z` u offset explícito; no se aceptan fechas sin hora. `timezone` debe ser IANA: al enviarla explícitamente, el backend registra la verificación con el actor autenticado; omitirla en `PATCH` conserva la verificación anterior. La política única resuelve la fase por calendario local y la disposición de clubes: cierre manual primero, luego `not_open_yet`, `open` hasta el deadline inclusivo, y `late_approval_required` sólo después. `not_open_yet` no crea ni habilita aprobación tardía.

`GET`/`POST`/`PATCH` de camporee local y de unión incluyen `orders_enabled`, `orders_opens_at` y `orders_deadline`. No hay `GET` dedicado de orders-settings; la ventana también viaja en `GET .../order-offerings`. Mutación dedicada: `PATCH .../orders-settings`. Ver §camporee orders.

Los mismos `GET`/`POST` de camporee aceptan `supply_edit_cutoff_local_time` (default `21:00`). Mutación dedicada: `PATCH .../supply-settings`. Ver §camporee supplies.

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/camporees` | JWT | Permisos: camporees:read. Recorte territorial rol-primero (`director-lf`/unión/división y admin con ancla); coordinador sin asignación de club → denegado. Query opcional `club_type_id` (1=Aventureros, 2=Conquistadores, 3=Guías Mayores) recorta por `includes_*`; sin el query el catálogo territorial queda completo (admin). | Listar camporees | CamporeesService.findAll() | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/union` | JWT | Permisos: camporees:read. Mismo recorte rol-primero que el listado local (campo / unión / división). | Listar camporees de unión | CamporeesService.findAllUnion() | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/union/:camporeeId` | JWT | Permisos: camporees:read | Obtener camporee de unión por ID | CamporeesService.findOneUnion() | `src/camporees/camporees.controller.ts` |
| POST | `/api/v1/camporees/union` | JWT | Permisos: camporees:create | Crear camporee de unión | CamporeesService.createUnion() | `src/camporees/camporees.controller.ts` |
| PATCH | `/api/v1/camporees/union/:camporeeId` | JWT | Permisos: camporees:update | Actualizar camporee de unión | CamporeesService.updateUnion() | `src/camporees/camporees.controller.ts` |
| DELETE | `/api/v1/camporees/union/:camporeeId` | JWT | Permisos: camporees:delete | Desactivar camporee de unión | CamporeesService.removeUnion() | `src/camporees/camporees.controller.ts` |
| POST | `/api/v1/camporees/union/:camporeeId/clubs` | JWT | Permisos: attendance:manage | Inscribir club en camporee de unión | CamporeesService.enrollClubToUnion() | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/union/:camporeeId/clubs` | JWT | Permisos: attendance:read | Listar clubes inscritos en camporee de unión | CamporeesService.getUnionEnrolledClubs() | `src/camporees/camporees.controller.ts` |
| DELETE | `/api/v1/camporees/union/:camporeeId/clubs/:camporeeClubId` | JWT | Permisos: attendance:manage | Cancelar inscripción de club en camporee de unión | CamporeesService.cancelUnionClubEnrollment() | `src/camporees/camporees.controller.ts` |
| POST | `/api/v1/union-camporees/:camporeeId/club-registration/close` | JWT | Permisos: camporee_events:update | Close union camporee club registration | CamporeesService.closeUnionCamporeeClubRegistration() | `src/camporees/camporee-club-registration.controller.ts` |
| POST | `/api/v1/union-camporees/:camporeeId/club-registration/reopen` | JWT | Permisos: camporee_events:update | Reopen union camporee club registration | CamporeesService.reopenUnionCamporeeClubRegistration() | `src/camporees/camporee-club-registration.controller.ts` |
| POST | `/api/v1/camporees/union/:camporeeId/register` | JWT | Permisos: attendance:manage | Registrar miembro en camporee de unión | CamporeesService.registerMemberToUnion() | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/union/:camporeeId/members` | JWT | Permisos: attendance:read | Listar miembros del camporee de unión | CamporeesService.getUnionMembers() | `src/camporees/camporees.controller.ts` |
| DELETE | `/api/v1/camporees/union/:camporeeId/members/:userId` | JWT | Permisos: attendance:manage | Remover miembro del camporee de unión | CamporeesService.removeUnionMember() | `src/camporees/camporees.controller.ts` |
| POST | `/api/v1/camporees/union/:camporeeId/members/:memberId/payments` | JWT | Permisos: attendance:manage | Registrar pago de miembro en camporee de unión | CamporeesService.createUnionPayment() | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/union/:camporeeId/members/:memberId/payments` | JWT | Permisos: attendance:read | Listar pagos de un miembro en camporee de unión | CamporeesService.getUnionMemberPayments() | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/union/:camporeeId/payments` | JWT | Permisos: attendance:read | Listar todos los pagos del camporee de unión | CamporeesService.getUnionCamporeePayments() | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/union/:camporeeId/pending` | JWT | Permisos: attendance:approve_late | Listar inscripciones pendientes de aprobación en camporee de unión | CamporeeLateApprovalsService.listUnionPending() | `src/camporees/camporees.controller.ts` |
| PATCH | `/api/v1/camporees/union/:camporeeId/clubs/:camporeeClubId/approve` | JWT | Permisos: attendance:approve_late | Aprobar inscripción tardía de club en camporee de unión | CamporeeLateApprovalsService.approveUnionClubEnrollment() | `src/camporees/camporees.controller.ts` |
| PATCH | `/api/v1/camporees/union/:camporeeId/clubs/:camporeeClubId/reject` | JWT | Permisos: attendance:approve_late | Rechazar inscripción tardía de club en camporee de unión | CamporeeLateApprovalsService.rejectUnionClubEnrollment() | `src/camporees/camporees.controller.ts` |
| PATCH | `/api/v1/camporees/union/:camporeeId/members/:camporeeMemberId/approve` | JWT | Permisos: attendance:approve_late | Aprobar inscripción tardía de miembro en camporee de unión | CamporeeLateApprovalsService.approveUnionMemberEnrollment() | `src/camporees/camporees.controller.ts` |
| PATCH | `/api/v1/camporees/union/:camporeeId/members/:camporeeMemberId/reject` | JWT | Permisos: attendance:approve_late | Rechazar inscripción tardía de miembro en camporee de unión | CamporeeLateApprovalsService.rejectUnionMemberEnrollment() | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/:camporeeId/pending` | JWT | Permisos: attendance:approve_late | Listar inscripciones pendientes de aprobación | CamporeeLateApprovalsService.listPending() | `src/camporees/camporees.controller.ts` |
| PATCH | `/api/v1/camporees/:camporeeId/clubs/:camporeeClubId/approve` | JWT | Permisos: attendance:approve_late | Aprobar inscripción tardía de club | CamporeeLateApprovalsService.approveLocalClubEnrollment() | `src/camporees/camporees.controller.ts` |
| PATCH | `/api/v1/camporees/:camporeeId/clubs/:camporeeClubId/reject` | JWT | Permisos: attendance:approve_late | Rechazar inscripción tardía de club | CamporeeLateApprovalsService.rejectLocalClubEnrollment() | `src/camporees/camporees.controller.ts` |
| PATCH | `/api/v1/camporees/:camporeeId/members/:camporeeMemberId/approve` | JWT | Permisos: attendance:approve_late | Aprobar inscripción tardía de miembro | CamporeeLateApprovalsService.approveLocalMemberEnrollment() | `src/camporees/camporees.controller.ts` |
| PATCH | `/api/v1/camporees/:camporeeId/members/:camporeeMemberId/reject` | JWT | Permisos: attendance:approve_late | Rechazar inscripción tardía de miembro | CamporeeLateApprovalsService.rejectLocalMemberEnrollment() | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/:camporeeId/section-registration` | JWT | Permisos: camporees:read | Estado contextual de inscripción al camporee de la sección activa del actor (`CamporeeSectionRegistrationDto`) | CamporeesService.getActiveSectionRegistration() | `src/camporees/camporees.controller.ts` |
| POST | `/api/v1/camporees/:camporeeId/section-registration` | JWT | Permisos: camporees:register_active_section | Inscribir la sección activa del actor. No acepta un ID de sección enviado por el cliente. 400 si la inscripción no está disponible | CamporeesService.registerActiveSection() | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/:camporeeId` | JWT | Permisos: camporees:read | Obtener camporee por ID | CamporeesService.findOne() | `src/camporees/camporees.controller.ts` |
| POST | `/api/v1/camporees` | JWT | Permisos: camporees:create | Crear camporee | CamporeesService.create() | `src/camporees/camporees.controller.ts` |
| PATCH | `/api/v1/camporees/:camporeeId` | JWT | Permisos: camporees:update | Actualizar camporee | CamporeesService.update() | `src/camporees/camporees.controller.ts` |
| DELETE | `/api/v1/camporees/:camporeeId` | JWT | Permisos: camporees:delete | Desactivar camporee | CamporeesService.remove() | `src/camporees/camporees.controller.ts` |
| POST | `/api/v1/camporees/:camporeeId/register` | JWT | Permisos: attendance:manage | Registrar miembro en camporee | CamporeesService.registerMember() | `src/camporees/camporees.controller.ts` |
| POST | `/api/v1/camporees/:camporeeId/participants` | JWT | Permisos: attendance:manage | Alias contextual para registrar participantes con la sección activa del director (`RegisterMemberDto`). 422 `CAMPOREE_SECTION_REGISTRATION_REQUIRED` o `CAMPOREE_MEMBER_OUTSIDE_ACTIVE_SECTION` | CamporeesService.registerParticipants() | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/:camporeeId/members` | JWT | Permisos: attendance:read | Listar miembros del camporee | CamporeesService.getMembers() | `src/camporees/camporees.controller.ts` |
| DELETE | `/api/v1/camporees/:camporeeId/members/:userId` | JWT | Permisos: attendance:manage | Remover miembro del camporee | CamporeesService.removeMember() | `src/camporees/camporees.controller.ts` |
| POST | `/api/v1/camporees/:camporeeId/clubs` | JWT | Permisos: attendance:manage | Inscribir club en camporee | CamporeesService.enrollClub() | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/:camporeeId/clubs` | JWT | Permisos: attendance:read | Listar clubes inscritos en camporee | CamporeesService.getEnrolledClubs() | `src/camporees/camporees.controller.ts` |
| DELETE | `/api/v1/camporees/:camporeeId/clubs/:camporeeClubId` | JWT | Permisos: attendance:manage | Cancelar inscripción de club | CamporeesService.cancelClubEnrollment() | `src/camporees/camporees.controller.ts` |
| POST | `/api/v1/camporees/:camporeeId/club-registration/close` | JWT | Permisos: camporee_events:update | Close local camporee club registration | CamporeesService.closeLocalCamporeeClubRegistration() | `src/camporees/camporee-club-registration.controller.ts` |
| POST | `/api/v1/camporees/:camporeeId/club-registration/reopen` | JWT | Permisos: camporee_events:update | Reopen local camporee club registration | CamporeesService.reopenLocalCamporeeClubRegistration() | `src/camporees/camporee-club-registration.controller.ts` |
| POST | `/api/v1/camporees/:camporeeId/members/:memberId/payments` | JWT | Permisos: attendance:manage | Registrar pago de miembro | CamporeesService.createPayment() | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/:camporeeId/members/:memberId/payments` | JWT | Permisos: attendance:read | Listar pagos de un miembro | CamporeesService.getMemberPayments() | `src/camporees/camporees.controller.ts` |
| GET | `/api/v1/camporees/:camporeeId/payments` | JWT | Permisos: attendance:read | Listar todos los pagos del camporee | CamporeesService.getCamporeePayments() | `src/camporees/camporees.controller.ts` |
| PATCH | `/api/v1/camporees/payments/:paymentId` | JWT | Permisos: attendance:manage | Actualizar pago | CamporeesService.updatePayment() | `src/camporees/camporees.controller.ts` |
| POST | `/api/v1/camporees/:camporeeId/payments/:paymentId/voucher` | JWT | Permisos: attendance:manage | Adjuntar comprobante a un pago | CamporeesService.uploadPaymentVoucher() | `src/camporees/camporees.controller.ts` |
| DELETE | `/api/v1/camporees/:camporeeId/payments/:paymentId/voucher` | JWT | Permisos: attendance:manage | Remover comprobante de un pago | CamporeesService.removePaymentVoucher() | `src/camporees/camporees.controller.ts` |
| PATCH | `/api/v1/camporees/payments/:camporeePaymentId/approve` | JWT | Permisos: attendance:approve_late | Aprobar pago tardío de camporee | CamporeeLateApprovalsService.approvePayment() | `src/camporees/camporees.controller.ts` |
| PATCH | `/api/v1/camporees/payments/:camporeePaymentId/reject` | JWT | Permisos: attendance:approve_late | Rechazar pago tardío de camporee | CamporeeLateApprovalsService.rejectPayment() | `src/camporees/camporees.controller.ts` |

### catalogs

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/catalogs/club-types` | JWT opcional (`@Public` + OptionalJwt) | - | Obtener tipos de club | CatalogsService.getClubTypes() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/activity-types` | JWT opcional (`@Public` + OptionalJwt) | - | Obtener tipos de actividad | CatalogsService.getActivityTypes() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/relationship-types` | JWT opcional (`@Public` + OptionalJwt) | - | Obtener tipos de relación | CatalogsService.getRelationshipTypes() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/countries` | JWT opcional (`@Public` + OptionalJwt) | - | Países. Sin JWT / sin rol territorial: directorio completo. Con rol territorial: solo el país del actor. | CatalogsService.getCountries() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/divisions` | JWT opcional (`@Public` + OptionalJwt) | - | Divisiones. Con rol territorial: solo las que tienen uniones en el país del actor. | CatalogsService.getDivisions() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/unions` | JWT opcional (`@Public` + OptionalJwt) | - | Uniones. Con rol territorial: uniones del país del actor; `countryId`/`divisionId` de otro país → 403 `GUARD_PERMISSION_DENIED`. | CatalogsService.getUnions() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/local-fields` | JWT opcional (`@Public` + OptionalJwt) | - | Campos locales. Con rol territorial: campos del país del actor; `unionId` de otro país → 403 `GUARD_PERMISSION_DENIED`. | CatalogsService.getLocalFields() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/districts` | JWT opcional (`@Public` + OptionalJwt) | - | Distritos. Con rol territorial: distritos del país del actor; `localFieldId` de otro país → 403 `GUARD_PERMISSION_DENIED`. | CatalogsService.getDistricts() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/churches` | JWT opcional (`@Public` + OptionalJwt) | - | Iglesias. Con rol territorial: iglesias del país del actor; `districtId` de otro país → 403 `GUARD_PERMISSION_DENIED`. | CatalogsService.getChurches() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/roles` | JWT opcional (`@Public` + OptionalJwt) | - | Obtener roles disponibles | CatalogsService.getRoles() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/ecclesiastical-years` | JWT opcional (`@Public` + OptionalJwt) | - | Obtener años eclesiásticos | CatalogsService.getEcclesiasticalYears() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/ecclesiastical-years/current` | JWT opcional (`@Public` + OptionalJwt) | - | Obtener año eclesiástico actual | CatalogsService.getCurrentEcclesiasticalYear() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/club-ideals` | JWT opcional (`@Public` + OptionalJwt) | - | Obtener ideales de club | CatalogsService.getClubIdeals() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/allergies` | JWT opcional (`@Public` + OptionalJwt) | - | Obtener catálogo de alergias | CatalogsService.getAllergies() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/diseases` | JWT opcional (`@Public` + OptionalJwt) | - | Obtener catálogo de enfermedades | CatalogsService.getDiseases() | `src/catalogs/catalogs.controller.ts` |
| GET | `/api/v1/catalogs/medicines` | JWT opcional (`@Public` + OptionalJwt) | - | Obtener catálogo de medicamentos | CatalogsService.getMedicines() | `src/catalogs/catalogs.controller.ts` |

### admin-certificate-bulk-imports

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/certificate-bulk-imports/pending` | JWT | Global: super-admin, admin, assistant-admin, director-lf, assistant-lf | Listar cargas por certificado pendientes | AdminCertificateBulkImportsService.listPending() | `src/certificate-bulk-imports/admin-certificate-bulk-imports.controller.ts` |
| GET | `/api/v1/admin/certificate-bulk-imports/:batchId` | JWT | Global: super-admin, admin, assistant-admin, director-lf, assistant-lf | Obtener detalle de carga por certificado. Agrega `ocr_state`/`ocr_error_code` del lote, `files[].page_count` y, por ítem, `instructor` (sin correo ni foto), `instructor_conflict`, `source_file_id` y `source_page` | AdminCertificateBulkImportsService.getDetail() | `src/certificate-bulk-imports/admin-certificate-bulk-imports.controller.ts` |
| POST | `/api/v1/admin/certificate-bulk-imports/:batchId/approve` | JWT | Global: super-admin, admin, assistant-admin, director-lf, assistant-lf | Rechaza decidir el lote entero. Cada fila se aprueba sola | AdminCertificateBulkImportsService.approveBatch() | `src/certificate-bulk-imports/admin-certificate-bulk-imports.controller.ts` |
| POST | `/api/v1/admin/certificate-bulk-imports/:batchId/reject` | JWT | Global: super-admin, admin, assistant-admin, director-lf, assistant-lf | Rechaza decidir el lote entero. Cada fila se rechaza sola | AdminCertificateBulkImportsService.rejectBatch() | `src/certificate-bulk-imports/admin-certificate-bulk-imports.controller.ts` |
| POST | `/api/v1/admin/certificate-bulk-imports/:batchId/items/:itemId/approve` | JWT | Global: super-admin, admin, assistant-admin, director-lf, assistant-lf | Aprobar una fila. Si hay cursado operativo no investido del mismo periodo, exige `reconcile_enrollment_id` y `expected_modified_at`. En una fila HONOR la respuesta incluye `instructor_conflict` (la especialidad ya estaba `APPROVED` con otro instructor: se conserva el existente) | AdminCertificateBulkImportsService.approveItem() | `src/certificate-bulk-imports/admin-certificate-bulk-imports.controller.ts` |
| POST | `/api/v1/admin/certificate-bulk-imports/:batchId/items/:itemId/reject` | JWT | Global: super-admin, admin, assistant-admin, director-lf, assistant-lf | Rechazar una fila del lote con motivo | AdminCertificateBulkImportsService.rejectItem() | `src/certificate-bulk-imports/admin-certificate-bulk-imports.controller.ts` |

### certificate-bulk-imports

Edad histórica de una fila de clase, al inicio del año eclesiástico de `completed_at`: `CERTIFICATE_IMPORT_BIRTHDAY_REQUIRED`, `CERTIFICATE_IMPORT_CLASS_MINIMUM_AGE_REQUIRED`, `CERTIFICATE_IMPORT_AGE_BELOW_MINIMUM` (`namedArgs`: `age`, `minimumAge`), y los de periodo `CERTIFICATE_IMPORT_DATE_REQUIRED`, `CERTIFICATE_IMPORT_YEAR_NOT_FOUND`, `CERTIFICATE_IMPORT_YEAR_AMBIGUOUS`. Ocurren al dejar la fila lista, al enviarla, al reenviarla y al aprobarla. `PATCH` con `mark_as_ready: true` y edad inválida no guarda. Un `POST` que crea el lote con `mark_as_ready: true` y la edad inválida deja el ítem en `NEEDS_REVIEW` con el motivo; con datos válidos nace `READY`. Lo mismo vale para un catálogo inexistente o inactivo (`CERTIFICATE_IMPORT_CATALOG_NOT_FOUND`) y para una fecha futura (`CERTIFICATE_IMPORT_DATE_IN_FUTURE`), también con `mark_as_ready: false`: al crear (lote con `items[]` o `POST` de un ítem) el ítem nace `NEEDS_REVIEW` con ese código en `rejection_reason` y no falla el lote. El `PATCH` de un ítem es la ruta de edición explícita y sigue respondiendo 400 con esos mismos códigos. Un `PATCH` de una fila de clase ya `READY`, sin `mark_as_ready` o con `false`, guarda la corrección como `NEEDS_REVIEW` si la edad ya no alcanza. La aprobación institucional usa la misma comprobación dentro de la transacción que escribe `APPROVED`.

Solicitud viva de la misma persona y clase: el año que decide es `investiture_authorization_requests.ecclesiastical_year_id` del `PENDING`, no el año de inicio del enrollment. Si el certificado cae en ese año, HTTP 400 `CERTIFICATE_IMPORT_AUTHORIZATION_PENDING`. El mensaje dice que la persona tiene una solicitud de investidura pendiente en este año y que la autorización tiene prioridad. Ocurre al marcar la fila lista, al enviar, al reenviar y al aprobar, y también al crear o aprobar una solicitud institucional, incluida la sustitución de Guía Mayor. La autoridad es la aprobación: no escribe enrollment, historial, evento ni conciliación, y el ítem no queda aprobado. Sin un `PENDING` de esa persona y clase, el mismo año sigue la reconciliación actual. Si el certificado es anterior al año de esa solicitud y la inscripción vinculada sigue `OPERATIONAL`, se acredita y en la misma transacción esa persona pasa a `REMOVED` con `resolution_code` `HISTORICAL_CERTIFICATE_APPLIED` y `system_reason` «Investidura aplicada por certificado de un año anterior». No usa el texto de falta de requisitos, no emite `class.completed` desde la solicitud, no crea un resultado de autorización y no envía correo. La aprobación institucional de un año anterior a la solicitud hace ese retiro y deja la solicitud `APPROVED`; no crea un enrollment. Una clase de un solo año no cambia, porque el año de la solicitud y el del enrollment coinciden. Los roles que aprueban no cambian. Si el año de esa solicitud ya terminó —el año está inactivo, o el día local del Campo de la solicitud es posterior a `end_date`; la zona sale de sección → club → Campo y, si falta, es `America/Mexico_City`— aunque el barrido de year-cut no haya corrido, la misma transacción la deja `CLOSED_YEAR` con `resolution_code` `CLOSED_YEAR`, sin motivo de falta de requisitos y sin evento. Un certificado de un año posterior no escribe `system_reason`. Un certificado de ese mismo año acredita, conserva `CLOSED_YEAR` y escribe `system_reason` «Investidura acreditada posteriormente mediante certificado validado». Lo aprueba `director-lf` o `assistant-lf` de ese Campo, o `admin`, `assistant-admin` o `super-admin` en su alcance. Otro Campo, un `director-lf` o `assistant-lf` sin Campo, o un actor sin esos roles: HTTP 403 `CERTIFICATE_IMPORT_ENDED_YEAR_FIELD_FORBIDDEN` (código traducible), sin efectos. Si el lote quedó en un Campo distinto al de la solicitud, solo un admin global o `super-admin` acredita. El lote sigue limitado por `batch.local_field_id`. Antes del `FOR SHARE` de usuario, clase y año, el envío, el reenvío y la aprobación reúnen los años de las fechas y los años de solicitud `PENDING` y toman `investiture-authorization-year:` de ese conjunto en orden ascendente de `year_id`. La validación de cada ítem no vuelve a tomar esos candados. Después, la aprobación toma `investiture-authorization-user:` y `investiture-authorization-enrollment:` en orden ascendente. El de usuario se toma aunque la primera lectura no vea un `PENDING`.

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/certificate-bulk-imports` | JWT | Dueño, desde el JWT | Listar expedientes propios | CertificateBulkImportsService.listMine() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |
| POST | `/api/v1/certificate-bulk-imports` | JWT | - | Crear un borrador de carga por certificado. Acepta `files[]` (hasta 10) e `items[]`; una fila con instructor inválido o fecha fuera de rango nace `NEEDS_REVIEW` con el código en `rejection_reason` y no falla el lote (salvo fecha fuera de rango con `mark_as_ready: true`, que responde 400). Responde `ocr_state: null` | CertificateBulkImportsService.createDraft() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |
| POST | `/api/v1/certificate-bulk-imports/:batchId/items` | JWT | Dueño, borrador | Alta manual de fila (mismos campos que el `PATCH` de fila) | CertificateBulkImportsService.addItem() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |
| DELETE | `/api/v1/certificate-bulk-imports/:batchId/items/:itemId` | JWT | Dueño, borrador | Quitar fila no enviada | CertificateBulkImportsService.removeItem() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |
| POST | `/api/v1/certificate-bulk-imports/:batchId/process-ocr` | JWT | - | Encola lectura Google Vision para JPEG/PNG/WebP y PDF completo de 1–5 páginas (≤10 MiB), vía ADC local (`OCR_MODE=direct`) o proxy keyless (`OCR_MODE=remote`, aprobado en local, no desplegado). Sin Redis: `CERTIFICATE_IMPORT_OCR_UNAVAILABLE`. Credenciales, cuota y lectura fallida se resuelven asíncronamente; no hay `OCR_PROCESSED` ante fallo; el resultado se lee en `ocr_state`/`ocr_error_code` del lote. Registra `OCR_QUEUED` antes de encolar. Una lectura en cola o en curso no se duplica (devuelve el lote); tras un fallo, llamarlo de nuevo reintenta | CertificateBulkImportsService.processOcr() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |
| GET | `/api/v1/certificate-bulk-imports/catalog/classes?clubTypeId=` | JWT | `@SkipPermissions` | Clases elegibles al cargar un certificado: `[{ class_id, name, asset_code, club_type_id, institutional }]`. Incluye clases retiradas (que `GET /classes` oculta) e institucionales (`institutional: true`); excluye las inactivas que no son institucionales. `clubTypeId` opcional | CertificateBulkImportsService.listClassCatalog() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |
| GET | `/api/v1/certificate-bulk-imports/:batchId` | JWT | - | Obtener detalle de una carga por certificado. Incluye `ocr_state` y `ocr_error_code`, `files[].page_count`, y por ítem `honor {honor_id, name, category}`, `class {class_id, name, asset_code, club_type}`, `instructor`, `source_file_id` y `source_page` | CertificateBulkImportsService.getBatch() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |
| DELETE | `/api/v1/certificate-bulk-imports/:batchId` | JWT | Dueño, solo `DRAFT` | Descartar un borrador propio: borra el lote, sus filas y archivos y, tras el commit, los objetos de R2 (mejor esfuerzo). 404 `CERTIFICATE_IMPORT_BATCH_NOT_FOUND` si no existe o no es del usuario; 409 `CERTIFICATE_IMPORT_BATCH_NOT_DELETABLE` (ya no es `DRAFT` o tiene solicitudes institucionales); 409 `CERTIFICATE_IMPORT_OCR_IN_PROGRESS` (lectura en cola o en curso; reintentar). Responde `{ batch_id, deleted: true }` | CertificateImportDraftDeletionService.deleteDraft() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |
| PATCH | `/api/v1/certificate-bulk-imports/:batchId/items/:itemId` | JWT | - | Corregir o completar una fila detectada por OCR. Acepta `instructor_user_id` o `instructor_name` (solo filas HONOR; como máximo uno; `null` lo borra), `club_type_id` (solo verificación de la clase) y `completed_at` entre 1960-01-01 y hoy | CertificateBulkImportsService.updateItem() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |
| POST | `/api/v1/certificate-bulk-imports/:batchId/submit` | JWT | - | Enviar carga por certificado a validación de Campo Local | CertificateBulkImportsService.submit() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |
| POST | `/api/v1/certificate-bulk-imports/:batchId/items/:itemId/resubmit` | JWT | - | Corregir y reenviar una fila rechazada | CertificateBulkImportsService.resubmitItem() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |
| POST | `/api/v1/certificate-bulk-imports/:batchId/files/presign` | JWT | Dueño del lote | Preparar subida firmada de un comprobante | CertificateImportFilesService.presign() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |
| POST | `/api/v1/certificate-bulk-imports/:batchId/files/:fileId/confirm` | JWT | Dueño del lote | Confirmar bytes reales y sellar; PDF válido 1–5 páginas, no cifrado. PDF_INVALID/PDF_ENCRYPTED/PDF_TOO_MANY_PAGES → 400. Cola de validación llena o espera vencida → 429 `CERTIFICATE_IMPORT_PDF_BUSY`; el archivo no queda confirmado | CertificateImportFilesService.confirm() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |
| GET | `/api/v1/certificate-bulk-imports/:batchId/files/:fileId/download` | JWT | Dueño; Campo Local en su ámbito; evidencia institucional solo dueño o super-admin | URL efímera del objeto sellado | CertificateImportFilesService.download() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |
| DELETE | `/api/v1/certificate-bulk-imports/:batchId/files/:fileId` | JWT | Dueño, solo expediente editable y sin filas enviadas | Retirar comprobante no enviado | CertificateImportFilesService.remove() | `src/certificate-bulk-imports/certificate-bulk-imports.controller.ts` |

#### Contrato de archivos/OCR por certificado (2026-10-01)

- Un documento activo por lote; JPEG/PNG/WebP/PDF, **máximo binario 10 MiB**. Secuencia: crear borrador → presign → PUT privado R2 → confirm → consultar lote → process-ocr. El PUT firmado no recibe Bearer de la API ni sigue redirects.
- `confirm` valida bytes y estructura PDF real antes de `CONFIRMED`; máximo **cinco páginas del documento completo**, no truncamiento de páginas. Cifrado, cierre/xref mínimo inválido, corrupción/truncamiento, cero o >5 páginas se rechazan. PDF se sella desde el Buffer validado en una clave exclusiva por intento; imágenes mantienen su clave existente. No copiar staging mutable después de validar PDF.
- Errores PDF HTTP **400**, nombres completos: `CERTIFICATE_IMPORT_PDF_TOO_MANY_PAGES`, `CERTIFICATE_IMPORT_PDF_ENCRYPTED`, `CERTIFICATE_IMPORT_PDF_INVALID`. Mantiene códigos existentes de tamaño/MIME/storage/ownership. Son `BadRequestException` legacy: el código llega en **`message`**, no debe asumirse `code`. Ejemplo (timestamp/path omitidos):

```json
{"status":"error","statusCode":400,"message":"CERTIFICATE_IMPORT_PDF_TOO_MANY_PAGES"}
```

- `confirm` sin turno de validación (cola llena o espera de 2 s vencida) responde HTTP **429** `CERTIFICATE_IMPORT_PDF_BUSY`. El archivo no queda confirmado; se puede reintentar el mismo `confirm`. Mismo sobre legacy: el código va en **`message`**. No es `CERTIFICATE_IMPORT_OCR_UNAVAILABLE`. Ejemplo (timestamp/path omitidos):

```json
{"status":"error","statusCode":429,"message":"CERTIFICATE_IMPORT_PDF_BUSY"}
```

- `process-ocr` devuelve el lote tras **encolar**, no el resultado de Vision. Redis ausente falla al encolar (`CERTIFICATE_IMPORT_OCR_UNAVAILABLE`); en el worker ADC/auth (o proxy no disponible) falla con el mismo código, cuota con `CERTIFICATE_IMPORT_OCR_QUOTA`, fallo/deadline/resultados incompletos con `CERTIFICATE_IMPORT_OCR_FAILED`. Estos fallos posteriores **no son** respuesta HTTP retroactiva: el cliente los lee en `ocr_state`/`ocr_error_code` del lote (ver «Estado de lectura, instructor y páginas» más abajo). No escribe `OCR_PROCESSED` salvo lectura completa exitosa. El SDK usa ADC, gRPC/Buffer, deadline 25 s y sin retries internos; BullMQ conserva dos intentos/concurrencia 1. Los códigos terminales (`FAILED`, `QUOTA`, `UNSUPPORTED_TYPE`, `FILE_TOO_LARGE`, `PDF_*`) no gastan el segundo intento; `CERTIFICATE_IMPORT_OCR_UNAVAILABLE` sí es reintentable.
- PDF antiguo confirmado se valida nuevamente antes de Vision; se exige exactamente una respuesta sin error por cada página `1..pageCount`. OCR solo propone; agregar/corregir filas manualmente y aprobación autorizada continúan separados.
- `CERTIFICATE_IMPORT_PDF_BUSY` es de `confirm` y es el único código de este contrato con HTTP 429 hacia la app. Está **aprobado en local**; sigue sin desplegar. El 429 conserva `message` (en producción el filtro sustituye `message` cuando `status >= 500`, por eso no se usó 503).
- Implementación revisada e integrada al workspace principal; el proxy OCR keyless está **aprobado en local** (`PASS_LOCAL_SLICE` en Task0, 1, 1b, 2, R, 3 y 4) pero **no desplegado**: no existen Cloud Run, Firestore, Secret Manager ni el modo `remote` en Render. Configuración en Render y humo OCR real siguen pendientes. [Runbook de operación](../guides/google-vision-certificate-ocr.md) · [infraestructura de preproducción](../guides/ocr-proxy-preprod-infra.md).

#### Estado de lectura, instructor y páginas (2026-10-13)

Campos añadidos a las respuestas de lote (`POST /certificate-bulk-imports`, `GET .../:batchId`, `POST .../process-ocr`, `POST .../submit`, y el detalle admin). Todos son aditivos: un cliente anterior los ignora.

| Campo | Dónde | Contrato |
|---|---|---|
| `ocr_state` | lote | `null` (nunca se pidió OCR), `pending`, `running`, `done` (leyó filas), `empty` (leyó, sin filas) o `failed`. Se **deriva** de eventos (`OCR_QUEUED`, `OCR_PROCESSED`, `OCR_FAILED`) y del job de BullMQ; no hay tabla ni columna. Si no se pudo determinar (Redis no responde), las dos claves se omiten: es «sin dato», distinto de `null`. Un `OCR_QUEUED` sin job y con más de 5 minutos sin `OCR_PROCESSED` cuenta como `failed` |
| `ocr_error_code` | lote | Solo con `ocr_state: 'failed'` cuando el worker registró la causa (`OCR_FAILED`); `null` si la causa es desconocida. Lista blanca: `CERTIFICATE_IMPORT_OCR_UNAVAILABLE`, `..._OCR_FAILED`, `..._OCR_QUOTA`, `..._OCR_UNSUPPORTED_TYPE`, `..._OCR_FILE_TOO_LARGE`, `..._PDF_TOO_MANY_PAGES`, `..._PDF_INVALID`, `..._PDF_ENCRYPTED`, `..._STORAGE_UNAVAILABLE`, `..._FILE_NOT_CONFIRMED`, `..._FILE_CONTENT_MISMATCH`, `..._FILE_TOO_LARGE`, `..._FILE_URL_INVALID`, `..._CANNOT_PROCESS_OCR`, `..._BATCH_NOT_FOUND`; cualquier otro se publica como `CERTIFICATE_IMPORT_OCR_FAILED`. Un reintento (`OCR_QUEUED` nuevo) lo limpia |
| `files[].page_count` | archivo | Páginas del archivo, escrito al confirmar (PDF: el conteo del validador; imagen: 1). `null` en archivos anteriores a la migración M2 |
| `items[].source_file_id`, `items[].source_page` | fila | Archivo del lote y página (1 a 5, dentro de ese archivo) donde el OCR leyó la fila. `null` en filas manuales o anteriores a M2. Si no hay `source_file_id`, el cliente ignora `source_page` |
| `items[].honor`, `items[].class` | fila | `honor { honor_id, name, category { honor_category_id, name } }` y `class { class_id, name, asset_code, club_type { club_type_id, name } }`, con nombres traducidos al idioma pedido; `null` si la fila aún no eligió catálogo |
| `items[].instructor` | fila HONOR | `null`, `{ kind: 'USER', user_id, display_name, photo_url? }` o `{ kind: 'EXTERNAL', display_name }`. El nombre de un usuario se lee en vivo (cuenta anonimizada: «Usuario eliminado»). Nunca trae correo. `photo_url` (URL firmada de vida corta) solo en respuestas del propio miembro (su lote); el admin no la recibe |
| `items[].instructor_conflict` | detalle admin / respuesta de aprobar | `true` si la especialidad ya estaba `APPROVED` con otro instructor y se conservó el existente (D7) |

Escritura de fila (`POST .../items`, `PATCH .../items/:itemId`, `resubmit`, y `items[]` al crear): `instructor_user_id` (uuid) o `instructor_name` (3 a 150 caracteres, sin caracteres de control), **como máximo uno**; `null` borra; mandar uno reemplaza al otro. El instructor es opcional y no cuenta para dejar la fila lista. Un usuario del sistema debe ser del **mismo Campo Local que el dueño del lote**, activo, aprobado y mayor de edad.

| Código | HTTP | Cuándo |
|---|---|---|
| `HONOR_INSTRUCTOR_AMBIGUOUS` | 400 | Vienen `instructor_user_id` e `instructor_name` |
| `HONOR_INSTRUCTOR_INVALID` | 400 | El usuario no es elegible (otro Campo, inactivo, no aprobado, menor de edad, inexistente). Un solo código para no revelar si existe |
| `HONOR_INSTRUCTOR_SELF` | 400 | El instructor es el propio dueño |
| `CERTIFICATE_IMPORT_HONOR_INSTRUCTOR_NOT_ALLOWED` | 400 | Instructor en una fila CLASS |
| `CERTIFICATE_IMPORT_CLASS_CLUB_TYPE_MISMATCH` | 400 | `club_type_id` no coincide con el de la clase elegida (no se guarda) |
| `CERTIFICATE_IMPORT_DATE_TOO_OLD` / `_IN_FUTURE` / `_INVALID` | 400 | `completed_at` anterior a 1960-01-01, posterior a hoy o no es una fecha real. En `PATCH`/`resubmit` y con `mark_as_ready: true` es 400; al crear sin `mark_as_ready` la fila nace `NEEDS_REVIEW` con el código en `rejection_reason`. El código llega en `message` (sobre legacy) |
| `CERTIFICATE_IMPORT_BATCH_NOT_DELETABLE`, `CERTIFICATE_IMPORT_OCR_IN_PROGRESS` | 409 | `DELETE` del borrador (ver la fila del endpoint) |

El OCR **no** hace match de catálogo: entrega `detected_name`, fecha (`completed_at` solo si cae entre 1960-01-01 y hoy; si no, la cruda queda en `detected_date` y `completed_at` en `NULL`) y confianza. `honor_id`/`class_id` los elige el miembro.

#### Contrato interno OCR (backend a proxy)

No agrega endpoints públicos: la app y el admin no lo consumen. Lo llama solo el worker de Render cuando `OCR_MODE=remote` (estado: aprobado en local, no desplegado). Variables del backend: `OCR_MODE` (`direct` | `remote`; obligatoria en producción), `OCR_PROXY_URL` (URL completa `https://<host>/v1/ocr`), `OCR_PROXY_ENV`, `OCR_PROXY_KID`, `OCR_PROXY_SECRET` (base64 de ≥ 32 bytes; el mismo valor que `OCR_SECRET_CURRENT` del proxy para ese `kid`).

| Aspecto | Contrato |
|---|---|
| Solicitud | `POST /v1/ocr`, cuerpo binario sin compresión ni redirects, ≤ 10 MiB; JPEG, PNG, WebP o PDF de 1–5 páginas. |
| Autenticación | HMAC-SHA256 sobre una cuerda canónica v1 con headers `X-Ocr-*` (versión, entorno, `kid`, `operationId`, `issuedAt`, MIME, longitud, `X-Ocr-Page-Count`, timestamp ±120 s, nonce, SHA-256 del cuerpo, firma). Sin Bearer ni credenciales Google. |
| Identidad | `operationId` = `file_id` persistido; `issuedAt` = `confirmed_at`. Estables entre reintentos. Nunca viaja un identificador de usuario. |
| Páginas | Render valida y cuenta el PDF y firma `X-Ocr-Page-Count`; el proxy no parsea PDF y exige cobertura exacta y `totalPages == N`. |
| Cuota | 400 páginas por día UTC y por entorno (`OCR_MAX_PAGES_PER_ENV_PER_DAY`, 1..400), compartidas entre usuarios. |
| Plazos | Vision 25 s; proxy 35 s; cliente de Render 40 s absolutos. |
| Respuesta 200 | JSON UTF-8 v1 `{version, operationId, pageCount, pages:[{pageNumber, text}]}`, ≤ 16 MiB. |
| Error | `{version, code, requestId}` sin texto OCR ni datos humanos. |

Mapeo del código interno al código que ve la app (sin endpoint nuevo):

| Código interno (HTTP) | Código en la app |
|---|---|
| `UNAUTHORIZED` (401), `FORBIDDEN` (403), `UNAVAILABLE` (503), `DISCONNECTED` (503) | `CERTIFICATE_IMPORT_OCR_UNAVAILABLE` |
| `UNSUPPORTED_TYPE` (400) | `CERTIFICATE_IMPORT_OCR_UNSUPPORTED_TYPE` |
| `PAYLOAD_TOO_LARGE` (413) | `CERTIFICATE_IMPORT_OCR_FILE_TOO_LARGE` |
| `PDF_TOO_MANY_PAGES`, `PDF_ENCRYPTED`, `PDF_INVALID` (400) | el mismo nombre `CERTIFICATE_IMPORT_PDF_*` |
| `INVALID_CONTRACT` (400), `ENCODED` (400), `EMPTY_DOCUMENT` (400), `CONFLICT` (409), `RESPONSE_TOO_LARGE` (504), `UNCERTAIN` (504), `PAGE_COUNT_MISMATCH` (502) | `CERTIFICATE_IMPORT_OCR_FAILED` |
| `QUOTA` (429, sobre v1 válido) | `CERTIFICATE_IMPORT_OCR_QUOTA` |
| Cualquier 429, 5xx o 504 **sin sobre v1 válido** (por ejemplo Cloud Run sin instancia libre con máximo 1) | `CERTIFICATE_IMPORT_OCR_UNAVAILABLE`, nunca `QUOTA` |

Garantías limitadas: tras `CALLING` confirmado no hay segunda llamada a Vision; la incertidumbre y la respuesta `COMPLETE` perdida van a revisión manual. No hay exactly-once. Si un reintento de BullMQ encuentra el lease del ledger vigente (60 s), el proxy responde `CONFLICT` y la app ve `CERTIFICATE_IMPORT_OCR_FAILED`. Dependencias de despliegue: [infraestructura de preproducción](../guides/ocr-proxy-preprod-infra.md).

### certificate-import-institutional-requests

Aprobar no crea `enrollments` ni reactiva la clase. En HTTP, Campo Local, admin genérico y Unión reciben `GUARD_PERMISSION_DENIED`. Si el guard no aplica, el servicio responde `CERTIFICATE_IMPORT_INSTITUTIONAL_FORBIDDEN`. En la bandeja común, Unión pasa el alias de `director-lf` y el servicio responde `CERTIFICATE_IMPORT_REVIEWER_SCOPE_REQUIRED`.

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/certificate-import-institutional-requests` | JWT | Dueño | Enviar solicitud de Guía Mayor Avanzado o Instructor | InstitutionalCertificateRequestsService.submit() | `src/certificate-bulk-imports/institutional-certificate-requests.controller.ts` |
| GET | `/api/v1/certificate-import-institutional-requests` | JWT | Dueño | Consultar sus solicitudes | InstitutionalCertificateRequestsService.listMine() | `src/certificate-bulk-imports/institutional-certificate-requests.controller.ts` |
| GET | `/api/v1/certificate-import-institutional-requests/:requestId` | JWT | Dueño | Detalle, motivo y bloqueo de periodo | InstitutionalCertificateRequestsService.getMine() | `src/certificate-bulk-imports/institutional-certificate-requests.controller.ts` |

### admin-certificate-import-institutional-requests

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/certificate-import-institutional-requests` | JWT | Solo super-admin | Bandeja institucional. Query: `page`, `limit`, `status`, `class_id`, `q` | InstitutionalCertificateRequestsService.listForReview() | `src/certificate-bulk-imports/admin-institutional-certificate-requests.controller.ts` |
| GET | `/api/v1/admin/certificate-import-institutional-requests/:requestId` | JWT | Solo super-admin | Detalle institucional | InstitutionalCertificateRequestsService.getForReview() | `src/certificate-bulk-imports/admin-institutional-certificate-requests.controller.ts` |
| POST | `/api/v1/admin/certificate-import-institutional-requests/:requestId/approve` | JWT | Solo super-admin | Validar expediente, sin crear `enrollments` | InstitutionalCertificateRequestsService.approve() | `src/certificate-bulk-imports/admin-institutional-certificate-requests.controller.ts` |
| POST | `/api/v1/admin/certificate-import-institutional-requests/:requestId/reject` | JWT | Solo super-admin | Rechazar con motivo | InstitutionalCertificateRequestsService.reject() | `src/certificate-bulk-imports/admin-institutional-certificate-requests.controller.ts` |

### certifications

> Motor configurable versionado (migración `20260811180000_configurable_certifications_engine`). La inscripción y el progreso identifican la inscripción por **`userId` + `certificationId`**. Requisitos, evidencias, cierre y revisión final usan `enrollmentId` (`certification-enrollments/:enrollmentId`).

#### Catálogo (Optional JWT)

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/certifications/certifications` | Optional JWT | - | Listar certificaciones disponibles (paginado) | CertificationsService.findAll() | `src/certifications/certifications.controller.ts` |
| GET | `/api/v1/certifications/certifications/:id` | Optional JWT | - | Detalle de certificación con módulos y secciones | CertificationsService.findOne() | `src/certifications/certifications.controller.ts` |

#### Inscripción y progreso (participante / delegado)

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/certifications/users/:userId/certifications/enroll` | JWT | Permisos: user_certifications:manage; owner `userId` | Inscribir en la versión `PUBLISHED` vigente (evalúa elegibilidad configurable). 409 `CERT_ALREADY_ENROLLED` si hay inscripción activa o una fila histórica inactiva `CERTIFIED`/`APPROVED`/`SUBMITTED_FOR_FINAL_REVIEW`; las inactivas `WITHDRAWN`/`EXPIRED` sí permiten reinscribir | CertificationsService.enrollUser() | `src/certifications/certifications.controller.ts` |
| GET | `/api/v1/certifications/users/:userId/certifications` | JWT | Permisos: user_certifications:read; owner `userId` | Listar inscripciones del usuario con resumen de progreso | CertificationsService.getUserCertifications() | `src/certifications/certifications.controller.ts` |
| GET | `/api/v1/certifications/users/:userId/certifications/:certificationId/eligibility` | JWT | Permisos: user_certifications:read; owner `userId` | Evaluar elegibilidad explicable por regla (versión publicada) | CertificationsService.getEligibility() | `src/certifications/certifications.controller.ts` |
| GET | `/api/v1/certifications/users/:userId/certifications/:certificationId/progress` | JWT | Permisos: user_certifications:read; owner `userId` | Progreso detallado por módulos/secciones (inscripciones versionadas usan `status` de requisito) | CertificationsService.getCertificationProgress() | `src/certifications/certifications.controller.ts` |
| PATCH | `/api/v1/certifications/users/:userId/certifications/:certificationId/progress` | JWT | Permisos: user_certifications:manage; owner `userId` | **[LEGACY — deprecado 2026-08-11]** Toggle booleano de sección; inscripciones con `certification_version_id` reciben `410 CERT_LEGACY_ENDPOINT_DEPRECATED` | CertificationsService.updateProgress() | `src/certifications/certifications.controller.ts` |
| DELETE | `/api/v1/certifications/users/:userId/certifications/:certificationId` | JWT | Permisos: user_certifications:manage; owner `userId` | Abandonar inscripción (soft delete). 409 `CERT_ENROLLMENT_NOT_ABANDONABLE` en `CERTIFIED`, `APPROVED` o `SUBMITTED_FOR_FINAL_REVIEW`; en `ENROLLED`/`IN_PROGRESS`/`READY_FOR_CLOSEOUT`/`CHANGES_REQUESTED` pasa a `WITHDRAWN` con `active=false` y evento `WITHDRAWN`; `EXPIRED` queda `EXPIRED` y solo se desactiva | CertificationsService.deleteCertification() | `src/certifications/certifications.controller.ts` |

#### Requisitos y evidencias (participante)

Path base: `/api/v1/certifications/users/:userId/certification-enrollments/:enrollmentId/requirements/:requirementId`. La inscripción se identifica por `enrollmentId` (debe existir, estar activa y pertenecer al `userId` autenticado).

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/certifications/users/:userId/certification-enrollments/:enrollmentId/requirements/:requirementId` | JWT | user_certifications:read; owner `userId` | Estado del requisito, respuestas y componentes | CertificationRequirementsService.getRequirement() | `src/certifications/controllers/user-certification-requirements.controller.ts` |
| PATCH | `/api/v1/certifications/users/:userId/certification-enrollments/:enrollmentId/requirements/:requirementId/draft` | JWT | user_certifications:manage; owner `userId` | Guardar borrador (solo requisito `DRAFT` o `CHANGES_REQUESTED` e inscripción editable) | CertificationRequirementsService.saveDraft() | `src/certifications/controllers/user-certification-requirements.controller.ts` |
| POST | `/api/v1/certifications/users/:userId/certification-enrollments/:enrollmentId/requirements/:requirementId/submit` | JWT | user_certifications:manage; owner `userId` | Enviar requisito a revisión (`lock_version` obligatorio) | CertificationRequirementsService.submitRequirement() | `src/certifications/controllers/user-certification-requirements.controller.ts` |
| POST | `/api/v1/certifications/users/:userId/certification-enrollments/:enrollmentId/requirements/:requirementId/evidences/presign` | JWT | user_certifications:manage; owner `userId` | URL firmada de subida R2 (`component_id`, MIME, tamaño) | CertificationEvidenceService.presign() | `src/certifications/controllers/user-certification-requirements.controller.ts` |
| POST | `/api/v1/certifications/users/:userId/certification-enrollments/:enrollmentId/requirements/:requirementId/evidences/confirm` | JWT | user_certifications:manage; owner `userId` | Confirmar objeto subido (valida HEAD en R2) | CertificationEvidenceService.confirm() | `src/certifications/controllers/user-certification-requirements.controller.ts` |
| DELETE | `/api/v1/certifications/users/:userId/certification-enrollments/:enrollmentId/evidences/:evidenceId` | JWT | user_certifications:manage; owner `userId` | Eliminar evidencia mientras el requisito sea editable | CertificationEvidenceService.delete() | `src/certifications/controllers/user-certification-requirements.controller.ts` |

#### Cierre institucional (participante)

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/certifications/users/:userId/certification-enrollments/:enrollmentId/closeout-evidence/presign` | JWT | user_certifications:manage; owner `userId` | URL firmada para comprobante de junta | CertificationCloseoutService.presignCloseoutEvidence() | `src/certifications/controllers/certification-closeout.controller.ts` |
| POST | `/api/v1/certifications/users/:userId/certification-enrollments/:enrollmentId/closeout-evidence/confirm` | JWT | user_certifications:manage; owner `userId` | Confirmar comprobante de junta subido a R2 | CertificationCloseoutService.confirmCloseoutEvidence() | `src/certifications/controllers/certification-closeout.controller.ts` |
| POST | `/api/v1/certifications/users/:userId/certification-enrollments/:enrollmentId/submit-final` | JWT | user_certifications:manage; owner `userId` | Enviar inscripción a revisión final (requisitos obligatorios `APPROVED` + comprobante `CONFIRMED`) | CertificationCloseoutService.submitFinal() | `src/certifications/controllers/certification-closeout.controller.ts` |

#### Revisión de requisitos (institucional)

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/certifications/reviews/requirements` | JWT | Permisos: certifications:review; scope global | Bandeja de requisitos (filtro opcional `?status=`) | CertificationReviewService.getTray() | `src/certifications/controllers/certification-review.controller.ts` |
| GET | `/api/v1/certifications/reviews/requirements/:progressId` | JWT | Permisos: certifications:review; scope global | Detalle de requisito con respuestas, evidencias e historial | CertificationReviewService.getDetail() | `src/certifications/controllers/certification-review.controller.ts` |
| GET | `/api/v1/certifications/reviews/requirements/:progressId/evidences/:evidenceId/download` | JWT | Permisos: certifications:review; scope global | URL firmada efímera (TTL 15 min) de evidencia activa `CONFIRMED` del requisito; no acepta object key del cliente | CertificationReviewService.getEvidenceDownloadUrl() | `src/certifications/controllers/certification-review.controller.ts` |
| POST | `/api/v1/certifications/reviews/requirements/:progressId/approve` | JWT | Permisos: certifications:review; scope global | Aprobar requisito `SUBMITTED` (`lock_version` obligatorio). Si la inscripción fue abandonada (`active=false`) responde 404 `RECORD_NOT_FOUND`; el detalle y la descarga de evidencia siguen viendo filas históricas | CertificationReviewService.approve() | `src/certifications/controllers/certification-review.controller.ts` |
| POST | `/api/v1/certifications/reviews/requirements/:progressId/request-changes` | JWT | Permisos: certifications:review; scope global | Devolver requisito con comentario obligatorio. Misma regla de inscripción abandonada (404 `RECORD_NOT_FOUND`) | CertificationReviewService.requestChanges() | `src/certifications/controllers/certification-review.controller.ts` |

#### Revisión final y certificación (institucional)

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/certifications/reviews/final` | JWT | Permisos: certifications:review; scope global | Bandeja de cierres (`SUBMITTED_FOR_FINAL_REVIEW` y `APPROVED`) con metadata del comprobante | CertificationCloseoutService.getFinalTray() | `src/certifications/controllers/certification-closeout.controller.ts` |
| GET | `/api/v1/certifications/reviews/final/:enrollmentId/closeout-evidence/download` | JWT | Permisos: certifications:review; scope global | URL firmada efímera (TTL 15 min) del comprobante de junta activo `CONFIRMED` | CertificationCloseoutService.getCloseoutEvidenceDownloadUrl() | `src/certifications/controllers/certification-closeout.controller.ts` |
| POST | `/api/v1/certifications/reviews/final/:enrollmentId/approve-closeout-evidence` | JWT | Permisos: certifications:review; scope global | Aprobar comprobante de junta → inscripción `APPROVED` | CertificationCloseoutService.approveCloseoutEvidence() | `src/certifications/controllers/certification-closeout.controller.ts` |
| POST | `/api/v1/certifications/reviews/final/:enrollmentId/request-changes` | JWT | Permisos: certifications:review; scope global | Devolver cierre con comentario obligatorio | CertificationCloseoutService.requestChanges() | `src/certifications/controllers/certification-closeout.controller.ts` |
| POST | `/api/v1/certifications/reviews/final/:enrollmentId/certify` | JWT | Permisos: certifications:certify; scope global | Certificar inscripción válida (idempotente) | CertificationCloseoutService.certify() | `src/certifications/controllers/certification-closeout.controller.ts` |

#### Códigos de error `CERT_*`

| Código | HTTP típico | Cuándo |
| --- | --- | --- |
| `CERT_NOT_FOUND` | 404 | Certificación inexistente o inactiva |
| `CERT_ALREADY_ENROLLED` | 409 | Inscripción duplicada activa |
| `CERT_ELIGIBILITY_REQUIRED` | 403 | Usuario no cumple reglas de elegibilidad al inscribir |
| `CERT_ENROLLMENT_NOT_FOUND` | 404 | Sin inscripción activa para `userId` + `certificationId` |
| `CERT_SECTION_INVALID` | 400 | Sección/componente fuera de la versión inscrita |
| `CERT_VERSION_NOT_PUBLISHED` | 400 | No hay versión publicada vigente |
| `CERT_VERSION_IMMUTABLE` | 409 | Mutación sobre versión `PUBLISHED`/`RETIRED` |
| `CERT_REQUIREMENT_LOCKED` | 409 | Requisito en `SUBMITTED`/`APPROVED`; evidencia bloqueada; o inscripción no editable (`details.entity = 'enrollment'`): crear, editar o enviar requisitos y evidencias solo se permite en `ENROLLED`, `IN_PROGRESS`, `CHANGES_REQUESTED` y `READY_FOR_CLOSEOUT` |
| `CERT_REQUIREMENT_INCOMPLETE` | 400 | Faltan entregables obligatorios, objeto R2 ausente, o un componente `FILE_EVIDENCE` sin al menos una evidencia `CONFIRMED` y activa |
| `CERT_INVALID_TRANSITION` | 400 | Transición de estado inválida (inscripción o requisito) |
| `CERT_EVIDENCE_INVALID_TYPE` | 400 | MIME no permitido (`jpeg`, `png`, `webp`, `pdf`) |
| `CERT_EVIDENCE_TOO_LARGE` | 400 | Archivo > 10 MiB o divergencia vs. declarado |
| `CERT_REVIEW_SCOPE_FORBIDDEN` | 403 | Revisor fuera de campo local del participante, sin acceso global, o es el propio participante |
| `CERT_CLOSEOUT_INCOMPLETE` | 400 | Faltan requisitos aprobados o comprobante de junta listo |
| `CERT_CONCURRENT_UPDATE` | 409 | `lock_version` obsoleto en envío/revisión |
| `CERT_LEGACY_ENDPOINT_DEPRECATED` | 410 | `PATCH .../progress` sobre inscripción versionada |
| `CERT_ENROLLMENT_NOT_ABANDONABLE` | 409 | `DELETE .../certifications/:certificationId` sobre una inscripción `CERTIFIED`, `APPROVED` o `SUBMITTED_FOR_FINAL_REVIEW` |

### Admin - Certifications

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/certifications` | JWT | Permisos: certifications:configure; scope global | Listar certificaciones con resumen de versiones (id, número, status, título, fechas) | CertificationDefinitionsService.listCertificationsWithVersions() | `src/certifications/controllers/admin-certifications.controller.ts` |
| GET | `/api/v1/admin/certifications/:certificationId/versions/:versionId` | JWT | Permisos: certifications:configure | Árbol completo de una versión: metadatos, reglas de elegibilidad, módulos → secciones → componentes (con `configuration`), todo ordenado por `sort_order`; legible en cualquier status (`DRAFT`/`PUBLISHED`/`RETIRED`) | CertificationDefinitionsService.getVersionDetail() | `src/certifications/controllers/admin-certifications.controller.ts` |
| POST | `/api/v1/admin/certifications` | JWT | Permisos: certifications:configure; scope global | Crear certificación con versión inicial `DRAFT` | CertificationDefinitionsService.createCertification() | `src/certifications/controllers/admin-certifications.controller.ts` |
| POST | `/api/v1/admin/certifications/:certificationId/versions` | JWT | Permisos: certifications:configure | Crear versión `DRAFT` | CertificationDefinitionsService.createDraftVersion() | `src/certifications/controllers/admin-certifications.controller.ts` |
| POST | `/api/v1/admin/certifications/:certificationId/versions/:versionId/clone` | JWT | Permisos: certifications:configure | Clonar versión `PUBLISHED`/`RETIRED` a nuevo `DRAFT` | CertificationDefinitionsService.cloneVersion() | `src/certifications/controllers/admin-certifications.controller.ts` |
| PATCH | `/api/v1/admin/certifications/:certificationId/versions/:versionId` | JWT | Permisos: certifications:configure | Actualizar metadatos de versión `DRAFT` | CertificationDefinitionsService.updateVersionMetadata() | `src/certifications/controllers/admin-certifications.controller.ts` |
| PATCH | `/api/v1/admin/certifications/:certificationId/versions/:versionId/eligibility-rules` | JWT | Permisos: certifications:configure | Reemplazar reglas de elegibilidad del borrador | CertificationDefinitionsService.replaceEligibilityRules() | `src/certifications/controllers/admin-certifications.controller.ts` |
| PATCH | `/api/v1/admin/certifications/:certificationId/versions/:versionId/tree` | JWT | Permisos: certifications:configure | Reemplazar árbol módulos/secciones/componentes del borrador | CertificationDefinitionsService.replaceModulesTree() | `src/certifications/controllers/admin-certifications.controller.ts` |
| POST | `/api/v1/admin/certifications/:certificationId/versions/:versionId/publish` | JWT | Permisos: certifications:publish | Publicar borrador (retira versión `PUBLISHED` anterior) | CertificationDefinitionsService.publishVersion() | `src/certifications/controllers/admin-certifications.controller.ts` |
| DELETE | `/api/v1/admin/certifications/:certificationId/versions/:versionId/publish` | JWT | Permisos: certifications:publish | Retirar versión `PUBLISHED` | CertificationDefinitionsService.retireVersion() | `src/certifications/controllers/admin-certifications.controller.ts` |

### class-counselor-assignments

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId/class-counselor-assignments` | JWT | Permisos: club_roles:read | Listar asignaciones pedagógicas de clases por sección | ClassCounselorAssignmentsService.listAssignments() | `src/classes/class-counselor-assignments.controller.ts` |
| POST | `/api/v1/clubs/:clubId/sections/:sectionId/class-counselor-assignments` | JWT | Permisos: club_roles:assign | Asignar un consejero o secretario a una clase progresiva | ClassCounselorAssignmentsService.createAssignment() | `src/classes/class-counselor-assignments.controller.ts` |
| PATCH | `/api/v1/class-counselor-assignments/:assignmentId` | JWT | Permisos: club_roles:assign | Actualizar una asignación pedagógica de clase | ClassCounselorAssignmentsService.updateAssignment() | `src/classes/class-counselor-assignments.controller.ts` |
| DELETE | `/api/v1/class-counselor-assignments/:assignmentId` | JWT | Permisos: club_roles:revoke | Revocar una asignación pedagógica de clase | ClassCounselorAssignmentsService.removeAssignment() | `src/classes/class-counselor-assignments.controller.ts` |

### class-progress-scope

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId/classes/progress-scope` | JWT | Permisos: classes:read | Listar clases visibles para seguimiento de progreso | ClassProgressScopeService.getProgressScope() | `src/classes/class-progress-scope.controller.ts` |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId/classes/:classId/members-progress` | JWT | Permisos: classes:read | Listar avance de miembros por clase en una sección. Response `members[]` incluye `cross_type_enrollment: boolean`. Devuelve miembros regulares de la sección **y** GMs con `cross_type_enrollment=true` de cualquier sección del mismo club. | ClassProgressScopeService.getClassMembersProgress() | `src/classes/class-progress-scope.controller.ts` |

### class-thresholds

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/local-fields/:localFieldId/class-thresholds/:ecclesiasticalYearId` | JWT | `director-lf` y `assistant-lf` solo en su Campo; `super-admin` en cualquier Campo. Admin, unión, división y un Campo ajeno: 403 `GUARD_PERMISSION_DENIED`. El alias de `GlobalRolesGuard` deja entrar a unión y división; el servicio igual responde 403. | Leer el porcentaje efectivo. Sin fila: `minimum_percent` 80 y `configured` false. La respuesta incluye `can_edit`. | FieldClassThresholdConfigService.get() | `src/classes/field-class-threshold.controller.ts` |
| PATCH | `/api/v1/local-fields/:localFieldId/class-thresholds/:ecclesiasticalYearId` | JWT | Mismos roles que el GET. Escritura: director y asistente del Campo hasta el 30 de junio 23:59 en `local_fields.timezone`, solo si ese instante cae dentro del año pedido. Después, solo `super-admin`, y tampoco fuera de ese año. Fuera de plazo, o con el año `active` en false aunque el día caiga dentro de sus fechas: 403 `CLASS_THRESHOLD_EDIT_CLOSED` para todos los roles, incluido `super-admin`. | Guardar `minimum_percent`. Si el cuerpo no es un entero 0–100 (`101`, `-1`, `90.5`, `"90"`, `null`), el `I18nValidationPipe` responde HTTP 400 con `statusCode`, `message` (arreglo) y `error: "Bad Request"`, sin `code`. `CLASS_THRESHOLD_PERCENT_INVALID` lo lanza el servicio en llamadas internas; no es el contrato de esta ruta. Campo o año ausente: 404 `CLASS_THRESHOLD_FIELD_NOT_FOUND` o `CLASS_THRESHOLD_YEAR_NOT_FOUND`. Zona inválida: 503 `LOCAL_FIELD_TIMEZONE_UNAVAILABLE`. | FieldClassThresholdConfigService.update() | `src/classes/field-class-threshold.controller.ts` |

### investiture-windows

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/local-fields/:localFieldId/investiture-windows/:ecclesiasticalYearId` | JWT | Consultan, dentro de su alcance: `director-lf`, `assistant-lf`, `admin`, `assistant-admin`, `director-union`, `assistant-union`, `director-dia`, `assistant-dia` y `super-admin`. Fuera de alcance: 403 `GUARD_PERMISSION_DENIED`. El alias de `GlobalRolesGuard` deja entrar a unión y división; el servicio igual recorta el Campo. | Sin fila y con intersección: 1 de octubre a 20 de diciembre, recortado al año, `configured` false, `operational` true, sin insertar. Sin intersección y sin configuración válida: `start_date` null, `end_date` null, `configured` false, `operational` false. No se devuelve el año completo ni un rango invertido. `operational` indica que existe un rango, no que el día local caiga dentro. Incluye `can_edit`. Una fila fuera del año, con inicio posterior al fin o con un día imposible no abre la ventana y la lectura no la reescribe. Editar la ventana no autoriza investiduras ni habilita el porcentaje de clase. | FieldInvestitureWindowConfigService.get() | `src/classes/field-investiture-window.controller.ts` |
| PATCH | `/api/v1/local-fields/:localFieldId/investiture-windows/:ecclesiasticalYearId` | JWT | Escriben, con el año activo y el día local dentro de ese año: `director-lf` y `assistant-lf` solo en su Campo; `admin` y `assistant-admin` en su alcance; `super-admin` en cualquier Campo. Unión y división no escriben: 403 `GUARD_PERMISSION_DENIED`. Año inactivo o día local fuera del año: 403 `INVESTITURE_WINDOW_EDIT_CLOSED`. | Cuerpo `start_date` y `end_date` (`YYYY-MM-DD`), inclusivos, dentro del año y con inicio no posterior al fin. Un cuerpo que no tiene esa forma lo rechaza el `I18nValidationPipe` con HTTP 400 sin `code`. Día imposible: 400 `INVESTITURE_WINDOW_DATE_INVALID`. Fuera del año: 400 `INVESTITURE_WINDOW_OUTSIDE_YEAR`. Inicio posterior al fin: 400 `INVESTITURE_WINDOW_START_AFTER_END`. Campo o año ausente: 404 `INVESTITURE_WINDOW_FIELD_NOT_FOUND` o `INVESTITURE_WINDOW_YEAR_NOT_FOUND`. | FieldInvestitureWindowConfigService.update() | `src/classes/field-investiture-window.controller.ts` |

### investiture-pastors

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/investiture-pastor-quota` | JWT | Leen: `super-admin`, `director-lf`, `assistant-lf`, `director-union` y `assistant-union`. Admin, división y director de club: 403 `GUARD_PERMISSION_DENIED`. El alias de `GlobalRolesGuard` deja entrar a división; el servicio igual responde 403. | Sin fila: `slots` 2, `configured` false, sin insertar. `can_edit` es true solo para `super-admin`. | DistrictInvestiturePastorService.getQuota() | `src/classes/district-investiture-pastors.controller.ts` |
| PATCH | `/api/v1/investiture-pastor-quota` | JWT | Solo `super-admin`. Los demás roles, incluidos Campo y unión: 403 `GUARD_PERMISSION_DENIED`. | Cuerpo `{ "slots": 1 }`, entero mayor o igual a 0. El mismo tope vale para todos los distritos. El cambio y las altas o reactivaciones comparten un candado de transacción, también si todavía no hay fila. Si algún distrito ya tiene más pastores activos, 409 `INVESTITURE_PASTOR_QUOTA_BELOW_ASSIGNMENTS` y no se reescribe ni se borran asignaciones. Un cuerpo que no es ese entero lo rechaza el `I18nValidationPipe` con HTTP 400 sin `code`. `INVESTITURE_PASTOR_QUOTA_INVALID` queda para el servicio. | DistrictInvestiturePastorService.updateQuota() | `src/classes/district-investiture-pastors.controller.ts` |
| GET | `/api/v1/districts/:districtId/investiture-pastors` | JWT | Leen dentro de su alcance: `director-lf`, `assistant-lf`, `director-union`, `assistant-union` y `super-admin`. Admin, división y un distrito fuera de alcance: 403 `GUARD_PERMISSION_DENIED`, sin listar pastores. | Pastores activos del distrito. Cada fila trae `user_name` (nombre y apellidos armados igual que en las solicitudes; «Sin nombre» si no hay datos) y `email`. Si el usuario sigue con el rol global `pastor`, `can_authorize` es true. Si ya no lo tiene, la fila sigue activa, ocupa cupo, `can_authorize` es false y `role_missing` es true. Si su cuenta está eliminada, la fila sigue activa y ocupando cupo, `can_authorize` es false y `account_inactive` es true. No se desactiva sola. `can_assign` es false para `super-admin` y cuando el cupo está lleno. | DistrictInvestiturePastorService.list() | `src/classes/district-investiture-pastors.controller.ts` |
| POST | `/api/v1/districts/:districtId/investiture-pastors` | JWT | Asignan dentro de su alcance: `director-lf`, `assistant-lf`, `director-union` y `assistant-union`. `super-admin`, admin y división no asignan por esos roles: 403 `GUARD_PERMISSION_DENIED`. Un cargo de unión sí alcanza los distritos de su unión; un director de Campo solo el suyo. | Cuerpo `{ "user_id": "<uuid>" }`. El usuario debe tener el rol global `pastor`. Alta y reactivación toman el mismo candado que el cambio de cupo antes de leer el tope, también sin fila. Cupo lleno: 409 `INVESTITURE_PASTOR_QUOTA_FULL`. Ya asignado: 409 `INVESTITURE_PASTOR_ALREADY_ASSIGNED`. Sin ese rol: 400 `INVESTITURE_PASTOR_ROLE_REQUIRED`. El pastor debe pertenecer al Campo del distrito (`users.local_field_id` igual al `local_field_id` del distrito); de otro Campo, aunque sea de la misma unión, o sin Campo: 400 `INVESTITURE_PASTOR_FIELD_MISMATCH`, también al reactivar una asignación inactiva y para un cargo de unión. Se evalúa después del rol. Usuario ausente: 404 `INVESTITURE_PASTOR_USER_NOT_FOUND`. Distrito ausente: 404 `INVESTITURE_PASTOR_DISTRICT_NOT_FOUND`. Dos altas del último cupo no pueden quedar ambas activas. La respuesta incluye `user_name` y `email`. Asignar no autoriza una investidura ni llama al pipeline anterior. | DistrictInvestiturePastorService.assign() | `src/classes/district-investiture-pastors.controller.ts` |
| DELETE | `/api/v1/districts/:districtId/investiture-pastors/:userId` | JWT | Los mismos roles que el POST, dentro del mismo alcance. | Desactiva la asignación y libera el cupo. Responde `can_authorize: false`, con `user_name` y `email`. Si no estaba activa: 404 `INVESTITURE_PASTOR_NOT_ASSIGNED`. | DistrictInvestiturePastorService.remove() | `src/classes/district-investiture-pastors.controller.ts` |
| GET | `/api/v1/clubs/:clubId/investiture-authorizers` | JWT | La misma lectura que el listado del distrito, aplicada al distrito resuelto. | El distrito sale de `clubs.church_id` → `churches.districlub_type_id`. No usa `clubs.districlub_type_id` ni un distrito del usuario. `resolved_from` es `church`. Solo entran pastores activos que todavía tienen el rol global `pastor`. Cada uno trae `user_name` y `email`. Quien lo perdió no aparece, aunque su asignación siga ocupando cupo. Club o iglesia ausente: 404 `INVESTITURE_PASTOR_CLUB_NOT_FOUND` o `INVESTITURE_PASTOR_CHURCH_NOT_FOUND`. | DistrictInvestiturePastorService.authorizersForClub() | `src/classes/district-investiture-pastors.controller.ts` |
| GET | `/api/v1/investiture-pastor-candidates?q=&districtId=` | JWT | Quien puede asignar: `director-lf`, `assistant-lf`, `director-union` y `assistant-union`. `super-admin`, admin, división y otros roles: 403 `GUARD_PERMISSION_DENIED`. Unión sin alcance: 403 `ADMIN_USER_SCOPE_MISSING`. | Busca a quién asignar como pastor. `q` es obligatorio, se recorta y exige 3 caracteres o más, y cada palabra (separada por espacios) al menos 2; si no, 400 del `I18nValidationPipe` (por ejemplo `a b`). Compara sin distinguir mayúsculas y por contenido en nombre, apellidos y correo; con varias palabras, cada una debe aparecer en alguno de esos campos. `%`, `_` y `\` se tratan como texto. Solo devuelve cuentas activas con el rol global `pastor` activo (la misma regla de `can_authorize`), hasta 20, por nombre. Cada elemento es `{ "user_id", "user_name", "email" }`. Limita por territorio de quien busca: `director-lf` y `assistant-lf` solo ven pastores cuyo `users.local_field_id` es su Campo; `director-union` y `assistant-union`, los de los Campos de su unión. Un pastor sin `local_field_id` no se devuelve (hay que fijarle el Campo en su perfil). `districtId` es opcional (entero positivo; otro valor: 400). Si viene, se autoriza el distrito con el mismo alcance que al asignar (fuera de alcance: 403 `GUARD_PERMISSION_DENIED`; ausente: 404 `INVESTITURE_PASTOR_DISTRICT_NOT_FOUND`, también con una `q` demasiado corta) y solo se devuelven pastores del Campo de ese distrito, que es la única regla con la que el alta los acepta; así un cargo de unión no ve pastores de otros Campos. Sin `districtId` se mantiene el límite por territorio descrito arriba. | DistrictInvestiturePastorService.searchCandidates() | `src/classes/district-investiture-pastors.controller.ts` |

### investiture-requests

Módulo hermano de `InvestitureModule`. No llama a `submit`, `club-approve`, `coordinator-approve`, `field-approve` ni `invest`, y no envía correo. El controlador usa `JwtAuthGuard` y `@SkipPermissions()`. No usa `GlobalRolesGuard`. El cargo se resuelve en el servicio: director, secretario o secretario-tesorero de esa sección y año, con asignación operativa y `status` active. El subdirector recibe 403 `INVESTITURE_REQUEST_FORBIDDEN` al presentar, leer, agregar, quitar y cambiar fecha. `super-admin` puede leer una solicitud por id y cambiar la fecha. No presenta, no agrega, no quita, no autoriza y el listado de autorizador le responde 403. Un cuerpo que no tiene la forma descrita lo rechaza el `I18nValidationPipe` con HTTP 400 sin `code`.

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/club-sections/:sectionId/investiture-requests` | JWT | Director, secretario o secretario-tesorero de la sección y el año. Subdirector y `super-admin`: 403 `INVESTITURE_REQUEST_FORBIDDEN`. | Cuerpo `{ "ecclesiastical_year_id", "investiture_date", "enrollment_ids" }`. Una solicitud por sección y año mientras haya pendientes. Varias personas comparten la fecha. El día local tiene que caer en la ventana y en el año. Si la llamada no trae un instante explícito, ese día se lee del reloj otra vez después de los candados y antes de escribir. Sin intersección de ventana: 409 `INVESTITURE_REQUEST_WINDOW_CLOSED`. Fecha fuera de la ventana: 400 `INVESTITURE_REQUEST_DATE_OUTSIDE_WINDOW`. Fuera del año: 400 `INVESTITURE_REQUEST_DATE_OUTSIDE_YEAR`. Día imposible: 400 `INVESTITURE_REQUEST_DATE_INVALID`. Año cerrado: 409 `INVESTITURE_REQUEST_YEAR_CLOSED`. Sin progreso: 409 `INVESTITURE_REQUEST_NOT_ELIGIBLE`. `GM-02` y `GM-03`: 400 `INVESTITURE_REQUEST_CLASS_NOT_ELIGIBLE`, sin insertar la persona. Sin duración mínima: 400 `INVESTITURE_DURATION_MIN_NOT_MET`. Certificado histórico: 409 `INVESTITURE_REQUEST_NOT_OPERATIONAL`. Fuera de la sección: 409 `INVESTITURE_REQUEST_OUTSIDE_SECTION`. Aventureros o Conquistadores con otra solicitud activa: 409 `INVESTITURE_REQUEST_ACTIVE_EXISTS`. Guía Mayor, incluido el ya investido que cursa otra clase por `cross_type_enrollment`, puede tener otra activa si la clase es distinta. Ya `INVESTIDO` en esa clase, en este enrollment o en otro de la misma persona y clase y de cualquier `record_kind`: 409 `INVESTITURE_REQUEST_ALREADY_INVESTED` y los pendientes anteriores de esa persona y clase pasan a `REMOVED` con `resolution_code` `ALREADY_INVESTED`. `enrollUser` no impide ese segundo enrollment salvo el caso estrecho de Guía Mayor investida y la clase destino también investida. `validateDisplayOrderProgression` no mira `investiture_status`. Solo con `locked_for_validation` en true (fase 8, decisión B5; el estado de la cadena ya no cuenta): 409 `INVESTITURE_REQUEST_LEGACY_PIPELINE_ACTIVE`. Un expediente desbloqueado, como uno que soltó el desbloqueo, sí se puede presentar. No se inserta la persona. Selección vacía: 400 `INVESTITURE_REQUEST_EMPTY`. Las altas de una persona toman `pg_advisory_xact_lock` por usuario antes de releer. | InvestitureAuthorizationRequestService.present() | `src/investiture-requests/investiture-authorization-requests.controller.ts` |
| GET | `/api/v1/club-sections/:sectionId/investiture-requests?ecclesiastical_year_id=` | JWT | Los mismos cargos de sección. Subdirector: 403. `super-admin` sin ese cargo: 403. | Devuelve la solicitud que todavía tiene alguien `PENDING`. Si no queda ninguno, devuelve la de `CLOSED_YEAR` cuyo `system_reason` es «Investidura acreditada posteriormente mediante certificado validado». Si tampoco, devuelve la informativa con `resolution_code` `HISTORICAL_CERTIFICATE_APPLIED`: la de menor `request_id` y, dentro de ella, la persona de menor `person_id`. Si no hay ninguna de las dos, `data: null` sin insertar. Cada persona trae `can_authorize: true` solo si sigue `PENDING`, y `resolution_code`. | InvestitureAuthorizationRequestService.list() | `src/investiture-requests/investiture-authorization-requests.controller.ts` |
| GET | `/api/v1/club-sections/:sectionId/investiture-requests/presentation-context?ecclesiastical_year_id=` | JWT | Director, secretario o secretario-tesorero de la sección y el año (los mismos de `present`). Subdirector y `super-admin` sin ese cargo: 403 `INVESTITURE_REQUEST_FORBIDDEN`. Sin `ecclesiastical_year_id`: 400. | Solo informativa: no escribe, no abre transacción ni toma candados; `present` vuelve a comprobar todo bajo candados. Devuelve `{ club_section_id, ecclesiastical_year_id, window: { start_date, end_date, open_today, time_zone_invalid }, year_open, open_request_id, candidates[] }`. `open_today` usa el día local del Campo; con la ventana cerrada los candidatos igual se listan. Si la zona horaria guardada del Campo es inválida, `open_today` es `false` y `time_zone_invalid` es `true` (la lectura sigue funcionando; `present` responde `INVESTITURE_REQUEST_TIME_ZONE_INVALID` hasta corregirla). `open_request_id` es la solicitud con `PENDING` de esa sección y año, o null. Cada candidato (`enrollment_id`, `user_id`, `user_name`, `class_id`, `class_name`, `overall_progress`, `eligible`, `blocked_code`, `pending_person_id`) sale de enrollments `OPERATIONAL` activos y no `INVESTIDO`, de la clase del tipo de la sección (las clases institucionales GM-02 y GM-03 no se listan: nunca tienen solicitudes), de miembros activos de la sección en ese año, más las clases cruzadas que `present` acepta (Guía Mayor investido con cargo en otra sección del mismo club). `blocked_code` es el primer código que `present` lanzaría (`INVESTITURE_REQUEST_NOT_OPERATIONAL`, `_OUTSIDE_SECTION`, `_ALREADY_INVESTED`, `_LEGACY_PIPELINE_ACTIVE`, `_ACTIVE_EXISTS`, `_NOT_ELIGIBLE`, `INVESTITURE_DURATION_MIN_NOT_MET`, `INVESTITURE_DURATION_EXPIRED`, `_CLASS_NOT_ELIGIBLE`); `pending_person_id` se llena si la persona ya está `PENDING` en la solicitud abierta. Orden: elegibles primero y luego por nombre. | InvestitureAuthorizationRequestService.presentationContext() | `src/investiture-requests/investiture-authorization-requests.controller.ts` |
| POST | `/api/v1/investiture-requests/:requestId/people` | JWT | Los mismos cargos de sección que el POST inicial. | Agrega personas con su propia fecha. No reescribe la fecha de quienes ya estaban. `GM-02` y `GM-03`: 400 `INVESTITURE_REQUEST_CLASS_NOT_ELIGIBLE`, sin insertar la persona. Mismas reglas de ventana, año, progreso, duración y solicitud activa. Sin instante explícito, el día se vuelve a leer del reloj después de los candados. Si otra cabecera de la sección y el año ya tiene pendientes, no reactiva esta: 409 `INVESTITURE_REQUEST_STALE`. Hay que volver a cargar el listado. No mueve personas. Otro `INVESTIDO` de la misma persona y clase, cualquier `record_kind`: 409 `INVESTITURE_REQUEST_ALREADY_INVESTED`. Solo `locked_for_validation` en true: 409 `INVESTITURE_REQUEST_LEGACY_PIPELINE_ACTIVE`. | InvestitureAuthorizationRequestService.addPeople() | `src/investiture-requests/investiture-authorization-requests.controller.ts` |
| DELETE | `/api/v1/investiture-requests/:requestId/people/:personId` | JWT | Los mismos cargos de sección. | Pasa el pendiente a `REMOVED`, `resolution_code` `REMOVED`. Libera solo el bloqueo de progreso de esa solicitud. No cambia `investiture_status` ni `locked_for_validation`. Si ya no está pendiente: 409 `INVESTITURE_REQUEST_NOT_PENDING`. | InvestitureAuthorizationRequestService.remove() | `src/investiture-requests/investiture-authorization-requests.controller.ts` |
| PATCH | `/api/v1/investiture-requests/:requestId/dates` | JWT | Director, secretario o secretario-tesorero de la sección, o `super-admin`. Subdirector: 403. | Cuerpo `{ "investiture_date", "person_ids" }`. Una fecha válida para todos los pendientes seleccionados. No toca a los no seleccionados ni a quien no está `PENDING`. Si alguno de la selección ya no está pendiente, no cambia a ninguno: 409 `INVESTITURE_REQUEST_NOT_PENDING`. Se puede corregir con el día local fuera de la ventana, si el año sigue abierto y la fecha nueva cae en la ventana y en el año. Con la ventana cerrada por falta de intersección, ninguna fecha entra. Año cerrado: 409 `INVESTITURE_REQUEST_YEAR_CLOSED`. Cada persona cambiada guarda `date_changed_by_id` y `date_changed_at` con el actor y el reloj de la aplicación. Quitar también usa ese reloj. La respuesta lleva la forma de la directiva (con el motivo humano de otras personas rechazadas) cuando corrige la directiva de la sección, y la forma del autorizador (`rejection_reason` en null) cuando corrige `super-admin`. | InvestitureAuthorizationRequestService.changeDates() | `src/investiture-requests/investiture-authorization-requests.controller.ts` |
| GET | `/api/v1/investiture-requests?ecclesiastical_year_id=` | JWT | Pastor asignado al distrito de la iglesia del club, o `director-lf` / `assistant-lf` de ese Campo. `admin`, `super-admin`, unión, división y el directivo de sección no listan por esos cargos: 403 `INVESTITURE_REQUEST_FORBIDDEN`. Otro Campo u otro distrito: 403. | Lista las solicitudes de ese año que todavía tienen alguien `PENDING`, una persona `CLOSED_YEAR` con `system_reason` «Investidura acreditada posteriormente mediante certificado validado», o una persona `REMOVED` con `resolution_code` `HISTORICAL_CERTIFICATE_APPLIED`, en el territorio del actor. Cada solicitud trae además `club_id`, `club_name`, `section_name`, `district_name`, `pending_count` (personas `PENDING`), `earliest_investiture_date` (menor fecha entre los `PENDING`, o null) y `created_at`; se leen por lote, sin una consulta por solicitud. Cada persona trae `user_name`, `class_name`, `section_name` y `resolved_by_name`. El autorizador ve `system_reason` y `rejection_reason` en null. No envía correo por ese retiro. | InvestitureAuthorizationRequestService.listForAuthorizer() | `src/investiture-requests/investiture-authorization-requests.controller.ts` |
| GET | `/api/v1/investiture-requests/:requestId` | JWT | El autorizador del territorio, o `super-admin`. | Devuelve la solicitud con todas sus personas, incluidos investidos, rechazados y retirados, y los mismos campos de cabecera del listado (`club_id`, `club_name`, `section_name`, `district_name`, `pending_count`, `earliest_investiture_date`, `created_at`; también presentes en las lecturas de la directiva). Trae `user_name`, `class_name`, `section_name`, `authorization_comment`, `system_reason`, `resolution_code`, `resolved_by_id`, `resolved_by_name`, `date_changed_by_id` y `date_changed_at`. En un rechazo del sistema, `resolved_by_name` es «Sistema». El autorizador recibe `rejection_reason` en null. `super-admin` lee con la forma del autorizador (`rejection_reason` en null, sin el motivo humano) y no puede presentar ni resolver. Un certificado de un año anterior deja `REMOVED`, `resolution_code` `HISTORICAL_CERTIFICATE_APPLIED` y `system_reason` «Investidura aplicada por certificado de un año anterior». Un certificado del mismo año ya terminado deja `CLOSED_YEAR` y `system_reason` «Investidura acreditada posteriormente mediante certificado validado». | InvestitureAuthorizationRequestService.readForAuthorizer() | `src/investiture-requests/investiture-authorization-requests.controller.ts` |
| GET | `/api/v1/investiture-history` | JWT | Quien consulta, solo sus filas. | Historial propio. Incluye `PENDING`, `INVESTED`, rechazos, `CLOSED_YEAR` y el `REMOVED` de certificado histórico. Trae `class_id`, `class_name` y `ecclesiastical_year_id`. No trae `rejection_reason`, `system_reason` ni el tipo de rechazo. `PENDING`: `person_text` «En espera de autorización.». `INVESTED`: la fecha, la clase y `authorization_comment` si existe. Los dos rechazos salen como `status` `REJECTED` y `person_text` «Falta de requisitos para investidura». `CLOSED_YEAR` no usa ese texto. El certificado posterior del mismo año y el histórico dejan su nota en `person_text`. | InvestitureAuthorizationRequestService.ownHistory() | `src/investiture-requests/investiture-authorization-requests.controller.ts` |
| GET | `/api/v1/club-sections/:sectionId/investiture-history` | JWT | Director, secretario o secretario-tesorero con cargo operativo activo en esa sección. Otro cargo o otra sección: 403 `INVESTITURE_REQUEST_FORBIDDEN`. | El mismo historial, limitado a la sección. `CLOSED_YEAR` no trae el texto de falta de requisitos. Si se acreditó después por certificado del mismo año, `system_reason` es «Investidura acreditada posteriormente mediante certificado validado». | InvestitureAuthorizationRequestService.sectionHistory() | `src/investiture-requests/investiture-authorization-requests.controller.ts` |
| GET | `/api/v1/club-sections/:sectionId/investiture-yearbook` | JWT | Los mismos cargos de esa sección. | Anuario, no un aviso. Lista enrollments `OPERATIONAL` cuyo tipo de clase es el de esa sección, de quienes tuvieron cargo `active`, `inactive` o `ended` en cualquier sección del mismo club. Una clase de otro tipo, aunque la persona tenga membresía aquí, no entra. La clase cruzada aparece en la sección de su tipo, en el mismo club. No exige una solicitud de investidura. No crea inscripciones ni incluye otro club. | InvestitureAuthorizationRequestService.yearbook() | `src/investiture-requests/investiture-authorization-requests.controller.ts` |
| POST | `/api/v1/investiture-requests/:requestId/resolutions` | JWT | El mismo autorizador. Editar la ventana o la fecha no autoriza. | Cuerpo `{ "invest": [{ "person_id", "comment"? }], "reject": [{ "person_id", "reason" }] }`. `GM-02` y `GM-03` ya pendientes: `REMOVED` con `resolution_code` `CLASS_NOT_ELIGIBLE`, sin investir, sin evento y sin texto de falta de requisitos; el resto de la resolución se confirma. Presentar o agregar esas clases sigue en 400 `INVESTITURE_REQUEST_CLASS_NOT_ELIGIBLE`. Se puede investir a unos y rechazar a otros; el resto sigue `PENDING`. El comentario es opcional, hasta 500. El motivo humano es obligatorio, hasta 1000; si falta: 400 `INVESTITURE_REQUEST_REASON_REQUIRED`. Una persona en las dos listas, o repetida: 400 `INVESTITURE_REQUEST_CONFLICTING_DECISION`. Texto más largo: 400 `INVESTITURE_REQUEST_TEXT_TOO_LONG`. Selección vacía: 400 `INVESTITURE_REQUEST_EMPTY`. El día local tiene que caer en la ventana, hasta el último día incluido. No hay plazo de siete días después de la fecha de investidura. Fuera de la ventana: 409 `INVESTITURE_REQUEST_WINDOW_CLOSED`. Cambiar solo la fecha no reabre la ventana. Ampliar la ventana dentro del año sí permite resolver. Año cerrado, o el día local después de `end_date` aunque `active` siga true: 409 `INVESTITURE_REQUEST_YEAR_CLOSED`. Si la fecha de una persona quedó fuera de la ventana, esa persona sigue `PENDING` y la respuesta la trae en `blocked` con `INVESTITURE_REQUEST_DATE_OUTSIDE_WINDOW`; las demás de la misma llamada sí se resuelven. Si todas quedan bloqueadas, 400 con ese código y no se escribe nada. Quien ya no cumple progreso o duración queda `REJECTED_BY_SYSTEM`, `resolution_code` `REQUIREMENTS`, `system_reason` con el texto largo, y su enrollment no pasa a `INVESTIDO`. Las demás pueden quedar investidas. El rechazo humano queda `REJECTED_BY_PERSON` con `rejection_reason` y no cambia `investiture_status`. Autorizar pone la persona en `INVESTED` y el enrollment en `INVESTIDO` con la fecha de esa persona, sin fila en `investiture_validation_history`. El `updateMany` del enrollment exige el estado releído dentro de la transacción y, si coincide, deja `INVESTIDO` con `locked_for_validation` en false. Si no coincide una fila, esa persona queda `REMOVED` sin escribir el enrollment y sin `class.completed`. Si el estado actual es `INVESTIDO`, `resolution_code` es `ALREADY_INVESTED`. Si el enrollment conserva `locked_for_validation` en true de la vía anterior (y no está en `FIELD_APPROVED`), es `LEGACY_PIPELINE_ACTIVE`. En otro desajuste es `CONCURRENT_STATUS`. Las demás personas de la misma llamada se confirman. Ese desajuste no responde 409. Un `INVESTIDO` de la misma persona y clase, en otro enrollment y cualquier `record_kind`, deja a la persona `REMOVED` con `resolution_code` `ALREADY_INVESTED`, sin evento y sin el texto de falta de requisitos. Un enrollment con `locked_for_validation` en true que no está en `FIELD_APPROVED` queda `REMOVED` con `resolution_code` `LEGACY_PIPELINE_ACTIVE`, sin escribir el enrollment, sin evento y sin ese texto. `FIELD_APPROVED` con persona `PENDING`, aunque `locked_for_validation` sea true, lo escribe esta resolución: es el único escritor de esa carrera contra `invest`. Presentar y agregar rechazan ese `FIELD_APPROVED` solo mientras conserva `locked_for_validation`. Con la persona en `INVESTED` queda, en la misma transacción, `achievement_intent_key`. `class.completed` se entrega después del commit, con `idempotency_key` igual a esa intención. El `jobId` de la cola es otro valor estable, sin `:`. Si el insert o la cola fallan, la respuesta sigue en éxito. Si ese trabajo agota sus intentos y queda en `failed`, la reconciliación lo reintenta con el mismo id y los intentos en cero; no crea otra fila. Una reconciliación al arrancar y cada cinco minutos entrega esa intención aunque el año o la ventana ya hayan cerrado o el autorizador ya no tenga la asignación; no reabre la decisión. El reintento del POST, con el calendario abierto, también recupera una sola fila y después responde 409 `INVESTITURE_REQUEST_ALREADY_RESOLVED`. Presentar, rechazar, quitar, el cierre de esa fila o un fallo antes de confirmar no lo emiten. Si la persona ya no está pendiente y no hay intención pendiente, 409 `INVESTITURE_REQUEST_ALREADY_RESOLVED` cuando ninguna de la selección se pudo resolver. La primera decisión confirmada queda. Dentro de la transacción, después de esperar, se leen el año, la ventana y la asignación del pastor, y el instante de esa comprobación se toma después de los candados. El orden de candados es año, calendario del Campo, pastor si aplica, sección/año, usuarios y enrollments. Guardar la ventana, cerrar el año y quitar al pastor toman el candado que les corresponde, también si la ventana todavía no tiene fila. El cierre de una fila `PENDING` como `CLOSED_YEAR` no es ruta HTTP: lo hace `closePendingInvestitureAuthorizations`, sin tocar el enrollment ni emitir el logro. No envía correo ni notificación. | InvestitureAuthorizationRequestService.resolve() | `src/investiture-requests/investiture-authorization-requests.controller.ts` |

La duración usa el año de inicio del enrollment y el año de la solicitud. Si todavía no cumple `min_duration_years`, responde 400 `INVESTITURE_DURATION_MIN_NOT_MET`. Si ya superó `max_duration_years`, o el estado es `EXPIRED`, responde 400 `INVESTITURE_DURATION_EXPIRED` y no cambia el enrollment. Una inscripción cruzada válida se presenta en la sección del mismo club cuyo tipo es el de la clase; la membresía puede estar en otra sección de ese club. La sección de otro tipo, u otro club, responde 409 `INVESTITURE_REQUEST_OUTSIDE_SECTION`.

Presentar y agregar toman el candado de sección y año antes de buscar o crear la cabecera, aunque esa fila todavía no exista, y luego el candado de cada enrollment. Dos personas distintas de la misma sección y año quedan en una sola solicitud. La lectura devuelve a todas las que siguen `PENDING`. Después de confirmar, presentan y agregan guardan la intención del correo en esa misma transacción y después preparan un correo por destinatario y por rol. Cada presentación tiene su propia identidad. Volver a presentar los mismos enrollments es otra operación. Recuperar no cambia la identidad de quien ya fue atendido. Quitar y cambiar la fecha no lo preparan. Aceptar la cola deja el aviso en `queued`. `sent` llega cuando el proveedor confirma. Si ese acuse se pierde y el envío sigue permitido, el reintento usa el contenido guardado durante 24 horas y después el aviso queda `uncertain`, sin reenviar solo. Antes de cada llamada al proveedor, también con ese contenido congelado, se vuelven a leer destinatario, rol, territorio, año y pendientes. Si ya no corresponde, o si solo queda autorizada una parte del contenido congelado, no se envía y no se cambia el cuerpo ni la clave. Ese cuerpo, su destino y su alcance salen de la misma instantánea con la que se armó el correo.

Mientras una persona sigue `PENDING`, puntaje, alta o baja de evidencia, envío de la sección, y aprobar o rechazar esa evidencia responden 409 `INVESTITURE_REQUEST_PROGRESS_LOCKED`. Las escrituras de la vía anterior (club → coordinación → campo) ya no existen: sus rutas, los alias de enrollments, las operaciones en bloque y `POST /validation/submit` o `POST /validation/class/:id/review` con `entity_type` `class` responden HTTP 410 `INVESTITURE_LEGACY_PIPELINE_RETIRED` (fase 8, sección «investiture» más abajo), así que ya no responden `INVESTITURE_REQUEST_PROGRESS_LOCKED`. El código `INVESTITURE_CONCURRENT_UPDATE` (y otros siete que solo usaba esa vía: `INVESTITURE_INVALID_STATE_TRANSITION`, `INVESTITURE_ALREADY_INVESTIDO`, `INVESTITURE_REJECT_COMMENTS_REQUIRED`, `INVESTITURE_FIELD_APPROVE_REQUIRES_ADMIN`, `INVESTITURE_CONFIG_NOT_FOUND`, `INVESTITURE_CONFIG_DUPLICATE`, `INVESTITURE_REQUIREMENTS_INCOMPLETE`) se eliminó del backend en la fase 8. El honor no cambia. `expire-overdue` toma el mismo candado del enrollment dentro de la transacción que guarda, omite al enrollment con un `PENDING` sin abortar el lote y no escribe historial de las filas que no pasaron a `EXPIRED`. `locked_for_validation`, `INVESTIDO` y `EXPIRED` responden `CLASS_PROGRESS_LOCKED` antes de escribir; los estados de la cadena anterior (`CLUB_APPROVED`, `APPROVED` y similares) ya no bloquean por sí solos, así que un expediente liberado por el desbloqueo vuelve a admitir progreso. Enviar una sección y aprobar o rechazar una evidencia de clase solo se cierran con `INVESTIDO` o `EXPIRED`. Otra clase de la misma persona no queda bloqueada por esa fila.

Una resolución confirmada avisa en la bandeja de la app, no por correo. La intención de ese aviso queda en la misma transacción. La directiva de esa sección recibe como máximo dos avisos: uno de investidos y uno de rechazados. El de rechazados junta el rechazo humano y el del sistema, nombra a cada persona y dice quién decidió (la persona o «el sistema», con el texto largo solo en el del sistema). No incluye el motivo humano. La persona investida recibe el texto alegre, sin el comentario. Cualquier rechazo le deja solo «Falta de requisitos para investidura». El motivo humano y el comentario no salen en el aviso de la persona. El subdirector no lo recibe. Un reintento de una decisión ya confirmada no vuelve a avisar. La bandeja usa `notification_logs.idempotency_key`. Si esa escritura falla, el aviso no queda `sent`. El push no sustituye esa fila. El push del resultado lleva `data` con `type: "investiture_result"`, `audience` (`person` o `board`), `requestId`, `sectionId` (cadena) y, solo para `person`, `classId` (cadena); la bandeja (`notification_logs`) no cambia y se enruta por `source` (`investiture:invested` o `investiture:rejected`). Quien apaga `approvals` no lo recibe. El recordatorio es otro correo, el día programado, desde las 10:00 hasta las 23:59 en la zona del Campo. Si la corrida de las 10:00 no ocurrió, sale en la primera corrida de ese mismo día local y no se recupera un día anterior. Un reintento de un fallo vale solo ese día local de la ejecución; pasado el día queda `skipped` con `reminder_day_elapsed`. El tope es 5 intentos al proveedor y después `reminder_retry_limit`: cada entrega de un recordatorio a la cola es un único intento (`attempts: 1`, sin reintentos internos de BullMQ), de modo que el total no pasa de 5 llamadas al proveedor. No crea avisos periódicos en el panel. Una zona en blanco usa `America/Mexico_City`. Una zona inválida responde 400 `INVESTITURE_REQUEST_TIME_ZONE_INVALID` en la solicitud y en el certificado, y el recordatorio omite ese Campo. Un pastor que perdió el rol global no recibe presentación ni recordatorio. Antes de cada llamada al proveedor se vuelven a leer alcance, año, ventana y pendientes, también cuando el contenido ya está congelado. Si ya no corresponde, o si solo queda autorizada una parte del contenido congelado, no se envía y no se cambia el cuerpo ni la clave. Ese cuerpo, su destino y su alcance salen de la misma instantánea con la que se armó el correo. Si sigue permitido, un acuse ambiguo se reconcilia con el contenido guardado durante 24 horas y después queda `uncertain`. La ventana por defecto se resuelve igual en el primer envío y en el reintento. `investiture_message_dispatches` impide repetir el mismo envío para el mismo destinatario, rol y alcance. `queued` no es entrega. `INVESTITURE_EMAIL_ENABLED` sale en false. `ADMIN_PANEL_URL` arma `{origen}/investiture-requests/{requestId}` y solo es obligatorio con ese interruptor encendido. Presentación y recordatorios solo salen si ese interruptor y `EMAIL_ENABLED` están en true. Si falta uno, quedan `skipped` con `last_error` `investiture_email_disabled` y no se reenvían al encender el otro. Un job ya encolado se vuelve a consultar antes del proveedor y, si el correo ya no está habilitado, tampoco sale. La bandeja de la app no usa esos interruptores. Un error de un Campo no aborta los otros ni `deliverPending`. Cada aparición de `/investiture-requests/` exige origen absoluto. La fase 8 apagó la vía anterior en el código (rama `feat/investiture-legacy-shutdown`): no está desplegada, y sus migraciones y el desbloqueo no se aplicaron ni corrieron en ningún entorno.

### classes

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/classes` | Optional JWT | - | Listar clases | ClassesService.findAll() | `src/classes/classes.controller.ts` |
| GET | `/api/v1/classes/:classId` | Optional JWT | - | Obtener clase por ID (incluye `prerequisites` activos y `honors[]` por módulo) | ClassesService.findOne() | `src/classes/classes.controller.ts` |
| GET | `/api/v1/classes/:classId/modules` | Optional JWT | - | Obtener módulos de una clase (embebe `honors[]` por módulo, sin `user_status`) | ClassesService.getModules() | `src/classes/classes.controller.ts` |
| GET | `/api/v1/classes/:classId/honors` | Optional JWT | - | Especialidades relacionadas (`class_honors`); `module_id`, `module_name`, `material_url`; con JWT opcional incluye `user_status`. Informativo: no bloquea módulo ni investidura | ClassesService.getClassHonors() | `src/classes/classes.controller.ts` |

### user-classes

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/users/:userId/classes` | JWT | Permisos: classes:read | Obtener inscripciones del usuario, por `enrollment_date` desc. Cada fila trae `active`: `false` es una inscripción reemplazada al volver a elegir clase. La app la descarta, salvo `INVESTIDO`, y nunca la toma como clase actual. | ClassesService.getUserEnrollments() | `src/classes/classes.controller.ts` |
| POST | `/api/v1/users/:userId/classes/enroll` | JWT | Permisos: classes:submit_progress | Inscribir usuario en clase. GM investido puede añadir una clase cruzada de Aventureros/Conquistadores (`cross_type_enrollment`). Errores: `CLASS_MAX_AVENTU_CONQUIS_ACTIVE`, `CLASS_MAX_GM_ACTIVE`, `CLASS_CROSS_TYPE_GM_REQUIRED`, `CLASS_ALREADY_INVESTED`, `CLASS_ALREADY_ENROLLED` | ClassesService.enrollUser() | `src/classes/classes.controller.ts` |
| GET | `/api/v1/users/:userId/classes/:classId/progress` | JWT | Permisos: classes:read | Obtener progreso del usuario en una clase | ClassesService.getUserProgress() | `src/classes/classes.controller.ts` |
| PATCH | `/api/v1/users/:userId/classes/:classId/progress` | JWT | Permisos: classes:submit_progress | Actualizar progreso de sección | ClassesService.updateSectionProgress() | `src/classes/classes.controller.ts` |
| POST | `/api/v1/users/:userId/classes/:classId/sections/:sectionId/submit` | JWT | Permisos: classes:submit_progress | Submit a class section for validation | ClassesService.submitSection() | `src/classes/classes.controller.ts` |
| POST | `/api/v1/users/:userId/classes/:classId/sections/:sectionId/files` | JWT | Permisos: classes:submit_progress | Upload evidence file for a class section | ClassesService.uploadSectionFile() | `src/classes/classes.controller.ts` |
| DELETE | `/api/v1/users/:userId/classes/:classId/sections/:sectionId/files/:fileId` | JWT | Permisos: classes:submit_progress | Delete evidence file for a class section | ClassesService.deleteSectionFile() | `src/classes/classes.controller.ts` |

### club-enrollments

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/club-enrollments/validation/queue` | JWT | Permisos: club_instances:update | Listar inscripciones anuales pendientes de Campo Local | ClubEnrollmentsService.findValidationQueue() | `src/club-enrollments/club-enrollment-validation.controller.ts` |
| POST | `/api/v1/club-enrollments/:enrollmentId/approve` | JWT | Permisos: club_instances:update | Aprobar inscripción anual del club | ClubEnrollmentsService.approve() | `src/club-enrollments/club-enrollment-validation.controller.ts` |
| POST | `/api/v1/club-enrollments/:enrollmentId/reject` | JWT | Permisos: club_instances:update | Rechazar inscripción anual del club | ClubEnrollmentsService.reject() | `src/club-enrollments/club-enrollment-validation.controller.ts` |
| POST | `/api/v1/clubs/:clubId/sections/:sectionId/enrollments` | JWT | Permisos: club_instances:create | Crear inscripción anual. La sección debe pertenecer a `clubId`: si no, 404 `CLUB_SECTION_NOT_FOUND`. Un rol de club sin alcance territorial solo pasa en su propia sección activa; en otra sección del mismo club, 403 `GUARD_CLUB_SCOPE_REQUIRED` (antes pasaba en cualquiera del club). Los actores con alcance territorial (`canManageClub`) no cambian. | ClubEnrollmentsService.create() | `src/club-enrollments/club-enrollments.controller.ts` |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId/enrollments` | JWT | Permisos: club_instances:read | Listar inscripciones de la sección. Misma regla de sección que el POST: 404 `CLUB_SECTION_NOT_FOUND` si no pertenece a `clubId`; 403 `GUARD_CLUB_SCOPE_REQUIRED` para un rol de club fuera de su sección activa. | ClubEnrollmentsService.findBySectionId() | `src/club-enrollments/club-enrollments.controller.ts` |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId/enrollments/current` | JWT | Permisos: club_instances:read | Obtener inscripción vigente. Misma regla de sección que el POST: 404 `CLUB_SECTION_NOT_FOUND`; 403 `GUARD_CLUB_SCOPE_REQUIRED` fuera de la sección activa del rol de club. Sigue con `@ActingScope('member:read')`. | ClubEnrollmentsService.findCurrentBySectionId() | `src/club-enrollments/club-enrollments.controller.ts` |
| PATCH | `/api/v1/clubs/:clubId/sections/:sectionId/enrollments/:enrollmentId` | JWT | Permisos: club_instances:update | Actualizar inscripción. Misma regla de sección que el POST: 404 `CLUB_SECTION_NOT_FOUND`; 403 `GUARD_CLUB_SCOPE_REQUIRED`. Además, la inscripción debe pertenecer a la sección de la ruta: si no, 404 `CE_ENROLLMENT_NOT_FOUND`. Antes podía editarse cualquier inscripción por id. | ClubEnrollmentsService.update() | `src/club-enrollments/club-enrollments.controller.ts` |

### clubs

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/clubs` | JWT | SkipPermissions (picker post-registro); `@ActingScope('registration:write')` (el tutor que actúa por un menor la usa en el paso 3). Con rol territorial el backend recorta por JWT; filtros fuera de alcance → 403 `GUARD_PERMISSION_DENIED`. Sin rol territorial la lista sigue amplia. | Listar clubs | ClubsService.findAll() | `src/clubs/clubs.controller.ts` |
| GET | `/api/v1/clubs/:clubId` | JWT | Permisos: clubs:read | Obtener club por ID | ClubsService.findOne() | `src/clubs/clubs.controller.ts` |
| POST | `/api/v1/clubs` | JWT | Permisos: clubs:create. `local_field_id` debe estar dentro del alcance territorial del actor (`403 GUARD_PERMISSION_DENIED` si no). | Crear club y una sección por cada `club_type` activo. `enabled_club_type_ids` marca AV/CQ `active=true`. Guías Mayores (name/slug/code, nunca `club_type_id` numérico) queda siempre `active=true` y se inyecta si se omite. Array vacío válido si hay GM en catálogo; si no → `400 CLUB_SECTION_TYPES_REQUIRED`. Catálogo vacío o id inexistente → `400 CLUB_TYPE_NOT_FOUND`. No se inventa un id GM. | ClubsService.create() | `src/clubs/clubs.controller.ts` |
| PATCH | `/api/v1/clubs/:clubId` | JWT | Permisos: clubs:update; Club: director, deputy-director, secretary, secretary-treasurer | Actualizar ficha del club (dirección o secretaría de la sección activa) | ClubsService.update() | `src/clubs/clubs.controller.ts` |
| DELETE | `/api/v1/clubs/:clubId` | JWT | Permisos: clubs:delete; Club: director | Desactivar club (requiere rol director) | ClubsService.remove() | `src/clubs/clubs.controller.ts` |
| GET | `/api/v1/clubs/:clubId/sections` | JWT | SkipPermissions (picker post-registro); `@ActingScope('registration:write')` | Listar secciones del club. Por defecto solo `active=true` (post-registro/membresía). `?includeInactive=true` para gestión. Sin `name`; el tipo va en `club_types` | ClubsService.getSections() | `src/clubs/clubs.controller.ts` |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId` | JWT | Permisos: club_sections:read | Obtener sección por ID | ClubsService.getSection() | `src/clubs/clubs.controller.ts` |
| POST | `/api/v1/clubs/:clubId/sections` | JWT | Permisos: club_sections:create; Club: director, deputy-director | Crear sección si falta el tipo (club pre-migración). 409 si el tipo ya existe. Sin nombre propio | ClubsService.createSection() | `src/clubs/clubs.controller.ts` |
| PATCH | `/api/v1/clubs/:clubId/sections/:sectionId` | JWT | Permisos: club_sections:update; recurso `club_section`; Club: director, deputy-director, secretary, secretary-treasurer de esa sección | Actualizar sección (dirección o secretaría de la sección activa; no cruza a otra sección del mismo club). `active=false` en Guías Mayores → `400 CLUB_SECTION_MASTER_GUIDES_REQUIRED`. `active=true` en GM inactiva (legado) está permitido. `fee` / `souls_target` / meeting no se bloquean. | ClubsService.updateSection() | `src/clubs/clubs.controller.ts` |
| GET | `/api/v1/clubs/:clubId/leadership` | JWT | Permisos: clubs:read | Liderazgo del club: solo `status=active` del año eclesiástico vigente (excluye `designated`) | ClubsService.getClubLeadership() | `src/clubs/clubs.controller.ts` |
| GET | `/api/v1/clubs/:clubId/overview` | JWT | Permisos: clubs:read | Resumen agregado del club | ClubsService.getClubOverview() | `src/clubs/clubs.controller.ts` |
| GET | `/api/v1/clubs/:clubId/history` | JWT | Permisos: clubs:read | Historial de auditoría del club | ClubsService.getClubHistory() | `src/clubs/clubs.controller.ts` |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId/members` | JWT | Permisos: club_roles:read | Listar miembros de la sección. Incluye `guide_major_eligible` y `guide_major_basis` (`INVESTED`/`APPROVED`/`ACTIVE_ENROLLMENT`); `class_counselor_eligible` queda como alias. Primero corre `ClubsService.assertSectionBelongsToClub`: sección inexistente o de otro club → 404 `CLUB_SECTION_NOT_FOUND`, antes de cualquier lectura o escritura. La autorización no cambia (`type: 'club'`). | ClubsService.getMembers() | `src/clubs/clubs.controller.ts` |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId/members/:userId/assignable-roles` | JWT | Permisos: club_roles:read | Roles de club que se pueden asignar al usuario en esa sección. Devuelve `{ guide_major_eligible, section_kind (AV|CQ|GM|UNKNOWN), roles: [{ role_id, role_name, allowed, violation_rule, violation_code }] }` con **todos** los roles de club; los no permitidos traen `allowed:false` y el motivo (`CLUB_ROLE_GUIDE_MAJOR_REQUIRED` o `CLUB_ROLE_MEMBER_REQUIRES_GUIDE_MAJOR_SECTION`). La sección debe pertenecer a `clubId` y el usuario debe tener una asignación en ella (si no, 404 `GUARD_ASSIGNMENT_NOT_FOUND`). | ClubsService.getAssignableRoles() | `src/clubs/clubs.controller.ts` |
| POST | `/api/v1/clubs/:clubId/sections/:sectionId/roles` | JWT | Permisos: club_roles:assign | Asignar rol a un miembro (requiere director, deputy director o secretary). Elegibilidad GM (también en `PATCH /club-roles/:assignmentId`, `director-assignment`, `director-succession`, solicitudes de asignación/transferencia, aprobación de membresía y post-registro): 403 `CLUB_ROLE_GUIDE_MAJOR_REQUIRED` (cargo distinto de `member` sin ser elegible GM) o 403 `CLUB_ROLE_MEMBER_REQUIRES_GUIDE_MAJOR_SECTION` (elegible GM como `member` de AV/CQ); inscripción anual: outcome `blocked` con el mismo código (el salto de tipo AV→CQ por violación responde `skipped`, solo con `logger.warn`). Un menor sin consentimiento verificado → 409 `MR_CONSENT_NOT_VERIFIED` (compuerta de activación, ver `membership-requests`). Primero corre `ClubsService.assertSectionBelongsToClub`: sección inexistente o de otro club → 404 `CLUB_SECTION_NOT_FOUND`, antes de cualquier lectura o escritura. La autorización no cambia (`type: 'club'`). | ClubsService.assignRole() | `src/clubs/clubs.controller.ts` |
| POST | `/api/v1/clubs/:clubId/sections/:sectionId/director-assignment` | JWT | Permisos: club_roles:assign | Asignación inicial de director de sección del **año vigente**. Year distinto → 400 `CLUB_DIRECTOR_DESIGNATION_YEAR_INVALID`. Un menor sin consentimiento verificado → 409 `MR_CONSENT_NOT_VERIFIED`. Primero corre `ClubsService.assertSectionBelongsToClub`: sección inexistente o de otro club → 404 `CLUB_SECTION_NOT_FOUND`, antes de cualquier lectura o escritura. La autorización no cambia (`type: 'club'`). | ClubsService.assignInitialSectionDirector() | `src/clubs/clubs.controller.ts` |
| POST | `/api/v1/clubs/:clubId/sections/:sectionId/director-succession` | JWT | Permisos: club_roles:assign, club_roles:revoke; actores: super-admin, admin, director-lf, assistant-lf + canManageClub | Destitución del director en el **año eclesiástico vigente** (`getCurrentYear()`). El year del body y el de `current_assignment_id` deben coincidir con ese año; si no → 400 `CLUB_DIRECTOR_DESIGNATION_YEAR_INVALID`. **No** es la herramienta de diciembre para N+1 (usar `director-designation`). Un sucesor menor sin consentimiento verificado → 409 `MR_CONSENT_NOT_VERIFIED`, comprobado antes de terminar al director saliente (no se escribe nada). Primero corre `ClubsService.assertSectionBelongsToClub`: sección inexistente o de otro club → 404 `CLUB_SECTION_NOT_FOUND`, antes de cualquier lectura o escritura. La autorización no cambia (`type: 'club'`). | ClubsService.succeedSectionDirector() | `src/clubs/clubs.controller.ts` |
| POST | `/api/v1/clubs/:clubId/sections/:sectionId/director-designation` | JWT | Permisos: club_roles:assign; `@AuthorizationResource` club; assertCanDesignateDirector (super-admin, admin, director-lf, assistant-lf + canManageClub). Sección debe pertenecer a `clubId`. Header `Idempotency-Key` obligatorio | Preelegir director de un año futuro: crea fila en `director_succession_plans` (`status=scheduled`). No crea CRA `designated` ni invalida caché del sucesor. Vacante → `outgoing_assignment_id` null. Body `{ user_id, ecclesiastical_year_id }`. 201 data `{ succession_id, user_id, ecclesiastical_year_id, effective_date, status, version, outgoing_assignment_id }`. Misma clave+payload reutiliza el plan; distinta payload → 409 `IDEMPOTENCY_KEY_REUSED`. Plan abierto existente → 409 `CLUB_DIRECTOR_PLAN_CONFLICT`. Año no futuro (fechas, no `year_id`) → 400 `CLUB_DIRECTOR_PLAN_YEAR_INVALID`. Falta header → 400 `CLUB_DIRECTOR_PLAN_IDEMPOTENCY_REQUIRED`. `CLUB_DIRECTOR_DESIGNATION_YEAR_INVALID` queda para assignment/succession/update del **año vigente**, no para preelección | DirectorDesignationService.designate() | `src/clubs/clubs.controller.ts` |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId/director-designation` | JWT | Mismos actores que POST (permiso + assertCanDesignateDirector; no basta el permiso solo) | Plan abierto (`scheduled`/`activated`/`blocked`) del año `?yearId=` o `null`. Nunca CRA `designated` | DirectorDesignationService.getDesignation() | `src/clubs/clubs.controller.ts` |
| PATCH | `/api/v1/clubs/:clubId/sections/:sectionId/director-designation` | JWT | Mismos actores que POST | Reemplazar sucesor de un plan `scheduled`. Body `{ succession_id, version, successor_user_id }`. No muta al director operativo. 404 `CLUB_DIRECTOR_PLAN_NOT_FOUND`; versión obsoleta → 409 `CLUB_DIRECTOR_PLAN_VERSION_CONFLICT` | DirectorDesignationService.replacePlan() | `src/clubs/clubs.controller.ts` |
| DELETE | `/api/v1/clubs/:clubId/sections/:sectionId/director-designation` | JWT | Mismos actores que POST | Cancelar plan `scheduled`. Query `successionId` + `version`. No muta al director operativo. Tras cancelar se puede reprogramar | DirectorDesignationService.cancelPlan() | `src/clubs/clubs.controller.ts` |

### club-roles

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| PATCH | `/api/v1/club-roles/:assignmentId` | JWT | Permisos: club_roles:assign | Actualizar asignación de rol. No admite escribir `status=designated` (400 `CLUB_DIRECTOR_DESIGNATION_YEAR_INVALID`). Una fila ya `designated` no reconciliada rechaza cualquier mutación → 409 `CLUB_DIRECTOR_DESIGNATED_UNRECONCILED`. No mover un director a un año no vigente. `status` es un enum cerrado (`@IsIn`): `active`, `inactive`, `pending`, `rejected`, `expired`, `cancelled`, `ended` o `designated`; cualquier otro valor → 400 de validación. Un PATCH que escribe `status: 'active'` (o que cambia el rol de una fila activa) pasa por la compuerta de consentimiento: un menor sin consentimiento verificado → 409 `MR_CONSENT_NOT_VERIFIED`, siempre que el PATCH escriba `status: 'active'`, sea cual sea el estado leído antes de la transacción. Los demás PATCH (p. ej. terminar el rol) no la necesitan | ClubsService.updateRoleAssignment() | `src/clubs/clubs.controller.ts` |
| DELETE | `/api/v1/club-roles/:assignmentId` | JWT | Permisos: club_roles:revoke | Remover rol de miembro | ClubsService.removeRoleAssignment() | `src/clubs/clubs.controller.ts` |

### admin-coordination

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/coordination/local-fields/:localFieldId/zones` | JWT | Permisos: coordination:manage; Global: admin, super-admin, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Listar zonas de coordinación de un campo local | CoordinationService.listZones() | `src/coordination/coordination.controller.ts` |
| POST | `/api/v1/admin/coordination/local-fields/:localFieldId/zones` | JWT | Permisos: coordination:manage; Global: admin, super-admin, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Crear zona de coordinación en un campo local | CoordinationService.createZone() | `src/coordination/coordination.controller.ts` |
| PATCH | `/api/v1/admin/coordination/zones/:zoneId` | JWT | Permisos: coordination:manage; Global: admin, super-admin, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Actualizar zona de coordinación | CoordinationService.updateZone() | `src/coordination/coordination.controller.ts` |
| POST | `/api/v1/admin/coordination/zones/:zoneId/districts/:districtId` | JWT | Permisos: coordination:manage; Global: admin, super-admin, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Asignar un distrito a una zona de coordinación | CoordinationService.assignDistrictToZone() | `src/coordination/coordination.controller.ts` |
| DELETE | `/api/v1/admin/coordination/zones/:zoneId/districts/:districtId` | JWT | Permisos: coordination:manage; Global: admin, super-admin, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Quitar un distrito de una zona de coordinación | CoordinationService.removeDistrictFromZone() | `src/coordination/coordination.controller.ts` |
| GET | `/api/v1/admin/coordination/local-fields/:localFieldId/assignments` | JWT | Permisos: coordination:manage; Global: admin, super-admin, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Listar asignaciones de coordinadores | CoordinationService.listAssignments() | `src/coordination/coordination.controller.ts` |
| POST | `/api/v1/admin/coordination/local-fields/:localFieldId/assignments` | JWT | Permisos: coordination:manage; Global: admin, super-admin, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Crear asignación de coordinador | CoordinationService.createAssignment() | `src/coordination/coordination.controller.ts` |
| PATCH | `/api/v1/admin/coordination/assignments/:assignmentId` | JWT | Permisos: coordination:manage; Global: admin, super-admin, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Actualizar asignación de coordinador | CoordinationService.updateAssignment() | `src/coordination/coordination.controller.ts` |
| POST | `/api/v1/admin/coordination/local-fields/:localFieldId/backfill` | JWT | Permisos: coordination:manage; Global: admin, super-admin, director-lf, assistant-lf, director-union, assistant-union, director-dia, assistant-dia | Migrar coordinadores legacy (rol + local_field_id) a asignación GENERAL | CoordinationService.backfillLegacyAssignments() | `src/coordination/coordination.controller.ts` |

### coordination

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/coordination/me/scope` | JWT | - | Resolver el alcance efectivo de coordinación del usuario actual | CoordinationService.resolveCoordinatorScope() | `src/coordination/coordination.controller.ts` |
| GET | `/api/v1/coordination/me/consent-pending` | JWT | Permisos: consent:verify (global; debe venir de un rol de coordinador) | Fichas de consentimiento por verificar en todas las secciones del coordinador (mergeada en `development`, PR #534 de sacdia-backend; rama `feat/coordinator-pending-consents`) | CoordinatorConsentQueueService.listForCoordinator() | `src/coordination/coordination.controller.ts` |

### dashboard

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/dashboard/summary` | JWT | - | Resumen del dashboard del usuario autenticado. Clase actual: el enrollment `active` y `OPERATIONAL` más reciente por `enrollment_date`. Trae `current_class_name`, `current_class_id` e `investiture_status` de ese enrollment. El tab Clases de la app aplica la misma regla. **Sin datos de club** (backend `58669c63`): para un adolescente sin tutor verificado (`supervised_user` pendiente, o sin estado de supervisión) y para una edad desconocida la ruta sigue accesible (`self:read`), pero `club_name`, `club_type` y `user_role` son `null` y `upcoming_activities` es `[]` (la consulta de actividades ni se ejecuta; `DashboardService.getSummary` recibe `includeClubData: principalSeesClubData(req.user)`, `src/dashboard/dashboard.controller.ts:71`, `src/dashboard/dashboard.service.ts:133`), también con una asignación activa anterior al despliegue. Su progreso propio (clase actual, honores) sí se devuelve. Con tutor verificado, tutor actuando y dispositivo no cambia. | DashboardService.getSummary() | `src/dashboard/dashboard.controller.ts` |

### data-export

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/users/me/data-export` | JWT | - | Request a GDPR data export | DataExportService.requestExport() | `src/data-export/data-export.controller.ts` |
| GET | `/api/v1/users/me/data-exports` | JWT | - | List all data export requests for the current user | DataExportService.listExports() | `src/data-export/data-export.controller.ts` |
| GET | `/api/v1/users/me/data-exports/:exportId/download` | JWT | - | Get presigned download URL for a ready export | DataExportService.getDownloadUrl() | `src/data-export/data-export.controller.ts` |

El JSON exportado tiene `schema_version` `1.2.0` (antes `1.1.0` y `1.0.0`; cambios aditivos). La `1.1.0` añadió la clave `legal_acceptances`, después de `notification_preferences`: lista ordenada por `accepted_at` descendente de `{ document_type, document_version, accepted_at, method, ip_address, user_agent }` del propio usuario.

La `1.2.0` (perfiles familiares) añade la clave `family`, después de `legal_acceptances`: `{ dependent_profile, as_dependent, as_guardian }`. `dependent_profile` es `{ created_by_user_id, created_at, frozen_at, purge_after }` o `null`; `as_dependent` y `as_guardian` listan las tutorías donde el usuario es el menor o el tutor, con `{ guardianship_id, dependent_user_id, guardian_user_id, is_custodian, custodian_club_id, is_primary, consent_status, sworn_declaration_at, verification_method, verified_at, revoked_at, revoked_reason, created_at, relationship_type }` (`verification_method` puede ser `director_paper_form`, `coordinator_paper_form`, `guardian_invite`, `legacy_import` o `test_placeholder`). No incluye hashes de códigos, claves de archivos de evidencia ni nombre o teléfono de tutores externos.

### emergency-contacts

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/users/:userId/emergency-contacts` | JWT | - | Crear contacto de emergencia (máximo 5) | EmergencyContactsService.create() | `src/emergency-contacts/emergency-contacts.controller.ts` |
| GET | `/api/v1/users/:userId/emergency-contacts` | JWT | - | Listar contactos de emergencia del usuario | EmergencyContactsService.findAll() | `src/emergency-contacts/emergency-contacts.controller.ts` |
| GET | `/api/v1/users/:userId/emergency-contacts/:contactId` | JWT | - | Obtener un contacto específico | EmergencyContactsService.findOne() | `src/emergency-contacts/emergency-contacts.controller.ts` |
| PATCH | `/api/v1/users/:userId/emergency-contacts/:contactId` | JWT | - | Actualizar contacto de emergencia | EmergencyContactsService.update() | `src/emergency-contacts/emergency-contacts.controller.ts` |
| DELETE | `/api/v1/users/:userId/emergency-contacts/:contactId` | JWT | - | Eliminar contacto de emergencia (soft delete) | EmergencyContactsService.remove() | `src/emergency-contacts/emergency-contacts.controller.ts` |

### evidence-review

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/evidence-review/pending` | JWT | Global: admin, super-admin, coordinator; Permisos: validation:review | Listar evidencias pendientes de revisión. Cada ítem trae `section_name` (sección del programa de clase o especialidad) y `club_section_id`/`club_name`/`club_section_name` (sección de club del miembro, nullable) | EvidenceReviewService.getPending() | `src/evidence-review/evidence-review.controller.ts` |
| POST | `/api/v1/evidence-review/bulk-approve` | JWT | Global: admin, super-admin, coordinator; Permisos: validation:review | Aprobar múltiples evidencias en bloque | EvidenceReviewService.bulkApprove() | `src/evidence-review/evidence-review.controller.ts` |
| POST | `/api/v1/evidence-review/bulk-reject` | JWT | Global: admin, super-admin, coordinator; Permisos: validation:review | Rechazar múltiples evidencias en bloque | EvidenceReviewService.bulkReject() | `src/evidence-review/evidence-review.controller.ts` |
| GET | `/api/v1/evidence-review/:type/:id` | JWT | Global: admin, super-admin, coordinator; Permisos: validation:review | Obtener detalle de una evidencia con archivos adjuntos. Para `honor` agrega `instructor` (bloque sin foto ni correo; `null` si no declaró) y `completed_at` (fecha de finalización declarada) | EvidenceReviewService.getDetail() | `src/evidence-review/evidence-review.controller.ts` |
| POST | `/api/v1/evidence-review/:type/:id/approve` | JWT | Global: admin, super-admin, coordinator; Permisos: validation:review | Aprobar una evidencia | EvidenceReviewService.approve() | `src/evidence-review/evidence-review.controller.ts` |
| POST | `/api/v1/evidence-review/:type/:id/reject` | JWT | Global: admin, super-admin, coordinator; Permisos: validation:review | Rechazar una evidencia con motivo | EvidenceReviewService.reject() | `src/evidence-review/evidence-review.controller.ts` |
| GET | `/api/v1/evidence-review/:type/:id/history` | JWT | Global: admin, super-admin, coordinator; Permisos: validation:review | Historial de validación de una evidencia | EvidenceReviewService.getHistory() | `src/evidence-review/evidence-review.controller.ts` |

### finances

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/finances/categories` | JWT | Permisos: finances:read | Listar categorías financieras (Redis TTL 1h; epoch bump al mutar) | FinancesService.getCategories() | `src/finances/finances.controller.ts` |
| GET | `/api/v1/clubs/:clubId/finances/transactions` | JWT | Permisos: finances:read | Listar todas las transacciones del club (paginadas) | FinancesService.getAllTransactions() | `src/finances/finances.controller.ts` |
| GET | `/api/v1/clubs/:clubId/finances` | JWT | Permisos: finances:read | Listar movimientos financieros del club | FinancesService.findByClub() | `src/finances/finances.controller.ts` |
| GET | `/api/v1/clubs/:clubId/finances/summary` | JWT | Permisos: finances:read | Resumen financiero del club | FinancesService.getSummary() | `src/finances/finances.controller.ts` |
| POST | `/api/v1/clubs/:clubId/finances` | JWT | Permisos: finances:create; Club: director, deputy-director, treasurer, secretary-treasurer | Crear movimiento financiero | FinancesService.create() | `src/finances/finances.controller.ts` |
| GET | `/api/v1/finances/:financeId` | JWT | Permisos: finances:read | Obtener movimiento por ID | FinancesService.findOne() | `src/finances/finances.controller.ts` |
| POST | `/api/v1/finances/:financeId/evidences` | JWT | Permisos: finances:update | Subir foto de evidencia de un movimiento financiero | FinancesService.uploadEvidence() | `src/finances/finances.controller.ts` |
| PATCH | `/api/v1/finances/:financeId` | JWT | Permisos: finances:update | Actualizar movimiento | FinancesService.update() | `src/finances/finances.controller.ts` |
| DELETE | `/api/v1/finances/:financeId` | JWT | Permisos: finances:delete | Desactivar movimiento | FinancesService.remove() | `src/finances/finances.controller.ts` |

### guardianships

> Perfiles familiares (Fase 2), rama `feat/family-profiles`, Pendiente de merge (PR #530 de sacdia-backend). Ninguna ruta de `/guardianships/*` declara `@ActingScope`: mientras se actúa por un menor responden 403 `ACTING_FOR_SCOPE_DENIED`, y la app las llama sin `X-Acting-For`. La propiedad se comprueba en el servicio (`@SkipPermissions`), no con permisos RBAC. Respuestas con el envoltorio `{ "status": "success", "data": ... }`.

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/guardianships/relationship-types` | JWT | `@SkipPermissions` | Parentescos que un tutor puede declarar con el menor («yo soy su…»). Filas activas de `relationship_types` cuyo `name` está en la lista permitida, en el orden fijo de la lista (Padre, Madre, Tutor Legal, Abuelo, Abuela, Abuelo/a, Tío, Tía, Tío/a, Hermano/a Mayor, Otro; solo las filas que existan en el ambiente). 200 `{ status: "success", data: [{ relationship_type_id, name, description }] }`, la misma forma de ítem que `GET /api/v1/catalogs/relationship-types` (no localiza). Sin `@ActingScope`: se llama sin `X-Acting-For`. Ver «Parentesco del tutor» | GuardianshipsService.listGuardianRelationshipTypes() | `src/guardianships/guardianships.controller.ts` |
| GET | `/api/v1/guardianships/me/dependents` | JWT | `@SkipPermissions` | Listar los dependientes activos del tutor autenticado. Excluye congelados y purgados. Respuesta `{ dependents: DependentSummary[], limits: { max_dependents: 10, max_devices: 2 } }` (`max_devices` desde la Fase 3b) | GuardianshipsService.listForGuardian() | `src/guardianships/guardianships.controller.ts` |
| POST | `/api/v1/guardianships/me/dependents` | JWT | `@SkipPermissions`; throttle 10/hora | Registrar un menor sin cuenta (paso 0). En una transacción crea `users` (correo null, rol global `user`), `users_pr` en falso, `dependent_profiles`, la tutoría principal `pending` con `sworn_declaration_at` y las aceptaciones legales en nombre del menor. 201 con `DependentSummary` | GuardianshipsService.createDependent() | `src/guardianships/guardianships.controller.ts` |
| GET | `/api/v1/guardianships/me/dependents/:dependentId` | JWT | `@SkipPermissions` | Detalle de un dependiente con sus tutores (`DependentDetail`). Un dependiente ajeno, congelado o inexistente responde 404 `GUARDIANSHIP_NOT_FOUND` | GuardianshipsService.getDetailForGuardian() | `src/guardianships/guardianships.controller.ts` |
| POST | `/api/v1/guardianships/me/dependents/:dependentId/consent-evidence` | JWT | `@SkipPermissions`; throttle 20/hora | Subir la ficha de consentimiento firmada (foto o PDF). Multipart, campo `file`. 201 `{ evidence_id, content_type, size_bytes, uploaded_at }`. Solo la deja en espera del director: **nunca** verifica el consentimiento. Con el consentimiento ya verificado → 409 `GUARDIANSHIP_CONSENT_ALREADY_VERIFIED` (ver «Ficha de consentimiento firmada») | GuardianEvidenceService.uploadForGuardian() | `src/guardianships/guardianships.controller.ts` |
| GET | `/api/v1/guardianships/me/dependents/:dependentId/consent-evidence` | JWT | `@SkipPermissions` | URL firmada (15 min) de la ficha vigente. 200 `{ url, expires_in: 900, content_type, uploaded_at }`. Cada lectura se audita | GuardianEvidenceService.getForGuardian() | `src/guardianships/guardianships.controller.ts` |
| POST | `/api/v1/guardianships/me/dependents/:dependentId/link-codes` | JWT | `@SkipPermissions`; throttle 10/hora | Emitir un código para invitar a un segundo tutor (vigencia 72 h). Un código nuevo revoca los abiertos del mismo dependiente y propósito. Solo un tutor activo de ese dependiente; si no, 404 `GUARDIANSHIP_NOT_FOUND`. Con 4 tutores activos, 409 `GUARDIANSHIP_GUARDIAN_LIMIT_REACHED`. 201 `{ code, expires_at }` | LinkCodesService.issueSecondGuardianCode() | `src/guardianships/guardianships.controller.ts` |
| POST | `/api/v1/guardianships/link-codes/redeem` | JWT | `@SkipPermissions`; throttle 5 por 15 min y 20 por día | Canjear un código y quedar como tutor del menor. 201 con `DependentSummary`. Fase 3a: también canjea `teen_guardian_link` (código emitido por un adolescente; vínculo `pending`, no verificado) | LinkCodesService.redeem() | `src/guardianships/guardianships.controller.ts` |
| GET | `/api/v1/guardianships/me/deletion-impact` | JWT | `@SkipPermissions` | Qué pasaría con cada dependiente si el tutor elimina su cuenta. Respuesta `{ dependents: [{ user_id, display_name, outcome }] }`. Fase 3a: `outcome` puede ser también `pending_guardian` | GuardianshipLifecycleService.deletionImpact() | `src/guardianships/guardianships.controller.ts` |
| POST | `/api/v1/guardianships/:guardianshipId/revoke` | JWT | `@SkipPermissions` | Dejar una tutoría (`guardian_left`) o que el tutor principal quite a uno secundario (`removed_by_primary`). Responde 200. Fase 3a: el resultado `dependent_outcome` añade `pending_guardian` (adolescente con cuenta) | GuardianshipLifecycleService.revoke() | `src/guardianships/guardianships.controller.ts` |
| POST | `/api/v1/club-sections/:clubSectionId/dependents/:userId/claim-codes` | JWT | Permisos: club_members:approve · `@AuthorizationResource` club_section; throttle 10/hora | Un director emite un código de reclamo (vigencia 7 días) para devolver a una familia un menor bajo custodia del club. El menor debe tener una asignación activa o pendiente en esa sección y ningún tutor activo; si ya lo tiene, 409 `GUARDIANSHIP_ALREADY_GUARDIAN`; si no cumple, 404 `GUARDIANSHIP_NOT_FOUND`. 201 `{ code, expires_at }` | LinkCodesService.issueDirectorClaimCode() | `src/guardianships/dependent-claim-codes.controller.ts` |
| POST | `/api/v1/club-sections/:clubSectionId/dependents` | JWT | Permisos: dependents:create · `@AuthorizationResource` club_section; throttle 30/hora; bandera `FAMILY_DIRECTOR_CREATE_MINOR_ENABLED` | Fase 3c. Un director registra a un menor de 0 a 17 años bajo custodia del club: crea en una transacción el usuario sin cuenta ni correo, su perfil de dependiente, la custodia (consentimiento `pending`), una solicitud de membresía `pending` y las aceptaciones legales del menor hechas por el director. Cuerpo estricto (`name`, `paternal_last_name`, `maternal_last_name?`, `birthday`, `gender?`, `sworn_declaration: true`, versiones legales vigentes). 201 `{ dependent, guardianship, assignment }`. 404 `FAMILY_FEATURE_DISABLED` si la bandera está apagada; 422 `GUARDIANSHIP_DEPENDENT_AGE_OUT_OF_RANGE`; 500 `POST_REG_NO_ACTIVE_YEAR`. Detalle en «Registro de menores por un director y acceso familiar en el panel (Fase 3c)» | DirectorDependentsService.create() | `src/guardianships/director-dependents.controller.ts` |
| GET | `/api/v1/guardianships/me/dependents/:dependentId/supervised-login` | JWT | `@SkipPermissions` | Fase 3a. Elegibilidad para dar acceso propio al menor y, si existe, el acceso (con el nombre de usuario, solo para tutores verificados). Tutor verificado, como él mismo | SupervisedLoginsService.get() | `src/guardianships/guardianships.controller.ts` |
| POST | `/api/v1/guardianships/me/dependents/:dependentId/supervised-login` | JWT | `@SkipPermissions`; throttle 5/hora; bandera `FAMILY_TEEN_LOGIN_ENABLED` | Fase 3a. Habilitar acceso propio (`method` `handle` o `email`) a un menor de 13 a 17 años sin cuenta. 201 `{ supervised_login, devices_revoked }`. Termina el modo actuar por ese menor | SupervisedLoginsService.enable() | `src/guardianships/guardianships.controller.ts` |
| POST | `/api/v1/guardianships/me/dependents/:dependentId/supervised-login/disable` | JWT | `@SkipPermissions`; bandera `FAMILY_TEEN_LOGIN_ENABLED` | Fase 3a. Deshabilitar el acceso: sesiones borradas y 401 inmediato. 200 | SupervisedLoginsService.disable() | `src/guardianships/guardianships.controller.ts` |
| POST | `/api/v1/guardianships/me/dependents/:dependentId/supervised-login/reactivate` | JWT | `@SkipPermissions`; bandera `FAMILY_TEEN_LOGIN_ENABLED` | Fase 3a. Reactivar (con nombre de usuario exige una contraseña nueva). 200 | SupervisedLoginsService.reactivate() | `src/guardianships/guardianships.controller.ts` |
| POST | `/api/v1/guardianships/me/dependents/:dependentId/supervised-login/password` | JWT | `@SkipPermissions`; throttle 5/hora por dependiente; bandera `FAMILY_TEEN_LOGIN_ENABLED` | Fase 3a. Restablecer la contraseña (nombre de usuario: la fija el tutor; correo: correo estándar de restablecimiento). 200 `{ sessions_revoked }` | SupervisedLoginsService.resetPassword() | `src/guardianships/guardianships.controller.ts` |
| GET | `/api/v1/guardianships/me/dependents/:dependentId/summary` | JWT | `@SkipPermissions`; throttle 60/hora | Fase 3a. Resumen de progreso de clases, especialidades y asistencia del menor, sin salud. Tutor verificado, como él mismo | GuardianSummaryService.getSummary() | `src/guardianships/guardianships.controller.ts` |
| POST | `/api/v1/guardianships/me/dependents/:dependentId/devices/pairing-tokens` | JWT | `@SkipPermissions`; throttle 10/hora; bandera `FAMILY_LINKED_DEVICE_ENABLED` | Fase 3b. Crear el token de un solo uso (10 min) que el QR lleva para vincular el teléfono de un menor de 13 años. 201 `{ pairing_token, qr_payload, expires_at, expires_in }`. Solo un tutor verificado, como él mismo. Un token nuevo revoca los abiertos del mismo menor | DevicePairingService.issue() | `src/guardianships/guardianships.controller.ts` |
| GET | `/api/v1/guardianships/me/dependents/:dependentId/devices` | JWT | `@SkipPermissions`; no depende de la bandera | Fase 3b. Dispositivos del menor: activos y revocados en los últimos 30 días. 200 `{ devices, limits: { max_devices: 2 } }`. Cualquier tutor verificado | LinkedDevicesService.list() | `src/guardianships/guardianships.controller.ts` |
| POST | `/api/v1/guardianships/me/dependents/:dependentId/devices/:deviceId/revoke` | JWT | `@SkipPermissions`; throttle 30/hora; no depende de la bandera | Fase 3b. Desvincular un dispositivo (inmediato e idempotente). 200 `{ linked_device_id, revoked_at, revoked_reason }`. Cualquier tutor verificado; un dispositivo de otro menor → 404 `DEVICE_NOT_FOUND` | LinkedDevicesService.revoke() | `src/guardianships/guardianships.controller.ts` |

##### Parentesco del tutor

Lo que el tutor es del menor («yo soy su…») se restringe a una lista cerrada: **Padre, Madre, Tutor Legal, Abuelo, Abuela, Abuelo/a, Tío, Tía, Tío/a, Hermano/a Mayor y Otro**. La fija la constante `GUARDIAN_RELATIONSHIP_TYPE_NAMES` (`src/guardianships/guardianships.constants.ts:13-23`); su orden es el orden de `GET /api/v1/guardianships/relationship-types`. El resto del catálogo `relationship_types` (el de contactos de emergencia) no sirve para una tutoría.

- **Se compara por `name`, no por id.** `relationship_type_id` es un UUID generado al azar en cada ambiente (`prisma/schema.prisma:3727`), así que el mismo parentesco tiene un id distinto en desarrollo, staging y producción; `name` es único (`prisma/schema.prisma:3728`). Un id fijo en el código o en el cliente funcionaría en un ambiente y fallaría en otro. Los clientes **no filtran por UUID**: piden la lista al endpoint y envían el `relationship_type_id` que reciben.
- **Dónde se valida**: `GuardianshipsService.assertRelationshipType` (`guardianships.service.ts:135-153`) al crear un dependiente (`:197`, después de los pasos de versiones legales y de edad del tutor, antes de la fecha de nacimiento del menor) y al canjear un código de vinculación (`link-codes.service.ts:242`, antes de normalizar el código: un parentesco no permitido ni consume el código ni cuenta para el bloqueo por fuerza bruta).
- **Dos errores distintos, ambos 400**: `GUARDIANSHIP_RELATIONSHIP_TYPE_INVALID` si el id no existe o la fila está inactiva (`guardianships.service.ts:144-147`) y `GUARDIANSHIP_RELATIONSHIP_TYPE_NOT_ALLOWED` si la fila existe y está activa pero su `name` no está en la lista (`:149-153`). Se evalúan en ese orden.
- **Solo aparecen las filas que existan y estén activas en el ambiente** (`listGuardianRelationshipTypes`, `guardianships.service.ts:159-178`). Renombrar o desactivar una fila desde el CRUD de `admin/relationship-types` la saca de la lista. `prisma/seed.ts:15-56` siembra «Abuelo/a» y «Tío/a» en una sola fila cada uno; algunas bases tienen además las formas separadas. La lista acepta ambas formas, así que todo ambiente ofrece abuelos y tíos.

##### `POST /api/v1/guardianships/me/dependents`

Body (campos extra, como `email` o `access_mode`, → 400 por `forbidNonWhitelisted`; el modo de acceso siempre lo calcula el servidor):

```json
{
  "name": "Ana",
  "paternal_last_name": "Pérez",
  "maternal_last_name": "López",
  "birthday": "2017-04-02",
  "relationship_type_id": "uuid",
  "sworn_declaration": true,
  "accepted_terms_version": "1.0.0-store",
  "accepted_privacy_version": "1.0.0-store"
}
```

`maternal_last_name` es opcional; `birthday` es `YYYY-MM-DD`; `sworn_declaration` debe ser `true`. `relationship_type_id` sale de `GET /api/v1/guardianships/relationship-types` (ver «Parentesco del tutor»), no del catálogo completo `GET /api/v1/catalogs/relationship-types`.

Reglas, en este orden: versiones legales vigentes, tutor adulto con fecha de nacimiento, parentesco existente, activo y dentro de la lista permitida, fecha de nacimiento válida, no futura y con edad por debajo de `minor_self_login_min_age` del país del tutor (13 por defecto) y, **desde la Fase 3a, por debajo de la mayoría de edad del país** (un tutor puede registrar a un adolescente de 13 a 17 años como dependiente para después darle acceso propio), y límite de dependientes. El dependiente toma el `country_id` del tutor. Errores: 400 `LEGAL_VERSION_MISMATCH`; 400 `GUARDIANSHIP_RELATIONSHIP_TYPE_INVALID` (id desconocido o inactivo); 400 `GUARDIANSHIP_RELATIONSHIP_TYPE_NOT_ALLOWED` (parentesco fuera de la lista); 422 `GUARDIANSHIP_GUARDIAN_BIRTHDAY_REQUIRED`; 422 `GUARDIANSHIP_GUARDIAN_NOT_ADULT`; 422 `GUARDIANSHIP_DEPENDENT_AGE_OUT_OF_RANGE` (Fase 3a: edad igual o mayor que la mayoría de edad del país; antes, 13 años o más); 409 `GUARDIANSHIP_DEPENDENT_LIMIT_REACHED` (máximo 10 dependientes activos por tutor).

##### `DependentSummary`

```json
{
  "user_id": "uuid",
  "name": "Ana",
  "paternal_last_name": "Pérez",
  "maternal_last_name": "López",
  "birthday": "2017-04-02",
  "age": 9,
  "user_image": null,
  "access_mode": "guardian_managed",
  "post_register_complete": false,
  "frozen": false,
  "guardianship": {
    "guardianship_id": "uuid",
    "is_primary": true,
    "relationship_type": { "relationship_type_id": "uuid", "name": "Madre" },
    "consent_status": "pending",
    "verified_at": null,
    "evidence_uploaded": false
  },
  "club_membership": null
}
```

- `access_mode` es `guardian_managed` o, desde la Fase 3a, `supervised_login` (ver «Acceso propio del adolescente y resumen»).
- `consent_status` es `pending` o `verified` (nunca `revoked`: esas filas no se listan).
- `evidence_uploaded` es `true` si la tutoría **principal** del menor tiene una ficha firmada vigente; un tutor secundario ve el mismo valor que el principal. `consent_status` y `verified_at` son los de la fila del tutor que consulta.
- `club_membership` es `null` o `{ "assignment_id", "status": "pending|active|rejected|expired|cancelled", "club_section_id", "club_name", "club_type_name" }`.
- `DependentDetail` es `DependentSummary` más `guardians: [{ guardianship_id, user_id, display_name, relationship_type_name, is_primary, is_custodian, consent_status, is_me }]`. `user_id` es `null` en una custodia de club.

##### Códigos de vinculación

- Formato `XXXX-XXXX`: 8 caracteres Crockford base32. Al canjear se normaliza (mayúsculas, sin guiones ni espacios, `O` a `0`, `I` y `L` a `1`). El servidor guarda solo un hash HMAC-SHA256; el código en claro se devuelve una única vez al emitirlo.
- Un código sirve una sola vez. Un canje que falla después de consumirlo (ya es tutor, límite de tutores, inviter que ya salió) hace rollback y **no** consume el código.
- Body del canje: `{ "code": "7KQ4-M9TX", "relationship_type_id": "uuid", "sworn_declaration": true }`. Quien canjea debe ser adulto con fecha de nacimiento (mismos 422 que al crear). El `relationship_type_id` pasa por la misma lista permitida que al crear un dependiente (ver «Parentesco del tutor»).
- `second_guardian`: crea una tutoría no principal con `invited_by_guardianship_id`; queda `verified` (`guardian_invite`) si la del invitador está verificada, y `pending` si no.
- `director_claim`: el que canjea queda como tutor **principal** `pending`; la custodia del club y cualquier tutor externo heredado se revocan con `claimed`. La verificación anterior no se hereda.
- Protección contra fuerza bruta: 5 canjes por 15 minutos y 20 por día por usuario (429 de throttle). Además, 10 canjes con código no válido (`GUARDIANSHIP_LINK_CODE_INVALID`, incluidos los mal formados) en 24 h, con la ventana contada desde el primero, bloquean al usuario con 429 `GUARDIANSHIP_LINK_CODE_LOCKED`, sin mirar el código. El contador es **atómico** (un solo `EVAL` de Redis: `INCR` más `PEXPIRE` en el primer fallo; clave `linkcode:failures:v2:{userId}`), de modo que intentos en paralelo no esquivan el umbral; sin Redis (desarrollo y tests) se cuenta en memoria del proceso. Si Redis falla, el bloqueo no aplica y solo queda el throttle.
- Canje y salida del mismo menor se serializan con un candado por dependiente (`pg_advisory_xact_lock`, ver «Concurrencia» más abajo).
- Errores del canje: 400 `GUARDIANSHIP_LINK_CODE_INVALID` (cuerpo idéntico para desconocido, vencido, consumido, revocado o ya reclamado); 403 `GUARDIANSHIP_LINK_CODE_SELF_REDEEM` (quien canjea es quien emitió el código: aplica a `second_guardian` y a `director_claim`; se comprueba **antes** de consumir, así que el código sigue vigente para la persona a la que iba dirigido, y no cuenta para el bloqueo por fuerza bruta); 409 `GUARDIANSHIP_ALREADY_GUARDIAN`; 409 `GUARDIANSHIP_GUARDIAN_LIMIT_REACHED` (máximo 4 tutores activos por dependiente; también al emitir); 400 `GUARDIANSHIP_RELATIONSHIP_TYPE_INVALID` (id desconocido o inactivo); 400 `GUARDIANSHIP_RELATIONSHIP_TYPE_NOT_ALLOWED` (fuera de la lista; se comprueba antes de mirar el código, que no se consume); 429 `GUARDIANSHIP_LINK_CODE_LOCKED`.

##### `POST /api/v1/guardianships/:guardianshipId/revoke`

Body `{ "reason": "guardian_left" | "removed_by_primary" }`. Respuesta:

```json
{ "status": "success", "data": { "guardianship_id": "uuid", "consent_status": "revoked", "dependent_outcome": "other_guardian" } }
```

- `guardian_left`: solo el titular de esa fila. `removed_by_primary`: solo el tutor principal, sobre uno secundario. Fase 3a: `removed_by_dependent` lo usa el adolescente con `POST /users/me/guardian-links/:guardianshipId/revoke` (solo sobre un vínculo **pendiente** que él inició; no está en el cuerpo de esta ruta). Otra combinación → 403 `GUARDIANSHIP_REVOKE_FORBIDDEN`; tutoría inexistente, ya revocada, de custodia o de un menor ajeno → 404 `GUARDIANSHIP_NOT_FOUND`.
- `dependent_outcome` indica qué pasa con el menor cuando sale el último tutor activo: `other_guardian` (queda otro tutor; si hacía falta, el más antiguo se vuelve principal), `club_custody` (el menor tiene asignación `active` o `pending`: se crea una fila de custodia del club con el estado y método heredados y se avisa a los directores), `frozen` (se congela y se purga a los 90 días) o, desde la Fase 3a, `pending_guardian` (adolescente **con cuenta**: no se congela; vuelve al modo pendiente de tutor en su siguiente petición y el reloj de 90 días reinicia; ver «Plazo de 90 días sin tutor»). Un adolescente con cuenta y una asignación `active` o `pending` recibe además la custodia del club (`club_custody`) y sigue en modo pendiente.

##### `GET /api/v1/guardianships/me/deletion-impact`

```json
{ "status": "success", "data": { "dependents": [ { "user_id": "uuid", "display_name": "Ana Pérez", "outcome": "other_guardian" } ] } }
```

`outcome` usa los mismos valores que `dependent_outcome` (cuatro desde la Fase 3a). Es una vista previa de solo lectura de lo que hará la eliminación de cuenta.

##### Concurrencia

Revocar, salir (también por cierre de cuenta), canjear un código, subir una ficha y verificar el consentimiento de un mismo menor toman un `pg_advisory_xact_lock` por dependiente (`guardianships:dependent:{id}`) y releen las filas ya con el candado. Así dos tutores que salen a la vez dejan exactamente **un** destino para el menor (otro tutor, custodia o congelado) y nunca un menor huérfano. Un menor compartido por dos tutores que se eliminan a la vez no produce interbloqueo: las filas se bloquean en orden ascendente por id.

##### Ficha de consentimiento firmada

Contrato común a los tres lectores (tutor, director, admin). Respuestas con envoltorio `{ status: 'success', data }`.

- **Archivo**: multipart, campo `file`; JPEG, PNG, WebP o PDF, máximo 10 MB, con comprobación de bytes mágicos. HEIC se rechaza: la app lo convierte a JPEG antes de subir. Sin archivo → 400 `FILE_REQUIRED`; tipo no permitido o HEIC → 400 `FILE_TYPE_INVALID`; más de 10 MB → 400 `FILE_TOO_LARGE` (o 413 de multer, según el límite que salte primero). Subir: 20 por hora y usuario (429 de throttle).
- **A quién pertenece**: a la fila de consentimiento del menor, es decir, su **tutoría principal activa** (de persona o de custodia del club). Cualquier tutor activo de un menor visible puede subir y leer por los endpoints del tutor; la ficha queda en la fila principal y `uploaded_by_user_id` guarda al que subió de verdad. `evidence_uploaded` en `DependentSummary` sale de la fila principal, así que un tutor secundario ve el mismo valor.
- **Historial**: una subida nueva marca la anterior como `superseded_at` y **conserva** su objeto en R2. Hay una sola ficha vigente por tutoría.
- **Evidencia bloqueada tras verificar**: si el menor ya tiene una tutoría real (no de prueba) `verified`, **cualquier** subida, del tutor o del director, responde 409 `GUARDIANSHIP_CONSENT_ALREADY_VERIFIED` y la ficha verificada sigue siendo la vigente (reemplazarla exige revocar y crear una tutoría nueva). La comprobación se hace antes de guardar y se repite dentro de la transacción con el candado del menor, así una verificación que gana la carrera mantiene su ficha. El archivo se valida antes (400 `FILE_REQUIRED` / `FILE_TYPE_INVALID`).
- **Lectura**: solo con URL firmada de 900 s (`expires_in: 900`) del bucket privado; no existe URL pública. Cada lectura se audita **antes** de devolver la URL (`entity_type = guardianship_consent_evidence`, `action = read`, `changes.via` = `guardian`, `director` o `admin`) y cada subida también (`action = uploaded`).
- **Bucket compartido en desarrollo**: `R2_BUCKET_GUARDIANSHIP_EVIDENCE` puede apuntar a un bucket privado existente. Los objetos quedan aislados bajo el prefijo `guardianships/consent` (clave `{prefijo}/{guardianshipId}/{uuid}.{ext}`) y solo se sirven con URL firmada de 900 s; el bucket no debe tener dominio personalizado ni `r2.dev` (condición de infraestructura que el código no comprueba). No se documentan nombres de bucket ni valores de entorno.
- **Fail closed**: el servicio comprueba `R2_BUCKET_GUARDIANSHIP_EVIDENCE` antes de tocar la base o el almacenamiento. Sin bucket, todas las operaciones de ficha responden 503 `GUARDIANSHIP_EVIDENCE_UNAVAILABLE` y el resto de la API funciona (la app arranca: la variable es opcional en Joi). `R2_PUBLIC_URL_GUARDIANSHIP_EVIDENCE` también es opcional porque el bucket es privado.
- **Errores**: 404 `GUARDIANSHIP_NOT_FOUND` (menor ajeno, congelado, sin tutoría principal; un extraño nunca recibe 403); 404 `GUARDIANSHIP_EVIDENCE_NOT_FOUND` (leer sin ficha vigente); 409 `GUARDIANSHIP_CONSENT_ALREADY_VERIFIED` (subir con el consentimiento ya verificado); 503 `GUARDIANSHIP_EVIDENCE_UNAVAILABLE`.

La verificación por el director y la lectura del director están en la sección `membership-requests`; la lectura de admin, en `admin-users`.

##### Congelación y purga

Un dependiente `frozen` no se lista, no se puede actuar por él y no recibe pushes. A los 90 días, el cron `dependent-profiles-purge` (`20 4 * * *` UTC, lotes de 100) lo anonimiza y **borra** sus datos personales (decisión A9: «borrar» es borrar, no solo ocultar). Detalle por tabla en `docs/database/SCHEMA-REFERENCE.md`, sección «Perfiles familiares». Anonimiza y borra en una transacción y, **después de confirmarla**, borra los objetos de R2 (fichas de consentimiento, foto de perfil, evidencias de clases y especialidades, certificados y documentos de especialidades) con mejor esfuerzo: si R2 falla, la purga no se revierte ni se reintenta y queda el registro `dependent_purge_storage_cleanup_failed` con el bucket y las claves (commit `9533895d`, pendiente de merge). En una tutoría de titular externo, el nombre queda como `'Tutor'` y no en NULL. La variable `R2_BUCKET_GUARDIANSHIP_EVIDENCE` apunta al bucket privado `GUARDIANSHIP_EVIDENCE` (opcional `R2_KEY_PREFIX_GUARDIANSHIP_EVIDENCE`, por defecto `guardianships/consent`). Las variables son opcionales al arrancar y solo son obligatorias al usar el bucket.

##### Acceso propio del adolescente y resumen (Fase 3a)

> Perfiles familiares, Fase 3a, rama `feat/family-profiles-phase3`, Pendiente de merge (PR #531 de sacdia-backend). Las seis rutas se llaman **como el tutor, sin `X-Acting-For`** (`skipActingFor`); mientras se actúa responden 403 `ACTING_FOR_SCOPE_DENIED`. Las cinco de `supervised-login` exigen la bandera `FAMILY_TEEN_LOGIN_ENABLED` (apagada → 404 `FAMILY_FEATURE_DISABLED`).

**Quién puede**: un tutor activo, no custodia, no `is_test_data` y con la tutoría **`verified`** (`GuardianPowersPolicy.assertVerifiedGuardian`). Un vínculo `pending` (por ejemplo, el de un código que el adolescente le dio a un desconocido) no tiene poderes de control. La respuesta depende de la ruta (todo sale de `GuardianPowersPolicy.assertVerifiedGuardian`, `src/guardianships/guardian-powers.policy.ts`):

| Ruta | Tutor con vínculo `pending` |
| --- | --- |
| `GET .../supervised-login` | **200** `{ eligible: false, ineligible_reason: "consent_not_verified", supervised_login: null }`; sin nombre de usuario ni correo (`SupervisedLoginsService.get`, `src/guardianships/supervised-logins.service.ts:198-212`) |
| `POST .../supervised-login`, `.../disable`, `.../reactivate`, `.../password` | **403** `GUARDIANSHIP_CONSENT_NOT_VERIFIED` |
| `GET .../summary` | **409** `GUARDIANSHIP_CONSENT_NOT_VERIFIED` (`{ pending: 'conflict' }`, `src/guardianships/guardian-summary.service.ts:86-89`) |

Con la bandera apagada, las cinco rutas de `supervised-login` responden 404 `FAMILY_FEATURE_DISABLED` antes de mirar al tutor. Un extraño o el tutor de otro menor → 404 `GUARDIANSHIP_NOT_FOUND`. Cualquier tutor verificado puede (no solo el principal); los demás tutores verificados reciben un aviso de cada acción.

**`GET .../dependents/:dependentId/supervised-login`**

```json
{
  "eligible": true,
  "ineligible_reason": null,
  "supervised_login": null
}
```

`ineligible_reason`: `age_below_min`, `age_over_majority`, `consent_not_verified`, `feature_disabled` o `custodian_only`. `supervised_login`, cuando existe: `{ method, login_handle, email, origin: "self_registered"|"guardian_enabled", enabled_at, disabled_at, disabled_reason, password_set_by }`. Solo un tutor verificado ve el `login_handle`.

**`POST .../dependents/:dependentId/supervised-login`** (habilitar; 5 por hora)

```json
{ "method": "handle", "password": "..." }
```

```json
{ "method": "email", "email": "ana@x.com", "password": "..." }
```

- **Precondiciones**: el menor no tiene cuenta, está activo y no congelado, tiene edad desde `minor_self_login_min_age` y menor que la mayoría de edad (si no → 422 `SUPERVISED_LOGIN_NOT_ELIGIBLE`, `details.reason`), y no tiene ya un acceso habilitado (409 `SUPERVISED_LOGIN_ALREADY_ENABLED`; un acceso deshabilitado se reactiva, no se vuelve a crear).
- **Una transacción**, con el candado por dependiente: crea la fila `account` de credencial con la contraseña del tutor (misma política y mismo bcrypt de costo 12 que el registro; política no cumplida → 422 `SUPERVISED_LOGIN_PASSWORD_INVALID` y no se crea nada), la fila `supervised_logins` (`origin = guardian_enabled`, `password_set_by = guardian`, `enabled_by_*`, nombre de usuario generado si `method = handle`; con `method = email` fija `users.email`, y si ya existe → 409 `SUPERVISED_LOGIN_EMAIL_UNAVAILABLE`), revoca los dispositivos vinculados del menor mediante el puerto `LINKED_DEVICE_REVOKER` (desde la Fase 3b ligado a `LinkedDevicesService`, motivo `teen_login_enabled`; ver «Dispositivo vinculado de menores de 13 años (Fase 3b)») y audita `supervised_login.enabled`. La contraseña nunca se devuelve, ni se registra ni se audita.
- **201**: `{ "supervised_login": { ... incluye "login_handle" ... }, "devices_revoked": 0 }`.
- **Efectos tras confirmar**: sube el `epoch`; el tutor que actuaba por el menor recibe 403 `ACTING_FOR_FORBIDDEN` en su siguiente petición (la app sale del modo actuar); los otros tutores verificados reciben `family:security`. Mientras el acceso esté habilitado, el tutor ya no actúa por el menor y los pushes del club dejan de copiarse al tutor.

**`POST .../supervised-login/disable`** (`{ "reason"?: "..." }`) → 200 `{ "supervised_login": { ..., "disabled_at", "disabled_reason": "guardian" } }`. Borra **todas** las sesiones del menor, manda sus tokens a la lista negra (28 800 s) y sube el `epoch`: con cualquier token anterior, la siguiente petición es 401 `AUTH_SUPERVISED_ACCESS_REVOKED`; el inicio de sesión con credenciales correctas da 403 `AUTH_SUPERVISED_LOGIN_DISABLED`. Solo mientras el menor sea menor de edad. Si el acceso lo habilitó el tutor (`origin = guardian_enabled`), el tutor puede **volver a actuar** por el menor; si el adolescente se registró solo (`self_registered`), no. 404 `SUPERVISED_LOGIN_NOT_FOUND` si no hay acceso.

**`POST .../supervised-login/reactivate`**: con `method = handle` exige una contraseña **nueva** definida por el tutor (`{ "password": "..." }`; la anterior deja de servir); con `method = email` no lleva cuerpo. Limpia `disabled_*`, sube el `epoch` y no restaura sesiones. Menor de edad solamente (si no, 422 `SUPERVISED_LOGIN_NOT_ELIGIBLE`). 200 `{ "supervised_login": { ... } }`.

**`POST .../supervised-login/password`** (5 por hora por dependiente): con `method = handle`, `{ "password": "..." }` es la contraseña nueva; con `method = email`, sin cuerpo: se revocan las sesiones y se envía al correo del adolescente el correo estándar de restablecimiento (el tutor nunca conoce ni fija esa contraseña). En ambos casos se borran todas las sesiones, se sube el `epoch`, se avisa a los otros tutores y el adolescente lo ve al iniciar sesión en su bandeja (sin push, para no entrar en bucle con un dispositivo bloqueado). 200 `{ "sessions_revoked": 2 }`.

**`GET .../dependents/:dependentId/summary`** (60 por hora; se audita `guardianship.summary_viewed`)

```json
{
  "dependent": { "user_id": "uuid", "name": "Ana", "age": 14, "access_mode": "supervised_login" },
  "classes": [ { "class_id": 3, "name": "Amigo", "progress_percent": 62, "sections_completed": 5, "sections_total": 8 } ],
  "honors": { "completed": 3, "in_progress": 2 },
  "attendance": { "from": "2026-01-01", "to": "2026-10-19", "activities_total": 12, "activities_attended": 9 },
  "dues": null,
  "generated_at": "2026-10-19T22:00:00.000Z"
}
```

- Lista cerrada de campos (lo comprueba una prueba de allowlist recursiva): **nunca** incluye salud (alergias, enfermedades, medicinas, contactos de emergencia), evidencias o imágenes, notas del consejero, datos de otros miembros, contacto, ubicación ni mensajes. `dues` es `null` (no hay módulo de cuotas por miembro).
- Funciona para cualquier modo de acceso del menor. Errores: 409 `GUARDIANSHIP_CONSENT_NOT_VERIFIED` (vínculo pendiente; **no** es 403 como en los poderes de control); 404 `GUARDIANSHIP_NOT_FOUND` (extraño, tutor de otro menor o menor con edad igual o mayor que la mayoría de edad); 403 `ACTING_FOR_SCOPE_DENIED` actuando.
- Transparencia: `GET /users/me/supervision.summary_visible_to_guardians` es `true` y la app le explica al adolescente qué ve su tutor.

**`DependentSummary` (cambios)**: `access_mode` es `guardian_managed` o `supervised_login` (lo calcula el servidor); se agregan `supervised_login` (`null` o `{ method, login_handle, enabled_at, disabled_at }`), `linked_devices_count` (dispositivos activos del menor; siempre `0` en la Fase 3a, real desde la Fase 3b: `GuardianshipsService.buildSummaries`, `src/guardianships/guardianships.service.ts`) y `age_milestone_reached` (`true` si tiene la edad mínima de cuenta y aún no tiene acceso).

**Código `teen_guardian_link`** (`POST /api/v1/guardianships/link-codes/redeem`, mismo cuerpo y mismo bloqueo por fuerza bruta): lo emite el **adolescente** (`POST /users/me/guardian-link-codes`). Al canjearlo, en una transacción con el candado del adolescente: solo si el adolescente está activo, tiene cuenta, es menor de edad, no tiene un tutor de persona activo y no está congelado (si no, 400 `GUARDIANSHIP_LINK_CODE_INVALID`); quien canjea debe ser adulto con fecha de nacimiento (422 `GUARDIANSHIP_GUARDIAN_NOT_ADULT` / `GUARDIANSHIP_GUARDIAN_BIRTHDAY_REQUIRED`, **el código no se consume**); no puede canjearlo el propio adolescente (403 `GUARDIANSHIP_LINK_CODE_SELF_REDEEM`). Crea el perfil `dependent_profiles` del adolescente (`created_by_user_id` = el adolescente) y una tutoría **no custodia, principal, `pending`, `invited_by` NULL** que **nunca se verifica sola**; detiene el reloj de 90 días y avisa al adolescente. 201 con `DependentSummary` (`access_mode: "supervised_login"`). Cuenta para el tope de 10 dependientes (409 `GUARDIANSHIP_DEPENDENT_LIMIT_REACHED`). Hasta que un director verifique el consentimiento, quien canjeó solo puede subir la ficha y ver el estado. Los códigos `second_guardian` también se pueden canjear para adolescentes con cuenta; `director_claim` sigue siendo solo de custodia.

### supervision (adolescente con cuenta supervisada)

> Perfiles familiares, Fase 3a, rama `feat/family-profiles-phase3`, Pendiente de merge (PR #531 de sacdia-backend). Rutas que llama el **propio adolescente** (principal `supervised_user`). Para un adulto: `GET /users/me/supervision` responde **200** con `status: null` (sin datos), y `POST /users/me/guardian-link-codes` responde **403** `PRINCIPAL_SCOPE_DENIED` con `kind: "user"` (`LinkCodesService.issueTeenGuardianLink`, `src/guardianships/link-codes.service.ts:196-204`). Actuando por un menor o con un dispositivo, el scope no está y responden `ACTING_FOR_SCOPE_DENIED` o `PRINCIPAL_SCOPE_DENIED`. Respuestas con `{ "status": "success", "data": ... }`.

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/users/me/guardian-link-codes` | JWT | Scope `guardian_link:issue`; `@SkipPermissions`; throttle 10/hora | El adolescente emite un código para que un adulto se vincule como su tutor (propósito `teen_guardian_link`, vigencia **72 h**, formato `XXXX-XXXX`, hash HMAC en la base, en claro una sola vez). Un código nuevo revoca los abiertos. Solo un adolescente sin tutor de persona activo; con menos de 4 tutores activos (409 `GUARDIANSHIP_GUARDIAN_LIMIT_REACHED`; ya vinculado → 409 `GUARDIANSHIP_ALREADY_GUARDIAN`). Un adulto, una edad desconocida o un adolescente activo no puede (403 `PRINCIPAL_SCOPE_DENIED`); un adolescente congelado no recibe código (404 `GUARDIANSHIP_NOT_FOUND`). 201 `{ code, expires_at }`. No requiere la bandera | LinkCodesService.issueTeenGuardianLinkCode() | `src/guardianships/teen-link-codes.controller.ts` |
| GET | `/api/v1/users/me/supervision` | JWT | Scope `self:read`; `@SkipPermissions` | Estado de supervisión del adolescente: `{ status: "pending_guardian"\|"active"\|null, pending_since, guardians: [{ guardianship_id, consent_status: "pending"\|"verified", display_name, relationship_type_name }], open_link_code: null \| { expires_at }, summary_visible_to_guardians: true, days_left: number \| null }`. `guardianship_id` y `consent_status` permiten a la app ofrecer «Quitar» solo en los vínculos `pending`; `days_left` son los días enteros que faltan para los 90 (`null` con el reloj detenido, es decir con un tutor vinculado, incluso pendiente). Un adulto recibe `status: null` y listas vacías. Sin datos de contacto | SupervisionService.getStatus() | `src/guardianships/teen-link-codes.controller.ts` |
| POST | `/api/v1/users/me/guardian-links/:guardianshipId/revoke` | JWT | Scope `guardian_link:issue`; `@SkipPermissions` | El adolescente quita un vínculo **pendiente** que él inició (motivo `removed_by_dependent`). Reinicia el reloj de 90 días. Solo aplica a vínculos que el propio adolescente inició con su código (`invited_by_guardianship_id IS NULL`, `GuardianshipLifecycleService.revokePendingLinkByDependent`, `src/guardianships/guardianship-lifecycle.service.ts:477`, backend `4ae0b245`). Un vínculo ya verificado, de otro adolescente, o un segundo tutor `pending` invitado por un tutor (`second_guardian`) → 404 `GUARDIANSHIP_NOT_FOUND` (lo ve un adolescente en modo pendiente). Un adolescente **activo** (con tutor verificado) recibe 403 `PRINCIPAL_SCOPE_DENIED`, porque `guardian_link:issue` solo está en `TEEN_PENDING_SCOPES`: no puede quitar un vínculo pendiente de un segundo tutor (limitación conocida, hallazgo S2 de la verificación 3a) | GuardianshipLifecycleService.revoke() | `src/guardianships/teen-link-codes.controller.ts` |

Contrato del vínculo y del reloj: «Cuentas supervisadas de 13 a 17 años (Fase 3a)» y «Acceso propio del adolescente y resumen» (en `guardianships`).

### health

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/health` | Public | - | Public ping — returns ok if API is reachable | - | `src/health/health.controller.ts` |
| GET | `/api/v1/health/details` | JWT | Global: admin, super-admin | Detailed health status (admin only) | - | `src/health/health.controller.ts` |

### honors

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/honors/:honorId/requirements` | Optional JWT | - | Obtener requisitos de un honor | HonorRequirementsService.getRequirements() | `src/honors/honor-requirements.controller.ts` |
| GET | `/api/v1/honors` | Optional JWT | - | Listar honores. Filtros `categoryId`, `clubTypeId`, `skillLevel`, `page`, `limit` y `search` (nombre y traducciones; de 2 a 60 caracteres tras recortar, si no 400; no se cachea) | HonorsService.findAll() | `src/honors/honors.controller.ts` |
| GET | `/api/v1/honors/categories` | Optional JWT | - | Listar categorías de honores (Redis TTL 1h; epoch bump al mutar categorías/honores) | HonorsService.getCategories() | `src/honors/honors.controller.ts` |
| GET | `/api/v1/honors/grouped-by-category` | Optional JWT | - | Listar honores agrupados por categoría (Redis TTL 1h; epoch bump al mutar honores/categorías/tipos de club) | HonorsService.getGroupedByCategory() | `src/honors/honors.controller.ts` |
| GET | `/api/v1/honors/:honorId` | Optional JWT | - | Obtener honor por ID | HonorsService.findOne() | `src/honors/honors.controller.ts` |

### user-honors

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/users/:userId/honors/:honorId/requirements/progress` | JWT | Permisos: user_honors:read | Obtener progreso de requisitos del usuario en un honor | HonorRequirementsService.getUserProgress() | `src/honors/honor-requirements.controller.ts` |
| PATCH | `/api/v1/users/:userId/honors/:honorId/requirements/progress/batch` | JWT | Permisos: user_honors:submit | Actualizar progreso de múltiples requisitos | HonorRequirementsService.bulkUpdateProgress() | `src/honors/honor-requirements.controller.ts` |
| PATCH | `/api/v1/users/:userId/honors/:honorId/requirements/:requirementId/progress` | JWT | Permisos: user_honors:submit | Actualizar progreso de un requisito individual | HonorRequirementsService.updateProgress() | `src/honors/honor-requirements.controller.ts` |
| POST | `/api/v1/users/:userId/honors/:honorId/requirements/:requirementId/evidence/upload` | JWT | Permisos: user_honors:create | Subir evidencia (imagen o archivo) para un requisito | HonorRequirementsService.uploadEvidence() | `src/honors/honor-requirements.controller.ts` |
| POST | `/api/v1/users/:userId/honors/:honorId/requirements/:requirementId/evidence/link` | JWT | Permisos: user_honors:create | Agregar enlace como evidencia para un requisito | HonorRequirementsService.addEvidenceLink() | `src/honors/honor-requirements.controller.ts` |
| GET | `/api/v1/users/:userId/honors/:honorId/requirements/:requirementId/evidence` | JWT | Permisos: user_honors:read | Listar evidencias de un requisito | HonorRequirementsService.getEvidences() | `src/honors/honor-requirements.controller.ts` |
| DELETE | `/api/v1/users/:userId/honors/:honorId/requirements/:requirementId/evidence/:evidenceId` | JWT | Permisos: user_honors:delete | Eliminar una evidencia de un requisito | HonorRequirementsService.deleteEvidence() | `src/honors/honor-requirements.controller.ts` |
| GET | `/api/v1/users/:userId/honors` | JWT | Permisos: user_honors:read | Obtener honores del usuario. Cada fila trae `completed_at`, el bloque `instructor` (sin foto en el listado) e `instructor_proposal` (última propuesta `PENDING` o `REJECTED` de una especialidad `APPROVED`; `null` si no hay) | HonorsService.getUserHonors() | `src/honors/honors.controller.ts` |
| GET | `/api/v1/users/:userId/honors/stats` | JWT | Permisos: user_honors:read | Obtener estadísticas de honores del usuario | HonorsService.getUserHonorStats() | `src/honors/honors.controller.ts` |
| POST | `/api/v1/users/:userId/honors` | JWT | Permisos: user_honors:create | Registrar honor con datos iniciales. Acepta `completedAt`, `instructorUserId` o `instructorName`. Sobre una fila existente `APPROVED` o `PENDING_REVIEW` responde 400 `VALIDATION_HONOR_INVALID_STATUS` y no escribe | HonorsService.createUserHonor() | `src/honors/honors.controller.ts` |
| POST | `/api/v1/users/:userId/honors/bulk` | JWT | Permisos: user_honors:create | Registrar honores de usuario de forma masiva. Mismos campos y mismo bloqueo por ítem; si un ítem es `APPROVED` o `PENDING_REVIEW` falla todo el lote sin escrituras parciales | HonorsService.createUserHonorsBulk() | `src/honors/honors.controller.ts` |
| POST | `/api/v1/users/:userId/honors/:honorId/files` | JWT | Permisos: user_honors:create | Subir evidencias del honor | HonorsService.uploadUserHonorFiles() | `src/honors/honors.controller.ts` |
| POST | `/api/v1/users/:userId/honors/:honorId` | JWT | Permisos: user_honors:create | Iniciar un honor. Sobre una fila inactiva `APPROVED` o `PENDING_REVIEW` solo restaura `active` (no reinicia estado, archivos ni fechas); sobre otra fila inactiva la reinicia y borra `instructor_*` y `completed_at` | HonorsService.startHonor() | `src/honors/honors.controller.ts` |
| PATCH | `/api/v1/users/:userId/honors/:honorId` | JWT | Permisos: user_honors:submit | Actualizar progreso de honor. Acepta `completedAt` (`yyyy-mm-dd`, de 1960-01-01 a hoy; `null` lo borra), `instructorUserId` o `instructorName` (como máximo uno; `null` lo borra). Solo en `IN_PROGRESS` o `REJECTED`; en `APPROVED` o `PENDING_REVIEW` responde 400 `VALIDATION_HONOR_INVALID_STATUS` | HonorsService.updateUserHonor() | `src/honors/honors.controller.ts` |
| DELETE | `/api/v1/users/:userId/honors/:honorId` | JWT | Permisos: user_honors:delete | Abandonar honor (desactiva `active`). En `APPROVED` o `PENDING_REVIEW` responde 400 `VALIDATION_HONOR_INVALID_STATUS` | HonorsService.abandonHonor() | `src/honors/honors.controller.ts` |
| POST | `/api/v1/users/:userId/honors/:honorId/instructor-proposal` | JWT | Permisos: user_honors:submit; solo el dueño (otro actor: 403 `HONOR_INSTRUCTOR_PROPOSAL_FORBIDDEN`); throttle 10/min | Proponer el instructor de una especialidad `APPROVED` activa. Body `{ instructorUserId? , instructorName? }`, exactamente uno. Crea una propuesta `PENDING` (201); si había otra pendiente, la pasa a `WITHDRAWN`. No cambia la especialidad hasta que el Campo Local apruebe | HonorInstructorProposalsService.propose() | `src/honors/honors.controller.ts` |
| DELETE | `/api/v1/users/:userId/honors/:honorId/instructor-proposal` | JWT | Permisos: user_honors:submit; solo el dueño | Retirar la propuesta `PENDING` (pasa a `WITHDRAWN`). 404 `HONOR_INSTRUCTOR_PROPOSAL_NOT_FOUND` si no hay una pendiente | HonorInstructorProposalsService.withdraw() | `src/honors/honors.controller.ts` |

### user-master-honors

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/users/:userId/master-honors` | JWT | Permisos: user_honors:read | Obtener maestrías del usuario | MasterHonorsService.getUserMasterHonors() | `src/honors/master-honors.controller.ts` |
| GET | `/api/v1/users/:userId/master-honors/roadmap` | JWT | Permisos: user_honors:read | Obtener roadmap de maestrías del usuario | MasterHonorsService.getUserMasterHonorRoadmap() | `src/honors/master-honors.controller.ts` |
| GET | `/api/v1/users/:userId/master-honors/:masterHonorId` | JWT | Permisos: user_honors:read | Obtener detalle de una maestría del usuario | MasterHonorsService.getUserMasterHonorDetail() | `src/honors/master-honors.controller.ts` |

### instructors

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/instructor-candidates?q=` | JWT | `@SkipPermissions`; throttle 30/min | Buscar instructores de especialidad del mismo Campo Local de quien llama: usuarios activos, aprobados y mayores de edad, sin incluir a quien llama. Busca por nombre y apellidos, nunca por correo (mínimo 3 caracteres en total y 2 por palabra; si no se cumple, o el llamante no tiene Campo Local, responde `[]`). Máximo 10 resultados `{ user_id, display_name, photo_url }` (`photo_url` firmada de vida corta o `null`) | InstructorsService.searchCandidates() | `src/instructors/instructor-candidates.controller.ts` |

### legal

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/legal/current` | Public | `@SkipPermissions`; throttle 30/min | Versiones vigentes y URLs públicas de los Términos y el Aviso de Privacidad. Siempre en el orden `terms`, `privacy` | LegalService.getCurrent() | `src/legal/legal.controller.ts` |
| GET | `/api/v1/users/me/legal-acceptance` | JWT | `@SkipPermissions`; throttle 30/min | Estado de aceptación del usuario autenticado para las versiones vigentes | LegalService.getStatus() | `src/legal/legal-acceptance.controller.ts` |
| POST | `/api/v1/users/me/legal-acceptance` | JWT | `@SkipPermissions`; throttle 10/min | Aceptar las versiones vigentes. Idempotente: responde 200 y no agrega filas si ya estaban aceptadas. Versión distinta de la vigente → 400 `LEGAL_VERSION_MISMATCH` sin escribir. Actuando por un menor (scope `legal:accept`) las filas se guardan para el menor con `accepted_by_user_id` = el tutor | LegalService.accept() | `src/legal/legal-acceptance.controller.ts` |

> **Fase 3a (borrador, Pendiente de merge (PR #531 de sacdia-backend))**: la constante `CURRENT_LEGAL_DOCUMENTS` (`src/legal/legal-documents.constants.ts`) ya está en `2.0.0-family` para `terms` y `privacy` en la rama, en su propio commit `86d3717a` (revertible solo; el comentario del archivo la marca como BORRADOR). Se despliega **solo después** de que el texto se apruebe y se publique en las URLs; promover a `main` está bloqueado hasta la aprobación legal (ver `docs/legal/README.md`). Con el cambio, todo usuario queda pendiente hasta aceptar la versión nueva (compuerta dura en la app): un adulto por sí mismo, un adolescente por sí mismo (también en modo pendiente; `accepted_by_user_id` null) y un tutor por cada dependiente mientras actúa (`accepted_by_user_id` = el tutor; que el tutor haya aceptado para sí no desbloquea a sus dependientes). Una versión vieja → 400 `LEGAL_VERSION_MISMATCH`. Repetir una aceptación no duplica filas (`skipDuplicates`). Los ejemplos de abajo muestran `1.0.0-store`, la versión vigente hasta entonces.

Sin token, los dos endpoints `users/me/legal-acceptance` responden 401 por el guard JWT global. El módulo `src/legal/` es la fuente de las versiones: `src/legal/legal-documents.constants.ts` (ver `docs/legal/README.md`).

##### `GET /api/v1/legal/current`

```json
{
  "status": "success",
  "data": {
    "documents": [
      { "document_type": "terms", "version": "1.0.0-store", "url": "https://sacdia.com/terms" },
      { "document_type": "privacy", "version": "1.0.0-store", "url": "https://sacdia.com/privacy" }
    ]
  }
}
```

##### Bloque de estado legal (`LegalStatus`)

Es idéntico en `data` de `GET` y `POST /api/v1/users/me/legal-acceptance`, y en `data.legal` de `GET /api/v1/auth/me`:

```json
{
  "requires_acceptance": true,
  "documents": [
    { "document_type": "terms", "version": "1.0.0-store", "url": "https://sacdia.com/terms", "accepted": false, "accepted_at": null },
    { "document_type": "privacy", "version": "1.0.0-store", "url": "https://sacdia.com/privacy", "accepted": true, "accepted_at": "2026-10-15T22:01:00.000Z" }
  ]
}
```

- Un documento está pendiente (`accepted: false`) si NO existe fila para `(usuario, document_type, versión vigente)`. No importa qué otras versiones haya aceptado antes.
- `requires_acceptance` es `true` si algún documento está pendiente.
- `accepted_at` es ISO 8601 de la aceptación de la versión vigente, o `null`.

##### `POST /api/v1/users/me/legal-acceptance`

Body (ambos obligatorios, se recortan, máximo 32; campos extra → 400 por `forbidNonWhitelisted`):

```json
{ "terms_version": "1.0.0-store", "privacy_version": "1.0.0-store" }
```

Respuesta 200: `{ "status": "success", "data": <LegalStatus> }`. Guarda las filas con `method = acceptance_gate`, IP y user agent de la petición, y `accepted_by_user_id` null. La identidad sale del JWT (`sub`), nunca del body.

Errores: 400 `LEGAL_VERSION_MISMATCH` (`{ "status": "error", "statusCode": 400, "code": "LEGAL_VERSION_MISMATCH", "message": "<traducido>", "timestamp": "...", "path": "..." }`) si alguna versión no es la vigente; 400 de validación genérica si falta, está vacía o no es string; 429 por throttle.

### insurance

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId/members/insurance` | JWT | Permisos: insurance:read | Listar seguros de miembros por sección | InsuranceService.listMembersInsurance() | `src/insurance/insurance.controller.ts` |
| GET | `/api/v1/insurance/expiring` | JWT | Global: admin, coordinator (alias: zone/general + director-lf/assistant-lf; LF recorta a local_field); SkipPermissions | Listar seguros próximos a vencer | InsuranceService.getExpiringInsurances() | `src/insurance/insurance.controller.ts` |
| GET | `/api/v1/users/:memberId/insurance` | JWT | Permisos: insurance:read | Obtener seguro activo del miembro | InsuranceService.getMemberInsurance() | `src/insurance/insurance.controller.ts` |
| POST | `/api/v1/users/:memberId/insurance` | JWT | Permisos: insurance:create | Crear seguro para un miembro (legacy directo) | InsuranceService.createInsurance() | `src/insurance/insurance.controller.ts` |
| PATCH | `/api/v1/insurance/:insuranceId` | JWT | Permisos: insurance:update | Actualizar seguro | InsuranceService.updateInsurance() | `src/insurance/insurance.controller.ts` |
| GET | `/api/v1/insurance/products` | JWT | Permisos: insurance:configure | Listar productos de seguro del Campo Local activo | InsuranceConfigService.listProducts() | `src/insurance/insurance.controller.ts` |
| POST | `/api/v1/insurance/products` | JWT | Permisos: insurance:configure | Crear producto de seguro para el Campo Local activo | InsuranceConfigService.createProduct() | `src/insurance/insurance.controller.ts` |
| PATCH | `/api/v1/insurance/products/:productId` | JWT | Permisos: insurance:configure | Actualizar producto de seguro del Campo Local activo | InsuranceConfigService.updateProduct() | `src/insurance/insurance.controller.ts` |
| GET | `/api/v1/insurance/cycles` | JWT | Permisos: insurance:configure | Listar ciclos de seguro del Campo Local activo | InsuranceConfigService.listCycles() | `src/insurance/insurance.controller.ts` |
| POST | `/api/v1/insurance/cycles` | JWT | Permisos: insurance:configure | Crear ciclo de seguro para el Campo Local activo | InsuranceConfigService.createCycle() | `src/insurance/insurance.controller.ts` |
| PATCH | `/api/v1/insurance/cycles/:cycleConfigId` | JWT | Permisos: insurance:configure | Actualizar ciclo de seguro del Campo Local activo | InsuranceConfigService.updateCycle() | `src/insurance/insurance.controller.ts` |
| POST | `/api/v1/club-sections/:sectionId/insurance/purchases` | JWT | Permisos: insurance:create | Registrar compra de cupos (qty, legacy a reemplazar por payment-orders) | InsurancePurchasesService.submit() | `src/insurance/insurance-purchases.controller.ts` |
| GET | `/api/v1/club-sections/:sectionId/insurance/purchases` | JWT | Permisos: insurance:read | Listar compras de cupos de la sección | InsurancePurchasesService.listForSection() | `src/insurance/insurance-purchases.controller.ts` |
| GET | `/api/v1/insurance/purchases/:purchaseId` | JWT | Permisos: insurance:read | Detalle de compra de cupos | InsurancePurchasesService.getById() | `src/insurance/insurance-purchases.controller.ts` |
| GET | `/api/v1/insurance/purchases/:purchaseId/proof` | JWT | Permisos: insurance:read | URL firmada del comprobante de compra | InsurancePurchasesService.getById() + signed proof | `src/insurance/insurance-purchases.controller.ts` |
| POST | `/api/v1/insurance/purchases/:purchaseId/confirm` | JWT | Permisos: insurance:review | Confirmar compra y materializar slots AVAILABLE | InsurancePurchasesService.confirm() | `src/insurance/insurance-purchases.controller.ts` |
| POST | `/api/v1/insurance/purchases/:purchaseId/reject` | JWT | Permisos: insurance:review | Rechazar compra de cupos | InsurancePurchasesService.reject() | `src/insurance/insurance-purchases.controller.ts` |
| POST | `/api/v1/insurance/purchases/:purchaseId/reverse` | JWT | Permisos: insurance:review | Revertir compra confirmada | InsurancePurchasesService.reverse() | `src/insurance/insurance-purchases.controller.ts` |

### field-payment-orders

Órdenes de pago territoriales (seguros + camporees). Flag `field_payment_orders_v1` por Campo Local; expiración default 15 días (`field_payment_orders.expiry_days`).

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/insurance/payment-orders` | JWT | Permisos: field-payment-orders:create | Emitir orden grupal de seguro (ciclo + beneficiarios nombrados) | FieldPaymentOrdersService.createInsuranceOrder() | `src/field-payment-orders/field-payment-orders.controller.ts` |
| POST | `/api/v1/camporees/:camporeeId/payment-orders` | JWT | Permisos: field-payment-orders:create | Emitir orden de inscripción a camporee local | FieldPaymentOrdersService.createCamporeeOrder() | `src/field-payment-orders/field-payment-orders.controller.ts` |
| POST | `/api/v1/union-camporees/:camporeeId/payment-orders` | JWT | Permisos: field-payment-orders:create | Emitir orden de inscripción a camporee de unión (v1.1: cobra el Campo Local del emisor) | FieldPaymentOrdersService.createUnionCamporeeOrder() | `src/field-payment-orders/field-payment-orders.controller.ts` |
| GET | `/api/v1/payment-orders` | JWT | Permisos: field-payment-orders:read | Listar órdenes del alcance del actor (filtros purpose/status/camporee_id/union_camporee_id) | FieldPaymentOrdersService.list() | `src/field-payment-orders/field-payment-orders.controller.ts` |
| GET | `/api/v1/payment-orders/review-queue` | JWT | Permisos: field-payment-orders:review | Bandeja de revisión LF (PROOF_SUBMITTED) | FieldPaymentOrdersService.reviewQueue() | `src/field-payment-orders/field-payment-orders.controller.ts` |
| GET | `/api/v1/payment-orders/context` | JWT | Permisos: field-payment-orders:read | Disponibilidad del flujo + ciclos de seguro para la sección activa (app) | FieldPaymentOrdersService.getIssuerContext() | `src/field-payment-orders/field-payment-orders.controller.ts` |
| GET | `/api/v1/payment-orders/config` | JWT | Permisos: field-payment-orders:configure | Instrucciones de pago del Campo Local (banco/caja) | FieldPaymentOrderConfigsService.get() | `src/field-payment-orders/field-payment-orders.controller.ts` |
| POST | `/api/v1/payment-orders/config` | JWT | Permisos: field-payment-orders:configure | Crear/actualizar instrucciones de pago del Campo Local | FieldPaymentOrderConfigsService.upsert() | `src/field-payment-orders/field-payment-orders.controller.ts` |
| GET | `/api/v1/payment-orders/:orderId` | JWT | Permisos: field-payment-orders:read | Detalle de orden con líneas y comprobantes | FieldPaymentOrdersService.get() | `src/field-payment-orders/field-payment-orders.controller.ts` |
| GET | `/api/v1/payment-orders/:orderId/document` | JWT | Permisos: field-payment-orders:read | PDF imprimible de la orden (PDFKit) | FieldPaymentOrdersService.getDocument() | `src/field-payment-orders/field-payment-orders.controller.ts` |
| GET | `/api/v1/payment-orders/:orderId/proof` | JWT | Permisos: field-payment-orders:read | URL firmada del comprobante (TTL 15 min) | FieldPaymentOrdersService.getProofDownload() | `src/field-payment-orders/field-payment-orders.controller.ts` |
| POST | `/api/v1/payment-orders/:orderId/proof` | JWT | Permisos: field-payment-orders:upload-proof | Subir comprobante (multipart, PDF/JPG/PNG ≤10 MB, magic bytes) | FieldPaymentOrdersService.uploadProof() | `src/field-payment-orders/field-payment-orders.controller.ts` |
| POST | `/api/v1/payment-orders/:orderId/cancel` | JWT | Permisos: field-payment-orders:cancel | Cancelar orden ISSUED/PROOF_REJECTED | FieldPaymentOrdersService.cancel() | `src/field-payment-orders/field-payment-orders.controller.ts` |
| POST | `/api/v1/payment-orders/:orderId/approve` | JWT | Permisos: field-payment-orders:review | Aprobar comprobante y materializar fulfillment (maker-checker) | FieldPaymentOrdersService.approve() | `src/field-payment-orders/field-payment-orders.controller.ts` |
| POST | `/api/v1/payment-orders/:orderId/reject` | JWT | Permisos: field-payment-orders:review | Rechazar comprobante con motivo obligatorio | FieldPaymentOrdersService.reject() | `src/field-payment-orders/field-payment-orders.controller.ts` |
| POST | `/api/v1/insurance/reassignments` | JWT | Permisos: field-payment-orders:create | Solicitar reasignación de cobertura activa (mismo club) | InsuranceReassignmentsService.create() | `src/field-payment-orders/insurance-reassignments.controller.ts` |
| GET | `/api/v1/insurance/reassignments` | JWT | Permisos: field-payment-orders:read | Listar solicitudes de reasignación del alcance | InsuranceReassignmentsService.list() | `src/field-payment-orders/insurance-reassignments.controller.ts` |
| POST | `/api/v1/insurance/reassignments/:requestId/approve` | JWT | Permisos: field-payment-orders:review | Aprobar reasignación (mueve assignment + slot movement) | InsuranceReassignmentsService.approve() | `src/field-payment-orders/insurance-reassignments.controller.ts` |
| POST | `/api/v1/insurance/reassignments/:requestId/reject` | JWT | Permisos: field-payment-orders:review | Rechazar reasignación con motivo | InsuranceReassignmentsService.reject() | `src/field-payment-orders/insurance-reassignments.controller.ts` |

### camporee order products

> Pedidos de mercancía (`src/camporee-orders`, migración `20260824190000_camporee_orders`). Distintos de `/payment-orders` (inscripción/seguro).

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/camporee-order-products` | JWT | Permisos: camporee-orders:catalog-manage | Crear producto de la biblioteca territorial | CatalogService.create() | `src/camporee-orders/catalog.controller.ts` |
| GET | `/api/v1/camporee-order-products` | JWT | Permisos: camporee-orders:read | Listar productos visibles en la cascada territorial | CatalogService.list() | `src/camporee-orders/catalog.controller.ts` |
| GET | `/api/v1/camporee-order-products/:productId` | JWT | Permisos: camporee-orders:read | Obtener un producto de la biblioteca | CatalogService.getById() | `src/camporee-orders/catalog.controller.ts` |
| PATCH | `/api/v1/camporee-order-products/:productId` | JWT | Permisos: camporee-orders:catalog-manage | Actualizar un producto (soft-delete con active=false) | CatalogService.update() | `src/camporee-orders/catalog.controller.ts` |
| POST | `/api/v1/camporee-order-products/:productId/options` | JWT | Permisos: camporee-orders:catalog-manage | Agregar una opción de talla al producto | CatalogService.addOption() | `src/camporee-orders/catalog.controller.ts` |
| PATCH | `/api/v1/camporee-order-product-options/:optionId` | JWT | Permisos: camporee-orders:catalog-manage | Actualizar una opción (label inmutable si hay líneas) | CatalogService.updateOption() | `src/camporee-orders/catalog.controller.ts` |

### camporee order offerings

No existe `GET .../orders-settings`. Settings en `GET` de camporee y en este GET de ofertas. Escritura: `PATCH .../orders-settings`.

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| PATCH | `/api/v1/camporees/:camporeeId/orders-settings` | JWT | Permisos: camporee-orders:offering-configure | Actualizar ventana de pedidos del camporee local | OfferingsService.updateSettings() | `src/camporee-orders/offerings.controller.ts` |
| PATCH | `/api/v1/union-camporees/:camporeeId/orders-settings` | JWT | Permisos: camporee-orders:offering-configure | Actualizar ventana de pedidos del camporee de unión | OfferingsService.updateSettings() | `src/camporee-orders/offerings.controller.ts` |
| GET | `/api/v1/camporees/:camporeeId/order-offerings` | JWT | Permisos: camporee-orders:read | Listar ofertas y settings de pedidos del camporee local | OfferingsService.getOfferings() | `src/camporee-orders/offerings.controller.ts` |
| GET | `/api/v1/union-camporees/:camporeeId/order-offerings` | JWT | Permisos: camporee-orders:read | Listar ofertas y settings de pedidos del camporee de unión | OfferingsService.getOfferings() | `src/camporee-orders/offerings.controller.ts` |
| PUT | `/api/v1/camporees/:camporeeId/order-offerings` | JWT | Permisos: camporee-orders:offering-configure | Reemplazar de forma idempotente las ofertas del camporee local | OfferingsService.replaceOfferings() | `src/camporee-orders/offerings.controller.ts` |
| PUT | `/api/v1/union-camporees/:camporeeId/order-offerings` | JWT | Permisos: camporee-orders:offering-configure | Reemplazar de forma idempotente las ofertas del camporee de unión | OfferingsService.replaceOfferings() | `src/camporee-orders/offerings.controller.ts` |

### camporee orders

Folio `PED{yyyy}{####}`. Máquina: `ISSUED` → `PROOF_SUBMITTED` → `PAID` → `DELIVERED` (más rechazo, cancelación, expiración y excepción `authorize-without-proof`). El cliente no envía montos.

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/camporees/:camporeeId/orders` | JWT | Permisos: camporee-orders:create | Emitir un pedido de sección para un camporee local | CamporeeOrdersService.create() | `src/camporee-orders/camporee-orders.controller.ts` |
| POST | `/api/v1/union-camporees/:camporeeId/orders` | JWT | Permisos: camporee-orders:create | Emitir un pedido de sección para un camporee de unión | CamporeeOrdersService.create() | `src/camporee-orders/camporee-orders.controller.ts` |
| GET | `/api/v1/camporee-orders` | JWT | Permisos: camporee-orders:read | Listar pedidos visibles (no colapsa suplementarios) | CamporeeOrdersService.list() | `src/camporee-orders/camporee-orders.controller.ts` |
| GET | `/api/v1/camporee-orders/review-queue` | JWT | Permisos: camporee-orders:review | Bandeja de revisión de pedidos con comprobante (Campo Local) | CamporeeOrdersService.reviewQueue() | `src/camporee-orders/camporee-orders.controller.ts` |
| GET | `/api/v1/camporee-orders/:orderId` | JWT | Permisos: camporee-orders:read | Detalle de pedido con líneas nominadas, summary y snapshot de pago | CamporeeOrdersService.get() | `src/camporee-orders/camporee-orders.controller.ts` |
| GET | `/api/v1/camporee-orders/:orderId/document` | JWT | Permisos: camporee-orders:read | Descargar PDF imprimible del pedido | CamporeeOrdersService.getDocument() | `src/camporee-orders/camporee-orders.controller.ts` |
| GET | `/api/v1/camporee-orders/:orderId/proof` | JWT | Permisos: camporee-orders:read | URL firmada del comprobante vigente (TTL 900 s) | CamporeeOrdersService.getProofDownload() | `src/camporee-orders/camporee-orders.controller.ts` |
| POST | `/api/v1/camporee-orders/:orderId/proof` | JWT | Permisos: camporee-orders:upload-proof | Subir comprobante de pago (multipart, campo file) | CamporeeOrdersService.uploadProof() | `src/camporee-orders/camporee-orders.controller.ts` |
| POST | `/api/v1/camporee-orders/:orderId/cancel` | JWT | Permisos: camporee-orders:create **o** camporee-orders:review | Cancelar un pedido emitido o con comprobante rechazado | CamporeeOrdersService.cancel() | `src/camporee-orders/camporee-orders.controller.ts` |
| POST | `/api/v1/camporee-orders/:orderId/approve` | JWT | Permisos: camporee-orders:review | Aprobar comprobante y marcar el pedido como pagado | CamporeeOrdersService.approve() | `src/camporee-orders/camporee-orders.controller.ts` |
| POST | `/api/v1/camporee-orders/:orderId/reject` | JWT | Permisos: camporee-orders:review | Rechazar comprobante (permite re-subida) | CamporeeOrdersService.reject() | `src/camporee-orders/camporee-orders.controller.ts` |
| POST | `/api/v1/camporee-orders/:orderId/authorize-without-proof` | JWT | Permisos: camporee-orders:authorize-without-proof | Marcar pagado sin comprobante (excepción de caja del Campo Local) | CamporeeOrdersService.authorizeWithoutProof() | `src/camporee-orders/camporee-orders.controller.ts` |
| POST | `/api/v1/camporee-orders/:orderId/deliver` | JWT | Permisos: camporee-orders:deliver | Marcar el bulto entregado del Campo Local a la sección | CamporeeOrdersService.deliverToSection() | `src/camporee-orders/camporee-orders.controller.ts` |
| POST | `/api/v1/camporee-orders/:orderId/lines/:lineId/deliver-to-member` | JWT | Permisos: camporee-orders:distribute | Marcar una línea nominada como entregada al miembro (solo director de la sección) | CamporeeOrdersService.deliverToMember() | `src/camporee-orders/camporee-orders.controller.ts` |

### payment obligations

Read model de solo lectura. No fusiona folios ni muta `field_payment_orders`, `material_orders`, `camporee_orders` o `camporee_supply_payment_docs`.

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/payment-obligations/pending` | JWT | Permisos (any): camporee-orders:read, camporee-supplies:read, field-payment-orders:read, materiales:read | Listar obligaciones pendientes (inscripción, materiales, pedidos e insumos) sin fusionar folios | PaymentObligationsService.listPending() | `src/payment-obligations/payment-obligations.controller.ts` |

### camporee supplies

> Insumos de sección (`src/camporee-supplies`, migración `20260826120000_camporee_supplies`). Distintos de `/camporee-orders` (mercancía PED) y `/payment-orders` (inscripción). Folio `INS{yyyy}{####}`.

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/camporees/:camporeeId/supply-catalog` | JWT | Permisos: camporee-supplies:read | Catálogo de slots y productos del camporee local | CamporeeSupplyConfigService.getCatalog() | `src/camporee-supplies/config.controller.ts` |
| GET | `/api/v1/union-camporees/:camporeeId/supply-catalog` | JWT | Permisos: camporee-supplies:read | Catálogo de slots y productos del camporee de unión | CamporeeSupplyConfigService.getCatalog() | `src/camporee-supplies/config.controller.ts` |
| PATCH | `/api/v1/camporees/:camporeeId/supply-settings` | JWT | Permisos: camporee-supplies:configure | Actualizar corte de edición de insumos (local) | CamporeeSupplyConfigService.updateSettings() | `src/camporee-supplies/config.controller.ts` |
| PATCH | `/api/v1/union-camporees/:camporeeId/supply-settings` | JWT | Permisos: camporee-supplies:configure | Actualizar corte de edición de insumos (unión) | CamporeeSupplyConfigService.updateSettings() | `src/camporee-supplies/config.controller.ts` |
| POST | `/api/v1/camporees/:camporeeId/supply-slots` | JWT | Permisos: camporee-supplies:configure | Crear horario de entrega (local) | CamporeeSupplyConfigService.createSlot() | `src/camporee-supplies/config.controller.ts` |
| POST | `/api/v1/union-camporees/:camporeeId/supply-slots` | JWT | Permisos: camporee-supplies:configure | Crear horario de entrega (unión) | CamporeeSupplyConfigService.createSlot() | `src/camporee-supplies/config.controller.ts` |
| PATCH | `/api/v1/camporees/:camporeeId/supply-slots/:slotId` | JWT | Permisos: camporee-supplies:configure | Actualizar horario de entrega (local) | CamporeeSupplyConfigService.updateSlot() | `src/camporee-supplies/config.controller.ts` |
| PATCH | `/api/v1/union-camporees/:camporeeId/supply-slots/:slotId` | JWT | Permisos: camporee-supplies:configure | Actualizar horario de entrega (unión) | CamporeeSupplyConfigService.updateSlot() | `src/camporee-supplies/config.controller.ts` |
| POST | `/api/v1/camporees/:camporeeId/supply-products` | JWT | Permisos: camporee-supplies:configure | Crear producto de insumos (local) | CamporeeSupplyConfigService.createProduct() | `src/camporee-supplies/config.controller.ts` |
| POST | `/api/v1/union-camporees/:camporeeId/supply-products` | JWT | Permisos: camporee-supplies:configure | Crear producto de insumos (unión) | CamporeeSupplyConfigService.createProduct() | `src/camporee-supplies/config.controller.ts` |
| PATCH | `/api/v1/camporees/:camporeeId/supply-products/:productId` | JWT | Permisos: camporee-supplies:configure | Actualizar producto; precio bloqueado si hay plan SUBMITTED | CamporeeSupplyConfigService.updateProduct() | `src/camporee-supplies/config.controller.ts` |
| PATCH | `/api/v1/union-camporees/:camporeeId/supply-products/:productId` | JWT | Permisos: camporee-supplies:configure | Actualizar producto de unión | CamporeeSupplyConfigService.updateProduct() | `src/camporee-supplies/config.controller.ts` |
| GET | `/api/v1/camporees/:camporeeId/supply-plan` | JWT | Permisos: camporee-supplies:plan | Plan de insumos de la sección activa (local) | CamporeeSupplyPlansService.getOwnPlan() | `src/camporee-supplies/plans.controller.ts` |
| GET | `/api/v1/union-camporees/:camporeeId/supply-plan` | JWT | Permisos: camporee-supplies:plan | Plan de insumos de la sección activa (unión) | CamporeeSupplyPlansService.getOwnPlan() | `src/camporee-supplies/plans.controller.ts` |
| PUT | `/api/v1/camporees/:camporeeId/supply-plan` | JWT | Permisos: camporee-supplies:plan | Reemplazar líneas del plan en DRAFT (local) | CamporeeSupplyPlansService.replaceDraft() | `src/camporee-supplies/plans.controller.ts` |
| PUT | `/api/v1/union-camporees/:camporeeId/supply-plan` | JWT | Permisos: camporee-supplies:plan | Reemplazar líneas del plan en DRAFT (unión) | CamporeeSupplyPlansService.replaceDraft() | `src/camporee-supplies/plans.controller.ts` |
| POST | `/api/v1/camporees/:camporeeId/supply-plan/submit` | JWT | Permisos: camporee-supplies:plan | Enviar plan y emitir folio PRINCIPAL INS (local) | CamporeeSupplyPlansService.submit() | `src/camporee-supplies/plans.controller.ts` |
| POST | `/api/v1/union-camporees/:camporeeId/supply-plan/submit` | JWT | Permisos: camporee-supplies:plan | Enviar plan y emitir folio PRINCIPAL INS (unión) | CamporeeSupplyPlansService.submit() | `src/camporee-supplies/plans.controller.ts` |
| PATCH | `/api/v1/camporees/:camporeeId/supply-plan/lines` | JWT | Permisos (any): camporee-supplies:plan, review-pay, configure | Ajustar línea SUBMITTED; CHARGE/REFUND; bypass freeze con motivo | CamporeeSupplyPlansService.adjustLine() | `src/camporee-supplies/plans.controller.ts` |
| PATCH | `/api/v1/union-camporees/:camporeeId/supply-plan/lines` | JWT | Permisos (any): camporee-supplies:plan, review-pay, configure | Ajustar línea SUBMITTED (unión) | CamporeeSupplyPlansService.adjustLine() | `src/camporee-supplies/plans.controller.ts` |
| GET | `/api/v1/camporees/:camporeeId/supply-plans` | JWT | Permisos: camporee-supplies:read | Listar planes de insumos del camporee local | CamporeeSupplyPlansService.listPlans() | `src/camporee-supplies/plans.controller.ts` |
| GET | `/api/v1/union-camporees/:camporeeId/supply-plans` | JWT | Permisos: camporee-supplies:read | Listar planes de insumos del camporee de unión | CamporeeSupplyPlansService.listPlans() | `src/camporee-supplies/plans.controller.ts` |
| POST | `/api/v1/camporees/:camporeeId/supply-lines/:lineId/deliveries` | JWT | Permisos: camporee-supplies:deliver | Entrega parcial a la sección (local) | CamporeeSupplyPlansService.deliver() | `src/camporee-supplies/plans.controller.ts` |
| POST | `/api/v1/union-camporees/:camporeeId/supply-lines/:lineId/deliveries` | JWT | Permisos: camporee-supplies:deliver | Entrega parcial a la sección (unión) | CamporeeSupplyPlansService.deliver() | `src/camporee-supplies/plans.controller.ts` |
| GET | `/api/v1/camporees/:camporeeId/supply-reports/kitchen` | JWT | Permisos: camporee-supplies:read | Demanda de cocina (opcional `?date=`) | CamporeeSupplyPlansService.kitchenReport() | `src/camporee-supplies/plans.controller.ts` |
| GET | `/api/v1/union-camporees/:camporeeId/supply-reports/kitchen` | JWT | Permisos: camporee-supplies:read | Demanda de cocina (unión) | CamporeeSupplyPlansService.kitchenReport() | `src/camporee-supplies/plans.controller.ts` |
| GET | `/api/v1/camporees/:camporeeId/supply-reports/cash` | JWT | Permisos: camporee-supplies:read | Totales de caja por sección (local) | CamporeeSupplyPlansService.cashReport() | `src/camporee-supplies/plans.controller.ts` |
| GET | `/api/v1/union-camporees/:camporeeId/supply-reports/cash` | JWT | Permisos: camporee-supplies:read | Totales de caja por sección (unión) | CamporeeSupplyPlansService.cashReport() | `src/camporee-supplies/plans.controller.ts` |
| POST | `/api/v1/camporee-supply-payments/:paymentId/mark-paid` | JWT | Permisos: camporee-supplies:review-pay | Marcar folio INS (principal, cargo o devolución) como pagado | CamporeeSupplyPlansService.markPaid() | `src/camporee-supplies/plans.controller.ts` |

### inventory

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/inventory/clubs/:clubId/inventory` | JWT | Permisos: inventory:read | Listar items del inventario de una instancia de club | InventoryService.findAllByClub() | `src/inventory/inventory.controller.ts` |
| GET | `/api/v1/inventory/inventory/:id` | JWT | Permisos: inventory:read | Obtener detalles de un item del inventario | InventoryService.findOne() | `src/inventory/inventory.controller.ts` |
| GET | `/api/v1/inventory/inventory/:inventoryId/history` | JWT | Permisos: inventory:read | Obtener historial de cambios de un item del inventario | InventoryService.getInventoryHistory() | `src/inventory/inventory.controller.ts` |
| POST | `/api/v1/inventory/clubs/:clubId/inventory` | JWT | Permisos: inventory:create | Agregar nuevo item al inventario | InventoryService.create() | `src/inventory/inventory.controller.ts` |
| PATCH | `/api/v1/inventory/inventory/:id` | JWT | Permisos: inventory:update | Actualizar un item del inventario | InventoryService.update() | `src/inventory/inventory.controller.ts` |
| POST | `/api/v1/inventory/inventory/:id/evidences` | JWT | Permisos: inventory:update | Subir foto de evidencia de un item de inventario | InventoryService.uploadEvidence() | `src/inventory/inventory.controller.ts` |
| DELETE | `/api/v1/inventory/inventory/:id` | JWT | Permisos: inventory:delete | Eliminar un item del inventario | InventoryService.delete() | `src/inventory/inventory.controller.ts` |
| GET | `/api/v1/inventory/catalogs/inventory-categories` | JWT | Permisos: inventory:read | Listar categorías de inventario (Redis TTL 1h) | InventoryService.findAllCategories() | `src/inventory/inventory.controller.ts` |

### investiture

Fase 8 (ejecutada en código el 2026-10-09; mergeada en `development` con backend #468 y #469): la vía club → coordinación → campo está apagada y desplegada en el backend vivo. Las 17 rutas marcadas «Retirada» responden HTTP 410 con el código estable `INVESTITURE_LEGACY_PIPELINE_RETIRED`, sin exigir permisos ni roles (solo el JWT global): ningún actor recibe un 403 que oculte el 410. Incluye las lecturas `GET /investiture/pending` y `GET /admin/investiture/config*`. Siguen vivos el historial (`GET /investiture/enrollments/:enrollmentId/history` y su alias), `expire-overdue` y el desbloqueo de abajo. Los 17 handlers están en `LegacyInvestitureRetiredController`; no leen cuerpo ni parámetros. El `message` sale del catálogo de errores del idioma de la petición; una app o un panel viejos que no mandan `Accept-Language` lo reciben en español. El inventario histórico y el tratamiento de cada expediente están en `docs/features/validacion-investiduras.md`, sección «Fase 8 — apagado». Los permisos `investiture:submit`, `investiture:validate`, `investiture:mark_invested` e `investiture_config:*` quedaron inertes con la fase 8 y se eliminaron del catálogo y de las concesiones con la migración `20261013110000_remove_retired_investiture_permissions` (backend #488, aplicada el 2026-10-13). `investiture:read` sigue en uso: lo exigen las dos lecturas del historial. Las migraciones `20261008120000` y `20261009120000` están aplicadas en las tres ramas de Neon y el `dry_run` del desbloqueo en `development` dio 0 candidatos; no se corrió `dry_run: false` en ningún entorno.

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/investiture/enrollments/:enrollmentId/submit` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Enviar a la validación anterior. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.submit() | `src/investiture/legacy-investiture-retired.controller.ts` |
| POST | `/api/v1/investiture/enrollments/:enrollmentId/club-approve` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Aprobación del club. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.clubApprove() | `src/investiture/legacy-investiture-retired.controller.ts` |
| POST | `/api/v1/investiture/enrollments/:enrollmentId/coordinator-approve` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Aprobación de coordinación. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.coordinatorApprove() | `src/investiture/legacy-investiture-retired.controller.ts` |
| POST | `/api/v1/investiture/enrollments/:enrollmentId/field-approve` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Aprobación del Campo. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.fieldApprove() | `src/investiture/legacy-investiture-retired.controller.ts` |
| POST | `/api/v1/investiture/enrollments/:enrollmentId/invest` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Investir por la vía anterior. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.invest() | `src/investiture/legacy-investiture-retired.controller.ts` |
| POST | `/api/v1/investiture/enrollments/:enrollmentId/reject` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Rechazar en la vía anterior. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.reject() | `src/investiture/legacy-investiture-retired.controller.ts` |
| POST | `/api/v1/investiture/enrollments/bulk-approve` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Aprobación en bloque. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.bulkApprove() | `src/investiture/legacy-investiture-retired.controller.ts` |
| POST | `/api/v1/investiture/enrollments/bulk-reject` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Rechazo en bloque. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.bulkReject() | `src/investiture/legacy-investiture-retired.controller.ts` |
| POST | `/api/v1/admin/classes/enrollments/expire-overdue` | JWT | Permisos: catalogs:update; Global: admin | Vencer manualmente enrollments atrasados por duración de clase | InvestitureService.expireOverdueEnrollments() | `src/investiture/investiture.controller.ts` |
| GET | `/api/v1/investiture/pending` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Pendientes de la vía anterior. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.pending() | `src/investiture/legacy-investiture-retired.controller.ts` |
| GET | `/api/v1/investiture/enrollments/:enrollmentId/history` | JWT | Permisos: investiture:read | Historial de validación de investidura de un enrollment | InvestitureService.getHistory() | `src/investiture/investiture.controller.ts` |
| POST | `/api/v1/enrollments/:enrollmentId/submit-for-validation` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Alias de envío a validación. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.submitForValidationAlias() | `src/investiture/legacy-investiture-retired.controller.ts` |
| POST | `/api/v1/enrollments/:enrollmentId/validate` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Alias de validación. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.validateAlias() | `src/investiture/legacy-investiture-retired.controller.ts` |
| POST | `/api/v1/enrollments/:enrollmentId/investiture` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Alias de investir. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.investitureAlias() | `src/investiture/legacy-investiture-retired.controller.ts` |
| GET | `/api/v1/enrollments/:enrollmentId/investiture-history` | JWT | Permisos: investiture:read | [LEGACY] Historial de validación de investidura de un enrollment | InvestitureService.getHistory() | `src/investiture/investiture.controller.ts` |
| POST | `/api/v1/admin/investiture/legacy-locks/release` | JWT | `super-admin` exacto, comprobado en el servicio (`ExactSuperAdminWritePolicy`); la ruta usa `@SkipPermissions`. Otro actor: 403 `SUPER_ADMIN_WRITE_REQUIRED` | Suelta `locked_for_validation` de los expedientes de la vía anterior sin cambiar su `investiture_status`. Cuerpo `{ "dry_run"?: boolean }`, por defecto `true` (solo lista); con `false` escribe. Responde 200 `{ "status": "success", "data": { "dry_run", "candidates": [], "skipped_pending": [], "released": [] } }`. Candidato: `enrollments` con `locked_for_validation` true, `record_kind` `OPERATIONAL` e `investiture_status` distinto de `INVESTIDO`, sin filtrar por `active` ni por el estado de la cadena. Un enrollment con una persona `PENDING` en `investiture_authorization_people` se omite y va a `skipped_pending`. Con `dry_run: false`, una transacción por enrollment bajo el candado `investiture-authorization-enrollment:`; cada liberado deja una fila `LEGACY_LOCK_RELEASED` en `investiture_validation_history` con el `super-admin` como `performed_by`. Idempotente: repetirlo no vuelve a liberar. Requiere la migración `20261009120000_investiture_legacy_lock_release_action` ya aplicada en ese entorno. No ejecutado en ningún entorno. | LegacyLockReleaseService.release() | `src/investiture/investiture.controller.ts` |
| GET | `/api/v1/admin/investiture/config` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Configuración de la investidura anterior. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.listConfigs() | `src/investiture/legacy-investiture-retired.controller.ts` |
| GET | `/api/v1/admin/investiture/config/:configId` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Configuración de la investidura anterior. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.getConfig() | `src/investiture/legacy-investiture-retired.controller.ts` |
| POST | `/api/v1/admin/investiture/config` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Configuración de la investidura anterior. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.createConfig() | `src/investiture/legacy-investiture-retired.controller.ts` |
| PATCH | `/api/v1/admin/investiture/config/:configId` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Configuración de la investidura anterior. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.updateConfig() | `src/investiture/legacy-investiture-retired.controller.ts` |
| DELETE | `/api/v1/admin/investiture/config/:configId` | JWT | Ninguno (`@SkipPermissions`, sin roles ni permisos) | **Retirada (fase 8): 410** `INVESTITURE_LEGACY_PIPELINE_RETIRED`. Configuración de la investidura anterior. Sin cuerpo ni pipes de parámetros: ningún 400 ni 403 tapa el 410. | LegacyInvestitureRetiredController.deleteConfig() | `src/investiture/legacy-investiture-retired.controller.ts` |

### legal-representatives

> Perfiles familiares, rama `feat/family-profiles`, Pendiente de merge (PR #530 de sacdia-backend). Los representantes legales quedan de **solo lectura**: las tutorías (`guardianships`, sección homónima) los reemplazan y la tabla se elimina en la Fase 4. Sobre `development` aún existen las cuatro rutas.

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/users/:userId/legal-representative` | JWT | - | Obtener representante legal del usuario (solo lectura; dato sensible `legal_representative:read`). Sin `@ActingScope`: no se puede leer actuando por un menor | LegalRepresentativesService.findOne() | `src/legal-representatives/legal-representatives.controller.ts` |

**Retiradas** (la ruta ya no existe: el servidor responde 404): `POST`, `PATCH` y `DELETE /api/v1/users/:userId/legal-representative`. Los endpoints de escritura y sus servicios, DTO y specs se eliminaron. El permiso `legal_representative:update` sigue en el catálogo y en los seeds de otros roles, pero ninguna ruta lo usa. Consecuencias:

- El paso 2 del post-registro **ya no exige** representante legal para menores (ver `post-registration`); un menor de 13 años lo registra un tutor y un adolescente de 13 a 17 años se registra sin tutor (pendiente de la Fase 3).
- Los códigos `LEGAL_REP_*` siguen en `ErrorCode` y en los `errors.json` pero ya no los emite ninguna ruta.
- `GET /users/:userId/requires-legal-representative` sigue (deprecado) y usa la mayoría de edad del país.
- **Despliegue conjunto**: la app anterior a la Fase 2 sigue llamando a las rutas de escritura retiradas durante el post-registro; el backend y la app de la Fase 2 se despliegan juntos.

### Materials — Catalog

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/materials/catalog/categories` | JWT | Permisos: MATERIALS_READ | List all categories with active product count | CatalogService.listCategories() | `src/materials/catalog/catalog.controller.ts` |
| GET | `/api/v1/materials/catalog/programs` | JWT | Permisos: MATERIALS_READ | List all programs (club types) | CatalogService.listPrograms() | `src/materials/catalog/catalog.controller.ts` |
| GET | `/api/v1/materials/catalog` | JWT | Permisos: MATERIALS_READ | List products (paginated, filtered, scoped to LF) | CatalogService.list() | `src/materials/catalog/catalog.controller.ts` |
| GET | `/api/v1/materials/catalog/:id` | JWT | Permisos: MATERIALS_READ | Get product detail by ID | CatalogService.getById() | `src/materials/catalog/catalog.controller.ts` |

### Materials — Categories (admin)

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/materials/categories` | JWT | Permisos: MATERIALS_MANAGE_INVENTORY | List all material categories (admin view; includes inactive) | CategoriesService.list() | `src/materials/categories/categories.controller.ts` |
| POST | `/api/v1/materials/categories` | JWT | Permisos: MATERIALS_MANAGE_INVENTORY | Create a new material category | CategoriesService.create() | `src/materials/categories/categories.controller.ts` |
| PATCH | `/api/v1/materials/categories/:id` | JWT | Permisos: MATERIALS_MANAGE_INVENTORY | Update an existing category | CategoriesService.update() | `src/materials/categories/categories.controller.ts` |
| DELETE | `/api/v1/materials/categories/:id` | JWT | Permisos: MATERIALS_MANAGE_INVENTORY | Soft-delete a category (active=false). Blocked when products reference it. | CategoriesService.softDelete() | `src/materials/categories/categories.controller.ts` |

### Materials — Config

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/materials/config` | JWT | Permisos: MATERIALS_READ | Get the caller's local_field payment + delivery configuration | ConfigService.get() | `src/materials/config/config.controller.ts` |
| GET | `/api/v1/materials/config/all` | JWT | Permisos: MATERIALS_CONFIGURE | Lista config de materiales en el territorio del actor (todos los campos si es unscoped; unión/división/LF recortan) | ConfigService.listForScope() | `src/materials/config/config.controller.ts` |
| PATCH | `/api/v1/materials/config` | JWT | Permisos: MATERIALS_CONFIGURE | Upsert the materials configuration for a local_field (matches caller scope) | ConfigService.upsert() | `src/materials/config/config.controller.ts` |
| PATCH | `/api/v1/materials/config/:localFieldId` | JWT | Permisos: MATERIALS_CONFIGURE | Upsert config for a specific local_field (admin direct) | ConfigService.upsert() | `src/materials/config/config.controller.ts` |

### Materials — Inventory

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/materials/inventory` | JWT | Permisos: MATERIALS_MANAGE_INVENTORY | List products for the caller's local_field (admins can pass ?local_field_id=N) | InventoryService.list() | `src/materials/inventory/inventory.controller.ts` |
| POST | `/api/v1/materials/inventory` | JWT | Permisos: MATERIALS_MANAGE_INVENTORY | Create a product for the caller's local_field (admins can pass ?local_field_id=N) | InventoryService.create() | `src/materials/inventory/inventory.controller.ts` |
| PATCH | `/api/v1/materials/inventory/:id` | JWT | Permisos: MATERIALS_MANAGE_INVENTORY | Partially update a product | InventoryService.update() | `src/materials/inventory/inventory.controller.ts` |
| DELETE | `/api/v1/materials/inventory/:id` | JWT | Permisos: MATERIALS_MANAGE_INVENTORY | Soft-delete a product (sets active=false) | InventoryService.softDelete() | `src/materials/inventory/inventory.controller.ts` |
| PATCH | `/api/v1/materials/inventory/:id/variants/:variantId` | JWT | Permisos: MATERIALS_MANAGE_INVENTORY | Update stock for a specific variant option; recomputes product total stock | InventoryService.updateVariantStock() | `src/materials/inventory/inventory.controller.ts` |

### Materials — Orders

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/materials/orders` | JWT | Permisos: MATERIALS_CREATE | Create a new order | OrdersService.createOrder() | `src/materials/orders/orders.controller.ts` |
| GET | `/api/v1/materials/orders/history` | JWT | Permisos: MATERIALS_READ | Caller's own order history (always scoped to own orders) | OrdersService.historial() | `src/materials/orders/orders.controller.ts` |
| GET | `/api/v1/materials/orders` | JWT | Permisos: MATERIALS_READ | List orders (visibility + LF aware) | OrdersService.list() | `src/materials/orders/orders.controller.ts` |
| PATCH | `/api/v1/materials/orders/:folio/lines/:lineId` | JWT | Permisos: MATERIALS_APPROVE | Update line availability (campo local only, en_revision orders only) | OrdersService.patchLine() | `src/materials/orders/orders.controller.ts` |
| POST | `/api/v1/materials/orders/:folio/approve` | JWT | Permisos: MATERIALS_APPROVE | Approve order — allocate folio, decrement stock, snapshot config | OrdersService.approve() | `src/materials/orders/orders.controller.ts` |
| POST | `/api/v1/materials/orders/:folio/cancel` | JWT | Permisos: MATERIALS_READ | Cancel order — allowed from en_revision (own or campo), aprobada, pagada (campo only) | OrdersService.cancel() | `src/materials/orders/orders.controller.ts` |
| POST | `/api/v1/materials/orders/:folio/deliver` | JWT | Permisos: MATERIALS_DELIVER | Mark order as delivered — terminal transition (pagada → entregada) | OrdersService.deliver() | `src/materials/orders/orders.controller.ts` |
| GET | `/api/v1/materials/orders/:folio` | JWT | Permisos: MATERIALS_READ | Get full order detail by folio | OrdersService.getByFolio() | `src/materials/orders/orders.controller.ts` |

### Materials — Receipts

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/materials/receipts/:folio` | JWT | Permisos: MATERIALS_UPLOAD_RECEIPT | Upload payment receipt for an approved order | ReceiptsService.upload() | `src/materials/receipts/receipts.controller.ts` |
| POST | `/api/v1/materials/receipts/:folio/approve` | JWT | Permisos: MATERIALS_VALIDATE_RECEIPT | Approve a pending receipt — transitions order to pagada | ReceiptsService.approve() | `src/materials/receipts/receipts.controller.ts` |
| POST | `/api/v1/materials/receipts/:folio/reject` | JWT | Permisos: MATERIALS_VALIDATE_RECEIPT | Reject a pending receipt — order remains in aprobada | ReceiptsService.reject() | `src/materials/receipts/receipts.controller.ts` |
| GET | `/api/v1/materials/receipts/:folio` | JWT | Permisos: MATERIALS_READ | List all receipts for an order (with signed read URLs) | ReceiptsService.list() | `src/materials/receipts/receipts.controller.ts` |

### member-of-month

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/member-of-month/admin/list` | JWT | Permisos: mom:supervise. Coordinator: `club_section_ids` (ignora `local_field_id`). | Listar miembro del mes multi-sección (admin/coordinator por asignaciones) | MemberOfMonthService.listForAdmin() | `src/member-of-month/member-of-month.controller.ts` |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId/member-of-month` | JWT | Permisos: mom:read | Obtener miembro del mes actual de la sección | MemberOfMonthService.getCurrentMemberOfMonth() | `src/member-of-month/member-of-month.controller.ts` |
| GET | `/api/v1/clubs/:clubId/sections/:sectionId/member-of-month/history` | JWT | Permisos: mom:read | Obtener historial paginado de miembro del mes | MemberOfMonthService.getMemberOfMonthHistory() | `src/member-of-month/member-of-month.controller.ts` |
| POST | `/api/v1/clubs/:clubId/sections/:sectionId/member-of-month/evaluate` | JWT | Permisos: mom:evaluate | Disparar evaluación manual de miembro del mes | MemberOfMonthService.evaluateMemberOfMonth() | `src/member-of-month/member-of-month.controller.ts` |

### annual-membership

> **Inscripción anual de miembros** — la directiva de la sección destino inscribe a no inscritos del **año vigente**. No copia cargos. D01 bloquea autoactivación del titular.
> POST crea matrícula de clase en la misma transacción (`NextClassResolver` + `ClassEnrollmentPolicyService` modo `annual` + `ClassEnrollmentWriter`). No usa `ClassesService.enrollUser`. GET une no inscritos locales con graduados de tipo (R14: última clase AV/CQ cursada, edad al inicio del año destino, sección destino activa). Salto AV→CQ / CQ→GM: `NextClassResolver` `crossed_type: true` e inscripción en la sección destino del POST; si el resolver apunta a otra sección, `blocked`. Catálogo incompleto, edad insuficiente o sin sección destino: `blocked` `ANNUAL_CLASS_POLICY_UNRESOLVED`. Última clase Guía Mayor: `path_complete`, membresía activa y sin inscripción nueva. Clases GM con `max_duration_years > 1` siguen abiertas (no es este salto). El DTO de resultado no expone `crossed_type`.

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/club-sections/:sectionId/annual-continuations` | JWT | Permisos: club_members:approve · `@AuthorizationResource` club_section | Listar no inscritos de la pertenencia de esa sección en el año vigente **y** candidatos de salto de tipo hacia esta sección (última AV→CQ o última CQ→GM, R14). Query: `page`, `limit`, `search`. Respuesta paginada: `{ user_id, name, base_section_id, ecclesiastical_year_id, annual_status, current_role, eligibility, blocked_reason, suggested_class }`. `suggested_class`: `{ status: 'resolved', class_id }`, `{ status: 'complete' }` cuando Guía Mayor ya es la última clase, o `{ status: 'blocked', code }` (p. ej. `ANNUAL_CLASS_POLICY_UNRESOLVED`). El alta responde `path_complete` sin `enrollment_id` nuevo. No lista exclusiva del año pasado. No filtra elegibilidad por `active=true` de cargos históricos. Directivo AV/CQ que retorna a GM (R04) no aparece aquí como graduado de tipo. | AnnualMembershipService.listContinuations() | `src/annual-membership/annual-continuations.controller.ts` |
| POST | `/api/v1/club-sections/:sectionId/annual-continuations` | JWT | Permisos: club_members:approve · `@AuthorizationResource` club_section | Inscribir. Body: `{ user_ids: string[] }` 1–100 distintos. Activa `member inactive` del año actual en **esta** sección **o crea** `member` active en destino si el salto de tipo es aceptado y la base no coincide. Matricula la clase resuelta (secuencia en el mismo tipo o clase por edad en el tipo destino). Sin exigir investidura del predecesor. Idempotente `already_enrolled` si ya hay `member active` aquí (`enrollment_id` puede ser `null` en ese outcome). Un director operativo en otra sección no cuenta como inscrito aquí. Lote por usuario: `enrolled\|already_enrolled\|blocked\|failed`. `enrollment_id` en `enrolled`. Actor registrado. Dueño del perfil **no** autoriza este POST. Un menor sin consentimiento verificado no se inscribe: su resultado es `blocked` con `error_code: MR_CONSENT_NOT_VERIFIED` y el resto del lote sigue (ver «Compuerta de consentimiento en las activaciones de rol») | AnnualMembershipService.continueUsers() | `src/annual-membership/annual-continuations.controller.ts` |
| POST | `/api/v1/users/:userId/membership/annual-enroll` | JWT | Permisos: registration:complete · Owner bypass (guard) | **D01 pendiente.** Siempre **403** `ANNUAL_ENROLL_REQUIRES_DIRECTIVE`, sin efectos. No éxito engañoso ni `pending`. | AnnualMembershipService.annualEnroll() | `src/annual-membership/annual-enroll.controller.ts` |

### membership-requests

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/club-sections/:clubSectionId/membership-requests` | JWT | Permisos: club_members:approve **o** consent:verify (modo «cualquiera de»; coordinadores solo en secciones cubiertas por sus `coordinator_assignments` `GENERAL`/`ZONE`/`SECTION`, `@AuthorizationResource` club_section con `coordinatorSections`) | Listar solicitudes pendientes de membresía. Un revisor solo-verificación (opción B) ve solo menores con consentimiento `pending` y ficha vigente, y las filas con `viewer_verify_block` se muestran con el bloqueo. Cada ítem añade `consent` (`null` para adultos; para menores sin cuenta, ver «Consentimiento del tutor» debajo; Fase 3c: el bloque lleva `viewer_can_verify` y `viewer_verify_block`, ver «`consent.viewer_can_verify` y `consent.viewer_verify_block`») y `effective_expires_at` (cuándo vence de verdad; ver «Expiración» debajo), y `users.email` puede ser `null` | MembershipRequestsService.listPending() | `src/membership-requests/membership-requests.controller.ts` |
| POST | `/api/v1/club-sections/:clubSectionId/membership-requests/:assignmentId/approve` | JWT | Permisos: club_members:approve | Aprobar solicitud de membresía. **Responde 200** (`@HttpCode(HttpStatus.OK)`, commit `1e423a34` de la rama `fix/approve-status-and-device-refresh-pg`, pendiente de merge; antes respondía 201 y el QA 3a lo confirmó en vivo). Un menor (sin cuenta, o **con cuenta y de edad menor que la mayoría de edad del país**, Fase 3a; también con fecha de nacimiento `NULL`, que falla cerrada) cuyo consentimiento no está verificado → 409 `MR_CONSENT_NOT_VERIFIED` (la comprobación va dentro de la transacción de la aprobación y es la compuerta común de activación, ver «Compuerta de consentimiento en las activaciones de rol»). Si la solicitud ya no está `pending` al entrar a la transacción (otra revisión la procesó, o se canceló o expiró) no se activa nada: 409 `MR_ALREADY_PENDING`, o 404 `MR_NOT_FOUND` si es de otra sección. El 409 de esta ruta tiene **dos causas distintas**: `MR_CONSENT_NOT_VERIFIED` (el menor no tiene el consentimiento verificado) y `MR_ALREADY_PENDING` (la solicitud ya no estaba pendiente); el Swagger las separaba mal y se corrigió (`membership-requests.controller.ts:128-132`). Aprobar y rechazar registran un evento de auditoría con el revisor como actor | MembershipRequestsService.approve() | `src/membership-requests/membership-requests.controller.ts` |
| POST | `/api/v1/club-sections/:clubSectionId/membership-requests/:assignmentId/reject` | JWT | Permisos: club_members:approve | Rechazar solicitud de membresía. Responde **200** (`@HttpCode(HttpStatus.OK)`, commit `1e423a34`, pendiente de merge; antes 201) | MembershipRequestsService.reject() | `src/membership-requests/membership-requests.controller.ts` |
| POST | `/api/v1/club-sections/:clubSectionId/membership-requests/:assignmentId/consent-evidence` | JWT | Permisos: club_members:approve (solo; `consent:verify` no basta: un revisor solo-verificación recibe 403 `GUARD_PERMISSION_DENIED` o `GUARD_CLUB_SCOPE_REQUIRED`) · `@AuthorizationResource` club_assignment; throttle 20/hora | El director sube la ficha firmada del menor (multipart `file`; mismas reglas de archivo que la del tutor). Solo para solicitudes `pending` de esa sección. 201 `{ evidence_id, content_type, size_bytes, uploaded_at }`. No verifica el consentimiento. Con el consentimiento ya verificado → 409 `GUARDIANSHIP_CONSENT_ALREADY_VERIFIED` | GuardianEvidenceService.uploadForDirector() | `src/membership-requests/membership-requests.controller.ts` |
| GET | `/api/v1/club-sections/:clubSectionId/membership-requests/:assignmentId/consent-evidence` | JWT | Permisos: club_members:approve **o** consent:verify (modo «cualquiera de»; coordinadores solo en secciones cubiertas por sus asignaciones, `coordinatorSections`) · `@AuthorizationResource` club_assignment | URL firmada (15 min) de la ficha vigente. Solicitudes `pending` o `active` de esa sección. Un revisor solo-verificación solo la lee dentro de su lista (solicitud `pending`, menor, consentimiento `pending`, ficha vigente); fuera, 404 `MR_NOT_FOUND`. 200 `{ url, expires_in: 900, content_type, uploaded_at, uploaded_by_display_name }` | GuardianEvidenceService.getForDirector() | `src/membership-requests/membership-requests.controller.ts` |
| POST | `/api/v1/club-sections/:clubSectionId/membership-requests/:assignmentId/verify-consent` | JWT | Permisos: club_members:approve **o** consent:verify (Fase 3c, modo «cualquiera de»; `approve: true` exige además club_members:approve, si no 403 `MR_APPROVE_PERMISSION_REQUIRED`; coordinadores solo en secciones cubiertas por sus asignaciones, `coordinatorSections`; un solo-verificación fuera de su lista → 404 `MR_NOT_FOUND`) · `@AuthorizationResource` club_assignment | El director confirma que revisó la ficha firmada y verifica el consentimiento del menor (y, con `approve: true`, aprueba la solicitud). Responde **200** (idempotente), no 201 | ConsentVerificationService.verify() | `src/membership-requests/membership-requests.controller.ts` |

#### Consentimiento del tutor (menores sin cuenta)

> Perfiles familiares, rama `feat/family-profiles`, Pendiente de merge (PR #530 de sacdia-backend). Aplica a **dependientes** (usuarios con `dependent_profiles`). Las filas `is_test_data` nunca cuentan como consentimiento.
>
> **Fase 3a** (rama `feat/family-profiles-phase3`, Pendiente de merge (PR #531 de sacdia-backend)): la compuerta y el bloque `consent` pasan de «tiene `dependent_profiles`» a **«es menor de edad»** (edad menor que la mayoría de edad del país, o `dependent_profiles`, o fecha de nacimiento `NULL`). Un adolescente que se registró solo ya **no** queda sin consentimiento: aprobar su solicitud responde 409 `MR_CONSENT_NOT_VERIFIED` hasta que haya un tutor vinculado y verificado. Solo los adultos no cambian (`consent` es `null`). Un menor sin `dependent_profiles` (adolescente que aún no tiene tutor) recibe el bloque `{ "required": true, "dependent": false, "guardian_linked": false, "guardianship_id": null, "status": "pending", "guardians": [] }`; **todos** los bloques agregan `guardian_linked` (`true` si hay una tutoría de persona activa, aunque sea pendiente).

**Bloque `consent` en `GET .../membership-requests`** (una consulta por lote, sin N+1):

```json
{
  "required": true,
  "dependent": true,
  "guardianship_id": "uuid",
  "status": "pending",
  "evidence_uploaded": false,
  "guardians": [
    { "display_name": "María Pérez", "relationship_type_name": "Madre", "is_primary": true }
  ]
}
```

- `status` es `verified` solo si alguna tutoría real (no de prueba, no revocada) está verificada; si no, `pending`. `guardianship_id` es la tutoría principal activa sobre la que actúa `verify-consent`, o `null` si no queda ninguna.
- `evidence_uploaded` mira la ficha vigente de la fila principal.
- `verification_method` toma `director_paper_form`, `coordinator_paper_form` (verificó un coordinador por su asignación), `guardian_invite`, `legacy_import` o `test_placeholder`, o `null` si la tutoría no está verificada.
- `guardians` va con la principal primero y luego por antigüedad. Una custodia del club muestra el nombre del club. No incluye teléfonos ni correos.
- **Fase 3c**: el bloque agrega `viewer_can_verify` (boolean) y `viewer_verify_block` (`self_guardian`, `self_custodian` o `null`), calculados para quien consulta. Semántica exacta en «`consent.viewer_can_verify` y `consent.viewer_verify_block`» (sección «Registro de menores por un director y acceso familiar en el panel (Fase 3c)»).

**`POST .../:assignmentId/verify-consent`**. Body (campos extra → 400):

```json
{ "confirm_paper_form_reviewed": true, "approve": true }
```

- `confirm_paper_form_reviewed` es obligatorio y debe ser `true`; `approve` es opcional (por defecto `false`).
- Respuesta 200: `{ guardianship: { guardianship_id, consent_status: "verified", verified_at, verified_by_user_id, verification_method }, assignment: <fila club_role_assignments> | null, approve_error: string | null }`. `verification_method` es `coordinator_paper_form` si quien verifica llegó a la sección por la vía del coordinador (rol global de coordinador con `consent:verify` y una `coordinator_assignment` vigente que cubre la sección, es decir, el `coordinatorSectionGrant`) y `director_paper_form` en cualquier otro caso (director, o un rol de club con solo `consent:verify`). Rama `feat/coordinator-pending-consents`. Las filas verificadas antes de este cambio quedan como `director_paper_form`.
- Una transacción, serializada por dependiente: la solicitud debe pertenecer a la sección de la ruta; se actúa sobre la **tutoría principal activa** (de persona o de custodia); debe haber una ficha vigente. Marca la fila `verified` (`verified_by_user_id`, `verified_at`, `director_paper_form` o `coordinator_paper_form` según la vía de quien verifica), **promueve** a `verified` (`guardian_invite`) a los tutores invitados por ese tutor mientras estaba `pending` (también en cadena), y escribe el evento de auditoría `guardianship` / `consent_verified` en la misma transacción (`changes.verification_method` lleva el mismo valor que la fila; con la vía de coordinador el resumen dice «verificado por el coordinador»). Después del commit sube el `epoch` de acting-for (los scopes del tutor se amplían en su siguiente petición) y avisa a los tutores (push `family:consent_verified`, excluye a quien verificó).
- **Aprobación en dos tiempos**: si `approve: true` y aprobar falla **después** del commit, la respuesta es 200 con `assignment: null` y `approve_error` con el código del fallo; el consentimiento queda verificado y repetir la misma llamada reintenta solo la aprobación.
- **Idempotencia**: si la solicitud ya está `active` y el consentimiento verificado → 200 sin efectos. Si la tutoría ya estaba verificada y la solicitud sigue `pending`, no se reescribe nada.
- **Fase 3a — verificar sobre una asignación ya `active`**: `verify-consent` también acepta una asignación `active` con el consentimiento aún `pending` (un adolescente que ya estaba en un club antes de la Fase 3a) y **solo verifica** (`assignment: null`, sin aprobar). Funciona para un adolescente con tutoría (su `dependent_profiles` se crea al canjear el código). Al verificar a un adolescente: se asegura idempotentemente su fila `supervised_logins` (`method = email`), se limpia `pending_since`, se sube su `epoch` (pasa a `TEEN_SCOPES` en su siguiente petición) y se avisa al tutor con `family:consent_verified`. Se mantiene `GUARDIANSHIP_GUARDIAN_SELF_VERIFY`: un tutor vivo nunca verifica.
- **Cuatro ojos** (se evalúan solo cuando el consentimiento pasa de `pending` a `verified`; repetir la llamada sobre una tutoría ya verificada es una no-operación 200):
  - **En toda tutoría** (de persona o de custodia): quien verifica no puede ser un tutor vigente del menor (principal, secundario, invitado o de prueba; una tutoría `revoked` no cuenta), aunque tenga `club_members:approve` en la sección → 403 `GUARDIANSHIP_GUARDIAN_SELF_VERIFY`. Otra persona autorizada del club o un administrador debe hacerlo.
  - **Solo en custodia del club** (decisión A14): quien verifica no puede ser quien subió la ficha vigente, ni quien creó al menor (`dependent_profiles.created_by_user_id`), ni el último tutor que lo dejó en custodia (tutoría `revoked` con `revoked_reason` `guardian_left` o `guardian_account_closed`) → 403 `GUARDIANSHIP_CUSTODIAN_SELF_VERIFY`. Otra persona autorizada del club (subdirector, secretario, otro director con `club_members:approve`) o un administrador sí puede. En tutorías de persona, quien sube la ficha como director sí puede verificarla mientras no sea tutor del menor.
- Errores: 400 `MR_CONSENT_CONFIRMATION_REQUIRED` (`confirm_paper_form_reviewed: false`; ausente o no booleano → 400 de validación genérico); 403 `GUARDIANSHIP_GUARDIAN_SELF_VERIFY`, 403 `GUARDIANSHIP_CUSTODIAN_SELF_VERIFY`, 403 `MR_APPROVE_PERMISSION_REQUIRED` o ni `club_members:approve` ni `consent:verify` (para un coordinador, 403 `GUARD_CLUB_SCOPE_REQUIRED` fuera de las secciones que cubren sus asignaciones); 404 `MR_NOT_FOUND` (solicitud inexistente, de otra sección o inactiva; para un revisor solo-verificación, también todo lo que quede fuera de su lista); 404 `GUARDIANSHIP_NOT_FOUND` (el solicitante no es un dependiente, o no hay tutoría principal activa: no se escribe nada); 409 `GUARDIANSHIP_EVIDENCE_REQUIRED` (sin ficha vigente); 409 `MR_ALREADY_PENDING` (solicitud ya procesada de otro modo, o alguien verificó o revocó entre la lectura y la escritura).

**Subir y leer la ficha como director**: la solicitud debe pertenecer a la sección de la ruta y ser de un dependiente (si no, 404 `MR_NOT_FOUND` o 404 `GUARDIANSHIP_NOT_FOUND`); subir exige estado `pending`, leer admite `pending` y `active`. Subir con el consentimiento del menor **ya verificado** → 409 `GUARDIANSHIP_CONSENT_ALREADY_VERIFIED` (la ficha verificada queda bloqueada; reemplazarla exige una tutoría nueva, es decir, revocar). 404 `GUARDIANSHIP_EVIDENCE_NOT_FOUND` si no hay ficha; 503 `GUARDIANSHIP_EVIDENCE_UNAVAILABLE` sin bucket. Con `X-Acting-For` estas rutas responden 403 `ACTING_FOR_SCOPE_DENIED` (ninguna declara scope).

**Expiración**: el cron de membresía caduca las solicitudes `pending` tras `membership.pending_timeout_days` (8 por defecto). Para un dependiente con consentimiento **sin verificar** el plazo es de al menos **30 días** desde la creación (`max(configurado, 30)`), porque la ficha viaja por el tutor. Al verificar, el reloj **se reinicia**: el plazo base se cuenta desde `max(creación, verificación)`. El resto de solicitudes no cambia. El cron decide con `created_at` y la fecha de verificación, no con la columna `expires_at`.

**`effective_expires_at`** (cada ítem de `GET .../membership-requests`): instante ISO 8601 (UTC) en que la solicitud vence de verdad. Sale de la **misma función** que usa el cron, `effectiveMembershipExpiry` (`src/membership-requests/membership-request-expiry.ts:37-53`), así que lo que ve el director y lo que ejecuta el cron no pueden discrepar:

| Solicitante | `effective_expires_at` |
| --- | --- |
| Adulto o adolescente con cuenta | `created_at` + plazo base |
| Menor sin cuenta, consentimiento sin verificar | `created_at` + `max(plazo base, 30)` días |
| Menor sin cuenta, consentimiento verificado | `max(created_at, verified_at)` + plazo base |

La solicitud vence cuando la hora actual es estrictamente posterior a ese instante (`membership-request-expiry.ts:55-60`). `expires_at` se devuelve sin cambios, pero es solo el plazo base que se guardó al crear la solicitud (hoy fijo: creación + 8 días, `post-registration.service.ts:593-594`, sin leer la configuración ni el consentimiento), así que **los clientes muestran `effective_expires_at`**. `listPending` calcula el valor en lote junto al bloque `consent` (`membership-requests.service.ts:84-100`).

Cambios de comportamiento al extraer la función compartida (`membership-request-expiry.ts`, usada por el cron en `membership-requests.service.ts:414-476` y por el listado):

- **Plazo base inválido**: si `membership.pending_timeout_days` no es un número (o no existe), se usa **8** (`parsePendingTimeoutDays`, `:14-20`). Antes el cron pasaba el `parseInt` tal cual, sin respaldo.
- **Aritmética de días en UTC**: los días se suman o restan con `setUTCDate` (`addDays`, `:22-26`). Antes el cron restaba con `setDate`, que usa la hora local del servidor.
- La constante `DEPENDENT_CONSENT_PENDING_TIMEOUT_DAYS` (30) y el valor por defecto (8) viven ahora en ese archivo, no en el servicio.

**Aviso a directores**: la notificación de solicitud nueva de un menor con consentimiento pendiente usa el título «Menor · consentimiento pendiente» y pide verificar la ficha antes de aprobar.

##### Compuerta de consentimiento en las activaciones de rol

La regla es **una sola** y la aplican todas las escrituras que pueden dejar una fila de `club_role_assignments` en estado `active` (`src/membership-requests/assignment-activation-gate.ts`): un **menor** necesita una tutoría `verified` real (no `is_test_data`, no revocada; la custodia del club cuenta). **Fase 3a**: «menor» ya no es solo «tiene `dependent_profiles`»: es cualquiera con edad menor que la mayoría de edad del país (calendario de la zona horaria del país), con `dependent_profiles`, o con fecha de nacimiento `NULL` (falla cerrada; se resuelve al guardar una fecha de adulto). Los adolescentes con cuenta propia **sí** se bloquean; solo los adultos no. En el año de corte, el candado por dependiente también incluye a los menores por edad. Se llama con el **mismo cliente de transacción** que escribe la asignación, justo antes de la escritura, y toma el candado por dependiente (el mismo de verificar, revocar, salir y subir ficha), así una activación y un cambio de consentimiento no compiten. Sin consentimiento verificado → 409 `MR_CONSENT_NOT_VERIFIED`.

| Ruta o proceso | Método de servicio | Sin consentimiento verificado |
| --- | --- | --- |
| `POST /club-sections/:clubSectionId/membership-requests/:assignmentId/approve` | `MembershipRequestsService.approve` | 409 |
| `PATCH /club-roles/:assignmentId` (solo si escribe `status: 'active'` o cambia el rol de una fila activa) | `ClubsService.updateRoleAssignment` | 409 |
| `POST /clubs/:clubId/sections/:sectionId/roles` | `ClubsService.assignRole` | 409 |
| `POST /clubs/:clubId/sections/:sectionId/director-assignment` | `ClubsService.assignInitialSectionDirector` | 409 |
| `POST /clubs/:clubId/sections/:sectionId/director-succession` (sucesor) | `ClubsService.succeedSectionDirector` | 409, antes de terminar al saliente |
| `POST /requests/assignments/:requestId/review` (aprobar) | `RequestsService.reviewAssignment` | 409 |
| `POST /requests/transfers/:requestId/review` (aprobar; mueve una membresía ya activa a otra sección y se controla igual) | `RequestsService.reviewTransfer` | 409 |
| `POST /club-sections/:sectionId/annual-continuations` (reactivar `member inactive`, activar el marcador de la sección base, crear `member` por salto de tipo) | `AnnualMembershipService._enrollInTransaction` | resultado por usuario `blocked` con `error_code: MR_CONSENT_NOT_VERIFIED`; el lote sigue |
| Corte de año (cron diario `5 6 * * *` UTC): salto de tipo | `AnnualMembershipService.writeTypeJumpEnrollment` | se omite (`skipped`) con `logger.warn`; el corte sigue |
| Corte de año: activación de planes de sucesión de director | `YearCutService.activateScheduledPlans` | el plan se omite con código `MR_CONSENT_NOT_VERIFIED` y se avisa a administradores y a director-lf/assistant-lf del campo local; el corte sigue |

El corte de año toma de antemano el candado de todos los dependientes implicados en orden ascendente de `user_id` para no provocar interbloqueos. **No** pasan por la compuerta porque no activan: `DELETE /club-roles/:assignmentId` (`ended`), rechazar, cancelar, expirar, el cierre de asignaciones al terminar el año, el marcador `inactive` de «no inscrito» y el paso 3 del post-registro (crea la solicitud en `pending`; se activa después por `approve`). Un guard de pruebas (`assignment-activation-gate.inventory.spec.ts`, escaneo de AST) falla si aparece una escritura nueva sobre `club_role_assignments` que active sin la compuerta (cada sitio se anota con `// activation-gate: <usuario>`). Las escrituras fuera del backend (SQL manual, seeds, scripts) **no** pasan por la compuerta: ver [runbook de activación manual](../runbooks/family-profiles-consent-gate-manual-sql.md).

**Fase 3a**: el guard `assignment-activation-gate.inventory.spec.ts` verifica ahora la regla por edad y parametriza las siete escrituras que activan con un menor de 16 años sin consentimiento (todas → 409 `MR_CONSENT_NOT_VERIFIED`). En el corte de año y la continuación anual, solo se bloquea a los menores sin consentimiento y el lote sigue.

**Errores nuevos** de esta sección: `MR_CONSENT_NOT_VERIFIED` (409), `MR_CONSENT_CONFIRMATION_REQUIRED` (400), `GUARDIANSHIP_EVIDENCE_REQUIRED` (409), `GUARDIANSHIP_EVIDENCE_NOT_FOUND` (404), `GUARDIANSHIP_EVIDENCE_UNAVAILABLE` (503), `GUARDIANSHIP_CUSTODIAN_SELF_VERIFY` (403), `GUARDIANSHIP_GUARDIAN_SELF_VERIFY` (403), `GUARDIANSHIP_CONSENT_ALREADY_VERIFIED` (409).

### monthly-reports

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/monthly-reports/preview/:enrollmentId` | JWT | Permisos: reports:read | Vista previa del informe mensual | MonthlyReportsService.preview() | `src/monthly-reports/monthly-reports.controller.ts` |
| POST | `/api/v1/monthly-reports/:enrollmentId` | JWT | Permisos: reports:read | Obtener o crear borrador de informe mensual | MonthlyReportsService.getOrCreateDraft() | `src/monthly-reports/monthly-reports.controller.ts` |
| PATCH | `/api/v1/monthly-reports/:reportId/manual-data` | JWT | Permisos: reports:read | Actualizar datos manuales del informe | MonthlyReportsService.updateManualData() | `src/monthly-reports/monthly-reports.controller.ts` |
| POST | `/api/v1/monthly-reports/:reportId/generate` | JWT | Permisos: reports:read | Encola congelar snapshot + PDF (202). Poll GET :reportId hasta generated. | MonthlyReportsService.enqueueGenerate() | `src/monthly-reports/monthly-reports.controller.ts` |
| POST | `/api/v1/monthly-reports/:reportId/submit` | JWT | Permisos: reports:read | Enviar informe al campo | MonthlyReportsService.submit() | `src/monthly-reports/monthly-reports.controller.ts` |
| GET | `/api/v1/monthly-reports/enrollment/:enrollmentId` | JWT | Permisos: reports:read | Listar informes de una matrícula | MonthlyReportsService.listReports() | `src/monthly-reports/monthly-reports.controller.ts` |
| GET | `/api/v1/monthly-reports/:reportId/pdf` | JWT | Permisos: reports:download | Descargar PDF. Nombre: `informe-mensual-{club}-{tipo}-{mes}-{año}.pdf` | MonthlyReportsPdfService.generatePdf() | `src/monthly-reports/monthly-reports.controller.ts` |
| POST | `/api/v1/monthly-reports/:reportId/regenerate` | JWT | Permisos: reports:write | Encola rerender del PDF almacenado (202) | MonthlyReportsService.enqueueRegenerate() | `src/monthly-reports/monthly-reports.controller.ts` |
| GET | `/api/v1/monthly-reports/admin/list` | JWT | Permisos: reports:read | Listar reportes multi-club (admin/coordinator) | MonthlyReportsService.listForAdmin() | `src/monthly-reports/monthly-reports.controller.ts` |
| GET | `/api/v1/monthly-reports/:reportId` | JWT | Permisos: reports:read | Obtener informe mensual | MonthlyReportsService.getReport() | `src/monthly-reports/monthly-reports.controller.ts` |

### Notifications

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/notifications/send` | JWT | Permisos: notifications:send | Send notification to specific user | NotificationsService.sendToUser() | `src/notifications/notifications.controller.ts` |
| POST | `/api/v1/notifications/broadcast` | JWT | Permisos: notifications:broadcast | Send notification to all users | NotificationsService.broadcast() | `src/notifications/notifications.controller.ts` |
| POST | `/api/v1/notifications/club/:instanceType/:instanceId` | JWT | Permisos: notifications:club | Send notification to club members | NotificationsService.sendToClubMembers() | `src/notifications/notifications.controller.ts` |
| GET | `/api/v1/notifications/targets/club` | JWT | Permisos: notifications:club | Get authorized club notification targets for current actor | NotificationsService.getAuthorizedClubTargets() | `src/notifications/notifications.controller.ts` |
| GET | `/api/v1/notifications/history` | JWT | - | Get paginated notification history | NotificationsService.getNotificationHistory() | `src/notifications/notifications.controller.ts` |
| GET | `/api/v1/notifications/unread-count` | JWT | - | Get unread notification count for the current user | NotificationsService.getUnreadCount() | `src/notifications/notifications.controller.ts` |
| PATCH | `/api/v1/notifications/read-all` | JWT | - | Mark all unread notifications as read | NotificationsService.markAllDeliveriesRead() | `src/notifications/notifications.controller.ts` |
| PATCH | `/api/v1/notifications/:deliveryId/read` | JWT | - | Mark a single notification delivery as read | NotificationsService.markDeliveryRead() | `src/notifications/notifications.controller.ts` |
| GET | `/api/v1/notifications/preferences` | JWT | - | Get current user notification preferences | NotificationPreferencesService.getUserPreferences() | `src/notifications/notifications.controller.ts` |
| PUT | `/api/v1/notifications/preferences/:category` | JWT | - | Update notification preference for a category | NotificationPreferencesService.setPreference() | `src/notifications/notifications.controller.ts` |

Perfiles familiares: un dependiente no tiene cuenta ni tokens FCM, así que un push dirigido a él se reenvía a sus tutores activos (máximo 4, sin custodia ni datos de prueba) con título `"{Nombre} · {título}"` y `data.dependent_user_id`. Cada tutor recibe el push solo si su propia preferencia de la categoría lo permite. La entrega en la bandeja sigue en el menor (el tutor la lee actuando por él, scope `self:read`). No aplica a pushes silenciosos ni a fuentes `family:*`. Fuentes nuevas, todas de la categoría `approvals`: `family:custody_transferred`, `family:evidence_uploaded` (evidencia subida por o para el menor por alguien que no es el tutor que actúa; sin efecto cuando el propio tutor sube actuando) y `family:consent_verified` (un director verificó la ficha firmada: llega a los tutores del menor, excepto a quien verificó, con `data: { type: "dependent_consent_verified", dependent_user_id }`, así que la app aplica el mismo diálogo «¿Cambiar a su perfil?» que con cualquier push de un menor). No hay chat ni mensajería entre usuarios.

### FCM Tokens

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/fcm-tokens` | JWT | - | Register FCM token | FcmTokensService.registerToken() | `src/notifications/notifications.controller.ts` |
| DELETE | `/api/v1/fcm-tokens/by-token` | JWT | - | Unregister FCM token by token string | FcmTokensService.unregisterToken() | `src/notifications/notifications.controller.ts` |
| DELETE | `/api/v1/fcm-tokens/:id` | JWT | - | Unregister FCM token by record ID | FcmTokensService.unregisterTokenById() | `src/notifications/notifications.controller.ts` |
| GET | `/api/v1/fcm-tokens` | JWT | - | Get current user FCM tokens | FcmTokensService.getUserTokens() | `src/notifications/notifications.controller.ts` |
| GET | `/api/v1/fcm-tokens/user/:userId` | JWT | Owner o global: admin, assistant-admin, super-admin. `coordinator` no es atajo. | Get FCM tokens by user ID (owner/admin only) | FcmTokensService.getUserTokens() | `src/notifications/notifications.controller.ts` |

### User Notification Preferences

> Fase 3a: `GET`/`PATCH /users/me/notification-preferences` llevan el scope `self:preferences` y `POST`/`DELETE /users/me/fcm-tokens` el scope `push:register`, ambos para el adolescente (pendiente y con tutor). El tutor actuando y los demás tipos siguen sin acceso; los `/fcm-tokens*` heredados no llevan scope. Un tutor no puede silenciar `family:security` (ver «Avisos de seguridad al tutor»).

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/users/me/notification-preferences` | JWT | - | Get notification preferences for the authenticated user | - | `src/notifications/user-notification-preferences.controller.ts` |
| PATCH | `/api/v1/users/me/notification-preferences` | JWT | - | Update notification preferences | NotificationPreferencesService.setPreference() | `src/notifications/user-notification-preferences.controller.ts` |
| POST | `/api/v1/users/me/fcm-tokens` | JWT | - | Register an FCM token for the authenticated user | FcmTokensService.registerToken() | `src/notifications/user-notification-preferences.controller.ts` |
| DELETE | `/api/v1/users/me/fcm-tokens/:tokenId` | JWT | - | Unregister an FCM token by record ID | FcmTokensService.unregisterTokenById() | `src/notifications/user-notification-preferences.controller.ts` |

### post-registration

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/users/:userId/post-registration/photo-status` | JWT | - | Verificar si el usuario tiene foto de perfil subida | PostRegistrationService.getPhotoStatus() | `src/post-registration/post-registration.controller.ts` |
| GET | `/api/v1/users/:userId/post-registration/status` | JWT | - | Obtener estado del post-registro | PostRegistrationService.getStatus() | `src/post-registration/post-registration.controller.ts` |
| POST | `/api/v1/users/:userId/post-registration/step-1/complete` | JWT | Permisos: registration:complete | Completar Paso 1: Foto de perfil | PostRegistrationService.completeStep1() | `src/post-registration/post-registration.controller.ts` |
| POST | `/api/v1/users/:userId/post-registration/step-2/complete` | JWT | Permisos: registration:complete | Completar Paso 2: Información personal. Valida género, cumpleaños, bautismo y al menos un contacto de emergencia. **Ya no exige representante legal** para menores (perfiles familiares) | PostRegistrationService.completeStep2() | `src/post-registration/post-registration.controller.ts` |
| POST | `/api/v1/users/:userId/post-registration/step-3/complete` | JWT | Permisos: registration:complete | Completar Paso 3: Selección de club | PostRegistrationService.completeStep3() | `src/post-registration/post-registration.controller.ts` |
| POST | `/api/v1/users/:userId/post-registration/step-3/guardian-only` | JWT | Permisos: registration:complete | Paso 3 alterno «Solo soy tutor de menores»: cierra el post-registro de un adulto sin elegir club. Sin `@ActingScope` (ver abajo). 200 `{ status, message: "Post-registro completado", data: { mode: "guardian_only" } }` | PostRegistrationService.completeGuardianOnly() | `src/post-registration/post-registration.controller.ts` |
| POST | `/api/v1/users/:userId/post-registration/step-3/consent-evidence` | JWT | Scope `consent:evidence` (solo tutor actuando); `@SkipPermissions`; throttle 20/hora | Fase 3a. El tutor que actúa por el menor sube la ficha de consentimiento firmada sin salir del modo actuar (multipart `file`). Ver contrato abajo | PostRegistrationService.uploadConsentEvidence() | `src/post-registration/post-registration.controller.ts` |
| POST | `/api/v1/users/:userId/post-registration/membership-request/cancel` | JWT | Permisos: registration:complete | Cancelar solicitud pendiente de membresía | PostRegistrationService.cancelPendingMembershipRequest() | `src/post-registration/post-registration.controller.ts` |

##### `POST /api/v1/users/:userId/post-registration/step-3/consent-evidence`

> Perfiles familiares, Fase 3a, rama `feat/family-profiles-phase3`, Pendiente de merge (PR #531 de sacdia-backend). Cierra el residual aceptado nº 2 de la Fase 2 (el tutor tenía que salir del modo actuar para subir la ficha).

- Solo con `kind = guardian_acting` y `:userId` igual al menor por el que actúa; si no, 403 (un adolescente o un dispositivo vinculado: 403 `PRINCIPAL_SCOPE_DENIED`). El tutor sale de `actor_sub` y la tutoría sale del **principal** (`guardianship_id`), nunca del cuerpo ni de la ruta: un cuerpo que nombre otra tutoría se ignora.
- Mismas reglas de archivo y de fallo cerrado que la subida del tutor (`POST /guardianships/me/dependents/:dependentId/consent-evidence`): JPEG, PNG, WebP o PDF, 10 MB, bytes mágicos, HEIC rechazado, una ficha vigente por tutoría, 20 por hora compartidas con la ruta del tutor. `uploaded_by_user_id` es el tutor.
- 201 `{ evidence_id, content_type, size_bytes, uploaded_at }`. Errores: 403 `ACTING_FOR_SCOPE_DENIED`; 409 `GUARDIANSHIP_CONSENT_ALREADY_VERIFIED`; 503 `GUARDIANSHIP_EVIDENCE_UNAVAILABLE` sin bucket; 400 `FILE_*`; 429. La auditoría guarda al tutor como actor y al menor como objetivo.

##### `POST /api/v1/users/:userId/post-registration/step-3/guardian-only`

> Perfiles familiares, rama `feat/family-profiles`, Pendiente de merge (PR #530 de sacdia-backend).

Body opcional (todos los campos pueden omitirse): `{ "country_id": 1, "union_id": 2, "local_field_id": 3 }`. Si llegan, se guardan en el usuario. No exige que ya exista un dependiente: el tutor puede cerrar su post-registro antes de añadir menores.

- **Efecto**: marca `users_pr.club_selection_complete`, `complete` y `date_completed`, sube la versión del contexto de autorización y limpia su caché. No crea solicitud de club.
- **Solo el propio usuario**: `:userId` distinto del que llama (incluido un admin) → 400 `POST_REG_NOT_INITIATED`.
- **Solo adultos con cuenta**: necesita una fila `account` (un dependiente nunca la tiene), `birthday` y edad igual o mayor que la mayoría de edad del país (la del `country_id` del body, o la del usuario) → si no, 422 `POST_REG_GUARDIAN_ONLY_REQUIRES_ADULT`. Sin `users_pr` → 400 `POST_REG_NOT_INITIATED`.
- **Nunca actuando**: no declara `@ActingScope` y está en la lista de rutas sin scope, así que con `X-Acting-For` responde 403 `ACTING_FOR_SCOPE_DENIED`: un tutor que actúa por un menor no puede cerrar el post-registro del propio tutor.

### qr

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/qr/member/token` | JWT | Scope `credential:read` (Fase 3a) | Issue a short-lived QR token for the authenticated member. Un adolescente pendiente o una edad desconocida: 403 `PRINCIPAL_SCOPE_DENIED` | QrService.generateMemberToken() | `src/qr/qr.controller.ts` |
| GET | `/api/v1/qr/me` | JWT | Scope `credential:read` (Fase 3a) | Get the authenticated user QR metadata. Un adolescente pendiente o una edad desconocida: 403 `PRINCIPAL_SCOPE_DENIED` | QrService.getMyQr() | `src/qr/qr.controller.ts` |
| GET | `/api/v1/qr/me/card` | JWT | Scope `credential:read` (Fase 3a) | Get the QR card payload for the authenticated user. Un adolescente pendiente o una edad desconocida: 403 `PRINCIPAL_SCOPE_DENIED` | QrService.getMyCard() | `src/qr/qr.controller.ts` |
| GET | `/api/v1/qr/me/card.pdf` | JWT | Scope `credential:read` (Fase 3a) | Generate a PDF version of the authenticated user QR card. Un adolescente pendiente o una edad desconocida: 403 `PRINCIPAL_SCOPE_DENIED` | QrService.generateMyCardPdf() | `src/qr/qr.controller.ts` |
| POST | `/api/v1/qr/validate` | JWT | Permisos: qr:validate | Validate a scanned QR token with the canonical QR contract | QrService.validateMemberQr() | `src/qr/qr.controller.ts` |
| POST | `/api/v1/qr/scan` | JWT | Permisos: attendance:manage | Legacy alias for QR validation + attendance capture | QrService.scanMemberToken() | `src/qr/qr.controller.ts` |

**Scope `credential:read` (Fase 3a)**: las cuatro rutas `GET /qr/me*` y `GET /qr/member/token` llevan `@ActingScope('credential:read')` (antes `self:read`). La tienen el adolescente **activo**, el tutor actuando y el dispositivo vinculado; un adolescente sin tutor verificado y una edad desconocida reciben 403 `PRINCIPAL_SCOPE_DENIED`, también con una asignación de club activa anterior al despliegue (decisión y salida en «Sin datos de club ni credencial hasta que haya un tutor verificado»). **Residual conocido**: un token QR emitido antes de que el adolescente pasara a pendiente (TTL de 24 h, `QR_MEMBER_TTL_SECONDS`, `src/qr/qr.service.ts:35`) sigue validándose en `POST /qr/validate|scan` hasta que caduca; la validación solo comprueba la firma, el `sub` y al miembro, no el principal del portador.

`GET /qr/me/card` incluye en `member` el campo local (`local_field_name`), la unión (`union_name`) y el año eclesiástico vigente (`ecclesiastical_year`, año calendario en `America/Mexico_City`). Ese año es la vigencia de la credencial. `expires_at` sigue siendo solo la caducidad del token QR.

### quarterly-reports

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/quarterly-reports` | JWT | Permisos: reports:read | Listar informes trimestrales (admin) | QuarterlyReportsService.listForAdmin() | `src/quarterly-reports/quarterly-reports.controller.ts` |
| GET | `/api/v1/admin/quarterly-reports/:id` | JWT | Permisos: reports:read | Obtener informe trimestral por ID (admin) | QuarterlyReportsService.getReport() | `src/quarterly-reports/quarterly-reports.controller.ts` |
| PATCH | `/api/v1/admin/quarterly-reports/:id` | JWT | Permisos: reports:update | Actualizar datos manuales del informe trimestral (admin) | QuarterlyReportsService.updateManualData() | `src/quarterly-reports/quarterly-reports.controller.ts` |
| POST | `/api/v1/admin/quarterly-reports/:id/regenerate` | JWT | Permisos: reports:update | Regenerar datos calculados del informe trimestral (admin) | QuarterlyReportsService.regenerate() | `src/quarterly-reports/quarterly-reports.controller.ts` |
| POST | `/api/v1/admin/quarterly-reports/:id/finalize` | JWT | Permisos: reports:update | Finalizar informe trimestral (admin) | QuarterlyReportsService.finalize() | `src/quarterly-reports/quarterly-reports.controller.ts` |
| GET | `/api/v1/admin/quarterly-reports/:id/pdf` | JWT | Permisos: reports:download | Descargar PDF trimestral. Nombre: `informe-trimestral-{club}-{tipo}-{trimestre}-{año}.pdf` | QuarterlyReportsPdfService.generatePdf() | `src/quarterly-reports/quarterly-reports.controller.ts` |
| GET | `/api/v1/clubs/:clubId/quarterly-reports` | JWT | Permisos: reports:read | Listar informes trimestrales de un club (usuario) | QuarterlyReportsService.listForClub() | `src/quarterly-reports/quarterly-reports.controller.ts` |
| GET | `/api/v1/clubs/:clubId/quarterly-reports/:id` | JWT | Permisos: reports:read | Obtener informe trimestral por ID (usuario) | QuarterlyReportsService.getReport() | `src/quarterly-reports/quarterly-reports.controller.ts` |
| GET | `/api/v1/clubs/:clubId/quarterly-reports/:id/pdf` | JWT | Permisos: reports:download | Descargar PDF trimestral. Nombre: `informe-trimestral-{club}-{tipo}-{trimestre}-{año}.pdf` | QuarterlyReportsPdfService.generatePdf() | `src/quarterly-reports/quarterly-reports.controller.ts` |

### Ranking Weights

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/ranking-weights` | JWT | Permisos: ranking_weights:read | List all ranking weight configs | RankingWeightsService.list() | `src/ranking-weights/ranking-weights.controller.ts` |
| GET | `/api/v1/ranking-weights/:id` | JWT | Permisos: ranking_weights:read | Get a single ranking weight config by UUID | RankingWeightsService.getById() | `src/ranking-weights/ranking-weights.controller.ts` |
| POST | `/api/v1/ranking-weights` | JWT | Permisos: ranking_weights:write | Create a club-type ranking weight override | RankingWeightsService.create() | `src/ranking-weights/ranking-weights.controller.ts` |
| PATCH | `/api/v1/ranking-weights/:id` | JWT | Permisos: ranking_weights:write | Partially update a ranking weight config | RankingWeightsService.update() | `src/ranking-weights/ranking-weights.controller.ts` |
| DELETE | `/api/v1/ranking-weights/:id` | JWT | Permisos: ranking_weights:write | Delete a ranking weight override | RankingWeightsService.delete() | `src/ranking-weights/ranking-weights.controller.ts` |

### Annual Ranking Configs

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/annual-ranking-configs` | JWT | Permisos: ranking_weights:read | List annual ranking point budgets | AnnualRankingConfigService.list() | `src/rankings/annual-ranking-progress/annual-ranking-config.controller.ts` |
| POST | `/api/v1/annual-ranking-configs` | JWT | Permisos: ranking_weights:write | Create an annual ranking point budget | AnnualRankingConfigService.create() | `src/rankings/annual-ranking-progress/annual-ranking-config.controller.ts` |
| PATCH | `/api/v1/annual-ranking-configs/:id` | JWT | Permisos: ranking_weights:write | Update an annual ranking point budget | AnnualRankingConfigService.update() | `src/rankings/annual-ranking-progress/annual-ranking-config.controller.ts` |
| DELETE | `/api/v1/annual-ranking-configs/:id` | JWT | Permisos: ranking_weights:write | Deactivate an annual ranking point budget | AnnualRankingConfigService.deactivate() | `src/rankings/annual-ranking-progress/annual-ranking-config.controller.ts` |

### Annual Ranking Progress

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/club-sections/:sectionId/annual-ranking-progress` | JWT | Permisos: rankings:read, rankings:read_lf, rankings:read_global, section_rankings:read_club, section_rankings:read_lf, section_rankings:read_global (any) | Get annual ranking progress for one club section | AnnualRankingProgressService.getSectionProgress() | `src/rankings/annual-ranking-progress/annual-ranking-progress.controller.ts` |

### Annual Rankings

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/annual-rankings` | JWT | Permisos: rankings:read | List annual club rankings for administration | AnnualRankingsService.getLeaderboard() | `src/rankings/annual-ranking-progress/annual-rankings.controller.ts` |

### Ranking Tiers

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/ranking-tiers` | JWT | Permisos: ranking_weights:read | List active ranking recognition tiers | RankingTiersService.listActive() | `src/rankings/annual-ranking-progress/ranking-tiers.controller.ts` |
| PATCH | `/api/v1/ranking-tiers/:id` | JWT | Permisos: ranking_weights:write | Update a ranking recognition tier | RankingTiersService.update() | `src/rankings/annual-ranking-progress/ranking-tiers.controller.ts` |

### Member Ranking Weights

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/member-ranking-weights` | JWT | Global: admin, super-admin; Permisos: member_ranking_weights:read | List all ranking weight configurations (admin) | MemberRankingWeightsService.list() | `src/rankings/member-ranking-weights/member-ranking-weights.controller.ts` |
| POST | `/api/v1/member-ranking-weights` | JWT | Global: admin, super-admin; Permisos: member_ranking_weights:write | Create a ranking weight configuration (admin) | MemberRankingWeightsService.create() | `src/rankings/member-ranking-weights/member-ranking-weights.controller.ts` |
| GET | `/api/v1/member-ranking-weights/:id` | JWT | Global: admin, super-admin; Permisos: member_ranking_weights:read | Get a ranking weight configuration by ID (admin) | MemberRankingWeightsService.findOne() | `src/rankings/member-ranking-weights/member-ranking-weights.controller.ts` |
| PATCH | `/api/v1/member-ranking-weights/:id` | JWT | Global: admin, super-admin; Permisos: member_ranking_weights:write | Update a ranking weight configuration (admin) | MemberRankingWeightsService.update() | `src/rankings/member-ranking-weights/member-ranking-weights.controller.ts` |
| DELETE | `/api/v1/member-ranking-weights/:id` | JWT | Global: admin, super-admin; Permisos: member_ranking_weights:write | Delete a ranking weight configuration (admin) | MemberRankingWeightsService.remove() | `src/rankings/member-ranking-weights/member-ranking-weights.controller.ts` |

### Member Rankings

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/member-rankings/me` | JWT | Permisos: member_rankings:read_self | Get the calling member own ranking | MemberRankingsService.getMyRanking() | `src/rankings/member-rankings/member-rankings.controller.ts` |
| POST | `/api/v1/member-rankings/recalculate` | JWT | Permisos: member_ranking_weights:write | Encola recálculo member + section (y club). Responde al encolar. | MemberRankingsService.triggerRecalculate() | `src/rankings/member-rankings/member-rankings.controller.ts` |
| GET | `/api/v1/member-rankings/:enrollmentId/breakdown` | JWT | Permisos: member_rankings:read_self, member_rankings:read_section, member_rankings:read_club, member_rankings:read_lf, member_rankings:read_global (any) | Get score breakdown for a specific enrollment | MemberRankingsService.getBreakdown() | `src/rankings/member-rankings/member-rankings.controller.ts` |
| GET | `/api/v1/member-rankings` | JWT | Permisos: member_rankings:read_self, member_rankings:read_section, member_rankings:read_club, member_rankings:read_lf, member_rankings:read_global (any) | List member rankings (paginated, RBAC scope-filtered) | MemberRankingsService.list() | `src/rankings/member-rankings/member-rankings.controller.ts` |

### Section Rankings

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/section-rankings/:sectionId/members` | JWT | Permisos: section_rankings:read_club, section_rankings:read_lf, section_rankings:read_global (any) | Get members for a specific section ordered by rank_position ASC NULLS LAST | SectionRankingsService.getMembers() | `src/rankings/section-rankings/section-rankings.controller.ts` |
| GET | `/api/v1/section-rankings` | JWT | Permisos: section_rankings:read_club, section_rankings:read_lf, section_rankings:read_global (any) | List section rankings (paginated, RBAC scope-filtered) | SectionRankingsService.list() | `src/rankings/section-rankings/section-rankings.controller.ts` |

### rbac

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/rbac/permissions` | JWT | Permisos: permissions:read | Listar todos los permisos | RbacService.listPermissions() | `src/rbac/rbac.controller.ts` |
| GET | `/api/v1/admin/rbac/permissions/:id` | JWT | Permisos: permissions:read | Obtener un permiso por ID | RbacService.getPermissionById() | `src/rbac/rbac.controller.ts` |
| POST | `/api/v1/admin/rbac/permissions` | JWT | Global: super-admin; Permisos: permissions:assign | Crear un nuevo permiso | RbacService.createPermission() | `src/rbac/rbac.controller.ts` |
| PATCH | `/api/v1/admin/rbac/permissions/:id` | JWT | Global: super-admin; Permisos: permissions:assign | Actualizar un permiso | RbacService.updatePermission() | `src/rbac/rbac.controller.ts` |
| DELETE | `/api/v1/admin/rbac/permissions/:id` | JWT | Global: super-admin; Permisos: permissions:assign | Desactivar un permiso | RbacService.deletePermission() | `src/rbac/rbac.controller.ts` |
| GET | `/api/v1/admin/rbac/roles` | JWT | Permisos: roles:read | Listar roles con sus permisos | RbacService.listRoles() | `src/rbac/rbac.controller.ts` |
| GET | `/api/v1/admin/rbac/roles/:id` | JWT | Permisos: roles:read | Obtener rol con sus permisos | RbacService.getRoleWithPermissions() | `src/rbac/rbac.controller.ts` |
| POST | `/api/v1/admin/rbac/roles` | JWT | Global: super-admin | Crear un nuevo rol | RbacService.createRole() | `src/rbac/rbac.controller.ts` |
| PATCH | `/api/v1/admin/rbac/roles/:id` | JWT | Global: super-admin | Actualizar descripción y/o permisos de un rol | RbacService.updateRole() | `src/rbac/rbac.controller.ts` |
| DELETE | `/api/v1/admin/rbac/roles/:id` | JWT | Global: super-admin | Desactivar (soft delete) un rol | RbacService.deactivateRole() | `src/rbac/rbac.controller.ts` |
| POST | `/api/v1/admin/rbac/roles/:id/permissions` | JWT | Global: super-admin; Permisos: permissions:assign | Asignar permisos a un rol | RbacService.assignPermissionsToRole() | `src/rbac/rbac.controller.ts` |
| PUT | `/api/v1/admin/rbac/roles/:id/permissions` | JWT | Global: super-admin; Permisos: permissions:assign | Sincronizar permisos de un rol (reemplaza todos) | RbacService.syncRolePermissions() | `src/rbac/rbac.controller.ts` |
| DELETE | `/api/v1/admin/rbac/roles/:id/permissions/:permissionId` | JWT | Global: super-admin; Permisos: permissions:assign | Remover un permiso de un rol | RbacService.removePermissionFromRole() | `src/rbac/rbac.controller.ts` |
| GET | `/api/v1/admin/rbac/users/:userId/permissions` | JWT | Permisos: permissions:read | Listar permisos directos de un usuario | RbacService.getUserPermissions() | `src/rbac/rbac.controller.ts` |
| POST | `/api/v1/admin/rbac/users/:userId/permissions` | JWT | Global: super-admin; Permisos: permissions:assign | Asignar un permiso directo a un usuario | RbacService.assignPermissionToUser() | `src/rbac/rbac.controller.ts` |
| DELETE | `/api/v1/admin/rbac/users/:userId/permissions/:permissionId` | JWT | Global: super-admin; Permisos: permissions:assign | Remover un permiso directo de un usuario | RbacService.removePermissionFromUser() | `src/rbac/rbac.controller.ts` |
| GET | `/api/v1/admin/rbac/users/:userId/roles` | JWT | Global: admin, super-admin | Listar roles asignados a un usuario | RbacService.getUserRoles() | `src/rbac/rbac.controller.ts` |
| POST | `/api/v1/admin/rbac/users/:userId/roles` | JWT | Global: admin, super-admin | Asignar un rol a un usuario | RbacService.assignRoleToUser() | `src/rbac/rbac.controller.ts` |
| DELETE | `/api/v1/admin/rbac/users/:userId/roles/:roleId` | JWT | Global: admin, super-admin | Remover un rol de un usuario | RbacService.removeRoleFromUser() | `src/rbac/rbac.controller.ts` |

### rbac-bootstrap

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/admin/rbac/bootstrap-admin` | Public | - | Crear el primer super-admin (solo funciona si no existe ninguno) | ConfigService.get(), RbacService.bootstrapAdmin() | `src/rbac/rbac.controller.ts` |

### requests

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/requests/transfers` | JWT | Permisos: requests:read | Crear solicitud de transferencia | RequestsService.createTransferRequest() | `src/requests/requests.controller.ts` |
| GET | `/api/v1/requests/transfers` | JWT | Permisos: requests:read | Listar solicitudes de transferencia | RequestsService.getTransferRequests() | `src/requests/requests.controller.ts` |
| GET | `/api/v1/requests/transfers/:requestId` | JWT | Permisos: requests:read | Obtener solicitud de transferencia | RequestsService.getTransferRequest() | `src/requests/requests.controller.ts` |
| POST | `/api/v1/requests/transfers/:requestId/review` | JWT | Permisos: requests:review | Revisar solicitud de transferencia. Al **aprobar**, la membresía activa pasa a otra sección y se aplica la compuerta de consentimiento: un menor sin consentimiento verificado → 409 `MR_CONSENT_NOT_VERIFIED` (ver `membership-requests`) | RequestsService.reviewTransfer() | `src/requests/requests.controller.ts` |
| POST | `/api/v1/requests/assignments` | JWT | Permisos: requests:review | Crear solicitud de asignación de rol | RequestsService.createAssignmentRequest() | `src/requests/requests.controller.ts` |
| GET | `/api/v1/requests/assignments` | JWT | Permisos: requests:read | Listar solicitudes de asignación de rol | RequestsService.getAssignmentRequests() | `src/requests/requests.controller.ts` |
| GET | `/api/v1/requests/assignments/:requestId` | JWT | Permisos: requests:read | Obtener solicitud de asignación de rol | RequestsService.getAssignmentRequest() | `src/requests/requests.controller.ts` |
| POST | `/api/v1/requests/assignments/:requestId/review` | JWT | Permisos: requests:review | Revisar solicitud de asignación de rol. Al **aprobar** se crea la asignación activa y se aplica la compuerta de consentimiento: un menor sin consentimiento verificado → 409 `MR_CONSENT_NOT_VERIFIED` (ver `membership-requests`) | RequestsService.reviewAssignment() | `src/requests/requests.controller.ts` |

### resource-categories

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/resource-categories` | JWT | Permisos: resource_categories:create | Crear categoría de recurso | ResourceCategoriesService.create() | `src/resources/resource-categories.controller.ts` |
| GET | `/api/v1/resource-categories` | JWT | Permisos: resource_categories:read | Listar categorías de recursos activas (Redis TTL 1h) | ResourceCategoriesService.findAll() | `src/resources/resource-categories.controller.ts` |
| GET | `/api/v1/resource-categories/:id` | JWT | Permisos: resource_categories:read | Obtener categoría de recurso por ID | ResourceCategoriesService.findOne() | `src/resources/resource-categories.controller.ts` |
| PATCH | `/api/v1/resource-categories/:id` | JWT | Permisos: resource_categories:update | Actualizar categoría de recurso | ResourceCategoriesService.update() | `src/resources/resource-categories.controller.ts` |
| DELETE | `/api/v1/resource-categories/:id` | JWT | Permisos: resource_categories:delete | Desactivar categoría de recurso (soft delete) | ResourceCategoriesService.remove() | `src/resources/resource-categories.controller.ts` |

### Resources (App)

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/resources/me` | JWT | - | Mis recursos | AuthorizationContextService.resolveUserAuthorization(), ResourcesService.getVisibleResources() | `src/resources/resources-app.controller.ts` |
| GET | `/api/v1/resources/me/:id` | JWT | - | Obtener recurso visible | AuthorizationContextService.resolveUserAuthorization(), ResourcesService.findOneVisible() | `src/resources/resources-app.controller.ts` |
| GET | `/api/v1/resources/me/:id/signed-url` | JWT | - | Obtener URL firmada (app) | AuthorizationContextService.resolveUserAuthorization(), ResourcesService.getVisibleSignedUrl() | `src/resources/resources-app.controller.ts` |

### Resources

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/resources` | JWT | Permisos: resources:create | Crear recurso | ResourcesService.create() | `src/resources/resources.controller.ts` |
| POST | `/api/v1/resources/upload-url` | JWT | Permisos: resources:create | Generar URL firmada para subir un recurso directo a R2 | ResourcesService.generateUploadUrl() | `src/resources/resources.controller.ts` |
| POST | `/api/v1/resources/from-uploaded` | JWT | Permisos: resources:create | Crear recurso desde archivo ya subido a R2 (presigned flow) | ResourcesService.createFromUploaded() | `src/resources/resources.controller.ts` |
| GET | `/api/v1/resources` | JWT | Permisos: resources:read | Listar recursos | ResourcesService.findAll() | `src/resources/resources.controller.ts` |
| GET | `/api/v1/resources/:id` | JWT | Permisos: resources:read | Obtener recurso | ResourcesService.findOne() | `src/resources/resources.controller.ts` |
| GET | `/api/v1/resources/:id/signed-url` | JWT | Permisos: resources:read | Obtener URL firmada | ResourcesService.getSignedUrl() | `src/resources/resources.controller.ts` |
| PATCH | `/api/v1/resources/:id` | JWT | Permisos: resources:update | Actualizar recurso | ResourcesService.update() | `src/resources/resources.controller.ts` |
| DELETE | `/api/v1/resources/:id` | JWT | Permisos: resources:delete | Eliminar recurso | ResourcesService.remove() | `src/resources/resources.controller.ts` |

### scoring-categories

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/divisions/scoring-categories` | JWT | Permisos: scoring_categories:read; Global: admin, super-admin | Listar categorías de puntuación a nivel división | ScoringCategoriesService.findDivisionCategories() | `src/scoring-categories/scoring-categories.controller.ts` |
| POST | `/api/v1/divisions/scoring-categories` | JWT | Permisos: scoring_categories:manage; Global: admin, super-admin | Crear categoría de puntuación a nivel división | ScoringCategoriesService.createDivisionCategory() | `src/scoring-categories/scoring-categories.controller.ts` |
| PATCH | `/api/v1/divisions/scoring-categories/:id` | JWT | Permisos: scoring_categories:manage; Global: admin, super-admin | Actualizar categoría de puntuación a nivel división | ScoringCategoriesService.updateDivisionCategory() | `src/scoring-categories/scoring-categories.controller.ts` |
| DELETE | `/api/v1/divisions/scoring-categories/:id` | JWT | Permisos: scoring_categories:manage; Global: admin, super-admin | Desactivar categoría de puntuación a nivel división (soft delete) | ScoringCategoriesService.deleteDivisionCategory() | `src/scoring-categories/scoring-categories.controller.ts` |
| GET | `/api/v1/unions/:unionId/scoring-categories` | JWT | Permisos: scoring_categories:read | Listar categorías de puntuación para una unión (heredadas + propias) | ScoringCategoriesService.findUnionCategories() | `src/scoring-categories/scoring-categories.controller.ts` |
| POST | `/api/v1/unions/:unionId/scoring-categories` | JWT | Permisos: scoring_categories:manage | Crear categoría de puntuación para una unión | ScoringCategoriesService.createUnionCategory() | `src/scoring-categories/scoring-categories.controller.ts` |
| PATCH | `/api/v1/unions/:unionId/scoring-categories/:id` | JWT | Permisos: scoring_categories:manage | Actualizar categoría de puntuación propia de una unión | ScoringCategoriesService.updateUnionCategory() | `src/scoring-categories/scoring-categories.controller.ts` |
| DELETE | `/api/v1/unions/:unionId/scoring-categories/:id` | JWT | Permisos: scoring_categories:manage | Desactivar categoría de puntuación propia de una unión (soft delete) | ScoringCategoriesService.deleteUnionCategory() | `src/scoring-categories/scoring-categories.controller.ts` |
| GET | `/api/v1/local-fields/:fieldId/scoring-categories` | JWT | Permisos: scoring_categories:read | Listar categorías de puntuación activas para un campo local (división + unión + propias) | ScoringCategoriesService.findLocalFieldCategories() | `src/scoring-categories/scoring-categories.controller.ts` |
| POST | `/api/v1/local-fields/:fieldId/scoring-categories` | JWT | Permisos: scoring_categories:manage | Crear categoría de puntuación para un campo local | ScoringCategoriesService.createLocalFieldCategory() | `src/scoring-categories/scoring-categories.controller.ts` |
| PATCH | `/api/v1/local-fields/:fieldId/scoring-categories/:id` | JWT | Permisos: scoring_categories:manage | Actualizar categoría de puntuación propia de un campo local | ScoringCategoriesService.updateLocalFieldCategory() | `src/scoring-categories/scoring-categories.controller.ts` |
| DELETE | `/api/v1/local-fields/:fieldId/scoring-categories/:id` | JWT | Permisos: scoring_categories:manage | Desactivar categoría de puntuación propia de un campo local (soft delete) | ScoringCategoriesService.deleteLocalFieldCategory() | `src/scoring-categories/scoring-categories.controller.ts` |

### admin-support

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/admin/support/reports` | JWT | Global: admin, coordinator (alias: zone/general + director-lf/assistant-lf; LF recorta a local_field) | Listar reportes de soporte | SupportService.listReports() | `src/support/support-admin.controller.ts` |
| GET | `/api/v1/admin/support/reports/:reportId` | JWT | Global: admin, coordinator (alias: zone/general + director-lf/assistant-lf; LF recorta a local_field) | Obtener detalle de un reporte de soporte | SupportService.getReport() | `src/support/support-admin.controller.ts` |
| PATCH | `/api/v1/admin/support/reports/:reportId/status` | JWT | Global: admin, coordinator (alias: zone/general + director-lf/assistant-lf; LF recorta a local_field) | Actualizar estado de un reporte de soporte | SupportService.updateReportStatus() | `src/support/support-admin.controller.ts` |

### support

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/support/reports` | JWT | - | Create a new support report | SupportService.createReport() | `src/support/support.controller.ts` |

### system-config

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/system-config` | JWT | Global: admin, super-admin | Listar todas las configuraciones del sistema | SystemConfigService.findAll() | `src/system-config/system-config.controller.ts` |
| GET | `/api/v1/system-config/:key` | JWT | Global: admin, super-admin | Obtener una configuracion por clave | SystemConfigService.findByKey() | `src/system-config/system-config.controller.ts` |
| PATCH | `/api/v1/system-config/:key` | JWT | Global: admin, super-admin | Actualizar una configuracion del sistema | SystemConfigService.updateByKey() | `src/system-config/system-config.controller.ts` |

### units

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/clubs/:clubId/units` | JWT | Permisos: units:read | Listar unidades del club | UnitsService.findByClub() | `src/units/units.controller.ts` |
| POST | `/api/v1/clubs/:clubId/units` | JWT | Permisos: units:create | Crear unidad en el club | UnitsService.create() | `src/units/units.controller.ts` |
| GET | `/api/v1/clubs/:clubId/units/:unitId` | JWT | Permisos: units:read | Obtener detalle de una unidad con miembros | UnitsService.findOne() | `src/units/units.controller.ts` |
| PATCH | `/api/v1/clubs/:clubId/units/:unitId` | JWT | Permisos: units:update | Actualizar unidad | UnitsService.update() | `src/units/units.controller.ts` |
| DELETE | `/api/v1/clubs/:clubId/units/:unitId` | JWT | Permisos: units:delete | Desactivar unidad (soft delete) | UnitsService.remove() | `src/units/units.controller.ts` |
| POST | `/api/v1/clubs/:clubId/units/:unitId/members` | JWT | Permisos: units:update | Agregar miembro a la unidad | UnitsService.addMember() | `src/units/units.controller.ts` |
| DELETE | `/api/v1/clubs/:clubId/units/:unitId/members/:memberId` | JWT | Permisos: units:update | Remover miembro de la unidad (soft delete) | UnitsService.removeMember() | `src/units/units.controller.ts` |
| GET | `/api/v1/clubs/:clubId/units/:unitId/weekly-records` | JWT | Permisos: units:read | Listar registros semanales de la unidad | UnitsService.findWeeklyRecords() | `src/units/units.controller.ts` |
| POST | `/api/v1/clubs/:clubId/units/:unitId/weekly-records` | JWT | Permisos: units:update | Crear registro semanal (solo semana vigente domingo–sábado, hora México) | UnitsService.createWeeklyRecord() | `src/units/units.controller.ts` |
| POST | `/api/v1/clubs/:clubId/units/:unitId/weekly-records/bulk` | JWT | Permisos: units:update | Crear o actualizar registros semanales de forma atómica (semana vigente domingo–sábado, hora México) | UnitsService.bulkUpsertWeeklyRecords() | `src/units/units.controller.ts` |
| PATCH | `/api/v1/clubs/:clubId/units/:unitId/weekly-records/:recordId` | JWT | Permisos: units:update | Actualizar registro semanal (solo si pertenece a la semana vigente) | UnitsService.updateWeeklyRecord() | `src/units/units.controller.ts` |

### users

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/users/:userId` | JWT | Permisos: users:read_detail | Obtener información de un usuario | UsersService.findOne() | `src/users/users.controller.ts` |
| GET | `/api/v1/users/:userId/allergies` | JWT | - | Obtener alergias activas del usuario | UsersService.getAllergies() | `src/users/users.controller.ts` |
| GET | `/api/v1/users/:userId/diseases` | JWT | - | Obtener enfermedades activas del usuario | UsersService.getDiseases() | `src/users/users.controller.ts` |
| GET | `/api/v1/users/:userId/medicines` | JWT | - | Obtener medicamentos activos del usuario | UsersService.getMedicines() | `src/users/users.controller.ts` |
| PATCH | `/api/v1/users/:userId` | JWT | Permisos: users:update_profile | Actualizar información personal del usuario. Si quien edita es el propio titular de una cuenta y la nueva `birthday` lo deja por debajo de la edad mínima de cuenta de su país → 422 `USER_SELF_ACCOUNT_BELOW_MINIMUM_AGE` (ver «Edad mínima de la cuenta»). Actuando por un menor (scope `profile:write`) y las ediciones de admin no pasan por esa regla. Fase 3a: un adolescente (`supervised_user`) que cambia su propia `birthday` → 422 `USER_BIRTHDAY_CHANGE_REQUIRES_GUARDIAN`; cualquier cambio de fecha sube el `epoch`, y un titular de cuenta que entra al rango 13-17 recibe su fila `supervised_logins` (`self_registered`, `pending_since = now`) | UsersService.update() | `src/users/users.controller.ts` |
| PUT | `/api/v1/users/:userId/allergies` | JWT | - | Guardar alergias del usuario | UsersService.updateAllergies() | `src/users/users.controller.ts` |
| PUT | `/api/v1/users/:userId/diseases` | JWT | - | Guardar enfermedades del usuario | UsersService.updateDiseases() | `src/users/users.controller.ts` |
| PUT | `/api/v1/users/:userId/medicines` | JWT | - | Guardar medicamentos del usuario | UsersService.updateMedicines() | `src/users/users.controller.ts` |
| DELETE | `/api/v1/users/:userId/allergies/:allergyId` | JWT | - | Eliminar alergia del usuario (borrado lógico) | UsersService.removeAllergy() | `src/users/users.controller.ts` |
| DELETE | `/api/v1/users/:userId/diseases/:diseaseId` | JWT | - | Eliminar enfermedad del usuario (borrado lógico) | UsersService.removeDisease() | `src/users/users.controller.ts` |
| DELETE | `/api/v1/users/:userId/medicines/:medicineId` | JWT | - | Eliminar medicamento del usuario (borrado lógico) | UsersService.removeMedicine() | `src/users/users.controller.ts` |
| POST | `/api/v1/users/:userId/profile-picture` | JWT | Permisos: users:update_profile | Subir foto de perfil | UsersService.uploadProfilePicture() | `src/users/users.controller.ts` |
| DELETE | `/api/v1/users/:userId/profile-picture` | JWT | Permisos: users:update_profile | Eliminar foto de perfil | UsersService.deleteProfilePicture() | `src/users/users.controller.ts` |
| GET | `/api/v1/users/:userId/age` | JWT | Permisos: users:read_detail | Calcular edad del usuario | UsersService.calculateAge() | `src/users/users.controller.ts` |
| GET | `/api/v1/users/:userId/requires-legal-representative` | JWT | Permisos: users:read_detail | **Deprecado**: los representantes legales son de solo lectura y los reemplazan las tutorías. Verificar si el usuario es menor de edad según la mayoría de edad de su país (`countries.age_of_majority`, 18 por defecto); la respuesta ya no dice «18» fijo | UsersService.calculateAge(), UsersService.requiresLegalRepresentative() | `src/users/users.controller.ts` |

### validation

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/v1/validation/submit` | JWT | Permisos: validation:submit | Enviar clase/honor a revision. Con `entity_type` `class`: 410 `INVESTITURE_LEGACY_PIPELINE_RETIRED` (fase 8) sin leer ni escribir. Sin el permiso `validation:submit` la respuesta es 403 antes que ese 410. El honor no cambia. | ValidationService.submitForReview() | `src/validation/validation.controller.ts` |
| POST | `/api/v1/validation/:entityType/:entityId/review` | JWT | Permisos: validation:review | Aprobar o rechazar clase/honor. Con `class`, aprobar o rechazar, con o sin comentario: 410 `INVESTITURE_LEGACY_PIPELINE_RETIRED` (fase 8), sin escribir. Sin el permiso `validation:review` la respuesta es 403 antes que ese 410. El honor no cambia. | ValidationService.review() | `src/validation/validation.controller.ts` |
| GET | `/api/v1/validation/pending` | JWT | Permisos: validation:read | Listar items pendientes de revision. Desde la fase 8 `classes` siempre es `[]`: solo salen honores. | ValidationService.getPendingReviews() | `src/validation/validation.controller.ts` |
| GET | `/api/v1/validation/:entityType/:entityId/history` | JWT | Permisos: validation:read | Historial de validacion | ValidationService.getValidationHistory() | `src/validation/validation.controller.ts` |
| GET | `/api/v1/validation/eligibility/:userId` | JWT | Permisos: validation:read | Verificar elegibilidad para investidura | ValidationService.checkInvestmentEligibility() | `src/validation/validation.controller.ts` |

### year-end

| Method | Path | Auth | Roles/Permisos | Uso | Uso backend | Source |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/v1/year-end/:yearId/preview` | JWT | Global: admin, super-admin; Permisos: ecclesiastical_years:update | Vista previa del impacto de cierre de ano | YearEndService.previewClosureImpact() | `src/year-end/year-end.controller.ts` |
| POST | `/api/v1/year-end/:yearId/close` | JWT | Global: admin, super-admin; Permisos: ecclesiastical_years:update | Cierra el año. Además de inscripciones de club, carpetas e informes, deja en `CLOSED_YEAR` los pendientes de investidura de ese año. Presentar y agregar toman el candado del año antes que el de la sección y vuelven a leer el año: si el cierre ya dejó el año inactivo, no queda `PENDING`; si la alta escribe mientras espera, este cierre la incluye. No cambia `INVESTED`, no copia la solicitud al año siguiente y no escribe el texto de falta de requisitos. Un año ya inactivo responde `YEAR_END_YEAR_CLOSED`. El conteo va en `investiturePendingClosed`. | YearEndService.closeYear() | `src/year-end/year-end.controller.ts` |

## Nota de mantenimiento

- Si cambia un controller, regenerar esta referencia contra `sacdia-backend/src/**/*controller.ts`.
- No confiar en conteos editoriales antiguos: el conteo vigente debe salir del mismo extractor que produce esta tabla.
