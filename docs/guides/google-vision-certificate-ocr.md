# OCR de certificados con Google Vision — runbook

**Estado**: ACTIVE. Modo `direct` (ADC en la Mac) operativo en local. Modo `remote` (proxy keyless) **aprobado en local, no desplegado**.
**Verificado**: 2026-10-07 contra el código de `sacdia-backend/` y `sacdia-ocr-proxy/` y la documentación oficial citada.

## Qué hace y qué NO hace

El backend extrae texto de JPEG, PNG, WebP o PDF completos de 1–5 páginas (máximo binario 10 MiB). El OCR propone filas; **no verifica autenticidad ni aprueba**. El miembro revisa/agrega/corrige tipo, catálogo y fecha; después envía. Campo Local decide las filas que le corresponden. Guía Mayor Avanzado/Instructor conservan la bandeja exclusiva del superadministrador, sin crear `enrollments` al aprobar la solicitud institucional. Corregir datos tras fallo OCR NO equivale a aprobación humana ni a un job técnico exitoso.

R2 permanece privado: presign → PUT → confirm/sello; no copiar a GCS ni publicar el documento. La app no usa credenciales Google. La cola `certificate-import-ocr` procesa asíncronamente con concurrencia 1 y dos intentos. Aceptar un job no confirma la lectura. `GOOGLE_VISION_API_KEY` ya no autentica este proveedor, y **ningún modo usa claves de cuenta de servicio ni API keys**: la organización bloquea crear claves de cuenta de servicio y el diseño no las necesita.

## Dos modos de lectura

`OCR_MODE` elige el proveedor. Es obligatorio cuando `NODE_ENV=production`; fuera de producción el valor por defecto es `direct`.

| Modo | Dónde corre | Credenciales Google | Estado |
|---|---|---|---|
| `direct` | Mac del desarrollador | ADC personal (`gcloud auth application-default login`) | Operativo en local. No sirve en Render: no hay ADC. |
| `remote` | Render → proxy en Cloud Run | Ninguna en Render. El proxy usa la identidad de su cuenta de servicio (ADC de Cloud Run). Render y el proxy comparten un secreto HMAC. | Aprobado en local (`PASS_LOCAL_SLICE`). **No hay Cloud Run, Firestore, Secret Manager ni modo remote en Render.** |

Flujo `remote`: Render lee el comprobante sellado de R2, valida el PDF y cuenta sus páginas, firma la solicitud con HMAC-SHA256 y la envía por HTTPS a `POST /v1/ocr` del proxy. El proxy verifica la firma y el replay, reserva la cuota del día en Firestore (solo metadata), confirma `CALLING` y hace **una** llamada a Vision en el endpoint `us-vision.googleapis.com`. Devuelve el texto por páginas; Render ejecuta su parser y su flujo de revisión humana. Detalle de decisión: [ADR 11](../api/ARCHITECTURE-DECISIONS.md). Infraestructura de preproducción: [runbook de infraestructura](ocr-proxy-preprod-infra.md).

## Estado por slice (2026-10-07)

| Slice | Contenido | Estado |
|---|---|---|
| Task0, Task1, Task1b | Layout, contrato HMAC v1, `X-Ocr-Page-Count` | Aprobado en local |
| Task2 | Ledger Firestore y cuota (probado con emulador) | Aprobado en local; el emulador no equivale a la durabilidad de producción |
| TaskR | Contención PDF en Render (worker descartable, tope de decodificación, `CERTIFICATE_IMPORT_PDF_BUSY`) | Aprobado en local |
| Task3 | Handler del proxy y adaptador Vision (simulado) | Aprobado en local; sin llamada real a Vision |
| Task4 | Adaptador `remote` en el backend | Aprobado en local |
| Entrypoint de producción del proxy | `0.0.0.0:$PORT`, variables `OCR_*` | En implementación, no aprobado |
| Cloud Run, Firestore, Secret Manager, Render `remote`, humo real | | **No existen / no ejecutados** |

## Prerrequisitos y configuración runtime

Antes de habilitar lectura real, verificar en el ambiente elegido:

- Redis configurado para la cola; sin Redis `process-ocr` devuelve `CERTIFICATE_IMPORT_OCR_UNAVAILABLE` y no invoca Vision en el request.
- R2 configurado y bucket privado de certificados (`R2_BUCKET_CERTIFICATE_IMPORTS`, credenciales/alias de storage existentes). Sin bucket, subida responde `CERTIFICATE_IMPORT_STORAGE_UNAVAILABLE`.
- Modo `direct`: ADC en el runtime que ejecuta el worker (la Mac). Modo `remote`: el proxy desplegado, con Firestore, el secreto HMAC y la cuenta de servicio de runtime.

### Variables del backend

| Variable | Uso |
|---|---|
| `OCR_MODE` | `direct` o `remote`. Obligatoria con `NODE_ENV=production`. Cualquier otro valor falla al arrancar. |
| `OCR_PROXY_URL` | Solo `remote`. URL **completa del endpoint**, incluida la ruta: `https://<host>/v1/ocr`. https obligatorio; `http://127.0.0.1` solo fuera de producción. |
| `OCR_PROXY_ENV` | Solo `remote`. Entorno lógico, `^[a-z0-9]([a-z0-9-]{0,30}[a-z0-9])?$`. Debe ser igual a `OCR_ENV` del proxy. |
| `OCR_PROXY_KID` | Solo `remote`. Identificador de la llave, `^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$`. Debe existir en el llavero del proxy. |
| `OCR_PROXY_SECRET` | Solo `remote`. Base64 estándar de al menos 32 bytes; es el mismo texto que `OCR_SECRET_CURRENT` para ese `kid`. Un valor inválido hace fallar el arranque sin copiar el secreto al mensaje. |
| `GOOGLE_APPLICATION_CREDENTIALS`, `GOOGLE_CLOUD_PROJECT`, `GOOGLE_CLOUD_QUOTA_PROJECT` | Solo `direct` (ADC). No aplican en `remote`. |

Con `remote` incompleto el backend **no arranca** y no cae a ADC en silencio.

### Variables del proxy (entrypoint de producción)

Nombres exactos que lee el entrypoint, según el trabajo en curso (no aprobado todavía; confirmar contra el código al aprobarlo):

| Variable | Uso |
|---|---|
| `OCR_ENV` | Entorno único del proceso. Un proceso atiende un solo entorno. |
| `OCR_KID_CURRENT`, `OCR_SECRET_CURRENT` | Llave vigente. El secreto es base64 de al menos 32 bytes. |
| `OCR_KID_PREVIOUS`, `OCR_SECRET_PREVIOUS` | Opcionales. Llave anterior durante una rotación. |
| `OCR_MAX_PAGES_PER_ENV_PER_DAY` | Entero de 1 a 400. Ausente significa 400. `0`, negativo, fracción, texto o más de 400 es inválido y nunca significa "ilimitado". |
| `GOOGLE_CLOUD_PROJECT` | Proyecto de Firestore y de cuota. |
| `PORT` | Lo inyecta Cloud Run. |
| `OCR_SHUTDOWN_GRACE_MS` | Margen de cierre ordenado; menor que los 10 s entre `SIGTERM` y `SIGKILL` de Cloud Run. |

El arranque es el script `start` de `sacdia-ocr-proxy/package.json`.

## Modo direct: ADC local en la Mac

Desde una sesión propia con Google Cloud CLI instalado:

```sh
gcloud auth application-default login
gcloud auth application-default set-quota-project sacdia-dev-489217
```

El login ADC es distinto del login de gcloud. El archivo local habitual está en `$HOME/.config/gcloud/application_default_credentials.json` (puede variar con `CLOUDSDK_CONFIG`); no mostrar su contenido, copiarlo al repo ni subirlo a Render. Si `GOOGLE_APPLICATION_CREDENTIALS` apunta a otro archivo, el backend usará ese archivo en lugar del ADC personal. Reiniciar el proceso local tras cambiar su ambiente, sin build como parte de esta tarea. Cuota y permisos: la identidad necesita el permiso `serviceusage.services.use` en el proyecto de cuota. [Autenticación Vision y permiso de cuota](https://docs.cloud.google.com/vision/docs/authentication) · [Ruta y precedencia ADC](https://docs.cloud.google.com/docs/authentication/application-default-credentials).

ADC no es obligatorio al arrancar; el cliente se crea al intentar OCR. Credenciales ausentes o autorización rechazada generan `CERTIFICATE_IMPORT_OCR_UNAVAILABLE` en el worker.

Estado registrado: ADC local preparado para `sacdia-dev-489217`. Existe la cuenta `sacdia-vision-preprod@sacdia-dev-489217.iam.gserviceaccount.com` con `roles/serviceusage.serviceUsageConsumer` y **sin claves**; en el diseño `remote` es la identidad candidata de runtime del proxy.

## Modo remote: secreto HMAC, generación y rotación

Las recetas anteriores de este runbook (Secret File con una clave JSON de cuenta de servicio, `GOOGLE_APPLICATION_CREDENTIALS` en Render, API key de Vision) **se retiraron**: la organización bloquea las claves de cuenta de servicio (`iam.disableServiceAccountKeyCreation`) y la API key se evaluó y descartó. Render no guarda ninguna credencial Google.

### Generar y rotar el secreto HMAC

Reglas:

- Al menos 32 bytes aleatorios, en base64 estándar: `openssl rand -base64 32`. Un secreto más corto lo rechazan el firmante, el llavero del proxy y la validación de arranque del backend.
- Un secreto por entorno. Nunca compartir una llave entre preproducción y producción.
- El valor se guarda en Secret Manager (proyecto del entorno) y se copia al panel de Render como `OCR_PROXY_SECRET`. Nunca va a Git, `.env` reales, logs, chat ni argumentos de línea de comandos.
- Generar y leer siempre por tubería, para que el valor no quede en el historial de la shell:

```sh
openssl rand -base64 32 | tr -d '\n' | gcloud secrets create <secreto> \
  --replication-policy=user-managed --locations=us-east4 --data-file=-
```

El procedimiento completo (permisos mínimos, despliegue y cómo pasar el valor a Render sin pantalla ni historial) está en el [runbook de infraestructura](ocr-proxy-preprod-infra.md). Generar secretos y guardarlos en Secret Manager o en Render requiere autorización humana explícita.

Rotación, con ventana explícita (el proxy admite una llave actual y una anterior):

1. Generar un secreto nuevo con un `kid` nuevo (por ejemplo `k2-2026-12`), en otro secreto de Secret Manager.
2. Desplegar el proxy con `OCR_KID_CURRENT`/`OCR_SECRET_CURRENT` = llave nueva y `OCR_KID_PREVIOUS`/`OCR_SECRET_PREVIOUS` = llave vieja. A partir de aquí el proxy acepta ambas.
3. Cambiar en Render `OCR_PROXY_KID` y `OCR_PROXY_SECRET` a la llave nueva (el guardado puede redesplegar).
4. Esperar a que ya no queden solicitudes firmadas con la llave vieja: cada intento se firma de nuevo con la configuración vigente, y el sesgo de reloj tolerado es de ±120 s, así que basta una ventana corta; conservar la llave anterior al menos varias horas por prudencia.
5. Desplegar de nuevo el proxy sin `OCR_KID_PREVIOUS`/`OCR_SECRET_PREVIOUS` y deshabilitar la versión vieja del secreto.

Rotar la llave **no** cambia el `operationId` ni reinicia el ledger ni la cuota. Si el secreto se expone: rotar de inmediato y, mientras tanto, cerrar el servicio (ver el rollback del runbook de infraestructura) y revisar la facturación.

## Contrato interno con el proxy (resumen)

No hay endpoints públicos nuevos. Detalle del contrato interno en [ENDPOINTS-LIVE-REFERENCE](../api/ENDPOINTS-LIVE-REFERENCE.md#contrato-interno-ocr-backend-a-proxy).

- `POST /v1/ocr`, cuerpo binario sin compresión, hasta 10 MiB. Headers `X-Ocr-*` firmados: versión, entorno, `kid`, `operationId`, `issuedAt`, MIME, longitud, `X-Ocr-Page-Count` (1–5, imagen = 1), timestamp, nonce y SHA-256 del cuerpo.
- `operationId` es el `file_id` ya persistido y `issuedAt` es `confirmed_at`: estables entre reintentos, reinicios y reencolado. No hay UUID nuevo por intento.
- Render cuenta las páginas con `assertCertificateImportPdf`. El proxy **no** parsea PDF: pide a Vision `pages: [1..N]` y exige cobertura exacta y `totalPages == N`.
- Plazos: Vision 25 s, proxy 35 s, cliente de Render 40 s absolutos.
- Respuesta 200: JSON UTF-8 con las páginas 1..N en orden, hasta 16 MiB. Error: `{"version":"v1","code","requestId"}`.
- **Solo un sobre JSON v1 válido decide el código.** Un 429, 5xx o 504 sin sobre válido (por ejemplo, Cloud Run sin instancia libre con máximo 1) es `CERTIFICATE_IMPORT_OCR_UNAVAILABLE`, nunca `CERTIFICATE_IMPORT_OCR_QUOTA`. Reintentar es seguro porque, tras `CALLING`, el ledger impide una segunda llamada a Vision.
- Incertidumbre (crash, deadline, red, respuesta perdida) y `COMPLETE` con respuesta perdida van a revisión manual (`CERTIFICATE_IMPORT_OCR_FAILED`) **sin** segunda llamada a Vision. No hay exactly-once ni caché de resultados.
- Un reintento de BullMQ (5 s) que encuentra el lease vigente (60 s) recibe `CONFLICT` y el archivo pasa a revisión manual. No se reprograma ni se repite Vision.

## Límites, sellado y riesgos operativos

- **Cinco páginas es política SACDIA para todo el PDF.** Vision small-batch permite seleccionar hasta cinco páginas por solicitud; no es un límite universal de PDF de Google. Se solicitan explícitamente `1..pageCount`, nunca se trunca el documento. [Small-batch](https://docs.cloud.google.com/vision/docs/file-small-batch).
- **10 MiB es el límite binario SACDIA**, no el límite JSON de Google. gRPC/Buffer evita la expansión base64 de REST; envío máximo 12 MiB, recepción 16 MiB. El transporte real cerca del límite sigue pendiente de humo. [Cuotas y límites Vision](https://docs.cloud.google.com/vision/quotas).
- **Cuota diaria de la aplicación**: 400 páginas por día UTC y por entorno, compartidas entre todos los usuarios (imagen 1, PDF su total de 1–5; se admite todo el archivo o nada). Vision solo tiene cuotas por minuto, así que esta es la única barrera diaria. El desbordamiento va a revisión manual, no a una cola del día siguiente.
- **Validación PDF en Render (TaskR).** `pdf-lib` 1.17.1 (fijada, con parche que limita la descompresión a 1 MiB por stream y 2 MiB acumulados) corre en un `worker_thread` descartable con heap acotado, un worker a la vez y hasta cuatro en espera, dimensionado para el plan Free de Render (512 MB, 0,1 CPU). Rechaza cifrado, corrupto/truncado, cero o más de cinco páginas, y vuelve a validar archivos confirmados antiguos antes de OCR. Cierre/xref mínimo validado **no** certifica toda la norma ISO. Los supuestos de memoria del plan Free (padre Nest ~300 MiB) no están medidos en Render. [LoadOptions pdf-lib](https://pdf-lib.js.org/docs/api/interfaces/loadoptions).
- `CERTIFICATE_IMPORT_PDF_BUSY` (HTTP 429, solo en `confirm`): el turno de validación no se obtuvo; el archivo no quedó confirmado; reintentar el mismo `confirm`. En el worker de OCR, la cola llena responde `CERTIFICATE_IMPORT_OCR_UNAVAILABLE`.
- El mismo Buffer PDF validado se sube al sello privado exclusivo `batches/{batchId}/sealed/{fileId}-{attemptUuid}.pdf` (el storage puede añadir su prefijo). No se vuelve a copiar un staging mutable. Imágenes usan `fileId-<uuid>` por intento. Si falla persistir el sello, solo se borra la clave propia cuando una relectura DB exitosa demuestra que no está referenciada; ante estado ambiguo puede quedar **huérfana**, para no borrar evidencia comprometida. No existe un limpiador automático nuevo: investigar/reconciliar antes de borrar objetos.
- Cada respuesta PDF debe tener todas las páginas exactamente una vez y sin errores; respuesta parcial, duplicada o con error no registra `OCR_PROCESSED`. Una página válida sin texto puede existir, pero ausencia total de texto usable falla.
- Ledger Firestore: solo metadata (estado, fechas, digest, MIME, longitud, páginas, reserva, lease/fence). Nunca texto OCR, archivos, nombres, correos, UUID de usuario, URLs ni claves R2. Digest, `operationId` y nonce son metadata privada y correlacionable.

## Códigos que ve la app

| Código | Cuándo |
|---|---|
| `CERTIFICATE_IMPORT_OCR_UNAVAILABLE` | Redis ausente al encolar; ADC ausente (`direct`); proxy inalcanzable, 401/403/503, 429/5xx/504 sin sobre válido, redirect, plazo de 40 s; cola de validación PDF llena en el worker. |
| `CERTIFICATE_IMPORT_OCR_QUOTA` | Solo un sobre v1 `QUOTA` válido (cuota diaria de la aplicación) o cuota de Vision en `direct`. |
| `CERTIFICATE_IMPORT_OCR_FAILED` | Contrato inválido, documento sin texto, respuesta demasiado grande, conflicto, incertidumbre, `PAGE_COUNT_MISMATCH`, lease vigente. Revisión manual; el archivo sellado permanece. |
| `CERTIFICATE_IMPORT_OCR_UNSUPPORTED_TYPE`, `CERTIFICATE_IMPORT_OCR_FILE_TOO_LARGE` | MIME no admitido; más de 10 MiB. |
| `CERTIFICATE_IMPORT_PDF_TOO_MANY_PAGES`, `_ENCRYPTED`, `_INVALID` | HTTP 400 en `confirm`; el código va en `message`. |
| `CERTIFICATE_IMPORT_PDF_BUSY` | HTTP 429 en `confirm`; reintentar. |

Los fallos posteriores al encolado no son una respuesta HTTP retroactiva ni un campo público de job. Los códigos terminales no gastan el segundo intento de BullMQ; `CERTIFICATE_IMPORT_OCR_UNAVAILABLE` sí es reintentable.

## Diagnóstico y verificación posterior autorizada

Confirmación HTTP 400 devuelve los códigos legacy en `message`. No imprimir detalles del parser, credenciales ni el secreto HMAC. Si OCR falla después de confirmación válida, conservar evidencia y permitir captura/corrección manual; el revisor humano aún debe decidir.

Pendiente de autorización: desplegar la infraestructura, configurar Render y ejecutar el humo sintético (imagen, PDF de 1 y 5 páginas, rechazo del PDF de 6, cuota, replay, pérdida de respuesta sin segunda llamada a Vision). Usar documentos sintéticos sin datos personales, confirmar costos y revisar logs sin contenido OCR/PII. Procedimiento: [runbook de infraestructura](ocr-proxy-preprod-infra.md). No se hicieron llamadas live a Vision, a Google Cloud ni a Render en este trabajo.

Las pruebas offline no equivalen a producción lista. Persisten hallazgos de `audit` ajenos al baseline (una alta aceptada de Prisma y avisos moderados/bajos); no se declara el repositorio libre de vulnerabilidades. [Contrato API](../api/ENDPOINTS-LIVE-REFERENCE.md#contrato-de-archivosocr-por-certificado-2026-10-01) · [Feature](../features/carga-masiva-certificados.md).

### Verificación local histórica (2026-10-01)

Workspace principal `/Users/abner/Documents/development/sacdia`: 261 pruebas backend / 20 suites y 37 pruebas app, sin builds, previo al modo `remote`. Trazabilidad: [integración autorizada](../plans/2026-09-30-vision-adc-pdf.md#integración-autorizada-al-workspace-principal-2026-10-01). Las cifras vigentes de los slices del proxy están en el [plan](../plans/2026-10-02-vision-keyless-plan.md).
