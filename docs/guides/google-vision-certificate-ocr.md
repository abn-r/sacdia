# Google Vision ADC para certificados — runbook

**Estado**: ACTIVE (operación propuesta; despliegue pendiente)  
**Verificado**: 2026-10-01 contra implementación revisada, integrada al workspace principal por autorización expresa, y documentación oficial.

## Qué hace y qué NO hace

El backend extrae texto de JPEG, PNG, WebP o PDF completos de 1–5 páginas (máximo binario 10 MiB). El OCR propone filas; **no verifica autenticidad ni aprueba**. El miembro revisa/agrega/corrige tipo, catálogo y fecha; después envía. Campo Local decide las filas que le corresponden. Guía Mayor Avanzado/Instructor conservan la bandeja exclusiva del superadministrador, sin crear `enrollments` al aprobar la solicitud institucional. Corregir datos tras fallo OCR NO equivale a aprobación humana ni a un job técnico exitoso.

R2 permanece privado: presign → PUT → confirm/sello; no copiar a GCS ni publicar el documento. La app no usa credenciales Google. La cola `certificate-import-ocr` procesa asíncronamente con concurrencia 1/dos intentos. Aceptar un job no confirma la lectura. El SDK `@google-cloud/vision` usa ADC, gRPC/Buffer, deadline de 25 s y sin retries propios. `GOOGLE_VISION_API_KEY` ya no autentica este proveedor.

## Prerrequisitos y configuración runtime

Antes de habilitar lectura real, verificar en el ambiente elegido:

- Proyecto Google con facturación y Vision API habilitadas, cuotas/presupuesto y principal autorizado; una cuenta dedicada por ambiente, sin Owner/Editor como atajo.
- Redis configurado para la cola; sin Redis `process-ocr` devuelve `CERTIFICATE_IMPORT_OCR_UNAVAILABLE` y no invoca Vision en el request.
- R2 configurado y bucket privado de certificados (`R2_BUCKET_CERTIFICATE_IMPORTS`, credenciales/alias de storage existentes). Sin bucket, subida responde `CERTIFICATE_IMPORT_STORAGE_UNAVAILABLE`.
- Backend y worker disponen de ADC en **su propio runtime**, no solo en la máquina del desarrollador. Si el worker corre en otro servicio, ese servicio necesita también identidad, Redis y R2.

Variables opcionales validadas (no escriben ni imprimen un JSON de credenciales):

| Variable | Uso |
|---|---|
| `GOOGLE_APPLICATION_CREDENTIALS` | Ruta al archivo de credenciales ADC del runtime. Si falta, SDK usa la búsqueda ADC estándar. |
| `GOOGLE_CLOUD_PROJECT` | Proyecto de Google explícito para el cliente. |
| `GOOGLE_CLOUD_QUOTA_PROJECT` | Proyecto de cuota de la autenticación ADC; confirmar permiso `serviceusage.services.use` en ese proyecto. |

ADC no es obligatorio al arrancar; el cliente se crea/valida al intentar OCR. Credenciales ausentes/inválidas o autorización rechazada generan `CERTIFICATE_IMPORT_OCR_UNAVAILABLE`; cuota genera `CERTIFICATE_IMPORT_OCR_QUOTA`; fallo/deadline/resultado incompleto genera `CERTIFICATE_IMPORT_OCR_FAILED` en el worker. No hay un nuevo campo público de job/error ni un HTTP retroactivo después de encolar.

## Mac: ADC local

Desde una sesión propia con Google Cloud CLI instalado:

```sh
gcloud auth application-default login
gcloud auth application-default set-quota-project sacdia-dev-489217
```

El login ADC es distinto del login de gcloud. El archivo local habitual está en `$HOME/.config/gcloud/application_default_credentials.json` (puede variar con `CLOUDSDK_CONFIG`); no mostrar su contenido, copiarlo al repo ni subirlo a Render. Si `GOOGLE_APPLICATION_CREDENTIALS` apunta a otro archivo, el backend usará ese archivo en lugar del ADC personal. Reiniciar el proceso local tras cambiar su ambiente, sin build como parte de esta tarea. [Autenticación Vision y permiso de cuota](https://docs.cloud.google.com/vision/docs/authentication) · [Ruta y precedencia ADC](https://docs.cloud.google.com/docs/authentication/application-default-credentials).

Estado registrado en esta implementación: ADC local preparado para `sacdia-dev-489217`; cuenta preproducción `sacdia-vision-preprod@sacdia-dev-489217.iam.gserviceaccount.com` creada con `roles/serviceusage.serviceUsageConsumer`. **No se generó una clave JSON, no se modificó Render ni se probó OCR facturable.** Que exista la identidad no demuestra aún el smoke del runtime remoto.

## Render: identidad dedicada (pendiente de autorización)

Preferir identidad/proyecto separados para producción. Google recomienda Workload Identity Federation para workloads fuera de Google Cloud: evita claves largas, pero exige integración de identidad que este trabajo no configura. La ruta Secret File con cuenta dedicada es operativamente simple, a cambio de gestionar una clave privada y su rotación. [Métodos de autenticación Vision](https://docs.cloud.google.com/vision/docs/authentication).

Si se autoriza usar una clave de cuenta de servicio:

1. Un operador autorizado genera la clave de **la cuenta dedicada del ambiente**, nunca del ADC personal, y la guarda solo en un canal/almacén seguro. No se incluye aquí un comando de generación automática ni el payload secreto.
2. En el servicio backend/worker Render, añadir un Secret File con nombre como `vision-preprod.json`. El archivo estará en `/etc/secrets/vision-preprod.json`; configurar `GOOGLE_APPLICATION_CREDENTIALS` con esa ruta y proyectos correspondientes. No poner el JSON en variables de texto, `.env` real, logs, chat ni Git.
3. **Agregar/guardar Secret File dispara un despliegue en Render**; guardar variables también puede desplegar según la opción seleccionada. Generar/subir claves y guardar/redeploy son acciones fuera del trabajo de código aprobado: solicitar autorización explícita antes. [Secret Files y guardado de variables en Render](https://render.com/docs/configure-environment-variables).
4. Conceder privilegio mínimo: `roles/serviceusage.serviceUsageConsumer` en el proyecto de cuota (`serviceusage.services.use`), no roles amplios por conveniencia. El contenido se envía inline desde R2; no agregar permisos GCS por defecto. Confirmar la autorización efectiva con el smoke autorizado. [Proyecto de cuota](https://docs.cloud.google.com/docs/quotas/set-quota-project).
5. Registrar custodio/fecha/rotación de la clave sin su contenido. Para rotar, crear reemplazo autorizado, actualizar Secret File, desplegar y comprobar lectura; luego revocar/eliminar la clave antigua. Ante exposición, revocar de inmediato y revisar accesos/facturación. No conservar copias personales.

## Límites, sellado y riesgos operativos

- **Cinco páginas es política SACDIA para todo el PDF.** Vision small-batch permite seleccionar hasta cinco páginas por solicitud; no es un límite universal de PDF de Google. Se solicitan explícitamente `1..pageCount`, nunca se trunca el documento. [Small-batch](https://docs.cloud.google.com/vision/docs/file-small-batch).
- **10 MiB es el límite binario SACDIA**, no el límite JSON de Google. El SDK gRPC/Buffer evita expansión base64 de REST; envío máximo 12 MiB/recepción 16 MiB con envelope. El transporte real cerca del límite sigue pendiente de smoke preprod. [Cuotas y límites Vision](https://docs.cloud.google.com/vision/quotas).
- `pdf-lib` carga estructura real sin `ignoreEncryption`; helper compartido rechaza cifrado, corrupto/truncado, cero o >5 páginas antes de confirmar, y vuelve a validar archivos confirmados antiguos antes de OCR. Cierre/xref mínimo validado **no** certifica toda la norma ISO, renderización Google ni todo el historial incremental. [LoadOptions pdf-lib](https://pdf-lib.js.org/docs/api/interfaces/loadoptions).
- El mismo Buffer PDF validado se sube al sello privado exclusivo `batches/{batchId}/sealed/{fileId}-{attemptUuid}.pdf` (el storage puede añadir su prefijo). No se vuelve a copiar un staging mutable. Imágenes conservan su clave fija previa. Si falla persistir el sello, solo se borra la clave propia cuando una relectura DB exitosa demuestra que no está referenciada; ante estado ambiguo puede quedar **huérfana**, para no borrar evidencia comprometida. No existe un limpiador automático nuevo: investigar/reconciliar antes de borrar objetos.
- Tamaño/páginas no limitan CPU, memoria expandida ni descompresión del parser. No hay sandbox/worker aislado del parser ni presupuesto de CPU nuevo; monitorizar recursos y documentar degradación antes de habilitar producción.
- Cada respuesta PDF debe tener todas las páginas exactamente una vez y sin errores; respuesta parcial, duplicada o con error no registra `OCR_PROCESSED`. Una página válida sin texto puede existir, pero ausencia total de texto usable falla.

## Diagnóstico y verificación posterior autorizada

Confirmación HTTP400 devuelve los códigos legacy en `message`: `CERTIFICATE_IMPORT_PDF_TOO_MANY_PAGES` (dividir/extraer ≤5), `CERTIFICATE_IMPORT_PDF_ENCRYPTED` (quitar protección), `CERTIFICATE_IMPORT_PDF_INVALID` (re-exportar). No imprimir detalles del parser ni credenciales. Si OCR falla después de confirmación válida, conservar evidencia y permitir captura/corrección manual; el revisor humano aún debe decidir.

Pendiente de autorización: configurar Render, desplegar y ejecutar smoke con imagen/PDF1/PDF5, rechazo PDF6/cifrado/corrupto, fallo de credenciales/cuota y continuación manual. Usar documentos sintéticos sin datos personales, confirmar todas las páginas y costos, revisar logs sin contenido OCR/PII y evidencias privadas. No se realizaron llamadas live a Vision, DB ni cambios de despliegue en este trabajo.

Pruebas offline no equivalen a producción lista. Backend tiene baseline de diagnósticos TypeScript no relacionados y hallazgos audit restantes: los parches autorizados de Joi, brace-expansion y engine.io eliminan sus avisos, pero permanecen una alta aceptada de Prisma y avisos moderados/bajos; no se declara el repositorio libre de vulnerabilidades. La revisión independiente y la integración selectiva al workspace principal están completadas; configurar identidades remotas, desplegar y comprobar OCR real siguen pendientes de autorización. [Contrato API](../api/ENDPOINTS-LIVE-REFERENCE.md#contrato-de-archivosocr-por-certificado-2026-10-01) · [Feature](../features/carga-masiva-certificados.md).


### Verificación local tras integración autorizada (2026-10-01)

Workspace principal `/Users/abner/Documents/development/sacdia`: **261 pruebas backend /20 suites** y **37 pruebas app**, analyzer y formato Dart focalizados limpios, sin builds. La comparación causal de fuentes TypeScript previas/integradas con dependencias actuales registra123 diagnósticos existentes en ambos lados, sin nuevos; un formato previo en la spec compartida permanece sin modificar. Los cambios abiertos de otros trabajos se conservaron por hunks, claves y hashes. La consulta inicial de audit fue rechazada por falta de autorización de metadatos; el usuario autorizó después nombres/versiones y los parches acotados. Audit fresco tras Joi18.2.6, brace-expansion1.1.21/5.0.12 y engine.io6.6.10: **0 críticas, 1 alta aceptada, 10 moderadas y 2 bajas**. La política high/critical del repositorio pasa con **0 bloqueantes**; el audit bruto conserva salida1 por hallazgos restantes. Se repitieron261 pruebas backend y5 pruebas de la política, todas pasando; sin builds ni upgrades ajenos. Esto no acredita la operación en Render ni un smoke facturable. [Trazabilidad de integración y comandos](../plans/2026-09-30-vision-adc-pdf.md#integración-autorizada-al-workspace-principal-2026-10-01).
