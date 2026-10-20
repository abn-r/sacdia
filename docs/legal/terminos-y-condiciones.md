---
documento: Términos de Uso
version: 2.0.0-family
fecha: 2026-10-19
estado: BORRADOR — requiere revisión del usuario o de un abogado (no publicar ni promover a main hasta que se apruebe)
version_publicada_vigente: 1.0.0-store
aplicable_a: sacdia-app (iOS/Android) + sacdia-admin (web)
url_publica_sugerida: https://sacdia.com/terms
contacto: sacdia.app@gmail.com
---

# Términos de Uso de SACDIA

Última actualización: **19 de octubre de 2026** (borrador de la versión 2.0.0-family; la versión publicada hoy sigue siendo la 1.0.0-store del 30 de junio de 2026)
Contacto: **sacdia.app@gmail.com**

> **BORRADOR — requiere revisión del usuario o de un abogado.** Pendiente de merge (PR #531 de sacdia-backend).
> Este texto es la versión **2.0.0-family**: cuentas supervisadas para adolescentes de 13 a 17 años (Fase 3 de perfiles familiares). Solo las secciones marcadas con este mismo aviso cambiaron respecto de la 1.0.0-store (§2 y §3, y el párrafo de menores de §10). El resto del texto no cambió. La constante de versión del backend (`legal-documents.constants.ts`) pasa a `2.0.0-family` solo después de que este texto se apruebe y se publique en `https://sacdia.com/terms`.

Estos Términos regulan el acceso y uso de **SACDIA**, plataforma digital para apoyar la administración, trazabilidad y acompañamiento de clubes juveniles cristianos/adventistas, incluyendo la app móvil y el panel administrativo web.

SACDIA se publica en una fase operativa inicial. Actualmente **no ofrece pagos dentro de la app, suscripciones, patrocinios comerciales ni venta de productos digitales**.

Al crear una cuenta, iniciar sesión o utilizar SACDIA, aceptas estos Términos y el [Aviso de Privacidad](https://sacdia.com/privacy). Si no estás de acuerdo, no utilices la plataforma.

## 1. Propósito de SACDIA

SACDIA ayuda a clubes, líderes, padres/tutores y miembros a gestionar información relacionada con:

- perfil y trayectoria de miembros;
- clubes, secciones, unidades y roles;
- clases, honores, evidencias, certificados y actividades;
- contactos de emergencia, información médica relevante y seguros;
- notificaciones operativas sobre la vida del club;
- soporte y seguridad de la cuenta.

SACDIA **no sustituye** la supervisión humana, pastoral, administrativa, médica o legal de la organización responsable de cada club. La plataforma es una herramienta de apoyo; las decisiones institucionales y de seguridad siguen siendo responsabilidad de los adultos y autoridades correspondientes.

## 2. Cuentas y acceso

> **BORRADOR — requiere revisión del usuario o de un abogado.** Esta sección cambió en la versión 2.0.0-family (antes 1.0.0-store) y no debe publicarse sin aprobación.

Para usar SACDIA puedes registrarte con correo y contraseña o iniciar sesión mediante proveedores compatibles, como Google o Apple. Si eres adolescente de 13 a 17 años y tu madre, padre o tutor habilitó tu acceso, puedes iniciar sesión con un nombre de usuario que genera SACDIA y la contraseña que tu tutor definió (ver la sección 3).

Te comprometes a:

- proporcionar información veraz y actualizada;
- proteger tus credenciales;
- no compartir tu cuenta con terceros;
- notificar cualquier uso no autorizado;
- usar la plataforma solo para fines legítimos relacionados con la operación del club.

Algunas funciones pueden depender de aprobación o asignación de roles por parte de un director, administrador o autoridad del club.

## 3. Menores de edad

> **BORRADOR — requiere revisión del usuario o de un abogado.** Esta sección cambió en la versión 2.0.0-family (antes 1.0.0-store) y no debe publicarse sin aprobación.

> Las edades de esta sección son las de México (13 y 18 años). En otro país se aplican las edades que SACDIA tenga configuradas para ese país.

SACDIA puede tratar información de menores de edad porque muchos clubes incluyen niñas, niños y adolescentes. Los datos de menores deben tratarse con especial cuidado.

### 3.1 Tipos de cuenta según la edad

| Edad | Qué puede tener |
|---|---|
| 18 años o más | Cuenta propia. |
| De 13 a 17 años | Cuenta **supervisada** (sección 3.2): propia, pero bajo la supervisión de un tutor adulto. |
| Menos de 13 años | **No** puede tener cuenta propia. Lo registra su tutor (o un director de club acreditado, sección 3.4) como dependiente y el tutor actúa por él. Podrá usar un dispositivo vinculado (ver el aviso de la sección 3.2). |

La fecha de nacimiento la declara quien registra. Declarar una fecha falsa para obtener un tipo de cuenta que no corresponde puede llevar a suspender o eliminar la cuenta.

### 3.2 Cuenta supervisada de 13 a 17 años

Si tienes entre 13 y 17 años, puedes usar SACDIA con una cuenta supervisada. Debes usarla únicamente con autorización y supervisión de tu madre, padre, tutor o responsable adulto. La cuenta supervisada se obtiene de dos maneras:

- **La creas tú**: te registras con tu correo. Mientras no tengas un tutor vinculado y verificado, tu cuenta está en **modo pendiente de tutor**.
- **La habilita tu tutor**: tu tutor, desde su propia cuenta, te crea un acceso con un nombre de usuario generado por SACDIA (sin correo) o con tu correo, y define tu contraseña.

**Modo pendiente de tutor.** Puedes completar tu perfil y tu registro, cambiar tu contraseña y generar un código para que un adulto se vincule como tu tutor. No puedes ver datos de otros miembros ni de tu club, ni inscribirte en actividades o clases, y tu ingreso a un club no puede aprobarse. Un tutor se vincula con ese código; el vínculo solo pasa a ser válido cuando una persona autorizada del club o del campo local revisa y verifica la ficha de consentimiento firmada en papel. Hasta esa verificación, la persona que canjeó el código **no** tiene facultades sobre tu cuenta ni recibe avisos de seguridad sobre ella.

**Plazo.** Si pasan 90 días sin un tutor vinculado, tu cuenta se congela y 90 días después se elimina. Antes recibes recordatorios en la app a los 7, 30 y 83 días. Puedes quitar un vínculo pendiente que tú mismo iniciaste si te equivocaste de persona.

**Cuenta supervisada con tutor verificado.** Usas la app de miembro con las restricciones propias de tu edad: no puedes administrar sesiones, activar verificación en dos pasos, exportar datos, eliminar tu cuenta ni usar las secciones de familia. Tus datos de salud no son visibles para tu tutor.

> **Función de la Fase 3b (dispositivo vinculado, menores de 13 años): implementada, desactivada hasta su despliegue.** El tutor verificado vincula un teléfono del menor con un código QR de un solo uso que dura 10 minutos; cada menor puede tener hasta 2 dispositivos vinculados. El dispositivo vinculado no tiene correo ni contraseña, puede ver el progreso y el calendario del menor (sin la lista de quién más asiste), subir evidencias de clases y enviarlas a validación, y el tutor puede desvincularlo en cualquier momento. La vinculación vence a los 180 días como máximo. El tutor recibe un aviso cada vez que se vincula o desvincula un dispositivo, salvo cuando la desvinculación se debe al congelamiento del perfil o a que se activó el acceso propio del menor (en ese caso recibe el aviso de ese cambio), y cada vez que el dispositivo sube una evidencia. Esta parte del texto solo debe publicarse cuando la función esté activa.

### 3.3 Facultades del tutor

Un tutor cuyo vínculo ya fue verificado por el club puede, sobre la cuenta supervisada del menor:

- habilitar, deshabilitar y volver a habilitar el acceso del menor;
- restablecer la contraseña del menor (nunca puede ver una contraseña);
- ver un resumen del progreso de clases, especialidades y asistencia del menor;
- recibir avisos de seguridad en la app (nuevo inicio de sesión, cambio o restablecimiento de contraseña, bloqueos de acceso y cambios de acceso).

El tutor **no** ve los datos de salud, las evidencias, los mensajes ni las notas del consejero del menor con cuenta supervisada. SACDIA no ofrece mensajería privada entre usuarios. Mientras el acceso propio del menor esté habilitado, el tutor no puede actuar en su nombre; al deshabilitarlo, puede volver a hacerlo cuando el menor fue registrado por un tutor o director. Si hay varios tutores, todos los verificados reciben los avisos de las acciones de los demás.

### 3.4 Registro de menores por un adulto

Si eres adulto y registras, administras o subes información de un menor, declaras que cuentas con autorización suficiente para hacerlo y que usarás la información únicamente para fines propios del club.

> **Función pendiente de la Fase 3c (directores).** Un director de club acreditado puede registrar a un menor de 0 a 17 años en su sección, bajo custodia del club, declarando bajo protesta de decir verdad que cuenta con la autorización firmada de su tutor. El consentimiento de ese menor lo verifica **otra persona** (otra persona autorizada del club o del campo local, o un administrador), nunca quien lo registró ni quien subió el formato. Esta parte solo debe publicarse cuando la función esté activa.

### 3.5 Eliminación de la cuenta de un menor

Una cuenta supervisada **no** puede eliminarse desde la app por el propio menor. La eliminación (o el ejercicio de derechos de acceso, rectificación, cancelación u oposición) se solicita por el tutor o por un administrador, escribiendo a **sacdia.app@gmail.com**.

### 3.6 Conducta con menores

Está prohibido usar SACDIA para exponer, acosar, contactar indebidamente, discriminar o explotar a menores de edad.

## 4. Conducta aceptable

No está permitido:

- usar SACDIA para fines ilegales, abusivos, discriminatorios o ajenos al club;
- subir contenido falso, ofensivo, sexual, violento, discriminatorio o que vulnere derechos de terceros;
- publicar información personal de otra persona sin autorización;
- intentar acceder a cuentas, datos, clubes o módulos sin permiso;
- interferir con la seguridad, disponibilidad o integridad del sistema;
- suplantar identidades o manipular evidencias, certificados o registros.

SACDIA puede suspender, limitar o eliminar cuentas, contenidos o accesos cuando detecte uso indebido, riesgo para menores, riesgo de seguridad o incumplimiento de estos Términos.

## 5. Contenido y evidencias

Los usuarios pueden subir fotografías, documentos, evidencias, comprobantes, imágenes y otros materiales necesarios para operar el club.

El usuario conserva los derechos que le correspondan sobre su contenido. Al subirlo a SACDIA, concede a SACDIA una autorización limitada para almacenarlo, procesarlo, mostrarlo a usuarios autorizados y usarlo únicamente para operar la plataforma y prestar soporte.

SACDIA **no vende** el contenido de los usuarios ni lo utiliza para publicidad.

Antes de subir imágenes o documentos de otras personas, especialmente de menores, debes contar con autorización suficiente y respetar la privacidad de los involucrados.

## 6. Datos de salud, religión y emergencia

SACDIA puede incluir datos sensibles, como información médica relevante, alergias, enfermedades, medicamentos, tipo de sangre, seguros, contactos de emergencia y datos relacionados con la participación en clubes cristianos/adventistas.

Estos datos se tratan únicamente para operación del club, seguridad de actividades, acompañamiento institucional, soporte y protección de los miembros.

SACDIA no presta servicios médicos, no reemplaza la atención profesional y no garantiza que la información registrada sea suficiente para atender una emergencia. Los adultos responsables del club deben verificar la información crítica antes de actividades que impliquen riesgo.

## 7. Notificaciones y comunicaciones

SACDIA puede enviar notificaciones dentro de la app, push notifications o correos relacionados con:

- seguridad de cuenta;
- verificación de correo;
- actividades del club;
- avisos administrativos;
- cambios relevantes del servicio;
- soporte o reportes.

Las notificaciones deben usarse con fines operativos del club. Cualquier uso para acoso, contacto indebido, presión, publicidad no autorizada o comunicación inapropiada con menores está prohibido.

## 8. Pagos

SACDIA no procesa pagos dentro de la app en esta etapa. Si en el futuro se habilitan pagos, cuotas, donativos, suscripciones o servicios comerciales, se actualizarán estos Términos antes de activar dicha funcionalidad.

## 9. Privacidad y seguridad

El tratamiento de datos personales se explica en el [Aviso de Privacidad](https://sacdia.com/privacy).

SACDIA declara como principio operativo que:

- no vende datos personales;
- no usa datos personales para publicidad comportamental;
- no comparte datos con anunciantes;
- solo utiliza proveedores técnicos necesarios para operar, proteger, hospedar, monitorear y dar soporte a la plataforma.

Aunque SACDIA aplica medidas razonables de seguridad, ningún sistema digital es completamente infalible. Si detectas una vulnerabilidad o uso indebido, repórtalo a **sacdia.app@gmail.com**.

## 10. Eliminación de cuenta y datos

Puedes solicitar o ejecutar la eliminación de tu cuenta desde las opciones disponibles en la app o escribiendo a **sacdia.app@gmail.com**.

Al eliminar una cuenta, SACDIA podrá eliminar, anonimizar o conservar ciertos datos cuando sea necesario para seguridad, auditoría, integridad histórica del club, cumplimiento de solicitudes pendientes, prevención de abuso o respaldo técnico temporal.

> **BORRADOR — requiere revisión del usuario o de un abogado.** Esta sección cambió en la versión 2.0.0-family (antes 1.0.0-store) y no debe publicarse sin aprobación.

Las cuentas supervisadas de adolescentes de 13 a 17 años siguen la sección 3.5: las elimina el tutor o un administrador, y una cuenta sin tutor vinculado se congela a los 90 días y se elimina 90 días después (sección 3.2).

## 11. Disponibilidad y cambios

SACDIA se proporciona "tal cual" y según disponibilidad. Puede haber errores, interrupciones, mantenimiento, cambios de funcionalidad o limitaciones técnicas.

SACDIA puede actualizar estos Términos para reflejar cambios del producto, seguridad, proveedores o requisitos de tiendas. La versión vigente estará disponible en **https://sacdia.com/terms**.

## 12. Contacto

Para soporte, privacidad, eliminación de cuenta o dudas sobre estos Términos:

- Correo: **sacdia.app@gmail.com**
- Soporte: **https://sacdia.com/support**
- Privacidad: **https://sacdia.com/privacy**

---

## Nota operativa

Este documento está redactado para publicación inicial en App Store y Google Play, alineado con el funcionamiento actual de SACDIA. No constituye asesoría legal personalizada. Antes de usarlo como documento jurídico definitivo de una entidad formal, debe ser revisado por un abogado.
