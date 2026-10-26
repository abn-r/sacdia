---
documento: Aviso de Privacidad
version: 2.0.0-family
fecha: 2026-10-26
estado: BORRADOR — requiere revisión del usuario o de un abogado (no publicar ni promover a main hasta que se apruebe)
version_publicada_vigente: 1.0.0-store
aplicable_a: sacdia-app (iOS/Android) + sacdia-admin (web)
url_publica_sugerida: https://sacdia.com/privacy
contacto: sacdia.app@gmail.com
---

# Aviso de Privacidad de SACDIA

Última actualización: **26 de octubre de 2026** (borrador de la versión 2.0.0-family; la versión publicada hoy sigue siendo la 1.0.0-store del 30 de junio de 2026)
Contacto de privacidad: **sacdia.app@gmail.com**

> **BORRADOR — requiere revisión del usuario o de un abogado.** Pendiente de merge (PR #531 de sacdia-backend).
> Este texto es la versión **2.0.0-family**: cuentas supervisadas para adolescentes de 13 a 17 años (Fase 3 de perfiles familiares). Las secciones marcadas con este mismo aviso cambiaron respecto de la 1.0.0-store: §2.1, §2.4, §2.8, §6 (Fase 3, 2026-10-19) y §1, §2.3, §4, §7 (mejoras P0 del benchmark legal `BENCHMARK-2026-10-26.md`, 2026-10-26). El resto no cambió. La constante de versión del backend (`legal-documents.constants.ts`) pasa a `2.0.0-family` solo después de que este texto se apruebe y se publique en `https://sacdia.com/privacy`.
> Este borrador contiene marcadores `[PENDIENTE: ...]` en §1 (identidad y domicilio del responsable). No se publica con marcadores: la puerta de publicación del `README.md` debe verificar también `rg "\[PENDIENTE:" docs/legal/aviso-de-privacidad.md docs/legal/terminos-y-condiciones.md`.

Este Aviso explica cómo SACDIA recolecta, usa, protege y comparte datos personales al utilizar la aplicación móvil, el panel administrativo web y los servicios relacionados.

La idea central es simple: **SACDIA no vende datos personales, no los usa para publicidad comportamental y no los comparte con anunciantes**. Los datos se usan para operar la plataforma, proteger a los usuarios, administrar clubes y dar soporte técnico.

## 1. Identidad y domicilio del responsable

> **BORRADOR — requiere revisión del usuario o de un abogado.** Esta sección cambió el 2026-10-26 (P0-1 del benchmark). La LFPDPPP exige identificar al responsable y su domicilio; la 1.0.0-store no lo hacía. No publicar con los marcadores `[PENDIENTE: ...]` sin resolver.

El responsable del tratamiento de tus datos personales es:

- Responsable: **[PENDIENTE: razón social de la persona moral o nombre completo de la persona física que opera SACDIA]**
- Domicilio para oír y recibir notificaciones: **[PENDIENTE: calle, número, colonia, código postal, ciudad y entidad federativa]**
- Correo para privacidad y derechos ARCO: **sacdia.app@gmail.com**
- Soporte: **https://sacdia.com/support**
- Términos: **https://sacdia.com/terms**

SACDIA es una plataforma tecnológica para administración y trazabilidad de clubes juveniles cristianos/adventistas. Los clubes, coordinaciones y campos locales que usan SACDIA recaban parte de la información (por ejemplo, el formato de consentimiento firmado por el tutor) bajo sus propios procedimientos; SACDIA trata esa información como responsable de la plataforma conforme a este Aviso.

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

#### 2.3.1 Consentimiento expreso y separado para datos sensibles

> **BORRADOR — requiere revisión del usuario o de un abogado.** Esta sección es nueva (2026-10-26, P0-2 del benchmark; hallazgo C-01 de `REVIEW-REPORT.md`). **La app hoy muestra un solo control de aceptación para Términos y Aviso** (`sac_legal_consent.dart`) y no recaba consentimientos separados. Antes de publicar este texto, la app debe mostrar dos controles independientes y registrar cada aceptación por separado (por ejemplo, con tipos de documento `health` y `religion` en `legal_acceptances`), o este apartado debe retirarse. No prometer un control que el sistema no implementa.

Los datos sensibles requieren tu consentimiento **expreso**, distinto de la aceptación general de este Aviso. SACDIA lo recaba por separado para cada categoría:

- **Datos de salud** (tipo de sangre, alergias, enfermedades, medicamentos, pólizas o comprobantes de seguro): se solicita un consentimiento expreso al capturar la ficha médica. Si no lo otorgas, puedes seguir usando SACDIA, pero el club no contará con tu ficha médica en la plataforma y deberá gestionarla por otros medios.
- **Afiliación religiosa** (pertenencia a un club cristiano/adventista): se solicita un consentimiento expreso al vincularte a un club. Es necesario para operar la plataforma; sin él no es posible registrar la membresía.

Para menores de edad, ambos consentimientos los otorga el tutor o representante legal (ver §2.4). Puedes revocar cualquiera de los dos conforme a §7.

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

> **BORRADOR — requiere revisión del usuario o de un abogado.** Esta sección cambió en la versión 2.0.0-family (PostHog, 2026-10-19) y de nuevo el 2026-10-26 (P0-4 del benchmark): se completó la lista con los proveedores que el código usa y no estaban declarados (Upstash, Google Cloud Run/Firestore, AWS S3 legado, contenido externo) y se agregaron datos y país por proveedor. Pendientes antes de publicar: (a) confirmar la razón social exacta de cada proveedor; (b) confirmar que se aceptaron los términos de encargado o DPA de cada uno en su consola; (c) retirar la fila de AWS S3 cuando las imágenes del catálogo migren a Cloudflare R2; (d) publicar las filas de Cloud Run/Firestore solo cuando el proxy de OCR esté desplegado.

SACDIA no vende datos personales.

### 4.1 Encargados (proveedores técnicos)

Para operar la plataforma, SACDIA remite datos a proveedores técnicos que los tratan **por cuenta de SACDIA y bajo sus instrucciones** (encargados). No deciden sobre tus datos ni los usan para fines propios. Estas remisiones no requieren tu consentimiento conforme a la LFPDPPP, pero te las informamos para que sepas exactamente quién participa:

| Encargado | Servicio | Datos que puede tratar | País de tratamiento |
|---|---|---|---|
| **Neon, Inc.** (PostgreSQL) | Base de datos principal | Todos los datos de la plataforma | Estados Unidos |
| **Render Services, Inc.** | Hosting del backend/API | Todos los datos en tránsito; registros técnicos de peticiones | Estados Unidos |
| **Vercel, Inc.** | Hosting del panel web | Datos del panel en tránsito; registros técnicos | Estados Unidos |
| **Cloudflare, Inc.** (R2) | Almacenamiento de archivos | Fotos, evidencias, certificados, comprobantes, formatos de consentimiento, exportaciones de datos | Estados Unidos / red global |
| **Upstash, Inc.** (Redis) | Caché e infraestructura de colas | Copias temporales de respuestas de la API y trabajos en cola (por ejemplo, OCR de certificados) | Estados Unidos |
| **Google LLC** (Identidad y Firebase) | Inicio de sesión con Google, notificaciones push (Firebase Cloud Messaging), verificación de integridad de la app (App Check) | Correo, nombre, foto e identificador de Google; token de notificaciones; identificador de instalación | Estados Unidos |
| **Google LLC** (Maps Platform) | Mapas en la app y en el panel | Coordenadas de los lugares que consultas o seleccionas; dirección IP | Estados Unidos |
| **Google LLC** (Cloud: Vision; Cloud Run y Firestore cuando se active el proxy de OCR) | Lectura automática (OCR) de certificados que subes para proponer sus datos | Imagen o PDF del certificado; metadatos de uso sin contenido personal | Estados Unidos (us-east4) |
| **Apple Inc.** | Inicio de sesión con Apple y servicios del sistema operativo | Identificador de Apple, nombre opcional, correo real o de retransmisión | Estados Unidos |
| **Functional Software, Inc.** (Sentry) | Monitoreo de errores y estabilidad | Registros técnicos con campos sensibles redactados en origen; sin usuario asociado | Estados Unidos |
| **PostHog, Inc.** | Analítica de uso de la app, sin grabación de sesiones | Pantallas vistas y eventos de producto; identificador interno solo en mayores de edad (ver §2.4.1) | Estados Unidos |
| **OpenStreetMap Foundation** (Nominatim) | Búsqueda de lugares al registrar actividades | Texto de búsqueda y dirección IP | Reino Unido / Unión Europea |
| **Resend, Inc.** | Correo transaccional | Correo y contenido del mensaje (verificación, seguridad, soporte) | Estados Unidos |
| **Amazon Web Services, Inc.** (S3, legado) | Imágenes del catálogo de especialidades | Ningún dato personal; la dirección IP del dispositivo llega al servidor al cargar las imágenes. En migración a Cloudflare R2 | Estados Unidos |

Estos proveedores están obligados por sus términos de servicio y acuerdos de tratamiento de datos a aplicar medidas de seguridad, confidencialidad y limitación de finalidad equivalentes a las de este Aviso. Varios tratan datos fuera de México. Al aceptar este Aviso, reconoces que tus datos pueden tratarse en los países indicados, lo cual es necesario para prestar el servicio.

### 4.2 Contenido externo

Cuando un club enlaza un recurso externo (por ejemplo, un video de YouTube), la app carga su miniatura directamente desde el servidor del tercero (Google), que recibe la dirección IP de tu dispositivo. El panel web carga tipografías desde Google Fonts, con el mismo efecto. SACDIA no comparte con esos servicios ningún otro dato tuyo.

### 4.3 Transferencias

SACDIA **no transfiere** datos personales a terceros que decidan sobre ellos para fines propios, salvo en los casos siguientes, que no requieren tu consentimiento:

- autoridades competentes, cuando lo exija una ley o un requerimiento debidamente fundado;
- ejercicio o defensa de derechos de SACDIA o de los usuarios;
- prevención de abuso, fraude o respuesta a incidentes de seguridad;
- atención médica de emergencia durante una actividad del club, limitada a los datos de la ficha médica y contactos de emergencia.

Los directores, consejeros y personal autorizado de tu club, coordinación o campo local acceden a tus datos **dentro de la plataforma**, según su rol y permisos (ver §5). Eso no es una transferencia a terceros: es el uso para el que registraste la información.

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

## 7. Derechos ARCO, revocación del consentimiento y limitación de uso

> **BORRADOR — requiere revisión del usuario o de un abogado.** Esta sección cambió en la versión 2.0.0-family (menores, 2026-10-19) y se reescribió el 2026-10-26 (P0-3 del benchmark) con procedimiento, plazos y revocación. Los plazos de 20 y 15 días hábiles son los de la LFPDPPP de 2010; el abogado debe confirmar si la ley de 2025 los cambió. Confirmar también el nombre vigente de la autoridad.

### 7.1 Tus derechos

Puedes ejercer en cualquier momento tus derechos de **Acceso, Rectificación, Cancelación y Oposición (ARCO)**:

- **Acceso**: conocer qué datos tuyos tratamos y bajo qué condiciones.
- **Rectificación**: corregir datos inexactos o incompletos. Buena parte de tu perfil puedes corregirla directamente en la app.
- **Cancelación**: solicitar la eliminación o anonimización de tus datos, con los límites de §6.
- **Oposición**: oponerte al tratamiento para un fin concreto.

También puedes:

- **exportar** una copia de tu información disponible (en la app, para mayores de edad; o por correo);
- **revocar** el consentimiento que otorgaste (ver §7.4);
- **revisar** los datos de menores bajo tu responsabilidad (para una cuenta supervisada, la solicitud la hace el tutor; ver §2.4);
- **retirar permisos del dispositivo**, como ubicación o notificaciones, desde la configuración de iOS o Android.

### 7.2 Cómo presentar una solicitud

Escribe a **sacdia.app@gmail.com**, de preferencia desde el correo asociado a tu cuenta, e incluye:

1. tu nombre completo y el correo de la cuenta;
2. el derecho que ejerces y una descripción clara de lo que solicitas;
3. cualquier dato que ayude a localizar la información (club, periodo, tipo de registro);
4. si no escribes desde el correo de la cuenta, o la solicitud afecta datos sensibles o de un menor: una identificación oficial vigente y, para menores, el documento que acredite la patria potestad, tutela o representación legal.

### 7.3 Plazos y costo

- Te responderemos en un máximo de **20 días hábiles** a partir de que recibamos la solicitud completa. Si necesitamos más información, te la pediremos dentro de los primeros 5 días hábiles y el plazo se cuenta desde que la entregues.
- Si la solicitud procede, la haremos efectiva dentro de los **15 días hábiles** siguientes a la respuesta.
- Estos plazos pueden ampliarse una sola vez por un periodo igual cuando lo justifiquen las circunstancias, y te lo informaremos.
- El ejercicio de derechos ARCO es **gratuito**. Solo podrían cobrarse costos justificados de envío o reproducción de copias, que te informaríamos antes.

### 7.4 Revocación del consentimiento

Puedes revocar el consentimiento que nos diste, incluido el consentimiento separado para datos de salud o afiliación religiosa (§2.3.1), por el mismo medio de §7.2. Ten en cuenta:

- la revocación no afecta el tratamiento ya realizado ni los registros que debamos conservar por las razones de §6;
- revocar el consentimiento de datos de salud implica que el club deje de contar con tu ficha médica en la plataforma;
- revocar el consentimiento de afiliación religiosa o de los datos de cuenta implica dar de baja tu membresía o tu cuenta, porque sin ellos no es posible prestar el servicio.

### 7.5 Limitación de uso o divulgación

SACDIA no usa tus datos para finalidades secundarias (mercadotecnia, publicidad, perfiles comerciales ni venta), así que no existe una lista de exclusión que debas solicitar. Si en el futuro se agregara una finalidad secundaria, se pedirá tu consentimiento por separado y podrás negarlo sin afectar el servicio.

### 7.6 Autoridad

Si consideras que tu derecho a la protección de datos fue vulnerado, puedes acudir a la autoridad competente en México, la **Secretaría Anticorrupción y Buen Gobierno** (antes INAI), conforme a la LFPDPPP.

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
