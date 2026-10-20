---
documento: Checklist de privacidad para tiendas
version: 2.0.0-family
fecha: 2026-10-19
estado: BORRADOR — requiere revisión del usuario o de un abogado (la última submission aprobada fue con la 1.0.0-store; no reenviar con este texto hasta que se apruebe)
version_publicada_vigente: 1.0.0-store
aplicable_a: App Store Connect + Google Play Console
---

# Checklist de privacidad para App Store y Google Play

> **BORRADOR — requiere revisión del usuario o de un abogado.** Pendiente de merge (PR por abrir: feat/family-profiles-phase3). <!-- TODO(orquestador): reemplazar por «PR #NNN de sacdia-backend» cuando exista el PR. -->
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
- **Analítica de uso (PostHog)**: declarar que se recolecta solo en mayores de 18 años asociada a la cuenta (borrador: verificar que la declaración vigente de App Store Connect y Google Play ya la incluye; el aviso 1.0.0-store no nombraba a PostHog).
- **Personas de 13 a 17 años**: analítica **anónima** únicamente (sin identificador de usuario, correo, nombre de usuario ni nombre; sin usuario en Sentry). Debe reflejarse en «Datos vinculados al usuario» frente a «Datos no vinculados».
- **Modo dispositivo vinculado (menores de 13 años; función de la Fase 3b, aún no activa)**: sin identificadores personales en el dispositivo (ni correo ni contraseña); solo token de notificaciones (FCM) y sesión; **sin analítica de uso** (PostHog desactivado en este modo). No declarar al dispositivo vinculado como recolector de datos de seguimiento.

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

Declarar compartición/procesamiento con proveedores técnicos necesarios, no con anunciantes:

- Neon/PostgreSQL — base de datos.
- Render — backend/API.
- Vercel — panel web.
- Cloudflare R2 — almacenamiento de archivos.
- Google/Firebase — autenticación Google, FCM, Android y mapas cuando aplique.
- Google Cloud Vision — lectura automática (OCR) de imágenes de certificados que sube el usuario.
- Apple — autenticación Apple y servicios iOS cuando aplique.
- Sentry — errores y estabilidad.
- OpenStreetMap/Nominatim/geocoding — búsqueda o selección de lugares.
- PostHog — analítica de uso de la app (menores de 18 años: solo anónima; dispositivo vinculado: ninguna).
- Resend — correo transaccional para verificación, seguridad o soporte.
- Proveedor de correo transaccional — verificación, seguridad o soporte.

## 5. Seguridad de datos

> **BORRADOR — requiere revisión del usuario o de un abogado.** Esta sección cambió en la versión 2.0.0-family (antes 1.0.0-store) y no debe usarse en una submission sin aprobación.

Declarar que los datos se transmiten cifrados en producción mediante HTTPS.

Declarar que el usuario puede solicitar eliminación de cuenta/datos desde la app o por contacto de soporte. No prometer eliminación total inmediata: usar lenguaje de eliminación, anonimización o conservación limitada cuando sea necesaria por seguridad, trazabilidad o respaldo.

**Minimización de datos de menores**: una cuenta supervisada de 13 a 17 años sin tutor vinculado se congela a los 90 días y se elimina y anonimiza 90 días después. Una cuenta supervisada no puede eliminarse desde la app por el propio menor (la solicitud la hace el tutor o un administrador): declararlo así en la ficha si la tienda pregunta por el mecanismo de eliminación (puede requerir revisión legal).

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
- [ ] (2.0.0-family) Las declaraciones de privacidad de App Store Connect y Google Play (Data Safety) reflejan la analítica anónima de 13 a 17 años y, cuando se active la Fase 3b, el modo dispositivo vinculado sin analítica.
- [ ] (2.0.0-family) Cuentas de menores: confirmar con las tiendas si el flujo de cuentas supervisadas exige declaraciones adicionales para apps dirigidas a menores (Families / «Designed for Families»). **Pregunta legal abierta.**

## 7. Advertencia técnica

No declarar "no compartimos datos" en absoluto. La declaración correcta es:

> No vendemos datos personales ni los compartimos con anunciantes. Compartimos o procesamos datos solo con proveedores técnicos necesarios para operar y proteger SACDIA.
