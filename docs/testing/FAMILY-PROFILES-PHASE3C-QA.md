# QA de perfiles familiares, Fase 3c (el director registra menores, panel de acceso familiar y cron de cambios de edad)

**Estado**: PLAN, sin ejecutar. Todos los escenarios están en «Pendiente»
**Fecha del plan**: 2026-10-20
**Ramas**: `feat/family-profiles-phase3` en sacdia-backend (HEAD `32022392`), sacdia-app (HEAD `345dadc0`) y sacdia-admin (HEAD `7a9bfd6`), Pendiente de merge (PR por abrir: feat/family-profiles-phase3) <!-- TODO(orquestador): reemplazar por «PR #NNN» de cada repo cuando existan. -->
**Contrato a probar**: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, «Registro de menores por un director y acceso familiar en el panel (Fase 3c)». Esquema: `docs/database/SCHEMA-REFERENCE.md`, «Registro por director y acceso familiar (Fase 3c)». Feature: `docs/features/family-profiles.md`, «Fase 3».

Este documento es el guion de la 3c, escrito con el mismo estilo que `FAMILY-PROFILES-PHASE3A-QA.md` y `FAMILY-PROFILES-PHASE3B-QA.md`. La columna «Resultado» se llena al ejecutarlo (tarea T3c-Q02); hoy ningún escenario tiene evidencia en vivo. Los usuarios de prueba y cómo crearlos están en `docs/testing/TEST-USERS.md`. Aquí no se anotan contraseñas ni tokens.

## Cómo leer las marcas

- **Verificado**: se ejecutó y el resultado coincide con el contrato.
- **Verificado solo por API**: la API se probó en vivo; la pantalla del simulador o del panel no.
- **Verificado en simulador** / **Verificado en el panel**: se ejecutó en la interfaz contra el backend local.
- **Solo pruebas automáticas**: cubierto por jest, flutter test o vitest, no se corrió en vivo.
- **Pendiente**: no hay evidencia todavía (no se ejecutó, o solo se ejecutó parte del escenario; la nota lo dice).
- **Falla**: el resultado no coincide con el contrato (anotar el hallazgo y el commit del arreglo).

## Precondiciones

1. Backend local contra la rama `development` de Neon con las migraciones `20261022120000_family_director_minors` y `20261022130000_seed_family_permissions` **ya aplicadas** (aplicadas el 2026-10-20 con aprobación del usuario, dos veces cada una; el rol `assistant-admin` no existe en esa rama, así que quedaron 10 asignaciones de permiso). `prisma migrate status` al día.
2. Banderas del servidor, **con reinicio** (la bandera es una foto del arranque): `FAMILY_DIRECTOR_CREATE_MINOR_ENABLED=true` (secciones A a E), `FAMILY_TEEN_LOGIN_ENABLED=true` (sección F y el escenario C5) y `FAMILY_LINKED_DEVICE_ENABLED=true` (secciones E y G). Para H, cada una apagada por separado.
3. Un **año eclesiástico vigente** en la base (sin él el registro responde 500 `POST_REG_NO_ACTIVE_YEAR`; ver A6).
4. Personas de prueba, todas en la **misma sección** salvo que se diga otra cosa:
   - **D**: director de club con `dependents:create` (p. ej. `director-club@sacdia.com`, hoy sección 163; ver `TEST-USERS.md`).
   - **S**: una persona con rol de club `secretary`, `secretary-treasurer` o `deputy-director` **activo en la sección de D** (no es un coordinador). `secretary-club@sacdia.com` está en la sección 1: **no sirve** para la sección de D; hay que crear la asignación en la sección de D.
   - **C**: un coordinador global (`coordinator`, `zone-coordinator` o `general-coordinator`), para documentar la limitación B11.
   - **A**: un administrador con `users:update_admin` y `legal_representative:update`; **A0**: un administrador de solo lectura.
   - **P**: un adulto con cuenta (futuro tutor, para el reclamo); **G**: un tutor **verificado** de un menor sin cuenta (sección F y G); un segundo tutor verificado **G2** del mismo menor (F y G).
5. App: simulador (iPhone 17 Pro, iOS 26) con la sesión de D, otro con la de S, otro con la de P. Panel: sesión de A.
6. **Cómo disparar los crones.** Ninguno tiene endpoint HTTP. Opciones: esperar a su hora (`family-age-transitions` a las 14:00 UTC) o invocar el método desde un script de contexto de aplicación (`NestFactory.createApplicationContext(AppModule)`, precedente `scripts/backfill-monthly-report-pdfs.ts`): `FamilyAgeTransitionsCronService.run(now)` (sin candado; devuelve `{ nudged, skippedNoGuardian, majorityRevoked, expiredRevoked, failed }`) y `MembershipRequestsService.expireStaleRequests()`. Para mover fechas hay que editar filas de `development` a mano con psql (no hay reloj simulado); anotar cada edición y revertirla.
7. Redis disponible (compuerta de principales, contadores).

## Evidencia automática (informada por el backend, la app y el panel; no re-ejecutada al escribir este plan)

| Suite | Resultado informado |
| --- | --- |
| Backend, jest completo `--maxWorkers=3` en `32022392` | 535 suites pasan (6 omitidas), 8647 pruebas pasan (34 omitidas), 0 fallos |
| Backend, e2e `test/director-created-minor.e2e-spec.ts` | 47 de 47, con un doble de Prisma en memoria (no necesita la base) |
| Backend, `tsc --noEmit -p tsconfig.build.json` | limpio |
| App, `flutter test` en `3d11517b` | 3188 pasan, 0 fallan; `flutter analyze` de `lib/features/members` sin avisos |
| Panel, `vitest` en `05ec6de` | 1549 pasan y 1 falla por un fixture ambiental (busca la app como repo hermano); `tsc` y `eslint` de los archivos tocados limpios |

Límites conocidos de esa evidencia: el e2e **no** sube una ficha real (R2; se fuerza el estado de la ficha), sustituye `ClubRoleEligibilityService` y `AuthorizationContextVersionService`, y `NotificationsService.sendToUser` es un espía; el cron de edades se probó con la base simulada; los 403 de `PermissionsGuard` con la territorialidad real solo los cubre `src/auth/permissions-consent-verify.spec.ts`.

## Escenarios

Notación: **M** = el menor que registra D (sin cuenta), **ficha** = la ficha de consentimiento firmada en papel, **req** = la solicitud de membresía de M.

### A. El director registra un menor

| ID | Escenario | Esperado | Resultado |
| --- | --- | --- | --- |
| A1 | Con la bandera encendida, D abre Miembros de su sección en la app y pulsa «Registrar un menor». Llena nombre, apellidos, fecha de nacimiento de **10 años**, marca la declaración bajo protesta y las aceptaciones de Términos y Privacidad en nombre del menor, y envía | La acción solo existe para D (permiso `dependents:create` **y** `family_features.director_create_minor`). Éxito: aviso y vuelta a la lista; en Solicitudes aparece req con la insignia «Menor · consentimiento pendiente». API: 201 `{ dependent { user_id, age: 10 }, guardianship { is_custodian: true, consent_status: "pending" }, assignment { status: "pending", club_section_id } }` | Pendiente |
| A2 | Filas creadas (psql de solo lectura): M, su perfil, la custodia, req y las aceptaciones | `users` con `email` NULL y `country_id` del club de la sección; **sin** fila en `account`; `users_pr` con todo en `false`; `users_roles` rol `user`; `dependent_profiles.created_by_user_id` = D; `guardianships` con `is_custodian`, `custodian_club_id` = club principal, `consent_status = pending`; `club_role_assignments` con `status = 'pending'` (nunca `active`); **dos** `legal_acceptances` con `accepted_by_user_id` = D; una fila `audit_logs` `dependent` / `created_by_director` | Pendiente |
| A3 | Quién recibe el aviso | S (y los demás revisores activos de la sección: `director`, `deputy-director`, `secretary`, `secretary-treasurer`) recibe «Menor · consentimiento pendiente» (fuente `membership_requests:new_request`). **D no** lo recibe | Pendiente |
| A4 | Validaciones por API: `sworn_declaration: false`; clave extra `email`; `access_mode`; una versión legal que no es la vigente | 400 de validación para las tres primeras (nada se crea); 400 `LEGAL_VERSION_MISMATCH` para la última. En la app la versión vencida invalida los documentos legales y desmarca la aceptación | Pendiente |
| A5 | Edad: fecha futura; 18 años; **15 años** (menor de la mayoría de edad del país de la sección) | Futura y 18: 422 `GUARDIANSHIP_DEPENDENT_AGE_OUT_OF_RANGE` (la app muestra el texto del director, **no** el de «Mi familia»). 15 años: 201 (la edad válida es más ancha que la del tutor) | Pendiente |
| A6 | Sin año eclesiástico vigente (poner el rango fuera de hoy en una copia de prueba, o usar una base sin año) | 500 `POST_REG_NO_ACTIVE_YEAR` y **no** queda ninguna fila (ni usuario, ni custodia, ni req) | Pendiente |
| A7 | 31 registros en una hora con D | El 31.º: 429 (throttle de 30 por hora por director) | Pendiente |
| A8 | Quién puede y quién no: un miembro, S sin `dependents:create` y un director de **otra** sección; luego un tutor actuando por un menor, un adolescente supervisado y un teléfono vinculado | Los tres primeros: 403 (la entrada de la app está oculta para quien no tiene el permiso). Actuando: 403 `ACTING_FOR_SCOPE_DENIED`. Adolescente y dispositivo: 403 `PRINCIPAL_SCOPE_DENIED` | Pendiente |
| A9 | Registrar al menor y comprobar «Mi familia» de cualquier tutor | M no aparece en ninguna lista de tutor (no tiene tutor de persona); el selector de perfil no lo ofrece | Pendiente |

### B. Verificación con cuatro ojos

| ID | Escenario | Esperado | Resultado |
| --- | --- | --- | --- |
| B1 | D abre la verificación de req (sin ficha) y luego sube la ficha desde la app | Sin ficha no hay nada que verificar. Después de subirla, el botón de confirmar queda **deshabilitado** con «Otra persona debe verificar este consentimiento: tú registraste al menor, subiste la ficha o lo dejaste bajo custodia del club» | Pendiente |
| B2 | `GET .../membership-requests` como D, como S y como A (todos con ficha ya subida y consentimiento `pending`) | `consent.viewer_can_verify` y `consent.viewer_verify_block`: D `false` / `self_custodian`; S `true` / `null`; A `true` / `null`. En ningún caso aparecen ids de creador ni de quien subió. Antes de subir la ficha: `false` / `null` para todos. Tras verificar: `false` / `null` | Pendiente |
| B3 | D llama a `verify-consent` a la fuerza (API), con `approve: false` y con `approve: true` | 403 `GUARDIANSHIP_CUSTODIAN_SELF_VERIFY` en ambos; el consentimiento sigue `pending` y no hay evento `guardianship.consent_verified`. En la app el mismo 403 deja el botón deshabilitado con el mismo mensaje | Pendiente |
| B4 | D llama a `approve` mientras el consentimiento sigue `pending` | 409 `MR_CONSENT_NOT_VERIFIED`; req sigue `pending` | Pendiente |
| B5 | **S** (secretario de la **misma sección**, no un coordinador) abre la verificación, ve la ficha por URL firmada, marca la casilla y confirma | El botón está habilitado. 200: consentimiento `verified`, `verification_method = director_paper_form`, evento `guardianship.consent_verified` con **S** como actor. Si S tiene `club_members:approve` (el secretario lo tiene en el seed) y confirma con aprobar, req queda `active` en la misma llamada; si no, B6 | Pendiente |
| B6 | D aprueba req ya verificada por S | req `active`; M es miembro de la sección; D ve el éxito. M sigue sin cuenta | Pendiente |
| B7 | Otra req de M2 (creado por D): **S** sube la ficha vigente y luego S intenta verificarla | 403 `GUARDIANSHIP_CUSTODIAN_SELF_VERIFY` (quien sube la ficha vigente no la verifica en una custodia); la lista da a S `false` / `self_custodian`. Otro tercero sí puede (B8) | Pendiente |
| B8 | Un tercero con `club_members:approve` en la sección (otro director o subdirector) verifica una req que D creó y S subió | 200 (un tercero distinto del creador y del que subió) | Pendiente |
| B9 | **C** (coordinador) intenta listar las solicitudes y verificar req | 403 en ambos. Documenta la limitación B11: aunque tuviera `consent:verify`, el guard lo negaría con `GUARD_CLUB_SCOPE_REQUIRED` dentro de su zona. Anotar el `code` real recibido | Pendiente |
| B10 | `approve: true` con un usuario que tiene `consent:verify` pero no `club_members:approve` | 403 `MR_APPROVE_PERMISSION_REQUIRED` antes de tocar nada. **No hay un rol de club así en el seed**: solo se puede probar con un usuario de prueba al que se le quite `club_members:approve` o con las pruebas automáticas. En la app, ese modo muestra «Confirmar verificación» y no aprueba, pero **no se alcanza** desde la lista porque la pestaña de solicitudes exige `club_members:approve` | Pendiente |
| B11 | Un admin que además creó a M intenta verificar | 403 `GUARDIANSHIP_CUSTODIAN_SELF_VERIFY`: la regla va por id de usuario, no por rol | Pendiente |
| B12 | Un tutor vigente del menor (p. ej. P tras el reclamo C2) intenta verificar con `club_members:approve` | 403 `GUARDIANSHIP_GUARDIAN_SELF_VERIFY` y `viewer_verify_block = self_guardian` en la lista | Pendiente |

### C. Reclamo por la familia

| ID | Escenario | Esperado | Resultado |
| --- | --- | --- | --- |
| C1 | D (o S) abre la verificación de M (bajo custodia) y pulsa «Generar código para los padres» en «Entregar a la familia» | Código `XXXX-XXXX`, vigencia de 7 días, se puede copiar y compartir. API 201 `{ code, expires_at }`. Con M ya con un tutor activo, 409 `GUARDIANSHIP_ALREADY_GUARDIAN` | Pendiente |
| C2 | P canjea el código en Mi familia > «Tengo un código de vinculación» con un parentesco de la lista | P queda como tutor **principal**, no custodia, con consentimiento **`pending`**. La fila de custodia pasa a `revoked` con `revoked_reason = claimed`. M aparece en la lista de P. Si M ya estaba aprobado, sigue `active` | Pendiente |
| C3 | Misma situación: la verificación que S hizo bajo custodia | **No se hereda**: el consentimiento vuelve a `pending` con P como tutor principal | Pendiente |
| C4 | P (o el director) sube la ficha nueva y **D, el creador original, la verifica** | 200: la regla de custodia no aplica a la fila del tutor (P3-A26). El evento queda con D como actor. P no puede verificar su propia ficha (`GUARDIANSHIP_GUARDIAN_SELF_VERIFY`, B12) | Pendiente |
| C5 | Con M de **15 años** reclamado: P intenta habilitar el acceso propio antes y después de verificar (`FAMILY_TEEN_LOGIN_ENABLED` encendida) | Antes: 403 `GUARDIANSHIP_CONSENT_NOT_VERIFIED`. Después: se puede habilitar | Pendiente |
| C6 | Canjear el mismo código por segunda vez, y canjear un código vencido | 400 `GUARDIANSHIP_LINK_CODE_INVALID` (uniforme) | Pendiente |
| C7 | Emitir un código para un menor de otra sección o sin asignación viva en la sección | 404 `GUARDIANSHIP_NOT_FOUND` | Pendiente |

### D. Solicitud vencida de un menor en custodia

| ID | Escenario | Esperado | Resultado |
| --- | --- | --- | --- |
| D1 | M nuevo (consentimiento `pending`, solo custodia). Mover `created_at` de req a hace **más de 30 días** y ejecutar `expireStaleRequests` | req queda `expired`. En `dependent_profiles`: `frozen_at = now`, `purge_after = frozen_at + 90 días`. Sus dispositivos (si hubiera) revocados con `dependent_frozen`. M queda congelado (no se lista ni se puede actuar por él) | Pendiente |
| D2 | Con M del mismo tipo pero con solo **29** días | req **no** vence (el plazo mínimo con el consentimiento sin verificar es 30 días) | Pendiente |
| D3 | M con un tutor reclamado (C2) o con otra membresía `pending` o `active` y su req vence | req vence pero M **no** se congela | Pendiente |
| D4 | Adelantar `purge_after` de M congelado y ejecutar el cron `dependent-profiles-purge` | M anonimizado como en la Fase 2 (fila `users` anonimizada, custodia conservada) | Pendiente |

### E. Panel: tarjeta de acceso familiar

| ID | Escenario | Esperado | Resultado |
| --- | --- | --- | --- |
| E1 | A abre `/dashboard/users/{adolescente con acceso propio activo}` | La tarjeta «Acceso familiar» (pestaña Resumen, bajo Tutorías) muestra el estado (Activa / Pendiente de tutor / Desactivada), el método, el origen, quién lo habilitó y el nombre de usuario (solo con el permiso sensible); los correos nulos salen como «—». Sin el permiso `legal_representative:read` la tarjeta no aparece | Pendiente |
| E2 | A pulsa «Desactivar» y escribe un motivo de **menos de 5** caracteres, luego uno válido | El diálogo no deja confirmar con menos de 5 y se queda abierto ante un error. Con motivo válido: el estado pasa a Desactivada. API 200 sin nombre de usuario ni correo en el cuerpo | Pendiente |
| E3 | Efectos de E2 en el adolescente y en sus tutores | La siguiente petición del adolescente: 401 `AUTH_SUPERVISED_ACCESS_REVOKED`. **Todos** los tutores verificados reciben `family:security` «acceso desactivado» (sin motivo ni nombre de usuario). Fila `audit_logs` `admin.supervised_login.disabled` con `changes.reason` y `sessions_revoked`, actor = A | Pendiente |
| E4 | Repetir «Desactivar» (API) y desactivar a un usuario sin acceso propio | Repetir: 200, idempotente, sin nuevo aviso. Sin acceso propio: 404 `SUPERVISED_LOGIN_NOT_FOUND` | Pendiente |
| E5 | A pulsa «Revocar» en un dispositivo activo de un menor (dispositivo vinculado en 3b) con un motivo | El dispositivo pasa a revocado. El teléfono, en su siguiente acción, vuelve a la pantalla de vinculación con el aviso de desvinculación (401 `AUTH_DEVICE_REVOKED`). Los tutores verificados reciben «dispositivo desvinculado». Auditoría `admin.linked_device.revoked` con el motivo | Pendiente |
| E6 | Revocar el dispositivo de **otra** familia usando el `userId` de otro menor; repetir E5 | 404 `DEVICE_NOT_FOUND`; repetir: 200 con los valores originales y sin aviso nuevo | Pendiente |
| E7 | La tarjeta no tiene control para habilitar, reactivar ni restablecer contraseña; probar `POST /admin/users/{id}/supervised-login/reactivate`, `.../enable` y `.../password` | Solo «Desactivar» y «Revocar». Las tres rutas: 404 o 405 | Pendiente |
| E8 | A0 (administrador de solo lectura) y un director de campo fuera del alcance del menor | A0: no ve las acciones; la API responde 403. Fuera de alcance: 404 `ADMIN_USER_NOT_FOUND` | Pendiente |
| E9 | En la tarjeta, abrir las sesiones del usuario (carga bajo demanda) con un teléfono vinculado activo | Las sesiones de usuario llevan su etiqueta normal; la del teléfono vinculado lleva la insignia «Dispositivo vinculado» y la etiqueta del dispositivo | Pendiente |
| E10 | En `/dashboard/requests/membership`: req de M como D-admin creador, como A y la de un adolescente sin tutor | Insignia «Menor» también para el adolescente. Verificar deshabilitado con tooltip para el adolescente sin tutor y para quien el servidor marca `self_custodian`/`self_guardian`. Si se fuerza `MR_APPROVE_PERMISSION_REQUIRED`, el diálogo desmarca «Aprobar» | Pendiente |

### F. Aviso de los 13 años (`family-age-transitions`)

Fixture: menor sin cuenta con tutor **verificado** G, `birthday` = hoy hace 13 años (en la zona del país) y `teen_login_nudged_at` NULL; sin acceso propio habilitado; `FAMILY_TEEN_LOGIN_ENABLED=true`. Disparar con `run()` (precondición 6).

| ID | Escenario | Esperado | Resultado |
| --- | --- | --- | --- |
| F1 | Ejecutar el cron | Resumen `nudged: 1`. G recibe push y bandeja: «{Nombre} ya puede tener su propio acceso» («Puedes activar el inicio de sesión propio de {Nombre} desde su perfil.»), fuente `family:age_nudge`, `data.type = dependent_age_milestone`. `dependent_profiles.teen_login_nudged_at` ya no es NULL. Sin correo | Pendiente |
| F2 | Tocar el push en la app de G (en segundo plano y desde arranque en frío) | Abre el detalle del menor en Mi familia sin cambiar de perfil (si G está actuando por otro menor, sale primero). La sección «Acceso» muestra la tarjeta «ya puede tener su propio acceso» | Pendiente |
| F3 | Ejecutar el cron otra vez, hoy y «mañana» | `nudged: 0`; G no recibe un segundo aviso | Pendiente |
| F4 | Recuperación: menor con 13 años y 3 días y marca NULL (cron «perdido») | Se avisa una sola vez (la comparación es `>=` la edad mínima, no «cumple hoy») | Pendiente |
| F5 | Dos tutores verificados G y G2 | Ambos reciben el aviso; la marca se pone una sola vez | Pendiente |
| F6 | Menor con tutor `pending`, solo con custodia del club o sin tutor | Se omite (`skippedNoGuardian`); la marca **sigue NULL**. Cuando un tutor se verifique, el siguiente cron lo avisa | Pendiente |
| F7 | Menor con acceso propio ya habilitado, congelado, o de 12 años o de 18 | No se avisa | Pendiente |
| F8 | `FAMILY_TEEN_LOGIN_ENABLED=false` (con reinicio) y repetir F1 con otro menor | No se envía nada **y** la marca queda NULL | Pendiente |
| F9 | Fecha límite en una zona distinta de UTC: nacimiento un día antes en Ciudad de México que en UTC | La edad se calcula en la zona del país del menor; el aviso sale según esa fecha | Pendiente |
| F10 | Todos los envíos a los tutores fallan (difícil de reproducir en vivo; hay prueba automática) | El resumen cuenta `failed`, la marca se **libera** a NULL y se reintenta en la siguiente corrida | Pendiente |

### G. Barrido de dispositivos vinculados

Fixture: menor con un teléfono vinculado activo (3b, `FAMILY_LINKED_DEVICE_ENABLED=true`) y tutores verificados G y G2.

| ID | Escenario | Esperado | Resultado |
| --- | --- | --- | --- |
| G1 | Poner el `birthday` del menor con la mayoría de edad cumplida y ejecutar `run()` | `majorityRevoked: 1`. El dispositivo queda con `revoked_reason = majority`. G y G2 reciben **un** «{nombre} · dispositivo desvinculado» con «{nombre} ya tiene la edad para usar su propia cuenta.» El teléfono, en su siguiente acción, 401 `AUTH_DEVICE_REVOKED` | Pendiente |
| G2 | Misma situación pero el teléfono hace una petición **antes** de que corra el cron (la compuerta revoca primero) | El dispositivo queda con `revoked_reason = majority` y los tutores reciben **un solo** aviso; el cron después no avisa de nuevo | Pendiente |
| G3 | `absolute_expires_at` en el pasado (mover la fecha) y menor menor de edad | `expiredRevoked: 1`, motivo `expired`. Aviso con «La vinculación venció después de 180 días; puedes vincularlo de nuevo.» | Pendiente |
| G4 | Dispositivo con las dos condiciones (mayor de edad y vencido) | Gana `majority` | Pendiente |
| G5 | Menor que cumple 13 años con un dispositivo activo | **No** se revoca (el dispositivo sigue vivo hasta la mayoría de edad) | Pendiente |
| G6 | `FAMILY_TEEN_LOGIN_ENABLED=false` | El barrido corre igual y revoca (no depende de esa bandera) | Pendiente |
| G7 | Menor sin tutores verificados restantes | Se revoca sin aviso y sin error | Pendiente |
| G8 | Dispositivo de un menor sin fecha de nacimiento | El cron lo deja; la compuerta del siguiente request lo revoca como `majority` (falla cerrada) | Pendiente |

### H. Banderas apagadas

| ID | Escenario | Esperado | Resultado |
| --- | --- | --- | --- |
| H1 | `FAMILY_DIRECTOR_CREATE_MINOR_ENABLED=false` (con reinicio): `GET /auth/me` de D y `POST /club-sections/:id/dependents` | `family_features.director_create_minor = false`; la app oculta «Registrar un menor». API: 404 `FAMILY_FEATURE_DISABLED`. Un usuario **sin** permiso sigue recibiendo 403 (los guards van antes que la bandera) | Pendiente |
| H2 | Con la bandera apagada, M ya creado: verificar, aprobar, emitir y canjear el código, vencimiento | Todo sigue funcionando; la bandera solo gobierna el registro | Pendiente |
| H3 | Las tres banderas apagadas: compuerta de consentimiento, modo pendiente, crones y avisos | Siguen activos (no tienen bandera) | Pendiente |

### I. Permisos y base de datos (psql de solo lectura)

| ID | Escenario | Esperado | Resultado |
| --- | --- | --- | --- |
| I1 | Permisos efectivos por rol | `director` y `deputy-director` de club: `dependents:create` y `consent:verify`; `secretary` y `secretary-treasurer`: `consent:verify` (y **no** `dependents:create`); `coordinator`, `zone-coordinator`, `general-coordinator` y `member`: ninguno de los dos; `admin` y `super-admin`: ambos | Pendiente |
| I2 | Conteo en `development` | 10 filas de `role_permissions` para los dos permisos (la rama no tiene `assistant-admin`) | Pendiente |
| I3 | Columna `dependent_profiles.teen_login_nudged_at` | `timestamptz`, nullable, sin default | Pendiente |
| I4 | Reaplicar las dos migraciones con psql (en transacción que se revierte) | Sin errores y sin cambios | Pendiente |

## Observaciones del autor del plan (verificadas en el código, sin corrida)

1. **B11**: los coordinadores no tienen `consent:verify` y el guard los niega en su propio territorio (`src/auth/permissions-consent-verify.spec.ts`). El guion de «secretario o coordinador verifica» del diseño se cambió a «S, otro director o un subdirector de la sección».
2. **Un revisor con solo `consent:verify` no puede listar ni ver la ficha** (siguen exigiendo `club_members:approve`). Como ningún rol de club tiene `consent:verify` sin `club_members:approve`, B10 no se alcanza con roles reales.
3. **`secretary-club@sacdia.com` pertenece a la sección 1**, no a la del director de prueba; hay que crear la asignación de S en la sección de D (o usar un subdirector).
4. **No hay endpoint para disparar los crones**: ver la precondición 6. Las ediciones de fechas a mano en `development` hay que revertirlas.
5. **Orden de la bandera y los guards en el registro**: un llamante sin permiso recibe 403 incluso con la bandera apagada; el 404 `FAMILY_FEATURE_DISABLED` lo ve solo quien sí tiene el permiso.
6. **`.env.example`** no pudo comprobarse durante la implementación; verificar a mano que liste las tres banderas `FAMILY_*` antes del PR.
7. El texto legal en borrador dice que verifica «un coordinador» y que la app del dispositivo no existe: ambas frases ya son falsas (ver `docs/legal/README.md`, puerta de publicación).

## Datos que dejará la corrida en Neon `development`

Se anotarán al ejecutar (ids de M, de los tutores de prueba y de los dispositivos). Limpiar con los ids que muestre `GET /guardianships/me/dependents` y revertir las fechas movidas a mano.
