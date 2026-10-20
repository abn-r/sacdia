# QA de perfiles familiares, Fase 3a (adolescentes de 13 a 17 años)

**Estado**: PARCIAL (tres comprobaciones pendientes, ver «Pendiente»)
**Fecha de las corridas**: 2026-10-20
**Rama**: `feat/family-profiles-phase3` (backend y app), Pendiente de merge (PR por abrir: feat/family-profiles-phase3)
**Contrato probado**: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, «Cuentas supervisadas de 13 a 17 años (Fase 3a)»

Resumen de las pruebas manuales de la sub-fase 3a: API contra el backend local (`:3002`, base Neon `development`, `FAMILY_TEEN_LOGIN_ENABLED=true`) y simulador contra esa misma API. Los usuarios de prueba y cómo crearlos están en `docs/testing/TEST-USERS.md`. Aquí no se anotan contraseñas.

## Cómo leer las marcas

- **Verificado**: se ejecutó y el resultado coincide con el contrato.
- **Verificado solo por API**: la API se probó en vivo; la pantalla del simulador no.
- **Solo pruebas automáticas**: cubierto por jest o flutter test, no se corrió en vivo.
- **Pendiente**: no hay evidencia todavía.

## Evidencia automática (corrida de verificación del 2026-10-20)

| Suite | Resultado |
| --- | --- |
| Backend, jest enfocado (`src/auth`, `src/guardianships`, `src/membership-requests`, `src/users`, `src/notifications`, `src/legal`) | 85 suites, 1831 pruebas, 0 fallos |
| Backend, i18n de códigos de error y validación de entorno | 3 suites, 111 pruebas |
| Backend, e2e (`supervised-login` y `acting-for`) | 2 suites, 77 pruebas |
| Backend, `tsc --noEmit -p tsconfig.build.json` | sin salida (limpio) |
| App, `flutter test test/features/{teen,family,auth,post_registration} test/core` | 1211 pruebas, todas pasan |
| App, suite completa (corrida del QA, después de los arreglos) | 2872 pruebas |

La suite completa de jest del backend (7889 según el último reporte del orquestador) y la paridad de i18n de la app no las ejecutó el verificador.

## Recorridos

### 1. Adolescente que se registra solo (15 años) — Verificado

Recorrido completo en simulador y API:

1. Registro de un adolescente de 15 años. El registro guarda `birthday` y `country_id` (ver el arreglo de `9f83891d` abajo) y el adolescente es `teen_pending` desde la primera petición.
2. Post-registro.
3. Pantalla «Falta tu tutor» (modo pendiente, reloj de 90 días).
4. El adolescente emite un código de vínculo (`POST /users/me/guardian-link-codes`).
5. Un adulto canjea el código y queda como tutor `pending`, sin poderes.
6. El tutor sube la ficha de consentimiento.
7. Un director verifica el consentimiento (recorrido 3).
8. El adolescente ve el modal de transparencia, la aprobación responde **201** y el inicio muestra su club (Estella, Conquistadores, clase Viajero) como miembro.

### 2. Código de vínculo del adolescente — Verificado

Emisión, canje por un adulto, vínculo `pending` sin poderes de control. Un tutor con vínculo `pending` recibe 200 con `ineligible_reason: "consent_not_verified"` en `GET .../supervised-login`, 403 `GUARDIANSHIP_CONSENT_NOT_VERIFIED` en los poderes de control y 409 en el resumen (comprobado por API; contrato en `ENDPOINTS-LIVE-REFERENCE`, sección `guardianships`).

### 3. Alcance de la verificación del director (sección 165 contra 163) — Verificado

La solicitud del adolescente fue a la **sección 165**. `director-lf@sacdia.com` (director del campo local 4) la verificó. `director-club@sacdia.com`, cuyo alcance es la **sección 163** (Estella, Aventureros; ver `TEST-USERS.md`), recibió **403 `GUARD_CLUB_SCOPE_REQUIRED`** sobre la 165, que es lo correcto: un director de club solo verifica en su sección.

### 4. Avisos de seguridad al tutor — Verificado (un aviso); resto solo pruebas automáticas

- Verificado en vivo: la bandeja del tutor recibe `family:consent_verified` y `family:security` «Mateo · nuevo inicio de sesión» (confirma el arreglo del hallazgo BUG-1, abajo).
- Solo pruebas automáticas: bloqueo por intentos fallidos, cambio y restablecimiento de contraseña, acceso habilitado o deshabilitado, y el aviso `family:guardian_linked` al adolescente. Las pruebas del servicio pasan, pero no hay una corrida en vivo posterior al arreglo.

### 5. Resumen del tutor — Verificado

`GET /guardianships/me/dependents/:dependentId/summary` responde 200 con `access_mode: "supervised_login"`, edad 15 y una clase. Sin datos de salud (la lista de campos es cerrada y la comprueba una prueba de allowlist).

### 6. Inicio de sesión por nombre de usuario (handle) — Verificado solo por API

Habilitar el acceso de un dependiente de 14 años con `method = handle`, iniciar sesión con el nombre de usuario generado, y deshabilitar (el tutor vuelve a poder actuar, `origin = guardian_enabled`). **Pendiente en el simulador** (ver abajo). Tras deshabilitar, el token viejo responde `AUTH_SUPERVISED_ACCESS_REVOKED` (arreglo BUG-5).

### 7. Bloqueo por intentos fallidos — Verificado solo por API

429 `AUTH_LOGIN_LOCKED` con la cabecera `Retry-After` y sin `details` en el cuerpo (decisión de diseño: el cliente lee la cabecera). **Pendiente en el simulador** (mensaje de la app con la espera).

### 8. Compuerta legal — Verificado solo por API

Una versión distinta de la vigente responde 400 `LEGAL_VERSION_MISMATCH`. La constante del backend es `2.0.0-family` (borrador, commit `86d3717a`). El flujo de volver a aceptar tras subir la versión no se grabó en el simulador.

### 9. Paso 3 con el tutor actuando (`consent:evidence`) — Verificado solo por API

El tutor sube la ficha desde el paso 3 actuando por el menor (`POST /users/:userId/post-registration/step-3/consent-evidence`).

## Arreglos hechos durante el QA

| Commit | Qué |
| --- | --- |
| backend `3815f954` | BUG-1: los avisos al tutor nunca se enviaban. Causa: `{...NOOP, ...instance}` no copia los métodos del prototipo de una instancia de clase; el puerto ahora se enlaza clave por clave |
| backend `f3d5cd96` | BUG-2: la ventana de deduplicación se reclamaba antes de mirar los destinatarios |
| backend `9f83891d` | BUG-3 (seguridad): el registro no guardaba `birthday`, así que un adolescente de 15 años tenía poderes de adulto hasta guardar la fecha |
| backend `edfbd54a` | BUG-4: una fecha `YYYY-MM-DD` en `PATCH /users/:userId` daba 500 |
| backend `0fcd57b2` | BUG-5: un token en lista negra de un supervisado ahora responde `AUTH_SUPERVISED_ACCESS_REVOKED` |
| backend `f0755479` | BUG-6: fuga de tiempo en el inicio de sesión al saltarse la consulta de la cuenta |
| backend `81b3d00a` | Un adolescente supervisado puede reenviar su fecha de nacimiento sin cambios |
| backend `7e9d5156` | `GET /auth/oauth/providers` lleva `account:manage`, para que una cuenta social de edad desconocida reautentique antes de eliminarse (App Store 5.1.1(v)) |
| backend `035c633f` | C1 (FP3-35): apagar `FAMILY_TEEN_LOGIN_ENABLED` corta las sesiones por nombre de usuario ya abiertas (antes la bandera solo se leía en el inicio de sesión) |
| backend `83ffe7cf` | `member:read` incluye `GET .../enrollments/current` y `GET /camporee-judges/me/assignments`: el inicio del adolescente activo daba 403 en ambas |
| backend `c8d3590b` | FP3-23: el enlace `SUPERVISED_LOGIN_EVENTS` pasa a ser obligatorio (sin `@Optional()`); si falta, el servidor no arranca. Antes todos los avisos al tutor eran una no-operación silenciosa |
| backend `58669c63` | FP3-03 y FP3-07: `GET /dashboard/summary` no devuelve datos de club (`club_name`, `club_type`, `user_role` en `null`, `upcoming_activities` vacío) a un adolescente sin tutor verificado ni a una edad desconocida |
| backend `cce8c687` | Scopes `credential:read` (credencial QR) y `club:context` (`PATCH /auth/me/context`): negados al adolescente pendiente y a la edad desconocida (403 `PRINCIPAL_SCOPE_DENIED`) |
| backend `be1456f6` | `GET /auth/me` vacía el contexto de club para ese principal (`stripClubContext`) |
| backend `4ae0b245` | El adolescente solo revoca vínculos pendientes que él inició; un `second_guardian` pendiente responde 404 `GUARDIANSHIP_NOT_FOUND` |
| backend `63d0b1bf` | Prueba de inventario: las escrituras de `supervised_logins.disabled_reason` se mantienen dentro del CHECK de la base |
| backend `2ee31a54` | Documentación en `src/common/guards/README.md` de los tipos de principal y los conjuntos de scopes de la Fase 3 |
| backend `2a59b814` | Formato de las pruebas de datos de club y de revocación (sin cambio de comportamiento) |
| app `e7e06a7d` | «Eliminar cuenta» en la cabecera del post-registro |
| app `0ba75b48`, `f0b05f0a`, `c9d1a3a8`, `75dea719` | Mensaje del 429, parsers alineados con los contratos confirmados y otros ajustes de la app |
| app `3e38f38d`, `bc7d1aaa` | Se quitó «mensajes» del texto de privacidad: SACDIA no tiene mensajería |

### 10. Sin datos de club ni credencial sin tutor verificado — Solo pruebas automáticas

Decisión de producto (opción A): un adolescente sin tutor verificado y una cuenta de edad desconocida no ven datos de club ni tienen credencial QR, tampoco con una asignación de club `active` anterior al despliegue. Contrato: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, «Sin datos de club ni credencial hasta que haya un tutor verificado».

- Scopes nuevos `credential:read` (`GET /qr/me`, `/qr/me/card`, `/qr/me/card.pdf`, `/qr/member/token`) y `club:context` (`PATCH /auth/me/context`): 403 `PRINCIPAL_SCOPE_DENIED` para un adolescente pendiente y para la edad desconocida. Pruebas: `acting-scope-metadata.spec.ts`, `acting-scope.policy.spec.ts`, `pending-teen-club-data.spec.ts`.
- `GET /auth/me` sin contexto de club para ese principal: `strip-club-context.spec.ts` y `auth.service.spec.ts`.
- `GET /dashboard/summary` con `club_name`, `club_type` y `user_role` en `null` y `upcoming_activities` vacío: `dashboard.controller.spec.ts`, `dashboard.service.spec.ts` y un caso nuevo en `test/supervised-login.e2e-spec.ts`.
- **No** se probó en vivo en el simulador ni contra Neon `development` con un adolescente que ya tuviera una asignación activa.
- **Impacto de producción a vigilar al desplegar**: los miembros de 13 a 17 años con asignación activa previa pierden la credencial, el cambio de contexto y el nombre del club en su primera petición, hasta que un tutor se vincule y un director verifique el consentimiento sobre la asignación activa.
- **Residual conocido, sin corregir**: un token QR emitido antes de que el adolescente pasara a pendiente (TTL de 24 h) sigue validándose al escanearlo hasta que caduca.

### 11. Revocar un vínculo pendiente — Solo pruebas automáticas

El adolescente solo quita los vínculos pendientes que él inició (`invited_by_guardianship_id IS NULL`). Un segundo tutor `pending` invitado por un tutor responde 404 `GUARDIANSHIP_NOT_FOUND`. Prueba: `guardianship-lifecycle.service.spec.ts`.

### 12. Banderas y enlace de avisos — Solo pruebas automáticas

- Falta el enlace `SUPERVISED_LOGIN_EVENTS`: el servidor no arranca. Pruebas: `supervised-login-events.binding.spec.ts` y el e2e `supervised-login`, que resuelve cada consumidor desde el `AppModule` real y comprueba que su aviso llega al tutor verificado.
- Cambiar `FAMILY_TEEN_LOGIN_ENABLED` en un servidor desplegado **exige reiniciar**: `ConfigService` lee la foto del entorno del arranque. Apagarla y no reiniciar deja abiertas las sesiones por nombre de usuario. Al probar C1 en un entorno desplegado hay que reiniciar después de cambiar la variable.

## Pendiente

1. **Inicio de sesión por nombre de usuario en el simulador**: pantalla de login con identificador, error uniforme, mensaje de acceso deshabilitado y de cuenta congelada.
2. **Bloqueo por intentos fallidos en el simulador**: el 429 con `Retry-After` y el texto de la espera.
3. **Comprobación de anonimato en PostHog**: confirmar en el panel de PostHog (y en Sentry) que un adolescente y una cuenta de edad desconocida **no** aparecen identificados. Hoy solo la cubren `analytics_policy_test` y `no_sentry_user_test` y el `analytics_anonymous` de `GET /auth/me`.

Otros puntos abiertos que no son del simulador:

- **C1 (FP3-35)**: con `FAMILY_TEEN_LOGIN_ENABLED=false` las sesiones por nombre de usuario ya abiertas se cortan desde el commit `035c633f` del backend (401 en la siguiente petición y refresh rechazado). Lo cubren pruebas unitarias y un caso nuevo en `test/supervised-login.e2e-spec.ts`; **no** se probó en vivo en el simulador.
- Deshabilitar y restablecer la contraseña, la subida de versión legal y el paso 3 actuando no tienen grabación en el simulador (solo API).
- ~~Aplicación formal de la migración a Neon `development` (tarea T3a-B05)~~ **Hecha**: la migración `20261020120000_family_teen_login` se aplicó a la rama `development` de Neon con aprobación del usuario y se verificó con `prisma migrate status`.
- Recorrido offline (arranque en frío sin red): la app trata al adolescente como adulto hasta que `GET /auth/me` responde (la cuenta guardada no incluye el principal). Documentado, no corregido.

## Datos que quedan en Neon `development`

Usuarios adolescentes `42cd884a-01a0-4077-8106-cc9b9596ca56`, `324440b0-404a-4e29-98db-296e4fa6b24f` y `665990ff-7230-4565-bf94-cbef5b0cc147`; dependiente de 14 años con nombre de usuario `4246d499-598a-40cb-9cea-29ed8ee7485f`; dependiente de 8 años congelado `6271480a-f4f9-4548-9721-b67678d58079`. Los tutores de esa corrida se eliminaron. Antes del arreglo de `7e9d5156` y del botón «Eliminar cuenta» un adolescente no podía eliminarse a sí mismo (`DELETE /auth/me` da 403 `PRINCIPAL_SCOPE_DENIED` para `supervised_user`, a propósito); quedan por limpiar.
