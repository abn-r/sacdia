# Operación del correo `contacto@sacdia.com`

**Estado**: ACTIVE

**Última verificación**: 2026-07-23

**Alcance**: Cloudflare Email Routing, Resend, Render y Gmail

## Objetivo

Mantener este flujo:

```text
Entrante:
contacto@sacdia.com -> Cloudflare Email Routing -> sacdia.app@gmail.com

Automático:
sacdia-backend -> BullMQ -> Resend API -> destinatario

Manual:
Gmail -> Resend SMTP -> destinatario
```

Resend conserva un límite de 100 correos diarios en su plan gratuito. El
backend limita su worker a 90 trabajos cada 24 horas para reservar hasta 10
envíos manuales desde Gmail. La cuota pertenece a la cuenta de Resend y se
comparte entre ambas API keys.

> [!CAUTION]
> Nunca pegues una API key en commits, tickets, capturas de pantalla,
> documentación o conversaciones. Resend muestra el valor completo una sola
> vez. Guárdalo directamente en el consumidor correspondiente.

## 1. Limpiar la DKIM duplicada

En **Cloudflare → sacdia.com → DNS → Records**:

1. filtrar por `resend._domainkey`;
2. conservar el TXT cuyo contenido contiene `QC7jEbKNVU3` y termina en
   `q1uLJvVQIDAQAB`;
3. eliminar únicamente el TXT que contiene `QDblsCnOvCJB` y termina en
   `ETO84kuQb78cTQIDAQAB`;
4. confirmar en Resend que `sacdia.com` continúa con estado **Verified**.

No modificar:

- los MX raíz usados por Cloudflare Email Routing;
- el SPF raíz de Cloudflare;
- DMARC;
- el MX y SPF de `send.sacdia.com`;
- la DKIM activa de Resend.

La limpieza evita publicar dos claves diferentes bajo el mismo selector.

## 2. Verificar la recepción en Cloudflare

En **Cloudflare → Compute → Email Service → Email Routing**:

1. abrir **Destination Addresses**;
2. confirmar que `sacdia.app@gmail.com` está verificada;
3. abrir **Routing Rules**;
4. confirmar una regla activa con:
   - patrón: `contacto` + `sacdia.com`;
   - acción: **Send to an email**;
   - destino: `sacdia.app@gmail.com`;
5. enviar un correo externo a `contacto@sacdia.com` y confirmar su llegada.

No habilitar **Receiving** en Resend: la recepción pertenece a Cloudflare y
ambos proveedores no deben competir por los MX raíz.

## 3. Crear dos API keys en Resend

En **Resend → API Keys → Create API Key**, crear:

| Nombre | Permiso | Dominio | Destino |
|--------|---------|---------|---------|
| `sacdia-backend-production` | Sending access | `sacdia.com` | Render |
| `sacdia-gmail-smtp` | Sending access | `sacdia.com` | Gmail |

No reutilizar una misma key. La separación permite revocar Gmail sin detener el
backend, o rotar el backend sin romper el envío manual.

Al crear cada key:

1. copiarla una sola vez;
2. pegarla directamente en Render o Gmail;
3. no guardarla en `.env` versionados;
4. no compartirla por chat.

## 4. Configurar Render

En el servicio del backend, abrir **Environment → Environment Variables**.
Primero guardar:

```env
EMAIL_ENABLED=false
RESEND_API_KEY=<key de sacdia-backend-production>
RESEND_FROM_EMAIL=SACDIA <contacto@sacdia.com>
RESEND_REPLY_TO=contacto@sacdia.com
REDIS_URL=<conexión redis/rediss real>
```

Consideraciones:

- `RESEND_API_KEY` y `REDIS_URL` son secretos;
- el backend fallará al arrancar si el email está habilitado y falta alguno;
- `REDIS_URL` es obligatorio porque BullMQ procesa los envíos;
- elegir **Save only** permite preparar variables sin activar todavía el
  servicio.

Después de configurar Gmail y completar las pruebas previas:

1. cambiar `EMAIL_ENABLED=true`;
2. elegir **Save and deploy** o desplegar la revisión aprobada;
3. revisar los logs de arranque;
4. si falla la validación, volver a `EMAIL_ENABLED=false` antes de corregir.

## 5. Configurar Gmail para “Enviar como”

Desde `sacdia.app@gmail.com`, en una computadora:

1. abrir **Configuración → Ver toda la configuración**;
2. entrar en **Cuentas e importación**;
3. en **Enviar correo electrónico como**, elegir
   **Agregar otra dirección de correo electrónico**;
4. usar:

```text
Nombre: SACDIA
Dirección: contacto@sacdia.com
```

5. configurar el servidor SMTP:

```text
Servidor SMTP: smtp.resend.com
Puerto: 465
Usuario: resend
Contraseña: API key sacdia-gmail-smtp
Conexión segura: SSL
```

6. solicitar la verificación;
7. abrir en Gmail el mensaje enviado a `contacto@sacdia.com`;
8. confirmar mediante el enlace o código;
9. marcar `contacto@sacdia.com` como dirección predeterminada;
10. editar la dirección y definir `contacto@sacdia.com` también como
    Reply-To.

Si el puerto 465 falla por negociación TLS, usar puerto 587 con TLS/STARTTLS.
No usar una conexión sin cifrar.

## 6. Pruebas de aceptación

### 6.1 Correo entrante

1. enviar desde una cuenta externa a `contacto@sacdia.com`;
2. confirmar que llega a `sacdia.app@gmail.com`;
3. comprobar que Cloudflare no muestra errores de routing.

### 6.2 Correo manual

1. redactar en Gmail;
2. seleccionar `contacto@sacdia.com` en **De**;
3. enviar a una cuenta externa;
4. responder el mensaje;
5. confirmar que la respuesta llega a `sacdia.app@gmail.com`.

### 6.3 Correo automático

1. ejecutar un flujo real que genere email, como verificación o recuperación;
2. comprobar que el trabajo se procesa en BullMQ;
3. confirmar el ID del mensaje en Resend;
4. responder y confirmar la llegada a Gmail.

En el mensaje recibido, abrir **Mostrar original** y verificar:

```text
From: SACDIA <contacto@sacdia.com>
SPF: PASS
DKIM: PASS
DMARC: PASS
```

Repetir esta validación con un mensaje automático y uno enviado desde Gmail.

## 7. Monitoreo y cuota

- revisar **Resend → Usage** durante los primeros envíos;
- revisar los logs por key para distinguir backend y Gmail;
- mantener el backend dentro de 90 trabajos por 24 horas;
- recordar que Gmail puede consumir la reserva de 10 envíos;
- reevaluar el proveedor o el plan antes de superar 100 diarios o 3,000
  mensuales.

Los trabajos del backend que excedan el límite permanecen esperando en BullMQ;
no se descartan ni consumen un intento de retry.

## 8. Rotación y rollback

### Backend

1. crear una key nueva con `Sending access` para `sacdia.com`;
2. reemplazar `RESEND_API_KEY` en Render;
3. desplegar y enviar una prueba;
4. revocar la key anterior.

### Gmail

1. crear una nueva key restringida;
2. editar o recrear la configuración SMTP de Gmail;
3. enviar una prueba;
4. revocar la key anterior.

### Rollback inmediato

Cambiar `EMAIL_ENABLED=false` en Render. Esto detiene el envío automático sin
alterar Cloudflare, Gmail ni la recepción de `contacto@sacdia.com`.

## Fuentes operativas

- [Resend: SMTP](https://resend.com/docs/send-with-smtp)
- [Resend: API keys](https://resend.com/docs/dashboard/api-keys/introduction)
- [Resend: precios](https://resend.com/pricing)
- [Cloudflare: reglas y destinos de Email Routing](https://developers.cloudflare.com/email-service/configuration/email-routing-addresses/)
- [Gmail: enviar desde otra dirección](https://support.google.com/mail/answer/22370?hl=es-419)
- [Render: variables y secretos](https://render.com/docs/configure-environment-variables)
