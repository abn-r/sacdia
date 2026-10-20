# QA de perfiles familiares, Fase 3b (dispositivo vinculado de menores de 13 años)

**Estado**: EJECUTADO PARCIALMENTE el 2026-10-20: QA de API (12 escenarios, sin errores) y QA en simulador (iPhone 17 Pro, iOS 26, todo PASS). Los escenarios sin resultado siguen en «Pendiente» (ver «Resultados de la corrida»)
**Fecha del plan y de la corrida**: 2026-10-20
**Rama**: `feat/family-profiles-phase3` (backend), Pendiente de merge (PR por abrir: feat/family-profiles-phase3)
**Contrato a probar**: `docs/api/ENDPOINTS-LIVE-REFERENCE.md`, «Dispositivo vinculado de menores de 13 años (Fase 3b)». Esquema: `docs/database/SCHEMA-REFERENCE.md`, «Dispositivos vinculados (Fase 3b)».

Este documento es el guion de la 3b. La columna «Resultado» registra lo que se ejecutó el 2026-10-20 (API local contra Neon `development` y simulador); lo que no se ejecutó sigue en «Pendiente». Los usuarios de prueba y cómo crearlos están en `docs/testing/TEST-USERS.md`. Aquí no se anotan contraseñas ni tokens.

## Cómo leer las marcas

- **Verificado**: se ejecutó y el resultado coincide con el contrato.
- **Verificado solo por API**: la API se probó en vivo (QA de API, engram #11614); la pantalla del simulador no.
- **Verificado en simulador**: se ejecutó en el simulador (iPhone 17 Pro, iOS 26) contra el backend local.
- **Solo pruebas automáticas**: cubierto por jest o flutter test, no se corrió en vivo.
- **Pendiente**: no hay evidencia todavía (no se ejecutó, o solo se ejecutó parte del escenario; la nota lo dice).
- **Falla**: el resultado no coincide con el contrato (anotar el hallazgo y el commit del arreglo).

## Precondiciones

1. Backend local contra la rama `development` de Neon, con la migración `20261021120000_family_linked_devices` **ya aplicada** (aplicada el 2026-10-20 con aprobación del usuario; `prisma migrate status` al día).
2. `FAMILY_LINKED_DEVICE_ENABLED=true` en el entorno **y reinicio del servidor** (la bandera es una foto del arranque; cambiarla sin reiniciar no surte efecto). `FAMILY_TEEN_LOGIN_ENABLED=true` si se prueba el escenario G1.
3. Un tutor con tutoría **`verified`** sobre un menor registrado de menos de 13 años (sin cuenta ni acceso propio) y con una inscripción de clase y una sección de clase con evidencia posible. Un segundo tutor verificado del mismo menor (para los avisos). Un tutor con vínculo `pending` (para los 403). Un tutor ajeno al menor.
4. Redis disponible (compuerta, contador de fallos de IP). Para el escenario de Redis caído, un entorno aparte.
5. Dos teléfonos o simuladores solo para la sección K; la corrida de API no los necesita.

## Evidencia automática (informada por el backend, no re-ejecutada al escribir este plan)

| Suite | Resultado informado |
| --- | --- |
| Backend, jest completo (`--maxWorkers=3`) en el commit `bbf26068` (informado antes de los arreglos `08ca4338`, `0d40ac40`, `a8af9091` y `1054af7a`; no se re-ejecutó entero después de ellos, cada arreglo trae sus pruebas) | 525 suites, 8303 pruebas pasan, 34 omitidas, 0 fallos |
| Backend, e2e (`supervised-login`, `acting-for`, `linked-devices`, `notifications-security`, `social-sign-in`) | 5 suites, 119 pruebas, incluidas 19 de `test/linked-devices.e2e-spec.ts` |
| Backend, `tsc --noEmit -p tsconfig.build.json` | limpio |
| Directorio e2e completo | 26 suites fallan igual que en la línea base de la 3a (257 pruebas, sin base de datos en el sandbox) |

Límites conocidos de esa evidencia: el e2e de dispositivos usa la aplicación real pero con `ClassesService.uploadSectionFile` y `submitSection` simulados en la frontera del servicio (el aviso al tutor sí es el real) y con el RBAC dejado pasar; el paso «volver a vincular y luego habilitar el acceso propio» está cubierto por pruebas unitarias, no por HTTP; el SQL crudo de refresh no se probó contra un Postgres real (solo la consulta de búsqueda, en PGlite).

## Resultados de la corrida (2026-10-20)

### QA de API (backend local en el puerto 3002 contra Neon `development`, las dos banderas encendidas)

Pasaron los 12 escenarios, sin errores nuevos. Detalle en engram #11614 (`qa/family-profiles-phase3-api-3b`). Lo verificado:

- Token de emparejamiento: 201, `sacdia://pair?t=`, 600 s; 403 actuando por el menor; 403 para el tutor con vínculo `pending`.
- Canje: 200, `aud = sacdia:device`, vigencia 1 h; reutilizar el token y un token basura responden 400 `DEVICE_PAIRING_TOKEN_INVALID`.
- `GET /auth/me` de un dispositivo: `mode = device`, `kind = linked_device`, `analytics_anonymous = true`.
- Lecturas permitidas 200; rutas denegadas 403 `PRINCIPAL_SCOPE_DENIED`; `X-Acting-For` 403 `ACTING_FOR_FORBIDDEN`.
- Evidencia de clase (subir y enviar a validación) 201, y la bandeja del tutor recibe `family:evidence_uploaded`.
- Tope: 409 `DEVICE_LIMIT_REACHED` con dos dispositivos.
- Revocar es inmediato (siguiente petición 401 `AUTH_DEVICE_REVOKED`; el refresh da `AUTH_REFRESH_TOKEN_INVALID`) e idempotente.
- Refresh pone en lista negra el token de acceso anterior; el logout revoca con el motivo `device_logout`.
- Vinculación no elegible: 422 `DEVICE_PAIRING_NOT_ELIGIBLE` (`has_supervised_login` y `age_not_under_min_self_login`).

**No se ejercitó en la API**: el detalle de agenda sin asistentes (el club de prueba no tenía actividades) y el camino del tope **al canjear** (solo al crear el token). Siguen Pendiente C5 y la segunda parte de B7.

### QA en simulador (iPhone 17 Pro, iOS 26, app en `41388c13`)

Todo PASS:

- Vinculación con el enlace profundo `sacdia://pair?t=…`. El simulador no puede escanear, así que se usó el camino de la cámara del sistema; **el escaneo del QR dentro de la app no se ejercitó**. La etiqueta por defecto es el modelo del dispositivo.
- Inicio del dispositivo: «Mi avance», «Próxima actividad», «Mi credencial QR», «Este teléfono» y «Desvincular».
- Clases, detalle de clase y requisito con evidencia: subida de imagen y «Enviar a validación», estado «Enviado».
- Bandeja del tutor: recibió los avisos «dispositivo vinculado» y «Sofi subió evidencia».
- Agenda y Avisos: estados vacíos correctos.
- Registro del backend durante la sesión: ningún 403 originado en el dispositivo.
- El tutor desvincula por API: la siguiente petición del teléfono lo devuelve a la pantalla de vinculación con el aviso «Tu tutor desvinculó este teléfono. Pídele que lo vincule de nuevo.»

### Hallazgos y arreglos durante la corrida

| Hallazgo | Arreglo |
| --- | --- |
| Un enlace de vinculación abierto con la pantalla de vinculación ya visible se ignoraba: go_router aterriza en la misma ruta y la vista solo leía el enlace en `initState` | App `41388c13`, con una prueba de widget (roja sin el arreglo, verde con él) |
| El tipo de sangre llegaba al dispositivo en `GET /users/:userId` | Backend `1054af7a`: la respuesta omite `blood` para un `linked_device` |

Arreglos previos al QA, ya reflejados en el contrato y en estas pruebas: avisos de evidencia solo a tutores verificados (`08ca4338`), logout que revoca antes de borrar la sesión y autocuración de dispositivos huérfanos en el tope (`0d40ac40`), purga que anonimiza `linked_devices` y borra los tokens de emparejamiento (`a8af9091`).

### Seguimientos cosméticos (no se arreglaron)

1. El texto de ayuda bajo «Nombre de este teléfono» aparece truncado con «…».
2. La tarjeta de clase muestra el rango de años «2026–2026».
3. El icono de campana de la pestaña Avisos no hace nada visible en un dispositivo.

## Escenarios

Notación: **T** = tutor verificado, **T2** = segundo tutor verificado, **Tp** = tutor con vínculo `pending`, **X** = persona ajena, **M** = el menor, **D** = el dispositivo (token de dispositivo).

### A. Vinculación feliz

| ID | Escenario | Esperado | Resultado |
| --- | --- | --- | --- |
| A1 | T: `POST /guardianships/me/dependents/{M}/devices/pairing-tokens` | 201 con `pairing_token` (22 caracteres), `qr_payload` = `sacdia://pair?t=<token>`, `expires_in: 600`, `expires_at` a 10 min | Verificado solo por API (201, `sacdia://pair?t=`, 600 s) |
| A2 | `POST /auth/device/pair` con ese token, `platform`, `app_version` y `label` | 200 con `accessToken`, `refreshToken`, `expiresAt`, `tokenType: bearer`, `device { linked_device_id, label }` y `user { id, name (solo primer nombre), avatar }`; sin datos de tutores ni apellidos | Verificado solo por API (200; no se registró cada campo de la respuesta) |
| A3 | Decodificar el `accessToken` (sin tocar la firma) | `aud` es la cadena `sacdia:device`, `iss` `https://api.sacdia.app`, `sub` = M, `sid`, `dev` = `linked_device_id`, `jti`, vigencia 1 h; sin `email` ni `mfa_pending` | Verificado solo por API (`aud = sacdia:device`, vigencia 1 h; el resto de los claims no se anotó) |
| A4 | D: `GET /auth/me` | 200, `data.mode = "device"`, `data.principal.kind = "linked_device"`, `data.principal.device { linked_device_id, label, paired_at }`, `data.family = null`, `data.principal.supervision = null`, `data.analytics_anonymous = true` | Verificado solo por API (`mode = device`, `kind = linked_device`, `analytics_anonymous = true`; `device`, `family` y `supervision` no se anotaron) |
| A5 | T y T2: bandeja y push tras A2 | Aviso `family:security` «{nombre} · dispositivo vinculado» con «{etiqueta} ({plataforma})» a ambos | Verificado en simulador, solo en la bandeja de un tutor (aviso «dispositivo vinculado»); push y T2 sin comprobar |
| A6 | T: `GET .../devices` | `devices[0]` con `status: "active"`, `paired_by_display_name`, `absolute_expires_at` a 180 días, `limits.max_devices: 2`; `GET /guardianships/me/dependents` muestra `linked_devices_count: 1` y `limits.max_devices: 2` | Pendiente |
| A7 | Fila `audit_logs` | `linked_device.paired` con `actor_kind = linked_device`; el token nunca aparece | Pendiente |

### B. Reglas de vinculación

| ID | Escenario | Esperado | Resultado |
| --- | --- | --- | --- |
| B1 | Canjear dos veces el mismo token | La segunda vez: 400 `DEVICE_PAIRING_TOKEN_INVALID` | Verificado solo por API (reutilizar el token: 400 `DEVICE_PAIRING_TOKEN_INVALID`) |
| B2 | Canjear un token desconocido, uno mal formado (no son 22 caracteres base64url) y uno vencido (esperar 10 min o mover `expires_at`) | Los tres: 400 `DEVICE_PAIRING_TOKEN_INVALID` con el **mismo cuerpo** (salvo `timestamp`) | Verificado solo por API para un token basura; token vencido y cuerpo idéntico sin comprobar |
| B3 | T crea un token y luego otro | El primero ya no sirve (400 uniforme); el segundo sí | Pendiente |
| B4 | M con 13 años cumplidos (o sin fecha de nacimiento) | Crear token: 422 `DEVICE_PAIRING_NOT_ELIGIBLE` (con `details.reason = age_not_under_min_self_login` solo fuera de producción) | Verificado solo por API (422 `age_not_under_min_self_login`) |
| B5 | M con una fila `account` o con `supervised_logins` (habilitado o no) | 422 `DEVICE_PAIRING_NOT_ELIGIBLE` (`reason = has_supervised_login` fuera de producción) | Verificado solo por API (422 `has_supervised_login`) |
| B6 | Tp crea un token; X crea un token | Tp: 403 `GUARDIANSHIP_CONSENT_NOT_VERIFIED`; X: 404 `GUARDIANSHIP_NOT_FOUND`. Custodia del club y tutor de prueba (`is_test_data`): 404 | Verificado solo por API la parte de Tp (403); X, custodia y datos de prueba sin comprobar |
| B7 | Con dos dispositivos activos: crear un tercer token, y canjear un token creado antes del segundo canje | Crear: 409 `DEVICE_LIMIT_REACHED`. Canjear: 409 `DEVICE_LIMIT_REACHED` y el token **no** se consume (sigue valiendo si se libera un cupo). El cuerpo del 409 no lleva `max_devices` | Verificado solo por API al **crear** el token (409 con dos dispositivos); el canje con tope no se probó |
| B8 | Familia cambiada entre crear y canjear (revocar la tutoría de T; habilitar el acceso propio de M) | El canje responde el 400 uniforme, no un 4xx distinto | Pendiente |
| B9 | `label` con marcado (`<b>x</b>`), con caracteres de control y de 500 caracteres; `app_version` de 64 caracteres | 200; el `label` queda limpio y de 40 caracteres como máximo (sin `<` ni `>`), por defecto `Dispositivo`; `app_version` de 32 | Pendiente |
| B10 | `platform` distinto de `ios` o `android` | 400 de validación (no el uniforme) | Pendiente |
| B11 | 30 canjes fallidos desde una IP en un día; luego un canje con token válido | 429 `AUTH_LOGIN_LOCKED`, cabecera `Retry-After: 3600`, sin `details`. Un 409 (B7) no suma al contador | Pendiente |
| B12 | Más de 5 canjes en un minuto desde una IP | 429 genérico del throttler | Pendiente |
| B13 | T con `X-Acting-For: {M}` crea un token | 403 `ACTING_FOR_SCOPE_DENIED` (la ruta se llama como el tutor) | Verificado solo por API (403 actuando) |

### C. Superficie del dispositivo

| ID | Escenario | Esperado | Resultado |
| --- | --- | --- | --- |
| C1 | D lee: `GET /users/{M}`, `/users/{M}/classes`, `/users/{M}/classes/{id}/progress`, `/users/{M}/honors`, `/notifications/history`, `/dashboard/summary`, `/qr/me` | 200 (sujeto al RBAC y a los datos de M) | Verificado solo por API (lecturas permitidas 200; no se anotó cada ruta) |
| C2 | D: `GET /users/{M}/allergies`, `PATCH /users/{M}`, `PATCH /auth/me/context`, `GET /clubs`, `GET /auth/sessions`, `DELETE /auth/me`, `GET /guardianships/me/dependents`, `GET /users/me/notification-preferences`, `POST /fcm-tokens` (legado) | 403 `PRINCIPAL_SCOPE_DENIED` con `kind: "linked_device"` (el detalle solo fuera de producción) | Verificado solo por API (403 `PRINCIPAL_SCOPE_DENIED`; no se anotó cada ruta) |
| C3 | D: subir, enlazar o borrar evidencia de una **especialidad** (`POST /users/{M}/honors/{h}/files`, `.../requirements/{r}/evidence/upload`, `.../link`, `DELETE .../evidence/{e}`) | 403 `PRINCIPAL_SCOPE_DENIED` (rutas `honors:write`) | Pendiente |
| C4 | D con `X-Acting-For: {cualquier UUID}` en cualquier ruta | 403 `ACTING_FOR_FORBIDDEN` | Verificado solo por API (403 `ACTING_FOR_FORBIDDEN`) |
| C5 | D: `GET /clubs/{id}/activities` y `GET /activities/{id}` de una actividad con asistentes y RSVP | Las respuestas **no** contienen `attendees`, `rsvp` ni `attendee_profiles`; el resto del payload es igual al de un adolescente. `GET /activity-series/{id}` responde 200 | Pendiente |
| C6 | D: `GET /qr/member/token`, `/qr/me/card`, `/qr/me/card.pdf` | 200 | Pendiente |
| C7 | D: `GET /users/me/supervision` | 200 con `status: null` | Pendiente |
| C8 | Token con las dos audiencias, con la audiencia de dispositivo como arreglo, firmado con otra clave, `alg: none`, y un token de acceso con un claim `dev` inventado | Los cinco: 401 (`GUARD_JWT_UNAUTHORIZED` o el de firma inválida); ninguno autentica como dispositivo | Pendiente |
| C9 | Un token de dispositivo cuyo `sid` es de una sesión de usuario o no existe | 401 | Pendiente |

### D. Evidencia de clases y aviso al tutor

| ID | Escenario | Esperado | Resultado |
| --- | --- | --- | --- |
| D1 | D sube un archivo a una sección de clase (`POST .../sections/{s}/files`) | 201; T y T2 reciben `family:evidence_uploaded` «{nombre} subió evidencia» con «Se subió evidencia de una clase: ...» | Verificado solo por API y en simulador (subida de imagen; el aviso «Sofi subió evidencia» llegó a la bandeja del tutor) |
| D2 | D sube **dos** archivos | Un aviso por cada subida | Pendiente |
| D3 | D borra un archivo y luego envía la sección a validación (`.../submit`) | Ambos 200/204 según el contrato de clases; **no** hay aviso nuevo | Pendiente |
| D4 | Tp (vínculo pendiente) en la bandeja tras D1 | **No** recibe el aviso (solo tutores `verified`; commit `08ca4338`) | Pendiente |
| D5 | T actuando por M (`X-Acting-For`) sube evidencia | **No** hay aviso (el tutor ya lo sabe) | Pendiente |
| D6 | Un archivo inválido o un fallo de R2 en la subida | Sin aviso; la subida no falla por el aviso | Pendiente |
| D7 | El detalle de la sección en una sección de otra clase de M, o de otro menor | 403/404 según el RBAC (el e2e no lo cubre) | Pendiente |

### E. Pushes y tokens de notificación

| ID | Escenario | Esperado | Resultado |
| --- | --- | --- | --- |
| E1 | D: `POST /users/me/fcm-tokens` | 200/201; la fila `linked_devices.fcm_token_id` apunta a ese token | Pendiente |
| E2 | D registra otro token (rotación) | El anterior queda `active = false`; `fcm_token_id` apunta al nuevo | Pendiente |
| E3 | Un push de club dirigido a M (por ejemplo una actividad nueva) | Llega al token de D **y** T/T2 reciben la copia con la etiqueta «{nombre} · {título}»; las fuentes `family:*` no se copian dos veces | Pendiente |
| E4 | T apaga la preferencia de esa fuente | T no recibe la copia; T2 sí | Pendiente |
| E5 | Revocar D (F1) y repetir el push de E3 | Nada llega a D; las copias a tutores siguen | Pendiente |
| E6 | Revocar el último dispositivo con tokens huérfanos del menor | Todos los tokens FCM activos de M quedan `active = false` | Pendiente |

### F. Desvincular

| ID | Escenario | Esperado | Resultado |
| --- | --- | --- | --- |
| F1 | T: `POST .../devices/{d}/revoke` | 200 `{ linked_device_id, revoked_at, revoked_reason: "guardian" }` | Verificado solo por API |
| F2 | D: **la siguiente** petición, con su JWT aún vigente | 401 `AUTH_DEVICE_REVOKED` | Verificado solo por API (401 `AUTH_DEVICE_REVOKED`; en simulador el teléfono volvió a la pantalla de vinculación, ver K5) |
| F3 | D: `POST /auth/refresh` con su refresh token tras F1 | 401 (el refresh token ya no tiene dueño: `AUTH_REFRESH_TOKEN_INVALID`); nunca un JWT de acceso | Verificado solo por API (`AUTH_REFRESH_TOKEN_INVALID`) |
| F4 | T repite la revocación | 200 con el `revoked_at` original y sin escritura ni aviso nuevos | Verificado solo por API (idempotente) |
| F5 | T2 y T tras F1 | T2 recibe «{nombre} · dispositivo desvinculado»; T (quien revocó) no | Pendiente |
| F6 | T revoca un dispositivo de otro menor, o inexistente | 404 `DEVICE_NOT_FOUND` | Pendiente |
| F7 | Tp revoca; X revoca | Tp: 403 `GUARDIANSHIP_CONSENT_NOT_VERIFIED`; X: 404 `GUARDIANSHIP_NOT_FOUND` | Pendiente |
| F8 | `GET .../devices` tras F1 | El dispositivo sigue en la lista con `status: "revoked"` y su motivo; desaparece a los 30 días | Pendiente |
| F9 | T2 (no quien emparejó) revoca un dispositivo | 200 (cualquier tutor verificado puede) | Pendiente |
| F10 | Fila `audit_logs` | `linked_device.revoked` con `reason`; una sola fila aunque se repita F1 | Pendiente |

### G. Revocación automática

| ID | Escenario | Esperado | Resultado |
| --- | --- | --- | --- |
| G1 | T habilita el acceso propio de M (`POST .../supervised-login`, con `FAMILY_TEEN_LOGIN_ENABLED=true`) | 201 con `devices_revoked` igual al número de dispositivos activos; el dispositivo queda `teen_login_enabled` y D recibe 401 en su siguiente petición | Pendiente |
| G2 | El tutor que emparejó D sale (`POST /guardianships/{g}/revoke`, `guardian_left`), con otro tutor T2 y un dispositivo de T2 | D queda `guardianship_revoked`; el dispositivo emparejado por T2 sigue funcionando; T2 puede vincular de nuevo | Pendiente |
| G3 | Sale el último tutor de M (con y sin asignación de club) | Todos los dispositivos quedan `guardianship_revoked` (resultado `club_custody`) o `dependent_frozen` (resultado `frozen`) | Pendiente |
| G4 | El tutor que emparejó elimina su cuenta | Sus dispositivos quedan `guardian_account_closed` | Pendiente |
| G5 | M cumple la mayoría de edad (mover `birthday` en la base de desarrollo) | La **siguiente** petición de D es 401 y la fila queda `majority` (es perezoso; el barrido por cron es de la 3c) | Pendiente |
| G6 | M cumple 13 años (mover `birthday`) | D **sigue** funcionando; crear un token nuevo da 422 | Pendiente |
| G7 | La tutoría de emparejamiento deja de ser `verified` (volver a `pending` en la base) | La siguiente petición de D es 401 y queda `guardianship_revoked` | Pendiente |
| G8 | M congelado (cron de 90 días o a mano) | D es 401 y la fila queda `dependent_frozen`; los tokens FCM de M se borran en la purga | Pendiente |
| G9 | Un admin borra la sesión de D (`DELETE /admin/users/{M}/sessions/{sid}`) | D es 401 y la fila queda `session_revoked`; `GET /admin/users/{M}/sessions` mostraba `kind: "device"` antes | Pendiente |
| G10 | Cada revocación de G2, G4, G9 y la de F1 | Los tutores restantes reciben el aviso de desvinculación; las de G1, G3 (congelado), G5 y G6 no avisan | Pendiente |
| G11 | Tras la purga de M (90 días después de congelar) | Ver «Observaciones»: las filas de `linked_devices` y `device_pairing_tokens` quedan; documentar qué datos conservan | Pendiente |

### H. Refresh y cierre de sesión

| ID | Escenario | Esperado | Resultado |
| --- | --- | --- | --- |
| H1 | D: `POST /auth/refresh` con el refresh token y el access token presentado | 200 con un JWT de **dispositivo** nuevo (`aud: sacdia:device`); el anterior queda en lista negra (401 si se vuelve a usar); la sesión desliza 30 días | Verificado solo por API (el token de acceso anterior queda en lista negra; no se anotó el resto) |
| H2 | Mover `absolute_expires_at` al pasado y refrescar | 401 `AUTH_DEVICE_SESSION_EXPIRED`; la fila queda `expired` | Pendiente |
| H3 | Cerca del tope (`absolute_expires_at` a 10 días) y refrescar | `expiresAt` de la sesión no pasa del tope | Pendiente |
| H4 | D: `POST /auth/logout` con su refresh token | 200; la fila queda `device_logout`; la sesión borrada; T y T2 reciben el aviso | Verificado solo por API (motivo `device_logout`) |
| H5 | Con la bandera apagada (I1), `POST /auth/refresh` de D | 401 `AUTH_DEVICE_REVOKED` sin cambiar datos | Pendiente |

### I. Bandera

| ID | Escenario | Esperado | Resultado |
| --- | --- | --- | --- |
| I1 | Apagar `FAMILY_LINKED_DEVICE_ENABLED` y reiniciar | D: 401 `AUTH_DEVICE_REVOKED` en toda petición; canje: 400 uniforme; crear token: 404 `FAMILY_FEATURE_DISABLED`; `GET .../devices` y la revocación siguen respondiendo; las filas no cambian (`revoked_at` nulo) | Pendiente |
| I2 | Volver a encender y reiniciar | D vuelve a funcionar con el mismo token | Pendiente |
| I3 | Apagar la bandera **sin** reiniciar | Sin efecto (comportamiento documentado de `ConfigService`); anotar si en el entorno de prueba se confirma | Pendiente |
| I4 | `GET /auth/me` | `family_features.linked_device` refleja la bandera | Pendiente |

### J. Registro, auditoría y privacidad

| ID | Escenario | Esperado | Resultado |
| --- | --- | --- | --- |
| J1 | Log de peticiones durante C1 | `userId` aparece como `device:{linked_device_id}`, no como el id de M | Pendiente |
| J2 | Buscar el token de emparejamiento en los logs (pino), en Sentry y en `audit_logs` | No aparece en ninguno; los campos `pairing_token` y `qr_payload` salen redactados | Pendiente |
| J3 | Un 409/400 del canje en Sentry | El cuerpo no lleva el token | Pendiente |
| J4 | Redis caído durante C1 | Se consulta la base; sigue 200 | Pendiente |
| J5 | Base caída o lenta durante una petición de D | 503 `AUTH_REVOCATION_CHECK_UNAVAILABLE`; nunca se concede | Pendiente |
| J6 | `last_seen_at` tras varias peticiones de D en menos de 5 min | Se escribe una sola vez en la ventana | Pendiente |

### K. Simulador (app de la 3b, tareas A01 a A11, ya implementada)

| ID | Escenario | Esperado | Resultado |
| --- | --- | --- | --- |
| K1 | El tutor genera el QR, el simulador del menor lo escanea (`sacdia://pair?t=`) | El teléfono pasa al modo dispositivo y muestra Inicio, Clases, Agenda y Avisos | Verificado en simulador con el enlace profundo (no se escaneó el QR); la etiqueta por defecto fue el modelo del dispositivo |
| K2 | El menor sube una evidencia de clase y la envía | El tutor recibe el push «{nombre} subió evidencia» | Verificado en simulador hasta la bandeja del tutor («Sofi subió evidencia»); el push al teléfono del tutor no se comprobó |
| K3 | Un push de club | Llega al dispositivo y al tutor (con la etiqueta) | Pendiente |
| K4 | Agenda | Sin nombres de asistentes | Parcial: estado vacío de Agenda verificado en simulador; sin actividades no se pudo comprobar la ausencia de asistentes |
| K5 | El tutor desvincula | El dispositivo vuelve a la pantalla de vinculación en su siguiente acción, con el aviso «este dispositivo fue desvinculado» | Verificado en simulador (la desvinculación se hizo por API): vuelve a la pantalla de vinculación con «Tu tutor desvinculó este teléfono. Pídele que lo vincule de nuevo.» |
| K6 | El tutor habilita el acceso propio del menor (3a) | El dispositivo se desvincula | Pendiente |
| K7 | Tercer dispositivo | La app del tutor muestra el límite (`DEVICE_LIMIT_REACHED`) | Pendiente |
| K8 | PostHog en el dispositivo | Desactivado: sin `identify`, sin eventos, sin usuario en Sentry (comprobar en el panel) | Pendiente |
| K9 | Arranque en frío desde un push en el teléfono del tutor (arrastre FP-64 de la 3a) | Abre el destino correcto | Pendiente |
| K10 | Intentar usar el esquema `sacdia://pair` con una sesión de usuario abierta | La app lo rechaza con un mensaje y **sin** llamar a la API | Pendiente |

### L. Restricciones de la base (Neon `development`, a mano con psql, en una transacción que se revierte)

| ID | Escenario | Esperado | Resultado |
| --- | --- | --- | --- |
| L1 | Insertar dos `linked_devices` con el mismo `session_id` | Falla por `uq_linked_devices_session` | Pendiente |
| L2 | `revoked_at` sin `revoked_reason` (y al revés) | Falla por `linked_devices_revoked_ck` | Pendiente |
| L3 | `revoked_reason` fuera de la lista, `platform` distinto de `ios`/`android`, `absolute_expires_at <= paired_at` | Fallan por sus CHECK | Pendiente |
| L4 | Token con `consumed_at` y sin `consumed_device_id` (y al revés) | Falla por `device_pairing_tokens_consumed_ck` | Pendiente |
| L5 | Token con `expires_at` a más de 15 minutos de `created_at` | Falla por `device_pairing_tokens_expiry_ck` | Pendiente |
| L6 | `token_hash` repetido | Falla por la UNIQUE | Pendiente |
| L7 | `supervised_logins.disabled_reason = 'age_majority'` | La base lo acepta (valor reservado, sin uso por la decisión FP3-16 opción A); un valor fuera de la lista falla | Pendiente |

## Observaciones del autor del plan (verificadas en el código, sin corrida)

1. **`max_devices` no viaja en el 409** `DEVICE_LIMIT_REACHED`: el código lo pasa como argumento de la plantilla del mensaje y el mensaje no lo usa (`src/guardianships/device-pairing.service.ts`, función `limitReached`). El tope se lee de `limits.max_devices`.
2. **`details.reason` de `DEVICE_PAIRING_NOT_ELIGIBLE` se quita en producción** (`HttpExceptionFilter`): la app no puede distinguir «tiene acceso propio» de «ya tiene 13 años» por la respuesta en producción. Si la app necesita el motivo, hay que cambiar el contrato.
3. **Un dispositivo vinculado a los 12 años sigue vivo después de los 13** hasta la mayoría de edad (la compuerta solo revisa la mayoría de edad). Es intencional según el e2e, pero conviene confirmarlo con producto y con el texto legal.
4. **El cierre de sesión es de mejor esfuerzo**, pero desde `0d40ac40` revoca el dispositivo **antes** de borrar la sesión (una sola transacción). Si la revocación falla, la fila queda activa sin sesión y la comprobación del tope la cura al crear o canjear un token (la marca `session_revoked`), así que ya no ocupa un cupo para siempre.
5. **La purga de M** (desde `a8af9091`) borra los tokens de emparejamiento y anonimiza `linked_devices` (`label` = `Dispositivo`, `app_version` y `fcm_token_id` nulos); las filas se conservan como auditoría. Ver «Retención y purga» en `SCHEMA-REFERENCE.md`. G11 sigue Pendiente: no se ejecutó la purga en vivo.
6. **`revokeAsAdmin` existía sin endpoint al escribir este plan**; la 3c lo expone (`POST /admin/users/:userId/linked-devices/:deviceId/revoke`) y añade el barrido por cron de mayoría de edad y de expiración (`family-age-transitions`). Esos escenarios están en `docs/testing/FAMILY-PROFILES-PHASE3C-QA.md`; la compuerta (perezosa) sigue cubriendo ambos casos en el servidor.

## Datos que quedan en Neon `development`

Según el QA de API (engram #11614): quedan el menor D (`3ebb3fc8-…`), D2 y D3 con dispositivos revocados y un token FCM falso; los tutores de prueba se borraron. Del QA en simulador no se anotó qué datos quedaron; limpiarlos con los ids que muestre `GET /guardianships/me/dependents`.
