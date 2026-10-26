---
documento: Checklist de privacidad para tiendas
version: 2.0.0-family
fecha: 2026-10-20
estado: BORRADOR — requiere revisión del usuario o de un abogado (la última submission aprobada fue con la 1.0.0-store; no reenviar con este texto hasta que se apruebe)
version_publicada_vigente: 1.0.0-store
aplicable_a: App Store Connect + Google Play Console
---

# Checklist de privacidad para App Store y Google Play

> **BORRADOR — requiere revisión del usuario o de un abogado.** Pendiente de merge (PR #531 de sacdia-backend).
> Versión 2.0.0-family: cuentas supervisadas de 13 a 17 años. Las secciones 2, 3, 4, 5 y 6 marcadas con el aviso de abajo cambiaron; el resto no.

Este checklist traduce el funcionamiento actual de SACDIA a declaraciones prácticas para las tiendas. Debe usarse junto con:

- `docs/legal/aviso-de-privacidad.md`
- `docs/legal/terminos-y-condiciones.md`
- URL pública: `https://sacdia.com/privacy`
- URL pública: `https://sacdia.com/terms`
- Soporte/eliminación: `https://sacdia.com/support` y `sacdia.app@gmail.com`

## 1. Mensaje base de privacidad

Usar esta posición en tiendas y materiales públicos:

> SACDIA no vende datos personales, no comparte datos con anunciantes y no usa información para publicidad comportamental. Los datos se usan para operar la cuenta, administrar clubes, proteger miembros, enviar notificaciones operativas, almacenar evidencias y mejorar la estabilidad de la app mediante proveedores técnicos necesarios.

## 2. Datos que deben declararse

### Identidad y contacto

- Nombre y apellidos.
- Correo electrónico.
- Foto de perfil, si el usuario la agrega.
- Datos de contactos de emergencia y representantes/tutores cuando se registren.

### Datos sensibles

> **BORRADOR — requiere revisión del usuario o de un abogado.** Esta sección cambió en la versión 2.0.0-family (antes 1.0.0-store) y no debe usarse en una submission sin aprobación.

- Información médica relevante: tipo de sangre, alergias, enfermedades, medicamentos, seguros.
- Información relacionada con pertenencia/participación en clubes cristianos/adventistas.
- Datos de menores cuando el club los registre o administre.
- Datos de personas de 13 a 17 años con **cuenta supervisada**: correo o nombre de usuario generado, estado de acceso y vínculo con su tutor. Las personas menores de 13 años no tienen cuenta ni correo.

### Contenido del usuario

- Fotografías.
- Documentos.
- Evidencias.
- Certificados.
- Comprobantes.
- Reportes de soporte.

### Ubicación

- Ubicación/coordenadas de actividades.
- Búsquedas de lugares.
- Ubicación del dispositivo cuando el usuario otorga permiso para seleccionar un lugar.

### Identificadores, dispositivo y diagnósticos

> **BORRADOR — requiere revisión del usuario o de un abogado.** Esta sección cambió en la versión 2.0.0-family (antes 1.0.0-store) y no debe usarse en una submission sin aprobación.

- Identificador interno de usuario.
- Tokens de notificaciones push.
- Sesiones y datos de autenticación.
- Datos de dispositivo, sistema operativo y versión de app.
- Crash logs, errores y rendimiento vía Sentry u otros diagnósticos.
- **Analítica de uso (PostHog)**: la app identifica a la persona (con su identificador interno, nunca correo ni nombre) solo cuando el servidor lo permite de forma explícita (`GET /auth/me` con `analytics_anonymous: false`), es decir, una persona con la mayoría de edad de su país cumplida. Declararla como dato vinculado al usuario solo para ese grupo (borrador: verificar que la declaración vigente de App Store Connect y Google Play ya la incluye; el aviso 1.0.0-store no nombraba a PostHog).
- **Personas de 13 a 17 años y cuentas sin fecha de nacimiento (cuenta supervisada, pendiente de tutor o con tutor)**: analítica **anónima** únicamente. La app nunca llama a `identify` para ellas; si el teléfono tenía antes a otra persona identificada, hace `reset` para que los eventos del menor no queden atados a esa identidad. Un campo `analytics_anonymous` ausente o desconocido se trata como anónimo (falla cerrado). Sin usuario en Sentry: la app no asigna usuario a Sentry a nadie (`sendDefaultPii = false`, y una prueba automática falla si alguien añade `setUser`/`SentryUser`). Debe reflejarse en «Datos vinculados al usuario» frente a «Datos no vinculados». Verificado en código y pruebas de la app (`AnalyticsPolicy`, `analytics_policy_test`, `no_sentry_user_test`); **la comprobación en el panel de PostHog y de Sentry sigue pendiente** (QA de las fases 3a y 3b).
- **Modo dispositivo vinculado (menores de 13 años; función de la Fase 3b: servidor y app implementados en la rama `feat/family-profiles-phase3`, desactivado hasta activar `FAMILY_LINKED_DEVICE_ENABLED`)**: el teléfono no guarda ni pide identificadores personales (ni correo ni contraseña ni nombre de usuario). Lo único que se recolecta es el token de notificaciones (FCM), la sesión del dispositivo (vence a los 180 días como máximo) y un nombre del teléfono que ve el tutor en su lista de dispositivos, además de los diagnósticos técnicos estándar de Sentry sin usuario. **Sin analítica de uso**: PostHog no se inicializa en el arranque en frío cuando la instalación está en modo dispositivo, y al vincular el teléfono se desactiva (`disable` más `reset`); el servidor además responde `analytics_anonymous: true` para el dispositivo. No declarar al dispositivo vinculado como recolector de datos de seguimiento. Pendiente: comprobar en el panel de PostHog que el teléfono vinculado no emite eventos (QA 3b, caso K8).

### Actividad dentro de la app

- Actividades, asistencia, progreso, validaciones, roles, notificaciones, reportes y acciones necesarias para operar el club.

## 3. Propósitos que deben declararse

- Funcionalidad de la app.
- Administración de cuenta.
- Seguridad y prevención de abuso.
- Gestión de clubes, miembros, roles, actividades y evidencias.
- Notificaciones operativas.
- Soporte al usuario.
- Diagnóstico de fallos, estabilidad y rendimiento.
- Cumplimiento o atención de solicitudes de eliminación/exportación.

No declarar publicidad, tracking publicitario ni venta de datos.

## 4. Compartición con terceros

> **BORRADOR — requiere revisión del usuario o de un abogado.** Lista completada el 2026-10-26 (P0-4 del benchmark) con los proveedores que el código usa y no estaban declarados. Debe coincidir con la tabla de §4.1 del aviso.

Declarar compartición/procesamiento con proveedores técnicos necesarios (encargados), no con anunciantes:

- Neon/PostgreSQL — base de datos.
- Render — backend/API.
- Vercel — panel web.
- Cloudflare R2 — almacenamiento de archivos (incluye formatos de consentimiento y exportaciones).
- Upstash (Redis) — caché e infraestructura de colas (copias temporales de respuestas; trabajos de OCR). **Nuevo 2026-10-26.**
- Google/Firebase — autenticación Google, FCM, App Check, Android.
- Google Maps Platform — mapas en app y panel (coordenadas de lugares consultados).
- Google Cloud Vision — lectura automática (OCR) de imágenes de certificados que sube el usuario. Cuando se despliegue el proxy de OCR: también Cloud Run y Firestore (metadatos de uso). **Ampliado 2026-10-26.**
- Apple — autenticación Apple y servicios iOS cuando aplique.
- Sentry — errores y estabilidad, sin usuario asociado.
- OpenStreetMap/Nominatim — búsqueda de lugares (texto de búsqueda e IP). El geocoding inverso en móvil usa los geocoders nativos de Apple/Google.
- PostHog — analítica de uso de la app (menores de 18 años: solo anónima; dispositivo vinculado: ninguna).
- Resend — correo transaccional para verificación, seguridad o soporte.
- Amazon Web Services (S3, legado) — imágenes del catálogo de especialidades (sin datos personales; IP del dispositivo). **Nuevo 2026-10-26.** Retirar cuando `sacdia-app/lib/features/honors/data/models/*.dart` y `classes/data/models/class_honor_model.dart` dejen de apuntar a `amazonaws.com`.
- Contenido externo: miniaturas de YouTube (app) y Google Fonts (panel web) cargan directo desde Google con la IP del usuario. No es un SDK ni comparte otros datos; mencionarlo solo en el aviso (§4.2), no como "tercero con el que se comparten datos" en las tiendas.

No declarar como terceros a los directores, consejeros o personal del club: acceden dentro de la plataforma según su rol.

## 5. Seguridad de datos

> **BORRADOR — requiere revisión del usuario o de un abogado.** Esta sección cambió en la versión 2.0.0-family (antes 1.0.0-store) y no debe usarse en una submission sin aprobación.

Declarar que los datos se transmiten cifrados en producción mediante HTTPS.

Declarar que el usuario puede solicitar eliminación de cuenta/datos desde la app o por contacto de soporte. No prometer eliminación total inmediata: usar lenguaje de eliminación, anonimización o conservación limitada cuando sea necesaria por seguridad, trazabilidad o respaldo.

> **BORRADOR — requiere revisión del usuario o de un abogado.** Lo que sigue (eliminación de cuentas de menores) es la **pregunta legal abierta P3-A22** de la Fase 3.

**Minimización de datos de menores**: una cuenta supervisada de 13 a 17 años sin tutor vinculado recibe recordatorios a los 7, 30 y 83 días, se congela a los 90 días (no puede iniciar sesión: `AUTH_ACCOUNT_FROZEN`) y se elimina y anonimiza 90 días después. El plazo cuenta desde el registro (o, en las cuentas que ya existían antes de esta función, desde la primera evaluación tras el despliegue, de modo que nadie se congela en la primera ejecución) y vuelve a empezar si el último tutor se retira o un vínculo pendiente se revoca. Un tutor vinculado que aún no verifica un director cuenta como vinculado y detiene el plazo (no recibe facultades hasta la verificación). La purga borra las credenciales y las cuentas OAuth, las sesiones y los tokens de notificaciones, y anula el correo y los datos personales.

**Eliminación de cuenta desde la app (App Store 5.1.1(v)): quién puede y quién no.** Declarar el mecanismo real, que depende del tipo de cuenta:

| Tipo de cuenta | ¿Puede iniciar la eliminación desde la app? |
|---|---|
| Adulto (mayoría de edad del país cumplida) | Sí: Ajustes, reautenticando (contraseña o proveedor Google/Apple). Si tiene menores a su cargo, antes ve el efecto sobre cada uno y debe confirmarlo |
| Cuenta sin fecha de nacimiento (por ejemplo, alta con Google o Apple antes del paso 2 del post-registro) | Sí: también desde el encabezado del post-registro, para que no quede atrapada |
| Adolescente de 13 a 17 años (cuenta supervisada, pendiente o con tutor) | **No** desde la app: la entrada está oculta y el servidor la rechaza. Lo solicita el tutor o un administrador por `sacdia.app@gmail.com`; si no hay tutor vinculado, la eliminación ocurre sola a los 90 + 90 días |
| Menor de 13 años con teléfono vinculado | **No**: el teléfono no tiene cuenta. Lo gestiona el tutor: desvincula el dispositivo, o al retirarse el último tutor el perfil se congela y se purga a los 90 días |
| Persona que actúa en nombre de un menor | **No**: mientras se actúa por un menor no se puede eliminar la cuenta de nadie |

Este punto **puede chocar con la regla 5.1.1(v)** (una app que permite crear cuentas debe permitir iniciar su eliminación dentro de la app) para el caso de 13 a 17 años, que sí pueden crear una cuenta desde el registro. Es una decisión del usuario del 2026-10-19, marcada para revisión legal (REVIEW-REPORT, punto 3): no afirmar en la ficha de tienda que todo usuario puede eliminar su cuenta desde la app, y confirmar con el abogado y con la tienda si exige una vía dentro de la app para estos casos antes de enviar la 2.0.0-family.

## 6. Antes de enviar a revisión

- [ ] `https://sacdia.com/privacy` abre sin login y muestra el aviso vigente.
- [ ] `https://sacdia.com/terms` abre sin login y muestra los términos vigentes.
- [ ] `https://sacdia.com/support` abre sin login o explica claramente cómo solicitar soporte/eliminación.
- [ ] `sacdia.app@gmail.com` está activo y monitoreado.
- [ ] La ficha de App Store Connect coincide con este checklist.
- [ ] La sección Data Safety de Google Play coincide con este checklist.
- [ ] El archivo `sacdia-admin/.env.sentry-build-plugin` fue removido del repo y el token fue rotado.
- [ ] El manifiesto de privacidad iOS (`sacdia-app/ios/Runner/PrivacyInfo.xcprivacy`) fue revisado contra los datos realmente recolectados.
- [x] El FAQ de eliminación de cuenta no promete plazos o eliminación total que el backend no cumpla.
- [ ] (2.0.0-family) La revisión del usuario o de un abogado aprobó el texto de `terminos-y-condiciones.md` y `aviso-de-privacidad.md` versión 2.0.0-family y se publicó en `https://sacdia.com/terms` y `https://sacdia.com/privacy` **antes** de subir la constante de versión del backend.
- [ ] (2.0.0-family) Las declaraciones de privacidad de App Store Connect y Google Play (Data Safety) reflejan la analítica anónima de 13 a 17 años y, cuando se active la Fase 3b, el modo dispositivo vinculado sin analítica ni identificadores personales.
- [ ] (2.0.0-family) La ficha explica la eliminación de cuenta según la tabla de la sección 5 (los adolescentes de 13 a 17 años no pueden eliminarla desde la app) y el abogado confirmó que es aceptable ante 5.1.1(v) y la LFPDPPP. **Pregunta legal abierta (P3-A22).**
- [ ] (2.0.0-family) Se comprobó en el panel de PostHog y de Sentry que una cuenta de 13 a 17 años, una cuenta sin fecha de nacimiento y un teléfono vinculado no aparecen identificados (y que el teléfono vinculado no emite eventos).
- [ ] (2.0.0-family) Cuentas de menores: confirmar con las tiendas si el flujo de cuentas supervisadas exige declaraciones adicionales para apps dirigidas a menores (Families / «Designed for Families»). **Pregunta legal abierta.** No aplicar a la categoría Kids de Apple (prohíbe analítica de terceros; usamos Sentry y PostHog). En Google Play existe la clasificación «mixed audience», que exige pantalla neutral de edad si se declara que la app incluye menores. Ver `BENCHMARK-2026-10-26.md` §3 punto 14.
- [ ] (2.0.0-family, P0 benchmark) Resueltos los marcadores `[PENDIENTE: ...]` de identidad y domicilio del responsable en aviso §1 y términos (intro y §12).
- [ ] (2.0.0-family, P0 benchmark) La app muestra consentimiento expreso **separado** para datos de salud y para afiliación religiosa (aviso §2.3.1) y lo registra por separado; si no, se retira §2.3.1 antes de publicar.
- [ ] (2.0.0-family, P0 benchmark) Confirmados en la consola de cada proveedor de la tabla §4.1 del aviso los términos de encargado o DPA aceptados, y la razón social exacta.
- [ ] (2.0.0-family, P0 benchmark) Imágenes del catálogo de especialidades migradas de AWS S3 a Cloudflare R2, o AWS declarado en tiendas.
- [ ] (2.0.0-family, P0 benchmark) El abogado confirmó los plazos ARCO (20 y 15 días hábiles) y el nombre de la autoridad con la LFPDPPP de 2025 (aviso §7).

## 7. Advertencia técnica

No declarar "no compartimos datos" en absoluto. La declaración correcta es:

> No vendemos datos personales ni los compartimos con anunciantes. Compartimos o procesamos datos solo con proveedores técnicos necesarios para operar y proteger SACDIA.
