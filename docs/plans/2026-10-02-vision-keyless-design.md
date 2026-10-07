# OCR keyless desde Render — diseño aceptado

> **Estado real (revisado 2026-10-04 contra `development`)**: Diseño aceptado; sin implementar en ninguna rama (tampoco en el PR #448). Depende de que el PR #448 se integre antes.


**Estado documental:** ACTIVE
**Fecha:** 2026-10-02
**Diseño:** aceptado; **implementación:** pendiente; **despliegue:** no realizado.

Este documento registra decisiones aprobadas, no una autorización para crear infraestructura,
instalar dependencias, generar secretos, ejecutar builds, desplegar o llamar a Vision.
El [plan de implementación](2026-10-02-vision-keyless-plan.md) es trabajo futuro.

## 1. Contexto y decisiones humanas

El backend actual tiene `GoogleVisionCertificateOcrProvider` con SDK oficial y ADC local.
Render todavía no tiene configurado/desplegado el nuevo OCR. La política legacy de Google
bloquea crear claves de cuentas de servicio; no se probó una excepción exclusiva para la
cuenta OCR que preserve todas las protecciones. No se propone debilitarla.

Se aprobó mover únicamente la extracción externa a Cloud Run, conservando Render:

- HTTPS firmado, protegido por autenticación de aplicación: aprobación Engram **10875**.
- Firestore solo para metadata e incertidumbre resuelta manualmente: **10908**.
- Procesamiento propuesto en Estados Unidos: **10913**.
- Cloud Run y Firestore Standard regional en **`us-east4`, Northern Virginia**,
  con retención técnica mínima de ocho días: **10930**.
- Cuota **400 páginas por día UTC por entorno**, compartida entre todos sus usuarios:
  aclaración humana «400 por entorno», **10927 actualizado / 10931**.

La aclaración reemplaza el requisito previo de cuatro páginas por usuario. No se añade un
identificador de usuario, `quotaSubject` ni contador por persona al contrato remoto.
Estos identificadores Engram son trazabilidad, no archivos ni contratos runtime.

## 2. ADR ligero: contexto, decisión, alternativas y consecuencias

**Decisión:** proxy HTTPS de OCR, autenticado con HMAC entre servidores. Cloud Run usa ADC
con su identidad de servicio, sin una clave privada Google. Render conserva R2, ownership,
BullMQ, parsing de negocio y persistencia. Firestore conserva exclusivamente metadata.

**Alternativa no elegida:** worker/job en Google que solicita trabajos a un endpoint privado
firmado de Render. Evita ingreso público al proxy, pero exige nuevas leases/acknowledgements,
planificación, latencia y estados de entrega. No corresponde al contrato síncrono interno elegido.

**Consecuencias:** se introduce un servicio y un almacén durable adicionales. Se acepta que,
ante respuesta perdida o ejecución incierta, el documento vaya a revisión manual sin repetir
Vision. Google keyless **no** elimina el secreto HMAC de aplicación ni todo el riesgo de costo.
La invocación de plataforma debe permitir llegar a la autenticación de aplicación; su mecanismo
IAM debe pasar el preflight. No se aprobó un grant público ni desactivar una protección.

## 3. Límites e invariantes conservados

- API de miembros, Flutter, admin, permisos, schema y aprobación humana no cambian.
- `process-ocr` acepta una cola y devuelve el batch, no confirma lectura ni aprobación.
- Render comprueba dueño del batch y archivo confirmado, lee R2 privado y envía sus bytes
  sellados. Nunca recibe una URL remota que el proxy deba descargar ni comparte credenciales R2.
- Máximo binario **10 MiB (10 485 760 bytes)**; JPEG, PNG, WebP o PDF completo de **1–5 páginas**.
  No se seleccionan solo las primeras páginas ni se modifica la subida firmada existente.
- PDFs reales se validan antes de confirmación y OCR; se conserva el mismo Buffer validado
  y su sello exclusivo. El control de estructura existente no certifica ISO ni acota descompresión.
- BullMQ conserva **dos intentos**, backoff fijo **5 segundos**, concurrencia **1**.
- Render analiza el texto **completo** antes de limitar `rawText` persistido a **20 000 caracteres**.
  Un fallo no registra `OCR_PROCESSED`; las propuestas quedan `NEEDS_REVIEW`.
- ADC directo local del Mac se conserva. El contador descrito aquí controla el modo remoto
  del entorno, no inventa una cuota por usuario ni modifica la ruta local aprobada.

## 4. Flujo y responsabilidades

1. Flutter sube mediante signed PUT; Render confirma evidencia privada y ownership.
2. El worker Render obtiene el Buffer sellado y contexto de operación estable por archivo.
3. El adaptador firma y envía una solicitud binaria a `POST /v1/ocr`.
4. Proxy limita lectura, verifica HMAC/hash/replay y valida MIME/PDF; después admite operación
   y reserva páginas atómicamente en Firestore.
5. Confirma durablemente `CALLING`, fuera de la transacción ejecuta una única llamada Vision.
6. Valida cobertura total, limita respuesta y registra solo resultado técnico `COMPLETE`.
7. Devuelve texto completo por páginas. Render ejecuta su parser y workflow actuales.

**Gate de integración:** `CertificateOcrProvider.extract(files)` y el payload actual
`{ userId, batchId }` no transportan `operationId/issuedAt`. El job actual se elimina al completar.
Por ello `jobId=certificate-ocr-{batchId}` no demuestra identidad durable tras reencolado.
Antes de implementar se debe probar cómo una operación por archivo mantiene identidad y fecha
inmutables entre intentos, reinicios y reencolado. No generar UUID nuevo por HTTP, cambiar la
identidad por rotación HMAC ni reutilizar una operación para bytes distintos. Si hace falta
schema, API o nueva persistencia de negocio, detener y pedir autorización específica.

## 5. Contrato interno HTTPS v1

**Request:** cuerpo binario sin base64, compresión ni URL de origen. Ruta fija `POST /v1/ocr`;
TLS verificado y sin redirects. Canonicalización estricta y versionada, sin concatenaciones
ambiguas; rechazar headers duplicados, valores fuera de gramática y metadata desconocida.

Campos firmados en orden fijo:

| Campo | Regla |
|---|---|
| versión, método, path | `v1`, `POST`, `/v1/ocr`; no normalización silenciosa |
| entorno, `kid` | allowlist propia del entorno; clave actual/anterior durante ventana acotada |
| `operationId`, `issuedAt` | opaco, estable por archivo; fecha inmutable del origen de operación |
| MIME, longitud | tipos admitidos; longitud real exacta dentro de 10 MiB |
| timestamp, nonce | timestamp UTC; nonce aleatorio de al menos 128 bits por intento HTTP |
| SHA-256 | digest de **los bytes reales**, vinculado a todos los campos anteriores |

HMAC-SHA256 y comparaciones constant-time. Verificar primero formato/firma del digest declarado;
leer el cuerpo con límite y comprobar su digest real antes de PDF/parsing/Vision. No confiar
solo en `Content-Length`. No usar un body parser ilimitado ni descomprimir antes del límite.

**Respuesta 200:** JSON v1 con `operationId`, `pageCount` y lista ordenada de
`{ pageNumber, text }`; imagen equivale a página 1. Texto completo, no SDK/protobuf, entidades
ni datos de diagnóstico. Máximo **16 MiB (16 777 216 bytes)** del JSON UTF-8 completo serializado.
Todas las páginas exactamente una vez, sin faltantes, extras, duplicados, errores ni discrepancia
con `totalPages` si Google lo informa. Texto totalmente vacío o exceso de respuesta falla entero;
no truncar para convertir un fallo en éxito.

**Error:** `{ version, code, requestId }`, allowlist técnica sin texto OCR, nombres, URLs,
identificadores humanos, stack, headers secretos o excepción original. `requestId` opaco por
intento; no usar `operationId`, digest o nonce como etiquetas de logs.

## 6. Replay, expiración y Firestore metadata

- Tolerancia de reloj **±120 segundos**. Un timestamp futuro aceptado puede seguir válido
  hasta **240 segundos** desde recepción. El nonce consumido se retiene hasta superar toda
  esa ventana; limpieza elegible a partir de **cinco minutos**, nunca antes de la expiración lógica.
- Una operación es válida hasta **siete días** desde su `issuedAt` inmutable. Ledger y contador
  son elegibles para purga a partir de **ocho días**, sin reducir el horizonte de idempotencia.
- Expiración se evalúa en código, aunque el documento todavía exista. TTL no es autenticación,
  no valida expiración y no garantiza borrado físico inmediato. [TTL de Firestore](https://firebase.google.com/docs/firestore/ttl).
- Colecciones conceptuales aisladas por entorno: operaciones, nonces y cuota diaria UTC.
  Metadata mínima: estado, fechas, digest, MIME/longitud/páginas, reserva, lease/fence y expiración.
- No guardar certificados, texto OCR, nombres, email/UUID de usuario, claves R2, URLs o secretos.
  Digest/opid/nonce son metadata privada y correlacionable: acceso y logs restringidos.
- No GCS ni caché de resultados. Firestore no debe recibir una respuesta OCR gigante;
  su documento tiene límite de [1 MiB](https://docs.cloud.google.com/firestore/quotas).

## 7. Estado durable y garantías limitadas

| Estado | Comportamiento |
|---|---|
| `PLANNED` | admisión y reserva; recuperación con lease/fence solo si se prueba que nunca pasó a `CALLING` |
| `CALLING` | commit durable confirmado antes del RPC; ninguna segunda ejecución automática |
| `COMPLETE` | respuesta válida obtenida y metadata confirmada; no almacena texto recuperable |
| `UNKNOWN` | RPC iniciado o persistencia/entrega incierta; revisión manual, sin nueva llamada Vision |

Los callbacks de transacción Firestore pueden repetirse: **nunca** poner Vision, HTTP ni
side effects externos dentro de ellos. [Transacciones](https://docs.cloud.google.com/firestore/native/docs/manage-data/transactions).
La transición `CALLING` debe confirmar commit inequívoco antes de llamar. Si es ambiguo,
releer solo metadata; no lanzar RPC salvo prueba inequívoca de admisión propia y fencing válido.
Un proceso con fence antiguo no puede completar la transición ni llamar después de perder lease.

Timeout, crash, desconexión, respuesta incompleta o fallo al persistir después de `CALLING`
se tratan conservadoramente como inciertos. Un `COMPLETE` cuya respuesta Render perdió también
va a manual: no hay caché que devolver. Nunca volver a Vision para reconstruir esa respuesta.
No se promete exactly-once, devolución garantizada ni factura exactamente una vez.

## 8. Cuota y errores sin cambiar API pública

Reservar atómicamente **400 páginas/día UTC/entorno**, compartidas entre todos sus usuarios.
Una imagen reserva 1; PDF reserva su total validado de 1–5. Admitir todo el archivo o nada.
La misma operación reserva una sola vez; reserva conservadora no se devuelve tras incertidumbre.
El límite requiere configuración validada, positiva y acotada: cero o valor inválido nunca significa
ilimitado. Nombre candidato `OCR_MAX_PAGES_PER_ENV_PER_DAY`; si falta, default aprobado 400.

Con dos páginas/documento permite hasta 200 documentos/día; tres mil documentos/mes pueden
caberse distribuidos, pero una concentración diaria puede excederlo. Overflow va a manual,
no a una cola automática del día siguiente. No es un tope de factura; invocaciones rechazadas,
almacén, SDK y otros servicios también pueden facturar.

| HTTP interno | Categoría | Adaptación Render existente |
|---|---|---|
| 401/403 | firma, entorno o credencial de aplicación inválidos | `CERTIFICATE_IMPORT_OCR_UNAVAILABLE` |
| 400/413 | contrato/archivo inválido | código PDF/archivo existente cuando comprobado; si no, `CERTIFICATE_IMPORT_OCR_FAILED` |
| 409 | ocupado, conflicto de operación, `UNKNOWN` o resultado no recuperable | fallo manual; nunca cambiar opid para eludirlo |
| 429 | cuota de aplicación o Google | `CERTIFICATE_IMPORT_OCR_QUOTA`; `Retry-After` informativo, sin agendar mañana |
| 503 | indisponible antes de RPC | `CERTIFICATE_IMPORT_OCR_UNAVAILABLE`; repetir solo con prueba de cero side effects |
| 504/fallo post-`CALLING` | ejecución incierta | `CERTIFICATE_IMPORT_OCR_FAILED`; manual, sin repetir Vision |

No se añade un campo público de job/error ni HTTP retroactivo tras encolar. El catálogo y cuatro
locales actuales deben verificarse al implementar. Los dos intentos BullMQ reutilizan operación;
un segundo HTTP usa nonce nuevo, no una segunda llamada Vision tras estado incierto.

## 9. Ubicación, seguridad y recursos

Cloud Run y Firestore: **`us-east4`**. Vision: endpoint explícito **`us-vision.googleapis.com`**,
con parent `projects/.../locations/us` en operaciones que lo requieran; sin fallback global.
[Vision regional](https://docs.cloud.google.com/vision/docs/ocr) delimita Estados Unidos,
no garantiza Virginia. No se promete residencia integral estadounidense de R2 u otros sistemas.

SA y secretos separados por entorno. Cloud Run usa [service identity/ADC](https://docs.cloud.google.com/run/docs/securing/service-identity),
no `GOOGLE_APPLICATION_CREDENTIALS` con una clave Google. HMAC solo en backend Render y
Secret Manager; nunca Flutter ni credenciales personales en Render. Rotación con ventana explícita.
Runtime sin Owner/Editor/rol organizacional: acceso Firestore y Secret Manager mínimo al recurso,
permiso de consumo de cuota donde corresponda, deployer separado. Alcance IAM exacto es gate.
El grant humano temporal OrgPolicyAdmin fue retirado; no se necesita reinstalarlo por conveniencia.

Recursos iniciales **tentativos**: 1 vCPU, 512 MiB, min instances 0, max instances 1,
concurrencia 1; SDK 25 s/retries desactivados, proxy 35 s, cliente Render 40 s.
Perfil de cold start y aislamiento PDF con deadline/memoria deben demostrar viabilidad antes
 de habilitarlo; límite de páginas no limita CPU. No aumentar recursos silenciosamente.
Un [504 de Cloud Run](https://docs.cloud.google.com/run/docs/configuring/request-timeout)
no garantiza que el trabajo se detuvo. Max instances y alertas tampoco son límites de factura.
No registrar certificados/texto, headers firmados, nonce/digest/opid, secretos o excepciones completas;
solo métricas agregadas de estado, duración, páginas y fallos sin etiquetas privadas.

## 10. Costos orientativos, no factura ni autorización de gasto

Modelo anterior: 400–600 documentos iniciales/mes, pico 3000; 1–2 páginas/documento,
10 segundos activos, 1 vCPU/0.5 GiB, min0, sin retries y con free allowances disponibles.
Subtotal referencial con auxiliares modelados: **USD 0.05–0.35 inicial / 3.05–7.55 pico**;
sin free allowances, pico **5.69–10.19**. Firestore fue calculado con tarifa publicada de Iowa:
**no es una cotización exacta de Virginia**. Tarifa Virginia y cuenta de facturación son gate.
Fuentes: [Run](https://cloud.google.com/run/pricing), [Vision](https://cloud.google.com/vision/pricing),
[Firestore](https://cloud.google.com/firestore/pricing). Créditos son compartidos según servicio;
retries, TTL facturable, índices, red, logs, builds y usos de otros entornos pueden aumentar gastos.
Reserva orientativa USD5 inicial/USD20 pico no es tarifa, autorización ni límite garantizado.

## 11. Gates y verificación futura

1. Autorizar implementación local y resolver ubicación/framework del servicio y contexto opid.
2. TDD offline, emulator aislado autorizado, tests de concurrencia/replay/estados/bytes completos;
   revisión independiente de contrato/seguridad y perfil PDF. No llamar a Vision en unit tests.
3. Antes de infraestructura: identificar proyecto/SA producción; verificar DB Firestore existente
   y región inmutable; políticas de ubicación, domain restricted sharing y requireInvokerIam.
   [Invocación pública](https://docs.cloud.google.com/run/docs/authenticating/public) debe ser
   compatible sin debilitar políticas ni excepciones silenciosas. Si no, detener.
4. APIs/IAM/secretos/Firestore/build/deploy requieren autorizaciones explícitas por superficie.
   Preproducción primero; smoke posterior exclusivamente sintético, sin certificados personales.
5. Producción requiere proyecto identificado y aprobación separada. Rollback deshabilita modo
   remoto y permite manual; conserva ledger y no reinicia operaciones desconocidas.

Documentación runtime a sincronizar cuando se implemente: [feature](../features/carga-masiva-certificados.md),
[API](../api/ENDPOINTS-LIVE-REFERENCE.md), [frontend](../api/FRONTEND-INTEGRATION-GUIDE.md),
[runbook](../guides/google-vision-certificate-ocr.md), [arquitectura](../api/ARCHITECTURE-DECISIONS.md)
y [tecnología](../steering/tech.md). La ruta con clave del runbook actual no es este diseño futuro.

## 12. Evidencia de preparación

Código leído mediante Graft/spans: `sacdia-backend/src/certificate-bulk-imports/ocr/`
(provider, parser, processor y queue), `certificate-bulk-imports.service.ts:101–235`,
`certificate-import-pdf.ts` y `src/config/env.validation.ts:218–227`.
Antecedentes temporales: `/private/tmp/sacdia-ocr-keyless-preliminary-5zrcp9a0/section-1-preliminary.md`,
`/private/tmp/sacdia-ocr-section2-proposed-uetsx1ij/section-2-contract-proposed.md`,
`/private/tmp/sacdia-ocr-section3-proposed-vip4au_0/section-3-operational-proposed.md`.
Son borradores históricos; Oregon y cuota por usuario no prevalecen sobre las aprobaciones actuales.
