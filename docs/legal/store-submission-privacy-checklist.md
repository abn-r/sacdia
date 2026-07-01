---
documento: Checklist de privacidad para tiendas
version: 1.0.0-store
fecha: 2026-06-30
estado: OPERATIVO PARA SUBMISSION
aplicable_a: App Store Connect + Google Play Console
---

# Checklist de privacidad para App Store y Google Play

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

- Información médica relevante: tipo de sangre, alergias, enfermedades, medicamentos, seguros.
- Información relacionada con pertenencia/participación en clubes cristianos/adventistas.
- Datos de menores cuando el club los registre o administre.

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

- Identificador interno de usuario.
- Tokens de notificaciones push.
- Sesiones y datos de autenticación.
- Datos de dispositivo, sistema operativo y versión de app.
- Crash logs, errores y rendimiento vía Sentry u otros diagnósticos.

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
- Apple — autenticación Apple y servicios iOS cuando aplique.
- Sentry — errores y estabilidad.
- OpenStreetMap/Nominatim/geocoding — búsqueda o selección de lugares.
- Proveedor de correo transaccional — verificación, seguridad o soporte.

## 5. Seguridad de datos

Declarar que los datos se transmiten cifrados en producción mediante HTTPS.

Declarar que el usuario puede solicitar eliminación de cuenta/datos desde la app o por contacto de soporte. No prometer eliminación total inmediata: usar lenguaje de eliminación, anonimización o conservación limitada cuando sea necesaria por seguridad, trazabilidad o respaldo.

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

## 7. Advertencia técnica

No declarar "no compartimos datos" en absoluto. La declaración correcta es:

> No vendemos datos personales ni los compartimos con anunciantes. Compartimos o procesamos datos solo con proveedores técnicos necesarios para operar y proteger SACDIA.
