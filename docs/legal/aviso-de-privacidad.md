---
documento: Aviso de Privacidad
version: 2.0.0-family
fecha: 2026-10-19
estado: BORRADOR — requiere revisión del usuario o de un abogado (no publicar ni promover a main hasta que se apruebe)
version_publicada_vigente: 1.0.0-store
aplicable_a: sacdia-app (iOS/Android) + sacdia-admin (web)
url_publica_sugerida: https://sacdia.com/privacy
contacto: sacdia.app@gmail.com
---

# Aviso de Privacidad de SACDIA

Última actualización: **19 de octubre de 2026** (borrador de la versión 2.0.0-family; la versión publicada hoy sigue siendo la 1.0.0-store del 30 de junio de 2026)
Contacto de privacidad: **sacdia.app@gmail.com**

> **BORRADOR — requiere revisión del usuario o de un abogado.** Pendiente de merge (PR por abrir: feat/family-profiles-phase3). <!-- TODO(orquestador): reemplazar por «PR #NNN de sacdia-backend» cuando exista el PR. -->
> Este texto es la versión **2.0.0-family**: cuentas supervisadas para adolescentes de 13 a 17 años (Fase 3 de perfiles familiares). Solo las secciones marcadas con este mismo aviso cambiaron respecto de la 1.0.0-store (§2.1, §2.4, §2.8, §4, §6 y §7). El resto no cambió. La constante de versión del backend (`legal-documents.constants.ts`) pasa a `2.0.0-family` solo después de que este texto se apruebe y se publique en `https://sacdia.com/privacy`.

Este Aviso explica cómo SACDIA recolecta, usa, protege y comparte datos personales al utilizar la aplicación móvil, el panel administrativo web y los servicios relacionados.

La idea central es simple: **SACDIA no vende datos personales, no los usa para publicidad comportamental y no los comparte con anunciantes**. Los datos se usan para operar la plataforma, proteger a los usuarios, administrar clubes y dar soporte técnico.

## 1. Responsable operativo

Para esta etapa de publicación, SACDIA opera como plataforma tecnológica para administración y trazabilidad de clubes juveniles cristianos/adventistas. Las consultas de privacidad, soporte, acceso, corrección o eliminación de datos pueden enviarse a:

- Correo: **sacdia.app@gmail.com**
- Soporte: **https://sacdia.com/support**
- Términos: **https://sacdia.com/terms**

## 2. Datos que podemos recolectar

SACDIA puede recolectar las siguientes categorías de datos, según las funciones que uses y la información que proporciones:

### 2.1 Cuenta e identidad

- nombre y apellidos;
- correo electrónico;
- foto de perfil, si se proporciona;
- identificadores internos de usuario;
- credenciales protegidas, sesiones y datos de autenticación;
- datos recibidos de Google o Apple cuando eliges iniciar sesión con esos proveedores;
- para cuentas supervisadas habilitadas por un tutor: un nombre de usuario generado por SACDIA (sin correo) y su estado de acceso (habilitado, deshabilitado y quién lo cambió).

> **BORRADOR — requiere revisión del usuario o de un abogado.** Esta sección cambió en la versión 2.0.0-family (antes 1.0.0-store) y no debe publicarse sin aprobación.

### 2.2 Perfil de miembro y club

- fecha de nacimiento, género y datos de perfil;
- club, sección, unidad, cargos, roles y permisos;
- historial de inscripción, trayectoria, clases, honores, certificaciones, asistencia, actividades, puntos y evidencias;
- solicitudes, validaciones, reportes y registros administrativos.

### 2.3 Datos sensibles y de seguridad personal

SACDIA puede tratar datos sensibles cuando sean necesarios para la operación segura del club:

- tipo de sangre;
- alergias, enfermedades, medicamentos y datos médicos relevantes;
- pólizas o comprobantes de seguro;
- contactos de emergencia;
- datos de representante legal o tutor;
- información relacionada con la participación en clubes cristianos/adventistas.

Estos datos se usan para fines operativos, de seguridad, acompañamiento institucional y administración del club. No se venden, no se usan para publicidad y no se comparten con anunciantes.

### 2.4 Menores de edad

> **BORRADOR — requiere revisión del usuario o de un abogado.** Esta sección cambió en la versión 2.0.0-family (antes 1.0.0-store) y no debe publicarse sin aprobación.

SACDIA puede tratar información de menores de edad porque la operación de clubes juveniles lo requiere. La información de menores debe ser proporcionada, autorizada o supervisada por madre, padre, tutor, representante legal o autoridad adulta del club. Si consideras que se registró información de un menor sin autorización suficiente, puedes solicitar revisión o eliminación escribiendo a **sacdia.app@gmail.com**.

#### 2.4.1 Qué cambia según la edad

Las edades son las de México (13 y 18 años); en otro país se aplican las configuradas para ese país.

| Edad | Cuenta | Analítica y diagnóstico | Qué ve el tutor |
|---|---|---|---|
| Menos de 13 años | Sin cuenta propia: lo registra su tutor (o un director acreditado) y el tutor actúa por él. Puede usar un dispositivo vinculado sin identificación personal (función de la Fase 3b: implementada en el servidor, desactivada hasta su despliegue; hasta 2 dispositivos por menor, con vinculación de 180 días como máximo). | Sin analítica personalizada: el dispositivo vinculado no envía eventos de producto, y mientras el tutor actúa por el menor no se identifica al menor en la analítica. | Todo lo del menor, porque actúa en su nombre. |
| De 13 a 17 años | Cuenta supervisada, propia pero bajo un tutor. | Solo analítica **anónima**: no se identifica a la persona en la herramienta de analítica ni se asocia un usuario a los reportes de errores, y los eventos no llevan identificador de usuario, correo, nombre de usuario ni nombre. | Un **resumen** de progreso y asistencia y los avisos de seguridad. No ve salud, evidencias, notas ni mensajes. |
| 18 años o más | Cuenta propia. | Analítica de uso asociada a la cuenta, como se describe en la sección 2.8. | No aplica. |

#### 2.4.2 Cuentas supervisadas y consentimiento del tutor

Una persona de 13 a 17 años que se registra por su cuenta queda en un **modo pendiente de tutor** hasta que un adulto se vincule con un código de un solo uso (vigente 72 horas) y un director del club verifique el formato de consentimiento firmado en papel. Ese formato se sube como imagen o PDF a un almacenamiento privado y solo se lee con enlaces temporales; la verificación la hace una persona del club distinta del tutor (y, cuando el menor está bajo custodia del club, distinta de quien registró al menor o subió el formato). **SACDIA no envía un correo de confirmación adicional al tutor para el consentimiento:** el mecanismo verificable es el formato firmado revisado por un director.

Mientras no haya un tutor verificado, la persona no puede ver datos del club. Si pasan 90 días sin tutor vinculado, la cuenta se congela y 90 días después se elimina y anonimiza; antes se envían recordatorios en la app a los 7, 30 y 83 días.

#### 2.4.3 Qué se comparte con el tutor

- **Resumen:** para una cuenta supervisada con tutor verificado, el tutor ve un resumen de progreso de clases, especialidades y asistencia del año en curso. No incluye datos de salud, contactos de emergencia, evidencias, notas ni ubicación. SACDIA informa a la persona menor, dentro de la app, de qué ve su tutor.
- **Avisos de seguridad al tutor:** nuevo inicio de sesión, cambio o restablecimiento de contraseña, bloqueos de acceso, cambios de acceso y, en menores de 13 años, vinculación o desvinculación de dispositivos. Además, cuando un dispositivo vinculado sube una evidencia de una clase, el tutor recibe un aviso informativo. Se envían como notificaciones push y en la bandeja de la app, nunca por correo, y no incluyen contraseñas, nombres de usuario ni direcciones IP. El tutor no puede desactivarlos.
- **Copias de notificaciones del club:** para menores de 13 años, el tutor recibe una copia de las notificaciones del club dirigidas al menor. Las personas de 13 a 17 años con acceso propio **no** generan copias para el tutor.

### 2.5 Contenido y archivos

- fotografías;
- documentos;
- evidencias de actividades, clases u honores;
- certificados;
- comprobantes;
- imágenes de actividades;
- archivos enviados para soporte o reportes.

### 2.6 Ubicación

SACDIA puede usar ubicación para funciones relacionadas con actividades y mapas:

- ubicación o coordenadas de actividades registradas;
- búsquedas de lugares o direcciones;
- ubicación aproximada o precisa del dispositivo, solo cuando das permiso al sistema operativo y la función lo requiere para seleccionar un lugar.

Puedes controlar permisos de ubicación desde la configuración de iOS o Android.

### 2.7 Notificaciones y dispositivo

- token de notificaciones push;
- preferencias de notificación;
- historial técnico de entregas;
- tipo de dispositivo, sistema operativo, versión de app y datos necesarios para enviar o diagnosticar notificaciones.

### 2.8 Datos técnicos, seguridad y diagnóstico

- dirección IP y metadatos técnicos de conexión;
- registros de seguridad y auditoría;
- errores, fallos, rendimiento y diagnósticos;
- datos de soporte enviados por el usuario;
- almacenamiento local necesario para sesión, preferencias, caché y funcionamiento offline limitado;
- analítica de uso de la app (pantallas vistas) con PostHog, asociada a la cuenta solo en mayores de 18 años (ver la sección 2.4.1).

> **BORRADOR — requiere revisión del usuario o de un abogado.** Esta sección cambió en la versión 2.0.0-family (antes 1.0.0-store) y no debe publicarse sin aprobación.

## 3. Para qué usamos los datos

Usamos los datos personales para:

- crear y proteger cuentas;
- autenticar usuarios;
- administrar clubes, secciones, roles y permisos;
- registrar trayectoria, clases, honores, evidencias y actividades;
- apoyar la seguridad de miembros durante actividades;
- gestionar contactos de emergencia y datos médicos relevantes;
- enviar notificaciones operativas;
- prestar soporte;
- diagnosticar errores y mejorar estabilidad;
- prevenir abuso, fraude o accesos no autorizados;
- permitir exportación, corrección o eliminación de datos cuando aplique;
- cumplir solicitudes de usuarios y obligaciones razonables de seguridad.

SACDIA no usa datos personales para publicidad comportamental ni para crear perfiles comerciales.

## 4. Cuándo compartimos datos

> **BORRADOR — requiere revisión del usuario o de un abogado.** Esta sección cambió en la versión 2.0.0-family (antes 1.0.0-store) y no debe publicarse sin aprobación.

SACDIA no vende datos personales.

Podemos compartir o procesar datos con proveedores técnicos únicamente cuando sea necesario para operar la plataforma. Estos proveedores actúan como infraestructura, almacenamiento, autenticación, monitoreo, mapas, notificaciones o soporte.

Entre los proveedores o servicios que pueden participar se encuentran:

- **Neon/PostgreSQL**: base de datos;
- **Render**: hosting de backend/API;
- **Vercel**: hosting del panel web;
- **Cloudflare R2**: almacenamiento de archivos, imágenes, evidencias, certificados, comprobantes y exportaciones;
- **Google**: inicio de sesión con Google, Firebase Cloud Messaging, servicios de Android y mapas cuando aplique;
- **Google Cloud Vision**: lectura automática (OCR) de imágenes de certificados que el usuario sube para proponer sus datos;
- **Apple**: inicio de sesión con Apple y servicios del sistema operativo cuando aplique;
- **Sentry**: monitoreo de errores y estabilidad;
- **PostHog**: analítica de uso de la app, sin grabación de sesiones; en menores de 18 años solo analítica anónima (ver la sección 2.4.1);
- **OpenStreetMap/Nominatim y servicios de geocodificación**: búsqueda o selección de lugares;
- **Resend**: envío de correo transaccional para verificación, seguridad o soporte;
- proveedores de correo o mensajería transaccional configurados para verificación, seguridad o soporte.

Estos proveedores pueden procesar datos en México, Estados Unidos u otros países, según su infraestructura.

También podemos compartir información si es necesario para cumplir una obligación legal, atender una autoridad competente, proteger derechos, prevenir abuso o responder a incidentes de seguridad.

## 5. Seguridad

SACDIA aplica medidas razonables para proteger los datos, incluyendo:

- comunicación mediante HTTPS en producción;
- autenticación y sesiones protegidas;
- control de acceso por roles y permisos;
- almacenamiento de archivos mediante servicios controlados y URLs firmadas cuando aplica;
- separación de permisos para datos sensibles;
- monitoreo de errores y eventos de seguridad;
- registros técnicos para auditoría y diagnóstico;
- limpieza o redacción de datos sensibles en flujos de diagnóstico cuando es posible.

Aun así, ningún sistema es 100% seguro. Si detectas una vulnerabilidad, acceso indebido o exposición de datos, repórtalo a **sacdia.app@gmail.com**.

## 6. Conservación y eliminación

> **BORRADOR — requiere revisión del usuario o de un abogado.** Esta sección cambió en la versión 2.0.0-family (antes 1.0.0-store) y no debe publicarse sin aprobación.

Conservamos datos mientras la cuenta esté activa o mientras sean necesarios para operar el club, preservar la trayectoria institucional, dar soporte, proteger la seguridad, atender solicitudes o mantener integridad técnica.

Puedes solicitar eliminación de cuenta o datos desde la app, cuando la función esté disponible, o escribiendo a **sacdia.app@gmail.com**.

Una cuenta supervisada de una persona de 13 a 17 años sin tutor vinculado se congela a los 90 días y se elimina y anonimiza 90 días después. Una cuenta supervisada no puede eliminarse desde la app por la propia persona menor: la solicitud la hace el tutor o un administrador.

Al eliminar una cuenta, SACDIA podrá eliminar, anonimizar o conservar ciertos registros cuando sean necesarios para:

- seguridad y prevención de abuso;
- auditoría técnica;
- trazabilidad institucional del club;
- atención de solicitudes pendientes;
- respaldo temporal;
- cumplimiento de obligaciones aplicables.

Los datos anonimizados o agregados pueden conservarse sin identificar directamente al usuario.

## 7. Derechos del usuario

> **BORRADOR — requiere revisión del usuario o de un abogado.** Esta sección cambió en la versión 2.0.0-family (antes 1.0.0-store) y no debe publicarse sin aprobación.

Puedes solicitar:

- acceso a tus datos;
- corrección de datos incorrectos;
- eliminación o anonimización cuando proceda;
- exportación o copia de información disponible;
- revisión de datos de menores bajo tu responsabilidad (para una cuenta supervisada, la solicitud la hace el tutor);
- revocación de permisos del dispositivo, como ubicación o notificaciones.

Para ejercer estos derechos, escribe a **sacdia.app@gmail.com** desde el correo asociado a tu cuenta o proporciona información suficiente para verificar tu identidad.

## 8. Permisos del dispositivo

SACDIA puede solicitar permisos del dispositivo, como:

- cámara o galería, para subir evidencias o fotos;
- ubicación, para seleccionar o ubicar actividades;
- notificaciones, para recibir avisos operativos;
- biometría del dispositivo, si activas bloqueo local de la app.

Puedes cambiar estos permisos desde la configuración de iOS o Android. SACDIA no almacena datos biométricos; la validación biométrica ocurre en el dispositivo mediante el sistema operativo.

## 9. Cambios a este Aviso

Podemos actualizar este Aviso para reflejar cambios del producto, proveedores, seguridad o requisitos de App Store y Google Play.

La versión vigente estará disponible en **https://sacdia.com/privacy**. Si el cambio es importante, procuraremos comunicarlo dentro de la app o por medios razonables.

## 10. Contacto

Para privacidad, soporte, eliminación de cuenta o dudas sobre tus datos:

- Correo: **sacdia.app@gmail.com**
- Soporte: **https://sacdia.com/support**
- Términos: **https://sacdia.com/terms**

---

## Nota operativa

Este documento está redactado para publicación inicial en App Store y Google Play, alineado con el funcionamiento actual de SACDIA. No constituye asesoría legal personalizada. Antes de usarlo como documento jurídico definitivo de una entidad formal, debe ser revisado por un abogado.
