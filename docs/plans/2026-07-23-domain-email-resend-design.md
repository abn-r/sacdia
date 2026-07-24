# Diseño: correo transaccional y remitente humano con `contacto@sacdia.com`

**Estado**: APPROVED

**Fecha**: 2026-07-23

**Alcance**: `sacdia-backend`, Resend, Cloudflare Email Routing, Render y Gmail

**Remitente canónico**: `SACDIA <contacto@sacdia.com>`

**Buzón de destino**: `sacdia.app@gmail.com`

## 1. Problema

SACDIA necesita que:

1. los correos automáticos del backend salgan como
   `SACDIA <contacto@sacdia.com>`;
2. los correos enviados manualmente desde Gmail también usen
   `contacto@sacdia.com`;
3. las respuestas e ingresos a `contacto@sacdia.com` lleguen a
   `sacdia.app@gmail.com`;
4. el servicio permanezca dentro de los límites gratuitos mientras el volumen
   lo permita.

El backend ya tiene integración con Resend, BullMQ y React Email. El cambio no
requiere crear un sistema de correo nuevo, sino corregir y activar la
infraestructura existente.

## 2. Estado verificado

### 2.1 Backend

- `ResendEmailProvider` implementa el transporte.
- `EmailService` publica una fachada para los casos de uso.
- `EmailProcessor` renderiza plantillas React Email.
- BullMQ aporta cola, reintentos y backoff.
- `EMAIL_ENABLED` actúa como interruptor de seguridad.
- `.env.example` todavía documenta remitentes `@sacdia.app`.
- Los comentarios afirman un límite de 90 correos diarios, pero el runtime no
  configura actualmente un `limiter` de BullMQ.

### 2.2 DNS y proveedores

- `sacdia.com` usa nameservers de Cloudflare.
- Cloudflare Email Routing recibe el correo del dominio.
- Los MX de `sacdia.com` apuntan a Cloudflare.
- SPF de recepción y DMARC están publicados.
- Resend muestra `sacdia.com` como `Verified`.
- El envío está habilitado en Resend y la recepción está deshabilitada.
- Los registros SPF/MX de `send.sacdia.com` están verificados.
- Existen dos TXT distintos en `resend._domainkey.sacdia.com`.

La clave DKIM activa es la que contiene `QC7jEbKNVU3...` y termina en
`q1uLJvVQIDAQAB`. La clave que contiene `QDblsCnOvCJB...` y termina en
`ETO84kuQb78cTQIDAQAB` es obsoleta.

## 3. Objetivos

- Usar `contacto@sacdia.com` como `From` y `Reply-To` del backend.
- Enviar desde Gmail con el mismo remitente mediante Resend SMTP.
- Recibir en `sacdia.app@gmail.com` mediante Cloudflare Email Routing.
- Separar las credenciales de backend y Gmail.
- Aplicar realmente el límite diario reservado para el backend.
- Fallar temprano si el correo se habilita sin configuración válida.
- Verificar SPF, DKIM y DMARC en mensajes reales.

## 4. Fuera de alcance

- Crear buzones independientes o almacenamiento IMAP/POP.
- Sustituir Gmail como interfaz humana.
- Habilitar recepción en Resend.
- Contratar Google Workspace.
- Autoalojar Postfix u otro servidor SMTP.
- Crear endpoints API nuevos o modificar el schema de base de datos.
- Guardar credenciales reales en el repositorio.

## 5. Alternativas evaluadas

### A. Resend para backend y Gmail — seleccionada

El backend usa la API de Resend y Gmail usa el SMTP de Resend. Cloudflare
reenvía el correo entrante a Gmail.

**Ventajas**:

- reutiliza el transporte ya implementado;
- mantiene un único dominio autenticado;
- permite separar API keys por consumidor;
- no agrega mensualidad dentro del límite gratuito.

**Trade-off**: backend y Gmail comparten la cuota diaria de la cuenta Resend.

### B. Resend para backend y Google Workspace para correo humano

Ofrece buzones corporativos completos y administración centralizada.

**Desventaja decisiva**: agrega una mensualidad y no cumple la restricción de
costo.

### C. SMTP autoalojado

Evita depender de un relay de terceros.

**Desventajas decisivas**: reputación IP, PTR/rDNS, listas de bloqueo,
actualizaciones de seguridad, monitoreo y recuperación quedan bajo
responsabilidad de SACDIA.

## 6. Arquitectura aprobada

```text
Correo entrante
  contacto@sacdia.com
    -> Cloudflare Email Routing
      -> sacdia.app@gmail.com

Correo automático
  sacdia-backend
    -> BullMQ
      -> EmailProcessor
        -> Resend API
          -> destinatario

Correo manual
  Gmail "Enviar como contacto@sacdia.com"
    -> Resend SMTP
      -> destinatario
```

## 7. Diseño de backend

### 7.1 Configuración

Producción usará secretos administrados por Render:

```env
EMAIL_ENABLED=true
RESEND_API_KEY=<backend-sending-key>
RESEND_FROM_EMAIL=SACDIA <contacto@sacdia.com>
RESEND_REPLY_TO=contacto@sacdia.com
```

`.env.example` documentará los valores no secretos correctos. Ningún `.env`
real será modificado o versionado.

### 7.2 Validación de arranque

Cuando `EMAIL_ENABLED=true`:

- `RESEND_API_KEY` debe existir y no ser un placeholder;
- `RESEND_FROM_EMAIL` debe contener un remitente válido;
- `RESEND_REPLY_TO`, si existe, debe ser un email válido;
- Redis debe estar disponible en producción, como ya exige el runtime.

La aplicación debe fallar al arrancar con un mensaje seguro y accionable si
alguna precondición falta. El secreto nunca debe aparecer en logs.

### 7.3 Cuota diaria

El worker de BullMQ aplicará un límite efectivo de 90 trabajos por 24 horas.
Esto reserva hasta 10 envíos diarios para Gmail dentro del límite gratuito
actual de 100 diarios.

Los trabajos excedentes deben permanecer demorados en la cola, no descartarse
ni contabilizarse como intentos fallidos.

### 7.4 Errores y observabilidad

- Mantener cinco intentos con backoff exponencial para fallos transitorios.
- Conservar trabajos fallidos para auditoría.
- No registrar direcciones completas, tokens ni API keys.
- Registrar el ID asignado por Resend y el tipo de trabajo.
- Reportar a Sentry los fallos permanentes del worker.

## 8. Diseño de credenciales

Se crearán dos API keys Resend:

1. `sacdia-backend-production`
   - permiso: `Sending access`;
   - dominio: `sacdia.com`;
   - almacenamiento: secreto de Render.
2. `sacdia-gmail-smtp`
   - permiso: `Sending access`;
   - dominio: `sacdia.com`;
   - almacenamiento: configuración SMTP de Gmail.

La separación permite revocar una integración sin interrumpir la otra y
facilita identificar abuso por key.

## 9. Diseño de Gmail

Gmail configurará `contacto@sacdia.com` en **Cuentas e importación → Enviar
como**:

```text
Host: smtp.resend.com
Puerto: 465
Usuario: resend
Contraseña: API key sacdia-gmail-smtp
Seguridad: SSL
```

La verificación enviada por Gmail llegará a `sacdia.app@gmail.com` mediante
Cloudflare Email Routing.

`contacto@sacdia.com` se establecerá como remitente predeterminado y como
dirección de respuesta.

## 10. Diseño DNS

- Conservar los MX raíz de Cloudflare Email Routing.
- Conservar SPF y DMARC existentes.
- Conservar MX y SPF de `send.sacdia.com`.
- Conservar únicamente la DKIM activa de Resend:
  `QC7jEbKNVU3...q1uLJvVQIDAQAB`.
- Eliminar la DKIM obsoleta:
  `QDblsCnOvCJB...ETO84kuQb78cTQIDAQAB`.
- No habilitar recepción en Resend porque competiría con Cloudflare por los MX
  de recepción.

## 11. Pruebas y verificación

### 11.1 Automatizadas

- validación condicional de variables de entorno;
- configuración efectiva del límite BullMQ;
- remitente y `Reply-To` enviados al proveedor;
- comportamiento con `EMAIL_ENABLED=false`;
- errores seguros cuando falta configuración;
- regresión de los casos de uso existentes.

### 11.2 Operativas

1. Enviar un correo de prueba desde el backend.
2. Confirmar `From: contacto@sacdia.com`.
3. Revisar `Authentication-Results`:
   - SPF: `PASS`;
   - DKIM: `PASS`;
   - DMARC: `PASS`.
4. Responder y confirmar llegada a `sacdia.app@gmail.com`.
5. Enviar manualmente desde Gmail y repetir la validación.
6. Confirmar el mensaje y su ID en los logs de Resend.

## 12. Despliegue

Orden:

1. limpiar la DKIM duplicada;
2. crear las dos API keys restringidas;
3. desplegar la corrección y documentación del backend;
4. configurar secretos en Render con `EMAIL_ENABLED=false`;
5. configurar Gmail y completar su verificación;
6. activar `EMAIL_ENABLED=true`;
7. ejecutar pruebas operativas;
8. monitorear los primeros envíos y la cuota diaria.

El despliegue es reversible desactivando `EMAIL_ENABLED` sin retirar DNS ni
afectar la recepción en Gmail.

## 13. Criterios de aceptación

- El backend envía como `SACDIA <contacto@sacdia.com>`.
- Las respuestas llegan a `sacdia.app@gmail.com`.
- Gmail envía manualmente como `contacto@sacdia.com`.
- SPF, DKIM y DMARC pasan en ambos flujos.
- Backend y Gmail usan API keys distintas, restringidas y revocables.
- BullMQ aplica realmente el límite diario.
- La configuración inválida falla al iniciar sin exponer secretos.
- Los tests relevantes pasan.
- La documentación refleja el estado final.
