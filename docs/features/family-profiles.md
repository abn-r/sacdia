# Perfiles familiares (tutores y menores de 13 años)

**Estado**: IMPLEMENTADO PARCIAL (Fase 2 de 4 implementada en rama y pendiente de merge: `feat/family-profiles` en sacdia-backend, sacdia-app y sacdia-admin; `docs/family-profiles` en este repo). No desplegado. Faltan las Fases 3 y 4 y la Fase 3 bloquea el lanzamiento.
**Verificado contra código**: 2026-10-19 (backend `554552c1`, app `819f257f`, admin `79a7b29`). La compuerta de activación, las reglas de cuatro ojos y el bloqueo de la ficha verificada se releyeron contra el backend `603d3d8e`. Segundo pase del mismo día contra backend `422433c0`, app `df2e6c6f` y admin `4a50314` (lista de parentescos del tutor, selector de club al actuar, `effective_expires_at` y los ajustes de la app y del panel)
**Dominios relacionados**: [auth.md](auth.md) (sesión y post-registro), [membership-requests.md](membership-requests.md) (aprobación de ingreso), [contactos-emergencia-representante-legal.md](contactos-emergencia-representante-legal.md) (representante legal, ahora de solo lectura), [rbac.md](rbac.md) (permisos sensibles), [qr-credencial.md](qr-credencial.md) (correo nulo en la tarjeta)

> [!IMPORTANT]
> **Restricción de lanzamiento (Fase 3)**: esta fase **no** debe llegar a producción sin la Fase 3. Quedan dos huecos que hoy solo existen en desarrollo: (1) un adolescente de 13 a 17 años que se registra solo no tiene tutor ni representante legal (las rutas de escritura del representante se retiraron y aún no hay inicio de sesión supervisado), y (2) puede existir brevemente una cuenta social de un menor de 13 años hasta que intente guardar su fecha de nacimiento. Detalle en «Fases y restricción de lanzamiento».

## Descripción de dominio

Un menor de 13 años (el corte depende del país) no puede tener cuenta propia. Antes se registraba solo y un `legal_representatives` no resistía el uso real (un representante por menor, representantes externos sin usuario, sin evidencia ni verificación). Ahora el **tutor adulto** es el titular de la cuenta: registra al menor como un **dependiente** (un perfil `users` sin cuenta de acceso ni correo), actúa por él con el mismo token del tutor y, para que el menor ingrese a un club, un **director verifica la ficha de consentimiento firmada en papel** antes de aprobar la solicitud.

No hay chat ni mensajería entre usuarios, ni ahora ni después. La app y el panel solo muestran quién responde por quién.

## Fases y restricción de lanzamiento

| Fase | Contenido | Estado |
|---|---|---|
| 1 | Aceptación legal de Términos y Aviso de Privacidad | Mergeada (backend #515, #516, #518; app #177; docs #139, #140) |
| 2 | Tutorías, perfiles dependientes, actuar en nombre del menor, verificación del director (esta página) | Implementada en rama; ver sub-fases abajo |
| 3 | Inicio de sesión supervisado de 13 a 17 años, dispositivo vinculado del menor de 13 años (QR del tutor), avisos de seguridad al tutor, resúmenes para el tutor | **No iniciada. Bloquea el lanzamiento a producción** |
| 4 | Liberación a los 18 años (cron), reaceptación de términos, eliminación de `legal_representatives` | No iniciada |

La Fase 2 se entregó en tres sub-fases sobre **una rama y un PR por repo** (excepción de tamaño aprobada; los commits por unidad de trabajo son la mitigación de revisión): **2a** backend base y actuar-en-nombre, **2b** app (Mi familia, cambio de perfil, post-registro), **2c** verificación del director (backend, app y panel).

Huecos que la Fase 3 debe cerrar antes de producción:

- Un adolescente de 13 a 17 años que se registra por su cuenta no tiene tutoría y ya no puede registrar un representante legal. No hay cadena de consentimiento para él.
- Un dependiente que cumple 13 años **sigue gestionado por su tutor hasta la mayoría de edad** (no hay Fase 3 que le dé acceso propio). Es intencional: actuar se corta por mayoría de edad, no por los 13 años.
- Una cuenta social (Google/Apple) de un menor de 13 años se crea sin pasar por `POST /auth/register`; solo la frena `PATCH /users/:userId` cuando guarda su fecha de nacimiento (paso 2 del post-registro). Decisión A4/A5: se acepta en la Fase 2 y se endurece en la Fase 3.
- Tampoco existe todavía un flujo para que el director **cree** menores: los códigos de reclamo (`director_claim`) solo devuelven a una familia un menor que ya está bajo custodia del club.

## Modelo de datos

Una migración, `20261016120000_family_profiles` (17 sentencias, sin DML, única `ALTER` a una tabla existente fuera de `countries`: `users.email DROP NOT NULL`). Detalle por columna en [SCHEMA-REFERENCE.md](../database/SCHEMA-REFERENCE.md), sección «Perfiles familiares».

| Concepto | Tabla / columna | Reglas clave |
|---|---|---|
| Dependiente | `users` sin fila `account`, `email` NULL, más `dependent_profiles` | Una fila por menor; guarda quién lo creó, `frozen_at`, `purge_after` y `purged_at` |
| Tutoría | `guardianships` | Una fila por tutor (o por custodia de club) y menor; las revocadas se conservan como historial. Máximo 10 dependientes por tutor y 4 tutores activos por menor |
| Consentimiento | `guardianships.consent_status` | `pending`, `verified` o `revoked`. `verified` solo lo escribe la verificación del director (`director_paper_form`) o la promoción de un tutor invitado (`guardian_invite`) |
| Ficha firmada | `guardianship_consent_evidences` | Append-only; una sola vigente por tutoría; bucket privado de R2 |
| Código de vinculación | `guardianship_link_codes` | 8 caracteres Crockford (`XXXX-XXXX`), solo se guarda el hash HMAC; un solo uso |
| Política de edad por país | `countries.minor_self_login_min_age`, `age_of_majority`, `age_reference_timezone` | Valores por defecto 13, 18 y `America/Mexico_City` si el país es desconocido |

Tipos de tutoría:

- **Tutor con cuenta**: la fila normal. Uno es el **principal** (puede quitar a un secundario).
- **Custodia del club** (`is_custodian`): cuando el último tutor sale y el menor tiene una asignación `active` o `pending`, el club queda como titular de la fila. El club no es un usuario, así que "el custodio" no tiene identidad persistida (ver regla de cuatro ojos).
- **Tutor externo** (`external_name`): solo viene de importar `legal_representatives` con el script de desarrollo; no da acceso.
- **Datos de prueba** (`is_test_data`): nunca cuentan como consentimiento ni dan acceso.

`legal_representatives` queda de **solo lectura** hasta la Fase 4. Las tutorías la reemplazan.

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
14. **Inicio de un tutor sin club**: quien cerró el post-registro como «solo tutor» no tiene resumen de club que mostrar. El inicio muestra «Tu cuenta está lista» con una única acción, **Ir a Mi familia** (`dashboard_view.dart:73-77` y `:363-422`, claves `dashboard.guardian_no_club.*`). La condición es `isGuardianWithoutClub` (`authorization_utils.dart:223-235`): no se está actuando, no hay ninguna asignación de club visible (activa, pendiente, inactiva o vencida; las `designated` no cuentan) y, o bien `family.is_guardian` o `family.dependents_count > 0`, o bien el post-registro está completo con la autorización devuelta sin clubes. No usa campos nuevos del servidor.
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
- **Detalle de usuario** (`/dashboard/users/[userId]`, pestaña Resumen): tarjeta de **tutorías** con quién responde por el usuario (historial incluido, con quién verificó y cuándo), por quién responde él, y el ciclo de congelación. «Ver ficha» pide la URL firmada al hacer clic y la abre en una pestaña nueva. Se oculta si el actor no tiene `legal_representative:read` (ni el respaldo `users:read_detail`) o si el bloque está vacío. Un correo nulo se muestra como «—».
- Las tutorías **no se editan desde el panel**: el panel solo lee.
- **Un dependiente se muestra «Sin acceso propio»** en el detalle de usuario. Los interruptores App, Panel y Estado de «Roles y acceso» guardan banderas de un inicio de sesión que no existe, así que se reemplazan por el aviso «Sin acceso propio · Gestionado por su tutor» (`resumen-tab.tsx:160-174`, `data-testid="dependent-no-access"`); en la barra lateral, «Acceso a la app» muestra «Sin acceso propio» y «Acceso al panel», «No» (`users/[userId]/page.tsx:609-624`). La señal es `guardianships.dependent_profile != null` (`page.tsx:162`), por lo que solo funciona si el actor puede leer ese bloque (`legal_representative:read`); sin ese permiso el bloque llega `null` y se ven las banderas de siempre.
- **La sección de representante legal vacía se oculta**: el representante legal es de solo lectura y heredado, así que la sección (06) solo se dibuja si existe un registro (`resumen-tab.tsx:210`). Cuando existe, se titula «Representante legal (heredado)» con la nota «Registro heredado, solo lectura. Las relaciones actuales se gestionan en Tutorías.» (`page.tsx:390-391`). Antes mostraba «Sin representante legal registrado.».
- **Creador del perfil**: la tarjeta de tutorías muestra «Creado por» con los primeros 8 caracteres del id, como enlace al detalle de ese usuario (`/dashboard/users/<id>`; el id completo va en el `title`). La API solo devuelve el id del creador, no su nombre (`user-guardianships-card.tsx:47-49` y `:318-332`). Antes se imprimía el UUID completo.
- **Vencimiento efectivo en solicitudes de membresía**: la columna de vencimiento muestra `effective_expires_at ?? expires_at` (`pending-members-table.tsx:58-61` y `:210`) y el aviso «vence pronto» (menos de 48 horas) usa ese mismo valor. Mientras el consentimiento del menor está pendiente se añade un icono de información con el texto «Se extiende mientras el consentimiento está pendiente» (`:267-281`). El tipo `MembershipRequest` gana `effective_expires_at` (`src/lib/api/membership-requests.ts:44-54`).
- **Columna de acciones fija**: en la tabla de solicitudes pendientes (`/dashboard/requests/membership` y el panel de pendientes del club) la columna de acciones queda pegada al borde derecho con fondo opaco, así aprobar, verificar y rechazar siguen al alcance cuando la tabla se desplaza en horizontal en anchos estrechos (`pending-members-table.tsx:70-78`, `:199` y `:288`).

## Verificación del director (backend)

Contrato en [ENDPOINTS-LIVE-REFERENCE.md](../api/ENDPOINTS-LIVE-REFERENCE.md), secciones `membership-requests`, `guardianships` y `admin-users`. Resumen de reglas:

- **Compuerta de consentimiento**: ver la sección siguiente. Aprobar una solicitud de un dependiente sin tutoría verificada responde 409 `MR_CONSENT_NOT_VERIFIED`; adultos y adolescentes con cuenta no cambian.
- **Ficha**: la suben el tutor (cualquier tutor activo) o el director en un bucket privado de R2 (JPEG, PNG, WebP o PDF, 10 MB, bytes mágicos; HEIC se rechaza y la app lo convierte). Una subida nueva reemplaza a la anterior sin borrar el objeto **mientras el consentimiento esté pendiente**. Una vez verificado, la ficha queda **bloqueada**: cualquier subida (del tutor o del director) responde 409 `GUARDIANSHIP_CONSENT_ALREADY_VERIFIED` y reemplazarla exige una tutoría nueva tras revocar (`guardian-evidence.service.ts:403-419`, comprobado antes de guardar y otra vez dentro de la transacción con el candado del menor, `:320` y `:344`). Solo se lee con URL firmada de 900 s; cada lectura y subida se audita.
- **`verify-consent`**: exige ficha vigente y la casilla de confirmación; marca verificada la tutoría principal activa, promueve a los tutores invitados, escribe el evento `guardianship.consent_verified` en la misma transacción, sube el `epoch` de acting-for (los scopes del tutor se amplían en su siguiente petición) y avisa a los tutores. Con `approve: true` aprueba después del commit; si eso falla devuelve 200 con `approve_error` y repetir la llamada reintenta solo la aprobación. Es idempotente.
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
- `approve`: si la solicitud no está `pending` dentro de la transacción (otra revisión, cancelación o expiración), retorna sin activar nada: 409 `MR_ALREADY_PENDING`, o 404 `MR_NOT_FOUND` si es de otra sección (`membership-requests.service.ts:135-143`, `:175-183`). Nunca cae al `updateMany` sin pasar por la compuerta: el post-registro vuelve a poner en `pending` filas rechazadas o vencidas y una de ellas habría coincidido con el `WHERE` sin compuerta (comentario del código).
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

**Purga a los 90 días** (decisión A9: «borrar» es borrar, no solo ocultar). El cron `dependent-profiles-purge` (`20 4 * * *` UTC, lotes de 100):

1. Primero borra los objetos de R2: fichas de consentimiento, foto de perfil, evidencias de clases y especialidades, y certificados, documentos e imágenes de especialidades. Si R2 falla, no cambia nada y reintenta al día siguiente (la corrida se reporta como fallida y alerta).
2. En una transacción: anonimiza la fila `users` (`active = false`, correo, nombre, apellidos, fecha de nacimiento, sangre, género, bautismo, imagen y geografía en NULL), borra alergias, enfermedades, medicinas, contactos de emergencia, filas de ficha, archivos de evidencia, bandeja de notificaciones, vacía las columnas de archivos de sus especialidades y anula el nombre y teléfono del tutor externo y la IP y el user agent de sus aceptaciones legales.
3. **Se conserva** la fila `users` anonimizada, las tutorías (quién lo tuvo a cargo) y el progreso de clases y especialidades, sin archivos.

**Eliminación de cuenta del tutor**: en la misma transacción se ceden o congelan los menores y se anulan la IP y el user agent de las aceptaciones legales del tutor **y de las que hizo en nombre de sus dependientes** (`accepted_by_user_id` = el tutor), porque llevan su IP y dispositivo.

## Decisiones

| Decisión | Alternativa rechazada | Motivo |
|---|---|---|
| Sustituir el principal en `JwtStrategy.validate` y comprobar scopes en `handleRequest` de los guards de passport | Un guard global aparte; ampliar solo el bypass de dueño | Los `JwtAuthGuard` locales vuelven a ejecutar `validate`; comprobar donde se crea el principal impide que el guard global y los locales discrepen |
| Autorización por **scopes**, denegado por defecto | Lista fija de endpoints | El dispositivo vinculado de la Fase 3 solo tendrá que declarar sus scopes |
| Actuar se permite hasta la **mayoría de edad** mientras no exista cuenta; los 13 años solo se aplican al crear | Cortar a los 13 | Evita dejar fuera a un menor que cumple 13 antes de la Fase 3 |
| `dependent_profiles` como tabla propia | Inferir "sin cuenta"; banderas en `users` | Solo se permite una `ALTER` en `users` (el correo); da identidad explícita y ciclo de congelación y purga |
| Fichas en tabla append-only | Columnas en `guardianships` | Conserva el historial legal y quién subió cada archivo |
| Verificar la **tutoría principal**; los invitados heredan | Verificar a cada tutor | La ficha es del ingreso del menor; un tutor verificado responde por quien invita |
| El bloque de admin reutiliza la familia `legal_representative:read` | Permisos `guardianship:*` nuevos | Evita DML y seeds en la Fase 2; el cambio de nombre llega en la Fase 4 con la tabla |
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

## Prerrequisitos de despliegue

1. **Bucket privado de R2 para fichas** (lo crea el usuario): crear el bucket y fijar `R2_BUCKET_GUARDIANSHIP_EVIDENCE` en Render **antes del deploy**. Opcionales: `R2_PUBLIC_URL_GUARDIANSHIP_EVIDENCE` (no hace falta: el bucket es privado) y `R2_KEY_PREFIX_GUARDIANSHIP_EVIDENCE` (por defecto `guardianships/consent`). Sin ellas la app arranca y los endpoints de ficha responden 503; no es un fallo del resto de la API.

   **Almacenamiento en desarrollo**: `R2_BUCKET_GUARDIANSHIP_EVIDENCE` puede apuntar a un bucket privado que ya exista; para QA no hace falta crear uno exclusivo. Compartir bucket es seguro por tres razones, todas de código: (1) los objetos viven bajo el prefijo `guardianships/consent` (`R2_KEY_PREFIX_GUARDIANSHIP_EVIDENCE`, por defecto, `r2-file-storage.service.ts:728-731`) con la clave `{prefijo}/{guardianshipId}/{uuid}.{ext}` (`guardian-evidence.service.ts:322-327`), así que no se mezclan con las claves de otros módulos; (2) se sirven **solo** por URL firmada de 900 s (`guardian-evidence.service.ts:36` y `:457-461`) y `R2_PUBLIC_URL_GUARDIANSHIP_EVIDENCE` nunca se usa para servir (`file-storage.service.ts:61-70`); (3) la purga de 90 días borra únicamente las claves registradas en `guardianship_consent_evidences` (`dependent-profiles-purge-cron.service.ts:273-275`), no barre el prefijo. La condición de seguridad que el código **no** puede comprobar es de infraestructura: ese bucket no debe tener dominio personalizado ni acceso `r2.dev` habilitados. Los nombres de bucket y los valores de entorno no se documentan aquí.
2. **Migración** `20261016120000_family_profiles`: `prisma migrate status` contra Neon `development` debe mostrarla como única pendiente. Aplicarla a Neon `development` para QA es un paso manual aparte con aprobación explícita (psql más la fila en `_prisma_migrations`). Render la corre con `migrate deploy` al final del build.
3. **Orden de merge y deploy**: backend y app juntos (ver «Decisiones»). El panel puede ir con ellos; sin el backend no muestra nada nuevo.
4. Antes de abrir los PR, el backend debe incluir #528 (validación de ámbito y solicitudes; pendiente de merge al 2026-10-19) y estar al día con `development`.

## Lo que no incluye la Fase 2

- Inicio de sesión de adolescentes, dispositivo vinculado, avisos de seguridad y resúmenes para el tutor (Fase 3).
- Liberación a los 18 años, reaceptación de términos y eliminación de `legal_representatives` (Fase 4).
- Que el director cree menores. Los códigos de reclamo solo reintegran a una familia un menor que ya está bajo custodia del club.
- Subir la ficha desde el paso 3 del menor actuando (opcional, no implementado; la ruta del tutor ya es segura para agregarlo).
- Exigencia de la aceptación legal en el servidor para el resto de endpoints.
- Cualquier tipo de chat.

## Pruebas automáticas (a 2026-10-19)

> Las cifras son de la corrida previa a los endurecimientos de la compuerta de activación; este pase de documentación no volvió a ejecutar las suites.

| Repo | Resultado |
|---|---|
| Backend | Jest completo: 473 suites, 6882 pruebas pasan, 0 fallan; e2e de acting-for 25 de 25 (arranca el `AppModule` completo, así prueba la inyección de dependencias); `tsc` limpio |
| App | `flutter test`: 2452 pasan, 0 fallan; `dart format` sin cambios; `flutter analyze`: 12 avisos que ya existían |
| Admin | `tsc` limpio; Vitest: 1471 pasan y 1 falla por un fixture que busca la carpeta de la app como repo hermano (ambiental, no relacionado) |

No se ejecutó nada contra una base de datos real, R2, Redis ni dispositivo: eso es la lista de QA manual.

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

**Backend / datos** (solo con base real)

- Migración aplicada dos veces, restricciones de la base, conteos reales de throttling, Redis real (`EVAL` del contador) y concurrencia real de Postgres: no se pueden probar sin base ni Redis.
- Purga: congelar un menor de prueba, adelantar `purge_after` y verificar filas y objetos de R2 borrados.

## Referencias

- Contrato HTTP: [ENDPOINTS-LIVE-REFERENCE.md](../api/ENDPOINTS-LIVE-REFERENCE.md) (secciones «Actuar en nombre de un dependiente», `guardianships`, `membership-requests`, `legal-representatives`, `post-registration`, `admin-users`, «Edad mínima de la cuenta»).
- Esquema: [SCHEMA-REFERENCE.md](../database/SCHEMA-REFERENCE.md), «Perfiles familiares»; espejo en `docs/database/schema.prisma`.
- Registro de decisiones: [DECISIONS-PENDING.md](../audit/DECISIONS-PENDING.md).
- Operación: [runbook de SQL manual y seeds frente a la compuerta](../runbooks/family-profiles-consent-gate-manual-sql.md).
- Código: `sacdia-backend/src/guardianships/`, `src/auth/acting-for/`, `src/membership-requests/consent-*.ts`, `src/membership-requests/assignment-activation-gate.ts`, `src/common/guards/README.md` (sección de actuar-en-nombre); `sacdia-app/lib/features/family/`, `lib/core/consent/`, `lib/core/auth/acting_for_session.dart`; `sacdia-admin/src/components/membership/membership-consent-verify-dialog.tsx`, `src/components/users/user-guardianships-card.tsx`.
