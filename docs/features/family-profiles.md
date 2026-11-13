# Perfiles familiares (tutores y menores de 13 años)

**Estado**: IMPLEMENTADO PARCIAL (Fases 2 a 4 en `development`; la **Fase 4 (liberación a la mayoría de edad)** entró con backend #654, app #257 y admin #305 el 2026-11-13, detrás de `FAMILY_MAJORITY_RELEASE_ENABLED` y con los textos legales pendientes de aprobación; ver «Fase 4»). La Fase 2 entró con sacdia-backend #530, sacdia-app #178, sacdia-admin #243 y sacdia #141 (2026-10-19); la Fase 3, con sus tres sub-fases 3a (inicio de sesión supervisado), 3b (dispositivo vinculado) y 3c (el director registra menores, tarjeta de acceso familiar en el panel y cron de cambios de edad), con sacdia-backend #531, sacdia-app #179, sacdia-admin #244 y sacdia #142 (2026-10-20). No promovido a `main`. QA: 3a y 3b ejecutados en parte, 3c **Pendiente** (`docs/testing/FAMILY-PROFILES-PHASE3A-QA.md`, `...PHASE3B-QA.md`, `...PHASE3C-QA.md`); contrato: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`.
**Verificado contra código**: la sección «Fase 4» se verificó el 2026-11-12 contra el árbol de código de las ramas `feat/family-profiles-phase4` (backend `2dddd957`, app `d4133071`, admin `46906bd3`), integradas después en `development` con los PR #654, #257 y #305. El resto: 2026-10-19 (backend `554552c1`, app `819f257f`, admin `79a7b29`). La compuerta de activación, las reglas de cuatro ojos y el bloqueo de la ficha verificada se releyeron contra el backend `603d3d8e`. Segundo pase del mismo día contra backend `422433c0`, app `df2e6c6f` y admin `4a50314` (lista de parentescos del tutor, selector de club al actuar, `effective_expires_at` y los ajustes de la app y del panel). La sección «Fase 3» se verificó el 2026-10-20 contra backend `32022392`, app `345dadc0` y admin `7a9bfd6` (ramas `feat/family-profiles-phase3`)
**Dominios relacionados**: [auth.md](auth.md) (sesión y post-registro), [membership-requests.md](membership-requests.md) (aprobación de ingreso), [contactos-emergencia-representante-legal.md](contactos-emergencia-representante-legal.md) (representante legal, eliminado en la Fase 4), [rbac.md](rbac.md) (permisos sensibles), [qr-credencial.md](qr-credencial.md) (correo nulo en la tarjeta)

> [!IMPORTANT]
> **Restricción de lanzamiento (Fase 3)**: la Fase 2 **no** debe llegar a producción sin la Fase 3. La Fase 3 los cierra (ver «Fase 3») y ya está en `development`; siguen abiertos en cualquier ambiente al que no se haya promovido. Los dos huecos, que hoy solo existen en desarrollo: (1) un adolescente de 13 a 17 años que se registra solo no tiene tutor ni representante legal (las rutas de escritura del representante se retiraron y aún no hay inicio de sesión supervisado), y (2) puede existir brevemente una cuenta social de un menor de 13 años hasta que intente guardar su fecha de nacimiento. Detalle en «Fases y restricción de lanzamiento». La Fase 3 además **no se puede promover a `main` sin la aprobación del texto legal `2.0.0-family`** (`docs/legal/README.md`) ni sin la lista de `docs/deployment/DEPLOYMENT-GUIDE.md`, §0.6.

## Descripción de dominio

Un menor de 13 años (el corte depende del país) no puede tener cuenta propia. Antes se registraba solo y un `legal_representatives` no resistía el uso real (un representante por menor, representantes externos sin usuario, sin evidencia ni verificación). Ahora el **tutor adulto** es el titular de la cuenta: registra al menor como un **dependiente** (un perfil `users` sin cuenta de acceso ni correo), actúa por él con el mismo token del tutor y, para que el menor ingrese a un club, un **director verifica la ficha de consentimiento firmada en papel** antes de aprobar la solicitud.

No hay chat ni mensajería entre usuarios, ni ahora ni después. La app y el panel solo muestran quién responde por quién.

## Fases y restricción de lanzamiento

| Fase | Contenido | Estado |
|---|---|---|
| 1 | Aceptación legal de Términos y Aviso de Privacidad | Mergeada (backend #515, #516, #518; app #177; docs #139, #140) |
| 2 | Tutorías, perfiles dependientes, actuar en nombre del menor, verificación del director (esta página) | Implementada en rama; ver sub-fases abajo |
| 3 | Inicio de sesión supervisado de 13 a 17 años (**3a**), dispositivo vinculado del menor de 13 años con QR del tutor (**3b**), el director registra menores, panel de acceso familiar, cron de cambios de edad y avisos de seguridad y resúmenes para el tutor (**3c** y lo transversal) | **3a, 3b y 3c en `development` (sacdia-backend #531, sacdia-app #179 y sacdia-admin #244); QA de la 3c corrida el 2026-10-20. Bloquea el lanzamiento a producción** |
| 4 | Liberación a la mayoría de edad (cron `family-majority-release`), aceptación propia de los términos, congelamiento sin purga, reclamo de cuenta con código, renombre de permisos a `guardianship:*` y eliminación de `legal_representatives` | Integrada en `development` (backend #654, app #257, admin #305); todo detrás de `FAMILY_MAJORITY_RELEASE_ENABLED` y con los textos legales sin aprobar. Ver «Fase 4» |

La Fase 2 se entregó en tres sub-fases sobre **una rama y un PR por repo** (excepción de tamaño aprobada; los commits por unidad de trabajo son la mitigación de revisión): **2a** backend base y actuar-en-nombre, **2b** app (Mi familia, cambio de perfil, post-registro), **2c** verificación del director (backend, app y panel).

Huecos de la Fase 2 que la Fase 3 cierra (ya en `development`; siguen abiertos donde no se haya promovido):

- Un adolescente de 13 a 17 años que se registra por su cuenta no tiene tutoría y ya no puede registrar un representante legal. No hay cadena de consentimiento para él. **3a**: es un usuario supervisado, queda en modo pendiente de tutor y necesita un tutor con consentimiento verificado.
- Un dependiente que cumple 13 años **sigue gestionado por su tutor hasta la mayoría de edad**: actuar se corta por mayoría de edad, no por los 13 años. **3a** y **3c**: el tutor verificado puede darle acceso propio, y a los 13 años el cron avisa a sus tutores verificados.
- Una cuenta social (Google/Apple) de un menor de 13 años se crea sin pasar por `POST /auth/register`; solo la frena `PATCH /users/:userId` cuando guarda su fecha de nacimiento (paso 2 del post-registro). Decisión A4/A5. **3a**: una cuenta sin fecha de nacimiento y con el post-registro abierto queda restringida (`age_unknown_user`) hasta guardarla.
- No existía un flujo para que el director **cree** menores: los códigos de reclamo (`director_claim`) solo devuelven a una familia un menor que ya está bajo custodia del club. **3c**: `POST /club-sections/:clubSectionId/dependents`.

## Modelo de datos

Una migración, `20261016120000_family_profiles` (17 sentencias, sin DML, única `ALTER` a una tabla existente fuera de `countries`: `users.email DROP NOT NULL`). Detalle por columna en [SCHEMA-REFERENCE.md](../database/SCHEMA-REFERENCE.md), sección «Perfiles familiares».

| Concepto | Tabla / columna | Reglas clave |
|---|---|---|
| Dependiente | `users` sin fila `account`, `email` NULL, más `dependent_profiles` | Una fila por menor; guarda quién lo creó, `frozen_at`, `purge_after` y `purged_at`. Fase 4 (backend #654): suma `majority_notice_sent_at`, `released_at`, `release_deadline_at`, `release_source`, `release_accepted_at`, `release_completed_at`, `release_reminder_level` y `frozen_reason` |
| Tutoría | `guardianships` | Una fila por tutor (o por custodia de club) y menor; las revocadas se conservan como historial. Máximo 10 dependientes por tutor y 4 tutores activos por menor |
| Consentimiento | `guardianships.consent_status` | `pending`, `verified` o `revoked`. `verified` solo lo escribe la verificación de la ficha en papel (`director_paper_form` si verifica un director o un rol de club; `coordinator_paper_form` si verifica un coordinador por su asignación) o la promoción de un tutor invitado (`guardian_invite`) |
| Ficha firmada | `guardianship_consent_evidences` | Append-only; una sola vigente por tutoría; bucket privado de R2 |
| Código de vinculación | `guardianship_link_codes` | 8 caracteres Crockford (`XXXX-XXXX`), solo se guarda el hash HMAC; un solo uso |
| Política de edad por país | `countries.minor_self_login_min_age`, `age_of_majority`, `age_reference_timezone` | Valores por defecto 13, 18 y `America/Mexico_City` si el país es desconocido |

Tipos de tutoría:

- **Tutor con cuenta**: la fila normal. Uno es el **principal** (puede quitar a un secundario).
- **Custodia del club** (`is_custodian`): cuando el último tutor sale y el menor tiene una asignación `active` o `pending`, el club queda como titular de la fila. El club no es un usuario, así que "el custodio" no tiene identidad persistida (ver regla de cuatro ojos).
- **Tutor externo** (`external_name`): solo viene de importar `legal_representatives` con el script de desarrollo; no da acceso.
- **Datos de prueba** (`is_test_data`): nunca cuentan como consentimiento ni dan acceso.

Las tutorías reemplazan a `legal_representatives`. La Fase 4 (backend #654) eliminó el módulo, las rutas y el modelo Prisma; la tabla se borra de la base con la migración `20261114100000` (**Pendiente de merge (backend PR #655, en borrador)**; ver «Fase 4»).

## Parentesco del tutor

El parentesco que el tutor declara con el menor («yo soy su…») se limita a una lista cerrada: **Padre, Madre, Tutor Legal, Abuelo, Abuela, Abuelo/a, Tío, Tía, Tío/a, Hermano/a Mayor y Otro** (constante `GUARDIAN_RELATIONSHIP_TYPE_NAMES`, `sacdia-backend/src/guardianships/guardianships.constants.ts:13-23`). El resto del catálogo `relationship_types` existe para los contactos de emergencia y no aplica a una tutoría.

- **Se compara por nombre, no por id.** `relationship_type_id` es un UUID aleatorio por ambiente (`prisma/schema.prisma:3727`), de modo que el mismo parentesco tiene ids distintos en desarrollo, staging y producción; `name` es único (`prisma/schema.prisma:3728`). Una lista de ids fijos en el servidor o en la app se rompería al cambiar de ambiente. El cliente no filtra por UUID: pide la lista al servidor y envía el id que recibe.
- **Dónde se valida**: al crear un dependiente (`guardianships.service.ts:197`) y al canjear un código de vinculación (`link-codes.service.ts:242`), ambos con `assertRelationshipType` (`guardianships.service.ts:135-153`). En el canje la comprobación va antes de mirar el código: un parentesco no permitido no lo consume.
- **Errores (400)**: `GUARDIANSHIP_RELATIONSHIP_TYPE_INVALID` si el id no existe o está inactivo (sigue vigente) y `GUARDIANSHIP_RELATIONSHIP_TYPE_NOT_ALLOWED` si es una fila real y activa fuera de la lista.
- **`GET /api/v1/guardianships/relationship-types`** devuelve las filas activas de la lista en su orden de visualización, con el envoltorio `{ status, data }`. No lleva scope de actuar (`guardianships.controller.ts:76-92`).
- **Formas combinadas y separadas**: `prisma/seed.ts:15-56` siembra «Abuelo/a» y «Tío/a» en una sola fila cada uno; algunas bases tienen además las formas separadas. La lista acepta ambas (`guardianships.constants.ts`), así que todo ambiente ofrece abuelos y tíos. Solo aparecen las filas que existan y estén activas.
- **App**: «Añadir menor» y «Tengo un código de vinculación» usan `guardianshipRelationshipTypesProvider` (`family_providers.dart:92-95`, que llama `getRelationshipTypes` en `family_remote_data_source.dart:98-121`) en vez del catálogo completo; el selector es el mismo componente con búsqueda de los contactos de emergencia (`relationship_type_picker_field.dart`). El código `GUARDIANSHIP_RELATIONSHIP_TYPE_NOT_ALLOWED` tiene mensaje propio (`family_error_messages.dart:23`, `assets/translations/es.json:450`).

## Actuar en nombre del menor (seguridad)

Contrato completo en [ENDPOINTS-LIVE-REFERENCE.md](../api/ENDPOINTS-LIVE-REFERENCE.md), sección «Actuar en nombre de un dependiente».

- El tutor usa **su propio JWT** y añade `X-Acting-For: <user_id del menor>`. No hay token nuevo.
- `JwtStrategy.validate` sustituye el principal (`sub` pasa a ser el menor, `actor_sub` sigue siendo el tutor). Los scopes se comprueban en `handleRequest` de los dos guards de passport, así el guard global y los `JwtAuthGuard` locales nunca discrepan.
- **Denegado por defecto**: una ruta solo es accesible actuando si declara `@ActingScope(<scope>)`. Hoy son **64 rutas** (la lista exacta la fija un snapshot en `acting-scope-metadata.spec.ts`; falla también ante un `@ActingScope` a nivel de clase). Scopes: `self:read`, `profile:write`, `registration:write`, `legal:accept` (consentimiento `pending`) y además `classes:write`, `honors:write`, `evidence:upload` (consentimiento `verified`).
- **Nunca actuando**: contraseña, sesiones, MFA, eliminar cuenta, exportación de datos, tokens FCM, preferencias de notificación, todas las rutas `/guardianships/*`, el paso 3 alterno «solo soy tutor», el representante legal, clubes y administración. La única excepción son las dos lecturas del selector de club del paso 3, `GET /clubs` y `GET /clubs/:clubId/sections`, con scope `registration:write` (`clubs.controller.ts:75`, `:192`); cualquier otra ruta `/clubs/*` sigue denegada y la regla «nunca» del spec de metadatos las excluye con una expresión regular (`acting-scope-metadata.spec.ts:263-269`). El tutor gestiona a su familia desde su propio perfil.
- Quién puede actuar: tutor **activo** con tutoría `pending` o `verified` de persona (no custodia, no externa, no de prueba) de un menor activo, sin cuenta, no congelado, con fecha de nacimiento y **menor de la mayoría de edad** del país. Cualquier otro caso responde el mismo `403 ACTING_FOR_FORBIDDEN` (no se puede enumerar quién es menor de quién).
- **Auditoría**: las filas escritas actuando llevan `actor_user_id` = tutor, `actor_kind = guardian_acting`, `target_user_id` = menor y `request_context.acting_for`. Las columnas de dominio (quién subió una evidencia) guardan al menor; el rastro del tutor está en la auditoría. En `legal_acceptances`, `accepted_by_user_id` es el tutor.
- **Rate limit**: cuenta contra el tutor, no contra el menor.
- Los clientes **no leen `details`** de los errores: en producción el filtro HTTP lo elimina. Solo se usa el `code`.
- El permiso base de un menor actuando es el de un usuario común; un tutor **no gana ningún permiso de club** por actuar.

## Flujos de la app (sacdia-app)

Documentados con detalle de implementación en `sacdia-app/CLAUDE.md`, sección «Perfiles familiares (tutor y menores)».

### Tutor

1. **Mi familia** (`/family`, entrada en el perfil y aviso único tras el post-registro del propio tutor). Lista a los menores con su estado de consentimiento y de club. Rutas: `/family`, `/family/add`, `/family/link`, `/family/:dependentId`.
2. **Añadir menor** (paso 0): nombre, apellidos, fecha de nacimiento, parentesco (solo los de la lista de «Parentesco del tutor»), declaración jurada y aceptación de términos en nombre del menor. Crea el dependiente y **cambia automáticamente a su perfil**.
3. **Pasos 1 a 3 del post-registro actuando**: foto, información personal (contacto de emergencia y salud) y solicitud de club, con el header `X-Acting-For`. El paso 2 ya no pide representante legal.
4. **Cambio de perfil**: selector «Tú · Ana · Luis» y banner fijo «Viendo como Ana · Volver a mi perfil». Cada cambio purga cachés y proveedores por perfil; no se guarda nada del menor en disco (el estado de actuación vive solo en memoria y, tras un cierre brusco, el arranque en frío limpia lo que quedó). Un cambio rápido Ana a Luis descarta las respuestas tardías de Ana.
5. **Acceso retirado en caliente**: si el servidor responde `ACTING_FOR_FORBIDDEN` a mitad de sesión (otro dispositivo revocó la tutoría), la app sale del modo actuar, vuelve al tutor y avisa con un mensaje. Nunca cierra la sesión del tutor ni restaura al menor desde caché.
6. **Mientras actúa**: se ocultan sesiones, exportación de datos, cambio de contraseña, eliminar cuenta y Mi familia.
7. **Código de vinculación**: cualquier tutor activo del menor emite un código de 72 h para un segundo tutor; el otro tutor lo canjea en «Tengo un código de vinculación». Estados de error visibles: código inválido (mismo mensaje para desconocido, vencido, usado o reclamado), bloqueado por intentos, ya es tutor, no es adulto, y no puede canjear su propio código.
8. **Salir de una tutoría / quitar a un secundario**: se muestra primero el resultado previsto (otro tutor, custodia del club o congelado 90 días) y luego el real.
9. **Solo soy tutor de menores**: en el paso 3 del propio tutor, cierra el post-registro sin elegir club y lleva a Mi familia.
10. **Registro**: la fecha de nacimiento es obligatoria; por debajo de 13 años la app muestra «Pide a tu tutor que te registre desde Mi familia» sin llamar a la API. El servidor repite la regla por país.
11. **Eliminar cuenta con menores**: aviso previo con el resultado de cada menor (desde `deletion-impact`) y casilla de confirmación; luego la contraseña. Si el servidor responde `AUTH_DELETE_DEPENDENTS_ACK_REQUIRED` (lista desactualizada), vuelve a mostrar el aviso con la lista fresca y reintenta, máximo dos veces.
12. **Notificaciones**: un push dirigido al menor llega al tutor con el nombre del menor. Al tocarlo, un diálogo pregunta «Esta notificación es de Ana. ¿Cambiar a su perfil?»; solo ofrece menores de la lista fresca del tutor y que no estén congelados. No se cambia nunca de perfil sin esa confirmación.
13. **Ficha firmada** (detalle del menor): el tutor sube una foto (cámara o galería) o un PDF y puede ver la ficha ya subida. Subirla **no verifica** nada: queda esperando al director. Una vez verificado, se oculta la subida y se muestra «verificado».
14. **Inicio de un tutor sin club**: quien cerró el post-registro como «solo tutor» no tiene resumen de club que mostrar. El inicio muestra «Tu cuenta está lista» con una única acción, **Ir a Mi familia** (`dashboard_view.dart:73-77` y `:363-422`, claves `dashboard.guardian_no_club.*`). La condición es `isGuardianWithoutClub` (`authorization_utils.dart:223-235`): no se está actuando, no hay ninguna asignación de club visible (activa, pendiente, inactiva o vencida; las `designated` no cuentan) y, o bien `family.is_guardian` o `family.dependents_count > 0`, o bien el post-registro está completo con la autorización devuelta sin clubes. No usa campos nuevos del servidor. Si además tiene un rol global de coordinación y no tiene club, el inicio es el hub de coordinación, no este (ver `coordinacion.md`, «Coordinador sin club propio»).
15. **Texto en tercera persona al actuar**: los pasos de foto, información personal y selección de club, y la pregunta del bautismo, nombran al menor («Elige el club de Ana», «¿Está bautizado(a) Ana?») en vez de hablarle al tutor. `actingCopyName` devuelve el nombre de pila del menor (o «este menor» si falta, `post_registration.acting.name_fallback`) y `null` si no se actúa, y `postRegistrationCopy` usa la clave `<clave>_acting` (`acting_copy.dart:11-25`; se aplica en `photo_step_view.dart:157`, `personal_info_step_view.dart:120` y `club_selection_step_view.dart:112`). Sin actuar queda el texto en segunda persona de antes.
16. **Pantalla de solicitud pendiente al actuar**: el inicio de un menor con solicitud pendiente nombra al menor, no menciona la formación personal y explica que el director revisará la solicitud junto con la ficha firmada (`dashboard.pending_state.body_acting`). La acción «Ir a mi perfil» se reemplaza por **Ir a Mi familia**, que primero **sale del modo actuar** (`switchProfile(null)`) y luego abre `/family`, porque esas rutas están bloqueadas mientras hay un menor activo (`dashboard_view.dart:249-333`, `_openFamily` en `:260-265`). Sin actuar se conserva el texto original y «Ir a mi perfil».
17. **Los errores conservan su código y nunca muestran texto crudo**: los orígenes de datos de post-registro y de selección de club convertían cualquier `DioException` en un error de red sin código, de modo que un 403 `ACTING_FOR_SCOPE_DENIED` se leía «Sin conexión» y la pantalla imprimía la excepción tal cual (`AppException: … (Code: null)`). Ahora lanzan `businessErrorFrom(e)` (conserva el `code`; `core/errors/business_error.dart`), los repositorios copian `errorCode` a la falla (`post_registration_repository_impl.dart`) y las vistas pasan por `userErrorMessage` (`core/errors/user_error_message.dart:16-36`): primero la traducción `errors.<código en minúsculas>`, luego el mensaje de conexión si no hay red, y si no `common.error_generic`. Nunca devuelve `toString()` ni el texto del servidor y solo lee `code`, jamás `details`. El mensaje de `ACTING_FOR_SCOPE_DENIED` dice que el perfil de un menor se está gestionando (`errors.acting_for_scope_denied`, `es.json:452`).
18. **Un 409 del paso 3 nunca cuenta como éxito**: antes la app trataba cualquier 409 de `completeStep3` como «paso ya completo». Un 409 de ese paso es un conflicto real (`POST_REG_DUPLICATE_MEMBERSHIP`, `post-registration.service.ts:581`, o `CLASS_ALREADY_ENROLLED`, `:737` y `:804`), así que ahora se muestra con su mensaje (`post_registration_flow_providers.dart:135-143`; `errors.post_reg_duplicate_membership`, `es.json:472`) y el flujo no avanza.

### Director

1. En **Miembros → solicitudes de ingreso**, una solicitud de un menor muestra la insignia «Menor · consentimiento pendiente/verificado». El botón de aprobar se convierte en **Verificar consentimiento** mientras esté pendiente; si la lista estaba desactualizada y el servidor responde `MR_CONSENT_NOT_VERIFIED`, la app avisa y abre la verificación.
2. La pantalla de verificación muestra los tutores, la ficha vigente (por URL firmada de 15 minutos, sin guardarla en caché ni compartirla) y permite subir otra (cámara, galería o PDF). Para confirmar hace falta una ficha **ya subida al servidor**, marcar «Verifiqué la ficha firmada» y no tener un archivo elegido sin subir.
3. Confirmar llama a `verify-consent` con `approve: true`. Si la verificación se guardó pero la aprobación falló, la app muestra «verificado, pero falló la aprobación» con el motivo y un botón de reintentar (misma llamada, idempotente). Subir o salir de la pantalla nunca verifican.
4. Si el menor está bajo **custodia del club**, quien subió la ficha o creó al menor no puede verificarlo: la app muestra el mensaje de cuatro ojos y debe verificar otra persona autorizada del club.

## Flujos del panel (sacdia-admin)

- **Solicitudes de membresía** (`/dashboard/requests/membership`, y el panel de pendientes del detalle de club): insignia de consentimiento, aprobar deshabilitado con tooltip mientras esté pendiente y acción **Verificar** con un `AlertDialog`: ver la ficha (imagen o PDF por URL firmada), subir una nueva, casilla obligatoria y aprobar al confirmar (casilla activa por defecto). Si la verificación se guardó y la aprobación falló, avisa y refresca la lista (aprobar queda habilitado). Los errores se mapean por `code`.
- **Detalle de usuario** (`/dashboard/users/[userId]`, pestaña Resumen): tarjeta de **tutorías** con quién responde por el usuario (historial incluido, con quién verificó y cuándo), por quién responde él, y el ciclo de congelación. «Ver ficha» pide la URL firmada al hacer clic y la abre en una pestaña nueva. Se oculta si el actor no tiene `guardianship:read` (antes `legal_representative:read`, renombrado en la Fase 4; ni el respaldo `users:read_detail`) o si el bloque está vacío. Un correo nulo se muestra como «—».
- Las tutorías **no se editan desde el panel**: el panel solo lee.
- **Un dependiente se muestra «Sin acceso propio»** en el detalle de usuario. Los interruptores App, Panel y Estado de «Roles y acceso» guardan banderas de un inicio de sesión que no existe, así que se reemplazan por el aviso «Sin acceso propio · Gestionado por su tutor» (`resumen-tab.tsx:160-174`, `data-testid="dependent-no-access"`); en la barra lateral, «Acceso a la app» muestra «Sin acceso propio» y «Acceso al panel», «No» (`users/[userId]/page.tsx:609-624`). La señal es `guardianships.dependent_profile != null` (`page.tsx:162`), por lo que solo funciona si el actor puede leer ese bloque (`legal_representative:read`); sin ese permiso el bloque llega `null` y se ven las banderas de siempre.
- **Sin sección de representante legal (Fase 4)**: la sección 06 «Representante legal (heredado)» del Resumen, que en la Fase 2 solo se dibujaba si existía un registro, se quitó junto con el módulo; las relaciones actuales se gestionan en Tutorías.
- **Creador del perfil**: la tarjeta de tutorías muestra «Creado por» con los primeros 8 caracteres del id, como enlace al detalle de ese usuario (`/dashboard/users/<id>`; el id completo va en el `title`). La API solo devuelve el id del creador, no su nombre (`user-guardianships-card.tsx:47-49` y `:318-332`). Antes se imprimía el UUID completo.
- **Vencimiento efectivo en solicitudes de membresía**: la columna de vencimiento muestra `effective_expires_at ?? expires_at` (`pending-members-table.tsx:58-61` y `:210`) y el aviso «vence pronto» (menos de 48 horas) usa ese mismo valor. Mientras el consentimiento del menor está pendiente se añade un icono de información con el texto «Se extiende mientras el consentimiento está pendiente» (`:267-281`). El tipo `MembershipRequest` gana `effective_expires_at` (`src/lib/api/membership-requests.ts:44-54`).
- **Columna de acciones fija**: en la tabla de solicitudes pendientes (`/dashboard/requests/membership` y el panel de pendientes del club) la columna de acciones queda pegada al borde derecho con fondo opaco, así aprobar, verificar y rechazar siguen al alcance cuando la tabla se desplaza en horizontal en anchos estrechos (`pending-members-table.tsx:70-78`, `:199` y `:288`).

## Verificación del director (backend)

Contrato en [ENDPOINTS-LIVE-REFERENCE.md](../api/ENDPOINTS-LIVE-REFERENCE.md), secciones `membership-requests`, `guardianships` y `admin-users`. Resumen de reglas:

- **Compuerta de consentimiento**: ver la sección siguiente. Aprobar una solicitud de un dependiente sin tutoría verificada responde 409 `MR_CONSENT_NOT_VERIFIED`; adultos y adolescentes con cuenta no cambian.
- **Ficha**: la suben el tutor (cualquier tutor activo) o el director en un bucket privado de R2 (JPEG, PNG, WebP o PDF, 10 MB, bytes mágicos; HEIC se rechaza y la app lo convierte). Una subida nueva reemplaza a la anterior sin borrar el objeto **mientras el consentimiento esté pendiente**. Una vez verificado, la ficha queda **bloqueada**: cualquier subida (del tutor o del director) responde 409 `GUARDIANSHIP_CONSENT_ALREADY_VERIFIED` y reemplazarla exige una tutoría nueva tras revocar (`guardian-evidence.service.ts:403-419`, comprobado antes de guardar y otra vez dentro de la transacción con el candado del menor, `:320` y `:344`). Solo se lee con URL firmada de 900 s; cada lectura y subida se audita.
- **`verify-consent`**: exige ficha vigente y la casilla de confirmación; marca verificada la tutoría principal activa, promueve a los tutores invitados, escribe el evento `guardianship.consent_verified` en la misma transacción (con `changes.verification_method`), sube el `epoch` de acting-for (los scopes del tutor se amplían en su siguiente petición) y avisa a los tutores. Con `approve: true` aprueba después del commit; si eso falla devuelve 200 con `approve_error` y repetir la llamada reintenta solo la aprobación. Es idempotente. El `verification_method` que guarda depende de la vía de quien verifica: `coordinator_paper_form` si llegó por la asignación de coordinador (`coordinatorSectionGrant`), `director_paper_form` si llegó por un rol de club (director, o un rol con solo `consent:verify`).
- **Cuatro ojos**: quien verifica no puede ser (a) un tutor vigente del menor, en cualquier tutoría → 403 `GUARDIANSHIP_GUARDIAN_SELF_VERIFY`; ni, si la tutoría principal es una custodia del club, (b) quien subió la ficha vigente, quien creó al menor o el último tutor que lo dejó en custodia → 403 `GUARDIANSHIP_CUSTODIAN_SELF_VERIFY`. Se evalúan al pasar de `pending` a `verified`; repetir la llamada sobre una tutoría ya verificada es una no-operación (`consent-verification.service.ts:231`, `:244`, `:246`, `:312-368`). Ver A14 en «Decisiones».
- **Caducidad**: una solicitud `pending` de un menor con consentimiento sin verificar vive al menos 30 días (en vez de 8); al verificar, el plazo base (`membership.pending_timeout_days`, 8 por defecto) se cuenta desde la verificación. El cron decide con `created_at` y la fecha de verificación, no con `expires_at` (`membership-requests.service.ts:414-476`). La regla vive en una función compartida, `effectiveMembershipExpiry` (`membership-request-expiry.ts:37-53`), y el listado de solicitudes la expone como `effective_expires_at` para que el director vea el vencimiento real, no el `expires_at` guardado al crear (creación + 8 días). Con esa función, un plazo base inválido cae a 8 y los días se cuentan en UTC.
- **Aviso al director**: la solicitud nueva de un menor llega con el título «Menor · consentimiento pendiente».
- **Fail closed**: sin `R2_BUCKET_GUARDIANSHIP_EVIDENCE` todas las operaciones de ficha responden 503 `GUARDIANSHIP_EVIDENCE_UNAVAILABLE` y el resto de la API funciona.

## Compuerta de consentimiento en toda activación de rol de club

Un dependiente solo puede quedar con un rol de club `active` si tiene una tutoría `verified` real (no `is_test_data`). La regla es una función única, `assertAssignmentActivationAllowed` (`src/membership-requests/assignment-activation-gate.ts:53-60`, lanza 409 `MR_CONSENT_NOT_VERIFIED`), y **cada** escritura que puede activar una fila de `club_role_assignments` la llama con el mismo cliente de transacción, justo antes de escribir. Para un dependiente toma el candado por menor (el de verificar, revocar, salir y subir ficha), así una activación y un cambio de consentimiento no compiten. Los adultos, incluidos los adolescentes que se registraron solos, nunca se bloquean (`assignment-activation-gate.ts:26-47`).

Rutas y procesos cubiertos (inventario del guard `assignment-activation-gate.inventory.spec.ts`, líneas 863-897; cada sitio lleva un comentario `// activation-gate: <usuario>`):

| Camino | Sin consentimiento verificado |
|---|---|
| `POST /club-sections/:clubSectionId/membership-requests/:assignmentId/approve` | 409 `MR_CONSENT_NOT_VERIFIED` |
| `PATCH /club-roles/:assignmentId` cuando escribe `status: 'active'` o cambia el rol de una fila activa (`clubs.service.ts:842-869`) | 409 |
| `POST /clubs/:clubId/sections/:sectionId/roles`, `.../director-assignment`, `.../director-succession` (sucesor, antes de terminar al saliente) | 409 |
| `POST /requests/assignments/:requestId/review` y `POST /requests/transfers/:requestId/review`, al aprobar (la transferencia mueve una membresía ya activa y también se controla) | 409 |
| `POST /club-sections/:sectionId/annual-continuations` (reactivar, marcador de la sección base, salto de tipo) | resultado por usuario `blocked` con `error_code: MR_CONSENT_NOT_VERIFIED`; el lote sigue (`annual-membership.service.ts:83`, `:486-495`) |
| Corte de año: salto de tipo y activación de planes de sucesión de director | se omite el caso, con aviso en logs (y notificación a administradores y a director-lf/assistant-lf para los planes de director); el corte sigue (`year-cut.service.ts:712-722`, `annual-membership.service.ts:400-404`) |

No pasan por la compuerta porque no activan: terminar un rol (`DELETE /club-roles/:assignmentId`), rechazar, cancelar, expirar, el cierre de año, el marcador `inactive` de «no inscrito» y el paso 3 del post-registro (crea la solicitud en `pending`).

Endurecimientos asociados:

- `PATCH /club-roles/:assignmentId`: el `status` del DTO es un enum cerrado con `@IsIn` (`active`, `inactive`, `pending`, `rejected`, `expired`, `cancelled`, `ended`, `designated`; `role-assignment.dto.ts:16-25` y `:117`). Antes era un `@IsString()` libre.
- `approve`: si la solicitud no está `pending` dentro de la transacción (otra revisión, cancelación o expiración), retorna sin activar nada: 409 `MR_ALREADY_PROCESSED` (antes `MR_ALREADY_PENDING`), o 404 `MR_NOT_FOUND` si es de otra sección (`membership-requests.service.ts:135-143`, `:175-183`). Nunca cae al `updateMany` sin pasar por la compuerta: el post-registro vuelve a poner en `pending` filas rechazadas o vencidas y una de ellas habría coincidido con el `WHERE` sin compuerta (comentario del código).
- `PATCH` con `status: 'active'` se controla siempre, aunque la lectura previa (fuera de la transacción) diga que la fila ya estaba activa (`clubs.service.ts:862-869`).

> [!WARNING]
> **Operaciones fuera del backend**: el SQL manual, los seeds y los scripts escriben directo en la tabla y **se saltan la compuerta** (la base de datos no tiene ningún trigger que la repita). Quien active roles de club por esa vía debe verificar el consentimiento a mano. Procedimiento: [runbook de activación manual](../runbooks/family-profiles-consent-gate-manual-sql.md).

## Salida del tutor, custodia, congelación y retención

Cuando el último tutor activo sale (por `revoke` o al eliminar su cuenta):

| Situación del menor | Resultado | Qué pasa |
|---|---|---|
| Queda otro tutor activo | `other_guardian` | El más antiguo pasa a principal si hace falta |
| Tiene una asignación de club `active` o `pending` | `club_custody` | Se crea una fila de custodia del club con el estado heredado; se avisa a los directores («Un menor quedó bajo custodia del club») |
| Ninguna de las anteriores | `frozen` | `frozen_at = now()`, `purge_after = now() + 90 días`; no se lista, no se puede actuar por él ni recibe pushes |

Todo se serializa por menor con un candado de Postgres (`pg_advisory_xact_lock`), así que dos salidas simultáneas dejan exactamente un destino.

> [!NOTE]
> **Fase 4 (backend #654)**: el congelamiento de arriba y la purga a los 90 días siguen siendo los de un menor sin tutor. Una persona **liberada por mayoría de edad** y congelada es otra cosa: tiene `frozen_reason = 'majority_release'`, **sin** `purge_after`, y el cron de purga **nunca** la toma. Ver «Fase 4».

**Purga a los 90 días** (decisión A9: «borrar» es borrar, no solo ocultar). El cron `dependent-profiles-purge` (`20 4 * * *` UTC, lotes de 100):

1. En una transacción: anonimiza la fila `users` (`active = false`, correo, nombre, apellidos, fecha de nacimiento, sangre, género, fecha de bautismo (`baptism_date`), imagen y geografía en NULL; el booleano `baptism` no se toca), borra alergias, enfermedades, medicinas, contactos de emergencia, filas de ficha, archivos de evidencia, bandeja de notificaciones, vacía las columnas de archivos de sus especialidades y anula el teléfono del tutor externo (y su nombre, que en la fila de un titular externo queda con el marcador `'Tutor'` porque `guardianships_holder_ck` exige un nombre; corregido en `9533895d`) y la IP y el user agent de sus aceptaciones legales. En esa misma transacción **cancela** sus solicitudes de membresía `pending` (`status = 'cancelled'`, `active = false`, `end_date = now`; la misma escritura que la cancelación del propio usuario), para que no queden como aspirantes sin nombre en la lista del director, y **termina** el resto de sus asignaciones vivas de club (`status` `active` o `inactive` con `active = true`, cualquier rol: `status = 'ended'`, `active = false`, `end_date = now`) para que no sigan como miembros sin nombre; las inscripciones (`enrollments`) no se tocan (ni la baja de un miembro ni el corte de año las modifican). Mientras un menor está congelado, `GET /clubs/:clubId/sections/:sectionId/members` y el detalle de ranking de la sección ya lo ocultan.
2. **Después de confirmar la transacción** borra los objetos de R2 (fichas de consentimiento, foto de perfil, evidencias de clases y especialidades, y certificados, documentos e imágenes de especialidades), por bucket y con mejor esfuerzo. Si R2 falla, la purga **no** se revierte ni se reintenta; se registra `dependent_purge_storage_cleanup_failed` con el bucket y las claves para limpiar los huérfanos a mano.
3. **Se conserva** la fila `users` anonimizada, las tutorías (quién lo tuvo a cargo) y el progreso de clases y especialidades, sin archivos.

**Eliminación de cuenta del tutor**: en la misma transacción se ceden o congelan los menores y se anulan la IP y el user agent de las aceptaciones legales del tutor **y de las que hizo en nombre de sus dependientes** (`accepted_by_user_id` = el tutor), porque llevan su IP y dispositivo.

## Fase 3 (3a, 3b y 3c)

> [!NOTE]
> En `development` desde el 2026-10-20 (sacdia-backend #531, sacdia-app #179, sacdia-admin #244 y sacdia #142; un PR por repo). Las migraciones de la fase están aplicadas en Neon `development`, `staging` y `production` (verificado el 2026-11-12). Contrato exacto en [ENDPOINTS-LIVE-REFERENCE.md](../api/ENDPOINTS-LIVE-REFERENCE.md); esquema en [SCHEMA-REFERENCE.md](../database/SCHEMA-REFERENCE.md); promoción en [DEPLOYMENT-GUIDE.md](../deployment/DEPLOYMENT-GUIDE.md), §0.6.

Las tres sub-fases se entregaron en orden (cada una con su verificación y su QA) y comparten tres banderas de servidor, todas `false` por defecto: `FAMILY_TEEN_LOGIN_ENABLED` (3a), `FAMILY_LINKED_DEVICE_ENABLED` (3b) y `FAMILY_DIRECTOR_CREATE_MINOR_ENABLED` (3c). `GET /auth/me` las expone en `family_features` y la app oculta lo que esté apagado. Lo que cierra un hueco de seguridad (compuerta de consentimiento por edad, modo pendiente de tutor, crones, avisos) **no tiene bandera**.

| Sub-fase | Qué entrega | Bandera | Estado |
|---|---|---|---|
| 3a | Cuentas supervisadas de 13 a 17 años: tipos de principal `supervised_user` y `age_unknown_user`, modo pendiente de tutor (plazo de 90 días), acceso propio que habilita el tutor, avisos de seguridad y resumen para el tutor, ficha subida por el tutor al actuar en el paso 3, analítica anónima, texto legal `2.0.0-family` (borrador) | `FAMILY_TEEN_LOGIN_ENABLED` (solo el acceso propio) | Implementada; QA parcial |
| 3b | Dispositivo vinculado del menor de 13 años: el tutor verificado vincula el teléfono con un QR de un solo uso; el teléfono tiene su propia sesión y una superficie mínima | `FAMILY_LINKED_DEVICE_ENABLED` | Implementada (servidor y app); QA ejecutado en parte |
| 3c | El director registra menores bajo custodia del club, verificación del consentimiento por otra persona, tarjeta de acceso familiar en el panel (desactivar acceso, desvincular dispositivo), cron de cambios de edad | `FAMILY_DIRECTOR_CREATE_MINOR_ENABLED` (solo el registro) | Implementada (servidor, app y panel); QA **Pendiente** |

### 3a: cuentas supervisadas (resumen)

- El servidor decide **en cada petición** si una cuenta es adulta, supervisada (`supervised_user`, con `supervision` `pending_guardian` o `active`) o de edad desconocida (`age_unknown_user`, sin fecha de nacimiento y con el post-registro abierto). Nunca por un claim del JWT. Cada tipo tiene un conjunto de scopes con denegado por defecto (403 `PRINCIPAL_SCOPE_DENIED`).
- **La compuerta de consentimiento pasa de «es dependiente» a «es menor de edad»**: aprobar la solicitud de un adolescente que se registró solo responde 409 `MR_CONSENT_NOT_VERIFIED` hasta que haya un tutor vinculado y verificado. `verify-consent` también verifica sobre una asignación que ya está `active`.
- **Modo pendiente de tutor**: un adolescente sin tutor verificado no ve datos de club ni tiene credencial QR. Recordatorios a los 7, 30 y 83 días; a los 90 se congela y 90 días después se purga (cron `pending-teen-guardian`).
- **Vincular un tutor**: el adolescente emite un código (`POST /users/me/guardian-link-codes`), un adulto lo canjea y queda como tutor `pending` sin poderes hasta que un director verifica.
- **Acceso propio supervisado**: el tutor **verificado** habilita (por correo o con un nombre de usuario generado por el servidor), desactiva, reactiva y restablece la contraseña. Bloqueo progresivo por intentos fallidos.
- Avisos de seguridad al tutor (`family:security`, obligatorios), resumen de progreso sin datos de salud, y analítica anónima para 13 a 17 y edad desconocida.

### 3b: dispositivo vinculado (resumen)

- El tutor verificado crea un token QR de 10 minutos; el teléfono lo canjea (`POST /auth/device/pair`) y recibe un JWT de audiencia propia (`sacdia:device`, 1 hora) y una sesión que desliza hasta un tope absoluto de **180 días**. Hasta 2 dispositivos por menor.
- El dispositivo es un principal más (`linked_device`): sin correo, sin contraseña, sin `X-Acting-For`; ve progreso y agenda (sin la lista de asistentes), sube evidencia de clases y la envía a validación. La app le da su propia cáscara (clases, agenda, avisos) y **no inicializa PostHog**.
- El tutor lo desvincula cuando quiera; el siguiente request del teléfono es 401 `AUTH_DEVICE_REVOKED`. Los demás tutores verificados reciben el aviso.

### 3c: el director registra menores y el panel de acceso familiar

**Qué resuelve.** Un director podía devolver a una familia un menor bajo custodia del club, pero no crearlo. Ahora lo registra él mismo en su sección y el club lo custodia hasta que lo reclame una familia. La seguridad del consentimiento la sostienen dos reglas: **el menor nunca queda `active` por la ruta de registro** (siempre `pending`) y **quien lo creó no puede verificar su consentimiento**.

**Flujo completo** (contrato en [ENDPOINTS-LIVE-REFERENCE.md](../api/ENDPOINTS-LIVE-REFERENCE.md), «Registro de menores por un director y acceso familiar en el panel (Fase 3c)»):

1. El director (rol de club `director` o `deputy-director`, con `dependents:create`, y con `FAMILY_DIRECTOR_CREATE_MINOR_ENABLED` encendida) registra al menor de 0 a 17 años con una declaración bajo protesta y las aceptaciones legales en nombre del menor (`accepted_by_user_id` = el director). Se crea, en una transacción, el usuario sin cuenta ni correo, la custodia del club con consentimiento `pending`, una solicitud de membresía `pending` y la auditoría `dependent.created_by_director`. Los revisores de la sección (menos el creador) reciben «Menor · consentimiento pendiente».
2. Alguien sube la ficha firmada (el creador puede subirla, pero eso no le permite verificar).
3. **Otra persona** con `club_members:approve` o `consent:verify` (subdirector, secretario, secretario-tesorero, otro director, un admin o un coordinador cuya asignación cubra la sección) verifica con `verify-consent`. El creador, quien subió la ficha vigente y el último tutor que cedió al menor reciben 403 `GUARDIANSHIP_CUSTODIAN_SELF_VERIFY`; un tutor vigente 403 `GUARDIANSHIP_GUARDIAN_SELF_VERIFY`. La regla va por **id de usuario**: un creador que además es admin sigue bloqueado.
4. Aprobar exige `club_members:approve` (`approve: true` solo con `consent:verify` → 403 `MR_APPROVE_PERMISSION_REQUIRED`). El creador que aprueba mientras el consentimiento está `pending` recibe 409 `MR_CONSENT_NOT_VERIFIED`.
5. **Reclamo por la familia**: el director emite un código `XXXX-XXXX` de 7 días (`POST .../dependents/:userId/claim-codes`, `club_members:approve`); un adulto lo canjea y queda como tutor principal en `pending` (la custodia pasa a `revoked` con motivo `claimed`; la verificación **no** se hereda). El creador **sí** puede verificar la ficha nueva del tutor. Un menor de 13 a 17 años reclamado solo puede recibir acceso propio con el tutor ya verificado.
6. **Si nadie lo reclama ni lo verifica**: la solicitud vence (30 días como mínimo con el consentimiento sin verificar) y el menor que solo tiene la custodia del club se **congela** (`frozen_at = now`, `purge_after = now + 90 días`, dispositivos revocados) y la purga lo anonimiza después.

**Permisos** (migración `20261022130000_seed_family_permissions`): `dependents:create` para director y subdirector de club; `consent:verify` para director, subdirector, secretario y secretario-tesorero de club; ambos para `admin`, `assistant-admin` y `super-admin`. `consent:verify` también para `coordinator`, `zone-coordinator` y `general-coordinator` (migración `20261023120000_grant_consent_verify_to_coordinators`, solo DML, aplicada en `development`, `staging` y `production`).

> [!NOTE]
> **Coordinadores (antes limitación B11, resuelta en el seguimiento `coordinator-consent-verify`)**: `PermissionsGuard` no conocía el territorio de un coordinador (403 `GUARD_CLUB_SCOPE_REQUIRED` incluso dentro de su zona), y ampliar `canManageClub` habría dado poderes de gestión de club en todas partes. La solución es estrecha y por ruta: la migración `20261023120000_grant_consent_verify_to_coordinators` da `consent:verify` a los tres roles de coordinador, y solo tres rutas (lista de solicitudes, `GET` de la ficha y `verify-consent`) aceptan `coordinatorSections`; subir la ficha (`POST`) es solo de quien aprueba. Un coordinador pasa únicamente en las secciones que cubren sus `coordinator_assignments` vigentes (`GENERAL`: el campo local; `ZONE`: los distritos de la zona en el tipo de club de la asignación; `SECTION`: esa sección). Ser miembro del club sin asignación no basta (403 `GUARD_CLUB_SCOPE_REQUIRED`).
>
> Es un revisor **solo-verificación** (opción B): ve en la lista solo los menores con consentimiento `pending` y ficha vigente (las filas con `viewer_verify_block` se muestran con el bloqueo), lee la ficha solo dentro de esa lista, **no puede subir la ficha** (403) ni aprobar (`approve: true` → 403 `MR_APPROVE_PERMISSION_REQUIRED`), y fuera de su lista `verify-consent` responde 404 `MR_NOT_FOUND`. Contrato completo en [ENDPOINTS-LIVE-REFERENCE.md](../api/ENDPOINTS-LIVE-REFERENCE.md), «Revisor solo-verificación». Cubierto por pruebas unitarias y el e2e `test/director-created-minor.e2e-spec.ts` (viaje A2). El 2026-10-21 se ejercitó en vivo la verificación de un coordinador `ZONE` (`verify-consent` con `approve: false`: consentimiento `verified`, solicitud todavía `pending`; ver `docs/testing/FAMILY-PROFILES-PHASE3C-QA.md`, B13a, B13c y la observación 8). Sigue sin verificarse en vivo el resto: la lista por sección, la lectura de la ficha (la QA no tenía R2), los rechazos (otra sección, asignación vencida, miembro sin asignación, subir ficha, aprobar) y los coordinadores `SECTION` y `GENERAL`. Los clientes añaden el modo solo-verificación (sacdia-app #180 y sacdia-admin #245, en `development`). Cuando un coordinador verifica por esta vía, la tutoría queda con `verification_method = coordinator_paper_form` y no con `director_paper_form`; el evento de auditoría lo registra igual y el panel lo muestra como «Ficha en papel (coordinador)».
>
> **Cola del coordinador (seguimiento `coordinator-pending-consents`, 2026-10-21, mergeado en `development`, PR #534 de sacdia-backend)**: en lugar de elegir sección por sección, el coordinador abre **una sola cola** con las fichas por verificar de todas las secciones que cubren sus asignaciones vigentes: `GET /api/v1/coordination/me/consent-pending` (contrato completo en [ENDPOINTS-LIVE-REFERENCE.md](../api/ENDPOINTS-LIVE-REFERENCE.md), «`GET /api/v1/coordination/me/consent-pending`»). Lista lo mismo que la vista solo-verificación de una sección (menores con consentimiento `pending` y ficha vigente), ordenado por la ficha que más lleva esperando, paginado por `limit` (1 a 100, 50 por defecto) y `offset`, con el `total` de la cola completa y un resumen `by_section` (`club_name`, `club_type_name`, `district_name`, `pending_consent_count`). La autoridad es más estrecha que la de la lista por sección: el permiso `consent:verify` se evalúa como **global** y debe venir de un **rol de coordinador**; un `consent:verify` que sale solo de un rol de club, o un director, secretario o admin, recibe 403 `GUARD_PERMISSION_DENIED` y usa la lista por sección. Sin asignaciones vigentes que cubran una sección activa: 403 `GUARD_CLUB_SCOPE_REQUIRED`. Un tutor actuando, un adolescente supervisado y un dispositivo vinculado reciben 403 `ACTING_FOR_SCOPE_DENIED` o `PRINCIPAL_SCOPE_DENIED`.
>
> Clientes (sacdia-app #181 y sacdia-admin #246, en `development`): la app usa la ruta en «Fichas por verificar» (páginas de 50 con «Cargar más») y muestra una insignia con el total en el hub de coordinación (`limit=1`); el panel la usa como vista por defecto «Todas mis secciones» de las solicitudes de membresía de un coordinador (páginas de 25). Ambos quitan la ficha de la cola al verificar y deciden los estados de error por `code`. Al elegir una sección concreta (chip del resumen) el panel vuelve a la lista por sección. Cubierto por pruebas unitarias y el e2e `test/coordinator-consent-pending.e2e-spec.ts` del backend (15 casos, con un doble de Prisma en memoria, que no evalúa filtros relacionales); QA en vivo de la API y la app el 2026-10-21 en una rama temporal de Neon; el panel queda solo con pruebas automáticas (ver `docs/testing/FAMILY-PROFILES-PHASE3C-QA.md`, escenarios B13 a B13c).
>
> **Territorio de zona**: una asignación `ZONE` solo cubre un club cuando el **distrito** está activo (`districts.active`), además del vínculo zona-distrito activo, la zona, el club y la sección. Ver `docs/canon/runtime-coordination.md`.

**Cron `family-age-transitions`** (`0 14 * * *` UTC, candado de 23 h): (1) cuando un menor sin cuenta cumple la edad mínima de acceso propio avisa **una sola vez** a sus tutores verificados (`family:age_nudge`, push y bandeja; el aviso lleva a su detalle, sección «Acceso»); (2) barre los dispositivos vinculados: los que llegan a la mayoría de edad (`majority`) o pasan de 180 días (`expired`) se revocan y se avisa a los tutores verificados una sola vez (ruling W6), gane el barrido o la compuerta por petición. Con `FAMILY_TEEN_LOGIN_ENABLED` apagada el aviso no se envía ni se marca; el barrido de dispositivos corre siempre.

**Flujos de la app** (`sacdia-app`, relativo a `lib/`):

- **Registrar un menor** (`features/members/`): acción en la pantalla de miembros de la sección, visible solo con el permiso `dependents:create` **y** `family_features.director_create_minor`. Formulario con declaración bajo protesta y aceptación de Términos y Privacidad en nombre del menor; los errores se mapean por `code` (con texto propio para edad fuera de rango y para falta de año eclesiástico). El éxito deja una solicitud con la insignia «Menor · consentimiento pendiente».
- **Verificación con cuatro ojos**: el botón de confirmar se deshabilita con el aviso «Otra persona debe verificar este consentimiento: tú registraste al menor, subiste la ficha o lo dejaste bajo custodia del club» cuando el servidor dice `viewer_verify_block = self_custodian` (o cuando, en esta sesión, esta persona registró al menor o subió la ficha); con `self_guardian` el aviso es el del tutor; un 403 forzado de custodia da el mismo mensaje. Quien solo tiene `consent:verify` ve «Confirmar verificación» (no aprueba). Detalle del contrato: `consent.viewer_can_verify`.
- **Código para la familia**: en la verificación de un menor bajo custodia (para quien puede aprobar) la sección «Entregar a la familia» con «Generar código para los padres» (copiar, compartir, vigencia de 7 días). La familia lo canjea en Mi familia > «Tengo un código de vinculación».
- **Aviso de los 13 años**: una tarjeta en la sección «Acceso» del detalle del menor (solo con la bandera de acceso propio y sin acceso propio habilitado), destino del push `family:age_nudge`.
- **Toque de push por modo** y **proveedores por perfil**: ver `sacdia-app/CLAUDE.md`, «Modos de sesión (Fase 3)», «Política de analítica por modo» y «Push tocado: ruta por modo».

**Flujos del panel** (`sacdia-admin`):

- **Tarjeta «Acceso familiar»** en el detalle de usuario (pestaña Resumen, bajo la tarjeta de tutorías): estado del acceso propio (Activa / Pendiente de tutor / Desactivada), método, origen, quién lo habilitó y, si el actor lo puede ver, el nombre de usuario; tabla de dispositivos (etiqueta, plataforma, quién lo vinculó, última conexión, vencimiento) y lista de sesiones bajo demanda, donde una sesión de dispositivo lleva la insignia «Dispositivo vinculado». Se oculta si el bloque es `null` o está vacío; las acciones solo se dibujan para quien puede gestionar el acceso del usuario y tiene el permiso sensible de actualizar el representante legal.
- **Desactivar acceso** y **Revocar dispositivo**: `AlertDialog` con un **motivo obligatorio** de 5 a 500 caracteres, que solo queda en la auditoría. No hay control para habilitar, reactivar ni restablecer la contraseña.
- **Solicitudes de membresía**: la insignia «Menor» cubre también a los adolescentes; verificar se deshabilita (con tooltip) cuando nadie está vinculado como tutor (`guardianship_id` nulo) o cuando el servidor informa un `viewer_verify_block`; el diálogo de verificación desmarca «Aprobar» ante `MR_APPROVE_PERMISSION_REQUIRED`.

**Limitaciones conocidas de la 3c**:

- **Coordinadores**: en una rama de Neon donde no se haya aplicado la migración `20261023120000_grant_consent_verify_to_coordinators` no tienen `consent:verify` y todo sigue como en la 3c original (ver la nota de arriba). Está aplicada en `development` y `staging` (2026-10-21) y pendiente en `production`.
- **Un revisor solo-verificación** (hoy, el coordinador) lista y lee la ficha solo dentro de su lista, no sube fichas ni aprueba; subir la ficha sigue siendo `club_members:approve`.
- **Cola del coordinador**: la paginación es por `offset` y el total se calcula en memoria; si otro revisor verifica una ficha entre dos páginas, las siguientes se desplazan. Los clientes quitan la ficha verificada de su copia local y refrescan. Un contador de pendientes por sección en `GET /coordination/me/scope` no se añadió: el conteo exacto necesita el predicado compartido de la cola y `by_section` ya lo da.
- El panel **no tenía** una pestaña de sesiones (se retiró a propósito antes), así que la lista de sesiones de la tarjeta es de solo lectura y se carga bajo demanda; no hay forma de revocar una sesión desde ahí.
- `.env.example` del backend no pudo leerse ni editarse durante la implementación: comprobar a mano que liste las tres banderas `FAMILY_*` antes del PR.
- La app y el panel infieren «quién no puede verificar» del `viewer_verify_block` de la **lista**, que es una instantánea: quien sube la ficha después de cargarla pasa a ser el subidor vigente, y la app lo cubre con su conocimiento de la sesión; el servidor (403) sigue mandando.
- Nada de la 3c se ha ejercitado todavía en vivo (simulador ni Neon con las banderas encendidas): ver `docs/testing/FAMILY-PROFILES-PHASE3C-QA.md`, todo **Pendiente**.

## Fase 4: liberación a la mayoría de edad

> [!NOTE]
> Integrada en `development` con sacdia-backend #654, sacdia-app #257 y sacdia-admin #305 (2026-11-13); esta sección se verificó el 2026-11-12 contra el árbol de trabajo de las ramas antes del merge. Todo el comportamiento de liberación está detrás de `FAMILY_MAJORITY_RELEASE_ENABLED` (variable de entorno, por defecto `false`, no es `system_config`). Contrato HTTP: [ENDPOINTS-LIVE-REFERENCE.md](../api/ENDPOINTS-LIVE-REFERENCE.md), «Liberación a la mayoría de edad (Fase 4)». Esquema: [SCHEMA-REFERENCE.md](../database/SCHEMA-REFERENCE.md), «Liberación a la mayoría de edad (Fase 4)». Rollout: [DEPLOYMENT-GUIDE.md](../deployment/DEPLOYMENT-GUIDE.md), §0.6, punto 11. **Los textos legales (avisos, aceptación y congelamiento) no están aprobados**: [docs/legal/README.md](../legal/README.md).

### Qué resuelve

Hasta la Fase 3 un dependiente que cumplía la mayoría de edad del país seguía con su fila de tutorías y con una cuenta que el tutor había habilitado. Ahora, al cumplirla, el sistema **libera** a la persona: los tutores dejan de tener cualquier facultad, y la persona pasa a ser un adulto con cuenta propia que debe aceptar de su parte los Términos y el Aviso de Privacidad vigentes (y tener un correo). Si no lo hace en 30 días queda **congelada**, y nunca se borra sola.

### Línea de tiempo

| Cuándo | Qué pasa | Quién lo hace |
|---|---|---|
| 30 días antes de la mayoría de edad | Aviso: la persona (si tiene cuenta o acceso por nombre de usuario), los tutores verificados y, si el menor está solo bajo custodia del club, los directores | Cron `family-majority-release` |
| Día de la mayoría de edad (según el país y su zona horaria) | **Liberación**: se revocan todas las tutorías con motivo `released`; plazo de 30 días para aceptar | Cron (la compuerta perezosa del servidor restringe a la persona desde la medianoche local, antes de que corra) |
| 23 y 29 días después (7 y 1 día antes del plazo) | Recordatorios a la persona | Cron |
| 30 días después, sin completar | **Congelamiento** (`frozen_reason = 'majority_release'`, sin fecha de purga) | Cron |
| En cualquier momento, aun congelada | Aceptar los términos (y añadir correo si falta) **descongela**; reclamar la cuenta con un código, también | La persona |

Las fechas de la mayoría de edad salen de `countries.age_of_majority` y `age_reference_timezone` (18 y `America/Mexico_City` por defecto). Quien nació un 29 de febrero cumple la mayoría de edad el 1 de marzo en un año no bisiesto (`majorityDateOf` en `src/common/age/age.util.ts`, la misma aritmética que `ageAt`).

### Estados de la persona

| Estado | Condición en `dependent_profiles` | Principal que resuelve el servidor |
|---|---|---|
| Rastreada | Fila presente, `released_at` nulo | Menor: el de la Fase 3 (`supervised_user`, dispositivo vinculado o actuando) |
| Avisada | `majority_notice_sent_at` puesto | Igual; solo cambia lo que se muestra |
| Liberada, pendiente | `released_at` puesto, sin `release_completed_at`, sin `frozen_at` | `released_user`, fase `pending` |
| Congelada | `frozen_at` puesto con `frozen_reason = 'majority_release'` y sin `purge_after` | `released_user`, fase `frozen` |
| Completada | `release_completed_at` puesto (aceptó **y** tiene correo) | `user` (adulto común) |

La compuerta es **perezosa**: con la bandera encendida, el resolver trata como liberada a toda persona rastreada, mayor de edad y sin completar, aunque el cron todavía no haya corrido. Así no hay una ventana entre la medianoche del cumpleaños y las 09:30 UTC. Con la bandera apagada el resolver se comporta exactamente como antes. Una persona adulta que se registró sola y **nunca tuvo** una fila de tutoría (autorregistro de un adolescente sin tutor vinculado) no se rastrea: al cumplir la mayoría de edad es un adulto común (ruling R4).

### La liberación

Por cada persona, en **una transacción** bajo el candado de dependiente: se revalida la edad (una fecha de nacimiento corregida gana al escaneo), se reclama `released_at` con compare-and-set y, en la misma transacción:

- se revocan **todas** las tutorías no revocadas (de personas, de custodia del club y las pendientes) con `consent_status = 'revoked'` y `revoked_reason = 'released'`; no se crea custodia ni se promueve a nadie;
- se revocan los códigos de vinculación abiertos (`second_guardian`, `director_claim`, `teen_guardian_link`), **nunca** los `adult_claim`;
- se desvinculan los dispositivos (`majority`) y se reinicia el reloj de tutor pendiente;
- se audita `family.majority.released` (actor `system`; `family.majority.backfill_released` en el relleno).

Después del commit se sube el epoch de acting-for (el token del tutor deja de actuar en la siguiente petición) y se avisa. Un adulto **encontrado tarde** (ya era mayor cuando la bandera se encendió, por ejemplo un dependiente que ya tenía 18 años) sigue el mismo camino con `release_source = 'catchup'` y un plazo de 30 días desde ese momento. La migración de relleno no libera a nadie: solo garantiza que todo dependiente de una tutoría o acceso supervisado tenga su fila.

### Aceptación, correo y finalización

- La persona lee y acepta los Términos y el Aviso vigentes (`POST /users/me/legal-acceptance`). Se guarda una fila **propia** con `method = 'majority_release'` y `accepted_by_user_id` nulo, para la **misma versión** que el tutor pudo haber aceptado en su nombre (no hay subida global de versión; ver la validez en [docs/legal/README.md](../legal/README.md)). El estado legal de un `released_user` solo cuenta esas filas.
- Si no tiene correo (adolescente con usuario generado), debe añadirlo con `POST /users/me/release/email`; queda **sin verificar** y se envía el correo de verificación. Un correo sin verificar basta para completar (ruling R5). El ex tutor no puede hacerlo por ella.
- Al cumplirse **ambas** condiciones, `release_completed_at` se pone y la persona vuelve al principal `user`; la caché de acting-for se invalida. Eso puede ocurrir con la aceptación o con el correo, lo que llegue último.
- El orden es indiferente y ambos pasos son idempotentes; una segunda aceptación responde 200 sin duplicar filas, y dos aceptaciones simultáneas dejan una.

### Congelado: nunca se borra, nunca bloquea el acceso

Una persona que no acepta en 30 días se congela: `frozen_at`, `frozen_reason = 'majority_release'`, **sin** `purge_after`. Sus datos se ocultan de las listas del club y no se procesan, y se conservan hasta que vuelva. Reglas (rulings R1 y R6):

- **Nunca se purga sola.** El cron de purga salta siempre las filas con `frozen_reason = 'majority_release'`, con la bandera encendida o apagada. Solo la persona puede pedir la eliminación (`DELETE /auth/me`), igual que cualquier adulto. Los congelamientos antiguos (`frozen_reason` nulo) conservan los 90 días de purga.
- **El congelamiento no bloquea el inicio de sesión.** Si tiene credenciales, entra y aterriza en la pantalla de liberación («Eres mayor de edad y aún no has reclamado tu cuenta»): añade correo si falta, acepta los términos y queda descongelada y activa (`frozen_at` y `frozen_reason` a `NULL`, `family.release.thawed`). Los scopes del principal son los **mismos** en `pending` y `frozen`.
- **Sin plazo para recuperarse.** El `adult_claim` se puede pedir y canjear en cualquier momento, también congelada.
- Un congelamiento antiguo (menor sin tutor) **nunca** se descongela por esta vía.
- El congelamiento no cierra sesiones ni revoca códigos `adult_claim`; **no se avisa a los ex tutores** (ruling R3, privacidad): solo a la persona.

### Persona sin cuenta: reclamar con un código (`adult_claim`)

Un dependiente que nunca tuvo cuenta (menor de 13 años, o sin acceso propio) no tiene credenciales al ser liberado: no puede aceptar nada. Un **código de reclamo** le da acceso:

1. Lo emite un **ex tutor** (`POST /guardianships/me/released/:dependentId/adult-claim-code`, desde «Historial» en Mi familia) o, si el menor estaba bajo custodia del club (o su ex tutor no tiene usuario), un **director** con `club_members:approve` en la sección (`POST /club-sections/:clubSectionId/dependents/:userId/adult-claim-codes`, desde el perfil del miembro en la app). Formato `XXXX-XXXX`, vigencia de 14 días; el código en claro sale una sola vez y solo se guarda su HMAC; uno nuevo reemplaza al abierto. El ex tutor y el director son avisados al liberarse la persona (`majority_handover`), porque el código no puede generarse en el cron.
2. La persona lo canjea en la pantalla pública «Tengo un código de acceso» (login → `/adult-claim`) con `POST /auth/adult-claim/redeem` (código, correo y contraseña). En **una transacción** se consume el código, se guarda el correo (sin verificar) y se crea la credencial. **No** se devuelven tokens y **no** se acepta nada: la persona inicia sesión con su correo y aterriza en `/release`, donde acepta los términos y queda activa.
3. Seguridad: el mismo 400 uniforme (`GUARDIANSHIP_LINK_CODE_INVALID`) para código desconocido, vencido, usado, revocado, mal formado, de otro propósito o de una persona purgada; el código no se consume si falla una precondición (404 `FAMILY_ADULT_CLAIM_NOT_RELEASED`); 409 `FAMILY_ADULT_CLAIM_EMAIL_UNAVAILABLE` si el correo es de otro; bloqueo por IP (10 fallos en 24 h) y limitación a 10 por hora; el código se comprueba **antes** de calcular el hash de la contraseña. No se crea ninguna tutoría.
4. El claim no se puede usar si la persona ya tiene cuenta o acceso por nombre de usuario, ya completó o tiene un congelamiento antiguo.

### Historial del ex tutor

`GET /guardianships/me/history` devuelve, para el ex tutor, las personas que liberó: nombre (nulo si se purgó), parentesco, fecha de liberación y `can_issue_claim`. Nada de salud, club, progreso ni contacto. `Mi familia` **no** lista ya a la persona liberada y esta no cuenta para el tope de 10 dependientes (la lista aplica el corte por edad aun entre la medianoche y el cron); el ex tutor deja de recibir sus avisos de seguridad y resúmenes, sus pushes y su `X-Acting-For` (403). Al eliminar la cuenta de un tutor que solo tiene personas liberadas no se pide confirmación de menores (`deletion-impact` solo lista menores).

### Avisos y recordatorios

Todos los avisos de la Fase 4 son **obligatorios** (fuentes `family:majority:*`, prefijo en `MANDATORY_SOURCE_PREFIXES`): el usuario no los puede silenciar. Los envía el propio cron por push y bandeja (`data.type` `majority_notice`, `majority_released`, `majority_reminder`, `majority_frozen` y `majority_handover`) y, **solo a la persona** y cuando tiene correo, por correo (plantilla `majority-release.tsx` en es, en, fr y pt-BR, sin credenciales ni enlaces; con `EMAIL_ENABLED=false` se omite sin fallar). Los textos del servidor van en español.

| Aviso | Cuándo | Recibe |
|---|---|---|
| `notice` | 30 días antes | La persona (con cuenta o acceso); los tutores **verificados** (no los pendientes); los directores de la sección solo si el menor está **únicamente** bajo custodia del club |
| `released` («Ahora eres independiente») | Al liberarla | La persona con cuenta o acceso |
| `handover` | Al liberarla, si no tiene cuenta | Los ex tutores y, si había custodia, los directores de la sección; también el emisor de un código cuando se canjea |
| `reminder` | 7 y 1 día antes del plazo | La persona; si no tiene cuenta, ex tutores y directores |
| `frozen` | Al congelarla | **Solo la persona** (ruling R3) |

Un fallo de envío no impide la liberación; si ningún destinatario recibe el aviso de 30 días, el compare-and-set se devuelve y se reintenta al día siguiente. Los avisos de la persona **nunca** se reenvían a los tutores. Un destinatario inalcanzable (sin token de push) solo recibe la bandeja.

### Compuerta del servidor: el principal `released_user`

Principal de la Fase 4 (se suma a `user`, `guardian_acting`, `supervised_user`, `age_unknown_user` y `linked_device`). Denegado por defecto: una ruta solo es accesible si declara uno de sus scopes (`release:read`, `release:email`, `data:export`, `legal:accept` o `account:manage`; **no** `self:read` ni nada de club). Un `ActingScope` puede ahora ser un arreglo («cualquiera de»). Las 13 rutas accesibles (pending y frozen) son: `GET /auth/me`, `GET` y `POST /users/me/legal-acceptance`, `POST /users/me/release/email`, `POST /auth/verify-email/send`, las tres rutas de exportación de datos, `GET /auth/sessions`, `DELETE /auth/sessions`, `DELETE /auth/sessions/:sessionId`, `DELETE /auth/me` y `GET /auth/oauth/providers`; las fija `release-gate.allowlist.spec.ts` contra el registro real. Todo lo demás responde 403 `PRINCIPAL_SCOPE_DENIED` con `kind = released_user` (muestreado en la auditoría). `X-Acting-For` responde 403. No ve datos de club y queda fuera de los pushes de club. Un token anterior a la liberación queda restringido en la siguiente petición; el principal no entra a la lista negra de JWT.

- `GET /auth/me`: `data.mode = 'released'`, `data.principal.release` (`status`, `released_at`, `deadline_at`, `frozen_at`, `purge_after` siempre `null`, `needs_acceptance`, `needs_email`, `login_method`), `data.family = null` y **`data.analytics_anonymous = true`**: la analítica del cliente sigue anónima hasta completar la liberación. `data.family_features.majority_release` expone la bandera. Para un menor, con la bandera encendida, `principal.supervision` suma `majority_date` y `release_notice_sent`.
- La caché del principal supervisado pasa a `supv:v4` (y `supv:v4r` con la bandera encendida; TTL de 60 s recortado a la medianoche local).

### Lista del club

La persona liberada y pendiente **sigue en las listas** como un adulto cualquiera (su rol y su progreso se conservan mientras decide) y los roles que ya veían los miembros ven además `release_status: "pending"` y `release_deadline_at` (la app lo muestra como insignia al director; sin datos personales nuevos). Una persona **congelada** por la liberación sale de las listas y de los conteos de la sección, y vuelve al descongelarse. No se tocó ninguna consulta de `club_role_assignments` (el guard `club-assignment-effectivity` sigue en verde). Los pagos y el progreso se conservan siempre; la anonimización solo ocurre si la persona pide eliminar su cuenta.

### App (sacdia-app) y panel (sacdia-admin)

**App**, `lib/features/majority_release/`:

- **Compuerta de rutas**: el redirect del router evalúa la liberación **antes** de la compuerta legal. Pendiente: solo `/release`, `/access-denied` y los visores de documentos legales. Congelada: `/release/frozen`, `/release` (la aceptación descongela) y `/access-denied`. Ninguna es accesible actuando. Al completarse, `refreshAuthorization()` lleva a la persona al inicio de un adulto.
- **`/release`** (pendiente, y al descongelar): pasos para leer y aceptar los Términos y el Aviso vigentes y, si `needs_email`, añadir el correo (errores 409 en línea, aviso de verificación); cuenta atrás de días hasta el plazo; acciones de exportar y eliminar la cuenta siempre visibles.
- **`/release/frozen`**: explicación de solo lectura (sin fecha de purga ni promesa de borrado), exportar datos, eliminar cuenta y la acción «aceptar para recuperar el acceso» que reutiliza el flujo de `/release`.
- **`/adult-claim`** (pública): código, correo y contraseña; error uniforme ante código inválido y mensaje de bloqueo ante 429; tras el éxito, a iniciar sesión con el correo precargado. Entrada: «Tengo un código de acceso» en el inicio/inicio de sesión.
- **Tutor**: «Historial» en Mi familia, colapsado («Mostrar liberados»), `/family/released` con la entrada mínima (nombre y fecha; «Persona liberada» si se purgó) y la hoja para generar el código (se muestra una vez, copiar y compartir). **Director**: acción en el perfil del miembro, para personas liberadas que venían de custodia (`release_status = pending` y `club_members:approve`).
- **Aviso** descartable en el perfil del menor de 13 a 17 años y en el inicio de un adolescente pendiente (fecha de mayoría de edad y qué pasa después). El banner específico en la app del tutor no se hizo (no hay campo en el contrato; lo cubren el push y la bandeja).
- **Push**: `majority_*` lleva a la persona a `/release` o `/release/frozen` según su estado, al tutor a `/family` (aviso) o `/family/released` (entrega) y a los adolescentes a la bandeja; nunca cambia de perfil.
- **Transversal**: `AuthInterceptor` omite el `X-Acting-For` en `/users/me/release`, `/auth/adult-claim` es pública, `AnalyticsPolicy` trata a la persona liberada como anónima, y las 4 traducciones (es, en, fr, pt-BR) añaden `release.*`, `adult_claim.*`, `family.history.*`, `notifications.majority_*` y los 5 códigos de error.

**Panel**, `src/components/users/user-guardianships-card.tsx` (detalle de usuario, tarjeta de tutorías): bloque «Mayoría de edad» con una insignia (aviso enviado, liberado pendiente, completado o congelado) y las fechas de aviso, liberación, plazo, aceptación y finalización; el congelado por liberación **no** muestra fecha de purga. Es solo de lectura (no hay desbloqueo ni edición desde el panel). El job `family-majority-release` está en `/dashboard/system/jobs` con etiqueta propia y «Ejecutar ahora» (con la confirmación habitual). Los permisos pasan a `guardianship:*` (abajo).

### Bandera, cron y prueba en seco

- `FAMILY_MAJORITY_RELEASE_ENABLED` (por defecto `false`; se lee al arrancar): con ella apagada el cron registra la corrida como omitida (`flag_disabled`), no se avisa ni se libera ni se congela a nadie, la compuerta del resolver no actúa y `family_features.majority_release` es `false`. Apagarla **no** deshace lo ya liberado.
- `FAMILY_MAJORITY_RELEASE_DRY_RUN`: el cron calcula y deja el resumen en el log (`majority_release_dry_run`), sin escribir ni enviar nada.
- Cron `family-majority-release`: `30 9 * * *` UTC, candado `cron:family-majority-release` de 23 h, corrida registrada en `cron_run_log`, falla la corrida si algún elemento falla y reintenta al día siguiente. Detalle en [cron-automation.md](cron-automation.md), job 22.
- `scripts/family-profiles/majority-release-dry-run.ts`: informe de conteos por paso y por país (solo UUID). **Limitación conocida**: con `tsx` 4.23 y Node 24 todo script que arranque Nest e importe `src/app.module` falla con `ERR_INVALID_URL_SCHEME`; la alternativa que funcionó en `development` fue un `.cjs` contra `dist/` (ver DEPLOYMENT-GUIDE §0.6, punto 11.5). **Encender la bandera restringe a la vez a toda persona rastreada mayor de edad**: hacer la prueba en seco y publicar la app con la compuerta antes.

### Permisos renombrados y `legal_representatives` eliminado

- `legal_representative:read|update` pasan a `guardianship:read|update` (migración `20261113130000_family_guardianship_permission_rename`: mismos ids, mismas asignaciones por rol; en Neon `development`, 17 asignaciones por permiso). Se conserva el respaldo `users:*` hasta el **2027-03-31**. La clave de caché de autorización pasa a `auth:context:v9`. Detalle en [rbac.md](rbac.md).
- Se elimina el módulo `legal-representatives`, `GET /users/:userId/legal-representative` y `GET /users/:userId/requires-legal-representative`, y el bloque `legal_representative` de `GET /admin/users/:userId` y del panel. La tabla `legal_representatives` se borra de la base con `20261114100000_family_drop_legal_representatives` (**Pendiente de merge (backend PR #655, en borrador)**; el modelo Prisma ya se quitó; irreversible, después de `pg_dump` por ambiente y con el código ya desplegado); no se copia ningún dato a las tutorías. Ver [contactos-emergencia-representante-legal.md](contactos-emergencia-representante-legal.md).
- Orden de integración por el contrato cruzado: primero los commits del panel y de la app, luego las variables `SACDIA_ADMIN_CONTRACT_REF` y `SACDIA_APP_CONTRACT_REF`, luego el backend (ver DEPLOYMENT-GUIDE §0.6, punto 11.2).

### Decisiones de la Fase 4

Decisiones de producto del 2026-11-12 y ajustes posteriores del mismo día (rulings R1 a R6, vinculantes; donde difieren de la especificación y del diseño originales, mandan estas):

| # | Decisión |
|---|---|
| D1 | **Plazos**: aviso 30 días antes de la mayoría de edad; 30 días después para aceptar los Términos y el Aviso vigentes; si no, congelamiento. (La decisión original purgaba 90 días después del congelamiento; la sustituye R6.) |
| D2 | **El tutor, tras la mayoría de edad, no puede nada operativo** (ni actuar, ni resumen, ni avisos); solo queda una entrada «liberado» en su lista, oculta por defecto. La tutoría se revoca con motivo `released` |
| D3 | **Rol de club y progreso se conservan** mientras decide, visibles al club hasta el congelamiento; pagos y progreso se retienen |
| D4 | **Aceptación por persona** (`method = 'majority_release'`) sobre la misma versión del texto, sin subida global de versión; compuerta de servidor solo para liberados sin aceptar |
| D5 | **Sin correo (usuario generado) debe añadir uno** al liberarse o queda congelado; el tutor no puede hacerlo a los 18 |
| D6 | **Sin cuenta**: código de reclamo `adult_claim` (reutiliza `guardianship_link_codes`) que emite el ex tutor o el director; crea credencial y correo en una transacción |
| D7 | **Ya mayores con tutoría** se tratan como liberados «el primer día», con aviso acortado (en producción no hay ninguno) |
| D8 | **Mayoría de edad y zona horaria por país** para el aviso y la liberación |
| D9 | **Renombrar `legal_representative:read\|update` a `guardianship:read\|update`** ahora, con respaldo `users:*` hasta 2027-03-31, y eliminar la tabla `legal_representatives` |
| D10 | **Aviso de 30 días**: a la persona (push y bandeja, correo si hay), a los tutores verificados (fuente obligatoria) y al director del club solo si el menor está únicamente bajo custodia |
| R1 | **Descongelar**: una persona congelada puede aún aceptar los términos y añadir correo; aceptar (con correo) la descongela. Los scopes de `pending` y `frozen` son los mismos |
| R2 | **Recordatorios 7 y 1 día antes del plazo** (niveles 1 y 2) más un aviso «ya eres independiente» al liberarla (en lugar de los +7/+20/+27 días del diseño) |
| R3 | **Los ex tutores no reciben el aviso de congelamiento** (privacidad) |
| R4 | **Un adolescente autorregistrado que nunca tuvo tutor** (sin fila en `dependent_profiles`) no se rastrea: es un adulto común a la mayoría de edad |
| R5 | **Un correo sin verificar basta para completar** la liberación (la verificación se pide como siempre) |
| R6 | **Nunca se borra solo a un adulto liberado**: el congelamiento no tiene `purge_after`, el cron de purga lo salta siempre, el congelamiento no bloquea el inicio de sesión y el reclamo con código es posible en cualquier momento. Solo la persona puede pedir su eliminación. **Abierto legal**: confirmar con un abogado que conservar de forma indefinida, sin tratamiento, los datos de un exmenor es aceptable bajo la LFPDPPP |

Decisiones de diseño: el congelamiento se separa del de las fases 2 y 3 por una columna `frozen_reason` (NULL en los antiguos); el CHECK `dependent_profiles_frozen_ck` depende del motivo (un congelamiento por liberación tiene `frozen_at` y **nunca** `purge_after`); la aceptación usa índices únicos parciales (una fila del tutor y otra propia para la misma versión); los códigos `adult_claim` reutilizan `guardianship_link_codes`; la compuerta de servidor es un nuevo principal (`released_user`) y no códigos de error propios (`FAMILY_RELEASE_ACCEPTANCE_REQUIRED` y `FAMILY_RELEASE_FROZEN` de la especificación se **sustituyen** por `PRINCIPAL_SCOPE_DENIED`); el historial del tutor es una ruta propia (`GET /guardianships/me/history`) y no `include_released=true`.

### Lo que no incluye la Fase 4

- **Textos legales aprobados**: avisos, aceptación y congelamiento están en borrador (ver [docs/legal/README.md](../legal/README.md)); tampoco se actualizaron el aviso de privacidad ni los términos publicados.
- **Retención indefinida bajo la LFPDPPP**: pendiente de confirmar con un abogado (ruling R6).
- **Purga de adolescentes sin tutor** (`pending-teen-guardian`, Fase 3): sigue congelando a los 90 días y purgando 90 días después; la Fase 4 no la modifica (el criterio de «nunca borrar solo» podría revisarse después).
- **Aviso en la app del tutor por cada dependiente**: se cubre con el push y la bandeja; no hay un banner propio (no hay campo en el contrato).
- **Desbloqueo o edición desde el panel**: solo lectura; tampoco hay una acción de administración para emitir el código de reclamo (lo emiten el ex tutor o el director desde la app).
- **Una opción de dry-run en el registro de crones** del panel: el panel no la ofrece; la prueba en seco se hace con la variable o con el script.
- **Cron de purga para adultos liberados**: no existe (decisión R6); si la persona quiere borrar sus datos, lo pide ella.
- **Migraciones aplicadas fuera de `development`**: pendientes; el DROP de `legal_representatives` también en `development`.

### Prerrequisitos de despliegue de la Fase 4

Resumen; el procedimiento completo está en [DEPLOYMENT-GUIDE.md](../deployment/DEPLOYMENT-GUIDE.md), §0.6, punto 11.

1. **Migraciones** en este orden: `20261113100000`, `20261113110000`, `20261113120000`, `20261113140000`, `20261113130000` (renombre de permisos) y, **al final, por ambiente, tras `pg_dump` y con el código ya desplegado**, `20261114100000` (borra `legal_representatives`; irreversible). Las cinco primeras (la Fase 4 propiamente dicha) están aplicadas en Neon `development`, `staging` y `production` (2026-11-13). La última, `20261114100000`, está aplicada solo en `development` (2026-11-12, tras `pg_dump`) y su PR (backend #655) sigue en borrador.
2. **Orden de merge por el contrato cruzado** (ya integrado en `development`): commits de renombre del panel y de la app, luego las variables de contrato, luego el backend, luego las variables al SHA integrado.
3. **Bandera**: desplegar con `FAMILY_MAJORITY_RELEASE_ENABLED=false`; publicar la app con la compuerta **antes** de encenderla; prueba en seco en `development` y `staging`; encender en `development` y `preproduction`; `staging` y `production` solo con aprobación y tras la aprobación legal.
4. `FAMILY_MAJORITY_RELEASE_DRY_RUN` solo para la prueba en seco.
5. Un plan de Render siempre encendido para que el cron corra (punto 10 de §0.6).

**Verificación y QA ya hecha**: la API se probó en vivo contra Neon `development` el 2026-11-12 (12 de 13 escenarios pasaron; el que falló destapó que el CHECK `dependent_profiles_frozen_ck` de la Fase 2 impedía congelar sin `purge_after`, corregido y reaplicado). La app y el panel tienen pruebas automáticas; no hay registro de QA manual de las pantallas de liberación en la app ni en el panel. Queda la matriz: adolescente con usuario generado, adolescente con correo, menor solo bajo custodia, persona sin cuenta que reclama con código, y descongelar aceptando.

## Decisiones

| Decisión | Alternativa rechazada | Motivo |
|---|---|---|
| Sustituir el principal en `JwtStrategy.validate` y comprobar scopes en `handleRequest` de los guards de passport | Un guard global aparte; ampliar solo el bypass de dueño | Los `JwtAuthGuard` locales vuelven a ejecutar `validate`; comprobar donde se crea el principal impide que el guard global y los locales discrepen |
| Autorización por **scopes**, denegado por defecto | Lista fija de endpoints | El dispositivo vinculado de la Fase 3 solo tendrá que declarar sus scopes |
| Actuar se permite hasta la **mayoría de edad** mientras no exista cuenta; los 13 años solo se aplican al crear | Cortar a los 13 | Evita dejar fuera a un menor que cumple 13 antes de la Fase 3 |
| `dependent_profiles` como tabla propia | Inferir "sin cuenta"; banderas en `users` | Solo se permite una `ALTER` en `users` (el correo); da identidad explícita y ciclo de congelación y purga |
| Fichas en tabla append-only | Columnas en `guardianships` | Conserva el historial legal y quién subió cada archivo |
| Verificar la **tutoría principal**; los invitados heredan | Verificar a cada tutor | La ficha es del ingreso del menor; un tutor verificado responde por quien invita |
| El bloque de admin reutiliza la familia `legal_representative:read` | Permisos `guardianship:*` nuevos | Evita DML y seeds en la Fase 2; el cambio de nombre llegó en la Fase 4 con la eliminación de la tabla (`guardianship:read\|update`, mismos ids) |
| Pushes dirigidos al menor van a sus tutores, con el nombre del menor | Solo bandeja | Un menor sin cuenta no tiene tokens FCM (A3). La bandeja sigue en el menor |
| Aviso al tutor cuando alguien sube evidencia por el menor | - | El gancho existe; es un no-op cuando el propio tutor sube actuando y cobra sentido con el dispositivo vinculado (Fase 3) |
| **Sin chat ni mensajería entre usuarios** | - | Decisión permanente |
| Tutor elimina cuenta y el menor no tiene club: **congelar 90 días** | Eliminarlo en el acto | El tutor puede ser sustituido por otro y el menor no pierde datos por error |
| **A9 (purga)**: anonimizar la fila `users` **y borrar** salud, contactos de emergencia, fichas (filas y objetos de R2), foto, archivos de evidencia, bandeja, datos del tutor externo e IP y user agent de aceptaciones | Solo anonimizar | Es lo que el usuario pidió con "que se borre"; se amplió tras la verificación 2a (ruling S7) |
| **A14 (cuatro ojos)**: dos reglas. (1) En **toda** tutoría, un tutor vigente del menor no puede verificar su consentimiento, aunque tenga `club_members:approve`: 403 `GUARDIANSHIP_GUARDIAN_SELF_VERIFY` (tutoría `revoked` no cuenta). (2) En la tutoría de **custodia** el club no tiene identidad de usuario, así que el conjunto prohibido es: quien subió la ficha vigente, quien creó al menor y el último tutor que lo dejó en custodia (`guardian_left` o `guardian_account_closed`): 403 `GUARDIANSHIP_CUSTODIAN_SELF_VERIFY`. Otra persona autorizada del club (subdirector, secretario, secretario tesorero u otro director con `club_members:approve`) o un administrador sí | Que el director custodio verifique su propia custodia; que un tutor se auto-verifique por tener permiso en la sección | Evita que una sola persona se auto-autorice un consentimiento |
| Cualquier tutor activo de un menor visible puede subir y leer la ficha; se guarda en la fila principal | Solo el tutor principal | Un tutor secundario ve el mismo estado y puede ayudar; `uploaded_by_user_id` guarda al autor real |
| **Una sola compuerta** de activación (`assertAssignmentActivationAllowed`) llamada por cada escritura que activa `club_role_assignments`, con un guard de pruebas por AST que falla si aparece una escritura nueva sin ella | Comprobar el consentimiento solo en `approve` | Varias rutas activan sin pasar por `approve` (asignar rol, sucesión de director, solicitudes de asignación y transferencia, inscripción anual, corte de año, `PATCH` con `status`); hallazgos C1/C2 de la verificación 2c (`assignment-activation-gate.ts:10-11`) |
| **Ficha bloqueada tras verificar**: subir con el consentimiento verificado es 409 `GUARDIANSHIP_CONSENT_ALREADY_VERIFIED` | Permitir reemplazar la ficha de un consentimiento ya verificado | La ficha verificada es la que revisó el director; el servicio exige revocar y crear una tutoría nueva para cambiarla (`guardian-evidence.service.ts:95-97`) |
| La verificación reinicia el plazo (A11) y una solicitud con consentimiento pendiente vive 30 días | Mantener 8 días | La ficha viaja por el tutor y no debe caducar justo al verificarla |
| Un código no se consume si el canje falla; un canje no puede hacerlo quien lo emitió (403); bloqueo tras 10 fallos en 24 h contados desde el primero con contador atómico | - | Fuerza bruta y autocanje (hallazgos W1, S5 de la verificación 2a) |
| Un tutor eliminado o desactivado no puede actuar | - | La fila de tutoría no basta (hallazgo S1) |
| **Parentesco del tutor por lista cerrada de nombres** (`GUARDIAN_RELATIONSHIP_TYPE_NAMES`); `GET /guardianships/relationship-types` entrega las filas y el cliente envía el id recibido | Lista de UUID fijos; filtrar en el cliente; reutilizar todo el catálogo `relationship_types` | Los UUID son aleatorios por ambiente y el catálogo trae parentescos que no describen a un tutor (p. ej. los de contactos de emergencia); el servidor es la única fuente de la lista y valida igual en crear y canjear |
| Máximo 4 tutores activos por menor y 10 menores por tutor | - | Límites de servicio; `409 GUARDIANSHIP_GUARDIAN_LIMIT_REACHED` y `GUARDIANSHIP_DEPENDENT_LIMIT_REACHED` |
| El menor toma el país del tutor para su política de edad (A3) | País propio | Un menor nuevo no tiene país |
| La interfaz de código de reclamo vive en Mi familia («Tengo un código de vinculación») (A15) | Pantalla aparte | Un solo punto de entrada |
| La app descarta respuestas tardías tras un cambio de perfil y sale del modo actuar ante `ACTING_FOR_FORBIDDEN` (A12/A13) | - | Evita mostrar datos del perfil anterior |
| Los clientes no dependen de `details` (ruling de apply) | - | El filtro HTTP lo quita en producción |
| Backend y app de la Fase 2 se **despliegan juntos** | Desplegar por separado | El backend retira `POST/PATCH/DELETE /users/:userId/legal-representative`, que la app anterior sigue llamando en el post-registro |
| Migración con un único `DROP NOT NULL` permitido (`users.email`) y sin copiar datos | `INSERT` desde `legal_representatives` | El guard de migraciones prohíbe DML; en producción se parte limpio |
| **3c · el menor del director nace `pending` y sin cuenta**: la ruta de registro nunca crea una asignación `active` ni una fila `account`, y la edad válida es `0 <= edad < mayoría de edad` del país de la **sección** | Crear al menor ya activo; reutilizar la edad de 13 del tutor; usar el país del director | La compuerta de consentimiento sigue siendo la única que activa, y el director registra menores de cualquier edad bajo la mayoría de edad |
| **3c · cuatro ojos por id de usuario** (el creador, quien subió la ficha vigente y el tutor que cedió al menor no verifican; un tutor vigente tampoco), sin código de error nuevo | Basarlo en el rol o en la permisología (un admin creador podría verificar); un código de error propio | Quien crea no puede ser quien confirma, aunque tenga el permiso, sea admin o pierda el rol después (P3-A19, A14) |
| **3c · `consent:verify` separado de `club_members:approve`**; `approve: true` exige además `club_members:approve` (403 `MR_APPROVE_PERMISSION_REQUIRED`) | Un solo permiso para verificar y aprobar | Permite un revisor que verifique sin poder aprobar la membresía. Los roles de club con el permiso ya aprobaban; el revisor real es el coordinador (seguimiento `coordinator-consent-verify`) |
| **3c · B11: `consent:verify` solo a roles de club y admin; los coordinadores quedan fuera** (superada por la fila siguiente) | Dárselo a `coordinator`, `zone-coordinator`, `general-coordinator` y `assistant-lf` como planeaba el diseño | La prueba con el guard real demostró que `resolveActorTerritoryScope` no conoce a los coordinadores (403 `GUARD_CLUB_SCOPE_REQUIRED` en su propio territorio). Se retiró del seed y se informó |
| **Seguimiento · coordinadores verifican por asignación, con una opción por ruta (`coordinatorSections`) y no ampliando `canManageClub`** (2026-10-20) | Ampliar `resolveActorTerritoryScope`/`canManageClub` para que conozcan a los coordinadores | `canManageClub` es por club y gobierna la gestión en todas partes (designar directores, finanzas, inventario, seguros); ampliarlo les habría dado esos poderes, y además una asignación `ZONE` cubre un solo tipo de club. La autoridad del coordinador es su asignación (canon `runtime-coordination`) |
| **Seguimiento · opción B: el revisor solo-verificación ve solo lo que puede verificar** (menores con consentimiento `pending` y ficha vigente) | Darle la lista completa de solicitudes | Minimización de datos: un coordinador cubre muchos clubes, y la lista queda como «fichas por verificar» |
| **Seguimiento · `coordinator_paper_form`: un coordinador que verifica deja su propio `verification_method`** (2026-10-21). Se guarda cuando quien verifica llegó por la vía del coordinador (`coordinatorSectionGrant`: rol global de coordinador con `consent:verify` y una `coordinator_assignment` vigente que cubre la sección); director y roles de club con solo `consent:verify` siguen con `director_paper_form`, y `guardian_invite` no cambia. Precondición: si el coordinador además tiene autoridad de club en esa misma sección (director o secretario de ella), `PermissionsGuard` lo deja pasar por la vía de club, `coordinatorSectionGrant` queda en `false` y se guarda `director_paper_form`. El mismo valor va a la respuesta y a `changes.verification_method` del evento `consent_verified`. Las filas verificadas antes quedan como `director_paper_form` | Seguir guardando `director_paper_form` para todos | La QA en vivo del 2026-10-21 guardó `director_paper_form` para un coordinador: el dato no distinguía quién revisó la ficha. El panel muestra «Ficha en papel (coordinador)». La migración `20261024120000_allow_coordinator_paper_form` (commit `74f5412c`) amplía el CHECK `guardianships_verification_method_ck` con el valor nuevo; aplicada en `development`, `staging` y `production` (ver SCHEMA-REFERENCE). Validada el 2026-10-21 contra Postgres real en la rama temporal de Neon `qa-coord-20261021` |
| **Seguimiento · W5: el revisor solo-verificación no sube fichas** | Dejarlo subir la ficha en papel que recibió | Subir es trabajo del tutor o del director, y quien sube queda impedido para verificar en custodia |
| **3c · `viewer_can_verify` / `viewer_verify_block` en la lista, calculados con el predicado de `verify-consent`** | Que los clientes lo deduzcan del usuario que creó o subió la ficha | Los clientes no deben conocer ids de creador ni de quien subió la ficha; un solo predicado evita que la lista y el endpoint discrepen. El servidor (403) sigue mandando |
| **3c · una solicitud vencida de un menor solo bajo custodia lo congela** (`frozen_at`, `purge_after` a 90 días) | Dejarlo activo sin dueño; borrarlo de inmediato | Un menor que el club registró y nadie reclamó sigue el calendario de la Fase 2 (P3-A18) |
| **3c · el aviso de los 13 años reclama la marca antes de enviar** (`teen_login_nudged_at`, compare-and-set); si todos los envíos fallan, la libera | Marcar después de enviar | Dos instancias o un reintento no pueden avisar dos veces; el barrido de dispositivos no depende de la bandera para que el mantenimiento corra siempre |
| **3c · avisar a los tutores cuando un dispositivo se desvincula por `majority` o `expired`** (ruling W6) | No avisar | Si no, el tutor no sabría nunca que el teléfono dejó de funcionar. Una sola vez, gane el barrido o la compuerta |
| **3c · el panel solo desactiva el acceso y desvincula dispositivos, con un motivo obligatorio de 5 a 500 caracteres que solo va a la auditoría**; no hay ruta de admin para habilitar, reactivar ni cambiar contraseñas | Que el admin pueda reactivar o restablecer la contraseña de un menor | Un admin no debe poder entrar como el menor ni fijarle una contraseña; corregir un acceso es cosa del tutor (FP3-66) |
| **3c · las aceptaciones legales del menor las registra el director** (`accepted_by_user_id` = director) | Pedir al tutor que acepte después | El menor no tiene cuenta y el tutor aún no existe; vale la declaración bajo protesta del director (R10) |

## Prerrequisitos de despliegue

1. **Bucket privado de R2 para fichas** (lo crea el usuario): crear el bucket y fijar `R2_BUCKET_GUARDIANSHIP_EVIDENCE` en Render **antes del deploy**. Opcionales: `R2_PUBLIC_URL_GUARDIANSHIP_EVIDENCE` (no hace falta: el bucket es privado) y `R2_KEY_PREFIX_GUARDIANSHIP_EVIDENCE` (por defecto `guardianships/consent`). Sin ellas la app arranca y los endpoints de ficha responden 503; no es un fallo del resto de la API.

   **Almacenamiento en desarrollo**: `R2_BUCKET_GUARDIANSHIP_EVIDENCE` puede apuntar a un bucket privado que ya exista; para QA no hace falta crear uno exclusivo. Compartir bucket es seguro por tres razones, todas de código: (1) los objetos viven bajo el prefijo `guardianships/consent` (`R2_KEY_PREFIX_GUARDIANSHIP_EVIDENCE`, por defecto, `r2-file-storage.service.ts:728-731`) con la clave `{prefijo}/{guardianshipId}/{uuid}.{ext}` (`guardian-evidence.service.ts:322-327`), así que no se mezclan con las claves de otros módulos; (2) se sirven **solo** por URL firmada de 900 s (`guardian-evidence.service.ts:36` y `:457-461`) y `R2_PUBLIC_URL_GUARDIANSHIP_EVIDENCE` nunca se usa para servir (`file-storage.service.ts:61-70`); (3) la purga de 90 días borra únicamente las claves registradas en `guardianship_consent_evidences` (`dependent-profiles-purge-cron.service.ts:273-275`), no barre el prefijo. La condición de seguridad que el código **no** puede comprobar es de infraestructura: ese bucket no debe tener dominio personalizado ni acceso `r2.dev` habilitados. Los nombres de bucket y los valores de entorno no se documentan aquí.
2. **Migración de la Fase 2** `20261016120000_family_profiles`: aplicada en Neon `development`, `staging` y `production` (verificado el 2026-11-12).
3. **Orden de merge y deploy**: backend y app juntos (ver «Decisiones»). El panel puede ir con ellos; sin el backend no muestra nada nuevo.
4. Antes de abrir los PR, el backend debe incluir #528 (validación de ámbito y solicitudes) y #529 (UUID inválido en el guard), ambos ya integrados en la rama, y estar al día con `development`.
5. **Fase 3**: cuatro migraciones más (`20261020120000_family_teen_login`, `20261021120000_family_linked_devices`, `20261022120000_family_director_minors`, `20261022130000_seed_family_permissions`), las banderas `FAMILY_*` por ambiente, la aprobación legal del texto `2.0.0-family` y el aviso a los directores. Todo en `docs/deployment/DEPLOYMENT-GUIDE.md`, §0.6. Las cuatro están aplicadas en Neon `development`, `staging` y `production` (verificado el 2026-11-12).

6. **Fase 4** (backend #654, app #257, admin #305): seis migraciones más (`20261113100000`, `20261113110000`, `20261113120000`, `20261113140000`, `20261113130000` y, la última y por ambiente, `20261114100000`), las variables `FAMILY_MAJORITY_RELEASE_ENABLED` y `FAMILY_MAJORITY_RELEASE_DRY_RUN`, la app con la compuerta antes de encender la bandera y la aprobación legal. Resumen en «Fase 4», «Prerrequisitos de despliegue de la Fase 4»; procedimiento en `docs/deployment/DEPLOYMENT-GUIDE.md`, §0.6, punto 11.

## Lo que no incluye la Fase 2

- Inicio de sesión de adolescentes, dispositivo vinculado, avisos de seguridad y resúmenes para el tutor (Fase 3; la 3a, la 3b y la 3c ya están en `development`, ver «Fase 3»).
- Liberación a la mayoría de edad, reaceptación de términos y eliminación de `legal_representatives` (Fase 4; backend #654, app #257, admin #305, ver «Fase 4»).
- Que el director cree menores (Fase 3c, ya implementada en la rama). En la Fase 2 los códigos de reclamo solo reintegran a una familia un menor que ya está bajo custodia del club.
- Subir la ficha desde el paso 3 del menor actuando (opcional, no implementado; la ruta del tutor ya es segura para agregarlo).
- Exigencia de la aceptación legal en el servidor para el resto de endpoints.
- Cualquier tipo de chat.

## Pruebas automáticas (a 2026-10-19; Fase 3 a 2026-10-20)

> Las cifras son de la corrida previa a los endurecimientos de la compuerta de activación; este pase de documentación no volvió a ejecutar las suites.

| Repo | Resultado |
|---|---|
| Backend | Jest completo: 473 suites, 6882 pruebas pasan, 0 fallan; e2e de acting-for 25 de 25 (arranca el `AppModule` completo, así prueba la inyección de dependencias); `tsc` limpio |
| App | `flutter test`: 2452 pasan, 0 fallan; `dart format` sin cambios; `flutter analyze`: 12 avisos que ya existían |
| Admin | `tsc` limpio; Vitest: 1471 pasan y 1 falla por un fixture que busca la carpeta de la app como repo hermano (ambiental, no relacionado) |

No se ejecutó nada contra una base de datos real, R2, Redis ni dispositivo: eso es la lista de QA manual.

**Fase 3 (cifras informadas por quien implementó cada repo; este pase de documentación no volvió a ejecutar las suites):**

| Repo | Resultado |
|---|---|
| Backend (`32022392`) | Jest completo `--maxWorkers=3`: 535 suites pasan (6 omitidas), 8647 pruebas pasan (34 omitidas), 0 fallan; `tsc --noEmit -p tsconfig.build.json` limpio; e2e de la 3c `test/director-created-minor.e2e-spec.ts` 47 de 47 contra un doble en memoria (no necesita base). En corridas anteriores un worker se cayó con SIGSEGV en `admin-phase-e-catalogs.service.spec.ts` (carga de PGlite); a solas pasa |
| App (`345dadc0`) | `flutter test`: 3188 pasan, 0 fallan (corrida del lote 3 de la 3c); `flutter analyze lib/features/members test/features/members` sin avisos; el análisis completo conserva 12 avisos anteriores |
| Admin | En `05ec6de`: Vitest 1549 pasan y 1 falla por el fixture del catálogo de pantallas que busca la app como repo hermano (ambiental); `tsc` y `eslint` de los archivos tocados limpios. El commit `7a9bfd6` (veredicto del servidor) no está recontado aquí |

**Fase 4** (cifras informadas por quien implementó cada repo; este pase de documentación no volvió a ejecutar las suites):

| Repo | Resultado |
|---|---|
| Backend | Jest completo: 667 suites y 11 365 pruebas pasan (dos suites de PDF fallan bajo carga y pasan a solas: 120 pruebas); `lint:ci`, `tsc` de compilación y `pnpm authz:check` limpios. El spec de la migración de renombrado se corrió contra un Postgres local (4 pasan). Los specs que simulan la base **no** vieron el CHECK `dependent_profiles_frozen_ck`: lo destapó el QA en vivo |
| App | `flutter test`: 4 762 pasan; `flutter analyze` sin avisos nuevos (los anteriores siguen) |
| Admin | `tsc` limpio; Vitest 2 625 pasan; `eslint` de los archivos tocados limpio |

## QA manual pendiente

Requiere el bucket de R2 creado y la migración aplicada en Neon `development`.

**App (simulador de iOS y dispositivo)**

- Añadir un menor: pasos 0 a 3 mientras actúa; cambiador y banner; sin datos viejos tras un cambio rápido Ana a Luis.
- Revocar la tutoría desde otra sesión: mensaje y regreso al tutor.
- Código de vinculación: canje, bloqueo por intentos, código vencido, canje del propio código.
- Tocar un push de un menor: diálogo y cambio de perfil.
- Cada ruta con scope de la lista de metadatos, actuando como menor con consentimiento `pending` y `verified`.
- Un perfil con correo nulo (QR, ajustes, soporte).
- Salir de una tutoría: resultados `other_guardian`, `club_custody` y `frozen`.
- Eliminar cuenta con dependientes (aviso, confirmación y reintento del 409).
- Cámara, galería y PDF en iOS y Android, incluida la negativa de permisos; una foto HEIC de la galería de iOS debe terminar como JPEG; límite de 10 MB; la ficha firmada se abre en el visor (imagen y PDF) y vence a los 15 minutos.
- El tutor sube la ficha, el director verifica, el tutor ve «verificado».
- Autoverificación de custodia bloqueada (403) y el mensaje mostrado.
- 503 con la variable del bucket ausente.
- Reintento tras `approve_error` (difícil de reproducir).

**Panel**

- Insignia, aprobar deshabilitado y diálogo de verificación (ver/subir/reemplazar, casilla obligatoria, aprobar por defecto); mensaje de autoverificación y de 503.
- Detalle de usuario: menor con tutores, tutor revocado, menor en custodia, usuario tutor, menor congelado; «Ver ficha» y «Abrir ficha»; administrador sin `legal_representative:read` no ve la tarjeta.

**Fase 3**: los guiones y su estado están en `docs/testing/FAMILY-PROFILES-PHASE3A-QA.md` (parcial), `docs/testing/FAMILY-PROFILES-PHASE3B-QA.md` (ejecutado en parte) y `docs/testing/FAMILY-PROFILES-PHASE3C-QA.md` (**todo Pendiente**: registro por el director, cuatro ojos, reclamo, tarjeta de acceso familiar, aviso de los 13 años, barrido de dispositivos, banderas apagadas).

**Fase 4** (2026-11-12): la API se probó en vivo contra Neon `development` (12 de 13 escenarios; el fallo era el CHECK del congelamiento, ya corregido). Una cuenta de QA («QaMajority Fixture») quedó liberada y completada en esa base. Pendiente: QA manual de las pantallas `/release`, `/release/frozen`, `/adult-claim`, el historial del tutor y la acción del director en la app; la tarjeta «Mayoría de edad» del panel; y la matriz de personas (adolescente con usuario generado, adolescente con correo, menor solo bajo custodia, persona sin cuenta que reclama con código, descongelar aceptando). No hay guion de QA escrito para la Fase 4.

**Backend / datos** (solo con base real)

- Migración aplicada dos veces, restricciones de la base, conteos reales de throttling, Redis real (`EVAL` del contador) y concurrencia real de Postgres: no se pueden probar sin base ni Redis.
- Purga: congelar un menor de prueba, adelantar `purge_after` y verificar filas y objetos de R2 borrados.

## Referencias

- Contrato HTTP: [ENDPOINTS-LIVE-REFERENCE.md](../api/ENDPOINTS-LIVE-REFERENCE.md) (secciones «Actuar en nombre de un dependiente», `guardianships`, `membership-requests`, `legal-representatives`, `post-registration`, `admin-users`, «Edad mínima de la cuenta»).
- Esquema: [SCHEMA-REFERENCE.md](../database/SCHEMA-REFERENCE.md), «Perfiles familiares»; espejo en `docs/database/schema.prisma`.
- QA de la Fase 3: [3a](../testing/FAMILY-PROFILES-PHASE3A-QA.md), [3b](../testing/FAMILY-PROFILES-PHASE3B-QA.md) y [3c](../testing/FAMILY-PROFILES-PHASE3C-QA.md).
- Promoción de la Fase 3: [DEPLOYMENT-GUIDE.md](../deployment/DEPLOYMENT-GUIDE.md), §0.6. Texto legal en borrador: [docs/legal/README.md](../legal/README.md).
- Registro de decisiones: [DECISIONS-PENDING.md](../audit/DECISIONS-PENDING.md).
- Operación: [runbook de SQL manual y seeds frente a la compuerta](../runbooks/family-profiles-consent-gate-manual-sql.md).
- Fase 4: contrato en [ENDPOINTS-LIVE-REFERENCE.md](../api/ENDPOINTS-LIVE-REFERENCE.md), «Liberación a la mayoría de edad (Fase 4)»; esquema en [SCHEMA-REFERENCE.md](../database/SCHEMA-REFERENCE.md); cron en [cron-automation.md](cron-automation.md), job 22; permisos en [rbac.md](rbac.md); rollout en [DEPLOYMENT-GUIDE.md](../deployment/DEPLOYMENT-GUIDE.md), §0.6, punto 11; puntos legales abiertos en [docs/legal/README.md](../legal/README.md).
- Código: `sacdia-backend/src/guardianships/` (Fase 4: `family-majority-release-cron.service.ts`, `release*.ts`, `adult-claim*.ts`), `src/auth/acting-for/`, `src/auth/supervised/`, `src/legal/`, `src/membership-requests/consent-*.ts`, `src/membership-requests/assignment-activation-gate.ts`, `src/common/guards/README.md` (sección de actuar-en-nombre); `sacdia-app/lib/features/family/`, `lib/features/majority_release/`, `lib/core/consent/`, `lib/core/auth/acting_for_session.dart`; `sacdia-admin/src/components/membership/membership-consent-verify-dialog.tsx`, `src/components/users/user-guardianships-card.tsx`.
